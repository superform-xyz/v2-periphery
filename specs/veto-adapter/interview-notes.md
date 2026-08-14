# Veto Adapter — Interview Notes

**Date:** 2026-08-14
**Source document:** "Counsel <> Engineering Alignment" (Notion export, `Counsel Engineering Alignment 3ba35672200c80858f17df917638a798.md`)
**Linear issue:** N/A
**Security mode:** auto-enabled (on-chain feature)

## Feature summary

A thin contract (`SuperVaultVetoAdapter`) installed as the selected SuperVault's **primary manager**, replacing the curator, who becomes the adapter's *operator*. The adapter gates exactly two primary-manager call families behind a propose → review-window → veto/execute flow:

1. `manageYieldSource(source, oracle, Add)` (and batch additions), and
2. `SuperVaultAggregator.proposeStrategyHooksRoot(strategy, newRoot)` — every replacement strategy root, because a root is opaque onchain.

All other manager operations the pilot vault needs are explicitly typed pass-throughs (no delay) or intentionally disabled. This is Control 1 of the counsel pilot; Control 2 (SuperGovernor takeover runbook) is operational and out of this contract's scope, but the adapter must not obstruct it.

## Decisions from the interview

| # | Question | Decision |
|---|----------|----------|
| 1 | Who can call `execute(proposalId)` after the review window? | **Operator only.** Nobody can force-execute a proposal the curator abandoned. |
| 2 | Review window / proposal expiry configuration | **Immutable at deploy** (constructor params). Placeholder values until counsel decides: 3-day review window, 7-day expiry after the window opens. Changing them = redeploy. |
| 3 | Batch yield-source additions (`manageYieldSources`) | **Decompose to singles.** No batch propose function; each source is its own proposal; execute forwards a single `manageYieldSource` call. Each addition individually vetoable. |
| 4 | Veto authorization | **Live `SuperGovernor.isGuardian(msg.sender)` check at veto time.** Tracks guardian rotation automatically. |
| 5 | Non-Add yield-source actions | **Remove = immediate typed forward** (administrative registry deletion, per the doc). **Update = disabled** (oracle changes explicitly out of pilot scope). |
| 6 | Operator (curator) rotation | **Immutable.** Operator fixed in constructor; key rotation = redeploy + manager change. Zero admin surface. |
| 7 | Location & testing | **v2-periphery**, `src/SuperVault/SuperVaultVetoAdapter.sol`. Foundry unit tests + fork tests against a Base mainnet SuperVault deployment. |
| 8 | Selector matrix breadth | **Full operational parity** — forward all four groups (see matrix below). User understands disabled selectors are unreachable while the adapter is primary manager, recoverable only via SuperGovernor takeover + redeploy; chose to forward groups 3 and 4 anyway to keep the curator operational. |
| 9 | `cancelChangePrimaryManager` | **Forward it** (operator-only). Defense-in-depth: lets the adapter cancel a hostile primary-manager-change proposal from a stale secondary manager. The rest of the manager-change family stays disabled. |
| 10 | SuperVaultExecutor session keys | **Forward grant/revoke** — `grantSessionKey`, `revokeSessionKey`, batch variants (operator-only) plus `invalidateAllSessionKeys` (operator or guardian). Keeps Superman keeper automation working; keys still die on generation bumps at enrollment/takeover. |
| 11 | Stray assets on adapter | **Permissionless sweep to operator** — `receive()` for strategy ETH refunds; `sweepERC20(token)` / `sweepNative()` send full balance to the immutable operator (anyone can call; destination fixed). `executeWithdrawUpkeep` pays upkeep tokens to the current mainManager (the adapter), so this is required. |
| 12 | `updateDeviationThreshold` | **Veto-gated** (third proposal type, `proposeDeviationThreshold`). Security research flagged it as the sharpest no-veto lever under operator-key compromise (widens PPS-manipulation defenses). Moves from typed-forward list to veto path. |
| 13 | Security-pattern resolutions | Veto valid for the proposal's entire Pending lifetime (never window-bounded — closes the execute-front-runs-veto race). `manageYieldSource(Remove)` forward hard-codes the `Remove` enum. Proposal id = monotonic nonce; `execute(id)` takes only the id, args read from storage. |

## Selector matrix (as decided)

Verified against `src/SuperVault/SuperVaultStrategy.sol` and `src/SuperVault/SuperVaultAggregator.sol` in this repo.

### Veto-gated (propose/delay/veto/execute)
| Target | Function | Notes |
|--------|----------|-------|
| Strategy | `manageYieldSource(source, oracle, Add)` | via `proposeYieldSourceAdd`; batch decomposed to singles |
| Aggregator | `proposeStrategyHooksRoot(strategy, newRoot)` | via `proposeStrategyRoot(root, manifestHash)`; manifest hash published in the proposal event |

### Typed forwards (operator-only, immediate)
| Target | Function | Gate on target |
|--------|----------|----------------|
| Strategy | `executeHooks(args)` | `_isManager` |
| Strategy | `fulfillRedeemRequests(...)` | `_isManager` |
| Strategy | `fulfillCancelRedeemRequests(controllers)` | `_isManager` |
| Strategy | `skimPerformanceFee()` | `_isManager` |
| Strategy | `manageYieldSource(source, address(0)?, Remove)` | `_isPrimaryManager` — immediate administrative deletion |
| Strategy | `proposeVaultFeeConfigUpdate(...)` / `executeVaultFeeConfigUpdate()` | `_isPrimaryManager` (has own strategy timelock) |
| Strategy | `managePPSExpiration(action, staleness)` | propose/execute/cancel |
| Aggregator | `pauseStrategy(strategy)` / `unpauseStrategy(strategy)` | `isAnyManager` |
| Aggregator | `executeStrategyHooksRootUpdate(strategy)` | completes a non-vetoed root proposal after aggregator timelock |
| Aggregator | `proposeWithdrawUpkeep(strategy)` / `executeWithdrawUpkeep(strategy)` | mainManager-only / permissionless-after-timelock respectively |
| Aggregator | `updateDeviationThreshold(strategy, threshold)` | mainManager-only |
| Aggregator | `removeSecondaryManager(strategy, manager)` | mainManager-only |
| Adapter | `invalidateAllSessionKeys()` | forwards Executor generation bump; callable by operator AND guardian (needed at enrollment and immediately after takeover) |

### Explicitly disabled (no code path exists in the adapter)
| Function | Why |
|----------|-----|
| `manageYieldSource(..., Add)` direct / `manageYieldSources` batch | must go through veto path |
| `manageYieldSource(..., Update)` | oracle changes out of pilot scope |
| `proposeStrategyHooksRoot` direct | must go through veto path |
| `addSecondaryManager` | closes the secondary-manager → 7-day primary-change bypass |
| `proposeChangePrimaryManager` / `cancelChangePrimaryManager` / `executeChangePrimaryManager` | adapter replacement only via SuperGovernor emergency takeover, by design |
| `changeGlobalLeavesStatus` | global-leaf administration out of pilot scope |
| `proposeMinUpdateIntervalChange` and related | out of pilot scope |
| Any generic call / arbitrary forwarding | forbidden by the alignment doc |

Notes: `depositUpkeep` is callable by anyone directly (pulls from `msg.sender`) and `claimUpkeep` is SuperGovernor-only — neither needs forwarding.

## Requirements carried from the alignment doc

- Proposals bind strategy, action type, and **exact arguments**; any mutation (source, oracle, root, manifestHash, proposalId) must fail.
- Only the operator can propose; only a live SuperGovernor guardian can veto; veto is **permanent** for that proposal.
- Execution impossible before window elapses or after veto; proposals expire and cannot be replayed.
- Every replacement strategy root goes through the veto window; the adapter never classifies roots onchain. Manifest hash is stored/emitted; root reproduction from the manifest happens off-chain before execute.
- The veto actor gets **no positive powers** — cannot execute hooks, add sources, or move assets (exception: `invalidateAllSessionKeys`, a purely protective action required by the takeover runbook).
- The curator must have **no callable path** to add a secondary manager or reach a disabled selector.
- The adapter must never become fee recipient (operational constraint on manager-change calls; also the adapter never passes itself as recipient).
- Superman (off-chain ops) integrates against the adapter ABI, not `SuperVaultStrategy` directly; regression tests required.
- Active-root policy unchanged: the veto does not restrict use already authorized by either active root, nor global-leaf unbanning — documented, not covered.

## Non-functional requirements

- Minimal retrofit: no proxy, no upgradeability, no owner/admin role, immutable configuration.
- Solidity/Foundry, matching v2-periphery conventions (OZ 5.x non-upgradeable where needed).
- Fork tests on Base mainnet deployment must cover the full veto test list and bypass tests from the alignment doc.

## Out of scope

Generic policy engine, recovery-only contract, depositor voting, veto over fees/oracles/global leaves, production deployment decision, legal sufficiency claims. Control 2 (takeover drill) is a runbook/test exercise, not new contract code — but adapter tests must prove takeover cleanly evicts the adapter.
