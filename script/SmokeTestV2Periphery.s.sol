// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ConfigPeriphery } from "./utils/ConfigPeriphery.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";

// Periphery contracts
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { ISuperOracle } from "../src/interfaces/oracles/ISuperOracle.sol";
import { FeeType } from "../src/interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVault } from "../src/interfaces/SuperVault/ISuperVault.sol";
import { ISuperVaultStrategy } from "../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { console2 } from "forge-std/console2.sol";

/// @title SmokeTestV2Periphery
/// @notice Post-deployment smoke tests for V2 Periphery contracts
/// @dev Verifies roles, configuration, oracle feeds, and gas info are set correctly
contract SmokeTestV2Periphery is DeployV2Base, ConfigPeriphery {
    /*//////////////////////////////////////////////////////////////
                              STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    struct PeripheryContracts {
        address superGovernor;
        address superOracle;
        address superBank;
        address superVaultAggregator;
        address ecdsappsOracle;
        address vaultImpl;
        address strategyImpl;
        address escrowImpl;
    }

    /// @notice Maximum number of warnings to track
    uint256 internal constant MAX_WARNINGS = 20;

    /// @notice Array to track warning messages
    string[] internal warnings;

    /// @notice Sets up complete configuration for periphery contracts
    /// @param env Environment (0/2 = production, 1 = test)
    /// @param saltNamespace Salt namespace for deployment (if empty, uses production default)
    function _setConfiguration(uint256 env, string memory saltNamespace) internal {
        // Set base configuration (chain names, common addresses)
        _setBaseConfiguration(env, saltNamespace);

        // Set periphery contract dependencies
        _setPeripheryConfiguration();
    }

    /// @notice Run smoke tests for deployed V2 Periphery contracts
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId The target chain ID
    function run(uint256 env, uint64 chainId) public broadcast(env) {
        _setConfiguration(env, "");
        _runSmokeTests(chainId, env);
    }

    /// @notice Run smoke tests with custom salt namespace
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId The target chain ID
    /// @param saltNamespace Salt namespace used for deployment
    function run(uint256 env, uint64 chainId, string memory saltNamespace) public broadcast(env) {
        _setConfiguration(env, saltNamespace);
        _runSmokeTests(chainId, env);
    }

    /// @notice Internal function to run all smoke tests
    /// @param chainId The target chain ID
    /// @param env Environment
    function _runSmokeTests(uint64 chainId, uint256 env) internal {
        console2.log("====== V2 Periphery Smoke Tests ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("");

        // Clear warnings array
        delete warnings;

        // For non-mainnet chains, check if contracts are deployed first
        // This allows CI to pass when contracts haven't been deployed yet on new chains
        if (chainId != MAINNET_CHAIN_ID) {
            address superGovernorAddr = _computeSuperGovernorAddress(env);
            if (superGovernorAddr.code.length == 0) {
                console2.log("SuperGovernor not deployed on chain", chainId);
                console2.log("Skipping smoke tests for this chain (contracts not yet deployed)");
                console2.log("====== Smoke Tests Skipped ======");
                return;
            }
        }

        // Compute deployed contract addresses
        PeripheryContracts memory peripheryContracts = _computePeripheryContractAddresses(env);

        // Run smoke tests
        _smokeTest(peripheryContracts, chainId, env);

        // Print warnings summary at the end
        _printWarningsSummary();

        console2.log("====== All Smoke Tests Completed ======");
    }

    /// @notice Add a warning to the warnings list
    /// @param warning The warning message to add
    function _addWarning(string memory warning) internal {
        if (warnings.length < MAX_WARNINGS) {
            warnings.push(warning);
        }
    }

    /// @notice Print all warnings at the end of the smoke test
    function _printWarningsSummary() internal view {
        if (warnings.length > 0) {
            console2.log("");
            console2.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            console2.log("!!! WARNINGS SUMMARY !!!");
            console2.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            console2.log("Total warnings:", warnings.length);
            console2.log("");

            for (uint256 i = 0; i < warnings.length; i++) {
                console2.log("[WARNING", i + 1, "]", warnings[i]);
            }

            console2.log("");
            console2.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        } else {
            console2.log("");
            console2.log("No warnings detected.");
        }
    }

    /// @notice Compute just the SuperGovernor address (for deployment check)
    /// @param env Environment
    /// @return The computed SuperGovernor address
    function _computeSuperGovernorAddress(uint256 env) internal view returns (address) {
        return DeterministicDeployerLib.computeAddress(
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
                    env == 0 // upkeepPaymentsEnabled
                )
            ),
            __getSalt(SUPER_GOVERNOR_KEY)
        );
    }

    /// @notice Compute periphery contract addresses from deployment
    /// @param env Environment
    /// @return peripheryContracts Struct containing all periphery contract addresses
    function _computePeripheryContractAddresses(uint256 env)
        internal
        view
        returns (PeripheryContracts memory peripheryContracts)
    {
        // Compute SuperGovernor address first (needed for dependent contracts)
        peripheryContracts.superGovernor = DeterministicDeployerLib.computeAddress(
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
                    env == 0 // upkeepPaymentsEnabled
                )
            ),
            __getSalt(SUPER_GOVERNOR_KEY)
        );

        // Validate SuperGovernor is deployed
        require(peripheryContracts.superGovernor.code.length > 0, "SuperGovernor not deployed");
        console2.log("SuperGovernor address:", peripheryContracts.superGovernor);

        // Get addresses from SuperGovernor with detailed error handling
        SuperGovernor governor = SuperGovernor(peripheryContracts.superGovernor);

        // Get role keys for logging
        bytes32 aggregatorKey = governor.SUPER_VAULT_AGGREGATOR();
        bytes32 oracleKey = governor.SUPER_ORACLE();
        bytes32 bankKey = governor.SUPER_BANK();

        console2.log("Looking up registered addresses in SuperGovernor...");
        console2.log("  SUPER_VAULT_AGGREGATOR key:", vm.toString(aggregatorKey));
        console2.log("  SUPER_ORACLE key:", vm.toString(oracleKey));
        console2.log("  SUPER_BANK key:", vm.toString(bankKey));

        // Try to get each address with detailed error messages
        peripheryContracts.superVaultAggregator = _safeGetAddress(governor, aggregatorKey, "SUPER_VAULT_AGGREGATOR");
        peripheryContracts.superOracle = _safeGetAddress(governor, oracleKey, "SUPER_ORACLE");
        peripheryContracts.superBank = _safeGetAddress(governor, bankKey, "SUPER_BANK");
        peripheryContracts.ecdsappsOracle = governor.getActivePPSOracle();

        console2.log("  Active PPS Oracle:", peripheryContracts.ecdsappsOracle);

        return peripheryContracts;
    }

    /// @notice Safely get an address from SuperGovernor with detailed error logging
    /// @param governor The SuperGovernor contract
    /// @param key The address key to lookup
    /// @param keyName Human-readable name of the key for logging
    /// @return The address if found
    function _safeGetAddress(
        SuperGovernor governor,
        bytes32 key,
        string memory keyName
    )
        internal
        view
        returns (address)
    {
        // Use low-level call to check if address exists without reverting
        (bool success, bytes memory data) = address(governor).staticcall(
            abi.encodeWithSelector(governor.getAddress.selector, key)
        );

        if (!success) {
            console2.log("");
            console2.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            console2.log("ERROR: Failed to get address from SuperGovernor");
            console2.log("  Key name:", keyName);
            console2.log("  Key hash:", vm.toString(key));
            console2.log("  SuperGovernor:", address(governor));
            console2.log("");
            console2.log("This usually means the address has NOT been registered");
            console2.log("in SuperGovernor after deployment.");
            console2.log("");
            console2.log("To fix this, run the configuration script to register");
            console2.log("the contract address in SuperGovernor using setAddress()");
            console2.log("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            console2.log("");

            revert(string.concat("CONTRACT_NOT_FOUND: ", keyName, " not registered in SuperGovernor"));
        }

        address result = abi.decode(data, (address));
        console2.log(string.concat("  ", keyName, ":"), result);
        return result;
    }

    /// @notice Smoke test to verify roles and configuration are set correctly post-deployment
    /// @param peripheryContracts The deployed periphery contract addresses
    /// @param chainId The chain ID for chain-specific oracle selection
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    function _smokeTest(PeripheryContracts memory peripheryContracts, uint64 chainId, uint256 env) internal {
        console2.log("");
        console2.log("=== Running Smoke Test ===");

        SuperGovernor governor = SuperGovernor(peripheryContracts.superGovernor);

        // Verify all roles are configured correctly
        // Skip for HyperEVM/Flare since roles haven't been transferred yet
        if (chainId == HYPEREVM_CHAIN_ID || chainId == FLARE_CHAIN_ID) {
            console2.log("[Role Check] SKIPPED - Roles not yet transferred on this chain");
        } else {
            _verifyRoles(governor, env);
        }

        // Verify active PPS oracle is set
        address activePPSOracle = governor.getActivePPSOracle();
        console2.log("[Config Check] Active PPS Oracle:", activePPSOracle);
        require(activePPSOracle == peripheryContracts.ecdsappsOracle, "SMOKE_TEST_FAILED: PPS Oracle mismatch");


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

        // Verify gas info is set for ECDSAPPSOracle (mainnet only, skip for staging)
        _verifyGasInfo(governor, peripheryContracts.ecdsappsOracle, chainId, env);

        // Verify oracle feeds return valid prices via SuperOracle integration
        // Skip for test environment (env == 1) since oracles may not be available on vnet
        if (env != 1) {
            _verifyOracleFeeds(peripheryContracts.superOracle, chainId);
        } else {
            console2.log("[Config Check] Skipping oracle feed verification for test environment");
        }

        // Verify upkeep payments status
        _verifyUpkeepPaymentsStatus(governor, env);

        // Verify fee configuration
        _verifyFeeConfiguration(governor);

        // Verify registered hooks
        _verifyRegisteredHooks(governor);

        // Verify min staleness configuration
        _verifyMinStaleness(governor);

        // Verify UP and UPKEEP_TOKEN addresses (mainnet only)
        _verifyUpkeepTokenConfig(governor, chainId);

        // Verify deployed vaults (if any exist)
        _verifyDeployedVaults(peripheryContracts.superVaultAggregator, peripheryContracts.superGovernor);

        console2.log("=== Smoke Test PASSED ===");
        console2.log("");
    }

    /// @notice Verify all roles are configured correctly on SuperGovernor
    /// @param governor The SuperGovernor contract
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    function _verifyRoles(SuperGovernor governor, uint256 env) internal view {
        console2.log("");
        console2.log("=== Verifying Role Configuration ===");

        // Check admin roles are assigned to correct addresses (not deployer)
        console2.log("[Role Check] Deployer address:", configuration.deployer);
        _verifyAdminRoles(governor, env);

        // Skip operational role checks for staging (env == 2) since roles may not have been assigned
        if (env == 2) {
            console2.log("");
            console2.log("[Role Check] SKIPPED - Operational role checks skipped for staging");
        } else {
            // Check configured role holders from configuration
            console2.log("");
            console2.log("[Role Check] Configured role holders:");
            _verifyOperationalRoleHolders(governor);

            // Verify deployer does NOT have operational roles
            console2.log("");
            console2.log("[Role Check] Verifying deployer does NOT have operational roles:");
            _verifyDeployerNoOperationalRoles(governor);
        }

        console2.log("=== Role Verification Complete ===");
    }

    /// @notice Verify admin roles are assigned to correct addresses
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    function _verifyAdminRoles(SuperGovernor governor, uint256 env) internal view {
        // SUPER_GOVERNOR_ADDRESS should have DEFAULT_ADMIN_ROLE and SUPER_GOVERNOR_ROLE
        // Skip for staging (env == 2) since roles may not have been transferred yet
        if (env == 2) {
            console2.log("[Role Check] SKIPPED - SUPER_GOVERNOR_ADDRESS role check skipped for staging");
        } else {
            bool superGovernorHasDefaultAdmin =
                governor.hasRole(governor.DEFAULT_ADMIN_ROLE(), SUPER_GOVERNOR_ADDRESS);
            bool superGovernorHasSuperGovernorRole =
                governor.hasRole(governor.SUPER_GOVERNOR_ROLE(), SUPER_GOVERNOR_ADDRESS);

            console2.log("[Role Check] SUPER_GOVERNOR_ADDRESS:", SUPER_GOVERNOR_ADDRESS);
            console2.log("  DEFAULT_ADMIN_ROLE:", superGovernorHasDefaultAdmin);
            console2.log("  SUPER_GOVERNOR_ROLE:", superGovernorHasSuperGovernorRole);

            require(
                superGovernorHasDefaultAdmin, "SMOKE_TEST_FAILED: SUPER_GOVERNOR_ADDRESS missing DEFAULT_ADMIN_ROLE"
            );
            require(
                superGovernorHasSuperGovernorRole, "SMOKE_TEST_FAILED: SUPER_GOVERNOR_ADDRESS missing SUPER_GOVERNOR_ROLE"
            );
        }

        // GOVERNOR address should have GOVERNOR_ROLE
        // Skip for staging (env == 2) since roles may not have been transferred yet
        if (env == 2) {
            console2.log("[Role Check] SKIPPED - GOVERNOR role check skipped for staging");
        } else {
            bool governorHasGovernorRole = governor.hasRole(governor.GOVERNOR_ROLE(), GOVERNOR);
            console2.log("[Role Check] GOVERNOR address:", GOVERNOR);
            console2.log("  GOVERNOR_ROLE:", governorHasGovernorRole);
            require(governorHasGovernorRole, "SMOKE_TEST_FAILED: GOVERNOR missing GOVERNOR_ROLE");

            // Verify deployer does NOT have any admin roles anymore (only in prod)
            bool deployerHasDefaultAdmin = governor.hasRole(governor.DEFAULT_ADMIN_ROLE(), configuration.deployer);
            bool deployerHasSuperGovernor = governor.hasRole(governor.SUPER_GOVERNOR_ROLE(), configuration.deployer);
            bool deployerHasGovernor = governor.hasRole(governor.GOVERNOR_ROLE(), configuration.deployer);

            console2.log("[Role Check] Verifying deployer does NOT have admin roles:");
            console2.log("  Deployer has DEFAULT_ADMIN_ROLE:", deployerHasDefaultAdmin);
            console2.log("  Deployer has SUPER_GOVERNOR_ROLE:", deployerHasSuperGovernor);
            console2.log("  Deployer has GOVERNOR_ROLE:", deployerHasGovernor);

            require(!deployerHasDefaultAdmin, "SMOKE_TEST_FAILED: Deployer should NOT have DEFAULT_ADMIN_ROLE");
            require(!deployerHasSuperGovernor, "SMOKE_TEST_FAILED: Deployer should NOT have SUPER_GOVERNOR_ROLE");
            require(!deployerHasGovernor, "SMOKE_TEST_FAILED: Deployer should NOT have GOVERNOR_ROLE");
        }
    }

    /// @notice Verify operational role holders have their roles
    function _verifyOperationalRoleHolders(SuperGovernor governor) internal view {
        // Bank Manager
        console2.log("  Bank Manager address:", configuration.bankManager);
        require(
            governor.hasRole(governor.BANK_MANAGER_ROLE(), configuration.bankManager),
            "SMOKE_TEST_FAILED: Bank manager missing BANK_MANAGER_ROLE"
        );
        console2.log("    has BANK_MANAGER_ROLE: true");

        // Oracle Manager
        console2.log("  Oracle Manager address:", configuration.oracleManager);
        require(
            governor.hasRole(governor.ORACLE_MANAGER_ROLE(), configuration.oracleManager),
            "SMOKE_TEST_FAILED: Oracle manager missing ORACLE_MANAGER_ROLE"
        );
        console2.log("    has ORACLE_MANAGER_ROLE: true");

        // Gas Manager
        console2.log("  Gas Manager address:", configuration.gasManager);
        require(
            governor.hasRole(governor.GAS_MANAGER_ROLE(), configuration.gasManager),
            "SMOKE_TEST_FAILED: Gas manager missing GAS_MANAGER_ROLE"
        );
        console2.log("    has GAS_MANAGER_ROLE: true");

        // Guardian
        console2.log("  Guardian address:", configuration.guardian);
        require(
            governor.hasRole(governor.GUARDIAN_ROLE(), configuration.guardian),
            "SMOKE_TEST_FAILED: Guardian missing GUARDIAN_ROLE"
        );
        console2.log("    has GUARDIAN_ROLE: true");
    }

    /// @notice Verify deployer does NOT have operational roles
    function _verifyDeployerNoOperationalRoles(SuperGovernor governor) internal view {
        require(
            !governor.hasRole(governor.BANK_MANAGER_ROLE(), configuration.deployer),
            "SMOKE_TEST_FAILED: Deployer should NOT have BANK_MANAGER_ROLE"
        );
        console2.log("  Deployer has BANK_MANAGER_ROLE: false");

        require(
            !governor.hasRole(governor.ORACLE_MANAGER_ROLE(), configuration.deployer),
            "SMOKE_TEST_FAILED: Deployer should NOT have ORACLE_MANAGER_ROLE"
        );
        console2.log("  Deployer has ORACLE_MANAGER_ROLE: false");

        require(
            !governor.hasRole(governor.GAS_MANAGER_ROLE(), configuration.deployer),
            "SMOKE_TEST_FAILED: Deployer should NOT have GAS_MANAGER_ROLE"
        );
        console2.log("  Deployer has GAS_MANAGER_ROLE: false");

        require(
            !governor.hasRole(governor.GUARDIAN_ROLE(), configuration.deployer),
            "SMOKE_TEST_FAILED: Deployer should NOT have GUARDIAN_ROLE"
        );
        console2.log("  Deployer has GUARDIAN_ROLE: false");

        console2.log("  Deployer does not have any operational roles: PASSED");
    }

    /// @notice Verify gas info is configured correctly for ECDSAPPSOracle
    /// @param governor The SuperGovernor contract
    /// @param ecdsappsOracle The ECDSAPPSOracle address
    /// @param chainId The chain ID
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    function _verifyGasInfo(SuperGovernor governor, address ecdsappsOracle, uint64 chainId, uint256 env) internal view {
        console2.log("");
        console2.log("=== Verifying Gas Info Configuration ===");

        // Skip gas info verification for staging (env == 2) since it may not be configured
        if (env == 2) {
            console2.log("[Gas Check] SKIPPED - Gas info verification skipped for staging");
            console2.log("=== Gas Info Verification Complete ===");
            return;
        }

        console2.log("ECDSAPPSOracle address:", ecdsappsOracle);

        uint256 gasInfo = governor.getGasInfo(ecdsappsOracle);
        console2.log("[Gas Check] Gas per entry:", gasInfo);
        console2.log("[Gas Check] Expected (GAS_PER_ENTRY):", GAS_PER_ENTRY);

        if (chainId == MAINNET_CHAIN_ID) {
            // On mainnet, gas info MUST be set for upkeep cost calculations
            require(gasInfo > 0, "SMOKE_TEST_FAILED: Gas info not set for ECDSAPPSOracle (mainnet requires gas info)");
            require(gasInfo == GAS_PER_ENTRY, "SMOKE_TEST_FAILED: Gas info mismatch");
            console2.log("[Gas Check] Status: VALID (mainnet)");
        } else {
            // On L2s, gas info may not be set yet (depends on L2 gas oracle availability)
            if (gasInfo == 0) {
                console2.log("[Gas Check] Status: NOT SET (L2 - may be configured later)");
                console2.log("  NOTE: Gas info can be set via SetGasInfo script when L2 gas oracle is available");
            } else {
                require(gasInfo == GAS_PER_ENTRY, "SMOKE_TEST_FAILED: Gas info mismatch");
                console2.log("[Gas Check] Status: VALID (L2)");
            }
        }

        console2.log("=== Gas Info Verification Complete ===");
    }

    /// @notice Verify oracle feeds return valid prices via SuperOracle integration
    /// @dev Uses AVERAGE_PROVIDER to test the full oracle pipeline
    /// @param superOracleAddr The SuperOracle/SuperOracleL2 address
    /// @param chainId The chain ID for chain-specific oracle selection
    function _verifyOracleFeeds(address superOracleAddr, uint64 chainId) internal view {
        console2.log("");
        console2.log("=== Verifying Oracle Feeds via SuperOracle ===");
        console2.log("SuperOracle address:", superOracleAddr);

        bytes32 AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");
        ISuperOracle oracle = ISuperOracle(superOracleAddr);

        // 1. Verify ETH/USD feed (available on all chains)
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

        // 2. Verify GAS -> WEI feed (mainnet only)
        if (chainId == MAINNET_CHAIN_ID) {
            console2.log("[Feed 2] GAS_QUOTE -> WEI_QUOTE (Gas Price):");
            {
                uint256 oneGasUnit = 1;
                (uint256 gasWeiQuote,, uint256 totalProviders, uint256 availableProviders) =
                    oracle.getQuoteFromProvider(oneGasUnit, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);

                console2.log("  1 gas unit = %s wei", gasWeiQuote);
                console2.log("  Total providers:", totalProviders);
                console2.log("  Available providers:", availableProviders);

                require(gasWeiQuote > 0, "SMOKE_TEST_FAILED: GAS/WEI quote is zero");
                require(availableProviders > 0, "SMOKE_TEST_FAILED: No available providers for GAS/WEI");
                console2.log("  Status: VALID");
            }

            // 3. Verify UP -> USD feed (mainnet only)
            console2.log("[Feed 3] UP_TOKEN -> USD_TOKEN (UP/USD):");
            {
                uint256 oneUp = 1e18;
                (uint256 upUsdQuote,, uint256 totalProviders, uint256 availableProviders) =
                    oracle.getQuoteFromProvider(oneUp, UP_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);

                console2.log("  1 UP = %s USD (18 decimals)", upUsdQuote);
                console2.log("  Total providers:", totalProviders);
                console2.log("  Available providers:", availableProviders);

                require(upUsdQuote > 0, "SMOKE_TEST_FAILED: UP/USD quote is zero");
                require(availableProviders > 0, "SMOKE_TEST_FAILED: No available providers for UP/USD");
                console2.log("  Status: VALID");
            }
        } else {
            console2.log("[Feed 2] GAS_QUOTE -> WEI_QUOTE: SKIPPED (mainnet only)");
            console2.log("[Feed 3] UP_TOKEN -> USD_TOKEN: SKIPPED (mainnet only)");
        }

        console2.log("=== All Oracle Feeds Verified via SuperOracle ===");
    }

    /// @notice Verify upkeep payments status is configured correctly
    /// @param governor The SuperGovernor contract
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    function _verifyUpkeepPaymentsStatus(SuperGovernor governor, uint256 env) internal {
        console2.log("");
        console2.log("=== Verifying Upkeep Payments Status ===");

        bool upkeepEnabled = governor.isUpkeepPaymentsEnabled();
        console2.log("[Upkeep Check] Upkeep payments enabled:", upkeepEnabled);

        if (env == 0) {
            // Production should have upkeep payments enabled
            require(upkeepEnabled, "SMOKE_TEST_FAILED: Upkeep payments should be enabled on production");
            console2.log("[Upkeep Check] Status: VALID (production - enabled)");
        } else {
            // Staging/test - just log the status
            console2.log("[Upkeep Check] Status: OK (non-production environment)");
        }

        // Check for pending upkeep change
        (bool proposedStatus, uint256 effectiveTime) = governor.getProposedUpkeepPaymentsStatus();
        if (effectiveTime > 0) {
            console2.log("[Upkeep Check] WARNING: Pending upkeep payments change detected");
            console2.log("  Proposed status:", proposedStatus);
            console2.log("  Effective time:", effectiveTime);
            _addWarning("Pending upkeep payments change detected");
        } else {
            console2.log("[Upkeep Check] No pending upkeep payments change");
        }

        console2.log("=== Upkeep Payments Status Verification Complete ===");
    }

    /// @notice Verify fee configuration is within expected bounds
    /// @param governor The SuperGovernor contract
    function _verifyFeeConfiguration(SuperGovernor governor) internal view {
        console2.log("");
        console2.log("=== Verifying Fee Configuration ===");

        uint256 revenueShare = governor.getFee(FeeType.REVENUE_SHARE);
        uint256 performanceFeeShare = governor.getFee(FeeType.PERFORMANCE_FEE_SHARE);

        console2.log("[Fee Check] Revenue share (bps):", revenueShare);
        console2.log("[Fee Check] Performance fee share (bps):", performanceFeeShare);

        // Verify fees are within reasonable bounds
        // Revenue share: max 100% (10000 bps)
        require(revenueShare <= 10_000, "SMOKE_TEST_FAILED: Revenue share too high (max 100%)");
        // Performance fee share: max 100% (10000 bps)
        require(performanceFeeShare <= 10_000, "SMOKE_TEST_FAILED: Performance fee share too high (max 100%)");

        console2.log("[Fee Check] All fees within acceptable bounds");
        console2.log("=== Fee Configuration Verification Complete ===");
    }

    /// @notice Verify registered hooks on SuperGovernor
    /// @param governor The SuperGovernor contract
    function _verifyRegisteredHooks(SuperGovernor governor) internal {
        console2.log("");
        console2.log("=== Verifying Registered Hooks ===");

        address[] memory hooks = governor.getRegisteredHooks();
        console2.log("[Hooks Check] Total registered hooks:", hooks.length);

        // Log first few hooks for verification (up to 10)
        uint256 displayCount = hooks.length > 10 ? 10 : hooks.length;
        for (uint256 i = 0; i < displayCount; i++) {
            console2.log("  Hook", i, ":", hooks[i]);
            require(governor.isHookRegistered(hooks[i]), "SMOKE_TEST_FAILED: Hook not properly registered");
        }

        if (hooks.length > 10) {
            console2.log("  ... and", hooks.length - 10, "more hooks");
        }

        // We expect at least some hooks to be registered in production
        // But don't fail if none - this might be valid in some environments
        if (hooks.length == 0) {
            console2.log("[Hooks Check] WARNING: No hooks registered");
            _addWarning("No hooks registered");
        } else {
            console2.log("[Hooks Check] All displayed hooks verified as registered");
        }

        console2.log("=== Registered Hooks Verification Complete ===");
    }

    /// @notice Verify minimum staleness configuration
    /// @param governor The SuperGovernor contract
    function _verifyMinStaleness(SuperGovernor governor) internal {
        console2.log("");
        console2.log("=== Verifying Min Staleness Configuration ===");

        uint256 minStaleness = governor.getMinStaleness();
        console2.log("[Staleness Check] Min staleness (seconds):", minStaleness);
        console2.log("[Staleness Check] Min staleness (hours):", minStaleness / 3600);

        // Min staleness should be at least 5 minutes (300 seconds) - warn if too low
        if (minStaleness < 300) {
            string memory warningMsg = "Min staleness is too low (should be >= 5 minutes)";
            console2.log("[Staleness Check] WARNING:", warningMsg);
            _addWarning(warningMsg);
        } else {
            console2.log("[Staleness Check] Min staleness is valid");
        }

        // Check for pending min staleness change
        (uint256 proposedMinStaleness, uint256 effectiveTime) = governor.getProposedMinStaleness();
        if (effectiveTime > 0) {
            console2.log("[Staleness Check] WARNING: Pending min staleness change detected");
            console2.log("  Proposed min staleness:", proposedMinStaleness);
            console2.log("  Effective time:", effectiveTime);
            _addWarning("Pending min staleness change detected");
        }

        console2.log("=== Min Staleness Verification Complete ===");
    }

    /// @notice Verify UP and UPKEEP_TOKEN addresses are configured (mainnet only)
    /// @param governor The SuperGovernor contract
    /// @param chainId The chain ID
    function _verifyUpkeepTokenConfig(SuperGovernor governor, uint64 chainId) internal view {
        console2.log("");
        console2.log("=== Verifying Upkeep Token Configuration ===");

        if (chainId == MAINNET_CHAIN_ID) {
            // On mainnet, UP and UPKEEP_TOKEN should be set
            address upToken = governor.getAddress(keccak256("UP"));
            address upkeepToken = governor.getAddress(keccak256("UPKEEP_TOKEN"));

            console2.log("[Token Check] UP token:", upToken);
            console2.log("[Token Check] UPKEEP_TOKEN:", upkeepToken);

            require(upToken != address(0), "SMOKE_TEST_FAILED: UP token not set on mainnet");
            require(upkeepToken != address(0), "SMOKE_TEST_FAILED: UPKEEP_TOKEN not set on mainnet");

            console2.log("[Token Check] Mainnet token addresses verified");
        } else {
            console2.log("[Token Check] Skipping UP/UPKEEP_TOKEN check (non-mainnet chain)");
        }

        console2.log("=== Upkeep Token Configuration Verification Complete ===");
    }

    /// @notice Verify deployed SuperVaults are functioning correctly
    /// @param aggregatorAddr The SuperVaultAggregator address
    /// @param governorAddr The SuperGovernor address for immutable verification
    function _verifyDeployedVaults(address aggregatorAddr, address governorAddr) internal {
        console2.log("");
        console2.log("=== Verifying Deployed Vaults ===");

        if (aggregatorAddr == address(0)) {
            console2.log("[Vault Check] SuperVaultAggregator not set, skipping vault verification");
            return;
        }

        ISuperVaultAggregator aggregator = ISuperVaultAggregator(aggregatorAddr);

        uint256 vaultCount = aggregator.getSuperVaultsCount();
        uint256 strategyCount = aggregator.getSuperVaultStrategiesCount();
        uint256 escrowCount = aggregator.getSuperVaultEscrowsCount();

        console2.log("[Vault Check] Total SuperVaults:", vaultCount);
        console2.log("[Vault Check] Total Strategies:", strategyCount);
        console2.log("[Vault Check] Total Escrows:", escrowCount);

        // Verify counts match (should be 1:1:1 ratio)
        require(vaultCount == strategyCount, "SMOKE_TEST_FAILED: Vault/Strategy count mismatch");
        require(vaultCount == escrowCount, "SMOKE_TEST_FAILED: Vault/Escrow count mismatch");

        // Verify hooks root update timelock is set
        uint256 hooksTimelock = aggregator.getHooksRootUpdateTimelock();
        console2.log("[Vault Check] Hooks root update timelock (seconds):", hooksTimelock);
        require(hooksTimelock > 0, "SMOKE_TEST_FAILED: Hooks root update timelock not set");

        // Check global hooks root veto status
        bool globalVetoed = aggregator.isGlobalHooksRootVetoed();
        console2.log("[Vault Check] Global hooks root vetoed:", globalVetoed);

        if (vaultCount > 0) {
            // Verify all vaults, not just the first one
            for (uint256 i = 0; i < vaultCount; i++) {
                _verifySingleVault(aggregator, governorAddr, i);
            }
        } else {
            console2.log("[Vault Check] No vaults deployed yet, skipping vault-specific checks");
        }

        console2.log("=== Deployed Vaults Verification Complete ===");
    }

    /// @notice Verify a single SuperVault's immutable and deployment parameters
    /// @param aggregator The SuperVaultAggregator contract
    /// @param governorAddr The expected SuperGovernor address
    /// @param index The index of the vault to verify
    function _verifySingleVault(ISuperVaultAggregator aggregator, address governorAddr, uint256 index) internal {
        address vaultAddr = aggregator.superVaults(index);
        address strategyAddr = aggregator.superVaultStrategies(index);
        address escrowAddr = aggregator.superVaultEscrows(index);

        console2.log("");
        console2.log("[Vault", index, "] Verifying vault:", vaultAddr);
        console2.log("  Strategy:", strategyAddr);
        console2.log("  Escrow:", escrowAddr);

        // Verify vault immutables and get vault info for strategy checks
        (uint8 vaultDecimals, address vaultAsset, string memory vaultSymbol) =
            _verifyVaultImmutables(vaultAddr, strategyAddr, escrowAddr, governorAddr);

        // Verify strategy immutables
        _verifyStrategyImmutables(strategyAddr, vaultAddr, vaultAsset, vaultDecimals, governorAddr);

        // Verify aggregator data
        _verifyAggregatorData(aggregator, strategyAddr, vaultSymbol);

        // Verify fee configuration
        _verifyVaultFeeConfig(strategyAddr);

        console2.log("[Vault", index, "] Verification PASSED");
    }

    /// @notice Verify vault immutable parameters
    function _verifyVaultImmutables(
        address vaultAddr,
        address strategyAddr,
        address escrowAddr,
        address governorAddr
    )
        internal
        view
        returns (uint8 vaultDecimals, address vaultAsset, string memory vaultSymbol)
    {
        // Get vault info
        string memory vaultName = IERC20Metadata(vaultAddr).name();
        vaultSymbol = IERC20Metadata(vaultAddr).symbol();
        vaultDecimals = IERC20Metadata(vaultAddr).decimals();
        vaultAsset = IERC4626(vaultAddr).asset();

        console2.log("  Vault Name:", vaultName);
        console2.log("  Vault Symbol:", vaultSymbol);
        console2.log("  Vault Decimals:", vaultDecimals);
        console2.log("  Vault Asset:", vaultAsset);

        // Verify vault's strategy and escrow pointers match aggregator
        address vaultStrategy = _getVaultStrategy(vaultAddr);
        address vaultEscrow = ISuperVault(vaultAddr).escrow();

        console2.log("  Vault -> Strategy:", vaultStrategy);
        console2.log("  Vault -> Escrow:", vaultEscrow);

        require(vaultStrategy == strategyAddr, "SMOKE_TEST_FAILED: Vault strategy mismatch");
        require(vaultEscrow == escrowAddr, "SMOKE_TEST_FAILED: Vault escrow mismatch");

        // Verify vault's SUPER_GOVERNOR immutable
        address vaultGovernor = _getVaultSuperGovernor(vaultAddr);
        console2.log("  Vault SUPER_GOVERNOR:", vaultGovernor);
        require(vaultGovernor == governorAddr, "SMOKE_TEST_FAILED: Vault SUPER_GOVERNOR mismatch");

        // Verify vault PRECISION matches 10^decimals
        uint256 vaultPrecision = _getVaultPrecision(vaultAddr);
        uint256 expectedPrecision = 10 ** vaultDecimals;
        console2.log("  Vault PRECISION:", vaultPrecision);
        console2.log("  Expected PRECISION:", expectedPrecision);
        require(vaultPrecision == expectedPrecision, "SMOKE_TEST_FAILED: Vault PRECISION mismatch");
    }

    /// @notice Verify strategy immutable parameters
    function _verifyStrategyImmutables(
        address strategyAddr,
        address vaultAddr,
        address vaultAsset,
        uint8 vaultDecimals,
        address governorAddr
    )
        internal
        view
    {
        // Verify strategy's vault info
        (address stratVault, address stratAsset, uint8 stratDecimals) =
            ISuperVaultStrategy(strategyAddr).getVaultInfo();
        console2.log("  Strategy -> Vault:", stratVault);
        console2.log("  Strategy -> Asset:", stratAsset);
        console2.log("  Strategy Decimals:", stratDecimals);

        require(stratVault == vaultAddr, "SMOKE_TEST_FAILED: Strategy vault mismatch");
        require(stratAsset == vaultAsset, "SMOKE_TEST_FAILED: Strategy asset mismatch");
        require(stratDecimals == vaultDecimals, "SMOKE_TEST_FAILED: Strategy decimals mismatch");

        // Verify strategy's SUPER_GOVERNOR immutable
        address strategyGovernor = _getStrategySuperGovernor(strategyAddr);
        console2.log("  Strategy SUPER_GOVERNOR:", strategyGovernor);
        require(strategyGovernor == governorAddr, "SMOKE_TEST_FAILED: Strategy SUPER_GOVERNOR mismatch");

        // Verify strategy PRECISION matches 10^decimals
        uint256 strategyPrecision = _getStrategyPrecision(strategyAddr);
        uint256 expectedPrecision = 10 ** vaultDecimals;
        console2.log("  Strategy PRECISION:", strategyPrecision);
        require(strategyPrecision == expectedPrecision, "SMOKE_TEST_FAILED: Strategy PRECISION mismatch");
    }

    /// @notice Verify aggregator data for a strategy
    function _verifyAggregatorData(
        ISuperVaultAggregator aggregator,
        address strategyAddr,
        string memory vaultSymbol
    )
        internal
    {
        // Verify strategy has valid PPS
        uint256 pps = aggregator.getPPS(strategyAddr);
        console2.log("  Strategy PPS:", pps);
        require(pps > 0, "SMOKE_TEST_FAILED: Strategy PPS is zero");

        // Check strategy pause status
        bool isPaused = aggregator.isStrategyPaused(strategyAddr);
        console2.log("  Strategy paused:", isPaused);
        if (isPaused) {
            _addWarning(string.concat("Vault ", vaultSymbol, " strategy is paused"));
        }

        // Check PPS staleness
        bool isStale = aggregator.isPPSStale(strategyAddr);
        console2.log("  PPS stale:", isStale);
        if (isStale) {
            _addWarning(string.concat("Vault ", vaultSymbol, " PPS is stale"));
        }

        // Get main manager
        address mainManager = aggregator.getMainManager(strategyAddr);
        console2.log("  Main manager:", mainManager);
        require(mainManager != address(0), "SMOKE_TEST_FAILED: Strategy has no main manager");

        // Get upkeep balance
        uint256 upkeepBalance = aggregator.getUpkeepBalance(strategyAddr);
        console2.log("  Upkeep balance:", upkeepBalance);

        // Get staleness configuration
        uint256 maxStaleness = aggregator.getMaxStaleness(strategyAddr);
        uint256 minUpdateInterval = aggregator.getMinUpdateInterval(strategyAddr);
        console2.log("  Max staleness (seconds):", maxStaleness);
        console2.log("  Min update interval (seconds):", minUpdateInterval);

        // Verify min update interval < max staleness
        require(
            minUpdateInterval < maxStaleness, "SMOKE_TEST_FAILED: minUpdateInterval must be less than maxStaleness"
        );

        // Get deviation threshold
        uint256 deviationThreshold = aggregator.getDeviationThreshold(strategyAddr);
        console2.log("  Deviation threshold:", deviationThreshold);
    }

    /// @notice Verify vault fee configuration
    function _verifyVaultFeeConfig(address strategyAddr) internal view {
        ISuperVaultStrategy.FeeConfig memory feeConfig = ISuperVaultStrategy(strategyAddr).getConfigInfo();
        console2.log("  Performance fee (bps):", feeConfig.performanceFeeBps);
        console2.log("  Management fee (bps):", feeConfig.managementFeeBps);
        console2.log("  Fee recipient:", feeConfig.recipient);

        // Verify fees are reasonable
        require(feeConfig.performanceFeeBps <= 5000, "SMOKE_TEST_FAILED: Performance fee > 50%");
        require(feeConfig.managementFeeBps <= 500, "SMOKE_TEST_FAILED: Management fee > 5%");
        require(feeConfig.recipient != address(0), "SMOKE_TEST_FAILED: Fee recipient is zero");
    }

    /// @notice Get vault's strategy address via low-level call
    function _getVaultStrategy(address vault) internal view returns (address) {
        (bool success, bytes memory data) = vault.staticcall(abi.encodeWithSignature("strategy()"));
        require(success, "SMOKE_TEST_FAILED: Failed to get vault strategy");
        return abi.decode(data, (address));
    }

    /// @notice Get vault's SUPER_GOVERNOR address via low-level call
    function _getVaultSuperGovernor(address vault) internal view returns (address) {
        (bool success, bytes memory data) = vault.staticcall(abi.encodeWithSignature("SUPER_GOVERNOR()"));
        require(success, "SMOKE_TEST_FAILED: Failed to get vault SUPER_GOVERNOR");
        return abi.decode(data, (address));
    }

    /// @notice Get vault's PRECISION via low-level call
    function _getVaultPrecision(address vault) internal view returns (uint256) {
        (bool success, bytes memory data) = vault.staticcall(abi.encodeWithSignature("PRECISION()"));
        require(success, "SMOKE_TEST_FAILED: Failed to get vault PRECISION");
        return abi.decode(data, (uint256));
    }

    /// @notice Get strategy's SUPER_GOVERNOR address via low-level call
    function _getStrategySuperGovernor(address strategy) internal view returns (address) {
        (bool success, bytes memory data) = strategy.staticcall(abi.encodeWithSignature("SUPER_GOVERNOR()"));
        require(success, "SMOKE_TEST_FAILED: Failed to get strategy SUPER_GOVERNOR");
        return abi.decode(data, (address));
    }

    /// @notice Get strategy's PRECISION via low-level call
    function _getStrategyPrecision(address strategy) internal view returns (uint256) {
        (bool success, bytes memory data) = strategy.staticcall(abi.encodeWithSignature("PRECISION()"));
        require(success, "SMOKE_TEST_FAILED: Failed to get strategy PRECISION");
        return abi.decode(data, (uint256));
    }
}
