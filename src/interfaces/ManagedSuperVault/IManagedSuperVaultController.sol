// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title IManagedSuperVaultController
/// @notice Interface for the ManagedSuperVaultController: the manager-operated counterpart of
///         SuperVaultStrategy for Managed Vaults. Owns deposit request accounting and approvals,
///         redemption fulfillment, the attested manual NAV module, policy-gated arbitrary calldata
///         execution, and fee handling. Holds operational custody of vault assets.
/// @dev No strategy hooks, no yield-source registry, no optimizer, no rebalancing.
/// @author Superform Labs
interface IManagedSuperVaultController {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_LENGTH();
    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error ACCESS_DENIED();
    error INVALID_AMOUNT();
    error INVALID_TIMESTAMP();
    error REQUEST_NOT_FOUND();
    error INVALID_ARRAY_LENGTH();
    error ACTION_TYPE_DISALLOWED();
    error INVALID_PERFORMANCE_FEE_BPS();
    error MANAGER_NOT_AUTHORIZED();
    error INVALID_PPS();
    error INVALID_VAULT();
    error INVALID_ASSET();
    error MANAGED_VAULT_PAUSED();
    error STALE_NAV();
    error NAV_EXPIRED();
    error NO_PROPOSAL();
    error INVALID_REDEEM_SLIPPAGE_BPS();
    error CANCELLATION_REDEEM_REQUEST_PENDING();
    error BOUNDS_EXCEEDED(uint256 minAllowed, uint256 maxAllowed, uint256 actual);
    error INSUFFICIENT_LIQUIDITY();
    error CONTROLLERS_NOT_SORTED_UNIQUE();
    error ZERO_SHARE_FULFILLMENT_DISALLOWED();
    error NOT_ENOUGH_FREE_ASSETS_FEE_SKIM();
    error SKIM_TIMELOCK_ACTIVE();

    // Deposit / approval errors
    error DEPOSITS_PAUSED();
    error DEPOSITOR_NOT_APPROVED();
    error DEPOSIT_BELOW_MINIMUM();
    error DEPOSIT_ABOVE_MAXIMUM();
    error INVALID_APPROVAL_STATUS();

    // NAV errors
    error NAV_PROPOSAL_PENDING();
    error NAV_PROPOSAL_NOT_PENDING();
    error NAV_PROPOSAL_NOT_IN_REVIEW();
    error EVIDENCE_REQUIRED();
    error NOT_NAV_ATTESTOR();
    error ATTESTOR_CANNOT_BE_PROPOSER();
    error ALREADY_ATTESTED();
    error ATTESTATION_THRESHOLD_NOT_MET();
    error INVALID_ATTESTATION_CONFIG();
    error ATTESTOR_ALREADY_EXISTS();
    error NAV_CONFIG_TIMELOCK_NOT_EXPIRED();
    error NO_PENDING_NAV_CONFIG();

    // Execution policy errors
    error TARGET_FORBIDDEN();
    error CALL_NOT_ALLOWED();
    error VALUE_NOT_ALLOWED();
    error VALUE_EXCEEDS_CAP();
    error VALUE_EXCEEDS_WINDOW_CAP();
    error ARG_CONSTRAINT_VIOLATED();
    error ARG_CONSTRAINT_REQUIRED();
    error INVALID_CALL_RULE();
    error OPERATION_ID_USED();
    error INVALID_OPERATION_ID();
    error BATCH_SIZE_EXCEEDED();
    error EXECUTION_FAILED(uint256 index, bytes returnData);

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    /// @notice Operations forwarded from the vault on the 7540 redeem path
    enum Operation {
        RedeemRequest,
        CancelRedeemRequest,
        ClaimCancelRedeem,
        ClaimRedeem
    }

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

    /// @notice Lifecycle status of a NAV update proposal
    enum NAVProposalStatus {
        None,
        PendingAttestation,
        ReviewRequired,
        Finalized,
        Canceled
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fee configuration, mirrors the SuperVault family fee structure
    struct FeeConfig {
        uint256 performanceFeeBps; // On PPS growth above high-water mark at skim time
        uint256 managementFeeBps; // Entry fee on deposit fulfillment (asset-side)
        address recipient; // Fee sink (entry + performance)
    }

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

    /// @notice NAV attestation configuration
    /// @param attestors Set of independent attestor addresses
    /// @param threshold Number of attestations required to finalize a NAV proposal (MVP: 1)
    struct NavAttestationConfig {
        address[] attestors;
        uint8 threshold;
    }

    /// @notice A NAV update proposal
    struct NAVUpdateProposal {
        uint256 proposedPPS;
        uint256 effectiveTimestamp;
        bytes32 evidenceHash;
        string evidenceURI;
        address proposer;
        uint8 attestationCount;
        NAVProposalStatus status;
    }

    /// @notice Per-controller (7540 user) state for async deposits and redemptions
    struct ManagedVaultState {
        // Async deposits
        uint256 pendingDepositAssets; // Assets requested, held in escrow, awaiting fulfillment
        uint256 claimableDepositAssets; // Net assets fulfilled, claimable via deposit()/mint() (ERC-7540 claim)
        uint256 averageDepositPrice; // Weighted average PPS across fulfillments (claim pricing)
        // Cancellation (redeem)
        bool pendingCancelRedeemRequest;
        uint256 claimableCancelRedeemRequest;
        // Redeems
        uint256 pendingRedeemRequest; // Shares requested
        uint256 maxWithdraw; // Assets claimable after fulfillment
        uint256 averageRequestPPS; // Average PPS at the time of redeem request
        uint256 averageWithdrawPrice; // Average price for claimable assets
        uint16 redeemSlippageBps; // User-defined slippage tolerance in BPS for redeem fulfillment
    }

    /// @notice A whitelisted arbitrary call to execute
    struct ManagedCall {
        address target;
        uint256 value;
        bytes data;
    }

    /// @notice Execution policy rule for a (target, selector) pair
    /// @param allowed Whether calls to this (target, selector) are allowed
    /// @param valueAllowed Whether native value may be attached
    /// @param maxValuePerCall Maximum native value per call (only if valueAllowed)
    /// @param windowValueCap Maximum cumulative native value per rolling window (0 = per-call cap only)
    /// @param windowDuration Duration of the rolling value window in seconds
    /// @param constrainedArgs Static-word indices of address-typed args that must be allowlisted
    struct CallRule {
        bool allowed;
        bool valueAllowed;
        uint256 maxValuePerCall;
        uint256 windowValueCap;
        uint64 windowDuration;
        uint8[] constrainedArgs;
    }

    /// @notice Rolling window usage accounting for a (target, selector) pair
    struct WindowUsage {
        uint64 windowStart;
        uint256 valueUsed;
    }

    /// @notice Local variables for redeem fulfillment to avoid stack too deep
    struct FulfillRedeemVars {
        uint256 totalRequestedShares;
        uint256 totalNetAssetsOut;
        uint256 currentPPS;
        uint256 controllerBalance;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SuperGovernorSet(address indexed superGovernor);
    event Initialized(address indexed vault);

    // Deposit lifecycle
    event DepositRequestPlaced(address indexed controller, uint256 assets);
    event DepositRequestCanceled(address indexed controller, uint256 assets);
    event DepositRequestRejected(address indexed controller, uint256 assets, string reason);
    event DepositRequestFulfilled(
        address indexed controller, uint256 assetsGross, uint256 assetsNet, uint256 shares, uint256 pps
    );
    event DepositClaimed(address indexed controller, uint256 assets);
    event DepositPolicyUpdated(
        DepositApprovalMode approvalMode, bool depositsPaused, uint256 minDepositAssets, uint256 maxDepositAssets
    );

    // Approvals
    event DepositorApproved(address indexed depositor, bytes32 kycRef);
    event DepositorRejected(address indexed depositor);
    event DepositorRevoked(address indexed depositor);

    // Redemptions (mirrors SuperVaultStrategy events)
    event RedeemRequestPlaced(address indexed controller, address indexed owner, uint256 shares);
    event RedeemRequestClaimed(address indexed controller, address indexed receiver, uint256 assets, uint256 shares);
    event RedeemRequestsFulfilled(address[] controllers, uint256 processedShares, uint256 currentPPS);
    event RedeemRequestCanceled(address indexed controller, uint256 shares);
    event RedeemCancelRequestPlaced(address indexed controller);
    event RedeemCancelRequestFulfilled(address indexed controller, uint256 shares);
    event RedeemClaimable(
        address indexed controller, uint256 assetsFulfilled, uint256 sharesFulfilled, uint256 averageWithdrawPrice
    );
    event RedeemSlippageSet(address indexed controller, uint16 slippageBps);

    // NAV lifecycle
    event NAVProposed(
        uint256 indexed proposalId,
        uint256 previousPPS,
        uint256 proposedPPS,
        uint256 effectiveTimestamp,
        address indexed proposer,
        bytes32 evidenceHash,
        string evidenceURI
    );
    event NAVAttested(uint256 indexed proposalId, address indexed attestor, uint8 attestationCount);
    event NAVFinalized(uint256 indexed proposalId, uint256 finalizedPPS, uint256 effectiveTimestamp);
    event NAVReviewRequired(uint256 indexed proposalId, uint256 proposedPPS, uint256 currentPPS);
    event NAVProposalCanceled(uint256 indexed proposalId, address indexed canceledBy);
    event NAVLargeDeviationResolved(uint256 indexed proposalId, address indexed resolvedBy);
    event NAVAttestorAdded(address indexed attestor);
    event NAVAttestorRemoved(address indexed attestor);
    event NAVAttestationThresholdUpdated(uint8 threshold);
    event NAVAttestationConfigProposed(address[] attestors, uint8 threshold, uint256 effectiveTime);
    event NAVAttestationConfigCancelled();

    // Execution policy
    event CallRuleSet(
        address indexed target,
        bytes4 indexed selector,
        bool allowed,
        bool valueAllowed,
        uint256 maxValuePerCall,
        uint256 windowValueCap,
        uint64 windowDuration,
        uint8[] constrainedArgs
    );
    event CallRuleRemoved(address indexed target, bytes4 indexed selector);
    event ArgAllowedValueSet(
        address indexed target, bytes4 indexed selector, uint8 argIndex, address value, bool allowed
    );
    event ManagedCallExecuted(
        address indexed executor,
        address indexed target,
        bytes4 indexed selector,
        uint256 value,
        bytes32 operationId,
        bytes32 calldataHash
    );

    // Fees (mirrors SuperVaultStrategy events)
    event VaultFeeConfigUpdated(uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient);
    event VaultFeeConfigProposed(
        uint256 performanceFeeBps, uint256 managementFeeBps, address indexed recipient, uint256 effectiveTime
    );
    event FeeRecipientChanged(address indexed newRecipient);
    event ManagementFeePaid(address indexed controller, address indexed recipient, uint256 feeAssets, uint256 feeBps);
    event HWMPPSUpdated(uint256 newHwmPps, uint256 previousPps, uint256 profit, uint256 feeCollected);
    event HighWaterMarkReset(uint256 newHwmPps);
    event PerformanceFeeSkimmed(uint256 totalFee, uint256 superformFee);

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the controller with required parameters
    /// @param vaultAddress Address of the associated ManagedSuperVault
    /// @param feeConfigData Fee configuration
    /// @param depositPolicyData Deposit policy configuration
    /// @param navConfigData NAV attestation configuration
    function initialize(
        address vaultAddress,
        FeeConfig memory feeConfigData,
        DepositPolicy memory depositPolicyData,
        NavAttestationConfig memory navConfigData
    )
        external;

    /*//////////////////////////////////////////////////////////////
                        VAULT-ONLY OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Handle a new async deposit request placed through the vault
    /// @param controller The controller (7540 user) placing the request
    /// @param assets The amount of assets requested
    function handleDepositRequest(address controller, uint256 assets) external;

    /// @notice Handle cancellation of a pending deposit request; clears state and returns refundable assets
    /// @param controller The controller cancelling
    /// @return assets The amount of assets to refund from escrow
    function handleCancelDepositRequest(address controller) external returns (uint256 assets);

    /// @notice Handle claim of fulfilled deposit assets; decrements claimable state
    /// @dev The vault computes shares at the average deposit price and mints; this only updates accounting
    /// @param controller The controller claiming
    /// @param assets The amount of net fulfilled assets being claimed
    function handleClaimDeposit(address controller, uint256 assets) external;

    /// @notice Execute async redeem operations (request, cancel, claim), mirrors SuperVaultStrategy
    /// @param op The operation type
    /// @param controller The controller address
    /// @param receiver The receiver address
    /// @param amount The amount of assets or shares
    function handleOperations7540(Operation op, address controller, address receiver, uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: DEPOSITS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fulfill pending deposit requests at the current finalized NAV, minting claimable shares
    /// @dev Pulls pending assets from escrow into the controller, skims entry fee, prices shares at stored PPS.
    ///      Controllers with no pending deposit are skipped (not reverted) so a front-run cancel cannot
    ///      brick the whole batch.
    /// @param controllers Controllers with pending deposit requests
    function fulfillDepositRequests(address[] calldata controllers) external;

    /// @notice Reject pending deposit requests, refunding assets from escrow to the depositors
    /// @param controllers Controllers with pending deposit requests to reject
    /// @param reason Human-readable rejection reason (emitted)
    function rejectDepositRequests(address[] calldata controllers, string calldata reason) external;

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: APPROVALS
    //////////////////////////////////////////////////////////////*/

    /// @notice Approve depositors, optionally recording a KYC/subscription reference hash
    /// @param depositors The depositor addresses to approve
    /// @param kycRefs KYC/subscription reference hashes (bytes32(0) if not applicable)
    function approveDepositors(address[] calldata depositors, bytes32[] calldata kycRefs) external;

    /// @notice Reject depositors
    /// @param depositors The depositor addresses to reject
    function rejectDepositors(address[] calldata depositors) external;

    /// @notice Revoke previously approved depositors
    /// @param depositors The depositor addresses to revoke
    function revokeDepositors(address[] calldata depositors) external;

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: REDEMPTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fulfills pending cancel redeem requests by making shares claimable
    /// @param controllers Array of controller addresses with pending cancel requests
    function fulfillCancelRedeemRequests(address[] memory controllers) external;

    /// @notice Fulfills pending redeem requests with exact total assets per controller
    /// @param controllers Ordered/unique controllers with pending requests
    /// @param totalAssetsOut Total assets for each controller[i], bounded by slippage floor and theoretical value
    function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata totalAssetsOut) external;

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: NAV
    //////////////////////////////////////////////////////////////*/

    /// @notice Propose a NAV/PPS update with evidence; requires independent attestation to finalize
    /// @param newPPS The proposed price-per-share (scaled by asset decimals)
    /// @param effectiveTimestamp The observation timestamp the NAV corresponds to (<= block.timestamp)
    /// @param evidenceHash Hash of offchain evidence backing the NAV (required)
    /// @param evidenceURI URI of offchain evidence (optional)
    /// @return proposalId The created proposal id
    function proposeNAVUpdate(
        uint256 newPPS,
        uint256 effectiveTimestamp,
        bytes32 evidenceHash,
        string calldata evidenceURI
    )
        external
        returns (uint256 proposalId);

    /// @notice Attest a pending NAV proposal; auto-finalizes when the attestation threshold is met
    /// @param proposalId The proposal to attest
    function attestNAVUpdate(uint256 proposalId) external;

    /// @notice Cancel a pending or in-review NAV proposal
    /// @param proposalId The proposal to cancel
    function cancelNAVUpdate(uint256 proposalId) external;

    /// @notice Finalize a large-deviation NAV proposal after the vault was explicitly unpaused
    /// @dev Requires: proposal in ReviewRequired with threshold attestations, vault unpaused (elevated action).
    ///      This is the only path that finalizes a NAV exceeding the deviation bound.
    /// @param proposalId The proposal to resolve
    function resolveLargeDeviationNAV(uint256 proposalId) external;

    /// @notice Propose a replacement NAV attestor set and threshold (main manager only, timelocked)
    /// @dev The attestor set / threshold are the independence guarantee; changes are timelocked so
    ///      investors and Superform have a visible window to react before they take effect.
    /// @param attestors The new full attestor set
    /// @param threshold The new attestation threshold (1..attestors.length)
    function proposeNAVAttestationConfig(address[] calldata attestors, uint8 threshold) external;

    /// @notice Execute a pending NAV attestation config change after the timelock (main manager only)
    function executeNAVAttestationConfig() external;

    /// @notice Cancel a pending NAV attestation config change (main manager only)
    function cancelNAVAttestationConfig() external;

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Execute a single whitelisted call gated by the onchain execution policy
    /// @param call The call to execute
    /// @param operationId Unique operation id for replay protection (indexable)
    function executeManagedCall(ManagedCall calldata call, bytes32 operationId) external payable;

    /// @notice Execute a batch of whitelisted calls gated by the onchain execution policy
    /// @param calls The calls to execute
    /// @param operationId Unique operation id for replay protection (indexable)
    function executeManagedBatch(ManagedCall[] calldata calls, bytes32 operationId) external payable;

    /// @notice Set or update the execution policy rule for a (target, selector) pair (main manager only)
    /// @dev Sensitive value-moving selectors (approve/transfer/transferFrom/increaseAllowance/setApprovalForAll)
    ///      cannot be enabled without constraining their spender/recipient/operator argument
    function setCallRule(address target, bytes4 selector, CallRule calldata rule) external;

    /// @notice Remove the execution policy rule for a (target, selector) pair (main manager only)
    function removeCallRule(address target, bytes4 selector) external;

    /// @notice Allow or disallow an address value for a constrained argument (main manager only)
    function setArgAllowedValues(
        address target,
        bytes4 selector,
        uint8 argIndex,
        address[] calldata values,
        bool allowed
    )
        external;

    /*//////////////////////////////////////////////////////////////
                    MANAGER OPERATIONS: POLICY & FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Update the deposit policy (main manager only)
    function setDepositPolicy(DepositPolicy calldata policy) external;

    /// @notice Skim performance fees based on PPS high-water mark (mirrors SuperVaultStrategy)
    function skimPerformanceFee() external;

    /// @notice Propose a fee configuration change (main manager only, 1-week timelock)
    function proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    )
        external;

    /// @notice Execute the proposed fee configuration after the timelock
    function executeVaultFeeConfigUpdate() external;

    /// @notice Change the fee recipient (aggregator only, during primary manager replacement)
    function changeFeeRecipient(address newRecipient) external;

    /// @notice Reset the high-water mark PPS (aggregator only)
    function resetHighWaterMark(uint256 newHwmPps) external;

    /*//////////////////////////////////////////////////////////////
                        USER OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the slippage tolerance for redeem request fulfillments
    /// @param slippageBps Slippage tolerance in basis points
    function setRedeemSlippage(uint16 slippageBps) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the vault info
    function getVaultInfo() external view returns (address vault, address asset, uint8 vaultDecimals);

    /// @notice Get the fee configuration
    function getConfigInfo() external view returns (FeeConfig memory feeConfig);

    /// @notice Returns the currently stored PPS value (latest finalized attested NAV)
    function getStoredPPS() external view returns (uint256);

    /// @notice NAV mode marker for downstream systems; always "attested_manual"
    function navMode() external pure returns (string memory);

    /// @notice Get the per-controller managed vault state
    function getManagedVaultState(address controller) external view returns (ManagedVaultState memory state);

    /// @notice Get the deposit policy
    function getDepositPolicy() external view returns (DepositPolicy memory policy);

    /// @notice Get a depositor's approval status
    function getApprovalStatus(address depositor) external view returns (ApprovalStatus status);

    /// @notice Total assets across all pending deposit requests (held in escrow)
    function totalPendingDepositAssets() external view returns (uint256);

    /// @notice Pending deposit request assets for a controller
    function pendingDepositRequest(address controller) external view returns (uint256 pendingAssets);

    /// @notice Claimable (net, post-entry-fee) deposit assets for a controller
    function claimableDepositRequest(address controller) external view returns (uint256 claimableAssets);

    /// @notice Weighted average PPS at which a controller's deposits were fulfilled (claim pricing)
    function getAverageDepositPrice(address controller) external view returns (uint256 averageDepositPrice);

    /// @notice Get a NAV proposal
    function getNAVProposal(uint256 proposalId) external view returns (NAVUpdateProposal memory proposal);

    /// @notice Get the currently active (pending or in-review) NAV proposal id, 0 if none
    function getActiveNAVProposalId() external view returns (uint256 proposalId);

    /// @notice Get the NAV attestation configuration
    function getNAVAttestationConfig() external view returns (address[] memory attestors, uint8 threshold);

    /// @notice Get the pending (timelocked) NAV attestation config change, if any
    /// @return attestors The proposed attestor set
    /// @return threshold The proposed threshold
    /// @return effectiveTime Timestamp after which the change can be executed (0 = none pending)
    function getPendingNAVAttestationConfig()
        external
        view
        returns (address[] memory attestors, uint8 threshold, uint256 effectiveTime);

    /// @notice Whether an address is a configured NAV attestor
    function isNAVAttestor(address attestor) external view returns (bool);

    /// @notice Whether an attestor has attested a given proposal
    function hasAttested(uint256 proposalId, address attestor) external view returns (bool);

    /// @notice Get the execution policy rule for a (target, selector) pair
    function getCallRule(address target, bytes4 selector) external view returns (CallRule memory rule);

    /// @notice Get the rolling window usage for a (target, selector) pair
    function getWindowUsage(address target, bytes4 selector) external view returns (WindowUsage memory usage);

    /// @notice Whether an address value is allowed for a constrained argument
    function isArgValueAllowed(
        address target,
        bytes4 selector,
        uint8 argIndex,
        address value
    )
        external
        view
        returns (bool);

    /// @notice Whether an operation id has already been used
    function isOperationIdUsed(bytes32 operationId) external view returns (bool);

    /// @notice Get the pending redeem request amount (shares) for a controller
    function pendingRedeemRequest(address controller) external view returns (uint256 pendingShares);

    /// @notice Get the pending cancellation flag for a controller's redeem request
    function pendingCancelRedeemRequest(address controller) external view returns (bool isPending);

    /// @notice Get the claimable cancel redeem request amount (shares) for a controller
    function claimableCancelRedeemRequest(address controller) external view returns (uint256 claimableShares);

    /// @notice Get the claimable withdraw amount (assets) for a controller
    function claimableWithdraw(address controller) external view returns (uint256 claimableAssets);

    /// @notice Get the average withdraw price for a controller
    function getAverageWithdrawPrice(address controller) external view returns (uint256 averageWithdrawPrice);

    /// @notice Preview exact redeem fulfillment for offchain calculation
    function previewExactRedeem(address controller)
        external
        view
        returns (uint256 shares, uint256 theoreticalAssets, uint256 minAssets);

    /// @notice Get the current unrealized profit above the high-water mark
    function vaultUnrealizedProfit() external view returns (uint256);
}
