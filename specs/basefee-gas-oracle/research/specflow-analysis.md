# SpecFlow Analysis — BasefeeGasOracle

Source: spec-flow-analyzer agent, 2026-08-18. Verified against SuperOracleBase.sol, SuperGovernor.sol, SuperVaultAggregator.sol.

## 1. Missing operational flows (highest impact first)

**A. `queueOracleUpdate` has a single global pending-update slot with NO collision check.**
`SuperOracleBase.sol:126-147` — `pendingUpdate` is one global struct, unconditionally overwritten at :142. (Contrast `queueProviderRemoval`, which reverts `PENDING_UPDATE_EXISTS()` at :174.) Any other governance oracle action queued during the 7-day window silently clobbers this proposal — no revert, first timelock clock discarded. Mitigation: operational lock on `queueOracleUpdate` Aug 25 → execute, plus a pre-execute assertion that `pendingUpdate` still matches what was queued.

**B. `executeOracleUpdate` is role-gated, not permissionless** (unlike SuperBank's merkle-root execute). `SuperOracleBase.sol:150-162` requires SUPER_GOVERNOR; `SuperGovernor.executeOracleUpdate()` (:332-337) requires `_ORACLE_MANAGER_ROLE`. Nobody is named as owner of the execute step ~7 days after queue; a missed execute silently loses the pre-deprecation buffer. Needs a calendar-backed runbook entry + named role holder.

**C. Role-handoff for the new contract's AccessControl is unspecified, and the sibling deploy script contradicts the security recommendation.** `DeploySuperformGasOracle.s.sol:30-33` grants DEFAULT_ADMIN + KEEPER to a single `owner` — the exact anti-pattern evm-security.md §1.5 flags. `DeployBasefeeGasOracle.s.sol` must take separate `admin` and `gasManager` addresses.

**D. Deploy-verification drift.** `ConfigBase.sol:63` (`ORACLE_GAS_TO_ETH`) is consumed by `_checkSuperOracle` (`DeployV2Periphery.s.sol:445,797`) which checks only the CHAINLINK slot — it can neither catch a bad SUPERFORM registration nor confirm the migration. Update the check.

**E. No post-execute verification runbook** (no `runCheck` analogue for the governance registration step).

## 2. Edge cases

- **Pending-update collision** (see A) — verify no other mainnet oracle governance action is scheduled Aug 25 – Sep 2.
- **Provider removal blast radius**: `queueProviderRemoval`/`executeProviderRemoval` (`SuperOracleBase.sol:172-218`, 1-hour removal timelock) removes the ENTIRE provider — no per-pair removal exists (`_validateOracleInputs` rejects `feed == address(0)` at :309). If SUPERFORM serves other pairs, removal is a landmine. **[RESOLVED by spec author — see addendum below.]**
- **AVERAGE is an unweighted mean with no divergence gate**: stddev is computed (:497-522) but `SuperGovernor._convertGasToUpkeepToken` discards it. The "2x guard" is a fork-test assertion, not an on-chain circuit breaker; a 2x+ feed disagreement post-registration flows straight into charges.
- **Baseline drift makes the fork test flaky**: a hardcoded 0.2157 UP baseline conflates "registered correctly" with "basefee hasn't moved since Aug 18". Derive the expected value from the fork block's live `block.basefee` instead.
- **Deprecation-before-execute window**: if Chainlink freezes before execute lands, GAS→WEI has zero valid providers for the gap → documented benign leak (free upkeep) for those days.

## 3. Unstated assumptions

1. `_ORACLE_MANAGER_ROLE` holder executes on schedule (manual step, no runbook).
2. No other governance action touches the global pending slot during the window.
3. GAS_MANAGER_ROLE and DEFAULT_ADMIN on different keys (deploy-script precedent says otherwise).
4. SUPERFORM has no other mainnet pair registrations. **[Checked — it does; see addendum.]**
5. Knob setters are instant (no timelock): fast to fix, equally fast to fat-finger a legitimate-but-wrong in-bounds value (e.g. 30_000 = 3x) that takes effect on the next updatePPS.
6. Off-chain consumers (Superman/OMS/erebor) unaffected by the blended→solo transition (unverified; separate sweep).

## 4. Rollback/abort flows

- Bad knobs: GAS_MANAGER setter call — instant, bounded. Fine.
- **Bad oracle contract: no fast path.** Re-queue a corrected address at the SUPERFORM+GAS→WEI slot (surgical, but another 7-day timelock with the flawed oracle still averaged in) — this is the designated abort path. Provider removal is NOT viable (see addendum). No "pause this provider's AVERAGE contribution" switch exists.
- Downstream auto-pause recovery is per-strategy (`unpauseStrategy`, `SuperVaultAggregator.sol:472-487`), then C1-RE_ANCHOR requires post-unpause-timestamped signatures — a broad overcharge means N independent manual recoveries.

## 5. Monitoring flows implied but uncommitted

Recommendations from research docs that need explicit in/out-of-scope decisions and owners (v2-monitoring tooling exists):
- Fast Gas feed `updatedAt` freeze alert.
- SUPERFORM-vs-CHAINLINK GAS→WEI divergence alert (deviation already computed on-chain, unused).
- `paramsLastUpdatedAt` exposure for stale-knob visibility.
- Strategy upkeep balance vs max-bound-answer alert (organic 30-50x gas days can honestly auto-pause underfunded strategies).
- Named owner for watching the Chainlink freeze event and green-lighting a follow-up CHAINLINK-slot cleanup.

## Recommended next steps (priority order)

1. ~~Verify SUPERFORM's other mainnet registrations~~ **done — see addendum.**
2. Confirm `_ORACLE_MANAGER_ROLE` holder; calendar-backed execute runbook step.
3. `DeployBasefeeGasOracle.s.sol` takes separate admin/gasManager addresses.
4. Pre-execute assertion that `pendingUpdate` matches what was queued.
5. Fork-test baseline computed from forked block's live basefee, not a frozen constant.
6. Document re-queue (not provider removal) as the abort path before execute.

---

## Addendum (spec author, 2026-08-18): SUPERFORM provider registrations on mainnet

Per `DeployV2Periphery.s.sol` feed configuration, **SUPERFORM already serves UP→USD on mainnet**
(`providers[2] = PROVIDER_SUPERFORM; feeds[2] = fixedPriceOracle`) — and that pair is part of the
same 3-hop upkeep conversion (`USD → UP` step in `_convertGasToUpkeepToken`). Provider-wide
removal of SUPERFORM would therefore not only remove the basefee oracle but break the USD→UP hop
of upkeep pricing itself. **Provider removal is ruled out as a rollback lever; re-queue at the
pair slot is the only abort path.**
