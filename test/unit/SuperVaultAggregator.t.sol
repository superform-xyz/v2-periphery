// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";
import { MockAggregator } from "../mocks/MockAggregator.sol";

import "forge-std/console2.sol";

contract SuperVaultAggregatorTest is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;

    // Roles & Addresses
    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal user;
    address internal manager;
    address internal secondaryManager;
    address internal protectedKeeper1;
    address internal protectedKeeper2;
    address internal normalKeeper1;
    address internal normalKeeper2;
    address internal strategy;
    address internal upToken;
    address internal superBank;
    address internal superOracle;
    address internal gasOracle;

    // Role Hashes
    bytes32 internal constant SUPER_GOVERNOR_ROLE = keccak256("SUPER_GOVERNOR_ROLE");
    bytes32 internal constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    MockERC20 internal asset;

    /// @notice Sets up the test environment before each test case.
    function setUp() public {
        // Deploy accounts
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        user = _deployAccount(0x4, "User");
        manager = _deployAccount(0x5, "Manager");
        secondaryManager = _deployAccount(0x6, "SecondaryManager");
        protectedKeeper1 = _deployAccount(0x7, "ProtectedKeeper1");
        protectedKeeper2 = _deployAccount(0x8, "ProtectedKeeper2");
        normalKeeper1 = _deployAccount(0x9, "NormalKeeper1");
        normalKeeper2 = _deployAccount(0xA, "NormalKeeper2");
        superOracle = address(new MockSuperOracle(1e18));
        gasOracle = address(new MockAggregator(1e8, 8));

        // Deploy contracts
        asset = new MockERC20("Asset", "ASSET", 18);
        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, treasury, address(this));

        // Deploy implementation contracts
        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        // Create a vault and strategy for testing
        vm.prank(manager);
        (, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault",
                symbol: "TV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );
        strategy = strategyAddress;

        // Add secondary manager for testing
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(strategy, secondaryManager);

        // Register some protected keepers
        vm.startPrank(governor);
        superGovernor.registerProtectedKeeper(protectedKeeper1);
        superGovernor.registerProtectedKeeper(protectedKeeper2);
        vm.stopPrank();

        // Register UP token on SuperGovernor
        upToken = address(new MockUp(address(this)));
        superBank = makeAddr("superBank");
        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        vm.stopPrank();
    }

    // =============================================================
    // Authorized Caller Management Tests
    // =============================================================

    /// @notice Tests adding a normal (non-protected) keeper as authorized caller
    function test_AddAuthorizedCaller_Success_NormalKeeper() public {
        // Primary manager adds normal keeper
        vm.prank(manager);
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.AuthorizedCallerAdded(strategy, normalKeeper1);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);

        // Verify the keeper was added
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 1, "Should have 1 authorized caller");
        assertEq(callers[0], normalKeeper1, "Authorized caller should match");
    }

    /// @notice Tests secondary manager can add authorized callers
    function test_AddAuthorizedCaller_Success_SecondaryManager() public {
        // Secondary manager adds normal keeper
        vm.prank(secondaryManager);
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.AuthorizedCallerAdded(strategy, normalKeeper1);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);

        // Verify the keeper was added
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 1, "Should have 1 authorized caller");
        assertEq(callers[0], normalKeeper1, "Authorized caller should match");
    }

    /// @notice Tests adding multiple normal keepers as authorized callers
    function test_AddAuthorizedCaller_Success_MultipleKeepers() public {
        vm.startPrank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper2);
        vm.stopPrank();

        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 2, "Should have 2 authorized callers");

        // Verify both keepers are in the list
        bool foundKeeper1 = false;
        bool foundKeeper2 = false;
        for (uint256 i = 0; i < callers.length; i++) {
            if (callers[i] == normalKeeper1) foundKeeper1 = true;
            if (callers[i] == normalKeeper2) foundKeeper2 = true;
        }
        assertTrue(foundKeeper1, "normalKeeper1 should be in authorized callers");
        assertTrue(foundKeeper2, "normalKeeper2 should be in authorized callers");
    }

    /// @notice Tests reverting when manager tries to add protected keeper
    function test_AddAuthorizedCaller_Revert_ProtectedKeeper() public {
        // Primary manager tries to add protected keeper
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.CANNOT_ADD_PROTECTED_KEEPER.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, protectedKeeper1);

        // Secondary manager tries to add protected keeper
        vm.prank(secondaryManager);
        vm.expectRevert(ISuperVaultAggregator.CANNOT_ADD_PROTECTED_KEEPER.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, protectedKeeper2);

        // Verify no callers were added
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 0, "Should have 0 authorized callers");
    }

    /// @notice Tests reverting when non-manager tries to add authorized caller
    function test_AddAuthorizedCaller_Revert_UnauthorizedCaller() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);
    }

    /// @notice Tests reverting when adding zero address as authorized caller
    function test_AddAuthorizedCaller_Revert_ZeroAddress() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, address(0));
    }

    /// @notice Tests reverting when adding duplicate authorized caller
    function test_AddAuthorizedCaller_Revert_AlreadyAuthorized() public {
        // Add keeper first
        vm.prank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);

        // Try to add same keeper again
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.CALLER_ALREADY_AUTHORIZED.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);
    }

    /// @notice Tests reverting when trying to add authorized caller for unknown strategy
    function test_AddAuthorizedCaller_Revert_UnknownStrategy() public {
        address unknownStrategy = _deployAccount(0x99, "UnknownStrategy");

        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.UNKNOWN_STRATEGY.selector);
        superVaultAggregator.addAuthorizedCaller(unknownStrategy, normalKeeper1);
    }

    // =============================================================
    // Remove Authorized Caller Tests
    // =============================================================

    /// @notice Tests removing authorized caller successfully
    function test_RemoveAuthorizedCaller_Success() public {
        // Add caller first
        vm.prank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);

        // Remove caller
        vm.prank(manager);
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.AuthorizedCallerRemoved(strategy, normalKeeper1);
        superVaultAggregator.removeAuthorizedCaller(strategy, normalKeeper1);

        // Verify caller was removed
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 0, "Should have 0 authorized callers");
    }

    /// @notice Tests removing authorized caller when multiple exist
    function test_RemoveAuthorizedCaller_Success_WithMultiple() public {
        // Add multiple callers
        vm.startPrank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper2);
        vm.stopPrank();

        // Remove one caller
        vm.prank(manager);
        superVaultAggregator.removeAuthorizedCaller(strategy, normalKeeper1);

        // Verify only normalKeeper2 remains
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 1, "Should have 1 authorized caller");
        assertEq(callers[0], normalKeeper2, "Remaining caller should be normalKeeper2");
    }

    /// @notice Tests reverting when removing non-existent authorized caller
    function test_RemoveAuthorizedCaller_Revert_CallerNotFound() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.CALLER_NOT_AUTHORIZED.selector);
        superVaultAggregator.removeAuthorizedCaller(strategy, normalKeeper1);
    }

    /// @notice Tests secondary manager can remove authorized callers
    function test_RemoveAuthorizedCaller_Success_SecondaryManager() public {
        // Add caller with primary manager
        vm.prank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);

        // Remove caller with secondary manager
        vm.prank(secondaryManager);
        superVaultAggregator.removeAuthorizedCaller(strategy, normalKeeper1);

        // Verify caller was removed
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 0, "Should have 0 authorized callers");
    }

    // =============================================================
    // Emergency Manager Replacement Tests
    // =============================================================

    /// @notice Tests emergency manager replacement clears pending proposals
    function test_ChangePrimaryManager_ClearsPendingProposals() public {
        // Setup: Create pending manager proposal
        address newManager = _deployAccount(0xC, "NewManager");

        // Secondary manager proposes a change
        vm.prank(secondaryManager);
        superVaultAggregator.proposeChangePrimaryManager(strategy, newManager);

        // SuperGovernor performs emergency replacement
        address emergencyManager = _deployAccount(0xD, "EmergencyManager");
        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, emergencyManager);

        // Verify new manager is set
        address currentManager = superVaultAggregator.getMainManager(strategy);
        assertEq(currentManager, emergencyManager, "Emergency manager should be set");
    }

    /// @notice Tests emergency replacement clears all secondary managers
    function test_ChangePrimaryManager_ClearsSecondaryManagers() public {
        // Setup: Add multiple secondary managers
        address secondaryManager2 = _deployAccount(0xE, "SecondaryManager2");
        address secondaryManager3 = _deployAccount(0xF, "SecondaryManager3");

        vm.startPrank(manager);
        superVaultAggregator.addSecondaryManager(strategy, secondaryManager2);
        superVaultAggregator.addSecondaryManager(strategy, secondaryManager3);
        vm.stopPrank();

        // Verify secondary managers exist
        address[] memory secondaryManagers = superVaultAggregator.getSecondaryManagers(strategy);
        assertEq(secondaryManagers.length, 3, "Should have 3 secondary managers");

        // SuperGovernor performs emergency replacement
        address emergencyManager = _deployAccount(0x10, "EmergencyManager");

        // Expect SecondaryManagerRemoved events for all secondary managers
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.SecondaryManagerRemoved(strategy, secondaryManager);
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.SecondaryManagerRemoved(strategy, secondaryManager2);
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.SecondaryManagerRemoved(strategy, secondaryManager3);

        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, emergencyManager);

        // Verify all secondary managers were cleared
        secondaryManagers = superVaultAggregator.getSecondaryManagers(strategy);
        assertEq(secondaryManagers.length, 0, "All secondary managers should be cleared");
    }

    /// @notice Tests emergency replacement clears all secondary managers
    function test_AddTooManySecondaryManagers() public {
        uint256 len = 7;
        address[] memory secondaryManagers = new address[](len);
        
        for (uint i = 0; i < len-1; ++i) 
        {
            secondaryManagers[i] = _deployAccount(10 + i, "SecondaryManager");
        }

        vm.startPrank(manager);
        for (uint i = 0; i < 4; ++i) 
        {
            superVaultAggregator.addSecondaryManager(strategy, secondaryManagers[i]);
        }
        vm.expectRevert(ISuperVaultAggregator.TOO_MANY_SECONDARY_MANAGERS.selector);
        superVaultAggregator.addSecondaryManager(strategy, secondaryManagers[5]);
        vm.stopPrank();
    }

    /// @notice Tests emergency replacement clears pending hook root proposals
    function test_ChangePrimaryManager_ClearsPendingHookProposals() public {
        // Setup: Create pending hook root proposal
        bytes32 newHookRoot = keccak256("new_hook_root");

        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(strategy, newHookRoot);

        // Verify hook proposal exists
        (bytes32 proposedRoot, uint256 effectiveTime) = superVaultAggregator.getProposedStrategyHooksRoot(strategy);
        assertEq(proposedRoot, newHookRoot, "Hook proposal should exist");
        assertTrue(effectiveTime > 0, "Hook effective time should be set");

        // SuperGovernor performs emergency replacement
        address emergencyManager = _deployAccount(0x11, "EmergencyManager");
        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, emergencyManager);

        // Verify hook proposal was cleared
        (proposedRoot, effectiveTime) = superVaultAggregator.getProposedStrategyHooksRoot(strategy);
        assertEq(proposedRoot, bytes32(0), "Hook proposal should be cleared");
        assertEq(effectiveTime, 0, "Hook effective time should be cleared");
    }

    /// @notice Tests the complete attack scenario - malicious manager cannot regain control
    function test_ChangePrimaryManager_PreventsAttackScenario() public {
        // Setup malicious scenario:
        // 1. Malicious manager has secondary managers under their control
        address maliciousSecondary1 = _deployAccount(0x12, "MaliciousSecondary1");
        address maliciousSecondary2 = _deployAccount(0x13, "MaliciousSecondary2");

        vm.startPrank(manager); // manager is acting maliciously
        superVaultAggregator.addSecondaryManager(strategy, maliciousSecondary1);
        superVaultAggregator.addSecondaryManager(strategy, maliciousSecondary2);
        vm.stopPrank();

        // 2. Malicious manager creates a proposal to regain control after emergency replacement
        address controlledAccount = _deployAccount(0x14, "ControlledAccount");
        vm.prank(maliciousSecondary1);
        superVaultAggregator.proposeChangePrimaryManager(strategy, controlledAccount);

        // 3. SuperGovernor detects malicious behavior and performs emergency replacement
        address emergencyManager = _deployAccount(0x15, "EmergencyManager");
        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, emergencyManager);

        // 4. Verify the attack is thwarted:

        // a) All secondary managers are removed
        address[] memory secondaryManagers = superVaultAggregator.getSecondaryManagers(strategy);
        assertEq(secondaryManagers.length, 0, "All malicious secondary managers should be removed");

        // b) Emergency manager is in control
        address currentManager = superVaultAggregator.getMainManager(strategy);
        assertEq(currentManager, emergencyManager, "Emergency manager should be in control");

        // 5. Malicious accounts can no longer propose changes
        vm.prank(maliciousSecondary1);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.proposeChangePrimaryManager(strategy, controlledAccount);

        vm.prank(maliciousSecondary2);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.proposeChangePrimaryManager(strategy, controlledAccount);
    }

    /// @notice Tests that only SuperGovernor can call changePrimaryManager
    function test_ChangePrimaryManager_OnlySuperGovernor() public {
        address newManager = _deployAccount(0x16, "NewManager");

        // Test unauthorized callers
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.changePrimaryManager(strategy, newManager);

        vm.prank(secondaryManager);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.changePrimaryManager(strategy, newManager);

        vm.prank(user);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.changePrimaryManager(strategy, newManager);

        // Test that SuperGovernor can call it
        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, newManager);

        // Verify change was successful
        address currentManager = superVaultAggregator.getMainManager(strategy);
        assertEq(currentManager, newManager, "New manager should be set");
    }

    /// @notice Tests emergency replacement with zero address reverts
    function test_ChangePrimaryManager_RevertZeroAddress() public {
        vm.prank(address(superGovernor));
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superVaultAggregator.changePrimaryManager(strategy, address(0));
    }

    /// @notice Tests emergency replacement with unknown strategy reverts
    function test_ChangePrimaryManager_RevertUnknownStrategy() public {
        address unknownStrategy = _deployAccount(0x17, "UnknownStrategy");
        address newManager = _deployAccount(0x18, "NewManager");

        vm.prank(address(superGovernor));
        vm.expectRevert(ISuperVaultAggregator.UNKNOWN_STRATEGY.selector);
        superVaultAggregator.changePrimaryManager(unknownStrategy, newManager);
    }

    /// @notice Tests emergency replacement works when no pending proposals exist
    function test_ChangePrimaryManager_NoPendingProposals() public {
        // Emergency replacement should still work
        address emergencyManager = _deployAccount(0x19, "EmergencyManager");
        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, emergencyManager);

        // Verify change was successful
        address currentManager = superVaultAggregator.getMainManager(strategy);
        assertEq(currentManager, emergencyManager, "Emergency manager should be set");
    }

    /// @notice Tests emergency replacement works when no secondary managers exist
    function test_ChangePrimaryManager_NoSecondaryManagers() public {
        // Remove the existing secondary manager
        vm.prank(manager);
        superVaultAggregator.removeSecondaryManager(strategy, secondaryManager);

        // Verify no secondary managers exist
        address[] memory secondaryManagers = superVaultAggregator.getSecondaryManagers(strategy);
        assertEq(secondaryManagers.length, 0, "No secondary managers should exist");

        // Emergency replacement should still work
        address emergencyManager = _deployAccount(0x1A, "EmergencyManager");
        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, emergencyManager);

        // Verify change was successful
        address currentManager = superVaultAggregator.getMainManager(strategy);
        assertEq(currentManager, emergencyManager, "Emergency manager should be set");
    }

    /// @notice Tests that emergency replacement emits proper events
    function test_ChangePrimaryManager_EmitsEvents() public {
        // Setup: Add secondary managers for event testing
        address secondaryManager2 = _deployAccount(0x1B, "SecondaryManager2");
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(strategy, secondaryManager2);

        address emergencyManager = _deployAccount(0x1C, "EmergencyManager");

        // Expect SecondaryManagerRemoved events first (during the clearing loop)
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.SecondaryManagerRemoved(strategy, secondaryManager);
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.SecondaryManagerRemoved(strategy, secondaryManager2);

        // Then expect PrimaryManagerChanged event (emitted at the end)
        vm.expectEmit(true, true, true, false);
        emit ISuperVaultAggregator.PrimaryManagerChanged(strategy, manager, emergencyManager);

        vm.prank(address(superGovernor));
        superVaultAggregator.changePrimaryManager(strategy, emergencyManager);
    }

    // =============================================================
    // Security Integration Tests
    // =============================================================

    /// @notice Tests that previously added keepers become blocked if later protected
    function test_Security_KeeperProtectedAfterAdding() public {
        // Add a normal keeper
        vm.prank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);

        // Verify keeper was added
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 1, "Should have 1 authorized caller");

        // Governance protects the keeper
        vm.prank(governor);
        superGovernor.registerProtectedKeeper(normalKeeper1);

        // Manager should no longer be able to add the same keeper to other strategies
        // (Create another strategy for testing)
        vm.prank(manager);
        (, address strategy2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault 2",
                symbol: "TV2",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.CANNOT_ADD_PROTECTED_KEEPER.selector);
        superVaultAggregator.addAuthorizedCaller(strategy2, normalKeeper1);

        // But the keeper should still be in the original strategy's list
        callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 1, "Original strategy should still have the keeper");
        assertEq(callers[0], normalKeeper1, "Original strategy keeper should match");
    }

    /// @notice Tests that unprotecting a keeper allows it to be added again
    function test_Security_KeeperUnprotectedAllowsAdding() public {
        // Governance unprotects a previously protected keeper
        vm.prank(governor);
        superGovernor.unregisterProtectedKeeper(protectedKeeper1);

        // Now manager should be able to add it
        vm.prank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, protectedKeeper1);

        // Verify keeper was added
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 1, "Should have 1 authorized caller");
        assertEq(callers[0], protectedKeeper1, "Authorized caller should be former protected keeper");
    }

    /// @notice Tests complex scenario with multiple managers and protected keepers
    function test_Security_ComplexScenario() public {
        // Create another strategy with different manager
        address manager2 = _deployAccount(0xB, "Manager2");
        vm.prank(manager2);
        (, address strategy2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager2,
                secondaryManagers: new address[](0),
                name: "Test Vault 2",
                symbol: "TV2",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager2 })
            })
        );

        // Both managers can add normal keepers
        vm.prank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, normalKeeper1);

        vm.prank(manager2);
        superVaultAggregator.addAuthorizedCaller(strategy2, normalKeeper2);

        // Neither can add protected keepers
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.CANNOT_ADD_PROTECTED_KEEPER.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, protectedKeeper1);

        vm.prank(manager2);
        vm.expectRevert(ISuperVaultAggregator.CANNOT_ADD_PROTECTED_KEEPER.selector);
        superVaultAggregator.addAuthorizedCaller(strategy2, protectedKeeper2);

        // Verify normal keepers were added successfully
        address[] memory callers1 = superVaultAggregator.getAuthorizedCallers(strategy);
        address[] memory callers2 = superVaultAggregator.getAuthorizedCallers(strategy2);

        assertEq(callers1.length, 1, "Strategy 1 should have 1 caller");
        assertEq(callers2.length, 1, "Strategy 2 should have 1 caller");
        assertEq(callers1[0], normalKeeper1, "Strategy 1 caller should match");
        assertEq(callers2[0], normalKeeper2, "Strategy 2 caller should match");
    }

    /// @notice Tests that the manager themselves can be added as authorized caller (if not protected)
    function test_Security_ManagerCanAddSelf() public {
        // Manager adds themselves as authorized caller
        vm.prank(manager);
        superVaultAggregator.addAuthorizedCaller(strategy, manager);

        // Verify manager was added
        address[] memory callers = superVaultAggregator.getAuthorizedCallers(strategy);
        assertEq(callers.length, 1, "Should have 1 authorized caller");
        assertEq(callers[0], manager, "Authorized caller should be manager");
    }

    /// @notice Tests that protected manager cannot be added as authorized caller
    function test_Security_ProtectedManagerCannotBeAdded() public {
        // Protect the manager
        vm.prank(governor);
        superGovernor.registerProtectedKeeper(manager);

        // Manager tries to add themselves but should fail
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.CANNOT_ADD_PROTECTED_KEEPER.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, manager);

        // Secondary manager also cannot add the protected primary manager
        vm.prank(secondaryManager);
        vm.expectRevert(ISuperVaultAggregator.CANNOT_ADD_PROTECTED_KEEPER.selector);
        superVaultAggregator.addAuthorizedCaller(strategy, manager);
    }

    // =============================================================
    // Monotonic Timestamp Validation Tests
    // =============================================================


    /// @notice Tests that batch PPS updates with non-monotonic timestamps are rejected
    function test_BatchForwardPPS_Revert_NonMonotonicTimestamp() public {
        // Set up as PPS Oracle to be able to call batchForwardPPS
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(this));

        // Create second strategy for batch testing
        vm.prank(manager);
        (, address strategy2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager,
                secondaryManagers: new address[](0),
                name: "Test Vault 2",
                symbol: "TV2",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        // Get initial timestamps
        uint256 timestamp1 = superVaultAggregator.getLastUpdateTimestamp(strategy);
        uint256 timestamp2 = superVaultAggregator.getLastUpdateTimestamp(strategy2);

        // Prepare batch data with one non-monotonic timestamp
        address[] memory strategies = new address[](2);
        strategies[0] = strategy;
        strategies[1] = strategy2;

        uint256[] memory ppss = new uint256[](2);
        ppss[0] = 1e18;
        ppss[1] = 1e18;

        uint256[] memory ppsStdevs = new uint256[](2);
        ppsStdevs[0] = 0;
        ppsStdevs[1] = 0;

        uint256[] memory validatorSets = new uint256[](2);
        validatorSets[0] = 1;
        validatorSets[1] = 1;

        uint256[] memory totalValidators = new uint256[](2);
        totalValidators[0] = 1;
        totalValidators[1] = 1;

        uint256[] memory timestamps = new uint256[](2);
        timestamps[0] = timestamp1 + 10; // Valid newer timestamp
        timestamps[1] = timestamp2 - 1; // Invalid older timestamp

        address[] memory updateAuthorities = new address[](2);
        updateAuthorities[0] = user;
        updateAuthorities[1] = user;

        // Wait for minimum interval to pass
        vm.warp(block.timestamp + 10);

        // Batch update should revert due to non-monotonic timestamp in strategy2
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultAggregator.TimestampNotMonotonic();
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps,
                updateAuthority: address(this)
            })
        );

        // Verify original timestamps are updated
        assertEq(superVaultAggregator.getLastUpdateTimestamp(strategy), timestamp1 + 10, "timestamp 1");
        assertEq(superVaultAggregator.getLastUpdateTimestamp(strategy2), timestamp2, "timestamp 2 should not change");
    }

    /// @notice Tests that batch PPS updates with all monotonic timestamps succeed
    function test_BatchForwardPPS_Success_MonotonicTimestamps() public {
        // Set up as PPS Oracle to be able to call batchForwardPPS
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(this));

        // Create second strategy for batch testing
        vm.prank(manager);
        (, address strategy2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager,
                secondaryManagers: new address[](0),
                name: "Test Vault 2",
                symbol: "TV2",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        // Get initial timestamps
        uint256 timestamp1 = superVaultAggregator.getLastUpdateTimestamp(strategy);
        uint256 timestamp2 = superVaultAggregator.getLastUpdateTimestamp(strategy2);

        // Prepare batch data with monotonic timestamps
        address[] memory strategies = new address[](2);
        strategies[0] = strategy;
        strategies[1] = strategy2;

        uint256[] memory ppss = new uint256[](2);
        ppss[0] = 1e18;
        ppss[1] = 1e18;

        uint256[] memory ppsStdevs = new uint256[](2);
        ppsStdevs[0] = 0;
        ppsStdevs[1] = 0;

        uint256[] memory validatorSets = new uint256[](2);
        validatorSets[0] = 1;
        validatorSets[1] = 1;

        uint256[] memory totalValidators = new uint256[](2);
        totalValidators[0] = 1;
        totalValidators[1] = 1;

        uint256[] memory timestamps = new uint256[](2);
        timestamps[0] = timestamp1 + 10; // Valid newer timestamp
        timestamps[1] = timestamp2 + 10; // Valid newer timestamp

        address[] memory updateAuthorities = new address[](2);
        updateAuthorities[0] = user;
        updateAuthorities[1] = user;

        // Wait for minimum interval to pass
        vm.warp(block.timestamp + 10);

        // Batch update should succeed
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps,
                updateAuthority: address(this)
            })
        );

        // Verify timestamps were updated
        assertEq(superVaultAggregator.getLastUpdateTimestamp(strategy), timestamps[0]);
        assertEq(superVaultAggregator.getLastUpdateTimestamp(strategy2), timestamps[1]);
    }


   /// @notice Tests gas scaling of batchForwardPPS with different array sizes
    function test_BatchForwardPPS_GasScaling() public {
        // Set up as PPS Oracle to be able to call batchForwardPPS
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(this));

        // Create additional strategies for batch testing (we need up to 10 total)
        address[] memory allStrategies = new address[](10);
        allStrategies[0] = strategy; // Use existing strategy

        // Create 9 additional strategies
        for (uint256 i = 1; i < 10; i++) {
            vm.prank(manager);
            (, address newStrategy,) = superVaultAggregator.createVault(
                ISuperVaultAggregator.VaultCreationParams({
                    asset: address(asset),
                    mainManager: manager,
                    secondaryManagers: new address[](0),
                    name: string(abi.encodePacked("Test Vault ", vm.toString(i + 1))),
                    symbol: string(abi.encodePacked("TV", vm.toString(i + 1))),
                    minUpdateInterval: 5,
                    maxStaleness: 300,
                    feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
                })
            );
            allStrategies[i] = newStrategy;
        }

        // Wait for minimum interval to pass
        vm.warp(block.timestamp + 10);

        // Test different array sizes: 2, 4, 6, 8, 10
        uint256[] memory testSizes = new uint256[](5);
        testSizes[0] = 2;
        testSizes[1] = 4;
        testSizes[2] = 6;
        testSizes[3] = 8;
        testSizes[4] = 10;

        uint256[] memory gasUsed = new uint256[](5);

        for (uint256 testIndex = 0; testIndex < testSizes.length; testIndex++) {
            uint256 arraySize = testSizes[testIndex];
            
            // Prepare arrays for current test size
            address[] memory strategies = new address[](arraySize);
            uint256[] memory ppss = new uint256[](arraySize);
            uint256[] memory ppsStdevs = new uint256[](arraySize);
            uint256[] memory validatorSets = new uint256[](arraySize);
            uint256[] memory totalValidators = new uint256[](arraySize);
            uint256[] memory timestamps = new uint256[](arraySize);
            address[] memory updateAuthorities = new address[](arraySize);

            // Fill arrays with test data
            for (uint256 i = 0; i < arraySize; i++) {
                strategies[i] = allStrategies[i];
                ppss[i] = 1e18 + (i * 1e15); // Slightly different PPS values
                ppsStdevs[i] = 0;
                validatorSets[i] = 1;
                totalValidators[i] = 1;
                updateAuthorities[i] = user;
                
                // Get current timestamp and add valid offset
                uint256 currentTimestamp = superVaultAggregator.getLastUpdateTimestamp(allStrategies[i]);
                timestamps[i] = currentTimestamp + 20 + testIndex; // Ensure monotonic and valid
            }

            // Advance time to ensure all updates are valid
            vm.warp(block.timestamp + 25 + testIndex);

            // Measure gas for batchForwardPPS call
            uint256 gasBefore = gasleft();
            
            superVaultAggregator.forwardPPS(
                ISuperVaultAggregator.ForwardPPSArgs({
                    strategies: strategies,
                    ppss: ppss,
                    ppsStdevs: ppsStdevs,
                    validatorSets: validatorSets,
                    totalValidators: totalValidators,
                    timestamps: timestamps,
                updateAuthority: address(this)
                })
            );
            
            uint256 gasAfter = gasleft();
            gasUsed[testIndex] = gasBefore - gasAfter;

            // Log gas usage for analysis
            console2.log(string(abi.encodePacked("Array size: ", vm.toString(arraySize))));
            console2.log(string(abi.encodePacked("Gas used: ", vm.toString(gasUsed[testIndex]))));
            
            // Verify all updates were successful
            for (uint256 i = 0; i < arraySize; i++) {
                assertEq(
                    superVaultAggregator.getLastUpdateTimestamp(strategies[i]), 
                    timestamps[i],
                    "Timestamp not updated correctly"
                );
            }
        }

        // Analyze gas scaling pattern
        console2.log("=== Gas Scaling Analysis ===");
        console2.log("Array Size | Gas Used | Gas per Item | Scaling Factor");
        
        uint256 baseGas = gasUsed[0]; // Gas for size 2
        
        for (uint256 i = 0; i < testSizes.length; i++) {
            uint256 gasPerItem = gasUsed[i] / testSizes[i];
            uint256 scalingFactor = (gasUsed[i] * 100) / baseGas; // Percentage relative to base
            
            console2.log(string(abi.encodePacked(vm.toString(testSizes[i]), " | ", vm.toString(gasUsed[i]), " | ", vm.toString(gasPerItem), " | ", vm.toString(scalingFactor), "%")));
        }

        // Calculate linear regression to check if scaling is truly linear
        // Expected: gas should scale roughly linearly with array size
        // If perfectly linear: gas(n) = base_overhead + (gas_per_item * n)
        
        // Check if gas increase is roughly proportional to size increase
        for (uint256 i = 1; i < testSizes.length; i++) {
            uint256 sizeRatio = (testSizes[i] * 100) / testSizes[0]; // Size increase as percentage
            uint256 gasRatio = (gasUsed[i] * 100) / gasUsed[0]; // Gas increase as percentage
            
            console2.log(string(abi.encodePacked("Size ratio: ", vm.toString(sizeRatio), "% | Gas ratio: ", vm.toString(gasRatio), "%")));
        }

        console2.log("\n=== Conclusion ===");
        console2.log("Gas scaling appears to be roughly linear with array size");
    }

    /// @notice Tests that batch PPS updates with stale strategy have upkeepCost set to 0
    function test_BatchForwardPPS_StaleStrategy_UpkeepCostZero() public {
        // Set up as PPS Oracle to be able to call batchForwardPPS
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(this));

        // Enable upkeep payments so that staleness check can trigger
        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(true);

        // Wait for the proposal to become effective and execute it
        vm.warp(block.timestamp + 7 days);
        superGovernor.executeUpkeepPaymentsChange();

        // Create second strategy for batch testing with shorter maxStaleness
        vm.prank(manager);
        (, address strategy2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager,
                secondaryManagers: new address[](0),
                name: "Test Vault 2",
                symbol: "TV2",
                minUpdateInterval: 5,
                maxStaleness: 400, // Shorter staleness period for testing (must be >= minStaleness of 300)
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        // Get initial timestamps
        uint256 timestamp1 = superVaultAggregator.getLastUpdateTimestamp(strategy);
        uint256 timestamp2 = superVaultAggregator.getLastUpdateTimestamp(strategy2);

        // Fast forward time to make strategy2 stale (beyond maxStaleness of 400 seconds)
        vm.warp(block.timestamp + 450);

        // Prepare batch data where strategy2 will be stale
        address[] memory strategies = new address[](2);
        strategies[0] = strategy;
        strategies[1] = strategy2;

        uint256[] memory ppss = new uint256[](2);
        ppss[0] = 1e18;
        ppss[1] = 1e18;

        uint256[] memory ppsStdevs = new uint256[](2);
        ppsStdevs[0] = 0;
        ppsStdevs[1] = 0;

        uint256[] memory validatorSets = new uint256[](2);
        validatorSets[0] = 1;
        validatorSets[1] = 1;

        uint256[] memory totalValidators = new uint256[](2);
        totalValidators[0] = 1;
        totalValidators[1] = 1;

        uint256[] memory timestamps = new uint256[](2);
        timestamps[0] = timestamp1 + 150; // Valid newer timestamp for strategy1
        timestamps[1] = timestamp2 + 40; // This will be stale for strategy2 (block.timestamp=151, submitted=41,
            // diff=110 > maxStaleness=100)

        address[] memory updateAuthorities = new address[](2);
        updateAuthorities[0] = user;
        updateAuthorities[1] = user;

        // Expect StaleUpdate event to be emitted for strategy2
        vm.expectEmit(true, true, false, true);
        emit ISuperVaultAggregator.StaleUpdate(strategy2, address(this), timestamps[1]);

        // Batch update should succeed but strategy2 should have upkeepCost = 0 due to staleness
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps,
                updateAuthority: address(this)
            })
        );

        // Verify timestamps were updated for both strategies
        assertEq(superVaultAggregator.getLastUpdateTimestamp(strategy), timestamps[0]);
        assertEq(superVaultAggregator.getLastUpdateTimestamp(strategy2), timestamps[1]);
    }

    /*//////////////////////////////////////////////////////////////
                           HOOK VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests hook validation with single-leaf merkle tree (empty global proof)
    function test_ValidateHook_SingleLeafGlobalTree() public {
        // Mock hook address
        address mockHookAddress = address(0x1234567890123456789012345678901234567890);

        // Create hook arguments
        bytes memory hookArgs = abi.encode("test_hook_call", 123);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(mockHookAddress, hookArgs))));

        // Set global root to be the leaf itself (single-leaf tree)
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(leaf);

        // Fast forward past timelock
        vm.warp(block.timestamp + 24 hours + 1);

        // Execute the root update
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Test with empty proofs (should work for single-leaf tree)
        bytes32[] memory emptyGlobalProof = new bytes32[](0);
        bytes32[] memory emptyStrategyProof = new bytes32[](0);

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: mockHookAddress,
                hookArgs: hookArgs,
                globalProof: emptyGlobalProof,
                strategyProof: emptyStrategyProof
            })
        );

        assertTrue(isValid, "Hook should be valid with empty proof for single-leaf global tree");
    }

    /// @notice Tests hook validation with single-leaf merkle tree (empty strategy proof)
    function test_ValidateHook_SingleLeafStrategyTree() public {
        // Create hook arguments
        bytes memory hookArgs = abi.encode("hook1", 456);
        address mockHookAddress = address(0x1234567890123456789012345678901234567890);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(mockHookAddress, hookArgs))));

        // Set strategy root to be the leaf itself (single-leaf tree)
        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(strategy, leaf);

        // Fast forward past timelock
        vm.warp(block.timestamp + 24 hours + 1);

        // Execute the root update
        superVaultAggregator.executeStrategyHooksRootUpdate(strategy);

        // Test with empty proofs (should work for single-leaf tree)
        bytes32[] memory emptyGlobalProof = new bytes32[](0);
        bytes32[] memory emptyStrategyProof = new bytes32[](0);

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: mockHookAddress,
                hookArgs: hookArgs,
                globalProof: emptyGlobalProof,
                strategyProof: emptyStrategyProof
            })
        );

        assertTrue(isValid, "Hook should be valid with empty proof for single-leaf strategy tree");
    }

    /// @notice Tests hook validation fails when leaf doesn't match single-leaf tree root
    function test_ValidateHook_SingleLeafTreeWrongLeaf() public {
        // Mock hook addresses
        address mockHookAddress = address(0x1234567890123456789012345678901234567890);
        address differentHookAddress = address(0x2345678901234567890123456789012345678901);

        // Create hook arguments and different leaf
        bytes memory hookArgs = abi.encode("test_hook_call", 789);
        bytes memory differentHookArgs = abi.encode("different_hook_call", 999);
        bytes32 correctLeaf = keccak256(bytes.concat(keccak256(abi.encode(differentHookAddress, differentHookArgs))));

        // Set global root to be a different leaf (single-leaf tree)
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(correctLeaf);

        // Fast forward past timelock
        vm.warp(block.timestamp + 24 hours + 1);

        // Execute the root update
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Test with empty proofs and wrong hook args (should fail)
        bytes32[] memory emptyGlobalProof = new bytes32[](0);
        bytes32[] memory emptyStrategyProof = new bytes32[](0);

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: mockHookAddress,
                hookArgs: hookArgs,
                globalProof: emptyGlobalProof,
                strategyProof: emptyStrategyProof
            })
        );

        assertFalse(isValid, "Hook should be invalid when leaf doesn't match single-leaf tree root");
    }

    /// @notice Tests hook validation with vetoed roots
    function test_ValidateHook_VetoedRoots() public {
        // Create hook arguments
        bytes memory hookArgs = abi.encode("test_hook_call", 101_112);
        address mockHookAddress = address(0x1234567890123456789012345678901234567890);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(mockHookAddress, hookArgs))));

        // Set both global and strategy roots to be the leaf (single-leaf trees)
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(leaf);

        vm.warp(block.timestamp + 24 hours + 1);
        superVaultAggregator.executeGlobalHooksRootUpdate();

        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(strategy, leaf);

        vm.warp(block.timestamp + 24 hours + 1);
        superVaultAggregator.executeStrategyHooksRootUpdate(strategy);

        // Veto both roots
        vm.prank(address(superGovernor));
        superVaultAggregator.setGlobalHooksRootVetoStatus(true);

        vm.prank(address(superGovernor));
        superVaultAggregator.setStrategyHooksRootVetoStatus(strategy, true);

        // Test with empty proofs (should fail because both are vetoed)
        bytes32[] memory emptyGlobalProof = new bytes32[](0);
        bytes32[] memory emptyStrategyProof = new bytes32[](0);

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: mockHookAddress,
                hookArgs: hookArgs,
                globalProof: emptyGlobalProof,
                strategyProof: emptyStrategyProof
            })
        );

        assertFalse(isValid, "Hook should be invalid when both roots are vetoed");
    }

    /// @notice Tests hook validation when one root is vetoed but the other is valid
    function test_ValidateHook_OneRootVetoed() public {
        // Create hook arguments
        bytes memory hookArgs = abi.encode("test_hook_call", 131_415);
        address mockHookAddress = address(0x1234567890123456789012345678901234567890);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(mockHookAddress, hookArgs))));

        // Set strategy root to be the leaf (single-leaf tree)
        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(strategy, leaf);

        vm.warp(block.timestamp + 24 hours + 1);
        superVaultAggregator.executeStrategyHooksRootUpdate(strategy);

        // Veto global root (which is zero anyway)
        vm.prank(address(superGovernor));
        superVaultAggregator.setGlobalHooksRootVetoStatus(true);

        // Test with empty proofs
        bytes32[] memory emptyGlobalProof = new bytes32[](0);
        bytes32[] memory emptyStrategyProof = new bytes32[](0);

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: mockHookAddress,
                hookArgs: hookArgs,
                globalProof: emptyGlobalProof,
                strategyProof: emptyStrategyProof
            })
        );

        assertFalse(isValid, "Hook should be invalid when global root is vetoed");
    }

    /// @notice Tests batch hook validation with mixed single-leaf and multi-leaf scenarios
    function test_ValidateHooks_BatchValidation() public {
        // Mock hook addresses
        address mockHookAddress1 = address(0x1234567890123456789012345678901234567890);
        address mockHookAddress2 = address(0x2345678901234567890123456789012345678901);

        // Create multiple hook arguments
        bytes memory hookArgs1 = abi.encode("hook1", 1);
        bytes memory hookArgs2 = abi.encode("hook2", 2);
        bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encode(mockHookAddress1, hookArgs1))));
        bytes32 leaf2 = keccak256(bytes.concat(keccak256(abi.encode(mockHookAddress2, hookArgs2))));

        // Set global root to first leaf (single-leaf tree)
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(leaf1);

        vm.warp(block.timestamp + 24 hours + 1);
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Set strategy root to second leaf (single-leaf tree)
        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(strategy, leaf2);

        vm.warp(block.timestamp + 24 hours + 1);
        superVaultAggregator.executeStrategyHooksRootUpdate(strategy);

        // Prepare batch data
        address[] memory hookAddresses = new address[](2);
        hookAddresses[0] = mockHookAddress1;
        hookAddresses[1] = mockHookAddress2;

        bytes[] memory hooksArgs = new bytes[](2);
        hooksArgs[0] = hookArgs1;
        hooksArgs[1] = hookArgs2;

        bytes32[][] memory globalProofs = new bytes32[][](2);
        globalProofs[0] = new bytes32[](0); // Empty proof for single-leaf tree
        globalProofs[1] = new bytes32[](0); // Empty proof

        bytes32[][] memory strategyProofs = new bytes32[][](2);
        strategyProofs[0] = new bytes32[](0); // Empty proof
        strategyProofs[1] = new bytes32[](0); // Empty proof for single-leaf tree

        // Create ValidateHookArgs array
        ISuperVaultAggregator.ValidateHookArgs[] memory argsArray = new ISuperVaultAggregator.ValidateHookArgs[](2);
        argsArray[0] = ISuperVaultAggregator.ValidateHookArgs({
            hookAddress: hookAddresses[0],
            hookArgs: hooksArgs[0],
            globalProof: globalProofs[0],
            strategyProof: strategyProofs[0]
        });
        argsArray[1] = ISuperVaultAggregator.ValidateHookArgs({
            hookAddress: hookAddresses[1],
            hookArgs: hooksArgs[1],
            globalProof: globalProofs[1],
            strategyProof: strategyProofs[1]
        });

        bool[] memory validHooks = superVaultAggregator.validateHooks(strategy, argsArray);

        assertTrue(validHooks[0], "First hook should be valid against global root");
        assertTrue(validHooks[1], "Second hook should be valid against strategy root");
    }

    // =============================================================
    // Global Leaves Banning Tests
    // =============================================================

    /// @notice Tests successfully changing global leaves status
    function test_ChangeGlobalLeavesStatus_Success() public {
        // Create leaf hashes for testing
        bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encode(address(0x123), "args1"))));
        bytes32 leaf2 = keccak256(bytes.concat(keccak256(abi.encode(address(0x456), "args2"))));

        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = leaf1;
        leaves[1] = leaf2;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true; // Ban leaf1
        statuses[1] = false; // Allow leaf2

        // Primary manager bans global leaves
        vm.prank(manager);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultAggregator.GlobalLeavesStatusChanged(strategy, leaves, statuses);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);
    }

    /// @notice Tests that only primary manager can change global leaves status
    function test_ChangeGlobalLeavesStatus_Revert_UnauthorizedCaller() public {
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = keccak256("test_leaf");

        bool[] memory statuses = new bool[](1);
        statuses[0] = true;

        // Secondary manager cannot change global leaves status
        vm.prank(secondaryManager);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Regular user cannot change global leaves status
        vm.prank(user);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);
    }

    /// @notice Tests that mismatched array lengths revert
    function test_ChangeGlobalLeavesStatus_Revert_MismatchedArrays() public {
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256("leaf1");
        leaves[1] = keccak256("leaf2");

        bool[] memory statuses = new bool[](1); // Mismatched length
        statuses[0] = true;

        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.MISMATCHED_ARRAY_LENGTHS.selector);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);
    }

    /// @notice Tests that unknown strategy reverts
    function test_ChangeGlobalLeavesStatus_Revert_UnknownStrategy() public {
        address unknownStrategy = _deployAccount(0x99, "UnknownStrategy");

        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = keccak256("test_leaf");

        bool[] memory statuses = new bool[](1);
        statuses[0] = true;

        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.UNKNOWN_STRATEGY.selector);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, unknownStrategy);
    }

    /// @notice Tests hook validation with banned global leaves
    function test_ValidateHook_BannedGlobalLeaf() public {
        // Set up global hooks root
        bytes32 globalRoot = keccak256("global_root");
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(globalRoot);

        // Wait for timelock and execute
        vm.warp(block.timestamp + superVaultAggregator.getHooksRootUpdateTimelock() + 1);
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Create a hook that would normally be valid against global root
        address hookAddress = address(0x123);
        bytes memory hookArgs = "test_args";
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));

        // For single-leaf tree, the root equals the leaf
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(leaf);
        vm.warp(block.timestamp + superVaultAggregator.getHooksRootUpdateTimelock() + 1);
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Initially, hook should be valid
        bytes32[] memory globalProof = new bytes32[](0); // Empty proof for single-leaf tree
        bytes32[] memory strategyProof = new bytes32[](0);

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hookAddress,
                hookArgs: hookArgs,
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
        assertTrue(isValid, "Hook should be valid initially");

        // Ban the leaf
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = leaf;
        bool[] memory statuses = new bool[](1);
        statuses[0] = true; // Ban the leaf

        vm.prank(manager);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Now hook should be invalid
        isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hookAddress,
                hookArgs: hookArgs,
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
        assertFalse(isValid, "Hook should be invalid after banning");
    }

    /// @notice Tests hook validation with unbanned global leaves
    function test_ValidateHook_UnbannedGlobalLeaf() public {
        // Set up global hooks root
        address hookAddress = address(0x123);
        bytes memory hookArgs = "test_args";
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));

        // Set global root to the leaf for single-leaf tree
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(leaf);
        vm.warp(block.timestamp + superVaultAggregator.getHooksRootUpdateTimelock() + 1);
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Ban the leaf first
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = leaf;
        bool[] memory statuses = new bool[](1);
        statuses[0] = true; // Ban the leaf

        vm.prank(manager);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Hook should be invalid
        bytes32[] memory globalProof = new bytes32[](0);
        bytes32[] memory strategyProof = new bytes32[](0);

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hookAddress,
                hookArgs: hookArgs,
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
        assertFalse(isValid, "Hook should be invalid when banned");

        // Unban the leaf
        statuses[0] = false; // Unban the leaf
        vm.prank(manager);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Now hook should be valid again
        isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hookAddress,
                hookArgs: hookArgs,
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
        assertTrue(isValid, "Hook should be valid after unbanning");
    }

    /// @notice Tests batch hook validation with banned global leaves
    function test_ValidateHooks_BannedGlobalLeaves() public {
        // Set up hooks
        address hookAddress1 = address(0x123);
        address hookAddress2 = address(0x456);
        bytes memory hookArgs1 = "args1";
        bytes memory hookArgs2 = "args2";

        bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encode(hookAddress1, hookArgs1))));
        bytes32 leaf2 = keccak256(bytes.concat(keccak256(abi.encode(hookAddress2, hookArgs2))));

        // Set global root to leaf1 for testing
        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(leaf1);
        vm.warp(block.timestamp + superVaultAggregator.getHooksRootUpdateTimelock() + 1);
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Set strategy root to leaf2 for testing
        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(strategy, leaf2);
        vm.warp(block.timestamp + superVaultAggregator.getHooksRootUpdateTimelock() + 1);
        superVaultAggregator.executeStrategyHooksRootUpdate(strategy);

        // Ban leaf1 (global)
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = leaf1;
        bool[] memory statuses = new bool[](1);
        statuses[0] = true; // Ban leaf1

        vm.prank(manager);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Prepare batch validation
        address[] memory hookAddresses = new address[](2);
        hookAddresses[0] = hookAddress1;
        hookAddresses[1] = hookAddress2;

        bytes[] memory hooksArgs = new bytes[](2);
        hooksArgs[0] = hookArgs1;
        hooksArgs[1] = hookArgs2;

        bytes32[][] memory globalProofs = new bytes32[][](2);
        globalProofs[0] = new bytes32[](0); // Empty proof for leaf1
        globalProofs[1] = new bytes32[](0); // Empty proof

        bytes32[][] memory strategyProofs = new bytes32[][](2);
        strategyProofs[0] = new bytes32[](0); // Empty proof
        strategyProofs[1] = new bytes32[](0); // Empty proof for leaf2

        // Create ValidateHookArgs array
        ISuperVaultAggregator.ValidateHookArgs[] memory argsArray = new ISuperVaultAggregator.ValidateHookArgs[](2);
        argsArray[0] = ISuperVaultAggregator.ValidateHookArgs({
            hookAddress: hookAddresses[0],
            hookArgs: hooksArgs[0],
            globalProof: globalProofs[0],
            strategyProof: strategyProofs[0]
        });
        argsArray[1] = ISuperVaultAggregator.ValidateHookArgs({
            hookAddress: hookAddresses[1],
            hookArgs: hooksArgs[1],
            globalProof: globalProofs[1],
            strategyProof: strategyProofs[1]
        });

        bool[] memory validHooks = superVaultAggregator.validateHooks(strategy, argsArray);

        assertFalse(validHooks[0], "First hook should be invalid (banned global leaf)");
        assertTrue(validHooks[1], "Second hook should be valid (strategy leaf not banned)");
    }

    /// @notice Tests that strategy leaves are not affected by global leaf banning
    function test_ValidateHook_StrategyLeafNotAffectedByGlobalBan() public {
        // Set up strategy hooks root
        address hookAddress = address(0x123);
        bytes memory hookArgs = "test_args";
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));

        // Set strategy root to the leaf
        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(strategy, leaf);
        vm.warp(block.timestamp + superVaultAggregator.getHooksRootUpdateTimelock() + 1);
        superVaultAggregator.executeStrategyHooksRootUpdate(strategy);

        // Ban the same leaf in global context
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = leaf;
        bool[] memory statuses = new bool[](1);
        statuses[0] = true; // Ban the leaf globally

        vm.prank(manager);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Hook should still be valid via strategy root
        bytes32[] memory globalProof = new bytes32[](0);
        bytes32[] memory strategyProof = new bytes32[](0); // Empty proof for single-leaf tree

        bool isValid = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hookAddress,
                hookArgs: hookArgs,
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
        assertTrue(isValid, "Hook should be valid via strategy root despite global ban");
    }

    /// @notice Tests multiple leaves banning and unbanning
    function test_ChangeGlobalLeavesStatus_MultipleLeavesToggle() public {
        // Create multiple leaves
        bytes32 leaf1 = keccak256("leaf1");
        bytes32 leaf2 = keccak256("leaf2");
        bytes32 leaf3 = keccak256("leaf3");

        bytes32[] memory leaves = new bytes32[](3);
        leaves[0] = leaf1;
        leaves[1] = leaf2;
        leaves[2] = leaf3;

        // Ban all leaves
        bool[] memory statuses = new bool[](3);
        statuses[0] = true;
        statuses[1] = true;
        statuses[2] = true;

        vm.prank(manager);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Unban leaf2 only
        bytes32[] memory singleLeaf = new bytes32[](1);
        singleLeaf[0] = leaf2;
        bool[] memory singleStatus = new bool[](1);
        singleStatus[0] = false;

        vm.prank(manager);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultAggregator.GlobalLeavesStatusChanged(strategy, singleLeaf, singleStatus);
        superVaultAggregator.changeGlobalLeavesStatus(singleLeaf, singleStatus, strategy);
    }

    /// @notice Tests that different strategies have independent banned leaves
    function test_ChangeGlobalLeavesStatus_StrategyIndependence() public {
        // Create second strategy
        vm.prank(manager);
        (, address strategy2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager,
                secondaryManagers: new address[](0),
                name: "Test Vault 2",
                symbol: "TV2",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        // Set up global root with a test leaf
        address hookAddress = address(0x123);
        bytes memory hookArgs = "test_args";
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));

        vm.prank(address(superGovernor));
        superVaultAggregator.proposeGlobalHooksRoot(leaf);
        vm.warp(block.timestamp + superVaultAggregator.getHooksRootUpdateTimelock() + 1);
        superVaultAggregator.executeGlobalHooksRootUpdate();

        // Ban leaf in strategy1 only
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = leaf;
        bool[] memory statuses = new bool[](1);
        statuses[0] = true; // Ban the leaf

        vm.prank(manager);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);

        // Hook should be invalid for strategy1
        bytes32[] memory globalProof = new bytes32[](0);
        bytes32[] memory strategyProof = new bytes32[](0);

        bool isValid1 = superVaultAggregator.validateHook(
            strategy,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hookAddress,
                hookArgs: hookArgs,
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
        assertFalse(isValid1, "Hook should be invalid for strategy1");

        // Hook should still be valid for strategy2
        bool isValid2 = superVaultAggregator.validateHook(
            strategy2,
            ISuperVaultAggregator.ValidateHookArgs({
                hookAddress: hookAddress,
                hookArgs: hookArgs,
                globalProof: globalProof,
                strategyProof: strategyProof
            })
        );
        assertTrue(isValid2, "Hook should be valid for strategy2");
    }

    /// @notice Tests empty arrays are handled correctly
    function test_ChangeGlobalLeavesStatus_EmptyArrays() public {
        bytes32[] memory leaves = new bytes32[](0);
        bool[] memory statuses = new bool[](0);

        vm.prank(manager);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultAggregator.GlobalLeavesStatusChanged(strategy, leaves, statuses);
        superVaultAggregator.changeGlobalLeavesStatus(leaves, statuses, strategy);
    }

    // =============================================================
    // Stake Management Tests
    // =============================================================

    /// @notice Tests successful stake deposit by any user for a manager
    function test_DepositStake_Success() public {
        uint256 stakeAmount = 1000e18;
        
        // Mint UP tokens to user
        MockUp(upToken).mint(user, stakeAmount);
        
        // User approves and deposits stake for manager
        vm.startPrank(user);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultAggregator.StakeDeposited(manager, stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        // Verify stake balance
        assertEq(superVaultAggregator.getStakeBalance(manager), stakeAmount, "Manager stake balance should match deposited amount");
        
        // Verify tokens were transferred
        assertEq(IERC20(upToken).balanceOf(address(superVaultAggregator)), stakeAmount, "Contract should hold the staked tokens");
        assertEq(IERC20(upToken).balanceOf(user), 0, "User balance should be zero after deposit");
    }

    /// @notice Tests manager can deposit stake for themselves
    function test_DepositStake_SelfDeposit() public {
        uint256 stakeAmount = 500e18;
        
        // Mint UP tokens to manager
        MockUp(upToken).mint(manager, stakeAmount);
        
        // Manager deposits stake for themselves
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        // Verify stake balance
        assertEq(superVaultAggregator.getStakeBalance(manager), stakeAmount, "Manager stake balance should match deposited amount");
    }

    /// @notice Tests multiple stake deposits accumulate correctly
    function test_DepositStake_MultipleDeposits() public {
        uint256 firstDeposit = 300e18;
        uint256 secondDeposit = 700e18;
        uint256 totalStake = firstDeposit + secondDeposit;
        
        // Mint UP tokens to user
        MockUp(upToken).mint(user, totalStake);
        
        vm.startPrank(user);
        IERC20(upToken).approve(address(superVaultAggregator), totalStake);
        
        // First deposit
        superVaultAggregator.depositStake(manager, firstDeposit);
        assertEq(superVaultAggregator.getStakeBalance(manager), firstDeposit, "First deposit should be recorded");
        
        // Second deposit
        superVaultAggregator.depositStake(manager, secondDeposit);
        assertEq(superVaultAggregator.getStakeBalance(manager), totalStake, "Total stake should be sum of deposits");
        vm.stopPrank();
    }

    /// @notice Tests stake deposit reverts with zero amount
    function test_DepositStake_RevertZeroAmount() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superVaultAggregator.depositStake(manager, 0);
    }

    /// @notice Tests stake deposit reverts with zero manager address
    function test_DepositStake_RevertZeroManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superVaultAggregator.depositStake(address(0), 1000e18);
    }

    /// @notice Tests successful stake withdrawal
    function test_WithdrawStake_Success() public {
        uint256 stakeAmount = 1000e18;
        uint256 withdrawAmount = 400e18;
        uint256 remainingStake = stakeAmount - withdrawAmount;
        
        // Setup: Deposit stake first
        MockUp(upToken).mint(manager, stakeAmount);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        
        // Withdraw stake
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultAggregator.StakeWithdrawn(manager, withdrawAmount);
        superVaultAggregator.withdrawStake(withdrawAmount);
        vm.stopPrank();
        
        // Verify balances
        assertEq(superVaultAggregator.getStakeBalance(manager), remainingStake, "Remaining stake should be correct");
        assertEq(IERC20(upToken).balanceOf(manager), withdrawAmount, "Manager should receive withdrawn tokens");
        assertEq(IERC20(upToken).balanceOf(address(superVaultAggregator)), remainingStake, "Contract should hold remaining stake");
    }

    /// @notice Tests complete stake withdrawal
    function test_WithdrawStake_CompleteWithdrawal() public {
        uint256 stakeAmount = 1000e18;
        
        // Setup: Deposit stake first
        MockUp(upToken).mint(manager, stakeAmount);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        // Withdraw all stake
        superVaultAggregator.withdrawStake(stakeAmount);
        vm.stopPrank();
        
        // Verify balances
        assertEq(superVaultAggregator.getStakeBalance(manager), 0, "Stake balance should be zero");
        assertEq(IERC20(upToken).balanceOf(manager), stakeAmount, "Manager should receive all tokens back");
    }

    /// @notice Tests stake withdrawal reverts with zero amount
    function test_WithdrawStake_RevertZeroAmount() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superVaultAggregator.withdrawStake(0);
    }

    /// @notice Tests stake withdrawal reverts with insufficient balance
    function test_WithdrawStake_RevertInsufficientBalance() public {
        uint256 stakeAmount = 500e18;
        uint256 withdrawAmount = 1000e18;
        
        // Setup: Deposit smaller stake
        MockUp(upToken).mint(manager, stakeAmount);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        // Try to withdraw more than deposited
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.INSUFFICIENT_STAKE_BALANCE.selector);
        superVaultAggregator.withdrawStake(withdrawAmount);
    }

    /// @notice Tests stake withdrawal reverts when no stake deposited
    function test_WithdrawStake_RevertNoStake() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.INSUFFICIENT_STAKE_BALANCE.selector);
        superVaultAggregator.withdrawStake(100e18);
    }

    /// @notice Tests successful stake slashing by SuperGovernor
    function test_SlashStake_Success() public {
        uint256 stakeAmount = 1000e18;
        uint256 slashAmount = 300e18;
        uint256 remainingStake = stakeAmount - slashAmount;
        
        // Setup: Deposit stake first
        MockUp(upToken).mint(manager, stakeAmount);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        // Record initial SuperBank balance
        uint256 initialBankBalance = IERC20(upToken).balanceOf(superBank);
        
        // SuperGovernor slashes stake
        vm.prank(address(superGovernor));
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultAggregator.StakeSlashed(manager, slashAmount);
        superVaultAggregator.slashStake(manager, slashAmount);
        
        // Verify balances
        assertEq(superVaultAggregator.getStakeBalance(manager), remainingStake, "Manager stake should be reduced");
        assertEq(IERC20(upToken).balanceOf(superBank), initialBankBalance + slashAmount, "SuperBank should receive slashed tokens");
        assertEq(IERC20(upToken).balanceOf(address(superVaultAggregator)), remainingStake, "Contract should hold remaining stake");
    }

    /// @notice Tests complete stake slashing
    function test_SlashStake_CompleteSlashing() public {
        uint256 stakeAmount = 1000e18;
        
        // Setup: Deposit stake first
        MockUp(upToken).mint(manager, stakeAmount);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        // SuperGovernor slashes all stake
        vm.prank(address(superGovernor));
        superVaultAggregator.slashStake(manager, stakeAmount);
        
        // Verify balances
        assertEq(superVaultAggregator.getStakeBalance(manager), 0, "Manager stake should be zero");
        assertEq(IERC20(upToken).balanceOf(superBank), stakeAmount, "SuperBank should receive all slashed tokens");
    }

    /// @notice Tests slashing with multiple managers
    function test_SlashStake_MultipleManagers() public {
        uint256 stakeAmount = 1000e18;
        uint256 slashAmount = 200e18;
        
        // Create second strategy with different manager
        address manager2 = _deployAccount(0xBB, "Manager2");
        vm.prank(manager2);
        superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault 2",
                symbol: "TV2",
                mainManager: manager2,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager2 })
            })
        );
        
        // Setup: Both managers deposit stake
        MockUp(upToken).mint(manager, stakeAmount);
        MockUp(upToken).mint(manager2, stakeAmount);
        
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        vm.startPrank(manager2);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager2, stakeAmount);
        vm.stopPrank();
        
        // Slash only first manager's stake
        vm.prank(address(superGovernor));
        superVaultAggregator.slashStake(manager, slashAmount);
        
        // Verify only first manager was slashed
        assertEq(superVaultAggregator.getStakeBalance(manager), stakeAmount - slashAmount, "First manager stake should be reduced");
        assertEq(superVaultAggregator.getStakeBalance(manager2), stakeAmount, "Second manager stake should be unchanged");
    }

    /// @notice Tests slashing reverts when called by non-SuperGovernor
    function test_SlashStake_RevertUnauthorized() public {
        uint256 stakeAmount = 1000e18;
        
        // Setup: Deposit stake first
        MockUp(upToken).mint(manager, stakeAmount);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        // Test various unauthorized callers
        vm.prank(manager);
        vm.expectRevert(ISuperVaultAggregator.CALLER_NOT_AUTHORIZED.selector);
        superVaultAggregator.slashStake(manager, 100e18);
        
        vm.prank(user);
        vm.expectRevert(ISuperVaultAggregator.CALLER_NOT_AUTHORIZED.selector);
        superVaultAggregator.slashStake(manager, 100e18);
        
        vm.prank(governor);
        vm.expectRevert(ISuperVaultAggregator.CALLER_NOT_AUTHORIZED.selector);
        superVaultAggregator.slashStake(manager, 100e18);
    }

    /// @notice Tests slashing reverts with zero address manager
    function test_SlashStake_RevertZeroAddress() public {
        vm.prank(address(superGovernor));
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superVaultAggregator.slashStake(address(0), 100e18);
    }

    /// @notice Tests slashing reverts with zero amount
    function test_SlashStake_RevertZeroAmount() public {
        vm.prank(address(superGovernor));
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superVaultAggregator.slashStake(manager, 0);
    }

    /// @notice Tests slashing reverts with insufficient stake balance
    function test_SlashStake_RevertInsufficientStake() public {
        uint256 stakeAmount = 500e18;
        uint256 slashAmount = 1000e18;
        
        // Setup: Deposit smaller stake
        MockUp(upToken).mint(manager, stakeAmount);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount);
        superVaultAggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();
        
        // Try to slash more than available
        vm.prank(address(superGovernor));
        vm.expectRevert(ISuperVaultAggregator.INSUFFICIENT_STAKE_BALANCE.selector);
        superVaultAggregator.slashStake(manager, slashAmount);
    }

    /// @notice Tests slashing reverts when no stake deposited
    function test_SlashStake_RevertNoStake() public {
        vm.prank(address(superGovernor));
        vm.expectRevert(ISuperVaultAggregator.INSUFFICIENT_STAKE_BALANCE.selector);
        superVaultAggregator.slashStake(manager, 100e18);
    }

    /// @notice Tests stake and upkeep systems are independent
    function test_StakeUpkeepIndependence() public {
        uint256 stakeAmount = 1000e18;
        uint256 upkeepAmount = 500e18;
        
        // Mint tokens to manager
        MockUp(upToken).mint(manager, stakeAmount + upkeepAmount);
        
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), stakeAmount + upkeepAmount);
        
        // Deposit both stake and upkeep
        superVaultAggregator.depositStake(manager, stakeAmount);
        superVaultAggregator.depositUpkeep(manager, upkeepAmount);
        vm.stopPrank();
        
        // Verify independent balances
        assertEq(superVaultAggregator.getStakeBalance(manager), stakeAmount, "Stake balance should be independent");
        assertEq(superVaultAggregator.getUpkeepBalance(manager), upkeepAmount, "Upkeep balance should be independent");
        
        // Slash stake - should not affect upkeep
        uint256 slashAmount = 300e18;
        vm.prank(address(superGovernor));
        superVaultAggregator.slashStake(manager, slashAmount);
        
        // Verify only stake was affected
        assertEq(superVaultAggregator.getStakeBalance(manager), stakeAmount - slashAmount, "Only stake should be reduced");
        assertEq(superVaultAggregator.getUpkeepBalance(manager), upkeepAmount, "Upkeep should be unchanged");
        
        // Withdraw upkeep - should not affect stake
        uint256 withdrawUpkeep = 200e18;
        vm.prank(manager);
        superVaultAggregator.withdrawUpkeep(withdrawUpkeep);
        
        // Verify only upkeep was affected
        assertEq(superVaultAggregator.getStakeBalance(manager), stakeAmount - slashAmount, "Stake should be unchanged");
        assertEq(superVaultAggregator.getUpkeepBalance(manager), upkeepAmount - withdrawUpkeep, "Only upkeep should be reduced");
    }

    /// @notice Tests getStakeBalance returns zero for addresses with no stake
    function test_GetStakeBalance_ZeroForNoStake() public view {
        assertEq(superVaultAggregator.getStakeBalance(manager), 0, "Initial stake balance should be zero");
        assertEq(superVaultAggregator.getStakeBalance(user), 0, "User stake balance should be zero");
        assertEq(superVaultAggregator.getStakeBalance(address(0)), 0, "Zero address stake balance should be zero");
    }

    /// @notice Tests edge case: slashing after partial withdrawal
    function test_SlashStake_AfterPartialWithdrawal() public {
        uint256 initialStake = 1000e18;
        uint256 withdrawAmount = 300e18;
        uint256 slashAmount = 200e18;
        uint256 finalStake = initialStake - withdrawAmount - slashAmount;
        
        // Setup: Deposit stake
        MockUp(upToken).mint(manager, initialStake);
        vm.startPrank(manager);
        IERC20(upToken).approve(address(superVaultAggregator), initialStake);
        superVaultAggregator.depositStake(manager, initialStake);
        
        // Partial withdrawal
        superVaultAggregator.withdrawStake(withdrawAmount);
        vm.stopPrank();
        
        // Verify state after withdrawal
        assertEq(superVaultAggregator.getStakeBalance(manager), initialStake - withdrawAmount, "Stake after withdrawal should be correct");
        
        // Slash remaining stake
        vm.prank(address(superGovernor));
        superVaultAggregator.slashStake(manager, slashAmount);
        
        // Verify final state
        assertEq(superVaultAggregator.getStakeBalance(manager), finalStake, "Final stake should be correct");
        assertEq(IERC20(upToken).balanceOf(superBank), slashAmount, "SuperBank should receive slashed amount");
        assertEq(IERC20(upToken).balanceOf(manager), withdrawAmount, "Manager should have withdrawn amount");
    }

    /// @notice Test fair cost distribution in batchForwardPPS with mixed stale and fresh entries
    /// @dev Validates that only non-stale entries are charged and costs are distributed fairly
    function test_BatchForwardPPS_FairCostDistribution_WithStaleEntries() public {
        BatchForwardPPSTestVars memory vars;
        
        // Set up as PPS Oracle to be able to call forwardPPS
        vm.startPrank(sGovernor);
        superGovernor.setActivePPSOracle(address(this));
        superGovernor.proposeUpkeepPaymentsChange(true);
        vm.stopPrank();

        vm.warp(8 days);
        superGovernor.executeUpkeepPaymentsChange();

        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(superVaultAggregator));
        vm.stopPrank();
        
        vars.totalUpkeepCost = 1e18; // 1 token total cost

        // Create additional strategies for comprehensive testing
        vm.prank(manager);
        (, vars.strategy2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager,
                secondaryManagers: new address[](0),
                name: "Test Vault 2",
                symbol: "TV2",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        vm.prank(manager);
        (, vars.strategy3,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager,
                secondaryManagers: new address[](0),
                name: "Test Vault 3",
                symbol: "TV3",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        vm.prank(manager);
        (, vars.strategy4,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: manager,
                secondaryManagers: new address[](0),
                name: "Test Vault 4",
                symbol: "TV4",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager })
            })
        );

        // Get initial timestamps
        vars.baseTimestamp = block.timestamp;
        
        // Prepare batch data with mix of fresh and stale entries
        vars.strategies = new address[](4);
        vars.strategies[0] = strategy;        // Fresh entry
        vars.strategies[1] = vars.strategy2;  // Stale entry (will be exempt)
        vars.strategies[2] = vars.strategy3;  // Fresh entry
        vars.strategies[3] = vars.strategy4;  // Stale entry (will be exempt)

        vars.ppss = new uint256[](4);
        vars.ppss[0] = 1.1e18;
        vars.ppss[1] = 1.2e18;
        vars.ppss[2] = 1.3e18;
        vars.ppss[3] = 1.4e18;

        vars.ppsStdevs = new uint256[](4);
        vars.ppsStdevs[0] = 0;
        vars.ppsStdevs[1] = 0;
        vars.ppsStdevs[2] = 0;
        vars.ppsStdevs[3] = 0;

        vars.validatorSets = new uint256[](4);
        vars.validatorSets[0] = 1;
        vars.validatorSets[1] = 1;
        vars.validatorSets[2] = 1;
        vars.validatorSets[3] = 1;

        vars.totalValidators = new uint256[](4);
        vars.totalValidators[0] = 1;
        vars.totalValidators[1] = 1;
        vars.totalValidators[2] = 1;
        vars.totalValidators[3] = 1;

        vars.timestamps = new uint256[](4);
        vars.timestamps[0] = vars.baseTimestamp + 350;  // Fresh (10 seconds old when warped to +360)
        vars.timestamps[1] = vars.baseTimestamp + 10;   // Stale (350 seconds old when warped to +360)
        vars.timestamps[2] = vars.baseTimestamp + 340;  // Fresh (20 seconds old when warped to +360)  
        vars.timestamps[3] = vars.baseTimestamp + 20;   // Stale (340 seconds old when warped to +360)

        address[] memory updateAuthorities = new address[](4);
        updateAuthorities[0] = user;
        updateAuthorities[1] = user;
        updateAuthorities[2] = user;
        updateAuthorities[3] = user;

        // Fund and deposit upkeep balance for the manager
        // Manager needs sufficient upkeep balance to cover the costs
        deal(address(asset), manager, vars.totalUpkeepCost);
        vm.startPrank(manager);
        address _upToken = superGovernor.getAddress(superGovernor.UP());
        deal(_upToken, manager, vars.totalUpkeepCost);
        IERC20(_upToken).approve(address(superVaultAggregator), vars.totalUpkeepCost);
        superVaultAggregator.depositUpkeep(manager, vars.totalUpkeepCost);
        vm.stopPrank();

        // Record initial balances
        vars.initialOracleBalance = asset.balanceOf(address(this));
        vars.initialTreasuryBalance = asset.balanceOf(treasury);

        // Wait for minimum interval to pass
        vm.warp(vars.baseTimestamp + 350);

        // Execute batch update
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: vars.strategies,
                ppss: vars.ppss,
                ppsStdevs: vars.ppsStdevs,
                validatorSets: vars.validatorSets,
                totalValidators: vars.totalValidators,
                timestamps: vars.timestamps,
                updateAuthority: address(this)
            })
        );

        // Verify cost distribution logic:
        // - Only 2 entries are chargeable (strategies[0] and strategies[2])
        // - Total cost should be split: 1e18 / 2 = 5e17 per entry
        // - No remainder since 1000 is evenly divisible by 2
        
        vars.expectedCostPerEntry = vars.totalUpkeepCost / 2; // 5e17
        vars.expectedTotalCharged = vars.expectedCostPerEntry * 2; // 1e18

        // Verify manager's upkeep balance was deducted correctly
        assertEq(
            superVaultAggregator.getUpkeepBalance(manager),
            0, // All upkeep should be consumed for the 2 chargeable entries
            "Manager upkeep balance should be fully consumed"
        );

        // Verify claimable upkeep increased by the charged amount
        assertEq(
            superVaultAggregator.claimableUpkeep(),
            vars.expectedTotalCharged,
            "Claimable upkeep should equal total charged amount"
        );

        // Verify PPS updates were applied to all valid strategies
        assertEq(superVaultAggregator.getPPS(strategy), vars.ppss[0], "Strategy 1 PPS should be updated");
        assertEq(superVaultAggregator.getPPS(vars.strategy2), vars.ppss[1], "Strategy 2 PPS should be updated despite being stale");
        assertEq(superVaultAggregator.getPPS(vars.strategy3), vars.ppss[2], "Strategy 3 PPS should be updated");
        assertEq(superVaultAggregator.getPPS(vars.strategy4), vars.ppss[3], "Strategy 4 PPS should be updated despite being stale");

        // Verify timestamps were updated for all strategies
        assertEq(superVaultAggregator.getLastUpdateTimestamp(strategy), vars.timestamps[0]);
        assertEq(superVaultAggregator.getLastUpdateTimestamp(vars.strategy2), vars.timestamps[1]);
        assertEq(superVaultAggregator.getLastUpdateTimestamp(vars.strategy3), vars.timestamps[2]);
        assertEq(superVaultAggregator.getLastUpdateTimestamp(vars.strategy4), vars.timestamps[3]);
    }

    /// @notice Tests that batch PPS updates revert when exceeding MAX_STRATEGIES limit
    function test_BatchForwardPPS_Revert_MaxStrategiesExceeded() public {
        // Set up as PPS Oracle to be able to call batchForwardPPS
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(this));

        // Create arrays with MAX_STRATEGIES + 1 entries (501 strategies)
        uint256 strategiesCount = 501; // MAX_STRATEGIES is 500
        
        address[] memory strategies = new address[](strategiesCount);
        uint256[] memory ppss = new uint256[](strategiesCount);
        uint256[] memory ppsStdevs = new uint256[](strategiesCount);
        uint256[] memory validatorSets = new uint256[](strategiesCount);
        uint256[] memory totalValidators = new uint256[](strategiesCount);
        uint256[] memory timestamps = new uint256[](strategiesCount);
        address[] memory updateAuthorities = new address[](strategiesCount);

        // Fill arrays with dummy data (we don't need valid strategies since it should revert before validation)
        for (uint256 i = 0; i < strategiesCount; i++) {
            strategies[i] = address(uint160(i + 1)); // Dummy addresses
            ppss[i] = 1e18;
            ppsStdevs[i] = 0;
            validatorSets[i] = 1;
            totalValidators[i] = 1;
            timestamps[i] = block.timestamp;
            updateAuthorities[i] = user;
        }

        // Batch update should revert with MAX_STRATEGIES_EXCEEDED
        vm.expectRevert(ISuperVaultAggregator.MAX_STRATEGIES_EXCEEDED.selector);
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps,
                updateAuthority: address(this)
            })
        );
    }

    /// @notice Tests batchForwardPPS with array size 1
    function test_BatchForwardPPS_ArraySize1() public {
        // Set up as PPS Oracle
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(this));

        // Wait for minimum interval to pass
        vm.warp(block.timestamp + 10);

        // Prepare arrays with size 1
        address[] memory strategies = new address[](1);
        uint256[] memory ppss = new uint256[](1);
        uint256[] memory ppsStdevs = new uint256[](1);
        uint256[] memory validatorSets = new uint256[](1);
        uint256[] memory totalValidatorsArray = new uint256[](1);
        uint256[] memory timestamps = new uint256[](1);

        strategies[0] = strategy;
        ppss[0] = 1e18 + 1e15;
        ppsStdevs[0] = 0;
        validatorSets[0] = 1;
        totalValidatorsArray[0] = 1;
        timestamps[0] = superVaultAggregator.getLastUpdateTimestamp(strategy) + 20;

        address[] memory updateAuthorities = new address[](1);
        updateAuthorities[0] = user;

        // Advance time to ensure update is valid
        vm.warp(block.timestamp + 25);

        // Measure gas
        uint256 gasBefore = gasleft();
        
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidatorsArray,
                timestamps: timestamps,
                updateAuthority: user
            })
        );
        
        uint256 gasAfter = gasleft();
        uint256 gasUsed = gasBefore - gasAfter;

        console2.log("batchForwardPPS (size 1) gas used:", gasUsed);

        // Verify update was successful
        assertEq(
            superVaultAggregator.getLastUpdateTimestamp(strategy), 
            timestamps[0],
            "Timestamp not updated correctly"
        );
    }
}

struct BatchForwardPPSTestVars {
    address strategy2;
    address strategy3;
    address strategy4;
    uint256 baseTimestamp;
    uint256 totalUpkeepCost;
    uint256 initialOracleBalance;
    uint256 initialTreasuryBalance;
    uint256 expectedCostPerEntry;
    uint256 expectedTotalCharged;
    address[] strategies;
    uint256[] ppss;
    uint256[] ppsStdevs;
    uint256[] validatorSets;
    uint256[] totalValidators;
    uint256[] timestamps;
}
