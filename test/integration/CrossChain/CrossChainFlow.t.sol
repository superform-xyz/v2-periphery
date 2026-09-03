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
import { MockAggregatorLite } from "../../unit/CrossChain/mocks/MockCapGuardDeps.sol";

/// @notice End-to-end integration of the three cross-chain contracts wired together via a lite
///         SuperGovernor (roles/validators/registry) and a lite aggregator (isMainManager). Every
///         cross-contract call is real: registry <-> oracle <-> cap guard.
contract CrossChainFlowTest is Test {
    CrossChainPositionRegistry internal registry;
    CrossChainAUMOracle internal oracle;
    CrossChainPositionCapGuard internal guard;
    MockGovernorLite internal governor;
    MockAggregatorLite internal aggregator;

    address internal strategy = makeAddr("strategy");
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

        // Force-book a real >50% drawdown to 10; breaker clears; cap guard works again.
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
