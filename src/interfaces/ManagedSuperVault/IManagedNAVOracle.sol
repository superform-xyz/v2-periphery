// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title IManagedNAVOracle
/// @author Superform Labs
/// @notice Interface for the ManagedNAVOracle — the attested-manual NAV front end for Managed SuperVaults
/// @dev The oracle collects manager proposals + M-of-N attestor sign-offs per strategy and, at threshold,
///      pushes the value into the ManagedSuperVaultAggregator via forwardPPS. All PPS safety rails
///      (monotonicity, rate limiting, staleness, deviation → auto-pause + stale) live downstream in the
///      aggregator's _forwardPPS; this contract only owns the attestation lifecycle.
interface IManagedNAVOracle {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/
    /// @notice Lifecycle status of a NAV update proposal
    /// @dev No ReviewRequired state (unlike the earlier managed-vault design): a proposal whose push is
    ///      dropped by the aggregator (deviation breach, rate limit, staleness, monotonicity) terminates
    ///      as Rejected and the manager re-proposes. A deviation breach auto-pauses the strategy in the
    ///      aggregator; after an explicit manager unpause, a fresh proposal lands because _forwardPPS
    ///      skips the deviation check while PPS is marked stale.
    enum NAVProposalStatus {
        None,
        PendingAttestation,
        Finalized,
        Rejected,
        Canceled
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @notice NAV attestation configuration for a strategy
    /// @param attestors Set of independent attestor addresses
    /// @param threshold Number of attestations required to finalize a NAV proposal (MVP: 1)
    struct NavAttestationConfig {
        address[] attestors;
        uint8 threshold;
    }

    /// @notice A NAV update proposal
    /// @param proposedPPS The proposed price-per-share (scaled to asset decimals)
    /// @param effectiveTimestamp Observation timestamp of the NAV value (not the proposal time)
    /// @param evidenceHash Hash of the offchain valuation evidence (required, never zero)
    /// @param evidenceURI URI of the offchain valuation evidence (event/indexing aid)
    /// @param proposer The manager who proposed the value (cannot attest to their own proposal)
    /// @param managerAtPropose Main manager snapshot at propose time — a mismatch at attest time
    ///        auto-cancels the proposal (manager-takeover invalidation without an aggregator callback)
    /// @param attestationCount Number of attestations collected so far
    /// @param status Lifecycle status
    struct NAVUpdateProposal {
        uint256 proposedPPS;
        uint256 effectiveTimestamp;
        bytes32 evidenceHash;
        string evidenceURI;
        address proposer;
        address managerAtPropose;
        uint8 attestationCount;
        NAVProposalStatus status;
    }

    /// @notice A pending (timelocked) attestation config change
    /// @param attestors Proposed attestor set
    /// @param threshold Proposed threshold
    /// @param effectiveTime When the change can be executed
    /// @param managerAtPropose Main manager snapshot at propose time (mismatch at execute auto-cancels)
    struct PendingAttestationConfig {
        address[] attestors;
        uint8 threshold;
        uint256 effectiveTime;
        address managerAtPropose;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a strategy's attestation config is initialized at vault creation
    event NAVAttestationConfigInitialized(address indexed strategy, address[] attestors, uint8 threshold);

    /// @notice Emitted when a NAV update is proposed
    event NAVProposed(
        address indexed strategy,
        uint256 indexed proposalId,
        uint256 previousPPS,
        uint256 proposedPPS,
        uint256 effectiveTimestamp,
        address indexed proposer,
        bytes32 evidenceHash,
        string evidenceURI
    );

    /// @notice Emitted when an attestor attests to a NAV proposal
    event NAVAttested(
        address indexed strategy, uint256 indexed proposalId, address indexed attestor, uint8 attestationCount
    );

    /// @notice Emitted when a NAV proposal reaches threshold and its value is accepted by the aggregator
    event NAVFinalized(address indexed strategy, uint256 indexed proposalId, uint256 finalizedPPS, uint256 timestamp);

    /// @notice Emitted when a NAV proposal reaches threshold but the aggregator drops the push
    ///         (deviation breach, rate limit, staleness, or monotonicity — see aggregator events for which)
    event NAVRejected(address indexed strategy, uint256 indexed proposalId, uint256 proposedPPS);

    /// @notice Emitted when a NAV proposal is cancelled (manager action, config swap, or manager change)
    event NAVProposalCanceled(address indexed strategy, uint256 indexed proposalId, address indexed canceledBy);

    /// @notice Emitted when an attestor is added to a strategy's set
    event NAVAttestorAdded(address indexed strategy, address indexed attestor);

    /// @notice Emitted when an attestor is removed from a strategy's set
    event NAVAttestorRemoved(address indexed strategy, address indexed attestor);

    /// @notice Emitted when a strategy's attestation threshold is updated
    event NAVAttestationThresholdUpdated(address indexed strategy, uint8 threshold);

    /// @notice Emitted when an attestation config change is proposed (starts the timelock)
    event NAVAttestationConfigProposed(
        address indexed strategy, address[] attestors, uint8 threshold, uint256 effectiveTime
    );

    /// @notice Emitted when a pending attestation config change is cancelled
    event NAVAttestationConfigCancelled(address indexed strategy);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when address provided is zero
    error ZERO_ADDRESS();
    /// @notice Thrown when the caller is not authorized
    error UNAUTHORIZED_UPDATE_AUTHORITY();
    /// @notice Thrown when the caller is not the managed aggregator
    error ONLY_AGGREGATOR();
    /// @notice Thrown when a proposed NAV value is zero
    error INVALID_NAV();
    /// @notice Thrown when no valuation evidence hash is provided
    error EVIDENCE_REQUIRED();
    /// @notice Thrown when the observation timestamp is in the future, not newer than the stored PPS,
    ///         not newer than the last unpause, older than maxStaleness, or inside the rate-limit window
    error INVALID_TIMESTAMP();
    /// @notice Thrown when proposing while the strategy is paused (the aggregator would drop the push)
    error STRATEGY_PAUSED();
    /// @notice Thrown when a proposal already exists for the strategy
    error NAV_PROPOSAL_PENDING();
    /// @notice Thrown when the proposal is not pending attestation
    error NAV_PROPOSAL_NOT_PENDING();
    /// @notice Thrown when the caller is not an attestor for the strategy
    error NOT_NAV_ATTESTOR();
    /// @notice Thrown when the proposer tries to attest to their own proposal
    error ATTESTOR_CANNOT_BE_PROPOSER();
    /// @notice Thrown when an attestor tries to attest twice
    error ALREADY_ATTESTED();
    /// @notice Thrown when the attestation config is invalid (empty set, zero threshold, threshold > set size)
    error INVALID_ATTESTATION_CONFIG();
    /// @notice Thrown when the attestor set contains duplicates
    error ATTESTOR_ALREADY_EXISTS();
    /// @notice Thrown when a strategy's config is already initialized
    error NAV_CONFIG_ALREADY_INITIALIZED();
    /// @notice Thrown when a strategy's config has not been initialized
    error NAV_CONFIG_NOT_INITIALIZED();
    /// @notice Thrown when there is no pending config change
    error NO_PENDING_NAV_CONFIG();
    /// @notice Thrown when the config-change timelock has not expired
    error NAV_CONFIG_TIMELOCK_NOT_EXPIRED();

    /*//////////////////////////////////////////////////////////////
                            CONFIG LIFECYCLE
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes a strategy's attestation config at vault creation
    /// @dev Only callable by the managed aggregator (during createVault), and only once per strategy
    /// @param strategy Address of the strategy
    /// @param config The attestation config (attestor set + threshold)
    function initializeAttestationConfig(address strategy, NavAttestationConfig calldata config) external;

    /// @notice Proposes a new attestation config (starts the 3-day timelock)
    /// @dev Only the strategy's main manager can propose
    function proposeNAVAttestationConfig(address strategy, address[] calldata attestors, uint8 threshold) external;

    /// @notice Executes a pending attestation config change after the timelock
    /// @dev Only the strategy's main manager can execute. Cancels any in-flight NAV proposal so
    ///      attestations collected under the old set cannot finalize under the new one. Auto-cancels
    ///      the pending config instead if the main manager changed since it was proposed.
    function executeNAVAttestationConfig(address strategy) external;

    /// @notice Cancels a pending attestation config change
    /// @dev Only the strategy's main manager can cancel
    function cancelNAVAttestationConfig(address strategy) external;

    /*//////////////////////////////////////////////////////////////
                            NAV LIFECYCLE
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes a NAV update for a strategy
    /// @dev Any manager of the strategy can propose. Prechecks mirror the aggregator's _forwardPPS
    ///      acceptance rules so obviously-doomed proposals revert here instead of dying at finalize.
    /// @param strategy Address of the strategy
    /// @param newPPS The proposed price-per-share (scaled to asset decimals)
    /// @param effectiveTimestamp Observation timestamp of the NAV value
    /// @param evidenceHash Hash of the offchain valuation evidence (required)
    /// @param evidenceURI URI of the offchain valuation evidence
    /// @return proposalId The id of the created proposal
    function proposeNAVUpdate(
        address strategy,
        uint256 newPPS,
        uint256 effectiveTimestamp,
        bytes32 evidenceHash,
        string calldata evidenceURI
    )
        external
        returns (uint256 proposalId);

    /// @notice Attests to a pending NAV proposal; finalizes (pushes to the aggregator) at threshold
    /// @dev If the strategy's main manager changed since the proposal was created, the proposal is
    ///      auto-cancelled instead of attested (the transaction succeeds; watch for NAVProposalCanceled)
    function attestNAVUpdate(address strategy, uint256 proposalId) external;

    /// @notice Cancels a pending NAV proposal
    /// @dev Any manager of the strategy can cancel
    function cancelNAVUpdate(address strategy, uint256 proposalId) external;

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/
    /// @notice The managed aggregator this oracle pushes PPS into
    function MANAGED_AGGREGATOR() external view returns (address);

    /// @notice The NAV mode label for this family (always "attested_manual")
    function NAV_MODE() external pure returns (string memory);

    /// @notice Gets a NAV proposal
    function getNAVProposal(
        address strategy,
        uint256 proposalId
    )
        external
        view
        returns (NAVUpdateProposal memory proposal);

    /// @notice Gets the active proposal id for a strategy (0 if none)
    function getActiveNAVProposalId(address strategy) external view returns (uint256 proposalId);

    /// @notice Gets the attestor set for a strategy
    function getNAVAttestors(address strategy) external view returns (address[] memory attestors);

    /// @notice Gets the attestation threshold for a strategy
    function getNAVAttestationThreshold(address strategy) external view returns (uint8 threshold);

    /// @notice Checks whether an address is an attestor for a strategy
    function isNAVAttestor(address strategy, address attestor) external view returns (bool);

    /// @notice Checks whether an attestor has attested to a proposal
    function hasAttested(address strategy, uint256 proposalId, address attestor) external view returns (bool);

    /// @notice Gets the pending (timelocked) attestation config change for a strategy
    function getPendingNAVAttestationConfig(address strategy)
        external
        view
        returns (PendingAttestationConfig memory pending);
}
