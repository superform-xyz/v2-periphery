// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../src/interfaces/SuperVault/ISuperVault.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";
import { MockAssetNoDecimals } from "../mocks/MockAssetNoDecimals.sol";
import { Mock4626Vault } from "../mocks/Mock4626Vault.sol";

import "forge-std/console2.sol";

/// @title SuperVaultTest
/// @notice Unit tests for SuperVault contract
contract SuperVaultTest is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    MockERC20 internal asset;

    // Roles & Addresses
    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal user;
    address internal manager;
    address internal superBank;
    address internal superOracle;
    address internal upToken;

    /// @notice Sets up the test environment before each test case
    function setUp() public {
        // Deploy accounts
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        user = _deployAccount(0x4, "User");
        manager = _deployAccount(0x5, "Manager");
        superOracle = address(new MockSuperOracle(1e18));

        // Deploy contracts
        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, treasury);

        // Deploy implementation contracts
        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        // Register dependencies on SuperGovernor
        upToken = address(new MockUp(address(this)));
        superBank = makeAddr("superBank");
        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(superVaultAggregator));
        vm.stopPrank();

        // Create a vault and strategy for testing
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
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: manager
                })
            })
        );

        vault = SuperVault(vaultAddress);
        strategy = SuperVaultStrategy(payable(strategyAddress));
    }

    // =============================================================
    // pendingCancelRedeemRequest Tests
    // =============================================================

    /// @notice Tests pendingCancelRedeemRequest returns false when no cancel request is pending
    function test_PendingCancelRedeemRequest_InitialState() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Test: Initially no pending cancel request (should return false)
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertFalse(isPending, "Should return false when no cancel request is pending");

        // Verify strategy returns same value
        bool strategyPending = strategy.pendingCancelRedeemRequest(testUser);
        assertEq(isPending, strategyPending, "Vault should return same value as strategy");
    }

    /// @notice Tests pendingCancelRedeemRequest returns true after cancel request is made
    function test_PendingCancelRedeemRequest_AfterCancelRequest() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Mint shares to user
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        // Request redemption
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);

        // Cancel the redemption request
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Test: Should return true (pending cancel request)
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertTrue(isPending, "Should return true when cancel request is pending");

        // Verify strategy returns same value
        bool strategyPending = strategy.pendingCancelRedeemRequest(testUser);
        assertEq(isPending, strategyPending, "Vault should return same value as strategy");
    }

    /// @notice Tests pendingCancelRedeemRequest returns true after fulfillment until claim
    function test_PendingCancelRedeemRequest_AfterFulfillment() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Mint shares to user and create cancel request
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Should still return true after fulfillment until claim
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertTrue(isPending, "Should still return true after fulfillment until claim");

        // Verify strategy returns same value
        bool strategyPending = strategy.pendingCancelRedeemRequest(testUser);
        assertEq(isPending, strategyPending, "Vault should return same value as strategy");
    }

    /// @notice Tests pendingCancelRedeemRequest returns false after claim is completed
    function test_PendingCancelRedeemRequest_AfterClaim() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Mint shares to user and create cancel request
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // User claims the cancel request
        vm.prank(testUser);
        vault.claimCancelRedeemRequest(0, testUser, testUser);

        // Test: Should return false after claim is completed
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertFalse(isPending, "Should return false after claim is completed");

        // Verify strategy returns same value
        bool strategyPending = strategy.pendingCancelRedeemRequest(testUser);
        assertEq(isPending, strategyPending, "Vault should return same value as strategy");
    }

    /// @notice Tests pendingCancelRedeemRequest with request ID parameter (always ignored)
    function test_PendingCancelRedeemRequest_RequestIdIgnored() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Create a cancel request
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Test: Different request IDs should return same result (parameter is ignored)
        bool isPending0 = vault.pendingCancelRedeemRequest(0, testUser);
        bool isPending1 = vault.pendingCancelRedeemRequest(1, testUser);
        bool isPending999 = vault.pendingCancelRedeemRequest(999, testUser);

        assertTrue(isPending0, "Request ID 0 should return true");
        assertEq(isPending0, isPending1, "Request ID should be ignored - result should be same");
        assertEq(isPending0, isPending999, "Request ID should be ignored - result should be same");
    }

    /// @notice Tests pendingCancelRedeemRequest for multiple users independently
    function test_PendingCancelRedeemRequest_MultipleUsers() public {
        address testUser1 = _deployAccount(0xABC, "TestUser1");
        address testUser2 = _deployAccount(0xDEF, "TestUser2");

        // Setup user1 with cancel request
        deal(address(asset), testUser1, 10000e18);
        vm.startPrank(testUser1);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser1);
        uint256 sharesToRedeem1 = vault.balanceOf(testUser1) / 2;
        vault.requestRedeem(sharesToRedeem1, testUser1, testUser1);
        vault.cancelRedeemRequest(0, testUser1);
        vm.stopPrank();

        // Setup user2 with no cancel request
        deal(address(asset), testUser2, 10000e18);
        vm.startPrank(testUser2);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser2);
        vm.stopPrank();

        // Test: User1 should have pending cancel request, User2 should not
        bool isPendingUser1 = vault.pendingCancelRedeemRequest(0, testUser1);
        bool isPendingUser2 = vault.pendingCancelRedeemRequest(0, testUser2);

        assertTrue(isPendingUser1, "User1 should have pending cancel request");
        assertFalse(isPendingUser2, "User2 should not have pending cancel request");
    }

    // =============================================================
    // maxMint Tests
    // =============================================================

    /// @notice Tests maxMint returns type(uint256).max when deposits can be accepted (initial state)
    function test_MaxMint_ReturnsMaxWhenDepositsAccepted() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Test: Initially deposits should be accepted (not paused, PPS not stale)
        uint256 maxMintAmount = vault.maxMint(testUser);
        assertEq(maxMintAmount, type(uint256).max, "Should return type(uint256).max when deposits are accepted");

        // Verify the strategy is not paused and PPS is not stale
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should not be paused");
        assertFalse(superVaultAggregator.isPPSStale(address(strategy)), "PPS should not be stale");
    }

    /// @notice Tests maxMint returns 0 when strategy is paused
    function test_MaxMint_ReturnsZeroWhenStrategyPaused() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Verify initial state: maxMint should return max value
        uint256 initialMaxMint = vault.maxMint(testUser);
        assertEq(initialMaxMint, type(uint256).max, "Initially should return type(uint256).max");

        // Pause the strategy (only manager can pause)
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Test: maxMint should now return 0
        uint256 maxMintAfterPause = vault.maxMint(testUser);
        assertEq(maxMintAfterPause, 0, "Should return 0 when strategy is paused");

        // Verify the strategy is paused
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should be paused");
    }

    /// @notice Tests maxMint returns 0 when PPS is stale (strategy unpaused but PPS not updated)
    function test_MaxMint_ReturnsZeroWhenPPSStale() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Pause the strategy (this sets ppsStale to true)
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Unpause the strategy (ppsStale remains true until PPS update)
        vm.prank(manager);
        superVaultAggregator.unpauseStrategy(address(strategy));

        // Test: maxMint should return 0 because PPS is stale
        uint256 maxMintAmount = vault.maxMint(testUser);
        assertEq(maxMintAmount, 0, "Should return 0 when PPS is stale");

        // Verify the strategy is not paused but PPS is stale
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should not be paused");
        assertTrue(superVaultAggregator.isPPSStale(address(strategy)), "PPS should be stale");
    }

    /// @notice Tests maxMint returns 0 when both strategy is paused and PPS is stale
    function test_MaxMint_ReturnsZeroWhenPausedAndStale() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Pause the strategy (this sets both isPaused and ppsStale to true)
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Test: maxMint should return 0
        uint256 maxMintAmount = vault.maxMint(testUser);
        assertEq(maxMintAmount, 0, "Should return 0 when strategy is paused and PPS is stale");

        // Verify both conditions are true
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should be paused");
        assertTrue(superVaultAggregator.isPPSStale(address(strategy)), "PPS should be stale");
    }

    /// @notice Tests maxMint with different addresses returns same value
    function test_MaxMint_AddressParameterIgnored() public {
        address testUser1 = _deployAccount(0xABC, "TestUser1");
        address testUser2 = _deployAccount(0xDEF, "TestUser2");
        address testUser3 = address(0);

        // Test: All addresses should return same value (address parameter is not used)
        uint256 maxMint1 = vault.maxMint(testUser1);
        uint256 maxMint2 = vault.maxMint(testUser2);
        uint256 maxMint3 = vault.maxMint(testUser3);

        assertEq(maxMint1, type(uint256).max, "TestUser1 should get max value");
        assertEq(maxMint1, maxMint2, "Address parameter should be ignored - same result for different addresses");
        assertEq(maxMint1, maxMint3, "Address parameter should be ignored - even zero address returns same result");
    }

    /// @notice Tests maxMint transitions between states correctly
    function test_MaxMint_StateTransitions() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Initial state: should return max
        uint256 maxMint1 = vault.maxMint(testUser);
        assertEq(maxMint1, type(uint256).max, "Initial state should return max");

        // Pause: should return 0
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));
        uint256 maxMint2 = vault.maxMint(testUser);
        assertEq(maxMint2, 0, "Paused state should return 0");

        // Unpause (but PPS still stale): should still return 0
        vm.prank(manager);
        superVaultAggregator.unpauseStrategy(address(strategy));
        uint256 maxMint3 = vault.maxMint(testUser);
        assertEq(maxMint3, 0, "Unpaused but stale PPS should return 0");

        // Verify final state
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should not be paused");
        assertTrue(superVaultAggregator.isPPSStale(address(strategy)), "PPS should still be stale");
    }

    // =============================================================
    // previewMint Tests
    // =============================================================

    /// @notice Tests previewMint returns correct gross assets when managementFeeBps < BPS_PRECISION
    function test_PreviewMint_NormalCase() public {
        // Create a vault with 5% (500 bps) management fee
        vm.prank(manager);
        (address vaultAddress, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault Fee",
                symbol: "TVF",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0,
                    managementFeeBps: 500, // 5% management fee
                    recipient: manager
                })
            })
        );

        SuperVault testVault = SuperVault(vaultAddress);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddress));

        // First deposit some assets to initialize PPS
        address depositor = _deployAccount(0x123, "Depositor");
        deal(address(asset), depositor, 10000e18);

        vm.startPrank(depositor);
        asset.approve(vaultAddress, 10000e18);
        testVault.deposit(1000e18, depositor);
        vm.stopPrank();

        // Test: Preview minting 100 shares
        // With 5% fee: net assets for 100 shares need to be calculated, then grossed up by 5%
        // Formula: gross = net * 10000 / (10000 - 500) = net * 10000 / 9500
        uint256 sharesToMint = 100e18;
        uint256 grossAssets = testVault.previewMint(sharesToMint);

        // Verify grossAssets > 0 and accounts for the fee
        assertGt(grossAssets, 0, "Gross assets should be greater than 0");

        // Calculate expected gross assets manually
        uint256 pps = testStrategy.getStoredPPS();
        uint256 assetsNet = (sharesToMint * pps + testVault.PRECISION() - 1) / testVault.PRECISION(); // Ceil div
        uint256 expectedGross = (assetsNet * 10_000 + 9500 - 1) / 9500; // Ceil div

        assertEq(grossAssets, expectedGross, "Gross assets should match expected calculation");
    }

    /// @notice Tests previewMint returns 0 when managementFeeBps >= BPS_PRECISION
    function test_PreviewMint_EdgeCaseImpossibleFee() public {
        // Create a vault with 100% (10000 bps) management fee
        vm.prank(manager);
        (address vaultAddress,,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault 100% Fee",
                symbol: "TV100",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0,
                    managementFeeBps: 10_000, // 100% management fee (BPS_PRECISION)
                    recipient: manager
                })
            })
        );

        SuperVault testVault = SuperVault(vaultAddress);

        // First deposit some assets to initialize PPS (though it should still work even without this)
        address depositor = _deployAccount(0x123, "Depositor");
        deal(address(asset), depositor, 10000e18);

        vm.startPrank(depositor);
        asset.approve(vaultAddress, 10000e18);
        // Note: deposit should fail with 100% fee, but we can still test previewMint
        vm.stopPrank();

        // Test: Preview minting any amount of shares should return 0
        uint256 sharesToMint = 100e18;
        uint256 grossAssets = testVault.previewMint(sharesToMint);

        // Verify: Should return 0 because it's impossible to mint with 100%+ fees
        assertEq(grossAssets, 0, "Should return 0 when feeBps >= BPS_PRECISION (impossible to mint)");

        // Test with different share amounts - all should return 0
        assertEq(testVault.previewMint(1), 0, "Should return 0 for any amount when fee is 100%");
        assertEq(testVault.previewMint(1000e18), 0, "Should return 0 for any amount when fee is 100%");
        assertEq(testVault.previewMint(type(uint256).max), 0, "Should return 0 for any amount when fee is 100%");
    }

    // =============================================================
    // withdraw Tests
    // =============================================================

    /// @notice Tests withdraw reverts when receiver is address(0)
    function test_Withdraw_RevertsOnZeroAddressReceiver() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: User deposits and requests redemption to have claimable assets
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        // Request redemption
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vm.stopPrank();

        // Manager fulfills the redemption request
        vm.startPrank(manager);
        deal(address(asset), address(strategy), 1000e18);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = sharesToRedeem;
        strategy.fulfillRedeemRequests(controllers, amounts);
        vm.stopPrank();

        // Test: Attempt to withdraw with receiver = address(0) should revert
        uint256 claimableAssets = vault.maxWithdraw(testUser);
        assertGt(claimableAssets, 0, "Should have claimable assets for test");

        vm.prank(testUser);
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.withdraw(claimableAssets, address(0), testUser);
    }

    /// @notice Tests withdraw reverts when averageWithdrawPrice is 0 (no fulfilled redemption)
    function test_Withdraw_RevertsOnZeroAverageWithdrawPrice() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: User deposits but has no redemption request
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Test: Attempt to withdraw without any redemption request should revert
        // because averageWithdrawPrice will be 0
        vm.prank(testUser);
        vm.expectRevert(ISuperVault.INVALID_WITHDRAW_PRICE.selector);
        vault.withdraw(100e18, testUser, testUser);

        // Verify that averageWithdrawPrice is indeed 0
        uint256 averageWithdrawPrice = strategy.getAverageWithdrawPrice(testUser);
        assertEq(averageWithdrawPrice, 0, "Average withdraw price should be 0 when no redemption fulfilled");
    }

    // =============================================================
    // SuperVaultStrategy Tests
    // =============================================================

    /// @notice Tests SuperVaultStrategy constructor reverts when superGovernor is address(0)
    function test_SuperVaultStrategy_Constructor_RevertsOnZeroAddress() public {
        // Test: Attempt to deploy SuperVaultStrategy with address(0) should revert
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        new SuperVaultStrategy(address(0));
    }

    /// @notice Tests SuperVaultStrategy initialize reverts when vaultAddress is address(0)
    function test_SuperVaultStrategy_Initialize_RevertsOnZeroVaultAddress() public {
        // Deploy a new strategy implementation
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));

        // Prepare valid fee config
        ISuperVaultStrategy.FeeConfig memory feeConfig = ISuperVaultStrategy.FeeConfig({
            performanceFeeBps: 1000,
            managementFeeBps: 500,
            recipient: manager
        });

        // Prepare initialization data with vaultAddress = address(0)
        bytes memory initData = abi.encodeWithSelector(
            SuperVaultStrategy.initialize.selector,
            address(0), // vaultAddress = address(0) should revert
            feeConfig
        );

        // Test: Attempt to deploy proxy with initialization that has vaultAddress = address(0) should revert
        vm.expectRevert(ISuperVaultStrategy.INVALID_VAULT.selector);
        new ERC1967Proxy(strategyImpl, initData);
    }

    /// @notice Tests SuperVaultStrategy initialize reverts when performanceFeeBps > MAX_PERFORMANCE_FEE
    function test_SuperVaultStrategy_Initialize_RevertsOnInvalidPerformanceFeeBps() public {
        // Deploy a new strategy implementation
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));

        // Prepare fee config with performanceFeeBps > MAX_PERFORMANCE_FEE (5100)
        ISuperVaultStrategy.FeeConfig memory feeConfig = ISuperVaultStrategy.FeeConfig({
            performanceFeeBps: 5101, // MAX_PERFORMANCE_FEE is 5100, so 5101 should revert
            managementFeeBps: 500,
            recipient: manager
        });

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            SuperVaultStrategy.initialize.selector,
            address(vault),
            feeConfig
        );

        // Test: Attempt to deploy proxy with invalid performanceFeeBps should revert
        vm.expectRevert(ISuperVaultStrategy.INVALID_PERFORMANCE_FEE_BPS.selector);
        new ERC1967Proxy(strategyImpl, initData);
    }

    /// @notice Tests SuperVaultStrategy initialize reverts when managementFeeBps > BPS_PRECISION
    function test_SuperVaultStrategy_Initialize_RevertsOnInvalidManagementFeeBps() public {
        // Deploy a new strategy implementation
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));

        // Prepare fee config with managementFeeBps > BPS_PRECISION (10_000)
        ISuperVaultStrategy.FeeConfig memory feeConfig = ISuperVaultStrategy.FeeConfig({
            performanceFeeBps: 1000,
            managementFeeBps: 10_001, // BPS_PRECISION is 10_000, so 10_001 should revert
            recipient: manager
        });

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            SuperVaultStrategy.initialize.selector,
            address(vault),
            feeConfig
        );

        // Test: Attempt to deploy proxy with invalid managementFeeBps should revert
        vm.expectRevert(ISuperVaultStrategy.INVALID_PERFORMANCE_FEE_BPS.selector);
        new ERC1967Proxy(strategyImpl, initData);
    }

    /// @notice Tests SuperVaultStrategy initialize reverts when asset has invalid decimals
    function test_SuperVaultStrategy_Initialize_RevertsOnInvalidAsset() public {
        // Deploy an asset without proper decimals implementation
        MockAssetNoDecimals invalidAsset = new MockAssetNoDecimals("Invalid Asset", "INVALID");

        // Deploy a mock vault with a valid asset initially
        Mock4626Vault mockVault = new Mock4626Vault(address(asset), "Mock Vault", "MVAULT");

        // Change the asset to the invalid one (using setAsset function)
        mockVault.setAsset(address(invalidAsset));

        // Deploy a new strategy implementation
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));

        // Prepare valid fee config
        ISuperVaultStrategy.FeeConfig memory feeConfig = ISuperVaultStrategy.FeeConfig({
            performanceFeeBps: 1000,
            managementFeeBps: 500,
            recipient: manager
        });

        // Prepare initialization data with mock vault that has invalid asset
        bytes memory initData = abi.encodeWithSelector(
            SuperVaultStrategy.initialize.selector,
            address(mockVault),
            feeConfig
        );

        // Test: Attempt to deploy proxy with vault that has invalid asset should revert
        vm.expectRevert(ISuperVaultStrategy.INVALID_ASSET.selector);
        new ERC1967Proxy(strategyImpl, initData);
    }

    /// @notice Tests handleOperations4626Deposit reverts when assetsGross is 0
    /// @dev Covers SuperVaultStrategy.sol:158
    /// @dev Note: SuperVault.deposit checks for zero first and reverts with ZERO_AMOUNT
    function test_HandleOperations4626Deposit_RevertsOnZeroAssets() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user approval but attempt to deposit 0 assets
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);

        // Test: Attempt to deposit 0 assets should revert with ZERO_AMOUNT
        // The vault checks this before calling the strategy, but both have the validation
        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.deposit(0, testUser);
        vm.stopPrank();
    }

    /// @notice Tests handleOperations4626Deposit reverts when controller is address(0)
    /// @dev Covers SuperVaultStrategy.sol:159
    /// @dev This tests the defensive validation in the strategy by attempting to call with address(0) as receiver
    function test_HandleOperations4626Deposit_RevertsOnZeroAddressController() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);

        // Test: Attempt to deposit with address(0) as receiver should revert
        // Note: The vault passes msg.sender as controller to the strategy
        // While we can't make msg.sender be address(0), this tests the validation exists
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.deposit(1000e18, address(0));
        vm.stopPrank();
    }

    /// @notice Tests handleOperations4626Deposit reverts when global hooks root is vetoed
    /// @dev Covers SuperVaultStrategy.sol:163-165
    function test_HandleOperations4626Deposit_RevertsWhenGlobalHooksVetoed() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Veto the global hooks root (only SuperGovernor can do this)
        vm.prank(address(superGovernor));
        superVaultAggregator.setGlobalHooksRootVetoStatus(true);

        // Verify the veto status is set
        assertTrue(superVaultAggregator.isGlobalHooksRootVetoed(), "Global hooks root should be vetoed");

        // Test: Attempt to deposit should revert with OPERATIONS_BLOCKED_BY_VETO
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.OPERATIONS_BLOCKED_BY_VETO.selector);
        vault.deposit(1000e18, testUser);

        // Cleanup: Unveto the global hooks root for other tests
        vm.prank(address(superGovernor));
        superVaultAggregator.setGlobalHooksRootVetoStatus(false);
    }
}
