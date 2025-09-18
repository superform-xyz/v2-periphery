// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

// external
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

// Superform
import { ISuperGovernor, FeeType } from "./interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "./interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperAssetFactory } from "./interfaces/SuperAsset/ISuperAssetFactory.sol";
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
    // Active PPS Oracle quorum requirement
    uint256 private _activePPSOracleQuorum;
    // Current active PPS Oracle
    address private _activePPSOracle;
    // Proposed new active PPS Oracle
    address private _proposedActivePPSOracle;
    // Effective time for proposed active PPS Oracle change
    uint256 private _activePPSOracleEffectiveTime;

    // Hook registry
    EnumerableSet.AddressSet private _registeredHooks;
    EnumerableSet.AddressSet private _registeredFulfillRequestsHooks;

    // SuperBank Hook Target validation
    mapping(address hook => ISuperGovernor.HookMerkleRootData merkleData) private superBankHooksMerkleRoots;

    // VaultBank registry
    EnumerableSet.AddressSet private _vaultBanks;
    mapping(uint64 chainId => address vaultBank) private _vaultBanksByChainId;

    // VaultBank Hook Target validation
    mapping(address hook => ISuperGovernor.HookMerkleRootData merkleData) private vaultBankHooksMerkleRoots;

    // Global freeze for manager takeovers
    bool private _managerTakeoversFrozen;

    // Validator registry
    EnumerableSet.AddressSet private _validators;

    // Relayer registry
    EnumerableSet.AddressSet private _relayers;

    // Protected keepers registry (cannot be added as authorized callers by managers)
    EnumerableSet.AddressSet private _protectedKeepers;

    // Executor registry
    EnumerableSet.AddressSet private _executors;

    // Polymer prover
    address private _prover;

    // Whitelisted incentive tokens
    mapping(address token => bool isWhitelisted) private _isWhitelistedIncentiveToken;
    EnumerableSet.AddressSet private _proposedWhitelistedIncentiveTokens;
    EnumerableSet.AddressSet private _proposedRemoveWhitelistedIncentiveTokens;
    uint256 private _proposedAddWhitelistedIncentiveTokensEffectiveTime;
    uint256 private _proposedRemoveWhitelistedIncentiveTokensEffectiveTime;

    // Fee management
    // Current fee values
    mapping(FeeType type_ => uint256 value) private _feeValues;
    // Proposed fee values
    mapping(FeeType type_ => uint256 proposedValue) private _proposedFeeValues;
    // Effective times for proposed fee updates
    mapping(FeeType type_ => uint256 effectiveTime) private _feeEffectiveTimes;

    mapping(address _oracle => GasInfo info) private _oracleGasInfo;

    // Upkeep control
    bool private _upkeepPaymentsEnabled;
    bool private _proposedUpkeepPaymentsEnabled;
    uint256 private _upkeepPaymentsChangeEffectiveTime;

    // Superform managers (exempt from upkeep costs)
    EnumerableSet.AddressSet private _superformManagers;

    // Min staleness configuration to prevent maxStaleness from being set too low
    uint256 private _minStaleness;
    uint256 private _proposedMinStaleness;
    uint256 private _minStalenesEffectiveTime;

    // Oracle constants
    address private constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private constant USD_TOKEN = address(840);
    address private constant GAS_QUOTE =
        address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address private constant GWEI_QUOTE =
        address(uint160(uint256(keccak256("GWEI_QUOTE"))));
    bytes32 private constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // Timelock configuration
    uint256 private constant TIMELOCK = 7 days;
    uint256 private constant BPS_MAX = 10_000; // 100% in basis points

    // Role definitions
    bytes32 private constant _SUPER_GOVERNOR_ROLE = keccak256("SUPER_GOVERNOR_ROLE");
    bytes32 private constant _GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 private constant _BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");
    bytes32 private constant _GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 private constant _SUPER_ASSET_FACTORY = keccak256("SUPER_ASSET_FACTORY");
    bytes32 private constant _GAS_MANAGER_ROLE = keccak256("GAS_MANAGER_ROLE");

    // Common contract keys
    bytes32 public constant UP = keccak256("UP");
    bytes32 public constant SUP = keccak256("SUP");
    bytes32 public constant TREASURY = keccak256("TREASURY");
    bytes32 public constant VAULT_BANK = keccak256("VAULT_BANK");
    bytes32 public constant SUPER_BANK = keccak256("SUPER_BANK");
    bytes32 public constant SUPER_ORACLE = keccak256("SUPER_ORACLE");
    bytes32 public constant BANK_MANAGER = keccak256("BANK_MANAGER");
    bytes32 public constant ECDSAPPSORACLE = keccak256("ECDSAPPSORACLE");
    bytes32 public constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the SuperGovernor contract
    /// @param superGovernor Address of the default admin (will have SUPER_GOVERNOR_ROLE)
    /// @param governor Address that will have the GOVERNOR_ROLE for daily operations
    /// @param bankManager Address that will have the BANK_MANAGER_ROLE for daily operations
    /// @param treasury_ Address of the treasury
    /// @param prover_ Address of the prover
    constructor(address superGovernor, address governor, address bankManager, address gasManager, address treasury_, address prover_) {
        if (
            superGovernor == address(0) || treasury_ == address(0) || governor == address(0)
                || bankManager == address(0) || prover_ == address(0) || gasManager == address(0)
        ) revert INVALID_ADDRESS();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, superGovernor);
        _grantRole(_SUPER_GOVERNOR_ROLE, superGovernor);
        _grantRole(_GOVERNOR_ROLE, governor);
        _grantRole(_BANK_MANAGER_ROLE, bankManager);
        _grantRole(_GAS_MANAGER_ROLE, gasManager);
        // Setup GUARDIAN_ROLE without assigning any address
        _setRoleAdmin(_GUARDIAN_ROLE, DEFAULT_ADMIN_ROLE);

        // Set role admins
        _setRoleAdmin(_GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_SUPER_GOVERNOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_BANK_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_GAS_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);

        // Initialize with default fees
        _feeValues[FeeType.REVENUE_SHARE] = 2000; // 20% revenue share
        _feeValues[FeeType.SUPER_VAULT_PERFORMANCE_FEE] = 2000; // 20% performance fee
        _feeValues[FeeType.SUPER_ASSET_SWAP_FEE] = 4000; // 40% swap fee
        emit FeeUpdated(FeeType.REVENUE_SHARE, _feeValues[FeeType.REVENUE_SHARE]);
        emit FeeUpdated(FeeType.SUPER_VAULT_PERFORMANCE_FEE, _feeValues[FeeType.SUPER_VAULT_PERFORMANCE_FEE]);
        emit FeeUpdated(FeeType.SUPER_ASSET_SWAP_FEE, _feeValues[FeeType.SUPER_ASSET_SWAP_FEE]);

        // Set treasury in address registry
        _addressRegistry[TREASURY] = treasury_;
        emit AddressSet(TREASURY, treasury_);

        // Initialize minimum staleness (5 minutes to prevent extremely low staleness values)
        _minStaleness = 300; // 5 minutes in seconds

        // Initialize prover
        _prover = prover_;
        emit ProverSet(prover_);
    }

    /*//////////////////////////////////////////////////////////////
                       CONTRACT REGISTRY FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function setAddress(bytes32 key, address value) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (value == address(0)) revert INVALID_ADDRESS();

        _addressRegistry[key] = value;
        emit AddressSet(key, value);
    }

    /*//////////////////////////////////////////////////////////////
                    PERIPHERY CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function setProver(address prover) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (prover == address(0)) revert INVALID_ADDRESS();

        _prover = prover;
        emit ProverSet(prover);
    }

    /// @inheritdoc ISuperGovernor
    function changePrimaryManager(address strategy, address newManager) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        // Check if takeovers are globally frozen
        if (_managerTakeoversFrozen) revert MANAGER_TAKEOVERS_FROZEN();

        address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
        if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

        // Call the interface method to change the manager
        // This function can only be called by the SuperGovernor and bypasses the timelock
        ISuperVaultAggregator(aggregator).changePrimaryManager(strategy, newManager);
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
    function setSuperAssetManager(address superAsset, address superAssetManager) external onlyRole(_GOVERNOR_ROLE) {
        if (superAsset == address(0) || superAssetManager == address(0)) revert INVALID_ADDRESS();
        address value = _addressRegistry[_SUPER_ASSET_FACTORY];
        if (value == address(0)) revert CONTRACT_NOT_FOUND();
        ISuperAssetFactory factory = ISuperAssetFactory(value);
        factory.setSuperAssetManager(superAsset, superAssetManager);
    }

    /// @inheritdoc ISuperGovernor
    function addICCToWhitelist(address icc) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (icc == address(0)) revert INVALID_ADDRESS();
        address value = _addressRegistry[_SUPER_ASSET_FACTORY];
        if (value == address(0)) revert CONTRACT_NOT_FOUND();
        ISuperAssetFactory factory = ISuperAssetFactory(value);
        factory.addICCToWhitelist(icc);
    }

    /// @inheritdoc ISuperGovernor
    function removeICCFromWhitelist(address icc) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (icc == address(0)) revert INVALID_ADDRESS();
        address value = _addressRegistry[_SUPER_ASSET_FACTORY];
        if (value == address(0)) revert CONTRACT_NOT_FOUND();
        ISuperAssetFactory factory = ISuperAssetFactory(value);
        factory.removeICCFromWhitelist(icc);
    }

    /// @inheritdoc ISuperGovernor
    function setOracleMaxStaleness(uint256 newMaxStaleness) external onlyRole(_GOVERNOR_ROLE) {
        if (newMaxStaleness < _minStaleness) revert MAX_STALENESS_TOO_LOW();
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).setMaxStaleness(newMaxStaleness);
    }

    /// @inheritdoc ISuperGovernor
    function setOracleFeedMaxStaleness(address feed, uint256 newMaxStaleness) external onlyRole(_GOVERNOR_ROLE) {
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
        onlyRole(_GOVERNOR_ROLE)
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
        onlyRole(_GOVERNOR_ROLE)
    {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).queueOracleUpdate(bases_, quotes_, providers_, feeds_);
    }

    /// @inheritdoc ISuperGovernor
    function queueOracleProviderRemoval(bytes32[] calldata providers) external onlyRole(_GOVERNOR_ROLE) {
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
        onlyRole(_GOVERNOR_ROLE)
    {
        address oracleL2 = _addressRegistry[SUPER_ORACLE];
        if (oracleL2 == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracleL2(oracleL2).batchSetUptimeFeed(dataOracles_, uptimeOracles_, gracePeriods_);
    }

    /// @inheritdoc ISuperGovernor
    function setEmergencyPrice(address token, uint256 price) external onlyRole(_GOVERNOR_ROLE) {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).setEmergencyPrice(token, price);
    }

    /// @inheritdoc ISuperGovernor
    function batchSetEmergencyPrices(
        address[] calldata tokens_,
        uint256[] calldata prices_
    )
        external
        onlyRole(_GOVERNOR_ROLE)
    {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert CONTRACT_NOT_FOUND();

        ISuperOracle(oracle).batchSetEmergencyPrice(tokens_, prices_);
    }

    /*//////////////////////////////////////////////////////////////
                            HOOK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function registerHook(address hook, bool isFulfillRequestsHook) external onlyRole(_GOVERNOR_ROLE) {
        if (hook == address(0)) revert INVALID_ADDRESS();

        if (isFulfillRequestsHook && _registeredFulfillRequestsHooks.add(hook)) {
            emit FulfillRequestsHookRegistered(hook);
        }
        if (_registeredHooks.add(hook)) {
            emit HookApproved(hook);
        }
    }

    /// @inheritdoc ISuperGovernor
    function unregisterHook(address hook) external onlyRole(_GOVERNOR_ROLE) {
        if (_registeredFulfillRequestsHooks.remove(hook)) {
            emit FulfillRequestsHookUnregistered(hook);
        }
        if (_registeredHooks.remove(hook)) {
            // Clear merkle root data for the unregistered hook to prevent stale data
            delete superBankHooksMerkleRoots[hook];
            delete vaultBankHooksMerkleRoots[hook];

            emit HookRemoved(hook);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXECUTORS MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function addExecutor(address executor) external onlyRole(_GOVERNOR_ROLE) {
        if (executor == address(0)) revert INVALID_ADDRESS();
        if (!_executors.add(executor)) revert EXECUTOR_ALREADY_REGISTERED();

        emit ExecutorAdded(executor);
    }

    /// @inheritdoc ISuperGovernor
    function removeExecutor(address executor) external onlyRole(_GOVERNOR_ROLE) {
        if (!_executors.remove(executor)) revert EXECUTOR_NOT_REGISTERED();

        emit ExecutorRemoved(executor);
    }

    /*//////////////////////////////////////////////////////////////
                          RELAYER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function addRelayer(address relayer) external onlyRole(_GOVERNOR_ROLE) {
        if (relayer == address(0)) revert INVALID_ADDRESS();
        if (!_relayers.add(relayer)) revert RELAYER_ALREADY_REGISTERED();

        emit RelayerAdded(relayer);
    }

    /// @inheritdoc ISuperGovernor
    function removeRelayer(address relayer) external onlyRole(_GOVERNOR_ROLE) {
        if (!_relayers.remove(relayer)) revert RELAYER_NOT_REGISTERED();

        emit RelayerRemoved(relayer);
    }

    /*//////////////////////////////////////////////////////////////
                        VALIDATOR MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function addValidator(address validator) external onlyRole(_GOVERNOR_ROLE) {
        if (validator == address(0)) revert INVALID_ADDRESS();
        if (!_validators.add(validator)) revert VALIDATOR_ALREADY_REGISTERED();

        emit ValidatorAdded(validator);
    }

    /// @inheritdoc ISuperGovernor
    function removeValidator(address validator) external onlyRole(_GOVERNOR_ROLE) {
        if (!_validators.remove(validator)) revert VALIDATOR_NOT_REGISTERED();

        emit ValidatorRemoved(validator);
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
    function setPPSOracleQuorum(uint256 quorum) external onlyRole(_GOVERNOR_ROLE) {
        if (quorum == 0) revert INVALID_QUORUM();

        _activePPSOracleQuorum = quorum;
        emit PPSOracleQuorumUpdated(quorum);
    }

    /*//////////////////////////////////////////////////////////////
                      REVENUE SHARE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function proposeFee(FeeType feeType, uint256 value) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        if (value > BPS_MAX) revert INVALID_FEE_VALUE();

        _proposedFeeValues[feeType] = value;
        _feeEffectiveTimes[feeType] = block.timestamp + TIMELOCK;

        emit FeeProposed(feeType, value, _feeEffectiveTimes[feeType]);
    }

    /// @inheritdoc ISuperGovernor
    function executeFeeUpdate(FeeType feeType) external {
        uint256 effectiveTime = _feeEffectiveTimes[feeType];
        if (effectiveTime == 0) revert NO_PROPOSED_FEE(feeType);
        if (block.timestamp < effectiveTime) {
            revert TIMELOCK_NOT_EXPIRED();
        }

        // Update the fee value
        _feeValues[feeType] = _proposedFeeValues[feeType];

        // Reset proposal data
        delete _proposedFeeValues[feeType];
        delete _feeEffectiveTimes[feeType];

        emit FeeUpdated(feeType, _feeValues[feeType]);
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
    function setGasInfo(address oracle, uint256 baseGasBatch, uint256 gasIncreasePerEntryBatch) external onlyRole(_GAS_MANAGER_ROLE) {
        if (oracle == address(0)) revert INVALID_ADDRESS();
        if (baseGasBatch == 0 || gasIncreasePerEntryBatch == 0) revert INVALID_GAS_INFO();

        _oracleGasInfo[oracle] = GasInfo({baseGasBatch: baseGasBatch, gasIncreasePerEntryBatch: gasIncreasePerEntryBatch});
        emit GasInfoSet(oracle, baseGasBatch, gasIncreasePerEntryBatch);
    }

    /// @notice Proposes a change to the upkeep payments enabled status
    /// @param enabled The proposed new status for upkeep payments
    function proposeUpkeepPaymentsChange(bool enabled) external onlyRole(_SUPER_GOVERNOR_ROLE) {
        _proposedUpkeepPaymentsEnabled = enabled;
        _upkeepPaymentsChangeEffectiveTime = block.timestamp + TIMELOCK;

        emit UpkeepPaymentsChangeProposed(enabled, _upkeepPaymentsChangeEffectiveTime);
    }

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
        _minStalenesEffectiveTime = block.timestamp + TIMELOCK;

        emit MinStalenesProposed(newMinStaleness, _minStalenesEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function executeMinStalenesChange() external {
        uint256 minStalenesEffectiveTime = _minStalenesEffectiveTime;
        if (minStalenesEffectiveTime == 0) revert NO_PROPOSED_MIN_STALENESS();
        if (block.timestamp < minStalenesEffectiveTime) revert TIMELOCK_NOT_EXPIRED();

        _minStaleness = _proposedMinStaleness;

        // Reset proposal data
        _proposedMinStaleness = 0;
        _minStalenesEffectiveTime = 0;

        emit MinStalenesChanged(_minStaleness);
    }

    /*//////////////////////////////////////////////////////////////
                      SUPERFORM MANAGER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function addSuperformManager(address manager) external onlyRole(_GOVERNOR_ROLE) {
        if (manager == address(0)) revert INVALID_ADDRESS();
        if (!_superformManagers.add(manager)) revert MANAGER_ALREADY_REGISTERED();

        emit SuperformManagerAdded(manager);
    }

    /// @inheritdoc ISuperGovernor
    function removeSuperformManager(address manager) external onlyRole(_GOVERNOR_ROLE) {
        if (!_superformManagers.remove(manager)) revert MANAGER_NOT_REGISTERED();

        emit SuperformManagerRemoved(manager);
    }

    /*//////////////////////////////////////////////////////////////
                           VAULT HOOKS MGMT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperGovernor
    function proposeVaultBankHookMerkleRoot(address hook, bytes32 proposedRoot) external onlyRole(_GOVERNOR_ROLE) {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        if (proposedRoot == bytes32(0)) revert ZERO_PROPOSED_MERKLE_ROOT();

        uint256 effectiveTime = block.timestamp + TIMELOCK;
        ISuperGovernor.HookMerkleRootData storage data = vaultBankHooksMerkleRoots[hook];
        data.proposedRoot = proposedRoot;
        data.effectiveTime = effectiveTime;

        emit VaultBankHookMerkleRootProposed(hook, proposedRoot, effectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function executeVaultBankHookMerkleRootUpdate(address hook) external {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();

        ISuperGovernor.HookMerkleRootData storage data = vaultBankHooksMerkleRoots[hook];

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

        emit VaultBankHookMerkleRootUpdated(hook, proposedRoot);
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
                        VAULT BANK MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function addVaultBank(uint64 chainId, address vaultBank) external onlyRole(_GOVERNOR_ROLE) {
        if (chainId == 0) revert INVALID_CHAIN_ID();
        if (vaultBank == address(0)) revert INVALID_ADDRESS();

        if (_vaultBanksByChainId[chainId] != address(0)) {
            _vaultBanks.remove(_vaultBanksByChainId[chainId]);
        }

        _vaultBanks.add(vaultBank);
        _vaultBanksByChainId[chainId] = vaultBank;

        emit VaultBankAddressAdded(chainId, vaultBank);
    }

    /// @inheritdoc ISuperGovernor
    function getVaultBank(uint64 chainId) external view returns (address) {
        return _vaultBanksByChainId[chainId];
    }

    /*//////////////////////////////////////////////////////////////
                      INCENTIVE TOKEN MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperGovernor
    function proposeAddIncentiveTokens(address[] memory tokens) external onlyRole(_GOVERNOR_ROLE) {
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == address(0)) revert INVALID_ADDRESS();
            _proposedWhitelistedIncentiveTokens.add(tokens[i]);
        }

        _proposedAddWhitelistedIncentiveTokensEffectiveTime = block.timestamp + TIMELOCK;

        emit WhitelistedIncentiveTokensProposed(
            _proposedWhitelistedIncentiveTokens.values(), _proposedAddWhitelistedIncentiveTokensEffectiveTime
        );
    }

    /// @inheritdoc ISuperGovernor
    function executeAddIncentiveTokens() external {
        if (
            _proposedAddWhitelistedIncentiveTokensEffectiveTime == 0
                || block.timestamp < _proposedAddWhitelistedIncentiveTokensEffectiveTime
        ) revert TIMELOCK_NOT_EXPIRED();

        // Get all proposed tokens before modifying the set
        address[] memory tokensToAdd = _proposedWhitelistedIncentiveTokens.values();
        uint256 len = tokensToAdd.length;
        address token;
        for (uint256 i; i < len; i++) {
            token = tokensToAdd[i];
            _isWhitelistedIncentiveToken[token] = true;
            // Remove from proposed whitelisted tokens
            _proposedWhitelistedIncentiveTokens.remove(token);
        }

        // Emit event once with all tokens
        emit WhitelistedIncentiveTokensAdded(tokensToAdd);

        // Reset proposal timestamp
        _proposedAddWhitelistedIncentiveTokensEffectiveTime = 0;
    }

    /// @inheritdoc ISuperGovernor
    function proposeRemoveIncentiveTokens(address[] memory tokens) external onlyRole(_GOVERNOR_ROLE) {
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] == address(0)) revert INVALID_ADDRESS();
            if (!_isWhitelistedIncentiveToken[tokens[i]]) revert NOT_WHITELISTED_INCENTIVE_TOKEN();

            _proposedRemoveWhitelistedIncentiveTokens.add(tokens[i]);
        }

        _proposedRemoveWhitelistedIncentiveTokensEffectiveTime = block.timestamp + TIMELOCK;

        emit WhitelistedIncentiveTokensProposed(
            _proposedRemoveWhitelistedIncentiveTokens.values(), _proposedRemoveWhitelistedIncentiveTokensEffectiveTime
        );
    }

    /// @inheritdoc ISuperGovernor
    function executeRemoveIncentiveTokens() external {
        if (
            _proposedRemoveWhitelistedIncentiveTokensEffectiveTime == 0
                || block.timestamp < _proposedRemoveWhitelistedIncentiveTokensEffectiveTime
        ) revert TIMELOCK_NOT_EXPIRED();

        // Get all proposed tokens before modifying the set
        address[] memory tokensToRemove = _proposedRemoveWhitelistedIncentiveTokens.values();
        uint256 len = tokensToRemove.length;
        address token;
        for (uint256 i; i < len; i++) {
            token = tokensToRemove[i];
            if (_isWhitelistedIncentiveToken[token]) {
                _isWhitelistedIncentiveToken[token] = false;
            }
            // Remove from proposed whitelisted tokens to be removed
            _proposedRemoveWhitelistedIncentiveTokens.remove(token);
        }

        // Emit event once with all tokens
        emit WhitelistedIncentiveTokensRemoved(tokensToRemove);

        // Reset proposal timestamp
        _proposedRemoveWhitelistedIncentiveTokensEffectiveTime = 0;
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
    function GUARDIAN_ROLE() external pure returns (bytes32) {
        return _GUARDIAN_ROLE;
    }

    /// @inheritdoc ISuperGovernor
    function SUPER_ASSET_FACTORY() external pure returns (bytes32) {
        return _SUPER_ASSET_FACTORY;
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
    function isFulfillRequestsHookRegistered(address hook) external view returns (bool) {
        return _registeredFulfillRequestsHooks.contains(hook);
    }

    /// @inheritdoc ISuperGovernor
    function getRegisteredHooks() external view returns (address[] memory) {
        return _registeredHooks.values();
    }

    /// @inheritdoc ISuperGovernor
    function getRegisteredFulfillRequestsHooks() external view returns (address[] memory) {
        return _registeredFulfillRequestsHooks.values();
    }

    /// @inheritdoc ISuperGovernor
    function isValidator(address validator) external view returns (bool) {
        return _validators.contains(validator);
    }

    /// @inheritdoc ISuperGovernor
    function isGuardian(address guardian) external view returns (bool) {
        return hasRole(_GUARDIAN_ROLE, guardian);
    }

    /// @inheritdoc ISuperGovernor
    function isRelayer(address relayer) external view returns (bool) {
        return _relayers.contains(relayer);
    }

    /// @inheritdoc ISuperGovernor
    function isExecutor(address executor) external view returns (bool) {
        return _executors.contains(executor);
    }

    /// @inheritdoc ISuperGovernor
    function getValidators() external view returns (address[] memory) {
        return _validators.values();
    }

    /// @inheritdoc ISuperGovernor
    function getRelayers() external view returns (address[] memory) {
        return _relayers.values();
    }

    /// @inheritdoc ISuperGovernor
    function getExecutors() external view returns (address[] memory) {
        return _executors.values();
    }

    /// @inheritdoc ISuperGovernor
    function getProposedActivePPSOracle() external view returns (address proposedOracle, uint256 effectiveTime) {
        return (_proposedActivePPSOracle, _activePPSOracleEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function getPPSOracleQuorum() external view returns (uint256) {
        return _activePPSOracleQuorum;
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
        return _feeValues[feeType];
    }

    /// @inheritdoc ISuperGovernor
    function getGasInfo(address oracle_) external view returns (GasInfo memory) {
        return _oracleGasInfo[oracle_];
    }

     /// @inheritdoc ISuperGovernor
    function getUpkeepCostPerBatchUpdate(address oracle_, uint256 chargeableEntries_) external view returns (uint256) {
        // Calculate total gas cost
        uint256 totalGas = _oracleGasInfo[oracle_].baseGasBatch + 
            (_oracleGasInfo[oracle_].gasIncreasePerEntryBatch * chargeableEntries_);

        return _convertGasToUp(totalGas);
    }

    /// @inheritdoc ISuperGovernor
    function getMinStaleness() external view returns (uint256) {
        return _minStaleness;
    }

    /// @inheritdoc ISuperGovernor
    function getProposedMinStaleness() external view returns (uint256 proposedMinStaleness, uint256 effectiveTime) {
        return (_proposedMinStaleness, _minStalenesEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function getSuperBankHookMerkleRoot(address hook) external view returns (bytes32) {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        return superBankHooksMerkleRoots[hook].currentRoot;
    }

    /// @inheritdoc ISuperGovernor
    function getVaultBankHookMerkleRoot(address hook) external view returns (bytes32) {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        return vaultBankHooksMerkleRoots[hook].currentRoot;
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
    function getProposedVaultBankHookMerkleRoot(address hook)
        external
        view
        returns (bytes32 proposedRoot, uint256 effectiveTime)
    {
        if (!_registeredHooks.contains(hook)) revert HOOK_NOT_APPROVED();
        ISuperGovernor.HookMerkleRootData storage data = vaultBankHooksMerkleRoots[hook];
        return (data.proposedRoot, data.effectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function getProver() external view returns (address) {
        return _prover;
    }

    /// @inheritdoc ISuperGovernor
    function isUpkeepPaymentsEnabled() external view returns (bool enabled) {
        return _upkeepPaymentsEnabled;
    }

    /// @inheritdoc ISuperGovernor
    function getProposedUpkeepPaymentsStatus() external view returns (bool enabled, uint256 effectiveTime) {
        return (_proposedUpkeepPaymentsEnabled, _upkeepPaymentsChangeEffectiveTime);
    }

    /// @inheritdoc ISuperGovernor
    function isSuperformManager(address manager) external view returns (bool isSuperform) {
        return _superformManagers.contains(manager);
    }

    /// @inheritdoc ISuperGovernor
    function getAllSuperformManagers() external view returns (address[] memory managers) {
        return _superformManagers.values();
    }

    /// @inheritdoc ISuperGovernor
    function getManagersPaginated(
        uint256 cursor,
        uint256 limit
    )
        external
        view
        returns (address[] memory chunkOfManagers, uint256 next)
    {
        uint256 len = _superformManagers.length();

        // clamp limit so we don’t read past end
        uint256 realLimit = limit;
        // If cursor is beyond the end, return empty array
        if (cursor >= len) {
            return (new address[](0), 0);
        }

        uint256 remaining = len - cursor;
        if (realLimit > remaining) realLimit = remaining;

        chunkOfManagers = new address[](realLimit);
        for (uint256 i; i < realLimit; ++i) {
            chunkOfManagers[i] = _superformManagers.at(cursor + i);
        }

        next = (cursor + realLimit < len) ? cursor + realLimit : 0;
    }

    /// @inheritdoc ISuperGovernor
    function getSuperformManagersCount() external view returns (uint256) {
        return _superformManagers.length();
    }

    /// @inheritdoc ISuperGovernor
    function isWhitelistedIncentiveToken(address token) external view returns (bool) {
        return _isWhitelistedIncentiveToken[token];
    }

    /// @inheritdoc ISuperGovernor
    function registerProtectedKeeper(address keeper) external onlyRole(_GOVERNOR_ROLE) {
        if (keeper == address(0)) revert INVALID_ADDRESS();
        if (_protectedKeepers.contains(keeper)) revert KEEPER_ALREADY_REGISTERED();

        _protectedKeepers.add(keeper);
        emit ProtectedKeeperRegistered(keeper);
    }

    /// @inheritdoc ISuperGovernor
    function unregisterProtectedKeeper(address keeper) external onlyRole(_GOVERNOR_ROLE) {
        if (!_protectedKeepers.contains(keeper)) revert KEEPER_NOT_REGISTERED();

        _protectedKeepers.remove(keeper);
        emit ProtectedKeeperUnregistered(keeper);
    }

    /// @inheritdoc ISuperGovernor
    function isProtectedKeeper(address keeper) external view returns (bool) {
        return _protectedKeepers.contains(keeper);
    }

    /// @inheritdoc ISuperGovernor
    function getProtectedKeepers() external view returns (address[] memory) {
        return _protectedKeepers.values();
    }

    /// @inheritdoc ISuperGovernor
    function getProtectedKeepersCount() external view returns (uint256) {
        return _protectedKeepers.length();
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _convertGasToUp(uint256 gasAmount) internal view returns (uint256) {
        address oracle = _addressRegistry[SUPER_ORACLE];
        if (oracle == address(0)) revert SUPER_ORACLE_NOT_FOUND();
        address upToken = _addressRegistry[UP];
        if (upToken == address(0)) revert UP_NOT_FOUND();

        // Step 1: convert gas to ETH
        (uint256 ethAmount,,,) = ISuperOracle(oracle).getQuoteFromProvider(
            gasAmount,
            GAS_QUOTE,
            GWEI_QUOTE,
            AVERAGE_PROVIDER
        );

        // Step 2: convert ETH to USD
        (uint256 ethToUsd,,,) = ISuperOracle(oracle).getQuoteFromProvider(
            ethAmount,
            NATIVE_TOKEN,
            USD_TOKEN,
            AVERAGE_PROVIDER
        );

        // Step 3: convert USD to UP (how much USD per UP token)
        (uint256 upPerUsd,,,) = ISuperOracle(oracle).getQuoteFromProvider(
            1e18, // 1 UP token (18 decimals)
            upToken,
            USD_TOKEN,
            AVERAGE_PROVIDER
        );

        // Calculate required UP tokens
        // usdAmount / upPerUsd = required UP tokens
        uint256 requiredUpTokens = Math.mulDiv(ethToUsd, 1e18, upPerUsd, Math.Rounding.Ceil);
        return requiredUpTokens;
    }
}
