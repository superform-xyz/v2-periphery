// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ManagedSuperVaultAggregator } from "../src/ManagedSuperVault/ManagedSuperVaultAggregator.sol";
import { ManagedNAVOracle } from "../src/ManagedSuperVault/ManagedNAVOracle.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeployManagedSuperVault
/// @notice Deployment script for the Managed SuperVault family (reuse architecture): the forked
///         vault/strategy implementations, the deposit queue implementation, the reused main-family
///         escrow implementation, the ManagedSuperVaultAggregator, and the ManagedNAVOracle.
/// @dev Deploys across multiple chains with deterministic addresses. Two wiring steps gate go-live,
///      both run via `runRegister` with the SUPER_GOVERNOR_ROLE account:
///      (1) SuperGovernor.setAddress(MANAGED_SUPER_VAULT_AGGREGATOR, aggregator) — discovery-only
///          (managed clones store their aggregator at initialize, unlike the main family);
///      (2) aggregator.setInitialNavOracle(oracle) — the family is inert (createVault and forwardPPS
///          revert) until the oracle is wired. Not a constructor arg because the oracle's constructor
///          takes the aggregator address (circular under CREATE2).
contract DeployManagedSuperVault is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    string internal constant VAULT_KEY = "ManagedSuperVault";
    string internal constant STRATEGY_KEY = "ManagedSuperVaultStrategy";
    string internal constant QUEUE_KEY = "ManagedSuperVaultDepositQueue";
    string internal constant AGGREGATOR_KEY = "ManagedSuperVaultAggregator";
    string internal constant ORACLE_KEY = "ManagedNAVOracle";

    /// @notice The escrow implementation is REUSED from the main SuperVault family: same bytecode and
    ///         salt key resolve to the same deterministic address, so on chains where the main family
    ///         is deployed this is a no-op skip
    string internal constant ESCROW_KEY = "SuperVaultEscrow";

    /// @notice SuperGovernor address-registry key for the managed aggregator (discovery-only)
    bytes32 internal constant MANAGED_AGGREGATOR_REGISTRY_KEY = keccak256("MANAGED_SUPER_VAULT_AGGREGATOR");

    /// @notice Local record of the deployed contracts for a single chain deploy
    struct ManagedDeployment {
        address vaultImpl;
        address strategyImpl;
        address escrowImpl;
        address queueImpl;
        address aggregator;
        address navOracle;
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

    /// @notice Register the managed aggregator in SuperGovernor's registry AND wire the NAV oracle
    /// @dev MUST be run by the SUPER_GOVERNOR_ROLE holder. The family is inert until the oracle is
    ///      wired; the registry key is discovery-only. Both steps are idempotent.
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to configure
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runRegister(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address superGovernor = _getSuperGovernorForEnv(env, chainId, branchName);

        address aggregator = _readDeployedAddress(env, chainId, branchName, AGGREGATOR_KEY);
        address navOracle = _readDeployedAddress(env, chainId, branchName, ORACLE_KEY);
        require(aggregator != address(0) && aggregator.code.length > 0, "AGGREGATOR_NOT_DEPLOYED");
        require(navOracle != address(0) && navOracle.code.length > 0, "NAV_ORACLE_NOT_DEPLOYED");
        // Re-verify the pair actually belongs together and to this SuperGovernor before wiring —
        // guards against a stale or hand-edited output JSON pointing at the wrong contracts.
        require(
            address(ManagedSuperVaultAggregator(aggregator).SUPER_GOVERNOR()) == superGovernor,
            "AGGREGATOR_GOVERNOR_MISMATCH"
        );
        require(ManagedNAVOracle(navOracle).MANAGED_AGGREGATOR() == aggregator, "ORACLE_AGGREGATOR_MISMATCH");

        console2.log("====== Registering ManagedSuperVault family ======");
        console2.log("Chain ID:", chainId);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("Aggregator:", aggregator);
        console2.log("NAV Oracle:", navOracle);

        address current = SuperGovernor(superGovernor).getAddress(MANAGED_AGGREGATOR_REGISTRY_KEY);
        if (current == aggregator) {
            console2.log("Registry key already set, skipping...");
        } else {
            SuperGovernor(superGovernor).setAddress(MANAGED_AGGREGATOR_REGISTRY_KEY, aggregator);
            console2.log("Registered MANAGED_SUPER_VAULT_AGGREGATOR ->", aggregator);
        }

        address wiredOracle = ManagedSuperVaultAggregator(aggregator).navOracle();
        if (wiredOracle == navOracle) {
            console2.log("NAV oracle already wired, skipping...");
        } else {
            require(wiredOracle == address(0), "DIFFERENT_NAV_ORACLE_WIRED");
            ManagedSuperVaultAggregator(aggregator).setInitialNavOracle(navOracle);
            console2.log("Wired NAV oracle ->", navOracle);
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
        _logCheck(STRATEGY_KEY, computed.strategyImpl);
        _logCheck(ESCROW_KEY, computed.escrowImpl);
        _logCheck(QUEUE_KEY, computed.queueImpl);
        _logCheck(AGGREGATOR_KEY, computed.aggregator);
        _logCheck(ORACLE_KEY, computed.navOracle);

        address registered = SuperGovernor(superGovernor).getAddress(MANAGED_AGGREGATOR_REGISTRY_KEY);
        console2.log("");
        console2.log("Registry MANAGED_SUPER_VAULT_AGGREGATOR:", registered);
        console2.log("Registration matches computed aggregator:", registered == computed.aggregator);
        if (computed.aggregator.code.length > 0) {
            address wiredOracle = ManagedSuperVaultAggregator(computed.aggregator).navOracle();
            console2.log("Wired NAV oracle:", wiredOracle);
            console2.log("Oracle wiring matches computed oracle:", wiredOracle == computed.navOracle);
        }

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

    /// @notice Internal deployment: 4 implementations + aggregator + NAV oracle, deterministic + idempotent
    /// @dev The escrow deploy is a no-op skip on chains where the main family already deployed it
    ///      (same bytecode + salt => same address)
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

        // Deploy implementations first (vault/strategy constructor: superGovernor; escrow/queue have none)
        d.vaultImpl = __deployContract(
            VAULT_KEY,
            chainId,
            __getSalt(VAULT_KEY),
            abi.encodePacked(_bytecode(VAULT_KEY, env), abi.encode(superGovernor))
        );
        d.strategyImpl = __deployContract(
            STRATEGY_KEY,
            chainId,
            __getSalt(STRATEGY_KEY),
            abi.encodePacked(_bytecode(STRATEGY_KEY, env), abi.encode(superGovernor))
        );
        d.escrowImpl = __deployContract(ESCROW_KEY, chainId, __getSalt(ESCROW_KEY), _bytecode(ESCROW_KEY, env));
        d.queueImpl = __deployContract(QUEUE_KEY, chainId, __getSalt(QUEUE_KEY), _bytecode(QUEUE_KEY, env));

        // Deploy the aggregator (constructor: superGovernor + 4 implementation addresses)
        d.aggregator = __deployContract(
            AGGREGATOR_KEY,
            chainId,
            __getSalt(AGGREGATOR_KEY),
            abi.encodePacked(
                _bytecode(AGGREGATOR_KEY, env),
                abi.encode(superGovernor, d.vaultImpl, d.strategyImpl, d.escrowImpl, d.queueImpl)
            )
        );

        // Deploy the NAV oracle (constructor: aggregator)
        d.navOracle = __deployContract(
            ORACLE_KEY,
            chainId,
            __getSalt(ORACLE_KEY),
            abi.encodePacked(_bytecode(ORACLE_KEY, env), abi.encode(d.aggregator))
        );

        // Verify wiring
        ManagedSuperVaultAggregator aggregator = ManagedSuperVaultAggregator(d.aggregator);
        require(address(aggregator.SUPER_GOVERNOR()) == superGovernor, "SUPER_GOVERNOR_MISMATCH");
        require(aggregator.VAULT_IMPLEMENTATION() == d.vaultImpl, "VAULT_IMPL_MISMATCH");
        require(aggregator.STRATEGY_IMPLEMENTATION() == d.strategyImpl, "STRATEGY_IMPL_MISMATCH");
        require(aggregator.ESCROW_IMPLEMENTATION() == d.escrowImpl, "ESCROW_IMPL_MISMATCH");
        require(aggregator.QUEUE_IMPLEMENTATION() == d.queueImpl, "QUEUE_IMPL_MISMATCH");
        require(ManagedNAVOracle(d.navOracle).MANAGED_AGGREGATOR() == d.aggregator, "ORACLE_AGGREGATOR_MISMATCH");

        _writeManagedJson(env, chainId, branchName, d);

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("ManagedSuperVault impl:", d.vaultImpl);
        console2.log("ManagedSuperVaultStrategy impl:", d.strategyImpl);
        console2.log("SuperVaultEscrow impl (reused):", d.escrowImpl);
        console2.log("ManagedSuperVaultDepositQueue impl:", d.queueImpl);
        console2.log("ManagedSuperVaultAggregator:", d.aggregator);
        console2.log("ManagedNAVOracle:", d.navOracle);
        console2.log("");
        console2.log("NEXT STEP: run `runRegister` with the SUPER_GOVERNOR_ROLE account to (1) register the");
        console2.log("aggregator under MANAGED_SUPER_VAULT_AGGREGATOR and (2) wire the NAV oracle via");
        console2.log("setInitialNavOracle. The family is inert until the oracle is wired.");
        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Compute deterministic addresses for the whole family (for checks)
    function _computeAddresses(uint256 env, address superGovernor) internal view returns (ManagedDeployment memory d) {
        d.vaultImpl = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_bytecode(VAULT_KEY, env), abi.encode(superGovernor)), __getSalt(VAULT_KEY)
        );
        d.strategyImpl = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_bytecode(STRATEGY_KEY, env), abi.encode(superGovernor)), __getSalt(STRATEGY_KEY)
        );
        d.escrowImpl = DeterministicDeployerLib.computeAddress(_bytecode(ESCROW_KEY, env), __getSalt(ESCROW_KEY));
        d.queueImpl = DeterministicDeployerLib.computeAddress(_bytecode(QUEUE_KEY, env), __getSalt(QUEUE_KEY));
        d.aggregator = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(
                _bytecode(AGGREGATOR_KEY, env),
                abi.encode(superGovernor, d.vaultImpl, d.strategyImpl, d.escrowImpl, d.queueImpl)
            ),
            __getSalt(AGGREGATOR_KEY)
        );
        d.navOracle = DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_bytecode(ORACLE_KEY, env), abi.encode(d.aggregator)), __getSalt(ORACLE_KEY)
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

    /// @notice Merge the managed family addresses into {ChainName}-latest.json
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
        vm.writeJson(vm.toString(d.strategyImpl), outputPath, string(abi.encodePacked(".", STRATEGY_KEY)));
        vm.writeJson(vm.toString(d.escrowImpl), outputPath, string(abi.encodePacked(".", ESCROW_KEY)));
        vm.writeJson(vm.toString(d.queueImpl), outputPath, string(abi.encodePacked(".", QUEUE_KEY)));
        vm.writeJson(vm.toString(d.aggregator), outputPath, string(abi.encodePacked(".", AGGREGATOR_KEY)));
        vm.writeJson(vm.toString(d.navOracle), outputPath, string(abi.encodePacked(".", ORACLE_KEY)));

        console2.log("");
        console2.log("Managed family addresses merged into:", outputPath);
    }
}
