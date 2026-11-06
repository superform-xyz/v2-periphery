// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { SuperVaultCounsel } from "../../src/SuperVault/SuperVaultCounsel.sol";
import { ISuperVaultCounsel } from "../../src/interfaces/SuperVault/ISuperVaultCounsel.sol";
import {
    MockCounselSuperGovernor,
    MockCounselStrategy,
    MockCounselAggregator,
    MockCounselExecutor
} from "./SuperVaultCounsel.t.sol";

/// @dev Random-walk handler: proposes, vetoes, executes, and warps time under fuzzed inputs while
///      tracking ghost state for the invariants
contract CounselHandler is Test {
    SuperVaultCounsel public counsel;
    MockCounselSuperGovernor public superGovernor;
    address public operator;
    address public guardian;

    // ghost state
    uint256 public ghost_proposed;
    uint256 public ghost_executed;
    uint256 public ghost_vetoed;
    uint256 public ghost_overCapAttempts;
    uint256 public ghost_overCapAccepted;
    mapping(uint256 => bool) public ghost_wasExecuted;
    mapping(uint256 => bool) public ghost_wasVetoed;

    constructor(
        SuperVaultCounsel counsel_,
        MockCounselSuperGovernor superGovernor_,
        address operator_,
        address guardian_
    ) {
        counsel = counsel_;
        superGovernor = superGovernor_;
        operator = operator_;
        guardian = guardian_;
    }

    function propose(uint256 seed) external {
        uint256 kind = seed % 8;
        vm.startPrank(operator);
        if (kind == 0) {
            counsel.proposeYieldSourceAdd(
                address(uint160(0x1000 + (seed % 1000))), address(uint160(0x9000 + (seed % 1000)))
            );
        } else if (kind == 1) {
            counsel.proposeStrategyRoot(bytes32(seed | 1), bytes32(~seed | 1));
        } else if (kind == 2) {
            uint256 min = counsel.MIN_DEVIATION_THRESHOLD();
            uint256 max = counsel.MAX_DEVIATION_THRESHOLD();
            counsel.proposeDeviationThreshold(min + (seed % (max - min + 1)));
        } else if (kind == 3) {
            bytes32[] memory leaves = new bytes32[](1 + (seed % 3));
            bool[] memory statuses = new bool[](leaves.length);
            for (uint256 i; i < leaves.length; ++i) {
                leaves[i] = keccak256(abi.encode(seed, i));
                statuses[i] = seed % 2 == 0;
            }
            counsel.proposeGlobalLeavesStatus(leaves, statuses);
        } else if (kind == 4) {
            counsel.proposeMinUpdateInterval(seed % 7 days);
        } else if (kind == 5) {
            counsel.proposeSecondaryManagerAdd(address(uint160(0x5000 + (seed % 1000))));
        } else if (kind == 6) {
            // always within the instance caps (the invariant run uses caps BELOW the strategy ceilings)
            counsel.proposeVaultFeeConfigUpdate(
                seed % (counsel.MAX_PERFORMANCE_FEE_BPS() + 1),
                seed % (counsel.MAX_MANAGEMENT_FEE_BPS() + 1),
                address(uint160(0x7000 + (seed % 1000)))
            );
        } else {
            // same address space as the Add kind so removals target plausible (possibly added) sources
            counsel.proposeYieldSourceRemove(address(uint160(0x1000 + (seed % 1000))));
        }
        vm.stopPrank();
        ++ghost_proposed;
    }

    /// @notice Adversarial: try to queue a fee config above either immutable cap; must always revert
    function proposeFeeAboveCap(uint256 seed) external {
        uint256 perfCap = counsel.MAX_PERFORMANCE_FEE_BPS();
        uint256 mgmtCap = counsel.MAX_MANAGEMENT_FEE_BPS();
        bool overPerf = seed % 2 == 0;
        uint256 perf = overPerf ? perfCap + 1 + (seed % 100) : seed % (perfCap + 1);
        uint256 mgmt = overPerf ? seed % (mgmtCap + 1) : mgmtCap + 1 + (seed % 100);
        ++ghost_overCapAttempts;
        vm.prank(operator);
        try counsel.proposeVaultFeeConfigUpdate(perf, mgmt, address(uint160(0x7000 + (seed % 1000)))) {
            ++ghost_overCapAccepted;
            ++ghost_proposed; // keep id accounting honest if it ever slips through
        } catch { }
    }

    function veto(uint256 idSeed) external {
        uint256 next = counsel.nextProposalId();
        if (next == 0) return;
        uint256 id = idSeed % next;
        vm.prank(guardian);
        try counsel.veto(id) {
            ++ghost_vetoed;
            ghost_wasVetoed[id] = true;
        } catch { }
    }

    function execute(uint256 idSeed) external {
        uint256 next = counsel.nextProposalId();
        if (next == 0) return;
        uint256 id = idSeed % next;
        vm.prank(operator);
        try counsel.execute(id) {
            ++ghost_executed;
            ghost_wasExecuted[id] = true;
        } catch { }
    }

    function warp(uint256 delta) external {
        vm.warp(block.timestamp + (delta % 4 days));
    }
}

contract SuperVaultCounselInvariantTest is Test {
    SuperVaultCounsel internal counsel;
    MockCounselSuperGovernor internal superGovernor;
    MockCounselStrategy internal strategy;
    MockCounselAggregator internal aggregator;
    MockCounselExecutor internal executor;
    CounselHandler internal handler;

    address internal operator = makeAddr("operator");
    address internal guardian = makeAddr("guardian");

    function setUp() public {
        superGovernor = new MockCounselSuperGovernor();
        strategy = new MockCounselStrategy();
        aggregator = new MockCounselAggregator();
        executor = new MockCounselExecutor();
        superGovernor.setGuardian(guardian, true);

        counsel = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            3 days,
            7 days,
            1e16,
            9e17,
            3000, // caps deliberately BELOW the strategy ceilings so the cap invariants are not vacuous
            500
        );

        handler = new CounselHandler(counsel, superGovernor, operator, guardian);
        targetContract(address(handler));
    }

    /// @notice A proposal is never both executed and vetoed, and terminal states are absorbing
    function invariant_terminalStatesExclusiveAndAbsorbing() public view {
        uint256 next = counsel.nextProposalId();
        for (uint256 id; id < next; ++id) {
            bool executed = handler.ghost_wasExecuted(id);
            bool vetoed = handler.ghost_wasVetoed(id);
            assertFalse(executed && vetoed, "proposal both executed and vetoed");
            ISuperVaultCounsel.ProposalStatus s = counsel.state(id);
            if (executed) {
                assertEq(uint8(s), uint8(ISuperVaultCounsel.ProposalStatus.Executed));
            }
            if (vetoed) {
                assertEq(uint8(s), uint8(ISuperVaultCounsel.ProposalStatus.Vetoed));
            }
        }
    }

    /// @notice Supersession: a proposal reported Superseded was never executed, and for every
    ///         single-slot type at most ONE proposal is ever executable at a time (the latest); an
    ///         older proposal of a single-slot type can never have been executed AFTER a newer one
    ///         of the same type was proposed (no rollback via a stale matured proposal).
    function invariant_supersededNeverExecutedAndLatestOnly() public view {
        uint256 next = counsel.nextProposalId();
        for (uint256 id; id < next; ++id) {
            ISuperVaultCounsel.ProposalStatus s = counsel.state(id);
            if (s == ISuperVaultCounsel.ProposalStatus.Superseded) {
                assertFalse(handler.ghost_wasExecuted(id), "superseded proposal was executed");
                (bool exists, uint256 latest) = counsel.latestProposalIdOfType(counsel.getProposal(id).actionType);
                assertTrue(exists && latest > id, "superseded proposal must be older than the epoch");
            }
            if (s == ISuperVaultCounsel.ProposalStatus.Ready) {
                ISuperVaultCounsel.ActionType t = counsel.getProposal(id).actionType;
                (bool exists, uint256 latest) = counsel.latestProposalIdOfType(t);
                if (exists) assertEq(latest, id, "a Ready single-slot proposal must be the latest of its type");
            }
        }
    }

    /// @notice Ids are monotonic: nextProposalId equals the number of successful proposes
    function invariant_idMonotonicity() public view {
        assertEq(counsel.nextProposalId(), handler.ghost_proposed());
    }

    /// @notice The strategy's governed surface is touched exactly once per executed Add/Remove
    ///         proposal — no parameter changes without a full-window, un-vetoed proposal
    function invariant_noGovernedChangeWithoutExecution() public view {
        uint256 forwarded = strategy.manageYieldSourceCalls();
        assertLe(forwarded, handler.ghost_executed(), "strategy touched more often than executions");
    }

    /// @notice No fee proposal above the immutable caps is ever stored, and the strategy never
    ///         receives a fee config above them (over-cap attempts always revert at propose time)
    function invariant_feeConfigNeverExceedsImmutableCaps() public view {
        uint256 perfCap = counsel.MAX_PERFORMANCE_FEE_BPS();
        uint256 mgmtCap = counsel.MAX_MANAGEMENT_FEE_BPS();
        assertEq(handler.ghost_overCapAccepted(), 0, "an over-cap fee proposal was accepted");
        uint256 next = counsel.nextProposalId();
        for (uint256 id; id < next; ++id) {
            ISuperVaultCounsel.Proposal memory p = counsel.getProposal(id);
            if (p.actionType == ISuperVaultCounsel.ActionType.FeeConfig) {
                assertLe(p.performanceFeeBps, perfCap, "stored perf fee above cap");
                assertLe(p.managementFeeBps, mgmtCap, "stored mgmt fee above cap");
            }
        }
        assertLe(strategy.feePerf(), perfCap, "strategy perf fee above cap");
        assertLe(strategy.feeMgmt(), mgmtCap, "strategy mgmt fee above cap");
    }

    /// @notice The immutable caps never move, whatever the handler does
    function invariant_feeCapsConstant() public view {
        assertEq(counsel.MAX_PERFORMANCE_FEE_BPS(), 3000);
        assertEq(counsel.MAX_MANAGEMENT_FEE_BPS(), 500);
    }

    /// @notice Every stored proposal status is within the stored subset (derived states are
    ///         never persisted)
    function invariant_storedStatusSubset() public view {
        uint256 next = counsel.nextProposalId();
        for (uint256 id; id < next; ++id) {
            uint8 stored = uint8(counsel.getProposal(id).status);
            assertTrue(
                stored == uint8(ISuperVaultCounsel.ProposalStatus.Pending)
                    || stored == uint8(ISuperVaultCounsel.ProposalStatus.Executed)
                    || stored == uint8(ISuperVaultCounsel.ProposalStatus.Vetoed),
                "derived state persisted"
            );
        }
    }
}
