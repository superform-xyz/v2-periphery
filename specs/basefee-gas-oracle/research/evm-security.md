# EVM Security Research — BasefeeGasOracle

Source: EVM security research agent, 2026-08-18. Vulnerability DB: `superform-specs/guidelines/solidity/vulnerabilities.md` (sections cited by number).

> **Spec-author reconciliation note (important):** finding 1.3's failure mode 3 ("revert → free
> upkeep forever") and its recommendation (b) ("drop-on-stale inside SuperOracle") are already
> satisfied by verified SuperOracle behavior: `_getQuoteFromOracle` with `revertOnError=false`
> returns 0 for a stale feed and `_getAverageQuote` skips it (`SuperOracleBase.sol:365-368,
> 467-470`). With the additive SUPERFORM registration, a frozen Chainlink feed blends into the
> average for at most `feedMaxStaleness` = 86400s, then is dropped and BasefeeGasOracle carries
> the pair alone. The residual exposure is the ≤24h frozen-answer blend window (modes 1/2 below).

## 1. Relevant Vulnerability Patterns

### 1.1 Unit/decimal confusion (1e9 wei/gwei class) — highest-probability bug class
DB: §3.2 (division before multiplication), §26.4.2 (decimals), Appendix "Flawed Oracles" (45.8% of oracle findings, 59.3% of losses).

- The Chainlink Fast Gas/Gwei feed reports **wei with `decimals() = 0`** despite the "Gwei" name. BasefeeGasOracle matching wei/0-decimals is correct — but the name-vs-unit trap is exactly how 1e9 bugs enter. Any consumer/test that reads "Gwei" in a name and scales by 1e9 produces a 1e9 error.
- **Averaging amplifies unit mismatch**: a gwei-denominated input blended with a wei-denominated one yields ~half the true value — passes eyeball tests. Assert unit parity in a fork test (both answers within a sanity band at the same block).
- Ordering: `basefee * multiplierBps / 10_000` (multiply-then-divide) is correct; divide-first zeroes out for basefee < 10_000 wei (§3.2). Mainnet basefee floor is ~7 wei; sub-gwei basefees are the norm now.

### 1.2 `updatedAt = block.timestamp` — always-fresh timestamp
DB: §4.2, §48.6. **Verdict: acceptable** — the answer derives from `block.basefee`, intrinsically fresh each block; no update tx exists whose absence could mean staleness (same pattern as wstETH-style rate adapters). Caveats:
- The thing that *can* go stale is the knob pair — a tip set in a 5-gwei era never revisited in a 0.05-gwei era. Mitigate: emit events on every set; optionally expose `paramsLastUpdatedAt` for off-chain monitoring.
- Round semantics: strict consumers require `roundId > 0` and `answeredInRound >= roundId`. Recommended: `roundId = answeredInRound = uint80(block.number)`, `startedAt = updatedAt = block.timestamp`.

### 1.3 Averaging a live feed with a deprecated feed — the cutover is the main risk window
DB: §18.1.4, §48.11, G.3. Deprecated Chainlink feeds **freeze** (keep returning the last round with aging `updatedAt`) rather than revert. Failure modes:
1. **Frozen-high**: feed freezes during a gas spike while real basefee falls → inflated average → overcharge → drains upkeep balances → `InsufficientUpkeep` auto-pause + ppsStale. *(Bounded to ≤24h by SuperOracle staleness drop — see reconciliation note.)*
2. **Frozen-low**: freezes at sub-gwei value during a later spike → silent undercharge/revenue leak. *(Same ≤24h bound.)*
3. **Revert → free upkeep forever**: only if ALL feeds for the pair are stale/dead. *(Prevented by the additive registration: BasefeeGasOracle can never go stale.)*
- Residual mitigations: off-chain alert on the Fast Gas feed's `updatedAt` and on divergence between the two feeds; optional follow-up governance action to remove/replace the CHAINLINK slot once frozen.

### 1.4 int256 cast
DB: §3.1, §29. Overflow unreachable (bounded formula << 2^255). Use OZ `SafeCast.toInt256()` for explicitness. Answer can structurally never be ≤ 0 on mainnet (floor `7 wei * 5000 / 10_000 = 3 wei`); encode as invariant test, don't assume.

### 1.5 Access control on setters
DB: §2.1, §4.3 (oracle update access — Critical), §14.3, §35.
- Enforce bounds **in the constructor too**, not just setters — deploy-time misconfiguration bypasses setter validation.
- `DEFAULT_ADMIN_ROLE` is the true blast radius (can re-grant GAS_MANAGER); prefer `AccessControlDefaultAdminRules` (two-step, delayed) or set admin = protocol multisig/timelock. Never leave GAS_MANAGER and DEFAULT_ADMIN as the same EOA.
- Emit old/new events on every setter (recurring audit finding; enables monitoring).

## 2. Exploit Precedents

| Incident | Date | Loss | Mechanism | Relevance |
|---|---|---|---|---|
| Synthetix sKRW | Jun 2019 | ~$1B notional (recovered) | Oracle unit-scaling error (1000x) | The scaling-error class to fuzz against |
| Venus + Blizz (LUNA) | May 2022 | ~$22M | Chainlink feed hit minAnswer floor/froze; protocols kept consuming | Direct precedent for frozen-feed consumption (§18.1.4) |
| Post-Merge feed deprecations | Sep 2022 | near-misses | Deprecated feeds froze at last values on PoW fork | Deprecated feeds freeze, don't revert — plan cutovers proactively |
| BonqDAO | Feb 2023 | ~$120M | Permissionless oracle update | Why setter gating+bounds matter (§4.1) |
| Rho Markets | Jul 2024 | $7.6M (returned) | Team misconfigured own oracle | Operator error ≈ key compromise; bounds+events+monitoring |
| KiloEx | Apr 2025 | ~$7.5M | Insufficiently gated price-setter | Access control on oracle setters (§4.3) |
| Compound/DAI Coinbase oracle | Nov 2020 | ~$89M liquidations | Thin upstream source | Blending unequal-quality sources degrades to the worse one |
| Multi-block basefee research (ChainSecurity, DISC 2023) | 2022-23 | academic | Proposers known ~12.8min ahead; k=2 same-builder runs ~514×/day, observed up to k=17 | Multi-block basefee manipulation feasible; economics are the defense |

No known incident weaponizes `block.basefee` as an oracle input — manipulation burns real ETH and the value here prices a fee paid *to* the protocol.

## 3. Attack Surface Map

### 3.1 Basefee manipulation (builders/validators)
±12.5%/block; 2x ≈ 6 consecutive full blocks, 3x ≈ 10. Cost: ~30M gas × k blocks burned at rising basefee (~0.3-0.5 ETH+ per sequence at 1 gwei), runs must be bought from proposers. Payoff: none — inflation increases fees paid TO Superform; deflation saves a strategy fractions of 0.2 UP. **Economically irrational.** Document in NatSpec that the oracle is fit for *fee charging only*, not collateral/settlement pricing — future reuse is the latent risk.

### 3.2 Compromised GAS_MANAGER key — quantified
Max answer under bounds: `3 × basefee + 10 gwei`; the additive 10 gwei bound dominates at sub-gwei basefees.
- Worst-case overcharge ≈ 3x (high-gas regime) to ~15-20x (low-gas regime): ~0.2 UP honest → ~0.6-4 UP.
- Auto-pause griefing: a strategy prefunded for N honest updates survives ~N/f under overcharge f — a week's prefund at 10x dies in <1 day, **not instantly**; monitoring on setter events catches it in the window.
- GAS_MANAGER **cannot**: make the oracle revert, return ≤0, freeze `updatedAt`, or touch the USD→UP hops. Well-contained key. DEFAULT_ADMIN needs multisig/timelock treatment.

### 3.3 No-key surface
- Chainlink Fast Gas freeze (bounded per reconciliation note) — largest expected-value risk, needs no attacker.
- **Organic gas spikes**: a real 50-gwei day multiplies upkeep cost 30-50x *legitimately*; balances sized for calm markets can auto-pause on honest volatility alone. Mitigate with balance-vs-max-bound alerting (monitoring side).

## 4. Recommended Security Patterns
1. Constructor-validated bounds (same checks as setters), named constants, custom errors.
2. Old/new events on every setter + off-chain alerts.
3. `AccessControlDefaultAdminRules` or admin = governance multisig; GAS_MANAGER ≠ DEFAULT_ADMIN key.
4. `SafeCast.toInt256`; `roundId = answeredInRound = uint80(block.number)`; `startedAt = updatedAt = block.timestamp`.
5. Cutover hygiene: off-chain monitor on Fast Gas `updatedAt` + feed divergence; scheduled follow-up removal of the frozen feed.
6. NatSpec trust model: per-block-fresh value justifies `updatedAt = block.timestamp`; fee-charging only.
7. Optional: `paramsLastUpdatedAt`; `maxAnswerWei` ceiling (e.g. 10,000 gwei) against client-bug anomalies.

## 5. Testing Recommendations

**Fuzz** (via `vm.fee`): basefee ∈ [0, 10_000 gwei] × multiplierBps ∈ [5000, 30000] × priorityFeeWei ∈ [0, 10 gwei] — answer exact vs reference formula, no reverts; include basefee = 0 and 7 wei edge. Setter fuzz just inside/outside bounds; non-role callers revert; revocation takes effect.

**Invariants**: `answer > 0` (basefee ≥ 1); `answer ≤ 3*basefee + 10 gwei`; monotone in basefee and each knob; `updatedAt == block.timestamp`; `answeredInRound >= roundId > 0`; `decimals() == 0`.

**Fork (mainnet)**:
- Unit parity: BasefeeGasOracle vs live Fast Gas answer within sanity band (0.2x-5x) at same block — catches 1e9 mismatch either direction.
- End-to-end 3-hop: `getUpkeepCostPerSingleUpdate` within 2× of recorded baseline (0.2157 UP) after SUPERFORM registration; re-assert under `vm.fee` shocks (0.1x/10x/100x).
- Cutover rehearsal: (a) frozen-high Fast Gas + fresh timestamps → assert blended average bounded; (b) warp +1 day (feed stale) → assert dropped from average, our feed carries alone, upkeep still charged (not free); (c) all-stale sanity: only reachable if our feed is deregistered.
- Auto-pause economics: fund strategy for N honest updates, set knobs to max bound, assert pause at ~N/f and ppsStale; assert recovery path.

**Review checklist sections**: vulnerabilities.md §2, §3.1-3.2, §4.1-4.3, §6.3, §14.3, §18.1.4, §24.10, §35, §48.6, §48.11.

Sources: ChainSecurity "Oracle Manipulation after the Merge"; DISC 2023 basefee-manipulation paper; arXiv 2303.04430 (multi-block MEV); Uniswap v3 oracles in PoS; Etherscan Fast Gas feed page.
