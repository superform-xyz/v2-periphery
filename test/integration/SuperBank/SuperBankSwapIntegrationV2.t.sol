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
import { Surl } from "@surl/Surl.sol";
import { strings } from "@stringutils/strings.sol";
import { AcrossV3Helper } from "@pigeon/across/AcrossV3Helper.sol";

/// @title SuperBankSwapIntegrationV2
/// @notice Integration tests for the redeployed (standardized) SwapOdosV2Hook, ApproveAndSwapOdosV2Hook,
///         AcrossSendFundsAndExecuteOnDstHook and ApproveAndAcrossSendFundsAndExecuteOnDstHook.
/// @dev Uses production-deployed contracts on Base/ETH forks. No mocks. Odos quotes fetched via surl.
///      Validates production merkle roots from superman/deployments/superbank/generated/prod/{1,8453}/:
///        ETH  AcrossSendFundsHook   (0xeA1b9ab1...): root 0x8f9ac93a..., 1188 leaves
///        ETH  ApproveAndAcrossHook  (0xDeF02397...): root 0xe9993d52..., 1188 leaves
///        ETH  ApproveAndSwapOdosV2  (0x3b2dbedf...): root 0x248fc37d..., 4 leaves (output tokens)
///        Base SwapOdosV2Hook        (0xE03FDd61...): root 0xd631e923..., 4 leaves (output tokens)
///        Base ApproveAndSwapOdosV2  (0x2334321d...): root 0xb9e3c9b8..., 4 leaves (output tokens)
///
///      The redeployed swap hooks use the standardized calldata layout (52-byte zero header + Layer 1 +
///      Layer 2 payload) and inspect() returns abi.encodePacked(outputToken), so proofs are selected by
///      output token. The Across hooks keep the same inspect args but their data layout also gained the
///      52-byte header. ApproveERC20Hook was NOT part of this redeployment scope — the previously
///      deployed instance (0x8b789980...) and its production tree are still used here.
///
/// Run:
///   forge test --match-contract SuperBankSwapIntegrationV2 -vvv
contract SuperBankSwapIntegrationV2 is Test, OdosAPIParser {
    using Surl for *;
    using strings for *;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (BASE MAINNET)
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // v2-core prod hooks (Base) — ApproveERC20Hook unchanged, SwapOdosV2Hook redeployed
    address constant APPROVE_ERC20_HOOK = 0x8b789980dc6cC7d88E30C442D704646ff7F6d306;
    address constant SWAP_ODOS_V2_HOOK = 0xE03FDd61D40045079e7aF3A381F80DD74739546e;

    // Tokens
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant UP = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address constant BASE_WETH = 0x4200000000000000000000000000000000000006;
    address constant BASE_CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    // Cross-chain UP variants (leaves of the output-token trees)
    address constant ETH_UP = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;
    address constant UP_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

    // Odos router (DEX aggregator — routes through Aerodrome, Uniswap v4, PancakeSwap, etc.)
    address constant ODOS_ROUTER = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1;

    // Chain
    uint256 constant BASE_CHAIN_ID = 8453;
    uint256 constant ETH_CHAIN_ID = 1;

    // ETH mainnet addresses (for cross-chain bridge test) — Across hooks redeployed
    address constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ACROSS_SEND_FUNDS_HOOK_ETH = 0xeA1b9ab11EC33F40fB36548cad1032DA9293c5f3;
    address constant APPROVE_AND_ACROSS_HOOK_ETH = 0xDeF02397EDBF7D0Da1E10fE297362c3aDf358fA1;
    address constant ETH_SPOKE_POOL = 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address constant BASE_SPOKE_POOL = 0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64;

    // ETH mainnet addresses (for ApproveAndSwapOdosV2Hook test) — hook redeployed
    address constant ETH_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ETH_WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant APPROVE_AND_SWAP_ODOS_V2_HOOK = 0x3b2dbedf63aB4D5F7652D8845C0EDA1fA42263cd;

    // Base ApproveAndSwapOdosV2Hook (single hook: approve + swap in one call) — redeployed
    address constant BASE_APPROVE_AND_SWAP_ODOS_V2_HOOK = 0x2334321db75F2889b44d10826b511ABE57C62Adf;

    // ── Production merkle roots (from superman/deployments/superbank/generated/prod/) ──
    // Base ApproveERC20Hook (unchanged deployment): 65 leaves
    bytes32 constant BASE_APPROVE_ERC20_ROOT = 0xdaa40f360d2bee5c44c9780104cba8949e13e9c32fb9f57f84a1e790d2fec412;
    // ETH ApproveERC20Hook (unchanged deployment): 165 leaves
    bytes32 constant ETH_APPROVE_ERC20_ROOT = 0xfa69a2a289b14c7a0b1b34de4e82e0a1d4582e315b301e965b26e432bba0e456;
    // Base SwapOdosV2Hook (redeployed): 4 leaves (output tokens)
    bytes32 constant BASE_SWAP_ODOS_V2_ROOT = 0xd631e923cdc355660cd79ca08fabdc9d4e295c4e3d72123af473ad247ab84ab4;
    // ETH ApproveAndSwapOdosV2Hook (redeployed): 4 leaves (output tokens)
    bytes32 constant ETH_APPROVE_AND_SWAP_ODOS_V2_ROOT =
        0x248fc37dcada309d7c32ce5f271c0e67f62d00e0716d9f10a9380f718e5d8800;
    // Base ApproveAndSwapOdosV2Hook (redeployed): 4 leaves (output tokens)
    bytes32 constant BASE_APPROVE_AND_SWAP_ODOS_V2_ROOT =
        0xb9e3c9b82b8f5de43bc743c1aeece9cf4869a2781a84e6fb3fe6db1e37f8f430;
    // ETH AcrossSendFundsAndExecuteOnDstHook (redeployed): 1188 leaves (incl. Base WETH/cbBTC outputs)
    bytes32 constant ETH_ACROSS_ROOT = 0x8f9ac93ada5514175ee0fa87614a428bd97e0edfbdd6af5b09efc2654c227ded;
    // ETH ApproveAndAcrossSendFundsAndExecuteOnDstHook (redeployed): 1188 leaves (incl. Base WETH/cbBTC outputs)
    bytes32 constant ETH_APPROVE_AND_ACROSS_ROOT =
        0xe9993d523de6c75ebe945a2adfd7646564f799a7f35be10bc1f8bec1ca9c2a26;

    // Base Across hooks (redeployed) — for Base-origin bridging
    address constant ACROSS_SEND_FUNDS_HOOK_BASE = 0xF583a7826Da0917a8d45eC4457d45D26D251B152;
    address constant APPROVE_AND_ACROSS_HOOK_BASE = 0x3170e72b2F8Ea2a7028374B051C5D443F5bcA91a;
    // Base AcrossSendFundsAndExecuteOnDstHook (redeployed): 169 leaves
    bytes32 constant BASE_ACROSS_ROOT = 0x6bc2e59da85e5eebcff11a9de5f2154654d59a24d21ecade2f56f4af92c34365;
    // Base ApproveAndAcrossSendFundsAndExecuteOnDstHook (redeployed): 169 leaves
    bytes32 constant BASE_APPROVE_AND_ACROSS_ROOT =
        0xb5f07630f5ff4ca4ea8b7caf7fe8d1f6dafe26c7472405de6a4948b8483e711d;

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

    /// @dev Minimal Odos quote request to check API availability. Skips the test suite if unreachable.
    function _skipIfOdosUnavailable() internal {
        string memory body = '{"chainId":8453,"inputTokens":[{"tokenAddress":"0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913","amount":"1000000"}],"outputTokens":[{"tokenAddress":"0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B","proportion":1}],"userAddr":"0x0000000000000000000000000000000000000001","compact":true}';
        string[] memory headers = new string[](1);
        headers[0] = "Content-Type: application/json";
        (uint256 status,) = API_QUOTE_URL.post(headers, body);
        if (status != 200) {
            vm.skip(true);
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                              TEST
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: deal USDC to SuperBank, fetch live Odos quote, approve + swap, receive UP
    /// @dev Single-leaf roots computed dynamically via each hook's inspect() — exercises the redeployed
    ///      SwapOdosV2Hook's new inspect() (returns outputToken).
    function test_executeHooks_swapUSDCtoUP() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        uint256 swapAmount = 100e6; // 100 USDC

        // 1. Fund SuperBank with USDC
        deal(USDC, SUPER_BANK, swapAmount);
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), swapAmount);

        // 2. Fetch live Odos quote via surl (no external scripts needed)
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: USDC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: UP, proportion: 1 });

        // Blacklist "Metric" source to avoid MetricOMM pools that may return zero output on fork
        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
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
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
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
    }

    // ═══════════════════════════════════════════════════════════════════
    //              TEST WITH PRODUCTION MERKLE TREES
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Same USDC->UP swap flow but using production-generated merkle trees.
    /// @dev ApproveERC20Hook (0x8b789980...): unchanged deployment, existing production root.
    ///      SwapOdosV2Hook  (0xE03FDd61...): redeployed, output-token tree (proof = UP leaf).
    function test_executeHooks_swapUSDCtoUP_withProductionMerkleTree() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        uint256 swapAmount = 100e6; // 100 USDC

        // 1. Fund SuperBank with USDC
        deal(USDC, SUPER_BANK, swapAmount);
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), swapAmount);

        // 2. Fetch live Odos quote via surl
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: USDC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: UP, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
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
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // 4. Set production merkle roots
        _setMerkleRoot(APPROVE_ERC20_HOOK, BASE_APPROVE_ERC20_ROOT);
        _setMerkleRoot(SWAP_ODOS_V2_HOOK, BASE_SWAP_ODOS_V2_ROOT);

        // 5. Execute with production proofs (swap proof selected by output token)
        uint256 upBefore = IERC20(UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildExecutionDataWithProofs(
                APPROVE_ERC20_HOOK,
                SWAP_ODOS_V2_HOOK,
                approveData,
                swapData,
                _getBaseApproveUsdcForOdosRouterProof(),
                _getBaseSwapOdosOutputProof(UP)
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

    /// @notice Bridges USDC from SuperBank on ETH to SuperBank on Base via the redeployed Across hook,
    ///         then swaps USDC→UP on Base via the redeployed SwapOdosV2Hook.
    /// @dev Multi-fork test using Pigeon (AcrossV3Helper) to simulate the cross-chain relay.
    ///      Phase 1: ETH fork — approve USDC for SpokePool + bridge via AcrossSendFundsAndExecuteOnDstHook
    ///      Phase 2: Pigeon relay — AcrossV3Helper fills the relay on Base fork
    ///      Phase 3: Base fork — approve USDC for Odos Router + swap via SwapOdosV2Hook
    function test_executeHooks_bridgeAndSwapUSDCtoUP() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        uint256 baseForkId = vm.activeFork();
        uint256 baseOriginalTimestamp = block.timestamp;

        // Phase 1: Bridge USDC from ETH to Base
        Vm.Log[] memory logs = _bridgeFromEthToBase(
            ETH_USDC, USDC, 100e6, _getApproveUsdcForSpokePoolProof(), _getUsdcEthToBaseAcrossProof()
        );

        // Phase 2: Pigeon relay (may advance Base fork timestamp)
        _relayAcrossBridge(logs, baseForkId);

        // Phase 3: Swap USDC→UP on Base
        vm.selectFork(baseForkId);
        vm.warp(baseOriginalTimestamp); // Restore to avoid stale oracle prices
        _swapUsdcToUpOnBase();
    }

    /// @dev Phase 1: On ETH fork, approve + bridge a token to SuperBank on Base via the redeployed Across hook.
    ///      Approve: existing ApproveERC20Hook production tree (token, spender=SpokePool ETH)
    ///      Across:  redeployed hook production tree (ethToken ETH→baseToken Base, SuperBank recipient)
    function _bridgeFromEthToBase(
        address ethToken,
        address baseToken,
        uint256 bridgeAmount,
        bytes32[] memory approveProof,
        bytes32[] memory acrossProof
    )
        internal
        returns (Vm.Log[] memory logs)
    {
        vm.selectFork(vm.createFork(vm.envString("ETHEREUM_RPC_URL")));

        // Grant roles on ETH fork (same SuperGovernor address, different chain state)
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        // Register hooks on ETH
        superGovernor.registerHook(APPROVE_ERC20_HOOK);
        superGovernor.registerHook(ACROSS_SEND_FUNDS_HOOK_ETH);

        // Fund SuperBank on ETH
        deal(ethToken, SUPER_BANK, bridgeAmount);
        assertEq(IERC20(ethToken).balanceOf(SUPER_BANK), bridgeAmount, "ETH token not dealt");

        // Approve: production merkle root from hook_0x8b789980...json (unchanged hook)
        _setMerkleRoot(APPROVE_ERC20_HOOK, ETH_APPROVE_ERC20_ROOT);

        // Across: production merkle root from hook_0xea1b9ab1...json (redeployed hook, 1188 leaves)
        _setMerkleRoot(ACROSS_SEND_FUNDS_HOOK_ETH, ETH_ACROSS_ROOT);

        // Execute hooks: approve + bridge with production proofs
        // (struct built field-by-field to avoid stack-too-deep)
        IHookExecutionData.HookExecutionData memory ed;
        ed.hooks = new address[](2);
        ed.hooks[0] = APPROVE_ERC20_HOOK;
        ed.hooks[1] = ACROSS_SEND_FUNDS_HOOK_ETH;
        ed.data = new bytes[](2);
        ed.data[0] = _encodeApproveHookData(ethToken, ETH_SPOKE_POOL, bridgeAmount, false);
        ed.data[1] = _encodeAcrossHookData(
            SUPER_BANK, ethToken, baseToken, bridgeAmount, bridgeAmount * 99 / 100, BASE_CHAIN_ID, false, bytes("")
        );
        ed.merkleProofs = new bytes32[][](2);
        ed.merkleProofs[0] = approveProof;
        ed.merkleProofs[1] = acrossProof;
        ed.expectedAssetsOrSharesOut = new uint256[](2);

        vm.recordLogs();
        superBank.executeHooks(ed);
        logs = vm.getRecordedLogs();

        assertEq(IERC20(ethToken).balanceOf(SUPER_BANK), 0, "All ETH tokens should be consumed by the bridge");
        console2.log("Phase 1: Bridged %d from ETH to Base", bridgeAmount);
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

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
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
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // Set production merkle roots
        _setMerkleRoot(APPROVE_ERC20_HOOK, BASE_APPROVE_ERC20_ROOT);
        _setMerkleRoot(SWAP_ODOS_V2_HOOK, BASE_SWAP_ODOS_V2_ROOT);

        // Execute with production proofs (swap proof selected by output token)
        uint256 upBefore = IERC20(UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildExecutionDataWithProofs(
                APPROVE_ERC20_HOOK,
                SWAP_ODOS_V2_HOOK,
                approveData,
                swapData,
                _getBaseApproveUsdcForOdosRouterProof(),
                _getBaseSwapOdosOutputProof(UP)
            )
        );

        uint256 upAfter = IERC20(UP).balanceOf(SUPER_BANK);
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), 0, "All USDC should be consumed by the swap");
        assertGt(upAfter - upBefore, 0, "SuperBank should have received UP tokens");

        console2.log("Swap result: %d USDC -> %d UP", usdcOnBase, upAfter - upBefore);
    }

    /// @dev Phase 3: Verify the bridged token arrived on Base SuperBank.
    ///      No swap leg: keeps the bridge tests independent of external swap-aggregator APIs.
    function _assertBridgedTokenArrived(address token) internal view {
        uint256 tokenOnBase = IERC20(token).balanceOf(SUPER_BANK);
        assertGt(tokenOnBase, 0, "Token should have arrived on Base via bridge");
        console2.log("Phase 3: bridged token received on Base:", tokenOnBase);
    }

    // ═══════════════════════════════════════════════════════════════════
    //      BRIDGE VIA ApproveAndAcrossSendFundsAndExecuteOnDstHook
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Bridges USDC from ETH to Base using the redeployed ApproveAndAcross (single combined hook)
    ///         then swaps USDC→UP.
    /// @dev Same flow as test_executeHooks_bridgeAndSwapUSDCtoUP() but uses ApproveAndAcross (1 hook)
    ///      instead of ApproveERC20Hook + AcrossSendFundsHook (2 hooks).
    function test_executeHooks_bridgeAndSwapUSDCtoUP_withApproveAndAcross() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        uint256 baseForkId = vm.activeFork();
        uint256 baseOriginalTimestamp = block.timestamp;

        // Phase 1: Bridge USDC from ETH to Base using combined ApproveAndAcross hook
        Vm.Log[] memory logs = _bridgeFromEthToBase_withApproveAndAcross(
            ETH_USDC, USDC, 100e6, _getApproveAndAcrossUsdcEthToBaseProof()
        );

        // Phase 2: Pigeon relay
        _relayAcrossBridge(logs, baseForkId);

        // Phase 3: Swap USDC→UP on Base (same as existing test)
        vm.selectFork(baseForkId);
        vm.warp(baseOriginalTimestamp);
        _swapUsdcToUpOnBase();
    }

    /// @dev Phase 1: On ETH fork, bridge a token to SuperBank on Base via the redeployed ApproveAndAcross hook.
    ///      Uses the production merkle tree (ethToken ETH→baseToken Base, SuperBank recipient).
    function _bridgeFromEthToBase_withApproveAndAcross(
        address ethToken,
        address baseToken,
        uint256 bridgeAmount,
        bytes32[] memory acrossProof
    )
        internal
        returns (Vm.Log[] memory logs)
    {
        uint256 ethForkId = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        vm.selectFork(ethForkId);

        // Grant roles on ETH fork
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        // Register the combined hook
        superGovernor.registerHook(APPROVE_AND_ACROSS_HOOK_ETH);

        // Fund SuperBank on ETH
        deal(ethToken, SUPER_BANK, bridgeAmount);
        assertEq(IERC20(ethToken).balanceOf(SUPER_BANK), bridgeAmount, "ETH token not dealt");

        // Encode hook data (same layout as AcrossSendFundsHook — the hook handles approval internally)
        bytes memory acrossData = _encodeAcrossHookData(
            SUPER_BANK, ethToken, baseToken, bridgeAmount, bridgeAmount * 99 / 100, BASE_CHAIN_ID, false, bytes("")
        );

        // ApproveAndAcross: production merkle root (redeployed hook, 1188 leaves)
        _setMerkleRoot(APPROVE_AND_ACROSS_HOOK_ETH, ETH_APPROVE_AND_ACROSS_ROOT);

        // Execute: single hook with production proof
        vm.recordLogs();
        superBank.executeHooks(
            _buildSingleHookExecutionData(APPROVE_AND_ACROSS_HOOK_ETH, acrossData, acrossProof)
        );
        logs = vm.getRecordedLogs();

        assertEq(IERC20(ethToken).balanceOf(SUPER_BANK), 0, "All ETH tokens should be consumed by the bridge");
        console2.log("Phase 1 (ApproveAndAcross): Bridged %d from ETH to Base", bridgeAmount);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              CROSS-CHAIN BRIDGE WETH / WBTC TESTS
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Bridges WETH from SuperBank on ETH to SuperBank on Base via the redeployed Across hook
    ///         (ApproveERC20Hook + AcrossSendFundsAndExecuteOnDstHook) and verifies arrival.
    function test_executeHooks_bridgeWETHtoBase() public {
        uint256 baseForkId = vm.activeFork();
        uint256 baseOriginalTimestamp = block.timestamp;

        // Phase 1: Bridge WETH from ETH to Base WETH
        Vm.Log[] memory logs = _bridgeFromEthToBase(
            ETH_WETH, BASE_WETH, 0.05 ether, _getApproveWethForSpokePoolProof(), _getWethEthToBaseAcrossProof()
        );

        // Phase 2: Pigeon relay
        _relayAcrossBridge(logs, baseForkId);

        // Phase 3: Verify WETH arrived on Base SuperBank
        vm.selectFork(baseForkId);
        vm.warp(baseOriginalTimestamp);
        _assertBridgedTokenArrived(BASE_WETH);
    }

    /// @notice Bridges WETH from ETH to Base using the redeployed ApproveAndAcross (single combined hook)
    ///         and verifies arrival.
    function test_executeHooks_bridgeWETHtoBase_withApproveAndAcross() public {
        uint256 baseForkId = vm.activeFork();
        uint256 baseOriginalTimestamp = block.timestamp;

        // Phase 1: Bridge WETH from ETH to Base WETH using combined ApproveAndAcross hook
        Vm.Log[] memory logs = _bridgeFromEthToBase_withApproveAndAcross(
            ETH_WETH, BASE_WETH, 0.05 ether, _getApproveAndAcrossWethEthToBaseProof()
        );

        // Phase 2: Pigeon relay
        _relayAcrossBridge(logs, baseForkId);

        // Phase 3: Verify WETH arrived on Base SuperBank
        vm.selectFork(baseForkId);
        vm.warp(baseOriginalTimestamp);
        _assertBridgedTokenArrived(BASE_WETH);
    }

    /// @notice Bridges WBTC from SuperBank on ETH to cbBTC on Base SuperBank via the redeployed Across hook
    ///         (ApproveERC20Hook + AcrossSendFundsAndExecuteOnDstHook) and verifies arrival.
    function test_executeHooks_bridgeWBTCtoCbBtcOnBase() public {
        uint256 baseForkId = vm.activeFork();
        uint256 baseOriginalTimestamp = block.timestamp;

        // Phase 1: Bridge WBTC (8 decimals) from ETH to cbBTC (8 decimals) on Base
        Vm.Log[] memory logs = _bridgeFromEthToBase(
            ETH_WBTC, BASE_CBBTC, 1e6, _getApproveWbtcForSpokePoolProof(), _getWbtcEthToBaseAcrossProof()
        );

        // Phase 2: Pigeon relay
        _relayAcrossBridge(logs, baseForkId);

        // Phase 3: Verify cbBTC arrived on Base SuperBank
        vm.selectFork(baseForkId);
        vm.warp(baseOriginalTimestamp);
        _assertBridgedTokenArrived(BASE_CBBTC);
    }

    /// @notice Bridges WBTC from ETH to cbBTC on Base using the redeployed ApproveAndAcross
    ///         (single combined hook) and verifies arrival.
    function test_executeHooks_bridgeWBTCtoCbBtcOnBase_withApproveAndAcross() public {
        uint256 baseForkId = vm.activeFork();
        uint256 baseOriginalTimestamp = block.timestamp;

        // Phase 1: Bridge WBTC from ETH to cbBTC on Base using combined ApproveAndAcross hook
        Vm.Log[] memory logs = _bridgeFromEthToBase_withApproveAndAcross(
            ETH_WBTC, BASE_CBBTC, 1e6, _getApproveAndAcrossWbtcEthToBaseProof()
        );

        // Phase 2: Pigeon relay
        _relayAcrossBridge(logs, baseForkId);

        // Phase 3: Verify cbBTC arrived on Base SuperBank
        vm.selectFork(baseForkId);
        vm.warp(baseOriginalTimestamp);
        _assertBridgedTokenArrived(BASE_CBBTC);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              CROSS-CHAIN BRIDGE BASE → ETH (cbBTC) TESTS
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Bridges cbBTC from SuperBank on Base to SuperBank on ETH via the redeployed Base Across hook
    ///         (ApproveERC20Hook + AcrossSendFundsAndExecuteOnDstHook) and verifies arrival.
    /// @dev cbBTC has the same address on Base and ETH mainnet, so the Base tree's output leaf is
    ///      cross-chain valid.
    function test_executeHooks_bridgeCbBtcBaseToEth() public {
        Vm.Log[] memory logs = _bridgeCbBtcFromBaseToEth(false);

        uint256 ethForkId = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        _relayAcrossBridgeToEth(logs, ethForkId);

        vm.selectFork(ethForkId);
        _assertBridgedTokenArrived(BASE_CBBTC); // same cbBTC address on ETH
    }

    /// @notice Bridges cbBTC from Base to ETH using the redeployed Base ApproveAndAcross
    ///         (single combined hook) and verifies arrival.
    function test_executeHooks_bridgeCbBtcBaseToEth_withApproveAndAcross() public {
        Vm.Log[] memory logs = _bridgeCbBtcFromBaseToEth(true);

        uint256 ethForkId = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        _relayAcrossBridgeToEth(logs, ethForkId);

        vm.selectFork(ethForkId);
        _assertBridgedTokenArrived(BASE_CBBTC); // same cbBTC address on ETH
    }

    /// @dev Phase 1: On the Base fork (active from setUp), bridge cbBTC to SuperBank on ETH.
    ///      useCombinedHook=false: ApproveERC20Hook + AcrossSendFundsAndExecuteOnDstHook (Base trees)
    ///      useCombinedHook=true:  ApproveAndAcrossSendFundsAndExecuteOnDstHook (single hook)
    function _bridgeCbBtcFromBaseToEth(bool useCombinedHook) internal returns (Vm.Log[] memory logs) {
        uint256 bridgeAmount = 1e6; // 0.01 cbBTC (8 decimals)
        deal(BASE_CBBTC, SUPER_BANK, bridgeAmount);

        bytes memory acrossData = _encodeAcrossHookData(
            SUPER_BANK, BASE_CBBTC, BASE_CBBTC, bridgeAmount, bridgeAmount * 99 / 100, ETH_CHAIN_ID, false, bytes("")
        );

        vm.recordLogs();
        if (useCombinedHook) {
            superGovernor.registerHook(APPROVE_AND_ACROSS_HOOK_BASE);
            _setMerkleRoot(APPROVE_AND_ACROSS_HOOK_BASE, BASE_APPROVE_AND_ACROSS_ROOT);
            superBank.executeHooks(
                _buildSingleHookExecutionData(
                    APPROVE_AND_ACROSS_HOOK_BASE, acrossData, _getApproveAndAcrossCbbtcBaseToEthProof()
                )
            );
        } else {
            superGovernor.registerHook(ACROSS_SEND_FUNDS_HOOK_BASE);
            _setMerkleRoot(APPROVE_ERC20_HOOK, BASE_APPROVE_ERC20_ROOT);
            _setMerkleRoot(ACROSS_SEND_FUNDS_HOOK_BASE, BASE_ACROSS_ROOT);
            superBank.executeHooks(
                _buildExecutionDataWithProofs(
                    APPROVE_ERC20_HOOK,
                    ACROSS_SEND_FUNDS_HOOK_BASE,
                    _encodeApproveHookData(BASE_CBBTC, BASE_SPOKE_POOL, bridgeAmount, false),
                    acrossData,
                    _getBaseApproveCbbtcForSpokePoolProof(),
                    _getCbbtcBaseToEthAcrossProof()
                )
            );
        }
        logs = vm.getRecordedLogs();

        assertEq(IERC20(BASE_CBBTC).balanceOf(SUPER_BANK), 0, "All cbBTC should be consumed by the bridge");
        console2.log("Phase 1: Bridged %d cbBTC from Base to ETH", bridgeAmount);
    }

    /// @dev Phase 2: Relay a Base→ETH Across bridge via Pigeon AcrossV3Helper.
    function _relayAcrossBridgeToEth(Vm.Log[] memory logs, uint256 ethForkId) internal {
        AcrossV3Helper acrossHelper = new AcrossV3Helper();
        vm.makePersistent(address(acrossHelper));

        address relayer = makeAddr("ACROSS_RELAYER");
        vm.makePersistent(relayer);

        acrossHelper.help(
            BASE_SPOKE_POOL, ETH_SPOKE_POOL, relayer, block.timestamp, ethForkId, ETH_CHAIN_ID, BASE_CHAIN_ID, logs
        );

        console2.log("Phase 2: Pigeon relayed Across bridge to ETH fork");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              ETH MAINNET SWAP VIA ApproveAndSwapOdosV2Hook
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Swaps WETH→USDC on ETH mainnet SuperBank using the redeployed ApproveAndSwapOdosV2Hook.
    /// @dev inspect() returns abi.encodePacked(outputToken); merkle tree has 4 leaves (output tokens).
    function test_executeHooks_swapWETHtoUSDC_withApproveAndSwap() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
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

        bytes memory hookData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // Execute with production proof (selected by output token)
        uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                APPROVE_AND_SWAP_ODOS_V2_HOOK, hookData, _getEthApproveAndSwapOutputProof(ETH_USDC)
            )
        );

        uint256 usdcAfter = IERC20(ETH_USDC).balanceOf(SUPER_BANK);
        uint256 wethAfter = IERC20(ETH_WETH).balanceOf(SUPER_BANK);

        assertEq(wethAfter, 0, "All WETH should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    /// @notice Swaps WBTC→USDC on ETH mainnet SuperBank using the redeployed ApproveAndSwapOdosV2Hook.
    /// @dev Same as WETH test but with WBTC (8 decimals).
    function test_executeHooks_swapWBTCtoUSDC_withApproveAndSwap() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
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

        bytes memory hookData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // Execute with production proof
        uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                APPROVE_AND_SWAP_ODOS_V2_HOOK, hookData, _getEthApproveAndSwapOutputProof(ETH_USDC)
            )
        );

        uint256 usdcAfter = IERC20(ETH_USDC).balanceOf(SUPER_BANK);
        uint256 wbtcAfter = IERC20(ETH_WBTC).balanceOf(SUPER_BANK);

        assertEq(wbtcAfter, 0, "All WBTC should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d WBTC -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              BASE: APPROVE + SWAP (SEPARATE HOOKS) WETH/cbBTC→USDC
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Swaps WETH→USDC on Base using ApproveERC20Hook + the redeployed SwapOdosV2Hook.
    function test_executeHooks_swapWETHtoUSDC_onBase() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        uint256 swapAmount = 0.05 ether; // 0.05 WETH

        // 1. Fund SuperBank with WETH
        deal(BASE_WETH, SUPER_BANK, swapAmount);
        assertEq(IERC20(BASE_WETH).balanceOf(SUPER_BANK), swapAmount);

        // 2. Fetch live Odos quote
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: BASE_WETH, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: USDC, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        // 3. Encode hook data
        bytes memory approveData = _encodeApproveHookData(BASE_WETH, ODOS_ROUTER, swapAmount, false);
        bytes memory swapData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // 4. Set production merkle roots
        _setMerkleRoot(APPROVE_ERC20_HOOK, BASE_APPROVE_ERC20_ROOT);
        _setMerkleRoot(SWAP_ODOS_V2_HOOK, BASE_SWAP_ODOS_V2_ROOT);

        // 5. Execute with production proofs
        uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildExecutionDataWithProofs(
                APPROVE_ERC20_HOOK,
                SWAP_ODOS_V2_HOOK,
                approveData,
                swapData,
                _getBaseApproveWethForOdosRouterProof(),
                _getBaseSwapOdosOutputProof(USDC)
            )
        );

        uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);
        uint256 wethAfter = IERC20(BASE_WETH).balanceOf(SUPER_BANK);

        assertEq(wethAfter, 0, "All WETH should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    /// @notice Swaps cbBTC→USDC on Base using ApproveERC20Hook + the redeployed SwapOdosV2Hook.
    /// @dev Same as WETH test but with cbBTC (8 decimals).
    function test_executeHooks_swapCBBTCtoUSDC_onBase() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        uint256 swapAmount = 1e6; // 0.01 cbBTC (8 decimals)

        // 1. Fund SuperBank with cbBTC
        deal(BASE_CBBTC, SUPER_BANK, swapAmount);
        assertEq(IERC20(BASE_CBBTC).balanceOf(SUPER_BANK), swapAmount);

        // 2. Fetch live Odos quote
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: BASE_CBBTC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: USDC, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        // 3. Encode hook data
        bytes memory approveData = _encodeApproveHookData(BASE_CBBTC, ODOS_ROUTER, swapAmount, false);
        bytes memory swapData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        // 4. Set production merkle roots
        _setMerkleRoot(APPROVE_ERC20_HOOK, BASE_APPROVE_ERC20_ROOT);
        _setMerkleRoot(SWAP_ODOS_V2_HOOK, BASE_SWAP_ODOS_V2_ROOT);

        // 5. Execute with production proofs
        uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildExecutionDataWithProofs(
                APPROVE_ERC20_HOOK,
                SWAP_ODOS_V2_HOOK,
                approveData,
                swapData,
                _getBaseApproveCbbtcForOdosRouterProof(),
                _getBaseSwapOdosOutputProof(USDC)
            )
        );

        uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);
        uint256 cbbtcAfter = IERC20(BASE_CBBTC).balanceOf(SUPER_BANK);

        assertEq(cbbtcAfter, 0, "All cbBTC should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d cbBTC -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //          BASE: ApproveAndSwapOdosV2Hook (SINGLE COMBINED HOOK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Swaps USDC→UP on Base using the redeployed ApproveAndSwapOdosV2Hook.
    function test_executeHooks_swapUSDCtoUP_withBaseApproveAndSwap() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        _setupBaseForkForApproveAndSwap();

        uint256 swapAmount = 100e6; // 100 USDC
        deal(USDC, SUPER_BANK, swapAmount);
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), swapAmount);

        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: USDC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: UP, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        bytes memory hookData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        uint256 upBefore = IERC20(UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                BASE_APPROVE_AND_SWAP_ODOS_V2_HOOK, hookData, _getBaseApproveAndSwapOutputProof(UP)
            )
        );

        uint256 upAfter = IERC20(UP).balanceOf(SUPER_BANK);
        uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);

        assertEq(usdcAfter, 0, "All USDC should be consumed by the swap");
        assertGt(upAfter - upBefore, 0, "SuperBank should have received UP tokens");

        console2.log("Swap result: %d USDC -> %d UP", swapAmount, upAfter - upBefore);
    }

    /// @notice Swaps WETH→USDC on Base using the redeployed ApproveAndSwapOdosV2Hook.
    function test_executeHooks_swapWETHtoUSDC_withBaseApproveAndSwap() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        _setupBaseForkForApproveAndSwap();

        uint256 swapAmount = 0.05 ether;
        deal(BASE_WETH, SUPER_BANK, swapAmount);
        assertEq(IERC20(BASE_WETH).balanceOf(SUPER_BANK), swapAmount);

        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: BASE_WETH, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: USDC, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        bytes memory hookData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                BASE_APPROVE_AND_SWAP_ODOS_V2_HOOK, hookData, _getBaseApproveAndSwapOutputProof(USDC)
            )
        );

        uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);
        uint256 wethAfter = IERC20(BASE_WETH).balanceOf(SUPER_BANK);

        assertEq(wethAfter, 0, "All WETH should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    /// @notice Swaps cbBTC→USDC on Base using the redeployed ApproveAndSwapOdosV2Hook.
    function test_executeHooks_swapCBBTCtoUSDC_withBaseApproveAndSwap() public {
        // Skip if Odos API is unavailable (rate-limited, down, etc.)
        _skipIfOdosUnavailable();
        _setupBaseForkForApproveAndSwap();

        uint256 swapAmount = 1e6; // 0.01 cbBTC (8 decimals)
        deal(BASE_CBBTC, SUPER_BANK, swapAmount);
        assertEq(IERC20(BASE_CBBTC).balanceOf(SUPER_BANK), swapAmount);

        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: BASE_CBBTC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: USDC, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
        string memory assembledHex = surlCallAssemble(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos executor:", decoded.executor);

        bytes memory hookData = _encodeSwapOdosHookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            decoded.referralCode
        );

        uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                BASE_APPROVE_AND_SWAP_ODOS_V2_HOOK, hookData, _getBaseApproveAndSwapOutputProof(USDC)
            )
        );

        uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);
        uint256 cbbtcAfter = IERC20(BASE_CBBTC).balanceOf(SUPER_BANK);

        assertEq(cbbtcAfter, 0, "All cbBTC should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("Swap result: %d cbBTC -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     FORK SETUP HELPERS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Sets up ETH mainnet fork for ApproveAndSwapOdosV2Hook tests.
    function _setupEthForkForApproveAndSwap() internal {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(APPROVE_AND_SWAP_ODOS_V2_HOOK);

        // ApproveAndSwapOdosV2Hook: production merkle root (4 leaves, output tokens)
        _setMerkleRoot(APPROVE_AND_SWAP_ODOS_V2_HOOK, ETH_APPROVE_AND_SWAP_ODOS_V2_ROOT);
    }

    /// @dev Sets up Base fork for ApproveAndSwapOdosV2Hook tests.
    function _setupBaseForkForApproveAndSwap() internal {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(BASE_APPROVE_AND_SWAP_ODOS_V2_HOOK);

        // ApproveAndSwapOdosV2Hook on Base: production merkle root (4 leaves, output tokens)
        _setMerkleRoot(BASE_APPROVE_AND_SWAP_ODOS_V2_HOOK, BASE_APPROVE_AND_SWAP_ODOS_V2_ROOT);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Returns the production merkle proof for USDC + Odos Router leaf in the
    ///      ApproveERC20Hook tree on Base (unchanged deployment).
    ///      Source: hook_0x8b789980dc6cc7d88e30c442d704646ff7f6d306.json (chain 8453)
    ///      Args: token=USDC (0x833589fC...), spender=Odos Router V2 (0x19cEeAd7...)
    function _getBaseApproveUsdcForOdosRouterProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0x8ff532e6fb7b80138c312fa9f03951de00ad181c6784f52885c27c153c62b39e;
        proof[1] = 0x00a4777ac75cfa9249a5ae50cbaea4d1b30c94ad4983a2fec46c50db24ab1f9a;
        proof[2] = 0xa7232f69950135a08b185560765444fc0fdd0123b3ada17fc052dbdff49fce87;
        proof[3] = 0xbabbe37eeeb38c04dccf0232dcc4de246e856f1c8a65f35ec93344f807a538d0;
        proof[4] = 0x7a90d49f881c218fcc0ce26fd662efb5af44ee0711745cd8058e058b69b771f1;
        proof[5] = 0x1898e448f5a0a4b665aa52f6cac5223345a49c5d2a2f2d91911a1b0848fdd040;
        proof[6] = 0xfc4c551dfd1d006b73230db4e7f5fdd90a74a48a13d13ca624a92df0da6f24b2;
    }

    /// @dev Returns the production merkle proof for approve WETH for OdosRouter
    ///      in the ApproveERC20Hook tree on Base (unchanged deployment).
    function _getBaseApproveWethForOdosRouterProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0x81d1d153c3f9eec33fc47326f41becec1fc7c37b7628fb3e33778d4d060540cf;
        proof[1] = 0x9e83ac6cab33f8706aa3268c7b67e5681b8e4bc052e77ef498b754cbc2804852;
        proof[2] = 0xf97c189ad66cf6832bf630b06808be198163a4c85764860499abf4ed03225033;
        proof[3] = 0xbabbe37eeeb38c04dccf0232dcc4de246e856f1c8a65f35ec93344f807a538d0;
        proof[4] = 0x7a90d49f881c218fcc0ce26fd662efb5af44ee0711745cd8058e058b69b771f1;
        proof[5] = 0x1898e448f5a0a4b665aa52f6cac5223345a49c5d2a2f2d91911a1b0848fdd040;
        proof[6] = 0xfc4c551dfd1d006b73230db4e7f5fdd90a74a48a13d13ca624a92df0da6f24b2;
    }

    /// @dev Returns the production merkle proof for approve cbBTC for OdosRouter
    ///      in the ApproveERC20Hook tree on Base (unchanged deployment).
    function _getBaseApproveCbbtcForOdosRouterProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0xce5a4c188b0ab4bc573ef075f435b49419a6f69e94fc96e284005f7171c9afb9;
        proof[1] = 0x6c3cd2c7e3613e2057f71f4b220e79203b95777f62305cc7dd4532d04ffec984;
        proof[2] = 0x532e581f446b0e3ccba32206831a826e3c9a3bc0d2bce3e0e8c7caf4456d1185;
        proof[3] = 0xa51210c759606a4f457fd2e2ea1286573241dfff4c9dbf6d36c5e4abe5878e5f;
        proof[4] = 0xc5518ac470ce01beae4f3e24aa1af06ee57be6eda991c4695109d1b308dd1391;
        proof[5] = 0x3b15e44430cbe83a077fccec1c7f5bc3d9213e0cb85123bc8b09a848c621ce0e;
        proof[6] = 0xfc4c551dfd1d006b73230db4e7f5fdd90a74a48a13d13ca624a92df0da6f24b2;
    }

    /// @dev Returns the production merkle proof for the given output token in the redeployed
    ///      SwapOdosV2Hook tree on Base (4 leaves, output-token whitelist).
    ///      Source: hook_0xe03fdd61d40045079e7af3a381f80dd74739546e.json (chain 8453)
    function _getBaseSwapOdosOutputProof(address outputToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (outputToken == UP_OFT) {
            // UP (OFT), idx 0
            proof[0] = 0x87638deac2013fcb40fc791863d46b41369f2df50d0bb19ac01b911e3e6a15bf;
            proof[1] = 0xd7790aa324dc407cc09d02de2a9378fff91f39e08e2220d3d9863631cb683ffd;
        } else if (outputToken == ETH_UP) {
            // UP (ETH), idx 1
            proof[0] = 0x4c441f9d1374c8e35e7842d2ba4b07b221e95997e6dce90a13e8bd0d9e316dc6;
            proof[1] = 0xd7790aa324dc407cc09d02de2a9378fff91f39e08e2220d3d9863631cb683ffd;
        } else if (outputToken == USDC) {
            // USDC (Base), idx 2
            proof[0] = 0xfd4b3989b03b700a5c548577bc43419d2783c73ef8da2cb91d88a9bf07a5e690;
            proof[1] = 0xc1ea72e9c93cf805a562c45b8ecd0e95854768734293a639fe40f9101da549da;
        } else if (outputToken == UP) {
            // UP (Base), idx 3
            proof[0] = 0xb7ccfe29b04186a642aea43a0114c600af7cc90d98b9ab55b22f55bb93a9330d;
            proof[1] = 0xc1ea72e9c93cf805a562c45b8ecd0e95854768734293a639fe40f9101da549da;
        } else {
            revert("Unknown outputToken - not in Base SwapOdosV2Hook tree");
        }
    }

    /// @dev Returns the production merkle proof for the given output token in the redeployed
    ///      ApproveAndSwapOdosV2Hook tree on ETH (4 leaves, output-token whitelist).
    ///      Source: hook_0x3b2dbedf63ab4d5f7652d8845c0eda1fa42263cd.json (chain 1)
    function _getEthApproveAndSwapOutputProof(address outputToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (outputToken == ETH_UP) {
            // UP (ETH), idx 0
            proof[0] = 0x4664d93dc6ed355c23ce0952001c5d01a0ab90b23574b9a7e2b9d4647bf6d9f7;
            proof[1] = 0x2fc04979315afe1162ed4ed958af288f7d5e1219dd94ce54ff49a6fa2b7960dd;
        } else if (outputToken == ETH_USDC) {
            // USDC (ETH), idx 1
            proof[0] = 0x2e3bbaf07089fd5490dab4e26d268df188064125fe54318f4bb25a73dfcca5af;
            proof[1] = 0x2fc04979315afe1162ed4ed958af288f7d5e1219dd94ce54ff49a6fa2b7960dd;
        } else if (outputToken == UP) {
            // UP (Base), idx 2
            proof[0] = 0xca06ee63c78849bfe5575c8fc37a6ce4efff5516523e20eb40fefa30e1aa3793;
            proof[1] = 0xdff9f298c297e630ddc4cae2acffef560bcf35d4d2d9cd9bad46e39b4b1b534d;
        } else if (outputToken == UP_OFT) {
            // UP (OFT), idx 3
            proof[0] = 0x724d225a7f83c7ee2004a71e03fce0c96c5f70f7fe60a41415c393ea8033dbc1;
            proof[1] = 0xdff9f298c297e630ddc4cae2acffef560bcf35d4d2d9cd9bad46e39b4b1b534d;
        } else {
            revert("Unknown outputToken - not in ETH ApproveAndSwapOdosV2Hook tree");
        }
    }

    /// @dev Returns the production merkle proof for the given output token in the redeployed
    ///      ApproveAndSwapOdosV2Hook tree on Base (4 leaves, output-token whitelist).
    ///      Source: hook_0x2334321db75f2889b44d10826b511abe57c62adf.json (chain 8453)
    function _getBaseApproveAndSwapOutputProof(address outputToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (outputToken == USDC) {
            // USDC (Base), idx 0
            proof[0] = 0x56c9769481e03ac697fdb3f2d62f1e07693f3b2dae903e4a49086ef6d50da8d1;
            proof[1] = 0xccb79a41bf0251815ab2de69a4d08638764aff6d59d3a9b5077b645c90a4e953;
        } else if (outputToken == UP) {
            // UP (Base), idx 1
            proof[0] = 0x3afc5beb0ed9e1f402e85a77f1e6f7f6217fcd8b3bfbd2f02f9582490fb68ce1;
            proof[1] = 0xccb79a41bf0251815ab2de69a4d08638764aff6d59d3a9b5077b645c90a4e953;
        } else if (outputToken == UP_OFT) {
            // UP (OFT), idx 2
            proof[0] = 0xd33d0b3f49ce39b54465e461ab6d4f09556f8b263f25103d36b257a4ffc02a46;
            proof[1] = 0xaa9ec82534c0d2a9cb026c78a94247e0b9a39c3ad3af9a8a37200a7047192254;
        } else if (outputToken == ETH_UP) {
            // UP (ETH), idx 3
            proof[0] = 0xd09749b761c8df7f5494ecced127b5bcf9b9d7d3f1472e663101d4e308c55f20;
            proof[1] = 0xaa9ec82534c0d2a9cb026c78a94247e0b9a39c3ad3af9a8a37200a7047192254;
        } else {
            revert("Unknown outputToken - not in Base ApproveAndSwapOdosV2Hook tree");
        }
    }

    /// @dev Returns the production merkle proof for approve USDC for SpokePool ETH
    ///      in the ApproveERC20Hook tree on ETH (unchanged deployment).
    ///      Source: hook_0x8b789980dc6cc7d88e30c442d704646ff7f6d306.json (chain 1)
    ///      Args: token=ETH USDC, spender=ETH SpokePool (0x5c7BCd6E...), leaf index 38
    function _getApproveUsdcForSpokePoolProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](8);
        proof[0] = 0x473a3d510eea0ef3fb57fa85fde3a5c7a215379e4631ac6921d433b089f12a14;
        proof[1] = 0xe6cfd83bd41aab4a23666b7260048a440ec9226ae717c5c4d3ea55f447af3e73;
        proof[2] = 0x055d5ce89a1ca1ed59f913c87c68aa0b6e9e14b85f0eb984d02646a8f450b217;
        proof[3] = 0x80e80472d7194a05b29bc849a6c734d74e7c9f15fb188ee0dde1b69e60cab586;
        proof[4] = 0x8bd0033f198c5635e5534c0c522a2472351260f1122823361cd2741abe4bb4c7;
        proof[5] = 0x87fefce5b5fd95a0e092819255236d6db2a68cc3d783b1886f598760fefe5dac;
        proof[6] = 0xaf4a53aae18cfcd590707a7c8fe5d1e6017ee12fbafd3b2c2d5b0dc07addcb6d;
        proof[7] = 0x6d609ffe0241e1a51d043b4ff0c8e4162b09e2f1dcb27b1ac82dbe9fb40da2b8;
    }

    /// @dev Returns the production merkle proof for approve WETH for SpokePool ETH
    ///      in the ApproveERC20Hook tree on ETH (unchanged deployment).
    ///      Source: hook_0x8b789980dc6cc7d88e30c442d704646ff7f6d306.json (chain 1)
    ///      Args: token=ETH WETH, spender=ETH SpokePool (0x5c7BCd6E...), leaf index 85
    function _getApproveWethForSpokePoolProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](8);
        proof[0] = 0x892d6f1e08cb907df681b59282d99b356534f330634029d4443ed2c6f7a9d9e2;
        proof[1] = 0x2bbda0aed315d4585fff461101b5bef754b251d5a7e15340ac56ad49ed75868f;
        proof[2] = 0x9336bd8125b8575fdf4c40e661ba003c88ae1fe49087bd3cc5c180dced418428;
        proof[3] = 0xb82a530baf9df46f4df7ca1af3d0e847a766992c9864340d0516afdad378b0c0;
        proof[4] = 0xfe4798ce48d1a009d6e2ee7c6a94de0ea947e1654ac11ba7dafe86d794c2d24b;
        proof[5] = 0xb8dfb84977fcb85af8076a4fc3ea5880bf73e8821f550346eb4d5de4d52f21ee;
        proof[6] = 0xbbad3daec60b4c56c24c820beb95a1d4ff14699ea0b9727d6aefc857cfcff669;
        proof[7] = 0x6d609ffe0241e1a51d043b4ff0c8e4162b09e2f1dcb27b1ac82dbe9fb40da2b8;
    }

    /// @dev Returns the production merkle proof for approve WBTC for SpokePool ETH
    ///      in the ApproveERC20Hook tree on ETH (unchanged deployment).
    ///      Source: hook_0x8b789980dc6cc7d88e30c442d704646ff7f6d306.json (chain 1)
    ///      Args: token=ETH WBTC, spender=ETH SpokePool (0x5c7BCd6E...), leaf index 130
    function _getApproveWbtcForSpokePoolProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0xce41750c3537aba27a76bc7c2a6e8465accf2d4591a9d26d1892843a9844d8a2;
        proof[1] = 0x9aa5aa7cdb67831f40511930c9f865926a89c588b8cd85552b50960acc9cc3be;
        proof[2] = 0x10876d9bfef00d153223e7f3dcb42fb8ed220580b13fafb19f2833fa3fbb7c6c;
        proof[3] = 0xad6fec99d23a2b2b3f553e5af6914e93de082c2a968f5aaf5128188099e8be08;
        proof[4] = 0x6a134e9c8a29002e94b0eee961ff433505a3f8875ab1b236640c15c61966a148;
        proof[5] = 0x62d7ca190902561196a3635ef43dde632f8177c293a000000b94217ee4df2f9c;
        proof[6] = 0x3b9eca93f3983a8b10c17961c86aabf9b4610676db961672236f5345c768f7bd;
    }

    /// @dev Returns the production merkle proof for USDC ETH→USDC Base leaf (index 396) in the
    ///      redeployed AcrossSendFundsAndExecuteOnDstHook tree on ETH.
    ///      Source: hook_0xea1b9ab11ec33f40fb36548cad1032da9293c5f3.json (chain 1, 1188 leaves)
    ///      Args: recipient=SuperBank, inputToken=ETH USDC, outputToken=Base USDC, exclusiveRelayer=0x0
    function _getUsdcEthToBaseAcrossProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](11);
        proof[0] = 0x5634e9eddaf94acbc40d2ff4585ce2644f30c7094a45cffaa6f2df259feda395;
        proof[1] = 0x96db45311b4548aab298b8729dc0d0d686af7529d83ed943b0a718964e165e9c;
        proof[2] = 0xf3216bc18b9b788780a61633be6356728abd928622fb83f47a701cf52bbaf1a7;
        proof[3] = 0x91fe0e3e4bad7440c645b46231f61b68225aedc25db3e35e257f4de4cf8a65c8;
        proof[4] = 0x370a0cb02ebe5395b05f19ef9894b370241ed68d04b266034e5c90b942e0c17f;
        proof[5] = 0x6fa51f08148cfce9ce09c68455511549bb89fc6be47dc1e81cfe643d381e3718;
        proof[6] = 0x6584294408ffd285468564cc537ef34121b88bb45b9ecac8384f3d7d9660ac4f;
        proof[7] = 0x11658912d3d8e66f794f8b2f9d0db1c211a4260fe0afde6f284299ded15a632f;
        proof[8] = 0xf550f1e3cc87b52bf4dea23ca4d44847f2af7725a658728fcc31e7e2d749c06e;
        proof[9] = 0xd22be117736d5adcb27eb6772b2d4251e32b834d726b7aedd0835c7c74b33acc;
        proof[10] = 0x12fb9d0183c2269eda06c4dbff1da48c8bac146fdda5d162810e3d784c72a8f7;
    }

    /// @dev Returns the production merkle proof for WETH ETH→WETH Base leaf (index 1031) in the
    ///      redeployed AcrossSendFundsAndExecuteOnDstHook tree on ETH.
    ///      Source: hook_0xea1b9ab11ec33f40fb36548cad1032da9293c5f3.json (chain 1, 1188 leaves)
    ///      Args: recipient=SuperBank, inputToken=ETH WETH, outputToken=Base WETH, exclusiveRelayer=0x0
    function _getWethEthToBaseAcrossProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](9);
        proof[0] = 0xddb609cf07956eb32ae82f44ecb858932b047ed2998d252a24efdd4da25b095b;
        proof[1] = 0xab3c3832d255930095d962719e0fbdbaed01f53b351cb510136bf1ba3e62858b;
        proof[2] = 0x382c1e61a4543a15afeeaa6f5b086ba8a20ecd3d88b97a46977bb8da115fd8a5;
        proof[3] = 0x404bc00813421463c30db1a8d58252fe2512783be4fea92e3273fb60f51c3fdd;
        proof[4] = 0xc54ccf8565701872356f18c3167c7aa267a13a1dd5f25cca96e0f1c5b2d1a93c;
        proof[5] = 0xd60c5cde7e1827ceeb2dcd3749fb5c2d5a93c135530323614987632f11605bff;
        proof[6] = 0x8515776a0c69599a28731e24ee246332e892ccc40aeea10385d1b25c6610350e;
        proof[7] = 0x4fd7658aec4db637bc5d33ea4ab45afaed4c60e2803b49ea28a6c4644ed66024;
        proof[8] = 0xdf6e19c44e12d5f207bc5fa76c2ec4c4b27ae773d2d93ab30ef9a7590bd0b299;
    }

    /// @dev Returns the production merkle proof for WBTC ETH→cbBTC Base leaf (index 636) in the
    ///      redeployed AcrossSendFundsAndExecuteOnDstHook tree on ETH.
    ///      Source: hook_0xea1b9ab11ec33f40fb36548cad1032da9293c5f3.json (chain 1, 1188 leaves)
    ///      Args: recipient=SuperBank, inputToken=ETH WBTC, outputToken=Base cbBTC, exclusiveRelayer=0x0
    function _getWbtcEthToBaseAcrossProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](11);
        proof[0] = 0x88bc2a731d3b08b9896298c18c9ca230789910222e1eb5382b3ca6a312b02c3d;
        proof[1] = 0xd3b5b6e94b3aab34e2bb7bd5f96b6e76393f2f313d188329ba32f8c4ffb976b8;
        proof[2] = 0xe770341a8e460addec0262166f3a3d00a8db02f17a368d49a1dbd67b8013a5b4;
        proof[3] = 0x2a7971e1c6ded41be71ccb204ce942d1d6b6030612eafa5775a1ab42c4856ab6;
        proof[4] = 0x4fd23006bed7082d06030779a54f728741fa12df58c13d353d24ea8d927a1b70;
        proof[5] = 0x40d478f9fc41b90be950a2ae6f71e601f228f0bc697ad4508b777cadf483fa7c;
        proof[6] = 0x1f76144b6ed4332c02a823275c8303c3d8ada704aa53a560974d28624e9e6e93;
        proof[7] = 0x33d7fe6d4568fc118699a5fd1a87dee5f8add29dc6a3ba75abce7cf581667672;
        proof[8] = 0xd5550b98663b6cf7c80cdc39b5ae1514bd22d58636511d10c6e92fcd43b3e2b5;
        proof[9] = 0x36e61e3f02c0a0ba2f4139ac1255a6b7422d36514a268eb766cb0641655b0176;
        proof[10] = 0x12fb9d0183c2269eda06c4dbff1da48c8bac146fdda5d162810e3d784c72a8f7;
    }

    /// @dev Returns the production merkle proof for USDC ETH→USDC Base leaf (index 558) in the
    ///      redeployed ApproveAndAcrossSendFundsAndExecuteOnDstHook tree on ETH.
    ///      Source: hook_0xdef02397edbf7d0da1e10fe297362c3adf358fa1.json (chain 1, 1188 leaves)
    ///      Args: recipient=SuperBank, inputToken=ETH USDC, outputToken=Base USDC, exclusiveRelayer=0x0
    function _getApproveAndAcrossUsdcEthToBaseProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](11);
        proof[0] = 0x76f856712cb217e5c676c40215f2beeba725a593e9de0899036ca77af60f41e9;
        proof[1] = 0xd2a58ae2d11a3fb20e99d0d6d4a4787424ff7af2f134aead1934a59926b5a993;
        proof[2] = 0x224b1852a926bca9a8bd3b84033fa80d57a005226fc187a58a8a9c6637437ca4;
        proof[3] = 0x2d628554e8507ab9dec1b8d0221b7f44c85e2c01a4786e76c6e56176526f5878;
        proof[4] = 0x47a93df5a008323d6c9978e87c961961b7b7c182366f9828da62c8d6c7be1c1b;
        proof[5] = 0x8b843d79e4f0ec9c3fb867b3c1839e5debc6f4967f21be3f5955e7fe5a39e1d2;
        proof[6] = 0xe8c53f3816dc537aa8d8352717b300382168678a3c49eda18a20c9fc066fbf02;
        proof[7] = 0x1719419790e437e2ba3d340dc38490a2c2f03cc014ce40d765dee52934cb1956;
        proof[8] = 0xcb2103053581aa566370874f046fe0f7d9b7da10f0ed8d5bbe30f46e2460fa81;
        proof[9] = 0x67374508497e575540b6c2177d3c0fb699518ef52685be3db18a332e4b6fc96b;
        proof[10] = 0xc0319a24d92f70caae93f049e380ce7cba78b2e29ecda0ed32216a21da766506;
    }

    /// @dev Returns the production merkle proof for WETH ETH→WETH Base leaf (index 9) in the
    ///      redeployed ApproveAndAcrossSendFundsAndExecuteOnDstHook tree on ETH.
    ///      Source: hook_0xdef02397edbf7d0da1e10fe297362c3adf358fa1.json (chain 1, 1188 leaves)
    ///      Args: recipient=SuperBank, inputToken=ETH WETH, outputToken=Base WETH, exclusiveRelayer=0x0
    function _getApproveAndAcrossWethEthToBaseProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](11);
        proof[0] = 0x025ff4fb46fb0bea2bf90bb2b7a1df50bfad99e53b12a554a55b597c702ac184;
        proof[1] = 0x8593ad6c4d691486f6c226d56301c05123c46dd3658b937cdb9538f3f3716bcc;
        proof[2] = 0xeb6f6d39d8034a746721012a3de84b0202dd540a306ddab89fa0ac50dec401fb;
        proof[3] = 0x5b66c200cccd777fe9dc9a9fc322f0b90a99fe171543d9ed1b9b5123e0b05fa4;
        proof[4] = 0xf1bae113ec19cb51825a4efaffb5c0ad3d9b2385b92b3100f554d722ebd585c4;
        proof[5] = 0x5aaf38736e1384bd2d9f2f9c81889cf7e7eacdfea05ac6036813eedc011a728b;
        proof[6] = 0x235e3749cf40e73b0ff782da2da2f8c53fe942027c20e95cbaebeafff9618951;
        proof[7] = 0x0f5b8ac8b0fed86b5b3e1ea9737bd5fe8b3618a7f8a897162882dfdced2c03bf;
        proof[8] = 0xd859174e704a0bd3f7db2bc77660196b52d65617b85ad5f48412cf08f873fb3c;
        proof[9] = 0x052de1fe8006c71919fd36611510c50e741751d49c05ac07a68c08ad777886d9;
        proof[10] = 0xc0319a24d92f70caae93f049e380ce7cba78b2e29ecda0ed32216a21da766506;
    }

    /// @dev Returns the production merkle proof for WBTC ETH→cbBTC Base leaf (index 909) in the
    ///      redeployed ApproveAndAcrossSendFundsAndExecuteOnDstHook tree on ETH.
    ///      Source: hook_0xdef02397edbf7d0da1e10fe297362c3adf358fa1.json (chain 1, 1188 leaves)
    ///      Args: recipient=SuperBank, inputToken=ETH WBTC, outputToken=Base cbBTC, exclusiveRelayer=0x0
    function _getApproveAndAcrossWbtcEthToBaseProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](11);
        proof[0] = 0xc3fbf00059d8e27410b450995ab5a92016751422fb837cfad6711cadcd5270c2;
        proof[1] = 0xda336e08290b10e2b8a8985864441fbadea4056ad36ab720db2429b3a0b8f933;
        proof[2] = 0xead35dfd4d008df0de89867245e18e14142aa4569f104c4a70df4c5a9649b380;
        proof[3] = 0x1851b4ef820d5bc033e3ae77b1e1d784ef93236573a563b5640145d327b5699d;
        proof[4] = 0x7fc0b8222d019c76b67a265ce6912979ffa3339eadabd3f6dc862faba2a70f6a;
        proof[5] = 0xaae822b9be988b5e0a7c83bd63f93c1748c809eae76ae8d6d07adcf1db85a9bb;
        proof[6] = 0x5b6afd4295f26774bac850e0642a814364faceb03829d448ddc5eb103be26f6a;
        proof[7] = 0xbcafeb0b511e1feac0f9c31fe7a363fb4d8edf3daeba381fb4842fc42b452663;
        proof[8] = 0xef57d536b4749d3ee8107082b2b9ba0ce4e92615dbde4af3386fa0b76c0e95df;
        proof[9] = 0x67374508497e575540b6c2177d3c0fb699518ef52685be3db18a332e4b6fc96b;
        proof[10] = 0xc0319a24d92f70caae93f049e380ce7cba78b2e29ecda0ed32216a21da766506;
    }

    /// @dev Returns the production merkle proof for approve cbBTC for SpokePool Base
    ///      in the ApproveERC20Hook tree on Base (unchanged deployment).
    ///      Source: hook_0x8b789980dc6cc7d88e30c442d704646ff7f6d306.json (chain 8453)
    ///      Args: token=Base cbBTC, spender=Base SpokePool (0x09aea4b2...), leaf index 21
    function _getBaseApproveCbbtcForSpokePoolProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0x5311008a93a84fe7d8dc438f1cff8a90e021351b598aaac5e7ef4e0fb3f63b10;
        proof[1] = 0xeb2ed70b31f774ddddc042c4661836343f31304678386bc7cf5812e2b2ac3e08;
        proof[2] = 0x961d3762c18203d498ee79263eebae52b32006894607b3fe9109968f7e1d2693;
        proof[3] = 0xd9cd9b2767d15475d60f490a6ca8692e3bc6de1fc72a31742248f226b5a4fd6a;
        proof[4] = 0x7a90d49f881c218fcc0ce26fd662efb5af44ee0711745cd8058e058b69b771f1;
        proof[5] = 0x1898e448f5a0a4b665aa52f6cac5223345a49c5d2a2f2d91911a1b0848fdd040;
        proof[6] = 0xfc4c551dfd1d006b73230db4e7f5fdd90a74a48a13d13ca624a92df0da6f24b2;
    }

    /// @dev Returns the production merkle proof for cbBTC Base→cbBTC ETH leaf (index 137) in the
    ///      redeployed AcrossSendFundsAndExecuteOnDstHook tree on Base.
    ///      Source: hook_0xf583a7826da0917a8d45ec4457d45d26d251b152.json (chain 8453, 169 leaves)
    ///      Args: recipient=SuperBank, inputToken=cbBTC, outputToken=cbBTC, exclusiveRelayer=0x0
    function _getCbbtcBaseToEthAcrossProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](7);
        proof[0] = 0xcb0dd06209adeeff874916e0ecfc7a6c60530935409238233dc8374a82e24458;
        proof[1] = 0x059b20b9de05404c0d601d23eb51a35f2b94831f5f54069804be4c0078b2bed1;
        proof[2] = 0x236385da9d614a190db7108dda433bf9ee7d2975446232248557320cdd2f64a0;
        proof[3] = 0xcc59de364bbfd3109c38e419657b96b62e4441df72cbb5e6ad65efec22921660;
        proof[4] = 0xa22c213837604f3370b9dd8306d1dcde9c36a62b977307c84a05850a65953813;
        proof[5] = 0x779fbd049d32d66216fd7d01b9b439ba0de2935eb0b9f7cdf1b18e891ba12502;
        proof[6] = 0x01b0a4707a118b90e38025a566ba4db3978515a8a58488e21cb910e4f4cc4ea6;
    }

    /// @dev Returns the production merkle proof for cbBTC Base→cbBTC ETH leaf (index 101) in the
    ///      redeployed ApproveAndAcrossSendFundsAndExecuteOnDstHook tree on Base.
    ///      Source: hook_0x3170e72b2f8ea2a7028374b051c5d443f5bca91a.json (chain 8453, 169 leaves)
    ///      Args: recipient=SuperBank, inputToken=cbBTC, outputToken=cbBTC, exclusiveRelayer=0x0
    function _getApproveAndAcrossCbbtcBaseToEthProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](8);
        proof[0] = 0xa08afcd655626de428dec47ad81f6dbe5472cb3a21ad8370002644e0d76263e5;
        proof[1] = 0x625b20e39ff2dacb80290d3ae44412d4d81c14d085508da829193c1b18529064;
        proof[2] = 0xb631a9c5a0d044c66eecd0370b7194b6f91581b0b9ab99146e548c21dea1959e;
        proof[3] = 0xa2aaa437f52b38ad52a600efa2c742dac31999d143cc59f0437981a57b26a0eb;
        proof[4] = 0x450ffc60ca6ce9a50f41c4e553dc29bbf74ff9f526a3899f6c293d7496741503;
        proof[5] = 0xee56c1d2049c7b49d7cef6bac961e78f1d522352218eb8180236279a5032d1e5;
        proof[6] = 0x5648ee53fed3f31ae3ab63404ad598d478ff83751cbb7ed034de82351785b278;
        proof[7] = 0x6224c8ff67df8a70a5e31e1e594668e96c17285ca340cf22b4701c144fc043c4;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     MERKLE ROOT MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Sets a pre-computed merkle root directly (no leaf computation, just propose+timelock+execute).
    function _setMerkleRoot(address hook, bytes32 root) internal {
        uint256 savedTimestamp = block.timestamp;
        superGovernor.proposeSuperBankHookMerkleRoot(hook, root);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook);
        vm.warp(savedTimestamp);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook), root, "Merkle root mismatch");
    }

    /// @dev Creates a single-leaf merkle tree (root == leaf) and registers it through the governance timelock.
    ///      For SuperBank, the merkle tree is simpler than SuperVault:
    ///        leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
    ///      where hookArgs = hook.inspect(hookData).
    ///      Single-leaf tree: root == leaf, empty proof.
    function _registerMerkleRoot(address hook, bytes memory hookData) internal {
        bytes memory hookArgs = ISuperHookInspector(hook).inspect(hookData);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));

        uint256 savedTimestamp = block.timestamp;
        superGovernor.proposeSuperBankHookMerkleRoot(hook, leaf);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook);
        vm.warp(savedTimestamp);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook), leaf, "Merkle root mismatch");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     ODOS API HELPERS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Calls Odos quote v2 with a sourceBlacklist to avoid broken pools on the fork.
    ///      Builds the base JSON via buildQuoteV2RequestBody, strips trailing "}", appends the blacklist.
    function _surlCallQuoteV2WithBlacklist(
        QuoteInputToken[] memory _inputTokens,
        QuoteOutputToken[] memory _outputTokens,
        address _account,
        uint256 _chainId,
        bool _compact,
        string memory _blacklist
    )
        internal
        returns (string memory)
    {
        string memory body = buildQuoteV2RequestBody(_inputTokens, _outputTokens, _account, _chainId, _compact);
        // Remove trailing "}" and append sourceBlacklist
        bytes memory bodyBytes = bytes(body);
        assembly {
            mstore(bodyBytes, sub(mload(bodyBytes), 1))
        }
        body = string(abi.encodePacked(bodyBytes, ',"sourceBlacklist":', _blacklist, "}"));

        string[] memory headers = new string[](1);
        headers[0] = "Content-Type: application/json";

        (uint256 status, bytes memory data) = API_QUOTE_URL.post(headers, body);
        if (status != 200) {
            vm.skip(true);
        }
        string memory json = string(data);

        strings.slice memory jsonSlice = json.toSlice();
        strings.slice memory key = '"pathId":"'.toSlice();
        strings.slice memory afterKey = jsonSlice.find(key).beyond(key);
        strings.slice memory pathId = afterKey.split('"'.toSlice());

        return pathId.toString();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     HOOK DATA ENCODING
    // ═══════════════════════════════════════════════════════════════════

    /// @dev ApproveERC20Hook data: [token][spender][amount][usePrevHookAmount] (unchanged deployment)
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

    /// @dev Redeployed Across hook data layout (see v2-core AcrossSendFundsAndExecuteOnDstHook.sol):
    ///      [52-byte zero header][value(32)][recipient(20)][inputToken(20)][outputToken(20)]
    ///      [inputAmount(32)][outputAmount(32)][destinationChainId(32)][exclusiveRelayer(20)]
    ///      [fillDeadlineOffset(4)][exclusivityPeriod(4)][usePrevHookAmount(1)][destinationMessage(variable)]
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
            bytes32(0),
            bytes20(address(0)), // 52-byte strategy header
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

    /// @dev Redeployed SwapOdosV2Hook data layout (see v2-core SwapOdosV2Hook.sol):
    ///      [52-byte zero header][inputToken(20)][outputToken(20)][inputAmount(32)]
    ///      [outputQuote(32)][outputMin(32)][usePrevHookAmount(1)][payloadLength(32)][payload]
    ///      Payload: abi.encode(inputReceiver, pathDefinition, executor, uint32 referralCode)
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
        bytes memory payload = abi.encode(inputReceiver, pathDefinition, executor, referralCode);
        return bytes.concat(
            bytes32(0),
            bytes20(address(0)), // 52-byte strategy header
            bytes20(inputToken),
            bytes20(outputToken),
            bytes32(inputAmount),
            bytes32(outputQuote),
            bytes32(outputMin),
            bytes1(usePrevHookAmount ? uint8(1) : uint8(0)),
            bytes32(payload.length),
            payload
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
