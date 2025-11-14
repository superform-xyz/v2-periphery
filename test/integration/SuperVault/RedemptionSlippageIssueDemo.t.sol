// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

/**
 * @title RedemptionSlippageIssueDemo
 * @notice Demonstrates the redemption slippage design flaw where minAssetsOut
 *         anchors to averageRequestPPS instead of currentPPS, causing reverts
 *         in legitimate loss scenarios.
 * 
 * @dev This is a simplified demonstration to illustrate the issue conceptually.
 *      A full integration test would require the complete SuperVault setup.
 */
contract RedemptionSlippageIssueDemo is Test {
    
    uint256 constant PRECISION = 1e18;
    uint256 constant BPS_PRECISION = 10_000;
    
    /*//////////////////////////////////////////////////////////////
                        SCENARIO DEMONSTRATION
    //////////////////////////////////////////////////////////////*/
    
    function test_DemonstrateSlippageIssue_WithLoss() public pure {
        console2.log("\n=== Demonstrating Slippage Issue ===\n");
        
        // SETUP: User requests redemption
        uint256 requestedShares = 2000e18;
        uint256 ppsAtRequest = 1.0e18; // PPS = 1.0 at request time
        uint16 userSlippageBps = 500; // User sets 5% slippage tolerance
        
        console2.log("T0 (Request Time):");
        console2.log("  PPS:", ppsAtRequest / 1e18);
        console2.log("  Shares Requested:", requestedShares / 1e18);
        console2.log("  User Slippage Tolerance:", userSlippageBps, "bps (5%)");
        
        // Calculate expected assets at request time
        uint256 expectedAssetsAtRequest = (requestedShares * ppsAtRequest) / PRECISION;
        console2.log("  Expected Assets:", expectedAssetsAtRequest / 1e18);
        
        // Calculate minAssetsOut using CURRENT implementation (anchored to request PPS)
        uint256 minAssetsOut_Current = computeMinNetOut_Current(
            requestedShares,
            ppsAtRequest,
            userSlippageBps
        );
        console2.log("  minAssetsOut (anchored to request):", minAssetsOut_Current / 1e18);
        
        // SCENARIO: Underlying vault loses 10% between request and fulfillment
        console2.log("\n[Market Event: Underlying vault loses 10%]\n");
        
        uint256 ppsAtFulfillment = 0.9e18; // PPS drops to 0.9
        
        console2.log("T1 (Fulfillment Time):");
        console2.log("  Current PPS:", ppsAtFulfillment / 1e18);
        
        // Calculate theoretical assets at current PPS
        uint256 theoreticalAssets = (requestedShares * ppsAtFulfillment) / PRECISION;
        console2.log("  Theoretical Assets (at current PPS):", theoreticalAssets / 1e18);
        
        // Manager executes hooks and obtains actual assets (with 10% loss)
        uint256 totalAssetsOut = 1800e18; // Manager gets 1800 instead of expected 2000
        console2.log("  Actual Assets from executeHooks:", totalAssetsOut / 1e18);
        
        // BOUNDS CHECK (current implementation)
        console2.log("\nBounds Check:");
        console2.log("  minAssetsOut:", minAssetsOut_Current / 1e18);
        console2.log("  totalAssetsOut:", totalAssetsOut / 1e18);
        console2.log("  theoreticalAssets:", theoreticalAssets / 1e18);
        console2.log("  Required: minAssetsOut <= totalAssetsOut <= theoreticalAssets");
        console2.log("  Check:", minAssetsOut_Current / 1e18, "<=", totalAssetsOut / 1e18);
        console2.log("         ", totalAssetsOut / 1e18, "<=", theoreticalAssets / 1e18);
        
        bool passesCheck = (totalAssetsOut >= minAssetsOut_Current) && (totalAssetsOut <= theoreticalAssets);
        
        if (!passesCheck) {
            console2.log("\n RESULT: BOUNDS_EXCEEDED - Transaction REVERTS");
            console2.log("  Reason: minAssetsOut (1900) > totalAssetsOut (1800)");
            console2.log("  minAssetsOut is anchored to OLD PPS (1.0), but actual is at NEW PPS (0.9)");
        } else {
            console2.log("\n RESULT: Transaction succeeds");
        }
        
        // Demonstrate that even 100% slippage doesn't help meaningfully
        console2.log("\n--- Testing with 100% Slippage ---");
        uint16 maxSlippageBps = 10_000;
        uint256 minAssetsOut_MaxSlippage = computeMinNetOut_Current(
            requestedShares,
            ppsAtRequest,
            maxSlippageBps
        );
        console2.log("  User sets slippageBps:", maxSlippageBps, "(100%)");
        console2.log("  minAssetsOut:", minAssetsOut_MaxSlippage / 1e18);
        console2.log("  This means: Accept ANY outcome, including total loss");
        console2.log("   User has NO protection - 'slippage tolerance' becomes meaningless");
        
        // Show what SHOULD happen with current PPS anchoring
        console2.log("\n=== Alternative: Anchor to Current PPS ===\n");
        uint256 minAssetsOut_Proposed = computeMinNetOut_Proposed(
            requestedShares,
            ppsAtFulfillment, // Use CURRENT PPS
            userSlippageBps
        );
        console2.log("  minAssetsOut (anchored to CURRENT PPS):", minAssetsOut_Proposed / 1e18);
        console2.log("  totalAssetsOut:", totalAssetsOut / 1e18);
        console2.log("  theoreticalAssets:", theoreticalAssets / 1e18);
        
        bool passesProposedCheck = (totalAssetsOut >= minAssetsOut_Proposed) && (totalAssetsOut <= theoreticalAssets);
        
        console2.log("\n  Bounds Check:", minAssetsOut_Proposed / 1e18, "<=", totalAssetsOut / 1e18);
        console2.log("                ", totalAssetsOut / 1e18, "<=", theoreticalAssets / 1e18);
        
        if (passesProposedCheck) {
            console2.log("\n RESULT: Transaction succeeds!");
            console2.log("  User gets 1800 assets, which is:");
            console2.log("    - Exactly theoretical at current PPS (100% of current value)");
            console2.log("    - Within 5% slippage tolerance of current market");
            console2.log("    - Fair distribution of the actual loss from underlying vault");
        }
        
        // Asset to demonstrate the issue
        assertFalse(passesCheck, "Current implementation should FAIL in loss scenario");
        assertTrue(passesProposedCheck, "Proposed implementation should SUCCEED in loss scenario");
    }
    
    function test_ShowAsymmetricRiskProfile() public pure {
        console2.log("\n=== Demonstrating Asymmetric Risk Profile ===\n");
        
        uint256 requestedShares = 1000e18;
        uint256 ppsAtRequest = 1.0e18;
        uint16 userSlippageBps = 500; // 5% tolerance
        
        uint256 minAssetsOut = computeMinNetOut_Current(requestedShares, ppsAtRequest, userSlippageBps);
        
        // SCENARIO A: PPS Increases (user wins)
        console2.log("Scenario A: PPS Increases to 1.1");
        uint256 ppsIncrease = 1.1e18;
        uint256 theoreticalA = (requestedShares * ppsIncrease) / PRECISION;
        uint256 totalAssetsOutA = 1100e18;
        
        console2.log("  minAssetsOut:", minAssetsOut / 1e18);
        console2.log("  totalAssetsOut:", totalAssetsOutA / 1e18);
        console2.log("  theoreticalAssets:", theoreticalA / 1e18);
        
        bool passesA = (totalAssetsOutA >= minAssetsOut) && (totalAssetsOutA <= theoreticalA);
        console2.log("  Result:", passesA ? " PASSES" : " FAILS");
        console2.log("  User gets UPSIDE (1100 instead of 1000)\n");
        
        // SCENARIO B: PPS Decreases (user loses, transaction fails)
        console2.log("Scenario B: PPS Decreases to 0.9");
        uint256 ppsDecrease = 0.9e18;
        uint256 theoreticalB = (requestedShares * ppsDecrease) / PRECISION;
        uint256 totalAssetsOutB = 900e18;
        
        console2.log("  minAssetsOut:", minAssetsOut / 1e18);
        console2.log("  totalAssetsOut:", totalAssetsOutB / 1e18);
        console2.log("  theoreticalAssets:", theoreticalB / 1e18);
        
        bool passesB = (totalAssetsOutB >= minAssetsOut) && (totalAssetsOutB <= theoreticalB);
        console2.log("  Result:", passesB ? " PASSES" : " FAILS");
        console2.log("  Transaction REVERTS - user cannot exit even with fair loss distribution");
        
        console2.log("\n Summary:");
        console2.log(unicode" Price UP   → User gets upside ");
        console2.log(unicode" Price DOWN → Transaction fails");
        console2.log(" This is asymmetric: heads you win, tails the system breaks");
        
        assertTrue(passesA, "Should pass when PPS increases");
        assertFalse(passesB, "Should fail when PPS decreases (demonstrating the issue)");
    }
    
    function test_ShowWorkaroundLimitations() public pure {
        console2.log("\n=== Demonstrating Workaround Limitations ===\n");
        
        uint256 requestedShares = 1000e18;
        uint256 ppsAtRequest = 1.0e18;
        uint256 ppsAtFulfillment = 0.85e18; // 15% loss
        
        uint256 theoreticalAssets = (requestedShares * ppsAtFulfillment) / PRECISION;
        uint256 totalAssetsOut = 850e18;
        
        console2.log("Scenario: 15% loss in underlying vault");
        console2.log("  PPS dropped from 1.0 to 0.85");
        console2.log("  User's shares worth: 850 assets\n");
        
        // Try different slippage values
        console2.log("User tries different slippage tolerances:\n");
        
        uint16[] memory slippageValues = new uint16[](5);
        slippageValues[0] = 500;   // 5%
        slippageValues[1] = 1000;  // 10%
        slippageValues[2] = 2000;  // 20%
        slippageValues[3] = 5000;  // 50%
        slippageValues[4] = 10000; // 100%
        
        for (uint256 i = 0; i < slippageValues.length; i++) {
            uint16 slippage = slippageValues[i];
            uint256 minOut = computeMinNetOut_Current(requestedShares, ppsAtRequest, slippage);
            bool passes = (totalAssetsOut >= minOut) && (totalAssetsOut <= theoreticalAssets);
            
            console2.log("  Slippage:", slippage, unicode"bps →", "minAssetsOut:");
            console2.log("           ", minOut / 1e18, unicode"→", passes ? " PASS" : " FAIL");
        }
        
        console2.log("\n Insight:");
        console2.log("  - Slippage < 15%: Transaction fails (minAssetsOut > 850)");
        console2.log("  - Slippage = 15%: minAssetsOut = 850, barely passes");
        console2.log("  - Slippage > 15%: User must accept MORE loss than necessary");
        console2.log("  - Slippage = 100%: minAssetsOut = 0, complete loss of protection");
        console2.log("\n   User cannot set 'reasonable' slippage for current market conditions");
        console2.log("     They must either accept the transaction fails OR remove all protection");
    }
    
    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Current implementation: anchors to averageRequestPPS
    function computeMinNetOut_Current(
        uint256 requestedShares,
        uint256 averageRequestPPS,
        uint16 slippageBps
    ) internal pure returns (uint256 minAssetsOut) {
        uint256 expectedAssets = (requestedShares * averageRequestPPS) / PRECISION;
        minAssetsOut = (expectedAssets * (BPS_PRECISION - slippageBps)) / BPS_PRECISION;
    }
    
    /// @notice Proposed implementation: anchors to currentPPS
    function computeMinNetOut_Proposed(
        uint256 requestedShares,
        uint256 currentPPS,
        uint16 slippageBps
    ) internal pure returns (uint256 minAssetsOut) {
        uint256 expectedAssets = (requestedShares * currentPPS) / PRECISION;
        minAssetsOut = (expectedAssets * (BPS_PRECISION - slippageBps)) / BPS_PRECISION;
    }
}
