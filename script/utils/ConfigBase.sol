// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import "./Constants.sol";

/// @title ConfigBase
/// @notice Base configuration contract containing common addresses, owner settings, and environment data structure
abstract contract ConfigBase is Constants {
    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Base environment data structure for common configuration
    struct EnvironmentData {
        address deployer;
        address owner;
        address treasury;
        address oracleManager;
        address bankManager;
        address gasManager;
        address governor;
        address guardian;
        mapping(uint64 chainId => address polymerProver) polymerProvers;
    }

    EnvironmentData public configuration;

    /// @notice Array of validator addresses
    address[] public validators;

    mapping(uint64 chainId => string chainName) internal chainNames;
    bytes internal SALT_NAMESPACE;
    string internal constant MNEMONIC = "test test test test test test test test test test test junk";
    string internal constant PRODUCTION_SALT_NAMESPACE = "PROD1.0.0";
    string internal constant STAGING_SALT_NAMESPACE = "STAGING1.0.0";

    address internal constant TEST_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address internal constant SUPERFORM_TREASURY = 0x1dbD9b26b295A33f126456Ab4e498cd308622f08;
    address internal constant DEFAULT_MANAGER = 0x9E545AEd5C57E20221d6311c6CcCe09304941BF0;

    address internal constant GOVERNOR = 0x9e01f41da2212C1FBc32A041CfAEF72479FA48eC;
    address internal constant GUARDIAN = 0x5E8C68Ef250fdBcF696F838033CCcE23785DA03F;
    address internal constant GAS_MANAGER = 0x4d7AACD4b72e6BC6eA0eee6AA61A773A8b556B99;
    address internal constant ORACLE_MANAGER = 0xC72F6950FBF6ffE315525E200F6E54A05F739311;

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets up base configuration including chain names and common addresses
    /// @param env Environment (0 = production, 1 = test, 2 = staging)
    /// @param saltNamespace Salt namespace for deployment (if empty, uses environment-specific default)
    function _setBaseConfiguration(uint256 env, string memory saltNamespace) internal {
        // Set salt namespace based on environment with different salts for prod vs staging
        if (bytes(saltNamespace).length == 0) {
            if (env == 0) {
                // Production environment - use production salt
                SALT_NAMESPACE = bytes(PRODUCTION_SALT_NAMESPACE);
            } else if (env == 2) {
                // Staging environment - use staging salt
                SALT_NAMESPACE = bytes(STAGING_SALT_NAMESPACE);
            } else {
                revert("INVALID_ENVIRONMENT");
            }
        } else {
            SALT_NAMESPACE = bytes(saltNamespace);
        }

        // ===== MAINNET CHAIN NAMES =====
        chainNames[MAINNET_CHAIN_ID] = ETHEREUM_KEY;
        chainNames[BASE_CHAIN_ID] = BASE_KEY;
        chainNames[OPTIMISM_CHAIN_ID] = OPTIMISM_KEY;
        chainNames[ARBITRUM_CHAIN_ID] = ARBITRUM_KEY;
        chainNames[BNB_CHAIN_ID] = BNB_KEY;

        // ===== COMMON CONFIGURATION =====
        if (env == 0 || env == 2) {
            // Production and Staging environments
            // Owner and deployer are the same for prod/staging
            configuration.owner = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;
            configuration.deployer = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;
            configuration.treasury = SUPERFORM_TREASURY;
            configuration.oracleManager = ORACLE_MANAGER;
            configuration.bankManager = DEFAULT_MANAGER;
            configuration.gasManager = GAS_MANAGER;
            // NOTE: Governor starts as deployer address to allow running
            // add_hooks_to_governor_staging_prod.sh right after deployment
            // (before Fireblocks is set up). Transfer to GOVERNOR later.
            configuration.governor = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;
            configuration.guardian = GUARDIAN;

            // Set validator addresses
            validators.push(0x02cbf3dac926743ec757b5A51310f46580e25A04);
            validators.push(0x33E69B6b8342882274c03Bcdc8a1873c6DA52573);
        } else {
            // Test environment
            configuration.owner = TEST_DEPLOYER;
            configuration.deployer = TEST_DEPLOYER;
            configuration.treasury = SUPERFORM_TREASURY;
            configuration.oracleManager = DEFAULT_MANAGER;
            configuration.bankManager = DEFAULT_MANAGER;
            configuration.gasManager = DEFAULT_MANAGER;
            configuration.governor = DEFAULT_MANAGER;
            configuration.guardian = DEFAULT_MANAGER;

            // Set validator addresses
            validators.push(0x02cbf3dac926743ec757b5A51310f46580e25A04);
            validators.push(0x33E69B6b8342882274c03Bcdc8a1873c6DA52573);
        }
    }
}
