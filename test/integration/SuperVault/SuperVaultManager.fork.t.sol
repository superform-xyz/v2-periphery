// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperVaultManager } from "../../../src/SuperVault/SuperVaultManager.sol";
import { ISuperVaultManager } from "../../../src/interfaces/SuperVault/ISuperVaultManager.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";

/// @title SuperVaultManagerForkTest
/// @notice Fork tests against real Base mainnet deployed vaults
/// @dev Uses production SuperGovernor, Aggregator, and strategy addresses from Base mainnet
contract SuperVaultManagerForkTest is Test {
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

    SuperVaultManager public superVaultManager;
    ISuperVaultAggregator public aggregator;
    ISuperGovernor public superGovernor;

    address public admin;
    address public sessionKey;
    address public sessionKey2;

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

        // Deploy SuperVaultManager against real SuperGovernor
        superVaultManager = new SuperVaultManager(SUPER_GOVERNOR, admin);

        // Add SuperVaultManager as secondary manager on USDC strategy
        // (impersonate the real production primary manager)
        vm.prank(MAIN_MANAGER);
        aggregator.addSecondaryManager(USDC_STRATEGY, address(superVaultManager));
    }

    /*//////////////////////////////////////////////////////////////
                    DEPLOYMENT & WIRING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_DeploymentAgainstRealGovernor() public view {
        assertEq(address(superVaultManager.SUPER_GOVERNOR()), SUPER_GOVERNOR);
        assertTrue(superVaultManager.hasRole(superVaultManager.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_Fork_SuperVaultManagerIsSecondaryManager() public view {
        assertTrue(aggregator.isSecondaryManager(address(superVaultManager), USDC_STRATEGY));
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
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);

        assertTrue(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        (uint256 storedExpiry, address grantedBy,) = superVaultManager.getSessionKeyData(USDC_STRATEGY, sessionKey);
        assertEq(storedExpiry, expiry);
        assertEq(grantedBy, MAIN_MANAGER);
    }

    function test_Fork_GrantSessionKey_RevertsForNonManager() public {
        address imposter = makeAddr("imposter");

        vm.prank(imposter);
        vm.expectRevert(ISuperVaultManager.CALLER_NOT_PRIMARY_MANAGER.selector);
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, block.timestamp + 1 days);
    }

    function test_Fork_RevokeSessionKey_ByRealPrimaryManager() public {
        uint256 expiry = block.timestamp + 1 days;

        vm.startPrank(MAIN_MANAGER);
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);
        assertTrue(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        superVaultManager.revokeSessionKey(USDC_STRATEGY, sessionKey);
        vm.stopPrank();

        assertFalse(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                    PAUSE/UNPAUSE VIA SESSION KEY
    //////////////////////////////////////////////////////////////*/

    function test_Fork_PauseUnpause_ThroughSessionKey() public {
        uint256 expiry = block.timestamp + 1 days;

        // Grant session key
        vm.prank(MAIN_MANAGER);
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);

        // Session key pauses the strategy
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(USDC_STRATEGY);
        assertTrue(aggregator.isStrategyPaused(USDC_STRATEGY));

        // Session key unpauses the strategy
        vm.prank(sessionKey);
        superVaultManager.unpauseStrategy(USDC_STRATEGY);
        assertFalse(aggregator.isStrategyPaused(USDC_STRATEGY));
    }

    function test_Fork_PauseStrategy_RevertsExpiredSessionKey() public {
        uint256 expiry = block.timestamp + 1 hours;

        vm.prank(MAIN_MANAGER);
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);

        // Warp past expiry
        vm.warp(expiry + 1);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.SESSION_KEY_EXPIRED.selector);
        superVaultManager.pauseStrategy(USDC_STRATEGY);
    }

    function test_Fork_PauseStrategy_RevertsUnauthorizedSessionKey() public {
        address unauthorized = makeAddr("unauthorized");

        vm.prank(unauthorized);
        vm.expectRevert(ISuperVaultManager.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.pauseStrategy(USDC_STRATEGY);
    }

    /*//////////////////////////////////////////////////////////////
                    CROSS-STRATEGY ISOLATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_SessionKeyIsolation_AcrossRealStrategies() public {
        // Add SuperVaultManager as secondary manager on WETH strategy too
        vm.prank(MAIN_MANAGER);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultManager));

        uint256 expiry = block.timestamp + 1 days;

        // Grant session key only for USDC strategy
        vm.prank(MAIN_MANAGER);
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);

        // Session key can pause USDC strategy
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(USDC_STRATEGY);
        assertTrue(aggregator.isStrategyPaused(USDC_STRATEGY));

        // Session key cannot pause WETH strategy (not authorized for it)
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.pauseStrategy(WETH_STRATEGY);

        // Unpause USDC for cleanup
        vm.prank(sessionKey);
        superVaultManager.unpauseStrategy(USDC_STRATEGY);
    }

    function test_Fork_PerStrategySessionKeys() public {
        // Add SuperVaultManager on WETH strategy
        vm.prank(MAIN_MANAGER);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultManager));

        uint256 expiry = block.timestamp + 1 days;

        // Grant different session keys per strategy
        vm.startPrank(MAIN_MANAGER);
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);
        superVaultManager.grantSessionKey(WETH_STRATEGY, sessionKey2, expiry);
        vm.stopPrank();

        // sessionKey works on USDC but not WETH
        assertTrue(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));
        assertFalse(superVaultManager.isSessionKeyValid(WETH_STRATEGY, sessionKey));

        // sessionKey2 works on WETH but not USDC
        assertTrue(superVaultManager.isSessionKeyValid(WETH_STRATEGY, sessionKey2));
        assertFalse(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey2));
    }

    /*//////////////////////////////////////////////////////////////
                    BATCH OPERATIONS AGAINST REAL VAULTS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_BatchGrant_MultipleRealStrategies() public {
        // Add to WETH and CBBTC strategies too
        vm.startPrank(MAIN_MANAGER);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultManager));
        aggregator.addSecondaryManager(CBBTC_STRATEGY, address(superVaultManager));
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

        vm.prank(MAIN_MANAGER);
        superVaultManager.grantSessionKeysBatch(strategies, keys, expiries);

        assertTrue(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));
        assertTrue(superVaultManager.isSessionKeyValid(WETH_STRATEGY, sessionKey));
        assertTrue(superVaultManager.isSessionKeyValid(CBBTC_STRATEGY, sessionKey));
    }

    function test_Fork_BatchRevoke_MultipleRealStrategies() public {
        // Add to WETH strategy
        vm.startPrank(MAIN_MANAGER);
        aggregator.addSecondaryManager(WETH_STRATEGY, address(superVaultManager));

        // Grant on both
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, block.timestamp + 1 days);
        superVaultManager.grantSessionKey(WETH_STRATEGY, sessionKey, block.timestamp + 1 days);

        // Batch revoke
        address[] memory strategies = new address[](2);
        strategies[0] = USDC_STRATEGY;
        strategies[1] = WETH_STRATEGY;
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey;

        superVaultManager.revokeSessionKeysBatch(strategies, keys);
        vm.stopPrank();

        assertFalse(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));
        assertFalse(superVaultManager.isSessionKeyValid(WETH_STRATEGY, sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
                PRIMARY MANAGER CHANGE INVALIDATION
    //////////////////////////////////////////////////////////////*/

    function test_Fork_PrimaryManagerChange_InvalidatesSessionKeys() public {
        uint256 expiry = block.timestamp + 30 days;

        vm.prank(MAIN_MANAGER);
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);

        assertTrue(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // proposeChangePrimaryManager can only be called by a secondary manager
        // SuperVaultManager itself is a secondary manager, so we use it (via prank)
        address newManager = makeAddr("newManager");
        address feeRecipient = makeAddr("feeRecipient");
        vm.prank(address(superVaultManager));
        aggregator.proposeChangePrimaryManager(USDC_STRATEGY, newManager, feeRecipient);

        // Session key should still be valid during proposal period
        assertTrue(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // Warp past 7-day timelock
        vm.warp(block.timestamp + 7 days + 1);

        // Execute the manager change
        vm.prank(newManager);
        aggregator.executeChangePrimaryManager(USDC_STRATEGY);

        // Session key should now be invalid (grantedByManager no longer primary)
        assertFalse(superVaultManager.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // Session key forwarding should revert
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.PRIMARY_MANAGER_CHANGED.selector);
        superVaultManager.pauseStrategy(USDC_STRATEGY);

        // Restore the original manager: a secondary manager proposes, original manager accepts
        // First add superVaultManager as secondary on the now-newManager-owned strategy
        vm.prank(newManager);
        aggregator.addSecondaryManager(USDC_STRATEGY, address(superVaultManager));
        vm.prank(address(superVaultManager));
        aggregator.proposeChangePrimaryManager(USDC_STRATEGY, MAIN_MANAGER, feeRecipient);
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(MAIN_MANAGER);
        aggregator.executeChangePrimaryManager(USDC_STRATEGY);
    }

    /*//////////////////////////////////////////////////////////////
                    NOT-SECONDARY-MANAGER REVERT
    //////////////////////////////////////////////////////////////*/

    function test_Fork_NotSecondaryManager_RevertsOnPause() public {
        // Deploy a second SuperVaultManager that is NOT added as secondary manager
        SuperVaultManager svm2 = new SuperVaultManager(SUPER_GOVERNOR, admin);

        uint256 expiry = block.timestamp + 1 days;
        vm.prank(MAIN_MANAGER);
        svm2.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);

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
        superVaultManager.grantSessionKey(USDC_STRATEGY, sessionKey, expiry);

        // skimPerformanceFee should not revert (even if there's nothing to skim)
        vm.prank(sessionKey);
        superVaultManager.skimPerformanceFee(USDC_STRATEGY);
    }
}
