// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { ValidatorBonding } from "../../src/ValidatorBonding.sol";
import { IValidatorBonding } from "../../src/interfaces/IValidatorBonding.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @dev Random-walk handler over the bond lifecycle against a small fixed operator set, so
///      sequences actually collide on the same records: bond, bondFor, addBond, request, execute,
///      cancel, slash, delegate-key rotation, governance parameter proposals with their
///      permissionless execute, and time warps.
///
///      Two ADVERSARIAL actions must never succeed and their successes are counted so the
///      invariants can assert zero: a bondFor redirect, and an unrelated address calling every
///      bond-mutating entry point (addBond, requestUnbond, executeUnbond, cancelUnbond,
///      updateDelegateKey, slash).
///
///      Every action swallows expected reverts, so success counters back an afterInvariant()
///      coverage floor. Without it a campaign where almost everything reverted would satisfy
///      every invariant vacuously.
contract BondingHandler is Test {
    ValidatorBonding public bonding;
    MockERC20 public sup;
    address public governor;

    address[3] public operators;
    address[3] public beneficiaries;
    address public funder;

    // ghost state
    mapping(address operator => address beneficiary) public ghost_firstBeneficiary;
    mapping(address operator => bool seen) public ghost_everBonded;
    uint256 public ghost_mismatchedBondForAccepted;
    uint256 public ghost_thirdPartyWriteAccepted;
    uint256 public ghost_totalPaidOut;

    // Successful-transition counters. Every action swallows expected reverts, so without these a
    // walk in which almost nothing succeeded would satisfy every invariant vacuously.
    uint256 public ghost_bonded;
    uint256 public ghost_added;
    uint256 public ghost_requested;
    uint256 public ghost_executed;
    uint256 public ghost_cancelled;
    uint256 public ghost_slashed;
    uint256 public ghost_paramChanged;
    uint256 public ghost_keyRotated;

    constructor(ValidatorBonding bonding_, MockERC20 sup_, address governor_, address funder_) {
        bonding = bonding_;
        sup = sup_;
        governor = governor_;
        funder = funder_;
        operators = [makeAddr("op0"), makeAddr("op1"), makeAddr("op2")];
        beneficiaries = [makeAddr("ben0"), makeAddr("ben1"), makeAddr("ben2")];
    }

    function _op(uint256 seed) internal view returns (address) {
        return operators[seed % 3];
    }

    function _ben(uint256 seed) internal view returns (address) {
        return beneficiaries[seed % 3];
    }

    function _key(uint256 seed) internal pure returns (address) {
        return address(uint160(0xBEEF0000 + (seed % 5)));
    }

    /// @notice Operator bonds for itself
    function bondSelf(uint256 seed, uint256 amount) external {
        address op = _op(seed);
        address ben = _ben(seed >> 8);
        amount = bound(amount, bonding.minimumBond(), bonding.minimumBond() * 3);
        sup.mint(op, amount);
        vm.startPrank(op);
        sup.approve(address(bonding), amount);
        try bonding.bond(amount, ben, _key(seed)) {
            _recordBeneficiary(op, ben);
            ++ghost_bonded;
        } catch { }
        vm.stopPrank();
    }

    /// @notice A third party funds the bond with matching approved terms
    function bondForMatching(uint256 seed, uint256 amount) external {
        address op = _op(seed);
        address ben = _ben(seed >> 8);
        address dk = _key(seed);
        amount = bound(amount, bonding.minimumBond(), bonding.minimumBond() * 3);
        vm.prank(op);
        bonding.approveBondFor(funder, ben, dk);
        sup.mint(funder, amount);
        vm.startPrank(funder);
        sup.approve(address(bonding), amount);
        try bonding.bondFor(op, amount, ben, dk) {
            _recordBeneficiary(op, ben);
            ++ghost_bonded;
        } catch { }
        vm.stopPrank();
    }

    /// @notice ADVERSARIAL. The operator shows one set of terms, the funder verifies them, and the
    ///         operator rewrites the approval before the funder's call lands. Must always revert.
    function bondForRedirect(uint256 seed, uint256 amount) external {
        address op = _op(seed);
        address shown = _ben(seed >> 8);
        address dk = _key(seed);
        amount = bound(amount, bonding.minimumBond(), bonding.minimumBond() * 3);

        vm.prank(op);
        bonding.approveBondFor(funder, shown, dk);
        // operator rewrites itself in as beneficiary after the funder has verified
        vm.prank(op);
        bonding.approveBondFor(funder, op, dk);

        sup.mint(funder, amount);
        vm.startPrank(funder);
        sup.approve(address(bonding), amount);
        try bonding.bondFor(op, amount, shown, dk) {
            ++ghost_mismatchedBondForAccepted;
            _recordBeneficiary(op, shown);
        } catch { }
        vm.stopPrank();
    }

    /// @notice ADVERSARIAL. Someone who is neither operator nor beneficiary tries every
    ///         bond-touching entry point. None may succeed.
    function thirdPartyPokes(uint256 seed) external {
        address op = _op(seed);
        address intruder = address(uint160(0xBAD00000 + (seed % 7)));
        sup.mint(intruder, bonding.minimumBond());
        vm.startPrank(intruder);
        sup.approve(address(bonding), type(uint256).max);
        try bonding.addBond(op, 1) {
            ++ghost_thirdPartyWriteAccepted;
        } catch { }
        try bonding.requestUnbond(op, 1) {
            ++ghost_thirdPartyWriteAccepted;
        } catch { }
        try bonding.executeUnbond(op) {
            ++ghost_thirdPartyWriteAccepted;
        } catch { }
        try bonding.cancelUnbond(op) {
            ++ghost_thirdPartyWriteAccepted;
        } catch { }
        try bonding.updateDelegateKey(op, intruder) {
            ++ghost_thirdPartyWriteAccepted;
        } catch { }
        try bonding.slash(op, 1, intruder) {
            ++ghost_thirdPartyWriteAccepted;
        } catch { }
        vm.stopPrank();
    }

    function addBond(uint256 seed, uint256 amount) external {
        address op = _op(seed);
        amount = bound(amount, 1, bonding.minimumBond());
        sup.mint(op, amount);
        vm.startPrank(op);
        sup.approve(address(bonding), amount);
        try bonding.addBond(op, amount) {
            ++ghost_added;
        } catch { }
        vm.stopPrank();
    }

    function requestUnbond(uint256 seed, uint256 amount) external {
        address op = _op(seed);
        uint256 total = bonding.getBond(op).amount;
        if (total == 0) return;
        amount = bound(amount, 1, total);
        address caller = seed % 2 == 0 ? op : bonding.getBond(op).beneficiary;
        if (caller == address(0)) return;
        vm.prank(caller);
        try bonding.requestUnbond(op, amount) {
            ++ghost_requested;
        } catch { }
    }

    function executeUnbond(uint256 seed) external {
        address op = _op(seed);
        address ben = bonding.getBond(op).beneficiary;
        if (ben == address(0)) return;
        uint256 pending = bonding.getBond(op).unbondingAmount;
        // Steer to the reachable state. A pending unbond competes with cancelUnbond and slash in
        // the walk, so waiting for random warps to clear the cooldown first meant this action
        // never once succeeded across the whole campaign. Jumping to the deadline when a request
        // is actually live tests the same contract logic and makes the matured path reachable;
        // the before-deadline revert is covered by the unit suite.
        uint48 deadline = bonding.getBond(op).unbondingDeadline;
        if (pending > 0 && block.timestamp < deadline) vm.warp(deadline);
        uint256 before = sup.balanceOf(ben);
        vm.prank(seed % 2 == 0 ? op : ben);
        try bonding.executeUnbond(op) {
            ghost_totalPaidOut += sup.balanceOf(ben) - before;
            assertEq(sup.balanceOf(ben) - before, pending, "executeUnbond paid an amount it did not owe");
            _closeEpochIfEmpty(op);
            ++ghost_executed;
        } catch { }
    }

    /// @notice One legitimate end-to-end exit: request, wait out the cooldown, execute.
    /// @dev The granular actions above interleave randomly, which is what finds ordering bugs, but
    ///      it also means a whole campaign can pass without a single completed exit: cancelUnbond
    ///      and slash keep clearing the request before the cooldown elapses. That is exactly what
    ///      happened before the coverage floor existed. This action guarantees the matured path is
    ///      exercised every campaign without removing the interleaving from the others.
    function completeFullExit(uint256 seed) external {
        address op = _op(seed);
        IValidatorBonding.BondRecord memory r = bonding.getBond(op);
        if (r.amount == 0 || r.beneficiary == address(0) || r.unbondingAmount > 0) return;

        address caller = seed % 2 == 0 ? op : r.beneficiary;
        vm.prank(caller);
        try bonding.requestUnbond(op, r.amount) {
            ++ghost_requested;
        } catch {
            return;
        }

        vm.warp(bonding.getBond(op).unbondingDeadline);
        uint256 pending = bonding.getBond(op).unbondingAmount;
        uint256 before = sup.balanceOf(r.beneficiary);
        vm.prank(caller);
        try bonding.executeUnbond(op) {
            ghost_totalPaidOut += sup.balanceOf(r.beneficiary) - before;
            assertEq(sup.balanceOf(r.beneficiary) - before, pending, "full exit paid the wrong amount");
            _closeEpochIfEmpty(op);
            ++ghost_executed;
        } catch { }
    }

    function cancelUnbond(uint256 seed) external {
        address op = _op(seed);
        address ben = bonding.getBond(op).beneficiary;
        if (ben == address(0)) return;
        vm.prank(seed % 2 == 0 ? op : ben);
        try bonding.cancelUnbond(op) {
            ++ghost_cancelled;
        } catch { }
    }

    /// @notice The other legitimate composite: open an exit then abandon it.
    /// @dev Same reasoning as completeFullExit. The granular cancelUnbond only fires usefully when
    ///      a request happens to be live, and the composites consume requests quickly, so without
    ///      this a campaign can finish having never cancelled anything. Keeping both composite and
    ///      granular forms means the floor is guaranteed while the random interleaving, which is
    ///      what actually finds ordering bugs, is untouched.
    function requestThenCancel(uint256 seed) external {
        address op = _op(seed);
        IValidatorBonding.BondRecord memory r = bonding.getBond(op);
        if (r.amount == 0 || r.beneficiary == address(0) || r.unbondingAmount > 0) return;

        // Full amount, not a random partial: a partial that leaves less than minimumBond reverts
        // BELOW_MINIMUM_BOND and returns before cancelling, which is what made this composite stop
        // covering the cancel path once cancellation became beneficiary-only.
        address opener = seed % 2 == 0 ? op : r.beneficiary;
        vm.prank(opener);
        try bonding.requestUnbond(op, r.amount) {
            ++ghost_requested;
        } catch {
            return;
        }

        // Always the beneficiary here, since this composite exists to guarantee the happy path is
        // covered. The granular cancelUnbond action still attempts it as the operator half the
        // time, which is where the refusal gets exercised.
        vm.prank(r.beneficiary);
        try bonding.cancelUnbond(op) {
            ++ghost_cancelled;
        } catch { }
    }

    function slash(uint256 seed, uint256 amount) external {
        address op = _op(seed);
        uint256 total = bonding.getBond(op).amount;
        if (total == 0) return;
        amount = bound(amount, 1, total);
        address recipient = address(uint160(0x5A5A0000 + (seed % 3)));
        uint256 before = sup.balanceOf(recipient);
        vm.prank(governor);
        try bonding.slash(op, amount, recipient) {
            ghost_totalPaidOut += sup.balanceOf(recipient) - before;
            _closeEpochIfEmpty(op);
            ++ghost_slashed;
        } catch { }
    }

    /// @notice Governance proposes a new minimum bond. Execution is permissionless after the
    ///         parameter timelock, so the walk can also land it from any caller.
    function proposeMinimumBond(uint256 seed) external {
        uint256 newMin = bound(seed, bonding.MIN_MINIMUM_BOND(), 3_000_000e18);
        vm.prank(governor);
        try bonding.proposeMinimumBond(newMin) { } catch { }
    }

    function executeMinimumBondUpdate(uint256 seed) external {
        vm.prank(address(uint160(0xE0E0 + (seed % 3)))); // permissionless on purpose
        try bonding.executeMinimumBondUpdate() {
            ++ghost_paramChanged;
        } catch { }
    }

    function proposeUnbondingPeriod(uint256 seed) external {
        uint256 newPeriod = bound(seed, bonding.MIN_UNBONDING_PERIOD(), 30 days);
        vm.prank(governor);
        try bonding.proposeUnbondingPeriod(newPeriod) { } catch { }
    }

    function executeUnbondingPeriodUpdate(uint256 seed) external {
        vm.prank(address(uint160(0xE1E1 + (seed % 3))));
        try bonding.executeUnbondingPeriodUpdate() {
            ++ghost_paramChanged;
        } catch { }
    }

    /// @notice Legitimate delegate-key rotation by either authorised party
    function rotateDelegateKey(uint256 seed) external {
        address op = _op(seed);
        address ben = bonding.getBond(op).beneficiary;
        if (ben == address(0)) return;
        vm.prank(seed % 2 == 0 ? op : ben);
        try bonding.updateDelegateKey(op, _key(seed >> 8)) {
            ++ghost_keyRotated;
        } catch { }
    }

    function warp(uint256 delta) external {
        vm.warp(block.timestamp + bound(delta, 1 hours, 10 days));
        // deliberately spans the 1-day cooldown most of the time so matured unbonds are reachable
    }

    function _recordBeneficiary(address op, address ben) internal {
        if (!ghost_everBonded[op]) {
            ghost_everBonded[op] = true;
            ghost_firstBeneficiary[op] = ben;
        }
    }

    /// @dev A fully exited bond ends its epoch. Re-bonding afterwards is allowed to name a new
    ///      beneficiary, so the ghost must stop asserting the old one.
    function _closeEpochIfEmpty(address op) internal {
        if (bonding.getBond(op).amount == 0) {
            ghost_everBonded[op] = false;
            ghost_firstBeneficiary[op] = address(0);
        }
    }

    function allOperators() external view returns (address[3] memory) {
        return operators;
    }
}

contract ValidatorBondingInvariantTest is Test {
    ValidatorBonding internal bonding;
    MockERC20 internal sup;
    BondingHandler internal handler;

    address internal admin = makeAddr("admin");
    address internal governor = makeAddr("governor");
    address internal funder = makeAddr("funder");

    uint256 internal constant MINIMUM_BOND = 1_000_000e18;

    function setUp() public {
        sup = new MockERC20("Staked UP", "sUP", 18);
        // 1 day rather than production's 7. The walk has to reach executeUnbond past competing
        // cancels and slashes, and with a 7-day cooldown against warps of at most 10 days it
        // never did: the first version of this suite completed zero unbonds across 128k calls
        // and every invariant still passed. MIN_UNBONDING_PERIOD is 1 day, so this stays inside
        // the production range, and the walk's own proposeUnbondingPeriod action pushes it back
        // up to 30 days anyway.
        bonding = new ValidatorBonding(address(sup), MINIMUM_BOND, 1 days, admin, governor);
        handler = new BondingHandler(bonding, sup, governor, funder);
        targetContract(address(handler));
    }

    /// @notice The unbonding slice can never exceed the bond it is carved out of. If it could,
    ///         executeUnbond would underflow or pay out more than the operator ever bonded.
    function invariant_unbondingNeverExceedsBond() public view {
        address[3] memory ops = handler.allOperators();
        for (uint256 i; i < ops.length; ++i) {
            IValidatorBonding.BondRecord memory b = bonding.getBond(ops[i]);
            assertLe(b.unbondingAmount, b.amount, "unbondingAmount exceeds amount");
        }
    }

    /// @notice Solvency: the contract always holds at least the sum of every live bond. Anything
    ///         less means some payout path released tokens it did not account for.
    function invariant_solvent() public view {
        address[3] memory ops = handler.allOperators();
        uint256 owed;
        for (uint256 i; i < ops.length; ++i) {
            owed += bonding.getBond(ops[i]).amount;
        }
        assertGe(sup.balanceOf(address(bonding)), owed, "contract holds less than it owes");
    }

    /// @notice THE property the bondFor fix exists to protect. Once a bond is live its beneficiary
    ///         is fixed, and no sequence of approvals, adds, unbonds, cancels or slashes moves it.
    ///         The handler actively tries to redirect it on every call to bondForRedirect.
    function invariant_beneficiaryImmutableWhileBonded() public view {
        assertEq(handler.ghost_mismatchedBondForAccepted(), 0, "a redirected bondFor was accepted");
        address[3] memory ops = handler.allOperators();
        for (uint256 i; i < ops.length; ++i) {
            address op = ops[i];
            IValidatorBonding.BondRecord memory b = bonding.getBond(op);
            if (b.amount > 0 && handler.ghost_everBonded(op)) {
                assertEq(b.beneficiary, handler.ghost_firstBeneficiary(op), "beneficiary changed under a live bond");
            }
        }
    }

    /// @notice Nobody outside the operator/beneficiary pair, and outside GOVERNOR_ROLE for slash,
    ///         can touch a bond. The handler hammers every entry point from an unrelated address.
    function invariant_noThirdPartyWrites() public view {
        assertEq(handler.ghost_thirdPartyWriteAccepted(), 0, "a third party mutated a bond");
    }

    /// @notice Registry membership tracks status exactly: an operator is enumerated if and only if
    ///         it is not Unbonded. A desync would leave a ghost validator in the active set or hide
    ///         a live one from slashing tooling.
    function invariant_registryMatchesStatus() public view {
        address[3] memory ops = handler.allOperators();
        address[] memory enumerated = bonding.getOperators();
        for (uint256 i; i < ops.length; ++i) {
            bool present;
            for (uint256 j; j < enumerated.length; ++j) {
                if (enumerated[j] == ops[i]) {
                    present = true;
                    break;
                }
            }
            bool unbonded = bonding.getBond(ops[i]).status == IValidatorBonding.ValidatorStatus.Unbonded;
            assertEq(present, !unbonded, "registry membership disagrees with status");
        }
    }

    /// @notice An operator reported active must actually be collateralised at or above the current
    ///         minimum, counting only the portion that is not already on its way out.
    function invariant_activeOperatorsAreCollateralised() public view {
        address[] memory active = bonding.getActiveOperators();
        uint256 min = bonding.minimumBond();
        for (uint256 i; i < active.length; ++i) {
            IValidatorBonding.BondRecord memory b = bonding.getBond(active[i]);
            assertGe(b.amount - b.unbondingAmount, min, "active operator is under-collateralised");
        }
    }

    /// @notice The documented sentinel holds: a record with no pending unbond carries no deadline
    ///         and no initiator. Catches the class where a terminal transition clears the amount
    ///         but leaves the companion fields behind for the next tenure to inherit.
    function invariant_noStaleUnbondFields() public view {
        address[3] memory ops = handler.allOperators();
        for (uint256 i; i < ops.length; ++i) {
            IValidatorBonding.BondRecord memory b = bonding.getBond(ops[i]);
            if (b.unbondingAmount == 0) {
                assertEq(b.unbondingDeadline, 0, "deadline set with no pending unbond");
                assertEq(b.unbondingInitiator, address(0), "initiator set with no pending unbond");
            }
        }
    }

    /// @notice Coverage floor. Runs once after the campaign, so it can assert the walk actually
    ///         exercised the lifecycle rather than reverting its way to a green board. Without
    ///         this, every invariant above is satisfiable by a campaign in which nothing happened.
    function afterInvariant() public view {
        assertGt(handler.ghost_bonded(), 0, "no bond was ever created");
        assertGt(handler.ghost_added(), 0, "addBond never succeeded");
        assertGt(handler.ghost_requested(), 0, "requestUnbond never succeeded");
        assertGt(handler.ghost_executed(), 0, "executeUnbond never succeeded");
        assertGt(handler.ghost_cancelled(), 0, "cancelUnbond never succeeded");
        assertGt(handler.ghost_slashed(), 0, "slash never succeeded");
        assertGt(handler.ghost_paramChanged(), 0, "no governance parameter change ever landed");
        assertGt(handler.ghost_keyRotated(), 0, "delegate-key rotation never succeeded");
    }

    /// @notice Every token that left the contract left through executeUnbond or slash, so the
    ///         amount paid out can never exceed what was ever put in.
    function invariant_payoutsNeverExceedDeposits() public view {
        uint256 owed;
        address[3] memory ops = handler.allOperators();
        for (uint256 i; i < ops.length; ++i) {
            owed += bonding.getBond(ops[i]).amount;
        }
        assertEq(
            sup.balanceOf(address(bonding)),
            owed,
            "contract balance drifted from the sum of bonds; a payout or credit is unaccounted for"
        );
    }
}
