# Best-Practices Research: Veto-Timelock Governance Adapters (for SuperVaultCounsel)

Research scope: an immutable, ownerless adapter occupying a vault protocol's curator/primary-manager seat, with propose → 3-day veto window → execute inside [window end, window end + expiry), guardian veto-until-execution read live from a registry, typed operator-only forwards for daily ops, no generic execute/fallback/delegatecall, and permissionless sweeps to an immutable operator.

---

## 1. Prior art: veto/timelock guardian patterns

### OpenZeppelin TimelockController (proposer / executor / canceller)

The canonical general-purpose implementation (TimelockController.sol, OZ governance docs). Key traits:

- Three roles: `PROPOSER_ROLE` schedules, `EXECUTOR_ROLE` executes after `minDelay`, `CANCELLER_ROLE` may cancel any *pending* (not-yet-executed) operation. Cancellation resets the operation to Unset — this is exactly the "veto until execution" semantic, and it is the mainstream precedent for it.
- Operations are identified by `hashOperation(target, value, data, predecessor, salt)`; only the hash and a timestamp are stored. Full calldata must be re-supplied at `execute` and is checked against the hash.
- Executor role can be granted to `address(0)`, making execution **permissionless** after the delay — widely used and relevant: if SuperVaultCounsel's `execute(id)` is proposer-only, that is *stricter* than OZ's common open-executor configuration, which is fine but worth an explicit design note.
- **What OZ gets right vs. this design:** generic and battle-tested; predecessor ordering; clean state machine (Unset/Waiting/Ready/Done). **What it gets wrong for this use case:** it is a *generic* executor — arbitrary target/calldata — which is precisely the attack surface SuperVaultCounsel's typed-function design eliminates; it has **no expiry** (a scheduled-and-forgotten operation stays executable forever, a known operational hazard); roles are mutable via self-administration, so it is not "ownerless".

### Compound Timelock

`queueTransaction` stores `keccak256(abi.encode(target, value, signature, data, eta))` in a `queuedTransactions` mapping; `executeTransaction` reverts with "Transaction is stale" if `block.timestamp > eta + GRACE_PERIOD` (14 days). Forked everywhere (e.g., Uniswap). It introduced the **grace-period/expiry** idea OZ lacks. Weaknesses vs. this design: single `admin` (no separate veto role — cancellation is admin-only via `cancelTransaction`), hash-only storage, generic calldata execution.

### MetaMorpho / Morpho Vaults — the closest analog

- Owner/Curator/Guardian/Allocator split maps almost one-to-one onto SuperVaultCounsel's proposer/guardian/operator triad. Curator submits risk-sensitive changes (`submitCap`, `submitMarketRemoval`); a **typed pending slot per action** (`PendingUint192 { value, validAt }`, `PendingAddress`) holds the staged value; after `validAt`, **anyone** can call `acceptCap` etc.; the guardian (and curator/owner) can `revokePendingCap` / `revokePendingTimelock` / `revokePendingGuardian` **at any time up to acceptance** — i.e., veto-until-execution, not veto-only-during-window. Timelock has a hardcoded 1-day floor so depositors can exit (B.Protocol's decentralized-guardian writeup shows guardians can themselves be contracts — directly relevant to reading guardians from a registry).
- **What MetaMorpho gets right:** typed actions (no generic execute), full staged *values* stored on-chain (not hashes), guardian revocation until the moment of acceptance, permissionless acceptance after the window, cap-decreases/removals-to-safety are instant while increases are timelocked (asymmetric risk treatment — worth copying: vetoes and de-risking actions should never be timelocked).
- **What it gets wrong / differs:** **no expiry** — a pending cap sits executable forever after `validAt`, forcing the guardian to stay vigilant indefinitely (SuperVaultCounsel's 7-day expiry fixes this); one pending slot per action type means a new submission requires revoking the old one (fine for caps, awkward for arbitrary proposals — the monotonic-id queue in SuperVaultCounsel generalizes this correctly); guardian is a single mutable address set by owner, not a live registry.

### Lido: Easy Track and Dual Governance

- **Easy Track** is optimistic/veto governance for routine ops: motions auto-pass after 72h unless >=0.5% of LDO objects; enactment is permissionless; rejected motions deactivate. This is **veto-only-during-window** (objections counted within the motion duration), and it works because objection is a *vote tally*, not a single actor's call — a threshold crossed mid-window is decisive. For a single-guardian design, window-limited veto is strictly weaker.
- **Dual Governance**: a *dynamic* timelock — >1% of stETH in the veto-signalling escrow pauses execution 5–45 days; >10% triggers rage-quit into an immutable escrow. Notable for SuperVaultCounsel: the rage-quit escrow is deliberately **immutable** (precedent for immutable safety-critical components), and the design treats the timelock length as a function of how contested the action is. Overkill for a curator adapter, but validates the principle that the veto path must be *cheaper and faster* than the propose path.

### Optimism / Arbitrum Security Councils

Arbitrum routes normal proposals through L2 timelock + withdrawal delay + L1 timelock (~17-day exit window), while a 9-of-12 Security Council can act instantly in emergencies; Optimism's Foundation retains "cancel on timelock" levers. Lessons: (a) emergency/veto authority is held by a **multisig of rotating humans, not a contract role** — key rotation happens inside the Safe, addresses stay stable; (b) veto/cancel powers bypass all delays; (c) councils are elected/rotated off-chain and the on-chain seat is just an address — the registry-lookup pattern generalizes this.

### MakerDAO GSM / DSPause

`plot` schedules a plan (usr, tag, fax, eta), `exec` executes after delay, `drop` cancels. Two things stand out. First, `tag` is the **codehash** of the target spell — execution reverts if the target's code changed since plotting, defending against the "args mutate between propose and execute" problem at the code level. Second, `exec` runs through a `DSPauseProxy` in **isolated storage context specifically because it uses delegatecall** — an entire class of complexity SuperVaultCounsel avoids by banning delegatecall outright. The GSM delay has been governance-adjusted (30h→18h under attack pressure), illustrating why hardcoding the window in an immutable contract is a double-edged sword.

**Verdict on the overall design:** SuperVaultCounsel composes the best element of each: MetaMorpho's typed actions + guardian-revoke-until-acceptance, Compound/Aave's grace-period expiry, OZ's monotonic clean lifecycle, and Security-Council-style veto via external membership. No surveyed system has all four; the combination is sound and each piece has strong precedent.

---

## 2. Proposal storage: full args by monotonic id vs. hash

**Precedent for hash-only** (OZ TimelockController, Compound Timelock, OZ Governor where `proposalId = keccak256(abi.encode(targets, values, calldatas, descriptionHash))`): one storage slot per operation regardless of payload size — cheap to schedule; calldata is re-supplied and verified at execution. Drawbacks: (a) the on-chain state is opaque — watchers must reconstruct intent from events, and if event indexing fails there is *no on-chain way to know what a pending hash does*; (b) the executor must possess the exact original calldata; (c) hash collisions across identical operations need a salt.

**Precedent for full-args storage** (Compound Governor Bravo stores `targets/values/signatures/calldatas` arrays in the `Proposal` struct keyed by an incrementing `proposalCount`, readable via `getActions(proposalId)`; **MetaMorpho** stores the actual pending `value`/`validAt` on-chain): `execute(id)` takes no payload, so **execution cannot mutate the action** — the property SuperVaultCounsel wants. Anyone can read exactly what proposal N will do by calling a view function, which materially strengthens the guardian's position during the veto window.

**Trade-off analysis:**

- *Gas:* for typed, fixed-shape actions (set-cap, set-fee, change-allocator — a few words each), full storage costs one or two extra `SSTORE`s at propose time and often *saves* gas at execute (no calldata re-hash/compare, smaller execute calldata). The hash pattern only wins for large/variable payloads (batch calls with big bytes arrays) — which SuperVaultCounsel has banned anyway. For this design, storing args is the right call and Bravo + MetaMorpho are direct precedent.
- *Auditability:* full storage makes `getProposal(id)` the single source of truth; combine with events rather than relying on either alone.
- *Recommendation:* store args in a tight struct (pack `uint40 vetoDeadline`, `uint40 expiry`, `uint8 actionType`, and an enum status into one slot where possible); use a monotonic `uint256 nextId` (never reuse ids — Bravo precedent); mark executed/vetoed with a status field rather than deleting, so historical queries work. Consider zeroing large payload fields on terminal states for a gas refund only if payloads can be big.

One residual risk full-args storage does **not** cover: the *target's meaning* can change even if args can't (e.g., the vault swaps an underlying module between propose and execute). MakerDAO's codehash `tag` is the precedent-approved mitigation if any proposed action points at mutable external code; for typed calls into a known vault it is usually unnecessary, but note it in the security review.

---

## 3. Veto-until-execution vs. veto-only-during-window

**Precedent strongly favors veto-until-execution for single-actor guardians.** OZ's `CANCELLER_ROLE` can cancel any time before execution; MetaMorpho's guardian can revoke a pending cap any time before `acceptCap`; Compound's admin can `cancelTransaction` up to execution; Optimism's cancel-on-timelock lever is not window-bounded. Veto-only-during-window appears in *threshold/vote* systems (Lido Easy Track's 72h objection tally) where the veto is an aggregate, not a race.

The reason is a concrete race: with veto-only-during-window, at the window boundary the proposer can **front-run the guardian's veto** — observe `veto(id)` in the public mempool, and land `execute(id)` first (or simply time execution to the first block after the window while the veto tx from block N-1 is still pending). The guardian's protection then depends on transaction-ordering luck and MEV dynamics, which is exactly what a safety mechanism must not depend on. With veto-until-execution, the race inverts in the guardian's favor: veto wins in any block where both land, ordering permitting, and there is no deadline pressure at all — the guardian can veto at leisure during the entire [propose, execute) interval, including the execution-eligibility period.

**Private mempool implications:** the guardian should still submit vetoes via a private channel (Flashbots Protect) — not because the veto can be beaten (with until-execution semantics it can't be, except by an executor landing in an earlier block), but because (a) a public veto tx signals the guardian's intent and gas price, letting a malicious proposer race `execute` into the same block with higher priority fee; ensure `veto(id)` reverts cleanly (or better, no-ops with an event) if the proposal was just executed, and conversely `execute(id)` must hard-revert if vetoed — the state machine must make veto-then-execute and execute-then-veto both deterministic; (b) on L2s/side-chains with sequencer FCFS ordering, latency to the sequencer is the race, and a direct sequencer submission path should be documented in the guardian runbook.

Design detail with precedent: make `veto` accept the id and *nothing else* (no args re-supply), keep it callable by **any** live guardian (1-of-N — MetaMorpho lets curator, guardian, or owner all revoke), and never timelock or fee-gate the veto path.

---

## 4. Expiry / grace period

- **Compound:** `GRACE_PERIOD = 14 days` after `eta`; stale transactions revert.
- **Aave Governance V2:** executors have a 5-day `GRACE_PERIOD`; unexecuted queued proposals transition to `EXPIRED` and must restart the full process.
- **OZ TimelockController:** no expiry — operations stay Ready forever. This is a recognized operational gap: forgotten scheduled operations become time bombs that an attacker who later compromises an executor key can fire, and watchers must track them indefinitely.
- **MetaMorpho:** also no expiry on pending values — same indefinite-vigilance burden.

**Recommended handling (aligned with the stated design):** the [vetoWindowEnd, vetoWindowEnd + 7 days) execution interval follows the Compound/Aave school and is the better practice for an immutable contract precisely because there is no admin to clean up stale state. Specifics worth adopting:

1. Enforce expiry in `execute` with a strict half-open check (`block.timestamp >= vetoDeadline && block.timestamp < vetoDeadline + EXPIRY`), Compound-style.
2. Expired proposals need no explicit cancellation — but expose `state(id)` returning an explicit `Expired` status (Aave/Bravo `ProposalState` enum precedent) so off-chain tooling doesn't have to recompute it, and optionally a permissionless `markExpired(id)`-style cleanup emitting an event for indexers (nice-to-have, not required).
3. 7 days is within precedent range (Aave 5d, Compound 14d) and reasonable against a 3-day veto window: long enough to survive weekend/multisig-coordination delays on the proposer side, short enough that guardian vigilance per proposal is bounded to 10 days total. Precedent check passes.
4. Document that re-proposing after expiry restarts the full veto window (Aave semantics) — no fast-track resubmission.

---

## 5. Immutable, ownerless governance adapters: precedent and pitfalls

Precedent for immutability at the safety layer: Lido's rage-quit escrow is immutable by design; MetaMorpho vaults are non-upgradeable with a hardcoded 1-day timelock floor; Uniswap v2/v3 core, Liquity, and Morpho Blue itself are the flagship immutable-core precedents. Upgradeability itself is a major exploit class (e.g., PAID Network's proxy-admin key compromise), so immutability *removes* attack surface as well as flexibility.

Known pitfalls and the precedent-approved mitigations:

1. **Bricking via immutable addresses.** Every immutable address (operator, registry, vault) is a permanent bet. The standard mitigation — used by Optimism/Arbitrum Security Councils and virtually every serious protocol — is to point immutable slots at **Safes (or registries), never EOAs**, so key rotation happens *inside* the pointed-to contract without touching the adapter. SuperVaultCounsel already does this for guardians (registry lookup) — apply the same standard to the immutable operator: it should be a Safe, and its signer-rotation runbook is part of the deployment, not an afterthought.
2. **Bricking via dead registry.** If the governance registry is emptied, upgraded incompatibly, or `isGuardian` starts reverting, the veto path dies while the propose/execute path lives — the worst possible failure mode. Mitigations: treat a reverting/empty registry as **fail-closed for execution** (if the veto mechanism cannot function, sensitive `execute` should not proceed) or at minimum specify and test the behavior; wrap the `isGuardian` staticcall so a revert is caught and mapped to a defined outcome rather than bubbling.
3. **Escape hatch via higher authority.** The design's own escape hatch is correct and has direct precedent: because the adapter merely *occupies a seat* (curator/primary manager) granted by the vault's owner/admin, the ultimate recovery path is the vault's higher authority reassigning the seat — analogous to MetaMorpho's owner being able to replace the curator, or a Security Council acting above the timelock. Verify explicitly, pre-deployment, that (a) the seat *is* reassignable by an authority the team controls or trusts, and (b) nothing in the adapter (e.g., accepting ownership of anything) makes it the *terminal* authority. An immutable adapter that becomes an unremovable owner is the classic bricking story.
4. **Hardcoded time parameters.** MakerDAO changed its GSM delay under live attack pressure (30h→18h); an immutable adapter cannot. 3d/7d hardcoded is acceptable (MetaMorpho hardcodes its 1-day floor) but should be justified in docs, and the seat-reassignment escape hatch is what makes it acceptable — replacement, not upgrade, is the parameter-change mechanism.
5. **No fallback/receive footguns.** With no fallback/delegatecall, tokens or ETH forced into the contract would strand — the permissionless `sweep` to the immutable operator is the right pattern (precedent: countless `skim`/`sweep`/`rescueTokens` functions; making it permissionless with a hardcoded destination removes the trust question entirely). Ensure sweep covers ETH (selfdestruct-forced) and ERC-20s, and that it **cannot touch vault shares/assets the adapter legitimately holds in its seat role**, if any — enumerate exclusions explicitly.

---

## 6. Live membership checks (`isGuardian` at call time) vs. cached roles

Checking membership **at call time against an external registry** is the more decentralization-friendly pattern and matches Security-Council practice (the council address is stable; membership churns inside it), but it imports the registry's mutation schedule into the adapter's security model. Pitfalls:

1. **Guardian removed mid-window.** A proposal is submitted while guardian G watches; G is rotated out of the registry on day 2; if no remaining guardian is watching, the veto window silently loses its watcher. This is a process risk, not a code bug — mitigate with observability (registry-change events must page the same on-call as proposal events) and by keeping veto 1-of-N over *all* live guardians so any survivor can act.
2. **Guardian added mid-window can veto immediately.** This is a feature (more protection), but note it means whoever controls the registry can always manufacture a veto — i.e., **registry admin ⊇ guardian power**. Document that the registry's own change-control (ideally itself timelocked/multisig) is part of the adapter's TCB.
3. **Registry admin ≠ veto-griefing immunity.** Conversely, whoever can *empty* the registry can disable veto. Combined with pitfall 2, the registry admin is strictly the most powerful actor in the system; the design docs must say so.
4. **TOCTOU inside a single tx** is not an issue here (membership checked in the veto tx itself), but avoid any pattern that caches an `isGuardian` result across calls (e.g., recording "vetoer" eligibility at propose time) — that would recreate OZ Governor's known snapshot-vs-execution divergence problems in the wrong direction.
5. **Interface robustness:** call `isGuardian` as a view via the interface, define behavior on revert/empty-code, and pin the registry address as `immutable` so the lookup target itself cannot be swapped out from under the adapter.

Recommendation: keep live lookup (it matches the design's ownerless ethos and Security-Council precedent), and add a `guardianRegistry()` immutable getter plus an explicit `canVeto(address) → bool` view so watchers and UIs share the contract's exact eligibility logic.

---

## 7. Events and observability for the veto window

The guardian's entire power is reaction speed inside 3 days; the event surface is therefore a first-class security feature, not logging hygiene. Precedent: OZ TimelockController emits `CallScheduled` (per call, with full target/value/data/predecessor/delay), `CallExecuted`, `Cancelled`, `CallSalt`; Bravo emits `ProposalCreated` with full args *and human description*; monitoring stacks (OpenZeppelin Defender Monitor, Forta bots such as the timelock privilege-escalation detector) key entirely off these events and alert to Slack/Telegram/PagerDuty. Lifecycle-anomaly detection (e.g., Executed-before-Scheduled for an id) is an established Forta pattern worth replicating.

Concrete recommendations:

1. **`ProposalCreated(uint256 indexed id, address indexed proposer, uint8 indexed actionType, bytes args, uint40 vetoDeadline, uint40 expiry)`** — emit *everything* needed to evaluate the proposal without an `eth_call`: decoded typed args (since actions are typed, emit typed fields, not just raw bytes, where practical), and critically the **absolute timestamps** for veto deadline and expiry (absolute times let alerting compute countdowns without chain-constant knowledge). Index `actionType` so watchers can subscribe at different severities per action.
2. **`ProposalVetoed(uint256 indexed id, address indexed guardian)`** and **`ProposalExecuted(uint256 indexed id, address indexed executor)`** — the vetoer's address matters for accountability since eligibility is registry-based and transient.
3. **`ProposalExpired(id)`** if a cleanup path exists; otherwise ensure `state(id)` view exposes Expired.
4. **Operator-forward events** for every typed daily-op call (`OperatorActionExecuted(selector/actionType, args)`) — day-to-day ops bypass the veto window by design, so they are exactly where post-hoc monitoring must be strongest; an operator-key compromise is detectable only through these.
5. **`Swept(token, amount, to)`** for the permissionless sweep.
6. **Views for watchers:** `state(id)`, `getProposal(id)` (full struct), `pendingProposalIds()` or at minimum `nextId` + non-terminal iteration support, `canVeto(address)`, `guardianRegistry()`. Off-chain systems should never need to replay events to answer "what can be executed right now."
7. **Runbook requirements (document alongside the contract):** a monitor on `ProposalCreated` paging all guardians immediately (3-day window ⇒ alert latency budget is minutes, not hours); a second monitor on the **guardian registry's** membership-change events; a pre-signed or one-click veto transaction path per guardian via a private relay (Flashbots Protect); and a heartbeat check that `isGuardian` still returns true for each expected guardian.

---

## Summary of gaps vs. precedent worth addressing

| Design element | Precedent verdict | Action |
|---|---|---|
| Typed actions, no generic execute | MetaMorpho — strong precedent | Keep |
| Full-args storage by monotonic id | Governor Bravo, MetaMorpho | Keep; pack structs, keep terminal status |
| Veto-until-execution | OZ canceller, MetaMorpho, Compound | Keep; make veto/execute mutually exclusive and race-deterministic |
| 3-day window + 7-day expiry | Aave (5d grace), Compound (14d) | Keep; expose `Expired` state; document restart-on-expiry |
| Immutable + ownerless | Morpho Blue, Lido rage-quit escrow | Keep; operator must be a Safe; verify seat is reassignable by higher authority |
| Live registry lookup | B.Protocol guardian-as-contract, Security Councils | Keep; define revert/empty behavior; registry admin is in the TCB — document |
| No expiry-free pending state | Fixes MetaMorpho's and OZ's known gap | — |
| Observability | OZ Defender/Forta patterns | Emit absolute deadlines; monitor registry changes too |
