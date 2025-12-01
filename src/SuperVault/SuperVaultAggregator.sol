// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Superform
import { SuperVault } from "./SuperVault.sol";
import { SuperVaultStrategy } from "./SuperVaultStrategy.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { SuperVaultEscrow } from "./SuperVaultEscrow.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
// Libraries
import { AssetMetadataLib } from "../libraries/AssetMetadataLib.sol";

/// @title SuperVaultAggregator
/// @author Superform Labs
/// @notice Registry and PPS oracle for all SuperVaults
/// @dev Creates new SuperVault trios and manages PPS updates
contract SuperVaultAggregator is ISuperVaultAggregator {
    using AssetMetadataLib for address;
    using Clones for address;
    using SafeERC20 for IERC20;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    // Vault implementation contracts
    address public immutable VAULT_IMPLEMENTATION;
    address public immutable STRATEGY_IMPLEMENTATION;
    address public immutable ESCROW_IMPLEMENTATION;

    // Governance
    ISuperGovernor public immutable SUPER_GOVERNOR;

    // Claimable upkeep
    uint256 public claimableUpkeep;

    // Strategy data storage
    mapping(address strategy => StrategyData) private _strategyData;

    // Upkeep balances (per strategy)
    mapping(address strategy => uint256 upkeep) private _strategyUpkeepBalance;

    // Two-step upkeep withdrawal system
    mapping(address strategy => UpkeepWithdrawalRequest) public pendingUpkeepWithdrawals;

    // Registry of created vaults
    EnumerableSet.AddressSet private _superVaults;
    EnumerableSet.AddressSet private _superVaultStrategies;
    EnumerableSet.AddressSet private _superVaultEscrows;

    // Constant for basis points precision (100% = 10,000 bps)
    uint256 private constant BPS_PRECISION = 10_000;

    // Maximum performance fee allowed (51%)
    uint256 private constant MAX_PERFORMANCE_FEE = 5100;

    // Maximum number of secondary managers per strategy to prevent governance DoS on manager replacement
    uint256 public constant MAX_SECONDARY_MANAGERS = 5;

    // Default deviation threshold for new strategies (50% in 1e18 scale)
    uint256 private constant DEFAULT_DEVIATION_THRESHOLD = 5e17;

    // Timelock for upkeep withdrawal (24 hours)
    uint256 public constant UPKEEP_WITHDRAWAL_TIMELOCK = 24 hours;

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
        if (!SUPER_GOVERNOR.isActivePPSOracle(msg.sender)) {
            revert UNAUTHORIZED_PPS_ORACLE();
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
    /// @notice Initializes the SuperVaultAggregator
    /// @param superGovernor_ Address of the SuperGovernor contract
    /// @param vaultImpl_ Address of the pre-deployed SuperVault implementation
    /// @param strategyImpl_ Address of the pre-deployed SuperVaultStrategy implementation
    /// @param escrowImpl_ Address of the pre-deployed SuperVaultEscrow implementation
    constructor(address superGovernor_, address vaultImpl_, address strategyImpl_, address escrowImpl_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        if (vaultImpl_ == address(0)) revert ZERO_ADDRESS();
        if (strategyImpl_ == address(0)) revert ZERO_ADDRESS();
        if (escrowImpl_ == address(0)) revert ZERO_ADDRESS();

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        VAULT_IMPLEMENTATION = vaultImpl_;
        STRATEGY_IMPLEMENTATION = strategyImpl_;
        ESCROW_IMPLEMENTATION = escrowImpl_;
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT CREATION
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultAggregator
    function createVault(VaultCreationParams calldata params)
        external
        returns (address superVault, address strategy, address escrow)
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

        // Initialize superVault
        SuperVault(superVault).initialize(params.asset, params.name, params.symbol, strategy, escrow);

        // Initialize escrow
        SuperVaultEscrow(escrow).initialize(superVault);

        // Initialize strategy
        SuperVaultStrategy(payable(strategy)).initialize(superVault, params.feeConfig);

        // Store vault trio in registry
        _superVaults.add(superVault);
        _superVaultStrategies.add(strategy);
        _superVaultEscrows.add(escrow);

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

        emit VaultDeployed(superVault, strategy, escrow, params.asset, params.name, params.symbol, vars.currentNonce);
        emit PPSUpdated(strategy, vars.initialPPS, _strategyData[strategy].lastUpdateTimestamp);

        return (superVault, strategy, escrow);
    }

    /*//////////////////////////////////////////////////////////////
                          PPS UPDATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultAggregator
    function forwardPPS(ForwardPPSArgs calldata args) external onlyPPSOracle {
        bool paymentsEnabled = SUPER_GOVERNOR.isUpkeepPaymentsEnabled();

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

            uint256 upkeepCost = 0;
            if (paymentsEnabled) {
                // Query cost directly per entry
                // Everyone pays the upkeep cost
                try SUPER_GOVERNOR.getUpkeepCostPerSingleUpdate(msg.sender) returns (uint256 cost) {
                    upkeepCost = cost;
                } catch {
                    // If upkeep cost computation fails (e.g., oracle misconfiguration),
                    // allow PPS update to proceed without charging upkeep.
                    upkeepCost = 0;
                }
            }

            _forwardPPS(
                PPSUpdateData({
                    strategy: strategy,
                    // isExempt when upkeepCost is 0 (covers both paymentsDisabled and oracle failures)
                    isExempt: upkeepCost == 0,
                    pps: args.ppss[i],
                    timestamp: ts,
                    upkeepCost: upkeepCost
                })
            );
        }
    }

    /// @inheritdoc ISuperVaultAggregator
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
                        UPKEEP MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultAggregator
    function depositUpkeep(address strategy, uint256 amount) external validStrategy(strategy) {
        if (amount == 0) revert ZERO_AMOUNT();

        // Get the UPKEEP_TOKEN address from SUPER_GOVERNOR
        address upkeepToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UPKEEP_TOKEN());

        // Transfer UPKEEP_TOKEN from msg.sender to this contract
        IERC20(upkeepToken).safeTransferFrom(msg.sender, address(this), amount);

        // Update upkeep balance for this strategy
        _strategyUpkeepBalance[strategy] += amount;

        emit UpkeepDeposited(strategy, msg.sender, amount);
    }

    /// @inheritdoc ISuperVaultAggregator
    function claimUpkeep(uint256 amount) external {
        // Only SUPER_GOVERNOR can claim upkeep
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert CALLER_NOT_AUTHORIZED();
        }

        if (claimableUpkeep < amount) revert INSUFFICIENT_UPKEEP();
        claimableUpkeep -= amount;

        // Get the UPKEEP_TOKEN address from SUPER_GOVERNOR
        address upkeepToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UPKEEP_TOKEN());

        // Transfer UPKEEP_TOKEN to `SuperBank`
        address _superBank = _getSuperBank();
        IERC20(upkeepToken).safeTransfer(_superBank, amount);
        emit UpkeepClaimed(_superBank, amount);
    }

    /// @inheritdoc ISuperVaultAggregator
    function proposeWithdrawUpkeep(address strategy) external validStrategy(strategy) {
        // Only mainManager can propose upkeep withdrawal from a strategy
        if (msg.sender != _strategyData[strategy].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Get current strategy upkeep balance (full balance withdrawal)
        uint256 currentBalance = _strategyUpkeepBalance[strategy];
        if (currentBalance == 0) revert ZERO_AMOUNT();

        // Create withdrawal request
        pendingUpkeepWithdrawals[strategy] = UpkeepWithdrawalRequest({
            amount: currentBalance, effectiveTime: block.timestamp + UPKEEP_WITHDRAWAL_TIMELOCK
        });

        emit UpkeepWithdrawalProposed(
            strategy, msg.sender, currentBalance, block.timestamp + UPKEEP_WITHDRAWAL_TIMELOCK
        );
    }

    /// @inheritdoc ISuperVaultAggregator
    function executeWithdrawUpkeep(address strategy) external validStrategy(strategy) {
        UpkeepWithdrawalRequest memory request = pendingUpkeepWithdrawals[strategy];

        // Check that a request exists
        if (request.effectiveTime == 0) revert UPKEEP_WITHDRAWAL_NOT_FOUND();

        // Check that timelock has passed
        if (block.timestamp < request.effectiveTime) revert UPKEEP_WITHDRAWAL_NOT_READY();

        // Calculate actual withdrawal amount (use current balance, may be less if upkeep was spent)
        uint256 currentBalance = _strategyUpkeepBalance[strategy];
        uint256 withdrawalAmount = currentBalance < request.amount ? currentBalance : request.amount;

        if (withdrawalAmount == 0) revert ZERO_AMOUNT();

        // Clear the pending request
        delete pendingUpkeepWithdrawals[strategy];

        // Get the UPKEEP_TOKEN address from SUPER_GOVERNOR
        address upkeepToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UPKEEP_TOKEN());

        // Update upkeep balance
        unchecked {
            _strategyUpkeepBalance[strategy] -= withdrawalAmount;
        }

        // Transfer UPKEEP_TOKEN to the original main manager (not msg.sender)
        address mainManager = _strategyData[strategy].mainManager;
        IERC20(upkeepToken).safeTransfer(mainManager, withdrawalAmount);

        emit UpkeepWithdrawn(strategy, mainManager, withdrawalAmount);
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
    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
    function removeSecondaryManager(address strategy, address manager) external validStrategy(strategy) {
        // Only the primary manager can remove secondary managers
        if (msg.sender != _strategyData[strategy].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        // Remove the manager using EnumerableSet
        if (!_strategyData[strategy].secondaryManagers.remove(manager)) revert MANAGER_NOT_FOUND();

        emit SecondaryManagerRemoved(strategy, manager);
    }

    /// @inheritdoc ISuperVaultAggregator
    function updateDeviationThreshold(address strategy, uint256 deviationThreshold_) external validStrategy(strategy) {
        // Since this is a risky call, we only allow main managers as callers
        if (msg.sender != _strategyData[strategy].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Update the threshold
        _strategyData[strategy].deviationThreshold = deviationThreshold_;

        // Emit the event
        emit DeviationThresholdUpdated(strategy, deviationThreshold_);
    }

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
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
        // Only SuperGovernor can call this
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

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

        // SECURITY: Cancel any pending upkeep withdrawal to prevent old manager from withdrawing
        if (pendingUpkeepWithdrawals[strategy].effectiveTime != 0) {
            delete pendingUpkeepWithdrawals[strategy];
            emit UpkeepWithdrawalCancelled(strategy);
        }

        // Set the new primary manager
        _strategyData[strategy].mainManager = newManager;

        // Set the new fee recipient
        ISuperVaultStrategy(strategy).changeFeeRecipient(feeRecipient);

        emit PrimaryManagerChanged(strategy, oldManager, newManager, feeRecipient);
    }

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
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

        // Cancel any pending upkeep withdrawal to ensure clean transition
        if (pendingUpkeepWithdrawals[strategy].effectiveTime != 0) {
            delete pendingUpkeepWithdrawals[strategy];
            emit UpkeepWithdrawalCancelled(strategy);
        }

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

    /// @inheritdoc ISuperVaultAggregator
    /// @dev SECURITY: This function is intended to be used by governance to onboard a new manager without penalizing
    /// them for the previous manager's performance.
    /// @dev If a manager is replaced while the strategy is below its
    /// previous HWM, the new manager would otherwise inherit a "loss" state and be unable to earn performance fees
    /// until the fee config are updated after the week timelock.
    /// @dev Calling this function resets the HWM to the current PPS, allowing a newly appointed manager to start from a
    /// neutral baseline. @dev This function is only callable by SUPER_GOVERNOR
    function resetHighWaterMark(address strategy) external validStrategy(strategy) {
        // Only SuperGovernor can call this
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        uint256 newHwmPps = _strategyData[strategy].pps;

        // Reset the High Water Mark to the current PPS
        ISuperVaultStrategy(strategy).resetHighWaterMark(newHwmPps);

        emit HighWaterMarkReset(strategy, newHwmPps);
    }

    /*//////////////////////////////////////////////////////////////
                        HOOK VALIDATION FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultAggregator
    function setHooksRootUpdateTimelock(uint256 newTimelock) external {
        // Only SUPER_GOVERNOR can update the timelock
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Update the timelock
        _hooksRootUpdateTimelock = newTimelock;

        emit HooksRootUpdateTimelockChanged(newTimelock);
    }

    /// @inheritdoc ISuperVaultAggregator
    function proposeGlobalHooksRoot(bytes32 newRoot) external {
        // Only SUPER_GOVERNOR can update the global hooks root
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Set new root with timelock
        _proposedGlobalHooksRoot = newRoot;
        uint256 effectiveTime = block.timestamp + _hooksRootUpdateTimelock;
        _globalHooksRootEffectiveTime = effectiveTime;

        emit GlobalHooksRootUpdateProposed(newRoot, effectiveTime);
    }

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
    function setGlobalHooksRootVetoStatus(bool vetoed) external {
        // Only SuperGovernor can call this
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Don't emit event if status doesn't change
        if (_globalHooksRootVetoed == vetoed) {
            return;
        }

        // Update veto status
        _globalHooksRootVetoed = vetoed;

        emit GlobalHooksRootVetoStatusChanged(vetoed, _globalHooksRoot);
    }

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
    function setStrategyHooksRootVetoStatus(address strategy, bool vetoed) external validStrategy(strategy) {
        // Only SuperGovernor can call this
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

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

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
    function getProposedMinUpdateInterval(address strategy)
        external
        view
        returns (uint256 proposedInterval, uint256 effectiveTime)
    {
        return (
            _strategyData[strategy].proposedMinUpdateInterval, _strategyData[strategy].minUpdateIntervalEffectiveTime
        );
    }

    /// @inheritdoc ISuperVaultAggregator
    function isGlobalHooksRootVetoed() external view returns (bool vetoed) {
        return _globalHooksRootVetoed;
    }

    /// @inheritdoc ISuperVaultAggregator
    function isStrategyHooksRootVetoed(address strategy) external view returns (bool vetoed) {
        return _strategyData[strategy].hooksRootVetoed;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultAggregator
    function getSuperVaultsCount() external view returns (uint256) {
        return _superVaults.length();
    }

    /// @inheritdoc ISuperVaultAggregator
    function getSuperVaultStrategiesCount() external view returns (uint256) {
        return _superVaultStrategies.length();
    }

    /// @inheritdoc ISuperVaultAggregator
    function getSuperVaultEscrowsCount() external view returns (uint256) {
        return _superVaultEscrows.length();
    }

    /// @inheritdoc ISuperVaultAggregator
    function getCurrentNonce() external view returns (uint256) {
        return _vaultCreationNonce;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getHooksRootUpdateTimelock() external view returns (uint256) {
        return _hooksRootUpdateTimelock;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getPPS(address strategy) external view validStrategy(strategy) returns (uint256 pps) {
        return _strategyData[strategy].pps;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getLastUpdateTimestamp(address strategy) external view returns (uint256 timestamp) {
        return _strategyData[strategy].lastUpdateTimestamp;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getMinUpdateInterval(address strategy) external view returns (uint256 interval) {
        return _strategyData[strategy].minUpdateInterval;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getMaxStaleness(address strategy) external view returns (uint256 staleness) {
        return _strategyData[strategy].maxStaleness;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getDeviationThreshold(address strategy)
        external
        view
        validStrategy(strategy)
        returns (uint256 deviationThreshold)
    {
        return _strategyData[strategy].deviationThreshold;
    }

    /// @inheritdoc ISuperVaultAggregator
    function isStrategyPaused(address strategy) external view returns (bool isPaused) {
        return _strategyData[strategy].isPaused;
    }

    /// @inheritdoc ISuperVaultAggregator
    function isPPSStale(address strategy) external view returns (bool isStale) {
        return _strategyData[strategy].ppsStale;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getLastUnpauseTimestamp(address strategy) external view returns (uint256 timestamp) {
        return _strategyData[strategy].lastUnpauseTimestamp;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getUpkeepBalance(address strategy) external view returns (uint256 balance) {
        return _strategyUpkeepBalance[strategy];
    }

    /// @inheritdoc ISuperVaultAggregator
    function getMainManager(address strategy) external view returns (address manager) {
        return _strategyData[strategy].mainManager;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getPendingManagerChange(address strategy)
        external
        view
        returns (address proposedManager, uint256 effectiveTime)
    {
        return (_strategyData[strategy].proposedManager, _strategyData[strategy].managerChangeEffectiveTime);
    }

    /// @inheritdoc ISuperVaultAggregator
    function isMainManager(address manager, address strategy) public view returns (bool) {
        return _strategyData[strategy].mainManager == manager;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getSecondaryManagers(address strategy) external view returns (address[] memory) {
        return _strategyData[strategy].secondaryManagers.values();
    }

    /// @inheritdoc ISuperVaultAggregator
    function isSecondaryManager(address manager, address strategy) external view returns (bool) {
        return _strategyData[strategy].secondaryManagers.contains(manager);
    }

    /// @inheritdoc ISuperVaultAggregator
    function isAnyManager(address manager, address strategy) public view returns (bool) {
        // Single storage pointer read instead of multiple
        StrategyData storage data = _strategyData[strategy];
        return (data.mainManager == manager) || data.secondaryManagers.contains(manager);
    }

    /// @inheritdoc ISuperVaultAggregator
    function getAllSuperVaults() external view returns (address[] memory) {
        return _superVaults.values();
    }

    /// @inheritdoc ISuperVaultAggregator
    function superVaults(uint256 index) external view returns (address) {
        if (index >= _superVaults.length()) revert INDEX_OUT_OF_BOUNDS();
        return _superVaults.at(index);
    }

    /// @inheritdoc ISuperVaultAggregator
    function getAllSuperVaultStrategies() external view returns (address[] memory) {
        return _superVaultStrategies.values();
    }

    /// @inheritdoc ISuperVaultAggregator
    function superVaultStrategies(uint256 index) external view returns (address) {
        if (index >= _superVaultStrategies.length()) revert INDEX_OUT_OF_BOUNDS();
        return _superVaultStrategies.at(index);
    }

    /// @inheritdoc ISuperVaultAggregator
    function getAllSuperVaultEscrows() external view returns (address[] memory) {
        return _superVaultEscrows.values();
    }

    /// @inheritdoc ISuperVaultAggregator
    function superVaultEscrows(uint256 index) external view returns (address) {
        if (index >= _superVaultEscrows.length()) revert INDEX_OUT_OF_BOUNDS();
        return _superVaultEscrows.at(index);
    }

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
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

    /// @inheritdoc ISuperVaultAggregator
    function getGlobalHooksRoot() external view returns (bytes32 root) {
        return _globalHooksRoot;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getProposedGlobalHooksRoot() external view returns (bytes32 root, uint256 effectiveTime) {
        return (_proposedGlobalHooksRoot, _globalHooksRootEffectiveTime);
    }

    /// @notice Checks if the global hooks root is active (timelock period has passed)
    /// @return isActive True if the global hooks root is active
    function isGlobalHooksRootActive() external view returns (bool) {
        return block.timestamp >= _globalHooksRootEffectiveTime && _globalHooksRoot != bytes32(0);
    }

    /// @inheritdoc ISuperVaultAggregator
    function getStrategyHooksRoot(address strategy) external view returns (bytes32 root) {
        return _strategyData[strategy].managerHooksRoot;
    }

    /// @inheritdoc ISuperVaultAggregator
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
    /// @dev Implements Properties 7-11 from /security/security_properties.md:
    ///      - Property 7: Timestamp Monotonicity (line 1213)
    ///      - Property 8: Post-Unpause Timestamp Validation / C1-RE_ANCHOR (line 1222)
    ///      - Property 9: Rate Limit Enforcement (line 1231)
    ///      - Property 10: Deviation Threshold / C1 Check (line 1242)
    ///      - Property 11: Upkeep Balance Check (line 1284)
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

        // [Property 11: Upkeep Balance Check]
        // Ensure the strategy has sufficient upkeep balance to pay for this update.
        // If insufficient, auto-pause the strategy and mark PPS as stale to protect against
        // continued operation without proper oracle funding.
        uint256 strategyUpkeepBalance = _strategyUpkeepBalance[args.strategy];
        if (!args.isExempt) {
            // Check if strategy has sufficient upkeep balance
            if (strategyUpkeepBalance < args.upkeepCost) {
                _strategyData[args.strategy].isPaused = true;
                _strategyData[args.strategy].ppsStale = true;
                emit StrategyPaused(args.strategy);
                emit StrategyPPSStale(args.strategy);
                emit InsufficientUpkeep(args.strategy, args.strategy, strategyUpkeepBalance, args.upkeepCost);
                return;
            }

            // Deduct the upkeep cost and emit event
            _strategyUpkeepBalance[args.strategy] -= args.upkeepCost;

            // Add claimable upkeep for the `feeRecipient`
            claimableUpkeep += args.upkeepCost;

            emit UpkeepSpent(args.strategy, args.upkeepCost, strategyUpkeepBalance, claimableUpkeep);
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

    /**
     * @dev Internal function to return the `SuperBank` address
     * @return superBank The superBank address
     */
    function _getSuperBank() internal view returns (address) {
        return SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.SUPER_BANK());
    }
}
