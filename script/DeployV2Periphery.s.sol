// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ConfigPeriphery } from "./utils/ConfigPeriphery.sol";

// Periphery contracts - only import SuperGovernor for configuration
import { SuperGovernor } from "../src/SuperGovernor.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployV2Periphery is DeployV2Base, ConfigPeriphery {
    /*//////////////////////////////////////////////////////////////
                              STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    struct PeripheryContracts {
        address superGovernor;
        address superVaultAggregator;
        address ecdsappsOracle;
        address vaultImpl;
        address strategyImpl;
        address escrowImpl;
    }

    // Core contract addresses needed for periphery deployment
    struct CoreContractAddresses {
        address superLedgerConfiguration;
        address superValidator;
        address superDestinationValidator;
        address superExecutor;
        address superDestinationExecutor;
        address superLedger;
    }

    /// @notice Sets up complete configuration for periphery contracts
    /// @param env Environment (0/2 = production, 1 = test)
    /// @param saltNamespace Salt namespace for deployment (if empty, uses production default)
    function _setConfiguration(uint256 env, string memory saltNamespace) internal {
        // Set base configuration (chain names, common addresses)
        _setBaseConfiguration(env, saltNamespace);

        // Set periphery contract dependencies
        _setPeripheryConfiguration();
    }

    function run(uint256 env, uint64 chainId) public broadcast(env) {
        _setConfiguration(env, "");
        _validateDeployer(env);
        _deployPeriphery(chainId, env);
    }

    function run(uint256 env, uint64 chainId, string memory saltNamespace) public broadcast(env) {
        _setConfiguration(env, saltNamespace);
        _validateDeployer(env);
        _deployPeriphery(chainId, env);
    }

    function run(
        uint256 env,
        uint64 chainId,
        string memory saltNamespace,
        string memory coreSalt
    )
        public
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        _deployPeripheryWithCoreSalt(chainId, env, coreSalt);
    }

    /// @notice Check V2 Periphery contract addresses before deployment
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId The target chain ID
    function runCheck(uint256 env, uint64 chainId) public broadcast(env) {
        _setConfiguration(env, "");
        console2.log("====== V2 Periphery Address Verification ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("");

        // Reset counters
        deployed = 0;
        total = 0;

        _checkPeripheryContracts(chainId, env);

        // Log comprehensive deployment summary
        _logDeploymentSummary(chainId);

        // ===== SUMMARY =====
        console2.log("");
        console2.log("=====> On this chain we have", deployed, "contracts already deployed out of", total);
        console2.log("======================================");
    }

    /// @notice Estimate deployment costs for V2 Periphery contracts
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId The target chain ID
    /// @dev This function estimates gas costs based on bytecode sizes and current gas prices
    function runEstimate(uint256 env, uint64 chainId) public broadcast(env) {
        _setConfiguration(env, "");
        console2.log("====== V2 Periphery Deployment Cost Estimation ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("");

        // Reset counters
        deployed = 0;
        total = 0;

        // First check which contracts need deployment
        _checkPeripheryContracts(chainId, env);

        // Get current gas price
        uint256 gasPrice = tx.gasprice;
        if (gasPrice == 0) {
            // Fallback to a reasonable default if gasprice is not available (simulation mode)
            gasPrice = 30 gwei;
        }

        console2.log("Current Gas Price:", gasPrice / 1 gwei, "gwei");
        console2.log("");

        // Estimate deployment costs for contracts that need deployment
        uint256 totalGasEstimate = 0;
        uint256 contractsNeedingDeployment = 0;

        console2.log("=== Contract Deployment Gas Estimates ===");

        // Check each contract and estimate gas if not deployed
        totalGasEstimate += _estimateContractGas(SUPER_GOVERNOR_KEY, chainId, env);
        totalGasEstimate += _estimateContractGas(ECDSAPPS_ORACLE_KEY, chainId, env);
        totalGasEstimate += _estimateContractGas(SUPER_VAULT_KEY, chainId, env);
        totalGasEstimate += _estimateContractGas(SUPER_VAULT_STRATEGY_KEY, chainId, env);
        totalGasEstimate += _estimateContractGas(SUPER_VAULT_ESCROW_KEY, chainId, env);
        totalGasEstimate += _estimateContractGas(SUPER_VAULT_AGGREGATOR_KEY, chainId, env);

        // Count contracts needing deployment
        contractsNeedingDeployment = total - deployed;

        console2.log("");
        console2.log("=== COST SUMMARY ===");
        console2.log("Contracts already deployed:", deployed);
        console2.log("Contracts needing deployment:", contractsNeedingDeployment);
        console2.log("Total estimated gas:", totalGasEstimate);

        uint256 totalCostWei = totalGasEstimate * gasPrice;
        uint256 totalCostGwei = totalCostWei / 1 gwei;
        uint256 totalCostEthWhole = totalCostWei / 1 ether;
        uint256 totalCostEthFraction = (totalCostWei % 1 ether) / 1e14; // 4 decimal places

        console2.log("Estimated cost (gwei):", totalCostGwei);
        console2.log("");
        console2.log("=====> ESTIMATED_NATIVE_COST_WEI:", totalCostWei);
        console2.log(string(abi.encodePacked("=====> ESTIMATED_NATIVE_COST_ETH: ", vm.toString(totalCostEthWhole), ".", vm.toString(totalCostEthFraction))));
        console2.log("=====> CONTRACTS_TO_DEPLOY:", contractsNeedingDeployment);
        console2.log("======================================");
    }

    /// @notice Estimate gas for deploying a single contract
    /// @param contractName Name of the contract
    /// @param chainId Chain ID
    /// @param env Environment
    /// @return gasEstimate Estimated gas for deployment (0 if already deployed)
    function _estimateContractGas(
        string memory contractName,
        uint64 chainId,
        uint256 env
    ) internal view returns (uint256 gasEstimate) {
        // Check if contract is already deployed
        ContractStatus memory status = contractDeploymentStatus[chainId][contractName];
        if (status.isDeployed) {
            console2.log(contractName, "- Already deployed, gas: 0");
            return 0;
        }

        // Check if bytecode exists
        if (!__checkBytecodeExists(contractName, env)) {
            console2.log(contractName, "- Bytecode not found, gas: 0");
            return 0;
        }

        // Get bytecode to estimate size-based gas
        bytes memory bytecode = __getBytecode(contractName, env);
        if (bytecode.length == 0) {
            console2.log(contractName, "- Empty bytecode, gas: 0");
            return 0;
        }

        // Gas estimation formula:
        // - Base CREATE2 cost: 32,000
        // - Per byte of init code: 200 gas (EIP-3860 initcode cost)
        // - Contract creation: ~21,000 base
        // - Storage operations during constructor: varies, estimate ~50,000 per contract
        // - Add 20% buffer for safety
        uint256 initCodeCost = bytecode.length * 200;
        uint256 baseCost = 32_000 + 21_000 + 50_000;
        gasEstimate = (baseCost + initCodeCost) * 120 / 100; // 20% buffer

        console2.log(string(abi.encodePacked(contractName, " - Bytecode size: ", vm.toString(bytecode.length), " bytes, estimated gas: ", vm.toString(gasEstimate))));

        return gasEstimate;
    }

    /// @notice Validate that msg.sender matches the expected deployer
    /// @dev Only validates in simulation mode (with --sender flag)
    /// In deploy mode with --account, Foundry handles validation automatically
    function _validateDeployer(uint256 env) internal view {
        if (env == 0 || env == 2) {
            // Only validate if msg.sender is not the default sender
            // Default sender = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
            // If we see this, we're either in deploy mode (where --account handles it)
            // or simulation mode with wrong --sender
            if (msg.sender != 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38) {
                // We have an explicit sender (from --sender flag in simulation mode)
                // Validate it matches the expected deployer
                require(
                    msg.sender == configuration.deployer,
                    string(
                        abi.encodePacked(
                            "DEPLOYER_MISMATCH: Expected ",
                            vm.toString(configuration.deployer),
                            " but got ",
                            vm.toString(msg.sender),
                            ". Ensure --sender flag matches the configured deployer address."
                        )
                    )
                );
                console2.log("Deployer validation passed:", msg.sender);
            } else {
                // Default sender - we're in deploy mode with --account
                // Foundry will handle the validation when broadcasting
                console2.log("Deploy mode: Using --account flag, validation handled by Foundry");
            }
        }
    }

    function _deployPeriphery(uint64 chainId, uint256 env) internal {
        console2.log("Deploying V2 Periphery on chainId: ", chainId);
        console2.log("Environment:", env);

        // Compute core contract addresses deterministically
        CoreContractAddresses memory coreAddresses = _computeCoreContractAddresses();

        // Validate core contracts are deployed
        _validateCoreContracts(coreAddresses);

        // Deploy periphery contracts
        PeripheryContracts memory peripheryContracts = _deployPeripheryContracts(chainId, env);

        // Configure contracts
        _configurePeripheryContracts(peripheryContracts, coreAddresses);

        // Write all exported contracts for this chain
        _writeExportedContracts(chainId);

        console2.log("All periphery contracts deployed and configured successfully.");
    }

    function _deployPeripheryWithCoreSalt(uint64 chainId, uint256 env, string memory coreSalt) internal {
        console2.log("Deploying V2 Periphery on chainId: ", chainId);
        console2.log("Environment:", env);
        console2.log("Using core salt: ", coreSalt);

        // Compute core contract addresses deterministically using the specific core salt
        CoreContractAddresses memory coreAddresses = _computeCoreContractAddressesWithSalt(coreSalt);

        // Validate core contracts are deployed
        _validateCoreContracts(coreAddresses);

        // Deploy periphery contracts
        PeripheryContracts memory peripheryContracts = _deployPeripheryContracts(chainId, env);

        // Configure contracts
        _configurePeripheryContracts(peripheryContracts, coreAddresses);

        // Write all exported contracts for this chain
        _writeExportedContracts(chainId);

        console2.log("All periphery contracts deployed and configured successfully.");
    }

    /// @notice Check periphery contract addresses (core 6 contracts only)
    /// @param env Environment (0 = prod uses locked-bytecode, 1/2 = dev/staging uses locked-bytecode-dev)
    function _checkPeripheryContracts(uint64, uint256 env) internal {
        console2.log("=== Core Periphery Contracts ===");

        // Core periphery contracts
        __checkContract(SUPER_GOVERNOR_KEY, __getSalt(SUPER_GOVERNOR_KEY), "", env);
        __checkContract(ECDSAPPS_ORACLE_KEY, __getSalt(ECDSAPPS_ORACLE_KEY), "", env);

        // Vault implementations
        __checkContract(SUPER_VAULT_KEY, __getSalt(SUPER_VAULT_KEY), "", env);
        __checkContract(SUPER_VAULT_STRATEGY_KEY, __getSalt(SUPER_VAULT_STRATEGY_KEY), "", env);
        __checkContract(SUPER_VAULT_ESCROW_KEY, __getSalt(SUPER_VAULT_ESCROW_KEY), "", env);

        // SuperVaultAggregator (depends on implementations)
        __checkContract(SUPER_VAULT_AGGREGATOR_KEY, __getSalt(SUPER_VAULT_AGGREGATOR_KEY), "", env);
    }

    /// @notice Compute core contract addresses deterministically
    /// @return coreAddresses Struct containing all core contract addresses
    function _computeCoreContractAddresses() internal view returns (CoreContractAddresses memory coreAddresses) {
        // Compute core contract addresses using same salt pattern
        coreAddresses.superLedgerConfiguration = __computeCoreContractAddress(SUPER_LEDGER_CONFIGURATION_KEY, "");
        coreAddresses.superValidator = __computeCoreContractAddress(SUPER_VALIDATOR_KEY, "");
        coreAddresses.superDestinationValidator = __computeCoreContractAddress(SUPER_DESTINATION_VALIDATOR_KEY, "");

        // SuperExecutor requires SuperLedgerConfiguration
        coreAddresses.superExecutor =
            __computeCoreContractAddress(SUPER_EXECUTOR_KEY, abi.encode(coreAddresses.superLedgerConfiguration));

        // SuperDestinationExecutor requires SuperLedgerConfiguration and SuperDestinationValidator
        coreAddresses.superDestinationExecutor = __computeCoreContractAddress(
            SUPER_DESTINATION_EXECUTOR_KEY,
            abi.encode(coreAddresses.superLedgerConfiguration, coreAddresses.superDestinationValidator)
        );

        // SuperLedger requires SuperLedgerConfiguration and allowedExecutors
        address[] memory allowedExecutors = new address[](2);
        allowedExecutors[0] = coreAddresses.superExecutor;
        allowedExecutors[1] = coreAddresses.superDestinationExecutor;
        coreAddresses.superLedger = __computeCoreContractAddress(
            SUPER_LEDGER_KEY, abi.encode(coreAddresses.superLedgerConfiguration, allowedExecutors)
        );
    }

    /// @notice Compute core contract addresses deterministically with a specific core salt
    /// @param coreSalt The salt used for core contract deployment
    /// @return coreAddresses Struct containing all core contract addresses
    function _computeCoreContractAddressesWithSalt(string memory coreSalt)
        internal
        view
        returns (CoreContractAddresses memory coreAddresses)
    {
        // Compute core contract addresses using the specific core salt
        coreAddresses.superLedgerConfiguration =
            __computeCoreContractAddressWithSalt(SUPER_LEDGER_CONFIGURATION_KEY, "", coreSalt);
        coreAddresses.superValidator = __computeCoreContractAddressWithSalt(SUPER_VALIDATOR_KEY, "", coreSalt);
        coreAddresses.superDestinationValidator =
            __computeCoreContractAddressWithSalt(SUPER_DESTINATION_VALIDATOR_KEY, "", coreSalt);

        // SuperExecutor requires SuperLedgerConfiguration
        coreAddresses.superExecutor = __computeCoreContractAddressWithSalt(
            SUPER_EXECUTOR_KEY, abi.encode(coreAddresses.superLedgerConfiguration), coreSalt
        );

        // SuperDestinationExecutor requires SuperLedgerConfiguration and SuperDestinationValidator
        coreAddresses.superDestinationExecutor = __computeCoreContractAddressWithSalt(
            SUPER_DESTINATION_EXECUTOR_KEY,
            abi.encode(coreAddresses.superLedgerConfiguration, coreAddresses.superDestinationValidator),
            coreSalt
        );

        // SuperLedger requires SuperLedgerConfiguration and allowedExecutors
        address[] memory allowedExecutors = new address[](2);
        allowedExecutors[0] = coreAddresses.superExecutor;
        allowedExecutors[1] = coreAddresses.superDestinationExecutor;
        coreAddresses.superLedger = __computeCoreContractAddressWithSalt(
            SUPER_LEDGER_KEY, abi.encode(coreAddresses.superLedgerConfiguration, allowedExecutors), coreSalt
        );
    }

    /// @notice Validate that core contracts are deployed
    /// @param coreAddresses Core contract addresses to validate
    function _validateCoreContracts(CoreContractAddresses memory coreAddresses) internal view {
        require(coreAddresses.superLedgerConfiguration.code.length > 0, "SuperLedgerConfiguration not deployed");
        require(coreAddresses.superValidator.code.length > 0, "SuperValidator not deployed");
        require(coreAddresses.superDestinationValidator.code.length > 0, "SuperDestinationValidator not deployed");
        require(coreAddresses.superExecutor.code.length > 0, "SuperExecutor not deployed");
        require(coreAddresses.superDestinationExecutor.code.length > 0, "SuperDestinationExecutor not deployed");
        require(coreAddresses.superLedger.code.length > 0, "SuperLedger not deployed");

        console2.log("All core contracts validated successfully");
        console2.log("  SuperLedgerConfiguration:", coreAddresses.superLedgerConfiguration);
        console2.log("  SuperValidator:", coreAddresses.superValidator);
        console2.log("  SuperDestinationValidator:", coreAddresses.superDestinationValidator);
        console2.log("  SuperExecutor:", coreAddresses.superExecutor);
        console2.log("  SuperDestinationExecutor:", coreAddresses.superDestinationExecutor);
        console2.log("  SuperLedger:", coreAddresses.superLedger);
    }

    function _deployPeripheryContracts(
        uint64 chainId,
        uint256 env
    )
        internal
        returns (PeripheryContracts memory peripheryContracts)
    {
        console2.log("Starting comprehensive periphery contract deployment with full validation...");
        console2.log("Environment:", env);

        // ===== VALIDATION PHASE =====
        require(configuration.treasury != address(0), "TREASURY_ADDRESS_ZERO");
        require(configuration.owner != address(0), "OWNER_ADDRESS_ZERO");
        require(configuration.governor != address(0), "GOVERNOR_ADDRESS_ZERO");
        require(configuration.bankManager != address(0), "BANK_MANAGER_ADDRESS_ZERO");
        require(configuration.oracleManager != address(0), "ORACLE_MANAGER_ADDRESS_ZERO");
        require(configuration.gasManager != address(0), "GAS_MANAGER_ADDRESS_ZERO");
        require(configuration.guardian != address(0), "GUARDIAN_ADDRESS_ZERO");
        require(validators.length > 0, "NO_VALIDATORS_CONFIGURED");

        console2.log("All periphery dependencies validated successfully");

        // Deploy SuperGovernor
        peripheryContracts.superGovernor = __deployContractIfNeeded(
            SUPER_GOVERNOR_KEY,
            chainId,
            __getSalt(SUPER_GOVERNOR_KEY),
            abi.encodePacked(
                __getBytecode(SUPER_GOVERNOR_KEY, env),
                abi.encode(
                    configuration.owner,
                    configuration.governor,
                    configuration.bankManager,
                    configuration.oracleManager,
                    configuration.gasManager,
                    configuration.guardian,
                    configuration.treasury
                )
            )
        );

        // Deploy SuperVault implementations first
        peripheryContracts.vaultImpl = __deployContractIfNeeded(
            SUPER_VAULT_KEY,
            chainId,
            __getSalt(SUPER_VAULT_KEY),
            abi.encodePacked(
                __getBytecode(SUPER_VAULT_KEY, env),
                abi.encode(peripheryContracts.superGovernor)
            )
        );

        peripheryContracts.strategyImpl = __deployContractIfNeeded(
            SUPER_VAULT_STRATEGY_KEY,
            chainId,
            __getSalt(SUPER_VAULT_STRATEGY_KEY),
            abi.encodePacked(
                __getBytecode(SUPER_VAULT_STRATEGY_KEY, env),
                abi.encode(peripheryContracts.superGovernor)
            )
        );

        peripheryContracts.escrowImpl = __deployContractIfNeeded(
            SUPER_VAULT_ESCROW_KEY,
            chainId,
            __getSalt(SUPER_VAULT_ESCROW_KEY),
            __getBytecode(SUPER_VAULT_ESCROW_KEY, env)
        );

        // Deploy SuperVaultAggregator (takes all four addresses)
        peripheryContracts.superVaultAggregator = __deployContractIfNeeded(
            SUPER_VAULT_AGGREGATOR_KEY,
            chainId,
            __getSalt(SUPER_VAULT_AGGREGATOR_KEY),
            abi.encodePacked(
                __getBytecode(SUPER_VAULT_AGGREGATOR_KEY, env),
                abi.encode(
                    peripheryContracts.superGovernor,
                    peripheryContracts.vaultImpl,
                    peripheryContracts.strategyImpl,
                    peripheryContracts.escrowImpl
                )
            )
        );

        // Deploy ECDSAPPSOracle
        peripheryContracts.ecdsappsOracle = __deployContractIfNeeded(
            ECDSAPPS_ORACLE_KEY,
            chainId,
            __getSalt(ECDSAPPS_ORACLE_KEY),
            abi.encodePacked(
                __getBytecode(ECDSAPPS_ORACLE_KEY, env),
                abi.encode(peripheryContracts.superGovernor, ECDSAPPS_ORACLE_KEY, ECDSAPPS_ORACLE_VERSION)
            )
        );

        console2.log("All periphery contracts deployment completed successfully with full validation");

        return peripheryContracts;
    }

    function _configurePeripheryContracts(
        PeripheryContracts memory peripheryContracts,
        CoreContractAddresses memory
    )
        internal
    {
        console2.log("Configuring core periphery contracts...");
        console2.log("msg.sender:", msg.sender);
        console2.log("SuperGovernor address:", peripheryContracts.superGovernor);

        // NOTE: SUPER_GOVERNOR_ROLE and GOVERNOR_ROLE are already granted to the deployer
        // in the SuperGovernor constructor via configuration.owner and configuration.governor

        console2.log("[Step 1] Setting active PPS oracle...");
        console2.log("  Oracle address:", peripheryContracts.ecdsappsOracle);
        // Configure SuperGovernor with oracle
        SuperGovernor(peripheryContracts.superGovernor).setActivePPSOracle(peripheryContracts.ecdsappsOracle);
        console2.log("[Step 1] DONE - Set active PPS oracle");

        console2.log("[Step 2] Setting validator configuration...");
        SuperGovernor(peripheryContracts.superGovernor).setValidatorConfig(
            INITIAL_VALIDATOR_CONFIG_VERSION,
            validators,
            validatorPublicKeys,
            INITIAL_VALIDATOR_QUORUM,
            "" // offchainConfig - empty for initial setup
        );
        console2.log(
            "[Step 2] DONE - Set validator configuration with",
            validators.length,
            "validators and quorum of",
            INITIAL_VALIDATOR_QUORUM
        );

        console2.log("[Step 3] Setting SuperVaultAggregator address...");
        console2.log("  Aggregator address:", peripheryContracts.superVaultAggregator);
        // Configure SuperGovernor with aggregator
        SuperGovernor(peripheryContracts.superGovernor)
            .setAddress(
                SuperGovernor(peripheryContracts.superGovernor).SUPER_VAULT_AGGREGATOR(),
                peripheryContracts.superVaultAggregator
            );
        console2.log("[Step 3] DONE - Set SuperVaultAggregator address");

        console2.log("[Step 4] Checking if need to configure governor roles...");
        console2.log("  configuration.owner:", configuration.owner);
        console2.log("  TEST_DEPLOYER:", TEST_DEPLOYER);
        // Grant roles and revoke from deployer for production
        if (configuration.owner != TEST_DEPLOYER) {
            console2.log("[Step 4] Configuring governor roles...");
            _configureGovernorRoles(SuperGovernor(peripheryContracts.superGovernor));
            console2.log("[Step 4] DONE - Configured governor roles");
        } else {
            console2.log("[Step 4] SKIPPED - Test environment, not configuring governor roles");
        }

        console2.log("All core periphery contracts configured successfully");
    }

    function _configureGovernorRoles(SuperGovernor superGovernor) internal {
        // Grant SUPER_GOVERNOR_ROLE to the validator address and revoke from TEST_DEPLOYER
        superGovernor.grantRole(keccak256("SUPER_GOVERNOR_ROLE"), 0xd95f4bc7733d9E94978244C0a27c1815878a59BB);
        console2.log("Granted SUPER_GOVERNOR_ROLE to: 0xd95f4bc7733d9E94978244C0a27c1815878a59BB");

        superGovernor.revokeRole(keccak256("SUPER_GOVERNOR_ROLE"), TEST_DEPLOYER);
        console2.log("Revoked SUPER_GOVERNOR_ROLE from TEST_DEPLOYER");
    }
}
