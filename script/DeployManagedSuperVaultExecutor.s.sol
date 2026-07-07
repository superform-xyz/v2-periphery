// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ManagedSuperVaultExecutor } from "../src/ManagedSuperVault/ManagedSuperVaultExecutor.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeployManagedSuperVaultExecutor
/// @notice Deployment script for ManagedSuperVaultExecutor - session key delegation for managed vault
///         controller functions. Deployed as a singleton, then added as a secondary manager per controller.
/// @dev Mirrors DeploySuperVaultExecutor; same constructor shape (superGovernor, admin, entryPoint).
contract DeployManagedSuperVaultExecutor is DeployV2Base {
    /// @notice Contract key for ManagedSuperVaultExecutor
    string internal constant EXECUTOR_KEY = "ManagedSuperVaultExecutor";

    /// @notice Canonical ERC-4337 v0.7 EntryPoint address (same on all EVM chains)
    address internal constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    /// @notice Deploy ManagedSuperVaultExecutor on a single chain
    function run(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);
        _deploy(env, chainId, superGovernor, SUPER_GOVERNOR_ADDRESS, branchName);
    }

    /// @notice Deploy ManagedSuperVaultExecutor on multiple chains
    function runMultiChain(
        uint256 env,
        uint64[] calldata chainIds,
        string calldata branchName
    )
        external
        broadcast(env)
    {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address admin = SUPER_GOVERNOR_ADDRESS;

        console2.log("====== Deploying ManagedSuperVaultExecutor (Multi-Chain) ======");
        console2.log("Environment:", env);
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

    /// @notice Check if ManagedSuperVaultExecutor is deployed
    function runCheck(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);
        address admin = SUPER_GOVERNOR_ADDRESS;

        console2.log("====== ManagedSuperVaultExecutor Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("Admin:", admin);

        address executorAddr = _computeAddress(env, superGovernor, admin);
        bool isDeployed = executorAddr.code.length > 0;

        console2.log("Computed address:", executorAddr);
        console2.log("Is deployed:", isDeployed);

        if (isDeployed) {
            ManagedSuperVaultExecutor executor = ManagedSuperVaultExecutor(payable(executorAddr));
            console2.log("Has DEFAULT_ADMIN_ROLE:", executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), admin));
            console2.log("SUPER_GOVERNOR:", address(executor.SUPER_GOVERNOR()));
            console2.log("ENTRY_POINT:", executor.ENTRY_POINT());
        }

        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
        string memory envFolder = env == 0 ? "prod" : (env == 1 ? branchName : "staging");
        string memory chainName = chainNames[chainId];
        string memory jsonPath = string(
            abi.encodePacked(
                root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/", chainName, "-latest.json"
            )
        );

        string memory json = vm.readFile(jsonPath);
        superGovernor = vm.parseJsonAddress(json, ".SuperGovernor");
        require(superGovernor != address(0), "SUPER_GOVERNOR_NOT_FOUND_IN_OUTPUT");

        if (superGovernor.code.length == 0) {
            console2.log("WARNING: SuperGovernor not deployed on chain", chainId);
        }
    }

    function _deploy(
        uint256 env,
        uint64 chainId,
        address superGovernor,
        address admin,
        string calldata branchName
    )
        internal
    {
        console2.log("====== Deploying ManagedSuperVaultExecutor ======");
        console2.log("Chain ID:", chainId);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("Admin:", admin);

        require(superGovernor != address(0), "INVALID_SUPER_GOVERNOR");
        require(admin != address(0), "INVALID_ADMIN");

        bytes memory bytecode = __getBytecode(EXECUTOR_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");

        address executorAddr = __deployContract(
            EXECUTOR_KEY,
            chainId,
            __getSalt(EXECUTOR_KEY),
            abi.encodePacked(bytecode, abi.encode(superGovernor, admin, ENTRY_POINT))
        );

        ManagedSuperVaultExecutor executor = ManagedSuperVaultExecutor(payable(executorAddr));
        require(executor.hasRole(executor.DEFAULT_ADMIN_ROLE(), admin), "ADMIN_ROLE_MISMATCH");
        require(address(executor.SUPER_GOVERNOR()) == superGovernor, "SUPER_GOVERNOR_MISMATCH");
        require(executor.ENTRY_POINT() == ENTRY_POINT, "ENTRY_POINT_MISMATCH");

        _writeExecutorJson(env, chainId, executorAddr, branchName);

        console2.log("ManagedSuperVaultExecutor deployed at:", executorAddr);
        console2.log("");
        console2.log("NEXT STEP: add the executor as a secondary manager per controller via");
        console2.log("ManagedSuperVaultAggregator.addSecondaryManager(controller, executorAddr), then grant");
        console2.log("session keys via ManagedSuperVaultExecutor.grantSessionKey(controller, key, expiry, perms).");
        console2.log("====== Deployment Complete ======");
    }

    function _writeExecutorJson(
        uint256 env,
        uint64 chainId,
        address executorAddr,
        string calldata branchName
    )
        internal
    {
        string memory root = vm.projectRoot();
        string memory envFolder = env == 0 ? "prod" : (env == 1 ? branchName : "staging");
        string memory chainName = chainNames[chainId];
        string memory outputFolder =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/"));

        vm.createDir(outputFolder, true);
        string memory outputPath = string(abi.encodePacked(outputFolder, chainName, "-latest.json"));
        vm.writeJson(vm.toString(executorAddr), outputPath, ".ManagedSuperVaultExecutor");

        console2.log("ManagedSuperVaultExecutor merged into:", outputPath);
    }

    function _computeAddress(uint256 env, address superGovernor, address admin) internal view returns (address) {
        bytes memory bytecode = __getBytecode(EXECUTOR_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(bytecode, abi.encode(superGovernor, admin, ENTRY_POINT)), __getSalt(EXECUTOR_KEY)
        );
    }
}
