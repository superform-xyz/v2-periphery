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
    /// @notice Array of validator public keys (corresponding to validators array)
    bytes[] public validatorPublicKeys;

    mapping(uint64 chainId => string chainName) internal chainNames;
    bytes internal SALT_NAMESPACE;
    string internal constant MNEMONIC = "test test test test test test test test test test test junk";
    string internal constant PRODUCTION_SALT_NAMESPACE = "PROD1.0.0";
    string internal constant STAGING_SALT_NAMESPACE = "STAGING1.0.0";

    address internal constant TEST_DEPLOYER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address internal constant SUPERFORM_TREASURY = 0x1dbD9b26b295A33f126456Ab4e498cd308622f08;

    /// @notice Deployer address used for initial setup (will transfer roles to GOVERNOR later)
    address internal constant DEPLOYER = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;

    address internal constant GOVERNOR = 0x9e01f41da2212C1FBc32A041CfAEF72479FA48eC;
    address internal constant GUARDIAN = 0x5E8C68Ef250fdBcF696F838033CCcE23785DA03F;
    address internal constant SUPER_GOVERNOR_ADDRESS = 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e;
    address internal constant GAS_MANAGER = 0x4d7AACD4b72e6BC6eA0eee6AA61A773A8b556B99;
    address internal constant ORACLE_MANAGER = 0xC72F6950FBF6ffE315525E200F6E54A05F739311;
    address internal constant BANK_MANAGER = 0xBe3B40a05BA6120B73F94c5018Bc90E49A6275E7;

    /*//////////////////////////////////////////////////////////////
                            ORACLE ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Gas to ETH oracle (Fast Gas / Gwei feed) - same on all chains
    address internal constant ORACLE_GAS_TO_ETH = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

    /// @notice ETH/USD oracle on Mainnet
    address internal constant ORACLE_ETH_USD_MAINNET = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /// @notice ETH/USD oracle on Base
    address internal constant ORACLE_ETH_USD_BASE = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;

    /// @notice Base Sequencer Uptime Feed (required for SuperOracleL2)
    address internal constant ORACLE_SEQUENCER_UPTIME_BASE = 0xBCF85224fc0756B9Fa45aA7892530B47e10b6433;

    // Oracle constants for SuperOracle configuration (must match SuperGovernor constants)
    address internal constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address internal constant USD_TOKEN = address(840);
    address internal constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address internal constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    address internal constant UP_TOKEN = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;
    int256 internal constant INITIAL_UP_PRICE = 0.09e18; // $0.09 with 18 decimals
    uint8 internal constant UP_PRICE_DECIMALS = 18;
    bytes32 internal constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 internal constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");

    /*//////////////////////////////////////////////////////////////
                        UPKEEP TOKEN ADDRESSES
    //////////////////////////////////////////////////////////////*/
    /// @notice UPKEEP_TOKEN is used for upkeep payments in SuperVaultAggregator
    /// @dev On mainnet: UPKEEP_TOKEN = UP_TOKEN
    /// @dev On L2s: UPKEEP_TOKEN = WETH (since UP token is only on mainnet)

    /// @notice UPKEEP_TOKEN on Mainnet (same as UP_TOKEN)
    address internal constant UPKEEP_TOKEN_MAINNET = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;

    /// @notice UPKEEP_TOKEN on Base (WETH)
    address internal constant UPKEEP_TOKEN_BASE = 0x4200000000000000000000000000000000000006;

    /*//////////////////////////////////////////////////////////////
                            GAS CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Gas per entry for ECDSAPPSOracle upkeep cost calculation
    uint256 internal constant GAS_PER_ENTRY = 135_000;

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets up base configuration including chain names and common addresses
    /// @param env Environment: 0 = production, 1 = test, 2 = staging
    /// @param saltNamespace Salt namespace (required for env=1, ignored for env=0/2)
    function _setBaseConfiguration(uint256 env, string memory saltNamespace) internal {
        // Validate environment parameter to prevent silent fallback to test config
        require(env == 0 || env == 1 || env == 2, "INVALID_ENV");

        // Set salt namespace based on environment
        // Production and staging use fixed salts (not overridable) for deterministic addresses
        // Test environment requires explicit salt namespace
        if (env == 0) {
            // Production environment - always use production salt
            SALT_NAMESPACE = bytes(PRODUCTION_SALT_NAMESPACE);
        } else if (env == 2) {
            // Staging environment - always use staging salt
            SALT_NAMESPACE = bytes(STAGING_SALT_NAMESPACE);
        } else {
            // Test environment (env=1) requires explicit salt namespace
            require(bytes(saltNamespace).length > 0, "TEST_ENV_REQUIRES_SALT_NAMESPACE");
            SALT_NAMESPACE = bytes(saltNamespace);
        }

        // ===== MAINNET CHAIN NAMES =====
        chainNames[MAINNET_CHAIN_ID] = ETHEREUM_KEY;
        chainNames[BASE_CHAIN_ID] = BASE_KEY;
        chainNames[OPTIMISM_CHAIN_ID] = OPTIMISM_KEY;
        chainNames[ARBITRUM_CHAIN_ID] = ARBITRUM_KEY;
        chainNames[BNB_CHAIN_ID] = BNB_KEY;

        // ===== COMMON CONFIGURATION =====
        if (env == 0) {
            // Production environment
            configuration.owner = DEPLOYER;
            configuration.deployer = DEPLOYER;
            configuration.treasury = SUPERFORM_TREASURY;
            configuration.oracleManager = ORACLE_MANAGER;
            configuration.bankManager = BANK_MANAGER;
            configuration.gasManager = GAS_MANAGER;
            configuration.governor = DEPLOYER;
            configuration.guardian = GUARDIAN;

            // Set production validator addresses and public keys
            validators.push(0x31a11c7502F6A5E551F50f0871d72E8Ce02D39E2);
            validatorPublicKeys.push(
                hex"04cc93b5c7c7fd2399dcf22a9501d7db18a326a568288d93cd41dea78035652dd65b6519153abdfa2b3bf1afefd1b1492d2b0f39652863adf81055748978f483a0"
            );
        } else if (env == 2) {
            // Staging environment
            configuration.owner = DEPLOYER;
            configuration.deployer = DEPLOYER;
            configuration.treasury = SUPERFORM_TREASURY;
            configuration.oracleManager = ORACLE_MANAGER;
            configuration.bankManager = BANK_MANAGER;
            configuration.gasManager = GAS_MANAGER;
            configuration.governor = DEPLOYER;
            configuration.guardian = GUARDIAN;

            // Set staging validator addresses (empty public keys for now)
            validators.push(0x02cbf3dac926743ec757b5A51310f46580e25A04);
            validators.push(0x33E69B6b8342882274c03Bcdc8a1873c6DA52573);
            validatorPublicKeys.push("");
            validatorPublicKeys.push("");
        } else if (env == 1) {
            // Test environment (vnet)
            configuration.owner = TEST_DEPLOYER;
            configuration.deployer = TEST_DEPLOYER;
            configuration.treasury = SUPERFORM_TREASURY;
            configuration.oracleManager = TEST_DEPLOYER;
            configuration.bankManager = TEST_DEPLOYER;
            configuration.gasManager = TEST_DEPLOYER;
            configuration.governor = TEST_DEPLOYER;
            configuration.guardian = TEST_DEPLOYER;

            // Set test validator addresses (empty public keys for now)
            validators.push(0x02cbf3dac926743ec757b5A51310f46580e25A04);
            validators.push(0x33E69B6b8342882274c03Bcdc8a1873c6DA52573);
            validatorPublicKeys.push("");
            validatorPublicKeys.push("");
        }
        // No else needed - env is already validated at function start
    }
}
