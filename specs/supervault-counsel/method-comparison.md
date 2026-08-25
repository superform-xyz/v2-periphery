# SuperVaultCounsel — Method Comparison vs. EOA in the Primary-Manager Seat

## What seat does the Counsel hold? (read this first)

**SuperVaultCounsel replaces the msig in the SuperVault primary-manager/curator seat** on the
`SuperVaultAggregator` — the seat that runs hooks, fulfills redemptions, manages yield sources,
roots, thresholds, and keeper session keys. It does **not** hold the SuperGovernor contract's
`SUPER_GOVERNOR_ROLE`. Every capability in the original design summary is a seat function; that
is the surface this document compares. (The contract was renamed from `SuperGovernorCounsel` to
`SuperVaultCounsel` precisely to make this scoping unambiguous.)

This split is deliberate, not an omission. The `SUPER_GOVERNOR_ROLE` contains
`changePrimaryManager` — the emergency takeover that sits **above** the Counsel as the ultimate
recovery lever (guardian veto → operator cancel → takeover trumps everything). If the Counsel
held that role, a compromised or bricked Counsel would be the terminal authority with nothing
above it. The msig therefore keeps its (rare, already 7-day-timelocked) protocol duties:
takeover, protocol fees, active PPS oracle, address registry, and guardian management — see
Section 4.

This document maps every method an EOA holding the **primary-manager seat** could call directly
against the SuperVaultCounsel equivalent. Use it to evaluate coverage: **every seat capability
is reachable through the Counsel** — the sharp levers cost a 3-day guardian-vetoable window;
day-to-day operations remain single immediate calls.

**Legend**

| Term | Meaning |
|---|---|
| **Immediate** | Single operator-only typed forward, executes at once |
| **Veto-gated** | `propose*(...)` → 3-day guardian veto window → `execute(id)` inside `[proposedAt+3d, proposedAt+7d)` |
| **Composition** | Reachable by combining two Counsel operations (no direct path, by design) |

Actors: **Operator** = immutable Safe (proposer + executor + day-to-day). **Guardian** = any
address passing `SuperGovernor.isGuardian` live; may only `veto` and `invalidateAllSessionKeys`.

---

## 1. SuperVaultStrategy methods

| EOA in the seat calls | SuperVaultCounsel equivalent | Flow |
|---|---|---|
| `manageYieldSource(source, oracle, Add)` | `proposeYieldSourceAdd(source, oracle)` → `execute(id)` | Veto-gated |
| `manageYieldSource(source, oracle, UpdateOracle)` | `removeYieldSource(source)` then `proposeYieldSourceAdd(source, newOracle)` → `execute(id)` | Composition — oracle swaps deliberately get guardian review |
| `manageYieldSource(source, —, Remove)` | `removeYieldSource(source)` (Remove enum hard-coded; can never Add/UpdateOracle) | Immediate |
| `manageYieldSources(...)` (batch) | N separate single proposals | Composition — batches removed so guardians review each payload |
| `executeHooks(args)` (payable) | `executeHooks(args)` — relays exact `msg.value`, never resident balance | Immediate |
| `fulfillRedeemRequests(controllers, assetsOut)` | `fulfillRedeemRequests(controllers, assetsOut)` | Immediate |
| `fulfillCancelRedeemRequests(controllers)` | `fulfillCancelRedeemRequests(controllers)` | Immediate |
| `skimPerformanceFee()` | `skimPerformanceFee()` (strategy blocks 12h post-unpause on both sides) | Immediate |
| `proposeVaultFeeConfigUpdate(perfBps, mgmtBps, recipient)` | `proposeVaultFeeConfigUpdate(...)` — protection is the strategy's own 1-week timelock only | Immediate ⚠️ documented risk acceptance: no guardian veto on fees (perf fee cap 51%) |
| `executeVaultFeeConfigUpdate()` | `executeVaultFeeConfigUpdate()` | Immediate |
| `managePPSExpiration(action, staleness)` | `managePPSExpiration(action, staleness)` (strategy's own 1-week timelock + 1min–1week bounds) | Immediate |

## 2. SuperVaultAggregator methods

| EOA in the seat calls | SuperVaultCounsel equivalent | Flow |
|---|---|---|
| `updateDeviationThreshold(strategy, x)` | `proposeDeviationThreshold(x)` → `execute(id)` — **plus immutable MIN/MAX bounds the EOA doesn't have** (an EOA can pass `type(uint256).max` and disable PPS defenses in one call) | Veto-gated |
| `proposeStrategyHooksRoot(strategy, root)` | `proposeStrategyRoot(root, manifestHash)` → `execute(id)` — adds the manifest-hash binding for guardian reproduction; aggregator's own 15-min timelock follows | Veto-gated (two-leg) |
| `executeStrategyHooksRootUpdate(strategy)` | `executeStrategyHooksRootUpdate()` (permissionless on the aggregator anyway) | Immediate (convenience) |
| `changeGlobalLeavesStatus(leaves, statuses, strategy)` | `proposeGlobalLeavesStatus(leaves, statuses)` → `execute(id)` — both ban and unban directions; urgent defense = immediate `pauseStrategy()` | Veto-gated |
| `proposeMinUpdateIntervalChange(strategy, interval)` | `proposeMinUpdateInterval(interval)` → `execute(id)`; aggregator's own 3-day parameter timelock follows (`interval < maxStaleness` enforced there) | Veto-gated (two-leg) |
| `executeMinUpdateIntervalChange(strategy)` | `executeMinUpdateIntervalChange()` (permissionless on the aggregator anyway) | Immediate (convenience) |
| `cancelMinUpdateIntervalChange(strategy)` | `cancelMinUpdateIntervalChange()` | Immediate (defensive) |
| `addSecondaryManager(strategy, manager)` | Three paths: `enrollExecutor()` — hard-coded to the immutable SuperVaultExecutor (immediate); `proposeSecondaryManagerAdd(manager)` → `execute(id)` — arbitrary address (veto-gated); `proposeCounselMigration(newCounsel)` → `execute(id)` — wiring-validated successor offer (veto-gated) | Mixed (see each) |
| `removeSecondaryManager(strategy, manager)` | `removeSecondaryManager(manager)` | Immediate |
| `cancelChangePrimaryManager(strategy)` | `cancelChangePrimaryManager()` (seat defense against hostile secondaries) | Immediate |
| `proposeWithdrawUpkeep(strategy)` | `proposeWithdrawUpkeep()` (aggregator's 24h timelock applies to both) | Immediate |
| `executeWithdrawUpkeep(strategy)` | `executeWithdrawUpkeep()` — funds land on the **Counsel** (current mainManager); permissionless `sweepNative()`/`sweepERC20()` deliver them to the operator (an EOA was paid directly) | Immediate |
| `pauseStrategy(strategy)` / `unpauseStrategy(strategy)` | `pauseStrategy()` / `unpauseStrategy()` | Immediate |
| *(Seat handover — an EOA would `addSecondaryManager(newMgr)` and have it call `proposeChangePrimaryManager`)* | Propose-and-accept: `proposeCounselMigration(newCounsel)` → `execute(id)` seats successor as **secondary only** (the offer); successor's operator calls `newCounsel.acceptCounselSeat(feeRecipient)` (structurally restricted to the offered contract) → aggregator's 7-day timelock → permissionless completion. Retraction: `removeSecondaryManager(newCounsel)` pre-accept, `cancelChangePrimaryManager()` during the timelock | Veto-gated + accept |

## 3. SuperVaultExecutor methods (keeper session keys)

| EOA in the seat calls | SuperVaultCounsel equivalent | Flow |
|---|---|---|
| `grantSessionKey(strategy, key, expiry, perms)` | `grantSessionKey(key, expiry, perms)` (strategy auto-filled from the immutable) | Immediate |
| `grantSessionKeysBatch(strategies, keys, expiries, perms)` | `grantSessionKeysBatch(keys, expiries, perms)` | Immediate |
| `revokeSessionKey(strategy, key)` | `revokeSessionKey(key)` | Immediate |
| `revokeSessionKeysBatch(strategies, keys)` | `revokeSessionKeysBatch(keys)` | Immediate |
| `invalidateAllSessionKeys(strategy)` | `invalidateAllSessionKeys()` — **operator OR any live guardian** (extra protective power the EOA setup doesn't have) | Immediate |

## 4. Stays with the SuperGovernor msig (the actual `SUPER_GOVERNOR_ROLE` surface)

These live on the **SuperGovernor contract's own roles**, not the primary-manager seat. Neither an
EOA in the seat nor the Counsel can call them; they are unchanged by Counsel enrollment. They are
the msig's remaining duties post-enrollment — rare by nature, and already behind the
SuperGovernor's own 7-day timelocks where applicable. Constraining these too would require a
separate role-holder wrapper contract (out of scope here), and the takeover +
`freezeManagerTakeover` + guardian management would still need to remain outside any such wrapper
to preserve the recovery hierarchy:

- `changePrimaryManager(...)` — emergency takeover (the ultimate recovery lever above the Counsel)
- `freezeManagerTakeover()` — ⚠️ permanent; **never call while a Counsel is enrolled**
- `resetHighWaterMark(strategy)`
- `changeHooksRootUpdateTimelock(newTimelock)`
- `proposeGlobalHooksRoot(root)` (GOVERNOR role) and global-root veto flags (GUARDIAN role)
- Protocol fee / active-PPS-oracle / min-staleness propose-execute pairs
- Address registry (`setAddress`)
- Guardian role grant/revoke (`grantRole`/`revokeRole` on `GUARDIAN_ROLE`)

## 5. Counsel-only machinery (no EOA equivalent)

| Method | Who | Purpose |
|---|---|---|
| `veto(id)` | Any live guardian | Terminal cancel of any pending/ready proposal, valid until the moment of execution |
| `execute(id)` | Operator | Executes exact stored args of a matured, un-vetoed proposal inside `[proposedAt+3d, proposedAt+7d)` |
| `acceptCounselSeat(feeRecipient)` | Operator (of the offered successor) | Claims a migration offer; only works from a secondary seat |
| `state(id)` / `getProposal(id)` / `nextProposalId()` / `canVeto(addr)` | Anyone (views) | Monitor/guardian observability; Ready/Expired derived, never stored |
| `sweepERC20(token)` / `sweepNative()` | Anyone | Full balance to the immutable operator only; the Counsel holds no funds by invariant |
| `receive()` | — | Accepts hook ETH refunds and upkeep payouts (recovered via sweeps) |

## 6. Summary

- **Coverage:** all 25 seat methods are reachable; 7 sharp levers are veto-gated
  (yield-source add, strategy root, deviation threshold, global leaves, min-update interval,
  secondary-manager add, Counsel migration), 16 are immediate forwards, 2 are compositions
  (UpdateOracle, batch) — deliberate, so guardians review each payload.
- **Strictly safer than an EOA:** deviation-threshold bounds, manifest-hash binding on opaque
  roots, guardian kill-switch on session keys, stored-args execution (no payload mutation),
  no generic call path — the entire authority is enumerable from the ABI.
- **Timing costs vs. an EOA:** +3 days on the seven veto-gated actions; everything else
  identical (the strategy/aggregator's own timelocks apply equally to both).
- **Recovery hierarchy:** guardian veto (3d) → operator retraction/cancel → SuperGovernor
  takeover (instant, trumps everything).
