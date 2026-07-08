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
/// @dev There is intentionally no PPS oracle / upkeep / hooks-root machinery here. The aggregator owns
///      the full attested-manual NAV lifecycle (propose/attest/resolve + attestor-set timelock), keyed by
///      controller. Large NAV deviations auto-pause the vault and mark NAV stale, mirroring the Full
///      SuperVault posture.
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
        uint256 proposedDeviationThreshold;
        uint256 deviationThresholdEffectiveTime;
        // Min update interval proposal data
        uint256 proposedMinUpdateInterval;
        uint256 minUpdateIntervalEffectiveTime;
        uint256 lastUnpauseTimestamp;
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

    // NAV attestation lifecycle, keyed by controller. Consolidated here (rather than the controller) so
    // all NAV/PPS/deviation/pause logic lives in one place, and to keep the controller under EIP-170.
    mapping(address controller => EnumerableSet.AddressSet) private _navAttestors;
    mapping(address controller => uint8) private _navThreshold;
    mapping(address controller => uint256) private _nextProposalId;
    mapping(address controller => uint256) private _activeProposalId;
    mapping(address controller => mapping(uint256 => IManagedSuperVaultController.NAVUpdateProposal)) private
        _navProposals;
    mapping(address controller => mapping(uint256 => mapping(address => bool))) private _hasAttested;
    // Timelocked attestor-set / threshold change (independence guarantee)
    mapping(address controller => address[]) private _pendingAttestors;
    mapping(address controller => uint8) private _pendingThreshold;
    mapping(address controller => uint256) private _navConfigEffectiveTime;

    // Constants
    uint256 private constant BPS_PRECISION = 10_000;
    uint256 private constant MAX_PERFORMANCE_FEE = 5100;

    // Maximum number of secondary managers per vault to prevent governance DoS on manager replacement
    uint256 public constant MAX_SECONDARY_MANAGERS = 5;

    // Default NAV deviation threshold for new vaults (50% in 1e18 scale, same as Full SuperVaults)
    uint256 private constant DEFAULT_DEVIATION_THRESHOLD = 5e17;

    // Maximum NAV deviation threshold (100% in 1e18 scale). The bound is mandatory for attested-manual
    // NAV, so it can never be raised high enough to effectively disable it.
    uint256 private constant MAX_DEVIATION_THRESHOLD = 1e18;

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
        ManagedSuperVaultController(payable(controller)).initialize(vault, params.feeConfig, params.depositPolicy);

        // Configure the NAV attestor set (the NAV lifecycle lives here in the aggregator).
        // A configured independent attestor set is mandatory.
        uint256 attestorsLen = params.navConfig.attestors.length;
        if (attestorsLen == 0) revert INVALID_ATTESTATION_CONFIG();
        if (params.navConfig.threshold == 0 || params.navConfig.threshold > attestorsLen) {
            revert INVALID_ATTESTATION_CONFIG();
        }
        for (uint256 i; i < attestorsLen; ++i) {
            address attestor = params.navConfig.attestors[i];
            if (attestor == address(0)) revert ZERO_ADDRESS();
            if (!_navAttestors[controller].add(attestor)) revert ATTESTOR_ALREADY_EXISTS();
            emit NAVAttestorAdded(controller, attestor);
        }
        _navThreshold[controller] = params.navConfig.threshold;
        emit NAVAttestationThresholdUpdated(controller, params.navConfig.threshold);

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

        uint256 secondaryLen = params.secondaryManagers.length;
        if (secondaryLen > MAX_SECONDARY_MANAGERS) revert TOO_MANY_SECONDARY_MANAGERS();

        for (uint256 i; i < secondaryLen; ++i) {
            address secondaryManager = params.secondaryManagers[i];

            if (secondaryManager == address(0)) revert ZERO_ADDRESS();
            if (data.mainManager == secondaryManager) revert SECONDARY_MANAGER_CANNOT_BE_PRIMARY();
            if (!data.secondaryManagers.add(secondaryManager)) revert MANAGER_ALREADY_EXISTS();
        }

        // NAV deviation threshold: creation param in bps, stored in 1e18 scale (0 = default 50%,
        // capped at 100% so the mandatory bound can never be effectively disabled)
        if (params.maxUpdateDeviationBps > BPS_PRECISION) revert INVALID_DEVIATION_THRESHOLD();
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
    function proposeNAVUpdate(
        address controller,
        uint256 newPPS,
        uint256 effectiveTimestamp,
        bytes32 evidenceHash,
        string calldata evidenceURI
    )
        external
        validController(controller)
        returns (uint256 proposalId)
    {
        if (!isAnyManager(msg.sender, controller)) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (newPPS == 0) revert INVALID_NAV();
        if (evidenceHash == bytes32(0)) revert EVIDENCE_REQUIRED();
        if (effectiveTimestamp > block.timestamp) revert INVALID_TIMESTAMP();
        if (effectiveTimestamp <= _managedVaultData[controller].lastUpdateTimestamp) revert INVALID_TIMESTAMP();

        // Only one active proposal at a time; an existing pending/in-review proposal must be
        // explicitly cancelled (cancelNAVUpdate) or resolved first
        if (_activeProposalId[controller] != 0) revert NAV_PROPOSAL_PENDING();

        proposalId = ++_nextProposalId[controller];
        _navProposals[controller][proposalId] = IManagedSuperVaultController.NAVUpdateProposal({
            proposedPPS: newPPS,
            effectiveTimestamp: effectiveTimestamp,
            evidenceHash: evidenceHash,
            evidenceURI: evidenceURI,
            proposer: msg.sender,
            attestationCount: 0,
            status: IManagedSuperVaultController.NAVProposalStatus.PendingAttestation
        });
        _activeProposalId[controller] = proposalId;

        emit NAVProposed(
            controller,
            proposalId,
            _managedVaultData[controller].pps,
            newPPS,
            effectiveTimestamp,
            msg.sender,
            evidenceHash,
            evidenceURI
        );
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function attestNAVUpdate(address controller, uint256 proposalId) external validController(controller) {
        if (!_navAttestors[controller].contains(msg.sender)) revert NOT_NAV_ATTESTOR();

        IManagedSuperVaultController.NAVUpdateProposal storage proposal = _navProposals[controller][proposalId];
        if (proposal.status != IManagedSuperVaultController.NAVProposalStatus.PendingAttestation) {
            revert NAV_PROPOSAL_NOT_PENDING();
        }
        if (msg.sender == proposal.proposer) revert ATTESTOR_CANNOT_BE_PROPOSER();
        if (_hasAttested[controller][proposalId][msg.sender]) revert ALREADY_ATTESTED();

        _hasAttested[controller][proposalId][msg.sender] = true;
        proposal.attestationCount += 1;

        emit NAVAttested(controller, proposalId, msg.sender, proposal.attestationCount);

        // Normal path: never bypasses the deviation bound (allowLargeDeviation = false). An out-of-bound
        // proposal moves to ReviewRequired and can only finalize via resolveLargeDeviationNAV.
        if (proposal.attestationCount >= _navThreshold[controller]) {
            _finalizeNAV(controller, proposalId, proposal, proposal.effectiveTimestamp, false);
        }
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelNAVUpdate(address controller, uint256 proposalId) external validController(controller) {
        if (!isAnyManager(msg.sender, controller)) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        IManagedSuperVaultController.NAVUpdateProposal storage proposal = _navProposals[controller][proposalId];
        if (
            proposal.status != IManagedSuperVaultController.NAVProposalStatus.PendingAttestation
                && proposal.status != IManagedSuperVaultController.NAVProposalStatus.ReviewRequired
        ) revert NAV_PROPOSAL_NOT_PENDING();

        proposal.status = IManagedSuperVaultController.NAVProposalStatus.Canceled;
        if (_activeProposalId[controller] == proposalId) _activeProposalId[controller] = 0;

        emit NAVProposalCanceled(controller, proposalId, msg.sender);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function resolveLargeDeviationNAV(address controller, uint256 proposalId) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        IManagedSuperVaultController.NAVUpdateProposal storage proposal = _navProposals[controller][proposalId];
        if (proposal.status != IManagedSuperVaultController.NAVProposalStatus.ReviewRequired) {
            revert NAV_PROPOSAL_NOT_IN_REVIEW();
        }
        if (proposal.attestationCount < _navThreshold[controller]) revert ATTESTATION_THRESHOLD_NOT_MET();

        // Elevated action: the vault auto-paused on the deviation breach; it must have been explicitly
        // unpaused (indexable manager action) before the large-deviation NAV can be finalized. This is
        // the ONLY path that finalizes a NAV exceeding the deviation bound (allowLargeDeviation = true);
        // an ordinary attestation can never bypass the bound, even right after a manual pause/unpause.
        if (_managedVaultData[controller].isPaused) revert MANAGED_VAULT_PAUSED();

        // Re-stamp the NAV at resolve time: the original effective timestamp necessarily predates the
        // deviation pause, which the post-unpause validation would reject.
        _finalizeNAV(controller, proposalId, proposal, block.timestamp, true);
        emit NAVLargeDeviationResolved(controller, proposalId, msg.sender);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function proposeNAVAttestationConfig(
        address controller,
        address[] calldata attestors,
        uint8 threshold
    )
        external
        validController(controller)
    {
        if (msg.sender != _managedVaultData[controller].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        uint256 len = attestors.length;
        if (len == 0 || threshold == 0 || threshold > len) revert INVALID_ATTESTATION_CONFIG();
        for (uint256 i; i < len; ++i) {
            if (attestors[i] == address(0)) revert ZERO_ADDRESS();
            for (uint256 j = i + 1; j < len; ++j) {
                if (attestors[i] == attestors[j]) revert ATTESTOR_ALREADY_EXISTS();
            }
        }

        _pendingAttestors[controller] = attestors;
        _pendingThreshold[controller] = threshold;
        _navConfigEffectiveTime[controller] = block.timestamp + _PARAMETER_CHANGE_TIMELOCK;

        emit NAVAttestationConfigProposed(controller, attestors, threshold, _navConfigEffectiveTime[controller]);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeNAVAttestationConfig(address controller) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (_navConfigEffectiveTime[controller] == 0) revert NO_PENDING_NAV_CONFIG();
        if (block.timestamp < _navConfigEffectiveTime[controller]) revert NAV_CONFIG_TIMELOCK_NOT_EXPIRED();

        // SECURITY: cancel any in-flight proposal so attestations collected under the OLD attestor set
        // cannot finalize under the new set/threshold (no stale-attestation carry across a config swap).
        uint256 activeId = _activeProposalId[controller];
        if (activeId != 0) {
            _navProposals[controller][activeId].status = IManagedSuperVaultController.NAVProposalStatus.Canceled;
            _activeProposalId[controller] = 0;
            emit NAVProposalCanceled(controller, activeId, msg.sender);
        }

        // Clear the current attestor set
        address[] memory current = _navAttestors[controller].values();
        for (uint256 i; i < current.length; ++i) {
            _navAttestors[controller].remove(current[i]);
            emit NAVAttestorRemoved(controller, current[i]);
        }

        // Install the new attestor set + threshold
        address[] memory next = _pendingAttestors[controller];
        for (uint256 i; i < next.length; ++i) {
            _navAttestors[controller].add(next[i]);
            emit NAVAttestorAdded(controller, next[i]);
        }
        _navThreshold[controller] = _pendingThreshold[controller];
        emit NAVAttestationThresholdUpdated(controller, _pendingThreshold[controller]);

        delete _pendingAttestors[controller];
        _pendingThreshold[controller] = 0;
        _navConfigEffectiveTime[controller] = 0;
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelNAVAttestationConfig(address controller) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        if (_navConfigEffectiveTime[controller] == 0) revert NO_PENDING_NAV_CONFIG();

        delete _pendingAttestors[controller];
        _pendingThreshold[controller] = 0;
        _navConfigEffectiveTime[controller] = 0;

        emit NAVAttestationConfigCancelled(controller);
    }

    /// @notice Finalize an attested NAV proposal by attempting to store it
    /// @dev A deviation-bound rejection auto-pauses the vault and returns the proposal to ReviewRequired.
    function _finalizeNAV(
        address controller,
        uint256 proposalId,
        IManagedSuperVaultController.NAVUpdateProposal storage proposal,
        uint256 navTimestamp,
        bool allowLargeDeviation
    )
        internal
    {
        bool accepted = _storeNAV(controller, proposal.proposedPPS, navTimestamp, allowLargeDeviation);

        if (accepted) {
            proposal.status = IManagedSuperVaultController.NAVProposalStatus.Finalized;
            _activeProposalId[controller] = 0;
            emit NAVFinalized(controller, proposalId, proposal.proposedPPS, navTimestamp);
        } else {
            proposal.status = IManagedSuperVaultController.NAVProposalStatus.ReviewRequired;
            emit NAVReviewRequired(controller, proposalId, proposal.proposedPPS, _managedVaultData[controller].pps);
        }
    }

    /// @notice Invalidate any in-flight NAV proposal and pending attestor-config change for a controller
    /// @dev Called when the attestor set or the primary manager changes. This prevents (a) attestations
    ///      collected under an old attestor set from finalizing under a new set, and (b) a NAV proposal or
    ///      a queued attestor-config change left by an outgoing manager from surviving the transition.
    function _invalidatePendingNAV(address controller) internal {
        uint256 activeId = _activeProposalId[controller];
        if (activeId != 0) {
            _navProposals[controller][activeId].status = IManagedSuperVaultController.NAVProposalStatus.Canceled;
            _activeProposalId[controller] = 0;
            emit NAVProposalCanceled(controller, activeId, msg.sender);
        }
        if (_navConfigEffectiveTime[controller] != 0) {
            delete _pendingAttestors[controller];
            _pendingThreshold[controller] = 0;
            _navConfigEffectiveTime[controller] = 0;
            emit NAVAttestationConfigCancelled(controller);
        }
    }

    /// @notice Store a finalized attested NAV, enforcing freshness/monotonicity/deviation invariants
    /// @dev Internal: only reachable via _finalizeNAV (attestation or elevated resolve path). A
    ///      deviation-bound failure auto-pauses the vault, marks NAV stale, drops the value, returns false.
    ///      The deviation check is bypassed only when allowLargeDeviation is set (resolve path).
    function _storeNAV(
        address controller,
        uint256 newPPS,
        uint256 timestamp,
        bool allowLargeDeviation
    )
        internal
        returns (bool)
    {
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

        // [Deviation Threshold] Large deviations auto-pause the vault and drop the value. The check is
        // bypassed ONLY when the controller passes allowLargeDeviation (its elevated resolve path) — a
        // manual pause/unpause leaves navStale set but can never bypass the bound on the normal path.
        uint256 currentPPS = data.pps;
        if (!allowLargeDeviation && data.deviationThreshold != type(uint256).max && currentPPS > 0) {
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
        // Serialize skims against the NAV lifecycle: a skim bumps lastUpdateTimestamp, which would
        // otherwise stall an in-flight proposal on the monotonicity check at finalize. Resolve or
        // cancel the active proposal before skimming.
        if (_activeProposalId[controller] != 0) revert NAV_PROPOSAL_PENDING();
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
    function proposeDeviationThresholdChange(
        address controller,
        uint256 deviationThreshold_
    )
        external
        validController(controller)
    {
        if (msg.sender != _managedVaultData[controller].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }
        // Cannot disable or loosen beyond 100%; the bound is mandatory for attested-manual NAV
        if (deviationThreshold_ == 0 || deviationThreshold_ > MAX_DEVIATION_THRESHOLD) {
            revert INVALID_DEVIATION_THRESHOLD();
        }

        uint256 effectiveTime = block.timestamp + _PARAMETER_CHANGE_TIMELOCK;
        _managedVaultData[controller].proposedDeviationThreshold = deviationThreshold_;
        _managedVaultData[controller].deviationThresholdEffectiveTime = effectiveTime;

        emit DeviationThresholdChangeProposed(controller, deviationThreshold_, effectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function executeDeviationThresholdChange(address controller) external validController(controller) {
        if (_managedVaultData[controller].deviationThresholdEffectiveTime == 0) {
            revert NO_PENDING_DEVIATION_THRESHOLD_CHANGE();
        }
        if (block.timestamp < _managedVaultData[controller].deviationThresholdEffectiveTime) {
            revert TIMELOCK_NOT_EXPIRED();
        }

        uint256 newThreshold = _managedVaultData[controller].proposedDeviationThreshold;

        _managedVaultData[controller].proposedDeviationThreshold = 0;
        _managedVaultData[controller].deviationThresholdEffectiveTime = 0;

        _managedVaultData[controller].deviationThreshold = newThreshold;

        emit DeviationThresholdUpdated(controller, newThreshold);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function cancelDeviationThresholdChange(address controller) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }
        if (_managedVaultData[controller].deviationThresholdEffectiveTime == 0) {
            revert NO_PENDING_DEVIATION_THRESHOLD_CHANGE();
        }

        uint256 cancelled = _managedVaultData[controller].proposedDeviationThreshold;
        _managedVaultData[controller].proposedDeviationThreshold = 0;
        _managedVaultData[controller].deviationThresholdEffectiveTime = 0;

        emit DeviationThresholdChangeCancelled(controller, cancelled);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    /// @dev Event-only: the URI is not stored onchain; indexers read the latest from this event
    function updateMetadataURI(address controller, string calldata metadataURI) external validController(controller) {
        if (msg.sender != _managedVaultData[controller].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

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
        // SECURITY: drop any pending deviation-threshold loosening queued by the outgoing manager
        _managedVaultData[controller].proposedDeviationThreshold = 0;
        _managedVaultData[controller].deviationThresholdEffectiveTime = 0;
        // SECURITY: invalidate any in-flight NAV proposal / queued attestor-config change
        _invalidatePendingNAV(controller);

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
        _managedVaultData[controller].proposedDeviationThreshold = 0;
        _managedVaultData[controller].deviationThresholdEffectiveTime = 0;
        // SECURITY: invalidate any in-flight NAV proposal / queued attestor-config change
        _invalidatePendingNAV(controller);

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
    function getProposedDeviationThreshold(address controller)
        external
        view
        returns (uint256 proposedThreshold, uint256 effectiveTime)
    {
        return (
            _managedVaultData[controller].proposedDeviationThreshold,
            _managedVaultData[controller].deviationThresholdEffectiveTime
        );
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getNAVProposal(
        address controller,
        uint256 proposalId
    )
        external
        view
        returns (IManagedSuperVaultController.NAVUpdateProposal memory proposal)
    {
        return _navProposals[controller][proposalId];
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getActiveNAVProposalId(address controller) external view returns (uint256 proposalId) {
        return _activeProposalId[controller];
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getNAVAttestationConfig(address controller)
        external
        view
        returns (address[] memory attestors, uint8 threshold)
    {
        return (_navAttestors[controller].values(), _navThreshold[controller]);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function getPendingNAVAttestationConfig(address controller)
        external
        view
        returns (address[] memory attestors, uint8 threshold, uint256 effectiveTime)
    {
        return (_pendingAttestors[controller], _pendingThreshold[controller], _navConfigEffectiveTime[controller]);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function isNAVAttestor(address controller, address attestor) external view returns (bool) {
        return _navAttestors[controller].contains(attestor);
    }

    /// @inheritdoc IManagedSuperVaultAggregator
    function hasAttested(address controller, uint256 proposalId, address attestor) external view returns (bool) {
        return _hasAttested[controller][proposalId][attestor];
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
