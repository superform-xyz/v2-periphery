// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ISuperVaultStrategy } from "../SuperVault/ISuperVaultStrategy.sol";
import { IManagedNAVOracle } from "./IManagedNAVOracle.sol";
import { IManagedSuperVaultDepositQueue } from "./IManagedSuperVaultDepositQueue.sol";

/// @title IManagedSuperVaultAggregator
/// @author Superform Labs
/// @notice Interface for the ManagedSuperVaultAggregator contract
/// @dev Registry and attested-PPS sink for all Managed SuperVaults. Fork of ISuperVaultAggregator:
///      no upkeep subsystem, manual-NAV oracle authorization (timelocked), and a 4th clone
///      (deposit queue) per vault.
interface IManagedSuperVaultAggregator {
    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Arguments for forwarding PPS updates to avoid stack too deep errors
    /// @param strategy Address of the strategy being updated
    /// @param pps New price-per-share value
    /// @param timestamp Timestamp when the value was generated
    struct PPSUpdateData {
        address strategy;
        uint256 pps;
        uint256 timestamp;
    }

    /// @notice Local variables for vault creation to avoid stack too deep
    /// @param currentNonce Current vault creation nonce
    /// @param salt Salt for deterministic proxy creation
    /// @param initialPPS Initial price-per-share value
    struct VaultCreationLocalVars {
        uint256 currentNonce;
        bytes32 salt;
        uint256 initialPPS;
    }

    /// @notice Strategy configuration and state data
    /// @param pps Current price-per-share value
    /// @param lastUpdateTimestamp Last time PPS was updated
    /// @param minUpdateInterval Minimum time interval between PPS updates
    /// @param maxStaleness Maximum time allowed between PPS updates before staleness
    /// @param isPaused Whether the strategy is paused
    /// @param mainManager Address of the primary manager controlling the strategy
    /// @param secondaryManagers Set of secondary managers that can manage the strategy
    struct StrategyData {
        uint256 pps; // Slot 0: 32 bytes
        uint256 lastUpdateTimestamp; // Slot 1: 32 bytes
        uint256 minUpdateInterval; // Slot 2: 32 bytes
        uint256 maxStaleness; // Slot 3: 32 bytes
        // Packed slot 4: saves 2 storage slots (~4000 gas per read)
        address mainManager; // 20 bytes
        bool ppsStale; // 1 byte
        bool isPaused; // 1 byte
        bool hooksRootVetoed; // 1 byte
        uint72 __gap1; // 9 bytes padding
        EnumerableSet.AddressSet secondaryManagers;
        // Manager change proposal data
        address proposedManager;
        address proposedFeeRecipient;
        uint256 managerChangeEffectiveTime;
        // Hook validation data
        bytes32 managerHooksRoot;
        // Hook root update proposal data
        bytes32 proposedHooksRoot;
        uint256 hooksRootEffectiveTime;
        // PPS Verification thresholds
        uint256 deviationThreshold; // Threshold for abs(new - current) / current
        // Banned global leaves mapping
        mapping(bytes32 => bool) bannedLeaves; // Mapping of leaf hash to banned status
        // Min update interval proposal data
        uint256 proposedMinUpdateInterval;
        uint256 minUpdateIntervalEffectiveTime;
        uint256 lastUnpauseTimestamp; // Timestamp of last unpause (for skim timelock)
        // Deviation threshold proposal data (managed diff: timelocked, unlike the main family)
        uint256 proposedDeviationThreshold;
        uint256 deviationThresholdEffectiveTime;
    }

    /// @notice Parameters for creating a new Managed SuperVault quartet
    /// @param asset Address of the underlying asset
    /// @param name Name of the vault token
    /// @param symbol Symbol of the vault token
    /// @param mainManager Address of the vault mainManager
    /// @param minUpdateInterval Minimum time interval between PPS updates
    /// @param maxStaleness Maximum time allowed between PPS updates before staleness
    /// @param feeConfig Fee configuration for the vault
    /// @param depositPolicy Deposit policy for the vault's deposit queue
    /// @param navConfig NAV attestation config (attestor set + threshold) registered with the NAV oracle
    /// @param metadataURI Offchain metadata URI (event-only, not stored onchain)
    struct VaultCreationParams {
        address asset;
        string name;
        string symbol;
        address mainManager;
        address[] secondaryManagers;
        uint256 minUpdateInterval;
        uint256 maxStaleness;
        ISuperVaultStrategy.FeeConfig feeConfig;
        IManagedSuperVaultDepositQueue.DepositPolicy depositPolicy;
        IManagedNAVOracle.NavAttestationConfig navConfig;
        string metadataURI;
    }

    /// @notice Struct to hold cached hook validation state variables to avoid stack too deep
    /// @param globalHooksRootVetoed Cached global hooks root veto status
    /// @param globalHooksRoot Cached global hooks root
    /// @param strategyHooksRootVetoed Cached strategy hooks root veto status
    /// @param strategyRoot Cached strategy hooks root
    struct HookValidationCache {
        bool globalHooksRootVetoed;
        bytes32 globalHooksRoot;
        bool strategyHooksRootVetoed;
        bytes32 strategyRoot;
    }

    /// @notice Arguments for validating a hook to avoid stack too deep
    /// @param hookAddress Address of the hook contract
    /// @param hookArgs Encoded arguments for the hook operation
    /// @param globalProof Merkle proof for the global root
    /// @param strategyProof Merkle proof for the strategy-specific root
    struct ValidateHookArgs {
        address hookAddress;
        bytes hookArgs;
        bytes32[] globalProof;
        bytes32[] strategyProof;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a new managed vault quartet is created
    /// @param vault Address of the created ManagedSuperVault
    /// @param strategy Address of the created ManagedSuperVaultStrategy
    /// @param escrow Address of the created escrow (reused SuperVaultEscrow implementation)
    /// @param depositQueue Address of the created ManagedSuperVaultDepositQueue
    /// @param asset Address of the underlying asset
    /// @param name Name of the vault token
    /// @param symbol Symbol of the vault token
    /// @param nonce The nonce used for vault creation
    event ManagedVaultDeployed(
        address indexed vault,
        address indexed strategy,
        address escrow,
        address depositQueue,
        address asset,
        string name,
        string symbol,
        uint256 indexed nonce
    );

    /// @notice Emitted when a vault's metadata URI is set or updated (event-only, no onchain storage)
    /// @param strategy Address of the strategy the metadata belongs to
    /// @param metadataURI The new metadata URI
    event MetadataURIUpdated(address indexed strategy, string metadataURI);

    /// @notice Emitted when a NAV oracle change is proposed
    /// @param proposedOracle Address of the proposed NAV oracle
    /// @param effectiveTime Timestamp when the change can be executed
    event NavOracleProposed(address indexed proposedOracle, uint256 effectiveTime);

    /// @notice Emitted when the NAV oracle is changed (or initially set in the constructor)
    /// @param oldOracle Address of the previous NAV oracle (address(0) at construction)
    /// @param newOracle Address of the new NAV oracle
    event NavOracleChanged(address indexed oldOracle, address indexed newOracle);

    /// @notice Emitted when a pending NAV oracle change is cancelled
    /// @param cancelledOracle Address of the oracle that had been proposed
    event NavOracleChangeCancelled(address indexed cancelledOracle);

    /// @notice Emitted when a PPS value is updated
    /// @param strategy Address of the strategy
    /// @param pps New price-per-share value
    /// @param timestamp Timestamp of the update
    event PPSUpdated(address indexed strategy, uint256 pps, uint256 timestamp);

    /// @notice Emitted when a strategy is paused due to missed updates
    /// @param strategy Address of the paused strategy
    event StrategyPaused(address indexed strategy);

    /// @notice Emitted when a strategy is unpaused
    /// @param strategy Address of the unpaused strategy
    event StrategyUnpaused(address indexed strategy);

    /// @notice Emitted when a strategy validation check fails but execution continues
    /// @param strategy Address of the strategy that failed the check
    /// @param reason String description of which check failed
    event StrategyCheckFailed(address indexed strategy, string reason);

    /// @notice Emitted when a secondary manager is added to a strategy
    /// @param strategy Address of the strategy
    /// @param manager Address of the manager added
    event SecondaryManagerAdded(address indexed strategy, address indexed manager);

    /// @notice Emitted when a secondary manager is removed from a strategy
    /// @param strategy Address of the strategy
    /// @param manager Address of the manager removed
    event SecondaryManagerRemoved(address indexed strategy, address indexed manager);

    /// @notice Emitted when a primary manager is changed
    /// @param strategy Address of the strategy
    /// @param oldManager Address of the old primary manager
    /// @param newManager Address of the new primary manager
    /// @param feeRecipient Address of the new fee recipient
    event PrimaryManagerChanged(
        address indexed strategy, address indexed oldManager, address indexed newManager, address feeRecipient
    );

    /// @notice Emitted when a change to primary manager is proposed by a secondary manager
    /// @param strategy Address of the strategy
    /// @param proposer Address of the secondary manager who made the proposal
    /// @param newManager Address of the proposed new primary manager
    /// @param effectiveTime Timestamp when the proposal can be executed
    event PrimaryManagerChangeProposed(
        address indexed strategy,
        address indexed proposer,
        address indexed newManager,
        address feeRecipient,
        uint256 effectiveTime
    );

    /// @notice Emitted when a primary manager change proposal is cancelled
    /// @param strategy Address of the strategy
    /// @param cancelledManager Address of the manager that was proposed
    event PrimaryManagerChangeCancelled(address indexed strategy, address indexed cancelledManager);

    /// @notice Emitted when the High Water Mark for a strategy is reset to PPS
    /// @param strategy Address of the strategy
    /// @param newHWM The new High Water Mark (PPS)
    event HighWaterMarkReset(address indexed strategy, uint256 indexed newHWM);

    /// @notice Emitted when a PPS update is stale (Validators could get slashed for innactivity)
    /// @param strategy Address of the strategy
    /// @param updateAuthority Address of the update authority
    /// @param timestamp Timestamp of the stale update
    event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp);

    /// @notice Emitted when the global hooks Merkle root is being updated
    /// @param root New root value
    /// @param effectiveTime Timestamp when the root becomes effective
    event GlobalHooksRootUpdateProposed(bytes32 indexed root, uint256 effectiveTime);

    /// @notice Emitted when the global hooks Merkle root is updated
    /// @param oldRoot Previous root value
    /// @param newRoot New root value
    event GlobalHooksRootUpdated(bytes32 indexed oldRoot, bytes32 newRoot);

    /// @notice Emitted when a strategy-specific hooks Merkle root is updated
    /// @param strategy Address of the strategy
    /// @param oldRoot Previous root value (may be zero)
    /// @param newRoot New root value
    event StrategyHooksRootUpdated(address indexed strategy, bytes32 oldRoot, bytes32 newRoot);

    /// @notice Emitted when a strategy-specific hooks Merkle root is proposed
    /// @param strategy Address of the strategy
    /// @param proposer Address of the account proposing the new root
    /// @param root New root value
    /// @param effectiveTime Timestamp when the root becomes effective
    event StrategyHooksRootUpdateProposed(
        address indexed strategy, address indexed proposer, bytes32 root, uint256 effectiveTime
    );

    /// @notice Emitted when a proposed global hooks root update is vetoed by SuperGovernor
    /// @param vetoed Whether the root is being vetoed (true) or unvetoed (false)
    /// @param root The root value affected
    event GlobalHooksRootVetoStatusChanged(bool vetoed, bytes32 indexed root);

    /// @notice Emitted when a strategy's hooks Merkle root veto status changes
    /// @param strategy Address of the strategy
    /// @param vetoed Whether the root is being vetoed (true) or unvetoed (false)
    /// @param root The root value affected
    event StrategyHooksRootVetoStatusChanged(address indexed strategy, bool vetoed, bytes32 indexed root);

    /// @notice Emitted when a strategy's deviation threshold is updated
    /// @param strategy Address of the strategy
    /// @param deviationThreshold New deviation threshold (abs diff/current)
    event DeviationThresholdUpdated(address indexed strategy, uint256 deviationThreshold);

    /// @notice Emitted when a deviation-threshold change is proposed (starts the 3-day timelock)
    /// @param strategy Address of the strategy
    /// @param proposer Address of the main manager who made the proposal
    /// @param newDeviationThreshold The proposed threshold
    /// @param effectiveTime Timestamp when the proposal can be executed
    event DeviationThresholdChangeProposed(
        address indexed strategy, address indexed proposer, uint256 newDeviationThreshold, uint256 effectiveTime
    );

    /// @notice Emitted when a pending deviation-threshold change is cancelled
    /// @param strategy Address of the strategy
    /// @param cancelledThreshold The proposed threshold that was cancelled
    event DeviationThresholdChangeCancelled(address indexed strategy, uint256 cancelledThreshold);

    /// @notice Emitted when the hooks root update timelock is changed
    /// @param newTimelock New timelock duration in seconds
    event HooksRootUpdateTimelockChanged(uint256 newTimelock);

    /// @notice Emitted when global leaves status is changed for a strategy
    /// @param strategy Address of the strategy
    /// @param leaves Array of leaf hashes that had their status changed
    /// @param statuses Array of new banned statuses (true = banned, false = allowed)
    event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses);

    /// @notice Emitted when PPS update is too frequent (before minUpdateInterval)
    event UpdateTooFrequent();

    /// @notice Emitted when PPS update timestamp is not monotonically increasing
    event TimestampNotMonotonic();

    /// @notice Emitted when PPS update is rejected due to stale signature after unpause
    event StaleSignatureAfterUnpause(
        address indexed strategy, uint256 signatureTimestamp, uint256 lastUnpauseTimestamp
    );

    /// @notice Emitted when the provided timestamp is too large
    event ProvidedTimestampExceedsBlockTimestamp(
        address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp
    );

    /// @notice Emitted when a strategy is unknown
    event UnknownStrategy(address indexed strategy);

    /// @notice Emitted when the old primary manager is removed from the strategy
    /// @dev This can happen because of reaching the max number of secondary managers
    event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager);

    /// @notice Emitted when a strategy's PPS is stale
    event StrategyPPSStale(address indexed strategy);

    /// @notice Emitted when a strategy's PPS is reset
    event StrategyPPSStaleReset(address indexed strategy);

    /// @notice Emitted when PPS is updated after performance fee skimming
    /// @param strategy Address of the strategy
    /// @param oldPPS Previous price-per-share value
    /// @param newPPS New price-per-share value after fee deduction
    /// @param feeAmount Amount of fee skimmed that caused the PPS update
    /// @param timestamp Timestamp of the update
    event PPSUpdatedAfterSkim(
        address indexed strategy, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp
    );

    /// @notice Emitted when a change to minUpdateInterval is proposed
    /// @param strategy Address of the strategy
    /// @param proposer Address of the manager who made the proposal
    /// @param newMinUpdateInterval The proposed new minimum update interval
    /// @param effectiveTime Timestamp when the proposal can be executed
    event MinUpdateIntervalChangeProposed(
        address indexed strategy, address indexed proposer, uint256 newMinUpdateInterval, uint256 effectiveTime
    );

    /// @notice Emitted when a minUpdateInterval change is executed
    /// @param strategy Address of the strategy
    /// @param oldMinUpdateInterval Previous minimum update interval
    /// @param newMinUpdateInterval New minimum update interval
    event MinUpdateIntervalChanged(
        address indexed strategy, uint256 oldMinUpdateInterval, uint256 newMinUpdateInterval
    );

    /// @notice Emitted when a minUpdateInterval change proposal is rejected due to validation failure
    /// @param strategy Address of the strategy
    /// @param proposedInterval The proposed interval that was rejected
    /// @param currentMaxStaleness The current maxStaleness value that caused rejection
    event MinUpdateIntervalChangeRejected(
        address indexed strategy, uint256 proposedInterval, uint256 currentMaxStaleness
    );

    /// @notice Emitted when a minUpdateInterval change proposal is cancelled
    /// @param strategy Address of the strategy
    /// @param cancelledInterval The proposed interval that was cancelled
    event MinUpdateIntervalChangeCancelled(address indexed strategy, uint256 cancelledInterval);

    /// @notice Emitted when a PPS update is rejected because strategy is paused
    /// @param strategy Address of the paused strategy
    event PPSUpdateRejectedStrategyPaused(address indexed strategy);

    /*///////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when address provided is zero
    error ZERO_ADDRESS();
    /// @notice Thrown when amount provided is zero
    error ZERO_AMOUNT();
    /// @notice Thrown when vault creation parameters are invalid (empty name or symbol)
    error INVALID_VAULT_PARAMS();
    /// @notice Thrown when array length is zero
    error ZERO_ARRAY_LENGTH();
    /// @notice Thrown when array length is zero
    error ARRAY_LENGTH_MISMATCH();
    /// @notice Thrown when asset is invalid
    error INVALID_ASSET();
    /// @notice Thrown when caller is not authorized
    error CALLER_NOT_AUTHORIZED();
    /// @notice Thrown when caller is not an approved PPS oracle
    error UNAUTHORIZED_PPS_ORACLE();
    /// @notice Thrown when caller is not authorized for update
    error UNAUTHORIZED_UPDATE_AUTHORITY();
    /// @notice Thrown when strategy address is not a known SuperVault strategy
    error UNKNOWN_STRATEGY();
    /// @notice Thrown when trying to unpause a strategy that is not paused
    error STRATEGY_NOT_PAUSED();
    /// @notice Thrown when trying to pause a strategy that is already paused
    error STRATEGY_ALREADY_PAUSED();
    /// @notice Thrown when array index is out of bounds
    error INDEX_OUT_OF_BOUNDS();
    /// @notice Thrown when attempting to add a manager that already exists
    error MANAGER_ALREADY_EXISTS();
    /// @notice Thrown when attempting to add a manager that is the primary manager
    error SECONDARY_MANAGER_CANNOT_BE_PRIMARY();
    /// @notice Thrown when there is no pending global hooks root change
    error NO_PENDING_GLOBAL_ROOT_CHANGE();
    /// @notice Thrown when attempting to execute a hooks root change before timelock has elapsed
    error ROOT_UPDATE_NOT_READY();
    /// @notice Thrown when a provided hook fails Merkle proof validation
    error HOOK_VALIDATION_FAILED();
    /// @notice Thrown when manager is not found
    error MANAGER_NOT_FOUND();
    /// @notice Thrown when there is no pending manager change proposal
    error NO_PENDING_MANAGER_CHANGE();
    /// @notice Thrown when caller is not authorized to update settings
    error UNAUTHORIZED_CALLER();
    /// @notice Thrown when the timelock for a proposed change has not expired
    error TIMELOCK_NOT_EXPIRED();
    /// @notice Thrown when an array length is invalid
    error INVALID_ARRAY_LENGTH();
    /// @notice Thrown when the provided maxStaleness is less than the minimum required staleness
    error MAX_STALENESS_TOO_LOW();
    /// @notice Thrown when arrays have mismatched lengths
    error MISMATCHED_ARRAY_LENGTHS();
    /// @notice Thrown when timestamp is invalid
    error INVALID_TIMESTAMP(uint256 index);
    /// @notice Thrown when too many secondary managers are added
    error TOO_MANY_SECONDARY_MANAGERS();
    /// @notice Thrown when no NAV oracle change proposal is pending
    error NO_PENDING_NAV_ORACLE_CHANGE();
    /// @notice Thrown when setting the initial NAV oracle after one is already set
    error NAV_ORACLE_ALREADY_SET();
    /// @notice Thrown when a deviation threshold outside (0, 1e18] is proposed — the check cannot be disabled
    error INVALID_DEVIATION_THRESHOLD();
    /// @notice Thrown when no deviation-threshold change proposal is pending
    error NO_PENDING_DEVIATION_THRESHOLD_CHANGE();
    /// @notice Thrown when manager takeovers are globally frozen in the SuperGovernor
    error MANAGER_TAKEOVERS_FROZEN();
    /// @notice PPS must decrease after skimming fees
    error PPS_MUST_DECREASE_AFTER_SKIM();
    /// @notice PPS deduction is larger than the maximum allowed fee rate
    error PPS_DEDUCTION_TOO_LARGE();
    /// @notice Thrown when no minUpdateInterval change proposal is pending
    error NO_PENDING_MIN_UPDATE_INTERVAL_CHANGE();
    /// @notice Thrown when minUpdateInterval >= maxStaleness
    error MIN_UPDATE_INTERVAL_TOO_HIGH();
    /// @notice Thrown when trying to update PPS while strategy is paused
    error STRATEGY_PAUSED();
    /// @notice Thrown when trying to update PPS while PPS is stale
    error PPS_STALE();

    /*//////////////////////////////////////////////////////////////
                            VAULT CREATION
    //////////////////////////////////////////////////////////////*/
    /// @notice Creates a new Managed SuperVault quartet (vault, strategy, escrow, deposit queue)
    /// @dev Also registers the vault's NAV attestation config with the NAV oracle atomically
    /// @param params Parameters for the new vault creation
    /// @return superVault Address of the created ManagedSuperVault
    /// @return strategy Address of the created ManagedSuperVaultStrategy
    /// @return escrow Address of the created escrow (reused SuperVaultEscrow implementation)
    /// @return depositQueue Address of the created ManagedSuperVaultDepositQueue
    function createVault(VaultCreationParams calldata params)
        external
        returns (address superVault, address strategy, address escrow, address depositQueue);

    /*//////////////////////////////////////////////////////////////
                          PPS UPDATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Arguments for batch forwarding PPS updates
    /// @param strategies Array of strategy addresses
    /// @param ppss Array of price-per-share values
    /// @param timestamps Array of timestamps when values were generated
    /// @param updateAuthority Address of the update authority
    struct ForwardPPSArgs {
        address[] strategies;
        uint256[] ppss;
        uint256[] timestamps;
        address updateAuthority;
    }

    /// @notice Batch forwards validated PPS updates to multiple strategies
    /// @param args Struct containing all batch PPS update parameters
    function forwardPPS(ForwardPPSArgs calldata args) external;

    /// @notice Updates PPS directly after performance fee skimming
    /// @dev Only callable by the strategy contract itself (msg.sender must be a registered strategy)
    /// @param newPPS New price-per-share value after fee deduction
    /// @param feeAmount Amount of fee that was skimmed (for event logging)
    function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) external;

    /*//////////////////////////////////////////////////////////////
                        NAV ORACLE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Wires the initial NAV oracle (one-time, immediate)
    /// @dev Only callable by SUPER_GOVERNOR_ROLE holders while no oracle is set. Not a constructor arg
    ///      because the oracle's constructor takes this aggregator's address (circular under CREATE2).
    ///      The family is inert (forwardPPS and createVault revert) until this is called.
    /// @param oracle Address of the ManagedNAVOracle
    function setInitialNavOracle(address oracle) external;

    /// @notice Proposes a new NAV oracle (starts the 7-day timelock)
    /// @dev Only callable by SUPER_GOVERNOR_ROLE holders. The NAV oracle fully controls stored PPS
    ///      for every managed vault, so changes are timelocked like SuperGovernor's active PPS oracle.
    /// @param newOracle Address of the proposed NAV oracle
    function proposeNavOracle(address newOracle) external;

    /// @notice Executes a pending NAV oracle change after the timelock
    /// @dev Can be called by anyone once the timelock has elapsed
    function executeNavOracleChange() external;

    /// @notice Cancels a pending NAV oracle change
    /// @dev Only callable by SUPER_GOVERNOR_ROLE holders
    function cancelNavOracleChange() external;

    /*//////////////////////////////////////////////////////////////
                        METADATA MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Emits an updated metadata URI for a vault (event-only, no onchain storage)
    /// @dev Only callable by a manager of the strategy
    /// @param strategy Address of the strategy
    /// @param metadataURI The new metadata URI
    function updateMetadataURI(address strategy, string calldata metadataURI) external;

    /*//////////////////////////////////////////////////////////////
                        PAUSE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Manually pauses a strategy
    /// @param strategy Address of the strategy to pause
    function pauseStrategy(address strategy) external;

    /// @notice Manually unpauses a strategy
    /// @param strategy Address of the strategy to unpause
    function unpauseStrategy(address strategy) external;

    /*//////////////////////////////////////////////////////////////
                       MANAGER MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a secondary manager to a strategy
    /// @notice A manager can either be secondary or primary
    /// @param strategy Address of the strategy
    /// @param manager Address of the manager to add
    function addSecondaryManager(address strategy, address manager) external;

    /// @notice Removes a secondary manager from a strategy
    /// @param strategy Address of the strategy
    /// @param manager Address of the manager to remove
    function removeSecondaryManager(address strategy, address manager) external;

    /// @notice Changes the primary manager of a strategy immediately (only callable by SuperGovernor)
    /// @notice A manager can either be secondary or primary
    /// @param strategy Address of the strategy
    /// @param newManager Address of the new primary manager
    /// @param feeRecipient Address of the new fee recipient
    function changePrimaryManager(address strategy, address newManager, address feeRecipient) external;

    /// @notice Proposes a change to the primary manager (callable by secondary managers)
    /// @notice A manager can either be secondary or primary
    /// @param strategy Address of the strategy
    /// @param newManager Address of the proposed new primary manager
    /// @param feeRecipient Address of the new fee recipient
    function proposeChangePrimaryManager(address strategy, address newManager, address feeRecipient) external;

    /// @notice Cancels a pending primary manager change proposal
    /// @dev Only the current primary manager can cancel the proposal
    /// @param strategy Address of the strategy
    function cancelChangePrimaryManager(address strategy) external;

    /// @notice Executes a previously proposed change to the primary manager after timelock
    /// @param strategy Address of the strategy
    function executeChangePrimaryManager(address strategy) external;

    /// @notice Resets the strategy's performance-fee high-water mark to PPS
    /// @dev Only callable by SuperGovernor
    /// @param strategy Address of the strategy
    function resetHighWaterMark(address strategy) external;

    /*//////////////////////////////////////////////////////////////
                        HOOK VALIDATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets a new hooks root update timelock duration
    /// @param newTimelock The new timelock duration in seconds
    function setHooksRootUpdateTimelock(uint256 newTimelock) external;

    /// @notice Proposes an update to the global hooks Merkle root
    /// @dev Only callable by SUPER_GOVERNOR
    /// @param newRoot New Merkle root for global hooks validation
    function proposeGlobalHooksRoot(bytes32 newRoot) external;

    /// @notice Executes a previously proposed global hooks root update after timelock period
    /// @dev Can be called by anyone after the timelock period has elapsed
    function executeGlobalHooksRootUpdate() external;

    /// @notice Proposes an update to a strategy-specific hooks Merkle root
    /// @dev Only callable by the main manager for the strategy
    /// @param strategy Address of the strategy
    /// @param newRoot New Merkle root for strategy-specific hooks
    function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) external;

    /// @notice Executes a previously proposed strategy hooks root update after timelock period
    /// @dev Can be called by anyone after the timelock period has elapsed
    /// @param strategy Address of the strategy whose root update to execute
    function executeStrategyHooksRootUpdate(address strategy) external;

    /// @notice Set veto status for the global hooks root
    /// @dev Only callable by SuperGovernor
    /// @param vetoed Whether to veto (true) or unveto (false) the global hooks root
    function setGlobalHooksRootVetoStatus(bool vetoed) external;

    /// @notice Set veto status for a strategy-specific hooks root
    /// @notice Sets the veto status of a strategy's hooks Merkle root
    /// @param strategy Address of the strategy
    /// @param vetoed Whether to veto (true) or unveto (false)
    function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) external;

    /// @notice Proposes a deviation-threshold change for a strategy (starts the 3-day timelock)
    /// @dev Managed diff: timelocked, unlike the main family's instant setter — manual NAV is
    ///      manager-attested, so the manager must not be able to widen their own bound instantly.
    ///      Bounded to (0, 1e18]; the deviation check can never be disabled.
    /// @param strategy Address of the strategy
    /// @param newDeviationThreshold New deviation threshold (abs diff/current ratio, scaled by 1e18)
    function proposeDeviationThresholdChange(address strategy, uint256 newDeviationThreshold) external;

    /// @notice Executes a pending deviation-threshold change after the timelock
    /// @dev Can be called by anyone once the timelock has elapsed
    /// @param strategy Address of the strategy
    function executeDeviationThresholdChange(address strategy) external;

    /// @notice Cancels a pending deviation-threshold change
    /// @dev Only the main manager can cancel
    /// @param strategy Address of the strategy
    function cancelDeviationThresholdChange(address strategy) external;

    /// @notice Gets the proposed deviation threshold and effective time
    /// @param strategy Address of the strategy
    /// @return proposedThreshold The proposed deviation threshold (0 if none)
    /// @return effectiveTime The timestamp when the proposal can be executed (0 if none)
    function getProposedDeviationThreshold(address strategy)
        external
        view
        returns (uint256 proposedThreshold, uint256 effectiveTime);

    /// @notice Changes the banned status of global leaves for a specific strategy
    /// @dev Only callable by the primary manager of the strategy
    /// @param leaves Array of leaf hashes to change status for
    /// @param statuses Array of banned statuses (true = banned, false = allowed)
    /// @param strategy Address of the strategy to change banned leaves for
    function changeGlobalLeavesStatus(bytes32[] memory leaves, bool[] memory statuses, address strategy) external;

    /*//////////////////////////////////////////////////////////////
                 MIN UPDATE INTERVAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Proposes a change to the minimum update interval for a strategy
    /// @param strategy Address of the strategy
    /// @param newMinUpdateInterval The proposed new minimum update interval (in seconds)
    /// @dev Only the main manager can propose. Must be less than maxStaleness
    function proposeMinUpdateIntervalChange(address strategy, uint256 newMinUpdateInterval) external;

    /// @notice Executes a previously proposed minUpdateInterval change after timelock
    /// @param strategy Address of the strategy whose minUpdateInterval to update
    /// @dev Can be called by anyone after the timelock period has elapsed
    function executeMinUpdateIntervalChange(address strategy) external;

    /// @notice Cancels a pending minUpdateInterval change proposal
    /// @param strategy Address of the strategy
    /// @dev Only the main manager can cancel
    function cancelMinUpdateIntervalChange(address strategy) external;

    /// @notice Gets the proposed minUpdateInterval and effective time
    /// @param strategy Address of the strategy
    /// @return proposedInterval The proposed minimum update interval
    /// @return effectiveTime The timestamp when the proposed interval becomes effective
    function getProposedMinUpdateInterval(address strategy)
        external
        view
        returns (uint256 proposedInterval, uint256 effectiveTime);

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the current vault creation nonce
    /// @dev This nonce is incremented every time a new vault is created
    /// @return Current vault creation nonce
    function getCurrentNonce() external view returns (uint256);

    /// @notice Check if the global hooks root is currently vetoed
    /// @return vetoed True if the global hooks root is vetoed
    function isGlobalHooksRootVetoed() external view returns (bool vetoed);

    /// @notice Check if a strategy hooks root is currently vetoed
    /// @param strategy Address of the strategy to check
    /// @return vetoed True if the strategy hooks root is vetoed
    function isStrategyHooksRootVetoed(address strategy) external view returns (bool vetoed);

    /// @notice Gets the current hooks root update timelock duration
    /// @return The current timelock duration in seconds
    function getHooksRootUpdateTimelock() external view returns (uint256);

    /// @notice Gets the current PPS (price-per-share) for a strategy
    /// @param strategy Address of the strategy
    /// @return pps Current price-per-share value
    function getPPS(address strategy) external view returns (uint256 pps);

    /// @notice Gets the last update timestamp for a strategy's PPS
    /// @param strategy Address of the strategy
    /// @return timestamp Last update timestamp
    function getLastUpdateTimestamp(address strategy) external view returns (uint256 timestamp);

    /// @notice Gets the minimum update interval for a strategy
    /// @param strategy Address of the strategy
    /// @return interval Minimum time between updates
    function getMinUpdateInterval(address strategy) external view returns (uint256 interval);

    /// @notice Gets the maximum staleness period for a strategy
    /// @param strategy Address of the strategy
    /// @return staleness Maximum time allowed between updates
    function getMaxStaleness(address strategy) external view returns (uint256 staleness);

    /// @notice Gets the deviation threshold for a strategy
    /// @param strategy Address of the strategy
    /// @return deviationThreshold The current deviation threshold (abs diff/current ratio, scaled by 1e18)
    function getDeviationThreshold(address strategy) external view returns (uint256 deviationThreshold);

    /// @notice Checks if a strategy is currently paused
    /// @param strategy Address of the strategy
    /// @return isPaused True if paused, false otherwise
    function isStrategyPaused(address strategy) external view returns (bool isPaused);

    /// @notice Checks if a strategy's PPS is stale
    /// @dev PPS is automatically set to stale when the strategy is paused due to
    ///      lack of upkeep payment in `SuperVaultAggregator`
    /// @param strategy Address of the strategy
    /// @return isStale True if stale, false otherwise
    function isPPSStale(address strategy) external view returns (bool isStale);

    /// @notice Gets the last unpause timestamp for a strategy
    /// @param strategy Address of the strategy
    /// @return timestamp Last unpause timestamp (0 if never unpaused)
    function getLastUnpauseTimestamp(address strategy) external view returns (uint256 timestamp);

    /// @notice Gets the deposit queue for a vault
    /// @param vault Address of the ManagedSuperVault
    /// @return queue Address of the vault's deposit queue (address(0) if unknown vault)
    function getDepositQueue(address vault) external view returns (address queue);

    /// @notice Gets all created deposit queues
    /// @return Array of deposit queue addresses
    function getAllDepositQueues() external view returns (address[] memory);

    /// @notice Checks whether an address is a deposit queue created by this aggregator
    /// @param queue Address to check
    /// @return True if the address is a registered deposit queue
    function isDepositQueue(address queue) external view returns (bool);

    /// @notice Gets the current NAV oracle
    /// @return The address of the NAV oracle authorized to push PPS
    function navOracle() external view returns (address);

    /// @notice Gets the main manager for a strategy
    /// @param strategy Address of the strategy
    /// @return manager Address of the main manager
    function getMainManager(address strategy) external view returns (address manager);

    /// @notice Gets pending primary manager change details
    /// @param strategy Address of the strategy
    /// @return proposedManager Address of the proposed new manager (address(0) if no pending change)
    /// @return effectiveTime Timestamp when the change can be executed (0 if no pending change)
    function getPendingManagerChange(address strategy)
        external
        view
        returns (address proposedManager, uint256 effectiveTime);

    /// @notice Checks if an address is the main manager for a strategy
    /// @param manager Address of the manager
    /// @param strategy Address of the strategy
    /// @return isMainManager True if the address is the main manager, false otherwise
    function isMainManager(address manager, address strategy) external view returns (bool isMainManager);

    /// @notice Gets all secondary managers for a strategy
    /// @param strategy Address of the strategy
    /// @return secondaryManagers Array of secondary manager addresses
    function getSecondaryManagers(address strategy) external view returns (address[] memory secondaryManagers);

    /// @notice Checks if an address is a secondary manager for a strategy
    /// @param manager Address of the manager
    /// @param strategy Address of the strategy
    /// @return isSecondaryManager True if the address is a secondary manager, false otherwise
    function isSecondaryManager(address manager, address strategy) external view returns (bool isSecondaryManager);

    /// @dev Internal helper function to check if an address is any kind of manager (primary or secondary)
    /// @param manager Address to check
    /// @param strategy The strategy to check against
    /// @return True if the address is either the primary manager or a secondary manager
    function isAnyManager(address manager, address strategy) external view returns (bool);

    /// @notice Gets all created SuperVaults
    /// @return Array of SuperVault addresses
    function getAllSuperVaults() external view returns (address[] memory);

    /// @notice Gets a SuperVault by index
    /// @param index The index of the SuperVault
    /// @return The SuperVault address at the given index
    function superVaults(uint256 index) external view returns (address);

    /// @notice Gets all created SuperVaultStrategies
    /// @return Array of SuperVaultStrategy addresses
    function getAllSuperVaultStrategies() external view returns (address[] memory);

    /// @notice Gets a SuperVaultStrategy by index
    /// @param index The index of the SuperVaultStrategy
    /// @return The SuperVaultStrategy address at the given index
    function superVaultStrategies(uint256 index) external view returns (address);

    /// @notice Gets all created SuperVaultEscrows
    /// @return Array of SuperVaultEscrow addresses
    function getAllSuperVaultEscrows() external view returns (address[] memory);

    /// @notice Gets a SuperVaultEscrow by index
    /// @param index The index of the SuperVaultEscrow
    /// @return The SuperVaultEscrow address at the given index
    function superVaultEscrows(uint256 index) external view returns (address);

    /// @notice Validates a hook against both global and strategy-specific Merkle roots
    /// @param strategy Address of the strategy
    /// @param args Arguments for hook validation
    /// @return isValid True if the hook is valid against either root
    function validateHook(address strategy, ValidateHookArgs calldata args) external view returns (bool isValid);

    /// @notice Batch validates multiple hooks against Merkle roots
    /// @param strategy Address of the strategy
    /// @param argsArray Array of hook validation arguments
    /// @return validHooks Array of booleans indicating which hooks are valid
    function validateHooks(
        address strategy,
        ValidateHookArgs[] calldata argsArray
    )
        external
        view
        returns (bool[] memory validHooks);

    /// @notice Gets the current global hooks Merkle root
    /// @return root The current global hooks Merkle root
    function getGlobalHooksRoot() external view returns (bytes32 root);

    /// @notice Gets the proposed global hooks root and effective time
    /// @return root The proposed global hooks Merkle root
    /// @return effectiveTime The timestamp when the proposed root becomes effective
    function getProposedGlobalHooksRoot() external view returns (bytes32 root, uint256 effectiveTime);

    /// @notice Checks if the global hooks root is active (timelock period has passed)
    /// @return isActive True if the global hooks root is active
    function isGlobalHooksRootActive() external view returns (bool);

    /// @notice Gets the hooks Merkle root for a specific strategy
    /// @param strategy Address of the strategy
    /// @return root The strategy-specific hooks Merkle root
    function getStrategyHooksRoot(address strategy) external view returns (bytes32 root);

    /// @notice Gets the proposed strategy hooks root and effective time
    /// @param strategy Address of the strategy
    /// @return root The proposed strategy hooks Merkle root
    /// @return effectiveTime The timestamp when the proposed root becomes effective
    function getProposedStrategyHooksRoot(address strategy) external view returns (bytes32 root, uint256 effectiveTime);

    /// @notice Gets the total number of SuperVaults
    /// @return count The total number of SuperVaults
    function getSuperVaultsCount() external view returns (uint256);

    /// @notice Gets the total number of SuperVaultStrategies
    /// @return count The total number of SuperVaultStrategies
    function getSuperVaultStrategiesCount() external view returns (uint256);

    /// @notice Gets the total number of SuperVaultEscrows
    /// @return count The total number of SuperVaultEscrows
    function getSuperVaultEscrowsCount() external view returns (uint256);
}
