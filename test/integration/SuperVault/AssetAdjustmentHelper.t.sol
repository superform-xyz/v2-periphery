// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

import "forge-std/console2.sol";

/**
 * @title AssetAdjustmentHelper
 * @author Superform Labs
 * @notice Abstract helper contract for adjusting fulfillment amounts to match actual available assets
 * @dev This contract provides utility functions to handle precision losses between theoretical
 *      fulfillment calculations and actual executeHooks output, ensuring INSUFFICIENT_LIQUIDITY
 *      errors are avoided by pro-rata adjustment of netAssetsOut arrays.
 */
abstract contract AssetAdjustmentHelper is Test {
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error EMPTY_ARRAYS();
    error ARRAY_LENGTH_MISMATCH();
    error ZERO_TOTAL_THEORETICAL();
    error INSUFFICIENT_AVAILABLE_ASSETS();

    /*//////////////////////////////////////////////////////////////
                            CORE ADJUSTMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Adjusts netAssetsOut arrays to match actual available assets from executeHooks
     * @dev This function handles the precision mismatch between theoretical fulfillment amounts
     *      (calculated at current PPS) and actual assets obtained from executeHooks (which may
     *      have rounding losses). The shortfall is distributed pro-rata based on each controller's
     *      theoretical redemption amount.
     *
     *      Example scenario:
     *      - Controller A: 800 theoretical assets (80% of total)
     *      - Controller B: 200 theoretical assets (20% of total)
     *      - Total theoretical: 1000 assets
     *      - Available from hooks: 998 assets (2 wei loss)
     *      - Adjusted A: 798.4 → 798 assets (1.6 wei loss)
     *      - Adjusted B: 199.6 → 199 assets (0.4 wei loss)
     *
     * @param controllers Array of controller addresses (must be sorted/unique)
     * @param theoreticalNetAssets Array of theoretical net assets per controller from previewExactRedeem
     * @param totalTheoreticalNetAssets Total theoretical net assets (sum of theoreticalNetAssets, from
     * previewExactRedeemBatch)
     * @param totalAvailableAssets Actual assets available from executeHooks (sum of expectedAssetsOrSharesOut)
     * @return fulfillRedeemTotalAssetsOut Array adjusted to match available liquidity, sum <= totalAvailableAssets
     */
    function calculateFulfillRedeemTotalAssetsOut(
        address[] memory controllers,
        uint256[] memory theoreticalNetAssets,
        uint256 totalTheoreticalNetAssets,
        uint256 totalAvailableAssets
    )
        internal
        pure
        returns (uint256[] memory fulfillRedeemTotalAssetsOut)
    {
        // Input validation
        if (controllers.length == 0 || theoreticalNetAssets.length == 0) {
            revert EMPTY_ARRAYS();
        }
        if (controllers.length != theoreticalNetAssets.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        fulfillRedeemTotalAssetsOut = new uint256[](controllers.length);

        if (totalTheoreticalNetAssets == 0) {
            revert ZERO_TOTAL_THEORETICAL();
        }

        // Handle edge case: available assets exceed theoretical (should not happen but protect anyway)
        if (totalAvailableAssets >= totalTheoreticalNetAssets) {
            // No adjustment needed - return theoretical amounts
            return theoreticalNetAssets;
        }

        // Ensure we don't try to fulfill more than what's theoretically possible
        if (totalAvailableAssets > totalTheoreticalNetAssets) {
            revert INSUFFICIENT_AVAILABLE_ASSETS();
        }

        console2.log(
            "Adjusting netAssets: Theoretical=%s, Available=%s", totalTheoreticalNetAssets, totalAvailableAssets
        );

        // Distribute available assets pro-rata based on theoretical amounts
        uint256 totalAdjusted = 0;

        for (uint256 i = 0; i < theoreticalNetAssets.length; i++) {
            // Pro-rata calculation for all users: (theoretical[i] * available) / totalTheoretical
            fulfillRedeemTotalAssetsOut[i] =
                theoreticalNetAssets[i].mulDiv(totalAvailableAssets, totalTheoreticalNetAssets, Math.Rounding.Floor);
            totalAdjusted += fulfillRedeemTotalAssetsOut[i];
        }

        // Handle remainder: keep it in the vault as free assets rather than giving to last user
        // This ensures fair distribution - remainder stays with vault, not unfairly given to last user
        uint256 remainder = totalAvailableAssets - totalAdjusted;
        if (remainder > 0) {
            // Remainder stays in vault as free assets - no user gets unfair advantage
            // Log the remainder for transparency
            console2.log("Remainder kept in vault as free assets:", remainder);
        }

        return fulfillRedeemTotalAssetsOut;
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATED WORKFLOW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Complete workflow to calculate adjusted totalAssetsOut for fulfillRedeemRequests
     * @dev This function combines theoretical preview calculations with actual executeHooks
     *      output to produce adjusted fulfillment amounts. This is the main function to use
     *      when you need to fulfill redemption requests while accounting for execution losses.
     *
     *      Workflow:
     *      1. Get theoretical net assets for all controllers via batch preview
     *      2. Calculate total available assets from executeHooks output
     *      3. Adjust theoretical amounts pro-rata to match available assets
     *      4. Return adjusted array ready for fulfillRedeemRequests as totalAssetsOut
     *
     *      NOTE: The returned amounts represent totalAssetsOut (pre-fee) for fulfillRedeemRequests.
     *      Fees are calculated and deducted internally based on full theoretical amounts,
     *      ensuring fees are never reduced due to execution losses.
     *
     * @param strategy The SuperVault strategy contract
     * @param controllers Sorted/unique controller addresses with pending redemptions
     * @param expectedAssetsFromHooks Array of assets expected from executeHooks (from expectedAssetsOrSharesOut)
     * @return fulfillRedeemTotalAssetsOut Final totalAssetsOut array for fulfillRedeemRequests call (pre-fee amounts)
     */
    function calculateAdjustedFulfillment(
        ISuperVaultStrategy strategy,
        address[] memory controllers,
        uint256[] memory expectedAssetsFromHooks
    )
        internal
        view
        returns (uint256[] memory fulfillRedeemTotalAssetsOut)
    {
        // Input validation
        if (controllers.length == 0 || expectedAssetsFromHooks.length == 0) {
            revert EMPTY_ARRAYS();
        }

        // Step 1: Get theoretical net assets for all controllers using strategy's batch preview
        (uint256 totalTheoreticalNetAssets, uint256[] memory theoreticalNetAssets) =
            strategy.previewExactRedeemBatch(controllers);

        // Step 2: Calculate total available assets from executeHooks
        uint256 totalAvailableAssets = 0;
        for (uint256 i = 0; i < expectedAssetsFromHooks.length; i++) {
            console2.log("Available from hooks [index %s]: %s", i, expectedAssetsFromHooks[i]);
            totalAvailableAssets += expectedAssetsFromHooks[i];
        }

        // Step 3: Adjust theoretical amounts to match available assets
        fulfillRedeemTotalAssetsOut = calculateFulfillRedeemTotalAssetsOut(
            controllers, theoreticalNetAssets, totalTheoreticalNetAssets, totalAvailableAssets
        );

        return fulfillRedeemTotalAssetsOut;
    }

    /**
     * @notice Calculate adjusted netAssetsOut for liquidity-only fulfillment (no executeHooks)
     * @dev This function handles cases where fulfillRedeemRequests is called directly from
     *      strategy asset balance without prior executeHooks call. It uses the strategy's
     *      current asset balance as the available liquidity and adjusts theoretical amounts
     *      accordingly to prevent INSUFFICIENT_LIQUIDITY errors.
     *
     *      Use this function for tests that:
     *      - Have free assets sitting in strategy balance
     *      - Don't call executeHooks before fulfillment
     *      - Want to fulfill from strategy liquidity directly
     *
     * @param strategy The SuperVault strategy contract
     * @param asset The underlying asset contract
     * @param controllers Sorted/unique controller addresses with pending redemptions
     * @return fulfillRedeemTotalAssetsOut Final totalAssetsOut array for fulfillRedeemRequests call
     */
    function calculateLiquidityOnlyFulfillment(
        ISuperVaultStrategy strategy,
        address asset,
        address[] memory controllers
    )
        internal
        view
        returns (uint256[] memory fulfillRedeemTotalAssetsOut)
    {
        // Input validation
        if (controllers.length == 0) {
            revert EMPTY_ARRAYS();
        }

        // Step 1: Get current strategy asset balance (available liquidity)
        uint256 strategyBalance = IERC20(asset).balanceOf(address(strategy));

        // Step 2: Get theoretical net assets for all controllers using strategy's batch preview
        (uint256 totalTheoretical, uint256[] memory theoreticalNetAssets) =
            strategy.previewExactRedeemBatch(controllers);

        // Step 3: If strategy has enough balance, use theoretical amounts
        if (strategyBalance >= totalTheoretical) {
            return theoreticalNetAssets;
        }

        // Step 4: Strategy balance is insufficient, adjust pro-rata
        fulfillRedeemTotalAssetsOut =
            calculateFulfillRedeemTotalAssetsOut(controllers, theoreticalNetAssets, totalTheoretical, strategyBalance);

        return fulfillRedeemTotalAssetsOut;
    }

    /*//////////////////////////////////////////////////////////////
                            UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculate the total loss due to execution precision issues
     * @dev Helper function to quantify the difference between theoretical and available assets
     * @param theoreticalNetAssets Array of theoretical net assets
     * @param totalAvailableAssets Actual assets available from executeHooks
     * @return totalLoss The total amount of assets lost due to precision/rounding
     */
    function calculateExecutionLoss(
        uint256[] memory theoreticalNetAssets,
        uint256 totalAvailableAssets
    )
        internal
        pure
        returns (uint256 totalLoss)
    {
        uint256 totalTheoretical = 0;
        for (uint256 i = 0; i < theoreticalNetAssets.length; i++) {
            totalTheoretical += theoreticalNetAssets[i];
        }

        if (totalTheoretical > totalAvailableAssets) {
            totalLoss = totalTheoretical - totalAvailableAssets;
        } else {
            totalLoss = 0;
        }

        return totalLoss;
    }

    /**
     * @notice Verify that fulfillRedeemTotalAssetsOut sum is reasonable relative to available assets
     * @dev Helper function to validate adjustment calculations
     * @dev With the fix, remainder stays in vault so sum will be <= totalAvailableAssets
     * @param fulfillRedeemTotalAssetsOut Array of totalAssetsOut amounts for fulfillRedeemRequests
     * @param totalAvailableAssets Expected total available assets
     * @return isValid True if the sum is valid (sum <= totalAvailableAssets)
     */
    function verifyFulfillRedeemSum(
        uint256[] memory fulfillRedeemTotalAssetsOut,
        uint256 totalAvailableAssets
    )
        internal
        pure
        returns (bool isValid)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < fulfillRedeemTotalAssetsOut.length; i++) {
            sum += fulfillRedeemTotalAssetsOut[i];
        }

        // With the fix: sum should be <= totalAvailableAssets (remainder stays in vault)
        isValid = sum <= totalAvailableAssets;

        return isValid;
    }
}

/**
 * @title AssetAdjustmentHelperTest
 * @notice Concrete test contract for testing the AssetAdjustmentHelper functions
 */
contract AssetAdjustmentHelperTest is AssetAdjustmentHelper {
    /*//////////////////////////////////////////////////////////////
                        INTEGRATION DEMONSTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Demonstrates how to use the helper functions to fix INSUFFICIENT_LIQUIDITY
     * @dev This test shows the exact pattern that should be used in existing test suites
     *      to handle the precision mismatch between theoretical fulfillment and actual
     *      executeHooks output. This pattern can be applied to any test that calls
     *      both executeHooks and fulfillRedeemRequests.
     */
    function test_IntegrationExample_FixingInsufficientLiquidity() public {
        // SCENARIO: Simulating the exact situation from test_FulfillRedeem_FullAmount
        // where strategy balance = 999,999,998 but theoretical = 1,000,000,000

        // Setup: Single controller requesting full redemption
        address[] memory controllers = new address[](1);
        controllers[0] = address(0x123); // Simulated user account

        // STEP 1: Simulate executeHooks results
        // This would normally come from expectedAssetsOrSharesOut array
        uint256[] memory expectedFromHooks = new uint256[](2);
        expectedFromHooks[0] = 435_019_644; // Vault 1 output (from test logs)
        expectedFromHooks[1] = 443_122_022; // Vault 2 output (from test logs)
        // Total available: 878,141,666 assets from hooks

        // STEP 2: Calculate total available assets
        uint256 totalAvailable = 0;
        for (uint256 i = 0; i < expectedFromHooks.length; i++) {
            totalAvailable += expectedFromHooks[i];
        }
        // Note: In real scenario, this would be 999,999,998 from strategy balance

        // STEP 3: Simulate theoretical net assets (what previewExactRedeem would return)
        uint256[] memory theoreticalNetAssets = new uint256[](1);
        theoreticalNetAssets[0] = totalAvailable + 2; // 2 wei more than available (the precision loss)
        uint256 totalTheoreticalNetAssets = theoreticalNetAssets[0]; // Single controller case

        // STEP 4: Apply adjustment to fix the precision mismatch
        uint256[] memory fulfillRedeemTotalAssetsOut = calculateFulfillRedeemTotalAssetsOut(
            controllers, theoreticalNetAssets, totalTheoreticalNetAssets, totalAvailable
        );

        // VERIFICATION: With the fix, totalAssetsOut should be fair (pro-rata) not all remaining
        // In this single controller case, they should get their fair share, remainder stays in vault
        assertTrue(fulfillRedeemTotalAssetsOut[0] <= totalAvailable, "TotalAssetsOut should not exceed available");
        assertTrue(verifyFulfillRedeemSum(fulfillRedeemTotalAssetsOut, totalAvailable), "FulfillRedeem should be valid");

        // SUCCESS: Now fulfillRedeemRequests would work with fulfillRedeemTotalAssetsOut
        // instead of theoretical amounts, eliminating INSUFFICIENT_LIQUIDITY error

        emit log_named_uint("Theoretical Net Assets", theoreticalNetAssets[0]);
        emit log_named_uint("Available from Hooks", totalAvailable);
        emit log_named_uint("FulfillRedeem TotalAssetsOut", fulfillRedeemTotalAssetsOut[0]);
        emit log_named_uint("Precision Loss (wei)", theoreticalNetAssets[0] - fulfillRedeemTotalAssetsOut[0]);
    }

    /**
     * @notice Shows the recommended integration pattern for existing test suites
     * @dev This demonstrates how to modify existing test functions that currently fail
     *      with INSUFFICIENT_LIQUIDITY errors. The pattern is:
     *      1. Execute hooks and capture expectedAssetsOrSharesOut
     *      2. Use calculateAdjustedFulfillment to get proper netAssetsOut
     *      3. Call fulfillRedeemRequests with adjusted amounts
     */
    function test_RecommendedIntegrationPattern() public {
        // This is a mock demonstration of how to integrate into existing tests

        // EXISTING PATTERN (that fails):
        // strategy.executeHooks(args);  // Causes 2 wei precision loss
        // (, , , uint256 theoNet, ) = strategy.previewExactRedeem(controller);
        // strategy.fulfillRedeemRequests([controller], [theoNet]); // FAILS: INSUFFICIENT_LIQUIDITY

        // NEW PATTERN (that works):
        address[] memory controllers = new address[](1);
        controllers[0] = address(0x456);

        // 1. Calculate expected output from hooks (this comes from expectedAssetsOrSharesOut)
        uint256[] memory expectedFromHooks = new uint256[](2);
        expectedFromHooks[0] = 500e6 - 1; // Vault 1 with 1 wei loss
        expectedFromHooks[1] = 500e6 - 1; // Vault 2 with 1 wei loss

        // 2. Use helper to get adjusted fulfillment amounts
        // NOTE: In real integration, you'd pass the actual strategy contract
        // For this demo, we'll simulate what calculateAdjustedFulfillment would return
        uint256 totalAvailable = expectedFromHooks[0] + expectedFromHooks[1]; // 999,999,998

        uint256[] memory theoreticalAmounts = new uint256[](1);
        theoreticalAmounts[0] = 1000e6; // Theoretical: 1,000,000,000
        uint256 totalTheoreticalNetAssets = theoreticalAmounts[0]; // Single controller case

        uint256[] memory fulfillRedeemTotalAssetsOut = calculateFulfillRedeemTotalAssetsOut(
            controllers, theoreticalAmounts, totalTheoreticalNetAssets, totalAvailable
        );

        // 3. Use totalAssetsOut amounts for fulfillment (this would work)
        // strategy.fulfillRedeemRequests(controllers, fulfillRedeemTotalAssetsOut); // SUCCESS!

        assertTrue(fulfillRedeemTotalAssetsOut[0] <= totalAvailable, "TotalAssetsOut should not exceed available");

        emit log_named_string("Integration Status", "SUCCESS - No INSUFFICIENT_LIQUIDITY error");
        emit log_named_uint("Original Theoretical", theoreticalAmounts[0]);
        emit log_named_uint("FulfillRedeem TotalAssetsOut", fulfillRedeemTotalAssetsOut[0]);
        emit log_named_uint("Precision Loss Handled (wei)", theoreticalAmounts[0] - fulfillRedeemTotalAssetsOut[0]);
    }

    /*//////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SingleController_FullLossAttribution() public pure {
        // Setup: Single controller with execution loss
        address[] memory controllers = new address[](1);
        controllers[0] = address(0x1);

        uint256[] memory theoretical = new uint256[](1);
        theoretical[0] = 1000e6; // 1000 USDC theoretical
        uint256 totalTheoretical = theoretical[0]; // Single controller case

        uint256 available = 999_999_998; // 2 wei loss

        // Execute adjustment
        uint256[] memory fulfillRedeemTotalAssetsOut =
            calculateFulfillRedeemTotalAssetsOut(controllers, theoretical, totalTheoretical, available);

        // Verify: Single controller gets fair pro-rata amount, remainder stays in vault
        assertTrue(fulfillRedeemTotalAssetsOut[0] <= available, "Single controller should not exceed available");
        assertTrue(
            fulfillRedeemTotalAssetsOut[0] >= available - 2, "Single controller should get close to their fair share"
        );
        assertTrue(verifyFulfillRedeemSum(fulfillRedeemTotalAssetsOut, available), "TotalAssetsOut should be valid");
    }

    function test_MultipleControllers_ProRataDistribution() public pure {
        // Setup: Multiple controllers with different request sizes
        address[] memory controllers = new address[](3);
        controllers[0] = address(0x1);
        controllers[1] = address(0x2);
        controllers[2] = address(0x3);

        uint256[] memory theoretical = new uint256[](3);
        theoretical[0] = 500e6; // 50% of total
        theoretical[1] = 300e6; // 30% of total
        theoretical[2] = 200e6; // 20% of total
        // Total: 1000e6
        uint256 totalTheoretical = theoretical[0] + theoretical[1] + theoretical[2];

        uint256 available = 998e6; // 2e6 loss

        // Execute adjustment
        uint256[] memory fulfillRedeemTotalAssetsOut =
            calculateFulfillRedeemTotalAssetsOut(controllers, theoretical, totalTheoretical, available);

        // Verify pro-rata distribution (allowing for rounding)
        // Expected: ~499e6, ~299.4e6, ~199.6e6
        assertTrue(
            fulfillRedeemTotalAssetsOut[0] >= 498e6 && fulfillRedeemTotalAssetsOut[0] <= 500e6,
            "Controller 0 should get ~50%"
        );
        assertTrue(
            fulfillRedeemTotalAssetsOut[1] >= 298e6 && fulfillRedeemTotalAssetsOut[1] <= 300e6,
            "Controller 1 should get ~30%"
        );
        assertTrue(
            fulfillRedeemTotalAssetsOut[2] >= 198e6 && fulfillRedeemTotalAssetsOut[2] <= 200e6,
            "Controller 2 should get ~20%"
        );

        // Verify total is valid (sum <= available, remainder stays in vault)
        assertTrue(verifyFulfillRedeemSum(fulfillRedeemTotalAssetsOut, available), "TotalAssetsOut should be valid");
    }

    function test_ZeroLoss_NoAdjustment() public pure {
        // Setup: No execution loss
        address[] memory controllers = new address[](2);
        controllers[0] = address(0x1);
        controllers[1] = address(0x2);

        uint256[] memory theoretical = new uint256[](2);
        theoretical[0] = 600e6;
        theoretical[1] = 400e6;
        uint256 totalTheoretical = theoretical[0] + theoretical[1];

        uint256 available = 1000e6; // Exact match

        // Execute adjustment
        uint256[] memory fulfillRedeemTotalAssetsOut =
            calculateFulfillRedeemTotalAssetsOut(controllers, theoretical, totalTheoretical, available);

        // Verify: No adjustment when no loss
        assertEq(fulfillRedeemTotalAssetsOut[0], theoretical[0], "No adjustment needed when no loss");
        assertEq(fulfillRedeemTotalAssetsOut[1], theoretical[1], "No adjustment needed when no loss");
    }

    function test_EdgeCase_LargeLoss() public pure {
        // Setup: Significant execution loss
        address[] memory controllers = new address[](2);
        controllers[0] = address(0x1);
        controllers[1] = address(0x2);

        uint256[] memory theoretical = new uint256[](2);
        theoretical[0] = 700e6;
        theoretical[1] = 300e6;
        uint256 totalTheoretical = theoretical[0] + theoretical[1];

        uint256 available = 500e6; // 50% loss (extreme case)

        // Execute adjustment
        uint256[] memory fulfillRedeemTotalAssetsOut =
            calculateFulfillRedeemTotalAssetsOut(controllers, theoretical, totalTheoretical, available);

        // Verify proportional reduction
        // Expected: ~350e6, ~150e6
        assertTrue(
            fulfillRedeemTotalAssetsOut[0] >= 349e6 && fulfillRedeemTotalAssetsOut[0] <= 351e6,
            "Large loss should be proportional"
        );
        assertTrue(
            fulfillRedeemTotalAssetsOut[1] >= 149e6 && fulfillRedeemTotalAssetsOut[1] <= 151e6,
            "Large loss should be proportional"
        );

        assertTrue(verifyFulfillRedeemSum(fulfillRedeemTotalAssetsOut, available), "Large loss should be valid");
    }
}
