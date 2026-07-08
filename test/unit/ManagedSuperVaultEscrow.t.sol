// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { IManagedSuperVaultEscrow } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultEscrow.sol";

/// @notice Access-control for the escrow: only the vault/controller may move funds, and the release
///         (fulfillment) path is controller-only.
contract ManagedSuperVaultEscrowTest is ManagedSuperVaultTestBase {
    address internal outsider;

    function setUp() public override {
        super.setUp();
        outsider = makeAddr("outsider");
    }

    function test_shareFunctions_vaultOnly() public {
        vm.startPrank(outsider);
        vm.expectRevert(IManagedSuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.escrowShares(user, 1);
        vm.expectRevert(IManagedSuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.returnShares(user, 1);
        vm.expectRevert(IManagedSuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.returnAssets(user, 1);
        vm.stopPrank();

        // The controller is not the vault -> also rejected on share/asset-return paths
        vm.prank(address(controller));
        vm.expectRevert(IManagedSuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.escrowShares(user, 1);
    }

    function test_refundDepositAssets_vaultOrControllerOnly() public {
        vm.prank(outsider);
        vm.expectRevert(IManagedSuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.refundDepositAssets(user, 1);
    }

    function test_releaseDepositAssets_controllerOnly() public {
        // Outsider rejected
        vm.prank(outsider);
        vm.expectRevert(IManagedSuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.releaseDepositAssets(user, 1);

        // Even the vault cannot call release (it is the controller's fulfillment path)
        vm.prank(address(vault));
        vm.expectRevert(IManagedSuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.releaseDepositAssets(user, 1);
    }

    function test_initialize_once() public {
        vm.expectRevert(IManagedSuperVaultEscrow.ALREADY_INITIALIZED.selector);
        escrow.initialize(address(vault), address(controller));
    }
}
