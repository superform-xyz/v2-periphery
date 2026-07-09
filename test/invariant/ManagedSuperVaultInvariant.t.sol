// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultStrategy } from "../../src/ManagedSuperVault/ManagedSuperVaultStrategy.sol";
import { ManagedSuperVaultDepositQueue } from "../../src/ManagedSuperVault/ManagedSuperVaultDepositQueue.sol";
import { ManagedNAVOracle } from "../../src/ManagedSuperVault/ManagedNAVOracle.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @notice Drives random deposit-queue lifecycle sequences (plus native redeems and bounded NAV
///         pushes) across a fixed actor set to pin the reuse architecture's custody accounting:
///         the QUEUE holds exactly the pending deposit assets and the pre-minted claimable shares,
///         while fulfilled assets sit in the strategy and share supply is fully attributed.
contract Handler is Test {
    ManagedSuperVault internal vault;
    ManagedSuperVaultStrategy internal strategy;
    ManagedSuperVaultDepositQueue internal queue;
    ManagedNAVOracle internal navOracle;
    MockERC20 internal asset;
    address internal manager;
    address internal attestor;
    uint256 internal minUpdateInterval;
    bytes32 internal constant EVIDENCE_HASH = keccak256("nav-evidence");

    address[] internal actors; // sorted ascending (fulfillRedeemRequests requires sorted, unique)

    constructor(
        ManagedSuperVault vault_,
        ManagedSuperVaultStrategy strategy_,
        ManagedSuperVaultDepositQueue queue_,
        ManagedNAVOracle navOracle_,
        MockERC20 asset_,
        address manager_,
        address attestor_,
        uint256 minUpdateInterval_,
        address[] memory actors_
    ) {
        vault = vault_;
        strategy = strategy_;
        queue = queue_;
        navOracle = navOracle_;
        asset = asset_;
        manager = manager_;
        attestor = attestor_;
        minUpdateInterval = minUpdateInterval_;
        actors = actors_;
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT QUEUE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function requestDeposit(uint256 seed, uint256 amount) external {
        address a = _actor(seed);
        amount = bound(amount, 1e6, 1e22);
        asset.mint(a, amount);
        vm.startPrank(a);
        asset.approve(address(queue), amount);
        queue.requestDeposit(amount, a, a);
        vm.stopPrank();
    }

    function cancelDeposit(uint256 seed) external {
        address a = _actor(seed);
        if (queue.pendingDepositRequest(0, a) == 0) return;
        vm.prank(a);
        queue.cancelDepositRequest(0, a);
    }

    function rejectDeposit(uint256 seed) external {
        address a = _actor(seed);
        if (queue.pendingDepositRequest(0, a) == 0) return;
        address[] memory one = new address[](1);
        one[0] = a;
        vm.prank(manager);
        queue.rejectDepositRequests(one, "reject");
    }

    function fulfillDeposits() external {
        address[] memory pending = _actorsWithPendingDeposit();
        if (pending.length == 0) return;
        vm.prank(manager);
        queue.fulfillDepositRequests(pending);
    }

    /// @notice Claim through the assets leg (queue.deposit), sometimes partially
    function claimDepositAsDeposit(uint256 seed, uint256 fractionSeed) external {
        address a = _actor(seed);
        uint256 claimableAssets = queue.claimableDepositRequest(0, a);
        if (claimableAssets == 0) return;
        uint256 assets = bound(fractionSeed, 1, claimableAssets);
        // Skip dust claims that would round to zero shares (queue reverts INVALID_AMOUNT)
        uint256 claimableShares = queue.maxMint(a);
        if (claimableShares * assets / claimableAssets == 0) return;
        vm.prank(a);
        queue.deposit(assets, a, a);
    }

    /// @notice Claim through the shares leg (queue.mint), sometimes partially
    function claimDepositAsMint(uint256 seed, uint256 fractionSeed) external {
        address a = _actor(seed);
        uint256 claimableShares = queue.maxMint(a);
        if (claimableShares == 0) return;
        uint256 shares = bound(fractionSeed, 1, claimableShares);
        vm.prank(a);
        queue.mint(shares, a, a);
    }

    /*//////////////////////////////////////////////////////////////
                        NATIVE REDEEM OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function requestRedeem(uint256 seed, uint256 shareSeed) external {
        address a = _actor(seed);
        uint256 bal = vault.balanceOf(a);
        if (bal == 0) return;
        if (strategy.pendingCancelRedeemRequest(a)) return;
        uint256 shares = bound(shareSeed, 1, bal);
        vm.prank(a);
        vault.requestRedeem(shares, a, a);
    }

    function fulfillRedeems() external {
        // Actors are pre-sorted; collect fulfillable requests in order (stays sorted/unique).
        // Skip controllers whose slippage floor exceeds today's theoretical value (PPS moved
        // down more than their tolerance) — a real manager would wait, not revert the batch.
        uint256 n;
        uint256 totalNeeded;
        for (uint256 i; i < actors.length; ++i) {
            (uint256 shares, uint256 theoretical, uint256 minAssets) = strategy.previewExactRedeem(actors[i]);
            if (shares == 0 || theoretical < minAssets) continue;
            n++;
            totalNeeded += theoretical;
        }
        if (n == 0) return;

        address[] memory cs = new address[](n);
        uint256[] memory amts = new uint256[](n);
        uint256 j;
        for (uint256 i; i < actors.length; ++i) {
            (uint256 shares, uint256 theoretical, uint256 minAssets) = strategy.previewExactRedeem(actors[i]);
            if (shares == 0 || theoretical < minAssets) continue;
            cs[j] = actors[i];
            amts[j] = theoretical;
            j++;
        }

        // Realize any NAV appreciation into the strategy so fulfillment is solvent (the attested
        // NAV models offchain gains; strategy balance is not part of any invariant here)
        uint256 balance = asset.balanceOf(address(strategy));
        if (balance < totalNeeded) {
            asset.mint(address(strategy), totalNeeded - balance);
        }

        vm.prank(manager);
        strategy.fulfillRedeemRequests(cs, amts);
    }

    function claimRedeem(uint256 seed) external {
        address a = _actor(seed);
        uint256 claimable = vault.maxWithdraw(a);
        if (claimable == 0) return;
        vm.prank(a);
        vault.withdraw(claimable, a, a);
    }

    /*//////////////////////////////////////////////////////////////
                            NAV OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Push an attested NAV within the deviation bound (multiplicative step in
    ///         [-4%, +4%], clamped to [0.5, 2.0]) through propose + attest on the oracle
    function pushNAV(uint256 stepSeed) external {
        uint256 current = strategy.getStoredPPS();
        uint256 stepBps = bound(stepSeed, 9600, 10_400); // x0.96 .. x1.04
        uint256 newPPS = current * stepBps / 10_000;
        if (newPPS < 0.5e18) newPPS = 0.5e18;
        if (newPPS > 2e18) newPPS = 2e18;
        if (newPPS == current && stepBps != 10_000) return; // clamped into a no-op

        vm.warp(block.timestamp + minUpdateInterval + 1);

        vm.prank(manager);
        uint256 id = navOracle.proposeNAVUpdate(address(strategy), newPPS, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), id);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    function _actorsWithPendingDeposit() internal view returns (address[] memory) {
        uint256 n;
        for (uint256 i; i < actors.length; ++i) {
            if (queue.pendingDepositRequest(0, actors[i]) != 0) n++;
        }
        address[] memory out = new address[](n);
        uint256 j;
        for (uint256 i; i < actors.length; ++i) {
            if (queue.pendingDepositRequest(0, actors[i]) != 0) out[j++] = actors[i];
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

        handler = new Handler(
            vault, strategy, queue, navOracle, asset, manager, attestor, MIN_UPDATE_INTERVAL, actors
        );
        targetContract(address(handler));
    }

    /// @notice The queue holds EXACTLY the pending deposit assets: fulfilled (claimable) assets
    ///         move to the strategy at fulfillment, cancellations/rejections refund immediately.
    function invariant_queueHoldsExactlyPendingAssets() public view {
        assertEq(asset.balanceOf(address(queue)), queue.totalPendingDepositAssets());
    }

    /// @notice The queue's vault-share balance backs every claimable share; with only tracked
    ///         actors interacting this is an exact equality.
    function invariant_queueSharesBackClaimable() public view {
        uint256 sumClaimableShares;
        for (uint256 i; i < actors.length; ++i) {
            sumClaimableShares += queue.maxMint(actors[i]);
        }
        uint256 queueShareBal = IERC20(address(vault)).balanceOf(address(queue));
        assertGe(queueShareBal, sumClaimableShares, "queue shares under-back claimables");
        assertEq(queueShareBal, sumClaimableShares, "exact with only tracked actors");
    }

    /// @notice The queue's aggregate pending counter always equals the sum of per-actor pendings.
    function invariant_totalPendingMatchesSum() public view {
        uint256 sum;
        for (uint256 i; i < actors.length; ++i) {
            sum += queue.pendingDepositRequest(0, actors[i]);
        }
        assertEq(queue.totalPendingDepositAssets(), sum);
    }

    /// @notice Share supply is fully attributed: every minted share is either still custodied by
    ///         the queue (unclaimed), held by an actor, or escrowed pending redemption.
    function invariant_totalSupplyFullyAttributed() public view {
        uint256 attributed = IERC20(address(vault)).balanceOf(address(queue))
            + IERC20(address(vault)).balanceOf(address(escrow));
        for (uint256 i; i < actors.length; ++i) {
            attributed += IERC20(address(vault)).balanceOf(actors[i]);
        }
        assertEq(vault.totalSupply(), attributed);
    }

    /// @notice PPS is always positive (the rails reject zero and auto-pause instead of storing).
    function invariant_ppsPositive() public view {
        assertGt(aggregator.getPPS(address(strategy)), 0);
    }
}
