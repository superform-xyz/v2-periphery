# Pendle PT Amortized Pricing Oracle Spec

## Metadata
- Project: v2-periphery
- Milestone: PT Pricing Improvements
- Linear Issue: SV-1095
- Interview Date: 2026-01-21
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

Implement a new `PendlePTAmortizedOracle` contract that provides **amortized cost pricing** for Pendle PT positions in SuperVaults. This replaces volatile mark-to-market pricing with deterministic, linear pull-to-par pricing suitable for the "Boring Strategy" (hold-to-maturity).

**Purpose:** Properly price the PT token subset of SuperVault Strategy total assets. Once priced, this value is added to other assets to get total assets, then divided by shares to get PPS.

The oracle uses Book Value accounting: `B(t) = A - (A - B(t0)) × (T - t) / (T - t0)`, where the price linearly converges from purchase price to face value at maturity.

## Requirements

### Functional
1. **Track only 2 variables per vault/market:** `lastUpdateBookValue` (B(t0)) and `lastUpdateTime` (t0)
2. **Read on-demand:** `ptAmount` from `IERC20(PT).balanceOf(strategy)`, `maturityTime` from `IPrincipalToken(PT).expiry()`
3. Calculate amortized book value using linear pull-to-par formula
4. Support multiple PT markets with different maturities per vault
5. Record purchases and redemptions via authorized keeper role (updates tracked variables per update rules)
6. Return current book value for PPS calculation

### Non-Functional
- Deterministic: Same result at same block height (validator network consensus)
- Transparent: Events for all state changes (Hypernative monitoring)
- Gas efficient: View functions < 10k gas
- Safe: OpenZeppelin AccessControl, Math.mulDiv, and SafeCast
- Input validation: Sanity checks on keeper inputs (sySpent ≤ ptAmount)

## Technical Design

### Architecture

```
┌─────────────────┐     ┌──────────────────────────┐
│  SuperVault     │     │  PendlePTAmortizedOracle │
│  Strategy       │────▶│  ─────────────────────── │
└─────────────────┘     │  STORED (per vault/pt):  │
        │               │  - lastUpdateBookValue   │
        ▼               │  - lastUpdateTime        │
┌─────────────────┐     │                          │
│  Keeper         │────▶│  READ ON-DEMAND:         │
│  (records txns) │     │  - ptAmount from ERC20   │
└─────────────────┘     │  - maturityTime from PT  │
                        └──────────────────────────┘
                                  │
                                  ▼
                    ┌──────────────────────────┐
                    │  Strategy.totalAssets()  │
                    │  - getBookValue() for PT │
                    │  - + other assets        │
                    │  - / shares = PPS        │
                    └──────────────────────────┘
```

### Data Model

```solidity
// Only 2 variables need tracking - the rest are read on-demand
struct BookValueState {
    uint128 lastUpdateBookValue;  // B(t0): Book value at last update
    uint64 lastUpdateTime;        // t0: Timestamp of last update
}

mapping(address vault => mapping(address pt => BookValueState)) public bookValues;

// Read on-demand:
// ptAmount (A) = IERC20(pt).balanceOf(strategy)
// maturityTime (T) = IPrincipalToken(pt).expiry()
```

### API

```solidity
// Keeper functions (KEEPER_ROLE required) - update the 2 tracked variables
function recordPurchase(address vault, address strategy, address pt, uint256 sySpent) external;
function recordRedemption(address vault, address strategy, address pt, uint256 ptRedeemed) external;

// View functions (public)
function getBookValue(address vault, address strategy, address pt) external view returns (uint256);
```

## Implementation Plan

### Phase 1: Core Contract
- [ ] Create `PendlePTAmortizedOracle.sol` with minimal `BookValueState` storage
- [ ] Implement `_calculateBookValue()` with amortization formula (reads ptAmount & maturity on-demand)
- [ ] Implement `recordPurchase()` - updates lastUpdateBookValue and lastUpdateTime per update rules
- [ ] Implement `recordRedemption()` - updates with cost basis accounting per update rules
- [ ] Add AccessControl with KEEPER_ROLE and MANAGER_ROLE

### Phase 2: View Functions & Events
- [ ] Implement `getBookValue()` - reads ptAmount from balanceOf, maturity from expiry()
- [ ] Add events: BookValueUpdated

### Phase 3: Testing
- [ ] Unit tests for amortization math and edge cases
- [ ] Integration tests for full position lifecycle
- [ ] Fork tests against real Pendle markets

## Test Plan
- [ ] Unit tests for: `_calculateBookValue` formula, update rules (buy/sell)
- [ ] Integration tests for: full lifecycle, access control
- [ ] Fork tests for: real Pendle PT token integration (balanceOf, expiry)

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Keeper records incorrect values | Medium | High | Event monitoring, sanity checks |
| Keeper fails to record | Medium | Medium | Alerts, TWAP fallback |
| Overflow in calculations | Low | High | OpenZeppelin Math.mulDiv |

## Open Questions (Resolved)
| Question | Answer | Decided By |
|----------|--------|------------|
| Where should logic live? | New dedicated oracle | Cosmin |
| How to record purchases? | Keeper/executor call | Cosmin |
| Multi-market support? | Yes, per vault/market | Cosmin |
| Migration approach? | Fresh start | Cosmin |
| Fallback behavior? | Revert if no position | Cosmin |

## Interview Notes
See: [interview-notes.md](./interview-notes.md)

## Technical Details
See: [technical-spec.md](./technical-spec.md)

## Research
See: [research/](./research/)
- [sv-1095-proposal.md](./research/sv-1095-proposal.md) - Mathematical framework
- [repo-analysis.md](./research/repo-analysis.md) - Existing patterns
- [best-practices.md](./research/best-practices.md) - Industry practices
- [specflow-analysis.md](./research/specflow-analysis.md) - Flow analysis

---

## Approval
- [ ] Pod Leader Approved
- Approved date: ___

## Next Steps
After approval, run: `/superform:work specs/pendle-pt-amortized-pricing/technical-spec.md`
