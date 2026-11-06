// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { ConfigureSuperVaultCounsel } from "../../../script/ConfigureSuperVaultCounsel.s.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVaultCounsel } from "../../../src/SuperVault/SuperVaultCounsel.sol";
import { ISuperVaultExecutor } from "../../../src/interfaces/SuperVault/ISuperVaultExecutor.sol";
import {
    MockCounselSuperGovernor,
    MockCounselStrategy,
    MockCounselAggregator,
    MockCounselExecutor
} from "../SuperVaultCounsel.t.sol";

/// @dev Minimal aggregator stub exposing only what the enrollment guard reads. Kept local rather
///      than extending MockCounselAggregator, which the Counsel suite depends on.
contract StubAggregator {
    mapping(address executor => mapping(address strategy => bool seated)) public seated;

    function setSeated(address executor, address strategy, bool v) external {
        seated[executor][strategy] = v;
    }

    function isSecondaryManager(address manager, address strategy) external view returns (bool) {
        return seated[manager][strategy];
    }
}

/// @dev Exposes the script's enrollment guard and the broadcaster the modifier resolves, so both
///      can be asserted directly instead of only through a full on-chain script run.
contract ConfigureHarness is ConfigureSuperVaultCounsel {
    function needsEnrollment(
        ISuperVaultAggregator aggregator,
        address executor,
        address strategy
    )
        external
        view
        returns (bool)
    {
        return _needsEnrollment(aggregator, executor, strategy);
    }

    /// @dev Runs the real `broadcast(env)` modifier and reports what it resolved the broadcaster
    ///      to. vm.startBroadcast is a no-op for assertions here; only the resolution matters.
    function resolveBroadcaster(uint256 env) external broadcast(env) returns (address) {
        return _broadcaster;
    }

    function broadcasterView() external view returns (address) {
        return _broadcaster;
    }
}

/// @notice Covers the two gaps named in the PR #335 review: that re-running enrollment must not
///         destroy live keeper keys, and that the operator pre-check must use the resolved
///         broadcaster rather than msg.sender.
contract ConfigureSuperVaultCounselScriptTest is Test {
    ConfigureHarness internal harness;
    StubAggregator internal stub;
    MockCounselAggregator internal aggregator;
    MockCounselExecutor internal executor;
    MockCounselSuperGovernor internal superGovernor;
    MockCounselStrategy internal strategy;
    SuperVaultCounsel internal counsel;

    address internal operator = makeAddr("operator");
    address internal guardian = makeAddr("guardian");

    function setUp() public {
        harness = new ConfigureHarness();
        stub = new StubAggregator();
        aggregator = new MockCounselAggregator();
        executor = new MockCounselExecutor();
        superGovernor = new MockCounselSuperGovernor();
        strategy = new MockCounselStrategy();
        superGovernor.setGuardian(guardian, true);

        counsel = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0),
            address(aggregator),
            address(strategy),
            address(executor),
            3 days,
            7 days,
            1e16,
            9e17,
            5100,
            10_000
        );
    }

    /*//////////////////////////////////////////////////////////////
        ITEM 1 — re-running enrollment must not kill live keeper keys
    //////////////////////////////////////////////////////////////*/

    /// @notice An executor still seated as secondary means no seating has happened since, so the
    ///         enrollment steps must be skipped.
    /// @dev Before the fix only enrollExecutor was guarded while invalidateAllSessionKeys ran
    ///      unconditionally, so a second run after step 4 wiped every keeper key just granted.
    function test_guard_skipsWhenExecutorIsStillSeated() public {
        stub.setSeated(address(executor), address(strategy), true);
        assertFalse(
            harness.needsEnrollment(ISuperVaultAggregator(address(stub)), address(executor), address(strategy)),
            "a still-seated executor must skip both steps"
        );
    }

    /// @notice After a seating wipes the secondaries, the steps must run.
    function test_guard_runsWhenExecutorWasWiped() public {
        stub.setSeated(address(executor), address(strategy), false);
        assertTrue(
            harness.needsEnrollment(ISuperVaultAggregator(address(stub)), address(executor), address(strategy)),
            "a wiped executor must trigger enrollment"
        );
    }

    /// @notice Why the guard matters: invalidation is destructive and not idempotent.
    /// @dev Documents the damage the unguarded script did. Keys are granted (step 4), then a
    ///      second enrollment run invalidates them. The guard above is what prevents this path
    ///      being reached when the executor is still seated.
    function test_guard_whyItMatters_invalidateAfterGrantKillsKeys() public {
        vm.startPrank(operator);
        counsel.enrollExecutor();
        address[] memory keys = new address[](1);
        keys[0] = makeAddr("keeperKey");
        uint256[] memory expiries = new uint256[](1);
        expiries[0] = block.timestamp + 30 days;
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](1);
        perms[0] = new ISuperVaultExecutor.Permission[](1);
        perms[0][0] = ISuperVaultExecutor.Permission.ExecuteHooks;
        counsel.grantSessionKeysBatch(keys, expiries, perms);
        assertEq(executor.batchLen(), 1, "keeper keys granted (step 4)");
        uint256 genBefore = executor.generation();

        // the second run, unguarded, would land here
        counsel.invalidateAllSessionKeys();
        vm.stopPrank();
        assertEq(executor.generation(), genBefore + 1, "a re-run bumps the generation, killing those keys");
    }

    /*//////////////////////////////////////////////////////////////
        ITEM 2 — the operator pre-check must use the real broadcaster
    //////////////////////////////////////////////////////////////*/

    /// @notice On vnet the modifier broadcasts from a key derived from MNEMONIC, not msg.sender.
    /// @dev This is the bug: the pre-check compared msg.sender, which on vnet is foundry's default
    ///      sender and never the deployer, so the check was meaningless there.
    function test_broadcaster_vnetResolvesToDerivedKeyNotMsgSender() public {
        (address expected,) = deriveRememberKey("test test test test test test test test test test test junk", 0);
        address resolved = harness.resolveBroadcaster(1);
        assertEq(resolved, expected, "vnet broadcaster is the derived deployer");
        assertTrue(resolved != address(this), "and is NOT msg.sender, which is what the check used");
    }

    /// @notice For prod and staging the broadcaster is msg.sender, which the runner sets via
    ///         --sender. Behaviour there is unchanged by the fix.
    function test_broadcaster_prodAndStagingResolveToMsgSender() public {
        assertEq(harness.resolveBroadcaster(0), address(this), "prod broadcaster is msg.sender");
        assertEq(harness.resolveBroadcaster(2), address(this), "staging broadcaster is msg.sender");
    }

    /// @notice The resolved value persists for the body of the run, which is what lets the
    ///         pre-check and the per-strategy loop compare against the same address.
    function test_broadcaster_persistsAfterTheModifierRuns() public {
        harness.resolveBroadcaster(0);
        assertEq(harness.broadcasterView(), address(this));
    }
}
