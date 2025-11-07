// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";

// external
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// superform
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ApproveAndSwapOdosV2Hook } from "@superform-v2-core/src/hooks/swappers/odos/ApproveAndSwapOdosV2Hook.sol";
import { MockPendleRouter } from "@superform-v2-core/test/mocks/MockPendleRouter.sol";
import { MockPendleMarket } from "@superform-v2-core/test/mocks/MockPendleMarket.sol";
import { PendleRouterSwapHook } from "@superform-v2-core/src/hooks/swappers/pendle/PendleRouterSwapHook.sol";
import { PendleRouterRedeemHook } from "@superform-v2-core/src/hooks/swappers/pendle/PendleRouterRedeemHook.sol";
import { IPendleMarket } from "@superform-v2-core/src/vendor/pendle/IPendleMarket.sol";
import { IStandardizedYield } from "@superform-v2-core/src/vendor/pendle/IStandardizedYield.sol";
import {
    IPendleRouterV4,
    LimitOrderData,
    FillOrderParams,
    TokenInput,
    TokenOutput,
    ApproxParams,
    SwapType,
    SwapData
} from "@superform-v2-core/src/vendor/pendle/IPendleRouterV4.sol";

/// @notice Separate test file for Pendle integration tests
/// @dev We warp time in setUp to before the Pendle market expiry to avoid MarketExpired errors
contract SuperVaultPendleTest is BaseSuperVaultTest {
    using Math for uint256;

    // Odos and Pendle addresses
    address public odosRouterAddress;
    address public pendlePufETHMarket;
    
    // Token addresses
    IERC20 public eUSDe;
    IERC20 public yt_eUSDe;
    IERC20 public pt_eUSDe;
    
    // Hooks
    PendleRouterSwapHook public pendleRouterSwapHook;
    address public approveAndSwapOdosHookAddress;

    // Struct to avoid stack too deep in tests
    struct PendleTestVars {
        address sy;
        address pt;
        address yt;
        address[] syTokenIns;
        address approveHook;
        uint256 ptBalance;
        uint256 wethBalanceBefore;
        uint256 wethBalanceAfter;
        uint256 ptBalanceAfter;
    }

    function setUp() public override {
        // Fork at a specific block where Pendle market was still active
        // pufETH market 0x58612beB0e8a126735b19BB222cbC7fC2C162D2a expires around Nov 2024
        // Fork at block 21000000 (Oct 2024) - close to expiry but before it
        vm.createSelectFork(vm.envString(ETHEREUM_RPC_URL_KEY), 21_000_000);

        super.setUp();

        updateTestVaultPredictions();
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Setup for real Pendle and Odos integration
        odosRouterAddress = CHAIN_1_ODOS_ROUTER;
        pendlePufETHMarket = 0x58612beB0e8a126735b19BB222cbC7fC2C162D2a;

        // Initialize Pendle token addresses
        // Token Out = Token Redeem Sy = Ethena USDe
        eUSDe = IERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
        // YT Ethena USDe
        yt_eUSDe = IERC20(0x733Ee9Ba88f16023146EbC965b7A1Da18a322464);
        // PT Ethena USDe
        pt_eUSDe = IERC20(0x917459337CaAC939D41d7493B3999f571D20D667);

        // Deploy hooks
        pendleRouterSwapHook = new PendleRouterSwapHook(CHAIN_1_PENDLE_ROUTER);
        approveAndSwapOdosHookAddress = address(new ApproveAndSwapOdosV2Hook(odosRouterAddress));
        
        // Register hooks
        superGovernor.registerHook(approveAndSwapOdosHookAddress);
        superGovernor.registerHook(address(pendleRouterSwapHook));
    }

    function test_PendleRouterSwap() public {
        uint256 amount = 100e6;

        // Direct deposit
        _deposit(amount);

        // Verify deposit state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), amount, "Wrong strategy balance");

        address approveHook = _getHookAddress(ETH, APPROVE_ERC20_HOOK_KEY);

        IPendleMarket _market = IPendleMarket(pendlePufETHMarket);

        (address sy, address pt,) = _market.readTokens();
        // note syTokenIns [1] is WETH for this SY, which should have high liquidity
        address[] memory syTokenIns = IStandardizedYield(sy).getTokensIn();
        uint256 balance = IERC20(pt).balanceOf(accountEth);
        assertEq(balance, 0);

        address[] memory hookAddresses_ = new address[](2);
        hookAddresses_[0] = address(approveHook);
        hookAddresses_[1] = address(pendleRouterSwapHook);

        bytes[] memory hookData = new bytes[](2);
        hookData[0] = _createApproveHookData(CHAIN_1_USDC, CHAIN_1_PENDLE_ROUTER, amount, false);
        hookData[1] = _createPendleRouterSwapHookDataWithOdos(
            pendlePufETHMarket, address(strategy), false, 0, false, amount, CHAIN_1_USDC, syTokenIns[1]
        );

        // Mock the Odos router to perform a 1:1 swap (USDC amount in -> equivalent WETH amount out)
        // The swap happens inside Pendle's swapExactTokenForPt
        vm.mockCall(
            CHAIN_1_ODOS_ROUTER,
            abi.encodeWithSignature("swapCompact()"),
            abi.encode(0)
        );
        // Deal WETH to Pendle Router (not swap contract) to simulate successful Odos swap
        // Pendle Router checks its own balance after the swap
        deal(syTokenIns[1], CHAIN_1_PENDLE_ROUTER, amount * 1e12); // Convert USDC 6 decimals to WETH 18 decimals

        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hookAddresses_,
                hookCalldata: hookData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: new bytes32[][](2),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();

        // Verify PT tokens received
        uint256 ptBalance = IERC20(pt).balanceOf(address(strategy));
        assertGt(ptBalance, 0, "No PT tokens received");
    }

    function test_PendleRouterSwapAndRedeem() public {
        uint256 amount = 100e6;
        PendleTestVars memory vars;

        // Direct deposit
        _deposit(amount);

        // Verify deposit state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), amount, "Wrong strategy balance");

        vars.approveHook = _getHookAddress(ETH, APPROVE_ERC20_HOOK_KEY);

        IPendleMarket _market = IPendleMarket(pendlePufETHMarket);

        (vars.sy, vars.pt, vars.yt) = _market.readTokens();
        // note syTokenIns [1] is WETH for this SY, which should have high liquidity
        vars.syTokenIns = IStandardizedYield(vars.sy).getTokensIn();
        // Get valid output tokens for redeeming SY
        address[] memory syTokensOut = IStandardizedYield(vars.sy).getTokensOut();
        address pufETH = syTokensOut[0]; // The only valid token out is pufETH
        uint256 balance = IERC20(vars.pt).balanceOf(accountEth);
        assertEq(balance, 0);

        address[] memory hookAddresses_ = new address[](2);
        hookAddresses_[0] = address(vars.approveHook);
        hookAddresses_[1] = address(pendleRouterSwapHook);

        bytes[] memory hookData = new bytes[](2);
        hookData[0] = _createApproveHookData(CHAIN_1_USDC, CHAIN_1_PENDLE_ROUTER, amount, false);
        hookData[1] = _createPendleRouterSwapHookDataWithOdos(
            pendlePufETHMarket, address(strategy), false, 0, false, amount, CHAIN_1_USDC, vars.syTokenIns[1]
        );

        // Mock the Odos router to perform a 1:1 swap (USDC amount in -> equivalent WETH amount out)
        // The swap happens inside Pendle's swapExactTokenForPt
        vm.mockCall(
            CHAIN_1_ODOS_ROUTER,
            abi.encodeWithSignature("swapCompact()"),
            abi.encode(0)
        );
        // Deal WETH to Pendle Router (not swap contract) to simulate successful Odos swap
        // Pendle Router checks its own balance after the swap
        deal(vars.syTokenIns[1], CHAIN_1_PENDLE_ROUTER, amount * 1e12); // Convert USDC 6 decimals to WETH 18 decimals

        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hookAddresses_,
                hookCalldata: hookData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: new bytes32[][](2),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();

        // Verify PT tokens received
        vars.ptBalance = IERC20(vars.pt).balanceOf(address(strategy));
        assertGt(vars.ptBalance, 0, "No PT tokens received");

        // Now swap PT back to underlying token using Pendle swap hook
        // Warp forward past maturity (pufETH market expires around Nov 2024, we're at Oct 2024)
        vm.warp(block.timestamp + 60 days);

        // Setup swap PT back to token execution
        address[] memory swapBackHookAddresses = new address[](2);
        swapBackHookAddresses[0] = address(vars.approveHook);
        swapBackHookAddresses[1] = address(pendleRouterSwapHook);

        bytes[] memory swapBackHookData = new bytes[](2);
        swapBackHookData[0] = _createApproveHookData(vars.pt, CHAIN_1_PENDLE_ROUTER, vars.ptBalance, false);
        swapBackHookData[1] = _createPendleRouterSwapHookDataPtToToken(
            pendlePufETHMarket,
            address(strategy),
            false, // usePrevHookAmount
            0, // value
            vars.ptBalance,
            pufETH // tokenOut = pufETH (the only valid tokenOut for this SY)
        );

        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        uint256 pufETHBalanceBefore = IERC20(pufETH).balanceOf(address(strategy));

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: swapBackHookAddresses,
                hookCalldata: swapBackHookData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: new bytes32[][](2),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();

        // Verify PT swapped back and pufETH received
        vars.ptBalanceAfter = IERC20(vars.pt).balanceOf(address(strategy));
        uint256 pufETHBalanceAfter = IERC20(pufETH).balanceOf(address(strategy));
        
        assertEq(vars.ptBalanceAfter, 0, "PT tokens not fully swapped");
        assertGt(pufETHBalanceAfter, pufETHBalanceBefore, "No pufETH received from PT swap");
    }

    /*//////////////////////////////////////////////////////////////
                     INTERNAL
    //////////////////////////////////////////////////////////////*/
    function _createPendleRouterSwapHookDataWithOdos(
        address market_,
        address account_,
        bool usePrevHookAmount_,
        uint256 value_,
        bool ptToToken_,
        uint256 amount_,
        address tokenIn_,
        address tokenMint_
    )
        internal
        returns (bytes memory)
    {
        bytes memory pendleTxData;
        if (!ptToToken_) {
            // call Odos swapAPI to get the calldata
            // note, odos swap receiver has to be pendle router
            bytes memory odosCalldata =
                _createOdosSwapCalldataRequest(tokenIn_, tokenMint_, amount_, CHAIN_1_PENDLE_ROUTER);

            decodeOdosSwapCalldata(odosCalldata);

            pendleTxData = _createTokenToPtPendleTxDataWithOdos(
                market_, account_, tokenIn_, 1, amount_, tokenMint_, odosCalldata, CHAIN_1_PENDLE_SWAP, CHAIN_1_ODOS_ROUTER
            );
        } else {
            revert("Not implemented");
        }
        return abi.encodePacked(
            bytes32(bytes("")), // yieldSourceOracleId
            market_,            // yieldSource
            usePrevHookAmount_,
            value_,
            pendleTxData
        );
    }

    function _createPendleRedeemHookData(
        uint256 amount,
        address yt,
        address pt,
        address tokenOut,
        address tokenRedeemSy,
        uint256 minTokenOut,
        bool usePrevHookAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            amount,
            yt,
            pt,
            tokenOut,
            minTokenOut,
            usePrevHookAmount,
            abi.encode(_createPendleRedeemTokenOutput(tokenOut, minTokenOut, tokenRedeemSy))
        );
    }

    function _createPendleRedeemTokenOutput(
        address tokenOut,
        uint256 minTokenOut,
        address tokenRedeemSy
    )
        internal
        pure
        returns (TokenOutput memory)
    {
        return TokenOutput({
            tokenOut: tokenOut,
            minTokenOut: minTokenOut,
            tokenRedeemSy: tokenRedeemSy,
            pendleSwap: address(0),
            swapData: SwapData({ swapType: SwapType.NONE, extRouter: address(0), extCalldata: bytes(""), needScale: false })
        });
    }

    function _createTokenToPtPendleTxDataWithOdos(
        address market_,
        address receiver_,
        address tokenIn_,
        uint256 minPtOut_,
        uint256 amount_,
        address tokenMintSY_,
        bytes memory odosCalldata_,
        address pendleSwap_,
        address odosRouter_
    )
        internal
        pure
        returns (bytes memory pendleTxData)
    {
        // no limit order needed
        LimitOrderData memory limit = LimitOrderData({
            limitRouter: address(0),
            epsSkipMarket: 0,
            normalFills: new FillOrderParams[](0),
            flashFills: new FillOrderParams[](0),
            optData: "0x"
        });

        // TokenInput
        TokenInput memory input = TokenInput({
            tokenIn: tokenIn_,
            netTokenIn: amount_,
            tokenMintSy: tokenMintSY_,
            pendleSwap: pendleSwap_,
            swapData: SwapData({
                extRouter: odosRouter_,
                extCalldata: odosCalldata_,
                needScale: false,
                swapType: SwapType.ODOS
            })
        });

        // Approximation parameters for PT output
        // Using wide bounds since we're swapping USDC (6 decimals) to PT tokens (18 decimals)
        ApproxParams memory guessPtOut = ApproxParams({
            guessMin: 1,
            guessMax: 1e24,
            guessOffchain: 1e18,
            maxIteration: 30,
            eps: 10_000_000_000_000
        });

        pendleTxData = abi.encodeWithSelector(
            IPendleRouterV4.swapExactTokenForPt.selector, receiver_, market_, minPtOut_, guessPtOut, input, limit
        );
    }

    function _createOdosSwapCalldataRequest(
        address tokenIn_,
        address tokenOut_,
        uint256 amount_,
        address receiver_
    )
        internal
        returns (bytes memory)
    {
        // get pathId
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: tokenIn_, amount: amount_ });
        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: tokenOut_, proportion: 1 });
        string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, receiver_, ETH, true);

        // get assemble data
        string memory swapCompactData = surlCallAssemble(pathId, receiver_);
        return fromHex(swapCompactData);
    }

    function _createPendleRouterSwapHookDataPtToToken(
        address market_,
        address account_,
        bool usePrevHookAmount_,
        uint256 value_,
        uint256 amount_,
        address tokenOut_
    )
        internal
        pure
        returns (bytes memory)
    {
        // Create TokenOutput struct for PT to token swap
        TokenOutput memory output = TokenOutput({
            tokenOut: tokenOut_,
            minTokenOut: 1,
            tokenRedeemSy: tokenOut_,
            pendleSwap: address(0),
            swapData: SwapData({
                swapType: SwapType.NONE,
                extRouter: address(0),
                extCalldata: bytes(""),
                needScale: false
            })
        });

        // Encode swapExactPtForToken call
        bytes memory pendleTxData = abi.encodeWithSelector(
            IPendleRouterV4.swapExactPtForToken.selector,
            account_, // receiver
            market_, // market
            amount_, // exactPtIn
            output, // output
            LimitOrderData({
                limitRouter: address(0),
                epsSkipMarket: 0,
                normalFills: new FillOrderParams[](0),
                flashFills: new FillOrderParams[](0),
                optData: "0x"
            })
        );

        return abi.encodePacked(
            bytes32(bytes("")), // yieldSourceOracleId
            market_,            // yieldSource
            usePrevHookAmount_,
            value_,
            pendleTxData
        );
    }
}
