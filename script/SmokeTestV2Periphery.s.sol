// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ConfigPeriphery } from "./utils/ConfigPeriphery.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";

// Periphery contracts
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { FixedPriceOracle } from "../src/oracles/FixedPriceOracle.sol";
import { ISuperOracle } from "../src/interfaces/oracles/ISuperOracle.sol";

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
        address fixedPriceOracle;
        address vaultImpl;
        address strategyImpl;
        address escrowImpl;
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
    function _runSmokeTests(uint64 chainId, uint256 env) internal view {
        console2.log("====== V2 Periphery Smoke Tests ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("");

        // Compute deployed contract addresses
        PeripheryContracts memory peripheryContracts = _computePeripheryContractAddresses(chainId, env);

        // Run smoke tests
        _smokeTest(peripheryContracts, chainId, env);

        console2.log("====== All Smoke Tests Completed ======");
    }

    /// @notice Compute periphery contract addresses from deployment
    /// @param chainId Chain ID
    /// @param env Environment
    /// @return peripheryContracts Struct containing all periphery contract addresses
    function _computePeripheryContractAddresses(
        uint64 chainId,
        uint256 env
    )
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

        // Get addresses from SuperGovernor
        SuperGovernor governor = SuperGovernor(peripheryContracts.superGovernor);

        peripheryContracts.superVaultAggregator = governor.getAddress(governor.SUPER_VAULT_AGGREGATOR());
        peripheryContracts.superOracle = governor.getAddress(governor.SUPER_ORACLE());
        peripheryContracts.superBank = governor.getAddress(governor.SUPER_BANK());
        peripheryContracts.ecdsappsOracle = governor.getActivePPSOracle();

        // Compute FixedPriceOracle address
        peripheryContracts.fixedPriceOracle = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(
                type(FixedPriceOracle).creationCode,
                abi.encode(INITIAL_UP_PRICE, UP_PRICE_DECIMALS, configuration.deployer)
            ),
            __getSalt(FIXED_PRICE_ORACLE_KEY)
        );

        return peripheryContracts;
    }

    /// @notice Smoke test to verify roles and configuration are set correctly post-deployment
    /// @param peripheryContracts The deployed periphery contract addresses
    /// @param chainId The chain ID for chain-specific oracle selection
    /// @param env Environment (0 = prod, 1 = test, 2 = staging)
    function _smokeTest(PeripheryContracts memory peripheryContracts, uint64 chainId, uint256 env) internal view {
        console2.log("");
        console2.log("=== Running Smoke Test ===");

        SuperGovernor governor = SuperGovernor(peripheryContracts.superGovernor);

        // Verify all roles are configured correctly
        _verifyRoles(governor);

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

        // Verify gas info is set for ECDSAPPSOracle (mainnet only)
        _verifyGasInfo(governor, peripheryContracts.ecdsappsOracle, chainId);

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

    /// @notice Verify all roles are configured correctly on SuperGovernor
    /// @param governor The SuperGovernor contract
    function _verifyRoles(SuperGovernor governor) internal view {
        console2.log("");
        console2.log("=== Verifying Role Configuration ===");

        // Get all role identifiers
        bytes32 defaultAdminRole = governor.DEFAULT_ADMIN_ROLE();
        bytes32 superGovernorRole = governor.SUPER_GOVERNOR_ROLE();
        bytes32 governorRole = governor.GOVERNOR_ROLE();
        bytes32 bankManagerRole = governor.BANK_MANAGER_ROLE();
        bytes32 oracleManagerRole = governor.ORACLE_MANAGER_ROLE();
        bytes32 gasManagerRole = governor.GAS_MANAGER_ROLE();
        bytes32 guardianRole = governor.GUARDIAN_ROLE();

        // Check deployer roles (should have admin roles initially)
        console2.log("[Role Check] Deployer address:", configuration.deployer);

        bool hasDefaultAdmin = governor.hasRole(defaultAdminRole, configuration.deployer);
        bool hasSuperGovernor = governor.hasRole(superGovernorRole, configuration.deployer);
        bool hasGovernor = governor.hasRole(governorRole, configuration.deployer);

        console2.log("  DEFAULT_ADMIN_ROLE:", hasDefaultAdmin);
        console2.log("  SUPER_GOVERNOR_ROLE:", hasSuperGovernor);
        console2.log("  GOVERNOR_ROLE:", hasGovernor);

        require(hasDefaultAdmin, "SMOKE_TEST_FAILED: Deployer missing DEFAULT_ADMIN_ROLE");
        require(hasSuperGovernor, "SMOKE_TEST_FAILED: Deployer missing SUPER_GOVERNOR_ROLE");
        require(hasGovernor, "SMOKE_TEST_FAILED: Deployer missing GOVERNOR_ROLE");

        // Check configured role holders from configuration
        console2.log("");
        console2.log("[Role Check] Configured role holders:");

        // Bank Manager
        console2.log("  Bank Manager address:", configuration.bankManager);
        bool bankManagerHasRole = governor.hasRole(bankManagerRole, configuration.bankManager);
        console2.log("    has BANK_MANAGER_ROLE:", bankManagerHasRole);
        require(bankManagerHasRole, "SMOKE_TEST_FAILED: Bank manager missing BANK_MANAGER_ROLE");

        // Oracle Manager
        console2.log("  Oracle Manager address:", configuration.oracleManager);
        bool oracleManagerHasRole = governor.hasRole(oracleManagerRole, configuration.oracleManager);
        console2.log("    has ORACLE_MANAGER_ROLE:", oracleManagerHasRole);
        require(oracleManagerHasRole, "SMOKE_TEST_FAILED: Oracle manager missing ORACLE_MANAGER_ROLE");

        // Gas Manager
        console2.log("  Gas Manager address:", configuration.gasManager);
        bool gasManagerHasRole = governor.hasRole(gasManagerRole, configuration.gasManager);
        console2.log("    has GAS_MANAGER_ROLE:", gasManagerHasRole);
        require(gasManagerHasRole, "SMOKE_TEST_FAILED: Gas manager missing GAS_MANAGER_ROLE");

        // Guardian
        console2.log("  Guardian address:", configuration.guardian);
        bool guardianHasRole = governor.hasRole(guardianRole, configuration.guardian);
        console2.log("    has GUARDIAN_ROLE:", guardianHasRole);
        require(guardianHasRole, "SMOKE_TEST_FAILED: Guardian missing GUARDIAN_ROLE");

        // Verify deployer does NOT have operational roles (unless they are the same address)
        console2.log("");
        console2.log("[Role Check] Verifying deployer does not have unintended operational roles:");

        if (configuration.deployer != configuration.bankManager) {
            bool deployerHasBankManager = governor.hasRole(bankManagerRole, configuration.deployer);
            console2.log("  Deployer has BANK_MANAGER_ROLE:", deployerHasBankManager);
            // Note: This is informational, not a failure - deployer might temporarily have role
        }

        if (configuration.deployer != configuration.gasManager) {
            bool deployerHasGasManager = governor.hasRole(gasManagerRole, configuration.deployer);
            console2.log("  Deployer has GAS_MANAGER_ROLE:", deployerHasGasManager);
            // After SetGasInfo, deployer should NOT have this role
            if (deployerHasGasManager) {
                console2.log("  WARNING: Deployer still has GAS_MANAGER_ROLE - should be revoked after SetGasInfo");
            }
        }

        console2.log("=== Role Verification Complete ===");
    }

    /// @notice Verify gas info is configured correctly for ECDSAPPSOracle
    /// @param governor The SuperGovernor contract
    /// @param ecdsappsOracle The ECDSAPPSOracle address
    /// @param chainId The chain ID
    function _verifyGasInfo(SuperGovernor governor, address ecdsappsOracle, uint64 chainId) internal view {
        console2.log("");
        console2.log("=== Verifying Gas Info Configuration ===");
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
}
