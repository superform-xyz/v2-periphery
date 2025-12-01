// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Superform
import { ISuperGovernor, FeeType } from "./interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "./interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperOracle } from "./interfaces/oracles/ISuperOracle.sol";
import { ISuperOracleL2 } from "./interfaces/oracles/ISuperOracleL2.sol";

/// @title SuperGovernor
/// @author Superform Labs
/// @notice Central registry for all deployed contracts in the Superform periphery
contract SuperGovernor is ISuperGovernor, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    // Address registry
    mapping(bytes32 id => address address_) private _addressRegistry;

    // PPS Oracle management
    // Current active PPS Oracle
    address private _activePPSOracle;
    // Proposed new active PPS Oracle
    address private _proposedActivePPSOracle;
    // Effective time for proposed active PPS Oracle change
    uint256 private _activePPSOracleEffectiveTime;

    // Hook registry
    EnumerableSet.AddressSet private _registeredHooks;

    // SuperBank Hook Target validation
    mapping(address hook => ISuperGovernor.HookMerkleRootData merkleData) private superBankHooksMerkleRoots;

    // Global freeze for manager takeovers
    bool private _managerTakeoversFrozen;

    // Validator configuration struct
    struct ValidatorConfig {
        uint256 version;
        EnumerableSet.AddressSet validators;
        bytes[] validatorPublicKeys;
        uint256 quorum;
    }

    // Validator configuration
    ValidatorConfig private _validatorConfig;

    // Fee management - packed struct for gas optimization
    struct FeeData {
        uint128 value; // Current fee value (BPS, max 10000)
        uint128 proposedValue; // Proposed fee value
        uint256 effectiveTime; // Timestamp when proposed value becomes effective
    }
    mapping(FeeType => FeeData) private _feeData;

    mapping(address _oracle => uint256 _entryGas) private _gasPerEntry;

    // Upkeep control
    bool private _upkeepPaymentsEnabled;
    bool private _proposedUpkeepPaymentsEnabled;
    uint256 private _upkeepPaymentsChangeEffectiveTime;

    // Min staleness configuration to prevent maxStaleness from being set too low
    uint256 private _minStaleness;
    uint256 private _proposedMinStaleness;
    uint256 private _minStalenessEffectiveTime;

    // Oracle constants for price conversions in _convertGasToUpkeepToken()
    // Standard ERC-7281 address for native token (ETH)
    address private constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    // ISO 4217 numeric code for USD (840)
    address private constant USD_TOKEN = address(840);
    // Synthetic address for gas units in oracle pricing
    address private constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    // Synthetic address for wei units in oracle pricing
    address private constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    // Provider identifier for averaged oracle prices
    bytes32 private constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // Timelock configuration
    // 7-day timelock for critical parameter changes (standard governance delay)
    uint256 private constant TIMELOCK = 7 days;
    uint256 private constant BPS_MAX = 10_000; // 100% in basis points

    // Role definitions
    bytes32 private constant _SUPER_GOVERNOR_ROLE = keccak256("SUPER_GOVERNOR_ROLE");
    bytes32 private constant _GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 private constant _BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");
    bytes32 private constant _GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 private constant _GAS_MANAGER_ROLE = keccak256("GAS_MANAGER_ROLE");
    bytes32 private constant _ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");

    // Common contract keys
    bytes32 public constant UP = keccak256("UP");
    bytes32 public constant UPKEEP_TOKEN = keccak256("UPKEEP_TOKEN");
    bytes32 public constant SUP_STRATEGY = keccak256("SUP_STRATEGY");
    bytes32 public constant TREASURY = keccak256("TREASURY");
    bytes32 public constant SUPER_BANK = keccak256("SUPER_BANK");
    bytes32 public constant SUPER_ORACLE = keccak256("SUPER_ORACLE");
    bytes32 public constant BANK_MANAGER = keccak256("BANK_MANAGER");
    bytes32 public constant ECDSAPPSORACLE = keccak256("ECDSAPPSORACLE");
    bytes32 public constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    // Fee constants
    uint256 public constant REVENUE_SHARE = 0; // 0% starting revenue share to sUP
    uint256 public constant PERFORMANCE_FEE_SHARE = 5000; // 50% protocol share of manager's performance fee

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the SuperGovernor contract
    /// @param superGovernor Address of the default admin (will have SUPER_GOVERNOR_ROLE)
    /// @param governor Address that will have the GOVERNOR_ROLE for daily operations
    /// @param bankManager Address that will have the BANK_MANAGER_ROLE for daily operations
    /// @param oracleManager Address that will have the ORACLE_MANAGER_ROLE for daily operations
    /// @param gasManager Address that will have the GAS_MANAGER_ROLE for daily operations
    /// @param guardian Address that will have the GUARDIAN_ROLE for veto operations
    /// @param treasury Address of the treasury
    /// @param upkeepPaymentsEnabled Initial value for upkeep payments (true for mainnet, false otherwise)
    constructor(
        address superGovernor,
        address governor,
        address bankManager,
        address oracleManager,
        address gasManager,
        address guardian,
        address treasury,
        bool upkeepPaymentsEnabled
    ) {
        if (
            superGovernor == address(0) || treasury == address(0) || governor == address(0) || bankManager == address(0)
                || gasManager == address(0) || oracleManager == address(0) || guardian == address(0)
        ) revert INVALID_ADDRESS();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, superGovernor);
        _grantRole(_SUPER_GOVERNOR_ROLE, superGovernor);
        _grantRole(_GOVERNOR_ROLE, governor);
        _grantRole(_BANK_MANAGER_ROLE, bankManager);
        _grantRole(_ORACLE_MANAGER_ROLE, oracleManager);
        _grantRole(_GAS_MANAGER_ROLE, gasManager);
        _grantRole(_GUARDIAN_ROLE, guardian);

        // Set role admins
        _setRoleAdmin(_GUARDIAN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_SUPER_GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_BANK_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_ORACLE_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_GAS_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);

        // Initialize with default fees
        // casting to 'uint128' is safe because REVENUE_SHARE and PERFORMANCE_FEE_SHARE are constants < BPS_MAX (10000)
        // forge-lint: disable-next-line(unsafe-typecast)
        _feeData[FeeType.REVENUE_SHARE].value = uint128(REVENUE_SHARE); // 0% revenue share (changeable via governance)
        // forge-lint: disable-next-line(unsafe-typecast)
        _feeData[FeeType.PERFORMANCE_FEE_SHARE].value = uint128(PERFORMANCE_FEE_SHARE); // 50% protocol fee share
        emit FeeUpdated(FeeType.REVENUE_SHARE, REVENUE_SHARE);
        emit FeeUpdated(FeeType.PERFORMANCE_FEE_SHARE, PERFORMANCE_FEE_SHARE);

        // Set treasury in address registry
        _addressRegistry[TREASURY] = treasury;
        emit AddressSet(TREASURY, address(0), treasury);

        // Initialize minimum staleness to 5 minutes (300 seconds)
        // Prevents oracle manipulation via extremely low staleness values
        // Ensures sufficient time for price feed updates across providers
        _minStaleness = 300;

        // Initialize upkeep payments enabled status
        // True for mainnet (where upkeep is needed), false otherwise
        _upkeepPaymentsEnabled = upkeepPaymentsEnabled;
    }

    /*//////////////////////////////////////////////////////////////
                       CONTRACT REGISTRY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function setAddress(bytes32 key, address value) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (value == address(0)) revert INVALID_ADDRESS();

        address oldValue = _addressRegistry[key];

        _addressRegistry[key] = value;
        emit AddressSet(key, oldValue, value);
    }

    /*//////////////////////////////////////////////////////////////
                    PERIPHERY CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function changePrimaryManager(
        address strategy,
        address newManager,
        address feeRecipient
    )
        external
        onlyRole(_SUPER_GOVERNOR_ROLE)
    {
        // Check if takeovers are globally frozen
        if (_managerTakeoversFrozen) revert MANAGER_TAKEOVERS_FROZEN();

        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        // Call the interface method to change the manager
        // This function can only be called by the SuperGovernor and bypasses the timelock
        ISuperVaultAggregator(aggregator).changePrimaryManager(strategy, newManager, feeRecipient);
    }

    /// @inheritdoc ISuperGovernor
    function resetHighWaterMark(address strategy) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (strategy == address(0)) revert INVALID_ADDRESS();

        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperVaultAggregator(aggregator).resetHighWaterMark(strategy);
    }

    /// @inheritdoc ISuperGovernor
    function freezeManagerTakeover() external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (_managerTakeoversFrozen) revert MANAGER_TAKEOVERS_FROZEN();

        // Set frozen status to true (permanent, cannot be undone)
        _managerTakeoversFrozen = true;

        // Emit event for the frozen status
        emit ManagerTakeoversFrozen();
    }

    /// @inheritdoc ISuperGovernor
    function changeHooksRootUpdateTimelock(uint256 newTimelock) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        // Note: Zero timelock is intentionally allowed for SUPER_GOVERNOR_ROLE
        // to enable immediate hook updates in emergency situations
        // Call the SuperVaultAggregator to change the hooks root update timelock
        ISuperVaultAggregator(aggregator).setHooksRootUpdateTimelock(newTimelock);
    }

    /// @inheritdoc ISuperGovernor
    function proposeGlobalHooksRoot(bytes32 newRoot) external onlyRole(_GOVERNOR_ROLE) {
        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperVaultAggregator(aggregator).proposeGlobalHooksRoot(newRoot);
    }

    /// @inheritdoc ISuperGovernor
    function setGlobalHooksRootVetoStatus(bool vetoed) external onlyRole(_GUARDIAN_ROLE) {
        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperVaultAggregator(aggregator).setGlobalHooksRootVetoStatus(vetoed);
    }

    /// @inheritdoc ISuperGovernor
    function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) external onlyRole(_GUARDIAN_ROLE) {
        if (strategy == address(0)) revert INVALID_ADDRESS();

        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperVaultAggregator(aggregator).setStrategyHooksRootVetoStatus(strategy, vetoed);
    }

    /// @inheritdoc ISuperGovernor
    function setOracleMaxStaleness(uint256 newMaxStaleness) external onlyRole(_ORACLE_MANAGER_ROLE) {
        if (newMaxStaleness < _minStaleness) revert MAX_STALENESS_TOO_LOW();
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).setDefaultStaleness(newMaxStaleness);
    }

    /// @inheritdoc ISuperGovernor
    function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) external onlyRole(_ORACLE_MANAGER_ROLE) {
        if (feed == address(0)) revert INVALID_ADDRESS();
        if (newMaxStaleness < _minStaleness) revert MAX_STALENESS_TOO_LOW();
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).setFeedMaxStaleness(feed, newMaxStaleness);
    }

    /// @inheritdoc ISuperGovernor
    function setOracleFeedMaxStalenessBatch(
        address[] calldata feeds_,
        uint256[] calldata newMaxStalenessList_
    )
        external
        onlyRole(_ORACLE_MANAGER_ROLE)
    {
        // Validate all staleness values before proceeding
        for (uint256 i; i < newMaxStalenessList_.length; i++) {
            if (newMaxStalenessList_[i] < _minStaleness) revert MAX_STALENESS_TOO_LOW();
        }

        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).setFeedMaxStalenessBatch(feeds_, newMaxStalenessList_);
    }

    /// @inheritdoc ISuperGovernor
    function queueOracleUpdate(
        address[] calldata bases_,
        address[] calldata quotes_,
        bytes32[] calldata providers_,
        address[] calldata feeds_
    )
        external
        onlyRole(_ORACLE_MANAGER_ROLE)
    {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).queueOracleUpdate(bases_, quotes_, providers_, feeds_);
    }

    /// @inheritdoc ISuperGovernor
    function executeOracleUpdate() external onlyRole(_ORACLE_MANAGER_ROLE) {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).executeOracleUpdate();
    }

    /// @inheritdoc ISuperGovernor
    function queueOracleProviderRemoval(bytes32[] calldata providers) external onlyRole(_ORACLE_MANAGER_ROLE) {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).queueProviderRemoval(providers);
    }

    /// @inheritdoc ISuperGovernor
    function batchSetOracleUptimeFeed(
        address[] calldata dataOracles_,
        address[] calldata uptimeOracles_,
        uint256[] calldata gracePeriods_
    )
        external
        onlyRole(_ORACLE_MANAGER_ROLE)
    {
        address oracleL2 = _addressRegistry[SUPER_ORACLE];
        if (oracleL2 == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracleL2(oracleL2).batchSetUptimeFeed(dataOracles_, uptimeOracles_, gracePeriods_);
    }

    /*//////////////////////////////////////////////////////////////
                            HOOK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function registerHook(address hook) external onlyRole(_GOVERNOR_ROLE) {
        if (hook == address(0)) revert INVALID_ADDRESS();

        if (_registeredHooks.add(hook)) {
            emit HookApproved(hook);
        }
    }

    /// @inheritdoc ISuperGovernor
    function unregisterHook(address hook) external onlyRole(_GOVERNOR_ROLE) {
        if (_registeredHooks.remove(hook)) {
            // Clear merkle root data for the unregistered hook to prevent stale data
            delete superBankHooksMerkleRoots[hook];

            emit HookRemoved(hook);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        VALIDATOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    // version is provided as param and not incremented in the function to sync config versions across chains
    // offchainConfig is not stored and simply emitted to create source for offchain validators to sync on
    function setValidatorConfig(
        uint256 version,
        address[] calldata validators,
        bytes[] calldata validatorPublicKeys,
        uint256 quorum,
        bytes calldata offchainConfig
    )
        external
        onlyRole(_GOVERNOR_ROLE)
    {
        uint256 validatorsLength = validators.length;
        uint256 validatorPublicKeysLength = validatorPublicKeys.length;
        // Validate inputs
        if (validatorsLength == 0) revert EMPTY_VALIDATOR_ARRAY();
        if (validatorsLength != validatorPublicKeysLength) revert ARRAY_LENGTH_MISMATCH();
        if (quorum == 0 || quorum > validatorsLength) revert INVALID_QUORUM();

        // Clear existing validators
        _validatorConfig.validators.clear();

        // Add new validators and validate no duplicates
        for (uint256 i; i < validatorsLength; i++) {
            if (validators[i] == address(0)) revert INVALID_ADDRESS();
            if (!_validatorConfig.validators.add(validators[i])) revert VALIDATOR_ALREADY_REGISTERED();
        }

        // Update config tracking
        _validatorConfig.version = version;
        _validatorConfig.quorum = quorum;

        // Store public keys
        delete _validatorConfig.validatorPublicKeys;
        for (uint256 i; i < validatorPublicKeysLength; i++) {
            _validatorConfig.validatorPublicKeys.push(validatorPublicKeys[i]);
        }

        emit ValidatorConfigSet(_validatorConfig.version, validators, validatorPublicKeys, quorum, offchainConfig);
    }

    /*//////////////////////////////////////////////////////////////
                         PPS ORACLE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function setActivePPSOracle(address oracle) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (oracle == address(0)) revert INVALID_ADDRESS();

        // If this is the first oracle or replacing a zero oracle, set it immediately
        if (_activePPSOracle == address(0)) {
            _activePPSOracle = oracle;
            emit ActivePPSOracleSet(oracle);
        } else {
            // Otherwise require the timelock process
            revert MUST_USE_TIMELOCK_FOR_CHANGE();
        }
    }

    /// @inheritdoc ISuperGovernor
    function proposeActivePPSOracle(address oracle) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (oracle == address(0)) revert INVALID_ADDRESS();

        _proposedActivePPSOracle = oracle;
        _activePPSOracleEffectiveTime = block.timestamp + TIMELOCK;

        emit ActivePPSOracleProposed(oracle, _activePPSOracleEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function executeActivePPSOracleChange() external {
        if (_proposedActivePPSOracle == address(0)) revert NO_PROPOSED_PPS_ORACLE();

        if (block.timestamp < _activePPSOracleEffectiveTime) {
            revert TIMELOCK_NOT_EXPIRED();
        }

        address oldOracle = _activePPSOracle;
        _activePPSOracle = _proposedActivePPSOracle;

        // Reset proposal data
        _proposedActivePPSOracle = address(0);
        _activePPSOracleEffectiveTime = 0;

        emit ActivePPSOracleChanged(oldOracle, _activePPSOracle);
    }

    /// @inheritdoc ISuperGovernor
    function cancelOracleProviderRemoval() external onlyRole(_ORACLE_MANAGER_ROLE) {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).cancelProviderRemoval();
    }

    /// @inheritdoc ISuperGovernor
    function executeOracleProviderRemoval() external onlyRole(_ORACLE_MANAGER_ROLE) {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).executeProviderRemoval();
    }

    /*//////////////////////////////////////////////////////////////
                      REVENUE SHARE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function proposeFee(FeeType feeType, uint256 value) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (value > BPS_MAX) revert INVALID_FEE_VALUE();

        FeeData storage feeData = _feeData[feeType];
        // casting to 'uint128' is safe because value is validated to be <= BPS_MAX (10000)
        // forge-lint: disable-next-line(unsafe-typecast)
        feeData.proposedValue = uint128(value);
        feeData.effectiveTime = block.timestamp + TIMELOCK;

        emit FeeProposed(feeType, value, feeData.effectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function executeFeeUpdate(FeeType feeType) external {
        FeeData storage feeData = _feeData[feeType];
        uint256 effectiveTime = feeData.effectiveTime;
        if (effectiveTime == 0) revert NO_PROPOSED_FEE(feeType);
        if (block.timestamp < effectiveTime) {
            revert TIMELOCK_NOT_EXPIRED();
        }

        // Update the fee value from proposed
        feeData.value = feeData.proposedValue;

        // Reset proposal data
        feeData.proposedValue = 0;
        feeData.effectiveTime = 0;

        emit FeeUpdated(feeType, feeData.value);
    }

    /// @inheritdoc ISuperGovernor
    function executeUpkeepClaim(uint256 amount) external onlyRole(_GOVERNOR_ROLE) {
        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperVaultAggregator(aggregator).claimUpkeep(amount);
    }

    /*//////////////////////////////////////////////////////////////
                        UPKEEP COST MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function setGasInfo(address oracle, uint256 gasIncreasePerEntryBatch) external onlyRole(_GAS_MANAGER_ROLE) {
        if (oracle == address(0)) revert INVALID_ADDRESS();
        if (gasIncreasePerEntryBatch == 0) revert INVALID_GAS_INFO();

        _gasPerEntry[oracle] = gasIncreasePerEntryBatch;
        emit GasInfoSet(oracle, gasIncreasePerEntryBatch);
    }

    /// @inheritdoc ISuperGovernor
    /// @notice Proposes a change to the upkeep payments enabled status
    /// @param enabled The proposed new status for upkeep payments
    function proposeUpkeepPaymentsChange(bool enabled) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        _proposedUpkeepPaymentsEnabled = enabled;
        _upkeepPaymentsChangeEffectiveTime = block.timestamp + TIMELOCK;

        emit UpkeepPaymentsChangeProposed(enabled, _upkeepPaymentsChangeEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    /// @notice Executes a previously proposed change to upkeep payments status after timelock expires
    function executeUpkeepPaymentsChange() external {
        if (_upkeepPaymentsChangeEffectiveTime == 0) revert NO_PENDING_CHANGE();
        if (block.timestamp < _upkeepPaymentsChangeEffectiveTime) revert TIMELOCK_NOT_EXPIRED();

        _upkeepPaymentsEnabled = _proposedUpkeepPaymentsEnabled;
        _upkeepPaymentsChangeEffectiveTime = 0;
        _proposedUpkeepPaymentsEnabled = false;

        emit UpkeepPaymentsChanged(_upkeepPaymentsEnabled);
    }

    /*//////////////////////////////////////////////////////////////
                        MIN STALENESS MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function proposeMinStaleness(uint256 newMinStaleness) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        _proposedMinStaleness = newMinStaleness;
        _minStalenessEffectiveTime = block.timestamp + TIMELOCK;

        emit MinStalenessProposed(newMinStaleness, _minStalenessEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function executeMinStalenessChange() external {
        uint256 minStalenessEffectiveTime = _minStalenessEffectiveTime;
        if (minStalenessEffectiveTime == 0) revert NO_PROPOSED_MIN_STALENESS();
        if (block.timestamp < minStalenessEffectiveTime) revert TIMELOCK_NOT_EXPIRED();

        _minStaleness = _proposedMinStaleness;

        // Reset proposal data
        _proposedMinStaleness = 0;
        _minStalenessEffectiveTime = 0;

        emit MinStalenessChanged(_minStaleness);
    }

    /*//////////////////////////////////////////////////////////////
                           SUPERBANK HOOKS MGMT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function proposeSuperBankHookMerkleRoot(address hook, bytes32 proposedRoot) external onlyRole(_GOVERNOR_ROLE) {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        if (proposedRoot == bytes32(0)) revert ZERO_PROPOSED_MERKLE_ROOT();

        uint256 effectiveTime = block.timestamp + TIMELOCK;
        ISuperGovernor.HookMerkleRootData storage data = superBankHooksMerkleRoots[hook];
        data.proposedRoot = proposedRoot;
        data.effectiveTime = effectiveTime;

        emit SuperBankHookMerkleRootProposed(hook, proposedRoot, effectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function executeSuperBankHookMerkleRootUpdate(address hook) external {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();

        ISuperGovernor.HookMerkleRootData storage data = superBankHooksMerkleRoots[hook];

        // Check if there's a proposed update
        bytes32 proposedRoot = data.proposedRoot;
        if (proposedRoot == bytes32(0)) revert NO_PROPOSED_MERKLE_ROOT();

        // Check if the effective time has passed
        if (block.timestamp < data.effectiveTime) revert TIMELOCK_NOT_EXPIRED();

        // Update the Merkle root
        data.currentRoot = proposedRoot;

        // Reset the proposal
        data.proposedRoot = bytes32(0);
        data.effectiveTime = 0;

        emit SuperBankHookMerkleRootUpdated(hook, proposedRoot);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function SUPER_GOVERNOR_ROLE() external pure returns (bytes32) {
        return _SUPER_GOVERNOR_ROLE;
    }

    /// @inheritdoc ISuperGovernor
    function GOVERNOR_ROLE() external pure returns (bytes32) {
        return _GOVERNOR_ROLE;
    }

    /// @inheritdoc ISuperGovernor
    function BANK_MANAGER_ROLE() external pure returns (bytes32) {
        return _BANK_MANAGER_ROLE;
    }

    /// @inheritdoc ISuperGovernor
    function GAS_MANAGER_ROLE() external pure returns (bytes32) {
        return _GAS_MANAGER_ROLE;
    }

    /// @inheritdoc ISuperGovernor
    function ORACLE_MANAGER_ROLE() external pure returns (bytes32) {
        return _ORACLE_MANAGER_ROLE;
    }

    /// @inheritdoc ISuperGovernor
    function GUARDIAN_ROLE() external pure returns (bytes32) {
        return _GUARDIAN_ROLE;
    }

    /// @inheritdoc ISuperGovernor
    function getAddress(bytes32 key) external view returns (address) {
        address value = _addressRegistry[key];
        if (value == address(0)) revert CONTRACT_NOT_FOUND();
        return value;
    }

    /// @inheritdoc ISuperGovernor
    function isManagerTakeoverFrozen() external view returns (bool) {
        return _managerTakeoversFrozen;
    }

    /// @inheritdoc ISuperGovernor
    function isHookRegistered(address hook) external view returns (bool) {
        return _registeredHooks.contains(hook);
    }

    /// @inheritdoc ISuperGovernor
    function getRegisteredHooks() external view returns (address[] memory) {
        return _registeredHooks.values();
    }

    /// @inheritdoc ISuperGovernor
    function getValidatorConfig()
        external
        view
        returns (uint256 version, address[] memory validators, bytes[] memory validatorPublicKeys, uint256 quorum)
    {
        return (
            _validatorConfig.version,
            _validatorConfig.validators.values(),
            _validatorConfig.validatorPublicKeys,
            _validatorConfig.quorum
        );
    }

    /// @inheritdoc ISuperGovernor
    function isValidator(address validator) external view returns (bool) {
        return _validatorConfig.validators.contains(validator);
    }

    /// @inheritdoc ISuperGovernor
    function isGuardian(address guardian) external view returns (bool) {
        return hasRole(_GUARDIAN_ROLE, guardian);
    }

    /// @inheritdoc ISuperGovernor
    function getValidators() external view returns (address[] memory) {
        return _validatorConfig.validators.values();
    }

    /// @inheritdoc ISuperGovernor
    function getValidatorsCount() external view returns (uint256) {
        return _validatorConfig.validators.length();
    }

    /// @inheritdoc ISuperGovernor
    function getValidatorAt(uint256 index) external view returns (address) {
        return _validatorConfig.validators.at(index);
    }

    /// @inheritdoc ISuperGovernor
    function getProposedActivePPSOracle() external view returns (address proposedOracle, uint256 effectiveTime) {
        return (_proposedActivePPSOracle, _activePPSOracleEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function getPPSOracleQuorum() external view returns (uint256) {
        return _validatorConfig.quorum;
    }

    /// @inheritdoc ISuperGovernor
    function getActivePPSOracle() external view returns (address) {
        if (_activePPSOracle == address(0)) revert NO_ACTIVE_PPS_ORACLE();
        return _activePPSOracle;
    }

    /// @inheritdoc ISuperGovernor
    function isActivePPSOracle(address oracle) external view returns (bool) {
        return oracle == _activePPSOracle;
    }

    /// @inheritdoc ISuperGovernor
    function getFee(FeeType feeType) external view returns (uint256) {
        return _feeData[feeType].value;
    }

    /// @inheritdoc ISuperGovernor
    function getGasInfo(address oracle_) external view returns (uint256) {
        return _gasPerEntry[oracle_];
    }

    /// @inheritdoc ISuperGovernor
    function getUpkeepCostPerSingleUpdate(address oracle_) external view returns (uint256) {
        return _convertGasToUpkeepToken(_gasPerEntry[oracle_]);
    }

    /// @inheritdoc ISuperGovernor
    function getMinStaleness() external view returns (uint256) {
        return _minStaleness;
    }

    /// @inheritdoc ISuperGovernor
    function getProposedMinStaleness() external view returns (uint256 proposedMinStaleness, uint256 effectiveTime) {
        return (_proposedMinStaleness, _minStalenessEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function getSuperBankHookMerkleRoot(address hook) external view returns (bytes32) {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        return superBankHooksMerkleRoots[hook].currentRoot;
    }

    /// @inheritdoc ISuperGovernor
    function getProposedSuperBankHookMerkleRoot(address hook)
        external
        view
        returns (bytes32 proposedRoot, uint256 effectiveTime)
    {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        ISuperGovernor.HookMerkleRootData storage data = superBankHooksMerkleRoots[hook];
        return (data.proposedRoot, data.effectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function isUpkeepPaymentsEnabled() external view returns (bool enabled) {
        return _upkeepPaymentsEnabled;
    }

    /// @inheritdoc ISuperGovernor
    function getProposedUpkeepPaymentsStatus() external view returns (bool enabled, uint256 effectiveTime) {
        return (_proposedUpkeepPaymentsEnabled, _upkeepPaymentsChangeEffectiveTime);
    }

    /// @dev Advertise ISuperGovernor support for ERC-165 detection
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return interfaceId == type(ISuperGovernor).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Converts gas units to UPKEEP_TOKEN cost using multi-step oracle pricing
    /// @dev Performs 3 oracle conversions: Gas->Native, Native->USD, USD->UPKEEP_TOKEN
    /// @dev Uses AVERAGE_PROVIDER for all price feeds to ensure consistency
    /// @dev Uses Math.Rounding.Ceil to ensure sufficient upkeep coverage
    /// @dev Dynamically queries token decimals to support tokens with different decimal places (e.g., USDC=6, WETH=18)
    /// @param gasAmount The gas units to convert
    /// @return requiredUpkeepTokens The equivalent amount in UPKEEP_TOKEN (token's native decimals)
    function _convertGasToUpkeepToken(uint256 gasAmount) internal view returns (uint256) {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert SUPER_ORACLE_NOT_FOUND();
        address upkeepToken = _addressRegistry[UPKEEP_TOKEN];
        if (upkeepToken == address(0)) revert UPKEEP_TOKEN_NOT_FOUND();

        // Get the upkeep token's decimals dynamically
        uint8 tokenDecimals = IERC20Metadata(upkeepToken).decimals();
        uint256 tokenUnit = 10 ** tokenDecimals;

        // Step 1: convert gas to native token (wei)
        (uint256 weiAmount,,,) =
            ISuperOracle(oracle).getQuoteFromProvider(gasAmount, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);

        // Step 2: convert native token to USD
        (uint256 nativeToUsd,,,) =
            ISuperOracle(oracle).getQuoteFromProvider(weiAmount, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);

        // Step 3: convert USD to UPKEEP_TOKEN (how much USD per 1 UPKEEP_TOKEN)
        (uint256 usdPerUpkeepToken,,,) = ISuperOracle(oracle)
            .getQuoteFromProvider(
                tokenUnit, // 1 UPKEEP_TOKEN (using actual decimals)
                upkeepToken,
                USD_TOKEN,
                AVERAGE_PROVIDER
            );

        // Calculate required UPKEEP_TOKEN
        // (usdAmount * tokenUnit) / usdPerUpkeepToken = required UPKEEP_TOKEN
        // Simplifies to: usdAmount / (usdPerUpkeepToken / tokenUnit) = tokens needed
        return Math.mulDiv(nativeToUsd, tokenUnit, usdPerUpkeepToken, Math.Rounding.Ceil);
    }
}
