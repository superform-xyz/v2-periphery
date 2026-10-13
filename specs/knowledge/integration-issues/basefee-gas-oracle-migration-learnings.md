---
title: BasefeeGasOracle migration — non-obvious findings
category: integration-issues
component: SuperOracle / SuperGovernor / oracles
date: 2026-08-18
tags: [oracle, chainlink-deprecation, basefee, governance-timelock, fork-tests, submodule]
related:
  - specs/basefee-gas-oracle/technical-spec.md
  - specs/basefee-gas-oracle/research/specflow-analysis.md
---

# BasefeeGasOracle migration — non-obvious findings

Context: replacing the deprecated Chainlink Fast Gas / Gwei feed (mainnet GAS_QUOTE→WEI_QUOTE in
SuperOracle) with a `block.basefee`-derived oracle. Full spec: `specs/basefee-gas-oracle/`.

## 1. `queueOracleUpdate` has ONE global pending slot with no collision guard

`SuperOracleBase.sol:126-147` — a second `queueOracleUpdate` during the 1-week timelock silently
overwrites the first (no revert, no distinguishing event; the first proposal's clock is discarded).
`queueProviderRemoval` DOES guard (`PENDING_UPDATE_EXISTS`), `queueOracleUpdate` does not.
**Rule: before `executeOracleUpdate`, verify on-chain that `pendingUpdate` still matches what you
queued, and freeze other oracle governance during the window.** Also: `executeOracleUpdate` is
`_ORACLE_MANAGER_ROLE`-gated (NOT permissionless like SuperBank's merkle-root execute) — someone
must remember to call it.

## 2. SuperOracle provider removal is all-or-nothing

There is no per-pair feed removal (`_validateOracleInputs` rejects `feed == address(0)`).
`executeProviderRemoval` kills the ENTIRE provider across all pairs. On mainnet the SUPERFORM
provider serves UP→USD (FixedPriceOracle `0x66b3...565c`) — removing it to roll back a gas-feed
mistake would break upkeep pricing's USD→UP hop. **Rollback for a bad feed = re-queue a corrected
address at the same (base, quote, provider) slot; another full timelock.**

## 3. SuperOracle AVERAGE drops stale feeds instead of reverting

`_getQuoteFromOracle(revertOnError=false)` returns 0 for stale/broken feeds and `_getAverageQuote`
skips them; it reverts `NO_VALID_REPORTED_PRICES` only when ZERO providers are valid. This makes
additive registration (new feed under a second provider) a zero-flag-day migration pattern: the
dying feed blends for ≤ `feedMaxStaleness` (1 day) after freezing, then drops automatically.

## 4. Governor enforces a 300s staleness floor

`SuperGovernor.setOracleFeedMaxStaleness*` reverts `MAX_STALENESS_TOO_LOW` below `_minStaleness`
(300 at deploy). In fork tests you cannot set a feed's staleness to 1s to force-stale it — use
`governor.getMinStaleness()` and warp far enough past it (the 1-week timelock warp suffices).

## 5. Fork tests that warp past the timelock stale every Chainlink feed

After `vm.warp(+1 weeks)`, all real Chainlink data on the fork is stale. Raise staleness for every
feed in the conversion path (`setOracleMaxStaleness` + `setOracleFeedMaxStalenessBatch`) or reads
revert. Pattern established in `test/integration/oracles/UpOracleUpdate.t.sol:346-368`.

## 6. `block.basefee` is 0 in fee-field-less `eth_call`

geth (PR #23027) disables basefee accounting when no gas-price fields are passed — a plain
`cast call` on a basefee-derived oracle returns only the additive term, and any view that folds it
in (e.g. `getUpkeepCostPerSingleUpdate` post-migration) understates. Off-chain consumers must pass
`--gas-price`/`maxFeePerGas` for true quotes. On-chain callers and Foundry fork tests are
unaffected (fork tests see the forked block's basefee).

## 7. Fork-test baselines must be relative, not frozen constants

Asserting cost against a hardcoded "0.2157 UP as of Aug 18" conflates registration correctness
with gas-market drift and goes flaky. Capture the baseline **on the same fork block**
(pre-migration cost) and assert the post-migration value against that.

## 8. Local `lib/v2-core` submodule ahead of dev breaks the periphery build

If v2-core is checked out on a newer branch (e.g. `feat/rh-deployment`), interface drift
(`ISuperHook` etc.) and moved files (PendleRouterSwapHook → `deprecated/`) break compilation of
dev-based branches. Fix: `git -C lib/v2-core checkout <recorded-commit>` (find it via
`git ls-tree HEAD lib/v2-core`). Separately, `test/integration/SuperVault/SuperVault.Pendle.t.sol`
does not compile even at dev's recorded commit — skip with `--skip "SuperVault.Pendle"`.

## 9. The "Fast Gas / Gwei" feed answers in WEI (decimals()=0)

Despite the name. Verified live: answer ~1.45e8 ≈ 0.145 gwei. Any consumer scaling by 1e9 because
of the name creates the classic 1e9 bug. The replacement deliberately says "Basefee Gas / Wei".
Guard: fork-test unit-parity assertion (new answer within [0.2x, 5x] of the live feed's).
