// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultCounsel } from "../interfaces/SuperVault/ISuperVaultCounsel.sol";
import { IVetoRegistry } from "../interfaces/SuperVault/IVetoRegistry.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultExecutor } from "../interfaces/SuperVault/ISuperVaultExecutor.sol";

/// @title SuperVaultCounsel
/// @author Superform Labs
/// @notice Immutable, ownerless adapter occupying the SuperVault primary-manager/curator seat.
///         Every sharp curator lever — yield-source additions, strategy hooks-root replacement,
///         PPS deviation-threshold changes, global-leaf ban/unban, min-update-interval changes,
///         secondary-manager additions, and Counsel migration offers — exists only behind a
///         propose → guardian-veto-window → execute flow. Any live SuperGovernor guardian can
///         veto up to the moment of execution. Day-to-day operations are typed, operator-only
///         forwards; there is no generic call path, no owner, no upgradeability.
/// @dev One instance per strategy; all counterparties and timing immutable from the constructor.
///      Replacement paths (two, both heavily guarded):
///        1. SuperGovernor.changePrimaryManager emergency takeover — instant, msig-only.
///        2. Propose-and-accept migration: this Counsel's operator queues
///           proposeCounselMigration(newCounsel) (3-day guardian veto window), which on execute
///           seats the successor as SECONDARY manager only; the successor must then itself call
///           acceptCounselSeat() (structurally restricted to the offered contract by the
///           aggregator's secondary-only gate), starting the aggregator's 7-day manager-change
///           timelock, during which the current operator can still cancelChangePrimaryManager().
///      OPERATIONAL INVARIANTS (runbook):
///        - Never call SuperGovernor.freezeManagerTakeover() while a Counsel is enrolled — it is
///          permanent and removes the only adapter-replacement path.
///        - Enrollment sequence: takeover/create → enrollExecutor() → invalidateAllSessionKeys()
///          → grantSessionKeysBatch(...). Session keys from a prior tenure silently revive on
///          reinstatement unless invalidated.
///        - The strategy-root manifest MUST be published to an append-only channel before
///          proposeStrategyRoot; guardians veto any root whose manifest is unpublished or does
///          not reproduce the root (the hash binding is evidentiary, not cryptographic).
contract SuperVaultCounsel is ISuperVaultCounsel, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The operator Safe: proposer, executor of matured proposals, and day-to-day caller
    address public immutable OPERATOR;

    /// @notice SuperGovernor used for live guardian lookups
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @notice Veto-authority registry consulted by veto/canVeto/invalidateAllSessionKeys
    /// @dev Defaults to SUPER_GOVERNOR when constructed with address(0). Per-instance so veto
    ///      authority is pluggable (e.g. a Newton attestation shim) without protocol-wide
    ///      GUARDIAN_ROLE. NOT required equal on migration - guardian-reviewed like any diff.
    IVetoRegistry public immutable VETO_REGISTRY;

    /// @notice The SuperVaultAggregator this Counsel manages the strategy on
    ISuperVaultAggregator public immutable AGGREGATOR;

    /// @notice The single strategy this Counsel is the primary manager of
    ISuperVaultStrategy public immutable STRATEGY;

    /// @notice The keeper session-key module; sole target of enrollExecutor()
    ISuperVaultExecutor public immutable EXECUTOR;

    /// @notice Guardian veto window measured from proposedAt
    uint256 public immutable VETO_WINDOW;

    /// @notice Proposal expiry measured from proposedAt; executable in [VETO_WINDOW, EXPIRY)
    uint256 public immutable EXPIRY;

    /// @notice Immutable floor for proposeDeviationThreshold
    uint256 public immutable MIN_DEVIATION_THRESHOLD;

    /// @notice Immutable ceiling for proposeDeviationThreshold
    uint256 public immutable MAX_DEVIATION_THRESHOLD;

    /// @notice Proposals by monotonic id
    mapping(uint256 id => Proposal proposal) private _proposals;

    /// @notice Next proposal id; ids are never reused
    uint256 private _nextProposalId;

    /// @notice Strategy's performance-fee cap, mirrored for propose-time validation
    uint256 private constant MAX_PERFORMANCE_FEE_BPS = 5100;

    /// @notice Strategy's management (asset-side entry) fee cap, mirrored for propose-time validation
    uint256 private constant MAX_MANAGEMENT_FEE_BPS = 10_000;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOperator() {
        if (msg.sender != OPERATOR) revert NOT_OPERATOR();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy the Counsel with its full, final configuration — nothing is settable later
    /// @dev No code-length checks on operator_: Safes may be counterfactual at deploy time
    /// @param operator_ The operator Safe; must be non-zero
    /// @param superGovernor_ SuperGovernor for live isGuardian lookups; must be non-zero
    /// @param vetoRegistry_ Veto-authority registry; address(0) defaults to superGovernor_
    /// @param aggregator_ The SuperVaultAggregator; must be non-zero
    /// @param strategy_ The managed strategy; must be non-zero
    /// @param executor_ The SuperVaultExecutor session-key module; must be non-zero
    /// @param vetoWindow_ Guardian veto window in seconds; must be non-zero
    /// @param expiry_ Proposal expiry in seconds from proposedAt; must exceed vetoWindow_
    /// @param minDeviationThreshold_ Floor for deviation-threshold proposals; must be non-zero
    /// @param maxDeviationThreshold_ Ceiling for deviation-threshold proposals; must be >= floor
    ///        and < type(uint256).max (max uint disables the aggregator's PPS deviation check)
    constructor(
        address operator_,
        address superGovernor_,
        address vetoRegistry_,
        address aggregator_,
        address strategy_,
        address executor_,
        uint256 vetoWindow_,
        uint256 expiry_,
        uint256 minDeviationThreshold_,
        uint256 maxDeviationThreshold_
    ) {
        if (
            operator_ == address(0) || superGovernor_ == address(0) || aggregator_ == address(0)
                || strategy_ == address(0) || executor_ == address(0)
        ) revert ZERO_ADDRESS();
        if (
            vetoWindow_ == 0 || expiry_ <= vetoWindow_ || minDeviationThreshold_ == 0
                || maxDeviationThreshold_ < minDeviationThreshold_ || maxDeviationThreshold_ == type(uint256).max
        ) revert INVALID_CONFIG();

        OPERATOR = operator_;
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        VETO_REGISTRY = IVetoRegistry(vetoRegistry_ == address(0) ? superGovernor_ : vetoRegistry_);
        AGGREGATOR = ISuperVaultAggregator(aggregator_);
        STRATEGY = ISuperVaultStrategy(strategy_);
        EXECUTOR = ISuperVaultExecutor(executor_);
        VETO_WINDOW = vetoWindow_;
        EXPIRY = expiry_;
        MIN_DEVIATION_THRESHOLD = minDeviationThreshold_;
        MAX_DEVIATION_THRESHOLD = maxDeviationThreshold_;
    }

    /*//////////////////////////////////////////////////////////////
                        VETO-GATED PROPOSALS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultCounsel
    function proposeYieldSourceAdd(address source, address oracle) external onlyOperator returns (uint256 id) {
        if (source == address(0) || oracle == address(0)) revert ZERO_ADDRESS();
        Proposal memory p;
        p.actionType = ActionType.YieldSourceAdd;
        p.source = source;
        p.oracle = oracle;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeStrategyRoot(bytes32 root, bytes32 manifestHash) external onlyOperator returns (uint256 id) {
        if (root == bytes32(0) || manifestHash == bytes32(0)) revert INVALID_ROOT();
        Proposal memory p;
        p.actionType = ActionType.StrategyRoot;
        p.root = root;
        p.manifestHash = manifestHash;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeDeviationThreshold(uint256 newThreshold) external onlyOperator returns (uint256 id) {
        if (newThreshold < MIN_DEVIATION_THRESHOLD || newThreshold > MAX_DEVIATION_THRESHOLD) {
            revert THRESHOLD_OUT_OF_BOUNDS(newThreshold, MIN_DEVIATION_THRESHOLD, MAX_DEVIATION_THRESHOLD);
        }
        Proposal memory p;
        p.actionType = ActionType.DeviationThreshold;
        p.newThreshold = newThreshold;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeCounselMigration(address newCounsel) external onlyOperator returns (uint256 id) {
        // Validity predicates: the successor must be a live contract, not this instance, and
        // wired to the exact same seat. A mismatch means acceptCounselSeat() could never work
        // (the aggregator gates it per-strategy), so it is rejected at propose time where the
        // guardian reviews it.
        if (newCounsel == address(0) || newCounsel == address(this) || newCounsel.code.length == 0) {
            revert INVALID_MIGRATION_TARGET();
        }
        if (
            address(ISuperVaultCounsel(newCounsel).STRATEGY()) != address(STRATEGY)
                || address(ISuperVaultCounsel(newCounsel).AGGREGATOR()) != address(AGGREGATOR)
                || address(ISuperVaultCounsel(newCounsel).SUPER_GOVERNOR()) != address(SUPER_GOVERNOR)
        ) revert INVALID_MIGRATION_TARGET();
        // SUPER_GOVERNOR equality is a hard invariant: a successor wired to a different governor
        // has different (possibly fake) veto machinery. EXECUTOR and the timing/bound immutables
        // are deliberately NOT required equal - changing them is a legitimate use of migration -
        // but they are interface-exposed so guardians and monitors diff the full successor
        // config during the 3-day veto window.

        Proposal memory p;
        p.actionType = ActionType.CounselMigration;
        p.newCounsel = newCounsel;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeGlobalLeavesStatus(
        bytes32[] calldata leaves,
        bool[] calldata statuses
    )
        external
        onlyOperator
        returns (uint256 id)
    {
        if (leaves.length == 0 || leaves.length != statuses.length) revert INVALID_LEAVES();
        Proposal memory p;
        p.actionType = ActionType.GlobalLeavesStatus;
        p.leaves = leaves;
        p.statuses = statuses;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeMinUpdateInterval(uint256 newMinUpdateInterval) external onlyOperator returns (uint256 id) {
        // interval < maxStaleness is enforced by the aggregator at the second leg; the guardian
        // reviews the value during the veto window
        Proposal memory p;
        p.actionType = ActionType.MinUpdateInterval;
        p.newMinUpdateInterval = newMinUpdateInterval;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeSecondaryManagerAdd(address manager) external onlyOperator returns (uint256 id) {
        if (manager == address(0)) revert ZERO_ADDRESS();
        Proposal memory p;
        p.actionType = ActionType.SecondaryManagerAdd;
        p.newSecondaryManager = manager;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    /// @dev The aggregator's secondary-only gate on proposeChangePrimaryManager is what makes
    ///      this an "accept": only the contract that was offered the seat (seated as secondary by
    ///      a matured, un-vetoed CounselMigration proposal) can successfully claim it
    function acceptCounselSeat(address feeRecipient) external onlyOperator {
        if (feeRecipient == address(0)) revert ZERO_ADDRESS();
        AGGREGATOR.proposeChangePrimaryManager(address(STRATEGY), address(this), feeRecipient);
        emit CounselSeatAccepted(feeRecipient);
    }

    /// @inheritdoc ISuperVaultCounsel
    function veto(uint256 id) external {
        if (!VETO_REGISTRY.isGuardian(msg.sender)) revert NOT_GUARDIAN();
        ProposalStatus current = state(id);
        if (current != ProposalStatus.Pending && current != ProposalStatus.Ready) {
            revert PROPOSAL_NOT_VETOABLE(id, current);
        }
        _proposals[id].status = ProposalStatus.Vetoed;
        emit ProposalVetoed(id, msg.sender);
    }

    /// @inheritdoc ISuperVaultCounsel
    function execute(uint256 id) external onlyOperator nonReentrant {
        ProposalStatus current = state(id);
        if (current != ProposalStatus.Ready) revert PROPOSAL_NOT_READY(id, current);

        Proposal memory p = _proposals[id];
        // CEI: terminal status before any external call
        _proposals[id].status = ProposalStatus.Executed;

        if (p.actionType == ActionType.YieldSourceAdd) {
            STRATEGY.manageYieldSource(p.source, p.oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        } else if (p.actionType == ActionType.StrategyRoot) {
            // Starts the aggregator's own (shorter) timelock; its execute is permissionless.
            // The Counsel window above is the real defense.
            AGGREGATOR.proposeStrategyHooksRoot(address(STRATEGY), p.root);
        } else if (p.actionType == ActionType.DeviationThreshold) {
            AGGREGATOR.updateDeviationThreshold(address(STRATEGY), p.newThreshold);
        } else if (p.actionType == ActionType.CounselMigration) {
            // Seat the successor as SECONDARY only — an offer, not a handover. The seat moves
            // only if the successor itself calls acceptCounselSeat(), and the aggregator's own
            // 7-day manager-change timelock then runs. Retraction remains available via
            // removeSecondaryManager(newCounsel) / cancelChangePrimaryManager().
            AGGREGATOR.addSecondaryManager(address(STRATEGY), p.newCounsel);
        } else if (p.actionType == ActionType.GlobalLeavesStatus) {
            AGGREGATOR.changeGlobalLeavesStatus(p.leaves, p.statuses, address(STRATEGY));
        } else if (p.actionType == ActionType.MinUpdateInterval) {
            // Starts the aggregator's own 3-day parameter timelock; its execute is permissionless
            // (convenience forward: executeMinUpdateIntervalChange). The aggregator enforces
            // interval < maxStaleness here.
            AGGREGATOR.proposeMinUpdateIntervalChange(address(STRATEGY), p.newMinUpdateInterval);
        } else if (p.actionType == ActionType.SecondaryManagerAdd) {
            // Guardian-reviewed for 3 days; the operator retains removeSecondaryManager and
            // cancelChangePrimaryManager as standing defenses against the 7-day replacement
            // path this could otherwise enable.
            AGGREGATOR.addSecondaryManager(address(STRATEGY), p.newSecondaryManager);
        } else {
            // FeeConfig: starts the strategy's own 1-week fee timelock; the second leg is the
            // executeVaultFeeConfigUpdate() forward. Total path: 3-day veto + 1-week strategy
            // timelock (~10 days).
            STRATEGY.proposeVaultFeeConfigUpdate(p.performanceFeeBps, p.managementFeeBps, p.feeRecipient);
        }

        emit ProposalExecuted(id, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                    TYPED FORWARDS — STRATEGY (operator)
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultCounsel
    /// @dev Relays exact msg.value — never resident balance; refunds from the strategy land on
    ///      this contract and are recoverable via sweepNative()
    function executeHooks(ISuperVaultStrategy.ExecuteArgs calldata args) external payable onlyOperator nonReentrant {
        emit OperatorActionExecuted(this.executeHooks.selector);
        STRATEGY.executeHooks{ value: msg.value }(args);
    }

    /// @inheritdoc ISuperVaultCounsel
    function fulfillRedeemRequests(
        address[] calldata controllers,
        uint256[] calldata totalAssetsOut
    )
        external
        onlyOperator
    {
        emit OperatorActionExecuted(this.fulfillRedeemRequests.selector);
        STRATEGY.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @inheritdoc ISuperVaultCounsel
    function fulfillCancelRedeemRequests(address[] calldata controllers) external onlyOperator {
        emit OperatorActionExecuted(this.fulfillCancelRedeemRequests.selector);
        STRATEGY.fulfillCancelRedeemRequests(controllers);
    }

    /// @inheritdoc ISuperVaultCounsel
    function skimPerformanceFee() external onlyOperator {
        emit OperatorActionExecuted(this.skimPerformanceFee.selector);
        STRATEGY.skimPerformanceFee();
    }

    /// @inheritdoc ISuperVaultCounsel
    function removeYieldSource(address source) external onlyOperator {
        emit OperatorActionExecuted(this.removeYieldSource.selector);
        STRATEGY.manageYieldSource(source, address(0), ISuperVaultStrategy.YieldSourceAction.Remove);
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    )
        external
        onlyOperator
        returns (uint256 id)
    {
        // Bounds mirror the strategy's own caps so an invalid config fails at propose time,
        // where the guardian reviews it. The management fee is an ASSET-SIDE ENTRY FEE: up to
        // 100% of every deposit to an arbitrary recipient - which is exactly why this lever is
        // veto-gated rather than an immediate forward.
        if (
            performanceFeeBps > MAX_PERFORMANCE_FEE_BPS || managementFeeBps > MAX_MANAGEMENT_FEE_BPS
                || recipient == address(0)
        ) revert INVALID_FEE_CONFIG(performanceFeeBps, managementFeeBps);
        Proposal memory p;
        p.actionType = ActionType.FeeConfig;
        p.performanceFeeBps = performanceFeeBps;
        p.managementFeeBps = managementFeeBps;
        p.feeRecipient = recipient;
        id = _storeProposal(p);
    }

    /// @inheritdoc ISuperVaultCounsel
    function executeVaultFeeConfigUpdate() external onlyOperator {
        emit OperatorActionExecuted(this.executeVaultFeeConfigUpdate.selector);
        STRATEGY.executeVaultFeeConfigUpdate();
    }

    /// @inheritdoc ISuperVaultCounsel
    function managePPSExpiration(
        ISuperVaultStrategy.PPSExpirationAction action,
        uint256 ppsExpiration
    )
        external
        onlyOperator
    {
        emit OperatorActionExecuted(this.managePPSExpiration.selector);
        STRATEGY.managePPSExpiration(action, ppsExpiration);
    }

    /*//////////////////////////////////////////////////////////////
                    TYPED FORWARDS — AGGREGATOR (operator)
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultCounsel
    function pauseStrategy() external onlyOperator {
        emit OperatorActionExecuted(this.pauseStrategy.selector);
        AGGREGATOR.pauseStrategy(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function unpauseStrategy() external onlyOperator {
        emit OperatorActionExecuted(this.unpauseStrategy.selector);
        AGGREGATOR.unpauseStrategy(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function executeStrategyHooksRootUpdate() external onlyOperator {
        emit OperatorActionExecuted(this.executeStrategyHooksRootUpdate.selector);
        AGGREGATOR.executeStrategyHooksRootUpdate(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function proposeWithdrawUpkeep() external onlyOperator {
        emit OperatorActionExecuted(this.proposeWithdrawUpkeep.selector);
        AGGREGATOR.proposeWithdrawUpkeep(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function executeWithdrawUpkeep() external onlyOperator {
        emit OperatorActionExecuted(this.executeWithdrawUpkeep.selector);
        AGGREGATOR.executeWithdrawUpkeep(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function executeMinUpdateIntervalChange() external onlyOperator {
        emit OperatorActionExecuted(this.executeMinUpdateIntervalChange.selector);
        AGGREGATOR.executeMinUpdateIntervalChange(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function cancelMinUpdateIntervalChange() external onlyOperator {
        emit OperatorActionExecuted(this.cancelMinUpdateIntervalChange.selector);
        AGGREGATOR.cancelMinUpdateIntervalChange(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function removeSecondaryManager(address manager) external onlyOperator {
        emit OperatorActionExecuted(this.removeSecondaryManager.selector);
        AGGREGATOR.removeSecondaryManager(address(STRATEGY), manager);
    }

    /// @inheritdoc ISuperVaultCounsel
    function cancelChangePrimaryManager() external onlyOperator {
        emit OperatorActionExecuted(this.cancelChangePrimaryManager.selector);
        AGGREGATOR.cancelChangePrimaryManager(address(STRATEGY));
    }

    /// @inheritdoc ISuperVaultCounsel
    function enrollExecutor() external onlyOperator {
        AGGREGATOR.addSecondaryManager(address(STRATEGY), address(EXECUTOR));
        emit ExecutorEnrolled();
    }

    /*//////////////////////////////////////////////////////////////
                TYPED FORWARDS — EXECUTOR SESSION KEYS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultCounsel
    function grantSessionKey(
        address sessionKey,
        uint256 expiry,
        ISuperVaultExecutor.Permission[] calldata permissions
    )
        external
        onlyOperator
    {
        emit OperatorActionExecuted(this.grantSessionKey.selector);
        EXECUTOR.grantSessionKey(address(STRATEGY), sessionKey, expiry, permissions);
    }

    /// @inheritdoc ISuperVaultCounsel
    function grantSessionKeysBatch(
        address[] calldata sessionKeys,
        uint256[] calldata expiries,
        ISuperVaultExecutor.Permission[][] calldata permissions
    )
        external
        onlyOperator
    {
        emit OperatorActionExecuted(this.grantSessionKeysBatch.selector);
        uint256 len = sessionKeys.length;
        address[] memory strategies = new address[](len);
        for (uint256 i; i < len; ++i) {
            strategies[i] = address(STRATEGY);
        }
        EXECUTOR.grantSessionKeysBatch(strategies, sessionKeys, expiries, permissions);
    }

    /// @inheritdoc ISuperVaultCounsel
    function revokeSessionKey(address sessionKey) external onlyOperator {
        emit OperatorActionExecuted(this.revokeSessionKey.selector);
        EXECUTOR.revokeSessionKey(address(STRATEGY), sessionKey);
    }

    /// @inheritdoc ISuperVaultCounsel
    function revokeSessionKeysBatch(address[] calldata sessionKeys) external onlyOperator {
        emit OperatorActionExecuted(this.revokeSessionKeysBatch.selector);
        uint256 len = sessionKeys.length;
        address[] memory strategies = new address[](len);
        for (uint256 i; i < len; ++i) {
            strategies[i] = address(STRATEGY);
        }
        EXECUTOR.revokeSessionKeysBatch(strategies, sessionKeys);
    }

    /// @inheritdoc ISuperVaultCounsel
    function invalidateAllSessionKeys() external {
        if (msg.sender != OPERATOR && !VETO_REGISTRY.isGuardian(msg.sender)) revert NOT_AUTHORIZED();
        EXECUTOR.invalidateAllSessionKeys(address(STRATEGY));
        emit AllSessionKeysInvalidated(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            HOUSEKEEPING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultCounsel
    /// @dev Balance-snapshot pattern: transfers whatever this contract holds (fee-on-transfer
    ///      tolerant); SafeERC20 reverts cleanly for token addresses without code
    function sweepERC20(address token) external nonReentrant {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(OPERATOR, balance);
        emit ERC20Swept(token, balance);
    }

    /// @inheritdoc ISuperVaultCounsel
    /// @dev Full-gas send — the operator is a Safe whose receive() exceeds the 2300 stipend
    function sweepNative() external nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(OPERATOR), balance);
        emit NativeSwept(balance);
    }

    /// @notice Accepts ETH refunds from strategy hook execution and upkeep withdrawals; recover
    ///         via sweepNative()
    receive() external payable { }

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultCounsel
    /// @dev Ready and Expired are derived: executable iff
    ///      block.timestamp ∈ [proposedAt + VETO_WINDOW, proposedAt + EXPIRY)
    function state(uint256 id) public view returns (ProposalStatus) {
        Proposal storage p = _proposals[id];
        ProposalStatus stored = p.status;
        if (stored == ProposalStatus.Pending) {
            uint256 proposedAt = p.proposedAt;
            if (block.timestamp >= proposedAt + EXPIRY) return ProposalStatus.Expired;
            if (block.timestamp >= proposedAt + VETO_WINDOW) return ProposalStatus.Ready;
        }
        return stored;
    }

    /// @inheritdoc ISuperVaultCounsel
    function getProposal(uint256 id) external view returns (Proposal memory) {
        return _proposals[id];
    }

    /// @inheritdoc ISuperVaultCounsel
    function nextProposalId() external view returns (uint256) {
        return _nextProposalId;
    }

    /// @inheritdoc ISuperVaultCounsel
    function canVeto(address account) external view returns (bool) {
        return VETO_REGISTRY.isGuardian(account);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Assign the next monotonic id, stamp and store the proposal, emit ProposalCreated
    /// @param p The proposal with actionType and payload fields populated
    /// @return id The assigned proposal id
    function _storeProposal(Proposal memory p) internal returns (uint256 id) {
        id = _nextProposalId++;
        p.proposedAt = SafeCast.toUint64(block.timestamp);
        p.status = ProposalStatus.Pending;
        _proposals[id] = p;

        emit ProposalCreated(id, p.actionType, msg.sender, p, block.timestamp + VETO_WINDOW, block.timestamp + EXPIRY);
    }
}
