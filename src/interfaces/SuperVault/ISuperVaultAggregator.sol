// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ISuperVaultStrategy } from "../SuperVault/ISuperVaultStrategy.sol";

/// @title ISuperVaultAggregator
/// @author Superform Labs
/// @notice Interface for the SuperVaultAggregator contract
/// @dev Registry and PPS oracle for all SuperVaults
interface ISuperVaultAggregator {
    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Arguments for forwarding PPS updates to avoid stack too deep errors
    /// @param strategy Address of the strategy being updated
    /// @param isExempt Whether the update is exempt from paying upkeep
    /// @param pps New price-per-share value
    /// @param ppsStdev Standard deviation of the price-per-share
    /// @param validatorSet Number of validators who calculated this PPS
    /// @param totalValidators Total number of validators in the network
    /// @param timestamp Timestamp when the value was generated
    /// @param upkeepCost Amount of upkeep tokens to charge if not exempt
    struct PPSUpdateData {
        address strategy;
        bool isExempt;
        uint256 pps;
        uint256 ppsStdev;
        uint256 validatorSet;
        uint256 totalValidators;
        uint256 timestamp;
        uint256 upkeepCost;
    }

    /// @notice Local variables for vault creation to avoid stack too deep
    /// @param currentNonce Current vault creation nonce
    /// @param salt Salt for deterministic proxy creation
    /// @param success Whether asset decimals retrieval was successful
    /// @param assetDecimals Decimals of the underlying asset
    /// @param underlyingDecimals Final decimals to use (18 if retrieval failed)
    /// @param initialPPS Initial price-per-share value
    struct VaultCreationLocalVars {
        uint256 currentNonce;
        bytes32 salt;
        bool success;
        uint8 assetDecimals;
        uint8 underlyingDecimals;
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
    /// @param authorizedCallers List of callers authorized to update PPS without paying upkeep
    struct StrategyData {
        uint256 pps;
        uint256 ppsStdev;
        uint256 lastUpdateTimestamp;
        uint256 minUpdateInterval;
        uint256 maxStaleness;
        bool ppsStale;
        bool isPaused;
        address mainManager;
        EnumerableSet.AddressSet secondaryManagers;
        EnumerableSet.AddressSet authorizedCallers;
        // Manager change proposal data
        address proposedManager;
        uint256 managerChangeEffectiveTime;
        // Hook validation data
        bytes32 managerHooksRoot;
        // Hook root update proposal data
        bytes32 proposedHooksRoot;
        uint256 hooksRootEffectiveTime;
        // Veto status
        bool hooksRootVetoed;
        // PPS Verification thresholds
        uint256 dispersionThreshold; // Threshold for standard deviation / mean
        uint256 deviationThreshold; // Threshold for abs(new - current) / current
        uint256 mnThreshold; // Threshold for validatorSet / totalValidators ratio, scaled by 1e18
        // Banned global leaves mapping
        mapping(bytes32 => bool) bannedLeaves; // Mapping of leaf hash to banned status
        uint256 maxUnpauseTimeLock;
    }

    /// @notice Parameters for creating a new SuperVault trio
    /// @param asset Address of the underlying asset
    /// @param name Name of the vault token
    /// @param symbol Symbol of the vault token
    /// @param mainManager Address of the vault mainManager
    /// @param minUpdateInterval Minimum time interval between PPS updates
    /// @param maxStaleness Maximum time allowed between PPS updates before staleness
    /// @param feeConfig Fee configuration for the vault
    struct VaultCreationParams {
        address asset;
        string name;
        string symbol;
        address mainManager;
        address[] secondaryManagers;
        uint256 minUpdateInterval;
        uint256 maxStaleness;
        ISuperVaultStrategy.FeeConfig feeConfig;
        uint256 maxUnpauseTimeLock;
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

    struct WithdrawStakeRequest {
        uint256 amount;
        uint256 timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a new vault trio is created
    /// @param vault Address of the created SuperVault
    /// @param strategy Address of the created SuperVaultStrategy
    /// @param escrow Address of the created SuperVaultEscrow
    /// @param asset Address of the underlying asset
    /// @param name Name of the vault token
    /// @param symbol Symbol of the vault token
    /// @param nonce The nonce used for vault creation
    event VaultDeployed(
        address indexed vault,
        address indexed strategy,
        address escrow,
        address asset,
        string name,
        string symbol,
        uint256 indexed nonce
    );

    /// @notice Emitted when a PPS value is updated
    /// @param strategy Address of the strategy
    /// @param pps New price-per-share value
    /// @param ppsStdev Standard deviation of price-per-share value
    /// @param validatorSet Number of validators who calculated this PPS
    /// @param totalValidators Total number of validators in the network
    /// @param timestamp Timestamp of the update
    event PPSUpdated(
        address indexed strategy,
        uint256 pps,
        uint256 ppsStdev,
        uint256 validatorSet,
        uint256 totalValidators,
        uint256 timestamp
    );

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

    /// @notice Emitted when upkeep tokens are deposited
    /// @param manager Address of the manager
    /// @param amount Amount of UP tokens deposited
    event UpkeepDeposited(address indexed manager, uint256 amount);

    /// @notice Emitted when upkeep tokens are withdrawn
    /// @param manager Address of the manager
    /// @param amount Amount of UP tokens withdrawn
    event UpkeepWithdrawn(address indexed manager, uint256 amount);

    /// @notice Emitted when upkeep tokens are spent for validation
    /// @param manager Address of the manager
    /// @param amount Amount of UP tokens spent
    /// @param balance Current balance of the manager
    /// @param claimableUpkeep Amount of upkeep tokens claimable by the manager
    event UpkeepSpent(address indexed manager, uint256 amount, uint256 balance, uint256 claimableUpkeep);

    /// @notice Emitted when stake tokens are deposited
    /// @param manager Address of the manager
    /// @param amount Amount of UP tokens deposited as stake
    event StakeDeposited(address indexed manager, uint256 amount);

    /// @notice Emitted when a stake withdrawal request is initiated
    /// @param manager Address of the manager
    /// @param amount Amount of UP tokens to withdraw
    event StakeWithdrawRequested(address indexed manager, uint256 amount);

    /// @notice Emitted when stake tokens are withdrawn
    /// @param manager Address of the manager
    /// @param amount Amount of UP tokens withdrawn from stake
    event StakeWithdrawn(address indexed manager, uint256 amount);

    /// @notice Emitted when a manager's stake is slashed
    /// @param manager The manager whose stake was slashed
    /// @param amount The amount of UP tokens slashed
    event StakeSlashed(address indexed manager, uint256 amount);

    /// @notice Emitted when an authorized caller is added for a strategy
    /// @param strategy Address of the strategy
    /// @param caller Address of the authorized caller
    event AuthorizedCallerAdded(address indexed strategy, address indexed caller);

    /// @notice Emitted when an authorized caller is removed for a strategy
    /// @param strategy Address of the strategy
    /// @param caller Address of the removed caller
    event AuthorizedCallerRemoved(address indexed strategy, address indexed caller);

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
    event PrimaryManagerChanged(address indexed strategy, address indexed oldManager, address indexed newManager);

    /// @notice Emitted when a primary manager is changed to a superform manager
    /// @param strategy Address of the strategy
    /// @param oldManager Address of the old primary manager
    /// @param newManager Address of the new primary manager (superform manager)
    event PrimaryManagerChangedToSuperform(
        address indexed strategy, address indexed oldManager, address indexed newManager
    );

    /// @notice Emitted when a change to primary manager is proposed by a secondary manager
    /// @param strategy Address of the strategy
    /// @param proposer Address of the secondary manager who made the proposal
    /// @param newManager Address of the proposed new primary manager
    /// @param effectiveTime Timestamp when the proposal can be executed
    event PrimaryManagerChangeProposed(
        address indexed strategy, address indexed proposer, address indexed newManager, uint256 effectiveTime
    );

    /// @notice Emitted when a PPS update is stale (Validators could get slashed for innactivity)
    /// @param strategy Address of the strategy
    /// @param updateAuthority Address of the update authority
    /// @param timestamp Timestamp of the stale update
    event StaleUpdate(address indexed strategy, address indexed updateAuthority, uint256 timestamp);

    /// @notice Emitted when the upkeep cost per update is changed
    /// @param oldCost Previous upkeep cost per update
    /// @param newCost New upkeep cost per update
    event UpkeepCostUpdated(uint256 oldCost, uint256 newCost);

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

    /// @notice Emitted when a strategy's PPS verification thresholds are updated
    /// @param strategy Address of the strategy
    /// @param dispersionThreshold New dispersion threshold (stddev/mean)
    /// @param deviationThreshold New deviation threshold (abs diff/current)
    /// @param mnThreshold New M/N threshold (validatorSet/totalValidators)
    event PPSVerificationThresholdsUpdated(
        address indexed strategy, uint256 dispersionThreshold, uint256 deviationThreshold, uint256 mnThreshold
    );

    /// @notice Emitted when the hooks root update timelock is changed
    /// @param newTimelock New timelock duration in seconds
    event HooksRootUpdateTimelockChanged(uint256 newTimelock);

    /// @notice Emitted when global leaves status is changed for a strategy
    /// @param strategy Address of the strategy
    /// @param leaves Array of leaf hashes that had their status changed
    /// @param statuses Array of new banned statuses (true = banned, false = allowed)
    event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses);

    /// @notice Emitted when a proposed global hooks root update is vetoed by a guardian
    /// @param guardian Address of the guardian who vetoed the update
    /// @param root The vetoed root value
    event GlobalHooksRootVetoed(address indexed guardian, bytes32 indexed root);

    /// @notice Emitted when a proposed strategy hooks root update is vetoed by a guardian
    /// @param guardian Address of the guardian who vetoed the update
    /// @param strategy Address of the strategy whose root update was vetoed
    /// @param root The vetoed root value
    event StrategyHooksRootVetoed(address indexed guardian, address indexed strategy, bytes32 indexed root);

    /// @notice Emitted when upkeep is claimed
    /// @param superBank Address of the superBank
    /// @param amount Amount of upkeep claimed
    event UpkeepClaimed(address indexed superBank, uint256 amount);

    /// @notice Emitted when PPS update is too frequent (before minUpdateInterval)
    event UpdateTooFrequent();

    /// @notice Emitted when PPS update timestamp is not monotonically increasing
    event TimestampNotMonotonic();

    /// @notice Emitted when a manager does not have enough upkeep balance
    event InsufficientUpkeep(address indexed strategy, address indexed manager, uint256 balance, uint256 cost);

    /// @notice Emitted when the provided timestamp is too large
    event ProvidedTimestampExceedsBlockTimestamp(
        address indexed strategy, uint256 argsTimestamp, uint256 blockTimestamp
    );

    /// @notice Emitted when a strategy is unknown
    event UnknownStrategy(address indexed strategy);

    /// @notice Emitted when the caller is authorized
    event AuthorizedCaller(address indexed strategy, address indexed caller);

    /// @notice Emitted when the old primary manager is removed from the strategy
    /// @dev This can happen because of reaching the max number of secondary managers
    event OldPrimaryManagerRemoved(address indexed strategy, address indexed oldManager);

    /// @notice Emitted when payment is skipped for a paused strategy
    event PaymentSkippedForPausedStrategy(address indexed strategy);

    /// @notice Emitted when the strategy's PPS unpause timelock is updated
    event StrategyUnpausePPSTimelockUpdated(address indexed strategy, uint256 newTimelock);

    /// @notice Emitted when a strategy's PPS is stale
    event StrategyPPSStale(address indexed strategy);
    
    /// @notice Emitted when a strategy's PPS is reset
    event StrategyPPSStaleReset(address indexed strategy);

    /*///////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when address provided is zero
    error ZERO_ADDRESS();
    /// @notice Thrown when amount provided is zero
    error ZERO_AMOUNT();
    /// @notice Thrown when array length is zero
    error ZERO_ARRAY_LENGTH();
    /// @notice Thrown when array length is zero
    error ARRAY_LENGTH_MISMATCH();
    /// @notice Thrown when asset is invalid
    error INVALID_ASSET();
    /// @notice Thrown when insufficient upkeep balance for operation
    error INSUFFICIENT_UPKEEP();
    /// @notice Thrown when vault is paused but operation requires active state
    error VAULT_PAUSED();
    /// @notice Thrown when caller is not an approved PPS oracle
    error UNAUTHORIZED_PPS_ORACLE();
    /// @notice Thrown when PPS update is too stale (after maxStaleness)
    error UPDATE_TOO_STALE();
    /// @notice Thrown when caller is not authorized for update
    error UNAUTHORIZED_UPDATE_AUTHORITY();
    /// @notice Thrown when strategy address is not a known SuperVault strategy
    error UNKNOWN_STRATEGY();
    /// @notice Thrown when withdrawing more upkeep than available
    error INSUFFICIENT_UPKEEP_BALANCE();
    /// @notice Thrown when withdrawing more stake than available
    error INSUFFICIENT_STAKE_BALANCE();
    /// @notice Thrown when trying to unpause a strategy that is not paused
    error STRATEGY_NOT_PAUSED();
    /// @notice Thrown when caller is already authorized
    error CALLER_ALREADY_AUTHORIZED();
    /// @notice Thrown when caller is not authorized
    error CALLER_NOT_AUTHORIZED();
    /// @notice Thrown when array index is out of bounds
    error INDEX_OUT_OF_BOUNDS();
    /// @notice Thrown when attempting to remove the last manager
    error CANNOT_REMOVE_LAST_MANAGER();
    /// @notice Thrown when attempting to add a manager that already exists
    error MANAGER_ALREADY_EXISTS();
    /// @notice Thrown when there is no pending global hooks root change
    error NO_PENDING_GLOBAL_ROOT_CHANGE();
    /// @notice Thrown when attempting to execute an in-progress manager change before timelock elapsed
    error MANAGER_CHANGE_NOT_READY();
    /// @notice Thrown when attempting to execute a hooks root change before timelock has elapsed
    error ROOT_UPDATE_NOT_READY();
    /// @notice Thrown when a provided hook fails Merkle proof validation
    error HOOK_VALIDATION_FAILED();
    /// @notice Thrown when a non-guardian tries to veto a root update
    error NOT_A_GUARDIAN();
    /// @notice Thrown when trying to veto a root update that doesn't exist
    error NO_PENDING_ROOT_UPDATE();
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
    /// @notice Thrown when trying to add a protected keeper as an authorized caller
    error CANNOT_ADD_PROTECTED_KEEPER();
    /// @notice Thrown when the provided maxStaleness is less than the minimum required staleness
    error MAX_STALENESS_TOO_LOW();
    /// @notice Thrown when arrays have mismatched lengths
    error MISMATCHED_ARRAY_LENGTHS();
    /// @notice Thrown when timestamp is invalid
    error INVALID_TIMESTAMP(uint256 index);
    /// @notice Thrown when too many secondary managers are added
    error TOO_MANY_SECONDARY_MANAGERS();
    /// @notice Thrown when the number of strategies exceeds the maximum allowed
    error MAX_STRATEGIES_EXCEEDED();
    /// @notice Thrown when withdrawal request is expired
    error WITHDRAWAL_REQUEST_EXPIRED();
    /// @notice Thrown when withdrawal request is not ready
    error WITHDRAW_STAKE_REQUEST_NOT_READY();
    /// @notice Thrown when withdrawal request is not found
    error WITHDRAW_STAKE_REQUEST_NOT_FOUND();
    /// @notice Thrown when PPS is too stale to unpause a strategy
    error UNPAUSE_TIMELOCK_NOT_MET();

    /*//////////////////////////////////////////////////////////////
                            VAULT CREATION
    //////////////////////////////////////////////////////////////*/
    /// @notice Creates a new SuperVault trio (SuperVault, SuperVaultStrategy, SuperVaultEscrow)
    /// @param params Parameters for the new vault creation
    /// @return superVault Address of the created SuperVault
    /// @return strategy Address of the created SuperVaultStrategy
    /// @return escrow Address of the created SuperVaultEscrow
    function createVault(VaultCreationParams calldata params)
        external
        returns (address superVault, address strategy, address escrow);

    /*//////////////////////////////////////////////////////////////
                          PPS UPDATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Arguments for batch forwarding PPS updates
    /// @param strategies Array of strategy addresses
    /// @param ppss Array of price-per-share values
    /// @param ppsStdevs Array of standard deviations of price-per-share values
    /// @param validatorSet Number of validators who calculated the PPS (same for all strategies)
    /// @param totalValidator Total number of validators in the network (same for all strategies)
    /// @param timestamps Array of timestamps when values were generated
    struct ForwardPPSArgs {
        address[] strategies;
        uint256[] ppss;
        uint256[] ppsStdevs;
        uint256 validatorSet;
        uint256 totalValidator;
        uint256[] timestamps;
        address updateAuthority;
    }

    /// @notice Batch forwards validated PPS updates to multiple strategies
    /// @param args Struct containing all batch PPS update parameters
    function forwardPPS(ForwardPPSArgs calldata args) external;

    /*//////////////////////////////////////////////////////////////
                        UPKEEP MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposits UP tokens for manager upkeep
    /// @param manager Address of the manager to deposit for
    /// @param amount Amount of UP tokens to deposit
    function depositUpkeep(address manager, uint256 amount) external;

    /// @notice Withdraws UP tokens from manager upkeep balance
    /// @param amount Amount of UP tokens to withdraw
    function withdrawUpkeep(uint256 amount) external;

    /// @notice Claims upkeep tokens from the contract
    /// @param amount Amount of UP tokens to claim
    function claimUpkeep(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                        STAKE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposits UP tokens as stake for manager economic security
    /// @param manager Address of the manager to deposit stake for
    /// @param amount Amount of UP tokens to deposit as stake
    function depositStake(address manager, uint256 amount) external;

    /// @notice Initiates withdrawal of staked UP tokens
    /// @param amount Amount of UP tokens to withdraw from stake
    function requestStakeWithdrawal(uint256 amount) external;

    /// @notice Executes the withdrawal of UP tokens from manager stake balance
    function completeStakeWithdrawal() external;

    /// @notice Slashes a manager's stake balance by a specified amount
    /// @param manager The manager whose stake will be slashed
    /// @param amount The amount of UP tokens to slash from the manager's stake balance
    function slashStake(address manager, uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                        AUTHORIZED CALLER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds an authorized caller for a strategy
    /// @param strategy Address of the strategy
    /// @param caller Address of the caller to authorize
    function addAuthorizedCaller(address strategy, address caller) external;

    /// @notice Removes an authorized caller for a strategy
    /// @param strategy Address of the strategy
    /// @param caller Address of the caller to remove
    function removeAuthorizedCaller(address strategy, address caller) external;

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
    function changePrimaryManager(address strategy, address newManager) external;

    /// @notice Proposes a change to the primary manager (callable by secondary managers)
    /// @notice A manager can either be secondary or primary
    /// @param strategy Address of the strategy
    /// @param newManager Address of the proposed new primary manager
    function proposeChangePrimaryManager(address strategy, address newManager) external;

    /// @notice Executes a previously proposed change to the primary manager after timelock
    /// @param strategy Address of the strategy
    function executeChangePrimaryManager(address strategy) external;

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

    /// @notice Updates the PPS verification thresholds for a strategy
    /// @param strategy Address of the strategy
    /// @param dispersionThreshold_ New dispersion threshold (stddev/mean ratio, scaled by 1e18)
    /// @param deviationThreshold_ New deviation threshold (abs diff/current ratio, scaled by 1e18)
    /// @param mnThreshold_ New M/N threshold (validatorSet/totalValidators ratio, scaled by 1e18)
    function updatePPSVerificationThresholds(
        address strategy,
        uint256 dispersionThreshold_,
        uint256 deviationThreshold_,
        uint256 mnThreshold_
    )
        external;

    /// @notice Changes the banned status of global leaves for a specific strategy
    /// @dev Only callable by the primary manager of the strategy
    /// @param leaves Array of leaf hashes to change status for
    /// @param statuses Array of banned statuses (true = banned, false = allowed)
    /// @param strategy Address of the strategy to change banned leaves for
    function changeGlobalLeavesStatus(bytes32[] memory leaves, bool[] memory statuses, address strategy) external;

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

    /// @notice Gets the current PPS and its standard deviation for a strategy
    /// @param strategy Address of the strategy
    /// @return pps Current price-per-share value
    /// @return ppsStdev Standard deviation of price-per-share value
    function getPPSWithStdDev(address strategy) external view returns (uint256 pps, uint256 ppsStdev);

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

    /// @notice Gets the PPS verification thresholds for a strategy
    /// @param strategy Address of the strategy
    /// @return dispersionThreshold The current dispersion threshold (stddev/mean ratio, scaled by 1e18)
    /// @return deviationThreshold The current deviation threshold (abs diff/current ratio, scaled by 1e18)
    /// @return mnThreshold The current M/N threshold (validatorSet/totalValidators ratio, scaled by 1e18)
    function getPPSVerificationThresholds(address strategy)
        external
        view
        returns (uint256 dispersionThreshold, uint256 deviationThreshold, uint256 mnThreshold);

    /// @notice Checks if a strategy is currently paused
    /// @param strategy Address of the strategy
    /// @return isPaused True if paused, false otherwise
    function isStrategyPaused(address strategy) external view returns (bool isPaused);

    /// @notice Gets the current upkeep balance for a manager
    /// @param manager Address of the manager
    /// @return balance Current upkeep balance in UP tokens
    function getUpkeepBalance(address manager) external view returns (uint256 balance);

    /// @notice Gets the current stake balance for a manager
    /// @param manager Address of the manager
    /// @return balance Current stake balance in UP tokens
    function getStakeBalance(address manager) external view returns (uint256 balance);

    /// @notice Gets all authorized callers for a strategy
    /// @param strategy Address of the strategy
    /// @return callers Array of authorized callers
    function getAuthorizedCallers(address strategy) external view returns (address[] memory callers);

    /// @notice Gets the main manager for a strategy
    /// @param strategy Address of the strategy
    /// @return manager Address of the main manager
    function getMainManager(address strategy) external view returns (address manager);

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
    function getProposedStrategyHooksRoot(address strategy)
        external
        view
        returns (bytes32 root, uint256 effectiveTime);

    /// @notice Updates the strategy's PPS unpause timelock
    /// @param strategy Address of the strategy
    /// @param timelock The new timelock value
    function updateUnpausePPSTimelock(address strategy, uint256 timelock) external;
}
