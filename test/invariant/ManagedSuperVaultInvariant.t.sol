// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { ManagedSuperVaultAggregator } from "../../src/ManagedSuperVault/ManagedSuperVaultAggregator.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @notice Drives random deposit/redeem lifecycle sequences across a fixed actor set. NAV is held at 1.0
///         so the invariants isolate the escrow-custody and deposit accounting (the novel surface); NAV
///         and fee fixed-point math are covered by the fuzz suite.
contract Handler is Test {
    ManagedSuperVault internal vault;
    ManagedSuperVaultController internal controller;
    address internal escrow;
    MockERC20 internal asset;
    address internal manager;
    address[] internal actors; // sorted ascending (fulfillRedeemRequests requires sorted, unique)

    constructor(
        ManagedSuperVault vault_,
        ManagedSuperVaultController controller_,
        address escrow_,
        MockERC20 asset_,
        address manager_,
        address[] memory actors_
    ) {
        vault = vault_;
        controller = controller_;
        escrow = escrow_;
        asset = asset_;
        manager = manager_;
        actors = actors_;
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function requestDeposit(uint256 seed, uint256 amount) external {
        address a = _actor(seed);
        amount = bound(amount, 1e6, 1e22);
        asset.mint(a, amount);
        vm.startPrank(a);
        asset.approve(address(vault), amount);
        vault.requestDeposit(amount, a, a);
        vm.stopPrank();
    }

    function cancelDeposit(uint256 seed) external {
        address a = _actor(seed);
        if (controller.pendingDepositRequest(a) == 0) return;
        vm.prank(a);
        vault.cancelDepositRequest(0, a);
    }

    function rejectDeposit(uint256 seed) external {
        address a = _actor(seed);
        if (controller.pendingDepositRequest(a) == 0) return;
        address[] memory one = new address[](1);
        one[0] = a;
        vm.prank(manager);
        controller.rejectDepositRequests(one, "reject");
    }

    function fulfillDeposits() external {
        address[] memory pending = _actorsWith(true);
        if (pending.length == 0) return;
        vm.prank(manager);
        controller.fulfillDepositRequests(pending);
    }

    function claimDeposit(uint256 seed) external {
        address a = _actor(seed);
        uint256 claimable = controller.claimableDepositRequest(a);
        if (claimable == 0) return;
        vm.prank(a);
        vault.deposit(claimable, a, a);
    }

    function requestRedeem(uint256 seed, uint256 shareSeed) external {
        address a = _actor(seed);
        uint256 bal = vault.balanceOf(a);
        if (bal == 0 || controller.pendingRedeemRequest(a) != 0) return;
        if (controller.pendingCancelRedeemRequest(a)) return;
        uint256 shares = bound(shareSeed, 1, bal);
        vm.prank(a);
        vault.requestRedeem(shares, a, a);
    }

    function fulfillRedeem() external {
        // actors are pre-sorted; collect those with a pending redeem in-order (stays sorted/unique)
        uint256 n;
        for (uint256 i; i < actors.length; ++i) {
            if (controller.pendingRedeemRequest(actors[i]) != 0) n++;
        }
        if (n == 0) return;
        address[] memory cs = new address[](n);
        uint256[] memory amts = new uint256[](n);
        uint256 j;
        for (uint256 i; i < actors.length; ++i) {
            uint256 pending = controller.pendingRedeemRequest(actors[i]);
            if (pending == 0) continue;
            (, uint256 theoretical,) = controller.previewExactRedeem(actors[i]);
            cs[j] = actors[i];
            amts[j] = theoretical; // PPS is 1.0, so this is within the slippage band
            j++;
        }
        vm.prank(manager);
        controller.fulfillRedeemRequests(cs, amts);
    }

    function claimRedeem(uint256 seed) external {
        address a = _actor(seed);
        uint256 claimable = vault.maxWithdraw(a);
        if (claimable == 0) return;
        vm.prank(a);
        vault.withdraw(claimable, a, a);
    }

    function _actorsWith(bool pendingDeposit) internal view returns (address[] memory) {
        uint256 n;
        for (uint256 i; i < actors.length; ++i) {
            if ((controller.pendingDepositRequest(actors[i]) != 0) == pendingDeposit) n++;
        }
        address[] memory out = new address[](n);
        uint256 j;
        for (uint256 i; i < actors.length; ++i) {
            if ((controller.pendingDepositRequest(actors[i]) != 0) == pendingDeposit) out[j++] = actors[i];
        }
        return out;
    }

    function allActors() external view returns (address[] memory) {
        return actors;
    }
}

contract ManagedSuperVaultInvariantTest is ManagedSuperVaultTestBase {
    Handler internal handler;
    address[] internal actors;

    function setUp() public override {
        super.setUp();

        // Four fixed actors, sorted ascending for the sorted-unique fulfill requirement
        address[] memory raw = new address[](4);
        raw[0] = makeAddr("actorA");
        raw[1] = makeAddr("actorB");
        raw[2] = makeAddr("actorC");
        raw[3] = makeAddr("actorD");
        for (uint256 i; i < raw.length; ++i) {
            for (uint256 k = i + 1; k < raw.length; ++k) {
                if (raw[k] < raw[i]) (raw[i], raw[k]) = (raw[k], raw[i]);
            }
        }
        actors = raw;

        handler = new Handler(vault, controller, address(escrow), asset, manager, actors);
        targetContract(address(handler));
    }

    /// @notice The controller's totalPendingDepositAssets always equals the sum of per-actor pending.
    function invariant_totalPendingMatchesSum() public view {
        uint256 sum;
        for (uint256 i; i < actors.length; ++i) {
            sum += controller.pendingDepositRequest(actors[i]);
        }
        assertEq(controller.totalPendingDepositAssets(), sum);
    }

    /// @notice The escrow always holds at least its obligations: every pending deposit and every
    ///         fulfilled-but-unclaimed redemption is backed by real assets in escrow.
    function invariant_escrowSolvency() public view {
        uint256 obligations = controller.totalPendingDepositAssets();
        for (uint256 i; i < actors.length; ++i) {
            obligations += controller.claimableWithdraw(actors[i]);
        }
        assertGe(asset.balanceOf(address(escrow)), obligations);
    }

    /// @notice Redemption claims can never dip into pending-deposit custody.
    function invariant_redeemableExcludesPendingDeposits() public view {
        uint256 escrowBal = asset.balanceOf(address(escrow));
        assertGe(escrowBal, controller.totalPendingDepositAssets());
    }

    /// @notice PPS is always positive.
    function invariant_ppsPositive() public view {
        assertGt(aggregator.getPPS(address(controller)), 0);
    }
}
