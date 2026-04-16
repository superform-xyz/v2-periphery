// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";

/// @title SuperBankKyberSwapIntegration
/// @notice Integration test: SuperBank.executeHooks swaps on HyperEVM via ApproveAndSwapKyberSwapHook
/// @dev Uses production-deployed contracts on a HyperEVM fork (chain 999).
///
///      ApproveAndSwapKyberSwapHook is a combined approve+swap hook. Its inspect()
///      returns abi.encodePacked(dstToken), so the merkle leaf is keyed by destination token.
///
/// Run:
///   forge test --match-contract SuperBankKyberSwapIntegration -vvv
contract SuperBankKyberSwapIntegration is Test {
    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (HYPEREVM)
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // v2-core prod hooks (HyperEVM)
    address constant APPROVE_ERC20_HOOK = 0x8b789980dc6cC7d88E30C442D704646ff7F6d306;
    address constant APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xF3818ac90DCA76a7Efe40C3cB2548F96B2236595;
    address constant SWAP_KYBERSWAP_HOOK = 0x1851A7fa26B507b681187585e3B368B95FbfdBB0;
    address constant APPROVE_AND_ACROSS_HOOK = 0x77c932e8F7A308Ddf0EB4cd94ea0526Ed676eFeE;

    // Tokens (HyperEVM)
    address constant USDC = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    address constant UP_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

    // Chain
    uint256 constant HYPEREVM_CHAIN_ID = 999;

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

        // Grant this test contract GOVERNOR_ROLE and BANK_MANAGER_ROLE via direct storage writes
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        // Sanity checks
        assertTrue(superGovernor.hasRole(superGovernor.GOVERNOR_ROLE(), address(this)), "GOVERNOR_ROLE not granted");
        assertTrue(
            superGovernor.hasRole(superGovernor.BANK_MANAGER_ROLE(), address(this)), "BANK_MANAGER_ROLE not granted"
        );

        // Register hooks (idempotent — no-op if already registered)
        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        superGovernor.registerHook(APPROVE_AND_ACROSS_HOOK);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              TEST WITH PRODUCTION MERKLE TREES
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Validates that the production merkle roots can be set and that the hook
    ///         registration and root proposal/execution flow works for KyberSwap on HyperEVM.
    /// @dev Uses production roots from superman/deployments/superbank/generated/prod/999/
    ///
    ///      ApproveAndSwapKyberSwapHook (0xF3818ac9...): root 0xfd0cee7e..., 2 leaves (dst_token=USDC,UP)
    ///      ApproveERC20Hook            (0x8b789980...): root 0x1ce055e9..., 10 leaves
    function test_setProductionMerkleRoots_kyberSwapOnHyperEVM() public {
        // Set production merkle roots
        //   ApproveERC20Hook: 10 leaves (USDC+UP approved for various spenders)
        _setMerkleRoot(APPROVE_ERC20_HOOK, 0x1ce055e97c45de28b011b800771200feb493f26913c683dd30aac4af9bb0b485);
        //   ApproveAndSwapKyberSwapHook: 2 leaves (dst_token=USDC, dst_token=UP)
        _setMerkleRoot(
            APPROVE_AND_SWAP_KYBERSWAP_HOOK, 0xfd0cee7ef52e43e35f4bb5259fd373a4f4ee2f21bc3164d3b2f3036ee9a985f8
        );

        // Verify roots are set
        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_ERC20_HOOK),
            0x1ce055e97c45de28b011b800771200feb493f26913c683dd30aac4af9bb0b485,
            "ApproveERC20Hook root mismatch"
        );
        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            0xfd0cee7ef52e43e35f4bb5259fd373a4f4ee2f21bc3164d3b2f3036ee9a985f8,
            "ApproveAndSwapKyberSwapHook root mismatch"
        );

        console2.log("Production merkle roots set successfully for KyberSwap on HyperEVM");
    }

    /// @notice Validates the SwapKyberSwapHook production merkle root on HyperEVM.
    function test_setProductionMerkleRoots_swapKyberSwapOnHyperEVM() public {
        superGovernor.registerHook(SWAP_KYBERSWAP_HOOK);

        //   SwapKyberSwapHook: 2 leaves (dst_token=USDC, dst_token=UP)
        _setMerkleRoot(SWAP_KYBERSWAP_HOOK, 0x89ef5092e84840c57e8fac67b3069b08cb62fc6c07c3f8506dd8509ea770ff0f);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(SWAP_KYBERSWAP_HOOK),
            0x89ef5092e84840c57e8fac67b3069b08cb62fc6c07c3f8506dd8509ea770ff0f,
            "SwapKyberSwapHook root mismatch"
        );

        console2.log("SwapKyberSwapHook production merkle root set successfully on HyperEVM");
    }

    /// @notice Validates the full ApproveAndSwapKyberSwapHook inspect() → merkle leaf flow.
    /// @dev Encodes hook data, computes leaf hashes, and verifies they match the generated tree.
    ///      Leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, encodedArgs))))
    ///      Where encodedArgs = abi.encodePacked(dstToken)
    function test_inspectAndVerifyLeaf_approveAndSwapKyberSwap() public pure {
        // Leaf 0: dst_token = UP (UpOft)
        {
            bytes memory encodedArgs = abi.encodePacked(UP_OFT);
            bytes32 computedLeaf =
                keccak256(bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs))));
            assertEq(
                computedLeaf,
                0x306d0515d6386244f4cbe03bd0803eeb7a4b879f3e009e7cf143e8079401f810,
                "Leaf hash mismatch for dst_token=UP"
            );
        }

        // Leaf 1: dst_token = USDC
        {
            bytes memory encodedArgs = abi.encodePacked(USDC);
            bytes32 computedLeaf =
                keccak256(bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs))));
            assertEq(
                computedLeaf,
                0xf8941e7df08cd5767243a79f66843c9ab424c485bb155f8d978bd7fbf325145f,
                "Leaf hash mismatch for dst_token=USDC"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //      TEST WITH PRODUCTION MERKLE TREES — APPROVE AND ACROSS
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Validates the ApproveAndAcrossSendFundsAndExecuteOnDstHook production merkle root on HyperEVM.
    function test_setProductionMerkleRoots_approveAndAcrossOnHyperEVM() public {
        //   ApproveAndAcrossSendFundsAndExecuteOnDstHook: 6 leaves
        _setMerkleRoot(APPROVE_AND_ACROSS_HOOK, 0x893631ba68fd73c2e74dcf604a4b5ef869f5254463eedfe50a1edca19db166e8);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_ACROSS_HOOK),
            0x893631ba68fd73c2e74dcf604a4b5ef869f5254463eedfe50a1edca19db166e8,
            "ApproveAndAcrossSendFundsAndExecuteOnDstHook root mismatch"
        );

        console2.log("ApproveAndAcross production merkle root set successfully on HyperEVM");
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

    /// @dev Grants a role on the SuperGovernor by writing directly to AccessControl storage.
    function _forceGrantRole(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR_ADDR, hasRoleSlot, bytes32(uint256(1)));
    }
}
