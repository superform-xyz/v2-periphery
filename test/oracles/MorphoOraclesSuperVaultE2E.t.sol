// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// External imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { Test } from "forge-std/Test.sol";

// Morpho imports
import { Id, MarketParams, IMorpho } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { IMorphoStaticTyping } from "@superform-v2-core/src/vendor/morpho/IMorpho.sol";
import { MarketParamsLib } from "@superform-v2-core/src/vendor/morpho/MarketParamsLib.sol";
import { SharesMathLib } from "@superform-v2-core/src/vendor/morpho/SharesMathLib.sol";

// Superform imports
import { MorphoLendYieldSourceOracle } from "../../src/oracles/MorphoLendYieldSourceOracle.sol";
import { MorphoBorrowCostOracle } from "../../src/oracles/MorphoBorrowCostOracle.sol";
import { AbstractMorphoOracle } from "../../src/oracles/AbstractMorphoOracle.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

/// @notice Minimal ERC4626 interface for reading SuperVault state
interface IERC4626Minimal {
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function asset() external view returns (address);
    function totalSupply() external view returns (uint256);
}

/// @title MorphoOraclesSuperVaultE2E
/// @author Superform Labs
/// @notice E2E tests for Morpho oracles integrated with real deployed SuperVault strategies
///
/// Real contracts (Ethereum mainnet):
///   - Morpho:   0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb
///   - SuperUSDC vault:     0xf6EbeA08a0Dfd44825f67Fa9963911c81BE2a947
///   - SuperUSDC strategy:  0x41A9Eb398518D2487301c61D2b33E4e966A9F1DD
///   - SuperWBTC vault:     0x8c365aF7094Eaac29314eDeE577B435892CA93A3
///   - SuperWBTC strategy:  0xa96060B0B6907406EdBDf3cCc9438abf0F78Cf83
///   - SuperWETH vault:     0xa036823b9A24F63c32553367bf181Ee04229c3AC
///   - SuperWETH strategy:  0x1199a6B2587Ed96446E76Dee3FB660bb8fCfd0b2
///
/// Uses forked mainnet state — no mocks
contract MorphoOraclesSuperVaultE2E is Test {
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    address public constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    // SuperVault contracts
    address public constant SUPER_USDC_VAULT = 0xf6EbeA08a0Dfd44825f67Fa9963911c81BE2a947;
    address public constant SUPER_USDC_STRATEGY = 0x41A9Eb398518D2487301c61D2b33E4e966A9F1DD;
    address public constant SUPER_WBTC_VAULT = 0x8c365aF7094Eaac29314eDeE577B435892CA93A3;
    address public constant SUPER_WBTC_STRATEGY = 0xa96060B0B6907406EdBDf3cCc9438abf0F78Cf83;
    address public constant SUPER_WETH_VAULT = 0xa036823b9A24F63c32553367bf181Ee04229c3AC;
    address public constant SUPER_WETH_STRATEGY = 0x1199a6B2587Ed96446E76Dee3FB660bb8fCfd0b2;

    // Token addresses
    address public constant CHAIN_1_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant CHAIN_1_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    // WBTC/USDC Morpho market constants
    address public constant MORPHO_ORACLE_WBTC_USDC = 0xDddd770BADd886dF3864029e4B377B5F6a2B6b83;
    address public constant MORPHO_IRM_WBTC_USDC = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;
    uint256 public constant WBTC_USDC_LLTV = 860_000_000_000_000_000;

    /*//////////////////////////////////////////////////////////////
                                  STORAGE
    //////////////////////////////////////////////////////////////*/

    MorphoLendYieldSourceOracle public lendOracle;
    MorphoBorrowCostOracle public borrowOracle;

    address public superLedgerConfiguration;

    MarketParams public wbtcUsdcMarket;
    Id public wbtcUsdcMarketId;

    /*//////////////////////////////////////////////////////////////
                                  SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        superLedgerConfiguration = makeAddr("superLedgerConfig");

        lendOracle = new MorphoLendYieldSourceOracle(MORPHO, superLedgerConfiguration, address(this));
        borrowOracle = new MorphoBorrowCostOracle(MORPHO, superLedgerConfiguration, address(this));

        wbtcUsdcMarket = MarketParams({
            loanToken: CHAIN_1_USDC,
            collateralToken: CHAIN_1_WBTC,
            oracle: MORPHO_ORACLE_WBTC_USDC,
            irm: MORPHO_IRM_WBTC_USDC,
            lltv: WBTC_USDC_LLTV
        });
        wbtcUsdcMarketId = wbtcUsdcMarket.id();

        // Accrue interest so lastUpdate == block.timestamp, ensuring oracle's
        // interest-adjusted values match raw MORPHO.market() values at test start
        IMorpho(MORPHO).accrueInterest(wbtcUsdcMarket);
    }

    /*//////////////////////////////////////////////////////////////
                    STRATEGY YIELD SOURCE DISCOVERY
    //////////////////////////////////////////////////////////////*/

    function test_superUSDCStrategy_hasYieldSources() public view {
        ISuperVaultStrategy.YieldSourceInfo[] memory sources =
            ISuperVaultStrategy(SUPER_USDC_STRATEGY).getYieldSourcesList();
        assertGt(sources.length, 0, "SuperUSDC strategy should have yield sources");
    }

    function test_superWBTCStrategy_hasYieldSources() public view {
        ISuperVaultStrategy.YieldSourceInfo[] memory sources =
            ISuperVaultStrategy(SUPER_WBTC_STRATEGY).getYieldSourcesList();
        assertGt(sources.length, 0, "SuperWBTC strategy should have yield sources");
    }

    function test_superWETHStrategy_hasYieldSources() public view {
        ISuperVaultStrategy.YieldSourceInfo[] memory sources =
            ISuperVaultStrategy(SUPER_WETH_STRATEGY).getYieldSourcesList();
        assertGt(sources.length, 0, "SuperWETH strategy should have yield sources");
    }

    function test_strategyYieldSources_haveNonZeroOracles() public view {
        ISuperVaultStrategy.YieldSourceInfo[] memory sources =
            ISuperVaultStrategy(SUPER_USDC_STRATEGY).getYieldSourcesList();

        for (uint256 i; i < sources.length; i++) {
            assertTrue(sources[i].sourceAddress != address(0), "Yield source address should be non-zero");
            assertTrue(sources[i].oracle != address(0), "Oracle address should be non-zero");
        }
    }

    /*//////////////////////////////////////////////////////////////
                ORACLE-STRATEGY POSITION TRACKING (LEND)
    //////////////////////////////////////////////////////////////*/

    /// @notice Lend oracle correctly reads strategy's Morpho supply shares
    function test_lendOracle_tracksStrategySupplyPosition() public {
        address yieldSourceId = makeAddr("wbtc-usdc-lend");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        (uint256 supplyShares,,) = IMorphoStaticTyping(MORPHO).position(wbtcUsdcMarketId, SUPER_USDC_STRATEGY);

        uint256 oracleBalance = lendOracle.getBalanceOfOwner(yieldSourceId, SUPER_USDC_STRATEGY);
        assertEq(oracleBalance, supplyShares, "Oracle balance should match Morpho supply position");
    }

    /// @notice TVL by owner matches manual share-to-asset conversion
    function test_lendOracle_tvlForStrategy_matchesManualCalc() public {
        address yieldSourceId = makeAddr("wbtc-usdc-lend");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        (uint256 supplyShares,,) = IMorphoStaticTyping(MORPHO).position(wbtcUsdcMarketId, SUPER_USDC_STRATEGY);
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) =
            IMorphoStaticTyping(MORPHO).market(wbtcUsdcMarketId);

        uint256 expectedTvl;
        if (supplyShares > 0) {
            expectedTvl = supplyShares.toAssetsDown(totalSupplyAssets, totalSupplyShares);
        }

        uint256 oracleTvl = lendOracle.getTVLByOwnerOfShares(yieldSourceId, SUPER_USDC_STRATEGY);
        assertEq(oracleTvl, expectedTvl, "Oracle TVL should match manual calculation");
    }

    /// @notice Lend PPS should be positive
    /// @dev Morpho shares have a 1e6 virtual offset (SharesMathLib.VIRTUAL_SHARES),
    ///      so for 6-decimal tokens like USDC, integer PPS ≈ 1
    function test_lendOracle_pps_isPositive() public {
        address yieldSourceId = makeAddr("wbtc-usdc-lend");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        uint256 pps = lendOracle.getPricePerShare(yieldSourceId);
        assertGt(pps, 0, "Morpho lend PPS should be positive");
    }

    /*//////////////////////////////////////////////////////////////
                ORACLE-STRATEGY POSITION TRACKING (BORROW)
    //////////////////////////////////////////////////////////////*/

    /// @notice Borrow oracle correctly reads strategy's Morpho borrow shares
    function test_borrowOracle_tracksStrategyBorrowPosition() public {
        address yieldSourceId = makeAddr("wbtc-usdc-borrow");
        borrowOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        (, uint128 borrowShares,) = IMorphoStaticTyping(MORPHO).position(wbtcUsdcMarketId, SUPER_USDC_STRATEGY);

        uint256 oracleBalance = borrowOracle.getBalanceOfOwner(yieldSourceId, SUPER_USDC_STRATEGY);
        assertEq(oracleBalance, borrowShares, "Oracle should match Morpho borrow position");
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-STRATEGY SAME MARKET
    //////////////////////////////////////////////////////////////*/

    /// @notice Different strategies have independent balances on the same market registration
    function test_multipleStrategies_independentBalances() public {
        address yieldSourceId = makeAddr("wbtc-usdc-lend");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        (uint256 usdcShares,,) = IMorphoStaticTyping(MORPHO).position(wbtcUsdcMarketId, SUPER_USDC_STRATEGY);
        (uint256 wbtcShares,,) = IMorphoStaticTyping(MORPHO).position(wbtcUsdcMarketId, SUPER_WBTC_STRATEGY);
        (uint256 wethShares,,) = IMorphoStaticTyping(MORPHO).position(wbtcUsdcMarketId, SUPER_WETH_STRATEGY);

        assertEq(lendOracle.getBalanceOfOwner(yieldSourceId, SUPER_USDC_STRATEGY), usdcShares);
        assertEq(lendOracle.getBalanceOfOwner(yieldSourceId, SUPER_WBTC_STRATEGY), wbtcShares);
        assertEq(lendOracle.getBalanceOfOwner(yieldSourceId, SUPER_WETH_STRATEGY), wethShares);
    }

    /*//////////////////////////////////////////////////////////////
                SUPERVAULT ACCOUNTING CONSISTENCY
    //////////////////////////////////////////////////////////////*/

    /// @notice Strategy's Morpho position via oracle should not exceed SuperVault total assets
    function test_strategyMorphoPosition_noLargerThanVaultTotalAssets() public {
        address yieldSourceId = makeAddr("wbtc-usdc-lend");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        uint256 morphoPositionValue = lendOracle.getTVLByOwnerOfShares(yieldSourceId, SUPER_USDC_STRATEGY);
        uint256 totalAssets = IERC4626Minimal(SUPER_USDC_VAULT).totalAssets();

        assertLe(morphoPositionValue, totalAssets, "Morpho position should not exceed SuperVault total assets");
    }

    /// @notice SuperVault stored PPS should be positive
    function test_superVaultStoredPPS_isPositive() public view {
        uint256 storedPps = ISuperVaultStrategy(SUPER_USDC_STRATEGY).getStoredPPS();
        assertGt(storedPps, 0, "Stored PPS should be positive");
    }

    /// @notice SuperVault total assets should be positive (vault has real deposits)
    function test_superVaultTotalAssets_isPositive() public view {
        uint256 totalAssets = IERC4626Minimal(SUPER_USDC_VAULT).totalAssets();
        assertGt(totalAssets, 0, "SuperVault should have positive total assets");
    }

    /// @notice Asset output is positive and consistent with share-to-asset math
    /// @dev Morpho shares use a virtual offset (1e6 virtual shares), so
    ///      the raw share-to-asset ratio differs from 1:1 in loan token decimals
    function test_lendOracle_assetConversion_isPositive() public {
        address yieldSourceId = makeAddr("wbtc-usdc-lend");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        uint256 sharesIn = 1_000_000e6;
        uint256 assetsOut = lendOracle.getAssetOutput(yieldSourceId, address(0), sharesIn);

        assertGt(assetsOut, 0, "Asset output should be positive");

        // Round-trip: shares → assets → shares should be <= original shares (no free value)
        uint256 sharesBack = lendOracle.getShareOutput(yieldSourceId, address(0), assetsOut);
        assertLe(sharesBack, sharesIn, "Round-trip should not create value");
    }

    /*//////////////////////////////////////////////////////////////
                        INTEREST ACCRUAL
    //////////////////////////////////////////////////////////////*/

    /// @notice After interest accrues, strategy's position value increases
    function test_interestAccrual_growsStrategyValue() public {
        address yieldSourceId = makeAddr("wbtc-usdc-lend");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        (uint256 supplyShares,,) = IMorphoStaticTyping(MORPHO).position(wbtcUsdcMarketId, SUPER_USDC_STRATEGY);
        if (supplyShares == 0) return; // Skip if no position

        uint256 valueBefore = lendOracle.getTVLByOwnerOfShares(yieldSourceId, SUPER_USDC_STRATEGY);

        vm.warp(block.timestamp + 365 days);
        IMorpho(MORPHO).accrueInterest(wbtcUsdcMarket);

        (,, uint128 totalBorrowAssets,,,) = IMorphoStaticTyping(MORPHO).market(wbtcUsdcMarketId);
        if (totalBorrowAssets > 0) {
            uint256 valueAfter = lendOracle.getTVLByOwnerOfShares(yieldSourceId, SUPER_USDC_STRATEGY);
            assertGt(valueAfter, valueBefore, "Strategy position value should increase with interest");
        }
    }

    /// @notice Borrow cost PPS grows at least as fast as lend yield PPS
    function test_borrowCostGrowth_geqLendYieldGrowth() public {
        address lendSourceId = makeAddr("lend-src");
        address borrowSourceId = makeAddr("borrow-src");

        lendOracle.registerMarket(lendSourceId, wbtcUsdcMarket);
        borrowOracle.registerMarket(borrowSourceId, wbtcUsdcMarket);

        uint256 lendPpsBefore = lendOracle.getPricePerShare(lendSourceId);
        uint256 borrowPpsBefore = borrowOracle.getPricePerShare(borrowSourceId);

        vm.warp(block.timestamp + 365 days);
        IMorpho(MORPHO).accrueInterest(wbtcUsdcMarket);

        (,, uint128 totalBorrowAssets,,,) = IMorphoStaticTyping(MORPHO).market(wbtcUsdcMarketId);
        if (totalBorrowAssets > 0) {
            uint256 lendPpsAfter = lendOracle.getPricePerShare(lendSourceId);
            uint256 borrowPpsAfter = borrowOracle.getPricePerShare(borrowSourceId);

            uint256 borrowGrowth = borrowPpsAfter - borrowPpsBefore;
            uint256 lendGrowth = lendPpsAfter - lendPpsBefore;

            assertGe(borrowGrowth, lendGrowth, "Borrow cost growth should >= lend yield growth");
        }
    }

    /*//////////////////////////////////////////////////////////////
            FULL LIFECYCLE: DEPOSIT → TRACK → ACCRUE → VERIFY
    //////////////////////////////////////////////////////////////*/

    /// @notice Complete lifecycle: supply to Morpho, verify oracle tracking, accrue interest, verify growth
    function test_fullLifecycle_supplyTrackAccrue() public {
        address yieldSourceId = makeAddr("lifecycle-test");
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        address depositor = makeAddr("depositor");
        uint256 depositAmount = 100_000e6;

        deal(CHAIN_1_USDC, depositor, depositAmount);

        uint256 tvlBefore = lendOracle.getTVL(yieldSourceId);

        // Supply to Morpho
        vm.startPrank(depositor);
        IERC20(CHAIN_1_USDC).approve(MORPHO, depositAmount);
        IMorpho(MORPHO).supply(wbtcUsdcMarket, depositAmount, 0, depositor, "");
        vm.stopPrank();

        // Oracle tracks the new position
        uint256 balance = lendOracle.getBalanceOfOwner(yieldSourceId, depositor);
        assertGt(balance, 0, "Depositor should have supply shares");

        // TVL should increase by at least the deposit amount
        // (may be slightly more due to interest accrual triggered by supply())
        uint256 tvlAfter = lendOracle.getTVL(yieldSourceId);
        assertGe(tvlAfter - tvlBefore, depositAmount, "TVL should increase by at least deposit amount");

        uint256 ownerTvl = lendOracle.getTVLByOwnerOfShares(yieldSourceId, depositor);
        assertApproxEqAbs(ownerTvl, depositAmount, 2, "Owner TVL should match deposit");

        // Accrue interest — use large share amount for precision (integer PPS can truncate for low-decimal tokens)
        uint256 largeShares = 1_000_000_000e6;
        uint256 assetOutputBefore = lendOracle.getAssetOutput(yieldSourceId, address(0), largeShares);
        vm.warp(block.timestamp + 30 days);
        IMorpho(MORPHO).accrueInterest(wbtcUsdcMarket);

        (,, uint128 totalBorrowAssets,,,) = IMorphoStaticTyping(MORPHO).market(wbtcUsdcMarketId);
        if (totalBorrowAssets > 0) {
            uint256 assetOutputAfter = lendOracle.getAssetOutput(yieldSourceId, address(0), largeShares);
            assertGt(assetOutputAfter, assetOutputBefore, "Asset output should increase after interest accrual");

            uint256 ownerTvlAfter = lendOracle.getTVLByOwnerOfShares(yieldSourceId, depositor);
            assertGt(ownerTvlAfter, ownerTvl, "Owner TVL should increase after interest");
        }
    }

    /// @notice Full borrow lifecycle: supply collateral, borrow, verify borrow oracle tracking
    function test_fullLifecycle_borrowTrackAccrue() public {
        address yieldSourceId = makeAddr("borrow-lifecycle");
        borrowOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);

        address borrower = makeAddr("borrower");
        uint256 collateralAmount = 1e8; // 1 WBTC
        uint256 borrowAmount = 10_000e6; // 10k USDC

        // Fund borrower with collateral
        deal(CHAIN_1_WBTC, borrower, collateralAmount);

        vm.startPrank(borrower);

        // Supply collateral
        IERC20(CHAIN_1_WBTC).approve(MORPHO, collateralAmount);
        IMorpho(MORPHO).supplyCollateral(wbtcUsdcMarket, collateralAmount, borrower, "");

        // Borrow
        IMorpho(MORPHO).borrow(wbtcUsdcMarket, borrowAmount, 0, borrower, borrower);
        vm.stopPrank();

        // Oracle tracks the borrow position
        uint256 borrowShares = borrowOracle.getBalanceOfOwner(yieldSourceId, borrower);
        assertGt(borrowShares, 0, "Borrower should have borrow shares");

        uint256 borrowTvl = borrowOracle.getTVLByOwnerOfShares(yieldSourceId, borrower);
        assertApproxEqAbs(borrowTvl, borrowAmount, 2, "Borrow TVL should approximate borrow amount");

        // Accrue interest — borrow debt grows
        uint256 debtBefore = borrowOracle.getTVLByOwnerOfShares(yieldSourceId, borrower);
        vm.warp(block.timestamp + 365 days);
        IMorpho(MORPHO).accrueInterest(wbtcUsdcMarket);

        uint256 debtAfter = borrowOracle.getTVLByOwnerOfShares(yieldSourceId, borrower);
        assertGt(debtAfter, debtBefore, "Borrow debt should grow with interest");
    }

    /*//////////////////////////////////////////////////////////////
                MULTI-REGISTRATION LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /// @notice Same oracle instance tracks multiple registrations independently
    function test_multipleRegistrations_independentLifecycle() public {
        address source1 = makeAddr("source1");
        address source2 = makeAddr("source2");

        lendOracle.registerMarket(source1, wbtcUsdcMarket);
        lendOracle.registerMarket(source2, wbtcUsdcMarket);

        // Both report same PPS (same underlying market)
        assertEq(lendOracle.getPricePerShare(source1), lendOracle.getPricePerShare(source2));

        // Both report same TVL
        assertEq(lendOracle.getTVL(source1), lendOracle.getTVL(source2));

        // Unregister one — the other still works
        lendOracle.unregisterMarket(source1);

        vm.expectRevert(AbstractMorphoOracle.MARKET_NOT_REGISTERED.selector);
        lendOracle.getPricePerShare(source1);

        assertGt(lendOracle.getPricePerShare(source2), 0);
    }

    /// @notice Re-registering after unregister works correctly
    function test_unregisterAndReregister_preservesFunctionality() public {
        address yieldSourceId = makeAddr("reregister-test");

        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);
        uint256 ppsBefore = lendOracle.getPricePerShare(yieldSourceId);

        lendOracle.unregisterMarket(yieldSourceId);

        vm.expectRevert(AbstractMorphoOracle.MARKET_NOT_REGISTERED.selector);
        lendOracle.getPricePerShare(yieldSourceId);

        // Re-register
        lendOracle.registerMarket(yieldSourceId, wbtcUsdcMarket);
        uint256 ppsAfter = lendOracle.getPricePerShare(yieldSourceId);

        assertEq(ppsAfter, ppsBefore, "PPS should be identical after re-registration");
    }

    /*//////////////////////////////////////////////////////////////
                    LEND + BORROW ORACLE CONSISTENCY
    //////////////////////////////////////////////////////////////*/

    /// @notice On the same market, lend TVL >= borrow TVL (market invariant)
    function test_lendTVL_geq_borrowTVL_sameMarket() public {
        address lendSourceId = makeAddr("lend");
        address borrowSourceId = makeAddr("borrow");

        lendOracle.registerMarket(lendSourceId, wbtcUsdcMarket);
        borrowOracle.registerMarket(borrowSourceId, wbtcUsdcMarket);

        uint256 lendTvl = lendOracle.getTVL(lendSourceId);
        uint256 borrowTvl = borrowOracle.getTVL(borrowSourceId);

        assertGe(lendTvl, borrowTvl, "Total supply should >= total borrow");
    }

    /// @notice Both oracles report same decimals for the same market
    function test_bothOracles_sameDecimals_sameMarket() public {
        address lendSourceId = makeAddr("lend");
        address borrowSourceId = makeAddr("borrow");

        lendOracle.registerMarket(lendSourceId, wbtcUsdcMarket);
        borrowOracle.registerMarket(borrowSourceId, wbtcUsdcMarket);

        assertEq(lendOracle.decimals(lendSourceId), borrowOracle.decimals(borrowSourceId));
        assertEq(lendOracle.decimals(lendSourceId), 6); // USDC decimals
    }

    /// @notice Borrow PPS >= Lend PPS (rounding difference — borrow rounds up, lend rounds down)
    function test_borrowPPS_geq_lendPPS() public {
        address lendSourceId = makeAddr("lend");
        address borrowSourceId = makeAddr("borrow");

        lendOracle.registerMarket(lendSourceId, wbtcUsdcMarket);
        borrowOracle.registerMarket(borrowSourceId, wbtcUsdcMarket);

        // Compare supply-side PPS vs borrow-side PPS for borrow totals
        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) =
            IMorphoStaticTyping(MORPHO).market(wbtcUsdcMarketId);

        if (totalBorrowAssets > 0) {
            uint256 lendEquiv = uint256(10 ** 6).toAssetsDown(totalBorrowAssets, totalBorrowShares);
            uint256 borrowPps = borrowOracle.getPricePerShare(borrowSourceId);
            assertGe(borrowPps, lendEquiv, "Borrow PPS (roundUp) should >= lend equivalent (roundDown)");
        }
    }
}
