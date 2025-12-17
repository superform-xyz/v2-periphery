// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { FixedPriceOracle } from "../src/oracles/FixedPriceOracle.sol";
import { console2 } from "forge-std/console2.sol";

/// @title TransferSuperGovernorRole
/// @notice Script to transfer GOVERNOR_ROLE, SUPER_GOVERNOR_ROLE, and DEFAULT_ADMIN_ROLE from deployer to production
/// @dev This script should be run after deployment once Fireblocks is set up
/// @dev The transfer follows a 7-step process:
///      Step 1: Grant GOVERNOR_ROLE to production GOVERNOR address
///      Step 2: Revoke GOVERNOR_ROLE from deployer
///      Step 3: Grant SUPER_GOVERNOR_ROLE to production SUPER_GOVERNOR_ADDRESS
///      Step 4: Grant DEFAULT_ADMIN_ROLE to production SUPER_GOVERNOR_ADDRESS
///      Step 5: Revoke SUPER_GOVERNOR_ROLE from deployer
///      Step 6: Revoke DEFAULT_ADMIN_ROLE from deployer
///      Step 7: Transfer FixedPriceOracle ownership to SuperGovernor
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

        console2.log("=== Transferring Roles ===");
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
        console2.log("New GOVERNOR:", GOVERNOR);
        console2.log("New SUPER_GOVERNOR:", SUPER_GOVERNOR_ADDRESS);

        // Check if roles are already transferred and skip if so
        if (_checkAndSkipIfAlreadyTransferred(superGovernorAddr, chainId, env, saltNamespace)) {
            return;
        }

        // Continue with transfer
        _executeRoleTransfer(superGovernorAddr, chainId, env, saltNamespace);
    }

    /// @notice Check if roles are already transferred to production addresses
    /// @return True if already transferred (should skip), false if transfer needed
    function _checkAndSkipIfAlreadyTransferred(
        address superGovernorAddr,
        uint64 chainId,
        uint256 env,
        string memory saltNamespace
    )
        internal
        returns (bool)
    {
        SuperGovernor sg = SuperGovernor(superGovernorAddr);

        console2.log("");
        console2.log("=== Verifying Current State ===");

        // Check deployer roles (should all be false if already transferred)
        bool deployerHasRoles = sg.hasRole(keccak256("GOVERNOR_ROLE"), DEPLOYER)
            || sg.hasRole(keccak256("SUPER_GOVERNOR_ROLE"), DEPLOYER) || sg.hasRole(sg.DEFAULT_ADMIN_ROLE(), DEPLOYER);

        // Check new addresses have roles (should all be true if already transferred)
        bool newAddressesHaveRoles = sg.hasRole(keccak256("GOVERNOR_ROLE"), GOVERNOR)
            && sg.hasRole(keccak256("SUPER_GOVERNOR_ROLE"), SUPER_GOVERNOR_ADDRESS)
            && sg.hasRole(sg.DEFAULT_ADMIN_ROLE(), SUPER_GOVERNOR_ADDRESS);

        console2.log("Deployer still has roles:", deployerHasRoles);
        console2.log("New addresses have roles:", newAddressesHaveRoles);

        // Already transferred if deployer has no roles and new addresses have all roles
        if (!deployerHasRoles && newAddressesHaveRoles) {
            console2.log("");
            console2.log("=== SKIPPED: Roles Already Transferred ===");
            console2.log("All roles are already correctly assigned to production addresses.");
            console2.log("No action needed for this chain.");

            // Still check FixedPriceOracle ownership
            _transferFixedPriceOracleOwnership(chainId, env, saltNamespace, superGovernorAddr);
            return true;
        }

        return false;
    }

    /// @notice Execute the actual role transfer
    function _executeRoleTransfer(
        address superGovernorAddr,
        uint64 chainId,
        uint256 env,
        string memory saltNamespace
    )
        internal
    {
        SuperGovernor superGovernor = SuperGovernor(superGovernorAddr);
        bytes32 governorRole = keccak256("GOVERNOR_ROLE");
        bytes32 superGovernorRole = keccak256("SUPER_GOVERNOR_ROLE");
        bytes32 defaultAdminRole = superGovernor.DEFAULT_ADMIN_ROLE();

        // Verify deployer has required roles
        require(superGovernor.hasRole(governorRole, DEPLOYER), "Deployer must have GOVERNOR_ROLE");
        require(superGovernor.hasRole(superGovernorRole, DEPLOYER), "Deployer must have SUPER_GOVERNOR_ROLE");
        require(superGovernor.hasRole(defaultAdminRole, DEPLOYER), "Deployer must have DEFAULT_ADMIN_ROLE");

        // Execute transfer
        console2.log("");
        console2.log("=== Executing Role Transfer ===");

        // Step 1: Grant GOVERNOR_ROLE to production GOVERNOR address
        console2.log("[Step 1] Granting GOVERNOR_ROLE to production GOVERNOR address...");
        superGovernor.grantRole(governorRole, GOVERNOR);
        console2.log("[Step 1] DONE - Granted GOVERNOR_ROLE to:", GOVERNOR);

        // Step 2: Revoke GOVERNOR_ROLE from deployer
        console2.log("[Step 2] Revoking GOVERNOR_ROLE from deployer...");
        superGovernor.revokeRole(governorRole, DEPLOYER);
        console2.log("[Step 2] DONE - Revoked GOVERNOR_ROLE from:", DEPLOYER);

        // Verify GOVERNOR_ROLE transfer
        bool deployerHasGovernorRole = superGovernor.hasRole(governorRole, DEPLOYER);
        bool newGovernorHasRole = superGovernor.hasRole(governorRole, GOVERNOR);
        console2.log("[Verify] Deployer has GOVERNOR_ROLE:", deployerHasGovernorRole);
        console2.log("[Verify] New GOVERNOR has GOVERNOR_ROLE:", newGovernorHasRole);
        require(!deployerHasGovernorRole, "Deployer should not have GOVERNOR_ROLE");
        require(newGovernorHasRole, "New GOVERNOR should have GOVERNOR_ROLE");

        // Step 3: Grant SUPER_GOVERNOR_ROLE to new address
        console2.log("[Step 3] Granting SUPER_GOVERNOR_ROLE to new address...");
        superGovernor.grantRole(superGovernorRole, SUPER_GOVERNOR_ADDRESS);
        console2.log("[Step 3] DONE - Granted SUPER_GOVERNOR_ROLE to:", SUPER_GOVERNOR_ADDRESS);

        // Step 4: Grant DEFAULT_ADMIN_ROLE to new address
        console2.log("[Step 4] Granting DEFAULT_ADMIN_ROLE to new address...");
        superGovernor.grantRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);
        console2.log("[Step 4] DONE - Granted DEFAULT_ADMIN_ROLE to:", SUPER_GOVERNOR_ADDRESS);

        // Step 5: Revoke SUPER_GOVERNOR_ROLE from deployer
        console2.log("[Step 5] Revoking SUPER_GOVERNOR_ROLE from deployer...");
        superGovernor.revokeRole(superGovernorRole, DEPLOYER);
        console2.log("[Step 5] DONE - Revoked SUPER_GOVERNOR_ROLE from:", DEPLOYER);

        // Step 6: Revoke DEFAULT_ADMIN_ROLE from deployer
        console2.log("[Step 6] Revoking DEFAULT_ADMIN_ROLE from deployer...");
        superGovernor.revokeRole(defaultAdminRole, DEPLOYER);
        console2.log("[Step 6] DONE - Revoked DEFAULT_ADMIN_ROLE from:", DEPLOYER);

        // Step 7: Transfer FixedPriceOracle ownership to SuperGovernor
        _transferFixedPriceOracleOwnership(chainId, env, saltNamespace, superGovernorAddr);

        // Verify final state
        _verifyFinalState(superGovernor, governorRole, superGovernorRole, defaultAdminRole);

        console2.log("");
        console2.log("=== Role Transfer Complete ===");
        console2.log("GOVERNOR_ROLE transferred to:", GOVERNOR);
        console2.log("SUPER_GOVERNOR_ROLE transferred to:", SUPER_GOVERNOR_ADDRESS);
    }

    /// @notice Verify final state after role transfer
    function _verifyFinalState(
        SuperGovernor superGovernor,
        bytes32 governorRole,
        bytes32 superGovernorRole,
        bytes32 defaultAdminRole
    )
        internal
        view
    {
        console2.log("");
        console2.log("=== Verifying Final State ===");

        bool deployerHasGovernorRole = superGovernor.hasRole(governorRole, DEPLOYER);
        bool deployerHasSuperGovernorRole = superGovernor.hasRole(superGovernorRole, DEPLOYER);
        bool deployerHasAdminRole = superGovernor.hasRole(defaultAdminRole, DEPLOYER);
        bool newGovernorHasRole = superGovernor.hasRole(governorRole, GOVERNOR);
        bool newHasSuperGovernorRole = superGovernor.hasRole(superGovernorRole, SUPER_GOVERNOR_ADDRESS);
        bool newHasAdminRole = superGovernor.hasRole(defaultAdminRole, SUPER_GOVERNOR_ADDRESS);

        console2.log("Deployer has GOVERNOR_ROLE:", deployerHasGovernorRole);
        console2.log("Deployer has SUPER_GOVERNOR_ROLE:", deployerHasSuperGovernorRole);
        console2.log("Deployer has DEFAULT_ADMIN_ROLE:", deployerHasAdminRole);
        console2.log("New GOVERNOR has GOVERNOR_ROLE:", newGovernorHasRole);
        console2.log("New address has SUPER_GOVERNOR_ROLE:", newHasSuperGovernorRole);
        console2.log("New address has DEFAULT_ADMIN_ROLE:", newHasAdminRole);

        require(!deployerHasGovernorRole, "Deployer should not have GOVERNOR_ROLE");
        require(!deployerHasSuperGovernorRole, "Deployer should not have SUPER_GOVERNOR_ROLE");
        require(!deployerHasAdminRole, "Deployer should not have DEFAULT_ADMIN_ROLE");
        require(newGovernorHasRole, "New GOVERNOR should have GOVERNOR_ROLE");
        require(newHasSuperGovernorRole, "New address should have SUPER_GOVERNOR_ROLE");
        require(newHasAdminRole, "New address should have DEFAULT_ADMIN_ROLE");
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

    /// @notice Transfer FixedPriceOracle ownership to SuperGovernor
    function _transferFixedPriceOracleOwnership(
        uint64 chainId,
        uint256 env,
        string memory saltNamespace,
        address superGovernorAddr
    )
        internal
    {
        console2.log("[Step 7] Transferring FixedPriceOracle ownership to SuperGovernor...");
        address fixedPriceOracleAddr = _getFixedPriceOracleAddress(chainId, env, saltNamespace);
        if (fixedPriceOracleAddr != address(0)) {
            FixedPriceOracle oracle = FixedPriceOracle(fixedPriceOracleAddr);
            address currentOwner = oracle.owner();
            console2.log("  FixedPriceOracle address:", fixedPriceOracleAddr);
            console2.log("  Current owner:", currentOwner);
            console2.log("  New owner (SuperGovernor):", superGovernorAddr);

            if (currentOwner == DEPLOYER) {
                oracle.transferOwnership(superGovernorAddr);
                console2.log("[Step 7] DONE - Transferred FixedPriceOracle ownership to SuperGovernor");

                // Verify ownership transfer
                address newOwner = oracle.owner();
                require(newOwner == superGovernorAddr, "FixedPriceOracle ownership transfer failed");
                console2.log("[Verify] FixedPriceOracle new owner:", newOwner);
            } else if (currentOwner == superGovernorAddr) {
                console2.log("[Step 7] SKIPPED - FixedPriceOracle already owned by SuperGovernor");
            } else {
                console2.log("[Step 7] WARNING - FixedPriceOracle owned by unexpected address:", currentOwner);
            }
        } else {
            console2.log("[Step 7] SKIPPED - FixedPriceOracle not found (mainnet only)");
        }
    }

    /// @notice Get FixedPriceOracle address from deployment files
    function _getFixedPriceOracleAddress(
        uint64 chainId,
        uint256 env,
        string memory saltNamespace
    )
        internal
        view
        returns (address)
    {
        // Try to get from local contract addresses first
        address oracle = _getContract(chainId, "FixedPriceOracle");
        if (oracle != address(0)) {
            return oracle;
        }

        // Read from periphery deployment JSON files
        string memory peripheryJson = _readPeripheryContractsFromOutput(chainId, env, saltNamespace);
        if (bytes(peripheryJson).length > 0) {
            address oracleAddr = _safeParseJsonAddress(peripheryJson, ".FixedPriceOracle");
            if (oracleAddr != address(0)) {
                return oracleAddr;
            }
        }

        return address(0);
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
