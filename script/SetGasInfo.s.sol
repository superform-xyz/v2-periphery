// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { console2 } from "forge-std/console2.sol";

/// @title SetGasInfo
/// @notice Emergency script to set gas info for ECDSAPPSOracle on SuperGovernor
/// @dev This script should only be run on mainnet as gas info is mainnet-specific
/// @dev The script temporarily grants GAS_MANAGER_ROLE to deployer if needed, then revokes it
contract SetGasInfo is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set gas info for ECDSAPPSOracle (mainnet only)
    /// @param env Environment (0 = production, 2 = staging)
    /// @param chainId Chain ID (must be mainnet = 1)
    function run(uint256 env, uint64 chainId) external broadcast(env) {
        _setGasInfo(env, chainId);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setGasInfo(uint256 env, uint64 chainId) internal {
        // Set base configuration (salt is fixed based on env)
        _setBaseConfiguration(env, "");

        console2.log("=== Setting Gas Info for ECDSAPPSOracle ===");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);

        // Validate chain ID (mainnet only)
        require(chainId == MAINNET_CHAIN_ID, "GAS_INFO_MAINNET_ONLY");
        console2.log("Chain validation passed: mainnet");

        // Get SuperGovernor address
        address superGovernorAddr = _getSuperGovernorAddress(chainId, env);
        require(superGovernorAddr != address(0), "SUPER_GOVERNOR_NOT_FOUND");
        console2.log("SuperGovernor address:", superGovernorAddr);

        // Get ECDSAPPSOracle address
        address ecdsaPPSOracle = _getECDSAPPSOracleAddress(chainId, env);
        require(ecdsaPPSOracle != address(0), "ECDSA_PPS_ORACLE_NOT_FOUND");
        console2.log("ECDSAPPSOracle address:", ecdsaPPSOracle);

        SuperGovernor governor = SuperGovernor(superGovernorAddr);
        bytes32 gasManagerRole = governor.GAS_MANAGER_ROLE();

        // Check initial state
        console2.log("");
        console2.log("=== Initial State ===");
        bool deployerHadRole = governor.hasRole(gasManagerRole, configuration.deployer);
        console2.log("Deployer address:", configuration.deployer);
        console2.log("Deployer has GAS_MANAGER_ROLE:", deployerHadRole);

        // Grant role temporarily if needed (deployer has DEFAULT_ADMIN_ROLE)
        if (!deployerHadRole) {
            console2.log("");
            console2.log("[Step 1] Granting GAS_MANAGER_ROLE to deployer...");
            governor.grantRole(gasManagerRole, configuration.deployer);
            console2.log("[Step 1] DONE - Granted GAS_MANAGER_ROLE to deployer");
        } else {
            console2.log("");
            console2.log("[Step 1] SKIPPED - Deployer already has GAS_MANAGER_ROLE");
        }

        // Call setGasInfo
        console2.log("");
        console2.log("[Step 2] Calling setGasInfo...");
        console2.log("  ECDSAPPSOracle:", ecdsaPPSOracle);
        console2.log("  Gas per entry:", GAS_PER_ENTRY);
        governor.setGasInfo(ecdsaPPSOracle, GAS_PER_ENTRY);
        console2.log("[Step 2] DONE - setGasInfo called successfully");

        // Revoke temporary role if it was granted
        if (!deployerHadRole) {
            console2.log("");
            console2.log("[Step 3] Revoking GAS_MANAGER_ROLE from deployer...");
            governor.revokeRole(gasManagerRole, configuration.deployer);
            console2.log("[Step 3] DONE - Revoked GAS_MANAGER_ROLE from deployer");
        } else {
            console2.log("");
            console2.log("[Step 3] SKIPPED - Deployer had role before, not revoking");
        }

        // Run smoke test
        _smokeTest(governor, gasManagerRole, deployerHadRole);

        console2.log("");
        console2.log("=== Gas Info Configuration Complete ===");
    }

    /// @notice Smoke test to verify deployer does not have GAS_MANAGER_ROLE after execution
    /// @dev Only verifies role revocation if deployer didn't have the role before
    function _smokeTest(SuperGovernor governor, bytes32 gasManagerRole, bool deployerHadRoleBefore) internal view {
        console2.log("");
        console2.log("=== Running Smoke Test ===");

        bool deployerHasRoleNow = governor.hasRole(gasManagerRole, configuration.deployer);
        console2.log("Deployer has GAS_MANAGER_ROLE now:", deployerHasRoleNow);

        if (!deployerHadRoleBefore) {
            // If deployer didn't have role before, it should not have it now
            require(!deployerHasRoleNow, "SMOKE_TEST_FAILED: Deployer should not have GAS_MANAGER_ROLE");
            console2.log("PASSED: Deployer does not have GAS_MANAGER_ROLE (as expected)");
        } else {
            // If deployer had role before, we didn't revoke it
            console2.log("PASSED: Deployer role unchanged (had role before execution)");
        }

        console2.log("=== Smoke Test PASSED ===");
    }

    /// @notice Get SuperGovernor address from deployment files
    function _getSuperGovernorAddress(uint64 chainId, uint256 env) internal view returns (address) {
        // Try to get from local contract addresses first
        address superGovernor = _getContract(chainId, "SuperGovernor");
        if (superGovernor != address(0)) {
            console2.log("Found SuperGovernor from local deployment");
            return superGovernor;
        }

        // Read from periphery deployment JSON files
        string memory peripheryJson = _readPeripheryContractsFromOutput(chainId, env);
        if (bytes(peripheryJson).length > 0) {
            address governorAddr = _safeParseJsonAddress(peripheryJson, ".SuperGovernor");
            if (governorAddr != address(0)) {
                console2.log("Found SuperGovernor from deployment file");
                return governorAddr;
            }
        }

        return address(0);
    }

    /// @notice Get ECDSAPPSOracle address from deployment files
    function _getECDSAPPSOracleAddress(uint64 chainId, uint256 env) internal view returns (address) {
        // Try to get from local contract addresses first
        address oracle = _getContract(chainId, "ECDSAPPSOracle");
        if (oracle != address(0)) {
            console2.log("Found ECDSAPPSOracle from local deployment");
            return oracle;
        }

        // Read from periphery deployment JSON files
        string memory peripheryJson = _readPeripheryContractsFromOutput(chainId, env);
        if (bytes(peripheryJson).length > 0) {
            address oracleAddr = _safeParseJsonAddress(peripheryJson, ".ECDSAPPSOracle");
            if (oracleAddr != address(0)) {
                console2.log("Found ECDSAPPSOracle from deployment file");
                return oracleAddr;
            }
        }

        return address(0);
    }

    /// @notice Read periphery contracts from output files
    function _readPeripheryContractsFromOutput(uint64 chainId, uint256 env) internal view returns (string memory) {
        string memory peripheryRoot = vm.projectRoot();
        string memory chainName = _getChainName(chainId);

        // Salt is fixed based on environment (prod or staging)
        string memory envName;
        if (env == 0) {
            envName = "prod";
        } else {
            envName = "staging"; // env=2
        }

        string memory outputPath = string(
            abi.encodePacked(
                peripheryRoot,
                "/script/output/",
                envName,
                "/",
                vm.toString(uint256(chainId)),
                "/",
                chainName,
                "-latest.json"
            )
        );

        console2.log("Reading deployment file:", outputPath);

        try vm.readFile(outputPath) returns (string memory fileContent) {
            return fileContent;
        } catch {
            console2.log("Failed to read deployment file");
            return "";
        }
    }

    /// @notice Get chain name from chain ID
    function _getChainName(uint64 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum";
        if (chainId == 8453) return "Base";
        if (chainId == 10) return "Optimism";
        return "Unknown";
    }

    /// @notice Safely parse an address from JSON
    function _safeParseJsonAddress(string memory json, string memory key) internal pure returns (address) {
        try vm.parseJsonAddress(json, key) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
}
