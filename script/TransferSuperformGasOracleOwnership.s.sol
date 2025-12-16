// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperformGasOracle } from "../src/oracles/SuperformGasOracle.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title TransferSuperformGasOracleOwnership
/// @notice Script to transfer SuperformGasOracle admin role to SUPER_GOVERNOR_ADDRESS
contract TransferSuperformGasOracleOwnership is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for SuperformGasOracle
    string internal constant SUPERFORM_GAS_ORACLE_KEY = "SuperformGasOracle";

    /// @notice Default initial gas price (must match deployment)
    int256 internal constant DEFAULT_INITIAL_GAS_PRICE = 1_000_000;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer admin role to SUPER_GOVERNOR_ADDRESS
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param chainId Chain ID
    /// @param currentAdmin Current admin address (must match deployed oracle's admin)
    function run(uint256 env, uint64 chainId, address currentAdmin) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== Transfer SuperformGasOracle Admin Role ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Current Admin:", currentAdmin);
        console2.log("New Admin (SUPER_GOVERNOR_ADDRESS):", SUPER_GOVERNOR_ADDRESS);
        console2.log("");

        // Compute oracle address
        address oracleAddr = _computeAddress(DEFAULT_INITIAL_GAS_PRICE, currentAdmin);
        require(oracleAddr.code.length > 0, "SuperformGasOracle not deployed");

        SuperformGasOracle oracle = SuperformGasOracle(oracleAddr);
        bytes32 DEFAULT_ADMIN_ROLE = oracle.DEFAULT_ADMIN_ROLE();
        bytes32 KEEPER_ROLE = oracle.KEEPER_ROLE();

        // Verify current admin has admin role
        console2.log("Oracle Address:", oracleAddr);
        console2.log("Current admin has DEFAULT_ADMIN_ROLE:", oracle.hasRole(DEFAULT_ADMIN_ROLE, currentAdmin));

        require(oracle.hasRole(DEFAULT_ADMIN_ROLE, currentAdmin), "ADMIN_MISMATCH: Current admin does not have role");
        require(
            !oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS),
            "ALREADY_TRANSFERRED: SUPER_GOVERNOR already has admin role"
        );

        // Transfer roles to SUPER_GOVERNOR_ADDRESS
        console2.log("");
        console2.log("Granting roles to SUPER_GOVERNOR_ADDRESS...");

        // Grant admin role to new admin
        oracle.grantRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS);
        console2.log("  [+] Granted DEFAULT_ADMIN_ROLE");

        // Grant keeper role to new admin
        oracle.grantRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS);
        console2.log("  [+] Granted KEEPER_ROLE");

        // Revoke roles from current admin
        console2.log("");
        console2.log("Revoking roles from current admin...");

        oracle.revokeRole(KEEPER_ROLE, currentAdmin);
        console2.log("  [-] Revoked KEEPER_ROLE");

        oracle.revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        console2.log("  [-] Revoked DEFAULT_ADMIN_ROLE");

        // Verify transfer
        require(oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS), "TRANSFER_FAILED: New admin role mismatch");
        require(!oracle.hasRole(DEFAULT_ADMIN_ROLE, currentAdmin), "TRANSFER_FAILED: Old admin still has role");

        console2.log("");
        console2.log("=== Transfer Complete ===");
        console2.log("New Admin:", SUPER_GOVERNOR_ADDRESS);
        console2.log("Has DEFAULT_ADMIN_ROLE:", oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("Has KEEPER_ROLE:", oracle.hasRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("====== Admin Role Transfer Complete ======");
    }

    /// @notice Check current role status
    /// @param env Environment (0 = prod, 2 = staging)
    /// @param chainId Chain ID
    /// @param deployedAdmin Admin address used during deployment
    function runCheck(uint256 env, uint64 chainId, address deployedAdmin) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== SuperformGasOracle Role Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("SUPER_GOVERNOR_ADDRESS:", SUPER_GOVERNOR_ADDRESS);
        console2.log("");

        // Compute oracle address
        address oracleAddr = _computeAddress(DEFAULT_INITIAL_GAS_PRICE, deployedAdmin);

        if (oracleAddr.code.length == 0) {
            console2.log("Oracle Address (computed):", oracleAddr);
            console2.log("Status: NOT DEPLOYED");
            return;
        }

        SuperformGasOracle oracle = SuperformGasOracle(oracleAddr);
        bytes32 DEFAULT_ADMIN_ROLE = oracle.DEFAULT_ADMIN_ROLE();
        bytes32 KEEPER_ROLE = oracle.KEEPER_ROLE();

        console2.log("Oracle Address:", oracleAddr);
        console2.log("");
        console2.log("=== Role Status ===");
        console2.log("Deployer has DEFAULT_ADMIN_ROLE:", oracle.hasRole(DEFAULT_ADMIN_ROLE, deployedAdmin));
        console2.log("Deployer has KEEPER_ROLE:", oracle.hasRole(KEEPER_ROLE, deployedAdmin));
        console2.log("SUPER_GOVERNOR has DEFAULT_ADMIN_ROLE:", oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("SUPER_GOVERNOR has KEEPER_ROLE:", oracle.hasRole(KEEPER_ROLE, SUPER_GOVERNOR_ADDRESS));
        console2.log("");

        if (oracle.hasRole(DEFAULT_ADMIN_ROLE, SUPER_GOVERNOR_ADDRESS)) {
            console2.log("Status: ROLES ALREADY TRANSFERRED");
        } else if (oracle.hasRole(DEFAULT_ADMIN_ROLE, deployedAdmin)) {
            console2.log("Status: ROLES NEED TRANSFER");
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

    /// @notice Compute the deterministic address for SuperformGasOracle
    function _computeAddress(int256 initialGasPrice, address admin) internal returns (address) {
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(type(SuperformGasOracle).creationCode, abi.encode(initialGasPrice, admin)),
            __getSalt(SUPERFORM_GAS_ORACLE_KEY)
        );
    }
}
