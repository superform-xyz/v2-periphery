---
title: Pendle PT Amortized Oracle Implementation
category: new-feature
date: 2026-01-23
spec: /specs/pendle-pt-amortized-pricing/spec.md
components: [PendlePTAmortizedOracle, BookValueState]
tags: [pendle, oracle, amortization, book-value, pt-pricing]
---

# Pendle PT Amortized Oracle Implementation

## Summary

Implemented `PendlePTAmortizedOracle` - a new oracle contract that provides amortized cost pricing for Pendle Principal Token (PT) positions held by SuperVault strategies. This replaces volatile mark-to-market pricing with deterministic, linear pull-to-par pricing suitable for hold-to-maturity strategies.

The oracle uses the Book Value accounting formula: `B(t) = A - (A - B(t0)) × (T - t) / (T - t0)`, where the price linearly converges from purchase price to face value at maturity.

## Implementation Details

### Key Decisions

**1. Storage Structure - 3 Variables Instead of 2**

The original spec proposed storing only 2 variables (`lastUpdateBookValue` and `lastUpdateTime`) and reading `ptAmount` from `balanceOf` on-demand. During implementation, I discovered this causes incorrect amortization calculations for subsequent purchases.

**Problem:** When recording a purchase after PT is received, `balanceOf` returns the NEW total amount, but the amortization formula should use the OLD amount to calculate the current book value before adding the new purchase.

**Solution:** Store `lastUpdatePtAmount` alongside the other two variables. This ensures mathematically correct amortization:

```solidity
struct BookValueState {
    uint128 lastUpdateBookValue;  // B(t0): Book value at last update
    uint64 lastUpdateTime;        // t0: Timestamp of last update
    uint128 lastUpdatePtAmount;   // A(t0): PT amount at last update
}
```

**2. Two Calculation Functions**

- `_calculateBookValue()` - Uses current `balanceOf` for external queries via `getBookValue()`
- `_calculateBookValueWithStoredAmount()` - Uses stored `lastUpdatePtAmount` for keeper updates

This separation ensures:
- External callers always get the current amortized value based on actual holdings
- Keeper updates use consistent state for calculations

**3. Market Address vs PT Address**

The spec showed accepting PT address directly, but the existing codebase pattern uses Market address. Implementation accepts Market address and extracts PT via `IPMarket(market).readTokens()`.

### Code Examples

**Recording a purchase:**
```solidity
function recordPurchase(address strategy, address market, uint256 sySpent) external onlyRole(KEEPER_ROLE) {
    // Get current book value using STORED ptAmount (not current balanceOf)
    uint256 currentBookValue = _calculateBookValueWithStoredAmount(state, maturity);
    uint256 newBookValue = currentBookValue + sySpent;

    // Sanity check against CURRENT balanceOf
    uint256 ptAmount = IERC20(address(pt)).balanceOf(strategy);
    if (newBookValue > ptAmount) revert BOOK_VALUE_EXCEEDS_FACE_VALUE();

    // Update state with current ptAmount
    state.lastUpdatePtAmount = ptAmount.toUint128();
}
```

**Amortization formula implementation:**
```solidity
// B(t) = A - (A - B(t0)) × (T - t) / (T - t0)
uint256 timeRemaining = T - block.timestamp;
uint256 totalDuration = T - t0;
uint256 unamortizedDiscount = (A - B_t0).mulDiv(timeRemaining, totalDuration);
return A - unamortizedDiscount;
```

## Testing Strategy

**Unit Tests (29 tests):**
- Constructor and role initialization
- First purchase and subsequent purchase recording
- Partial and full redemption with cost basis accounting
- Linear amortization at various time points (0%, 25%, 50%, 75%, 100%)
- Edge cases: after maturity, zero balance, no position
- Error conditions: zero address, zero amount, market expired, insufficient position
- Access control: keeper-only functions, manager-only functions
- Numerical example validation from SV-1095 proposal
- Fuzz tests for amounts and time points

**Integration Tests (fork tests):**
- Real Pendle markets on Ethereum mainnet
- Verify `balanceOf()` and `expiry()` reads work correctly
- Full lifecycle with actual PT tokens

## Prevention & Best Practices

**When implementing similar amortization oracles:**

1. **State Consistency**: If using on-demand reads for variables in time-dependent formulas, ensure the formula is evaluated with consistent state. Either:
   - Store all variables needed for calculation
   - Ensure external reads happen at the same logical time point

2. **Keeper Call Ordering**: Document whether keeper calls should happen BEFORE or AFTER token transfers:
   - `recordPurchase`: Called AFTER PT received (needs current balanceOf for sanity check)
   - `recordRedemption`: Called BEFORE PT redeemed (needs current balanceOf for cost basis)

3. **Sanity Checks**: Always validate keeper inputs against chain state to catch errors:
   - Book value should never exceed face value (ptAmount)
   - Redemption amount should not exceed holdings

4. **SafeCast Usage**: Use SafeCast for all integer downcasts to prevent silent overflow

## Related Documentation

- [SV-1095 Proposal](../research/sv-1095-proposal.md) - Mathematical framework
- [Technical Spec](../technical-spec.md) - Full implementation details
- [Pendle Oracle Docs](https://docs.pendle.finance/pendle-v2/Developers/Oracles/)
- Existing implementation: `v2-core/src/accounting/oracles/PendlePTYieldSourceOracle.sol`
