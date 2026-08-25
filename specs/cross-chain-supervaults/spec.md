# Cross-Chain SuperVaults Spec

## Metadata
- Project: v2-periphery
- Milestone: Cross-Chain Yield Deployment
- Linear Issue: N/A
- Interview Date: 2026-08-25
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

Enable SuperVaults to deploy yield across multiple chains while maintaining all accounting and share management on a single hub chain (per-vault). Three new composable contracts (CrossChainPositionRegistry, CrossChainAUMOracle, CrossChainPositionCapGuard) extend the existing SuperVault system without modifying any core contracts. Cross-chain deposits reuse the existing SuperExecutor intent flow, withdrawals use the existing ERC7540 async redemption path, and PPS updates use the existing `forwardPPS()` oracle pipeline.

The architecture is generic but the first implementation targets the FXRP vault on Flare with Stellar yield sources managed externally by Bizantine. Key use cases include singular stock products bridging to find best yield, basis trades on HyperCore, and carry/leverage strategies.

## Requirements

### Functional
1. Track cross-chain positions with full lifecycle (Pending -> Active -> WindingDown -> Exited) via CrossChainPositionRegistry
2. Accept quorum-signed AUM updates from off-chain oracle network via CrossChainAUMOracle
3. Enforce on-chain cross-chain allocation caps (global BPS + per-chain) via CrossChainPositionCapGuard
4. Reject cross-chain deployments when AUM data is stale (fail-safe)
5. Auto-invalidate unconfirmed positions after timeout (2 hours)
6. Support cross-chain deposits via existing SuperExecutor intent flow (no changes)
7. Support async withdrawals via existing ERC7540 flow when buffer insufficient (no changes)

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
  CrossChainPositionCapGuard [NEW]  -- validates during executeHooks()
      |
  SuperVaultAggregator [UNCHANGED]  -- stores PPS

Spoke Chains:
  Existing bridge hooks (Across V3 / deBridge) [UNCHANGED]
  Existing SuperDestinationExecutor [UNCHANGED]
```

### Data Model

**CrossChainPosition:**
- chainId, targetProtocol, targetAsset, deployedAmount
- lastReportedValue, lastReportTimestamp
- status (Pending/Active/WindingDown/Exited)
- registeredAt (for timeout)

**AUMReport:**
- totalCrossChainAssets, timestamp, nonce

**CapConfig:**
- maxCrossChainBps (global), perChainCap mapping

### API Changes

**New Contracts:**

| Contract | Key Functions |
|---|---|
| CrossChainPositionRegistry | `registerPosition()`, `confirmPosition()`, `updatePositionValue()`, `beginPositionExit()`, `deregisterPosition()`, `getCrossChainAUM()` |
| CrossChainAUMOracle | `forwardAUM()` (quorum-signed), `isAUMFresh()`, `getTotalAUM()` |
| CrossChainPositionCapGuard | `validateAllocation()`, `setCapConfig()` |

**SuperGovernor additions:**
- `CROSS_CHAIN_POSITION_REGISTRY` address key
- `CROSS_CHAIN_AUM_ORACLE` address key
- `CROSS_CHAIN_CAP_GUARD` address key

## Implementation Plan

### Phase 1: Core Position Tracking
- [ ] Implement CrossChainPositionRegistry with position lifecycle
- [ ] Implement registrar role management (per-strategy, set by primary manager)
- [ ] Add position confirmation flow (oracle confirms after bridge fill)
- [ ] Add position timeout auto-invalidation
- [ ] Unit tests for registry

### Phase 2: AUM Oracle
- [ ] Implement CrossChainAUMOracle with ECDSA quorum validation
- [ ] Implement all validation properties (timestamp, staleness, rate limit, deviation)
- [ ] Integrate with CrossChainPositionRegistry for value updates
- [ ] Unit tests for oracle

### Phase 3: Cap Enforcement
- [ ] Implement CrossChainPositionCapGuard with global + per-chain caps
- [ ] Integrate as pre-bridge hook in Merkle-validated hook chain
- [ ] Add AUM freshness gate (stale data blocks deployments)
- [ ] Unit tests for cap guard

### Phase 4: Integration & Testing
- [ ] Register new contracts in SuperGovernor
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
- [ ] Unit tests for: CrossChainPositionRegistry, CrossChainAUMOracle, CrossChainPositionCapGuard
- [ ] Fork tests for: full cross-chain deposit/bridge/register/update flow
- [ ] Invariant tests for: position count <= AUM, cap never exceeded, PPS * supply ~= AUM
- [ ] Fuzz tests for: cap enforcement boundaries, AUM deviation checks
- [ ] Scenario tests for: stale AUM blocks deposits, liquidation lag, bridge timeout, double-counting prevention

## Risks & Mitigations
| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| False position registration inflates PPS | Position Registration | Low | Critical | Quorum registration + oracle confirmation | Wormhole 2022 - $320M |
| AUM oracle compromise | Oracle | Low | Critical | M-of-N quorum + deviation threshold | Ronin 2022 - $625M |
| Cap bypass via flash loan | Flash Loan | Medium | High | Oracle-reported AUM (not balances) | Euler 2023 - $197M |
| Bridge fill failure leaves phantom position | Cross-Chain | Medium | Medium | Pending status, 2h timeout, no AUM impact until confirmed | - |
| Double-counting during position exit | Vault Accounting | Medium | High | Atomic deregistration on bridge callback | - |
| Stale position data after remote liquidation | Oracle | Medium | High | AUM deviation threshold flags large drops | - |
| Registrar key compromise | Access Control | Low | High | Multi-sig/quorum for registrar role | Multichain 2023 - $130M |

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
