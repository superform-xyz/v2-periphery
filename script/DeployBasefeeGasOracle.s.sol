// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { BasefeeGasOracle } from "../src/oracles/BasefeeGasOracle.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeployBasefeeGasOracle
/// @notice Deployment script for BasefeeGasOracle - a basefee-derived gas price oracle for Ethereum mainnet
/// @dev Replaces the deprecated Chainlink Fast Gas feed for SuperOracle's GAS_QUOTE -> WEI_QUOTE pair.
///      Takes SEPARATE admin and gasManager addresses: collapsing both roles onto one key is the
///      anti-pattern this script deliberately avoids (see specs/basefee-gas-oracle).
contract DeployBasefeeGasOracle is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for BasefeeGasOracle
    string internal constant BASEFEE_GAS_ORACLE_KEY = "BasefeeGasOracle";

    /// @notice Default basefee multiplier: 2x - deliberate over-recovery
    /// @dev Charges ~1.3-1.5x what the Chainlink Fast Gas feed quotes (Fast Gas runs ~1.5x raw
    ///      basefee), while staying within the 2x migration acceptance band vs today's cost.
    ///      Used for deterministic address computation and must match the deployed oracle.
    uint256 internal constant DEFAULT_MULTIPLIER_BPS = 20_000;

    /// @notice Default priority fee addend: 0.001 gwei
    /// @dev ~10x the node-suggested tip at spec time; negligible vs mainnet basefee.
    uint256 internal constant DEFAULT_PRIORITY_FEE_WEI = 1_000_000;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy BasefeeGasOracle with default calibration
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param admin Address receiving DEFAULT_ADMIN_ROLE (protocol multisig)
    /// @param gasManager Address receiving GAS_MANAGER_ROLE (must differ from admin)
    function run(uint256 env, uint64 chainId, address admin, address gasManager) external broadcast(env) {
        _deploy(env, chainId, DEFAULT_MULTIPLIER_BPS, DEFAULT_PRIORITY_FEE_WEI, admin, gasManager);
    }

    /// @notice Deploy BasefeeGasOracle with custom calibration
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param multiplierBps Basefee multiplier in basis points (bounded by the contract)
    /// @param priorityFeeWei Priority fee addend in wei (bounded by the contract)
    /// @param admin Address receiving DEFAULT_ADMIN_ROLE (protocol multisig)
    /// @param gasManager Address receiving GAS_MANAGER_ROLE (must differ from admin)
    function run(
        uint256 env,
        uint64 chainId,
        uint256 multiplierBps,
        uint256 priorityFeeWei,
        address admin,
        address gasManager
    )
        external
        broadcast(env)
    {
        _deploy(env, chainId, multiplierBps, priorityFeeWei, admin, gasManager);
    }

    /// @notice Check if BasefeeGasOracle is deployed and log its live state (default calibration)
    /// @dev The CREATE2 address commits to the constructor args; deployments made via the
    ///      custom-calibration run overload live at a different address - use the runCheck
    ///      overload below with the same knobs in that case.
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param admin Admin address used in deployment
    /// @param gasManager Gas manager address used in deployment
    function runCheck(uint256 env, uint64 chainId, address admin, address gasManager) external broadcast(env) {
        _runCheck(env, chainId, DEFAULT_MULTIPLIER_BPS, DEFAULT_PRIORITY_FEE_WEI, admin, gasManager);
    }

    /// @notice Check a custom-calibration deployment (knobs must match the deployed constructor args)
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param multiplierBps Multiplier used at deployment
    /// @param priorityFeeWei Priority fee used at deployment
    /// @param admin Admin address used in deployment
    /// @param gasManager Gas manager address used in deployment
    function runCheck(
        uint256 env,
        uint64 chainId,
        uint256 multiplierBps,
        uint256 priorityFeeWei,
        address admin,
        address gasManager
    )
        external
        broadcast(env)
    {
        _runCheck(env, chainId, multiplierBps, priorityFeeWei, admin, gasManager);
    }

    /// @notice Internal check implementation
    function _runCheck(
        uint256 env,
        uint64 chainId,
        uint256 multiplierBps,
        uint256 priorityFeeWei,
        address admin,
        address gasManager
    )
        internal
    {
        _setBaseConfiguration(env, "");

        console2.log("====== BasefeeGasOracle Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Admin:", admin);
        console2.log("Gas Manager:", gasManager);
        console2.log("");

        address oracleAddr = _computeAddress(multiplierBps, priorityFeeWei, admin, gasManager);
        bool isDeployed = oracleAddr.code.length > 0;

        console2.log("Computed address:", oracleAddr);
        console2.log("Is deployed:", isDeployed);

        if (isDeployed) {
            BasefeeGasOracle oracle = BasefeeGasOracle(oracleAddr);
            console2.log("");
            console2.log("=== Oracle State ===");
            console2.log("Admin has DEFAULT_ADMIN_ROLE:", oracle.hasRole(oracle.DEFAULT_ADMIN_ROLE(), admin));
            console2.log("Gas manager has GAS_MANAGER_ROLE:", oracle.hasRole(oracle.GAS_MANAGER_ROLE(), gasManager));
            console2.log("Decimals:", oracle.decimals());
            console2.log("Description:", oracle.description());
            console2.log("Multiplier (bps):", oracle.multiplierBps());
            console2.log("Priority fee (wei):", oracle.priorityFeeWei());
            console2.log("Params last updated:", oracle.paramsLastUpdatedAt());
            console2.log("Answer (wei per gas; 0 in fee-field-less eth_call):", uint256(oracle.latestAnswer()));
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal deployment function
    function _deploy(
        uint256 env,
        uint64 chainId,
        uint256 multiplierBps,
        uint256 priorityFeeWei,
        address admin,
        address gasManager
    )
        internal
    {
        _setBaseConfiguration(env, "");

        console2.log("====== Deploying BasefeeGasOracle ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Multiplier (bps):", multiplierBps);
        console2.log("Priority fee (wei):", priorityFeeWei);
        console2.log("Admin:", admin);
        console2.log("Gas Manager:", gasManager);
        console2.log("");

        // Validate inputs (contract constructor re-validates the knob bounds)
        require(admin != address(0), "INVALID_ADMIN");
        require(gasManager != address(0), "INVALID_GAS_MANAGER");
        require(admin != gasManager, "ADMIN_MUST_DIFFER_FROM_GAS_MANAGER");

        // The oracle's semantics are Ethereum-mainnet-specific: on OP-stack L2s block.basefee
        // excludes L1 data fees, so this oracle would structurally undercharge there. Warning
        // only (not a revert) so mainnet-forking vnet/staging environments keep working.
        if (chainId != 1) {
            console2.log("[WARNING] BasefeeGasOracle is designed for Ethereum mainnet (chainId 1).");
            console2.log("[WARNING] On L2s block.basefee excludes L1 data fees - do not deploy there.");
        }

        // Deploy
        address oracleAddr = __deployContract(
            BASEFEE_GAS_ORACLE_KEY,
            chainId,
            __getSalt(BASEFEE_GAS_ORACLE_KEY),
            abi.encodePacked(
                type(BasefeeGasOracle).creationCode, abi.encode(multiplierBps, priorityFeeWei, admin, gasManager)
            )
        );

        // Verify deployment
        BasefeeGasOracle oracle = BasefeeGasOracle(oracleAddr);
        require(oracle.hasRole(oracle.DEFAULT_ADMIN_ROLE(), admin), "ADMIN_ROLE_MISMATCH");
        require(oracle.hasRole(oracle.GAS_MANAGER_ROLE(), gasManager), "GAS_MANAGER_ROLE_MISMATCH");
        require(!oracle.hasRole(oracle.GAS_MANAGER_ROLE(), admin), "ADMIN_SHOULD_NOT_HOLD_GAS_MANAGER");
        require(oracle.multiplierBps() == multiplierBps, "MULTIPLIER_MISMATCH");
        require(oracle.priorityFeeWei() == priorityFeeWei, "PRIORITY_FEE_MISMATCH");
        require(oracle.decimals() == 0, "DECIMALS_MISMATCH");

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("Oracle deployed at:", oracleAddr);
        console2.log("Admin verified:", admin);
        console2.log("Gas manager verified:", gasManager);
        console2.log("Multiplier verified (bps):", oracle.multiplierBps());
        console2.log("Priority fee verified (wei):", oracle.priorityFeeWei());

        // Write JSON output
        _writeBasefeeGasOracleJson(env, chainId, oracleAddr);

        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Merge BasefeeGasOracle address into {ChainName}-latest.json
    function _writeBasefeeGasOracleJson(uint256 env, uint64 chainId, address oracleAddr) internal {
        string memory root = vm.projectRoot();
        string memory envFolder = env == 0 ? "prod" : "staging";
        string memory outputFolder =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/"));

        vm.createDir(outputFolder, true);

        string memory chainName = chainNames[chainId];
        require(bytes(chainName).length > 0, "UNSUPPORTED_CHAIN_NAME");

        string memory outputPath = string(abi.encodePacked(outputFolder, chainName, "-latest.json"));
        vm.writeJson(vm.toString(oracleAddr), outputPath, ".BasefeeGasOracle");

        console2.log("");
        console2.log("BasefeeGasOracle merged into:", outputPath);
    }

    /// @notice Compute the deterministic address for BasefeeGasOracle
    function _computeAddress(
        uint256 multiplierBps,
        uint256 priorityFeeWei,
        address admin,
        address gasManager
    )
        internal
        view
        returns (address)
    {
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(
                type(BasefeeGasOracle).creationCode, abi.encode(multiplierBps, priorityFeeWei, admin, gasManager)
            ),
            __getSalt(BASEFEE_GAS_ORACLE_KEY)
        );
    }
}
