# SuperVaultCounsel — Actor Flow Analysis (SpecFlow)

*(Full analysis; actors: Operator, Guardian(s) via live SuperGovernor.isGuardian, SuperGovernor msig, keepers via SuperVaultExecutor session keys, anonymous sweepers.)*

## Key flows

### Enrollment (3 paths)
1. `createVault(params.mainManager = Counsel)` at creation.
2. Instant takeover: `SuperGovernor.changePrimaryManager(strategy, Counsel, feeRecipient)` — reverts if `freezeManagerTakeover()` ever called.
3. 7-day path: an existing secondary calls `aggregator.proposeChangePrimaryManager` → permissionless execute after 7d.

**Paths 2 AND 3 both wipe all secondary managers** (incl. SuperVaultExecutor) and pending proposals, and force-set feeRecipient. The executor-enrollment gap fires on every real enrollment, not just takeover.

### Post-enrollment bootstrap
Re-add executor as secondary (blocked pending decision), `invalidateAllSessionKeys` (kills stale keys AND prevents silent revival from prior tenure), `grantSessionKeysBatch` to re-onboard keepers.

### Veto-gated lifecycle state machine
None → Pending (propose) → {Vetoed (any live guardian, any time before execution — terminal), Ready (derived, t ∈ [proposedAt+3d, proposedAt+7d)), Expired (derived, t ≥ proposedAt+7d)}; Ready → Executed (operator). Veto valid during Ready up to the execute call. Terminal states absorbing; content re-proposable under fresh id.

### Strategy-root two-leg flow
Counsel-propose(root, manifestHash) → 3d veto → operator pushes `aggregator.proposeStrategyHooksRoot` → aggregator's own 15-min timelock → **permissionless** `aggregator.executeStrategyHooksRootUpdate` (bypasses Counsel; second leg unstoppable at Counsel layer — by design, Counsel window is the real defense).

### Hostile scenarios
- **Compromised operator**: full day-to-day surface (skim bounded by 12h-post-unpause + HWM; pause griefing instant; malicious executeHooks calldata) but CANNOT change deviation threshold / add sources / change root without surviving a live 3-day veto. Remediation: takeover.
- **Hostile secondary pre-enrollment**: can race `proposeChangePrimaryManager` before Counsel is primary — rollout runbook must audit the secondary list clean BEFORE enrollment.
- **Guardian rotation mid-window**: revoked → in-flight proposal may lose its watcher; added → can veto immediately; emptied to zero → every proposal becomes a rubber stamp with no on-chain signal. Registry admin is de facto veto controller (TCB).
- **freezeManagerTakeover() while enrolled** → Counsel permanently irreplaceable. Standing policy: never freeze while any Counsel is enrolled.

### Takeover/exit and re-enrollment
Takeover leaves Counsel-internal proposals orphaned (state(id) keeps reporting Pending/Ready but downstream execution reverts). Session keys die on manager change but **silently revive** if the same Counsel is reinstated — invalidateAllSessionKeys required at every (re-)enrollment.

## Permutations matrix (condensed)
- Execute timing: t < +3d revert; t == +3d boundary; (3d,7d) Ready; t == +7d boundary (Ready or Expired? pin half-open [start,end)); t > +7d Expired.
- Veto: before window / during / during Ready / same block as execute (veto-wins must be deterministic); re-veto reverts (terminal).
- Guardian state at veto: valid-at-propose+valid-at-veto / added-mid-window / revoked-mid-window / zero guardians.
- Re-proposal after veto/expiry: no cooldown specified — guardian-fatigue risk.
- Sweep: any caller; token types (no-return, FOT, reverting, EOA address — SafeERC20 handles); timing vs. in-flight withdraw-upkeep cycle (funds land on Counsel; sweep is harmless since destination is operator either way).
- executeWithdrawUpkeep pays the **Counsel contract** (current mainManager), not the operator — funds require a follow-up sweep.
- Multi-chain: each chain needs its own instance; confirm per-chain SuperGovernor and freeze scope.

## Missing elements (spec must answer)
1. **Manifest binding is evidentiary only** — nothing on-chain proves manifestHash derives root. Manifest-equivocation defeats the root-veto purpose even with honest guardians. Highest-severity gap. Mitigation: require pre-publication of the manifest to an append-only channel before propose; document as named residual risk.
2. **Fee-config bypass** — fee changes (perf up to 51%) ride only the strategy's 1-week timelock with NO guardian veto, while the (less severe) deviation threshold got veto-gated. Needs explicit risk acceptance or re-routing.
3. **Executor re-enrollment gap** — needs hard-coded `enrollExecutorAsSecondaryManager()`; confirmed safe (executor exposes no proposeChangePrimaryManager).
4. **Deviation-threshold bounds** — aggregator's setter is unbounded (max uint disables PPS checks); the Counsel proposal path inherits this unless it adds floor/ceiling (Resolv precedent: validity predicates, not just human veto).
5. **Guardian-count floor** — zero-guardian registry silently converts vetoes to rubber stamps; must be an explicit off-chain monitoring requirement.
6. **Orphaned-proposal state after takeover** — document "unreachable therefore harmless" or add Superseded state.
7. **Event schema under-specified** — ProposalCreated must emit decoded typed args + absolute deadline timestamps.
8. **Redundant operator-gating** on Counsel.executeWithdrawUpkeep / executeStrategyHooksRootUpdate (aggregator counterparts already permissionless) — cosmetic access control, liveness cost only.

## Critical questions
1. Proposer == Operator, or separate Curator immutable? (collapses/separates attack surfaces A/B)
2. execute(id): operator-only (liveness dependency; can expire mature good proposals) vs permissionless-after-window (OZ/Aave/Compound norm)?
3. enrollExecutorAsSecondaryManager(): add? (recommended yes — hard-coded target)
4. Deviation-threshold bounds at the Counsel level? (recommended yes)
5. One instance per strategy (immutable target; matches un-parameterized surface) vs multi-strategy instance (strategy param on every forward)?
6. manifestHash: evidentiary convention + published-manifest precondition, or attempt on-chain binding? (on-chain infeasible for opaque roots)

## Important questions
7. Fee-config: keep outside veto (documented acceptance) or route through veto path?
8. freezeManagerTakeover scope (global?) — standing "never freeze while enrolled" policy.
9. Concurrent-proposal cap / re-proposal cooldown? (spam/guardian-fatigue)
10. Keep operator gate on the two redundant executes?
11. Terminal state for takeover-orphaned proposals?
12. Can createVault pre-seed the executor as secondary? (would sidestep gap for new vaults)

## Nice-to-have
13. Cooldown on guardian invalidateAllSessionKeys (griefing lever)?
14. Permissionless markExpired(id) + event vs derived-only state()?
15. Proposal id type: uint256 monotonic nonce (canonical) vs bytes32.
