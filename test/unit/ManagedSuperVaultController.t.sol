// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { ManagedSuperVaultEscrow } from "../../src/ManagedSuperVault/ManagedSuperVaultEscrow.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultController } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

contract ManagedSuperVaultControllerTest is ManagedSuperVaultTestBase {
    address internal custodian;

    function setUp() public override {
        super.setUp();
        custodian = makeAddr("custodian");
    }

    /*//////////////////////////////////////////////////////////////
                        APPROVALS / ALLOWLIST
    //////////////////////////////////////////////////////////////*/

    function _allowlistVault() internal returns (ManagedSuperVault v, ManagedSuperVaultController c) {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.depositPolicy.approvalMode = IManagedSuperVaultController.DepositApprovalMode.Allowlist;
        (address vault_, address controller_,) = _createManagedVault(params);
        return (ManagedSuperVault(vault_), ManagedSuperVaultController(payable(controller_)));
    }

    function test_allowlistMode_blocksUnapprovedDeposits() public {
        (ManagedSuperVault v, ManagedSuperVaultController c) = _allowlistVault();

        vm.startPrank(user);
        asset.approve(address(v), 100e18);
        vm.expectRevert(IManagedSuperVaultController.DEPOSITOR_NOT_APPROVED.selector);
        v.requestDeposit(100e18, user, user);
        vm.stopPrank();

        // Approve and retry
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        bytes32[] memory refs = new bytes32[](1);
        refs[0] = keccak256("kyc-ref");
        vm.prank(manager);
        c.approveDepositors(depositors, refs);

        assertEq(uint8(c.getApprovalStatus(user)), uint8(IManagedSuperVaultController.ApprovalStatus.Approved));
        assertEq(c.getKycRef(user), keccak256("kyc-ref"));

        vm.prank(user);
        v.requestDeposit(100e18, user, user);
        assertEq(c.pendingDepositRequest(user), 100e18);

        // Revoke blocks further requests
        vm.prank(manager);
        c.revokeDepositors(depositors);

        vm.startPrank(user);
        asset.approve(address(v), 1e18);
        vm.expectRevert(IManagedSuperVaultController.DEPOSITOR_NOT_APPROVED.selector);
        v.requestDeposit(1e18, user, user);
        vm.stopPrank();
    }

    function test_requestApproval_auditTrail() public {
        (, ManagedSuperVaultController c) = _allowlistVault();

        vm.prank(user);
        c.requestApproval();
        assertEq(uint8(c.getApprovalStatus(user)), uint8(IManagedSuperVaultController.ApprovalStatus.Requested));

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        c.rejectDepositors(depositors);
        assertEq(uint8(c.getApprovalStatus(user)), uint8(IManagedSuperVaultController.ApprovalStatus.Rejected));
    }

    function test_approvals_managerGated() public {
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        bytes32[] memory refs = new bytes32[](1);

        vm.expectRevert(IManagedSuperVaultController.MANAGER_NOT_AUTHORIZED.selector);
        vm.prank(user);
        controller.approveDepositors(depositors, refs);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT POLICY
    //////////////////////////////////////////////////////////////*/

    function test_depositPolicy_minAndCaps() public {
        IManagedSuperVaultController.DepositPolicy memory policy = controller.getDepositPolicy();
        policy.minDepositAssets = 10e18;
        policy.maxDepositAssets = 150e18; // per-wallet cumulative cap
        policy.totalDepositCap = 200e18;

        vm.prank(manager);
        controller.setDepositPolicy(policy);

        vm.startPrank(user);
        asset.approve(address(vault), type(uint256).max);

        vm.expectRevert(IManagedSuperVaultController.DEPOSIT_BELOW_MINIMUM.selector);
        vault.requestDeposit(9e18, user, user);

        vault.requestDeposit(100e18, user, user);

        vm.expectRevert(IManagedSuperVaultController.DEPOSIT_WALLET_CAP_EXCEEDED.selector);
        vault.requestDeposit(51e18, user, user);

        vault.requestDeposit(50e18, user, user);
        vm.stopPrank();

        // Total cap: user has 150, user2 can only add 50
        vm.startPrank(user2);
        asset.approve(address(vault), type(uint256).max);
        vm.expectRevert(IManagedSuperVaultController.DEPOSIT_TOTAL_CAP_EXCEEDED.selector);
        vault.requestDeposit(51e18, user2, user2);

        vault.requestDeposit(50e18, user2, user2);
        vm.stopPrank();
    }

    function test_depositPolicy_pausedAndWindow() public {
        IManagedSuperVaultController.DepositPolicy memory policy = controller.getDepositPolicy();
        policy.depositsPaused = true;
        vm.prank(manager);
        controller.setDepositPolicy(policy);

        vm.startPrank(user);
        asset.approve(address(vault), type(uint256).max);
        vm.expectRevert(IManagedSuperVaultController.DEPOSITS_PAUSED.selector);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        // Subscription window in the future
        policy.depositsPaused = false;
        policy.subscriptionWindowStart = block.timestamp + 1 days;
        vm.prank(manager);
        controller.setDepositPolicy(policy);

        vm.prank(user);
        vm.expectRevert(IManagedSuperVaultController.SUBSCRIPTION_WINDOW_CLOSED.selector);
        vault.requestDeposit(100e18, user, user);

        vm.warp(block.timestamp + 1 days);
        vm.prank(user);
        vault.requestDeposit(100e18, user, user);
    }

    function test_rejectDepositRequests_refundsDepositor() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        uint256 balanceBefore = asset.balanceOf(user);

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        controller.rejectDepositRequests(depositors, "kyc failed");

        assertEq(asset.balanceOf(user), balanceBefore + 100e18);
        assertEq(controller.pendingDepositRequest(user), 0);
        assertEq(controller.totalPendingDepositAssets(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        NAV MODULE
    //////////////////////////////////////////////////////////////*/

    function test_proposeNAV_validations() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);

        vm.startPrank(manager);
        vm.expectRevert(IManagedSuperVaultController.INVALID_PPS.selector);
        controller.proposeNAVUpdate(0, block.timestamp, EVIDENCE_HASH, "");

        vm.expectRevert(IManagedSuperVaultController.EVIDENCE_REQUIRED.selector);
        controller.proposeNAVUpdate(1.01e18, block.timestamp, bytes32(0), "");

        vm.expectRevert(IManagedSuperVaultController.INVALID_TIMESTAMP.selector);
        controller.proposeNAVUpdate(1.01e18, block.timestamp + 1, EVIDENCE_HASH, "");

        uint256 proposalId = controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");
        assertEq(controller.getActiveNAVProposalId(), proposalId);

        // Second concurrent proposal blocked
        vm.expectRevert(IManagedSuperVaultController.NAV_PROPOSAL_PENDING.selector);
        controller.proposeNAVUpdate(1.02e18, block.timestamp, EVIDENCE_HASH, "");
        vm.stopPrank();

        // Non-manager cannot propose
        vm.expectRevert(IManagedSuperVaultController.MANAGER_NOT_AUTHORIZED.selector);
        vm.prank(user);
        controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");
    }

    function test_attestNAV_gating() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");

        // Non-attestor cannot attest (not even the manager)
        vm.expectRevert(IManagedSuperVaultController.NOT_NAV_ATTESTOR.selector);
        vm.prank(manager);
        controller.attestNAVUpdate(proposalId);

        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);

        assertEq(controller.getStoredPPS(), 1.01e18);
        assertEq(controller.getActiveNAVProposalId(), 0);

        // Cannot re-attest a finalized proposal
        vm.expectRevert(IManagedSuperVaultController.NAV_PROPOSAL_NOT_PENDING.selector);
        vm.prank(attestor2);
        controller.attestNAVUpdate(proposalId);
    }

    function test_attestNAV_proposerCannotSelfAttest() public {
        // Make attestor also a manager so it can propose
        vm.prank(manager);
        aggregator.addSecondaryManager(address(controller), attestor);

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(attestor);
        uint256 proposalId = controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.expectRevert(IManagedSuperVaultController.ATTESTOR_CANNOT_BE_PROPOSER.selector);
        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);

        // Independent attestor finalizes
        vm.prank(attestor2);
        controller.attestNAVUpdate(proposalId);
        assertEq(controller.getStoredPPS(), 1.01e18);
    }

    function test_attestNAV_thresholdTwo() public {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.navConfig.threshold = 2;
        (, address controller_,) = _createManagedVault(params);
        ManagedSuperVaultController c = ManagedSuperVaultController(payable(controller_));

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = c.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.prank(attestor);
        c.attestNAVUpdate(proposalId);

        // Still pending at 1/2 attestations
        assertEq(c.getStoredPPS(), 1e18);
        assertEq(
            uint8(c.getNAVProposal(proposalId).status),
            uint8(IManagedSuperVaultController.NAVProposalStatus.PendingAttestation)
        );

        vm.expectRevert(IManagedSuperVaultController.ALREADY_ATTESTED.selector);
        vm.prank(attestor);
        c.attestNAVUpdate(proposalId);

        vm.prank(attestor2);
        c.attestNAVUpdate(proposalId);
        assertEq(c.getStoredPPS(), 1.01e18);
    }

    function test_navProposal_expiry() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.warp(block.timestamp + 1 days + 1);

        vm.expectRevert(IManagedSuperVaultController.NAV_PROPOSAL_EXPIRED.selector);
        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);

        // Expired proposal is auto-canceled by a fresh proposal
        vm.prank(manager);
        uint256 newId = controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");
        assertEq(controller.getActiveNAVProposalId(), newId);
        assertEq(
            uint8(controller.getNAVProposal(proposalId).status),
            uint8(IManagedSuperVaultController.NAVProposalStatus.Canceled)
        );
    }

    function test_cancelNAVUpdate() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.prank(secondaryManager);
        controller.cancelNAVUpdate(proposalId);
        assertEq(controller.getActiveNAVProposalId(), 0);
    }

    function test_attestorManagement() public {
        address newAttestor = makeAddr("newAttestor");

        vm.expectRevert(IManagedSuperVaultController.MANAGER_NOT_AUTHORIZED.selector);
        vm.prank(user);
        controller.addNAVAttestor(newAttestor);

        vm.startPrank(manager);
        controller.addNAVAttestor(newAttestor);
        assertTrue(controller.isNAVAttestor(newAttestor));

        controller.setNAVAttestationThreshold(3);

        // Cannot remove below threshold
        vm.expectRevert(IManagedSuperVaultController.INVALID_ATTESTATION_CONFIG.selector);
        controller.removeNAVAttestor(newAttestor);

        controller.setNAVAttestationThreshold(1);
        controller.removeNAVAttestor(newAttestor);
        assertFalse(controller.isNAVAttestor(newAttestor));

        // Threshold above attestor count rejected
        vm.expectRevert(IManagedSuperVaultController.INVALID_ATTESTATION_CONFIG.selector);
        controller.setNAVAttestationThreshold(3);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        EXECUTION POLICY
    //////////////////////////////////////////////////////////////*/

    function _emptyRule() internal pure returns (IManagedSuperVaultController.CallRule memory rule) {
        rule.allowed = true;
    }

    function _transferRule() internal pure returns (IManagedSuperVaultController.CallRule memory rule) {
        rule.allowed = true;
        rule.constrainedArgs = new uint8[](1);
        rule.constrainedArgs[0] = 0;
    }

    function _fundController(uint256 amount) internal {
        // Deposit round trip so the controller holds operational assets
        _depositRoundTrip(user, amount);
    }

    function test_setCallRule_primaryManagerOnly() public {
        vm.expectRevert(IManagedSuperVaultController.MANAGER_NOT_AUTHORIZED.selector);
        vm.prank(secondaryManager);
        controller.setCallRule(address(asset), MockERC20.mint.selector, _emptyRule());
    }

    function test_setCallRule_sensitiveSelectorRequiresConstraint() public {
        vm.startPrank(manager);
        vm.expectRevert(IManagedSuperVaultController.ARG_CONSTRAINT_REQUIRED.selector);
        controller.setCallRule(address(asset), asset.transfer.selector, _emptyRule());

        // With the recipient arg constrained it works
        controller.setCallRule(address(asset), asset.transfer.selector, _transferRule());
        vm.stopPrank();
    }

    function test_setCallRule_forbiddenTargets() public {
        vm.startPrank(manager);
        vm.expectRevert(IManagedSuperVaultController.TARGET_FORBIDDEN.selector);
        controller.setCallRule(address(vault), bytes4(0), _emptyRule());
        vm.expectRevert(IManagedSuperVaultController.TARGET_FORBIDDEN.selector);
        controller.setCallRule(address(controller), bytes4(0), _emptyRule());
        vm.expectRevert(IManagedSuperVaultController.TARGET_FORBIDDEN.selector);
        controller.setCallRule(address(escrow), bytes4(0), _emptyRule());
        vm.expectRevert(IManagedSuperVaultController.TARGET_FORBIDDEN.selector);
        controller.setCallRule(address(aggregator), bytes4(0), _emptyRule());
        vm.expectRevert(IManagedSuperVaultController.TARGET_FORBIDDEN.selector);
        controller.setCallRule(address(superGovernor), bytes4(0), _emptyRule());
        vm.stopPrank();
    }

    function test_executeManagedCall_allowlistAndArgConstraints() public {
        _fundController(100e18);

        // Policy: transfer on the asset, recipient constrained to custodian
        vm.startPrank(manager);
        controller.setCallRule(address(asset), asset.transfer.selector, _transferRule());
        address[] memory allowedValues = new address[](1);
        allowedValues[0] = custodian;
        controller.setArgAllowedValues(address(asset), asset.transfer.selector, 0, allowedValues, true);
        vm.stopPrank();

        // Transfer to a non-allowlisted recipient reverts
        IManagedSuperVaultController.ManagedCall memory badCall = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (user2, 10e18))
        });
        vm.expectRevert(IManagedSuperVaultController.ARG_CONSTRAINT_VIOLATED.selector);
        vm.prank(manager);
        controller.executeManagedCall(badCall, keccak256("op-1"));

        // Transfer to custodian passes
        IManagedSuperVaultController.ManagedCall memory goodCall = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 10e18))
        });
        vm.prank(manager);
        controller.executeManagedCall(goodCall, keccak256("op-2"));
        assertEq(asset.balanceOf(custodian), 10e18);
    }

    function test_executeManagedCall_disallowedSelectorAndTarget() public {
        _fundController(100e18);

        // No rule at all
        IManagedSuperVaultController.ManagedCall memory call_ = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 10e18))
        });
        vm.expectRevert(IManagedSuperVaultController.CALL_NOT_ALLOWED.selector);
        vm.prank(manager);
        controller.executeManagedCall(call_, keccak256("op-1"));

        // Forbidden target blocked even without a rule
        IManagedSuperVaultController.ManagedCall memory forbidden = IManagedSuperVaultController.ManagedCall({
            target: address(vault), value: 0, data: abi.encodeCall(ManagedSuperVault.burnShares, (1))
        });
        vm.expectRevert(IManagedSuperVaultController.TARGET_FORBIDDEN.selector);
        vm.prank(manager);
        controller.executeManagedCall(forbidden, keccak256("op-2"));
    }

    function test_executeManagedCall_operationIdReplay() public {
        _fundController(100e18);

        vm.startPrank(manager);
        controller.setCallRule(address(asset), asset.transfer.selector, _transferRule());
        address[] memory allowedValues = new address[](1);
        allowedValues[0] = custodian;
        controller.setArgAllowedValues(address(asset), asset.transfer.selector, 0, allowedValues, true);

        IManagedSuperVaultController.ManagedCall memory call_ = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 1e18))
        });

        controller.executeManagedCall(call_, keccak256("op-1"));

        vm.expectRevert(IManagedSuperVaultController.OPERATION_ID_USED.selector);
        controller.executeManagedCall(call_, keccak256("op-1"));

        vm.expectRevert(IManagedSuperVaultController.INVALID_OPERATION_ID.selector);
        controller.executeManagedCall(call_, bytes32(0));
        vm.stopPrank();
    }

    function test_executeManagedCall_valueCaps() public {
        vm.deal(address(controller), 100 ether);
        address payable sink = payable(makeAddr("ethSink"));

        // Plain ETH transfer = selector 0
        IManagedSuperVaultController.CallRule memory rule;
        rule.allowed = true;
        rule.valueAllowed = true;
        rule.maxValuePerCall = 1 ether;
        rule.windowValueCap = 2 ether;
        rule.windowDuration = 1 days;

        vm.prank(manager);
        controller.setCallRule(sink, bytes4(0), rule);

        IManagedSuperVaultController.ManagedCall memory call_ =
            IManagedSuperVaultController.ManagedCall({ target: sink, value: 1.5 ether, data: "" });

        // Per-call cap
        vm.expectRevert(IManagedSuperVaultController.VALUE_EXCEEDS_CAP.selector);
        vm.prank(manager);
        controller.executeManagedCall(call_, keccak256("op-1"));

        // Windowed cumulative cap: 1 + 1 fills the window, third call breaches
        call_.value = 1 ether;
        vm.startPrank(manager);
        controller.executeManagedCall(call_, keccak256("op-2"));
        controller.executeManagedCall(call_, keccak256("op-3"));

        vm.expectRevert(IManagedSuperVaultController.VALUE_EXCEEDS_WINDOW_CAP.selector);
        controller.executeManagedCall(call_, keccak256("op-4"));

        // Window rolls over
        vm.warp(block.timestamp + 1 days + 1);
        controller.executeManagedCall(call_, keccak256("op-5"));
        vm.stopPrank();

        assertEq(sink.balance, 3 ether);

        // Value on a rule without valueAllowed reverts
        IManagedSuperVaultController.CallRule memory noValueRule;
        noValueRule.allowed = true;
        address sink2 = makeAddr("ethSink2");
        vm.prank(manager);
        controller.setCallRule(sink2, bytes4(0), noValueRule);

        IManagedSuperVaultController.ManagedCall memory noValueCall =
            IManagedSuperVaultController.ManagedCall({ target: sink2, value: 1 ether, data: "" });
        vm.expectRevert(IManagedSuperVaultController.VALUE_NOT_ALLOWED.selector);
        vm.prank(manager);
        controller.executeManagedCall(noValueCall, keccak256("op-6"));
    }

    function test_executeManagedCall_failureBubbles() public {
        // transfer of more than the controller balance -> ERC20 revert wrapped in EXECUTION_FAILED
        vm.startPrank(manager);
        controller.setCallRule(address(asset), asset.transfer.selector, _transferRule());
        address[] memory allowedValues = new address[](1);
        allowedValues[0] = custodian;
        controller.setArgAllowedValues(address(asset), asset.transfer.selector, 0, allowedValues, true);

        IManagedSuperVaultController.ManagedCall memory call_ = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 1e18))
        });

        vm.expectPartialRevert(IManagedSuperVaultController.EXECUTION_FAILED.selector);
        controller.executeManagedCall(call_, keccak256("op-1"));
        vm.stopPrank();
    }

    function test_executeManagedBatch() public {
        _fundController(100e18);

        vm.startPrank(manager);
        controller.setCallRule(address(asset), asset.transfer.selector, _transferRule());
        address[] memory allowedValues = new address[](1);
        allowedValues[0] = custodian;
        controller.setArgAllowedValues(address(asset), asset.transfer.selector, 0, allowedValues, true);

        IManagedSuperVaultController.ManagedCall[] memory calls = new IManagedSuperVaultController.ManagedCall[](2);
        calls[0] = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 1e18))
        });
        calls[1] = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 2e18))
        });

        controller.executeManagedBatch(calls, keccak256("batch-1"));
        vm.stopPrank();

        assertEq(asset.balanceOf(custodian), 3e18);
    }

    /*//////////////////////////////////////////////////////////////
                            FEES
    //////////////////////////////////////////////////////////////*/

    function test_managementFee_onDepositFulfillment() public {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.feeConfig.managementFeeBps = 100; // 1% entry fee
        (address vault_, address controller_,) = _createManagedVault(params);
        ManagedSuperVault v = ManagedSuperVault(vault_);
        ManagedSuperVaultController c = ManagedSuperVaultController(payable(controller_));

        vm.startPrank(user);
        asset.approve(vault_, 100e18);
        v.requestDeposit(100e18, user, user);
        vm.stopPrank();

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        c.fulfillDepositRequests(depositors);

        assertEq(asset.balanceOf(feeRecipient), 1e18);
        assertEq(c.claimableDepositRequest(user), 99e18);
        assertEq(asset.balanceOf(controller_), 99e18);
    }

    function test_performanceFeeSkim() public {
        _depositRoundTrip(user, 100e18);

        // NAV appreciates 10%
        _updateNAV(1.1e18);

        uint256 treasuryBefore = asset.balanceOf(treasury);
        uint256 recipientBefore = asset.balanceOf(feeRecipient);

        vm.prank(manager);
        controller.skimPerformanceFee();

        // profit = 0.1 * 100 = 10; perf fee 10% = 1; split 50/50 with treasury
        assertEq(asset.balanceOf(treasury), treasuryBefore + 0.5e18);
        assertEq(asset.balanceOf(feeRecipient), recipientBefore + 0.5e18);

        // PPS reduced by fee / supply = 0.01
        assertEq(controller.getStoredPPS(), 1.09e18);
        assertEq(controller.vaultHwmPps(), 1.09e18);
    }

    function test_skim_postUnpauseTimelock() public {
        _depositRoundTrip(user, 100e18);
        _updateNAV(1.1e18);

        vm.startPrank(manager);
        aggregator.pauseManagedVault(address(controller));
        aggregator.unpauseManagedVault(address(controller));
        vm.stopPrank();

        // NAV is stale after unpause; a fresh update is required first
        _updateNAV(1.1e18 + 1);

        vm.expectRevert(IManagedSuperVaultController.SKIM_TIMELOCK_ACTIVE.selector);
        vm.prank(manager);
        controller.skimPerformanceFee();

        vm.warp(block.timestamp + 12 hours);
        vm.prank(manager);
        controller.skimPerformanceFee();
    }
}
