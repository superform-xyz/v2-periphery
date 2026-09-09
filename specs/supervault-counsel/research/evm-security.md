# Security Research Report: `SuperVaultCounsel` Immutable Governance Adapter

**Primary reference**: `/Users/cosming/1.Coding/Superform/superform-specs/guidelines/solidity/vulnerabilities.md` (Superform internal vuln DB; note: it lives in the `superform-specs` repo, not v2-core/v2-periphery).

---

## 1. RELEVANT VULNERABILITY PATTERNS

### 1.1 Access control on propose / execute / veto (§2.1, §35.5, §35.2)
- The adapter multiplexes four authority tiers (curator-proposer, operator, guardian, SuperGovernor takeover). Every typed forward and state transition needs an explicit, correct modifier.
- **Proposer/executor role confusion (§35.5)**: decide explicitly whether execution of a matured proposal is operator-only (a stalled/compromised operator can indefinitely block valid governance — liveness DoS) or permissionless (then no state-sensitive parameter may be read at execution that the caller can pre-manipulate).
- **Privileged executor bypass (§35.2)**: verify no path (including takeover) lets a privileged address change a governed parameter *without* the veto window. Takeover must be scoped to *replacing the adapter*, never to mutating parameters through it.

### 1.2 Timelock bypass (§35.1, §35.2, §35.6, §14.1)
- 3-day veto window is defensible only if paired with monitoring that alerts guardians at propose time. The `[window end, 7d)` execution interval is a grace period — operator-only execution + short grace invites strategic blocking/expiry griefing.
- Boundary inclusivity: bypass hides in `>=` vs `>` at both edges. Execution at exactly `proposedAt+window` shortens the veto window by one block; veto allowed at the execution block creates a race — pick veto-wins and test.
- **Queue manipulation (§35.3)**: re-propose of an identical payload must not reset/erase a veto already cast (argues for monotonic ids over content hashes).

### 1.3 Governance front-running & execution manipulation (§34.5, §6.1)
- Up to 7 days pass between propose and execute; an operator can time a threshold-loosening execution to coincide with a PPS excursion. Consider re-validating conditions at execution.
- **Manifest equivocation**: if the on-chain proposal commits to a root while the manifest is off-chain, the proposer can publish manifest A for guardian sign-off and execute a root whose preimage is manifest B. The commitment must uniquely and verifiably determine the leaf set reviewed. Avoid `abi.encodePacked` with multiple dynamic fields in the binding hash (§9.4).

### 1.4 Live-role-check pitfalls (§14.4, §34.6)
- Guardian removed mid-window → in-flight malicious proposal loses its only check with no notice. Guardian added mid-window → can veto immediately (desirable but non-deterministic authority). Document and test both transitions.
- A compromised SuperGovernor that can flip `isGuardian` controls whether any veto can occur — the veto subsystem is only as trustworthy as SuperGovernor's guardian management.

### 1.5 Proposal replay (§9.1, §39.2)
- Monotonic id + terminal status (executed/vetoed/expired) so nothing re-executes, re-vetoes, or revives. Content-hash identity would collide identical payloads and allow reviving vetoed content.

### 1.6 Payable-forward `msg.value` bugs (§13.3, §14.3, §8.1)
- Never check/reuse `msg.value` across loop iterations or fan-out; relay exactly `msg.value`, never resident balance; check the forwarded call's success.

### 1.7 Sweep-function abuse (§37.3, §37.5, §18.1.3, §D.2)
- If any governed logic reads `address(this).balance`/`balanceOf(this)`, donations or sweeps can be timed to corrupt it — the adapter holds no accounting state, keep it that way.
- Sweep must never accept `from`/`amount`/`to` params; recipient hard-coded; only unencumbered residuals.
- Forced ETH (selfdestruct/coinbase) can inflate balance (§D.2/SWC-132) — sweep-by-balance is fine only because no logic depends on balance.

### 1.8 ETH-refund reentrancy via `receive()` (§1.1, §1.2, §8.2)
- Hook-execution refunds land on the adapter; a callee could re-enter forwards or sweeps. CEI + `nonReentrant` on the payable relay; refund recipients constrained.

---

## 2. EXPLOIT PRECEDENTS

| Incident | Mechanism | Relevance | DB ref |
|---|---|---|---|
| **Beanstalk (2022, $182M)** | Flash-loaned votes → instant `emergencyCommit`, no timelock | Justifies the veto window; adapter is not token-vote-based, removing the root cause — but only if no instant path exists. Takeover must not become an "emergencyCommit" for parameters | §34.1 |
| **Tornado Cash governance (2023)** | Benign-looking proposal with hidden self-mutating payload | Maps to root↔manifest equivocation: what the guardian reviews must be exactly what executes. Keep no-delegatecall/no-generic-execute absolute | §34.5, §11.5 |
| **Audius (2022, ~$6M)** | Proxy storage collision + bypassable governance init | Immutable non-proxy adapter removes this class entirely — a genuine advantage | §2.4, §11.1 |
| **Compound Proposal 62 (2021, ~$80M)** | Honest-but-buggy proposal passed the timelock | Veto catches malicious, not honest-but-wrong: add validity predicates/bounds on governed parameters (deviation-threshold floor/ceiling) | §39.3 |
| **Resolv (2026, $25M)** | Privileged function with access control but no validity predicates; key compromise | The single most relevant precedent for the operator key: each forward should carry on-chain invariants where possible | §39.3 |
| **sDOLA donation (2026, $239K)** | Donation inflated a balance-derived rate | Never derive decisions from raw balances a donation can move | §37.3 |
| **Parity multisig (2017, $280M+)** | delegatecall + selfdestruct | Confirms banning delegatecall/generic execute; never add a "rescue" path later | §11.5, §8.3 |

---

## 3. ATTACK SURFACE MAP (per actor)

**A. Compromised operator key** — highest-value target. Can run every typed forward (hooks with ETH, redemptions, skim, pause, session keys) and time sweeps. Cannot change governed parameters (real containment boundary). Pause-griefing is instant. Mitigations: per-forward invariants, guardian invalidateAllSessionKeys, SuperGovernor takeover as remediation.

**B. Compromised curator/proposer key** — time-bounded, veto-catchable. Escape hatches: manifest equivocation, proposal spam to exhaust guardian attention (§34.2), timing execution within the 7-day window. Mitigations: unique root↔manifest binding, rate-limit/cooldown on proposals, bounds so even executed proposals can't set nonsensical values.

**C. Malicious guardian (griefing)** — can veto everything forever (governance DoS) and spam invalidateAllSessionKeys (keeper churn). Cannot steal or push. Remedy: SuperGovernor guardian rotation (live-checked → immediate). Accepted trade-off; document.

**D. Stale guardian set** — rotation mid-window silently disarms/rearms the veto. Effective veto power at any instant equals SuperGovernor's current state. Mitigations: deliberate live-semantics documentation, first-class monitoring of guardian-role events.

**E. SuperGovernor takeover interplay** — the intentional backdoor. Must be scoped to atomic adapter replacement, never parameter mutation through the adapter. Its access control is now a crown jewel. NOTE also `freezeManagerTakeover()` permanence.

**F. Keeper session keys** — leaked key = scoped operator compromise. Ensure expiries, individual revocation, generation-bump kill switch; grantedByManager==mainManager rule means keys die on manager change and can silently revive on reinstatement unless invalidated.

---

## 4. RECOMMENDED SECURITY PATTERNS

Apply:
1. **Validity predicates on every governed parameter and forward (§39.3)** — hard min/max on deviation threshold, shape checks on yield-source additions.
2. **Strong root↔manifest binding (§34.5, §6.1, §9.4)** — no packed-encoding ambiguity.
3. **Monotonic ids + terminal status enum (§9.1, §39.2, §14.4)**.
4. **Exact msg.value relay + success checks (§13.3, §8.1)**.
5. **CEI + nonReentrant across the payable/forward/sweep cluster (§1.1, §1.2)**.
6. **No balance-derived logic (§37.3, §22.2, §D.2)**.
7. **Sweep hardening (§37.5, §18.1.3)** — hard-coded recipient, no params beyond token.
8. **Proposal anti-spam (§34.2)** — cap active proposals or proposer cooldown.
9. **Boundary-correct timing (§14.1, §35.1, §35.6)**.
10. **Session-key hygiene (§39.2, §21.2)**.
11. **Events on every transition** — propose/veto/execute/expire, sweeps, session keys, and monitor SuperGovernor guardian-role events as first-class alerts.

Intentionally omitted (defensible):
- No pausability/upgradeability/proxy of the adapter itself — eliminates §11.x classes; takeover is the recovery lever.
- No fallback/delegatecall/generic execute — removes §8.2-8.4; resist later "rescue"/"multicall" additions.
- Veto-only guardian — minimal blast radius; accepted perpetual-veto griefing cost.
- Live guardian check — immediate rotation; accepted coupling to SuperGovernor state.

---

## 5. TESTING RECOMMENDATIONS

State machine / invariants:
- Exactly one of {pending, executed, vetoed, expired} at all times; terminal states absorbing. Fuzz call sequences for double-execute/re-veto/revival.
- No governed parameter changes except via a full-window, un-vetoed proposal (catches §35.2 bypass).
- Executed root always matches the manifest hash committed at propose.

Window boundaries: warp to `proposedAt+window-1/+window/+window+1`, `+expiry-1/+expiry/+expiry+1`; assert veto/execute eligibility at each; pin inclusivity.

Races: veto and execute in the same block — assert deterministic veto-wins; fuzz orderings so no interleaving yields both succeeding.

Live-guardian transitions: remove/add/rotate guardians mid-window via a mock SuperGovernor; assert documented semantics under every timing.

Nonce monotonicity: interleaved propose/execute/veto/expire across many proposals; ids strictly monotonic, payload-identical proposals independently tracked.

msg.value exactness: fuzz value vs forwarded amount; resident balance never drawn into a forward; force-feed ETH via selfdestruct before forward/sweep and assert logic unaffected.

Sweep: fuzz caller/params — recipient constant; pending-operation balances untouchable; fee-on-transfer/multi-entrypoint tokens.

Reentrancy: malicious receive()/callee re-entering forwards/sweeps during refunds.

Session keys: expiry/revoke/generation-bump interleavings; revoked/expired keys fail; invalidateAll atomically disables; reinstatement-revival scenario.

Liveness/griefing: perpetual-veto guardian model — SuperGovernor rotation is the only escape, measure time-to-recovery; proposal-spam model with rate limit.

Takeover interplay: takeover replaces the adapter but cannot mutate governed parameters through it; fuzz takeover timing against in-flight proposals.
