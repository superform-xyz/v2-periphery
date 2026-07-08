// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IManagedSuperVaultController } from "./IManagedSuperVaultController.sol";

/// @title IManagedSuperVaultAggregator
/// @notice Interface for the ManagedSuperVaultAggregator: sibling factory and registry for Managed Vaults.
///         Deploys deterministic vault/controller/escrow trios and owns per-vault registry state:
///         managers, pause state, attested manual NAV/PPS, freshness, and deviation bounds.
/// @dev Unlike SuperVaultAggregator there is no PPS oracle / upkeep machinery. This aggregator also owns
///      the full attested-manual NAV lifecycle (propose/attest/resolve + attestor-set timelock), keyed by
///      controller, so all NAV/PPS/deviation/pause logic lives in one place.
/// @author Superform Labs
interface IManagedSuperVaultAggregator {
    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Parameters for creating a new Managed Vault trio
    /// @param asset Address of the underlying asset
    /// @param name Name of the vault token
    /// @param symbol Symbol of the vault token
    /// @param mainManager Address of the vault main manager
    /// @param secondaryManagers Secondary manager addresses (max 5)
    /// @param minUpdateInterval Minimum time interval between NAV updates
    /// @param maxStaleness Maximum age of a NAV update before the vault is considered stale
    /// @param maxUpdateDeviationBps Max NAV change per update in bps before review/pause (0 = default 50%)
    /// @param depositPolicy Deposit policy configuration
    /// @param navConfig NAV attestation configuration (attestors, threshold)
    /// @param feeConfig Fee configuration (same structure as Full SuperVaults)
    /// @param metadataURI Offchain metadata URI (descriptions, policies, disclosures); emitted, not stored
    struct ManagedVaultCreationParams {
        address asset;
        string name;
        string symbol;
        address mainManager;
        address[] secondaryManagers;
        uint256 minUpdateInterval;
        uint256 maxStaleness;
        uint256 maxUpdateDeviationBps;
        IManagedSuperVaultController.DepositPolicy depositPolicy;
        IManagedSuperVaultController.NavAttestationConfig navConfig;
        IManagedSuperVaultController.FeeConfig feeConfig;
        string metadataURI;
    }

    /// @notice Local variables for vault creation to avoid stack too deep
    struct VaultCreationLocalVars {
        uint256 currentNonce;
        bytes32 salt;
        uint256 initialPPS;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Managed Vault trio is created
    event ManagedSuperVaultDeployed(
        address indexed vault,
        address indexed controller,
        address escrow,
        address asset,
        string name,
        string symbol,
        uint256 indexed nonce
    );

    /// @notice Emitted alongside deployment with the vault's configuration flags and metadata
    event ManagedVaultConfigRegistered(
        address indexed controller, IManagedSuperVaultController.DepositApprovalMode approvalMode, string metadataURI
    );

    /// @notice Emitted when a finalized attested NAV is stored
    /// @param controller Address of the vault controller
    /// @param previousPPS Previous price-per-share value
    /// @param newPPS New price-per-share value
    /// @param timestamp Observation timestamp of the update
    event ManagedNAVUpdated(address indexed controller, uint256 previousPPS, uint256 newPPS, uint256 timestamp);

    /// @notice Emitted when a NAV update is rejected for exceeding the deviation threshold
    /// @param controller Address of the vault controller
    /// @param proposedPPS Rejected price-per-share value
    /// @param currentPPS Current stored price-per-share value
    /// @param deviation Relative deviation (1e18 scale)
    event ManagedNAVDeviationExceeded(
        address indexed controller, uint256 proposedPPS, uint256 currentPPS, uint256 deviation
    );

    /// @notice Emitted when PPS is reduced after a performance fee skim
    event PPSUpdatedAfterSkim(
        address indexed controller, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp
    );

    /// @notice Emitted when a managed vault is paused
    event ManagedVaultPaused(address indexed controller);

    /// @notice Emitted when a managed vault is unpaused
    event ManagedVaultUnpaused(address indexed controller);

    /// @notice Emitted when a managed vault's NAV is marked stale
    event ManagedVaultNAVStale(address indexed controller);

    /// @notice Emitted when a managed vault's NAV stale flag is cleared
    event ManagedVaultNAVStaleReset(address indexed controller);

    /// @notice Emitted when a secondary manager is added
    event SecondaryManagerAdded(address indexed controller, address indexed manager);

    /// @notice Emitted when a secondary manager is removed
    event SecondaryManagerRemoved(address indexed controller, address indexed manager);

    /// @notice Emitted when a deviation threshold change is proposed
    event DeviationThresholdChangeProposed(address indexed controller, uint256 newThreshold, uint256 effectiveTime);

    /// @notice Emitted when a deviation threshold change is executed
    event DeviationThresholdUpdated(address indexed controller, uint256 deviationThreshold);

    /// @notice Emitted when a deviation threshold change is cancelled
    event DeviationThresholdChangeCancelled(address indexed controller, uint256 cancelledThreshold);

    /// @notice Emitted when a primary manager change is proposed
    event PrimaryManagerChangeProposed(
        address indexed controller,
        address indexed proposer,
        address indexed newManager,
        address feeRecipient,
        uint256 effectiveTime
    );

    /// @notice Emitted when a primary manager change proposal is cancelled
    event PrimaryManagerChangeCancelled(address indexed controller, address indexed cancelledManager);

    /// @notice Emitted when the primary manager is changed
    event PrimaryManagerChanged(
        address indexed controller, address indexed oldManager, address indexed newManager, address feeRecipient
    );

    /// @notice Emitted when the high-water mark is reset by governance
    event HighWaterMarkReset(address indexed controller, uint256 indexed newHwmPps);

    /// @notice Emitted when a min update interval change is proposed
    event MinUpdateIntervalChangeProposed(
        address indexed controller, address indexed proposer, uint256 newMinUpdateInterval, uint256 effectiveTime
    );

    /// @notice Emitted when a min update interval change is executed
    event MinUpdateIntervalChanged(address indexed controller, uint256 oldInterval, uint256 newInterval);

    /// @notice Emitted when a min update interval change is cancelled
    event MinUpdateIntervalChangeCancelled(address indexed controller, uint256 cancelledInterval);

    /// @notice Emitted when the metadata URI is updated
    event MetadataURIUpdated(address indexed controller, string metadataURI);

    // --- NAV attestation lifecycle ---
    event NAVProposed(
        address indexed controller,
        uint256 indexed proposalId,
        uint256 previousPPS,
        uint256 proposedPPS,
        uint256 effectiveTimestamp,
        address indexed proposer,
        bytes32 evidenceHash,
        string evidenceURI
    );
    event NAVAttested(
        address indexed controller, uint256 indexed proposalId, address indexed attestor, uint8 attestationCount
    );
    event NAVFinalized(address indexed controller, uint256 indexed proposalId, uint256 finalizedPPS, uint256 timestamp);
    event NAVReviewRequired(
        address indexed controller, uint256 indexed proposalId, uint256 proposedPPS, uint256 currentPPS
    );
    event NAVProposalCanceled(address indexed controller, uint256 indexed proposalId, address indexed canceledBy);
    event NAVLargeDeviationResolved(address indexed controller, uint256 indexed proposalId, address indexed resolvedBy);
    event NAVAttestorAdded(address indexed controller, address indexed attestor);
    event NAVAttestorRemoved(address indexed controller, address indexed attestor);
    event NAVAttestationThresholdUpdated(address indexed controller, uint8 threshold);
    event NAVAttestationConfigProposed(
        address indexed controller, address[] attestors, uint8 threshold, uint256 effectiveTime
    );
    event NAVAttestationConfigCancelled(address indexed controller);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZERO_ADDRESS();
    error INVALID_VAULT_PARAMS();
    error INVALID_ASSET();
    error UNKNOWN_CONTROLLER();
    error UNAUTHORIZED_UPDATE_AUTHORITY();
    error MANAGED_VAULT_PAUSED();
    error MANAGED_VAULT_NOT_PAUSED();
    error MANAGED_VAULT_ALREADY_PAUSED();
    error NAV_STALE();
    error INVALID_NAV();
    error INVALID_TIMESTAMP();
    error UPDATE_TOO_FREQUENT();
    error STALE_UPDATE();
    error PPS_MUST_DECREASE_AFTER_SKIM();
    error PPS_DEDUCTION_TOO_LARGE();
    error MAX_STALENESS_TOO_LOW();
    error TOO_MANY_SECONDARY_MANAGERS();
    error SECONDARY_MANAGER_CANNOT_BE_PRIMARY();
    error MANAGER_ALREADY_EXISTS();
    error MANAGER_NOT_FOUND();
    error NO_PENDING_MANAGER_CHANGE();
    error TIMELOCK_NOT_EXPIRED();
    error NO_PENDING_MIN_UPDATE_INTERVAL_CHANGE();
    error MIN_UPDATE_INTERVAL_TOO_HIGH();
    error NO_PENDING_DEVIATION_THRESHOLD_CHANGE();
    error INVALID_DEVIATION_THRESHOLD();
    error INDEX_OUT_OF_BOUNDS();
    // NAV attestation lifecycle
    error EVIDENCE_REQUIRED();
    error NOT_NAV_ATTESTOR();
    error ATTESTOR_CANNOT_BE_PROPOSER();
    error ALREADY_ATTESTED();
    error NAV_PROPOSAL_PENDING();
    error NAV_PROPOSAL_NOT_PENDING();
    error NAV_PROPOSAL_NOT_IN_REVIEW();
    error ATTESTATION_THRESHOLD_NOT_MET();
    error INVALID_ATTESTATION_CONFIG();
    error ATTESTOR_ALREADY_EXISTS();
    error NAV_CONFIG_TIMELOCK_NOT_EXPIRED();
    error NO_PENDING_NAV_CONFIG();

    /*//////////////////////////////////////////////////////////////
                            VAULT CREATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Managed Vault trio (vault, controller, escrow) via deterministic clones
    /// @param params Creation parameters
    /// @return vault Address of the created ManagedSuperVault
    /// @return controller Address of the created ManagedSuperVaultController
    /// @return escrow Address of the created ManagedSuperVaultEscrow
    function createManagedVault(ManagedVaultCreationParams calldata params)
        external
        returns (address vault, address controller, address escrow);

    /*//////////////////////////////////////////////////////////////
                        NAV ATTESTATION LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /// @notice Propose a NAV/PPS update with evidence; requires independent attestation to finalize
    /// @dev Any manager may propose. Only one active proposal per vault at a time.
    /// @param controller The managed vault controller
    /// @param newPPS The proposed price-per-share (scaled by asset decimals)
    /// @param effectiveTimestamp The observation timestamp the NAV corresponds to (<= block.timestamp)
    /// @param evidenceHash Hash of offchain evidence backing the NAV (required)
    /// @param evidenceURI URI of offchain evidence (optional)
    /// @return proposalId The created proposal id
    function proposeNAVUpdate(
        address controller,
        uint256 newPPS,
        uint256 effectiveTimestamp,
        bytes32 evidenceHash,
        string calldata evidenceURI
    )
        external
        returns (uint256 proposalId);

    /// @notice Attest a pending NAV proposal; auto-finalizes when the attestation threshold is met
    function attestNAVUpdate(address controller, uint256 proposalId) external;

    /// @notice Cancel a pending or in-review NAV proposal (any manager)
    function cancelNAVUpdate(address controller, uint256 proposalId) external;

    /// @notice Finalize a large-deviation NAV proposal after the vault was explicitly unpaused
    /// @dev Requires: proposal in ReviewRequired with threshold attestations, vault unpaused (main
    ///      manager only). This is the only path that finalizes a NAV exceeding the deviation bound.
    function resolveLargeDeviationNAV(address controller, uint256 proposalId) external;

    /// @notice Propose a replacement NAV attestor set and threshold (main manager only, 3-day timelock)
    function proposeNAVAttestationConfig(address controller, address[] calldata attestors, uint8 threshold) external;

    /// @notice Execute a pending NAV attestation config change after the timelock (main manager only)
    function executeNAVAttestationConfig(address controller) external;

    /// @notice Cancel a pending NAV attestation config change (main manager only)
    function cancelNAVAttestationConfig(address controller) external;

    /// @notice Reduce PPS after a performance fee skim. Only callable by a registered controller for itself.
    /// @param newPPS The post-skim price-per-share (must strictly decrease within max fee bounds)
    /// @param feeAmount The fee amount extracted (must be non-zero)
    function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) external;

    /*//////////////////////////////////////////////////////////////
                            PAUSE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Manually pause a managed vault (any manager). Marks NAV stale.
    function pauseManagedVault(address controller) external;

    /// @notice Manually unpause a managed vault (any manager). NAV remains stale until a fresh update.
    function unpauseManagedVault(address controller) external;

    /*//////////////////////////////////////////////////////////////
                        MANAGER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a secondary manager (main manager only)
    function addSecondaryManager(address controller, address manager) external;

    /// @notice Remove a secondary manager (main manager only)
    function removeSecondaryManager(address controller, address manager) external;

    /// @notice Propose a NAV deviation-threshold change, 1e18 scale (main manager only, 3-day timelock)
    /// @dev The threshold is the mandatory guardrail against manager NAV manipulation; changes are
    ///      timelocked and cannot disable it (bounded to (0, 1e18]).
    function proposeDeviationThresholdChange(address controller, uint256 deviationThreshold) external;

    /// @notice Execute a pending deviation-threshold change after the timelock
    function executeDeviationThresholdChange(address controller) external;

    /// @notice Cancel a pending deviation-threshold change (main manager only)
    function cancelDeviationThresholdChange(address controller) external;

    /// @notice Emit an updated offchain metadata URI (main manager only; event-only, not stored)
    function updateMetadataURI(address controller, string calldata metadataURI) external;

    /// @notice Propose a primary manager change (secondary managers only, 7-day timelock)
    function proposeChangePrimaryManager(address controller, address newManager, address feeRecipient) external;

    /// @notice Cancel a pending primary manager change (main manager only)
    function cancelChangePrimaryManager(address controller) external;

    /// @notice Execute a pending primary manager change after the timelock
    function executeChangePrimaryManager(address controller) external;

    /// @notice Emergency governance override of the primary manager (SuperGovernor only)
    function changePrimaryManager(address controller, address newManager, address feeRecipient) external;

    /// @notice Reset the high-water mark to the current PPS (SuperGovernor only)
    function resetHighWaterMark(address controller) external;

    /*//////////////////////////////////////////////////////////////
                    MIN UPDATE INTERVAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Propose a min update interval change (main manager only, 3-day timelock)
    function proposeMinUpdateIntervalChange(address controller, uint256 newMinUpdateInterval) external;

    /// @notice Execute a pending min update interval change after the timelock
    function executeMinUpdateIntervalChange(address controller) external;

    /// @notice Cancel a pending min update interval change (main manager only)
    function cancelMinUpdateIntervalChange(address controller) external;

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Vault type marker for downstream systems; always "managed_vault"
    function VAULT_TYPE() external pure returns (string memory);

    /// @notice NAV mode marker for downstream systems; always "attested_manual"
    function NAV_MODE() external pure returns (string memory);

    /// @notice Get the current PPS (latest finalized attested NAV) for a controller
    function getPPS(address controller) external view returns (uint256 pps);

    /// @notice Get the last NAV update timestamp for a controller
    function getLastUpdateTimestamp(address controller) external view returns (uint256 timestamp);

    /// @notice Get the min NAV update interval for a controller
    function getMinUpdateInterval(address controller) external view returns (uint256 interval);

    /// @notice Get the max NAV staleness for a controller
    function getMaxStaleness(address controller) external view returns (uint256 staleness);

    /// @notice Get the NAV deviation threshold (1e18 scale) for a controller
    function getDeviationThreshold(address controller) external view returns (uint256 deviationThreshold);

    /// @notice Whether a managed vault is paused
    function isManagedVaultPaused(address controller) external view returns (bool isPaused);

    /// @notice Whether a managed vault's NAV is flagged stale
    function isNAVStale(address controller) external view returns (bool isStale);

    /// @notice Get the last unpause timestamp (for the post-unpause skim timelock)
    function getLastUnpauseTimestamp(address controller) external view returns (uint256 timestamp);

    /// @notice Get the main manager for a controller
    function getMainManager(address controller) external view returns (address manager);

    /// @notice Get pending primary manager change details
    function getPendingManagerChange(address controller)
        external
        view
        returns (address proposedManager, uint256 effectiveTime);

    /// @notice Whether an address is the main manager of a controller
    function isMainManager(address manager, address controller) external view returns (bool);

    /// @notice Get all secondary managers for a controller
    function getSecondaryManagers(address controller) external view returns (address[] memory);

    /// @notice Whether an address is a secondary manager of a controller
    function isSecondaryManager(address manager, address controller) external view returns (bool);

    /// @notice Whether an address is the main or a secondary manager of a controller
    function isAnyManager(address manager, address controller) external view returns (bool);

    /// @notice Get pending min update interval change details
    function getProposedMinUpdateInterval(address controller)
        external
        view
        returns (uint256 proposedInterval, uint256 effectiveTime);

    /// @notice Get pending deviation-threshold change details
    function getProposedDeviationThreshold(address controller)
        external
        view
        returns (uint256 proposedThreshold, uint256 effectiveTime);

    /// @notice Get a NAV proposal for a controller
    function getNAVProposal(
        address controller,
        uint256 proposalId
    )
        external
        view
        returns (IManagedSuperVaultController.NAVUpdateProposal memory proposal);

    /// @notice Get the currently active (pending or in-review) NAV proposal id for a controller, 0 if none
    function getActiveNAVProposalId(address controller) external view returns (uint256 proposalId);

    /// @notice Get the NAV attestation configuration for a controller
    function getNAVAttestationConfig(address controller)
        external
        view
        returns (address[] memory attestors, uint8 threshold);

    /// @notice Get the pending (timelocked) NAV attestation config change for a controller, if any
    function getPendingNAVAttestationConfig(address controller)
        external
        view
        returns (address[] memory attestors, uint8 threshold, uint256 effectiveTime);

    /// @notice Whether an address is a configured NAV attestor for a controller
    function isNAVAttestor(address controller, address attestor) external view returns (bool);

    /// @notice Whether an attestor has attested a given proposal for a controller
    function hasAttested(address controller, uint256 proposalId, address attestor) external view returns (bool);

    /// @notice Whether an address is a Managed Vault created by this aggregator
    function isManagedVault(address vault) external view returns (bool);

    /// @notice Get the controller for a managed vault
    function getManagedVaultController(address vault) external view returns (address controller);

    /// @notice Get the escrow for a managed vault
    function getManagedVaultEscrow(address vault) external view returns (address escrow);

    /// @notice Get all managed vaults
    function getAllManagedVaults() external view returns (address[] memory);

    /// @notice Get all managed vault controllers
    function getAllManagedVaultControllers() external view returns (address[] memory);

    /// @notice Get the managed vault at an index
    function managedVaults(uint256 index) external view returns (address);

    /// @notice Get the managed vault controller at an index
    function managedVaultControllers(uint256 index) external view returns (address);

    /// @notice Get the count of managed vaults
    function getManagedVaultsCount() external view returns (uint256);

    /// @notice Get the current vault creation nonce
    function getCurrentNonce() external view returns (uint256);
}
