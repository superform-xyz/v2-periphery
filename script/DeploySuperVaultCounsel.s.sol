// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperVaultCounsel } from "../src/SuperVault/SuperVaultCounsel.sol";
import { ISuperVaultAggregator } from "../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
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
        _deploy(env, chainId, branchName, operator, strategy, minDeviationThreshold, maxDeviationThreshold);
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

        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.operator = operator;
        p.strategy = strategy;
        p.minDev = minDeviationThreshold;
        p.maxDev = maxDeviationThreshold;
        (p.superGovernor, p.aggregator, p.executor) = _resolveAddresses(env, chainId, branchName);

        console2.log("====== SuperVaultCounsel Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Strategy:", strategy);
        console2.log("Operator:", operator);
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
    }

    /// @notice Internal deployment function
    function _deploy(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        address operator,
        address strategy,
        uint256 minDeviationThreshold,
        uint256 maxDeviationThreshold
    )
        internal
    {
        DeployParams memory p;
        p.env = env;
        p.chainId = chainId;
        p.operator = operator;
        p.strategy = strategy;
        p.minDev = minDeviationThreshold;
        p.maxDev = maxDeviationThreshold;
        (p.superGovernor, p.aggregator, p.executor) = _resolveAddresses(env, chainId, branchName);

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
        _writeCounselJson(env, chainId, counselAddr, strategy, branchName);

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
            p.operator, p.superGovernor, p.aggregator, p.strategy, p.executor, VETO_WINDOW, EXPIRY, p.minDev, p.maxDev
        );
    }

    /// @notice Verify every immutable on the deployed Counsel matches the intended configuration
    function _verifyDeployment(DeployParams memory p, address counselAddr) internal view {
        SuperVaultCounsel counsel = SuperVaultCounsel(payable(counselAddr));
        require(counsel.OPERATOR() == p.operator, "OPERATOR_MISMATCH");
        require(address(counsel.SUPER_GOVERNOR()) == p.superGovernor, "SUPER_GOVERNOR_MISMATCH");
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

    /// @notice Compute the deterministic address for a strategy's Counsel
    function _computeAddress(DeployParams memory p) internal view returns (address) {
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(_getCounselBytecode(p.env), _encodeConstructorArgs(p)), __getSalt(_saltName(p.strategy))
        );
    }
}
