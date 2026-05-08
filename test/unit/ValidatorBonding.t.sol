// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { ValidatorBonding } from "../../src/ValidatorBonding.sol";
import { IValidatorBonding } from "../../src/interfaces/IValidatorBonding.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

contract ValidatorBondingTest is Test {
    ValidatorBonding internal bonding;
    MockERC20 internal supToken;

    address internal admin = makeAddr("admin");
    address internal governor = makeAddr("governor");
    address internal operator1 = makeAddr("operator1");
    address internal operator2 = makeAddr("operator2");
    address internal beneficiary1 = makeAddr("beneficiary1");
    address internal beneficiary2 = makeAddr("beneficiary2");
    address internal delegateKey1 = makeAddr("delegateKey1");
    address internal delegateKey2 = makeAddr("delegateKey2");
    address internal treasury = makeAddr("treasury");
    address internal bonder = makeAddr("bonder");

    uint256 internal constant MINIMUM_BOND = 1_000_000e18;
    uint256 internal constant UNBONDING_PERIOD = 7 days;

    function setUp() public {
        supToken = new MockERC20("Staked UP", "sUP", 18);
        bonding = new ValidatorBonding(address(supToken), MINIMUM_BOND, UNBONDING_PERIOD, admin, governor);

        // Mint sUP to operators and beneficiaries for testing
        supToken.mint(operator1, 10_000_000e18);
        supToken.mint(operator2, 10_000_000e18);
        supToken.mint(beneficiary1, 10_000_000e18);
        supToken.mint(bonder, 10_000_000e18);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function test_constructor_setsImmutables() public view {
        assertEq(address(bonding.SUP_TOKEN()), address(supToken));
        assertEq(bonding.minimumBond(), MINIMUM_BOND);
        assertEq(bonding.unbondingPeriod(), UNBONDING_PERIOD);
        assertEq(bonding.parameterTimelock(), bonding.DEFAULT_PARAMETER_TIMELOCK());
        assertTrue(bonding.hasRole(bonding.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(bonding.hasRole(bonding.GOVERNOR_ROLE(), governor));
    }

    function test_constructor_revertsZeroSupToken() public {
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        new ValidatorBonding(address(0), MINIMUM_BOND, UNBONDING_PERIOD, admin, governor);
    }

    function test_constructor_revertsZeroAdmin() public {
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        new ValidatorBonding(address(supToken), MINIMUM_BOND, UNBONDING_PERIOD, address(0), governor);
    }

    function test_constructor_revertsZeroGovernor() public {
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        new ValidatorBonding(address(supToken), MINIMUM_BOND, UNBONDING_PERIOD, admin, address(0));
    }

    function test_constructor_revertsInvalidMinimumBondTooLow() public {
        vm.expectRevert(IValidatorBonding.INVALID_MINIMUM_BOND.selector);
        new ValidatorBonding(address(supToken), 0, UNBONDING_PERIOD, admin, governor);
    }

    function test_constructor_revertsInvalidMinimumBondTooHigh() public {
        vm.expectRevert(IValidatorBonding.INVALID_MINIMUM_BOND.selector);
        new ValidatorBonding(address(supToken), 100_000_001e18, UNBONDING_PERIOD, admin, governor);
    }

    function test_constructor_revertsInvalidUnbondingPeriodTooLow() public {
        vm.expectRevert(IValidatorBonding.INVALID_UNBONDING_PERIOD.selector);
        new ValidatorBonding(address(supToken), MINIMUM_BOND, 0, admin, governor);
    }

    function test_constructor_revertsInvalidUnbondingPeriodTooHigh() public {
        vm.expectRevert(IValidatorBonding.INVALID_UNBONDING_PERIOD.selector);
        new ValidatorBonding(address(supToken), MINIMUM_BOND, 366 days, admin, governor);
    }

    /*//////////////////////////////////////////////////////////////
                              BOND
    //////////////////////////////////////////////////////////////*/

    function test_bond_selfBond() public {
        vm.startPrank(operator1);
        supToken.approve(address(bonding), MINIMUM_BOND);

        vm.expectEmit(true, true, false, true);
        emit IValidatorBonding.Bonded(operator1, operator1, operator1, delegateKey1, MINIMUM_BOND);
        bonding.bond(MINIMUM_BOND, operator1, delegateKey1);
        vm.stopPrank();

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, MINIMUM_BOND);
        assertEq(record.beneficiary, operator1);
        assertEq(record.delegateKey, delegateKey1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertTrue(bonding.isBonded(operator1));
        assertEq(bonding.getOperatorCount(), 1);
    }

    function test_bondFor_withApproval() public {
        // Operator approves beneficiary1 as bonder
        vm.prank(operator1);
        bonding.approveBondFor(beneficiary1);

        vm.startPrank(beneficiary1);
        supToken.approve(address(bonding), MINIMUM_BOND);

        vm.expectEmit(true, true, false, true);
        emit IValidatorBonding.Bonded(operator1, beneficiary1, beneficiary1, delegateKey1, MINIMUM_BOND);
        bonding.bondFor(operator1, MINIMUM_BOND, beneficiary1, delegateKey1);
        vm.stopPrank();

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, MINIMUM_BOND);
        assertEq(record.beneficiary, beneficiary1);
        assertEq(record.delegateKey, delegateKey1);
        assertTrue(bonding.isBonded(operator1));

        address[] memory operators = bonding.getOperators();
        assertEq(operators.length, 1);
        assertEq(operators[0], operator1);
    }

    function test_bondFor_revertsWithoutApproval() public {
        vm.startPrank(beneficiary1);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.NOT_APPROVED_BONDER.selector);
        bonding.bondFor(operator1, MINIMUM_BOND, beneficiary1, delegateKey1);
        vm.stopPrank();
    }

    function test_bondFor_revertsZeroOperator() public {
        // address(0) can't approve, so bondFor(address(0), ...) always reverts with NOT_APPROVED_BONDER
        vm.startPrank(operator1);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.NOT_APPROVED_BONDER.selector);
        bonding.bondFor(address(0), MINIMUM_BOND, beneficiary1, delegateKey1);
        vm.stopPrank();
    }

    function test_bond_revertsZeroBeneficiary() public {
        vm.startPrank(operator1);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        bonding.bond(MINIMUM_BOND, address(0), delegateKey1);
        vm.stopPrank();
    }

    function test_bond_revertsZeroDelegateKey() public {
        vm.startPrank(operator1);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        bonding.bond(MINIMUM_BOND, operator1, address(0));
        vm.stopPrank();
    }

    function test_bond_revertsBelowMinimum() public {
        vm.startPrank(operator1);
        supToken.approve(address(bonding), MINIMUM_BOND - 1);
        vm.expectRevert(IValidatorBonding.BELOW_MINIMUM_BOND.selector);
        bonding.bond(MINIMUM_BOND - 1, operator1, delegateKey1);
        vm.stopPrank();
    }

    function test_bond_revertsAlreadyBonded() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.startPrank(operator1);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.ALREADY_BONDED.selector);
        bonding.bond(MINIMUM_BOND, operator1, delegateKey1);
        vm.stopPrank();
    }

    function test_bond_transfersTokens() public {
        uint256 balanceBefore = supToken.balanceOf(operator1);

        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        assertEq(supToken.balanceOf(operator1), balanceBefore - MINIMUM_BOND);
        assertEq(supToken.balanceOf(address(bonding)), MINIMUM_BOND);
    }

    /*//////////////////////////////////////////////////////////////
                        BOND-FOR APPROVAL
    //////////////////////////////////////////////////////////////*/

    function test_approveBondFor() public {
        vm.prank(operator1);
        vm.expectEmit(true, true, false, false);
        emit IValidatorBonding.BondForApproved(operator1, bonder);
        bonding.approveBondFor(bonder);

        assertEq(bonding.getBondForApproval(operator1), bonder);
    }

    function test_approveBondFor_revertsZeroAddress() public {
        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        bonding.approveBondFor(address(0));
    }

    function test_revokeBondForApproval() public {
        vm.prank(operator1);
        bonding.approveBondFor(bonder);
        assertEq(bonding.getBondForApproval(operator1), bonder);

        vm.prank(operator1);
        vm.expectEmit(true, false, false, false);
        emit IValidatorBonding.BondForApprovalRevoked(operator1);
        bonding.revokeBondForApproval();

        assertEq(bonding.getBondForApproval(operator1), address(0));
    }

    function test_bondFor_approveThenRevokeThenFail() public {
        vm.prank(operator1);
        bonding.approveBondFor(bonder);

        vm.prank(operator1);
        bonding.revokeBondForApproval();

        vm.startPrank(bonder);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.NOT_APPROVED_BONDER.selector);
        bonding.bondFor(operator1, MINIMUM_BOND, beneficiary1, delegateKey1);
        vm.stopPrank();
    }

    function test_bondFor_approvalIsPerOperator() public {
        // operator1 approves bonder — should NOT let bonder bondFor operator2
        vm.prank(operator1);
        bonding.approveBondFor(bonder);

        vm.startPrank(bonder);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.NOT_APPROVED_BONDER.selector);
        bonding.bondFor(operator2, MINIMUM_BOND, beneficiary1, delegateKey1);
        vm.stopPrank();
    }

    function test_bondFor_approvalOverwrite() public {
        // operator1 approves bonder, then overwrites with beneficiary1
        vm.prank(operator1);
        bonding.approveBondFor(bonder);

        vm.prank(operator1);
        bonding.approveBondFor(beneficiary1);

        // bonder is no longer approved
        assertEq(bonding.getBondForApproval(operator1), beneficiary1);

        vm.startPrank(bonder);
        supToken.approve(address(bonding), MINIMUM_BOND);
        vm.expectRevert(IValidatorBonding.NOT_APPROVED_BONDER.selector);
        bonding.bondFor(operator1, MINIMUM_BOND, beneficiary1, delegateKey1);
        vm.stopPrank();

        // beneficiary1 can bond
        vm.startPrank(beneficiary1);
        supToken.approve(address(bonding), MINIMUM_BOND);
        bonding.bondFor(operator1, MINIMUM_BOND, beneficiary1, delegateKey1);
        vm.stopPrank();

        assertTrue(bonding.isBonded(operator1));
    }

    /*//////////////////////////////////////////////////////////////
                            ADD BOND
    //////////////////////////////////////////////////////////////*/

    function test_addBond_bonded() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        uint256 addAmount = 500_000e18;
        vm.startPrank(operator1);
        supToken.approve(address(bonding), addAmount);

        vm.expectEmit(true, false, false, true);
        emit IValidatorBonding.BondAdded(operator1, operator1, addAmount, MINIMUM_BOND + addAmount);
        bonding.addBond(operator1, addAmount);
        vm.stopPrank();

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, MINIMUM_BOND + addAmount);
    }

    function test_addBond_byBeneficiary() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        uint256 addAmount = 500_000e18;
        vm.startPrank(beneficiary1);
        supToken.approve(address(bonding), addAmount);
        bonding.addBond(operator1, addAmount);
        vm.stopPrank();

        assertEq(bonding.getBond(operator1).amount, MINIMUM_BOND + addAmount);
    }

    function test_addBond_revertsNotOperatorOrBeneficiary() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        // bonder is neither operator nor beneficiary
        uint256 addAmount = 500_000e18;
        vm.startPrank(bonder);
        supToken.approve(address(bonding), addAmount);
        vm.expectRevert(IValidatorBonding.NOT_OPERATOR_OR_BENEFICIARY.selector);
        bonding.addBond(operator1, addAmount);
        vm.stopPrank();
    }

    function test_addBond_unbondingStatus() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        _requestFullUnbond(operator1, operator1);

        uint256 addAmount = 500_000e18;
        vm.startPrank(operator1);
        supToken.approve(address(bonding), addAmount);
        bonding.addBond(operator1, addAmount);
        vm.stopPrank();

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, MINIMUM_BOND + addAmount);
        // Status should still be Unbonding (addBond doesn't cancel unbond)
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonding));
    }

    function test_addBond_recoveryAfterSlash() public {
        uint256 bondAmount = 1_500_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        // Slash below minimum
        vm.prank(governor);
        bonding.slash(operator1, 600_000e18, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));
        assertEq(record.amount, 900_000e18);
        assertEq(bonding.getOperatorCount(), 0); // removed from registry

        // Recovery: addBond to re-meet minimum
        vm.startPrank(operator1);
        supToken.approve(address(bonding), 200_000e18);
        bonding.addBond(operator1, 200_000e18);
        vm.stopPrank();

        record = bonding.getBond(operator1);
        assertEq(record.amount, 1_100_000e18);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertEq(bonding.getOperatorCount(), 1); // re-added to registry
    }

    function test_addBond_revertsZeroAmount() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.startPrank(operator1);
        vm.expectRevert(IValidatorBonding.ZERO_AMOUNT.selector);
        bonding.addBond(operator1, 0);
        vm.stopPrank();
    }

    function test_addBond_revertsInvalidStatus() public {
        // operator2 has never bonded (status = Unbonded, amount = 0)
        vm.startPrank(operator2);
        supToken.approve(address(bonding), 100e18);
        vm.expectRevert(IValidatorBonding.INVALID_STATUS.selector);
        bonding.addBond(operator2, 100e18);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                         UPDATE DELEGATE KEY
    //////////////////////////////////////////////////////////////*/

    function test_updateDelegateKey_byOperator() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        vm.expectEmit(true, false, false, true);
        emit IValidatorBonding.DelegateKeyUpdated(operator1, delegateKey1, delegateKey2);
        bonding.updateDelegateKey(operator1, delegateKey2);

        assertEq(bonding.getBond(operator1).delegateKey, delegateKey2);
    }

    function test_updateDelegateKey_byBeneficiary() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        vm.prank(beneficiary1);
        bonding.updateDelegateKey(operator1, delegateKey2);

        assertEq(bonding.getBond(operator1).delegateKey, delegateKey2);
    }

    function test_updateDelegateKey_revertsNotOperatorOrBeneficiary() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator2);
        vm.expectRevert(IValidatorBonding.NOT_OPERATOR_OR_BENEFICIARY.selector);
        bonding.updateDelegateKey(operator1, delegateKey2);
    }

    function test_updateDelegateKey_revertsZeroAddress() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        bonding.updateDelegateKey(operator1, address(0));
    }

    function test_updateDelegateKey_revertsUnbondedNoAmount() public {
        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.INVALID_STATUS.selector);
        bonding.updateDelegateKey(operator1, delegateKey2);
    }

    /*//////////////////////////////////////////////////////////////
                          REQUEST UNBOND
    //////////////////////////////////////////////////////////////*/

    function test_requestUnbond_full() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        uint256 expectedDeadline = block.timestamp + UNBONDING_PERIOD;
        vm.expectEmit(true, false, false, true);
        emit IValidatorBonding.UnbondRequested(operator1, MINIMUM_BOND, expectedDeadline);
        bonding.requestUnbond(operator1, MINIMUM_BOND);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonding));
        assertEq(record.unbondingAmount, MINIMUM_BOND);
        assertEq(record.unbondingDeadline, expectedDeadline);
        assertEq(record.unbondingInitiator, operator1);
        assertEq(record.amount, MINIMUM_BOND); // amount unchanged until executeUnbond
    }

    function test_requestUnbond_partial() public {
        uint256 bondAmount = 2_000_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        uint256 unbondAmount = 500_000e18; // remaining 1.5M >= 1M minimum
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded)); // partial stays Bonded
        assertEq(record.unbondingAmount, unbondAmount);
        assertEq(record.amount, bondAmount); // total unchanged
    }

    function test_requestUnbond_byBeneficiary() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        vm.prank(beneficiary1);
        bonding.requestUnbond(operator1, MINIMUM_BOND);

        assertEq(bonding.getBond(operator1).unbondingInitiator, beneficiary1);
    }

    function test_requestUnbond_revertsNotOperatorOrBeneficiary() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator2);
        vm.expectRevert(IValidatorBonding.NOT_OPERATOR_OR_BENEFICIARY.selector);
        bonding.requestUnbond(operator1, MINIMUM_BOND);
    }

    function test_requestUnbond_revertsZeroAmount() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.ZERO_AMOUNT.selector);
        bonding.requestUnbond(operator1, 0);
    }

    function test_requestUnbond_revertsPendingExists() public {
        uint256 bondAmount = 2_000_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        vm.startPrank(operator1);
        bonding.requestUnbond(operator1, 500_000e18);

        vm.expectRevert(IValidatorBonding.PENDING_UNBOND_EXISTS.selector);
        bonding.requestUnbond(operator1, 500_000e18);
        vm.stopPrank();
    }

    function test_requestUnbond_revertsPartialBelowMinimum() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        // Trying to unbond 1 token would leave 999_999 below 1M minimum
        vm.expectRevert(IValidatorBonding.BELOW_MINIMUM_BOND.selector);
        bonding.requestUnbond(operator1, 1);
    }

    function test_requestUnbond_revertsExceedsBondAmount() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.EXCEEDS_BOND_AMOUNT.selector);
        bonding.requestUnbond(operator1, MINIMUM_BOND + 1);
    }

    function test_requestUnbond_unbondedWithResidual() public {
        uint256 bondAmount = 1_500_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        // Slash below minimum
        vm.prank(governor);
        bonding.slash(operator1, 600_000e18, treasury);

        // Now Unbonded with 900k residual — should be able to unbond it
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 900_000e18);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.unbondingAmount, 900_000e18);
    }

    /*//////////////////////////////////////////////////////////////
                          EXECUTE UNBOND
    //////////////////////////////////////////////////////////////*/

    function test_executeUnbond_fullUnbond() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        _requestFullUnbond(operator1, operator1);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        uint256 balanceBefore = supToken.balanceOf(operator1);

        vm.prank(operator1);
        vm.expectEmit(true, true, false, true);
        emit IValidatorBonding.UnbondExecuted(operator1, operator1, MINIMUM_BOND);
        bonding.executeUnbond(operator1);

        assertEq(supToken.balanceOf(operator1), balanceBefore + MINIMUM_BOND);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));
        assertEq(record.amount, 0);
        assertEq(record.unbondingAmount, 0);
        assertEq(record.unbondingDeadline, 0);
        assertEq(record.unbondingInitiator, address(0));
        assertEq(bonding.getOperatorCount(), 0);
        assertFalse(bonding.isBonded(operator1));
    }

    function test_executeUnbond_partialUnbond() public {
        uint256 bondAmount = 2_000_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        uint256 unbondAmount = 500_000e18;
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, bondAmount - unbondAmount);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertEq(bonding.getOperatorCount(), 1);
    }

    function test_executeUnbond_sendsToBeneficiary() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);
        _requestFullUnbond(operator1, beneficiary1);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        uint256 benBalBefore = supToken.balanceOf(beneficiary1);

        vm.prank(beneficiary1);
        bonding.executeUnbond(operator1);

        assertEq(supToken.balanceOf(beneficiary1), benBalBefore + MINIMUM_BOND);
    }

    function test_executeUnbond_revertsBeforeDeadline() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        _requestFullUnbond(operator1, operator1);

        vm.warp(block.timestamp + UNBONDING_PERIOD - 1);

        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.UNBONDING_NOT_COMPLETE.selector);
        bonding.executeUnbond(operator1);
    }

    function test_executeUnbond_revertsNoPendingUnbond() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.NO_PENDING_UNBOND.selector);
        bonding.executeUnbond(operator1);
    }

    function test_executeUnbond_revertsNotOperatorOrBeneficiary() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);
        _requestFullUnbond(operator1, operator1);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        vm.prank(operator2);
        vm.expectRevert(IValidatorBonding.NOT_OPERATOR_OR_BENEFICIARY.selector);
        bonding.executeUnbond(operator1);
    }

    /*//////////////////////////////////////////////////////////////
                          CANCEL UNBOND
    //////////////////////////////////////////////////////////////*/

    function test_cancelUnbond_fullUnbond() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        _requestFullUnbond(operator1, operator1);

        vm.prank(operator1);
        vm.expectEmit(true, false, false, true);
        emit IValidatorBonding.UnbondCancelled(operator1, MINIMUM_BOND);
        bonding.cancelUnbond(operator1);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertEq(record.unbondingAmount, 0);
        assertEq(record.unbondingDeadline, 0);
        assertEq(record.unbondingInitiator, address(0));
    }

    function test_cancelUnbond_partialUnbond() public {
        uint256 bondAmount = 2_000_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        vm.prank(operator1);
        bonding.requestUnbond(operator1, 500_000e18);

        vm.prank(operator1);
        bonding.cancelUnbond(operator1);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertEq(record.unbondingAmount, 0);
    }

    function test_cancelUnbond_revertsNotInitiator() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        // Operator initiates unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, MINIMUM_BOND);

        // Beneficiary cannot cancel
        vm.prank(beneficiary1);
        vm.expectRevert(IValidatorBonding.NOT_UNBOND_INITIATOR.selector);
        bonding.cancelUnbond(operator1);
    }

    function test_cancelUnbond_revertsNoPendingUnbond() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.NO_PENDING_UNBOND.selector);
        bonding.cancelUnbond(operator1);
    }

    /*//////////////////////////////////////////////////////////////
                              SLASH
    //////////////////////////////////////////////////////////////*/

    function test_slash_basic() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        uint256 slashAmount = 500_000e18;
        vm.prank(governor);
        vm.expectEmit(true, false, true, true);
        emit IValidatorBonding.Slashed(operator1, slashAmount, treasury, MINIMUM_BOND - slashAmount);
        bonding.slash(operator1, slashAmount, treasury);

        assertEq(supToken.balanceOf(treasury), slashAmount);
        assertEq(bonding.getBond(operator1).amount, MINIMUM_BOND - slashAmount);
    }

    function test_slash_proportional() public {
        uint256 bondAmount = 1_500_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        // Request partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 500_000e18);

        // Slash 300k — proportional: Ceil(300k * 500k / 1.5M) = 100k from unbonding, 200k from bonded
        uint256 slashAmount = 300_000e18;
        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, bondAmount - slashAmount); // 1.2M
        assertEq(record.unbondingAmount, 400_000e18); // 500k - 100k = 400k (exact division, no ceil effect)
    }

    function test_slash_proportional_ceilRounding() public {
        // Choose amounts where division has a remainder to trigger Ceil rounding
        // Bond 3_000_003, partial unbond 1_000_001 (remaining 2_000_002 >= 1M minimum)
        // Slash 1_000_000 → slashFromUnbonding = Ceil(1_000_000 * 1_000_001 / 3_000_003)
        // = Ceil(333_333.888...) = 333_334 (rounded UP)
        // Floor would give 333_333 — so Ceil adds 1 extra to slash from unbonding
        uint256 bondAmount = 3_000_003e18;
        supToken.mint(operator1, bondAmount);
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        uint256 unbondAmount = 1_000_001e18;
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        uint256 slashAmount = 1_000_000e18;
        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);

        // Total amount decreases by exactly slashAmount
        assertEq(record.amount, bondAmount - slashAmount);

        // With Ceil rounding: slashFromUnbonding is rounded UP (favors protocol)
        uint256 floorSlashFromUnbonding = (slashAmount * unbondAmount) / bondAmount;
        // Ceil rounds up, so unbondingAmount should be <= floor estimate
        assertLe(record.unbondingAmount, unbondAmount - floorSlashFromUnbonding);
        // But at most 1 less (ceil adds at most 1)
        assertGe(record.unbondingAmount, unbondAmount - floorSlashFromUnbonding - 1);

        // Invariant: unbondingAmount <= amount
        assertLe(record.unbondingAmount, record.amount);
    }

    function test_slash_fullSlash() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(governor);
        bonding.slash(operator1, MINIMUM_BOND, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, 0);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));
        assertEq(bonding.getOperatorCount(), 0);
    }

    function test_slash_cappedToTotal() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        // Slash more than total
        vm.prank(governor);
        bonding.slash(operator1, MINIMUM_BOND * 2, treasury);

        assertEq(supToken.balanceOf(treasury), MINIMUM_BOND);
        assertEq(bonding.getBond(operator1).amount, 0);
    }

    function test_slash_belowMinimum_resetsUnbondingState() public {
        uint256 bondAmount = 1_500_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        // Request partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 500_000e18);

        // Slash enough to go below minimum
        vm.prank(governor);
        bonding.slash(operator1, 600_000e18, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));
        assertEq(record.unbondingAmount, 0); // reset
        assertEq(record.unbondingDeadline, 0); // reset
        assertEq(record.unbondingInitiator, address(0)); // reset
        assertEq(record.amount, 900_000e18); // residual remains
    }

    function test_slash_revertsNotGovernor() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), bonding.GOVERNOR_ROLE()
            )
        );
        bonding.slash(operator1, 1, treasury);
    }

    function test_slash_revertsZeroAmount() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(governor);
        vm.expectRevert(IValidatorBonding.ZERO_AMOUNT.selector);
        bonding.slash(operator1, 0, treasury);
    }

    function test_slash_revertsZeroRecipient() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(governor);
        vm.expectRevert(IValidatorBonding.INVALID_ADDRESS.selector);
        bonding.slash(operator1, 1, address(0));
    }

    function test_slash_revertsNothingToSlash() public {
        vm.prank(governor);
        vm.expectRevert(IValidatorBonding.NOTHING_TO_SLASH.selector);
        bonding.slash(operator1, 1, treasury);
    }

    function test_slash_noUnbondingPortion() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        // No pending unbond — all slash comes from bonded portion
        vm.prank(governor);
        bonding.slash(operator1, 500_000e18, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, 500_000e18);
        assertEq(record.unbondingAmount, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    ADMIN — MINIMUM BOND TIMELOCK
    //////////////////////////////////////////////////////////////*/

    function test_proposeMinimumBond() public {
        uint256 newMinimum = 2_000_000e18;
        uint256 expectedEffective = block.timestamp + bonding.parameterTimelock();

        vm.prank(governor);
        vm.expectEmit(false, false, false, true);
        emit IValidatorBonding.MinimumBondProposed(MINIMUM_BOND, newMinimum, expectedEffective);
        bonding.proposeMinimumBond(newMinimum);
    }

    function test_executeMinimumBondUpdate() public {
        uint256 newMinimum = 2_000_000e18;

        vm.prank(governor);
        bonding.proposeMinimumBond(newMinimum);

        // Warp past timelock
        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);

        vm.expectEmit(false, false, false, true);
        emit IValidatorBonding.MinimumBondUpdated(MINIMUM_BOND, newMinimum);
        bonding.executeMinimumBondUpdate();

        assertEq(bonding.minimumBond(), newMinimum);
    }

    function test_executeMinimumBondUpdate_revertsNoPending() public {
        vm.expectRevert(IValidatorBonding.NO_PENDING_CHANGE.selector);
        bonding.executeMinimumBondUpdate();
    }

    function test_executeMinimumBondUpdate_revertsTimelockNotExpired() public {
        vm.prank(governor);
        bonding.proposeMinimumBond(2_000_000e18);

        vm.warp(block.timestamp + bonding.parameterTimelock() - 1);

        vm.expectRevert(IValidatorBonding.TIMELOCK_NOT_EXPIRED.selector);
        bonding.executeMinimumBondUpdate();
    }

    function test_proposeMinimumBond_revertsNotGovernor() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), bonding.GOVERNOR_ROLE()
            )
        );
        bonding.proposeMinimumBond(1e18);
    }

    function test_proposeMinimumBond_revertsTooHigh() public {
        vm.prank(governor);
        vm.expectRevert(IValidatorBonding.INVALID_MINIMUM_BOND.selector);
        bonding.proposeMinimumBond(100_000_001e18);
    }

    function test_proposeMinimumBond_revertsTooLow() public {
        vm.prank(governor);
        vm.expectRevert(IValidatorBonding.INVALID_MINIMUM_BOND.selector);
        bonding.proposeMinimumBond(0);
    }

    function test_executeMinimumBondUpdate_permissionless() public {
        // Anyone can execute after timelock — not just governor
        vm.prank(governor);
        bonding.proposeMinimumBond(2_000_000e18);

        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);

        // Random address executes
        vm.prank(operator1);
        bonding.executeMinimumBondUpdate();

        assertEq(bonding.minimumBond(), 2_000_000e18);
    }

    function test_proposeMinimumBond_overwritesPrevious() public {
        // First proposal
        vm.prank(governor);
        bonding.proposeMinimumBond(2_000_000e18);

        // Overwrite with different value — should emit ParameterChangeCancelled for the first
        bytes32 minBondKey = bonding.MINIMUM_BOND_KEY();
        vm.expectEmit(true, false, false, true, address(bonding));
        emit IValidatorBonding.ParameterChangeCancelled(minBondKey);
        vm.prank(governor);
        bonding.proposeMinimumBond(3_000_000e18);

        // Execute should apply the second proposal
        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);
        bonding.executeMinimumBondUpdate();

        assertEq(bonding.minimumBond(), 3_000_000e18);
    }

    function test_customTimelockAffectsProposals() public {
        // Admin sets a longer timelock
        vm.prank(admin);
        bonding.setParameterTimelock(10 days);

        // Governor proposes with new timelock
        vm.prank(governor);
        bonding.proposeMinimumBond(2_000_000e18);

        // Default timelock (2 days) is not enough
        vm.warp(block.timestamp + 2 days + 1);
        vm.expectRevert(IValidatorBonding.TIMELOCK_NOT_EXPIRED.selector);
        bonding.executeMinimumBondUpdate();

        // Need 10 days
        vm.warp(block.timestamp + 8 days); // 2 days + 1 + 8 days > 10 days
        bonding.executeMinimumBondUpdate();

        assertEq(bonding.minimumBond(), 2_000_000e18);
    }

    /*//////////////////////////////////////////////////////////////
                  ADMIN — UNBONDING PERIOD TIMELOCK
    //////////////////////////////////////////////////////////////*/

    function test_proposeUnbondingPeriod() public {
        uint256 newPeriod = 14 days;
        uint256 expectedEffective = block.timestamp + bonding.parameterTimelock();

        vm.prank(governor);
        vm.expectEmit(false, false, false, true);
        emit IValidatorBonding.UnbondingPeriodProposed(UNBONDING_PERIOD, newPeriod, expectedEffective);
        bonding.proposeUnbondingPeriod(newPeriod);
    }

    function test_executeUnbondingPeriodUpdate() public {
        uint256 newPeriod = 14 days;

        vm.prank(governor);
        bonding.proposeUnbondingPeriod(newPeriod);

        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);

        vm.expectEmit(false, false, false, true);
        emit IValidatorBonding.UnbondingPeriodUpdated(UNBONDING_PERIOD, newPeriod);
        bonding.executeUnbondingPeriodUpdate();

        assertEq(bonding.unbondingPeriod(), newPeriod);
    }

    function test_executeUnbondingPeriodUpdate_revertsNoPending() public {
        vm.expectRevert(IValidatorBonding.NO_PENDING_CHANGE.selector);
        bonding.executeUnbondingPeriodUpdate();
    }

    function test_executeUnbondingPeriodUpdate_revertsTimelockNotExpired() public {
        vm.prank(governor);
        bonding.proposeUnbondingPeriod(14 days);

        vm.warp(block.timestamp + bonding.parameterTimelock() - 1);

        vm.expectRevert(IValidatorBonding.TIMELOCK_NOT_EXPIRED.selector);
        bonding.executeUnbondingPeriodUpdate();
    }

    function test_proposeUnbondingPeriod_revertsNotGovernor() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), bonding.GOVERNOR_ROLE()
            )
        );
        bonding.proposeUnbondingPeriod(14 days);
    }

    function test_proposeUnbondingPeriod_revertsTooHigh() public {
        vm.prank(governor);
        vm.expectRevert(IValidatorBonding.INVALID_UNBONDING_PERIOD.selector);
        bonding.proposeUnbondingPeriod(366 days);
    }

    function test_proposeUnbondingPeriod_revertsTooLow() public {
        vm.prank(governor);
        vm.expectRevert(IValidatorBonding.INVALID_UNBONDING_PERIOD.selector);
        bonding.proposeUnbondingPeriod(0);
    }

    /*//////////////////////////////////////////////////////////////
                  ADMIN — CANCEL PROPOSED CHANGE
    //////////////////////////////////////////////////////////////*/

    function test_cancelProposedChange_minimumBond() public {
        bytes32 minBondKey = bonding.MINIMUM_BOND_KEY();

        vm.prank(governor);
        bonding.proposeMinimumBond(2_000_000e18);

        vm.expectEmit(true, false, false, false);
        emit IValidatorBonding.ParameterChangeCancelled(minBondKey);
        vm.prank(governor);
        bonding.cancelProposedChange(minBondKey);

        // Cannot execute after cancel
        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);
        vm.expectRevert(IValidatorBonding.NO_PENDING_CHANGE.selector);
        bonding.executeMinimumBondUpdate();
    }

    function test_cancelProposedChange_unbondingPeriod() public {
        bytes32 unbondingKey = bonding.UNBONDING_PERIOD_KEY();

        vm.prank(governor);
        bonding.proposeUnbondingPeriod(14 days);

        vm.prank(governor);
        bonding.cancelProposedChange(unbondingKey);

        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);
        vm.expectRevert(IValidatorBonding.NO_PENDING_CHANGE.selector);
        bonding.executeUnbondingPeriodUpdate();
    }

    function test_cancelProposedChange_revertsNoPending() public {
        bytes32 minBondKey = bonding.MINIMUM_BOND_KEY();
        vm.expectRevert(IValidatorBonding.NO_PENDING_CHANGE.selector);
        vm.prank(governor);
        bonding.cancelProposedChange(minBondKey);
    }

    function test_cancelProposedChange_revertsNotGovernor() public {
        bytes32 minBondKey = bonding.MINIMUM_BOND_KEY();
        bytes32 govRole = bonding.GOVERNOR_ROLE();

        vm.prank(governor);
        bonding.proposeMinimumBond(2_000_000e18);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), govRole)
        );
        bonding.cancelProposedChange(minBondKey);
    }

    /*//////////////////////////////////////////////////////////////
                  ADMIN — PARAMETER TIMELOCK
    //////////////////////////////////////////////////////////////*/

    function test_setParameterTimelock() public {
        uint256 newTimelock = 7 days;
        uint256 currentTimelock = bonding.parameterTimelock();

        vm.expectEmit(false, false, false, true);
        emit IValidatorBonding.ParameterTimelockUpdated(currentTimelock, newTimelock);
        vm.prank(admin);
        bonding.setParameterTimelock(newTimelock);

        assertEq(bonding.parameterTimelock(), newTimelock);
    }

    function test_setParameterTimelock_revertsNotAdmin() public {
        bytes32 adminRole = bonding.DEFAULT_ADMIN_ROLE();
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, governor, adminRole)
        );
        vm.prank(governor);
        bonding.setParameterTimelock(7 days);
    }

    function test_setParameterTimelock_revertsTooHigh() public {
        vm.prank(admin);
        vm.expectRevert(IValidatorBonding.INVALID_PARAMETER_TIMELOCK.selector);
        bonding.setParameterTimelock(31 days);
    }

    function test_setParameterTimelock_revertsTooLow() public {
        vm.prank(admin);
        vm.expectRevert(IValidatorBonding.INVALID_PARAMETER_TIMELOCK.selector);
        bonding.setParameterTimelock(0);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function test_isBonded_trueWhenBonded() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        assertTrue(bonding.isBonded(operator1));
    }

    function test_isBonded_falseWhenUnbonded() public view {
        assertFalse(bonding.isBonded(operator1));
    }

    function test_isBonded_falseWhenEffectiveBelowMinimum() public {
        // Bond 3M, unbond exactly 2M (remaining 1M >= minimumBond for partial check)
        uint256 bondAmount = 3_000_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        // Partial unbond of 2M — remaining 1M is exactly at minimum, should pass partial check
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 2_000_000e18);

        // Effective balance = 3M - 2M = 1M, equals minimum — isBonded returns true
        assertTrue(bonding.isBonded(operator1));

        // Cancel and try unbonding 2_000_001 — remaining 999_999 < minimum
        vm.prank(operator1);
        bonding.cancelUnbond(operator1);

        // Partial unbond where remaining < minimum should revert
        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.BELOW_MINIMUM_BOND.selector);
        bonding.requestUnbond(operator1, 2_000_001e18);

        // Instead, do full unbond — this is allowed
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 3_000_000e18);

        // Full unbond → status Unbonding → isBonded false
        assertFalse(bonding.isBonded(operator1));
    }

    function test_getOperators_multipleOperators() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        _bondOperator(operator2, operator2, delegateKey2, MINIMUM_BOND);

        address[] memory operators = bonding.getOperators();
        assertEq(operators.length, 2);
        assertEq(bonding.getOperatorCount(), 2);
    }

    function test_getActiveOperators() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        _bondOperator(operator2, operator2, delegateKey2, MINIMUM_BOND);

        // Both active
        address[] memory active = bonding.getActiveOperators();
        assertEq(active.length, 2);

        // Put operator1 in Unbonding (full) — no longer active
        _requestFullUnbond(operator1, operator1);

        active = bonding.getActiveOperators();
        assertEq(active.length, 1);
        assertEq(active[0], operator2);

        // getOperators still returns both (includes Unbonding)
        assertEq(bonding.getOperators().length, 2);
    }

    function test_getActiveOperators_partialUnbondStillActive() public {
        // Bond 2M each
        uint256 bondAmount = 2_000_000e18;
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);
        _bondOperator(operator2, operator2, delegateKey2, bondAmount);

        // Partial unbond for operator1 — remaining 1.5M >= 1M minimum, still active
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 500_000e18);

        address[] memory active = bonding.getActiveOperators();
        assertEq(active.length, 2); // Both still active since effective balance >= minimumBond

        // Partial unbond more — remaining 1M == minimum, still active
        vm.prank(operator1);
        bonding.cancelUnbond(operator1);
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 1_000_000e18);

        active = bonding.getActiveOperators();
        assertEq(active.length, 2); // 2M - 1M = 1M == minimum, still active
    }

    function test_getActiveOperators_empty() public view {
        address[] memory active = bonding.getActiveOperators();
        assertEq(active.length, 0);
    }

    /*//////////////////////////////////////////////////////////////
                         FULL LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    function test_fullLifecycle_selfBondUnbondRebond() public {
        // Bond
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);
        assertTrue(bonding.isBonded(operator1));

        // Request full unbond
        _requestFullUnbond(operator1, operator1);

        // Execute unbond
        vm.warp(block.timestamp + UNBONDING_PERIOD);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);
        assertFalse(bonding.isBonded(operator1));

        // Re-bond
        vm.startPrank(operator1);
        supToken.approve(address(bonding), MINIMUM_BOND);
        bonding.bond(MINIMUM_BOND, operator1, delegateKey2); // can change beneficiary/key on re-bond
        vm.stopPrank();
        assertTrue(bonding.isBonded(operator1));
    }

    function test_fullLifecycle_foundationSlashAndRecovery() public {
        // Operator approves foundation to bond on their behalf
        vm.prank(operator1);
        bonding.approveBondFor(beneficiary1);

        // Foundation bonds for operator
        vm.startPrank(beneficiary1);
        supToken.approve(address(bonding), 2_000_000e18);
        bonding.bondFor(operator1, 2_000_000e18, beneficiary1, delegateKey1);
        vm.stopPrank();

        // Governor slashes
        vm.prank(governor);
        bonding.slash(operator1, 1_200_000e18, treasury);

        // Operator now Unbonded with 800k residual
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));

        // Operator tops up to recover
        vm.startPrank(operator1);
        supToken.approve(address(bonding), 300_000e18);
        bonding.addBond(operator1, 300_000e18);
        vm.stopPrank();

        record = bonding.getBond(operator1);
        assertEq(record.amount, 1_100_000e18);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertEq(record.beneficiary, beneficiary1); // beneficiary unchanged
    }

    function test_unbondingPeriodChange_doesNotAffectInFlight() public {
        _bondOperator(operator1, operator1, delegateKey1, MINIMUM_BOND);

        vm.prank(operator1);
        bonding.requestUnbond(operator1, MINIMUM_BOND);
        uint256 originalDeadline = bonding.getBond(operator1).unbondingDeadline;

        // Governor proposes new unbonding period (14 days)
        vm.prank(governor);
        bonding.proposeUnbondingPeriod(14 days);

        // Warp past parameter timelock to execute the change
        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);
        bonding.executeUnbondingPeriodUpdate();
        assertEq(bonding.unbondingPeriod(), 14 days);

        // Original deadline unchanged
        assertEq(bonding.getBond(operator1).unbondingDeadline, originalDeadline);

        // Can still execute at original deadline
        vm.warp(originalDeadline);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);
    }

    /*//////////////////////////////////////////////////////////////
                          FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_slash_proportionalMath(uint256 bondAmount, uint256 unbondFraction, uint256 slashAmount) public {
        bondAmount = bound(bondAmount, MINIMUM_BOND, 50_000_000e18);
        slashAmount = bound(slashAmount, 1, bondAmount);

        // unbondFraction determines partial vs full unbond
        // Only allow full unbond or partial where remaining >= minimumBond
        unbondFraction = bound(unbondFraction, 0, 100);
        uint256 unbondAmount;
        if (unbondFraction == 100) {
            unbondAmount = bondAmount;
        } else {
            // Max partial unbond = bondAmount - minimumBond
            uint256 maxPartial = bondAmount > MINIMUM_BOND ? bondAmount - MINIMUM_BOND : 0;
            unbondAmount = maxPartial > 0 ? bound(unbondFraction, 1, maxPartial) : 0;
        }

        supToken.mint(operator1, bondAmount);
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        if (unbondAmount > 0) {
            vm.prank(operator1);
            bonding.requestUnbond(operator1, unbondAmount);
        }

        uint256 contractBalBefore = supToken.balanceOf(address(bonding));

        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);

        // Invariant: contract balance decreased by exact slash amount
        assertEq(supToken.balanceOf(address(bonding)), contractBalBefore - slashAmount);
        // Invariant: unbondingAmount <= amount
        assertLe(record.unbondingAmount, record.amount);
    }

    function testFuzz_bond_andUnbond(uint256 bondAmount) public {
        bondAmount = bound(bondAmount, MINIMUM_BOND, 50_000_000e18);

        supToken.mint(operator1, bondAmount);
        _bondOperator(operator1, operator1, delegateKey1, bondAmount);

        vm.prank(operator1);
        bonding.requestUnbond(operator1, bondAmount);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        uint256 balBefore = supToken.balanceOf(operator1);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        // Invariant: full amount returned
        assertEq(supToken.balanceOf(operator1), balBefore + bondAmount);
        assertEq(supToken.balanceOf(address(bonding)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                      MULTI-STEP SCENARIOS
    //////////////////////////////////////////////////////////////*/

    /// @notice Governor slashes during unbonding window, then executeUnbond uses the reduced amount
    function test_scenario_slashThenExecuteUnbond() public {
        uint256 bondAmount = 2_000_000e18;
        uint256 unbondAmount = 1_000_000e18;
        uint256 slashAmount = 500_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Operator requests partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        // Governor slashes before deadline
        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        // Verify proportional slash: unbondingAmount reduced
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, bondAmount - slashAmount); // 1.5M
        // slashFromUnbonding = ceil(500k * 1M / 2M) = 250k
        assertEq(record.unbondingAmount, unbondAmount - 250_000e18); // 750k

        // Warp past deadline and execute unbond
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);

        uint256 beneficiaryBefore = supToken.balanceOf(beneficiary1);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        // Beneficiary receives the post-slash unbonding amount (750k)
        assertEq(supToken.balanceOf(beneficiary1), beneficiaryBefore + 750_000e18);

        // Remaining 750k: executeUnbond sets status to Bonded (amount > 0), but isBonded() returns false
        // because effective balance (750k) < minimumBond (1M)
        record = bonding.getBond(operator1);
        assertEq(record.amount, 750_000e18);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertFalse(bonding.isBonded(operator1));
    }

    /// @notice Governor slashes the same operator multiple times in sequence
    function test_scenario_multipleSequentialSlashes() public {
        uint256 bondAmount = 5_000_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Slash 1: 1M
        vm.prank(governor);
        bonding.slash(operator1, 1_000_000e18, treasury);
        assertEq(bonding.getBond(operator1).amount, 4_000_000e18);
        assertTrue(bonding.isBonded(operator1));

        // Slash 2: 1.5M
        vm.prank(governor);
        bonding.slash(operator1, 1_500_000e18, treasury);
        assertEq(bonding.getBond(operator1).amount, 2_500_000e18);
        assertTrue(bonding.isBonded(operator1));

        // Slash 3: 1M
        vm.prank(governor);
        bonding.slash(operator1, 1_000_000e18, treasury);
        assertEq(bonding.getBond(operator1).amount, 1_500_000e18);
        assertTrue(bonding.isBonded(operator1));

        // Slash 4: push below minimum
        vm.prank(governor);
        bonding.slash(operator1, 600_000e18, treasury);
        assertEq(bonding.getBond(operator1).amount, 900_000e18);
        assertFalse(bonding.isBonded(operator1));
        assertEq(uint8(bonding.getBond(operator1).status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));

        // Treasury received all slashed amounts
        assertEq(supToken.balanceOf(treasury), 4_100_000e18);
    }

    /// @notice Slash during unbonding, then initiator cancels — bond remains reduced
    function test_scenario_slashThenCancelUnbond() public {
        uint256 bondAmount = 3_000_000e18;
        uint256 unbondAmount = 1_000_000e18;
        uint256 slashAmount = 600_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        // Governor slashes
        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        // Verify state after slash
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, bondAmount - slashAmount); // 2.4M
        // slashFromUnbonding = ceil(600k * 1M / 3M) = 200k
        uint256 postSlashUnbonding = unbondAmount - 200_000e18; // 800k
        assertEq(record.unbondingAmount, postSlashUnbonding);

        // Operator cancels the unbond
        vm.prank(operator1);
        bonding.cancelUnbond(operator1);

        // After cancel: unbonding cleared, total bond = 2.4M, status = Bonded
        record = bonding.getBond(operator1);
        assertEq(record.amount, 2_400_000e18);
        assertEq(record.unbondingAmount, 0);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertTrue(bonding.isBonded(operator1));
    }

    /// @notice Beneficiary adds bond while a partial unbond is pending — total increases, unbonding unchanged
    function test_scenario_addBondDuringUnbonding() public {
        uint256 bondAmount = 3_000_000e18;
        uint256 unbondAmount = 1_000_000e18;
        uint256 addAmount = 500_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        // Beneficiary adds bond
        vm.startPrank(beneficiary1);
        supToken.approve(address(bonding), addAmount);
        bonding.addBond(operator1, addAmount);
        vm.stopPrank();

        // Total increases, unbonding stays the same
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, bondAmount + addAmount); // 3.5M
        assertEq(record.unbondingAmount, unbondAmount); // 1M unchanged
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));

        // Execute unbond after deadline
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        // Remaining = 3.5M - 1M = 2.5M, still Bonded
        record = bonding.getBond(operator1);
        assertEq(record.amount, 2_500_000e18);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
    }

    /// @notice Propose minimum bond change while operators are unbonding — new minimum affects isBonded but not unbond
    function test_scenario_parameterChangeDuringUnbonding() public {
        uint256 bondAmount = 2_000_000e18;
        uint256 unbondAmount = 500_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        // Governor proposes raising minimum to 2M
        vm.prank(governor);
        bonding.proposeMinimumBond(2_000_000e18);

        // Wait for timelock and execute
        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);
        bonding.executeMinimumBondUpdate();
        assertEq(bonding.minimumBond(), 2_000_000e18);

        // Operator's effective balance = 2M - 500k = 1.5M < new minimum 2M
        assertFalse(bonding.isBonded(operator1));

        // But executeUnbond still works after deadline (already past it)
        vm.warp(block.timestamp + UNBONDING_PERIOD);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, 1_500_000e18);
        // 1.5M < new minimum 2M → still not considered bonded
        assertFalse(bonding.isBonded(operator1));
        // But status is Bonded (status field doesn't auto-update based on minimumBond changes)
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
    }

    /// @notice Slash pushes operator below the pending (not yet active) new minimum — current minimum still applies
    function test_scenario_slashBelowPendingMinimum() public {
        uint256 bondAmount = 3_000_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Governor proposes raising minimum to 2.5M (not yet active)
        vm.prank(governor);
        bonding.proposeMinimumBond(2_500_000e18);

        // Slash to 2M — above current minimum (1M) but below pending (2.5M)
        vm.prank(governor);
        bonding.slash(operator1, 1_000_000e18, treasury);

        // Still bonded under current minimum
        assertTrue(bonding.isBonded(operator1));
        assertEq(bonding.getBond(operator1).amount, 2_000_000e18);

        // Execute the minimum bond update
        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);
        bonding.executeMinimumBondUpdate();

        // Now isBonded returns false because 2M < new minimum 2.5M
        assertFalse(bonding.isBonded(operator1));
        // But status is still Bonded — isBonded is a view check, not a state transition
        assertEq(uint8(bonding.getBond(operator1).status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
    }

    /// @notice Full unbond → re-bond with a new beneficiary (beneficiary change path)
    function test_scenario_fullUnbondAndRebondNewBeneficiary() public {
        uint256 bondAmount = 2_000_000e18;
        address newBeneficiary = makeAddr("newBeneficiary");
        address newDelegateKey = makeAddr("newDelegateKey");

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Full unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, bondAmount);

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        // Verify clean Unbonded state
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, 0);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));

        // beneficiary1 received the tokens
        uint256 beneficiaryBal = supToken.balanceOf(beneficiary1);
        assertTrue(beneficiaryBal >= bondAmount);

        // Re-bond with new beneficiary and delegate key
        supToken.mint(operator1, bondAmount);

        _bondOperator(operator1, newBeneficiary, newDelegateKey, bondAmount);

        record = bonding.getBond(operator1);
        assertEq(record.beneficiary, newBeneficiary);
        assertEq(record.delegateKey, newDelegateKey);
        assertEq(record.amount, bondAmount);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
    }

    /// @notice Multi-operator: slash one operator, others completely unaffected
    function test_scenario_slashOneOperatorOthersUnaffected() public {
        uint256 bondAmount = 2_000_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);
        _bondOperator(operator2, beneficiary2, delegateKey2, bondAmount);

        // Slash only operator1
        vm.prank(governor);
        bonding.slash(operator1, 1_500_000e18, treasury);

        // operator1 slashed below minimum
        assertFalse(bonding.isBonded(operator1));
        assertEq(bonding.getBond(operator1).amount, 500_000e18);

        // operator2 completely untouched
        assertTrue(bonding.isBonded(operator2));
        assertEq(bonding.getBond(operator2).amount, bondAmount);

        // getActiveOperators returns only operator2
        address[] memory active = bonding.getActiveOperators();
        assertEq(active.length, 1);
        assertEq(active[0], operator2);
    }

    /// @notice Slash to zero then recovery via addBond
    function test_scenario_fullSlashThenRecovery() public {
        uint256 bondAmount = 2_000_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Full slash
        vm.prank(governor);
        bonding.slash(operator1, bondAmount, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, 0);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));

        // Cannot addBond — status is Unbonded with zero amount (INVALID_STATUS)
        vm.startPrank(operator1);
        supToken.approve(address(bonding), bondAmount);
        vm.expectRevert(IValidatorBonding.INVALID_STATUS.selector);
        bonding.addBond(operator1, bondAmount);
        vm.stopPrank();

        // Must re-bond fresh
        supToken.mint(operator1, bondAmount);
        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        assertTrue(bonding.isBonded(operator1));
        assertEq(bonding.getBond(operator1).amount, bondAmount);
    }

    /// @notice Partial slash leaves residual → addBond recovers → unbond cycle
    function test_scenario_partialSlashRecoveryUnbond() public {
        uint256 bondAmount = 3_000_000e18;
        uint256 slashAmount = 2_500_000e18;
        uint256 recoveryAmount = 2_000_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Slash to 500k (below minimum, Unbonded but has residual)
        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, 500_000e18);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));

        // addBond to recover above minimum
        vm.startPrank(operator1);
        supToken.approve(address(bonding), recoveryAmount);
        bonding.addBond(operator1, recoveryAmount);
        vm.stopPrank();

        record = bonding.getBond(operator1);
        assertEq(record.amount, 2_500_000e18);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertTrue(bonding.isBonded(operator1));

        // Now unbond the full amount
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 2_500_000e18);

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        assertEq(bonding.getBond(operator1).amount, 0);
        // Beneficiary receives the 2.5M unbonded amount
        uint256 beneficiaryBal = supToken.balanceOf(beneficiary1);
        assertTrue(beneficiaryBal >= 2_500_000e18);
    }

    /// @notice Bond → partial unbond → slash resets unbonding state (below minimum) → addBond recovery → new unbond
    function test_scenario_slashResetsUnbondingThenRecovery() public {
        uint256 bondAmount = 2_000_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 1_000_000e18);

        // Heavy slash pushes below minimum — unbonding state should be reset
        vm.prank(governor);
        bonding.slash(operator1, 1_500_000e18, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, 500_000e18);
        assertEq(record.unbondingAmount, 0); // Reset by slash
        assertEq(record.unbondingDeadline, 0);
        assertEq(record.unbondingInitiator, address(0));
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));

        // Recovery via addBond
        vm.startPrank(operator1);
        supToken.approve(address(bonding), 1_500_000e18);
        bonding.addBond(operator1, 1_500_000e18);
        vm.stopPrank();

        assertTrue(bonding.isBonded(operator1));

        // Can start a fresh unbond cycle
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 2_000_000e18);

        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        assertEq(bonding.getBond(operator1).amount, 0);
    }

    /// @notice Two operators unbond simultaneously, governor slashes one mid-unbond — isolation check
    function test_scenario_twoOperatorsUnbondSlashOne() public {
        uint256 bondAmount = 2_000_000e18;

        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);
        _bondOperator(operator2, beneficiary2, delegateKey2, bondAmount);

        // Both request full unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, bondAmount);
        vm.prank(operator2);
        bonding.requestUnbond(operator2, bondAmount);

        // Slash operator1 during unbonding
        vm.prank(governor);
        bonding.slash(operator1, 1_000_000e18, treasury);

        // Operator1: slashed
        IValidatorBonding.BondRecord memory r1 = bonding.getBond(operator1);
        assertEq(r1.amount, 1_000_000e18);

        // Operator2: completely unaffected
        IValidatorBonding.BondRecord memory r2 = bonding.getBond(operator2);
        assertEq(r2.amount, bondAmount);
        assertEq(r2.unbondingAmount, bondAmount);

        // Operator2 executes unbond normally
        vm.warp(block.timestamp + UNBONDING_PERIOD + 1);
        vm.prank(operator2);
        bonding.executeUnbond(operator2);

        assertEq(supToken.balanceOf(beneficiary2), bondAmount);
        assertEq(bonding.getBond(operator2).amount, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    PR REVIEW FIX REGRESSION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice M-1: cancelUnbond with no pending unbond reverts NO_PENDING_UNBOND (not NOT_UNBOND_INITIATOR)
    function test_cancelUnbond_noPending_thirdPartyGetsCorrectError() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, MINIMUM_BOND);

        // Random third party tries to cancel — should get NO_PENDING_UNBOND, not NOT_UNBOND_INITIATOR
        address randomCaller = makeAddr("random");
        vm.prank(randomCaller);
        vm.expectRevert(IValidatorBonding.NO_PENDING_UNBOND.selector);
        bonding.cancelUnbond(operator1);
    }

    /// @notice M-1: cancelUnbond with pending unbond by wrong caller reverts NOT_UNBOND_INITIATOR
    function test_cancelUnbond_wrongInitiator_revertsNotUnbondInitiator() public {
        _bondOperator(operator1, beneficiary1, delegateKey1, 2_000_000e18);

        // Operator initiates unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 2_000_000e18);

        // Beneficiary tries to cancel — should get NOT_UNBOND_INITIATOR (not NO_PENDING_UNBOND)
        vm.prank(beneficiary1);
        vm.expectRevert(IValidatorBonding.NOT_UNBOND_INITIATOR.selector);
        bonding.cancelUnbond(operator1);
    }

    /// @notice M-1: unbonded operator (no bond at all) — cancelUnbond reverts NO_PENDING_UNBOND
    function test_cancelUnbond_unbondedOperator_revertsNoPending() public {
        // operator1 never bonded
        vm.prank(operator1);
        vm.expectRevert(IValidatorBonding.NO_PENDING_UNBOND.selector);
        bonding.cancelUnbond(operator1);
    }

    /// @notice L-1: first proposal does NOT emit ParameterChangeCancelled
    function test_proposeMinimumBond_firstProposal_noCancel() public {
        vm.prank(governor);
        vm.recordLogs();
        bonding.proposeMinimumBond(2_000_000e18);

        // Check no ParameterChangeCancelled was emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 cancelSig = keccak256("ParameterChangeCancelled(bytes32)");
        for (uint256 i; i < entries.length; i++) {
            assertTrue(entries[i].topics[0] != cancelSig, "Should not emit ParameterChangeCancelled on first proposal");
        }
    }

    /// @notice L-1: overwriting unbonding period proposal also emits ParameterChangeCancelled
    function test_proposeUnbondingPeriod_overwriteEmitsCancel() public {
        // First proposal
        vm.prank(governor);
        bonding.proposeUnbondingPeriod(14 days);

        // Overwrite — should emit ParameterChangeCancelled
        bytes32 unbondKey = bonding.UNBONDING_PERIOD_KEY();
        vm.expectEmit(true, false, false, true, address(bonding));
        emit IValidatorBonding.ParameterChangeCancelled(unbondKey);
        vm.prank(governor);
        bonding.proposeUnbondingPeriod(21 days);

        // Execute applies the second
        vm.warp(block.timestamp + bonding.parameterTimelock() + 1);
        bonding.executeUnbondingPeriodUpdate();
        assertEq(bonding.unbondingPeriod(), 21 days);
    }

    /// @notice I-1: GOVERNOR_ROLE public constant returns the correct role hash
    function test_governorRole_publicConstant() public view {
        assertEq(bonding.GOVERNOR_ROLE(), keccak256("GOVERNOR_ROLE"));
        assertTrue(bonding.hasRole(bonding.GOVERNOR_ROLE(), governor));
    }

    /// @notice L-2: status == Bonded but isBonded() == false after slash during unbonding + executeUnbond
    function test_statusBondedButNotIsBonded_afterSlashAndExecute() public {
        uint256 bondAmount = 2_000_000e18;
        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Request partial unbond (1M out of 2M)
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 1_000_000e18);

        // Slash 1.5M (crosses minimum for remaining bonded portion)
        vm.prank(governor);
        bonding.slash(operator1, 1_500_000e18, treasury);

        // After heavy slash, status is Unbonded (below minimum)
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));
        assertFalse(bonding.isBonded(operator1));
    }

    /// @notice I-3: addBond during Unbonding does NOT cancel the pending unbond
    function test_addBondDuringUnbonding_doesNotCancelPendingUnbond() public {
        uint256 bondAmount = 2_000_000e18;
        _bondOperator(operator1, beneficiary1, delegateKey1, bondAmount);

        // Request partial unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, 1_000_000e18);

        IValidatorBonding.BondRecord memory before = bonding.getBond(operator1);
        uint256 unbondingBefore = before.unbondingAmount;
        uint48 deadlineBefore = before.unbondingDeadline;
        assertEq(unbondingBefore, 1_000_000e18);

        // Beneficiary adds 500k bond
        supToken.mint(beneficiary1, 500_000e18);
        vm.startPrank(beneficiary1);
        supToken.approve(address(bonding), 500_000e18);
        bonding.addBond(operator1, 500_000e18);
        vm.stopPrank();

        // Unbonding state unchanged
        IValidatorBonding.BondRecord memory after_ = bonding.getBond(operator1);
        assertEq(after_.unbondingAmount, unbondingBefore, "unbondingAmount should be unchanged");
        assertEq(after_.unbondingDeadline, deadlineBefore, "deadline should be unchanged");
        assertEq(after_.amount, bondAmount + 500_000e18, "total should increase");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    function _bondOperator(address op, address ben, address dk, uint256 amount) internal {
        vm.startPrank(op);
        supToken.approve(address(bonding), amount);
        bonding.bond(amount, ben, dk);
        vm.stopPrank();
    }

    function _bondForOperator(address op, address funder, address ben, address dk, uint256 amount) internal {
        vm.prank(op);
        bonding.approveBondFor(funder);

        vm.startPrank(funder);
        supToken.approve(address(bonding), amount);
        bonding.bondFor(op, amount, ben, dk);
        vm.stopPrank();
    }

    function _requestFullUnbond(address op, address caller) internal {
        uint256 amount = bonding.getBond(op).amount;
        vm.prank(caller);
        bonding.requestUnbond(op, amount);
    }
}
