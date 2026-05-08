// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ValidatorBonding } from "../src/ValidatorBonding.sol";
import { console2 } from "forge-std/console2.sol";

/// @title TransferValidatorBondingRoles
/// @notice Transfers ValidatorBonding roles:
///         - DEFAULT_ADMIN_ROLE → SUPER_GOVERNOR_ADDRESS (multisig)
///         - GOVERNOR_ROLE → GOVERNOR (governance EOA)
/// @dev The deployer must currently hold DEFAULT_ADMIN_ROLE to execute this.
contract TransferValidatorBondingRoles is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer roles to production addresses
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param bondingAddr The deployed ValidatorBonding address
    /// @param currentAdmin Current admin address (the deployer)
    function run(uint256 env, address bondingAddr, address currentAdmin) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== Transfer ValidatorBonding Roles ======");
        console2.log("Environment:", env);
        console2.log("ValidatorBonding:", bondingAddr);
        console2.log("Current Admin:", currentAdmin);
        console2.log("New Admin (SUPER_GOVERNOR_ADDRESS):", SUPER_GOVERNOR_ADDRESS);
        console2.log("New Governor (GOVERNOR):", GOVERNOR);
        console2.log("");

        require(bondingAddr.code.length > 0, "ValidatorBonding not deployed at given address");

        ValidatorBonding bonding = ValidatorBonding(bondingAddr);
        bytes32 defaultAdminRole = bonding.DEFAULT_ADMIN_ROLE();
        bytes32 governorRole = bonding.GOVERNOR_ROLE();

        // ===== Current State =====
        console2.log("=== Current Role State ===");

        bool currentAdminHasAdmin = bonding.hasRole(defaultAdminRole, currentAdmin);
        bool superGovernorHasAdmin = bonding.hasRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);
        bool governorHasGovernor = bonding.hasRole(governorRole, GOVERNOR);

        console2.log("Current admin has DEFAULT_ADMIN_ROLE:", currentAdminHasAdmin);
        console2.log("SUPER_GOVERNOR_ADDRESS has DEFAULT_ADMIN_ROLE:", superGovernorHasAdmin);
        console2.log("GOVERNOR has GOVERNOR_ROLE:", governorHasGovernor);
        console2.log("");

        // Check if fully transferred already
        bool fullyTransferred = superGovernorHasAdmin && governorHasGovernor && !currentAdminHasAdmin;

        if (fullyTransferred) {
            console2.log("=== SKIPPED: Roles Already Transferred ===");
            return;
        }

        require(currentAdminHasAdmin, "ADMIN_MISMATCH: Current admin does not have DEFAULT_ADMIN_ROLE");

        // ===== Step 1: Grant GOVERNOR_ROLE to GOVERNOR =====
        console2.log("=== Step 1: Grant GOVERNOR_ROLE ===");
        if (!governorHasGovernor) {
            bonding.grantRole(governorRole, GOVERNOR);
            console2.log("  [+] Granted GOVERNOR_ROLE to:", GOVERNOR);
        } else {
            console2.log("  [=] GOVERNOR_ROLE already granted to:", GOVERNOR);
        }

        // ===== Step 2: Grant DEFAULT_ADMIN_ROLE to SUPER_GOVERNOR_ADDRESS =====
        console2.log("=== Step 2: Grant DEFAULT_ADMIN_ROLE ===");
        if (!superGovernorHasAdmin) {
            bonding.grantRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);
            console2.log("  [+] Granted DEFAULT_ADMIN_ROLE to:", SUPER_GOVERNOR_ADDRESS);
        } else {
            console2.log("  [=] DEFAULT_ADMIN_ROLE already granted to:", SUPER_GOVERNOR_ADDRESS);
        }

        // ===== Step 3: Revoke DEFAULT_ADMIN_ROLE from current admin =====
        console2.log("=== Step 3: Revoke DEFAULT_ADMIN_ROLE from current admin ===");
        if (currentAdminHasAdmin) {
            bonding.revokeRole(defaultAdminRole, currentAdmin);
            console2.log("  [-] Revoked DEFAULT_ADMIN_ROLE from:", currentAdmin);
        } else {
            console2.log("  [=] DEFAULT_ADMIN_ROLE already revoked from:", currentAdmin);
        }

        // ===== Verify =====
        console2.log("");
        console2.log("=== Verification ===");

        require(
            bonding.hasRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS),
            "TRANSFER_FAILED: SUPER_GOVERNOR_ADDRESS missing DEFAULT_ADMIN_ROLE"
        );
        require(
            bonding.hasRole(governorRole, GOVERNOR), "TRANSFER_FAILED: GOVERNOR missing GOVERNOR_ROLE"
        );
        require(
            !bonding.hasRole(defaultAdminRole, currentAdmin), "TRANSFER_FAILED: Current admin still has DEFAULT_ADMIN_ROLE"
        );

        console2.log("DEFAULT_ADMIN_ROLE -> SUPER_GOVERNOR_ADDRESS:", SUPER_GOVERNOR_ADDRESS);
        console2.log("GOVERNOR_ROLE -> GOVERNOR:", GOVERNOR);
        console2.log("Old admin revoked:", currentAdmin);
        console2.log("");
        console2.log("====== Role Transfer Complete ======");
    }

    /// @notice Check current role status
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param bondingAddr The deployed ValidatorBonding address
    /// @param deployedAdmin Admin address used during deployment
    function runCheck(uint256 env, address bondingAddr, address deployedAdmin) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== ValidatorBonding Role Check ======");
        console2.log("Environment:", env);
        console2.log("ValidatorBonding:", bondingAddr);
        console2.log("SUPER_GOVERNOR_ADDRESS:", SUPER_GOVERNOR_ADDRESS);
        console2.log("GOVERNOR:", GOVERNOR);
        console2.log("");

        if (bondingAddr.code.length == 0) {
            console2.log("Status: NOT DEPLOYED at given address");
            return;
        }

        ValidatorBonding bonding = ValidatorBonding(bondingAddr);
        bytes32 defaultAdminRole = bonding.DEFAULT_ADMIN_ROLE();
        bytes32 governorRole = bonding.GOVERNOR_ROLE();

        console2.log("=== Role Status ===");
        console2.log("Deployer has DEFAULT_ADMIN_ROLE:", bonding.hasRole(defaultAdminRole, deployedAdmin));
        console2.log("SUPER_GOVERNOR_ADDRESS has DEFAULT_ADMIN_ROLE:", bonding.hasRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS));
        console2.log("GOVERNOR has GOVERNOR_ROLE:", bonding.hasRole(governorRole, GOVERNOR));
        console2.log("");

        bool superGovernorHasAdmin = bonding.hasRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);
        bool governorHasGovernor = bonding.hasRole(governorRole, GOVERNOR);
        bool deployerHasAdmin = bonding.hasRole(defaultAdminRole, deployedAdmin);

        if (superGovernorHasAdmin && governorHasGovernor && !deployerHasAdmin) {
            console2.log("Status: ROLES FULLY TRANSFERRED");
        } else if (deployerHasAdmin) {
            console2.log("Status: ROLES NEED TRANSFER");
            console2.log("  DEFAULT_ADMIN_ROLE: deployer ->", SUPER_GOVERNOR_ADDRESS);
            if (!governorHasGovernor) {
                console2.log("  GOVERNOR_ROLE: (none) ->", GOVERNOR);
            }
        } else {
            console2.log("Status: UNEXPECTED - Neither deployer nor SUPER_GOVERNOR has admin role");
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }
}
