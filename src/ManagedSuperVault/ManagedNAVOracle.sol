// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Superform
import { IManagedNAVOracle } from "../interfaces/ManagedSuperVault/IManagedNAVOracle.sol";
import { IManagedSuperVaultAggregator } from "../interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";

/// @title ManagedNAVOracle
/// @author Superform Labs
/// @notice Attested-manual NAV front end for Managed SuperVaults: managers propose a NAV with offchain
///         evidence, an M-of-N attestor set signs off onchain, and at threshold the value is pushed into
///         the ManagedSuperVaultAggregator via forwardPPS
/// @dev This is the managed-family counterpart of ECDSAPPSOracle (which verifies validator signatures for
///      the main family). All PPS safety rails — monotonicity, post-unpause anchoring, rate limiting,
///      staleness, and the deviation bound with auto-pause + stale marking — live downstream in the
///      aggregator's _forwardPPS. Because forwardPPS skips (rather than reverts) on a rejected value,
///      finalization reads getLastUpdateTimestamp before and after the push to learn the outcome: an
///      unchanged timestamp terminates the proposal as Rejected and the manager re-proposes.
///
///      Large-deviation runbook (replaces the earlier design's ReviewRequired/resolve state machine):
///      threshold attestation → aggregator drops the value, auto-pauses and marks PPS stale (proposal →
///      Rejected here) → manager unpauseStrategy on the aggregator → manager re-proposes with a fresh
///      observation timestamp after the unpause → attestors re-attest → the push lands because
///      _forwardPPS skips the deviation check while PPS is marked stale.
contract ManagedNAVOracle is IManagedNAVOracle {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedNAVOracle
    address public immutable MANAGED_AGGREGATOR;

    /// @dev Timelock for attestation config changes
    uint256 private constant _PARAMETER_CHANGE_TIMELOCK = 3 days;

    // Attestation config, keyed by strategy
    mapping(address strategy => EnumerableSet.AddressSet attestors) private _navAttestors;
    mapping(address strategy => uint8 threshold) private _navThreshold;
    mapping(address strategy => PendingAttestationConfig pending) private _pendingConfig;

    // Proposal lifecycle, keyed by strategy
    mapping(address strategy => uint256 id) private _nextProposalId;
    mapping(address strategy => uint256 id) private _activeProposalId;
    mapping(address strategy => mapping(uint256 proposalId => NAVUpdateProposal)) private _navProposals;
    mapping(address strategy => mapping(uint256 proposalId => mapping(address attestor => bool))) private _hasAttested;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param managedAggregator_ The ManagedSuperVaultAggregator this oracle pushes PPS into
    ///        (may be a precomputed CREATE2 address; the two contracts reference each other)
    constructor(address managedAggregator_) {
        if (managedAggregator_ == address(0)) revert ZERO_ADDRESS();
        MANAGED_AGGREGATOR = managedAggregator_;
    }

    /*//////////////////////////////////////////////////////////////
                            CONFIG LIFECYCLE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedNAVOracle
    function initializeAttestationConfig(address strategy, NavAttestationConfig calldata config) external {
        if (msg.sender != MANAGED_AGGREGATOR) revert ONLY_AGGREGATOR();
        if (_navThreshold[strategy] != 0) revert NAV_CONFIG_ALREADY_INITIALIZED();

        _validateConfig(config.attestors, config.threshold);

        uint256 len = config.attestors.length;
        for (uint256 i; i < len; ++i) {
            _navAttestors[strategy].add(config.attestors[i]);
            emit NAVAttestorAdded(strategy, config.attestors[i]);
        }
        _navThreshold[strategy] = config.threshold;

        emit NAVAttestationThresholdUpdated(strategy, config.threshold);
        emit NAVAttestationConfigInitialized(strategy, config.attestors, config.threshold);
    }

    /// @inheritdoc IManagedNAVOracle
    function proposeNAVAttestationConfig(
        address strategy,
        address[] calldata attestors,
        uint8 threshold
    )
        external
    {
        address mainManager = _requireMainManager(strategy);
        if (_navThreshold[strategy] == 0) revert NAV_CONFIG_NOT_INITIALIZED();

        _validateConfig(attestors, threshold);

        PendingAttestationConfig storage pending = _pendingConfig[strategy];
        pending.attestors = attestors;
        pending.threshold = threshold;
        pending.effectiveTime = block.timestamp + _PARAMETER_CHANGE_TIMELOCK;
        pending.managerAtPropose = mainManager;

        emit NAVAttestationConfigProposed(strategy, attestors, threshold, pending.effectiveTime);
    }

    /// @inheritdoc IManagedNAVOracle
    function executeNAVAttestationConfig(address strategy) external {
        address mainManager = _requireMainManager(strategy);

        PendingAttestationConfig storage pending = _pendingConfig[strategy];
        if (pending.effectiveTime == 0) revert NO_PENDING_NAV_CONFIG();
        if (block.timestamp < pending.effectiveTime) revert NAV_CONFIG_TIMELOCK_NOT_EXPIRED();

        // SECURITY: a pending config proposed by an outgoing manager must not survive a takeover —
        // auto-cancel instead of executing when the main manager changed since the proposal
        if (pending.managerAtPropose != mainManager) {
            delete _pendingConfig[strategy];
            emit NAVAttestationConfigCancelled(strategy);
            return;
        }

        // SECURITY: cancel any in-flight proposal so attestations collected under the OLD attestor set
        // cannot finalize under the new set/threshold (no stale-attestation carry across a config swap)
        uint256 activeId = _activeProposalId[strategy];
        if (activeId != 0) {
            _navProposals[strategy][activeId].status = NAVProposalStatus.Canceled;
            _activeProposalId[strategy] = 0;
            emit NAVProposalCanceled(strategy, activeId, msg.sender);
        }

        // Clear the current attestor set
        address[] memory current = _navAttestors[strategy].values();
        for (uint256 i; i < current.length; ++i) {
            _navAttestors[strategy].remove(current[i]);
            emit NAVAttestorRemoved(strategy, current[i]);
        }

        // Install the new attestor set + threshold
        address[] memory next = pending.attestors;
        for (uint256 i; i < next.length; ++i) {
            _navAttestors[strategy].add(next[i]);
            emit NAVAttestorAdded(strategy, next[i]);
        }
        _navThreshold[strategy] = pending.threshold;
        emit NAVAttestationThresholdUpdated(strategy, pending.threshold);

        delete _pendingConfig[strategy];
    }

    /// @inheritdoc IManagedNAVOracle
    function cancelNAVAttestationConfig(address strategy) external {
        _requireMainManager(strategy);
        if (_pendingConfig[strategy].effectiveTime == 0) revert NO_PENDING_NAV_CONFIG();

        delete _pendingConfig[strategy];

        emit NAVAttestationConfigCancelled(strategy);
    }

    /*//////////////////////////////////////////////////////////////
                            NAV LIFECYCLE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedNAVOracle
    function proposeNAVUpdate(
        address strategy,
        uint256 newPPS,
        uint256 effectiveTimestamp,
        bytes32 evidenceHash,
        string calldata evidenceURI
    )
        external
        returns (uint256 proposalId)
    {
        IManagedSuperVaultAggregator aggregator = IManagedSuperVaultAggregator(MANAGED_AGGREGATOR);
        if (!aggregator.isAnyManager(msg.sender, strategy)) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        if (_navThreshold[strategy] == 0) revert NAV_CONFIG_NOT_INITIALIZED();

        if (newPPS == 0) revert INVALID_NAV();
        if (evidenceHash == bytes32(0)) revert EVIDENCE_REQUIRED();

        // Only one active proposal at a time; an existing pending proposal must be explicitly
        // cancelled (cancelNAVUpdate) first
        if (_activeProposalId[strategy] != 0) revert NAV_PROPOSAL_PENDING();

        // Prechecks mirroring the aggregator's _forwardPPS acceptance rules, so obviously-doomed
        // proposals revert here rather than collecting attestations and dying at finalize. The
        // authoritative checks still run downstream at push time.
        if (aggregator.isStrategyPaused(strategy)) revert STRATEGY_PAUSED();
        uint256 lastUpdate = aggregator.getLastUpdateTimestamp(strategy);
        if (
            effectiveTimestamp > block.timestamp || effectiveTimestamp <= lastUpdate
                || effectiveTimestamp <= aggregator.getLastUnpauseTimestamp(strategy)
                || block.timestamp - effectiveTimestamp > aggregator.getMaxStaleness(strategy)
                || effectiveTimestamp - lastUpdate < aggregator.getMinUpdateInterval(strategy)
        ) revert INVALID_TIMESTAMP();

        proposalId = ++_nextProposalId[strategy];
        _navProposals[strategy][proposalId] = NAVUpdateProposal({
            proposedPPS: newPPS,
            effectiveTimestamp: effectiveTimestamp,
            evidenceHash: evidenceHash,
            evidenceURI: evidenceURI,
            proposer: msg.sender,
            managerAtPropose: aggregator.getMainManager(strategy),
            attestationCount: 0,
            status: NAVProposalStatus.PendingAttestation
        });
        _activeProposalId[strategy] = proposalId;

        emit NAVProposed(
            strategy,
            proposalId,
            aggregator.getPPS(strategy),
            newPPS,
            effectiveTimestamp,
            msg.sender,
            evidenceHash,
            evidenceURI
        );
    }

    /// @inheritdoc IManagedNAVOracle
    function attestNAVUpdate(address strategy, uint256 proposalId) external {
        if (!_navAttestors[strategy].contains(msg.sender)) revert NOT_NAV_ATTESTOR();

        NAVUpdateProposal storage proposal = _navProposals[strategy][proposalId];
        if (proposal.status != NAVProposalStatus.PendingAttestation) revert NAV_PROPOSAL_NOT_PENDING();
        if (msg.sender == proposal.proposer) revert ATTESTOR_CANNOT_BE_PROPOSER();
        if (_hasAttested[strategy][proposalId][msg.sender]) revert ALREADY_ATTESTED();

        // SECURITY: a proposal created under an outgoing main manager must not survive a takeover —
        // auto-cancel instead of attesting when the main manager changed since the proposal. The
        // transaction succeeds (reverting would roll the cancellation back); watch NAVProposalCanceled.
        if (IManagedSuperVaultAggregator(MANAGED_AGGREGATOR).getMainManager(strategy) != proposal.managerAtPropose) {
            proposal.status = NAVProposalStatus.Canceled;
            _activeProposalId[strategy] = 0;
            emit NAVProposalCanceled(strategy, proposalId, msg.sender);
            return;
        }

        _hasAttested[strategy][proposalId][msg.sender] = true;
        proposal.attestationCount += 1;

        emit NAVAttested(strategy, proposalId, msg.sender, proposal.attestationCount);

        if (proposal.attestationCount >= _navThreshold[strategy]) {
            _finalizeNAV(strategy, proposalId, proposal);
        }
    }

    /// @inheritdoc IManagedNAVOracle
    function cancelNAVUpdate(address strategy, uint256 proposalId) external {
        if (!IManagedSuperVaultAggregator(MANAGED_AGGREGATOR).isAnyManager(msg.sender, strategy)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        NAVUpdateProposal storage proposal = _navProposals[strategy][proposalId];
        if (proposal.status != NAVProposalStatus.PendingAttestation) revert NAV_PROPOSAL_NOT_PENDING();

        proposal.status = NAVProposalStatus.Canceled;
        if (_activeProposalId[strategy] == proposalId) _activeProposalId[strategy] = 0;

        emit NAVProposalCanceled(strategy, proposalId, msg.sender);
    }

    /// @notice Pushes an attested value into the aggregator and records the outcome
    /// @dev forwardPPS skips (never reverts) on rejection — monotonicity, rate limit, staleness, or the
    ///      deviation bound (which also auto-pauses the strategy and marks PPS stale). The only robust
    ///      acceptance signal is getLastUpdateTimestamp changing across the push: comparing to the
    ///      proposal timestamp would false-positive if e.g. a fee skim landed in between. On rejection
    ///      the proposal terminates as Rejected and the manager re-proposes (see the deviation runbook
    ///      in the contract natspec).
    function _finalizeNAV(address strategy, uint256 proposalId, NAVUpdateProposal storage proposal) private {
        IManagedSuperVaultAggregator aggregator = IManagedSuperVaultAggregator(MANAGED_AGGREGATOR);

        uint256 lastUpdateBefore = aggregator.getLastUpdateTimestamp(strategy);

        address[] memory strategies = new address[](1);
        uint256[] memory ppss = new uint256[](1);
        uint256[] memory timestamps = new uint256[](1);
        strategies[0] = strategy;
        ppss[0] = proposal.proposedPPS;
        timestamps[0] = proposal.effectiveTimestamp;

        aggregator.forwardPPS(
            IManagedSuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: proposal.proposer
            })
        );

        _activeProposalId[strategy] = 0;

        if (aggregator.getLastUpdateTimestamp(strategy) != lastUpdateBefore) {
            proposal.status = NAVProposalStatus.Finalized;
            emit NAVFinalized(strategy, proposalId, proposal.proposedPPS, proposal.effectiveTimestamp);
        } else {
            proposal.status = NAVProposalStatus.Rejected;
            emit NAVRejected(strategy, proposalId, proposal.proposedPPS);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedNAVOracle
    function NAV_MODE() external pure returns (string memory) {
        return "attested_manual";
    }

    /// @inheritdoc IManagedNAVOracle
    function getNAVProposal(
        address strategy,
        uint256 proposalId
    )
        external
        view
        returns (NAVUpdateProposal memory proposal)
    {
        return _navProposals[strategy][proposalId];
    }

    /// @inheritdoc IManagedNAVOracle
    function getActiveNAVProposalId(address strategy) external view returns (uint256 proposalId) {
        return _activeProposalId[strategy];
    }

    /// @inheritdoc IManagedNAVOracle
    function getNAVAttestors(address strategy) external view returns (address[] memory attestors) {
        return _navAttestors[strategy].values();
    }

    /// @inheritdoc IManagedNAVOracle
    function getNAVAttestationThreshold(address strategy) external view returns (uint8 threshold) {
        return _navThreshold[strategy];
    }

    /// @inheritdoc IManagedNAVOracle
    function isNAVAttestor(address strategy, address attestor) external view returns (bool) {
        return _navAttestors[strategy].contains(attestor);
    }

    /// @inheritdoc IManagedNAVOracle
    function hasAttested(address strategy, uint256 proposalId, address attestor) external view returns (bool) {
        return _hasAttested[strategy][proposalId][attestor];
    }

    /// @inheritdoc IManagedNAVOracle
    function getPendingNAVAttestationConfig(address strategy)
        external
        view
        returns (PendingAttestationConfig memory pending)
    {
        return _pendingConfig[strategy];
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev Reverts unless msg.sender is the strategy's main manager; returns the main manager
    function _requireMainManager(address strategy) private view returns (address mainManager) {
        mainManager = IManagedSuperVaultAggregator(MANAGED_AGGREGATOR).getMainManager(strategy);
        if (msg.sender != mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();
    }

    /// @dev Validates an attestation config: non-empty set, threshold in [1, len], no zero or duplicate attestors
    function _validateConfig(address[] calldata attestors, uint8 threshold) private pure {
        uint256 len = attestors.length;
        if (len == 0 || threshold == 0 || threshold > len) revert INVALID_ATTESTATION_CONFIG();
        for (uint256 i; i < len; ++i) {
            if (attestors[i] == address(0)) revert ZERO_ADDRESS();
            for (uint256 j = i + 1; j < len; ++j) {
                if (attestors[i] == attestors[j]) revert ATTESTOR_ALREADY_EXISTS();
            }
        }
    }
}
