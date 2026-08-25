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
                              REGISTRATION
    //////////////////////////////////////////////////////////////*/

    function _registerSuperVault(uint256 amount, uint256 shares) internal returns (bytes32 id) {
        vm.prank(registrar);
        id = registry.registerPosition(
            strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, amount, shares
        );
    }

    function test_RegisterSuperVault_StartsPending() public {
        bytes32 id = _registerSuperVault(100e18, 95e18);
        ICrossChainPositionRegistry.CrossChainPosition memory p = registry.positions(id);
        assertEq(uint256(p.status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
        assertEq(p.destinationVault, destVault);
        assertEq(p.deployedAmount, 100e18);
        assertEq(p.sharesHeld, 95e18);
        assertEq(registry.getPositionIds(strategy).length, 1);
    }

    function test_RegisterIdle_OK() public {
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.Idle, address(0), 50e18, 0
        );
        assertEq(uint256(registry.positions(id).status), uint256(ICrossChainPositionRegistry.PositionStatus.Pending));
    }

    function test_Register_RevertUnauthorizedRegistrar() public {
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_REGISTRAR.selector);
        registry.registerPosition(
            strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, 1e18, 1e18
        );
    }

    function test_Register_RevertUnapprovedVault() public {
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.DESTINATION_NOT_APPROVED.selector);
        registry.registerPosition(
            strategy, CHAIN_B, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, 1e18, 1e18
        );
    }

    function test_Register_RevertSuperVaultWithZeroShares() public {
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.INVALID_KIND_CONFIG.selector);
        registry.registerPosition(
            strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, 1e18, 0
        );
    }

    function test_Register_RevertIdleWithVault() public {
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.INVALID_KIND_CONFIG.selector);
        registry.registerPosition(strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.Idle, destVault, 1e18, 0);
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
        vm.prank(registrar);
        vm.expectRevert(ICrossChainPositionRegistry.MAX_POSITIONS_REACHED.selector);
        registry.registerPosition(
            strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, 1e18, 1e18
        );
    }

    /*//////////////////////////////////////////////////////////////
                           ORACLE SYNC / LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    function _sync(bytes32 id, uint256 value) internal {
        vm.prank(aumOracle);
        registry.syncPositionFromReport(strategy, id, value, block.timestamp);
    }

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

    /*//////////////////////////////////////////////////////////////
                           BRIDGED-OUT ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function test_BridgedOut_RecordRequiresAuthorizedHook() public {
        vm.expectRevert(ICrossChainPositionRegistry.UNAUTHORIZED_BRIDGE_HOOK.selector);
        registry.recordBridgedOut(strategy, CHAIN_A, 10e18);
    }

    function test_BridgedOut_CountedInEffectiveExposureThenReleasedOnConfirm() public {
        vm.prank(bridgeHook);
        registry.recordBridgedOut(strategy, CHAIN_A, 100e18);
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 100e18);
        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 100e18);

        bytes32 id = _registerSuperVault(100e18, 95e18);
        _sync(id, 101e18); // Pending -> Active releases the in-flight reservation

        assertEq(registry.bridgedOut(strategy), 0, "in-flight released on confirmation");
        // Effective exposure now reflects the confirmed value only (no double count).
        assertEq(registry.getEffectiveCrossChainExposure(strategy), 101e18);
        assertEq(registry.getEffectiveChainExposure(strategy, CHAIN_A), 101e18);
    }

    function test_BridgedOut_ReleaseIsChainIsolated() public {
        // P2-2: releasing a CHAIN_A position must not touch CHAIN_B's in-flight reservation.
        capGuard.setApproved(strategy, CHAIN_B, destVault, true);
        vm.startPrank(bridgeHook);
        registry.recordBridgedOut(strategy, CHAIN_A, 100e18);
        registry.recordBridgedOut(strategy, CHAIN_B, 100e18);
        vm.stopPrank();
        assertEq(registry.bridgedOut(strategy), 200e18);

        bytes32 idA = _registerSuperVault(100e18, 95e18); // CHAIN_A
        _sync(idA, 100e18); // confirm -> releases CHAIN_A's 100

        assertEq(registry.bridgedOutByChain(strategy, CHAIN_A), 0, "A released");
        assertEq(registry.bridgedOutByChain(strategy, CHAIN_B), 100e18, "B untouched");
        assertEq(registry.bridgedOut(strategy), 100e18, "global == sum(per-chain)");
    }

    function test_BridgedOut_ReleaseClampedToChainOutstanding() public {
        // P2-2: a position whose deployedAmount exceeds its chain's outstanding in-flight releases
        // only the outstanding amount (no underflow, no consuming another dimension).
        vm.prank(bridgeHook);
        registry.recordBridgedOut(strategy, CHAIN_A, 100e18);
        vm.prank(registrar);
        bytes32 id = registry.registerPosition(
            strategy, CHAIN_A, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, 200e18, 95e18
        );
        _sync(id, 100e18); // deployedAmount 200 > outstanding 100 -> release clamps to 100
        assertEq(registry.bridgedOut(strategy), 0);
        assertEq(registry.bridgedOutByChain(strategy, CHAIN_A), 0);
    }

    function test_BridgedOut_ReleasedOnInvalidation() public {
        vm.prank(bridgeHook);
        registry.recordBridgedOut(strategy, CHAIN_A, 100e18);
        bytes32 id = _registerSuperVault(100e18, 95e18);
        vm.warp(block.timestamp + registry.POSITION_CONFIRMATION_TIMEOUT() + 1);
        _sync(id, 0); // timed out -> Invalidated, releases reservation
        assertEq(registry.bridgedOut(strategy), 0);
    }

    /*//////////////////////////////////////////////////////////////
                       EXPIRED-PENDING CLEANUP (P2-1)
    //////////////////////////////////////////////////////////////*/

    function test_InvalidateExpiredPending_ReleasesAndEvicts() public {
        vm.prank(bridgeHook);
        registry.recordBridgedOut(strategy, CHAIN_A, 100e18);
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
        vm.prank(registrar);
        bytes32 idB = registry.registerPosition(
            strategy, CHAIN_B, ICrossChainPositionRegistry.PositionKind.SuperVault, destVault, 40e18, 40e18
        );
        _sync(idB, 40e18);

        assertEq(registry.getChainExposure(strategy, CHAIN_A), 100e18);
        assertEq(registry.getChainExposure(strategy, CHAIN_B), 40e18);
        assertEq(registry.getCrossChainAUM(strategy), 140e18);
    }
}
