# Repo Research: SuperVaultVetoAdapter groundwork (v2-periphery)

## 1. SuperVaultStrategy.sol (`src/SuperVault/SuperVaultStrategy.sol`, 1135 lines)

**Access helpers** (both revert `MANAGER_NOT_AUTHORIZED()`):
- `_isManager(address)` — :840-844 — `_getSuperVaultAggregator().isAnyManager(manager_, address(this))`
- `_isPrimaryManager(address)` — :848-852 — `aggregator.isMainManager(manager_, address(this))`
- Aggregator resolved live per-call via `SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.SUPER_VAULT_AGGREGATOR())` — :832-836

**Any-manager functions** (secondary managers can also call these directly on the strategy):
- `executeHooks(ExecuteArgs calldata args) external payable nonReentrant` — :273 (`_isManager` at :274). **Payable — adapter forward must be payable and pass `msg.value`.**
- `fulfillCancelRedeemRequests(address[] memory controllers) external nonReentrant` — :300
- `fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata totalAssetsOut) external nonReentrant` — :318-324 (controllers must be sorted+unique :339)
- `skimPerformanceFee() external nonReentrant` — :373 (12h post-unpause timelock `POST_UNPAUSE_SKIM_TIMELOCK` :59)

**Primary-manager-only functions**:
- `manageYieldSource(address source, address oracle, YieldSourceAction actionType)` — :462
- `manageYieldSources(sources[], oracles[], actionTypes[])` — :468-474
  - `_addYieldSource` :871 (reverts on zero source/oracle or existing), `_updateYieldSourceOracle` :883, `_removeYieldSource` :894 (oracle param unused for Remove — pass `address(0)`)
- `proposeVaultFeeConfigUpdate(perfBps, mgmtBps, recipient)` — :496-502 (own `PROPOSAL_TIMELOCK = 1 weeks` :62)
- `executeVaultFeeConfigUpdate()` — :516
- `managePPSExpiration(PPSExpirationAction action, uint256 staleness_)` — :550-558; outer function unchecked, every branch calls `_isPrimaryManager` (:908, :923, :940). Bounds: 1 minute ≤ threshold ≤ 1 week.

**Types** (`src/interfaces/SuperVault/ISuperVaultStrategy.sol`):
```solidity
struct ExecuteArgs {                        // :117-128
    address[] hooks;
    bytes[] hookCalldata;
    uint256[] expectedAssetsOrSharesOut;
    bytes32[][] globalProofs;
    bytes32[][] strategyProofs;
}
enum YieldSourceAction { Add, UpdateOracle, Remove }        // :179-183
enum PPSExpirationAction { Propose, Execute, Cancel }       // :186-190
struct FeeConfig { uint256 performanceFeeBps; uint256 managementFeeBps; address recipient; } // :110-114
```

## 2. SuperVaultAggregator.sol (`src/SuperVault/SuperVaultAggregator.sol`, 1413 lines)

Strategy-scoped functions use `modifier validStrategy` (:108-115). Manager gate is an inline `msg.sender != _strategyData[strategy].mainManager → revert UNAUTHORIZED_UPDATE_AUTHORITY()`.

**Veto-gated targets:**
- `proposeStrategyHooksRoot(address strategy, bytes32 newRoot)` — :825; mainManager-only; sets `proposedHooksRoot` + `hooksRootEffectiveTime = block.timestamp + _hooksRootUpdateTimelock` :832-834
- `executeStrategyHooksRootUpdate(address strategy)` — :840; **permissionless** after timelock

**Timelock mechanics:** `_hooksRootUpdateTimelock = 15 minutes` default (:78), mutable only via `setHooksRootUpdateTimelock` (SUPER_GOVERNOR-gated, :757-767). Guardian veto flag: `setStrategyHooksRootVetoStatus(strategy, bool)` :864 (SuperGovernor-only, exposed to GUARDIAN_ROLE) — flips `hooksRootVetoed` on the *active* root; a blanket runtime stop, complementary to the adapter's proposal-level veto.

**Pass-through candidates:**
- `pauseStrategy` :452 / `unpauseStrategy` :472 — `isAnyManager`
- `proposeWithdrawUpkeep(strategy)` — :392, mainManager-only; `UPKEEP_WITHDRAWAL_TIMELOCK = 24 hours` :74
- `executeWithdrawUpkeep(strategy)` — :413, **permissionless**; transfers to current `mainManager` (i.e. the adapter!) :439-441 — **adapter needs an ERC20 exit path to the operator**
- `updateDeviationThreshold(strategy, threshold)` — :525, mainManager-only
- `removeSecondaryManager(strategy, manager)` — :514, mainManager-only
- `changeGlobalLeavesStatus(leaves[], statuses[], strategy)` — :539-545, mainManager-only (spec: NOT forwarded)

**Deliberately NOT forwarded (verified gating):**
- `addSecondaryManager(strategy, manager)` — :493, mainManager-only; cap `MAX_SECONDARY_MANAGERS = 5` :68
- `proposeChangePrimaryManager(strategy, newManager, feeRecipient)` — :636-643, **secondary-managers-only** :645 (`_MANAGER_CHANGE_TIMELOCK = 7 days` :77)
- `cancelChangePrimaryManager(strategy)` — :666, **mainManager-only** — ⚠️ without a forward, the adapter cannot cancel a hostile secondary-manager takeover proposal (relevant only if a stale secondary exists)
- `executeChangePrimaryManager(strategy)` — :688, permissionless after timelock; clears all secondaries :704, pending hooks root :712-713, upkeep withdrawal :707-710

**mainManager storage/change:** `_strategyData[strategy].mainManager` (`ISuperVaultAggregator.sol:47-76`), set at creation (:207), changed via `executeChangePrimaryManager` (:718) or emergency `changePrimaryManager(strategy, newManager, feeRecipient)` :575-633 — **SUPER_GOVERNOR-only** :584, bypasses timelock, clears pending manager/feeRecipient/hooksRoot/minUpdateInterval proposals, wipes ALL secondaries (:610-618), cancels pending upkeep withdrawal, calls `changeFeeRecipient(feeRecipient)` :630.
- Views: `isMainManager` :1072, `isAnyManager` :1087, `isSecondaryManager` :1082, `getSecondaryManagers` :1077, `getProposedStrategyHooksRoot` :1216, `getStrategyHooksRoot` :1211, `getHooksRootUpdateTimelock` :1003.

## 3. SuperVaultExecutor.sol

- Storage: `_sessionKeys[strategy][sessionKey] => SessionKeyData` :50, `_strategyGeneration[strategy] => uint88` :53
- `SessionKeyData { uint256 expiry; address grantedByManager; uint88 generation; uint8 permissions; }` (`ISuperVaultExecutor.sol:31-36`); `enum Permission { ExecuteHooks, FulfillCancelRedeem, FulfillRedeem, SkimFee, Pause, Unpause }` :18-25
- Validity requires `data.generation == _strategyGeneration[strategy]` (:315, :331, :410)
- **`invalidateAllSessionKeys(address strategy)`** — :161-165, `++_strategyGeneration[strategy]`, emits `AllSessionKeysInvalidated`. Gated `_validatePrimaryManager(strategy)` :436-440 → while adapter is primary manager, **only the adapter can call it**.
- `grantSessionKey` :105 / `revokeSessionKey` :141 (+ batches :118/:147) are **also primary-manager-only** — ⚠️ if the curator relies on session-key keepers, the adapter must forward grant/revoke too (gap to confirm).
- Documented pitfall :98-102: keys granted by a reinstated former manager silently reactivate; generation bump is the mitigation.

## 4. SuperGovernor.sol (`src/SuperGovernor.sol`)

- `_GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE")` :97; role admin = DEFAULT_ADMIN_ROLE :153
- **`isGuardian(address) external view returns (bool)`** — :708-710 (`hasRole(_GUARDIAN_ROLE, guardian)`); interface `ISuperGovernor.sol:417` — the live check for adapter `veto()`
- Guardian powers today: `setGlobalHooksRootVetoStatus(bool)` :260, `setStrategyHooksRootVetoStatus(address,bool)` :268
- Takeover: `changePrimaryManager(strategy, newManager, feeRecipient) onlyRole(_SUPER_GOVERNOR_ROLE)` — :200-217; blocked if `_managerTakeoversFrozen` :209 (`freezeManagerTakeover()` :230 one-way). Aggregator-side, so the adapter cannot obstruct it.

## 5. Repo conventions

- **Solidity:** `pragma solidity 0.8.30;` pinned (`foundry.toml`: `solc = "0.8.30"`, optimizer 200 runs, `ffi = true`). License: `// SPDX-License-Identifier: Apache-2.0`
- **Errors:** custom errors, SCREAMING_SNAKE_CASE, declared in the **interface** (`ISuperVaultStrategy.sol:14-21`)
- **Events:** PascalCase, declared in interface, emitted in impl
- **Natspec:** `/// @title /// @author Superform Labs /// @notice` on contracts; `/// @inheritdoc` on impls; section banners
- **Interfaces:** `src/interfaces/SuperVault/ISuperVaultVetoAdapter.sol` alongside `src/SuperVault/SuperVaultVetoAdapter.sol`
- **Tests:** `test/unit/*.t.sol`, `test/integration/SuperVault/*.fork.t.sol`. Fork pattern (`SuperVaultExecutor.fork.t.sol:16-83`): plain `Test`, hardcoded prod addresses, `vm.createSelectFork(vm.envString("BASE_RPC_URL"))` in `setUp()`. `BASE_RPC_URL` via Makefile/1Password (`Makefile:9`). Shared setups: `test/BaseTest.t.sol`, `test/integration/SuperVault/BaseSuperVaultTest.t.sol`
- **Timelock/proposal precedents:** propose/execute pair with `effectiveTime = block.timestamp + TIMELOCK`, zero-value sentinel, delete-on-execute: fee config (`SuperVaultStrategy.sol:496-536`), PPS expiration (:906-949), hooks roots (`SuperVaultAggregator.sol:825-861`), manager change (:636-729), SuperBank merkle roots (`SuperGovernor.sol:598-611`). Guardian veto flag pattern: `SuperVaultAggregator.sol:864-879`. No existing contract combines propose/veto/expiry/proposalId — closest composite is aggregator hooks-root + guardian veto.

## 6. Base mainnet deployments (fork tests)

From `script/output/prod/8453/Base-latest.json`:

| Contract | Address |
|---|---|
| SuperGovernor | `0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4` |
| SuperVaultAggregator | `0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698` |
| SuperVaultExecutor | `0x183e3171EEf801cE2A29FD48B3b21188f241875d` |
| SuperVaultStrategy (impl) | `0x770abd170404B8ed8182c04f380E567e647b457D` |

Live strategies used by existing fork tests (`SuperVaultExecutor.fork.t.sol:22-37`): USDC `0x5bE8c059A8E101d24B107aFb5A013feF505280b9`, WETH `0x2787a17fe04C73AD109370C90917d62D1899Eb6A`, cbBTC `0x0c14c751b19D4362f14f4A1D1cB963180B63fB87`, current MAIN_MANAGER `0xb3dCDaA89B0A43bcC59a9BDEEb5583EC2071066c`. Staging/demo variants under `script/output/{staging,demo}/8453/`.

## Design-relevant observations

1. `managePPSExpiration` outer function is permissionless; gating inside branches — typed forward safe as-is.
2. `executeHooks` is `payable`; forward must relay `msg.value`. Strategy refunds ETH (`receive()` :117) — adapter may need `receive()` + ETH sweep-to-operator.
3. `executeWithdrawUpkeep` pays the **current mainManager** (the adapter) — upkeep tokens land on the adapter; needs an ERC20 sweep to operator or explicit acceptance.
4. `executeStrategyHooksRootUpdate` and `executeWithdrawUpkeep` are permissionless on the aggregator — forwarding is convenience only.
5. Residual secondaries can call `_isManager` functions, pause/unpause, and `proposeChangePrimaryManager` (7-day ejection of the adapter). Enrollment must remove all secondaries; consider forwarding `cancelChangePrimaryManager` as defense.
6. Session-key `grantSessionKey`/`revokeSessionKey` are primary-manager-only and not in the forward matrix — functional gap if curator uses session-key keepers.
