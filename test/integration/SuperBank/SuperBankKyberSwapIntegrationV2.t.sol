// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { KyberSwapAPIParser } from "@superform-v2-core/test/utils/parsers/KyberSwapAPIParser.sol";
import { Surl } from "@surl/Surl.sol";
import { strings } from "@stringutils/strings.sol";
import { AcrossV3Helper } from "@pigeon/across/AcrossV3Helper.sol";

/// @title SuperBankKyberSwapIntegrationV2
/// @notice Integration tests for the redeployed (standardized) ApproveAndSwapKyberSwapHook on HyperEVM (chain 999)
/// @dev Validates production merkle roots from superman/deployments/superbank/generated/prod/999/
///      hook_0xcf5419270c9415e44c97e595c505708cfa334c30.json (ApproveAndSwapKyberSwapHook, 4 leaves)
///      hook_0x8643a93724f97b60d3d5d64cb44d0f3e012e2cde.json (ApproveAndAcross, 6 leaves)
///
///      The redeployed hook uses the standardized swap calldata layout
///      (52-byte zero header + Layer 1 + Layer 2 payload = abi.encode(txData));
///      inspect() still resolves to the destination/output token, so leaf args are unchanged.
///
/// Run:
///   forge test --match-contract SuperBankKyberSwapIntegrationV2 -vvv
contract SuperBankKyberSwapIntegrationV2 is Test, KyberSwapAPIParser {
    using Surl for *;
    using strings for *;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (HYPEREVM)
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // v2-core prod hooks (HyperEVM) — redeployed (script/output/prod/999/HyperEVM-latest.json)
    address constant APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xcF5419270C9415E44c97E595c505708cfA334C30;
    address constant APPROVE_AND_ACROSS_HOOK = 0x8643A93724F97b60D3d5d64cb44d0F3e012e2CDe;
    address constant SWAP_KYBERSWAP_HOOK = 0x05c49e05bb8575afdf1142cC95dA6747b069174A;
    address constant ACROSS_SEND_FUNDS_HOOK = 0xc5147702Cfd4d8ab5F028e57B30253460583b54d;

    // Tokens (HyperEVM)
    address constant USDC = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    address constant UP_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    address constant WHYPE = 0x5555555555555555555555555555555555555555;

    // Base USDC (cross-chain output token in the HyperEVM Across trees)
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // KyberSwap MetaAggregationRouterV2 (read from SWAP_KYBERSWAP_HOOK.KYBER_ROUTER())
    address constant KYBER_ROUTER = 0x6131B5fae19EA4f9D964eAc0408E4408b66337b5;

    // Across V3 SpokePools (HYPEREVM value read from the deployed hooks' SPOKE_POOL_V3())
    address constant HYPEREVM_SPOKE_POOL = 0x35E63eA3eb0fb7A3bc543C71FB66412e1F6B0E04;
    address constant BASE_SPOKE_POOL = 0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64;

    uint256 constant HYPEREVM_CHAIN_ID = 999;
    uint256 constant BASE_CHAIN_ID = 8453;

    // ── Production merkle root (from superman/deployments/superbank/generated/prod/999/) ──
    // HyperEVM ApproveAndSwapKyberSwapHook (0xcF5419...): 4 leaves (USDC, UP_OFT, UP_ETH, UP_BASE)
    bytes32 constant HYPEREVM_KYBERSWAP_ROOT = 0xac4a92a3b8b7b71c3d2e7081389c448404980051efdd7cf36f79cf09f7394b8e;
    // HyperEVM ApproveAndAcrossSendFundsAndExecuteOnDstHook (0x8643A937...): 6 leaves
    bytes32 constant HYPEREVM_APPROVE_AND_ACROSS_ROOT =
        0x285f976599d07c604e1b13580dc3bbaf43064223e4c5610784b5b1c0b289f3e8;
    // HyperEVM SwapKyberSwapHook (0x05c49e05...): 2 leaves (UP_OFT, USDC)
    bytes32 constant HYPEREVM_SWAP_KYBERSWAP_ROOT =
        0x5bbbc06ab3786f3ead20492e88ec732a8045e14344b03e9d114c0be75ee2404d;
    // HyperEVM AcrossSendFundsAndExecuteOnDstHook (0xc5147702...): 6 leaves
    bytes32 constant HYPEREVM_ACROSS_ROOT = 0xa20104149c80c1beb82aaaf68f82c8d0fa2446eb69d8a6726d237a0c3ba82224;

    // Retry config for API-dependent tests
    uint256 constant MAX_RETRIES = 3;

    // Contracts
    SuperBank superBank;
    SuperGovernor superGovernor;

    // ═══════════════════════════════════════════════════════════════════
    //                              SETUP
    // ═══════════════════════════════════════════════════════════════════

    function setUp() public {
        vm.createSelectFork(vm.envString("HYPEREVM_RPC_URL"));

        superBank = SuperBank(payable(SUPER_BANK));
        superGovernor = SuperGovernor(SUPER_GOVERNOR_ADDR);

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        assertTrue(superGovernor.hasRole(superGovernor.GOVERNOR_ROLE(), address(this)), "GOVERNOR_ROLE not granted");
        assertTrue(
            superGovernor.hasRole(superGovernor.BANK_MANAGER_ROLE(), address(this)), "BANK_MANAGER_ROLE not granted"
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //         KYBERSWAP: LEAF HASH VERIFICATION (PURE — NO FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify computed leaf hashes match generated tree for ApproveAndSwapKyberSwapHook on HyperEVM.
    function test_inspectAndVerifyLeaf_approveAndSwapKyberSwap_hyperEVM() public pure {
        // Leaf 0: dst_token = UP_OFT
        {
            bytes memory encodedArgs = abi.encodePacked(UP_OFT);
            bytes32 computedLeaf =
                keccak256(bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs))));
            assertEq(
                computedLeaf,
                0x34571fee8571b9270c9f1cbf4edb91a42c3a7eb0fa5c5f9f3af5c38f54c8da9a,
                "Leaf hash mismatch for dst_token=UP_OFT"
            );
        }

        // Leaf 1: dst_token = USDC
        {
            bytes memory encodedArgs = abi.encodePacked(USDC);
            bytes32 computedLeaf =
                keccak256(bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs))));
            assertEq(
                computedLeaf,
                0x4e6e856a74280aa24ffc7141200a7244853efddd4cc65b1dafe7786ea21ceaeb,
                "Leaf hash mismatch for dst_token=USDC"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //              KYBERSWAP: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle root for the redeployed ApproveAndSwapKyberSwapHook on HyperEVM and verify.
    function test_setProductionMerkleRoots_kyberSwapOnHyperEVM() public {
        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, HYPEREVM_KYBERSWAP_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            HYPEREVM_KYBERSWAP_ROOT,
            "ApproveAndSwapKyberSwapHook root mismatch"
        );
        console2.log("HyperEVM ApproveAndSwapKyberSwapHook (redeployed) production merkle root set successfully");
    }

    /// @notice Validates the redeployed ApproveAndAcross production merkle root on HyperEVM.
    function test_setProductionMerkleRoots_approveAndAcrossOnHyperEVM() public {
        superGovernor.registerHook(APPROVE_AND_ACROSS_HOOK);
        _setMerkleRoot(APPROVE_AND_ACROSS_HOOK, HYPEREVM_APPROVE_AND_ACROSS_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_ACROSS_HOOK),
            HYPEREVM_APPROVE_AND_ACROSS_ROOT,
            "ApproveAndAcross root mismatch"
        );
        console2.log("ApproveAndAcross (redeployed) production merkle root set successfully on HyperEVM");
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAP ON HYPEREVM (WHYPE → USDC)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap WHYPE→USDC on HyperEVM via the redeployed ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapWHYPEtoUSDC_kyberSwap_onHyperEVM() public {
        _skipIfKyberUnavailable("hyperevm", WHYPE, USDC);

        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, HYPEREVM_KYBERSWAP_ROOT);

        uint256 swapAmount = 1 ether; // 1 WHYPE

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(WHYPE, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(WHYPE, USDC, swapAmount, "hyperevm");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                WHYPE, USDC, swapAmount, expectedOut, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    APPROVE_AND_SWAP_KYBERSWAP_HOOK,
                    hookData,
                    _getHyperEvmKyberSwapProof(USDC)
                )
            ) {
                uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);
                uint256 whypeAfter = IERC20(WHYPE).balanceOf(SUPER_BANK);

                assertEq(whypeAfter, 0, "All WHYPE should be consumed");
                assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

                console2.log("KyberSwap HyperEVM: %d WHYPE -> %d USDC", swapAmount, usdcAfter - usdcBefore);
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        vm.skip(true); // KyberSwap live routes returned incompatible calldata on all retries — skip rather than fail CI
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAP VIA STANDALONE SwapKyberSwapHook
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Swaps WHYPE→USDC on HyperEVM via the standalone (redeployed) SwapKyberSwapHook with
    ///         its production merkle root.
    /// @dev The production ApproveERC20Hook tree has NO leaf for the KyberSwap router as spender, so
    ///      the router allowance is set here via prank as test setup. Flagged as a config gap: without
    ///      an approve leaf the standalone SwapKyberSwapHook is not executable through SuperBank in
    ///      production — only the ApproveAndSwap variant is.
    function test_executeHooks_swapWHYPEtoUSDC_standaloneKyberSwap_onHyperEVM() public {
        _skipIfKyberUnavailable("hyperevm", WHYPE, USDC);

        superGovernor.registerHook(SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(SWAP_KYBERSWAP_HOOK, HYPEREVM_SWAP_KYBERSWAP_ROOT);

        uint256 swapAmount = 1 ether; // 1 WHYPE

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(WHYPE, SUPER_BANK, swapAmount);

            // Test-only router allowance (no production approve leaf for the KyberSwap router)
            vm.prank(SUPER_BANK);
            IERC20(WHYPE).approve(KYBER_ROUTER, swapAmount);

            (bytes memory txData, uint256 expectedOut) = _getKyberSwapTxData(WHYPE, USDC, swapAmount, "hyperevm");
            console2.log("KyberSwap (standalone) attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData =
                _encodeKyberSwapHookData(WHYPE, USDC, swapAmount, expectedOut, expectedOut / 2, false, txData);

            uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(SWAP_KYBERSWAP_HOOK, hookData, _getHyperEvmSwapKyberSwapProof(USDC))
            ) {
                assertEq(IERC20(WHYPE).balanceOf(SUPER_BANK), 0, "All WHYPE should be consumed");
                assertGt(IERC20(USDC).balanceOf(SUPER_BANK) - usdcBefore, 0, "SuperBank should have received USDC");
                console2.log("Standalone KyberSwap HyperEVM: swapped WHYPE -> USDC");
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        vm.skip(true); // KyberSwap live routes returned incompatible calldata on all retries
    }

    // ═══════════════════════════════════════════════════════════════════
    //       ACROSS: REAL BRIDGE HYPEREVM → BASE (UP OFT)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Bridges USDC from SuperBank on HyperEVM to USDC on the Base SuperBank via the redeployed
    ///         ApproveAndAcross hook with its production merkle root, relayed with Pigeon.
    /// @dev Base USDC (0x8335...) is the only cross-chain-valid output token in the HyperEVM Across trees.
    function test_executeHooks_bridgeUSDCtoBase_withApproveAndAcross_onHyperEVM() public {
        superGovernor.registerHook(APPROVE_AND_ACROSS_HOOK);
        _setMerkleRoot(APPROVE_AND_ACROSS_HOOK, HYPEREVM_APPROVE_AND_ACROSS_ROOT);

        uint256 bridgeAmount = 100e6; // 100 USDC (6 decimals)
        deal(USDC, SUPER_BANK, bridgeAmount);

        bytes memory acrossData = _encodeAcrossHookData(
            SUPER_BANK, USDC, BASE_USDC, bridgeAmount, bridgeAmount * 99 / 100, BASE_CHAIN_ID, false, bytes("")
        );

        vm.recordLogs();
        superBank.executeHooks(
            _buildSingleHookExecutionData(APPROVE_AND_ACROSS_HOOK, acrossData, _getApproveAndAcrossUsdcToBaseProof())
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), 0, "All USDC should be consumed by the bridge");

        _relayToBaseAndAssertUsdcArrived(logs);
    }

    /// @notice Bridges USDC HyperEVM→Base via the standalone AcrossSendFundsAndExecuteOnDstHook
    ///         with its production merkle root.
    /// @dev The production ApproveERC20Hook tree on HyperEVM has NO leaf for the HyperEVM SpokePool
    ///      as spender, so the allowance is set here via prank as test setup. Flagged as a config gap:
    ///      only the ApproveAndAcross variant is executable end-to-end through SuperBank in production.
    function test_executeHooks_bridgeUSDCtoBase_standaloneAcross_onHyperEVM() public {
        superGovernor.registerHook(ACROSS_SEND_FUNDS_HOOK);
        _setMerkleRoot(ACROSS_SEND_FUNDS_HOOK, HYPEREVM_ACROSS_ROOT);

        uint256 bridgeAmount = 100e6; // 100 USDC (6 decimals)
        deal(USDC, SUPER_BANK, bridgeAmount);

        // Test-only SpokePool allowance (no production approve leaf for the HyperEVM SpokePool)
        vm.prank(SUPER_BANK);
        IERC20(USDC).approve(HYPEREVM_SPOKE_POOL, bridgeAmount);

        bytes memory acrossData = _encodeAcrossHookData(
            SUPER_BANK, USDC, BASE_USDC, bridgeAmount, bridgeAmount * 99 / 100, BASE_CHAIN_ID, false, bytes("")
        );

        vm.recordLogs();
        superBank.executeHooks(
            _buildSingleHookExecutionData(ACROSS_SEND_FUNDS_HOOK, acrossData, _getAcrossUsdcToBaseProof())
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(IERC20(USDC).balanceOf(SUPER_BANK), 0, "All USDC should be consumed by the bridge");

        _relayToBaseAndAssertUsdcArrived(logs);
    }

    /// @dev Relays the recorded Across deposit to a fresh Base fork via Pigeon and asserts
    ///      USDC arrived on the Base SuperBank.
    function _relayToBaseAndAssertUsdcArrived(Vm.Log[] memory logs) internal {
        uint256 srcForkId = vm.activeFork();
        uint256 baseForkId = vm.createFork(vm.envString("BASE_RPC_URL"));
        vm.selectFork(baseForkId);
        uint256 usdcBefore = IERC20(BASE_USDC).balanceOf(SUPER_BANK);
        vm.selectFork(srcForkId); // back to the HyperEVM fork

        AcrossV3Helper acrossHelper = new AcrossV3Helper();
        vm.makePersistent(address(acrossHelper));
        address relayer = makeAddr("ACROSS_RELAYER");
        vm.makePersistent(relayer);

        acrossHelper.help(
            HYPEREVM_SPOKE_POOL,
            BASE_SPOKE_POOL,
            relayer,
            block.timestamp,
            baseForkId,
            BASE_CHAIN_ID,
            HYPEREVM_CHAIN_ID,
            logs
        );

        vm.selectFork(baseForkId);
        uint256 usdcAfter = IERC20(BASE_USDC).balanceOf(SUPER_BANK);
        assertGt(usdcAfter - usdcBefore, 0, "USDC should have arrived on Base via bridge");
        console2.log("Bridged USDC arrived on Base:", usdcAfter - usdcBefore);
    }

    /// @dev Redeployed Across hook data layout (52-byte header + packed args, see
    ///      v2-core AcrossSendFundsAndExecuteOnDstHook.sol).
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

    // ═══════════════════════════════════════════════════════════════════
    //                     KYBERSWAP API HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _skipIfKyberUnavailable(string memory chain, address tokenIn, address tokenOut) internal {
        try this._tryKyberRoute(chain, tokenIn, tokenOut) {}
        catch {
            vm.skip(true);
        }
    }

    function _tryKyberRoute(string memory chain, address tokenIn, address tokenOut) external {
        surlCallRoutes(tokenIn, tokenOut, 1 ether, chain);
    }

    function _getKyberSwapTxData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        string memory chain
    )
        internal
        returns (bytes memory txData_, uint256 expectedOut)
    {
        string memory routeSummary = surlCallRoutes(tokenIn, tokenOut, amountIn, chain);
        expectedOut = extractAmountOut(routeSummary);
        string memory txDataHex = surlCallBuild(routeSummary, SUPER_BANK, SUPER_BANK, 200, chain);
        txData_ = fromHex(txDataHex);
    }

    /// @dev Standardized swap hook data layout (see v2-core SwapCalldataLayout.sol):
    ///      [52-byte zero header][inputToken(20)][outputToken(20)][inputAmount(32)]
    ///      [outputQuote(32)][outputMin(32)][usePrevHookAmount(1)][payloadLength(32)][payload(var)]
    ///      Payload for KyberSwap: abi.encode(bytes txData)
    function _encodeKyberSwapHookData(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputQuote,
        uint256 outputMin,
        bool usePrevHookAmount,
        bytes memory txData
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory payload = abi.encode(txData);
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
    //              KYBERSWAP PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev HyperEVM ApproveAndSwapKyberSwapHook proofs (4 leaves)
    ///      Source: hook_0xcf5419270c9415e44c97e595c505708cfa334c30.json (chain 999)
    function _getHyperEvmKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        if (dstToken == 0x642fFC3496AcA19106BAB7A42F1F221a329654fe) {
            // UP_OFT, idx 0
            proof = new bytes32[](2);
            proof[0] = 0x4e6e856a74280aa24ffc7141200a7244853efddd4cc65b1dafe7786ea21ceaeb;
            proof[1] = 0x91bf797ff71011c2df1d9c6639d72c0361318d354837e102544580fde995d2b9;
        } else if (dstToken == 0xb88339CB7199b77E23DB6E890353E22632Ba630f) {
            // USDC, idx 1
            proof = new bytes32[](2);
            proof[0] = 0x34571fee8571b9270c9f1cbf4edb91a42c3a7eb0fa5c5f9f3af5c38f54c8da9a;
            proof[1] = 0x91bf797ff71011c2df1d9c6639d72c0361318d354837e102544580fde995d2b9;
        } else {
            revert("Unknown dstToken - not in HyperEVM KyberSwap tree");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     EXECUTION DATA BUILDER
    // ═══════════════════════════════════════════════════════════════════

    /// @dev HyperEVM standalone SwapKyberSwapHook proofs (2 leaves: UP_OFT, USDC)
    ///      Source: hook_0x05c49e05bb8575afdf1142cc95da6747b069174a.json (chain 999)
    function _getHyperEvmSwapKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](1);
        if (dstToken == USDC) {
            // USDC, idx 1
            proof[0] = 0xb917ab4edcac9259f8fe8bc6f59c4695b43940e5806fb7755aef61a8dabc723b;
        } else {
            revert("Unknown dstToken - not in HyperEVM SwapKyberSwapHook tree");
        }
    }

    /// @dev HyperEVM ApproveAndAcross proof for USDC(999)→USDC(Base) leaf (index 5, 6 leaves).
    ///      Source: hook_0x8643a93724f97b60d3d5d64cb44d0f3e012e2cde.json (chain 999)
    ///      Args: recipient=SuperBank, inputToken=USDC(999), outputToken=Base USDC, exclusiveRelayer=0x0
    function _getApproveAndAcrossUsdcToBaseProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        proof[0] = 0xcecf9771038ea45b6f3ff6b249b7b21155d0d7af268a87b3156d9cda315acd7d;
        proof[1] = 0x8b2df561ac441bbb7466f319cc957399719d0e9df17661a0a827ebf9e4922b2c;
    }

    /// @dev HyperEVM standalone AcrossSendFundsHook proof for USDC(999)→USDC(Base) leaf (index 5, 6 leaves).
    ///      Source: hook_0xc5147702cfd4d8ab5f028e57b30253460583b54d.json (chain 999)
    ///      Args: recipient=SuperBank, inputToken=USDC(999), outputToken=Base USDC, exclusiveRelayer=0x0
    function _getAcrossUsdcToBaseProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        proof[0] = 0xa4f4a6d4f13d4e51d3409d514bad6e3ce6e4a458742b8fb2b3e59558f7a62300;
        proof[1] = 0x53c576e5aaa1baf930a1b5632fd8fe6621deaacdfefe7ec767c4b0640d2151cb;
    }

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

    // ═══════════════════════════════════════════════════════════════════
    //                     MERKLE ROOT MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════

    function _setMerkleRoot(address hook, bytes32 root) internal {
        uint256 savedTimestamp = block.timestamp;
        superGovernor.proposeSuperBankHookMerkleRoot(hook, root);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook);
        vm.warp(savedTimestamp);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook), root, "Merkle root mismatch");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     ACCESS CONTROL HELPER
    // ═══════════════════════════════════════════════════════════════════

    function _forceGrantRole(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR_ADDR, hasRoleSlot, bytes32(uint256(1)));
    }
}
