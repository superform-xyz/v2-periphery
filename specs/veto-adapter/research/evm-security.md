# EVM Security Research: SuperVaultVetoAdapter

**Primary reference:** `/Users/cosming/1.Coding/Superform/superform-specs/guidelines/solidity/vulnerabilities.md` (5,052 lines; § refs below). Companion: `coding-rules.md` same dir.

## 1. Relevant vulnerability patterns

### Access control (§2.1, §35.2, §35.5)
- Every ungated adapter function executes with PRIMARY MANAGER privilege — one forgotten `onlyOperator` = that manager function is public. Default-deny structurally: no `fallback()`, bare `receive()` only.
- Privileged-executor bypass: any path reaching `manageYieldSource(Add)` or `proposeStrategyHooksRoot` outside the state machine defeats the contract. The Remove forward must **hard-code the action enum** — caller-supplied enum turns it into an Add/Update bypass.
- Proposer==executor (operator) is compensated by guardian veto ⇒ veto liveness is the security boundary.
- Constructor: revert on zero addresses; sane bounds on window/expiry (unrecoverable if wrong — no owner).

### Proposal lifecycle (§14.4, §9.1)
- Guard: executed-re-executed, vetoed-executed, expired-executed (off-by-one at boundaries §14.2), reentrancy double-dispatch.
- **Re-propose treadmill:** veto is per-instance; operator can re-propose identical content forcing repeated guardian vetoes — attention-exhaustion on the human layer. Mitigate with perfect event indexing; optionally content-hash counters for monitoring.

### Hash collisions (§9.4, SWC-133)
- `abi.encodePacked` multi-arg ids are collision-prone, worse across two proposal types. Use monotonic nonce ids + `abi.encode` with type discriminator for any content hash.

### Griefing (§34.2, §7.1)
- Third-party spam closed (operator-only propose). Residual: operator buries a malicious proposal among hundreds (human-layer). Store proposals in mapping; never iterate on-chain.

### Front-running execute vs veto (§6.1, §35.6)
- TOCTOU race at window-open: operator front-runs guardian's veto tx. **Veto must remain valid for the proposal's entire Pending lifetime** — the window is a minimum delay before execute, never a veto deadline.
- Expiry defends against sleeper proposals executed after guardian attention moved on (§34.5); enforce in `execute`, on-chain.

### msg.sender context loss
- Target-side events attribute everything to the adapter ⇒ adapter must emit its own attribution events (operator, proposal id).
- Audit every forwarded selector for `msg.sender`-directed payouts (confirmed: `executeWithdrawUpkeep` pays mainManager → sweep needed; verify `skimPerformanceFee` pays configured recipient, not sender).

### ETH handling (§13.3)
- `executeHooks` forward: pass **exactly `msg.value`**, never `address(this).balance` (adapter legitimately accrues ETH via refunds/upkeep). All other functions non-payable. `sweepNative` via `call` with success check (§8.1).

### Reentrancy (§1.1–1.5)
- Hooks can re-enter the adapter; they can't pass operator/guardian gates, so keep the permissionless set exactly {sweeps} and it's harmless.
- `execute(id)`: CEI — mark Executed **before** the forward; `nonReentrant` on `execute` + `executeHooks` forward.

### Guardian TOCTOU (§34.6)
- Live `isGuardian` is correct. Residual: all guardians rotated out mid-window ⇒ degrades to pure delay (monitoring/runbook, NOT an on-chain `guardianCount > 0` check — that would let guardians brick execution by resigning). SuperGovernor address is the trust root — fork-test `isGuardian` against real Base deployment.
- Guardian positive-power creep: `invalidateAllSessionKeys` must only bump generation, never grant.

### Operator key compromise blast radius (headline analysis — document verbatim in spec)
Immediately, no veto: `executeHooks` (bounded by ACTIVE roots — the real damage ceiling), fulfill*/cancel fulfill, `manageYieldSource(Remove)`, `updateDeviationThreshold` (widens PPS-manipulation defenses — scrutinize), fee-config (bounded by strategy's own 1-week timelock + caps), pause/unpause, session-key grants (same authority class as executeHooks).
Behind veto window: yield-source adds, new strategy roots — the only paths to authorizing NEW fund flows. Audit question: can immediate forwards compose into a new-fund-flow primitive? (Remove+re-Add is vetoable on the Add; scrutinize Remove alone, deviation threshold, fulfill*.)
Guardian compromise: veto-DoS + session-key invalidation spam. No fund access. Acceptable; document.

## 2. Exploit precedents

| Incident | Loss | Lesson |
|---|---|---|
| Beanstalk 2022 | $182M | No fast-path around the review window, ever (no "emergency" execute) |
| Tornado Cash governance 2023 | ~$1M + capture | Bind exact arguments; the strategy root's off-chain manifest is the residual analog — manifest-hash event + mandatory off-chain root reproduction before execute is the anti-bait-and-switch |
| **Sonne Finance 2024** | $20M | Timelocked txs became permissionlessly executable after delay; attacker chose execution timing. Directly validates operator-only execute + expiry |
| Compound Prop 62/64 2021 | ~$80–160M | Timelocks delay your remediation too; instant negative-power veto + external takeover are the answers; test takeover is never obstructed by adapter state |
| Multichain anyCall 2022 / Furucombo 2021 / Socket 2024 / Dexible 2023 | $1.4M–$15M | Canonical anti-generic-forwarder precedents; adapter must hold no approvals, no user funds |
| Audius 2022 | $6M | Proxy/init misconfig class — closed by no-proxy, constructor-only, immutable |
| Nomad 2022 | $190M | Default-deny: exact-state checks (`== Pending`), never negative checks that `Status.None == 0` could satisfy |
| Ronin/Harmony/Radiant/Bybit | up to $1.43B | Privileged key compromise WILL be assumed; blast-radius doc is the point of this design |
| Parity 2017 | $30M | No init function at all |

## 3. Attack surface map (condensed)

- **Propose**: spam-burying (human layer); id collisions (closed by nonce); veto treadmill; referent mutation during window (CREATE2-redeployed source — guardians re-check at execute; expiry bounds drift); third-party propose (must revert).
- **Veto**: veto-everything DoS (accepted, guardian rotatable); veto-after-execute (must revert); ex-guardian veto (closed by live check); empty guardian set (pure-delay degradation, monitored); wrong-proposal veto (closed by unambiguous ids + full-args events).
- **Execute**: before window/after expiry/after veto/twice (state machine); front-run pending veto (veto valid whole lifetime); reentrant double-execute (CEI); args drift (execute takes only id, args from storage); third-party execute (Sonne — must revert).
- **Typed forwards**: ungated forward = escalation (per-function audit); caller-controlled enum in Remove (hard-code); msg.value hygiene; hook reentry (permissionless set = sweeps only); deviation-threshold widening (flagged); pause games; session-key grants to attacker keys (generation bump at takeover kills them).
- **Disabled selectors**: NO reachable path to `addSecondaryManager` (THE invariant — 7-day bypass), `proposeChangePrimaryManager` family, `manageYieldSources` batch, `manageYieldSource(Update)`, `changeGlobalLeavesStatus`, `proposeMinUpdateIntervalChange`, direct `proposeStrategyHooksRoot`. Takeover must evict the adapter cleanly regardless of pending proposal state.
- **Funds**: sweep destination immutable (closed); ERC-777 callback during sweep (harmless, nonReentrant anyway); adapter never calls `approve`.

## 4. Recommended security patterns

1. **Proposal id = monotonic `uint256` nonce** (`++proposalCount`); full typed payload in storage struct. Emit content hash (`keccak256(abi.encode(type, args, nonce))`) in events for off-chain matching.
2. **State enum default-deny**: `Status { None, Pending, Vetoed, Executed }`; Expired derived from time. Transitions check exact prior state (`== Pending`), never `!=` checks.
3. **`execute(uint256 id)` takes nothing but the id** — forwarded calldata assembled from storage.
4. **Veto requires only `Status.Pending`** — no timestamp condition; valid from propose until execute succeeds or expiry.
5. **CEI + `nonReentrant`** on `execute` and the payable `executeHooks` forward.
6. **Selector discipline**: one external function per forwarded target function; interface calls with compiled-in enums; no `fallback()`; bare `receive()` only.
7. **Payable hygiene**: only `executeHooks` forward payable, forwards `{value: msg.value}`.
8. **Modifiers**: `onlyOperator` (immutable equality), `onlyGuardian` (live isGuardian), `onlyOperatorOrGuardian` for `invalidateAllSessionKeys` only. No owner/roles/admin.
9. **Constructor validation**: zero-address reverts; `reviewWindow > 0`, `expiryWindow > 0`, sanity ceiling (window ≤ 30 days).
10. **Event completeness — events are the product** (legal-control contract): `Proposed(id, type, proposer, source, oracle | root, manifestHash, windowEndsAt, expiresAt)`, `Vetoed(id, guardian)`, `Executed(id, executor)`; every typed forward emits attribution; sweeps emit token/amount.
11. **Timestamps**: store `windowEndsAt`/`expiresAt` at propose; execute requires `now >= windowEndsAt && now < expiresAt`; strict consistent comparisons, unit-test both edges (§14.1/2).
12. **Zero occurrences of**: `approve`, `delegatecall`, assembly, CREATE — grep-level CI check (§24.1).

## 5. Testing recommendations

### Invariants (handler-based Foundry campaign)
1. **No path to disabled selectors** — mock-target selector recorder + `recorder.never(sel)` across arbitrary operator/guardian/third-party sequences.
2. Vetoed ⇒ never executes (any warp/actor sequence).
3. Executed ⇒ terminal (incl. malicious-hook re-entrant `execute(id)` mid-forward).
4. Expired ⇒ never executes; boundary pair at `expiresAt ± 1`.
5. Window hard floor; boundary pair at `windowEndsAt ± 1`.
6. Args at target == bytes-for-bytes proposed args (fuzzed payloads).
7. Adapter never retains balances; `executeHooks` forwards `msg.value` exactly even with force-fed ETH (§D.2); never emits `Approval`.
8. Authorization matrix fuzzed over {operator, live guardian, ex-guardian, mid-window-added guardian, random}.
9. Id uniqueness incl. identical content re-proposed.
10. Veto liveness fuzzed over `[propose, expiry)` — always succeeds while Pending, incl. after `windowEndsAt`.

### Directed scenarios
- Same-block execute/veto race at `windowEndsAt` both orderings — first-lands-wins, clean revert for loser.
- Sonne scenario: third-party execute of matured proposal reverts; post-expiry operator also blocked.
- Tornado scenario (fork): manifest changed off-chain — assert event carried manifestHash (documented limitation, off-chain check possible).
- Remove-enum hardening: adversarial encodings can't reach Add/Update.
- Malicious hook re-enters every adapter function — only sweeps succeed, harmlessly.
- Guardian-set drained mid-window: pure-delay behavior; execute still works (no bricking).
- **Takeover eviction (Base fork)**: pending/vetoed/matured proposals in every state → SuperGovernor takeover → adapter cleanly evicted, stale proposals revert cleanly on execute, generation bump kills operator-granted session keys.
- `executeWithdrawUpkeep` → sweep flow, fuzzed with fee-on-transfer token (§10.1 — sweep must use balance-based amounts).
- Slither CI gate + grep check for delegatecall/assembly/approve.

## Open design questions surfaced
(a) Should `updateDeviationThreshold` (and `manageYieldSource(Remove)`) really be immediate forwards given PPS/accounting leverage under operator-key compromise? → user decision.
(b) Veto valid after `windowEndsAt` until execute — **resolved: yes** (pattern 4).
(c) Remove forward hard-codes the enum — **resolved: yes** (pattern 6).
