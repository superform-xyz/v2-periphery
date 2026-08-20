// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperVaultCounsel } from "../src/SuperVault/SuperVaultCounsel.sol";
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
    /// @param minDeviationThreshold Immutable floor for proposeDeviationThreshold
    /// @param maxDeviationThreshold Immutable ceiling for proposeDeviationThreshold
    function run(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        address operator,
        address strategy,
        uint256 minDeviationThreshold,
        uint256 maxDeviationThreshold
    )
        external
        broadcast(env)
    {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        // Ad-hoc path: vetoRegistry defaults to the SuperGovernor (contract-side fallback)
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.operator = operator;
        p.strategy = strategy;
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

        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        address[] memory strategies;
        (p.operator, p.minDev, p.maxDev, strategies, p.vetoRegistry) = _readFleetConfig(env, chainId);

        (, address aggregator,) = _resolveAddresses(env, chainId, branchName);
        address[] memory registry = ISuperVaultAggregator(aggregator).getAllSuperVaultStrategies();

        if (strategies.length == 0) {
            console2.log("Fleet list empty for this env/chain - falling back to FULL on-chain registry");
            strategies = registry;
        }
        require(strategies.length > 0, "NO_STRATEGIES_CONFIGURED_OR_REGISTERED");

        console2.log("====== Deploying SuperVaultCounsel fleet ======");
        console2.log("Operator (from counsel-fleet.json):", p.operator);
        console2.log("Veto registry (0 = SuperGovernor default):", p.vetoRegistry);
        console2.log("Deviation bounds:", p.minDev, p.maxDev);
        console2.log("Strategies to process:", strategies.length);
        console2.log("");

        uint256 deployedCount;
        uint256 skippedCount;
        for (uint256 i = 0; i < strategies.length; i++) {
            console2.log("--- Strategy", i + 1, "of", strategies.length);
            require(_inRegistry(registry, strategies[i]), "FLEET_STRATEGY_NOT_IN_AGGREGATOR_REGISTRY");
            p.strategy = strategies[i];
            if (_isCounselDeployed(p, branchName)) {
                console2.log("Counsel already deployed for", strategies[i], "- skipping");
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
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.strategy = strategy;
        (p.operator, p.minDev, p.maxDev,, p.vetoRegistry) = _readFleetConfig(env, chainId);
        console2.log("Operator (from counsel-fleet.json):", p.operator);
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
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.strategy = strategy;
        (p.operator, p.minDev, p.maxDev,, p.vetoRegistry) = _readFleetConfig(env, chainId);
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
    function _check(DeployParams memory p, string calldata branchName) internal {
        (p.superGovernor, p.aggregator, p.executor) = _resolveAddresses(p.env, uint64(p.chainId), branchName);

        console2.log("====== SuperVaultCounsel Deployment Check ======");
        console2.log("Chain ID:", p.chainId);
        console2.log("Environment:", p.env);
        console2.log("Strategy:", p.strategy);
        console2.log("Operator:", p.operator);
        console2.log("");

        address counselAddr = _computeAddress(p);
        bool isDeployed = counselAddr.code.length > 0;

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
        address vetoRegistry; // address(0) = default to superGovernor (contract-side fallback)
    }

    /// @notice Internal deployment function (params pre-built by the caller)
    function _deploy(DeployParams memory p, string calldata branchName) internal {
        (p.superGovernor, p.aggregator, p.executor) = _resolveAddresses(p.env, uint64(p.chainId), branchName);

        _logDeployHeader(p);
        _validateParams(p);

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
        string memory outputPath = _outputJsonPath(env, chainId, branchName);
        string memory key = string(abi.encodePacked(".SuperVaultCounsel_", vm.toString(strategy)));
        vm.writeJson(vm.toString(counselAddr), outputPath, key);

        console2.log("");
        console2.log("SuperVaultCounsel merged into:", outputPath);
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

    /// @notice Read operator, deviation bounds, and the curated strategy list from counsel-fleet.json
    function _readFleetConfig(
        uint256 env,
        uint64 chainId
    )
        internal
        view
        returns (
            address operator,
            uint256 minDev,
            uint256 maxDev,
            address[] memory strategies,
            address fleetVetoRegistry
        )
    {
        string memory json = vm.readFile(string(abi.encodePacked(vm.projectRoot(), "/script/utils/counsel-fleet.json")));
        // env 0 = prod; everything else (staging/vnet) uses the staging fleet section
        string memory envKey = env == 0 ? ".prod" : ".staging";

        operator = vm.parseJsonAddress(json, string(abi.encodePacked(envKey, ".operator")));
        {
            string memory vrKey = string(abi.encodePacked(envKey, ".vetoRegistry"));
            fleetVetoRegistry = vm.keyExistsJson(json, vrKey) ? vm.parseJsonAddress(json, vrKey) : address(0);
        }
        if (operator == address(0)) {
            // Simulation runs may proceed with a placeholder operator; any BROADCAST requires
            // the real operator Safe to be set in counsel-fleet.json (it is immutable per Counsel).
            require(
                !vm.isContext(VmSafe.ForgeContext.ScriptBroadcast) && !vm.isContext(VmSafe.ForgeContext.ScriptResume),
                "OPERATOR_NOT_SET_IN_COUNSEL_FLEET_JSON_REQUIRED_FOR_BROADCAST"
            );
            operator = address(uint160(uint256(keccak256("COUNSEL_SIMULATION_OPERATOR_PLACEHOLDER"))));
            console2.log("[WARNING] operator not set in counsel-fleet.json - SIMULATION placeholder:", operator);
            console2.log("[WARNING] computed Counsel addresses will differ from the real deployment");
        }
        minDev = vm.parseJsonUint(json, string(abi.encodePacked(envKey, ".minDeviationThreshold")));
        maxDev = vm.parseJsonUint(json, string(abi.encodePacked(envKey, ".maxDeviationThreshold")));

        string memory strategiesKey = string(abi.encodePacked(envKey, ".strategies.", vm.toString(uint256(chainId))));
        require(vm.keyExistsJson(json, strategiesKey), "CHAIN_NOT_IN_COUNSEL_FLEET_JSON");
        strategies = vm.parseJsonAddressArray(json, strategiesKey);
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
    function _computeAddress(DeployParams memory p) internal view returns (address) {
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_getCounselBytecode(p.env), _encodeConstructorArgs(p)), __getSalt(_saltName(p.strategy))
        );
    }
}
