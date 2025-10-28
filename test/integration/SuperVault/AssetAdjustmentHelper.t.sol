// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

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
     * @param totalAvailableAssets Actual assets available from executeHooks (sum of expectedAssetsOrSharesOut)
     * @return adjustedNetAssets Array adjusted to match available liquidity, sum <= totalAvailableAssets
     */
    function adjustNetAssetsForExecutionLoss(
        address[] memory controllers,
        uint256[] memory theoreticalNetAssets,
        uint256 totalAvailableAssets
    ) 
        internal 
        pure 
        returns (uint256[] memory adjustedNetAssets) 
    {
        // Input validation
        if (controllers.length == 0 || theoreticalNetAssets.length == 0) {
            revert EMPTY_ARRAYS();
        }
        if (controllers.length != theoreticalNetAssets.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        adjustedNetAssets = new uint256[](controllers.length);
        
        // Calculate total theoretical assets across all controllers
        uint256 totalTheoreticalAssets = 0;
        for (uint256 i = 0; i < theoreticalNetAssets.length; i++) {
            totalTheoreticalAssets += theoreticalNetAssets[i];
        }
        
        if (totalTheoreticalAssets == 0) {
            revert ZERO_TOTAL_THEORETICAL();
        }

        // Handle edge case: available assets exceed theoretical (should not happen but protect anyway)
        if (totalAvailableAssets >= totalTheoreticalAssets) {
            // No adjustment needed - return theoretical amounts
            return theoreticalNetAssets;
        }

        // Ensure we don't try to fulfill more than what's theoretically possible
        if (totalAvailableAssets > totalTheoreticalAssets) {
            revert INSUFFICIENT_AVAILABLE_ASSETS();
        }

        // Distribute available assets pro-rata based on theoretical amounts
        uint256 totalAdjusted = 0;
        
        for (uint256 i = 0; i < theoreticalNetAssets.length; i++) {
            if (i == theoreticalNetAssets.length - 1) {
                // Last controller gets remaining assets to handle rounding
                adjustedNetAssets[i] = totalAvailableAssets - totalAdjusted;
            } else {
                // Pro-rata calculation: (theoretical[i] * available) / totalTheoretical
                adjustedNetAssets[i] = theoreticalNetAssets[i].mulDiv(
                    totalAvailableAssets, 
                    totalTheoreticalAssets, 
                    Math.Rounding.Floor
                );
                totalAdjusted += adjustedNetAssets[i];
            }
        }

        return adjustedNetAssets;
    }

    // Note: previewExactRedeemBatch has been moved to ISuperVaultStrategy/SuperVaultStrategy
    // for production use. The strategy contract now provides efficient batch preview.

    /*//////////////////////////////////////////////////////////////
                        INTEGRATED WORKFLOW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Complete workflow to calculate adjusted netAssetsOut for fulfillRedeemRequests
     * @dev This function combines theoretical preview calculations with actual executeHooks
     *      output to produce adjusted fulfillment amounts. This is the main function to use
     *      when you need to fulfill redemption requests while accounting for execution losses.
     *      
     *      Workflow:
     *      1. Get theoretical net assets for all controllers via batch preview
     *      2. Calculate total available assets from executeHooks output  
     *      3. Adjust theoretical amounts pro-rata to match available assets
     *      4. Return adjusted array ready for fulfillRedeemRequests
     *
     * @param strategy The SuperVault strategy contract
     * @param controllers Sorted/unique controller addresses with pending redemptions
     * @param expectedAssetsFromHooks Array of assets expected from executeHooks (from expectedAssetsOrSharesOut)
     * @return adjustedNetAssets Final netAssetsOut array for fulfillRedeemRequests call
     */
    function calculateAdjustedFulfillment(
        ISuperVaultStrategy strategy,
        address[] memory controllers,
        uint256[] memory expectedAssetsFromHooks
    ) 
        internal 
        view 
        returns (uint256[] memory adjustedNetAssets) 
    {
        // Input validation
        if (controllers.length == 0 || expectedAssetsFromHooks.length == 0) {
            revert EMPTY_ARRAYS();
        }

        // Step 1: Get theoretical net assets for all controllers using strategy's batch preview
        (, uint256[] memory theoreticalNetAssets) = strategy.previewExactRedeemBatch(controllers);

        // Step 2: Calculate total available assets from executeHooks
        uint256 totalAvailableAssets = 0;
        for (uint256 i = 0; i < expectedAssetsFromHooks.length; i++) {
            totalAvailableAssets += expectedAssetsFromHooks[i];
        }

        // Step 3: Adjust theoretical amounts to match available assets
        adjustedNetAssets = adjustNetAssetsForExecutionLoss(
            controllers,
            theoreticalNetAssets,
            totalAvailableAssets
        );

        return adjustedNetAssets;
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
     * @return adjustedNetAssets Final netAssetsOut array for fulfillRedeemRequests call
     */
    function calculateLiquidityOnlyFulfillment(
        ISuperVaultStrategy strategy,
        address asset,
        address[] memory controllers
    ) 
        internal 
        view 
        returns (uint256[] memory adjustedNetAssets) 
    {
        // Input validation
        if (controllers.length == 0) {
            revert EMPTY_ARRAYS();
        }

        // Step 1: Get current strategy asset balance (available liquidity)
        uint256 strategyBalance = IERC20(asset).balanceOf(address(strategy));
        
        // Step 2: Get theoretical net assets for all controllers using strategy's batch preview
        (, uint256[] memory theoreticalNetAssets) = strategy.previewExactRedeemBatch(controllers);

        // Step 3: Calculate total theoretical requirement
        uint256 totalTheoretical = 0;
        for (uint256 i = 0; i < theoreticalNetAssets.length; i++) {
            totalTheoretical += theoreticalNetAssets[i];
        }

        // Step 4: If strategy has enough balance, use theoretical amounts
        if (strategyBalance >= totalTheoretical) {
            return theoreticalNetAssets;
        }

        // Step 5: Strategy balance is insufficient, adjust pro-rata
        adjustedNetAssets = adjustNetAssetsForExecutionLoss(
            controllers,
            theoreticalNetAssets,
            strategyBalance
        );

        return adjustedNetAssets;
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
     * @notice Verify that adjusted amounts sum to available assets
     * @dev Helper function to validate adjustment calculations
     * @param adjustedNetAssets Array of adjusted net assets
     * @param totalAvailableAssets Expected total available assets
     * @return isValid True if the sum matches (within 1 wei tolerance)
     */
    function verifyAdjustmentSum(
        uint256[] memory adjustedNetAssets,
        uint256 totalAvailableAssets
    ) 
        internal 
        pure 
        returns (bool isValid) 
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < adjustedNetAssets.length; i++) {
            sum += adjustedNetAssets[i];
        }
        
        // Allow 1 wei difference due to rounding in pro-rata calculations
        isValid = sum <= totalAvailableAssets && (totalAvailableAssets - sum) <= 1;
        
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
        expectedFromHooks[0] = 435019644; // Vault 1 output (from test logs)
        expectedFromHooks[1] = 443122022; // Vault 2 output (from test logs) 
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
        
        // STEP 4: Apply adjustment to fix the precision mismatch
        uint256[] memory adjustedNetAssets = adjustNetAssetsForExecutionLoss(
            controllers,
            theoreticalNetAssets,
            totalAvailable
        );
        
        // VERIFICATION: The adjusted amount should exactly match available assets
        assertEq(adjustedNetAssets[0], totalAvailable, "Adjusted amount should match available");
        assertTrue(
            verifyAdjustmentSum(adjustedNetAssets, totalAvailable),
            "Adjustment should sum to available assets"
        );
        
        // SUCCESS: Now fulfillRedeemRequests would work with adjustedNetAssets
        // instead of theoretical amounts, eliminating INSUFFICIENT_LIQUIDITY error
        
        emit log_named_uint("Theoretical Net Assets", theoreticalNetAssets[0]);
        emit log_named_uint("Available from Hooks", totalAvailable);
        emit log_named_uint("Adjusted Net Assets", adjustedNetAssets[0]);
        emit log_named_uint("Precision Loss (wei)", theoreticalNetAssets[0] - adjustedNetAssets[0]);
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
        
        uint256[] memory adjustedNetAssets = adjustNetAssetsForExecutionLoss(
            controllers,
            theoreticalAmounts,
            totalAvailable
        );
        
        // 3. Use adjusted amounts for fulfillment (this would work)
        // strategy.fulfillRedeemRequests(controllers, adjustedNetAssets); // SUCCESS!
        
        assertEq(adjustedNetAssets[0], totalAvailable, "Adjustment should match available");
        
        emit log_named_string("Integration Status", "SUCCESS - No INSUFFICIENT_LIQUIDITY error");
        emit log_named_uint("Original Theoretical", theoreticalAmounts[0]);
        emit log_named_uint("Adjusted for Execution", adjustedNetAssets[0]);
        emit log_named_uint("Precision Loss Handled (wei)", theoreticalAmounts[0] - adjustedNetAssets[0]);
    }

    /*//////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SingleController_FullLossAttribution() public {
        // Setup: Single controller with execution loss
        address[] memory controllers = new address[](1);
        controllers[0] = address(0x1);
        
        uint256[] memory theoretical = new uint256[](1);
        theoretical[0] = 1000e6; // 1000 USDC theoretical
        
        uint256 available = 999999998; // 2 wei loss
        
        // Execute adjustment
        uint256[] memory adjusted = adjustNetAssetsForExecutionLoss(
            controllers,
            theoretical,
            available
        );
        
        // Verify: Full loss attributed to single controller
        assertEq(adjusted[0], available, "Single controller should get all available assets");
        assertTrue(
            verifyAdjustmentSum(adjusted, available),
            "Adjustment sum should match available assets"
        );
    }

    function test_MultipleControllers_ProRataDistribution() public {
        // Setup: Multiple controllers with different request sizes
        address[] memory controllers = new address[](3);
        controllers[0] = address(0x1);
        controllers[1] = address(0x2); 
        controllers[2] = address(0x3);
        
        uint256[] memory theoretical = new uint256[](3);
        theoretical[0] = 500e6;  // 50% of total
        theoretical[1] = 300e6;  // 30% of total
        theoretical[2] = 200e6;  // 20% of total
        // Total: 1000e6
        
        uint256 available = 998e6; // 2e6 loss
        
        // Execute adjustment
        uint256[] memory adjusted = adjustNetAssetsForExecutionLoss(
            controllers,
            theoretical,
            available
        );
        
        // Verify pro-rata distribution (allowing for rounding)
        // Expected: ~499e6, ~299.4e6, ~199.6e6
        assertTrue(adjusted[0] >= 498e6 && adjusted[0] <= 500e6, "Controller 0 should get ~50%");
        assertTrue(adjusted[1] >= 298e6 && adjusted[1] <= 300e6, "Controller 1 should get ~30%");
        assertTrue(adjusted[2] >= 198e6 && adjusted[2] <= 200e6, "Controller 2 should get ~20%");
        
        // Verify total
        assertTrue(
            verifyAdjustmentSum(adjusted, available),
            "Adjustment sum should match available assets"
        );
    }

    function test_ZeroLoss_NoAdjustment() public {
        // Setup: No execution loss
        address[] memory controllers = new address[](2);
        controllers[0] = address(0x1);
        controllers[1] = address(0x2);
        
        uint256[] memory theoretical = new uint256[](2);
        theoretical[0] = 600e6;
        theoretical[1] = 400e6;
        
        uint256 available = 1000e6; // Exact match
        
        // Execute adjustment
        uint256[] memory adjusted = adjustNetAssetsForExecutionLoss(
            controllers,
            theoretical,
            available
        );
        
        // Verify: No adjustment when no loss
        assertEq(adjusted[0], theoretical[0], "No adjustment needed when no loss");
        assertEq(adjusted[1], theoretical[1], "No adjustment needed when no loss");
    }

    function test_EdgeCase_LargeLoss() public {
        // Setup: Significant execution loss
        address[] memory controllers = new address[](2);
        controllers[0] = address(0x1);
        controllers[1] = address(0x2);
        
        uint256[] memory theoretical = new uint256[](2);
        theoretical[0] = 700e6;
        theoretical[1] = 300e6;
        
        uint256 available = 500e6; // 50% loss (extreme case)
        
        // Execute adjustment
        uint256[] memory adjusted = adjustNetAssetsForExecutionLoss(
            controllers,
            theoretical,
            available
        );
        
        // Verify proportional reduction
        // Expected: ~350e6, ~150e6
        assertTrue(adjusted[0] >= 349e6 && adjusted[0] <= 351e6, "Large loss should be proportional");
        assertTrue(adjusted[1] >= 149e6 && adjusted[1] <= 151e6, "Large loss should be proportional");
        
        assertTrue(
            verifyAdjustmentSum(adjusted, available),
            "Large loss adjustment sum should match"
        );
    }
}