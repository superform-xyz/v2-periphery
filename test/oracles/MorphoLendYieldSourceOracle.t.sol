// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { Id, MarketParams } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { MarketParamsLib } from "@superform-v2-core/src/vendor/morpho/MarketParamsLib.sol";
import { SharesMathLib } from "@superform-v2-core/src/vendor/morpho/SharesMathLib.sol";
import { MorphoLendYieldSourceOracle } from "../../src/oracles/MorphoLendYieldSourceOracle.sol";
import { AbstractMorphoOracle } from "../../src/oracles/AbstractMorphoOracle.sol";

import { MockMorpho, MockMorphoERC20 } from "../mocks/MockMorpho.sol";

/// @title MorphoLendYieldSourceOracleTest
/// @notice Unit tests for MorphoLendYieldSourceOracle
contract MorphoLendYieldSourceOracleTest is Test {
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    MorphoLendYieldSourceOracle public oracle;
    MockMorpho public morpho;
    MockMorphoERC20 public loanToken;
    MockMorphoERC20 public collateralToken;

    address public user;
    address public yieldSourceId;
    address public superLedgerConfiguration;

    MarketParams public marketParams;
    Id public marketId;

    // Test market values (18-decimal token for precision in PPS tests)
    uint128 constant TOTAL_SUPPLY_ASSETS = 1_000_000e18;
    uint128 constant TOTAL_SUPPLY_SHARES = 1_000_000e24;
    uint128 constant TOTAL_BORROW_ASSETS = 500_000e18;
    uint128 constant TOTAL_BORROW_SHARES = 500_000e24;

    address public admin;

    event MarketRegistered(address indexed yieldSourceId, Id indexed marketId);
    event MarketUnregistered(address indexed yieldSourceId, Id indexed marketId);

    function setUp() public {
        user = makeAddr("user");
        admin = makeAddr("admin");
        yieldSourceId = makeAddr("yieldSource");
        superLedgerConfiguration = makeAddr("superLedgerConfig");

        // Deploy mocks
        loanToken = new MockMorphoERC20("Wrapped ETH", "WETH", 18);
        collateralToken = new MockMorphoERC20("USD Coin", "USDC", 6);
        morpho = new MockMorpho();

        // Setup market params
        marketParams = MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(collateralToken),
            oracle: makeAddr("priceOracle"),
            irm: makeAddr("irm"),
            lltv: 860_000_000_000_000_000
        });
        marketId = marketParams.id();

        // Setup mock Morpho state
        morpho.setMarketParams(marketId, marketParams);
        morpho.setMarket(
            marketId,
            TOTAL_SUPPLY_ASSETS,
            TOTAL_SUPPLY_SHARES,
            TOTAL_BORROW_ASSETS,
            TOTAL_BORROW_SHARES,
            uint128(block.timestamp),
            0
        );

        // Deploy oracle
        oracle = new MorphoLendYieldSourceOracle(address(morpho), superLedgerConfiguration, admin);

        // Register market
        vm.prank(admin);
        oracle.registerMarket(yieldSourceId, marketParams);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_constructor_initializesCorrectly() public view {
        assertEq(address(oracle.MORPHO()), address(morpho));
        assertEq(oracle.SUPER_LEDGER_CONFIGURATION(), superLedgerConfiguration);
        assertTrue(oracle.hasRole(oracle.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(oracle.hasRole(oracle.MANAGER_ROLE(), admin));
    }

    function test_constructor_revertsOnZeroMorpho() public {
        vm.expectRevert(AbstractMorphoOracle.ZERO_ADDRESS.selector);
        new MorphoLendYieldSourceOracle(address(0), superLedgerConfiguration, admin);
    }

    function test_constructor_revertsOnZeroAdmin() public {
        vm.expectRevert(AbstractMorphoOracle.ZERO_ADDRESS.selector);
        new MorphoLendYieldSourceOracle(address(morpho), superLedgerConfiguration, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        MARKET REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_registerMarket_emitsEvent() public {
        address newYieldSource = makeAddr("newYieldSource");

        vm.expectEmit(true, true, true, true);
        emit MarketRegistered(newYieldSource, marketId);

        vm.prank(admin);
        oracle.registerMarket(newYieldSource, marketParams);
    }

    function test_registerMarket_revertsForNonManager() public {
        address newYieldSource = makeAddr("newYieldSource");

        vm.prank(user);
        vm.expectRevert();
        oracle.registerMarket(newYieldSource, marketParams);
    }

    function test_registerMarket_worksForGrantedManager() public {
        address manager = makeAddr("manager");
        bytes32 managerRole = oracle.MANAGER_ROLE();

        vm.prank(admin);
        oracle.grantRole(managerRole, manager);

        address newYieldSource = makeAddr("newYieldSource");
        vm.prank(manager);
        oracle.registerMarket(newYieldSource, marketParams);

        assertEq(oracle.decimals(newYieldSource), 18);
    }

    function test_registerMarket_revertsOnZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert(AbstractMorphoOracle.ZERO_ADDRESS.selector);
        oracle.registerMarket(address(0), marketParams);
    }

    function test_registerMarket_revertsIfAlreadyRegistered() public {
        vm.prank(admin);
        vm.expectRevert(AbstractMorphoOracle.MARKET_ALREADY_REGISTERED.selector);
        oracle.registerMarket(yieldSourceId, marketParams);
    }

    function test_registerMarket_revertsIfMarketDoesNotExist() public {
        MarketParams memory fakeParams = MarketParams({
            loanToken: makeAddr("fake"),
            collateralToken: makeAddr("fake2"),
            oracle: makeAddr("fake3"),
            irm: makeAddr("fake4"),
            lltv: 1
        });

        vm.prank(admin);
        vm.expectRevert(AbstractMorphoOracle.MARKET_DOES_NOT_EXIST.selector);
        oracle.registerMarket(makeAddr("newSource"), fakeParams);
    }

    /*//////////////////////////////////////////////////////////////
                        UNREGISTER MARKET TESTS
    //////////////////////////////////////////////////////////////*/

    function test_unregisterMarket_removesMapping() public {
        vm.prank(admin);
        oracle.unregisterMarket(yieldSourceId);

        vm.expectRevert(AbstractMorphoOracle.MARKET_NOT_REGISTERED.selector);
        oracle.decimals(yieldSourceId);
    }

    function test_unregisterMarket_emitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit MarketUnregistered(yieldSourceId, marketId);

        vm.prank(admin);
        oracle.unregisterMarket(yieldSourceId);
    }

    function test_unregisterMarket_revertsForNonManager() public {
        vm.prank(user);
        vm.expectRevert();
        oracle.unregisterMarket(yieldSourceId);
    }

    function test_unregisterMarket_revertsIfNotRegistered() public {
        vm.prank(admin);
        vm.expectRevert(AbstractMorphoOracle.MARKET_NOT_REGISTERED.selector);
        oracle.unregisterMarket(makeAddr("unregistered"));
    }

    function test_unregisterAndReregister() public {
        vm.startPrank(admin);
        oracle.unregisterMarket(yieldSourceId);
        oracle.registerMarket(yieldSourceId, marketParams);
        vm.stopPrank();

        assertEq(oracle.decimals(yieldSourceId), 18);
    }

    /*//////////////////////////////////////////////////////////////
                            DECIMALS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_decimals_returnsLoanTokenDecimals() public view {
        assertEq(oracle.decimals(yieldSourceId), 18);
    }

    function test_decimals_revertsForUnregistered() public {
        vm.expectRevert(AbstractMorphoOracle.MARKET_NOT_REGISTERED.selector);
        oracle.decimals(makeAddr("unregistered"));
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE PER SHARE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getPricePerShare_returnsCorrectValue() public view {
        uint256 pps = oracle.getPricePerShare(yieldSourceId);

        uint256 expected = uint256(10 ** 18).toAssetsDown(TOTAL_SUPPLY_ASSETS, TOTAL_SUPPLY_SHARES);
        assertEq(pps, expected);
    }

    function test_getPricePerShare_increasesWithInterest() public {
        uint256 ppsBefore = oracle.getPricePerShare(yieldSourceId);

        morpho.setMarket(
            marketId,
            TOTAL_SUPPLY_ASSETS + 50_000e18,
            TOTAL_SUPPLY_SHARES,
            TOTAL_BORROW_ASSETS,
            TOTAL_BORROW_SHARES,
            uint128(block.timestamp),
            0
        );

        uint256 ppsAfter = oracle.getPricePerShare(yieldSourceId);
        assertGt(ppsAfter, ppsBefore);
    }

    /*//////////////////////////////////////////////////////////////
                        ASSET/SHARE CONVERSION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getAssetOutput_convertsCorrectly() public view {
        uint256 sharesIn = 1000e18;
        uint256 assets = oracle.getAssetOutput(yieldSourceId, address(0), sharesIn);

        uint256 expected = sharesIn.toAssetsDown(TOTAL_SUPPLY_ASSETS, TOTAL_SUPPLY_SHARES);
        assertEq(assets, expected);
    }

    function test_getShareOutput_convertsCorrectly() public view {
        uint256 assetsIn = 1000e18;
        uint256 shares = oracle.getShareOutput(yieldSourceId, address(0), assetsIn);

        uint256 expected = assetsIn.toSharesDown(TOTAL_SUPPLY_ASSETS, TOTAL_SUPPLY_SHARES);
        assertEq(shares, expected);
    }

    function test_getWithdrawalShareOutput_roundsUp() public view {
        uint256 assetsIn = 1000e18;
        uint256 withdrawalShares = oracle.getWithdrawalShareOutput(yieldSourceId, address(0), assetsIn);
        uint256 depositShares = oracle.getShareOutput(yieldSourceId, address(0), assetsIn);

        assertGe(withdrawalShares, depositShares);
    }

    /*//////////////////////////////////////////////////////////////
                            BALANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getBalanceOfOwner_returnsSupplyShares() public {
        uint256 shares = 5000e18;
        morpho.setPosition(marketId, user, shares, 0, 0);

        assertEq(oracle.getBalanceOfOwner(yieldSourceId, user), shares);
    }

    function test_getBalanceOfOwner_returnsZeroForNoPosition() public view {
        assertEq(oracle.getBalanceOfOwner(yieldSourceId, user), 0);
    }

    /*//////////////////////////////////////////////////////////////
                              TVL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getTVLByOwnerOfShares_withPosition() public {
        uint256 shares = 5000e18;
        morpho.setPosition(marketId, user, shares, 0, 0);

        uint256 tvl = oracle.getTVLByOwnerOfShares(yieldSourceId, user);
        uint256 expected = shares.toAssetsDown(TOTAL_SUPPLY_ASSETS, TOTAL_SUPPLY_SHARES);
        assertEq(tvl, expected);
    }

    function test_getTVLByOwnerOfShares_zeroReturnsZero() public view {
        assertEq(oracle.getTVLByOwnerOfShares(yieldSourceId, user), 0);
    }

    function test_getTVL_returnsTotalSupplyAssets() public view {
        assertEq(oracle.getTVL(yieldSourceId), TOTAL_SUPPLY_ASSETS);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-DECIMAL TESTS (6, 8, 18)
    //////////////////////////////////////////////////////////////*/

    /// @notice Helper: create a market with a given loan token decimal and register it
    function _setupDecimalMarket(
        uint8 dec,
        uint128 supplyAssets,
        uint128 supplyShares,
        uint128 borrowAssets,
        uint128 borrowShares
    )
        internal
        returns (address srcId, MarketParams memory params, Id mktId)
    {
        MockMorphoERC20 loan = new MockMorphoERC20("Token", "TKN", dec);
        MockMorphoERC20 col = new MockMorphoERC20("Collateral", "COL", 18);

        params = MarketParams({
            loanToken: address(loan),
            collateralToken: address(col),
            oracle: makeAddr("oracle"),
            irm: makeAddr("irm"),
            lltv: 800_000_000_000_000_000
        });
        mktId = params.id();

        morpho.setMarketParams(mktId, params);
        morpho.setMarket(mktId, supplyAssets, supplyShares, borrowAssets, borrowShares, uint128(block.timestamp), 0);

        srcId = makeAddr(string(abi.encodePacked("src-", dec)));
        vm.prank(admin);
        oracle.registerMarket(srcId, params);
    }

    // --- 6 decimal tests (USDC-like) ---

    function test_decimals_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        assertEq(oracle.decimals(srcId), 6);
    }

    function test_getPricePerShare_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 pps = oracle.getPricePerShare(srcId);
        uint256 expected = uint256(10 ** 6).toAssetsDown(1_000_000e6, 1_000_000e12);
        assertEq(pps, expected);
        assertGt(pps, 0);
    }

    function test_getAssetOutput_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 sharesIn = 1000e6;
        uint256 assets = oracle.getAssetOutput(srcId, address(0), sharesIn);
        uint256 expected = sharesIn.toAssetsDown(1_000_000e6, 1_000_000e12);
        assertEq(assets, expected);
    }

    function test_getShareOutput_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 assetsIn = 1000e6;
        uint256 shares = oracle.getShareOutput(srcId, address(0), assetsIn);
        uint256 expected = assetsIn.toSharesDown(1_000_000e6, 1_000_000e12);
        assertEq(shares, expected);
    }

    function test_withdrawalSharesGeDep_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 assetsIn = 1000e6;
        assertGe(
            oracle.getWithdrawalShareOutput(srcId, address(0), assetsIn),
            oracle.getShareOutput(srcId, address(0), assetsIn)
        );
    }

    function test_roundTrip_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 sharesIn = 5000e6;
        uint256 assets = oracle.getAssetOutput(srcId, address(0), sharesIn);
        uint256 sharesBack = oracle.getShareOutput(srcId, address(0), assets);
        assertLe(sharesBack, sharesIn, "Round-trip should not create value");
    }

    function test_tvl_6dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        assertEq(oracle.getTVL(srcId), 1_000_000e6);

        morpho.setPosition(mktId, user, 100e6, 0, 0);
        uint256 ownerTvl = oracle.getTVLByOwnerOfShares(srcId, user);
        uint256 expected = uint256(100e6).toAssetsDown(1_000_000e6, 1_000_000e12);
        assertEq(ownerTvl, expected);
    }

    function test_ppsIncreasesWithInterest_6dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        // Use large share amount to avoid truncation at low decimals
        uint256 largeShares = 1_000_000e6;
        uint256 assetsBefore = oracle.getAssetOutput(srcId, address(0), largeShares);

        // Simulate interest: increase supply assets (same shares)
        morpho.setMarket(mktId, 1_050_000e6, 1_000_000e12, 500_000e6, 500_000e12, uint128(block.timestamp), 0);

        uint256 assetsAfter = oracle.getAssetOutput(srcId, address(0), largeShares);
        assertGt(assetsAfter, assetsBefore, "6-dec: interest should increase asset output");
    }

    function test_ppsIncreasesWithInterest_8dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 largeShares = 100e8;
        uint256 assetsBefore = oracle.getAssetOutput(srcId, address(0), largeShares);

        // Simulate interest: increase supply assets (same shares)
        morpho.setMarket(mktId, 1_050e8, 1_000e14, 500e8, 500e14, uint128(block.timestamp), 0);

        uint256 assetsAfter = oracle.getAssetOutput(srcId, address(0), largeShares);
        assertGt(assetsAfter, assetsBefore, "8-dec: interest should increase asset output");
    }

    // --- 8 decimal tests (WBTC-like) ---

    function test_decimals_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        assertEq(oracle.decimals(srcId), 8);
    }

    function test_getPricePerShare_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 pps = oracle.getPricePerShare(srcId);
        uint256 expected = uint256(10 ** 8).toAssetsDown(1_000e8, 1_000e14);
        assertEq(pps, expected);
        assertGt(pps, 0);
    }

    function test_getAssetOutput_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 sharesIn = 10e8;
        uint256 assets = oracle.getAssetOutput(srcId, address(0), sharesIn);
        uint256 expected = sharesIn.toAssetsDown(1_000e8, 1_000e14);
        assertEq(assets, expected);
    }

    function test_getShareOutput_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 assetsIn = 10e8;
        uint256 shares = oracle.getShareOutput(srcId, address(0), assetsIn);
        uint256 expected = assetsIn.toSharesDown(1_000e8, 1_000e14);
        assertEq(shares, expected);
    }

    function test_withdrawalSharesGeDep_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 assetsIn = 10e8;
        assertGe(
            oracle.getWithdrawalShareOutput(srcId, address(0), assetsIn),
            oracle.getShareOutput(srcId, address(0), assetsIn)
        );
    }

    function test_roundTrip_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 sharesIn = 50e8;
        uint256 assets = oracle.getAssetOutput(srcId, address(0), sharesIn);
        uint256 sharesBack = oracle.getShareOutput(srcId, address(0), assets);
        assertLe(sharesBack, sharesIn, "Round-trip should not create value");
    }

    function test_tvl_8dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        assertEq(oracle.getTVL(srcId), 1_000e8);

        morpho.setPosition(mktId, user, 10e8, 0, 0);
        uint256 ownerTvl = oracle.getTVLByOwnerOfShares(srcId, user);
        uint256 expected = uint256(10e8).toAssetsDown(1_000e8, 1_000e14);
        assertEq(ownerTvl, expected);
    }

    // --- Cross-decimal consistency ---

    function test_crossDecimal_sameOracleTracksMultipleDecimals() public {
        (address src6,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        (address src8,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);

        assertEq(oracle.decimals(src6), 6);
        assertEq(oracle.decimals(src8), 8);
        assertEq(oracle.decimals(yieldSourceId), 18); // from setUp

        // All PPS should be positive
        assertGt(oracle.getPricePerShare(src6), 0);
        assertGt(oracle.getPricePerShare(src8), 0);
        assertGt(oracle.getPricePerShare(yieldSourceId), 0);

        // Each market's TVL uses its own decimals
        assertEq(oracle.getTVL(src6), 1_000_000e6);
        assertEq(oracle.getTVL(src8), 1_000e8);
        assertEq(oracle.getTVL(yieldSourceId), TOTAL_SUPPLY_ASSETS);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice shares → assets → shares never creates value (lend rounds DOWN both ways)
    function test_fuzz_roundTrip_neverCreatesValue(
        uint128 totalSupplyAssets_,
        uint128 totalSupplyShares_,
        uint128 sharesIn
    )
        public
    {
        totalSupplyAssets_ = uint128(bound(totalSupplyAssets_, 0, type(uint128).max));
        totalSupplyShares_ = uint128(bound(totalSupplyShares_, 0, type(uint128).max));
        sharesIn = uint128(bound(sharesIn, 1, type(uint128).max));

        morpho.setMarket(marketId, totalSupplyAssets_, totalSupplyShares_, 0, 0, uint128(block.timestamp), 0);

        uint256 assets = oracle.getAssetOutput(yieldSourceId, address(0), sharesIn);
        uint256 sharesBack = oracle.getShareOutput(yieldSourceId, address(0), assets);

        assertLe(sharesBack, sharesIn, "Round-trip should not create shares");
    }

    /// @notice assets → shares → assets never creates value (lend rounds DOWN both ways)
    function test_fuzz_roundTrip_assetsNeverGrow(
        uint128 totalSupplyAssets_,
        uint128 totalSupplyShares_,
        uint128 assetsIn
    )
        public
    {
        totalSupplyAssets_ = uint128(bound(totalSupplyAssets_, 0, type(uint128).max));
        totalSupplyShares_ = uint128(bound(totalSupplyShares_, 0, type(uint128).max));
        assetsIn = uint128(bound(assetsIn, 1, type(uint128).max));

        morpho.setMarket(marketId, totalSupplyAssets_, totalSupplyShares_, 0, 0, uint128(block.timestamp), 0);

        uint256 shares = oracle.getShareOutput(yieldSourceId, address(0), assetsIn);
        uint256 assetsBack = oracle.getAssetOutput(yieldSourceId, address(0), shares);

        assertLe(assetsBack, assetsIn, "Round-trip should not create assets");
    }

    /// @notice withdrawalShares >= depositShares for same assets (roundUp vs roundDown)
    function test_fuzz_withdrawalSharesGeqDepositShares(
        uint128 totalSupplyAssets_,
        uint128 totalSupplyShares_,
        uint128 assetsIn
    )
        public
    {
        totalSupplyAssets_ = uint128(bound(totalSupplyAssets_, 0, type(uint128).max));
        totalSupplyShares_ = uint128(bound(totalSupplyShares_, 0, type(uint128).max));
        assetsIn = uint128(bound(assetsIn, 1, type(uint128).max));

        morpho.setMarket(marketId, totalSupplyAssets_, totalSupplyShares_, 0, 0, uint128(block.timestamp), 0);

        uint256 depositShares = oracle.getShareOutput(yieldSourceId, address(0), assetsIn);
        uint256 withdrawalShares = oracle.getWithdrawalShareOutput(yieldSourceId, address(0), assetsIn);

        assertGe(withdrawalShares, depositShares, "Withdrawal shares should >= deposit shares");
    }

    /// @notice PPS is always positive for realistic Morpho market ratios
    /// @dev Morpho shares have a 1e6 virtual offset, so shares ≈ assets * 1e6 initially.
    ///      Extreme deflation (totalAssets << totalShares) can cause PPS to round to 0,
    ///      but this doesn't occur in real Morpho markets.
    function test_fuzz_ppsAlwaysPositive(uint128 totalSupplyAssets_, uint128 totalSupplyShares_) public {
        totalSupplyAssets_ = uint128(bound(totalSupplyAssets_, 1, type(uint128).max));
        // Cap shares/assets ratio to 1e12 (far beyond any realistic Morpho market)
        uint256 maxShares = uint256(totalSupplyAssets_) * 1e12;
        if (maxShares > type(uint128).max) maxShares = type(uint128).max;
        totalSupplyShares_ = uint128(bound(totalSupplyShares_, 1, maxShares));

        morpho.setMarket(marketId, totalSupplyAssets_, totalSupplyShares_, 0, 0, uint128(block.timestamp), 0);

        uint256 pps = oracle.getPricePerShare(yieldSourceId);
        assertGt(pps, 0, "PPS should always be positive");
    }

    /// @notice Zero input returns zero output
    function test_fuzz_zeroSharesInput_returnsZero(uint128 totalSupplyAssets_, uint128 totalSupplyShares_) public {
        totalSupplyAssets_ = uint128(bound(totalSupplyAssets_, 0, type(uint128).max));
        totalSupplyShares_ = uint128(bound(totalSupplyShares_, 0, type(uint128).max));

        morpho.setMarket(marketId, totalSupplyAssets_, totalSupplyShares_, 0, 0, uint128(block.timestamp), 0);

        assertEq(oracle.getAssetOutput(yieldSourceId, address(0), 0), 0, "0 shares should return 0 assets");
        assertEq(oracle.getShareOutput(yieldSourceId, address(0), 0), 0, "0 assets should return 0 shares");
    }

    /// @notice Virtual offset handles empty market (totalAssets=0, totalShares=0) without revert
    function test_fuzz_emptyMarket_noRevert(uint128 sharesIn) public {
        sharesIn = uint128(bound(sharesIn, 0, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, 0, 0, uint128(block.timestamp), 0);

        // Should not revert — virtual offset (VIRTUAL_ASSETS=1, VIRTUAL_SHARES=1e6) prevents division by zero
        oracle.getAssetOutput(yieldSourceId, address(0), sharesIn);
        oracle.getShareOutput(yieldSourceId, address(0), sharesIn);
        oracle.getPricePerShare(yieldSourceId);
        oracle.getWithdrawalShareOutput(yieldSourceId, address(0), sharesIn);
    }

    /// @notice Minimum input (1 share) never reverts and returns reasonable value
    function test_fuzz_minimumInput_noRevert(uint128 totalSupplyAssets_, uint128 totalSupplyShares_) public {
        totalSupplyAssets_ = uint128(bound(totalSupplyAssets_, 0, type(uint128).max));
        totalSupplyShares_ = uint128(bound(totalSupplyShares_, 0, type(uint128).max));

        morpho.setMarket(marketId, totalSupplyAssets_, totalSupplyShares_, 0, 0, uint128(block.timestamp), 0);

        // 1 share and 1 asset should never revert
        oracle.getAssetOutput(yieldSourceId, address(0), 1);
        oracle.getShareOutput(yieldSourceId, address(0), 1);
        oracle.getWithdrawalShareOutput(yieldSourceId, address(0), 1);
    }

    // --- Cross-decimal consistency ---

    function test_interestIncreasesAssetOutput_allDecimals() public {
        // 6 decimals
        (address src6,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        // 8 decimals
        (address src8,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);

        // Record before values
        uint256 shares6 = 1_000_000e6;
        uint256 shares8 = 100e8;
        uint256 shares18 = 1_000e18;

        uint256 before6 = oracle.getAssetOutput(src6, address(0), shares6);
        uint256 before8 = oracle.getAssetOutput(src8, address(0), shares8);
        uint256 before18 = oracle.getAssetOutput(yieldSourceId, address(0), shares18);

        // Simulate interest accrual for the 18-dec market (from setUp)
        morpho.setMarket(
            marketId,
            TOTAL_SUPPLY_ASSETS + 50_000e18,
            TOTAL_SUPPLY_SHARES,
            TOTAL_BORROW_ASSETS,
            TOTAL_BORROW_SHARES,
            uint128(block.timestamp),
            0
        );

        uint256 after18 = oracle.getAssetOutput(yieldSourceId, address(0), shares18);
        assertGt(after18, before18, "18-dec: asset output should increase with interest");

        // 6-dec and 8-dec unchanged (different markets)
        assertEq(oracle.getAssetOutput(src6, address(0), shares6), before6);
        assertEq(oracle.getAssetOutput(src8, address(0), shares8), before8);
    }
}
