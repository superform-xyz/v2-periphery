// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

abstract contract Constants {
    // chain names
    string internal constant ETHEREUM_KEY = "Ethereum";
    string internal constant BASE_KEY = "Base";
    string internal constant OPTIMISM_KEY = "Optimism";
    string internal constant ARBITRUM_KEY = "Arbitrum";
    string internal constant BNB_KEY = "BNB";
    string internal constant HYPEREVM_KEY = "HyperEVM";
    string internal constant FLARE_KEY = "Flare";
    string internal constant SEPOLIA_KEY = "Sepolia";
    string internal constant ARB_SEPOLIA_KEY = "Arbitrum_Sepolia";
    string internal constant BASE_SEPOLIA_KEY = "Base_Sepolia";
    string internal constant OP_SEPOLIA_KEY = "OP_Sepolia";

    // mainnets
    uint64 internal constant MAINNET_CHAIN_ID = 1;
    uint64 internal constant BASE_CHAIN_ID = 8453;
    uint64 internal constant OPTIMISM_CHAIN_ID = 10;
    uint64 internal constant ARBITRUM_CHAIN_ID = 42_161;
    uint64 internal constant BNB_CHAIN_ID = 56;
    uint64 internal constant HYPEREVM_CHAIN_ID = 999;
    uint64 internal constant FLARE_CHAIN_ID = 14;
    // testnets
    uint64 internal constant SEPOLIA_CHAIN_ID = 11_155_111;
    uint64 internal constant ARB_SEPOLIA_CHAIN_ID = 421_613;
    uint64 internal constant BASE_SEPOLIA_CHAIN_ID = 84_532;
    uint64 internal constant OP_SEPOLIA_CHAIN_ID = 11_155_420;

    // Polymer Prover addresses per chain
    address internal constant POLYMER_PROVER_MAINNET = 0x95ccEAE71605c5d97A0AC0EA13013b058729d075;
    address internal constant POLYMER_PROVER_BASE = 0x95ccEAE71605c5d97A0AC0EA13013b058729d075;
    address internal constant POLYMER_PROVER_OPTIMISM = 0x95ccEAE71605c5d97A0AC0EA13013b058729d075;
    address internal constant POLYMER_PROVER_ARBITRUM = 0x95ccEAE71605c5d97A0AC0EA13013b058729d075;
    address internal constant POLYMER_PROVER_BNB = 0x95ccEAE71605c5d97A0AC0EA13013b058729d075;

    // periphery contract keys
    string internal constant SUPER_GOVERNOR_KEY = "SuperGovernor";
    string internal constant VAULT_BANK_KEY = "VaultBank";
    string internal constant SUPER_VAULT_AGGREGATOR_KEY = "SuperVaultAggregator";
    string internal constant ECDSAPPS_ORACLE_KEY = "ECDSAPPSOracle";
    string internal constant ECDSAPPS_ORACLE_VERSION = "1.0";
    string internal constant FIXED_PRICE_ORACLE_KEY = "FixedPriceOracle";
    string internal constant SUPER_ORACLE_KEY = "SuperOracle";
    string internal constant SUPER_ORACLE_L2_KEY = "SuperOracleL2";
    string internal constant SUPER_BANK_KEY = "SuperBank";
    string internal constant BUNDLER_REGISTRY_KEY = "BundlerRegistry";
    string internal constant SUPER_ASSET_KEY = "SuperAsset";
    string internal constant SUPER_ASSET_FACTORY_KEY = "SuperAssetFactory";
    string internal constant UP_KEY = "Up";
    string internal constant UP_DISTRIBUTOR_KEY = "UpDistributor";

    // SuperVault implementation keys (for salt generation and address tracking)
    string internal constant SUPER_VAULT_KEY = "SuperVault";
    string internal constant SUPER_VAULT_STRATEGY_KEY = "SuperVaultStrategy";
    string internal constant SUPER_VAULT_ESCROW_KEY = "SuperVaultEscrow";

    // Validator configuration defaults
    uint256 internal constant INITIAL_VALIDATOR_CONFIG_VERSION = 1;
    uint256 internal constant INITIAL_VALIDATOR_QUORUM = 1;

    // core contract keys (for deterministic address computation)
    string internal constant SUPER_DEPLOYER_KEY = "SuperDeployer";
    string internal constant SUPER_EXECUTOR_KEY = "SuperExecutor";
    string internal constant SUPER_DESTINATION_EXECUTOR_KEY = "SuperDestinationExecutor";
    string internal constant SUPER_LEDGER_KEY = "SuperLedger";
    string internal constant SUPER_LEDGER_CONFIGURATION_KEY = "SuperLedgerConfiguration";
    string internal constant SUPER_VALIDATOR_KEY = "SuperValidator";
    string internal constant SUPER_DESTINATION_VALIDATOR_KEY = "SuperDestinationValidator";
}
