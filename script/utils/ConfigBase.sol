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
        mapping(uint64 chainId => address polymerProver) polymerProvers;
    }

    EnvironmentData public configuration;

    /// @notice Array of validator addresses
    address[] public validators;

    mapping(uint64 chainId => string chainName) internal chainNames;
    bytes internal SALT_NAMESPACE;
    string internal constant MNEMONIC = "test test test test test test test test test test test junk";
    string internal constant PRODUCTION_SALT_NAMESPACE = "DEPLOYPROD1.0.0";

    address internal constant TEST_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets up base configuration including chain names and common addresses
    /// @param env Environment (0/2 = production, 1 = test)
    /// @param saltNamespace Salt namespace for deployment (if empty, uses production default)
    function _setBaseConfiguration(uint256 env, string memory saltNamespace) internal {
        // Set salt namespace - use production default if empty
        if (bytes(saltNamespace).length == 0) {
            SALT_NAMESPACE = bytes(PRODUCTION_SALT_NAMESPACE);
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
            // Production environment
            configuration.owner = 0x22BC97cFac64D6d9BCaDF5dC36e4D01Db9e929c5;
            configuration.treasury = 0x22BC97cFac64D6d9BCaDF5dC36e4D01Db9e929c5;

            // Set validator addresses
            validators.push(0x02cbf3dac926743ec757b5A51310f46580e25A04);
            validators.push(0x33E69B6b8342882274c03Bcdc8a1873c6DA52573);
        } else {
            // Test environment
            configuration.owner = TEST_DEPLOYER;
            configuration.treasury = TEST_DEPLOYER;

            // Set validator addresses
            validators.push(0x02cbf3dac926743ec757b5A51310f46580e25A04);
            validators.push(0x33E69B6b8342882274c03Bcdc8a1873c6DA52573);
        }
    }
}
