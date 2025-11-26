// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor, FeeType } from "../../src/interfaces/ISuperGovernor.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";

contract SuperGovernorTest is PeripheryHelpers {
    SuperVaultAggregator internal aggregator;
    SuperGovernor internal superGovernor;
    MockUp internal upToken;

    // Roles & Addresses
    address internal sGovernor;
    address internal governor;
    address internal oracleManager;
    address internal treasury;
    address internal user;
    address internal hook1;
    address internal hook2;
    address internal fulfillHook1;
    address internal fulfillHook2;
    address internal validator1;
    address internal validator2;
    address internal ppsOracle1;
    address internal ppsOracle2;
    address internal superVaultAggregator;
    address internal strategy1;
    address internal newManager;
    address internal manager;
    address internal superBank;

    // Role Hashes
    bytes32 internal constant SUPER_GOVERNOR_ROLE = keccak256("SUPER_GOVERNOR_ROLE");
    bytes32 internal constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 internal constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");
    bytes32 internal constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");
    bytes32 internal constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    // Keys
    bytes32 internal constant TEST_KEY = keccak256("TEST_KEY");

    // Constants
    uint256 internal constant TIMELOCK = 7 days;
    uint256 internal constant BPS_MAX = 10_000;

    MockERC20 internal asset;

    /// @notice Sets up the test environment before each test case.
    function setUp() public {
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        oracleManager = _deployAccount(0x4, "OracleManager");
        user = _deployAccount(0x5, "User");
        hook1 = _deployAccount(0x6, "Hook1");
        hook2 = _deployAccount(0x7, "Hook2");
        fulfillHook1 = _deployAccount(0x8, "FulfillHook1");
        fulfillHook2 = _deployAccount(0x9, "FulfillHook2");
        validator1 = _deployAccount(0xA, "Validator1");
        validator2 = _deployAccount(0xB, "Validator2");
        ppsOracle1 = _deployAccount(0xC, "PPSOracle1");
        ppsOracle2 = _deployAccount(0xD, "PPSOracle2");
        newManager = _deployAccount(0xE, "NewManager");
        manager = _deployAccount(0xF, "Manager");
        upToken = new MockUp(address(this));
        superBank = _deployAccount(0x12, "SuperBank");

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, oracleManager, governor, treasury);

        // Deploy implementation contracts first
        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator =
            address(new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl));
        aggregator = SuperVaultAggregator(superVaultAggregator);

        (, address strategy,) = ISuperVaultAggregator(superVaultAggregator)
            .createVault(
                ISuperVaultAggregator.VaultCreationParams({
                    asset: address(asset),
                    mainManager: address(this),
                    secondaryManagers: new address[](0),
                    name: "SUP",
                    symbol: "SUP",
                    minUpdateInterval: 5,
                    maxStaleness: 300,
                    feeConfig: ISuperVaultStrategy.FeeConfig({
                        performanceFeeBps: 1000, managementFeeBps: 0, recipient: address(this)
                    })
                })
            );
        strategy1 = strategy;

        vm.startPrank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, address(aggregator));
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.UP(), address(upToken));
        superGovernor.grantRole(superGovernor.GUARDIAN_ROLE(), governor);
        vm.stopPrank();
    }

    // =============================================================
    // Constructor Tests
    // =============================================================

    /// @notice Tests if the constructor correctly sets initial roles and treasury.
    function test_constructor_InitialState() public view {
        assertTrue(superGovernor.hasRole(SUPER_GOVERNOR_ROLE, sGovernor), "Admin should have SUPER_GOVERNOR_ROLE");
        assertTrue(superGovernor.hasRole(GOVERNOR_ROLE, governor), "Governor should have GOVERNOR_ROLE");
        assertTrue(superGovernor.hasRole(BANK_MANAGER_ROLE, governor), "Governor should have BANK_MANAGER_ROLE");
        assertEq(superGovernor.getAddress(superGovernor.TREASURY()), treasury, "Treasury address mismatch");
    }

    /// @notice Tests constructor revert on zero address superGovernor.
    function test_constructor_Revert_ZeroAdmin() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        new SuperGovernor(address(0), governor, governor, oracleManager, governor, treasury);
    }

    /// @notice Tests constructor revert on zero address governor.
    function test_constructor_Revert_ZeroGovernor() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);

        new SuperGovernor(sGovernor, address(0), governor, oracleManager, governor, treasury);
    }

    /// @notice Tests constructor revert on zero address treasury.
    function test_constructor_Revert_ZeroTreasury() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);

        new SuperGovernor(sGovernor, governor, governor, oracleManager, governor, address(0));
    }

    /// @notice Tests constructor revert on zero address oracleManager.
    function test_constructor_Revert_ZeroOracleManager() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);

        new SuperGovernor(sGovernor, governor, governor, address(0), governor, treasury);
    }

    // =============================================================
    // ERC-165 Interface Detection Tests
    // =============================================================

    /// @notice Tests supportsInterface returns true for ISuperGovernor interface
    /// @dev Covers SuperGovernor.sol:849 - ISuperGovernor interface detection
    function test_SupportsInterface_ISuperGovernor() public view {
        bytes4 interfaceId = type(ISuperGovernor).interfaceId;
        assertTrue(superGovernor.supportsInterface(interfaceId), "Should support ISuperGovernor interface");
    }

    /// @notice Tests supportsInterface returns true for IAccessControl interface
    /// @dev Verifies inherited AccessControl interface is supported
    function test_SupportsInterface_IAccessControl() public view {
        bytes4 interfaceId = type(IAccessControl).interfaceId;
        assertTrue(superGovernor.supportsInterface(interfaceId), "Should support IAccessControl interface");
    }

    /// @notice Tests supportsInterface returns true for IERC165 interface
    /// @dev Verifies ERC-165 interface itself is supported
    function test_SupportsInterface_IERC165() public view {
        bytes4 interfaceId = type(IERC165).interfaceId;
        assertTrue(superGovernor.supportsInterface(interfaceId), "Should support IERC165 interface");
    }

    /// @notice Tests supportsInterface returns false for unsupported interface
    /// @dev Tests with a random interface ID that should not be supported
    function test_SupportsInterface_UnsupportedInterface() public view {
        bytes4 randomInterfaceId = bytes4(keccak256("RandomInterface()"));
        assertFalse(
            superGovernor.supportsInterface(randomInterfaceId), "Should not support random interface"
        );
    }

    /// @notice Tests supportsInterface returns false for zero interface ID
    /// @dev Tests edge case with bytes4(0)
    function test_SupportsInterface_ZeroInterfaceId() public view {
        bytes4 zeroInterfaceId = bytes4(0);
        assertFalse(superGovernor.supportsInterface(zeroInterfaceId), "Should not support zero interface ID");
    }

    /// @notice Tests supportsInterface returns false for invalid interface ID
    /// @dev Tests with 0xffffffff which is an invalid/reserved interface ID in ERC-165
    function test_SupportsInterface_InvalidInterfaceId() public view {
        bytes4 invalidInterfaceId = 0xffffffff;
        assertFalse(
            superGovernor.supportsInterface(invalidInterfaceId), "Should not support invalid interface ID"
        );
    }

    /// @notice Tests supportsInterface with multiple known interfaces
    /// @dev Verifies all supported interfaces return true
    function test_SupportsInterface_MultipleKnownInterfaces() public view {
        // Test ISuperGovernor
        assertTrue(
            superGovernor.supportsInterface(type(ISuperGovernor).interfaceId),
            "Should support ISuperGovernor"
        );

        // Test IAccessControl
        assertTrue(
            superGovernor.supportsInterface(type(IAccessControl).interfaceId),
            "Should support IAccessControl"
        );

        // Test IERC165
        assertTrue(
            superGovernor.supportsInterface(type(IERC165).interfaceId),
            "Should support IERC165"
        );
    }

    // =============================================================
    // Role Tests
    // =============================================================

    /// @notice Tests that only SUPER_GOVERNOR_ROLE can call SUPER_GOVERNOR_ROLE functions.
    function test_Role_SuperGovernorOnlyFunctions() public {
        vm.prank(governor);
        // Expected role hash for SUPER_GOVERNOR_ROLE
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, governor, SUPER_GOVERNOR_ROLE
            )
        );
        superGovernor.setAddress(TEST_KEY, user);

        vm.prank(sGovernor);
        superGovernor.setAddress(TEST_KEY, user); // Should succeed
    }

    /// @notice Tests that only GOVERNOR_ROLE can call GOVERNOR_ROLE functions.
    function test_Role_GovernorOnlyFunctions() public {
        // Setup validator config
        address[] memory validators = new address[](1);
        validators[0] = validator1;
        bytes[] memory validatorPublicKeys = new bytes[](1);
        validatorPublicKeys[0] = "";

        vm.prank(sGovernor); // Admin has SUPER_GOVERNOR_ROLE but not GOVERNOR_ROLE by default
        // Expected role hash for GOVERNOR_ROLE
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, "");

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, ""); // Should succeed
    }

    // =============================================================
    // Address Registry Tests
    // =============================================================

    /// @notice Tests setting and getting an address.
    function test_AddressRegistry_SetAndGetAddress() public {
        vm.prank(sGovernor);
        vm.expectEmit(true, true, true, true);
        emit ISuperGovernor.AddressSet(TEST_KEY, address(0), user);
        superGovernor.setAddress(TEST_KEY, user);

        assertEq(superGovernor.getAddress(TEST_KEY), user, "Address mismatch");
    }

    /// @notice Tests setting an address with SUPER_GOVERNOR_ROLE.
    function test_AddressRegistry_SetAddress_AccessControl() public {
        // Test with governor role (should fail)
        vm.prank(governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, governor, SUPER_GOVERNOR_ROLE
            )
        );
        superGovernor.setAddress(TEST_KEY, user);

        // Test with superGovernor role (should succeed)
        vm.prank(sGovernor);
        superGovernor.setAddress(TEST_KEY, user);
        assertEq(superGovernor.getAddress(TEST_KEY), user);
    }

    /// @notice Tests reverting when setting address to address(0).
    function test_AddressRegistry_SetAddress_Revert_ZeroAddress() public {
        vm.prank(sGovernor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.setAddress(TEST_KEY, address(0));
    }

    /// @notice Tests reverting when getting a non-existent address.
    function test_AddressRegistry_GetAddress_Revert_NotFound() public {
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.getAddress(keccak256("NON_EXISTENT"));
    }

    // =============================================================
    // Getters Tests
    // =============================================================
    function test_RoleGetters() public view {
        assertEq(superGovernor.SUPER_GOVERNOR_ROLE(), keccak256("SUPER_GOVERNOR_ROLE"));
        assertEq(superGovernor.GOVERNOR_ROLE(), keccak256("GOVERNOR_ROLE"));
        assertEq(superGovernor.ORACLE_MANAGER_ROLE(), keccak256("ORACLE_MANAGER_ROLE"));
        assertEq(superGovernor.GUARDIAN_ROLE(), keccak256("GUARDIAN_ROLE"));
    }

    function test_IsGuardian() public view {
        assertTrue(superGovernor.isGuardian(governor), "Governor should be a guardian");
        assertFalse(superGovernor.isGuardian(address(this)), "This contract should not be a guardian");
    }

    // =============================================================
    // Manager Takeover Tests
    // =============================================================

    /// @notice Tests changing a manager for a strategy
    function test_ManagerTakeover_ChangeManager() public {
        // Set up SuperVaultAggregator address in registry
        vm.prank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, superVaultAggregator);

        // Test with governor role
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(strategy1, newManager);

        assertEq(ISuperVaultAggregator(superVaultAggregator).getMainManager(strategy1), newManager);
    }

    /// @notice Tests freezing manager takeovers
    function test_ManagerTakeover_Freeze() public {
        vm.prank(sGovernor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ManagerTakeoversFrozen();
        superGovernor.freezeManagerTakeover();

        assertTrue(superGovernor.isManagerTakeoverFrozen(), "Manager takeovers should be frozen");
    }

    /// @notice Tests reverting when trying to freeze already frozen manager takeovers
    function test_ManagerTakeover_Revert_AlreadyFrozen() public {
        // First freeze
        vm.prank(sGovernor);
        superGovernor.freezeManagerTakeover();

        // Try to freeze again
        vm.prank(sGovernor);
        vm.expectRevert(ISuperGovernor.MANAGER_TAKEOVERS_FROZEN.selector);
        superGovernor.freezeManagerTakeover();
    }

    /// @notice Tests reverting when trying to change manager after freeze
    function test_ManagerTakeover_Revert_FrozenChangeAttempt() public {
        // Set up SuperVaultAggregator address in registry
        vm.prank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, superVaultAggregator);

        // Freeze manager takeovers
        vm.prank(sGovernor);
        superGovernor.freezeManagerTakeover();

        // Try to change manager after freeze
        vm.prank(sGovernor);
        vm.expectRevert(ISuperGovernor.MANAGER_TAKEOVERS_FROZEN.selector);
        superGovernor.changePrimaryManager(strategy1, newManager);
    }

    /// @notice Tests changePrimaryManager reverts when aggregator is not set
    /// @dev Covers SuperGovernor.sol:190 - if (aggregator == address(0)) revert CONTRACT_NOT_FOUND()
    function test_ChangePrimaryManager_RevertsWhenAggregatorNotSet() public {
        // Deploy a fresh SuperGovernor instance without setting the aggregator
        address freshSGovernor = _deployAccount(0xFF, "FreshSuperGovernor");
        SuperGovernor freshGovernor = new SuperGovernor(freshSGovernor, governor, governor, governor, governor, treasury);

        // Don't set the aggregator in registry - it should be address(0)
        vm.prank(freshSGovernor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        freshGovernor.changePrimaryManager(strategy1, newManager);
    }

    /// @notice Tests changePrimaryManager reverts when called by unauthorized user
    /// @dev Covers SuperGovernor.sol:185 - onlyRole(_SUPER_GOVERNOR_ROLE) modifier
    function test_ChangePrimaryManager_RevertsOnUnauthorized() public {
        // Set up SuperVaultAggregator address in registry
        vm.prank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, superVaultAggregator);

        // Try to change manager as governor (has GOVERNOR_ROLE but not SUPER_GOVERNOR_ROLE)
        vm.prank(governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, governor, SUPER_GOVERNOR_ROLE
            )
        );
        superGovernor.changePrimaryManager(strategy1, newManager);

        // Try to change manager as regular user (no roles)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, SUPER_GOVERNOR_ROLE
            )
        );
        superGovernor.changePrimaryManager(strategy1, newManager);
    }

    /// @notice Tests changePrimaryManager success path with all checks passing
    /// @dev Comprehensive test covering all conditions: not frozen, aggregator set, authorized caller
    function test_ChangePrimaryManager_SuccessWithAllConditions() public {
        // Verify initial manager
        address initialManager = ISuperVaultAggregator(superVaultAggregator).getMainManager(strategy1);
        assertEq(initialManager, address(this), "Initial manager should be this contract");

        // Set up SuperVaultAggregator address in registry
        vm.prank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, superVaultAggregator);

        // Verify manager takeovers are not frozen
        assertFalse(superGovernor.isManagerTakeoverFrozen(), "Manager takeovers should not be frozen initially");

        // Change manager as sGovernor (has SUPER_GOVERNOR_ROLE)
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(strategy1, newManager);

        // Verify the manager was changed
        address updatedManager = ISuperVaultAggregator(superVaultAggregator).getMainManager(strategy1);
        assertEq(updatedManager, newManager, "Manager should be updated to newManager");
    }

    /// @notice Tests changePrimaryManager with zero address as new manager
    /// @dev Tests edge case with zero address (should be caught by aggregator, not SuperGovernor)
    function test_ChangePrimaryManager_WithZeroAddressManager() public {
        // Set up SuperVaultAggregator address in registry
        vm.prank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, superVaultAggregator);

        // Try to change manager to zero address
        // This should revert in the aggregator's changePrimaryManager, not in SuperGovernor
        vm.prank(sGovernor);
        vm.expectRevert(); // Aggregator will revert with its own error
        superGovernor.changePrimaryManager(strategy1, address(0));
    }

    // =============================================================
    // Hook Management Tests
    // =============================================================

    /// @notice Tests registering a hook
    function test_HookManagement_RegisterHook() public {
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.HookApproved(hook1);
        superGovernor.registerHook(hook1);

        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should be registered");
    }

    /// @notice Tests reverting when registering a hook with zero address
    function test_HookManagement_Revert_ZeroAddress() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.registerHook(address(0));
    }

    /// @notice Tests that registering an already registered hook doesn't emit events
    function test_HookManagement_AlreadyRegistered_NoEvent() public {
        // Register hook first
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Verify it's registered
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should be registered");

        // Try to register again - should not revert
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Hook should still be registered
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should still be registered");
    }

    /// @notice Tests that registering an already registered fulfill requests hook doesn't emit events
    function test_HookManagement_FulfillHookAlreadyRegistered_NoEvent() public {
        // Register fulfill hook first
        vm.prank(governor);
        superGovernor.registerHook(fulfillHook1);

        // Verify it's registered in both sets
        assertTrue(superGovernor.isHookRegistered(fulfillHook1), "Hook should be registered");

        // Try to register again - should not revert
        vm.prank(governor);
        superGovernor.registerHook(fulfillHook1);

        // Hook should still be registered in both sets
        assertTrue(superGovernor.isHookRegistered(fulfillHook1), "Hook should still be registered");
    }

    /// @notice Tests unregistering a hook
    function test_HookManagement_UnregisterHook() public {
        // Register hook first
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Unregister hook
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.HookRemoved(hook1);
        superGovernor.unregisterHook(hook1);

        assertFalse(superGovernor.isHookRegistered(hook1), "Hook should be unregistered");
    }

    /// @notice Tests the fix for the dangerous hook registration behavior where sets can get out of sync
    function test_HookManagement_FixedInvariantMaintenance() public {
        // Test case 1: Register a hook in regular set, then try to register it as fulfill request hook
        // This should work now and not revert
        vm.prank(governor);
        superGovernor.registerHook(hook1);
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should be in regular set");

        // Now register the same hook again - should not revert
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Should still be registered
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should still be in regular set");

        // Test case 2: Unregister should remove from both sets
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.HookRemoved(hook1);
        superGovernor.unregisterHook(hook1);

        // Should be removed from both sets
        assertFalse(superGovernor.isHookRegistered(hook1), "Hook should be removed from regular set");

        // Test case 3: Unregistering a hook that's only in regular set should work
        vm.prank(governor);
        superGovernor.registerHook(hook2);

        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.HookRemoved(hook2);
        superGovernor.unregisterHook(hook2);

        assertFalse(superGovernor.isHookRegistered(hook2), "Hook should be removed");
    }

    /// @notice Tests getting the list of registered hooks
    function test_HookManagement_GetRegisteredHooks() public {
        // Register two hooks
        vm.startPrank(governor);
        superGovernor.registerHook(hook1);
        superGovernor.registerHook(hook2);
        vm.stopPrank();

        address[] memory hooks = superGovernor.getRegisteredHooks();
        assertEq(hooks.length, 2, "Should have 2 registered hooks");
        assertTrue(hooks[0] == hook1 || hooks[1] == hook1, "hook1 should be in the list");
        assertTrue(hooks[0] == hook2 || hooks[1] == hook2, "hook2 should be in the list");
    }

    function test_ChangeHooksRootUpdateTimelock() public {
        vm.prank(sGovernor);
        superGovernor.changeHooksRootUpdateTimelock(100);
        uint256 timelock = aggregator.getHooksRootUpdateTimelock();
        assertEq(timelock, 100, "Timelock should be 100");
    }

    /// @notice Tests changeHooksRootUpdateTimelock reverts when aggregator is not set
    /// @dev Covers SuperGovernor.sol:210-211 - if (aggregator == address(0)) revert CONTRACT_NOT_FOUND()
    function test_ChangeHooksRootUpdateTimelock_RevertsWhenAggregatorNotSet() public {
        // Deploy a fresh SuperGovernor instance without setting the aggregator
        address freshSGovernor = _deployAccount(0xFE, "FreshSuperGovernor2");
        SuperGovernor freshGovernor = new SuperGovernor(freshSGovernor, governor, governor, governor, governor, treasury);

        vm.prank(freshSGovernor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        freshGovernor.changeHooksRootUpdateTimelock(100);
    }

    /// @notice Tests changeHooksRootUpdateTimelock reverts when called by unauthorized user
    /// @dev Covers SuperGovernor.sol:209 - onlyRole(_SUPER_GOVERNOR_ROLE) modifier
    function test_ChangeHooksRootUpdateTimelock_RevertsOnUnauthorized() public {
        // Try with governor role (not super governor)
        vm.prank(governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, governor, SUPER_GOVERNOR_ROLE
            )
        );
        superGovernor.changeHooksRootUpdateTimelock(100);

        // Try with regular user (no roles)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, SUPER_GOVERNOR_ROLE)
        );
        superGovernor.changeHooksRootUpdateTimelock(100);
    }

    /// @notice Tests changeHooksRootUpdateTimelock allows zero timelock (emergency use)
    /// @dev Verifies that zero timelock is intentionally allowed for SUPER_GOVERNOR_ROLE
    function test_ChangeHooksRootUpdateTimelock_AllowsZeroTimelock() public {
        vm.prank(sGovernor);
        superGovernor.changeHooksRootUpdateTimelock(0);
        uint256 timelock = aggregator.getHooksRootUpdateTimelock();
        assertEq(timelock, 0, "Timelock should be 0 for emergency situations");
    }

    /// @notice Tests proposeGlobalHooksRoot success path
    /// @dev Covers SuperGovernor.sol:220-225
    function test_ProposeGlobalHooksRoot_Success() public {
        bytes32 newRoot = keccak256("new global hooks root");

        vm.prank(governor);
        superGovernor.proposeGlobalHooksRoot(newRoot);

        (bytes32 proposedRoot,) = aggregator.getProposedGlobalHooksRoot();
        assertEq(proposedRoot, newRoot, "Proposed root should match");
    }

    /// @notice Tests proposeGlobalHooksRoot reverts when aggregator is not set
    /// @dev Covers SuperGovernor.sol:221-222 - if (aggregator == address(0)) revert CONTRACT_NOT_FOUND()
    function test_ProposeGlobalHooksRoot_RevertsWhenAggregatorNotSet() public {
        // Deploy a fresh SuperGovernor instance without setting the aggregator
        // The constructor automatically grants GOVERNOR_ROLE to the 2nd parameter (governor)
        address freshSGovernor = _deployAccount(0xFD, "FreshSuperGovernor3");
        address freshGovernor2 = _deployAccount(0xFC, "FreshGovernor");
        SuperGovernor freshGovernor = new SuperGovernor(freshSGovernor, freshGovernor2, freshGovernor2, freshGovernor2, freshGovernor2, treasury);

        bytes32 newRoot = keccak256("new global hooks root");

        vm.prank(freshGovernor2);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        freshGovernor.proposeGlobalHooksRoot(newRoot);
    }

    /// @notice Tests proposeGlobalHooksRoot reverts when called by unauthorized user
    /// @dev Covers SuperGovernor.sol:220 - onlyRole(_GOVERNOR_ROLE) modifier
    function test_ProposeGlobalHooksRoot_RevertsOnUnauthorized() public {
        bytes32 newRoot = keccak256("new global hooks root");

        // Try with regular user (no roles)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.proposeGlobalHooksRoot(newRoot);

        // Try with sGovernor who has SUPER_GOVERNOR_ROLE but not GOVERNOR_ROLE
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.proposeGlobalHooksRoot(newRoot);
    }

    function test_SetGlobalHooksVetoStatus() public {
        vm.prank(governor);
        superGovernor.setGlobalHooksRootVetoStatus(true);
        bool vetoed = aggregator.isGlobalHooksRootVetoed();
        assertTrue(vetoed, "Global hooks should be vetoed");
    }

    /// @notice Tests setGlobalHooksRootVetoStatus reverts when aggregator is not set
    /// @dev Covers SuperGovernor.sol:229-230 - if (aggregator == address(0)) revert CONTRACT_NOT_FOUND()
    function test_SetGlobalHooksVetoStatus_RevertsWhenAggregatorNotSet() public {
        // Deploy a fresh SuperGovernor instance without setting the aggregator
        // Pass governor as 2nd param, and grant GUARDIAN_ROLE to governor after
        address freshSGovernor = _deployAccount(0xFB, "FreshSuperGovernor4");
        SuperGovernor freshGovernor = new SuperGovernor(freshSGovernor, governor, governor, governor, governor, treasury);

        // Get GUARDIAN_ROLE before prank to avoid consuming the prank
        bytes32 guardianRole = freshGovernor.GUARDIAN_ROLE();

        // Grant GUARDIAN_ROLE to governor (who already has GOVERNOR_ROLE from constructor)
        vm.prank(freshSGovernor);
        freshGovernor.grantRole(guardianRole, governor);

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        freshGovernor.setGlobalHooksRootVetoStatus(true);
    }

    /// @notice Tests setGlobalHooksRootVetoStatus reverts when called by unauthorized user
    /// @dev Covers SuperGovernor.sol:228 - onlyRole(_GUARDIAN_ROLE) modifier
    function test_SetGlobalHooksVetoStatus_RevertsOnUnauthorized() public {
        bytes32 guardianRole = superGovernor.GUARDIAN_ROLE();

        // Try with regular user (no roles)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, guardianRole)
        );
        superGovernor.setGlobalHooksRootVetoStatus(true);

        // Try with sGovernor who has SUPER_GOVERNOR_ROLE but not GUARDIAN_ROLE
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, guardianRole)
        );
        superGovernor.setGlobalHooksRootVetoStatus(true);
    }

    function test_SetStrategyHooksVetoStatus() public {
        vm.prank(governor);
        superGovernor.setStrategyHooksRootVetoStatus(address(strategy1), true);
        bool vetoed = aggregator.isStrategyHooksRootVetoed(address(strategy1));
        assertTrue(vetoed, "Strategy hooks should be vetoed");
    }

    /// @notice Tests setStrategyHooksRootVetoStatus reverts when strategy is zero address
    /// @dev Covers SuperGovernor.sol:237 - if (strategy == address(0)) revert INVALID_ADDRESS()
    function test_SetStrategyHooksVetoStatus_RevertsOnZeroStrategy() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.setStrategyHooksRootVetoStatus(address(0), true);
    }

    /// @notice Tests setStrategyHooksRootVetoStatus reverts when aggregator is not set
    /// @dev Covers SuperGovernor.sol:239-240 - if (aggregator == address(0)) revert CONTRACT_NOT_FOUND()
    function test_SetStrategyHooksVetoStatus_RevertsWhenAggregatorNotSet() public {
        // Deploy a fresh SuperGovernor instance without setting the aggregator
        // Pass governor as 2nd param, and grant GUARDIAN_ROLE to governor after
        address freshSGovernor = _deployAccount(0xF9, "FreshSuperGovernor5");
        SuperGovernor freshGovernor = new SuperGovernor(freshSGovernor, governor, governor, governor, governor, treasury);

        // Get GUARDIAN_ROLE before prank to avoid consuming the prank
        bytes32 guardianRole = freshGovernor.GUARDIAN_ROLE();

        // Grant GUARDIAN_ROLE to governor (who already has GOVERNOR_ROLE from constructor)
        vm.prank(freshSGovernor);
        freshGovernor.grantRole(guardianRole, governor);

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        freshGovernor.setStrategyHooksRootVetoStatus(strategy1, true);
    }

    /// @notice Tests setStrategyHooksRootVetoStatus reverts when called by unauthorized user
    /// @dev Covers SuperGovernor.sol:236 - onlyRole(_GUARDIAN_ROLE) modifier
    function test_SetStrategyHooksVetoStatus_RevertsOnUnauthorized() public {
        bytes32 guardianRole = superGovernor.GUARDIAN_ROLE();

        // Try with regular user (no roles)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, guardianRole)
        );
        superGovernor.setStrategyHooksRootVetoStatus(strategy1, true);

        // Try with sGovernor who has SUPER_GOVERNOR_ROLE but not GUARDIAN_ROLE
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, guardianRole)
        );
        superGovernor.setStrategyHooksRootVetoStatus(strategy1, true);
    }

    /// @notice Tests executeUpkeepClaim passes aggregator check when set
    /// @dev Covers SuperGovernor.sol:513 - aggregator check passes when aggregator is set
    /// Note: May fail with INSUFFICIENT_UPKEEP if no upkeep balance exists, but that validates
    /// the aggregator check passed (since CONTRACT_NOT_FOUND would occur first)
    function test_ExecuteUpkeepClaim_PassesAggregatorCheck() public {
        uint256 claimAmount = 1000;

        vm.prank(governor);
        // This should pass the aggregator != address(0) check at line 513
        // It may revert with INSUFFICIENT_UPKEEP, which is expected business logic
        try superGovernor.executeUpkeepClaim(claimAmount) {
            // Success - aggregator was set and had sufficient upkeep
        } catch (bytes memory reason) {
            // If it reverts, ensure it's not CONTRACT_NOT_FOUND
            // CONTRACT_NOT_FOUND would indicate line 513 failed
            bytes4 selector = bytes4(reason);
            bytes4 contractNotFound = ISuperGovernor.CONTRACT_NOT_FOUND.selector;
            assertTrue(selector != contractNotFound, "Should not revert with CONTRACT_NOT_FOUND");
        }
    }

    /// @notice Tests executeUpkeepClaim reverts when aggregator is not set
    /// @dev Covers SuperGovernor.sol:513 - if (aggregator == address(0)) revert CONTRACT_NOT_FOUND()
    function test_ExecuteUpkeepClaim_RevertsWhenAggregatorNotSet() public {
        // Deploy a fresh SuperGovernor instance without setting the aggregator
        address freshSGovernor = _deployAccount(0xF7, "FreshSuperGovernor6");
        address freshGovernor2 = _deployAccount(0xF6, "FreshGovernor2");
        SuperGovernor freshGovernor = new SuperGovernor(freshSGovernor, freshGovernor2, freshGovernor2, freshGovernor2, freshGovernor2, treasury);

        uint256 claimAmount = 1000;

        vm.prank(freshGovernor2);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        freshGovernor.executeUpkeepClaim(claimAmount);
    }

    /// @notice Tests executeUpkeepClaim reverts when called by unauthorized user
    /// @dev Covers SuperGovernor.sol:511 - onlyRole(_GOVERNOR_ROLE) modifier
    function test_ExecuteUpkeepClaim_RevertsOnUnauthorized() public {
        uint256 claimAmount = 1000;

        // Try with regular user (no roles)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.executeUpkeepClaim(claimAmount);

        // Try with sGovernor who has SUPER_GOVERNOR_ROLE but not GOVERNOR_ROLE alone
        // Note: sGovernor might have GOVERNOR_ROLE depending on setup, so this may need adjustment
    }

    /// @notice Tests executeUpkeepClaim with zero amount
    /// @dev Edge case test for zero claim amount
    function test_ExecuteUpkeepClaim_WithZeroAmount() public {
        vm.prank(governor);
        superGovernor.executeUpkeepClaim(0);
        // Should succeed - zero claims are allowed
    }

    /// @notice Tests executeUpkeepClaim successfully delegates to aggregator
    /// @dev Covers SuperGovernor.sol:511-516 success path with aggregator delegation
    function test_ExecuteUpkeepClaim_Success() public {
        // Setup mock aggregator
        MockSuperVaultAggregator mockAggregator = new MockSuperVaultAggregator();
        bytes32 aggregatorKey = superGovernor.SUPER_VAULT_AGGREGATOR();
        vm.prank(sGovernor);
        superGovernor.setAddress(aggregatorKey, address(mockAggregator));

        // Execute upkeep claim
        uint256 claimAmount = 1000;
        vm.prank(governor);
        superGovernor.executeUpkeepClaim(claimAmount);

        // Verify aggregator received the call
        assertTrue(mockAggregator.claimUpkeepCalled(), "Aggregator should have received the claim call");
        assertEq(mockAggregator.lastClaimAmount(), claimAmount, "Claim amount should match");
    }

    /// @notice Tests executeUpkeepClaim with zero amount delegates correctly
    /// @dev Verifies zero amount is properly passed to aggregator
    function test_ExecuteUpkeepClaim_ZeroAmountDelegation() public {
        // Setup mock aggregator
        MockSuperVaultAggregator mockAggregator = new MockSuperVaultAggregator();
        bytes32 aggregatorKey = superGovernor.SUPER_VAULT_AGGREGATOR();
        vm.prank(sGovernor);
        superGovernor.setAddress(aggregatorKey, address(mockAggregator));

        // Execute upkeep claim with zero amount
        vm.prank(governor);
        superGovernor.executeUpkeepClaim(0);

        // Verify aggregator received the call with zero amount
        assertTrue(mockAggregator.claimUpkeepCalled(), "Aggregator should have received the claim call");
        assertEq(mockAggregator.lastClaimAmount(), 0, "Claim amount should be zero");
    }

    /// @notice Tests executeUpkeepClaim with large amount
    /// @dev Verifies large amounts are properly passed to aggregator
    function test_ExecuteUpkeepClaim_LargeAmount() public {
        // Setup mock aggregator
        MockSuperVaultAggregator mockAggregator = new MockSuperVaultAggregator();
        bytes32 aggregatorKey = superGovernor.SUPER_VAULT_AGGREGATOR();
        vm.prank(sGovernor);
        superGovernor.setAddress(aggregatorKey, address(mockAggregator));

        // Execute upkeep claim with large amount
        uint256 largeAmount = type(uint128).max;
        vm.prank(governor);
        superGovernor.executeUpkeepClaim(largeAmount);

        // Verify aggregator received the call with correct amount
        assertTrue(mockAggregator.claimUpkeepCalled(), "Aggregator should have received the claim call");
        assertEq(mockAggregator.lastClaimAmount(), largeAmount, "Claim amount should match large value");
    }

    // =============================================================
    // Validator Management Tests
    // =============================================================

    /// @notice Tests setting validator configuration
    function test_ValidatorManagement_SetValidatorConfig() public {
        // Setup validator config
        address[] memory validators = new address[](1);
        validators[0] = validator1;
        bytes[] memory validatorPublicKeys = new bytes[](1);
        validatorPublicKeys[0] = "";

        vm.prank(governor);
        vm.expectEmit(true, false, false, true);
        emit ISuperGovernor.ValidatorConfigSet(1, validators, validatorPublicKeys, 1, "");
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, "");

        assertTrue(superGovernor.isValidator(validator1), "Validator should be added");
        address[] memory validatorsList = superGovernor.getValidators();
        assertEq(validatorsList.length, 1, "Should have 1 validator");
        assertEq(validatorsList[0], validator1, "Validator in list should match");
    }

    /// @notice Tests getting validators by index using getValidatorAt
    function test_ValidatorManagement_GetValidatorAt() public {
        // Setup validators config with two validators
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;
        bytes[] memory validatorPublicKeys = new bytes[](2);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 2, "");
        vm.stopPrank();

        // Verify count
        uint256 count = superGovernor.getValidatorsCount();
        assertEq(count, 2, "Should have 2 validators");

        // Get validators by index
        address validatorAt0 = superGovernor.getValidatorAt(0);
        address validatorAt1 = superGovernor.getValidatorAt(1);

        // Verify both validators are accessible
        assertTrue(
            validatorAt0 == validator1 || validatorAt0 == validator2, "Index 0 should be validator1 or validator2"
        );
        assertTrue(
            validatorAt1 == validator1 || validatorAt1 == validator2, "Index 1 should be validator1 or validator2"
        );
        assertTrue(validatorAt0 != validatorAt1, "Validators at different indices should be different");

        // Verify we can access each validator
        assertTrue(superGovernor.isValidator(validatorAt0), "Validator at index 0 should be registered");
        assertTrue(superGovernor.isValidator(validatorAt1), "Validator at index 1 should be registered");

        // Test that out-of-bounds index reverts
        vm.expectRevert();
        superGovernor.getValidatorAt(2);

        // Test that large out-of-bounds index also reverts
        vm.expectRevert();
        superGovernor.getValidatorAt(999);
    }

    /// @notice Tests reverting when setting validator config with zero address
    function test_ValidatorManagement_Revert_ZeroAddress() public {
        address[] memory validators = new address[](1);
        validators[0] = address(0);
        bytes[] memory validatorPublicKeys = new bytes[](1);
        validatorPublicKeys[0] = "";

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, "");
    }

    /// @notice Tests reverting when adding duplicate validators in config
    function test_ValidatorManagement_Revert_DuplicateValidators() public {
        // Try to add duplicate validators in the same config
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator1; // duplicate
        bytes[] memory validatorPublicKeys = new bytes[](2);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.VALIDATOR_ALREADY_REGISTERED.selector);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 2, "");
    }

    /// @notice Tests removing validators by updating config
    function test_ValidatorManagement_RemoveValidatorByConfig() public {
        // Add validator first
        address[] memory validators = new address[](1);
        validators[0] = validator1;
        bytes[] memory validatorPublicKeys = new bytes[](1);
        validatorPublicKeys[0] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, "");
        assertTrue(superGovernor.isValidator(validator1), "Validator should be added");

        // Remove validator by setting empty config
        address[] memory emptyValidators = new address[](1);
        emptyValidators[0] = validator2; // Different validator
        bytes[] memory emptyKeys = new bytes[](1);
        emptyKeys[0] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(2, emptyValidators, emptyKeys, 1, "");

        assertFalse(superGovernor.isValidator(validator1), "Validator1 should be removed");
        assertTrue(superGovernor.isValidator(validator2), "Validator2 should be added");
    }

    /// @notice Tests updating validator config with multiple validators
    function test_ValidatorManagement_UpdateConfigWithMultiple() public {
        // Set initial config with two validators
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;
        bytes[] memory validatorPublicKeys = new bytes[](2);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";

        vm.startPrank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 2, "");
        vm.stopPrank();

        // Update config to remove the first validator
        address[] memory newValidators = new address[](1);
        newValidators[0] = validator2;
        bytes[] memory newKeys = new bytes[](1);
        newKeys[0] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(2, newValidators, newKeys, 1, "");

        assertFalse(superGovernor.isValidator(validator1), "validator1 should be removed");
        assertTrue(superGovernor.isValidator(validator2), "validator2 should still be registered");

        address[] memory validatorsList = superGovernor.getValidators();
        assertEq(validatorsList.length, 1, "Should have 1 validator remaining");
        assertEq(validatorsList[0], validator2, "Remaining validator should be validator2");
    }

    /// @notice Tests reverting when trying to set empty validator array
    function test_ValidatorManagement_Revert_EmptyValidatorArray() public {
        address[] memory emptyValidators = new address[](0);
        bytes[] memory emptyKeys = new bytes[](0);

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.EMPTY_VALIDATOR_ARRAY.selector);
        superGovernor.setValidatorConfig(1, emptyValidators, emptyKeys, 0, "");
    }

    /// @notice Tests reverting when validator and public key array lengths mismatch
    function test_ValidatorManagement_Revert_ArrayLengthMismatch() public {
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;

        bytes[] memory validatorPublicKeys = new bytes[](1); // Length mismatch
        validatorPublicKeys[0] = "";

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.ARRAY_LENGTH_MISMATCH.selector);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, "");
    }

    /// @notice Tests reverting when quorum exceeds validator count
    function test_ValidatorManagement_Revert_QuorumExceedsValidators() public {
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;

        bytes[] memory validatorPublicKeys = new bytes[](2);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_QUORUM.selector);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 3, ""); // quorum > validators
    }

    /// @notice Tests edge case where quorum equals validator count
    function test_ValidatorManagement_QuorumEqualsValidators() public {
        address[] memory validators = new address[](3);
        validators[0] = validator1;
        validators[1] = validator2;
        validators[2] = address(0x123);

        bytes[] memory validatorPublicKeys = new bytes[](3);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";
        validatorPublicKeys[2] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 3, ""); // quorum == validators

        assertEq(superGovernor.getPPSOracleQuorum(), 3, "Quorum should equal validator count");
        assertEq(superGovernor.getValidatorsCount(), 3, "Should have 3 validators");
    }

    /// @notice Tests edge case with quorum of 1
    function test_ValidatorManagement_MinimumQuorum() public {
        address[] memory validators = new address[](3);
        validators[0] = validator1;
        validators[1] = validator2;
        validators[2] = address(0x123);

        bytes[] memory validatorPublicKeys = new bytes[](3);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";
        validatorPublicKeys[2] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, ""); // minimum quorum

        assertEq(superGovernor.getPPSOracleQuorum(), 1, "Quorum should be 1");
    }

    /// @notice Tests version tracking across multiple config updates
    function test_ValidatorManagement_VersionTracking() public {
        address[] memory validators = new address[](1);
        validators[0] = validator1;
        bytes[] memory validatorPublicKeys = new bytes[](1);
        validatorPublicKeys[0] = "";

        // Set version 1
        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, "");

        (uint256 version1,,,) = superGovernor.getValidatorConfig();
        assertEq(version1, 1, "Version should be 1");

        // Update to version 5
        validators[0] = validator2;
        vm.prank(governor);
        superGovernor.setValidatorConfig(5, validators, validatorPublicKeys, 1, "");

        (uint256 version2,,,) = superGovernor.getValidatorConfig();
        assertEq(version2, 5, "Version should be 5");
    }

    /// @notice Tests public keys storage and retrieval
    function test_ValidatorManagement_PublicKeysStorage() public {
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;

        bytes[] memory validatorPublicKeys = new bytes[](2);
        validatorPublicKeys[0] = hex"abcdef";
        validatorPublicKeys[1] = hex"123456";

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 2, "");

        (,, bytes[] memory storedKeys,) = superGovernor.getValidatorConfig();
        assertEq(storedKeys.length, 2, "Should have 2 public keys");
        assertEq(storedKeys[0], validatorPublicKeys[0], "First public key should match");
        assertEq(storedKeys[1], validatorPublicKeys[1], "Second public key should match");
    }

    /// @notice Tests offchain config parameter emission (not stored)
    function test_ValidatorManagement_OffchainConfigEmission() public {
        address[] memory validators = new address[](1);
        validators[0] = validator1;
        bytes[] memory validatorPublicKeys = new bytes[](1);
        validatorPublicKeys[0] = "";
        bytes memory offchainConfig = hex"deadbeef";

        vm.prank(governor);
        vm.expectEmit(true, false, false, true);
        emit ISuperGovernor.ValidatorConfigSet(1, validators, validatorPublicKeys, 1, offchainConfig);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 1, offchainConfig);

        // Offchain config is not stored, only emitted
        // We verify it was emitted via the expectEmit above
    }

    /// @notice Tests that old validators are properly cleared when setting new config
    function test_ValidatorManagement_ValidatorClearing() public {
        // Set initial config with 3 validators
        address[] memory validators1 = new address[](3);
        validators1[0] = validator1;
        validators1[1] = validator2;
        validators1[2] = address(0x123);
        bytes[] memory validatorPublicKeys1 = new bytes[](3);
        validatorPublicKeys1[0] = "";
        validatorPublicKeys1[1] = "";
        validatorPublicKeys1[2] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators1, validatorPublicKeys1, 2, "");

        assertEq(superGovernor.getValidatorsCount(), 3, "Should have 3 validators");
        assertTrue(superGovernor.isValidator(validator1), "validator1 should be registered");
        assertTrue(superGovernor.isValidator(validator2), "validator2 should be registered");

        // Replace with single validator
        address[] memory validators2 = new address[](1);
        validators2[0] = address(0x456);
        bytes[] memory validatorPublicKeys2 = new bytes[](1);
        validatorPublicKeys2[0] = "";

        vm.prank(governor);
        superGovernor.setValidatorConfig(2, validators2, validatorPublicKeys2, 1, "");

        // Verify old validators are cleared
        assertEq(superGovernor.getValidatorsCount(), 1, "Should have 1 validator");
        assertFalse(superGovernor.isValidator(validator1), "validator1 should be cleared");
        assertFalse(superGovernor.isValidator(validator2), "validator2 should be cleared");
        assertFalse(superGovernor.isValidator(address(0x123)), "validator3 should be cleared");
        assertTrue(superGovernor.isValidator(address(0x456)), "New validator should be registered");
    }

    /// @notice Tests setting validator config with a large validator set
    function test_ValidatorManagement_LargeValidatorSet() public {
        uint256 validatorCount = 50;
        address[] memory validators = new address[](validatorCount);
        bytes[] memory validatorPublicKeys = new bytes[](validatorCount);

        for (uint256 i = 0; i < validatorCount; i++) {
            validators[i] = address(uint160(1000 + i));
            validatorPublicKeys[i] = "";
        }

        vm.prank(governor);
        superGovernor.setValidatorConfig(1, validators, validatorPublicKeys, 25, "");

        assertEq(superGovernor.getValidatorsCount(), validatorCount, "Should have 50 validators");
        assertEq(superGovernor.getPPSOracleQuorum(), 25, "Quorum should be 25");

        // Verify a few validators are registered
        assertTrue(superGovernor.isValidator(validators[0]), "First validator should be registered");
        assertTrue(superGovernor.isValidator(validators[25]), "Middle validator should be registered");
        assertTrue(superGovernor.isValidator(validators[49]), "Last validator should be registered");
    }

    /// @notice Tests that ValidatorConfigSet event is emitted with quorum included
    function test_ValidatorManagement_EventEmissionWithQuorum() public {
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;
        bytes[] memory validatorPublicKeys = new bytes[](2);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";
        uint256 quorum = 2;
        uint256 version = 1;

        vm.prank(governor);
        // Verify that ValidatorConfigSet event includes quorum parameter
        vm.expectEmit(true, false, false, true);
        emit ISuperGovernor.ValidatorConfigSet(version, validators, validatorPublicKeys, quorum, "");
        superGovernor.setValidatorConfig(version, validators, validatorPublicKeys, quorum, "");

        // Verify state was updated correctly
        assertEq(superGovernor.getPPSOracleQuorum(), quorum, "Quorum should be updated");
        assertEq(superGovernor.getValidatorsCount(), 2, "Should have 2 validators");
    }

    // =============================================================
    // Emergency Price Tests
    // =============================================================
    function test_SetEmergencyPrice() public {
        uint256 emergencyPrice = 1e18;

        MockSuperOracleForStaleness oracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        // Set the oracle in the registry
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(oracle));

        vm.prank(governor);
        superGovernor.setEmergencyPrice(address(asset), emergencyPrice);

        assertEq(oracle.getEmergencyPrice(address(asset)), emergencyPrice, "Emergency price should be set");
    }

    /// @notice Tests setEmergencyPrice reverts when oracle is not set in registry
    /// @dev Covers SuperGovernor.sol:333 - if (oracle == address(0)) revert CONTRACT_NOT_FOUND()
    function test_SetEmergencyPrice_Revert_OracleNotSet() public {
        address token = makeAddr("token");
        uint256 price = 1e18;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.setEmergencyPrice(token, price);
    }

    /// @notice Tests batchSetEmergencyPrices reverts when oracle is not set in registry
    /// @dev Covers SuperGovernor.sol:347 - if (oracle == address(0)) revert CONTRACT_NOT_FOUND()
    function test_BatchSetEmergencyPrices_Revert_OracleNotSet() public {
        address[] memory tokens = new address[](2);
        tokens[0] = makeAddr("token1");
        tokens[1] = makeAddr("token2");

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e18;
        prices[1] = 2e18;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.batchSetEmergencyPrices(tokens, prices);
    }

    /// @notice Tests batchSetEmergencyPrices successfully delegates to oracle
    /// @dev Covers SuperGovernor.sol:339-350 success path with oracle delegation
    function test_BatchSetEmergencyPrices_Success() public {
        // Setup mock oracle
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();
        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Prepare test data
        address[] memory tokens = new address[](2);
        tokens[0] = makeAddr("token1");
        tokens[1] = makeAddr("token2");

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e18;
        prices[1] = 2e18;

        // Call batchSetEmergencyPrices
        vm.prank(governor);
        superGovernor.batchSetEmergencyPrices(tokens, prices);

        // Verify oracle received the call
        assertTrue(mockOracle.batchSetEmergencyPriceCalled(), "Oracle should have received the batch call");
        assertEq(mockOracle.getLastBatchTokensLength(), 2, "Should have 2 tokens");
        assertEq(mockOracle.getLastBatchToken(0), tokens[0], "First token should match");
        assertEq(mockOracle.getLastBatchToken(1), tokens[1], "Second token should match");
        assertEq(mockOracle.getLastBatchPrice(0), prices[0], "First price should match");
        assertEq(mockOracle.getLastBatchPrice(1), prices[1], "Second price should match");
    }

    /// @notice Tests batchSetEmergencyPrices access control
    /// @dev Covers SuperGovernor.sol:345 - onlyRole(_GOVERNOR_ROLE)
    function test_BatchSetEmergencyPrices_AccessControl() public {
        // Setup mock oracle
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();
        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Prepare test data
        address[] memory tokens = new address[](2);
        tokens[0] = makeAddr("token1");
        tokens[1] = makeAddr("token2");

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e18;
        prices[1] = 2e18;

        // Try to call from unauthorized address
        address unauthorized = makeAddr("unauthorized");
        vm.prank(unauthorized);
        vm.expectRevert();
        superGovernor.batchSetEmergencyPrices(tokens, prices);

        // Verify oracle did not receive the call
        assertFalse(mockOracle.batchSetEmergencyPriceCalled(), "Oracle should not have received the call");
    }

    /// @notice Tests batchSetEmergencyPrices with empty arrays delegates to oracle
    /// @dev Covers SuperGovernor.sol:339-350 with edge case - oracle will handle validation
    function test_BatchSetEmergencyPrices_EmptyArrays() public {
        // Setup mock oracle
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();
        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Prepare empty arrays
        address[] memory tokens = new address[](0);
        uint256[] memory prices = new uint256[](0);

        // Call should succeed at SuperGovernor level and delegate to oracle
        vm.prank(governor);
        superGovernor.batchSetEmergencyPrices(tokens, prices);

        // Verify oracle received the call (even with empty arrays)
        assertTrue(mockOracle.batchSetEmergencyPriceCalled(), "Oracle should have received the call");
        assertEq(mockOracle.getLastBatchTokensLength(), 0, "Should have 0 tokens");
    }

    // =============================================================
    // PPS Oracle Management Tests
    // =============================================================

    /// @notice Tests proposing a new active PPS Oracle
    function test_PPSOracleManagement_ProposeActivePPSOracle() public {
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(sGovernor);
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.ActivePPSOracleProposed(ppsOracle1, expectedTime);
        superGovernor.proposeActivePPSOracle(ppsOracle1);

        (address proposedOracle, uint256 effectiveTime) = superGovernor.getProposedActivePPSOracle();
        assertEq(proposedOracle, ppsOracle1, "Proposed PPS Oracle address mismatch");
        assertEq(effectiveTime, expectedTime, "Effective time mismatch");
    }

    function test_SetActivePPSOracle_Revert_MustUseTimelock() public {
        vm.startPrank(sGovernor);
        superGovernor.setActivePPSOracle(ppsOracle1);
        vm.expectRevert(ISuperGovernor.MUST_USE_TIMELOCK_FOR_CHANGE.selector);
        superGovernor.setActivePPSOracle(ppsOracle1);
        vm.stopPrank();
    }

    /// @notice Tests reverting when proposing a PPS Oracle with zero address
    function test_PPSOracleManagement_Revert_ProposeZeroAddress() public {
        vm.prank(sGovernor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.proposeActivePPSOracle(address(0));
    }

    /// @notice Tests reverting when setting active PPS Oracle with zero address
    /// @dev Covers SuperGovernor.sol:427 - if (oracle == address(0)) revert INVALID_ADDRESS()
    function test_PPSOracleManagement_Revert_SetActiveZeroAddress() public {
        vm.prank(sGovernor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.setActivePPSOracle(address(0));
    }

    /// @notice Tests executing a PPS Oracle change
    function test_PPSOracleManagement_ExecuteActivePPSOracleChange() public {
        // Propose a new PPS Oracle
        vm.prank(sGovernor);
        superGovernor.proposeActivePPSOracle(ppsOracle1);

        // Warp to after timelock
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the change
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ActivePPSOracleChanged(address(0), ppsOracle1);
        superGovernor.executeActivePPSOracleChange();

        assertEq(superGovernor.getActivePPSOracle(), ppsOracle1, "Active PPS Oracle should be updated");
        assertTrue(superGovernor.isActivePPSOracle(ppsOracle1), "isActivePPSOracle should return true");

        // Check that proposal data is reset
        (address proposedOracle,) = superGovernor.getProposedActivePPSOracle();
        assertEq(proposedOracle, address(0), "Proposed PPS Oracle should be reset");
    }

    /// @notice Tests reverting when executing without a proposal
    function test_PPSOracleManagement_Revert_ExecuteNoProposal() public {
        vm.expectRevert(ISuperGovernor.NO_PROPOSED_PPS_ORACLE.selector);
        superGovernor.executeActivePPSOracleChange();
    }

    /// @notice Tests reverting when executing before timelock expiry
    function test_PPSOracleManagement_Revert_ExecuteBeforeTimelock() public {
        // Propose a new PPS Oracle
        vm.prank(sGovernor);
        superGovernor.proposeActivePPSOracle(ppsOracle1);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeActivePPSOracleChange();
    }

    /// @notice Tests setting the validator configuration including quorum
    function test_ValidatorManagement_SetValidatorConfigWithQuorum() public {
        // Setup validators
        address[] memory validators = new address[](3);
        validators[0] = address(0x1);
        validators[1] = address(0x2);
        validators[2] = address(0x3);

        bytes[] memory validatorPublicKeys = new bytes[](3);
        validatorPublicKeys[0] = "";
        validatorPublicKeys[1] = "";
        validatorPublicKeys[2] = "";

        uint256 newQuorum = 2;
        uint256 version = 1;

        // Test invalid quorum (0)
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_QUORUM.selector);
        superGovernor.setValidatorConfig(
            version,
            validators,
            validatorPublicKeys,
            0, // invalid quorum
            ""
        );

        // Test valid configuration
        vm.prank(governor);
        vm.expectEmit(true, false, false, true);
        emit ISuperGovernor.ValidatorConfigSet(version, validators, validatorPublicKeys, newQuorum, "");
        superGovernor.setValidatorConfig(version, validators, validatorPublicKeys, newQuorum, "");

        assertEq(superGovernor.getPPSOracleQuorum(), newQuorum, "PPS Oracle quorum mismatch");
    }

    // =============================================================
    // Gas Info Management Tests
    // =============================================================

    /// @notice Tests setting gas info successfully
    function test_GasInfo_SetGasInfo_Success() public {
        address oracle = makeAddr("testOracle");
        uint256 gasIncreasePerBatch = 1000;

        vm.prank(governor); // GAS_MANAGER_ROLE is held by governor in setUp
        superGovernor.setGasInfo(oracle, gasIncreasePerBatch);

        assertEq(superGovernor.getGasInfo(oracle), gasIncreasePerBatch, "Gas per entry should match");
    }

    /// @notice Tests reverting when setting gas info with zero address oracle
    /// @dev Covers SuperGovernor.sol:523 - if (oracle == address(0)) revert INVALID_ADDRESS()
    function test_GasInfo_SetGasInfo_RevertsOnZeroOracle() public {
        uint256 gasIncreasePerBatch = 1000;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.setGasInfo(address(0), gasIncreasePerBatch);
    }

    /// @notice Tests reverting when setting gas info with zero gas increase
    /// @dev Covers SuperGovernor.sol:524 - if (gasIncreasePerEntryBatch == 0) revert INVALID_GAS_INFO()
    function test_GasInfo_SetGasInfo_RevertsOnZeroGas() public {
        address oracle = makeAddr("testOracle");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_GAS_INFO.selector);
        superGovernor.setGasInfo(oracle, 0);
    }

    /// @notice Tests setGasInfo access control
    /// @dev Covers SuperGovernor.sol:522 - onlyRole(_GAS_MANAGER_ROLE)
    function test_GasInfo_SetGasInfo_AccessControl() public {
        address oracle = makeAddr("testOracle");
        uint256 gasIncreasePerBatch = 1000;
        bytes32 gasManagerRole = superGovernor.GAS_MANAGER_ROLE();

        // Try with unauthorized user (no roles)
        address unauthorized = makeAddr("unauthorized");
        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, gasManagerRole
            )
        );
        superGovernor.setGasInfo(oracle, gasIncreasePerBatch);

        // Try with sGovernor (has SUPER_GOVERNOR_ROLE but not GAS_MANAGER_ROLE)
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, gasManagerRole)
        );
        superGovernor.setGasInfo(oracle, gasIncreasePerBatch);

        // Verify governor (who has GAS_MANAGER_ROLE) can call successfully
        vm.prank(governor);
        superGovernor.setGasInfo(oracle, gasIncreasePerBatch);
        assertEq(superGovernor.getGasInfo(oracle), gasIncreasePerBatch, "Gas info should be set");
    }

    /// @notice Tests setGasInfo emits correct event
    /// @dev Covers SuperGovernor.sol:527 - emit GasInfoSet(oracle, gasIncreasePerEntryBatch)
    function test_GasInfo_SetGasInfo_EmitsEvent() public {
        address oracle = makeAddr("testOracle");
        uint256 gasIncreasePerBatch = 1000;

        vm.prank(governor);
        vm.expectEmit(true, true, false, true);
        emit ISuperGovernor.GasInfoSet(oracle, gasIncreasePerBatch);
        superGovernor.setGasInfo(oracle, gasIncreasePerBatch);
    }

    /// @notice Tests updating gas info multiple times for the same oracle
    /// @dev Verifies that gas info can be updated and the latest value is stored
    function test_GasInfo_SetGasInfo_MultipleUpdates() public {
        address oracle = makeAddr("testOracle");
        uint256 firstGasValue = 1000;
        uint256 secondGasValue = 2000;
        uint256 thirdGasValue = 5000;

        // First update
        vm.prank(governor);
        superGovernor.setGasInfo(oracle, firstGasValue);
        assertEq(superGovernor.getGasInfo(oracle), firstGasValue, "First gas value should be set");

        // Second update
        vm.prank(governor);
        superGovernor.setGasInfo(oracle, secondGasValue);
        assertEq(superGovernor.getGasInfo(oracle), secondGasValue, "Second gas value should override first");

        // Third update
        vm.prank(governor);
        superGovernor.setGasInfo(oracle, thirdGasValue);
        assertEq(superGovernor.getGasInfo(oracle), thirdGasValue, "Third gas value should override second");
    }

    /// @notice Tests setGasInfo with large gas values
    /// @dev Verifies that large uint256 values are properly stored
    function test_GasInfo_SetGasInfo_LargeValue() public {
        address oracle = makeAddr("testOracle");
        uint256 largeGasValue = type(uint256).max;

        vm.prank(governor);
        superGovernor.setGasInfo(oracle, largeGasValue);
        assertEq(superGovernor.getGasInfo(oracle), largeGasValue, "Large gas value should be stored correctly");
    }

    /// @notice Tests setGasInfo with multiple different oracles
    /// @dev Verifies that gas info is stored independently for each oracle
    function test_GasInfo_SetGasInfo_MultipleOracles() public {
        address oracle1 = makeAddr("oracle1");
        address oracle2 = makeAddr("oracle2");
        address oracle3 = makeAddr("oracle3");
        uint256 gasValue1 = 1000;
        uint256 gasValue2 = 2000;
        uint256 gasValue3 = 3000;

        // Set gas info for each oracle
        vm.startPrank(governor);
        superGovernor.setGasInfo(oracle1, gasValue1);
        superGovernor.setGasInfo(oracle2, gasValue2);
        superGovernor.setGasInfo(oracle3, gasValue3);
        vm.stopPrank();

        // Verify each oracle has correct gas info
        assertEq(superGovernor.getGasInfo(oracle1), gasValue1, "Oracle1 gas value should match");
        assertEq(superGovernor.getGasInfo(oracle2), gasValue2, "Oracle2 gas value should match");
        assertEq(superGovernor.getGasInfo(oracle3), gasValue3, "Oracle3 gas value should match");
    }

    // =============================================================
    // Fee Management Tests
    // =============================================================

    /// @notice Tests proposing a new fee
    function test_FeeManagement_ProposeFee() public {
        FeeType feeType = FeeType.REVENUE_SHARE;
        uint256 feeValue = 50; // 0.5% in basis points
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(sGovernor);
        vm.expectEmit(true, true, true, true);
        emit ISuperGovernor.FeeProposed(feeType, feeValue, expectedTime);
        superGovernor.proposeFee(feeType, feeValue);

        // Since we can't directly check the proposed fee value, we'll test it through execution
    }

    /// @notice Tests reverting when proposing an invalid fee value
    function test_FeeManagement_Revert_InvalidFeeValue() public {
        FeeType feeType = FeeType.REVENUE_SHARE;
        uint256 invalidFeeValue = BPS_MAX + 1; // Greater than max

        vm.prank(sGovernor);
        vm.expectRevert(ISuperGovernor.INVALID_FEE_VALUE.selector);
        superGovernor.proposeFee(feeType, invalidFeeValue);
    }

    /// @notice Tests executing a fee update
    function test_FeeManagement_ExecuteFeeUpdate() public {
        FeeType feeType = FeeType.REVENUE_SHARE;
        uint256 feeValue = 50; // 0.5% in basis points

        // Propose new fee
        vm.prank(sGovernor);
        superGovernor.proposeFee(feeType, feeValue);

        // Warp to after timelock
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the fee update
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.FeeUpdated(feeType, feeValue);
        superGovernor.executeFeeUpdate(feeType);

        assertEq(superGovernor.getFee(feeType), feeValue, "Fee value mismatch");
    }

    /// @notice Tests reverting when executing a fee update without a proposal
    function test_FeeManagement_Revert_ExecuteNoProposal() public {
        FeeType feeType = FeeType.REVENUE_SHARE;

        vm.expectRevert(abi.encodeWithSelector(ISuperGovernor.NO_PROPOSED_FEE.selector, feeType));
        superGovernor.executeFeeUpdate(feeType);
    }

    /// @notice Tests reverting when executing a fee update before timelock expiry
    function test_FeeManagement_Revert_ExecuteBeforeTimelock() public {
        FeeType feeType = FeeType.REVENUE_SHARE;
        uint256 feeValue = 50;

        // Propose new fee
        vm.prank(sGovernor);
        superGovernor.proposeFee(feeType, feeValue);

        // Try to execute before timelock expires
        vm.expectRevert(abi.encodeWithSelector(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector));
        superGovernor.executeFeeUpdate(feeType);
    }

    // =============================================================
    // Upkeep Payments Management Tests
    // =============================================================

    /// @notice Tests getProposedUpkeepPaymentsStatus returns initial state
    /// @dev Verifies default values before any proposal is made
    function test_UpkeepPayments_GetProposedStatus_InitialState() public view {
        (bool enabled, uint256 effectiveTime) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabled, false, "Initial enabled should be false");
        assertEq(effectiveTime, 0, "Initial effective time should be 0");
    }

    /// @notice Tests getProposedUpkeepPaymentsStatus after proposing to enable
    /// @dev Verifies getter returns correct values after proposal to enable
    function test_UpkeepPayments_GetProposedStatus_AfterProposeEnable() public {
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(true);

        (bool enabled, uint256 effectiveTime) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabled, true, "Proposed enabled should be true");
        assertEq(effectiveTime, expectedTime, "Effective time should match");
    }

    /// @notice Tests getProposedUpkeepPaymentsStatus after proposing to disable
    /// @dev Verifies getter returns correct values after proposal to disable
    function test_UpkeepPayments_GetProposedStatus_AfterProposeDisable() public {
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(false);

        (bool enabled, uint256 effectiveTime) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabled, false, "Proposed enabled should be false");
        assertEq(effectiveTime, expectedTime, "Effective time should match");
    }

    function test_UpkeepPayments_ExecuteBeforeTimelock() public {
        // Propose change
        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(true);

        // Verify proposal is set
        (bool enabledBefore, uint256 effectiveTimeBefore) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabledBefore, true, "Should be true before execution");
        assertTrue(effectiveTimeBefore > 0, "Effective time should be set");

        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeUpkeepPaymentsChange();
    }

    /// @notice Tests getProposedUpkeepPaymentsStatus after execution
    /// @dev Verifies getter returns reset values after execution
    function test_UpkeepPayments_GetProposedStatus_AfterExecution() public {
        // Propose change
        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(true);

        // Verify proposal is set
        (bool enabledBefore, uint256 effectiveTimeBefore) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabledBefore, true, "Should be true before execution");
        assertTrue(effectiveTimeBefore > 0, "Effective time should be set");

        // Warp past timelock and execute
        vm.warp(block.timestamp + TIMELOCK + 1);
        superGovernor.executeUpkeepPaymentsChange();

        // Verify proposal is reset after execution
        (bool enabledAfter, uint256 effectiveTimeAfter) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabledAfter, false, "Should be reset to false after execution");
        assertEq(effectiveTimeAfter, 0, "Effective time should be reset to 0");
    }

    /// @notice Tests getProposedUpkeepPaymentsStatus with multiple proposals
    /// @dev Verifies latest proposal overrides previous ones
    function test_UpkeepPayments_GetProposedStatus_MultipleProposals() public {
        // First proposal - enable
        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(true);

        (bool enabled1, uint256 effectiveTime1) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabled1, true, "First proposal should be true");
        uint256 expectedTime1 = block.timestamp + TIMELOCK;
        assertEq(effectiveTime1, expectedTime1, "First effective time should match");

        // Warp time forward (but not past timelock)
        vm.warp(block.timestamp + 100);

        // Second proposal - disable
        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(false);

        (bool enabled2, uint256 effectiveTime2) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabled2, false, "Second proposal should override to false");
        uint256 expectedTime2 = block.timestamp + TIMELOCK;
        assertEq(effectiveTime2, expectedTime2, "Second effective time should be updated");
        assertTrue(effectiveTime2 > effectiveTime1, "Second effective time should be later");

        // Warp time forward again
        vm.warp(block.timestamp + 200);

        // Third proposal - enable again
        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(true);

        (bool enabled3, uint256 effectiveTime3) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabled3, true, "Third proposal should override to true");
        uint256 expectedTime3 = block.timestamp + TIMELOCK;
        assertEq(effectiveTime3, expectedTime3, "Third effective time should be updated");
        assertTrue(effectiveTime3 > effectiveTime2, "Third effective time should be latest");
    }

    /// @notice Tests getProposedUpkeepPaymentsStatus with time warp but no execution
    /// @dev Verifies proposal values persist even after timelock expires without execution
    function test_UpkeepPayments_GetProposedStatus_AfterTimelockWithoutExecution() public {
        uint256 expectedTime = block.timestamp + TIMELOCK;

        // Propose change
        vm.prank(sGovernor);
        superGovernor.proposeUpkeepPaymentsChange(true);

        // Warp past timelock
        vm.warp(block.timestamp + TIMELOCK + 1000);

        // Verify proposal still exists (not auto-executed)
        (bool enabled, uint256 effectiveTime) = superGovernor.getProposedUpkeepPaymentsStatus();
        assertEq(enabled, true, "Proposal should still be true");
        assertEq(effectiveTime, expectedTime, "Effective time should remain unchanged");
    }

    // =============================================================
    // Superform Manager Management Tests
    // =============================================================

    /// @notice Tests adding a superform manager
    function test_SuperformManager_AddManager() public {
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.SuperformManagerAdded(newManager);
        superGovernor.addSuperformManager(newManager);

        assertTrue(superGovernor.isSuperformManager(newManager), "Manager should be added");

        address[] memory managers = superGovernor.getAllSuperformManagers();
        assertEq(managers.length, 1, "Should have 1 manager");
        assertEq(managers[0], newManager, "Manager in list should match");
    }

    /// @notice Tests reverting when adding a manager with zero address
    function test_SuperformManager_Revert_ZeroAddress() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.addSuperformManager(address(0));
    }

    /// @notice Tests reverting when adding an already registered manager
    function test_SuperformManager_Revert_AlreadyRegistered() public {
        // Add manager first
        vm.prank(governor);
        superGovernor.addSuperformManager(newManager);

        // Try to add again
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.MANAGER_ALREADY_REGISTERED.selector);
        superGovernor.addSuperformManager(newManager);
    }

    /// @notice Tests removing a superform manager
    function test_SuperformManager_RemoveManager() public {
        // Add manager first
        vm.prank(governor);
        superGovernor.addSuperformManager(newManager);

        // Remove manager
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.SuperformManagerRemoved(newManager);
        superGovernor.removeSuperformManager(newManager);

        assertFalse(superGovernor.isSuperformManager(newManager), "Manager should be removed");

        address[] memory managers = superGovernor.getAllSuperformManagers();
        assertEq(managers.length, 0, "Should have 0 managers");
    }

    /// @notice Tests reverting when removing a non-existent manager
    function test_SuperformManager_Revert_NotRegistered() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.MANAGER_NOT_REGISTERED.selector);
        superGovernor.removeSuperformManager(newManager);
    }

    /// @notice Tests paginated retrieval of managers with various scenarios
    function test_SuperformManager_GetManagersPaginated() public {
        // Create additional manager addresses for testing
        address manager1 = _deployAccount(0x10, "Manager1");
        address manager2 = _deployAccount(0x11, "Manager2");
        address manager3 = _deployAccount(0x12, "Manager3");
        address manager4 = _deployAccount(0x13, "Manager4");
        address manager5 = _deployAccount(0x14, "Manager5");

        // Test with no managers
        (address[] memory chunk, uint256 next) = superGovernor.getManagersPaginated(0, 10);
        assertEq(chunk.length, 0, "Should return empty array when no managers");
        assertEq(next, 0, "Next cursor should be 0 when no managers");

        // Add 5 managers
        vm.startPrank(governor);
        superGovernor.addSuperformManager(manager1);
        superGovernor.addSuperformManager(manager2);
        superGovernor.addSuperformManager(manager3);
        superGovernor.addSuperformManager(manager4);
        superGovernor.addSuperformManager(manager5);
        vm.stopPrank();

        // Test getting first 3 managers
        (chunk, next) = superGovernor.getManagersPaginated(0, 3);
        assertEq(chunk.length, 3, "Should return 3 managers");
        assertEq(next, 3, "Next cursor should be 3");

        // Verify the managers are in the expected order (note: EnumerableSet doesn't guarantee order)
        assertTrue(_addressInArray(chunk, manager1), "manager1 should be in chunk");
        assertTrue(_addressInArray(chunk, manager2), "manager2 should be in chunk");
        assertTrue(_addressInArray(chunk, manager3), "manager3 should be in chunk");

        // Test getting next 2 managers
        (chunk, next) = superGovernor.getManagersPaginated(3, 3);
        assertEq(chunk.length, 2, "Should return 2 remaining managers");
        assertEq(next, 0, "Next cursor should be 0 when reached end");

        assertTrue(_addressInArray(chunk, manager4), "manager4 should be in chunk");
        assertTrue(_addressInArray(chunk, manager5), "manager5 should be in chunk");

        // Test limit larger than remaining items
        (chunk, next) = superGovernor.getManagersPaginated(0, 10);
        assertEq(chunk.length, 5, "Should return all 5 managers when limit > total");
        assertEq(next, 0, "Next cursor should be 0 when all items returned");

        // Test cursor at the end
        (chunk, next) = superGovernor.getManagersPaginated(5, 3);
        assertEq(chunk.length, 0, "Should return empty array when cursor at end");
        assertEq(next, 0, "Next cursor should be 0 when cursor at end");

        // Test getting single manager
        (chunk, next) = superGovernor.getManagersPaginated(1, 1);
        assertEq(chunk.length, 1, "Should return 1 manager");
        assertEq(next, 2, "Next cursor should be 2");

        // Test edge case: cursor beyond end
        (chunk, next) = superGovernor.getManagersPaginated(10, 3);
        assertEq(chunk.length, 0, "Should return empty array when cursor beyond end");
        assertEq(next, 0, "Next cursor should be 0 when cursor beyond end");
    }

    /// @notice Helper function to check if an address is in an array
    function _addressInArray(address[] memory array, address target) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == target) {
                return true;
            }
        }
        return false;
    }

    /// @notice Tests getSuperformManagersCount returns initial count
    /// @dev Verifies count is 0 when no managers are registered
    function test_SuperformManager_GetManagersCount_InitialState() public view {
        uint256 count = superGovernor.getSuperformManagersCount();
        assertEq(count, 0, "Initial count should be 0");
    }

    /// @notice Tests getSuperformManagersCount after adding one manager
    /// @dev Verifies count increments to 1 after adding a manager
    function test_SuperformManager_GetManagersCount_AfterAddOne() public {
        vm.prank(governor);
        superGovernor.addSuperformManager(newManager);

        uint256 count = superGovernor.getSuperformManagersCount();
        assertEq(count, 1, "Count should be 1 after adding one manager");
    }

    /// @notice Tests getSuperformManagersCount after adding multiple managers
    /// @dev Verifies count matches the number of managers added
    function test_SuperformManager_GetManagersCount_AfterAddMultiple() public {
        address manager1 = _deployAccount(0x20, "Manager1");
        address manager2 = _deployAccount(0x21, "Manager2");
        address manager3 = _deployAccount(0x22, "Manager3");
        address manager4 = _deployAccount(0x23, "Manager4");
        address manager5 = _deployAccount(0x24, "Manager5");

        vm.startPrank(governor);
        superGovernor.addSuperformManager(manager1);
        assertEq(superGovernor.getSuperformManagersCount(), 1, "Count should be 1");

        superGovernor.addSuperformManager(manager2);
        assertEq(superGovernor.getSuperformManagersCount(), 2, "Count should be 2");

        superGovernor.addSuperformManager(manager3);
        assertEq(superGovernor.getSuperformManagersCount(), 3, "Count should be 3");

        superGovernor.addSuperformManager(manager4);
        assertEq(superGovernor.getSuperformManagersCount(), 4, "Count should be 4");

        superGovernor.addSuperformManager(manager5);
        assertEq(superGovernor.getSuperformManagersCount(), 5, "Count should be 5");
        vm.stopPrank();
    }

    /// @notice Tests getSuperformManagersCount after removing a manager
    /// @dev Verifies count decrements after removing a manager
    function test_SuperformManager_GetManagersCount_AfterRemove() public {
        address manager1 = _deployAccount(0x30, "Manager1");
        address manager2 = _deployAccount(0x31, "Manager2");

        // Add two managers
        vm.startPrank(governor);
        superGovernor.addSuperformManager(manager1);
        superGovernor.addSuperformManager(manager2);
        assertEq(superGovernor.getSuperformManagersCount(), 2, "Count should be 2 after adding");

        // Remove one manager
        superGovernor.removeSuperformManager(manager1);
        assertEq(superGovernor.getSuperformManagersCount(), 1, "Count should be 1 after removing one");

        // Remove second manager
        superGovernor.removeSuperformManager(manager2);
        assertEq(superGovernor.getSuperformManagersCount(), 0, "Count should be 0 after removing all");
        vm.stopPrank();
    }

    /// @notice Tests getSuperformManagersCount with add/remove operations
    /// @dev Verifies count is accurate through multiple add and remove operations
    function test_SuperformManager_GetManagersCount_MixedOperations() public {
        address manager1 = _deployAccount(0x40, "Manager1");
        address manager2 = _deployAccount(0x41, "Manager2");
        address manager3 = _deployAccount(0x42, "Manager3");

        vm.startPrank(governor);

        // Start with 0
        assertEq(superGovernor.getSuperformManagersCount(), 0, "Initial count should be 0");

        // Add 3 managers
        superGovernor.addSuperformManager(manager1);
        superGovernor.addSuperformManager(manager2);
        superGovernor.addSuperformManager(manager3);
        assertEq(superGovernor.getSuperformManagersCount(), 3, "Count should be 3 after adding");

        // Remove one from the middle
        superGovernor.removeSuperformManager(manager2);
        assertEq(superGovernor.getSuperformManagersCount(), 2, "Count should be 2 after removing one");

        // Add it back
        superGovernor.addSuperformManager(manager2);
        assertEq(superGovernor.getSuperformManagersCount(), 3, "Count should be 3 after re-adding");

        // Remove two
        superGovernor.removeSuperformManager(manager1);
        superGovernor.removeSuperformManager(manager3);
        assertEq(superGovernor.getSuperformManagersCount(), 1, "Count should be 1 after removing two");

        vm.stopPrank();
    }

    /// @notice Tests getSuperformManagersCount matches getAllSuperformManagers length
    /// @dev Verifies consistency between count getter and array getter
    function test_SuperformManager_GetManagersCount_MatchesArrayLength() public {
        address manager1 = _deployAccount(0x50, "Manager1");
        address manager2 = _deployAccount(0x51, "Manager2");
        address manager3 = _deployAccount(0x52, "Manager3");

        vm.startPrank(governor);

        // Initial state
        assertEq(superGovernor.getSuperformManagersCount(), superGovernor.getAllSuperformManagers().length, "Count should match array length initially");

        // After adding managers
        superGovernor.addSuperformManager(manager1);
        assertEq(superGovernor.getSuperformManagersCount(), superGovernor.getAllSuperformManagers().length, "Count should match array length after adding one");

        superGovernor.addSuperformManager(manager2);
        superGovernor.addSuperformManager(manager3);
        assertEq(superGovernor.getSuperformManagersCount(), superGovernor.getAllSuperformManagers().length, "Count should match array length after adding multiple");

        // After removing managers
        superGovernor.removeSuperformManager(manager2);
        assertEq(superGovernor.getSuperformManagersCount(), superGovernor.getAllSuperformManagers().length, "Count should match array length after removing");

        vm.stopPrank();
    }

    // =============================================================
    // SuperBank Hook Merkle Root Tests
    // =============================================================

    /// @notice Tests proposing a new SuperBank hook merkle root
    function test_MerkleRoot_ProposeMerkleRoot() public {
        // First register the hook
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Propose a new merkle root
        bytes32 proposedRoot = keccak256("test_root");
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(governor);
        vm.expectEmit(true, true, true, true);
        emit ISuperGovernor.SuperBankHookMerkleRootProposed(hook1, proposedRoot, expectedTime);
        superGovernor.proposeSuperBankHookMerkleRoot(hook1, proposedRoot);

        (bytes32 actualProposedRoot, uint256 effectiveTime) = superGovernor.getProposedSuperBankHookMerkleRoot(hook1);
        assertEq(actualProposedRoot, proposedRoot, "Proposed merkle root mismatch");
        assertEq(effectiveTime, expectedTime, "Effective time mismatch");
    }

    /// @notice Tests reverting when proposing a merkle root for an unregistered hook
    function test_MerkleRoot_Revert_HookNotApproved() public {
        bytes32 proposedRoot = keccak256("test_root");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.HOOK_NOT_APPROVED.selector);
        superGovernor.proposeSuperBankHookMerkleRoot(hook1, proposedRoot);
    }

    /// @notice Tests executing a merkle root update
    function test_MerkleRoot_ExecuteMerkleRootUpdate() public {
        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Propose a new merkle root
        bytes32 proposedRoot = keccak256("test_root");
        vm.prank(governor);
        superGovernor.proposeSuperBankHookMerkleRoot(hook1, proposedRoot);

        // Warp to after timelock
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the merkle root update
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.SuperBankHookMerkleRootUpdated(hook1, proposedRoot);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook1);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook1), proposedRoot, "Merkle root mismatch");
    }

    function test_MerkleRoot_Revert_NotApproved() public {
        address unapprovedHook = makeAddr("unapprovedHook");

        vm.expectRevert(ISuperGovernor.HOOK_NOT_APPROVED.selector);
        superGovernor.getSuperBankHookMerkleRoot(unapprovedHook);

        vm.expectRevert(ISuperGovernor.HOOK_NOT_APPROVED.selector);
        superGovernor.getProposedSuperBankHookMerkleRoot(unapprovedHook);
    }

    /// @notice Tests reverting when executing a merkle root update for an unregistered hook
    function test_MerkleRoot_Revert_ExecuteHookNotApproved() public {
        vm.expectRevert(ISuperGovernor.HOOK_NOT_APPROVED.selector);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook1);
    }

    /// @notice Tests reverting when executing without a merkle root proposal
    function test_MerkleRoot_Revert_ExecuteNoProposal() public {
        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Try to execute without a proposal
        vm.expectRevert(ISuperGovernor.NO_PROPOSED_MERKLE_ROOT.selector);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook1);
    }

    /// @notice Tests reverting when executing a merkle root update before timelock expiry
    function test_MerkleRoot_Revert_ExecuteBeforeTimelock() public {
        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(hook1);

        // Propose a new merkle root
        bytes32 proposedRoot = keccak256("test_root");
        vm.prank(governor);
        superGovernor.proposeSuperBankHookMerkleRoot(hook1, proposedRoot);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook1);
    }

    // =============================================================
    // Min Staleness Management Tests
    // =============================================================

    /// @notice Tests proposing a new minimum staleness value
    function test_MinStalenesManagement_ProposeMinStaleness() public {
        uint256 newMinStaleness = 600; // 10 minutes
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(sGovernor);
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.MinStalenessProposed(newMinStaleness, expectedTime);
        superGovernor.proposeMinStaleness(newMinStaleness);

        (uint256 proposedMinStaleness, uint256 effectiveTime) = superGovernor.getProposedMinStaleness();
        assertEq(proposedMinStaleness, newMinStaleness, "Proposed minimum staleness mismatch");
        assertEq(effectiveTime, expectedTime, "Effective time mismatch");
    }

    /// @notice Tests access control for proposeMinStaleness (only SUPER_GOVERNOR_ROLE)
    function test_MinStalenesManagement_ProposeAccessControl() public {
        uint256 newMinStaleness = 600;

        // Test with governor (should fail - needs SUPER_GOVERNOR_ROLE)
        vm.prank(governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, governor, SUPER_GOVERNOR_ROLE
            )
        );
        superGovernor.proposeMinStaleness(newMinStaleness);

        // Test with user (should fail)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, SUPER_GOVERNOR_ROLE)
        );
        superGovernor.proposeMinStaleness(newMinStaleness);

        // Test with sGovernor (should succeed)
        vm.prank(sGovernor);
        superGovernor.proposeMinStaleness(newMinStaleness);
    }

    /// @notice Tests executing a minimum staleness change
    function test_MinStalenesManagement_ExecuteMinStalenesChange() public {
        uint256 newMinStaleness = 600; // 10 minutes

        // Propose new minimum staleness
        vm.prank(sGovernor);
        superGovernor.proposeMinStaleness(newMinStaleness);

        // Check initial value (should be 300 from constructor)
        assertEq(superGovernor.getMinStaleness(), 300, "Initial minimum staleness should be 300");

        // Warp to after timelock
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the change
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.MinStalenessChanged(newMinStaleness);
        superGovernor.executeMinStalenesChange();

        assertEq(superGovernor.getMinStaleness(), newMinStaleness, "Minimum staleness should be updated");

        // Check that proposal data is reset
        (uint256 proposedMinStaleness,) = superGovernor.getProposedMinStaleness();
        assertEq(proposedMinStaleness, 0, "Proposed minimum staleness should be reset");
    }

    /// @notice Tests reverting when executing without a proposal
    function test_MinStalenesManagement_Revert_ExecuteNoProposal() public {
        vm.expectRevert(ISuperGovernor.NO_PROPOSED_MIN_STALENESS.selector);
        superGovernor.executeMinStalenesChange();
    }

    /// @notice Tests reverting when executing before timelock expiry
    function test_MinStalenesManagement_Revert_ExecuteBeforeTimelock() public {
        uint256 newMinStaleness = 600;

        // Propose new minimum staleness
        vm.prank(sGovernor);
        superGovernor.proposeMinStaleness(newMinStaleness);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeMinStalenesChange();
    }

    /// @notice Tests the initial minimum staleness value
    function test_MinStalenesManagement_InitialValue() public view {
        // Should be initialized to 300 seconds (5 minutes) in constructor
        assertEq(superGovernor.getMinStaleness(), 300, "Initial minimum staleness should be 300 seconds");
    }

    /// @notice Tests that execution is public (can be called by anyone)
    function test_MinStalenesManagement_PublicExecution() public {
        uint256 newMinStaleness = 600;

        // Propose as sGovernor
        vm.prank(sGovernor);
        superGovernor.proposeMinStaleness(newMinStaleness);

        // Execute as regular user (should work)
        vm.warp(block.timestamp + TIMELOCK + 1);
        vm.prank(user);
        superGovernor.executeMinStalenesChange();

        assertEq(superGovernor.getMinStaleness(), newMinStaleness, "Minimum staleness should be updated");
    }

    // =============================================================
    // Oracle Staleness Validation Tests
    // =============================================================

    /// @notice Tests that roles are properly assigned for oracle tests
    function test_OracleStalenesValidation_RoleAssignments() public view {
        assertTrue(superGovernor.hasRole(SUPER_GOVERNOR_ROLE, sGovernor), "sGovernor should have SUPER_GOVERNOR_ROLE");
        assertTrue(superGovernor.hasRole(GOVERNOR_ROLE, governor), "governor should have GOVERNOR_ROLE");
        assertTrue(superGovernor.hasRole(BANK_MANAGER_ROLE, governor), "governor should have BANK_MANAGER_ROLE");
    }

    /// @notice Tests setOracleMaxStaleness with valid staleness value
    function test_OracleStalenesValidation_SetOracleMaxStaleness_Success() public {
        // Create a mock oracle that implements the required functions
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        // Get the oracle key before pranking
        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        // Set the oracle in the registry
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        uint256 validStaleness = 400; // Greater than min staleness of 300

        vm.prank(governor);
        superGovernor.setOracleMaxStaleness(validStaleness);

        // Verify the mock oracle received the call
        assertEq(mockOracle.lastMaxStaleness(), validStaleness, "Oracle should have received the staleness value");
    }

    /// @notice Tests setOracleMaxStaleness reverts when staleness is too low
    function test_OracleStalenesValidation_SetOracleMaxStaleness_Revert_TooLow() public {
        // Create a mock oracle
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        // Get the oracle key before pranking
        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        // Set the oracle in the registry
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        uint256 tooLowStaleness = 200; // Less than min staleness of 300

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.MAX_STALENESS_TOO_LOW.selector);
        superGovernor.setOracleMaxStaleness(tooLowStaleness);
    }

    /// @notice Tests setOracleFeedMaxStaleness with valid staleness value
    function test_OracleStalenesValidation_SetOracleFeedMaxStaleness_Success() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        address feed = address(0x123);
        uint256 validStaleness = 500;

        vm.prank(governor);
        superGovernor.setOracleFeedMaxStaleness(feed, validStaleness);

        assertEq(mockOracle.lastFeed(), feed, "Oracle should have received the feed address");
        assertEq(mockOracle.lastFeedStaleness(), validStaleness, "Oracle should have received the staleness value");
    }

    /// @notice Tests setOracleFeedMaxStaleness reverts when staleness is too low
    function test_OracleStalenesValidation_SetOracleFeedMaxStaleness_Revert_TooLow() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        address feed = address(0x123);
        uint256 tooLowStaleness = 250; // Less than min staleness of 300

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.MAX_STALENESS_TOO_LOW.selector);
        superGovernor.setOracleFeedMaxStaleness(feed, tooLowStaleness);
    }

    /// @notice Tests setOracleFeedMaxStaleness reverts with zero feed address
    function test_OracleStalenesValidation_SetOracleFeedMaxStaleness_Revert_ZeroFeed() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        uint256 validStaleness = 400;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.setOracleFeedMaxStaleness(address(0), validStaleness);
    }

    /// @notice Tests setOracleFeedMaxStalenessBatch with all valid staleness values
    function test_OracleStalenesValidation_SetOracleFeedMaxStalenessBatch_Success() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        address[] memory feeds = new address[](3);
        feeds[0] = address(0x123);
        feeds[1] = address(0x456);
        feeds[2] = address(0x789);

        uint256[] memory stalenessList = new uint256[](3);
        stalenessList[0] = 400;
        stalenessList[1] = 500;
        stalenessList[2] = 600;

        vm.prank(governor);
        superGovernor.setOracleFeedMaxStalenessBatch(feeds, stalenessList);

        assertTrue(mockOracle.batchCalled(), "Oracle batch function should have been called");
    }

    /// @notice Tests setOracleFeedMaxStalenessBatch reverts when any staleness is too low
    function test_OracleStalenesValidation_SetOracleFeedMaxStalenessBatch_Revert_OneTooLow() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        address[] memory feeds = new address[](3);
        feeds[0] = address(0x123);
        feeds[1] = address(0x456);
        feeds[2] = address(0x789);

        uint256[] memory stalenessList = new uint256[](3);
        stalenessList[0] = 400; // Valid
        stalenessList[1] = 200; // Too low!
        stalenessList[2] = 600; // Valid

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.MAX_STALENESS_TOO_LOW.selector);
        superGovernor.setOracleFeedMaxStalenessBatch(feeds, stalenessList);
    }

    /// @notice Tests oracle staleness validation after changing minimum staleness
    function test_OracleStalenesValidation_AfterMinStalenesChange() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Change minimum staleness to a higher value
        uint256 newMinStaleness = 800;
        vm.prank(sGovernor);
        superGovernor.proposeMinStaleness(newMinStaleness);
        vm.warp(block.timestamp + TIMELOCK + 1);
        superGovernor.executeMinStalenesChange();

        // Now values that were previously valid should be rejected
        uint256 previouslyValidStaleness = 600; // Was > 300, but now < 800

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.MAX_STALENESS_TOO_LOW.selector);
        superGovernor.setOracleMaxStaleness(previouslyValidStaleness);

        // But values above the new minimum should work
        uint256 nowValidStaleness = 900;

        vm.prank(governor);
        superGovernor.setOracleMaxStaleness(nowValidStaleness);
        assertEq(mockOracle.lastMaxStaleness(), nowValidStaleness, "Oracle should accept valid staleness");
    }

    /// @notice Tests access control for oracle staleness functions
    function f() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        uint256 validStaleness = 400;
        address feed = address(0x123);

        // Test with user (should fail - needs GOVERNOR_ROLE)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.setOracleMaxStaleness(validStaleness);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.setOracleFeedMaxStaleness(feed, validStaleness);

        // Test with sGovernor (should fail - needs GOVERNOR_ROLE specifically)
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.setOracleMaxStaleness(validStaleness);

        // Test with governor (should succeed)
        vm.prank(governor);
        superGovernor.setOracleMaxStaleness(validStaleness);
        assertEq(mockOracle.lastMaxStaleness(), validStaleness, "Governor should be able to set staleness");
    }

    /// @notice Tests reverting when oracle is not set in registry
    function test_OracleStalenesValidation_Revert_OracleNotSet() public {
        uint256 validStaleness = 400;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.setOracleMaxStaleness(validStaleness);
    }

    /// @notice Tests setOracleFeedMaxStaleness reverts when oracle is not set in registry
    /// @dev Covers SuperGovernor.sol:259 - if (oracle == address(0)) revert CONTRACT_NOT_FOUND()
    function test_OracleStalenesValidation_SetOracleFeedMaxStaleness_Revert_OracleNotSet() public {
        address feed = makeAddr("testFeed");
        uint256 validStaleness = 400;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.setOracleFeedMaxStaleness(feed, validStaleness);
    }

    /// @notice Tests setOracleFeedMaxStalenessBatch reverts when oracle is not set in registry
    /// @dev Covers SuperGovernor.sol:278 - if (oracle == address(0)) revert CONTRACT_NOT_FOUND()
    function test_OracleStalenesValidation_SetOracleFeedMaxStalenessBatch_Revert_OracleNotSet() public {
        address[] memory feeds = new address[](2);
        feeds[0] = makeAddr("feed1");
        feeds[1] = makeAddr("feed2");

        uint256[] memory stalenessList = new uint256[](2);
        stalenessList[0] = 400;
        stalenessList[1] = 500;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.setOracleFeedMaxStalenessBatch(feeds, stalenessList);
    }

    // =============================================================
    // Oracle Update Management Tests
    // =============================================================

    /// @notice Tests queueOracleUpdate with valid parameters
    function test_OracleUpdateManagement_QueueOracleUpdate_Success() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        address[] memory bases = new address[](2);
        bases[0] = address(0x111);
        bases[1] = address(0x222);

        address[] memory quotes = new address[](2);
        quotes[0] = address(0x333);
        quotes[1] = address(0x444);

        bytes32[] memory providers = new bytes32[](2);
        providers[0] = keccak256("PROVIDER1");
        providers[1] = keccak256("PROVIDER2");

        address[] memory feeds = new address[](2);
        feeds[0] = address(0x555);
        feeds[1] = address(0x666);

        vm.prank(governor);
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);

        // Verify the mock oracle received the call
        assertTrue(mockOracle.oracleUpdateQueued(), "Oracle update should be queued");
        assertEq(mockOracle.getLastBasesLength(), 2, "Should have 2 bases");
        assertEq(mockOracle.getLastQuotesLength(), 2, "Should have 2 quotes");
        assertEq(mockOracle.getLastProvidersLength(), 2, "Should have 2 providers");
        assertEq(mockOracle.getLastFeedsLength(), 2, "Should have 2 feeds");
        assertEq(mockOracle.getLastBase(0), bases[0], "First base should match");
        assertEq(mockOracle.getLastBase(1), bases[1], "Second base should match");
    }

    /// @notice Tests queueOracleUpdate reverts when oracle is not set in registry
    function test_OracleUpdateManagement_QueueOracleUpdate_Revert_OracleNotSet() public {
        address[] memory bases = new address[](1);
        bases[0] = address(0x111);

        address[] memory quotes = new address[](1);
        quotes[0] = address(0x333);

        bytes32[] memory providers = new bytes32[](1);
        providers[0] = keccak256("PROVIDER1");

        address[] memory feeds = new address[](1);
        feeds[0] = address(0x555);

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);
    }

    /// @notice Tests queueOracleUpdate access control - only GOVERNOR_ROLE can call
    function test_OracleUpdateManagement_QueueOracleUpdate_AccessControl() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        address[] memory bases = new address[](1);
        bases[0] = address(0x111);

        address[] memory quotes = new address[](1);
        quotes[0] = address(0x333);

        bytes32[] memory providers = new bytes32[](1);
        providers[0] = keccak256("PROVIDER1");

        address[] memory feeds = new address[](1);
        feeds[0] = address(0x555);

        // Test with user (should fail - needs GOVERNOR_ROLE)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);

        // Test with sGovernor (should fail - needs GOVERNOR_ROLE specifically)
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);

        // Test with governor (should succeed)
        vm.prank(governor);
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);
        assertTrue(mockOracle.oracleUpdateQueued(), "Governor should be able to queue oracle update");
    }

    /// @notice Tests queueOracleUpdate with empty arrays
    function test_OracleUpdateManagement_QueueOracleUpdate_EmptyArrays() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        address[] memory bases = new address[](0);
        address[] memory quotes = new address[](0);
        bytes32[] memory providers = new bytes32[](0);
        address[] memory feeds = new address[](0);

        vm.prank(governor);
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);

        // Verify the mock oracle received the call with empty arrays
        assertTrue(mockOracle.oracleUpdateQueued(), "Oracle update should be queued");
        assertEq(mockOracle.getLastBasesLength(), 0, "Should have 0 bases");
        assertEq(mockOracle.getLastQuotesLength(), 0, "Should have 0 quotes");
        assertEq(mockOracle.getLastProvidersLength(), 0, "Should have 0 providers");
        assertEq(mockOracle.getLastFeedsLength(), 0, "Should have 0 feeds");
    }

    /// @notice Tests executeOracleUpdate with valid setup
    function test_OracleUpdateManagement_ExecuteOracleUpdate_Success() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // First queue an update
        address[] memory bases = new address[](1);
        bases[0] = address(0x111);

        address[] memory quotes = new address[](1);
        quotes[0] = address(0x333);

        bytes32[] memory providers = new bytes32[](1);
        providers[0] = keccak256("PROVIDER1");

        address[] memory feeds = new address[](1);
        feeds[0] = address(0x555);

        vm.prank(governor);
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);

        // Now execute the update
        vm.prank(oracleManager); // sGovernor has ORACLE_MANAGER_ROLE
        superGovernor.executeOracleUpdate();

        // Verify the mock oracle received the execution call
        assertTrue(mockOracle.oracleUpdateExecuted(), "Oracle update should be executed");
    }

    /// @notice Tests executeOracleUpdate reverts when oracle is not set in registry
    function test_OracleUpdateManagement_ExecuteOracleUpdate_Revert_OracleNotSet() public {
        vm.prank(oracleManager);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.executeOracleUpdate();
    }

    /// @notice Tests executeOracleUpdate access control - only ORACLE_MANAGER_ROLE can call
    function test_OracleUpdateManagement_ExecuteOracleUpdate_AccessControl() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Test with user (should fail - needs ORACLE_MANAGER_ROLE)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, ORACLE_MANAGER_ROLE)
        );
        superGovernor.executeOracleUpdate();

        // Test with governor (should fail - needs ORACLE_MANAGER_ROLE specifically)
        vm.prank(governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, governor, ORACLE_MANAGER_ROLE
            )
        );
        superGovernor.executeOracleUpdate();

        // Test with sGovernor (should succeed - has ORACLE_MANAGER_ROLE)
        vm.prank(oracleManager);
        superGovernor.executeOracleUpdate();
        assertTrue(mockOracle.oracleUpdateExecuted(), "sGovernor should be able to execute oracle update");
    }

    /// @notice Tests queueOracleProviderRemoval reverts when oracle is not set in registry
    /// @dev Covers SuperGovernor.sol:310 - if (oracle == address(0)) revert CONTRACT_NOT_FOUND()
    function test_OracleUpdateManagement_QueueOracleProviderRemoval_Revert_OracleNotSet() public {
        bytes32[] memory providers = new bytes32[](1);
        providers[0] = keccak256("PROVIDER1");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.queueOracleProviderRemoval(providers);
    }

    /// @notice Tests executeOracleProviderRemoval reverts when oracle is not set in registry
    /// @dev Covers SuperGovernor.sol:470 - if (oracle == address(0)) revert CONTRACT_NOT_FOUND()
    function test_OracleUpdateManagement_ExecuteOracleProviderRemoval_Revert_OracleNotSet() public {
        vm.prank(oracleManager);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.executeOracleProviderRemoval();
    }

    /// @notice Tests executeOracleProviderRemoval successfully delegates to oracle
    /// @dev Covers SuperGovernor.sol:468-473 success path with oracle delegation
    function test_OracleUpdateManagement_ExecuteOracleProviderRemoval_Success() public {
        // Setup mock oracle
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();
        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Call executeOracleProviderRemoval
        vm.prank(oracleManager); // oracleManager has ORACLE_MANAGER_ROLE
        superGovernor.executeOracleProviderRemoval();

        // Verify oracle received the call
        assertTrue(mockOracle.providerRemovalExecuted(), "Oracle should have executed provider removal");
    }

    /// @notice Tests executeOracleProviderRemoval access control
    /// @dev Covers SuperGovernor.sol:468 - onlyRole(_ORACLE_MANAGER_ROLE)
    function test_OracleUpdateManagement_ExecuteOracleProviderRemoval_AccessControl() public {
        // Setup mock oracle
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();
        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Try to call from unauthorized address (regular user)
        address unauthorized = makeAddr("unauthorized");
        vm.prank(unauthorized);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, ORACLE_MANAGER_ROLE
            )
        );
        superGovernor.executeOracleProviderRemoval();

        // Try to call from governor (has GOVERNOR_ROLE but not ORACLE_MANAGER_ROLE)
        vm.prank(governor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, governor, ORACLE_MANAGER_ROLE
            )
        );
        superGovernor.executeOracleProviderRemoval();

        // Verify oracle did not receive the call from unauthorized callers
        assertFalse(mockOracle.providerRemovalExecuted(), "Oracle should not have been called by unauthorized users");

        // Verify oracleManager (who has ORACLE_MANAGER_ROLE) can call successfully
        vm.prank(oracleManager);
        superGovernor.executeOracleProviderRemoval();
        assertTrue(mockOracle.providerRemovalExecuted(), "Oracle should have been called by authorized user");
    }

    /// @notice Tests batchSetOracleUptimeFeed reverts when oracle is not set in registry
    /// @dev Covers SuperGovernor.sol:325 - if (oracleL2 == address(0)) revert CONTRACT_NOT_FOUND()
    function test_OracleUpdateManagement_BatchSetOracleUptimeFeed_Revert_OracleNotSet() public {
        address[] memory dataOracles = new address[](1);
        dataOracles[0] = makeAddr("dataOracle");

        address[] memory uptimeOracles = new address[](1);
        uptimeOracles[0] = makeAddr("uptimeOracle");

        uint256[] memory gracePeriods = new uint256[](1);
        gracePeriods[0] = 3600;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    /// @notice Tests batchSetOracleUptimeFeed success path
    /// @dev Covers SuperGovernor.sol:316-328 complete flow
    function test_OracleUpdateManagement_BatchSetOracleUptimeFeed_Success() public {
        // Note: This test verifies the call succeeds and delegates to the oracle
        // The actual uptime feed validation logic is tested in SuperOracleL2 tests
        MockSuperOracleL2 mockOracleL2 = new MockSuperOracleL2();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracleL2));

        address[] memory dataOracles = new address[](2);
        dataOracles[0] = makeAddr("dataOracle1");
        dataOracles[1] = makeAddr("dataOracle2");

        address[] memory uptimeOracles = new address[](2);
        uptimeOracles[0] = makeAddr("uptimeOracle1");
        uptimeOracles[1] = makeAddr("uptimeOracle2");

        uint256[] memory gracePeriods = new uint256[](2);
        gracePeriods[0] = 3600;
        gracePeriods[1] = 7200;

        vm.prank(governor);
        superGovernor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Verify the mock received the call
        assertTrue(mockOracleL2.batchSetUptimeFeedCalled(), "Oracle should have received the call");
    }

    /// @notice Tests batchSetOracleUptimeFeed access control
    /// @dev Covers SuperGovernor.sol:322 - onlyRole(_GOVERNOR_ROLE) modifier
    function test_OracleUpdateManagement_BatchSetOracleUptimeFeed_AccessControl() public {
        MockSuperOracleL2 mockOracleL2 = new MockSuperOracleL2();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracleL2));

        address[] memory dataOracles = new address[](1);
        dataOracles[0] = makeAddr("dataOracle");

        address[] memory uptimeOracles = new address[](1);
        uptimeOracles[0] = makeAddr("uptimeOracle");

        uint256[] memory gracePeriods = new uint256[](1);
        gracePeriods[0] = 3600;

        // Try with user (should fail - needs GOVERNOR_ROLE)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Try with governor (should succeed - has GOVERNOR_ROLE)
        vm.prank(governor);
        superGovernor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        assertTrue(mockOracleL2.batchSetUptimeFeedCalled(), "Governor should be able to call");
    }

    /// @notice Tests batchSetOracleUptimeFeed with empty arrays
    /// @dev Tests edge case with empty input arrays
    function test_OracleUpdateManagement_BatchSetOracleUptimeFeed_EmptyArrays() public {
        MockSuperOracleL2 mockOracleL2 = new MockSuperOracleL2();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();
        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracleL2));

        address[] memory dataOracles = new address[](0);
        address[] memory uptimeOracles = new address[](0);
        uint256[] memory gracePeriods = new uint256[](0);

        // Should delegate to oracle (oracle will validate)
        vm.prank(governor);
        superGovernor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    /// @notice Tests executeOracleUpdate can be called without queuing first (depends on oracle implementation)
    function test_OracleUpdateManagement_ExecuteOracleUpdate_WithoutQueue() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Execute without queuing first - this should work with our mock
        vm.prank(oracleManager);
        superGovernor.executeOracleUpdate();

        // Verify the mock oracle received the execution call
        assertTrue(mockOracle.oracleUpdateExecuted(), "Oracle update should be executed");
    }

    /// @notice Tests the complete flow: queue then execute oracle update
    function test_OracleUpdateManagement_CompleteFlow() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Step 1: Queue the update
        address[] memory bases = new address[](3);
        bases[0] = address(0x111);
        bases[1] = address(0x222);
        bases[2] = address(0x333);

        address[] memory quotes = new address[](3);
        quotes[0] = address(0x444);
        quotes[1] = address(0x555);
        quotes[2] = address(0x666);

        bytes32[] memory providers = new bytes32[](3);
        providers[0] = keccak256("PROVIDER1");
        providers[1] = keccak256("PROVIDER2");
        providers[2] = keccak256("PROVIDER3");

        address[] memory feeds = new address[](3);
        feeds[0] = address(0x777);
        feeds[1] = address(0x888);
        feeds[2] = address(0x999);

        vm.prank(governor);
        superGovernor.queueOracleUpdate(bases, quotes, providers, feeds);

        // Verify queuing worked
        assertTrue(mockOracle.oracleUpdateQueued(), "Oracle update should be queued");
        assertEq(mockOracle.getLastBasesLength(), 3, "Should have 3 bases");
        assertEq(mockOracle.getLastProvider(2), providers[2], "Third provider should match");

        // Step 2: Execute the update
        vm.prank(oracleManager);
        superGovernor.executeOracleUpdate();

        // Verify execution worked
        assertTrue(mockOracle.oracleUpdateExecuted(), "Oracle update should be executed");
    }

    /// @notice Tests multiple queue operations (should overwrite previous)
    function test_OracleUpdateManagement_MultipleQueueOperations() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // First queue operation
        address[] memory bases1 = new address[](1);
        bases1[0] = address(0x111);

        address[] memory quotes1 = new address[](1);
        quotes1[0] = address(0x333);

        bytes32[] memory providers1 = new bytes32[](1);
        providers1[0] = keccak256("PROVIDER1");

        address[] memory feeds1 = new address[](1);
        feeds1[0] = address(0x555);

        vm.prank(governor);
        superGovernor.queueOracleUpdate(bases1, quotes1, providers1, feeds1);

        // Second queue operation (should overwrite)
        address[] memory bases2 = new address[](2);
        bases2[0] = address(0x222);
        bases2[1] = address(0x333);

        address[] memory quotes2 = new address[](2);
        quotes2[0] = address(0x444);
        quotes2[1] = address(0x555);

        bytes32[] memory providers2 = new bytes32[](2);
        providers2[0] = keccak256("PROVIDER2");
        providers2[1] = keccak256("PROVIDER3");

        address[] memory feeds2 = new address[](2);
        feeds2[0] = address(0x666);
        feeds2[1] = address(0x777);

        vm.prank(governor);
        superGovernor.queueOracleUpdate(bases2, quotes2, providers2, feeds2);

        // Verify the second operation overwrote the first
        assertTrue(mockOracle.oracleUpdateQueued(), "Oracle update should be queued");
        assertEq(mockOracle.getLastBasesLength(), 2, "Should have 2 bases from second operation");
        assertEq(mockOracle.getLastBase(0), bases2[0], "First base should be from second operation");
        assertEq(mockOracle.getLastBase(1), bases2[1], "Second base should be from second operation");
        assertEq(mockOracle.getLastProvider(0), providers2[0], "First provider should be from second operation");
    }

    function test_QueueOracleProviderRemoval() public {
        bytes32[] memory providers = new bytes32[](1);
        providers[0] = keccak256("PROVIDER1");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.queueOracleProviderRemoval(providers);

        // TODO: success flow
    }

    /// @notice Tests executeUpkeepPaymentsChange reverts when no change is pending
    /// @dev Covers SuperGovernor.sol:543 - if (_upkeepPaymentsChangeEffectiveTime == 0) revert NO_PENDING_CHANGE()
    function test_ExecuteUpkeepPaymentsChange_NoPendingChange() public {
        // Try to execute without proposing first
        vm.expectRevert(ISuperGovernor.NO_PENDING_CHANGE.selector);
        superGovernor.executeUpkeepPaymentsChange();
    }

    /// @notice Tests proposeSuperBankHookMerkleRoot reverts when proposed root is zero
    /// @dev Covers SuperGovernor.sol:603 - if (proposedRoot == bytes32(0)) revert ZERO_PROPOSED_MERKLE_ROOT()
    function test_ProposeSuperBankHookMerkleRoot_ZeroProposedRoot() public {
        // First register a hook
        address testHook = makeAddr("testHook");
        vm.prank(governor);
        superGovernor.registerHook(testHook);

        // Try to propose zero root
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.ZERO_PROPOSED_MERKLE_ROOT.selector);
        superGovernor.proposeSuperBankHookMerkleRoot(testHook, bytes32(0));
    }

    /// @notice Tests getUpkeepCostPerSingleUpdate reverts when SUPER_ORACLE not found
    /// @dev Covers SuperGovernor.sol:863 - if (oracle == address(0)) revert SUPER_ORACLE_NOT_FOUND()
    function test_GetUpkeepCostPerSingleUpdate_SuperOracleNotFound() public {
        // SUPER_ORACLE is not set in the registry
        address testOracle = makeAddr("testOracle");

        vm.expectRevert(ISuperGovernor.SUPER_ORACLE_NOT_FOUND.selector);
        superGovernor.getUpkeepCostPerSingleUpdate(testOracle);
    }
}

// =============================================================
// Mock Contract for Oracle Staleness Testing
// =============================================================

/// @notice Mock SuperOracle contract that implements the staleness functions for testing
contract MockSuperOracleForStaleness {
    uint256 public lastMaxStaleness;
    address public lastFeed;
    uint256 public lastFeedStaleness;
    bool public batchCalled;

    // Oracle update tracking
    address[] public lastBases;
    address[] public lastQuotes;
    bytes32[] public lastProviders;
    address[] public lastFeeds;
    bool public oracleUpdateQueued;
    bool public oracleUpdateExecuted;
    bool public providerRemovalExecuted;

    mapping(address token => uint256 emergencyPrice) public emergencyPrices;
    bool public batchSetEmergencyPriceCalled;
    address[] public lastBatchTokens;
    uint256[] public lastBatchPrices;

    function setEmergencyPrice(address token, uint256 emergencyPrice) external {
        emergencyPrices[token] = emergencyPrice;
    }

    function getEmergencyPrice(address token) external view returns (uint256) {
        return emergencyPrices[token];
    }

    function batchSetEmergencyPrice(address[] calldata tokens, uint256[] calldata prices) external {
        batchSetEmergencyPriceCalled = true;
        delete lastBatchTokens;
        delete lastBatchPrices;
        for (uint256 i = 0; i < tokens.length; i++) {
            lastBatchTokens.push(tokens[i]);
            lastBatchPrices.push(prices[i]);
            emergencyPrices[tokens[i]] = prices[i];
        }
    }

    function getLastBatchTokensLength() external view returns (uint256) {
        return lastBatchTokens.length;
    }

    function getLastBatchToken(uint256 index) external view returns (address) {
        return lastBatchTokens[index];
    }

    function getLastBatchPrice(uint256 index) external view returns (uint256) {
        return lastBatchPrices[index];
    }

    function setDefaultStaleness(uint256 newMaxStaleness) external {
        lastMaxStaleness = newMaxStaleness;
    }

    function setFeedMaxStaleness(address feed, uint256 newMaxStaleness) external {
        lastFeed = feed;
        lastFeedStaleness = newMaxStaleness;
    }

    function setFeedMaxStalenessBatch(address[] calldata, uint256[] calldata) external {
        batchCalled = true;
    }

    function queueOracleUpdate(
        address[] calldata bases,
        address[] calldata quotes,
        bytes32[] calldata providers,
        address[] calldata feeds
    )
        external
    {
        lastBases = bases;
        lastQuotes = quotes;
        lastProviders = providers;
        lastFeeds = feeds;
        oracleUpdateQueued = true;
    }

    function executeOracleUpdate() external {
        oracleUpdateExecuted = true;
    }

    function executeProviderRemoval() external {
        providerRemovalExecuted = true;
    }

    // Getter functions for testing
    function getLastBasesLength() external view returns (uint256) {
        return lastBases.length;
    }

    function getLastQuotesLength() external view returns (uint256) {
        return lastQuotes.length;
    }

    function getLastProvidersLength() external view returns (uint256) {
        return lastProviders.length;
    }

    function getLastFeedsLength() external view returns (uint256) {
        return lastFeeds.length;
    }

    function getLastBase(uint256 index) external view returns (address) {
        return lastBases[index];
    }

    function getLastQuote(uint256 index) external view returns (address) {
        return lastQuotes[index];
    }

    function getLastProvider(uint256 index) external view returns (bytes32) {
        return lastProviders[index];
    }

    function getLastFeed(uint256 index) external view returns (address) {
        return lastFeeds[index];
    }

    /// @notice Mock implementation of getQuoteFromProvider for _convertGasToUp testing
    function getQuoteFromProvider(
        uint256 amount,
        address,
        address,
        bytes32
    )
        external
        pure
        returns (uint256, uint256, uint256, uint256)
    {
        // Return amount as-is for simplicity in testing
        return (amount, 0, 0, 0);
    }
}

/// @notice Mock SuperOracleL2 for testing batchSetOracleUptimeFeed delegation
contract MockSuperOracleL2 {
    bool private _batchSetUptimeFeedCalled;

    function batchSetUptimeFeed(
        address[] calldata,
        address[] calldata,
        uint256[] calldata
    )
        external
    {
        _batchSetUptimeFeedCalled = true;
    }

    function batchSetUptimeFeedCalled() external view returns (bool) {
        return _batchSetUptimeFeedCalled;
    }
}

/// @notice Mock SuperVaultAggregator for testing executeUpkeepClaim delegation
contract MockSuperVaultAggregator {
    bool private _claimUpkeepCalled;
    uint256 private _lastClaimAmount;

    function claimUpkeep(uint256 amount) external {
        _claimUpkeepCalled = true;
        _lastClaimAmount = amount;
    }

    function claimUpkeepCalled() external view returns (bool) {
        return _claimUpkeepCalled;
    }

    function lastClaimAmount() external view returns (uint256) {
        return _lastClaimAmount;
    }
}
