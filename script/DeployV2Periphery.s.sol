// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ConfigPeriphery } from "./utils/ConfigPeriphery.sol";

// Periphery contracts
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { SuperBank } from "../src/SuperBank.sol";
import { FixedPriceOracle } from "../src/oracles/FixedPriceOracle.sol";
import { SuperOracle } from "../src/oracles/SuperOracle.sol";
import { SuperOracleL2 } from "../src/oracles/SuperOracleL2.sol";
import { AggregatorV3Interface } from "../src/vendor/chainlink/AggregatorV3Interface.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployV2Periphery is DeployV2Base, ConfigPeriphery {
    /*//////////////////////////////////////////////////////////////
                              STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    struct PeripheryContracts {
        address superGovernor;
        address superOracle;
        address superBank;
        address superVaultAggregator;
        address ecdsappsOracle;
        address fixedPriceOracle;
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
        totalGasEstimate += _estimateContractGas(FIXED_PRICE_ORACLE_KEY, chainId, env);
        // SuperOracle (mainnet) or SuperOracleL2 (L2 chains)
        if (chainId == MAINNET_CHAIN_ID) {
            totalGasEstimate += _estimateContractGas(SUPER_ORACLE_KEY, chainId, env);
        } else {
            totalGasEstimate += _estimateContractGas(SUPER_ORACLE_L2_KEY, chainId, env);
        }
        totalGasEstimate += _estimateContractGas(SUPER_BANK_KEY, chainId, env);
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

        // Run smoke test to verify deployment
        _smokeTest(peripheryContracts, chainId);

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

        // Run smoke test to verify deployment
        _smokeTest(peripheryContracts, chainId);

        // Write all exported contracts for this chain
        _writeExportedContracts(chainId);

        console2.log("All periphery contracts deployed and configured successfully.");
    }

    /// @notice Check periphery contract addresses (core contracts)
    /// @param chainId Chain ID for chain-specific contracts
    /// @param env Environment (0 = prod uses locked-bytecode, 1/2 = dev/staging uses locked-bytecode-dev)
    function _checkPeripheryContracts(uint64 chainId, uint256 env) internal {
        console2.log("=== Core Periphery Contracts ===");

        // Core periphery contracts
        __checkContract(SUPER_GOVERNOR_KEY, __getSalt(SUPER_GOVERNOR_KEY), "", env);
        __checkContract(ECDSAPPS_ORACLE_KEY, __getSalt(ECDSAPPS_ORACLE_KEY), "", env);
        __checkContract(FIXED_PRICE_ORACLE_KEY, __getSalt(FIXED_PRICE_ORACLE_KEY), "", env);

        // SuperOracle (mainnet) or SuperOracleL2 (L2 chains)
        if (chainId == MAINNET_CHAIN_ID) {
            __checkContract(SUPER_ORACLE_KEY, __getSalt(SUPER_ORACLE_KEY), "", env);
        } else {
            __checkContract(SUPER_ORACLE_L2_KEY, __getSalt(SUPER_ORACLE_L2_KEY), "", env);
        }

        // SuperBank
        __checkContract(SUPER_BANK_KEY, __getSalt(SUPER_BANK_KEY), "", env);

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

        // Deploy FixedPriceOracle (UP/USD temporary oracle)
        // Owner is set to deployer who can update the price
        peripheryContracts.fixedPriceOracle = __deployContractIfNeeded(
            FIXED_PRICE_ORACLE_KEY,
            chainId,
            __getSalt(FIXED_PRICE_ORACLE_KEY),
            abi.encodePacked(
                type(FixedPriceOracle).creationCode,
                abi.encode(INITIAL_UP_PRICE, UP_PRICE_DECIMALS, configuration.deployer)
            )
        );

        // Deploy SuperOracle (mainnet) or SuperOracleL2 (L2 chains)
        // Mainnet: GAS->WEI, ETH->USD, UP->USD
        // L2: ETH->USD only (gas oracle and UP oracle not available)
        peripheryContracts.superOracle = _deploySuperOracle(
            chainId,
            peripheryContracts.superGovernor,
            peripheryContracts.fixedPriceOracle
        );

        // Deploy SuperBank
        peripheryContracts.superBank = __deployContractIfNeeded(
            SUPER_BANK_KEY,
            chainId,
            __getSalt(SUPER_BANK_KEY),
            abi.encodePacked(
                type(SuperBank).creationCode,
                abi.encode(peripheryContracts.superGovernor)
            )
        );

        console2.log("All periphery contracts deployment completed successfully with full validation");

        return peripheryContracts;
    }

    /// @notice Deploy SuperOracle (mainnet) or SuperOracleL2 (L2 chains) with initial oracle feeds
    /// @param chainId The chain ID to deploy on
    /// @param superGovernor The SuperGovernor address
    /// @param fixedPriceOracle The FixedPriceOracle address for UP/USD pricing
    /// @return superOracle The deployed SuperOracle address
    function _deploySuperOracle(
        uint64 chainId,
        address superGovernor,
        address fixedPriceOracle
    )
        internal
        returns (address superOracle)
    {
        // Configure initial oracle feeds
        // Mainnet: 3 feeds (GAS->WEI, ETH->USD, UP->USD)
        // L2 chains: 1 feed (ETH->USD only) - gas oracle and UP oracle only available on mainnet

        address[] memory bases;
        address[] memory quotes;
        bytes32[] memory providers;
        address[] memory feeds;

        if (chainId == MAINNET_CHAIN_ID) {
            // Mainnet: include GAS->WEI, ETH->USD, and UP->USD oracles
            bases = new address[](3);
            quotes = new address[](3);
            providers = new bytes32[](3);
            feeds = new address[](3);

            // Feed 1: GAS -> WEI (gas price oracle) - mainnet only
            bases[0] = GAS_QUOTE;
            quotes[0] = WEI_QUOTE;
            providers[0] = PROVIDER_CHAINLINK;
            feeds[0] = ORACLE_GAS_TO_ETH;

            // Feed 2: ETH -> USD
            bases[1] = NATIVE_TOKEN;
            quotes[1] = USD_TOKEN;
            providers[1] = PROVIDER_CHAINLINK;
            feeds[1] = ORACLE_ETH_USD_MAINNET;

            // Feed 3: UP -> USD (using FixedPriceOracle)
            bases[2] = UP_TOKEN;
            quotes[2] = USD_TOKEN;
            providers[2] = PROVIDER_SUPERFORM;
            feeds[2] = fixedPriceOracle;

            superOracle = __deployContractIfNeeded(
                SUPER_ORACLE_KEY,
                chainId,
                __getSalt(SUPER_ORACLE_KEY),
                abi.encodePacked(
                    type(SuperOracle).creationCode,
                    abi.encode(superGovernor, bases, quotes, providers, feeds)
                )
            );

            console2.log("SuperOracle deployed at:", superOracle);
            console2.log("  Chain ID:", chainId);
            console2.log("  Configured oracles: GAS->WEI, ETH->USD, UP->USD");
        } else {
            // L2 chains: only ETH->USD oracle (no gas oracle or UP oracle available)
            bases = new address[](1);
            quotes = new address[](1);
            providers = new bytes32[](1);
            feeds = new address[](1);

            // Feed 1: ETH -> USD
            bases[0] = NATIVE_TOKEN;
            quotes[0] = USD_TOKEN;
            providers[0] = PROVIDER_CHAINLINK;

            if (chainId == BASE_CHAIN_ID) {
                feeds[0] = ORACLE_ETH_USD_BASE;
            } else {
                revert("ORACLE_ETH_USD not configured for this chain");
            }

            superOracle = __deployContractIfNeeded(
                SUPER_ORACLE_L2_KEY,
                chainId,
                __getSalt(SUPER_ORACLE_L2_KEY),
                abi.encodePacked(
                    type(SuperOracleL2).creationCode,
                    abi.encode(superGovernor, bases, quotes, providers, feeds)
                )
            );

            console2.log("SuperOracleL2 deployed at:", superOracle);
            console2.log("  Chain ID:", chainId);
            console2.log("  Configured oracles: ETH->USD");
            console2.log("  WARNING: GAS->WEI oracle not configured (mainnet only)");
            console2.log("  WARNING: UP->USD oracle not configured (mainnet only)");
        }

        return superOracle;
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

        console2.log("[Step 4] Setting SuperOracle address...");
        console2.log("  Oracle address:", peripheryContracts.superOracle);
        SuperGovernor(peripheryContracts.superGovernor)
            .setAddress(
                SuperGovernor(peripheryContracts.superGovernor).SUPER_ORACLE(),
                peripheryContracts.superOracle
            );
        console2.log("[Step 4] DONE - Set SuperOracle address");

        console2.log("[Step 5] Setting SuperBank address...");
        console2.log("  Bank address:", peripheryContracts.superBank);
        SuperGovernor(peripheryContracts.superGovernor)
            .setAddress(
                SuperGovernor(peripheryContracts.superGovernor).SUPER_BANK(),
                peripheryContracts.superBank
            );
        console2.log("[Step 5] DONE - Set SuperBank address");

        // NOTE: Governor roles are granted to the deployer initially via configuration.governor
        // in the SuperGovernor constructor. Transfer to the actual GOVERNOR address should happen
        // later via TransferSuperGovernorRole script after Fireblocks is set up.

        console2.log("All core periphery contracts configured successfully");
    }

    /// @notice Smoke test to verify roles and configuration are set correctly post-deployment
    /// @param peripheryContracts The deployed periphery contract addresses
    /// @param chainId The chain ID for chain-specific oracle selection
    function _smokeTest(PeripheryContracts memory peripheryContracts, uint64 chainId) internal view {
        console2.log("");
        console2.log("=== Running Smoke Test ===");

        SuperGovernor governor = SuperGovernor(peripheryContracts.superGovernor);
        bytes32 superGovernorRole = keccak256("SUPER_GOVERNOR_ROLE");
        bytes32 defaultAdminRole = governor.DEFAULT_ADMIN_ROLE();

        // Verify SUPER_GOVERNOR_ROLE is held by deployer
        bool deployerHasSuperGovernorRole = governor.hasRole(superGovernorRole, DEPLOYER);
        bool deployerHasDefaultAdminRole = governor.hasRole(defaultAdminRole, DEPLOYER);

        console2.log("[Role Check] DEPLOYER has SUPER_GOVERNOR_ROLE:", deployerHasSuperGovernorRole);
        console2.log("[Role Check] DEPLOYER has DEFAULT_ADMIN_ROLE:", deployerHasDefaultAdminRole);

        require(deployerHasSuperGovernorRole, "SMOKE_TEST_FAILED: Deployer missing SUPER_GOVERNOR_ROLE");
        require(deployerHasDefaultAdminRole, "SMOKE_TEST_FAILED: Deployer missing DEFAULT_ADMIN_ROLE");

        // Verify active PPS oracle is set
        address activePPSOracle = governor.getActivePPSOracle();
        console2.log("[Config Check] Active PPS Oracle:", activePPSOracle);
        require(activePPSOracle == peripheryContracts.ecdsappsOracle, "SMOKE_TEST_FAILED: PPS Oracle mismatch");

        // Verify FixedPriceOracle is deployed and configured correctly
        console2.log("[Config Check] FixedPriceOracle:", peripheryContracts.fixedPriceOracle);
        require(peripheryContracts.fixedPriceOracle != address(0), "SMOKE_TEST_FAILED: FixedPriceOracle not deployed");
        FixedPriceOracle fixedOracle = FixedPriceOracle(peripheryContracts.fixedPriceOracle);
        require(fixedOracle.owner() == DEPLOYER, "SMOKE_TEST_FAILED: FixedPriceOracle owner mismatch");
        require(fixedOracle.decimals() == UP_PRICE_DECIMALS, "SMOKE_TEST_FAILED: FixedPriceOracle decimals mismatch");
        (, int256 price,,,) = fixedOracle.latestRoundData();
        require(price == INITIAL_UP_PRICE, "SMOKE_TEST_FAILED: FixedPriceOracle price mismatch");

        // Verify SuperVaultAggregator is set
        address aggregator = governor.getAddress(governor.SUPER_VAULT_AGGREGATOR());
        console2.log("[Config Check] SuperVaultAggregator:", aggregator);
        require(
            aggregator == peripheryContracts.superVaultAggregator, "SMOKE_TEST_FAILED: Aggregator mismatch"
        );

        // Verify SuperOracle is set
        address superOracle = governor.getAddress(governor.SUPER_ORACLE());
        console2.log("[Config Check] SuperOracle:", superOracle);
        require(superOracle == peripheryContracts.superOracle, "SMOKE_TEST_FAILED: SuperOracle mismatch");
        require(superOracle != address(0), "SMOKE_TEST_FAILED: SuperOracle not set");

        // Verify SuperBank is set
        address superBank = governor.getAddress(governor.SUPER_BANK());
        console2.log("[Config Check] SuperBank:", superBank);
        require(superBank == peripheryContracts.superBank, "SMOKE_TEST_FAILED: SuperBank mismatch");
        require(superBank != address(0), "SMOKE_TEST_FAILED: SuperBank not set");

        // Verify validator configuration
        (, address[] memory validatorAddrs,, uint256 quorum) = governor.getValidatorConfig();
        console2.log("[Config Check] Validator count:", validatorAddrs.length);
        console2.log("[Config Check] Quorum:", quorum);
        require(validatorAddrs.length > 0, "SMOKE_TEST_FAILED: No validators configured");
        require(quorum == INITIAL_VALIDATOR_QUORUM, "SMOKE_TEST_FAILED: Quorum mismatch");

        // Verify oracle feeds return valid prices and recent timestamps
        _verifyOracleFeeds(peripheryContracts.fixedPriceOracle, chainId);

        console2.log("=== Smoke Test PASSED ===");
        console2.log("");
    }

    /// @notice Verify oracle feeds return valid prices and timestamps within 2 days
    /// @param fixedPriceOracleAddr The FixedPriceOracle address
    /// @param chainId The chain ID for chain-specific oracle selection
    function _verifyOracleFeeds(address fixedPriceOracleAddr, uint64 chainId) internal view {
        console2.log("");
        console2.log("=== Verifying Oracle Feeds ===");

        uint256 maxStaleness = 2 days;

        // 1. Verify FixedPriceOracle (UP/USD)
        console2.log("[Oracle 1] FixedPriceOracle (UP/USD):");
        {
            (, int256 upPrice,, uint256 upUpdatedAt,) = FixedPriceOracle(fixedPriceOracleAddr).latestRoundData();
            console2.log("  Price:", uint256(upPrice));
            console2.log("  Updated at:", upUpdatedAt);
            console2.log("  Current time:", block.timestamp);

            require(upPrice > 0, "SMOKE_TEST_FAILED: FixedPriceOracle price is zero");
            require(
                block.timestamp - upUpdatedAt <= maxStaleness,
                "SMOKE_TEST_FAILED: FixedPriceOracle timestamp too stale (> 2 days)"
            );
            console2.log("  Status: VALID");
        }

        // 2. Verify Gas Oracle (GAS -> WEI) - Mainnet only
        if (chainId == MAINNET_CHAIN_ID) {
            console2.log("[Oracle 2] Gas Oracle (ORACLE_GAS_TO_ETH):");
            AggregatorV3Interface gasOracle = AggregatorV3Interface(ORACLE_GAS_TO_ETH);
            (, int256 gasPrice,, uint256 gasUpdatedAt,) = gasOracle.latestRoundData();
            console2.log("  Price (gwei):", uint256(gasPrice));
            console2.log("  Updated at:", gasUpdatedAt);
            console2.log("  Current time:", block.timestamp);

            require(gasPrice > 0, "SMOKE_TEST_FAILED: Gas oracle price is zero");
            require(
                block.timestamp - gasUpdatedAt <= maxStaleness,
                "SMOKE_TEST_FAILED: Gas oracle timestamp too stale (> 2 days)"
            );
            console2.log("  Status: VALID");
        } else {
            console2.log("[Oracle 2] Gas Oracle: SKIPPED (mainnet only)");
        }

        // 3. Verify ETH/USD Oracle (chain-specific)
        console2.log("[Oracle 3] ETH/USD Oracle:");
        {
            address ethUsdOracleAddr;
            if (chainId == MAINNET_CHAIN_ID) {
                ethUsdOracleAddr = ORACLE_ETH_USD_MAINNET;
                console2.log("  Using: Mainnet ETH/USD Oracle");
            } else if (chainId == BASE_CHAIN_ID) {
                ethUsdOracleAddr = ORACLE_ETH_USD_BASE;
                console2.log("  Using: Base ETH/USD Oracle");
            } else {
                ethUsdOracleAddr = ORACLE_ETH_USD_MAINNET;
                console2.log("  Using: Mainnet ETH/USD Oracle (default)");
            }
            console2.log("  Address:", ethUsdOracleAddr);

            AggregatorV3Interface ethUsdOracle = AggregatorV3Interface(ethUsdOracleAddr);
            (, int256 ethPrice,, uint256 ethUpdatedAt,) = ethUsdOracle.latestRoundData();
            console2.log("  Price (USD, 8 decimals):", uint256(ethPrice));
            console2.log("  Updated at:", ethUpdatedAt);
            console2.log("  Current time:", block.timestamp);

            require(ethPrice > 0, "SMOKE_TEST_FAILED: ETH/USD oracle price is zero");
            require(
                block.timestamp - ethUpdatedAt <= maxStaleness,
                "SMOKE_TEST_FAILED: ETH/USD oracle timestamp too stale (> 2 days)"
            );
            console2.log("  Status: VALID");
        }

        console2.log("=== All Oracle Feeds Verified ===");
    }
}
