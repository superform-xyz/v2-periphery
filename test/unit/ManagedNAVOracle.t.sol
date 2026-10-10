// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedNAVOracle } from "../../src/ManagedSuperVault/ManagedNAVOracle.sol";
import { IManagedNAVOracle } from "../../src/interfaces/ManagedSuperVault/IManagedNAVOracle.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";

/// @title ManagedNAVOracleTest
/// @notice Unit tests for ManagedNAVOracle — the attested-manual NAV front end for Managed SuperVaults.
///         Covers the proposal/attestation lifecycle, the Rejected paths (aggregator forwardPPS skips
///         instead of reverting), manager-snapshot invalidation, and the timelocked attestation-config
///         lifecycle.
contract ManagedNAVOracleTest is ManagedSuperVaultTestBase {
    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Warps past the rate limit and proposes `newPPS` as `manager` with a fresh observation timestamp
    function _propose(address strategy_, uint256 newPPS) internal returns (uint256 proposalId) {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        proposalId =
            navOracle.proposeNAVUpdate(strategy_, newPPS, block.timestamp, EVIDENCE_HASH, "ipfs://evidence");
    }

    /// @dev Creates a second managed vault whose NAV config requires 2 attestations
    function _createThresholdTwoStrategy() internal returns (address strategy2) {
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();
        params.navConfig.threshold = 2;
        (, strategy2,,) = _createManagedVault(params);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor rejects a zero aggregator address
    function test_constructor_revertsOnZeroAggregator() public {
        vm.expectRevert(IManagedNAVOracle.ZERO_ADDRESS.selector);
        new ManagedNAVOracle(address(0));
    }

    /// @notice Constructor stores the aggregator address
    function test_constructor_setsAggregator() public view {
        assertEq(navOracle.MANAGED_AGGREGATOR(), address(aggregator));
    }

    /*//////////////////////////////////////////////////////////////
                        LIFECYCLE HAPPY PATH
    //////////////////////////////////////////////////////////////*/

    /// @notice propose -> attest -> finalized: PPS lands in the aggregator, proposal is Finalized,
    ///         NAVFinalized is emitted and the active proposal slot is cleared
    function test_proposeAttestFinalize_happyPath() public {
        uint256 newPPS = 1.05e18;
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        uint256 ts = block.timestamp;

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVProposed(
            address(strategy), 1, INITIAL_PPS, newPPS, ts, manager, EVIDENCE_HASH, "ipfs://evidence"
        );
        vm.prank(manager);
        uint256 proposalId = navOracle.proposeNAVUpdate(address(strategy), newPPS, ts, EVIDENCE_HASH, "ipfs://evidence");
        assertEq(proposalId, 1);
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), proposalId);

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVAttested(address(strategy), proposalId, attestor, 1);
        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVFinalized(address(strategy), proposalId, newPPS, ts);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        // Value landed in the aggregator
        assertEq(aggregator.getPPS(address(strategy)), newPPS);
        assertEq(aggregator.getLastUpdateTimestamp(address(strategy)), ts);

        // Proposal terminated as Finalized, active slot cleared
        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(address(strategy), proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.Finalized));
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);
        assertTrue(navOracle.hasAttested(address(strategy), proposalId, attestor));

        // A terminated proposal cannot be attested again
        vm.expectRevert(IManagedNAVOracle.NAV_PROPOSAL_NOT_PENDING.selector);
        vm.prank(attestor2);
        navOracle.attestNAVUpdate(address(strategy), proposalId);
    }

    /// @notice Secondary managers can also propose NAV updates
    function test_proposeNAVUpdate_secondaryManagerCanPropose() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(secondaryManager);
        uint256 proposalId = navOracle.proposeNAVUpdate(
            address(strategy), 1.01e18, block.timestamp, EVIDENCE_HASH, "ipfs://evidence"
        );

        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(address(strategy), proposalId);
        assertEq(proposal.proposer, secondaryManager);
        // managerAtPropose snapshots the MAIN manager, not the proposer
        assertEq(proposal.managerAtPropose, manager);
    }

    /*//////////////////////////////////////////////////////////////
                        PROPOSE VALIDATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Proposing a zero PPS reverts
    function test_proposeNAVUpdate_revertsOnZeroPPS() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectRevert(IManagedNAVOracle.INVALID_NAV.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(address(strategy), 0, block.timestamp, EVIDENCE_HASH, "");
    }

    /// @notice Proposing without an evidence hash reverts
    function test_proposeNAVUpdate_revertsOnZeroEvidenceHash() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectRevert(IManagedNAVOracle.EVIDENCE_REQUIRED.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(address(strategy), 1.01e18, block.timestamp, bytes32(0), "");
    }

    /// @notice A future observation timestamp reverts
    function test_proposeNAVUpdate_revertsOnFutureTimestamp() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectRevert(IManagedNAVOracle.INVALID_TIMESTAMP.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(address(strategy), 1.01e18, block.timestamp + 1, EVIDENCE_HASH, "");
    }

    /// @notice An observation timestamp not strictly newer than the stored PPS timestamp reverts
    function test_proposeNAVUpdate_revertsOnTimestampNotAfterLastUpdate() public {
        uint256 lastUpdate = aggregator.getLastUpdateTimestamp(address(strategy));
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectRevert(IManagedNAVOracle.INVALID_TIMESTAMP.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(address(strategy), 1.01e18, lastUpdate, EVIDENCE_HASH, "");
    }

    /// @notice An observation timestamp older than maxStaleness reverts
    function test_proposeNAVUpdate_revertsOnStaleTimestamp() public {
        vm.warp(block.timestamp + 2 days);
        // Newer than lastUpdate and outside the rate-limit window, but older than maxStaleness
        uint256 staleTs = block.timestamp - MAX_STALENESS - 1;
        vm.expectRevert(IManagedNAVOracle.INVALID_TIMESTAMP.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(address(strategy), 1.01e18, staleTs, EVIDENCE_HASH, "");
    }

    /// @notice An observation timestamp inside the minUpdateInterval window reverts
    function test_proposeNAVUpdate_revertsInsideMinUpdateInterval() public {
        uint256 lastUpdate = aggregator.getLastUpdateTimestamp(address(strategy));
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 10);
        // Fresh (not stale, not future, newer than lastUpdate) but < lastUpdate + MIN_UPDATE_INTERVAL
        uint256 tooSoonTs = lastUpdate + MIN_UPDATE_INTERVAL - 1;
        vm.expectRevert(IManagedNAVOracle.INVALID_TIMESTAMP.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(address(strategy), 1.01e18, tooSoonTs, EVIDENCE_HASH, "");
    }

    /// @notice Proposing while the strategy is paused reverts (the aggregator would drop the push)
    function test_proposeNAVUpdate_revertsWhenStrategyPaused() public {
        vm.prank(manager);
        aggregator.pauseStrategy(address(strategy));

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectRevert(IManagedNAVOracle.STRATEGY_PAUSED.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(address(strategy), 1.01e18, block.timestamp, EVIDENCE_HASH, "");
    }

    /// @notice Only managers of the strategy can propose
    function test_proposeNAVUpdate_revertsForNonManager() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectRevert(IManagedNAVOracle.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(user);
        navOracle.proposeNAVUpdate(address(strategy), 1.01e18, block.timestamp, EVIDENCE_HASH, "");
    }

    /// @notice Only one active proposal at a time; a second propose reverts
    function test_proposeNAVUpdate_revertsOnSecondActiveProposal() public {
        _propose(address(strategy), 1.01e18);

        vm.expectRevert(IManagedNAVOracle.NAV_PROPOSAL_PENDING.selector);
        vm.prank(secondaryManager);
        navOracle.proposeNAVUpdate(address(strategy), 1.02e18, block.timestamp, EVIDENCE_HASH, "");
    }

    /// @notice Proposing for an unknown (never-created, hence unconfigured) strategy reverts.
    /// @dev The manager check runs before the config-initialized check, and no one is a manager of an
    ///      unknown strategy, so UNAUTHORIZED_UPDATE_AUTHORITY is hit first (NAV_CONFIG_NOT_INITIALIZED
    ///      is unreachable through public flows because createVault initializes the config atomically).
    function test_proposeNAVUpdate_revertsOnUnknownStrategy() public {
        vm.expectRevert(IManagedNAVOracle.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(manager);
        navOracle.proposeNAVUpdate(makeAddr("unknownStrategy"), 1.01e18, block.timestamp, EVIDENCE_HASH, "");
    }

    /*//////////////////////////////////////////////////////////////
                        ATTEST VALIDATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Only configured attestors can attest
    function test_attestNAVUpdate_revertsForNonAttestor() public {
        uint256 proposalId = _propose(address(strategy), 1.01e18);

        vm.expectRevert(IManagedNAVOracle.NOT_NAV_ATTESTOR.selector);
        vm.prank(user);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        // The manager (proposer) is not in the attestor set either
        vm.expectRevert(IManagedNAVOracle.NOT_NAV_ATTESTOR.selector);
        vm.prank(manager);
        navOracle.attestNAVUpdate(address(strategy), proposalId);
    }

    /// @notice An attestor who is also a manager cannot attest their own proposal
    function test_attestNAVUpdate_revertsForProposerAttestor() public {
        // Make the attestor a secondary manager so they can propose
        vm.prank(manager);
        aggregator.addSecondaryManager(address(strategy), attestor);

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(attestor);
        uint256 proposalId =
            navOracle.proposeNAVUpdate(address(strategy), 1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.expectRevert(IManagedNAVOracle.ATTESTOR_CANNOT_BE_PROPOSER.selector);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        // A different attestor can still finalize the attestor-proposed value
        vm.prank(attestor2);
        navOracle.attestNAVUpdate(address(strategy), proposalId);
        assertEq(aggregator.getPPS(address(strategy)), 1.01e18);
    }

    /// @notice Attesting a proposal that does not exist (status None) reverts
    function test_attestNAVUpdate_revertsOnNonexistentProposal() public {
        vm.expectRevert(IManagedNAVOracle.NAV_PROPOSAL_NOT_PENDING.selector);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), 999);
    }

    /// @notice The same attestor cannot attest twice (threshold-2 vault so the first attest doesn't finalize)
    function test_attestNAVUpdate_revertsOnDoubleAttest() public {
        address strategy2 = _createThresholdTwoStrategy();
        uint256 proposalId = _propose(strategy2, 1.01e18);

        vm.prank(attestor);
        navOracle.attestNAVUpdate(strategy2, proposalId);

        vm.expectRevert(IManagedNAVOracle.ALREADY_ATTESTED.selector);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(strategy2, proposalId);
    }

    /// @notice Finalization triggers at exactly the threshold: 1 of 2 keeps the proposal pending,
    ///         2 of 2 finalizes and pushes the value
    function test_attestNAVUpdate_finalizesExactlyAtThreshold() public {
        address strategy2 = _createThresholdTwoStrategy();
        uint256 newPPS = 1.05e18;
        uint256 proposalId = _propose(strategy2, newPPS);
        uint256 ts = block.timestamp;

        // First attestation: below threshold, nothing pushed
        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVAttested(strategy2, proposalId, attestor, 1);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(strategy2, proposalId);

        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(strategy2, proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.PendingAttestation));
        assertEq(proposal.attestationCount, 1);
        assertEq(aggregator.getPPS(strategy2), INITIAL_PPS);
        assertEq(navOracle.getActiveNAVProposalId(strategy2), proposalId);

        // Second attestation: exactly at threshold, finalizes
        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVFinalized(strategy2, proposalId, newPPS, ts);
        vm.prank(attestor2);
        navOracle.attestNAVUpdate(strategy2, proposalId);

        proposal = navOracle.getNAVProposal(strategy2, proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.Finalized));
        assertEq(proposal.attestationCount, 2);
        assertEq(aggregator.getPPS(strategy2), newPPS);
        assertEq(navOracle.getActiveNAVProposalId(strategy2), 0);
    }

    /*//////////////////////////////////////////////////////////////
                            CANCEL
    //////////////////////////////////////////////////////////////*/

    /// @notice A manager can cancel a pending proposal, clearing the active slot for a re-propose
    function test_cancelNAVUpdate_managerCancelsPending() public {
        uint256 proposalId = _propose(address(strategy), 1.01e18);

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVProposalCanceled(address(strategy), proposalId, manager);
        vm.prank(manager);
        navOracle.cancelNAVUpdate(address(strategy), proposalId);

        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(address(strategy), proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.Canceled));
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);

        // Slot is free: the manager can propose again
        uint256 nextId = _propose(address(strategy), 1.02e18);
        assertEq(nextId, proposalId + 1);
    }

    /// @notice Cancelling a proposal that is not pending reverts
    function test_cancelNAVUpdate_revertsWhenNotPending() public {
        uint256 proposalId = _propose(address(strategy), 1.01e18);
        vm.prank(manager);
        navOracle.cancelNAVUpdate(address(strategy), proposalId);

        vm.expectRevert(IManagedNAVOracle.NAV_PROPOSAL_NOT_PENDING.selector);
        vm.prank(manager);
        navOracle.cancelNAVUpdate(address(strategy), proposalId);
    }

    /// @notice Only managers can cancel a proposal
    function test_cancelNAVUpdate_revertsForNonManager() public {
        uint256 proposalId = _propose(address(strategy), 1.01e18);

        vm.expectRevert(IManagedNAVOracle.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(user);
        navOracle.cancelNAVUpdate(address(strategy), proposalId);
    }

    /*//////////////////////////////////////////////////////////////
                        REJECTED PATHS
    //////////////////////////////////////////////////////////////*/

    /// @notice If the strategy is paused between propose and threshold attest, forwardPPS skips the push
    ///         and the proposal terminates as Rejected (the attest transaction itself succeeds)
    function test_attestNAVUpdate_rejectedWhenStrategyPausedAfterPropose() public {
        uint256 proposalId = _propose(address(strategy), 1.01e18);

        // Pause lands after the propose prechecks already passed
        vm.prank(manager);
        aggregator.pauseStrategy(address(strategy));

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVRejected(address(strategy), proposalId, 1.01e18);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(address(strategy), proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.Rejected));
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);
        assertEq(aggregator.getPPS(address(strategy)), INITIAL_PPS);
    }

    /// @notice A performance-fee skim between propose and attest bumps the aggregator's lastUpdateTimestamp,
    ///         so the queued observation fails monotonicity at push time and the proposal is Rejected
    ///         (without auto-pausing — monotonicity skips are silent drops)
    function test_attestNAVUpdate_rejectedOnMonotonicityAfterSkim() public {
        // Seed supply + strategy liquidity, then lift PPS above the 1.0 HWM so a skim is possible
        _requestFulfillClaim(user, 100e18);
        _pushNAV(1.2e18);

        // Propose with a valid (fresh) observation timestamp
        uint256 proposalId = _propose(address(strategy), 1.25e18);

        // Skim moves lastUpdateTimestamp to block.timestamp == the proposal's effectiveTimestamp
        vm.prank(manager);
        strategy.skimPerformanceFee();
        uint256 ppsAfterSkim = aggregator.getPPS(address(strategy));
        assertLt(ppsAfterSkim, 1.2e18);

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVRejected(address(strategy), proposalId, 1.25e18);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        // Rejected without pausing: the manager simply re-proposes with a fresher observation
        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(address(strategy), proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.Rejected));
        assertEq(aggregator.getPPS(address(strategy)), ppsAfterSkim);
        assertFalse(aggregator.isStrategyPaused(address(strategy)));
        assertFalse(aggregator.isPPSStale(address(strategy)));
    }

    /// @notice A >deviation-threshold PPS jump is dropped at push time: proposal Rejected, strategy
    ///         auto-paused, PPS marked stale and the stored value unchanged
    function test_attestNAVUpdate_deviationRejectionAutoPauses() public {
        // 1e18 -> 1.6e18 is a 60% move, above the 50% default deviation threshold
        uint256 proposalId = _propose(address(strategy), 1.6e18);

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVRejected(address(strategy), proposalId, 1.6e18);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(address(strategy), proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.Rejected));
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);
        assertEq(aggregator.getPPS(address(strategy)), INITIAL_PPS);
        assertTrue(aggregator.isStrategyPaused(address(strategy)));
        assertTrue(aggregator.isPPSStale(address(strategy)));
    }

    /// @notice Full large-deviation runbook: deviation rejection -> manager unpause -> fresh re-propose
    ///         -> re-attest lands because _forwardPPS skips the deviation bound while PPS is stale
    function test_deviationRunbook_unpauseReproposeLands() public {
        // Step 1: out-of-bound value is rejected and auto-pauses the strategy
        uint256 rejectedId = _propose(address(strategy), 1.6e18);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), rejectedId);
        assertTrue(aggregator.isStrategyPaused(address(strategy)));
        assertTrue(aggregator.isPPSStale(address(strategy)));

        // Step 2: explicit manager unpause (PPS stays stale)
        vm.prank(manager);
        aggregator.unpauseStrategy(address(strategy));
        assertFalse(aggregator.isStrategyPaused(address(strategy)));
        assertTrue(aggregator.isPPSStale(address(strategy)));

        // Step 3: re-propose the same out-of-bound value with a fresh observation after the unpause
        uint256 proposalId = _propose(address(strategy), 1.6e18);
        uint256 ts = block.timestamp;
        assertGt(ts, aggregator.getLastUnpauseTimestamp(address(strategy)));

        // Step 4: re-attest — the push lands via the stale-skip of the deviation check
        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVFinalized(address(strategy), proposalId, 1.6e18, ts);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        assertEq(aggregator.getPPS(address(strategy)), 1.6e18);
        assertFalse(aggregator.isPPSStale(address(strategy)));
        assertFalse(aggregator.isStrategyPaused(address(strategy)));
        assertEq(
            uint8(navOracle.getNAVProposal(address(strategy), proposalId).status),
            uint8(IManagedNAVOracle.NAVProposalStatus.Finalized)
        );
    }

    /*//////////////////////////////////////////////////////////////
                    MANAGER-SNAPSHOT INVALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @notice A proposal created under an outgoing main manager is auto-cancelled at attest time:
    ///         the transaction succeeds but the proposal flips to Canceled with no attestation recorded
    function test_attestNAVUpdate_autoCancelsAfterMainManagerChange() public {
        uint256 proposalId = _propose(address(strategy), 1.01e18);

        // Governance replaces the main manager while the proposal is in flight
        vm.prank(sGovernor);
        aggregator.changePrimaryManager(address(strategy), makeAddr("newMainManager"), makeAddr("newFeeRecipient"));

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVProposalCanceled(address(strategy), proposalId, attestor);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(address(strategy), proposalId);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.Canceled));
        assertEq(proposal.attestationCount, 0);
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);
        assertFalse(navOracle.hasAttested(address(strategy), proposalId, attestor));
        assertEq(aggregator.getPPS(address(strategy)), INITIAL_PPS);
    }

    /*//////////////////////////////////////////////////////////////
                    ATTESTATION CONFIG LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /// @notice initializeAttestationConfig is aggregator-only
    function test_initializeAttestationConfig_revertsForNonAggregator() public {
        address[] memory attestors = new address[](1);
        attestors[0] = attestor;

        vm.expectRevert(IManagedNAVOracle.ONLY_AGGREGATOR.selector);
        vm.prank(manager);
        navOracle.initializeAttestationConfig(
            address(strategy), IManagedNAVOracle.NavAttestationConfig({ attestors: attestors, threshold: 1 })
        );
    }

    /// @notice A strategy's config can only be initialized once
    function test_initializeAttestationConfig_revertsOnDoubleInit() public {
        address[] memory attestors = new address[](1);
        attestors[0] = attestor;

        vm.expectRevert(IManagedNAVOracle.NAV_CONFIG_ALREADY_INITIALIZED.selector);
        vm.prank(address(aggregator));
        navOracle.initializeAttestationConfig(
            address(strategy), IManagedNAVOracle.NavAttestationConfig({ attestors: attestors, threshold: 1 })
        );
    }

    /// @notice Only the main manager can propose an attestation config change
    function test_proposeNAVAttestationConfig_revertsForNonMainManager() public {
        address[] memory next = new address[](1);
        next[0] = makeAddr("freshAttestor");

        vm.expectRevert(IManagedNAVOracle.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(secondaryManager);
        navOracle.proposeNAVAttestationConfig(address(strategy), next, 1);

        vm.expectRevert(IManagedNAVOracle.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(user);
        navOracle.proposeNAVAttestationConfig(address(strategy), next, 1);
    }

    /// @notice Invalid config shapes revert: empty set, zero threshold, threshold > set size,
    ///         zero attestor, duplicate attestor
    function test_proposeNAVAttestationConfig_revertsOnInvalidConfigs() public {
        address[] memory empty = new address[](0);
        address[] memory one = new address[](1);
        one[0] = makeAddr("freshAttestor");

        vm.startPrank(manager);
        vm.expectRevert(IManagedNAVOracle.INVALID_ATTESTATION_CONFIG.selector);
        navOracle.proposeNAVAttestationConfig(address(strategy), empty, 1);

        vm.expectRevert(IManagedNAVOracle.INVALID_ATTESTATION_CONFIG.selector);
        navOracle.proposeNAVAttestationConfig(address(strategy), one, 0);

        vm.expectRevert(IManagedNAVOracle.INVALID_ATTESTATION_CONFIG.selector);
        navOracle.proposeNAVAttestationConfig(address(strategy), one, 2);

        address[] memory withZero = new address[](2);
        withZero[0] = makeAddr("freshAttestor");
        withZero[1] = address(0);
        vm.expectRevert(IManagedNAVOracle.ZERO_ADDRESS.selector);
        navOracle.proposeNAVAttestationConfig(address(strategy), withZero, 1);

        address[] memory duplicate = new address[](2);
        duplicate[0] = makeAddr("freshAttestor");
        duplicate[1] = makeAddr("freshAttestor");
        vm.expectRevert(IManagedNAVOracle.ATTESTOR_ALREADY_EXISTS.selector);
        navOracle.proposeNAVAttestationConfig(address(strategy), duplicate, 1);
        vm.stopPrank();
    }

    /// @notice Executing a config change before the 3-day timelock reverts
    function test_executeNAVAttestationConfig_revertsBeforeTimelock() public {
        address[] memory next = new address[](1);
        next[0] = makeAddr("freshAttestor");
        vm.prank(manager);
        navOracle.proposeNAVAttestationConfig(address(strategy), next, 1);

        vm.expectRevert(IManagedNAVOracle.NAV_CONFIG_TIMELOCK_NOT_EXPIRED.selector);
        vm.prank(manager);
        navOracle.executeNAVAttestationConfig(address(strategy));
    }

    /// @notice After the timelock the attestor set is swapped (old removed, new added) and the
    ///         threshold updated; the new set is live for attestations, the old one is not
    function test_executeNAVAttestationConfig_swapsAttestorSet() public {
        address newAttestor1 = makeAddr("newAttestor1");
        address newAttestor2 = makeAddr("newAttestor2");
        address[] memory next = new address[](2);
        next[0] = newAttestor1;
        next[1] = newAttestor2;

        vm.prank(manager);
        navOracle.proposeNAVAttestationConfig(address(strategy), next, 2);

        IManagedNAVOracle.PendingAttestationConfig memory pending =
            navOracle.getPendingNAVAttestationConfig(address(strategy));
        assertEq(pending.effectiveTime, block.timestamp + 3 days);
        assertEq(pending.threshold, 2);
        assertEq(pending.managerAtPropose, manager);

        vm.warp(block.timestamp + 3 days);
        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVAttestationThresholdUpdated(address(strategy), 2);
        vm.prank(manager);
        navOracle.executeNAVAttestationConfig(address(strategy));

        // Set swapped and threshold updated
        assertEq(navOracle.getNAVAttestors(address(strategy)).length, 2);
        assertFalse(navOracle.isNAVAttestor(address(strategy), attestor));
        assertFalse(navOracle.isNAVAttestor(address(strategy), attestor2));
        assertTrue(navOracle.isNAVAttestor(address(strategy), newAttestor1));
        assertTrue(navOracle.isNAVAttestor(address(strategy), newAttestor2));
        assertEq(navOracle.getNAVAttestationThreshold(address(strategy)), 2);
        assertEq(navOracle.getPendingNAVAttestationConfig(address(strategy)).effectiveTime, 0);

        // Old attestor can no longer attest; the new 2-of-2 set finalizes
        uint256 proposalId = _propose(address(strategy), 1.05e18);
        vm.expectRevert(IManagedNAVOracle.NOT_NAV_ATTESTOR.selector);
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);

        vm.prank(newAttestor1);
        navOracle.attestNAVUpdate(address(strategy), proposalId);
        vm.prank(newAttestor2);
        navOracle.attestNAVUpdate(address(strategy), proposalId);
        assertEq(aggregator.getPPS(address(strategy)), 1.05e18);
    }

    /// @notice Executing a config swap cancels any in-flight NAV proposal so attestations collected
    ///         under the old set cannot finalize under the new one
    function test_executeNAVAttestationConfig_cancelsInFlightProposal() public {
        address newAttestor = makeAddr("freshAttestor");
        address[] memory next = new address[](1);
        next[0] = newAttestor;
        vm.prank(manager);
        navOracle.proposeNAVAttestationConfig(address(strategy), next, 1);

        // Open a NAV proposal near the end of the timelock
        vm.warp(block.timestamp + 3 days);
        uint256 proposalId = _propose(address(strategy), 1.01e18);

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVProposalCanceled(address(strategy), proposalId, manager);
        vm.prank(manager);
        navOracle.executeNAVAttestationConfig(address(strategy));

        assertEq(
            uint8(navOracle.getNAVProposal(address(strategy), proposalId).status),
            uint8(IManagedNAVOracle.NAVProposalStatus.Canceled)
        );
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);

        // Even the NEW valid attestor cannot revive the cancelled proposal
        vm.expectRevert(IManagedNAVOracle.NAV_PROPOSAL_NOT_PENDING.selector);
        vm.prank(newAttestor);
        navOracle.attestNAVUpdate(address(strategy), proposalId);
    }

    /// @notice A pending config proposed by an outgoing main manager is auto-cancelled at execute time
    ///         instead of being installed; the attestor set is untouched
    function test_executeNAVAttestationConfig_autoCancelsAfterManagerChange() public {
        address[] memory next = new address[](1);
        next[0] = makeAddr("sockpuppetAttestor");
        vm.prank(manager);
        navOracle.proposeNAVAttestationConfig(address(strategy), next, 1);

        // Governance replaces the main manager during the timelock
        address newMainManager = makeAddr("newMainManager");
        vm.prank(sGovernor);
        aggregator.changePrimaryManager(address(strategy), newMainManager, makeAddr("newFeeRecipient"));

        vm.warp(block.timestamp + 3 days);
        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVAttestationConfigCancelled(address(strategy));
        vm.prank(newMainManager);
        navOracle.executeNAVAttestationConfig(address(strategy));

        // Config unchanged, pending cleared
        assertTrue(navOracle.isNAVAttestor(address(strategy), attestor));
        assertTrue(navOracle.isNAVAttestor(address(strategy), attestor2));
        assertFalse(navOracle.isNAVAttestor(address(strategy), next[0]));
        assertEq(navOracle.getNAVAttestationThreshold(address(strategy)), 1);
        assertEq(navOracle.getPendingNAVAttestationConfig(address(strategy)).effectiveTime, 0);
    }

    /// @notice Executing with no pending config reverts
    function test_executeNAVAttestationConfig_revertsWithoutPending() public {
        vm.expectRevert(IManagedNAVOracle.NO_PENDING_NAV_CONFIG.selector);
        vm.prank(manager);
        navOracle.executeNAVAttestationConfig(address(strategy));
    }

    /// @notice The main manager can cancel a pending config; a second cancel (no pending) reverts
    function test_cancelNAVAttestationConfig_worksAndRevertsWithoutPending() public {
        address[] memory next = new address[](1);
        next[0] = makeAddr("freshAttestor");
        vm.prank(manager);
        navOracle.proposeNAVAttestationConfig(address(strategy), next, 1);

        // Non-main managers cannot cancel
        vm.expectRevert(IManagedNAVOracle.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        vm.prank(secondaryManager);
        navOracle.cancelNAVAttestationConfig(address(strategy));

        vm.expectEmit(true, true, true, true);
        emit IManagedNAVOracle.NAVAttestationConfigCancelled(address(strategy));
        vm.prank(manager);
        navOracle.cancelNAVAttestationConfig(address(strategy));
        assertEq(navOracle.getPendingNAVAttestationConfig(address(strategy)).effectiveTime, 0);

        vm.expectRevert(IManagedNAVOracle.NO_PENDING_NAV_CONFIG.selector);
        vm.prank(manager);
        navOracle.cancelNAVAttestationConfig(address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                              VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initial view sanity: NAV mode label, attestor set/threshold from vault creation,
    ///         no active proposal and no pending config
    function test_views_initialState() public view {
        assertEq(navOracle.NAV_MODE(), "attested_manual");

        address[] memory attestors = navOracle.getNAVAttestors(address(strategy));
        assertEq(attestors.length, 2);
        assertTrue(navOracle.isNAVAttestor(address(strategy), attestor));
        assertTrue(navOracle.isNAVAttestor(address(strategy), attestor2));
        assertFalse(navOracle.isNAVAttestor(address(strategy), manager));
        assertEq(navOracle.getNAVAttestationThreshold(address(strategy)), 1);

        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);
        assertEq(navOracle.getPendingNAVAttestationConfig(address(strategy)).effectiveTime, 0);
        assertFalse(navOracle.hasAttested(address(strategy), 1, attestor));
    }

    /// @notice getNAVProposal round-trips all proposal fields; hasAttested flips after an attest
    function test_views_proposalAndAttestation() public {
        address strategy2 = _createThresholdTwoStrategy();
        uint256 proposalId = _propose(strategy2, 1.05e18);

        IManagedNAVOracle.NAVUpdateProposal memory proposal = navOracle.getNAVProposal(strategy2, proposalId);
        assertEq(proposal.proposedPPS, 1.05e18);
        assertEq(proposal.effectiveTimestamp, block.timestamp);
        assertEq(proposal.evidenceHash, EVIDENCE_HASH);
        assertEq(proposal.evidenceURI, "ipfs://evidence");
        assertEq(proposal.proposer, manager);
        assertEq(proposal.managerAtPropose, manager);
        assertEq(proposal.attestationCount, 0);
        assertEq(uint8(proposal.status), uint8(IManagedNAVOracle.NAVProposalStatus.PendingAttestation));

        assertFalse(navOracle.hasAttested(strategy2, proposalId, attestor));
        vm.prank(attestor);
        navOracle.attestNAVUpdate(strategy2, proposalId);
        assertTrue(navOracle.hasAttested(strategy2, proposalId, attestor));
        assertFalse(navOracle.hasAttested(strategy2, proposalId, attestor2));
    }
}
