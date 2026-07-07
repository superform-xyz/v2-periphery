// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../../../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { ManagedSuperVaultEscrow } from "../../../src/ManagedSuperVault/ManagedSuperVaultEscrow.sol";
import {
    IManagedSuperVaultAggregator
} from "../../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import {
    IManagedSuperVaultController
} from "../../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";

/// @notice Full Managed Vault lifecycle: partner-gated subscriptions, whitelisted execution to an
///         offchain custodian, attested NAV appreciation, fee skim, and batch redemption settlement.
contract ManagedSuperVaultIntegrationTest is ManagedSuperVaultTestBase {
    ManagedSuperVault internal mVault;
    ManagedSuperVaultController internal mController;
    ManagedSuperVaultEscrow internal mEscrow;

    address internal custodian;

    function setUp() public override {
        super.setUp();
        custodian = makeAddr("custodian");

        // Allowlist-gated vault with entry fee and 10% performance fee
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.depositPolicy.approvalMode = IManagedSuperVaultController.DepositApprovalMode.KycApproved;
        params.feeConfig.managementFeeBps = 50; // 0.5% entry fee

        (address vault_, address controller_, address escrow_) = _createManagedVault(params);
        mVault = ManagedSuperVault(vault_);
        mController = ManagedSuperVaultController(payable(controller_));
        mEscrow = ManagedSuperVaultEscrow(escrow_);
    }

    function test_fullLifecycle() public {
        // ---------- 1. Subscription: KYC approval gating ----------
        vm.prank(user);
        mController.requestApproval();
        vm.prank(user2);
        mController.requestApproval();

        address[] memory depositors = new address[](2);
        depositors[0] = user;
        depositors[1] = user2;
        bytes32[] memory kycRefs = new bytes32[](2);
        kycRefs[0] = keccak256("kyc-user");
        kycRefs[1] = keccak256("kyc-user2");
        vm.prank(manager);
        mController.approveDepositors(depositors, kycRefs);

        // ---------- 2. Async deposit requests ----------
        vm.startPrank(user);
        asset.approve(address(mVault), 200_000e18);
        mVault.requestDeposit(200_000e18, user, user);
        vm.stopPrank();

        vm.startPrank(user2);
        asset.approve(address(mVault), 100_000e18);
        mVault.requestDeposit(100_000e18, user2, user2);
        vm.stopPrank();

        assertEq(asset.balanceOf(address(mEscrow)), 300_000e18);

        // ---------- 3. Manager fulfills; entry fee skimmed; users claim shares ----------
        vm.prank(manager);
        mController.fulfillDepositRequests(depositors);

        // 0.5% entry fee on 300k = 1500
        assertEq(asset.balanceOf(feeRecipient), 1500e18);

        uint256 claimableUser = mVault.maxDeposit(user);
        uint256 claimableUser2 = mVault.maxDeposit(user2);
        vm.prank(user);
        uint256 sharesUser = mVault.deposit(claimableUser, user, user);
        vm.prank(user2);
        uint256 sharesUser2 = mVault.deposit(claimableUser2, user2, user2);

        assertEq(sharesUser, 199_000e18);
        assertEq(sharesUser2, 99_500e18);

        // ---------- 4. Whitelisted execution: move capital to the custodian ----------
        IManagedSuperVaultController.CallRule memory rule;
        rule.allowed = true;
        rule.constrainedArgs = new uint8[](1);
        rule.constrainedArgs[0] = 0;

        vm.startPrank(manager);
        mController.setCallRule(address(asset), asset.transfer.selector, rule);
        address[] memory allowed = new address[](1);
        allowed[0] = custodian;
        mController.setArgAllowedValues(address(asset), asset.transfer.selector, 0, allowed, true);

        mController.executeManagedCall(
            IManagedSuperVaultController.ManagedCall({
                target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 298_500e18))
            }),
            keccak256("deploy-to-custodian")
        );
        vm.stopPrank();

        assertEq(asset.balanceOf(custodian), 298_500e18);
        assertEq(asset.balanceOf(address(mController)), 0);

        // ---------- 5. Offchain strategy gains 10%; capital returns; NAV attested up ----------
        asset.mint(custodian, 29_850e18); // +10% offchain gains
        vm.prank(custodian);
        asset.transfer(address(mController), 328_350e18);

        // Manager proposes NAV = 1.10; independent attestor finalizes
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = mController.proposeNAVUpdate(1.1e18, block.timestamp, EVIDENCE_HASH, "ipfs://q2-nav");
        vm.prank(attestor);
        mController.attestNAVUpdate(proposalId);
        assertEq(mController.getStoredPPS(), 1.1e18);

        // ---------- 6. Performance fee skim ----------
        vm.prank(manager);
        mController.skimPerformanceFee();

        // profit = 0.1 * 298,500 = 29,850; 10% fee = 2,985 split 50/50 treasury/recipient
        assertEq(asset.balanceOf(treasury), 1492.5e18);
        uint256 postSkimPPS = mController.getStoredPPS();
        assertEq(postSkimPPS, 1.09e18); // 1.10 - 2985/298500

        // ---------- 7. Async redemption: user redeems half ----------
        uint256 redeemShares = sharesUser / 2;
        vm.prank(user);
        mVault.requestRedeem(redeemShares, user, user);

        (, uint256 theoreticalAssets,) = mController.previewExactRedeem(user);

        address[] memory redeemers = new address[](1);
        redeemers[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = theoreticalAssets;

        vm.prank(manager);
        mController.fulfillRedeemRequests(redeemers, amounts);

        uint256 userAssetsBefore = asset.balanceOf(user);
        uint256 claimable = mVault.maxWithdraw(user);
        vm.prank(user);
        mVault.withdraw(claimable, user, user);

        // 99,500 shares at post-skim PPS 1.09
        assertEq(asset.balanceOf(user) - userAssetsBefore, redeemShares * postSkimPPS / 1e18);
        assertEq(mVault.balanceOf(user), sharesUser - redeemShares);

        // ---------- 8. Audit surface sanity ----------
        assertEq(mVault.totalSupply(), sharesUser - redeemShares + sharesUser2);
        assertEq(aggregator.getMetadataURI(address(mController)), "ipfs://managed-vault-metadata");
        assertTrue(mController.isOperationIdUsed(keccak256("deploy-to-custodian")));
    }

    function test_largeDeviationLifecycle() public {
        // Seed the vault
        vm.prank(user);
        mController.requestApproval();
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        bytes32[] memory kycRefs = new bytes32[](1);
        vm.prank(manager);
        mController.approveDepositors(depositors, kycRefs);

        vm.startPrank(user);
        asset.approve(address(mVault), 100e18);
        mVault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        vm.prank(manager);
        mController.fulfillDepositRequests(depositors);

        // Manager proposes a 2x NAV (exceeds 50% deviation bound); attestation trips review + pause
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = mController.proposeNAVUpdate(2e18, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        mController.attestNAVUpdate(proposalId);

        assertTrue(aggregator.isManagedVaultPaused(address(mController)));
        assertEq(mController.getStoredPPS(), 1e18); // value dropped

        // NAV-sensitive operations are blocked while paused/stale
        vm.startPrank(user);
        asset.approve(address(mVault), 1e18);
        vm.expectRevert(IManagedSuperVaultController.MANAGED_VAULT_PAUSED.selector);
        mVault.requestDeposit(1e18, user, user);
        vm.stopPrank();

        // Explicit unpause, then the elevated resolve finalizes the attested large-deviation NAV
        vm.prank(manager);
        aggregator.unpauseManagedVault(address(mController));

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        mController.resolveLargeDeviationNAV(proposalId);

        assertEq(mController.getStoredPPS(), 2e18);
        assertFalse(aggregator.isNAVStale(address(mController)));
    }
}
