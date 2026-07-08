// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultController } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";

/// @notice Property-based fuzz tests for the fixed-point NAV / share / fee math, where dust and rounding
///         bugs hide. Everything rounds in the protocol's favour and stays within advertised bounds.
contract ManagedSuperVaultFuzzTest is ManagedSuperVaultTestBase {
    uint256 internal constant WAD = 1e18;

    /// @notice Deposit share pricing: shares are floor(assetsNet * PRECISION / pps) and never over-mint
    ///         relative to the assets paid in (round-trip value cannot exceed principal).
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_depositSharePricing(uint256 assets, uint256 pps) public {
        // Keep the NAV move within the 50% deviation bound so it finalizes in one step
        pps = bound(pps, 0.51e18, 1.49e18);
        assets = bound(assets, 1e12, 1e30);

        _updateNAV(pps);
        assertEq(aggregator.getPPS(address(controller)), pps);

        asset.mint(user, assets);
        vm.startPrank(user);
        asset.approve(address(vault), assets);
        vault.requestDeposit(assets, user, user);
        vm.stopPrank();

        address[] memory d = new address[](1);
        d[0] = user;
        vm.prank(manager);
        controller.fulfillDepositRequests(d);

        // No management fee on the default vault, so net == gross
        uint256 claimable = controller.claimableDepositRequest(user);
        assertEq(claimable, assets);

        vm.prank(user);
        uint256 shares = vault.deposit(claimable, user, user);

        // Exact pricing and no value creation via rounding
        assertEq(shares, Math_mulDivFloor(assets, WAD, pps));
        assertLe(vault.convertToAssets(shares), assets);
    }

    /// @notice Redeem pricing: fulfilling at the theoretical amount pays out floor(shares * pps / PRECISION)
    ///         and never more than the shares are worth at the current NAV.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_redeemPricing(uint256 depositAssets, uint256 pps) public {
        pps = bound(pps, 0.51e18, 1.49e18);
        depositAssets = bound(depositAssets, 1e15, 1e28);

        asset.mint(user, depositAssets); // ensure balance for large fuzzed principals
        uint256 shares = _depositRoundTrip(user, depositAssets); // priced at PPS 1.0

        _updateNAV(pps);

        // Fund the controller so redemption at the new NAV is solvent (offchain gain returned)
        uint256 owed = Math_mulDivFloor(shares, pps, WAD);
        if (owed > depositAssets) asset.mint(address(controller), owed - depositAssets);

        vm.prank(user);
        vault.requestRedeem(shares, user, user);
        (, uint256 theoretical,) = controller.previewExactRedeem(user);
        assertEq(theoretical, Math_mulDivFloor(shares, pps, WAD));

        address[] memory c = new address[](1);
        c[0] = user;
        uint256[] memory a = new uint256[](1);
        a[0] = theoretical;
        vm.prank(manager);
        controller.fulfillRedeemRequests(c, a);

        uint256 before = asset.balanceOf(user);
        uint256 claimable = vault.maxWithdraw(user);
        vm.prank(user);
        vault.withdraw(claimable, user, user);
        assertEq(asset.balanceOf(user) - before, theoretical);
    }

    /// @notice A performance-fee skim always reduces PPS, stays within the MAX_PERFORMANCE_FEE deduction
    ///         bound, and never crosses below the high-water mark it started from.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_skimBounded(uint256 perfFeeBps, uint256 growthBps) public {
        perfFeeBps = bound(perfFeeBps, 1, 5100); // (0, MAX_PERFORMANCE_FEE]
        growthBps = bound(growthBps, 1, 4900); // NAV growth within the deviation bound

        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.feeConfig.performanceFeeBps = perfFeeBps;
        (address vault_, address controller_,) = _createManagedVault(params);
        ManagedSuperVault v = ManagedSuperVault(vault_);
        ManagedSuperVaultController c = ManagedSuperVaultController(payable(controller_));

        // Seed the vault
        _depositRoundTripOn(v, c, user, 1_000_000e18);

        uint256 newPPS = WAD + (WAD * growthBps) / 10_000;
        _updateNAVOn(c, newPPS);
        uint256 ppsBeforeSkim = c.getStoredPPS();

        vm.prank(manager);
        c.skimPerformanceFee();

        uint256 ppsAfter = c.getStoredPPS();
        // PPS strictly decreases (or is unchanged if the fee rounded to zero), never increases
        assertLe(ppsAfter, ppsBeforeSkim);
        // The deduction can never exceed the MAX_PERFORMANCE_FEE bound of the pre-skim PPS
        uint256 minAllowed = Math_mulDivCeil(ppsBeforeSkim, 10_000 - 5100, 10_000);
        assertGe(ppsAfter, minAllowed);
        // HWM tracks the new PPS
        assertEq(c.vaultHwmPps(), ppsAfter);
    }

    /// @notice Deviation classification: a proposal within the bound finalizes and stores; one beyond the
    ///         bound is dropped (value not stored) and the vault auto-pauses into review.
    /// forge-config: default.fuzz.runs = 256
    function testFuzz_deviationClassification(uint256 pps) public {
        pps = bound(pps, 0.01e18, 3e18);
        uint256 base = aggregator.getPPS(address(controller)); // 1.0
        uint256 absDiff = pps > base ? pps - base : base - pps;
        bool withinBound = Math_mulDivFloor(absDiff, 1e18, base) <= 5e17; // 50%

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 id = aggregator.proposeNAVUpdate(address(controller), pps, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(controller), id);

        if (withinBound) {
            assertEq(aggregator.getPPS(address(controller)), pps);
            assertFalse(aggregator.isManagedVaultPaused(address(controller)));
        } else {
            assertEq(aggregator.getPPS(address(controller)), base); // value dropped
            assertTrue(aggregator.isManagedVaultPaused(address(controller)));
            assertEq(
                uint8(aggregator.getNAVProposal(address(controller), id).status),
                uint8(IManagedSuperVaultController.NAVProposalStatus.ReviewRequired)
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    function _depositRoundTripOn(
        ManagedSuperVault v,
        ManagedSuperVaultController c,
        address who,
        uint256 amount
    )
        internal
    {
        asset.mint(who, amount);
        vm.startPrank(who);
        asset.approve(address(v), amount);
        v.requestDeposit(amount, who, who);
        vm.stopPrank();
        address[] memory d = new address[](1);
        d[0] = who;
        vm.prank(manager);
        c.fulfillDepositRequests(d);
        uint256 claimable = c.claimableDepositRequest(who);
        vm.prank(who);
        v.deposit(claimable, who, who);
    }

    function _updateNAVOn(ManagedSuperVaultController c, uint256 newPPS) internal {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 id = aggregator.proposeNAVUpdate(address(c), newPPS, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(c), id);
    }

    function Math_mulDivFloor(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y) / d;
    }

    function Math_mulDivCeil(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        return (x * y + d - 1) / d;
    }
}
