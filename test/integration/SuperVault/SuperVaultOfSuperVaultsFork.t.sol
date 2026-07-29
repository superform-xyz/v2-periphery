// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultAggregator } from "../../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { SuperVaultYieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/SuperVaultYieldSourceOracle.sol";
import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { TotalAssetHelper } from "./TotalAssetHelper.sol";

/// @title SuperVaultOfSuperVaultsFork
/// @notice Fork test: Deploy SuperAI on a mainnet fork using the real SuperUSDC as a yield source.
///         Validates that a SuperVault can use another live SuperVault as an underlying yield source.
///
/// Real contracts (Ethereum mainnet):
///   - SuperUSDC vault:     0xf6EbeA08a0Dfd44825f67Fa9963911c81BE2a947
///   - SuperUSDC strategy:  0x41A9Eb398518D2487301c61D2b33E4e966A9F1DD
///   - SuperVaultAggregator: 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698
///   - SuperGovernor:        0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4
///   - ECDSAPPSOracle:       0x366d88F03B8EF34eb49F32a927ff6e1609F694F2
///   - ApproveAndDeposit4626VaultHook: 0xF37535D96712FBaEf6D868e721E7b987ad1E6A86
///   - Redeem4626VaultHook:            0x5c3edf3F7c43828Bb72a668e2B29f9e2D9Af5A69
contract SuperVaultOfSuperVaultsFork is Test {
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                            MAINNET CONSTANTS
    //////////////////////////////////////////////////////////////*/

    // Production contracts
    address public constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address public constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address public constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;

    // SuperUSDC
    address public constant SUPER_USDC_VAULT = 0xf6EbeA08a0Dfd44825f67Fa9963911c81BE2a947;
    address public constant SUPER_USDC_STRATEGY = 0x41A9Eb398518D2487301c61D2b33E4e966A9F1DD;

    // Hooks (deployed at same address on all chains)
    address public constant DEPOSIT_HOOK = 0xF37535D96712FBaEf6D868e721E7b987ad1E6A86;
    address public constant REDEEM_HOOK = 0x5c3edf3F7c43828Bb72a668e2B29f9e2D9Af5A69;

    // Tokens
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Test key for signing PPS updates
    uint256 public constant TEST_VALIDATOR_KEY = 0xABCD;

    // Access control role hashes (matching SuperGovernor constants)
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    SuperVault public svAI;
    SuperVaultStrategy public stratAI;
    SuperVaultYieldSourceOracle public svOracle;
    TotalAssetHelper public totalAssetHelper;

    address public manager;
    address public user;
    address public testValidator;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        manager = makeAddr("manager");
        user = makeAddr("user");
        testValidator = vm.addr(TEST_VALIDATOR_KEY);

        totalAssetHelper = new TotalAssetHelper();

        // Grant GOVERNOR_ROLE to this test contract so we can register validators
        _grantGovernorRole(address(this));

        // Register our test validator for PPS signing
        _registerTestValidator();

        // Deploy the SuperVault-specific yield source oracle
        // Use a dummy superLedgerConfiguration since it's not used for TVL queries
        svOracle = new SuperVaultYieldSourceOracle(makeAddr("ledgerConfig"));

        // Deploy SuperAI vault via the production aggregator
        _deploySuperAIVault();

        // Register SuperUSDC as a yield source for SuperAI
        vm.prank(manager);
        stratAI.manageYieldSource(SUPER_USDC_VAULT, address(svOracle), ISuperVaultStrategy.YieldSourceAction.Add);

        // Set up strategy-specific hooks root for deposit into SuperUSDC
        _setupStrategyHooksRoot();

        // Disable upkeep payments so PPS updates don't auto-pause our unfunded strategy
        vm.mockCall(
            SUPER_GOVERNOR,
            abi.encodeWithSelector(ISuperGovernor.isUpkeepPaymentsEnabled.selector),
            abi.encode(false)
        );

        // Update PPS for SuperAI (initial PPS)
        _updatePPS(address(stratAI), address(svAI));
    }

    /*//////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Verify SuperUSDC is live and has real yield sources
    function test_fork_superUSDC_isLive() public view {
        ISuperVaultStrategy.YieldSourceInfo[] memory sources =
            ISuperVaultStrategy(SUPER_USDC_STRATEGY).getYieldSourcesList();
        assertGt(sources.length, 0, "SuperUSDC should have yield sources");

        uint256 totalAssets = SuperVault(SUPER_USDC_VAULT).totalAssets();
        console2.log("SuperUSDC totalAssets:", totalAssets);
        assertGt(totalAssets, 0, "SuperUSDC should have non-zero totalAssets");

        uint256 pps = SuperVault(SUPER_USDC_VAULT).convertToAssets(1e6);
        console2.log("SuperUSDC PPS (per 1e6 shares):", pps);
    }

    /// @notice Deposit USDC into SuperAI and allocate to the real SuperUSDC
    function test_fork_depositAndAllocateToSuperUSDC() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Fund user and deposit into SuperAI
        deal(USDC, user, depositAmount);
        vm.startPrank(user);
        IERC20(USDC).approve(address(svAI), depositAmount);
        svAI.deposit(depositAmount, user);
        vm.stopPrank();

        uint256 userShares = svAI.balanceOf(user);
        assertGt(userShares, 0, "No SuperAI shares minted");
        console2.log("SuperAI shares minted:", userShares);

        // USDC should be sitting as free assets in stratAI
        assertEq(IERC20(USDC).balanceOf(address(stratAI)), depositAmount, "Wrong free assets in stratAI");

        // Allocate all USDC to SuperUSDC via deposit hook
        _allocateToSuperUSDC(depositAmount);

        // Verify: stratAI holds SuperUSDC shares (not USDC)
        uint256 svUsdcShares = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        assertGt(svUsdcShares, 0, "No SuperUSDC shares received");
        console2.log("SuperUSDC shares held by stratAI:", svUsdcShares);

        // Verify: stratAI should have zero free USDC
        assertEq(IERC20(USDC).balanceOf(address(stratAI)), 0, "stratAI should have zero free USDC");

        // Verify: totalAssets of SuperAI should be ~1000 USDC
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));
        console2.log("SuperAI totalAssets after allocation:", totalAssetsAI);
        // Allow small difference due to SuperUSDC PPS rounding
        assertApproxEqRel(totalAssetsAI, depositAmount, 0.01e18, "totalAssets should be ~depositAmount");
    }

    /// @notice Test that PPS oracle correctly reports value through the SV-of-SV chain
    function test_fork_totalAssetsReflectsRealSuperUSDCValue() public {
        uint256 depositAmount = 5000e6; // 5000 USDC

        // Deposit and allocate
        deal(USDC, user, depositAmount);
        vm.startPrank(user);
        IERC20(USDC).approve(address(svAI), depositAmount);
        svAI.deposit(depositAmount, user);
        vm.stopPrank();

        _allocateToSuperUSDC(depositAmount);

        // Get totalAssets via TotalAssetHelper (uses the oracle chain)
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));

        // Cross-check: manually compute expected value
        uint256 svUsdcShares = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        uint256 expectedFromConvert = SuperVault(SUPER_USDC_VAULT).convertToAssets(svUsdcShares);

        console2.log("totalAssets from oracle chain:", totalAssetsAI);
        console2.log("expected from convertToAssets:", expectedFromConvert);
        console2.log("SuperUSDC shares held:", svUsdcShares);

        assertApproxEqAbs(totalAssetsAI, expectedFromConvert, 1, "Oracle chain should match convertToAssets");
    }

    /// @notice Full lifecycle on a mainnet fork: deposit -> allocate -> requestRedeem -> fulfill -> claim
    function test_fork_fullLifecycle() public {
        uint256 depositAmount = 1000e6;

        // --- STEP 1: Deposit ---
        deal(USDC, user, depositAmount);
        vm.startPrank(user);
        IERC20(USDC).approve(address(svAI), depositAmount);
        svAI.deposit(depositAmount, user);
        vm.stopPrank();

        // --- STEP 2: Allocate to SuperUSDC ---
        _allocateToSuperUSDC(depositAmount);

        // Update PPS after allocation
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        // --- STEP 3: User requests redeem ---
        uint256 userShares = svAI.balanceOf(user);
        vm.startPrank(user);
        svAI.requestRedeem(userShares, user, user);
        vm.stopPrank();

        // --- STEP 4: Manager unwinds from SuperUSDC (async flow) ---
        _unwindFromSuperUSDC();

        // --- STEP 5: Fulfill user's redeem on SuperAI ---
        _fulfillUserRedeem(userShares);

        // --- STEP 6: User claims ---
        uint256 claimable = svAI.maxWithdraw(user);
        assertGt(claimable, 0, "Nothing to claim");

        uint256 balanceBefore = IERC20(USDC).balanceOf(user);
        vm.prank(user);
        svAI.withdraw(claimable, user, user);

        uint256 received = IERC20(USDC).balanceOf(user) - balanceBefore;
        console2.log("User deposited:", depositAmount);
        console2.log("User received:", received);
        // Allow up to 1% difference for fees/rounding through real SuperUSDC
        assertApproxEqRel(received, depositAmount, 0.01e18, "User didn't get back ~deposited amount");
    }

    /// @notice Two users deposit different amounts, allocate, both redeem. Verifies fair share distribution.
    function test_fork_multiUserDepositAndRedeem() public {
        address user2 = makeAddr("user2");
        uint256 depositA = 1000e6;
        uint256 depositB = 2000e6;

        // Both users deposit
        _depositAs(user, depositA);
        _depositAs(user2, depositB);

        uint256 sharesA = svAI.balanceOf(user);
        uint256 sharesB = svAI.balanceOf(user2);
        console2.log("User A shares:", sharesA);
        console2.log("User B shares:", sharesB);

        // User B should have ~2x the shares of User A
        assertApproxEqRel(sharesB, sharesA * 2, 0.01e18, "Share ratio should be ~2:1");

        // Allocate all to SuperUSDC
        _allocateToSuperUSDC(depositA + depositB);

        // Update PPS after allocation
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        // Both users request redeem
        vm.prank(user);
        svAI.requestRedeem(sharesA, user, user);
        vm.prank(user2);
        svAI.requestRedeem(sharesB, user2, user2);

        // Unwind and fulfill
        _unwindFromSuperUSDC();
        _fulfillUserRedeemFor(user, sharesA);
        _fulfillUserRedeemFor(user2, sharesB);

        // Both users claim
        uint256 claimableA = svAI.maxWithdraw(user);
        uint256 claimableB = svAI.maxWithdraw(user2);
        assertGt(claimableA, 0, "User A nothing to claim");
        assertGt(claimableB, 0, "User B nothing to claim");

        vm.prank(user);
        svAI.withdraw(claimableA, user, user);
        vm.prank(user2);
        svAI.withdraw(claimableB, user2, user2);

        uint256 receivedA = IERC20(USDC).balanceOf(user);
        uint256 receivedB = IERC20(USDC).balanceOf(user2);
        console2.log("User A received:", receivedA);
        console2.log("User B received:", receivedB);

        // Each user gets back ~their deposit
        assertApproxEqRel(receivedA, depositA, 0.01e18, "User A didn't get proportional assets");
        assertApproxEqRel(receivedB, depositB, 0.01e18, "User B didn't get proportional assets");
    }

    /// @notice Deposit 1000 USDC but only allocate 600, keeping 400 as free USDC. Verify totalAssets.
    function test_fork_partialAllocation() public {
        uint256 depositAmount = 1000e6;
        uint256 allocateAmount = 600e6;
        uint256 freeAmount = depositAmount - allocateAmount;

        _depositAs(user, depositAmount);
        _allocateToSuperUSDC(allocateAmount);

        // Verify free USDC in strategy
        assertEq(IERC20(USDC).balanceOf(address(stratAI)), freeAmount, "Wrong free USDC");

        // Verify SuperUSDC shares held
        uint256 svUsdcShares = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        assertGt(svUsdcShares, 0, "No SuperUSDC shares");

        // totalAssets = free USDC + oracle TVL from SuperUSDC shares
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));
        console2.log("totalAssets (mixed):", totalAssetsAI);
        console2.log("free USDC:", freeAmount);

        uint256 oracleTVL = SuperVault(SUPER_USDC_VAULT).convertToAssets(svUsdcShares);
        console2.log("oracle TVL from SuperUSDC:", oracleTVL);

        assertApproxEqRel(totalAssetsAI, depositAmount, 0.01e18, "totalAssets should be ~depositAmount");
        // Specifically: totalAssets should be close to freeAmount + oracleTVL
        assertApproxEqAbs(totalAssetsAI, freeAmount + oracleTVL, 1, "totalAssets != free + oracle TVL");
    }

    /// @notice User A deposits at PPS=1.0, PPS drops after allocation (rounding), User B deposits at new PPS.
    function test_fork_secondDepositAtDifferentPPS() public {
        uint256 depositA = 1000e6;
        uint256 depositB = 500e6;

        // User A deposits at initial PPS
        _depositAs(user, depositA);
        uint256 sharesA = svAI.balanceOf(user);

        // Allocate to SuperUSDC (may cause rounding loss -> PPS < 1.0)
        _allocateToSuperUSDC(depositA);

        // Update PPS after allocation
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        uint256 ppsAfterAlloc = SuperVaultAggregator(AGGREGATOR).getPPS(address(stratAI));
        uint256 precision = svAI.PRECISION();
        console2.log("PPS after allocation:", ppsAfterAlloc);
        console2.log("Precision:", precision);

        // User B deposits at the new PPS
        address user2 = makeAddr("user2");
        _depositAs(user2, depositB);
        uint256 sharesB = svAI.balanceOf(user2);

        console2.log("User A shares:", sharesA);
        console2.log("User B shares:", sharesB);

        if (ppsAfterAlloc < precision) {
            // PPS < 1.0 -> shares are cheaper -> User B gets MORE shares per USDC
            assertGt(sharesB * depositA, sharesA * depositB, "User B should get more shares/USDC when PPS < 1.0");
        } else {
            // PPS >= 1.0 -> User B gets equal or fewer shares per USDC
            assertLe(sharesB * depositA, sharesA * depositB, "User B should get <=  shares/USDC when PPS >= 1.0");
        }

        // Verify totalAssets reflects both deposits
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));
        console2.log("totalAssets after both deposits:", totalAssetsAI);
        assertApproxEqRel(totalAssetsAI, depositA + depositB, 0.01e18, "totalAssets should reflect both deposits");
    }

    /// @notice Manager pauses strategy, deposit reverts; unpause, deposit works.
    function test_fork_pauseBlocksDeposit() public {
        uint256 depositAmount = 100e6;

        // Pause
        vm.prank(manager);
        SuperVaultAggregator(AGGREGATOR).pauseStrategy(address(stratAI));

        // Deposit should revert
        deal(USDC, user, depositAmount);
        vm.startPrank(user);
        IERC20(USDC).approve(address(svAI), depositAmount);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        svAI.deposit(depositAmount, user);
        vm.stopPrank();

        // Unpause
        vm.prank(manager);
        SuperVaultAggregator(AGGREGATOR).unpauseStrategy(address(stratAI));

        // PPS is stale after unpause, so update it
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        // Deposit should work now
        vm.startPrank(user);
        svAI.deposit(depositAmount, user);
        vm.stopPrank();

        assertGt(svAI.balanceOf(user), 0, "Deposit should succeed after unpause");
    }

    /// @notice Deposit 1000 USDC, allocate, redeem only 50% of shares. Verify partial state.
    function test_fork_partialRedeem() public {
        uint256 depositAmount = 1000e6;
        _depositAs(user, depositAmount);
        _allocateToSuperUSDC(depositAmount);

        // Update PPS after allocation
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        uint256 totalShares = svAI.balanceOf(user);
        uint256 redeemShares = totalShares / 2;

        // Request partial redeem
        vm.prank(user);
        svAI.requestRedeem(redeemShares, user, user);

        // Verify user still holds 50% of shares (in escrow the other 50%)
        // After requestRedeem, shares are transferred to escrow
        uint256 remainingShares = svAI.balanceOf(user);
        assertApproxEqAbs(remainingShares, totalShares - redeemShares, 1, "User should hold ~50% shares");

        // Unwind partial from SuperUSDC
        _unwindFromSuperUSDCPartial(redeemShares);

        // Fulfill the partial redeem
        _fulfillUserRedeemFor(user, redeemShares);

        // User claims partial
        uint256 claimable = svAI.maxWithdraw(user);
        assertGt(claimable, 0, "Nothing to claim after partial redeem");

        vm.prank(user);
        svAI.withdraw(claimable, user, user);

        uint256 received = IERC20(USDC).balanceOf(user);
        console2.log("Partial redeem received:", received);
        assertApproxEqRel(received, depositAmount / 2, 0.02e18, "Should receive ~50% of deposit");

        // User still holds shares
        assertGt(svAI.balanceOf(user), 0, "User should still hold remaining shares");
    }

    /// @notice Simulate SuperUSDC yield via mock, verify SuperAI PPS increases.
    function test_fork_ppsReflectsSuperUSDCYield() public {
        uint256 depositAmount = 1000e6;
        _depositAs(user, depositAmount);
        _allocateToSuperUSDC(depositAmount);

        // Update PPS after allocation
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        uint256 ppsBefore = SuperVaultAggregator(AGGREGATOR).getPPS(address(stratAI));
        console2.log("PPS before yield:", ppsBefore);

        // SuperVault.convertToAssets uses stored PPS, so dealing USDC won't change it.
        // Instead, mock convertToAssets on SuperUSDC to simulate a PPS increase (yield).
        uint256 svUsdcShares = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        uint256 currentValue = SuperVault(SUPER_USDC_VAULT).convertToAssets(svUsdcShares);
        uint256 yieldedValue = currentValue + 100e6; // +100 USDC yield

        vm.mockCall(
            SUPER_USDC_VAULT,
            abi.encodeWithSelector(IERC4626.convertToAssets.selector, svUsdcShares),
            abi.encode(yieldedValue)
        );

        // Recompute PPS - should be higher since oracle now sees higher TVL
        vm.warp(block.timestamp + 10);
        uint256 ppsAfter = _computePPS(address(stratAI), address(svAI));
        console2.log("PPS after yield:", ppsAfter);

        assertGt(ppsAfter, ppsBefore, "PPS should increase after SuperUSDC yield");

        vm.clearMockedCalls();
    }

    /// @notice Deposit 1000, allocate 500, update PPS, allocate another 500. Verify sequential allocations.
    function test_fork_multipleAllocationsInTranches() public {
        uint256 depositAmount = 1000e6;
        uint256 tranche = 500e6;

        _depositAs(user, depositAmount);

        // First allocation
        _allocateToSuperUSDC(tranche);
        uint256 sharesAfterFirst = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        assertGt(sharesAfterFirst, 0, "No shares after first allocation");
        assertEq(IERC20(USDC).balanceOf(address(stratAI)), tranche, "Should have 500 USDC left");

        // Update PPS between allocations
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        // Second allocation
        _allocateToSuperUSDC(tranche);
        uint256 sharesAfterSecond = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        assertGt(sharesAfterSecond, sharesAfterFirst, "Should have more shares after second allocation");
        assertEq(IERC20(USDC).balanceOf(address(stratAI)), 0, "Should have 0 USDC left");

        // totalAssets should reflect ~1000 USDC
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));
        console2.log("totalAssets after two tranches:", totalAssetsAI);
        assertApproxEqRel(totalAssetsAI, depositAmount, 0.01e18, "totalAssets should be ~depositAmount");
    }

    /// @notice User deposits, requests redeem, cancels. Manager fulfills cancellation. User can deposit again.
    function test_fork_redeemCancellation() public {
        uint256 depositAmount = 500e6;
        _depositAs(user, depositAmount);

        uint256 shares = svAI.balanceOf(user);

        // Allocate
        _allocateToSuperUSDC(depositAmount);
        vm.warp(block.timestamp + 10);
        _updatePPS(address(stratAI), address(svAI));

        // Request redeem
        vm.prank(user);
        svAI.requestRedeem(shares, user, user);
        assertEq(svAI.balanceOf(user), 0, "User should have 0 shares after requestRedeem");

        // Cancel the redeem request
        vm.prank(user);
        svAI.cancelRedeemRequest(0, user);

        // Manager fulfills the cancellation
        address[] memory controllers = new address[](1);
        controllers[0] = user;
        vm.prank(manager);
        stratAI.fulfillCancelRedeemRequests(controllers);

        // User claims cancelled shares back
        vm.prank(user);
        svAI.claimCancelRedeemRequest(0, user, user);

        // Shares should be returned
        uint256 sharesAfterCancel = svAI.balanceOf(user);
        assertEq(sharesAfterCancel, shares, "Shares should be returned after cancel");

        // User can deposit again
        _depositAs(user, 100e6);
        assertGt(svAI.balanceOf(user), shares, "User should have more shares after second deposit");
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL: VAULT DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    function _deploySuperAIVault() internal {
        ISuperGovernor governor = ISuperGovernor(SUPER_GOVERNOR);
        uint256 minStaleness = governor.getMinStaleness();

        ISuperVaultAggregator.VaultCreationParams memory params = ISuperVaultAggregator.VaultCreationParams({
            asset: USDC,
            name: "SuperAI Vault",
            symbol: "svAI",
            mainManager: manager,
            secondaryManagers: new address[](0),
            minUpdateInterval: 0,
            maxStaleness: minStaleness > 0 ? minStaleness : 1 days,
            feeConfig: ISuperVaultStrategy.FeeConfig({
                performanceFeeBps: 0,
                managementFeeBps: 0,
                recipient: manager
            })
        });

        (address vault, address strategy,) = SuperVaultAggregator(AGGREGATOR).createVault(params);
        svAI = SuperVault(vault);
        stratAI = SuperVaultStrategy(payable(strategy));

        vm.label(vault, "svAI");
        vm.label(strategy, "stratAI");
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL: ACCESS CONTROL HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Grant GOVERNOR_ROLE to an account using OZ AccessControl storage manipulation
    function _grantGovernorRole(address account) internal {
        // OZ 5.x AccessControl stores _roles at slot 0
        // _roles[role].hasRole[account] is at keccak256(account . keccak256(role . 0))
        bytes32 roleSlot = keccak256(abi.encode(GOVERNOR_ROLE, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR, hasRoleSlot, bytes32(uint256(1)));
    }

    /// @dev Register a test validator in the SuperGovernor for PPS signing
    function _registerTestValidator() internal {
        address[] memory validators = new address[](1);
        validators[0] = testValidator;
        bytes[] memory pubKeys = new bytes[](1);
        pubKeys[0] = "";

        ISuperGovernor(SUPER_GOVERNOR).setValidatorConfig(
            1, // version
            validators,
            pubKeys,
            1, // quorum = 1
            "" // offchain config
        );
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL: PPS UPDATE
    //////////////////////////////////////////////////////////////*/

    function _computePPS(address strategyAddr, address vault_) internal view returns (uint256) {
        uint256 totalSupplyAmount = SuperVault(vault_).totalSupply();
        uint256 precision = SuperVault(vault_).PRECISION();
        if (totalSupplyAmount == 0) return precision;
        (uint256 currentTotalAssets,) = totalAssetHelper.totalAssets(strategyAddr);
        return currentTotalAssets.mulDiv(precision, totalSupplyAmount, Math.Rounding.Floor);
    }

    function _signPPS(address strategyAddr, uint256 pps) internal view returns (bytes memory) {
        IECDSAPPSOracle oracle = IECDSAPPSOracle(ECDSA_PPS_ORACLE);
        bytes32 structHash = keccak256(
            abi.encodePacked(
                oracle.UPDATE_PPS_TYPEHASH(), strategyAddr, pps, block.timestamp, oracle.noncePerStrategy(strategyAddr)
            )
        );
        bytes32 digest = MessageHashUtils.toTypedDataHash(oracle.domainSeparator(), structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TEST_VALIDATOR_KEY, digest);
        return abi.encodePacked(r, s, v);
    }

    function _updatePPS(address strategyAddr, address vault_) internal {
        uint256 pps = _computePPS(strategyAddr, vault_);

        address[] memory strategies = new address[](1);
        strategies[0] = strategyAddr;

        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = new bytes[](1);
        proofsArray[0][0] = _signPPS(strategyAddr, pps);

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = pps;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        IECDSAPPSOracle(ECDSA_PPS_ORACLE).updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL: MERKLE TREE FOR STRATEGY HOOKS
    //////////////////////////////////////////////////////////////*/

    function _setupStrategyHooksRoot() internal {
        (, bytes32 root) = _buildStrategyTree();

        vm.prank(manager);
        SuperVaultAggregator(AGGREGATOR).proposeStrategyHooksRoot(address(stratAI), root);

        vm.warp(block.timestamp + 20 minutes);
        SuperVaultAggregator(AGGREGATOR).executeStrategyHooksRootUpdate(address(stratAI));
    }

    function _createLeaf(address hookAddress, bytes memory hookArgs) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
    }

    function _sortBytes32(bytes32[] memory arr) internal pure {
        uint256 n = arr.length;
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = i + 1; j < n; j++) {
                if (arr[i] > arr[j]) {
                    (arr[i], arr[j]) = (arr[j], arr[i]);
                }
            }
        }
    }

    function _computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint256 n = leaves.length;
        while (n > 1) {
            for (uint256 i = 0; i < n / 2; i++) {
                bytes32 left = leaves[2 * i];
                bytes32 right = leaves[2 * i + 1];
                if (left <= right) {
                    leaves[i] = keccak256(abi.encodePacked(left, right));
                } else {
                    leaves[i] = keccak256(abi.encodePacked(right, left));
                }
            }
            n = n / 2;
        }
        return leaves[0];
    }

    function _computeMerkleProof(bytes32[] memory leaves, uint256 leafIndex) internal pure returns (bytes32[] memory) {
        uint256 n = leaves.length;
        uint256 depth = 0;
        uint256 temp = n;
        while (temp > 1) {
            depth++;
            temp /= 2;
        }

        bytes32[] memory proof = new bytes32[](depth);
        uint256 proofIndex = 0;
        uint256 currentIndex = leafIndex;

        bytes32[] memory tree = new bytes32[](n);
        for (uint256 i = 0; i < n; i++) {
            tree[i] = leaves[i];
        }

        uint256 currentN = n;
        while (currentN > 1) {
            uint256 siblingIndex = currentIndex % 2 == 0 ? currentIndex + 1 : currentIndex - 1;
            proof[proofIndex] = tree[siblingIndex];
            proofIndex++;

            for (uint256 i = 0; i < currentN / 2; i++) {
                bytes32 left = tree[2 * i];
                bytes32 right = tree[2 * i + 1];
                if (left <= right) {
                    tree[i] = keccak256(abi.encodePacked(left, right));
                } else {
                    tree[i] = keccak256(abi.encodePacked(right, left));
                }
            }

            currentIndex /= 2;
            currentN /= 2;
        }

        return proof;
    }

    function _buildStrategyTree() internal view returns (bytes32[] memory sortedLeaves, bytes32 root) {
        // Leaves: deposit into SuperUSDC + redeem from SuperUSDC
        sortedLeaves = new bytes32[](4);
        sortedLeaves[0] = _createLeaf(DEPOSIT_HOOK, abi.encodePacked(SUPER_USDC_VAULT, USDC));
        sortedLeaves[1] = _createLeaf(REDEEM_HOOK, abi.encodePacked(SUPER_USDC_VAULT, address(stratAI)));
        sortedLeaves[2] = bytes32(0);
        sortedLeaves[3] = bytes32(0);

        _sortBytes32(sortedLeaves);

        // Compute root on a COPY so sortedLeaves is preserved for proof generation
        bytes32[] memory leavesCopy = new bytes32[](4);
        for (uint256 i = 0; i < 4; i++) {
            leavesCopy[i] = sortedLeaves[i];
        }
        root = _computeMerkleRoot(leavesCopy);
    }

    function _getStrategyProof(
        address hookAddress,
        bytes memory hookArgs
    )
        internal
        view
        returns (bytes32[] memory proof)
    {
        (bytes32[] memory sortedLeaves,) = _buildStrategyTree();
        bytes32 targetLeaf = _createLeaf(hookAddress, hookArgs);

        for (uint256 i = 0; i < sortedLeaves.length; i++) {
            if (sortedLeaves[i] == targetLeaf) {
                return _computeMerkleProof(sortedLeaves, i);
            }
        }
        revert("Leaf not found in strategy tree");
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL: HOOK EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @dev Unwind stratAI's position from SuperUSDC via the async redeem flow
    function _unwindFromSuperUSDC() internal {
        uint256 svUsdcShares = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        vm.prank(address(stratAI));
        SuperVault(SUPER_USDC_VAULT).requestRedeem(svUsdcShares, address(stratAI), address(stratAI));

        // SuperUSDC's manager fulfills stratAI's request
        address superUsdcManager = SuperVaultAggregator(AGGREGATOR).getMainManager(SUPER_USDC_STRATEGY);
        uint256 redeemValue = SuperVault(SUPER_USDC_VAULT).convertToAssets(svUsdcShares);
        deal(USDC, SUPER_USDC_STRATEGY, IERC20(USDC).balanceOf(SUPER_USDC_STRATEGY) + redeemValue);

        address[] memory controllers = new address[](1);
        controllers[0] = address(stratAI);
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = redeemValue;

        vm.prank(superUsdcManager);
        SuperVaultStrategy(payable(SUPER_USDC_STRATEGY)).fulfillRedeemRequests(controllers, assetsOut);

        // stratAI withdraws USDC from SuperUSDC
        uint256 claimable = SuperVault(SUPER_USDC_VAULT).maxWithdraw(address(stratAI));
        vm.prank(address(stratAI));
        SuperVault(SUPER_USDC_VAULT).withdraw(claimable, address(stratAI), address(stratAI));
    }

    /// @dev Fulfill user's redeem on SuperAI, capping at theoretical max to respect bounds
    function _fulfillUserRedeem(uint256 pendingShares) internal {
        address[] memory users = new address[](1);
        users[0] = user;

        uint256 currentPPS = SuperVaultAggregator(AGGREGATOR).getPPS(address(stratAI));
        uint256 theoreticalMax = pendingShares.mulDiv(currentPPS, svAI.PRECISION(), Math.Rounding.Floor);
        uint256 available = IERC20(USDC).balanceOf(address(stratAI));

        uint256[] memory userAssetsOut = new uint256[](1);
        userAssetsOut[0] = available < theoreticalMax ? available : theoreticalMax;

        vm.prank(manager);
        stratAI.fulfillRedeemRequests(users, userAssetsOut);
    }

    /// @dev Fund, approve, and deposit for any user
    function _depositAs(address who, uint256 amount) internal {
        deal(USDC, who, IERC20(USDC).balanceOf(who) + amount);
        vm.startPrank(who);
        IERC20(USDC).approve(address(svAI), amount);
        svAI.deposit(amount, who);
        vm.stopPrank();
    }

    /// @dev Fulfill a specific user's redeem request
    function _fulfillUserRedeemFor(address who, uint256 pendingShares) internal {
        address[] memory users = new address[](1);
        users[0] = who;

        uint256 currentPPS = SuperVaultAggregator(AGGREGATOR).getPPS(address(stratAI));
        uint256 theoreticalMax = pendingShares.mulDiv(currentPPS, svAI.PRECISION(), Math.Rounding.Floor);
        uint256 available = IERC20(USDC).balanceOf(address(stratAI));

        uint256[] memory userAssetsOut = new uint256[](1);
        userAssetsOut[0] = available < theoreticalMax ? available : theoreticalMax;

        vm.prank(manager);
        stratAI.fulfillRedeemRequests(users, userAssetsOut);
    }

    /// @dev Unwind a partial position from SuperUSDC (based on share ratio)
    function _unwindFromSuperUSDCPartial(uint256 redeemShares) internal {
        uint256 totalSvUsdcShares = SuperVault(SUPER_USDC_VAULT).balanceOf(address(stratAI));
        // totalSupply() already includes escrowed shares (they're transferred, not burned)
        uint256 totalSvAISupply = svAI.totalSupply();
        uint256 sharesToUnwind = totalSvUsdcShares.mulDiv(redeemShares, totalSvAISupply, Math.Rounding.Ceil);
        if (sharesToUnwind > totalSvUsdcShares) sharesToUnwind = totalSvUsdcShares;

        vm.prank(address(stratAI));
        SuperVault(SUPER_USDC_VAULT).requestRedeem(sharesToUnwind, address(stratAI), address(stratAI));

        // Fulfill
        address superUsdcManager = SuperVaultAggregator(AGGREGATOR).getMainManager(SUPER_USDC_STRATEGY);
        uint256 redeemValue = SuperVault(SUPER_USDC_VAULT).convertToAssets(sharesToUnwind);
        deal(USDC, SUPER_USDC_STRATEGY, IERC20(USDC).balanceOf(SUPER_USDC_STRATEGY) + redeemValue);

        address[] memory controllers = new address[](1);
        controllers[0] = address(stratAI);
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = redeemValue;

        vm.prank(superUsdcManager);
        SuperVaultStrategy(payable(SUPER_USDC_STRATEGY)).fulfillRedeemRequests(controllers, assetsOut);

        // Withdraw
        uint256 claimable = SuperVault(SUPER_USDC_VAULT).maxWithdraw(address(stratAI));
        vm.prank(address(stratAI));
        SuperVault(SUPER_USDC_VAULT).withdraw(claimable, address(stratAI), address(stratAI));
    }

    function _allocateToSuperUSDC(uint256 amount) internal {
        // Build hook data for ApproveAndDeposit4626VaultHook
        // Layout: bytes32 oracleId | address vault | address token | uint256 amount | bool usePrev | address vaultBank | uint256 dstChainId
        bytes32 oracleId = bytes32(0); // placeholder, not used by SuperVault strategy
        bytes memory hookData =
            abi.encodePacked(oracleId, SUPER_USDC_VAULT, USDC, amount, false, address(0), uint256(0));

        address[] memory hooks = new address[](1);
        hooks[0] = DEPOSIT_HOOK;

        bytes[] memory hookCalldata = new bytes[](1);
        hookCalldata[0] = hookData;

        uint256[] memory expectedOut = new uint256[](1);
        expectedOut[0] = IERC4626(SUPER_USDC_VAULT).previewDeposit(amount);

        // Get inspected args for proof
        bytes memory inspectedArgs = ISuperHookInspector(DEPOSIT_HOOK).inspect(hookData);

        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0);

        bytes32[][] memory stratProofs = new bytes32[][](1);
        stratProofs[0] = _getStrategyProof(DEPOSIT_HOOK, inspectedArgs);

        vm.prank(manager);
        stratAI.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooks,
                hookCalldata: hookCalldata,
                expectedAssetsOrSharesOut: expectedOut,
                globalProofs: globalProofs,
                strategyProofs: stratProofs
            })
        );
    }
}
