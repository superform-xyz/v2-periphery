# SuperVaultVetoAdapter Spec

## Metadata
- Project: v2-periphery
- Milestone: Counsel pilot — Control 1 (30-day plan, Week 2 deliverable)
- Linear Issue: N/A
- Interview Date: 2026-08-14
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

An immutable contract installed as the selected SuperVault's **primary manager**, replacing the curator (who becomes its operator). Three call families — yield-source additions, replacement strategy-root proposals, and PPS deviation-threshold changes — are gated behind a propose → review-window → guardian-veto/execute flow with exact-argument binding, expiry, and no replay. Every other manager function the pilot vault needs is an explicit typed pass-through; `addSecondaryManager`, the manager-change family, oracle updates, and global-leaf administration are structurally unreachable. The only way to replace the adapter is SuperGovernor emergency takeover, by design.

The contract holds no funds, has no owner, no proxy, and no generic call path; its entire authority is enumerable from its ABI. Guardian power is negative-only (veto + protective session-key invalidation). Implements Control 1 of the counsel alignment doc; tests must also prove the adapter never obstructs Control 2 (takeover).

## Requirements

### Functional
1. Operator proposes exact `(source, oracle, Add)` calls, `(root, manifestHash)` root proposals (manifestHash ≠ 0), and deviation-threshold changes; each executable only in `[window end, expiry)`, by the operator only.
2. Any live `SuperGovernor.isGuardian` address can permanently veto any Pending proposal at any time before execution, with an emitted reason.
3. Typed forwards (operator-only, immediate): executeHooks (payable), fulfill/cancel redemptions, fee skim, yield-source Remove (enum hard-coded), fee-config propose/execute, PPS-expiration, pause/unpause, strategy-root execute, upkeep withdrawal, removeSecondaryManager, cancelChangePrimaryManager, session-key grant/revoke.
4. `invalidateAllSessionKeys` callable by operator **or** guardian (enrollment + pre-takeover).
5. Permissionless sweeps send stray ETH/tokens to the immutable operator.

### Non-Functional
- Immutable config (constructor-only), Solidity 0.8.30, OZ 5.3.0, repo conventions (interface-declared errors/events, natspec).
- Zero occurrences of delegatecall/assembly/approve/CREATE; no fallback; Slither-clean.
- Events carry full proposal payloads — off-chain monitoring needs no eth_calls ("events are the product" for this legal-control contract).

## Technical Design

### Architecture
Adapter sits between operator/guardians and the three targets (Strategy, Aggregator, Executor). `SUPER_GOVERNOR` immutable; aggregator/executor resolved live via `SUPER_GOVERNOR.getAddress(...)`. Proposal ids are a monotonic nonce; args stored in a struct; `execute(id)` takes only the id. Stored states None/Pending/Vetoed/Executed; Ready/Expired derived from timestamps. Placeholder timings: 3-day window, 7-day expiry (counsel to finalize).

### Data Model
`mapping(uint256 => Proposal)` with `{kind, status, windowEndsAt, expiresAt, source, oracle, root, manifestHash, deviationThreshold}`. No iterable structures on-chain.

### API Changes
New contract + interface (`src/SuperVault/SuperVaultVetoAdapter.sol`, `src/interfaces/SuperVault/ISuperVaultVetoAdapter.sol`). Superman must target the adapter ABI instead of `SuperVaultStrategy` for manager operations (regression-tested).

## Implementation Plan

### Phase 1: Contract
- [ ] Interface (errors/events/structs) + constructor/modifiers/state machine
- [ ] Three propose functions, veto, execute, `state()` view
- [ ] Typed forwards (strategy/aggregator/executor) + sweeps + `receive()`

### Phase 2: Tests
- [ ] Unit tests vs mocks with selector recorder
- [ ] Invariant campaign (10 invariants: never-disabled-selector, terminal states, args fidelity, balance hygiene, veto liveness)
- [ ] Base fork tests: atomic enrollment, full root lifecycle incl. aggregator 15-min window, bad-root eviction pairing, takeover eviction in every proposal state, Superman regression

### Phase 3: Hardening
- [ ] Slither + CI grep gate, gas snapshot, natspec, deployment checklist (immutables read-back, operator-Safe ETH-receive probe, fork dry-run)

## Test Plan
- [ ] Unit tests for: proposal state machine, authorization matrix, boundary conditions (±1s), constructor validation, every typed forward
- [ ] Integration tests for: enrollment sequencing (atomic + gap variants), root lifecycle across both timelocks, takeover eviction, session-key generation sequencing, sweep flows
- [ ] E2E (fork) tests for: full counsel test list — veto permanence, mutation/replay/expiry failures, direct-call closure after manager transfer, Superman-via-adapter regression

## Risks & Mitigations
| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| Missed gate on a typed forward | Access Control | Low | Critical | per-function auth tests + fuzzed sender matrix | — |
| Operator key compromise | Operational | Med | High | all new-fund-flow paths behind veto window; blast radius documented for counsel | Radiant 2024 – $50M |
| Execute front-runs a pending veto | MEV | Med | High | veto valid for entire Pending lifetime | — |
| Timelock-execute timing abuse | Business Logic | Low | High | operator-only execute + proposal expiry | Sonne 2024 – $20M |
| Root bait-and-switch via off-chain manifest | Business Logic | Med | High | manifestHash required non-zero + mandatory off-chain root reproduction before execute | Tornado governance 2023 |
| Bad root activates during eviction (15-min aggregator window) | Business Logic | Low | High | runbook pairs blanket root veto with takeover in one batch; fork-tested | — |
| Stale secondary manager hostile takeover | Access Control | Low | High | atomic enrollment batch + cancelChangePrimaryManager forward | — |
| Stale session keys around takeover | Access Control | Med | Med | guardian generation bump pre-takeover, manager bump post-takeover; fork-tested | — |
| Generic-forwarder class | Access Control | — | — | structurally absent: typed forwards only, no approvals, no funds | Multichain/Furucombo/Socket – $1.4–15M |
| Uninitialized-state acceptance | Business Logic | Low | High | exact-state checks, default-deny | Nomad 2022 – $190M |

## Open Questions (Resolved)
| Question | Answer | Decided By |
|----------|--------|------------|
| Execute permission | Operator-only | user (interview) |
| Window/expiry config | Immutable at deploy; 3d/7d placeholders pending counsel | user (interview) |
| Batch yield-source adds | Decomposed to single proposals | user (interview) |
| Veto authorization | Live `isGuardian` check | user (interview) |
| Remove/Update actions | Remove immediate (enum hard-coded); Update disabled | user (interview) |
| Operator rotation | Immutable; rotation inside the operator Safe | user (interview) |
| Selector matrix breadth | Full operational parity (all four groups) | user (interview) |
| cancelChangePrimaryManager | Forwarded (defense-in-depth) | user (interview) |
| Session-key management | Grant/revoke forwarded; invalidate operator-or-guardian | user (interview) |
| Stray assets | Permissionless sweep to operator | user (interview) |
| updateDeviationThreshold | Veto-gated (third proposal type) | user (interview, per security research) |
| Veto validity window | Entire Pending lifetime | security research |
| Proposal identity | Monotonic nonce, single namespace, args in storage | security research |
| SuperGovernor resolution | Immutable SUPER_GOVERNOR; aggregator/executor via getAddress | specflow default (repo convention) |
| manifestHash == 0 | Rejected at propose | specflow default |
| Operator self-cancel | None; expiry or guardian veto | specflow default |

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
After approval, run: `/superform:work specs/veto-adapter/technical-spec.md`
