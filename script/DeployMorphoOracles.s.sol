// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { MorphoLendYieldSourceOracle } from "../src/oracles/MorphoLendYieldSourceOracle.sol";
import { MorphoBorrowCostOracle } from "../src/oracles/MorphoBorrowCostOracle.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeployMorphoOracles
/// @notice Deployment script for MorphoLendYieldSourceOracle and MorphoBorrowCostOracle
/// @dev Deploys both oracles with the deployer as admin (DEFAULT_ADMIN_ROLE + MANAGER_ROLE)
contract DeployMorphoOracles is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    string internal constant MORPHO_LEND_ORACLE_KEY = "MorphoLendYieldSourceOracle";
    string internal constant MORPHO_BORROW_ORACLE_KEY = "MorphoBorrowCostOracle";

    /// @notice Morpho Blue singleton addresses per chain
    address internal constant MORPHO_MAINNET = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address internal constant MORPHO_BASE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address internal constant MORPHO_OPTIMISM = 0xce95AfbB8EA029495c66020883F87aaE8864AF92;
    address internal constant MORPHO_ARBITRUM = 0x6c247b1F6182318877311737BaC0844bAa518F5e;
    address internal constant MORPHO_BNB = 0x01b0Bd309AA75547f7a37Ad7B1219A898E67a83a;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy both Morpho oracles
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    function run(uint256 env, uint64 chainId) external broadcast(env) {
        _deploy(env, chainId);
    }

    /// @notice Check deployment status of both Morpho oracles
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    function runCheck(uint256 env, uint64 chainId) external broadcast(env) {
        _setBaseConfiguration(env, "");

        address morpho = _getMorphoAddress(chainId);
        address admin = msg.sender;
        address superLedgerConfiguration = _getSuperLedgerConfiguration();

        console2.log("====== Morpho Oracles Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Morpho:", morpho);
        console2.log("Admin:", admin);
        console2.log("SuperLedgerConfiguration:", superLedgerConfiguration);
        console2.log("");

        // Check lend oracle
        address lendAddr = _computeLendOracleAddress(morpho, superLedgerConfiguration, admin);
        bool lendDeployed = lendAddr.code.length > 0;
        console2.log("=== MorphoLendYieldSourceOracle ===");
        console2.log("Computed address:", lendAddr);
        console2.log("Is deployed:", lendDeployed);

        if (lendDeployed) {
            MorphoLendYieldSourceOracle lendOracle = MorphoLendYieldSourceOracle(lendAddr);
            console2.log("Has DEFAULT_ADMIN_ROLE:", lendOracle.hasRole(lendOracle.DEFAULT_ADMIN_ROLE(), admin));
            console2.log("Has MANAGER_ROLE:", lendOracle.hasRole(lendOracle.MANAGER_ROLE(), admin));
        }
        console2.log("");

        // Check borrow oracle
        address borrowAddr = _computeBorrowOracleAddress(morpho, superLedgerConfiguration, admin);
        bool borrowDeployed = borrowAddr.code.length > 0;
        console2.log("=== MorphoBorrowCostOracle ===");
        console2.log("Computed address:", borrowAddr);
        console2.log("Is deployed:", borrowDeployed);

        if (borrowDeployed) {
            MorphoBorrowCostOracle borrowOracle = MorphoBorrowCostOracle(borrowAddr);
            console2.log("Has DEFAULT_ADMIN_ROLE:", borrowOracle.hasRole(borrowOracle.DEFAULT_ADMIN_ROLE(), admin));
            console2.log("Has MANAGER_ROLE:", borrowOracle.hasRole(borrowOracle.MANAGER_ROLE(), admin));
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal deployment function
    function _deploy(uint256 env, uint64 chainId) internal {
        _setBaseConfiguration(env, "");

        address morpho = _getMorphoAddress(chainId);
        address admin = msg.sender;
        address slc = _getSuperLedgerConfiguration();

        console2.log("====== Deploying Morpho Oracles ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Morpho:", morpho);
        console2.log("Admin:", admin);
        console2.log("SuperLedgerConfiguration:", slc);
        console2.log("");

        // Validate
        require(morpho != address(0), "UNSUPPORTED_CHAIN");
        require(admin != address(0), "INVALID_ADMIN");
        require(slc != address(0), "INVALID_SUPER_LEDGER_CONFIGURATION");

        // Deploy and verify lend oracle
        address lendAddr = _deployLendOracle(chainId, morpho, slc, admin);

        // Deploy and verify borrow oracle
        address borrowAddr = _deployBorrowOracle(chainId, morpho, slc, admin);

        // Write JSON output
        _writeMorphoOraclesJson(env, chainId, lendAddr, borrowAddr, admin);

        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Deploy and verify the lend oracle
    function _deployLendOracle(
        uint64 chainId,
        address morpho,
        address slc,
        address admin
    )
        internal
        returns (address lendAddr)
    {
        lendAddr = __deployContract(
            MORPHO_LEND_ORACLE_KEY,
            chainId,
            __getSalt(MORPHO_LEND_ORACLE_KEY),
            abi.encodePacked(type(MorphoLendYieldSourceOracle).creationCode, abi.encode(morpho, slc, admin))
        );

        MorphoLendYieldSourceOracle lendOracle = MorphoLendYieldSourceOracle(lendAddr);
        require(lendOracle.hasRole(lendOracle.DEFAULT_ADMIN_ROLE(), admin), "LEND_ADMIN_ROLE_MISMATCH");
        require(lendOracle.hasRole(lendOracle.MANAGER_ROLE(), admin), "LEND_MANAGER_ROLE_MISMATCH");
        require(address(lendOracle.MORPHO()) == morpho, "LEND_MORPHO_MISMATCH");

        console2.log("");
        console2.log("=== MorphoLendYieldSourceOracle Verified ===");
        console2.log("Address:", lendAddr);
        console2.log("");
    }

    /// @notice Deploy and verify the borrow oracle
    function _deployBorrowOracle(
        uint64 chainId,
        address morpho,
        address slc,
        address admin
    )
        internal
        returns (address borrowAddr)
    {
        borrowAddr = __deployContract(
            MORPHO_BORROW_ORACLE_KEY,
            chainId,
            __getSalt(MORPHO_BORROW_ORACLE_KEY),
            abi.encodePacked(type(MorphoBorrowCostOracle).creationCode, abi.encode(morpho, slc, admin))
        );

        MorphoBorrowCostOracle borrowOracle = MorphoBorrowCostOracle(borrowAddr);
        require(borrowOracle.hasRole(borrowOracle.DEFAULT_ADMIN_ROLE(), admin), "BORROW_ADMIN_ROLE_MISMATCH");
        require(borrowOracle.hasRole(borrowOracle.MANAGER_ROLE(), admin), "BORROW_MANAGER_ROLE_MISMATCH");
        require(address(borrowOracle.MORPHO()) == morpho, "BORROW_MORPHO_MISMATCH");

        console2.log("");
        console2.log("=== MorphoBorrowCostOracle Verified ===");
        console2.log("Address:", borrowAddr);
        console2.log("");
    }

    /// @notice Compute the SuperLedgerConfiguration address for the current environment
    function _getSuperLedgerConfiguration() internal view returns (address) {
        return __computeCoreContractAddress(SUPER_LEDGER_CONFIGURATION_KEY, "");
    }

    /// @notice Get Morpho singleton address for a given chain
    function _getMorphoAddress(uint64 chainId) internal pure returns (address) {
        if (chainId == MAINNET_CHAIN_ID) return MORPHO_MAINNET;
        if (chainId == BASE_CHAIN_ID) return MORPHO_BASE;
        if (chainId == OPTIMISM_CHAIN_ID) return MORPHO_OPTIMISM;
        if (chainId == ARBITRUM_CHAIN_ID) return MORPHO_ARBITRUM;
        if (chainId == BNB_CHAIN_ID) return MORPHO_BNB;
        return address(0);
    }

    /// @notice Write MorphoOracles-latest.json to script/output/{prod|staging}/{chainId}/
    function _writeMorphoOraclesJson(
        uint256 env,
        uint64 chainId,
        address lendAddr,
        address borrowAddr,
        address admin
    )
        internal
    {
        string memory root = vm.projectRoot();
        string memory envFolder = env == 0 ? "prod" : "staging";
        string memory outputFolder =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/"));

        // Create directory if needed
        vm.createDir(outputFolder, true);

        // Create JSON content
        string memory json = vm.serializeAddress("MorphoOracles", "MorphoLendYieldSourceOracle", lendAddr);
        json = vm.serializeAddress("MorphoOracles", "MorphoBorrowCostOracle", borrowAddr);
        json = vm.serializeAddress("MorphoOracles", "admin", admin);
        json = vm.serializeUint("MorphoOracles", "chainId", chainId);

        // Write to file
        string memory outputPath = string(abi.encodePacked(outputFolder, "MorphoOracles-latest.json"));
        vm.writeJson(json, outputPath);

        console2.log("");
        console2.log("JSON output written to:", outputPath);
    }

    /// @notice Compute deterministic address for MorphoLendYieldSourceOracle
    function _computeLendOracleAddress(
        address morpho,
        address superLedgerConfiguration,
        address admin
    )
        internal
        view
        returns (address)
    {
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(
                type(MorphoLendYieldSourceOracle).creationCode,
                abi.encode(morpho, superLedgerConfiguration, admin)
            ),
            __getSalt(MORPHO_LEND_ORACLE_KEY)
        );
    }

    /// @notice Compute deterministic address for MorphoBorrowCostOracle
    function _computeBorrowOracleAddress(
        address morpho,
        address superLedgerConfiguration,
        address admin
    )
        internal
        view
        returns (address)
    {
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(
                type(MorphoBorrowCostOracle).creationCode,
                abi.encode(morpho, superLedgerConfiguration, admin)
            ),
            __getSalt(MORPHO_BORROW_ORACLE_KEY)
        );
    }
}
