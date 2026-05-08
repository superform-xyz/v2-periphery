// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { ValidatorBonding } from "../../src/ValidatorBonding.sol";
import { IValidatorBonding } from "../../src/interfaces/IValidatorBonding.sol";
import { ISuperGovernor } from "../../src/interfaces/ISuperGovernor.sol";

/// @title ValidatorBondingForkTest
/// @notice Integration tests against real Base mainnet contracts
/// @dev Forks Base mainnet, deposits UP into the sUP SuperVault, then bonds sUP in ValidatorBonding
contract ValidatorBondingForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                    PRODUCTION ADDRESSES (BASE)
    //////////////////////////////////////////////////////////////*/

    /// @dev UP token on Base
    address constant UP_TOKEN = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;

    /// @dev sUP SuperVault (ERC4626, asset = UP)
    address constant SUP_VAULT = 0x2c71f70e2Ec720AE061Ae7E0316fC9654d94f417;

    /// @dev SuperGovernor on Base
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    /*//////////////////////////////////////////////////////////////
                            TEST STATE
    //////////////////////////////////////////////////////////////*/

    ValidatorBonding public bonding;
    IERC20 public up;
    IERC4626 public supVault;
    IERC20 public sup;

    address public admin = makeAddr("admin");
    address public governor = makeAddr("governor");
    address public operator1 = makeAddr("operator1");
    address public operator2 = makeAddr("operator2");
    address public foundation = makeAddr("foundation");
    address public delegateKey1 = makeAddr("delegateKey1");
    address public delegateKey2 = makeAddr("delegateKey2");
    address public treasury = makeAddr("treasury");

    uint256 public constant MINIMUM_BOND = 1_000_000e18;
    uint256 public constant UNBONDING_PERIOD = 7 days;

    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        up = IERC20(UP_TOKEN);
        supVault = IERC4626(SUP_VAULT);
        sup = IERC20(SUP_VAULT); // sUP shares are the vault token itself

        // Verify fork state
        assertEq(supVault.asset(), UP_TOKEN, "sUP vault asset should be UP");

        // Deploy ValidatorBonding against real sUP token
        bonding = new ValidatorBonding(SUP_VAULT, MINIMUM_BOND, UNBONDING_PERIOD, admin, governor);
    }

    /*//////////////////////////////////////////////////////////////
                       DEPOSIT UP → GET sUP
    //////////////////////////////////////////////////////////////*/

    /// @notice Helper: give UP tokens and deposit into sUP vault
    /// @param user The user depositing
    /// @param upAmount Amount of UP to deposit
    /// @return supShares Amount of sUP shares received
    function _depositUpForSup(address user, uint256 upAmount) internal returns (uint256 supShares) {
        // Deal UP tokens to user
        deal(UP_TOKEN, user, upAmount);

        vm.startPrank(user);
        up.approve(SUP_VAULT, upAmount);
        supShares = supVault.deposit(upAmount, user);
        vm.stopPrank();

        assertGt(supShares, 0, "Should receive sUP shares");
    }

    /*//////////////////////////////////////////////////////////////
                    INTEGRATION: DEPOSIT UP → BOND sUP
    //////////////////////////////////////////////////////////////*/

    function test_fork_depositUpAndBond() public {
        // Step 1: Operator deposits UP into sUP vault
        uint256 upAmount = 2_000_000e18; // deposit 2M UP
        uint256 supShares = _depositUpForSup(operator1, upAmount);

        // Step 2: Operator bonds sUP in ValidatorBonding
        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares);
        bonding.bond(supShares, operator1, delegateKey1);
        vm.stopPrank();

        // Verify bond state
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, supShares);
        assertEq(record.beneficiary, operator1);
        assertEq(record.delegateKey, delegateKey1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertTrue(bonding.isBonded(operator1));

        // sUP transferred to bonding contract
        assertEq(sup.balanceOf(address(bonding)), supShares);
        assertEq(sup.balanceOf(operator1), 0);
    }

    function test_fork_foundationBondsForOperator() public {
        // Foundation gets UP and deposits for sUP
        uint256 upAmount = 2_000_000e18;
        uint256 supShares = _depositUpForSup(foundation, upAmount);

        // Operator approves foundation to bond on their behalf
        vm.prank(operator1);
        bonding.approveBondFor(foundation);

        // Foundation bonds sUP on behalf of operator
        vm.startPrank(foundation);
        sup.approve(address(bonding), supShares);
        bonding.bondFor(operator1, supShares, foundation, delegateKey1);
        vm.stopPrank();

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(record.amount, supShares);
        assertEq(record.beneficiary, foundation); // Foundation is beneficiary
        assertTrue(bonding.isBonded(operator1));
    }

    function test_fork_fullBondUnbondLifecycle() public {
        // Step 1: Deposit UP → sUP → bond
        uint256 upAmount = 2_000_000e18;
        uint256 supShares = _depositUpForSup(operator1, upAmount);

        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares);
        bonding.bond(supShares, operator1, delegateKey1);
        vm.stopPrank();

        assertTrue(bonding.isBonded(operator1));

        // Step 2: Request full unbond
        vm.prank(operator1);
        bonding.requestUnbond(operator1, supShares);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonding));

        // Step 3: Wait for unbonding period
        vm.warp(block.timestamp + UNBONDING_PERIOD);

        // Step 4: Execute unbond — sUP returns to operator (beneficiary)
        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        assertEq(sup.balanceOf(operator1), supShares);
        assertEq(sup.balanceOf(address(bonding)), 0);
        assertFalse(bonding.isBonded(operator1));

        // Step 5: Operator can redeem sUP back to UP via the vault
        vm.startPrank(operator1);
        // Note: SuperVault uses async redeem (ERC-7540), so requestRedeem + fulfillment
        // We just verify the sUP balance is back — full redemption flow is out of scope
        assertEq(sup.balanceOf(operator1), supShares);
        vm.stopPrank();
    }

    function test_fork_slashAndRecovery() public {
        // Operator bonds
        uint256 upAmount = 2_000_000e18;
        uint256 supShares = _depositUpForSup(operator1, upAmount);

        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares);
        bonding.bond(supShares, operator1, delegateKey1);
        vm.stopPrank();

        uint256 bondedShares = bonding.getBond(operator1).amount;

        // Governor slashes 60% of bond
        uint256 slashAmount = (bondedShares * 60) / 100;
        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        // Slashed sUP goes to treasury
        assertEq(sup.balanceOf(treasury), slashAmount);

        // Operator has residual bond below minimum → status Unbonded
        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);
        uint256 remaining = bondedShares - slashAmount;
        assertEq(record.amount, remaining);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Unbonded));
        assertEq(bonding.getOperatorCount(), 0);

        // Recovery: operator deposits more UP → sUP → addBond
        uint256 topUpUp = 2_000_000e18;
        uint256 topUpShares = _depositUpForSup(operator1, topUpUp);

        vm.startPrank(operator1);
        sup.approve(address(bonding), topUpShares);
        bonding.addBond(operator1, topUpShares);
        vm.stopPrank();

        // Should be recovered now
        record = bonding.getBond(operator1);
        assertEq(record.amount, remaining + topUpShares);
        assertEq(uint8(record.status), uint8(IValidatorBonding.ValidatorStatus.Bonded));
        assertEq(bonding.getOperatorCount(), 1);
        assertTrue(bonding.isBonded(operator1));
    }

    function test_fork_multipleValidators() public {
        // Operator 1 self-bonds
        uint256 supShares1 = _depositUpForSup(operator1, 2_000_000e18);
        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares1);
        bonding.bond(supShares1, operator1, delegateKey1);
        vm.stopPrank();

        // Operator 2 approves foundation, then foundation bonds for operator 2
        vm.prank(operator2);
        bonding.approveBondFor(foundation);

        uint256 supShares2 = _depositUpForSup(foundation, 3_000_000e18);
        vm.startPrank(foundation);
        sup.approve(address(bonding), supShares2);
        bonding.bondFor(operator2, supShares2, foundation, delegateKey2);
        vm.stopPrank();

        // Both bonded
        assertTrue(bonding.isBonded(operator1));
        assertTrue(bonding.isBonded(operator2));
        assertEq(bonding.getOperatorCount(), 2);

        address[] memory operators = bonding.getOperators();
        assertEq(operators.length, 2);

        // Total sUP held
        assertEq(sup.balanceOf(address(bonding)), supShares1 + supShares2);
    }

    function test_fork_foundationUnbondsLoan() public {
        // Operator approves foundation
        vm.prank(operator1);
        bonding.approveBondFor(foundation);

        // Foundation bonds for operator
        uint256 supShares = _depositUpForSup(foundation, 2_000_000e18);
        vm.startPrank(foundation);
        sup.approve(address(bonding), supShares);
        bonding.bondFor(operator1, supShares, foundation, delegateKey1);
        vm.stopPrank();

        // Foundation pulls back the loan (beneficiary initiates unbond)
        vm.prank(foundation);
        bonding.requestUnbond(operator1, supShares);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        // Foundation executes unbond — sUP goes to foundation (beneficiary), NOT operator
        uint256 foundationBalBefore = sup.balanceOf(foundation);
        vm.prank(foundation);
        bonding.executeUnbond(operator1);

        assertEq(sup.balanceOf(foundation), foundationBalBefore + supShares);
        assertEq(sup.balanceOf(operator1), 0); // operator gets nothing
        assertFalse(bonding.isBonded(operator1));
    }

    function test_fork_supVaultSharesAreTransferableForBonding() public {
        // Verify that sUP (SuperVault shares) work correctly as an ERC20 for bonding
        uint256 upAmount = 2_000_000e18;
        uint256 supShares = _depositUpForSup(operator1, upAmount);

        // Verify sUP properties
        assertGt(supShares, 0);
        assertEq(sup.balanceOf(operator1), supShares);

        // sUP should be 18 decimals (SuperVault shares)
        assertEq(IERC4626(SUP_VAULT).decimals(), 18);

        // Verify the vault's totalAssets makes sense
        assertGt(supVault.totalAssets(), 0);

        // Bond it
        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares);
        bonding.bond(supShares, operator1, delegateKey1);
        vm.stopPrank();

        assertTrue(bonding.isBonded(operator1));
    }

    function test_fork_proportionalSlashWithUnbonding() public {
        // Bond 3M UP worth of sUP
        uint256 supShares = _depositUpForSup(operator1, 3_000_000e18);

        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares);
        bonding.bond(supShares, operator1, delegateKey1);
        vm.stopPrank();

        uint256 totalBonded = bonding.getBond(operator1).amount;

        // Request partial unbond of ~1/3
        uint256 unbondAmount = totalBonded / 3;
        vm.prank(operator1);
        bonding.requestUnbond(operator1, unbondAmount);

        // Slash 30% of total
        uint256 slashAmount = (totalBonded * 30) / 100;
        vm.prank(governor);
        bonding.slash(operator1, slashAmount, treasury);

        IValidatorBonding.BondRecord memory record = bonding.getBond(operator1);

        // Verify proportional slash math (uses Ceil rounding — rounds against operator)
        // slashFromUnbonding = Ceil(slashAmount * unbondAmount / totalBonded)
        uint256 expectedSlashFromUnbondingFloor = (slashAmount * unbondAmount) / totalBonded;
        uint256 expectedRemainingTotal = totalBonded - slashAmount;

        assertEq(record.amount, expectedRemainingTotal);
        // Ceil rounding may reduce unbondingAmount by up to 1 more than floor division
        assertApproxEqAbs(record.unbondingAmount, unbondAmount - expectedSlashFromUnbondingFloor, 1);
        assertEq(sup.balanceOf(treasury), slashAmount);

        // Invariant: unbondingAmount <= amount
        assertLe(record.unbondingAmount, record.amount);
    }

    /*//////////////////////////////////////////////////////////////
                GOVERNANCE INTEGRATION: BOND → VALIDATOR CONFIG
    //////////////////////////////////////////////////////////////*/

    /// @notice Helper: grant a role on the real SuperGovernor using vm.store
    /// @dev OZ 5.x (non-upgradeable) AccessControl stores _roles mapping at slot 0.
    ///      Layout: _roles[role].hasRole[account] where _roles is at slot 0.
    ///      roleSlot = keccak256(abi.encode(role, 0))
    ///      hasRoleSlot = keccak256(abi.encode(account, roleSlot))
    ///      If OZ upgrades change the storage layout, hasRole will return false below and this test will fail,
    ///      making the hardcoded slot self-verifying.
    function _grantRoleOnGovernor(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR, hasRoleSlot, bytes32(uint256(1)));
        // Verify the vm.store actually worked (guards against OZ storage layout changes)
        assertTrue(
            ISuperGovernor(SUPER_GOVERNOR).hasRole(role, account),
            "vm.store role grant failed - OZ storage layout may have changed"
        );
    }

    function test_fork_bondThenAddToValidatorConfig() public {
        ISuperGovernor superGovernor = ISuperGovernor(SUPER_GOVERNOR);

        // Step 1: Operator bonds sUP
        uint256 supShares = _depositUpForSup(operator1, 2_000_000e18);
        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares);
        bonding.bond(supShares, operator1, delegateKey1);
        vm.stopPrank();

        assertTrue(bonding.isBonded(operator1));

        // Step 2: Grant GOVERNOR_ROLE on real SuperGovernor to our test governor
        bytes32 govRole = superGovernor.GOVERNOR_ROLE();
        _grantRoleOnGovernor(govRole, governor);

        // Step 3: Governor adds bonded operator to validator config
        address[] memory validators = new address[](1);
        validators[0] = operator1;

        bytes[] memory pubKeys = new bytes[](1);
        pubKeys[0] = abi.encodePacked(delegateKey1); // simplified public key

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, pubKeys, 1, "");

        // Step 4: Cross-reference — bonded in ValidatorBonding AND registered in SuperGovernor
        assertTrue(bonding.isBonded(operator1), "operator should be bonded");
        assertTrue(superGovernor.isValidator(operator1), "operator should be in validator set");

        // Verify validator config
        (uint256 version, address[] memory configValidators,,) = superGovernor.getValidatorConfig();
        assertEq(version, 1);
        assertEq(configValidators.length, 1);
        assertEq(configValidators[0], operator1);
    }

    function test_fork_slashAndRemoveFromValidatorConfig() public {
        ISuperGovernor superGovernor = ISuperGovernor(SUPER_GOVERNOR);

        // Setup: Bond two operators
        uint256 supShares1 = _depositUpForSup(operator1, 2_000_000e18);
        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares1);
        bonding.bond(supShares1, operator1, delegateKey1);
        vm.stopPrank();

        uint256 supShares2 = _depositUpForSup(operator2, 2_000_000e18);
        vm.startPrank(operator2);
        sup.approve(address(bonding), supShares2);
        bonding.bond(supShares2, operator2, delegateKey2);
        vm.stopPrank();

        // Grant GOVERNOR_ROLE
        bytes32 govRole = superGovernor.GOVERNOR_ROLE();
        _grantRoleOnGovernor(govRole, governor);

        // Add both to validator config
        address[] memory validators = new address[](2);
        validators[0] = operator1;
        validators[1] = operator2;

        bytes[] memory pubKeys = new bytes[](2);
        pubKeys[0] = abi.encodePacked(delegateKey1);
        pubKeys[1] = abi.encodePacked(delegateKey2);

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, pubKeys, 2, "");

        assertEq(superGovernor.getValidatorsCount(), 2);

        // Slash operator1 (100%) — this removes from bonding registry
        vm.prank(governor);
        bonding.slash(operator1, supShares1, treasury);

        assertFalse(bonding.isBonded(operator1));
        assertEq(bonding.getOperatorCount(), 1); // only operator2 bonded

        // Atomically remove slashed operator from validator config
        // In production this would be a Safe multicall; here we do it sequentially
        address[] memory remainingValidators = new address[](1);
        remainingValidators[0] = operator2;

        bytes[] memory remainingPubKeys = new bytes[](1);
        remainingPubKeys[0] = abi.encodePacked(delegateKey2);

        vm.prank(governor);
        superGovernor.setValidatorConfig(2, remainingValidators, remainingPubKeys, 1, "");

        // Verify final state
        assertFalse(superGovernor.isValidator(operator1), "slashed operator should be removed");
        assertTrue(superGovernor.isValidator(operator2), "remaining operator should stay");
        assertEq(superGovernor.getValidatorsCount(), 1);

        // Treasury received slashed sUP
        assertEq(sup.balanceOf(treasury), supShares1);
    }

    function test_fork_crossReferenceBondedAndValidatorSets() public {
        ISuperGovernor superGovernor = ISuperGovernor(SUPER_GOVERNOR);

        // Bond operator1 and operator2
        uint256 supShares1 = _depositUpForSup(operator1, 2_000_000e18);
        vm.startPrank(operator1);
        sup.approve(address(bonding), supShares1);
        bonding.bond(supShares1, operator1, delegateKey1);
        vm.stopPrank();

        uint256 supShares2 = _depositUpForSup(operator2, 2_000_000e18);
        vm.startPrank(operator2);
        sup.approve(address(bonding), supShares2);
        bonding.bond(supShares2, operator2, delegateKey2);
        vm.stopPrank();

        // Grant GOVERNOR_ROLE and set validator config
        bytes32 govRole = superGovernor.GOVERNOR_ROLE();
        _grantRoleOnGovernor(govRole, governor);

        address[] memory validators = new address[](2);
        validators[0] = operator1;
        validators[1] = operator2;

        bytes[] memory pubKeys = new bytes[](2);
        pubKeys[0] = abi.encodePacked(delegateKey1);
        pubKeys[1] = abi.encodePacked(delegateKey2);

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, pubKeys, 2, "");

        // Cross-reference: every validator in SuperGovernor should be bonded
        address[] memory bondedOperators = bonding.getOperators();
        address[] memory configValidators = superGovernor.getValidators();

        assertEq(bondedOperators.length, configValidators.length, "sets should have same size");

        for (uint256 i; i < configValidators.length; i++) {
            assertTrue(
                bonding.isBonded(configValidators[i]),
                string.concat("validator should be bonded: ", vm.toString(configValidators[i]))
            );
        }

        // Operator1 unbonds → off-chain tooling would detect the mismatch
        vm.prank(operator1);
        bonding.requestUnbond(operator1, supShares1);

        vm.warp(block.timestamp + UNBONDING_PERIOD);

        vm.prank(operator1);
        bonding.executeUnbond(operator1);

        // Now bonded set (1 operator) != validator config set (2 validators)
        assertEq(bonding.getOperatorCount(), 1);
        assertEq(superGovernor.getValidatorsCount(), 2);

        // Off-chain detection: operator1 is in validator config but NOT bonded
        assertFalse(bonding.isBonded(operator1), "operator1 unbonded");
        assertTrue(superGovernor.isValidator(operator1), "operator1 still in validator config");

        // Governance would then update the config to remove unbonded operator
        address[] memory updatedValidators = new address[](1);
        updatedValidators[0] = operator2;

        bytes[] memory updatedPubKeys = new bytes[](1);
        updatedPubKeys[0] = abi.encodePacked(delegateKey2);

        vm.prank(governor);
        superGovernor.setValidatorConfig(2, updatedValidators, updatedPubKeys, 1, "");

        // Now both sets are in sync again
        assertEq(bonding.getOperatorCount(), 1);
        assertEq(superGovernor.getValidatorsCount(), 1);
        assertTrue(bonding.isBonded(operator2));
        assertTrue(superGovernor.isValidator(operator2));
    }
}
