// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { console2 } from "forge-std/console2.sol";

/// @title SuperVaultAccountingLib
/// @author Superform Labs
/// @notice Stateless library for SuperVault accounting calculations
/// @dev All functions are pure for easy auditing and testing
library SuperVaultAccountingLib {
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error INSUFFICIENT_SHARES();
    error SLIPPAGE_EXCEEDED();
    error INSUFFICIENT_LIQUIDITY();

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant BPS_PRECISION = 10_000;

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate cost basis for requested shares using proportional approach
    /// @param accumulatorShares Total shares in accumulator
    /// @param accumulatorCostBasis Total cost basis in accumulator
    /// @param requestedShares Shares being redeemed
    /// @return costBasis Proportional cost basis for requested shares
    /// @return newAccumulatorShares Updated accumulator shares
    /// @return newAccumulatorCostBasis Updated accumulator cost basis
    function calculateCostBasis(
        uint256 accumulatorShares,
        uint256 accumulatorCostBasis,
        uint256 requestedShares
    )
        internal
        pure
        returns (uint256 costBasis, uint256 newAccumulatorShares, uint256 newAccumulatorCostBasis)
    {
        if (requestedShares > accumulatorShares) revert INSUFFICIENT_SHARES();

        // Calculate cost basis proportionally
        costBasis = requestedShares.mulDiv(accumulatorCostBasis, accumulatorShares, Math.Rounding.Floor);

        // Calculate updated accumulator values
        newAccumulatorShares = accumulatorShares - requestedShares;
        newAccumulatorCostBasis = accumulatorCostBasis - costBasis;

        return (costBasis, newAccumulatorShares, newAccumulatorCostBasis);
    }

    /// @notice Validate PPS slippage is within acceptable bounds
    /// @param currentPPS Current price per share
    /// @param averageRequestPPS Average PPS at time of request
    /// @param maxPPSSlippage Maximum allowed PPS decrease in BPS
    function validatePPSSlippage(uint256 currentPPS, uint256 averageRequestPPS, uint256 maxPPSSlippage) internal pure {
        // Skip if no request PPS recorded or no max slippage set
        if (averageRequestPPS == 0 || maxPPSSlippage == 0) return;

        // Calculate the percentage decrease from request PPS to current PPS
        if (currentPPS < averageRequestPPS) {
            uint256 decrease =
                ((averageRequestPPS - currentPPS).mulDiv(BPS_PRECISION, averageRequestPPS, Math.Rounding.Floor));

            // If decrease exceeds maximum allowed slippage, revert
            if (decrease > maxPPSSlippage) revert SLIPPAGE_EXCEEDED();
        }
    }

    /// @notice Calculate performance fee on profit
    /// @param currentAssetsWithFees Current value of shares in assets
    /// @param historicalAssets Historical cost basis in assets
    /// @param performanceFeeBps Performance fee in basis points
    /// @param superformRevenueShare Superform's revenue share in BPS
    /// @return totalFee Total fee amount
    /// @return superformFee Superform's portion of the fee
    /// @return recipientFee Recipient's portion of the fee
    function calculatePerformanceFee(
        uint256 currentAssetsWithFees,
        uint256 historicalAssets,
        uint256 performanceFeeBps,
        uint256 superformRevenueShare
    )
        internal
        pure
        returns (uint256 totalFee, uint256 superformFee, uint256 recipientFee)
    {
        if (currentAssetsWithFees <= historicalAssets) {
            return (0, 0, 0);
        }

        uint256 profit = currentAssetsWithFees - historicalAssets;
        totalFee = profit.mulDiv(performanceFeeBps, BPS_PRECISION, Math.Rounding.Ceil);

        if (totalFee > 0) {
            superformFee = totalFee.mulDiv(superformRevenueShare, BPS_PRECISION, Math.Rounding.Floor);
            recipientFee = totalFee - superformFee;
        }

        return (totalFee, superformFee, recipientFee);
    }

    /// @notice Calculate final assets after fee deduction and validate sufficient liquidity
    /// @param currentAssetsWithFees Assets before fee deduction
    /// @param totalFee Total fee to deduct
    /// @param strategyBalance Available balance in strategy
    /// @return currentAssets Final assets after fees
    function calculateCurrentAssets(
        uint256 currentAssetsWithFees,
        uint256 totalFee,
        uint256 strategyBalance
    )
        internal
        pure
        returns (uint256 currentAssets)
    {
        currentAssets = currentAssetsWithFees - totalFee;
        console2.log("currentAssets", currentAssets);
        console2.log("strategyBalance", strategyBalance);
        /// @dev TODO truncate for now but this should be removed;
        // Revert if insufficient liquidity instead of silently capping
        // Strategist must maintain free asset reserve or executeHooks to redeem from yield sources first
        if (currentAssets > strategyBalance) {
            currentAssets = strategyBalance;
        }

        return currentAssets;
    }

    /// @notice Validate redemption share amounts are within tolerance bounds
    /// @param intendedShares Shares intended to be redeemed
    /// @param totalRequestedShares Total shares requested by users
    /// @param toleranceConstant Tolerance in wei
    function validateRedemptionBounds(
        uint256 intendedShares,
        uint256 totalRequestedShares,
        uint256 toleranceConstant
    )
        internal
        pure
    {
        // Lower bound check
        require(intendedShares + toleranceConstant >= totalRequestedShares, "Below tolerance");

        // Upper bound check
        require(intendedShares <= totalRequestedShares + toleranceConstant, "Above tolerance");
    }

    /// @notice Calculate updated average withdraw price
    /// @param currentMaxWithdraw Current max withdrawable assets
    /// @param currentAverageWithdrawPrice Current average withdraw price
    /// @param requestedShares New shares being fulfilled
    /// @param currentAssetsWithFees New assets being added
    /// @param precision Precision constant
    /// @return newAverageWithdrawPrice Updated average withdraw price
    function calculateAverageWithdrawPrice(
        uint256 currentMaxWithdraw,
        uint256 currentAverageWithdrawPrice,
        uint256 requestedShares,
        uint256 currentAssetsWithFees,
        uint256 precision
    )
        internal
        pure
        returns (uint256 newAverageWithdrawPrice)
    {
        uint256 existingShares;
        uint256 existingAssets;

        if (currentMaxWithdraw > 0 && currentAverageWithdrawPrice > 0) {
            existingShares = currentMaxWithdraw.mulDiv(precision, currentAverageWithdrawPrice, Math.Rounding.Floor);
            existingAssets = currentMaxWithdraw;
        }

        uint256 newTotalShares = existingShares + requestedShares;
        uint256 newTotalAssets = existingAssets + currentAssetsWithFees;

        if (newTotalShares > 0) {
            newAverageWithdrawPrice = newTotalAssets.mulDiv(precision, newTotalShares, Math.Rounding.Floor);
        }

        return newAverageWithdrawPrice;
    }
}
