# SuperVaultCounsel — v2-periphery Repository Research Report

Repo: `/Users/cosming/1.Coding/Superform/v2-periphery` (Solidity `0.8.30`, `foundry.toml:13`; Apache-2.0).

Contract map:
- `src/SuperGovernor.sol` (847 lines)
- `src/SuperVault/SuperVaultAggregator.sol` (1413 lines)
- `src/SuperVault/SuperVaultStrategy.sol` (1135 lines) — this is the "strategy contract"; `SuperVault.sol` is the ERC-4626/7540 share token that delegates to it
- `src/SuperVault/SuperVaultExecutor.sol` (517 lines) — the session-key module
- Interfaces under `src/interfaces/ISuperGovernor.sol` and `src/interfaces/SuperVault/`

---

## 1. SuperGovernor

### `isGuardian` semantics
`src/SuperGovernor.sol:708-710`:
```solidity
function isGuardian(address guardian) external view returns (bool) {
    return hasRole(_GUARDIAN_ROLE, guardian);
}
```
Live OZ `AccessControl` role check. `_GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE")` (line 97); getter `GUARDIAN_ROLE()` at 662-664.

### Guardian role management
- Initial guardian granted in constructor (line 150). Role admin for `_GUARDIAN_ROLE` is `DEFAULT_ADMIN_ROLE` (line 153), granted to the `superGovernor` msig (line 144). Guardians added/removed via standard OZ `grantRole`/`revokeRole`; **multiple guardians possible; no bespoke add/remove function**.
- Guardian powers today: `setGlobalHooksRootVetoStatus(bool)` (260-265) and `setStrategyHooksRootVetoStatus(address,bool)` (268-275), both `onlyRole(_GUARDIAN_ROLE)`, forwarding to the aggregator.

### Emergency takeover of SuperVault primary manager
`src/SuperGovernor.sol:200-217`:
```solidity
function changePrimaryManager(address strategy, address newManager, address feeRecipient)
    external onlyRole(_SUPER_GOVERNOR_ROLE)
```
- Reverts `MANAGER_TAKEOVERS_FROZEN()` if `_managerTakeoversFrozen` (line 209). Resolves aggregator from registry key `SUPER_VAULT_AGGREGATOR` and calls `ISuperVaultAggregator.changePrimaryManager` — "bypasses the timelock" (lines 214-215).

### `_managerTakeoversFrozen`
- `freezeManagerTakeover()` — lines 230-238, `_SUPER_GOVERNOR_ROLE`, **permanent one-way** ("cannot be undone"). View `isManagerTakeoverFrozen()` (674-676).
- **Spec-critical**: if `freezeManagerTakeover()` is ever called while the Counsel is primary, the Counsel becomes irreplaceable via takeover (only the 7-day secondary path would remain — which the Counsel design closes). DO NOT freeze while Counsel is enrolled.

### Other
- `resetHighWaterMark(address strategy)` — 220-227, `_SUPER_GOVERNOR_ROLE` (neutral HWM baseline for replacement managers).
- `changeHooksRootUpdateTimelock(uint256)` — 241-249, `_SUPER_GOVERNOR_ROLE`; zero allowed for emergencies.
- Governance `TIMELOCK = 7 days` constant (line 90) used for fees/PPS-oracle/min-staleness propose-execute pairs.

---

## 2. SuperVaultAggregator

Timelock constants (lines 73-81):

| Constant | Value | Line |
|---|---|---|
| `UPKEEP_WITHDRAWAL_TIMELOCK` | `24 hours` | 74 |
| `_MANAGER_CHANGE_TIMELOCK` | `7 days` | 77 |
| `_hooksRootUpdateTimelock` (mutable) | **`15 minutes` initial — VERIFIED** | 78 |
| `_PARAMETER_CHANGE_TIMELOCK` | `3 days` | 81 |
| `MAX_SECONDARY_MANAGERS` | `5` | 68 |

### Strategy hooks-root propose/execute
- `proposeStrategyHooksRoot(address strategy, bytes32 newRoot)` — 825-837. **mainManager only**. Effective = `block.timestamp + _hooksRootUpdateTimelock`. No content binding (root is opaque — the Counsel's manifest hash adds what's missing).
- `executeStrategyHooksRootUpdate(address strategy)` — 840-861. **Permissionless** after timelock.
- Guardian veto: `setStrategyHooksRootVetoStatus(address,bool)` — 864-879, callable **only by SUPER_GOVERNOR contract**; guardians reach it via SuperGovernor. NOTE: the veto flag blocks *validation of all hooks* (`validateHook` 1136-1139), not the pending proposal — an unvetoed proposal still executes.
- Views: `getProposedStrategyHooksRoot` (1216-1222), `getStrategyHooksRoot` (1211-1213), `getHooksRootUpdateTimelock` (1003-1005).

### Pause / unpause
- `pauseStrategy` — 452-467; `unpauseStrategy` — 472-487. Access: `isAnyManager` (**primary OR secondary**). Unpause records `lastUnpauseTimestamp` (feeds strategy 12h skim timelock).

### Withdraw-upkeep
- `proposeWithdrawUpkeep(address strategy)` — 392-410. **mainManager only**; always full balance; 24h timelock.
- `executeWithdrawUpkeep(address strategy)` — 413-444. **Permissionless**; pays the *current* `mainManager` (440-441).

### Secondary managers
- `addSecondaryManager(address strategy, address manager)` — 493-511. **mainManager only**; cap 5.
- `removeSecondaryManager(address strategy, address manager)` — 514-522. **mainManager only**.

### Primary manager change — the "seven-day replacement bypass" (VERIFIED)
- `changePrimaryManager(strategy, newManager, feeRecipient)` — 575-633. **Only SUPER_GOVERNOR contract**, immediate. Clears: pending manager proposal, pending fee-recipient, pending hooks-root, pending minUpdateInterval proposal, **ALL secondary managers**, pending upkeep withdrawal; then sets `mainManager` and calls `ISuperVaultStrategy.changeFeeRecipient`.
- `proposeChangePrimaryManager(strategy, newManager, feeRecipient)` — 636-663. **Only secondary managers**. Timelock `_MANAGER_CHANGE_TIMELOCK = 7 days` — VERIFIED. If the Counsel is primary and any secondary exists, that secondary can queue the Counsel's replacement with only 7 days' delay.
- `cancelChangePrimaryManager(strategy)` — 666-685. **Only current mainManager** — Counsel needs this typed forward to defend its seat.
- `executeChangePrimaryManager(strategy)` — 688-729. **Permissionless** after timelock; clears all secondaries etc.
- Views: `getPendingManagerChange` (1063-1069), `getMainManager` (1058), `isMainManager` (1072), `isSecondaryManager` (1082), `isAnyManager` (1087-1091).

### `changeGlobalLeavesStatus`
539-564: `(bytes32[] leaves, bool[] statuses, address strategy)`. **mainManager only, immediate**. Bans/unbans global-root leaves per strategy.

### Deviation threshold (LIVES HERE, not on the strategy)
`updateDeviationThreshold(address strategy, uint256 deviationThreshold_)` — 525-536. **mainManager only, immediate, NO bounds check** — `type(uint256).max` disables the deviation check entirely (`_forwardPPS` line 1279). Default `5e17` = 50% (line 71). This is what the Counsel wraps in propose → veto → execute.

### Min-update-interval proposals
- `proposeMinUpdateIntervalChange` — 886-910 (mainManager, < maxStaleness, 3-day timelock); `executeMinUpdateIntervalChange` — 913-935 (permissionless); `cancelMinUpdateIntervalChange` — 938-956 (mainManager).

### StrategyData
`src/interfaces/SuperVault/ISuperVaultAggregator.sol:47-76` — `mainManager` (53), `secondaryManagers` EnumerableSet (58), manager-change proposal fields (60-62), hooks-root fields (64-67), `deviationThreshold` (69), `bannedLeaves` (71), minUpdateInterval fields (73-74), `lastUnpauseTimestamp` (75).

---

## 3. SuperVaultStrategy (the strategy contract)

Access helpers: `_isManager` (840-844 → `aggregator.isAnyManager`), `_isPrimaryManager` (848-852 → `aggregator.isMainManager`). **The strategy holds no manager storage — everything resolves through the aggregator**; enrolling the Counsel is purely an aggregator-side `mainManager` change.

| Function | Signature | Access | Line |
|---|---|---|---|
| `executeHooks` | `(ExecuteArgs calldata args) external payable nonReentrant` — **payable VERIFIED** | any manager | 273-297 |
| `fulfillCancelRedeemRequests` | `(address[] memory controllers) external nonReentrant` | any manager | 300-315 |
| `fulfillRedeemRequests` | `(address[] calldata controllers, uint256[] calldata totalAssetsOut) external nonReentrant` — controllers sorted & unique | any manager | 318-368 |
| `skimPerformanceFee` | `() external nonReentrant` — blocked 12h after unpause (`POST_UNPAUSE_SKIM_TIMELOCK = 12 hours`) | any manager | 373-456 |
| `manageYieldSource` | `(address source, address oracle, YieldSourceAction actionType) external` — **immediate, no timelock** | **primary only** | 462-465 |
| `manageYieldSources` | batch variant | **primary only** | 468-485 |
| `proposeVaultFeeConfigUpdate` | `(uint256 performanceFeeBps, uint256 managementFeeBps, address recipient)` — `PROPOSAL_TIMELOCK = 1 weeks` **VERIFIED** (line 62) | **primary only** | 496-513 |
| `executeVaultFeeConfigUpdate` | `() external` — **also primary-gated** (517); resets HWM to current PPS (532) | **primary only** | 516-536 |
| `managePPSExpiration` | `(PPSExpirationAction action, uint256 staleness_)` — Propose/Execute/Cancel dispatcher; 1-week timelock; bounds 1 minute..1 week | **primary only** | 550-558 |
| `changeFeeRecipient` | `(address newRecipient)` | **only aggregator** | 488-493 |
| `resetHighWaterMark` | `(uint256 newHwmPps)` | **only aggregator** | 539-547 |

### `YieldSourceAction` enum — CORRECTION
`src/interfaces/SuperVault/ISuperVaultStrategy.sol:179-183`:
```solidity
enum YieldSourceAction { Add, UpdateOracle, Remove }   // middle member is UpdateOracle, NOT "Update"
```
Dispatch at `SuperVaultStrategy.sol:858-866`; `_addYieldSource` (871-878, reverts on duplicates), `_updateYieldSourceOracle` (883-890), `_removeYieldSource` (894-904).

### PPS deviation threshold
**No setter on the strategy** — it is `SuperVaultAggregator.updateDeviationThreshold` (§2).

### Key structs/enums for typed forwards
- `FeeConfig { uint256 performanceFeeBps; uint256 managementFeeBps; address recipient; }` (ISuperVaultStrategy 110-114)
- `ExecuteArgs { address[] hooks; bytes[] hookCalldata; uint256[] expectedAssetsOrSharesOut; bytes32[][] globalProofs; bytes32[][] strategyProofs; }` (117-128)
- `PPSExpirationAction { Propose, Execute, Cancel }` (186-190)
- Fee caps: `MAX_PERFORMANCE_FEE = 5100` (51%); management fee ≤ 10 000 bps.

---

## 4. Executor / session keys — `SuperVaultExecutor`

"Secondary manager contract that allows session key holders to call strategy functions… added as secondary manager on strategies" (lines 17-18). Non-upgradeable, OZ AccessControl + ReentrancyGuard, also ERC-4337 v0.7 `IAccount`.

### Session-key management (all gated `aggregator.isMainManager(msg.sender, strategy)`, lines 436-449)
- `grantSessionKey(address strategy, address sessionKey, uint256 expiry, Permission[] calldata permissions)` — 105-115
- `grantSessionKeysBatch(...)` — 118-138 (`MAX_BATCH_SIZE = 50`)
- `revokeSessionKey(address strategy, address sessionKey)` — 141-144
- `revokeSessionKeysBatch(...)` — 147-158
- `invalidateAllSessionKeys(address strategy)` — 161-165: generation bump `++_strategyGeneration[strategy]` (uint88)

### Typed keeper forwards (session-key gated via `Permission` bitmask)
`executeHooks` (payable, 172-182, ETH balance-delta refund pattern), `fulfillCancelRedeemRequests` (185-188), `fulfillRedeemRequests` (191-201), `skimPerformanceFee` (204-207), `pauseStrategy`/`unpauseStrategy` (210-221). ERC-4337 `validateUserOp` (ExecuteHooks permission only) + `executeFromEntryPoint`. Admin `sweepETH(address to)` (292-305, DEFAULT_ADMIN_ROLE) — return-bomb-safe assembly call.

### Data types (`ISuperVaultExecutor`)
- `enum Permission { ExecuteHooks, FulfillCancelRedeem, FulfillRedeem, SkimFee, Pause, Unpause }` (18-25, uint8 bitmask)
- `struct SessionKeyData { uint256 expiry; address grantedByManager; uint88 generation; uint8 permissions; }` (31-36)

### ⚠️ Spec-critical validity rule
Every session-key check requires `aggregator.isMainManager(data.grantedByManager, strategy)` (impl 316, 333, 412, 477-479; warning comment 98-102). Consequences:
1. The moment the Counsel becomes primary, **all session keys granted by the msig go dead** — keepers must be re-granted keys *by the Counsel*.
2. If the Counsel is replaced and later reinstated, old keys silently revive unless `invalidateAllSessionKeys` was called (documented at 98-102) — this is why the design calls invalidateAll "at enrollment, and again after takeover".
3. The Counsel's typed surface must include the executor's five session-key management functions.

### ⚠️ DESIGN GAP DISCOVERED — executor re-enrollment
`SuperVaultExecutor` must itself be a **secondary manager** on each strategy for keeper calls to pass the strategy's `isAnyManager` check. But enrollment of the Counsel via `changePrimaryManager` **wipes ALL secondary managers** (aggregator 595-624), and the Counsel design deliberately omits `addSecondaryManager`. Without a path to re-add the executor, keepers are permanently dead post-enrollment. Fix options: a typed `enrollExecutorAsSecondaryManager()` forward hard-coded to the immutable `SuperVaultExecutor` address (safe: the executor exposes no `proposeChangePrimaryManager`, so re-adding it does NOT reopen the 7-day bypass), or accept keepers routing exclusively through the Counsel's operator forwards.

---

## 5. Conventions

### File/contract structure
- `// SPDX-License-Identifier: Apache-2.0` + `pragma solidity 0.8.30;` (locked, `auto_detect_solc = false`).
- Section banners `/*////… NAME …////*/`; header NatSpec `@title/@author Superform Labs/@notice`.
- **All errors and events declared in the interface**, not the implementation; implementations carry `/// @inheritdoc IFoo`.
- Errors: SCREAMING_SNAKE_CASE custom errors, mostly parameterless; occasional parameterized (`BOUNDS_EXCEEDED(uint256,uint256,uint256)`).
- Events: PascalCase, indexed key addresses; proposals emit `<X>Proposed(..., effectiveTime)`, executes `<X>Updated/Changed`, cancels `<X>Cancelled`.
- Modifiers wrap tiny internal functions; simple msg.sender checks inline with `ACCESS_DENIED()`-style errors.
- Loops `for (uint256 i; i < len; ++i)`; SafeERC20; `Math.mulDiv`; EnumerableSet; forge-lint disable comments for validated casts.

### Timelock / propose-execute pattern to mirror
1. **Propose** (role-gated): validate → store proposed value + `effectiveTime = block.timestamp + TIMELOCK` → emit `<X>Proposed(..., effectiveTime)`.
2. **Execute**: revert `NO_PENDING_*` if empty, `TIMELOCK_NOT_EXPIRED()` if early → apply → zero fields → emit. Often **permissionless** (strategy fee-config execute is a role-gated exception).
3. **Cancel** (optional, proposer-gated).
4. **Veto** exists today only as the hooks-root boolean flag pattern. Nothing in the codebase implements per-proposal terminal veto or an expiry upper bound — `effectiveTime` proposals never expire today. The Counsel's `[proposedAt+3d, proposedAt+7d)` window and monotonic nonce are new patterns.

### Manager wiring (how the Counsel gets enrolled)
- Source of truth: `_strategyData[strategy].mainManager` in the aggregator; strategy and executor resolve live via `SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR)` → `isMainManager`/`isAnyManager`. No enrollment call on the strategy.
- Three enrollment paths: (1) at creation — `createVault(VaultCreationParams)` with `params.mainManager = counsel`; (2) instant takeover — `SuperGovernor.changePrimaryManager` (blocked if takeovers frozen); (3) the 7-day secondary path.
- On any primary change the aggregator wipes secondaries + pending proposals and force-sets the fee recipient — enrollment design must supply `feeRecipient`, re-add the executor (see gap above), and re-grant session keys.
- Manager can be any contract address; plain address comparisons.

### Adapter surface checklist (from verified access control)
Primary-only calls the Counsel must make: `manageYieldSource(s)`, `proposeVaultFeeConfigUpdate` + `executeVaultFeeConfigUpdate`, `managePPSExpiration`, `proposeStrategyHooksRoot`, `updateDeviationThreshold`, `changeGlobalLeavesStatus` (excluded by design), `add/removeSecondaryManager` (add excluded by design — see gap), `cancelChangePrimaryManager`, `proposeWithdrawUpkeep`, min-update-interval propose/cancel (excluded by design), executor session-key functions. Any-manager: `executeHooks` (payable), `fulfillRedeemRequests`, `fulfillCancelRedeemRequests`, `skimPerformanceFee`, `pauseStrategy`/`unpauseStrategy`. Permissionless on aggregator (no forward strictly needed): `executeStrategyHooksRootUpdate`, `executeMinUpdateIntervalChange`, `executeWithdrawUpkeep`.
- NOTE: because `executeStrategyHooksRootUpdate` is permissionless, the Counsel's veto window for roots only works if the Counsel delays its *own* call to `proposeStrategyHooksRoot` (Counsel-internal propose → 3d veto → then propose to aggregator; aggregator's 15-min timelock + permissionless execute run after).
