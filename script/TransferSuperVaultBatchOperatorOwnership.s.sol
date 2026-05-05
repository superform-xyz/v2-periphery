// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperVaultBatchOperator } from "../src/SuperVault/SuperVaultBatchOperator.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title TransferSuperVaultBatchOperatorOwnership
/// @notice Script to transfer SuperVaultBatchOperator admin role to SUPER_GOVERNOR_ADDRESS
contract TransferSuperVaultBatchOperatorOwnership is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for SuperVaultBatchOperator
    string internal constant BATCH_OPERATOR_KEY = "SuperVaultBatchOperator";

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer admin role to SUPER_GOVERNOR_ADDRESS
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param chainId Chain ID
    /// @param batchOperatorAddr The deployed SuperVaultBatchOperator address
    /// @param currentAdmin Current admin address (must match deployed operator's admin)
    function run(uint256 env, uint64 chainId, address batchOperatorAddr, address currentAdmin) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== Transfer SuperVaultBatchOperator Admin Role ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Batch Operator Address:", batchOperatorAddr);
        console2.log("Current Admin:", currentAdmin);
        console2.log("New Admin (SUPER_GOVERNOR_ADDRESS):", SUPER_GOVERNOR_ADDRESS);
        console2.log("");

        require(batchOperatorAddr.code.length > 0, "SuperVaultBatchOperator not deployed at given address");

        SuperVaultBatchOperator batchOperator = SuperVaultBatchOperator(batchOperatorAddr);
        bytes32 DEFAULT_ADMIN_ROLE = batchOperator.DEFAULT_ADMIN_ROLE();
        bytes32 OPERATOR_ROLE = batchOperator.OPERATOR_ROLE();

        // Check current role state
        console2.log("Batch Operator Address:", batchOperatorAddr);

        bool currentAdminHasAdmin = batchOperator.hasRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        bool newAdminHasAdmin = batchOperator.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS);

        console2.log("Current admin has DEFAULT_ADMIN_ROLE:", currentAdminHasAdmin);
        console2.log("SUPER_GOVERNOR has DEFAULT_ADMIN_ROLE:", newAdminHasAdmin);

        // Check if transfer is complete (skip if so)
        bool fullyTransferred = newAdminHasAdmin && !currentAdminHasAdmin;

        if (fullyTransferred) {
            console2.log("");
            console2.log("=== SKIPPED: Admin Role Already Transferred ===");
            console2.log("SUPER_GOVERNOR_ADDRESS already has admin role and current admin has none.");
            return;
        }

        // Verify we can proceed (current admin must have admin role to grant/revoke)
        require(currentAdminHasAdmin, "ADMIN_MISMATCH: Current admin does not have DEFAULT_ADMIN_ROLE");

        // Transfer admin role to SUPER_GOVERNOR_ADDRESS
        console2.log("");
        console2.log("Granting DEFAULT_ADMIN_ROLE to SUPER_GOVERNOR_ADDRESS...");

        if (!newAdminHasAdmin) {
            batchOperator.grantRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS);
            console2.log("  [+] Granted DEFAULT_ADMIN_ROLE");
        } else {
            console2.log("  [=] DEFAULT_ADMIN_ROLE already granted");
        }

        // Revoke admin role from current admin
        console2.log("");
        console2.log("Revoking DEFAULT_ADMIN_ROLE from current admin...");

        if (currentAdminHasAdmin) {
            batchOperator.revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
            console2.log("  [-] Revoked DEFAULT_ADMIN_ROLE");
        } else {
            console2.log("  [=] DEFAULT_ADMIN_ROLE already revoked");
        }

        // Verify transfer
        require(
            batchOperator.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS), "TRANSFER_FAILED: New admin role mismatch"
        );
        require(!batchOperator.hasRole(DEFAULT_ADMIN_ROLE, currentAdmin), "TRANSFER_FAILED: Old admin still has role");

        console2.log("");
        console2.log("=== Transfer Complete ===");
        console2.log("New Admin:", SUPER_GOVERNOR_ADDRESS);
        console2.log("Has DEFAULT_ADMIN_ROLE:", batchOperator.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("====== Admin Role Transfer Complete ======");
    }

    /// @notice Check current role status
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param chainId Chain ID
    /// @param batchOperatorAddr The deployed SuperVaultBatchOperator address
    /// @param deployedAdmin Admin address used during deployment
    function runCheck(uint256 env, uint64 chainId, address batchOperatorAddr, address deployedAdmin) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== SuperVaultBatchOperator Role Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Batch Operator Address:", batchOperatorAddr);
        console2.log("SUPER_GOVERNOR_ADDRESS:", SUPER_GOVERNOR_ADDRESS);
        console2.log("");

        if (batchOperatorAddr.code.length == 0) {
            console2.log("Status: NOT DEPLOYED at given address");
            return;
        }

        SuperVaultBatchOperator batchOperator = SuperVaultBatchOperator(batchOperatorAddr);
        bytes32 DEFAULT_ADMIN_ROLE = batchOperator.DEFAULT_ADMIN_ROLE();
        bytes32 OPERATOR_ROLE = batchOperator.OPERATOR_ROLE();

        // Get operator address for this environment
        address operator = _getOperatorForEnv(env);

        console2.log("=== Role Status ===");
        console2.log("Deployer has DEFAULT_ADMIN_ROLE:", batchOperator.hasRole(DEFAULT_ADMIN_ROLE, deployedAdmin));
        console2.log("SUPER_GOVERNOR has DEFAULT_ADMIN_ROLE:", batchOperator.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("Operator has OPERATOR_ROLE:", batchOperator.hasRole(OPERATOR_ROLE, operator));
        console2.log("");

        if (batchOperator.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS)) {
            console2.log("Status: ADMIN ROLE ALREADY TRANSFERRED");
        } else if (batchOperator.hasRole(DEFAULT_ADMIN_ROLE, deployedAdmin)) {
            console2.log("Status: ADMIN ROLE NEEDS TRANSFER");
            console2.log("  From:", deployedAdmin);
            console2.log("  To:", SUPER_GOVERNOR_ADDRESS);
        } else {
            console2.log("Status: UNEXPECTED - Neither deployer nor SUPER_GOVERNOR has admin role");
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get operator address based on environment
    /// @param env Environment (0 = prod, 2 = staging)
    function _getOperatorForEnv(uint256 env) internal pure returns (address) {
        if (env == 0) {
            return BATCH_OPERATOR_PROD;
        } else {
            return BATCH_OPERATOR_STAGING;
        }
    }

    /// @notice Compute the deterministic address for SuperVaultBatchOperator
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param admin Admin address
    /// @param operator Operator address
    function _computeAddress(uint256 env, address admin, address operator) internal view returns (address) {
        bytes memory bytecode = __getBytecode(BATCH_OPERATOR_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(bytecode, abi.encode(admin, operator)), __getSalt(BATCH_OPERATOR_KEY)
        );
    }
}
