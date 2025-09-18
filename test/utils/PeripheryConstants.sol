// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

abstract contract PeripheryConstants {
    string public constant SUPER_ORACLE_KEY = "SuperOracle";
    string public constant SUPER_GOVERNOR_KEY = "SuperGovernor";
    string public constant SUPER_BANK_KEY = "SuperBank";
    string public constant SUPER_VAULT_AGGREGATOR_KEY = "SUPER_VAULT_AGGREGATOR";
    string public constant ECDSAPPS_ORACLE_KEY = "ECDSAPPS_ORACLE";
    string public constant ECDSAPPS_ORACLE_VERSION = "1.0";
    uint256 public constant EMERGENCY_ADMIN_KEY = 0x6;

    string public constant ORACLE_ETH_TO_USD_KEY = "ORACLE_ETH_TO_USD";
    string public constant ORACLE_USD_TO_UP_KEY = "ORACLE_USD_TO_UP";
    string public constant ORACLE_GAS_TO_ETH_KEY = "ORACLE_GAS_TO_ETH";

    address public constant CHAIN_1_POLYMER_PROVER = 0x441f16587d8a8cACE647352B24E1Aefa55ACEA76;
    address public constant CHAIN_10_POLYMER_PROVER = address(0); // not available
    address public constant CHAIN_8453_POLYMER_PROVER = address(0); // not available

    address public constant ORACLE_ETH_TO_USD = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant ORACLE_USD_TO_UP = address(0);
    address public constant ORACLE_GAS_TO_ETH = address(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
}
