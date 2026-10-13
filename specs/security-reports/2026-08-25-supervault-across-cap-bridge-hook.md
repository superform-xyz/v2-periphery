# Security Analysis Report — SuperVaultAcrossCapBridgeHook + CrossChain cap system

## Metadata
- **Target:** `v2-core/src/hooks/bridges/across/SuperVaultAcrossCapBridgeHook.sol` (new) and its periphery trust boundary: `CrossChainPositionCapGuard.sol`, `CrossChainPositionRegistry.sol`, `CrossChainAUMOracle.sol`
- **Mode:** review (3 parallel agents: vulnerability scanner, best-practices, EVM security research)
- **Date:** 2026-08-25
- **Contract Types:** cross-chain bridge hook + oracle-fed risk-cap accounting
- **Vulnerability DB:** vulnerabilities.md (36 sections) + manual Sections 50/51

## Summary
| Severity | Count | Blocks Merge |
|----------|-------|--------------|
| P0 Critical | 0 | Yes |
| P1 High | 3 | Yes |
| P2 Medium | 3 | No |
| P3 Low | 4 (+ best-practices set) | No |

## Remediation status (2026-08-25)
Fixes applied to `SuperVaultAcrossCapBridgeHook.sol` (the review target) + new test `test/unit/hooks/bridges/SuperVaultAcrossCapBridgeHook.t.sol` (8 passing):
- **P1-1 FIXED** — hook now resolves cap guard + registry from `SUPER_GOVERNOR.getAddress(...)` at execution (same keys the periphery uses); constructor takes `superGovernor_` instead of the two immutables. Migration test proves exposure follows the governor pointer.
- **P2-2 FIXED** — full-width `destinationChainId` validated; `> type(uint64).max` reverts `DATA_NOT_VALID`.
- **P3-1 FIXED (test half)** — offset-equivalence test asserts the hook validates exactly the tuple the parent bridges (both amount branches). Constants left local because the parent is locked bytecode (can't share its private constants without re-locking it).
- **P3-2 FIXED** — explicit `data.length < 269` typed-error guard in `_preExecute`.
- **P3-3 / P3-4 FIXED (documented)** — idle-hold unreachability and Across refund/depositor behavior now in NatSpec.
- **P1-3 documented, NOT code-fixable here** — machine-enforcement belongs at the executor/validator layer, not this hook; NatSpec states it as a monitored governance invariant.

Already fixed on disk by a prior periphery hardening pass (verified, no action): best-practices event + interface for `setBridgeHookAuthorization`; `2 hours` duplication (now reads `POSITION_CONFIRMATION_TIMEOUT()`); P2-1 misleading NatSpec (now honestly documents the consistency band is inert until `_impliedAssets` is wired); P1-2 partially mitigated by new `invalidateExpiredPending` + clamped `_releaseBridgedOut`.

Still open (need periphery-author design decisions, not touched): **P1-2** residual (link each `recordBridgedOut` to a position id so a missing/lagging registration cannot strand or under-count exposure) and **P2-1** (wire `_impliedAssets` to a PPS source to activate the consistency-band backstop before mainnet).

## Verdict
**FAIL** — 3 blocking (P1) findings. None is a classic "drain in one tx" bug; all three are ways the cap silently stops binding (bypass) or permanently over-counts (DoS). The mechanical core of the hook is correct: offsets, amount resolution, rollback atomicity, and access control all verified clean.

---

## Verified-correct (so the report is not misread as "the hook is broken")
- **Offsets match the parent exactly.** RECIPIENT=84, INPUT_AMOUNT=144, DST_CHAIN_ID=208, USE_PREV_HOOK_AMOUNT=268 all line up with `ApproveAndAcrossSendFundsAndExecuteOnDstHook`'s documented layout and the `depositV3Now` call it builds. The validated (amount, chain, recipient) equals the bridged tuple. No off-by-N.
- **Rollback atomicity holds.** `_preExecute` reserves before the approve/bridge executions; batch runs in revert-on-failure mode, so a failing send unwinds `recordBridgedOut` with the tx. The "stuck reservation on partial revert" concern does not apply on the standard path.
- **No reentrancy / returnbomb surface added.** `validateAllocation` is view, `recordBridgedOut` is a plain SSTORE, `_processHook` is `nonReentrant`, and the guard/registry are trusted immutables (Sections 50/51 clear).
- **Self-scoping accounting.** `recordBridgedOut(strategy = account)` where `account == msg.sender` (BaseHook), so an account cannot spoof another strategy's exposure.

---

## P1 Findings (High — must fix)

### P1-1: Hook writes exposure to an immutable registry; the cap reads it from the SuperGovernor-resolved registry → silent bypass on migration
- **File:** `SuperVaultAcrossCapBridgeHook.sol:62,102` vs `CrossChainPositionCapGuard.sol:80-81`
- **Category:** Cross-Chain / Config divergence
- **Description:** The hook records `bridgedOut` into its **constructor-injected immutable** `POSITION_REGISTRY`. The cap guard reads exposure from `SUPER_GOVERNOR.getAddress(CROSS_CHAIN_POSITION_REGISTRY)` — resolved dynamically at call time (verified at guard line 81). Nothing on-chain asserts the two are the same contract. A governor registry rotation (routine upgrade) leaves the immutable hook writing to the old registry while the cap reads the new (empty) one; the in-flight term becomes 0 and both global and per-chain caps under-count.
- **Exploit Scenario:** Governance rotates `CROSS_CHAIN_POSITION_REGISTRY`. The deployed hook keeps crediting the old registry. `validateAllocation` reads `bridgedOut = 0` from the new registry and approves cross-chain allocations that blow through `maxCrossChainBps` / `perChainCap` while funds are in flight.
- **Fix:** Resolve the registry (and cap guard) via `SUPER_GOVERNOR.getAddress(...)` at call time — the hook already uses minimal local interfaces, so add a minimal `ISuperGovernor.getAddress` view and keep the no-periphery-dependency property. If the immutable is retained for gas, assert `POSITION_REGISTRY == SUPER_GOVERNOR.getAddress(CROSS_CHAIN_POSITION_REGISTRY)` in `_preExecute` and revert on mismatch. Same reasoning applies to the immutable `CAP_GUARD`.
- **Reference:** vulnerabilities.md §16, §2.

### P1-2: In-flight `bridgedOut` reservation has no guaranteed release path (two-writer accounting desync)
- **File:** `CrossChainPositionRegistry.sol:216-221` (record) vs `187-203,306-312` (release)
- **Category:** Logic / Accounting
- **Description:** `recordBridgedOut` credits `(strategy, chainId, amount)` with **no position id**. The only decrement path is `_releaseBridgedOut`, reached only from `syncPositionFromReport`, keyed on a *separately* registered position's `deployedAmount`. The hook write and the registrar's `registerPosition` are independent, unlinked events with independently supplied amounts. Both agents independently flagged this. Failure modes: (a) **over-count / cap DoS** — if no matching position is ever registered, or `deployedAmount < recorded amount`, the clamp at 306-311 strands the remainder forever; `getEffectiveCrossChainExposure` stays inflated and every future allocation reverts, with no admin drain. (b) **under-count / bypass** — a Pending position past the 2h `POSITION_CONFIRMATION_TIMEOUT` is invalidated and its reservation released even if the Across fill lands afterward; the cap then sees 0 in-flight and approves a second allocation on top of capital already deployed abroad.
- **Exploit Scenario (bypass):** A relayer fills an Across deposit >2h after `registerPosition`. The oracle report invalidates the Pending position and releases `bridgedOut`; the guard sees zero in-flight and approves another large allocation — total cross-chain exposure exceeds `maxCrossChainBps`.
- **Fix:** Bind each reservation to a registry-created record atomically (hook creates the Pending position, or `recordBridgedOut` returns an id the registrar must consume), reconcile timeout-invalidation against confirmed fills rather than a bare 2h clock, and add a governor-gated sweep for stranded reservations. Invariant test: `bridgedOut` returns to 0 for any bridge that either confirms or is refunded.
- **Reference:** vulnerabilities.md §16.3, §33.6, §14; OWASP SC02:2026.

### P1-3: Cap binding is an off-chain governance invariant, not machine-enforced
- **File:** `SuperVaultAcrossCapBridgeHook.sol:30-38` (NatSpec claim); enforcement absent at executor/validator layer
- **Category:** Business Logic / Access Control
- **Description:** The hook's own NatSpec states the cap is binding *only if* raw Across hooks are not registered on chains hosting a cap-enabled strategy. That is a deployment/governance assumption with no on-chain backstop. Any other fund-exiting leaf reachable by the strategy account — a raw Across hook, another bridge adapter, a transfer-then-bridge composition, a future hook — moves value cross-chain with zero cap check and zero `recordBridgedOut`. `setBridgeHookAuthorization` controls who may *write* exposure but does not force every outbound-value path through a writer. Direct structural parallel to the Abracadabra Oct 2025 batch-bypass (~$1.7M) and Router Protocol Jul 2025.
- **Fix:** Make the invariant machine-checked: deny-by-default on outbound-value hooks for cap-enabled strategies at the executor/validator layer, or gate SpokePool spend for these strategies behind the cap guard. At minimum, treat "only capped bridge hooks registered on host chains" as a monitored release-gate invariant (diff registry `bridgedOut` + reported AUM against actual token outflows) and document/test the full hook set per cap-enabled chain.
- **Reference:** vulnerabilities.md §2; SECURITY.md "multiple valid execution paths"; OWASP SC01/SC02:2026.

---

## P2 Findings (Medium — should fix)

### P2-1: `forceAUMUpdate` consistency-band backstop is currently a no-op
- **File:** `CrossChainAUMOracle.sol:184-190,383-399`
- **Description:** `forceAUMUpdate` skips deviation checks and relies on "the SEC-8 consistency band (the backstop)." But `_impliedAssets` is a stub returning `0`, so `_consistencyBreach` is unconditionally false — the advertised backstop is disabled. A quorum-signed forced report with inflated `hubAssets` raises the cap denominator (`totalAUM * maxCrossChainBps`) and clears the breaker, unlocking over-allocation. Trust model is honest-quorum, but the NatSpec materially overstates the on-chain protection.
- **Fix:** Wire `_impliedAssets` (PPS × totalSupply) before enabling force updates in production, or bound the forced total; correct the NatSpec to say the band is inert until wired.
- **Reference:** vulnerabilities.md §39.3, §4; OWASP SC03:2026.

### P2-2: `destinationChainId` truncated to `uint64` for the cap check while the bridge uses full `uint256`
- **File:** `SuperVaultAcrossCapBridgeHook.sol:93` vs parent `_buildBridgeExecution` (offset 208, full uint256)
- **Description:** `uint64(BytesLib.toUint256(data, 208))` truncates; the parent forwards the full `uint256` to `depositV3Now`. A value `k·2^64 + approvedChain` passes the cap check (low 64 bits = approved chain) while the bridge is instructed with the full-width value, and exposure is keyed under the truncated chain. Practical fund-loss is limited (Across rejects nonexistent chains), but it is a validated-value ≠ used-value divergence and a latent bypass on any modulo-2^64 collision.
- **Fix:** `require(BytesLib.toUint256(data, DST_CHAIN_ID_OFFSET) <= type(uint64).max)` (or decode at identical width in both places). Add a differential test asserting the validated chainId equals the value handed to the SpokePool.
- **Reference:** OWASP SC05/SC07:2026.

### P2-3: `destinationChainId` and amount are not in the signed `inspect()` leaf
- **File:** `SuperVaultAcrossCapBridgeHook.sol:105-109` and parent `inspect()` (`:230-237`)
- **Description:** The inherited leaf binds recipient/inputToken/outputToken/exclusiveRelayer but **not** chainId, amount, or usePrevHookAmount. On the ERC-4337 path this is safe — the full hookData is bound via `userOpHash` in `SuperValidator._createLeaf`, so a solver cannot mutate them. The residual risk is entirely that assumption plus the guard's `approvedDestinationVault[chainId][vault]` keying: since a vault *can* be approved on multiple chains (verified — keyed by (chain, vault)), any submission path that derived the leaf from `inspect()` output alone would let a submitter steer a signed intent to whichever approved chain has cap headroom. Idle-hold (`recipient == address(0)`) widens this since the recipient carries no vault identity.
- **Fix:** Confirm and test that every execution path binds the leaf to full hookData via `userOpHash`; if any path uses `inspect()`-only leaves, include `destinationChainId` (and amount fields) in the leaf, or forbid approving one recipient across multiple chains and assert it in `setApprovedDestination`.
- **Reference:** vulnerabilities.md §16.1, §33.4, §39.2.

---

## P3 Findings (Low)
- **P3-1 — Offsets duplicated from parent private constants with zero test coverage** (`SuperVaultAcrossCapBridgeHook.sol:49-52`). The hook re-declares `144`/`268` that shadow the parent's `AMOUNT_POSITION`/`USE_PREV_HOOK_AMOUNT_POSITION`, and **no test anywhere** asserts the decoded (recipient, chainId, amount) equals what the parent bridges. The cap's correctness rests on four unchecked literals. Fix: promote the parent constants to `internal`, reuse them, and add the offset-equivalence unit test (both `usePrevHookAmount` branches). *This is the single highest-value fix — it converts P1-2/P2-2 latent-drift risk into a compile+test guarantee.*
- **P3-2 — `_preExecute` decodes at fixed offsets without a length check** (`:90-99`); relies on BytesLib's untyped OOB revert instead of the parent's `DATA_NOT_VALID()`. Add `if (data.length < 269) revert DATA_NOT_VALID();`.
- **P3-3 — Idle-hold destination path unreachable via this hook** — guard treats `destinationVault == address(0)` as idle-hold, but the parent bridge builder reverts on `recipient == address(0)`. Dead policy surface; document or route idle-hold distinctly.
- **P3-4 — Across refund-to-depositor path doesn't notify the registry** — unfilled `depositV3` refunds the strategy on origin chain but leaves the reservation until (if) a Pending position times out; ties into P1-2. Verify the `depositor` handed to the SpokePool is the strategy account.

## Best-practices (from agent 2; non-blocking)
- **P2:** `setBridgeHookAuthorization` mutates the SEC-1 control surface with **no event**; `setBridgeHookAuthorization`/`authorizedBridgeHook` **missing from `ICrossChainPositionRegistry`**; `CrossChainAUMOracle._positionRequired` hardcodes `2 hours` duplicating the registry constant; interface functions (`forwardAUM`/`forceAUMUpdate`) lack NatSpec at the API boundary.
- **P3:** dead errors (`INVALID_MAINNET_CHAIN`, `POSITION_NOT_FOUND`), `forge fmt` line-length violations in the oracle, inconsistent auth idioms (modifier vs inline vs helper across the three contracts), magic `10_000`/`1e18`, `registerPosition` accepts `deployedAmount == 0`, inline interface declarations in the hook file (move to a shared vendor file).

---

## Attack Surface Summary
- **External entry points:** `preExecute`/`postExecute` (account-gated), `recordBridgedOut` (hook-allowlist-gated), `validateAllocation` (view), `forwardAUM`/`forceAUMUpdate` (quorum-gated), governance setters.
- **Value transfer:** Across `depositV3Now` via SpokePool (parent hook).
- **Oracle dependencies:** `CrossChainAUMOracle` quorum-signed reports feed the cap denominator; fail-closed on staleness/breaker.
- **Config surfaces:** SuperGovernor registry resolution (P1-1), bridge-hook allowlist (P1-3), destination/chain approval, cap knobs.

## Recommended invariant tests
- `invariant_bridgedOutReturnsToZero`: any bridge that confirms or refunds drives `bridgedOut` back to 0.
- `invariant_validatedTupleEqualsBridged`: decoded (recipient, chainId, amount) == the `depositV3Now` args, both `usePrevHookAmount` branches.
- `invariant_registryAddressesAgree`: `hook.POSITION_REGISTRY == SuperGovernor.getAddress(CROSS_CHAIN_POSITION_REGISTRY)`.
- `invariant_capBindsAcrossAllOutboundHooks`: no authorized outbound-value hook for a cap-enabled strategy skips `recordBridgedOut`.

## Sources
vulnerabilities.md §2,§4,§14,§16,§33,§39,§50,§51; OWASP SC Top 10 2026 (SC01/02/03/05/07); Abracadabra Oct 2025, Router Protocol Jul 2025, OpenZeppelin Across V3 audit, Across depositV3 refund semantics.
