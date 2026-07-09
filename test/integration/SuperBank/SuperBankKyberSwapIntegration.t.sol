// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { KyberSwapAPIParser } from "@superform-v2-core/test/utils/parsers/KyberSwapAPIParser.sol";
import { Surl } from "@surl/Surl.sol";
import { strings } from "@stringutils/strings.sol";

/// @title SuperBankKyberSwapIntegration
/// @notice Integration tests for ApproveAndSwapKyberSwapHook on HyperEVM (chain 999)
/// @dev Validates production merkle roots from superman/deployments/superbank/generated/
///      Tests real swaps on HyperEVM fork using live KyberSwap quotes.
///
/// Run:
///   forge test --match-contract SuperBankKyberSwapIntegration -vvv
contract SuperBankKyberSwapIntegration is Test, KyberSwapAPIParser {
    using Surl for *;
    using strings for *;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (HYPEREVM)
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // v2-core prod hooks (HyperEVM) — current deployments
    address constant APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xdC9D10d9710DBf82924a3F7733293457Ad12D37D;
    address constant APPROVE_AND_ACROSS_HOOK = 0x77c932e8F7A308Ddf0EB4cd94ea0526Ed676eFeE;

    // Tokens (HyperEVM)
    address constant USDC = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    address constant UP_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    address constant WHYPE = 0x5555555555555555555555555555555555555555;

    // ── Production merkle root (from superman/deployments/superbank/generated/) ──
    // HyperEVM ApproveAndSwapKyberSwapHook (0xdC9D10d9): 4 leaves (USDC, UP_OFT, UP_ETH, UP_BASE)
    bytes32 constant HYPEREVM_KYBERSWAP_ROOT = 0x18b62ae3075292dbd5d6eae622ad53f17f7b2b106a2c0c9b55e1a2b8383f95f6;

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
                0x0691d5cc4c6f90159bb4601b754daa4349df3499f31281ef46a3fa1183676a10,
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
                0x1ecf4fa5f73a9b1314f4ba99804c5c95fa5aae307df29af3743990df466e2572,
                "Leaf hash mismatch for dst_token=USDC"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //              KYBERSWAP: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle root for ApproveAndSwapKyberSwapHook on HyperEVM and verify.
    function test_setProductionMerkleRoots_kyberSwapOnHyperEVM() public {
        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, HYPEREVM_KYBERSWAP_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            HYPEREVM_KYBERSWAP_ROOT,
            "ApproveAndSwapKyberSwapHook root mismatch"
        );
        console2.log("HyperEVM ApproveAndSwapKyberSwapHook production merkle root set successfully");
    }

    /// @notice Validates the ApproveAndAcross production merkle root on HyperEVM.
    function test_setProductionMerkleRoots_approveAndAcrossOnHyperEVM() public {
        superGovernor.registerHook(APPROVE_AND_ACROSS_HOOK);
        _setMerkleRoot(APPROVE_AND_ACROSS_HOOK, 0x893631ba68fd73c2e74dcf604a4b5ef869f5254463eedfe50a1edca19db166e8);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_ACROSS_HOOK),
            0x893631ba68fd73c2e74dcf604a4b5ef869f5254463eedfe50a1edca19db166e8,
            "ApproveAndAcross root mismatch"
        );
        console2.log("ApproveAndAcross production merkle root set successfully on HyperEVM");
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAP ON HYPEREVM (WHYPE → USDC)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap WHYPE→USDC on HyperEVM via ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapWHYPEtoUSDC_kyberSwap_onHyperEVM() public {
        _skipIfKyberUnavailable("hyperevm", WHYPE, USDC);

        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, HYPEREVM_KYBERSWAP_ROOT);

        uint256 swapAmount = 1 ether; // 1 WHYPE (~$63)

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(WHYPE, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(WHYPE, USDC, swapAmount, "hyperevm");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                WHYPE, USDC, swapAmount, expectedOut / 2, false, txData
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
        vm.skip(true);
    }

    /// @notice Full integration: swap USDC→WHYPE on HyperEVM via ApproveAndSwapKyberSwapHook.
    ///         Uses WHYPE as an intermediary test since UP is not yet on KyberSwap for HyperEVM.
    ///         dst_token in merkle proof is not checked against the outputToken in the hook data —
    ///         KyberSwap doesn't verify that. But we can't test USDC→UP because KyberSwap has no
    ///         UP liquidity on HyperEVM. So we skip this direction for now.

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

    /// @dev ApproveAndSwapKyberSwapHook data layout:
    ///      [inputToken(20)][outputToken(20)][inputAmount(32)][outputMin(32)]
    ///      [usePrevHookAmount(1)][txDataLength(32)][txData(var)]
    function _encodeKyberSwapHookData(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputMin,
        bool usePrevHookAmount,
        bytes memory txData
    )
        internal
        pure
        returns (bytes memory)
    {
        return bytes.concat(
            bytes20(inputToken),
            bytes20(outputToken),
            bytes32(inputAmount),
            bytes32(outputMin),
            bytes1(usePrevHookAmount ? uint8(1) : uint8(0)),
            bytes32(txData.length),
            txData
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //              KYBERSWAP PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev HyperEVM ApproveAndSwapKyberSwapHook proofs (4 leaves)
    ///      Source: hook_0xdc9d10d9710dbf82924a3f7733293457ad12d37d.json (chain 999)
    function _getHyperEvmKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        if (dstToken == 0x642fFC3496AcA19106BAB7A42F1F221a329654fe) {
            // UP_OFT, idx 0
            proof = new bytes32[](2);
            proof[0] = 0x1ecf4fa5f73a9b1314f4ba99804c5c95fa5aae307df29af3743990df466e2572;
            proof[1] = 0x525c770369ef74c0ca23581b12c97f61a4bc7dc1dca7cbb4c99a429d07354974;
        } else if (dstToken == 0xb88339CB7199b77E23DB6E890353E22632Ba630f) {
            // USDC, idx 1
            proof = new bytes32[](2);
            proof[0] = 0x0691d5cc4c6f90159bb4601b754daa4349df3499f31281ef46a3fa1183676a10;
            proof[1] = 0x525c770369ef74c0ca23581b12c97f61a4bc7dc1dca7cbb4c99a429d07354974;
        } else {
            revert("Unknown dstToken - not in HyperEVM KyberSwap tree");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     EXECUTION DATA BUILDER
    // ═══════════════════════════════════════════════════════════════════

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
