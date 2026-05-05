// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { SuperVaultBatchOperator } from "../../src/SuperVault/SuperVaultBatchOperator.sol";
import { ISuperVaultBatchOperator } from "../../src/interfaces/SuperVault/ISuperVaultBatchOperator.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";

import "forge-std/console2.sol";

/// @title SuperVaultBatchOperatorTest
/// @notice Unit tests for SuperVaultBatchOperator contract
contract SuperVaultBatchOperatorTest is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    SuperVaultBatchOperator internal batchOperator;
    MockERC20 internal asset;

    // Roles & Addresses
    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal user;
    address internal manager;
    address internal admin;
    address internal operator;
    address internal superBank;
    address internal superOracle;
    address internal upToken;

    function setUp() public {
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        user = _deployAccount(0x4, "User");
        manager = _deployAccount(0x5, "Manager");
        admin = _deployAccount(0x6, "Admin");
        operator = _deployAccount(0x7, "Operator");
        superOracle = address(new MockSuperOracle(1e18));

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, governor, governor, treasury, false);

        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        upToken = address(new MockUp(address(this)));
        superBank = makeAddr("superBank");
        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.UPKEEP_TOKEN(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(superVaultAggregator));
        vm.stopPrank();

        vm.prank(manager);
        (address vaultAddress, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault",
                symbol: "TV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager
                })
            })
        );

        vault = SuperVault(vaultAddress);
        strategy = SuperVaultStrategy(payable(strategyAddress));

        // Deploy batch operator
        batchOperator = new SuperVaultBatchOperator(admin, operator);
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_SetsRolesCorrectly() public view {
        assertTrue(batchOperator.hasRole(batchOperator.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(batchOperator.hasRole(batchOperator.OPERATOR_ROLE(), operator));
    }

    function test_Constructor_RevertsOnZeroAdminAddress() public {
        vm.expectRevert(ISuperVaultBatchOperator.ZERO_ADMIN_ADDRESS.selector);
        new SuperVaultBatchOperator(address(0), operator);
    }

    function test_Constructor_RevertsOnZeroOperatorAddress() public {
        vm.expectRevert(ISuperVaultBatchOperator.ZERO_OPERATOR_ADDRESS.selector);
        new SuperVaultBatchOperator(admin, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        BATCH WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchWithdraw_RevertsOnEmptyRequests() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](0);

        vm.prank(operator);
        vm.expectRevert(ISuperVaultBatchOperator.EMPTY_REQUESTS.selector);
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_RevertsOnAccessControl() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });

        vm.prank(user); // not operator
        vm.expectRevert();
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_SkipsZeroVaultAddress() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(0), controller: user, amount: 100e18 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.WithdrawRequestSkipped(0, address(0), user, 100e18);
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_SkipsZeroControllerAddress() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] =
            ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: address(0), amount: 100e18 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.WithdrawRequestSkipped(0, address(vault), address(0), 100e18);
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_SkipsZeroAmount() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 0 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.WithdrawRequestSkipped(0, address(vault), user, 0);
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_EmitsWithdrawFailedOnRevert() public {
        // Withdraw will fail because user has no claimable assets
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.WithdrawFailed(0, address(vault), user, 100e18);
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_EmitsBatchWithdrawExecuted() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });

        vm.prank(operator);
        // Withdraw will fail (no assets), so successCount = 0
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultBatchOperator.BatchWithdrawExecuted(operator, 0);
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_MultipleRequestsMixed() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](3);
        // Invalid request (zero vault)
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(0), controller: user, amount: 100e18 });
        // Valid but will fail (no assets)
        requests[1] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });
        // Invalid request (zero amount)
        requests[2] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 0 });

        vm.prank(operator);
        batchOperator.batchWithdraw(requests);
    }

    /*//////////////////////////////////////////////////////////////
                        BATCH REDEEM TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchRedeem_RevertsOnEmptyRequests() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](0);

        vm.prank(operator);
        vm.expectRevert(ISuperVaultBatchOperator.EMPTY_REQUESTS.selector);
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_RevertsOnAccessControl() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });

        vm.prank(user); // not operator
        vm.expectRevert();
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_SkipsZeroVaultAddress() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(0), controller: user, amount: 100e18 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.RedeemRequestSkipped(0, address(0), user, 100e18);
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_SkipsZeroControllerAddress() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] =
            ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: address(0), amount: 100e18 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.RedeemRequestSkipped(0, address(vault), address(0), 100e18);
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_SkipsZeroAmount() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 0 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.RedeemRequestSkipped(0, address(vault), user, 0);
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_EmitsRedeemFailedOnRevert() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });

        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultBatchOperator.RedeemFailed(0, address(vault), user, 100e18);
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_EmitsBatchRedeemExecuted() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });

        vm.prank(operator);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultBatchOperator.BatchRedeemExecuted(operator, 0);
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_MultipleRequestsMixed() public {
        ISuperVaultBatchOperator.BatchRequest[] memory requests = new ISuperVaultBatchOperator.BatchRequest[](3);
        requests[0] = ISuperVaultBatchOperator.BatchRequest({ vault: address(0), controller: user, amount: 100e18 });
        requests[1] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 100e18 });
        requests[2] = ISuperVaultBatchOperator.BatchRequest({ vault: address(vault), controller: user, amount: 0 });

        vm.prank(operator);
        batchOperator.batchRedeem(requests);
    }

    /*//////////////////////////////////////////////////////////////
                    BATCH EMERGENCY WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchEmergencyWithdraw_TransfersTokens() public {
        // Send some tokens to the batch operator
        deal(address(asset), address(batchOperator), 1000e18);

        address[] memory tokens = new address[](1);
        tokens[0] = address(asset);

        vm.prank(admin);
        batchOperator.batchEmergencyWithdraw(tokens, treasury);

        assertEq(asset.balanceOf(treasury), 1000e18);
        assertEq(asset.balanceOf(address(batchOperator)), 0);
    }

    function test_BatchEmergencyWithdraw_MultipleTokens() public {
        MockERC20 asset2 = new MockERC20("Asset2", "ASSET2", 18);
        deal(address(asset), address(batchOperator), 500e18);
        deal(address(asset2), address(batchOperator), 200e18);

        address[] memory tokens = new address[](2);
        tokens[0] = address(asset);
        tokens[1] = address(asset2);

        vm.prank(admin);
        batchOperator.batchEmergencyWithdraw(tokens, treasury);

        assertEq(asset.balanceOf(treasury), 500e18);
        assertEq(asset2.balanceOf(treasury), 200e18);
    }

    function test_BatchEmergencyWithdraw_ZeroBalance() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(asset);

        vm.prank(admin);
        // Should not revert even with zero balance
        batchOperator.batchEmergencyWithdraw(tokens, treasury);

        assertEq(asset.balanceOf(treasury), 0);
    }

    function test_BatchEmergencyWithdraw_RevertsOnZeroToAddress() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(asset);

        vm.prank(admin);
        vm.expectRevert(ISuperVaultBatchOperator.ZERO_TO_ADDRESS.selector);
        batchOperator.batchEmergencyWithdraw(tokens, address(0));
    }

    function test_BatchEmergencyWithdraw_RevertsOnZeroTokenAddress() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        vm.prank(admin);
        vm.expectRevert(ISuperVaultBatchOperator.ZERO_TOKEN_ADDRESS.selector);
        batchOperator.batchEmergencyWithdraw(tokens, treasury);
    }

    function test_BatchEmergencyWithdraw_RevertsOnAccessControl() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(asset);

        vm.prank(operator); // not admin
        vm.expectRevert();
        batchOperator.batchEmergencyWithdraw(tokens, treasury);
    }

    function test_BatchEmergencyWithdraw_EmitsEvent() public {
        deal(address(asset), address(batchOperator), 100e18);

        address[] memory tokens = new address[](1);
        tokens[0] = address(asset);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100e18;

        vm.prank(admin);
        vm.expectEmit(false, true, false, true);
        emit ISuperVaultBatchOperator.BatchEmergencyWithdraw(tokens, treasury, amounts);
        batchOperator.batchEmergencyWithdraw(tokens, treasury);
    }

    /*//////////////////////////////////////////////////////////////
                        ROLE MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RoleManagement_AdminCanGrantRole() public {
        address newOperator = makeAddr("newOperator");
        bytes32 operatorRole = batchOperator.OPERATOR_ROLE();

        vm.prank(admin);
        batchOperator.grantRole(operatorRole, newOperator);

        assertTrue(batchOperator.hasRole(operatorRole, newOperator));
    }

    function test_RoleManagement_AdminCanRevokeRole() public {
        bytes32 operatorRole = batchOperator.OPERATOR_ROLE();

        vm.prank(admin);
        batchOperator.revokeRole(operatorRole, operator);

        assertFalse(batchOperator.hasRole(operatorRole, operator));
    }

    function test_OperatorRoleConstant() public view {
        assertEq(batchOperator.OPERATOR_ROLE(), keccak256("OPERATOR_ROLE"));
    }
}
