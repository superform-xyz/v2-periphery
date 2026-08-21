// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperVaultCounsel } from "../src/SuperVault/SuperVaultCounsel.sol";
import { SuperVaultVetoRegistry } from "../src/SuperVault/SuperVaultVetoRegistry.sol";
import { ISuperVaultAggregator } from "../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeploySuperVaultCounsel
/// @notice Deployment script for SuperVaultCounsel — the immutable veto-gated adapter that
///         occupies a SuperVault strategy's primary-manager/curator seat
/// @dev One Counsel instance per strategy: the salt embeds the strategy address so each strategy
///      gets its own deterministic Counsel address. SuperGovernor, Aggregator, and
///      SuperVaultExecutor are resolved from the chain's output JSON; the operator Safe and the
///      deviation-threshold bounds are supplied per deployment.
///
///      POST-DEPLOYMENT ENROLLMENT SEQUENCE (runbook — order matters):
///        0. Audit the strategy's secondary-manager list is clean BEFORE enrollment
///           (a hostile pre-existing secondary can race proposeChangePrimaryManager).
///        1. SuperGovernor msig: changePrimaryManager(strategy, counsel, feeRecipient)
///        2. Operator: counsel.enrollExecutor()            (enrollment wiped all secondaries)
///        3. Operator or guardian: counsel.invalidateAllSessionKeys()
///        4. Operator: counsel.grantSessionKeysBatch(...)  (re-onboard keepers)
///      NEVER call SuperGovernor.freezeManagerTakeover() while a Counsel is enrolled — it is
///      permanent and removes the only adapter-replacement path.
contract DeploySuperVaultCounsel is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for SuperVaultCounsel bytecode artifacts
    string internal constant COUNSEL_KEY = "SuperVaultCounsel";

    /// @notice Contract key for SuperVaultVetoRegistry bytecode artifacts
    string internal constant REGISTRY_KEY = "SuperVaultVetoRegistry";

    /// @notice Guardian veto window (spec-pinned)
    uint256 internal constant VETO_WINDOW = 3 days;

    /// @notice Proposal expiry from proposedAt (spec-pinned); executable in [VETO_WINDOW, EXPIRY)
    uint256 internal constant EXPIRY = 7 days;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy a SuperVaultCounsel for one strategy on one chain
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    /// @param operator The operator Safe (proposer + executor + day-to-day); must be non-zero
    /// @param strategy The SuperVaultStrategy this Counsel will manage; must be non-zero
    /// @param vetoRegistry Pre-deployed IVetoRegistry CONTRACT; address(0) defaults to the
    ///        SuperGovernor. For EOA guardians use the fleet config's vetoGuardians (runOne/runAll)
    /// @param minDeviationThreshold Immutable floor for proposeDeviationThreshold
    /// @param maxDeviationThreshold Immutable ceiling for proposeDeviationThreshold
    function run(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        address operator,
        address strategy,
        address vetoRegistry,
        uint256 minDeviationThreshold,
        uint256 maxDeviationThreshold
    )
        external
        broadcast(env)
    {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.operator = operator;
        p.strategy = strategy;
        p.vetoRegistry = vetoRegistry;
        p.minDev = minDeviationThreshold;
        p.maxDev = maxDeviationThreshold;
        _deploy(p, branchName);
    }

    /// @notice Deploy a SuperVaultCounsel for every strategy in the curated fleet config
    /// @dev Reads script/utils/counsel-fleet.json: the operator Safe, deviation bounds, and the
    ///      per-chain strategy list all come from the config, so no extra params are needed.
    ///      "All strategies" means the CURATED fleet - not the full aggregator registry. If the
    ///      config's strategy list for this env+chain is empty, falls back to the full on-chain
    ///      registry (intended for staging/test environments). Every curated strategy is
    ///      validated against the registry. Already-deployed Counsels (same salt + args) are
    ///      skipped, making re-runs idempotent. Each deployment is written to the output JSON
    ///      under ".SuperVaultCounsel_<strategy>".
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    function runAll(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        FleetEntry[] memory entries = _readFleetEntries(env, chainId);

        (, address aggregator,) = _resolveAddresses(env, chainId, branchName);
        address[] memory registry = ISuperVaultAggregator(aggregator).getAllSuperVaultStrategies();

        if (entries.length == 0) {
            console2.log("Fleet list empty for this env/chain - falling back to FULL on-chain registry");
            entries = _fleetFromRegistry(env, registry);
        }
        require(entries.length > 0, "NO_STRATEGIES_CONFIGURED_OR_REGISTERED");

        console2.log("====== Deploying SuperVaultCounsel fleet ======");
        console2.log("Strategies to process:", entries.length);
        console2.log("");

        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        uint256 deployedCount;
        uint256 skippedCount;
        for (uint256 i = 0; i < entries.length; i++) {
            console2.log("--- Strategy", i + 1, "of", entries.length);
            require(_inRegistry(registry, entries[i].strategy), "FLEET_STRATEGY_NOT_IN_AGGREGATOR_REGISTRY");
            p.strategy = entries[i].strategy;
            p.operator = _resolveOperator(entries[i].operator);
            p.vetoRegistry = entries[i].vetoRegistry;
            p.vetoGuardians = entries[i].vetoGuardians;
            p.minDev = entries[i].minDev;
            p.maxDev = entries[i].maxDev;
            console2.log("    operator:", p.operator);
            _logVetoConfig(p);
            if (_isCounselDeployed(p, branchName)) {
                console2.log("Counsel already deployed for", entries[i].strategy, "- skipping");
                skippedCount++;
                continue;
            }
            _deploy(p, branchName);
            deployedCount++;
        }

        console2.log("");
        console2.log("====== Fleet deployment complete ======");
        console2.log("Deployed:", deployedCount);
        console2.log("Skipped (already deployed):", skippedCount);
    }

    /// @notice Deploy one strategy's Counsel using operator/bounds from counsel-fleet.json
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    /// @param strategy The SuperVaultStrategy this Counsel will manage
    function runOne(uint256 env, uint64 chainId, string calldata branchName, address strategy) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        FleetEntry memory e = _fleetEntryFor(env, chainId, strategy);
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.strategy = strategy;
        p.operator = _resolveOperator(e.operator);
        p.vetoRegistry = e.vetoRegistry;
        p.vetoGuardians = e.vetoGuardians;
        p.minDev = e.minDev;
        p.maxDev = e.maxDev;
        console2.log("Operator (from counsel-fleet.json):", p.operator);
        _logVetoConfig(p);
        _deploy(p, branchName);
    }

    /// @notice Check one strategy's Counsel using operator/bounds from counsel-fleet.json
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    /// @param strategy The strategy the Counsel manages
    function runCheckOne(uint256 env, uint64 chainId, string calldata branchName, address strategy) external {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        FleetEntry memory e = _fleetEntryFor(env, chainId, strategy);
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.strategy = strategy;
        p.operator = _resolveOperator(e.operator);
        p.vetoRegistry = e.vetoRegistry;
        p.vetoGuardians = e.vetoGuardians;
        p.minDev = e.minDev;
        p.maxDev = e.maxDev;
        _check(p, branchName);
    }

    /// @notice Check deployment status and enrollment state for a strategy's Counsel
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    /// @param operator The operator Safe used at deployment
    /// @param strategy The strategy the Counsel manages
    /// @param minDeviationThreshold Floor used at deployment
    /// @param maxDeviationThreshold Ceiling used at deployment
    function runCheck(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        address operator,
        address strategy,
        uint256 minDeviationThreshold,
        uint256 maxDeviationThreshold
    )
        external
    {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        // Ad-hoc check path assumes the default veto registry (SuperGovernor)
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.operator = operator;
        p.strategy = strategy;
        p.minDev = minDeviationThreshold;
        p.maxDev = maxDeviationThreshold;
        _check(p, branchName);
    }

    /// @notice Shared check implementation (vetoRegistry participates in the CREATE2 address)
    function _check(DeployParams memory p, string calldata branchName) internal view {
        (p.superGovernor, p.aggregator, p.executor) = _resolveAddresses(p.env, uint64(p.chainId), branchName);

        console2.log("====== SuperVaultCounsel Deployment Check ======");
        console2.log("Chain ID:", p.chainId);
        console2.log("Environment:", p.env);
        console2.log("Strategy:", p.strategy);
        console2.log("Operator:", p.operator);
        _logVetoConfig(p);

        address counselAddr = _computeAddress(p); // resolves p.vetoRegistry to its registry
        bool isDeployed = counselAddr.code.length > 0;

        if (p.vetoRegistry != address(0)) {
            console2.log("Veto registry (resolved):", p.vetoRegistry);
            console2.log("Registry is deployed:", p.vetoRegistry.code.length > 0);
        } else {
            console2.log("Veto registry (resolved): SuperGovernor default");
        }
        console2.log("");
        console2.log("Computed address:", counselAddr);
        console2.log("Is deployed:", isDeployed);

        if (isDeployed) {
            SuperVaultCounsel counsel = SuperVaultCounsel(payable(counselAddr));
            console2.log("");
            console2.log("=== Counsel State ===");
            console2.log("OPERATOR:", counsel.OPERATOR());
            console2.log("SUPER_GOVERNOR:", address(counsel.SUPER_GOVERNOR()));
            console2.log("VETO_REGISTRY:", address(counsel.VETO_REGISTRY()));
            console2.log("AGGREGATOR:", address(counsel.AGGREGATOR()));
            console2.log("STRATEGY:", address(counsel.STRATEGY()));
            console2.log("EXECUTOR:", address(counsel.EXECUTOR()));
            console2.log("VETO_WINDOW:", counsel.VETO_WINDOW());
            console2.log("EXPIRY:", counsel.EXPIRY());
            console2.log("MIN_DEVIATION_THRESHOLD:", counsel.MIN_DEVIATION_THRESHOLD());
            console2.log("MAX_DEVIATION_THRESHOLD:", counsel.MAX_DEVIATION_THRESHOLD());
            console2.log("Proposals created:", counsel.nextProposalId());

            console2.log("");
            console2.log("=== Enrollment State (aggregator) ===");
            address mainManager = ISuperVaultAggregator(p.aggregator).getMainManager(p.strategy);
            console2.log("Strategy mainManager:", mainManager);
            console2.log("Counsel is enrolled as primary:", mainManager == counselAddr);
            console2.log(
                "Executor is secondary manager:",
                ISuperVaultAggregator(p.aggregator).isSecondaryManager(p.executor, p.strategy)
            );
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Resolve SuperGovernor, Aggregator, and SuperVaultExecutor from the output JSON
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param branchName Branch name for vnet deployments
    function _resolveAddresses(
        uint256 env,
        uint64 chainId,
        string calldata branchName
    )
        internal
        view
        returns (address superGovernor, address aggregator, address executor)
    {
        string memory json = vm.readFile(_outputJsonPath(env, chainId, branchName));

        superGovernor = vm.parseJsonAddress(json, ".SuperGovernor");
        aggregator = vm.parseJsonAddress(json, ".SuperVaultAggregator");
        executor = vm.parseJsonAddress(json, ".SuperVaultExecutor");

        require(superGovernor != address(0), "SUPER_GOVERNOR_NOT_FOUND_IN_OUTPUT");
        require(aggregator != address(0), "AGGREGATOR_NOT_FOUND_IN_OUTPUT");
        require(executor != address(0), "EXECUTOR_NOT_FOUND_IN_OUTPUT");

        if (superGovernor.code.length == 0) console2.log("WARNING: SuperGovernor has no code on chain", chainId);
        if (aggregator.code.length == 0) console2.log("WARNING: Aggregator has no code on chain", chainId);
        if (executor.code.length == 0) console2.log("WARNING: SuperVaultExecutor has no code on chain", chainId);
    }

    /// @notice Bundled deployment parameters (avoids stack-too-deep)
    struct DeployParams {
        uint256 env;
        uint64 chainId;
        address operator;
        address strategy;
        uint256 minDev;
        uint256 maxDev;
        address superGovernor;
        address aggregator;
        address executor;
        address vetoRegistry; // pre-deployed IVetoRegistry contract; address(0) = SuperGovernor fallback
        address[] vetoGuardians; // non-empty = auto-deploy a per-strategy SuperVaultVetoRegistry with this set
    }

    /// @notice Internal deployment function (params pre-built by the caller)
    function _deploy(DeployParams memory p, string calldata branchName) internal {
        (p.superGovernor, p.aggregator, p.executor) = _resolveAddresses(p.env, uint64(p.chainId), branchName);

        _logDeployHeader(p);
        _validateParams(p);

        // Resolve the veto authority: a vetoGuardians batch auto-deploys a per-strategy
        // SuperVaultVetoRegistry; a vetoRegistry must be an already-deployed contract; zero
        // falls through to the Counsel's SuperGovernor default.
        p.vetoRegistry = _resolveOrDeployVetoRegistry(p, branchName);

        // Per-strategy salt: each strategy gets its own deterministic Counsel address
        address counselAddr = __deployContract(
            COUNSEL_KEY,
            p.chainId,
            __getSalt(_saltName(p.strategy)),
            abi.encodePacked(_getCounselBytecode(p.env), _encodeConstructorArgs(p))
        );

        _verifyDeployment(p, counselAddr);

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("SuperVaultCounsel deployed at:", counselAddr);
        console2.log("All immutables verified");

        // Write JSON output (keyed per strategy)
        _writeCounselJson(p.env, uint64(p.chainId), counselAddr, p.strategy, branchName);

        console2.log("");
        console2.log("====== Deployment Complete ======");
        console2.log("");
        console2.log("NEXT STEPS (enrollment runbook):");
        console2.log("  0. Audit strategy secondary-manager list is clean");
        console2.log("  1. SuperGovernor msig: changePrimaryManager(strategy, counsel, feeRecipient)");
        console2.log("  2. Operator: counsel.enrollExecutor()");
        console2.log("  3. Operator/guardian: counsel.invalidateAllSessionKeys()");
        console2.log("  4. Operator: counsel.grantSessionKeysBatch(...)");
        console2.log("  NEVER freezeManagerTakeover() while a Counsel is enrolled");
    }

    /// @notice Log the deployment header
    function _logDeployHeader(DeployParams memory p) internal pure {
        console2.log("====== Deploying SuperVaultCounsel ======");
        console2.log("Chain ID:", p.chainId);
        console2.log("Environment:", p.env);
        console2.log("Operator:", p.operator);
        console2.log("Strategy:", p.strategy);
        console2.log("SuperGovernor:", p.superGovernor);
        console2.log("Aggregator:", p.aggregator);
        console2.log("SuperVaultExecutor:", p.executor);
        console2.log("Veto window:", VETO_WINDOW);
        console2.log("Expiry:", EXPIRY);
        console2.log("Deviation bounds:", p.minDev, p.maxDev);
        console2.log("");
    }

    /// @notice Validate inputs (mirrors the constructor's own checks so simulation fails early)
    function _validateParams(DeployParams memory p) internal view {
        require(p.operator != address(0), "INVALID_OPERATOR");
        require(p.strategy != address(0), "INVALID_STRATEGY");
        require(p.strategy.code.length > 0, "STRATEGY_NOT_DEPLOYED");
        require(p.minDev > 0 && p.maxDev >= p.minDev && p.maxDev < type(uint256).max, "INVALID_DEVIATION_BOUNDS");
    }

    /// @notice Get bytecode from environment-specific artifacts
    function _getCounselBytecode(uint256 env) internal view returns (bytes memory bytecode) {
        bytecode = __getBytecode(COUNSEL_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
    }

    /// @notice Get SuperVaultVetoRegistry bytecode from environment-specific artifacts
    function _getRegistryBytecode(uint256 env) internal view returns (bytes memory bytecode) {
        bytecode = __getBytecode(REGISTRY_KEY, env);
        require(bytecode.length > 0, "REGISTRY_BYTECODE_NOT_FOUND");
    }

    /// @notice Resolve the veto-registry address a deployment with these params will use,
    ///         WITHOUT deploying anything: a vetoGuardians batch maps to its per-strategy
    ///         registry's deterministic CREATE2 address; a vetoRegistry contract passes
    ///         through (codeless addresses are rejected - use vetoGuardians for EOAs).
    function _predictVetoRegistry(DeployParams memory p) internal view returns (address) {
        if (p.vetoGuardians.length > 0) {
            require(p.vetoRegistry == address(0), "AMBIGUOUS_VETO_CONFIG_SET_GUARDIANS_OR_REGISTRY_NOT_BOTH");
            return DeterministicDeployerLib.computeAddress(
                _registryCreationCode(p.env, p.vetoGuardians), __getSalt(_registrySaltName(p.strategy))
            );
        }
        if (p.vetoRegistry != address(0)) {
            require(p.vetoRegistry.code.length > 0, "VETO_REGISTRY_MUST_BE_A_CONTRACT_USE_VETO_GUARDIANS_FOR_EOAS");
        }
        return p.vetoRegistry;
    }

    /// @notice Deploy-time veto resolution: deploys the per-strategy registry when a
    ///         vetoGuardians batch is configured, probes every guardian, and records the
    ///         registry in the output JSON under "SuperVaultVetoRegistry_<strategy>"
    function _resolveOrDeployVetoRegistry(DeployParams memory p, string calldata branchName) internal returns (address) {
        if (p.vetoGuardians.length > 0) {
            require(p.vetoRegistry == address(0), "AMBIGUOUS_VETO_CONFIG_SET_GUARDIANS_OR_REGISTRY_NOT_BOTH");
            address registryAddr = __deployContract(
                REGISTRY_KEY,
                p.chainId,
                __getSalt(_registrySaltName(p.strategy)),
                _registryCreationCode(p.env, p.vetoGuardians)
            );
            for (uint256 i = 0; i < p.vetoGuardians.length; i++) {
                require(SuperVaultVetoRegistry(registryAddr).isGuardian(p.vetoGuardians[i]), "REGISTRY_PROBE_FAILED");
            }
            _writeAddressJson(p.env, uint64(p.chainId), REGISTRY_KEY, registryAddr, p.strategy, branchName);
            return registryAddr;
        }
        if (p.vetoRegistry != address(0)) {
            require(p.vetoRegistry.code.length > 0, "VETO_REGISTRY_MUST_BE_A_CONTRACT_USE_VETO_GUARDIANS_FOR_EOAS");
        }
        return p.vetoRegistry;
    }

    /// @notice CREATE2 creation code for a per-strategy registry with a fixed guardian batch
    function _registryCreationCode(uint256 env, address[] memory guardians) internal view returns (bytes memory) {
        return abi.encodePacked(_getRegistryBytecode(env), abi.encode(guardians));
    }

    /// @notice Log the resolved veto configuration for one deployment
    function _logVetoConfig(DeployParams memory p) internal pure {
        if (p.vetoGuardians.length > 0) {
            console2.log("    veto: per-strategy registry, guardians:", p.vetoGuardians.length);
            for (uint256 i = 0; i < p.vetoGuardians.length; i++) {
                console2.log("      guardian:", p.vetoGuardians[i]);
            }
        } else if (p.vetoRegistry != address(0)) {
            console2.log("    veto: custom registry contract:", p.vetoRegistry);
        } else {
            console2.log("    veto: SuperGovernor default");
        }
    }

    /// @notice ABI-encode the Counsel constructor args in declaration order
    function _encodeConstructorArgs(DeployParams memory p) internal pure returns (bytes memory) {
        return abi.encode(
            p.operator,
            p.superGovernor,
            p.vetoRegistry,
            p.aggregator,
            p.strategy,
            p.executor,
            VETO_WINDOW,
            EXPIRY,
            p.minDev,
            p.maxDev
        );
    }

    /// @notice Verify every immutable on the deployed Counsel matches the intended configuration
    function _verifyDeployment(DeployParams memory p, address counselAddr) internal view {
        SuperVaultCounsel counsel = SuperVaultCounsel(payable(counselAddr));
        require(counsel.OPERATOR() == p.operator, "OPERATOR_MISMATCH");
        require(address(counsel.SUPER_GOVERNOR()) == p.superGovernor, "SUPER_GOVERNOR_MISMATCH");
        require(
            address(counsel.VETO_REGISTRY()) == (p.vetoRegistry == address(0) ? p.superGovernor : p.vetoRegistry),
            "VETO_REGISTRY_MISMATCH"
        );
        require(address(counsel.AGGREGATOR()) == p.aggregator, "AGGREGATOR_MISMATCH");
        require(address(counsel.STRATEGY()) == p.strategy, "STRATEGY_MISMATCH");
        require(address(counsel.EXECUTOR()) == p.executor, "EXECUTOR_MISMATCH");
        require(counsel.VETO_WINDOW() == VETO_WINDOW, "VETO_WINDOW_MISMATCH");
        require(counsel.EXPIRY() == EXPIRY, "EXPIRY_MISMATCH");
        require(counsel.MIN_DEVIATION_THRESHOLD() == p.minDev, "MIN_DEV_MISMATCH");
        require(counsel.MAX_DEVIATION_THRESHOLD() == p.maxDev, "MAX_DEV_MISMATCH");
    }

    /// @notice Merge the Counsel address into {ChainName}-latest.json under a per-strategy key
    function _writeCounselJson(
        uint256 env,
        uint64 chainId,
        address counselAddr,
        address strategy,
        string calldata branchName
    )
        internal
    {
        _writeAddressJson(env, chainId, COUNSEL_KEY, counselAddr, strategy, branchName);
    }

    /// @notice Merge an address into {ChainName}-latest.json under "<contractKey>_<strategy>"
    function _writeAddressJson(
        uint256 env,
        uint64 chainId,
        string memory contractKey,
        address addr,
        address strategy,
        string calldata branchName
    )
        internal
    {
        string memory outputPath = _outputJsonPath(env, chainId, branchName);
        string memory key = string(abi.encodePacked(".", contractKey, "_", vm.toString(strategy)));
        vm.writeJson(vm.toString(addr), outputPath, key);

        console2.log("");
        console2.log(string(abi.encodePacked(contractKey, " merged into:")), outputPath);
        console2.log("Under key:", key);
    }

    /// @notice Path to the chain's output JSON for the given environment
    function _outputJsonPath(
        uint256 env,
        uint64 chainId,
        string calldata branchName
    )
        internal
        view
        returns (string memory)
    {
        string memory envFolder;
        if (env == 0) {
            envFolder = "prod";
        } else if (env == 1) {
            envFolder = branchName;
        } else {
            envFolder = "staging";
        }
        return string(
            abi.encodePacked(
                vm.projectRoot(),
                "/script/output/",
                envFolder,
                "/",
                vm.toString(uint256(chainId)),
                "/",
                chainNames[chainId],
                "-latest.json"
            )
        );
    }

    /// @notice Per-strategy salt name so multiple Counsel instances coexist deterministically
    function _saltName(address strategy) internal pure returns (string memory) {
        return string(abi.encodePacked(COUNSEL_KEY, "_", vm.toString(strategy)));
    }

    /// @notice Per-strategy salt name for the strategy's SuperVaultVetoRegistry
    function _registrySaltName(address strategy) internal pure returns (string memory) {
        return string(abi.encodePacked(REGISTRY_KEY, "_", vm.toString(strategy)));
    }

    /// @notice Read operator, deviation bounds, and the curated strategy list from counsel-fleet.json
    /// @notice One resolved fleet entry: per-strategy config with env defaults applied
    struct FleetEntry {
        address strategy;
        address operator;
        address vetoRegistry;
        address[] vetoGuardians;
        uint256 minDev;
        uint256 maxDev;
    }

    /// @notice Read the environment defaults from counsel-fleet.json
    function _readFleetDefaults(
        string memory json,
        string memory envKey
    )
        internal
        view
        returns (
            address dOperator,
            address dVetoRegistry,
            address[] memory dVetoGuardians,
            uint256 dMinDev,
            uint256 dMaxDev
        )
    {
        string memory d = string(abi.encodePacked(envKey, ".defaults"));
        dOperator = vm.parseJsonAddress(json, string(abi.encodePacked(d, ".operator")));
        dVetoRegistry = vm.parseJsonAddress(json, string(abi.encodePacked(d, ".vetoRegistry")));
        string memory gk = string(abi.encodePacked(d, ".vetoGuardians"));
        dVetoGuardians = vm.keyExistsJson(json, gk) ? vm.parseJsonAddressArray(json, gk) : new address[](0);
        require(
            !(dVetoGuardians.length > 0 && dVetoRegistry != address(0)),
            "AMBIGUOUS_DEFAULT_VETO_CONFIG_SET_GUARDIANS_OR_REGISTRY_NOT_BOTH"
        );
        dMinDev = vm.parseJsonUint(json, string(abi.encodePacked(d, ".minDeviationThreshold")));
        dMaxDev = vm.parseJsonUint(json, string(abi.encodePacked(d, ".maxDeviationThreshold")));
    }

    /// @notice Resolve an operator: zero means "not set" - allowed with a placeholder in
    ///         simulation, hard-rejected on any broadcast (it is immutable per Counsel)
    function _resolveOperator(address operator) internal view returns (address) {
        if (operator != address(0)) return operator;
        require(
            !vm.isContext(VmSafe.ForgeContext.ScriptBroadcast) && !vm.isContext(VmSafe.ForgeContext.ScriptResume),
            "OPERATOR_NOT_SET_IN_COUNSEL_FLEET_JSON_REQUIRED_FOR_BROADCAST"
        );
        address placeholder = address(uint160(uint256(keccak256("COUNSEL_SIMULATION_OPERATOR_PLACEHOLDER"))));
        console2.log("[WARNING] operator not set in counsel-fleet.json - SIMULATION placeholder:", placeholder);
        console2.log("[WARNING] computed Counsel addresses will differ from the real deployment");
        return placeholder;
    }

    /// @notice Read the per-strategy fleet entries for env+chain, applying defaults for any
    ///         field an entry omits (operator / vetoRegistry / min-/maxDeviationThreshold)
    function _readFleetEntries(uint256 env, uint64 chainId) internal view returns (FleetEntry[] memory entries) {
        string memory json = vm.readFile(string(abi.encodePacked(vm.projectRoot(), "/script/utils/counsel-fleet.json")));
        // env 0 = prod; everything else (staging/vnet) uses the staging fleet section
        string memory envKey = env == 0 ? ".prod" : ".staging";
        (address dOperator, address dVetoRegistry, address[] memory dVetoGuardians, uint256 dMinDev, uint256 dMaxDev) =
            _readFleetDefaults(json, envKey);

        string memory base = string(abi.encodePacked(envKey, ".strategies.", vm.toString(uint256(chainId))));
        require(vm.keyExistsJson(json, base), "CHAIN_NOT_IN_COUNSEL_FLEET_JSON");

        uint256 n;
        while (vm.keyExistsJson(json, string(abi.encodePacked(base, "[", vm.toString(n), "]")))) {
            n++;
        }

        entries = new FleetEntry[](n);
        for (uint256 i = 0; i < n; i++) {
            string memory e = string(abi.encodePacked(base, "[", vm.toString(i), "]"));
            entries[i].strategy = vm.parseJsonAddress(json, string(abi.encodePacked(e, ".strategy")));
            entries[i].operator = _entryAddr(json, e, ".operator", dOperator);
            (entries[i].vetoRegistry, entries[i].vetoGuardians) =
                _entryVetoConfig(json, e, dVetoRegistry, dVetoGuardians);
            entries[i].minDev = _entryUint(json, e, ".minDeviationThreshold", dMinDev);
            entries[i].maxDev = _entryUint(json, e, ".maxDeviationThreshold", dMaxDev);
        }
    }

    /// @notice Entry-level address override; a present, non-zero value wins over the default
    function _entryAddr(
        string memory json,
        string memory entryPath,
        string memory field,
        address dflt
    )
        internal
        view
        returns (address)
    {
        string memory k = string(abi.encodePacked(entryPath, field));
        if (!vm.keyExistsJson(json, k)) return dflt;
        address v = vm.parseJsonAddress(json, k);
        return v == address(0) ? dflt : v;
    }

    /// @notice Entry-level uint override; a present value wins over the default
    function _entryUint(
        string memory json,
        string memory entryPath,
        string memory field,
        uint256 dflt
    )
        internal
        view
        returns (uint256)
    {
        string memory k = string(abi.encodePacked(entryPath, field));
        return vm.keyExistsJson(json, k) ? vm.parseJsonUint(json, k) : dflt;
    }

    /// @notice Resolve an entry's veto configuration. An explicit entry-level vetoGuardians
    ///         array or vetoRegistry contract wins outright (and suppresses the other
    ///         inherited default); with neither present the environment defaults apply.
    function _entryVetoConfig(
        string memory json,
        string memory entryPath,
        address dVetoRegistry,
        address[] memory dVetoGuardians
    )
        internal
        view
        returns (address vetoRegistry, address[] memory vetoGuardians)
    {
        string memory gk = string(abi.encodePacked(entryPath, ".vetoGuardians"));
        string memory rk = string(abi.encodePacked(entryPath, ".vetoRegistry"));
        bool hasGuardians = vm.keyExistsJson(json, gk) && vm.parseJsonAddressArray(json, gk).length > 0;
        bool hasRegistry = vm.keyExistsJson(json, rk) && vm.parseJsonAddress(json, rk) != address(0);
        require(!(hasGuardians && hasRegistry), "AMBIGUOUS_ENTRY_VETO_CONFIG_SET_GUARDIANS_OR_REGISTRY_NOT_BOTH");
        if (hasGuardians) return (address(0), vm.parseJsonAddressArray(json, gk));
        if (hasRegistry) return (vm.parseJsonAddress(json, rk), new address[](0));
        return (dVetoRegistry, dVetoGuardians);
    }

    /// @notice Build fleet entries from the full on-chain registry using environment defaults
    ///         (runAll fallback when the curated list is empty)
    function _fleetFromRegistry(
        uint256 env,
        address[] memory registry
    )
        internal
        view
        returns (FleetEntry[] memory entries)
    {
        string memory json = vm.readFile(string(abi.encodePacked(vm.projectRoot(), "/script/utils/counsel-fleet.json")));
        (address dOp, address dVr, address[] memory dVg, uint256 dMin, uint256 dMax) =
            _readFleetDefaults(json, env == 0 ? ".prod" : ".staging");
        entries = new FleetEntry[](registry.length);
        for (uint256 i = 0; i < registry.length; i++) {
            entries[i] = FleetEntry({
                strategy: registry[i],
                operator: dOp,
                vetoRegistry: dVr,
                vetoGuardians: dVg,
                minDev: dMin,
                maxDev: dMax
            });
        }
    }

    /// @notice Resolve the fleet entry for one strategy; falls back to env defaults (with a log)
    ///         when the strategy is not in the curated list
    function _fleetEntryFor(uint256 env, uint64 chainId, address strategy) internal view returns (FleetEntry memory e) {
        FleetEntry[] memory entries = _readFleetEntries(env, chainId);
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].strategy == strategy) return entries[i];
        }
        console2.log("Strategy not in counsel-fleet.json - using environment defaults");
        string memory json = vm.readFile(string(abi.encodePacked(vm.projectRoot(), "/script/utils/counsel-fleet.json")));
        (e.operator, e.vetoRegistry, e.vetoGuardians, e.minDev, e.maxDev) =
            _readFleetDefaults(json, env == 0 ? ".prod" : ".staging");
        e.strategy = strategy;
    }

    /// @notice Whether a strategy is present in the aggregator's registry
    function _inRegistry(address[] memory registry, address strategy) internal pure returns (bool) {
        for (uint256 i = 0; i < registry.length; i++) {
            if (registry[i] == strategy) return true;
        }
        return false;
    }

    /// @notice Whether a Counsel with these exact args is already deployed at its deterministic address
    function _isCounselDeployed(DeployParams memory p, string calldata branchName) internal view returns (bool) {
        (p.superGovernor, p.aggregator, p.executor) = _resolveAddresses(p.env, uint64(p.chainId), branchName);
        return _computeAddress(p).code.length > 0;
    }

    /// @notice Compute the deterministic address for a strategy's Counsel
    /// @dev Resolves the veto authority to its registry address first — a bare guardian in the
    ///      fleet config participates in the Counsel's CREATE2 address via its deployed registry
    function _computeAddress(DeployParams memory p) internal view returns (address) {
        p.vetoRegistry = _predictVetoRegistry(p);
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_getCounselBytecode(p.env), _encodeConstructorArgs(p)), __getSalt(_saltName(p.strategy))
        );
    }
}
