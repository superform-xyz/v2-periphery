// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultStrategy } from "../../src/ManagedSuperVault/ManagedSuperVaultStrategy.sol";
import { ManagedSuperVaultDepositQueue } from "../../src/ManagedSuperVault/ManagedSuperVaultDepositQueue.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { IManagedNAVOracle } from "../../src/interfaces/ManagedSuperVault/IManagedNAVOracle.sol";
import {
    IManagedSuperVaultAggregator
} from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";

/// @notice Property-based fuzz tests for the fixed-point NAV / share / fee math, where dust and
///         rounding bugs hide. Ported from the old managed-family fuzz suite to the reuse
///         architecture: NAV flows through navOracle.proposeNAVUpdate/attestNAVUpdate (keyed by
///         the strategy) with the aggregator's _forwardPPS rails deciding acceptance — rail
///         rejections surface as a Rejected proposal status (plus auto-pause), while propose-time
///         prechecks (INVALID_TIMESTAMP etc.) revert.
contract ManagedSuperVaultFuzzTest is ManagedSuperVaultTestBase {
    uint256 internal constant WAD = 1e18;

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT / REDEEM ROUND-TRIP PRICING
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit share pricing at a fuzzed PPS within the deviation bound: the async
    ///         request -> fulfill -> claim round trip mints exactly floor(net * 1e18 / pps) shares
    ///         (net == gross with no management fee) and never over-mints relative to the assets
    ///         paid in (round-trip value cannot exceed principal).
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_depositSharePricing(uint256 assets, uint256 pps) public {
        // Keep the NAV move within the 50% deviation bound so it finalizes in one step
        pps = bound(pps, 0.51e18, 1.49e18);
        assets = bound(assets, 1e12, 1e30);

        _pushNAV(pps);
        assertEq(aggregator.getPPS(address(strategy)), pps);

        asset.mint(user, assets);
        vm.startPrank(user);
        asset.approve(address(queue), assets);
        queue.requestDeposit(assets, user, user);
        vm.stopPrank();

        address[] memory d = new address[](1);
        d[0] = user;
        vm.prank(manager);
        queue.fulfillDepositRequests(d);

        // No management fee on the default vault, so net == gross
        uint256 claimable = queue.claimableDepositRequest(0, user);
        assertEq(claimable, assets);

        vm.prank(user);
        uint256 shares = queue.deposit(claimable, user, user);

        // Conservation: exact pricing and no value creation via rounding
        assertEq(shares, Math_mulDivFloor(assets, WAD, pps), "shares == floor(net * 1e18 / pps)");
        assertEq(vault.balanceOf(user), shares, "native shares delivered");
        assertLe(vault.convertToAssets(shares), assets, "no value creation via rounding");
    }

    /// @notice Redeem pricing: after a NAV move, fulfilling at the theoretical amount pays out
    ///         exactly floor(shares * pps / 1e18) — proportional to the shares redeemed and never
    ///         more than they are worth at the current NAV.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_redeemRoundTrip(uint256 depositAssets, uint256 pps) public {
        pps = bound(pps, 0.51e18, 1.49e18);
        depositAssets = bound(depositAssets, 1e15, 1e28);

        asset.mint(user, depositAssets); // ensure balance for large fuzzed principals
        uint256 shares = _requestFulfillClaim(user, depositAssets); // priced at PPS 1.0
        assertEq(shares, depositAssets);

        _pushNAV(pps);

        // Fund the strategy so redemption at the new NAV is solvent (offchain gain realized);
        // deposits already sit in the strategy from fulfillment
        uint256 owed = Math_mulDivFloor(shares, pps, WAD);
        if (owed > depositAssets) asset.mint(address(strategy), owed - depositAssets);

        vm.prank(user);
        vault.requestRedeem(shares, user, user);
        (, uint256 theoretical,) = strategy.previewExactRedeem(user);
        assertEq(theoretical, owed, "theoretical == floor(shares * pps / 1e18)");

        address[] memory c = new address[](1);
        c[0] = user;
        uint256[] memory a = new uint256[](1);
        a[0] = theoretical;
        vm.prank(manager);
        strategy.fulfillRedeemRequests(c, a);

        uint256 before = asset.balanceOf(user);
        uint256 claimable = vault.maxWithdraw(user);
        vm.prank(user);
        vault.withdraw(claimable, user, user);
        assertEq(asset.balanceOf(user) - before, theoretical, "round trip returns proportional assets");
    }

    /*//////////////////////////////////////////////////////////////
                        PERFORMANCE FEE SKIM
    //////////////////////////////////////////////////////////////*/

    /// @notice A performance-fee skim always reduces PPS, stays within the MAX_PERFORMANCE_FEE
    ///         deduction bound, and ratchets the high-water mark to the post-fee PPS.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_skimBounded(uint256 perfFeeBps, uint256 growthBps) public {
        perfFeeBps = bound(perfFeeBps, 1, 5100); // (0, MAX_PERFORMANCE_FEE]
        growthBps = bound(growthBps, 1, 4900); // NAV growth within the deviation bound

        // Fresh vault with the fuzzed performance fee; point the inherited handles at it so the
        // base helpers (_pushNAV, _requestFulfillClaim) drive the new quartet
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();
        params.feeConfig.performanceFeeBps = perfFeeBps;
        (address vault_, address strategy_, address escrow_, address queue_) = _createManagedVault(params);
        vault = ManagedSuperVault(vault_);
        strategy = ManagedSuperVaultStrategy(payable(strategy_));
        escrow = SuperVaultEscrow(escrow_);
        queue = ManagedSuperVaultDepositQueue(queue_);

        // Seed the vault
        _requestFulfillClaim(user, 1_000_000e18);

        uint256 newPPS = WAD + (WAD * growthBps) / 10_000;
        _pushNAV(newPPS);
        uint256 ppsBeforeSkim = strategy.getStoredPPS();
        assertEq(ppsBeforeSkim, newPPS);

        vm.prank(manager);
        strategy.skimPerformanceFee();

        uint256 ppsAfter = strategy.getStoredPPS();
        // PPS strictly decreases (or is unchanged if the fee rounded to zero), never increases
        assertLe(ppsAfter, ppsBeforeSkim);
        // The deduction can never exceed the MAX_PERFORMANCE_FEE bound of the pre-skim PPS
        uint256 minAllowed = Math_mulDivCeil(ppsBeforeSkim, 10_000 - 5100, 10_000);
        assertGe(ppsAfter, minAllowed);
        // HWM tracks the new PPS
        assertEq(strategy.vaultHwmPps(), ppsAfter);
    }

    /*//////////////////////////////////////////////////////////////
                    NAV RAILS: DEVIATION + TIMESTAMPS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deviation classification through the attestation lifecycle: a proposal within the
    ///         50% bound finalizes and stores; one beyond the bound is dropped by the aggregator's
    ///         rails (value not stored), terminates as Rejected on the oracle, and auto-pauses the
    ///         strategy with PPS marked stale.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_deviationClassification(uint256 pps) public {
        pps = bound(pps, 0.01e18, 3e18);
        uint256 base = aggregator.getPPS(address(strategy)); // 1.0
        uint256 absDiff = pps > base ? pps - base : base - pps;
        bool withinBound = Math_mulDivFloor(absDiff, WAD, base) <= 5e17; // 50%

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 id = navOracle.proposeNAVUpdate(address(strategy), pps, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), id);

        if (withinBound) {
            assertEq(aggregator.getPPS(address(strategy)), pps, "value stored");
            assertFalse(aggregator.isStrategyPaused(address(strategy)), "no pause");
            assertEq(
                uint8(navOracle.getNAVProposal(address(strategy), id).status),
                uint8(IManagedNAVOracle.NAVProposalStatus.Finalized)
            );
        } else {
            assertEq(aggregator.getPPS(address(strategy)), base, "value dropped");
            assertTrue(aggregator.isStrategyPaused(address(strategy)), "auto-paused");
            assertTrue(aggregator.isPPSStale(address(strategy)), "PPS marked stale");
            assertEq(
                uint8(navOracle.getNAVProposal(address(strategy), id).status),
                uint8(IManagedNAVOracle.NAVProposalStatus.Rejected)
            );
        }
        // Either way the proposal terminated: no active proposal remains
        assertEq(navOracle.getActiveNAVProposalId(address(strategy)), 0);
    }

    /// @notice Monotonicity precheck: after a successful push at timestamp T, proposing with any
    ///         effectiveTimestamp <= T (or in the future, or violating the rate limit) REVERTS at
    ///         propose time with INVALID_TIMESTAMP — doomed proposals never collect attestations.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_proposeTimestampPrechecks(uint256 pps, uint256 staleOffset) public {
        pps = bound(pps, 0.51e18, 1.49e18);
        _pushNAV(pps);
        uint256 lastUpdate = aggregator.getLastUpdateTimestamp(address(strategy));
        assertEq(lastUpdate, block.timestamp);

        // Move forward enough that the rate limit is not the binding constraint
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 100);

        // 1. Any timestamp at or before the last accepted update is rejected (monotonicity)
        uint256 staleTs = lastUpdate - bound(staleOffset, 0, lastUpdate - 1);
        vm.prank(manager);
        vm.expectRevert(IManagedNAVOracle.INVALID_TIMESTAMP.selector);
        navOracle.proposeNAVUpdate(address(strategy), pps, staleTs, EVIDENCE_HASH, "");

        // 2. Future timestamps are rejected
        vm.prank(manager);
        vm.expectRevert(IManagedNAVOracle.INVALID_TIMESTAMP.selector);
        navOracle.proposeNAVUpdate(address(strategy), pps, block.timestamp + 1, EVIDENCE_HASH, "");

        // 3. Rate limit: a timestamp within minUpdateInterval of the last update is rejected
        vm.prank(manager);
        vm.expectRevert(IManagedNAVOracle.INVALID_TIMESTAMP.selector);
        navOracle.proposeNAVUpdate(
            address(strategy), pps, lastUpdate + MIN_UPDATE_INTERVAL - 1, EVIDENCE_HASH, ""
        );

        // A valid now-timestamped proposal still goes through
        vm.prank(manager);
        uint256 id = navOracle.proposeNAVUpdate(address(strategy), pps, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy), id);
        assertEq(
            uint8(navOracle.getNAVProposal(address(strategy), id).status),
            uint8(IManagedNAVOracle.NAVProposalStatus.Finalized)
        );
    }

    /// @notice Stored PPS is monotone in acceptance: a finalized proposal always moves
    ///         lastUpdateTimestamp strictly forward, and consecutive accepted updates keep PPS
    ///         positive and within the deviation corridor of their predecessor.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_navAcceptanceMonotonic(uint256 pps1, uint256 pps2) public {
        pps1 = bound(pps1, 0.51e18, 1.49e18);
        // Second update within 50% of the first so both finalize
        pps2 = bound(pps2, Math_mulDivCeil(pps1, 51, 100), Math_mulDivFloor(pps1, 149, 100));

        uint256 ts0 = aggregator.getLastUpdateTimestamp(address(strategy));
        _pushNAV(pps1);
        uint256 ts1 = aggregator.getLastUpdateTimestamp(address(strategy));
        assertGt(ts1, ts0, "accepted update moves the clock forward");
        assertEq(aggregator.getPPS(address(strategy)), pps1);

        _pushNAV(pps2);
        uint256 ts2 = aggregator.getLastUpdateTimestamp(address(strategy));
        assertGt(ts2, ts1, "strictly increasing timestamps");
        assertEq(aggregator.getPPS(address(strategy)), pps2);
        assertGt(aggregator.getPPS(address(strategy)), 0, "PPS always positive");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    function Math_mulDivFloor(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y) / d;
    }

    function Math_mulDivCeil(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y + d - 1) / d;
    }
}
