// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Superform
import { ManagedSuperVault } from "./ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "./ManagedSuperVaultController.sol";
import { ManagedSuperVaultEscrow } from "./ManagedSuperVaultEscrow.sol";
import { IManagedSuperVaultController } from "../interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { IManagedSuperVaultAggregator } from "../interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";

// Libraries
import { AssetMetadataLib } from "../libraries/AssetMetadataLib.sol";

/// @title ManagedSuperVaultAggregator
/// @author Superform Labs
/// @notice Sibling factory and registry for Managed Vaults. Deploys deterministic
///         vault/controller/escrow trios and owns per-vault registry state: managers, pause state,
///         attested manual NAV/PPS, freshness, and deviation bounds.
/// @dev There is intentionally no PPS oracle / upkeep / hooks-root machinery here: the NAV write path
///      is controller-only (finalized attested NAV proposals and fee-skim decreases). Large NAV
///      deviations auto-pause the vault and mark NAV stale, mirroring the Full SuperVault posture.
contract ManagedSuperVaultAggregator is IManagedSuperVaultAggregator {
    using AssetMetadataLib for address;
    using Clones for address;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Managed vault configuration and state data, keyed by controller address
    struct ManagedVaultData {
        uint256 pps; // Latest finalized attested NAV (scaled by asset decimals)
        uint256 lastUpdateTimestamp; // Observation timestamp of the latest finalized NAV
        uint256 minUpdateInterval; // Minimum time between NAV updates
        uint256 maxStaleness; // Maximum NAV age before the vault is operationally stale
        // Packed slot
        address mainManager;
        bool navStale;
        bool isPaused;
        // Registry links
        address vault;
        address escrow;
        // Managers
        EnumerableSet.AddressSet secondaryManagers;
        // Manager change proposal data
        address proposedManager;
        address proposedFeeRecipient;
        uint256 managerChangeEffectiveTime;
        // NAV deviation threshold: abs(new - current) / current, 1e18 scale
        uint256 deviationThreshold;
        // Min update interval proposal data
        uint256 proposedMinUpdateInterval;
        uint256 minUpdateIntervalEffectiveTime;
        uint256 lastUnpauseTimestamp;
        // Offchain metadata (descriptions, policies, disclosures)
        string metadataURI;
    }

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    // Vault implementation contracts
    address public immutable VAULT_IMPLEMENTATION;
    address public immutable CONTROLLER_IMPLEMENTATION;
    address public immutable ESCROW_IMPLEMENTATION;

    // Governance
    ISuperGovernor public immutable SUPER_GOVERNOR;

    // Managed vault data storage, keyed by controller
    mapping(address controller => ManagedVaultData) private _managedVaultData;

    // Registry of created vaults
    EnumerableSet.AddressSet private _managedVaults;
    EnumerableSet.AddressSet private _managedVaultControllers;
    EnumerableSet.AddressSet private _managedVaultEscrows;

    // Vault lookups
    mapping(address vault => address controller) private _vaultToController;
    mapping(address vault => address escrow) private _vaultToEscrow;

    // Constants
    uint256 private constant BPS_PRECISION = 10_000;
    uint256 private constant MAX_PERFORMANCE_FEE = 5100;

    // Maximum number of secondary managers per vault to prevent governance DoS on manager replacement
    uint256 public constant MAX_SECONDARY_MANAGERS = 5;

    // Default NAV deviation threshold for new vaults (50% in 1e18 scale, same as Full SuperVaults)
    uint256 private constant DEFAULT_DEVIATION_THRESHOLD = 5e17;

    // Timelock for manager changes
    uint256 private constant _MANAGER_CHANGE_TIMELOCK = 7 days;

    // Timelock for parameter changes (3 days)
    uint256 private constant _PARAMETER_CHANGE_TIMELOCK = 3 days;

    // Nonce for vault creation tracking
    uint256 private _vaultCreationNonce;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates that a controller exists (has been created by this aggregator)
    modifier validController(address controller) {
        _validController(controller);
        _;
    }

    function _validController(address controller) internal view {
        if (!_managedVaultControllers.contains(controller)) revert UNKNOWN_CONTROLLER();
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the ManagedSuperVaultAggregator
    /// @param superGovernor_ Address of the SuperGovernor contract
    /// @param vaultImpl_ Address of the pre-deployed ManagedSuperVault implementation
    /// @param controllerImpl_ Address of the pre-deployed ManagedSuperVaultController implementation
    /// @param escrowImpl_ Address of the pre-deployed ManagedSuperVaultEscrow implementation
    constructor(address superGovernor_, address vaultImpl_, address controllerImpl_, address escrowImpl_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        if (vaultImpl_ == address(0)) revert ZERO_ADDRESS();
        if (controllerImpl_ == address(0)) revert ZERO_ADDRESS();
        if (escrowImpl_ == address(0)) revert ZERO_ADDRESS();

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        VAULT_IMPLEMENTATION = vaultImpl_;
        CONTROLLER_IMPLEMENTATION = controllerImpl_;
        ESCROW_IMPLEMENTATION = escrowImpl_;
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT CREATION
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function createManagedVault(ManagedVaultCreationParams calldata params)
        external
        returns (address vault, address controller, address escrow)
    {
        // Input validation
        if (params.asset == address(0) || params.mainManager == address(0)) revert ZERO_ADDRESS();
        if (
            (params.feeConfig.performanceFeeBps > 0 || params.feeConfig.managementFeeBps > 0)
                && params.feeConfig.recipient == address(0)
        ) revert ZERO_ADDRESS();

        if (bytes(params.name).length == 0 || bytes(params.symbol).length == 0) {
            revert INVALID_VAULT_PARAMS();
        }

        // Validate NAV freshness parameters
        if (params.maxStaleness < SUPER_GOVERNOR.getMinStaleness()) {
            revert MAX_STALENESS_TOO_LOW();
        }
        if (params.minUpdateInterval >= params.maxStaleness) {
            revert INVALID_VAULT_PARAMS();
        }

        VaultCreationLocalVars memory vars;

        vars.currentNonce = _vaultCreationNonce++;
        vars.salt = keccak256(abi.encode(msg.sender, params.asset, params.name, params.symbol, vars.currentNonce));

        // Create minimal proxies
        vault = VAULT_IMPLEMENTATION.cloneDeterministic(vars.salt);
        escrow = ESCROW_IMPLEMENTATION.cloneDeterministic(vars.salt);
        controller = CONTROLLER_IMPLEMENTATION.cloneDeterministic(vars.salt);

        // Initialize vault
        ManagedSuperVault(vault).initialize(params.asset, params.name, params.symbol, controller, escrow);

        // Initialize escrow
        ManagedSuperVaultEscrow(escrow).initialize(vault, controller);

        // Initialize controller
        ManagedSuperVaultController(payable(controller))
            .initialize(vault, params.feeConfig, params.depositPolicy, params.navConfig);

        // Store vault trio in registry
        _managedVaults.add(vault);
        _managedVaultControllers.add(controller);
        _managedVaultEscrows.add(escrow);
        _vaultToController[vault] = controller;
        _vaultToEscrow[vault] = escrow;

        _registerManagedVault(params, vault, controller, escrow, vars);

        return (vault, controller, escrow);
    }

    /// @notice Store registry data and emit deployment events for a newly created trio
    /// @dev Split from createManagedVault to avoid stack-too-deep
    function _registerManagedVault(
        ManagedVaultCreationParams calldata params,
        address vault,
        address controller,
        address escrow,
        VaultCreationLocalVars memory vars
    )
        internal
    {
        // Get asset decimals
        (bool success, uint8 assetDecimals) = params.asset.tryGetAssetDecimals();
        if (!success) revert INVALID_ASSET();
        // Initial PPS is always 1.0 (scaled by asset decimals) for new vaults
        vars.initialPPS = 10 ** assetDecimals;

        ManagedVaultData storage data = _managedVaultData[controller];
        data.pps = vars.initialPPS;
        data.lastUpdateTimestamp = block.timestamp;
        data.minUpdateInterval = params.minUpdateInterval;
        data.maxStaleness = params.maxStaleness;
        data.isPaused = false;
        data.mainManager = params.mainManager;
        data.vault = vault;
        data.escrow = escrow;
        data.metadataURI = params.metadataURI;

        uint256 secondaryLen = params.secondaryManagers.length;
        if (secondaryLen > MAX_SECONDARY_MANAGERS) revert TOO_MANY_SECONDARY_MANAGERS();

        for (uint256 i; i < secondaryLen; ++i) {
            address secondaryManager = params.secondaryManagers[i];

            if (secondaryManager == address(0)) revert ZERO_ADDRESS();
            if (data.mainManager == secondaryManager) revert SECONDARY_MANAGER_CANNOT_BE_PRIMARY();
            if (!data.secondaryManagers.add(secondaryManager)) revert MANAGER_ALREADY_EXISTS();
        }

        // NAV deviation threshold: creation param in bps, stored in 1e18 scale (0 = default 50%)
        data.deviationThreshold = params.maxUpdateDeviationBps == 0
            ? DEFAULT_DEVIATION_THRESHOLD
            : Math.mulDiv(params.maxUpdateDeviationBps, 1e18, BPS_PRECISION);

        _emitDeploymentEvents(params, vault, controller, escrow, vars.currentNonce, vars.initialPPS);
    }

    /// @notice Emit deployment events
    /// @dev Split from registration and using memory copies of the dynamic fields to avoid stack-too-deep
    function _emitDeploymentEvents(
        ManagedVaultCreationParams calldata params,
        address vault,
        address controller,
        address escrow,
        uint256 nonce,
        uint256 initialPPS
    )
        private
    {
        string memory name_ = params.name;
        string memory symbol_ = params.symbol;
        string memory metadataURI_ = params.metadataURI;

        emit ManagedSuperVaultDeployed(vault, controller, escrow, params.asset, name_, symbol_, nonce);
        emit ManagedVaultConfigRegistered(controller, params.depositPolicy.approvalMode, metadataURI_);
        emit ManagedNAVUpdated(controller, 0, initialPPS, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                    NAV WRITE PATH (CONTROLLER-ONLY)
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultAggregator
    function updateManagedNAV(uint256 newPPS, uint256 timestamp) external validController(msg.sender) returns (bool) {
        address controller = msg.sender;
        ManagedVaultData storage data = _managedVaultData[controller];

        // No NAV finalization while paused
        if (data.isPaused) revert MANAGED_VAULT_PAUSED();

        if (newPPS == 0) revert INVALID_NAV();

        // [Future Timestamp Rejection]
        if (timestamp > block.timestamp) revert INVALID_TIMESTAMP();

        // [Timestamp Monotonicity]
        uint256 lastUpdate = data.lastUpdateTimestamp;
        if (timestamp <= lastUpdate) revert INVALID_TIMESTAMP();

        // [Post-Unpause Timestamp Validation] only accept observations made after the last unpause
        uint256 lastUnpauseTimestamp = data.lastUnpauseTimestamp;
        if (lastUnpauseTimestamp > 0 && timestamp <= lastUnpauseTimestamp) revert INVALID_TIMESTAMP();

        // [Staleness Enforcement (Absolute Time)]
        if (block.timestamp - timestamp > data.maxStaleness) revert STALE_UPDATE();

        // [Rate Limit Enforcement]
        if (timestamp - lastUpdate < data.minUpdateInterval) revert UPDATE_TOO_FREQUENT();

        // [Deviation Threshold] Large deviations auto-pause the vault and drop the value; the stale
        // flag skips this check so an explicitly resolved large-deviation NAV can finalize after an
        // unpause (mirrors the Full SuperVault emergency-update escape hatch)
        uint256 currentPPS = data.pps;
        if (data.deviationThreshold != type(uint256).max && currentPPS > 0 && !data.navStale) {
            uint256 absDiff = newPPS > currentPPS ? (newPPS - currentPPS) : (currentPPS - newPPS);
            uint256 relativeDeviation = Math.mulDiv(absDiff, 1e18, currentPPS);
            if (relativeDeviation > data.deviationThreshold) {
                data.isPaused = true;
                data.navStale = true;
                emit ManagedNAVDeviationExceeded(controller, newPPS, currentPPS, relativeDeviation);
                emit ManagedVaultPaused(controller);
                emit ManagedVaultNAVStale(controller);
                return false;
            }
        }

        // Store NAV and clear the stale flag
        data.pps = newPPS;
        data.lastUpdateTimestamp = timestamp;
        if (data.navStale) {
            data.navStale = false;
            emit ManagedVaultNAVStaleReset(controller);
        }
        emit ManagedNAVUpdated(controller, currentPPS, newPPS, timestamp);
        return true;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function updatePPSAfterSkim(uint256 newPPS, uint256 feeAmount) external validController(msg.sender) {
        address controller = msg.sender;

        ManagedVaultData storage data = _managedVaultData[controller];
        if (data.isPaused) revert MANAGED_VAULT_PAUSED();
        if (data.navStale) revert NAV_STALE();
        uint256 oldPPS = data.pps;

        // VALIDATION 1: PPS must decrease after fee skim
        if (newPPS >= oldPPS) revert PPS_MUST_DECREASE_AFTER_SKIM();

        // VALIDATION 2: PPS must be positive
        if (newPPS == 0) revert INVALID_NAV();

        // VALIDATION 3: Range check - deduction must be within max fee bounds
        uint256 minAllowedPPS = oldPPS.mulDiv(BPS_PRECISION - MAX_PERFORMANCE_FEE, BPS_PRECISION, Math.Rounding.Ceil);
        if (newPPS < minAllowedPPS) revert PPS_DEDUCTION_TOO_LARGE();

        // VALIDATION 4: Fee amount must be non-zero when PPS decreases
        if (feeAmount == 0) revert INVALID_NAV();

        data.pps = newPPS;
        data.lastUpdateTimestamp = block.timestamp;

        emit PPSUpdatedAfterSkim(controller, oldPPS, newPPS, feeAmount, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function pauseManagedVault(address controller) external validController(controller) {
        if (!isAnyManager(msg.sender, controller)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (_managedVaultData[controller].isPaused) {
            revert MANAGED_VAULT_ALREADY_PAUSED();
        }

        _managedVaultData[controller].isPaused = true;
        _managedVaultData[controller].navStale = true;
        emit ManagedVaultPaused(controller);
        emit ManagedVaultNAVStale(controller);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev Unpausing keeps NAV stale until a fresh attested update finalizes
    function unpauseManagedVault(address controller) external validController(controller) {
        if (!isAnyManager(msg.sender, controller)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (!_managedVaultData[controller].isPaused) {
            revert MANAGED_VAULT_NOT_PAUSED();
        }

        _managedVaultData[controller].isPaused = false;
        _managedVaultData[controller].lastUnpauseTimestamp = block.timestamp; // Track for skim timelock
        // navStale remains true from pause until a fresh update finalizes
        emit ManagedVaultUnpaused(controller);
    }

    /*//////////////////////////////////////////////////////////////
                       MANAGER MANAGEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultAggregator
    function addSecondaryManager(address controller, address manager) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (manager == address(0)) revert ZERO_ADDRESS();
        if (_managedVaultData[controller].mainManager == manager) revert SECONDARY_MANAGER_CANNOT_BE_PRIMARY();

        if (_managedVaultData[controller].secondaryManagers.length() >= MAX_SECONDARY_MANAGERS) {
            revert TOO_MANY_SECONDARY_MANAGERS();
        }

        if (!_managedVaultData[controller].secondaryManagers.add(manager)) revert MANAGER_ALREADY_EXISTS();

        emit SecondaryManagerAdded(controller, manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function removeSecondaryManager(address controller, address manager) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (!_managedVaultData[controller].secondaryManagers.remove(manager)) revert MANAGER_NOT_FOUND();

        emit SecondaryManagerRemoved(controller, manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function updateDeviationThreshold(
        address controller,
        uint256 deviationThreshold_
    )
        external
        validController(controller)
    {
        if (msg.sender != _managedVaultData[controller].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        _managedVaultData[controller].deviationThreshold = deviationThreshold_;

        emit DeviationThresholdUpdated(controller, deviationThreshold_);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function updateMetadataURI(address controller, string calldata metadataURI) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        _managedVaultData[controller].metadataURI = metadataURI;

        emit MetadataURIUpdated(controller, metadataURI);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev SECURITY: emergency governance override, mirrors SuperVaultAggregator.changePrimaryManager.
    ///      Clears all pending proposals and secondary managers to prevent malicious manager attacks.
    function changePrimaryManager(
        address controller,
        address newManager,
        address feeRecipient
    )
        external
        validController(controller)
    {
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (newManager == address(0) || feeRecipient == address(0)) revert ZERO_ADDRESS();
        if (newManager == _managedVaultData[controller].mainManager) revert MANAGER_ALREADY_EXISTS();

        address oldManager = _managedVaultData[controller].mainManager;

        // SECURITY: Clear any pending proposals to prevent malicious re-takeover
        _managedVaultData[controller].proposedManager = address(0);
        _managedVaultData[controller].proposedFeeRecipient = address(0);
        _managedVaultData[controller].managerChangeEffectiveTime = 0;
        _managedVaultData[controller].proposedMinUpdateInterval = 0;
        _managedVaultData[controller].minUpdateIntervalEffectiveTime = 0;

        // SECURITY: Clear all secondary managers as they may be controlled by the malicious manager
        address[] memory clearedSecondaryManagers = _managedVaultData[controller].secondaryManagers.values();
        for (uint256 i = 0; i < clearedSecondaryManagers.length; i++) {
            _managedVaultData[controller].secondaryManagers.remove(clearedSecondaryManagers[i]);
            emit SecondaryManagerRemoved(controller, clearedSecondaryManagers[i]);
        }

        _managedVaultData[controller].mainManager = newManager;

        IManagedSuperVaultController(controller).changeFeeRecipient(feeRecipient);

        emit PrimaryManagerChanged(controller, oldManager, newManager, feeRecipient);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function proposeChangePrimaryManager(
        address controller,
        address newManager,
        address feeRecipient
    )
        external
        validController(controller)
    {
        // Only secondary managers can propose changes to the primary manager
        if (!_managedVaultData[controller].secondaryManagers.contains(msg.sender)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (newManager == address(0) || feeRecipient == address(0)) revert ZERO_ADDRESS();
        if (newManager == _managedVaultData[controller].mainManager) revert MANAGER_ALREADY_EXISTS();

        uint256 effectiveTime = block.timestamp + _MANAGER_CHANGE_TIMELOCK;

        _managedVaultData[controller].proposedManager = newManager;
        _managedVaultData[controller].proposedFeeRecipient = feeRecipient;
        _managedVaultData[controller].managerChangeEffectiveTime = effectiveTime;

        emit PrimaryManagerChangeProposed(controller, msg.sender, newManager, feeRecipient, effectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelChangePrimaryManager(address controller) external validController(controller) {
        if (_managedVaultData[controller].mainManager != msg.sender) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (_managedVaultData[controller].proposedManager == address(0)) {
            revert NO_PENDING_MANAGER_CHANGE();
        }

        address cancelledManager = _managedVaultData[controller].proposedManager;

        _managedVaultData[controller].proposedManager = address(0);
        _managedVaultData[controller].proposedFeeRecipient = address(0);
        _managedVaultData[controller].managerChangeEffectiveTime = 0;

        emit PrimaryManagerChangeCancelled(controller, cancelledManager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeChangePrimaryManager(address controller) external validController(controller) {
        if (_managedVaultData[controller].proposedManager == address(0)) revert NO_PENDING_MANAGER_CHANGE();

        if (block.timestamp < _managedVaultData[controller].managerChangeEffectiveTime) revert TIMELOCK_NOT_EXPIRED();

        address newManager = _managedVaultData[controller].proposedManager;
        address feeRecipient = _managedVaultData[controller].proposedFeeRecipient;

        if (newManager == address(0) || feeRecipient == address(0)) revert ZERO_ADDRESS();

        address oldManager = _managedVaultData[controller].mainManager;

        // SECURITY: Clear all secondary managers to prevent privilege retention
        _managedVaultData[controller].secondaryManagers.clear();

        _managedVaultData[controller].proposedMinUpdateInterval = 0;
        _managedVaultData[controller].minUpdateIntervalEffectiveTime = 0;

        _managedVaultData[controller].mainManager = newManager;

        IManagedSuperVaultController(controller).changeFeeRecipient(feeRecipient);

        _managedVaultData[controller].proposedManager = address(0);
        _managedVaultData[controller].proposedFeeRecipient = address(0);
        _managedVaultData[controller].managerChangeEffectiveTime = 0;

        emit PrimaryManagerChanged(controller, oldManager, newManager, feeRecipient);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev SECURITY: allows governance to onboard a new manager without penalizing them for the
    ///      previous manager's performance (mirrors SuperVaultAggregator.resetHighWaterMark)
    function resetHighWaterMark(address controller) external validController(controller) {
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        uint256 newHwmPps = _managedVaultData[controller].pps;

        IManagedSuperVaultController(controller).resetHighWaterMark(newHwmPps);

        emit HighWaterMarkReset(controller, newHwmPps);
    }

    /*//////////////////////////////////////////////////////////////
                 MIN UPDATE INTERVAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultAggregator
    function proposeMinUpdateIntervalChange(
        address controller,
        uint256 newMinUpdateInterval
    )
        external
        validController(controller)
    {
        if (_managedVaultData[controller].mainManager != msg.sender) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (newMinUpdateInterval >= _managedVaultData[controller].maxStaleness) {
            revert MIN_UPDATE_INTERVAL_TOO_HIGH();
        }

        uint256 effectiveTime = block.timestamp + _PARAMETER_CHANGE_TIMELOCK;
        _managedVaultData[controller].proposedMinUpdateInterval = newMinUpdateInterval;
        _managedVaultData[controller].minUpdateIntervalEffectiveTime = effectiveTime;

        emit MinUpdateIntervalChangeProposed(controller, msg.sender, newMinUpdateInterval, effectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeMinUpdateIntervalChange(address controller) external validController(controller) {
        if (_managedVaultData[controller].minUpdateIntervalEffectiveTime == 0) {
            revert NO_PENDING_MIN_UPDATE_INTERVAL_CHANGE();
        }

        if (block.timestamp < _managedVaultData[controller].minUpdateIntervalEffectiveTime) {
            revert TIMELOCK_NOT_EXPIRED();
        }

        uint256 newInterval = _managedVaultData[controller].proposedMinUpdateInterval;
        uint256 oldInterval = _managedVaultData[controller].minUpdateInterval;

        _managedVaultData[controller].proposedMinUpdateInterval = 0;
        _managedVaultData[controller].minUpdateIntervalEffectiveTime = 0;

        _managedVaultData[controller].minUpdateInterval = newInterval;

        emit MinUpdateIntervalChanged(controller, oldInterval, newInterval);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelMinUpdateIntervalChange(address controller) external validController(controller) {
        if (_managedVaultData[controller].mainManager != msg.sender) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (_managedVaultData[controller].minUpdateIntervalEffectiveTime == 0) {
            revert NO_PENDING_MIN_UPDATE_INTERVAL_CHANGE();
        }

        uint256 cancelledInterval = _managedVaultData[controller].proposedMinUpdateInterval;

        _managedVaultData[controller].proposedMinUpdateInterval = 0;
        _managedVaultData[controller].minUpdateIntervalEffectiveTime = 0;

        emit MinUpdateIntervalChangeCancelled(controller, cancelledInterval);
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultAggregator
    function VAULT_TYPE() external pure returns (string memory) {
        return "managed_vault";
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function NAV_MODE() external pure returns (string memory) {
        return "attested_manual";
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getPPS(address controller) external view validController(controller) returns (uint256 pps) {
        return _managedVaultData[controller].pps;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getLastUpdateTimestamp(address controller) external view returns (uint256 timestamp) {
        return _managedVaultData[controller].lastUpdateTimestamp;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getMinUpdateInterval(address controller) external view returns (uint256 interval) {
        return _managedVaultData[controller].minUpdateInterval;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getMaxStaleness(address controller) external view returns (uint256 staleness) {
        return _managedVaultData[controller].maxStaleness;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getDeviationThreshold(address controller)
        external
        view
        validController(controller)
        returns (uint256 deviationThreshold)
    {
        return _managedVaultData[controller].deviationThreshold;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isManagedVaultPaused(address controller) external view returns (bool isPaused) {
        return _managedVaultData[controller].isPaused;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isNAVStale(address controller) external view returns (bool isStale) {
        return _managedVaultData[controller].navStale;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getLastUnpauseTimestamp(address controller) external view returns (uint256 timestamp) {
        return _managedVaultData[controller].lastUnpauseTimestamp;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getMainManager(address controller) external view returns (address manager) {
        return _managedVaultData[controller].mainManager;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getPendingManagerChange(address controller)
        external
        view
        returns (address proposedManager, uint256 effectiveTime)
    {
        return (_managedVaultData[controller].proposedManager, _managedVaultData[controller].managerChangeEffectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isMainManager(address manager, address controller) public view returns (bool) {
        return _managedVaultData[controller].mainManager == manager;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getSecondaryManagers(address controller) external view returns (address[] memory) {
        return _managedVaultData[controller].secondaryManagers.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isSecondaryManager(address manager, address controller) external view returns (bool) {
        return _managedVaultData[controller].secondaryManagers.contains(manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isAnyManager(address manager, address controller) public view returns (bool) {
        ManagedVaultData storage data = _managedVaultData[controller];
        return (data.mainManager == manager) || data.secondaryManagers.contains(manager);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getProposedMinUpdateInterval(address controller)
        external
        view
        returns (uint256 proposedInterval, uint256 effectiveTime)
    {
        return (
            _managedVaultData[controller].proposedMinUpdateInterval,
            _managedVaultData[controller].minUpdateIntervalEffectiveTime
        );
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getMetadataURI(address controller) external view returns (string memory metadataURI) {
        return _managedVaultData[controller].metadataURI;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isManagedVault(address vault) external view returns (bool) {
        return _managedVaults.contains(vault);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getManagedVaultController(address vault) external view returns (address controller) {
        return _vaultToController[vault];
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getManagedVaultEscrow(address vault) external view returns (address escrow) {
        return _vaultToEscrow[vault];
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getAllManagedVaults() external view returns (address[] memory) {
        return _managedVaults.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getAllManagedVaultControllers() external view returns (address[] memory) {
        return _managedVaultControllers.values();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function managedVaults(uint256 index) external view returns (address) {
        if (index >= _managedVaults.length()) revert INDEX_OUT_OF_BOUNDS();
        return _managedVaults.at(index);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function managedVaultControllers(uint256 index) external view returns (address) {
        if (index >= _managedVaultControllers.length()) revert INDEX_OUT_OF_BOUNDS();
        return _managedVaultControllers.at(index);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getManagedVaultsCount() external view returns (uint256) {
        return _managedVaults.length();
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getCurrentNonce() external view returns (uint256) {
        return _vaultCreationNonce;
    }
}
