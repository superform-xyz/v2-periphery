// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultDepositQueue } from "../../src/ManagedSuperVault/ManagedSuperVaultDepositQueue.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import {
    IManagedSuperVaultDepositQueue
} from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultDepositQueue.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IERC7540Deposit, IERC7540CancelDeposit } from "../../src/vendor/standards/ERC7540/IERC7540Vault.sol";

/// @notice Unit + fuzz suite for the ManagedSuperVaultDepositQueue (async ERC-7540 deposit leg)
contract ManagedSuperVaultDepositQueueTest is ManagedSuperVaultTestBase {
    using Math for uint256;

    uint256 internal constant ENTRY_FEE_BPS = 100; // 1% management (entry) fee for fee-vault tests
    uint256 internal constant BPS = 10_000;

    address internal operator;

    function setUp() public override {
        super.setUp();
        operator = makeAddr("operator");
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _request(ManagedSuperVaultDepositQueue q, address depositor, uint256 assets) internal {
        vm.startPrank(depositor);
        asset.approve(address(q), assets);
        q.requestDeposit(assets, depositor, depositor);
        vm.stopPrank();
    }

    function _fulfill(ManagedSuperVaultDepositQueue q, address controller) internal {
        address[] memory controllers = new address[](1);
        controllers[0] = controller;
        vm.prank(manager);
        q.fulfillDepositRequests(controllers);
    }

    /// @dev Vault with a 1% management (entry) fee, skimmed natively by the strategy at fulfill
    function _createFeeVault() internal returns (ManagedSuperVault v, ManagedSuperVaultDepositQueue q) {
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();
        params.feeConfig.managementFeeBps = ENTRY_FEE_BPS;
        (address vault_,,, address queue_) = _createManagedVault(params);
        return (ManagedSuperVault(vault_), ManagedSuperVaultDepositQueue(queue_));
    }

    function _setApprovalMode(IManagedSuperVaultDepositQueue.DepositApprovalMode mode) internal {
        IManagedSuperVaultDepositQueue.DepositPolicy memory policy = queue.getDepositPolicy();
        policy.approvalMode = mode;
        vm.prank(manager);
        queue.setDepositPolicy(policy);
    }

    function _approveDepositor(ManagedSuperVaultDepositQueue q, address depositor) internal {
        address[] memory depositors = new address[](1);
        depositors[0] = depositor;
        bytes32[] memory refs = new bytes32[](1);
        refs[0] = keccak256("kyc-ref");
        vm.prank(manager);
        q.approveDepositors(depositors, refs);
    }

    /*//////////////////////////////////////////////////////////////
                            REQUEST PATH
    //////////////////////////////////////////////////////////////*/

    /// @notice Happy path: assets pulled into queue custody, pending state updated, events emitted
    function test_RequestDeposit_Success() public {
        uint256 amount = 100e18;
        uint256 userBalanceBefore = asset.balanceOf(user);

        vm.startPrank(user);
        asset.approve(address(queue), amount);

        vm.expectEmit(true, true, true, true);
        emit IERC7540Deposit.DepositRequest(user, user, 0, user, amount);
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositRequestPlaced(user, amount);
        uint256 requestId = queue.requestDeposit(amount, user, user);
        vm.stopPrank();

        assertEq(requestId, 0, "single-request model uses id 0");
        assertEq(queue.pendingDepositRequest(0, user), amount, "pending assets");
        assertEq(queue.totalPendingDepositAssets(), amount, "total pending");
        assertEq(asset.balanceOf(address(queue)), amount, "queue holds pending assets");
        assertEq(asset.balanceOf(user), userBalanceBefore - amount, "user debited");

        // A second request accumulates onto the same open request
        _request(queue, user, 50e18);
        assertEq(queue.pendingDepositRequest(0, user), 150e18, "pending accumulates");
        assertEq(queue.totalPendingDepositAssets(), 150e18, "total pending accumulates");
    }

    function test_RequestDeposit_RevertZeroAssets() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_AMOUNT.selector);
        vm.prank(user);
        queue.requestDeposit(0, user, user);
    }

    function test_RequestDeposit_RevertZeroController() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        vm.prank(user);
        queue.requestDeposit(1e18, address(0), user);
    }

    function test_RequestDeposit_RevertZeroOwner() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        vm.prank(user);
        queue.requestDeposit(1e18, user, address(0));
    }

    function test_RequestDeposit_RevertControllerNotOwner() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.CONTROLLER_MUST_EQUAL_OWNER.selector);
        vm.prank(user);
        queue.requestDeposit(1e18, user2, user);
    }

    function test_RequestDeposit_RevertCallerNeitherOwnerNorOperator() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_CALLER.selector);
        vm.prank(user2);
        queue.requestDeposit(1e18, user, user);
    }

    /// @notice Vault-approved operators (single operator surface on the vault) can request for the owner
    function test_RequestDeposit_OperatorCanRequestForOwner() public {
        uint256 amount = 100e18;

        vm.startPrank(user);
        vault.setOperator(operator, true);
        asset.approve(address(queue), amount);
        vm.stopPrank();

        vm.prank(operator);
        queue.requestDeposit(amount, user, user);

        assertEq(queue.pendingDepositRequest(0, user), amount, "operator placed request for owner");
        assertEq(asset.balanceOf(address(queue)), amount, "assets pulled from owner");
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT POLICY
    //////////////////////////////////////////////////////////////*/

    function test_RequestDeposit_RevertWhenDepositsPaused() public {
        IManagedSuperVaultDepositQueue.DepositPolicy memory policy = queue.getDepositPolicy();
        policy.depositsPaused = true;
        vm.prank(manager);
        queue.setDepositPolicy(policy);

        vm.startPrank(user);
        asset.approve(address(queue), 100e18);
        vm.expectRevert(IManagedSuperVaultDepositQueue.DEPOSITS_PAUSED.selector);
        queue.requestDeposit(100e18, user, user);
        vm.stopPrank();

        // Unpause -> request works again
        policy.depositsPaused = false;
        vm.prank(manager);
        queue.setDepositPolicy(policy);

        vm.prank(user);
        queue.requestDeposit(100e18, user, user);
        assertEq(queue.pendingDepositRequest(0, user), 100e18);
    }

    function test_RequestDeposit_MinMaxBounds() public {
        IManagedSuperVaultDepositQueue.DepositPolicy memory policy = queue.getDepositPolicy();
        policy.minDepositAssets = 10e18;
        policy.maxDepositAssets = 150e18; // per-request max
        vm.prank(manager);
        queue.setDepositPolicy(policy);

        vm.startPrank(user);
        asset.approve(address(queue), type(uint256).max);

        vm.expectRevert(IManagedSuperVaultDepositQueue.DEPOSIT_BELOW_MINIMUM.selector);
        queue.requestDeposit(9e18, user, user);

        vm.expectRevert(IManagedSuperVaultDepositQueue.DEPOSIT_ABOVE_MAXIMUM.selector);
        queue.requestDeposit(151e18, user, user);

        // Within [min, max] passes; the cap is per-request, so a second request is independent
        queue.requestDeposit(150e18, user, user);
        queue.requestDeposit(150e18, user, user);
        assertEq(queue.pendingDepositRequest(0, user), 300e18);
        vm.stopPrank();
    }

    function test_RequestDeposit_AllowlistMode_ApproveAndRevoke() public {
        _setApprovalMode(IManagedSuperVaultDepositQueue.DepositApprovalMode.Allowlist);

        vm.startPrank(user);
        asset.approve(address(queue), type(uint256).max);
        vm.expectRevert(IManagedSuperVaultDepositQueue.DEPOSITOR_NOT_APPROVED.selector);
        queue.requestDeposit(100e18, user, user);
        vm.stopPrank();

        // Approve (kycRef hash is event-only)
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        bytes32[] memory refs = new bytes32[](1);
        refs[0] = keccak256("kyc-ref");
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositorApproved(user, refs[0]);
        vm.prank(manager);
        queue.approveDepositors(depositors, refs);

        assertEq(
            uint8(queue.getApprovalStatus(user)), uint8(IManagedSuperVaultDepositQueue.ApprovalStatus.Approved)
        );

        vm.prank(user);
        queue.requestDeposit(100e18, user, user);
        assertEq(queue.pendingDepositRequest(0, user), 100e18);

        // Revoke blocks further requests
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositorRevoked(user);
        vm.prank(manager);
        queue.revokeDepositors(depositors);
        assertEq(
            uint8(queue.getApprovalStatus(user)), uint8(IManagedSuperVaultDepositQueue.ApprovalStatus.Revoked)
        );

        vm.startPrank(user);
        vm.expectRevert(IManagedSuperVaultDepositQueue.DEPOSITOR_NOT_APPROVED.selector);
        queue.requestDeposit(1e18, user, user);
        vm.stopPrank();
    }

    /// @notice ManagerApproved and KycApproved gate exactly like Allowlist: only Approved status passes
    function test_RequestDeposit_ManagerApprovedAndKycModes_GateTheSame() public {
        IManagedSuperVaultDepositQueue.DepositApprovalMode[2] memory modes = [
            IManagedSuperVaultDepositQueue.DepositApprovalMode.ManagerApproved,
            IManagedSuperVaultDepositQueue.DepositApprovalMode.KycApproved
        ];

        vm.prank(user);
        asset.approve(address(queue), type(uint256).max);

        address[] memory depositors = new address[](1);
        depositors[0] = user;

        for (uint256 i; i < modes.length; ++i) {
            _setApprovalMode(modes[i]);

            // Reset user to unapproved (Rejected) for the second iteration
            if (queue.getApprovalStatus(user) == IManagedSuperVaultDepositQueue.ApprovalStatus.Approved) {
                vm.prank(manager);
                queue.rejectDepositors(depositors);
            }

            vm.expectRevert(IManagedSuperVaultDepositQueue.DEPOSITOR_NOT_APPROVED.selector);
            vm.prank(user);
            queue.requestDeposit(100e18, user, user);

            _approveDepositor(queue, user);

            vm.prank(user);
            queue.requestDeposit(100e18, user, user);
        }

        assertEq(queue.pendingDepositRequest(0, user), 200e18, "one request per gated mode");
    }

    function test_RejectDepositors_SetsStatus() public {
        address[] memory depositors = new address[](1);
        depositors[0] = user;

        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositorRejected(user);
        vm.prank(manager);
        queue.rejectDepositors(depositors);

        assertEq(
            uint8(queue.getApprovalStatus(user)), uint8(IManagedSuperVaultDepositQueue.ApprovalStatus.Rejected)
        );
    }

    function test_RevokeDepositors_RevertWhenNotApproved() public {
        address[] memory depositors = new address[](1);
        depositors[0] = user; // status None

        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_APPROVAL_STATUS.selector);
        vm.prank(manager);
        queue.revokeDepositors(depositors);
    }

    function test_ApprovalManagement_Validation() public {
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        bytes32[] memory refs = new bytes32[](1);

        // Manager-gated
        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_MANAGER.selector);
        vm.prank(user);
        queue.approveDepositors(depositors, refs);

        vm.startPrank(manager);
        // Zero-length arrays
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_LENGTH.selector);
        queue.approveDepositors(new address[](0), new bytes32[](0));

        // Mismatched arrays
        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_ARRAY_LENGTH.selector);
        queue.approveDepositors(depositors, new bytes32[](2));

        // Zero depositor
        address[] memory zeroDepositor = new address[](1);
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        queue.approveDepositors(zeroDepositor, refs);
        vm.stopPrank();
    }

    function test_SetDepositPolicy_MainManagerOnly() public {
        IManagedSuperVaultDepositQueue.DepositPolicy memory policy = queue.getDepositPolicy();
        policy.minDepositAssets = 5e18;

        // Secondary manager is a manager but NOT the main manager
        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_MAIN_MANAGER.selector);
        vm.prank(secondaryManager);
        queue.setDepositPolicy(policy);

        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_MAIN_MANAGER.selector);
        vm.prank(user);
        queue.setDepositPolicy(policy);

        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositPolicyUpdated(
            policy.approvalMode, policy.depositsPaused, policy.minDepositAssets, policy.maxDepositAssets
        );
        vm.prank(manager);
        queue.setDepositPolicy(policy);

        assertEq(queue.getDepositPolicy().minDepositAssets, 5e18);
    }

    /*//////////////////////////////////////////////////////////////
                        REQUEST-SIDE STATE GATE
    //////////////////////////////////////////////////////////////*/

    function test_RequestDeposit_RevertWhenStrategyPaused() public {
        vm.prank(manager);
        aggregator.pauseStrategy(address(strategy));

        vm.startPrank(user);
        asset.approve(address(queue), 100e18);
        vm.expectRevert(IManagedSuperVaultDepositQueue.VAULT_NOT_ACCEPTING_DEPOSITS.selector);
        queue.requestDeposit(100e18, user, user);
        vm.stopPrank();
    }

    function test_RequestDeposit_RevertWhenPPSExpired() public {
        // Warp past ppsExpiration (default 1 days) and MAX_STALENESS (1 days) since the last update
        vm.warp(block.timestamp + strategy.ppsExpiration() + MAX_STALENESS + 1);

        vm.startPrank(user);
        asset.approve(address(queue), 100e18);
        vm.expectRevert(IManagedSuperVaultDepositQueue.VAULT_NOT_ACCEPTING_DEPOSITS.selector);
        queue.requestDeposit(100e18, user, user);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                CANCEL
    //////////////////////////////////////////////////////////////*/

    function test_CancelDepositRequest_RefundsInstantly() public {
        uint256 amount = 100e18;
        _request(queue, user, amount);
        uint256 balanceBefore = asset.balanceOf(user);

        vm.expectEmit(true, true, true, true);
        emit IERC7540CancelDeposit.CancelDepositRequest(user, 0, user);
        vm.expectEmit(true, true, true, true);
        emit IERC7540CancelDeposit.CancelDepositClaim(user, user, 0, user, amount);
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositRequestCanceled(user, amount);
        vm.prank(user);
        queue.cancelDepositRequest(0, user);

        assertEq(asset.balanceOf(user), balanceBefore + amount, "instant refund");
        assertEq(queue.pendingDepositRequest(0, user), 0, "pending cleared");
        assertEq(queue.totalPendingDepositAssets(), 0, "total pending cleared");
        assertEq(asset.balanceOf(address(queue)), 0, "queue drained");
    }

    function test_CancelDepositRequest_RevertNoPending() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.REQUEST_NOT_FOUND.selector);
        vm.prank(user);
        queue.cancelDepositRequest(0, user);
    }

    function test_CancelDepositRequest_RevertInvalidCaller() public {
        _request(queue, user, 100e18);

        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_CALLER.selector);
        vm.prank(user2);
        queue.cancelDepositRequest(0, user);

        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        vm.prank(user);
        queue.cancelDepositRequest(0, address(0));
    }

    /// @notice Refund always goes to the controller, even when an operator cancels
    function test_CancelDepositRequest_OperatorCanCancel() public {
        _request(queue, user, 100e18);
        vm.prank(user);
        vault.setOperator(operator, true);

        uint256 balanceBefore = asset.balanceOf(user);
        vm.prank(operator);
        queue.cancelDepositRequest(0, user);

        assertEq(asset.balanceOf(user), balanceBefore + 100e18, "refund to controller, not operator");
        assertEq(asset.balanceOf(operator), 0);
    }

    /// @notice Cancels are instantly fulfilled: no pending/claimable cancel state ever exists
    function test_CancelViews_InstantModel() public {
        _request(queue, user, 100e18);

        assertFalse(queue.pendingCancelDepositRequest(0, user));
        assertEq(queue.claimableCancelDepositRequest(0, user), 0);

        vm.prank(user);
        queue.cancelDepositRequest(0, user);

        assertFalse(queue.pendingCancelDepositRequest(0, user));
        assertEq(queue.claimableCancelDepositRequest(0, user), 0);

        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_IMPLEMENTED.selector);
        queue.claimCancelDepositRequest(0, user, user);
    }

    /*//////////////////////////////////////////////////////////////
                                FULFILL
    //////////////////////////////////////////////////////////////*/

    function test_FulfillDepositRequests_RevertNotManager() public {
        address[] memory controllers = new address[](1);
        controllers[0] = user;

        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_MANAGER.selector);
        vm.prank(user);
        queue.fulfillDepositRequests(controllers);
    }

    function test_FulfillDepositRequests_RevertZeroLength() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_LENGTH.selector);
        vm.prank(manager);
        queue.fulfillDepositRequests(new address[](0));
    }

    /// @notice Zero mgmt fee: net == gross, shares = gross * PRECISION / pps, shares held by the queue
    function test_FulfillDepositRequests_Success() public {
        uint256 amount = 100e18;
        _request(queue, user, amount);

        assertEq(queue.getAverageDepositPrice(user), 0, "no average price before fulfill");

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositRequestFulfilled(user, amount, amount, amount, INITIAL_PPS);
        vm.prank(manager);
        queue.fulfillDepositRequests(controllers);

        assertEq(queue.pendingDepositRequest(0, user), 0, "pending cleared");
        assertEq(queue.totalPendingDepositAssets(), 0, "total pending cleared");
        assertEq(queue.claimableDepositRequest(0, user), amount, "claimable assets == net == gross");
        assertEq(queue.maxDeposit(user), amount, "maxDeposit mirrors claimable assets");
        assertEq(queue.maxMint(user), amount, "maxMint mirrors claimable shares (pps 1.0)");
        assertEq(vault.balanceOf(address(queue)), amount, "queue holds pre-minted shares");
        assertEq(vault.balanceOf(user), 0, "nothing claimed yet");
        assertEq(queue.getAverageDepositPrice(user), INITIAL_PPS, "average price = pps at fulfill");
    }

    function test_FulfillDepositRequests_SecondaryManagerCanFulfill() public {
        _request(queue, user, 100e18);

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        vm.prank(secondaryManager);
        queue.fulfillDepositRequests(controllers);

        assertEq(queue.claimableDepositRequest(0, user), 100e18);
    }

    /// @notice Zero-pending controllers are skipped (a front-run cancel cannot brick the batch)
    function test_FulfillDepositRequests_SkipsZeroPending() public {
        _request(queue, user2, 100e18);

        address[] memory controllers = new address[](2);
        controllers[0] = user; // no request -> skipped
        controllers[1] = user2; // fulfilled
        vm.prank(manager);
        queue.fulfillDepositRequests(controllers);

        assertEq(queue.claimableDepositRequest(0, user), 0, "no-request controller untouched");
        assertEq(queue.claimableDepositRequest(0, user2), 100e18, "real request fulfilled");
    }

    /// @notice Queue accounting must exactly match the strategy's native entry-fee skim
    function test_FulfillDepositRequests_EntryFeeParity() public {
        (ManagedSuperVault v, ManagedSuperVaultDepositQueue q) = _createFeeVault();

        uint256 gross = 100e18 + 7; // odd amount to exercise the ceil rounding on the fee
        uint256 fee = gross.mulDiv(ENTRY_FEE_BPS, BPS, Math.Rounding.Ceil);
        uint256 net = gross - fee;

        _request(q, user, gross);

        // The vault's exact fee/share math, computed BEFORE fulfill
        uint256 expectedShares = v.previewDeposit(gross);
        uint256 feeRecipientBefore = asset.balanceOf(feeRecipient);

        _fulfill(q, user);

        assertEq(q.claimableDepositRequest(0, user), net, "claimable assets = gross - ceil fee");
        assertEq(q.maxMint(user), expectedShares, "claimable shares == previewDeposit(gross)");
        assertEq(v.balanceOf(address(q)), expectedShares, "queue holds exactly the minted net shares");
        assertEq(asset.balanceOf(feeRecipient), feeRecipientBefore + fee, "strategy paid the entry fee");
        assertEq(asset.balanceOf(address(q)), 0, "queue forwarded the full gross");
    }

    /// @notice Dust requests netting to zero are skipped (stay pending for cancel/reject), not reverted
    function test_FulfillDepositRequests_SkipsDust() public {
        (, ManagedSuperVaultDepositQueue q) = _createFeeVault();

        // 1 wei -> 1% fee ceil-rounds to 1 wei -> net 0 -> skip
        _request(q, user, 1);
        _request(q, user2, 100e18);

        address[] memory controllers = new address[](2);
        controllers[0] = user;
        controllers[1] = user2;
        vm.prank(manager);
        q.fulfillDepositRequests(controllers);

        assertEq(q.pendingDepositRequest(0, user), 1, "dust request stays pending");
        assertEq(q.claimableDepositRequest(0, user), 0, "dust request not fulfilled");
        assertEq(q.claimableDepositRequest(0, user2), 99e18, "real request fulfilled");

        // The dust request can still be cancelled for a refund
        vm.prank(user);
        q.cancelDepositRequest(0, user);
        assertEq(q.pendingDepositRequest(0, user), 0);
    }

    function test_FulfillDepositRequests_RevertWhenPaused() public {
        _request(queue, user, 100e18);

        vm.prank(manager);
        aggregator.pauseStrategy(address(strategy));

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        vm.prank(manager);
        queue.fulfillDepositRequests(controllers);
    }

    function test_FulfillDepositRequests_RevertWhenPPSExpired() public {
        _request(queue, user, 100e18);

        vm.warp(block.timestamp + strategy.ppsExpiration() + 1);

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        vm.expectRevert(ISuperVaultStrategy.PPS_EXPIRED.selector);
        vm.prank(manager);
        queue.fulfillDepositRequests(controllers);
    }

    /// @notice Fulfillment prices at the CURRENT attested PPS, not the PPS at request time
    function test_FulfillDepositRequests_PricesAtCurrentPPS() public {
        uint256 amount = 100e18;
        _request(queue, user, amount); // requested at PPS 1e18

        _pushNAV(1.2e18); // within the 50% deviation threshold

        uint256 expectedShares = amount.mulDiv(vault.PRECISION(), 1.2e18); // floor

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositRequestFulfilled(user, amount, amount, expectedShares, 1.2e18);
        vm.prank(manager);
        queue.fulfillDepositRequests(controllers);

        assertEq(queue.maxMint(user), expectedShares, "shares priced at current attested PPS");
        assertEq(queue.claimableDepositRequest(0, user), amount);
        assertEq(
            queue.getAverageDepositPrice(user),
            amount.mulDiv(vault.PRECISION(), expectedShares),
            "derived average price"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        CLAIMS (PRO-RATA)
    //////////////////////////////////////////////////////////////*/

    /// @notice Full claim transfers ALL claimable shares exactly and zeroes both balances
    function test_Deposit_FullClaim() public {
        uint256 amount = 100e18;
        _request(queue, user, amount);
        _pushNAV(1.2e18);
        _fulfill(queue, user);

        uint256 claimableAssets = queue.maxDeposit(user);
        uint256 claimableShares = queue.maxMint(user);

        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.Deposit(user, user, claimableAssets, claimableShares);
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositClaimed(user, claimableAssets);
        vm.prank(user);
        uint256 shares = queue.deposit(claimableAssets, user, user);

        assertEq(shares, claimableShares, "full claim transfers the exact remaining shares");
        assertEq(vault.balanceOf(user), claimableShares, "native vault shares delivered");
        assertEq(vault.balanceOf(address(queue)), 0, "queue fully drained");
        assertEq(queue.maxDeposit(user), 0, "claimable assets zeroed");
        assertEq(queue.maxMint(user), 0, "claimable shares zeroed");
    }

    /// @notice Partial claims are pro-rata (floor) over the exact claimable balances
    function test_Deposit_PartialClaims() public {
        uint256 amount = 100e18;
        _request(queue, user, amount);
        _pushNAV(1.2e18);
        _fulfill(queue, user);

        uint256 assetsTotal = queue.maxDeposit(user);
        uint256 sharesTotal = queue.maxMint(user);

        // First partial: 40% of claimable assets
        uint256 a1 = 40e18;
        uint256 expected1 = sharesTotal.mulDiv(a1, assetsTotal); // floor
        vm.prank(user);
        uint256 s1 = queue.deposit(a1, user, user);
        assertEq(s1, expected1, "pro-rata floor on partial claim");
        assertEq(queue.maxDeposit(user), assetsTotal - a1);
        assertEq(queue.maxMint(user), sharesTotal - s1);

        // Second partial: remainder — exhausts both balances exactly
        uint256 a2 = assetsTotal - a1;
        vm.prank(user);
        uint256 s2 = queue.deposit(a2, user, user);

        assertEq(s1 + s2, sharesTotal, "partials sum exactly to minted shares");
        assertLe(s1 + s2, sharesTotal, "never over-distributes");
        assertEq(queue.maxDeposit(user), 0);
        assertEq(queue.maxMint(user), 0);
        assertEq(vault.balanceOf(user), sharesTotal);
        assertEq(vault.balanceOf(address(queue)), 0);
    }

    /// @notice Mint path consumes ceil-rounded assets; minting all shares consumes exactly all assets
    function test_Mint_ConsumesCeilRoundedAssets() public {
        uint256 amount = 100e18;
        _request(queue, user, amount);
        _pushNAV(1.2e18);
        _fulfill(queue, user);

        uint256 assetsTotal = queue.maxDeposit(user);
        uint256 sharesTotal = queue.maxMint(user);

        uint256 s1 = sharesTotal / 3;
        uint256 expectedAssets1 = assetsTotal.mulDiv(s1, sharesTotal, Math.Rounding.Ceil);
        vm.prank(user);
        uint256 a1 = queue.mint(s1, user, user);
        assertEq(a1, expectedAssets1, "mint consumes ceil-rounded assets (against the claimer)");
        assertEq(queue.maxDeposit(user), assetsTotal - a1);
        assertEq(queue.maxMint(user), sharesTotal - s1);

        // Mint all remaining shares -> consumes exactly all remaining assets
        uint256 s2 = sharesTotal - s1;
        vm.prank(user);
        uint256 a2 = queue.mint(s2, user, user);

        assertEq(a1 + a2, assetsTotal, "mint(allShares) consumes exactly all assets");
        assertEq(queue.maxDeposit(user), 0);
        assertEq(queue.maxMint(user), 0);
        assertEq(vault.balanceOf(user), sharesTotal);
    }

    function test_Claims_Reverts() public {
        uint256 amount = 100e18;
        _request(queue, user, amount);
        _fulfill(queue, user);

        uint256 claimableAssets = queue.maxDeposit(user);
        uint256 claimableShares = queue.maxMint(user);

        vm.startPrank(user);
        // More than claimable
        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_AMOUNT.selector);
        queue.deposit(claimableAssets + 1, user, user);
        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_AMOUNT.selector);
        queue.mint(claimableShares + 1, user, user);

        // Zero amounts
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_AMOUNT.selector);
        queue.deposit(0, user, user);
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_AMOUNT.selector);
        queue.mint(0, user, user);

        // Zero receiver / controller
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        queue.deposit(1e18, address(0), user);
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        queue.deposit(1e18, user, address(0));
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        queue.mint(1e18, address(0), user);
        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_ADDRESS.selector);
        queue.mint(1e18, user, address(0));
        vm.stopPrank();

        // Neither controller nor operator
        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_CALLER.selector);
        vm.prank(user2);
        queue.deposit(1e18, user2, user);
        vm.expectRevert(IManagedSuperVaultDepositQueue.INVALID_CALLER.selector);
        vm.prank(user2);
        queue.mint(1e18, user2, user);
    }

    function test_Claims_OperatorCanClaimToReceiver() public {
        uint256 amount = 100e18;
        _request(queue, user, amount);
        _fulfill(queue, user);

        vm.prank(user);
        vault.setOperator(operator, true);

        address receiver = makeAddr("receiver");
        uint256 claimableAssets = queue.maxDeposit(user);

        vm.prank(operator);
        uint256 shares = queue.deposit(claimableAssets, receiver, user);

        assertEq(vault.balanceOf(receiver), shares, "operator claimed to the designated receiver");
        assertEq(queue.maxDeposit(user), 0);
        assertEq(queue.maxMint(user), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        CLAIM CONSERVATION (FUZZ)
    //////////////////////////////////////////////////////////////*/

    /// @dev One partial claim for `who` driven by randomness `r` (mixes deposit- and mint-path).
    ///      Returns (sharesOut, assetsConsumed); no-op when nothing meaningful is claimable.
    function _partialClaim(address who, uint256 r) internal returns (uint256 sharesOut, uint256 assetsConsumed) {
        IManagedSuperVaultDepositQueue.DepositState memory st = queue.getDepositState(who);
        if (st.claimableDepositAssets == 0 || st.claimableDepositShares == 0) return (0, 0);

        if (r & 1 == 1) {
            uint256 s = bound(r >> 1, 1, st.claimableDepositShares);
            vm.prank(who);
            assetsConsumed = queue.mint(s, who, who);
            sharesOut = s;
        } else {
            uint256 a = bound(r >> 1, 1, st.claimableDepositAssets);
            // Skip amounts whose pro-rata share floor-rounds to zero (contract reverts INVALID_AMOUNT)
            if (st.claimableDepositShares.mulDiv(a, st.claimableDepositAssets) == 0) return (0, 0);
            vm.prank(who);
            sharesOut = queue.deposit(a, who, who);
            assetsConsumed = a;
        }
    }

    /// @dev Drains `who`'s claimable balances completely; returns (sharesOut, assetsConsumed)
    function _finalClaim(address who) internal returns (uint256 sharesOut, uint256 assetsConsumed) {
        IManagedSuperVaultDepositQueue.DepositState memory st = queue.getDepositState(who);
        if (st.claimableDepositAssets > 0) {
            vm.prank(who);
            sharesOut = queue.deposit(st.claimableDepositAssets, who, who);
            assetsConsumed = st.claimableDepositAssets;
        } else if (st.claimableDepositShares > 0) {
            // Assets already fully consumed by ceil-rounded mints; recover the stranded shares
            vm.prank(who);
            assetsConsumed = queue.mint(st.claimableDepositShares, who, who);
            sharesOut = st.claimableDepositShares;
        }
    }

    /// @notice request -> fulfill (at a fuzzed PPS) -> N mixed partial claims never over-distributes,
    ///         and a final full claim leaves exactly 0/0 with everything conserved
    function testFuzz_Claims_Conservation(uint256 amount, uint256 pps, uint256 seed) public {
        amount = bound(amount, 1e12, 1_000_000e18);
        pps = bound(pps, 0.6e18, 1.4e18); // within the 50% deviation threshold

        _request(queue, user, amount);
        _pushNAV(pps);
        _fulfill(queue, user);

        uint256 assetsNet = queue.maxDeposit(user);
        uint256 sharesMinted = queue.maxMint(user);
        assertEq(assetsNet, amount, "net == gross with zero mgmt fee");
        assertEq(sharesMinted, amount.mulDiv(vault.PRECISION(), pps), "shares = gross * PRECISION / pps");
        assertEq(vault.balanceOf(address(queue)), sharesMinted);

        uint256 sumShares;
        uint256 sumAssets;

        for (uint256 i; i < 4; ++i) {
            (uint256 s, uint256 a) = _partialClaim(user, uint256(keccak256(abi.encode(seed, i))));
            sumShares += s;
            sumAssets += a;

            assertLe(sumShares, sharesMinted, "shares over-distribution");
            assertLe(sumAssets, assetsNet, "assets over-consumption");
        }

        (uint256 fs, uint256 fa) = _finalClaim(user);
        sumShares += fs;
        sumAssets += fa;

        assertEq(queue.maxDeposit(user), 0, "final claim zeroes assets");
        assertEq(queue.maxMint(user), 0, "final claim zeroes shares");
        assertEq(sumShares, sharesMinted, "all minted shares distributed");
        assertEq(sumAssets, assetsNet, "all net assets consumed");
        assertEq(vault.balanceOf(user), sharesMinted, "user received every share");
        assertEq(vault.balanceOf(address(queue)), 0, "queue holds nothing after full claim");
    }

    /// @notice Interleaved claims across two controllers never touch each other's claimable state
    function testFuzz_Claims_CrossControllerIsolation(uint256 a1, uint256 a2, uint256 pps, uint256 seed) public {
        a1 = bound(a1, 1e12, 1_000_000e18);
        a2 = bound(a2, 1e12, 1_000_000e18);
        pps = bound(pps, 0.6e18, 1.4e18);

        _request(queue, user, a1);
        _request(queue, user2, a2);
        _pushNAV(pps);

        address[] memory controllers = new address[](2);
        controllers[0] = user;
        controllers[1] = user2;
        vm.prank(manager);
        queue.fulfillDepositRequests(controllers);

        uint256 minted1 = queue.maxMint(user);
        uint256 minted2 = queue.maxMint(user2);
        assertEq(vault.balanceOf(address(queue)), minted1 + minted2);

        uint256 sumShares1;
        uint256 sumShares2;

        for (uint256 i; i < 3; ++i) {
            // user claims; user2's claimables must be untouched
            IManagedSuperVaultDepositQueue.DepositState memory other = queue.getDepositState(user2);
            (uint256 s1,) = _partialClaim(user, uint256(keccak256(abi.encode(seed, "u1", i))));
            sumShares1 += s1;
            assertEq(queue.maxDeposit(user2), other.claimableDepositAssets, "user claim touched user2 assets");
            assertEq(queue.maxMint(user2), other.claimableDepositShares, "user claim touched user2 shares");

            // user2 claims; user's claimables must be untouched
            other = queue.getDepositState(user);
            (uint256 s2,) = _partialClaim(user2, uint256(keccak256(abi.encode(seed, "u2", i))));
            sumShares2 += s2;
            assertEq(queue.maxDeposit(user), other.claimableDepositAssets, "user2 claim touched user assets");
            assertEq(queue.maxMint(user), other.claimableDepositShares, "user2 claim touched user shares");
        }

        (uint256 f1,) = _finalClaim(user);
        (uint256 f2,) = _finalClaim(user2);
        sumShares1 += f1;
        sumShares2 += f2;

        assertEq(sumShares1, minted1, "controller A received exactly its mint");
        assertEq(sumShares2, minted2, "controller B received exactly its mint");
        assertEq(vault.balanceOf(user), minted1);
        assertEq(vault.balanceOf(user2), minted2);
        assertEq(vault.balanceOf(address(queue)), 0, "queue fully distributed");
        assertEq(queue.maxDeposit(user) + queue.maxMint(user), 0);
        assertEq(queue.maxDeposit(user2) + queue.maxMint(user2), 0);
    }

    /*//////////////////////////////////////////////////////////////
                                REJECT
    //////////////////////////////////////////////////////////////*/

    function test_RejectDepositRequests_RefundsAndEmits() public {
        _request(queue, user, 100e18);
        _request(queue, user2, 50e18);

        uint256 balance1Before = asset.balanceOf(user);
        uint256 balance2Before = asset.balanceOf(user2);

        // Batch includes a zero-pending controller which is skipped, not reverted
        address[] memory controllers = new address[](3);
        controllers[0] = user;
        controllers[1] = user2;
        controllers[2] = makeAddr("noRequest");

        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositRequestRejected(user, 100e18, "kyc failed");
        vm.expectEmit(true, true, true, true);
        emit IManagedSuperVaultDepositQueue.DepositRequestRejected(user2, 50e18, "kyc failed");
        vm.prank(manager);
        queue.rejectDepositRequests(controllers, "kyc failed");

        assertEq(asset.balanceOf(user), balance1Before + 100e18, "user refunded");
        assertEq(asset.balanceOf(user2), balance2Before + 50e18, "user2 refunded");
        assertEq(queue.pendingDepositRequest(0, user), 0);
        assertEq(queue.pendingDepositRequest(0, user2), 0);
        assertEq(queue.totalPendingDepositAssets(), 0);
        assertEq(asset.balanceOf(address(queue)), 0);
    }

    function test_RejectDepositRequests_Reverts() public {
        address[] memory controllers = new address[](1);
        controllers[0] = user;

        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_MANAGER.selector);
        vm.prank(user);
        queue.rejectDepositRequests(controllers, "nope");

        vm.expectRevert(IManagedSuperVaultDepositQueue.ZERO_LENGTH.selector);
        vm.prank(manager);
        queue.rejectDepositRequests(new address[](0), "nope");
    }

    /*//////////////////////////////////////////////////////////////
                        VIEWS / 7540 CONFORMANCE
    //////////////////////////////////////////////////////////////*/

    function test_Views_Addresses() public view {
        assertEq(queue.asset(), address(asset));
        assertEq(queue.share(), address(vault), "ERC-7575: share token is the vault");
        assertEq(queue.vault(), address(vault));
        assertEq(queue.strategy(), address(strategy));
        assertEq(queue.aggregator(), address(aggregator));
    }

    /// @notice ERC-7540: previews MUST revert on async request legs
    function test_Previews_RevertNotImplemented() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_IMPLEMENTED.selector);
        queue.previewDeposit(1e18);

        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_IMPLEMENTED.selector);
        queue.previewMint(1e18);
    }

    /// @notice Operator approvals live on the vault; the queue only mirrors them
    function test_Operator_PassThrough() public {
        vm.expectRevert(IManagedSuperVaultDepositQueue.NOT_IMPLEMENTED.selector);
        queue.setOperator(operator, true);

        assertFalse(queue.isOperator(user, operator));

        vm.prank(user);
        vault.setOperator(operator, true);
        assertTrue(queue.isOperator(user, operator), "mirrors the vault's operator registry");

        vm.prank(user);
        vault.setOperator(operator, false);
        assertFalse(queue.isOperator(user, operator));
    }

    function test_SupportsInterface() public view {
        assertTrue(queue.supportsInterface(type(IERC7540Deposit).interfaceId));
        assertTrue(queue.supportsInterface(type(IERC7540CancelDeposit).interfaceId));
        assertTrue(queue.supportsInterface(type(IERC165).interfaceId));
        assertFalse(queue.supportsInterface(0xdeadbeef));
    }

    /*//////////////////////////////////////////////////////////////
                    VAULT-GATE REGRESSION (MANAGED DIFF)
    //////////////////////////////////////////////////////////////*/

    /// @notice Sync deposit/mint on the vault are gated to the deposit queue
    function test_VaultGate_DirectDepositAndMintRevert() public {
        vm.startPrank(user);
        vm.expectRevert(ManagedSuperVault.ONLY_DEPOSIT_QUEUE.selector);
        vault.deposit(100e18, user);

        vm.expectRevert(ManagedSuperVault.ONLY_DEPOSIT_QUEUE.selector);
        vault.mint(100e18, user);
        vm.stopPrank();
    }

    /// @notice maxDeposit/maxMint report 0 for everyone but the queue; max for the queue when healthy
    function test_VaultGate_MaxDepositMaxMint() public {
        assertEq(vault.maxDeposit(user), 0);
        assertEq(vault.maxMint(user), 0);
        assertEq(vault.maxDeposit(address(queue)), type(uint256).max);
        assertEq(vault.maxMint(address(queue)), type(uint256).max);

        // Unhealthy (paused) -> 0 even for the queue
        vm.prank(manager);
        aggregator.pauseStrategy(address(strategy));
        assertEq(vault.maxDeposit(address(queue)), 0);
        assertEq(vault.maxMint(address(queue)), 0);
    }
}
