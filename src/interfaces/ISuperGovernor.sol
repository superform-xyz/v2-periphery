// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/*//////////////////////////////////////////////////////////////
                                  ENUMS
    //////////////////////////////////////////////////////////////*/
/// @notice Enum representing different types of fees that can be managed
enum FeeType {
    REVENUE_SHARE,
    SUPER_VAULT_PERFORMANCE_FEE,
    SUPER_ASSET_SWAP_FEE
}
/// @title ISuperGovernor
/// @author Superform Labs
/// @notice Interface for the SuperGovernor contract
/// @dev Central registry for all deployed contracts in the Superform periphery

interface ISuperGovernor is IAccessControl {
    /*//////////////////////////////////////////////////////////////
                                  STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Structure containing Merkle root data for a hook
    struct HookMerkleRootData {
        bytes32 currentRoot; // Current active Merkle root for the hook
        bytes32 proposedRoot; // Proposed new Merkle root (zero if no proposal exists)
        uint256 effectiveTime; // Timestamp when the proposed root becomes effective
    }

    struct GasInfo {
        // `batchForwardPPS` base gas
        uint256 baseGasBatch;
        // `batchForwardPPS` gas increase per entry
        uint256 gasIncreasePerEntryBatch;
    }

    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when a function that should only be called by governor is called by someone else
    error ONLY_GOVERNOR();
    /// @notice Thrown when trying to register a contract that is already registered
    error CONTRACT_ALREADY_REGISTERED();
    /// @notice Thrown when trying to access a contract that is not registered
    error CONTRACT_NOT_FOUND();
    /// @notice Thrown when providing an invalid address (typically zero address)
    error INVALID_ADDRESS();
    /// @notice Thrown when providing an invalid chain ID
    error INVALID_CHAIN_ID();
    /// @notice Thrown when a hook is already approved
    error HOOK_ALREADY_APPROVED();
    /// @notice Thrown when a hook is not approved but expected to be
    error HOOK_NOT_APPROVED();
    /// @notice Thrown when a fulfill requests hook is already registered
    error FULFILL_REQUESTS_HOOK_ALREADY_REGISTERED();
    /// @notice Thrown when a fulfill requests hook is not registered but expected to be
    error FULFILL_REQUESTS_HOOK_NOT_REGISTERED();
    /// @notice Thrown when provided revenue share is invalid (exceeds 100%)
    error INVALID_REVENUE_SHARE();
    /// @notice Thrown when an invalid fee value is proposed (must be <= BPS_MAX)
    error INVALID_FEE_VALUE();
    /// @notice Thrown when no proposed fee exists but one is expected
    error NO_PROPOSED_FEE(FeeType feeType);
    /// @notice Thrown when timelock period has not expired
    error TIMELOCK_NOT_EXPIRED();
    /// @notice Thrown when a validator is not registered
    error VALIDATOR_NOT_REGISTERED();
    /// @notice Thrown when a validator is already registered
    error VALIDATOR_ALREADY_REGISTERED();
    /// @notice Thrown when trying to change active PPS oracle directly
    error MUST_USE_TIMELOCK_FOR_CHANGE();
    /// @notice Thrown when a SuperBank hook Merkle root is not registered but expected to be
    error INVALID_TIMESTAMP();
    /// @notice Thrown when attempting to set an invalid quorum value (typically zero)
    error INVALID_QUORUM();
    /// @notice Thrown when no active PPS oracle is set but one is required
    error NO_ACTIVE_PPS_ORACLE();
    /// @notice Thrown when no proposed PPS oracle exists but one is expected
    error NO_PROPOSED_PPS_ORACLE();
    /// @notice Error thrown when manager takeovers are frozen
    error MANAGER_TAKEOVERS_FROZEN();
    /// @notice Thrown when no proposed Merkle root exists but one is expected
    error NO_PROPOSED_MERKLE_ROOT();
    /// @notice Thrown when no proposed Merkle root exists but one is expected
    error ZERO_PROPOSED_MERKLE_ROOT();
    /// @notice Thrown when no proposed minimum staleness exists but one is expected
    error NO_PROPOSED_MIN_STALENESS();
    /// @notice Thrown when the provided maxStaleness is less than the minimum required staleness
    error MAX_STALENESS_TOO_LOW();
    /// @notice Thrown when a relayer is not registered
    error RELAYER_NOT_REGISTERED();
    /// @notice Thrown when a relayer is already registered
    error RELAYER_ALREADY_REGISTERED();
    /// @notice Thrown when an executor is not registered
    error EXECUTOR_NOT_REGISTERED();
    /// @notice Thrown when an executor is already registered
    error EXECUTOR_ALREADY_REGISTERED();
    /// @notice Thrown when there's no pending change but one is expected
    error NO_PENDING_CHANGE();
    /// @notice Thrown when a manager is not registered
    error MANAGER_NOT_REGISTERED();
    /// @notice Thrown when a manager is already registered
    error MANAGER_ALREADY_REGISTERED();
    /// @notice Thrown when a token is already whitelisted
    error TOKEN_ALREADY_WHITELISTED();
    /// @notice Thrown when a token is not proposed for whitelisting but expected to be
    error NOT_PROPOSED_INCENTIVE_TOKEN();
    /// @notice Thrown when a token is not whitelisted but expected to be
    error NOT_WHITELISTED_INCENTIVE_TOKEN();
    /// @notice Thrown when trying to register a keeper that is already registered
    error KEEPER_ALREADY_REGISTERED();
    /// @notice Thrown when trying to unregister a keeper that is not registered
    error KEEPER_NOT_REGISTERED();
    /// @notice Thrown when the price is not found
    error PRICE_NOT_FOUND();
    /// @notice Thrown when the price is stale
    error STALE_ORACLE_PRICE();
    /// @notice Thrown when the super oracle is not found
    error SUPER_ORACLE_NOT_FOUND();
    /// @notice Thrown when the up token is not found
    error UP_NOT_FOUND();
    /// @notice Thrown when the gas info is invalid
    error INVALID_GAS_INFO();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when an address is set in the registry
    /// @param key The key used to reference the address
    /// @param value The address value
    event AddressSet(bytes32 indexed key, address indexed value);

    /// @notice Emitted when a hook is approved
    /// @param hook The address of the approved hook
    event HookApproved(address indexed hook);

    /// @notice Emitted when a hook is removed
    /// @param hook The address of the removed hook
    event HookRemoved(address indexed hook);

    /// @notice Emitted when a fulfill requests hook is registered
    /// @param hook The address of the registered fulfill requests hook
    event FulfillRequestsHookRegistered(address indexed hook);

    /// @notice Emitted when a fulfill requests hook is unregistered
    /// @param hook The address of the unregistered fulfill requests hook
    event FulfillRequestsHookUnregistered(address indexed hook);

    /// @notice Emitted when a validator is registered
    /// @param validator The address of the registered validator
    event ValidatorAdded(address indexed validator);

    /// @notice Emitted when a validator is removed
    /// @param validator The address of the removed validator
    event ValidatorRemoved(address indexed validator);

    /// @notice Emitted when revenue share is updated
    /// @param share The new revenue share percentage
    event RevenueShareUpdated(uint256 share);

    /// @notice Emitted when a new fee is proposed
    /// @param feeType The type of fee being proposed
    /// @param value The proposed fee value (in basis points)
    /// @param effectiveTime The timestamp when the fee will be effective
    event FeeProposed(FeeType indexed feeType, uint256 value, uint256 effectiveTime);

    /// @notice Emitted when a fee is updated
    /// @param feeType The type of fee being updated
    /// @param value The new fee value (in basis points)
    event FeeUpdated(FeeType indexed feeType, uint256 value);

    /// @notice Emitted when a new SuperBank hook Merkle root is proposed
    /// @param hook The hook address for which the Merkle root is being proposed
    /// @param newRoot The new Merkle root
    /// @param effectiveTime The timestamp when the new root will be effective
    event SuperBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime);

    /// @notice Emitted when the SuperBank hook Merkle root is updated.
    /// @param hook The address of the hook for which the Merkle root was updated.
    /// @param newRoot The new Merkle root.
    event SuperBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot);

    /// @notice Emitted when the VaultBank hook Merkle root is proposed
    /// @param hook The hook address for which the Merkle root is being proposed
    /// @param newRoot The new Merkle root
    /// @param effectiveTime The timestamp when the new root will be effective
    event VaultBankHookMerkleRootProposed(address indexed hook, bytes32 newRoot, uint256 effectiveTime);

    /// @notice Emitted when the VaultBank hook Merkle root is updated.
    /// @param hook The address of the hook for which the Merkle root was updated.
    /// @param newRoot The new Merkle root.
    event VaultBankHookMerkleRootUpdated(address indexed hook, bytes32 newRoot);

    /// @notice Emitted when the active PPS Oracle's quorum requirement is updated
    /// @param quorum The new quorum value
    event PPSOracleQuorumUpdated(uint256 quorum);

    /// @notice Emitted when an active PPS oracle is initially set
    /// @param oracle The address of the set oracle
    event ActivePPSOracleSet(address indexed oracle);

    /// @notice Emitted when a new PPS oracle is proposed
    /// @param oracle The address of the proposed oracle
    /// @param effectiveTime The timestamp when the proposal will be effective
    event ActivePPSOracleProposed(address indexed oracle, uint256 effectiveTime);

    /// @notice Emitted when the active PPS oracle is changed
    /// @param oldOracle The address of the previous oracle
    /// @param newOracle The address of the new oracle
    event ActivePPSOracleChanged(address indexed oldOracle, address indexed newOracle);

    /// @notice Event emitted when manager takeovers are permanently frozen
    event ManagerTakeoversFrozen();

    /// @notice Emitted when a relayer is added
    /// @param relayer The address of the added relayer
    event RelayerAdded(address indexed relayer);

    /// @notice Emitted when a relayer is removed
    /// @param relayer The address of the removed relayer
    event RelayerRemoved(address indexed relayer);

    /// @notice Emitted when a vault bank is added
    /// @param chainId The chain ID of the added vault bank
    /// @param vaultBank The address of the added vault bank
    event VaultBankAddressAdded(uint64 indexed chainId, address indexed vaultBank);

    /// @notice Emitted when an executor is added
    /// @param executor The address of the added executor
    event ExecutorAdded(address indexed executor);

    /// @notice Emitted when an executor is removed
    /// @param executor The address of the removed executor
    event ExecutorRemoved(address indexed executor);

    /// @notice Emitted when a prover is set
    /// @param prover The address of the prover
    event ProverSet(address indexed prover);

    /// @notice Emitted when a change to upkeep payments status is proposed
    /// @param enabled The proposed status (enabled/disabled)
    /// @param effectiveTime The timestamp when the status change will be effective
    event UpkeepPaymentsChangeProposed(bool enabled, uint256 effectiveTime);

    /// @notice Emitted when upkeep payments status is changed
    /// @param enabled The new status (enabled/disabled)
    event UpkeepPaymentsChanged(bool enabled);

    /// @notice Emitted when a new minimum staleness is proposed
    /// @param newMinStaleness The proposed minimum staleness value
    /// @param effectiveTime The timestamp when the new value will be effective
    event MinStalenesProposed(uint256 newMinStaleness, uint256 effectiveTime);

    /// @notice Emitted when the minimum staleness is changed
    /// @param newMinStaleness The new minimum staleness value
    event MinStalenesChanged(uint256 newMinStaleness);

    /// @notice Emitted when a superform manager is added
    /// @param manager The address of the added manager
    event SuperformManagerAdded(address indexed manager);

    /// @notice Emitted when a superform manager is removed
    /// @param manager The address of the removed manager
    event SuperformManagerRemoved(address indexed manager);

    /// @notice Emitted when incentive tokens are proposed for whitelisting
    /// @param tokens The addresses of the proposed tokens
    /// @param effectiveTime The timestamp when the proposal will be effective
    event WhitelistedIncentiveTokensProposed(address[] tokens, uint256 effectiveTime);

    /// @notice Emitted when whitelisted incentive tokens are added
    /// @param tokens The addresses of the added tokens
    event WhitelistedIncentiveTokensAdded(address[] tokens);

    /// @notice Emitted when whitelisted incentive tokens are removed
    /// @param tokens The addresses of the removed tokens
    event WhitelistedIncentiveTokensRemoved(address[] tokens);

    /// @notice Emitted when a protected keeper is registered
    /// @param keeper Address of the keeper being registered
    event ProtectedKeeperRegistered(address indexed keeper);

    /// @notice Emitted when a protected keeper is unregistered
    /// @param keeper Address of the keeper being unregistered
    event ProtectedKeeperUnregistered(address indexed keeper);

    /// @notice Emitted when gas info is set
    /// @param oracle The address of the oracle
    /// @param baseGasBatch The base gas for the oracle
    /// @param gasIncreasePerEntryBatch The gas increase per entry for the oracle
    event GasInfoSet(address indexed oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch);

    /*//////////////////////////////////////////////////////////////
                       CONTRACT REGISTRY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets an address in the registry
    /// @param key The key to associate with the address
    /// @param value The address value
    function setAddress(bytes32 key, address value) external;

    /*//////////////////////////////////////////////////////////////
                        PERIPHERY CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the prover address
    /// @param prover The address of the prover
    function setProver(address prover) external;

    /// @notice Change the primary manager for a strategy
    /// @dev Only SuperGovernor can call this function directly
    /// @param strategy The strategy address
    /// @param newManager The new primary manager address
    function changePrimaryManager(address strategy, address newManager) external;

    /// @notice Permanently freezes all manager takeovers globally
    function freezeManagerTakeover() external;

    /// @notice Changes the hooks root update timelock duration
    /// @param newTimelock New timelock duration in seconds
    function changeHooksRootUpdateTimelock(uint256 newTimelock) external;

    /// @notice Proposes a new global hooks Merkle root
    /// @dev Only GOVERNOR_ROLE can call this function
    /// @param newRoot New Merkle root for global hooks validation
    function proposeGlobalHooksRoot(bytes32 newRoot) external;

    /// @notice Sets veto status for global hooks Merkle root
    /// @dev Only GUARDIAN_ROLE can call this function
    /// @param vetoed Whether to veto (true) or unveto (false) the global hooks root
    function setGlobalHooksRootVetoStatus(bool vetoed) external;

    /// @notice Sets veto status for a strategy-specific hooks Merkle root
    /// @dev Only GUARDIAN_ROLE can call this function
    /// @param strategy Address of the strategy to affect
    /// @param vetoed Whether to veto (true) or unveto (false) the strategy hooks root
    function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) external;

    /// @notice Sets the superasset manager for a superasset
    /// @param superAsset The superasset address
    /// @param superAssetManager The new superasset manager address
    function setSuperAssetManager(address superAsset, address superAssetManager) external;

    /// @notice Adds an ICC to the whitelist
    /// @param icc The ICC address to add
    function addICCToWhitelist(address icc) external;

    /// @notice Removes an ICC from the whitelist
    /// @param icc The ICC address to remove
    function removeICCFromWhitelist(address icc) external;

    /// @notice Sets the maximum staleness period for all oracle feeds
    /// @param newMaxStaleness The new maximum staleness period in seconds
    function setOracleMaxStaleness(uint256 newMaxStaleness) external;

    /// @notice Sets the maximum staleness period for a specific oracle feed
    /// @param feed The address of the feed to set staleness for
    /// @param newMaxStaleness The new maximum staleness period in seconds
    function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) external;

    /// @notice Sets the maximum staleness periods for multiple oracle feeds in batch
    /// @param feeds The addresses of the feeds to set staleness for
    /// @param newMaxStalenessList The new maximum staleness periods in seconds
    function setOracleFeedMaxStalenessBatch(
        address[] calldata feeds,
        uint256[] calldata newMaxStalenessList
    )
        external;

    /// @notice Queues an oracle update for execution after timelock period
    /// @param bases Base asset addresses
    /// @param quotes Quote asset addresses
    /// @param providers Provider identifiers
    /// @param feeds Feed addresses
    function queueOracleUpdate(
        address[] calldata bases,
        address[] calldata quotes,
        bytes32[] calldata providers,
        address[] calldata feeds
    )
        external;

    /// @notice Queues a provider removal for execution after timelock period
    /// @param providers The providers to remove
    function queueOracleProviderRemoval(bytes32[] calldata providers) external;

    /// @notice Sets uptime feeds for multiple data oracles in batch (Layer 2 only)
    /// @param dataOracles Array of data oracle addresses to set uptime feeds for
    /// @param uptimeOracles Array of uptime feed addresses to set
    /// @param gracePeriods Array of grace periods in seconds after sequencer restart
    function batchSetOracleUptimeFeed(
        address[] calldata dataOracles,
        address[] calldata uptimeOracles,
        uint256[] calldata gracePeriods
    )
        external;

    /// @notice Sets the emergency price for a token
    /// @param token The address of the token
    /// @param price The emergency price to set
    function setEmergencyPrice(address token, uint256 price) external;

    /// @notice Sets the emergency price for multiple tokens o
    /// @param tokens Array of token addresses
    /// @param prices Array of emergency prices
    function batchSetEmergencyPrices(address[] calldata tokens, uint256[] calldata prices) external;

    /*//////////////////////////////////////////////////////////////
                          HOOK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Registers a hook for use in SuperVaults
    /// @param hook The address of the hook to register
    /// @param isFulfillRequestsHook Whether the hook is a fulfill requests hook
    function registerHook(address hook, bool isFulfillRequestsHook) external;

    /// @notice Unregisters a hook from the approved list
    /// @param hook The address of the hook to unregister
    function unregisterHook(address hook) external;

    /*//////////////////////////////////////////////////////////////
                        EXECUTOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Adds an executor to the approved list
    /// @param executor The address of the executor to add
    function addExecutor(address executor) external;

    /// @notice Removes an executor from the approved list
    /// @param executor The address of the executor to remove
    function removeExecutor(address executor) external;

    /*//////////////////////////////////////////////////////////////
                        RELAYER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Adds a relayer to the approved list
    /// @param relayer The address of the relayer to add
    function addRelayer(address relayer) external;

    /// @notice Removes a relayer from the approved list
    /// @param relayer The address of the relayer to remove
    function removeRelayer(address relayer) external;

    /*//////////////////////////////////////////////////////////////
                      VALIDATOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Adds a validator to the approved list
    /// @param validator The address of the validator to add
    function addValidator(address validator) external;

    /// @notice Removes a validator from the approved list
    /// @param validator The address of the validator to remove
    function removeValidator(address validator) external;

    /*//////////////////////////////////////////////////////////////
                       PPS ORACLE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the active PPS oracle (only if there is no active oracle yet)
    /// @param oracle Address of the PPS oracle to set as active
    function setActivePPSOracle(address oracle) external;

    /// @notice Proposes a new active PPS oracle (when there is already an active one)
    /// @param oracle Address of the PPS oracle to propose as active
    function proposeActivePPSOracle(address oracle) external;

    /// @notice Executes a previously proposed PPS oracle change after timelock has expired
    function executeActivePPSOracleChange() external;

    /// @notice Sets the quorum requirement for the active PPS Oracle
    /// @param quorum The new quorum value
    function setPPSOracleQuorum(uint256 quorum) external;

    /*//////////////////////////////////////////////////////////////
                      REVENUE SHARE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes a new fee value
    /// @param feeType The type of fee to propose
    /// @param value The proposed fee value (in basis points)
    function proposeFee(FeeType feeType, uint256 value) external;

    /// @notice Executes a previously proposed fee update after timelock has expired
    /// @param feeType The type of ffee to execute the update for
    function executeFeeUpdate(FeeType feeType) external;

    /// @notice Executes an upkeep claim on `SuperVaultAggregator`
    /// @param amount The amount to claim
    function executeUpkeepClaim(uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                      UPKEEP COST MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets gas info for an oracle
    /// @param oracle The address of the oracle
    /// @param baseGasBatch The base gas for the oracle
    /// @param gasIncreasePerEntryBatch The gas increase per entry for the oracle
    function setGasInfo(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch) external;

    /// @notice Proposes a change to upkeep payments enabled status
    /// @param enabled The proposed enabled status
    function proposeUpkeepPaymentsChange(bool enabled) external;

    /// @notice Executes a previously proposed upkeep payments status change
    function executeUpkeepPaymentsChange() external;

    /*//////////////////////////////////////////////////////////////
                        MIN STALENESS MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes a new minimum staleness value to prevent maxStaleness from being set too low
    /// @param newMinStaleness The proposed new minimum staleness value in seconds
    function proposeMinStaleness(uint256 newMinStaleness) external;

    /// @notice Executes a previously proposed minimum staleness change after timelock has expired
    function executeMinStalenesChange() external;

    /*//////////////////////////////////////////////////////////////
                        SUPERFORM MANAGER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Adds a manager to the superform managers list
    /// @param manager Address of the manager to add
    function addSuperformManager(address manager) external;

    /// @notice Removes a manager from the superform managers list
    /// @param manager Address of the manager to remove
    function removeSuperformManager(address manager) external;

    /*//////////////////////////////////////////////////////////////
                           VAULT HOOKS MGMT
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes a new Merkle root for a specific hook's allowed targets.
    /// @param hook The address of the hook to update the Merkle root for.
    /// @param proposedRoot The proposed new Merkle root.
    function proposeVaultBankHookMerkleRoot(address hook, bytes32 proposedRoot) external;

    /// @notice Executes a previously proposed Merkle root update for a specific hook if the effective time has passed.
    /// @param hook The address of the hook to execute the update for.
    function executeVaultBankHookMerkleRootUpdate(address hook) external;

    /*//////////////////////////////////////////////////////////////
                           SUPERBANK HOOKS MGMT
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes a new Merkle root for a specific hook's allowed targets.
    /// @param hook The address of the hook to update the Merkle root for.
    /// @param proposedRoot The proposed new Merkle root.
    function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) external;

    /// @notice Executes a previously proposed Merkle root update for a specific hook if the effective time has passed.
    /// @param hook The address of the hook to execute the update for.
    function executeSuperBankHookMerkleRootUpdate(address hook) external;

    /*//////////////////////////////////////////////////////////////
                        VAULT BANK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Adds a vault bank address for a specific chain ID
    /// @param chainId The chain ID to add the vault bank for
    /// @param vaultBank The address of the vault bank to add
    function addVaultBank(uint64 chainId, address vaultBank) external;

    /*//////////////////////////////////////////////////////////////
                        INCENTIVE TOKEN MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Proposes whitelisted incentive tokens
    /// @param tokens The addresses of the tokens to add
    function proposeAddIncentiveTokens(address[] memory tokens) external;

    /// @notice Executes a previously proposed whitelisted incentive token update after timelock has expired
    function executeAddIncentiveTokens() external;

    /// @notice Proposes a new whitelisted incentive token
    /// @param tokens The addresses of the tokens to add
    function proposeRemoveIncentiveTokens(address[] memory tokens) external;

    /// @notice Executes a previously proposed whitelisted incentive tokens removal after timelock has expired
    function executeRemoveIncentiveTokens() external;

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice The identifier of the role that grants access to critical governance functions
    function SUPER_GOVERNOR_ROLE() external view returns (bytes32);

    /// @notice The identifier of the role that grants access to daily operations like hooks and validators
    function GOVERNOR_ROLE() external view returns (bytes32);

    /// @notice The identifier of the role that grants access to bank management functions
    function BANK_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The identifier of the role that grants access to gas management functions
    function GAS_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The identifier of the role that grants access to guardian functions
    function GUARDIAN_ROLE() external view returns (bytes32);

    /// @notice The identifier of the role that grants access to superasset factory
    function SUPER_ASSET_FACTORY() external view returns (bytes32);

    /// @notice Gets an address from the registry
    /// @param key The key of the address to get
    /// @return The address value
    function getAddress(bytes32 key) external view returns (address);

    /// @notice Checks if manager takeovers are frozen
    /// @return True if manager takeovers are frozen, false otherwise
    function isManagerTakeoverFrozen() external view returns (bool);

    /// @notice Gets the vault bank address for a specific chain ID
    /// @param chainId The chain ID to get the vault bank for
    /// @return The vault bank address
    function getVaultBank(uint64 chainId) external view returns (address);

    /// @notice Checks if a hook is registered
    /// @param hook The address of the hook to check
    /// @return True if the hook is registered, false otherwise
    function isHookRegistered(address hook) external view returns (bool);

    /// @notice Checks if a hook is registered as a fulfill requests hook
    /// @param hook The address of the hook to check
    /// @return True if the hook is registered as a fulfill requests hook, false otherwise
    function isFulfillRequestsHookRegistered(address hook) external view returns (bool);

    /// @notice Gets all registered hooks
    /// @return An array of registered hook addresses
    function getRegisteredHooks() external view returns (address[] memory);

    /// @notice Gets all registered fulfill requests hooks
    /// @return An array of registered fulfill requests hook addresses
    function getRegisteredFulfillRequestsHooks() external view returns (address[] memory);

    /// @notice Checks if an address is an approved validator
    /// @param validator The address to check
    /// @return True if the address is an approved validator, false otherwise
    function isValidator(address validator) external view returns (bool);

    /// @notice Checks if an address has the guardian role
    /// @param guardian Address to check
    /// @return true if the address has the GUARDIAN_ROLE
    function isGuardian(address guardian) external view returns (bool);

    /// @notice Checks if an address is an approved relayer
    /// @param relayer The address to check
    /// @return True if the address is an approved relayer, false otherwise
    function isRelayer(address relayer) external view returns (bool);

    /// @notice Checks if an address is an approved executor
    /// @param executor The address to check
    /// @return True if the address is an approved executor, false otherwise
    function isExecutor(address executor) external view returns (bool);

    /// @notice Returns all registered validators
    /// @return List of validator addresses
    function getValidators() external view returns (address[] memory);

    /// @notice Returns all registered relayers
    /// @return List of relayer addresses
    function getRelayers() external view returns (address[] memory);

    /// @notice Returns all registered executors
    /// @return List of executor addresses
    function getExecutors() external view returns (address[] memory);

    /// @notice Gets the proposed active PPS oracle and its effective time
    /// @return proposedOracle The proposed oracle address
    /// @return effectiveTime The timestamp when the proposed oracle will become effective
    function getProposedActivePPSOracle() external view returns (address proposedOracle, uint256 effectiveTime);

    /// @notice Gets the current quorum requirement for the active PPS Oracle
    /// @return The current quorum requirement
    function getPPSOracleQuorum() external view returns (uint256);

    /// @notice Gets the active PPS oracle
    /// @return The active PPS oracle address
    function getActivePPSOracle() external view returns (address);

    /// @notice Checks if an address is the current active PPS oracle
    /// @param oracle The address to check
    /// @return True if the address is the active PPS oracle, false otherwise
    function isActivePPSOracle(address oracle) external view returns (bool);

    /// @notice Gets the current fee value for a specific fee type
    /// @param feeType The type of fee to get
    /// @return The current fee value (in basis points)
    function getFee(FeeType feeType) external view returns (uint256);

    /// @notice Gets the current upkeep cost per batch update for PPS updates
    /// @param oracle The address of the PPS oracle
    /// @param chargeableEntries The number of chargeable entries
    /// @return The current upkeep cost per batch update in UP tokens
    function getUpkeepCostPerBatchUpdate(address oracle, uint256 chargeableEntries) external view returns (uint256);

    /// @notice Gets the proposed upkeep cost per update and its effective time
    /// @notice Gets the current minimum staleness value
    /// @return The current minimum staleness value in seconds
    function getMinStaleness() external view returns (uint256);

    /// @notice Gets the proposed minimum staleness value and its effective time
    /// @return proposedMinStaleness The proposed new minimum staleness value
    /// @return effectiveTime The timestamp when the new value will become effective
    function getProposedMinStaleness() external view returns (uint256 proposedMinStaleness, uint256 effectiveTime);

    /// @notice Returns the current Merkle root for a specific hook's allowed targets.
    /// @param hook The address of the hook to get the Merkle root for.
    /// @return The Merkle root for the hook's allowed targets.
    function getSuperBankHookMerkleRoot(address hook) external view returns (bytes32);

    /// @notice Returns the current Merkle root for a specific hook's allowed targets.
    /// @param hook The address of the hook to get the Merkle root for.
    /// @return The Merkle root for the hook's allowed targets.
    function getVaultBankHookMerkleRoot(address hook) external view returns (bytes32);

    /// @notice Gets the proposed Merkle root and its effective time for a specific hook.
    /// @param hook The address of the hook to get the proposed Merkle root for.
    /// @return proposedRoot The proposed Merkle root.
    /// @return effectiveTime The timestamp when the proposed root will become effective.
    function getProposedSuperBankHookMerkleRoot(address hook)
        external
        view
        returns (bytes32 proposedRoot, uint256 effectiveTime);

    /// @notice Gets the proposed Merkle root and its effective time for a specific hook.
    /// @param hook The address of the hook to get the proposed Merkle root for.
    /// @return proposedRoot The proposed Merkle root.
    /// @return effectiveTime The timestamp when the proposed root will become effective.
    function getProposedVaultBankHookMerkleRoot(address hook)
        external
        view
        returns (bytes32 proposedRoot, uint256 effectiveTime);

    /// @notice Checks if a token is whitelisted as an incentive token
    /// @param token The address of the token to check
    /// @return True if the token is whitelisted as an incentive token, false otherwise
    function isWhitelistedIncentiveToken(address token) external view returns (bool);

    /// @notice Gets the prover address
    /// @return The address of the prover
    function getProver() external view returns (address);

    /// @notice Checks if upkeep payments are currently enabled
    /// @return enabled True if upkeep payments are enabled
    function isUpkeepPaymentsEnabled() external view returns (bool);

    /// @notice Gets the proposed upkeep payments status and effective time
    /// @return enabled The proposed status
    /// @return effectiveTime The timestamp when the change becomes effective
    function getProposedUpkeepPaymentsStatus() external view returns (bool enabled, uint256 effectiveTime);

    /// @notice Checks if an address is a registered superform manager
    /// @param manager The address to check
    /// @return isSuperform True if the address is a superform manager
    function isSuperformManager(address manager) external view returns (bool);

    /// @notice Gets the list of all superform managers
    /// @return managers The list of all superform manager addresses
    function getAllSuperformManagers() external view returns (address[] memory);

    /// @notice Returns up to `limit` superform managers starting from `cursor`
    /// @param cursor The index to start reading from (0 … len-1)
    /// @param limit The maximum number of records to return
    /// @return chunkOfManagers The array slice [cursor … cursor+limit-1]
    /// @return next The next cursor value the caller should use, or 0 to indicate done
    function getManagersPaginated(
        uint256 cursor,
        uint256 limit
    )
        external
        view
        returns (address[] memory chunkOfManagers, uint256 next);

    /// @notice Gets the number of superform managers
    /// @return The number of superform managers
    function getSuperformManagersCount() external view returns (uint256);

    /// @notice Gets the SUP ID
    /// @return The ID of the SUP token
    function SUP() external view returns (bytes32);

    /// @notice Gets the UP ID
    /// @return The ID of the UP token
    function UP() external view returns (bytes32);

    /// @notice Gets the Treasury ID
    /// @return The ID for the Treasury in the registry
    function TREASURY() external view returns (bytes32);

    /// @notice Gets the SuperOracle ID
    /// @return The ID for the SuperOracle in the registry
    function SUPER_ORACLE() external view returns (bytes32);

    /// @notice Gets the ECDSA PPS Oracle ID
    /// @return The ID for the ECDSA PPS Oracle in the registry
    function ECDSAPPSORACLE() external view returns (bytes32);

    /// @notice Gets the SuperVaultAggregator ID
    /// @return The ID for the SuperVaultAggregator in the registry
    function SUPER_VAULT_AGGREGATOR() external view returns (bytes32);

    /// @notice Gets the SuperBank ID
    /// @return The ID for the SuperBank in the registry
    function SUPER_BANK() external view returns (bytes32);

    /// @notice Registers a keeper that cannot be added as authorized caller by managers
    /// @dev Only governance can register protected keepers
    /// @param keeper Address of the keeper to register
    function registerProtectedKeeper(address keeper) external;

    /// @notice Unregisters a protected keeper
    /// @dev Only governance can unregister protected keepers
    /// @param keeper Address of the keeper to unregister
    function unregisterProtectedKeeper(address keeper) external;

    /// @notice Checks if an address is a registered protected keeper
    /// @param keeper Address to check
    /// @return True if the address is a registered protected keeper
    function isProtectedKeeper(address keeper) external view returns (bool);

    /// @notice Gets all registered protected keepers
    /// @return Array of all registered protected keeper addresses
    function getProtectedKeepers() external view returns (address[] memory);

    /// @notice Gets the number of registered protected keepers
    /// @return The number of registered protected keepers
    function getProtectedKeepersCount() external view returns (uint256);

    /// @notice Gets the gas info for a specific SuperVault PPS Oracle
    /// @param oracle_ The address of the oracle to get gas info for
    /// @return The gas info for the specified oracle
    function getGasInfo(address oracle_) external view returns (GasInfo memory);
}
