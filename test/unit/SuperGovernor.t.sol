// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor, FeeType } from "../../src/interfaces/ISuperGovernor.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
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
        user = _deployAccount(0x4, "User");
        hook1 = _deployAccount(0x5, "Hook1");
        hook2 = _deployAccount(0x6, "Hook2");
        fulfillHook1 = _deployAccount(0x7, "FulfillHook1");
        fulfillHook2 = _deployAccount(0x8, "FulfillHook2");
        validator1 = _deployAccount(0x9, "Validator1");
        validator2 = _deployAccount(0xA, "Validator2");
        ppsOracle1 = _deployAccount(0xB, "PPSOracle1");
        ppsOracle2 = _deployAccount(0xC, "PPSOracle2");
        newManager = _deployAccount(0xF, "NewManager");
        manager = _deployAccount(0x10, "Manager");
        upToken = new MockUp(address(this));
        superBank = _deployAccount(0x12, "SuperBank");

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, treasury);

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
                    }),
                    maxUnpauseTimeLock: 0
                })
            );
        strategy1 = strategy;

        vm.startPrank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, address(aggregator));
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.UP(), address(upToken));
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
        new SuperGovernor(address(0), governor, governor, governor, treasury);
    }

    /// @notice Tests constructor revert on zero address governor.
    function test_constructor_Revert_ZeroGovernor() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);

        new SuperGovernor(sGovernor, address(0), governor, governor, treasury);
    }

    /// @notice Tests constructor revert on zero address treasury.
    function test_constructor_Revert_ZeroTreasury() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);

        new SuperGovernor(sGovernor, governor, governor, governor, address(0));
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
        vm.prank(sGovernor); // Admin has SUPER_GOVERNOR_ROLE but not GOVERNOR_ROLE by default
        // Expected role hash for GOVERNOR_ROLE
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.addValidator(validator1);

        vm.prank(governor);
        superGovernor.addValidator(validator1); // Should succeed
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

    function test_IsExecutor() public {
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ExecutorAdded(address(this));
        superGovernor.addExecutor(address(this));

        assertTrue(superGovernor.isExecutor(address(this)), "This contract should be an executor");
        address[] memory executors = superGovernor.getExecutors();
        assertEq(executors.length, 1, "Should have 1 executor");
        assertEq(executors[0], address(this), "Executor in list should match");

        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ExecutorRemoved(address(this));
        superGovernor.removeExecutor(address(this));

        assertFalse(superGovernor.isExecutor(address(this)), "This contract should not be an executor");
        executors = superGovernor.getExecutors();
        assertEq(executors.length, 0, "Should have 0 executors");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.EXECUTOR_NOT_REGISTERED.selector);
        superGovernor.removeExecutor(address(this));
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

    // =============================================================
    // Validator Management Tests
    // =============================================================

    /// @notice Tests adding a validator
    function test_ValidatorManagement_AddValidator() public {
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ValidatorAdded(validator1, block.timestamp);
        superGovernor.addValidator(validator1);

        assertTrue(superGovernor.isValidator(validator1), "Validator should be added");
        address[] memory validators = superGovernor.getValidators();
        assertEq(validators.length, 1, "Should have 1 validator");
        assertEq(validators[0], validator1, "Validator in list should match");
    }

    /// @notice Tests getting validators by index using getValidatorAt
    function test_ValidatorManagement_GetValidatorAt() public {
        // Add two validators
        vm.startPrank(governor);
        superGovernor.addValidator(validator1);
        superGovernor.addValidator(validator2);
        vm.stopPrank();

        // Verify count
        uint256 count = superGovernor.getValidatorsCount();
        assertEq(count, 2, "Should have 2 validators");

        // Get validators by index
        address validatorAt0 = superGovernor.getValidatorAt(0);
        address validatorAt1 = superGovernor.getValidatorAt(1);

        // Verify both validators are accessible
        assertTrue(validatorAt0 == validator1 || validatorAt0 == validator2, "Index 0 should be validator1 or validator2");
        assertTrue(validatorAt1 == validator1 || validatorAt1 == validator2, "Index 1 should be validator1 or validator2");
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

    /// @notice Tests reverting when adding a validator with zero address
    function test_ValidatorManagement_Revert_ZeroAddress() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.addValidator(address(0));
    }

    /// @notice Tests reverting when adding an already registered validator
    function test_ValidatorManagement_Revert_AlreadyRegistered() public {
        // Add validator first
        vm.prank(governor);
        superGovernor.addValidator(validator1);

        // Try to add again
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.VALIDATOR_ALREADY_REGISTERED.selector);
        superGovernor.addValidator(validator1);
    }

    /// @notice Tests removing a validator
    function test_ValidatorManagement_RemoveValidator() public {
        // Add validator first
        vm.prank(governor);
        superGovernor.addValidator(validator1);

        // Remove validator
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ValidatorRemoved(validator1, block.timestamp);
        superGovernor.removeValidator(validator1);

        assertFalse(superGovernor.isValidator(validator1), "Validator should be removed");
        address[] memory validators = superGovernor.getValidators();
        assertEq(validators.length, 0, "Should have 0 validators");
    }

    /// @notice Tests reverting when removing a non-existent validator
    function test_ValidatorManagement_Revert_NotRegistered() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.VALIDATOR_NOT_REGISTERED.selector);
        superGovernor.removeValidator(validator1);
    }

    /// @notice Tests removing a validator when multiple validators exist
    function test_ValidatorManagement_RemoveValidatorWithMultiple() public {
        // Add two validators
        vm.startPrank(governor);
        superGovernor.addValidator(validator1);
        superGovernor.addValidator(validator2);
        vm.stopPrank();

        // Remove the first validator
        vm.prank(governor);
        superGovernor.removeValidator(validator1);

        assertFalse(superGovernor.isValidator(validator1), "validator1 should be removed");
        assertTrue(superGovernor.isValidator(validator2), "validator2 should still be registered");

        address[] memory validators = superGovernor.getValidators();
        assertEq(validators.length, 1, "Should have 1 validator remaining");
        assertEq(validators[0], validator2, "Remaining validator should be validator2");
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

    /// @notice Tests setting the PPS Oracle quorum
    function test_PPSOracleManagement_SetPPSOracleQuorum() public {
        uint256 newQuorum = 3;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_QUORUM.selector);
        superGovernor.setPPSOracleQuorum(0);

        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.PPSOracleQuorumUpdated(newQuorum);
        superGovernor.setPPSOracleQuorum(newQuorum);

        assertEq(superGovernor.getPPSOracleQuorum(), newQuorum, "PPS Oracle quorum mismatch");
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

    // =============================================================
    // Slash Stake Validation Tests
    // =============================================================
    /// @notice Tests successful stake slashing
    function test_SlashStake_Success() public {
        uint256 stakeAmount = 1000e18;
        uint256 slashAmount = 200e18;
        uint256 remainingStake = stakeAmount - slashAmount;

        // Setup: Deposit stake first
        upToken.mint(manager, stakeAmount);
        vm.startPrank(manager);
        upToken.approve(address(superVaultAggregator), stakeAmount);
        aggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();

        // Record initial SuperBank balance
        uint256 initialBankBalance = upToken.balanceOf(superBank);

        // SuperGovernor slashes stake
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperVaultAggregator.StakeSlashed(manager, slashAmount);
        superGovernor.slashStake(manager, slashAmount);

        // Verify balances
        assertEq(aggregator.getStakeBalance(manager), remainingStake, "Manager stake should be reduced");
        assertEq(
            upToken.balanceOf(superBank), initialBankBalance + slashAmount, "SuperBank should receive slashed tokens"
        );
        assertEq(upToken.balanceOf(address(aggregator)), remainingStake, "Contract should hold remaining stake");
    }

    /// @notice Tests complete stake slashing
    function test_SlashStake_CompleteSlashing() public {
        uint256 stakeAmount = 1000e18;

        // Setup: Deposit stake first
        upToken.mint(manager, stakeAmount);
        vm.startPrank(manager);
        upToken.approve(address(superVaultAggregator), stakeAmount);
        aggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();

        // SuperGovernor slashes all stake
        vm.prank(governor);
        superGovernor.slashStake(manager, stakeAmount);

        // Verify balances
        assertEq(aggregator.getStakeBalance(manager), 0, "Manager stake should be zero");
        assertEq(upToken.balanceOf(superBank), stakeAmount, "SuperBank should receive all slashed tokens");
    }

    /// @notice Tests slashing reverts when called by non-governor
    function test_SlashStake_RevertUnauthorized() public {
        uint256 stakeAmount = 1000e18;

        // Setup: Deposit stake first
        upToken.mint(manager, stakeAmount);
        vm.startPrank(manager);
        upToken.approve(address(superVaultAggregator), stakeAmount);
        aggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();

        // Test various unauthorized callers
        vm.prank(manager);
        vm.expectRevert();
        superGovernor.slashStake(manager, 100e18);

        vm.prank(user);
        vm.expectRevert();
        superGovernor.slashStake(manager, 100e18);

        vm.prank(sGovernor);
        vm.expectRevert();
        superGovernor.slashStake(manager, 100e18);
    }

    /// @notice Tests slashing reverts when SuperVaultAggregator is not set
    function test_SlashStake_RevertContractNotFound() public {
        // Deploy a new SuperGovernor with valid addresses but without setting the aggregator
        SuperGovernor newSuperGovernor = new SuperGovernor(
            sGovernor,
            governor,
            governor, // bankManager (using governor as valid address)
            governor, // gasManager (using governor as valid address)s
            treasury
        );

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        newSuperGovernor.slashStake(manager, 100e18);
    }

    /// @notice Tests slashing reverts with zero address manager
    function test_SlashStake_RevertZeroAddress() public {
        vm.prank(governor);
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        superGovernor.slashStake(address(0), 100e18);
    }

    /// @notice Tests slashing reverts with insufficient stake balance
    function test_SlashStake_PartialSlashWhenInsufficient() public {
        uint256 stakeAmount = 500e18;
        uint256 slashAmount = 1000e18;

        // Setup: Deposit smaller stake
        upToken.mint(manager, stakeAmount);
        vm.startPrank(manager);
        upToken.approve(address(superVaultAggregator), stakeAmount);
        aggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();

        // Get SuperBank balance before
        address superBankAddr = superGovernor.getAddress(superGovernor.SUPER_BANK());
        uint256 superBankBalanceBefore = upToken.balanceOf(superBankAddr);

        // Try to slash more than available - should slash only what's available
        vm.prank(governor);
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultAggregator.StakeSlashed(manager, stakeAmount); // Only stakeAmount is slashed
        superGovernor.slashStake(manager, slashAmount);

        // Verify only available amount was slashed
        assertEq(aggregator.getStakeBalance(manager), 0, "All stake should be slashed");
        assertEq(
            upToken.balanceOf(superBankAddr),
            superBankBalanceBefore + stakeAmount,
            "SuperBank should receive available amount"
        );
    }

    /// @notice Tests slashing reverts when no stake deposited
    function test_SlashStake_RevertNoStake() public {
        vm.prank(governor);
        vm.expectRevert(ISuperVaultAggregator.ZERO_AMOUNT.selector);
        superGovernor.slashStake(manager, 100e18);
    }

    /// @notice Tests slashing with multiple managers
    function test_SlashStake_MultipleManagers() public {
        uint256 stakeAmount = 1000e18;
        uint256 slashAmount = 200e18;
        address manager2 = _deployAccount(0x9, "Manager2");

        // Setup: Deposit stake for both managers
        upToken.mint(manager, stakeAmount);
        upToken.mint(manager2, stakeAmount);

        vm.startPrank(manager);
        upToken.approve(address(superVaultAggregator), stakeAmount);
        aggregator.depositStake(manager, stakeAmount);
        vm.stopPrank();

        vm.startPrank(manager2);
        upToken.approve(address(superVaultAggregator), stakeAmount);
        aggregator.depositStake(manager2, stakeAmount);
        vm.stopPrank();

        // Slash only first manager's stake
        vm.prank(governor);
        superGovernor.slashStake(manager, slashAmount);

        // Verify only first manager was slashed
        assertEq(
            aggregator.getStakeBalance(manager), stakeAmount - slashAmount, "First manager stake should be reduced"
        );
        assertEq(aggregator.getStakeBalance(manager2), stakeAmount, "Second manager stake should be unchanged");
    }

    /// @notice Tests stake and upkeep systems are independent
    function test_SlashStake_StakeUpkeepIndependence() public {
        uint256 stakeAmount = 1000e18;
        uint256 upkeepAmount = 500e18;

        // Mint tokens to manager
        upToken.mint(manager, stakeAmount + upkeepAmount);

        // Deposit both stake and upkeep
        vm.startPrank(manager);
        upToken.approve(address(superVaultAggregator), stakeAmount + upkeepAmount);
        aggregator.depositStake(manager, stakeAmount);
        ISuperVaultAggregator(superVaultAggregator).depositUpkeep(manager, upkeepAmount);
        vm.stopPrank();

        // Verify independent balances
        assertEq(aggregator.getStakeBalance(manager), stakeAmount, "Stake balance should be independent");
        assertEq(
            ISuperVaultAggregator(superVaultAggregator).getUpkeepBalance(manager),
            upkeepAmount,
            "Upkeep balance should be independent"
        );

        // Slash stake - should not affect upkeep
        uint256 slashAmount = 300e18;
        vm.prank(governor);
        superGovernor.slashStake(manager, slashAmount);

        // Verify only stake was affected
        assertEq(
            ISuperVaultAggregator(superVaultAggregator).getStakeBalance(manager),
            stakeAmount - slashAmount,
            "Only stake should be reduced"
        );
        assertEq(
            ISuperVaultAggregator(superVaultAggregator).getUpkeepBalance(manager),
            upkeepAmount,
            "Upkeep should be unchanged"
        );
        assertEq(aggregator.getStakeBalance(manager), stakeAmount - slashAmount, "Only stake should be reduced");
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
        emit ISuperGovernor.MinStalenesProposed(newMinStaleness, expectedTime);
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
        emit ISuperGovernor.MinStalenesChanged(newMinStaleness);
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
        vm.prank(sGovernor); // sGovernor has ORACLE_MANAGER_ROLE
        superGovernor.executeOracleUpdate();

        // Verify the mock oracle received the execution call
        assertTrue(mockOracle.oracleUpdateExecuted(), "Oracle update should be executed");
    }

    /// @notice Tests executeOracleUpdate reverts when oracle is not set in registry
    function test_OracleUpdateManagement_ExecuteOracleUpdate_Revert_OracleNotSet() public {
        vm.prank(sGovernor);
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
        vm.prank(sGovernor);
        superGovernor.executeOracleUpdate();
        assertTrue(mockOracle.oracleUpdateExecuted(), "sGovernor should be able to execute oracle update");
    }

    /// @notice Tests executeOracleUpdate can be called without queuing first (depends on oracle implementation)
    function test_OracleUpdateManagement_ExecuteOracleUpdate_WithoutQueue() public {
        MockSuperOracleForStaleness mockOracle = new MockSuperOracleForStaleness();

        bytes32 oracleKey = superGovernor.SUPER_ORACLE();

        vm.prank(sGovernor);
        superGovernor.setAddress(oracleKey, address(mockOracle));

        // Execute without queuing first - this should work with our mock
        vm.prank(sGovernor);
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
        vm.prank(sGovernor);
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

    function test_ExecuteOracleProviderRemoval() public { }

    function test_QueueOracleProviderRemoval() public {
        bytes32[] memory providers = new bytes32[](1);
        providers[0] = keccak256("PROVIDER1");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.queueOracleProviderRemoval(providers);

        // TODO: success flow
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

    mapping(address token => uint256 emergencyPrice) public emergencyPrices;

    function setEmergencyPrice(address token, uint256 emergencyPrice) external {
        emergencyPrices[token] = emergencyPrice;
    }

    function getEmergencyPrice(address token) external view returns (uint256) {
        return emergencyPrices[token];
    }

    mapping(address token => uint256 emergencyPrice) public emergencyPrices;

    function setEmergencyPrice(address token, uint256 emergencyPrice) external {
        emergencyPrices[token] = emergencyPrice;
    }

    function getEmergencyPrice(address token) external view returns (uint256) {
        return emergencyPrices[token];
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
}
