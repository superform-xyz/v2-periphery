// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperVaultCounsel } from "../src/SuperVault/SuperVaultCounsel.sol";
import { ISuperVaultAggregator } from "../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { console2 } from "forge-std/console2.sol";

/// @title ConfigureSuperVaultCounsel
/// @notice Post-seating enrollment script for SuperVaultCounsel — runs steps 2 and 3 of the
///         enrollment runbook AFTER the SuperGovernor msig has executed
///         changePrimaryManager(strategy, counsel, feeRecipient):
///           2. counsel.invalidateAllSessionKeys() (kills any keys from a prior tenure)
///           3. counsel.enrollExecutor()           (re-adds the executor the seating wiped)
///         ORDER MATTERS: the executor validates grants against the current primary manager and
///         its key generation, and a manager change does not bump the generation, so a Counsel
///         reinstated at the SAME address revives every unexpired key from its previous tenure.
///
///         SAFE TO RE-RUN, but only because of one guard. Both steps are skipped entirely when the
///         executor is already a secondary manager. A seating wipes every secondary, so a still
///         seated executor proves no seating has happened since enrollment, which proves no stale
///         keys exist. Without that guard a second run after step 4 would invalidate the keeper
///         keys just granted and stop the keepers with no error anywhere. Do not "simplify" the
///         guard to cover enrollExecutor alone: that was the original bug.
///         Seating wipes the executor from the secondary set, which is what keeps those revived
///         keys inert; enrolling the executor before invalidating them re-arms them for the
///         gap between the two (separately mined) transactions. Invalidate first.
/// @dev The broadcaster MUST be the Counsel's OPERATOR (both calls are operator-gated; this
///      script pre-checks and reverts early otherwise). Step 4 — grantSessionKeysBatch to
///      re-onboard keepers — carries keeper-specific permission payloads and is deliberately
///      NOT automated here; run it as a follow-up operator action.
///      The Counsel address is resolved from the chain output JSON under the per-strategy key
///      written by DeploySuperVaultCounsel (".SuperVaultCounsel_<strategy>").
contract ConfigureSuperVaultCounsel is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Enroll the executor and invalidate stale session keys for one strategy's Counsel
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    /// @param strategy The strategy whose Counsel to configure
    function run(uint256 env, uint64 chainId, string calldata branchName, address strategy) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        (SuperVaultCounsel counsel, ISuperVaultAggregator aggregator, address executor) =
            _resolve(env, chainId, branchName, strategy);

        console2.log("====== Configure SuperVaultCounsel (enrollment steps 2-3) ======");
        console2.log("Chain ID:", chainId);
        console2.log("Strategy:", strategy);
        console2.log("Counsel:", address(counsel));
        console2.log("Executor:", executor);
        console2.log("");

        // Pre-flight: the seat must already be transferred (runbook step 1)
        address mainManager = aggregator.getMainManager(strategy);
        console2.log("Strategy mainManager:", mainManager);
        require(mainManager == address(counsel), "COUNSEL_NOT_SEATED_RUN_CHANGE_PRIMARY_MANAGER_FIRST");

        // Pre-flight: both calls below are operator-gated. Compare against the RESOLVED
        // broadcaster, not msg.sender: on vnet the modifier broadcasts from a key derived from
        // MNEMONIC while msg.sender stays foundry's default sender, so a msg.sender check there
        // is meaningless and elsewhere passes only because the runner sets --sender.
        address operator = counsel.OPERATOR();
        console2.log("Counsel OPERATOR:", operator);
        console2.log("Broadcaster:", _broadcaster);
        require(_broadcaster == operator, "BROADCASTER_IS_NOT_COUNSEL_OPERATOR");

        // Steps 2 and 3, guarded together so the script is safe to re-run.
        //
        // A seating wipes every secondary manager. So an executor that is STILL a secondary proves
        // no seating has happened since it was enrolled, which in turn proves no keys survive from
        // a prior tenure. Both steps are then not merely redundant but harmful: a second run after
        // step 4 would invalidate the keeper keys just granted and silently halt the keepers.
        // Guarding only enrollExecutor, as this script previously did, left exactly that hole.
        if (!_needsEnrollment(aggregator, executor, strategy)) {
            console2.log("[Steps 2-3] Executor is already a secondary manager.");
            console2.log("            No seating since enrollment, so no stale keys can exist.");
            console2.log("            SKIPPING BOTH - invalidating here would kill live keeper keys.");
        } else {
            // Order matters: invalidate BEFORE the executor regains manager powers, because a
            // Counsel reinstated at the same address revives every unexpired key from its
            // previous tenure (a manager change does not bump the executor's key generation).
            console2.log("[Step 2] Calling invalidateAllSessionKeys()...");
            counsel.invalidateAllSessionKeys();
            console2.log("[Step 2] DONE");

            console2.log("[Step 3] Calling enrollExecutor()...");
            counsel.enrollExecutor();
            console2.log("[Step 3] DONE");
        }

        // Post-verify
        require(aggregator.isSecondaryManager(executor, strategy), "EXECUTOR_ENROLLMENT_FAILED");

        console2.log("");
        console2.log("====== Enrollment steps 2-3 complete ======");
        console2.log("NEXT: operator runs counsel.grantSessionKeysBatch(...) to re-onboard keepers (step 4)");
        console2.log("NEVER call SuperGovernor.freezeManagerTakeover() while a Counsel is enrolled");
    }

    /// @notice Enroll executors for every curated-fleet strategy whose Counsel is deployed and seated
    /// @dev Iterates the curated fleet from script/utils/counsel-fleet.json ("all strategies" =
    ///      the curated list, not the full registry; empty list falls back to the registry for
    ///      staging/test). Per strategy, skips (with a log, not a revert) when: no Counsel in
    ///      the output JSON, the Counsel is not seated as mainManager yet (runbook step 1
    ///      pending), or the broadcaster is not that Counsel's operator. Everything else gets
    ///      invalidateAllSessionKeys() then enrollExecutor() (in that order — see the contract
    ///      NatSpec).
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    function runAll(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        string memory json = vm.readFile(_outputJsonPath(env, chainId, branchName));
        ISuperVaultAggregator aggregator = ISuperVaultAggregator(vm.parseJsonAddress(json, ".SuperVaultAggregator"));

        address[] memory strategies = _readFleetStrategies(env, chainId);
        if (strategies.length == 0) {
            console2.log("Fleet list empty for this env/chain - falling back to FULL on-chain registry");
            strategies = aggregator.getAllSuperVaultStrategies();
        }

        console2.log("====== Configure SuperVaultCounsel for the curated fleet ======");
        console2.log("Strategies to process:", strategies.length);
        console2.log("Broadcaster:", _broadcaster);
        console2.log("");

        uint256 configured;
        uint256 alreadyEnrolled;
        uint256 skipped;
        for (uint256 i = 0; i < strategies.length; i++) {
            address strategy = strategies[i];
            console2.log("--- Strategy:", strategy);

            address counselAddr = _tryResolveCounsel(json, strategy);
            if (counselAddr == address(0) || counselAddr.code.length == 0) {
                console2.log("    SKIP: no deployed Counsel in output JSON");
                skipped++;
                continue;
            }
            SuperVaultCounsel counsel = SuperVaultCounsel(payable(counselAddr));
            if (aggregator.getMainManager(strategy) != counselAddr) {
                console2.log("    SKIP: Counsel not seated as mainManager (runbook step 1 pending)");
                skipped++;
                continue;
            }
            if (counsel.OPERATOR() != _broadcaster) {
                console2.log("    SKIP: broadcaster is not this Counsel's operator:", counsel.OPERATOR());
                skipped++;
                continue;
            }

            address executor = address(counsel.EXECUTOR());
            // See run(): a still-seated executor proves no seating since enrollment, so no stale
            // keys exist and invalidating would destroy the live keeper keys from step 4. This is
            // the guard that makes runAll safe across a fleet where some strategies are onboarded.
            if (!_needsEnrollment(aggregator, executor, strategy)) {
                console2.log("    ALREADY ENROLLED: skipping both steps (would kill live keeper keys)");
                alreadyEnrolled++;
                continue;
            }

            // invalidate FIRST: stale keys from a prior tenure revive with the seat and must be
            // dead before the executor regains manager powers
            counsel.invalidateAllSessionKeys();
            console2.log("    invalidateAllSessionKeys: DONE");
            counsel.enrollExecutor();
            console2.log("    enrollExecutor: DONE");
            require(aggregator.isSecondaryManager(executor, strategy), "EXECUTOR_ENROLLMENT_FAILED");
            configured++;
        }

        console2.log("");
        console2.log("====== Fleet enrollment complete ======");
        console2.log("Configured:", configured);
        console2.log("Already enrolled:", alreadyEnrolled);
        console2.log("Skipped:", skipped);
        console2.log("NEXT: operator runs grantSessionKeysBatch(...) per configured strategy (step 4)");

        // Fail loudly rather than reporting success after doing nothing. A run where every
        // strategy was skipped (wrong operator account, nothing seated yet, no Counsel deployed)
        // used to exit zero, so CI and runbook automation could not tell it from a real run.
        // "Already enrolled" counts as success: that is the idempotent re-run working as intended.
        if (strategies.length > 0 && configured == 0 && alreadyEnrolled == 0) {
            revert("NOTHING_CONFIGURED_EVERY_STRATEGY_SKIPPED");
        }
    }

    /// @notice Whether enrollment steps 2 and 3 still need to run for this strategy.
    /// @dev The whole safety of re-running this script rests here. A seating wipes every secondary
    ///      manager, so an executor that is STILL a secondary proves no seating has occurred since
    ///      it was enrolled, which proves no session keys survive from a prior tenure. Running the
    ///      steps anyway would invalidate the keeper keys granted in step 4 and silently stop the
    ///      keepers. Returning false here is therefore a correctness requirement, not an
    ///      optimisation.
    /// @param aggregator The SuperVaultAggregator
    /// @param executor The Counsel's executor
    /// @param strategy The strategy being enrolled
    /// @return True when the steps must run, false when they must be skipped
    function _needsEnrollment(
        ISuperVaultAggregator aggregator,
        address executor,
        address strategy
    )
        internal
        view
        returns (bool)
    {
        return !aggregator.isSecondaryManager(executor, strategy);
    }

    /// @notice Read-only enrollment status for one strategy's Counsel
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    /// @param strategy The strategy to check
    function runCheck(uint256 env, uint64 chainId, string calldata branchName, address strategy) external {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        (SuperVaultCounsel counsel, ISuperVaultAggregator aggregator, address executor) =
            _resolve(env, chainId, branchName, strategy);

        console2.log("====== SuperVaultCounsel Enrollment Status ======");
        console2.log("Chain ID:", chainId);
        console2.log("Strategy:", strategy);
        console2.log("Counsel:", address(counsel));
        console2.log("Counsel OPERATOR:", counsel.OPERATOR());
        console2.log("");

        address mainManager = aggregator.getMainManager(strategy);
        console2.log("[Step 1] mainManager:", mainManager);
        console2.log("[Step 1] Counsel seated as primary:", mainManager == address(counsel));
        console2.log("[Step 3] Executor enrolled as secondary:", aggregator.isSecondaryManager(executor, strategy));
        console2.log(
            "[Step 2] invalidateAllSessionKeys leaves no on-chain flag to read - see the executor's AllSessionKeysInvalidated events"
        );

        address[] memory secondaries = aggregator.getSecondaryManagers(strategy);
        console2.log("Secondary managers (audit - runbook step 0):", secondaries.length);
        for (uint256 i = 0; i < secondaries.length; i++) {
            console2.log("  -", secondaries[i], secondaries[i] == executor ? "(executor)" : "");
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Resolve the Counsel (per-strategy output key), Aggregator, and Executor
    function _resolve(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        address strategy
    )
        internal
        view
        returns (SuperVaultCounsel counsel, ISuperVaultAggregator aggregator, address executor)
    {
        require(strategy != address(0), "INVALID_STRATEGY");

        string memory json = vm.readFile(_outputJsonPath(env, chainId, branchName));

        string memory counselKey = string(abi.encodePacked(".SuperVaultCounsel_", vm.toString(strategy)));
        require(vm.keyExistsJson(json, counselKey), "COUNSEL_NOT_IN_OUTPUT_JSON_DEPLOY_FIRST");
        address counselAddr = vm.parseJsonAddress(json, counselKey);
        require(counselAddr != address(0), "COUNSEL_NOT_IN_OUTPUT_JSON_DEPLOY_FIRST");
        require(counselAddr.code.length > 0, "COUNSEL_NOT_DEPLOYED");

        address aggregatorAddr = vm.parseJsonAddress(json, ".SuperVaultAggregator");
        require(aggregatorAddr != address(0), "AGGREGATOR_NOT_FOUND_IN_OUTPUT");

        counsel = SuperVaultCounsel(payable(counselAddr));
        aggregator = ISuperVaultAggregator(aggregatorAddr);
        executor = address(counsel.EXECUTOR());

        // The Counsel's immutable strategy must match the requested one (guards against a
        // stale/mismatched output-JSON entry)
        require(address(counsel.STRATEGY()) == strategy, "COUNSEL_STRATEGY_MISMATCH");
    }

    /// @notice Read the curated strategy list for this env+chain from counsel-fleet.json
    ///         (per-strategy entry objects; only the .strategy field is needed here)
    function _readFleetStrategies(uint256 env, uint64 chainId) internal view returns (address[] memory strategies) {
        string memory json = vm.readFile(string(abi.encodePacked(vm.projectRoot(), "/script/utils/counsel-fleet.json")));
        // env 0 = prod; everything else (staging/vnet) uses the staging fleet section
        string memory base =
            string(abi.encodePacked(env == 0 ? ".prod" : ".staging", ".strategies.", vm.toString(uint256(chainId))));
        require(vm.keyExistsJson(json, base), "CHAIN_NOT_IN_COUNSEL_FLEET_JSON");

        uint256 n;
        while (vm.keyExistsJson(json, string(abi.encodePacked(base, "[", vm.toString(n), "]")))) {
            n++;
        }
        strategies = new address[](n);
        for (uint256 i = 0; i < n; i++) {
            strategies[i] =
                vm.parseJsonAddress(json, string(abi.encodePacked(base, "[", vm.toString(i), "]", ".strategy")));
        }
    }

    /// @notice Non-reverting Counsel lookup for the fleet path
    function _tryResolveCounsel(string memory json, address strategy) internal view returns (address) {
        string memory key = string(abi.encodePacked(".SuperVaultCounsel_", vm.toString(strategy)));
        if (!vm.keyExistsJson(json, key)) return address(0);
        return vm.parseJsonAddress(json, key);
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
}
