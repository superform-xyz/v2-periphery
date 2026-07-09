// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

// Superform
import { ManagedSuperVault } from "./ManagedSuperVault.sol";
import { ManagedSuperVaultStrategy } from "./ManagedSuperVaultStrategy.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../SuperVault/SuperVaultEscrow.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { IManagedSuperVaultAggregator } from "../interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedNAVOracle } from "../interfaces/ManagedSuperVault/IManagedNAVOracle.sol";
import { IManagedSuperVaultDepositQueue } from "../interfaces/ManagedSuperVault/IManagedSuperVaultDepositQueue.sol";
// Libraries
import { AssetMetadataLib } from "../libraries/AssetMetadataLib.sol";

/// @title ManagedSuperVaultAggregator
/// @author Superform Labs
/// @notice Registry and attested-PPS sink for all Managed SuperVaults
/// @dev Fork of SuperVaultAggregator — review by diffing against src/SuperVault/SuperVaultAggregator.sol.
///      Managed diffs: (1) PPS pushed by a manual-NAV attestation oracle (timelocked swap) instead of the
///      SuperGovernor's active PPS oracle; (2) upkeep subsystem removed; (3) governance functions gated by
///      SuperGovernor roles (the deployed SuperGovernor only drives the main-family aggregator);
///      (4) createVault clones a 4th contract, the deposit queue, and registers the vault's NAV attestation
///      config atomically. Sync deposits on managed vaults are gated to the queue (see ManagedSuperVault).
contract ManagedSuperVaultAggregator is IManagedSuperVaultAggregator {
    using AssetMetadataLib for address;
    using Clones for address;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    // Vault implementation contracts
    address public immutable VAULT_IMPLEMENTATION;
    address public immutable STRATEGY_IMPLEMENTATION;
    address public immutable ESCROW_IMPLEMENTATION;
    address public immutable QUEUE_IMPLEMENTATION;

    // Governance
    ISuperGovernor public immutable SUPER_GOVERNOR;

    // Manual-NAV attestation oracle authorized to push PPS for this aggregator's strategies.
    // Managed replacement for SuperGovernor's (singleton, validator-fed) active PPS oracle.
    address public navOracle;
    address public proposedNavOracle;
    uint256 public navOracleEffectiveTime;

    // Strategy data storage
    mapping(address strategy => StrategyData) private _strategyData;

    // Registry of created vaults
    EnumerableSet.AddressSet private _superVaults;
    EnumerableSet.AddressSet private _superVaultStrategies;
    EnumerableSet.AddressSet private _superVaultEscrows;
    EnumerableSet.AddressSet private _depositQueues;

    // Deposit queue lookup by vault
    mapping(address vault => address queue) private _depositQueueByVault;

    // Constant for basis points precision (100% = 10,000 bps)
    uint256 private constant BPS_PRECISION = 10_000;

    // Maximum performance fee allowed (51%)
    uint256 private constant MAX_PERFORMANCE_FEE = 5100;

    // Maximum number of secondary managers per strategy to prevent governance DoS on manager replacement
    uint256 public constant MAX_SECONDARY_MANAGERS = 5;

    // Default deviation threshold for new strategies (50% in 1e18 scale)
    uint256 private constant DEFAULT_DEVIATION_THRESHOLD = 5e17;

    // Maximum deviation threshold (100% in 1e18 scale) — the deviation check cannot be disabled
    uint256 private constant MAX_DEVIATION_THRESHOLD = 1e18;

    // Timelock for NAV oracle changes (mirrors SuperGovernor's active-PPS-oracle timelock)
    uint256 public constant NAV_ORACLE_CHANGE_TIMELOCK = 7 days;

    // SuperGovernor roles authorized for governance functions on this aggregator.
    // The deployed SuperGovernor contract only drives the aggregator registered at its main
    // SUPER_VAULT_AGGREGATOR key, so this fork gates on role-holders calling directly instead.
    bytes32 private constant _SUPER_GOVERNOR_ROLE = keccak256("SUPER_GOVERNOR_ROLE");
    bytes32 private constant _GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 private constant _GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    // Timelock for manager changes and Merkle root updates
    uint256 private constant _MANAGER_CHANGE_TIMELOCK = 7 days;
    uint256 private _hooksRootUpdateTimelock = 15 minutes;

    // Timelock for parameter changes (3 days)
    uint256 private constant _PARAMETER_CHANGE_TIMELOCK = 3 days;

    // Global hooks Merkle root data
    bytes32 private _globalHooksRoot;
    bytes32 private _proposedGlobalHooksRoot;
    uint256 private _globalHooksRootEffectiveTime;
    bool private _globalHooksRootVetoed;

    // Nonce for vault creation tracking
    uint256 private _vaultCreationNonce;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Validates that msg.sender is the active PPS Oracle
    modifier onlyPPSOracle() {
        _onlyPPSOracle();
        _;
    }

    function _onlyPPSOracle() internal view {
        if (msg.sender != navOracle) {
            revert UNAUTHORIZED_PPS_ORACLE();
        }
    }

    /// @notice Validates that msg.sender holds the given SuperGovernor role
    function _requireRole(bytes32 role) internal view {
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(role, msg.sender)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }
    }

    /// @notice Validates that a strategy exists (has been created by this aggregator)
    modifier validStrategy(address strategy) {
        _validStrategy(strategy);
        _;
    }

    function _validStrategy(address strategy) internal view {
        if (!_superVaultStrategies.contains(strategy)) revert UNKNOWN_STRATEGY();
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the ManagedSuperVaultAggregator
    /// @param superGovernor_ Address of the SuperGovernor contract
    /// @param vaultImpl_ Address of the pre-deployed ManagedSuperVault implementation
    /// @param strategyImpl_ Address of the pre-deployed ManagedSuperVaultStrategy implementation
    /// @param escrowImpl_ Address of the pre-deployed SuperVaultEscrow implementation (reused from the main family)
    /// @param queueImpl_ Address of the pre-deployed ManagedSuperVaultDepositQueue implementation
    /// @dev The NAV oracle is NOT a constructor arg: the oracle's constructor takes this aggregator's
    ///      address, so mutual CREATE2 constructor args would be circular. It is wired post-deploy via
    ///      setInitialNavOracle (first-set immediate, mirroring SuperGovernor.setActivePPSOracle); the
    ///      family is inert (forwardPPS and createVault revert) until then.
    constructor(
        address superGovernor_,
        address vaultImpl_,
        address strategyImpl_,
        address escrowImpl_,
        address queueImpl_
    ) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        if (vaultImpl_ == address(0)) revert ZERO_ADDRESS();
        if (strategyImpl_ == address(0)) revert ZERO_ADDRESS();
        if (escrowImpl_ == address(0)) revert ZERO_ADDRESS();
        if (queueImpl_ == address(0)) revert ZERO_ADDRESS();

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        VAULT_IMPLEMENTATION = vaultImpl_;
        STRATEGY_IMPLEMENTATION = strategyImpl_;
        ESCROW_IMPLEMENTATION = escrowImpl_;
        QUEUE_IMPLEMENTATION = queueImpl_;
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT CREATION
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function createVault(VaultCreationParams calldata params)
        external
        returns (address superVault, address strategy, address escrow, address depositQueue)
    {
        // Input validation
        if (params.asset == address(0) || params.mainManager == address(0) || params.feeConfig.recipient == address(0))
        {
            revert ZERO_ADDRESS();
        }

        /// @dev Check that name and symbol are not empty
        ///      We don't check for anything else and
        ///       it's up to the creator to ensure that the vault
        ///       is created with valid parameters
        if (bytes(params.name).length == 0 || bytes(params.symbol).length == 0) {
            revert INVALID_VAULT_PARAMS();
        }

        // Initialize local variables struct to avoid stack too deep
        VaultCreationLocalVars memory vars;

        vars.currentNonce = _vaultCreationNonce++;
        vars.salt = keccak256(abi.encode(msg.sender, params.asset, params.name, params.symbol, vars.currentNonce));

        // Create minimal proxies
        superVault = VAULT_IMPLEMENTATION.cloneDeterministic(vars.salt);
        escrow = ESCROW_IMPLEMENTATION.cloneDeterministic(vars.salt);
        strategy = STRATEGY_IMPLEMENTATION.cloneDeterministic(vars.salt);
        depositQueue = QUEUE_IMPLEMENTATION.cloneDeterministic(vars.salt);

        // Initialize superVault (sync deposit/mint gated to the deposit queue)
        ManagedSuperVault(superVault).initialize(params.asset, params.name, params.symbol, strategy, escrow, depositQueue);

        // Initialize escrow
        SuperVaultEscrow(escrow).initialize(superVault);

        // Initialize strategy
        ManagedSuperVaultStrategy(payable(strategy)).initialize(superVault, params.feeConfig);

        // Initialize deposit queue
        IManagedSuperVaultDepositQueue(depositQueue).initialize(superVault, strategy, params.depositPolicy);

        // Register the vault's NAV attestation config with the oracle atomically so the vault
        // can never exist in an unconfigured-NAV state
        IManagedNAVOracle(navOracle).initializeAttestationConfig(strategy, params.navConfig);

        // Store vault quartet in registry
        _superVaults.add(superVault);
        _superVaultStrategies.add(strategy);
        _superVaultEscrows.add(escrow);
        _depositQueues.add(depositQueue);
        _depositQueueByVault[superVault] = depositQueue;

        // Get asset decimals
        (bool success, uint8 assetDecimals) = params.asset.tryGetAssetDecimals();
        if (!success) revert INVALID_ASSET();
        // Initial PPS is always 1.0 (scaled by asset decimals) for new vaults
        // This means 1 vault share = 1 unit of underlying asset at inception
        vars.initialPPS = 10 ** assetDecimals;

        // Validate maxStaleness against minimum required staleness
        if (params.maxStaleness < SUPER_GOVERNOR.getMinStaleness()) {
            revert MAX_STALENESS_TOO_LOW();
        }

        // Validate minUpdateInterval against minimum required staleness
        if (params.minUpdateInterval >= params.maxStaleness) {
            revert INVALID_VAULT_PARAMS();
        }

        // Initialize StrategyData individually to avoid mapping assignment issues
        _strategyData[strategy].pps = vars.initialPPS;
        _strategyData[strategy].lastUpdateTimestamp = block.timestamp;
        _strategyData[strategy].minUpdateInterval = params.minUpdateInterval;
        _strategyData[strategy].maxStaleness = params.maxStaleness;
        _strategyData[strategy].isPaused = false;
        _strategyData[strategy].mainManager = params.mainManager;

        uint256 secondaryLen = params.secondaryManagers.length;
        if (secondaryLen > MAX_SECONDARY_MANAGERS) revert TOO_MANY_SECONDARY_MANAGERS();

        for (uint256 i; i < secondaryLen; ++i) {
            address _secondaryManager = params.secondaryManagers[i];

            // Check if manager is a zero address
            if (_secondaryManager == address(0)) revert ZERO_ADDRESS();

            // Check if manager is already the primary manager
            if (_strategyData[strategy].mainManager == _secondaryManager) revert SECONDARY_MANAGER_CANNOT_BE_PRIMARY();

            // Add secondary manager and revert if it already exists
            if (!_strategyData[strategy].secondaryManagers.add(_secondaryManager)) {
                revert MANAGER_ALREADY_EXISTS();
            }
        }

        _strategyData[strategy].deviationThreshold = DEFAULT_DEVIATION_THRESHOLD;

        _emitDeploymentEvents(params, superVault, strategy, escrow, depositQueue, vars.currentNonce, vars.initialPPS);

        return (superVault, strategy, escrow, depositQueue);
    }

    /// @notice Emit deployment events
    /// @dev Split from createVault and using memory copies of the dynamic fields to avoid stack-too-deep
    function _emitDeploymentEvents(
        VaultCreationParams calldata params,
        address superVault,
        address strategy,
        address escrow,
        address depositQueue,
        uint256 nonce,
        uint256 initialPPS
    )
        private
    {
        string memory name_ = params.name;
        string memory symbol_ = params.symbol;
        string memory metadataURI_ = params.metadataURI;

        emit ManagedVaultDeployed(superVault, strategy, escrow, depositQueue, params.asset, name_, symbol_, nonce);
        emit MetadataURIUpdated(strategy, metadataURI_);
        emit PPSUpdated(strategy, initialPPS, _strategyData[strategy].lastUpdateTimestamp);
    }

    /*//////////////////////////////////////////////////////////////
                          PPS UPDATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function forwardPPS(ForwardPPSArgs calldata args) external onlyPPSOracle {
        uint256 strategiesLength = args.strategies.length;
        for (uint256 i; i < strategiesLength; ++i) {
            address strategy = args.strategies[i];

            // Skip invalid strategy
            if (!_superVaultStrategies.contains(strategy)) {
                emit UnknownStrategy(strategy);
                continue;
            }

            // Skip invalid timestamp
            uint256 ts = args.timestamps[i];

            // [Property 4: Future Timestamp Rejection]
            // Reject updates with timestamps in the future. This prevents validators from
            // creating signatures with future timestamps that could be used later.
            if (ts > block.timestamp) {
                emit ProvidedTimestampExceedsBlockTimestamp(strategy, ts, block.timestamp);
                continue;
            }

            StrategyData storage data = _strategyData[strategy];

            // [Property 5: Pause Rejection]
            // Always skip paused strategies, regardless of payment settings.
            // Paused strategies should not accept any PPS updates until explicitly unpaused.
            // This check happens early to avoid unnecessary processing and gas costs.
            if (data.isPaused) {
                emit PPSUpdateRejectedStrategyPaused(strategy);
                continue; // Skip processing paused strategies
            }

            // [Property 6: Staleness Enforcement (Absolute Time)]
            // Always enforce staleness check, regardless of payment status.
            // This prevents attackers from submitting stale signatures to manipulate PPS.
            // The check must occur before payment calculation to protect all strategies.
            if (block.timestamp - ts > data.maxStaleness) {
                emit StaleUpdate(strategy, args.updateAuthority, ts);
                continue; // Skip processing stale updates
            }

            _forwardPPS(PPSUpdateData({ strategy: strategy, pps: args.ppss[i], timestamp: ts }));
        }
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) external validStrategy(msg.sender) {
        // msg.sender must be a registered strategy (validated by modifier)
        address strategy = msg.sender;

        StrategyData storage data = _strategyData[strategy];
        // Disallow PPS updates after skim when strategy is paused or PPS is stale
        if (data.isPaused) revert STRATEGY_PAUSED();
        if (data.ppsStale) revert PPS_STALE();
        uint256 oldPPS = data.pps;

        // VALIDATION 1: PPS must decrease after fee skim
        if (newPPS >= oldPPS) revert PPS_MUST_DECREASE_AFTER_SKIM();

        // VALIDATION 2: PPS must be positive
        if (newPPS == 0) revert INVALID_ASSET();

        // VALIDATION 3: Range check - deduction must be within max fee bounds
        // Use MAX_PERFORMANCE_FEE to avoid external call to strategy
        // Max possible PPS after skim: oldPPS * (1 - MAX_PERFORMANCE_FEE)
        // Use Ceil rounding to ensure strict enforcement of MAX_PERFORMANCE_FEE (51%) limit
        uint256 minAllowedPPS = oldPPS.mulDiv(BPS_PRECISION - MAX_PERFORMANCE_FEE, BPS_PRECISION, Math.Rounding.Ceil);

        if (newPPS < minAllowedPPS) revert PPS_DEDUCTION_TOO_LARGE();

        // VALIDATION 4: Fee amount must be non-zero when PPS decreases
        // This ensures consistent reporting between PPS change and claimed fee amount
        if (feeAmount == 0) revert INVALID_ASSET();

        // UPDATE: Store new PPS
        data.pps = newPPS;

        // UPDATE TIMESTAMP
        // Update timestamp to reflect when this PPS change occurred
        // NOTE: This may interact with oracle submissions - to be discussed
        data.lastUpdateTimestamp = block.timestamp;

        // NOTE: We do NOT reset ppsStale flag here
        // The skim function can only be called if _validateStrategyState doesn't revert
        // So if we reach here, the strategy state is valid

        emit PPSUpdatedAfterSkim(strategy, oldPPS, newPPS, feeAmount, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        NAV ORACLE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev First-set is immediate and one-time (mirrors SuperGovernor.setActivePPSOracle); all
    ///      subsequent changes must go through the timelocked propose/execute path
    function setInitialNavOracle(address oracle) external {
        _requireRole(_SUPER_GOVERNOR_ROLE);

        if (oracle == address(0)) revert ZERO_ADDRESS();
        if (navOracle != address(0)) revert NAV_ORACLE_ALREADY_SET();

        navOracle = oracle;

        emit NavOracleChanged(address(0), oracle);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev Timelocked because the NAV oracle has full control over stored PPS for every
    ///      managed vault — mirrors SuperGovernor's active-PPS-oracle change pattern
    function proposeNavOracle(address newOracle) external {
        _requireRole(_SUPER_GOVERNOR_ROLE);

        if (newOracle == address(0)) revert ZERO_ADDRESS();

        proposedNavOracle = newOracle;
        navOracleEffectiveTime = block.timestamp + NAV_ORACLE_CHANGE_TIMELOCK;

        emit NavOracleProposed(newOracle, navOracleEffectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeNavOracleChange() external {
        if (proposedNavOracle == address(0)) revert NO_PENDING_NAV_ORACLE_CHANGE();
        if (block.timestamp < navOracleEffectiveTime) revert TIMELOCK_NOT_EXPIRED();

        address oldOracle = navOracle;
        navOracle = proposedNavOracle;

        proposedNavOracle = address(0);
        navOracleEffectiveTime = 0;

        emit NavOracleChanged(oldOracle, navOracle);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelNavOracleChange() external {
        _requireRole(_SUPER_GOVERNOR_ROLE);

        if (proposedNavOracle == address(0)) revert NO_PENDING_NAV_ORACLE_CHANGE();

        address cancelledOracle = proposedNavOracle;
        proposedNavOracle = address(0);
        navOracleEffectiveTime = 0;

        emit NavOracleChangeCancelled(cancelledOracle);
    }

    /*//////////////////////////////////////////////////////////////
                        METADATA MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev The metadata URI is event-only (no onchain storage) — indexers track the latest value
    function updateMetadataURI(address strategy, string calldata metadataURI) external validStrategy(strategy) {
        if (!isAnyManager(msg.sender, strategy)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        emit MetadataURIUpdated(strategy, metadataURI);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Manually pauses a strategy
    /// @param strategy Address of the strategy to pause
    /// @dev Only the main or secondary manager of the strategy can pause it
    function pauseStrategy(address strategy) external validStrategy(strategy) {
        // Either primary or secondary manager can pause
        if (!isAnyManager(msg.sender, strategy)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Check if strategy is already paused
        if (_strategyData[strategy].isPaused) {
            revert STRATEGY_ALREADY_PAUSED();
        }

        // Pause the strategy
        _strategyData[strategy].isPaused = true;
        _strategyData[strategy].ppsStale = true;
        emit StrategyPaused(strategy);
    }

    /// @notice Manually unpauses a strategy
    /// @param strategy Address of the strategy to unpause
    /// @dev unpausing marks PPS stale until a fresh oracle update
    function unpauseStrategy(address strategy) external validStrategy(strategy) {
        if (!isAnyManager(msg.sender, strategy)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Check if strategy is currently paused
        if (!_strategyData[strategy].isPaused) {
            revert STRATEGY_NOT_PAUSED();
        }

        // Unpause the strategy and track unpause timestamp
        _strategyData[strategy].isPaused = false;
        _strategyData[strategy].lastUnpauseTimestamp = block.timestamp; // Track for skim timelock
        // ppsStale already true from pause - no need to set again (gas savings)
        emit StrategyUnpaused(strategy);
    }

    /*//////////////////////////////////////////////////////////////
                       MANAGER MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function addSecondaryManager(address strategy, address manager) external validStrategy(strategy) {
        // Only the primary manager can add secondary managers
        if (msg.sender != _strategyData[strategy].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (manager == address(0)) revert ZERO_ADDRESS();

        // Check if manager is already the primary manager
        if (_strategyData[strategy].mainManager == manager) revert SECONDARY_MANAGER_CANNOT_BE_PRIMARY();

        // Enforce a cap on secondary managers to prevent governance DoS on changePrimaryManager
        if (_strategyData[strategy].secondaryManagers.length() >= MAX_SECONDARY_MANAGERS) {
            revert TOO_MANY_SECONDARY_MANAGERS();
        }

        // Add as secondary manager using EnumerableSet
        if (!_strategyData[strategy].secondaryManagers.add(manager)) revert MANAGER_ALREADY_EXISTS();

        emit SecondaryManagerAdded(strategy, manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function removeSecondaryManager(address strategy, address manager) external validStrategy(strategy) {
        // Only the primary manager can remove secondary managers
        if (msg.sender != _strategyData[strategy].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        // Remove the manager using EnumerableSet
        if (!_strategyData[strategy].secondaryManagers.remove(manager)) revert MANAGER_NOT_FOUND();

        emit SecondaryManagerRemoved(strategy, manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function updateDeviationThreshold(address strategy, uint256 deviationThreshold_) external validStrategy(strategy) {
        // Since this is a risky call, we only allow main managers as callers
        if (msg.sender != _strategyData[strategy].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Managed hardening: the deviation check cannot be disabled — manual NAV is manager-attested,
        // so the bound must stay live (capped at 100%; zero would block every update)
        if (deviationThreshold_ == 0 || deviationThreshold_ > MAX_DEVIATION_THRESHOLD) {
            revert INVALID_DEVIATION_THRESHOLD();
        }

        // Update the threshold
        _strategyData[strategy].deviationThreshold = deviationThreshold_;

        // Emit the event
        emit DeviationThresholdUpdated(strategy, deviationThreshold_);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function changeGlobalLeavesStatus(
        bytes32[] memory leaves,
        bool[] memory statuses,
        address strategy
    )
        external
        validStrategy(strategy)
    {
        // Only the primary manager can change global leaves status
        if (msg.sender != _strategyData[strategy].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }
        uint256 leavesLen = leaves.length;
        // Check array lengths match
        if (leavesLen != statuses.length) {
            revert MISMATCHED_ARRAY_LENGTHS();
        }

        // Update banned status for each leaf
        for (uint256 i; i < leavesLen; i++) {
            _strategyData[strategy].bannedLeaves[leaves[i]] = statuses[i];
        }

        // Emit event
        emit GlobalLeavesStatusChanged(strategy, leaves, statuses);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev SECURITY: This is the emergency governance override function
    /// @dev Clears ALL pending proposals and secondary managers to prevent malicious manager attacks:
    ///      - Pending manager change proposals
    ///      - Pending hooks root proposals
    ///      - Pending minUpdateInterval proposals
    ///      - ALL secondary managers (they may be controlled by malicious manager)
    /// @dev This ensures clean slate for new manager without inherited vulnerabilities
    /// @dev This function is only callable by SUPER_GOVERNOR
    function changePrimaryManager(
        address strategy,
        address newManager,
        address feeRecipient
    )
        external
        validStrategy(strategy)
    {
        // Gated on the SuperGovernor role (the deployed SuperGovernor contract cannot reach this
        // aggregator); the takeover-freeze check is inlined since it lives in the governor wrapper
        _requireRole(_SUPER_GOVERNOR_ROLE);
        if (SUPER_GOVERNOR.isManagerTakeoverFrozen()) revert MANAGER_TAKEOVERS_FROZEN();

        if (newManager == address(0) || feeRecipient == address(0)) revert ZERO_ADDRESS();

        // Check if new manager is already the primary manager to prevent malicious feeRecipient update
        if (newManager == _strategyData[strategy].mainManager) revert MANAGER_ALREADY_EXISTS();

        address oldManager = _strategyData[strategy].mainManager;

        // SECURITY: Clear any pending manager proposals to prevent malicious re-takeover
        _strategyData[strategy].proposedManager = address(0);
        _strategyData[strategy].managerChangeEffectiveTime = 0;

        // SECURITY: Clear any pending fee recipient proposals to prevent malicious change
        _strategyData[strategy].proposedFeeRecipient = address(0);

        // SECURITY: Clear any pending hooks root proposals to prevent malicious hook updates
        _strategyData[strategy].proposedHooksRoot = bytes32(0);
        _strategyData[strategy].hooksRootEffectiveTime = 0;

        // SECURITY: Clear any pending minUpdateInterval proposals
        _strategyData[strategy].proposedMinUpdateInterval = 0;
        _strategyData[strategy].minUpdateIntervalEffectiveTime = 0;

        // SECURITY: Clear all secondary managers as they may be controlled by malicious manager
        // Get all secondary managers first to emit proper events
        address[] memory clearedSecondaryManagers = _strategyData[strategy].secondaryManagers.values();

        // Clear the entire secondary managers set
        for (uint256 i = 0; i < clearedSecondaryManagers.length; i++) {
            _strategyData[strategy].secondaryManagers.remove(clearedSecondaryManagers[i]);
            emit SecondaryManagerRemoved(strategy, clearedSecondaryManagers[i]);
        }

        // Set the new primary manager
        _strategyData[strategy].mainManager = newManager;

        // Set the new fee recipient
        ISuperVaultStrategy(strategy).changeFeeRecipient(feeRecipient);

        emit PrimaryManagerChanged(strategy, oldManager, newManager, feeRecipient);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function proposeChangePrimaryManager(
        address strategy,
        address newManager,
        address feeRecipient
    )
        external
        validStrategy(strategy)
    {
        // Only secondary managers can propose changes to the primary manager
        if (!_strategyData[strategy].secondaryManagers.contains(msg.sender)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (newManager == address(0) || feeRecipient == address(0)) revert ZERO_ADDRESS();

        // Check if new manager is already the primary manager to prevent malicious feeRecipient update
        if (newManager == _strategyData[strategy].mainManager) revert MANAGER_ALREADY_EXISTS();

        // Set up the proposal with 7-day timelock
        uint256 effectiveTime = block.timestamp + _MANAGER_CHANGE_TIMELOCK;

        // Store proposal in the strategy data
        _strategyData[strategy].proposedManager = newManager;
        _strategyData[strategy].proposedFeeRecipient = feeRecipient;
        _strategyData[strategy].managerChangeEffectiveTime = effectiveTime;

        emit PrimaryManagerChangeProposed(strategy, msg.sender, newManager, feeRecipient, effectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelChangePrimaryManager(address strategy) external validStrategy(strategy) {
        // Only the current main manager can cancel the proposal
        if (_strategyData[strategy].mainManager != msg.sender) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Check if there is a pending proposal
        if (_strategyData[strategy].proposedManager == address(0)) {
            revert NO_PENDING_MANAGER_CHANGE();
        }

        address cancelledManager = _strategyData[strategy].proposedManager;

        // Clear the proposal
        _strategyData[strategy].proposedManager = address(0);
        _strategyData[strategy].proposedFeeRecipient = address(0);
        _strategyData[strategy].managerChangeEffectiveTime = 0;

        emit PrimaryManagerChangeCancelled(strategy, cancelledManager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeChangePrimaryManager(address strategy) external validStrategy(strategy) {
        // Check if there is a pending proposal
        if (_strategyData[strategy].proposedManager == address(0)) revert NO_PENDING_MANAGER_CHANGE();

        // Check if the timelock period has passed
        if (block.timestamp < _strategyData[strategy].managerChangeEffectiveTime) revert TIMELOCK_NOT_EXPIRED();

        address newManager = _strategyData[strategy].proposedManager;
        address feeRecipient = _strategyData[strategy].proposedFeeRecipient;

        // Validate proposed values are not zero addresses (defense in depth)
        if (newManager == address(0) || feeRecipient == address(0)) revert ZERO_ADDRESS();

        address oldManager = _strategyData[strategy].mainManager;

        // SECURITY: Clear all secondary managers to prevent privilege retntion
        _strategyData[strategy].secondaryManagers.clear();

        _strategyData[strategy].proposedHooksRoot = bytes32(0);
        _strategyData[strategy].hooksRootEffectiveTime = 0;
        _strategyData[strategy].proposedMinUpdateInterval = 0;
        _strategyData[strategy].minUpdateIntervalEffectiveTime = 0;

        // Set the new primary manager
        _strategyData[strategy].mainManager = newManager;

        // Set the new fee recipient
        ISuperVaultStrategy(strategy).changeFeeRecipient(feeRecipient);

        // Clear the proposal
        _strategyData[strategy].proposedManager = address(0);
        _strategyData[strategy].proposedFeeRecipient = address(0);
        _strategyData[strategy].managerChangeEffectiveTime = 0;

        emit PrimaryManagerChanged(strategy, oldManager, newManager, feeRecipient);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev SECURITY: This function is intended to be used by governance to onboard a new manager without penalizing
    /// them for the previous manager's performance.
    /// @dev If a manager is replaced while the strategy is below its
    /// previous HWM, the new manager would otherwise inherit a "loss" state and be unable to earn performance fees
    /// until the fee config are updated after the week timelock.
    /// @dev Calling this function resets the HWM to the current PPS, allowing a newly appointed manager to start from a
    /// neutral baseline. @dev This function is only callable by SUPER_GOVERNOR
    function resetHighWaterMark(address strategy) external validStrategy(strategy) {
        // Gated on the SuperGovernor role (see changePrimaryManager)
        _requireRole(_SUPER_GOVERNOR_ROLE);

        uint256 newHwmPps = _strategyData[strategy].pps;

        // Reset the High Water Mark to the current PPS
        ISuperVaultStrategy(strategy).resetHighWaterMark(newHwmPps);

        emit HighWaterMarkReset(strategy, newHwmPps);
    }

    /*//////////////////////////////////////////////////////////////
                        HOOK VALIDATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function setHooksRootUpdateTimelock(uint256 newTimelock) external {
        // Gated on the SuperGovernor role (see changePrimaryManager)
        _requireRole(_SUPER_GOVERNOR_ROLE);

        // Update the timelock
        _hooksRootUpdateTimelock = newTimelock;

        emit HooksRootUpdateTimelockChanged(newTimelock);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function proposeGlobalHooksRoot(bytes32 newRoot) external {
        // Governor role proposes this aggregator's own global hooks root (mirrors
        // SuperGovernor.changeGlobalHooksRoot, which only drives the main-family aggregator)
        _requireRole(_GOVERNOR_ROLE);

        // Set new root with timelock
        _proposedGlobalHooksRoot = newRoot;
        uint256 effectiveTime = block.timestamp + _hooksRootUpdateTimelock;
        _globalHooksRootEffectiveTime = effectiveTime;

        emit GlobalHooksRootUpdateProposed(newRoot, effectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeGlobalHooksRootUpdate() external {
        bytes32 proposedRoot = _proposedGlobalHooksRoot;
        // Ensure there is a pending proposal
        if (proposedRoot == bytes32(0)) {
            revert NO_PENDING_GLOBAL_ROOT_CHANGE();
        }

        // Check if timelock period has elapsed
        if (block.timestamp < _globalHooksRootEffectiveTime) {
            revert ROOT_UPDATE_NOT_READY();
        }

        // Update the global hooks root
        bytes32 oldRoot = _globalHooksRoot;
        _globalHooksRoot = proposedRoot;
        _globalHooksRootEffectiveTime = 0;
        _proposedGlobalHooksRoot = bytes32(0);

        emit GlobalHooksRootUpdated(oldRoot, proposedRoot);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function setGlobalHooksRootVetoStatus(bool vetoed) external {
        // Guardian role vetoes (mirrors SuperGovernor.setGlobalHooksRootVetoStatus)
        _requireRole(_GUARDIAN_ROLE);

        // Don't emit event if status doesn't change
        if (_globalHooksRootVetoed == vetoed) {
            return;
        }

        // Update veto status
        _globalHooksRootVetoed = vetoed;

        emit GlobalHooksRootVetoStatusChanged(vetoed, _globalHooksRoot);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) external validStrategy(strategy) {
        // Only the main manager can propose strategy-specific hooks root
        if (_strategyData[strategy].mainManager != msg.sender) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Set proposed root with timelock
        _strategyData[strategy].proposedHooksRoot = newRoot;
        uint256 effectiveTime = block.timestamp + _hooksRootUpdateTimelock;
        _strategyData[strategy].hooksRootEffectiveTime = effectiveTime;

        emit StrategyHooksRootUpdateProposed(strategy, msg.sender, newRoot, effectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeStrategyHooksRootUpdate(address strategy) external validStrategy(strategy) {
        bytes32 proposedRoot = _strategyData[strategy].proposedHooksRoot;
        // Ensure there is a pending proposal
        if (proposedRoot == bytes32(0)) {
            revert NO_PENDING_MANAGER_CHANGE(); // Reusing error for simplicity
        }

        // Check if timelock period has elapsed
        if (block.timestamp < _strategyData[strategy].hooksRootEffectiveTime) {
            revert ROOT_UPDATE_NOT_READY();
        }

        // Update the strategy's hooks root
        bytes32 oldRoot = _strategyData[strategy].managerHooksRoot;
        _strategyData[strategy].managerHooksRoot = proposedRoot;

        // Reset proposal state
        _strategyData[strategy].proposedHooksRoot = bytes32(0);
        _strategyData[strategy].hooksRootEffectiveTime = 0;

        emit StrategyHooksRootUpdated(strategy, oldRoot, proposedRoot);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) external validStrategy(strategy) {
        // Guardian role vetoes (mirrors SuperGovernor.setStrategyHooksRootVetoStatus)
        _requireRole(_GUARDIAN_ROLE);

        // Don't emit event if status doesn't change
        if (_strategyData[strategy].hooksRootVetoed == vetoed) {
            return;
        }

        // Update veto status
        _strategyData[strategy].hooksRootVetoed = vetoed;

        emit StrategyHooksRootVetoStatusChanged(strategy, vetoed, _strategyData[strategy].managerHooksRoot);
    }

    /*//////////////////////////////////////////////////////////////
                 MIN UPDATE INTERVAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultAggregator
    function proposeMinUpdateIntervalChange(
        address strategy,
        uint256 newMinUpdateInterval
    )
        external
        validStrategy(strategy)
    {
        // Only the main manager can propose changes
        if (_strategyData[strategy].mainManager != msg.sender) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Validate: newMinUpdateInterval must be less than maxStaleness
        // This ensures updates can occur before data becomes stale
        if (newMinUpdateInterval >= _strategyData[strategy].maxStaleness) {
            revert MIN_UPDATE_INTERVAL_TOO_HIGH();
        }

        // Set proposed interval with timelock
        uint256 effectiveTime = block.timestamp + _PARAMETER_CHANGE_TIMELOCK;
        _strategyData[strategy].proposedMinUpdateInterval = newMinUpdateInterval;
        _strategyData[strategy].minUpdateIntervalEffectiveTime = effectiveTime;

        emit MinUpdateIntervalChangeProposed(strategy, msg.sender, newMinUpdateInterval, effectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeMinUpdateIntervalChange(address strategy) external validStrategy(strategy) {
        // Check if there is a pending proposal
        if (_strategyData[strategy].minUpdateIntervalEffectiveTime == 0) {
            revert NO_PENDING_MIN_UPDATE_INTERVAL_CHANGE();
        }

        // Check if the timelock period has passed
        if (block.timestamp < _strategyData[strategy].minUpdateIntervalEffectiveTime) {
            revert TIMELOCK_NOT_EXPIRED();
        }

        uint256 newInterval = _strategyData[strategy].proposedMinUpdateInterval;
        uint256 oldInterval = _strategyData[strategy].minUpdateInterval;

        // Clear the proposal first
        _strategyData[strategy].proposedMinUpdateInterval = 0;
        _strategyData[strategy].minUpdateIntervalEffectiveTime = 0;

        // Update the minUpdateInterval
        _strategyData[strategy].minUpdateInterval = newInterval;

        emit MinUpdateIntervalChanged(strategy, oldInterval, newInterval);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelMinUpdateIntervalChange(address strategy) external validStrategy(strategy) {
        // Only the main manager can cancel
        if (_strategyData[strategy].mainManager != msg.sender) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Check if there is a pending proposal
        if (_strategyData[strategy].minUpdateIntervalEffectiveTime == 0) {
            revert NO_PENDING_MIN_UPDATE_INTERVAL_CHANGE();
        }

        uint256 cancelledInterval = _strategyData[strategy].proposedMinUpdateInterval;

        // Clear the proposal
        _strategyData[strategy].proposedMinUpdateInterval = 0;
        _strategyData[strategy].minUpdateIntervalEffectiveTime = 0;

        emit MinUpdateIntervalChangeCancelled(strategy, cancelledInterval);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getProposedMinUpdateInterval(address strategy)
        external
        view
        returns (uint256 proposedInterval, uint256 effectiveTime)
    {
        return (
            _strategyData[strategy].proposedMinUpdateInterval, _strategyData[strategy].minUpdateIntervalEffectiveTime
        );
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isGlobalHooksRootVetoed() external view returns (bool vetoed) {
        return _globalHooksRootVetoed;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isStrategyHooksRootVetoed(address strategy) external view returns (bool vetoed) {
        return _strategyData[strategy].hooksRootVetoed;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function getSuperVaultsCount() external view returns (uint256) {
        return _superVaults.length();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getSuperVaultStrategiesCount() external view returns (uint256) {
        return _superVaultStrategies.length();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getSuperVaultEscrowsCount() external view returns (uint256) {
        return _superVaultEscrows.length();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getCurrentNonce() external view returns (uint256) {
        return _vaultCreationNonce;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getHooksRootUpdateTimelock() external view returns (uint256) {
        return _hooksRootUpdateTimelock;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getPPS(address strategy) external view validStrategy(strategy) returns (uint256 pps) {
        return _strategyData[strategy].pps;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getLastUpdateTimestamp(address strategy) external view returns (uint256 timestamp) {
        return _strategyData[strategy].lastUpdateTimestamp;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getMinUpdateInterval(address strategy) external view returns (uint256 interval) {
        return _strategyData[strategy].minUpdateInterval;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getMaxStaleness(address strategy) external view returns (uint256 staleness) {
        return _strategyData[strategy].maxStaleness;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getDeviationThreshold(address strategy)
        external
        view
        validStrategy(strategy)
        returns (uint256 deviationThreshold)
    {
        return _strategyData[strategy].deviationThreshold;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isStrategyPaused(address strategy) external view returns (bool isPaused) {
        return _strategyData[strategy].isPaused;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isPPSStale(address strategy) external view returns (bool isStale) {
        return _strategyData[strategy].ppsStale;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getLastUnpauseTimestamp(address strategy) external view returns (uint256 timestamp) {
        return _strategyData[strategy].lastUnpauseTimestamp;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getDepositQueue(address vault) external view returns (address queue) {
        return _depositQueueByVault[vault];
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getAllDepositQueues() external view returns (address[] memory) {
        return _depositQueues.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isDepositQueue(address queue) external view returns (bool) {
        return _depositQueues.contains(queue);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getMainManager(address strategy) external view returns (address manager) {
        return _strategyData[strategy].mainManager;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getPendingManagerChange(address strategy)
        external
        view
        returns (address proposedManager, uint256 effectiveTime)
    {
        return (_strategyData[strategy].proposedManager, _strategyData[strategy].managerChangeEffectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isMainManager(address manager, address strategy) public view returns (bool) {
        return _strategyData[strategy].mainManager == manager;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getSecondaryManagers(address strategy) external view returns (address[] memory) {
        return _strategyData[strategy].secondaryManagers.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isSecondaryManager(address manager, address strategy) external view returns (bool) {
        return _strategyData[strategy].secondaryManagers.contains(manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isAnyManager(address manager, address strategy) public view returns (bool) {
        // Single storage pointer read instead of multiple
        StrategyData storage data = _strategyData[strategy];
        return (data.mainManager == manager) || data.secondaryManagers.contains(manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getAllSuperVaults() external view returns (address[] memory) {
        return _superVaults.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function superVaults(uint256 index) external view returns (address) {
        if (index >= _superVaults.length()) revert INDEX_OUT_OF_BOUNDS();
        return _superVaults.at(index);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getAllSuperVaultStrategies() external view returns (address[] memory) {
        return _superVaultStrategies.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function superVaultStrategies(uint256 index) external view returns (address) {
        if (index >= _superVaultStrategies.length()) revert INDEX_OUT_OF_BOUNDS();
        return _superVaultStrategies.at(index);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getAllSuperVaultEscrows() external view returns (address[] memory) {
        return _superVaultEscrows.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function superVaultEscrows(uint256 index) external view returns (address) {
        if (index >= _superVaultEscrows.length()) revert INDEX_OUT_OF_BOUNDS();
        return _superVaultEscrows.at(index);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function validateHook(address strategy, ValidateHookArgs calldata args) external view returns (bool isValid) {
        // Cache all state variables in struct
        HookValidationCache memory cache = HookValidationCache({
            globalHooksRootVetoed: _globalHooksRootVetoed,
            globalHooksRoot: _globalHooksRoot,
            strategyHooksRootVetoed: _strategyData[strategy].hooksRootVetoed,
            strategyRoot: _strategyData[strategy].managerHooksRoot
        });

        // Early return false if either global or strategy hooks root is vetoed
        if (cache.globalHooksRootVetoed || cache.strategyHooksRootVetoed) {
            return false;
        }

        // Try to validate against global root first
        if (_validateSingleHook(args.hookAddress, args.hookArgs, args.globalProof, true, cache, strategy)) {
            return true;
        }

        // If global validation fails, try strategy root
        return _validateSingleHook(args.hookAddress, args.hookArgs, args.strategyProof, false, cache, strategy);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function validateHooks(
        address strategy,
        ValidateHookArgs[] calldata argsArray
    )
        external
        view
        returns (bool[] memory validHooks)
    {
        uint256 length = argsArray.length;

        // Cache all state variables in struct
        HookValidationCache memory cache = HookValidationCache({
            globalHooksRootVetoed: _globalHooksRootVetoed,
            globalHooksRoot: _globalHooksRoot,
            strategyHooksRootVetoed: _strategyData[strategy].hooksRootVetoed,
            strategyRoot: _strategyData[strategy].managerHooksRoot
        });

        // Early return all false if either global or strategy hooks root is vetoed
        if (cache.globalHooksRootVetoed || cache.strategyHooksRootVetoed) {
            return new bool[](length); // Array initialized with all false values
        }

        // Validate each hook
        validHooks = new bool[](length);
        for (uint256 i; i < length; i++) {
            // Try global root first
            if (_validateSingleHook(
                    argsArray[i].hookAddress, argsArray[i].hookArgs, argsArray[i].globalProof, true, cache, strategy
                )) {
                validHooks[i] = true;
            } else {
                // Try strategy root
                validHooks[i] = _validateSingleHook(
                    argsArray[i].hookAddress, argsArray[i].hookArgs, argsArray[i].strategyProof, false, cache, strategy
                );
            }
            // If both conditions fail, validHooks[i] remains false (default value)
        }

        return validHooks;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getGlobalHooksRoot() external view returns (bytes32 root) {
        return _globalHooksRoot;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getProposedGlobalHooksRoot() external view returns (bytes32 root, uint256 effectiveTime) {
        return (_proposedGlobalHooksRoot, _globalHooksRootEffectiveTime);
    }

    /// @notice Checks if the global hooks root is active (timelock period has passed)
    /// @return isActive True if the global hooks root is active
    function isGlobalHooksRootActive() external view returns (bool) {
        return block.timestamp >= _globalHooksRootEffectiveTime && _globalHooksRoot != bytes32(0);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getStrategyHooksRoot(address strategy) external view returns (bytes32 root) {
        return _strategyData[strategy].managerHooksRoot;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getProposedStrategyHooksRoot(address strategy)
        external
        view
        returns (bytes32 root, uint256 effectiveTime)
    {
        return (_strategyData[strategy].proposedHooksRoot, _strategyData[strategy].hooksRootEffectiveTime);
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Internal implementation of forwarding PPS updates
    /// @dev Implements Properties 7-10 from /security/security_properties.md:
    ///      - Property 7: Timestamp Monotonicity
    ///      - Property 8: Post-Unpause Timestamp Validation / C1-RE_ANCHOR
    ///      - Property 9: Rate Limit Enforcement
    ///      - Property 10: Deviation Threshold / C1 Check
    ///      (Property 11, the upkeep balance check, does not apply — the managed family has no upkeep)
    /// @dev Uses 'return' (not 'revert') for business logic rejections to enable batch processing
    /// @dev Auto-pauses strategy and marks PPS stale on validation failures
    /// @param args Struct containing all parameters for PPS update
    function _forwardPPS(PPSUpdateData memory args) internal {
        // Check rate limiting
        // Use the minimum of minUpdateInterval and maxStaleness to ensure minInterval is never higher than maxStaleness
        uint256 minInterval = _strategyData[args.strategy].minUpdateInterval;
        uint256 lastUpdate = _strategyData[args.strategy].lastUpdateTimestamp;

        // [Property 7: Timestamp Monotonicity]
        // Ensure timestamps are strictly increasing to prevent out-of-order updates.
        // This guarantees that PPS updates reflect the true chronological order of market conditions.
        if (args.timestamp <= lastUpdate) {
            emit TimestampNotMonotonic();
            return;
        }

        // [Property 8: Post-Unpause Timestamp Validation (C1-RE_ANCHOR)]
        // After unpause, only accept signatures timestamped AFTER the unpause event.
        // Note: lastUnpauseTimestamp is 0 for never-paused strategies (check skipped via short-circuit).
        uint256 lastUnpauseTimestamp = _strategyData[args.strategy].lastUnpauseTimestamp;
        if (lastUnpauseTimestamp > 0 && args.timestamp <= lastUnpauseTimestamp) {
            emit StaleSignatureAfterUnpause(args.strategy, args.timestamp, lastUnpauseTimestamp);
            return;
        }

        // [Property 9: Rate Limit Enforcement]
        // Enforce minimum time interval between PPS updates to prevent spam and ensure
        // adequate time for market conditions to change meaningfully.
        if (args.timestamp - lastUpdate < minInterval) {
            emit UpdateTooFrequent();
            return;
        }

        // Flag to track if any check failed
        bool checksFailed;

        // [Property 10: Deviation Threshold (C1 Check)]
        // Check if PPS deviation exceeds the configured threshold.
        // Large deviations may indicate data errors or extreme market conditions requiring review.
        // Skip this check if: threshold disabled (type(uint256).max), no previous PPS, or PPS marked stale.
        // Stale PPS skip allows emergency updates during liquidation scenarios.
        // Failures trigger auto-pause and mark PPS as stale (handled below).
        uint256 currentPPS = _strategyData[args.strategy].pps;
        if (
            _strategyData[args.strategy].deviationThreshold != type(uint256).max && currentPPS > 0
                && !_strategyData[args.strategy].ppsStale
        ) {
            // Skip deviation check if stale
            // Calculate absolute deviation, scaled by 1e18
            uint256 absDiff = args.pps > currentPPS ? (args.pps - currentPPS) : (currentPPS - args.pps);
            uint256 relativeDeviation = Math.mulDiv(absDiff, 1e18, currentPPS);
            if (relativeDeviation > _strategyData[args.strategy].deviationThreshold) {
                checksFailed = true;
                emit StrategyCheckFailed(args.strategy, "HIGH_PPS_DEVIATION");
            }
        }


        // Pause strategy if any check failed and mark PPS as stale
        if ((checksFailed || args.pps == 0)) {
            _strategyData[args.strategy].isPaused = true;
            _strategyData[args.strategy].ppsStale = true; // Mark stale when auto-pausing
            emit StrategyPaused(args.strategy);
            emit StrategyPPSStale(args.strategy);
        } else {
            // Only store PPS, timestamp and clear stale flag when validation passes
            _strategyData[args.strategy].pps = args.pps;
            _strategyData[args.strategy].lastUpdateTimestamp = args.timestamp;
            // Only reset stale flag if it was previously stale (gas optimization)
            if (_strategyData[args.strategy].ppsStale) {
                _strategyData[args.strategy].ppsStale = false;
                emit StrategyPPSStaleReset(args.strategy);
            }
            emit PPSUpdated(args.strategy, args.pps, args.timestamp);
        }
        // If checks failed, PPS remains at old value (safer for external integrators)
    }

    /// @notice Creates a leaf node for Merkle verification from hook address and arguments
    /// @param hookAddress The address of the hook contract
    /// @param hookArgs The packed-encoded hook arguments (from solidityPack in JS)
    /// @return leaf The leaf node hash
    function _createLeaf(address hookAddress, bytes calldata hookArgs) internal pure returns (bytes32) {
        /// @dev The leaf now includes both hook address and args to prevent cross-hook replay attacks
        /// @dev Different hooks with identical encoded args will have different authorization leaves
        /// @dev This matches StandardMerkleTree's standardLeafHash: keccak256(keccak256(abi.encode(hookAddress,
        /// hookArgs)))
        /// @dev but uses bytes.concat for explicit concatenation
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
    }

    /**
     * @dev Internal function to validate a single hook against either global or strategy root
     * @param hookAddress The address of the hook contract
     * @param hookArgs Hook arguments
     * @param proof Merkle proof for the specified root
     * @param isGlobalProof Whether to validate against global root (true) or strategy root (false)
     * @param cache Cached hook validation state variables
     * @param strategy Address of the strategy (needed to check banned leaves for global proofs)
     * @return True if hook is valid, false otherwise
     */
    function _validateSingleHook(
        address hookAddress,
        bytes calldata hookArgs,
        bytes32[] calldata proof,
        bool isGlobalProof,
        HookValidationCache memory cache,
        address strategy
    )
        internal
        view
        returns (bool)
    {
        // Early return for common veto cases (avoid leaf creation cost)
        if (isGlobalProof) {
            if (cache.globalHooksRootVetoed || cache.globalHooksRoot == bytes32(0)) {
                return false;
            }
        } else {
            if (cache.strategyHooksRootVetoed || cache.strategyRoot == bytes32(0)) {
                return false;
            }
        }

        // Only create leaf if checks pass
        bytes32 leaf = _createLeaf(hookAddress, hookArgs);

        if (isGlobalProof) {
            // Check if this leaf is banned by the manager
            if (_strategyData[strategy].bannedLeaves[leaf]) {
                return false;
            }

            // For single-leaf trees, empty proof is valid when root equals leaf
            if (proof.length == 0) {
                return cache.globalHooksRoot == leaf;
            }
            return MerkleProof.verify(proof, cache.globalHooksRoot, leaf);
        } else {
            // For single-leaf trees, empty proof is valid when root equals leaf
            if (proof.length == 0) {
                return cache.strategyRoot == leaf;
            }
            return MerkleProof.verify(proof, cache.strategyRoot, leaf);
        }
    }

}
