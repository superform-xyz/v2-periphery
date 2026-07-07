// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

// Periphery Interfaces
import { IManagedSuperVault } from "../interfaces/ManagedSuperVault/IManagedSuperVault.sol";
import { IManagedSuperVaultController } from "../interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { IManagedSuperVaultAggregator } from "../interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultEscrow } from "../interfaces/ManagedSuperVault/IManagedSuperVaultEscrow.sol";
import { ISuperGovernor, FeeType } from "../interfaces/ISuperGovernor.sol";
import { SuperVaultAccountingLib } from "../libraries/SuperVaultAccountingLib.sol";
import { AssetMetadataLib } from "../libraries/AssetMetadataLib.sol";
import { ManagedExecutionLib } from "../libraries/ManagedExecutionLib.sol";

/// @title ManagedSuperVaultController
/// @author Superform Labs
/// @notice Manager-operated counterpart of SuperVaultStrategy for Managed Vaults. Owns deposit request
///         accounting and approvals, redemption fulfillment, the attested manual NAV module, policy-gated
///         arbitrary calldata execution, and fee handling. Holds operational custody of vault assets.
/// @dev No strategy hooks, no yield-source registry, no optimizer, no rebalancing. Calldata execution is
///      gated by an explicit onchain policy: target/selector allowlist, per-call and rolling-window native
///      value caps, and address-argument constraints for value-moving selectors.
contract ManagedSuperVaultController is IManagedSuperVaultController, Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using AssetMetadataLib for address;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant BPS_PRECISION = 10_000;
    uint256 private constant MAX_PERFORMANCE_FEE = 5100; // 51% max performance fee

    /// @dev Default redeem slippage tolerance when user hasn't set their own (0.5%)
    uint16 public constant DEFAULT_REDEEM_SLIPPAGE_BPS = 50;

    /// @dev Timelock period after unpause during which performance fee skimming is disabled (rug prevention)
    uint256 private constant POST_UNPAUSE_SKIM_TIMELOCK = 12 hours;

    /// @dev Timelock duration for fee config updates
    uint256 private constant PROPOSAL_TIMELOCK = 1 weeks;

    /// @dev Maximum number of calls per managed batch execution
    uint256 public constant MAX_BATCH_SIZE = 50;

    /// @dev Registry key for the ManagedSuperVaultAggregator in the SuperGovernor address registry
    bytes32 public constant MANAGED_SUPER_VAULT_AGGREGATOR_KEY = keccak256("MANAGED_SUPER_VAULT_AGGREGATOR");

    uint256 public PRECISION;

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    // Packed slot: vault address + decimals
    address private _vault;
    uint8 private _vaultDecimals;

    IERC20 private _asset;
    address private _escrow;

    // Fee configuration (mirrors SuperVaultStrategy)
    FeeConfig private feeConfig;
    FeeConfig private proposedFeeConfig;
    uint256 private feeConfigEffectiveTime;

    // Core contracts
    ISuperGovernor public immutable SUPER_GOVERNOR;

    // --- Global Vault High-Water Mark (PPS-based) ---
    uint256 public vaultHwmPps;

    // --- Per-controller (7540 user) state ---
    mapping(address controller => ManagedVaultState state) private managedVaultState;

    // --- Deposit accounting ---
    uint256 public totalPendingDepositAssets;

    // --- Deposit policy & approvals ---
    DepositPolicy private depositPolicy;
    mapping(address depositor => ApprovalStatus status) private _approvalStatus;

    // --- Execution policy ---
    mapping(address target => mapping(bytes4 selector => CallRule rule)) private _callRules;
    mapping(address target => mapping(bytes4 selector => WindowUsage usage)) private _windowUsage;
    mapping(
        address target => mapping(bytes4 selector => mapping(uint8 argIndex => mapping(address value => bool allowed)))
    ) private _allowedArgValues;
    mapping(bytes32 operationId => bool used) private _usedOperationIds;

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        emit SuperGovernorSet(superGovernor_);
        _disableInitializers();
    }

    /// @notice Allows the contract to receive native ETH (operational custody)
    receive() external payable { }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultController
    /// @dev The NAV attestation lifecycle lives in the ManagedSuperVaultAggregator (which owns PPS,
    ///      deviation, and pause state); the aggregator configures the attestor set at creation.
    function initialize(
        address vaultAddress,
        FeeConfig memory feeConfigData,
        DepositPolicy memory depositPolicyData
    )
        external
        initializer
    {
        if (vaultAddress == address(0)) revert INVALID_VAULT();
        if (
            (feeConfigData.performanceFeeBps > 0 || feeConfigData.managementFeeBps > 0)
                && feeConfigData.recipient == address(0)
        ) revert ZERO_ADDRESS();
        if (feeConfigData.performanceFeeBps > MAX_PERFORMANCE_FEE) revert INVALID_PERFORMANCE_FEE_BPS();
        if (feeConfigData.managementFeeBps > BPS_PRECISION) revert INVALID_PERFORMANCE_FEE_BPS();

        __ReentrancyGuard_init();

        _vault = vaultAddress;
        _asset = IERC20(IERC4626(vaultAddress).asset());
        _escrow = IManagedSuperVault(vaultAddress).escrow();
        _vaultDecimals = IERC20Metadata(vaultAddress).decimals();
        PRECISION = 10 ** _vaultDecimals;
        feeConfig = feeConfigData;

        _setDepositPolicy(depositPolicyData);

        // Initialize HWM to 1.0 using asset decimals (same as aggregator initial PPS)
        (bool success, uint8 assetDecimals) = address(_asset).tryGetAssetDecimals();
        if (!success) revert INVALID_ASSET();
        vaultHwmPps = 10 ** assetDecimals;

        emit Initialized(_vault);
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT-ONLY OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultController
    function handleDepositRequest(address controller, uint256 assets) external {
        _requireVault();
        if (assets == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();

        _validateManagedVaultState(_getAggregator());

        DepositPolicy memory policy = depositPolicy;

        if (policy.depositsPaused) revert DEPOSITS_PAUSED();

        if (policy.approvalMode != DepositApprovalMode.Open && _approvalStatus[controller] != ApprovalStatus.Approved) {
            revert DEPOSITOR_NOT_APPROVED();
        }

        if (assets < policy.minDepositAssets) revert DEPOSIT_BELOW_MINIMUM();
        if (policy.maxDepositAssets != 0 && assets > policy.maxDepositAssets) revert DEPOSIT_ABOVE_MAXIMUM();

        managedVaultState[controller].pendingDepositAssets += assets;
        totalPendingDepositAssets += assets;

        emit DepositRequestPlaced(controller, assets);
    }

    /// @inheritdoc IManagedSuperVaultController
    function handleCancelDepositRequest(address controller) external returns (uint256 assets) {
        _requireVault();
        if (controller == address(0)) revert ZERO_ADDRESS();

        ManagedVaultState storage state = managedVaultState[controller];
        assets = state.pendingDepositAssets;
        if (assets == 0) revert REQUEST_NOT_FOUND();

        state.pendingDepositAssets = 0;
        totalPendingDepositAssets -= assets;

        emit DepositRequestCanceled(controller, assets);
    }

    /// @inheritdoc IManagedSuperVaultController
    function handleClaimDeposit(address controller, uint256 assets) external {
        _requireVault();
        if (assets == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();

        ManagedVaultState storage state = managedVaultState[controller];
        if (assets > state.claimableDepositAssets) revert INVALID_AMOUNT();
        state.claimableDepositAssets -= assets;

        emit DepositClaimed(controller, assets);
    }

    /// @inheritdoc IManagedSuperVaultController
    function handleOperations7540(Operation operation, address controller, address receiver, uint256 amount) external {
        _requireVault();
        IManagedSuperVaultAggregator aggregator = _getAggregator();

        if (operation == Operation.RedeemRequest) {
            _validateManagedVaultState(aggregator);
            _handleRequestRedeem(controller, amount); // amount = shares
        } else if (operation == Operation.ClaimCancelRedeem) {
            _handleClaimCancelRedeem(controller);
        } else if (operation == Operation.ClaimRedeem) {
            _handleClaimRedeem(controller, receiver, amount); // amount = assets
        } else if (operation == Operation.CancelRedeemRequest) {
            _handleCancelRedeemRequest(controller);
        } else {
            revert ACTION_TYPE_DISALLOWED();
        }
    }

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: DEPOSITS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultController
    function fulfillDepositRequests(address[] calldata controllers) external nonReentrant {
        _isManager(msg.sender);
        _validateManagedVaultState(_getAggregator());

        uint256 len = controllers.length;
        if (len == 0) revert ZERO_LENGTH();

        uint256 currentPPS = getStoredPPS();
        if (currentPPS == 0) revert INVALID_PPS();

        uint256 feeBps = feeConfig.managementFeeBps;
        uint256 totalGrossAssets;
        uint256 totalFeeAssets;

        for (uint256 i; i < len; ++i) {
            address controller = controllers[i];
            ManagedVaultState storage state = managedVaultState[controller];

            uint256 assetsGross = state.pendingDepositAssets;
            // Skip controllers with no pending request so a front-run cancel cannot brick the batch
            if (assetsGross == 0) continue;

            // Entry fee in ASSETS (asset-side, mirrors SuperVaultStrategy management fee)
            uint256 feeAssets = feeBps == 0 ? 0 : Math.mulDiv(assetsGross, feeBps, BPS_PRECISION, Math.Rounding.Ceil);
            uint256 assetsNet = assetsGross - feeAssets;
            if (assetsNet == 0) revert INVALID_AMOUNT();

            uint256 impliedShares = Math.mulDiv(assetsNet, PRECISION, currentPPS, Math.Rounding.Floor);
            if (impliedShares == 0) revert INVALID_AMOUNT();

            // Weighted average claim price across fulfillments (same formula as the redeem side)
            state.averageDepositPrice = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
                state.claimableDepositAssets, state.averageDepositPrice, impliedShares, assetsNet, PRECISION
            );

            state.pendingDepositAssets = 0;
            state.claimableDepositAssets += assetsNet;

            totalGrossAssets += assetsGross;
            totalFeeAssets += feeAssets;

            if (feeAssets != 0) {
                emit ManagementFeePaid(controller, feeConfig.recipient, feeAssets, feeBps);
            }
            emit DepositRequestFulfilled(controller, assetsGross, assetsNet, impliedShares, currentPPS);
        }

        totalPendingDepositAssets -= totalGrossAssets;

        // Move deposit assets from escrow into operational custody
        if (totalGrossAssets != 0) {
            IManagedSuperVaultEscrow(_escrow).releaseDepositAssets(address(this), totalGrossAssets);
        }

        // Pay entry fees
        if (totalFeeAssets != 0) {
            address recipient = feeConfig.recipient;
            if (recipient == address(0)) revert ZERO_ADDRESS();
            _asset.safeTransfer(recipient, totalFeeAssets);
        }
    }

    /// @inheritdoc IManagedSuperVaultController
    function rejectDepositRequests(address[] calldata controllers, string calldata reason) external nonReentrant {
        _isManager(msg.sender);

        uint256 len = controllers.length;
        if (len == 0) revert ZERO_LENGTH();

        for (uint256 i; i < len; ++i) {
            address controller = controllers[i];
            ManagedVaultState storage state = managedVaultState[controller];

            uint256 assets = state.pendingDepositAssets;
            // Skip controllers with no pending request (mirrors fulfill; avoids batch-brick reverts)
            if (assets == 0) continue;

            state.pendingDepositAssets = 0;
            totalPendingDepositAssets -= assets;

            // Refund assets from escrow back to the depositor
            IManagedSuperVaultEscrow(_escrow).refundDepositAssets(controller, assets);

            emit DepositRequestRejected(controller, assets, reason);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: APPROVALS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultController
    function approveDepositors(address[] calldata depositors, bytes32[] calldata kycRefs) external {
        _isManager(msg.sender);

        uint256 len = depositors.length;
        if (len == 0) revert ZERO_LENGTH();
        if (kycRefs.length != len) revert INVALID_ARRAY_LENGTH();

        for (uint256 i; i < len; ++i) {
            address depositor = depositors[i];
            if (depositor == address(0)) revert ZERO_ADDRESS();
            _approvalStatus[depositor] = ApprovalStatus.Approved;
            // KYC/subscription reference is emitted for offchain indexing only; never stored onchain
            emit DepositorApproved(depositor, kycRefs[i]);
        }
    }

    /// @inheritdoc IManagedSuperVaultController
    function rejectDepositors(address[] calldata depositors) external {
        _isManager(msg.sender);

        uint256 len = depositors.length;
        if (len == 0) revert ZERO_LENGTH();

        for (uint256 i; i < len; ++i) {
            address depositor = depositors[i];
            _approvalStatus[depositor] = ApprovalStatus.Rejected;
            emit DepositorRejected(depositor);
        }
    }

    /// @inheritdoc IManagedSuperVaultController
    function revokeDepositors(address[] calldata depositors) external {
        _isManager(msg.sender);

        uint256 len = depositors.length;
        if (len == 0) revert ZERO_LENGTH();

        for (uint256 i; i < len; ++i) {
            address depositor = depositors[i];
            if (_approvalStatus[depositor] != ApprovalStatus.Approved) revert INVALID_APPROVAL_STATUS();
            _approvalStatus[depositor] = ApprovalStatus.Revoked;
            emit DepositorRevoked(depositor);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: REDEMPTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultController
    function fulfillCancelRedeemRequests(address[] memory controllers) external nonReentrant {
        _isManager(msg.sender);

        uint256 controllersLength = controllers.length;
        if (controllersLength == 0) revert ZERO_LENGTH();

        for (uint256 i; i < controllersLength; ++i) {
            ManagedVaultState storage state = managedVaultState[controllers[i]];
            if (state.pendingCancelRedeemRequest) {
                state.claimableCancelRedeemRequest += state.pendingRedeemRequest;
                state.pendingRedeemRequest = 0;
                state.averageRequestPPS = 0;
                emit RedeemCancelRequestFulfilled(controllers[i], state.claimableCancelRedeemRequest);
            }
        }
    }

    /// @inheritdoc IManagedSuperVaultController
    function fulfillRedeemRequests(
        address[] calldata controllers,
        uint256[] calldata totalAssetsOut
    )
        external
        nonReentrant
    {
        _isManager(msg.sender);

        _validateManagedVaultState(_getAggregator());

        uint256 len = controllers.length;
        if (len == 0 || totalAssetsOut.length != len) revert INVALID_ARRAY_LENGTH();

        FulfillRedeemVars memory vars;
        vars.currentPPS = getStoredPPS();
        if (vars.currentPPS == 0) revert INVALID_PPS();

        for (uint256 i; i < len; ++i) {
            // Validate controllers are sorted and unique
            if (i > 0 && controllers[i] <= controllers[i - 1]) revert CONTROLLERS_NOT_SORTED_UNIQUE();

            uint256 pendingShares = managedVaultState[controllers[i]].pendingRedeemRequest;
            vars.totalRequestedShares += pendingShares;

            if (pendingShares == 0) revert ZERO_SHARE_FULFILLMENT_DISALLOWED();

            _processExactFulfillmentBatch(controllers[i], totalAssetsOut[i], vars.currentPPS, pendingShares);
            vars.totalNetAssetsOut += totalAssetsOut[i];
        }

        // Balance check against operational custody
        vars.controllerBalance = _asset.balanceOf(address(this));
        if (vars.controllerBalance < vars.totalNetAssetsOut) {
            revert INSUFFICIENT_LIQUIDITY();
        }

        // Burn shares held in escrow
        IManagedSuperVault(_vault).burnShares(vars.totalRequestedShares);

        // Transfer net assets to escrow for claims
        if (vars.totalNetAssetsOut > 0) {
            _asset.safeTransfer(_escrow, vars.totalNetAssetsOut);
        }

        emit RedeemRequestsFulfilled(controllers, vars.totalRequestedShares, vars.currentPPS);
    }

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultController
    function executeManagedCall(ManagedCall calldata call, bytes32 operationId) external payable nonReentrant {
        _isManager(msg.sender);
        _useOperationId(operationId);
        ManagedExecutionLib.executeSingle(
            _callRules, _windowUsage, _allowedArgValues, call, _forbiddenTargets(), operationId, 0
        );
    }

    /// @inheritdoc IManagedSuperVaultController
    function executeManagedBatch(ManagedCall[] calldata calls, bytes32 operationId) external payable nonReentrant {
        _isManager(msg.sender);

        uint256 len = calls.length;
        if (len == 0) revert ZERO_LENGTH();
        if (len > MAX_BATCH_SIZE) revert BATCH_SIZE_EXCEEDED();

        _useOperationId(operationId);

        ManagedExecutionLib.ForbiddenTargets memory forbidden = _forbiddenTargets();
        for (uint256 i; i < len; ++i) {
            ManagedExecutionLib.executeSingle(
                _callRules, _windowUsage, _allowedArgValues, calls[i], forbidden, operationId, i
            );
        }
    }

    /// @inheritdoc IManagedSuperVaultController
    function setCallRule(address target, bytes4 selector, CallRule calldata rule) external {
        _isPrimaryManager(msg.sender);

        if (target == address(0)) revert ZERO_ADDRESS();
        _checkForbiddenTarget(target);

        ManagedExecutionLib.validateCallRule(rule, selector);

        _callRules[target][selector] = rule;
        delete _windowUsage[target][selector];

        emit CallRuleSet(
            target,
            selector,
            rule.allowed,
            rule.valueAllowed,
            rule.maxValuePerCall,
            rule.windowValueCap,
            rule.windowDuration,
            rule.constrainedArgs
        );
    }

    /// @inheritdoc IManagedSuperVaultController
    function removeCallRule(address target, bytes4 selector) external {
        _isPrimaryManager(msg.sender);
        delete _callRules[target][selector];
        delete _windowUsage[target][selector];
        emit CallRuleRemoved(target, selector);
    }

    /// @inheritdoc IManagedSuperVaultController
    function setArgAllowedValues(
        address target,
        bytes4 selector,
        uint8 argIndex,
        address[] calldata values,
        bool allowed
    )
        external
    {
        _isPrimaryManager(msg.sender);

        uint256 len = values.length;
        if (len == 0) revert ZERO_LENGTH();

        for (uint256 i; i < len; ++i) {
            _allowedArgValues[target][selector][argIndex][values[i]] = allowed;
            emit ArgAllowedValueSet(target, selector, argIndex, values[i], allowed);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: POLICY & FEES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultController
    function setDepositPolicy(DepositPolicy calldata policy) external {
        _isPrimaryManager(msg.sender);
        _setDepositPolicy(policy);
    }

    /// @inheritdoc IManagedSuperVaultController
    function skimPerformanceFee() external nonReentrant {
        _isManager(msg.sender);

        IManagedSuperVaultAggregator aggregator = _getAggregator();
        _validateManagedVaultState(aggregator);

        // Prevent skim for 12 hours after unpause (detection window, mirrors SuperVaultStrategy)
        uint256 lastUnpause = aggregator.getLastUnpauseTimestamp(address(this));
        if (block.timestamp < lastUnpause + POST_UNPAUSE_SKIM_TIMELOCK) {
            revert SKIM_TIMELOCK_ACTIVE();
        }

        IERC4626 vault = IERC4626(_vault);
        uint256 totalSupplyLocal = vault.totalSupply();

        if (totalSupplyLocal == 0) return;

        uint256 currentPPS = aggregator.getPPS(address(this));
        if (currentPPS == 0) revert INVALID_PPS();

        uint256 hwmPps = vaultHwmPps;

        if (currentPPS <= hwmPps) {
            return;
        }

        uint256 ppsGrowth = currentPPS - hwmPps;
        uint256 profit = Math.mulDiv(ppsGrowth, totalSupplyLocal, PRECISION, Math.Rounding.Floor);
        if (profit == 0) return;

        uint256 fee = Math.mulDiv(profit, feeConfig.performanceFeeBps, BPS_PRECISION, Math.Rounding.Ceil);
        if (fee == 0) return;

        // Split fee between Superform treasury and manager recipient
        uint256 sfFee =
            Math.mulDiv(fee, SUPER_GOVERNOR.getFee(FeeType.PERFORMANCE_FEE_SHARE), BPS_PRECISION, Math.Rounding.Floor);
        uint256 recipientFee = fee - sfFee;

        if (_asset.balanceOf(address(this)) < fee) revert NOT_ENOUGH_FREE_ASSETS_FEE_SKIM();

        if (sfFee > 0) _asset.safeTransfer(SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.TREASURY()), sfFee);
        if (recipientFee > 0) _asset.safeTransfer(feeConfig.recipient, recipientFee);

        emit PerformanceFeeSkimmed(fee, sfFee);

        uint256 ppsReduction = Math.mulDiv(fee, PRECISION, totalSupplyLocal, Math.Rounding.Floor);
        if (ppsReduction >= currentPPS) revert INVALID_PPS();

        uint256 newPPS = currentPPS - ppsReduction;
        if (newPPS == 0) revert INVALID_PPS();

        vaultHwmPps = newPPS;

        emit HWMPPSUpdated(newPPS, currentPPS, profit, fee);

        aggregator.updatePPSAfterSkim(newPPS, fee);
    }

    /// @inheritdoc IManagedSuperVaultController
    function proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    )
        external
    {
        _isPrimaryManager(msg.sender);

        if (performanceFeeBps > MAX_PERFORMANCE_FEE) revert INVALID_PERFORMANCE_FEE_BPS();
        if (managementFeeBps > BPS_PRECISION) revert INVALID_PERFORMANCE_FEE_BPS();
        if (recipient == address(0)) revert ZERO_ADDRESS();
        proposedFeeConfig = FeeConfig({
            performanceFeeBps: performanceFeeBps, managementFeeBps: managementFeeBps, recipient: recipient
        });
        feeConfigEffectiveTime = block.timestamp + PROPOSAL_TIMELOCK;
        emit VaultFeeConfigProposed(performanceFeeBps, managementFeeBps, recipient, feeConfigEffectiveTime);
    }

    /// @inheritdoc IManagedSuperVaultController
    function executeVaultFeeConfigUpdate() external {
        _isPrimaryManager(msg.sender);

        if (block.timestamp < feeConfigEffectiveTime) revert INVALID_TIMESTAMP();
        if (proposedFeeConfig.recipient == address(0)) revert ZERO_ADDRESS();

        uint256 currentPPS = getStoredPPS();
        uint256 oldHwmPps = vaultHwmPps;

        feeConfig = proposedFeeConfig;
        delete proposedFeeConfig;
        feeConfigEffectiveTime = 0;

        // Reset HWM to current PPS to avoid incorrect fee calculations under the new structure
        vaultHwmPps = currentPPS;

        emit VaultFeeConfigUpdated(feeConfig.performanceFeeBps, feeConfig.managementFeeBps, feeConfig.recipient);
        emit HWMPPSUpdated(currentPPS, oldHwmPps, 0, 0);
    }

    /// @inheritdoc IManagedSuperVaultController
    function changeFeeRecipient(address newRecipient) external {
        if (msg.sender != address(_getAggregator())) revert ACCESS_DENIED();

        feeConfig.recipient = newRecipient;
        emit FeeRecipientChanged(newRecipient);
    }

    /// @inheritdoc IManagedSuperVaultController
    function resetHighWaterMark(uint256 newHwmPps) external {
        if (msg.sender != address(_getAggregator())) revert ACCESS_DENIED();

        if (newHwmPps == 0) revert INVALID_PPS();

        vaultHwmPps = newHwmPps;

        emit HighWaterMarkReset(newHwmPps);
    }

    /*//////////////////////////////////////////////////////////////
                        USER OPERATIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultController
    function setRedeemSlippage(uint16 slippageBps) external {
        if (slippageBps > BPS_PRECISION) revert INVALID_REDEEM_SLIPPAGE_BPS();

        managedVaultState[msg.sender].redeemSlippageBps = slippageBps;

        emit RedeemSlippageSet(msg.sender, slippageBps);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultController
    function getVaultInfo() external view returns (address vault, address asset, uint8 vaultDecimals) {
        vault = _vault;
        asset = address(_asset);
        vaultDecimals = _vaultDecimals;
    }

    /// @inheritdoc IManagedSuperVaultController
    function getConfigInfo() external view returns (FeeConfig memory feeConfig_) {
        feeConfig_ = feeConfig;
    }

    /// @inheritdoc IManagedSuperVaultController
    function getStoredPPS() public view returns (uint256) {
        return _getAggregator().getPPS(address(this));
    }

    /// @inheritdoc IManagedSuperVaultController
    function navMode() external pure returns (string memory) {
        return "attested_manual";
    }

    /// @inheritdoc IManagedSuperVaultController
    function getManagedVaultState(address controller) external view returns (ManagedVaultState memory state) {
        return managedVaultState[controller];
    }

    /// @inheritdoc IManagedSuperVaultController
    function getDepositPolicy() external view returns (DepositPolicy memory policy) {
        return depositPolicy;
    }

    /// @inheritdoc IManagedSuperVaultController
    function getApprovalStatus(address depositor) external view returns (ApprovalStatus status) {
        return _approvalStatus[depositor];
    }

    /// @inheritdoc IManagedSuperVaultController
    function pendingDepositRequest(address controller) external view returns (uint256 pendingAssets) {
        return managedVaultState[controller].pendingDepositAssets;
    }

    /// @inheritdoc IManagedSuperVaultController
    function claimableDepositRequest(address controller) external view returns (uint256 claimableAssets) {
        return managedVaultState[controller].claimableDepositAssets;
    }

    /// @inheritdoc IManagedSuperVaultController
    function getAverageDepositPrice(address controller) external view returns (uint256 averageDepositPrice) {
        return managedVaultState[controller].averageDepositPrice;
    }

    /// @inheritdoc IManagedSuperVaultController
    function getCallRule(address target, bytes4 selector) external view returns (CallRule memory rule) {
        return _callRules[target][selector];
    }

    /// @inheritdoc IManagedSuperVaultController
    function getWindowUsage(address target, bytes4 selector) external view returns (WindowUsage memory usage) {
        return _windowUsage[target][selector];
    }

    /// @inheritdoc IManagedSuperVaultController
    function isArgValueAllowed(
        address target,
        bytes4 selector,
        uint8 argIndex,
        address value
    )
        external
        view
        returns (bool)
    {
        return _allowedArgValues[target][selector][argIndex][value];
    }

    /// @inheritdoc IManagedSuperVaultController
    function isOperationIdUsed(bytes32 operationId) external view returns (bool) {
        return _usedOperationIds[operationId];
    }

    /// @inheritdoc IManagedSuperVaultController
    function pendingRedeemRequest(address controller) external view returns (uint256 pendingShares) {
        return managedVaultState[controller].pendingRedeemRequest;
    }

    /// @inheritdoc IManagedSuperVaultController
    function claimableWithdraw(address controller) external view returns (uint256 claimableAssets) {
        return managedVaultState[controller].maxWithdraw;
    }

    /// @inheritdoc IManagedSuperVaultController
    function pendingCancelRedeemRequest(address controller) external view returns (bool) {
        return managedVaultState[controller].pendingCancelRedeemRequest;
    }

    /// @inheritdoc IManagedSuperVaultController
    function claimableCancelRedeemRequest(address controller) external view returns (uint256 claimableShares) {
        if (!managedVaultState[controller].pendingCancelRedeemRequest) return 0;
        return managedVaultState[controller].claimableCancelRedeemRequest;
    }

    /// @inheritdoc IManagedSuperVaultController
    function getAverageWithdrawPrice(address controller) external view returns (uint256 averageWithdrawPrice) {
        return managedVaultState[controller].averageWithdrawPrice;
    }

    /// @inheritdoc IManagedSuperVaultController
    function previewExactRedeem(address controller)
        external
        view
        returns (uint256 shares, uint256 theoreticalAssets, uint256 minAssets)
    {
        ManagedVaultState memory state = managedVaultState[controller];
        shares = state.pendingRedeemRequest;

        if (shares == 0) return (0, 0, 0);

        uint256 pps = getStoredPPS();
        theoreticalAssets = shares.mulDiv(pps, PRECISION, Math.Rounding.Floor);

        uint16 slippageBps = state.redeemSlippageBps > 0 ? state.redeemSlippageBps : DEFAULT_REDEEM_SLIPPAGE_BPS;

        minAssets = SuperVaultAccountingLib.computeMinNetOut(shares, state.averageRequestPPS, slippageBps, PRECISION);

        return (shares, theoreticalAssets, minAssets);
    }

    /// @inheritdoc IManagedSuperVaultController
    function vaultUnrealizedProfit() external view returns (uint256) {
        IERC4626 vault = IERC4626(_vault);
        uint256 totalSupplyLocal = vault.totalSupply();

        if (totalSupplyLocal == 0) return 0;

        uint256 currentPPS = getStoredPPS();

        if (currentPPS <= vaultHwmPps) return 0;

        uint256 ppsGrowth = currentPPS - vaultHwmPps;
        return Math.mulDiv(ppsGrowth, totalSupplyLocal, PRECISION, Math.Rounding.Floor);
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL EXECUTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Consume an operation id (replay protection)
    function _useOperationId(bytes32 operationId) internal {
        if (operationId == bytes32(0)) revert INVALID_OPERATION_ID();
        if (_usedOperationIds[operationId]) revert OPERATION_ID_USED();
        _usedOperationIds[operationId] = true;
    }

    /// @notice Build the forbidden-target set for the execution library
    function _forbiddenTargets() internal view returns (ManagedExecutionLib.ForbiddenTargets memory) {
        return ManagedExecutionLib.ForbiddenTargets({
            vault: _vault,
            controller: address(this),
            escrow: _escrow,
            aggregator: address(_getAggregator()),
            governor: address(SUPER_GOVERNOR)
        });
    }

    /// @notice Block setting a policy rule for a system target it could never safely call
    function _checkForbiddenTarget(address target) internal view {
        if (
            target == _vault || target == address(this) || target == _escrow || target == address(_getAggregator())
                || target == address(SUPER_GOVERNOR)
        ) revert TARGET_FORBIDDEN();
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL REDEMPTION PROCESSING
    //////////////////////////////////////////////////////////////*/

    /// @notice Process exact fulfillment for batch processing (mirrors SuperVaultStrategy)
    function _processExactFulfillmentBatch(
        address controller,
        uint256 totalAssetsOut,
        uint256 currentPPS,
        uint256 pendingShares
    )
        internal
    {
        ManagedVaultState storage state = managedVaultState[controller];

        uint16 slippageBps = state.redeemSlippageBps > 0 ? state.redeemSlippageBps : DEFAULT_REDEEM_SLIPPAGE_BPS;

        uint256 theoreticalAssets = pendingShares.mulDiv(currentPPS, PRECISION, Math.Rounding.Floor);

        uint256 minAssetsOut =
            SuperVaultAccountingLib.computeMinNetOut(pendingShares, state.averageRequestPPS, slippageBps, PRECISION);

        if (totalAssetsOut < minAssetsOut || totalAssetsOut > theoreticalAssets) {
            revert BOUNDS_EXCEEDED(minAssetsOut, theoreticalAssets, totalAssetsOut);
        }

        state.averageWithdrawPrice = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
            state.maxWithdraw, state.averageWithdrawPrice, pendingShares, totalAssetsOut, PRECISION
        );

        state.pendingRedeemRequest = 0;
        state.maxWithdraw += totalAssetsOut;
        state.averageRequestPPS = 0;
        state.pendingCancelRedeemRequest = false;
        state.claimableCancelRedeemRequest = 0;

        emit RedeemClaimable(controller, totalAssetsOut, pendingShares, state.averageWithdrawPrice);
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Resolve the ManagedSuperVaultAggregator via the SuperGovernor address registry
    function _getAggregator() internal view returns (IManagedSuperVaultAggregator) {
        return IManagedSuperVaultAggregator(SUPER_GOVERNOR.getAddress(MANAGED_SUPER_VAULT_AGGREGATOR_KEY));
    }

    /// @notice Check if the caller is any manager (main or secondary)
    function _isManager(address manager_) internal view {
        if (!_getAggregator().isAnyManager(manager_, address(this))) {
            revert MANAGER_NOT_AUTHORIZED();
        }
    }

    /// @notice Check if the caller is the primary manager
    function _isPrimaryManager(address manager_) internal view {
        if (!_getAggregator().isMainManager(manager_, address(this))) {
            revert MANAGER_NOT_AUTHORIZED();
        }
    }

    /// @notice Validate and store the deposit policy
    function _setDepositPolicy(DepositPolicy memory policy) internal {
        if (policy.maxDepositAssets != 0 && policy.maxDepositAssets < policy.minDepositAssets) {
            revert ACTION_TYPE_DISALLOWED();
        }

        depositPolicy = policy;

        emit DepositPolicyUpdated(
            policy.approvalMode, policy.depositsPaused, policy.minDepositAssets, policy.maxDepositAssets
        );
    }

    /// @notice Internal function to handle a redeem request (mirrors SuperVaultStrategy)
    function _handleRequestRedeem(address controller, uint256 shares) private {
        if (shares == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();
        ManagedVaultState storage state = managedVaultState[controller];

        uint256 currentPPS = getStoredPPS();
        if (currentPPS == 0) revert INVALID_PPS();

        if (state.pendingRedeemRequest > 0) {
            uint256 existingSharesInRequest = state.pendingRedeemRequest;
            uint256 newTotalSharesInRequest = existingSharesInRequest + shares;

            state.averageRequestPPS =
                ((existingSharesInRequest * state.averageRequestPPS) + (shares * currentPPS)) / newTotalSharesInRequest;

            state.pendingRedeemRequest = newTotalSharesInRequest;
        } else {
            state.pendingRedeemRequest = shares;
            state.averageRequestPPS = currentPPS;
        }

        emit RedeemRequestPlaced(controller, controller, shares);
    }

    /// @notice Internal function to handle a redeem cancellation request
    function _handleCancelRedeemRequest(address controller) private {
        if (controller == address(0)) revert ZERO_ADDRESS();
        ManagedVaultState storage state = managedVaultState[controller];
        if (state.pendingRedeemRequest == 0) revert REQUEST_NOT_FOUND();
        if (state.pendingCancelRedeemRequest) revert CANCELLATION_REDEEM_REQUEST_PENDING();

        state.pendingCancelRedeemRequest = true;
        emit RedeemCancelRequestPlaced(controller);
    }

    /// @notice Internal function to handle a claim redeem cancellation
    function _handleClaimCancelRedeem(address controller) private {
        if (controller == address(0)) revert ZERO_ADDRESS();
        ManagedVaultState storage state = managedVaultState[controller];
        uint256 pendingShares = state.claimableCancelRedeemRequest;
        if (pendingShares == 0) revert REQUEST_NOT_FOUND();

        if (!state.pendingCancelRedeemRequest) revert CANCELLATION_REDEEM_REQUEST_PENDING();

        state.pendingCancelRedeemRequest = false;
        state.claimableCancelRedeemRequest = 0;
        emit RedeemRequestCanceled(controller, pendingShares);
    }

    /// @notice Internal function to handle a redeem claim
    /// @dev Only updates state. Vault is responsible for calling Escrow.returnAssets() after this returns.
    function _handleClaimRedeem(address controller, address receiver, uint256 assetsToClaim) private {
        if (assetsToClaim == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();
        ManagedVaultState storage state = managedVaultState[controller];
        state.maxWithdraw -= assetsToClaim;
        emit RedeemRequestClaimed(controller, receiver, assetsToClaim, 0);
    }

    /// @notice Internal function to check if the caller is the vault
    function _requireVault() internal view {
        if (msg.sender != _vault) revert ACCESS_DENIED();
    }

    /// @notice Validates full managed vault state: pause, stale flag, and NAV freshness
    /// @dev Used for operations that require a current NAV: deposit requests/fulfillment,
    ///      redeem requests/fulfillment, and fee skims
    function _validateManagedVaultState(IManagedSuperVaultAggregator aggregator) internal view {
        if (aggregator.isManagedVaultPaused(address(this))) revert MANAGED_VAULT_PAUSED();
        if (aggregator.isNAVStale(address(this))) revert STALE_NAV();
        if (
            block.timestamp - aggregator.getLastUpdateTimestamp(address(this))
                > aggregator.getMaxStaleness(address(this))
        ) {
            revert NAV_EXPIRED();
        }
    }
}
