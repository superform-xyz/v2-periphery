# Security Analysis Report — Cross-chain SuperVaults (post review-round 6)

## Metadata
- **Target:** v2-periphery `src/CrossChain/*` + interfaces + deploy runbook; v2-core `src/hooks/bridges/SuperVaultCapBridgeCommon.sol`, the three `SuperVault*CapBridgeHook`s, and the Stargate/Across/deBridge destination adapters — CURRENT uncommitted working trees (periphery on top of `37c1aecb`, core on top of `c6b2f36f`)
- **Mode:** review (inline critical-pattern scan + vulnerability-DB scanner + coding-standards/docs audit + external precedent research)
- **Date:** 2026-09-08
- **Contract types detected:** bridge (Across V3 / deBridge DLN / Stargate V2 + LayerZero V2 compose), oracle (EIP-712 quorum reports with deviation bands + breaker), access-controlled accounting/cap policy, ERC-7579 hooks
- **Files analyzed:** 11 source files (3,829 lines) + 5 interfaces + runbook + specs
- **Vulnerability database:** superform-specs/guidelines/solidity/vulnerabilities.md (36 sections + appendices), coding-rules.md
- **Prior context:** 6 external review rounds (v2-periphery #336, v2-core #987). Classes already closed in those rounds were not re-reported.

## Summary
| Severity | Count | Blocks merge |
|---|---|---|
| P0 Critical | 0 | — |
| P1 High | 0 | — |
| P2 Medium | 1 (fixed in this working tree) | No |
| P3 Low | 4 (2 fixed, 2 noted) | No |

## Verdict
**PASS** — no P0/P1. The one P2 (liveness of the hub-assets deviation band) and a rotation-hazard tripwire were fixed in the same working tree; everything else is documentation or operational.

## P0 / P1
None found.

## P2

### P2-1 `hubAssets` deviation band was symmetric and not lifecycle-aware (liveness) — FIXED
- **File:** `v2-periphery/src/CrossChain/CrossChainAUMOracle.sol` (`forwardAUM`, P2-4 block)
- **Category:** DoS / oracle liveness
- **Description (VERIFIED):** the band compared the signed hub balance only to the previous hub balance and fed the breaker. Every cap-hook send shrinks the hub by exactly the reserved amount, so any deployment (or user deposit) larger than θ of the *hub* balance made every honest report soft-fail; ≤ `maxConsecutiveDeviationBreaches` retries tripped the breaker, and the only way to commit was `forceAUMUpdate`. Fail-safe (no fund loss) but it turned the emergency path into the routine path, and an unprivileged depositor could trip the breaker of a mostly-deployed vault.
- **Trace:** θ = 50 %, cap 50 %, hub 1,000, cross-chain 0. Manager bridges 600 (allowed). Honest next report `hubAssets = 400` → 60 % deviation → soft-fail + breach. Repeat → breaker → `isAUMFresh = false` → every cap-hook send reverts.
- **Fix applied (refined after an adversarial re-check of the first version):** the band is on the PUBLISHED TOTAL — `hubAssets + candidateCrossChain ≤ (prevHub + prevCrossChain + inFlight − observedOverlap)·(1+θ)` (`_publishedTotalBreach`). A first version banded the hub alone against θ of the previous total, which would have let a colluding quorum book value into the hub AND keep it cross-chain in one report (denominator envelope up to ~2× the pre-change one when the PPS backstop is inactive); the published-total form keeps the per-report envelope exactly at the pre-change `(1+θ)·(total + inFlight)` while still admitting a post-send report, an exit returning to the hub and a deposit up to θ of AUM. Downward moves are deliberately unbounded (quorum-trusted, denominator-shrinking only); the band soft-fails WITHOUT feeding the breaker. Regressions: `test_ForwardAUM_HubAssetsDeviationSoftFails` (over-bound soft-fails, breaker untouched, exactly-at-bound commits, downward commits) and `test_R7_HubAndCrossChainCannotBothBookTheSameCapital` (5,000/5,000: 15,000 + 7,500 soft-fails, 10,000 + 5,000 commits).
- **Related hardening:** `MAX_MAX_STALENESS` lowered from 24h to 4h (two reservation/confirmation cycles), so a stale denominator can no longer back many allocation cycles by configuration; runbook step 14 says to set `maxStaleness` near the reporting cadence.

## P3

### P3-1 Address-book rotation of the registry orphans reservations and silently reopens headroom — TRIPWIRE ADDED
- **Files:** `SuperGovernor.setAddress` (instant, no timelock); consumers `CrossChainPositionCapGuard.validateAllocation`, `CrossChainAUMOracle._registry()`, `SuperVaultCapBridgeCommon`
- **Description (VERIFIED, governance-trust):** re-pointing `CROSS_CHAIN_POSITION_REGISTRY` while capital is Open/Consumed/Active makes the guard read exposure 0 from the new registry while positions live in the old one.
- **Fix applied (superseded by the round-7 identity handshake, kept as defense in depth):** `validateAllocation` reverts `REGISTRY_ORACLE_DESYNC` when the resolved registry differs from `oracle.reportRegistry(strategy)` — the registry the latest committed report was booked against, written at every commit — so a rotation fails closed until a fresh quorum-signed report is committed under the new registry. The amount check `registry.getEffectiveCrossChainExposure(strategy) < oracle.latestReport(strategy).totalCrossChainAssets` remains as a ledger-mismatch backstop; on its own it could not catch a rotation while the old registry held only Open or zero-valued Pending exposure (committed total 0, as the external reviewer showed). That inequality holds by construction after every commit (each booked unit is matched by a confirmed value, a counted reservation, or the observed excess; verified across never-reported, below/above-band observations, confirm, reconcile, drain, deregister, governance invalidate/release, re-consume, soft-fail and force paths), so it only fires on a mid-flight REGISTRY rotation. An oracle rotation is covered differently: it zeroes `latestReport`, so `isAUMFresh` fails closed until the new oracle is force-seeded. Rotating both together opens headroom by governance decision — the runbook forbids registry rotation without an explicit migration/import. Regression: `test_R7_RevertIf_RegistryOracleDesync`.

### P3-2 Oracle rotation re-arms the unbounded bootstrap and wedges `forwardAUM` for strategies with settled positions — NOTED (ops)
- A new oracle starts with cache 0 / `reportBootstrapped = false`; its first report's `hubAssets` is unbounded again and the aggregate anchor is `bridgedOut` only, so Active value above 1.5 × bridgedOut breaches — `forceAUMUpdate` (ORACLE_MANAGER + quorum + live PPS) is the seeding path. Documented as an oracle-rotation runbook item; a governor-only `importReport` is the code alternative if rotation is ever planned.

### P3-3 `SuperGovernor.getAddress` reverts on unset keys; `_impliedAssets` NatSpec claimed tolerance — FIXED (docs)
- Behaviour is fail-closed everywhere; the misleading comment was corrected.

### P3-4 `DebridgeAdapter.onEtherReceived` forwards `address(this).balance` rather than `msg.value` — NOTED
- Out of this PR's scope (shared adapter, not in the cap path); not a theft vector. Recommend `msg.value` in a separate change.

## What we checked and found sound (shareable with the reviewer)
1. **Reentrancy / call ordering** — every external call from registry/oracle/guard targets a governance-registered contract or is a STATICCALL (`getVaultInfo`, `totalAssets`, `quoteOFT`, `getOutAmount`); `_syncAndCommit` loops over a trusted registry with no untrusted callee in between; hooks' `validateAllocation → recordBridgedOut` run in `_preExecute` and revert atomically with the batch; adapters: `lzCompose` endpoint-only → self-call, `claimFailedTransfer` CEI + `nonReentrant`, pre-balance gate.
2. **EIP-712 report path** — OZ `EIP712` domain (chainId + verifyingContract); typehash binds strategy, id-hash, value-hash, hubAssets, timestamp, nonce; distinct `ForceUpdateAUM` typehash; `encodePacked` only over fixed-width arrays; nonce consumed on soft-fail and revert-safe; strictly ascending unique signers vs the live validator set; quorum floor > 0; OZ 5.x ECDSA; timestamp bounded future/stale/min-interval plus wall-clock `lastCommitAt`.
3. **Access control** — every state-changing function gated; zero registrar / unset oracle key fail closed; `setCapConfig` loosening detection compares each entry to stored state before any write; screener veto needs GUARDIAN_ROLE; leaf double-hashed.
4. **Integer / rounding** — `lowerBase − lowerBase·θ/1e18` cannot underflow (θ ≤ 0.5e18); `_relDiff` handles `b == 0`; `mulDiv` rescales match the parents byte-for-byte; 1-wei reservation cannot zero-confirm; `overlap ≤ inFlight` by construction; Across `uint32 fillDeadlineOffset` is relative, so comparing it to `RESERVATION_TIMEOUT` is correct.
5. **Griefing / DoS** — breaker fed only by aggregate/per-position bands (quorum-controlled inputs) after this round; consistency and hub bands excluded; permissionless `forwardAUM` cannot alter a signed report; 64-position cap and `openReservationCount` are self-DoS only; report validation ~7M gas at n = 64 (acceptable on L2).
6. **Rotation hazards** — guard rotation is leaf-pinned (fail-closed); registry rotation now trips the desync check; oracle rotation documented (P3-2); validator removal takes effect at next submission.
7. **Upgrade / observability** — no proxies; every lifecycle transition emits an event.
8. **Destination adapters** — `StargateAdapter` checks `msg.sender == LZ_ENDPOINT` and `TokenMessaging.assetIds(_from) != 0` (LZ V2 compose sender trust); `composeFrom` intentionally unauthenticated because the executor validates the account's destination signature and consumes `usedMerkleRoots`; both `catch {}` blocks discard revert data (returnbomb-safe); Across/deBridge adapters verify spoke-pool / external-call-adapter callers.
9. **Inline critical patterns** — pragma locked 0.8.30; no `tx.origin`, `delegatecall`, `selfdestruct`; no `catch (bytes memory)`; no division-before-multiplication; low-level `.call{value:}` targets are the payload `account` before the executor runs, with no state written around them.

## External precedent mapping (research agent; all mitigations verified in code unless marked)
| Pattern / precedent | Relevance | Status |
|---|---|---|
| Ostium 2026 signer-key compromise (future-dated reports, no plausibility bound) | AUM oracle | timestamp bounded above (`FUTURE_TIMESTAMP`) and below; bands/breaker governance-tunable only; quorum shares the PPS validator set (inherent to trust model) |
| LZ V2 permissionless `sendCompose`; Allbridge 2026 trusted-amount receiver | StargateAdapter | endpoint + pool allowlist enforced; amount taken from the verified pool credit |
| Same-address smart account not yet deployed on destination (Wintermute/OP) | destination account | operational: governance pins destinations only after off-chain codehash/owner check — runbook item |
| Across refund after expiry; deBridge no-deadline orders; Stargate rewards | reservation lifecycle | refund window is conservative (reservation + hub balance both counted until governance release); Stargate exactness enforced by quoteOFT + fee-lib pin |
| Nonce burned on soft-fail (permit-style griefing) | `forwardAUM` | a breaching report must itself be quorum-signed; anyone can pre-empt but not alter; accepted, documented |
| `maxStaleness` ceiling vs 2h operations (was 24h) | cap guard freshness | code ceiling lowered to 4h (`MAX_MAX_STALENESS`); the runbook sets `maxStaleness` close to the reporting cadence |
| EIP-712 cross-chain / cross-contract replay | reports, destination typed action | domain binds chainId + verifyingContract; destination signature binds account + chain |
| Executor privilege scope (Poly Network) | destination executor | typed action restricted to the pinned approve/deposit hook pair |
| Merkle veto asymmetry / timelock | root screener | accepted operational risk until the next aggregator release (documented) |
| ERC-7579 hook ordering | cap hooks | reservation mint and bridge send are one atomic batch; no try/catch around the send |

## Attack-tree pass — open / accepted residual leaves (ranked by feasibility × impact)

No new closable gap in the cap boundary. Every path to "exceed the cap", "understate remote capital" or "uncount by time" is blocked by a cited check; the leaves below are residuals of the stated trust model, each with its existing mitigation and a cheap hardening for a later change.

| # | Leaf | Existing mitigation | Suggested hardening (not applied) |
|---|---|---|---|
| 1 | Raw-leaf timelock race: `executeStrategyHooksRootUpdate` does not consult the screener; only `enforceProposalClearance` inside (grace, timelock] stops an uncleared root (accepted operational risk) | watchers + clear-before-propose | next aggregator release: activation requires screener clearance; until then a keeper calling `enforceProposalClearance` at `proposedAt + grace` for every screened strategy |
| 2 | Compromised manager skims up to the 10 % floor per bridge leg via own `exclusiveRelayer` / colluding taker (bounded manager theft, not a cap bypass; the 90 % floor was accepted in rounds 2–4 as fee/slippage room) | 90 % floor = confirm floor; monitoring | governance-configurable per-route floor (≥ 99 % for same-asset routes) or an `exclusiveRelayer` allowlist / `exclusiveRelayer == 0` for cap routes |
| 3 | Banned hook still a leaf of the GLOBAL root → protocol-wide permissionless veto | runbook order rule | `setBannedHook` requires a governor attestation that the hook is not a global leaf; monitor bans vs the published global leaf set |
| 4 | Quorum-key laddering of hub/AUM (θ per commit, paced by `minUpdateInterval` + wall clock; PPS band binds only when live and signed by the same set) | K2 force hard-block, pacing, 4h staleness | production `minUpdateInterval ≥ 15 min`; guard denominator `min(reported total, implied assets)` when PPS is fresh |
| 5 | Between-report staleness after large redemptions (denominator stale for ≤ `maxStaleness`) | `MAX_MAX_STALENESS` now 4h | same `min(reported, implied)` denominator in `validateAllocation` |
| 6 | Default-deny veto is strategy-wide: an uncleared proposal lets anyone halt all hooks (incl. exits) after grace | grace period | per-(strategy, root) clearance in the next aggregator release; "clear then propose" runbook |
| 7 | Stargate delivery whose destination action silently skips (reused root / short balance) leaves funds idle on the hub-controlled account; a vault-kind reservation cannot be registered as Idle, so it is either counted forever or governance-released with the idle balance off-book | Stargate exact-delivery lock; governance evidence rule before any release | governor `reconcileIdleDelivery(reservationId)` converting a Consumed/Open vault reservation into an Idle position the oracle can value |
| 8 | Whale consistency-band griefing (move ≥ tolerance of AUM between signing and submission every report → reports stale → sends revert; exits unaffected) | fail-safe, band excluded from breaker | widen tolerance proportionally to supply change since the report timestamp, or an ORACLE_MANAGER supply-snapshot attestation |
| 9 | deBridge order uncancellable if the same-address account is never deployed on the take chain (give amount locked) | initData / CREATE2 determinism | runbook: verify the account codehash on the destination before `setApprovedDestination` |

## Recommended invariant suite (Echidna/Medusa/Foundry) — follow-up
1. `invariant_ExposureCoversCommittedTotal` — `getEffectiveCrossChainExposure(s) >= latestReport(s).totalCrossChainAssets` after every commit.
2. `invariant_BridgedOutEqualsCountedReservations` — `bridgedOut[s] == Σ amount over Open/Consumed reservations`, and per chain.
3. `invariant_PendingExcessEqualsSumMax0` — `pendingObservedExcess[s] == Σ max(0, lastReportedValue − deployedAmount)` over Pending positions.
4. `invariant_ExposureNeverDropsWithoutGovernance` — excluding governance resolution calls, exposure decreases only through committed reports bounded by the bands.
5. `invariant_CommitRateBounded` — consecutive commits are ≥ `minUpdateInterval` apart and `hubAssets + total ≤ (1+θ)·(prevTotal + inFlight − overlap)` unless first report.
6. `invariant_CapHoldsAtSend` — after every `recordBridgedOut` via the guard, `exposure·10_000 ≤ maxCrossChainBps·getTotalAUM` and `chainExposure ≤ perChainCap` on the same snapshot.
7. `invariant_SlotBound` — `positions.length + openReservationCount ≤ 64`; every `ReservationConsumed(recounted = true)` follows exactly one `ReservationReleased`.
8. `invariant_TerminalIsSilent` — Exited/Invalidated positions contribute 0 to AUM, exposure and `_candidateTotal`, and never re-enter the live set.

## Coding-standards / documentation findings (applied in this working tree)
- Stale statements corrected: `res.hook` comment, Stargate zero-amount rationale (ratio check no longer exists), `stargateMinDeliveryBps` described as an enable switch (guard + interface), common-path and Across comments no longer mention registrar release, spec lines claiming co-approved registrar appointment / cap-loosening timelock / "non-expired" completeness, `_impliedAssets` tolerance claim, "front-run" wording.
- Across `inspect` magic numbers replaced by `OUTPUT_TOKEN_OFFSET` / new `EXCLUSIVE_RELAYER_OFFSET`.
- Oracle interface gained `reportBootstrapped` and `domainSeparator` declarations.
- Deferred (nits): per-chain event in `setCapConfig`, calldata printers for `setStrategyDestinationAsset` / `setStargateFeeLib`, `@notice` on remaining interface getters/errors, `POSITION_NOT_OBSERVED` error naming, `getAddress` duplication in the Stargate hook, `GovernorGated` base extraction.

## Security knowledge sources
- vulnerabilities.md sections: 1 (reentrancy), 2 (access control), 3 (arithmetic), 4 (oracle), 7 (DoS), 8 (unchecked calls), 9 (encodePacked), 11/35 (governance/upgrade), 15 (code quality), 16/33 (cross-chain/bridge), 20 (Merkle), 36 (pre-PR checklist), 41.1, 50 (LZ V2 compose), 51 (returnbomb), App. H.
- evmresearch.io: circuit-breaker independence, oracle dispute windows, CREATE2 same-address, ERC-4337/7579 module risks, cross-chain replay, Merkle double-hashing, governance-timelock emergency windows.
- Exploits cross-referenced: Ostium (2026), Allbridge (2026), Router (2025), Orbit Chain, Wintermute/OP, Poly Network, BonqDAO, Merkl C4.
- Coding rules validated: pinned pragma, custom errors, event coverage, NatSpec/@inheritdoc, CEI, bounded loops, import organization.
