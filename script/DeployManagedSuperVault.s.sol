// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ManagedSuperVault } from "../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { ManagedSuperVaultEscrow } from "../src/ManagedSuperVault/ManagedSuperVaultEscrow.sol";
import { ManagedSuperVaultAggregator } from "../src/ManagedSuperVault/ManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultAggregator } from "../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeployManagedSuperVault
/// @notice Deployment script for the ManagedSuperVault contract family: the vault/controller/escrow
///         implementations and the ManagedSuperVaultAggregator sibling factory.
/// @dev Deploys across multiple chains with deterministic addresses, mirroring DeploySuperVaultExecutor.
///      The aggregator must be registered in SuperGovernor under the MANAGED_SUPER_VAULT_AGGREGATOR key
///      before the family is usable — run the `runRegister` entrypoint with the SUPER_GOVERNOR_ROLE account.
contract DeployManagedSuperVault is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    string internal constant VAULT_KEY = "ManagedSuperVault";
    string internal constant CONTROLLER_KEY = "ManagedSuperVaultController";
    string internal constant ESCROW_KEY = "ManagedSuperVaultEscrow";
    string internal constant AGGREGATOR_KEY = "ManagedSuperVaultAggregator";

    /// @notice SuperGovernor address-registry key for the managed aggregator
    ///         (must match ManagedSuperVaultController / ManagedSuperVaultExecutor)
    bytes32 internal constant MANAGED_AGGREGATOR_REGISTRY_KEY = keccak256("MANAGED_SUPER_VAULT_AGGREGATOR");

    /// @notice Local record of the deployed implementations for a single chain deploy
    struct ManagedDeployment {
        address vaultImpl;
        address controllerImpl;
        address escrowImpl;
        address aggregator;
    }

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy the Managed SuperVault family on a single chain
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function run(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);
        _deploy(env, chainId, superGovernor, branchName);
    }

    /// @notice Deploy the Managed SuperVault family on multiple chains
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainIds Array of chain IDs to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
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

        console2.log("====== Deploying ManagedSuperVault family (Multi-Chain) ======");
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("Number of chains:", chainIds.length);
        console2.log("");

        for (uint256 i = 0; i < chainIds.length; i++) {
            address superGovernor = _getSuperGovernorForEnv(env, chainIds[i], branchName);
            _deploy(env, chainIds[i], superGovernor, branchName);
            console2.log("");
        }

        console2.log("====== Multi-Chain Deployment Complete ======");
    }

    /// @notice Register the deployed managed aggregator in SuperGovernor's address registry
    /// @dev MUST be run by the SUPER_GOVERNOR_ROLE holder. The vault/controller/executor resolve the
    ///      aggregator via this key, so the family is inert until this is set.
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to configure
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runRegister(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);

        address aggregator = _readDeployedAddress(env, chainId, branchName, AGGREGATOR_KEY);
        require(aggregator != address(0) && aggregator.code.length > 0, "AGGREGATOR_NOT_DEPLOYED");

        console2.log("====== Registering ManagedSuperVaultAggregator ======");
        console2.log("Chain ID:", chainId);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("Aggregator:", aggregator);

        address current = SuperGovernor(superGovernor).getAddress(MANAGED_AGGREGATOR_REGISTRY_KEY);
        if (current == aggregator) {
            console2.log("Already registered, skipping...");
        } else {
            SuperGovernor(superGovernor).setAddress(MANAGED_AGGREGATOR_REGISTRY_KEY, aggregator);
            console2.log("Registered MANAGED_SUPER_VAULT_AGGREGATOR ->", aggregator);
        }

        console2.log("====== Registration Complete ======");
    }

    /// @notice Check deployment + registration status
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runCheck(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);

        console2.log("====== ManagedSuperVault Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("");

        ManagedDeployment memory computed = _computeAddresses(env, superGovernor);

        _logCheck(VAULT_KEY, computed.vaultImpl);
        _logCheck(CONTROLLER_KEY, computed.controllerImpl);
        _logCheck(ESCROW_KEY, computed.escrowImpl);
        _logCheck(AGGREGATOR_KEY, computed.aggregator);

        address registered = SuperGovernor(superGovernor).getAddress(MANAGED_AGGREGATOR_REGISTRY_KEY);
        console2.log("");
        console2.log("Registry MANAGED_SUPER_VAULT_AGGREGATOR:", registered);
        console2.log("Registration matches computed aggregator:", registered == computed.aggregator);

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get SuperGovernor address for the given chain and environment (reads deployment output JSON)
    function _getSuperGovernorForEnv(
        uint256 env,
        uint64 chainId,
        string calldata branchName
    )
        internal
        view
        returns (address superGovernor)
    {
        string memory jsonPath = _outputPath(env, chainId, branchName);
        string memory json = vm.readFile(jsonPath);
        superGovernor = vm.parseJsonAddress(json, ".SuperGovernor");

        require(superGovernor != address(0), "SUPER_GOVERNOR_NOT_FOUND_IN_OUTPUT");

        if (superGovernor.code.length == 0) {
            console2.log("WARNING: SuperGovernor not deployed on chain", chainId);
            console2.log("Address from output JSON:", superGovernor);
        }
    }

    /// @notice Internal deployment: 3 implementations + aggregator, deterministic + idempotent
    function _deploy(uint256 env, uint64 chainId, address superGovernor, string calldata branchName) internal {
        console2.log("====== Deploying ManagedSuperVault family ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("SuperGovernor:", superGovernor);
        console2.log("");

        require(superGovernor != address(0), "INVALID_SUPER_GOVERNOR");

        ManagedDeployment memory d;

        // Deploy implementations first (constructor: superGovernor; escrow has none)
        d.vaultImpl = __deployContract(
            VAULT_KEY,
            chainId,
            __getSalt(VAULT_KEY),
            abi.encodePacked(_bytecode(VAULT_KEY, env), abi.encode(superGovernor))
        );
        d.controllerImpl = __deployContract(
            CONTROLLER_KEY,
            chainId,
            __getSalt(CONTROLLER_KEY),
            abi.encodePacked(_bytecode(CONTROLLER_KEY, env), abi.encode(superGovernor))
        );
        d.escrowImpl = __deployContract(ESCROW_KEY, chainId, __getSalt(ESCROW_KEY), _bytecode(ESCROW_KEY, env));

        // Deploy the aggregator (constructor: superGovernor, vaultImpl, controllerImpl, escrowImpl)
        d.aggregator = __deployContract(
            AGGREGATOR_KEY,
            chainId,
            __getSalt(AGGREGATOR_KEY),
            abi.encodePacked(
                _bytecode(AGGREGATOR_KEY, env), abi.encode(superGovernor, d.vaultImpl, d.controllerImpl, d.escrowImpl)
            )
        );

        // Verify aggregator wiring
        ManagedSuperVaultAggregator aggregator = ManagedSuperVaultAggregator(d.aggregator);
        require(address(aggregator.SUPER_GOVERNOR()) == superGovernor, "SUPER_GOVERNOR_MISMATCH");
        require(aggregator.VAULT_IMPLEMENTATION() == d.vaultImpl, "VAULT_IMPL_MISMATCH");
        require(aggregator.CONTROLLER_IMPLEMENTATION() == d.controllerImpl, "CONTROLLER_IMPL_MISMATCH");
        require(aggregator.ESCROW_IMPLEMENTATION() == d.escrowImpl, "ESCROW_IMPL_MISMATCH");

        _writeManagedJson(env, chainId, branchName, d);

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("ManagedSuperVault impl:", d.vaultImpl);
        console2.log("ManagedSuperVaultController impl:", d.controllerImpl);
        console2.log("ManagedSuperVaultEscrow impl:", d.escrowImpl);
        console2.log("ManagedSuperVaultAggregator:", d.aggregator);
        console2.log("");
        console2.log("NEXT STEP: run `runRegister` with the SUPER_GOVERNOR_ROLE account to register the");
        console2.log("aggregator under MANAGED_SUPER_VAULT_AGGREGATOR before creating any managed vaults.");
        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Compute deterministic addresses for the whole family (for checks)
    function _computeAddresses(uint256 env, address superGovernor) internal view returns (ManagedDeployment memory d) {
        d.vaultImpl = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_bytecode(VAULT_KEY, env), abi.encode(superGovernor)), __getSalt(VAULT_KEY)
        );
        d.controllerImpl = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_bytecode(CONTROLLER_KEY, env), abi.encode(superGovernor)), __getSalt(CONTROLLER_KEY)
        );
        d.escrowImpl = DeterministicDeployerLib.computeAddress(_bytecode(ESCROW_KEY, env), __getSalt(ESCROW_KEY));
        d.aggregator = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(
                _bytecode(AGGREGATOR_KEY, env), abi.encode(superGovernor, d.vaultImpl, d.controllerImpl, d.escrowImpl)
            ),
            __getSalt(AGGREGATOR_KEY)
        );
    }

    /// @notice Fetch bytecode from the env-appropriate locked artifacts, reverting if missing
    function _bytecode(string memory contractName, uint256 env) internal view returns (bytes memory bytecode) {
        bytecode = __getBytecode(contractName, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
    }

    function _logCheck(string memory name, address addr) internal view {
        console2.log(name, addr, "deployed:", addr.code.length > 0);
    }

    /// @notice Path to the deployment output JSON for a chain/env
    function _outputPath(uint256 env, uint64 chainId, string calldata branchName)
        internal
        view
        returns (string memory)
    {
        string memory root = vm.projectRoot();
        string memory envFolder = env == 0 ? "prod" : (env == 1 ? branchName : "staging");
        string memory chainName = chainNames[chainId];
        return string(
            abi.encodePacked(
                root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/", chainName, "-latest.json"
            )
        );
    }

    /// @notice Read a previously-deployed managed address from the output JSON
    function _readDeployedAddress(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        string memory key
    )
        internal
        view
        returns (address)
    {
        string memory json = vm.readFile(_outputPath(env, chainId, branchName));
        return vm.parseJsonAddress(json, string(abi.encodePacked(".", key)));
    }

    /// @notice Merge the four managed addresses into {ChainName}-latest.json
    function _writeManagedJson(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        ManagedDeployment memory d
    )
        internal
    {
        string memory outputPath = _outputPath(env, chainId, branchName);
        vm.writeJson(vm.toString(d.vaultImpl), outputPath, string(abi.encodePacked(".", VAULT_KEY)));
        vm.writeJson(vm.toString(d.controllerImpl), outputPath, string(abi.encodePacked(".", CONTROLLER_KEY)));
        vm.writeJson(vm.toString(d.escrowImpl), outputPath, string(abi.encodePacked(".", ESCROW_KEY)));
        vm.writeJson(vm.toString(d.aggregator), outputPath, string(abi.encodePacked(".", AGGREGATOR_KEY)));

        console2.log("");
        console2.log("Managed family addresses merged into:", outputPath);
    }
}
