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

    function test_rejectDepositors_setsStatus() public {
        (, ManagedSuperVaultController c) = _allowlistVault();

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

    function test_depositPolicy_minAndMax() public {
        IManagedSuperVaultController.DepositPolicy memory policy = controller.getDepositPolicy();
        policy.minDepositAssets = 10e18;
        policy.maxDepositAssets = 150e18; // per-request max

        vm.prank(manager);
        controller.setDepositPolicy(policy);

        vm.startPrank(user);
        asset.approve(address(vault), type(uint256).max);

        vm.expectRevert(IManagedSuperVaultController.DEPOSIT_BELOW_MINIMUM.selector);
        vault.requestDeposit(9e18, user, user);

        vm.expectRevert(IManagedSuperVaultController.DEPOSIT_ABOVE_MAXIMUM.selector);
        vault.requestDeposit(151e18, user, user);

        // Within [min, max] passes; the cap is per-request, so a second request is independent
        vault.requestDeposit(150e18, user, user);
        vault.requestDeposit(150e18, user, user);
        assertEq(controller.pendingDepositRequest(user), 300e18);
        vm.stopPrank();
    }

    function test_depositPolicy_paused() public {
        IManagedSuperVaultController.DepositPolicy memory policy = controller.getDepositPolicy();
        policy.depositsPaused = true;
        vm.prank(manager);
        controller.setDepositPolicy(policy);

        vm.startPrank(user);
        asset.approve(address(vault), type(uint256).max);
        vm.expectRevert(IManagedSuperVaultController.DEPOSITS_PAUSED.selector);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        policy.depositsPaused = false;
        vm.prank(manager);
        controller.setDepositPolicy(policy);

        vm.prank(user);
        vault.requestDeposit(100e18, user, user);
        assertEq(controller.pendingDepositRequest(user), 100e18);
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
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_NAV.selector);
        aggregator.proposeNAVUpdate(address(controller), 0, block.timestamp, EVIDENCE_HASH, "");

        vm.expectRevert(IManagedSuperVaultAggregator.EVIDENCE_REQUIRED.selector);
        aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, bytes32(0), "");

        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_TIMESTAMP.selector);
        aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp + 1, EVIDENCE_HASH, "");

        uint256 proposalId =
            aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, EVIDENCE_HASH, "");
        assertEq(aggregator.getActiveNAVProposalId(address(controller)), proposalId);

        // Second concurrent proposal blocked
        vm.expectRevert(IManagedSuperVaultAggregator.NAV_PROPOSAL_PENDING.selector);
        aggregator.proposeNAVUpdate(address(controller), 1.02e18, block.timestamp, EVIDENCE_HASH, "");
        vm.stopPrank();

        // Non-manager cannot propose
        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(user);
        aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, EVIDENCE_HASH, "");
    }

    function test_attestNAV_gating() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId =
            aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, EVIDENCE_HASH, "");

        // Non-attestor cannot attest (not even the manager)
        vm.expectRevert(IManagedSuperVaultAggregator.NOT_NAV_ATTESTOR.selector);
        vm.prank(manager);
        aggregator.attestNAVUpdate(address(controller), proposalId);

        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(controller), proposalId);

        assertEq(controller.getStoredPPS(), 1.01e18);
        assertEq(aggregator.getActiveNAVProposalId(address(controller)), 0);

        // Cannot re-attest a finalized proposal
        vm.expectRevert(IManagedSuperVaultAggregator.NAV_PROPOSAL_NOT_PENDING.selector);
        vm.prank(attestor2);
        aggregator.attestNAVUpdate(address(controller), proposalId);
    }

    function test_attestNAV_proposerCannotSelfAttest() public {
        // Make attestor also a manager so it can propose
        vm.prank(manager);
        aggregator.addSecondaryManager(address(controller), attestor);

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(attestor);
        uint256 proposalId =
            aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.expectRevert(IManagedSuperVaultAggregator.ATTESTOR_CANNOT_BE_PROPOSER.selector);
        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(controller), proposalId);

        // Independent attestor finalizes
        vm.prank(attestor2);
        aggregator.attestNAVUpdate(address(controller), proposalId);
        assertEq(controller.getStoredPPS(), 1.01e18);
    }

    function test_attestNAV_thresholdTwo() public {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.navConfig.threshold = 2;
        (, address controller_,) = _createManagedVault(params);
        ManagedSuperVaultController c = ManagedSuperVaultController(payable(controller_));

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = aggregator.proposeNAVUpdate(address(c), 1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(c), proposalId);

        // Still pending at 1/2 attestations
        assertEq(c.getStoredPPS(), 1e18);
        assertEq(
            uint8(aggregator.getNAVProposal(address(c), proposalId).status),
            uint8(IManagedSuperVaultController.NAVProposalStatus.PendingAttestation)
        );

        vm.expectRevert(IManagedSuperVaultAggregator.ALREADY_ATTESTED.selector);
        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(c), proposalId);

        vm.prank(attestor2);
        aggregator.attestNAVUpdate(address(c), proposalId);
        assertEq(c.getStoredPPS(), 1.01e18);
    }

    function test_navProposal_oneActiveAtATime() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId =
            aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, EVIDENCE_HASH, "");

        // A second proposal is blocked while one is active; must cancel first
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.NAV_PROPOSAL_PENDING.selector);
        aggregator.proposeNAVUpdate(address(controller), 1.02e18, block.timestamp, EVIDENCE_HASH, "");

        vm.prank(manager);
        aggregator.cancelNAVUpdate(address(controller), proposalId);

        vm.prank(manager);
        uint256 newId = aggregator.proposeNAVUpdate(address(controller), 1.02e18, block.timestamp, EVIDENCE_HASH, "");
        assertEq(aggregator.getActiveNAVProposalId(address(controller)), newId);
    }

    function test_cancelNAVUpdate() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId =
            aggregator.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.prank(secondaryManager);
        aggregator.cancelNAVUpdate(address(controller), proposalId);
        assertEq(aggregator.getActiveNAVProposalId(address(controller)), 0);
    }

    function test_attestationConfig_timelocked() public {
        address newAttestor = makeAddr("newAttestor");
        address newAttestor2 = makeAddr("newAttestor2");

        address[] memory proposed = new address[](2);
        proposed[0] = newAttestor;
        proposed[1] = newAttestor2;

        // Only the primary manager can propose
        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(user);
        aggregator.proposeNAVAttestationConfig(address(controller), proposed, 2);

        // Threshold above set size rejected
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_ATTESTATION_CONFIG.selector);
        vm.prank(manager);
        aggregator.proposeNAVAttestationConfig(address(controller), proposed, 3);

        vm.prank(manager);
        aggregator.proposeNAVAttestationConfig(address(controller), proposed, 2);

        // Cannot execute before the timelock
        vm.expectRevert(IManagedSuperVaultAggregator.NAV_CONFIG_TIMELOCK_NOT_EXPIRED.selector);
        vm.prank(manager);
        aggregator.executeNAVAttestationConfig(address(controller));

        // Old attestor set is still in force until execution
        assertTrue(aggregator.isNAVAttestor(address(controller), attestor));
        assertFalse(aggregator.isNAVAttestor(address(controller), newAttestor));

        vm.warp(block.timestamp + 3 days);
        vm.prank(manager);
        aggregator.executeNAVAttestationConfig(address(controller));

        // New set installed, old set removed
        assertTrue(aggregator.isNAVAttestor(address(controller), newAttestor));
        assertTrue(aggregator.isNAVAttestor(address(controller), newAttestor2));
        assertFalse(aggregator.isNAVAttestor(address(controller), attestor));
        assertFalse(aggregator.isNAVAttestor(address(controller), attestor2));

        (address[] memory attestors, uint8 threshold) = aggregator.getNAVAttestationConfig(address(controller));
        assertEq(attestors.length, 2);
        assertEq(threshold, 2);
    }

    function test_attestationConfig_cancel() public {
        address[] memory proposed = new address[](1);
        proposed[0] = makeAddr("newAttestor");

        vm.prank(manager);
        aggregator.proposeNAVAttestationConfig(address(controller), proposed, 1);

        (,, uint256 eff) = aggregator.getPendingNAVAttestationConfig(address(controller));
        assertGt(eff, 0);

        vm.prank(manager);
        aggregator.cancelNAVAttestationConfig(address(controller));

        (,, uint256 effAfter) = aggregator.getPendingNAVAttestationConfig(address(controller));
        assertEq(effAfter, 0);
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

    /// @notice Regression: re-applying (or removing + re-adding) a rule must NOT reset the rolling
    ///         window usage, else the manager could zero the value cap on demand.
    function test_setCallRule_doesNotResetWindowUsage() public {
        vm.deal(address(controller), 100 ether);
        address payable sink = payable(makeAddr("windowSink"));

        IManagedSuperVaultController.CallRule memory rule;
        rule.allowed = true;
        rule.valueAllowed = true;
        rule.maxValuePerCall = 1 ether;
        rule.windowValueCap = 2 ether;
        rule.windowDuration = 1 days;

        vm.startPrank(manager);
        controller.setCallRule(sink, bytes4(0), rule);

        IManagedSuperVaultController.ManagedCall memory call_ =
            IManagedSuperVaultController.ManagedCall({ target: sink, value: 1 ether, data: "" });
        controller.executeManagedCall(call_, keccak256("w-1"));
        controller.executeManagedCall(call_, keccak256("w-2")); // window now full (2 ether)

        // Re-applying the same rule must not zero the counter...
        controller.setCallRule(sink, bytes4(0), rule);
        vm.expectRevert(IManagedSuperVaultController.VALUE_EXCEEDS_WINDOW_CAP.selector);
        controller.executeManagedCall(call_, keccak256("w-3"));

        // ...nor does remove + re-add.
        controller.removeCallRule(sink, bytes4(0));
        controller.setCallRule(sink, bytes4(0), rule);
        vm.expectRevert(IManagedSuperVaultController.VALUE_EXCEEDS_WINDOW_CAP.selector);
        controller.executeManagedCall(call_, keccak256("w-4"));
        vm.stopPrank();

        assertEq(sink.balance, 2 ether);
    }

    /// @notice Fix: a dust request that nets to zero assets/shares is skipped, not reverted, so it
    ///         can't brick the batch — mirroring the zero-pending skip.
    function test_fulfillDepositRequests_skipsDustAndMixed() public {
        // Vault with a management fee so a 1-wei request nets to zero
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.feeConfig.managementFeeBps = 100; // 1%
        (address vault_, address controller_,) = _createManagedVault(params);
        ManagedSuperVault v = ManagedSuperVault(vault_);
        ManagedSuperVaultController c = ManagedSuperVaultController(payable(controller_));

        // user2 places a dust request (1 wei -> fee rounds it to 0 net); user places a real one
        vm.startPrank(user2);
        asset.approve(vault_, 1);
        v.requestDeposit(1, user2, user2);
        vm.stopPrank();

        vm.startPrank(user);
        asset.approve(vault_, 100e18);
        v.requestDeposit(100e18, user, user);
        vm.stopPrank();

        // Mixed batch (dust + real, plus an untouched third) must not revert
        address[] memory depositors = new address[](3);
        depositors[0] = user2; // dust -> skipped
        depositors[1] = user; // real -> fulfilled
        depositors[2] = makeAddr("noRequest"); // zero-pending -> skipped
        vm.prank(manager);
        c.fulfillDepositRequests(depositors);

        // Real request fulfilled; dust stays pending and can still be cancelled/refunded
        assertEq(c.claimableDepositRequest(user), 99e18);
        assertEq(c.pendingDepositRequest(user2), 1);

        vm.prank(user2);
        v.cancelDepositRequest(0, user2);
        assertEq(c.pendingDepositRequest(user2), 0);
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

    /// @notice Fix: a fee skim is blocked while a NAV proposal is in flight, so the skim's timestamp
    ///         bump can't stall the proposal on the monotonicity check at finalize.
    function test_skim_blockedWhileNavProposalPending() public {
        _depositRoundTrip(user, 100e18);
        _updateNAV(1.1e18); // PPS now above HWM, no active proposal

        // Open (but don't finalize) a NAV proposal
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        aggregator.proposeNAVUpdate(address(controller), 1.2e18, block.timestamp, EVIDENCE_HASH, "");

        // Skim is blocked until the proposal is resolved or cancelled
        vm.expectRevert(IManagedSuperVaultAggregator.NAV_PROPOSAL_PENDING.selector);
        vm.prank(manager);
        controller.skimPerformanceFee();

        // Cancel the proposal -> skim works again
        uint256 activeId = aggregator.getActiveNAVProposalId(address(controller));
        vm.prank(manager);
        aggregator.cancelNAVUpdate(address(controller), activeId);
        vm.prank(manager);
        controller.skimPerformanceFee();
    }
}
