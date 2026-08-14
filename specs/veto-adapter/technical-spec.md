# SuperVaultVetoAdapter Technical Specification

## Overview

`SuperVaultVetoAdapter` is a thin, immutable contract installed as the **primary manager** of one selected SuperVault strategy. The curator loses direct manager access and becomes the adapter's *operator*. Three call families are gated behind a propose → review-window → veto/execute flow; every other manager function the pilot vault needs is an explicit typed pass-through; everything else is structurally unreachable. Any live SuperGovernor guardian can permanently veto a pending proposal. The contract implements Control 1 of the counsel pilot ("Counsel <> Engineering Alignment"); Control 2 (takeover runbook) is operational but this spec's tests must prove the adapter never obstructs it.

Design maxims: no proxy, no owner, no generic calls, no funds at rest, events are the product.

## Problem Statement

`SuperVaultStrategy.manageYieldSource(Add)` and `SuperVaultAggregator.proposeStrategyHooksRoot` are direct primary-manager powers with no exact-call cancellation path (the native guardian veto is a blanket runtime stop that also blocks unwind hooks). Counsel requires a narrow, exact-proposal veto over those two families without replacing the existing hook/merkle authorization system.

## Architecture

```
curator (operator Safe)                     guardians (SuperGovernor GUARDIAN_ROLE)
        │ propose / execute / typed forwards        │ veto(id, reason)
        ▼                                           ▼
        ┌─────────────────────────────────────────────┐
        │            SuperVaultVetoAdapter            │  ← primary manager
        │  immutable: STRATEGY, SUPER_GOVERNOR,       │
        │             OPERATOR, REVIEW_WINDOW, EXPIRY │
        │  aggregator/executor resolved live via      │
        │  SUPER_GOVERNOR.getAddress(...)             │
        └──────┬──────────────┬──────────────┬────────┘
               ▼              ▼              ▼
     SuperVaultStrategy  SuperVaultAggregator  SuperVaultExecutor
```

- **Files**: `src/SuperVault/SuperVaultVetoAdapter.sol`, `src/interfaces/SuperVault/ISuperVaultVetoAdapter.sol` (errors + events + structs in the interface, repo style).
- **Solidity 0.8.30**, OZ 5.3.0 (`ReentrancyGuard`, `SafeERC20` for sweep only). No AccessControl (immutable operator + live `isGuardian`).
- **Trust root**: `SUPER_GOVERNOR` immutable (same as `SuperVaultStrategy`); aggregator and executor resolved per-call via `SUPER_GOVERNOR.getAddress(...)` so registry migrations don't strand the adapter.

## Proposal state machine

```solidity
enum ProposalType { YieldSourceAdd, StrategyRoot, DeviationThreshold }
enum Status { None, Pending, Vetoed, Executed }   // Expired & Ready derived from time

struct Proposal {
    ProposalType kind;
    Status status;
    uint64 windowEndsAt;    // block.timestamp + REVIEW_WINDOW at propose
    uint64 expiresAt;       // windowEndsAt + EXPIRY
    address source;         // YieldSourceAdd
    address oracle;         // YieldSourceAdd
    bytes32 root;           // StrategyRoot
    bytes32 manifestHash;   // StrategyRoot, required non-zero
    uint256 deviationThreshold; // DeviationThreshold
}
mapping(uint256 => Proposal) public proposals;   // id = ++proposalCount (single namespace)
```

Rules (all from security research, Sonne/Tornado/Nomad precedents):
- `id` = monotonic nonce — no content hashing, no collision surface, identical content re-proposable under a fresh id and fresh window.
- Transitions check exact prior state (`== Pending`), never negative checks (`Status.None == 0` must never pass).
- `execute(id)` takes **only the id**; forwarded calldata is assembled from storage — argument mutation is structurally impossible.
- `execute` requires `Status.Pending && block.timestamp >= windowEndsAt && block.timestamp < expiresAt`, operator-only; CEI: set `Executed`, emit, then forward; `nonReentrant`.
- `veto(id, reason)` requires only `Status.Pending` — valid the entire lifetime until execute lands (closes the execute-front-runs-veto race). Terminal. Reason string emitted for the legal audit trail.
- Public `state(id)` view returns derived `{None, Pending, Ready, Vetoed, Executed, Expired}`.

## Interface

```solidity
// ── veto-gated proposals ─────────────────────────────────────────
function proposeYieldSourceAdd(address source, address oracle) external returns (uint256 id);   // onlyOperator
function proposeStrategyRoot(bytes32 root, bytes32 manifestHash) external returns (uint256 id); // onlyOperator; manifestHash != 0
function proposeDeviationThreshold(uint256 newThreshold) external returns (uint256 id);         // onlyOperator
function veto(uint256 id, string calldata reason) external;   // live SUPER_GOVERNOR.isGuardian(msg.sender)
function execute(uint256 id) external;                        // onlyOperator, nonReentrant
function state(uint256 id) external view returns (DerivedStatus);

// ── typed forwards → strategy (onlyOperator, immediate) ──────────
function executeHooks(ISuperVaultStrategy.ExecuteArgs calldata args) external payable; // nonReentrant; forwards exactly msg.value
function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata totalAssetsOut) external;
function fulfillCancelRedeemRequests(address[] calldata controllers) external;
function skimPerformanceFee() external;
function removeYieldSource(address source) external;          // YieldSourceAction.Remove hard-coded
function proposeVaultFeeConfigUpdate(uint256 perfBps, uint256 mgmtBps, address recipient) external;
function executeVaultFeeConfigUpdate() external;
function managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction action, uint256 staleness) external;

// ── typed forwards → aggregator (onlyOperator, immediate) ────────
function pauseStrategy() external;
function unpauseStrategy() external;
function executeStrategyHooksRootUpdate() external;           // completes non-vetoed root after aggregator 15-min timelock
function proposeWithdrawUpkeep() external;
function executeWithdrawUpkeep() external;                    // upkeep tokens land on adapter → sweep
function removeSecondaryManager(address manager) external;
function cancelChangePrimaryManager() external;               // defense vs hostile stale-secondary proposal

// ── typed forwards → executor (session keys) ─────────────────────
function grantSessionKey(/* mirror ISuperVaultExecutor */) external;      // onlyOperator (+ batch variants)
function revokeSessionKey(address sessionKey) external;                   // onlyOperator (+ batch variants)
function invalidateAllSessionKeys() external;                 // onlyOperatorOrGuardian — enrollment & pre-takeover

// ── housekeeping ─────────────────────────────────────────────────
function sweepERC20(address token) external;   // permissionless, full balance → OPERATOR (SafeERC20, balance-based)
function sweepNative() external;               // permissionless, call() with success check → OPERATOR
receive() external payable;                    // strategy ETH refunds; NO fallback function
```

Constructor: `(strategy, superGovernor, operator, reviewWindow, expiry)` — all immutable; reverts on any zero address, `reviewWindow == 0`, `expiry == 0`, `reviewWindow > 30 days`. Placeholder durations until counsel decides: **3-day window, 7-day expiry**.

Deliberately absent (no code path): `manageYieldSource(Add/UpdateOracle)` direct, `manageYieldSources` batch, `proposeStrategyHooksRoot` direct, `addSecondaryManager`, `proposeChangePrimaryManager`/`executeChangePrimaryManager`, `changeGlobalLeavesStatus`, min-update-interval proposals, `updateDeviationThreshold` direct, any `fallback`, `delegatecall`, `approve`, assembly, CREATE.

## Events

```solidity
event Proposed(uint256 indexed id, ProposalType indexed kind, address source, address oracle,
               bytes32 root, bytes32 manifestHash, uint256 deviationThreshold,
               uint64 windowEndsAt, uint64 expiresAt);
event Vetoed(uint256 indexed id, address indexed guardian, string reason);
event Executed(uint256 indexed id, address indexed operator);
// + one attribution event per typed forward (target-side events show only the adapter as sender)
event Swept(address indexed token, uint256 amount);   // token == address(0) for native
```

Watchers need zero `eth_call`s: the `Proposed` event carries the full payload and both timestamps.

## Attack Surface Analysis

### Access control & bypass (vulnerabilities.md §2, §35)
- [x] Every external function operator-gated, guardian-gated, or provably-safe permissionless (sweeps only) — one missed gate = public manager power
- [x] `Remove` enum hard-coded (caller-supplied enum would be an Add bypass)
- [x] No fallback; unknown selectors revert; default-deny state checks (Nomad)
- [x] No path from operator to `addSecondaryManager`/manager-change family — **THE invariant** (7-day ejection bypass)
- [x] Constructor zero-address/bounds validation (no owner to fix a misdeploy)

### Proposal lifecycle (§9, §14)
- [x] Nonce ids — no `encodePacked` collisions, no replay, no cross-type ambiguity
- [x] Vetoed/Executed terminal; expired never executes; strict boundary comparisons tested at ±1s
- [x] Veto valid for whole Pending lifetime — closes execute-front-runs-veto TOCTOU (§6.1)
- [x] Operator-only execute — Sonne Finance 2024 ($20M: permissionless timelock execute let the attacker pick timing)
- [x] Expiry — no sleeper proposals (§34.5); Beanstalk lesson: no fast path around the window, ever

### Forwarding (§13, §1)
- [x] `executeHooks` forwards exactly `msg.value`, never balance (force-fed ETH test)
- [x] CEI + `nonReentrant` on `execute` and `executeHooks`; hooks re-entering the adapter can only reach sweeps (harmless, fixed destination)
- [x] Adapter never calls `approve`/`delegatecall` (Multichain/Furucombo class) — grep-level CI check
- [x] Sweeps balance-based (fee-on-transfer safe), destination immutable

### Cross-contract races (specflow analysis)
- [x] Root that passes the adapter window still has the aggregator's own 15-min timelock; eviction over a bad root pairs `setStrategyHooksRootVetoStatus` with takeover in one governance batch (permissionless root-execute front-run)
- [x] Session-key generation untouched by manager change — guardian bumps via adapter **before/with** takeover; replacement manager bumps after
- [x] Enrollment atomic: emergency `changePrimaryManager` (clears secondaries) + `invalidateAllSessionKeys` in one Safe batch; non-atomic gap monitored, `cancelChangePrimaryManager` as reactive defense

### Key-compromise blast radius (document verbatim for counsel)
- Operator key, no veto: hook execution **bounded by already-active merkle roots** (the real ceiling), fulfill/cancel, yield-source Remove, fee config (own 1-week timelock + caps), PPS-expiration, pause games, session-key grants. Behind the window: source adds, new roots, deviation threshold — every path to authorizing *new* fund flows or weakening PPS defenses.
- Guardian key: veto-DoS of strategy evolution + session-key invalidation spam. No fund access. Vault continues on current config — fail-safe, not fail-dead.
- All-guardians-rotated-out mid-window: degrades to pure delay; monitored, deliberately NOT an on-chain `guardianCount > 0` check (guardians could brick execution by resigning).

### Exploit precedent
| Precedent | Loss | Our mitigation |
|---|---|---|
| Sonne Finance 2024 | $20M | operator-only execute + expiry |
| Tornado governance 2023 | governance capture | exact stored args; mandatory off-chain manifest→root reproduction before execute |
| Beanstalk 2022 | $182M | no emergency/fast execute path exists |
| Multichain/Furucombo/Socket/Dexible | $1.4–15M | no generic forwarding, no approvals, no funds |
| Nomad 2022 | $190M | exact-state checks, default-deny |
| Compound Prop 62 | ~$80M+ | instant negative-power veto + external takeover, tested unobstructed |

## Acceptance Criteria

### Functional
- [ ] Three proposal types flow propose → window → veto/execute with nonce ids, stored args, `execute(id)`-only
- [ ] Veto: any live guardian, whole Pending lifetime, terminal, reason emitted
- [ ] Execute: operator-only, `[windowEndsAt, expiresAt)` only, exact stored args forwarded
- [ ] All typed forwards work end-to-end against the live strategy/aggregator/executor on a Base fork
- [ ] `manifestHash != 0` enforced on root proposals
- [ ] Sweeps deliver full ETH/token balances to the operator; permissionless; fee-on-transfer safe
- [ ] Session-key grant/revoke/invalidate forwards work; `invalidateAllSessionKeys` callable by operator or guardian

### Security (all must have tests)
- [ ] No reachable path from any actor to any disabled selector (selector-recorder invariant)
- [ ] Vetoed ⇒ never executes; Executed ⇒ terminal (incl. reentrant hook attempt); Expired ⇒ never executes; boundaries ±1s
- [ ] Same-block veto/execute race: first lands wins, loser reverts cleanly, both orderings
- [ ] Third-party execute of matured proposal reverts (Sonne)
- [ ] `executeHooks` forwards exactly `msg.value` under force-fed ETH
- [ ] Authorization matrix fuzzed over {operator, live guardian, ex-guardian, mid-window-added guardian, random}
- [ ] Adapter holds no residual balances after sweep; never emits `Approval`
- [ ] Zero occurrences of `delegatecall`/assembly/`approve`/CREATE in adapter source (CI grep) + Slither clean

### Operational / integration (fork tests on Base)
- [ ] Atomic enrollment batch: takeover-install + generation bump in one multisend; post-state verified (adapter is mainManager, zero secondaries, old session keys dead, curator has no manager role)
- [ ] Non-atomic enrollment gap: hostile stale-secondary `proposeChangePrimaryManager` → `cancelChangePrimaryManager` via adapter cancels it
- [ ] Full root lifecycle: adapter propose → un-vetoed → execute → aggregator 15-min timelock → `executeStrategyHooksRootUpdate` → root active; and the last-resort path: guardian `setStrategyHooksRootVetoStatus` within the 15-min window
- [ ] Bad-root eviction: blanket root veto + SuperGovernor takeover in one batch; permissionless root-execute cannot front-run
- [ ] Takeover eviction with proposals in every state: adapter cleanly evicted, stale proposals revert cleanly, generation bump (pre-takeover via guardian, post-takeover via new manager) kills operator-granted keys
- [ ] Correlation invariant: every aggregator `proposeStrategyHooksRoot` in any adapter test tx co-occurs with the adapter's `Executed` event
- [ ] Duplicate-content proposals: second matured proposal reverts at strategy (`already exists`) without corrupting adapter state
- [ ] Superman regression: manager operations submitted via the adapter ABI end-to-end

## Test Plan

- **Unit** (`test/unit/SuperVaultVetoAdapter.t.sol`): state machine, auth matrix, boundaries, constructor validation, events — against mock strategy/aggregator/executor with a selector recorder.
- **Invariant** (forge-std StdInvariant handler, inline `forge-config`, run under `FOUNDRY_PROFILE=ci`): the 10 invariants from `research/evm-security.md` §5 (never-disabled-selector, terminal states, args fidelity, balance hygiene, id uniqueness, veto liveness).
- **Fork** (`test/integration/SuperVault/SuperVaultVetoAdapter.fork.t.sol`, template: `ValidatorBonding.fork.t.sol`): Base mainnet via `vm.createSelectFork(vm.envString("BASE_RPC_URL"))`; SuperGovernor `0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4`, Aggregator `0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698`, Executor `0x183e3171EEf801cE2A29FD48B3b21188f241875d`, USDC strategy `0x5bE8c059A8E101d24B107aFb5A013feF505280b9`; role granting via the OZ 5.x slot-0 `vm.store` trick; timelock bypass via `vm.warp`.

## Dependencies & Risks

| Risk | Category | L | I | Mitigation | Precedent |
|---|---|---|---|---|---|
| Missed gate on a typed forward | Access Control | Low | Critical | per-function auth tests + fuzzed matrix | — |
| Operator key compromise | Operational | Med | High | veto window on all new-fund-flow paths; blast radius documented | Radiant 2024 $50M |
| Execute front-runs veto | MEV/TOCTOU | Med | High | veto valid whole Pending lifetime | — |
| Permissionless-execute timing abuse | Business Logic | — | — | operator-only execute + expiry | Sonne 2024 $20M |
| Root bait-and-switch via manifest | Business Logic | Med | High | manifestHash required + mandatory off-chain reproduction | Tornado 2023 |
| Bad root activates during eviction | Cross-Chain/Race | Low | High | paired blanket-veto+takeover runbook step, fork-tested | — |
| Stale secondary hostile takeover | Access Control | Low | High | atomic enrollment + cancelChangePrimaryManager | — |
| Stale session keys post-takeover | Access Control | Med | Med | pre-takeover guardian bump + post-takeover manager bump, fork-tested | Executor docs :98-102 |
| All guardians rotated mid-window | Operational | Low | Med | monitoring + liveness drills; no on-chain bricking check | — |
| Funds stranded on adapter | Vault Accounting | Med | Low | permissionless sweeps to immutable operator; deploy-checklist ETH-receive probe | — |
| Wrong immutables at deploy | Operational | Low | Critical | constructor validation + post-deploy fork dry-run checklist | Parity 2017 |

**Open operational items (not blockers for implementation):** final window/expiry durations (counsel); redemption-continuity SLA sizing session-key expiry (ops); pilot vault selection (Week 1 of the 30-day plan).

## Implementation Plan

1. **Interface + contract skeleton** — `ISuperVaultVetoAdapter.sol` (errors/events/structs), constructor, modifiers, state machine.
2. **Proposal flows** — three propose functions, veto, execute with per-type dispatch, `state()` view.
3. **Typed forwards** — strategy, aggregator, executor groups + sweeps + `receive()`.
4. **Unit + invariant tests** — mocks with selector recorder; handler campaign.
5. **Fork tests** — enrollment, lifecycle, eviction, Superman regression scenarios.
6. **Hardening pass** — Slither, CI grep gate, gas snapshot, natspec completeness.

## References
- Source doc: "Counsel <> Engineering Alignment" (Notion export)
- Decisions: [interview-notes.md](./interview-notes.md) (13 decisions + selector matrix)
- Research: [repo-analysis](./research/repo-analysis.md) · [best-practices](./research/best-practices.md) · [framework-docs](./research/framework-docs.md) · [evm-security](./research/evm-security.md) · [specflow-analysis](./research/specflow-analysis.md)
- Vulnerability DB: `superform-specs/guidelines/solidity/vulnerabilities.md`
- Targets: `src/SuperVault/SuperVaultStrategy.sol`, `src/SuperVault/SuperVaultAggregator.sol`, `src/SuperVault/SuperVaultExecutor.sol`, `src/SuperGovernor.sol`
