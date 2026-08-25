# SuperVaultCounsel Spec

## Metadata
- Project: Superform v2-periphery
- Milestone: SuperVault curator decentralization ("counsel adapter")
- Linear Issue: N/A
- Interview Date: 2026-08-19
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

`SuperVaultCounsel` is an immutable, ownerless adapter that takes the SuperVault primary
manager/curator seat on `SuperVaultAggregator`, replacing the SuperGovernor msig in that role.
Every sharp curator lever — eight veto-gated action types: yield-source additions, strategy
hooks-root replacement (bound to a published leaf-manifest hash), PPS deviation-threshold changes,
Counsel migration offers, global-leaf ban/unban, min-update-interval changes (two-leg via the
aggregator's own timelock), secondary-manager additions, and vault fee-config updates (two-leg
via the strategy's own 1-week timelock; perf <=51%, entry fee <=100%, bounds mirrored at propose
time) — exists only behind a
propose → 3-day guardian-veto window → execute inside `[proposedAt+3d, proposedAt+7d)` flow.
Any live `SuperGovernor.isGuardian` address can veto up to the moment of execution (the hard
guarantee is the 3-day Pending window; once Ready, execute-vs-veto is a mempool race the operator
wins if first — guardians veto during Pending, via private relay); `execute(id)` is operator-only
and forwards exact stored args (monotonic ids, no replay, no arg mutation). Everything else the
seat requires is a typed, operator-only forward; there is no generic call path, no owner, no
upgradeability. Replacement has two paths: `SuperGovernor.changePrimaryManager` takeover
(instant, msig-only), or the propose-and-accept migration — a matured `CounselMigration` proposal
seats the successor as SECONDARY only; the successor must itself call `acceptCounselSeat()`
(structurally restricted by the aggregator's secondary-only gate), starting the aggregator's
7-day manager-change timelock, during which `cancelChangePrimaryManager()` remains available.
One instance per strategy; operator is a Safe; all parameters immutable from the constructor.

Research validated the design against MetaMorpho (closest analog), OZ TimelockController, Compound/
Aave grace periods, and Superform's vulnerability database, and surfaced one hard gap now fixed in
spec: enrollment wipes all secondary managers including the keeper session-key module, so the
Counsel gains a hard-coded `enrollExecutor()` forward (verified not to reopen the 7-day
replacement bypass).

## Requirements

### Functional
1. Veto-gated flows (eight): `proposeYieldSourceAdd(source, oracle)`, `proposeStrategyRoot(root,
   manifestHash)`, `proposeDeviationThreshold(newThreshold)`, `proposeCounselMigration(newCounsel)`
   (validates successor STRATEGY + AGGREGATOR wiring at propose time),
   `proposeGlobalLeavesStatus(leaves, statuses)`, `proposeMinUpdateInterval(interval)` (two-leg:
   execute starts the aggregator's own parameter timelock), `proposeSecondaryManagerAdd(manager)`,
   `proposeVaultFeeConfigUpdate(perfBps, mgmtBps, recipient)` (two-leg: execute starts the
   strategy's own 1-week fee timelock; bounds perf <=5100 bps / mgmt <=10_000 bps / non-zero
   recipient mirrored at propose time)
   → `veto(id)` (any live guardian, until execution, terminal) / `execute(id)` (operator-only,
   exact stored args, half-open window) / derived expiry. Plus `acceptCounselSeat(feeRecipient)`:
   the successor-side claim of a migration offer (operator-only; aggregator's secondary-only gate
   makes it structurally self-targeted).
2. Day-to-day operator forwards: `executeHooks` (payable, exact `msg.value` relay), redemption and
   cancellation fulfillment, `skimPerformanceFee`, `removeYieldSource` (Remove hard-coded),
    `managePPSExpiration`,
   pause/unpause, withdraw-upkeep, `removeSecondaryManager`, `cancelChangePrimaryManager`,
   `enrollExecutor()` (hard-coded executor address), session-key grant/revoke/batch,
   `executeMinUpdateIntervalChange`/`cancelMinUpdateIntervalChange` and
   `executeVaultFeeConfigUpdate` (second legs of the min-interval and fee-config flows).
3. Guardian surface: `veto(id)` and `invalidateAllSessionKeys()` only.
4. Permissionless: `sweepERC20`/`sweepNative` (full balance, destination hard-coded to operator),
   `state(id)`/`getProposal(id)`/`canVeto(addr)` views.
5. Deliberately absent: `UpdateOracle` yield-source action, batch manage, arbitrary-target
   `proposeChangePrimaryManager` (only the self-targeted `acceptCounselSeat` exists),
   generic execute/fallback/delegatecall/approvals, any owner/admin/setter.
   (Global-leaves, min-interval, and secondary-manager adds are NOT absent — they shipped as
   veto-gated action types 4-6.)

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
`SUPER_GOVERNOR` (protocol identity; migration equality invariant), `VETO_REGISTRY` (veto-authority
lookup consulted by veto/canVeto/invalidateAllSessionKeys; constructor arg, address(0) defaults to
SUPER_GOVERNOR — per-instance so veto authority is pluggable, e.g. a Newton attestation shim,
without protocol-wide GUARDIAN_ROLE; P7), `AGGREGATOR`, `STRATEGY`, `EXECUTOR`, `VETO_WINDOW = 3 days`,
`EXPIRY = 7 days`, `MIN/MAX_DEVIATION_THRESHOLD`. Proposal state machine:
None → Pending → {Vetoed | Executed | Expired}, with Ready/Expired derived in the `state(id)` view
(never stored). Two flows are two-leg: strategy-root (`execute(id)` pushes
`aggregator.proposeStrategyHooksRoot`, then the aggregator's own 15-minute timelock +
permissionless execute) and min-update-interval (`execute(id)` pushes
`proposeMinUpdateIntervalChange`, then the aggregator's parameter timelock; the aggregator
enforces interval < maxStaleness at that leg). CounselMigration executes as
`addSecondaryManager(newCounsel)` — an offer, not a handover; the seat moves only via the
successor's `acceptCounselSeat()` + the aggregator's 7-day manager-change timelock.

### Data Model
`struct Proposal { uint64 proposedAt; ProposalStatus status; ActionType actionType; address source;
address oracle; bytes32 root; bytes32 manifestHash; uint256 newThreshold; address newCounsel;
bytes32[] leaves; bool[] statuses; uint256 newMinUpdateInterval; address newSecondaryManager; }`
keyed by a `uint256` monotonic nonce; `ActionType` has eight members (YieldSourceAdd, StrategyRoot,
DeviationThreshold, CounselMigration, GlobalLeavesStatus, MinUpdateInterval, SecondaryManagerAdd,
FeeConfig — the last carrying performanceFeeBps/managementFeeBps/feeRecipient fields).
Full args stored (Governor Bravo/MetaMorpho precedent) so `execute(id)` cannot mutate them.

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
- [ ] Guardian runbook (veto during Pending via private relay, pagers, isGuardian heartbeats;
      treat any SecondaryManagerAdd as "authorize adapter escape in ~10 days"; page on
      PrimaryManagerChangeProposed), enrollment runbook (secondary-audit → takeover →
      enrollExecutor → invalidateAllSessionKeys → grant keys), yield-source swap runbook
      (add replacement → unwind old to ~zero → remove; removal is registry deletion with no
      occupancy check), never-freeze policy, v2-monitoring config, deployment script

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
| Fee-config abuse (perf ≤51% AND entry fee up to 100%, arbitrary recipient) | Access Control | Low | High | FIXED (P1): ActionType.FeeConfig — 3-day guardian veto + the strategy's 1-week timelock (~10 days total); bounds mirrored at propose time | — |
| SecondaryManagerAdd = adapter escape hatch (seated secondary can proposeChangePrimaryManager later; cancel is operator-gated) | Access Control | Low | High | Guardian runbook treats any SecondaryManagerAdd as "authorize escape in ~10 days"; page on PrimaryManagerChangeProposed; takeover inside 7-day window | — |
| Migration successor wiring (was partial) | Business Logic | Low | Med | FIXED: propose requires successor SUPER_GOVERNOR equality (fake-veto-machinery hard invariant); EXECUTOR + timing/bounds interface-exposed for guardian/monitor diffing, deliberately not required equal (legitimate migration levers) | — |
| Yield-source removal drops live source from valuation set → PPS deviation → auto-pause (blocks redeems) | Operational | Med | Med | Runbook: add replacement first, unwind old source to ~zero, only then remove; or accept the pause as deliberate friction | — |
| Compromised operator key | Access Control | Low | High | Veto window contains governed params; guardian session-key kill-switch; takeover | Resolv 2026 – $25M |
| Honest-but-wrong threshold proposal | Business Logic | Med | High | Immutable floor/ceiling validity predicates | Compound Prop 62 – ~$80M |
| Guardian griefing (perpetual veto / key nukes) | Operational | Low | Med | SuperGovernor guardian rotation (live, immediate) | — |
| Zero/stale guardian set disarms veto | Operational | Low | High | Pager on guardian-role events + isGuardian heartbeats | — |
| freezeManagerTakeover during tenure → irreplaceable | Operational | Low | Critical | Standing never-freeze policy | — |
| Hostile pre-enrollment secondary races takeover | Access Control | Low | High | Audit secondary list clean before enrollment | — |
| Proposal spam / guardian fatigue | Operational | Med | Med | Accepted v1; monitoring runbook; revisit cap later | — |
| Ready-window veto/execute mempool race (operator wins if first) | Timelock | Low | High | Hard guarantee is the 3-day Pending window: guardians veto during Pending, via private relay; deterministic ordering tests codify Ready-window semantics | — |

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
