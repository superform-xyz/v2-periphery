// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// Superform
import { ISuperVaultStrategy } from "./ISuperVaultStrategy.sol";
import { ISuperVaultExecutor } from "./ISuperVaultExecutor.sol";
import { ISuperVaultAggregator } from "./ISuperVaultAggregator.sol";

/// @title ISuperVaultCounsel
/// @author Superform Labs
/// @notice Interface for the SuperVaultCounsel — an immutable, ownerless adapter that occupies
///         the SuperVault primary-manager/curator seat. Every sharp curator lever (yield-source
///         additions, strategy hooks-root replacement, PPS deviation-threshold changes,
///         global-leaf ban/unban, min-update-interval changes, secondary-manager additions,
///         Counsel migration offers) exists only behind a propose → guardian-veto-window →
///         execute flow; day-to-day operations are typed, operator-only forwards. The adapter's
///         entire authority is enumerable from this ABI.
interface ISuperVaultCounsel {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a zero address is supplied where one is not permitted
    error ZERO_ADDRESS();

    /// @notice Thrown when constructor timing or bounds configuration is invalid
    error INVALID_CONFIG();

    /// @notice Thrown when a caller other than the immutable operator invokes an operator function
    error NOT_OPERATOR();

    /// @notice Thrown when veto is called by an address that is not a live SuperGovernor guardian
    error NOT_GUARDIAN();

    /// @notice Thrown when invalidateAllSessionKeys is called by neither the operator nor a guardian
    error NOT_AUTHORIZED();

    /// @notice Thrown when a proposal is not in a vetoable state (Pending or Ready)
    /// @param id The proposal id
    /// @param current The proposal's current derived status
    error PROPOSAL_NOT_VETOABLE(uint256 id, ProposalStatus current);

    /// @notice Thrown when execute is called on a proposal that is not Ready
    /// @param id The proposal id
    /// @param current The proposal's current derived status
    error PROPOSAL_NOT_READY(uint256 id, ProposalStatus current);

    /// @notice Thrown when a proposed deviation threshold is outside the immutable bounds
    /// @param newThreshold The rejected threshold
    /// @param min The immutable floor
    /// @param max The immutable ceiling
    error THRESHOLD_OUT_OF_BOUNDS(uint256 newThreshold, uint256 min, uint256 max);

    /// @notice Thrown when a proposed root or manifest hash is zero
    error INVALID_ROOT();

    /// @notice Thrown when a proposed successor Counsel is invalid (zero, self, codeless, or
    ///         wired to a different strategy/aggregator)
    error INVALID_MIGRATION_TARGET();

    /// @notice Thrown when a global-leaves proposal has empty or length-mismatched arrays
    error INVALID_LEAVES();

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    /// @notice Lifecycle status of a proposal
    /// @dev None MUST stay first so unset mapping slots decode to None. Ready and Expired are
    ///      derived from timestamps in state() and are never written to storage; the stored
    ///      subset is None/Pending/Executed/Vetoed.
    enum ProposalStatus {
        None, // 0: does not exist
        Pending, // 1: proposed, veto window running (stored)
        Ready, // 2: window passed un-vetoed, executable (derived)
        Executed, // 3: executed (stored, terminal)
        Vetoed, // 4: vetoed by a guardian (stored, terminal)
        Expired // 5: not executed before expiry (derived, terminal)
    }

    /// @notice The veto-gated action types
    enum ActionType {
        YieldSourceAdd, // 0: strategy.manageYieldSource(source, oracle, Add)
        StrategyRoot, // 1: aggregator.proposeStrategyHooksRoot(strategy, root)
        DeviationThreshold, // 2: aggregator.updateDeviationThreshold(strategy, newThreshold)
        CounselMigration, // 3: aggregator.addSecondaryManager(strategy, newCounsel) — the "offer"
        GlobalLeavesStatus, // 4: aggregator.changeGlobalLeavesStatus(leaves, statuses, strategy)
        MinUpdateInterval, // 5: aggregator.proposeMinUpdateIntervalChange(strategy, interval) — two-leg
        SecondaryManagerAdd // 6: aggregator.addSecondaryManager(strategy, manager)
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Full stored proposal: execute(id) forwards exactly these args, making argument
    ///         mutation structurally impossible
    struct Proposal {
        /// @notice Timestamp the proposal was created (packed with status and actionType)
        uint64 proposedAt;
        /// @notice Stored status subset: None/Pending/Executed/Vetoed
        ProposalStatus status;
        /// @notice Which veto-gated action this proposal performs on execute
        ActionType actionType;
        /// @notice YieldSourceAdd: the yield source to add
        address source;
        /// @notice YieldSourceAdd: the oracle for the yield source
        address oracle;
        /// @notice StrategyRoot: the replacement strategy hooks root
        bytes32 root;
        /// @notice StrategyRoot: hash of the published leaf manifest the guardian reviews
        bytes32 manifestHash;
        /// @notice DeviationThreshold: the new PPS deviation threshold
        uint256 newThreshold;
        /// @notice CounselMigration: the successor Counsel offered the seat
        address newCounsel;
        /// @notice GlobalLeavesStatus: the global-root leaves to update
        bytes32[] leaves;
        /// @notice GlobalLeavesStatus: banned status per leaf (true = banned)
        bool[] statuses;
        /// @notice MinUpdateInterval: the new minimum PPS update interval
        uint256 newMinUpdateInterval;
        /// @notice SecondaryManagerAdd: the manager to seat as secondary
        address newSecondaryManager;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a veto-gated proposal is created
    /// @dev Emits the full stored proposal so monitors can evaluate it without an eth_call;
    ///      vetoDeadline and expiry are absolute timestamps so monitors need no chain constants
    event ProposalCreated(
        uint256 indexed id,
        ActionType indexed actionType,
        address indexed proposer,
        Proposal proposal,
        uint256 vetoDeadline,
        uint256 expiry
    );

    /// @notice Emitted when a guardian vetoes a proposal (terminal)
    event ProposalVetoed(uint256 indexed id, address indexed guardian);

    /// @notice Emitted when the operator executes a matured proposal (terminal)
    event ProposalExecuted(uint256 indexed id, address indexed executor);

    /// @notice Emitted on every operator day-to-day typed forward (post-hoc audit trail — these
    ///         forwards bypass the veto window by design)
    /// @param selector The Counsel function selector that was invoked
    event OperatorActionExecuted(bytes4 indexed selector);

    /// @notice Emitted when the SuperVaultExecutor is (re-)enrolled as secondary manager
    event ExecutorEnrolled();

    /// @notice Emitted when this Counsel accepts a migration offer by proposing itself as
    ///         primary manager on the aggregator (starts the aggregator's 7-day timelock)
    event CounselSeatAccepted(address indexed feeRecipient);

    /// @notice Emitted when all session keys are invalidated via generation bump
    event AllSessionKeysInvalidated(address indexed caller);

    /// @notice Emitted when an ERC20 balance is swept to the operator
    event ERC20Swept(address indexed token, uint256 amount);

    /// @notice Emitted when the native balance is swept to the operator
    event NativeSwept(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                        VETO-GATED PROPOSALS
    //////////////////////////////////////////////////////////////*/

    /// @notice Queue an exact yield-source addition behind the veto window
    /// @dev Batches are deliberately decomposed to singles; the Add enum is fixed at execute time
    /// @param source The yield source to add; must be non-zero
    /// @param oracle The oracle for the yield source; must be non-zero
    /// @return id The monotonic proposal id
    function proposeYieldSourceAdd(address source, address oracle) external returns (uint256 id);

    /// @notice Queue a replacement strategy hooks-root behind the veto window
    /// @dev manifestHash is evidentiary: the manifest MUST be published to an append-only channel
    ///      before proposing so guardians can reproduce the root; guardians should veto any root
    ///      whose manifest is unpublished or does not derive the root
    /// @param root The replacement strategy hooks root; must be non-zero
    /// @param manifestHash Hash of the published leaf manifest; must be non-zero
    /// @return id The monotonic proposal id
    function proposeStrategyRoot(bytes32 root, bytes32 manifestHash) external returns (uint256 id);

    /// @notice Queue a PPS deviation-threshold change behind the veto window
    /// @dev Bounded by the immutable floor/ceiling — the aggregator's setter is unbounded and
    ///      type(uint256).max would disable PPS defenses entirely
    /// @param newThreshold The new deviation threshold; must be within immutable bounds
    /// @return id The monotonic proposal id
    function proposeDeviationThreshold(uint256 newThreshold) external returns (uint256 id);

    /// @notice Queue a Counsel migration offer behind the veto window (propose-and-accept step 1)
    /// @dev On execute, the successor is seated as a SECONDARY manager only — an offer, not a
    ///      handover. The seat moves only when the successor itself calls acceptCounselSeat()
    ///      (structurally restricted to the proposed contract by the aggregator's
    ///      secondary-only gate on proposeChangePrimaryManager), followed by the aggregator's
    ///      own 7-day manager-change timelock. Until then the current operator can retract via
    ///      removeSecondaryManager(newCounsel) or cancelChangePrimaryManager().
    /// @param newCounsel The successor Counsel; must be a deployed contract wired to the same
    ///        strategy and aggregator, and not this contract
    /// @return id The monotonic proposal id
    function proposeCounselMigration(address newCounsel) external returns (uint256 id);

    /// @notice Accept a migration offer: propose this Counsel as the strategy's primary manager
    ///         (propose-and-accept step 2)
    /// @dev Operator-only. Succeeds only while this Counsel holds a secondary-manager seat
    ///      (i.e., a predecessor's migration offer matured un-vetoed). Starts the aggregator's
    ///      7-day manager-change timelock; completion via the aggregator's permissionless
    ///      executeChangePrimaryManager wipes all secondaries — run the enrollment runbook after
    ///      (enrollExecutor, invalidateAllSessionKeys, re-grant keys).
    /// @param feeRecipient The fee recipient the aggregator force-sets on the strategy at handover
    function acceptCounselSeat(address feeRecipient) external;

    /// @notice Queue a global-root leaf ban/unban update behind the veto window
    /// @dev Both directions are veto-gated; for urgent defense the operator's immediate
    ///      pauseStrategy() remains the coarse substitute for banning
    /// @param leaves The global-root leaf hashes to update; non-empty
    /// @param statuses Banned status per leaf (true = banned); same length as leaves
    /// @return id The monotonic proposal id
    function proposeGlobalLeavesStatus(
        bytes32[] calldata leaves,
        bool[] calldata statuses
    )
        external
        returns (uint256 id);

    /// @notice Queue a minimum-PPS-update-interval change behind the veto window (two-leg)
    /// @dev On execute, forwards aggregator.proposeMinUpdateIntervalChange, which starts the
    ///      aggregator's own 3-day parameter timelock; its execute is permissionless (convenience
    ///      forward: executeMinUpdateIntervalChange). The aggregator enforces
    ///      interval < maxStaleness at the second leg.
    /// @param newMinUpdateInterval The new minimum update interval in seconds
    /// @return id The monotonic proposal id
    function proposeMinUpdateInterval(uint256 newMinUpdateInterval) external returns (uint256 id);

    /// @notice Queue an arbitrary secondary-manager addition behind the veto window
    /// @dev The 7-day replacement bypass this could enable stays defended: the guardian reviews
    ///      the address for 3 days, and the operator retains removeSecondaryManager and
    ///      cancelChangePrimaryManager at all times
    /// @param manager The address to seat as secondary manager; must be non-zero
    /// @return id The monotonic proposal id
    function proposeSecondaryManagerAdd(address manager) external returns (uint256 id);

    /// @notice Permanently cancel a proposal; callable by any live SuperGovernor guardian at any
    ///         time before execution — including the whole Ready period (no front-run window)
    /// @param id The proposal id to veto
    function veto(uint256 id) external;

    /// @notice Execute a matured proposal; operator-only; forwards the exact stored args
    /// @dev Executable iff block.timestamp ∈ [proposedAt + VETO_WINDOW, proposedAt + EXPIRY)
    /// @param id The proposal id to execute
    function execute(uint256 id) external;

    /*//////////////////////////////////////////////////////////////
                    TYPED FORWARDS — STRATEGY (operator)
    //////////////////////////////////////////////////////////////*/

    /// @notice Relay hook execution to the strategy with exact msg.value
    /// @param args The strategy ExecuteArgs
    function executeHooks(ISuperVaultStrategy.ExecuteArgs calldata args) external payable;

    /// @notice Fulfill redemption requests on the strategy
    function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata totalAssetsOut) external;

    /// @notice Fulfill redemption cancellation requests on the strategy
    function fulfillCancelRedeemRequests(address[] calldata controllers) external;

    /// @notice Skim accrued performance fees on the strategy
    function skimPerformanceFee() external;

    /// @notice Remove a yield source immediately; the Remove enum is hard-coded and this path can
    ///         never add or update
    /// @param source The yield source to remove
    function removeYieldSource(address source) external;

    /// @notice Propose a vault fee-config update (rides the strategy's own 1-week timelock; not
    ///         guardian-vetoable — documented risk acceptance)
    function proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    )
        external;

    /// @notice Execute a matured vault fee-config update on the strategy
    function executeVaultFeeConfigUpdate() external;

    /// @notice Manage the strategy's PPS expiration threshold (strategy-side 1-week timelock)
    function managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction action, uint256 ppsExpiration) external;

    /*//////////////////////////////////////////////////////////////
                    TYPED FORWARDS — AGGREGATOR (operator)
    //////////////////////////////////////////////////////////////*/

    /// @notice Pause the strategy on the aggregator
    function pauseStrategy() external;

    /// @notice Unpause the strategy on the aggregator
    function unpauseStrategy() external;

    /// @notice Complete a non-vetoed root proposal after the aggregator's own timelock
    /// @dev Convenience only — the aggregator function is already permissionless
    function executeStrategyHooksRootUpdate() external;

    /// @notice Propose withdrawing upkeep funds (aggregator 24h timelock)
    function proposeWithdrawUpkeep() external;

    /// @notice Execute a matured upkeep withdrawal
    /// @dev The aggregator pays the current mainManager — i.e. this contract; funds then reach the
    ///      operator via the permissionless sweeps
    function executeWithdrawUpkeep() external;

    /// @notice Complete a matured min-update-interval change on the aggregator
    /// @dev Convenience only — the aggregator function is already permissionless
    function executeMinUpdateIntervalChange() external;

    /// @notice Cancel a pending min-update-interval change on the aggregator (defensive)
    function cancelMinUpdateIntervalChange() external;

    /// @notice Remove a secondary manager from the strategy
    function removeSecondaryManager(address manager) external;

    /// @notice Cancel a hostile primary-manager-change proposal from a stale secondary
    function cancelChangePrimaryManager() external;

    /// @notice Re-enroll the immutable SuperVaultExecutor as secondary manager
    /// @dev Enrollment via changePrimaryManager wipes ALL secondary managers including the
    ///      executor, killing keepers; this hard-coded forward is the only add path and cannot be
    ///      bent toward any other address. The executor exposes no proposeChangePrimaryManager, so
    ///      this does not reopen the 7-day replacement bypass.
    function enrollExecutor() external;

    /*//////////////////////////////////////////////////////////////
                TYPED FORWARDS — EXECUTOR SESSION KEYS
    //////////////////////////////////////////////////////////////*/

    /// @notice Grant a keeper session key on the executor for the immutable strategy
    function grantSessionKey(
        address sessionKey,
        uint256 expiry,
        ISuperVaultExecutor.Permission[] calldata permissions
    )
        external;

    /// @notice Batch-grant keeper session keys on the executor for the immutable strategy
    function grantSessionKeysBatch(
        address[] calldata sessionKeys,
        uint256[] calldata expiries,
        ISuperVaultExecutor.Permission[][] calldata permissions
    )
        external;

    /// @notice Revoke a keeper session key on the executor
    function revokeSessionKey(address sessionKey) external;

    /// @notice Batch-revoke keeper session keys on the executor
    function revokeSessionKeysBatch(address[] calldata sessionKeys) external;

    /// @notice Invalidate all session keys via generation bump; operator OR any live guardian
    /// @dev MUST be called at every (re-)enrollment: keys granted in a prior tenure silently
    ///      revive if this contract is reinstated as mainManager
    function invalidateAllSessionKeys() external;

    /*//////////////////////////////////////////////////////////////
                            HOUSEKEEPING
    //////////////////////////////////////////////////////////////*/

    /// @notice Sweep the full balance of an ERC20 token to the immutable operator; permissionless
    /// @param token The token to sweep
    function sweepERC20(address token) external;

    /// @notice Sweep the full native balance to the immutable operator; permissionless
    function sweepNative() external;

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Derived lifecycle status of a proposal (Ready/Expired computed from timestamps)
    function state(uint256 id) external view returns (ProposalStatus);

    /// @notice Full stored proposal struct
    function getProposal(uint256 id) external view returns (Proposal memory);

    /// @notice The next proposal id to be assigned (== number of proposals ever created)
    function nextProposalId() external view returns (uint256);

    /// @notice Whether an address may currently veto (live SuperGovernor.isGuardian lookup)
    function canVeto(address account) external view returns (bool);

    /// @notice The single strategy this Counsel manages (immutable)
    /// @dev Also used by a predecessor Counsel to validate migration-target wiring
    function STRATEGY() external view returns (ISuperVaultStrategy);

    /// @notice The aggregator this Counsel operates on (immutable)
    /// @dev Also used by a predecessor Counsel to validate migration-target wiring
    function AGGREGATOR() external view returns (ISuperVaultAggregator);

    /// @notice The operator Safe (immutable)
    function OPERATOR() external view returns (address);
}
