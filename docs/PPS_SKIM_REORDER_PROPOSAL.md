# PPS Update Flow: Skim Before Store Proposal

## Overview

This document outlines a proposed change to reorder operations in the `forwardPPS` function in `SuperVaultAggregator.sol`. The change involves calling `skimPerformanceFee` **before** storing the PPS, using a gross totalAssets value derived from the incoming gross PPS update. This ensures that performance fees are deducted from the gross value, resulting in a net PPS that accurately reflects the vault's value after fees.

## Current Flow

### Current `_forwardPPS` Flow (SuperVaultAggregator.sol)

1. **Rate Limiting Checks** (C1)
   - Verify timestamp is monotonically increasing
   - Verify minimum update interval is respected

2. **Validation Checks** (C2.1, C2.2, C2.3)
   - C2.1: Dispersion check (stddev/mean)
   - C2.2: Deviation check (relative deviation from current PPS)
   - C2.3: M/N check (validator participation rate)

3. **Pause Logic**
   - Pause strategy if checks fail or PPS == 0

4. **Upkeep Cost Handling**
   - Deduct upkeep costs from manager balance

5. **Store Gross PPS**
   - Store `args.pps` (gross PPS) directly to `_strategyData[strategy].pps`

### Current `skimPerformanceFee` Flow (SuperVaultStrategy.sol)

1. **Get Current Total Assets**
   - Calls `vault.totalAssets()` which uses **stored PPS** from aggregator
   - Formula: `totalSupply * storedPPS / PRECISION`

2. **Calculate Profit**
   - `profit = curTotalAssets - vaultTotalCostBasis` (if > 0)

3. **Calculate and Transfer Fees**
   - `fee = profit * performanceFeeBps / BPS_PRECISION`
   - Split between treasury and fee recipient
   - Transfer fees out

4. **Update HWM**
   - `vaultTotalCostBasis = curTotalAssets - fee`

### Problem with Current Flow

- Performance fees are calculated based on the **previously stored PPS**, not the fresh update
- This creates a timing gap where fees are taken from stale values
- The stored PPS represents gross value, but users should see net value after fees
- Fees are only skimmed when managers manually call `skimPerformanceFee()`, not automatically on each PPS update

## Proposed Flow

### Proposed `_forwardPPS` Flow

1. **Rate Limiting Checks** (C1) - **UNCHANGED**
   - Verify timestamp is monotonically increasing
   - Verify minimum update interval is respected

2. **Validation Checks** (C2.1, C2.2, C2.3) - **UNCHANGED**
   - Perform all checks on **gross PPS** (`args.pps`)
   - C2.1: Dispersion check
   - C2.2: Deviation check  
   - C2.3: M/N check

3. **Calculate Gross Total Assets**
   - Get vault address from strategy: `strategy.getVaultInfo()`
   - Get total supply: `IERC20(vault).totalSupply()`
   - Calculate gross total assets: `grossTotalAssets = totalSupply * grossPPS / PRECISION`
   - If `totalSupply == 0`, skip skim (no fees to calculate)

4. **Call Skim Function**
   - Call `strategy.skimPerformanceFeeWithGrossAssets(grossTotalAssets)`
   - This function will:
     - Calculate profit above HWM
     - Take performance fees
     - Update `vaultTotalCostBasis` to net value
     - Return net total assets after fees

5. **Calculate Net PPS**
   - `netTotalAssets = skimResult.netTotalAssets`
   - `netPPS = netTotalAssets * PRECISION / totalSupply`
   - If `totalSupply == 0`, use gross PPS as net PPS

6. **Pause Logic** - **UNCHANGED**
   - Pause strategy if checks failed or gross PPS == 0

7. **Upkeep Cost Handling** - **UNCHANGED**
   - Deduct upkeep costs from manager balance

8. **Store Net PPS**
   - Store `netPPS` to `_strategyData[strategy].pps`
   - Store `args.ppsStdev` (unchanged, based on gross PPS)
   - Update timestamp and stale flags

### Proposed `skimPerformanceFeeWithGrossAssets` Flow (SuperVaultStrategy.sol)

New function signature:
```solidity
function skimPerformanceFeeWithGrossAssets(uint256 grossTotalAssets) 
    external 
    returns (uint256 netTotalAssets)
```

1. **Authorization**
   - Only callable by `SuperVaultAggregator`
   - Use `_requireVault()` pattern or add aggregator check

2. **Calculate Profit**
   - `highWaterMark = totalSupply > 0 ? vaultTotalCostBasis : 0`
   - `profit = grossTotalAssets > highWaterMark ? grossTotalAssets - highWaterMark : 0`

3. **Calculate Fees**
   - If `profit == 0`, return `grossTotalAssets` (no fees)
   - `fee = profit * performanceFeeBps / BPS_PRECISION`
   - `sfFee = fee * superGovernorFee / BPS_PRECISION`

4. **Transfer Fees**
   - Transfer `sfFee` to treasury
   - Transfer `fee - sfFee` to fee recipient
   - Both transfers use `_safeTokenTransfer()`

5. **Update HWM**
   - `netTotalAssets = grossTotalAssets - fee`
   - `vaultTotalCostBasis = netTotalAssets`

6. **Return Net Total Assets**
   - Return `netTotalAssets` for PPS calculation

## Key Changes Summary

### SuperVaultAggregator.sol

1. **In `_forwardPPS` function:**
   - After validation checks, before storing PPS:
     - Get vault address via `ISuperVaultStrategy(strategy).getVaultInfo()`
     - Get total supply from vault
     - Calculate gross total assets from gross PPS
     - Call `skimPerformanceFeeWithGrossAssets(grossTotalAssets)`
     - Calculate net PPS from returned net total assets
     - Store net PPS instead of gross PPS

2. **New imports needed:**
   - `IERC20` for totalSupply
   - `ISuperVaultStrategy` interface

### SuperVaultStrategy.sol

1. **New function:**
   - `skimPerformanceFeeWithGrossAssets(uint256 grossTotalAssets) external returns (uint256 netTotalAssets)`
   - Similar logic to current `skimPerformanceFee()` but:
     - Takes gross total assets as parameter instead of reading from vault
     - Returns net total assets after fees
     - Only callable by aggregator

2. **Modify existing function:**
   - Keep `skimPerformanceFee()` for manual manager calls (backward compatibility)
   - This can continue to use `vault.totalAssets()` since it will use the updated net PPS

## Mathematical Flow

### Gross to Net Calculation

```
Given:
  - grossPPS: PPS from oracle (before fees)
  - totalSupply: Current vault share supply
  - vaultTotalCostBasis: Current HWM
  - performanceFeeBps: Performance fee in basis points

Step 1: Calculate gross total assets
  grossTotalAssets = totalSupply * grossPPS / PRECISION

Step 2: Calculate profit
  profit = max(0, grossTotalAssets - vaultTotalCostBasis)

Step 3: Calculate fees
  fee = profit * performanceFeeBps / BPS_PRECISION
  sfFee = fee * superGovernorFee / BPS_PRECISION

Step 4: Calculate net total assets
  netTotalAssets = grossTotalAssets - fee

Step 5: Update HWM
  vaultTotalCostBasis = netTotalAssets

Step 6: Calculate net PPS
  netPPS = netTotalAssets * PRECISION / totalSupply

Step 7: Store net PPS
  _strategyData[strategy].pps = netPPS
```

## Edge Cases

### Zero Total Supply
- If `totalSupply == 0`, skip skim logic
- Use gross PPS as net PPS (no fees to calculate)
- Store gross PPS directly

### Zero Profit
- If `grossTotalAssets <= vaultTotalCostBasis`:
  - No performance fee
  - `netTotalAssets = grossTotalAssets`
  - `netPPS = grossPPS`

### Checks Failed
- If C2.1, C2.2, or C2.3 fail:
  - Still perform skim (if checks are warnings, not blockers)
  - OR skip skim if we're pausing (depends on business logic)
  - Store gross PPS if pausing (or 0)

### Reentrancy
- `skimPerformanceFeeWithGrossAssets` will use `nonReentrant` modifier
- Aggregator already handles reentrancy at top level

### Gas Considerations
- Additional external call in hot path
- Strategy contract call adds gas cost
- Consider batch optimization if multiple strategies

## Benefits

1. **Automatic Fee Deduction**: Fees are automatically deducted on each PPS update
2. **Accurate Net PPS**: Stored PPS reflects actual net value users receive
3. **No Timing Gaps**: Fees calculated from fresh PPS update, not stale value
4. **Consistent State**: `vaultTotalCostBasis` always reflects post-fee state
5. **Better UX**: Users see net PPS that reflects actual redeemable value

## Risks & Considerations

1. **Gas Cost**: Additional external call per PPS update
2. **Failure Handling**: What if skim fails? Should we revert or continue with gross PPS?
3. **Zero Supply Edge Case**: Handle carefully to avoid division by zero
4. **Backward Compatibility**: Existing `skimPerformanceFee()` should still work
5. **Events**: Need to emit events for both gross and net PPS values for transparency

## Implementation Steps

1. **Add new function to ISuperVaultStrategy interface**
   ```solidity
   function skimPerformanceFeeWithGrossAssets(uint256 grossTotalAssets) 
       external 
       returns (uint256 netTotalAssets);
   ```

2. **Implement function in SuperVaultStrategy.sol**
   - Add aggregator authorization check
   - Implement fee calculation logic
   - Return net total assets

3. **Modify `_forwardPPS` in SuperVaultAggregator.sol**
   - Add gross total assets calculation
   - Call skim function
   - Calculate and store net PPS

4. **Update events**
   - Consider emitting both gross and net PPS in `PPSUpdated` event
   - Add event for fee skimming in aggregator context

5. **Add tests**
   - Test gross to net conversion
   - Test edge cases (zero supply, zero profit)
   - Test failure scenarios
   - Test gas costs

6. **Update documentation**
   - Document new flow
   - Update PPS calculation explanations

### Edge Case: Zero Supply

If `totalSupply == 0` after redemption:
- HWM should remain unchanged (it's the peak value reached)
- Next deposit will add to existing HWM
- This ensures fees are calculated correctly on new deposits

## Questions to Resolve

1. **Should we skip skim if validation checks fail?**
   - Option A: Skip skim, store gross PPS (current behavior)
   - Option B: Perform skim, but pause strategy
   - Option C: Always perform skim regardless of checks

2. **What happens if skim function reverts?**
   - Option A: Revert entire PPS update
   - Option B: Store gross PPS and continue 
   - Option C: Pause strategy

3. **Should we emit both gross and net PPS?**
   - Useful for transparency and off-chain tracking
   - Adds event gas cost

4. **Performance fee calculation timing:**
   - Should fees be calculated on every update?
   - Or only when profit threshold is met?

5. **Authorization model:**
   - How to ensure only aggregator can call skim function?
   - Use `msg.sender == aggregator` check?
   - Or use role-based access control?

6. **HWM reduction on redemption:**
   - ✅ **Recommendation**: Remove HWM reduction on redemption
   - HWM should only update on deposits and skims
   - This ensures fees are calculated correctly on new profits only

## Testing Strategy

1. **Unit Tests**
   - Test gross to net PPS calculation
   - Test fee calculation with various profit scenarios
   - Test edge cases (zero supply, zero profit, zero fees)

2. **Integration Tests**
   - Test full PPS update flow with skim
   - Test multiple strategies in batch update
   - Test failure scenarios

3. **Gas Tests**
   - Measure gas cost increase
   - Compare with current implementation
   - Optimize if needed

4. **Scenario Tests**
   - Test with various fee configurations
   - Test with different HWM states
   - Test with paused/unpaused strategies

