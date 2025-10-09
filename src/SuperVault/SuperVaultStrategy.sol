// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

// External
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Core Interfaces
import {
    ISuperHook,
    ISuperHookResult,
    ISuperHookOutflow,
    ISuperHookInflowOutflow,
    ISuperHookResultOutflow,
    ISuperHookContextAware,
    ISuperHookInspector
} from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { IYieldSourceOracle } from "@superform-v2-core/src/interfaces/accounting/IYieldSourceOracle.sol";

// Periphery Interfaces
import { ISuperVault } from "../interfaces/SuperVault/ISuperVault.sol";
import { HookDataDecoder } from "@superform-v2-core/src/libraries/HookDataDecoder.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperGovernor, FeeType } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";

/// @title SuperVaultStrategy
/// @author Superform Labs
/// @notice Strategy implementation for SuperVault that executes strategies
contract SuperVaultStrategy is ISuperVaultStrategy, Initializable, ReentrancyGuardUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Math for uint256;

    
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant ONE_WEEK = 7 days;
    uint256 private constant BPS_PRECISION = 10_000;
    /// @dev The following is needed because the `processedShares` for some vaults (for example Centrifuge)
    ///      can be lower by 1 or 2 wei than the `totalRequestedAmount`in SuperVault shares
    uint256 private constant TOLERANCE_CONSTANT = 10 wei;

    // Slippage tolerance in BPS (1%)
    uint256 private constant SV_SLIPPAGE_TOLERANCE_BPS = 100;

    uint256 public PRECISION;

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    address private _vault;
    IERC20 private _asset;
    uint8 private _vaultDecimals;

    // Global configuration
    uint256 private _maxPPSSlippage;

    // Fee configuration
    FeeConfig private feeConfig;
    FeeConfig private proposedFeeConfig;
    uint256 private feeConfigEffectiveTime;

    // Core contracts
    ISuperGovernor public immutable superGovernor;

    // Emergency withdrawable configuration
    bool public emergencyWithdrawable;
    bool public proposedEmergencyWithdrawable;
    uint256 public emergencyWithdrawableEffectiveTime;

    // Yield source configuration - simplified mapping from source to oracle
    mapping(address source => address oracle) private yieldSources;
    EnumerableSet.AddressSet private yieldSourcesList;

    // --- Redeem Request State ---
    mapping(address controller => SuperVaultState state) private superVaultState;

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();

        superGovernor = ISuperGovernor(superGovernor_);
        emit SuperGovernorSet(superGovernor_);
        _disableInitializers();
    }

    /// @notice Allows the contract to receive native ETH
    /// @dev Required for hooks that may send ETH back to the strategy
    receive() external payable { }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    function initialize(address vaultAddress, FeeConfig memory feeConfigData) external initializer {
        if (vaultAddress == address(0)) revert INVALID_VAULT();
        // if either fee is configured, check if recipient is address (0), if it is revert with ZERO ADDRESS
        // if both fees are 0, no need check address (it just passes the if). Recipient can be configured later
        if (
            (feeConfigData.performanceFeeBps > 0 || feeConfigData.managementFeeBps > 0)
                && feeConfigData.recipient == address(0)
        ) revert ZERO_ADDRESS();
        if (feeConfigData.performanceFeeBps > BPS_PRECISION) revert INVALID_PERFORMANCE_FEE_BPS();
        if (feeConfigData.managementFeeBps > BPS_PRECISION) revert INVALID_PERFORMANCE_FEE_BPS();

        __ReentrancyGuard_init();

        _vault = vaultAddress;
        _asset = IERC20(IERC4626(vaultAddress).asset());
        _vaultDecimals = IERC20Metadata(vaultAddress).decimals();
        PRECISION = 10 ** _vaultDecimals;
        feeConfig = feeConfigData;
        _maxPPSSlippage = 500; // 5% as a start, configurable later

        emit Initialized(_vault);
    }

    /*//////////////////////////////////////////////////////////////
                        CORE STRATEGY OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultStrategy
    function handleOperations4626Deposit(
        address controller,
        uint256 assetsGross
    )
        external
        returns (uint256 sharesNet)
    {
        _requireVault();

        if (assetsGross == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();

        // Check if strategy is paused or if global hooks root is vetoed
        if (_isPaused()) revert STRATEGY_PAUSED();
        if (_getSuperVaultAggregator().isGlobalHooksRootVetoed()) {
            revert OPERATIONS_BLOCKED_BY_VETO();
        }

        // Fee skim in ASSETS (asset-side entry fee)
        uint256 feeBps = feeConfig.managementFeeBps;
        uint256 feeAssets = feeBps == 0 ? 0 : Math.mulDiv(assetsGross, feeBps, BPS_PRECISION, Math.Rounding.Ceil);

        uint256 assetsNet = assetsGross - feeAssets;
        if (assetsNet == 0) revert INVALID_AMOUNT();

        if (feeAssets != 0) {
            address recipient = feeConfig.recipient;
            if (recipient == address(0)) revert ZERO_ADDRESS();
            _safeTokenTransfer(address(_asset), recipient, feeAssets);
            emit ManagementFeePaid(controller, recipient, feeAssets, feeBps);
        }

        // Compute shares on NET using current PPS
        uint256 pps = getStoredPPS();
        if (pps == 0) revert INVALID_PPS();
        sharesNet = Math.mulDiv(assetsNet, PRECISION, pps, Math.Rounding.Floor);
        if (sharesNet == 0) revert INVALID_AMOUNT();

        // Account on NET
        SuperVaultState storage state = superVaultState[controller];
        state.accumulatorShares += sharesNet;
        state.accumulatorCostBasis += assetsNet;
        emit DepositHandled(controller, assetsNet, sharesNet);
        return sharesNet;
    }

    /// @inheritdoc ISuperVaultStrategy
    function handleOperations4626Mint(
        address controller,
        uint256 sharesNet,
        uint256 assetsGross,
        uint256 assetsNet
    )
        external
    {
        _requireVault();

        if (sharesNet == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();

        // Check if strategy is paused or if global hooks root is vetoed
        if (_isPaused()) revert STRATEGY_PAUSED();
        if (_getSuperVaultAggregator().isGlobalHooksRootVetoed()) {
            revert OPERATIONS_BLOCKED_BY_VETO();
        }

        uint256 feeBps = feeConfig.managementFeeBps;
        // Transfer fee if needed
        if (feeBps != 0) {
            uint256 feeAssets = assetsGross - assetsNet;
            if (feeAssets != 0) {
                address recipient = feeConfig.recipient;
                if (recipient == address(0)) revert ZERO_ADDRESS();
                _safeTokenTransfer(address(_asset), recipient, feeAssets);
                emit ManagementFeePaid(controller, recipient, feeAssets, feeBps);
            }
        }

        // Account on NET
        SuperVaultState storage state = superVaultState[controller];
        state.accumulatorShares += sharesNet;
        state.accumulatorCostBasis += assetsNet;
        emit DepositHandled(controller, assetsNet, sharesNet);
    }

    /// @inheritdoc ISuperVaultStrategy
    function quoteMintAssetsGross(uint256 shares) external view returns (uint256 assetsGross, uint256 assetsNet) {
        uint256 pps = getStoredPPS();
        if (pps == 0) revert INVALID_PPS();
        assetsNet = Math.mulDiv(shares, pps, PRECISION, Math.Rounding.Ceil);
        if (assetsNet == 0) revert INVALID_AMOUNT();

        uint256 feeBps = feeConfig.managementFeeBps;
        if (feeBps == 0) return (assetsNet, assetsNet);
        if (feeBps >= BPS_PRECISION) revert INVALID_AMOUNT(); // prevents div-by-zero (100% fee)
        assetsGross = Math.mulDiv(assetsNet, BPS_PRECISION, (BPS_PRECISION - feeBps), Math.Rounding.Ceil);
        return (assetsGross, assetsNet);
    }

    /// @inheritdoc ISuperVaultStrategy
    function handleOperations7540(Operation operation, address controller, address receiver, uint256 amount) external {
        _requireVault();

        if (_isPaused()) revert STRATEGY_PAUSED();

        if (operation == Operation.RedeemRequest) {
            _handleRequestRedeem(controller, amount); // amount = shares
        } else if (operation == Operation.CancelRedeem) {
            _handleCancelRedeem(controller);
        } else if (operation == Operation.ClaimRedeem) {
            _handleClaimRedeem(controller, receiver, amount); // amount = assets
        } else {
            revert ACTION_TYPE_DISALLOWED();
        }
    }

    /*//////////////////////////////////////////////////////////////
                MANAGER EXTERNAL ACCESS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultStrategy
    function executeHooks(ExecuteArgs calldata args) external payable nonReentrant {
        _isManager(msg.sender);

        uint256 hooksLength = args.hooks.length;
        if (hooksLength == 0) revert ZERO_LENGTH();
        if (args.hookCalldata.length != hooksLength) revert INVALID_ARRAY_LENGTH();
        if (args.expectedAssetsOrSharesOut.length != hooksLength) revert INVALID_ARRAY_LENGTH();
        if (args.globalProofs.length != hooksLength) revert INVALID_ARRAY_LENGTH();
        if (args.strategyProofs.length != hooksLength) revert INVALID_ARRAY_LENGTH();

        address prevHook;
        for (uint256 i; i < hooksLength; ++i) {
            address hook = args.hooks[i];
            if (!_isRegisteredHook(hook)) revert INVALID_HOOK();

            // Check if the hook was validated
            if (!_validateHook(hook, args.hookCalldata[i], args.globalProofs[i], args.strategyProofs[i])) {
                revert HOOK_VALIDATION_FAILED();
            }

            prevHook =
                _processSingleHookExecution(hook, prevHook, args.hookCalldata[i], args.expectedAssetsOrSharesOut[i]);
        }
        emit HooksExecuted(args.hooks);
    }

    /// @inheritdoc ISuperVaultStrategy
    function fulfillRedeemRequests(FulfillArgs calldata args) external payable nonReentrant {
        (uint256 controllersLength, uint256 currentPPS, uint256 totalRequestedShares) =
            _precheckAndGetRedeemTotals(args.controllers);

        uint256 hooksLength = args.hooks.length;
        if (hooksLength == 0) revert ZERO_LENGTH();
        if (args.hookCalldata.length != hooksLength) revert INVALID_ARRAY_LENGTH();
        if (args.expectedAssetsOrSharesOut.length != hooksLength) revert INVALID_ARRAY_LENGTH();
        if (args.globalProofs.length != hooksLength) revert INVALID_ARRAY_LENGTH();
        if (args.strategyProofs.length != hooksLength) revert INVALID_ARRAY_LENGTH();

        uint256 intendedShares;
        for (uint256 i; i < hooksLength; ++i) {
            address hook = args.hooks[i];
            if (!_isFulfillRequestsHook(hook)) revert INVALID_HOOK();
            // Check if the hook was validated
            if (!_validateHook(hook, args.hookCalldata[i], args.globalProofs[i], args.strategyProofs[i])) {
                revert HOOK_VALIDATION_FAILED();
            }
            if (args.expectedAssetsOrSharesOut[i] == 0) revert ZERO_EXPECTED_VALUE();

            intendedShares += ISuperHookInflowOutflow(hook).decodeAmount(args.hookCalldata[i]);
        }

        // Enforce both lower- and upper-bounds on intended shares to prevent escrow overburn
        if (intendedShares + TOLERANCE_CONSTANT < totalRequestedShares) {
            revert INVALID_REDEEM_FILL();
        }

        if (intendedShares > totalRequestedShares + TOLERANCE_CONSTANT) {
            revert INVALID_REDEEM_FILL();
        }

        uint256 processedShares;
        for (uint256 i; i < hooksLength; ++i) {
            address hook = args.hooks[i];
            uint256 amountSharesSpent = _processSingleFulfillHookExecution(
                hook, args.hookCalldata[i], args.expectedAssetsOrSharesOut[i], currentPPS
            );
            processedShares += amountSharesSpent;
        }

        // Post-condition: processed shares must match intended shares
        if (processedShares != intendedShares) revert INVALID_REDEEM_FILL();

        _processRedeemFulfillments(args.controllers, controllersLength, currentPPS);

        ISuperVault(_vault).burnShares(processedShares);

        emit RedeemRequestsFulfilled(args.hooks, args.controllers, processedShares, currentPPS);
    }

    /// @inheritdoc ISuperVaultStrategy
    function fulfillRedeemsFromLiquidity(address[] memory controllers) external payable nonReentrant {
        (uint256 controllersLength, uint256 currentPPS, uint256 totalRequestedShares) =
            _precheckAndGetRedeemTotals(controllers);

        uint256 processedShares;
        for (uint256 i; i < controllersLength; ++i) {
            processedShares += _processLiquidityRedeemFulfillment(controllers[i], currentPPS);
        }

        // Post-condition: processed shares must match intended shares
        if (processedShares != totalRequestedShares) revert INVALID_REDEEM_FILL();

        ISuperVault(_vault).burnShares(processedShares);

        emit RedeemRequestsFulfilledFromLiquidity(controllers, processedShares, currentPPS);
    }

    /*//////////////////////////////////////////////////////////////
                        YIELD SOURCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    // @inheritdoc ISuperVaultStrategy
    function manageYieldSource(address source, address oracle, uint8 actionType) external {
        _isPrimaryManager(msg.sender);
        _manageYieldSource(source, oracle, actionType);
    }

    // @inheritdoc ISuperVaultStrategy
    function manageYieldSources(
        address[] calldata sources,
        address[] calldata oracles,
        uint8[] calldata actionTypes
    )
        external
    {
        _isPrimaryManager(msg.sender);

        uint256 length = sources.length;
        if (length == 0) revert ZERO_LENGTH();
        if (oracles.length != length) revert INVALID_ARRAY_LENGTH();
        if (actionTypes.length != length) revert INVALID_ARRAY_LENGTH();

        for (uint256 i; i < length; ++i) {
            _manageYieldSource(sources[i], oracles[i], actionTypes[i]);
        }
    }

    // @inheritdoc ISuperVaultStrategy
    function proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    )
        external
    {
        _isPrimaryManager(msg.sender);

        if (performanceFeeBps > BPS_PRECISION) revert INVALID_PERFORMANCE_FEE_BPS();
        if (managementFeeBps > BPS_PRECISION) revert INVALID_PERFORMANCE_FEE_BPS();
        if (recipient == address(0)) revert ZERO_ADDRESS();
        proposedFeeConfig = FeeConfig({
            performanceFeeBps: performanceFeeBps,
            managementFeeBps: managementFeeBps,
            recipient: recipient
        });
        feeConfigEffectiveTime = block.timestamp + ONE_WEEK;
        emit VaultFeeConfigProposed(performanceFeeBps, managementFeeBps, recipient, feeConfigEffectiveTime);
    }

    // @inheritdoc ISuperVaultStrategy
    function executeVaultFeeConfigUpdate() external {
        if (block.timestamp < feeConfigEffectiveTime) revert INVALID_TIMESTAMP();
        if (proposedFeeConfig.recipient == address(0)) revert ZERO_ADDRESS();
        feeConfig = proposedFeeConfig;
        delete proposedFeeConfig;
        feeConfigEffectiveTime = 0;
        emit VaultFeeConfigUpdated(feeConfig.performanceFeeBps, feeConfig.managementFeeBps, feeConfig.recipient);
    }

    // @inheritdoc ISuperVaultStrategy
    function updateMaxPPSSlippage(uint256 maxSlippageBps) external {
        _isPrimaryManager(msg.sender);
        if (maxSlippageBps > BPS_PRECISION) revert INVALID_MAX_SLIPPAGE_BPS();
        _maxPPSSlippage = maxSlippageBps;
        emit MaxPPSSlippageUpdated(maxSlippageBps);
    }

    /// @inheritdoc ISuperVaultStrategy
    function manageEmergencyWithdraw(uint8 action, address recipient, uint256 amount) external {
        if (action == 1) {
            _proposeEmergencyWithdraw();
        } else if (action == 2) {
            _performEmergencyWithdraw(recipient, amount);
        } else if (action == 3) {
            _cancelEmergencyWithdrawProposal();
        } else {
            revert ACTION_TYPE_DISALLOWED();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultStrategy
    function moveAccumulatorOnTransfer(address from, address to, uint256 shares) external {
        _requireVault();
        if (shares == 0) return;

        SuperVaultState storage fromState = superVaultState[from];
        SuperVaultState storage toState = superVaultState[to];

        // Only move accumulator proportional to what's available
        // (accumulator shares may be less than ERC20 shares due to pending redeems)
        // see test_Fix1_AuditAttackScenarioFails
        uint256 availableAccumulatorShares = fromState.accumulatorShares;
        if (availableAccumulatorShares == 0) return; // No accumulator to move

        uint256 sharesToMove = shares > availableAccumulatorShares ? availableAccumulatorShares : shares;

        // Pro-rata move of cost basis (NO PPS here; preserves fee correctness)
        uint256 movedCostBasis = sharesToMove == availableAccumulatorShares
            ? fromState.accumulatorCostBasis
            : Math.mulDiv(sharesToMove, fromState.accumulatorCostBasis, availableAccumulatorShares, Math.Rounding.Floor);

        fromState.accumulatorShares -= sharesToMove;
        fromState.accumulatorCostBasis -= movedCostBasis;

        toState.accumulatorShares += sharesToMove;
        toState.accumulatorCostBasis += movedCostBasis;

        // Never touch: pendingRedeemRequest, averageRequestPPS, maxWithdraw, averageWithdrawPrice
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // @inheritdoc ISuperVaultStrategy
    function getVaultInfo() external view returns (address vault, address asset, uint8 vaultDecimals) {
        vault = _vault;
        asset = address(_asset);
        vaultDecimals = _vaultDecimals;
    }

    // @inheritdoc ISuperVaultStrategy
    function getConfigInfo() external view returns (FeeConfig memory feeConfig_) {
        feeConfig_ = feeConfig;
    }

    // @inheritdoc ISuperVaultStrategy
    function getStoredPPS() public view returns (uint256) {
        return _getSuperVaultAggregator().getPPS(address(this));
    }

    // @inheritdoc ISuperVaultStrategy
    function getSuperVaultState(address controller) external view returns (SuperVaultState memory state) {
        return superVaultState[controller];
    }

    // @inheritdoc ISuperVaultStrategy
    function getYieldSource(address source) external view returns (YieldSource memory) {
        return YieldSource({ oracle: yieldSources[source] });
    }

    // @inheritdoc ISuperVaultStrategy
    function getYieldSourcesList() external view returns (YieldSourceInfo[] memory) {
        uint256 length = yieldSourcesList.length();
        YieldSourceInfo[] memory sourcesInfo = new YieldSourceInfo[](length);

        for (uint256 i; i < length; ++i) {
            address sourceAddress = yieldSourcesList.at(i);
            address oracle = yieldSources[sourceAddress];

            sourcesInfo[i] = YieldSourceInfo({ sourceAddress: sourceAddress, oracle: oracle });
        }

        return sourcesInfo;
    }

    // @inheritdoc ISuperVaultStrategy
    function getYieldSources() external view returns (address[] memory) {
        return yieldSourcesList.values();
    }

    // @inheritdoc ISuperVaultStrategy
    function getYieldSourcesCount() external view returns (uint256) {
        return yieldSourcesList.length();
    }

    // @inheritdoc ISuperVaultStrategy
    function containsYieldSource(address source) external view returns (bool) {
        return yieldSourcesList.contains(source);
    }

    // @inheritdoc ISuperVaultStrategy
    function pendingRedeemRequest(address controller) external view returns (uint256 pendingShares) {
        return superVaultState[controller].pendingRedeemRequest;
    }

    // @inheritdoc ISuperVaultStrategy
    function claimableWithdraw(address controller) external view returns (uint256 claimableAssets) {
        return superVaultState[controller].maxWithdraw;
    }

    // @inheritdoc ISuperVaultStrategy
    function getAverageWithdrawPrice(address controller) external view returns (uint256 averageWithdrawPrice) {
        return superVaultState[controller].averageWithdrawPrice;
    }

    // @inheritdoc ISuperVaultStrategy
    function previewPerformanceFee(
        address controller,
        uint256 sharesToRedeem
    )
        external
        view
        returns (uint256 totalFee, uint256 superformFee, uint256 recipientFee)
    {
        if (sharesToRedeem == 0) return (0, 0, 0);

        // Get controller's state
        SuperVaultState storage state = superVaultState[controller];

        // Check if controller has enough shares
        if (sharesToRedeem > state.accumulatorShares) return (0, 0, 0);

        // Get the current price per share
        uint256 currentPPS = getStoredPPS();

        // Calculate historical assets (cost basis)
        uint256 historicalAssets = 0;
        if (state.accumulatorShares > 0) {
            historicalAssets =
                sharesToRedeem.mulDiv(state.accumulatorCostBasis, state.accumulatorShares, Math.Rounding.Floor);
        }

        // Calculate current value of shares in asset terms
        uint256 currentAssetsWithFees = sharesToRedeem.mulDiv(currentPPS, PRECISION, Math.Rounding.Floor);

        // Calculate fee (if any) using same logic as _calculateAndTransferFee
        if (currentAssetsWithFees > historicalAssets) {
            uint256 profit = currentAssetsWithFees - historicalAssets;
            uint256 performanceFeeBps = feeConfig.performanceFeeBps;
            totalFee = profit.mulDiv(performanceFeeBps, BPS_PRECISION, Math.Rounding.Ceil);

            if (totalFee > 0) {
                // Calculate Superform's portion of the fee using revenueShare from SuperGovernor
                superformFee = totalFee.mulDiv(
                    superGovernor.getFee(FeeType.SUPER_VAULT_PERFORMANCE_FEE), BPS_PRECISION, Math.Rounding.Floor
                );
                recipientFee = totalFee - superformFee;
            }
        }

        return (totalFee, superformFee, recipientFee);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Process a single hook execution
    /// @param hook Hook address
    /// @param prevHook Previous hook address
    /// @param hookCalldata Hook calldata
    /// @param expectedAssetsOrSharesOut Expected assets or shares output
    /// @return processedHook Processed hook address
    function _processSingleHookExecution(
        address hook,
        address prevHook,
        bytes memory hookCalldata,
        uint256 expectedAssetsOrSharesOut
    )
        internal
        returns (address)
    {
        ExecutionVars memory vars;
        vars.hookContract = ISuperHook(hook);

        vars.targetedYieldSource = HookDataDecoder.extractYieldSource(hookCalldata);

        // Bool flagging if the hook uses the previous hook's outAmount
        // @dev No slippage checks performed here as they have already been performed in the previous hook execution
        bool usePrevHookAmount = _decodeHookUsePrevHookAmount(hook, hookCalldata);

        ISuperHook(address(vars.hookContract)).setExecutionContext(address(this));
        vars.executions = vars.hookContract.build(prevHook, address(this), hookCalldata);
        for (uint256 j; j < vars.executions.length; ++j) {
            (vars.success,) =
                vars.executions[j].target.call{ value: vars.executions[j].value }(vars.executions[j].callData);
            if (!vars.success) revert OPERATION_FAILED();
        }
        ISuperHook(address(vars.hookContract)).resetExecutionState(address(this));

        uint256 actualOutput = ISuperHookResult(hook).getOutAmount(address(this));

        if (actualOutput < expectedAssetsOrSharesOut) {
            revert MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET();
        }

        emit HookExecuted(hook, prevHook, vars.targetedYieldSource, usePrevHookAmount, hookCalldata);

        return hook;
    }

    /// @notice Process redeem fulfillments for multiple controllers
    /// @param controllers Array of controller addresses
    /// @param controllersLength Length of controllers array
    /// @param currentPPS Current price per share
    function _processRedeemFulfillments(
        address[] calldata controllers,
        uint256 controllersLength,
        uint256 currentPPS
    ) internal {
        for (uint256 i; i < controllersLength; ++i) {
            _processSingleRedeemFulfillment(controllers[i], currentPPS);
        }
    }

    /// @notice Process redeem fulfillment for one controller (shared by all redeem types)
    function _processLiquidityRedeemFulfillment(
        address controller,
        uint256 currentPPS
    ) internal returns (uint256 processedShares) {
        return _processSingleRedeemFulfillment(controller, currentPPS);
    }

    /// @notice Process a single hook fulfillment execution
    /// @param hook Hook address
    /// @param hookCalldata Hook calldata
    /// @param expectedAssetOutput Expected asset output
    /// @param currentPPS Current price per share
    /// @return processedShares Processed shares
    function _processSingleFulfillHookExecution(
        address hook,
        bytes memory hookCalldata,
        uint256 expectedAssetOutput,
        uint256 currentPPS
    )
        internal
        returns (uint256)
    {
        OutflowExecutionVars memory vars;
        vars.hookContract = ISuperHook(hook);
        vars.hookType = ISuperHookResult(hook).hookType();
        if (vars.hookType != ISuperHook.HookType.OUTFLOW) revert INVALID_HOOK_TYPE();

        vars.targetedYieldSource = HookDataDecoder.extractYieldSource(hookCalldata);
        if (yieldSources[vars.targetedYieldSource] == address(0)) revert YIELD_SOURCE_NOT_FOUND();

        // we must always encode supervault shares when fulfilling redemptions
        vars.superVaultShares = ISuperHookInflowOutflow(hook).decodeAmount(hookCalldata);

        // Calculate underlying shares and update hook calldata
        vars.amountOfAssets = vars.superVaultShares.mulDiv(currentPPS, PRECISION, Math.Rounding.Floor);
        vars.svAsset = address(_asset);
        vars.amountConvertedToUnderlyingShares = IYieldSourceOracle(yieldSources[vars.targetedYieldSource])
            .getShareOutput(vars.targetedYieldSource, vars.svAsset, vars.amountOfAssets);
        hookCalldata =
            ISuperHookOutflow(hook).replaceCalldataAmount(hookCalldata, vars.amountConvertedToUnderlyingShares);

        vars.balanceAssetBefore = _getTokenBalance(vars.svAsset, address(this));

        ISuperHook(address(vars.hookContract)).setExecutionContext(address(this));

        vars.executions = vars.hookContract.build(address(0), address(this), hookCalldata);
        for (uint256 j; j < vars.executions.length; ++j) {
            (vars.success,) = vars.executions[j].target.call(vars.executions[j].callData);
            if (!vars.success) revert OPERATION_FAILED();
        }
        ISuperHook(address(vars.hookContract)).resetExecutionState(address(this));

        vars.outAmount = _getTokenBalance(vars.svAsset, address(this)) - vars.balanceAssetBefore;

        if (vars.outAmount == 0) revert ZERO_OUTPUT_AMOUNT();
        if (vars.outAmount < expectedAssetOutput) {
            revert MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET();
        }
        emit FulfillHookExecuted(hook, vars.targetedYieldSource, hookCalldata);

        return vars.superVaultShares;
    }

    /// @notice Process redeem fulfillment for one controller (shared by all redeem types)
    /// ->_processSingleRedeemFulfillment
    ///     -> _calculateAssetsAndProcessFees
    ///         -> _computeAndTranferFees
    ///         -> _updateAverageWithdrawPrice
    function _processSingleRedeemFulfillment(
        address controller,
        uint256 currentPPS
    ) private returns (uint256 processedShares) {
        SuperVaultState storage state = superVaultState[controller];
        uint256 requested = state.pendingRedeemRequest;

        // PPS slippage guard
        if (state.averageRequestPPS > 0 && _maxPPSSlippage > 0 && currentPPS < state.averageRequestPPS) {
            uint256 decrease = (state.averageRequestPPS - currentPPS)
                .mulDiv(BPS_PRECISION, state.averageRequestPPS, Math.Rounding.Floor);
            if (decrease > _maxPPSSlippage) revert SLIPPAGE_EXCEEDED();
        }

        uint256 assets = _calculateAssetsAndProcessFees(state, requested, currentPPS);

        // Update state
        state.pendingRedeemRequest = 0;
        state.maxWithdraw += assets;
        state.averageRequestPPS = 0;

        // Notify vault
        _onRedeemClaimable(
            controller,
            assets,
            requested,
            state.averageWithdrawPrice,
            state.accumulatorShares,
            state.accumulatorCostBasis
        );

        return requested;
    }

    /// @notice Calculate cost basis for requested shares using weighted average approach
    /// @param state User's vault state
    /// @param requestedShares Shares being redeemed
    function _calculateCostBasis(
        SuperVaultState storage state,
        uint256 requestedShares
    )
        private
        returns (uint256 costBasis)
    {
        if (requestedShares > state.accumulatorShares) revert INSUFFICIENT_SHARES();

        // Calculate cost basis proportionally
        costBasis = requestedShares.mulDiv(state.accumulatorCostBasis, state.accumulatorShares, Math.Rounding.Floor);

        // Update user's accumulator state
        state.accumulatorShares -= requestedShares;
        state.accumulatorCostBasis -= costBasis;

        return costBasis;
    }

    // --- Fee Processing ---
    /// @notice Calculate fee on profit and transfer to recipients
    /// @dev Used by both standard and liquidity redeem paths
    function _computeAndTranferFees(
        uint256 currentAssetsWithFees,
        uint256 historicalAssets
    ) private returns (uint256 currentAssets) {
        currentAssets = currentAssetsWithFees;
        if (currentAssetsWithFees <= historicalAssets) return currentAssets;

        uint256 profit = currentAssetsWithFees - historicalAssets;
        uint256 performanceFeeBps = feeConfig.performanceFeeBps;
        uint256 totalFee = profit.mulDiv(performanceFeeBps, BPS_PRECISION, Math.Rounding.Ceil);
        if (totalFee == 0) return currentAssets;

        // Split Superform vs recipient
        uint256 superformFee = totalFee.mulDiv(
            superGovernor.getFee(FeeType.SUPER_VAULT_PERFORMANCE_FEE),
            BPS_PRECISION,
            Math.Rounding.Floor
        );
        uint256 recipientFee = totalFee - superformFee;

        // Transfer Superform fee
        if (superformFee > 0) {
            address treasury = superGovernor.getAddress(superGovernor.TREASURY());
            _safeTokenTransfer(address(_asset), treasury, superformFee);
            emit FeePaid(treasury, superformFee, performanceFeeBps);
        }

        // Transfer recipient fee
        if (recipientFee > 0) {
            address recipient = feeConfig.recipient;
            if (recipient == address(0)) revert ZERO_ADDRESS();
            _safeTokenTransfer(address(_asset), recipient, recipientFee);
            emit FeePaid(recipient, recipientFee, performanceFeeBps);
        }

        return currentAssetsWithFees - totalFee;
    }

    function _calculateAssetsAndProcessFees(
        SuperVaultState storage state,
        uint256 requestedShares,
        uint256 currentPricePerShare
    ) private returns (uint256 currentAssets) {
        uint256 historicalAssets = _calculateCostBasis(state, requestedShares);
        uint256 currentAssetsWithFees =
            requestedShares.mulDiv(currentPricePerShare, PRECISION, Math.Rounding.Floor);
        uint256 currentAssetsAfterFees =
            _computeAndTranferFees(currentAssetsWithFees, historicalAssets);

        uint256 balance = _getTokenBalance(address(_asset), address(this));
        if (currentAssetsAfterFees > balance) currentAssetsAfterFees = balance;

        if (requestedShares > 0) {
            _updateAverageWithdrawPrice(state, requestedShares, currentAssetsWithFees);
        }

        return currentAssetsAfterFees;
    }

    /// @notice Internal function to update the average withdraw price
    /// @param state Storage reference to the vault state
    /// @param requestedShares Number of shares requested
    /// @param currentAssetsWithFees Current assets with fees
    function _updateAverageWithdrawPrice(
        SuperVaultState storage state,
        uint256 requestedShares,
        uint256 currentAssetsWithFees
    ) private {
        uint256 existingShares;
        uint256 existingAssets;

        if (state.maxWithdraw > 0 && state.averageWithdrawPrice > 0) {
            existingShares = state.maxWithdraw.mulDiv(
                PRECISION,
                state.averageWithdrawPrice,
                Math.Rounding.Floor
            );
            existingAssets = state.maxWithdraw;
        }

        uint256 newTotalShares = existingShares + requestedShares;
        uint256 newTotalAssets = existingAssets + currentAssetsWithFees;

        if (newTotalShares > 0) {
            state.averageWithdrawPrice = newTotalAssets.mulDiv(
                PRECISION,
                newTotalShares,
                Math.Rounding.Floor
            );
        }
    }


    /// @notice Internal function to get the SuperVaultAggregator
    /// @return The SuperVaultAggregator
    function _getSuperVaultAggregator() internal view returns (ISuperVaultAggregator) {
        address aggregatorAddress = superGovernor.getAddress(superGovernor.SUPER_VAULT_AGGREGATOR());

        return ISuperVaultAggregator(aggregatorAddress);
    }

    /// @notice Internal function to check if a manager is authorized
    /// @param manager_ The manager to check
    function _isManager(address manager_) internal view {
        if (!_getSuperVaultAggregator().isAnyManager(manager_, address(this))) {
            revert MANAGER_NOT_AUTHORIZED();
        }
    }

    /// @notice Internal function to check if a manager is the primary manager
    /// @param manager_ The manager to check
    function _isPrimaryManager(address manager_) internal view {
        if (!_getSuperVaultAggregator().isMainManager(manager_, address(this))) {
            revert MANAGER_NOT_AUTHORIZED();
        }
    }

    /// @notice Internal function to manage a yield source
    /// @param source Address of the yield source
    /// @param oracle Address of the oracle
    /// @param actionType Type of action: 0=Add, 1=UpdateOracle, 2=Remove
    function _manageYieldSource(address source, address oracle, uint8 actionType) internal {
        if (actionType == 0) {
            _addYieldSource(source, oracle);
        } else if (actionType == 1) {
            _updateYieldSourceOracle(source, oracle);
        } else if (actionType == 2) {
            _removeYieldSource(source);
        } else {
            revert ACTION_TYPE_DISALLOWED();
        }
    }

    /// @notice Internal function to add a yield source
    /// @param source Address of the yield source
    /// @param oracle Address of the oracle
    function _addYieldSource(address source, address oracle) internal {
        if (source == address(0) || oracle == address(0)) revert ZERO_ADDRESS();
        if (yieldSources[source] != address(0)) revert YIELD_SOURCE_ALREADY_EXISTS();
        yieldSources[source] = oracle;
        if (!yieldSourcesList.add(source)) revert YIELD_SOURCE_ALREADY_EXISTS();

        emit YieldSourceAdded(source, oracle);
    }

    /// @notice Internal function to update a yield source's oracle
    /// @param source Address of the yield source
    /// @param oracle Address of the oracle
    function _updateYieldSourceOracle(address source, address oracle) internal {
        if (oracle == address(0)) revert ZERO_ADDRESS();
        address oldOracle = yieldSources[source];
        if (oldOracle == address(0)) revert YIELD_SOURCE_NOT_FOUND();
        yieldSources[source] = oracle;

        emit YieldSourceOracleUpdated(source, oldOracle, oracle);
    }

    /// @notice Internal function to remove a yield source
    /// @param source Address of the yield source
    function _removeYieldSource(address source) internal {
        if (yieldSources[source] == address(0)) revert YIELD_SOURCE_NOT_FOUND();

        // Remove from mapping
        delete yieldSources[source];

        // Remove from EnumerableSet
        if (!yieldSourcesList.remove(source)) revert YIELD_SOURCE_NOT_FOUND();

        emit YieldSourceRemoved(source);
    }

    /// @notice Internal function to propose an emergency withdraw
    function _proposeEmergencyWithdraw() internal {
        _isPrimaryManager(msg.sender);

        if (proposedEmergencyWithdrawable) revert ALREADY_PROPOSED();

        proposedEmergencyWithdrawable = true;
        emergencyWithdrawableEffectiveTime = block.timestamp + ONE_WEEK;

        emit EmergencyWithdrawableProposed(true, emergencyWithdrawableEffectiveTime);
    }

    /// @notice Internal function to cancel an emergency withdraw proposal
    function _cancelEmergencyWithdrawProposal() internal {
        _isPrimaryManager(msg.sender);

        if (emergencyWithdrawableEffectiveTime == 0) revert NO_PROPOSAL();

        proposedEmergencyWithdrawable = false;
        emergencyWithdrawableEffectiveTime = 0;

        emit EmergencyWithdrawableProposalCanceled();
    }

    /// @notice Internal function to perform an emergency withdraw
    /// @param recipient Address to receive the assets
    /// @param amount Amount of assets to withdraw
    function _performEmergencyWithdraw(address recipient, uint256 amount) internal {
        _isPrimaryManager(msg.sender);

        // Must have a valid proposal
        if (!proposedEmergencyWithdrawable) revert NO_PROPOSAL();
        if (block.timestamp < emergencyWithdrawableEffectiveTime) revert INVALID_TIMESTAMP();

        if (recipient == address(0)) revert ZERO_ADDRESS();

        uint256 freeAssets = _getTokenBalance(address(_asset), address(this));
        if (amount == 0 || amount > freeAssets) revert INSUFFICIENT_FUNDS();

        _safeTokenTransfer(address(_asset), recipient, amount);

        emit EmergencyWithdrawal(recipient, amount);
    }

    /// @notice Internal function to check if a hook is a fulfill requests hook
    /// @param hook Address of the hook
    /// @return True if the hook is a fulfill requests hook, false otherwise
    function _isFulfillRequestsHook(address hook) private view returns (bool) {
        return superGovernor.isFulfillRequestsHookRegistered(hook);
    }

    /// @notice Internal function to check if a hook is registered
    /// @param hook Address of the hook
    /// @return True if the hook is registered, false otherwise
    function _isRegisteredHook(address hook) private view returns (bool) {
        return superGovernor.isHookRegistered(hook);
    }

    /// @notice Internal function to decode a hook's use previous hook amount
    /// @param hook Address of the hook
    /// @param hookCalldata Call data for the hook
    /// @return True if the hook should use the previous hook amount, false otherwise
    function _decodeHookUsePrevHookAmount(address hook, bytes memory hookCalldata) private pure returns (bool) {
        try ISuperHookContextAware(hook).decodeUsePrevHookAmount(hookCalldata) returns (bool usePrevHookAmount) {
            return usePrevHookAmount;
        } catch {
            return false;
        }
    }

    /// @notice Internal function to get the previous hook's output amount
    /// @param prevHook Address of the previous hook
    /// @return Output amount of the previous hook
    function _getPreviousHookOutAmount(address prevHook) private view returns (uint256) {
        return ISuperHookResultOutflow(prevHook).getOutAmount(address(this));
    }

    /// @notice Internal function to handle a redeem claimable
    /// @param controller Address of the controller
    /// @param assetsFulfilled Amount of assets fulfilled
    /// @param sharesFulfilled Amount of shares fulfilled
    /// @param averageWithdrawPrice Average withdraw price
    /// @param accumulatorShares Accumulator shares
    /// @param accumulatorCostBasis Accumulator cost basis
    function _onRedeemClaimable(
        address controller,
        uint256 assetsFulfilled,
        uint256 sharesFulfilled,
        uint256 averageWithdrawPrice,
        uint256 accumulatorShares,
        uint256 accumulatorCostBasis
    )
        private
    {
        ISuperVault(_vault).onRedeemClaimable(
            controller, assetsFulfilled, sharesFulfilled, averageWithdrawPrice, accumulatorShares, accumulatorCostBasis
        );
    }

    /// @notice Internal function to handle a redeem
    /// @param controller Address of the controller
    /// @param shares Amount of shares
    function _handleRequestRedeem(address controller, uint256 shares) private {
        if (shares == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();
        SuperVaultState storage state = superVaultState[controller];

        // Defense-in-depth: assert controller has accumulator shares
        if (state.accumulatorShares == 0) revert INSUFFICIENT_SHARES();

        // Get current PPS from aggregator to use as baseline for slippage protection
        uint256 currentPPS = getStoredPPS();
        if (currentPPS == 0) revert INVALID_PPS();

        // Calculate weighted average of PPS if there's an existing request
        if (state.pendingRedeemRequest > 0) {
            // Calculate weighted average of PPS based on share amounts
            uint256 existingSharesInRequest = state.pendingRedeemRequest;
            uint256 newTotalSharesInRequest = existingSharesInRequest + shares;

            // Use weighted average formula: (existingShares * existingPPS + newShares * currentPPS) / totalShares
            state.averageRequestPPS =
                ((existingSharesInRequest * state.averageRequestPPS) + (shares * currentPPS)) / newTotalSharesInRequest;

            // Update total shares
            state.pendingRedeemRequest = newTotalSharesInRequest;
        } else {
            // First request for this controller
            state.pendingRedeemRequest = shares;
            state.averageRequestPPS = currentPPS;
        }

        emit RedeemRequestPlaced(controller, controller, shares);
    }

    /// @notice Internal function to handle a redeem cancellation
    /// @param controller Address of the controller
    function _handleCancelRedeem(address controller) private {
        if (controller == address(0)) revert ZERO_ADDRESS();
        SuperVaultState storage state = superVaultState[controller];
        uint256 pendingShares = state.pendingRedeemRequest;
        if (pendingShares == 0) revert REQUEST_NOT_FOUND();
        // Only clear pending request metadata
        state.pendingRedeemRequest = 0;
        state.averageRequestPPS = 0;
        emit RedeemRequestCanceled(controller, pendingShares);
    }

    /// @notice Internal function to handle a redeem claim
    /// @param controller Address of the controller
    /// @param receiver Address of the receiver
    /// @param assetsToClaim Amount of assets to claim
    function _handleClaimRedeem(address controller, address receiver, uint256 assetsToClaim) private {
        if (assetsToClaim == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();
        SuperVaultState storage state = superVaultState[controller];

        // Handle dust collection for rounding errors
        uint256 actualAmountToClaim = assetsToClaim;
        uint256 remainingAssets = _asset.balanceOf(address(this));

        // If user is requesting slightly more than available due to rounding errors,
        // and the difference is small (dust), give them the remaining balance
        if (assetsToClaim > remainingAssets && assetsToClaim - remainingAssets <= TOLERANCE_CONSTANT) {
            actualAmountToClaim = remainingAssets;
        }

        if (state.maxWithdraw < actualAmountToClaim) revert INVALID_REDEEM_CLAIM();
        state.maxWithdraw -= actualAmountToClaim;
        _asset.safeTransfer(receiver, actualAmountToClaim);
        emit RedeemRequestFulfilled(receiver, controller, actualAmountToClaim, 0);
    }

    /// @notice Internal function to safely transfer tokens
    /// @param token Address of the token
    /// @param recipient Address to receive the tokens
    /// @param amount Amount of tokens to transfer
    function _safeTokenTransfer(address token, address recipient, uint256 amount) private {
        if (amount > 0) IERC20(token).safeTransfer(recipient, amount);
    }

    /// @notice Internal function to get the token balance of an account
    /// @param token Address of the token
    /// @param account Address of the account
    /// @return Token balance of the account
    function _getTokenBalance(address token, address account) private view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

    /// @notice Internal function to check if the caller is the vault
    /// @dev This is used to prevent unauthorized access to certain functions
    function _requireVault() internal view {
        if (msg.sender != _vault) revert ACCESS_DENIED();
    }

    /// @notice Checks if the strategy is currently paused
    /// @dev This calls SuperVaultAggregator.isStrategyPaused to determine pause status
    /// @return True if the strategy is paused, false otherwise
    function _isPaused() internal view returns (bool) {
        return _getSuperVaultAggregator().isStrategyPaused(address(this));
    }

    /// @notice Validates a hook using the Merkle root system
    /// @param hook Address of the hook to validate
    /// @param hookCalldata Calldata to be passed to the hook
    /// @param globalProof Merkle proof for the global root
    /// @param strategyProof Merkle proof for the strategy-specific root
    /// @return isValid True if the hook is valid, false otherwise
    function _validateHook(
        address hook,
        bytes memory hookCalldata,
        bytes32[] memory globalProof,
        bytes32[] memory strategyProof
    )
        internal
        view
        returns (bool)
    {
        return _getSuperVaultAggregator().validateHook(
            address(this),
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hook,
                hookArgs: ISuperHookInspector(hook).inspect(hookCalldata),
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
    }

    function _precheckAndGetRedeemTotals(address[] memory controllers)
        private
        view
        returns (uint256 controllersLength, uint256 currentPPS, uint256 totalRequestedShares)
    {
        _isManager(msg.sender);

        if (_isPaused()) revert STRATEGY_PAUSED();

        controllersLength = controllers.length;
        if (controllersLength == 0) revert ZERO_LENGTH();

        currentPPS = getStoredPPS();
        if (currentPPS == 0) revert INVALID_PPS();

        for (uint256 i; i < controllersLength; ++i) {
            totalRequestedShares += superVaultState[controllers[i]].pendingRedeemRequest;
        }
    }
}
