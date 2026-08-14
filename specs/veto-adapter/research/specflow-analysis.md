# SpecFlow Analysis: SuperVaultVetoAdapter

(Agent output, condensed. Question 5 below was resolved after this analysis ran: `updateDeviationThreshold` is now veto-gated — interview decision #12; `manageYieldSource(Remove)` stays an immediate forward per the counsel doc, with the enum hard-coded.)

## Actor flows walked

1. **Enrollment** — manager-change on aggregator (7-day path or SuperGovernor emergency) clears secondaries/pending proposals aggregator-side; adapter becomes mainManager. `invalidateAllSessionKeys` is NOT automatic and cannot run from the adapter's constructor (chicken-and-egg: not yet primary manager).
2. **Propose → Veto** — live-guardian veto while Pending, terminal.
3. **Propose → Execute → aggregator timelock (root case)** — adapter execute forwards `proposeStrategyHooksRoot`, which starts the aggregator's OWN 15-min timelock; then permissionless `executeStrategyHooksRootUpdate` activates the root. Post-adapter-execute, the only guardian defense is the aggregator-level blanket flag `setStrategyHooksRootVetoStatus` (weaker: neuters after activation).
4. **Typed pass-throughs** — immediate, operator-only.
5. **Session-key keepers** — keepers call the Executor directly; authorization = (strategy, key, generation).
6. **Takeover/eviction** — SuperGovernor `changePrimaryManager` immediate; stale adapter proposals become inert (execute reverts at target); session-key generation is NOT touched by the manager change — must be bumped separately.
7. **Decommissioning** — same code path as adversarial takeover; the adapter can never self-initiate hand-off (by design).

## Key gaps found

- **Enrollment atomicity**: stale secondaries retain manager powers AND can start a 7-day hostile `proposeChangePrimaryManager` countdown during any gap. `cancelChangePrimaryManager` forward is reactive only.
- **Session-key timing at takeover**: post-takeover the adapter can no longer call `invalidateAllSessionKeys` (fails `_validatePrimaryManager`). Guardian must call it via the adapter **before/atomically with** the takeover tx; the replacement manager bumps again after.
- **Cross-timelock race**: a bad root that slipped the adapter veto has only the aggregator's 15-min window; eviction over a bad root must pair `setStrategyHooksRootVetoStatus` with `changePrimaryManager` in the same governance action (permissionless root-execute can front-run the eviction).
- **Aggregator timelock is mutable** (SuperGovernor-gated) — adapter cannot enforce a floor; monitoring item.
- **manifestHash is not verified on-chain** — propose must at least revert on `manifestHash == 0`; reproduction is a mandatory off-chain runbook step.
- **Sweep recipient**: immutable operator that can't receive ETH strands funds forever — deployment-checklist item (Safes accept plain transfers).
- **No operator self-cancel**: mistaken proposals are simply never executed (expire), or guardian vetoes; document as SOP.
- **Proposal spam**: no on-chain limit on concurrent Pending proposals — off-chain monitoring dependency; dashboard + alerting required.

## Decisions adopted as spec defaults (from the analysis's recommendations)

| Question | Resolution |
|---|---|
| Enrollment atomicity | **Atomic Safe batch**: emergency `changePrimaryManager` (installs adapter — also clears all secondaries automatically) + `adapter.invalidateAllSessionKeys()` in one multisend; fork test both atomic and gap variants |
| SuperGovernor address | **Immutable `SUPER_GOVERNOR`** in constructor (matches `SuperVaultStrategy`'s own pattern); **aggregator/executor resolved dynamically** via `SUPER_GOVERNOR.getAddress(...)` per repo convention |
| Takeover pairing | Runbook + fork test: `setStrategyHooksRootVetoStatus` paired with `changePrimaryManager` when evicting over a bad root |
| Session-key sequencing | Guardian bumps generation via adapter before/with takeover; replacement manager bumps again after; both fork-tested |
| Proposal id namespace | Single monotonic `uint256` counter, type discriminator in the struct/event |
| manifestHash | Required non-zero on root proposals |
| Operator self-cancel | None (smaller surface); non-executed proposals expire; veto-as-undo documented |
| Redemption SLA | Counsel/ops TBD — flagged in spec as open operational item; session-key expiry sized against it |
| Sweep recipient | No on-chain probe; deployment checklist verifies operator Safe accepts ETH |
| Veto reason | `veto(id, string reason)` — emitted for the legal audit trail ("events are the product") |

## P0/P1 test additions (folded into acceptance criteria)

- Atomic enrollment fork test + non-atomic gap scenario with hostile stale-secondary proposal → `cancelChangePrimaryManager` mitigation
- Session-key invalidation sequencing fork test (guardian pre-takeover, new manager post-takeover)
- Bad-root eviction fork test: blanket root veto + takeover in one batch beats permissionless root-execute front-run
- Composite lifecycle: adapter execute → aggregator pending → guardian aggregator-level veto within 15 min (last resort)
- Duplicate-content proposals: second matured proposal reverts cleanly at strategy (`already exists`), no adapter state corruption
- Correlation invariant: every aggregator `proposeStrategyHooksRoot` event's tx contains the adapter's `Executed` event in the same tx
- Sweep with fee-on-transfer token; force-fed ETH does not affect `executeHooks` value forwarding
