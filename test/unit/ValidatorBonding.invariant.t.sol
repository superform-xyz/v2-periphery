// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { ValidatorBonding } from "../../src/ValidatorBonding.sol";
import { IValidatorBonding } from "../../src/interfaces/IValidatorBonding.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @dev Random-walk handler over the whole bond lifecycle: bond, bondFor, addBond, request,
///      execute, cancel, slash and time warps, against a small fixed operator set so sequences
///      actually collide on the same records. It also runs two ADVERSARIAL actions that must
///      never succeed, and counts the successes so the invariants can assert zero.
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
        try bonding.addBond(op, amount) { } catch { }
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
        try bonding.requestUnbond(op, amount) { } catch { }
    }

    function executeUnbond(uint256 seed) external {
        address op = _op(seed);
        address ben = bonding.getBond(op).beneficiary;
        if (ben == address(0)) return;
        uint256 pending = bonding.getBond(op).unbondingAmount;
        uint256 before = sup.balanceOf(ben);
        vm.prank(seed % 2 == 0 ? op : ben);
        try bonding.executeUnbond(op) {
            ghost_totalPaidOut += sup.balanceOf(ben) - before;
            assertEq(sup.balanceOf(ben) - before, pending, "executeUnbond paid an amount it did not owe");
            _closeEpochIfEmpty(op);
        } catch { }
    }

    function cancelUnbond(uint256 seed) external {
        address op = _op(seed);
        address ben = bonding.getBond(op).beneficiary;
        if (ben == address(0)) return;
        vm.prank(seed % 2 == 0 ? op : ben);
        try bonding.cancelUnbond(op) { } catch { }
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
        } catch { }
    }

    function warp(uint256 delta) external {
        vm.warp(block.timestamp + bound(delta, 1 hours, 10 days));
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
        bonding = new ValidatorBonding(address(sup), MINIMUM_BOND, 7 days, admin, governor);
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
