# Managed Vault Architecture — How the Flow Works

> This document explains the proposed Managed Vault architecture: a **wrapper-based approach** that avoids forking the SuperVault family while giving portfolio managers full control over async ERC-7540 vault rails and manual NAV attestation.

---

## The Core Problem

The existing `ECDSAPPSOracle` uses N-of-M validator ECDSA signatures to price every SuperVault strategy. It works for automated strategies where a keeper sends signed PPS updates.

**Managed Vaults need something different:** a portfolio manager should be able to say "my vault's NAV is $1.05 per share" and post that directly on-chain — no ECDSA quorum, no keeper bots.

The constraint is that `SuperGovernor._activePPSOracle` is a **singleton**: one oracle contract prices all strategies system-wide.

**Failed approach (PR #326):** Fork the entire SuperVault family → `ManagedSuperVaultAggregator`, `ManagedNAVOracle`, `ManagedSuperVaultDepositQueue`. Two parallel vault systems to maintain.

**This approach:** One wrapper vault + one enhanced oracle. No SV forks.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│   INVESTOR                                                               │
│     │                                                                    │
│     │  1. requestDeposit(100 USDC)                                       │
│     ▼                                                                    │
│   ManagedVaultWrapper  ──── holds ────►  SuperVaultStrategy shares       │
│     │                                   (invested capital)               │
│     │  pendingDepositRequest[investor] = 100 USDC                        │
│     │                                                                    │
│   MANAGER                                                                │
│     │                                                                    │
│     │  2. updatePPSManaged(svStrategy, 1.05e6)                           │
│     │         ▼                                                          │
│     │   ManagedECDSAAppsOracle                                           │
│     │         │  checks: isManagedStrategy[svStrategy] == true           │
│     │         │  checks: msg.sender == mainManager(svStrategy)           │
│     │         ▼                                                          │
│     │   aggregator.forwardPPS(svStrategy, 1.05e6)  ← same as ECDSA path │
│     │   wrapper.totalAssets() now reads updated svStrategy PPS           │
│     │                                                                    │
│     │  3. fulfillDepositRequests([investor])                             │
│     │         shares = 100 USDC * PRECISION / 1.05e6                    │
│     │         claimableDepositShares[investor] = shares                  │
│     │                                                                    │
│   INVESTOR                                                               │
│     │  4. claimDeposit(investor, receiver)                               │
│     │         receives: wrapper shares                                   │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## The Three New Contracts

### 1. `ManagedECDSAAppsOracle`

Replaces `ECDSAPPSOracle` as the system-wide `_activePPSOracle`.

Has **two dispatch paths**:

```
updatePPS(UpdatePPSArgs)       ← existing ECDSA path (unchanged)
                                 validates N-of-M validator signatures
                                 calls aggregator.forwardPPS() for SV strategies
                                 BLOCKS managed strategies from using this path

updatePPSManaged(strategy, pps) ← new managed path
                                   `strategy` = svStrategy (NOT the wrapper)
                                   checks: isManagedStrategy[strategy] == true
                                   checks: msg.sender is the strategy's mainManager
                                   calls: aggregator.forwardPPS(strategy, pps)
                                   NO signatures required, NO timelock
                                   wrapper reads updated PPS via aggregator.getStoredPPS(svStrategy)
```

**Key guard:** Managed strategies CANNOT be priced via ECDSA. Regular SV strategies CANNOT be priced via the managed path. Clear separation.

**Migration:** Governor proposes new oracle → 7-day timelock → executes. Existing SV strategies are immediately priced by the new oracle using the same ECDSA validation.

### 2. `ManagedVaultWrapper`

A standalone **fully-async ERC-7540 vault** (both deposit AND redeem async).

- **Asset:** Any ERC-20 (e.g., USDC)
- **Underlying:** SuperVault strategy shares
- **NAV:** Stored in `storedPPS`, set by the oracle calling `setPPS()`
- **Investor gating:** Optional `isGated` flag — only allowlisted investors can `requestDeposit`

**Storage model:**
```
pendingDepositRequest[controller]   → assets waiting to be converted to shares
claimableDepositShares[controller]  → shares ready to claim after manager fulfills

pendingRedeemRequest[controller]    → shares locked waiting for fulfillment
claimableRedeemAssets[controller]   → assets ready to claim after manager fulfills

totalPendingDeposits                → sum of all pending deposit assets (for share price calc)
aggregator.getStoredPPS(svStrategy) → current NAV (set by manager via oracle → forwardPPS)
```

**Critical design:** `ManagedVaultWrapper` has NO own PPS storage. The oracle calls `aggregator.forwardPPS(svStrategy, pps)` — the same aggregator path used by automated ECDSA updates, just without signatures. The wrapper reads the SV strategy's PPS from the aggregator to compute `totalAssets()`. The wrapper is NOT registered in the aggregator; only the underlying `svStrategy` is.

### 3. `ManagedVaultWrapperFactory`

Simple minimal-proxy (clone) deployer. Governor-only.

```
createWrapper(asset, svStrategy, manager, isGated)
  → clone(wrapperImpl)
  → wrapper.initialize(svStrategy, manager, isGated, aggregator)
  → oracle.setManagedStrategy(svStrategy, true)   ← registers svStrategy (NOT wrapper)
  → emit WrapperCreated
```

---

## Full Deposit Flow

```
Step 1: Investor deposits
  investor.requestDeposit(100 USDC, controller=investor, owner=investor)
  → USDC transferred from investor → wrapper
  → pendingDepositRequest[investor] += 100e6

Step 2: Manager deploys capital (optional, off-chain decision)
  manager calls SV: IERC4626(svStrategy).deposit(pendingUSDC, address(wrapper))
  → wrapper now holds svStrategy shares

Step 3: Manager attests NAV
  manager.updatePPSManaged(svStrategy, 1_050_000)  // $1.05 per SV share
  → oracle validates manager is authorized
  → aggregator.forwardPPS(svStrategy, 1_050_000)
  → aggregator stores: _strategyData[svStrategy].pps = 1_050_000

Step 4: Manager fulfills deposit requests
  manager.fulfillDepositRequests([investor])
  → wrapper reads svPPS = aggregator.getStoredPPS(svStrategy) = 1_050_000
  → wrapper computes pre-deposit NAV: totalSVAssets = svShares * svPPS / svPrecision
  → priorAssets = totalSVAssets - totalPendingDeposits
  → for investor: shares = 100e6 * priorSupply / priorAssets
  → claimableDepositShares[investor] = 95_238_095_238_095_238_095 (18 decimals)
  → pendingDepositRequest[investor] = 0

Step 5: Investor claims shares
  investor.claimDeposit(investor, receiver)
  → wrapper transfers shares to receiver
  → investor now holds managed vault wrapper shares
```

---

## Full Redeem Flow

```
Step 1: Investor requests redeem
  investor.requestRedeem(50 shares, controller=investor, owner=investor)
  → shares transferred from investor → wrapper (held pending)
  → pendingRedeemRequest[investor] = 50 shares

Step 2: Manager handles SV redemption (off-chain coordination)
  manager calls SV: ISuperVaultStrategy(svStrategy).requestRedeem(svShares, wrapper, wrapper)
  → wait for SV's own async redeem cycle to complete
  → ISuperVaultStrategy(svStrategy).claimRedeem(wrapper, wrapper)
  → wrapper now holds USDC

Step 3: Manager attests NAV (may be at different PPS than at deposit time)
  manager.updatePPSManaged(svStrategy, 1_100_000)  // $1.10 per SV share
  → aggregator.forwardPPS(svStrategy, 1_100_000)

Step 4: Manager fulfills redeem requests
  manager.fulfillRedeemRequests([investor], [55_000_000])  // 50 shares × $1.10
  → burns 50 wrapper shares
  → claimableRedeemAssets[investor] = 55e6
  → pendingRedeemRequest[investor] = 0

Step 5: Investor claims assets
  investor.claimRedeem(investor, receiver)
  → wrapper transfers 55 USDC to receiver
```

---

## NAV Is Manager-Attested, Not Derived

This is the most important conceptual point:

**The wrapper's NAV IS derived from the SV strategy's PPS stored in the aggregator.**

The manager calls `updatePPSManaged(svStrategy, value)` which flows to `aggregator.forwardPPS(svStrategy, value)`. This sets the SV strategy's on-chain PPS. The wrapper's `totalAssets()` then reads:
```
totalAssets = svShares × aggregator.getStoredPPS(svStrategy) / svPrecision
```

The manager-attested value can reflect:
- The market value of the underlying positions in the SV strategy
- A blended NAV accounting for off-chain assets or loans
- A manually audited fund administrator NAV

No compound PPS layers: one PPS (on the svStrategy) → one NAV (on the wrapper).

---

## Why Not Fork SuperVault?

The existing approach (PR #326) forks the SV family:

```
PR #326:
  ManagedSuperVaultAggregator  ← new aggregator
  ManagedNAVOracle             ← new oracle (separate from active PPS oracle)
  ManagedSuperVaultDepositQueue ← new deposit queue
  + modified SuperVault, SuperVaultStrategy
```

Problems:
- Two aggregators to maintain, upgrade, audit
- `ManagedNAVOracle` is NOT the `_activePPSOracle` — it's a side-channel, not integrated with the main PPS system
- Duplicated infrastructure: vault impl, strategy impl, escrow impl, aggregator

**Wrapper approach:**
- One new oracle (replaces existing, same interface for SV strategies)
- One new vault (standalone, not in SV family)
- Zero changes to SuperVaultAggregator, SuperVault, SuperVaultStrategy
- Manager attests NAV via `updatePPSManaged(svStrategy, pps)` → same `aggregator.forwardPPS()` call used by automated oracles, just without ECDSA signatures

---

## Security Considerations

### NAV Manipulation Risk
Manager can set any PPS before fulfilling redeems. A malicious manager could:
1. Lower PPS → fulfill redeems → investors receive fewer assets per share
2. Raise PPS → fulfill deposits → investors receive fewer shares per asset

**Mitigation:** `maxPPSChangeBps` bound (e.g., 10% per update). Guardian pause. Investor allowlist gives manager control over who can participate, reducing incentive for manipulation.

### Oracle Singleton Risk
`ManagedECDSAAppsOracle` prices all strategies. A bug in `updatePPSManaged` could affect SV strategy pricing if routing guard fails.

**Mitigation:** Hard separation — managed strategies are blocked from ECDSA path, SV strategies are blocked from managed path. Separate storage, separate execution paths.

### First Depositor Attack
Empty vault: attacker deposits 1 wei, donates assets directly, inflates exchange rate.

**Mitigation:** 1000 dead shares burned to `0xdead` in wrapper constructor.

### ERC-7540 Accounting
Pending state must be correctly transitioned to claimable. Classic vulnerability in async vaults (Lagoon Finance audit findings).

**Mitigation:** CEI pattern, nonReentrant on all state-changing functions, invariant fuzz tests.

---

## Invariants

```solidity
// 1. No shares created without pending deposits
assert(totalMintedEver == totalFulfilledDeposits + deadShares);

// 2. No assets distributed without pending redeems
assert(totalAssetsOut <= totalPendingRedeemAssets);

// 3. PPS staleness gates operations
assert(!isPPSStale() || (noDepositFulfills && noRedeemFulfills));

// 4. Managed and ECDSA paths don't cross
assert(forall s: isManagedStrategy[s] → ppsNotSetByECDSA(s));
assert(forall s: !isManagedStrategy[s] → ppsNotSetByManaged(s));
```

---

## Oracle Migration Steps (Production)

```
1. Deploy ManagedECDSAAppsOracle(superGovernor, name, version)

2. Transfer all managed strategy registrations:
   for each future wrapper: oracle.setManagedStrategy(wrapper, true)

3. Propose oracle change (SUPER_GOVERNOR_ROLE):
   superGovernor.proposeActivePPSOracle(address(newOracle))

4. Wait 7 days (TIMELOCK)

5. Execute change (permissionless):
   superGovernor.executeActivePPSOracleChange()

6. Verify:
   assert(superGovernor.isActivePPSOracle(address(newOracle)) == true)

7. Existing SV keepers start signing against new oracle's domain separator
   (Update off-chain signing config: new oracle address for EIP-712 domain)
```

---

## Files to Create

```
src/
  oracles/
    ManagedECDSAAppsOracle.sol        ← New: extends ECDSAPPSOracle
  SuperVault/
    ManagedVaultWrapper.sol           ← New: ERC-7540 vault
    ManagedVaultWrapperFactory.sol    ← New: minimal-proxy factory
  interfaces/
    SuperVault/
      IManagedVaultWrapper.sol        ← New: interface

test/
  unit/
    ManagedECDSAAppsOracle.t.sol      ← Unit tests
    ManagedVaultWrapper.t.sol         ← Unit tests + fuzz invariants
  integration/
    SuperVault/
      ManagedVaultWrapper.fork.t.sol  ← Fork test on Base mainnet
```

No other files need to be modified.
