// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

/*//////////////////////////////////////////////////////////////
                                  ENUMS
    //////////////////////////////////////////////////////////////*/
/// @notice Enum representing different types of fees that can be managed
enum FeeType {
    REVENUE_SHARE,
    PERFORMANCE_FEE_SHARE
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

    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when trying to access a contract that is not registered
    error CONTRACT_NOT_FOUND();
    /// @notice Thrown when providing an invalid address (typically zero address)
    error INVALID_ADDRESS();
    /// @notice Thrown when a hook is not approved but expected to be
    error HOOK_NOT_APPROVED();
    /// @notice Thrown when an invalid fee value is proposed (must be <= BPS_MAX)
    error INVALID_FEE_VALUE();
    /// @notice Thrown when no proposed fee exists but one is expected
    error NO_PROPOSED_FEE(FeeType feeType);
    /// @notice Thrown when timelock period has not expired
    error TIMELOCK_NOT_EXPIRED();
    /// @notice Thrown when a validator is already registered
    error VALIDATOR_ALREADY_REGISTERED();
    /// @notice Thrown when trying to change active PPS oracle directly
    error MUST_USE_TIMELOCK_FOR_CHANGE();
    /// @notice Thrown when a SuperBank hook Merkle root is not registered but expected to be
    /// @dev This error is defined here for use by other contracts in the system (SuperVaultStrategy,
    /// SuperVaultAggregator, ECDSAPPSOracle)
    error INVALID_TIMESTAMP();
    /// @notice Thrown when attempting to set an invalid quorum value (typically zero)
    error INVALID_QUORUM();
    /// @notice Thrown when validator and public key array lengths don't match
    error ARRAY_LENGTH_MISMATCH();
    /// @notice Thrown when trying to set validator config with an empty validator array
    error EMPTY_VALIDATOR_ARRAY();
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
    /// @notice Thrown when there's no pending change but one is expected
    error NO_PENDING_CHANGE();
    /// @notice Thrown when the super oracle is not found
    error SUPER_ORACLE_NOT_FOUND();
    /// @notice Thrown when the up token is not found
    error UP_NOT_FOUND();
    /// @notice Thrown when the upkeep token is not found
    error UPKEEP_TOKEN_NOT_FOUND();
    /// @notice Thrown when the gas info is invalid
    error INVALID_GAS_INFO();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when an address is set in the registry
    /// @param key The key used to reference the address
    /// @param oldValue The old address value
    /// @param value The address value
    event AddressSet(bytes32 indexed key, address indexed oldValue, address indexed value);

    /// @notice Emitted when a hook is approved
    /// @param hook The address of the approved hook
    event HookApproved(address indexed hook);

    /// @notice Emitted when validator configuration is set
    /// @param version The version of the configuration
    /// @param validators Array of validator addresses
    /// @param validatorPublicKeys Array of validator public keys (for signature verification)
    /// @param quorum The quorum required for validator consensus
    /// @param offchainConfig Offchain configuration data
    event ValidatorConfigSet(
        uint256 version, address[] validators, bytes[] validatorPublicKeys, uint256 quorum, bytes offchainConfig
    );

    /// @notice Emitted when a hook is removed
    /// @param hook The address of the removed hook
    event HookRemoved(address indexed hook);

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
    event MinStalenessProposed(uint256 newMinStaleness, uint256 effectiveTime);

    /// @notice Emitted when the minimum staleness is changed
    /// @param newMinStaleness The new minimum staleness value
    event MinStalenessChanged(uint256 newMinStaleness);

    /// @notice Emitted when gas info is set
    /// @param oracle The address of the oracle
    /// @param gasIncreasePerEntryBatch The gas increase per entry for the oracle
    event GasInfoSet(address indexed oracle, uint256 gasIncreasePerEntryBatch);

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

    /// @notice Change the primary manager for a strategy
    /// @dev Only SuperGovernor can call this function directly
    /// @param strategy The strategy address
    /// @param newManager The new primary manager address
    /// @param feeRecipient The new fee recipient address
    function changePrimaryManager(address strategy, address newManager, address feeRecipient) external;

    /// @notice Resets the high-water mark PPS to the current PPS
    /// @dev Only SuperGovernor can call this function
    /// @dev If a manager is replaced while the strategy is below its
    /// previous HWM, the new manager would otherwise inherit a "loss" state and be unable to earn performance fees
    /// until the fee config are updated after the week timelock.
    /// @dev This function will reset the High Water Mark (vaultHwmPps) to the current PPS value for the given strategy
    /// @param strategy Address of the strategy to reset the high-water mark for
    function resetHighWaterMark(address strategy) external;

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
    function setOracleFeedMaxStalenessBatch(address[] calldata feeds, uint256[] calldata newMaxStalenessList) external;

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

    /// @notice Executes a previously queued oracle update after timelock has expired
    function executeOracleUpdate() external;

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

    /*//////////////////////////////////////////////////////////////
                          HOOK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Registers a hook for use in SuperVaults
    /// @param hook The address of the hook to register
    function registerHook(address hook) external;

    /// @notice Unregisters a hook from the approved list
    /// @param hook The address of the hook to unregister
    function unregisterHook(address hook) external;

    /*//////////////////////////////////////////////////////////////
                        VALIDATOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the validator configuration for the protocol
    /// @dev This function atomically updates all validator configuration including quorum.
    ///      The entire validator set is replaced (not incrementally updated).
    ///      Version must be managed externally for cross-chain synchronization.
    ///      Quorum updates require providing the full validator list.
    /// @param version The version number for the configuration (for cross-chain sync)
    /// @param validators Array of validator addresses
    /// @param validatorPublicKeys Array of validator public keys for signature verification
    /// @param quorum The number of validators required for consensus
    /// @param offchainConfig Offchain configuration data (emitted but not stored)
    function setValidatorConfig(
        uint256 version,
        address[] calldata validators,
        bytes[] calldata validatorPublicKeys,
        uint256 quorum,
        bytes calldata offchainConfig
    )
        external;

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
    /// @param gasIncreasePerEntryBatch The gas increase per entry for the oracle
    function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) external;

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
    function executeMinStalenessChange() external;

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

    /// @notice The identifier of the role that grants access to oracle management functions
    function ORACLE_MANAGER_ROLE() external view returns (bytes32);

    /// @notice The identifier of the role that grants access to guardian functions
    function GUARDIAN_ROLE() external view returns (bytes32);

    /// @notice Gets an address from the registry
    /// @param key The key of the address to get
    /// @return The address value
    function getAddress(bytes32 key) external view returns (address);

    /// @notice Checks if manager takeovers are frozen
    /// @return True if manager takeovers are frozen, false otherwise
    function isManagerTakeoverFrozen() external view returns (bool);

    /// @notice Checks if a hook is registered
    /// @param hook The address of the hook to check
    /// @return True if the hook is registered, false otherwise
    function isHookRegistered(address hook) external view returns (bool);

    /// @notice Gets all registered hooks
    /// @return An array of registered hook addresses
    function getRegisteredHooks() external view returns (address[] memory);

    /// @notice Checks if an address is an approved validator
    /// @param validator The address to check
    /// @return True if the address is an approved validator, false otherwise
    function isValidator(address validator) external view returns (bool);

    /// @notice Checks if an address has the guardian role
    /// @param guardian Address to check
    /// @return true if the address has the GUARDIAN_ROLE
    function isGuardian(address guardian) external view returns (bool);

    /// @notice Returns the complete validator configuration
    /// @return version The current configuration version number
    /// @return validators Array of all registered validator addresses
    /// @return validatorPublicKeys Array of validator public keys
    /// @return quorum The number of validators required for consensus
    function getValidatorConfig()
        external
        view
        returns (uint256 version, address[] memory validators, bytes[] memory validatorPublicKeys, uint256 quorum);

    /// @notice Returns all registered validators
    /// @return List of validator addresses
    function getValidators() external view returns (address[] memory);

    /// @notice Returns the number of registered validators (O(1))
    function getValidatorsCount() external view returns (uint256);

    /// @notice Returns a validator address by index (0 … count-1)
    /// @param index The index into the validators set
    /// @return validator The validator address at the given index
    function getValidatorAt(uint256 index) external view returns (address validator);

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

    /// @notice Gets the current upkeep cost for an entry
    function getUpkeepCostPerSingleUpdate(address oracle_) external view returns (uint256);

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

    /// @notice Gets the proposed Merkle root and its effective time for a specific hook.
    /// @param hook The address of the hook to get the proposed Merkle root for.
    /// @return proposedRoot The proposed Merkle root.
    /// @return effectiveTime The timestamp when the proposed root will become effective.
    function getProposedSuperBankHookMerkleRoot(address hook)
        external
        view
        returns (bytes32 proposedRoot, uint256 effectiveTime);

    /// @notice Checks if upkeep payments are currently enabled
    /// @return enabled True if upkeep payments are enabled
    function isUpkeepPaymentsEnabled() external view returns (bool);

    /// @notice Gets the proposed upkeep payments status and effective time
    /// @return enabled The proposed status
    /// @return effectiveTime The timestamp when the change becomes effective
    function getProposedUpkeepPaymentsStatus() external view returns (bool enabled, uint256 effectiveTime);

    /// @notice Gets the SUP strategy ID
    /// @return The ID of the SUP strategy vault
    function SUP_STRATEGY() external view returns (bytes32);

    /// @notice Gets the UP ID
    /// @return The ID of the UP token
    function UP() external view returns (bytes32);

    /// @notice Gets the UPKEEP_TOKEN ID
    /// @return The ID of the UPKEEP_TOKEN (used for upkeep payments, can be UP on mainnet or WETH/USDC on L2s)
    function UPKEEP_TOKEN() external view returns (bytes32);

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

    /// @notice Gets the gas info for a specific SuperVault PPS Oracle
    /// @param oracle_ The address of the oracle to get gas info for
    /// @return The gas info for the specified oracle
    function getGasInfo(address oracle_) external view returns (uint256);

    /// @notice Cancels a previously proposed oracle provider removal
    function cancelOracleProviderRemoval() external;

    /// @notice Executes a previously proposed oracle provider removal after timelock has expired
    function executeOracleProviderRemoval() external;
}
