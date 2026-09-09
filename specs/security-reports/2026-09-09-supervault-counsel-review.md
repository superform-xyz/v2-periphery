# SuperVault Counsel — Security Review (2026-09-09)

**Target:** `feat/supergovernor-counsel` working tree (PR #335) after the supersession-epoch and
operator/guardian-separation hardening. Scope: `SuperVaultCounsel.sol`, `SuperVaultVetoRegistry.sol`,
`ISuperVaultCounsel.sol`, `IVetoRegistry.sol`, `DeploySuperVaultCounsel.s.sol`, `counsel-fleet.json`,
and the aggregator/strategy functions the Counsel forwards to.

**Method:** inline critical-pattern scan + three parallel reviewers (vulnerability-DB scanner against
`superform-specs/guidelines/solidity/vulnerabilities.md`, adversarial attack on the two new changes,
coding-rules/documentation audit). All VERIFIED findings were fixed in the same working tree; the
tables below record the state **after** the fixes.

**Verdict:** PASS. No P0/P1 exploitable findings. One deploy-blocking script bug (fail-closed) and one
design gap (per-leaf rollback class) were found and fixed; the rest were documentation and test gaps.

## Inline critical-pattern scan

| # | Pattern | Result |
|---|---------|--------|
| 1 | Reentrancy | PASS — `execute` sets status before the external call and is `nonReentrant`; sweeps `nonReentrant`; `executeHooks` relays exact `msg.value`, never resident balance |
| 2 | Access control | PASS — operator/guardian/anyone matrix verified per function; no owner, no generic call, no `delegatecall`/`selfdestruct` |
| 3 | Division before multiplication | N/A — no arithmetic beyond bounds checks |
| 4 | Unchecked return values | PASS — no low-level calls; `Address.sendValue` for native |
| 6 | `abi.encodePacked` collisions | PASS — none |
| 7 | `tx.origin` | PASS — none |
| 8 | Floating pragma | PASS — `pragma solidity 0.8.30` |
| 9 | Returnbomb in `catch` | PASS — the only `catch` is the bare constructor guard |

## Findings (ranked) — all fixed unless marked

| # | Sev | Where | Finding | Fix |
|---|-----|-------|---------|-----|
| F1 | P1 (deploy blocker, not exploitable) | `DeploySuperVaultCounsel.s.sol` `_deploy` | The new guardian-independence `require` probed `IVetoRegistry(p.vetoRegistry)` unresolved, i.e. `address(0)` in SuperGovernor-fallback mode — the prod/staging default after the fleet change. Every `run*` for those envs reverted with an opaque empty-returndata decode error before CREATE2. | Probe the resolved veto authority (`vetoRegistry == 0 ? superGovernor : vetoRegistry`), with a readable `VETO_AUTHORITY_HAS_NO_CODE` pre-check. Same probe surfaced in `_check` so `runCheckOne` warns before broadcast. |
| F2 | P3 | `SuperVaultCounsel._isSingleSlot` | `GlobalLeavesStatus` was classified set-membership, but every leaf is its own ban/unban slot: a stale matured `{X: unbanned}` batch could execute after a newer `{X: banned}` batch — the exact rollback class the epoch closes for roots. | `GlobalLeavesStatus` added to the single-slot set (whole-type supersession; batch leaf changes into one proposal). NatSpec, specs, and a regression test (`test_Supersession_GlobalLeavesStatusIsSingleSlot`) updated; the invariant handler already fuzzes this type. |
| F3 | P3 | `counsel-fleet.json` prod/4663 `TestNVDA-RH` | Entry still named the operator Safe as sole guardian; would now revert in both the script and the constructor and contradicted `_guardianIndependenceNote`. | Guardian set to the independent address `0x22BC97cFac64D6d9BCaDF5dC36e4D01Db9e929c5` (operator stays `0x6E3d…8dF8`); the redeploy gets a new registry + Counsel address (CREATE2 includes the registry) and must be re-seated. |
| F4 | P3 | `_storeProposal` | `ProposalSuperseded` was emitted for any stored-Pending predecessor, including one already derived-Expired, contradicting the event's "still-pending" doc and giving monitors a phantom transition. | Emit only when `state(prev) ∈ {Pending, Ready}` (evaluated before the epoch moves). Tests: `test_Supersession_NoEventWhenPreviousIsExecutedOrExpired`, `test_Supersession_EventForReadyPredecessor`. |
| F5 | P3 | Constructor | A codeless veto registry / SuperGovernor (EOA, counterfactual) made the guard's `try` fail with an opaque ABI-decode revert (not caught by `catch`). Fail-closed, but unreadable, and undocumented. | Explicit `VETO_REGISTRY_NOT_A_CONTRACT` revert before the `try`; NatSpec documents codeless vs reverting registries. Test `test_Constructor_RevertIf_VetoRegistryHasNoCode`. |
| F6 | P3 (docs) | `ISuperVaultCounsel.sol`, `SuperVaultCounsel.sol` header, `spec.md`, `technical-spec.md`, `review-2026-08-21.md` | Lifecycle text still described five states / veto "until execution"; `state()` pseudo-code lacked the epoch branch; execute row lacked the latest-id condition; review item #5 (`vetoBatch`) not annotated. | All updated; `ProposalSuperseded.actionType` now `indexed` (monitors filter by type); `@return`/`@param` completed on the new view and event. |
| F7 | P3 (tests) | `SuperVaultCounsel.t.sol` | Missing: veto of the newer proposal must not resurrect the older; guard against a custom registry (the prod path). Invariant had a vacuous vetoed-after-supersession assertion. | Added `test_Supersession_VetoOfNewerDoesNotResurrectOlder`, `test_Constructor_RevertIf_OperatorIsGuardian_CustomRegistry`; invariant now asserts a Superseded id is strictly older than the epoch. |

### Residuals (documented, not code-fixable here)

- **R1 — Guard is deploy-time and address-level.** A mutable registry (SuperGovernor `GUARDIAN_ROLE`,
  an admin-bearing custom registry) can later grant the operator guardian status; `veto()` does not
  re-check `msg.sender != OPERATOR`. A runtime check cannot detect the "sole guardian" case anyway.
  Off-chain monitoring requirement: registry heartbeat (known guardian `true`, operator `false`).
- **R2 — Set-membership stale re-add.** Two pending `YieldSourceAdd(S)`: execute one, remove S via
  forward, execute the tolerated duplicate → S re-added without a fresh window (within 7 days).
  Requires guardians to tolerate a visibly duplicate pending Add. Monitoring rule: duplicate pending
  Add of the same source ⇒ veto. Optional future hardening: key supersession by `keccak(type, payload)`.
- **R3 — Attention, not window.** Superseding gives the new proposal its own full 3-day window; the
  residual is that guardians who cleared proposal A must re-review B. Page on `ProposalSuperseded`.
- **R4 — Already-deployed Counsels** (e.g. RH `TestNVDA` `0x7b0D…`) are immutable and keep the old
  behaviour; they need redeploy + re-seat. `ProposalStatus.Superseded` (index 6) is appended, so
  existing enum values are unchanged, but `PROPOSAL_NOT_READY`/`PROPOSAL_NOT_VETOABLE` can now carry 6.
- **R5 — Prod guardian set.** Fleet defaults now rely on `SuperGovernor.isGuardian`; whoever holds
  `GUARDIAN_ROLE` per chain must not be the operator Safe, or the constructor reverts at broadcast.
  Verify chains 1 and 14 before any prod run.

## Checked and found sound

- **Supersession epoch.** id 0 sentinel (`id+1`) correct in every path; stored `Executed`/`Vetoed`
  win before the derived branch; `Superseded` precedes `Expired`/`Ready` and is absorbing (epoch
  monotonic, ids never reused). Same-block veto/propose race: either order leaves the older id dead
  and the guardian's goal met. Operator cannot use supersession to shorten a window, revive vetoed
  content, or harm a third party (it only kills the operator's own older proposals). Two-leg actions
  (FeeConfig, MinUpdateInterval) cannot desync: a started target timelock implies the Counsel
  proposal is already `Executed`; targets are last-write-wins with restarted timelocks.
  CounselMigration: only pending offers supersede; executed offers are aggregator secondaries.
  One extra cold SLOAD in `state()` for single-slot types.
- **Constructor guard.** Bare `catch {}` is returnbomb-safe; reverting registry tolerated (documented
  dead-registry semantics, `test_deadRegistry_*` unchanged); `SuperGovernor.isGuardian` exists; the
  script `require` sits after registry resolution and before CREATE2 in all of `run`/`runOne`/`runAll`.
- **Access matrix.** `veto` guardian-only (live lookup); `execute` + every typed forward operator-only;
  `acceptCounselSeat` successor-operator-only and structurally gated by the aggregator's secondary
  check; `invalidateAllSessionKeys` operator-or-guardian; sweeps permissionless but pay only `OPERATOR`.
- **Timelock classes.** No privileged bypass; aggregator root timelock (15 min, permissionless) is
  explicitly not relied upon; `changePrimaryManager` takeover clears pending slots + secondaries;
  governor `setStrategyHooksRootVetoStatus` remains a brake.
- **Bounds.** Deviation threshold `[MIN, MAX]`, `MAX != uint256.max`; fee caps mirror the strategy
  (5100 / 10_000, non-zero recipient); `minUpdateInterval < maxStaleness` enforced at the aggregator.
- **Migration flow.** Offer = secondary seat; accept = `proposeChangePrimaryManager(address(this))`;
  a live Counsel cannot self-accept; 7-day cancelable; fake-successor risk stays guardian-review.
- **Artifacts.** `generated-bytecode`, `locked-bytecode`, `locked-bytecode-dev` byte-identical
  (sha256 `c6138fc7…83b1`); ABI contains `OPERATOR_IS_GUARDIAN`, `VETO_REGISTRY_NOT_A_CONTRACT`,
  `ProposalSuperseded(uint256 indexed, uint256 indexed, uint8 indexed)`, `latestProposalIdOfType`.

## Test evidence

| Suite | Result |
|-------|--------|
| `test/unit/SuperVaultCounsel.t.sol` | 92 / 92 |
| `test/unit/SuperVaultCounsel.invariant.t.sol` | 5 / 5 (incl. `invariant_supersededNeverExecutedAndLatestOnly`) |
| `test/integration/SuperVault/SuperVaultCounsel.fork.t.sol` | 25 / 25 |
| `forge fmt --check`, `git diff --check` | clean |
