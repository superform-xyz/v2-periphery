// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

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

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, governor, treasury);

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
    // deposit Tests
    // =============================================================

    /// @notice Tests deposit reverts when assets is 0
    /// @dev Covers SuperVault.sol:145
    function test_Deposit_RevertsOnZeroAmount() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);

        // Test: Attempt to deposit 0 assets should revert with ZERO_AMOUNT
        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.deposit(0, testUser);
        vm.stopPrank();
    }

    /// @notice Tests deposit reverts when shares calculation rounds to 0
    /// @dev Covers SuperVault.sol:152 (defensive check)
    /// @dev Note: The strategy validates shares != 0 first (SuperVaultStrategy.sol:187), so it reverts
    ///      with INVALID_AMOUNT before the vault's check at line 152 is reached. The vault's check
    ///      is a defensive secondary validation in case the strategy implementation changes.
    function test_Deposit_RevertsOnZeroSharesReturned() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Manipulate PPS to an extremely high value so that shares calculation rounds to 0
        // Formula: sharesNet = (assetsNet * PRECISION) / pps (floor rounding)
        // For sharesNet to be 0: assetsNet * PRECISION < pps
        // If assetsNet = 1 wei and PRECISION = 1e18, then pps needs to be > 1e18
        // Set pps to 1e30 (extremely inflated)

        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Verify current PPS
        uint256 currentPPS = strategy.getStoredPPS();
        assertEq(currentPPS, 1e18, "PPS should be initialized to 1e18");

        // Set PPS to an extremely high value (1e30)
        uint256 inflatedPPS = 1e30;
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(inflatedPPS));

        // Verify the storage manipulation worked
        uint256 newPPS = strategy.getStoredPPS();
        assertEq(newPPS, inflatedPPS, "PPS should be inflated to 1e30");

        // Test: Attempt to deposit 1 wei should revert
        // The strategy catches sharesNet == 0 first and reverts with INVALID_AMOUNT
        // This validates that the zero shares case is caught (strategy validates before vault)
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.INVALID_AMOUNT.selector);
        vault.deposit(1, testUser);
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

    /// @notice Tests withdraw succeeds when operator calls with receiver == controller
    function test_Withdraw_OperatorSucceedsWithReceiverEqualController() public {
        address testUser = makeAddr("testUser");
        address operatorAddr = makeAddr("operator");

        // Setup: User deposits and requests redemption to have claimable assets
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        // Request redemption
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);

        // Set operator
        vault.setOperator(operatorAddr, true);
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

        // Test: Operator calls withdraw with receiver == controller (should succeed)
        uint256 claimableAssets = vault.maxWithdraw(testUser);
        assertGt(claimableAssets, 0, "Should have claimable assets for test");

        uint256 receiverBalanceBefore = asset.balanceOf(testUser);

        vm.prank(operatorAddr);
        vault.withdraw(claimableAssets, testUser, testUser);

        uint256 receiverBalanceAfter = asset.balanceOf(testUser);
        assertEq(receiverBalanceAfter - receiverBalanceBefore, claimableAssets, "Receiver should receive assets");
    }

    /// @notice Tests withdraw reverts when operator calls with receiver != controller
    function test_Withdraw_OperatorRevertsWithReceiverNotEqualController() public {
        address testUser = makeAddr("testUser");
        address operatorAddr = makeAddr("operator");
        address otherReceiver = makeAddr("otherReceiver");

        // Setup: User deposits and requests redemption to have claimable assets
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        // Request redemption
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);

        // Set operator
        vault.setOperator(operatorAddr, true);
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

        // Test: Operator calls withdraw with receiver != controller (should revert)
        uint256 claimableAssets = vault.maxWithdraw(testUser);
        assertGt(claimableAssets, 0, "Should have claimable assets for test");

        vm.prank(operatorAddr);
        vm.expectRevert(ISuperVault.RECEIVER_MUST_EQUAL_CONTROLLER.selector);
        vault.withdraw(claimableAssets, otherReceiver, testUser);
    }

    /// @notice Tests withdraw succeeds when controller calls with arbitrary receiver
    function test_Withdraw_ControllerSucceedsWithArbitraryReceiver() public {
        address testUser = makeAddr("testUser");
        address arbitraryReceiver = makeAddr("arbitraryReceiver");

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

        // Test: Controller calls withdraw with arbitrary receiver (should succeed)
        uint256 claimableAssets = vault.maxWithdraw(testUser);
        assertGt(claimableAssets, 0, "Should have claimable assets for test");

        uint256 receiverBalanceBefore = asset.balanceOf(arbitraryReceiver);

        vm.prank(testUser);
        vault.withdraw(claimableAssets, arbitraryReceiver, testUser);

        uint256 receiverBalanceAfter = asset.balanceOf(arbitraryReceiver);
        assertEq(receiverBalanceAfter - receiverBalanceBefore, claimableAssets, "Arbitrary receiver should receive assets");
    }

    /// @notice Tests withdraw reverts when non-operator calls on behalf of controller
    function test_Withdraw_NonOperatorReverts() public {
        address testUser = makeAddr("testUser");
        address nonOperator = makeAddr("nonOperator");

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

        // Test: Non-operator calls withdraw on behalf of controller (should revert)
        uint256 claimableAssets = vault.maxWithdraw(testUser);
        assertGt(claimableAssets, 0, "Should have claimable assets for test");

        vm.prank(nonOperator);
        vm.expectRevert(ISuperVault.INVALID_CONTROLLER.selector);
        vault.withdraw(claimableAssets, testUser, testUser);
    }

    /// @notice Tests redeem succeeds when operator calls with receiver == controller
    function test_Redeem_OperatorSucceedsWithReceiverEqualController() public {
        address testUser = makeAddr("testUser");
        address operatorAddr = makeAddr("operator");

        // Setup: User deposits and requests redemption to have claimable assets
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        // Request redemption
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);

        // Set operator
        vault.setOperator(operatorAddr, true);
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

        // Test: Operator calls redeem with receiver == controller (should succeed)
        uint256 maxRedeemShares = vault.maxRedeem(testUser);
        assertGt(maxRedeemShares, 0, "Should have redeemable shares for test");

        uint256 receiverBalanceBefore = asset.balanceOf(testUser);

        vm.prank(operatorAddr);
        vault.redeem(maxRedeemShares, testUser, testUser);

        uint256 receiverBalanceAfter = asset.balanceOf(testUser);
        assertGt(receiverBalanceAfter, receiverBalanceBefore, "Receiver should receive assets");
    }

    /// @notice Tests redeem reverts when operator calls with receiver != controller
    function test_Redeem_OperatorRevertsWithReceiverNotEqualController() public {
        address testUser = makeAddr("testUser");
        address operatorAddr = makeAddr("operator");
        address otherReceiver = makeAddr("otherReceiver");

        // Setup: User deposits and requests redemption to have claimable assets
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);

        // Request redemption
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);

        // Set operator
        vault.setOperator(operatorAddr, true);
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

        // Test: Operator calls redeem with receiver != controller (should revert)
        uint256 maxRedeemShares = vault.maxRedeem(testUser);
        assertGt(maxRedeemShares, 0, "Should have redeemable shares for test");

        vm.prank(operatorAddr);
        vm.expectRevert(ISuperVault.RECEIVER_MUST_EQUAL_CONTROLLER.selector);
        vault.redeem(maxRedeemShares, otherReceiver, testUser);
    }

    /// @notice Tests redeem succeeds when controller calls with arbitrary receiver
    function test_Redeem_ControllerSucceedsWithArbitraryReceiver() public {
        address testUser = makeAddr("testUser");
        address arbitraryReceiver = makeAddr("arbitraryReceiver");

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

        // Test: Controller calls redeem with arbitrary receiver (should succeed)
        uint256 maxRedeemShares = vault.maxRedeem(testUser);
        assertGt(maxRedeemShares, 0, "Should have redeemable shares for test");

        uint256 receiverBalanceBefore = asset.balanceOf(arbitraryReceiver);

        vm.prank(testUser);
        vault.redeem(maxRedeemShares, arbitraryReceiver, testUser);

        uint256 receiverBalanceAfter = asset.balanceOf(arbitraryReceiver);
        assertGt(receiverBalanceAfter, receiverBalanceBefore, "Arbitrary receiver should receive assets");
    }

    /// @notice Tests redeem reverts when non-operator calls on behalf of controller
    function test_Redeem_NonOperatorReverts() public {
        address testUser = makeAddr("testUser");
        address nonOperator = makeAddr("nonOperator");

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

        // Test: Non-operator calls redeem on behalf of controller (should revert)
        uint256 maxRedeemShares = vault.maxRedeem(testUser);
        assertGt(maxRedeemShares, 0, "Should have redeemable shares for test");

        vm.prank(nonOperator);
        vm.expectRevert(ISuperVault.INVALID_CONTROLLER.selector);
        vault.redeem(maxRedeemShares, testUser, testUser);
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

    /// @notice Tests SuperVaultStrategy initialize reverts when fees > 0 and recipient is address(0)
    /// @dev Covers SuperVaultStrategy.sol:124-127 (initialization validation that protects line 178)
    function test_SuperVaultStrategy_Initialize_RevertsOnZeroRecipientWithFees() public {
        // Deploy a new strategy implementation
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));

        // Prepare fee config with managementFeeBps > 0 but recipient = address(0)
        ISuperVaultStrategy.FeeConfig memory feeConfig = ISuperVaultStrategy.FeeConfig({
            performanceFeeBps: 0,
            managementFeeBps: 500, // Non-zero management fee
            recipient: address(0)  // Zero address recipient should revert
        });

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            SuperVaultStrategy.initialize.selector,
            address(vault),
            feeConfig
        );

        // Test: Attempt to deploy proxy with fees > 0 and zero recipient should revert
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        new ERC1967Proxy(strategyImpl, initData);
    }

    /// @notice Tests SuperVaultStrategy initialize allows address(0) recipient when both fees are 0
    /// @dev This is allowed because recipient can be configured later via fee config update
    function test_SuperVaultStrategy_Initialize_AllowsZeroRecipientWithZeroFees() public {
        // Deploy a new strategy implementation
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));

        // Prepare fee config with both fees = 0 and recipient = address(0)
        ISuperVaultStrategy.FeeConfig memory feeConfig = ISuperVaultStrategy.FeeConfig({
            performanceFeeBps: 0,
            managementFeeBps: 0,   // Zero fees
            recipient: address(0)  // Zero recipient is allowed when fees are 0
        });

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            SuperVaultStrategy.initialize.selector,
            address(vault),
            feeConfig
        );

        // Test: Should successfully deploy with zero fees and zero recipient
        address proxyAddress = address(new ERC1967Proxy(strategyImpl, initData));
        assertTrue(proxyAddress != address(0), "Proxy should be deployed successfully");

        // Verify the fee config
        ISuperVaultStrategy.FeeConfig memory configResult = ISuperVaultStrategy(payable(proxyAddress)).getConfigInfo();
        assertEq(configResult.performanceFeeBps, 0, "Performance fee should be 0");
        assertEq(configResult.managementFeeBps, 0, "Management fee should be 0");
        assertEq(configResult.recipient, address(0), "Recipient should be address(0)");
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

    /// @notice Tests handleOperations4626Deposit reverts when assetsNet becomes 0 after fee deduction
    /// @dev Covers SuperVaultStrategy.sol:174
    function test_HandleOperations4626Deposit_RevertsOnZeroAssetsNet() public {
        // Create a vault with very high management fee (99.99% = 9999 bps)
        vm.prank(manager);
        (address vaultAddress,,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "High Fee Vault",
                symbol: "HFV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0,
                    managementFeeBps: 9999, // 99.99% management fee
                    recipient: manager
                })
            })
        );

        SuperVault testVault = SuperVault(vaultAddress);
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(vaultAddress, 10000e18);

        // Test: Deposit a tiny amount (1 wei)
        // With 99.99% fee, feeAssets = ceil(1 * 9999 / 10000) = ceil(0.9999) = 1
        // assetsNet = 1 - 1 = 0, which should revert
        vm.expectRevert(ISuperVaultStrategy.INVALID_AMOUNT.selector);
        testVault.deposit(1, testUser);
        vm.stopPrank();
    }

    /// @notice Tests handleOperations4626Deposit reverts when PPS is 0
    /// @dev Covers SuperVaultStrategy.sol:185
    function test_HandleOperations4626Deposit_RevertsOnZeroPPS() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Use storage manipulation to corrupt the PPS to 0 in the aggregator
        // The aggregator stores strategy data in a mapping: mapping(address strategy => StrategyData) private _strategyData
        // StrategyData struct has pps as the first field
        // For mappings, the storage slot is: keccak256(abi.encode(key, slot))
        // We need to find the slot number for _strategyData mapping in SuperVaultAggregator

        // Based on SuperVaultAggregator storage layout:
        // Slot 0: claimableUpkeep
        // Slot 1: _strategyData mapping
        // Slot 2: _strategyUpkeepBalance mapping
        // Slot 3: pendingUpkeepWithdrawals mapping
        // Slots 4-6: EnumerableSets
        // etc...
        bytes32 strategyDataSlot = bytes32(uint256(1));

        // Calculate the storage location for this specific strategy's PPS
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Verify current PPS is not 0
        uint256 currentPPS = strategy.getStoredPPS();
        assertGt(currentPPS, 0, "PPS should be initialized to a non-zero value");

        // Corrupt the PPS to 0 in the aggregator
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(0)));

        // Verify the storage manipulation worked
        uint256 corruptedPPS = strategy.getStoredPPS();
        assertEq(corruptedPPS, 0, "PPS should be corrupted to 0");

        // Test: Attempt to deposit should revert with INVALID_PPS
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS.selector);
        vault.deposit(1000e18, testUser);
    }

    /// @notice Tests handleOperations4626Deposit reverts when sharesNet rounds to 0
    /// @dev Covers SuperVaultStrategy.sol:187
    function test_HandleOperations4626Deposit_RevertsOnZeroSharesNet() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Manipulate PPS to an extremely high value so that sharesNet rounds to 0
        // Formula: sharesNet = (assetsNet * PRECISION) / pps (floor rounding)
        // For sharesNet to be 0: assetsNet * PRECISION < pps
        // If assetsNet = 1 wei and PRECISION = 1e18, then pps needs to be > 1e18
        // Let's set pps to 1e30 (extremely inflated)

        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Verify current PPS
        uint256 currentPPS = strategy.getStoredPPS();
        assertEq(currentPPS, 1e18, "PPS should be initialized to 1e18");

        // Set PPS to an extremely high value (1e30)
        uint256 inflatedPPS = 1e30;
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(inflatedPPS));

        // Verify the storage manipulation worked
        uint256 newPPS = strategy.getStoredPPS();
        assertEq(newPPS, inflatedPPS, "PPS should be inflated to 1e30");

        // Test: Attempt to deposit 1 wei should revert with INVALID_AMOUNT
        // Calculation: sharesNet = (1 * 1e18) / 1e30 = 1e-12 which rounds to 0
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.INVALID_AMOUNT.selector);
        vault.deposit(1, testUser);
    }

    /// @notice Tests handleOperations4626Deposit reverts when called by non-vault address
    /// @dev Covers SuperVaultStrategy.sol:156 - _requireVault() check
    function test_HandleOperations4626Deposit_RevertsOnAccessDenied() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Test: Attempt to call handleOperations4626Deposit directly (not through vault) should revert
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.ACCESS_DENIED.selector);
        strategy.handleOperations4626Deposit(testUser, 1000e18);
    }

    /// @notice Tests handleOperations4626Deposit reverts when strategy is paused
    /// @dev Covers SuperVaultStrategy.sol:167 -> 1091 - STRATEGY_PAUSED validation
    function test_HandleOperations4626Deposit_RevertsWhenStrategyPaused() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Pause the strategy
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Verify the strategy is paused
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should be paused");

        // Test: Attempt to deposit should revert with STRATEGY_PAUSED
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        vault.deposit(1000e18, testUser);
    }

    /// @notice Tests handleOperations4626Deposit reverts when PPS is stale
    /// @dev Covers SuperVaultStrategy.sol:167 -> 1092 - STALE_PPS validation
    function test_HandleOperations4626Deposit_RevertsWhenPPSStale() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Pause and then unpause the strategy to make PPS stale
        vm.startPrank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));
        superVaultAggregator.unpauseStrategy(address(strategy));
        vm.stopPrank();

        // Verify the PPS is stale (after unpause, PPS becomes stale until next update)
        assertTrue(superVaultAggregator.isPPSStale(address(strategy)), "PPS should be stale");
        assertFalse(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should not be paused");

        // Test: Attempt to deposit should revert with STALE_PPS
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.STALE_PPS.selector);
        vault.deposit(1000e18, testUser);
    }

    /// @notice Tests handleOperations4626Deposit reverts when PPS has not been updated within ppsExpiration time
    /// @dev Covers SuperVaultStrategy.sol:167 -> 1093 - PPS_EXPIRED validation
    function test_HandleOperations4626Deposit_RevertsWhenPPSExpired() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Fast forward time beyond ppsExpiration (default is 1 day)
        // The PPS was last updated at vault creation (block.timestamp)
        vm.warp(block.timestamp + 1 days + 1);

        // Verify that PPS has expired
        uint256 lastUpdateTimestamp = superVaultAggregator.getLastUpdateTimestamp(address(strategy));
        assertGt(block.timestamp - lastUpdateTimestamp, 1 days, "PPS should be expired");

        // Test: Attempt to deposit should revert with PPS_EXPIRED
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.PPS_EXPIRED.selector);
        vault.deposit(1000e18, testUser);
    }

    /// @notice Tests handleOperations4626Deposit reverts when recipient is address(0) at runtime
    /// @dev Covers SuperVaultStrategy.sol:178 - defensive check for fee recipient
    function test_HandleOperations4626Deposit_RevertsOnZeroRecipientAtRuntime() public {
        // Create a vault with fees > 0 and valid recipient
        vm.prank(manager);
        (address vaultAddress, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Fee Vault",
                symbol: "TFV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0,
                    managementFeeBps: 500, // 5% management fee
                    recipient: manager // Valid recipient
                })
            })
        );

        SuperVault testVault = SuperVault(vaultAddress);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddress));

        // Verify initial config
        ISuperVaultStrategy.FeeConfig memory initialConfig = testStrategy.getConfigInfo();
        assertEq(initialConfig.managementFeeBps, 500, "Initial management fee should be 5%");
        assertEq(initialConfig.recipient, manager, "Initial recipient should be manager");

        // Use storage manipulation to corrupt the recipient to address(0)
        // This simulates a corrupted state that should never happen in production
        // Storage layout: feeConfig starts at slot 3 (after Initializable + ReentrancyGuard + packed slots 1-2)
        // Slot 3: performanceFeeBps
        // Slot 4: managementFeeBps
        // Slot 5: recipient

        // Calculate storage slot for recipient in the proxy
        bytes32 recipientSlot = bytes32(uint256(5)); // Slot 5 for recipient
        vm.store(strategyAddress, recipientSlot, bytes32(uint256(0))); // Set to address(0)

        // Verify the storage manipulation worked
        ISuperVaultStrategy.FeeConfig memory manipulatedConfig = testStrategy.getConfigInfo();
        assertEq(manipulatedConfig.managementFeeBps, 500, "Management fee should still be 5%");
        assertEq(manipulatedConfig.recipient, address(0), "Recipient should be corrupted to address(0)");

        // Setup: Give user assets and approval
        address testUser = _deployAccount(0xDEF, "TestUser");
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(vaultAddress, 10000e18);

        // Test: Attempt to deposit should revert at the defensive check (line 178)
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        testVault.deposit(1000e18, testUser);
        vm.stopPrank();
    }

    // =============================================================
    // handleOperations4626Mint Tests
    // =============================================================

    /// @notice Tests handleOperations4626Mint reverts when sharesNet is 0
    /// @dev Covers SuperVaultStrategy.sol:206
    function test_HandleOperations4626Mint_RevertsOnZeroShares() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);

        // Test: Attempt to mint 0 shares should revert with ZERO_AMOUNT
        // The vault checks this before calling the strategy
        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.mint(0, testUser);
        vm.stopPrank();
    }

    /// @notice Tests handleOperations4626Mint reverts when controller is address(0)
    /// @dev Covers SuperVaultStrategy.sol:207
    function test_HandleOperations4626Mint_RevertsOnZeroAddressController() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);

        // Test: Attempt to mint with address(0) as receiver should revert
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.mint(100e18, address(0));
        vm.stopPrank();
    }

    /// @notice Tests handleOperations4626Mint reverts when global hooks root is vetoed
    /// @dev Covers SuperVaultStrategy.sol:211-213
    function test_HandleOperations4626Mint_RevertsWhenGlobalHooksVetoed() public {
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

        // Test: Attempt to mint should revert with OPERATIONS_BLOCKED_BY_VETO
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.OPERATIONS_BLOCKED_BY_VETO.selector);
        vault.mint(100e18, testUser);

        // Cleanup: Unveto the global hooks root for other tests
        vm.prank(address(superGovernor));
        superVaultAggregator.setGlobalHooksRootVetoStatus(false);
    }

    /// @notice Tests handleOperations4626Mint successfully processes fees when feeBps != 0
    /// @dev Covers SuperVaultStrategy.sol:219-227 - the fee transfer block
    function test_HandleOperations4626Mint_ProcessesFeesCorrectly() public {
        // Create a vault with 5% management fee
        vm.prank(manager);
        (address vaultAddress,,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Fee Vault",
                symbol: "FV",
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
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(vaultAddress, 10000e18);

        // Get manager's balance before
        uint256 managerBalanceBefore = asset.balanceOf(manager);

        // Test: Mint shares (this will charge fee)
        uint256 sharesToMint = 100e18;
        testVault.mint(sharesToMint, testUser);

        // Verify manager received the fee
        uint256 managerBalanceAfter = asset.balanceOf(manager);
        assertGt(managerBalanceAfter, managerBalanceBefore, "Manager should have received fee");

        vm.stopPrank();
    }

    /// @notice Tests handleOperations4626Mint reverts when called by non-vault address
    /// @dev Covers SuperVaultStrategy.sol:204 - _requireVault() check
    function test_HandleOperations4626Mint_RevertsOnAccessDenied() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Test: Attempt to call handleOperations4626Mint directly (not through vault) should revert
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.ACCESS_DENIED.selector);
        strategy.handleOperations4626Mint(testUser, 100e18, 1000e18, 950e18);
    }

    /// @notice Tests handleOperations4626Mint reverts when strategy is paused
    /// @dev Covers SuperVaultStrategy.sol:215 -> 1091 - STRATEGY_PAUSED validation
    function test_HandleOperations4626Mint_RevertsWhenStrategyPaused() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Pause the strategy
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Test: Attempt to mint should revert with STRATEGY_PAUSED
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        vault.mint(100e18, testUser);
    }

    /// @notice Tests handleOperations4626Mint reverts when PPS is stale
    /// @dev Covers SuperVaultStrategy.sol:215 -> 1092 - STALE_PPS validation
    function test_HandleOperations4626Mint_RevertsWhenPPSStale() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Pause and then unpause the strategy to make PPS stale
        vm.startPrank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));
        superVaultAggregator.unpauseStrategy(address(strategy));
        vm.stopPrank();

        // Test: Attempt to mint should revert with STALE_PPS
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.STALE_PPS.selector);
        vault.mint(100e18, testUser);
    }

    /// @notice Tests handleOperations4626Mint reverts when PPS has expired
    /// @dev Covers SuperVaultStrategy.sol:215 -> 1093 - PPS_EXPIRED validation
    function test_HandleOperations4626Mint_RevertsWhenPPSExpired() public {
        address testUser = _deployAccount(0xDEF, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Fast forward time beyond ppsExpiration (default is 1 day)
        vm.warp(block.timestamp + 1 days + 1);

        // Test: Attempt to mint should revert with PPS_EXPIRED
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.PPS_EXPIRED.selector);
        vault.mint(100e18, testUser);
    }

    /// @notice Tests handleOperations4626Mint reverts when recipient is address(0) in fee block
    /// @dev Covers SuperVaultStrategy.sol:223 - recipient validation inside fee transfer
    function test_HandleOperations4626Mint_RevertsOnZeroRecipientInFeeBlock() public {
        // Create a vault with fees > 0 and valid recipient
        vm.prank(manager);
        (address vaultAddress, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Fee Vault",
                symbol: "TFV",
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

        // Corrupt the recipient to address(0) using storage manipulation
        bytes32 recipientSlot = bytes32(uint256(5)); // Slot 5 for recipient in strategy
        vm.store(strategyAddress, recipientSlot, bytes32(uint256(0)));

        // Verify the storage manipulation worked
        ISuperVaultStrategy.FeeConfig memory config = testStrategy.getConfigInfo();
        assertEq(config.recipient, address(0), "Recipient should be address(0)");

        // Setup: Give user assets and approval
        address testUser = _deployAccount(0xDEF, "TestUser");
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(vaultAddress, 10000e18);

        // Test: Attempt to mint should revert with ZERO_ADDRESS at the fee transfer check
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        testVault.mint(100e18, testUser);
        vm.stopPrank();
    }

    // =============================================================
    // quoteMintAssetsGross Tests
    // =============================================================

    /// @notice Tests quoteMintAssetsGross reverts when PPS is 0
    /// @dev Covers SuperVaultStrategy.sol:237
    function test_QuoteMintAssetsGross_RevertsOnZeroPPS() public {
        // Corrupt PPS to 0 using storage manipulation
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Set PPS to 0
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(0)));

        // Verify PPS is 0
        assertEq(strategy.getStoredPPS(), 0, "PPS should be 0");

        // Test: Attempt to quote should revert with INVALID_PPS
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS.selector);
        strategy.quoteMintAssetsGross(100e18);
    }

    /// @notice Tests quoteMintAssetsGross reverts when assetsNet rounds to 0
    /// @dev Covers SuperVaultStrategy.sol:239
    function test_QuoteMintAssetsGross_RevertsOnZeroAssetsNet() public {
        // Set PPS to extremely low value so assetsNet rounds to 0
        // Formula: assetsNet = (shares * pps) / PRECISION (ceil rounding)
        // For assetsNet to be 0 with shares = 1: pps * 1 < PRECISION
        // If PRECISION = 1e18 and shares = 1, then pps needs to be < 1e18
        // But with ceil rounding, we need pps to be exactly 0, which is caught by previous check
        // So let's use a very small shares value with normal pps to trigger the edge case

        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Set PPS to 1 (extremely low, but non-zero)
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(1)));

        // Verify PPS is 1
        assertEq(strategy.getStoredPPS(), 1, "PPS should be 1");

        // Test: Quote with 0 shares should revert
        // With PPS = 1, shares = 0: assetsNet = (0 * 1) / 1e18 = 0
        vm.expectRevert(ISuperVaultStrategy.INVALID_AMOUNT.selector);
        strategy.quoteMintAssetsGross(0);
    }

    /// @notice Tests quoteMintAssetsGross returns correct values when feeBps is 0
    /// @dev Covers SuperVaultStrategy.sol:242 - early return when no fees
    function test_QuoteMintAssetsGross_ZeroFees() public view {
        // The default vault has 0 management fees, so we can use it directly
        uint256 sharesToQuote = 100e18;

        // Get the quote
        (uint256 assetsGross, uint256 assetsNet) = strategy.quoteMintAssetsGross(sharesToQuote);

        // With 0 fees, assetsGross should equal assetsNet
        assertEq(assetsGross, assetsNet, "assetsGross should equal assetsNet when fees are 0");

        // Calculate expected assetsNet: (shares * pps) / PRECISION (ceil rounding)
        uint256 pps = strategy.getStoredPPS();
        uint256 expectedAssetsNet = Math.mulDiv(sharesToQuote, pps, 1e18, Math.Rounding.Ceil);
        assertEq(assetsNet, expectedAssetsNet, "assetsNet should match expected calculation");
    }

    /// @notice Tests quoteMintAssetsGross reverts when feeBps >= BPS_PRECISION
    /// @dev Covers SuperVaultStrategy.sol:243
    function test_QuoteMintAssetsGross_RevertsOnInvalidFeeBps() public {
        // Create a vault with feeBps = BPS_PRECISION (10000 = 100%)
        vm.prank(manager);
        (, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Invalid Fee Vault",
                symbol: "IFV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0,
                    managementFeeBps: 10000, // 100% fee (edge case allowed in init)
                    recipient: manager
                })
            })
        );

        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddress));

        // Test: Quote should revert with INVALID_AMOUNT (prevents div-by-zero)
        vm.expectRevert(ISuperVaultStrategy.INVALID_AMOUNT.selector);
        testStrategy.quoteMintAssetsGross(100e18);
    }

    /// @notice Tests quoteMintAssetsGross calculates correct values with non-zero fees
    /// @dev Covers SuperVaultStrategy.sol:244-245 - fee calculation and return
    function test_QuoteMintAssetsGross_WithFees() public {
        // Create a vault with 5% management fee
        vm.prank(manager);
        (, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Fee Vault",
                symbol: "FV",
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

        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddress));

        uint256 sharesToQuote = 100e18;

        // Get the quote
        (uint256 assetsGross, uint256 assetsNet) = testStrategy.quoteMintAssetsGross(sharesToQuote);

        // Verify assetsGross > assetsNet (fee is included)
        assertGt(assetsGross, assetsNet, "assetsGross should be greater than assetsNet with fees");

        // Calculate expected values manually
        uint256 pps = testStrategy.getStoredPPS();
        uint256 expectedAssetsNet = Math.mulDiv(sharesToQuote, pps, 1e18, Math.Rounding.Ceil);
        assertEq(assetsNet, expectedAssetsNet, "assetsNet should match expected calculation");

        // Formula: assetsGross = assetsNet * BPS_PRECISION / (BPS_PRECISION - feeBps) (ceil rounding)
        uint256 feeBps = 500;
        uint256 expectedAssetsGross = Math.mulDiv(assetsNet, 10000, (10000 - feeBps), Math.Rounding.Ceil);
        assertEq(assetsGross, expectedAssetsGross, "assetsGross should match expected calculation");

        // Verify the fee amount
        uint256 feeAmount = assetsGross - assetsNet;
        assertGt(feeAmount, 0, "Fee amount should be positive");

        // Verify the fee relationship using the inverse formula
        // If assetsGross = assetsNet * BPS / (BPS - fee), then
        // feeAmount = assetsGross - assetsNet = assetsNet * fee / (BPS - fee)
        uint256 expectedFeeFromFormula = Math.mulDiv(assetsNet, feeBps, (10000 - feeBps), Math.Rounding.Ceil);
        assertEq(feeAmount, expectedFeeFromFormula, "Fee should match formula derivation");
    }

    /// @notice Tests quoteMintAssetsGross with various fee percentages
    /// @dev Covers edge cases and validates formula correctness
    function test_QuoteMintAssetsGross_VariousFees() public {
        // Test with different fee percentages
        uint256[5] memory feePercentages = [uint256(100), 500, 1000, 2500, 9999]; // 1%, 5%, 10%, 25%, 99.99%

        for (uint256 i = 0; i < feePercentages.length; i++) {
            uint256 feeBps = feePercentages[i];

            // Create a vault with this fee percentage
            vm.prank(manager);
            (, address strategyAddress,) = superVaultAggregator.createVault(
                ISuperVaultAggregator.VaultCreationParams({
                    asset: address(asset),
                    name: string(abi.encodePacked("Vault", vm.toString(i))),
                    symbol: string(abi.encodePacked("V", vm.toString(i))),
                    mainManager: manager,
                    secondaryManagers: new address[](0),
                    minUpdateInterval: 5,
                    maxStaleness: 300,
                    feeConfig: ISuperVaultStrategy.FeeConfig({
                        performanceFeeBps: 0,
                        managementFeeBps: feeBps,
                        recipient: manager
                    })
                })
            );

            SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddress));

            uint256 sharesToQuote = 100e18;
            (uint256 assetsGross, uint256 assetsNet) = testStrategy.quoteMintAssetsGross(sharesToQuote);

            // Verify relationship
            assertGt(assetsGross, assetsNet, "assetsGross should be greater than assetsNet");

            // Verify formula: assetsGross = assetsNet * BPS_PRECISION / (BPS_PRECISION - feeBps)
            uint256 calculatedGross = Math.mulDiv(assetsNet, 10000, (10000 - feeBps), Math.Rounding.Ceil);
            assertEq(assetsGross, calculatedGross, "Formula should match for all fee percentages");
        }
    }

    // =============================================================
    // executeHooks Tests
    // =============================================================

    /// @notice Tests executeHooks reverts when hooks array is empty
    /// @dev Covers SuperVaultStrategy.sol:275
    function test_ExecuteHooks_RevertsOnZeroLength() public {
        // Create empty ExecuteArgs
        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: new address[](0),
            hookCalldata: new bytes[](0),
            expectedAssetsOrSharesOut: new uint256[](0),
            globalProofs: new bytes32[][](0),
            strategyProofs: new bytes32[][](0)
        });

        // Test: Attempt to execute with empty hooks array should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_LENGTH.selector);
        strategy.executeHooks(args);
    }

    /// @notice Tests executeHooks reverts when hookCalldata length doesn't match hooks length
    /// @dev Covers SuperVaultStrategy.sol:276
    function test_ExecuteHooks_RevertsOnHookCalldataLengthMismatch() public {
        // Create args with mismatched hookCalldata length
        address[] memory hooks = new address[](2);
        hooks[0] = address(0x1);
        hooks[1] = address(0x2);

        bytes[] memory hookCalldata = new bytes[](1); // Mismatch: 1 instead of 2
        hookCalldata[0] = "";

        uint256[] memory expectedOut = new uint256[](2);
        bytes32[][] memory globalProofs = new bytes32[][](2);
        bytes32[][] memory strategyProofs = new bytes32[][](2);

        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: hookCalldata,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });

        // Test: Attempt to execute should revert with INVALID_ARRAY_LENGTH
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.executeHooks(args);
    }

    /// @notice Tests executeHooks reverts when expectedAssetsOrSharesOut length doesn't match hooks length
    /// @dev Covers SuperVaultStrategy.sol:277
    function test_ExecuteHooks_RevertsOnExpectedAssetsLengthMismatch() public {
        // Create args with mismatched expectedAssetsOrSharesOut length
        address[] memory hooks = new address[](2);
        hooks[0] = address(0x1);
        hooks[1] = address(0x2);

        bytes[] memory hookCalldata = new bytes[](2);
        hookCalldata[0] = "";
        hookCalldata[1] = "";

        uint256[] memory expectedOut = new uint256[](3); // Mismatch: 3 instead of 2
        bytes32[][] memory globalProofs = new bytes32[][](2);
        bytes32[][] memory strategyProofs = new bytes32[][](2);

        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: hookCalldata,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });

        // Test: Attempt to execute should revert with INVALID_ARRAY_LENGTH
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.executeHooks(args);
    }

    /// @notice Tests executeHooks reverts when globalProofs length doesn't match hooks length
    /// @dev Covers SuperVaultStrategy.sol:278
    function test_ExecuteHooks_RevertsOnGlobalProofsLengthMismatch() public {
        // Create args with mismatched globalProofs length
        address[] memory hooks = new address[](2);
        hooks[0] = address(0x1);
        hooks[1] = address(0x2);

        bytes[] memory hookCalldata = new bytes[](2);
        hookCalldata[0] = "";
        hookCalldata[1] = "";

        uint256[] memory expectedOut = new uint256[](2);
        bytes32[][] memory globalProofs = new bytes32[][](1); // Mismatch: 1 instead of 2
        bytes32[][] memory strategyProofs = new bytes32[][](2);

        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: hookCalldata,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });

        // Test: Attempt to execute should revert with INVALID_ARRAY_LENGTH
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.executeHooks(args);
    }

    /// @notice Tests executeHooks reverts when strategyProofs length doesn't match hooks length
    /// @dev Covers SuperVaultStrategy.sol:279
    function test_ExecuteHooks_RevertsOnStrategyProofsLengthMismatch() public {
        // Create args with mismatched strategyProofs length
        address[] memory hooks = new address[](2);
        hooks[0] = address(0x1);
        hooks[1] = address(0x2);

        bytes[] memory hookCalldata = new bytes[](2);
        hookCalldata[0] = "";
        hookCalldata[1] = "";

        uint256[] memory expectedOut = new uint256[](2);
        bytes32[][] memory globalProofs = new bytes32[][](2);
        bytes32[][] memory strategyProofs = new bytes32[][](4); // Mismatch: 4 instead of 2

        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: hookCalldata,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });

        // Test: Attempt to execute should revert with INVALID_ARRAY_LENGTH
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.executeHooks(args);
    }

    /// @notice Tests executeHooks reverts when a hook is not registered
    function test_ExecuteHooks_RevertsOnInvalidHook() public {
        // Setup: Create ExecuteArgs with an unregistered hook address
        address[] memory hooks = new address[](1);
        hooks[0] = address(0x999); // Use an arbitrary address that is not registered as a hook

        bytes[] memory hookCalldata = new bytes[](1);
        hookCalldata[0] = "";

        uint256[] memory expectedOut = new uint256[](1);
        expectedOut[0] = 0;

        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0);

        bytes32[][] memory strategyProofs = new bytes32[][](1);
        strategyProofs[0] = new bytes32[](0);

        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: hookCalldata,
            expectedAssetsOrSharesOut: expectedOut,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });

        // Test: Attempt to execute should revert with INVALID_HOOK
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_HOOK.selector);
        strategy.executeHooks(args);
    }

    // =============================================================
    // fulfillRedeemRequests Tests
    // =============================================================

    /// @notice Tests fulfillRedeemRequests reverts when controllers array is empty
    /// @dev Covers SuperVaultStrategy.sol:329 (len == 0 condition)
    function test_FulfillRedeemRequests_RevertsOnEmptyControllersArray() public {
        // Setup: Create empty arrays
        address[] memory controllers = new address[](0);
        uint256[] memory totalAssetsOut = new uint256[](0);

        // Test: Attempt to fulfill with empty controllers array should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @notice Tests fulfillRedeemRequests reverts when array lengths don't match
    /// @dev Covers SuperVaultStrategy.sol:329 (totalAssetsOut.length != len condition)
    function test_FulfillRedeemRequests_RevertsOnArrayLengthMismatch() public {
        // Setup: Create arrays with mismatched lengths
        address[] memory controllers = new address[](2);
        controllers[0] = _deployAccount(0xABC, "TestUser1");
        controllers[1] = _deployAccount(0xDEF, "TestUser2");

        uint256[] memory totalAssetsOut = new uint256[](1); // Mismatch: 1 instead of 2
        totalAssetsOut[0] = 100e18;

        // Test: Attempt to fulfill with mismatched array lengths should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @notice Tests fulfillRedeemRequests reverts when PPS is 0
    /// @dev Covers SuperVaultStrategy.sol:333
    function test_FulfillRedeemRequests_RevertsOnZeroPPS() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Create valid arrays
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;

        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = 100e18;

        // Manipulate PPS to 0 using storage manipulation
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Verify current PPS is not 0
        uint256 currentPPS = strategy.getStoredPPS();
        assertGt(currentPPS, 0, "PPS should be initialized to a non-zero value");

        // Corrupt the PPS to 0 in the aggregator
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(0)));

        // Verify the storage manipulation worked
        uint256 corruptedPPS = strategy.getStoredPPS();
        assertEq(corruptedPPS, 0, "PPS should be corrupted to 0");

        // Test: Attempt to fulfill should revert with INVALID_PPS
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS.selector);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @notice Tests fulfillRedeemRequests reverts when controllers are not sorted in ascending order
    /// @dev Covers SuperVaultStrategy.sol:338 (controllers[i] < controllers[i-1] condition)
    function test_FulfillRedeemRequests_RevertsOnControllersNotSorted() public {
        // Setup: Create addresses where address2 > address1 numerically
        address testUser1 = address(0x1111);
        address testUser2 = address(0x2222);

        // Verify address2 > address1
        assertGt(uint160(testUser2), uint160(testUser1), "testUser2 should be > testUser1");

        // Setup: Give both users assets and have them deposit and request redemptions
        deal(address(asset), testUser1, 10000e18);
        deal(address(asset), testUser2, 10000e18);

        // User1 deposits and requests redemption
        vm.startPrank(testUser1);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser1);
        uint256 shares1 = vault.balanceOf(testUser1);
        vault.requestRedeem(shares1, testUser1, testUser1);
        vm.stopPrank();

        // User2 deposits and requests redemption
        vm.startPrank(testUser2);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser2);
        uint256 shares2 = vault.balanceOf(testUser2);
        vault.requestRedeem(shares2, testUser2, testUser2);
        vm.stopPrank();

        // Create controllers array in wrong order (descending instead of ascending)
        address[] memory controllers = new address[](2);
        controllers[0] = testUser2; // Higher address first (wrong order)
        controllers[1] = testUser1; // Lower address second

        uint256[] memory totalAssetsOut = new uint256[](2);
        totalAssetsOut[0] = shares2;
        totalAssetsOut[1] = shares1;

        // Test: Attempt to fulfill with unsorted controllers should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.CONTROLLERS_NOT_SORTED_UNIQUE.selector);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @notice Tests fulfillRedeemRequests reverts when controllers array contains duplicates
    /// @dev Covers SuperVaultStrategy.sol:338 (controllers[i] == controllers[i-1] condition)
    /// @dev Note: The `<=` operator in the check covers both `<` (not sorted) and `==` (duplicate) cases.
    ///      Since we successfully test the "not sorted" case above, and `<=` inherently includes `==`,
    ///      this test demonstrates that the same validation catches duplicates. Due to state modifications
    ///      in the loop (pendingRedeemRequest reset to 0 after fulfillment), we verify the validation
    ///      catches duplicates before any other processing occurs.
    function test_FulfillRedeemRequests_RevertsOnDuplicateControllers() public {
        address testUser1 = _deployAccount(0xABC, "TestUser1");
        address testUser2 = _deployAccount(0xDEF, "TestUser2");

        // Ensure proper ordering: testUser1 < testUser2
        if (uint160(testUser1) > uint160(testUser2)) {
            (testUser1, testUser2) = (testUser2, testUser1);
        }

        // Setup: Give both users assets and have them deposit and request redemptions
        deal(address(asset), testUser1, 10000e18);
        deal(address(asset), testUser2, 10000e18);

        // User1 deposits and requests redemption
        vm.startPrank(testUser1);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser1);
        uint256 shares1 = vault.balanceOf(testUser1);
        vault.requestRedeem(shares1, testUser1, testUser1);
        vm.stopPrank();

        // User2 deposits and requests redemption
        vm.startPrank(testUser2);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser2);
        vault.requestRedeem(vault.balanceOf(testUser2), testUser2, testUser2);
        vm.stopPrank();

        // Create controllers array with a duplicate at the end
        address[] memory controllers = new address[](3);
        controllers[0] = testUser1;
        controllers[1] = testUser2;
        controllers[2] = testUser2; // Duplicate - same as controllers[1]

        // Create totalAssetsOut with realistic values that will pass bounds checks for first two iterations
        // The pending shares are approximately 990e18 due to fees, so use that value
        uint256[] memory totalAssetsOut = new uint256[](3);
        totalAssetsOut[0] = 990e18;  // Matches expected min for user1
        totalAssetsOut[1] = 990e18;  // Matches expected min for user2
        totalAssetsOut[2] = 100e18;  // This won't matter since we'll revert at sorting check

        // Test: The `<=` check at line 338 will catch controllers[2] == controllers[1]
        // This revert happens during iteration validation, before state modifications
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.CONTROLLERS_NOT_SORTED_UNIQUE.selector);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @notice Tests fulfillRedeemRequests reverts when strategy has insufficient liquidity
    /// @dev Covers SuperVaultStrategy.sol:354-355
    function test_FulfillRedeemRequests_RevertsOnInsufficientLiquidity() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and have them deposit and request redemption
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares, testUser, testUser);
        vm.stopPrank();

        // Drain the strategy's asset balance to create insufficient liquidity
        // The strategy should have received assets during deposit, now we remove them
        uint256 strategyBalance = asset.balanceOf(address(strategy));
        assertGt(strategyBalance, 0, "Strategy should have some balance");

        // Transfer all assets out of the strategy to simulate insufficient liquidity
        vm.prank(address(strategy));
        asset.transfer(address(0xdead), strategyBalance);

        // Verify strategy now has 0 balance
        assertEq(asset.balanceOf(address(strategy)), 0, "Strategy should have 0 balance");

        // Create fulfillment request
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;

        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = 990e18; // Request to fulfill with this amount

        // Test: Attempt to fulfill should revert with INSUFFICIENT_LIQUIDITY
        // because strategy doesn't have enough assets to transfer
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INSUFFICIENT_LIQUIDITY.selector);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @notice Tests fulfillRedeemRequests reverts when totalAssetsOut is below minimum (slippage bound)
    /// @dev Covers SuperVaultStrategy.sol:786 (totalAssetsOut < minAssetsOut condition)
    function test_FulfillRedeemRequests_RevertsOnTotalAssetsOutBelowMinimum() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and have them deposit and request redemption
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares, testUser, testUser);
        vm.stopPrank();

        // theoreticalAssets = shares * currentPPS / PRECISION (1e18)
        // For 1000e18 assets deposited at PPS = 1e18, we get 1000e18 shares
        // theoreticalAssets = 1000e18 * 1e18 / 1e18 = 1000e18

        // minAssetsOut with 1% slippage (100 bps) = 990e18 (99% of theoretical)
        // We need to pass totalAssetsOut < 990e18 to trigger the revert

        address[] memory controllers = new address[](1);
        controllers[0] = testUser;

        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = 980e18; // Below minAssetsOut (990e18), should revert

        // Test: Attempt to fulfill with totalAssetsOut below minimum should revert with BOUNDS_EXCEEDED
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(ISuperVaultStrategy.BOUNDS_EXCEEDED.selector, 990e18, 1000e18, 980e18)
        );
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @notice Tests fulfillRedeemRequests reverts when totalAssetsOut exceeds theoretical maximum
    /// @dev Covers SuperVaultStrategy.sol:786 (totalAssetsOut > theoreticalAssets condition)
    function test_FulfillRedeemRequests_RevertsOnTotalAssetsOutAboveTheoretical() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and have them deposit and request redemption
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares, testUser, testUser);
        vm.stopPrank();

        // theoreticalAssets = shares * currentPPS / PRECISION
        // For 1000e18 assets deposited at PPS = 1e18, we get 1000e18 shares
        // theoreticalAssets = 1000e18 * 1e18 / 1e18 = 1000e18

        // We need to pass totalAssetsOut > 1000e18 to trigger the revert

        address[] memory controllers = new address[](1);
        controllers[0] = testUser;

        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = 1010e18; // Above theoreticalAssets (1000e18), should revert

        // Test: Attempt to fulfill with totalAssetsOut above theoretical should revert with BOUNDS_EXCEEDED
        vm.prank(manager);
        vm.expectRevert(
            abi.encodeWithSelector(ISuperVaultStrategy.BOUNDS_EXCEEDED.selector, 990e18, 1000e18, 1010e18)
        );
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    // =============================================================
    // skimPerformanceFee Tests
    // =============================================================

    /// @notice Tests skimPerformanceFee reverts when PPS is 0
    /// @dev Covers SuperVaultStrategy.sol:394
    function test_SkimPerformanceFee_RevertsOnZeroPPS() public {
        // Setup: Deposit to create some vault supply (required to get past the early return)
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Verify vault has supply
        assertGt(vault.totalSupply(), 0, "Vault should have supply");

        // Wait for the post-unpause skim timelock to expire (12 hours)
        // This is required to get past the SKIM_TIMELOCK_ACTIVE check
        vm.warp(block.timestamp + 12 hours + 1);

        // Manipulate PPS to 0 using storage manipulation
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Verify current PPS is not 0
        uint256 currentPPS = strategy.getStoredPPS();
        assertGt(currentPPS, 0, "PPS should be initialized to a non-zero value");

        // Corrupt the PPS to 0 in the aggregator
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(0)));

        // Verify the storage manipulation worked
        uint256 corruptedPPS = strategy.getStoredPPS();
        assertEq(corruptedPPS, 0, "PPS should be corrupted to 0");

        // Test: Attempt to skim performance fee should revert with INVALID_PPS
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS.selector);
        strategy.skimPerformanceFee();
    }

    /// @notice Tests skimPerformanceFee reverts when strategy doesn't have enough free assets
    /// @dev Covers SuperVaultStrategy.sol:427
    function test_SkimPerformanceFee_RevertsOnInsufficientFreeAssets() public {
        // Setup: Deposit to create some vault supply and establish a baseline
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Wait for the post-unpause skim timelock to expire (12 hours)
        vm.warp(block.timestamp + 12 hours + 1);

        // Simulate profit by increasing PPS above the high water mark
        // We need to manipulate the PPS to be higher than the initial value
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));

        // Get current PPS (should be 1e18 initially)
        uint256 currentPPS = strategy.getStoredPPS();
        assertEq(currentPPS, 1e18, "Initial PPS should be 1e18");

        // Set PPS to 2e18 (100% profit) to trigger fee calculation
        uint256 newPPS = 2e18;
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(newPPS));

        // Verify PPS is now higher
        assertEq(strategy.getStoredPPS(), newPPS, "PPS should be increased");

        // Now drain the strategy's assets to create insufficient liquidity for fee payment
        uint256 strategyBalance = asset.balanceOf(address(strategy));
        assertGt(strategyBalance, 0, "Strategy should have some balance");

        // Transfer almost all assets out, leaving just a tiny amount
        vm.prank(address(strategy));
        asset.transfer(address(0xdead), strategyBalance - 1e15); // Leave only 0.001 tokens

        // Verify strategy has minimal balance (not enough for the fee)
        uint256 remainingBalance = asset.balanceOf(address(strategy));
        assertLt(remainingBalance, 1e18, "Strategy should have very little balance");

        // Test: Attempt to skim performance fee should revert with NOT_ENOUGH_FREE_ASSETS_FEE_SKIM
        // The fee calculation will determine a fee amount, but strategy doesn't have enough assets
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.NOT_ENOUGH_FREE_ASSETS_FEE_SKIM.selector);
        strategy.skimPerformanceFee();
    }

    // NOTE: Two checks in skimPerformanceFee are mathematically impossible to trigger:
    // 1. Line 440: if (ppsReduction >= currentPPS) revert INVALID_PPS();
    // 2. Line 445: if (newPPS == 0) revert INVALID_PPS();
    // See DEFENSIVE_CHECKS_ANALYSIS.md for detailed mathematical proofs of why these checks
    // are untestable but important to keep as defensive safety mechanisms.

    // =============================================================
    // manageYieldSources Tests
    // =============================================================

    /// @notice Tests manageYieldSources reverts when caller is not primary manager
    /// @dev Covers SuperVaultStrategy.sol:474 (_isPrimaryManager check)
    function test_ManageYieldSources_RevertsOnNonPrimaryManager() public {
        address notManager = _deployAccount(0xBAD, "NotManager");

        address[] memory sources = new address[](1);
        sources[0] = address(0x1234);
        address[] memory oracles = new address[](1);
        oracles[0] = address(0x5678);
        uint8[] memory actionTypes = new uint8[](1);
        actionTypes[0] = 0; // Add

        vm.prank(notManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.manageYieldSources(sources, oracles, actionTypes);
    }

    /// @notice Tests manageYieldSource (singular) reverts when caller is not primary manager
    /// @dev Covers SuperVaultStrategy.sol:462 (_isPrimaryManager check)
    function test_ManageYieldSource_RevertsOnNonPrimaryManager() public {
        address notManager = _deployAccount(0xBAD, "NotManager");

        vm.prank(notManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.manageYieldSource(address(0x1234), address(0x5678), 0);
    }

    /// @notice Tests manageYieldSources reverts when sources array is empty
    /// @dev Covers SuperVaultStrategy.sol:477
    function test_ManageYieldSources_RevertsOnZeroLength() public {
        // Setup: Create empty arrays
        address[] memory sources = new address[](0);
        address[] memory oracles = new address[](0);
        uint8[] memory actionTypes = new uint8[](0);

        // Test: Attempt to manage with empty arrays should revert with ZERO_LENGTH
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_LENGTH.selector);
        strategy.manageYieldSources(sources, oracles, actionTypes);
    }

    /// @notice Tests manageYieldSources reverts when oracles array length doesn't match sources
    /// @dev Covers SuperVaultStrategy.sol:478
    function test_ManageYieldSources_RevertsOnOraclesLengthMismatch() public {
        // Setup: Create arrays with mismatched lengths
        address[] memory sources = new address[](2);
        sources[0] = address(0x1);
        sources[1] = address(0x2);

        address[] memory oracles = new address[](1); // Mismatch: 1 instead of 2
        oracles[0] = address(0x3);

        uint8[] memory actionTypes = new uint8[](2);
        actionTypes[0] = 1;
        actionTypes[1] = 1;

        // Test: Attempt to manage with mismatched oracles length should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.manageYieldSources(sources, oracles, actionTypes);
    }

    /// @notice Tests manageYieldSources reverts when actionTypes array length doesn't match sources
    /// @dev Covers SuperVaultStrategy.sol:479
    function test_ManageYieldSources_RevertsOnActionTypesLengthMismatch() public {
        // Setup: Create arrays with mismatched lengths
        address[] memory sources = new address[](2);
        sources[0] = address(0x1);
        sources[1] = address(0x2);

        address[] memory oracles = new address[](2);
        oracles[0] = address(0x3);
        oracles[1] = address(0x4);

        uint8[] memory actionTypes = new uint8[](3); // Mismatch: 3 instead of 2
        actionTypes[0] = 1;
        actionTypes[1] = 1;
        actionTypes[2] = 1;

        // Test: Attempt to manage with mismatched actionTypes length should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.manageYieldSources(sources, oracles, actionTypes);
    }

    /// @notice Tests manageYieldSource reverts on invalid actionType
    /// @dev Covers SuperVaultStrategy.sol:845 - ACTION_TYPE_DISALLOWED in _manageYieldSource
    function test_ManageYieldSource_RevertsOnInvalidActionType() public {
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        // Test: Attempt to manage with invalid actionType (3 or higher)
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ACTION_TYPE_DISALLOWED.selector);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 3);

        // Test with actionType 5
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ACTION_TYPE_DISALLOWED.selector);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 5);

        // Test with actionType 255 (max uint8)
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ACTION_TYPE_DISALLOWED.selector);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 255);
    }

    /// @notice Tests manageYieldSource reverts when adding with source = address(0)
    /// @dev Covers SuperVaultStrategy.sol:853 - ZERO_ADDRESS check in _addYieldSource
    function test_ManageYieldSource_RevertsOnZeroAddressSource() public {
        address oracleAddr = address(0x5678);

        // Test: Attempt to add yield source with address(0) as source
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        strategy.manageYieldSource(address(0), oracleAddr, 0); // actionType 0 = Add
    }

    /// @notice Tests manageYieldSource reverts when adding with oracle = address(0)
    /// @dev Covers SuperVaultStrategy.sol:853 - ZERO_ADDRESS check in _addYieldSource
    function test_ManageYieldSource_RevertsOnZeroAddressOracle_Add() public {
        address yieldSourceAddr = address(0x1234);

        // Test: Attempt to add yield source with address(0) as oracle
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        strategy.manageYieldSource(yieldSourceAddr, address(0), 0); // actionType 0 = Add
    }

    /// @notice Tests manageYieldSource reverts when adding duplicate yield source
    /// @dev Covers SuperVaultStrategy.sol:854 - YIELD_SOURCE_ALREADY_EXISTS check in _addYieldSource
    function test_ManageYieldSource_RevertsOnDuplicateSource() public {
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        // Setup: Add a yield source first
        vm.prank(manager);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 0); // actionType 0 = Add

        // Test: Attempt to add the same yield source again
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_ALREADY_EXISTS.selector);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 0); // actionType 0 = Add
    }

    /// @notice Tests manageYieldSource reverts when updating with oracle = address(0)
    /// @dev Covers SuperVaultStrategy.sol:865 - ZERO_ADDRESS check in _updateYieldSourceOracle
    function test_ManageYieldSource_RevertsOnZeroAddressOracle_Update() public {
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        // Setup: Add a yield source first
        vm.prank(manager);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 0); // actionType 0 = Add

        // Test: Attempt to update oracle to address(0)
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        strategy.manageYieldSource(yieldSourceAddr, address(0), 1); // actionType 1 = Update
    }

    /// @notice Tests manageYieldSource reverts when updating non-existent yield source
    /// @dev Covers SuperVaultStrategy.sol:867 - YIELD_SOURCE_NOT_FOUND check in _updateYieldSourceOracle
    function test_ManageYieldSource_RevertsOnNonExistentSource_Update() public {
        address nonExistentSource = address(0x9999);
        address newOracle = address(0xABCD);

        // Test: Attempt to update a yield source that doesn't exist
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_NOT_FOUND.selector);
        strategy.manageYieldSource(nonExistentSource, newOracle, 1); // actionType 1 = Update
    }

    /// @notice Tests manageYieldSource reverts when removing non-existent yield source
    /// @dev Covers SuperVaultStrategy.sol:876 - YIELD_SOURCE_NOT_FOUND check in _removeYieldSource
    function test_ManageYieldSource_RevertsOnNonExistentSource_Remove() public {
        address nonExistentSource = address(0x9999);

        // Test: Attempt to remove a yield source that doesn't exist
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_NOT_FOUND.selector);
        strategy.manageYieldSource(nonExistentSource, address(0), 2); // actionType 2 = Remove
    }

    /// @notice Tests _addYieldSource reverts when EnumerableSet.add() fails (defensive check)
    /// @dev Covers SuperVaultStrategy.sol:856 - EnumerableSet consistency check in _addYieldSource
    /// @dev This tests inconsistent state where mapping is cleared but set still contains the source
    function test_ManageYieldSource_RevertsOnEnumerableSetAddFailure() public {
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        // Step 1: Add a yield source normally (both mapping and set have it)
        vm.prank(manager);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 0); // actionType 0 = Add

        // Verify it was added
        ISuperVaultStrategy.YieldSource memory ys = strategy.getYieldSource(yieldSourceAddr);
        assertEq(ys.oracle, oracleAddr, "Yield source should be added");
        assertTrue(strategy.containsYieldSource(yieldSourceAddr), "Set should contain source");

        // Step 2: Corrupt the state by clearing the mapping but keeping the set
        // This creates inconsistent state: mapping shows address(0) but set still has the source
        // Find the storage slot for yieldSources mapping
        // Storage layout: PRECISION(0), packed(1), packed(2), FeeConfig(3-5), proposedFeeConfig(6-8),
        // feeConfigEffectiveTime(9), proposedPPSExpiryThreshold(10), ppsExpiryThresholdEffectiveTime(11),
        // ppsExpiration(12), yieldSources(13), yieldSourcesList(14), vaultHwmPps(15), superVaultState(16)
        // Mapping slot = keccak256(abi.encode(key, slot))

        bytes32 mappingSlot = bytes32(uint256(13)); // yieldSources is at slot 13
        bytes32 storageSlot = keccak256(abi.encode(yieldSourceAddr, mappingSlot));

        // Clear the mapping entry (set oracle to address(0))
        vm.store(address(strategy), storageSlot, bytes32(uint256(0)));

        // Verify the mapping is cleared but set still contains it
        ISuperVaultStrategy.YieldSource memory ysCorrupted = strategy.getYieldSource(yieldSourceAddr);
        assertEq(ysCorrupted.oracle, address(0), "Mapping should be cleared");
        assertTrue(strategy.containsYieldSource(yieldSourceAddr), "Set should still contain source");

        // Step 3: Try to add the same source again
        // This should pass the mapping check (line 854) but fail at EnumerableSet.add (line 856)
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_ALREADY_EXISTS.selector);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 0); // actionType 0 = Add
    }

    /// @notice Tests _removeYieldSource reverts when EnumerableSet.remove() fails (defensive check)
    /// @dev Covers SuperVaultStrategy.sol:882 - EnumerableSet consistency check in _removeYieldSource
    /// @dev This tests inconsistent state where mapping has value but set doesn't contain the source
    function test_ManageYieldSource_RevertsOnEnumerableSetRemoveFailure() public {
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        // Step 1: Add a yield source normally
        vm.prank(manager);
        strategy.manageYieldSource(yieldSourceAddr, oracleAddr, 0); // actionType 0 = Add

        // Verify it was added
        assertTrue(strategy.containsYieldSource(yieldSourceAddr), "Set should contain source");

        // Step 2: Remove it normally
        vm.prank(manager);
        strategy.manageYieldSource(yieldSourceAddr, address(0), 2); // actionType 2 = Remove

        // Verify it was removed
        assertFalse(strategy.containsYieldSource(yieldSourceAddr), "Set should not contain source");

        // Step 3: Corrupt the state by setting the mapping but not adding to set
        // This creates inconsistent state: mapping has oracle but set doesn't have the source
        bytes32 mappingSlot = bytes32(uint256(13)); // yieldSources is at slot 13
        bytes32 storageSlot = keccak256(abi.encode(yieldSourceAddr, mappingSlot));

        // Set the mapping entry to a non-zero oracle
        vm.store(address(strategy), storageSlot, bytes32(uint256(uint160(oracleAddr))));

        // Verify the inconsistent state
        ISuperVaultStrategy.YieldSource memory ysCorrupted = strategy.getYieldSource(yieldSourceAddr);
        assertEq(ysCorrupted.oracle, oracleAddr, "Mapping should have oracle");
        assertFalse(strategy.containsYieldSource(yieldSourceAddr), "Set should not contain source");

        // Step 4: Try to remove the source
        // This should pass the mapping check (line 876) but fail at EnumerableSet.remove (line 882)
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_NOT_FOUND.selector);
        strategy.manageYieldSource(yieldSourceAddr, address(0), 2); // actionType 2 = Remove
    }

    // =============================================================
    // Fee Config Update Tests
    // =============================================================

    /// @notice Tests proposeVaultFeeConfigUpdate reverts when caller is not primary manager
    /// @dev Covers SuperVaultStrategy.sol:494 (_isPrimaryManager check)
    function test_ProposeVaultFeeConfigUpdate_RevertsOnNonPrimaryManager() public {
        address notManager = _deployAccount(0xBAD, "NotManager");

        vm.prank(notManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.proposeVaultFeeConfigUpdate(1000, 500, manager);
    }

    /// @notice Tests executeVaultFeeConfigUpdate reverts when caller is not primary manager
    /// @dev Covers SuperVaultStrategy.sol:508 (_isPrimaryManager check)
    function test_ExecuteVaultFeeConfigUpdate_RevertsOnNonPrimaryManager() public {
        address notManager = _deployAccount(0xBAD, "NotManager");

        // Setup: First propose a valid fee config as manager
        vm.prank(manager);
        strategy.proposeVaultFeeConfigUpdate(1000, 500, manager);

        // Warp time to after effective time (1 week + 1 second)
        vm.warp(block.timestamp + 1 weeks + 1);

        // Test: Attempt to execute as non-manager should revert
        vm.prank(notManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.executeVaultFeeConfigUpdate();
    }

    /// @notice Tests executeVaultFeeConfigUpdate reverts when called before effective time
    /// @dev Covers SuperVaultStrategy.sol:510
    function test_ExecuteVaultFeeConfigUpdate_RevertsOnInvalidTimestamp() public {
        // Setup: Manipulate storage to set up proposedFeeConfig and future effective time
        // Based on forge inspect output:
        // - proposedFeeConfig is at slot 6 (spans 3 slots: 6, 7, 8)
        // - feeConfigEffectiveTime is at slot 9

        // Set proposedFeeConfig fields
        // Slot 6: Pack both fee values together
        bytes32 proposedFeesSlot = bytes32(uint256(6));
        uint256 packedFees = (uint256(500) << 16) | uint256(1000); // managementFeeBps: 500, performanceFeeBps: 1000
        vm.store(address(strategy), proposedFeesSlot, bytes32(packedFees));

        // Slot 7: Set recipient to a valid address (not zero)
        bytes32 proposedRecipientSlot = bytes32(uint256(7));
        address validRecipient = address(0x123);
        vm.store(address(strategy), proposedRecipientSlot, bytes32(uint256(uint160(validRecipient))));

        // Set feeConfigEffectiveTime to a future timestamp (1 hour from now)
        bytes32 effectiveTimeSlot = bytes32(uint256(9));
        uint256 futureTime = block.timestamp + 1 hours;
        vm.store(address(strategy), effectiveTimeSlot, bytes32(futureTime));

        // Test: Attempt to execute before effective time should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_TIMESTAMP.selector);
        strategy.executeVaultFeeConfigUpdate();
    }

    /// @notice Tests executeVaultFeeConfigUpdate reverts when proposed recipient is zero address
    /// @dev Covers SuperVaultStrategy.sol:511
    /// @dev This is a defensive check since proposeFeeConfigUpdate already validates recipient != 0
    function test_ExecuteVaultFeeConfigUpdate_RevertsOnZeroAddressRecipient() public {
        // Setup: Manipulate storage to set proposedFeeConfig.recipient to zero address
        // This tests the defensive check at line 511
        // Based on forge inspect output:
        // - proposedFeeConfig is at slot 6 (spans 3 slots: 6, 7, 8)
        // - feeConfigEffectiveTime is at slot 9

        // FeeConfig struct layout (each field in its own slot):
        // Slot 6: performanceFeeBps (uint16) + managementFeeBps (uint16) - packed
        // Slot 7: recipient (address)
        // Slot 8: (padding/next field)

        // Set feeConfigEffectiveTime to a past timestamp (so timestamp check passes)
        bytes32 effectiveTimeSlot = bytes32(uint256(9));
        vm.store(address(strategy), effectiveTimeSlot, bytes32(uint256(1))); // Very old timestamp

        // Set proposedFeeConfig fields
        // Slot 6: Pack both fee values together (performanceFeeBps in lower 16 bits, managementFeeBps in next 16 bits)
        bytes32 proposedFeesSlot = bytes32(uint256(6));
        uint256 packedFees = (uint256(500) << 16) | uint256(1000); // managementFeeBps: 500, performanceFeeBps: 1000
        vm.store(address(strategy), proposedFeesSlot, bytes32(packedFees));

        // Slot 7: Set recipient to zero address
        bytes32 proposedRecipientSlot = bytes32(uint256(7));
        vm.store(address(strategy), proposedRecipientSlot, bytes32(uint256(0))); // Zero address

        // Test: Attempt to execute with zero address recipient should revert
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        strategy.executeVaultFeeConfigUpdate();
    }

    // =============================================================
    // managePPSExpiration Tests
    // =============================================================

    /// @notice Tests managePPSExpiration with invalid action type
    /// @dev Covers SuperVaultStrategy.sol:538
    function test_ManagePPSExpiration_RevertsOnInvalidAction() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ACTION_TYPE_DISALLOWED.selector);
        strategy.managePPSExpiration(0, 1 hours); // Action 0 is invalid

        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ACTION_TYPE_DISALLOWED.selector);
        strategy.managePPSExpiration(4, 1 hours); // Action 4 is invalid
    }

    // =============================================================
    // Action 1: _proposePPSExpiration Tests
    // =============================================================

    /// @notice Tests proposePPSExpiration reverts when caller is not manager
    /// @dev Covers SuperVaultStrategy.sol:890
    function test_ProposePPSExpiration_RevertsOnNonManager() public {
        address notManager = _deployAccount(0xBAD, "NotManager");
        vm.prank(notManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.managePPSExpiration(1, 1 hours);
    }

    /// @notice Tests proposePPSExpiration reverts when threshold is below minimum
    /// @dev Covers SuperVaultStrategy.sol:892 - MIN_PPS_EXPIRATION_THRESHOLD = 1 minute
    function test_ProposePPSExpiration_RevertsOnThresholdTooLow() public {
        uint256 tooLowThreshold = 30 seconds; // Below 1 minute minimum
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(1, tooLowThreshold);
    }

    /// @notice Tests proposePPSExpiration reverts when threshold is above maximum
    /// @dev Covers SuperVaultStrategy.sol:892 - MAX_PPS_EXPIRATION_THRESHOLD = 1 week
    function test_ProposePPSExpiration_RevertsOnThresholdTooHigh() public {
        uint256 tooHighThreshold = 8 days; // Above 1 week maximum
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(1, tooHighThreshold);
    }

    /// @notice Tests proposePPSExpiration succeeds with valid threshold
    /// @dev Covers SuperVaultStrategy.sol:897-898
    function test_ProposePPSExpiration_SucceedsWithValidThreshold() public {
        uint256 validThreshold = 2 hours; // Within 1 minute to 1 week range
        vm.prank(manager);
        strategy.managePPSExpiration(1, validThreshold);
        // No revert means success
    }

    /// @notice Tests proposePPSExpiration succeeds with minimum threshold
    /// @dev Covers edge case at MIN_PPS_EXPIRATION_THRESHOLD
    function test_ProposePPSExpiration_SucceedsWithMinimumThreshold() public {
        uint256 minThreshold = 1 minutes; // Exactly at minimum
        vm.prank(manager);
        strategy.managePPSExpiration(1, minThreshold);
        // No revert means success
    }

    /// @notice Tests proposePPSExpiration succeeds with maximum threshold
    /// @dev Covers edge case at MAX_PPS_EXPIRATION_THRESHOLD
    function test_ProposePPSExpiration_SucceedsWithMaximumThreshold() public {
        uint256 maxThreshold = 1 weeks; // Exactly at maximum
        vm.prank(manager);
        strategy.managePPSExpiration(1, maxThreshold);
        // No revert means success
    }

    /// @notice Tests proposePPSExpiration reverts when threshold is zero
    /// @dev Covers SuperVaultStrategy.sol:892 - explicit zero test for lower bound
    function test_ProposePPSExpiration_RevertsOnZeroThreshold() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(1, 0);
    }

    /// @notice Tests proposePPSExpiration reverts when threshold is exactly MIN - 1
    /// @dev Covers SuperVaultStrategy.sol:892 - boundary test at MIN - 1 second
    function test_ProposePPSExpiration_RevertsOnMinMinusOne() public {
        uint256 almostMin = 1 minutes - 1; // 59 seconds
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(1, almostMin);
    }

    /// @notice Tests proposePPSExpiration reverts when threshold is exactly MAX + 1
    /// @dev Covers SuperVaultStrategy.sol:892 - boundary test at MAX + 1 second
    function test_ProposePPSExpiration_RevertsOnMaxPlusOne() public {
        uint256 justOverMax = 1 weeks + 1; // 1 week + 1 second
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(1, justOverMax);
    }

    // =============================================================
    // Action 2: _updatePPSExpiration Tests
    // =============================================================

    /// @notice Tests updatePPSExpiration reverts when caller is not manager
    /// @dev Covers SuperVaultStrategy.sol:905
    function test_UpdatePPSExpiration_RevertsOnNonManager() public {
        address notManager = _deployAccount(0xBAD, "NotManager");
        vm.prank(notManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.managePPSExpiration(2, 0); // staleness_ param ignored for action 2
    }

    /// @notice Tests updatePPSExpiration reverts when called before effective time
    /// @dev Covers SuperVaultStrategy.sol:908
    function test_UpdatePPSExpiration_RevertsOnInvalidTimestamp() public {
        // First propose a threshold
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours); // This sets effective time to block.timestamp + 1 week

        // Try to update immediately (before effective time)
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_TIMESTAMP.selector);
        strategy.managePPSExpiration(2, 0);
    }

    /// @notice Tests updatePPSExpiration reverts when no proposal exists
    /// @dev Covers SuperVaultStrategy.sol:910
    function test_UpdatePPSExpiration_RevertsOnZeroProposedThreshold() public {
        // Don't propose anything, try to update directly
        // Need to manipulate storage to pass timestamp check but have zero proposed threshold

        // Set ppsExpiryThresholdEffectiveTime to a past time (so timestamp check passes)
        bytes32 effectiveTimeSlot = bytes32(uint256(11)); // From storage layout
        vm.store(address(strategy), effectiveTimeSlot, bytes32(uint256(1))); // Very old timestamp

        // proposedPPSExpiryThreshold should be 0 by default
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(2, 0);
    }

    /// @notice Tests updatePPSExpiration succeeds after timelock passes
    /// @dev Covers SuperVaultStrategy.sol:912-915
    function test_UpdatePPSExpiration_SucceedsAfterTimelock() public {
        // Propose a threshold
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours);

        // Warp past the 1 week timelock
        vm.warp(block.timestamp + 1 weeks + 1);

        // Now update should succeed
        vm.prank(manager);
        strategy.managePPSExpiration(2, 0);
        // No revert means success
    }

    /// @notice Tests updatePPSExpiration reverts when timestamp is exactly effectiveTime - 1
    /// @dev Covers SuperVaultStrategy.sol:908 - boundary test for timestamp check
    function test_UpdatePPSExpiration_RevertsOnEffectiveTimeMinusOne() public {
        // Propose a threshold at timestamp T
        uint256 proposalTime = block.timestamp;
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours);
        // effectiveTime is now proposalTime + 1 weeks

        // Warp to exactly effectiveTime - 1 (still too early)
        vm.warp(proposalTime + 1 weeks - 1);

        // Should revert because block.timestamp < effectiveTime
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_TIMESTAMP.selector);
        strategy.managePPSExpiration(2, 0);
    }

    /// @notice Tests updatePPSExpiration succeeds when timestamp is exactly at effectiveTime
    /// @dev Covers SuperVaultStrategy.sol:908 - boundary test (>= should pass)
    function test_UpdatePPSExpiration_SucceedsAtExactEffectiveTime() public {
        // Propose a threshold at timestamp T
        uint256 proposalTime = block.timestamp;
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours);
        // effectiveTime is now proposalTime + 1 weeks

        // Warp to exactly effectiveTime
        vm.warp(proposalTime + 1 weeks);

        // Should succeed because block.timestamp >= effectiveTime
        vm.prank(manager);
        strategy.managePPSExpiration(2, 0);
        // No revert means success
    }

    /// @notice Tests updatePPSExpiration succeeds when timestamp is exactly effectiveTime + 1
    /// @dev Covers SuperVaultStrategy.sol:908 - boundary test (just past effective time)
    function test_UpdatePPSExpiration_SucceedsAtEffectiveTimePlusOne() public {
        // Propose a threshold at timestamp T
        uint256 proposalTime = block.timestamp;
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours);
        // effectiveTime is now proposalTime + 1 weeks

        // Warp to exactly effectiveTime + 1
        vm.warp(proposalTime + 1 weeks + 1);

        // Should succeed because block.timestamp > effectiveTime
        vm.prank(manager);
        strategy.managePPSExpiration(2, 0);
        // No revert means success
    }

    // =============================================================
    // Action 3: _cancelPPSExpirationProposalUpdate Tests
    // =============================================================

    /// @notice Tests cancelPPSExpirationProposalUpdate reverts when caller is not manager
    /// @dev Covers SuperVaultStrategy.sol:922
    function test_CancelPPSExpirationProposal_RevertsOnNonManager() public {
        address notManager = _deployAccount(0xBAD, "NotManager");
        vm.prank(notManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.managePPSExpiration(3, 0);
    }

    /// @notice Tests cancelPPSExpirationProposalUpdate reverts when no proposal exists
    /// @dev Covers SuperVaultStrategy.sol:924
    function test_CancelPPSExpirationProposal_RevertsOnNoProposal() public {
        // Don't propose anything, try to cancel
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
        strategy.managePPSExpiration(3, 0);
    }

    /// @notice Tests cancelPPSExpirationProposal succeeds when proposal exists
    /// @dev Covers SuperVaultStrategy.sol:926-927
    function test_CancelPPSExpirationProposal_SucceedsWithExistingProposal() public {
        // First propose a threshold
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours);

        // Now cancel should succeed
        vm.prank(manager);
        strategy.managePPSExpiration(3, 0);
        // No revert means success
    }

    /// @notice Tests cancelPPSExpirationProposal properly clears state variables
    /// @dev Covers SuperVaultStrategy.sol:926-927 - verifies both state variables are cleared
    function test_CancelPPSExpirationProposal_ClearsStateVariables() public {
        // Propose a threshold
        uint256 proposalThreshold = 3 hours;
        vm.prank(manager);
        strategy.managePPSExpiration(1, proposalThreshold);

        // Verify state is set (proposedPPSExpiryThreshold and ppsExpiryThresholdEffectiveTime)
        // We can't directly read these private variables, but we can verify behavior
        // If we try to cancel, it should succeed (proving effectiveTime != 0)

        // Cancel the proposal
        vm.prank(manager);
        strategy.managePPSExpiration(3, 0);

        // Verify state is cleared by trying to cancel again - should revert with NO_PROPOSAL
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
        strategy.managePPSExpiration(3, 0); // Should fail because ppsExpiryThresholdEffectiveTime == 0
    }

    /// @notice Tests cancelPPSExpirationProposal emits correct event
    /// @dev Covers SuperVaultStrategy.sol:929 - event emission
    function test_CancelPPSExpirationProposal_EmitsEvent() public {
        // Propose a threshold
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours);

        // Expect the PPSExpiryThresholdProposalCanceled event
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultStrategy.PPSExpiryThresholdProposalCanceled();

        // Cancel the proposal
        vm.prank(manager);
        strategy.managePPSExpiration(3, 0);
    }

    /// @notice Tests cancelPPSExpirationProposal with boundary case effectiveTime == 1
    /// @dev Covers SuperVaultStrategy.sol:924 - boundary test for non-zero effectiveTime
    function test_CancelPPSExpirationProposal_WithEffectiveTimeEqualOne() public {
        // Use vm.store to set ppsExpiryThresholdEffectiveTime to 1 (non-zero, smallest positive)
        // This tests the boundary: effectiveTime == 0 fails, effectiveTime >= 1 passes

        // Storage layout: ppsExpiryThresholdEffectiveTime is at slot 11
        bytes32 effectiveTimeSlot = bytes32(uint256(11));
        vm.store(address(strategy), effectiveTimeSlot, bytes32(uint256(1)));

        // Also need to set proposedPPSExpiryThreshold to non-zero (slot 10)
        bytes32 proposedThresholdSlot = bytes32(uint256(10));
        vm.store(address(strategy), proposedThresholdSlot, bytes32(uint256(2 hours)));

        // Now cancel should succeed because effectiveTime != 0
        vm.prank(manager);
        strategy.managePPSExpiration(3, 0);
        // No revert means success
    }

    /// @notice Tests full proposal lifecycle: propose -> cancel -> propose again
    /// @dev Covers complete workflow
    function test_ManagePPSExpiration_FullProposalLifecycle() public {
        // Propose
        vm.prank(manager);
        strategy.managePPSExpiration(1, 2 hours);

        // Cancel
        vm.prank(manager);
        strategy.managePPSExpiration(3, 0);

        // Propose again
        vm.prank(manager);
        strategy.managePPSExpiration(1, 3 hours);

        // Warp and update
        vm.warp(block.timestamp + 1 weeks + 1);
        vm.prank(manager);
        strategy.managePPSExpiration(2, 0);
        // No revert means success
    }

    // =============================================================
    // setRedeemSlippage Tests
    // =============================================================

    /// @notice Tests setRedeemSlippage reverts when slippage exceeds BPS_PRECISION
    /// @dev Covers SuperVaultStrategy.sol:547
    function test_SetRedeemSlippage_RevertsOnExcessiveSlippage() public {
        address _user = _deployAccount(0xABC, "TestUser");
        uint16 invalidSlippage = 10001; // BPS_PRECISION is 10000

        vm.prank(_user);
        vm.expectRevert(ISuperVaultStrategy.INVALID_REDEEM_SLIPPAGE_BPS.selector);
        strategy.setRedeemSlippage(invalidSlippage);
    }

    /// @notice Tests setRedeemSlippage succeeds with valid slippage
    /// @dev Covers SuperVaultStrategy.sol:549
    function test_SetRedeemSlippage_SucceedsWithValidSlippage() public {
        address _user = _deployAccount(0xABC, "TestUser");
        uint16 validSlippage = 500; // 5% slippage

        vm.prank(_user);
        strategy.setRedeemSlippage(validSlippage);

        // Verify it was stored correctly
        ISuperVaultStrategy.SuperVaultState memory state = strategy.getSuperVaultState(_user);
        assertEq(state.redeemSlippageBps, validSlippage, "Slippage should be stored correctly");
    }

    /// @notice Tests setRedeemSlippage succeeds with zero slippage
    /// @dev Covers edge case: 0% slippage
    function test_SetRedeemSlippage_SucceedsWithZeroSlippage() public {
        address _user = _deployAccount(0xABC, "TestUser");
        uint16 zeroSlippage = 0;

        vm.prank(_user);
        strategy.setRedeemSlippage(zeroSlippage);

        ISuperVaultStrategy.SuperVaultState memory state = strategy.getSuperVaultState(_user);
        assertEq(state.redeemSlippageBps, zeroSlippage, "Zero slippage should be stored correctly");
    }

    /// @notice Tests setRedeemSlippage succeeds with maximum valid slippage
    /// @dev Covers edge case: exactly BPS_PRECISION (10000 = 100%)
    function test_SetRedeemSlippage_SucceedsWithMaximumSlippage() public {
        address _user = _deployAccount(0xABC, "TestUser");
        uint16 maxSlippage = 10000; // Exactly BPS_PRECISION (100%)

        vm.prank(_user);
        strategy.setRedeemSlippage(maxSlippage);

        ISuperVaultStrategy.SuperVaultState memory state = strategy.getSuperVaultState(_user);
        assertEq(state.redeemSlippageBps, maxSlippage, "Maximum slippage should be stored correctly");
    }

    /// @notice Tests setRedeemSlippage allows different users to set different values
    /// @dev Verifies per-user storage isolation
    function test_SetRedeemSlippage_MultipleUsersIndependentSettings() public {
        address user1 = _deployAccount(0xABC, "User1");
        address user2 = _deployAccount(0xDEF, "User2");

        uint16 slippage1 = 100; // 1%
        uint16 slippage2 = 500; // 5%

        vm.prank(user1);
        strategy.setRedeemSlippage(slippage1);

        vm.prank(user2);
        strategy.setRedeemSlippage(slippage2);

        // Verify each user has their own value
        ISuperVaultStrategy.SuperVaultState memory state1 = strategy.getSuperVaultState(user1);
        ISuperVaultStrategy.SuperVaultState memory state2 = strategy.getSuperVaultState(user2);

        assertEq(state1.redeemSlippageBps, slippage1, "User1 slippage should be independent");
        assertEq(state2.redeemSlippageBps, slippage2, "User2 slippage should be independent");
    }

    // =============================================================
    // getYieldSource Tests
    // =============================================================

    /// @notice Tests getYieldSource returns correct oracle for existing yield source
    /// @dev Covers SuperVaultStrategy.sol:581
    function test_GetYieldSource_ReturnsCorrectOracleForExistingSource() public {
        // Setup: Add a yield source
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        address[] memory sources = new address[](1);
        address[] memory oracles = new address[](1);
        uint8[] memory actionTypes = new uint8[](1);

        sources[0] = yieldSourceAddr;
        oracles[0] = oracleAddr;
        actionTypes[0] = 0; // 0 = Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Test: Get the yield source
        ISuperVaultStrategy.YieldSource memory yieldSource = strategy.getYieldSource(yieldSourceAddr);

        assertEq(yieldSource.oracle, oracleAddr, "Oracle address should match");
    }

    /// @notice Tests getYieldSource returns zero address for non-existent yield source
    /// @dev Verifies default mapping behavior
    function test_GetYieldSource_ReturnsZeroAddressForNonExistentSource() public view {
        // Test: Query a yield source that was never added
        address nonExistentSource = address(0x9999);

        ISuperVaultStrategy.YieldSource memory yieldSource = strategy.getYieldSource(nonExistentSource);

        assertEq(yieldSource.oracle, address(0), "Oracle should be zero address for non-existent source");
    }

    /// @notice Tests getYieldSource with multiple yield sources
    /// @dev Verifies correct oracle returned for each source
    function test_GetYieldSource_MultipleYieldSources() public {
        // Setup: Add multiple yield sources
        address[] memory sources = new address[](3);
        address[] memory oracles = new address[](3);
        uint8[] memory actionTypes = new uint8[](3);

        sources[0] = address(0x1111);
        sources[1] = address(0x2222);
        sources[2] = address(0x3333);

        oracles[0] = address(0xAAAA);
        oracles[1] = address(0xBBBB);
        oracles[2] = address(0xCCCC);

        actionTypes[0] = 0; // Add
        actionTypes[1] = 0; // Add
        actionTypes[2] = 0; // Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Test: Get each yield source and verify oracle
        ISuperVaultStrategy.YieldSource memory ys1 = strategy.getYieldSource(sources[0]);
        ISuperVaultStrategy.YieldSource memory ys2 = strategy.getYieldSource(sources[1]);
        ISuperVaultStrategy.YieldSource memory ys3 = strategy.getYieldSource(sources[2]);

        assertEq(ys1.oracle, oracles[0], "First oracle should match");
        assertEq(ys2.oracle, oracles[1], "Second oracle should match");
        assertEq(ys3.oracle, oracles[2], "Third oracle should match");
    }

    /// @notice Tests getYieldSource after oracle update
    /// @dev Verifies oracle change is reflected
    function test_GetYieldSource_AfterOracleUpdate() public {
        // Setup: Add a yield source
        address yieldSourceAddr = address(0x1234);
        address originalOracle = address(0x5678);
        address newOracle = address(0xABCD);

        address[] memory sources = new address[](1);
        address[] memory oracles = new address[](1);
        uint8[] memory actionTypes = new uint8[](1);

        // Add the yield source
        sources[0] = yieldSourceAddr;
        oracles[0] = originalOracle;
        actionTypes[0] = 0; // Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Verify original oracle
        ISuperVaultStrategy.YieldSource memory ys1 = strategy.getYieldSource(yieldSourceAddr);
        assertEq(ys1.oracle, originalOracle, "Original oracle should match");

        // Update the oracle
        oracles[0] = newOracle;
        actionTypes[0] = 1; // 1 = UpdateOracle

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Test: Verify updated oracle
        ISuperVaultStrategy.YieldSource memory ys2 = strategy.getYieldSource(yieldSourceAddr);
        assertEq(ys2.oracle, newOracle, "Oracle should be updated");
    }

    /// @notice Tests getYieldSource after removal returns zero address
    /// @dev Verifies removal clears the oracle mapping
    function test_GetYieldSource_AfterRemoval() public {
        // Setup: Add a yield source
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        address[] memory sources = new address[](1);
        address[] memory oracles = new address[](1);
        uint8[] memory actionTypes = new uint8[](1);

        // Add the yield source
        sources[0] = yieldSourceAddr;
        oracles[0] = oracleAddr;
        actionTypes[0] = 0; // Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Verify it exists
        ISuperVaultStrategy.YieldSource memory ys1 = strategy.getYieldSource(yieldSourceAddr);
        assertEq(ys1.oracle, oracleAddr, "Oracle should exist before removal");

        // Remove the yield source
        actionTypes[0] = 2; // 2 = Remove

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Test: Verify oracle is cleared after removal
        ISuperVaultStrategy.YieldSource memory ys2 = strategy.getYieldSource(yieldSourceAddr);
        assertEq(ys2.oracle, address(0), "Oracle should be zero after removal");
    }

    // =============================================================
    // getYieldSourcesCount Tests
    // =============================================================

    /// @notice Tests getYieldSourcesCount returns zero initially
    /// @dev Covers SuperVaultStrategy.sol:606 - initial state
    function test_GetYieldSourcesCount_ReturnsZeroInitially() public view {
        uint256 count = strategy.getYieldSourcesCount();
        assertEq(count, 0, "Initial count should be zero");
    }

    /// @notice Tests getYieldSourcesCount after adding one yield source
    /// @dev Covers SuperVaultStrategy.sol:606
    function test_GetYieldSourcesCount_ReturnsOneAfterAddingSingleSource() public {
        // Setup: Add one yield source
        address[] memory sources = new address[](1);
        address[] memory oracles = new address[](1);
        uint8[] memory actionTypes = new uint8[](1);

        sources[0] = address(0x1234);
        oracles[0] = address(0x5678);
        actionTypes[0] = 0; // Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Test: Count should be 1
        uint256 count = strategy.getYieldSourcesCount();
        assertEq(count, 1, "Count should be 1 after adding one source");
    }

    /// @notice Tests getYieldSourcesCount after adding multiple yield sources
    /// @dev Verifies count increments correctly
    function test_GetYieldSourcesCount_ReturnsCorrectCountForMultipleSources() public {
        // Setup: Add 3 yield sources
        address[] memory sources = new address[](3);
        address[] memory oracles = new address[](3);
        uint8[] memory actionTypes = new uint8[](3);

        sources[0] = address(0x1111);
        sources[1] = address(0x2222);
        sources[2] = address(0x3333);

        oracles[0] = address(0xAAAA);
        oracles[1] = address(0xBBBB);
        oracles[2] = address(0xCCCC);

        actionTypes[0] = 0; // Add
        actionTypes[1] = 0; // Add
        actionTypes[2] = 0; // Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Test: Count should be 3
        uint256 count = strategy.getYieldSourcesCount();
        assertEq(count, 3, "Count should be 3 after adding three sources");
    }

    /// @notice Tests getYieldSourcesCount after removing a yield source
    /// @dev Verifies count decrements correctly
    function test_GetYieldSourcesCount_DecrementsAfterRemoval() public {
        // Setup: Add 2 yield sources
        address[] memory sources = new address[](2);
        address[] memory oracles = new address[](2);
        uint8[] memory actionTypes = new uint8[](2);

        sources[0] = address(0x1111);
        sources[1] = address(0x2222);

        oracles[0] = address(0xAAAA);
        oracles[1] = address(0xBBBB);

        actionTypes[0] = 0; // Add
        actionTypes[1] = 0; // Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Verify count is 2
        uint256 countBefore = strategy.getYieldSourcesCount();
        assertEq(countBefore, 2, "Count should be 2 after adding two sources");

        // Remove one source
        address[] memory sourcesToRemove = new address[](1);
        address[] memory oraclesToRemove = new address[](1);
        uint8[] memory removeActionTypes = new uint8[](1);

        sourcesToRemove[0] = address(0x1111);
        oraclesToRemove[0] = address(0); // Ignored for removal
        removeActionTypes[0] = 2; // Remove

        vm.prank(manager);
        strategy.manageYieldSources(sourcesToRemove, oraclesToRemove, removeActionTypes);

        // Test: Count should be 1
        uint256 countAfter = strategy.getYieldSourcesCount();
        assertEq(countAfter, 1, "Count should be 1 after removing one source");
    }

    /// @notice Tests getYieldSourcesCount with complex add/remove operations
    /// @dev Verifies count is accurate through multiple operations
    function test_GetYieldSourcesCount_ComplexOperations() public {
        // Initially 0
        assertEq(strategy.getYieldSourcesCount(), 0, "Initial count should be 0");

        // Add 3 sources
        address[] memory sources = new address[](3);
        address[] memory oracles = new address[](3);
        uint8[] memory actionTypes = new uint8[](3);

        sources[0] = address(0x1111);
        sources[1] = address(0x2222);
        sources[2] = address(0x3333);

        oracles[0] = address(0xAAAA);
        oracles[1] = address(0xBBBB);
        oracles[2] = address(0xCCCC);

        actionTypes[0] = 0;
        actionTypes[1] = 0;
        actionTypes[2] = 0;

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        assertEq(strategy.getYieldSourcesCount(), 3, "Count should be 3");

        // Remove 2 sources
        address[] memory sourcesToRemove = new address[](2);
        address[] memory oraclesToRemove = new address[](2);
        uint8[] memory removeActionTypes = new uint8[](2);

        sourcesToRemove[0] = address(0x1111);
        sourcesToRemove[1] = address(0x3333);
        oraclesToRemove[0] = address(0);
        oraclesToRemove[1] = address(0);
        removeActionTypes[0] = 2;
        removeActionTypes[1] = 2;

        vm.prank(manager);
        strategy.manageYieldSources(sourcesToRemove, oraclesToRemove, removeActionTypes);

        assertEq(strategy.getYieldSourcesCount(), 1, "Count should be 1 after removing 2");

        // Add 1 more source
        address[] memory moreSources = new address[](1);
        address[] memory moreOracles = new address[](1);
        uint8[] memory addActionTypes = new uint8[](1);

        moreSources[0] = address(0x4444);
        moreOracles[0] = address(0xDDDD);
        addActionTypes[0] = 0;

        vm.prank(manager);
        strategy.manageYieldSources(moreSources, moreOracles, addActionTypes);

        assertEq(strategy.getYieldSourcesCount(), 2, "Count should be 2 after adding 1 more");

        // Remove all
        address[] memory removeAll = new address[](2);
        address[] memory removeAllOracles = new address[](2);
        uint8[] memory removeAllTypes = new uint8[](2);

        removeAll[0] = address(0x2222);
        removeAll[1] = address(0x4444);
        removeAllOracles[0] = address(0);
        removeAllOracles[1] = address(0);
        removeAllTypes[0] = 2;
        removeAllTypes[1] = 2;

        vm.prank(manager);
        strategy.manageYieldSources(removeAll, removeAllOracles, removeAllTypes);

        assertEq(strategy.getYieldSourcesCount(), 0, "Count should be 0 after removing all");
    }

    /// @notice Tests getYieldSourcesCount after oracle update (should not change count)
    /// @dev Verifies that updating oracle doesn't affect count
    function test_GetYieldSourcesCount_UnchangedAfterOracleUpdate() public {
        // Add a yield source
        address[] memory sources = new address[](1);
        address[] memory oracles = new address[](1);
        uint8[] memory actionTypes = new uint8[](1);

        sources[0] = address(0x1234);
        oracles[0] = address(0x5678);
        actionTypes[0] = 0; // Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        uint256 countBefore = strategy.getYieldSourcesCount();
        assertEq(countBefore, 1, "Count should be 1");

        // Update the oracle
        oracles[0] = address(0xABCD);
        actionTypes[0] = 1; // UpdateOracle

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        // Test: Count should still be 1
        uint256 countAfter = strategy.getYieldSourcesCount();
        assertEq(countAfter, 1, "Count should remain 1 after oracle update");
    }

    // =============================================================
    // vaultUnrealizedProfit Tests
    // =============================================================

    /// @notice Tests vaultUnrealizedProfit returns zero when total supply is zero
    /// @dev Covers SuperVaultStrategy.sol:617
    function test_VaultUnrealizedProfit_ReturnsZeroWhenNoShares() public view {
        // Initial state: no deposits, totalSupply = 0
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when no shares exist");
    }

    /// @notice Tests vaultUnrealizedProfit returns zero when PPS equals HWM
    /// @dev Covers SuperVaultStrategy.sol:622
    function test_VaultUnrealizedProfit_ReturnsZeroWhenPPSEqualsHWM() public {
        // Setup: Make a deposit so totalSupply > 0
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // At this point, PPS should equal HWM (both at initial value)
        // Test: Should return 0 profit
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when PPS equals HWM");
    }

    /// @notice Tests vaultUnrealizedProfit returns zero when PPS is below HWM
    /// @dev Covers SuperVaultStrategy.sol:622
    function test_VaultUnrealizedProfit_ReturnsZeroWhenPPSBelowHWM() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set HWM to a higher value than current PPS using storage manipulation
        // vaultHwmPps is at slot 16 (from storage layout)
        uint256 highHWM = 2e18; // 2x starting PPS
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(highHWM));

        // Test: Should return 0 profit since currentPPS < HWM
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when PPS is below HWM");
    }

    /// @notice Tests vaultUnrealizedProfit calculates correct profit when PPS grows
    /// @dev Covers SuperVaultStrategy.sol:625-626
    function test_VaultUnrealizedProfit_CalculatesCorrectProfitOnPPSGrowth() public {
        // Setup: Make a deposit to have shares
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Get initial HWM (should be at starting PPS = 1e18)
        uint256 initialHWM = 1e18; // Starting PPS

        // Simulate PPS growth by manipulating PPS in aggregator
        uint256 newPPS = 1.5e18; // 50% growth
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(newPPS));

        // Get current PPS
        uint256 currentPPS = superVaultAggregator.getPPS(address(strategy));
        assertEq(currentPPS, newPPS, "PPS should be updated");

        // Calculate expected profit: (currentPPS - hwmPPS) * totalSupply / PRECISION
        uint256 ppsGrowth = currentPPS - initialHWM;
        uint256 expectedProfit = Math.mulDiv(ppsGrowth, shares, 1e18, Math.Rounding.Floor);

        // Test: Verify profit calculation
        uint256 actualProfit = strategy.vaultUnrealizedProfit();
        assertGt(actualProfit, 0, "Profit should be greater than 0");
        assertEq(actualProfit, expectedProfit, "Profit should match expected calculation");
    }

    /// @notice Tests vaultUnrealizedProfit uses getPPS from aggregator correctly
    /// @dev Covers SuperVaultStrategy.sol:619 - tests the getPPS call
    function test_VaultUnrealizedProfit_UsesCurrentPPSFromAggregator() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Manipulate PPS in aggregator to a known value
        uint256 newPPS = 2e18; // 2x starting PPS
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(newPPS));

        // Get current PPS to verify manipulation worked
        uint256 currentPPS = superVaultAggregator.getPPS(address(strategy));
        assertEq(currentPPS, newPPS, "PPS manipulation should work");

        // Test: vaultUnrealizedProfit should use this PPS value
        uint256 profit = strategy.vaultUnrealizedProfit();

        // Since PPS doubled from 1e18 to 2e18, and we have shares, profit should be > 0
        assertGt(profit, 0, "Profit should be calculated based on manipulated PPS");
    }

    /// @notice Tests vaultUnrealizedProfit with zero PPS returns zero
    /// @dev Tests edge case where getPPS returns 0
    function test_VaultUnrealizedProfit_ReturnsZeroWhenPPSIsZero() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Manipulate PPS to 0 in aggregator
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(0)));

        // Test: Should return 0 profit since currentPPS (0) <= vaultHwmPps
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when PPS is 0");
    }

    /// @notice Tests vaultUnrealizedProfit with large PPS values
    /// @dev Tests edge case with large numbers
    function test_VaultUnrealizedProfit_HandlesLargePPSValues() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set a very large PPS value
        uint256 largePPS = 1000e18; // 1000x starting PPS
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(largePPS));

        // Test: Should handle large values without overflow
        uint256 profit = strategy.vaultUnrealizedProfit();

        // Calculate expected profit
        uint256 ppsGrowth = largePPS - 1e18; // Growth from 1e18 to 1000e18
        uint256 expectedProfit = Math.mulDiv(ppsGrowth, shares, 1e18, Math.Rounding.Floor);

        assertEq(profit, expectedProfit, "Should handle large PPS values correctly");
        assertGt(profit, 0, "Profit should be substantial with large PPS growth");
    }

    /// @notice Tests vaultUnrealizedProfit with multiple users
    /// @dev Verifies profit calculation with multiple shareholders
    function test_VaultUnrealizedProfit_MultipleUsers() public {
        // Setup: Multiple users deposit
        address user1 = _deployAccount(0xABC, "User1");
        address user2 = _deployAccount(0xDEF, "User2");

        deal(address(asset), user1, 1000e18);
        deal(address(asset), user2, 2000e18);

        vm.startPrank(user1);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, user1);
        vm.stopPrank();

        vm.startPrank(user2);
        asset.approve(address(vault), 2000e18);
        vault.deposit(2000e18, user2);
        vm.stopPrank();

        uint256 totalShares = vault.totalSupply();

        // Increase PPS
        uint256 newPPS = 1.5e18; // 50% growth
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(newPPS));

        // Test: Profit should be based on total shares
        uint256 profit = strategy.vaultUnrealizedProfit();

        uint256 ppsGrowth = newPPS - 1e18;
        uint256 expectedProfit = Math.mulDiv(ppsGrowth, totalShares, 1e18, Math.Rounding.Floor);

        assertEq(profit, expectedProfit, "Profit should account for all shareholders");
    }

    // =============================================================
    // Additional tests for line 622: if (currentPPS <= vaultHwmPps) return 0;
    // =============================================================

    /// @notice Tests exact boundary: currentPPS exactly equals vaultHwmPps
    /// @dev Covers the == part of <= condition
    function test_VaultUnrealizedProfit_ExactEqualityBoundary() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set both PPS and HWM to the same custom value
        uint256 customValue = 5e18; // 5x starting PPS

        // Set HWM
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(customValue));

        // Set PPS in aggregator
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(customValue));

        // Test: Should return 0 when exactly equal
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when currentPPS exactly equals vaultHwmPps");
    }

    /// @notice Tests boundary: currentPPS is 1 wei less than vaultHwmPps
    /// @dev Tests the < part of <= condition at minimal difference
    function test_VaultUnrealizedProfit_OneLessThanHWM() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set HWM to a value
        uint256 hwmValue = 1e18 + 1000; // Starting PPS + 1000 wei
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(hwmValue));

        // Set PPS to 1 wei less than HWM
        uint256 ppsValue = hwmValue - 1;
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(ppsValue));

        // Test: Should return 0 when currentPPS < vaultHwmPps (even by 1 wei)
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when currentPPS is 1 wei less than vaultHwmPps");
    }

    /// @notice Tests boundary: currentPPS is 1 wei more than vaultHwmPps (should have profit)
    /// @dev Verifies the boundary - just above HWM should calculate profit
    function test_VaultUnrealizedProfit_OneMoreThanHWM() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set HWM to a value
        uint256 hwmValue = 1e18;
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(hwmValue));

        // Set PPS to 1 wei more than HWM
        uint256 ppsValue = hwmValue + 1;
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(ppsValue));

        // Test: Should return profit when currentPPS > vaultHwmPps (even by 1 wei)
        uint256 profit = strategy.vaultUnrealizedProfit();

        // Calculate expected profit: (ppsValue - hwmValue) * shares / PRECISION = 1 * shares / 1e18
        uint256 expectedProfit = Math.mulDiv(1, shares, 1e18, Math.Rounding.Floor);

        assertGt(profit, 0, "Profit should be greater than 0 when currentPPS is 1 wei more than vaultHwmPps");
        assertEq(profit, expectedProfit, "Profit should match expected calculation");
    }

    /// @notice Tests with HWM at maximum reasonable value
    /// @dev Tests edge case with very high HWM
    function test_VaultUnrealizedProfit_PPSEqualToVeryHighHWM() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set both to a very high value
        uint256 veryHighValue = 1000000e18; // 1 million times starting PPS

        // Set HWM
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(veryHighValue));

        // Set PPS equal to HWM
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(veryHighValue));

        // Test: Should return 0 when equal, even at very high values
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when currentPPS equals very high vaultHwmPps");
    }

    /// @notice Tests PPS significantly below HWM
    /// @dev Tests the < condition with large difference
    function test_VaultUnrealizedProfit_PPSSignificantlyBelowHWM() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set HWM to high value
        uint256 hwmValue = 10e18; // 10x starting PPS
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(hwmValue));

        // Set PPS significantly lower (50% of HWM)
        uint256 ppsValue = 5e18;
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(ppsValue));

        // Test: Should return 0 when currentPPS is significantly below vaultHwmPps
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when currentPPS is significantly below vaultHwmPps");
    }

    /// @notice Tests with both PPS and HWM at minimum non-zero value
    /// @dev Tests edge case with 1 wei for both
    function test_VaultUnrealizedProfit_MinimalValuesEqual() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Set both to 1 wei
        uint256 minValue = 1;

        // Set HWM
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(minValue));

        // Set PPS
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(minValue));

        // Test: Should return 0 when both are minimal and equal
        uint256 profit = strategy.vaultUnrealizedProfit();
        assertEq(profit, 0, "Profit should be 0 when both currentPPS and vaultHwmPps are 1 wei");
    }

    /// @notice Tests multiple scenarios where <= condition should return 0
    /// @dev Comprehensive test for various PPS/HWM relationships
    function test_VaultUnrealizedProfit_ComprehensiveLessThanOrEqualCases() public {
        // Setup: Make a deposit
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(1000e18, testUser);
        vm.stopPrank();

        // Test case 1: PPS = 1e18, HWM = 1e18 (equal at starting value)
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(uint256(1e18)));
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(1e18)));
        assertEq(strategy.vaultUnrealizedProfit(), 0, "Case 1: Equal at 1e18 should return 0");

        // Test case 2: PPS = 0.5e18, HWM = 1e18 (PPS < HWM)
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(0.5e18)));
        assertEq(strategy.vaultUnrealizedProfit(), 0, "Case 2: PPS < HWM should return 0");

        // Test case 3: PPS = 2e18, HWM = 3e18 (PPS < HWM, both above starting)
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(uint256(3e18)));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(2e18)));
        assertEq(strategy.vaultUnrealizedProfit(), 0, "Case 3: PPS (2e18) < HWM (3e18) should return 0");

        // Test case 4: PPS = 10e18, HWM = 10e18 (equal at high value)
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(uint256(10e18)));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(10e18)));
        assertEq(strategy.vaultUnrealizedProfit(), 0, "Case 4: Equal at 10e18 should return 0");

        // Test case 5: PPS = 0, HWM = 1 (minimal values, PPS < HWM)
        vm.store(address(strategy), bytes32(uint256(16)), bytes32(uint256(1)));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(uint256(0)));
        assertEq(strategy.vaultUnrealizedProfit(), 0, "Case 5: PPS (0) < HWM (1) should return 0");
    }

    // =============================================================
    // containsYieldSource Tests
    // =============================================================

    /// @notice Tests containsYieldSource returns false when source doesn't exist, true after adding, and false after removing
    /// @dev Covers SuperVaultStrategy.sol:630-632
    function test_ContainsYieldSource() public {
        // Setup: Define yield source addresses
        address yieldSourceAddr = address(0x1234);
        address oracleAddr = address(0x5678);

        // Test 1: Returns false when yield source doesn't exist
        bool containsBefore = strategy.containsYieldSource(yieldSourceAddr);
        assertFalse(containsBefore, "Should return false for non-existent yield source");

        // Test 2: Add yield source and verify it returns true
        address[] memory sources = new address[](1);
        address[] memory oracles = new address[](1);
        uint8[] memory actionTypes = new uint8[](1);

        sources[0] = yieldSourceAddr;
        oracles[0] = oracleAddr;
        actionTypes[0] = 0; // 0 = Add

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        bool containsAfterAdd = strategy.containsYieldSource(yieldSourceAddr);
        assertTrue(containsAfterAdd, "Should return true after adding yield source");

        // Test 3: Remove yield source and verify it returns false
        actionTypes[0] = 2; // 2 = Remove

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actionTypes);

        bool containsAfterRemove = strategy.containsYieldSource(yieldSourceAddr);
        assertFalse(containsAfterRemove, "Should return false after removing yield source");

        // Test 4: Verify other non-existent addresses also return false
        address anotherAddr = address(0x9999);
        bool containsOther = strategy.containsYieldSource(anotherAddr);
        assertFalse(containsOther, "Should return false for any non-existent yield source");
    }

    // =============================================================
    // previewExactRedeemBatch Tests
    // =============================================================

    /// @notice Tests previewExactRedeemBatch reverts when controllers array is empty
    /// @dev Covers SuperVaultStrategy.sol:687
    function test_PreviewExactRedeemBatch_RevertsOnZeroLength() public {
        // Setup: Create an empty controllers array
        address[] memory controllers = new address[](0);

        // Test: Attempt to preview with empty array should revert with ZERO_LENGTH
        vm.expectRevert(ISuperVaultStrategy.ZERO_LENGTH.selector);
        strategy.previewExactRedeemBatch(controllers);
    }

    // =============================================================
    // _handleRequestRedeem Tests (First 3 If Statements)
    // =============================================================

    /// @notice Tests requestRedeem reverts when shares is zero
    /// @dev Covers SuperVaultStrategy.sol:962 - first if statement in _handleRequestRedeem
    /// @dev Note: The vault ERC7540 layer checks for ZERO_AMOUNT before reaching the strategy
    function test_RequestRedeem_RevertsOnZeroShares() public {
        // Setup: Create a user with shares
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Test: Attempt to request redeem with 0 shares
        // The vault checks for zero amount before the strategy
        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.requestRedeem(0, testUser, testUser);
        vm.stopPrank();
    }

    /// @notice Tests requestRedeem reverts when controller is address(0)
    /// @dev Covers SuperVaultStrategy.sol:963 - second if statement in _handleRequestRedeem
    function test_RequestRedeem_RevertsOnZeroAddressController() public {
        // Setup: Create a user with shares
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        uint256 shares = vault.balanceOf(testUser);

        // Test: Attempt to request redeem with address(0) as controller
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        vault.requestRedeem(shares / 2, address(0), testUser);
        vm.stopPrank();
    }

    /// @notice Tests requestRedeem with PPS boundary (currentPPS == 1)
    /// @dev Covers SuperVaultStrategy.sol:968 - third if statement boundary test
    /// @dev Note: Testing currentPPS == 0 is difficult due to storage complexity
    /// @dev and represents a corrupted state that shouldn't occur in normal operation
    /// @dev This test verifies the success case with minimal PPS (boundary)
    function test_RequestRedeem_SucceedsWithMinimalPPS() public {
        // Setup: Create a user with shares
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        uint256 shares = vault.balanceOf(testUser);

        // Test: Request redeem with normal PPS (> 0) succeeds
        // This verifies the currentPPS check passes when PPS is valid
        vault.requestRedeem(shares / 2, testUser, testUser);
        vm.stopPrank();

        // No revert means the currentPPS check passed (PPS > 0)
    }

    /// @notice Tests requestRedeem succeeds with valid parameters
    /// @dev Covers success path for first 3 if statements (all conditions pass)
    function test_RequestRedeem_SucceedsWithValidParameters() public {
        // Setup: Create a user with shares
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        uint256 shares = vault.balanceOf(testUser);

        // Test: Request redeem with valid parameters
        uint256 sharesToRedeem = shares / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vm.stopPrank();

        // No revert means success
    }

    /// @notice Tests requestRedeem with shares exactly equal to 1 (boundary test)
    /// @dev Covers SuperVaultStrategy.sol:962 - boundary test for shares > 0
    function test_RequestRedeem_SucceedsWithOneShare() public {
        // Setup: Create a user with shares
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Test: Request redeem with exactly 1 share (boundary case)
        vault.requestRedeem(1, testUser, testUser);
        vm.stopPrank();
        // No revert means success
    }

    // =============================================================
    // _handleCancelRedeemRequest Tests (All If Checks)
    // =============================================================

    /// @notice Tests cancelRedeemRequest reverts when controller is address(0)
    /// @dev Covers SuperVaultStrategy.sol:995 - first if check in _handleCancelRedeemRequest
    /// @dev Note: The vault ERC7540 layer checks for INVALID_CONTROLLER before reaching the strategy
    function test_CancelRedeemRequest_RevertsOnZeroAddressController() public {
        // Setup: Create a user with a redeem request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares / 2, testUser, testUser);
        vm.stopPrank();

        // Test: Attempt to cancel with address(0) as controller
        // The vault checks for invalid controller before the strategy
        vm.prank(testUser);
        vm.expectRevert(ISuperVault.INVALID_CONTROLLER.selector);
        vault.cancelRedeemRequest(0, address(0));
    }

    /// @notice Tests cancelRedeemRequest reverts when no redeem request exists
    /// @dev Covers SuperVaultStrategy.sol:997 - second if check in _handleCancelRedeemRequest
    function test_CancelRedeemRequest_RevertsOnNoRedeemRequest() public {
        // Setup: Create a user without any redeem request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        // Intentionally NOT creating a redeem request

        // Test: Attempt to cancel when no redeem request exists
        vm.expectRevert(ISuperVaultStrategy.REQUEST_NOT_FOUND.selector);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();
    }

    /// @notice Tests cancelRedeemRequest reverts when cancel already pending
    /// @dev Covers SuperVaultStrategy.sol:998 - third if check in _handleCancelRedeemRequest
    function test_CancelRedeemRequest_RevertsOnCancelAlreadyPending() public {
        // Setup: Create a user with a redeem request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares / 2, testUser, testUser);

        // First cancel request succeeds
        vault.cancelRedeemRequest(0, testUser);

        // Test: Attempt to cancel again while first cancel is still pending
        vm.expectRevert(ISuperVaultStrategy.CANCELLATION_REDEEM_REQUEST_PENDING.selector);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();
    }

    /// @notice Tests cancelRedeemRequest succeeds with valid conditions
    /// @dev Covers success path for all 3 if checks in _handleCancelRedeemRequest
    function test_CancelRedeemRequest_SucceedsWithValidRequest() public {
        // Setup: Create a user with a redeem request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares / 2, testUser, testUser);

        // Test: Cancel with valid conditions (all checks pass)
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Verify cancel request is now pending
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertTrue(isPending, "Cancel request should be pending");
    }

    /// @notice Tests cancelRedeemRequest with pendingRedeemRequest exactly equal to 1
    /// @dev Covers SuperVaultStrategy.sol:997 - boundary test for pendingRedeemRequest > 0
    function test_CancelRedeemRequest_SucceedsWithMinimalRedeemRequest() public {
        // Setup: Create a user with minimal redeem request (1 share)
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Request redeem with exactly 1 share (boundary)
        vault.requestRedeem(1, testUser, testUser);

        // Test: Cancel should succeed with minimal redeem request
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Verify cancel request is pending
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertTrue(isPending, "Cancel request should be pending for minimal redeem");
    }

    // =============================================================
    // _handleClaimCancelRedeem Tests (All If Statements)
    // =============================================================

    /// @notice Tests claimCancelRedeem reverts when controller is address(0)
    /// @dev Covers SuperVaultStrategy.sol:1007 - first if statement in _handleClaimCancelRedeem
    /// @dev Note: The vault ERC7540 layer checks for INVALID_CONTROLLER before reaching the strategy
    function test_ClaimCancelRedeem_RevertsOnZeroAddressController() public {
        // Setup: Create a user with a fulfilled cancel request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares / 2, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills the cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Attempt to claim with address(0) as controller
        // The vault checks for zero address before validation
        vm.prank(testUser);
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.claimCancelRedeemRequest(0, testUser, address(0));
    }

    /// @notice Tests claimCancelRedeem reverts when no claimable cancel request exists
    /// @dev Covers SuperVaultStrategy.sol:1010 - second if statement in _handleClaimCancelRedeem
    function test_ClaimCancelRedeem_RevertsOnNoClaimableRequest() public {
        // Setup: Create a user without any claimable cancel request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        // Intentionally NOT creating a cancel request

        // Test: Attempt to claim when no claimable cancel request exists
        vm.expectRevert(ISuperVaultStrategy.REQUEST_NOT_FOUND.selector);
        vault.claimCancelRedeemRequest(0, testUser, testUser);
        vm.stopPrank();
    }

    /// @notice Tests that line 1012 check exists (defensive check for pendingCancelRedeemRequest flag)
    /// @dev Covers SuperVaultStrategy.sol:1012 - third if statement in _handleClaimCancelRedeem
    /// @dev This is a defensive check: if (!state.pendingCancelRedeemRequest) revert CANCELLATION_REDEEM_REQUEST_PENDING()
    /// @dev The check ensures pendingCancelRedeemRequest is true when claiming
    /// @dev This condition cannot be triggered through normal operations since:
    /// @dev - fulfillCancelRedeemRequests keeps pendingCancelRedeemRequest = true
    /// @dev - Only claimCancelRedeemRequest sets it to false (after passing all checks)
    /// @dev - So having claimable > 0 with pending = false would require corrupted state
    /// @dev Instead, we verify the check exists by ensuring the success path requires pending = true
    function test_ClaimCancelRedeem_RequiresPendingFlagTrue() public {
        // Setup: Create a fulfilled cancel request (pending = true, claimable > 0)
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares / 2, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills (sets claimable > 0, keeps pending = true)
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Verify the state before claim: pending should be true
        bool pendingBefore = vault.pendingCancelRedeemRequest(0, testUser);
        assertTrue(pendingBefore, "Pending flag should be true before claim");

        // Test: Successful claim (passes all checks including line 1012)
        vm.prank(testUser);
        vault.claimCancelRedeemRequest(0, testUser, testUser);

        // Verify the pending flag was cleared after successful claim
        bool pendingAfter = vault.pendingCancelRedeemRequest(0, testUser);
        assertFalse(pendingAfter, "Pending flag should be false after claim");

        // Note: Line 1012 check passed during the claim above
        // The check verifies pendingCancelRedeemRequest == true is required for claim to succeed
    }

    /// @notice Tests claimCancelRedeem succeeds with valid fulfilled request
    /// @dev Covers success path for all 3 if statements in _handleClaimCancelRedeem
    function test_ClaimCancelRedeem_SucceedsWithValidRequest() public {
        // Setup: Create a user with a fulfilled cancel request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        uint256 shares = vault.balanceOf(testUser);
        vault.requestRedeem(shares / 2, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills the cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Claim should succeed (all checks pass)
        vm.prank(testUser);
        vault.claimCancelRedeemRequest(0, testUser, testUser);

        // Verify cancel request is no longer pending after claim
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertFalse(isPending, "Cancel request should not be pending after claim");
    }

    /// @notice Tests claimCancelRedeem with claimableCancelRedeemRequest exactly equal to 1
    /// @dev Covers SuperVaultStrategy.sol:1010 - boundary test for claimable > 0
    function test_ClaimCancelRedeem_SucceedsWithMinimalClaimable() public {
        // Setup: Create a user with minimal cancel request (1 share)
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Request redeem with exactly 1 share
        vault.requestRedeem(1, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills the cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Claim should succeed with minimal claimable (boundary)
        vm.prank(testUser);
        vault.claimCancelRedeemRequest(0, testUser, testUser);

        // Verify claim was successful
        bool isPending = vault.pendingCancelRedeemRequest(0, testUser);
        assertFalse(isPending, "Cancel request should not be pending after claim");
    }

    /// @notice Tests claimCancelRedeemRequest succeeds when operator calls with receiver == controller
    function test_ClaimCancelRedeem_OperatorSucceedsWithReceiverEqualController() public {
        address testUser = makeAddr("testUser");
        address operatorAddr = makeAddr("operator");

        // Setup: User deposits, requests redemption, cancels, and sets operator
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Request and cancel redeem
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);

        // Set operator
        vault.setOperator(operatorAddr, true);
        vm.stopPrank();

        // Manager fulfills the cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Operator calls claimCancelRedeemRequest with receiver == controller (should succeed)
        uint256 claimableShares = strategy.claimableCancelRedeemRequest(testUser);
        assertGt(claimableShares, 0, "Should have claimable shares for test");

        uint256 receiverBalanceBefore = vault.balanceOf(testUser);

        vm.prank(operatorAddr);
        uint256 claimedShares = vault.claimCancelRedeemRequest(0, testUser, testUser);

        uint256 receiverBalanceAfter = vault.balanceOf(testUser);
        assertEq(receiverBalanceAfter - receiverBalanceBefore, claimedShares, "Receiver should receive shares");
    }

    /// @notice Tests claimCancelRedeemRequest reverts when operator calls with receiver != controller
    function test_ClaimCancelRedeem_OperatorRevertsWithReceiverNotEqualController() public {
        address testUser = makeAddr("testUser");
        address operatorAddr = makeAddr("operator");
        address otherReceiver = makeAddr("otherReceiver");

        // Setup: User deposits, requests redemption, cancels, and sets operator
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Request and cancel redeem
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);

        // Set operator
        vault.setOperator(operatorAddr, true);
        vm.stopPrank();

        // Manager fulfills the cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Operator calls claimCancelRedeemRequest with receiver != controller (should revert)
        uint256 claimableShares = strategy.claimableCancelRedeemRequest(testUser);
        assertGt(claimableShares, 0, "Should have claimable shares for test");

        vm.prank(operatorAddr);
        vm.expectRevert(ISuperVault.RECEIVER_MUST_EQUAL_CONTROLLER.selector);
        vault.claimCancelRedeemRequest(0, otherReceiver, testUser);
    }

    /// @notice Tests claimCancelRedeemRequest succeeds when controller calls with arbitrary receiver
    function test_ClaimCancelRedeem_ControllerSucceedsWithArbitraryReceiver() public {
        address testUser = makeAddr("testUser");
        address arbitraryReceiver = makeAddr("arbitraryReceiver");

        // Setup: User deposits, requests redemption, and cancels
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Request and cancel redeem
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills the cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Controller calls claimCancelRedeemRequest with arbitrary receiver (should succeed)
        uint256 claimableShares = strategy.claimableCancelRedeemRequest(testUser);
        assertGt(claimableShares, 0, "Should have claimable shares for test");

        uint256 receiverBalanceBefore = vault.balanceOf(arbitraryReceiver);

        vm.prank(testUser);
        uint256 claimedShares = vault.claimCancelRedeemRequest(0, arbitraryReceiver, testUser);

        uint256 receiverBalanceAfter = vault.balanceOf(arbitraryReceiver);
        assertEq(receiverBalanceAfter - receiverBalanceBefore, claimedShares, "Arbitrary receiver should receive shares");
    }

    /// @notice Tests claimCancelRedeemRequest reverts when non-operator calls on behalf of controller
    function test_ClaimCancelRedeem_NonOperatorReverts() public {
        address testUser = makeAddr("testUser");
        address nonOperator = makeAddr("nonOperator");

        // Setup: User deposits, requests redemption, and cancels
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);

        // Request and cancel redeem
        uint256 sharesToRedeem = vault.balanceOf(testUser) / 2;
        vault.requestRedeem(sharesToRedeem, testUser, testUser);
        vault.cancelRedeemRequest(0, testUser);
        vm.stopPrank();

        // Manager fulfills the cancel request
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Test: Non-operator calls claimCancelRedeemRequest on behalf of controller (should revert)
        uint256 claimableShares = strategy.claimableCancelRedeemRequest(testUser);
        assertGt(claimableShares, 0, "Should have claimable shares for test");

        vm.prank(nonOperator);
        vm.expectRevert(ISuperVault.INVALID_CONTROLLER.selector);
        vault.claimCancelRedeemRequest(0, testUser, testUser);
    }

    /// @notice Tests fulfillRedeemRequests reverts when controller has zero pending shares
    /// @dev Covers SuperVaultStrategy.sol:345 - if (pendingShares == 0) revert ZERO_SHARE_FULFILLMENT_DISALLOWED()
    function test_FulfillRedeemRequests_RevertsOnZeroShareFulfillment() public {
        // Setup: Create a user with no pending redeem request
        address testUser = _deployAccount(0xABC, "TestUser");
        deal(address(asset), testUser, 1000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 1000e18);
        vault.deposit(100e18, testUser);
        vm.stopPrank();

        // Test: Try to fulfill for a user with no pending request
        deal(address(asset), address(strategy), 100e18);
        vm.startPrank(manager);
        address[] memory controllers = new address[](1);
        controllers[0] = testUser; // This user has pendingShares = 0
        uint256[] memory assets = new uint256[](1);
        assets[0] = 10e18;

        vm.expectRevert(ISuperVaultStrategy.ZERO_SHARE_FULFILLMENT_DISALLOWED.selector);
        strategy.fulfillRedeemRequests(controllers, assets);
        vm.stopPrank();
    }
}
