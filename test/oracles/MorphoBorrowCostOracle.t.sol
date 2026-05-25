// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { Id, MarketParams } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { MarketParamsLib } from "@superform-v2-core/src/vendor/morpho/MarketParamsLib.sol";
import { SharesMathLib } from "@superform-v2-core/src/vendor/morpho/SharesMathLib.sol";
import { MorphoBorrowCostOracle } from "../../src/oracles/MorphoBorrowCostOracle.sol";
import { AbstractMorphoOracle } from "../../src/oracles/AbstractMorphoOracle.sol";

import { MockMorpho, MockMorphoERC20 } from "../mocks/MockMorpho.sol";

/// @title MorphoBorrowCostOracleTest
/// @notice Unit tests for MorphoBorrowCostOracle
contract MorphoBorrowCostOracleTest is Test {
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    MorphoBorrowCostOracle public oracle;
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
        oracle = new MorphoBorrowCostOracle(address(morpho), superLedgerConfiguration, admin);

        // Register market
        vm.prank(admin);
        oracle.registerMarket(yieldSourceId, marketParams);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_constructor_initializesCorrectly() public view {
        assertEq(address(oracle.MORPHO()), address(morpho));
        assertTrue(oracle.hasRole(oracle.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(oracle.hasRole(oracle.MANAGER_ROLE(), admin));
    }

    function test_constructor_revertsOnZeroMorpho() public {
        vm.expectRevert(AbstractMorphoOracle.ZERO_ADDRESS.selector);
        new MorphoBorrowCostOracle(address(0), superLedgerConfiguration, admin);
    }

    function test_constructor_revertsOnZeroAdmin() public {
        vm.expectRevert(AbstractMorphoOracle.ZERO_ADDRESS.selector);
        new MorphoBorrowCostOracle(address(morpho), superLedgerConfiguration, address(0));
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

    /*//////////////////////////////////////////////////////////////
                            DECIMALS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_decimals_returnsLoanTokenDecimals() public view {
        assertEq(oracle.decimals(yieldSourceId), 18);
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE PER SHARE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getPricePerShare_returnsCorrectValue() public view {
        uint256 pps = oracle.getPricePerShare(yieldSourceId);

        uint256 expected = uint256(10 ** 18).toAssetsUp(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);
        assertEq(pps, expected);
    }

    function test_getPricePerShare_increasesWithInterest() public {
        uint256 ppsBefore = oracle.getPricePerShare(yieldSourceId);

        morpho.setMarket(
            marketId,
            TOTAL_SUPPLY_ASSETS,
            TOTAL_SUPPLY_SHARES,
            TOTAL_BORROW_ASSETS + 25_000e18,
            TOTAL_BORROW_SHARES,
            uint128(block.timestamp),
            0
        );

        uint256 ppsAfter = oracle.getPricePerShare(yieldSourceId);
        assertGt(ppsAfter, ppsBefore);
    }

    function test_getPricePerShare_roundsUp() public pure {
        uint256 borrowPps = uint256(10 ** 18).toAssetsUp(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);
        uint256 lendEquivalentPps = uint256(10 ** 18).toAssetsDown(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);

        assertGe(borrowPps, lendEquivalentPps);
    }

    /*//////////////////////////////////////////////////////////////
                        ASSET/SHARE CONVERSION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getAssetOutput_roundsUp() public view {
        uint256 sharesIn = 1000e18;
        uint256 assets = oracle.getAssetOutput(yieldSourceId, address(0), sharesIn);

        uint256 expectedUp = sharesIn.toAssetsUp(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);
        uint256 expectedDown = sharesIn.toAssetsDown(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);

        assertEq(assets, expectedUp);
        assertGe(assets, expectedDown);
    }

    function test_getShareOutput_convertsCorrectly() public view {
        uint256 assetsIn = 1000e18;
        uint256 shares = oracle.getShareOutput(yieldSourceId, address(0), assetsIn);

        uint256 expected = assetsIn.toSharesDown(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);
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

    function test_getBalanceOfOwner_returnsBorrowShares() public {
        uint128 shares = 5000e18;
        morpho.setPosition(marketId, user, 0, shares, 0);

        assertEq(oracle.getBalanceOfOwner(yieldSourceId, user), shares);
    }

    function test_getBalanceOfOwner_returnsZeroForNoPosition() public view {
        assertEq(oracle.getBalanceOfOwner(yieldSourceId, user), 0);
    }

    /*//////////////////////////////////////////////////////////////
                              TVL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_getTVLByOwnerOfShares_withDebt() public {
        uint128 shares = 5000e18;
        morpho.setPosition(marketId, user, 0, shares, 0);

        uint256 tvl = oracle.getTVLByOwnerOfShares(yieldSourceId, user);
        uint256 expected = uint256(shares).toAssetsUp(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);
        assertEq(tvl, expected);
    }

    function test_getTVLByOwnerOfShares_zeroReturnsZero() public view {
        assertEq(oracle.getTVLByOwnerOfShares(yieldSourceId, user), 0);
    }

    function test_getTVL_returnsTotalBorrowAssets() public view {
        assertEq(oracle.getTVL(yieldSourceId), TOTAL_BORROW_ASSETS);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-DECIMAL TESTS (6, 8, 18)
    //////////////////////////////////////////////////////////////*/

    /// @notice Helper: create a borrow market with a given loan token decimal and register it
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
        uint256 expected = uint256(10 ** 6).toAssetsUp(500_000e6, 500_000e12);
        assertEq(pps, expected);
        assertGt(pps, 0);
    }

    function test_getAssetOutput_roundsUp_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 sharesIn = 1000e6;
        uint256 assets = oracle.getAssetOutput(srcId, address(0), sharesIn);
        uint256 expectedUp = sharesIn.toAssetsUp(500_000e6, 500_000e12);
        uint256 expectedDown = sharesIn.toAssetsDown(500_000e6, 500_000e12);
        assertEq(assets, expectedUp);
        assertGe(assets, expectedDown);
    }

    function test_getShareOutput_6dec() public {
        (address srcId,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 assetsIn = 1000e6;
        uint256 shares = oracle.getShareOutput(srcId, address(0), assetsIn);
        uint256 expected = assetsIn.toSharesDown(500_000e6, 500_000e12);
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

    function test_tvl_6dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        assertEq(oracle.getTVL(srcId), 500_000e6);

        morpho.setPosition(mktId, user, 0, 100e6, 0);
        uint256 ownerTvl = oracle.getTVLByOwnerOfShares(srcId, user);
        uint256 expected = uint256(100e6).toAssetsUp(500_000e6, 500_000e12);
        assertEq(ownerTvl, expected);
    }

    function test_ppsIncreasesWithInterest_6dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        uint256 largeShares = 1_000_000e6;
        uint256 assetsBefore = oracle.getAssetOutput(srcId, address(0), largeShares);

        // Simulate interest: increase borrow assets (same shares)
        morpho.setMarket(mktId, 1_000_000e6, 1_000_000e12, 525_000e6, 500_000e12, uint128(block.timestamp), 0);

        uint256 assetsAfter = oracle.getAssetOutput(srcId, address(0), largeShares);
        assertGt(assetsAfter, assetsBefore, "6-dec: borrow cost should increase with interest");
    }

    // --- 8 decimal tests (WBTC-like) ---

    function test_decimals_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        assertEq(oracle.decimals(srcId), 8);
    }

    function test_getPricePerShare_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 pps = oracle.getPricePerShare(srcId);
        uint256 expected = uint256(10 ** 8).toAssetsUp(500e8, 500e14);
        assertEq(pps, expected);
        assertGt(pps, 0);
    }

    function test_getAssetOutput_roundsUp_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 sharesIn = 10e8;
        uint256 assets = oracle.getAssetOutput(srcId, address(0), sharesIn);
        uint256 expectedUp = sharesIn.toAssetsUp(500e8, 500e14);
        uint256 expectedDown = sharesIn.toAssetsDown(500e8, 500e14);
        assertEq(assets, expectedUp);
        assertGe(assets, expectedDown);
    }

    function test_getShareOutput_8dec() public {
        (address srcId,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 assetsIn = 10e8;
        uint256 shares = oracle.getShareOutput(srcId, address(0), assetsIn);
        uint256 expected = assetsIn.toSharesDown(500e8, 500e14);
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

    function test_tvl_8dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        assertEq(oracle.getTVL(srcId), 500e8);

        morpho.setPosition(mktId, user, 0, 10e8, 0);
        uint256 ownerTvl = oracle.getTVLByOwnerOfShares(srcId, user);
        uint256 expected = uint256(10e8).toAssetsUp(500e8, 500e14);
        assertEq(ownerTvl, expected);
    }

    function test_ppsIncreasesWithInterest_8dec() public {
        (address srcId,, Id mktId) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);
        uint256 largeShares = 100e8;
        uint256 assetsBefore = oracle.getAssetOutput(srcId, address(0), largeShares);

        // Simulate interest: increase borrow assets (same shares)
        morpho.setMarket(mktId, 1_000e8, 1_000e14, 525e8, 500e14, uint128(block.timestamp), 0);

        uint256 assetsAfter = oracle.getAssetOutput(srcId, address(0), largeShares);
        assertGt(assetsAfter, assetsBefore, "8-dec: borrow cost should increase with interest");
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Debt never shrinks through round-trip: shares → assetsUp → withdrawalSharesUp >= original
    /// Both conversions round UP, so the round-trip conserves or inflates debt.
    function test_fuzz_roundTrip_debtNeverShrinks(
        uint128 totalBorrowAssets_,
        uint128 totalBorrowShares_,
        uint128 sharesIn
    )
        public
    {
        totalBorrowAssets_ = uint128(bound(totalBorrowAssets_, 0, type(uint128).max));
        totalBorrowShares_ = uint128(bound(totalBorrowShares_, 1, type(uint128).max));
        sharesIn = uint128(bound(sharesIn, 1, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, totalBorrowAssets_, totalBorrowShares_, uint128(block.timestamp), 0);

        uint256 assets = oracle.getAssetOutput(yieldSourceId, address(0), sharesIn);
        uint256 sharesBack = oracle.getWithdrawalShareOutput(yieldSourceId, address(0), assets);

        assertGe(sharesBack, sharesIn, "Debt shares should never shrink through round-trip");
    }

    /// @notice Borrow PPS (roundUp) >= lend equivalent (roundDown) for all market states
    function test_fuzz_borrowPpsGeqLendEquivalent(
        uint128 totalBorrowAssets_,
        uint128 totalBorrowShares_
    )
        public
    {
        totalBorrowAssets_ = uint128(bound(totalBorrowAssets_, 1, type(uint128).max));
        totalBorrowShares_ = uint128(bound(totalBorrowShares_, 1, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, totalBorrowAssets_, totalBorrowShares_, uint128(block.timestamp), 0);

        uint256 borrowPps = oracle.getPricePerShare(yieldSourceId);
        uint256 lendEquivalent = uint256(10 ** 18).toAssetsDown(totalBorrowAssets_, totalBorrowShares_);

        assertGe(borrowPps, lendEquivalent, "Borrow PPS (roundUp) should >= lend equivalent (roundDown)");
    }

    /// @notice Borrow getAssetOutput (roundUp) >= lend equivalent (roundDown)
    function test_fuzz_borrowAssetOutputGeqLendEquivalent(
        uint128 totalBorrowAssets_,
        uint128 totalBorrowShares_,
        uint128 sharesIn
    )
        public
    {
        totalBorrowAssets_ = uint128(bound(totalBorrowAssets_, 0, type(uint128).max));
        totalBorrowShares_ = uint128(bound(totalBorrowShares_, 0, type(uint128).max));
        sharesIn = uint128(bound(sharesIn, 1, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, totalBorrowAssets_, totalBorrowShares_, uint128(block.timestamp), 0);

        uint256 assetsUp = oracle.getAssetOutput(yieldSourceId, address(0), sharesIn);
        uint256 assetsDown = uint256(sharesIn).toAssetsDown(totalBorrowAssets_, totalBorrowShares_);

        assertGe(assetsUp, assetsDown, "Borrow asset output (roundUp) should >= lend equivalent (roundDown)");
    }

    /// @notice withdrawalShares >= depositShares for same assets
    function test_fuzz_withdrawalSharesGeqDepositShares(
        uint128 totalBorrowAssets_,
        uint128 totalBorrowShares_,
        uint128 assetsIn
    )
        public
    {
        totalBorrowAssets_ = uint128(bound(totalBorrowAssets_, 0, type(uint128).max));
        totalBorrowShares_ = uint128(bound(totalBorrowShares_, 0, type(uint128).max));
        assetsIn = uint128(bound(assetsIn, 1, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, totalBorrowAssets_, totalBorrowShares_, uint128(block.timestamp), 0);

        uint256 depositShares = oracle.getShareOutput(yieldSourceId, address(0), assetsIn);
        uint256 withdrawalShares = oracle.getWithdrawalShareOutput(yieldSourceId, address(0), assetsIn);

        assertGe(withdrawalShares, depositShares, "Withdrawal shares should >= deposit shares");
    }

    /// @notice PPS always positive for non-trivial borrow markets
    function test_fuzz_ppsAlwaysPositive(uint128 totalBorrowAssets_, uint128 totalBorrowShares_) public {
        totalBorrowAssets_ = uint128(bound(totalBorrowAssets_, 1, type(uint128).max));
        totalBorrowShares_ = uint128(bound(totalBorrowShares_, 1, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, totalBorrowAssets_, totalBorrowShares_, uint128(block.timestamp), 0);

        uint256 pps = oracle.getPricePerShare(yieldSourceId);
        assertGt(pps, 0, "Borrow PPS should always be positive");
    }

    /// @notice Zero input returns zero output
    function test_fuzz_zeroSharesInput_returnsZero(uint128 totalBorrowAssets_, uint128 totalBorrowShares_) public {
        totalBorrowAssets_ = uint128(bound(totalBorrowAssets_, 0, type(uint128).max));
        totalBorrowShares_ = uint128(bound(totalBorrowShares_, 0, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, totalBorrowAssets_, totalBorrowShares_, uint128(block.timestamp), 0);

        assertEq(oracle.getAssetOutput(yieldSourceId, address(0), 0), 0, "0 shares should return 0 assets");
        assertEq(oracle.getShareOutput(yieldSourceId, address(0), 0), 0, "0 assets should return 0 shares");
    }

    /// @notice Virtual offset handles empty market without revert
    function test_fuzz_emptyMarket_noRevert(uint128 sharesIn) public {
        sharesIn = uint128(bound(sharesIn, 0, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, 0, 0, uint128(block.timestamp), 0);

        oracle.getAssetOutput(yieldSourceId, address(0), sharesIn);
        oracle.getShareOutput(yieldSourceId, address(0), sharesIn);
        oracle.getPricePerShare(yieldSourceId);
        oracle.getWithdrawalShareOutput(yieldSourceId, address(0), sharesIn);
    }

    /// @notice Minimum input (1 share) never reverts
    function test_fuzz_minimumInput_noRevert(uint128 totalBorrowAssets_, uint128 totalBorrowShares_) public {
        totalBorrowAssets_ = uint128(bound(totalBorrowAssets_, 0, type(uint128).max));
        totalBorrowShares_ = uint128(bound(totalBorrowShares_, 0, type(uint128).max));

        morpho.setMarket(marketId, 0, 0, totalBorrowAssets_, totalBorrowShares_, uint128(block.timestamp), 0);

        oracle.getAssetOutput(yieldSourceId, address(0), 1);
        oracle.getShareOutput(yieldSourceId, address(0), 1);
        oracle.getWithdrawalShareOutput(yieldSourceId, address(0), 1);
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
        assertEq(oracle.getTVL(src6), 500_000e6);
        assertEq(oracle.getTVL(src8), 500e8);
        assertEq(oracle.getTVL(yieldSourceId), TOTAL_BORROW_ASSETS);
    }

    function test_borrowPPS_roundsUp_allDecimals() public {
        (address src6,,) = _setupDecimalMarket(6, 1_000_000e6, 1_000_000e12, 500_000e6, 500_000e12);
        (address src8,,) = _setupDecimalMarket(8, 1_000e8, 1_000e14, 500e8, 500e14);

        // Borrow PPS (roundUp) should >= equivalent lend (roundDown) for all decimals
        uint256 borrow6 = oracle.getPricePerShare(src6);
        uint256 lend6 = uint256(10 ** 6).toAssetsDown(500_000e6, 500_000e12);
        assertGe(borrow6, lend6, "6-dec: borrow PPS should >= lend equivalent");

        uint256 borrow8 = oracle.getPricePerShare(src8);
        uint256 lend8 = uint256(10 ** 8).toAssetsDown(500e8, 500e14);
        assertGe(borrow8, lend8, "8-dec: borrow PPS should >= lend equivalent");

        uint256 borrow18 = oracle.getPricePerShare(yieldSourceId);
        uint256 lend18 = uint256(10 ** 18).toAssetsDown(TOTAL_BORROW_ASSETS, TOTAL_BORROW_SHARES);
        assertGe(borrow18, lend18, "18-dec: borrow PPS should >= lend equivalent");
    }
}
