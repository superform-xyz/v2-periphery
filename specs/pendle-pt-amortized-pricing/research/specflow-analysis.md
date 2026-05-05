# SpecFlow Analysis: Pendle PT Amortized Pricing Oracle

## Critical Questions Requiring Clarification

### 🔴 CRITICAL (Blocks Implementation)

**Q1: How is maturity time T initialized on first purchase?**
- **Answer**: Read from PT contract via `IPPrincipalToken(pt).expiry()` where PT is obtained from `IPMarket(market).readTokens()`

**Q2: What is the exact formula for updating B(t0) on subsequent purchases?**
- **Answer**: From SV-1095 proposal:
  - First calculate current B(t): `B(t) = A - (A - B(t0)) × (T - t) / (T - t0)`
  - New B(t0) = B(t) + (additionalPT × price)
  - New A = A + additionalPT
  - New t0 = t (current time)

**Q3: How does the formula handle t = T and t > T?**
- **Answer**: Special case - if `t >= T`, return `B(T) = A` (face value). The formula naturally converges to A at maturity.

**Q4: Should recordRedemption validate that ptAmount <= A?**
- **Answer**: Yes, require `ptAmount <= A`, revert with `INSUFFICIENT_POSITION` otherwise.

**Q5: What are the exact parameter types for vault and market?**
- **Answer**:
  - `vault`: address (SuperVault contract)
  - `market`: address (Pendle Market address, not PT token)
  - Market is used to derive PT via `readTokens()`

**Q6: How is the Admin role initialized on deployment?**
- **Answer**: Constructor takes `admin` address parameter, grants `DEFAULT_ADMIN_ROLE` and `MANAGER_ROLE` to admin.

**Q7: What units/decimals are ptAmount, sySpent, and B(t) in?**
- **Answer**: All use 18 decimals (standard). PT amount in PT decimals, sySpent/B(t) in SY decimals (typically 18).

---

## Key Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| First purchase | Initialize A, t0, B(t0), T from PT contract |
| Purchase at/after maturity | Revert with `MARKET_EXPIRED` |
| Redemption > holdings | Revert with `INSUFFICIENT_POSITION` |
| Query at maturity (t=T) | Return B(T) = A |
| Query after maturity (t>T) | Return B(T) = A (capped) |
| Query no position | Revert with `NO_POSITION` |
| Full redemption (A→0) | Keep state with A=0, subsequent queries return 0 |
| Zero amount purchase | Revert with `ZERO_AMOUNT` |

---

## Events Required

```solidity
event PositionOpened(
    address indexed vault,
    address indexed market,
    uint256 ptAmount,
    uint256 bookValue,
    uint256 maturityTimestamp
);

event PositionIncreased(
    address indexed vault,
    address indexed market,
    uint256 additionalPt,
    uint256 newTotalPt,
    uint256 newBookValue
);

event PositionReduced(
    address indexed vault,
    address indexed market,
    uint256 redeemedPt,
    uint256 remainingPt,
    uint256 remainingBookValue
);
```

---

## Integration Flow

```
Strategy executes PT buy on Pendle
    ↓
Keeper monitors strategy transactions
    ↓
Keeper calls recordPurchase(vault, market, ptAmount, sySpent)
    ↓
Oracle stores: A, t0, B(t0), T
    ↓
Pricing service calls getBookValue(vault, market)
    ↓
Oracle calculates B(t) using amortization formula
    ↓
Pricing service applies Step 3 conversion (SY→Asset)
    ↓
Pricing service pushes PPS to aggregator
```
