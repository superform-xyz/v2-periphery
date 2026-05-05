# Interview Notes: Pendle PT Amortized Pricing

**Date:** 2026-01-21
**Interviewee:** Cosmin (Engineering)

---

## Problem Statement

The current `PendlePTYieldSourceOracle` uses `getPtToAssetRate()` which returns mark-to-market pricing based on AMM supply/demand. This causes PPS (Price Per Share) volatility in SuperVaults even though PT is guaranteed to converge to 1 at maturity.

For a "Boring PT Strategy" (hold-to-maturity), we need smooth, monotonically increasing prices that reflect accrued value from pull-to-par dynamics rather than market volatility.

---

## Solution: Cost-Basis Amortized Pricing

Replace mark-to-market pricing with a cost-basis approach that:
1. Tracks weighted average entry price (P0) and entry time (T0)
2. Applies linear pull-to-par formula: `P(t) = P0 + (1 - P0) × (t - T0) / (T_maturity - T0)`

### Why Cost-Basis Over Other Approaches?

| Approach | Discount Rate Source | Market Discovered? | Fits Strategy? |
|----------|---------------------|-------------------|----------------|
| LinearDiscountOracle | Governance-set rate | No | No - arbitrary |
| Chaos Labs PT Risk Oracle | Liquidity-aware | Yes | No - causes volatility |
| AMM TWAP | Supply/demand | Yes | No - mark-to-market |
| **Cost-basis** | Implied rate at purchase | Yes | **Yes** |

---

## Technical Decisions

### Architecture
**Decision:** New dedicated oracle (`PendlePTAmortizedOracle`)
**Rationale:** Keep existing `PendlePTYieldSourceOracle` for mark-to-market use cases; new oracle specifically for amortized pricing

### Purchase Recording
**Decision:** Keeper/executor call with specific `KEEPER_ROLE`
**Rationale:** Cannot modify SuperVault code, so external authorized caller records purchases
**Flow:**
1. Strategy executes PT buy via hooks
2. Keeper observes purchase (via events/logs)
3. Keeper calls `recordPurchase(vault, market, quantity, entryPrice, timestamp)`

### Multi-Market Support
**Decision:** Support multiple PT positions with different maturities per vault
**Data Structure:** `mapping(address vault => mapping(address market => Position))`

### Migration Strategy
**Decision:** Fresh start - only apply to new purchases after deployment
**Rationale:** Simpler, avoids complex historical reconstruction

### Fallback Behavior
**Decision:** Revert if no cost-basis data exists for a position
**Rationale:** Clear failure mode; forces explicit recording before pricing

### Redemption Handling
**Decision:** No adjustment to cost basis on partial redemptions
**Formula:** Keep same `avgP0` and `avgT0`, just reduce `totalQuantity`
**Rationale:** Standard moving average cost accounting

### Integration with Pricing Service
**Decision:** Oracle as source - pricing service reads from `getPrice()`, then pushes to aggregator
**Flow:**
1. Oracle provides deterministic price at any block
2. Pricing service queries oracle
3. Pricing service applies Step 3 conversion (e.g., DETH→WETH)
4. Pricing service pushes final PPS to aggregator

---

## Requirements

### Functional Requirements
1. Track weighted average entry price and entry time per vault/market
2. Calculate amortized price using linear pull-to-par formula
3. Support multiple PT markets with different maturities
4. Record purchases via authorized keeper role
5. Handle quantity reductions on redemptions

### Non-Functional Requirements
1. **Deterministic:** Same result for same block height (validator network)
2. **Transparent:** On-chain, verifiable (Hypernative monitoring)
3. **Single source of truth:** No off-chain state dependencies
4. **Gas efficient:** View functions must be cheap (<20k gas)

---

## Access Control

- `KEEPER_ROLE`: Can call `recordPurchase()` and `recordRedemption()`
- `ADMIN_ROLE`: Can grant/revoke keeper role, set market configurations

---

## Testing Strategy

**Decision:** Full integration tests
- Unit tests for weighted average math
- Unit tests for linear interpolation
- Fork tests against real Pendle markets
- Integration tests with SuperVaultStrategy
- Edge case tests (maturity reached, zero quantity, etc.)

---

## Open Questions (Resolved)

| Question | Answer | Decided By |
|----------|--------|------------|
| Where should logic live? | New dedicated oracle | Cosmin |
| How to record purchases? | Keeper/executor call | Cosmin |
| Multi-market support? | Yes, per vault/market | Cosmin |
| Migration approach? | Fresh start | Cosmin |
| Fallback behavior? | Revert | Cosmin |
| Redemption handling? | No adjustment | Cosmin |

---

## References

- Current oracle: `v2-core/src/accounting/oracles/PendlePTYieldSourceOracle.sol`
- Similar pattern: Cost-basis tracking for performance fees
- Pendle docs: https://docs.pendle.finance/pendle-v2/Developers/Oracles/
- Chaos Labs PT Risk Oracle: https://chaoslabs.xyz/posts/introducing-pendle-pt-risk-oracle
