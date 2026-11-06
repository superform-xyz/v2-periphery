// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC7540Deposit, IERC7540CancelDeposit } from "../../vendor/standards/ERC7540/IERC7540Vault.sol";

/// @title IManagedSuperVaultDepositQueue
/// @author Superform Labs
/// @notice Interface for the ManagedSuperVaultDepositQueue — the async ERC-7540 deposit leg for a ManagedSuperVault
/// @dev ERC-7575-style entry point: users request deposits here, the manager fulfills at the attested PPS by
///      calling the vault's (queue-gated) synchronous deposit, and users claim NATIVE vault shares. Redemptions
///      go through the vault's native async redeem — this contract has no redeem leg. Pending assets are held
///      by the queue itself; fulfilled shares are held by the queue until claimed.
interface IManagedSuperVaultDepositQueue is IERC7540Deposit, IERC7540CancelDeposit {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposit approval mode configured for the vault
    enum DepositApprovalMode {
        Open, // 0: anyone can request a deposit
        Allowlist, // 1: pre-approved allowlist required
        ManagerApproved, // 2: two-step request/approval required
        KycApproved // 3: KYC/subscription approval required (reference stored offchain, hash onchain)

    }

    /// @notice Approval status of a depositor
    /// @dev Approval requests originate offchain; only manager decisions are recorded onchain
    enum ApprovalStatus {
        None,
        Approved,
        Rejected,
        Revoked
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposit policy configuration
    /// @param approvalMode Approval mode gating deposit requests
    /// @param depositsPaused Manager-controlled pause for new deposit requests
    /// @param minDepositAssets Minimum assets per deposit request (0 = no minimum)
    /// @param maxDepositAssets Maximum assets per deposit request (0 = unlimited)
    struct DepositPolicy {
        DepositApprovalMode approvalMode;
        bool depositsPaused;
        uint256 minDepositAssets;
        uint256 maxDepositAssets;
    }

    /// @notice Per-controller (7540 user) async deposit state
    /// @param pendingDepositAssets Assets requested, held by the queue, awaiting fulfillment
    /// @param claimableDepositAssets Net assets fulfilled, claimable via deposit()/mint()
    /// @param claimableDepositShares Vault shares minted at fulfillment, held by the queue until claimed
    struct DepositState {
        uint256 pendingDepositAssets;
        uint256 claimableDepositAssets;
        uint256 claimableDepositShares;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the queue is initialized
    event Initialized(address indexed vault, address indexed strategy);

    /// @notice Emitted when a deposit request is placed
    event DepositRequestPlaced(address indexed controller, uint256 assets);

    /// @notice Emitted when a deposit request is fulfilled by a manager
    event DepositRequestFulfilled(
        address indexed controller, uint256 assetsGross, uint256 assetsNet, uint256 shares, uint256 pps
    );

    /// @notice Emitted when a deposit request is rejected by a manager
    event DepositRequestRejected(address indexed controller, uint256 assets, string reason);

    /// @notice Emitted when a deposit request is cancelled by its controller
    event DepositRequestCanceled(address indexed controller, uint256 assets);

    /// @notice Emitted when claimable deposit assets are claimed
    event DepositClaimed(address indexed controller, uint256 assets);

    /// @notice Emitted when the deposit policy is updated
    event DepositPolicyUpdated(
        DepositApprovalMode approvalMode, bool depositsPaused, uint256 minDepositAssets, uint256 maxDepositAssets
    );

    /// @notice Emitted when a depositor is approved (kycRef is a hash reference, event-only, never PII)
    event DepositorApproved(address indexed depositor, bytes32 kycRef);

    /// @notice Emitted when a depositor is rejected
    event DepositorRejected(address indexed depositor);

    /// @notice Emitted when a depositor's approval is revoked
    event DepositorRevoked(address indexed depositor);

    /// @notice Emitted on claim (ERC-7575 Deposit event shape)
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when address provided is zero
    error ZERO_ADDRESS();
    /// @notice Thrown when amount provided is zero
    error ZERO_AMOUNT();
    /// @notice Thrown when an array length is zero
    error ZERO_LENGTH();
    /// @notice Thrown when array lengths mismatch
    error INVALID_ARRAY_LENGTH();
    /// @notice Thrown when the caller is not the controller or an approved vault operator
    error INVALID_CALLER();
    /// @notice Thrown when controller != owner on request (per-controller single-request model)
    error CONTROLLER_MUST_EQUAL_OWNER();
    /// @notice Thrown when the caller is not a manager of the strategy
    error NOT_MANAGER();
    /// @notice Thrown when the caller is not the main manager of the strategy
    error NOT_MAIN_MANAGER();
    /// @notice Thrown when deposits are paused by policy
    error DEPOSITS_PAUSED();
    /// @notice Thrown when the depositor is not approved under the current approval mode
    error DEPOSITOR_NOT_APPROVED();
    /// @notice Thrown when the deposit is below the policy minimum
    error DEPOSIT_BELOW_MINIMUM();
    /// @notice Thrown when the deposit is above the policy maximum
    error DEPOSIT_ABOVE_MAXIMUM();
    /// @notice Thrown when the vault cannot accept deposits (paused, stale, or expired PPS)
    error VAULT_NOT_ACCEPTING_DEPOSITS();
    /// @notice Thrown when there is no pending request to act on
    error REQUEST_NOT_FOUND();
    /// @notice Thrown when the amount exceeds what is claimable
    error INVALID_AMOUNT();
    /// @notice Thrown when a depositor's approval status does not allow the action
    error INVALID_APPROVAL_STATUS();
    /// @notice Thrown when the vault mints a different share amount than the precomputed one at fulfill
    error FULFILLMENT_MISMATCH();
    /// @notice Thrown for the async-leg preview functions and the never-pending cancel claim (ERC-7540)
    error NOT_IMPLEMENTED();

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    /// @notice Initializes the queue clone
    /// @dev Only called by the managed aggregator during createVault (msg.sender is stored as aggregator)
    /// @param vault_ The ManagedSuperVault this queue fronts
    /// @param strategy_ The vault's strategy
    /// @param policy The initial deposit policy
    function initialize(address vault_, address strategy_, DepositPolicy calldata policy) external;

    /*//////////////////////////////////////////////////////////////
                          MANAGER OPERATIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Fulfills pending deposit requests at the current attested PPS
    /// @dev Any manager. Skips zero-pending and dust entries (front-run-cancel safety; a dust request
    ///      stays pending for cancel/reject). Reverts entirely when the vault is paused/stale/expired.
    /// @param controllers The controllers whose pending requests to fulfill
    function fulfillDepositRequests(address[] calldata controllers) external;

    /// @notice Rejects pending deposit requests, refunding the assets
    /// @dev Any manager. Skips zero-pending entries.
    /// @param controllers The controllers whose pending requests to reject
    /// @param reason Human-readable rejection reason (event-only)
    function rejectDepositRequests(address[] calldata controllers, string calldata reason) external;

    /// @notice Updates the deposit policy
    /// @dev Only the main manager
    function setDepositPolicy(DepositPolicy calldata policy) external;

    /// @notice Approves depositors (with event-only KYC reference hashes)
    /// @dev Any manager
    function approveDepositors(address[] calldata depositors, bytes32[] calldata kycRefs) external;

    /// @notice Rejects depositors
    /// @dev Any manager
    function rejectDepositors(address[] calldata depositors) external;

    /// @notice Revokes previously approved depositors
    /// @dev Any manager
    function revokeDepositors(address[] calldata depositors) external;

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/
    /// @notice The underlying asset (ERC-7575)
    function asset() external view returns (address);

    /// @notice The share token — the ManagedSuperVault (ERC-7575 external entry-point pattern)
    function share() external view returns (address);

    /// @notice The vault this queue fronts (same address as share())
    function vault() external view returns (address);

    /// @notice The vault's strategy
    function strategy() external view returns (address);

    /// @notice The managed aggregator that created this queue
    function aggregator() external view returns (address);

    /// @notice Maximum claimable assets for a controller (ERC-7540 claim bound)
    function maxDeposit(address controller) external view returns (uint256);

    /// @notice Maximum claimable shares for a controller (ERC-7540 claim bound)
    function maxMint(address controller) external view returns (uint256);

    /// @notice Reverts — previews are disallowed on ERC-7540 async legs
    function previewDeposit(uint256 assets) external view returns (uint256);

    /// @notice Reverts — previews are disallowed on ERC-7540 async legs
    function previewMint(uint256 shares) external view returns (uint256);

    /// @notice Gets a controller's full deposit state
    function getDepositState(address controller) external view returns (DepositState memory state);

    /// @notice Total assets currently pending across all controllers (equals the queue's asset balance)
    function totalPendingDepositAssets() external view returns (uint256);

    /// @notice Weighted-average claim price for a controller, derived from claimable assets/shares
    /// @dev Backend-compat view; claims themselves are pro-rata over exact claimable shares
    function getAverageDepositPrice(address controller) external view returns (uint256);

    /// @notice The current deposit policy
    function getDepositPolicy() external view returns (DepositPolicy memory policy);

    /// @notice A depositor's approval status
    function getApprovalStatus(address depositor) external view returns (ApprovalStatus status);
}
