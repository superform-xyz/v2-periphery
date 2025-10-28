// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

// External
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

// Superform
import { SuperVault } from "./SuperVault.sol";
import { SuperVaultStrategy } from "./SuperVaultStrategy.sol";
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

    // Upkeep balances
    mapping(address manager => uint256 upkeep) private _managerUpkeepBalance;

    // Stake balances
    mapping(address manager => uint256 stake) private _managerStakeBalance;

    // Withdraw stake requests
    mapping(address manager => WithdrawStakeRequest withdrawalRequest) public managerWithdrawalRequests;

    // Registry of created vaults
    EnumerableSet.AddressSet private _superVaults;
    EnumerableSet.AddressSet private _superVaultStrategies;
    EnumerableSet.AddressSet private _superVaultEscrows;

    // Constant for PPS decimals
    uint256 public constant PPS_DECIMALS = 18;

    // Maximum number of secondary managers per strategy to prevent governance DoS on manager replacement
    uint256 public constant MAX_SECONDARY_MANAGERS = 5;

    // Time lock for stake withdrawal requests
    uint256 public constant WITHDRAW_STAKE_TIMELOCK = 7 days;
    uint256 public constant WITHDRAWAL_REQUEST_TIMEOUT = 10 days;

    // Timelock for manager changes and Merkle root updates
    uint256 private constant _MANAGER_CHANGE_TIMELOCK = 7 days;
    // Default unpause timelock
    uint256 private constant _MAX_UNPAUSE_TIMELOCK = 1 days;
    uint256 private _hooksRootUpdateTimelock = 15 minutes;

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
        if (!SUPER_GOVERNOR.isActivePPSOracle(msg.sender)) {
            revert UNAUTHORIZED_PPS_ORACLE();
        }
        _;
    }

    /// @notice Validates that a strategy exists (has been created by this aggregator)
    modifier validStrategy(address strategy) {
        if (!_superVaultStrategies.contains(strategy)) revert UNKNOWN_STRATEGY();
        _;
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
            revert ZERO_AMOUNT();
        }

        // Initialize local variables struct to avoid stack too deep
        VaultCreationLocalVars memory vars;

        // Increment nonce before creating proxies
        vars.currentNonce = _vaultCreationNonce++;
        vars.salt = keccak256(abi.encode(msg.sender, params.asset, params.name, params.symbol, vars.currentNonce));

        // Create minimal proxies
        superVault = VAULT_IMPLEMENTATION.cloneDeterministic(vars.salt);
        escrow = ESCROW_IMPLEMENTATION.cloneDeterministic(vars.salt);
        strategy = STRATEGY_IMPLEMENTATION.cloneDeterministic(vars.salt);

        // Initialize superVault
        SuperVault(superVault).initialize(params.asset, params.name, params.symbol, strategy, escrow);

        // Initialize escrow
        SuperVaultEscrow(escrow).initialize(superVault, strategy);

        // Initialize strategy
        SuperVaultStrategy(payable(strategy)).initialize(superVault, params.feeConfig);

        // Store vault trio in registry
        _superVaults.add(superVault);
        _superVaultStrategies.add(strategy);
        _superVaultEscrows.add(escrow);

        // Get asset decimals
        (bool success, uint8 assetDecimals) = params.asset.tryGetAssetDecimals();
        if (!success) revert INVALID_ASSET();
        vars.initialPPS = 10 ** assetDecimals; // 1.0 as initial PPS

        // Validate maxStaleness against minimum required staleness
        if (params.maxStaleness < SUPER_GOVERNOR.getMinStaleness()) {
            revert MAX_STALENESS_TOO_LOW();
        }

        // Initialize StrategyData individually to avoid mapping assignment issues
        _strategyData[strategy].pps = vars.initialPPS;
        // Initialize standard deviation to 0
        _strategyData[strategy].lastUpdateTimestamp = block.timestamp;
        _strategyData[strategy].minUpdateInterval = params.minUpdateInterval;
        _strategyData[strategy].maxStaleness = params.maxStaleness;
        _strategyData[strategy].isPaused = false;
        _strategyData[strategy].mainManager = params.mainManager;
        _strategyData[strategy].maxUnpauseTimeLock =
            params.maxUnpauseTimeLock > 0 ? params.maxUnpauseTimeLock : _MAX_UNPAUSE_TIMELOCK;

        uint256 secondaryLen = params.secondaryManagers.length;
        for (uint256 i; i < secondaryLen; ++i) {
            _strategyData[strategy].secondaryManagers.add(params.secondaryManagers[i]);
        }
        if (_strategyData[strategy].secondaryManagers.length() > MAX_SECONDARY_MANAGERS) {
            revert TOO_MANY_SECONDARY_MANAGERS();
        }

        // Set default threshold values
        _strategyData[strategy].dispersionThreshold = type(uint256).max; // Default: max (disabled)
        _strategyData[strategy].deviationThreshold = type(uint256).max; // Default: max (disabled)

        emit VaultDeployed(superVault, strategy, escrow, params.asset, params.name, params.symbol, vars.currentNonce);
        emit PPSUpdated(strategy, vars.initialPPS, 0, 0, 0, _strategyData[strategy].lastUpdateTimestamp);

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
            if (ts > block.timestamp) {
                emit ProvidedTimestampExceedsBlockTimestamp(strategy, ts, block.timestamp);
                continue;
            }

            uint256 upkeepCost = 0;
            if (paymentsEnabled) {
                StrategyData storage data = _strategyData[strategy];
                // Check staleness
                if (data.isPaused) {
                    emit PaymentSkippedForPausedStrategy(strategy);
                } else if (block.timestamp - ts > data.maxStaleness) {
                    emit StaleUpdate(strategy, args.updateAuthority, ts);
                } else {
                    // Query cost directly per entry
                    upkeepCost = SUPER_GOVERNOR.getUpkeepCostPerSingleUpdate(msg.sender);
                }
            }

            _forwardPPS(
                PPSUpdateData({
                    strategy: strategy,
                    isExempt: (!paymentsEnabled) || (upkeepCost == 0),
                    pps: args.ppss[i],
                    ppsStdev: args.ppsStdevs[i],
                    validatorSet: args.validatorSets[i],
                    totalValidators: args.totalValidator,
                    timestamp: ts,
                    upkeepCost: upkeepCost
                })
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                        UPKEEP MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultAggregator
    function depositUpkeep(address manager, uint256 amount) external {
        if (amount == 0) revert ZERO_AMOUNT();

        // Get the UP token address from SUPER_GOVERNOR
        address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());

        // Transfer UP tokens from msg.sender to this contract
        IERC20(upToken).safeTransferFrom(msg.sender, address(this), amount);

        // Update upkeep balance
        _managerUpkeepBalance[manager] += amount;

        emit UpkeepDeposited(manager, amount);
    }

    /// @inheritdoc ISuperVaultAggregator
    function claimUpkeep(uint256 amount) external {
        // Only SUPER_GOVERNOR can claim upkeep
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert CALLER_NOT_AUTHORIZED();
        }

        if (claimableUpkeep < amount) revert INSUFFICIENT_UPKEEP();
        claimableUpkeep -= amount;

        // Get the UP token address from SUPER_GOVERNOR
        address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());

        // Transfer UP tokens to `SuperBank`
        address _superBank = _getSuperBank();
        IERC20(upToken).safeTransfer(_superBank, amount);
        emit UpkeepClaimed(_superBank, amount);
    }

    /// @inheritdoc ISuperVaultAggregator
    function withdrawUpkeep(uint256 amount) external {
        if (amount == 0) revert ZERO_AMOUNT();

        // Check sufficient balance
        if (_managerUpkeepBalance[msg.sender] < amount) {
            revert INSUFFICIENT_UPKEEP_BALANCE();
        }

        // Get the UP token address from SUPER_GOVERNOR
        address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());

        // Update upkeep balance
        /// @dev unchecked because amount validated above
        unchecked {
            _managerUpkeepBalance[msg.sender] -= amount;
        }

        // Transfer UP tokens to manager
        IERC20(upToken).safeTransfer(msg.sender, amount);

        emit UpkeepWithdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Manually unpauses a strategy
    /// @param strategy Address of the strategy to unpause
    /// @dev Only the main manager of the strategy can unpause it
    function unpauseStrategy(address strategy) external validStrategy(strategy) {
        // Allow only the UNPAUSER_ROLE to unpause
        if (!_isUnpauser(msg.sender)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Check if strategy is currently paused
        if (!_strategyData[strategy].isPaused) {
            revert STRATEGY_NOT_PAUSED();
        }

        uint256 lastUpdateTimestamp = _strategyData[strategy].lastUpdateTimestamp;
        if (block.timestamp - lastUpdateTimestamp >= _strategyData[strategy].maxUnpauseTimeLock) {
            revert UNPAUSE_TIMELOCK_NOT_MET();
        }

        // Unpause the strategy
        _strategyData[strategy].isPaused = false;
        _strategyData[strategy].ppsStale = true;
        emit StrategyUnpaused(strategy);
    }

    /*//////////////////////////////////////////////////////////////
                        STAKE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposits UP tokens as stake for manager economic security
    /// @param manager Address of the manager to deposit stake for
    /// @param amount Amount of UP tokens to deposit as stake
    function depositStake(address manager, uint256 amount) external {
        if (amount == 0) revert ZERO_AMOUNT();
        if (manager == address(0)) revert ZERO_ADDRESS();

        // Get the UP token address from SUPER_GOVERNOR
        address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());

        // Transfer UP tokens from msg.sender to this contract
        IERC20(upToken).safeTransferFrom(msg.sender, address(this), amount);

        // Update stake balance
        _managerStakeBalance[manager] += amount;

        emit StakeDeposited(manager, amount);
    }

    /// @inheritdoc ISuperVaultAggregator
    function requestStakeWithdrawal(uint256 amount) external {
        if (amount == 0) revert ZERO_AMOUNT();

        // Check sufficient balance
        if (_managerStakeBalance[msg.sender] < amount) {
            revert INSUFFICIENT_STAKE_BALANCE();
        }

        // Create withdrawal request
        managerWithdrawalRequests[msg.sender] = WithdrawStakeRequest({ amount: amount, timestamp: block.timestamp });

        emit StakeWithdrawRequested(msg.sender, amount);
    }

    function completeStakeWithdrawal() external {
        WithdrawStakeRequest memory request = managerWithdrawalRequests[msg.sender];

        if (request.amount == 0 || request.timestamp == 0) revert WITHDRAW_STAKE_REQUEST_NOT_FOUND();

        if (request.timestamp + WITHDRAW_STAKE_TIMELOCK > block.timestamp) {
            revert WITHDRAW_STAKE_REQUEST_NOT_READY();
        }

        if (block.timestamp > request.timestamp + WITHDRAWAL_REQUEST_TIMEOUT) {
            revert WITHDRAWAL_REQUEST_EXPIRED();
        }

        /// Get the UP token address from SUPER_GOVERNOR
        address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());

        // Update stake balance
        /// @dev re-check for sufficient balance in case slashing occurred
        if (_managerStakeBalance[msg.sender] >= request.amount) {
            _managerStakeBalance[msg.sender] -= request.amount;
        } else {
            revert INSUFFICIENT_STAKE_BALANCE();
        }

        // Clear withdrawal request
        delete managerWithdrawalRequests[msg.sender];

        emit StakeWithdrawn(msg.sender, request.amount);

        // Transfer UP tokens to manager
        IERC20(upToken).safeTransfer(msg.sender, request.amount);
    }

    /// @notice Slashes a manager's stake balance by a specified amount
    /// @param manager The manager whose stake will be slashed
    /// @param amount The amount of UP tokens to slash from the manager's stake balance
    function slashStake(address manager, uint256 amount) external {
        // Only SUPER_GOVERNOR can slash stake
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert CALLER_NOT_AUTHORIZED();
        }

        // Validate inputs
        if (manager == address(0)) revert ZERO_ADDRESS();
        if (amount == 0) revert ZERO_AMOUNT();

        // Check if manager has sufficient stake balance to slash
        if (_managerStakeBalance[manager] < amount) {
            revert INSUFFICIENT_STAKE_BALANCE();
        }

        // Reduce manager's stake balance
        _managerStakeBalance[manager] -= amount;

        // Clear any pending withdrawal requests
        delete managerWithdrawalRequests[manager];

        // Get the UP token address and SuperBank address
        address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());
        address superBank = _getSuperBank();

        // Transfer slashed amount directly to SuperBank
        IERC20(upToken).safeTransfer(superBank, amount);

        // Emit event for transparency
        emit StakeSlashed(manager, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        AUTHORIZED CALLER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultAggregator
    function addAuthorizedCaller(address strategy, address caller) external validStrategy(strategy) {
        // Either primary or secondary manager can add authorized callers
        if (!isAnyManager(msg.sender, strategy)) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (caller == address(0)) revert ZERO_ADDRESS();

        // Prevent managers from adding protected keepers to circumvent fees
        if (SUPER_GOVERNOR.isProtectedKeeper(caller)) {
            revert CANNOT_ADD_PROTECTED_KEEPER();
        }

        // Check if caller is already authorized and add if not
        if (!_strategyData[strategy].authorizedCallers.add(caller)) {
            revert CALLER_ALREADY_AUTHORIZED();
        }
        emit AuthorizedCallerAdded(strategy, caller);
    }

    /// @inheritdoc ISuperVaultAggregator
    function removeAuthorizedCaller(address strategy, address caller) external validStrategy(strategy) {
        // Either primary or secondary manager can remove authorized callers
        if (!isAnyManager(msg.sender, strategy)) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        // Remove the caller
        if (!_strategyData[strategy].authorizedCallers.remove(caller)) {
            revert CALLER_NOT_AUTHORIZED();
        }
        emit AuthorizedCallerRemoved(strategy, caller);
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
        if (_strategyData[strategy].mainManager == manager) revert MANAGER_ALREADY_EXISTS();

        // Enforce a cap on secondary managers to prevent governance DoS on changePrimaryManager
        if (_strategyData[strategy].secondaryManagers.length() > MAX_SECONDARY_MANAGERS) {
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
    function updateUnpausePPSTimelock(address strategy, uint256 newTimelock_) external validStrategy(strategy) {
        // Since this is a risky call, we only allow main managers as callers
        if (msg.sender != _strategyData[strategy].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Update the timelock
        _strategyData[strategy].maxUnpauseTimeLock = newTimelock_;

        emit StrategyUnpausePPSTimelockUpdated(strategy, newTimelock_);
    }

    /// @inheritdoc ISuperVaultAggregator
    function updatePPSVerificationThresholds(
        address strategy,
        uint256 dispersionThreshold_,
        uint256 deviationThreshold_,
        uint256 mnThreshold_
    )
        external
        validStrategy(strategy)
    {
        // Since this is a risky call, we only allow main managers as callers
        if (msg.sender != _strategyData[strategy].mainManager) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        // Update the thresholds
        _strategyData[strategy].dispersionThreshold = dispersionThreshold_;
        _strategyData[strategy].deviationThreshold = deviationThreshold_;
        _strategyData[strategy].mnThreshold = mnThreshold_;

        // Emit the event
        emit PPSVerificationThresholdsUpdated(strategy, dispersionThreshold_, deviationThreshold_, mnThreshold_);
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
    function changePrimaryManager(address strategy, address newManager) external validStrategy(strategy) {
        // Only SuperGovernor can call this
        if (msg.sender != address(SUPER_GOVERNOR)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (strategy == address(0)) revert ZERO_ADDRESS();

        if (newManager == address(0)) revert ZERO_ADDRESS();

        address oldManager = _strategyData[strategy].mainManager;

        // SECURITY: Clear any pending manager proposals to prevent malicious re-takeover
        _strategyData[strategy].proposedManager = address(0);
        _strategyData[strategy].managerChangeEffectiveTime = 0;

        // SECURITY: Clear any pending hooks root proposals to prevent malicious hook updates
        _strategyData[strategy].proposedHooksRoot = bytes32(0);
        _strategyData[strategy].hooksRootEffectiveTime = 0;

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

        emit PrimaryManagerChanged(strategy, oldManager, newManager);
    }

    /// @inheritdoc ISuperVaultAggregator
    function proposeChangePrimaryManager(address strategy, address newManager) external validStrategy(strategy) {
        // Only secondary managers can propose changes to the primary manager
        if (!_strategyData[strategy].secondaryManagers.contains(msg.sender)) {
            revert UNAUTHORIZED_UPDATE_AUTHORITY();
        }

        if (newManager == address(0)) revert ZERO_ADDRESS();

        // Set up the proposal with 7-day timelock
        uint256 effectiveTime = block.timestamp + _MANAGER_CHANGE_TIMELOCK;

        // Store proposal in the strategy data
        _strategyData[strategy].proposedManager = newManager;
        _strategyData[strategy].managerChangeEffectiveTime = effectiveTime;

        emit PrimaryManagerChangeProposed(strategy, msg.sender, newManager, effectiveTime);
    }

    /// @inheritdoc ISuperVaultAggregator
    function executeChangePrimaryManager(address strategy) external validStrategy(strategy) {
        // Check if there is a pending proposal
        if (_strategyData[strategy].proposedManager == address(0)) revert NO_PENDING_MANAGER_CHANGE();

        // Check if the timelock period has passed
        if (block.timestamp < _strategyData[strategy].managerChangeEffectiveTime) revert TIMELOCK_NOT_EXPIRED();

        address newManager = _strategyData[strategy].proposedManager;
        address oldManager = _strategyData[strategy].mainManager;

        // If new manager is already a secondary manager, remove them
        _strategyData[strategy].secondaryManagers.remove(newManager);

        // Make the old primary manager a secondary manager
        if (_strategyData[strategy].secondaryManagers.length() < MAX_SECONDARY_MANAGERS) {
            _strategyData[strategy].secondaryManagers.add(oldManager);
        } else {
            emit OldPrimaryManagerRemoved(strategy, oldManager);
        }

        // Set the new primary manager
        _strategyData[strategy].mainManager = newManager;

        // Clear the proposal
        _strategyData[strategy].proposedManager = address(0);

        emit PrimaryManagerChanged(strategy, oldManager, newManager);
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
    function getPPSWithStdDev(address strategy)
        external
        view
        validStrategy(strategy)
        returns (uint256 pps, uint256 ppsStdev)
    {
        return (_strategyData[strategy].pps, _strategyData[strategy].ppsStdev);
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
    function getPPSVerificationThresholds(address strategy)
        external
        view
        validStrategy(strategy)
        returns (uint256 dispersionThreshold, uint256 deviationThreshold, uint256 mnThreshold)
    {
        return (
            _strategyData[strategy].dispersionThreshold,
            _strategyData[strategy].deviationThreshold,
            _strategyData[strategy].mnThreshold
        );
    }

    /// @inheritdoc ISuperVaultAggregator
    function isStrategyPaused(address strategy) external view returns (bool isPaused) {
        return _strategyData[strategy].isPaused;
    }

    /// @inheritdoc ISuperVaultAggregator
    function getUpkeepBalance(address manager) external view returns (uint256 balance) {
        return _managerUpkeepBalance[manager];
    }

    /// @notice Gets the current stake balance for a manager
    /// @notice If a withdrawal request is pending, the balance is reduced by the amount of the request
    /// @param manager Address of the manager
    /// @return balance Current stake balance in UP tokens
    function getStakeBalance(address manager) external view returns (uint256 balance) {
        uint256 _requestAmount = managerWithdrawalRequests[manager].amount;
        if (_requestAmount > 0) {
            if (_requestAmount > _managerStakeBalance[manager]) {
                return 0;
            } else {
                return _managerStakeBalance[manager] - _requestAmount;
            }
        }
        return _managerStakeBalance[manager];
    }

    /// @inheritdoc ISuperVaultAggregator
    function getAuthorizedCallers(address strategy) external view returns (address[] memory callers) {
        return _strategyData[strategy].authorizedCallers.values();
    }

    /// @inheritdoc ISuperVaultAggregator
    function getMainManager(address strategy) external view returns (address manager) {
        return _strategyData[strategy].mainManager;
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
        // Check if primary manager
        if (_strategyData[strategy].mainManager == manager) {
            return true;
        }

        // Check if secondary manager using EnumerableSet
        return _strategyData[strategy].secondaryManagers.contains(manager);
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
    /// @param args Struct containing all parameters for PPS update
    function _forwardPPS(PPSUpdateData memory args) internal {
        // Check rate limiting
        uint256 minInterval = _strategyData[args.strategy].minUpdateInterval;
        uint256 lastUpdate = _strategyData[args.strategy].lastUpdateTimestamp;

        // Ensure timestamp is monotonically increasing to prevent out-of-order updates
        if (args.timestamp <= lastUpdate) {
            emit TimestampNotMonotonic();
            return;
        }

        if (!_strategyData[args.strategy].isPaused && (args.timestamp - lastUpdate < minInterval)) {
            emit UpdateTooFrequent();
            return;
        }

        // Get the strategy's manager to deduct upkeep cost from
        address manager = _strategyData[args.strategy].mainManager;

        // Flag to track if any check failed
        bool checksFailed;

        // C2.1) Dispersion Check: Check if the standard deviation is too high relative to mean
        if (_strategyData[args.strategy].dispersionThreshold != type(uint256).max && args.pps > 0) {
            // Calculate dispersion as stddev/mean
            uint256 dispersion = (args.ppsStdev * 1e18) / args.pps; // Scaled by 1e18 for precision
            if (dispersion > _strategyData[args.strategy].dispersionThreshold) {
                checksFailed = true;
                emit StrategyCheckFailed(args.strategy, "HIGH_PPS_DISPERSION");
            }
        }

        // C2.2) Deviation Check: Check if new PPS deviates too much from current PPS
        uint256 currentPPS = _strategyData[args.strategy].pps;
        if (_strategyData[args.strategy].deviationThreshold != type(uint256).max && currentPPS > 0) {
            // Calculate absolute deviation, scaled by 1e18
            uint256 absDiff = args.pps > currentPPS ? (args.pps - currentPPS) : (currentPPS - args.pps);
            uint256 relativeDeviation = (absDiff * 1e18) / currentPPS;
            if (relativeDeviation > _strategyData[args.strategy].deviationThreshold) {
                checksFailed = true;
                emit StrategyCheckFailed(args.strategy, "HIGH_PPS_DEVIATION");
            }
        }

        // C2.3) M/N Check: Check if enough validators participated
        if (args.totalValidators > 0 && _strategyData[args.strategy].mnThreshold > 0) {
            // Calculate participation rate, scaled by 1e18
            uint256 participationRate = (args.validatorSet * 1e18) / args.totalValidators;
            if (participationRate < _strategyData[args.strategy].mnThreshold) {
                checksFailed = true;
                emit StrategyCheckFailed(args.strategy, "INSUFFICIENT_VALIDATOR_PARTICIPATION");
            }
        }

        // Pause strategy if any check failed
        if ((checksFailed || args.pps == 0) && !_strategyData[args.strategy].isPaused) {
            _strategyData[args.strategy].isPaused = true;
            emit StrategyPaused(args.strategy);
        }

        // Handle upkeep costs unless exempt
        uint256 managerUpkeepBalance = _managerUpkeepBalance[manager];
        if (!args.isExempt) {
            // Check if manager has sufficient upkeep balance
            if (managerUpkeepBalance < args.upkeepCost) {
                _strategyData[args.strategy].isPaused = true;
                _strategyData[args.strategy].ppsStale = true;
                emit StrategyPaused(args.strategy);
                emit StrategyPPSStale(args.strategy);
                emit InsufficientUpkeep(args.strategy, manager, managerUpkeepBalance, args.upkeepCost);
                return;
            }

            // Deduct the upkeep cost and emit event
            _managerUpkeepBalance[manager] -= args.upkeepCost;

            // Add claimable upkeep for the `feeRecipient`
            claimableUpkeep += args.upkeepCost;

            emit UpkeepSpent(manager, args.upkeepCost, managerUpkeepBalance, claimableUpkeep);
        }

        // Update PPS, ppsStdev, timestamp and ppsStale in StrategyData
        _strategyData[args.strategy].pps = args.pps;
        _strategyData[args.strategy].ppsStdev = args.ppsStdev;
        _strategyData[args.strategy].lastUpdateTimestamp = args.timestamp;
        if (!checksFailed && args.pps > 0) {
            _strategyData[args.strategy].ppsStale = false;
            emit StrategyPPSStaleReset(args.strategy);
        }

        emit PPSUpdated(args.strategy, args.pps, args.ppsStdev, args.validatorSet, args.totalValidators, args.timestamp);
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
        // Create leaf node from the hook address and arguments
        bytes32 leaf = _createLeaf(hookAddress, hookArgs);

        if (isGlobalProof) {
            // Validate against global root
            if (cache.globalHooksRootVetoed || cache.globalHooksRoot == bytes32(0)) {
                return false;
            }

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
            // Validate against strategy root
            if (cache.strategyHooksRootVetoed || cache.strategyRoot == bytes32(0)) {
                return false;
            }
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

    function _isUnpauser(address account) internal view returns (bool) {
        return IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.UNPAUSER_ROLE(), account);
    }
}
