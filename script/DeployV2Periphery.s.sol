// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ConfigPeriphery } from "./utils/ConfigPeriphery.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";

// Periphery contracts
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { SuperBank } from "../src/SuperBank.sol";
import { FixedPriceOracle } from "../src/oracles/FixedPriceOracle.sol";
import { SuperOracle } from "../src/oracles/SuperOracle.sol";
import { SuperOracleL2 } from "../src/oracles/SuperOracleL2.sol";
import { ISuperOracle } from "../src/interfaces/oracles/ISuperOracle.sol";

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
        // SuperOracle (mainnet) or SuperOracleL2 (L2 chains) - same 3 feeds configuration
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
        console2.log(
            string(
                abi.encodePacked(
                    "=====> ESTIMATED_NATIVE_COST_ETH: ",
                    vm.toString(totalCostEthWhole),
                    ".",
                    vm.toString(totalCostEthFraction)
                )
            )
        );
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
    )
        internal
        view
        returns (uint256 gasEstimate)
    {
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

        console2.log(
            string(
                abi.encodePacked(
                    contractName,
                    " - Bytecode size: ",
                    vm.toString(bytecode.length),
                    " bytes, estimated gas: ",
                    vm.toString(gasEstimate)
                )
            )
        );

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
        _configurePeripheryContracts(peripheryContracts, coreAddresses, chainId, env);

        // Run smoke test to verify deployment
        _smokeTest(peripheryContracts, chainId, env);

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
        _configurePeripheryContracts(peripheryContracts, coreAddresses, chainId, env);

        // Run smoke test to verify deployment
        _smokeTest(peripheryContracts, chainId, env);

        // Write all exported contracts for this chain
        _writeExportedContracts(chainId);

        console2.log("All periphery contracts deployed and configured successfully.");
    }

    /// @notice Check periphery contract addresses (core contracts)
    /// @param chainId Chain ID for chain-specific contracts
    /// @param env Environment (0 = prod uses locked-bytecode, 1/2 = dev/staging uses locked-bytecode-dev)
    function _checkPeripheryContracts(uint64 chainId, uint256 env) internal {
        console2.log("=== Core Periphery Contracts ===");

        // Check SuperGovernor and get its address for dependent contracts
        address superGovernorAddr = _checkSuperGovernor(env);

        // Check ECDSAPPSOracle
        _checkECDSAPPSOracle(superGovernorAddr, env);

        // Check FixedPriceOracle and get its address
        address fixedPriceOracleAddr = _checkFixedPriceOracle();

        // Check SuperOracle (same deployment for all chains with chain-specific addresses)
        _checkSuperOracle(chainId, superGovernorAddr, fixedPriceOracleAddr);

        // Check SuperBank
        _checkSuperBank(superGovernorAddr);

        // Check vault implementations and aggregator
        _checkVaultContracts(superGovernorAddr, env);
    }

    /// @notice Check SuperGovernor and return its computed address
    function _checkSuperGovernor(uint256 env) internal returns (address) {
        bool upkeepPaymentsEnabled = env == 0;
        bytes memory args = abi.encode(
            configuration.owner,
            configuration.governor,
            configuration.bankManager,
            configuration.oracleManager,
            configuration.gasManager,
            configuration.guardian,
            configuration.treasury,
            upkeepPaymentsEnabled
        );
        __checkContract(SUPER_GOVERNOR_KEY, __getSalt(SUPER_GOVERNOR_KEY), args, env);

        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(__getBytecode(SUPER_GOVERNOR_KEY, env), args),
            __getSalt(SUPER_GOVERNOR_KEY)
        );
    }

    /// @notice Check ECDSAPPSOracle
    function _checkECDSAPPSOracle(address superGovernorAddr, uint256 env) internal {
        bytes memory args = abi.encode(superGovernorAddr, ECDSAPPS_ORACLE_KEY, ECDSAPPS_ORACLE_VERSION);
        __checkContract(ECDSAPPS_ORACLE_KEY, __getSalt(ECDSAPPS_ORACLE_KEY), args, env);
    }

    /// @notice Check FixedPriceOracle and return its computed address
    function _checkFixedPriceOracle() internal returns (address) {
        bytes memory args = abi.encode(INITIAL_UP_PRICE, UP_PRICE_DECIMALS, configuration.deployer);
        __checkContractWithBytecode(
            FIXED_PRICE_ORACLE_KEY,
            __getSalt(FIXED_PRICE_ORACLE_KEY),
            type(FixedPriceOracle).creationCode,
            args
        );
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(type(FixedPriceOracle).creationCode, args),
            __getSalt(FIXED_PRICE_ORACLE_KEY)
        );
    }

    /// @notice Check SuperBank
    function _checkSuperBank(address superGovernorAddr) internal {
        bytes memory args = abi.encode(superGovernorAddr);
        __checkContractWithBytecode(SUPER_BANK_KEY, __getSalt(SUPER_BANK_KEY), type(SuperBank).creationCode, args);
    }

    /// @notice Check vault implementation contracts and aggregator
    function _checkVaultContracts(address superGovernorAddr, uint256 env) internal {
        bytes memory vaultArgs = abi.encode(superGovernorAddr);

        // Check vault implementations
        __checkContract(SUPER_VAULT_KEY, __getSalt(SUPER_VAULT_KEY), vaultArgs, env);
        __checkContract(SUPER_VAULT_STRATEGY_KEY, __getSalt(SUPER_VAULT_STRATEGY_KEY), vaultArgs, env);
        __checkContract(SUPER_VAULT_ESCROW_KEY, __getSalt(SUPER_VAULT_ESCROW_KEY), "", env);

        // Compute implementation addresses for aggregator
        address vaultImpl = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(__getBytecode(SUPER_VAULT_KEY, env), vaultArgs),
            __getSalt(SUPER_VAULT_KEY)
        );
        address strategyImpl = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(__getBytecode(SUPER_VAULT_STRATEGY_KEY, env), vaultArgs),
            __getSalt(SUPER_VAULT_STRATEGY_KEY)
        );
        address escrowImpl = DeterministicDeployerLib.computeAddress(
            __getBytecode(SUPER_VAULT_ESCROW_KEY, env),
            __getSalt(SUPER_VAULT_ESCROW_KEY)
        );

        // Check aggregator
        bytes memory aggregatorArgs = abi.encode(superGovernorAddr, vaultImpl, strategyImpl, escrowImpl);
        __checkContract(SUPER_VAULT_AGGREGATOR_KEY, __getSalt(SUPER_VAULT_AGGREGATOR_KEY), aggregatorArgs, env);
    }

    /// @notice Check SuperOracle (mainnet) or SuperOracleL2 (L2s) with proper oracle feed configuration
    /// @dev Both mainnet and L2s use the same 3 feeds (GAS->WEI, ETH->USD, UP->USD)
    function _checkSuperOracle(uint64 chainId, address superGovernorAddr, address fixedPriceOracleAddr) internal {
        address[] memory bases = new address[](3);
        address[] memory quotes = new address[](3);
        bytes32[] memory providers = new bytes32[](3);
        address[] memory feeds = new address[](3);

        // Get chain-specific oracle addresses
        address gasOracle;
        address ethUsdOracle;
        address upToken;

        if (chainId == MAINNET_CHAIN_ID) {
            gasOracle = ORACLE_GAS_TO_ETH;
            ethUsdOracle = ORACLE_ETH_USD_MAINNET;
            upToken = UP_TOKEN;
        } else if (chainId == BASE_CHAIN_ID) {
            gasOracle = ORACLE_GAS_TO_WEI_BASE;
            ethUsdOracle = ORACLE_ETH_USD_BASE;
            upToken = UP_TOKEN_BASE;
            // Log warning if UP token is not deployed (non-blocking for simulation)
            if (UP_TOKEN_BASE.code.length == 0) {
                console2.log("[WARNING] UP_TOKEN_BASE not deployed - ensure UP token is deployed before actual deployment");
            }
        } else {
            revert("Oracle addresses not configured for this chain");
        }

        // Feed 1: GAS -> WEI
        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_CHAINLINK;
        feeds[0] = gasOracle;

        // Feed 2: ETH -> USD
        bases[1] = NATIVE_TOKEN;
        quotes[1] = USD_TOKEN;
        providers[1] = PROVIDER_CHAINLINK;
        feeds[1] = ethUsdOracle;

        // Feed 3: UP -> USD
        bases[2] = upToken;
        quotes[2] = USD_TOKEN;
        providers[2] = PROVIDER_SUPERFORM;
        feeds[2] = fixedPriceOracleAddr;

        bytes memory superOracleArgs = abi.encode(superGovernorAddr, bases, quotes, providers, feeds);

        if (chainId == MAINNET_CHAIN_ID) {
            __checkContractWithBytecode(
                SUPER_ORACLE_KEY, __getSalt(SUPER_ORACLE_KEY), type(SuperOracle).creationCode, superOracleArgs
            );
        } else {
            __checkContractWithBytecode(
                SUPER_ORACLE_L2_KEY, __getSalt(SUPER_ORACLE_L2_KEY), type(SuperOracleL2).creationCode, superOracleArgs
            );
        }
    }

    /// @notice Check contract using provided bytecode instead of locked bytecode
    /// @dev Used for contracts deployed with type().creationCode
    function __checkContractWithBytecode(
        string memory contractName,
        bytes32 salt,
        bytes memory bytecode,
        bytes memory args
    )
        internal
    {
        // Compute address with provided bytecode and args
        address contractAddr = DeterministicDeployerLib.computeAddress(abi.encodePacked(bytecode, args), salt);

        // Check if deployed
        uint256 codeSize = contractAddr.code.length;
        bool isDeployed = codeSize > 0;

        // Store deployment status
        _saveContractStatus(uint64(block.chainid), contractName, isDeployed, contractAddr);

        // Update counters
        if (isDeployed) {
            deployed++;
        }
        total++;

        // Log status
        console2.log(string(abi.encodePacked(contractName, " Addr: ")), contractAddr, " || >> Code Size: ", codeSize);
        console2.log("");
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
        // upkeepPaymentsEnabled is true only for production environment
        bool upkeepPaymentsEnabled = env == 0;
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
                    configuration.treasury,
                    upkeepPaymentsEnabled
                )
            )
        );

        // Deploy SuperVault implementations first
        peripheryContracts.vaultImpl = __deployContractIfNeeded(
            SUPER_VAULT_KEY,
            chainId,
            __getSalt(SUPER_VAULT_KEY),
            abi.encodePacked(__getBytecode(SUPER_VAULT_KEY, env), abi.encode(peripheryContracts.superGovernor))
        );

        peripheryContracts.strategyImpl = __deployContractIfNeeded(
            SUPER_VAULT_STRATEGY_KEY,
            chainId,
            __getSalt(SUPER_VAULT_STRATEGY_KEY),
            abi.encodePacked(__getBytecode(SUPER_VAULT_STRATEGY_KEY, env), abi.encode(peripheryContracts.superGovernor))
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
        // Skip for test environment (env == 1) since Chainlink oracles not available on vnet
        // Mainnet: GAS->WEI, ETH->USD, UP->USD
        // L2: ETH->USD only (gas oracle and UP oracle not available)
        if (env != 1) {
            peripheryContracts.superOracle =
                _deploySuperOracle(chainId, peripheryContracts.superGovernor, peripheryContracts.fixedPriceOracle);
        } else {
            console2.log("[!] Skipping SuperOracle deployment for test environment");
        }

        // Deploy SuperBank
        peripheryContracts.superBank = __deployContractIfNeeded(
            SUPER_BANK_KEY,
            chainId,
            __getSalt(SUPER_BANK_KEY),
            abi.encodePacked(type(SuperBank).creationCode, abi.encode(peripheryContracts.superGovernor))
        );

        console2.log("All periphery contracts deployment completed successfully with full validation");

        return peripheryContracts;
    }

    /// @notice Deploy SuperOracle (mainnet) or SuperOracleL2 (L2 chains) with initial oracle feeds
    /// @dev Both mainnet and L2s use the same 3 feeds: GAS->WEI, ETH->USD, UP->USD
    ///      Chain-specific addresses are used for each oracle
    /// @param chainId The chain ID to deploy on
    /// @param superGovernor The SuperGovernor address
    /// @param fixedPriceOracle The FixedPriceOracle address for UP/USD pricing
    /// @return superOracle The deployed SuperOracle/SuperOracleL2 address
    function _deploySuperOracle(
        uint64 chainId,
        address superGovernor,
        address fixedPriceOracle
    )
        internal
        returns (address superOracle)
    {
        // Configure initial oracle feeds
        // All chains: 3 feeds (GAS->WEI, ETH->USD, UP->USD)
        // Chain-specific addresses for each oracle

        address[] memory bases = new address[](3);
        address[] memory quotes = new address[](3);
        bytes32[] memory providers = new bytes32[](3);
        address[] memory feeds = new address[](3);

        // Get chain-specific oracle addresses
        address gasOracle;
        address ethUsdOracle;
        address upToken;

        if (chainId == MAINNET_CHAIN_ID) {
            gasOracle = ORACLE_GAS_TO_ETH;
            ethUsdOracle = ORACLE_ETH_USD_MAINNET;
            upToken = UP_TOKEN;
        } else if (chainId == BASE_CHAIN_ID) {
            gasOracle = ORACLE_GAS_TO_WEI_BASE;
            ethUsdOracle = ORACLE_ETH_USD_BASE;
            upToken = UP_TOKEN_BASE;
            // Log warning if UP token is not deployed (non-blocking for simulation)
            if (UP_TOKEN_BASE.code.length == 0) {
                console2.log("[WARNING] UP_TOKEN_BASE not deployed - ensure UP token is deployed before actual deployment");
            }
        } else {
            revert("Oracle addresses not configured for this chain");
        }

        // Feed 1: GAS -> WEI (gas price oracle)
        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_CHAINLINK;
        feeds[0] = gasOracle;

        // Feed 2: ETH -> USD
        bases[1] = NATIVE_TOKEN;
        quotes[1] = USD_TOKEN;
        providers[1] = PROVIDER_CHAINLINK;
        feeds[1] = ethUsdOracle;

        // Feed 3: UP -> USD (using FixedPriceOracle)
        bases[2] = upToken;
        quotes[2] = USD_TOKEN;
        providers[2] = PROVIDER_SUPERFORM;
        feeds[2] = fixedPriceOracle;

        if (chainId == MAINNET_CHAIN_ID) {
            superOracle = __deployContractIfNeeded(
                SUPER_ORACLE_KEY,
                chainId,
                __getSalt(SUPER_ORACLE_KEY),
                abi.encodePacked(
                    type(SuperOracle).creationCode, abi.encode(superGovernor, bases, quotes, providers, feeds)
                )
            );

            console2.log("SuperOracle deployed at:", superOracle);
        } else {
            superOracle = __deployContractIfNeeded(
                SUPER_ORACLE_L2_KEY,
                chainId,
                __getSalt(SUPER_ORACLE_L2_KEY),
                abi.encodePacked(
                    type(SuperOracleL2).creationCode, abi.encode(superGovernor, bases, quotes, providers, feeds)
                )
            );

            console2.log("SuperOracleL2 deployed at:", superOracle);
        }

        console2.log("  Chain ID:", chainId);
        console2.log("  Configured oracles: GAS->WEI, ETH->USD, UP->USD");
        console2.log("  Gas oracle:", gasOracle);
        console2.log("  ETH/USD oracle:", ethUsdOracle);
        console2.log("  UP token:", upToken);

        return superOracle;
    }

    function _configurePeripheryContracts(
        PeripheryContracts memory peripheryContracts,
        CoreContractAddresses memory,
        uint64 chainId,
        uint256 env
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
        SuperGovernor sg = SuperGovernor(peripheryContracts.superGovernor);

        // Check if oracle is already set (getActivePPSOracle reverts if not set)
        address currentOracle;
        try sg.getActivePPSOracle() returns (address oracle) {
            currentOracle = oracle;
        } catch {
            currentOracle = address(0);
        }

        if (currentOracle == peripheryContracts.ecdsappsOracle) {
            console2.log("[Step 1] SKIPPED - Oracle already set to correct address");
        } else if (currentOracle == address(0)) {
            // First time setting - can use setActivePPSOracle directly
            sg.setActivePPSOracle(peripheryContracts.ecdsappsOracle);
            console2.log("[Step 1] DONE - Set active PPS oracle");
        } else {
            // Oracle already set to different address - need timelock
            console2.log("[Step 1] WARNING - Different oracle already set:", currentOracle);
            console2.log("[Step 1] Use proposeActivePPSOracle + executeActivePPSOracleChange to change it");
            console2.log("[Step 1] SKIPPED - Requires timelock process");
        }

        console2.log("[Step 2] Setting validator configuration...");
        SuperGovernor(peripheryContracts.superGovernor)
            .setValidatorConfig(
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

        // Skip SuperOracle configuration for test environment (env == 1)
        if (env != 1) {
            console2.log("[Step 4] Setting SuperOracle address...");
            console2.log("  Oracle address:", peripheryContracts.superOracle);
            SuperGovernor(peripheryContracts.superGovernor)
                .setAddress(
                    SuperGovernor(peripheryContracts.superGovernor).SUPER_ORACLE(), peripheryContracts.superOracle
                );
            console2.log("[Step 4] DONE - Set SuperOracle address");
        } else {
            console2.log("[Step 4] Skipping SuperOracle configuration for test environment");
        }

        console2.log("[Step 5] Setting SuperBank address...");
        console2.log("  Bank address:", peripheryContracts.superBank);
        SuperGovernor(peripheryContracts.superGovernor)
            .setAddress(SuperGovernor(peripheryContracts.superGovernor).SUPER_BANK(), peripheryContracts.superBank);
        console2.log("[Step 5] DONE - Set SuperBank address");

        // Step 6: Configure uptime feed for L2 chains (Chainlink oracles may be stale during sequencer downtime)
        // Skip for test environment (env == 1) since oracles not deployed
        if (env != 1 && chainId != MAINNET_CHAIN_ID) {
            console2.log("[Step 6] Configuring L2 sequencer uptime feed...");

            SuperGovernor governor = SuperGovernor(peripheryContracts.superGovernor);
            bytes32 oracleManagerRole = keccak256("ORACLE_MANAGER_ROLE");

            // Grant ORACLE_MANAGER_ROLE to deployer temporarily (deployer has DEFAULT_ADMIN_ROLE)
            // Note: We use configuration.deployer instead of msg.sender because in Foundry scripts,
            // msg.sender may differ from the actual caller address (--sender flag) during simulation
            bool hadRole = governor.hasRole(oracleManagerRole, configuration.deployer);
            if (!hadRole) {
                governor.grantRole(oracleManagerRole, configuration.deployer);
                console2.log("  Granted ORACLE_MANAGER_ROLE to deployer:", configuration.deployer);
            }

            address[] memory dataOracles = new address[](3);
            address[] memory uptimeOracles = new address[](3);
            uint256[] memory gracePeriodsList = new uint256[](3);

            if (chainId == BASE_CHAIN_ID) {
                // ETH/USD oracle
                dataOracles[0] = ORACLE_ETH_USD_BASE;
                uptimeOracles[0] = ORACLE_SEQUENCER_UPTIME_BASE;
                gracePeriodsList[0] = 0; // Use default grace period (1 hour)

                // GAS/WEI oracle (SuperformGasOracle)
                dataOracles[1] = ORACLE_GAS_TO_WEI_BASE;
                uptimeOracles[1] = ORACLE_SEQUENCER_UPTIME_BASE;
                gracePeriodsList[1] = 0; // Use default grace period (1 hour)

                // FixedPriceOracle (UP/USD)
                dataOracles[2] = peripheryContracts.fixedPriceOracle;
                uptimeOracles[2] = ORACLE_SEQUENCER_UPTIME_BASE;
                gracePeriodsList[2] = 0; // Use default grace period (1 hour)
            } else {
                revert("ORACLE_SEQUENCER_UPTIME not configured for this chain");
            }

            governor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriodsList);

            // Revoke temporary role
            if (!hadRole) {
                governor.revokeRole(oracleManagerRole, configuration.deployer);
                console2.log("  Revoked ORACLE_MANAGER_ROLE from deployer");
            }

            console2.log("[Step 6] DONE - Configured uptime feeds for ETH/USD, GAS/WEI, and UP/USD oracles");
        }

        // NOTE: Governor roles are granted to the deployer initially via configuration.governor
        // in the SuperGovernor constructor. Transfer to the actual GOVERNOR address should happen
        // later via TransferSuperGovernorRole script after Fireblocks is set up.

        console2.log("All core periphery contracts configured successfully");
    }

    /// @notice Smoke test to verify roles and configuration are set correctly post-deployment
    /// @param peripheryContracts The deployed periphery contract addresses
    /// @param chainId The chain ID for chain-specific oracle selection
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    function _smokeTest(PeripheryContracts memory peripheryContracts, uint64 chainId, uint256 env) internal view {
        console2.log("");
        console2.log("=== Running Smoke Test ===");

        SuperGovernor governor = SuperGovernor(peripheryContracts.superGovernor);

        // Verify SUPER_GOVERNOR_ROLE is held by deployer (use configuration.deployer for env-specific address)
        console2.log("[Role Check] DEPLOYER address:", configuration.deployer);
        console2.log(
            "[Role Check] DEPLOYER has SUPER_GOVERNOR_ROLE:",
            governor.hasRole(keccak256("SUPER_GOVERNOR_ROLE"), configuration.deployer)
        );
        console2.log(
            "[Role Check] DEPLOYER has DEFAULT_ADMIN_ROLE:",
            governor.hasRole(governor.DEFAULT_ADMIN_ROLE(), configuration.deployer)
        );

        require(
            governor.hasRole(keccak256("SUPER_GOVERNOR_ROLE"), configuration.deployer),
            "SMOKE_TEST_FAILED: Deployer missing SUPER_GOVERNOR_ROLE"
        );
        require(
            governor.hasRole(governor.DEFAULT_ADMIN_ROLE(), configuration.deployer),
            "SMOKE_TEST_FAILED: Deployer missing DEFAULT_ADMIN_ROLE"
        );

        // Verify active PPS oracle is set
        address activePPSOracle = governor.getActivePPSOracle();
        console2.log("[Config Check] Active PPS Oracle:", activePPSOracle);
        require(activePPSOracle == peripheryContracts.ecdsappsOracle, "SMOKE_TEST_FAILED: PPS Oracle mismatch");

        // Verify FixedPriceOracle is deployed and configured correctly
        console2.log("[Config Check] FixedPriceOracle:", peripheryContracts.fixedPriceOracle);
        require(peripheryContracts.fixedPriceOracle != address(0), "SMOKE_TEST_FAILED: FixedPriceOracle not deployed");
        FixedPriceOracle fixedOracle = FixedPriceOracle(peripheryContracts.fixedPriceOracle);
        require(fixedOracle.owner() == configuration.deployer, "SMOKE_TEST_FAILED: FixedPriceOracle owner mismatch");
        require(fixedOracle.decimals() == UP_PRICE_DECIMALS, "SMOKE_TEST_FAILED: FixedPriceOracle decimals mismatch");
        (, int256 price,,,) = fixedOracle.latestRoundData();
        require(price == INITIAL_UP_PRICE, "SMOKE_TEST_FAILED: FixedPriceOracle price mismatch");

        // Verify SuperVaultAggregator is set
        address aggregator = governor.getAddress(governor.SUPER_VAULT_AGGREGATOR());
        console2.log("[Config Check] SuperVaultAggregator:", aggregator);
        require(aggregator == peripheryContracts.superVaultAggregator, "SMOKE_TEST_FAILED: Aggregator mismatch");

        // Verify SuperOracle is set (skip for test environment since oracle not deployed)
        if (env != 1) {
            address superOracle = governor.getAddress(governor.SUPER_ORACLE());
            console2.log("[Config Check] SuperOracle:", superOracle);
            require(superOracle == peripheryContracts.superOracle, "SMOKE_TEST_FAILED: SuperOracle mismatch");
            require(superOracle != address(0), "SMOKE_TEST_FAILED: SuperOracle not set");
        } else {
            console2.log("[Config Check] Skipping SuperOracle verification for test environment");
        }

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

        // Verify oracle feeds return valid prices via SuperOracle integration
        // Skip for test environment (env == 1) since oracles may not be available on vnet
        if (env != 1) {
            _verifyOracleFeeds(peripheryContracts.superOracle, chainId);
        } else {
            console2.log("[Config Check] Skipping oracle feed verification for test environment");
        }

        console2.log("=== Smoke Test PASSED ===");
        console2.log("");
    }

    /// @notice Verify oracle feeds return valid prices via SuperOracle integration
    /// @dev Uses AVERAGE_PROVIDER to test the full oracle pipeline
    /// @param superOracleAddr The SuperOracle address
    /// @param chainId The chain ID for chain-specific UP token selection
    function _verifyOracleFeeds(address superOracleAddr, uint64 chainId) internal view {
        console2.log("");
        console2.log("=== Verifying Oracle Feeds via SuperOracle ===");
        console2.log("SuperOracle address:", superOracleAddr);

        bytes32 AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");
        ISuperOracle oracle = ISuperOracle(superOracleAddr);

        // Get chain-specific UP token
        address upToken;
        if (chainId == MAINNET_CHAIN_ID) {
            upToken = UP_TOKEN;
        } else if (chainId == BASE_CHAIN_ID) {
            upToken = UP_TOKEN_BASE;
        } else {
            revert("UP token not configured for this chain");
        }

        // 1. Verify ETH/USD feed
        console2.log("[Feed 1] NATIVE_TOKEN -> USD_TOKEN (ETH/USD):");
        {
            uint256 oneEth = 1e18;
            (uint256 ethUsdQuote,, uint256 totalProviders, uint256 availableProviders) =
                oracle.getQuoteFromProvider(oneEth, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);

            console2.log("  1 ETH = %s USD (18 decimals)", ethUsdQuote);
            console2.log("  Total providers:", totalProviders);
            console2.log("  Available providers:", availableProviders);

            require(ethUsdQuote > 0, "SMOKE_TEST_FAILED: ETH/USD quote is zero");
            require(availableProviders > 0, "SMOKE_TEST_FAILED: No available providers for ETH/USD");
            console2.log("  Status: VALID");
        }

        // 2. Verify GAS -> WEI feed
        // Note: On L2 chains, the gas oracle (SuperformGasOracle) requires keeper initialization
        // Skip validation if the oracle hasn't been initialized yet
        console2.log("[Feed 2] GAS_QUOTE -> WEI_QUOTE (Gas Price):");
        {
            uint256 oneGasUnit = 1;
            try oracle.getQuoteFromProvider(oneGasUnit, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER) returns (
                uint256 gasWeiQuote, uint256, uint256 totalProviders, uint256 availableProviders
            ) {
                console2.log("  1 gas unit = %s wei", gasWeiQuote);
                console2.log("  Total providers:", totalProviders);
                console2.log("  Available providers:", availableProviders);

                if (gasWeiQuote > 0 && availableProviders > 0) {
                    console2.log("  Status: VALID");
                } else {
                    console2.log("  Status: NOT INITIALIZED (keeper needs to set price)");
                }
            } catch {
                console2.log("  Status: NOT INITIALIZED (keeper needs to set price)");
                console2.log("  [WARNING] GAS oracle not ready - run keeper to initialize");
            }
        }

        // 3. Verify UP -> USD feed
        console2.log("[Feed 3] UP_TOKEN -> USD_TOKEN (UP/USD):");
        console2.log("  UP token address:", upToken);
        {
            uint256 oneUp = 1e18;
            (uint256 upUsdQuote,, uint256 totalProviders, uint256 availableProviders) =
                oracle.getQuoteFromProvider(oneUp, upToken, USD_TOKEN, AVERAGE_PROVIDER);

            console2.log("  1 UP = %s USD (18 decimals)", upUsdQuote);
            console2.log("  Total providers:", totalProviders);
            console2.log("  Available providers:", availableProviders);

            require(upUsdQuote > 0, "SMOKE_TEST_FAILED: UP/USD quote is zero");
            require(availableProviders > 0, "SMOKE_TEST_FAILED: No available providers for UP/USD");
            console2.log("  Status: VALID");
        }

        console2.log("=== All Oracle Feeds Verified via SuperOracle ===");
    }
}
