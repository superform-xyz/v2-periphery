// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { ConfigureSuperVaultCounsel } from "../../../script/ConfigureSuperVaultCounsel.s.sol";

/*//////////////////////////////////////////////////////////////
                              STUBS
//////////////////////////////////////////////////////////////*/

/// @dev Only what the script reads from the executor: the per-strategy key generation, which
///      invalidation bumps. Nothing else about session keys matters to the script.
contract StubExecutor {
    mapping(address strategy => uint88) public generation;

    function getStrategyGeneration(address strategy) external view returns (uint88) {
        return generation[strategy];
    }

    function bump(address strategy) external {
        generation[strategy]++;
    }
}

/// @dev The aggregator surface runAll/run touch, plus `seat` and `wipeSecondaries` to drive the
///      two things a real seating does: install the Counsel as mainManager and wipe secondaries.
contract StubAggregator {
    mapping(address strategy => address) public mainManager;
    mapping(address strategy => address[]) internal _secondaries;
    address[] internal _all;

    function seat(address strategy, address counsel) external {
        mainManager[strategy] = counsel;
        delete _secondaries[strategy]; // a seating wipes every secondary manager
    }

    function wipeSecondaries(address strategy) external {
        delete _secondaries[strategy];
    }

    function addSecondary(address strategy, address manager) external {
        _secondaries[strategy].push(manager);
    }

    function setRegistry(address[] memory all) external {
        _all = all;
    }

    function getMainManager(address strategy) external view returns (address) {
        return mainManager[strategy];
    }

    function getSecondaryManagers(address strategy) external view returns (address[] memory) {
        return _secondaries[strategy];
    }

    function getAllSuperVaultStrategies() external view returns (address[] memory) {
        return _all;
    }

    function isSecondaryManager(address manager, address strategy) external view returns (bool) {
        address[] storage s = _secondaries[strategy];
        for (uint256 i; i < s.length; ++i) {
            if (s[i] == manager) return true;
        }
        return false;
    }
}

/// @dev A Counsel that records the ORDER of the two enrollment calls, which is the property the
///      runbook depends on, and performs their on-chain effects against the stubs.
contract StubCounsel {
    address public immutable OPERATOR;
    address public immutable EXECUTOR;
    address public immutable STRATEGY;
    StubAggregator internal immutable AGG;

    uint256 internal seq;
    uint256 public invalidateCalls;
    uint256 public enrollCalls;
    uint256 public lastInvalidateSeq;
    uint256 public lastEnrollSeq;

    constructor(address operator, address executor, address strategy, StubAggregator agg) {
        OPERATOR = operator;
        EXECUTOR = executor;
        STRATEGY = strategy;
        AGG = agg;
    }

    function invalidateAllSessionKeys() external {
        invalidateCalls++;
        lastInvalidateSeq = ++seq;
        StubExecutor(EXECUTOR).bump(STRATEGY);
    }

    function enrollExecutor() external {
        enrollCalls++;
        lastEnrollSeq = ++seq;
        AGG.addSecondary(STRATEGY, EXECUTOR);
    }
}

/// @dev The real script with its two disk reads replaced by in-memory values, so the full
///      run()/runAll() bodies execute, guard, counters and reverts included.
contract RunAllHarness is ConfigureSuperVaultCounsel {
    address[] internal _fleet;
    string internal _json;

    function setFleet(address[] memory fleet) external {
        _fleet = fleet;
    }

    function setJson(string memory json) external {
        _json = json;
    }

    function _readFleetStrategies(uint256, uint64) internal view override returns (address[] memory) {
        return _fleet;
    }

    function _loadOutputJson(uint256, uint64, string calldata) internal view override returns (string memory) {
        return _json;
    }
}

/*//////////////////////////////////////////////////////////////
                              TESTS
//////////////////////////////////////////////////////////////*/

/// @notice Drives the real run()/runAll() bodies through stubs. Covers the three cases the PR #335
///         script review asked for: a re-run after step 4 leaves keeper keys intact, a re-seat
///         followed by a re-run invalidates the old keys, and every skip path in runAll. It also
///         pins the one case the guard cannot cover, so the precondition is a test and not only
///         a comment.
contract ConfigureSuperVaultCounselRunAllTest is Test {
    uint256 internal constant STAGING = 2;
    uint256 internal constant PROD = 0;
    uint64 internal constant CHAIN = 8453;

    RunAllHarness internal script;
    StubAggregator internal agg;
    StubExecutor internal exec;

    address internal strategyA = makeAddr("strategyA");
    address internal strategyB = makeAddr("strategyB");
    StubCounsel internal counselA;
    StubCounsel internal counselB;

    function setUp() public {
        script = new RunAllHarness();
        agg = new StubAggregator();
        exec = new StubExecutor();
        // the test contract is msg.sender of the script call, which is what `_broadcaster`
        // resolves to for prod/staging, so it must be the operator for the pre-check to pass
        counselA = new StubCounsel(address(this), address(exec), strategyA, agg);
        counselB = new StubCounsel(address(this), address(exec), strategyB, agg);
    }

    /// @dev Output JSON with the aggregator and the given Counsel keys, built in memory.
    function _json(address[] memory strategies, address[] memory counsels) internal returns (string memory out) {
        string memory obj = "out";
        out = vm.serializeAddress(obj, "SuperVaultAggregator", address(agg));
        for (uint256 i; i < strategies.length; ++i) {
            out = vm.serializeAddress(obj, string.concat("SuperVaultCounsel_", vm.toString(strategies[i])), counsels[i]);
        }
    }

    function _one(address s, address c) internal returns (address[] memory, address[] memory) {
        address[] memory ss = new address[](1);
        address[] memory cs = new address[](1);
        ss[0] = s;
        cs[0] = c;
        return (ss, cs);
    }

    function _seatA() internal {
        (address[] memory ss, address[] memory cs) = _one(strategyA, address(counselA));
        script.setJson(_json(ss, cs));
        script.setFleet(ss);
        agg.seat(strategyA, address(counselA));
    }

    /*//////////////////////////////////////////////////////////////
                        THE THREE REQUESTED CASES
    //////////////////////////////////////////////////////////////*/

    /// @notice Fresh seat: both steps run, and invalidation lands BEFORE enrollment.
    function test_runAll_freshSeat_invalidatesBeforeEnrolling() public {
        _seatA();
        script.runAll(STAGING, CHAIN, "");

        assertEq(counselA.invalidateCalls(), 1, "step 2 ran");
        assertEq(counselA.enrollCalls(), 1, "step 3 ran");
        assertLt(counselA.lastInvalidateSeq(), counselA.lastEnrollSeq(), "invalidate must precede enroll");
        assertTrue(agg.isSecondaryManager(address(exec), strategyA), "executor enrolled");
        assertEq(exec.generation(strategyA), 1, "keys from the prior tenure are dead");
    }

    /// @notice A second run after step 4 must not touch the keys the operator just granted.
    function test_runAll_rerunAfterStep4_leavesKeeperKeysIntact() public {
        _seatA();
        script.runAll(STAGING, CHAIN, "");
        uint88 generationAfterStep4 = exec.generation(strategyA);

        script.runAll(STAGING, CHAIN, ""); // the re-run

        assertEq(counselA.invalidateCalls(), 1, "no second invalidation");
        assertEq(counselA.enrollCalls(), 1, "no second enrollment");
        assertEq(exec.generation(strategyA), generationAfterStep4, "keeper keys survive the re-run");
    }

    /// @notice A re-seat wipes the executor, so the next run must invalidate again, then enroll.
    function test_runAll_reseatThenRerun_invalidatesTheOldKeys() public {
        _seatA();
        script.runAll(STAGING, CHAIN, "");

        agg.seat(strategyA, address(counselA)); // Counsel loses and regains the seat: secondaries wiped
        assertFalse(agg.isSecondaryManager(address(exec), strategyA), "seating wiped the executor");

        script.runAll(STAGING, CHAIN, "");

        assertEq(counselA.invalidateCalls(), 2, "stale keys from the first tenure invalidated");
        assertEq(counselA.enrollCalls(), 2, "executor re-enrolled");
        assertLt(counselA.lastInvalidateSeq(), counselA.lastEnrollSeq(), "still in the safe order");
        assertEq(exec.generation(strategyA), 2);
    }

    /// @notice The precondition the guard cannot enforce, pinned as a test so it is not only a
    ///         comment: enrolling BY HAND after a re-seat makes the script skip, and the stale keys
    ///         stay live. This is why the runbook says to enroll through the script only.
    function test_runAll_manualEnrollAfterReseat_isTheDocumentedBlindSpot() public {
        _seatA();
        script.runAll(STAGING, CHAIN, "");

        agg.seat(strategyA, address(counselA)); // re-seat
        counselA.enrollExecutor(); // operator enrolls by hand, skipping invalidation

        script.runAll(STAGING, CHAIN, "");

        assertEq(counselA.invalidateCalls(), 1, "the script could not tell and skipped");
        assertEq(exec.generation(strategyA), 1, "keys from the first tenure are STILL live");
    }

    /*//////////////////////////////////////////////////////////////
                            SKIP PATHS
    //////////////////////////////////////////////////////////////*/

    /// @notice Each skip reason is exercised, and a run where everything was skipped reverts.
    function test_runAll_everySkipPath_thenRevertsWhenNothingWasConfigured() public {
        address strategyC = makeAddr("strategyC");
        StubCounsel counselWrongOp = new StubCounsel(makeAddr("someoneElse"), address(exec), strategyC, agg);

        // A: no Counsel key in the output JSON. B: Counsel present but not seated.
        // C: seated, but this broadcaster is not its operator.
        address[] memory ss = new address[](3);
        ss[0] = strategyA;
        ss[1] = strategyB;
        ss[2] = strategyC;
        address[] memory jsonStrategies = new address[](2);
        address[] memory jsonCounsels = new address[](2);
        jsonStrategies[0] = strategyB;
        jsonCounsels[0] = address(counselB);
        jsonStrategies[1] = strategyC;
        jsonCounsels[1] = address(counselWrongOp);
        script.setJson(_json(jsonStrategies, jsonCounsels));
        script.setFleet(ss);
        agg.seat(strategyC, address(counselWrongOp));

        vm.expectRevert(bytes("NOTHING_CONFIGURED_EVERY_STRATEGY_SKIPPED"));
        script.runAll(STAGING, CHAIN, "");

        assertEq(counselB.invalidateCalls() + counselB.enrollCalls(), 0, "unseated Counsel untouched");
        assertEq(counselWrongOp.invalidateCalls() + counselWrongOp.enrollCalls(), 0, "foreign operator untouched");
    }

    /// @notice A partial run configures what it can and does not revert.
    function test_runAll_partialRun_configuresTheRestWithoutReverting() public {
        address[] memory ss = new address[](2);
        ss[0] = strategyA;
        ss[1] = strategyB; // no JSON key: skipped
        (address[] memory js, address[] memory jc) = _one(strategyA, address(counselA));
        script.setJson(_json(js, jc));
        script.setFleet(ss);
        agg.seat(strategyA, address(counselA));

        script.runAll(STAGING, CHAIN, "");

        assertEq(counselA.enrollCalls(), 1, "A configured");
        assertEq(counselB.enrollCalls(), 0, "B skipped");
    }

    /// @notice An already-enrolled fleet counts as success, not as "nothing configured".
    function test_runAll_allAlreadyEnrolled_isSuccessNotRevert() public {
        _seatA();
        script.runAll(STAGING, CHAIN, "");
        script.runAll(STAGING, CHAIN, ""); // must not revert NOTHING_CONFIGURED
        assertEq(counselA.enrollCalls(), 1);
    }

    /*//////////////////////////////////////////////////////////////
                        FLEET FALLBACK BY ENV
    //////////////////////////////////////////////////////////////*/

    /// @notice On prod an empty fleet is a configuration mistake, never a cue to walk the registry.
    function test_runAll_prodEmptyFleet_refusesTheRegistryFallback() public {
        (address[] memory ss, address[] memory cs) = _one(strategyA, address(counselA));
        script.setJson(_json(ss, cs));
        script.setFleet(new address[](0));
        agg.setRegistry(ss);
        agg.seat(strategyA, address(counselA));

        vm.expectRevert(bytes("FLEET_EMPTY_FOR_PROD_REFUSING_REGISTRY_FALLBACK"));
        script.runAll(PROD, CHAIN, "");

        assertEq(counselA.enrollCalls(), 0, "nothing touched");
    }

    /// @notice Off prod the fallback still works, which is what staging and vnet rely on.
    function test_runAll_nonProdEmptyFleet_fallsBackToTheRegistry() public {
        (address[] memory ss, address[] memory cs) = _one(strategyA, address(counselA));
        script.setJson(_json(ss, cs));
        script.setFleet(new address[](0));
        agg.setRegistry(ss);
        agg.seat(strategyA, address(counselA));

        script.runAll(STAGING, CHAIN, "");

        assertEq(counselA.enrollCalls(), 1, "registry fallback configured A");
    }

    /*//////////////////////////////////////////////////////////////
                        SINGLE-STRATEGY run()
    //////////////////////////////////////////////////////////////*/

    /// @notice run() shares the helper, so it has the same order and the same re-run safety.
    function test_run_freshSeatThenRerun_sameGuardAsRunAll() public {
        _seatA();
        script.run(STAGING, CHAIN, "", strategyA);
        assertLt(counselA.lastInvalidateSeq(), counselA.lastEnrollSeq(), "invalidate before enroll");

        script.run(STAGING, CHAIN, "", strategyA);
        assertEq(counselA.invalidateCalls(), 1, "re-run skipped both steps");
    }

    function test_run_revertsWhenCounselIsNotSeated() public {
        (address[] memory ss, address[] memory cs) = _one(strategyA, address(counselA));
        script.setJson(_json(ss, cs));
        // not seated
        vm.expectRevert(bytes("COUNSEL_NOT_SEATED_RUN_CHANGE_PRIMARY_MANAGER_FIRST"));
        script.run(STAGING, CHAIN, "", strategyA);
    }

    function test_run_revertsWhenBroadcasterIsNotTheOperator() public {
        StubCounsel foreign = new StubCounsel(makeAddr("someoneElse"), address(exec), strategyA, agg);
        (address[] memory ss, address[] memory cs) = _one(strategyA, address(foreign));
        script.setJson(_json(ss, cs));
        agg.seat(strategyA, address(foreign));

        vm.expectRevert(bytes("BROADCASTER_IS_NOT_COUNSEL_OPERATOR"));
        script.run(STAGING, CHAIN, "", strategyA);
    }

    function test_run_revertsWhenCounselMissingFromOutputJson() public {
        script.setJson(_json(new address[](0), new address[](0)));
        vm.expectRevert(bytes("COUNSEL_NOT_IN_OUTPUT_JSON_DEPLOY_FIRST"));
        script.run(STAGING, CHAIN, "", strategyA);
    }
}
