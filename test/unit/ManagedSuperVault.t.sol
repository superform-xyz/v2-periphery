// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { IManagedSuperVault } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVault.sol";
import { IManagedSuperVaultController } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import {
    IERC7540Deposit,
    IERC7540Redeem,
    IERC7540Operator,
    IERC7540CancelDeposit,
    IERC7540CancelRedeem
} from "../../src/vendor/standards/ERC7540/IERC7540Vault.sol";

contract ManagedSuperVaultTest is ManagedSuperVaultTestBase {
    /*//////////////////////////////////////////////////////////////
                    SYNCHRONOUS PATHS UNAVAILABLE
    //////////////////////////////////////////////////////////////*/

    function test_syncDepositAndMint_revert() public {
        vm.startPrank(user);
        vm.expectRevert(IManagedSuperVault.NOT_IMPLEMENTED.selector);
        vault.deposit(1e18, user);

        vm.expectRevert(IManagedSuperVault.NOT_IMPLEMENTED.selector);
        vault.mint(1e18, user);
        vm.stopPrank();
    }

    function test_previews_revert() public {
        vm.expectRevert(IManagedSuperVault.NOT_IMPLEMENTED.selector);
        vault.previewDeposit(1e18);
        vm.expectRevert(IManagedSuperVault.NOT_IMPLEMENTED.selector);
        vault.previewMint(1e18);
        vm.expectRevert(IManagedSuperVault.NOT_IMPLEMENTED.selector);
        vault.previewWithdraw(1e18);
        vm.expectRevert(IManagedSuperVault.NOT_IMPLEMENTED.selector);
        vault.previewRedeem(1e18);
    }

    function test_supportsInterface() public view {
        assertTrue(vault.supportsInterface(type(IERC7540Deposit).interfaceId));
        assertTrue(vault.supportsInterface(type(IERC7540Redeem).interfaceId));
        assertTrue(vault.supportsInterface(type(IERC7540Operator).interfaceId));
        assertTrue(vault.supportsInterface(type(IERC7540CancelDeposit).interfaceId));
        assertTrue(vault.supportsInterface(type(IERC7540CancelRedeem).interfaceId));
    }

    /*//////////////////////////////////////////////////////////////
                        ASYNC DEPOSIT FLOW
    //////////////////////////////////////////////////////////////*/

    function test_requestDeposit_movesAssetsToEscrow() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        uint256 requestId = vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        assertEq(requestId, 0);
        assertEq(asset.balanceOf(address(escrow)), 100e18);
        assertEq(vault.pendingDepositRequest(0, user), 100e18);
        assertEq(controller.totalPendingDepositAssets(), 100e18);
        assertEq(vault.claimableDepositRequest(0, user), 0);
        assertEq(vault.balanceOf(user), 0);
    }

    function test_requestDeposit_controllerMustEqualOwner() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vm.expectRevert(IManagedSuperVault.CONTROLLER_MUST_EQUAL_OWNER.selector);
        vault.requestDeposit(100e18, user2, user);
        vm.stopPrank();
    }

    function test_requestDeposit_revertsWhenNAVExpired() public {
        vm.warp(block.timestamp + MAX_STALENESS + 1);

        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vm.expectRevert(IManagedSuperVaultController.NAV_EXPIRED.selector);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();
    }

    function test_requestDeposit_revertsWhenPaused() public {
        vm.prank(manager);
        aggregator.pauseManagedVault(address(controller));

        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vm.expectRevert(IManagedSuperVaultController.MANAGED_VAULT_PAUSED.selector);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();
    }

    function test_cancelDepositRequest_instantRefund() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vault.requestDeposit(100e18, user, user);

        uint256 balanceBefore = asset.balanceOf(user);
        vault.cancelDepositRequest(0, user);
        vm.stopPrank();

        assertEq(asset.balanceOf(user), balanceBefore + 100e18);
        assertEq(vault.pendingDepositRequest(0, user), 0);
        assertEq(controller.totalPendingDepositAssets(), 0);
        assertEq(asset.balanceOf(address(escrow)), 0);

        // Nothing pending to cancel anymore
        vm.expectRevert(IManagedSuperVaultController.REQUEST_NOT_FOUND.selector);
        vm.prank(user);
        vault.cancelDepositRequest(0, user);
    }

    function test_fulfillAndClaimDeposit_viaDeposit() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        controller.fulfillDepositRequests(depositors);

        // Assets moved from escrow into controller operational custody
        assertEq(asset.balanceOf(address(escrow)), 0);
        assertEq(asset.balanceOf(address(controller)), 100e18);

        // Claimable at PPS 1.0
        assertEq(vault.claimableDepositRequest(0, user), 100e18);
        assertEq(vault.maxDeposit(user), 100e18);
        assertEq(vault.maxMint(user), 100e18);

        vm.prank(user);
        uint256 shares = vault.deposit(100e18, user, user);
        assertEq(shares, 100e18);
        assertEq(vault.balanceOf(user), 100e18);
        assertEq(vault.claimableDepositRequest(0, user), 0);
        assertEq(vault.totalAssets(), 100e18);
    }

    function test_fulfillAndClaimDeposit_viaMint() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        controller.fulfillDepositRequests(depositors);

        vm.prank(user);
        uint256 assets = vault.mint(40e18, user, user);
        assertEq(assets, 40e18);
        assertEq(vault.balanceOf(user), 40e18);
        assertEq(vault.claimableDepositRequest(0, user), 60e18);
    }

    function test_claimDeposit_cannotExceedClaimable() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        controller.fulfillDepositRequests(depositors);

        vm.expectRevert(IManagedSuperVault.INVALID_AMOUNT.selector);
        vm.prank(user);
        vault.deposit(101e18, user, user);
    }

    function test_depositFulfillment_usesCurrentNAV() public {
        // First round trip establishes supply at PPS 1.0
        _depositRoundTrip(user, 100e18);

        // NAV moves to 1.25
        _updateNAV(1.25e18);

        vm.startPrank(user2);
        asset.approve(address(vault), 100e18);
        vault.requestDeposit(100e18, user2, user2);
        vm.stopPrank();

        address[] memory depositors = new address[](1);
        depositors[0] = user2;
        vm.prank(manager);
        controller.fulfillDepositRequests(depositors);

        assertEq(controller.getAverageDepositPrice(user2), 1.25e18);

        vm.prank(user2);
        uint256 shares = vault.deposit(100e18, user2, user2);
        assertEq(shares, 80e18); // 100 / 1.25
    }

    /*//////////////////////////////////////////////////////////////
                        ASYNC REDEEM FLOW
    //////////////////////////////////////////////////////////////*/

    function test_redeemRoundTrip() public {
        uint256 shares = _depositRoundTrip(user, 100e18);

        uint256 balanceBefore = asset.balanceOf(user);
        _redeemRoundTrip(user, shares);

        assertEq(asset.balanceOf(user), balanceBefore + 100e18);
        assertEq(vault.balanceOf(user), 0);
        assertEq(vault.totalSupply(), 0);
    }

    function test_redeemRequest_sharesLockedInEscrow() public {
        uint256 shares = _depositRoundTrip(user, 100e18);

        vm.prank(user);
        vault.requestRedeem(shares, user, user);

        assertEq(vault.balanceOf(user), 0);
        assertEq(vault.balanceOf(address(escrow)), shares);
        assertEq(vault.pendingRedeemRequest(0, user), shares);
    }

    function test_cancelRedeemRoundTrip() public {
        uint256 shares = _depositRoundTrip(user, 100e18);

        vm.startPrank(user);
        vault.requestRedeem(shares, user, user);
        vault.cancelRedeemRequest(0, user);
        vm.stopPrank();

        assertTrue(vault.pendingCancelRedeemRequest(0, user));

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        vm.prank(manager);
        controller.fulfillCancelRedeemRequests(controllers);

        assertEq(vault.claimableCancelRedeemRequest(0, user), shares);

        vm.prank(user);
        uint256 returned = vault.claimCancelRedeemRequest(0, user, user);
        assertEq(returned, shares);
        assertEq(vault.balanceOf(user), shares);
    }

    function test_redemptionClaims_cannotConsumePendingDeposits() public {
        uint256 shares = _depositRoundTrip(user, 100e18);

        // user2 places a pending deposit request that sits in escrow custody
        vm.startPrank(user2);
        asset.approve(address(vault), 50e18);
        vault.requestDeposit(50e18, user2, user2);
        vm.stopPrank();

        // user redeems everything
        _redeemRoundTrip(user, shares);

        // Pending deposit custody is intact
        assertEq(asset.balanceOf(address(escrow)), 50e18);
        assertEq(vault.pendingDepositRequest(0, user2), 50e18);
    }

    /*//////////////////////////////////////////////////////////////
                        OPERATOR MODEL
    //////////////////////////////////////////////////////////////*/

    function test_operatorCanActForController() public {
        address operator = makeAddr("managedOperator");

        vm.prank(user);
        vault.setOperator(operator, true);

        vm.prank(user);
        asset.approve(address(vault), 100e18);

        // Operator places the deposit request on behalf of user
        vm.prank(operator);
        vault.requestDeposit(100e18, user, user);

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        controller.fulfillDepositRequests(depositors);

        // Operator must set receiver == controller
        vm.expectRevert(IManagedSuperVault.RECEIVER_MUST_EQUAL_CONTROLLER.selector);
        vm.prank(operator);
        vault.deposit(100e18, operator, user);

        vm.prank(operator);
        vault.deposit(100e18, user, user);
        assertEq(vault.balanceOf(user), 100e18);
    }

    function test_nonOperatorCannotActForController() public {
        vm.prank(user);
        asset.approve(address(vault), 100e18);

        vm.expectRevert(IManagedSuperVault.INVALID_CONTROLLER.selector);
        vm.prank(user2);
        vault.requestDeposit(100e18, user, user);
    }
}
