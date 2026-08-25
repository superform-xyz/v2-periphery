# Cross-Chain SuperVaults Spec

## Metadata
- Project: v2-periphery
- Milestone: Cross-Chain Yield Deployment
- Linear Issue: N/A
- Interview Date: 2026-08-25
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved
- Security: adversarial review 2026-08-25 — 17 findings; RESOLVED items folded into technical-spec, **7 OPEN items require decisions before build** (see below)

> ### ⚠ Open Security Decisions (blocking build)
> From the adversarial review (full detail in [technical-spec.md](./technical-spec.md#security-findings--required-mitigations)):
> - **SEC-1 (Critical)** — "only bridging leaf" is not on-chain-enforceable: a rogue manager can bridge via a raw bridge leaf in their own strategy root. Pick a mitigation (deploy-time exclusion of raw bridge hooks / cap-aware bridge hooks / on-chain root screening).
> - **SEC-10 (High)** — guardian veto window is a global 15-min timelock; gate cross-chain root proposals behind GOVERNOR_ROLE or add a per-strategy timelock (aggregator change).
> - **SEC-7** — define `_getHubChainAssets` (cap denominator) against a flash-loan-robust source.
> - **SEC-8** — add on-chain PPS↔AUM consistency band.
> - **SEC-13** — deviation soft-fail currently blocks booking a real >50% loss; add circuit breaker + forced-update path.
> - **SEC-14** — specify `values[]` denomination + per-position deviation bound.
> - **SEC-16** — anchor zero-crossing/first AUM report.
>
> Until SEC-1 and SEC-10 are resolved, the cap system does NOT bind a rogue/compromised main manager.

## Summary

Enable SuperVaults to deploy yield across multiple chains while maintaining all accounting and share management on a single hub chain (per-vault). Four new composable contracts (CrossChainPositionRegistry, CrossChainAUMOracle, CrossChainPositionCapGuard, CapGuardedBridgeHook) extend the existing SuperVault system without modifying any core contracts. CapGuardedBridgeHook is the ONLY authorized bridging leaf for cross-chain strategies: it performs the cap check and the bridge send atomically in one hook, so the check cannot be omitted from a hook chain. Cross-chain deposits reuse the existing SuperExecutor intent flow, withdrawals use the existing ERC7540 async redemption path, and PPS updates use the existing `forwardPPS()` oracle pipeline.

The architecture is generic but the first implementation targets the FXRP vault on Flare with Stellar yield sources managed externally by Bizantine. Key use cases include singular stock products bridging to find best yield, basis trades on HyperCore, and carry/leverage strategies.

## Requirements

### Functional
1. Track cross-chain positions with full lifecycle (Pending -> Active -> WindingDown -> Exited) via CrossChainPositionRegistry
2. Accept quorum-signed PER-POSITION AUM reports (positionIds[], values[]) via CrossChainAUMOracle; aggregate derived on-chain; a report must cover every non-Exited position (completeness rule)
3. Enforce cross-chain allocation caps (global BPS + per-chain) atomically via CapGuardedBridgeHook (cap policy views/config live in CrossChainPositionCapGuard)
4. Reject cross-chain deployments when AUM data is stale (fail-safe); unconfigured strategies (zero maxStaleness) are blocked by default
5. Auto-invalidate unconfirmed positions after timeout (2 hours); confirmation is implicit - Pending -> Active on first inclusion in a quorum-signed report
6. AUM oracle integrity config (`setAUMOracleConfig`) gated to ORACLE_MANAGER_ROLE with hard bounds (NOT the strategy manager)
7. No raw Across/deBridge hook leaves in any root of a cross-chain-enabled strategy (root-generation lint + guardian veto)
8. Support cross-chain deposits via existing SuperExecutor intent flow (no changes)
9. Support async withdrawals via existing ERC7540 flow when buffer insufficient (no changes)

### Non-Functional
- Zero modifications to existing SuperVault, SuperVaultStrategy, SuperVaultAggregator, SuperVaultEscrow
- All AUM oracle validations mirror PPS oracle (timestamp monotonicity, staleness, rate limiting, deviation threshold)
- Gas-efficient: packed storage, EnumerableSet for O(1) lookups
- Oracle-reported AUM for cap enforcement (flash-loan resistant, not on-chain balances)

## Technical Design

### Architecture

```
Hub Chain (per-vault):
  SuperVault [UNCHANGED] -> SuperVaultStrategy [UNCHANGED]
      |
  CrossChainPositionRegistry [NEW]  <-- CrossChainAUMOracle [NEW]
      |
  CrossChainPositionCapGuard [NEW]  -- cap policy (views + config)
      |
  CapGuardedBridgeHook [NEW]  -- atomic: cap check + bridge send;
      |                          wraps Across V3 / deBridge [EXISTING];
      |                          the ONLY authorized bridging leaf
  SuperVaultAggregator [UNCHANGED]  -- stores PPS

Spoke Chains:
  Existing SuperDestinationExecutor [UNCHANGED]
  (raw Across/deBridge hook leaves are NEVER approved for
   cross-chain-enabled strategies - root hygiene invariant)
```

### Data Model

**CrossChainPosition:**
- chainId, targetProtocol, targetAsset, deployedAmount
- lastReportedValue, lastReportTimestamp
- status (Pending/Active/WindingDown/Exited)
- registeredAt (for timeout)

**AUMReport (signed payload is per-position; struct below is the on-chain aggregate cache):**
- signed: positionIds[], values[], timestamp, nonce
- cached: totalCrossChainAssets (= sum(values), derived on-chain), timestamp, nonce

**AUMOracleConfig (per strategy, ORACLE_MANAGER_ROLE-set, hard-bounded):**
- maxStaleness, minUpdateInterval, deviationThreshold

**CapConfig:**
- maxCrossChainBps (global), perChainCap mapping

### API Changes

**New Contracts:**

| Contract | Key Functions |
|---|---|
| CrossChainPositionRegistry | `registerPosition()`, `syncPositionFromReport()` (onlyAUMOracle - single oracle write path), `beginPositionExit()`, `deregisterPosition()`, `getCrossChainAUM()`, `getChainExposure()` |
| CrossChainAUMOracle | `forwardAUM(positionIds[], values[], ...)` (quorum-signed, complete reports), `setAUMOracleConfig()` (ORACLE_MANAGER_ROLE), `isAUMFresh()`, `getTotalAUM()` |
| CrossChainPositionCapGuard | `validateAllocation()` (view), `setCapConfig()` (manager-or-governor) |
| CapGuardedBridgeHook | atomic `validateAllocation` + bridge send; `inspect()` pins (guard, bridge target, chainId) in the Merkle leaf |

**SuperGovernor additions:**
- `CROSS_CHAIN_POSITION_REGISTRY` address key
- `CROSS_CHAIN_AUM_ORACLE` address key
- `CROSS_CHAIN_CAP_GUARD` address key

## Implementation Plan

### Phase 1: Core Position Tracking
- [ ] Implement CrossChainPositionRegistry with position lifecycle
- [ ] Implement registrar role management (per-strategy, set by primary manager)
- [ ] Position confirmation is implicit: Pending -> Active on first inclusion in a quorum-signed AUM report via `registry.syncPositionFromReport()` (no separate confirm tx)
- [ ] Add position timeout auto-invalidation
- [ ] Unit tests for registry

### Phase 2: AUM Oracle
- [ ] Implement CrossChainAUMOracle with ECDSA quorum validation over per-position reports (aggregate derived on-chain)
- [ ] Implement all validation properties (timestamp, staleness, rate limit, deviation on the aggregate)
- [ ] Implement report completeness check (INCOMPLETE_REPORT if any non-Exited position missing)
- [ ] Implement `setAUMOracleConfig` (ORACLE_MANAGER_ROLE, hard bounds; zero config = blocked)
- [ ] Integrate with CrossChainPositionRegistry via `syncPositionFromReport`
- [ ] Unit tests for oracle

### Phase 3: Cap Enforcement
- [ ] Implement CrossChainPositionCapGuard (policy views + config) with global + per-chain caps
- [ ] Implement CapGuardedBridgeHook: atomic cap check + bridge send in one hook (the only bridging leaf); reverts on cap breach or stale AUM
- [ ] Add root-lint to root-generation tooling: reject raw bridge hook leaves for cross-chain strategies
- [ ] Add AUM freshness gate (stale data blocks deployments)
- [ ] Unit tests for cap guard and CapGuardedBridgeHook

### Phase 4: Integration & Testing
- [ ] Register new contracts in SuperGovernor; register CapGuardedBridgeHook via hook lifecycle (`registerHook` + root proposal)
- [ ] Per-strategy onboarding order: registry keys -> `setAUMOracleConfig` -> `setCapConfig` -> approve CapGuardedBridgeHook leaf -> set registrar
- [ ] Fork tests with simulated cross-chain messaging
- [ ] Invariant tests (positions <= AUM, caps always respected)
- [ ] Fuzz tests for cap boundary conditions
- [ ] End-to-end scenario tests

### Phase 5: FXRP Deployment
- [ ] Deploy to Flare (hub chain for FXRP vault)
- [ ] Configure registrar for FXRP strategy
- [ ] Set cap configuration for initial deployment
- [ ] Coordinate with Bizantine on Stellar yield source parameters

## Test Plan
- [ ] Unit tests for: CrossChainPositionRegistry, CrossChainAUMOracle, CrossChainPositionCapGuard, CapGuardedBridgeHook
- [ ] Negative tests for: incomplete AUM reports revert, unconfigured strategy blocked, hook chain without CapGuardedBridgeHook cannot bridge (no raw bridge leaves in roots)
- [ ] Fork tests for: full cross-chain deposit/bridge/register/update flow
- [ ] Invariant tests for: position count <= AUM, cap never exceeded, PPS * supply ~= AUM
- [ ] Fuzz tests for: cap enforcement boundaries, AUM deviation checks
- [ ] Scenario tests for: stale AUM blocks cross-chain deployments, liquidation lag, bridge timeout, double-counting prevention, Pending timeout invalidation

## Risks & Mitigations
| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| **Rogue manager bridges via raw bridge leaf in own strategy root** | Access Control | **Medium** | **Critical** | **OPEN (SEC-1)**: atomic hook stops ordering bypass only; raw bridge hooks are globally registered - needs deploy-time exclusion / cap-aware bridge hooks / on-chain root screening. See technical-spec Security Findings | - |
| Rogue manager raises own cap | Access Control | Medium | Critical | SEC-2: cap loosening governor+timelocked | - |
| Cap overshoot via pipelined in-flight bridges | Cross-Chain | Medium | High | SEC-3: bridgedOut accumulator counts in-flight capital | - |
| False position registration inflates PPS | Position Registration | Low | Critical | Positions enter AUM only via quorum-signed reports (implicit confirmation); registrar SHOULD be multisig | Wormhole 2022 - $320M |
| AUM oracle compromise | Oracle | Low | Critical | M-of-N quorum + deviation threshold | Ronin 2022 - $625M |
| Cap bypass via flash loan | Flash Loan | Medium | High | Oracle-reported AUM (not balances) | Euler 2023 - $197M |
| Bridge fill failure leaves phantom position | Cross-Chain | Medium | Medium | Pending status, 2h timeout, no AUM impact until confirmed | - |
| Double-counting during position exit | Vault Accounting | Medium | High | Atomic deregistration on bridge callback | - |
| Stale position data after remote liquidation | Oracle | Medium | High | AUM deviation threshold flags large drops | - |
| Registrar key compromise | Access Control | Low | High | Multi-sig/quorum for registrar role | Multichain 2023 - $130M |
| Manager omits cap check from hook chain | Access Control | Medium | Critical | Atomic CapGuardedBridgeHook - the only bridging leaf contains the check | - |
| Raw bridge hook leaf added via manager root proposal | Access Control | Low | Critical | Guardian veto + automated root lint | - |
| Oracle omits losing positions from report | Oracle | Medium | High | Completeness check (report must cover all non-Exited positions) | - |
| Manager loosens AUM staleness/deviation config | Access Control | Medium | High | Config is ORACLE_MANAGER_ROLE-gated with hard bounds | - |

## Open Questions (Resolved)
| Question | Answer | Decided By |
|----------|--------|------------|
| Hub chain selection | Per-vault decision (FXRP on Flare) | Cosmin |
| Stellar bridging | External to SuperVaults (Bizantine handles) | Cosmin |
| OFT for shares | Not needed, shares stay ERC20 on hub | Cosmin |
| Deposit mechanism | Reuse SuperExecutor intent flow | Cosmin |
| Position tracking | Role-based registrar + oracle confirmation | Cosmin |
| Buffer management | Manager discretion (no enforced target) | Cosmin |
| Position caps | On-chain enforcement during executeHooks() | Cosmin |
| AUM for caps | Separate AUM oracle (avoids circular dependency) | Cosmin |
| Integration style | New composable contracts (non-breaking) | Cosmin |
| FXRP yield sources | TBD with Bizantine | Pending |

## Interview Notes
See: [interview-notes.md](./interview-notes.md)

## Technical Details
See: [technical-spec.md](./technical-spec.md)

## Research
See: [research/](./research/)

---

## Approval
- [ ] Pod Leader Approved
- Approved date: ___

## Next Steps
After approval, run: `/superform:work specs/cross-chain-supervaults/technical-spec.md`
