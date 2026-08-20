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
///           2. counsel.enrollExecutor()           (re-adds the executor the seating wiped)
///           3. counsel.invalidateAllSessionKeys() (kills any keys from a prior tenure)
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

        // Pre-flight: both calls below are operator-gated
        address operator = counsel.OPERATOR();
        console2.log("Counsel OPERATOR:", operator);
        console2.log("Broadcaster:", msg.sender);
        require(msg.sender == operator, "BROADCASTER_IS_NOT_COUNSEL_OPERATOR");

        // Step 2: re-enroll the executor (seating wiped all secondary managers)
        if (aggregator.isSecondaryManager(executor, strategy)) {
            console2.log("[Step 2] Executor already enrolled as secondary manager - skipping");
        } else {
            console2.log("[Step 2] Calling enrollExecutor()...");
            counsel.enrollExecutor();
            console2.log("[Step 2] DONE");
        }

        // Step 3: invalidate any session keys surviving from a prior tenure
        console2.log("[Step 3] Calling invalidateAllSessionKeys()...");
        counsel.invalidateAllSessionKeys();
        console2.log("[Step 3] DONE");

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
    ///      enrollExecutor() + invalidateAllSessionKeys().
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
        console2.log("Broadcaster:", msg.sender);
        console2.log("");

        uint256 configured;
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
            if (counsel.OPERATOR() != msg.sender) {
                console2.log("    SKIP: broadcaster is not this Counsel's operator:", counsel.OPERATOR());
                skipped++;
                continue;
            }

            address executor = address(counsel.EXECUTOR());
            if (aggregator.isSecondaryManager(executor, strategy)) {
                console2.log("    enrollExecutor: already enrolled - skipping call");
            } else {
                counsel.enrollExecutor();
                console2.log("    enrollExecutor: DONE");
            }
            counsel.invalidateAllSessionKeys();
            console2.log("    invalidateAllSessionKeys: DONE");
            require(aggregator.isSecondaryManager(executor, strategy), "EXECUTOR_ENROLLMENT_FAILED");
            configured++;
        }

        console2.log("");
        console2.log("====== Fleet enrollment complete ======");
        console2.log("Configured:", configured);
        console2.log("Skipped:", skipped);
        console2.log("NEXT: operator runs grantSessionKeysBatch(...) per configured strategy (step 4)");
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
        console2.log("[Step 2] Executor enrolled as secondary:", aggregator.isSecondaryManager(executor, strategy));

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
    function _readFleetStrategies(uint256 env, uint64 chainId) internal view returns (address[] memory) {
        string memory json = vm.readFile(string(abi.encodePacked(vm.projectRoot(), "/script/utils/counsel-fleet.json")));
        // env 0 = prod; everything else (staging/vnet) uses the staging fleet section
        string memory key = string(
            abi.encodePacked(env == 0 ? ".prod" : ".staging", ".strategies.", vm.toString(uint256(chainId)))
        );
        require(vm.keyExistsJson(json, key), "CHAIN_NOT_IN_COUNSEL_FLEET_JSON");
        return vm.parseJsonAddressArray(json, key);
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
