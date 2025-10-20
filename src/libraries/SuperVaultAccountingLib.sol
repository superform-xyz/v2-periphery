// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

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
    error ZERO_REQUEST_PPS();

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

    /// @notice Calculate final assets with dual-bound slippage protection
    /// @dev Implements dual-bound check:
    ///      - Lower bound: User's slippage protection against total losses (anchored to REQUEST PPS)
    ///      - Upper bound: Vault PPS preservation (never overpay)
    /// @param claimableAssetsWithFees Assets before fee deduction (theoretical amount at current PPS)
    /// @param totalFee Total performance fee to deduct
    /// @param strategyBalance Total available balance in strategy
    /// @param slippageBps User's slippage tolerance in basis points
    /// @param requestedShares Number of shares being redeemed
    /// @param averageRequestPPS PPS at the time of request
    /// @param precision Precision constant for PPS calculations
    /// @return claimableAssets Final assets user will receive (actual payout)
    function calculateClaimableAssets(
        uint256 claimableAssetsWithFees,
        uint256 totalFee,
        uint256 strategyBalance,
        uint256 slippageBps,
        uint256 requestedShares,
        uint256 averageRequestPPS,
        uint256 precision
    )
        internal
        pure
        returns (uint256 claimableAssets)
    {
        if (averageRequestPPS == 0) revert ZERO_REQUEST_PPS();

        // Step 1: Calculate expected assets based on REQUEST PPS
        // This is what user expected to receive when they submitted the request
        uint256 expectedAssetsAtRequest = requestedShares.mulDiv(averageRequestPPS, precision, Math.Rounding.Floor);

        // Step 2: Apply user's slippage to REQUEST expectations, then subtract fees
        // This protects against ALL losses: PPS drops, rounding, and UYS slippage combined
        uint256 minAssetOut =
            expectedAssetsAtRequest.mulDiv(BPS_PRECISION - slippageBps, BPS_PRECISION, Math.Rounding.Floor);
        // Subtract fees from minimum (fees are already transferred out of strategyBalance)
        if (minAssetOut > totalFee) {
            minAssetOut -= totalFee;
        } else {
            minAssetOut = 0;
        }

        // Step 3: Check lower bound - ensure strategy has enough to meet user's minimum
        // Fees have already been transferred out, so strategyBalance is post-fee
        if (strategyBalance < minAssetOut) {
            revert SLIPPAGE_EXCEEDED();
        }

        // Step 4: Calculate theoretical assets at current PPS (after fees)
        uint256 theoreticalAssets = claimableAssetsWithFees - totalFee;

        // Step 5: Pay user the minimum of (strategyBalance, theoreticalAssets)
        // - If strategyBalance < theoretical: user absorbs the loss (within their slippage tolerance)
        // - If strategyBalance >= theoretical: user gets exactly what they're entitled to (never overpay)
        // This preserves vault PPS: paying out <= theoretical means PPS doesn't decrease
        claimableAssets = strategyBalance < theoreticalAssets ? strategyBalance : theoreticalAssets;

        return claimableAssets;
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
