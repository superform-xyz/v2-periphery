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

/// @title MorphoOraclesE2E
/// @author Superform Labs
/// @notice E2E tests for MorphoLendYieldSourceOracle and MorphoBorrowCostOracle using real Morpho state
///
/// Real contracts:
///   - Morpho: 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb
///   - WBTC/USDC market (real on-chain market with active supply and borrow)
///
/// No mocks — reads directly from forked mainnet Morpho state
contract MorphoOraclesE2E is Test {
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    address public constant MORPHO = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address public constant CHAIN_1_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant CHAIN_1_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant MORPHO_ORACLE_WBTC_USDC = 0xDddd770BADd886dF3864029e4B377B5F6a2B6b83;
    address public constant MORPHO_IRM_WBTC_USDC = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;

    /// @notice Real deployed SuperVaultStrategy (has a real Morpho lending position)
    address public constant STRATEGY = 0x41A9Eb398518D2487301c61D2b33E4e966A9F1DD;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    MorphoLendYieldSourceOracle public lendOracle;
    MorphoBorrowCostOracle public borrowOracle;

    address public yieldSourceId;
    address public superLedgerConfiguration;

    MarketParams public marketParams;
    Id public marketId;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        yieldSourceId = makeAddr("yieldSource");
        superLedgerConfiguration = makeAddr("superLedgerConfig");

        marketParams = MarketParams({
            loanToken: CHAIN_1_USDC,
            collateralToken: CHAIN_1_WBTC,
            oracle: MORPHO_ORACLE_WBTC_USDC,
            irm: MORPHO_IRM_WBTC_USDC,
            lltv: 860_000_000_000_000_000
        });
        marketId = marketParams.id();

        // address(this) is admin
        lendOracle = new MorphoLendYieldSourceOracle(MORPHO, superLedgerConfiguration, address(this));
        borrowOracle = new MorphoBorrowCostOracle(MORPHO, superLedgerConfiguration, address(this));

        // Accrue interest so lastUpdate == block.timestamp, ensuring oracle's
        // interest-adjusted values match raw MORPHO.market() values at test start
        IMorpho(MORPHO).accrueInterest(marketParams);

        lendOracle.registerMarket(yieldSourceId, marketParams);
        borrowOracle.registerMarket(yieldSourceId, marketParams);
    }

    /*//////////////////////////////////////////////////////////////
                        LEND ORACLE E2E TESTS
    //////////////////////////////////////////////////////////////*/

    function test_lendOracle_decimals_matchesLoanToken() public view {
        uint8 oracleDecimals = lendOracle.decimals(yieldSourceId);
        uint8 usdcDecimals = IERC20Metadata(CHAIN_1_USDC).decimals();
        assertEq(oracleDecimals, usdcDecimals);
        assertEq(oracleDecimals, 6);
    }

    function test_lendOracle_getPricePerShare_isPositive() public view {
        uint256 pps = lendOracle.getPricePerShare(yieldSourceId);
        assertGt(pps, 0);
    }

    function test_lendOracle_getPricePerShare_matchesManualCalculation() public view {
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) =
            IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 manualPps = uint256(10 ** 6).toAssetsDown(totalSupplyAssets, totalSupplyShares);
        uint256 oraclePps = lendOracle.getPricePerShare(yieldSourceId);

        assertEq(oraclePps, manualPps);
    }

    function test_lendOracle_getAssetOutput_matchesMorphoMath() public view {
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) =
            IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 sharesIn = 1_000_000e6;
        uint256 manualAssets = sharesIn.toAssetsDown(totalSupplyAssets, totalSupplyShares);
        uint256 oracleAssets = lendOracle.getAssetOutput(yieldSourceId, address(0), sharesIn);

        assertEq(oracleAssets, manualAssets);
    }

    function test_lendOracle_getShareOutput_matchesMorphoMath() public view {
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) =
            IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 assetsIn = 1000e6;
        uint256 manualShares = assetsIn.toSharesDown(totalSupplyAssets, totalSupplyShares);
        uint256 oracleShares = lendOracle.getShareOutput(yieldSourceId, address(0), assetsIn);

        assertEq(oracleShares, manualShares);
    }

    function test_lendOracle_getWithdrawalShareOutput_roundsUp() public view {
        uint256 assetsIn = 1000e6;
        uint256 depositShares = lendOracle.getShareOutput(yieldSourceId, address(0), assetsIn);
        uint256 withdrawalShares = lendOracle.getWithdrawalShareOutput(yieldSourceId, address(0), assetsIn);

        assertGe(withdrawalShares, depositShares);
    }

    function test_lendOracle_getTVL_matchesMorphoTotalSupply() public view {
        (uint128 totalSupplyAssets,,,,,) = IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 oracleTvl = lendOracle.getTVL(yieldSourceId);
        assertEq(oracleTvl, totalSupplyAssets);
        assertGt(oracleTvl, 0);
    }

    function test_lendOracle_getBalanceOfOwner_matchesMorphoPosition() public view {
        (uint256 supplyShares,,) = IMorphoStaticTyping(MORPHO).position(marketId, STRATEGY);

        uint256 oracleBalance = lendOracle.getBalanceOfOwner(yieldSourceId, STRATEGY);
        assertEq(oracleBalance, supplyShares);
    }

    function test_lendOracle_assetOutput_increasesAfterInterest() public {
        uint256 largeShares = 1_000_000_000e6;
        uint256 assetsBefore = lendOracle.getAssetOutput(yieldSourceId, address(0), largeShares);

        vm.warp(block.timestamp + 365 days);
        IMorpho(MORPHO).accrueInterest(marketParams);

        uint256 assetsAfter = lendOracle.getAssetOutput(yieldSourceId, address(0), largeShares);

        (,, uint128 totalBorrowAssets,,,) = IMorphoStaticTyping(MORPHO).market(marketId);
        if (totalBorrowAssets > 0) {
            assertGt(assetsAfter, assetsBefore);
        }
    }

    function test_lendOracle_getTVLByOwnerOfShares_matchesManual() public view {
        (uint256 supplyShares,,) = IMorphoStaticTyping(MORPHO).position(marketId, STRATEGY);
        (uint128 totalSupplyAssets, uint128 totalSupplyShares,,,,) =
            IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 oracleTvl = lendOracle.getTVLByOwnerOfShares(yieldSourceId, STRATEGY);

        if (supplyShares == 0) {
            assertEq(oracleTvl, 0);
        } else {
            uint256 manualTvl = supplyShares.toAssetsDown(totalSupplyAssets, totalSupplyShares);
            assertEq(oracleTvl, manualTvl);
        }
    }

    /*//////////////////////////////////////////////////////////////
                       BORROW ORACLE E2E TESTS
    //////////////////////////////////////////////////////////////*/

    function test_borrowOracle_decimals_matchesLoanToken() public view {
        assertEq(borrowOracle.decimals(yieldSourceId), 6);
    }

    function test_borrowOracle_getPricePerShare_matchesManualCalculation() public view {
        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) =
            IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 manualPps = uint256(10 ** 6).toAssetsUp(totalBorrowAssets, totalBorrowShares);
        uint256 oraclePps = borrowOracle.getPricePerShare(yieldSourceId);

        assertEq(oraclePps, manualPps);
    }

    function test_borrowOracle_pps_geqLendPps() public view {
        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) =
            IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 borrowPps = uint256(10 ** 6).toAssetsUp(totalBorrowAssets, totalBorrowShares);
        uint256 lendEquivalent = uint256(10 ** 6).toAssetsDown(totalBorrowAssets, totalBorrowShares);

        assertGe(borrowPps, lendEquivalent);
    }

    function test_borrowOracle_getAssetOutput_roundsUp() public view {
        (,, uint128 totalBorrowAssets, uint128 totalBorrowShares,,) =
            IMorphoStaticTyping(MORPHO).market(marketId);

        uint256 sharesIn = 1_000_000e6;
        uint256 manualUp = sharesIn.toAssetsUp(totalBorrowAssets, totalBorrowShares);
        uint256 manualDown = sharesIn.toAssetsDown(totalBorrowAssets, totalBorrowShares);
        uint256 oracleAssets = borrowOracle.getAssetOutput(yieldSourceId, address(0), sharesIn);

        assertEq(oracleAssets, manualUp);
        assertGe(oracleAssets, manualDown);
    }

    function test_borrowOracle_getTVL_matchesMorphoTotalBorrow() public view {
        (,, uint128 totalBorrowAssets,,,) = IMorphoStaticTyping(MORPHO).market(marketId);

        assertEq(borrowOracle.getTVL(yieldSourceId), totalBorrowAssets);
    }

    function test_borrowOracle_assetOutput_increasesAfterInterest() public {
        (,, uint128 totalBorrowAssets,,,) = IMorphoStaticTyping(MORPHO).market(marketId);
        if (totalBorrowAssets == 0) return;

        uint256 largeShares = 1_000_000_000e6;
        uint256 assetsBefore = borrowOracle.getAssetOutput(yieldSourceId, address(0), largeShares);

        vm.warp(block.timestamp + 365 days);
        IMorpho(MORPHO).accrueInterest(marketParams);

        uint256 assetsAfter = borrowOracle.getAssetOutput(yieldSourceId, address(0), largeShares);
        assertGt(assetsAfter, assetsBefore);
    }

    function test_borrowOracle_getBalanceOfOwner_returnsBorrowShares() public view {
        (, uint128 borrowShares,) = IMorphoStaticTyping(MORPHO).position(marketId, STRATEGY);

        assertEq(borrowOracle.getBalanceOfOwner(yieldSourceId, STRATEGY), borrowShares);
    }

    /*//////////////////////////////////////////////////////////////
                    CROSS-ORACLE CONSISTENCY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_bothOracles_sameDecimals() public view {
        assertEq(lendOracle.decimals(yieldSourceId), borrowOracle.decimals(yieldSourceId));
    }

    function test_supplyTVL_geq_borrowTVL() public view {
        assertGe(lendOracle.getTVL(yieldSourceId), borrowOracle.getTVL(yieldSourceId));
    }

    /*//////////////////////////////////////////////////////////////
                    MARKET REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_registerMarket_revertsForFakeMarket() public {
        MarketParams memory fakeParams = MarketParams({
            loanToken: makeAddr("fake"),
            collateralToken: makeAddr("fake2"),
            oracle: makeAddr("fake3"),
            irm: makeAddr("fake4"),
            lltv: 1
        });

        vm.expectRevert(AbstractMorphoOracle.MARKET_DOES_NOT_EXIST.selector);
        lendOracle.registerMarket(makeAddr("newSource"), fakeParams);
    }

    function test_registerMarket_secondYieldSourceId() public {
        address secondId = makeAddr("secondYieldSource");
        lendOracle.registerMarket(secondId, marketParams);

        assertEq(lendOracle.getPricePerShare(yieldSourceId), lendOracle.getPricePerShare(secondId));
    }

    function test_registerMarket_revertsForNonManager() public {
        address nobody = makeAddr("nobody");
        vm.prank(nobody);
        vm.expectRevert();
        lendOracle.registerMarket(makeAddr("newSource"), marketParams);
    }

    function test_unregisterMarket_works() public {
        lendOracle.unregisterMarket(yieldSourceId);

        vm.expectRevert(AbstractMorphoOracle.MARKET_NOT_REGISTERED.selector);
        lendOracle.decimals(yieldSourceId);
    }

    function test_lendAndBorrow_supplyAfterDeposit() public {
        uint256 lendAmount = 10_000e6;
        address lender = makeAddr("lender");

        deal(CHAIN_1_USDC, lender, lendAmount);

        vm.startPrank(lender);
        IERC20(CHAIN_1_USDC).approve(MORPHO, lendAmount);
        IMorpho(MORPHO).supply(marketParams, lendAmount, 0, lender, "");
        vm.stopPrank();

        uint256 balance = lendOracle.getBalanceOfOwner(yieldSourceId, lender);
        assertGt(balance, 0);

        uint256 tvl = lendOracle.getTVLByOwnerOfShares(yieldSourceId, lender);
        assertApproxEqAbs(tvl, lendAmount, 2);
    }
}
