# BasefeeGasOracle Spec

## Metadata
- Project: v2-periphery
- Milestone: Chainlink Fast Gas feed deprecation response
- Linear Issue: N/A
- Interview Date: 2026-08-18
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

Chainlink has given direct notice that the Fast Gas / Gwei feed on Ethereum mainnet will be
deprecated by ~Sep 2, 2026. That feed is the sole GAS_QUOTE→WEI_QUOTE source in mainnet
SuperOracle, consumed (only) by `SuperGovernor.getUpkeepCostPerSingleUpdate` to price the upkeep
charged in `SuperVaultAggregator.updatePPS`. Doing nothing causes no outage — the try/catch falls
back to free upkeep — but permanently leaks upkeep revenue once the feed goes stale.

We replace it with `BasefeeGasOracle`, a ~90-line AggregatorV3-compatible contract computing
`block.basefee * multiplierBps / 10_000 + priorityFeeWei` (wei, 0 decimals) at read time. No
keeper or cron; it can never go stale; and since the charge executes in the same tx as the read,
it is *more* accurate than the pushed feed it replaces. Registration is additive under the
already-active SUPERFORM provider, so SuperOracle's AVERAGE blends both feeds until Fast Gas
freezes and is auto-dropped — a zero-flag-day migration in one governance action (1-week timelock;
queue by Aug 25-26).

## Requirements

### Functional
1. AggregatorV3Interface + legacy `latestAnswer()`; `decimals()=0`, wei-denominated (drop-in
   match for the incumbent feed's convention).
2. `answer = block.basefee * multiplierBps / 10_000 + priorityFeeWei`;
   `updatedAt = startedAt = block.timestamp`; `roundId = answeredInRound = uint80(block.number)`.
3. OZ AccessControl: DEFAULT_ADMIN_ROLE (multisig) + GAS_MANAGER_ROLE (separate key) gating two
   setters; bounds `multiplierBps ∈ [5_000, 30_000]`, `priorityFeeWei ≤ 10 gwei` enforced in
   constructor and setters; old/new events; `paramsLastUpdatedAt` for monitoring.
4. Initial calibration: multiplierBps = 20_000 (2x — deliberate over-recovery, charging above the
   old Fast Gas feed), priorityFeeWei = 1_000_000 wei. (Revised 2026-08-18 from the initial 1x.)

### Non-Functional
- Wei/gwei-confusion protection: fork-test gates (unit parity vs live feed; end-to-end cost within
  a [0.2x, 3x] policy-aware band of the same fork block's pre-migration cost) must pass before
  governance execute.
- Manipulation surface bounded by protocol (±12.5%/block) and economically irrational for a
  fee-charging oracle; documented in NatSpec as fee-charging-only.
- Governance queued by Aug 25-26 (soft deadline — a miss costs leaked revenue, not uptime).

## Technical Design

### Architecture
`BasefeeGasOracle` (new, src/oracles/) → registered in mainnet SuperOracle
(`0x8943...A070`) for GAS_QUOTE→WEI_QUOTE under the SUPERFORM provider, alongside the dying
Chainlink Fast Gas feed under CHAINLINK. AVERAGE blends both; SuperOracle drops the frozen feed
after 24h staleness; our feed then carries the pair alone. Consumers unchanged.

### Data Model
No storage changes elsewhere. Contract state: two packed uint128 knobs + `paramsLastUpdatedAt`.

### API Changes
None to existing contracts. New deploy script `DeployBasefeeGasOracle.s.sol` (separate
admin/gasManager args), ConfigBase constant, `_checkSuperOracle` extended to verify the new slot.

## Implementation Plan

### Phase 1: Contract + tests
- [ ] `src/oracles/BasefeeGasOracle.sol` per technical spec
- [ ] Unit tests (bounds, roles, formula fuzz + explicit edges, invariants)
- [ ] Mainnet fork migration test (governance flow, unit parity, 2x relative-baseline,
      frozen-feed rehearsal, auto-pause economics)

### Phase 2: Deploy + governance
- [ ] Deploy script + ConfigBase + smoke-check update
- [ ] Deploy to mainnet; verify roles/knobs via runCheck
- [ ] Queue `queueOracleUpdate` (Aug 25-26); org-wide freeze on other oracle queues
      (single global pending slot has no collision guard)
- [ ] Pre-execute assertion of `pendingUpdate`; execute at timelock expiry (named
      _ORACLE_MANAGER_ROLE holder; calendar entry — execute is NOT permissionless)
- [ ] Post-execute verification + handoff notes to monitoring

## Test Plan
- [ ] Unit tests for: constructor/setter bounds, role gating and revocation, formula exactness
      under `vm.fee` edges (0, 1, 7 wei, current ~45M wei, 100 gwei, 10_000 gwei), fuzz across
      basefee × knob domain, invariants (answer > 0; ≤ 3·basefee + 10 gwei; monotone; fresh
      timestamps; nonzero round ids).
- [ ] Integration (mainnet fork) for: storage-slot role grants, queue→warp→execute, unit parity
      with live Fast Gas, end-to-end upkeep cost vs basefee-derived baseline ± gas shocks,
      stale-feed drop (upkeep still charged, not free), strategy auto-pause/recovery economics.
- [ ] E2E: post-deploy `runCheck` + updated `_checkSuperOracle` smoke test on mainnet.

## Risks & Mitigations
| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| Unit-confusion (1e9) bug ships | Oracle | Low | Overcharge → fleet auto-pause; undercharge → silent leak | Fork-test gates block execute; honest "Wei" naming | Synthetix sKRW 2019 (~$1B notional) |
| Frozen Fast Gas pollutes average | Oracle | Low | ≤24h skewed charges | SuperOracle drop-on-stale bounds window; divergence alert | Venus/Blizz LUNA 2022 (~$22M) |
| GAS_MANAGER key compromise/fat-finger | Access Control | Low | ≤ 3x·basefee + 10 gwei overcharge; hours-days to pause | Constructor+setter bounds; old/new events + alerting; admin≠manager keys | Rho Markets 2024 ($7.6M); KiloEx 2025 (~$7.5M) |
| Pending-update slot clobbered in timelock week | Operational | Low | Migration silently lost | Org-wide queue freeze + pre-execute assertion | — |
| Execute step missed (role-gated) | Operational | Medium | Free-upkeep leak extends | Named owner + calendar entry | — |
| Basefee manipulation | MEV | Very Low | Bounded ±12.5%/block; charge flows to protocol | Economically irrational (break-even ~100M gas/block); NatSpec restricts to fee-charging | arXiv:2304.11478 |
| Organic gas spike auto-pauses underfunded strategies | Operational | Medium (pre-existing) | Per-strategy pause + manual recovery | Balance-vs-max-answer monitoring (out of scope, tracked) | — |

## Open Questions (Resolved)
| Question | Answer | Decided By |
|----------|--------|------------|
| Keep multiplier knob or simplify? | Keep multiplierBps (default 1x) | cosmin, 2026-08-18 |
| Replace CHAINLINK slot or add under SUPERFORM? | Additive under SUPERFORM (zero flag day) | cosmin, 2026-08-18 |
| Access control model? | Standalone AccessControl, admin=multisig, separate GAS_MANAGER key | cosmin, 2026-08-18 |
| Zero/absurd-answer guards? | Bounds in constructor+setters ([5000,30000] bps; ≤10 gwei) | cosmin, 2026-08-18 |
| Rollback lever? | Re-queue at pair slot only — provider removal ruled out (SUPERFORM also serves UP→USD, verified live) | spec research, 2026-08-18 |

## Interview Notes
See: [interview-notes.md](./interview-notes.md)

## Technical Details
See: [technical-spec.md](./technical-spec.md)

## Research
See: [research/](./research/)

---

## Approval
- [ ] Pod Leader Approved
- Approved date: ___

## Next Steps
After approval, run: `/superform:work specs/basefee-gas-oracle/technical-spec.md`
