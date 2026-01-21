# Pendle PT Amortized Pricing Oracle Spec

## Metadata
- Project: v2-periphery
- Milestone: PT Pricing Improvements
- Linear Issue: SV-1095
- Interview Date: 2026-01-21
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

Implement a new `PendlePTAmortizedOracle` contract that provides **amortized cost pricing** for Pendle PT positions in SuperVaults. This replaces volatile mark-to-market pricing with deterministic, linear pull-to-par pricing suitable for the "Boring Strategy" (hold-to-maturity).

The oracle tracks positions using Book Value accounting: `B(t) = A - (A - B(t0)) × (T - t) / (T - t0)`, where the price linearly converges from purchase price to face value at maturity. A keeper records purchases/redemptions, and the pricing service reads the amortized value for PPS calculation.

## Requirements

### Functional
1. Track PT positions per vault/market using state: (A, t0, B(t0), T)
2. Calculate amortized book value using linear pull-to-par formula
3. Support multiple PT markets with different maturities per vault
4. Record purchases and redemptions via authorized keeper role
5. Return current book value and derived price-per-PT for pricing service integration

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
└─────────────────┘     │  positions[vault][market]│
        │               │  - ptAmount (A)          │
        │               │  - bookValue (B(t0))     │
        ▼               │  - lastUpdateTime (t0)   │
┌─────────────────┐     │  - maturityTime (T)      │
│  Keeper         │────▶│                          │
│  (records txns) │     └──────────────────────────┘
└─────────────────┘               │
                                  ▼
                    ┌──────────────────────────┐
                    │  Pricing Service         │
                    │  - Reads getBookValue()  │
                    │  - Applies Step 3 conv   │
                    │  - Pushes PPS            │
                    └──────────────────────────┘
```

### Data Model

```solidity
struct Position {
    uint128 ptAmount;        // A: Total PT held
    uint128 bookValue;       // B(t0): Book value at last update
    uint64 lastUpdateTime;   // t0: Timestamp of last update
    uint64 maturityTime;     // T: PT maturity timestamp
    uint128 _reserved;       // Future use
}

mapping(address vault => mapping(address market => Position)) positions;
```

### API

```solidity
// Keeper functions (KEEPER_ROLE required)
function recordPurchase(address vault, address market, uint256 ptAmount, uint256 sySpent) external;
function recordRedemption(address vault, address market, uint256 ptAmount) external;

// View functions (public)
function getBookValue(address vault, address market) external view returns (uint256);
function getPricePerPt(address vault, address market) external view returns (uint256);
function getPosition(address vault, address market) external view returns (...);
```

## Implementation Plan

### Phase 1: Core Contract
- [ ] Create `PendlePTAmortizedOracle.sol` with Position struct and storage
- [ ] Implement `_calculateBookValue()` with amortization formula
- [ ] Implement `recordPurchase()` with position init/update logic
- [ ] Implement `recordRedemption()` with cost basis accounting
- [ ] Add AccessControl with KEEPER_ROLE and MANAGER_ROLE

### Phase 2: View Functions & Events
- [ ] Implement `getBookValue()`, `getPricePerPt()`, `getPosition()`
- [ ] Add events: PositionOpened, PositionIncreased, PositionReduced
- [ ] Implement `getVaultMarkets()` for position enumeration

### Phase 3: Testing
- [ ] Unit tests for amortization math and edge cases
- [ ] Integration tests for full position lifecycle
- [ ] Fork tests against real Pendle markets

## Test Plan
- [ ] Unit tests for: `_calculateBookValue`, weighted average updates, cost basis
- [ ] Integration tests for: full lifecycle, multi-market, access control
- [ ] Fork tests for: real Pendle market integration

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
