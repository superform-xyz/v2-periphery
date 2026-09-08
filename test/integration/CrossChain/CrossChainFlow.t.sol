// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { CrossChainPositionRegistry } from "../../../src/CrossChain/CrossChainPositionRegistry.sol";
import { CrossChainAUMOracle } from "../../../src/CrossChain/CrossChainAUMOracle.sol";
import { CrossChainPositionCapGuard } from "../../../src/CrossChain/CrossChainPositionCapGuard.sol";
import { ICrossChainPositionRegistry } from "../../../src/interfaces/CrossChain/ICrossChainPositionRegistry.sol";
import { ICrossChainAUMOracle } from "../../../src/interfaces/CrossChain/ICrossChainAUMOracle.sol";
import { ICrossChainPositionCapGuard } from "../../../src/interfaces/CrossChain/ICrossChainPositionCapGuard.sol";
import { MockGovernorLite } from "../../unit/CrossChain/mocks/MockGovernorLite.sol";
import {
    MockAggregatorLite,
    MockStrategyWithVault,
    MockVaultLite
} from "../../unit/CrossChain/mocks/MockCapGuardDeps.sol";

/// @notice End-to-end integration of the three cross-chain contracts wired together via a lite
///         SuperGovernor (roles/validators/registry) and a lite aggregator (isMainManager). Every
///         cross-contract call is real: registry <-> oracle <-> cap guard.
contract CrossChainFlowTest is Test {
    CrossChainPositionRegistry internal registry;
    CrossChainAUMOracle internal oracle;
    CrossChainPositionCapGuard internal guard;
    MockGovernorLite internal governor;
    MockAggregatorLite internal aggregator;

    MockStrategyWithVault internal strategyMock;
    MockVaultLite internal strategyVault;
    /// @dev K2: the strategy is a contract exposing getVaultInfo() -> vault.totalAssets() (the
    ///      implied-assets source); totalAssets defaults to 0 so the SEC-8 band stays inactive
    ///      except where a test arms it.
    address internal strategy;
    address internal registrar = makeAddr("registrar");
    address internal manager = makeAddr("manager");
    address internal bridgeHook = makeAddr("bridgeHook");
    address internal destVault = makeAddr("destVault");

    uint64 internal constant CHAIN_A = 8453;

    uint256[] internal pks;
    address[] internal signers;

    bytes32 internal constant UPDATE_AUM_TYPEHASH = keccak256(
        "UpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );
    bytes32 internal constant FORCE_UPDATE_AUM_TYPEHASH = keccak256(
        "ForceUpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );

    function setUp() public {
        governor = new MockGovernorLite();
        aggregator = new MockAggregatorLite();
        strategyMock = new MockStrategyWithVault();
        strategyVault = new MockVaultLite();
        strategyMock.setVault(address(strategyVault));
        strategy = address(strategyMock);
        registry = new CrossChainPositionRegistry(address(governor));
        oracle = new CrossChainAUMOracle(address(governor), "SuperformCrossChainAUM", "1");
        guard = new CrossChainPositionCapGuard(address(governor));

        // Register the three keys + aggregator in the governor registry.
        governor.setAddress(keccak256("CROSS_CHAIN_POSITION_REGISTRY"), address(registry));
        governor.setAddress(keccak256("CROSS_CHAIN_AUM_ORACLE"), address(oracle));
        governor.setAddress(keccak256("CROSS_CHAIN_CAP_GUARD"), address(guard));
        governor.setAddress(keccak256("SUPER_VAULT_AGGREGATOR"), address(aggregator));

        // Roles: this test contract is governor + oracle-manager.
        governor.grantRole(governor.GOVERNOR_ROLE(), address(this));
        governor.grantRole(governor.ORACLE_MANAGER_ROLE(), address(this));
        aggregator.setMainManager(manager, strategy, true);

        // Validators (3, quorum 2, sorted).
        uint256[] memory raw = new uint256[](3);
        raw[0] = 0xA11CE;
        raw[1] = 0xB0B;
        raw[2] = 0xC0FFEE;
        for (uint256 i; i < 3; ++i) {
            governor.setValidator(vm.addr(raw[i]), true);
        }
        governor.setQuorum(2);
        for (uint256 i; i < 3; ++i) {
            for (uint256 j = i + 1; j < 3; ++j) {
                if (vm.addr(raw[j]) < vm.addr(raw[i])) (raw[i], raw[j]) = (raw[j], raw[i]);
            }
            pks.push(raw[i]);
            signers.push(vm.addr(raw[i]));
        }

        // Wiring: registrar, hook authorization, cap config, oracle config, destination approval.
        registry.setRegistrar(strategy, registrar);
        registry.setBridgeHookAuthorization(bridgeHook, true);
        guard.setApprovedDestination(strategy, CHAIN_A, destVault, true);
        _setCapConfig(7000, 800e18, true); // 70% global, 800 per-chain cap
        oracle.setAUMOracleConfig(
            strategy,
            ICrossChainAUMOracle.AUMOracleConfig({
                maxStaleness: 1 hours,
                minUpdateInterval: 1 minutes,
                deviationThreshold: 0.5e18,
                perPositionDeviationThreshold: 0.75e18,
                consistencyToleranceBps: 100,
                maxConsecutiveDeviationBreaches: 2
            })
        );

        vm.warp(1_000_000);
    }

    function _setCapConfig(uint256 bps, uint256 cap, bool enabled) internal {
        uint64[] memory chains = new uint64[](1);
        chains[0] = CHAIN_A;
        uint256[] memory caps = new uint256[](1);
        caps[0] = cap;
        bool[] memory en = new bool[](1);
        en[0] = enabled;
        guard.setCapConfig(strategy, bps, chains, caps, en);
    }

    function _forwardAUM(bytes32 id, uint256 value, uint256 hubAssets, bool isForce) internal {
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = id;
        uint256[] memory vals = new uint256[](1);
        vals[0] = value;
        uint256 ts = block.timestamp;
        bytes32 structHash = keccak256(
            abi.encode(
                isForce ? FORCE_UPDATE_AUM_TYPEHASH : UPDATE_AUM_TYPEHASH,
                strategy,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(vals)),
                hubAssets,
                ts,
                oracle.noncePerStrategy(strategy)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", oracle.domainSeparator(), structHash));
        bytes[] memory proofs = new bytes[](2);
        for (uint256 i; i < 2; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(pks[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }
        if (isForce) oracle.forceAUMUpdate(strategy, ids, vals, hubAssets, ts, proofs);
        else oracle.forwardAUM(strategy, ids, vals, hubAssets, ts, proofs);
    }

    /*//////////////////////////////////////////////////////////////
                            FULL LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    function test_FullLifecycle_BridgeRegisterConfirmValidate() public {
        // 1. Hook mints the reservation; cap guard sees the exposure immediately (SEC-3/K1).
        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 100e18);

        // 2. Registrar registers the position by consuming that exact reservation (K1).
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );

        // 3. Quorum report confirms it: Pending -> Active, in-flight released, AUM cached.
        //    hubAssets 900 so total AUM = 900 + 100 = 1000. (B2: a Pending position is only
        //    reportable by a report timestamped strictly after registration.)
        vm.warp(block.timestamp + 1);
        _forwardAUM(id, 100e18, 900e18, false);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Active));
        assertEq(registry.bridgedOut(strategy), 0, "in-flight released on confirm");
        assertEq(oracle.getTotalAUM(strategy), 1000e18);
        assertTrue(oracle.isAUMFresh(strategy));
        _assertAccountingConsistent();

        // 4. Cap guard now validates against real confirmed exposure (100) and real AUM (1000):
        //    a further 500 -> 600 <= 70% of 1000, and per-chain 600 <= 800.
        guard.validateAllocation(strategy, CHAIN_A, destVault, 500e18);

        // ...but 650 more -> 750 > 700 (global cap) reverts.
        vm.expectRevert(ICrossChainPositionCapGuard.CROSS_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 650e18);
    }

    function test_BreakerBlocksCapThenForceRecovers() public {
        // Register + confirm a position at value 100 (AUM 1000).
        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );
        vm.warp(block.timestamp + 1);
        _forwardAUM(id, 100e18, 900e18, false);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 100e18); // ok

        // Two >50% deviation soft-fails trip the breaker.
        vm.warp(block.timestamp + 2 minutes);
        _forwardAUM(id, 300e18, 900e18, false);
        vm.warp(block.timestamp + 2 minutes);
        _forwardAUM(id, 300e18, 900e18, false);
        assertTrue(oracle.aumBreakerTripped(strategy));

        // Cap guard now blocks ALL deployments (isAUMFresh false = fail-safe).
        vm.expectRevert(ICrossChainPositionCapGuard.AUM_DATA_STALE.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 1e18);

        // Force-book a real >50% drawdown to 10; breaker clears; cap guard works again. K2: the
        // force path requires a live, consistent PPS backstop (implied ~= hub 900 + total 10).
        strategyVault.setTotalAssets(910e18);
        vm.warp(block.timestamp + 2 minutes);
        _forwardAUM(id, 10e18, 900e18, true);
        assertFalse(oracle.aumBreakerTripped(strategy));
        assertEq(oracle.getTotalAUM(strategy), 910e18);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 1e18); // ok again
        _assertAccountingConsistent();
    }

    function test_UnconfirmedPositionDoesNotCountTowardCap() public {
        // Register but never confirm: Pending is not counted by getCrossChainAUM, but its
        // in-flight bridgedOut IS (so caps still bind during the async window).
        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        vm.prank(registrar);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18);
        // Cover the Pending position with value 0 (stays Pending) plus hubAssets so a report commits.
        vm.warp(block.timestamp + 1);
        _reportPendingZero();

        // getCrossChainAUM = 0 (nothing Active), but effective exposure includes the 100 in-flight.
        assertEq(registry.getCrossChainAUM(strategy), 0);
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 100e18);
        _assertAccountingConsistent();
    }

    /*//////////////////////////////////////////////////////////////
                R5: ABOVE-CEILING PENDING OBSERVATION (REAL STACK)
    //////////////////////////////////////////////////////////////*/

    /// R5-P1 (reviewer round-5 trace, real stack): a first report ABOVE the 110% confirmation
    /// ceiling must (a) be counted in cap exposure at its observed value and (b) be published in
    /// the same snapshot it was validated in. Reserve 100, observe 140 with hub 900 and a live
    /// 1040 PPS backstop: exposure = 140 (not the 100 reservation), published AUM = 1040, so the
    /// 80 allocation that previously passed both caps now reverts on both.
    function test_R5_AboveCeilingObservationCountsInCapExposure() public {
        _setCapConfig(2000, 180e18, true); // 20% global, 180 on chain A
        strategyVault.setTotalAssets(1000e18); // live PPS x supply backstop
        _forwardMany(new bytes32[](0), new uint256[](0), 1000e18, false); // committed: hub 1000, cc 0
        assertEq(oracle.getTotalAUM(strategy), 1000e18);

        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );

        // The destination appreciates to 140 before its first report; hub holds 900 after the send.
        vm.warp(block.timestamp + 2 minutes);
        strategyVault.setTotalAssets(1040e18);
        _forwardAUM(id, 140e18, 900e18, false);

        // Validated snapshot == published snapshot: the 140 is booked, freshness is renewed on a
        // total inside the PPS band, and the position stays Pending (ceiling) with its
        // reservation retained.
        assertEq(oracle.getTotalAUM(strategy), 1040e18, "published total is the validated total");
        assertTrue(oracle.isAUMFresh(strategy));
        _assertPublishedSnapshotWithinPPSBand();
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
        assertEq(registry.bridgedOut(strategy), 100e18, "reservation retained above the ceiling");
        assertEq(registry.pendingObservedExcess(strategy), 40e18);
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 140e18, "exposure must be >= observed value");
        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 140e18);

        // The reviewer's allocation of 80: 140 + 80 = 220 > 20% of 1040 (208) -> global cap binds.
        vm.expectRevert(ICrossChainPositionCapGuard.CROSS_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 80e18);
        // Per-chain binds on its own: with the global cap lifted, 220 > 180 still reverts...
        _setCapConfig(10_000, 180e18, true);
        vm.expectRevert(ICrossChainPositionCapGuard.PER_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 80e18);
        // ...while an allocation that truly fits (140 + 40 = 180) passes.
        guard.validateAllocation(strategy, CHAIN_A, destVault, 40e18);
    }

    /// R5-P1: reservation 100, chain cap 105, observation 111 -> a single extra unit reverts.
    function test_R5_AboveCeilingObservationBindsChainCapByOneUnit() public {
        _setCapConfig(10_000, 105e18, true);
        _forwardMany(new bytes32[](0), new uint256[](0), 1000e18, false);

        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );
        vm.warp(block.timestamp + 2 minutes);
        _forwardAUM(id, 111e18, 900e18, false);

        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 111e18);
        vm.expectRevert(ICrossChainPositionCapGuard.PER_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 1);
    }

    /// R5-P1: forceAUMUpdate validates the same candidate and commits through the same path, so
    /// the published snapshot equals the validated one there too.
    function test_R5_ForcePathPublishesValidatedSnapshot() public {
        strategyVault.setTotalAssets(1000e18);
        _forwardMany(new bytes32[](0), new uint256[](0), 1000e18, false);

        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );
        vm.warp(block.timestamp + 2 minutes);
        strategyVault.setTotalAssets(1040e18);
        _forwardAUM(id, 140e18, 900e18, true); // force path (ORACLE_MANAGER + quorum, live PPS)

        assertEq(oracle.getTotalAUM(strategy), 1040e18, "force path publishes the validated total");
        _assertPublishedSnapshotWithinPPSBand();
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 140e18);
    }

    /*//////////////////////////////////////////////////////////////
            R6: TIME ALONE NEVER UNCOUNTS LANDED CAPITAL (REAL STACK)
    //////////////////////////////////////////////////////////////*/

    /// R6-P1 (reviewer round-6 trace, real stack): AUM 1,000, 20% global cap, 200 chain cap, 24h
    /// staleness. A legitimate 200 lands and is registered; >2h pass with no positive report. The
    /// old wall-clock paths let anyone invalidate the position, reset exposure to 0 and reuse the
    /// headroom under the still-fresh snapshot (true exposure 400 = 40%). Now: a non-governor
    /// cannot invalidate, a zero report past the timeout keeps the reservation counted, and the
    /// second 200 reverts on both caps.
    function test_R6_RegisteredPendingIsNeverUncountedByWallClock() public {
        _setCapConfig(2000, 200e18, true); // 20% global, 200 on chain A
        oracle.setAUMOracleConfig(
            strategy,
            ICrossChainAUMOracle.AUMOracleConfig({
                maxStaleness: 4 hours, // MAX_MAX_STALENESS (R7); still fresh after the 2h+ delay of the trace
                minUpdateInterval: 1 minutes,
                deviationThreshold: 0.5e18,
                perPositionDeviationThreshold: 0.75e18,
                consistencyToleranceBps: 100,
                maxConsecutiveDeviationBreaches: 2
            })
        );
        _forwardMany(new bytes32[](0), new uint256[](0), 1000e18, false); // fresh snapshot: AUM 1,000

        // 1-2. A legitimate 200 passes both caps, lands, and is registered (fill detected).
        guard.validateAllocation(strategy, CHAIN_A, destVault, 200e18);
        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 200e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 190e18
        );
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 200e18);

        // 3-4. >2h reporting delay; anyone tries to erase the landed capital.
        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);
        assertTrue(oracle.isAUMFresh(strategy), "snapshot still fresh under the 24h window");
        vm.prank(makeAddr("anyone"));
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_CONFIG.selector);
        registry.invalidateExpiredPending(strategy, id);
        vm.prank(makeAddr("anyone"));
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_CONFIG.selector); // governance-only (and Consumed
        // anyway)
        registry.releaseExpiredReservation(reservationId);
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 200e18, "wall clock cannot uncount");

        // A zero report past the timeout (the quorum has not observed it yet) must NOT release the
        // Consumed reservation either.
        _forwardAUM(id, 0, 1000e18, false); // hub reported unchanged: keeps the published 1,000 denominator of the
        // trace
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
        assertEq(registry.bridgedOut(strategy), 200e18, "zero report keeps the reservation counted");
        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 200e18);

        // 6. The second 200 reverts on the global cap (200 + 200 > 20% of 1,000)...
        vm.expectRevert(ICrossChainPositionCapGuard.CROSS_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 200e18);
        // ...and, with the global cap lifted, on the chain cap (400 > 200).
        _setCapConfig(10_000, 200e18, true);
        vm.expectRevert(ICrossChainPositionCapGuard.PER_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 200e18);

        // The late landing still confirms through the normal report path and settles.
        vm.warp(block.timestamp + 2 minutes);
        _forwardAUM(id, 200e18, 1000e18, false);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Active));
        assertEq(registry.bridgedOut(strategy), 0);
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 200e18);
    }

    /// R6 (reviewer's Open-Across variant): even a governance release followed by a late fill can
    /// never let a second allocation slip through for long — the late registration re-consumes the
    /// Released reservation, re-counting it EXACTLY once and re-arming both caps. (A release while
    /// a fill actually landed is a wrong attestation; the window it opens is transient and closes
    /// on registration — the runbook's evidence requirements exist to make it not happen at all.)
    function test_R6_GovernanceReleaseThenLateFillRecountsOnce() public {
        _setCapConfig(2000, 200e18, true);
        oracle.setAUMOracleConfig(
            strategy,
            ICrossChainAUMOracle.AUMOracleConfig({
                maxStaleness: 4 hours, // MAX_MAX_STALENESS (R7); the snapshot must still be fresh after the 2h release
                // window
                minUpdateInterval: 1 minutes,
                deviationThreshold: 0.5e18,
                perPositionDeviationThreshold: 0.75e18,
                consistencyToleranceBps: 100,
                maxConsecutiveDeviationBreaches: 2
            })
        );
        _forwardMany(new bytes32[](0), new uint256[](0), 1000e18, false);

        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 200e18);
        vm.warp(block.timestamp + registry.RESERVATION_TIMEOUT() + 1);
        registry.releaseExpiredReservation(reservationId); // governance attests no-fill
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 0);

        // The fill had in fact landed; the registrar registers it against the Released reservation.
        vm.prank(registrar);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 190e18);
        assertEq(registry.bridgedOut(strategy), 200e18, "re-counted exactly once");
        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 200e18);

        vm.expectRevert(ICrossChainPositionCapGuard.CROSS_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 200e18);
    }

    /// R6-P1 regression 4: a terminal invalidation cannot front-run a valid report — only
    /// governance can invalidate, so the report commits the landed 200.
    function test_R6_InvalidationCannotFrontRunReport() public {
        _forwardMany(new bytes32[](0), new uint256[](0), 1000e18, false);
        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 200e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 190e18
        );
        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);

        // Front-run attempt by anyone in the same block as the report: reverts.
        vm.prank(makeAddr("frontrunner"));
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_CONFIG.selector);
        registry.invalidateExpiredPending(strategy, id);

        _forwardAUM(id, 200e18, 800e18, false);
        assertEq(oracle.latestReport(strategy).totalCrossChainAssets, 200e18, "landed capital committed");
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 200e18);
    }

    /// @dev R5 regression 4: the EXACT committed snapshot (not merely the pre-commit candidate)
    ///      satisfies the configured PPS consistency band.
    function _assertPublishedSnapshotWithinPPSBand() internal view {
        uint256 published = oracle.getTotalAUM(strategy);
        uint256 implied = strategyVault.totalAssets();
        uint256 diff = published > implied ? published - implied : implied - published;
        assertLe(diff * 10_000 / implied, 100, "published snapshot outside the PPS band");
    }

    /// R4-P1 (exit livelock, real stack): a full exit must complete through NORMAL quorum
    /// reports — WindingDown -> drain-to-zero report commits (no breach, no breaker, no force
    /// path) -> deregisterPosition frees the slot. Before R4 a zero report was definitionally a
    /// 100% deviation, so this path was unroutable and every exit leaked a position slot.
    function test_R4_FullExit_DrainToZeroDeregistersThroughNormalReports() public {
        vm.prank(bridgeHook);
        bytes32 reservationId = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );
        vm.warp(block.timestamp + 1);
        _forwardAUM(id, 100e18, 900e18, false); // confirm at 100

        vm.prank(registrar);
        registry.beginPositionExit(strategy, id);

        // Destination drained; honest quorum reports zero. Must COMMIT, not soft-fail.
        vm.warp(block.timestamp + 2 minutes);
        _forwardAUM(id, 0, 1000e18, false); // capital returned to hub: hub 1000, cross-chain 0
        assertEq(oracle.consecutiveBreaches(strategy), 0, "drain must not breach");
        assertFalse(oracle.aumBreakerTripped(strategy));
        assertEq(oracle.getTotalAUM(strategy), 1000e18, "hub-only AUM after drain");
        _assertAccountingConsistent();

        // Oracle-confirmed zero -> deregistration works and the slot is freed.
        vm.prank(registrar);
        registry.deregisterPosition(strategy, id);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Exited));
        assertEq(registry.getPositionIds(strategy).length, 0, "slot freed - exits must not leak slots");
    }

    /// R4-P1 (confirmation blockade, real stack): a second bridge LARGER than the deviation band
    /// around the committed cross-chain total must still confirm — its still-counted reservation
    /// anchors the aggregate band. Before R4 the confirming report could never commit and the
    /// landed capital fell off-book at reservation expiry.
    function test_R4_LargeSecondBridgeConfirmsAndStaysOnBook() public {
        // First position: confirm 100 (committed cross-chain total = 100).
        vm.prank(bridgeHook);
        bytes32 res1 = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 100e18);
        vm.prank(registrar);
        bytes32 id1 =
            registry.registerPosition(strategy, res1, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18);
        vm.warp(block.timestamp + 1);
        _forwardAUM(id1, 100e18, 900e18, false);

        // Second bridge: 200 — a 190% raw-total jump once it lands (cache-only band <= 50%).
        vm.prank(bridgeHook);
        bytes32 res2 = registry.recordBridgedOut(strategy, CHAIN_A, destVault, 200e18);
        vm.prank(registrar);
        bytes32 id2 =
            registry.registerPosition(strategy, res2, ICrossChainPositionRegistry.PositionKind.SuperVault, 190e18);

        vm.warp(block.timestamp + 2 minutes);
        (bytes32 lo, bytes32 hi) = id1 < id2 ? (id1, id2) : (id2, id1);
        bytes32[] memory ids = new bytes32[](2);
        ids[0] = lo;
        ids[1] = hi;
        uint256[] memory vals = new uint256[](2);
        vals[0] = lo == id1 ? 100e18 : 190e18;
        vals[1] = hi == id2 ? 190e18 : 100e18;
        _forwardMany(ids, vals, 700e18, false);

        assertEq(uint256(registry.positions(id2).status), uint256(ICrossChainPositionRegistry.PositionStatus.Active));
        assertEq(registry.bridgedOut(strategy), 0, "both reservations settled");
        assertEq(registry.getCrossChainAUM(strategy), 290e18, "landed capital on-book");
        assertEq(oracle.consecutiveBreaches(strategy), 0, "legitimate landing must not breach");
        _assertAccountingConsistent();
    }

    function _forwardMany(bytes32[] memory ids, uint256[] memory vals, uint256 hubAssets, bool isForce) internal {
        uint256 ts = block.timestamp;
        bytes32 structHash = keccak256(
            abi.encode(
                isForce ? FORCE_UPDATE_AUM_TYPEHASH : UPDATE_AUM_TYPEHASH,
                strategy,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(vals)),
                hubAssets,
                ts,
                oracle.noncePerStrategy(strategy)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", oracle.domainSeparator(), structHash));
        bytes[] memory proofs = new bytes[](2);
        for (uint256 i; i < 2; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(pks[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }
        if (isForce) oracle.forceAUMUpdate(strategy, ids, vals, hubAssets, ts, proofs);
        else oracle.forwardAUM(strategy, ids, vals, hubAssets, ts, proofs);
    }

    /// B2.RR6 (PR336 review): after every accepted report the cached aggregate must equal what the
    /// registry actually accepted - the cap numerator and denominator derive from one snapshot.
    function _assertAccountingConsistent() internal view {
        assertEq(
            oracle.latestReport(strategy).totalCrossChainAssets,
            registry.getCrossChainAUM(strategy),
            "cached cross-chain total != registry-accepted AUM"
        );
    }

    function _reportPendingZero() internal {
        // Cover the single Pending position with value 0 and hubAssets 1000 so a report commits.
        bytes32[] memory allIds = registry.getPositionIds(strategy);
        uint256[] memory vals = new uint256[](allIds.length);
        // all zeros
        uint256 ts = block.timestamp;
        bytes32 structHash = keccak256(
            abi.encode(
                UPDATE_AUM_TYPEHASH,
                strategy,
                keccak256(abi.encodePacked(allIds)),
                keccak256(abi.encodePacked(vals)),
                uint256(1000e18),
                ts,
                oracle.noncePerStrategy(strategy)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", oracle.domainSeparator(), structHash));
        bytes[] memory proofs = new bytes[](2);
        for (uint256 i; i < 2; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(pks[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }
        oracle.forwardAUM(strategy, allIds, vals, 1000e18, ts, proofs);
    }
}
