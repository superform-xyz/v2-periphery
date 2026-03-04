// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { OdosAPIParser } from "@superform-v2-core/test/utils/parsers/OdosAPIParser.sol";
import { AcrossV3Helper } from "@pigeon/across/AcrossV3Helper.sol";

/// @title SuperBankSwapIntegration
/// @notice Integration test: SuperBank.executeHooks swaps USDC -> UP on Base via real Odos router
/// @dev Uses production-deployed contracts on a Base fork. No mocks. Odos quote fetched via surl.
///
///      Underlying swap routing (USDC -> UP on Base):
///      Odos aggregates across Base DEXs. The primary liquidity for UP lives on Aerodrome:
///        - Aerodrome UP/USDC pool: 0xb1857B20d91c216f51656B63081f35C7cD0A489d (~$240k liq)
///        - Aerodrome UP/cbBTC pool: 0x1E726F3177a933cc134Fd0ea7C326EAb270E0137 (~$512k liq)
///      For a 100 USDC swap, Odos typically routes directly through the Aerodrome UP/USDC pool.
///      Larger swaps may split across the cbBTC pool or other minor pools (Uniswap v4, PancakeSwap).
///
/// Run:
///   forge test --match-contract SuperBankSwapIntegration -vvv
contract SuperBankSwapIntegration is Test, OdosAPIParser {
    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (BASE MAINNET)
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // v2-core prod hooks
    address constant APPROVE_ERC20_HOOK = 0x8b789980dc6cC7d88E30C442D704646ff7F6d306;
    address constant SWAP_ODOS_V2_HOOK = 0x074F9973EBfB050D7abc75a5cB03491d675DA843;


    // Tokens
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant UP = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;

    // Odos router (DEX aggregator — routes through Aerodrome, Uniswap v4, PancakeSwap, etc.)
    address constant ODOS_ROUTER = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1;

    // Primary liquidity pools for UP on Base (Aerodrome)
    // Odos routes USDC->UP primarily through these Aerodrome pools
    address constant AERODROME_UP_USDC_POOL = 0xb1857B20d91c216f51656B63081f35C7cD0A489d;
    address constant AERODROME_UP_CBBTC_POOL = 0x1E726F3177a933cc134Fd0ea7C326EAb270E0137;

    // Chain
    uint256 constant BASE_CHAIN_ID = 8453;
    uint256 constant ETH_CHAIN_ID = 1;

    // ETH mainnet addresses (for cross-chain bridge test)
    address constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ACROSS_SEND_FUNDS_HOOK_ETH = 0x39962bE24192d0d6B6e3a19f332e3c825604d16A;
    address constant ETH_SPOKE_POOL = 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address constant BASE_SPOKE_POOL = 0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64;

    // ETH mainnet addresses (for ApproveAndSwapOdosV2Hook test)
    address constant ETH_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ETH_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant APPROVE_AND_SWAP_ODOS_V2_HOOK = 0xe138e0750a1311580A2c842FF10a9824Fc2C5217;
    address constant ETH_ODOS_ROUTER = 0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559;

    // Contracts
    SuperBank superBank;
    SuperGovernor superGovernor;

    // ═══════════════════════════════════════════════════════════════════
    //                              SETUP
    // ═══════════════════════════════════════════════════════════════════

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        superBank = SuperBank(payable(SUPER_BANK));
        superGovernor = SuperGovernor(SUPER_GOVERNOR_ADDR);

        // Grant this test contract GOVERNOR_ROLE and BANK_MANAGER_ROLE via direct storage writes
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        // Sanity checks
        assertTrue(superGovernor.hasRole(superGovernor.GOVERNOR_ROLE(), address(this)), "GOVERNOR_ROLE not granted");
        assertTrue(
            superGovernor.hasRole(superGovernor.BANK_MANAGER_ROLE(), address(this)), "BANK_MANAGER_ROLE not granted"
        );

        // Register hooks (idempotent — no-op if already registered)
        superGovernor.registerHook(APPROVE_ERC20_HOOK);
        superGovernor.registerHook(SWAP_ODOS_V2_HOOK);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                              TEST
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: deal USDC to SuperBank, fetch live Odos quote, approve + swap, receive UP
    /// @dev Odos aggregates the swap — under the hood it routes through Aerodrome pools on Base.
    ///      For 100 USDC, expect a direct route via the Aerodrome UP/USDC pool.
    function test_executeHooks_swapUSDCtoUP() public {
        uint256 swapAmount = 100e6; // 100 USDC

        // 1. Fund SuperBank with USDC
        deal(USDC, SUPER_BANK, swapAmount);
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), swapAmount);

        // 2. Fetch live Odos quote via surl (no external scripts needed)
        //    Odos finds the best route across Base DEXs. For USDC->UP this is primarily Aerodrome.
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: USDC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: UP, proportion: 1 });

        string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false);
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        // Log Aerodrome pool state before swap to confirm routing
        uint256 poolUsdcBefore = IERC20(USDC).balanceOf(AERODROME_UP_USDC_POOL);
        uint256 poolUpBefore = IERC20(UP).balanceOf(AERODROME_UP_USDC_POOL);
        console2.log("Aerodrome UP/USDC pool USDC before:", poolUsdcBefore);
        console2.log("Aerodrome UP/USDC pool UP before:", poolUpBefore);

        // 3. Encode hook data
        bytes memory approveData = _encodeApproveHookData(USDC, ODOS_ROUTER, swapAmount, false);

        bytes memory swapData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin - decoded.tokenInfo.outputMin * 1e4 / 1e5, // extra slippage buffer
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // 4. Register merkle roots (single-leaf trees, 7-day timelock each)
        _registerMerkleRoot(APPROVE_ERC20_HOOK, approveData);
        _registerMerkleRoot(SWAP_ODOS_V2_HOOK, swapData);

        // 5. Execute hooks via SuperBank
        uint256 upBefore = IERC20(UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildExecutionData(APPROVE_ERC20_HOOK, SWAP_ODOS_V2_HOOK, approveData, swapData)
        );

        uint256 upAfter = IERC20(UP).balanceOf(SUPER_BANK);
        uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);

        // 6. Assertions
        assertEq(usdcAfter, 0, "All USDC should be consumed by the swap");
        assertGt(upAfter - upBefore, 0, "SuperBank should have received UP tokens");

        console2.log("Swap result: %d USDC -> %d UP", swapAmount, upAfter - upBefore);

        // 7. Log Aerodrome pool state after swap to confirm routing through it
        uint256 poolUsdcAfter = IERC20(USDC).balanceOf(AERODROME_UP_USDC_POOL);
        uint256 poolUpAfter = IERC20(UP).balanceOf(AERODROME_UP_USDC_POOL);
        console2.log("Aerodrome UP/USDC pool USDC after:", poolUsdcAfter);
        console2.log("Aerodrome UP/USDC pool UP after:", poolUpAfter);

        // If Odos routed through Aerodrome UP/USDC, pool USDC should increase and pool UP should decrease
        if (poolUsdcAfter > poolUsdcBefore) {
            console2.log("Confirmed: Odos routed through Aerodrome UP/USDC pool");
            console2.log("  Pool USDC delta: +%d", poolUsdcAfter - poolUsdcBefore);
            console2.log("  Pool UP delta: -%d", poolUpBefore - poolUpAfter);
        } else {
            console2.log("Odos used alternative routing (not directly through Aerodrome UP/USDC pool)");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //              TEST WITH PRODUCTION MERKLE TREES
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Same USDC->UP swap flow but using production-generated merkle trees.
    /// @dev Uses ApproveERC20Hook + SwapOdosV2Hook with production roots from
    ///      superman/deployments/superbank/generated/prod/8453/
    ///
    ///      ApproveERC20Hook (0x8b789980...): root 0x4babad82..., leaf 32 (USDC, spender=Odos Router)
    ///      SwapOdosV2Hook  (0x074F9973...): root 0x1f04c759..., leaf 0  (executor=Odos Router)
    function test_executeHooks_swapUSDCtoUP_withProductionMerkleTree() public {
        uint256 swapAmount = 100e6; // 100 USDC

        // 1. Fund SuperBank with USDC
        deal(USDC, SUPER_BANK, swapAmount);
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), swapAmount);

        // 2. Fetch live Odos quote via surl
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: USDC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: UP, proportion: 1 });

        string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false);
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        // 3. Encode hook data
        bytes memory approveData = _encodeApproveHookData(USDC, ODOS_ROUTER, swapAmount, false);
        bytes memory swapData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin - decoded.tokenInfo.outputMin * 1e4 / 1e5, // extra slippage buffer
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // 4. Set production merkle roots
        //    ApproveERC20Hook: hook_0x8b789980...json (65 leaves)
        _setMerkleRoot(APPROVE_ERC20_HOOK, 0x4babad826da43858847227ec8c52ddfe054b5d75614631e8ec1860791c330e4e);
        //    SwapOdosV2Hook: hook_0x074f9973...json (4 leaves)
        _setMerkleRoot(SWAP_ODOS_V2_HOOK, 0xa5317c914c8c430ea5f6864653286b1563ca2730c223e22be9fe98bb7c6a0719);

        // 5. Execute with production proofs (swap proof selected dynamically based on Odos executor)
        uint256 upBefore = IERC20(UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildExecutionDataWithProofs(
                APPROVE_ERC20_HOOK,
                SWAP_ODOS_V2_HOOK,
                approveData,
                swapData,
                _getBaseApproveUsdcForOdosRouterProof(),
                _getBaseSwapOdosExecutorProof(decoded.executor)
            )
        );

        uint256 upAfter = IERC20(UP).balanceOf(SUPER_BANK);
        uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);

        // 6. Assertions
        assertEq(usdcAfter, 0, "All USDC should be consumed by the swap");
        assertGt(upAfter - upBefore, 0, "SuperBank should have received UP tokens");

        console2.log("Swap result: %d USDC -> %d UP", swapAmount, upAfter - upBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              CROSS-CHAIN BRIDGE + SWAP TEST
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Bridges USDC from SuperBank on ETH to SuperBank on Base via Across, then swaps USDC→UP.
    /// @dev Multi-fork test using Pigeon (AcrossV3Helper) to simulate the cross-chain relay.
    ///      Phase 1: ETH fork — approve USDC for SpokePool + bridge via AcrossSendFundsAndExecuteOnDstHook
    ///      Phase 2: Pigeon relay — AcrossV3Helper fills the relay on Base fork
    ///      Phase 3: Base fork — approve USDC for Odos Router + swap via SwapOdosV2Hook
    ///
    ///      All hooks use production merkle trees:
    ///        ETH ApproveERC20Hook:     root 0x30325d34..., leaf 20  (USDC, spender=SpokePool)
    ///        ETH AcrossHook:           root 0x3f45dfd6..., leaf 366 (USDC ETH→USDC Base)
    ///        Base ApproveERC20Hook:    root 0x4babad82..., leaf 32  (USDC, spender=Odos Router)
    ///        Base SwapOdosV2Hook:      root 0x1f04c759..., leaf 0   (executor=Odos Router)
    function test_executeHooks_bridgeAndSwapUSDCtoUP() public {
        uint256 baseForkId = vm.activeFork();

        // Phase 1: Bridge USDC from ETH to Base
        Vm.Log[] memory logs = _bridgeUsdcFromEthToBase(100e6);

        // Phase 2: Pigeon relay
        _relayAcrossBridge(logs, baseForkId);

        // Phase 3: Swap USDC→UP on Base
        vm.selectFork(baseForkId);
        _swapUsdcToUpOnBase();
    }

    /// @dev Phase 1: On ETH fork, approve + bridge USDC to SuperBank on Base via Across.
    ///      Both hooks use production merkle trees:
    ///        Approve: root 0x30325d34..., leaf 20 (USDC, spender=SpokePool ETH)
    ///        Across:  root 0x3f45dfd6..., leaf 366 (USDC ETH→USDC Base, SuperBank recipient)
    function _bridgeUsdcFromEthToBase(uint256 bridgeAmount) internal returns (Vm.Log[] memory logs) {
        uint256 ethForkId = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        vm.selectFork(ethForkId);

        // Grant roles on ETH fork (same SuperGovernor address, different chain state)
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        // Register hooks on ETH
        superGovernor.registerHook(APPROVE_ERC20_HOOK);
        superGovernor.registerHook(ACROSS_SEND_FUNDS_HOOK_ETH);

        // Fund SuperBank on ETH with USDC
        deal(ETH_USDC, SUPER_BANK, bridgeAmount);
        assertEq(IERC20(ETH_USDC).balanceOf(SUPER_BANK), bridgeAmount, "ETH USDC not dealt");

        // Encode hook data
        bytes memory approveData = _encodeApproveHookData(ETH_USDC, ETH_SPOKE_POOL, bridgeAmount, false);
        bytes memory acrossData = _encodeAcrossHookData(
            SUPER_BANK, ETH_USDC, USDC, bridgeAmount, bridgeAmount * 99 / 100, BASE_CHAIN_ID, false, bytes("")
        );

        // Approve: production merkle root from hook_0x8b789980...json (78 leaves)
        bytes32 approveRoot = 0x30325d341c1fe0a5850533689a88da77b33931a1d223932dae7abf1c7f7a327f;
        _setMerkleRoot(APPROVE_ERC20_HOOK, approveRoot);

        // Across: production merkle root from hook_0x39962be...json (702 leaves)
        bytes32 acrossRoot = 0x3f45dfd6ac970711dff6a23c0a74ad43fb1d96e537204ecc92fb85b9398caf39;
        _setMerkleRoot(ACROSS_SEND_FUNDS_HOOK_ETH, acrossRoot);

        // Execute hooks: approve (leaf 20) + bridge (leaf 366) with production proofs
        vm.recordLogs();
        superBank.executeHooks(
            _buildExecutionDataWithProofs(
                APPROVE_ERC20_HOOK,
                ACROSS_SEND_FUNDS_HOOK_ETH,
                approveData,
                acrossData,
                _getApproveUsdcForSpokePoolProof(),
                _getUsdcEthToBaseAcrossProof()
            )
        );
        logs = vm.getRecordedLogs();

        assertEq(IERC20(ETH_USDC).balanceOf(SUPER_BANK), 0, "All ETH USDC should be consumed by the bridge");
        console2.log("Phase 1: Bridged %d USDC from ETH to Base", bridgeAmount);
    }

    /// @dev Phase 2: Relay the Across bridge via Pigeon AcrossV3Helper.
    function _relayAcrossBridge(Vm.Log[] memory logs, uint256 baseForkId) internal {
        AcrossV3Helper acrossHelper = new AcrossV3Helper();
        vm.makePersistent(address(acrossHelper));

        address relayer = makeAddr("ACROSS_RELAYER");
        vm.makePersistent(relayer);

        acrossHelper.help(
            ETH_SPOKE_POOL, BASE_SPOKE_POOL, relayer, block.timestamp, baseForkId, BASE_CHAIN_ID, ETH_CHAIN_ID, logs
        );

        console2.log("Phase 2: Pigeon relayed Across bridge to Base fork");
    }

    /// @dev Phase 3: On Base fork, approve USDC for Odos Router + swap USDC→UP using production merkle trees.
    function _swapUsdcToUpOnBase() internal {
        // Verify USDC arrived on Base SuperBank
        uint256 usdcOnBase = IERC20(USDC).balanceOf(SUPER_BANK);
        assertGt(usdcOnBase, 0, "USDC should have arrived on Base via bridge");
        console2.log("Phase 3: USDC received on Base:", usdcOnBase);

        // Fetch live Odos quote for the actual received amount
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: USDC, amount: usdcOnBase });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: UP, proportion: 1 });

        string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false);
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);

        // Encode hook data
        bytes memory approveData = _encodeApproveHookData(USDC, ODOS_ROUTER, usdcOnBase, false);
        bytes memory swapData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin - decoded.tokenInfo.outputMin * 1e4 / 1e5, // extra slippage buffer
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // Set production merkle roots
        //   ApproveERC20Hook: hook_0x8b789980...json (65 leaves)
        _setMerkleRoot(APPROVE_ERC20_HOOK, 0x4babad826da43858847227ec8c52ddfe054b5d75614631e8ec1860791c330e4e);
        //   SwapOdosV2Hook: hook_0x074f9973...json (4 leaves)
        _setMerkleRoot(SWAP_ODOS_V2_HOOK, 0xa5317c914c8c430ea5f6864653286b1563ca2730c223e22be9fe98bb7c6a0719);

        // Execute with production proofs (swap proof selected dynamically based on Odos executor)
        uint256 upBefore = IERC20(UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildExecutionDataWithProofs(
                APPROVE_ERC20_HOOK,
                SWAP_ODOS_V2_HOOK,
                approveData,
                swapData,
                _getBaseApproveUsdcForOdosRouterProof(),
                _getBaseSwapOdosExecutorProof(decoded.executor)
            )
        );

        uint256 upAfter = IERC20(UP).balanceOf(SUPER_BANK);
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), 0, "All USDC should be consumed by the swap");
        assertGt(upAfter - upBefore, 0, "SuperBank should have received UP tokens");

        console2.log("Swap result: %d USDC -> %d UP", usdcOnBase, upAfter - upBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              ETH MAINNET SWAP VIA ApproveAndSwapOdosV2Hook
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Swaps WETH→USDC on ETH mainnet SuperBank using ApproveAndSwapOdosV2Hook (single hook).
    /// @dev Uses production merkle tree from superman/deployments/superbank/generated/prod/1/
    ///      ApproveAndSwapOdosV2Hook (0xe138e075...): root 0xf1e4158b..., 2704 leaves
    ///      inspect() returns: abi.encodePacked(inputToken, inputReceiver, outputToken, ODOS_ROUTER_V2, executor)
    function test_executeHooks_swapWETHtoUSDC_withApproveAndSwap() public {
        _setupEthForkForApproveAndSwap();

        uint256 swapAmount = 0.1 ether; // 0.1 WETH
        deal(ETH_WETH, SUPER_BANK, swapAmount);
        assertEq(IERC20(ETH_WETH).balanceOf(SUPER_BANK), swapAmount);

        // Fetch live Odos quote on ETH mainnet
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: ETH_WETH, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: ETH_USDC, proportion: 1 });

        string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, SUPER_BANK, ETH_CHAIN_ID, false);
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        // Encode hook data (same layout as SwapOdosV2Hook)
        // inputReceiver from Odos (typically the executor address — where router sends tokens for routing)
        bytes memory hookData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin - decoded.tokenInfo.outputMin * 1e4 / 1e5,
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        console2.log("Odos inputReceiver:", decoded.tokenInfo.inputReceiver);

        // Execute with production proof (proof selected by inputReceiver + executor combo)
        uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                APPROVE_AND_SWAP_ODOS_V2_HOOK,
                hookData,
                _getApproveAndSwapWethToUsdcProof(decoded.tokenInfo.inputReceiver, decoded.executor)
            )
        );

        uint256 usdcAfter = IERC20(ETH_USDC).balanceOf(SUPER_BANK);
        uint256 wethAfter = IERC20(ETH_WETH).balanceOf(SUPER_BANK);

        assertEq(wethAfter, 0, "All WETH should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    /// @notice Swaps WBTC→USDC on ETH mainnet SuperBank using ApproveAndSwapOdosV2Hook (single hook).
    /// @dev Same as WETH test but with WBTC (8 decimals).
    function test_executeHooks_swapWBTCtoUSDC_withApproveAndSwap() public {
        _setupEthForkForApproveAndSwap();

        uint256 swapAmount = 1e6; // 0.01 WBTC (8 decimals)
        deal(ETH_WBTC, SUPER_BANK, swapAmount);
        assertEq(IERC20(ETH_WBTC).balanceOf(SUPER_BANK), swapAmount);

        // Fetch live Odos quote on ETH mainnet
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: ETH_WBTC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: ETH_USDC, proportion: 1 });

        string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, SUPER_BANK, ETH_CHAIN_ID, false);
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);
        console2.log("Odos inputReceiver:", decoded.tokenInfo.inputReceiver);

        // Encode hook data
        bytes memory hookData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin - decoded.tokenInfo.outputMin * 1e4 / 1e5,
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // Execute with production proof
        uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                APPROVE_AND_SWAP_ODOS_V2_HOOK,
                hookData,
                _getApproveAndSwapWbtcToUsdcProof(decoded.tokenInfo.inputReceiver, decoded.executor)
            )
        );

        uint256 usdcAfter = IERC20(ETH_USDC).balanceOf(SUPER_BANK);
        uint256 wbtcAfter = IERC20(ETH_WBTC).balanceOf(SUPER_BANK);

        assertEq(wbtcAfter, 0, "All WBTC should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d WBTC -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    /// @dev Sets up ETH mainnet fork for ApproveAndSwapOdosV2Hook tests.
    function _setupEthForkForApproveAndSwap() internal {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(APPROVE_AND_SWAP_ODOS_V2_HOOK);

        // ApproveAndSwapOdosV2Hook: production merkle root (10816 leaves)
        _setMerkleRoot(
            APPROVE_AND_SWAP_ODOS_V2_HOOK,
            0xaced7564db364dfe8f300c8eebe0cdfab8e4daaea153a73ba48e86498195c619
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Returns the production merkle proof for USDC + Odos Router leaf (index 32) in the
    ///      ApproveERC20Hook tree on Base.
    ///      Source: hook_0x8b789980dc6cc7d88e30c442d704646ff7f6d306.json (chain 8453)
    ///      Args: token=USDC (0x833589fC...), spender=Odos Router V2 (0x19cEeAd7...)
    function _getBaseApproveUsdcForOdosRouterProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0x92c51b1be8863998aa297cf694f46e298a96694f9abc79a9ffb57d527181f2ba;
        proof[1] = 0x62f88cfd69237b7406c0b73a65f8356be4e4e342a40c4ca89c3642e1cbc99a5c;
        proof[2] = 0x153c4ac519759d33b5eea18953fa859a628ebf0ff7565333ee875aeb6c77ae86;
        proof[3] = 0x9f156bc9eaafd618e89fd31b1f0a86f5b6631ac5d60dad794d393d9ca737861c;
        proof[4] = 0xffcf13b1670a12ef50a6e9daaa3358799d9a05e9f51c57e1f27c85e4df2a4d9d;
        proof[5] = 0xd6b2acbc681dd6407a4fe10298e1534bf1c728c151d379c13b13eb7415f53167;
        proof[6] = 0xfc4c551dfd1d006b73230db4e7f5fdd90a74a48a13d13ca624a92df0da6f24b2;
    }

    /// @dev Returns the production merkle proof for the given executor in the SwapOdosV2Hook tree on Base.
    ///      Source: hook_0x074f9973ebfb050d7abc75a5cb03491d675da843.json (chain 8453, 4 leaves)
    ///      Odos can return different executors per quote, so the proof is selected dynamically.
    function _getBaseSwapOdosExecutorProof(address executor) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (executor == 0x19cEeAd7105607Cd444F5ad10dd51356436095a1) {
            // Leaf 0: Odos Router V2
            proof[0] = 0x83f1ab11e5deaa03b7cfc9574a037a510ad4759d278f287925c3fd113f6cc126;
            proof[1] = 0xcf02465c440da38fcfe07b2cc94a632c3b04471f14a2452450f3e7e3c4c58f84;
        } else if (executor == 0xbF44De8fc9EEEED8615b0b3bc095CB0ddef35e09) {
            // Leaf 1
            proof[0] = 0x822415c9b9d0f04cdb8d7850763588d2590f44ed2e074ac069d175202f9f584b;
            proof[1] = 0xcf02465c440da38fcfe07b2cc94a632c3b04471f14a2452450f3e7e3c4c58f84;
        } else if (executor == 0x6131B5fae19EA4f9D964eAc0408E4408b66337b5) {
            // Leaf 2
            proof[0] = 0xda2c835670e3df155414b4f235d43561fc870de2160a43846dd89ee4c7cfed2f;
            proof[1] = 0x287f9b6b4fe1b8c920bbe63eb8bf732f5b2dbe9e00d381dcf0d0675d5f23ebaa;
        } else if (executor == 0xd4F480965D2347d421F1bEC7F545682E5Ec2151D) {
            // Leaf 3
            proof[0] = 0xd2705c4c0bb867a7e891f71cd74abdd001cbb2ce530aadc4f43c5b49163d321c;
            proof[1] = 0x287f9b6b4fe1b8c920bbe63eb8bf732f5b2dbe9e00d381dcf0d0675d5f23ebaa;
        } else {
            revert("Unknown Odos executor - not in SwapOdosV2Hook tree");
        }
    }

    /// @dev Returns the production merkle proof for approve USDC for SpokePool ETH (leaf index 20)
    ///      in the ApproveERC20Hook tree on ETH.
    ///      Source: hook_0x8b789980dc6cc7d88e30c442d704646ff7f6d306.json
    ///      Args: token=ETH USDC, spender=ETH SpokePool (0x5c7BCd6E...)
    function _getApproveUsdcForSpokePoolProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0x473a3d510eea0ef3fb57fa85fde3a5c7a215379e4631ac6921d433b089f12a14;
        proof[1] = 0xc2afa7f5c2689267d678811dffee3f2b7daf35f8420079737fb64fe9cd6da5a5;
        proof[2] = 0x00f15ebe473ec10bca8ef807a320fe8addc9a811c4d7947e914d409dd7459e62;
        proof[3] = 0x69d615c4cd3f4660f563dac3a35652e1f31aecd68ed77983b305e677ccfe7725;
        proof[4] = 0x266bc5fb136822a47eeaf8d2197f891faaec75382234c2c65cbb7c0c79f6e30b;
        proof[5] = 0x79047255bef793b6c290e8d90a46383a33c59b925f337822b3450b485cd93dfa;
        proof[6] = 0x9a900d6b74af1c1a4fc702346b963062b66bb84c4d3717eba2e17757b7f3dbe0;
    }

    /// @dev Returns the production merkle proof for USDC ETH→USDC Base leaf (index 366) in the
    ///      AcrossSendFundsAndExecuteOnDstHook tree on ETH.
    ///      Source: hook_0x39962be24192d0d6b6e3a19f332e3c825604d16a.json
    ///      Args: recipient=SuperBank, inputToken=ETH USDC, outputToken=Base USDC, exclusiveRelayer=0x0
    function _getUsdcEthToBaseAcrossProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](10);
        proof[0] = 0x839a3178c2e735f6bcc0b7681a7de0dfc78dc529b6b198e0e9bcb5b42ce69242;
        proof[1] = 0xfbb24f1688958c2d6de0cad10d00a96eada65c382736dd02fde4985efeb75cba;
        proof[2] = 0x838dc2a774084ef44c932c00973ad38217698428c964c8c1a0aac7af5bc2af6f;
        proof[3] = 0xf0f7a59fc67403fc2653dad49858f6f0a696f348f4811a4c6870a5378e6b8f4b;
        proof[4] = 0xaaad529b7acc11f676a6fb9bea537f31640b9791c4ce10347ec2130825fb4088;
        proof[5] = 0xdf0f3b9c65a242f8befcddf7f32fe1e841e1023eba64d1ff1ac657bdd4274a64;
        proof[6] = 0x56aa91aa7ccfdbd010797bbbfcb6a41c266ba64b101de06d47b234b30d802375;
        proof[7] = 0xc4a9ad9cd18708394cf1435a50d14821086838040f058b661202961b223d1a4e;
        proof[8] = 0x1025aeaa46830ad674cf0d34ed425bfd481113edfeb36dd33cbccb2ced327736;
        proof[9] = 0x9e2e9e759cb239f75211c1dca8325051fa7a2dcef4c77803170bb0aea301c269;
    }

    /// @dev Returns the production merkle proof for WETH→USDC swap via ApproveAndSwapOdosV2Hook on ETH.
    ///      Source: hook_0xe138e0750a1311580a2c842ff10a9824fc2c5217.json (chain 1, 10816 leaves)
    ///      Leaf args: tokenIn=WETH, inputReceiver=dynamic, tokenOut=USDC, odosRouter=0xCf55..., executor=dynamic
    function _getApproveAndSwapWethToUsdcProof(address inputReceiver, address executor)
        internal
        pure
        returns (bytes32[] memory proof)
    {
        bytes32 key = keccak256(abi.encodePacked(inputReceiver, executor));

        if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 443
            proof = new bytes32[](14);
            proof[0] = 0x0a881e4e56fd53f2776d479d6c5b154165b34560f611783f8c351ebf618e2f43;
            proof[1] = 0x62fd167b2feead08dfa66d6748e054c5941aeb46bbfed8aab3690b1cba069109;
            proof[2] = 0x2cb21601eebcc3d02bc4ab15dae1dcbfb1e70518d4a6346bb9c813bf7a4337ed;
            proof[3] = 0xdc2970451b22f75b899793623bca7391248d8aa147485fe9bbee7fec8a187779;
            proof[4] = 0xbcabc418a2876056d8b074ab9103f3f9d0a59847de35c364fa96e5a6614dfcdd;
            proof[5] = 0xe3386e538ca07abcef55486906a829c185183928cfe64e033e4828ba1cc62cc4;
            proof[6] = 0xe95009a0da4729c16a3214b252e960b7dd433888c6567115af89e678e7fb6fa2;
            proof[7] = 0xd9c2e846e9c164373630ed6019b21fa0f54e5b2fb503f543784572e72b86436b;
            proof[8] = 0xe546751b12fd9ca7e5802a2d7e97a1325dee325940b2bb03828084a50ef037bd;
            proof[9] = 0xb6981693b12bfa78611a5c331a005ab1e15070bebba596227cc5f4916c93a48f;
            proof[10] = 0xfff7d53569dc7d42ced0154e060639d02e83de074788948314afdc2b1415f21d;
            proof[11] = 0xbb74b4926304fbfc1fe5c988c794ca59576dead53b83d6ea2907ac8469731de7;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 649
            proof = new bytes32[](14);
            proof[0] = 0x0efe7d4986ce96cc1bd9e94945fddc93b4a3f81e82bdbb048385752d7525fff9;
            proof[1] = 0x6e551810dadd69a217ac214555b52afa8e1a3e81e62bbd31a1447d21d8e6cea1;
            proof[2] = 0x14a121d92d106b4ff3fe9c24cca437216c83dfe75a10448ab3bb0087b0bd254d;
            proof[3] = 0x481532a1657005dc52c607f2f64f613e34869ff0d8415d94560c4f230ab659d9;
            proof[4] = 0x40b171c2b9cafd4d076dd43672f3d9052aa899c0b95efb710efb4c3b7b8157c8;
            proof[5] = 0xad5837c143cfd593f277808b211e0a10e822ee6f25499a8d9d13f495abfc08c6;
            proof[6] = 0xa7993472df55807e95440ba94788672c8634b295ab3372db327d1023c7e781eb;
            proof[7] = 0x8487f907d1e5e873ffbde938870d3340992fcfa1641ae314c6aa89dde3cc612b;
            proof[8] = 0xa681ab1ba3f92b315d13c4074f9877e1e9a9790737049794d38ad93750979936;
            proof[9] = 0x1fe067a9bc5be039f525a2f112bda908dd1fe7c3359faa10abb2c10b7c49ec0f;
            proof[10] = 0xfff7d53569dc7d42ced0154e060639d02e83de074788948314afdc2b1415f21d;
            proof[11] = 0xbb74b4926304fbfc1fe5c988c794ca59576dead53b83d6ea2907ac8469731de7;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 1029
            proof = new bytes32[](14);
            proof[0] = 0x17f9e3d84a24c9a8dd3e2723bc47f07e5299266da9d92bbb454ef165ee4ea4f7;
            proof[1] = 0xd5eb5e89201a88aeff4b7a460ae5fccce92cabe086889728796ba13819f90e35;
            proof[2] = 0xc75021d3446fb5732ac52e5e5268aff389c0e0929692eb4cc3da83976248a0d7;
            proof[3] = 0x330bc4f2079b5db3fdf7243aca8e95c79d8ac6f9945da6758aab65610db965bd;
            proof[4] = 0x4639ba154447bfc4b04384393db8afd017e4bcef8023af846adfc995c9fbff59;
            proof[5] = 0x7e542729a266848ea422300a3c916f3685275f58286eeb45625f4b4a93335633;
            proof[6] = 0x652547470181eea733087e35b8d433599109ad085ed943dd4d0610e7bd1a83bc;
            proof[7] = 0xa12db7c3aab7b7ef7177aac41144a39b9a000d428b2289abfd69ecf607c8df5f;
            proof[8] = 0x594bd5875e705e24c2d5ee75046c254ec8fefb0242e601cdb0d8fcc5bee4b680;
            proof[9] = 0x51e5b248f2da5f14b0f77d02c6abae05a886084b13ba812643fafb0c953e1ee7;
            proof[10] = 0x98b57381c0b50fd247786aece92f57da617ca000d2d853a18ce354ca10bda6d2;
            proof[11] = 0xbb74b4926304fbfc1fe5c988c794ca59576dead53b83d6ea2907ac8469731de7;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 1804
            proof = new bytes32[](14);
            proof[0] = 0x2a496788ff7613333026d598f5cd34caa3121cfed45152cf59d4969ec191f07b;
            proof[1] = 0x290e5f0a909b45b1587ab103515cc76bc7dae6d7e51ecaaad3532cf92cf5d5d7;
            proof[2] = 0x8f0578f1f9825d1f62863416dd44f6b471f38ef08bb6efa3ef2f41cec9f83d09;
            proof[3] = 0xa69ea1b71b1b27e79f8daffc1579a2f6f1903eab26c0208f9317274c052434f6;
            proof[4] = 0x6efe36ce4348502f7af2abe7076254e70f59506d17d725aea3d209f861ca4464;
            proof[5] = 0xfab0a9663f790cb10bcdeaadda113322ff9c0856c80c26bafad76411197711c4;
            proof[6] = 0xfc019508399158bc97b840881201e3ad74f06e6005bfe65171faf991a14aee5f;
            proof[7] = 0x33bffe860bc5f68cc7d0499994f64f2b88e589b839f6a8f14cf619efdb57311b;
            proof[8] = 0x01c4fbe3ccb7dc0f5169e1a469b320ded13c32aab0c3d2385fafb73f087b4b84;
            proof[9] = 0x045d463f91a4973b3e554ff26abbbeac6770c57d780e57858bf0605ddaf314d5;
            proof[10] = 0x98b57381c0b50fd247786aece92f57da617ca000d2d853a18ce354ca10bda6d2;
            proof[11] = 0xbb74b4926304fbfc1fe5c988c794ca59576dead53b83d6ea2907ac8469731de7;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 4349
            proof = new bytes32[](14);
            proof[0] = 0x671431aed923e44360ab3e185345ec3c55dd4381ad29ab8888f43bd68b2b3876;
            proof[1] = 0x6b3e082a7a74ab6f3072d94ce8322317cfb94a46fc3694f4ccc742bad45090e8;
            proof[2] = 0x989329196446010116f5b7367bf523a49348b573b268cda0fedd20a967e4aeff;
            proof[3] = 0x0b36a22e1326fb3a5aa569c695436a98a4fc069b0d047c2b558848d16cce9221;
            proof[4] = 0xb5a75db28e633dbd663204d0d14d34de9ec54243fe793023e6c83592c8431b92;
            proof[5] = 0x0b1f02081151497a5d3a1f31635f97d885b5e2ecdbe6d5c87dfc074268aa3911;
            proof[6] = 0x79e3a481900f3e644890b53a10b53b11214fba2681451cd0c3232a75d9bc261c;
            proof[7] = 0x7d36ca4213b67e3cec46778a6365f39acc523ea5b9d9eefa04d42ba115d2213a;
            proof[8] = 0xde17555923a25fbd2e45609b945a0d91c596483d38fa19de2aff064bad6d5e6b;
            proof[9] = 0x885029f460e37a949250a53e0dc98f6fba511c1048583f616e9b99d5b479292d;
            proof[10] = 0x45db3a8086f42c9525cf7c9abd6a2ec7569dbd8e771259564b2477a8d7dc5ea4;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 5024
            proof = new bytes32[](14);
            proof[0] = 0x766005c8fcacdc209afb8eddfa17428a09e9c1b8df01af9b437e664a97c95e23;
            proof[1] = 0x88f36ebfeb44218d30529ef839619e5d7f6c04557c22d8f6dba03a328fe20d23;
            proof[2] = 0xf969dd934d4079920ff1c60b846960207af748b6f50fa5e94a719e9be12d1ab8;
            proof[3] = 0xdef0c7d8ecc104947f6e829b4df0ee908d500b798679f2741ff01ecd8033d18a;
            proof[4] = 0x4a8f42a49455cf960a44b8d8143e2531b1d93e818c88b886b5c2273a58c0a14f;
            proof[5] = 0xcd8f2367b7bdb85bb07ed2d06afd69930a86f1bc69d15a005e4ab2edc8ba24dc;
            proof[6] = 0x34f8010087a812df15fe6bd0526d10db11b226a49d5430ed3399d9e8f5e7ca06;
            proof[7] = 0xcedd8caed20690d0d95b143fbfad5d351121d960335ed87ba6b9e094bca212ef;
            proof[8] = 0x23c3dab7d17c2981611c7f59bfc734eed5b90e5431a7c19a8f5ad2b70d42f1fc;
            proof[9] = 0xb20e41f9490e7820feb0bebde7833acfebe8cf4ae9325187c345dd824ccad5e0;
            proof[10] = 0x45db3a8086f42c9525cf7c9abd6a2ec7569dbd8e771259564b2477a8d7dc5ea4;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 5090
            proof = new bytes32[](14);
            proof[0] = 0x7836e5b297771b13c202392c44cf318789a6059103c3cb0fb5c61c835f610fe3;
            proof[1] = 0x149191bc065fafe1124febc2014e3a0e11ee35a34a5672d78ac2c3f6345498e3;
            proof[2] = 0x89e36e2ee9b37bdd0aaf12b4d6fe3fe64e8fb3633917277e64dcca6087e70117;
            proof[3] = 0xbc269186d42512286baf84b9339a4a2dd49f287ea30ee9f4de8d5e9990230a2a;
            proof[4] = 0xb5a8b9991ee79a54ab22879a5bb2494a2393cdda2a83bd2f6cebc70689e679f4;
            proof[5] = 0xed0b3706d9add584f193a0015556b0e5215143ea16171a2cc641943f8e27e90e;
            proof[6] = 0x66677a993a45c346d93f9b5d625813981571d6080ace17af68c38c435e4e77a9;
            proof[7] = 0xcedd8caed20690d0d95b143fbfad5d351121d960335ed87ba6b9e094bca212ef;
            proof[8] = 0x23c3dab7d17c2981611c7f59bfc734eed5b90e5431a7c19a8f5ad2b70d42f1fc;
            proof[9] = 0xb20e41f9490e7820feb0bebde7833acfebe8cf4ae9325187c345dd824ccad5e0;
            proof[10] = 0x45db3a8086f42c9525cf7c9abd6a2ec7569dbd8e771259564b2477a8d7dc5ea4;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 5266
            proof = new bytes32[](14);
            proof[0] = 0x7bae1fb5a7cfbf7b960857c53d5658fbe01fb6e274a233a90559c6a67ec3757e;
            proof[1] = 0x86dafdded681e8453be788051776846451bc3a10f99674525fbeb2b77c57a069;
            proof[2] = 0x5476d69f00b5017b45ef2a1aa8ab8e10d2fe6e191b5770178c9335d18a33aee6;
            proof[3] = 0x38badd9542fb9957b6993a0085a315c45bab9d257cb2ecda11a8b948abfcae06;
            proof[4] = 0x1dd6641b446d5db1d068049a7505b9b6f95adbc031425fe2f7b0d77c7996b4c9;
            proof[5] = 0x63207b366178519f4ba906733b1d21409a0781c420f566487f92ca8acb6eb3a2;
            proof[6] = 0xeabb09aac2be99f226a42bb641ea45682a30058b6a486613ccad25558f8f068b;
            proof[7] = 0xcc5976228ad83d259c8da7e458ecaf83fe7c93920b1957b0ebf588a86dba7368;
            proof[8] = 0x4b59cad92304c0e9fb1bce3e4d95bd0ae17a03cfab19e1b023b6ac6aa1727606;
            proof[9] = 0x67161d74b4f422e5f0527b43319648073feb5553d07cda522df147c5f57ae666;
            proof[10] = 0x006fe662adc894e4639b6a0dcdda5627979b9ace3baaf74e64dab38c4a754cb8;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 6204
            proof = new bytes32[](14);
            proof[0] = 0x9253ee9bda831af966fbf0537a813b82a064af9f5728062897e68fa2f61d8b0d;
            proof[1] = 0xcc117eba14f86aa0052c842a078c9e6c3a9cf6b35205c8a26e155ab26c89b445;
            proof[2] = 0x8af88cc9d988355eb189b354761d3d279fd0f5dcaaff556843c176ea92fb696f;
            proof[3] = 0x8fb7eeb5fcb2a7b739ecc93d8fc2c87567af6d8935bb28253133dbcc2b3ee851;
            proof[4] = 0x8d42b5e7247190a1eed79b85a10b35d6f00b3f83a0bb773a4b8d501bd960b458;
            proof[5] = 0x46ca5391ebd97eb349580555c16239117230a4857aa2fb72b5c5a186aaa5ba64;
            proof[6] = 0x53f64f8b588a3b0b956e8675bff604780648336effb44f205dcc5b22ffdb4f82;
            proof[7] = 0xb584d47bf0a8313dfdba2925226997db1f4dfec9b5cca4cf2ad6cec542cd8d73;
            proof[8] = 0x7e529a879e5f38f0eec017f9ae2100bcda7e2cd39db1eb63140e88b29eda69bc;
            proof[9] = 0x61418f1ef4a63ff8dd09150ce3a1df7161949415727f2d283099e075b61e0021;
            proof[10] = 0xe77b1a8da1ba7e18fde796a99147c73a139d97ca65304cb01700a523a6a101f0;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 7777
            proof = new bytes32[](14);
            proof[0] = 0xb7ea572203564ada1a009ad0a51afb4d357e3e9e13a6c1f5416dfcccb799cc82;
            proof[1] = 0x31db5293363f778598883c7fd056ca124d4844c39e1e9a07aa49c2b4097b70d9;
            proof[2] = 0x2fb0a0f3649278ef6337eda83291d6413330e50425e1f9c284608dd38881f8e4;
            proof[3] = 0x46753bb7bd7e848a015f2c29c3a55d03f255119b90f1f85089f0cc4ed23d18c9;
            proof[4] = 0xe0c34ba2b4da227f9af9639e2dc9438479ef3a4a984ccfd001e377ed9bae3cba;
            proof[5] = 0x4f930f8372287814b49a2b3f905f3f7b404153305b6c6ec07d01084f154269a5;
            proof[6] = 0x3db0df62e94a50ceeca596b8ee38b8ddfa1031d359667ae208ebb268cab11e35;
            proof[7] = 0xad78d5a4ebbf20ff4a447693754d1423c89ede39053a942b4688fc587b74b7fa;
            proof[8] = 0x0a27a3c34099ca88adcc54c5eb06a44a9f5e32215830b8f49454d2b5b7b4437a;
            proof[9] = 0x0b6b2bf00564271f27c23e5aa5861ac4cda0153aaae7dfe75e45ba257dd68d89;
            proof[10] = 0x337d5578ee0794f14d2fceaebfda2ac052d65939ad7919e78bf047268f8a88d4;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 7863
            proof = new bytes32[](14);
            proof[0] = 0xb9d781b5255db1fb328179a7537fd43d244fe07fe27a1f6435eb0b099a1ae16b;
            proof[1] = 0x9d7bd267c2e2f815863b2cade932bd0dd4b7fff9b8a60a23ae731295ec806ba6;
            proof[2] = 0xe2e319da8b6712272b8bec8ae57647db828cd6c765ed5bce5294afa4f1c78e3e;
            proof[3] = 0xcc655ce505b4ddb08d3f2e700bd05175acaa73e45603575a26c4f20f24779244;
            proof[4] = 0x358556e0d82a05bde4a628e98ea3cb2a6c56391fffacfe5f39b7056df2887995;
            proof[5] = 0xe958e2f5885df5134711374e13c739beb13819275f4665c2edfb60813ddf8626;
            proof[6] = 0xb72ba2e3634b24fd61adfe1581acd14517bc0022351c3b5e0fd066b196ba053f;
            proof[7] = 0xf11fa60fdedd355d51f6ae0accc04618858564bd016a4e71099abcfde5cabf02;
            proof[8] = 0x0a27a3c34099ca88adcc54c5eb06a44a9f5e32215830b8f49454d2b5b7b4437a;
            proof[9] = 0x0b6b2bf00564271f27c23e5aa5861ac4cda0153aaae7dfe75e45ba257dd68d89;
            proof[10] = 0x337d5578ee0794f14d2fceaebfda2ac052d65939ad7919e78bf047268f8a88d4;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 7868
            proof = new bytes32[](14);
            proof[0] = 0xb9f25f6c6587e12ea0e1a88d7d135aa0743c83ecf71a17b55fb4fcad86f4f269;
            proof[1] = 0x28b8cbb17f1877cac78a0be357d0b1c5c41fac620e753bac1dd45d053f64f4f2;
            proof[2] = 0xc8dbcc920ce4f68744d876bd99d47959cbd70ba7661a1bdb39b5b474eaad4599;
            proof[3] = 0xf5a80a7997bf32a62d12dc5aa815eae20c225a0b02a034c27d14b5dbc1d49330;
            proof[4] = 0x358556e0d82a05bde4a628e98ea3cb2a6c56391fffacfe5f39b7056df2887995;
            proof[5] = 0xe958e2f5885df5134711374e13c739beb13819275f4665c2edfb60813ddf8626;
            proof[6] = 0xb72ba2e3634b24fd61adfe1581acd14517bc0022351c3b5e0fd066b196ba053f;
            proof[7] = 0xf11fa60fdedd355d51f6ae0accc04618858564bd016a4e71099abcfde5cabf02;
            proof[8] = 0x0a27a3c34099ca88adcc54c5eb06a44a9f5e32215830b8f49454d2b5b7b4437a;
            proof[9] = 0x0b6b2bf00564271f27c23e5aa5861ac4cda0153aaae7dfe75e45ba257dd68d89;
            proof[10] = 0x337d5578ee0794f14d2fceaebfda2ac052d65939ad7919e78bf047268f8a88d4;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 8160
            proof = new bytes32[](14);
            proof[0] = 0xc10c6ecb35f77786477f513ea283a1335e157dd9a5f9c2f14ecfdc604775c486;
            proof[1] = 0xce21a7a203ffa213a75369adc9bf9802475101ec61c43b3ab6dba4f1a07b63be;
            proof[2] = 0xde59e6b548fc664911d2de7401eda02bde7f58aaa1a9bf40749351e5b8522876;
            proof[3] = 0x9c1a06375628fc0490f62076994916f2c7c31658662abb9168e0c9dae50435e1;
            proof[4] = 0xf2f22c8d537ada7a9c44b787c2f7c3d4be98e4ab8842fcf7d5c0b00f19330731;
            proof[5] = 0x4df0db6406478ba89e17159ddab13f0c50f630d92496ef13c017515054ec803e;
            proof[6] = 0x38415fce31c1742d79a2a653bd875b1e2d7bbf6f5698ec2e7fe8b3f6e81d26f5;
            proof[7] = 0x906fd6c02ed931c194c5a7dae391b18c7f538c1fe527e607f2d08f1f860f0276;
            proof[8] = 0xfebb001b4f1145bef29dda9cd4856c359c47ffa6d29458dd7e94a4a22152de32;
            proof[9] = 0x0b6b2bf00564271f27c23e5aa5861ac4cda0153aaae7dfe75e45ba257dd68d89;
            proof[10] = 0x337d5578ee0794f14d2fceaebfda2ac052d65939ad7919e78bf047268f8a88d4;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 8548
            proof = new bytes32[](13);
            proof[0] = 0xcabf257425aad676f781f54d718e2bf9cd922788ec571c0db7422fe3bbba5c98;
            proof[1] = 0x6f8b5554edfe32c8086d93f18929bec36a6291c2dee87d29d57ea984cd76e8ff;
            proof[2] = 0xee10c8b376c1b329f6b338d7b82bd9aae170b72e41c0809d35da61915267864d;
            proof[3] = 0xe7beab7c4343f4603628b0ea7ae636ffc9dfefa94e50d6885d5cca0cb3f41c1f;
            proof[4] = 0x15321b59d47b6d31793ee926ee6cd8a0f76bee25568f2108049d3c43386fa989;
            proof[5] = 0x7db115a330f0c61a558575759f30b8a5d06cf6f9e0c6a6147a20f1b018207cd6;
            proof[6] = 0xb9e3bf2220a3df4dec001d8eb0a8009cac5c3921998b013f44c1d6a7f4d8882b;
            proof[7] = 0x1b827fa3334b48dd4ab26eeb8e17305812ac5b1d262bd9fbb39afefb41c693e4;
            proof[8] = 0x4478b7470a443074a7508c4a4b21f2b6e67fd3b0998968b79bd7135365d9f671;
            proof[9] = 0xd137871216f052e3ed1397c977d9271c9ea3895adfcd5fb28c8882bc8c3fd89b;
            proof[10] = 0x7106c51977b78e53883b59d022fc5fbc4ff5a332e1ff0c2fa2d165b94a7552f9;
            proof[11] = 0xc1aa0f0beb9b0d1c6e631e4ea4bdba0ba97369364d2dee402a456b69182051fa;
            proof[12] = 0xcf092fa45614ed55511fb9aee1350689157934c0f689296509a50ace41ba103d;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 9393
            proof = new bytes32[](13);
            proof[0] = 0xdeef38db24c412eb4ee34e971a7568e4137f10c2fc0bfb84cbc974a695d4b5e3;
            proof[1] = 0x5e2e40eda298b214cd61ebb9db7022b23ec272e12d70a15f1313709192298e6e;
            proof[2] = 0x4aab431130e9fbc812d5c6ca6c616d0d8feaee67b5f8eab167354c4b16aac85e;
            proof[3] = 0x265b622583fb14e32e53b234a087684445de06a7d317d6040599dbea3406ba4f;
            proof[4] = 0xccc89a9e7c922871c5383c72e82c7cfb01759336f2cb435e8eb75d17c383ec29;
            proof[5] = 0x25480a2891cc2b8982abcf9bbb4b131f9e46896bf26475f75d69d20c004f6371;
            proof[6] = 0xde2dae5f806b9c2e3879ec42201044aaa57d0a5c7fa70007db31e5f8a5ef27d5;
            proof[7] = 0x453de2c28b2227cdac75597b469a9dcc2a4f7db473bf63bdb26566eced91c010;
            proof[8] = 0xc03e3a49c07c7d263b4ba3b3152df1d523d580b12a6edb00519ef888b1a4b21f;
            proof[9] = 0x8374dc029b0ce76e24580dd50f920b34b741441c8eba44cbb9b9743c4b6fb472;
            proof[10] = 0x809050cc479eefb2630b8288cad2d1d4af5137d868d7c354b1ac2475f69402db;
            proof[11] = 0xc1aa0f0beb9b0d1c6e631e4ea4bdba0ba97369364d2dee402a456b69182051fa;
            proof[12] = 0xcf092fa45614ed55511fb9aee1350689157934c0f689296509a50ace41ba103d;
        } else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 9870
            proof = new bytes32[](13);
            proof[0] = 0xeab70b5e386057f0242f8226434a834261be1b7156ad74035e0eb9f778085951;
            proof[1] = 0xe6ba3d9cbcd5fc26f355cb9e20baf71b4535ef6c8077fa95127ed35ccb3b845d;
            proof[2] = 0x9f55cdb4531381b0488eb1ab0c26dbe9f839df8384480b1b123ad3d28439bc99;
            proof[3] = 0x8618933817ddea8019adf9e7d5227718e7912b758b82a736d9fce9a1451b3b82;
            proof[4] = 0xd7dc890c07e5e9d9e5d60a1cb406c551b9fdbddecfeeee50286df744dcc584b0;
            proof[5] = 0x92caa803c2ad3f254d8452484efca4813366e4c70f86743fce062e8d282ea19f;
            proof[6] = 0x97d71ab6848c66a3c36c7aa305a64376d28c86e8b95168982f20af0cb077401c;
            proof[7] = 0x59abbf5258a40b93d47a3598737f9e29cc7ec21613ac310dfed45a962a18ca72;
            proof[8] = 0xc9c44fa9733049dad174565fa43e9b9a877d301da830ffd77a17be510c5118d2;
            proof[9] = 0x68aff0a9da8988b867e174c478e023afabf2101c95ad6a1746bb32cbc9d74d75;
            proof[10] = 0x809050cc479eefb2630b8288cad2d1d4af5137d868d7c354b1ac2475f69402db;
            proof[11] = 0xc1aa0f0beb9b0d1c6e631e4ea4bdba0ba97369364d2dee402a456b69182051fa;
            proof[12] = 0xcf092fa45614ed55511fb9aee1350689157934c0f689296509a50ace41ba103d;
        } else {
            revert("Unknown (inputReceiver, executor) combo - not in ApproveAndSwapOdosV2Hook WETH->USDC tree");
        }
    }

    /// @dev Returns the production merkle proof for WBTC→USDC swap via ApproveAndSwapOdosV2Hook on ETH.
    ///      Source: hook_0xe138e0750a1311580a2c842ff10a9824fc2c5217.json (chain 1, 10816 leaves)
    ///      Leaf args: tokenIn=WBTC, inputReceiver=dynamic, tokenOut=USDC, odosRouter=0xCf55..., executor=dynamic
    function _getApproveAndSwapWbtcToUsdcProof(address inputReceiver, address executor)
        internal
        pure
        returns (bytes32[] memory proof)
    {
        bytes32 key = keccak256(abi.encodePacked(inputReceiver, executor));

        if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 712
            proof = new bytes32[](14);
            proof[0] = 0x10ac13c0a18a94193cbca4dbae85034fb80262dff4630a9c6dfc2b1df3dff49c;
            proof[1] = 0x563fe92b32b13c7abfec3547b645db1b6412c5136575ba7491d3eb692cbcff20;
            proof[2] = 0x290cad701384a977c12b829ac59ede1910c183cf0414431fa7f59c2ae85ca33b;
            proof[3] = 0x7ae8adc180994331656411f0a8208d3ab1c9c81ef09a9e205306a0f9b596459f;
            proof[4] = 0x9a556d6c3b9d19ba3d457dc8242d08a9a977e8bdbb9260992454614582717fd0;
            proof[5] = 0x2d4037c9c9807a3f0d93a6ac352a2bf8f07fbeb43852c0584dbf53ca84abf631;
            proof[6] = 0x8803679f2d5fac95bd8cc8ee7f3002087a2bc93ed8b9430bc4828a5fa21c23d2;
            proof[7] = 0x8487f907d1e5e873ffbde938870d3340992fcfa1641ae314c6aa89dde3cc612b;
            proof[8] = 0xa681ab1ba3f92b315d13c4074f9877e1e9a9790737049794d38ad93750979936;
            proof[9] = 0x1fe067a9bc5be039f525a2f112bda908dd1fe7c3359faa10abb2c10b7c49ec0f;
            proof[10] = 0xfff7d53569dc7d42ced0154e060639d02e83de074788948314afdc2b1415f21d;
            proof[11] = 0xbb74b4926304fbfc1fe5c988c794ca59576dead53b83d6ea2907ac8469731de7;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 1710
            proof = new bytes32[](14);
            proof[0] = 0x27e29a4665cab403a136f214a47ea18e045ade6c1910f7c20f2aa62b80e1f54b;
            proof[1] = 0x191b783ff3609003e628f4c583206e4c786637ad49301de11b2c9564f9fe1b15;
            proof[2] = 0x67826a31a73d5bd1f3ba9ce9af828a752beb66896a8c8262f479dbd705f9b6a4;
            proof[3] = 0xf242444bcf105fdb42dd5d3cd8dae7be939390662b6dedfa3b6e83724eeced88;
            proof[4] = 0xdcce8d161445262d634bcf661fbcc98633f6691e006da9b31942d573979e09c3;
            proof[5] = 0x09bc9e2fb90705b0323b56c223524af8fcb751d38d9ddf91c2343ffefa16ad6f;
            proof[6] = 0x7e0db02ed8c243c6a4ce870e8714e89aefde82abf05287b07ddb51c5123b1465;
            proof[7] = 0x892e21e263b34ac28c5b52692773117e52ca19575bfe912c2621d49bdec08e8d;
            proof[8] = 0xc79a4644605c53203b15b46c5cf6a923429b2de3848c5654e88ac4797aa11a9a;
            proof[9] = 0x045d463f91a4973b3e554ff26abbbeac6770c57d780e57858bf0605ddaf314d5;
            proof[10] = 0x98b57381c0b50fd247786aece92f57da617ca000d2d853a18ce354ca10bda6d2;
            proof[11] = 0xbb74b4926304fbfc1fe5c988c794ca59576dead53b83d6ea2907ac8469731de7;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 2189
            proof = new bytes32[](14);
            proof[0] = 0x3495b6687bf6f99494e57b98d58f028264564825d34cdbb173a6b5fa52b18c13;
            proof[1] = 0x1288bb6908af47b26d4152e027b80190a50d150f7eb61853ec983c58f492ef8a;
            proof[2] = 0x1595265406c1338e479b3ff671a08fd84f99f4b4d73854a379a874ad995d4298;
            proof[3] = 0x970fb5b3d56fabf96ede542c5bd99dd12669f3161f8b4d74db49c35826e663f3;
            proof[4] = 0x90f8e20b8c77946c0e38c6d570f4f1fb0399405ae6a93907143eec6df89099af;
            proof[5] = 0xefbcb005cc5bad8e8ab66ebf09e2820bf88ad5d9135b060c75fa1dc0ce11aecd;
            proof[6] = 0x94933e6d4e7ab82e8fcad168048b65dcf4426decc935ec68dfa8e3ed574aa895;
            proof[7] = 0xde8b23b7b9b10efee3accc39509f7980d9d351f5b0a3c6009576090614897f1e;
            proof[8] = 0x10bd644e8f4b64546a74c4477449f0fb1ca82d6686bed2144ef80663f1615d83;
            proof[9] = 0x7b71b3601b7cc94e0791ce761b4f9aabbbe063a82ecb637981ed13bc1560a4d3;
            proof[10] = 0x82fab080b8786b0bbdf38b07db0029ecafa79420b4bf142455eee7dfadd68b10;
            proof[11] = 0x186dc380516853990dfd4fc219e457942830728ea0a4c62f166e5591b5f3cdaa;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 2195
            proof = new bytes32[](14);
            proof[0] = 0x34ba72d0ec5fed340b23958553ba770e42221a0102b38a9b58b181ebb55915e6;
            proof[1] = 0xb5617dfe6ee388ec2fc74305fa4e751d6493649f2b39e9ccbfff7c3398f19f33;
            proof[2] = 0x894db937bee15483e145d72ff92f8d8e739daab0c4dbc5abceed683c0f874876;
            proof[3] = 0xeccc6a7ca9049c1d0db05651d774f126311ae0f12e1035cd300c5cdfed4e0afd;
            proof[4] = 0x5b1c598e23d3675402a6c1db0fff3dfe6d5217dfe8933ac618ff9684d7edacde;
            proof[5] = 0xefbcb005cc5bad8e8ab66ebf09e2820bf88ad5d9135b060c75fa1dc0ce11aecd;
            proof[6] = 0x94933e6d4e7ab82e8fcad168048b65dcf4426decc935ec68dfa8e3ed574aa895;
            proof[7] = 0xde8b23b7b9b10efee3accc39509f7980d9d351f5b0a3c6009576090614897f1e;
            proof[8] = 0x10bd644e8f4b64546a74c4477449f0fb1ca82d6686bed2144ef80663f1615d83;
            proof[9] = 0x7b71b3601b7cc94e0791ce761b4f9aabbbe063a82ecb637981ed13bc1560a4d3;
            proof[10] = 0x82fab080b8786b0bbdf38b07db0029ecafa79420b4bf142455eee7dfadd68b10;
            proof[11] = 0x186dc380516853990dfd4fc219e457942830728ea0a4c62f166e5591b5f3cdaa;
            proof[12] = 0x5e33fd01f134b248be89041927b84074a7ed35b458d83d7e06d773d273f13b25;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 4886
            proof = new bytes32[](14);
            proof[0] = 0x73694d7d12c0e4ba0eaea1a4d473f02f03007c45a2a1b605bf27d382a8fb528d;
            proof[1] = 0x9921a741f844e341d9a03d9570e42fbf2a51a7e06a03a76324fe67c02348f513;
            proof[2] = 0x52afb0b115064b17e11d3408994a2a993a67218f653ac11375908b27f564153b;
            proof[3] = 0xd80693cd24c9531ba9207e9620bbf3ea4451a98e93a7e36f91f8581a599a0167;
            proof[4] = 0xce152080fdb5a72eea975c264e12d39080c6835c54fa1b3056849b0bf9ba24ff;
            proof[5] = 0x1278277e2f2c5f8cee2fceab36f264197ce7f47205b5114834ed1320f100d5f9;
            proof[6] = 0xb852844785f417244d0150a9a310edb3fed225645c67ab4a5740f664d81b5163;
            proof[7] = 0x3ddad3950f9505bb72841b92a979b4d3f81ae8d92df5f08a687d196453ecff51;
            proof[8] = 0x23c3dab7d17c2981611c7f59bfc734eed5b90e5431a7c19a8f5ad2b70d42f1fc;
            proof[9] = 0xb20e41f9490e7820feb0bebde7833acfebe8cf4ae9325187c345dd824ccad5e0;
            proof[10] = 0x45db3a8086f42c9525cf7c9abd6a2ec7569dbd8e771259564b2477a8d7dc5ea4;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 5645
            proof = new bytes32[](14);
            proof[0] = 0x859a08984f9a351da8ff299e59b3ab43053689b49568e2d469a902c381248eba;
            proof[1] = 0x7f0a8228f16610e0004403346fcbae6b07a0716ecc5ada73c696000988c2d560;
            proof[2] = 0xacea2a3b7fac61ced9376bb27a3e045352d645bafae98e674f81e81fd30f8d85;
            proof[3] = 0xfd02b1d79f81aafae1cf99048e19edde7df94efe6ef7a81233231bd3ff5b9bcf;
            proof[4] = 0xda3bab090f33765702fda01314c3d3a1cfb16c89bf7f16650ea5fbb03b3fe506;
            proof[5] = 0x79136ac288cdbdb16eb6e204dba5fe46cfb5bef3366e8f1710399109d05a697a;
            proof[6] = 0x7fc6a750e0f10e1e740d03c643c82f7d25f15713e44deeeb1c7b583147de1b9e;
            proof[7] = 0xb1c0ddb181dbbcf36127595dd165833d06eb4d6498aa064a112bd0d3fd837092;
            proof[8] = 0x84995160ad997000ce832de67220310c3a42e54f8161918cf194db0522d187e2;
            proof[9] = 0xc77adddc310303e9b82a5dcf02845a3b18d0f3dd5da709d8b87a6997b6da7548;
            proof[10] = 0x006fe662adc894e4639b6a0dcdda5627979b9ace3baaf74e64dab38c4a754cb8;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 5648
            proof = new bytes32[](14);
            proof[0] = 0x85b054f8d983d436f704f968576fe79e396a090f4a277088362ca98826acda78;
            proof[1] = 0x052fc80e4416fddb2916166a84fa2f870b5111573e24d91974922786400afa1d;
            proof[2] = 0x30404f804daf25710f8e78ed7d27b1eb016c24fc46257e980b4c487b7dbb2f6b;
            proof[3] = 0x5c7f471f6a7caac06ca245064dde0a28ec27c63cbae3e64c1cf4eb53117cd31c;
            proof[4] = 0x365ed819db73c15ec67280f26160c831857d19ed414e8f8b996c3f2e9d29fb66;
            proof[5] = 0x79136ac288cdbdb16eb6e204dba5fe46cfb5bef3366e8f1710399109d05a697a;
            proof[6] = 0x7fc6a750e0f10e1e740d03c643c82f7d25f15713e44deeeb1c7b583147de1b9e;
            proof[7] = 0xb1c0ddb181dbbcf36127595dd165833d06eb4d6498aa064a112bd0d3fd837092;
            proof[8] = 0x84995160ad997000ce832de67220310c3a42e54f8161918cf194db0522d187e2;
            proof[9] = 0xc77adddc310303e9b82a5dcf02845a3b18d0f3dd5da709d8b87a6997b6da7548;
            proof[10] = 0x006fe662adc894e4639b6a0dcdda5627979b9ace3baaf74e64dab38c4a754cb8;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 5900
            proof = new bytes32[](14);
            proof[0] = 0x8bb43fba374794a8abe06376511ae24384b4afb83bf713ced822fd257bbfb58b;
            proof[1] = 0x04850d3056bdf0484dbc1ae1c0f070757d1ae78a030d61f704a299fb4d6a4003;
            proof[2] = 0xeda17c5588efd4af4cfae9a9a6acb2c2ba6dd3d36f9cbabed3b06cd1c9a86da8;
            proof[3] = 0x3595da7a6b4f6758018b38f32996e1eadb1ca9166bbf91cd9c8e26a3aea80d18;
            proof[4] = 0xfbee3c4f127f5f359fd03f5f8dfc9cacd077384ebbde4d1c363f313a2bdc5834;
            proof[5] = 0x6b4c3a48ffecbd3fa6e1226a65a7924ff27ad2cf2d042fb305eefa528cb8a12b;
            proof[6] = 0x282c57162b2d8c6898ac1c50a05c93ec1ad75c13733ce35ec710f1ced70a82f2;
            proof[7] = 0x0badcc68bcb68a7e06461ccc602a4e18b2ab762332a817e8ce785959846a4c4c;
            proof[8] = 0xf08aad787ec943894d757f1c7e44143eb0a37bd8b1226a6753b571b05b9ae02a;
            proof[9] = 0xc77adddc310303e9b82a5dcf02845a3b18d0f3dd5da709d8b87a6997b6da7548;
            proof[10] = 0x006fe662adc894e4639b6a0dcdda5627979b9ace3baaf74e64dab38c4a754cb8;
            proof[11] = 0x6e02cb948b6380a2b89c3795ddd79c2cc405eb67dabb2399a5a94cb25ce6bba1;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 6346
            proof = new bytes32[](14);
            proof[0] = 0x95d85c2e45b94338270511f790f01b4c1bb071897fe22b791c95b528198c30cb;
            proof[1] = 0x04a7a3d32a5a80db4ab092c081abc6707313278b569504c8f298679b80281e78;
            proof[2] = 0xd410638ec42498263d414de6da8879314a4552ab47faac6a9ce37d5d54de701b;
            proof[3] = 0x9020f510ccea37ceb1bdff9ec388b349ed7e6892c18f78314e5c5a04e497be1f;
            proof[4] = 0xcb4922489a7792239aa786d8c581c44437ca2f4bfb7e4dfffa9e671b48067ccd;
            proof[5] = 0x9c059727ece56d5a128f90724e0adeb06ab79ca0f9a9ffc4e5945057198bc632;
            proof[6] = 0x0844148d36fd74e5a8582b42d29159a8b94466134a745b4acb94df0786be1527;
            proof[7] = 0xf0fabf262e8f44e604682d99c97501e0241fa61083f0be939ad22af776202dad;
            proof[8] = 0x7e529a879e5f38f0eec017f9ae2100bcda7e2cd39db1eb63140e88b29eda69bc;
            proof[9] = 0x61418f1ef4a63ff8dd09150ce3a1df7161949415727f2d283099e075b61e0021;
            proof[10] = 0xe77b1a8da1ba7e18fde796a99147c73a139d97ca65304cb01700a523a6a101f0;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 6512
            proof = new bytes32[](14);
            proof[0] = 0x99f29e51277efd2676220bb7ec74cda87c9429b316489dfa7d646ceffcab7040;
            proof[1] = 0x1e64118da1f79aa162bc33c902823267d26338a4e745fd95014d84ae30c2007d;
            proof[2] = 0x7b94e2f16618b56223b2df4c25169fe6435aabac65ecfbf0f93ea4df831f6235;
            proof[3] = 0xb6d009a6826899e9cb8290105a15f7363a6c9e1910d8bd6e216038c88e3ae14f;
            proof[4] = 0xbed47545b0a2cda95968ea21f8565f5bc204b3d6d7972d86c9e1b0c46c11c356;
            proof[5] = 0xf2e0bfcbdb441dc68ed7797e5a25d00fea05efab624f233a3f159ef530e21d40;
            proof[6] = 0x6fa7a935e2ca395d0c069828a263979f536beb86d9a4ea3d1d16ff4d08b74ded;
            proof[7] = 0xfaba4d9b9c6eaad4f0f738d46dc031449663cfce727d19fa37a90c19e32ef8fd;
            proof[8] = 0x86b31203516b08f78e5e104f587a97954cb9f3983913489efa0198ac41b87cea;
            proof[9] = 0x61418f1ef4a63ff8dd09150ce3a1df7161949415727f2d283099e075b61e0021;
            proof[10] = 0xe77b1a8da1ba7e18fde796a99147c73a139d97ca65304cb01700a523a6a101f0;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 6736
            proof = new bytes32[](14);
            proof[0] = 0x9f7508b0d7685462846a2a166fefa3b08597d8f441d961be24592ba65ea49d04;
            proof[1] = 0xf345bd4c9f843275be0c012be090642b1dccef8ac5a0b736d5a2ea6b99d1e177;
            proof[2] = 0x7a0ef6781d11823104c6948f856fd57f80212b9a74b93672595dd3939f7cd90f;
            proof[3] = 0x75f479fd6ffad62151f2e2bd1c5d03dd48745fb383cb9d095a5f25a802d39c51;
            proof[4] = 0xa493ae28f536db4bea37e8fda5496d69aeddb58210acfdd9a79faf20104b61f5;
            proof[5] = 0x5b497c18de83a2a42f544304bd2b2eb091ff5e281e861a979a05916476433842;
            proof[6] = 0x76cd58341a3e84cd382e62d8a71e0aebcaa991740b138f08d3c2ce432fbd48f8;
            proof[7] = 0x7cb271a26389abcd16f9364b3212523907f05c3e1d8059c057177053bfc2e04a;
            proof[8] = 0x1181b17638875fcc054ee2a153724abc5b388a471b67554e710961a36380c003;
            proof[9] = 0x629ab7c90c97d727179ffff8f335ad930e88300a4f1ce10930dfff25e351d594;
            proof[10] = 0xe77b1a8da1ba7e18fde796a99147c73a139d97ca65304cb01700a523a6a101f0;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            // Leaf 6951
            proof = new bytes32[](14);
            proof[0] = 0xa43d90e651fade9f25a9da6200e3c54ba757a9c57798cb29f825854aadd0f6fc;
            proof[1] = 0xf1fe5148d302cfc4ace92fbb52ee0f8aece734d28ae50ffcf2e03cba6dac4635;
            proof[2] = 0xca49a08e628ecaeaf432a7bbe831470123fc320162783640d8f2756afeb7e950;
            proof[3] = 0x88a7a1a219718b082a1112eddad0d460dfe0ae9c2dd1daf761b12e6683fb90ce;
            proof[4] = 0xbf615bf398953118a2c0e685bab4eb0a29074e9f08ccfed7d2088574db8f372d;
            proof[5] = 0xe6b5783ab6992c92784f24482c2b296287c0812083240938ddeef56a0abd1278;
            proof[6] = 0xc26c98ebdb92f38d8ac12a461227c14226f318ef22a178ec3f30038945f4d947;
            proof[7] = 0x161e2c8724eaac66410c1aede5d0404614d687dcc946730a6c9118d20efc5d58;
            proof[8] = 0x0de08c23b5ea1aedd4375b8609758819d8c3b0558e54e7da06dce44ef25f6e6c;
            proof[9] = 0x629ab7c90c97d727179ffff8f335ad930e88300a4f1ce10930dfff25e351d594;
            proof[10] = 0xe77b1a8da1ba7e18fde796a99147c73a139d97ca65304cb01700a523a6a101f0;
            proof[11] = 0x8c7d80a3b519a6c742f5eb32676a48f1da00e8116914a9b8ba7a3bb3dd2f350c;
            proof[12] = 0x82f65c0bdc1ad79754a0f70ec0ab0f5b9cfcbeb42cc944b73f9da31ff50fd1d2;
            proof[13] = 0x2e2d5256bc54cf513d3fcd51601f3c0b19f69b24f7e35cfff85086dfbcd42cff;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            // Leaf 8992
            proof = new bytes32[](13);
            proof[0] = 0xd57ec21f7547cb60ea07337703f065d34dd8e302225287b26e4999620a4da07e;
            proof[1] = 0x2862154e290ebedb1203767552cde13c5f5c362000c4ef29b1a8d797d75150b6;
            proof[2] = 0x62be384a2d7b0c59090f998e683e9f812d5d1bf1348da43fd9bcaffa497b080a;
            proof[3] = 0x82a75a436dc6ffa7a9c72e43d6fa7408513a487b080e152c9314bcd893bf856f;
            proof[4] = 0x0f1526afae95465a29b18b07252354952073a278fb1dbfeaae9fe7fe7becb580;
            proof[5] = 0x4624ec3c36956207784a02fbba92116bedd7cde52a0c474e53755dbde76f2764;
            proof[6] = 0xa0fa404b7ef7fbd604025e2b2f33c7ba1c49f6d28252725905059ad12c347645;
            proof[7] = 0x84d64da0ba04c59721b65ae3c0cbf481c9268749768d1ecdf1138009ae8ab01d;
            proof[8] = 0xf8fcd1b874cbe170a1267ed867d84b609d4a2e25f8116149768ef9f93178c2fb;
            proof[9] = 0x0f8fb0660dbc17d3f848ec31e2ff561cf27fa845ae2b137e353a8c7e97a02730;
            proof[10] = 0x7106c51977b78e53883b59d022fc5fbc4ff5a332e1ff0c2fa2d165b94a7552f9;
            proof[11] = 0xc1aa0f0beb9b0d1c6e631e4ea4bdba0ba97369364d2dee402a456b69182051fa;
            proof[12] = 0xcf092fa45614ed55511fb9aee1350689157934c0f689296509a50ace41ba103d;
        } else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 9364
            proof = new bytes32[](13);
            proof[0] = 0xde68379329e8496f64f33180a730eaefd315a56b9da33c73b46c6e3203a1c818;
            proof[1] = 0x660fbd456a1e2c3157fe9de135a3abb5d747bb62848aa35681c155c873fba182;
            proof[2] = 0x28afa2431e9afb22416477858c9abd6647beb0b44fba701ab75e631da4ba8b83;
            proof[3] = 0xb3de30c35318200914d27844d2ec4771b34a60e65f63960dd6f568890b67524b;
            proof[4] = 0x94c4a6f5cfed2e20c8c3831b15b52f985b8aedbcc1f42e38f4bc1fde186e2e38;
            proof[5] = 0x32f6a7e19cd654d33ebd8c59586a817a6a42a0a10cf8c7214e1188cbc5114f2f;
            proof[6] = 0xde2dae5f806b9c2e3879ec42201044aaa57d0a5c7fa70007db31e5f8a5ef27d5;
            proof[7] = 0x453de2c28b2227cdac75597b469a9dcc2a4f7db473bf63bdb26566eced91c010;
            proof[8] = 0xc03e3a49c07c7d263b4ba3b3152df1d523d580b12a6edb00519ef888b1a4b21f;
            proof[9] = 0x8374dc029b0ce76e24580dd50f920b34b741441c8eba44cbb9b9743c4b6fb472;
            proof[10] = 0x809050cc479eefb2630b8288cad2d1d4af5137d868d7c354b1ac2475f69402db;
            proof[11] = 0xc1aa0f0beb9b0d1c6e631e4ea4bdba0ba97369364d2dee402a456b69182051fa;
            proof[12] = 0xcf092fa45614ed55511fb9aee1350689157934c0f689296509a50ace41ba103d;
        } else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            // Leaf 9840
            proof = new bytes32[](13);
            proof[0] = 0xea0de5999181039b689ed0b7fe2ac860a341859e68dabfd5a431b7df4c9e7560;
            proof[1] = 0xd462e835af65a2c9eb3c87761df1e89897520e953a54f85856c533f44c8cca98;
            proof[2] = 0x1a536dee2f1fcaf17429cb52f2b920cc291e5f4ae848c3ab17d56307f51fa90b;
            proof[3] = 0x42d28d7126b17a953948458003dfc0bb292104c2d7362127efd365d0d69b089e;
            proof[4] = 0x2792c886202ef892a645c88b362b1859dbe0215d157a96cd33ecabf54c866247;
            proof[5] = 0xb1271f670b47478a2598f8cdaf3d0258be5f44abe80d5582cb3eac68f94f856a;
            proof[6] = 0x432426f7676d70182c41e6b0c154448108baf67d138538e8396ace8a8fbe3584;
            proof[7] = 0x34e0304b56f7ae0973b4dd4f22e9adf5b327dea2eadb65015cd66e1d3d524ef9;
            proof[8] = 0xc9c44fa9733049dad174565fa43e9b9a877d301da830ffd77a17be510c5118d2;
            proof[9] = 0x68aff0a9da8988b867e174c478e023afabf2101c95ad6a1746bb32cbc9d74d75;
            proof[10] = 0x809050cc479eefb2630b8288cad2d1d4af5137d868d7c354b1ac2475f69402db;
            proof[11] = 0xc1aa0f0beb9b0d1c6e631e4ea4bdba0ba97369364d2dee402a456b69182051fa;
            proof[12] = 0xcf092fa45614ed55511fb9aee1350689157934c0f689296509a50ace41ba103d;
        } else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            // Leaf 9842
            proof = new bytes32[](13);
            proof[0] = 0xea13d76efb4ff4994a62a5cd22b44d6cf1cf602df7792cb0b297b654f7bd30e0;
            proof[1] = 0xde7e817896cba5c8034c389f6dabb9b202e61e7f67519a00348eaa6793ff31d1;
            proof[2] = 0x1a536dee2f1fcaf17429cb52f2b920cc291e5f4ae848c3ab17d56307f51fa90b;
            proof[3] = 0x42d28d7126b17a953948458003dfc0bb292104c2d7362127efd365d0d69b089e;
            proof[4] = 0x2792c886202ef892a645c88b362b1859dbe0215d157a96cd33ecabf54c866247;
            proof[5] = 0xb1271f670b47478a2598f8cdaf3d0258be5f44abe80d5582cb3eac68f94f856a;
            proof[6] = 0x432426f7676d70182c41e6b0c154448108baf67d138538e8396ace8a8fbe3584;
            proof[7] = 0x34e0304b56f7ae0973b4dd4f22e9adf5b327dea2eadb65015cd66e1d3d524ef9;
            proof[8] = 0xc9c44fa9733049dad174565fa43e9b9a877d301da830ffd77a17be510c5118d2;
            proof[9] = 0x68aff0a9da8988b867e174c478e023afabf2101c95ad6a1746bb32cbc9d74d75;
            proof[10] = 0x809050cc479eefb2630b8288cad2d1d4af5137d868d7c354b1ac2475f69402db;
            proof[11] = 0xc1aa0f0beb9b0d1c6e631e4ea4bdba0ba97369364d2dee402a456b69182051fa;
            proof[12] = 0xcf092fa45614ed55511fb9aee1350689157934c0f689296509a50ace41ba103d;
        } else {
            revert("Unknown (inputReceiver, executor) combo - not in ApproveAndSwapOdosV2Hook WBTC->USDC tree");
        }
    }

    /// @dev Sets a pre-computed merkle root directly (no leaf computation, just propose+timelock+execute).
    function _setMerkleRoot(address hook, bytes32 root) internal {
        superGovernor.proposeSuperBankHookMerkleRoot(hook, root);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook), root, "Merkle root mismatch");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     MERKLE TREE REGISTRATION
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Creates a single-leaf merkle tree (root == leaf) and registers it through the governance timelock.
    ///      For SuperBank, the merkle tree is simpler than SuperVault:
    ///        leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
    ///      where hookArgs = hook.inspect(hookData).
    ///      Single-leaf tree: root == leaf, empty proof.
    function _registerMerkleRoot(address hook, bytes memory hookData) internal {
        bytes memory hookArgs = ISuperHookInspector(hook).inspect(hookData);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));

        superGovernor.proposeSuperBankHookMerkleRoot(hook, leaf);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook), leaf, "Merkle root mismatch");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     HOOK DATA ENCODING
    // ═══════════════════════════════════════════════════════════════════

    /// @dev ApproveERC20Hook data: [token][spender][amount][usePrevHookAmount]
    function _encodeApproveHookData(
        address token,
        address spender,
        uint256 amount,
        bool usePrevHookAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(token, spender, amount, usePrevHookAmount);
    }

    /// @dev AcrossSendFundsAndExecuteOnDstHook data layout (see AcrossSendFundsAndExecuteOnDstHook.sol)
    ///      [value(32)][recipient(20)][inputToken(20)][outputToken(20)][inputAmount(32)][outputAmount(32)]
    ///      [destinationChainId(32)][exclusiveRelayer(20)][fillDeadlineOffset(4)][exclusivityPeriod(4)]
    ///      [usePrevHookAmount(1)][destinationMessage(variable)]
    function _encodeAcrossHookData(
        address recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 destinationChainId,
        bool usePrevHookAmount,
        bytes memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            uint256(0), // value
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            outputAmount,
            destinationChainId,
            address(0), // exclusiveRelayer
            uint32(10 minutes), // fillDeadlineOffset
            uint32(0), // exclusivityPeriod
            usePrevHookAmount,
            message
        );
    }

    /// @dev SwapOdosV2Hook data layout (see SwapOdosV2Hook.sol for offsets)
    function _encodeSwapOdosHookData(
        address inputToken,
        uint256 inputAmount,
        address inputReceiver,
        address outputToken,
        uint256 outputQuote,
        uint256 outputMin,
        bool usePrevHookAmount,
        bytes memory pathDefinition,
        address executor,
        uint32 referralCode
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            inputToken,
            inputAmount,
            inputReceiver,
            outputToken,
            outputQuote,
            outputMin,
            usePrevHookAmount,
            pathDefinition.length,
            pathDefinition,
            executor,
            referralCode
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     EXECUTION DATA BUILDER
    // ═══════════════════════════════════════════════════════════════════

    function _buildExecutionData(
        address approveHook,
        address swapHook,
        bytes memory approveData,
        bytes memory swapData
    )
        internal
        pure
        returns (IHookExecutionData.HookExecutionData memory)
    {
        address[] memory hooks = new address[](2);
        hooks[0] = approveHook;
        hooks[1] = swapHook;

        bytes[] memory data = new bytes[](2);
        data[0] = approveData;
        data[1] = swapData;

        // Single-leaf merkle trees → empty proofs (root == leaf verification)
        bytes32[][] memory proofs = new bytes32[][](2);
        proofs[0] = new bytes32[](0);
        proofs[1] = new bytes32[](0);

        // 0 = no minimum at Bank level; slippage enforced by hook's outputMin
        uint256[] memory expectedOut = new uint256[](2);

        return IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: data,
            merkleProofs: proofs,
            expectedAssetsOrSharesOut: expectedOut
        });
    }

    /// @dev Builds execution data for a single hook with a production merkle proof.
    function _buildSingleHookExecutionData(
        address hook,
        bytes memory data,
        bytes32[] memory proof
    )
        internal
        pure
        returns (IHookExecutionData.HookExecutionData memory)
    {
        address[] memory hooks = new address[](1);
        hooks[0] = hook;

        bytes[] memory dataArr = new bytes[](1);
        dataArr[0] = data;

        bytes32[][] memory proofs = new bytes32[][](1);
        proofs[0] = proof;

        uint256[] memory expectedOut = new uint256[](1);

        return IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: dataArr,
            merkleProofs: proofs,
            expectedAssetsOrSharesOut: expectedOut
        });
    }

    /// @dev Builds execution data for two hooks with production merkle proofs.
    function _buildExecutionDataWithProofs(
        address hook1,
        address hook2,
        bytes memory data1,
        bytes memory data2,
        bytes32[] memory proof1,
        bytes32[] memory proof2
    )
        internal
        pure
        returns (IHookExecutionData.HookExecutionData memory)
    {
        address[] memory hooks = new address[](2);
        hooks[0] = hook1;
        hooks[1] = hook2;

        bytes[] memory dataArr = new bytes[](2);
        dataArr[0] = data1;
        dataArr[1] = data2;

        bytes32[][] memory proofs = new bytes32[][](2);
        proofs[0] = proof1;
        proofs[1] = proof2;

        uint256[] memory expectedOut = new uint256[](2);

        return IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: dataArr,
            merkleProofs: proofs,
            expectedAssetsOrSharesOut: expectedOut
        });
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     ACCESS CONTROL HELPER
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Grants a role on the SuperGovernor by writing directly to AccessControl storage.
    ///      OZ 5.x AccessControl: _roles mapping at slot 0.
    ///      _roles[role].hasRole[account] =
    ///        keccak256(abi.encode(account, keccak256(abi.encode(role, uint256(0)))))
    function _forceGrantRole(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR_ADDR, hasRoleSlot, bytes32(uint256(1)));
    }
}
