// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { console2 } from "forge-std/console2.sol";

/// @title TransferSuperGovernorRole
/// @notice Script to transfer SUPER_GOVERNOR_ROLE and DEFAULT_ADMIN_ROLE from deployer to production address
/// @dev This script should be run after deployment once Fireblocks is set up
/// @dev The transfer follows a 4-step process as documented in test_Role_TransferSuperGovernorRole:
///      Step 1: Grant SUPER_GOVERNOR_ROLE to new address
///      Step 2: Grant DEFAULT_ADMIN_ROLE to new address
///      Step 3: Revoke SUPER_GOVERNOR_ROLE from deployer
///      Step 4: Revoke DEFAULT_ADMIN_ROLE from deployer
contract TransferSuperGovernorRole is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer SUPER_GOVERNOR_ROLE to the production SUPER_GOVERNOR_ADDRESS
    /// @param env Environment (0 = production, 2 = staging)
    /// @param chainId Chain ID for deployment
    /// @param saltNamespace Salt namespace for deployment
    function run(uint256 env, uint64 chainId, string calldata saltNamespace) external broadcast(env) {
        _transferRole(env, chainId, saltNamespace);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _transferRole(uint256 env, uint64 chainId, string memory saltNamespace) internal {
        // Set base configuration
        _setBaseConfiguration(env, saltNamespace);

        console2.log("=== Transferring SUPER_GOVERNOR_ROLE ===");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Salt Namespace:", saltNamespace);

        // Get SuperGovernor address from deployment files
        address superGovernorAddr = _getSuperGovernorAddress(chainId, env, saltNamespace);
        if (superGovernorAddr == address(0)) {
            console2.log("ERROR: SuperGovernor not found");
            revert("SuperGovernor not found");
        }

        console2.log("SuperGovernor address:", superGovernorAddr);
        console2.log("Current holder (deployer):", DEPLOYER);
        console2.log("New holder:", SUPER_GOVERNOR_ADDRESS);

        SuperGovernor superGovernor = SuperGovernor(superGovernorAddr);
        bytes32 superGovernorRole = keccak256("SUPER_GOVERNOR_ROLE");
        bytes32 defaultAdminRole = superGovernor.DEFAULT_ADMIN_ROLE();

        // Verify initial state
        console2.log("");
        console2.log("=== Verifying Initial State ===");

        bool deployerHasSuperGovernorRole = superGovernor.hasRole(superGovernorRole, DEPLOYER);
        bool deployerHasAdminRole = superGovernor.hasRole(defaultAdminRole, DEPLOYER);
        bool newHasSuperGovernorRole = superGovernor.hasRole(superGovernorRole, SUPER_GOVERNOR_ADDRESS);
        bool newHasAdminRole = superGovernor.hasRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);

        console2.log("Deployer has SUPER_GOVERNOR_ROLE:", deployerHasSuperGovernorRole);
        console2.log("Deployer has DEFAULT_ADMIN_ROLE:", deployerHasAdminRole);
        console2.log("New address has SUPER_GOVERNOR_ROLE:", newHasSuperGovernorRole);
        console2.log("New address has DEFAULT_ADMIN_ROLE:", newHasAdminRole);

        require(deployerHasSuperGovernorRole, "Deployer must have SUPER_GOVERNOR_ROLE");
        require(deployerHasAdminRole, "Deployer must have DEFAULT_ADMIN_ROLE");

        // Execute transfer
        console2.log("");
        console2.log("=== Executing Role Transfer ===");

        // Step 1: Grant SUPER_GOVERNOR_ROLE to new address
        console2.log("[Step 1] Granting SUPER_GOVERNOR_ROLE to new address...");
        superGovernor.grantRole(superGovernorRole, SUPER_GOVERNOR_ADDRESS);
        console2.log("[Step 1] DONE - Granted SUPER_GOVERNOR_ROLE to:", SUPER_GOVERNOR_ADDRESS);

        // Step 2: Grant DEFAULT_ADMIN_ROLE to new address
        console2.log("[Step 2] Granting DEFAULT_ADMIN_ROLE to new address...");
        superGovernor.grantRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);
        console2.log("[Step 2] DONE - Granted DEFAULT_ADMIN_ROLE to:", SUPER_GOVERNOR_ADDRESS);

        // Step 3: Revoke SUPER_GOVERNOR_ROLE from deployer
        console2.log("[Step 3] Revoking SUPER_GOVERNOR_ROLE from deployer...");
        superGovernor.revokeRole(superGovernorRole, DEPLOYER);
        console2.log("[Step 3] DONE - Revoked SUPER_GOVERNOR_ROLE from:", DEPLOYER);

        // Step 4: Revoke DEFAULT_ADMIN_ROLE from deployer
        console2.log("[Step 4] Revoking DEFAULT_ADMIN_ROLE from deployer...");
        superGovernor.revokeRole(defaultAdminRole, DEPLOYER);
        console2.log("[Step 4] DONE - Revoked DEFAULT_ADMIN_ROLE from:", DEPLOYER);

        // Verify final state
        console2.log("");
        console2.log("=== Verifying Final State ===");

        deployerHasSuperGovernorRole = superGovernor.hasRole(superGovernorRole, DEPLOYER);
        deployerHasAdminRole = superGovernor.hasRole(defaultAdminRole, DEPLOYER);
        newHasSuperGovernorRole = superGovernor.hasRole(superGovernorRole, SUPER_GOVERNOR_ADDRESS);
        newHasAdminRole = superGovernor.hasRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);

        console2.log("Deployer has SUPER_GOVERNOR_ROLE:", deployerHasSuperGovernorRole);
        console2.log("Deployer has DEFAULT_ADMIN_ROLE:", deployerHasAdminRole);
        console2.log("New address has SUPER_GOVERNOR_ROLE:", newHasSuperGovernorRole);
        console2.log("New address has DEFAULT_ADMIN_ROLE:", newHasAdminRole);

        require(!deployerHasSuperGovernorRole, "Deployer should not have SUPER_GOVERNOR_ROLE");
        require(!deployerHasAdminRole, "Deployer should not have DEFAULT_ADMIN_ROLE");
        require(newHasSuperGovernorRole, "New address should have SUPER_GOVERNOR_ROLE");
        require(newHasAdminRole, "New address should have DEFAULT_ADMIN_ROLE");

        console2.log("");
        console2.log("=== Role Transfer Complete ===");
        console2.log("SUPER_GOVERNOR_ROLE successfully transferred to:", SUPER_GOVERNOR_ADDRESS);
    }

    /// @notice Get SuperGovernor address from deployment files
    function _getSuperGovernorAddress(
        uint64 chainId,
        uint256 env,
        string memory saltNamespace
    )
        internal
        view
        returns (address)
    {
        // Try to get from local contract addresses first
        address superGovernor = _getContract(chainId, "SuperGovernor");
        if (superGovernor != address(0)) {
            return superGovernor;
        }

        // Read from periphery deployment JSON files
        string memory peripheryJson = _readPeripheryContractsFromOutput(chainId, env, saltNamespace);
        if (bytes(peripheryJson).length > 0) {
            address governorAddr = _safeParseJsonAddress(peripheryJson, ".SuperGovernor");
            if (governorAddr != address(0)) {
                return governorAddr;
            }
        }

        return address(0);
    }

    /// @notice Read periphery contracts from output files
    function _readPeripheryContractsFromOutput(
        uint64 chainId,
        uint256 env,
        string memory branchName
    )
        internal
        view
        returns (string memory)
    {
        string memory peripheryRoot = vm.projectRoot();
        string memory chainName = _getChainName(chainId);

        string memory envName;
        if (env == 0) {
            envName = "prod";
        } else if (env == 1) {
            require(bytes(branchName).length > 0, "BRANCH_NAME_REQUIRED_FOR_ENV_1");
            envName = branchName;
        } else {
            envName = "staging";
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

        try vm.readFile(outputPath) returns (string memory fileContent) {
            return fileContent;
        } catch {
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
