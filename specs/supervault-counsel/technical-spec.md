# SuperVaultCounsel Technical Specification

## Overview

`SuperVaultCounsel` is an immutable, ownerless adapter contract that occupies the SuperVault
**primary manager / curator** seat on `SuperVaultAggregator`, replacing the SuperGovernor msig in
that role. It constrains the curator key: the three sharpest levers (yield-source additions,
strategy-root replacement, PPS deviation-threshold changes) only exist behind a
propose → 3-day guardian-veto window → execute-before-expiry flow, while day-to-day operations are
typed, operator-only forwards. There is no generic call path — the adapter's entire authority is
enumerable from its ABI. The only way to replace the adapter is `SuperGovernor.changePrimaryManager`
emergency takeover, by design.

One Counsel instance is bound to exactly one strategy; all counterparty addresses and timing
parameters are immutable from the constructor.

## Problem Statement

Today the SuperVault primary-manager seat is held directly by the SuperGovernor msig. A compromised
or coerced curator key can, in a single transaction: add a malicious yield source
(`manageYieldSource` is **immediate, no timelock** — `SuperVaultStrategy.sol:462`), disable the PPS
deviation defense entirely (`updateDeviationThreshold` is **immediate and unbounded** —
`SuperVaultAggregator.sol:525`; `type(uint256).max` disables the check at `_forwardPPS`, line 1279),
or push a hostile strategy hooks-root behind only a 15-minute aggregator timelock
(`_hooksRootUpdateTimelock`, `SuperVaultAggregator.sol:78`). It can also open the 7-day replacement
bypass by adding a secondary manager who later ejects the primary
(`proposeChangePrimaryManager`, secondary-only, `_MANAGER_CHANGE_TIMELOCK = 7 days`).

The Counsel closes all of these: sensitive actions become vetoable by any live guardian for 3 days,
the secondary-manager bypass is closed by omission, and everything else the curator seat can do is
reduced to an enumerable typed surface.

## Architecture

### Actors

| Actor | Identity | Authority |
|---|---|---|
| **Operator** | Immutable address (a Safe); **also the proposer** — one key | `propose*`, `execute(id)`, all day-to-day forwards, session-key management |
| **Guardian(s)** | Any address where `SUPER_GOVERNOR.isGuardian(addr)` is true **at call time** | `veto(id)`, `invalidateAllSessionKeys()` — no positive writes |
| **SuperGovernor msig** | Root authority | Guardian role grant/revoke; `changePrimaryManager` takeover (the sole adapter-replacement path) |
| **Keepers** | Session keys on `SuperVaultExecutor`, granted by the Counsel | Permission-scoped strategy ops (unchanged from today) |
| **Anyone** | — | `sweepERC20`/`sweepNative` (destination hard-coded to Operator) |

### Immutables (constructor)

```solidity
address        public immutable OPERATOR;          // Safe; proposer + executor + day-to-day
ISuperGovernor public immutable SUPER_GOVERNOR;    // live isGuardian lookup
ISuperVaultAggregator public immutable AGGREGATOR;
ISuperVaultStrategy   public immutable STRATEGY;
ISuperVaultExecutor   public immutable EXECUTOR;   // session-key module; also enrollExecutor target
uint256 public immutable VETO_WINDOW;              // 3 days
uint256 public immutable EXPIRY;                   // 7 days (from proposedAt)
uint256 public immutable MIN_DEVIATION_THRESHOLD;  // validity-predicate floor
uint256 public immutable MAX_DEVIATION_THRESHOLD;  // validity-predicate ceiling (< type(uint256).max)
```

Constructor validation: zero-check every address; `VETO_WINDOW > 0`;
`EXPIRY > VETO_WINDOW`; `0 < MIN_DEVIATION_THRESHOLD <= MAX_DEVIATION_THRESHOLD < type(uint256).max`.
Do **not** check code length on `OPERATOR` (Safes may be counterfactual). No owner, no admin, no
setters, no proxy, no fallback, no delegatecall, no approvals.

### Proposal state machine

```
None ──propose──▶ Pending ──veto (any live guardian, ANY time before execution)──▶ Vetoed (terminal)
                     │
                     ├─ t ∈ [proposedAt+VETO_WINDOW, proposedAt+EXPIRY) ⇒ Ready (derived)
                     │        └──execute (operator)──▶ Executed (terminal)
                     └─ t ≥ proposedAt+EXPIRY ⇒ Expired (derived, terminal)
```

- **Stored** statuses: `None / Pending / Executed / Vetoed`. **`Ready` and `Expired` are derived**
  in the `state(id)` view from `proposedAt` — never written by a keeper (OZ Governor pattern;
  eliminates "nobody poked the state" bugs).
- Boundary semantics (half-open, tested explicitly):
  executable iff `block.timestamp >= proposedAt + VETO_WINDOW && block.timestamp < proposedAt + EXPIRY`.
- **Veto-until-execution**: `veto(id)` succeeds any time `state(id)` is `Pending` or `Ready` —
  including the entire execution-eligibility period. No front-run window (precedent: OZ
  CANCELLER_ROLE, MetaMorpho guardian revoke, Compound admin cancel).
- Same-block race: veto-then-execute reverts the execute; execute-then-veto reverts the veto.
  Both orderings deterministic; no interleaving can produce both succeeding.
- Proposal ids: `uint256` monotonic nonce (`_nextProposalId++`), never reused. Full args stored in
  the proposal struct (Governor Bravo / MetaMorpho precedent) — `execute(id)` takes only the id, so
  argument mutation is structurally impossible and vetoed content cannot be revived under the same id.
- Expiry: an expired proposal dies; identical content may be re-proposed under a fresh id and a
  fresh full window (no fast-track).

### Storage

```solidity
enum ProposalStatus { None, Pending, Ready, Executed, Vetoed, Expired } // Ready/Expired derived only
enum ActionType     { YieldSourceAdd, StrategyRoot, DeviationThreshold }

struct Proposal {
    uint64  proposedAt;   // packed with status + actionType in one slot
    ProposalStatus status; // stored subset: None/Pending/Executed/Vetoed
    ActionType actionType;
    // typed payload (separate slots):
    address source;        // YieldSourceAdd
    address oracle;        // YieldSourceAdd
    bytes32 root;          // StrategyRoot
    bytes32 manifestHash;  // StrategyRoot
    uint256 newThreshold;  // DeviationThreshold
}
mapping(uint256 id => Proposal) internal _proposals;
uint256 internal _nextProposalId;
```

## Function Surface (final)

### Veto-gated (propose → window → veto/execute) — all propose/execute operator-only

| Function | Forwards to (on execute) | Validity predicates at propose |
|---|---|---|
| `proposeYieldSourceAdd(address source, address oracle)` | `STRATEGY.manageYieldSource(source, oracle, YieldSourceAction.Add)` | `source != 0`, `oracle != 0` |
| `proposeStrategyRoot(bytes32 root, bytes32 manifestHash)` | `AGGREGATOR.proposeStrategyHooksRoot(STRATEGY, root)` | `root != 0`, `manifestHash != 0` |
| `proposeDeviationThreshold(uint256 newThreshold)` | `AGGREGATOR.updateDeviationThreshold(STRATEGY, newThreshold)` | `MIN_DEVIATION_THRESHOLD <= newThreshold <= MAX_DEVIATION_THRESHOLD` |
| `veto(uint256 id)` | — (terminal state write) | caller passes `SUPER_GOVERNOR.isGuardian(msg.sender)` **live**; proposal Pending/Ready |
| `execute(uint256 id)` | exact stored args, per actionType | operator-only; inside `[proposedAt+VETO_WINDOW, proposedAt+EXPIRY)`; status Pending (not vetoed/executed) |

Notes:
- Batches are decomposed to singles — there is deliberately no `manageYieldSources` path.
- The enum literal `YieldSourceAction.Add` is hard-coded in the execute branch; **CORRECTION from
  the engineering summary**: the enum is `{ Add, UpdateOracle, Remove }`
  (`ISuperVaultStrategy.sol:179-183`) — `UpdateOracle` (oracle swaps) is deliberately unreachable.
- Deviation-threshold bounds are a **spec addition** (validity predicate; the aggregator setter is
  unbounded and `type(uint256).max` disables PPS defenses — Resolv-precedent hardening). A change
  outside the immutable bounds requires replacing the Counsel via takeover.
- **Strategy-root two-leg flow**: the Counsel's 3-day window guards the Counsel-internal proposal;
  `execute(id)` then calls `AGGREGATOR.proposeStrategyHooksRoot`, which starts the aggregator's own
  15-minute timelock, after which `AGGREGATOR.executeStrategyHooksRootUpdate` is **permissionless**.
  The Counsel window is the real defense; the aggregator timelock is a second, shorter fuse. Nothing
  at the Counsel layer can stop the second leg once pushed — by design.

### Typed forwards to the strategy (operator-only, immediate)

- `executeHooks(ISuperVaultStrategy.ExecuteArgs calldata args)` — `payable`, `nonReentrant`, relays
  exact `msg.value` (never resident balance)
- `fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata totalAssetsOut)`
- `fulfillCancelRedeemRequests(address[] calldata controllers)`
- `skimPerformanceFee()` — strategy blocks it for 12h post-unpause
- `removeYieldSource(address source)` — `YieldSourceAction.Remove` hard-coded; structurally cannot
  Add or UpdateOracle
- `proposeVaultFeeConfigUpdate(uint256 perfBps, uint256 mgmtBps, address recipient)` /
  `executeVaultFeeConfigUpdate()` — rides the strategy's own `PROPOSAL_TIMELOCK = 1 weeks`;
  **documented risk acceptance**: no guardian veto on fees (perf fee cap 5100 bps = 51%)
- `managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction action, uint256 staleness)` —
  strategy bounds 1 minute..1 week, own 1-week timelock

### Typed forwards to the aggregator (operator-only, immediate)

- `pauseStrategy()` / `unpauseStrategy()`
- `executeStrategyHooksRootUpdate()` — convenience; the aggregator function is already permissionless
- `proposeWithdrawUpkeep()` / `executeWithdrawUpkeep()` — the aggregator pays the **current
  mainManager**, i.e. the Counsel contract; funds then reach the Operator via the permissionless
  sweeps (documented linkage)
- `removeSecondaryManager(address manager)`
- `cancelChangePrimaryManager()` — defense against a hostile manager-change proposal from a stale
  secondary
- `enrollExecutor()` — **spec addition** (closes the enrollment gap): calls
  `AGGREGATOR.addSecondaryManager(STRATEGY, address(EXECUTOR))` with the immutable executor address
  **only**. Safe: `SuperVaultExecutor` exposes no `proposeChangePrimaryManager`, so re-adding it
  cannot reopen the 7-day replacement bypass. Without this, every enrollment (both takeover paths
  wipe ALL secondary managers) permanently kills keepers.

### Typed forwards to the Executor (session keys)

- `grantSessionKey(address sessionKey, uint256 expiry, ISuperVaultExecutor.Permission[] calldata permissions)`
  / `grantSessionKeysBatch(...)` — operator-only
- `revokeSessionKey(address sessionKey)` / `revokeSessionKeysBatch(...)` — operator-only
- `invalidateAllSessionKeys()` — **operator OR any live guardian**; generation bump. Must be called
  at every (re-)enrollment: session keys granted in a prior Counsel tenure **silently revive** if
  the same Counsel address is reinstated as mainManager (`SuperVaultExecutor.sol:98-102`).

### Housekeeping

- `sweepERC20(IERC20 token)` — permissionless; SafeERC20 `safeTransfer` of full live balance to
  `OPERATOR`; no amount/destination params; balance-snapshot pattern (fee-on-transfer tolerant;
  EOA token address reverts cleanly via SafeERC20's code check)
- `sweepNative()` — permissionless; `Address.sendValue(payable(OPERATOR), address(this).balance)`
  (full gas — Safe-compatible; never `transfer`/`send`)
- `receive() external payable {}` — bare; hook ETH refunds and upkeep withdrawals land here
- Views: `state(uint256 id)`, `getProposal(uint256 id)`, `nextProposalId()`, `canVeto(address)`

### Deliberately absent (no code path)

`manageYieldSource(UpdateOracle)`, `manageYieldSources` batch, `changeGlobalLeavesStatus`,
min-update-interval propose/cancel, `addSecondaryManager` (except the hard-coded `enrollExecutor`),
`proposeChangePrimaryManager`, generic `execute(target, bytes)`, fallback, delegatecall, approvals,
owner/admin/setters. Parameters excluded from the surface can only change via SuperGovernor takeover.

## Attack Surface Analysis

### Access Control & Roles
- [x] Four authority tiers, each an explicit check: `msg.sender == OPERATOR`;
  `SUPER_GOVERNOR.isGuardian(msg.sender)` live; permissionless sweeps; takeover happens outside the
  adapter (vuln DB §2.1, §35.5)
- [x] No path mutates a governed parameter without the veto window (§35.2); takeover replaces the
  adapter, it does not operate through it
- [x] Guardian negative-only: veto + invalidateAllSessionKeys; no positive writes (§34.6)
- [ ] Registry admin is the TCB apex: whoever grants/revokes GUARDIAN_ROLE on SuperGovernor can
  both manufacture and disable vetoes — SuperGovernor's own change-control documented as in-scope
- [ ] Zero-guardian registry silently converts vetoes to rubber stamps — off-chain heartbeat
  monitoring requirement (no on-chain floor)

### Timelock & State Machine
- [x] Half-open `[proposedAt+3d, proposedAt+7d)` with explicit boundary tests (§14.1, §35.1, §35.6)
- [x] Veto-until-execution; same-block races deterministic, veto-wins (§6.1)
- [x] Monotonic uint256 ids; terminal states absorbing; no replay/revival (§9.1, §39.2)
- [x] Expiry fixes the OZ/MetaMorpho no-expiry gap; re-propose restarts the full window
- [ ] No proposal-spam cap/cooldown in v1 — accepted guardian-fatigue risk (§34.2), mitigated by runbook

### Payable & Funds
- [x] `executeHooks` relays exact `msg.value`, never resident balance; single forward per entry (§13.3)
- [x] CEI everywhere (status written before external calls); `nonReentrant` on the payable relay
  (defense-in-depth, house style — storage-based guard, not transient: multi-chain EIP-1153 not assumed)
- [x] Holds no funds by invariant; no balance-derived logic anywhere, so donations/forced ETH are inert (§37.3, §D.2)
- [x] Sweeps: hard-coded destination, no params beyond token, SafeERC20/sendValue (§37.5)

### Governance-specific
- [ ] **Manifest equivocation (named residual risk)**: `manifestHash` is evidentiary — nothing
  on-chain proves it derives `root` (§34.5, §6.1; Tornado-governance precedent). Operational
  precondition: manifest published to an append-only channel BEFORE propose; guardians veto any
  root whose manifest is unpublished or non-reproducing. On-chain binding is infeasible for opaque roots.
- [x] Deviation-threshold bounds (immutable floor/ceiling) — honest-but-wrong and
  disable-the-defense proposals both blocked at propose time (§39.3; Compound-62/Resolv precedent)
- [ ] **Fee-config veto exclusion (named residual risk)**: up to 51% perf fee behind only the
  strategy's 1-week timelock, no guardian veto — kept per scope decision, requires pod-leader sign-off
- [ ] Guardian rotation mid-window changes the effective veto set (live semantics, documented);
  guardian-role events are first-class pager alerts

### Operational invariants (runbook, not code)
- **Never call `SuperGovernor.freezeManagerTakeover()` while any Counsel is enrolled** — it is
  permanent and removes the only adapter-replacement path
- Audit the secondary-manager list clean **before** enrollment (a hostile pre-existing secondary
  can race `proposeChangePrimaryManager` during rollout)
- Enrollment sequence: takeover/create → `enrollExecutor()` → `invalidateAllSessionKeys()` →
  `grantSessionKeysBatch(...)`
- Monitoring: page all guardians on `ProposalCreated` (minutes, not hours — 3-day budget);
  page on SuperGovernor guardian-role events; heartbeat `isGuardian` checks; guardians submit
  vetoes via private relay (Flashbots Protect) per runbook

### Exploit Precedent

| Similar case | Exploit | Relevance | Our mitigation |
|---|---|---|---|
| Beanstalk 2022 ($182M) | Instant governance execution | Why the veto window exists | No instant path for governed params; takeover replaces, never mutates |
| Tornado governance 2023 | Reviewed payload ≠ executed payload | Manifest equivocation | Stored-args execute + published-manifest precondition (residual risk documented) |
| Compound Prop 62 (~$80M) | Honest-but-buggy passed timelock | Veto can't catch honest-but-wrong | Immutable deviation-threshold bounds (validity predicates) |
| Resolv 2026 ($25M) | Access control without validity predicates | Operator key compromise | Typed surface + bounds + guardian kill-switch on session keys |
| Parity 2017 ($280M+) | delegatecall/selfdestruct | Why no generic paths | None exist; resist future "rescue" additions |

## Acceptance Criteria

### Functional
- [ ] All three veto-gated flows work end-to-end against fork-tested aggregator/strategy: propose →
  window → execute lands the exact stored args; vetoed and expired proposals can never execute
- [ ] `veto` succeeds for any live guardian at any point before execution, including the Ready
  period; reverts for non-guardians and on terminal proposals
- [ ] All operator forwards succeed for `OPERATOR` and revert for anyone else; guardian can call
  only `veto` and `invalidateAllSessionKeys`
- [ ] `enrollExecutor()` re-adds the executor after a takeover-enrollment; keepers function end-to-end
  (session key granted by Counsel → executor → strategy call succeeds)
- [ ] Sweeps deliver full balances to `OPERATOR` from any caller; `executeWithdrawUpkeep` funds
  landing on the Counsel are sweepable
- [ ] `state(id)` derives Ready/Expired correctly at every boundary

### Security
- [ ] All Attack Surface items addressed or explicitly signed off (manifest equivocation,
  fee-config exclusion, no spam cap, zero-guardian monitoring)
- [ ] Invariant suite: single-status invariant, terminal absorption, no-parameter-change-without-
  full-window, executed-root-matches-committed-manifestHash, msg.value exactness, sweep destination
  constant, nonce monotonicity
- [ ] Fuzz: window boundaries (±1s at both edges), same-block veto/execute orderings, guardian
  rotation mid-window (add/remove/empty via mock SuperGovernor), session-key
  revival-on-reinstatement, forced-ETH before forwards/sweeps
- [ ] Fork tests against deployed aggregator/strategy/executor bytecode on at least one chain

### Quality Gates
- [ ] Errors/events declared in `ISuperVaultCounsel` interface; implementation uses
  `@inheritdoc` (house convention)
- [ ] `ProposalCreated` emits decoded typed args + **absolute** `vetoDeadline`/`expiry` timestamps;
  every transition, sweep, and session-key change emits an event
- [ ] NatSpec on all externals; Solidity 0.8.30; OZ 5.3.0 non-upgradeable imports only

## Implementation

### src/SuperVault/SuperVaultCounsel.sol (skeleton)

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

contract SuperVaultCounsel is ISuperVaultCounsel, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── immutables (validated in constructor; no owner, no setters) ──
    address public immutable OPERATOR;
    ISuperGovernor public immutable SUPER_GOVERNOR;
    ISuperVaultAggregator public immutable AGGREGATOR;
    ISuperVaultStrategy public immutable STRATEGY;
    ISuperVaultExecutor public immutable EXECUTOR;
    uint256 public immutable VETO_WINDOW;   // 3 days
    uint256 public immutable EXPIRY;        // 7 days
    uint256 public immutable MIN_DEVIATION_THRESHOLD;
    uint256 public immutable MAX_DEVIATION_THRESHOLD;

    mapping(uint256 id => Proposal) internal _proposals;
    uint256 internal _nextProposalId;

    modifier onlyOperator() { if (msg.sender != OPERATOR) revert NOT_OPERATOR(); _; }

    // ── veto-gated ──
    function proposeYieldSourceAdd(address source, address oracle) external onlyOperator returns (uint256 id);
    function proposeStrategyRoot(bytes32 root, bytes32 manifestHash) external onlyOperator returns (uint256 id);
    function proposeDeviationThreshold(uint256 newThreshold) external onlyOperator returns (uint256 id);

    function veto(uint256 id) external {
        if (!SUPER_GOVERNOR.isGuardian(msg.sender)) revert NOT_GUARDIAN();
        ProposalStatus s = state(id);
        if (s != ProposalStatus.Pending && s != ProposalStatus.Ready) revert PROPOSAL_NOT_VETOABLE(id, s);
        _proposals[id].status = ProposalStatus.Vetoed;              // effects before nothing — terminal
        emit ProposalVetoed(id, msg.sender);
    }

    function execute(uint256 id) external onlyOperator {
        Proposal memory p = _proposals[id];
        if (state(id) != ProposalStatus.Ready) revert PROPOSAL_NOT_READY(id, state(id));
        _proposals[id].status = ProposalStatus.Executed;            // CEI: effect before interaction
        if (p.actionType == ActionType.YieldSourceAdd) {
            STRATEGY.manageYieldSource(p.source, p.oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        } else if (p.actionType == ActionType.StrategyRoot) {
            AGGREGATOR.proposeStrategyHooksRoot(address(STRATEGY), p.root); // aggregator 15-min fuse follows
        } else {
            AGGREGATOR.updateDeviationThreshold(address(STRATEGY), p.newThreshold);
        }
        emit ProposalExecuted(id, msg.sender);
    }

    function state(uint256 id) public view returns (ProposalStatus) {
        Proposal memory p = _proposals[id];
        if (p.status == ProposalStatus.Pending) {
            if (block.timestamp >= uint256(p.proposedAt) + EXPIRY) return ProposalStatus.Expired;
            if (block.timestamp >= uint256(p.proposedAt) + VETO_WINDOW) return ProposalStatus.Ready;
        }
        return p.status;
    }

    // ── day-to-day typed forwards (operator-only; exact-msg.value relay on the payable one) ──
    function executeHooks(ISuperVaultStrategy.ExecuteArgs calldata args) external payable onlyOperator nonReentrant {
        STRATEGY.executeHooks{ value: msg.value }(args);
    }
    function removeYieldSource(address source) external onlyOperator {
        STRATEGY.manageYieldSource(source, address(0), ISuperVaultStrategy.YieldSourceAction.Remove);
    }
    function enrollExecutor() external onlyOperator {
        AGGREGATOR.addSecondaryManager(address(STRATEGY), address(EXECUTOR)); // hard-coded target only
    }
    function cancelChangePrimaryManager() external onlyOperator {
        AGGREGATOR.cancelChangePrimaryManager(address(STRATEGY));
    }
    // ... remaining forwards per Function Surface (fulfill*, skim, fee-config, PPS-expiration,
    //     pause/unpause, withdraw-upkeep, removeSecondaryManager, session-key functions) ...

    function invalidateAllSessionKeys() external {
        if (msg.sender != OPERATOR && !SUPER_GOVERNOR.isGuardian(msg.sender)) revert NOT_AUTHORIZED();
        EXECUTOR.invalidateAllSessionKeys(address(STRATEGY));
    }

    // ── housekeeping ──
    function sweepERC20(IERC20 token) external { token.safeTransfer(OPERATOR, token.balanceOf(address(this))); }
    function sweepNative() external { Address.sendValue(payable(OPERATOR), address(this).balance); }
    receive() external payable { }
}
```

Interface `src/interfaces/SuperVault/ISuperVaultCounsel.sol` carries all errors
(SCREAMING_SNAKE_CASE per house style, parameterized where debuggable), events, enums, and structs.

### Event schema (observability is a security feature)

```solidity
event ProposalCreated(uint256 indexed id, ActionType indexed actionType, address indexed proposer,
                      address source, address oracle, bytes32 root, bytes32 manifestHash,
                      uint256 newThreshold, uint256 vetoDeadline, uint256 expiry); // absolute timestamps
event ProposalVetoed(uint256 indexed id, address indexed guardian);
event ProposalExecuted(uint256 indexed id, address indexed executor);
event ERC20Swept(address indexed token, uint256 amount);
event NativeSwept(uint256 amount);
event ExecutorEnrolled();
event AllSessionKeysInvalidated(address indexed caller);
// + one event per typed forward (operator-action audit trail — the forwards bypass the veto
//   window by design, so post-hoc monitoring must be strongest exactly there)
```

## Implementation Phases

### Phase 1: Core contract
- [ ] `ISuperVaultCounsel` interface (errors, events, enums, structs)
- [ ] Constructor + immutables + validation
- [ ] Proposal state machine (propose ×3, veto, execute, state view)
- [ ] All typed forwards + sweeps + receive

### Phase 2: Tests
- [ ] Unit: state machine, auth matrix (operator/guardian/anon × every function), boundaries,
  same-block races, bounds predicates, sweep behavior (incl. FOT/no-return/EOA tokens)
- [ ] Invariant/fuzz suite per Acceptance Criteria
- [ ] Fork integration: enrollment via mock takeover → enrollExecutor → session keys → keeper
  round-trip; strategy-root two-leg flow; withdraw-upkeep → sweep flow; guardian rotation via
  the real SuperGovernor role machinery

### Phase 3: Ops & rollout
- [ ] Guardian runbook (private-relay veto path, pager wiring, isGuardian heartbeats)
- [ ] Enrollment runbook (secondary-list audit → takeover → enrollExecutor →
  invalidateAllSessionKeys → grant keys), never-freeze policy
- [ ] v2-monitoring config for ProposalCreated / guardian-role events
- [ ] Deployment script + per-chain instance wiring

## Risks & Residual Acceptances (pod-leader sign-off required)

| # | Risk | Status |
|---|---|---|
| 1 | Manifest equivocation (manifestHash evidentiary only) | Residual — mitigated by publish-before-propose convention + guardian veto of unpublished roots |
| 2 | Fee-config outside the veto path (≤51% perf fee, 1-week strategy timelock only) | Residual — kept per scope decision |
| 3 | Perpetual-veto guardian griefing / invalidateAllSessionKeys griefing | Accepted — remedy is SuperGovernor guardian rotation (immediate, live-checked) |
| 4 | Zero/stale guardian set disarms veto silently | Accepted — off-chain monitoring requirement |
| 5 | Operator liveness: mature proposals can expire un-executed | Accepted — re-propose to recover |
| 6 | `freezeManagerTakeover()` would make the Counsel irreplaceable | Operational policy: never freeze while enrolled |
| 7 | Proposal spam / guardian fatigue (no cap/cooldown in v1) | Accepted — runbook mitigation |
| 8 | Registry admin ⊇ guardian power (SuperGovernor TCB) | Documented — SuperGovernor change-control in scope |

## References & Research

- Repo facts (verified file:line): [research/repo-analysis.md](./research/repo-analysis.md)
- Governance precedent (MetaMorpho, OZ, Compound, Lido, Security Councils): [research/best-practices.md](./research/best-practices.md)
- OZ 5.3.0 APIs and house patterns: [research/framework-docs.md](./research/framework-docs.md)
- Vulnerability mapping (superform-specs vulnerabilities.md §refs): [research/evm-security.md](./research/evm-security.md)
- Flow permutations and open-question resolution: [research/specflow-analysis.md](./research/specflow-analysis.md)
- Decisions log: [interview-notes.md](./interview-notes.md)
