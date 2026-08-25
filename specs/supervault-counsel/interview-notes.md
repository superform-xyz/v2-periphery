# SuperVaultCounsel — Interview Notes

- Date: 2026-08-19
- Interviewee: cosmin (Superform)
- Source: engineering discussion summary (Slack) pasted verbatim by the user + AskUserQuestion round
- Working name in discussion: "counsel adapter"

## Feature Summary

An immutable, non-reconfigurable adapter contract — `SuperVaultCounsel` — that replaces the
SuperGovernor msig in the SuperVault **primary manager / curator** seat. It constrains what the
curator key can do: sensitive actions go through a propose → veto-window → execute flow that any
live SuperGovernor guardian can veto; day-to-day operations are typed, operator-only forwards; and
there is deliberately **no** generic call path, so the adapter's entire authority is enumerable
from its ABI.

The only way to replace the adapter itself is a SuperGovernor emergency takeover — by design.

## Decisions (AskUserQuestion round, 2026-08-19)

| Question | Decision |
|----------|----------|
| Repo / location | **v2-periphery** — spec at `v2-periphery/specs/supervault-counsel/`; all integration targets (SuperGovernor, SuperVaultAggregator, SuperVault strategy, Executor session keys) live there |
| Veto window / expiry | **3-day veto window, 7-day expiry** — executable only inside `[proposedAt + 3d, proposedAt + 7d)`; both immutable, set in constructor |
| Contract name | **SuperVaultCounsel** |
| Scope | **Keep the full capability list as pasted** — no trimming of fee-config or PPS-expiration management |

## Capability List (verbatim from engineering summary)

### What the adapter contract can do

1. **Propose a yield-source addition with a delay** — the curator queues an exact
   (source, oracle, Add) call; executable only inside [window end, expiry).
2. **Propose a replacement strategy root with a delay** — bound to a published leaf manifest hash
   so the veto actor can reproduce what's inside the opaque root before it executes.
3. **Propose a deviation-threshold change with a delay** — same window, so PPS defenses can't be
   weakened instantly.
4. **Veto a pending proposal** — guardian-only, checked live against `SuperGovernor.isGuardian`;
   a veto is terminal for that proposal instance and stays valid until the moment of execution
   (no front-run window).
5. **Execute a matured proposal** — operator-only; args come from storage keyed by the id, so
   mutated arguments are structurally impossible; proposals are numbered by a monotonic nonce,
   so nothing replays.
6. **Expire proposals** — a proposal not executed before its expiry dies; same content can be
   re-proposed under a fresh id and a fresh window.
7. **Run day-to-day operations** — hook execution (with ETH), redemption and cancellation
   fulfillment, fee skim, fee-config changes (own timelock), PPS-expiration management,
   pause/unpause.
8. **Remove a yield source immediately** — administrative deletion only; the enum is hard-coded
   so this path can never add or update.
9. **Complete a vetted root on the aggregator** — after the adapter-level window passed un-vetoed,
   the operator forwards the aggregator's own execute.
10. **Manage keeper session keys** — grant/revoke (operator) and nuke-all via generation bump
    (operator or guardian; at enrollment, and again after takeover).
11. **Cancel a hostile primary-manager-change proposal** — closes the stale-secondary-manager
    ejection path.
12. **Return stray assets** — anyone can sweep ETH/tokens off the adapter, but only ever to the
    immutable operator; the adapter holds no funds by invariant.

### What it deliberately cannot do

- Cannot forward yield-source additions, strategy-root proposals, or deviation-threshold changes
  directly — those exist only behind the propose/delay/veto path.
- Cannot let the curator add a secondary manager or propose a primary-manager change — closes the
  seven-day replacement bypass; the only way to replace the adapter is SuperGovernor emergency
  takeover, by design.
- Cannot touch out-of-scope selectors — `manageYieldSource(Update)` (oracle changes),
  `manageYieldSources` batch, `changeGlobalLeavesStatus`, min-update-interval proposals: no code
  path exists.
- Cannot let the veto actor do anything positive — the guardian's only writes are `veto` and the
  purely protective `invalidateAllSessionKeys`.
- Cannot make generic calls — no `execute(target, bytes)`, no fallback, no delegatecall, no
  approvals; its entire authority is enumerable from the ABI.
- Cannot be reconfigured — no owner, no admin, everything immutable from the constructor
  (operator, window, expiry, target addresses); operator/guardian key rotation happens inside
  their Safes.

## Function Surface (verbatim from engineering summary)

### Veto-gated (propose → window → veto/execute)
- `proposeYieldSourceAdd(source, oracle)` — queue an exact yield-source addition (batches
  decomposed to singles)
- `proposeStrategyRoot(root, manifestHash)` — queue a replacement strategy-root proposal, bound
  to a published leaf manifest hash
- `proposeDeviationThreshold(newThreshold)` — queue a PPS deviation-threshold change (veto-gated:
  sharpest no-veto lever under key compromise)
- `veto(proposalId)` — permanently cancel a pending proposal (any live SuperGovernor guardian;
  valid the whole time a proposal is pending, not just during the window)
- `execute(proposalId)` — operator-only; takes only the id, forwards the exact stored args after
  the window and before expiry

### Typed forwards to the strategy (operator-only, immediate)
- `executeHooks(args)` — payable, relays exact msg.value
- `fulfillRedeemRequests(controllers, assetsOut)`
- `fulfillCancelRedeemRequests(controllers)`
- `skimPerformanceFee()`
- `removeYieldSource(source)` — Remove enum hard-coded in the adapter (can't be bent into
  Add/Update)
- `proposeVaultFeeConfigUpdate(perfBps, mgmtBps, recipient)` / `executeVaultFeeConfigUpdate()` —
  fee config keeps its own 1-week strategy timelock
- `managePPSExpiration(action, staleness)`

### Typed forwards to the aggregator (operator-only, immediate)
- `pauseStrategy()` / `unpauseStrategy()`
- `executeStrategyHooksRootUpdate()` — completes a non-vetoed root proposal after the
  aggregator's 15-min timelock
- `proposeWithdrawUpkeep()` / `executeWithdrawUpkeep()`
- `removeSecondaryManager(manager)`
- `cancelChangePrimaryManager()` — defense against a hostile manager-change proposal from a stale
  secondary

### Typed forwards to the Executor (session keys)
- `grantSessionKey(...)` / `revokeSessionKey(...)` + batch variants — operator-only, keeps
  Superman keepers working
- `invalidateAllSessionKeys()` — operator or guardian; called at enrollment and after takeover

### Housekeeping
- `sweepERC20(token)` / `sweepNative()` — permissionless, full balance to the immutable operator
  (upkeep withdrawals and hook ETH refunds land on the adapter)
- `receive()` — bare, for strategy ETH refunds
- `state(proposalId)` view — returns None / Pending / Ready / Executed / Vetoed / Expired

## Actors & Trust Model

- **Operator** (immutable address, a Safe): proposes, executes matured proposals, runs all
  day-to-day typed forwards, manages session keys. Key rotation happens inside the Safe, not the
  adapter.
- **Guardian** (any address passing `SuperGovernor.isGuardian` at call time): can only `veto` and
  `invalidateAllSessionKeys`. Purely protective — no positive writes.
- **SuperGovernor** (existing msig): retains emergency takeover as the sole adapter-replacement
  path; guardian set is read live from it.
- **Anyone**: sweeps (funds only ever move to the operator).

## Security Rationale (from discussion)

- Deviation-threshold change is veto-gated because it is "the sharpest no-veto lever under key
  compromise" — weakening PPS defenses must never be instant.
- Strategy roots are opaque; binding proposals to a published leaf **manifest hash** lets the
  guardian reproduce the root's contents before deciding to veto.
- Veto validity extends to the moment of execution — no window in which the operator can front-run
  a pending veto.
- Execute takes only the proposal id; arguments live in storage, making argument mutation
  structurally impossible; monotonic nonce prevents replay.
- The seven-day manager-replacement bypass (curator adds secondary manager → secondary proposes
  primary change) is closed by omitting those forwards entirely, plus
  `cancelChangePrimaryManager` as active defense.
- No fallback / delegatecall / generic execute / approvals: the full authority set is enumerable
  from the ABI.

## Open Items Captured for Spec

- Exact aggregator/strategy/executor function signatures must be pulled from
  v2-periphery sources (`SuperVaultAggregator.sol`, strategy contract, Executor session-key
  module) during research.
- Manifest-hash publication channel (where the leaf manifest is published for guardian
  reproduction) is off-chain process; spec should state the on-chain binding only.
- `_hooksRootUpdateTimelock` on the aggregator (15 min) interacts with the adapter's 3-day
  window: adapter window is the real defense; the aggregator timelock is a second, shorter fuse.

## Decisions (second AskUserQuestion round, 2026-08-19, post-SpecFlow)

| Question | Decision |
|----------|----------|
| Proposer identity | **Operator == Proposer** — one immutable Safe holds propose + execute + day-to-day; guardian veto is the sole containment for that key |
| `execute(proposalId)` auth | **Operator-only** — accepted liveness cost: a stalled Operator can let a mature proposal expire (re-propose to recover) |
| Executor-enrollment gap | **Add `enrollExecutor()`** — operator-only typed forward calling `aggregator.addSecondaryManager` with the immutable SuperVaultExecutor address only (verified: does not reopen the 7-day bypass) |
| Instance scope | **One Counsel per strategy** — strategy/aggregator/executor immutable in constructor; no strategy params on forwards |

## Documented defaults for remaining SpecFlow questions (pod leader to confirm at approval)

- **Deviation-threshold bounds**: spec ADDS hard immutable floor/ceiling at the Counsel level (aggregator setter is unbounded; `type(uint256).max` disables PPS checks — Resolv-style validity-predicate recommendation).
- **Fee-config outside veto path**: kept as day-to-day per the "no trimming" decision — documented as an explicit risk acceptance (up to 51% perf fee behind only the strategy's own 1-week timelock, no guardian veto).
- **Manifest binding**: evidentiary only (on-chain binding infeasible for opaque roots); operational precondition — manifest must be published to an append-only channel BEFORE propose; named residual risk.
- **Proposal spam**: no cap/cooldown in v1 — accepted guardian-fatigue risk, mitigated by monitoring runbook.
- **freezeManagerTakeover**: standing policy — never call while any Counsel is enrolled (would make it irreplaceable).
- **Orphaned proposals after takeover**: harmless-by-unreachability; documented, no Superseded state.
- **Redundant operator gates** on `executeStrategyHooksRootUpdate`/`executeWithdrawUpkeep` forwards: kept for operational symmetry; documented that aggregator counterparts are permissionless.
- **Proposal id**: `uint256` monotonic nonce.
- **Zero-guardian registry**: off-chain monitoring requirement (heartbeat isGuardian checks); no on-chain floor.

## Design amendment (2026-08-19): Counsel migration via propose-and-accept

User-requested addition. The Counsel gains a second, counsel-initiated replacement path alongside
SuperGovernor takeover, using a propose-and-accept pattern where **the proposed successor must
actively claim the seat**:

1. **Offer (veto-gated, 4th ActionType `CounselMigration`)**: old Counsel operator calls
   `proposeCounselMigration(newCounsel)`. Validity predicates at propose: non-zero, not self,
   deployed contract, and `STRATEGY()`/`AGGREGATOR()` wiring must match (checked via new interface
   getters). After the 3-day guardian window, `execute(id)` seats the successor as **secondary
   manager only** — an offer, not a handover.
2. **Accept**: the successor's operator calls `newCounsel.acceptCounselSeat(feeRecipient)` →
   forwards `aggregator.proposeChangePrimaryManager(strategy, address(this), feeRecipient)`.
   The aggregator's secondary-only gate makes acceptance structurally restricted to the offered
   contract. The aggregator's real **7-day manager-change timelock** then runs; completion is the
   aggregator's permissionless `executeChangePrimaryManager` (wipes secondaries as usual →
   successor runs the enrollment runbook).
3. **Brakes**: guardian veto on the offer (3d); old operator retraction any time before
   acceptance (`removeSecondaryManager(newCounsel)`); old operator abort during the 7-day
   timelock (`cancelChangePrimaryManager()`); SuperGovernor takeover trumps everything.

**Accepted trade-off (supersedes part of exclusion #2)**: the invariant "seat moves only via
takeover" becomes "…or via a 10-day, guardian-vetoable, twice-retractable, must-be-actively-
claimed path". Under full operator-key compromise, an attacker needs the guardian to miss the
3-day veto AND 7 further days with no cancel and no takeover, AND a successor contract that
passes the wiring predicates and actively claims. An unaccepted offer moves nothing forever.

Verified by 6 new unit tests and 5 new fork tests including a full end-to-end migration on the
real Base aggregator (91 total tests, all passing).

## Design amendment 2 (2026-08-19): full seat coverage — no takeover-only operations remain

User decision: the previously-excluded seat powers blocked functionality entirely while the
Counsel is enrolled, so all three now exist behind the SAME propose → 3-day veto → execute flow
(new ActionTypes 4-6):

- **`GlobalLeavesStatus`** — `proposeGlobalLeavesStatus(leaves[], statuses[])` → execute forwards
  `aggregator.changeGlobalLeavesStatus`. Both ban and unban directions veto-gated; urgent defense
  remains the operator's immediate `pauseStrategy()`.
- **`MinUpdateInterval`** — `proposeMinUpdateInterval(interval)` → two-leg like StrategyRoot:
  execute forwards the aggregator's own propose (its real 3-day parameter timelock + permissionless
  execute follow). New operator forwards: `executeMinUpdateIntervalChange()` (convenience) and
  `cancelMinUpdateIntervalChange()` (defensive). The aggregator enforces interval < maxStaleness
  at leg 2.
- **`SecondaryManagerAdd`** — `proposeSecondaryManagerAdd(manager)` → execute forwards
  `aggregator.addSecondaryManager`. Reopens the 7-day-bypass surface only behind the 3-day
  guardian review, with `removeSecondaryManager` + `cancelChangePrimaryManager` as standing
  defenses (fork-tested end-to-end including the hostile-secondary scenario).

Remaining deliberate exclusions (workarounds exist, nothing blocked): `manageYieldSource(UpdateOracle)`
(use remove + veto-gated re-add with the new oracle) and `manageYieldSources` batch (decompose to
singles). The SuperGovernor contract's own role surface (fees, PPS oracle, global root, registry,
guardians, takeover) was never in scope — the Counsel holds the primary-manager seat only.

`ProposalCreated` was refactored to emit the full `Proposal` struct (field list outgrew the flat
event). Test totals: 101 (72 unit + 4 invariant + 25 fork), all passing; min-update-interval
two-leg and global-leaves flows verified against the real Base aggregator.

## Rename (2026-08-19): SuperGovernorCounsel → SuperVaultCounsel

The original name kept prompting "does it hold the SUPER_GOVERNOR_ROLE?" — it does not; it holds
the SuperVault primary-manager/curator seat. Renamed to join the SuperVault* family beside
SuperVaultExecutor (the secondary-manager module). All files, identifiers, bytecode artifacts,
deploy scripts (deploy_supervault_counsel.sh), and this spec directory (specs/supervault-counsel)
renamed; 101 tests re-verified under the new name.
