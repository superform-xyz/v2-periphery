// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

// Superform
import { ManagedSuperVault } from "./ManagedSuperVault.sol";
import { ManagedSuperVaultStrategy } from "./ManagedSuperVaultStrategy.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IManagedSuperVaultAggregator } from "../interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultDepositQueue } from "../interfaces/ManagedSuperVault/IManagedSuperVaultDepositQueue.sol";
import {
    IERC7540Deposit,
    IERC7540CancelDeposit,
    IERC7540Operator
} from "../vendor/standards/ERC7540/IERC7540Vault.sol";

/// @title ManagedSuperVaultDepositQueue
/// @author Superform Labs
/// @notice Async ERC-7540 deposit leg for a ManagedSuperVault (ERC-7575 external entry-point pattern:
///         share() is the vault, which users redeem through directly via its native async redeem)
/// @dev Deposits must be async on managed vaults: pricing comes from a manager-attested NAV on a slow
///      cadence, so open synchronous deposits would allow stale-NAV timing arbitrage. The flow is
///      request (assets held here) → manager fulfill (queue calls the vault's queue-gated sync deposit
///      at the attested PPS; the strategy skims the entry fee natively) → claim (native vault shares,
///      pre-minted at fulfillment and held here, distributed pro-rata over exact claimable balances).
/// @dev Claims are pro-rata over exact claimable shares rather than priced at a stored average: with
///      pre-minted shares, average-price rounding could distribute more shares than the queue holds.
///      getAverageDepositPrice() is provided as a derived, backend-facing view.
/// @dev Assumes a standard (non-fee-on-transfer, non-rebasing) underlying asset, as elsewhere in this repo.
contract ManagedSuperVaultDepositQueue is
    IManagedSuperVaultDepositQueue,
    Initializable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @dev Single-request model: all requests share id 0 (one open request per controller)
    uint256 private constant REQUEST_ID = 0;
    uint256 private constant BPS_PRECISION = 10_000;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultDepositQueue
    address public vault;
    /// @inheritdoc IManagedSuperVaultDepositQueue
    address public strategy;
    /// @inheritdoc IManagedSuperVaultDepositQueue
    address public aggregator;
    /// @inheritdoc IManagedSuperVaultDepositQueue
    uint256 public totalPendingDepositAssets;

    IERC20 private _asset;
    uint256 private _precision;

    DepositPolicy private _depositPolicy;
    mapping(address depositor => ApprovalStatus status) private _approvalStatus;
    mapping(address controller => DepositState state) private _depositState;

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultDepositQueue
    function initialize(address vault_, address strategy_, DepositPolicy calldata policy) external initializer {
        /// @dev vault and strategy are pre-validated by the ManagedSuperVaultAggregator during createVault,
        ///      which is the only caller (stored as aggregator)
        __ReentrancyGuard_init();

        vault = vault_;
        strategy = strategy_;
        aggregator = msg.sender;
        _asset = IERC20(ManagedSuperVault(vault_).asset());
        _precision = ManagedSuperVault(vault_).PRECISION();
        _setDepositPolicy(policy);

        // One-time max approval so fulfillment's vault.deposit can pull assets from the queue.
        // The vault is trusted family code deployed by the same aggregator.
        _asset.forceApprove(vault_, type(uint256).max);

        emit Initialized(vault_, strategy_);
    }

    /*//////////////////////////////////////////////////////////////
                        ASYNC DEPOSIT FLOW (USERS)
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC7540Deposit
    /// @dev controller MUST equal owner (per-controller single-request accounting, mirrors the vault's
    ///      redeem side). Caller must be the owner or a vault-approved operator — operator approvals
    ///      live on the vault (single operator surface for both legs).
    function requestDeposit(
        uint256 assets,
        address controller,
        address owner
    )
        external
        nonReentrant
        returns (uint256)
    {
        if (assets == 0) revert ZERO_AMOUNT();
        if (owner == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        if (controller != owner) revert CONTROLLER_MUST_EQUAL_OWNER();
        _validateCaller(owner);

        // Mirror the vault-side state gate: no new requests while paused, stale, or expired
        if (!_vaultAcceptingDeposits()) revert VAULT_NOT_ACCEPTING_DEPOSITS();

        DepositPolicy memory policy = _depositPolicy;
        if (policy.depositsPaused) revert DEPOSITS_PAUSED();
        if (policy.approvalMode != DepositApprovalMode.Open && _approvalStatus[controller] != ApprovalStatus.Approved)
        {
            revert DEPOSITOR_NOT_APPROVED();
        }
        if (assets < policy.minDepositAssets) revert DEPOSIT_BELOW_MINIMUM();
        if (policy.maxDepositAssets != 0 && assets > policy.maxDepositAssets) revert DEPOSIT_ABOVE_MAXIMUM();

        _depositState[controller].pendingDepositAssets += assets;
        totalPendingDepositAssets += assets;

        // Pull assets into queue custody
        _asset.safeTransferFrom(owner, address(this), assets);

        emit DepositRequest(controller, owner, REQUEST_ID, msg.sender, assets);
        emit DepositRequestPlaced(controller, assets);
        return REQUEST_ID;
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @dev Instant-fulfillment cancel model: pending assets are refunded to the controller in the
    ///      same transaction (there is never a pending or claimable cancellation)
    function cancelDepositRequest(uint256, /*requestId*/ address controller) external nonReentrant {
        if (controller == address(0)) revert ZERO_ADDRESS();
        _validateCaller(controller);

        DepositState storage state = _depositState[controller];
        uint256 assets = state.pendingDepositAssets;
        if (assets == 0) revert REQUEST_NOT_FOUND();

        state.pendingDepositAssets = 0;
        totalPendingDepositAssets -= assets;

        _asset.safeTransfer(controller, assets);

        emit CancelDepositRequest(controller, REQUEST_ID, msg.sender);
        emit CancelDepositClaim(controller, controller, REQUEST_ID, msg.sender, assets);
        emit DepositRequestCanceled(controller, assets);
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @dev Deposit cancellations are instantly fulfilled; there is never a pending cancellation
    function pendingCancelDepositRequest(uint256, address) external pure returns (bool) {
        return false;
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @dev Deposit cancellations are instantly fulfilled and auto-claimed; nothing is ever claimable
    function claimableCancelDepositRequest(uint256, address) external pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc IERC7540CancelDeposit
    /// @dev Deposit cancellations are instantly fulfilled and auto-claimed in cancelDepositRequest
    function claimCancelDepositRequest(uint256, address, address) external pure returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC7540Deposit
    /// @notice Claim step: transfers pre-minted vault shares for fulfilled (claimable) deposit assets
    function deposit(uint256 assets, address receiver, address controller) external nonReentrant returns (uint256 shares) {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        if (assets == 0) revert ZERO_AMOUNT();
        _validateCaller(controller);

        DepositState storage state = _depositState[controller];
        if (assets > state.claimableDepositAssets) revert INVALID_AMOUNT();

        // Pro-rata over exact claimable balances; a full claim transfers the exact remaining shares
        shares = state.claimableDepositShares.mulDiv(assets, state.claimableDepositAssets, Math.Rounding.Floor);
        if (shares == 0) revert INVALID_AMOUNT();

        state.claimableDepositAssets -= assets;
        state.claimableDepositShares -= shares;

        IERC20(vault).safeTransfer(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
        emit DepositClaimed(controller, assets);
    }

    /// @inheritdoc IERC7540Deposit
    /// @notice Claim step: transfers exactly shares of pre-minted vault shares, consuming claimable assets
    function mint(uint256 shares, address receiver, address controller) external nonReentrant returns (uint256 assets) {
        if (receiver == address(0) || controller == address(0)) revert ZERO_ADDRESS();
        if (shares == 0) revert ZERO_AMOUNT();
        _validateCaller(controller);

        DepositState storage state = _depositState[controller];
        if (shares > state.claimableDepositShares) revert INVALID_AMOUNT();

        // Pro-rata (rounded against the claimer); shares == claimableShares consumes assets exactly
        assets = state.claimableDepositAssets.mulDiv(shares, state.claimableDepositShares, Math.Rounding.Ceil);

        state.claimableDepositAssets -= assets;
        state.claimableDepositShares -= shares;

        IERC20(vault).safeTransfer(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
        emit DepositClaimed(controller, assets);
    }

    /*//////////////////////////////////////////////////////////////
                          MANAGER OPERATIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IManagedSuperVaultDepositQueue
    /// @dev Reverts entirely when the vault is paused/stale/expired (vault.deposit enforces it);
    ///      the manager retries when the vault is healthy again
    function fulfillDepositRequests(address[] calldata controllers) external nonReentrant {
        _requireManager();

        uint256 len = controllers.length;
        if (len == 0) revert ZERO_LENGTH();

        ManagedSuperVault vault_ = ManagedSuperVault(vault);
        uint256 currentPPS = ManagedSuperVaultStrategy(payable(strategy)).getStoredPPS();

        for (uint256 i; i < len; ++i) {
            address controller = controllers[i];
            DepositState storage state = _depositState[controller];

            uint256 assetsGross = state.pendingDepositAssets;
            // Skip controllers with no pending request so a front-run cancel cannot brick the batch
            if (assetsGross == 0) continue;

            // Precompute the vault's exact fee/share math (previewDeposit = net shares after the
            // strategy's entry-fee skim). Skip (don't revert) dust requests that would net to zero,
            // consistent with the zero-pending skip — the request stays pending for cancel/reject.
            uint256 expectedShares = vault_.previewDeposit(assetsGross);
            uint256 assetsNet = assetsGross - _entryFee(assetsGross);
            if (assetsNet == 0 || expectedShares == 0) continue;

            state.pendingDepositAssets = 0;
            totalPendingDepositAssets -= assetsGross;

            // The vault pulls the gross assets from the queue and mints net shares to the queue;
            // the strategy skims the entry fee natively (no fee code here)
            uint256 sharesMinted = vault_.deposit(assetsGross, address(this));
            if (sharesMinted != expectedShares) revert FULFILLMENT_MISMATCH();

            state.claimableDepositAssets += assetsNet;
            state.claimableDepositShares += sharesMinted;

            emit DepositRequestFulfilled(controller, assetsGross, assetsNet, sharesMinted, currentPPS);
        }
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function rejectDepositRequests(address[] calldata controllers, string calldata reason) external nonReentrant {
        _requireManager();

        uint256 len = controllers.length;
        if (len == 0) revert ZERO_LENGTH();

        for (uint256 i; i < len; ++i) {
            address controller = controllers[i];
            DepositState storage state = _depositState[controller];

            uint256 assets = state.pendingDepositAssets;
            // Skip controllers with no pending request (mirrors fulfill; avoids batch-brick reverts)
            if (assets == 0) continue;

            state.pendingDepositAssets = 0;
            totalPendingDepositAssets -= assets;

            _asset.safeTransfer(controller, assets);

            emit DepositRequestRejected(controller, assets, reason);
        }
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function setDepositPolicy(DepositPolicy calldata policy) external {
        if (!IManagedSuperVaultAggregator(aggregator).isMainManager(msg.sender, strategy)) revert NOT_MAIN_MANAGER();
        _setDepositPolicy(policy);
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function approveDepositors(address[] calldata depositors, bytes32[] calldata kycRefs) external {
        _requireManager();

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

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function rejectDepositors(address[] calldata depositors) external {
        _requireManager();

        uint256 len = depositors.length;
        if (len == 0) revert ZERO_LENGTH();

        for (uint256 i; i < len; ++i) {
            _approvalStatus[depositors[i]] = ApprovalStatus.Rejected;
            emit DepositorRejected(depositors[i]);
        }
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function revokeDepositors(address[] calldata depositors) external {
        _requireManager();

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
                          OPERATOR PASS-THROUGH
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC7540Operator
    /// @dev Operator approvals live on the VAULT — one operator surface shared by the deposit leg
    ///      (this queue) and the native redeem leg. Call setOperator on the vault instead.
    function setOperator(address, bool) external pure returns (bool) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IERC7540Operator
    /// @dev Mirrors the vault's operator registry (see setOperator)
    function isOperator(address controller, address operator) external view returns (bool) {
        return ManagedSuperVault(vault).isOperator(controller, operator);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC7540Deposit
    function pendingDepositRequest(uint256, address controller) external view returns (uint256 pendingAssets) {
        return _depositState[controller].pendingDepositAssets;
    }

    /// @inheritdoc IERC7540Deposit
    function claimableDepositRequest(uint256, address controller) external view returns (uint256 claimableAssets) {
        return _depositState[controller].claimableDepositAssets;
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function asset() external view returns (address) {
        return address(_asset);
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    /// @dev ERC-7575 external entry-point pattern: the share token is the vault
    function share() external view returns (address) {
        return vault;
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function maxDeposit(address controller) external view returns (uint256) {
        return _depositState[controller].claimableDepositAssets;
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function maxMint(address controller) external view returns (uint256) {
        return _depositState[controller].claimableDepositShares;
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    /// @dev ERC-7540: previews MUST revert on async request legs
    function previewDeposit(uint256) external pure returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    /// @dev ERC-7540: previews MUST revert on async request legs
    function previewMint(uint256) external pure returns (uint256) {
        revert NOT_IMPLEMENTED();
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function getDepositState(address controller) external view returns (DepositState memory state) {
        return _depositState[controller];
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function getAverageDepositPrice(address controller) external view returns (uint256) {
        DepositState storage state = _depositState[controller];
        if (state.claimableDepositShares == 0) return 0;
        return state.claimableDepositAssets.mulDiv(_precision, state.claimableDepositShares, Math.Rounding.Floor);
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function getDepositPolicy() external view returns (DepositPolicy memory policy) {
        return _depositPolicy;
    }

    /// @inheritdoc IManagedSuperVaultDepositQueue
    function getApprovalStatus(address depositor) external view returns (ApprovalStatus status) {
        return _approvalStatus[depositor];
    }

    /// @notice ERC-165 support: the async deposit leg + deposit cancellation (no redeem leg here, so
    ///         the full IERC7575 id is deliberately NOT advertised — share()/asset() still aid discovery)
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC7540Deposit).interfaceId
            || interfaceId == type(IERC7540CancelDeposit).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev Caller must be the controller/owner themselves or a vault-approved operator
    function _validateCaller(address controller) private view {
        if (msg.sender != controller && !ManagedSuperVault(vault).isOperator(controller, msg.sender)) {
            revert INVALID_CALLER();
        }
    }

    /// @dev Caller must be a manager (main or secondary) of the strategy
    function _requireManager() private view {
        if (!IManagedSuperVaultAggregator(aggregator).isAnyManager(msg.sender, strategy)) revert NOT_MANAGER();
    }

    /// @dev Mirrors the strategy's _validateStrategyState gate for the request side:
    ///      not paused, PPS not stale, and PPS not expired
    function _vaultAcceptingDeposits() private view returns (bool) {
        IManagedSuperVaultAggregator aggregator_ = IManagedSuperVaultAggregator(aggregator);
        if (aggregator_.isStrategyPaused(strategy) || aggregator_.isPPSStale(strategy)) return false;
        return block.timestamp - aggregator_.getLastUpdateTimestamp(strategy)
            <= ManagedSuperVaultStrategy(payable(strategy)).ppsExpiration();
    }

    /// @dev The strategy's exact entry-fee formula (fee-on-gross, ceil) — see handleOperations4626Deposit
    function _entryFee(uint256 assetsGross) private view returns (uint256) {
        ISuperVaultStrategy.FeeConfig memory cfg = ISuperVaultStrategy(strategy).getConfigInfo();
        if (cfg.managementFeeBps == 0) return 0;
        return assetsGross.mulDiv(cfg.managementFeeBps, BPS_PRECISION, Math.Rounding.Ceil);
    }

    function _setDepositPolicy(DepositPolicy calldata policy) private {
        _depositPolicy = policy;
        emit DepositPolicyUpdated(
            policy.approvalMode, policy.depositsPaused, policy.minDepositAssets, policy.maxDepositAssets
        );
    }
}
