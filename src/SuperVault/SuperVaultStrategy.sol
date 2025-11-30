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
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { LibSort } from "solady/utils/LibSort.sol";

// Core Interfaces
import {
    ISuperHook,
    ISuperHookResult,
    ISuperHookContextAware,
    ISuperHookInspector
} from "@superform-v2-core/src/interfaces/ISuperHook.sol";

// Periphery Interfaces
import { ISuperVault } from "../interfaces/SuperVault/ISuperVault.sol";
import { HookDataDecoder } from "@superform-v2-core/src/libraries/HookDataDecoder.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperGovernor, FeeType } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVaultAccountingLib } from "../libraries/SuperVaultAccountingLib.sol";
import { AssetMetadataLib } from "../libraries/AssetMetadataLib.sol";

/// @title SuperVaultStrategy
/// @author Superform Labs
/// @notice Strategy implementation for SuperVault that executes strategies
contract SuperVaultStrategy is ISuperVaultStrategy, Initializable, ReentrancyGuardUpgradeable {
    using LibSort for address[];

    using EnumerableSet for EnumerableSet.AddressSet;
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

    /// @dev Minimum allowed staleness threshold for PPS updates (prevents too-frequent validation)
    uint256 private constant MIN_PPS_EXPIRATION_THRESHOLD = 1 minutes;

    /// @dev Maximum allowed staleness threshold for PPS updates (prevents indefinite stale data usage)
    uint256 private constant MAX_PPS_EXPIRATION_THRESHOLD = 1 weeks;

    /// @dev Timelock period after unpause during which performance fee skimming is disabled (rug prevention)
    uint256 private constant POST_UNPAUSE_SKIM_TIMELOCK = 12 hours;

    /// @dev Timelock duration for fee config and PPS expiration threshold updates
    uint256 private constant PROPOSAL_TIMELOCK = 1 weeks;

    uint256 public PRECISION; // Slot 0: 32 bytes

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    // Packed slot 1: saves 1 storage slot
    address private _vault; // 20 bytes
    uint8 private _vaultDecimals; // 1 byte
    uint88 private __gap1; // 11 bytes padding

    // Packed slot 2
    IERC20 private _asset; // 20 bytes (address)
    uint96 private __gap2; // 12 bytes padding

    // Global configuration

    // Fee configuration
    FeeConfig private feeConfig; // Slots 3-5 (96 bytes: 2 uint256 + 1 address)
    FeeConfig private proposedFeeConfig;
    uint256 private feeConfigEffectiveTime;

    // Core contracts
    ISuperGovernor public immutable SUPER_GOVERNOR;

    // PPS expiry threshold
    uint256 public proposedPPSExpiryThreshold;
    uint256 public ppsExpiryThresholdEffectiveTime;
    uint256 public ppsExpiration;

    // Yield source configuration - simplified mapping from source to oracle
    mapping(address source => address oracle) private yieldSources;
    EnumerableSet.AddressSet private yieldSourcesList;

    // --- Global Vault High-Water Mark (PPS-based) ---
    /// @notice High-water mark price-per-share for performance fee calculation
    /// @dev Represents the PPS at which performance fees were last collected
    ///      Scaled by PRECISION (e.g., 1e6 for USDC vaults, 1e18 for 18-decimal vaults)
    ///      Updated during skimPerformanceFee() when fees are taken, and in executeVaultFeeConfigUpdate()
    uint256 public vaultHwmPps;

    // --- Redeem Request State ---
    mapping(address controller => SuperVaultState state) private superVaultState;

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
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
        if (feeConfigData.performanceFeeBps > MAX_PERFORMANCE_FEE) revert INVALID_PERFORMANCE_FEE_BPS();
        if (feeConfigData.managementFeeBps > BPS_PRECISION) revert INVALID_PERFORMANCE_FEE_BPS();

        __ReentrancyGuard_init();

        _vault = vaultAddress;
        _asset = IERC20(IERC4626(vaultAddress).asset());
        _vaultDecimals = IERC20Metadata(vaultAddress).decimals();
        PRECISION = 10 ** _vaultDecimals;
        feeConfig = feeConfigData;

        ppsExpiration = 1 days;

        // Initialize HWM to 1.0 using asset decimals (same as aggregator)
        // Get asset decimals the same way aggregator does
        (bool success, uint8 assetDecimals) = address(_asset).tryGetAssetDecimals();
        if (!success) revert INVALID_ASSET();
        vaultHwmPps = 10 ** assetDecimals; // 1.0 as initial PPS (matches aggregator)

        emit Initialized(_vault);
    }

    /*//////////////////////////////////////////////////////////////
                        CORE STRATEGY OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultStrategy
    function handleOperations4626Deposit(address controller, uint256 assetsGross) external returns (uint256 sharesNet) {
        _requireVault();

        if (assetsGross == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();

        ISuperVaultAggregator aggregator = _getSuperVaultAggregator();

        if (aggregator.isGlobalHooksRootVetoed()) {
            revert OPERATIONS_BLOCKED_BY_VETO();
        }

        _validateStrategyState(aggregator);

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

        // No HWM update needed - deposits are PPS-neutral by design

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

        ISuperVaultAggregator aggregator = _getSuperVaultAggregator();

        if (aggregator.isGlobalHooksRootVetoed()) {
            revert OPERATIONS_BLOCKED_BY_VETO();
        }

        _validateStrategyState(aggregator);

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

        // No HWM update needed - mints are PPS-neutral by design

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
        ISuperVaultAggregator aggregator = _getSuperVaultAggregator();

        if (operation == Operation.RedeemRequest) {
            _validateStrategyState(aggregator);
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
    function fulfillCancelRedeemRequests(address[] memory controllers) external nonReentrant {
        _isManager(msg.sender);

        uint256 controllersLength = controllers.length;
        if (controllersLength == 0) revert ZERO_LENGTH();

        for (uint256 i; i < controllersLength; ++i) {
            SuperVaultState storage state = superVaultState[controllers[i]];
            if (state.pendingCancelRedeemRequest) {
                state.claimableCancelRedeemRequest += state.pendingRedeemRequest;
                state.pendingRedeemRequest = 0;
                state.averageRequestPPS = 0;
                emit RedeemCancelRequestFulfilled(controllers[i], state.claimableCancelRedeemRequest);
            }
        }
    }

    /// @inheritdoc ISuperVaultStrategy
    function fulfillRedeemRequests(
        address[] calldata controllers,
        uint256[] calldata totalAssetsOut
    )
        external
        nonReentrant
    {
        _isManager(msg.sender);

        _validateStrategyState(_getSuperVaultAggregator());

        uint256 len = controllers.length;
        if (len == 0 || totalAssetsOut.length != len) revert INVALID_ARRAY_LENGTH();

        FulfillRedeemVars memory vars;
        vars.currentPPS = getStoredPPS();
        if (vars.currentPPS == 0) revert INVALID_PPS();

        // Process each controller with all validations in one loop
        for (uint256 i; i < len; ++i) {
            // Validate controllers are sorted and unique
            if (i > 0 && controllers[i] <= controllers[i - 1]) revert CONTROLLERS_NOT_SORTED_UNIQUE();

            // Load pending shares into memory and accumulate total
            uint256 pendingShares = superVaultState[controllers[i]].pendingRedeemRequest;
            vars.totalRequestedShares += pendingShares;

            // Disallow fulfillment for controllers with zero pending shares
            if (pendingShares == 0) revert ZERO_SHARE_FULFILLMENT_DISALLOWED();

            // Process fulfillment and accumulate assets
            _processExactFulfillmentBatch(controllers[i], totalAssetsOut[i], vars.currentPPS, pendingShares);
            vars.totalNetAssetsOut += totalAssetsOut[i];
        }

        // Balance check (no fees expected)
        vars.strategyBalance = _getTokenBalance(address(_asset), address(this));
        if (vars.strategyBalance < vars.totalNetAssetsOut) {
            revert INSUFFICIENT_LIQUIDITY();
        }

        // Burn shares
        ISuperVault(_vault).burnShares(vars.totalRequestedShares);

        // Transfer net assets to escrow
        if (vars.totalNetAssetsOut > 0) {
            _asset.safeTransfer(ISuperVault(_vault).escrow(), vars.totalNetAssetsOut);
        }

        emit RedeemRequestsFulfilled(controllers, vars.totalRequestedShares, vars.currentPPS);
    }

    /// @notice Skim performance fees based on per-share High Water Mark
    /// @dev Can be called by any manager when vault PPS has grown above HWM
    /// @dev Uses PPS-based HWM which eliminates redemption-related vulnerabilities
    function skimPerformanceFee() external nonReentrant {
        _isManager(msg.sender);

        ISuperVaultAggregator aggregator = _getSuperVaultAggregator();
        _validateStrategyState(aggregator);

        // Prevent skim for 12 hours after unpause
        // This timelock gives a detection window for potential abuse of fee skimming
        // post unpausing with an abnormal PPS update
        uint256 lastUnpause = aggregator.getLastUnpauseTimestamp(address(this));
        if (block.timestamp < lastUnpause + POST_UNPAUSE_SKIM_TIMELOCK) {
            revert SKIM_TIMELOCK_ACTIVE();
        }

        IERC4626 vault = IERC4626(_vault);
        uint256 totalSupplyLocal = vault.totalSupply();

        // Early return if no supply - cannot calculate PPS or collect fees
        if (totalSupplyLocal == 0) return;

        // Get current PPS from aggregator
        uint256 currentPPS = aggregator.getPPS(address(this));
        if (currentPPS == 0) revert INVALID_PPS();

        // Get the high-water mark PPS (baseline for fee calculation)
        uint256 hwmPps = vaultHwmPps;

        // Check if there's any per-share growth above HWM
        if (currentPPS <= hwmPps) {
            // No growth above HWM, no fee to collect
            return;
        }

        // Calculate PPS growth above HWM
        uint256 ppsGrowth = currentPPS - hwmPps;

        // Calculate total profit: (PPS growth) * (total shares) / PRECISION
        // This represents the total assets gained above the high-water mark
        uint256 profit = Math.mulDiv(ppsGrowth, totalSupplyLocal, PRECISION, Math.Rounding.Floor);

        // Safety check: profit must be non-zero to collect fees
        if (profit == 0) return;

        // Calculate fee as percentage of profit
        uint256 fee = Math.mulDiv(profit, feeConfig.performanceFeeBps, BPS_PRECISION, Math.Rounding.Ceil);

        // Edge case: profit exists but fee rounds to zero
        if (fee == 0) return;

        // Split fee between Superform treasury and strategy recipient
        uint256 sfFee =
            Math.mulDiv(fee, SUPER_GOVERNOR.getFee(FeeType.PERFORMANCE_FEE_SHARE), BPS_PRECISION, Math.Rounding.Floor);
        uint256 recipientFee = fee - sfFee;

        // Check if strategy has sufficient liquid assets for fee transfer
        if (_getTokenBalance(address(_asset), address(this)) < fee) revert NOT_ENOUGH_FREE_ASSETS_FEE_SKIM();

        // Transfer fees to recipients
        _safeTokenTransfer(address(_asset), SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.TREASURY()), sfFee);
        _safeTokenTransfer(address(_asset), feeConfig.recipient, recipientFee);

        emit PerformanceFeeSkimmed(fee, sfFee);

        // Calculate the new PPS after fee extraction
        // Fee extraction reduces vault assets while shares stay constant, lowering PPS
        uint256 ppsReduction = Math.mulDiv(fee, PRECISION, totalSupplyLocal, Math.Rounding.Floor);

        // Safety check: ensure reduction doesn't crash PPS to zero
        if (ppsReduction >= currentPPS) revert INVALID_PPS();

        uint256 newPPS = currentPPS - ppsReduction;

        // Safety check: new PPS must be positive
        if (newPPS == 0) revert INVALID_PPS();

        // Update HWM to the new post-fee PPS
        // This becomes the new baseline for future fee calculations
        vaultHwmPps = newPPS;

        emit HWMPPSUpdated(newPPS, currentPPS, profit, fee);

        // Update PPS in aggregator to reflect fee extraction
        aggregator.updatePPSAfterSkim(newPPS, fee);
    }

    /*//////////////////////////////////////////////////////////////
                        YIELD SOURCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultStrategy
    function manageYieldSource(address source, address oracle, YieldSourceAction actionType) external {
        _isPrimaryManager(msg.sender);
        _manageYieldSource(source, oracle, actionType);
    }

    /// @inheritdoc ISuperVaultStrategy
    function manageYieldSources(
        address[] calldata sources,
        address[] calldata oracles,
        YieldSourceAction[] calldata actionTypes
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

    /// @inheritdoc ISuperVaultStrategy
    function changeFeeRecipient(address newRecipient) external {
        if (msg.sender != address(_getSuperVaultAggregator())) revert ACCESS_DENIED();

        feeConfig.recipient = newRecipient;
        emit FeeRecipientChanged(newRecipient);
    }

    /// @inheritdoc ISuperVaultStrategy
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

    /// @inheritdoc ISuperVaultStrategy
    function executeVaultFeeConfigUpdate() external {
        _isPrimaryManager(msg.sender);

        if (block.timestamp < feeConfigEffectiveTime) revert INVALID_TIMESTAMP();
        if (proposedFeeConfig.recipient == address(0)) revert ZERO_ADDRESS();

        // Get current PPS before updating fee config
        uint256 currentPPS = getStoredPPS();
        uint256 oldHwmPps = vaultHwmPps;

        // Update fee config
        feeConfig = proposedFeeConfig;
        delete proposedFeeConfig;
        feeConfigEffectiveTime = 0;

        // Reset HWM PPS to current PPS to avoid incorrect fee calculations with new fee structure
        vaultHwmPps = currentPPS;

        emit VaultFeeConfigUpdated(feeConfig.performanceFeeBps, feeConfig.managementFeeBps, feeConfig.recipient);
        emit HWMPPSUpdated(currentPPS, oldHwmPps, 0, 0);
    }

    /// @inheritdoc ISuperVaultStrategy
    function resetHighWaterMark(uint256 newHwmPps) external {
        if (msg.sender != address(_getSuperVaultAggregator())) revert ACCESS_DENIED();

        if (newHwmPps == 0) revert INVALID_PPS();

        vaultHwmPps = newHwmPps;

        emit HighWaterMarkReset(newHwmPps);
    }

    /// @inheritdoc ISuperVaultStrategy
    function managePPSExpiration(PPSExpirationAction action, uint256 staleness_) external {
        if (action == PPSExpirationAction.Propose) {
            _proposePPSExpiration(staleness_);
        } else if (action == PPSExpirationAction.Execute) {
            _updatePPSExpiration();
        } else if (action == PPSExpirationAction.Cancel) {
            _cancelPPSExpirationProposalUpdate();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        USER OPERATIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultStrategy
    function setRedeemSlippage(uint16 slippageBps) external {
        if (slippageBps > BPS_PRECISION) revert INVALID_REDEEM_SLIPPAGE_BPS();

        superVaultState[msg.sender].redeemSlippageBps = slippageBps;

        emit RedeemSlippageSet(msg.sender, slippageBps);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperVaultStrategy
    function getVaultInfo() external view returns (address vault, address asset, uint8 vaultDecimals) {
        vault = _vault;
        asset = address(_asset);
        vaultDecimals = _vaultDecimals;
    }

    /// @inheritdoc ISuperVaultStrategy
    function getConfigInfo() external view returns (FeeConfig memory feeConfig_) {
        feeConfig_ = feeConfig;
    }

    /// @inheritdoc ISuperVaultStrategy
    function getStoredPPS() public view returns (uint256) {
        return _getSuperVaultAggregator().getPPS(address(this));
    }

    /// @inheritdoc ISuperVaultStrategy
    function getSuperVaultState(address controller) external view returns (SuperVaultState memory state) {
        return superVaultState[controller];
    }

    /// @inheritdoc ISuperVaultStrategy
    function getYieldSource(address source) external view returns (YieldSource memory) {
        return YieldSource({ oracle: yieldSources[source] });
    }

    /// @inheritdoc ISuperVaultStrategy
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

    /// @inheritdoc ISuperVaultStrategy
    function getYieldSources() external view returns (address[] memory) {
        return yieldSourcesList.values();
    }

    /// @inheritdoc ISuperVaultStrategy
    function getYieldSourcesCount() external view returns (uint256) {
        return yieldSourcesList.length();
    }

    /// @notice Get the current unrealized profit above the High Water Mark
    /// @return profit Current profit above High Water Mark (in assets), 0 if no profit
    /// @dev Calculates based on PPS growth: (currentPPS - hwmPPS) * totalSupply / PRECISION
    function vaultUnrealizedProfit() external view returns (uint256) {
        IERC4626 vault = IERC4626(_vault);
        uint256 totalSupplyLocal = vault.totalSupply();

        // No profit if no shares exist
        if (totalSupplyLocal == 0) return 0;

        uint256 currentPPS = _getSuperVaultAggregator().getPPS(address(this));

        // No profit if current PPS is at or below HWM
        if (currentPPS <= vaultHwmPps) return 0;

        // Calculate profit as: (PPS growth) * (shares) / PRECISION
        uint256 ppsGrowth = currentPPS - vaultHwmPps;
        return Math.mulDiv(ppsGrowth, totalSupplyLocal, PRECISION, Math.Rounding.Floor);
    }

    /// @inheritdoc ISuperVaultStrategy
    function containsYieldSource(address source) external view returns (bool) {
        return yieldSourcesList.contains(source);
    }

    /// @inheritdoc ISuperVaultStrategy
    function pendingRedeemRequest(address controller) external view returns (uint256 pendingShares) {
        return superVaultState[controller].pendingRedeemRequest;
    }

    /// @inheritdoc ISuperVaultStrategy
    function claimableWithdraw(address controller) external view returns (uint256 claimableAssets) {
        return superVaultState[controller].maxWithdraw;
    }

    /// @inheritdoc ISuperVaultStrategy
    function pendingCancelRedeemRequest(address controller) external view returns (bool) {
        return superVaultState[controller].pendingCancelRedeemRequest;
    }

    /// @inheritdoc ISuperVaultStrategy
    function claimableCancelRedeemRequest(address controller) external view returns (uint256 claimableShares) {
        if (!superVaultState[controller].pendingCancelRedeemRequest) return 0;
        return superVaultState[controller].claimableCancelRedeemRequest;
    }

    /// @inheritdoc ISuperVaultStrategy
    function getAverageWithdrawPrice(address controller) external view returns (uint256 averageWithdrawPrice) {
        return superVaultState[controller].averageWithdrawPrice;
    }

    /// @inheritdoc ISuperVaultStrategy
    function previewExactRedeem(address controller)
        external
        view
        returns (uint256 shares, uint256 theoreticalAssets, uint256 minAssets)
    {
        SuperVaultState memory state = superVaultState[controller];
        shares = state.pendingRedeemRequest;

        if (shares == 0) return (0, 0, 0);

        uint256 pps = getStoredPPS();
        theoreticalAssets = shares.mulDiv(pps, PRECISION, Math.Rounding.Floor);

        uint16 slippageBps = state.redeemSlippageBps > 0 ? state.redeemSlippageBps : DEFAULT_REDEEM_SLIPPAGE_BPS;

        minAssets = SuperVaultAccountingLib.computeMinNetOut(shares, state.averageRequestPPS, slippageBps, PRECISION);

        return (shares, theoreticalAssets, minAssets);
    }

    /// @inheritdoc ISuperVaultStrategy
    function previewExactRedeemBatch(address[] calldata controllers)
        external
        view
        returns (uint256 totalTheoAssets, uint256[] memory individualAssets)
    {
        if (controllers.length == 0) revert ZERO_LENGTH();

        individualAssets = new uint256[](controllers.length);
        totalTheoAssets = 0;

        for (uint256 i = 0; i < controllers.length; i++) {
            // Get theoretical assets for this controller
            (, uint256 theoreticalAssets,) = this.previewExactRedeem(controllers[i]);
            individualAssets[i] = theoreticalAssets;
            totalTheoAssets += theoreticalAssets;
        }

        return (totalTheoAssets, individualAssets);
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
        // No slippage checks performed here as they have already been performed in the previous hook execution
        bool usePrevHookAmount = _decodeHookUsePrevHookAmount(hook, hookCalldata);

        ISuperHook(address(vars.hookContract)).setExecutionContext(address(this));
        vars.executions = vars.hookContract.build(prevHook, address(this), hookCalldata);
        for (uint256 j; j < vars.executions.length; ++j) {
            // Block hooks from calling the SuperVaultAggregator directly
            address aggregatorAddr = address(_getSuperVaultAggregator());
            if (vars.executions[j].target == aggregatorAddr) revert OPERATION_FAILED();
            (vars.success,) =
                vars.executions[j].target.call{ value: vars.executions[j].value }(vars.executions[j].callData);
            if (!vars.success) revert OPERATION_FAILED();
        }
        ISuperHook(address(vars.hookContract)).resetExecutionState(address(this));

        uint256 actualOutput = ISuperHookResult(hook).getOutAmount(address(this));

        // this is not to protect the user but rather a honest manager from doing a mistake
        if (actualOutput < expectedAssetsOrSharesOut) {
            revert MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET();
        }

        emit HookExecuted(hook, prevHook, vars.targetedYieldSource, usePrevHookAmount, hookCalldata);

        return hook;
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL REDEMPTION PROCESSING
    //////////////////////////////////////////////////////////////*/

    /// @notice Process exact fulfillment for batch processing
    /// @dev Handles all accounting updates for fulfilled redemption:
    ///      1. Validates slippage bounds (minAssets <= actual <= theoretical)
    ///      2. Updates weighted average withdraw price across multiple fulfillments
    ///      3. Clears pending state and makes assets claimable
    ///      4. Resets cancellation flags
    /// @dev SECURITY: Bounds validation ensures manager cannot underfill/overfill
    /// @dev ACCOUNTING: Average withdraw price uses weighted formula to track historical execution prices
    /// @param controller Controller address
    /// @param totalAssetsOut Total assets available for this controller (from executeHooks)
    /// @param currentPPS Current price per share
    /// @param pendingShares Pending shares for this controller (passed to avoid re-reading from storage)
    function _processExactFulfillmentBatch(
        address controller,
        uint256 totalAssetsOut,
        uint256 currentPPS,
        uint256 pendingShares
    )
        internal
    {
        SuperVaultState storage state = superVaultState[controller];

        // Slippage validation
        uint16 slippageBps = state.redeemSlippageBps > 0 ? state.redeemSlippageBps : DEFAULT_REDEEM_SLIPPAGE_BPS;

        uint256 theoreticalAssets = pendingShares.mulDiv(currentPPS, PRECISION, Math.Rounding.Floor);

        uint256 minAssetsOut =
            SuperVaultAccountingLib.computeMinNetOut(pendingShares, state.averageRequestPPS, slippageBps, PRECISION);

        // Bounds check: totalAssetsOut must be between minAssetsOut and theoreticalAssets
        if (totalAssetsOut < minAssetsOut || totalAssetsOut > theoreticalAssets) {
            revert BOUNDS_EXCEEDED(minAssetsOut, theoreticalAssets, totalAssetsOut);
        }

        // Update average withdraw price (use actual assets received)
        state.averageWithdrawPrice = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
            state.maxWithdraw, state.averageWithdrawPrice, pendingShares, totalAssetsOut, PRECISION
        );

        // Reset state
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

    /// @notice Internal function to get the SuperVaultAggregator
    /// @return The SuperVaultAggregator
    function _getSuperVaultAggregator() internal view returns (ISuperVaultAggregator) {
        address aggregatorAddress = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.SUPER_VAULT_AGGREGATOR());

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
    /// @param actionType Type of action (see YieldSourceAction enum)
    function _manageYieldSource(address source, address oracle, YieldSourceAction actionType) internal {
        if (actionType == YieldSourceAction.Add) {
            _addYieldSource(source, oracle);
        } else if (actionType == YieldSourceAction.UpdateOracle) {
            _updateYieldSourceOracle(source, oracle);
        } else if (actionType == YieldSourceAction.Remove) {
            _removeYieldSource(source);
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

    /// @notice Internal function to propose a PPS expiry threshold
    /// @param _threshold The new PPS expiry threshold
    function _proposePPSExpiration(uint256 _threshold) internal {
        _isPrimaryManager(msg.sender);

        if (_threshold < MIN_PPS_EXPIRATION_THRESHOLD || _threshold > MAX_PPS_EXPIRATION_THRESHOLD) {
            revert INVALID_PPS_EXPIRY_THRESHOLD();
        }

        uint256 currentProposedThreshold = proposedPPSExpiryThreshold;
        proposedPPSExpiryThreshold = _threshold;
        ppsExpiryThresholdEffectiveTime = block.timestamp + PROPOSAL_TIMELOCK;

        emit PPSExpirationProposed(currentProposedThreshold, _threshold, ppsExpiryThresholdEffectiveTime);
    }

    /// @notice Internal function to perform a PPS expiry threshold
    function _updatePPSExpiration() internal {
        _isPrimaryManager(msg.sender);

        // Must have a valid proposal
        if (block.timestamp < ppsExpiryThresholdEffectiveTime) revert INVALID_TIMESTAMP();

        if (proposedPPSExpiryThreshold == 0) revert INVALID_PPS_EXPIRY_THRESHOLD();

        uint256 _proposed = proposedPPSExpiryThreshold;
        ppsExpiration = _proposed;
        ppsExpiryThresholdEffectiveTime = 0;
        proposedPPSExpiryThreshold = 0;

        emit PPSExpiryThresholdUpdated(_proposed);
    }

    /// @notice Internal function to cancel a PPS expiry threshold proposal
    function _cancelPPSExpirationProposalUpdate() internal {
        _isPrimaryManager(msg.sender);

        if (ppsExpiryThresholdEffectiveTime == 0) revert NO_PROPOSAL();

        proposedPPSExpiryThreshold = 0;
        ppsExpiryThresholdEffectiveTime = 0;

        emit PPSExpiryThresholdProposalCanceled();
    }

    /// @notice Internal function to check if a hook is registered
    /// @param hook Address of the hook
    /// @return True if the hook is registered, false otherwise
    function _isRegisteredHook(address hook) private view returns (bool) {
        return SUPER_GOVERNOR.isHookRegistered(hook);
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

    /// @notice Internal function to handle a redeem
    /// @param controller Address of the controller
    /// @param shares Amount of shares
    function _handleRequestRedeem(address controller, uint256 shares) private {
        if (shares == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();
        SuperVaultState storage state = superVaultState[controller];

        // Get current PPS from aggregator to use as baseline for slippage protection
        uint256 currentPPS = getStoredPPS();
        if (currentPPS == 0) revert INVALID_PPS();

        // Calculate weighted average of PPS if there's an existing request
        if (state.pendingRedeemRequest > 0) {
            // Incremental request: Calculate weighted average PPS
            // This protects users from PPS manipulation between multiple requests
            // Formula: avgPPS = (oldShares * oldPPS + newShares * newPPS) / totalShares
            uint256 existingSharesInRequest = state.pendingRedeemRequest;
            uint256 newTotalSharesInRequest = existingSharesInRequest + shares;

            // Weighted average ensures fair pricing across multiple request timestamps
            state.averageRequestPPS =
                ((existingSharesInRequest * state.averageRequestPPS) + (shares * currentPPS)) / newTotalSharesInRequest;

            state.pendingRedeemRequest = newTotalSharesInRequest;
        } else {
            // First request: Initialize with current PPS as baseline for slippage protection
            state.pendingRedeemRequest = shares;
            state.averageRequestPPS = currentPPS;
        }

        emit RedeemRequestPlaced(controller, controller, shares);
    }

    /// @notice Internal function to handle a redeem cancellation request
    /// @param controller Address of the controller
    function _handleCancelRedeemRequest(address controller) private {
        if (controller == address(0)) revert ZERO_ADDRESS();
        SuperVaultState storage state = superVaultState[controller];
        if (state.pendingRedeemRequest == 0) revert REQUEST_NOT_FOUND();
        if (state.pendingCancelRedeemRequest) revert CANCELLATION_REDEEM_REQUEST_PENDING();

        state.pendingCancelRedeemRequest = true;
        emit RedeemCancelRequestPlaced(controller);
    }

    /// @notice Internal function to handle a claim redeem cancellation
    /// @param controller Address of the controller
    function _handleClaimCancelRedeem(address controller) private {
        if (controller == address(0)) revert ZERO_ADDRESS();
        SuperVaultState storage state = superVaultState[controller];
        uint256 pendingShares = state.claimableCancelRedeemRequest;
        if (pendingShares == 0) revert REQUEST_NOT_FOUND();

        if (!state.pendingCancelRedeemRequest) revert CANCELLATION_REDEEM_REQUEST_PENDING();

        // Clear pending request metadata
        state.pendingCancelRedeemRequest = false;
        state.claimableCancelRedeemRequest = 0;
        emit RedeemRequestCanceled(controller, pendingShares);
    }

    /// @notice Internal function to handle a redeem claim
    /// @dev Only updates state. Vault is responsible for calling Escrow.returnAssets() after this returns.
    ///      Callers (SuperVault.withdraw/redeem) already validate assetsToClaim <= state.maxWithdraw.
    /// @param controller Address of the controller
    /// @param receiver Address of the receiver (used for event only)
    /// @param assetsToClaim Amount of assets to claim
    function _handleClaimRedeem(address controller, address receiver, uint256 assetsToClaim) private {
        if (assetsToClaim == 0) revert INVALID_AMOUNT();
        if (controller == address(0)) revert ZERO_ADDRESS();
        SuperVaultState storage state = superVaultState[controller];
        state.maxWithdraw -= assetsToClaim;
        emit RedeemRequestClaimed(receiver, controller, assetsToClaim, 0);
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
    function _isPaused(ISuperVaultAggregator aggregator) internal view returns (bool) {
        return aggregator.isStrategyPaused(address(this));
    }

    /// @notice Checks if the PPS is stale
    /// @dev This calls SuperVaultAggregator.isPPSStale to determine stale status
    /// @return True if the PPS is stale, false otherwise
    function _isPPSStale(ISuperVaultAggregator aggregator) internal view returns (bool) {
        return aggregator.isPPSStale(address(this));
    }

    /// @notice Checks if the PPS is not updated
    /// @dev This checks if the PPS has not been updated since the `ppsExpiration` time
    /// @param aggregator The SuperVaultAggregator contract
    /// @return True if the PPS is not updated, false otherwise
    function _isPPSNotUpdated(ISuperVaultAggregator aggregator) internal view returns (bool) {
        // The `ppsExpiration` serves a different purpose:
        //       if the oracle network stops pushing updates for some reasons (e.g. quite some nodes go down and the
        // quorum is never reached)
        //       then the onchain PPS gets never updated and eventually it should not be used anymore, which is what the
        // `ppsExpiration` logic controls
        uint256 lastPPSUpdateTimestamp = aggregator.getLastUpdateTimestamp(address(this));
        return block.timestamp - lastPPSUpdateTimestamp > ppsExpiration;
    }

    /// @notice Validates full pps state by checking pause, stale, and PPS update status
    /// @dev Used for operations that require current PPS for calculations:
    ///      - handleOperations4626Deposit: Needs PPS to calculate shares from assets
    ///      - handleOperations4626Mint: Needs PPS to validate asset requirements
    ///      - fulfillRedeemRequests: Needs current PPS to calculate assets from shares
    /// @param aggregator The SuperVaultAggregator contract
    function _validateStrategyState(ISuperVaultAggregator aggregator) internal view {
        if (_isPaused(aggregator)) revert STRATEGY_PAUSED();
        if (_isPPSStale(aggregator)) revert STALE_PPS();
        if (_isPPSNotUpdated(aggregator)) revert PPS_EXPIRED();
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
        return _getSuperVaultAggregator()
            .validateHook(
                address(this),
                ISuperVaultAggregator.ValidateHookArgs({
                    hookAddress: hook,
                    hookArgs: ISuperHookInspector(hook).inspect(hookCalldata),
                    globalProof: globalProof,
                    strategyProof: strategyProof
                })
            );
    }
}
