# Security Analysis Report

## Metadata
- **Target:** BasefeeGasOracle changes on `feat/basefee-gas-oracle` — `src/oracles/BasefeeGasOracle.sol`, `script/DeployBasefeeGasOracle.s.sol`, `script/utils/ConfigBase.sol` (new constant), `script/DeployV2Periphery.s.sol` (new check block), 3 test files
- **Mode:** review (inline scan + 3 parallel agents: vulnerability scanner, best practices, EVM security researcher)
- **Date:** 2026-08-18
- **Contract Types Detected:** Oracle adapter (AggregatorV3Interface) / general
- **Files Analyzed:** 7
- **Vulnerability Database:** `superform-specs/guidelines/solidity/vulnerabilities.md` (36 sections, 300+ patterns)

## Summary
| Severity | Count | Blocks Merge |
|----------|-------|-------------|
| P0 Critical | 0 | — |
| P1 High | 0 | — |
| P2 Medium | 2 | No |
| P3 Low | 11 | No |

## Verdict
**PASS** — No P0 or P1 findings. Safe to proceed. The vulnerability scanner traced the full consumer path (`_answer` → `_getQuoteFromOracle`/`_getAverageQuote` → `_convertGasToUpkeepToken` → `updatePPS` try/catch) and confirmed no exploitable defect; both P2s are risk-management items, not code vulnerabilities.

> **Adjudication note:** the external research agent initially rated the gas-spike→auto-pause
> coupling P1. Downgraded to P2 by the merging reviewer: the exposure is pre-existing (the
> Chainlink Fast Gas feed tracked spikes identically, with a fast-premium on top, and the
> InsufficientUpkeep auto-pause is untouched aggregator design). The delta introduced by this PR
> is only the ~1.3–1.8x amplification from the deliberate 2x policy.

## P0 Findings
None found.

## P1 Findings
None found.

## P2 Findings (Should Fix / Should Track)

### [P2-1] Gas-spike → mass auto-pause coupling (pre-existing, amplified ~1.5x by the 2x policy)
- **File:** system-level (`src/oracles/BasefeeGasOracle.sol:213` input → `SuperVaultAggregator.sol:1299` auto-pause)
- **Category:** DoS / Oracle
- **Description:** `block.basefee` has no protocol ceiling and has organically spiked 10–50x within minutes (NFT mints; the 2020 spam event that cost Chainlink nodes ~700 ETH). At 2x multiplier a spike multiplies the per-update charge proportionally in the same transaction; strategies whose prefunded upkeep balance is sized for calm markets hit `InsufficientUpkeep` → auto-pause + ppsStale, potentially fleet-wide during one gas event. The keeper choosing the execution block also chooses the read basefee (timing, not manipulation — proceeds go to the protocol, so no attacker profit).
- **Exploit Scenario:** No attacker needed: a network-wide gas spike while balances are low pauses many strategies at once; recovery is per-strategy manual unpause + post-unpause-timestamped signatures.
- **Real-World Precedent:** Sep 2020 Ethereum gas spike / Chainlink node gas-drain (~700 ETH).
- **Mitigation (recommended, out of this PR's code scope):** v2-monitoring alert on strategy upkeep balance vs `3×basefee + 10 gwei` worst-case charge; keeper policy to defer non-urgent PPS updates during extreme basefee; consider a consumer-side per-update charge cap as future work. An oracle-side `maxAnswer` clamp was considered and rejected — a silent clamp is the LUNA/Venus anti-pattern (undercharges invisibly during genuine spikes).
- **Reference:** vulnerabilities.md §6.3, §24.10; OWASP SC10 (DoS).

### [P2-2] Bare `vm.expectRevert()` on the timelock-not-elapsed assertion voids that test's coverage
- **File:** `test/integration/oracles/BasefeeGasOracleMigration.t.sol:111` (also :104 and `UpkeepCostRealFlow.t.sol:162`, which are lower stakes)
- **Category:** Test Coverage
- **Description:** The assertion that `executeOracleUpdate` reverts before the timelock elapses accepts *any* revert — a role mismatch or unrelated failure would pass the test while the timelock property goes unverified.
- **Secure Pattern:** Qualify with the specific custom-error selector (`TIMELOCK_NOT_ELAPSED`, `NO_ORACLES_CONFIGURED`, stale-data error respectively).
- **Reference:** vulnerabilities.md §36 (comprehensive testing); house convention in `test/oracles/BasefeeGasOracle.t.sol` (all reverts selector-qualified).
- **Status: FIXED (2026-08-19)** — all three sites now use `ISuperOracle.NO_ORACLES_CONFIGURED` / `ISuperOracle.TIMELOCK_NOT_ELAPSED` / `ISuperOracle.ORACLE_UNTRUSTED_DATA` selectors; suites re-run green.

## P3 Findings (Consider Fixing)

| # | Finding | File | Disposition |
|---|---------|------|-------------|
| 1 | Floating pragma `^0.8.30` + MIT SPDX | `BasefeeGasOracle.sol:1-2` | **Accepted** — matches the feed-adapter family convention (SuperformGasOracle, FixedPriceOracle both use MIT + `^0.8.30`; core contracts use Apache-2.0 + pinned). solc is pinned 0.8.30 in foundry.toml, so bytecode/CREATE2 determinism holds in practice. |
| 2 | `getRoundData(id)` returns current data for any id instead of reverting | `BasefeeGasOracle.sol:157` | **Accepted** — matches sibling behavior, documented in NatSpec; SuperOracle discards round fields. Latent footgun only for hypothetical round-walking integrators. |
| 3 | `updatedAt = block.timestamp` removes the staleness off-switch for this feed | `BasefeeGasOracle.sol` | **Accepted by design** — the value cannot be stale; this is exactly what closes the free-upkeep hole. Residual: staleness cannot eject the feed; the ejection path is re-queue (7d). `paramsLastUpdatedAt` + setter events cover config-staleness monitoring. |
| 4 | Basefee proposer-influenceable ±12.5%/block; keeper-timeable | `BasefeeGasOracle.sol:213` | **Accepted, documented** — trust model in NatSpec restricts to fee-charging; answer ≤ 3×basefee + 10 gwei is fuzz-asserted. |
| 5 | Setters instant (no timelock) vs 7-day feed registration | `BasefeeGasOracle.sol:126-134` | **Accepted** — blast radius hard-bounded (~1.5x vs deployed policy); split keys; note DEFAULT_ADMIN can always re-grant itself GAS_MANAGER (inherent OZ semantics, admin = multisig). Monitoring alert on setter events recommended. |
| 6 | `runCheck` only detects default-calibration deployments | `DeployBasefeeGasOracle.s.sol:81` | **FIXED (2026-08-19)** — added a `runCheck` overload taking the knobs + NatSpec on the default overload's limitation. |
| 7 | No chainId guard; L2 `block.basefee` excludes L1 DA costs | `DeployBasefeeGasOracle.s.sol` | **FIXED (2026-08-19)** — console warning on `chainId != 1` (warning not revert, so mainnet-forking vnet/staging keep working). |
| 8 | `ORACLE_BASEFEE_GAS_MAINNET = address(0)` placeholder silently skips the smoke-check require until filled | `ConfigBase.sol:69` | **Accepted** — deliberate sentinel semantics, documented; runbook item to fill post-deploy. |
| 9 | Inline `keccak256("SUPERFORM")` where `PROVIDER_SUPERFORM` constant exists | `DeployV2Periphery.s.sol:1271` | **FIXED (2026-08-19)** — uses `PROVIDER_SUPERFORM`. |
| 10 | Duplicated fork-test helpers/constants across the two integration files | both integration tests | **Fix optional** — shared abstract base would keep prod addresses in one place. |
| 11 | Emit-before-write in setters (sibling uses cache-old → write → emit); missing NatSpec on the two internal setters; `paramsLastUpdatedAt` in its own slot | `BasefeeGasOracle.sol:190-207` | **FIXED (2026-08-19)** — setters now cache-old → write → stamp → emit; `@dev` NatSpec added. Slot packing declined (hot read path already single-slot). |

## Attack Surface Summary
- **External Entry Points:** `latestRoundData`, `getRoundData`, `latestAnswer`, `decimals`, `description`, `version` (all view/pure); `setMultiplierBps`, `setPriorityFeeWei` (GAS_MANAGER_ROLE); OZ role management (DEFAULT_ADMIN).
- **Value Transfer Points:** none in the contract; downstream, the answer prices UP-token upkeep deducted from strategy balances in `SuperVaultAggregator.updatePPS`.
- **Oracle Dependencies:** `block.basefee` (input); consumed by SuperOracle's AVERAGE alongside the Chainlink Fast Gas feed until its deprecation.
- **Cross-Contract Interactions:** none outbound (no external calls anywhere in the contract — no reentrancy surface).
- **Upgrade Mechanisms:** none (not upgradeable); config limited to two bounded knobs.

## Adjudicated agent conclusions (verification highlights)
- Overflow: needs basefee > ~2^241 wei — unreachable (total ETH supply ≈ 2^87 wei); SafeCast is defense-in-depth. Sound.
- `uint80(block.number)`: truncation unreachable; SuperOracle discards round fields (verified at `SuperOracleBase.sol:347-351`). Sound.
- Role-string reuse with SuperGovernor: OZ roles are per-contract; no shared registry; no cross-contract confusion. Ops note: same EOA on both contracts = one key touches both.
- CREATE2 griefing: constructor args are committed in the initcode hash — an attacker cannot plant a differently-configured contract at the expected address; pre-deploying identical initcode deploys the intended contract and post-checks still run. Not exploitable.
- Catch blocks: all bare (`DeployV2Periphery.s.sol:1272-1289`, `SuperOracleBase.sol:352`, `SuperVaultAggregator.sol:289`) — no returnbomb surface.
- Test bands: [0.2x, 3x]/[0.2x, 5x] fail a 1e9 unit error by ~8 orders of magnitude; bit-exact formula and 3-hop replication assertions leave no room for a masked unit bug. Maintenance note: fork-band tests may flake after Chainlink freezes the Fast Gas feed (~Sep 2026) as its snapshot diverges from live basefee.
- GAS_QUOTE/WEI_QUOTE sentinels: `BoringERC20.safeDecimals` returns 18 for codeless addresses, so 18/18 cancel and `quote = gasAmount × answer` exactly — matches test assertions.
- Constructor event ordering (old=0 in constructor events): true prior storage state, atomic, no external calls. Not a finding.

## Coding Standards Findings
`forge fmt --check` passes on all new files. Full compliance on: NatSpec for externals, old/new events on both setters, ALL_CAPS custom errors, script require-string convention, test naming/banners/expectEmit patterns, lint-suppression justifications, ConfigBase constant style. Violations: the P3 items #9 (inline hash), #11 (emit ordering, internal NatSpec), plus P2-2 (bare expectRevert).

## External Research Notes (EVM researcher)
- Oracle-misconfiguration is the dominant adapter loss class 2024–2026 (Morpho PAXG/USDC ~$230k, Steakhouse wstETH/WBTC decimals, DIA May-2026 10,000x unit compression across 16 feeds) — this PR's unit-parity + exact-mean + bit-exact fork assertions are the right guard; extend the same unit-parity check to any *future* gas provider added to the pair.
- Multi-block MEV context has shifted: 2–3 builders produce 80–95% of blocks (arXiv:2501.12827), making multi-block basefee influence structurally cheaper than pre-2024 assumptions — but the no-profit argument (charge flows to protocol) still holds; timing, not manipulation, is the practical vector (P2-1).
- `answeredInRound` deprecation confirmed (chainlink#7265); `roundId = answeredInRound = uint80(block.number)` passes both modern and legacy consumer checks.
- OWASP SC Top 10 2025: SC05/06/07/09 not applicable (no external calls, no markets, single-tx basefee manipulation impossible); SC01/03/04/08 mitigated; SC02 partially (basefee influence, bounded); SC10 DoS is the headline residual (P2-1).

## Security Knowledge Sources
- vulnerabilities.md sections: 2, 3, 4, 6, 7, 14, 15, 24.10, 25, 29, 35, 36, Appendix H
- evmresearch.io: oracle heartbeat/staleness patterns, minAnswer/maxAnswer, block-attribute manipulation, access control, L2 sequencer patterns (basefee explicitly out of the site's scope — academic sources used instead: AGHH/DISC 2023, arXiv:2304.11478, arXiv:2501.12827)
- Historical exploits cross-referenced: Morpho PAXG (2024), Steakhouse (2024), DIA (2026), LUNA/Venus (2022), Chainlink gas-spam (2020), LoopFi/Autonomint staleness findings (2024)
- Coding rules validated against `superform-specs/guidelines/solidity/coding-rules.md` + sibling-contract house style
