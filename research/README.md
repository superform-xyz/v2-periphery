# Pre-Skim Deposit Analysis: Economic & Business Justification

**For Auditors:** This document explains why we keep performance fee skimming separate from PPS updates, despite the theoretical possibility of users experiencing small value decreases when depositing before skim events.

---

## Simulation Assumptions (Simple Reference)

All analysis based on the following parameters:

**Vault Parameters:**
- TVL: $100M (also tested at $10M, $50M, $250M)
- APY: 10% annual yield
- Performance Fee: 20% on profits above high-water mark
- Superform Protocol Fee: 50% of performance fees
- Deposits: 100 random deposits per day (200% TVL annual volume)

**Gas Cost Assumptions:**
- Gas Price: 20 gwei
- ETH Price: $3,000
- PPS Update: 88,000 gas (~$5.28 per update)
- Separate Skim: 87,000 gas (~$5.22 per skim)
- Integrated Skim: 146,000 gas per combined operation (~$8.76)

**Current Operations:**
- PPS updates: 24x per day (hourly) = 8,760/year
- Skim calls: 1x per day (daily) = 365/year
- **Annual gas cost: $48,164** (8,760 × $5.28 + 365 × $5.22)

**Integrated Operations:**
- Combined PPS + Skim: 24x per day = 8,760/year
- **Annual gas cost: $76,738** (8,760 × $8.76)
- **Extra cost: $28,574/year**

**Yield Strategy Types Tested:**
- Continuous yield (lending protocols, AMMs)
- Daily harvest (daily reward claims)
- Weekly harvest (weekly reward farming)
- Monthly harvest (monthly reward farming)

---

## The Mechanism: How Pre-Skim Deposits Work

### Current Implementation (PPS-Based HWM)

Our vaults use a **price-per-share (PPS) based high-water mark** for performance fee collection:

1. **Yield accrues** → `totalAssets` increases → PPS rises above HWM
2. **User deposits** at current PPS (e.g., 1.0010)
3. **Manager calls `skimPerformanceFee()`**:
   ```solidity
   // Calculate profit above HWM (per-share basis)
   uint256 ppsGrowth = currentPPS - hwmPPS;
   uint256 profit = ppsGrowth * totalSupply;
   uint256 fee = profit * 0.20;  // 20% performance fee

   // Extract fees (50% to Superform, 50% to strategy manager)
   _safeTokenTransfer(treasury, fee * 0.50);
   _safeTokenTransfer(recipient, fee * 0.50);

   // PPS drops after fee extraction
   uint256 newPPS = (totalAssets - fee) / totalSupply;  // e.g., 1.0008
   vaultHwmPps = newPPS;
   ```

4. **User's shares now worth slightly less**: Deposited at 1.0010, now worth 1.0008

This is **by design** - performance fees must be extracted from vault assets, which proportionally affects all share values including newly minted ones.

---

## Quantitative Analysis: User Losses vs Integration Costs

We simulated **4 yield strategy types** over 365 days at $100M TVL with 10% APY:

| Strategy Type | User Losses/Year | Avg Loss/Deposit | Max Loss | Integration Gas Cost | Net Economic Impact |
|---------------|------------------|------------------|----------|---------------------|---------------------|
| **Continuous Yield** (lending, AMMs) | $4,799 | 0.0026% | 0.005% | $28,574 | **-$23,775** ❌ |
| **Daily Harvest** | $415 | 0.0009% | 0.006% | $28,579 | **-$28,164** ❌ |
| **Weekly Harvest** | $419 | 0.0006% | 0.013% | $30,422 | **-$30,003** ❌ |
| **Monthly Harvest** | $375 | 0.0006% | 0.156% | $30,422 | **-$30,047** ❌ |

### Key Insights

**1. Losses Are Negligible**
- Average loss: **0.0006-0.0026%** per affected deposit
- On a $1,000 deposit: user loses **$0.06-0.26** (6-26 cents)
- Total annual impact: **$375-4,799** across thousands of deposits

**2. Integration Costs Outweigh Benefits**
- Extra gas for hourly skims: **$28,600-30,400/year**
- User losses prevented: **$375-4,800/year**
- **Net loss to protocol: 6-81x** the benefit to users

**3. Discrete Harvests Are Not Worse**
Contrary to initial assumptions, less frequent harvests result in LOWER total losses:
- **Continuous yield**: 96% of deposits exposed (23hr window/day) → higher total losses
- **Monthly harvest**: Only 0.14% of deposits exposed (1hr window/month) → lower total losses
- Larger per-deposit loss (0.156% max) but far fewer users affected

**4. Why Losses Are So Small**
With 10% APY:
- Daily growth: 0.026% → 20% fee = **0.005% PPS drop**
- Weekly growth: 0.18% → 20% fee = **0.036% PPS drop**
- Monthly growth: 0.8% → 20% fee = **0.16% PPS drop**

Even the "worst case" monthly scenario results in <0.2% impact for <1% of depositors.

---

## Visual Evidence: PPS Evolution Charts

We've generated charts showing PPS evolution over time (see `/research/pps_*.png`):

### What the Charts Show

```
Continuous Yield:
├─ Gradual PPS increase (hourly compounding)
├─ Small frequent skim corrections (~0.005%)
└─ Long exposure windows (23hr/day)

Weekly Harvest:
├─ Flat PPS for 7 days
├─ Sudden jump at harvest (+0.18%)
├─ Skim correction 1hr later (-0.036%)
└─ Short exposure window (1hr/week)

Monthly Harvest:
├─ Flat PPS for 30 days
├─ Large jump at harvest (+0.8%)
├─ Skim correction 1hr later (-0.16%)
└─ Short exposure window (1hr/month)
```

The orange "User Loss Windows" in the visualizations clearly demonstrate:
- **Magnitude**: PPS drops are minimal (0.005-0.16%)
- **Frequency**: Most strategies use continuous/daily yield (highest frequency)
- **Exposure**: Actual affected user percentage is very small

---

## Appendix: Simulation Methodology

**Tools:** `/research/pre_skim_user_loss_analysis.py` + `visualize_pps_evolution.py`

**Parameters:**
- TVL: $100M
- APY: 10%
- Performance fee: 20% (50% to Superform)
- Deposits: 100/day randomly distributed
- Simulation period: 365 days

**Tested scenarios:**
- Continuous yield (hourly accrual)
- Daily harvest (1-day accumulation)
- Weekly harvest (7-day accumulation)
- Monthly harvest (30-day accumulation)

**Gas costs** (20 gwei @ $3,000 ETH):
- Separate: ~$48k/year (8,760 PPS updates + 365 skims)
- Integrated: ~$76k/year (8,760 combined operations)

**Code references:**
- Skim implementation: `src/SuperVault/SuperVaultStrategy.sol:367-443`
- PPS updates: `src/SuperVault/SuperVaultAggregator.sol` (`_forwardPPS`)
- HWM tracking: `SuperVaultStrategy.sol:384` (`vaultHwmPps`)

---

**For questions or additional analysis, contact Superform Labs.**
