// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultController } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { ManagedSuperVaultAggregator } from "../../src/ManagedSuperVault/ManagedSuperVaultAggregator.sol";

contract ManagedSuperVaultAggregatorTest is ManagedSuperVaultTestBase {
    /*//////////////////////////////////////////////////////////////
                            CREATION
    //////////////////////////////////////////////////////////////*/

    function test_createManagedVault_registersTrioAndInitialState() public view {
        assertTrue(aggregator.isManagedVault(address(vault)));
        assertEq(aggregator.getManagedVaultController(address(vault)), address(controller));
        assertEq(aggregator.getManagedVaultEscrow(address(vault)), address(escrow));
        assertEq(aggregator.getManagedVaultsCount(), 1);
        assertEq(aggregator.getCurrentNonce(), 1);

        // Initial PPS is 1.0 scaled by asset decimals
        assertEq(aggregator.getPPS(address(controller)), 1e18);
        assertEq(aggregator.getMainManager(address(controller)), manager);
        assertEq(aggregator.getMinUpdateInterval(address(controller)), MIN_UPDATE_INTERVAL);
        assertEq(aggregator.getMaxStaleness(address(controller)), MAX_STALENESS);
        // Default deviation threshold 50% (1e18 scale)
        assertEq(aggregator.getDeviationThreshold(address(controller)), 5e17);
        assertFalse(aggregator.isManagedVaultPaused(address(controller)));
        assertFalse(aggregator.isNAVStale(address(controller)));

        // Type markers
        assertEq(aggregator.VAULT_TYPE(), "managed_vault");
        assertEq(aggregator.NAV_MODE(), "attested_manual");
        assertEq(controller.navMode(), "attested_manual");
    }

    function test_createManagedVault_revertsOnLowMaxStaleness() public {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.maxStaleness = 299; // below SuperGovernor min staleness (300)
        vm.expectRevert(IManagedSuperVaultAggregator.MAX_STALENESS_TOO_LOW.selector);
        vm.prank(manager);
        aggregator.createManagedVault(params);
    }

    function test_createManagedVault_revertsWithoutAttestors() public {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.navConfig.attestors = new address[](0);
        vm.expectRevert(IManagedSuperVaultController.INVALID_ATTESTATION_CONFIG.selector);
        vm.prank(manager);
        aggregator.createManagedVault(params);
    }

    function test_createManagedVault_convertsDeviationBps() public {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.maxUpdateDeviationBps = 1000; // 10%
        (, address controller_,) = _createManagedVault(params);
        assertEq(aggregator.getDeviationThreshold(controller_), 1e17);
    }

    /*//////////////////////////////////////////////////////////////
                        NAV WRITE PATH
    //////////////////////////////////////////////////////////////*/

    function test_updateManagedNAV_onlyRegisteredController() public {
        vm.expectRevert(IManagedSuperVaultAggregator.UNKNOWN_CONTROLLER.selector);
        aggregator.updateManagedNAV(1e18, block.timestamp, false);
    }

    function test_updateManagedNAV_happyPath() public {
        _updateNAV(1.05e18);
        assertEq(aggregator.getPPS(address(controller)), 1.05e18);
        assertEq(controller.getStoredPPS(), 1.05e18);
    }

    function test_updateManagedNAV_rejectsTooFrequent() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        // Propose with an effective timestamp inside the min interval window
        uint256 badTimestamp = aggregator.getLastUpdateTimestamp(address(controller)) + 1;
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(1.01e18, badTimestamp, EVIDENCE_HASH, "");
        vm.expectRevert(IManagedSuperVaultAggregator.UPDATE_TOO_FREQUENT.selector);
        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);
    }

    function test_updateManagedNAV_deviationAutoPausesAndDropsValue() public {
        uint256 ppsBefore = aggregator.getPPS(address(controller));

        // Propose >50% move
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(2e18, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);

        // Rejected value is not stored; vault paused and NAV stale
        assertEq(aggregator.getPPS(address(controller)), ppsBefore);
        assertTrue(aggregator.isManagedVaultPaused(address(controller)));
        assertTrue(aggregator.isNAVStale(address(controller)));

        IManagedSuperVaultController.NAVUpdateProposal memory proposal = controller.getNAVProposal(proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedSuperVaultController.NAVProposalStatus.ReviewRequired));
    }

    function test_resolveLargeDeviationNAV_afterExplicitUnpause() public {
        // Trigger deviation review
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        uint256 effectiveTs = block.timestamp;
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(2e18, effectiveTs, EVIDENCE_HASH, "");
        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);

        // Cannot resolve while paused
        vm.expectRevert(IManagedSuperVaultController.MANAGED_VAULT_PAUSED.selector);
        vm.prank(manager);
        controller.resolveLargeDeviationNAV(proposalId);

        // Only the primary manager can resolve
        vm.expectRevert(IManagedSuperVaultController.MANAGER_NOT_AUTHORIZED.selector);
        vm.prank(secondaryManager);
        controller.resolveLargeDeviationNAV(proposalId);

        // Explicit unpause (elevated, indexable action); NAV remains stale
        vm.prank(manager);
        aggregator.unpauseManagedVault(address(controller));
        assertTrue(aggregator.isNAVStale(address(controller)));

        // Resolve re-stamps the attested NAV at resolve time; the stale flag bypasses the deviation bound
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        controller.resolveLargeDeviationNAV(proposalId);

        assertEq(aggregator.getPPS(address(controller)), 2e18);
        assertFalse(aggregator.isNAVStale(address(controller)));
        assertEq(controller.getActiveNAVProposalId(), 0);
        assertEq(
            uint8(controller.getNAVProposal(proposalId).status),
            uint8(IManagedSuperVaultController.NAVProposalStatus.Finalized)
        );
    }

    /// @notice Finding 1 regression: a manual pause/unpause must NOT let the manager bypass the
    ///         deviation bound. After unpause the ordinary attest path still trips ReviewRequired on an
    ///         out-of-bound NAV instead of finalizing it.
    function test_manualUnpause_doesNotBypassDeviationBound() public {
        // Manual pause + unpause leaves NAV flagged stale but must not arm a deviation bypass
        vm.startPrank(manager);
        aggregator.pauseManagedVault(address(controller));
        aggregator.unpauseManagedVault(address(controller));
        vm.stopPrank();
        assertTrue(aggregator.isNAVStale(address(controller)));

        // A within-bound update still finalizes normally and clears the stale flag
        _updateNAV(1.2e18);
        assertEq(aggregator.getPPS(address(controller)), 1.2e18);
        assertFalse(aggregator.isNAVStale(address(controller)));

        // Pause/unpause again, then try an out-of-bound (>50%) update via the ordinary path
        vm.startPrank(manager);
        aggregator.pauseManagedVault(address(controller));
        aggregator.unpauseManagedVault(address(controller));
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(3e18, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);

        // The out-of-bound value is dropped and the proposal is flagged for review — NOT finalized
        assertEq(aggregator.getPPS(address(controller)), 1.2e18);
        assertTrue(aggregator.isManagedVaultPaused(address(controller)));
        assertEq(
            uint8(controller.getNAVProposal(proposalId).status),
            uint8(IManagedSuperVaultController.NAVProposalStatus.ReviewRequired)
        );
    }

    function test_deviationThreshold_timelockedAndBounded() public {
        // Cannot disable (0) or exceed 100%
        vm.startPrank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_DEVIATION_THRESHOLD.selector);
        aggregator.proposeDeviationThresholdChange(address(controller), 0);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_DEVIATION_THRESHOLD.selector);
        aggregator.proposeDeviationThresholdChange(address(controller), 1e18 + 1);

        // Valid proposal is timelocked
        aggregator.proposeDeviationThresholdChange(address(controller), 1e17); // 10%
        vm.expectRevert(IManagedSuperVaultAggregator.TIMELOCK_NOT_EXPIRED.selector);
        aggregator.executeDeviationThresholdChange(address(controller));
        vm.stopPrank();

        // Still at the default until executed
        assertEq(aggregator.getDeviationThreshold(address(controller)), 5e17);

        vm.warp(block.timestamp + 3 days);
        aggregator.executeDeviationThresholdChange(address(controller));
        assertEq(aggregator.getDeviationThreshold(address(controller)), 1e17);
    }

    function test_createManagedVault_revertsOnDeviationBpsAboveMax() public {
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.maxUpdateDeviationBps = 10_001; // > 100%
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_DEVIATION_THRESHOLD.selector);
        vm.prank(manager);
        aggregator.createManagedVault(params);
    }

    function test_updateManagedNAV_revertsWhenPaused() public {
        vm.prank(manager);
        aggregator.pauseManagedVault(address(controller));

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 proposalId = controller.proposeNAVUpdate(1.01e18, block.timestamp, EVIDENCE_HASH, "");
        vm.expectRevert(IManagedSuperVaultAggregator.MANAGED_VAULT_PAUSED.selector);
        vm.prank(attestor);
        controller.attestNAVUpdate(proposalId);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function test_pauseUnpause_managerGated() public {
        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(user);
        aggregator.pauseManagedVault(address(controller));

        vm.prank(secondaryManager);
        aggregator.pauseManagedVault(address(controller));
        assertTrue(aggregator.isManagedVaultPaused(address(controller)));
        assertTrue(aggregator.isNAVStale(address(controller)));

        vm.prank(manager);
        aggregator.unpauseManagedVault(address(controller));
        assertFalse(aggregator.isManagedVaultPaused(address(controller)));
        // NAV remains stale until fresh update
        assertTrue(aggregator.isNAVStale(address(controller)));
        assertEq(aggregator.getLastUnpauseTimestamp(address(controller)), block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function test_secondaryManagerLifecycle() public {
        assertTrue(aggregator.isSecondaryManager(secondaryManager, address(controller)));
        assertTrue(aggregator.isAnyManager(secondaryManager, address(controller)));

        vm.prank(manager);
        aggregator.removeSecondaryManager(address(controller), secondaryManager);
        assertFalse(aggregator.isAnyManager(secondaryManager, address(controller)));

        // Revoked manager can no longer act
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        bytes32[] memory refs = new bytes32[](1);
        vm.expectRevert(IManagedSuperVaultController.MANAGER_NOT_AUTHORIZED.selector);
        vm.prank(secondaryManager);
        controller.approveDepositors(depositors, refs);
    }

    function test_proposeChangePrimaryManager_timelocked() public {
        address newManager = makeAddr("newManager");

        // Only secondary managers can propose
        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(user);
        aggregator.proposeChangePrimaryManager(address(controller), newManager, feeRecipient);

        vm.prank(secondaryManager);
        aggregator.proposeChangePrimaryManager(address(controller), newManager, feeRecipient);

        vm.expectRevert(IManagedSuperVaultAggregator.TIMELOCK_NOT_EXPIRED.selector);
        aggregator.executeChangePrimaryManager(address(controller));

        vm.warp(block.timestamp + 7 days);
        aggregator.executeChangePrimaryManager(address(controller));
        assertEq(aggregator.getMainManager(address(controller)), newManager);
        // Secondary managers cleared on replacement
        assertEq(aggregator.getSecondaryManagers(address(controller)).length, 0);
    }

    function test_changePrimaryManager_governorOnly() public {
        address newManager = makeAddr("newManager");

        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(manager);
        aggregator.changePrimaryManager(address(controller), newManager, feeRecipient);

        vm.prank(address(superGovernor));
        aggregator.changePrimaryManager(address(controller), newManager, feeRecipient);
        assertEq(aggregator.getMainManager(address(controller)), newManager);
    }

    function test_minUpdateIntervalChange_timelocked() public {
        vm.prank(manager);
        aggregator.proposeMinUpdateIntervalChange(address(controller), 200);

        vm.expectRevert(IManagedSuperVaultAggregator.TIMELOCK_NOT_EXPIRED.selector);
        aggregator.executeMinUpdateIntervalChange(address(controller));

        vm.warp(block.timestamp + 3 days);
        aggregator.executeMinUpdateIntervalChange(address(controller));
        assertEq(aggregator.getMinUpdateInterval(address(controller)), 200);
    }

    function test_updatePPSAfterSkim_validations() public {
        // Only registered controllers
        vm.expectRevert(IManagedSuperVaultAggregator.UNKNOWN_CONTROLLER.selector);
        aggregator.updatePPSAfterSkim(1e18, 1);

        // PPS must decrease
        vm.expectRevert(IManagedSuperVaultAggregator.PPS_MUST_DECREASE_AFTER_SKIM.selector);
        vm.prank(address(controller));
        aggregator.updatePPSAfterSkim(2e18, 1);

        // Deduction bounded by max performance fee
        vm.expectRevert(IManagedSuperVaultAggregator.PPS_DEDUCTION_TOO_LARGE.selector);
        vm.prank(address(controller));
        aggregator.updatePPSAfterSkim(0.4e18, 1);

        vm.prank(address(controller));
        aggregator.updatePPSAfterSkim(0.99e18, 1);
        assertEq(aggregator.getPPS(address(controller)), 0.99e18);
    }
}
