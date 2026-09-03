// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { CrossChainAUMOracle } from "../../../src/CrossChain/CrossChainAUMOracle.sol";
import { ICrossChainAUMOracle } from "../../../src/interfaces/CrossChain/ICrossChainAUMOracle.sol";
import { ICrossChainPositionRegistry } from "../../../src/interfaces/CrossChain/ICrossChainPositionRegistry.sol";
import { MockGovernorLite } from "./mocks/MockGovernorLite.sol";
import { MockRegistryLite } from "./mocks/MockRegistryLite.sol";

contract CrossChainAUMOracleTest is Test {
    CrossChainAUMOracle internal oracle;
    MockGovernorLite internal governor;
    MockRegistryLite internal registry;

    address internal strategy = makeAddr("strategy");

    // validators (sorted by address at setUp)
    uint256[] internal pks;
    address[] internal signers;

    bytes32 internal constant CROSS_CHAIN_POSITION_REGISTRY = keccak256("CROSS_CHAIN_POSITION_REGISTRY");
    bytes32 internal constant UPDATE_AUM_TYPEHASH = keccak256(
        "UpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );
    bytes32 internal constant FORCE_UPDATE_AUM_TYPEHASH = keccak256(
        "ForceUpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );

    function setUp() public {
        governor = new MockGovernorLite();
        registry = new MockRegistryLite();
        oracle = new CrossChainAUMOracle(address(governor), "SuperformCrossChainAUM", "1");

        governor.setAddress(CROSS_CHAIN_POSITION_REGISTRY, address(registry));
        governor.grantRole(governor.ORACLE_MANAGER_ROLE(), address(this));

        // 3 validators, quorum 2, sorted ascending by address
        uint256[] memory raw = new uint256[](3);
        raw[0] = 0xA11CE;
        raw[1] = 0xB0B;
        raw[2] = 0xC0FFEE;
        for (uint256 i; i < 3; ++i) {
            governor.setValidator(vm.addr(raw[i]), true);
        }
        governor.setQuorum(2);
        // sort (pk, addr) ascending by addr
        for (uint256 i; i < 3; ++i) {
            for (uint256 j = i + 1; j < 3; ++j) {
                if (vm.addr(raw[j]) < vm.addr(raw[i])) {
                    (raw[i], raw[j]) = (raw[j], raw[i]);
                }
            }
            pks.push(raw[i]);
            signers.push(vm.addr(raw[i]));
        }

        _setDefaultConfig();
        // B2: the oracle validates position ownership; mock positions must carry the strategy.
        registry.setDefaultStrategy(strategy);
        // In reality the bridged-out capital is recorded before the first report; set it high so
        // the SEC-16 zero-crossing anchor admits bootstrap reports in these oracle-focused tests.
        registry.setBridgedOut(strategy, 1_000_000e18);
        vm.warp(1_000_000);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _setDefaultConfig() internal {
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
    }

    function _digest(
        bytes32[] memory ids,
        uint256[] memory vals,
        uint256 hubAssets,
        uint256 ts,
        uint256 nonce,
        bool isForce
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(
            abi.encode(
                isForce ? FORCE_UPDATE_AUM_TYPEHASH : UPDATE_AUM_TYPEHASH,
                strategy,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(vals)),
                hubAssets,
                ts,
                nonce
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", oracle.domainSeparator(), structHash));
    }

    function _proofs(bytes32 digest, uint256 n) internal view returns (bytes[] memory proofs) {
        proofs = new bytes[](n);
        for (uint256 i; i < n; ++i) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(pks[i], digest);
            proofs[i] = abi.encodePacked(r, s, v);
        }
    }

    function _oneActivePosition(uint256 currentValue) internal returns (bytes32 id) {
        id = keccak256("pos1");
        registry.addPosition(id, ICrossChainPositionRegistry.PositionStatus.Active, block.timestamp - 1, currentValue);
    }

    function _report(
        bytes32 id,
        uint256 value,
        uint256 hubAssets,
        uint256 ts,
        bool isForce
    )
        internal
        view
        returns (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs)
    {
        ids = new bytes32[](1);
        ids[0] = id;
        vals = new uint256[](1);
        vals[0] = value;
        proofs = _proofs(_digest(ids, vals, hubAssets, ts, oracle.noncePerStrategy(strategy), isForce), 2);
    }

    /*//////////////////////////////////////////////////////////////
                                CONFIG
    //////////////////////////////////////////////////////////////*/

    function test_SetConfig_RevertNonOracleManager() public {
        vm.prank(makeAddr("rando"));
        vm.expectRevert(ICrossChainAUMOracle.UNAUTHORIZED_CONFIG.selector);
        _setDefaultConfig();
    }

    function test_SetConfig_RevertBadBounds() public {
        ICrossChainAUMOracle.AUMOracleConfig memory c = ICrossChainAUMOracle.AUMOracleConfig({
            maxStaleness: 1 hours,
            minUpdateInterval: 0, // below MIN_UPDATE_INTERVAL
            deviationThreshold: 0.5e18,
            perPositionDeviationThreshold: 0.75e18,
            consistencyToleranceBps: 100,
            maxConsecutiveDeviationBreaches: 2
        });
        vm.expectRevert(ICrossChainAUMOracle.INVALID_CONFIG.selector);
        oracle.setAUMOracleConfig(strategy, c);
    }

    /*//////////////////////////////////////////////////////////////
                             FORWARD (happy)
    //////////////////////////////////////////////////////////////*/

    function test_ForwardAUM_HappyPath() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 110e18, 20e18, ts, false);

        oracle.forwardAUM(strategy, ids, vals, 20e18, ts, proofs);

        assertEq(oracle.getTotalAUM(strategy), 130e18, "hubAssets + aggregate");
        assertTrue(oracle.isAUMFresh(strategy));
        assertEq(registry.syncedValue(id), 110e18, "position synced");
        assertEq(oracle.noncePerStrategy(strategy), 1);
    }

    function test_ForwardAUM_RevertQuorumNotMet() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = id;
        uint256[] memory vals = new uint256[](1);
        vals[0] = 100e18;
        bytes[] memory proofs = _proofs(_digest(ids, vals, 0, ts, 0, false), 1); // only 1 < quorum 2
        vm.expectRevert(ICrossChainAUMOracle.QUORUM_NOT_MET.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForwardAUM_RevertIncompleteReport() public {
        // Two Active positions exist but the report covers only one.
        bytes32 id1 = _oneActivePosition(100e18);
        bytes32 id2 = keccak256("pos2");
        registry.addPosition(id2, ICrossChainPositionRegistry.PositionStatus.Active, block.timestamp - 1, 50e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id1, 100e18, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.INCOMPLETE_REPORT.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForwardAUM_RevertUnconfigured() public {
        address other = makeAddr("otherStrategy");
        bytes32 id = keccak256("posX");
        registry.addPosition(id, ICrossChainPositionRegistry.PositionStatus.Active, block.timestamp - 1, 1e18);
        uint256 ts = block.timestamp;
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = id;
        uint256[] memory vals = new uint256[](1);
        vals[0] = 1e18;
        // sign for `other` strategy
        bytes32 structHash = keccak256(
            abi.encode(
                UPDATE_AUM_TYPEHASH,
                other,
                keccak256(abi.encodePacked(ids)),
                keccak256(abi.encodePacked(vals)),
                uint256(0),
                ts,
                uint256(0)
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", oracle.domainSeparator(), structHash));
        bytes[] memory proofs = _proofs(digest, 2);
        vm.expectRevert(ICrossChainAUMOracle.UNCONFIGURED_STRATEGY.selector);
        oracle.forwardAUM(other, ids, vals, 0, ts, proofs);
    }

    function test_ForwardAUM_RevertQuorumZero() public {
        governor.setQuorum(0); // P3-2: unset quorum must not collapse to 1-of-N
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.QUORUM_NOT_MET.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForwardAUM_HubAssetsDeviationSoftFails() public {
        bytes32 id = _oneActivePosition(100e18);
        // seed: value 100, hubAssets 100 -> total AUM 200 (bootstrap, hubAssets unbounded once)
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 100e18, ts, false);
        oracle.forwardAUM(strategy, ids, vals, 100e18, ts, proofs);
        assertEq(oracle.getTotalAUM(strategy), 200e18);

        // P2-4: hubAssets jumps 100 -> 300 (>50%) while the position value is unchanged -> soft-fail.
        vm.warp(block.timestamp + 2 minutes);
        ts = block.timestamp;
        (ids, vals, proofs) = _report(id, 100e18, 300e18, ts, false);
        vm.expectEmit(true, false, false, true);
        emit ICrossChainAUMOracle.AUMDeviationExceeded(strategy, 100e18, 300e18);
        oracle.forwardAUM(strategy, ids, vals, 300e18, ts, proofs);
        assertEq(oracle.getTotalAUM(strategy), 200e18, "inflated hubAssets rejected");
    }

    function test_ForwardAUM_HubAssetsWithinBoundCommits() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 100e18, ts, false);
        oracle.forwardAUM(strategy, ids, vals, 100e18, ts, proofs);

        // hubAssets 100 -> 120 (20% <= 50%) commits.
        vm.warp(block.timestamp + 2 minutes);
        ts = block.timestamp;
        (ids, vals, proofs) = _report(id, 100e18, 120e18, ts, false);
        oracle.forwardAUM(strategy, ids, vals, 120e18, ts, proofs);
        assertEq(oracle.getTotalAUM(strategy), 220e18);
    }

    /*//////////////////////////////////////////////////////////////
                    TIMESTAMP + SIGNER VALIDATION
    //////////////////////////////////////////////////////////////*/

    function test_ForwardAUM_RevertFutureTimestamp() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp + 100;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.FUTURE_TIMESTAMP.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForwardAUM_RevertStaleUpdate() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts1 = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 100e18, ts1, false);
        oracle.forwardAUM(strategy, ids, vals, 100e18, ts1, proofs);
        // resubmit at the same timestamp -> STALE_UPDATE (timestamp must strictly increase)
        (ids, vals, proofs) = _report(id, 100e18, 100e18, ts1, false);
        vm.expectRevert(ICrossChainAUMOracle.STALE_UPDATE.selector);
        oracle.forwardAUM(strategy, ids, vals, 100e18, ts1, proofs);
    }

    function test_ForwardAUM_RevertRateLimited() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts1 = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 100e18, ts1, false);
        oracle.forwardAUM(strategy, ids, vals, 100e18, ts1, proofs);
        // next report 30s later, below the 60s minUpdateInterval
        uint256 ts2 = ts1 + 30;
        vm.warp(ts2);
        (ids, vals, proofs) = _report(id, 100e18, 100e18, ts2, false);
        vm.expectRevert(ICrossChainAUMOracle.RATE_LIMITED.selector);
        oracle.forwardAUM(strategy, ids, vals, 100e18, ts2, proofs);
    }

    function test_ForwardAUM_RevertDataTooStale() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp - 3601; // maxStaleness = 1h
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.DATA_TOO_STALE.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForwardAUM_RevertNonAscendingSigners() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = id;
        uint256[] memory vals = new uint256[](1);
        vals[0] = 100e18;
        bytes32 digest = _digest(ids, vals, 0, ts, 0, false);
        // sign in DESCENDING order (pks[1] then pks[0]) -> INVALID_PROOF
        bytes[] memory proofs = new bytes[](2);
        proofs[0] = _sig(pks[1], digest);
        proofs[1] = _sig(pks[0], digest);
        vm.expectRevert(ICrossChainAUMOracle.INVALID_PROOF.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForwardAUM_RevertInvalidValidator() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = id;
        uint256[] memory vals = new uint256[](1);
        vals[0] = 100e18;
        bytes32 digest = _digest(ids, vals, 0, ts, 0, false);
        bytes[] memory proofs = new bytes[](2);
        proofs[0] = _sig(pks[0], digest);
        proofs[1] = _sig(0xDEAD, digest); // not a registered validator
        vm.expectRevert(ICrossChainAUMOracle.INVALID_VALIDATOR.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function _sig(uint256 pk, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }

    /*//////////////////////////////////////////////////////////////
                    PER-POSITION + ZERO-CROSSING
    //////////////////////////////////////////////////////////////*/

    function test_ForwardAUM_PerPositionDeviationSoftFails() public {
        bytes32 id = _oneActivePosition(100e18); // prev value 100
        uint256 ts = block.timestamp;
        // report 200 -> per-position relDiff 100% > 75% threshold -> soft fail
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 200e18, 0, ts, false);
        vm.expectEmit(true, true, false, true);
        emit ICrossChainAUMOracle.PositionDeviationExceeded(strategy, id, 100e18, 200e18);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
        assertEq(oracle.getTotalAUM(strategy), 0, "not committed");
    }

    function test_ForwardAUM_ZeroCrossingAnchorRejectsUnbackedBootstrap() public {
        registry.setBridgedOut(strategy, 100e18); // only 100 ever bridged out
        bytes32 id = _oneActivePosition(0); // prev 0 so per-position is skipped
        uint256 ts = block.timestamp;
        // bootstrap report claims 200 cross-chain but only 100 was bridged -> SEC-16 anchor rejects
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 200e18, 0, ts, false);
        vm.expectEmit(true, false, false, true);
        emit ICrossChainAUMOracle.AUMDeviationExceeded(strategy, 0, 200e18);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
        assertEq(oracle.getTotalAUM(strategy), 0);
    }

    function test_ForceUpdate_SkipsHubAssetsDeviation() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 100e18, 100e18, ts, false);
        oracle.forwardAUM(strategy, ids, vals, 100e18, ts, proofs); // seed hubAssets = 100

        // force a large hubAssets move (100 -> 500, >50%) - deviation skipped, commits.
        vm.warp(block.timestamp + 2 minutes);
        ts = block.timestamp;
        (ids, vals, proofs) = _report(id, 100e18, 500e18, ts, true);
        oracle.forceAUMUpdate(strategy, ids, vals, 500e18, ts, proofs);
        assertEq(oracle.getTotalAUM(strategy), 600e18, "force books the large hubAssets move");
    }

    /*//////////////////////////////////////////////////////////////
                       DEVIATION + BREAKER (SEC-13)
    //////////////////////////////////////////////////////////////*/

    function _seedActiveAggregate(bytes32 id, uint256 value) internal {
        // commit an initial report so current aggregate > 0
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, value, 0, ts, false);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    function test_Deviation_SoftFailConsumesNonceAndDoesNotUpdate() public {
        bytes32 id = _oneActivePosition(100e18);
        _seedActiveAggregate(id, 100e18); // aggregate = 100
        uint256 nonceBefore = oracle.noncePerStrategy(strategy);

        // propose 300 (>50% jump) -> soft fail
        vm.warp(block.timestamp + 2 minutes);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 300e18, 0, ts, false);
        vm.expectEmit(true, false, false, true);
        emit ICrossChainAUMOracle.AUMDeviationExceeded(strategy, 100e18, 300e18);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);

        assertEq(oracle.getTotalAUM(strategy), 100e18, "aggregate unchanged on soft fail");
        assertEq(oracle.noncePerStrategy(strategy), nonceBefore + 1, "nonce consumed");
    }

    function test_Deviation_RepeatedBreachesTripBreakerBlockingFreshness() public {
        bytes32 id = _oneActivePosition(100e18);
        _seedActiveAggregate(id, 100e18);

        // breach #1
        vm.warp(block.timestamp + 2 minutes);
        _softFail(id, 300e18);
        assertFalse(oracle.aumBreakerTripped(strategy));
        assertTrue(oracle.isAUMFresh(strategy));

        // breach #2 -> trips (maxConsecutiveDeviationBreaches = 2)
        vm.warp(block.timestamp + 2 minutes);
        _softFail(id, 300e18);
        assertTrue(oracle.aumBreakerTripped(strategy));
        assertFalse(oracle.isAUMFresh(strategy), "tripped breaker blocks freshness");
    }

    function _softFail(bytes32 id, uint256 value) internal {
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, value, 0, ts, false);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /*//////////////////////////////////////////////////////////////
                          FORCE UPDATE (SEC-13)
    //////////////////////////////////////////////////////////////*/

    function test_ForceUpdate_RevertNonOracleManager() public {
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 10e18, 0, ts, true);
        vm.prank(makeAddr("rando"));
        vm.expectRevert(ICrossChainAUMOracle.UNAUTHORIZED_FORCE_UPDATE.selector);
        oracle.forceAUMUpdate(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForceUpdate_BooksLargeLossAndClearsBreaker() public {
        bytes32 id = _oneActivePosition(100e18);
        _seedActiveAggregate(id, 100e18);

        // trip the breaker with two >50% soft-fails
        vm.warp(block.timestamp + 2 minutes);
        _softFail(id, 300e18);
        vm.warp(block.timestamp + 2 minutes);
        _softFail(id, 300e18);
        assertTrue(oracle.aumBreakerTripped(strategy));

        // force-book a real >50% drawdown to 10 (deviation skipped; consistency band disabled)
        vm.warp(block.timestamp + 2 minutes);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 10e18, 0, ts, true);
        oracle.forceAUMUpdate(strategy, ids, vals, 0, ts, proofs);

        assertEq(oracle.getTotalAUM(strategy), 10e18, "loss booked");
        assertFalse(oracle.aumBreakerTripped(strategy), "breaker cleared");
        assertTrue(oracle.isAUMFresh(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                   B2: CANONICAL REPORT SET (PR336 review)
    //////////////////////////////////////////////////////////////*/

    /// @dev Two-id signed report against the current nonce.
    function _report2(
        bytes32 idA,
        bytes32 idB,
        uint256 valA,
        uint256 valB,
        uint256 hubAssets,
        uint256 ts,
        bool isForce
    )
        internal
        view
        returns (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs)
    {
        ids = new bytes32[](2);
        vals = new uint256[](2);
        (ids[0], ids[1]) = (idA, idB);
        (vals[0], vals[1]) = (valA, valB);
        proofs = _proofs(_digest(ids, vals, hubAssets, ts, oracle.noncePerStrategy(strategy), isForce), 2);
    }

    /// @dev Sort so reports satisfy the strict-ascending rule; values travel with their id.
    function _ascending(
        bytes32 a,
        bytes32 b,
        uint256 va,
        uint256 vb
    )
        internal
        pure
        returns (bytes32, bytes32, uint256, uint256)
    {
        return a < b ? (a, b, va, vb) : (b, a, vb, va);
    }

    /// B2.RR1: an extra id the registry has never seen (with nonzero value) must revert - it can
    /// no longer inflate the cached aggregate while the registry skips it.
    function test_ForwardAUM_RevertExtraUnknownId() public {
        bytes32 idA = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32 i0, bytes32 i1, uint256 v0, uint256 v1) = _ascending(idA, keccak256("fakeId"), 100e18, 50e18);
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report2(i0, i1, v0, v1, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.UNKNOWN_POSITION_ID.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
        assertEq(oracle.getTotalAUM(strategy), 0, "no cached aggregate change");
    }

    /// B2.RR2: an id owned by a different strategy must revert.
    function test_ForwardAUM_RevertForeignStrategyId() public {
        bytes32 idA = _oneActivePosition(100e18);
        bytes32 idForeign = keccak256("foreignPos");
        registry.addPositionFor(
            makeAddr("otherStrategy"),
            idForeign,
            ICrossChainPositionRegistry.PositionStatus.Active,
            block.timestamp - 1,
            50e18
        );
        uint256 ts = block.timestamp;
        (bytes32 i0, bytes32 i1, uint256 v0, uint256 v1) = _ascending(idA, idForeign, 100e18, 50e18);
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report2(i0, i1, v0, v1, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.UNKNOWN_POSITION_ID.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /// B2.RR3: a duplicated active id must revert (strict ascending order forbids it).
    function test_ForwardAUM_RevertDuplicateId() public {
        bytes32 idA = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) =
            _report2(idA, idA, 50e18, 50e18, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.UNSORTED_REPORT.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /// B2: two valid ids in descending order must revert (canonical ordering).
    function test_ForwardAUM_RevertUnsortedIds() public {
        bytes32 idA = _oneActivePosition(100e18);
        bytes32 idB = keccak256("pos2");
        registry.addPosition(idB, ICrossChainPositionRegistry.PositionStatus.Active, block.timestamp - 1, 50e18);
        uint256 ts = block.timestamp;
        (bytes32 lo, bytes32 hi, uint256 vLo, uint256 vHi) = _ascending(idA, idB, 100e18, 50e18);
        // deliberately submit descending
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report2(hi, lo, vHi, vLo, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.UNSORTED_REPORT.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /// B2.RR4: an Exited id (late inclusion) with nonzero value must revert.
    function test_ForwardAUM_RevertExitedId() public {
        bytes32 idA = _oneActivePosition(100e18);
        bytes32 idExited = keccak256("exitedPos");
        registry.addPosition(idExited, ICrossChainPositionRegistry.PositionStatus.Exited, block.timestamp - 1, 0);
        uint256 ts = block.timestamp;
        (bytes32 i0, bytes32 i1, uint256 v0, uint256 v1) = _ascending(idA, idExited, 100e18, 50e18);
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report2(i0, i1, v0, v1, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.UNKNOWN_POSITION_ID.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /// B2.RR4: an expired Pending id must revert (it can only be invalidated, not reported).
    function test_ForwardAUM_RevertExpiredPendingId() public {
        bytes32 idA = _oneActivePosition(100e18);
        bytes32 idExpired = keccak256("expiredPending");
        registry.addPosition(
            idExpired, ICrossChainPositionRegistry.PositionStatus.Pending, block.timestamp - 3 hours, 0
        );
        uint256 ts = block.timestamp;
        (bytes32 i0, bytes32 i1, uint256 v0, uint256 v1) = _ascending(idA, idExpired, 100e18, 50e18);
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report2(i0, i1, v0, v1, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.UNKNOWN_POSITION_ID.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /// B2.RR5: a Pending position registered AT/AFTER the report timestamp cannot be confirmed
    /// by that report.
    function test_ForwardAUM_RevertPendingRegisteredAfterReportTimestamp() public {
        bytes32 idA = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        bytes32 idLate = keccak256("latePending");
        registry.addPosition(idLate, ICrossChainPositionRegistry.PositionStatus.Pending, ts, 0);
        (bytes32 i0, bytes32 i1, uint256 v0, uint256 v1) = _ascending(idA, idLate, 100e18, 50e18);
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report2(i0, i1, v0, v1, 0, ts, false);
        vm.expectRevert(ICrossChainAUMOracle.UNKNOWN_POSITION_ID.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /// B2.MR1.T5: a report longer than the registry position bound must revert.
    function test_ForwardAUM_RevertReportTooLarge() public {
        uint256 n = 65; // MAX_POSITIONS_PER_STRATEGY = 64
        bytes32[] memory ids = new bytes32[](n);
        uint256[] memory vals = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            ids[i] = bytes32(i + 1); // ascending
            vals[i] = 1e18;
        }
        uint256 ts = block.timestamp;
        bytes[] memory proofs = _proofs(_digest(ids, vals, 0, ts, 0, false), 2);
        vm.expectRevert(ICrossChainAUMOracle.REPORT_TOO_LARGE.selector);
        oracle.forwardAUM(strategy, ids, vals, 0, ts, proofs);
    }

    /// B2: the force path enforces the same canonical-set rules.
    function test_ForceUpdate_RevertExtraUnknownId() public {
        bytes32 idA = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32 i0, bytes32 i1, uint256 v0, uint256 v1) = _ascending(idA, keccak256("fakeId"), 100e18, 50e18);
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report2(i0, i1, v0, v1, 0, ts, true);
        vm.expectRevert(ICrossChainAUMOracle.UNKNOWN_POSITION_ID.selector);
        oracle.forceAUMUpdate(strategy, ids, vals, 0, ts, proofs);
    }

    function test_ForceUpdate_NormalSigNotAcceptedAsForce() public {
        // A signature over the UPDATE (non-force) typehash must not satisfy forceAUMUpdate.
        bytes32 id = _oneActivePosition(100e18);
        uint256 ts = block.timestamp;
        (bytes32[] memory ids, uint256[] memory vals, bytes[] memory proofs) = _report(id, 10e18, 0, ts, false); // normal
        // sig
        vm.expectRevert(ICrossChainAUMOracle.INVALID_VALIDATOR.selector);
        oracle.forceAUMUpdate(strategy, ids, vals, 0, ts, proofs);
    }
}
