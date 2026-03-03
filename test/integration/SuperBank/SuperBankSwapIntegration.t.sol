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
