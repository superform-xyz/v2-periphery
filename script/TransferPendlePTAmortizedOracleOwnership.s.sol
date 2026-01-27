// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { PendlePTAmortizedOracle } from "../src/oracles/vaults/PendlePTAmortizedOracle.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title TransferPendlePTAmortizedOracleOwnership
/// @notice Script to transfer PendlePTAmortizedOracle roles from DEPLOYER to SUPER_GOVERNOR_ADDRESS
/// @dev Transfers DEFAULT_ADMIN_ROLE, MANAGER_ROLE, and KEEPER_ROLE
contract TransferPendlePTAmortizedOracleOwnership is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for PendlePTAmortizedOracle
    string internal constant ORACLE_KEY = "PendlePTAmortizedOracle";

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer all roles to SUPER_GOVERNOR_ADDRESS
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param chainId Chain ID
    function run(uint256 env, uint64 chainId) external broadcast(env) {
        _setBaseConfiguration(env, "");

        // Validate SUPER_GOVERNOR_ADDRESS is not zero to prevent bricking the oracle
        require(SUPER_GOVERNOR_ADDRESS != address(0), "SUPER_GOVERNOR_ADDRESS cannot be zero");

        console2.log("====== Transfer PendlePTAmortizedOracle Roles ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Current Admin (DEPLOYER):", DEPLOYER);
        console2.log("New Admin (SUPER_GOVERNOR_ADDRESS):", SUPER_GOVERNOR_ADDRESS);
        console2.log("");

        // Compute oracle address (deployed with DEPLOYER as admin)
        address oracleAddr = _computeAddress(env, DEPLOYER);
        require(oracleAddr.code.length > 0, "PendlePTAmortizedOracle not deployed");

        PendlePTAmortizedOracle oracle = PendlePTAmortizedOracle(oracleAddr);
        bytes32 DEFAULT_ADMIN_ROLE = oracle.DEFAULT_ADMIN_ROLE();
        bytes32 MANAGER_ROLE = oracle.MANAGER_ROLE();
        bytes32 KEEPER_ROLE = oracle.KEEPER_ROLE();

        // Check current role state
        console2.log("Oracle Address:", oracleAddr);

        bool deployerHasAdmin = oracle.hasRole(DEFAULT_ADMIN_ROLE, DEPLOYER);
        bool deployerHasManager = oracle.hasRole(MANAGER_ROLE, DEPLOYER);
        bool deployerHasKeeper = oracle.hasRole(KEEPER_ROLE, DEPLOYER);

        bool governorHasAdmin = oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS);
        bool governorHasManager = oracle.hasRole(MANAGER_ROLE, SUPER_GOVERNOR_ADDRESS);
        bool governorHasKeeper = oracle.hasRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS);

        console2.log("");
        console2.log("=== Current Role Status ===");
        console2.log("DEPLOYER has DEFAULT_ADMIN_ROLE:", deployerHasAdmin);
        console2.log("DEPLOYER has MANAGER_ROLE:", deployerHasManager);
        console2.log("DEPLOYER has KEEPER_ROLE:", deployerHasKeeper);
        console2.log("");
        console2.log("SUPER_GOVERNOR has DEFAULT_ADMIN_ROLE:", governorHasAdmin);
        console2.log("SUPER_GOVERNOR has MANAGER_ROLE:", governorHasManager);
        console2.log("SUPER_GOVERNOR has KEEPER_ROLE:", governorHasKeeper);

        // Check if transfer is fully complete (skip if so)
        bool fullyTransferred = governorHasAdmin && governorHasManager && governorHasKeeper
            && !deployerHasAdmin && !deployerHasManager && !deployerHasKeeper;

        if (fullyTransferred) {
            console2.log("");
            console2.log("=== SKIPPED: Roles Already Fully Transferred ===");
            console2.log("SUPER_GOVERNOR_ADDRESS already has all roles and DEPLOYER has none.");
            return;
        }

        // Verify we can proceed (DEPLOYER must have admin role to grant/revoke)
        require(deployerHasAdmin, "ADMIN_MISMATCH: DEPLOYER does not have DEFAULT_ADMIN_ROLE");

        // Grant roles to SUPER_GOVERNOR_ADDRESS
        console2.log("");
        console2.log("Granting roles to SUPER_GOVERNOR_ADDRESS...");

        // Grant DEFAULT_ADMIN_ROLE (admin can grant this)
        if (!governorHasAdmin) {
            oracle.grantRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS);
            console2.log("  [+] Granted DEFAULT_ADMIN_ROLE");
        } else {
            console2.log("  [=] DEFAULT_ADMIN_ROLE already granted");
        }

        // Grant MANAGER_ROLE (admin can grant this since DEFAULT_ADMIN_ROLE is the admin of MANAGER_ROLE)
        if (!governorHasManager) {
            oracle.grantRole(MANAGER_ROLE, SUPER_GOVERNOR_ADDRESS);
            console2.log("  [+] Granted MANAGER_ROLE");
        } else {
            console2.log("  [=] MANAGER_ROLE already granted");
        }

        // Grant KEEPER_ROLE (MANAGER_ROLE can grant this via addKeeper)
        if (!governorHasKeeper) {
            oracle.addKeeper(SUPER_GOVERNOR_ADDRESS);
            console2.log("  [+] Granted KEEPER_ROLE");
        } else {
            console2.log("  [=] KEEPER_ROLE already granted");
        }

        // Revoke roles from DEPLOYER
        console2.log("");
        console2.log("Revoking roles from DEPLOYER...");

        // Revoke KEEPER_ROLE first (least privileged)
        if (deployerHasKeeper) {
            oracle.removeKeeper(DEPLOYER);
            console2.log("  [-] Revoked KEEPER_ROLE");
        } else {
            console2.log("  [=] KEEPER_ROLE already revoked");
        }

        // Revoke MANAGER_ROLE
        if (deployerHasManager) {
            oracle.revokeRole(MANAGER_ROLE, DEPLOYER);
            console2.log("  [-] Revoked MANAGER_ROLE");
        } else {
            console2.log("  [=] MANAGER_ROLE already revoked");
        }

        // Revoke DEFAULT_ADMIN_ROLE last (most privileged)
        if (deployerHasAdmin) {
            oracle.revokeRole(DEFAULT_ADMIN_ROLE, DEPLOYER);
            console2.log("  [-] Revoked DEFAULT_ADMIN_ROLE");
        } else {
            console2.log("  [=] DEFAULT_ADMIN_ROLE already revoked");
        }

        // Verify transfer
        require(oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS), "TRANSFER_FAILED: New admin role mismatch");
        require(oracle.hasRole(MANAGER_ROLE, SUPER_GOVERNOR_ADDRESS), "TRANSFER_FAILED: New manager role mismatch");
        require(oracle.hasRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS), "TRANSFER_FAILED: New keeper role mismatch");
        require(!oracle.hasRole(DEFAULT_ADMIN_ROLE, DEPLOYER), "TRANSFER_FAILED: Old admin still has admin role");
        require(!oracle.hasRole(MANAGER_ROLE, DEPLOYER), "TRANSFER_FAILED: Old admin still has manager role");
        require(!oracle.hasRole(KEEPER_ROLE, DEPLOYER), "TRANSFER_FAILED: Old admin still has keeper role");

        console2.log("");
        console2.log("=== Transfer Complete ===");
        console2.log("New Admin:", SUPER_GOVERNOR_ADDRESS);
        console2.log("Has DEFAULT_ADMIN_ROLE:", oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("Has MANAGER_ROLE:", oracle.hasRole(MANAGER_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("Has KEEPER_ROLE:", oracle.hasRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("====== Role Transfer Complete ======");
    }

    /// @notice Check current role status
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param chainId Chain ID
    function runCheck(uint256 env, uint64 chainId) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== PendlePTAmortizedOracle Role Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("DEPLOYER:", DEPLOYER);
        console2.log("SUPER_GOVERNOR_ADDRESS:", SUPER_GOVERNOR_ADDRESS);
        console2.log("");

        // Compute oracle address (deployed with DEPLOYER as admin)
        address oracleAddr = _computeAddress(env, DEPLOYER);

        if (oracleAddr.code.length == 0) {
            console2.log("Oracle Address (computed):", oracleAddr);
            console2.log("Status: NOT DEPLOYED");
            return;
        }

        PendlePTAmortizedOracle oracle = PendlePTAmortizedOracle(oracleAddr);
        bytes32 DEFAULT_ADMIN_ROLE = oracle.DEFAULT_ADMIN_ROLE();
        bytes32 MANAGER_ROLE = oracle.MANAGER_ROLE();
        bytes32 KEEPER_ROLE = oracle.KEEPER_ROLE();

        console2.log("Oracle Address:", oracleAddr);
        console2.log("");
        console2.log("=== DEPLOYER Role Status ===");
        console2.log("Has DEFAULT_ADMIN_ROLE:", oracle.hasRole(DEFAULT_ADMIN_ROLE, DEPLOYER));
        console2.log("Has MANAGER_ROLE:", oracle.hasRole(MANAGER_ROLE, DEPLOYER));
        console2.log("Has KEEPER_ROLE:", oracle.hasRole(KEEPER_ROLE, DEPLOYER));
        console2.log("");
        console2.log("=== SUPER_GOVERNOR Role Status ===");
        console2.log("Has DEFAULT_ADMIN_ROLE:", oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("Has MANAGER_ROLE:", oracle.hasRole(MANAGER_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("Has KEEPER_ROLE:", oracle.hasRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("");
        console2.log("Is paused:", oracle.paused());
        console2.log("");

        // Determine status
        bool deployerHasAll = oracle.hasRole(DEFAULT_ADMIN_ROLE, DEPLOYER)
            && oracle.hasRole(MANAGER_ROLE, DEPLOYER) && oracle.hasRole(KEEPER_ROLE, DEPLOYER);

        bool governorHasAll = oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS)
            && oracle.hasRole(MANAGER_ROLE, SUPER_GOVERNOR_ADDRESS)
            && oracle.hasRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS);

        bool deployerHasNone = !oracle.hasRole(DEFAULT_ADMIN_ROLE, DEPLOYER)
            && !oracle.hasRole(MANAGER_ROLE, DEPLOYER) && !oracle.hasRole(KEEPER_ROLE, DEPLOYER);

        if (governorHasAll && deployerHasNone) {
            console2.log("Status: ROLES FULLY TRANSFERRED TO SUPER_GOVERNOR");
        } else if (deployerHasAll && !governorHasAll) {
            console2.log("Status: ROLES NEED TRANSFER");
            console2.log("  From:", DEPLOYER);
            console2.log("  To:", SUPER_GOVERNOR_ADDRESS);
        } else if (governorHasAll && !deployerHasNone) {
            console2.log("Status: PARTIAL TRANSFER - Governor has roles but Deployer still has some");
        } else {
            console2.log("Status: UNEXPECTED STATE - Check role distribution manually");
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Compute the deterministic address for PendlePTAmortizedOracle
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param admin Admin address used during deployment
    function _computeAddress(uint256 env, address admin) internal view returns (address) {
        bytes memory bytecode = __getBytecode(ORACLE_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(bytecode, abi.encode(admin)), __getSalt(ORACLE_KEY)
        );
    }
}
