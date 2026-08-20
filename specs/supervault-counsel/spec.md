# SuperVaultCounsel Spec

## Metadata
- Project: Superform v2-periphery
- Milestone: SuperVault curator decentralization ("counsel adapter")
- Linear Issue: N/A
- Interview Date: 2026-08-19
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

`SuperVaultCounsel` is an immutable, ownerless adapter that takes the SuperVault primary
manager/curator seat on `SuperVaultAggregator`, replacing the SuperGovernor msig in that role. The
three sharpest curator levers — yield-source additions, strategy hooks-root replacement (bound to a
published leaf-manifest hash), and PPS deviation-threshold changes — exist only behind a
propose → 3-day guardian-veto window → execute inside `[proposedAt+3d, proposedAt+7d)` flow.
Any live `SuperGovernor.isGuardian` address can veto up to the moment of execution; `execute(id)`
is operator-only and forwards exact stored args (monotonic ids, no replay, no arg mutation).
Everything else the seat requires is a typed, operator-only forward; there is no generic call path,
no owner, no upgradeability. Replacement happens only via `SuperGovernor.changePrimaryManager`
takeover. One instance per strategy; operator is a Safe; all parameters immutable from the constructor.

Research validated the design against MetaMorpho (closest analog), OZ TimelockController, Compound/
Aave grace periods, and Superform's vulnerability database, and surfaced one hard gap now fixed in
spec: enrollment wipes all secondary managers including the keeper session-key module, so the
Counsel gains a hard-coded `enrollExecutor()` forward (verified not to reopen the 7-day
replacement bypass).

## Requirements

### Functional
1. Veto-gated flows: `proposeYieldSourceAdd(source, oracle)`, `proposeStrategyRoot(root, manifestHash)`,
   `proposeDeviationThreshold(newThreshold)` → `veto(id)` (any live guardian, until execution, terminal)
   / `execute(id)` (operator-only, exact stored args, half-open window) / derived expiry.
2. Day-to-day operator forwards: `executeHooks` (payable, exact `msg.value` relay), redemption and
   cancellation fulfillment, `skimPerformanceFee`, `removeYieldSource` (Remove hard-coded),
   fee-config propose/execute (strategy's own 1-week timelock), `managePPSExpiration`,
   pause/unpause, withdraw-upkeep, `removeSecondaryManager`, `cancelChangePrimaryManager`,
   `enrollExecutor()` (hard-coded executor address), session-key grant/revoke/batch.
3. Guardian surface: `veto(id)` and `invalidateAllSessionKeys()` only.
4. Permissionless: `sweepERC20`/`sweepNative` (full balance, destination hard-coded to operator),
   `state(id)`/`getProposal(id)`/`canVeto(addr)` views.
5. Deliberately absent: `UpdateOracle` yield-source action, batch manage, `changeGlobalLeavesStatus`,
   min-update-interval, `addSecondaryManager` (beyond enrollExecutor), `proposeChangePrimaryManager`,
   generic execute/fallback/delegatecall/approvals, any owner/admin/setter.

### Non-Functional
- Immutable and ownerless; Solidity 0.8.30; OZ 5.3.0 non-upgradeable; house conventions
  (interface-declared errors/events, SCREAMING_SNAKE errors, section banners, NatSpec).
- Validity predicates: immutable deviation-threshold floor/ceiling (aggregator setter is unbounded;
  max-uint disables PPS defenses).
- Observability as a security feature: `ProposalCreated` emits decoded args + absolute
  vetoDeadline/expiry; every transition/forward/sweep emits an event.
- CEI everywhere; `nonReentrant` on the payable relay; no balance-derived logic.

## Technical Design

### Architecture
Single contract + interface in v2-periphery. Immutables: `OPERATOR` (Safe; also proposer),
`SUPER_GOVERNOR` (live `isGuardian`), `AGGREGATOR`, `STRATEGY`, `EXECUTOR`, `VETO_WINDOW = 3 days`,
`EXPIRY = 7 days`, `MIN/MAX_DEVIATION_THRESHOLD`. Proposal state machine:
None → Pending → {Vetoed | Executed | Expired}, with Ready/Expired derived in the `state(id)` view
(never stored). Strategy-root execution is two-leg: Counsel window guards the Counsel-internal
proposal; `execute(id)` pushes `aggregator.proposeStrategyHooksRoot`, then the aggregator's own
15-minute timelock + permissionless execute complete it.

### Data Model
`struct Proposal { uint64 proposedAt; ProposalStatus status; ActionType actionType; address source;
address oracle; bytes32 root; bytes32 manifestHash; uint256 newThreshold; }` keyed by a `uint256`
monotonic nonce. Full args stored (Governor Bravo/MetaMorpho precedent) so `execute(id)` cannot
mutate them.

### API Changes
New contract + `ISuperVaultCounsel`. No changes to SuperGovernor, aggregator, strategy, or
executor — the Counsel is enrolled purely as aggregator `mainManager` data.

## Implementation Plan

### Phase 1: Core contract
- [ ] Interface (errors/events/enums/structs), constructor + validation, state machine,
      typed forwards, sweeps

### Phase 2: Tests
- [ ] Unit auth-matrix + boundary + race tests; invariant/fuzz suite; fork integration
      (enrollment → enrollExecutor → session keys → keeper round-trip; root two-leg; upkeep → sweep)

### Phase 3: Ops & rollout
- [ ] Guardian runbook (private-relay veto, pagers, isGuardian heartbeats), enrollment runbook
      (secondary-audit → takeover → enrollExecutor → invalidateAllSessionKeys → grant keys),
      never-freeze policy, v2-monitoring config, deployment script

## Test Plan
- [ ] Unit tests for: state machine (all transitions + terminal absorption), auth matrix, window
      boundaries (±1s both edges), same-block veto/execute (veto-wins determinism), deviation bounds,
      sweep token matrix (standard/no-return/FOT/reverting/EOA), msg.value exactness + forced ETH
- [ ] Integration tests for: enrollment paths (takeover and 7-day), executor re-enrollment + keeper
      round-trip, session-key revival-on-reinstatement, guardian rotation mid-window via real
      SuperGovernor roles, strategy-root two-leg, withdraw-upkeep landing on Counsel → sweep
- [ ] Invariant tests for: single-status, no-governed-change-without-full-window,
      executed-root-matches-committed-hash, nonce monotonicity, sweep destination constant

## Risks & Mitigations
| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| Manifest equivocation (hash evidentiary only) | Business Logic | Low | High | Publish-before-propose convention; guardians veto unpublished/non-reproducing roots | Tornado governance 2023 |
| Fee-config outside veto path (≤51% perf fee) | Access Control | Low | High | Strategy's 1-week timelock; explicit sign-off; takeover remediation | — |
| Compromised operator key | Access Control | Low | High | Veto window contains governed params; guardian session-key kill-switch; takeover | Resolv 2026 – $25M |
| Honest-but-wrong threshold proposal | Business Logic | Med | High | Immutable floor/ceiling validity predicates | Compound Prop 62 – ~$80M |
| Guardian griefing (perpetual veto / key nukes) | Operational | Low | Med | SuperGovernor guardian rotation (live, immediate) | — |
| Zero/stale guardian set disarms veto | Operational | Low | High | Pager on guardian-role events + isGuardian heartbeats | — |
| freezeManagerTakeover during tenure → irreplaceable | Operational | Low | Critical | Standing never-freeze policy | — |
| Hostile pre-enrollment secondary races takeover | Access Control | Low | High | Audit secondary list clean before enrollment | — |
| Proposal spam / guardian fatigue | Operational | Med | Med | Accepted v1; monitoring runbook; revisit cap later | — |
| Same-block veto/execute race | Timelock | Low | High | Veto-until-execution semantics; deterministic ordering tests | — |

## Open Questions (Resolved)
| Question | Answer | Decided By |
|----------|--------|------------|
| Repo / spec location | v2-periphery | cosmin, 2026-08-19 |
| Window / expiry | 3 days / 7 days, immutable | cosmin, 2026-08-19 |
| Contract name | SuperVaultCounsel | cosmin, 2026-08-19 |
| Capability scope | Full pasted list, no trimming | cosmin, 2026-08-19 |
| Proposer identity | Operator == Proposer (one Safe) | cosmin, 2026-08-19 |
| execute(id) auth | Operator-only (accepted liveness cost) | cosmin, 2026-08-19 |
| Executor-enrollment gap | Add hard-coded enrollExecutor() | cosmin, 2026-08-19 |
| Instance scope | One Counsel per strategy | cosmin, 2026-08-19 |
| Deviation bounds / manifest binding / fee exclusion / spam cap / freeze policy / orphaned proposals / id type | Documented defaults in interview-notes.md — pod leader confirms at approval | pending sign-off |

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
After approval, run: `/superform:work specs/supervault-counsel/technical-spec.md`
