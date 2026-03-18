// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { SuperVaultManager } from "../../src/SuperVault/SuperVaultManager.sol";
import { ISuperVaultManager } from "../../src/interfaces/SuperVault/ISuperVaultManager.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";
import { MockSuperHook } from "../mocks/MockSuperHook.sol";
import { MockHookTarget } from "../mocks/MockHookTarget.sol";

/// @title SuperVaultManagerE2ETest
/// @notice End-to-end tests for SuperVaultManager
contract SuperVaultManagerE2ETest is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    SuperVaultManager internal superVaultManager;
    MockERC20 internal asset;
    MockSuperHook internal mockHook;
    MockHookTarget internal mockTarget;

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

    uint256 internal constant HOOKS_ROOT_TIMELOCK = 15 minutes;

    /// @dev Builds hookCalldata with 32-byte oracle ID + 20-byte yield source (minimum for HookDataDecoder)
    function _buildHookCalldata() internal view returns (bytes memory) {
        return abi.encodePacked(bytes32(0), address(mockTarget));
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

        // Deploy SuperVaultManager
        superVaultManager = new SuperVaultManager(address(superGovernor), admin);

        // Add SuperVaultManager as secondary manager
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(address(strategy), address(superVaultManager));

        // Deploy mock hook infrastructure
        mockTarget = new MockHookTarget();
        mockHook = new MockSuperHook(address(mockTarget));

        // Register hook in SuperGovernor
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));
    }

    /*//////////////////////////////////////////////////////////////
        HELPER: compute leaf + set strategy hook root
    //////////////////////////////////////////////////////////////*/

    /// @dev Computes Merkle leaf for a hook and sets the strategy hooks root
    function _setupHookRoot(address hook, bytes memory hookCalldata) internal {
        bytes memory hookArgs = ISuperHookInspector(hook).inspect(hookCalldata);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));

        // Propose strategy hooks root (primary manager)
        vm.prank(manager);
        superVaultAggregator.proposeStrategyHooksRoot(address(strategy), leaf);

        // Fast forward past timelock
        vm.warp(block.timestamp + HOOKS_ROOT_TIMELOCK + 1);

        // Execute the root update
        superVaultAggregator.executeStrategyHooksRootUpdate(address(strategy));
    }

    /// @dev Grants a session key for the strategy
    function _grantKey(address key, uint256 duration) internal {
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), key, block.timestamp + duration);
    }

    /*//////////////////////////////////////////////////////////////
        E2E: FULL DEPLOYMENT & EXECUTE HOOKS THROUGH SESSION KEY
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: deploy -> add secondary -> grant key -> executeHooks through session key
    function test_E2E_ExecuteHooks_ThroughSessionKey() public {
        // Setup hook root so the hook passes validation
        bytes memory hookCalldata = _buildHookCalldata();
        _setupHookRoot(address(mockHook), hookCalldata);

        // Grant session key
        _grantKey(sessionKey, 1 days);

        // Build ExecuteArgs
        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = hookCalldata;

        uint256[] memory expectedOut = new uint256[](1);
        expectedOut[0] = 0;

        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0);

        bytes32[][] memory strategyProofs = new bytes32[][](1);
        strategyProofs[0] = new bytes32[](0);

        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: calldatas,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });

        // Execute through session key — this is the full path:
        // sessionKey -> SuperVaultManager.executeHooks -> strategy.executeHooks
        vm.prank(sessionKey);
        superVaultManager.executeHooks(address(strategy), args);
    }

    /*//////////////////////////////////////////////////////////////
        E2E: FULL REDEEM FLOW THROUGH SESSION KEY
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: deposit -> requestRedeem -> cancelRedeem -> fulfillCancelRedeem via session key
    function test_E2E_FulfillCancelRedeemRequests_ThroughSessionKey() public {
        // User deposits into vault
        deal(address(asset), user, 10_000e18);
        vm.startPrank(user);
        asset.approve(address(vault), 10_000e18);
        vault.deposit(1_000e18, user);

        // User requests redeem
        uint256 shares = vault.balanceOf(user) / 2;
        vault.requestRedeem(shares, user, user);

        // User cancels the redeem request
        vault.cancelRedeemRequest(0, user);
        vm.stopPrank();

        // Grant session key
        _grantKey(sessionKey, 1 days);

        // Session key holder fulfills the cancel request
        address[] memory controllers = new address[](1);
        controllers[0] = user;

        vm.prank(sessionKey);
        superVaultManager.fulfillCancelRedeemRequests(address(strategy), controllers);

        // Verify the cancel request was fulfilled
        assertTrue(strategy.pendingCancelRedeemRequest(user));
        uint256 claimable = strategy.claimableCancelRedeemRequest(user);
        assertGt(claimable, 0, "Should have claimable shares after fulfillment");
    }

    /*//////////////////////////////////////////////////////////////
        E2E: PAUSE/UNPAUSE THROUGH SESSION KEY
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: session key pauses and unpauses a strategy
    function test_E2E_PauseUnpause_ThroughSessionKey() public {
        _grantKey(sessionKey, 1 days);

        // Pause through session key
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Unpause through session key
        vm.prank(sessionKey);
        superVaultManager.unpauseStrategy(address(strategy));
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    /*//////////////////////////////////////////////////////////////
        E2E: PRIMARY MANAGER CHANGE INVALIDATES SESSION KEYS
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: session key works -> primary manager changes -> session key is invalidated
    function test_E2E_PrimaryManagerChange_InvalidatesSessionKeys() public {
        _grantKey(sessionKey, 1 days);

        // Session key works initially
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Pause through session key to prove it works
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Unpause first to reset state
        vm.prank(sessionKey);
        superVaultManager.unpauseStrategy(address(strategy));

        // SuperGovernor changes primary manager
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        // Session key is now invalidated
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // All forwarding functions revert with PRIMARY_MANAGER_CHANGED
        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.PRIMARY_MANAGER_CHANGED.selector);
        superVaultManager.executeHooks(address(strategy), args);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.PRIMARY_MANAGER_CHANGED.selector);
        superVaultManager.pauseStrategy(address(strategy));

        // New manager can grant new session keys
        // First add SuperVaultManager as secondary manager under new manager
        vm.prank(newManager);
        superVaultAggregator.addSecondaryManager(address(strategy), address(superVaultManager));

        address newSessionKey = makeAddr("newSessionKey");
        vm.prank(newManager);
        superVaultManager.grantSessionKey(address(strategy), newSessionKey, block.timestamp + 1 days);

        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), newSessionKey));
    }

    /*//////////////////////////////////////////////////////////////
        E2E: PROPOSED PRIMARY MANAGER CHANGE (TWO-STEP)
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: secondary manager proposes primary change -> timelock -> execute -> keys invalidated
    function test_E2E_TwoStepPrimaryManagerChange_InvalidatesSessionKeys() public {
        // Add another secondary manager who will propose the change
        address secondaryMgr = makeAddr("secondaryManager");
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(address(strategy), secondaryMgr);

        // Grant session key
        _grantKey(sessionKey, 7 days);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Secondary manager proposes primary change
        address newManager = makeAddr("proposedNewManager");
        vm.prank(secondaryMgr);
        superVaultAggregator.proposeChangePrimaryManager(address(strategy), newManager, newManager);

        // Session key still valid during proposal period
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Fast forward past timelock (7 days for manager change)
        vm.warp(block.timestamp + 7 days + 1);

        // Execute the primary manager change
        superVaultAggregator.executeChangePrimaryManager(address(strategy));

        // Now session key is invalidated
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
        E2E: MULTIPLE SESSION KEYS, SELECTIVE REVOCATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: grant multiple keys -> revoke one -> others still work
    function test_E2E_MultipleSessionKeys_SelectiveRevoke() public {
        address key1 = makeAddr("key1");
        address key2 = makeAddr("key2");
        address key3 = makeAddr("key3");

        vm.startPrank(manager);
        superVaultManager.grantSessionKey(address(strategy), key1, block.timestamp + 1 days);
        superVaultManager.grantSessionKey(address(strategy), key2, block.timestamp + 1 days);
        superVaultManager.grantSessionKey(address(strategy), key3, block.timestamp + 1 days);
        vm.stopPrank();

        // All three are valid
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), key1));
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), key2));
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), key3));

        // Revoke key2 only
        vm.prank(manager);
        superVaultManager.revokeSessionKey(address(strategy), key2);

        // key1 and key3 still valid, key2 is not
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), key1));
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), key2));
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), key3));

        // key1 can still pause
        vm.prank(key1);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // key2 cannot
        vm.prank(key2);
        vm.expectRevert(ISuperVaultManager.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.unpauseStrategy(address(strategy));

        // key3 can unpause
        vm.prank(key3);
        superVaultManager.unpauseStrategy(address(strategy));
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    /*//////////////////////////////////////////////////////////////
        E2E: SESSION KEY EXPIRY DURING ACTIVE USE
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: session key works -> time passes -> key expires -> operations revert
    function test_E2E_SessionKeyExpiry_DuringActiveUse() public {
        uint256 expiry = block.timestamp + 1 hours;
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, expiry);

        // Works before expiry
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        vm.prank(sessionKey);
        superVaultManager.unpauseStrategy(address(strategy));

        // Warp to exactly at expiry — should still revert (> check in _validateSessionKey)
        vm.warp(expiry + 1);

        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.SESSION_KEY_EXPIRED.selector);
        superVaultManager.pauseStrategy(address(strategy));

        // Manager can re-grant with new expiry
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 hours);

        // Works again
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));
    }

    /*//////////////////////////////////////////////////////////////
        E2E: MULTIPLE STRATEGIES, ISOLATED SESSION KEYS
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: session key for strategy A cannot operate on strategy B
    function test_E2E_CrossStrategyIsolation() public {
        // Create second vault/strategy
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

        // Add SuperVaultManager as secondary to both
        vm.startPrank(manager);
        superVaultAggregator.addSecondaryManager(strategy2Address, address(superVaultManager));

        // Grant session key ONLY for strategy1
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        vm.stopPrank();

        // Can operate on strategy1
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));

        // Cannot operate on strategy2
        assertFalse(superVaultManager.isSessionKeyValid(strategy2Address, sessionKey));
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.SESSION_KEY_NOT_AUTHORIZED.selector);
        superVaultManager.pauseStrategy(strategy2Address);
    }

    /*//////////////////////////////////////////////////////////////
        E2E: BATCH GRANT + REVOKE ACROSS STRATEGIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: batch grant keys for multiple strategies, batch revoke them
    function test_E2E_BatchGrantRevoke_MultiStrategy() public {
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

        // Add SuperVaultManager as secondary to both
        vm.startPrank(manager);
        superVaultAggregator.addSecondaryManager(strategy2Address, address(superVaultManager));

        // Batch grant: same key for both strategies
        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = strategy2Address;
        address[] memory keys = new address[](2);
        keys[0] = sessionKey;
        keys[1] = sessionKey;
        uint256[] memory expiries = new uint256[](2);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 1 days;

        superVaultManager.grantSessionKeysBatch(strategies, keys, expiries);
        vm.stopPrank();

        // Both valid
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
        assertTrue(superVaultManager.isSessionKeyValid(strategy2Address, sessionKey));

        // Can operate on both
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(strategy2Address);

        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));
        assertTrue(superVaultAggregator.isStrategyPaused(strategy2Address));

        // Batch revoke
        vm.prank(manager);
        superVaultManager.revokeSessionKeysBatch(strategies, keys);

        // Both invalidated
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
        assertFalse(superVaultManager.isSessionKeyValid(strategy2Address, sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
        E2E: ETH FORWARDING THROUGH EXECUTE HOOKS
    //////////////////////////////////////////////////////////////*/

    /// @dev Builds valid ExecuteArgs for the mock hook
    function _buildExecuteArgs() internal view returns (ISuperVaultStrategy.ExecuteArgs memory) {
        bytes memory hookCalldata = _buildHookCalldata();

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = hookCalldata;
        uint256[] memory expectedOut = new uint256[](1);
        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0);
        bytes32[][] memory strategyProofs = new bytes32[][](1);
        strategyProofs[0] = new bytes32[](0);

        return ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: calldatas,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });
    }

    /// @notice Full e2e: session key sends ETH with executeHooks, ETH reaches strategy
    function test_E2E_ExecuteHooks_WithETH() public {
        _setupHookRoot(address(mockHook), _buildHookCalldata());
        _grantKey(sessionKey, 1 days);

        ISuperVaultStrategy.ExecuteArgs memory args = _buildExecuteArgs();

        vm.deal(sessionKey, 1 ether);
        vm.prank(sessionKey);
        superVaultManager.executeHooks{ value: 0.5 ether }(address(strategy), args);

        assertEq(address(strategy).balance, 0.5 ether);
    }

    /// @notice Full e2e: stray ETH in the manager is NOT refunded (only caller's overpayment is)
    function test_E2E_ExecuteHooks_DoesNotRefundStrayETH() public {
        _setupHookRoot(address(mockHook), _buildHookCalldata());
        _grantKey(sessionKey, 1 days);

        ISuperVaultStrategy.ExecuteArgs memory args = _buildExecuteArgs();

        // Simulate stray ETH in the manager
        vm.deal(address(superVaultManager), 1 ether);

        uint256 balanceBefore = sessionKey.balance;
        vm.prank(sessionKey);
        superVaultManager.executeHooks(address(strategy), args);

        // Stray ETH should remain in the manager (balance-delta tracking)
        assertEq(address(superVaultManager).balance, 1 ether);
        assertEq(sessionKey.balance, balanceBefore);
    }

    /// @dev Builds ExecuteArgs with a specific hook and hookCalldata
    function _buildExecuteArgsFor(
        address hook,
        bytes memory hookCalldata_
    )
        internal
        pure
        returns (ISuperVaultStrategy.ExecuteArgs memory)
    {
        address[] memory hooks = new address[](1);
        hooks[0] = hook;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = hookCalldata_;
        uint256[] memory expectedOut = new uint256[](1);
        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0);
        bytes32[][] memory strategyProofs = new bytes32[][](1);
        strategyProofs[0] = new bytes32[](0);

        return ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: calldatas,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });
    }

    /// @dev Sets up a refunding hook that sends ETH back to the SuperVaultManager when executed
    function _setupRefundingHook()
        internal
        returns (MockSuperHook refundHook, bytes memory refundHookCalldata)
    {
        // Deploy a target that sends its ETH balance to the SuperVaultManager when called
        ETHRefunderTarget refunderTarget = new ETHRefunderTarget(address(superVaultManager));
        vm.deal(address(refunderTarget), 1 ether);

        // Deploy a hook pointing to the refunder target
        refundHook = new MockSuperHook(address(refunderTarget));

        // Register hook in SuperGovernor
        vm.prank(governor);
        superGovernor.registerHook(address(refundHook));

        // Build hookCalldata (minimum: 32-byte oracle ID + 20-byte yield source)
        refundHookCalldata = abi.encodePacked(bytes32(0), address(refunderTarget));

        // Set up strategy hooks root for this hook
        _setupHookRoot(address(refundHook), refundHookCalldata);
    }

    /// @notice Full e2e: hook target refunds ETH to manager, which is forwarded to caller with event
    function test_E2E_ExecuteHooks_RefundsCallerOverpayment() public {
        (MockSuperHook refundHook, bytes memory refundHookCalldata) = _setupRefundingHook();
        _grantKey(sessionKey, 1 days);

        ISuperVaultStrategy.ExecuteArgs memory args = _buildExecuteArgsFor(address(refundHook), refundHookCalldata);

        uint256 callerBalanceBefore = sessionKey.balance;

        vm.prank(sessionKey);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultManager.ETHRefunded(sessionKey, 1 ether);
        superVaultManager.executeHooks(address(strategy), args);

        // Refunder's ETH was sent to manager during hook execution, then refunded to caller
        assertEq(sessionKey.balance, callerBalanceBefore + 1 ether);
    }

    /// @notice Full e2e: ETH refund reverts when caller rejects ETH (assembly prevents return bomb)
    function test_E2E_ExecuteHooks_RevertsETHRefundFailed() public {
        (MockSuperHook refundHook, bytes memory refundHookCalldata) = _setupRefundingHook();

        // Use a contract that rejects ETH as the session key
        ETHRejecter rejecter = new ETHRejecter();
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), address(rejecter), block.timestamp + 1 days);

        ISuperVaultStrategy.ExecuteArgs memory args = _buildExecuteArgsFor(address(refundHook), refundHookCalldata);

        vm.prank(address(rejecter));
        vm.expectRevert(ISuperVaultManager.ETH_REFUND_FAILED.selector);
        superVaultManager.executeHooks(address(strategy), args);
    }

    /*//////////////////////////////////////////////////////////////
        E2E: SESSION KEY MANAGER NOT SECONDARY MANAGER
    //////////////////////////////////////////////////////////////*/

    /// @notice SuperVaultManager reverts at strategy level when not added as secondary manager
    function test_E2E_NotSecondaryManager_RevertsAtStrategy() public {
        // Create new strategy without adding SuperVaultManager as secondary
        vm.prank(manager);
        (, address freshStrategy,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Fresh Vault",
                symbol: "FV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: manager
                })
            })
        );

        // Grant session key for the fresh strategy
        vm.prank(manager);
        superVaultManager.grantSessionKey(freshStrategy, sessionKey, block.timestamp + 1 days);

        // Session key validation passes (key is valid)
        assertTrue(superVaultManager.isSessionKeyValid(freshStrategy, sessionKey));

        // But actual forwarding reverts because SuperVaultManager is not a secondary manager on the strategy
        // pauseStrategy goes through the aggregator which checks UNAUTHORIZED_UPDATE_AUTHORITY
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
        superVaultManager.pauseStrategy(freshStrategy);
    }

    /*//////////////////////////////////////////////////////////////
        E2E: GENERATION COUNTER PREVENTS ZOMBIE KEY REACTIVATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: grant key -> manager changes A->B -> B invalidates all -> B->A -> old key stays dead
    function test_E2E_GenerationCounter_PreventsZombieKeys() public {
        _grantKey(sessionKey, 7 days);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Manager changes A -> B
        address newManager = makeAddr("newManager");
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), newManager, newManager);

        // Key is invalid (PRIMARY_MANAGER_CHANGED)
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // New manager B adds SuperVaultManager as secondary and bumps generation
        vm.startPrank(newManager);
        superVaultAggregator.addSecondaryManager(address(strategy), address(superVaultManager));
        superVaultManager.invalidateAllSessionKeys(address(strategy));
        vm.stopPrank();

        // Manager reverts B -> A
        vm.prank(sGovernor);
        superGovernor.changePrimaryManager(address(strategy), manager, manager);

        // Without generation counter, old key would reactivate here.
        // With generation counter, it stays dead.
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Manager A must re-add secondary and explicitly re-grant
        vm.startPrank(manager);
        superVaultAggregator.addSecondaryManager(address(strategy), address(superVaultManager));
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        vm.stopPrank();

        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
        E2E: SWEEP ETH RECOVERS STUCK FUNDS
    //////////////////////////////////////////////////////////////*/

    /// @notice Full e2e: ETH gets stuck -> admin sweeps it to treasury
    function test_E2E_SweepETH_RecoversStuckFunds() public {
        // Simulate stuck ETH from accidental sends
        vm.deal(address(superVaultManager), 3 ether);
        assertEq(address(superVaultManager).balance, 3 ether);

        uint256 treasuryBefore = treasury.balance;

        // Admin sweeps to treasury
        vm.prank(admin);
        superVaultManager.sweepETH(treasury);

        assertEq(address(superVaultManager).balance, 0);
        assertEq(treasury.balance, treasuryBefore + 3 ether);
    }

    /*//////////////////////////////////////////////////////////////
        E2E: RE-GRANT AFTER EXPIRY
    //////////////////////////////////////////////////////////////*/

    /// @notice Session key expires -> manager re-grants -> session key works again
    function test_E2E_ReGrantAfterExpiry() public {
        // Grant with short expiry
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 hours);

        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Expire the key
        vm.warp(block.timestamp + 1 hours + 1);
        assertFalse(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Can't use it
        vm.prank(sessionKey);
        vm.expectRevert(ISuperVaultManager.SESSION_KEY_EXPIRED.selector);
        superVaultManager.pauseStrategy(address(strategy));

        // Re-grant
        vm.prank(manager);
        superVaultManager.grantSessionKey(address(strategy), sessionKey, block.timestamp + 1 days);
        assertTrue(superVaultManager.isSessionKeyValid(address(strategy), sessionKey));

        // Works again
        vm.prank(sessionKey);
        superVaultManager.pauseStrategy(address(strategy));
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)));
    }
}

/// @dev Helper contract that rejects ETH transfers (used for refund failure tests)
contract ETHRejecter {
    receive() external payable {
        revert("no ETH");
    }
}

/// @dev Helper contract that sends its ETH balance to a recipient when any function is called
///      Used to simulate a hook target refunding ETH back to the SuperVaultManager during executeHooks
contract ETHRefunderTarget {
    address public refundRecipient;

    constructor(address recipient_) {
        refundRecipient = recipient_;
    }

    fallback() external {
        uint256 bal = address(this).balance;
        if (bal > 0) {
            (bool s,) = refundRecipient.call{ value: bal }("");
            require(s, "ETHRefunderTarget: refund failed");
        }
    }

    receive() external payable { }
}
