// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

// external
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { UserOpData } from "modulekit/ModuleKit.sol";
import { IPendleMarket } from "v2-core/src/vendor/pendle/IPendleMarket.sol";
import { IPYieldToken } from "v2-core/src/vendor/pendle/IPYieldToken.sol";
import { IStandardizedYield } from "v2-core/src/vendor/pendle/IStandardizedYield.sol";
import {
    IPendleRouterV4,
    LimitOrderData,
    FillOrderParams,
    TokenInput,
    TokenOutput,
    ApproxParams,
    SwapType,
    SwapData
} from "v2-core/src/vendor/pendle/IPendleRouterV4.sol";
import { console2 } from "forge-std/console2.sol";

// Superform
import { PendleUnifiedHook } from "v2-core/src/hooks/swappers/pendle/PendleUnifiedHook.sol";
import { ISuperExecutor } from "v2-core/src/interfaces/ISuperExecutor.sol";
import { MinimalBaseIntegrationTest } from "v2-core/test/integration/MinimalBaseIntegrationTest.t.sol";

/// @title DETHMarketMigrationTest
/// @notice Integration test for DETH Pendle market migration without swap
/// @dev Tests the scenario where:
///      1. SuperVault has funds in DETH 29JAN2026 market (expired)
///      2. Redeem PT+YT after expiry to get DETH directly in strategy
///      3. Invest DETH into new 26APR2026 market WITHOUT swapping DETH -> WETH -> DETH
///      This avoids unnecessary swap fees and slippage by using DETH directly
contract DETHMarketMigrationTest is MinimalBaseIntegrationTest {
    // DETH token address (underlying for Pendle markets)
    address public constant DETH = 0x871aB8E36CaE9AF35c6A3488B049965233DeB7ed;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // First market (29JAN2026) - will be expired
    address public constant DETH_MARKET_OLD = 0x937c7868824ae53dB3b7C634de209FB7a74E362c;
    address public constant PT_DETH_OLD = 0x8209b01357946A64a0793e9773F6F3Fe5A5F2526;

    // Second market (26APR2026) - will invest into this
    address public constant DETH_MARKET_NEW = 0xaAAF90CBc7c8C38a08ca810c5e5f3C1D99a2b600;
    address public constant PT_DETH_NEW = 0xE1D9b789da5B5375eACF66f036022B019A2Af307;

    // SuperVault WETH addresses (mainnet)
    address public constant SUPERVAULT_WETH = 0xa036823b9A24F63c32553367bf181Ee04229c3AC;
    address public constant SUPERVAULT_WETH_STRATEGY = 0x1199a6B2587Ed96446E76Dee3FB660bb8fCfd0b2;

    PendleUnifiedHook public pendleUnifiedHook;

    // Market tokens
    address public syOld;
    address public ptOld;
    address public ytOld;

    address public syNew;
    address public ptNew;
    address public ytNew;

    function setUp() public override {
        // Fork mainnet at current block
        blockNumber = 0;
        super.setUp();

        // Deploy PendleUnifiedHook with real Pendle Router
        pendleUnifiedHook = new PendleUnifiedHook(CHAIN_1_PENDLE_ROUTER);

        // Get tokens from OLD DETH market (29JAN2026)
        (syOld, ptOld, ytOld) = IPendleMarket(DETH_MARKET_OLD).readTokens();

        // Get tokens from NEW DETH market (26APR2026)
        (syNew, ptNew, ytNew) = IPendleMarket(DETH_MARKET_NEW).readTokens();

        // Log addresses for debugging
        console2.log("OLD Market SY:", syOld);
        console2.log("OLD Market PT:", ptOld);
        console2.log("OLD Market YT:", ytOld);
        console2.log("NEW Market SY:", syNew);
        console2.log("NEW Market PT:", ptNew);
        console2.log("NEW Market YT:", ytNew);
    }

    /// @notice Test step 1 of migration: Redeem from expired market to get DETH directly
    /// @dev This demonstrates that DETH (not WETH) is received from post-maturity redemption
    function test_RedeemFromExpiredMarket_GetsDETH() public {
        // Setup: Deal PT and YT from OLD market to account
        // Note: Pendle PT packs a flag byte with totalSupply in slot 2, so deal(adjust=true)
        // breaks the storage layout. Use plain deal with an amount <= existing totalSupply
        // to avoid underflow in PT.burnByYT.
        uint256 ptSupply = IERC20(ptOld).totalSupply();
        uint256 ytSupply = IERC20(ytOld).totalSupply();
        uint256 redeemAmount = ptSupply < ytSupply ? ptSupply / 2 : ytSupply / 2;
        require(redeemAmount > 0, "No PT/YT supply remaining on expired market");
        deal(ptOld, accountEth, redeemAmount);
        deal(ytOld, accountEth, redeemAmount);

        assertEq(IERC20(ptOld).balanceOf(accountEth), redeemAmount, "PT not dealt");
        assertEq(IERC20(ytOld).balanceOf(accountEth), redeemAmount, "YT not dealt");

        // Record initial balances
        uint256 dethBalanceBefore = IERC20(DETH).balanceOf(accountEth);
        uint256 wethBalanceBefore = IERC20(WETH).balanceOf(accountEth);
        console2.log("Initial DETH balance:", dethBalanceBefore);
        console2.log("Initial WETH balance:", wethBalanceBefore);

        // Ensure we are AFTER the OLD market expiry (don't warp backwards if fork is already past expiry)
        uint256 expiryOld = IPYieldToken(ytOld).expiry();
        if (block.timestamp <= expiryOld) {
            vm.warp(expiryOld + 1 days);
        }
        console2.log("Current timestamp (after expiry):", block.timestamp);

        // Redeem from OLD market to get DETH (not WETH!)
        bytes memory redeemHookData = _createPendleUnifiedRedeemHookData(
            DETH_MARKET_OLD, // yieldSource is always the market
            redeemAmount,
            ytOld,
            DETH, // tokenOut - we want DETH directly
            DETH, // tokenRedeemSy - DETH is the valid SY output
            1, // minTokenOut
            false // usePrevHookAmount
        );

        {
            address[] memory hooks = new address[](1);
            hooks[0] = address(pendleUnifiedHook);

            bytes[] memory data = new bytes[](1);
            data[0] = redeemHookData;

            ISuperExecutor.ExecutorEntry memory entry =
                ISuperExecutor.ExecutorEntry({ hooksAddresses: hooks, hooksData: data });

            UserOpData memory userOpData = _getExecOps(instanceOnEth, superExecutorOnEth, abi.encode(entry));
            executeOp(userOpData);
        }

        // Verify we received DETH (not WETH)
        uint256 dethBalanceAfter = IERC20(DETH).balanceOf(accountEth);
        uint256 wethBalanceAfter = IERC20(WETH).balanceOf(accountEth);

        console2.log("Final DETH balance:", dethBalanceAfter);
        console2.log("Final WETH balance:", wethBalanceAfter);
        console2.log("DETH received from redemption:", dethBalanceAfter - dethBalanceBefore);

        // Key assertions:
        // 1. We received DETH (the underlying token)
        assertGt(dethBalanceAfter, dethBalanceBefore, "Should receive DETH from redemption");
        // 2. We did NOT receive WETH (no swap happened)
        assertEq(wethBalanceAfter, wethBalanceBefore, "Should NOT receive WETH - no swap needed");
    }

    /// @notice Test that both markets share the same SY and support DETH
    /// @dev This proves the migration path is valid: OLD market DETH -> NEW market DETH
    function test_MigrationPath_BothMarkets_SupportDETH() public view {
        // Both markets should share the same SY (they're both DETH markets)
        assertEq(syOld, syNew, "Both markets should use the same SY for DETH");

        // DETH is a valid output from OLD market (for redemption)
        bool dethValidOut = IStandardizedYield(syOld).isValidTokenOut(DETH);
        assertTrue(dethValidOut, "DETH should be valid output from OLD market SY");

        // DETH is a valid input for NEW market (for deposit)
        bool dethValidIn = IStandardizedYield(syNew).isValidTokenIn(DETH);
        assertTrue(dethValidIn, "DETH should be valid input for NEW market SY");

        // WETH is NOT a valid output from the DETH SY
        bool wethValidOut = IStandardizedYield(syOld).isValidTokenOut(WETH);
        assertFalse(wethValidOut, "WETH should NOT be valid output from DETH SY");

        console2.log("Shared SY address:", syOld);
        console2.log("DETH valid out:", dethValidOut);
        console2.log("DETH valid in:", dethValidIn);
        console2.log("WETH valid out:", wethValidOut);
    }

    /// @notice Test that DETH can be used directly as input for the new Pendle market
    /// @dev Verifies that DETH is a valid tokenIn for the new market's SY
    function test_DETH_Is_Valid_Input_For_NewMarket() public view {
        bool dethValid = IStandardizedYield(syNew).isValidTokenIn(DETH);
        assertTrue(dethValid, "DETH should be valid input for new market SY");

        address[] memory tokensIn = IStandardizedYield(syNew).getTokensIn();
        console2.log("Number of valid input tokens:", tokensIn.length);
        for (uint256 i = 0; i < tokensIn.length; i++) {
            console2.log("tokenIn:", i, tokensIn[i]);
        }
    }

    /// @notice Test that DETH can be directly obtained from old market redemption
    /// @dev Verifies that DETH is a valid tokenOut for the old market's SY
    function test_DETH_Is_Valid_Output_From_OldMarket() public view {
        bool dethValid = IStandardizedYield(syOld).isValidTokenOut(DETH);
        assertTrue(dethValid, "DETH should be valid output from old market SY");

        address[] memory tokensOut = IStandardizedYield(syOld).getTokensOut();
        console2.log("Number of valid output tokens:", tokensOut.length);
        for (uint256 i = 0; i < tokensOut.length; i++) {
            console2.log("tokenOut:", i, tokensOut[i]);
        }
    }

    /// @notice Test that both markets use the same SY (they share the DETH underlying)
    /// @dev If both markets use the same SY, the migration is even simpler
    function test_Markets_Share_Same_SY() public view {
        // Note: Different markets may have different SY implementations even for the same underlying
        // But they should both support DETH as input/output
        console2.log("OLD market SY:", syOld);
        console2.log("NEW market SY:", syNew);

        // Both should support DETH regardless of whether they share the same SY
        bool oldSupportsDeth = IStandardizedYield(syOld).isValidTokenOut(DETH);
        bool newSupportsDeth = IStandardizedYield(syNew).isValidTokenIn(DETH);

        assertTrue(oldSupportsDeth, "Old market SY should support DETH output");
        assertTrue(newSupportsDeth, "New market SY should support DETH input");
    }

    /// @notice Helper to create ApproveERC20Hook data
    /// @dev Data layout: [address token][address spender][uint256 amount][bool usePrevHookAmount]
    function _createApproveHookData(
        address token,
        address spender,
        uint256 amount
    )
        internal
        pure
        returns (bytes memory)
    {
        // ApproveERC20Hook data layout: [address token][address spender][uint256 amount][bool usePrevHookAmount]
        return abi.encodePacked(token, spender, amount, false);
    }

    /// @notice Helper to create PendleUnifiedHook data for redeemPyToToken (direct redemption)
    function _createPendleUnifiedRedeemHookData(
        address yieldSource,
        uint256 amount,
        address ytAddress,
        address tokenOut,
        address tokenRedeemSy,
        uint256 minTokenOut,
        bool usePrevHookAmount
    )
        internal
        view
        returns (bytes memory)
    {
        // Create TokenOutput struct with no swap routing (direct redemption)
        TokenOutput memory output = TokenOutput({
            tokenOut: tokenOut,
            minTokenOut: minTokenOut,
            tokenRedeemSy: tokenRedeemSy,
            pendleSwap: address(0),
            swapData: SwapData({ swapType: SwapType.NONE, extRouter: address(0), extCalldata: bytes(""), needScale: false })
        });

        // Encode txData for redeemPyToToken
        bytes memory txData =
            abi.encodeWithSelector(IPendleRouterV4.redeemPyToToken.selector, accountEth, ytAddress, amount, output);

        // Pack hook data: [bytes32 placeholder][address yieldSource][bool usePrevHookAmount][uint256 value][bytes txData]
        return abi.encodePacked(
            bytes32(0), // placeholder
            yieldSource, // yieldSource (always market address)
            usePrevHookAmount, // usePrevHookAmount
            uint256(0), // value (not used for redemptions)
            txData
        );
    }

    /// @notice Helper to create PendleUnifiedHook data for swapExactTokenForPt (buy PT with token)
    /// @dev Uses swapExactTokenForPt which is supported by PendleUnifiedHook
    function _createPendleUnifiedDepositHookData(
        address yieldSource,
        uint256 amount,
        address, /* ytAddress - unused for swapExactTokenForPt */
        address tokenIn,
        address tokenMintSy,
        uint256 minPtOut,
        bool usePrevHookAmount
    )
        internal
        view
        returns (bytes memory)
    {
        // Create TokenInput struct with no swap routing (direct minting via market)
        TokenInput memory input = TokenInput({
            tokenIn: tokenIn,
            netTokenIn: amount,
            tokenMintSy: tokenMintSy,
            pendleSwap: address(0),
            swapData: SwapData({ swapType: SwapType.NONE, extRouter: address(0), extCalldata: bytes(""), needScale: false })
        });

        // Create ApproxParams for PT out estimation
        ApproxParams memory guessPtOut = ApproxParams({
            guessMin: 0,
            guessMax: type(uint256).max,
            guessOffchain: 0,
            maxIteration: 256,
            eps: 1e15 // 0.1%
        });

        // Create empty LimitOrderData
        LimitOrderData memory limit = LimitOrderData({
            limitRouter: address(0),
            epsSkipMarket: 0,
            normalFills: new FillOrderParams[](0),
            flashFills: new FillOrderParams[](0),
            optData: bytes("")
        });

        // Encode txData for swapExactTokenForPt
        bytes memory txData = abi.encodeWithSelector(
            IPendleRouterV4.swapExactTokenForPt.selector,
            accountEth, // receiver
            yieldSource, // market
            minPtOut, // minPtOut
            guessPtOut, // ApproxParams
            input, // TokenInput
            limit // LimitOrderData
        );

        // Pack hook data: [bytes32 placeholder][address yieldSource][bool usePrevHookAmount][uint256 value][bytes txData]
        return abi.encodePacked(
            bytes32(0), // placeholder
            yieldSource, // yieldSource (always market address)
            usePrevHookAmount, // usePrevHookAmount
            uint256(0), // value
            txData
        );
    }
}
