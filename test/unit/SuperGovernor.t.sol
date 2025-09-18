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

contract SuperGovernorTest is PeripheryHelpers {
    SuperGovernor internal superGovernor;

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

    // Role Hashes
    bytes32 internal constant SUPER_GOVERNOR_ROLE = keccak256("SUPER_GOVERNOR_ROLE");
    bytes32 internal constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 internal constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");
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

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, treasury, address(this));

        // Deploy implementation contracts first
        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator =
            address(new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl));
        (, address strategy,) = ISuperVaultAggregator(superVaultAggregator).createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                mainManager: address(this),
                secondaryManagers: new address[](0),
                name: "SUP",
                symbol: "SUP",
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: address(this)
                })
            })
        );
        strategy1 = strategy;
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
        new SuperGovernor(address(0), governor, governor, governor, treasury, address(this));
    }

    /// @notice Tests constructor revert on zero address governor.
    function test_constructor_Revert_ZeroGovernor() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        new SuperGovernor(sGovernor, address(0), governor, governor, treasury, address(this));
    }

    /// @notice Tests constructor revert on zero address treasury.
    function test_constructor_Revert_ZeroTreasury() public {
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        new SuperGovernor(sGovernor, governor, governor, governor, address(0), address(this));
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
        emit ISuperGovernor.AddressSet(TEST_KEY, user);
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
        superGovernor.registerHook(hook1, false);

        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should be registered");
        assertFalse(
            superGovernor.isFulfillRequestsHookRegistered(hook1),
            "Hook should not be registered as fulfill requests hook"
        );
    }

    /// @notice Tests registering a fulfill requests hook
    function test_HookManagement_RegisterFulfillRequestsHook() public {
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.FulfillRequestsHookRegistered(fulfillHook1);
        superGovernor.registerHook(fulfillHook1, true);

        assertTrue(
            superGovernor.isFulfillRequestsHookRegistered(fulfillHook1),
            "Hook should be registered as fulfill requests hook"
        );
        assertTrue(superGovernor.isHookRegistered(fulfillHook1));
    }

    /// @notice Tests reverting when registering a hook with zero address
    function test_HookManagement_Revert_ZeroAddress() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.registerHook(address(0), false);
    }

    /// @notice Tests that registering an already registered hook doesn't emit events
    function test_HookManagement_AlreadyRegistered_NoEvent() public {
        // Register hook first
        vm.prank(governor);
        superGovernor.registerHook(hook1, false);

        // Verify it's registered
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should be registered");

        // Try to register again - should not revert
        vm.prank(governor);
        superGovernor.registerHook(hook1, false);

        // Hook should still be registered
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should still be registered");
    }

    /// @notice Tests that registering an already registered fulfill requests hook doesn't emit events
    function test_HookManagement_FulfillHookAlreadyRegistered_NoEvent() public {
        // Register fulfill hook first
        vm.prank(governor);
        superGovernor.registerHook(fulfillHook1, true);

        // Verify it's registered in both sets
        assertTrue(superGovernor.isHookRegistered(fulfillHook1), "Hook should be registered");
        assertTrue(superGovernor.isFulfillRequestsHookRegistered(fulfillHook1), "Fulfill hook should be registered");

        // Try to register again - should not revert
        vm.prank(governor);
        superGovernor.registerHook(fulfillHook1, true);

        // Hook should still be registered in both sets
        assertTrue(superGovernor.isHookRegistered(fulfillHook1), "Hook should still be registered");
        assertTrue(
            superGovernor.isFulfillRequestsHookRegistered(fulfillHook1), "Fulfill hook should still be registered"
        );
    }

    /// @notice Tests unregistering a hook
    function test_HookManagement_UnregisterHook() public {
        // Register hook first
        vm.prank(governor);
        superGovernor.registerHook(hook1, false);

        // Unregister hook
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.HookRemoved(hook1);
        superGovernor.unregisterHook(hook1);

        assertFalse(superGovernor.isHookRegistered(hook1), "Hook should be unregistered");
    }

    /// @notice Tests unregistering a fulfill requests hook
    function test_HookManagement_UnregisterFulfillRequestsHook() public {
        // Register fulfill hook first
        vm.prank(governor);
        superGovernor.registerHook(fulfillHook1, true);

        // Unregister fulfill hook
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.FulfillRequestsHookUnregistered(fulfillHook1);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.HookRemoved(fulfillHook1);
        superGovernor.unregisterHook(fulfillHook1);
        assertFalse(superGovernor.isHookRegistered(fulfillHook1), "Hook should be unregistered");

        assertFalse(superGovernor.isFulfillRequestsHookRegistered(fulfillHook1), "Fulfill hook should be unregistered");
    }

    /// @notice Tests the fix for the dangerous hook registration behavior where sets can get out of sync
    function test_HookManagement_FixedInvariantMaintenance() public {
        // Test case 1: Register a hook in regular set, then try to register it as fulfill request hook
        // This should work now and not revert
        vm.prank(governor);
        superGovernor.registerHook(hook1, false);
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should be in regular set");
        assertFalse(superGovernor.isFulfillRequestsHookRegistered(hook1), "Hook should not be in fulfill set yet");

        // Now register the same hook as a fulfill request hook - this should work
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.FulfillRequestsHookRegistered(hook1);
        superGovernor.registerHook(hook1, true);

        // Now it should be in both sets
        assertTrue(superGovernor.isHookRegistered(hook1), "Hook should still be in regular set");
        assertTrue(superGovernor.isFulfillRequestsHookRegistered(hook1), "Hook should now be in fulfill set");

        // Test case 2: Unregister should remove from both sets
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.FulfillRequestsHookUnregistered(hook1);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.HookRemoved(hook1);
        superGovernor.unregisterHook(hook1);

        // Should be removed from both sets
        assertFalse(superGovernor.isHookRegistered(hook1), "Hook should be removed from regular set");
        assertFalse(superGovernor.isFulfillRequestsHookRegistered(hook1), "Hook should be removed from fulfill set");

        // Test case 3: Unregistering a hook that's only in regular set should work
        vm.prank(governor);
        superGovernor.registerHook(hook2, false);

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
        superGovernor.registerHook(hook1, false);
        superGovernor.registerHook(hook2, false);
        vm.stopPrank();

        address[] memory hooks = superGovernor.getRegisteredHooks();
        assertEq(hooks.length, 2, "Should have 2 registered hooks");
        assertTrue(hooks[0] == hook1 || hooks[1] == hook1, "hook1 should be in the list");
        assertTrue(hooks[0] == hook2 || hooks[1] == hook2, "hook2 should be in the list");
    }

    /// @notice Tests getting the list of registered fulfill requests hooks
    function test_HookManagement_GetRegisteredFulfillRequestsHooks() public {
        // Register two fulfill hooks
        vm.startPrank(governor);
        superGovernor.registerHook(fulfillHook1, true);
        superGovernor.registerHook(fulfillHook2, true);
        vm.stopPrank();

        address[] memory hooks = superGovernor.getRegisteredFulfillRequestsHooks();
        assertEq(hooks.length, 2, "Should have 2 registered fulfill hooks");
        assertTrue(hooks[0] == fulfillHook1 || hooks[1] == fulfillHook1, "fulfillHook1 should be in the list");
        assertTrue(hooks[0] == fulfillHook2 || hooks[1] == fulfillHook2, "fulfillHook2 should be in the list");
    }

    // =============================================================
    // Validator Management Tests
    // =============================================================

    /// @notice Tests adding a validator
    function test_ValidatorManagement_AddValidator() public {
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ValidatorAdded(validator1);
        superGovernor.addValidator(validator1);

        assertTrue(superGovernor.isValidator(validator1), "Validator should be added");
        address[] memory validators = superGovernor.getValidators();
        assertEq(validators.length, 1, "Should have 1 validator");
        assertEq(validators[0], validator1, "Validator in list should match");
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
        emit ISuperGovernor.ValidatorRemoved(validator1);
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
        vm.expectEmit(true, true, true, false);
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
    // SuperBank Hook Merkle Root Tests
    // =============================================================

    /// @notice Tests proposing a new SuperBank hook merkle root
    function test_MerkleRoot_ProposeMerkleRoot() public {
        // First register the hook
        vm.prank(governor);
        superGovernor.registerHook(hook1, false);

        // Propose a new merkle root
        bytes32 proposedRoot = keccak256("test_root");
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(governor);
        vm.expectEmit(true, true, true, false);
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
        superGovernor.registerHook(hook1, false);

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
        superGovernor.registerHook(hook1, false);

        // Try to execute without a proposal
        vm.expectRevert(ISuperGovernor.NO_PROPOSED_MERKLE_ROOT.selector);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook1);
    }

    /// @notice Tests reverting when executing a merkle root update before timelock expiry
    function test_MerkleRoot_Revert_ExecuteBeforeTimelock() public {
        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(hook1, false);

        // Propose a new merkle root
        bytes32 proposedRoot = keccak256("test_root");
        vm.prank(governor);
        superGovernor.proposeSuperBankHookMerkleRoot(hook1, proposedRoot);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook1);
    }

    // =============================================================
    // Vault Bank Management Tests
    // =============================================================

    /// @notice Tests adding a vault bank successfully
    function test_VaultBankManagement_AddVaultBank() public {
        uint64 chainId = 1;
        address vaultBank = _deployAccount(0x20, "VaultBank1");

        vm.prank(governor);
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.VaultBankAddressAdded(chainId, vaultBank);
        superGovernor.addVaultBank(chainId, vaultBank);

        assertEq(superGovernor.getVaultBank(chainId), vaultBank, "Vault bank address mismatch");
    }

    /// @notice Tests adding multiple vault banks for different chains
    function test_VaultBankManagement_AddMultipleVaultBanks() public {
        uint64 chainId1 = 1;
        uint64 chainId2 = 137;
        address vaultBank1 = _deployAccount(0x20, "VaultBank1");
        address vaultBank2 = _deployAccount(0x21, "VaultBank2");

        vm.startPrank(governor);
        superGovernor.addVaultBank(chainId1, vaultBank1);
        superGovernor.addVaultBank(chainId2, vaultBank2);
        vm.stopPrank();

        assertEq(superGovernor.getVaultBank(chainId1), vaultBank1, "Chain 1 vault bank mismatch");
        assertEq(superGovernor.getVaultBank(chainId2), vaultBank2, "Chain 2 vault bank mismatch");
    }

    /// @notice Tests replacing an existing vault bank for the same chain
    function test_VaultBankManagement_ReplaceVaultBank() public {
        uint64 chainId = 1;
        address oldVaultBank = _deployAccount(0x20, "OldVaultBank");
        address newVaultBank = _deployAccount(0x21, "NewVaultBank");

        // Add initial vault bank
        vm.prank(governor);
        superGovernor.addVaultBank(chainId, oldVaultBank);
        assertEq(superGovernor.getVaultBank(chainId), oldVaultBank, "Initial vault bank not set");

        // Replace with new vault bank
        vm.prank(governor);
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.VaultBankAddressAdded(chainId, newVaultBank);
        superGovernor.addVaultBank(chainId, newVaultBank);

        assertEq(superGovernor.getVaultBank(chainId), newVaultBank, "Vault bank not replaced");
    }

    /// @notice Tests access control - only GOVERNOR_ROLE can add vault banks
    function test_VaultBankManagement_AccessControl() public {
        uint64 chainId = 1;
        address vaultBank = _deployAccount(0x20, "VaultBank");

        // Test with user (should fail)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.addVaultBank(chainId, vaultBank);

        // Test with sGovernor (should fail - needs GOVERNOR_ROLE specifically)
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.addVaultBank(chainId, vaultBank);

        // Test with governor (should succeed)
        vm.prank(governor);
        superGovernor.addVaultBank(chainId, vaultBank);
        assertEq(superGovernor.getVaultBank(chainId), vaultBank, "Governor should be able to add vault bank");
    }

    /// @notice Tests reverting when adding vault bank with zero chain ID
    function test_VaultBankManagement_Revert_ZeroChainId() public {
        address vaultBank = _deployAccount(0x20, "VaultBank");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_CHAIN_ID.selector);
        superGovernor.addVaultBank(0, vaultBank);
    }

    /// @notice Tests reverting when adding vault bank with zero address
    function test_VaultBankManagement_Revert_ZeroVaultBankAddress() public {
        uint64 chainId = 1;

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.addVaultBank(chainId, address(0));
    }

    /// @notice Tests getting vault bank for non-existent chain returns zero address
    function test_VaultBankManagement_GetNonExistentVaultBank() public view {
        uint64 nonExistentChainId = 999;
        address result = superGovernor.getVaultBank(nonExistentChainId);
        assertEq(result, address(0), "Non-existent vault bank should return zero address");
    }

    /// @notice Tests edge case with maximum chain ID
    function test_VaultBankManagement_MaxChainId() public {
        uint64 maxChainId = type(uint64).max;
        address vaultBank = _deployAccount(0x20, "MaxChainVaultBank");

        vm.prank(governor);
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.VaultBankAddressAdded(maxChainId, vaultBank);
        superGovernor.addVaultBank(maxChainId, vaultBank);

        assertEq(superGovernor.getVaultBank(maxChainId), vaultBank, "Max chain ID vault bank mismatch");
    }

    // =============================================================
    // Protected Keeper Registry Tests
    // =============================================================

    /// @notice Tests registering a protected keeper
    function test_ProtectedKeeperRegistry_RegisterProtectedKeeper() public {
        address keeper = _deployAccount(0x30, "ProtectedKeeper1");

        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ProtectedKeeperRegistered(keeper);
        superGovernor.registerProtectedKeeper(keeper);

        assertTrue(superGovernor.isProtectedKeeper(keeper), "Keeper should be registered as protected");

        address[] memory keepers = superGovernor.getProtectedKeepers();
        assertEq(keepers.length, 1, "Should have 1 protected keeper");
        assertEq(keepers[0], keeper, "Keeper in list should match");

        assertEq(superGovernor.getProtectedKeepersCount(), 1, "Count should be 1");
    }

    /// @notice Tests registering multiple protected keepers
    function test_ProtectedKeeperRegistry_RegisterMultipleKeepers() public {
        address keeper1 = _deployAccount(0x30, "ProtectedKeeper1");
        address keeper2 = _deployAccount(0x31, "ProtectedKeeper2");
        address keeper3 = _deployAccount(0x32, "ProtectedKeeper3");

        vm.startPrank(governor);
        superGovernor.registerProtectedKeeper(keeper1);
        superGovernor.registerProtectedKeeper(keeper2);
        superGovernor.registerProtectedKeeper(keeper3);
        vm.stopPrank();

        assertTrue(superGovernor.isProtectedKeeper(keeper1), "Keeper1 should be protected");
        assertTrue(superGovernor.isProtectedKeeper(keeper2), "Keeper2 should be protected");
        assertTrue(superGovernor.isProtectedKeeper(keeper3), "Keeper3 should be protected");

        address[] memory keepers = superGovernor.getProtectedKeepers();
        assertEq(keepers.length, 3, "Should have 3 protected keepers");
        assertEq(superGovernor.getProtectedKeepersCount(), 3, "Count should be 3");

        // Verify all keepers are in the list
        assertTrue(_addressInArray(keepers, keeper1), "keeper1 should be in list");
        assertTrue(_addressInArray(keepers, keeper2), "keeper2 should be in list");
        assertTrue(_addressInArray(keepers, keeper3), "keeper3 should be in list");
    }

    /// @notice Tests reverting when registering with zero address
    function test_ProtectedKeeperRegistry_Revert_ZeroAddress() public {
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.registerProtectedKeeper(address(0));
    }

    /// @notice Tests reverting when registering already registered keeper
    function test_ProtectedKeeperRegistry_Revert_AlreadyRegistered() public {
        address keeper = _deployAccount(0x30, "ProtectedKeeper1");

        // Register keeper first
        vm.prank(governor);
        superGovernor.registerProtectedKeeper(keeper);

        // Try to register again
        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.KEEPER_ALREADY_REGISTERED.selector);
        superGovernor.registerProtectedKeeper(keeper);
    }

    /// @notice Tests access control for registerProtectedKeeper
    function test_ProtectedKeeperRegistry_RegisterAccessControl() public {
        address keeper = _deployAccount(0x30, "ProtectedKeeper1");

        // Test with user (should fail)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.registerProtectedKeeper(keeper);

        // Test with sGovernor (should fail - needs GOVERNOR_ROLE specifically)
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.registerProtectedKeeper(keeper);

        // Test with governor (should succeed)
        vm.prank(governor);
        superGovernor.registerProtectedKeeper(keeper);
        assertTrue(superGovernor.isProtectedKeeper(keeper), "Governor should be able to register keeper");
    }

    /// @notice Tests unregistering a protected keeper
    function test_ProtectedKeeperRegistry_UnregisterProtectedKeeper() public {
        address keeper = _deployAccount(0x30, "ProtectedKeeper1");

        // Register keeper first
        vm.prank(governor);
        superGovernor.registerProtectedKeeper(keeper);
        assertTrue(superGovernor.isProtectedKeeper(keeper), "Keeper should be registered");

        // Unregister keeper
        vm.prank(governor);
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.ProtectedKeeperUnregistered(keeper);
        superGovernor.unregisterProtectedKeeper(keeper);

        assertFalse(superGovernor.isProtectedKeeper(keeper), "Keeper should no longer be protected");

        address[] memory keepers = superGovernor.getProtectedKeepers();
        assertEq(keepers.length, 0, "Should have 0 protected keepers");
        assertEq(superGovernor.getProtectedKeepersCount(), 0, "Count should be 0");
    }

    /// @notice Tests reverting when unregistering non-existent keeper
    function test_ProtectedKeeperRegistry_Revert_UnregisterNotRegistered() public {
        address keeper = _deployAccount(0x30, "ProtectedKeeper1");

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.KEEPER_NOT_REGISTERED.selector);
        superGovernor.unregisterProtectedKeeper(keeper);
    }

    /// @notice Tests access control for unregisterProtectedKeeper
    function test_ProtectedKeeperRegistry_UnregisterAccessControl() public {
        address keeper = _deployAccount(0x30, "ProtectedKeeper1");

        // Register keeper first
        vm.prank(governor);
        superGovernor.registerProtectedKeeper(keeper);

        // Test with user (should fail)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.unregisterProtectedKeeper(keeper);

        // Test with sGovernor (should fail - needs GOVERNOR_ROLE specifically)
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.unregisterProtectedKeeper(keeper);

        // Verify keeper is still registered
        assertTrue(superGovernor.isProtectedKeeper(keeper), "Keeper should still be protected");

        // Test with governor (should succeed)
        vm.prank(governor);
        superGovernor.unregisterProtectedKeeper(keeper);
        assertFalse(superGovernor.isProtectedKeeper(keeper), "Governor should be able to unregister keeper");
    }

    /// @notice Tests unregistering keeper when multiple keepers exist
    function test_ProtectedKeeperRegistry_UnregisterWithMultiple() public {
        address keeper1 = _deployAccount(0x30, "ProtectedKeeper1");
        address keeper2 = _deployAccount(0x31, "ProtectedKeeper2");
        address keeper3 = _deployAccount(0x32, "ProtectedKeeper3");

        // Register all keepers
        vm.startPrank(governor);
        superGovernor.registerProtectedKeeper(keeper1);
        superGovernor.registerProtectedKeeper(keeper2);
        superGovernor.registerProtectedKeeper(keeper3);
        vm.stopPrank();

        // Unregister middle keeper
        vm.prank(governor);
        superGovernor.unregisterProtectedKeeper(keeper2);

        // Verify states
        assertTrue(superGovernor.isProtectedKeeper(keeper1), "Keeper1 should still be protected");
        assertFalse(superGovernor.isProtectedKeeper(keeper2), "Keeper2 should no longer be protected");
        assertTrue(superGovernor.isProtectedKeeper(keeper3), "Keeper3 should still be protected");

        address[] memory keepers = superGovernor.getProtectedKeepers();
        assertEq(keepers.length, 2, "Should have 2 protected keepers remaining");
        assertEq(superGovernor.getProtectedKeepersCount(), 2, "Count should be 2");

        // Verify remaining keepers are in the list
        assertTrue(_addressInArray(keepers, keeper1), "keeper1 should still be in list");
        assertFalse(_addressInArray(keepers, keeper2), "keeper2 should not be in list");
        assertTrue(_addressInArray(keepers, keeper3), "keeper3 should still be in list");
    }

    /// @notice Tests checking non-existent keeper
    function test_ProtectedKeeperRegistry_IsProtectedKeeperFalse() public {
        address keeper = _deployAccount(0x30, "ProtectedKeeper1");
        assertFalse(superGovernor.isProtectedKeeper(keeper), "Non-registered keeper should return false");
    }

    /// @notice Tests getting empty keeper list initially
    function test_ProtectedKeeperRegistry_EmptyListInitially() public view {
        address[] memory keepers = superGovernor.getProtectedKeepers();
        assertEq(keepers.length, 0, "Should start with empty keeper list");
        assertEq(superGovernor.getProtectedKeepersCount(), 0, "Count should start at 0");
    }

    // =============================================================
    // Incentive Token Management Tests
    // =============================================================

    /// @notice Tests proposing to add incentive tokens
    function test_IncentiveTokenManagement_ProposeAddIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(governor);
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.WhitelistedIncentiveTokensProposed(tokens, expectedTime);
        superGovernor.proposeAddIncentiveTokens(tokens);

        // Check that tokens are in proposed state (not yet whitelisted)
        assertFalse(superGovernor.isWhitelistedIncentiveToken(token1), "Token1 should not be whitelisted yet");
        assertFalse(superGovernor.isWhitelistedIncentiveToken(token2), "Token2 should not be whitelisted yet");
    }

    /// @notice Tests reverting when proposing to add incentive tokens with zero address
    function test_IncentiveTokenManagement_Revert_ProposeAddZeroAddress() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.proposeAddIncentiveTokens(tokens);
    }

    /// @notice Tests executing addition of incentive tokens after timelock
    function test_IncentiveTokenManagement_ExecuteAddIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        // Propose the tokens
        vm.prank(governor);
        superGovernor.proposeAddIncentiveTokens(tokens);

        // Warp to after timelock
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the addition
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.WhitelistedIncentiveTokensAdded(tokens);
        superGovernor.executeAddIncentiveTokens();

        // Verify tokens are now whitelisted
        assertTrue(superGovernor.isWhitelistedIncentiveToken(token1), "Token1 should be whitelisted");
        assertTrue(superGovernor.isWhitelistedIncentiveToken(token2), "Token2 should be whitelisted");
    }

    /// @notice Tests reverting when executing add without proposal
    function test_IncentiveTokenManagement_Revert_ExecuteAddNoProposal() public {
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeAddIncentiveTokens();
    }

    /// @notice Tests reverting when executing add before timelock expiry
    function test_IncentiveTokenManagement_Revert_ExecuteAddBeforeTimelock() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x111);

        // Propose the tokens
        vm.prank(governor);
        superGovernor.proposeAddIncentiveTokens(tokens);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeAddIncentiveTokens();
    }

    /// @notice Tests proposing to remove incentive tokens
    function test_IncentiveTokenManagement_ProposeRemoveIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        // First add the tokens
        vm.prank(governor);
        superGovernor.proposeAddIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);
        superGovernor.executeAddIncentiveTokens();

        // Now propose to remove them
        vm.warp(block.timestamp + 1); // Move time forward slightly
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(governor);
        vm.expectEmit(true, true, false, false);
        emit ISuperGovernor.WhitelistedIncentiveTokensProposed(tokens, expectedTime);
        superGovernor.proposeRemoveIncentiveTokens(tokens);

        // Tokens should still be whitelisted until execution
        assertTrue(superGovernor.isWhitelistedIncentiveToken(token1), "Token1 should still be whitelisted");
        assertTrue(superGovernor.isWhitelistedIncentiveToken(token2), "Token2 should still be whitelisted");
    }

    /// @notice Tests reverting when proposing to remove non-whitelisted tokens
    function test_IncentiveTokenManagement_Revert_ProposeRemoveNotWhitelisted() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x111);

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.NOT_WHITELISTED_INCENTIVE_TOKEN.selector);
        superGovernor.proposeRemoveIncentiveTokens(tokens);
    }

    /// @notice Tests reverting when proposing to remove incentive tokens with zero address
    function test_IncentiveTokenManagement_Revert_ProposeRemoveZeroAddress() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        vm.prank(governor);
        vm.expectRevert(ISuperGovernor.INVALID_ADDRESS.selector);
        superGovernor.proposeRemoveIncentiveTokens(tokens);
    }

    /// @notice Tests executing removal of incentive tokens after timelock
    function test_IncentiveTokenManagement_ExecuteRemoveIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        // First add the tokens
        vm.prank(governor);
        superGovernor.proposeAddIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);
        superGovernor.executeAddIncentiveTokens();

        // Now propose and execute removal
        vm.warp(block.timestamp + 1);
        vm.prank(governor);
        superGovernor.proposeRemoveIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the removal
        vm.expectEmit(true, false, false, false);
        emit ISuperGovernor.WhitelistedIncentiveTokensRemoved(tokens);
        superGovernor.executeRemoveIncentiveTokens();

        // Verify tokens are no longer whitelisted
        assertFalse(superGovernor.isWhitelistedIncentiveToken(token1), "Token1 should not be whitelisted");
        assertFalse(superGovernor.isWhitelistedIncentiveToken(token2), "Token2 should not be whitelisted");
    }

    /// @notice Tests reverting when executing remove without proposal
    function test_IncentiveTokenManagement_Revert_ExecuteRemoveNoProposal() public {
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeRemoveIncentiveTokens();
    }

    /// @notice Tests reverting when executing remove before timelock expiry
    function test_IncentiveTokenManagement_Revert_ExecuteRemoveBeforeTimelock() public {
        address token1 = address(0x111);
        address[] memory tokens = new address[](1);
        tokens[0] = token1;

        // First add the token
        vm.prank(governor);
        superGovernor.proposeAddIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);
        superGovernor.executeAddIncentiveTokens();

        // Propose removal
        vm.warp(block.timestamp + 1);
        vm.prank(governor);
        superGovernor.proposeRemoveIncentiveTokens(tokens);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperGovernor.TIMELOCK_NOT_EXPIRED.selector);
        superGovernor.executeRemoveIncentiveTokens();
    }

    /// @notice Tests access control for proposing incentive token changes
    function test_IncentiveTokenManagement_AccessControl() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x111);

        // Test proposeAddIncentiveTokens with non-governor role
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.proposeAddIncentiveTokens(tokens);

        // Test proposeRemoveIncentiveTokens with non-governor role
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, GOVERNOR_ROLE)
        );
        superGovernor.proposeRemoveIncentiveTokens(tokens);

        // Test with superGovernor role (should fail - needs GOVERNOR_ROLE specifically)
        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.proposeAddIncentiveTokens(tokens);

        vm.prank(sGovernor);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, sGovernor, GOVERNOR_ROLE)
        );
        superGovernor.proposeRemoveIncentiveTokens(tokens);
    }

    /// @notice Tests that execution functions are public (can be called by anyone)
    function test_IncentiveTokenManagement_PublicExecution() public {
        address token1 = address(0x111);
        address[] memory tokens = new address[](1);
        tokens[0] = token1;

        // Propose as governor
        vm.prank(governor);
        superGovernor.proposeAddIncentiveTokens(tokens);

        // Execute as regular user (should work)
        vm.warp(block.timestamp + TIMELOCK + 1);
        vm.prank(user);
        superGovernor.executeAddIncentiveTokens();

        assertTrue(superGovernor.isWhitelistedIncentiveToken(token1), "Token should be whitelisted");

        // Same for removal
        vm.warp(block.timestamp + 1);
        vm.prank(governor);
        superGovernor.proposeRemoveIncentiveTokens(tokens);

        vm.warp(block.timestamp + TIMELOCK + 1);
        vm.prank(user);
        superGovernor.executeRemoveIncentiveTokens();

        assertFalse(superGovernor.isWhitelistedIncentiveToken(token1), "Token should not be whitelisted");
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

    function setMaxStaleness(uint256 newMaxStaleness) external {
        lastMaxStaleness = newMaxStaleness;
    }

    function setFeedMaxStaleness(address feed, uint256 newMaxStaleness) external {
        lastFeed = feed;
        lastFeedStaleness = newMaxStaleness;
    }

    function setFeedMaxStalenessBatch(address[] calldata, uint256[] calldata) external {
        batchCalled = true;
    }
}
