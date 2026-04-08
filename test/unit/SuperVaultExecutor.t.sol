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

    /// @dev All 6 permissions — used by existing tests to preserve pre-permission behavior
    function _permAll() internal pure returns (ISuperVaultExecutor.Permission[] memory perms) {
        perms = new ISuperVaultExecutor.Permission[](6);
        perms[0] = ISuperVaultExecutor.Permission.ExecuteHooks;
        perms[1] = ISuperVaultExecutor.Permission.FulfillCancelRedeem;
        perms[2] = ISuperVaultExecutor.Permission.FulfillRedeem;
        perms[3] = ISuperVaultExecutor.Permission.SkimFee;
        perms[4] = ISuperVaultExecutor.Permission.Pause;
        perms[5] = ISuperVaultExecutor.Permission.Unpause;
    }

    /// @dev Single permission helper
    function _perm(ISuperVaultExecutor.Permission p) internal pure returns (ISuperVaultExecutor.Permission[] memory perms) {
        perms = new ISuperVaultExecutor.Permission[](1);
        perms[0] = p;
    }

    /// @dev Two permissions helper
    function _perms2(
        ISuperVaultExecutor.Permission a,
        ISuperVaultExecutor.Permission b
    )
        internal
        pure
        returns (ISuperVaultExecutor.Permission[] memory perms)
    {
        perms = new ISuperVaultExecutor.Permission[](2);
        perms[0] = a;
        perms[1] = b;
    }

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
        emit ISuperVaultExecutor.SessionKeyGranted(address(strategy), sessionKey, expiry, manager, 0, 0x3F);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        (uint256 storedExpiry, address grantedBy, uint88 gen, uint8 perms) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, expiry);
        assertEq(grantedBy, manager);
        assertEq(gen, 0);
        assertEq(perms, 0x3F); // all 6 bits set
    }

    function test_GrantSessionKey_RevertsNotPrimaryManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
    }

    function test_GrantSessionKey_RevertsZeroSessionKey() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        superVaultExecutor.grantSessionKey(address(strategy), address(0), block.timestamp + 1 days, _permAll());
    }

    function test_GrantSessionKey_RevertsZeroExpiry() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_EXPIRY.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, 0, _permAll());
    }

    function test_GrantSessionKey_RevertsExpiryInPast() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EXPIRY_IN_PAST.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp, _permAll());
    }

    function test_GrantSessionKey_OverwritesExistingKey() public {
        uint256 expiry1 = block.timestamp + 1 days;
        uint256 expiry2 = block.timestamp + 7 days;

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry1, _permAll());
        (uint256 e1,,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(e1, expiry1);

        // Overwrite with new expiry
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry2, _permAll());
        (uint256 e2,,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(e2, expiry2);
        vm.stopPrank();
    }

    function test_GrantSessionKey_MaxExpiry_NeverExpires() public {
        uint256 maxExpiry = type(uint256).max;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, maxExpiry, _permAll());

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        // Still valid far in the future
        vm.warp(block.timestamp + 365 days * 100);
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_GrantSessionKey_RevertsExpiryEqualToTimestamp() public {
        // expiry <= block.timestamp reverts, so expiry == block.timestamp should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EXPIRY_IN_PAST.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp, _permAll());
    }

    function test_GrantSessionKey_RevertsZeroPermissions() public {
        ISuperVaultExecutor.Permission[] memory empty = new ISuperVaultExecutor.Permission[](0);
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_PERMISSIONS.selector);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, empty);
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
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](2);
        perms[0] = _permAll();
        perms[1] = _permAll();

        vm.prank(manager);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);

        (uint256 e1,,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        (uint256 e2,,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey2);
        assertEq(e1, block.timestamp + 1 days);
        assertEq(e2, block.timestamp + 2 days);
    }

    function test_GrantSessionKeysBatch_RevertsEmptyArray() public {
        address[] memory strategies = new address[](0);
        address[] memory keys = new address[](0);
        uint256[] memory expiries = new uint256[](0);
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](0);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.EMPTY_ARRAY.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);
    }

    function test_GrantSessionKeysBatch_RevertsBatchSizeExceeded() public {
        uint256 size = superVaultExecutor.MAX_BATCH_SIZE() + 1;
        address[] memory strategies = new address[](size);
        address[] memory keys = new address[](size);
        uint256[] memory expiries = new uint256[](size);
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](size);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.BATCH_SIZE_EXCEEDED.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);
    }

    function test_GrantSessionKeysBatch_RevertsArrayLengthMismatch() public {
        address[] memory strategies = new address[](2);
        address[] memory keys = new address[](1);
        uint256[] memory expiries = new uint256[](2);
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](2);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);
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
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](2);
        perms[0] = _permAll();
        perms[1] = _permAll();

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ZERO_ADDRESS.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);
    }

    function test_GrantSessionKeysBatch_AtExactlyMaxBatchSize() public {
        uint256 size = superVaultExecutor.MAX_BATCH_SIZE(); // 50
        address[] memory strategies = new address[](size);
        address[] memory keys = new address[](size);
        uint256[] memory expiries = new uint256[](size);
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](size);

        for (uint256 i; i < size; ++i) {
            strategies[i] = address(strategy);
            keys[i] = address(uint160(0x2000 + i));
            expiries[i] = block.timestamp + 1 days;
            perms[i] = _permAll();
        }

        vm.prank(manager);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);

        // Verify first and last
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), address(uint160(0x2000))));
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), address(uint160(0x2000 + size - 1))));
    }

    function test_GrantSessionKeysBatch_RevertsExpiriesMismatch() public {
        address[] memory strategies = new address[](2);
        address[] memory keys = new address[](2);
        uint256[] memory expiries = new uint256[](1); // mismatch
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](2);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);
    }

    function test_GrantSessionKeysBatch_RevertsNotPrimaryManager() public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(strategy);
        address[] memory keys = new address[](1);
        keys[0] = sessionKey;
        uint256[] memory expiries = new uint256[](1);
        expiries[0] = block.timestamp + 1 days;
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](1);
        perms[0] = _permAll();

        vm.prank(user);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);
    }

    function test_GrantSessionKeysBatch_RevertsPermissionsLengthMismatch() public {
        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = makeAddr("sessionKey2");
        uint256[] memory expiries = new uint256[](2);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 1 days;
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](1); // mismatch

        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.ARRAY_LENGTH_MISMATCH.selector);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);
    }

    function test_GrantSessionKeysBatch_WithMixedPermissions() public {
        address sessionKey2 = makeAddr("sessionKey2");
        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey2;
        uint256[] memory expiries = new uint256[](2);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 1 days;
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](2);
        perms[0] = _perm(ISuperVaultExecutor.Permission.Pause);
        perms[1] = _perm(ISuperVaultExecutor.Permission.ExecuteHooks);

        vm.prank(manager);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);

        // sessionKey has only Pause
        uint8 p1 = superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey);
        assertEq(p1, uint8(1 << uint8(ISuperVaultExecutor.Permission.Pause)));

        // sessionKey2 has only ExecuteHooks
        uint8 p2 = superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey2);
        assertEq(p2, uint8(1 << uint8(ISuperVaultExecutor.Permission.ExecuteHooks)));
    }

    /*//////////////////////////////////////////////////////////////
                    REVOKE SESSION KEY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevokeSessionKey_Success() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        vm.expectEmit(true, true, false, false);
        emit ISuperVaultExecutor.SessionKeyRevoked(address(strategy), sessionKey);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        vm.stopPrank();

        (uint256 storedExpiry, address grantedBy, uint88 gen, uint8 perms) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
        assertEq(perms, 0);
    }

    function test_RevokeSessionKey_RevertsForNonExistentKey() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
    }

    function test_RevokeSessionKey_DoubleRevokeReverts() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey2, block.timestamp + 1 days, _permAll());

        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey2;

        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
        vm.stopPrank();

        (uint256 e1,,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        (uint256 e2,,,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey2);
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
        (,, uint88 gen0,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(gen0, 0);

        // Bump generation
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));

        // Re-grant at generation 1
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
        (,, uint88 gen1,) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 7 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 7 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseForExpiredKey() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        vm.warp(block.timestamp + 1 days + 1);

        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseForUnauthorizedKey() public view {
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_ReturnsFalseWhenPrimaryManagerChanged() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        // Change primary manager via SuperGovernor
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function test_IsSessionKeyValid_TrueAtExactExpiry() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
        assertFalse(superVaultExecutor.isSessionKeyValid(strategyAddress2, sessionKey));
    }

    function test_IsSessionKeyValid_MultipleKeysPerStrategy() public {
        address sessionKey2 = makeAddr("sessionKey2");
        address sessionKey3 = makeAddr("sessionKey3");

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey2, block.timestamp + 2 days, _permAll());
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey3, block.timestamp + 3 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        vm.warp(block.timestamp + 1 days + 1);

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_ExecuteHooks_RevertsSessionKeyGenerationMismatch() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));

        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    function test_UnpauseStrategy_ForwardsSuccessfully() public {
        uint256 expiry = block.timestamp + 1 days;
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        vm.warp(expiry + 1);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_PauseStrategy_RevertsGenerationMismatch() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_GENERATION_MISMATCH.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_PauseStrategy_RevertsPrimaryManagerChanged() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

        // Session key tries to grant another key — should revert (not primary manager)
        address anotherKey = makeAddr("anotherKey");
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.grantSessionKey(address(strategy), anotherKey, block.timestamp + 1 days, _permAll());
    }

    function test_SessionKey_CannotCallRevokeSessionKey() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
    }

    function test_SessionKey_CannotCallInvalidateAllSessionKeys() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

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
        (uint256 expiry, address grantedBy, uint88 gen, uint8 perms) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(expiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
        assertEq(perms, 0);
    }

    function test_GetSessionKeyData_AfterGrantAndRevoke() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

        (uint256 expiry, address grantedBy, uint88 gen, uint8 perms) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertGt(expiry, 0);
        assertEq(grantedBy, manager);
        assertEq(gen, 0);
        assertEq(perms, 0x3F);

        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        vm.stopPrank();

        (expiry, grantedBy, gen, perms) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(expiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
        assertEq(perms, 0);
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

    function test_GetSessionKeyData_ReturnsCorrectPermissions() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.ExecuteHooks, ISuperVaultExecutor.Permission.Pause)
        );

        (,,, uint8 perms) = superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        // ExecuteHooks = bit 0, Pause = bit 4 => 0x11 = 17
        assertEq(perms, uint8((1 << 0) | (1 << 4)));
    }

    /*//////////////////////////////////////////////////////////////
                    PERMISSION-SPECIFIC TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Permission_ExecuteHooksOnly_CannotPause() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.ExecuteHooks)
        );

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_Permission_PauseOnly_CannotExecuteHooks() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_Permission_PauseOnly_CanPause() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    function test_Permission_PauseOnly_CannotUnpause() public {
        // Grant with both Pause and Unpause to pause first, then re-grant with only Pause
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.Pause, ISuperVaultExecutor.Permission.Unpause)
        );
        vm.stopPrank();

        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));

        // Re-grant with only Pause
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.unpauseStrategy(address(strategy));
    }

    function test_Permission_UnpauseOnly_CannotPause() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Unpause)
        );

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_Permission_SkimFeeOnly_CannotPause() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.SkimFee)
        );

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_Permission_FulfillCancelRedeemOnly_CannotExecuteHooks() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perm(ISuperVaultExecutor.Permission.FulfillCancelRedeem)
        );

        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);
    }

    function test_Permission_FulfillRedeemOnly_CannotSkimFee() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perm(ISuperVaultExecutor.Permission.FulfillRedeem)
        );

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.skimPerformanceFee(address(strategy));
    }

    function test_Permission_MultiplePermissions_AllowSubset() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.Pause, ISuperVaultExecutor.Permission.Unpause)
        );

        // Can pause
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Can unpause
        vm.prank(sessionKey);
        superVaultExecutor.unpauseStrategy(address(strategy));
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Cannot executeHooks
        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.executeHooks(address(strategy), args);

        // Cannot skimPerformanceFee
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.skimPerformanceFee(address(strategy));
    }

    function test_Permission_DuplicatePermissionsInArray_StillWorks() public {
        // Passing duplicate permissions should still work (idempotent OR)
        ISuperVaultExecutor.Permission[] memory perms = new ISuperVaultExecutor.Permission[](3);
        perms[0] = ISuperVaultExecutor.Permission.Pause;
        perms[1] = ISuperVaultExecutor.Permission.Pause;
        perms[2] = ISuperVaultExecutor.Permission.Unpause;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, perms);

        uint8 storedPerms = superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey);
        assertEq(storedPerms, uint8((1 << 4) | (1 << 5))); // Pause + Unpause
    }

    /*//////////////////////////////////////////////////////////////
                    isSessionKeyValidForPermission TESTS
    //////////////////////////////////////////////////////////////*/

    function test_IsSessionKeyValidForPermission_TrueForGrantedPermission() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
    }

    function test_IsSessionKeyValidForPermission_FalseForDeniedPermission() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );
    }

    function test_IsSessionKeyValidForPermission_FalseForExpiredKey() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 hours, _permAll()
        );

        vm.warp(block.timestamp + 1 hours + 1);

        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
    }

    function test_IsSessionKeyValidForPermission_FalseForNonExistentKey() public view {
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                    getSessionKeyPermissions TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetSessionKeyPermissions_ReturnsCorrectMask() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _permAll()
        );

        assertEq(superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey), 0x3F);
    }

    function test_GetSessionKeyPermissions_ReturnsZeroForNonExistent() public view {
        assertEq(superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey), 0);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_ExpiredKeysAlwaysRevert(uint256 expiryOffset) public {
        // Ensure offset is at least 1 so the key is initially valid
        expiryOffset = bound(expiryOffset, 1, 365 days);
        uint256 expiry = block.timestamp + expiryOffset;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
    }

    function testFuzz_GrantRevokeGrant(uint256 expiry1, uint256 expiry2) public {
        expiry1 = bound(expiry1, block.timestamp + 1, block.timestamp + 365 days);
        expiry2 = bound(expiry2, block.timestamp + 1, block.timestamp + 365 days);

        vm.startPrank(manager);

        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry1, _permAll());
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        assertFalse(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry2, _permAll());
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));

        vm.stopPrank();
    }

    function testFuzz_ExpiryBoundary_ValidAtExactExpiry(uint256 offset) public {
        offset = bound(offset, 1, 365 days);
        uint256 expiry = block.timestamp + offset;

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());

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
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());
        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);

        // Data should be fully cleared
        (uint256 storedExpiry, address grantedBy, uint88 gen, uint8 perms) =
            superVaultExecutor.getSessionKeyData(address(strategy), sessionKey);
        assertEq(storedExpiry, 0);
        assertEq(grantedBy, address(0));
        assertEq(gen, 0);
        assertEq(perms, 0);

        // Re-grant works
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, expiry, _permAll());
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
            superVaultExecutor.grantSessionKey(address(strategy), key, block.timestamp + 1 days, _permAll());
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

    /*//////////////////////////////////////////////////////////////
        PERMISSION POSITIVE TESTS: EACH PERMISSION CALLS ITS FUNCTION
    //////////////////////////////////////////////////////////////*/

    function test_Permission_SkimFeeOnly_PermissionGranted() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.SkimFee)
        );

        // Verify the permission is granted via view function
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.SkimFee
            )
        );
        // All other permissions should be denied
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
    }

    function test_Permission_UnpauseOnly_CanUnpause() public {
        // First pause via manager (secondary manager can pause directly on aggregator)
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Grant Unpause-only key
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Unpause)
        );

        vm.prank(sessionKey);
        superVaultExecutor.unpauseStrategy(address(strategy));
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    function test_Permission_FulfillCancelRedeemOnly_PermissionGranted() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perm(ISuperVaultExecutor.Permission.FulfillCancelRedeem)
        );

        // Verify the permission is granted via view function
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.FulfillCancelRedeem
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );
    }

    function test_Permission_FulfillRedeemOnly_PermissionGranted() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perm(ISuperVaultExecutor.Permission.FulfillRedeem)
        );

        // Verify the permission is granted via view function
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.FulfillRedeem
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.SkimFee
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
        EXHAUSTIVE PERMISSION DENIAL MATRIX
    //////////////////////////////////////////////////////////////*/

    /// @dev Helper: grants a single permission and asserts denial on all 5 other functions
    function _assertDeniedOnAllOtherFunctions(ISuperVaultExecutor.Permission granted) internal {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(granted)
        );

        // Check each function that should be denied
        if (granted != ISuperVaultExecutor.Permission.ExecuteHooks) {
            ISuperVaultStrategy.ExecuteArgs memory args;
            vm.prank(sessionKey);
            vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
            superVaultExecutor.executeHooks(address(strategy), args);
        }

        if (granted != ISuperVaultExecutor.Permission.FulfillCancelRedeem) {
            address[] memory controllers = new address[](0);
            vm.prank(sessionKey);
            vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
            superVaultExecutor.fulfillCancelRedeemRequests(address(strategy), controllers);
        }

        if (granted != ISuperVaultExecutor.Permission.FulfillRedeem) {
            address[] memory controllers = new address[](0);
            uint256[] memory amounts = new uint256[](0);
            vm.prank(sessionKey);
            vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
            superVaultExecutor.fulfillRedeemRequests(address(strategy), controllers, amounts);
        }

        if (granted != ISuperVaultExecutor.Permission.SkimFee) {
            vm.prank(sessionKey);
            vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
            superVaultExecutor.skimPerformanceFee(address(strategy));
        }

        if (granted != ISuperVaultExecutor.Permission.Pause) {
            vm.prank(sessionKey);
            vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
            superVaultExecutor.pauseStrategy(address(strategy));
        }

        if (granted != ISuperVaultExecutor.Permission.Unpause) {
            vm.prank(sessionKey);
            vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
            superVaultExecutor.unpauseStrategy(address(strategy));
        }
    }

    function test_Permission_ExecuteHooksOnly_DeniedOnAllOthers() public {
        _assertDeniedOnAllOtherFunctions(ISuperVaultExecutor.Permission.ExecuteHooks);
    }

    function test_Permission_FulfillCancelRedeemOnly_DeniedOnAllOthers() public {
        _assertDeniedOnAllOtherFunctions(ISuperVaultExecutor.Permission.FulfillCancelRedeem);
    }

    function test_Permission_FulfillRedeemOnly_DeniedOnAllOthers() public {
        _assertDeniedOnAllOtherFunctions(ISuperVaultExecutor.Permission.FulfillRedeem);
    }

    function test_Permission_SkimFeeOnly_DeniedOnAllOthers() public {
        _assertDeniedOnAllOtherFunctions(ISuperVaultExecutor.Permission.SkimFee);
    }

    function test_Permission_PauseOnly_DeniedOnAllOthers() public {
        _assertDeniedOnAllOtherFunctions(ISuperVaultExecutor.Permission.Pause);
    }

    function test_Permission_UnpauseOnly_DeniedOnAllOthers() public {
        _assertDeniedOnAllOtherFunctions(ISuperVaultExecutor.Permission.Unpause);
    }

    /*//////////////////////////////////////////////////////////////
        PERMISSION RE-GRANT (UPGRADE / DOWNGRADE)
    //////////////////////////////////////////////////////////////*/

    function test_Permission_ReGrant_DowngradeRemovesOldPermissions() public {
        // Grant Pause + Unpause
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.Pause, ISuperVaultExecutor.Permission.Unpause)
        );

        // Verify can pause
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));
        vm.prank(sessionKey);
        superVaultExecutor.unpauseStrategy(address(strategy));

        // Downgrade to Pause only (remove Unpause)
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        // Old Unpause permission should be gone
        uint8 perms = superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey);
        assertEq(perms, uint8(1 << uint8(ISuperVaultExecutor.Permission.Pause)));

        // Pause still works
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));

        // Unpause now denied
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.unpauseStrategy(address(strategy));
    }

    function test_Permission_ReGrant_UpgradeAddsNewPermissions() public {
        // Grant only Pause
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        // Cannot unpause
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Unpause
            )
        );

        // Upgrade to Pause + Unpause
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.Pause, ISuperVaultExecutor.Permission.Unpause)
        );

        // Now both work
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Unpause
            )
        );

        // Can do the actual round-trip
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));
        vm.prank(sessionKey);
        superVaultExecutor.unpauseStrategy(address(strategy));
    }

    function test_Permission_ReGrant_SwapsPermissions() public {
        // Grant Pause + Unpause
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.Pause, ISuperVaultExecutor.Permission.Unpause)
        );

        // Re-grant with ExecuteHooks + SkimFee (completely different set)
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            sessionKey,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.ExecuteHooks, ISuperVaultExecutor.Permission.SkimFee)
        );

        // Old permissions gone
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));

        // New permissions visible via view
        uint8 perms = superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey);
        uint8 expected = uint8(
            (1 << uint8(ISuperVaultExecutor.Permission.ExecuteHooks))
                | (1 << uint8(ISuperVaultExecutor.Permission.SkimFee))
        );
        assertEq(perms, expected);

        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.SkimFee
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
        PERMISSIONS SURVIVE / RESET THROUGH GENERATION CYCLES
    //////////////////////////////////////////////////////////////*/

    function test_Permission_AfterGenerationBump_ReGrantWithDifferentPerms() public {
        // Grant with all permissions at generation 0
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
        assertEq(superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey), 0x3F);

        // Bump generation
        superVaultExecutor.invalidateAllSessionKeys(address(strategy));

        // Re-grant with only Pause at generation 1
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );
        vm.stopPrank();

        // Only Pause works
        assertTrue(superVaultExecutor.isSessionKeyValid(address(strategy), sessionKey));
        assertEq(
            superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey),
            uint8(1 << uint8(ISuperVaultExecutor.Permission.Pause))
        );

        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.skimPerformanceFee(address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
        isSessionKeyValidForPermission EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_IsSessionKeyValidForPermission_FalseAfterGenerationBump() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );

        superVaultExecutor.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
    }

    function test_IsSessionKeyValidForPermission_FalseAfterManagerChange() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );

        // Change manager
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );
    }

    function test_IsSessionKeyValidForPermission_AllSixPermissions() public {
        // Grant all permissions and check each one individually
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());

        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.FulfillCancelRedeem
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.FulfillRedeem
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.SkimFee
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Unpause
            )
        );
    }

    function test_IsSessionKeyValidForPermission_SinglePermDeniesAllOthers() public {
        vm.prank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );

        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Pause
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.FulfillCancelRedeem
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.FulfillRedeem
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.SkimFee
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission.Unpause
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
        PERMISSION BITMASK FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_PermissionBitmask_CorrectEncoding(uint8 rawMask) public {
        // Clamp to valid 6-bit range (0x01..0x3F), must have at least 1 bit set
        rawMask = uint8(bound(rawMask, 1, 0x3F));

        // Build Permission[] from the mask bits
        uint256 count;
        for (uint8 i; i < 6; ++i) {
            if (rawMask & uint8(1 << i) != 0) count++;
        }

        ISuperVaultExecutor.Permission[] memory perms = new ISuperVaultExecutor.Permission[](count);
        uint256 idx;
        for (uint8 i; i < 6; ++i) {
            if (rawMask & uint8(1 << i) != 0) {
                perms[idx++] = ISuperVaultExecutor.Permission(i);
            }
        }

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, perms);

        uint8 stored = superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey);
        assertEq(stored, rawMask, "Stored bitmask should match input");
    }

    function testFuzz_PermissionBitmask_ViewConsistency(uint8 rawMask) public {
        rawMask = uint8(bound(rawMask, 1, 0x3F));

        // Build permissions from mask
        uint256 count;
        for (uint8 i; i < 6; ++i) {
            if (rawMask & uint8(1 << i) != 0) count++;
        }
        ISuperVaultExecutor.Permission[] memory perms = new ISuperVaultExecutor.Permission[](count);
        uint256 idx;
        for (uint8 i; i < 6; ++i) {
            if (rawMask & uint8(1 << i) != 0) {
                perms[idx++] = ISuperVaultExecutor.Permission(i);
            }
        }

        vm.prank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, perms);

        // isSessionKeyValidForPermission should match each bit
        for (uint8 i; i < 6; ++i) {
            bool expected = rawMask & uint8(1 << i) != 0;
            bool actual = superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), sessionKey, ISuperVaultExecutor.Permission(i)
            );
            assertEq(actual, expected, string.concat("Mismatch at permission index ", vm.toString(i)));
        }
    }

    /*//////////////////////////////////////////////////////////////
        MULTI-KEY PERMISSION ISOLATION
    //////////////////////////////////////////////////////////////*/

    function test_Permission_TwoKeysWithDifferentPerms_Isolated() public {
        address key1 = makeAddr("key1");
        address key2 = makeAddr("key2");

        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(
            address(strategy),
            key1,
            block.timestamp + 1 days,
            _perms2(ISuperVaultExecutor.Permission.Pause, ISuperVaultExecutor.Permission.Unpause)
        );
        superVaultExecutor.grantSessionKey(
            address(strategy), key2, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.SkimFee)
        );
        vm.stopPrank();

        // key1 can pause but not skim
        vm.prank(key1);
        superVaultExecutor.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        vm.prank(key1);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.skimPerformanceFee(address(strategy));

        // key1 unpauses for cleanup
        vm.prank(key1);
        superVaultExecutor.unpauseStrategy(address(strategy));

        // key2 has skim permission but not pause (verify via view)
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), key2, ISuperVaultExecutor.Permission.SkimFee
            )
        );

        vm.prank(key2);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.pauseStrategy(address(strategy));
    }

    function test_Permission_SameKeyDifferentStrategies_DifferentPerms() public {
        // Create second strategy
        vm.prank(manager);
        (, address strategy2Address,) = superVaultAggregator.createVault(
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

        vm.startPrank(manager);
        superVaultAggregator.addSecondaryManager(strategy2Address, address(superVaultExecutor));

        // Same key, different permissions per strategy
        superVaultExecutor.grantSessionKey(
            address(strategy), sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.Pause)
        );
        superVaultExecutor.grantSessionKey(
            strategy2Address, sessionKey, block.timestamp + 1 days, _perm(ISuperVaultExecutor.Permission.SkimFee)
        );
        vm.stopPrank();

        // Can pause strategy1
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(address(strategy));

        // Cannot skim strategy1
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.skimPerformanceFee(address(strategy));

        // Strategy2: has SkimFee permission (verify via view)
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                strategy2Address, sessionKey, ISuperVaultExecutor.Permission.SkimFee
            )
        );

        // Cannot pause strategy2
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_PERMISSION_DENIED.selector);
        superVaultExecutor.pauseStrategy(strategy2Address);
    }

    /*//////////////////////////////////////////////////////////////
        PERMISSION CLEARED ON REVOKE
    //////////////////////////////////////////////////////////////*/

    function test_Permission_RevokedKeyPermissionsCleared() public {
        vm.startPrank(manager);
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, _permAll());
        assertEq(superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey), 0x3F);

        superVaultExecutor.revokeSessionKey(address(strategy), sessionKey);
        vm.stopPrank();

        assertEq(superVaultExecutor.getSessionKeyPermissions(address(strategy), sessionKey), 0);

        // isSessionKeyValidForPermission returns false for all permissions
        for (uint8 i; i < 6; ++i) {
            assertFalse(
                superVaultExecutor.isSessionKeyValidForPermission(
                    address(strategy), sessionKey, ISuperVaultExecutor.Permission(i)
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
        BATCH GRANT WITH PER-KEY PERMISSION VERIFICATION
    //////////////////////////////////////////////////////////////*/

    function test_GrantSessionKeysBatch_DifferentPermsPerKey_VerifyEach() public {
        address key1 = makeAddr("batchKey1");
        address key2 = makeAddr("batchKey2");
        address key3 = makeAddr("batchKey3");

        address[] memory strategies = new address[](3);
        strategies[0] = address(strategy);
        strategies[1] = address(strategy);
        strategies[2] = address(strategy);
        address[] memory keys = new address[](3);
        keys[0] = key1;
        keys[1] = key2;
        keys[2] = key3;
        uint256[] memory expiries = new uint256[](3);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 1 days;
        expiries[2] = block.timestamp + 1 days;

        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](3);
        perms[0] = _perm(ISuperVaultExecutor.Permission.Pause);
        perms[1] = _perms2(ISuperVaultExecutor.Permission.ExecuteHooks, ISuperVaultExecutor.Permission.SkimFee);
        perms[2] = _permAll();

        vm.prank(manager);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);

        // key1: only Pause
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), key1, ISuperVaultExecutor.Permission.Pause
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), key1, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );

        // key2: ExecuteHooks + SkimFee
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), key2, ISuperVaultExecutor.Permission.ExecuteHooks
            )
        );
        assertTrue(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), key2, ISuperVaultExecutor.Permission.SkimFee
            )
        );
        assertFalse(
            superVaultExecutor.isSessionKeyValidForPermission(
                address(strategy), key2, ISuperVaultExecutor.Permission.Pause
            )
        );

        // key3: all permissions
        for (uint8 i; i < 6; ++i) {
            assertTrue(
                superVaultExecutor.isSessionKeyValidForPermission(
                    address(strategy), key3, ISuperVaultExecutor.Permission(i)
                )
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
        EVENT EMISSION WITH CORRECT PERMISSIONS
    //////////////////////////////////////////////////////////////*/

    function test_GrantSessionKey_EmitsCorrectPermissionBitmask() public {
        ISuperVaultExecutor.Permission[] memory perms =
            _perms2(ISuperVaultExecutor.Permission.ExecuteHooks, ISuperVaultExecutor.Permission.SkimFee);
        uint8 expectedMask = uint8((1 << 0) | (1 << 3)); // ExecuteHooks=0, SkimFee=3

        vm.prank(manager);
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultExecutor.SessionKeyGranted(
            address(strategy), sessionKey, block.timestamp + 1 days, manager, 0, expectedMask
        );
        superVaultExecutor.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days, perms);
    }
}

/// @dev Helper contract that rejects ETH transfers (used for refund failure tests)
contract ETHRejecter {
    receive() external payable {
        revert("no ETH");
    }
}
