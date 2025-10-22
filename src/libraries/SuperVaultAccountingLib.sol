// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";

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

    /*//////////////////////////////////////////////////////////////
                        VESTING CALCULATION HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Compute vested amount from delta and elapsed time (shared helper)
    /// @param delta Total amount to vest over duration
    /// @param elapsed Time elapsed since vesting start
    /// @param duration Total vesting duration
    /// @return vested Amount that has vested so far
    function computeVested(uint256 delta, uint256 elapsed, uint256 duration) internal pure returns (uint256 vested) {
        if (delta == 0) return 0;
        if (elapsed >= duration) return delta;
        return delta.mulDiv(elapsed, duration, Math.Rounding.Floor);
    }

    /// @dev Handle merge logic for PPS increases during active vesting
    /// @param currentPPS New higher PPS from aggregator
    /// @param oldStartPPS Original starting PPS
    /// @param oldTargetPPS Original target PPS
    /// @param vested Amount already vested from original delta
    /// @param ts Timestamp for reset
    /// @return newStartPPS Updated start PPS (includes vested amount)
    /// @return newTargetPPS Updated target PPS (preserves all yield)
    /// @return newStartTime Updated start time (reset to current)
    function computeMergedIncrease(
        uint256 currentPPS,
        uint256 oldStartPPS,
        uint256 oldTargetPPS,
        uint256 vested,
        uint256 ts
    )
        internal
        pure
        returns (uint256 newStartPPS, uint256 newTargetPPS, uint256 newStartTime)
    {
        // New start includes already vested amount
        newStartPPS = oldStartPPS + vested;

        // Calculate remaining unvested from original jump
        uint256 oldDelta = oldTargetPPS - oldStartPPS;
        uint256 remainingUnvested = oldDelta - vested;

        // Calculate new jump delta
        uint256 newDelta = currentPPS - oldTargetPPS;

        // Merge: new target = effective start + remaining old + new jump
        newTargetPPS = newStartPPS + remainingUnvested + newDelta;

        // Reset timer to current timestamp
        newStartTime = ts;

        return (newStartPPS, newTargetPPS, newStartTime);
    }

    /// @dev Handle capping logic for PPS decreases during vesting (dilution protection)
    /// @param currentPPS New lower PPS from aggregator
    /// @param currentEffective Current effective PPS based on vesting progress
    /// @param elapsed Time elapsed in current vesting period
    /// @param duration Original vesting duration
    /// @param ts Timestamp for reset
    /// @return newStartPPS Capped start PPS (never exceeds real PPS)
    /// @return newStartTime Updated start time (reset to current)
    /// @return newDuration Adjusted duration (remaining time)
    function computeCappedDecrease(
        uint256 currentPPS,
        uint256 currentEffective,
        uint256 elapsed,
        uint256 duration,
        uint256 ts
    )
        internal
        pure
        returns (uint256 newStartPPS, uint256 newStartTime, uint256 newDuration)
    {
        // Cap effective PPS to never exceed real PPS (prevents over-redemption)
        newStartPPS = Math.min(currentEffective, currentPPS);

        // Reset timer
        newStartTime = ts;

        // Adjust duration to remaining time (maintains vesting smoothness)
        newDuration = elapsed < duration ? duration - elapsed : 1; // Avoid div0

        return (newStartPPS, newStartTime, newDuration);
    }

    /// @dev Compute new vesting data values for updateVesting to apply to storage
    /// @dev This is the main pure function that encapsulates all vesting logic
    /// @param currentPPS Current PPS from aggregator
    /// @param vData Current vesting data from storage
    /// @param ts Current timestamp (lastUpdateTimestamp)
    /// @return newStartPPS New start PPS to store
    /// @return newTargetPPS New target PPS to store
    /// @return newStartTime New start time to store
    /// @return newDuration New duration to store
    /// @return shouldEmitDecrease Whether decrease event should be emitted
    function computeUpdatedVestingData(
        uint256 currentPPS,
        ISuperVaultStrategy.VestingData memory vData,
        uint256 ts
    )
        internal
        pure
        returns (
            uint256 newStartPPS,
            uint256 newTargetPPS,
            uint256 newStartTime,
            uint256 newDuration,
            bool shouldEmitDecrease
        )
    {
        // Early return if vesting is disabled
        if (vData.duration == 0) {
            return (0, 0, 0, 0, false);
        }

        // Calculate elapsed time and vested amount using shared helper
        uint256 elapsed = ts > vData.startTime ? ts - vData.startTime : 0;
        uint256 delta = uint256(vData.targetPPS) - uint256(vData.startPPS);
        uint256 vested = computeVested(delta, elapsed, vData.duration);

        // Base values (after applying vested amount)
        newStartPPS = uint256(vData.startPPS) + vested;
        newTargetPPS = vData.targetPPS;
        newStartTime = vData.startTime;
        newDuration = vData.duration;
        shouldEmitDecrease = false;

        if (currentPPS > vData.targetPPS) {
            // HANDLE PPS INCREASES: Merge new jumps with ongoing vesting
            // This preserves all yield by combining remaining unvested with new increases
            (newStartPPS, newTargetPPS, newStartTime) =
                computeMergedIncrease(currentPPS, vData.startPPS, vData.targetPPS, vested, ts);
        } else if (currentPPS < vData.targetPPS) {
            // HANDLE PPS DECREASES: Cap effective PPS for dilution protection
            // This prevents effective PPS from exceeding real PPS while preserving full yield unlock
            uint256 currentEffective = newStartPPS; // After vested amount added
            (newStartPPS, newStartTime, newDuration) =
                computeCappedDecrease(currentPPS, currentEffective, elapsed, vData.duration, ts);
            // Preserve original targetPPS to unlock full yield later
            // newTargetPPS remains unchanged
            shouldEmitDecrease = true;
        } else {
            // No PPS change: Just update target to include remaining unvested amount
            newTargetPPS = newStartPPS + (delta - vested);
        }

        return (newStartPPS, newTargetPPS, newStartTime, newDuration, shouldEmitDecrease);
    }

    /// @notice Performs linear vesting calculation between start and target PPS over time
    /// @dev Pure function for linear interpolation of PPS values during vesting periods
    /// @dev This is the core mathematical formula used by both simulation and update paths
    /// @param currentPPS Current PPS from aggregator (used for safety capping)
    /// @param startPPS Starting PPS value for vesting period
    /// @param targetPPS Target PPS value to vest towards
    /// @param startTime Timestamp when vesting period began
    /// @param duration Total vesting duration in seconds
    /// @param ts Current timestamp to calculate elapsed time
    /// @return effectivePPS Linearly interpolated PPS value, capped to currentPPS
    function calculateLinearVesting(
        uint256 currentPPS,
        uint256 startPPS,
        uint256 targetPPS,
        uint256 startTime,
        uint256 duration,
        uint256 ts
    )
        internal
        pure
        returns (uint256 effectivePPS)
    {
        // Early returns for edge cases
        if (targetPPS <= startPPS) return targetPPS;
        if (ts <= startTime) return startPPS;

        // Calculate elapsed time from consistent timestamp
        uint256 elapsed = ts - startTime;

        // Return full target if vesting complete
        if (elapsed >= duration) return targetPPS;

        // Linear interpolation: startPPS + (progress * delta)
        uint256 vested = (targetPPS - startPPS).mulDiv(elapsed, duration, Math.Rounding.Floor);
        uint256 effective = startPPS + vested;

        // Safety cap: prevent effective PPS from exceeding real PPS
        return Math.min(effective, currentPPS);
    }

    /// @dev Function to calculate effective PPS with cached data
    ///
    /// EFFECTIVE PPS CALCULATION:
    /// This function calculates the "effective" (vested) PPS at any point in time.
    /// It handles both active vesting and simulates future vesting for view functions.
    ///
    /// KEY CONCEPTS:
    /// - currentPPS: The latest PPS from the aggregator (real yield)
    /// - vData.targetPPS: The target PPS we're vesting towards (from last updateVesting)
    /// - vData.startPPS: The PPS we started vesting from
    /// - effectivePPS: The PPS users actually see (linearly interpolated)
    ///
    /// SIMULATION MODE (View Functions):
    /// When currentPPS > vData.targetPPS, a new jump has occurred but updateVesting()
    /// hasn't been called yet. We simulate what would happen if it were called now.
    /// This ensures view functions (like getEffectivePPS) return accurate values.
    ///
    /// EXAMPLE 1 - NORMAL VESTING:
    /// vData: {startPPS: 1000000, targetPPS: 1100000, startTime: T0, duration: 10 days}
    /// currentPPS: 1100000 (no new jump)
    /// At T0+3 days:
    ///   elapsed = 3 days
    ///   vestedAmount = (1100000 - 1000000) * 3/10 = 30000
    ///   effectivePPS = 1000000 + 30000 = 1030000
    ///
    /// EXAMPLE 2 - NEW JUMP SIMULATION:
    /// vData: {startPPS: 1000000, targetPPS: 1100000, startTime: T0, duration: 10 days}
    /// currentPPS: 1200000 (NEW JUMP detected!)
    /// At T0+15 days (5 days after first vesting completed):
    ///   Simulation kicks in: targetPPS > vData.targetPPS
    ///   New simulated vesting: 1100000 -> 1200000 starting at T0+10days
    ///   elapsed = 5 days (from simulated start)
    ///   vestedAmount = (1200000 - 1100000) * 5/10 = 50000
    ///   effectivePPS = 1100000 + 50000 = 1150000
    ///
    /// EXAMPLE 3 - CONCURRENT OPERATIONS:
    /// T0: Initial state, PPS = 1.0
    /// T1: Harvest, PPS jumps to 1.2, vesting starts (1.0 -> 1.2 over 10 days)
    /// T1+2d: User A deposits
    ///        effectivePPS = 1.04 (20% vested)
    ///        User gets shares = deposit / 1.04
    /// T1+5d: User B requests redeem
    ///        effectivePPS = 1.10 (50% vested)
    ///        Request locked at PPS = 1.10
    /// T1+6d: New harvest, aggregator PPS jumps to 1.3
    ///        This function simulates: would vest 1.2 -> 1.3
    ///        But actual vesting won't start until T1+10d
    /// T1+8d: User C deposits
    ///        effectivePPS = 1.16 (80% of first vesting)
    ///        New jump (1.3) NOT included yet
    /// T1+10d: First vesting completes
    ///         effectivePPS = 1.20
    ///         If updateVesting() called, new vesting 1.2 -> 1.3 starts
    /// T1+12d: User B's redeem fulfills
    ///         effectivePPS = 1.24 (20% of second vesting)
    ///         User B gets assets based on 1.24 (not their request PPS of 1.10)
    ///
    /// SLIPPAGE PROTECTION:
    /// Request/fulfill flows store the request PPS for slippage checks.
    /// Users are protected from PPS drops but benefit from increases.
    ///

    function calculateEffectivePPS(
        uint256 currentPPS,
        ISuperVaultStrategy.VestingData memory vData,
        uint256 ts
    )
        internal
        pure
        returns (uint256)
    {
        // REFACTORED: Use shared computation function for consistency
        // This ensures view functions and updateVesting use identical logic

        if (vData.duration == 0) return currentPPS;

        // Use the same pure computation function as updateVesting
        // but only extract the effective PPS (simulation mode)
        (
            uint256 simStartPPS,
            uint256 simTargetPPS,
            uint256 simStartTime,
            uint256 simDuration,
            // bool shouldEmitDecrease - ignore for simulation
        ) = computeUpdatedVestingData(currentPPS, vData, ts);

        // Use shared linear vesting calculation function
        // This ensures identical math between simulation and update paths
        return calculateLinearVesting(currentPPS, simStartPPS, simTargetPPS, simStartTime, simDuration, ts);
    }

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

    /// @notice Calculate final assets with dual-mode operation: loss socialization OR selective attribution
    /// @dev IMPORTANT: This function enables TWO distinct operational modes depending on strategist behavior:
    ///
    /// MODE 1 - STANDARD LOSS SOCIALIZATION (typical batch fulfillment):
    ///   - Strategist generates FULL liquidity via executeHooks for all pending requests
    ///   - strategyBalance >= sum of all theoretical payouts
    ///   - All users in batch get paid exactly at currentPPS (theoreticalAssets)
    ///   - Underlying Yield Source (UYS) withdrawal losses are socialized to remaining vault shareholders
    ///     via PPS updates, not to exiting users
    ///   - Example: If selling position incurs 2% slippage, vault PPS drops 2%, but exiting users
    ///     get paid at pre-drop PPS (loss absorbed by remaining shareholders)
    ///
    /// MODE 2 - SELECTIVE LOSS ATTRIBUTION (targeted fulfillment):
    ///   - Strategist generates PARTIAL liquidity via executeHooks for specific user(s)
    ///   - strategyBalance is intentionally limited to be < theoreticalAssets
    ///   - Users absorb the shortfall up to their slippage tolerance
    ///   - Enables attributing specific losses (e.g., PT secondary market slippage) directly to exiting user
    ///   - Example: Whale exits with illiquid PT → strategist sells PT with 5% slippage →
    ///     whale absorbs 5% loss (within their tolerance), vault PPS preserved
    ///
    /// OPERATIONAL REQUIREMENTS FOR MODE 2:
    ///   1. Strategy must have ≈0 free assets before executeHooks (else dilution occurs)
    ///   2. Target user(s) must be fulfilled separately (cannot mix with other users in batch)
    ///   3. executeHooks must generate precise amount: minAssetOut <= amount < theoreticalAssets
    ///   4. Atomic execution (no other executeHooks calls between generation and fulfillment)
    ///
    /// DUAL-BOUND PROTECTION:
    ///   - Lower bound: User's slippage protection (anchored to REQUEST PPS)
    ///       * Ensures user never receives less than (requestPPS * shares * (1 - slippageBps))
    ///       * Protects against PPS drops, rounding, AND selective attribution
    ///   - Upper bound: Vault PPS preservation (never overpay)
    ///       * Ensures payout <= theoretical value at current PPS
    ///       * Prevents vault PPS dilution regardless of strategyBalance
    ///
    /// @param claimableAssetsWithFees Assets before fee deduction (theoretical amount at current PPS)
    /// @param totalFee Total performance fee to deduct
    /// @param strategyBalance Total available balance in strategy (POST-FEE, controlled by executeHooks)
    /// @param slippageBps User's slippage tolerance in basis points
    /// @param requestedShares Number of shares being redeemed
    /// @param averageRequestPPS PPS at the time of request (slippage anchor point)
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
        // Step 1: Calculate expected assets based on REQUEST PPS
        // This is the user's anchor point - what they expected when submitting the request
        // Used as baseline for slippage protection, NOT current PPS
        uint256 expectedAssetsAtRequest = requestedShares.mulDiv(averageRequestPPS, precision, Math.Rounding.Floor);

        // Step 2: Apply user's slippage tolerance to their REQUEST expectations
        // This is the LOWER BOUND - protects user from ALL sources of loss:
        //   - PPS drops between request and fulfillment
        //   - Rounding errors
        //   - UYS withdrawal slippage (if attributed to user via Mode 2)
        // By anchoring to requestPPS (not currentPPS), user is protected even if vault PPS crashed
        uint256 minAssetOut =
            expectedAssetsAtRequest.mulDiv(BPS_PRECISION - slippageBps, BPS_PRECISION, Math.Rounding.Floor);

        // Subtract fees from minimum
        // (fees are already transferred out of strategyBalance in calling function)
        if (minAssetOut > totalFee) {
            minAssetOut -= totalFee;
        } else {
            minAssetOut = 0;
        }

        // Step 3: Enforce LOWER BOUND - revert if strategy cannot meet user's minimum
        // This check enables BOTH modes:
        //   - Mode 1: Should never revert (strategy has full liquidity)
        //   - Mode 2: Reverts if strategist didn't generate enough (misestimated UYS slippage)
        if (strategyBalance < minAssetOut) {
            revert SLIPPAGE_EXCEEDED();
        }

        // Step 4: Calculate theoretical payout at CURRENT PPS (after fees)
        // This is the UPPER BOUND - what user would get if vault had infinite liquidity
        uint256 theoreticalAssets = claimableAssetsWithFees - totalFee;

        // Step 5: DUAL-MODE PAYOUT LOGIC
        // Pay user the MINIMUM of (available liquidity, theoretical entitlement)
        //
        // CASE A: strategyBalance >= theoreticalAssets (Mode 1 - Standard)
        //   → claimableAssets = theoreticalAssets
        //   → User gets exactly what they're entitled to at current PPS
        //   → UYS losses were socialized to remaining shareholders (via PPS drop)
        //
        // CASE B: strategyBalance < theoreticalAssets (Mode 2 - Selective Attribution)
        //   → claimableAssets = strategyBalance
        //   → User absorbs the shortfall (theoreticalAssets - strategyBalance)
        //   → Shortfall represents UYS withdrawal losses specifically attributed to this user
        //   → Requires user's slippage tolerance >= loss amount (enforced in Step 3)
        //
        // In BOTH cases: paying out <= theoreticalAssets preserves vault PPS
        // (burning X shares for <= X * currentPPS assets cannot decrease PPS for remaining holders)
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
