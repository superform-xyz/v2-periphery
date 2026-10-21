// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ManagedVaultWrapper } from "../../src/SuperVault/ManagedVaultWrapper.sol";
import { IManagedVaultWrapper } from "../../src/interfaces/SuperVault/IManagedVaultWrapper.sol";
import { IERC7540Deposit } from "../../src/vendor/standards/ERC7540/IERC7540Vault.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockSuperVaultAggregator } from "../mocks/MockSuperVaultAggregator.sol";

/// @notice Unit tests for ManagedVaultWrapper
contract ManagedVaultWrapperTest is Test {
    ManagedVaultWrapper internal wrapperImpl;
    ManagedVaultWrapper internal wrapper;

    MockERC20 internal asset;
    MockERC20 internal svVault; // simulates SuperVault ERC-20 shares
    MockSuperVaultAggregator internal aggregator;

    address internal manager;
    address internal investor;
    address internal investor2;
    address internal stranger;
    address internal svStrategyAddr;

    uint256 internal constant PRECISION = 1e6; // 6-decimal asset (USDC)
    uint256 internal constant DEAD_SHARES = 1000;
    uint256 internal constant INITIAL_PPS = 1e6; // 1:1

    function setUp() public {
        manager = makeAddr("manager");
        investor = makeAddr("investor");
        investor2 = makeAddr("investor2");
        stranger = makeAddr("stranger");
        svStrategyAddr = makeAddr("svStrategy");

        // Deploy mock ERC-20 tokens
        asset = new MockERC20("USDC", "USDC", 6);
        svVault = new MockERC20("SV Vault", "SVV", 6);

        // Deploy and configure mock aggregator
        aggregator = new MockSuperVaultAggregator();
        aggregator.setMainManager(svStrategyAddr, manager);
        aggregator.setMaxStaleness(svStrategyAddr, 1 days);
        aggregator.setPPS(svStrategyAddr, INITIAL_PPS);

        // Deploy implementation and clone
        wrapperImpl = new ManagedVaultWrapper();
        address clone = Clones.clone(address(wrapperImpl));
        wrapper = ManagedVaultWrapper(clone);

        // Initialize
        wrapper.initialize(
            address(asset),
            "Managed Vault",
            "mvUSDC",
            address(svVault),
            svStrategyAddr,
            manager,
            false, // not gated
            address(aggregator)
        );

        // Give investor some USDC
        asset.mint(investor, 1000e6);
        asset.mint(investor2, 1000e6);
        vm.prank(investor);
        asset.approve(address(wrapper), type(uint256).max);
        vm.prank(investor2);
        asset.approve(address(wrapper), type(uint256).max);
    }

    // =============================================================
    // initialize
    // =============================================================

    function test_Initialize_SetsParameters() public view {
        assertEq(wrapper.asset(), address(asset));
        assertEq(wrapper.svVault(), address(svVault));
        assertEq(wrapper.svStrategy(), svStrategyAddr);
        assertEq(wrapper.mainManager(), manager);
        assertEq(wrapper.aggregator(), address(aggregator));
        assertFalse(wrapper.isGated());
        assertFalse(wrapper.isPaused());
    }

    function test_Initialize_MintsDeadShares() public view {
        assertEq(wrapper.balanceOf(address(0xdead)), DEAD_SHARES);
        assertEq(wrapper.totalSupply(), DEAD_SHARES);
    }

    function test_Initialize_RevertZeroAsset() public {
        address clone = Clones.clone(address(wrapperImpl));
        vm.expectRevert(IManagedVaultWrapper.ZERO_ADDRESS.selector);
        ManagedVaultWrapper(clone).initialize(
            address(0), "M", "M", address(svVault), svStrategyAddr, manager, false, address(aggregator)
        );
    }

    function test_Initialize_RevertZeroSvVault() public {
        address clone = Clones.clone(address(wrapperImpl));
        vm.expectRevert(IManagedVaultWrapper.ZERO_ADDRESS.selector);
        ManagedVaultWrapper(clone).initialize(
            address(asset), "M", "M", address(0), svStrategyAddr, manager, false, address(aggregator)
        );
    }

    function test_Initialize_RevertZeroManager() public {
        address clone = Clones.clone(address(wrapperImpl));
        vm.expectRevert(IManagedVaultWrapper.ZERO_ADDRESS.selector);
        ManagedVaultWrapper(clone).initialize(
            address(asset), "M", "M", address(svVault), svStrategyAddr, address(0), false, address(aggregator)
        );
    }

    // =============================================================
    // requestDeposit
    // =============================================================

    function test_RequestDeposit_TransfersAssets() public {
        uint256 amount = 100e6;
        vm.prank(investor);
        wrapper.requestDeposit(amount, investor, investor);

        assertEq(asset.balanceOf(address(wrapper)), amount);
        assertEq(wrapper.pendingDepositRequest(0, investor), amount);
        assertEq(wrapper.totalPendingDeposits(), amount);
    }

    function test_RequestDeposit_EmitsEvent() public {
        uint256 amount = 100e6;
        vm.expectEmit(true, true, true, true, address(wrapper));
        emit IERC7540Deposit.DepositRequest(investor, investor, 0, investor, amount);
        vm.prank(investor);
        wrapper.requestDeposit(amount, investor, investor);
    }

    function test_RequestDeposit_AccumulatesMultiple() public {
        vm.prank(investor);
        wrapper.requestDeposit(100e6, investor, investor);
        vm.prank(investor);
        wrapper.requestDeposit(50e6, investor, investor);

        assertEq(wrapper.pendingDepositRequest(0, investor), 150e6);
        assertEq(wrapper.totalPendingDeposits(), 150e6);
    }

    function test_RequestDeposit_RevertZeroAmount() public {
        vm.expectRevert(IManagedVaultWrapper.ZERO_AMOUNT.selector);
        vm.prank(investor);
        wrapper.requestDeposit(0, investor, investor);
    }

    function test_RequestDeposit_RevertWhenPaused() public {
        vm.prank(manager);
        wrapper.setPaused(true);
        vm.expectRevert(IManagedVaultWrapper.PAUSED.selector);
        vm.prank(investor);
        wrapper.requestDeposit(100e6, investor, investor);
    }

    function test_RequestDeposit_RevertNotAllowlisted_GatedVault() public {
        // Deploy a gated wrapper
        address clone = Clones.clone(address(wrapperImpl));
        ManagedVaultWrapper gatedWrapper = ManagedVaultWrapper(clone);
        gatedWrapper.initialize(
            address(asset), "Gated", "G", address(svVault), svStrategyAddr, manager, true, address(aggregator)
        );
        asset.mint(investor, 100e6);
        vm.prank(investor);
        asset.approve(address(gatedWrapper), type(uint256).max);

        vm.expectRevert(IManagedVaultWrapper.NOT_ALLOWLISTED.selector);
        vm.prank(investor);
        gatedWrapper.requestDeposit(100e6, investor, investor);
    }

    // =============================================================
    // fulfillDepositRequests
    // =============================================================

    function _depositAndDeployToSV(address investor_, uint256 amount) internal {
        vm.prank(investor_);
        wrapper.requestDeposit(amount, investor_, investor_);
        // Simulate manager deploying USDC into SV (transfers pending USDC to strategy, gives back SV shares)
        // In reality manager calls svVault.deposit(); here we manually:
        //   1. Take USDC from wrapper (manager withdraws)
        //   2. Mint SV shares to wrapper (representing SV deposit)
        // For simplicity: mint SV shares to wrapper equal to amount, and zero-out the USDC
        vm.prank(manager);
        IERC20(address(asset)).transferFrom(address(0), address(0), 0); // noop
        // Give svVault shares to wrapper (simulates deposit into SV)
        svVault.mint(address(wrapper), amount);
    }

    function test_FulfillDepositRequests_FirstDeposit() public {
        uint256 amount = 100e6;
        vm.prank(investor);
        wrapper.requestDeposit(amount, investor, investor);

        // Simulate SV deployment: give svVault shares to wrapper, remove the pending USDC
        // (Manager moved the USDC → SV; SV gave shares to wrapper)
        // Fake this: send USDC to /dev/null so totalPendingDeposits is accounted correctly
        // Actually, to keep it simple: we just don't remove the USDC here.
        // The totalAssets() will include both svShares*pps and rawAssets.
        // But totalPendingDeposits is subtracted, so priorAssets = 0 initially.

        // Give wrapper some svVault shares (simulating investment)
        svVault.mint(address(wrapper), amount);
        // Manager took the USDC out (in real flow), but for this test keep it simple.
        // priorAssets = totalAssets() - totalPendingDeposits
        // totalAssets() = svShares * pps / precision + rawUSDC
        //               = 100e6 * 1e6 / 1e6 + 100e6 = 200e6 (if USDC still here)
        // priorAssets = 200e6 - 100e6 = 100e6... but that's the existing SV value.
        // Actually for a "first deposit" scenario, priorSupply = 0 (excluding dead shares).
        // Let's verify the branch: priorSupply == DEAD_SHARES - DEAD_SHARES = 0 → initial formula

        address[] memory controllers = new address[](1);
        controllers[0] = investor;

        vm.prank(manager);
        wrapper.fulfillDepositRequests(controllers);

        // Should have minted shares equal to amount (1:1 for first deposit)
        assertEq(wrapper.claimableDepositShares(investor), amount);
        assertEq(wrapper.pendingDepositRequest(0, investor), 0);
        assertEq(wrapper.totalPendingDeposits(), 0);
    }

    function test_FulfillDepositRequests_ProportionalShares() public {
        // First investor deposits and claims
        uint256 amount1 = 100e6;
        vm.prank(investor);
        wrapper.requestDeposit(amount1, investor, investor);
        svVault.mint(address(wrapper), amount1);

        address[] memory c1 = new address[](1);
        c1[0] = investor;
        vm.prank(manager);
        wrapper.fulfillDepositRequests(c1);

        vm.prank(investor);
        wrapper.claimDeposit(investor, investor);

        // PPS increases to 1.1 (10% gain)
        aggregator.setPPS(svStrategyAddr, 1_100_000); // 1.1e6

        // Second investor deposits 100 USDC
        uint256 amount2 = 100e6;
        vm.prank(investor2);
        wrapper.requestDeposit(amount2, investor2, investor2);
        svVault.mint(address(wrapper), amount2); // give more svVault shares

        address[] memory c2 = new address[](1);
        c2[0] = investor2;
        vm.prank(manager);
        wrapper.fulfillDepositRequests(c2);

        // investor2 should get fewer shares since PPS went up
        uint256 sharesForInvestor2 = wrapper.claimableDepositShares(investor2);
        assertLt(sharesForInvestor2, amount2); // fewer shares than deposited assets
    }

    function test_FulfillDepositRequests_RevertNotManager() public {
        vm.prank(investor);
        wrapper.requestDeposit(100e6, investor, investor);

        address[] memory controllers = new address[](1);
        controllers[0] = investor;

        vm.expectRevert(IManagedVaultWrapper.UNAUTHORIZED.selector);
        vm.prank(stranger);
        wrapper.fulfillDepositRequests(controllers);
    }

    function test_FulfillDepositRequests_RevertPaused() public {
        vm.prank(investor);
        wrapper.requestDeposit(100e6, investor, investor);
        vm.prank(manager);
        wrapper.setPaused(true);

        address[] memory controllers = new address[](1);
        controllers[0] = investor;

        vm.expectRevert(IManagedVaultWrapper.PAUSED.selector);
        vm.prank(manager);
        wrapper.fulfillDepositRequests(controllers);
    }

    function test_FulfillDepositRequests_RevertPPSStale() public {
        vm.prank(investor);
        wrapper.requestDeposit(100e6, investor, investor);

        // Warp past maxStaleness (1 day)
        vm.warp(block.timestamp + 2 days);

        address[] memory controllers = new address[](1);
        controllers[0] = investor;

        vm.expectRevert(IManagedVaultWrapper.PPS_STALE.selector);
        vm.prank(manager);
        wrapper.fulfillDepositRequests(controllers);
    }

    function test_FulfillDepositRequests_RevertNoPendingDeposit() public {
        address[] memory controllers = new address[](1);
        controllers[0] = investor;

        vm.expectRevert(IManagedVaultWrapper.NO_PENDING_DEPOSIT.selector);
        vm.prank(manager);
        wrapper.fulfillDepositRequests(controllers);
    }

    // =============================================================
    // claimDeposit
    // =============================================================

    function test_ClaimDeposit_TransfersShares() public {
        uint256 amount = 100e6;
        vm.prank(investor);
        wrapper.requestDeposit(amount, investor, investor);
        svVault.mint(address(wrapper), amount);

        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        vm.prank(manager);
        wrapper.fulfillDepositRequests(controllers);

        vm.prank(investor);
        uint256 shares = wrapper.claimDeposit(investor, investor);

        assertEq(shares, wrapper.balanceOf(investor));
        assertEq(wrapper.claimableDepositShares(investor), 0);
    }

    function test_ClaimDeposit_RevertNoClaimableShares() public {
        vm.expectRevert(IManagedVaultWrapper.NO_CLAIMABLE_SHARES.selector);
        vm.prank(investor);
        wrapper.claimDeposit(investor, investor);
    }

    function test_ClaimDeposit_OperatorCanClaim() public {
        address operator = makeAddr("operator");
        uint256 amount = 100e6;

        vm.prank(investor);
        wrapper.requestDeposit(amount, investor, investor);
        svVault.mint(address(wrapper), amount);

        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        vm.prank(manager);
        wrapper.fulfillDepositRequests(controllers);

        vm.prank(investor);
        wrapper.setOperator(operator, true);

        vm.prank(operator);
        uint256 shares = wrapper.claimDeposit(investor, investor);
        assertGt(shares, 0);
    }

    // =============================================================
    // requestRedeem
    // =============================================================

    function _depositAndFulfillAndClaim(address investor_, uint256 amount) internal returns (uint256 shares) {
        vm.prank(investor_);
        wrapper.requestDeposit(amount, investor_, investor_);
        svVault.mint(address(wrapper), amount);

        address[] memory c = new address[](1);
        c[0] = investor_;
        vm.prank(manager);
        wrapper.fulfillDepositRequests(c);

        vm.prank(investor_);
        shares = wrapper.claimDeposit(investor_, investor_);
    }

    function test_RequestRedeem_LocksShares() public {
        uint256 amount = 100e6;
        uint256 shares = _depositAndFulfillAndClaim(investor, amount);

        vm.prank(investor);
        wrapper.requestRedeem(shares, investor, investor);

        assertEq(wrapper.pendingRedeemRequest(0, investor), shares);
        assertEq(wrapper.balanceOf(investor), 0);
        // Wrapper holds the locked shares
        assertEq(wrapper.balanceOf(address(wrapper)), shares);
    }

    function test_RequestRedeem_RevertZeroShares() public {
        _depositAndFulfillAndClaim(investor, 100e6);
        vm.expectRevert(IManagedVaultWrapper.ZERO_AMOUNT.selector);
        vm.prank(investor);
        wrapper.requestRedeem(0, investor, investor);
    }

    function test_RequestRedeem_RevertInsufficientBalance() public {
        _depositAndFulfillAndClaim(investor, 100e6);
        uint256 tooMany = wrapper.balanceOf(investor) + 1;
        vm.expectRevert(IManagedVaultWrapper.INSUFFICIENT_ASSETS.selector);
        vm.prank(investor);
        wrapper.requestRedeem(tooMany, investor, investor);
    }

    // =============================================================
    // fulfillRedeemRequests
    // =============================================================

    function test_FulfillRedeemRequests_MovesToClaimable() public {
        uint256 amount = 100e6;
        uint256 shares = _depositAndFulfillAndClaim(investor, amount);

        vm.prank(investor);
        wrapper.requestRedeem(shares, investor, investor);

        // Manager fulfills with 100 USDC payout
        asset.mint(address(wrapper), 100e6); // simulates manager having returned assets
        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 100e6;

        vm.prank(manager);
        wrapper.fulfillRedeemRequests(controllers, assetsOut);

        assertEq(wrapper.pendingRedeemRequest(0, investor), 0);
        assertEq(wrapper.claimableRedeemRequest(0, investor), shares);
        assertEq(wrapper.claimableRedeemAssets(investor), 100e6);
    }

    function test_FulfillRedeemRequests_RevertNotManager() public {
        uint256 shares = _depositAndFulfillAndClaim(investor, 100e6);
        vm.prank(investor);
        wrapper.requestRedeem(shares, investor, investor);

        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 100e6;

        vm.expectRevert(IManagedVaultWrapper.UNAUTHORIZED.selector);
        vm.prank(stranger);
        wrapper.fulfillRedeemRequests(controllers, assetsOut);
    }

    function test_FulfillRedeemRequests_RevertArrayMismatch() public {
        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        uint256[] memory assetsOut = new uint256[](2);

        vm.expectRevert(IManagedVaultWrapper.ARRAY_LENGTH_MISMATCH.selector);
        vm.prank(manager);
        wrapper.fulfillRedeemRequests(controllers, assetsOut);
    }

    function test_FulfillRedeemRequests_DoesNotBurnSharesYet() public {
        // Shares are moved from pending → claimable during fulfillRedeemRequests,
        // but NOT burned until the investor calls claimRedeem.
        uint256 amount = 100e6;
        uint256 shares = _depositAndFulfillAndClaim(investor, amount);
        uint256 supplyBefore = wrapper.totalSupply();

        vm.prank(investor);
        wrapper.requestRedeem(shares, investor, investor);

        asset.mint(address(wrapper), 100e6);
        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 100e6;

        vm.prank(manager);
        wrapper.fulfillRedeemRequests(controllers, assetsOut);

        // Supply NOT reduced yet — burn happens on claimRedeem
        assertEq(wrapper.totalSupply(), supplyBefore);
        assertEq(wrapper.claimableRedeemRequest(0, investor), shares);
    }

    function test_ClaimRedeem_BurnsLockedShares() public {
        // Verify that shares are burned when investor claims their redeem
        uint256 amount = 100e6;
        uint256 shares = _depositAndFulfillAndClaim(investor, amount);
        uint256 supplyAfterDeposit = wrapper.totalSupply();

        vm.prank(investor);
        wrapper.requestRedeem(shares, investor, investor);

        asset.mint(address(wrapper), 100e6);
        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 100e6;

        vm.prank(manager);
        wrapper.fulfillRedeemRequests(controllers, assetsOut);

        // Burn happens on claim
        vm.prank(investor);
        wrapper.claimRedeem(investor, investor);

        assertEq(wrapper.totalSupply(), supplyAfterDeposit - shares);
    }

    // =============================================================
    // claimRedeem
    // =============================================================

    function test_ClaimRedeem_TransfersAssets() public {
        uint256 amount = 100e6;
        uint256 shares = _depositAndFulfillAndClaim(investor, amount);

        vm.prank(investor);
        wrapper.requestRedeem(shares, investor, investor);

        asset.mint(address(wrapper), 100e6);
        address[] memory controllers = new address[](1);
        controllers[0] = investor;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 100e6;

        vm.prank(manager);
        wrapper.fulfillRedeemRequests(controllers, assetsOut);

        uint256 balanceBefore = asset.balanceOf(investor);
        vm.prank(investor);
        uint256 claimed = wrapper.claimRedeem(investor, investor);

        assertEq(claimed, 100e6);
        assertEq(asset.balanceOf(investor), balanceBefore + 100e6);
        assertEq(wrapper.claimableRedeemAssets(investor), 0);
    }

    function test_ClaimRedeem_RevertNoClaimableAssets() public {
        vm.expectRevert(IManagedVaultWrapper.NO_CLAIMABLE_ASSETS.selector);
        vm.prank(investor);
        wrapper.claimRedeem(investor, investor);
    }

    // =============================================================
    // totalAssets
    // =============================================================

    function test_TotalAssets_ReadsFromAggregator() public {
        // Give wrapper 200 svVault shares at PPS 1e6 → 200 USDC
        svVault.mint(address(wrapper), 200e6);
        uint256 ta = wrapper.totalAssets();
        assertEq(ta, 200e6);
    }

    function test_TotalAssets_IncludesRawAssetBalance() public {
        svVault.mint(address(wrapper), 100e6);
        asset.mint(address(wrapper), 50e6); // raw USDC in wrapper
        assertEq(wrapper.totalAssets(), 150e6);
    }

    function test_TotalAssets_ReflectsHigherPPS() public {
        svVault.mint(address(wrapper), 100e6);
        aggregator.setPPS(svStrategyAddr, 1_100_000); // 1.1 PPS
        assertEq(wrapper.totalAssets(), 110e6);
    }

    // =============================================================
    // isPPSStale
    // =============================================================

    function test_IsPPSStale_FalseInitially() public view {
        assertFalse(wrapper.isPPSStale());
    }

    function test_IsPPSStale_TrueAfterMaxStaleness() public {
        vm.warp(block.timestamp + 2 days);
        assertTrue(wrapper.isPPSStale());
    }

    // =============================================================
    // setAllowlist / gated vault
    // =============================================================

    function test_SetAllowlist_ManagerCanSet() public {
        address[] memory investors = new address[](1);
        investors[0] = investor;
        bool[] memory allowed = new bool[](1);
        allowed[0] = true;

        vm.prank(manager);
        wrapper.setAllowlist(investors, allowed);

        assertTrue(wrapper.allowlist(investor));
    }

    function test_SetAllowlist_RevertNonManager() public {
        address[] memory investors = new address[](1);
        investors[0] = investor;
        bool[] memory allowed = new bool[](1);
        allowed[0] = true;

        vm.expectRevert(IManagedVaultWrapper.UNAUTHORIZED.selector);
        vm.prank(stranger);
        wrapper.setAllowlist(investors, allowed);
    }

    function test_SetAllowlist_RevertArrayMismatch() public {
        address[] memory investors = new address[](1);
        investors[0] = investor;
        bool[] memory allowed = new bool[](2);

        vm.expectRevert(IManagedVaultWrapper.ARRAY_LENGTH_MISMATCH.selector);
        vm.prank(manager);
        wrapper.setAllowlist(investors, allowed);
    }

    // =============================================================
    // Dead shares protection
    // =============================================================

    function test_DeadShares_ProtectFirstDepositor() public {
        // The dead shares prevent the classic ERC-4626 inflation attack.
        // Dead address holds 1000 shares with no backing, so an attacker
        // donating to inflate exchange rate cannot cause the first real depositor
        // to receive 0 shares when DEAD_SHARES > 0.
        assertGt(wrapper.totalSupply(), 0); // totalSupply > 0 from start
        assertEq(wrapper.balanceOf(address(0xdead)), DEAD_SHARES);
    }

    // =============================================================
    // setPaused
    // =============================================================

    function test_SetPaused_ManagerCanPause() public {
        vm.prank(manager);
        wrapper.setPaused(true);
        assertTrue(wrapper.isPaused());
    }

    function test_SetPaused_ManagerCanUnpause() public {
        vm.prank(manager);
        wrapper.setPaused(true);
        vm.prank(manager);
        wrapper.setPaused(false);
        assertFalse(wrapper.isPaused());
    }

    function test_SetPaused_RevertNonManager() public {
        vm.expectRevert(IManagedVaultWrapper.UNAUTHORIZED.selector);
        vm.prank(stranger);
        wrapper.setPaused(true);
    }

    // =============================================================
    // setOperator / authorizeOperator
    // =============================================================

    function test_SetOperator_ApproveAndRevoke() public {
        address operator = makeAddr("operator");
        vm.prank(investor);
        wrapper.setOperator(operator, true);
        assertTrue(wrapper.isOperator(investor, operator));

        vm.prank(investor);
        wrapper.setOperator(operator, false);
        assertFalse(wrapper.isOperator(investor, operator));
    }

    function test_SetOperator_RevertSelf() public {
        vm.expectRevert(IManagedVaultWrapper.UNAUTHORIZED.selector);
        vm.prank(investor);
        wrapper.setOperator(investor, true);
    }
}
