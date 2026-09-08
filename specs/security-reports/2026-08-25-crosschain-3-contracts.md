# Security Analysis Report — Cross-Chain SuperVaults (3 contracts)

## Metadata
- **Target:** `src/CrossChain/CrossChainAUMOracle.sol`, `CrossChainPositionRegistry.sol`, `CrossChainPositionCapGuard.sol` (+ interfaces)
- **Mode:** review (inline scan + 3 parallel agents: vuln scanner, best-practices, EVM research)
- **Date:** 2026-08-25
- **Contract types:** M-of-N EIP-712 quorum oracle, cross-chain position registry, cap policy guard
- **DB:** superform-specs/guidelines/solidity/vulnerabilities.md (36 sections) + coding-rules.md
- **Context:** design review already resolved SEC-1..17 (specs/cross-chain-supervaults/technical-spec.md); these are NEW code-level findings.

## Summary
| Severity | Count | Blocks merge |
|----------|-------|--------------|
| P0 Critical | 0 | Yes |
| P1 High | 0 | Yes |
| P2 Medium | 5 | No |
| P3 Low | ~14 | No |

## Remediation status (2026-08-25)
All 5 P2 + the agreed quick P3s FIXED and tested (62 CrossChain tests green, `forge fmt` clean):
- **P2-1** `invalidateExpiredPending(strategy, positionId)` added (permissionless; releases in-flight + evicts).
- **P2-2** `_releaseBridgedOut` now clamps global + per-chain by a SINGLE value (bounded by per-chain outstanding) — no divergence, no cross-chain leak.
- **P2-3** `strategy` field added to `CrossChainPosition`; `syncPositionFromReport` skips (no-op) any id whose `strategy` mismatches.
- **P2-4** `hubAssets` now gets an aggregate deviation bound in `forwardAUM` (bootstrap exempt).
- **P2-5** `BridgeHookAuthorizationUpdated` event added + emitted; function/getter/event declared in the interface.
- **P3-2** local quorum floor (`quorum == 0` reverts `QUORUM_NOT_MET`); **P3-8** fail-fast `maxStaleness==0` moved before the ecrecover loop; **P3-6** oracle reads `POSITION_CONFIRMATION_TIMEOUT()` from the registry (no literal); **P3-13** `forge fmt` applied.
- New tests: registry `invalidateExpiredPending` (3) + foreign-strategy skip (1); oracle quorum-zero (1) + hubAssets deviation (1).
- Deferred (not in this pass): remaining P3s (per-chain cap event, constructor NatSpec, magic-constant naming, storage packing, zero-address guards on config setters, `domainSeparator` in interface, `_releaseBridgedOut` var rename) and the root SEC-8 `_impliedAssets` PPS wiring (P2-4/P3-1 now bounded by the hubAssets deviation check as an interim).

## Verdict
**PASS** — no P0/P1. There is no untrusted write path into the cap denominator or AUM: every input is quorum-signed (validators) or role-gated (registrar / governor / authorized hook). Confirmed-clean classes: EIP-712 signature/replay/malleability, reentrancy/call-ordering, arithmetic (multiply-before-divide, WAD/BPS scaling), fail-safe `getAddress`, bounded loops, lifecycle state machine (no resurrection/double-count), cap loosen/tighten gate, circuit-breaker (not grief-stuck). The residual risk is the **inherent push-oracle trust model** (off-chain validator quorum asserts cross-chain value) plus lifecycle/defense-in-depth gaps below.

---

## P2 Findings (Medium — should fix before merge)

### P2-1 — Expired `Pending` positions have no cleanup path (bridgedOut leak + slot exhaustion)
- **File:** `CrossChainPositionRegistry.sol` (sync `~176`), `CrossChainAUMOracle.sol:_positionRequired`
- **Category:** DoS / state machine (vuln.md §7.1, §14.4)
- A `Pending` position only leaves `Pending` inside `syncPositionFromReport`, which releases its `bridgedOut` reservation and evicts it. But the oracle's completeness rule stops *requiring* an expired `Pending` position after `POSITION_CONFIRMATION_TIMEOUT` (2h), and there is no registrar/permissionless `invalidateExpiredPending`. A bridge that never confirms leaves the position stuck forever → its `deployedAmount` is permanently reserved in `bridgedOut[strategy]` (permanently shrinking cap headroom), and it permanently occupies one of the 64 `MAX_POSITIONS_PER_STRATEGY` slots (repeat → `MAX_POSITIONS_REACHED`).
- **Fix:** add a permissionless (or registrar) `invalidateExpiredPending(strategy, positionId)` that, for a `Pending` position past the timeout, releases `bridgedOut` and evicts — independent of oracle inclusion.

### P2-2 — In-flight `bridgedOut` decoupled from bridge-recorded amount; independent clamps under-count exposure
- **File:** `CrossChainPositionRegistry.sol` `recordBridgedOut`, `_releaseBridgedOut`, `registerPosition`
- **Category:** accounting integrity (vuln.md §14.3)
- `bridgedOut` is incremented by the hook with an arbitrary `amount` keyed only by `(strategy, chainId)` — no positionId linkage. Release uses the *registrar-supplied* `pos.deployedAmount`, never checked to equal the hook-recorded amount, and clamps the global and per-chain counters **independently**. If a position is registered with a `deployedAmount` larger than its own in-flight amount, its release consumes *another* position's still-in-flight reservation, under-counting real exposure and letting `validateAllocation` permit allocation beyond the SEC-3 cap; global vs per-chain can also diverge.
- **Fix:** record in-flight per positionId (or make `registerPosition` the sole recorder), release exactly the stored amount, derive per-chain decrement from the same value.

### P2-3 — `syncPositionFromReport` never verifies the position belongs to `strategy`
- **File:** `CrossChainPositionRegistry.sol` sync; `ICrossChainPositionRegistry` struct (no strategy field)
- **Category:** missing validation / trusted-caller-untrusted-params (vuln.md §14.3, §2)
- `syncPositionFromReport(strategy, positionId, ...)` reads `_positions[positionId]` with no check that it was registered under `strategy` (the struct stores no `strategy`), and the oracle's completeness loop only iterates `_strategyPositions[strategy]` — it doesn't reject *extra* foreign ids in the report. A buggy/malicious quorum report for S that includes a positionId owned by S′ would corrupt S′'s value and release `bridgedOut[S]` using the foreign position's data. Defense-in-depth (requires signer compromise), but the salted-id scheme almost-but-not-quite prevents it.
- **Fix:** store `strategy` in `CrossChainPosition`; require `_positions[positionId].strategy == strategy` in sync; have the oracle reject report ids not in `_strategyPositions[strategy]`.

### P2-4 — `hubAssets` enters the cap denominator with no deviation bound (SEC-8 band disabled)
- **File:** `CrossChainAUMOracle.sol` `getTotalAUM`, `_consistencyBreach`, `_impliedAssets`
- **Category:** oracle / missing validation (vuln.md §4.2, §14.3)
- All deviation logic bounds only the cross-chain `total`. The signed `hubAssets` is written verbatim and added into `getTotalAUM` — the cap denominator. The one check that would sanity-bound it (SEC-8 consistency band on `hubAssets + total`) is a no-op because `_impliedAssets` returns 0. A single inflated `hubAssets` in an otherwise-valid report enlarges cap headroom with nothing catching it.
- **Fix:** apply an aggregate deviation bound to `hubAssets` (mirroring `total`), or block acceptance until `_impliedAssets` (SEC-8) is wired.

### P2-5 — `setBridgeHookAuthorization` emits no event
- **File:** `CrossChainPositionRegistry.sol` `setBridgeHookAuthorization`
- **Category:** observability of a security-relevant permission (coding-rules; vuln.md §36)
- This governor-only setter mutates the `authorizedBridgeHook` allowlist (who may write `bridgedOut`) but emits nothing, unlike every other setter. Monitoring can't track hook-authorization changes. Add `BridgeHookAuthorizationUpdated(hook, authorized)` (and declare the function/getter/event in the interface).

---

## P3 Findings (Low — consider)

- **P3-1** `forceAUMUpdate`'s advertised SEC-8 backstop is vacuous while `_impliedAssets` returns 0 — force can commit arbitrary `total`/`hubAssets` (subject only to completeness). Same root as P2-4; wire `_impliedAssets` or gate `forceAUMUpdate` behind an explicit bound/timelock.
- **P3-2** No local quorum floor: if `getPPSOracleQuorum()` ever returns 0, one signature passes. Add `require(quorum > 0)` locally.
- **P3-3** `setCapConfig` emits only the global cap; per-chain `perChainCap`/`chainEnabled` writes produce no event. Emit a per-chain event in the loop.
- **P3-4** `_impliedAssets` uses `strategy;` no-op to silence unused-param — drop the name instead (SWC-135).
- **P3-5** Constructors lack NatSpec (all three) — mirror `ECDSAPPSOracle`, esp. the EIP-712 domain immutability note.
- **P3-6** `2 hours` hardcoded in the oracle duplicates `POSITION_CONFIRMATION_TIMEOUT` — read from the registry / shared constant to avoid silent divergence.
- **P3-7** Magic `10_000` (BPS) and `1e18` (WAD) literals in the oracle — name them (cap guard already has `BPS_PRECISION`).
- **P3-8** `_verifyAndConsume` runs the full `_checkSigners` ecrecover loop before the cheap `maxStaleness == 0` revert — move the fail-fast check first.
- **P3-9** Cap guard loops re-read `chainIds.length` each iteration — cache `len` (as the other two contracts do).
- **P3-10** Storage-packing opportunity on bounded struct fields (`AUMOracleConfig` timestamps/bps/thresholds; position timestamps as uint64) — ABI-affecting, optional.
- **P3-11** Missing `strategy != address(0)` guard in `setAUMOracleConfig` / `setCapConfig` / `setApprovedDestination` (registry's `setRegistrar` does check).
- **P3-12** `domainSeparator()` not declared in `ICrossChainAUMOracle` (IECDSAPPSOracle declares it).
- **P3-13** Three lines exceed the `forge fmt` 120-col width → `forge fmt --check` fails CI; run `forge fmt`.
- **P3-14** `_releaseBridgedOut` locals `gAmt`/`cAmt` are cryptic — rename `globalRelease`/`chainRelease`.

---

## Threat-model context (external research → mapped to our mitigations)

The push-oracle class carries inherent risks (recent precedents: Allbridge, KelpDAO, Ronin, Force Bridge, MakerDAO stale-price). Mapping to this code:
- **Reported-value vs real-balance gap / cap-denominator gaming** → partially on us: the AUM the cap trusts is asserted off-chain. On-chain we have quorum + deviation on `total`, but **not on `hubAssets`** (P2-4). Operationally: anchor/reconcile reported value against net deposits; consider a trailing-min / lagged AUM as the cap denominator; timelock large AUM jumps.
- **Validator key compromise / quorum takeover** → inherent; mitigated by M-of-N + circuit breaker (caps single-report blast radius). Operational: key diversity, on-chain rotation, multisig registrar, human-readable EIP-712 payloads.
- **Signature/cross-chain replay & signer uniqueness** → CODE CLEAN: full EIP-712 domain (chainId+verifyingContract), per-strategy nonce, distinct UPDATE/FORCE typehashes, ascending-unique validators, OZ ECDSA (malleability-safe).
- **Aggregation logic (mean vs median)** → AUM is a SUM of independently-signed per-position values (correct); not a mean-of-quotes, so median-aggregation doesn't apply. Per-position deviation bound is present.
- **Async double-counting** → addressed by the `bridgedOut` in-flight model, but see P2-1/P2-2 for its gaps.

---

## Attack surface
- **External entry points:** `forwardAUM`, `forceAUMUpdate` (permissionless, quorum-gated); `registerPosition`/`beginPositionExit`/`deregisterPosition` (registrar); `syncPositionFromReport` (oracle-only); `recordBridgedOut` (authorized hook); `setAUMOracleConfig`/`setRegistrar`/`setBridgeHookAuthorization`/`setCapConfig`/`setApprovedDestination` (role-gated); `validateAllocation`/`isAUMFresh`/`getTotalAUM`/views (view).
- **Value transfer:** none directly (no token transfers in these contracts).
- **Oracle dependencies:** self (this AUM oracle) + SuperGovernor validator set/quorum + (future) `_impliedAssets` PPS source.
- **Cross-contract:** SuperGovernor (`getAddress`, `hasRole`, `isValidator`, `getPPSOracleQuorum`), SuperVaultAggregator (`isMainManager`), registry↔oracle↔capguard.
- **Upgrade/admin:** none upgradeable; governance via SuperGovernor roles.
