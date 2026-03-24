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
    SuperVaultExecutor internal superVaultExecutor;
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
        superVaultExecutor = new SuperVaultExecutor(address(superGovernor), admin);

        // Add SuperVaultExecutor as secondary manager
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(address(strategy), address(superVaultExecutor));
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_SetsImmutables() public view {
        assertEq(address(superVaultExecutor.SUPER_GOVERNOR()), address(superGovernor));
        assertTrue(superVaultExecutor.hasRole(superVaultExecutor.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_Constructor_RevertsOnZeroSuperGovernor() public {
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        new SuperVaultExecutor(address(0), admin);
    }

    function test_Constructor_RevertsOnZeroAdmin() public {
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        new SuperVaultExecutor(address(superGovernor), address(0));
    }

    function test_Constructor_CachesAggregatorKey() public view {
        assertEq(superVaultExecutor.SUPER_VAULT_AGGREGATOR_KEY(), superGovernor.SUPER_VAULT_AGGREGATOR());
    }

    function test_MaxBatchSize() public view {
        assertEq(superVaultExecutor.MAX_BATCH_SIZE(), 50);
    }

    /*//////////////////////////////////////////////////////////////
                    GRANT SESSION KEY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GrantSessionKey_Success() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultExecutor.SessionKeyGranted(address(strategy), sessionKey, expiry, manager, 0);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        (uint256 storedExpiry, address grantedBy, uint96 gen) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, expiry);
        assertEq(grantedBy, manager);
        assertEq(gen, 0);
    }

    function test_GrantSessionKey_RevertsNotPrimaryManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
    }

    function test_GrantSessionKey_RevertsZeroSessionKey() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        superVaultExecutor.grantSessionKey(address(strategy), address(0), block.timestamp + 1 days);
    }

    function test_GrantSessionKey_RevertsZeroExpiry() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_EXPIRY.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, 0);
    }

    function test_GrantSessionKey_RevertsExpiryInPast() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EXPIRY_IN_PAST.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp);
    }

    function test_GrantSessionKey_OverwritesExistingKey() public {
        uint256 expiry1 = block.timestamp + 1 days;
        uint256 expiry2 = block.timestamp + 7 days;

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry1);
        (uint256 e1,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(e1, expiry1);

        // Overwrite with new expiry
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry2);
        (uint256 e2,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(e2, expiry2);
        vm.stopPrank();
    }

    function test_GrantSessionKey_MaxExpiry_NeverExpires() public {
        uint256 maxExpiry = type(uint256).max;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, maxExpiry);

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // Still valid far in the future
        vm.warp(block.timestamp + 365 days * 100);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_GrantSessionKey_RevertsExpiryEqualToTimestamp() public {
        // expiry <= block.timestamp reverts, so expiry == block.timestamp should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EXPIRY_IN_PAST.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp);
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
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);

        (uint256 e1,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        (uint256 e2,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey2);
        assertEq(e1, block.timestamp + 1 days);
        assertEq(e2, block.timestamp + 2 days);
    }

    function test_GrantSessionKeysBatch_RevertsEmptyArray() public {
        address[] memory strategies = new address[](0);
        address[] memory keys = new address[](0);
        uint256[] memory expiries = new uint256[](0);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EMPTY_ARRAY.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);
    }

    function test_GrantSessionKeysBatch_RevertsBatchSizeExceeded() public {
        uint256 size = superVaultExecutor.MAX_BATCH_SIZE() + 1;
        address[] memory strategies = new address[](size);
        address[] memory keys = new address[](size);
        uint256[] memory expiries = new uint256[](size);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.BATCH_SIZE_EXCEEDED.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);
    }

    function test_GrantSessionKeysBatch_RevertsArrayLengthMismatch() public {
        address[] memory strategies = new address[](2);
        address[] memory keys = new address[](1);
        uint256[] memory expiries = new uint256[](2);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);
    }

    function test_GrantSessionKeysBatch_RevertsOnZeroSessionKeyInBatch() public {
        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = address(0); // zero address in second element
        uint256[] memory expiries = new uint256[](2);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 1 days;

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);
    }

    function test_GrantSessionKeysBatch_AtExactlyMaxBatchSize() public {
        uint256 size = superVaultExecutor.MAX_BATCH_SIZE(); // 50
        address[] memory strategies = new address[](size);
        address[] memory keys = new address[](size);
        uint256[] memory expiries = new uint256[](size);

        for (uint256 i; i < size; ++i) {
            strategies[i] = address(strategy);
            keys[i] = address(uint160(0x2000 + i));
            expiries[i] = block.timestamp + 1 days;
        }

        vm.prank(manager);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);

        // Verify first and last
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), address(uint160(0x2000))));
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), address(uint160(0x2000 + size - 1))));
    }

    function test_GrantSessionKeysBatch_RevertsExpiriesMismatch() public {
        address[] memory strategies = new address[](2);
        address[] memory keys = new address[](2);
        uint256[] memory expiries = new uint256[](1); // mismatch

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);
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
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries);
    }

    /*//////////////////////////////////////////////////////////////
                    REVOKE SESSION KEY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevokeSessionKey_Success() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.expectEmit(true, true, false, false);
        emit ISuperVaultExecutor.SessionKeyRevoked(address(strategy), sessionKey);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        vm.stopPrank();

        (uint256 storedExpiry, address grantedBy, uint96 gen) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
    }

    function test_RevokeSessionKey_RevertsForNonExistentKey() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
    }

    function test_RevokeSessionKey_DoubleRevokeReverts() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);

        // Second revoke should revert (expiry is 0 after delete)
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        vm.stopPrank();
    }

    function test_RevokeSessionKey_RevertsNotPrimaryManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
    }

    /*//////////////////////////////////////////////////////////////
                    REVOKE SESSION KEYS BATCH TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevokeSessionKeysBatch_Success() public {
        address sessionKey2 = makeAddr("sessionKey2");

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey2, block.timestamp + 1 days);

        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey2;

        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
        vm.stopPrank();

        (uint256 e1,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        (uint256 e2,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey2);
        assertEq(e1, 0);
        assertEq(e2, 0);
    }

    function test_RevokeSessionKeysBatch_RevertsEmptyArray() public {
        address[] memory strategies = new address[](0);
        address[] memory keys = new address[](0);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EMPTY_ARRAY.selector);
        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
    }

    function test_RevokeSessionKeysBatch_RevertsBatchSizeExceeded() public {
        uint256 size = superVaultExecutor.MAX_BATCH_SIZE() + 1;
        address[] memory strategies = new address[](size);
        address[] memory keys = new address[](size);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.BATCH_SIZE_EXCEEDED.selector);
        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
    }

    function test_RevokeSessionKeysBatch_RevertsArrayLengthMismatch() public {
        address[] memory strategies = new address[](2);
        address[] memory keys = new address[](1);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
    }

    function test_RevokeSessionKeysBatch_RevertsIfOneKeyNotGranted() public {
        address sessionKey2 = makeAddr("sessionKey2");

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        // sessionKey2 never granted

        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey2;

        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
        vm.stopPrank();
    }

    function test_RevokeSessionKeysBatch_RevertsNotPrimaryManager() public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(strategy);
        address[] memory keys = new address[](1);
        keys[0] = sessionKey;

        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
    }

    /*//////////////////////////////////////////////////////////////
                    INVALIDATE ALL SESSION KEYS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_InvalidateAllSessionKeys_Success() public {
        assertEq(superVaultExecutor.getStrategyGeneration(address(strategy)), 0);

        vm.prank(manager);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultExecutor.AllSessionKeysInvalidated(address(strategy), 1);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));

        assertEq(superVaultExecutor.getStrategyGeneration(address(strategy)), 1);
    }

    function test_InvalidateAllSessionKeys_InvalidatesExistingKeys() public {
        // Grant keys
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // Invalidate all
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        // Key is now invalid due to generation mismatch
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // Forwarding function reverts with generation mismatch
        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_GENERATION_MISMATCH.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_InvalidateAllSessionKeys_NewKeysUseNewGeneration() public {
        vm.startPrank(manager);

        // Grant at generation 0
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        (,, uint96 gen0) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(gen0, 0);

        // Bump generation
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));

        // Re-grant at generation 1
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        (,, uint96 gen1) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(gen1, 1);

        vm.stopPrank();

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_InvalidateAllSessionKeys_RevertsNotPrimaryManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
    }

    function test_InvalidateAllSessionKeys_FixesZombieKeyReactivation() public {
        // Grant key under manager A
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 7 days);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // Manager changes A -> B (key becomes invalid via PRIMARY_MANAGER_CHANGED)
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // New manager invalidates all keys (bumps generation as a precaution)
        vm.prank(newManager);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));

        // Manager reverts B -> A
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), manager, manager);

        // Without generation counter, the old key would reactivate here.
        // With generation counter, it stays invalid because generation doesn't match.
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // Manager A must explicitly re-grant
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 7 days);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                    SWEEP ETH TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SweepETH_Success() public {
        vm.deal(address(superVaultExecutor), 5 ether);

        address recipient = makeAddr("recipient");
        vm.prank(admin);
        superVaultExecutor.sweepETH(recipient);

        assertEq(address(superVaultExecutor).balance, 0);
        assertEq(recipient.balance, 5 ether);
    }

    function test_SweepETH_NoOpWhenNoBalance() public {
        address recipient = makeAddr("recipient");
        vm.prank(admin);
        superVaultExecutor.sweepETH(recipient);
        assertEq(recipient.balance, 0);
    }

    function test_SweepETH_RevertsNotAdmin() public {
        vm.deal(address(superVaultExecutor), 1 ether);

        bytes32 adminRole = superVaultExecutor.DEFAULT_ADMIN_ROLE();
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, adminRole)
        );
        superVaultExecutor.sweepETH(makeAddr("recipient"));
    }

    function test_SweepETH_RevertsZeroAddress() public {
        vm.deal(address(superVaultExecutor), 1 ether);
        vm.prank(admin);
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        superVaultExecutor.sweepETH(address(0));
    }

    function test_SweepETH_EmitsEvent() public {
        vm.deal(address(superVaultExecutor), 3 ether);
        address recipient = makeAddr("recipient");

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultExecutor.ETHSwept(recipient, 3 ether);
        superVaultExecutor.sweepETH(recipient);
    }

    function test_SweepETH_NoEventWhenZeroBalance() public {
        address recipient = makeAddr("recipient");

        vm.prank(admin);
        vm.recordLogs();
        superVaultExecutor.sweepETH(recipient);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i; i < entries.length; ++i) {
            assertTrue(
                entries[i].topics[0] != ISuperVaultExecutor.ETHSwept.selector,
                "Should not emit ETHSwept when balance is zero"
            );
        }
    }

    function test_SweepETH_RevertsWhenRecipientRejectsETH() public {
        vm.deal(address(superVaultExecutor), 1 ether);
        ETHRejecter rejecter = new ETHRejecter();

        vm.prank(admin);
        vm.expectRevert(ISuperVaultExecutor.ETH_TRANSFER_FAILED.selector);
        superVaultExecutor.sweepETH(address(rejecter));
    }

    /*//////////////////////////////////////////////////////////////
                    SESSION KEY VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_IsSessionKeyValid_ReturnsTrueForValidKey() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseForExpiredKey() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.warp(block.timestamp + 1 days + 1);

        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseForUnauthorizedKey() public view {
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseWhenPrimaryManagerChanged() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        // Change primary manager via SuperGovernor
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_TrueAtExactExpiry() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        // Warp to exactly the expiry timestamp — still valid (code checks >)
        vm.warp(expiry);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // One second later — expired
        vm.warp(expiry + 1);
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_CrossStrategyIsolation() public {
        // Create a second vault/strategy
        vm.prank(manager);
        (, address strategyAddress2,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault 2",
                symbol: "TV2",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager
                })
            })
        );

        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(strategyAddress2, address(superVaultExecutor));

        // Grant key for strategy 1 only
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
        assertFalse(superVaultExecutor.isSessionKeyValid(strategyAddress2, sessionKey));
    }

    function test_IsSessionKeyValid_MultipleKeysPerStrategy() public {
        address sessionKey2 = makeAddr("sessionKey2");
        address sessionKey3 = makeAddr("sessionKey3");

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey2, block.timestamp + 2 days);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey3, block.timestamp + 3 days);
        vm.stopPrank();

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey2));
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey3));

        // Revoke one — others unaffected
        vm.prank(manager);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey2);

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey2));
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey3));
    }

    function test_IsSessionKeyValid_ReturnsFalseAfterGenerationBump() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                FORWARDING VALIDATION REVERT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ExecuteHooks_RevertsSessionKeyNotAuthorized() public {
        ISuperVaultStrategy.ExecuteArgs memory args;

        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_ExecuteHooks_RevertsSessionKeyExpired() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.warp(block.timestamp + 1 days + 1);

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_ExecuteHooks_RevertsSessionKeyGenerationMismatch() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_GENERATION_MISMATCH.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_ExecuteHooks_RevertsPrimaryManagerChanged() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        // Change primary manager
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.PRIMARY_MANAGER_CHANGED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_FulfillCancelRedeemRequests_RevertsSessionKeyNotAuthorized() public {
        address[] memory controllers = new address[](0);
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.fulfillCancelRedeemRequests(address(strategy), controllers);
    }

    function test_FulfillRedeemRequests_RevertsSessionKeyNotAuthorized() public {
        address[] memory controllers = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.fulfillRedeemRequests(address(strategy), controllers, amounts);
    }

    function test_SkimPerformanceFee_RevertsSessionKeyNotAuthorized() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.skimPerformanceFee(address(strategy));
    }

    function test_PauseStrategy_RevertsSessionKeyNotAuthorized() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_UnpauseStrategy_RevertsSessionKeyNotAuthorized() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.unpauseStrategy(address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                    PAUSE/UNPAUSE FORWARDING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PauseStrategy_ForwardsSuccessfully() public {
        uint256 expiry = block.timestamp + 1 days;
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));

        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    function test_UnpauseStrategy_ForwardsSuccessfully() public {
        uint256 expiry = block.timestamp + 1 days;
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        // Pause first
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Unpause
        vm.prank(sessionKey);
        superVaultExecutor.unpauseStrategy(address(strategy));
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    /*//////////////////////////////////////////////////////////////
                PAUSE/UNPAUSE VALIDATION EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_PauseStrategy_RevertsExpiredSessionKey() public {
        uint256 expiry = block.timestamp + 1 hours;
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        vm.warp(expiry + 1);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_PauseStrategy_RevertsGenerationMismatch() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_GENERATION_MISMATCH.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_PauseStrategy_RevertsPrimaryManagerChanged() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);

        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.PRIMARY_MANAGER_CHANGED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_UnpauseStrategy_RevertsExpiredSessionKey() public {
        uint256 expiry = block.timestamp + 1 hours;
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        // Pause while key is valid
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));

        vm.warp(expiry + 1);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultExecutor.unpauseStrategy(address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                    SESSION KEY MANAGEMENT ACCESS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SessionKey_CannotCallGrantSessionKey() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);

        // Session key tries to grant another key — should revert (not primary manager)
        address anotherKey = makeAddr("anotherKey");
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.grantSessionKey(address(strategy), anotherKey, block.timestamp + 1 days);
    }

    function test_SessionKey_CannotCallRevokeSessionKey() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
    }

    function test_SessionKey_CannotCallInvalidateAllSessionKeys() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                    ETH REFUND TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ReceiveETH() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(superVaultExecutor).call{ value: 1 ether }("");
        assertTrue(success);
        assertEq(address(superVaultExecutor).balance, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                    STRATEGY GENERATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetSessionKeyData_ReturnsZeroesForNonExistentKey() public view {
        (uint256 expiry, address grantedBy, uint96 gen) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(expiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
    }

    function test_GetSessionKeyData_AfterGrantAndRevoke() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);

        (uint256 expiry, address grantedBy, uint96 gen) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertGt(expiry, 0);
        assertEq(grantedBy, manager);
        assertEq(gen, 0);

        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        vm.stopPrank();

        (expiry, grantedBy, gen) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(expiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
    }

    function test_GetStrategyGeneration_DefaultsToZero() public view {
        assertEq(superVaultExecutor.getStrategyGeneration(address(strategy)), 0);
    }

    function test_GetStrategyGeneration_IncrementsOnInvalidate() public {
        vm.startPrank(manager);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        assertEq(superVaultExecutor.getStrategyGeneration(address(strategy)), 1);
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        assertEq(superVaultExecutor.getStrategyGeneration(address(strategy)), 2);
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        // Warp past expiry
        vm.warp(expiry + 1);

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function testFuzz_ValidKeysPassValidation(uint256 expiryOffset) public {
        expiryOffset = bound(expiryOffset, 1, 365 days);
        uint256 expiry = block.timestamp + expiryOffset;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function testFuzz_GrantRevokeGrant(uint256 expiry1, uint256 expiry2) public {
        expiry1 = bound(expiry1, block.timestamp + 1, block.timestamp + 365 days);
        expiry2 = bound(expiry2, block.timestamp + 1, block.timestamp + 365 days);

        vm.startPrank(manager);

        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry1);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry2);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        vm.stopPrank();
    }

    function testFuzz_ExpiryBoundary_ValidAtExactExpiry(uint256 offset) public {
        offset = bound(offset, 1, 365 days);
        uint256 expiry = block.timestamp + offset;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);

        // At exact expiry: still valid
        vm.warp(expiry);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // One second past: expired
        vm.warp(expiry + 1);
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function testFuzz_RevokeAndRegrant(uint256 expiry) public {
        expiry = bound(expiry, block.timestamp + 1, block.timestamp + 365 days);

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);

        // Data should be fully cleared
        (uint256 storedExpiry, address grantedBy, uint96 gen) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);

        // Re-grant works
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
        vm.stopPrank();
    }

    function testFuzz_GenerationBumpInvalidatesAllKeys(uint8 numKeys, uint8 numBumps) public {
        numKeys = uint8(bound(numKeys, 1, 10));
        numBumps = uint8(bound(numBumps, 1, 5));

        // Grant multiple keys
        vm.startPrank(manager);
        for (uint256 i; i < numKeys; ++i) {
            address key = address(uint160(0x1000 + i));
            superVaultExecutor.grantSessionKey(address(strategy), key, block.timestamp + 1 days);
            assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), key));
        }

        // Bump generation
        for (uint256 i; i < numBumps; ++i) {
            superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        }
        vm.stopPrank();

        // All keys should be invalid
        for (uint256 i; i < numKeys; ++i) {
            address key = address(uint160(0x1000 + i));
            assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), key));
        }
    }
}

/// @dev Helper contract that rejects ETH transfers (used for refund failure tests)
contract ETHRejecter {
    receive() external payable {
        revert("no ETH");
    }
}
