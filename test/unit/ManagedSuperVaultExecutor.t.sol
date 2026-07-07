// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVaultExecutor } from "../../src/ManagedSuperVault/ManagedSuperVaultExecutor.sol";
import { IManagedSuperVaultExecutor } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultExecutor.sol";
import { IManagedSuperVaultController } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";

contract ManagedSuperVaultExecutorTest is ManagedSuperVaultTestBase {
    ManagedSuperVaultExecutor internal executor;
    address internal sessionKey;
    address internal custodian;
    address internal entryPoint;

    function setUp() public override {
        super.setUp();

        sessionKey = makeAddr("sessionKey");
        custodian = makeAddr("custodian");
        entryPoint = makeAddr("entryPoint");

        executor = new ManagedSuperVaultExecutor(address(superGovernor), sGovernor, entryPoint);

        // Executor operates as a secondary manager on the controller
        vm.prank(manager);
        aggregator.addSecondaryManager(address(controller), address(executor));
    }

    function _grant(IManagedSuperVaultExecutor.Permission permission) internal {
        IManagedSuperVaultExecutor.Permission[] memory permissions = new IManagedSuperVaultExecutor.Permission[](1);
        permissions[0] = permission;
        vm.prank(manager);
        executor.grantSessionKey(address(controller), sessionKey, block.timestamp + 1 days, permissions);
    }

    function test_grantSessionKey_primaryManagerOnly() public {
        IManagedSuperVaultExecutor.Permission[] memory permissions = new IManagedSuperVaultExecutor.Permission[](1);
        permissions[0] = IManagedSuperVaultExecutor.Permission.ExecuteCalls;

        vm.expectRevert(IManagedSuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        vm.prank(secondaryManager);
        executor.grantSessionKey(address(controller), sessionKey, block.timestamp + 1 days, permissions);

        vm.prank(manager);
        executor.grantSessionKey(address(controller), sessionKey, block.timestamp + 1 days, permissions);
        assertTrue(executor.isSessionKeyValid(address(controller), sessionKey));
    }

    function test_sessionKey_executesManagedCall() public {
        _depositRoundTrip(user, 100e18);
        _grant(IManagedSuperVaultExecutor.Permission.ExecuteCalls);

        // Configure the execution policy
        IManagedSuperVaultController.CallRule memory rule;
        rule.allowed = true;
        rule.constrainedArgs = new uint8[](1);
        vm.startPrank(manager);
        controller.setCallRule(address(asset), asset.transfer.selector, rule);
        address[] memory allowedValues = new address[](1);
        allowedValues[0] = custodian;
        controller.setArgAllowedValues(address(asset), asset.transfer.selector, 0, allowedValues, true);
        vm.stopPrank();

        IManagedSuperVaultController.ManagedCall memory call_ = IManagedSuperVaultController.ManagedCall({
            target: address(asset), value: 0, data: abi.encodeCall(asset.transfer, (custodian, 5e18))
        });

        vm.prank(sessionKey);
        executor.executeManagedCall(address(controller), call_, keccak256("sk-op-1"));
        assertEq(asset.balanceOf(custodian), 5e18);
    }

    function test_sessionKey_permissionScoping() public {
        _grant(IManagedSuperVaultExecutor.Permission.ProposeNAV);

        // Missing ExecuteCalls permission
        IManagedSuperVaultController.ManagedCall memory call_ =
            IManagedSuperVaultController.ManagedCall({ target: custodian, value: 0, data: "" });
        vm.expectRevert(IManagedSuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        vm.prank(sessionKey);
        executor.executeManagedCall(address(controller), call_, keccak256("sk-op-1"));

        // Granted permission works
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(sessionKey);
        uint256 proposalId = executor.proposeNAVUpdate(address(controller), 1.01e18, block.timestamp, EVIDENCE_HASH, "");

        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(controller), proposalId);
        assertEq(controller.getStoredPPS(), 1.01e18);
    }

    function test_sessionKey_expiryAndRevocation() public {
        _grant(IManagedSuperVaultExecutor.Permission.Pause);

        vm.warp(block.timestamp + 1 days + 1);
        vm.expectRevert(IManagedSuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        vm.prank(sessionKey);
        executor.pauseManagedVault(address(controller));

        _grant(IManagedSuperVaultExecutor.Permission.Pause);
        vm.prank(manager);
        executor.revokeSessionKey(address(controller), sessionKey);

        vm.expectRevert(IManagedSuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        vm.prank(sessionKey);
        executor.pauseManagedVault(address(controller));
    }

    function test_sessionKey_generationInvalidation() public {
        _grant(IManagedSuperVaultExecutor.Permission.Pause);

        vm.prank(manager);
        executor.invalidateAllSessionKeys(address(controller));

        vm.expectRevert(IManagedSuperVaultExecutor.SESSION_KEY_GENERATION_MISMATCH.selector);
        vm.prank(sessionKey);
        executor.pauseManagedVault(address(controller));
    }

    function test_sessionKey_diesWithGrantingManager() public {
        _grant(IManagedSuperVaultExecutor.Permission.Pause);

        // Governance replaces the primary manager
        vm.prank(address(superGovernor));
        aggregator.changePrimaryManager(address(controller), makeAddr("newManager"), feeRecipient);

        // Re-add the executor as secondary manager is not even needed to hit the check:
        vm.expectRevert(IManagedSuperVaultExecutor.PRIMARY_MANAGER_CHANGED.selector);
        vm.prank(sessionKey);
        executor.pauseManagedVault(address(controller));
    }

    function test_sessionKey_pauseUnpause() public {
        IManagedSuperVaultExecutor.Permission[] memory permissions = new IManagedSuperVaultExecutor.Permission[](2);
        permissions[0] = IManagedSuperVaultExecutor.Permission.Pause;
        permissions[1] = IManagedSuperVaultExecutor.Permission.Unpause;
        vm.prank(manager);
        executor.grantSessionKey(address(controller), sessionKey, block.timestamp + 1 days, permissions);

        vm.startPrank(sessionKey);
        executor.pauseManagedVault(address(controller));
        assertTrue(aggregator.isManagedVaultPaused(address(controller)));

        executor.unpauseManagedVault(address(controller));
        assertFalse(aggregator.isManagedVaultPaused(address(controller)));
        vm.stopPrank();
    }

    function test_fulfillDeposits_viaSessionKey() public {
        vm.startPrank(user);
        asset.approve(address(vault), 100e18);
        vault.requestDeposit(100e18, user, user);
        vm.stopPrank();

        _grant(IManagedSuperVaultExecutor.Permission.FulfillDeposits);

        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(sessionKey);
        executor.fulfillDepositRequests(address(controller), depositors);

        assertEq(controller.claimableDepositRequest(user), 100e18);
    }
}
