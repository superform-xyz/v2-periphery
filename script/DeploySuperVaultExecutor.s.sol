// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperVaultExecutor } from "../src/SuperVault/SuperVaultExecutor.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeploySuperVaultExecutor
/// @notice Deployment script for SuperVaultExecutor - session key delegation for secondary manager functions
/// @dev Deploys across multiple chains with deterministic addresses
contract DeploySuperVaultExecutor is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for SuperVaultExecutor
    string internal constant EXECUTOR_KEY = "SuperVaultExecutor";

    /// @notice Canonical ERC-4337 v0.7 EntryPoint address (same on all EVM chains)
    address internal constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy SuperVaultExecutor on a single chain
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function run(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);
        address admin = SUPER_GOVERNOR_ADDRESS;
        _deploy(env, chainId, superGovernor, admin, branchName);
    }

    /// @notice Deploy SuperVaultExecutor on multiple chains
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainIds Array of chain IDs to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runMultiChain(uint256 env, uint64[] calldata chainIds, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address admin = SUPER_GOVERNOR_ADDRESS;

        console2.log("====== Deploying SuperVaultExecutor (Multi-Chain) ======");
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("Admin (SUPER_GOVERNOR_ADDRESS):", admin);
        console2.log("Number of chains:", chainIds.length);
        console2.log("");

        for (uint256 i = 0; i < chainIds.length; i++) {
            address superGovernor = _getSuperGovernorForEnv(env, chainIds[i], branchName);
            _deploy(env, chainIds[i], superGovernor, admin, branchName);
            console2.log("");
        }

        console2.log("====== Multi-Chain Deployment Complete ======");
    }

    /// @notice Check if SuperVaultExecutor is deployed
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runCheck(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);
        address admin = SUPER_GOVERNOR_ADDRESS;

        console2.log("====== SuperVaultExecutor Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("SuperGovernor:", superGovernor);
        console2.log("Admin (SUPER_GOVERNOR_ADDRESS):", admin);
        console2.log("");

        address executorAddr = _computeAddress(env, superGovernor, admin);
        bool isDeployed = executorAddr.code.length > 0;

        console2.log("Computed address:", executorAddr);
        console2.log("Is deployed:", isDeployed);

        if (isDeployed) {
            SuperVaultExecutor executor = SuperVaultExecutor(payable(executorAddr));
            console2.log("");
            console2.log("=== Executor State ===");
            console2.log("Has DEFAULT_ADMIN_ROLE:", executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), admin));
            console2.log("SUPER_GOVERNOR:", address(executor.SUPER_GOVERNOR()));
            console2.log("ENTRY_POINT:", executor.ENTRY_POINT());
            console2.log("SUPER_VAULT_AGGREGATOR_KEY:", vm.toString(executor.SUPER_VAULT_AGGREGATOR_KEY()));
            console2.log("MAX_BATCH_SIZE:", executor.MAX_BATCH_SIZE());
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get SuperGovernor address for the given chain and environment
    /// @dev Reads the deployed SuperGovernor address from the output JSON files.
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param branchName Branch name for vnet deployments
    /// @return superGovernor The SuperGovernor address
    function _getSuperGovernorForEnv(
        uint256 env,
        uint64 chainId,
        string calldata branchName
    )
        internal
        view
        returns (address superGovernor)
    {
        string memory root = vm.projectRoot();
        string memory envFolder;
        if (env == 0) {
            envFolder = "prod";
        } else if (env == 1) {
            envFolder = branchName;
        } else {
            envFolder = "staging";
        }

        string memory chainName = chainNames[chainId];
        string memory jsonPath =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/", chainName, "-latest.json"));

        string memory json = vm.readFile(jsonPath);
        superGovernor = vm.parseJsonAddress(json, ".SuperGovernor");

        require(superGovernor != address(0), "SUPER_GOVERNOR_NOT_FOUND_IN_OUTPUT");

        // Validate the address has code on-chain
        if (superGovernor.code.length == 0) {
            console2.log("WARNING: SuperGovernor not deployed on chain", chainId);
            console2.log("Address from output JSON:", superGovernor);
        }
    }

    /// @notice Internal deployment function
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param superGovernor SuperGovernor address
    /// @param admin Admin address (receives DEFAULT_ADMIN_ROLE)
    /// @param branchName Branch name for vnet deployments
    function _deploy(
        uint256 env,
        uint64 chainId,
        address superGovernor,
        address admin,
        string calldata branchName
    )
        internal
    {
        _setBaseConfiguration(env, branchName);

        console2.log("====== Deploying SuperVaultExecutor ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("SuperGovernor:", superGovernor);
        console2.log("Admin:", admin);
        console2.log("");

        // Validate inputs
        require(superGovernor != address(0), "INVALID_SUPER_GOVERNOR");
        require(admin != address(0), "INVALID_ADMIN");

        // Get bytecode from generated artifacts
        bytes memory bytecode = __getBytecode(EXECUTOR_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");

        // Deploy
        address executorAddr = __deployContract(
            EXECUTOR_KEY,
            chainId,
            __getSalt(EXECUTOR_KEY),
            abi.encodePacked(bytecode, abi.encode(superGovernor, admin, ENTRY_POINT))
        );

        // Verify deployment
        SuperVaultExecutor executor = SuperVaultExecutor(payable(executorAddr));
        require(executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), admin), "ADMIN_ROLE_MISMATCH");
        require(address(executor.SUPER_GOVERNOR()) == superGovernor, "SUPER_GOVERNOR_MISMATCH");
        require(executor.ENTRY_POINT() == ENTRY_POINT, "ENTRY_POINT_MISMATCH");

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("SuperVaultExecutor deployed at:", executorAddr);
        console2.log("Admin verified:", admin);
        console2.log("SuperGovernor verified:", superGovernor);
        console2.log("EntryPoint verified:", ENTRY_POINT);
        console2.log("SUPER_VAULT_AGGREGATOR_KEY:", vm.toString(executor.SUPER_VAULT_AGGREGATOR_KEY()));

        // Write JSON output
        _writeExecutorJson(env, chainId, executorAddr, branchName);

        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Merge SuperVaultExecutor address into {ChainName}-latest.json
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param executorAddr Deployed executor address
    /// @param branchName Branch name for vnet deployments
    function _writeExecutorJson(
        uint256 env,
        uint64 chainId,
        address executorAddr,
        string calldata branchName
    )
        internal
    {
        string memory root = vm.projectRoot();
        string memory envFolder;
        if (env == 0) {
            envFolder = "prod";
        } else if (env == 1) {
            envFolder = branchName;
        } else {
            envFolder = "staging";
        }

        string memory chainName = chainNames[chainId];
        string memory outputFolder =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/"));

        // Create directory if it doesn't exist
        vm.createDir(outputFolder, true);

        string memory outputPath = string(abi.encodePacked(outputFolder, chainName, "-latest.json"));

        // Merge SuperVaultExecutor address into existing JSON
        vm.writeJson(vm.toString(executorAddr), outputPath, ".SuperVaultExecutor");

        console2.log("");
        console2.log("SuperVaultExecutor merged into:", outputPath);
    }

    /// @notice Compute the deterministic address for SuperVaultExecutor
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param superGovernor SuperGovernor address
    /// @param admin Admin address
    function _computeAddress(uint256 env, address superGovernor, address admin) internal view returns (address) {
        bytes memory bytecode = __getBytecode(EXECUTOR_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(bytecode, abi.encode(superGovernor, admin, ENTRY_POINT)), __getSalt(EXECUTOR_KEY)
        );
    }
}
