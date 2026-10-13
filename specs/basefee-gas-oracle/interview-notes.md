# BasefeeGasOracle — Interview Notes

Date: 2026-08-18
Interviewed: cosmin (pod: v2-periphery)
Context: Chainlink notified deprecation of the Fast Gas / Gwei feed on Ethereum mainnet ("deprecated by or shortly after 9/2/26"). This feed is SuperOracle's only GAS_QUOTE→WEI_QUOTE source on mainnet.

## Background facts established (verified against code + live chain state, 2026-08-18)

- **Single on-chain consumer, mainnet only.** GAS_QUOTE is consumed only by
  `SuperGovernor._convertGasToUpkeepToken` (`src/SuperGovernor.sol:827`), reached via
  `getUpkeepCostPerSingleUpdate`, whose only on-chain caller is
  `SuperVaultAggregator.updatePPS` (`src/SuperVault/SuperVaultAggregator.sol:287`) — wrapped in try/catch.
- **Live mainnet registration.** SuperOracle `0x8943128DbAb4279D561654dEED2930Bb975AA070`:
  GAS→WEI under CHAINLINK provider = Fast Gas feed `0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C`
  (decimals()=0, wei-denominated answer; read 75,808,082 ≈ 0.076 gwei on 2026-08-18).
  SUPERFORM provider slot for that pair is empty. Active providers: [CHAINLINK, SUPERFORM].
- **Base/HyperEVM/Flare** all run SuperformGasOracle `0x473b88f017dE39d85a102DA01A35a1b3507eBcFc`
  in that slot — unaffected.
- **Do-nothing failure mode is benign but leaky:** stale feed → AVERAGE path skips it →
  `NO_VALID_REPORTED_PRICES()` → caught by try/catch → `upkeepCost = 0`, `isExempt = true`.
  PPS updates keep flowing; upkeep silently becomes free. `defaultStaleness` = 86400 live.
  `isUpkeepPaymentsEnabled()` = true on mainnet, so this is real revenue leakage.
- **Off-chain views revert** (`NO_VALID_REPORTED_PRICES`), not zero — Superman/OMS/erebor sweep
  needed separately (out of scope for this contract).
- **Governance flow:** `SuperGovernor.queueOracleUpdate` → 1-week `TIMELOCK_PERIOD`
  (`src/oracles/SuperOracleBase.sol:40`) → `executeOracleUpdate`, both `_ORACLE_MANAGER_ROLE`-gated.
- **Baseline for cutover assertion:** `getUpkeepCostPerSingleUpdate(0x366d88F03B8EF34eb49F32a927ff6e1609F694F2)`
  = 215713625755269600 (~0.2157 UP) at `gasPerEntry` = 135,000. Live basefee at time of
  measurement: 44,748,267 wei (~0.045 gwei); node-suggested tip: 100,000 wei.

## Decisions (AskUserQuestion round, 2026-08-18)

1. **Formula:** Keep the multiplier knob.
   `answer = block.basefee * multiplierBps / 10_000 + priorityFeeWei`, wei-denominated, `decimals() = 0`.
   Default multiplierBps = 10_000 (1x). Rationale: policy knob for deliberate over/under-recovery
   without redeploy; charge executes inside the PPS-update tx so basefee at read time is exact.

2. **Migration:** Register under the **SUPERFORM provider** for GAS→WEI (additive), leaving the
   CHAINLINK Fast Gas slot in place. AVERAGE blends both while Fast Gas lives; when it goes stale
   post-deprecation it is skipped automatically. Zero flag day, single governance action.
   Accepted risk: garbage-but-fresh Fast Gas values pollute the average during the deprecation
   window (bounded by 1-day staleness and the 2× fork-test guard; can replace the CHAINLINK slot
   later if it misbehaves).

3. **Access control:** Standalone OZ `AccessControl` with `DEFAULT_ADMIN_ROLE` + `GAS_MANAGER_ROLE`,
   matching the existing `SuperformGasOracle` pattern (`src/oracles/SuperformGasOracle.sol`).
   Admin = protocol multisig.

4. **Safety rails:** Bounds enforced in setters (chosen option):
   - `multiplierBps` ∈ [5_000, 30_000] (0.5x–3x), constructor + setter.
   - `priorityFeeWei` ≤ 10 gwei cap, constructor + setter.
   - Since multiplierBps ≥ 5_000 and basefee ≥ 1 wei on mainnet, answer can never be 0 →
     the silent provider-skip (`answer <= 0` → untrusted → skipped) is structurally impossible.
   (Floor-at-1-wei and upper answer clamp were offered and not selected; bounds subsume the floor.)

## Requirements distilled

### Functional
- AggregatorV3Interface-compatible: `latestRoundData`, `getRoundData`, `decimals`=0,
  `description`, `version`; legacy `latestAnswer` for parity with SuperformGasOracle.
- Answer = `block.basefee * multiplierBps / 10_000 + priorityFeeWei` in wei per gas unit.
- `updatedAt`/`startedAt` = `block.timestamp` — can never go stale.
- Role-gated setters for both knobs with the bounds above, events on change.
- No keeper, no cron, no external dependencies.

### Non-functional
- Wei/gwei unit-confusion protection: the cutover check is a mainnet-fork test asserting
  post-registration `getUpkeepCostPerSingleUpdate` stays within ~2× of the recorded baseline
  (known 1e9-class confusion precedent in this stack — Octane finding, direction analysis:
  gwei-where-wei = 1e9 undercharge; mis-scaled wei = 1e9 overcharge → InsufficientUpkeep →
  per-strategy auto-pause + ppsStale at `SuperVaultAggregator.sol:1299-1305`, painful manual
  recovery due to C1-RE_ANCHOR post-unpause timestamp rule).
- Manipulation surface: basefee is protocol-bounded (±12.5%/block); PPS keeper has no incentive
  to time gas spikes (upkeep flows to protocol, not keeper).
- Deadline: queue governance by ~Aug 25–26 to be live before Sep 2 (soft deadline — miss costs
  revenue, not uptime).

### Initial calibration (proposed, confirm at deploy)
> **REVISED 2026-08-18 (post-implementation):** user decided `multiplierBps = 20_000` (2x) —
> deliberate over-recovery, charging above what the Fast Gas feed quoted (~1.3-1.8x of its
> charge given Fast Gas runs ~1.1-1.5x raw basefee). Fork-test acceptance band widened to
> [0.2x, 3x] accordingly (upper = MAX_MULTIPLIER_BPS); it guards unit errors, not policy.
- `multiplierBps` = 10_000 (1x). *(superseded — see revision note above)*
- `priorityFeeWei` = 1_000_000 wei (0.001 gwei; ~10× today's suggested tip, negligible vs accuracy).
- Expected answer at deploy ≈ basefee + 1e6 ≈ 4.6e7 wei — same order as Fast Gas's 7.6e7,
  well within the 2× guard.

### Testing
- Unit: constructor/setter bounds, role gating, formula correctness (fuzz basefee via vm.fee),
  interface conformance, answer positivity invariant.
- Mainnet fork: register under SUPERFORM via pranked governance flow (warp past 1-week timelock),
  assert `getUpkeepCostPerSingleUpdate` within 2× baseline; simulate Fast Gas going stale
  (warp +1 day without CL update) and assert cost query still returns sane value from our feed
  alone; assert updatePPS path charges (not free) after Fast Gas death.

## Out of scope
- Superman/OMS/erebor off-chain sweep for revert-vs-zero handling.
- L2 chains (already on SuperformGasOracle).
- Replacing the CHAINLINK slot (possible follow-up governance action).
