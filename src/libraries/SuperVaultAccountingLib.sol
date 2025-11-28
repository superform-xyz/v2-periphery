// SPDX-License-Identifier: Apache-2.0
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
    error INSUFFICIENT_LIQUIDITY();

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant BPS_PRECISION = 10_000;

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Compute minimum acceptable assets (slippage floor)
    /// @param requestedShares Number of shares being redeemed
    /// @param averageRequestPPS PPS at time of request (slippage anchor)
    /// @param slippageBps User's slippage tolerance in basis points
    /// @param precision Precision constant for PPS calculations
    /// @return minAssetsOut User's minimum acceptable assets
    function computeMinNetOut(
        uint256 requestedShares,
        uint256 averageRequestPPS,
        uint16 slippageBps,
        uint256 precision
    )
        internal
        pure
        returns (uint256 minAssetsOut)
    {
        uint256 expectedAssets = requestedShares.mulDiv(averageRequestPPS, precision, Math.Rounding.Floor);
        minAssetsOut = expectedAssets.mulDiv(BPS_PRECISION - slippageBps, BPS_PRECISION, Math.Rounding.Floor);
    }

    /// @notice Calculate updated average withdraw price
    /// @param currentMaxWithdraw Current max withdrawable assets
    /// @param currentAverageWithdrawPrice Current average withdraw price
    /// @param requestedShares New shares being fulfilled
    /// @param fulfilledAssets Assets received from fulfilling the redeem request
    /// @param precision Precision constant
    /// @return newAverageWithdrawPrice Updated average withdraw price
    function calculateAverageWithdrawPrice(
        uint256 currentMaxWithdraw,
        uint256 currentAverageWithdrawPrice,
        uint256 requestedShares,
        uint256 fulfilledAssets,
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
        uint256 newTotalAssets = existingAssets + fulfilledAssets;

        if (newTotalShares > 0) {
            newAverageWithdrawPrice = newTotalAssets.mulDiv(precision, newTotalShares, Math.Rounding.Floor);
        }

        return newAverageWithdrawPrice;
    }
}
