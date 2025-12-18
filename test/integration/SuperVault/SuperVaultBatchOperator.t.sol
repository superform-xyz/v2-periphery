// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";

// external
import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

// superform
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultBatchOperator } from "../../../src/SuperVault/SuperVaultBatchOperator.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { ISuperBank } from "../../../src/interfaces/ISuperBank.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { SuperVaultAggregator } from "../../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IERC7540Redeem, IERC7540Operator, IERC7741 } from "../../../src/vendor/standards/ERC7540/IERC7540Vault.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { ISuperExecutor } from "@superform-v2-core/src/interfaces/ISuperExecutor.sol";
import { AccountInstance, UserOpData } from "modulekit/ModuleKit.sol";

contract SuperVaultBatchOperatorTest is BaseSuperVaultTest {
    using Math for uint256;

    SuperVaultBatchOperator public batchOperator;

    function setUp() public override {
        super.setUp();

        // Deploy the batch operator
        batchOperator = new SuperVaultBatchOperator();
    }

    /*//////////////////////////////////////////////////////////////
                    BATCH WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchWithdraw_MultipleUsers() public {
        // Setup users with deposits
        address[3] memory users = [accountEth, accInstances[0].account, accInstances[1].account];
        uint256[3] memory depositAmounts = [uint256(1000e6), 500e6, 750e6];
        uint256[3] memory withdrawAmounts = [uint256(200e6), 100e6, 150e6];

        // Deposit for each user
        for (uint256 i = 0; i < 3; i++) {
            _getTokens(address(asset), users[i], depositAmounts[i]);
            vm.prank(users[i]);
            vault.deposit(depositAmounts[i], users[i]);
        }

        // Allocate to yield sources
        uint256 totalDeposited = depositAmounts[0] + depositAmounts[1] + depositAmounts[2];
        _depositFreeAssetsFromSingleAmount(totalDeposited, address(fluidVault), address(aaveVault));

        // Record initial balances
        uint256[3] memory initialBalances;
        for (uint256 i = 0; i < 3; i++) {
            initialBalances[i] = asset.balanceOf(users[i]);
        }

        // Create batch withdrawal requests
        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](3);
        for (uint256 i = 0; i < 3; i++) {
            requests[i] = SuperVaultBatchOperator.BatchRequest({
                vault: address(vault), owner: users[i], assets: withdrawAmounts[i]
            });
        }

        // Execute batch withdrawal
        batchOperator.batchWithdraw(requests);

        // Verify results
        for (uint256 i = 0; i < 3; i++) {
            assertEq(
                asset.balanceOf(users[i]) - initialBalances[i],
                withdrawAmounts[i],
                "User should receive correct withdrawal amount"
            );

            uint256 sharesBefore = vault.balanceOf(users[i]);
            assertTrue(sharesBefore < vault.balanceOf(users[i]) + withdrawAmounts[i], "User shares should decrease");
        }
    }

    function test_BatchWithdraw_EmptyArray() public {
        // Test with empty array
        SuperVaultBatchOperator.BatchRequest[] memory emptyRequests = new SuperVaultBatchOperator.BatchRequest[](0);

        // Should execute without error
        batchOperator.batchWithdraw(emptyRequests);
    }

    function test_BatchWithdraw_InvalidVault() public {
        // Create request with invalid vault address
        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = SuperVaultBatchOperator.BatchRequest({
            vault: address(0), // Invalid vault address
            owner: accountEth,
            assets: 100e6
        });

        // Should revert when trying to withdraw from invalid vault
        vm.expectRevert();
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_InsufficientBalance() public {
        // Setup user with small deposit
        uint256 depositAmount = 100e6; // 100 USDC
        _getTokens(address(asset), accountEth, depositAmount);
        vm.prank(accountEth);
        vault.deposit(depositAmount, accountEth);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Create request for more than user's max withdrawable amount
        uint256 excessiveAmount = depositAmount * 2; // Try to withdraw 2x deposit

        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](1);
        requests[0] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: excessiveAmount });

        // Should revert due to insufficient balance
        vm.expectRevert();
        batchOperator.batchWithdraw(requests);
    }

    function test_BatchWithdraw_ZeroAmount() public {
        // Setup user with deposit
        uint256 depositAmount = 100e6; // 100 USDC
        _getTokens(address(asset), accountEth, depositAmount);
        vm.prank(accountEth);
        vault.deposit(depositAmount, accountEth);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Create request with zero amount
        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: 0 });

        // Should execute without error (zero amount withdrawal should be allowed)
        batchOperator.batchWithdraw(requests);
    }

    /*//////////////////////////////////////////////////////////////
                    BATCH REDEEM TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchRedeem_MultipleUsers() public {
        // Setup users with deposits
        address[3] memory users = [accountEth, accInstances[0].account, accInstances[1].account];
        uint256[3] memory depositAmounts = [uint256(1000e6), 500e6, 750e6];

        // Deposit for each user
        for (uint256 i = 0; i < 3; i++) {
            _getTokens(address(asset), users[i], depositAmounts[i]);
            vm.prank(users[i]);
            vault.deposit(depositAmounts[i], users[i]);
        }

        // Allocate to yield sources
        uint256 totalDeposited = depositAmounts[0] + depositAmounts[1] + depositAmounts[2];
        _depositFreeAssetsFromSingleAmount(totalDeposited, address(fluidVault), address(aaveVault));

        // Create batch redemption requests
        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](3);
        for (uint256 i = 0; i < 3; i++) {
            uint256 shares = vault.balanceOf(users[i]);
            requests[i] = SuperVaultBatchOperator.BatchRequest({
                vault: address(vault),
                owner: users[i],
                assets: shares / (i + 3) // Different redemption amounts: 1/3, 1/4, 1/5
            });
        }

        // Record initial state
        uint256[3] memory initialBalances;
        uint256[3] memory initialShares;
        for (uint256 i = 0; i < 3; i++) {
            initialBalances[i] = asset.balanceOf(users[i]);
            initialShares[i] = vault.balanceOf(users[i]);
        }

        // Execute batch redemption
        batchOperator.batchRedeem(requests);

        // Verify results
        for (uint256 i = 0; i < 3; i++) {
            assertTrue(asset.balanceOf(users[i]) > initialBalances[i], "User should receive assets from redemption");
            assertEq(
                vault.balanceOf(users[i]),
                initialShares[i] - requests[i].assets,
                "User shares should decrease by redeem amount"
            );
        }
    }

    function test_BatchRedeem_EmptyArray() public {
        // Test with empty array
        SuperVaultBatchOperator.BatchRequest[] memory emptyRequests = new SuperVaultBatchOperator.BatchRequest[](0);

        // Should execute without error
        batchOperator.batchRedeem(emptyRequests);
    }

    function test_BatchRedeem_InvalidVault() public {
        // Create request with invalid vault address
        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = SuperVaultBatchOperator.BatchRequest({
            vault: address(0), // Invalid vault address
            owner: accountEth,
            assets: 100e6
        });

        // Should revert when trying to redeem from invalid vault
        vm.expectRevert();
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_InsufficientShares() public {
        // Setup user with small deposit
        uint256 depositAmount = 100e6; // 100 USDC
        _getTokens(address(asset), accountEth, depositAmount);
        vm.prank(accountEth);
        vault.deposit(depositAmount, accountEth);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Create request for more shares than user owns
        uint256 userShares = vault.balanceOf(accountEth);
        uint256 excessiveShares = userShares * 2; // Try to redeem 2x shares

        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](1);
        requests[0] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: excessiveShares });

        // Should revert due to insufficient shares
        vm.expectRevert();
        batchOperator.batchRedeem(requests);
    }

    function test_BatchRedeem_ZeroShares() public {
        // Setup user with deposit
        uint256 depositAmount = 100e6; // 100 USDC
        _getTokens(address(asset), accountEth, depositAmount);
        vm.prank(accountEth);
        vault.deposit(depositAmount, accountEth);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Create request with zero shares
        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](1);
        requests[0] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: 0 });

        // Should execute without error (zero shares redemption should be allowed)
        batchOperator.batchRedeem(requests);
    }

    /*//////////////////////////////////////////////////////////////
                    MIXED OPERATIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MixedBatchOperations() public {
        // Setup multiple users
        uint256 depositAmount = 500e6; // 500 USDC each
        address user1 = accountEth;
        address user2 = accInstances[0].account;

        // Deposit for both users
        _getTokens(address(asset), user1, depositAmount);
        _getTokens(address(asset), user2, depositAmount);

        vm.prank(user1);
        vault.deposit(depositAmount, user1);

        vm.prank(user2);
        vault.deposit(depositAmount, user2);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount * 2, address(fluidVault), address(aaveVault));

        // Record initial state
        uint256 initialBalance1 = asset.balanceOf(user1);
        uint256 initialBalance2 = asset.balanceOf(user2);
        uint256 initialShares1 = vault.balanceOf(user1);
        uint256 initialShares2 = vault.balanceOf(user2);

        // Execute batch withdrawal for user1
        uint256 withdrawAmount = 100e6;
        SuperVaultBatchOperator.BatchRequest[] memory withdrawRequests = new SuperVaultBatchOperator.BatchRequest[](1);
        withdrawRequests[0] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user1, assets: withdrawAmount });

        batchOperator.batchWithdraw(withdrawRequests);

        // Execute batch redemption for user2
        uint256 redeemShares = initialShares2 / 4; // Redeem 25% of shares
        SuperVaultBatchOperator.BatchRequest[] memory redeemRequests = new SuperVaultBatchOperator.BatchRequest[](1);
        redeemRequests[0] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user2, assets: redeemShares });

        batchOperator.batchRedeem(redeemRequests);

        // Verify user1 received withdrawal
        assertEq(asset.balanceOf(user1) - initialBalance1, withdrawAmount, "User1 should receive withdrawal amount");

        // Verify user2 received redemption
        assertTrue(asset.balanceOf(user2) > initialBalance2, "User2 should receive redemption assets");
        assertEq(vault.balanceOf(user2), initialShares2 - redeemShares, "User2 shares should decrease");
    }

    function test_BatchWithdraw_SameUserMultipleRequests() public {
        // Setup user with deposit
        uint256 depositAmount = 1000e6; // 1000 USDC
        _getTokens(address(asset), accountEth, depositAmount);
        vm.prank(accountEth);
        vault.deposit(depositAmount, accountEth);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Record initial balance
        uint256 initialBalance = asset.balanceOf(accountEth);

        // Create multiple requests for the same user
        uint256 withdrawAmount1 = 100e6;
        uint256 withdrawAmount2 = 150e6;
        uint256 withdrawAmount3 = 200e6;

        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](3);
        requests[0] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: withdrawAmount1 });
        requests[1] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: withdrawAmount2 });
        requests[2] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: withdrawAmount3 });

        // Execute batch withdrawal
        batchOperator.batchWithdraw(requests);

        // Verify total withdrawal amount
        uint256 totalWithdrawn = withdrawAmount1 + withdrawAmount2 + withdrawAmount3;
        assertEq(
            asset.balanceOf(accountEth) - initialBalance, totalWithdrawn, "User should receive total withdrawal amount"
        );
    }

    function test_BatchRedeem_SameUserMultipleRequests() public {
        // Setup user with deposit
        uint256 depositAmount = 1000e6; // 1000 USDC
        _getTokens(address(asset), accountEth, depositAmount);
        vm.prank(accountEth);
        vault.deposit(depositAmount, accountEth);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Record initial state
        uint256 initialBalance = asset.balanceOf(accountEth);
        uint256 initialShares = vault.balanceOf(accountEth);

        // Create multiple redemption requests for the same user
        uint256 redeemShares1 = initialShares / 10; // 10% of shares
        uint256 redeemShares2 = initialShares / 15; // ~6.67% of shares
        uint256 redeemShares3 = initialShares / 20; // 5% of shares

        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](3);
        requests[0] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: redeemShares1 });
        requests[1] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: redeemShares2 });
        requests[2] =
            SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: accountEth, assets: redeemShares3 });

        // Execute batch redemption
        batchOperator.batchRedeem(requests);

        // Verify total shares redeemed and assets received
        uint256 totalRedeemedShares = redeemShares1 + redeemShares2 + redeemShares3;
        assertEq(
            vault.balanceOf(accountEth),
            initialShares - totalRedeemedShares,
            "User shares should decrease by total redeemed amount"
        );

        assertTrue(asset.balanceOf(accountEth) > initialBalance, "User should receive assets from redemption");
    }

    /*//////////////////////////////////////////////////////////////
                    GAS OPTIMIZATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GasReport_BatchWithdraw() public {
        // Setup multiple users with deposits
        uint256 depositAmount = 500e6; // 500 USDC each
        address user1 = accountEth;
        address user2 = accInstances[0].account;
        address user3 = accInstances[1].account;

        // Deposit for each user
        _getTokens(address(asset), user1, depositAmount);
        _getTokens(address(asset), user2, depositAmount);
        _getTokens(address(asset), user3, depositAmount);

        vm.prank(user1);
        vault.deposit(depositAmount, user1);

        vm.prank(user2);
        vault.deposit(depositAmount, user2);

        vm.prank(user3);
        vault.deposit(depositAmount, user3);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount * 3, address(fluidVault), address(aaveVault));

        // Create batch withdrawal requests
        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](3);
        requests[0] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user1, assets: 100e6 });
        requests[1] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user2, assets: 100e6 });
        requests[2] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user3, assets: 100e6 });

        // Measure gas consumption
        uint256 gasStart = gasleft();
        batchOperator.batchWithdraw(requests);
        uint256 gasUsed = gasStart - gasleft();

        console2.log("Gas used for batchWithdraw (3 users):", gasUsed);
        console2.log("Gas per withdrawal:", gasUsed / 3);
    }

    function test_GasReport_BatchRedeem() public {
        // Setup multiple users with deposits
        uint256 depositAmount = 500e6; // 500 USDC each
        address user1 = accountEth;
        address user2 = accInstances[0].account;
        address user3 = accInstances[1].account;

        // Deposit for each user
        _getTokens(address(asset), user1, depositAmount);
        _getTokens(address(asset), user2, depositAmount);
        _getTokens(address(asset), user3, depositAmount);

        vm.prank(user1);
        vault.deposit(depositAmount, user1);

        vm.prank(user2);
        vault.deposit(depositAmount, user2);

        vm.prank(user3);
        vault.deposit(depositAmount, user3);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount * 3, address(fluidVault), address(aaveVault));

        // Create batch redemption requests
        uint256 shares1 = vault.balanceOf(user1) / 4;
        uint256 shares2 = vault.balanceOf(user2) / 4;
        uint256 shares3 = vault.balanceOf(user3) / 4;

        SuperVaultBatchOperator.BatchRequest[] memory requests = new SuperVaultBatchOperator.BatchRequest[](3);
        requests[0] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user1, assets: shares1 });
        requests[1] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user2, assets: shares2 });
        requests[2] = SuperVaultBatchOperator.BatchRequest({ vault: address(vault), owner: user3, assets: shares3 });

        // Measure gas consumption
        uint256 gasStart = gasleft();
        batchOperator.batchRedeem(requests);
        uint256 gasUsed = gasStart - gasleft();

        console2.log("Gas used for batchRedeem (3 users):", gasUsed);
        console2.log("Gas per redemption:", gasUsed / 3);
    }
}
