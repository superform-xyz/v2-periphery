// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { CrossChainPositionRegistry } from "../../../src/CrossChain/CrossChainPositionRegistry.sol";
import { ICrossChainPositionRegistry } from "../../../src/interfaces/CrossChain/ICrossChainPositionRegistry.sol";
import { MockGovernorLite } from "./mocks/MockGovernorLite.sol";
import { MockCapGuardLite } from "./mocks/MockCapGuardLite.sol";

contract CrossChainPositionRegistryTest is Test {
    CrossChainPositionRegistry internal registry;
    MockGovernorLite internal governor;
    MockCapGuardLite internal capGuard;

    address internal registrar = makeAddr("registrar");
    address internal aumOracle = makeAddr("aumOracle");
    address internal bridgeHook = makeAddr("bridgeHook");
    address internal strategy = makeAddr("strategy");
    address internal destVault = makeAddr("destVault");

    uint64 internal constant CHAIN_A = 8453;
    uint64 internal constant CHAIN_B = 42_161;

    bytes32 internal constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");
    bytes32 internal constant CROSS_CHAIN_CAP_GUARD = keccak256("CROSS_CHAIN_CAP_GUARD");

    function setUp() public {
        governor = new MockGovernorLite();
        capGuard = new MockCapGuardLite();
        registry = new CrossChainPositionRegistry(address(governor));

        governor.setAddress(CROSS_CHAIN_AUM_ORACLE, aumOracle);
        governor.setAddress(CROSS_CHAIN_CAP_GUARD, address(capGuard));
        // This test contract acts as governor for setRegistrar / setBridgeHookAuthorization.
        governor.grantRole(governor.GOVERNOR_ROLE(), address(this));

        registry.setRegistrar(strategy, registrar);
        registry.setBridgeHookAuthorization(bridgeHook, true);

        // Approve a SuperVault destination and an idle-hold escrow on CHAIN_A.
        capGuard.setApproved(strategy, CHAIN_A, destVault, true);
        capGuard.setApproved(strategy, CHAIN_A, address(0), true);
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS (K1)
    //////////////////////////////////////////////////////////////*/

    /// @dev Mint a cap-hook reservation for `strategy` (the K1 precondition of any registration).
    function _reserve(uint64 chainId, address vault, uint256 amount) internal returns (bytes32 reservationId) {
        return _reserveFor(strategy, chainId, vault, amount);
    }

    function _reserveFor(
        address strategy_,
        uint64 chainId,
        address vault,
        uint256 amount
    )
        internal
        returns (bytes32 reservationId)
    {
        vm.prank(bridgeHook);
        reservationId = registry.recordBridgedOut(strategy_, chainId, vault, amount);
    }

    function _registerSuperVault(uint256 amount, uint256 shares) internal returns (bytes32 id) {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, amount);
        vm.prank(registrar);
        id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, shares
        );
    }

    function _sync(bytes32 id, uint256 value) internal {
        vm.prank(aumOracle);
        registry.syncPositionFromReport(strategy, id, value, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                              REGISTRATION
    //////////////////////////////////////////////////////////////*/

    function test_RegisterSuperVault_StartsPending() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        ICrossChainPositionRegistry.CrossChainPosition memory p = registry.positions(id);
        assertEq(uint256(p.status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
        assertEq(p.destinationVault, destVault);
        assertEq(p.deployedAmount, 100e18, "deployedAmount = reservation amount, never registrar-supplied");
        assertEq(p.sharesHeld, 95e18);
        assertEq(registry.getPositionIds(strategy).length, 1);
    }

    function test_RegisterIdle_OK() public {
        bytes32 reservationId = _reserve(CHAIN_A, address(0), 50e18);
        vm.prank(registrar);
        bytes32 id =
            registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.Idle, 0);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
        assertEq(registry.positions(id).deployedAmount, 50e18);
    }

    function test_Register_RevertUnauthorizedRegistrar() public {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 1e18);
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_REGISTRAR.selector);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 1e18);
    }

    function test_Register_RevertUnapprovedVault() public {
        // The reservation names an (unapproved) CHAIN_B destination; registration re-checks the
        // allowlist so an approval revoked between send and registration blocks the position.
        bytes32 reservationId = _reserve(CHAIN_B, destVault, 1e18);
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.DESTINATION_NOT_APPROVED.selector);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 1e18);
    }

    function test_Register_RevertSuperVaultWithZeroShares() public {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 1e18);
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.RESERVATION_KIND_MISMATCH.selector);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 0);
    }

    function test_Register_RevertIdleKindOnVaultReservation() public {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 1e18);
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.RESERVATION_KIND_MISMATCH.selector);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.Idle, 0);
    }

    function test_Register_SaltedIdsAreUnique() public {
        bytes32 a = _registerSuperVault(10e18, 10e18);
        bytes32 b = _registerSuperVault(10e18, 10e18);
        assertTrue(a != b, "same-destination positions must get distinct ids");
        assertEq(registry.getPositionIds(strategy).length, 2);
    }

    function test_Register_RevertMaxPositions() public {
        uint256 max = registry.MAX_POSITIONS_PER_STRATEGY();
        for (uint256 i; i < max; ++i) {
            _registerSuperVault(1e18, 1e18);
        }
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 1e18);
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.MAX_POSITIONS_REACHED.selector);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 1e18);
    }

    /*//////////////////////////////////////////////////////////////
                       RESERVATION LIFECYCLE (K1)
    //////////////////////////////////////////////////////////////*/

    function test_Reservation_RevertRegisterWithUnknownReservation() public {
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.RESERVATION_NOT_CONSUMABLE.selector);
        registry.registerPosition(
            strategy, keccak256("no-such-reservation"), ICrossChainPositionRegistry.PositionKind.SuperVault, 1e18
        );
    }

    function test_Reservation_RevertDoubleConsume() public {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 10e18);
        vm.prank(registrar);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 10e18);
        // A second registration cannot bind the same reservation.
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.RESERVATION_NOT_CONSUMABLE.selector);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 10e18);
    }

    function test_Reservation_ForeignStrategyCannotConsume() public {
        // Strategy B's registrar cannot consume A's reservation, even for B.
        address strategyB = makeAddr("strategyB");
        address registrarB = makeAddr("registrarB");
        registry.setRegistrar(strategyB, registrarB);
        capGuard.setApproved(strategyB, CHAIN_A, destVault, true);

        bytes32 reservationId = _reserve(CHAIN_A, destVault, 10e18); // owned by A
        vm.prank(registrarB);
        vm.expectRevert(ICrossChainPositionRegistry.RESERVATION_NOT_CONSUMABLE.selector);
        registry.registerPosition(strategyB, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 10e18);
    }

    function test_Reservation_ExpiredReleasePermissionless() public {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 100e18);
        assertEq(registry.bridgedOut(strategy), 100e18);

        // Not expired yet.
        vm.expectRevert(ICrossChainPositionRegistry.RESERVATION_NOT_EXPIRED.selector);
        registry.releaseExpiredReservation(reservationId);

        vm.warp(block.timestamp + registry.RESERVATION_TIMEOUT() + 1);
        registry.releaseExpiredReservation(reservationId); // permissionless
        assertEq(registry.bridgedOut(strategy), 0, "expired reservation uncounted");
        assertEq(
            uint256(registry.reservations(reservationId).status),
            uint256(ICrossChainPositionRegistry.ReservationStatus.Released)
        );
    }

    /// K1: a fill that lands AFTER the reservation timed out and was released is still trackable —
    /// consuming the Released reservation re-counts it, so landed capital is never invisible.
    function test_Reservation_LateFillReconsumesReleasedReservation() public {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 100e18);
        vm.warp(block.timestamp + registry.RESERVATION_TIMEOUT() + 1);
        registry.releaseExpiredReservation(reservationId);
        assertEq(registry.bridgedOut(strategy), 0);

        // The slow bridge fills later; registrar registers against the SAME reservation.
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );
        assertEq(registry.bridgedOut(strategy), 100e18, "re-consume re-counts the exposure");

        // Confirmation settles the same reservation terminally.
        _sync(id, 100e18);
        assertEq(registry.bridgedOut(strategy), 0);
        assertEq(
            uint256(registry.reservations(reservationId).status),
            uint256(ICrossChainPositionRegistry.ReservationStatus.Settled)
        );
    }

    function test_Reservation_SettledNeverReconsumable() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        bytes32 reservationId = registry.positions(id).reservationId;
        _sync(id, 100e18); // confirm -> Settled

        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.RESERVATION_NOT_CONSUMABLE.selector);
        registry.registerPosition(strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18);
    }

    /// K1: after a POSITION invalidation (registered but never confirmed) the reservation is
    /// Released, so a late fill can still be registered against it.
    function test_Reservation_ReconsumableAfterPositionInvalidation() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        bytes32 reservationId = registry.positions(id).reservationId;
        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);
        registry.invalidateExpiredPending(strategy, id);
        assertEq(registry.bridgedOut(strategy), 0);

        vm.prank(registrar);
        bytes32 id2 = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );
        assertTrue(id2 != id, "fresh position id");
        assertEq(registry.bridgedOut(strategy), 100e18, "re-counted until confirmed");
    }

    /*//////////////////////////////////////////////////////////////
                           ORACLE SYNC / LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    function test_Sync_RevertNotOracle() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_AUM_ORACLE.selector);
        registry.syncPositionFromReport(strategy, id, 100e18, block.timestamp);
    }

    function test_Sync_PendingNonzeroConfirmsActive() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        _sync(id, 101e18);
        ICrossChainPositionRegistry.CrossChainPosition memory p = registry.positions(id);
        assertEq(uint256(p.status), uint256(ICrossChainPositionRegistry.PositionStatus.Active));
        assertEq(p.lastReportedValue, 101e18);
        assertEq(registry.getCrossChainAUM(strategy), 101e18);
    }

    function test_Sync_PendingZeroStaysPending() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        _sync(id, 0);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
        assertEq(registry.getCrossChainAUM(strategy), 0);
    }

    function test_Sync_PendingPastTimeoutInvalidatesAndEvicts() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);
        _sync(id, 101e18); // even a nonzero value cannot resurrect a timed-out position
        assertEq(
            uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Invalidated)
        );
        assertEq(registry.getPositionIds(strategy).length, 0, "evicted from set");
    }

    function test_Sync_ExitedIsSkippedNotReverted() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        _sync(id, 100e18); // Active
        vm.prank(registrar);
        registry.beginPositionExit(strategy, id);
        _sync(id, 0); // drained
        vm.prank(registrar);
        registry.deregisterPosition(strategy, id); // Exited + evicted
        // A late report referencing the exited id must be a no-op, not a revert.
        _sync(id, 100e18);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Exited));
    }

    /*//////////////////////////////////////////////////////////////
                              EXIT PATH
    //////////////////////////////////////////////////////////////*/

    function test_BeginExit_RevertIfNotActive() public {
        bytes32 id = _registerSuperVault(100e18, 95e18); // Pending
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.INVALID_POSITION_STATUS.selector);
        registry.beginPositionExit(strategy, id);
    }

    function test_Deregister_RevertIfNotDrained() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        _sync(id, 100e18); // Active
        vm.prank(registrar);
        registry.beginPositionExit(strategy, id);
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.POSITION_NOT_DRAINED.selector);
        registry.deregisterPosition(strategy, id);
    }

    function test_Deregister_OKWhenDrained() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        _sync(id, 100e18);
        vm.prank(registrar);
        registry.beginPositionExit(strategy, id);
        _sync(id, 0); // oracle-confirmed drain
        vm.prank(registrar);
        registry.deregisterPosition(strategy, id);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Exited));
        assertEq(registry.getPositionIds(strategy).length, 0);
    }

    /// B3 (PR336 review): a registrar authorized for strategy A must not be able to transition a
    /// position owned by strategy B, even by passing A to the auth modifier.
    function test_BeginExit_RevertForeignStrategyPosition() public {
        // Strategy B with its own registrar and an Active position.
        address strategyB = makeAddr("strategyB");
        address registrarB = makeAddr("registrarB");
        registry.setRegistrar(strategyB, registrarB);
        capGuard.setApproved(strategyB, CHAIN_A, destVault, true);
        bytes32 resB = _reserveFor(strategyB, CHAIN_A, destVault, 100e18);
        vm.prank(registrarB);
        bytes32 idB =
            registry.registerPosition(strategyB, resB, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18);
        vm.prank(aumOracle);
        registry.syncPositionFromReport(strategyB, idB, 100e18, block.timestamp); // Active

        // Registrar A passes its own strategy but B's position id.
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.POSITION_STRATEGY_MISMATCH.selector);
        registry.beginPositionExit(strategy, idB);

        // And the reverse direction is equally rejected.
        bytes32 idA = _registerSuperVault(100e18, 95e18);
        _sync(idA, 100e18); // Active
        vm.prank(registrarB);
        vm.expectRevert(ICrossChainPositionRegistry.POSITION_STRATEGY_MISMATCH.selector);
        registry.beginPositionExit(strategyB, idA);
    }

    /// B3: cross-strategy deregistration must revert (no Exited tombstones in another strategy's
    /// live set, no slot consumption).
    function test_Deregister_RevertForeignStrategyPosition() public {
        address strategyB = makeAddr("strategyB");
        address registrarB = makeAddr("registrarB");
        registry.setRegistrar(strategyB, registrarB);
        capGuard.setApproved(strategyB, CHAIN_A, destVault, true);
        bytes32 resB = _reserveFor(strategyB, CHAIN_A, destVault, 100e18);
        vm.prank(registrarB);
        bytes32 idB =
            registry.registerPosition(strategyB, resB, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18);
        vm.prank(aumOracle);
        registry.syncPositionFromReport(strategyB, idB, 100e18, block.timestamp); // Active
        vm.prank(registrarB);
        registry.beginPositionExit(strategyB, idB);
        vm.prank(aumOracle);
        registry.syncPositionFromReport(strategyB, idB, 0, block.timestamp); // drained

        // Registrar A cannot deregister B's drained position through its own authorization.
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.POSITION_STRATEGY_MISMATCH.selector);
        registry.deregisterPosition(strategy, idB);

        // B's set is intact and B's registrar can still complete the exit.
        assertEq(registry.getPositionIds(strategyB).length, 1);
        vm.prank(registrarB);
        registry.deregisterPosition(strategyB, idB);
        assertEq(registry.getPositionIds(strategyB).length, 0);
    }

    /*//////////////////////////////////////////////////////////////
                           BRIDGED-OUT ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function test_BridgedOut_RecordRequiresAuthorizedHook() public {
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_BRIDGE_HOOK.selector);
        registry.recordBridgedOut(strategy, CHAIN_A, destVault, 10e18);
    }

    function test_BridgedOut_CountedInEffectiveExposureThenReleasedOnConfirm() public {
        bytes32 reservationId = _reserve(CHAIN_A, destVault, 100e18);
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 100e18);
        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 100e18);

        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, reservationId, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18
        );
        _sync(id, 101e18); // Pending -> Active settles the reservation

        assertEq(registry.bridgedOut(strategy), 0, "in-flight released on confirmation");
        // Effective exposure now reflects the confirmed value only (no double count).
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 101e18);
        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 101e18);
    }

    function test_BridgedOut_ReleaseIsChainIsolated() public {
        // Settling a CHAIN_A position must not touch CHAIN_B's in-flight reservation.
        capGuard.setApproved(strategy, CHAIN_B, destVault, true);
        bytes32 resA = _reserve(CHAIN_A, destVault, 100e18);
        _reserve(CHAIN_B, destVault, 100e18);
        assertEq(registry.bridgedOut(strategy), 200e18);

        vm.prank(registrar);
        bytes32 idA =
            registry.registerPosition(strategy, resA, ICrossChainPositionRegistry.PositionKind.SuperVault, 95e18);
        _sync(idA, 100e18); // confirm -> settles CHAIN_A's reservation only

        assertEq(registry.bridgedOutByChain(strategy, CHAIN_A), 0, "A released");
        assertEq(registry.bridgedOutByChain(strategy, CHAIN_B), 100e18, "B untouched");
        assertEq(registry.bridgedOut(strategy), 100e18, "global == sum(per-chain)");
    }

    function test_BridgedOut_ReleasedOnInvalidation() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);
        _sync(id, 0); // timed out -> Invalidated, releases the reservation
        assertEq(registry.bridgedOut(strategy), 0);
    }

    /*//////////////////////////////////////////////////////////////
                       EXPIRED-PENDING CLEANUP (P2-1)
    //////////////////////////////////////////////////////////////*/

    function test_InvalidateExpiredPending_ReleasesAndEvicts() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);

        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);
        registry.invalidateExpiredPending(strategy, id); // permissionless

        assertEq(
            uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Invalidated)
        );
        assertEq(registry.getPositionIds(strategy).length, 0, "evicted");
        assertEq(registry.bridgedOut(strategy), 0, "in-flight released");
    }

    function test_InvalidateExpiredPending_RevertNotExpired() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        vm.expectRevert(ICrossChainPositionRegistry.POSITION_NOT_EXPIRED.selector);
        registry.invalidateExpiredPending(strategy, id);
    }

    function test_InvalidateExpiredPending_RevertNotPending() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        _sync(id, 100e18); // Active
        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);
        vm.expectRevert(ICrossChainPositionRegistry.INVALID_POSITION_STATUS.selector);
        registry.invalidateExpiredPending(strategy, id);
    }

    /*//////////////////////////////////////////////////////////////
                     FOREIGN-STRATEGY SYNC SKIP (P2-3)
    //////////////////////////////////////////////////////////////*/

    function test_Sync_ForeignStrategyIsSkipped() public {
        bytes32 id = _registerSuperVault(100e18, 95e18); // owned by `strategy`
        address other = makeAddr("otherStrategy");
        // A report claiming `other` owns this id must be a no-op, not corrupt the position.
        vm.prank(aumOracle);
        registry.syncPositionFromReport(other, id, 999e18, block.timestamp);
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
        assertEq(registry.positions(id).lastReportedValue, 0, "value untouched");
    }

    /*//////////////////////////////////////////////////////////////
                              ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    function test_SetRegistrar_RevertNonGovernor() public {
        vm.prank(makeAddr("rando"));
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_CONFIG.selector);
        registry.setRegistrar(strategy, makeAddr("newReg"));
    }

    function test_PerChainExposure_IsChainScoped() public {
        capGuard.setApproved(strategy, CHAIN_B, destVault, true);
        // position on CHAIN_A
        bytes32 idA = _registerSuperVault(100e18, 95e18);
        _sync(idA, 100e18);
        // position on CHAIN_B
        bytes32 resB = _reserve(CHAIN_B, destVault, 40e18);
        vm.prank(registrar);
        bytes32 idB =
            registry.registerPosition(strategy, resB, ICrossChainPositionRegistry.PositionKind.SuperVault, 40e18);
        _sync(idB, 40e18);

        assertEq(registry.getChainExposure(strategy, CHAIN_A), 100e18);
        assertEq(registry.getChainExposure(strategy, CHAIN_B), 40e18);
        assertEq(registry.getCrossChainAUM(strategy), 140e18);
    }
}
