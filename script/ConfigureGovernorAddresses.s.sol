// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { console2 } from "forge-std/console2.sol";

/// @title ConfigureGovernorAddresses
/// @notice Script to register core contract addresses in SuperGovernor
/// @dev This is a standalone script to set SUPER_VAULT_AGGREGATOR, SUPER_ORACLE, and SUPER_BANK
///      addresses in SuperGovernor when the deployment script exits early due to all contracts
///      already being deployed.
contract ConfigureGovernorAddresses is DeployV2Base {
    /// @notice Configure SuperGovernor with core contract addresses
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    /// @param chainId Chain ID for deployment
    function run(uint256 env, uint64 chainId) external broadcast(env) {
        _setBaseConfiguration(env, "");
        _configure(chainId, env);
    }

    /// @notice Configure SuperGovernor with core contract addresses (with salt namespace)
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    /// @param chainId Chain ID for deployment
    /// @param saltNamespace Salt namespace for deployment
    function run(uint256 env, uint64 chainId, string calldata saltNamespace) external broadcast(env) {
        _setBaseConfiguration(env, saltNamespace);
        _configure(chainId, env);
    }

    function _configure(uint64 chainId, uint256 env) internal {
        console2.log("=== Configuring SuperGovernor Core Addresses ===");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);

        // Read addresses from deployment JSON
        string memory peripheryJson = _readPeripheryContractsFromOutput(chainId, env);

        if (bytes(peripheryJson).length == 0) {
            console2.log("ERROR: Could not read periphery deployment file");
            revert("PERIPHERY_JSON_NOT_FOUND");
        }

        // Parse addresses from JSON
        address superGovernor = _safeParseJsonAddress(peripheryJson, ".SuperGovernor");
        address superVaultAggregator = _safeParseJsonAddress(peripheryJson, ".SuperVaultAggregator");
        address superOracle = _safeParseJsonAddress(peripheryJson, ".SuperOracle");
        address superBank = _safeParseJsonAddress(peripheryJson, ".SuperBank");
        address ecdsappsOracle = _safeParseJsonAddress(peripheryJson, ".ECDSAPPSOracle");

        console2.log("");
        console2.log("Addresses from deployment file:");
        console2.log("  SuperGovernor:", superGovernor);
        console2.log("  SuperVaultAggregator:", superVaultAggregator);
        console2.log("  SuperOracle:", superOracle);
        console2.log("  SuperBank:", superBank);
        console2.log("  ECDSAPPSOracle:", ecdsappsOracle);

        if (superGovernor == address(0)) {
            console2.log("ERROR: SuperGovernor address not found in deployment file");
            revert("SUPER_GOVERNOR_NOT_FOUND");
        }

        SuperGovernor governor = SuperGovernor(superGovernor);

        // Set SuperVaultAggregator
        if (superVaultAggregator != address(0)) {
            _setAddressIfNeeded(governor, governor.SUPER_VAULT_AGGREGATOR(), superVaultAggregator, "SUPER_VAULT_AGGREGATOR");
        } else {
            console2.log("SKIP: SuperVaultAggregator not in deployment file");
        }

        // Set SuperOracle
        if (superOracle != address(0)) {
            _setAddressIfNeeded(governor, governor.SUPER_ORACLE(), superOracle, "SUPER_ORACLE");
        } else {
            console2.log("SKIP: SuperOracle not in deployment file");
        }

        // Set SuperBank
        if (superBank != address(0)) {
            _setAddressIfNeeded(governor, governor.SUPER_BANK(), superBank, "SUPER_BANK");
        } else {
            console2.log("SKIP: SuperBank not in deployment file");
        }

        // Set Active PPS Oracle (ECDSAPPSOracle)
        if (ecdsappsOracle != address(0)) {
            _setActivePPSOracleIfNeeded(governor, ecdsappsOracle);
        } else {
            console2.log("SKIP: ECDSAPPSOracle not in deployment file");
        }

        // Set Validator Configuration
        _setValidatorConfigIfNeeded(governor);

        console2.log("");
        console2.log("=== Configuration Complete ===");
    }

    /// @notice Set validator configuration if not already set
    function _setValidatorConfigIfNeeded(SuperGovernor governor) internal {
        // Get current validator config
        (, address[] memory currentValidators,, uint256 currentQuorum) = governor.getValidatorConfig();

        console2.log("");
        console2.log("Validator Configuration:");
        console2.log("  Current validator count:", currentValidators.length);
        console2.log("  Current quorum:", currentQuorum);
        console2.log("  Expected validator count:", validators.length);
        console2.log("  Expected quorum:", INITIAL_VALIDATOR_QUORUM);

        // Check if already configured correctly
        if (currentValidators.length == validators.length && currentQuorum == INITIAL_VALIDATOR_QUORUM) {
            // Verify all validators match
            bool allMatch = true;
            for (uint256 i = 0; i < validators.length; i++) {
                if (currentValidators[i] != validators[i]) {
                    allMatch = false;
                    break;
                }
            }
            if (allMatch) {
                console2.log("SKIP: Validator configuration already set correctly");
                return;
            }
        }

        // Set validator configuration
        console2.log("SET: Validator configuration with %s validators", validators.length);
        governor.setValidatorConfig(
            INITIAL_VALIDATOR_CONFIG_VERSION,
            validators,
            validatorPublicKeys,
            INITIAL_VALIDATOR_QUORUM,
            "" // offchainConfig - empty for initial setup
        );
        console2.log("SUCCESS: Validator configuration set");
    }

    /// @notice Set the active PPS oracle if not already set
    function _setActivePPSOracleIfNeeded(SuperGovernor governor, address expected) internal {
        // Check if already set correctly
        try governor.getActivePPSOracle() returns (address current) {
            if (current == expected) {
                console2.log("SKIP: Active PPS Oracle already set correctly to %s", current);
                return;
            } else {
                // Already set to different address - requires timelock to change
                console2.log("WARNING: Active PPS Oracle already set to different address: %s", current);
                console2.log("WARNING: Use proposeActivePPSOracle + executeActivePPSOracleChange to change it");
                return;
            }
        } catch {
            // Not set yet - can set directly
            console2.log("SET: Active PPS Oracle to %s", expected);
        }

        // Set the active PPS oracle
        governor.setActivePPSOracle(expected);
        console2.log("SUCCESS: Active PPS Oracle configured");
    }

    /// @notice Set an address in SuperGovernor if not already set to the expected value
    function _setAddressIfNeeded(
        SuperGovernor governor,
        bytes32 key,
        address expected,
        string memory keyName
    ) internal {
        // Check if already set correctly
        try governor.getAddress(key) returns (address current) {
            if (current == expected) {
                console2.log("SKIP: %s already set correctly to %s", keyName, current);
                return;
            } else {
                console2.log("UPDATE: %s from %s to %s", keyName, current, expected);
            }
        } catch {
            console2.log("SET: %s to %s", keyName, expected);
        }

        // Set the address
        governor.setAddress(key, expected);
        console2.log("SUCCESS: %s configured", keyName);
    }

    /// @notice Read periphery contracts from output files
    function _readPeripheryContractsFromOutput(uint64 chainId, uint256 env) internal view returns (string memory) {
        string memory peripheryRoot = vm.projectRoot();
        string memory chainName = _getChainName(chainId);

        string memory envName;
        if (env == 0) {
            envName = "prod";
        } else if (env == 2) {
            envName = "staging";
        } else {
            envName = "test";
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

        console2.log("Reading from:", outputPath);

        try vm.readFile(outputPath) returns (string memory fileContent) {
            return fileContent;
        } catch {
            console2.log("Failed to read:", outputPath);
            return "";
        }
    }

    /// @notice Get chain name from chain ID
    function _getChainName(uint64 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum";
        if (chainId == 8453) return "Base";
        if (chainId == 999) return "HyperEVM";
        if (chainId == 14) return "Flare";
        if (chainId == 10) return "Optimism";
        if (chainId == 42161) return "Arbitrum";
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
