# SV-1095 - PT Pricing Proposal for the Boring Strategy

**Source:** Internal research document by quant team

## High Level Idea

Pricing PTs with their market price is conservative (always marked to market) but has downsides:
- High volatility due to thin Pendle AMM/OB liquidity

For the **Boring Strategy** (buy PT, hold to maturity), we use **linear discounting with amortized-cost accounting**.

---

## Mathematical Framework

### Single Purchase Formula

$$
\text{Value}(t) = P_0 + (1 - P_0) \cdot \frac{t - t_0}{T - t_0}
$$

Where:
- $P_0$ = purchase price
- $t_0$ = purchase time
- $T$ = maturity time

### Multiple Purchases - Weighted Averages

For purchases $(A_i, P_i, t_i)$:

$$
\tilde{P} = \frac{\sum_{i=1}^{n} A_i P_i}{\sum_{i=1}^{n} A_i}
$$

$$
\tilde{t}_0 = \frac{\sum_{i=1}^{n} A_i t_i}{\sum_{i=1}^{n} A_i}
$$

---

## Inventory Pricing Framework (Recommended)

### State Variables

- $T$ = PT Maturity (param)
- $A$ = Total PT amount held
- $t_0$ = Last time $A$ changed
- $B(t_0)$ = Last book value update

### Book Value Formula

$$
B(t; A, t_0, T) = A - (A - B(t_0)) \cdot \frac{T - t}{T - t_0}
$$

**Properties:**
- At $t = t_0$: $B(t_0) = B(t_0)$ ✓
- At $t = T$: $B(T) = A$ (face value) ✓
- Linear interpolation between

---

## Update Rules

### Initialization
When buying $A$ PTs at price $P$:
$$B(t_0) = A \cdot P$$

### Buying More PTs
When buying $\Delta A$ PTs at price $P$:
1. $B(t) \leftarrow B(t; A, t_0, T) + \Delta A \cdot P$
2. $A \leftarrow A + \Delta A$
3. $t_0 \leftarrow t$

### Selling PTs
When selling $\Delta A$ PTs at price $P$:

First calculate cost basis:
$$c(t) = \frac{B(t)}{A}$$

Then update:
1. $B(t) \leftarrow B(t; A, t_0, T) - \Delta A \cdot c(t)$
2. $A \leftarrow A - \Delta A$
3. $t_0 \leftarrow t$

Realized PnL:
$$\text{PnL} = \Delta A \cdot (P - c(t))$$

---

## Numerical Example

**Setup:** T = 100

| Trade | Time | Action | Price | A | B(t) | Notes |
|-------|------|--------|-------|---|------|-------|
| 1 | 0 | Buy 100 | 0.90 | 100 | 90 | Initial |
| 2 | 20 | Buy 50 | 0.92 | 150 | 138 | B(20)=92, +46 |
| 3 | 50 | Buy 25 | 0.95 | 175 | 166.25 | B(50)=142.5, +23.75 |
| 4 | 70 | Sell 60 | 0.96 | 115 | 111.55 | c=0.97, PnL=-0.6 |

---

## Key Insight

The **Book Value approach** is cleaner than tracking average price + average time:
- Directly tracks what matters for PPS calculation
- Natural handling of buys and sells
- Cost basis automatically derived as $B(t)/A$
