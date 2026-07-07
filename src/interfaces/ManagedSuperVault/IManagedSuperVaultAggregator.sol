// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IManagedSuperVaultController } from "./IManagedSuperVaultController.sol";

/// @title IManagedSuperVaultAggregator
/// @notice Interface for the ManagedSuperVaultAggregator: sibling factory and registry for Managed Vaults.
///         Deploys deterministic vault/controller/escrow trios and owns per-vault registry state:
///         managers, pause state, attested manual NAV/PPS, freshness, and deviation bounds.
/// @dev Unlike SuperVaultAggregator there is no PPS oracle / upkeep machinery: the NAV write path is
///      controller-only (finalized attested NAV proposals and fee-skim decreases).
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
    /// @param navConfig NAV attestation configuration (attestors, threshold, validity)
    /// @param feeConfig Fee configuration (same structure as Full SuperVaults)
    /// @param metadataURI Offchain metadata URI (descriptions, policies, disclosures)
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

    /// @notice Emitted when the deviation threshold is updated
    event DeviationThresholdUpdated(address indexed controller, uint256 deviationThreshold);

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
    event HighWaterMarkReset(address indexed controller, uint256 newHwmPps);

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
    error INDEX_OUT_OF_BOUNDS();

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
                        NAV WRITE PATH (CONTROLLER-ONLY)
    //////////////////////////////////////////////////////////////*/

    /// @notice Store a finalized attested NAV. Only callable by a registered controller for itself.
    /// @dev Enforces: not paused, timestamp monotonicity, no future timestamps, min update interval,
    ///      max staleness, and the deviation bound. A deviation-bound failure auto-pauses the vault,
    ///      marks NAV stale, drops the value, and returns false (mirrors Full SuperVault posture).
    ///      The deviation check is skipped while NAV is stale (explicit resolve/escape hatch).
    /// @param newPPS The finalized price-per-share
    /// @param timestamp The observation timestamp of the NAV
    /// @return accepted True if stored, false if rejected for deviation (vault now paused)
    function updateManagedNAV(uint256 newPPS, uint256 timestamp) external returns (bool accepted);

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

    /// @notice Update the NAV deviation threshold, 1e18 scale (main manager only)
    function updateDeviationThreshold(address controller, uint256 deviationThreshold) external;

    /// @notice Update the offchain metadata URI (main manager only)
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

    /// @notice Get the offchain metadata URI for a controller
    function getMetadataURI(address controller) external view returns (string memory metadataURI);

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
