// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperVaultExecutor } from "../../../src/SuperVault/SuperVaultExecutor.sol";
import { ISuperVaultExecutor } from "../../../src/interfaces/SuperVault/ISuperVaultExecutor.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";

/// @title SuperVaultExecutorForkTest
/// @notice Fork tests against real Base mainnet deployed vaults
/// @dev Uses production SuperGovernor, Aggregator, and strategy addresses from Base mainnet
contract SuperVaultExecutorForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                        PRODUCTION ADDRESSES (BASE)
    //////////////////////////////////////////////////////////////*/

    /// @dev SuperGovernor on Base mainnet
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    /// @dev SuperVaultAggregator on Base mainnet
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;

    /// @dev Primary manager for all production vaults
    address constant MAIN_MANAGER = 0xb3dCDaA89B0A43bcC59a9BDEEb5583EC2071066c;

    /// @dev Flagship USDC SuperVault strategy on Base mainnet
    address constant USDC_STRATEGY = 0x5bE8c059A8E101d24B107aFb5A013feF505280b9;

    /// @dev Flagship WETH SuperVault strategy on Base mainnet
    address constant WETH_STRATEGY = 0x2787a17fe04C73AD109370C90917d62D1899Eb6A;

    /// @dev Flagship CBBTC SuperVault strategy on Base mainnet
    address constant CBBTC_STRATEGY = 0x0c14c751b19D4362f14f4A1D1cB963180B63fB87;

    /*//////////////////////////////////////////////////////////////
                            TEST STATE
    //////////////////////////////////////////////////////////////*/

    SuperVaultExecutor public superVaultExecutor;
    ISuperVaultAggregator public aggregator;
    ISuperGovernor public superGovernor;

    address public admin;
    address public sessionKey;
    address public sessionKey2;

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev All 6 permissions
    function _permAll() internal pure returns (ISuperVaultExecutor.Permission[] memory perms) {
        perms = new ISuperVaultExecutor.Permission[](6);
        perms[0] = ISuperVaultExecutor.Permission.ExecuteHooks;
        perms[1] = ISuperVaultExecutor.Permission.FulfillCancelRedeem;
        perms[2] = ISuperVaultExecutor.Permission.FulfillRedeem;
        perms[3] = ISuperVaultExecutor.Permission.SkimFee;
        perms[4] = ISuperVaultExecutor.Permission.Pause;
        perms[5] = ISuperVaultExecutor.Permission.Unpause;
    }

    /// @dev Remove a secondary manager if the strategy is at MAX_SECONDARY_MANAGERS (5)
    ///      Must be called while pranking as MAIN_MANAGER
    function _makeRoomForSecondaryManager(address strategy) internal {
        address[] memory managers = aggregator.getSecondaryManagers(strategy);
        if (managers.length >= 5) {
            aggregator.removeSecondaryManager(strategy, managers[0]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        admin = makeAddr("admin");
        sessionKey = makeAddr("sessionKey");
        sessionKey2 = makeAddr("sessionKey2");

        superGovernor = ISuperGovernor(SUPER_GOVERNOR);
        aggregator = ISuperVaultAggregator(AGGREGATOR);

        // Deploy SuperVaultExecutor against real SuperGovernor
        // Using canonical v0.7 EntryPoint address
        superVaultExecutor = new SuperVaultExecutor(SUPER_GOVERNOR, admin, 0x0000000071727De22E5E9d8BAf0edAc6f37da032);

        // Add SuperVaultExecutor as secondary manager on USDC strategy
        // (impersonate the real production primary manager)
        // Production strategies may be at MAX_SECONDARY_MANAGERS (5), so make room first
        vm.startPrank(MAIN_MANAGER);
        _makeRoomForSecondaryManager(USDC_STRATEGY);
        aggregator.addSecondaryManager(USDC_STRATEGY, address(superVaultExecutor));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    DEPLOYMENT & WIRING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_DeploymentAgainstRealGovernor() public view {
        assertEq(address(superVaultExecutor.SUPER_GOVERNOR()), SUPER_GOVERNOR);
        assertTrue(superVaultExecutor.hasRole(superVaultExecutor.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_Fork_SuperVaultExecutorIsSecondaryManager() public view {
        assertTrue(aggregator.isSecondaryManager(address(superVaultExecutor), USDC_STRATEGY));
    }

    function test_Fork_AggregatorResolvesCorrectly() public view {
        // Verify the dynamic aggregator resolution works against real SuperGovernor
        address resolvedAggregator = superGovernor.getAddress(superGovernor.SUPER_VAULT_AGGREGATOR());
        assertEq(resolvedAggregator, AGGREGATOR);
    }

    /*//////////////////////////////////////////////////////////////
                    SESSION KEY GRANT/REVOKE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_GrantSessionKey_ByRealPrimaryManager() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());

        assertTrue(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        (uint256 storedExpiry, address grantedBy,,) = superVaultExecutor.getSessionKeyData(USDC_STRATEGY, sessionKey);
        assertEq(storedExpiry, expiry);
        assertEq(grantedBy, MAIN_MANAGER);
    }

    function test_Fork_GrantSessionKey_RevertsForNonManager() public {
        address imposter = makeAddr("imposter");

        vm.prank(imposter);
        vm.expectRevert(ISuperVaultExecutor.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, block.timestamp + 1 days, _permAll());
    }

    function test_Fork_RevokeSessionKey_ByRealPrimaryManager() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());
        assertTrue(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        superVaultExecutor.revokeSessionKey(USDC_STRATEGY, sessionKey);
        vm.stopPrank();

        assertFalse(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                    PAUSE/UNPAUSE VIA SESSION KEY
    //////////////////////////////////////////////////////////////*/

    function test_Fork_PauseUnpause_ThroughSessionKey() public {
        uint256 expiry = block.timestamp + 1 days;

        // Grant session key
        vm.prank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());

        // Session key pauses the strategy
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(USDC_STRATEGY);
        assertTrue(aggregator.isStrategyPaused(USDC_STRATEGY));

        // Session key unpauses the strategy
        vm.prank(sessionKey);
        superVaultExecutor.unpauseStrategy(USDC_STRATEGY);
        assertFalse(aggregator.isStrategyPaused(USDC_STRATEGY));
    }

    function test_Fork_PauseStrategy_RevertsExpiredSessionKey() public {
        uint256 expiry = block.timestamp + 1 hours;

        vm.prank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());

        // Warp past expiry
        vm.warp(expiry + 1);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_EXPIRED.selector);
        superVaultExecutor.pauseStrategy(USDC_STRATEGY);
    }

    function test_Fork_PauseStrategy_RevertsUnauthorizedSessionKey() public {
        address unauthorized = makeAddr("unauthorized");

        vm.prank(unauthorized);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.pauseStrategy(USDC_STRATEGY);
    }

    /*//////////////////////////////////////////////////////////////
                    CROSS-STRATEGY ISOLATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_SessionKeyIsolation_AcrossRealStrategies() public {
        // Add SuperVaultExecutor as secondary manager on WETH strategy too
        vm.startPrank(MAIN_MANAGER);
        _makeRoomForSecondaryManager(WETH_STRATEGY);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultExecutor));
        vm.stopPrank();

        uint256 expiry = block.timestamp + 1 days;

        // Grant session key only for USDC strategy
        vm.prank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());

        // Session key can pause USDC strategy
        vm.prank(sessionKey);
        superVaultExecutor.pauseStrategy(USDC_STRATEGY);
        assertTrue(aggregator.isStrategyPaused(USDC_STRATEGY));

        // Session key cannot pause WETH strategy (not authorized for it)
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultExecutor.pauseStrategy(WETH_STRATEGY);

        // Unpause USDC for cleanup
        vm.prank(sessionKey);
        superVaultExecutor.unpauseStrategy(USDC_STRATEGY);
    }

    function test_Fork_PerStrategySessionKeys() public {
        // Add SuperVaultExecutor on WETH strategy
        vm.startPrank(MAIN_MANAGER);
        _makeRoomForSecondaryManager(WETH_STRATEGY);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultExecutor));
        vm.stopPrank();

        uint256 expiry = block.timestamp + 1 days;

        // Grant different session keys per strategy
        vm.startPrank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());
        superVaultExecutor.grantSessionKey(WETH_STRATEGY, sessionKey2, expiry, _permAll());
        vm.stopPrank();

        // sessionKey works on USDC but not WETH
        assertTrue(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));
        assertFalse(superVaultExecutor.isSessionKeyValid(WETH_STRATEGY, sessionKey));

        // sessionKey2 works on WETH but not USDC
        assertTrue(superVaultExecutor.isSessionKeyValid(WETH_STRATEGY, sessionKey2));
        assertFalse(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey2));
    }

    /*//////////////////////////////////////////////////////////////
                    BATCH OPERATIONS AGAINST REAL VAULTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_BatchGrant_MultipleRealStrategies() public {
        // Add to WETH and CBBTC strategies too
        // Production strategies may be at MAX_SECONDARY_MANAGERS (5), so make room first
        vm.startPrank(MAIN_MANAGER);
        _makeRoomForSecondaryManager(WETH_STRATEGY);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultExecutor));
        _makeRoomForSecondaryManager(CBBTC_STRATEGY);
        aggregator.addSecondaryManager(CBBTC_STRATEGY, address(superVaultExecutor));
        vm.stopPrank();

        address[] memory strategies = new address[](3);
        strategies[0] = USDC_STRATEGY;
        strategies[1] = WETH_STRATEGY;
        strategies[2] = CBBTC_STRATEGY;

        address[] memory keys = new address[](3);
        keys[0] = sessionKey;
        keys[1] = sessionKey;
        keys[2] = sessionKey;

        uint256[] memory expiries = new uint256[](3);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 2 days;
        expiries[2] = block.timestamp + 3 days;

        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](3);
        perms[0] = _permAll();
        perms[1] = _permAll();
        perms[2] = _permAll();

        vm.prank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKeysBatch(strategies, keys, expiries, perms);

        assertTrue(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));
        assertTrue(superVaultExecutor.isSessionKeyValid(WETH_STRATEGY, sessionKey));
        assertTrue(superVaultExecutor.isSessionKeyValid(CBBTC_STRATEGY, sessionKey));
    }

    function test_Fork_BatchRevoke_MultipleRealStrategies() public {
        // Remove an existing secondary manager to free up a slot (max is 5)
        vm.startPrank(MAIN_MANAGER);
        _makeRoomForSecondaryManager(WETH_STRATEGY);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultExecutor));

        // Grant on both
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, block.timestamp + 1 days, _permAll());
        superVaultExecutor.grantSessionKey(WETH_STRATEGY, sessionKey, block.timestamp + 1 days, _permAll());

        // Batch revoke
        address[] memory strategies = new address[](2);
        strategies[0] = USDC_STRATEGY;
        strategies[1] = WETH_STRATEGY;
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey;

        superVaultExecutor.revokeSessionKeysBatch(strategies, keys);
        vm.stopPrank();

        assertFalse(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));
        assertFalse(superVaultExecutor.isSessionKeyValid(WETH_STRATEGY, sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                PRIMARY MANAGER CHANGE INVALIDATION
    //////////////////////////////////////////////////////////////*/

    function test_Fork_PrimaryManagerChange_InvalidatesSessionKeys() public {
        uint256 expiry = block.timestamp + 30 days;

        vm.prank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());

        assertTrue(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // proposeChangePrimaryManager can only be called by a secondary manager
        // SuperVaultExecutor itself is a secondary manager, so we use it (via prank)
        address newManager = makeAddr("newManager");
        address feeRecipient = makeAddr("feeRecipient");
        vm.prank(address(superVaultExecutor));
        aggregator.proposeChangePrimaryManager(USDC_STRATEGY, newManager, feeRecipient);

        // Session key should still be valid during proposal period
        assertTrue(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // Warp past 7-day timelock
        vm.warp(block.timestamp + 7 days + 1);

        // Execute the manager change
        vm.prank(newManager);
        aggregator.executeChangePrimaryManager(USDC_STRATEGY);

        // Session key should now be invalid (grantedByManager no longer primary)
        assertFalse(superVaultExecutor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // Session key forwarding should revert
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultExecutor.PRIMARY_MANAGER_CHANGED.selector);
        superVaultExecutor.pauseStrategy(USDC_STRATEGY);

        // Restore the original manager: a secondary manager proposes, original manager accepts
        // First add superVaultExecutor as secondary on the now-newManager-owned strategy
        vm.startPrank(newManager);
        _makeRoomForSecondaryManager(USDC_STRATEGY);
        aggregator.addSecondaryManager(USDC_STRATEGY, address(superVaultExecutor));
        vm.stopPrank();
        vm.prank(address(superVaultExecutor));
        aggregator.proposeChangePrimaryManager(USDC_STRATEGY, MAIN_MANAGER, feeRecipient);
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(MAIN_MANAGER);
        aggregator.executeChangePrimaryManager(USDC_STRATEGY);
    }

    /*//////////////////////////////////////////////////////////////
                    NOT-SECONDARY-MANAGER REVERT
    //////////////////////////////////////////////////////////////*/

    function test_Fork_NotSecondaryManager_RevertsOnPause() public {
        // Deploy a second SuperVaultExecutor that is NOT added as secondary manager
        SuperVaultExecutor svm2 = new SuperVaultExecutor(SUPER_GOVERNOR, admin, 0x0000000071727De22E5E9d8BAf0edAc6f37da032);

        uint256 expiry = block.timestamp + 1 days;
        vm.prank(MAIN_MANAGER);
        svm2.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());

        // Forwarding should revert at the aggregator level since svm2 is not a secondary manager
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        svm2.pauseStrategy(USDC_STRATEGY);
    }

    /*//////////////////////////////////////////////////////////////
                    SKIM PERFORMANCE FEE VIA SESSION KEY
    //////////////////////////////////////////////////////////////*/

    function test_Fork_SkimPerformanceFee_ThroughSessionKey() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.prank(MAIN_MANAGER);
        superVaultExecutor.grantSessionKey(USDC_STRATEGY, sessionKey, expiry, _permAll());

        // skimPerformanceFee should not revert (even if there's nothing to skim)
        vm.prank(sessionKey);
        superVaultExecutor.skimPerformanceFee(USDC_STRATEGY);
    }
}
