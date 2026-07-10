# Managed Vault Wrapper Spec

## Metadata
- Project: v2-periphery
- Milestone: Managed Vaults MVP
- Linear Issue: N/A
- Interview Date: 2026-07-10
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

---

## Summary

Managed Vaults is a new vault type in SuperformOS enabling portfolio managers to offer investors an **async ERC-7540 deposit/redeem experience** with **manager-attested NAV** — without forking the SuperVault family.

The architecture avoids duplicating SuperVault/SuperVaultStrategy/SuperVaultAggregator by introducing a wrapper pattern:
1. **`ManagedVaultWrapper`** — standalone ERC-7540 vault that wraps an existing SV strategy's shares. Investors interact only with this vault.
2. **`ManagedECDSAAppsOracle`** — extends the existing ECDSAPPSOracle to handle both automated ECDSA-signed PPS updates and a new single-call manager attestation path. Replaces `ECDSAPPSOracle` as the singleton `_activePPSOracle`.
3. **`ManagedVaultWrapperFactory`** — minimal-proxy deployer.

NAV is manager-attested: the manager calls `updatePPSManaged(wrapper, value)` at any time (no timelock). Even though the wrapper holds SV shares, the NAV is NOT auto-derived from SV PPS — the manager explicitly attests it.

---

## Requirements

### Functional

1. **Async deposit (ERC-7540):** Investors call `requestDeposit(assets, controller, owner)`. Assets held pending. Manager calls `fulfillDepositRequests(controllers[])` to mint shares at current PPS.
2. **Async redeem (ERC-7540):** Investors call `requestRedeem(shares, controller, owner)`. Manager calls `fulfillRedeemRequests(controllers[], assetsOut[])` to burn shares and release assets.
3. **NAV attestation:** Manager calls `ManagedECDSAAppsOracle.updatePPSManaged(strategy, pps)`. No timelock. Oracle calls `IManagedVaultWrapper(strategy).setPPS(pps)` directly (bypasses aggregator).
4. **Investor allowlist (optional):** `isGated` flag set at factory creation. Gated vaults reject `requestDeposit` from non-allowlisted addresses.
5. **ECDSA automation path unchanged:** Existing validator-signed batch updates for non-managed SV strategies continue to work via the same oracle. Guard prevents managed strategies from being updated via ECDSA path.
6. **Oracle rotation:** `ManagedECDSAAppsOracle` replaces `ECDSAPPSOracle` via `SuperGovernor.proposeActivePPSOracle` + 7-day timelock + `executeActivePPSOracleChange`.
7. **Multi-chain:** Deploy on Base, Optimism, Ethereum (anywhere existing SV aggregator is deployed).

### Non-Functional

- PPS staleness guard: deposits/redeems revert if `block.timestamp - ppsLastUpdated > maxStaleness`
- First depositor protection: 1000 dead shares burned at wrapper initialization
- `nonReentrant` on all state-changing functions
- CEI pattern: state effects before external calls in all fulfill functions
- No aggregator changes required (wrapper has own `storedPPS`)

---

## Technical Design

### Architecture

```
Investor ──requestDeposit──► ManagedVaultWrapper ◄──── holds SV shares
                                      │
                         Manager calls │ fulfillDepositRequests
                                      │ fulfillRedeemRequests
                                      │
             ManagedECDSAAppsOracle ──► setPPS(pps) ──► wrapper.storedPPS
                 │
                 ├─ ECDSA path: validates N-of-M signatures → aggregator.forwardPPS (SV strategies)
                 └─ Managed path: manager calls → wrapper.setPPS (wrapper strategies)
```

### Data Model

**`ManagedVaultWrapper` storage:**
```solidity
bool public isPaused;
bool public isGated;

mapping(address controller => uint256 assets) public pendingDepositRequest;
mapping(address controller => uint256 shares) public claimableDepositShares;
mapping(address controller => uint256 shares) public pendingRedeemRequest;
mapping(address controller => uint256 assets) public claimableRedeemAssets;

uint256 public totalPendingDeposits;  // sum of pending deposits (for share price calc)

mapping(address investor => bool) public allowlist;
address public mainManager;
address public svStrategy;   // underlying SV strategy (registered in aggregator)
address public aggregator;   // SuperVaultAggregator (read svStrategy PPS from here)
```

Note: NAV is NOT stored in the wrapper. `totalAssets()` = `svShares × svPPS / svPrecision` where `svPPS` is read from `aggregator.getStoredPPS(svStrategy)`. The manager attests NAV by calling `oracle.updatePPSManaged(svStrategy, pps)` → `aggregator.forwardPPS(svStrategy, pps)`.

**`ManagedECDSAAppsOracle` new storage:**
```solidity
mapping(address strategy => bool) public isManagedStrategy;
```

### API Changes (New Contracts)

**`ManagedVaultWrapper`:**
- `requestDeposit(uint256 assets, address controller, address owner) → requestId`
- `fulfillDepositRequests(address[] controllers)` — manager only
- `claimDeposit(address controller, address receiver) → shares`
- `requestRedeem(uint256 shares, address controller, address owner) → requestId`
- `fulfillRedeemRequests(address[] controllers, uint256[] assetsOut)` — manager only
- `claimRedeem(address controller, address receiver) → assets`
- `setPPS(uint256 pps)` — active oracle only
- `setAllowlist(address[] investors, bool[] allowed)` — manager only

**`ManagedECDSAAppsOracle` (extends ECDSAPPSOracle):**
- `updatePPS(UpdatePPSArgs calldata)` — overrides base; blocks managed strategies
- `updatePPSManaged(address strategy, uint256 pps)` — manager or oracle manager
- `setManagedStrategy(address strategy, bool managed)` — GOVERNOR_ROLE only

**`ManagedVaultWrapperFactory`:**
- `createWrapper(WrapperCreationParams calldata) → address wrapper` — GOVERNOR_ROLE only

---

## Implementation Plan

### Phase 1: Oracle (~1 week)
- [ ] Implement `ManagedECDSAAppsOracle`
- [ ] Unit tests: routing guard, access control, ECDSA path unchanged
- [ ] Integration test: deploy as `_activePPSOracle`, verify existing SV strategies still update via ECDSA

### Phase 2: Wrapper Vault (~2 weeks)
- [ ] Implement `ManagedVaultWrapper` (ERC-7540)
- [ ] Unit tests: deposit/redeem queues, PPS stale guard, allowlist, first depositor
- [ ] Invariant fuzz tests: accounting invariants
- [ ] Integration test: full deposit → fulfillment → claim lifecycle

### Phase 3: Factory + Migration (~1 week)
- [ ] Implement `ManagedVaultWrapperFactory`
- [ ] Integration test: create wrapper, register as managed, full lifecycle
- [ ] Fork test on Base mainnet: oracle rotation with existing SV strategies

---

## Test Plan
- [ ] Unit tests for: `ManagedECDSAAppsOracle` (routing guard, managed path auth), `ManagedVaultWrapper` (request/fulfill/claim, allowlist, PPS staleness, dead share), `ManagedVaultWrapperFactory` (clone, init)
- [ ] Integration tests for: full ERC-7540 deposit flow, full ERC-7540 redeem flow, oracle rotation (7-day timelock bypass in tests), gated vs open vault
- [ ] Fuzz/invariant tests: `totalSupply` ≤ sum(claimable + pending), `totalAssets` ≥ claimable owed, no loss of assets during fulfill
- [ ] Fork test: oracle migration on Base mainnet fork, existing SV ECDSA path unaffected

---

## Risks & Mitigations

| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| Manager sandwiches NAV before redeem fulfill | NAV Manipulation | Medium | High | Max deviation bound (10% BPS per update) on `updatePPSManaged` | Maple Finance 2022-23 bad debt |
| Oracle singleton bug corrupts all SV PPS | Oracle | Low | Critical | Strict routing guard: managed path cannot touch SV strategies; ECDSA path blocks managed strategies | — |
| First depositor inflation attack | Vault Accounting | Low | High | 1000 dead shares burned in constructor (OZ dead-shares pattern) | Multiple ERC-4626 near-misses |
| Pending→claimable accounting drift | Async Vault | Medium | High | CEI + nonReentrant on all fulfill paths; invariant fuzz tests | Lagoon Finance audit findings |
| PPS staleness allows over-issuance | Oracle Stale | Low | Medium | `isPPSStale()` guard gates all deposit/redeem operations | — |
| ECDSA path used for managed strategy | Access Control | Low | High | `updatePPS` override reverts if any strategy in `isManagedStrategy` | — |

*Categories: NAV Manipulation, Oracle, Vault Accounting, Async Vault, Access Control*

---

## Open Questions (Resolved)

| Question | Answer | Decided By |
|----------|--------|------------|
| Does wrapper hold SV shares or raw assets? | SV shares | Interview |
| Single oracle or two oracles? | Replace ECDSAPPSOracle entirely | Interview |
| NAV timelock? | No timelock, single-call | Interview |
| Does wrapper use aggregator's PPS storage? | No — own `storedPPS`; oracle calls `wrapper.setPPS()` directly | Research (aggregator skips unknown strategies) |
| Who fulfills deposit/redeem requests? | Manager (manually) or keeper bot | Interview |
| Open or gated vaults? | Configurable at factory creation time | Interview |
| Which chains? | All SV chains (Base, Optimism, Ethereum) | Interview |

---

## Interview Notes
See: [interview-notes.md](./interview-notes.md)

## Technical Details
See: [technical-spec.md](./technical-spec.md)

## Research
See: [research/](./research/)
- [repo-analysis.md](./research/repo-analysis.md)
- [evm-security.md](./research/evm-security.md)

---

## Approval
- [ ] Pod Leader Approved
- Approved date: ___

## Next Steps
After approval, run: `/superform:work specs/managed-vault-wrapper/technical-spec.md`
