// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Vm } from "forge-std/Vm.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { SuperVaultExecutor } from "../../src/SuperVault/SuperVaultExecutor.sol";
import { ISuperVaultExecutor } from "../../src/interfaces/SuperVault/ISuperVaultExecutor.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";

/// @title SuperVaultExecutorTest
/// @notice Unit tests for SuperVaultExecutor contract
contract SuperVaultExecutorTest is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    SuperVaultExecutor internal superVaultManager;
    MockERC20 internal asset;

    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal user;
    address internal manager;
    address internal admin;
    address internal sessionKey;
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
        sessionKey = _deployAccount(0x7, "SessionKey");
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

        // Deploy SuperVaultExecutor
        superVaultManager = new SuperVaultExecutor(address(superGovernor), admin);

        // Add SuperVaultExecutor as secondary manager
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(address(strategy), address(superVaultManager));
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_SetsImmutables() public view {
        assertEq(address(superVaultManager.SUPER_GOVERNOR()), address(superGovernor));
        assertTrue(superVaultManager.hasRole(superVaultManager.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_Constructor_RevertsOnZeroSuperGovernor() public {
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        new SuperVaultExecutor(address(0), admin);
    }

    function test_Constructor_RevertsOnZeroAdmin() public {
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        new SuperVaultExecutor(address(superGovernor), address(0));
    }

    function test_MaxBatchSize() public view {
        assertEq(superVaultManager.MAX_BATCH_SIZE(), 50);
    }

    /*//////////////////////////////////////////////////////////////
                    GRANT SESSION KEY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GrantSessionKey_Success() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultExecutor.SessionKeyGranted(address(strategy), sessionKey, expiry, manager, 0);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        (uint256 storedExpiry, address grantedBy, uint256 gen) =
            superVaultManager.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, expiry);
        assertEq(grantedBy, manager);
        assertEq(gen, 0);
    }

    function test_GrantSessionKey_RevertsNotPrimaryManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
    }

    function test_GrantSessionKey_RevertsZeroSessionKey() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        superVaultManager.grantSessionKey(address(strategy), address(0), block.timestamp + 1 days);
    }

    function test_GrantSessionKey_RevertsZeroExpiry() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_EXPIRY.selector);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, 0);
    }

    function test_GrantSessionKey_RevertsExpiryInPast() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EXPIRY_IN_PAST.selector);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                    GRANT SESSION KEYS BATCH TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GrantSessionKeysBatch_Success() public {
        address sessionKey2 = makeAddr("sessionKey2");
        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey2;
        uint256[] memory expiries = new uint256[](2);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 2 days;

        vm.prank(manager);
        superVaultManager.grantSessionKeysBatch(strategies, keys, expiries);

        (uint256 e1,,) = superVaultManager.getSessionKeyData(address(strategy), sessionKey);
        (uint256 e2,,) = superVaultManager.getSessionKeyData(address(strategy), sessionKey2);
        assertEq(e1, block.timestamp + 1 days);
        assertEq(e2, block.timestamp + 2 days);
    }

    function test_GrantSessionKeysBatch_RevertsEmptyArray() public {
        address[] memory strategies = new address[](0);
        address[] memory keys = new address[](0);
        uint256[] memory expiries = new uint256[](0);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EMPTY_ARRAY.selector);
        superVaultManager.grantSessionKeysBatch(strategies, keys, expiries);
    }

    function test_GrantSessionKeysBatch_RevertsBatchSizeExceeded() public {
        uint256 size = superVaultManager.MAX_BATCH_SIZE() + 1;
        address[] memory strategies = new address[](size);
        address[] memory keys = new address[](size);
        uint256[] memory expiries = new uint256[](size);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.BATCH_SIZE_EXCEEDED.selector);
        superVaultManager.grantSessionKeysBatch(strategies, keys, expiries);
    }

    function test_GrantSessionKeysBatch_RevertsArrayLengthMismatch() public {
        address[] memory strategies = new address[](2);
        address[] memory keys = new address[](1);
        uint256[] memory expiries = new uint256[](2);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultManager.grantSessionKeysBatch(strategies, keys, expiries);
    }

    function test_GrantSessionKeysBatch_RevertsNotPrimaryManager() public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(strategy);
        address[] memory keys = new address[](1);
        keys[0] = sessionKey;
        uint256[] memory expiries = new uint256[](1);
        expiries[0] = block.timestamp + 1 days;

        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultManager.grantSessionKeysBatch(strategies, keys, expiries);
    }

    /*//////////////////////////////////////////////////////////////
                    REVOKE SESSION KEY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevokeSessionKey_Success() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.expectEmit(true, true, false, false);
        emit ISuperVaultExecutor.SessionKeyRevoked(address(strategy), sessionKey);
        superVaultManager.revokeSessionKey(address(strategy), sessionKey);
        vm.stopPrank();

        (uint256 storedExpiry, address grantedBy, uint256 gen) =
            superVaultManager.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
    }

    function test_RevokeSessionKey_NoOpForNonExistentKey() public {
        // Revoking a key that was never granted is a no-op (no event emitted)
        vm.prank(manager);
        vm.recordLogs();
        superVaultManager.revokeSessionKey(address(strategy), sessionKey);

        // No SessionKeyRevoked event should be emitted
        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i; i < entries.length; ++i) {
            assertTrue(
                entries[i].topics[0] != ISuperVaultExecutor.SessionKeyRevoked.selector,
                "Should not emit SessionKeyRevoked for non-existent key"
            );
        }
    }

    function test_RevokeSessionKey_RevertsNotPrimaryManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultManager.revokeSessionKey(address(strategy), sessionKey);
    }

    /*//////////////////////////////////////////////////////////////
                    REVOKE SESSION KEYS BATCH TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevokeSessionKeysBatch_Success() public {
        address sessionKey2 = makeAddr("sessionKey2");

        vm.startPrank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        superVaultManager.grantSessionKey(address(strategy), sessionKey2, block.timestamp + 1 days);

        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey2;

        superVaultManager.revokeSessionKeysBatch(strategies, keys);
        vm.stopPrank();

        (uint256 e1,,) = superVaultManager.getSessionKeyData(address(strategy), sessionKey);
        (uint256 e2,,) = superVaultManager.getSessionKeyData(address(strategy), sessionKey2);
        assertEq(e1, 0);
        assertEq(e2, 0);
    }

    function test_RevokeSessionKeysBatch_RevertsEmptyArray() public {
        address[] memory strategies = new address[](0);
        address[] memory keys = new address[](0);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EMPTY_ARRAY.selector);
        superVaultManager.revokeSessionKeysBatch(strategies, keys);
    }

    function test_RevokeSessionKeysBatch_RevertsBatchSizeExceeded() public {
        uint256 size = superVaultManager.MAX_BATCH_SIZE() + 1;
        address[] memory strategies = new address[](size);
        address[] memory keys = new address[](size);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.BATCH_SIZE_EXCEEDED.selector);
        superVaultManager.revokeSessionKeysBatch(strategies, keys);
    }

    function test_RevokeSessionKeysBatch_RevertsArrayLengthMismatch() public {
        address[] memory strategies = new address[](2);
        address[] memory keys = new address[](1);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultManager.revokeSessionKeysBatch(strategies, keys);
    }

    function test_RevokeSessionKeysBatch_RevertsNotPrimaryManager() public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(strategy);
        address[] memory keys = new address[](1);
        keys[0] = sessionKey;

        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultManager.revokeSessionKeysBatch(strategies, keys);
    }

    /*//////////////////////////////////////////////////////////////
                    INVALIDATE ALL SESSION KEYS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_InvalidateAllSessionKeys_Success() public {
        assertEq(superVaultManager.getStrategyGeneration(address(strategy)), 0);

        vm.prank(manager);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultExecutor.AllSessionKeysInvalidated(address(strategy), 1);
        superVaultManager.invalidateAllSessionKeys(address(strategy));

        assertEq(superVaultManager.getStrategyGeneration(address(strategy)), 1);
    }

    function test_InvalidateAllSessionKeys_InvalidatesExistingKeys() public {
        // Grant keys
        vm.startPrank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Invalidate all
        superVaultManager.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        // Key is now invalid due to generation mismatch
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Forwarding function reverts with generation mismatch
        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_GENERATION_MISMATCH.selector);
        superVaultManager.executeHooks(address(strategy), args);
    }

    function test_InvalidateAllSessionKeys_NewKeysUseNewGeneration() public {
        vm.startPrank(manager);

        // Grant at generation 0
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        (,, uint256 gen0) = superVaultManager.getSessionKeyData(address(strategy), sessionKey);
        assertEq(gen0, 0);

        // Bump generation
        superVaultManager.invalidateAllSessionKeys(address(strategy));

        // Re-grant at generation 1
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        (,, uint256 gen1) = superVaultManager.getSessionKeyData(address(strategy), sessionKey);
        assertEq(gen1, 1);

        vm.stopPrank();

        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_InvalidateAllSessionKeys_RevertsNotPrimaryManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultManager.invalidateAllSessionKeys(address(strategy));
    }

    function test_InvalidateAllSessionKeys_FixesZombieKeyReactivation() public {
        // Grant key under manager A
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 7 days);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Manager changes A -> B (key becomes invalid via PRIMARY_MANAGER_CHANGED)
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // New manager invalidates all keys (bumps generation as a precaution)
        vm.prank(newManager);
        superVaultManager.invalidateAllSessionKeys(address(strategy));

        // Manager reverts B -> A
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), manager, manager);

        // Without generation counter, the old key would reactivate here.
        // With generation counter, it stays invalid because generation doesn't match.
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Manager A must explicitly re-grant
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 7 days);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                    SWEEP ETH TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SweepETH_Success() public {
        vm.deal(address(superVaultManager), 5 ether);

        address recipient = makeAddr("recipient");
        vm.prank(admin);
        superVaultManager.sweepETH(recipient);

        assertEq(address(superVaultManager).balance, 0);
        assertEq(recipient.balance, 5 ether);
    }

    function test_SweepETH_NoOpWhenNoBalance() public {
        address recipient = makeAddr("recipient");
        vm.prank(admin);
        superVaultManager.sweepETH(recipient);
        assertEq(recipient.balance, 0);
    }

    function test_SweepETH_RevertsNotAdmin() public {
        vm.deal(address(superVaultManager), 1 ether);

        bytes32 adminRole = superVaultManager.DEFAULT_ADMIN_ROLE();
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, adminRole)
        );
        superVaultManager.sweepETH(makeAddr("recipient"));
    }

    function test_SweepETH_RevertsZeroAddress() public {
        vm.deal(address(superVaultManager), 1 ether);
        vm.prank(admin);
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        superVaultManager.sweepETH(address(0));
    }

    function test_SweepETH_RevertsWhenRecipientRejectsETH() public {
        vm.deal(address(superVaultManager), 1 ether);
        ETHRejecter rejecter = new ETHRejecter();

        vm.prank(admin);
        vm.expectRevert(ISuperVaultExecutor.ETH_REFUND_FAILED.selector);
        superVaultManager.sweepETH(address(rejecter));
    }

    /*//////////////////////////////////////////////////////////////
                    SESSION KEY VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_IsSessionKeyValid_ReturnsTrueForValidKey() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseForExpiredKey() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.warp(block.timestamp + 1 days + 1);

        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseForUnauthorizedKey() public view {
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseWhenPrimaryManagerChanged() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        // Change primary manager via SuperGovernor
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseAfterGenerationBump() public {
        vm.startPrank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        superVaultManager.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                FORWARDING VALIDATION REVERT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ExecuteHooks_RevertsSessionKeyNotAuthorized() public {
        ISuperVaultStrategy.ExecuteArgs memory args;

        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.executeHooks(address(strategy), args);
    }

    function test_ExecuteHooks_RevertsSessionKeyExpired() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.warp(block.timestamp + 1 days + 1);

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultManager.executeHooks(address(strategy), args);
    }

    function test_ExecuteHooks_RevertsSessionKeyGenerationMismatch() public {
        vm.startPrank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        superVaultManager.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_GENERATION_MISMATCH.selector);
        superVaultManager.executeHooks(address(strategy), args);
    }

    function test_ExecuteHooks_RevertsPrimaryManagerChanged() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        // Change primary manager
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.PRIMARY_MANAGER_CHANGED.selector);
        superVaultManager.executeHooks(address(strategy), args);
    }

    function test_FulfillCancelRedeemRequests_RevertsSessionKeyNotAuthorized() public {
        address[] memory controllers = new address[](0);
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.fulfillCancelRedeemRequests(address(strategy), controllers);
    }

    function test_FulfillRedeemRequests_RevertsSessionKeyNotAuthorized() public {
        address[] memory controllers = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.fulfillRedeemRequests(address(strategy), controllers, amounts);
    }

    function test_SkimPerformanceFee_RevertsSessionKeyNotAuthorized() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.skimPerformanceFee(address(strategy));
    }

    function test_PauseStrategy_RevertsSessionKeyNotAuthorized() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.pauseStrategy(address(strategy));
    }

    function test_UnpauseStrategy_RevertsSessionKeyNotAuthorized() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.unpauseStrategy(address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                    PAUSE/UNPAUSE FORWARDING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PauseStrategy_ForwardsSuccessfully() public {
        uint256 expiry = block.timestamp + 1 days;
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));

        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    function test_UnpauseStrategy_ForwardsSuccessfully() public {
        uint256 expiry = block.timestamp + 1 days;
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        // Pause first
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Unpause
        vm.prank(sessionKey);
        superVaultManager.unpauseStrategy(address(strategy));
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    /*//////////////////////////////////////////////////////////////
                    ETH REFUND TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReceiveETH() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(superVaultManager).call{ value: 1 ether }("");
        assertTrue(success);
        assertEq(address(superVaultManager).balance, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    STRATEGY GENERATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetStrategyGeneration_DefaultsToZero() public view {
        assertEq(superVaultManager.getStrategyGeneration(address(strategy)), 0);
    }

    function test_GetStrategyGeneration_IncrementsOnInvalidate() public {
        vm.startPrank(manager);
        superVaultManager.invalidateAllSessionKeys(address(strategy));
        assertEq(superVaultManager.getStrategyGeneration(address(strategy)), 1);
        superVaultManager.invalidateAllSessionKeys(address(strategy));
        assertEq(superVaultManager.getStrategyGeneration(address(strategy)), 2);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_ExpiredKeysAlwaysRevert(uint256 expiryOffset) public {
        // Ensure offset is at least 1 so the key is initially valid
        expiryOffset = bound(expiryOffset, 1, 365 days);
        uint256 expiry = block.timestamp + expiryOffset;

        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        // Warp past expiry
        vm.warp(expiry + 1);

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultManager.executeHooks(address(strategy), args);
    }

    function testFuzz_ValidKeysPassValidation(uint256 expiryOffset) public {
        expiryOffset = bound(expiryOffset, 1, 365 days);
        uint256 expiry = block.timestamp + expiryOffset;

        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    function testFuzz_GrantRevokeGrant(uint256 expiry1, uint256 expiry2) public {
        expiry1 = bound(expiry1, block.timestamp + 1, block.timestamp + 365 days);
        expiry2 = bound(expiry2, block.timestamp + 1, block.timestamp + 365 days);

        vm.startPrank(manager);

        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry1);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        superVaultManager.revokeSessionKey(address(strategy), sessionKey);
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry2);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        vm.stopPrank();
    }

    function testFuzz_GenerationBumpInvalidatesAllKeys(uint8 numKeys, uint8 numBumps) public {
        numKeys = uint8(bound(numKeys, 1, 10));
        numBumps = uint8(bound(numBumps, 1, 5));

        // Grant multiple keys
        vm.startPrank(manager);
        for (uint256 i; i < numKeys; ++i) {
            address key = address(uint160(0x1000 + i));
            superVaultManager.grantSessionKey(address(strategy), key, block.timestamp + 1 days);
            assertTrue(superVaultManager.isSessionKeyValid(address(strategy), key));
        }

        // Bump generation
        for (uint256 i; i < numBumps; ++i) {
            superVaultManager.invalidateAllSessionKeys(address(strategy));
        }
        vm.stopPrank();

        // All keys should be invalid
        for (uint256 i; i < numKeys; ++i) {
            address key = address(uint160(0x1000 + i));
            assertFalse(superVaultManager.isSessionKeyValid(address(strategy), key));
        }
    }
}

/// @dev Helper contract that rejects ETH transfers (used for refund failure tests)
contract ETHRejecter {
    receive() external payable {
        revert("no ETH");
    }
}
