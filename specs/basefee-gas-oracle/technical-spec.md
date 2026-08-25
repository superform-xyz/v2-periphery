# BasefeeGasOracle Technical Specification

## Overview

An AggregatorV3Interface-compatible gas-price oracle for Ethereum mainnet that computes its
answer from `block.basefee` at read time:

```
answer = block.basefee * multiplierBps / 10_000 + priorityFeeWei   // wei per gas, decimals() = 0
```

It replaces the Chainlink Fast Gas / Gwei feed (`0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C`)
as SuperOracle's GAS_QUOTE→WEI_QUOTE source on mainnet. Chainlink has given direct written notice
that the feed "will be deprecated by or shortly after 9/2/26" (the public deprecation list lags
private outreach; the feed was still live on 2026-08-18).

No keeper, no cron, no external dependencies. Because the upkeep charge executes inside the same
PPS-update transaction that reads the oracle, `block.basefee` at read time is exactly the basefee
the keeper pays in that block — this is *more* accurate than the pushed Fast Gas feed, and the
formula shape is the canonical EIP-3198-motivated pattern (`BASEFEE + x` / `BASEFEE * (1+x)`
poke-bounty pricing named in the EIP's own motivation). The `+ priorityFeeWei` term fixes the
basefee-only undercounting deficiency OpenZeppelin flagged in Compound v3's `absorb` accounting.

## Problem Statement

GAS_QUOTE→WEI_QUOTE on mainnet has exactly one registered feed (Fast Gas, under the CHAINLINK
provider) and exactly one on-chain consumer: `SuperGovernor._convertGasToUpkeepToken`
(`src/SuperGovernor.sol:827`), reached via `getUpkeepCostPerSingleUpdate`, called only from
`SuperVaultAggregator.updatePPS` (`src/SuperVault/SuperVaultAggregator.sol:287`) inside a
try/catch. When the feed freezes post-deprecation (deprecated Chainlink feeds stop updating —
`updatedAt` freezes, no revert):

1. For ≤ `feedMaxStaleness` (86400s live) the frozen answer keeps being served.
2. After that, SuperOracle's AVERAGE path drops the stale feed; with no other feed the read
   reverts `NO_VALID_REPORTED_PRICES()` → caught → `upkeepCost = 0`, `isExempt = true` →
   **PPS updates keep flowing but upkeep is silently free** (payments are enabled on mainnet:
   `isUpkeepPaymentsEnabled() = true`). No outage — but permanent revenue leakage.
3. Off-chain consumers of the cost views get reverts (separate Superman/OMS/erebor sweep,
   out of scope here).

Base/HyperEVM/Flare already run SuperformGasOracle (`0x473b88f017dE39d85a102DA01A35a1b3507eBcFc`)
in this slot (verified live on all three) and are unaffected.

## Proposed Solution

1. **New contract** `src/oracles/BasefeeGasOracle.sol` (~90 lines), modeled 1:1 on
   `SuperformGasOracle.sol` conventions.
2. **Additive governance registration** under the already-active SUPERFORM provider for the
   GAS_QUOTE→WEI_QUOTE pair on mainnet SuperOracle. The AVERAGE path blends both feeds while
   Fast Gas lives; when it freezes and exceeds staleness it is dropped automatically
   (`SuperOracleBase.sol:365-368, 467-470`) and BasefeeGasOracle carries the pair alone.
   Zero flag day; the frozen-answer blend window is bounded at ≤ 24h.
3. **Deploy + governance runbook** with the operational guards identified in specflow analysis
   (global pending-slot collision, role-gated execute, separate admin/manager keys).

## Technical Design

### Contract: `src/oracles/BasefeeGasOracle.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";

/// @title BasefeeGasOracle
/// @notice Chainlink-compatible gas price oracle computing its answer from block.basefee at read time
/// @dev Replaces the deprecated Chainlink Fast Gas feed on Ethereum mainnet for SuperOracle's
///      GAS_QUOTE -> WEI_QUOTE pair. Answer is wei per gas unit with 0 decimals, matching the
///      Fast Gas feed's convention (wei-denominated despite the "Gwei" name).
///      answer = block.basefee * multiplierBps / 10_000 + priorityFeeWei
///      The value is intrinsically fresh every block, so updatedAt = block.timestamp is
///      semantically honest and the feed can never go stale.
///      TRUST MODEL: fit for fee charging only (charge executes in the same tx as the read;
///      basefee is proposer-influenceable +-12.5%/block) — NOT for collateral or settlement pricing.
///      NOTE: in a fee-field-less eth_call, nodes force block.basefee to 0, so off-chain reads
///      return priorityFeeWei only; pass explicit gas-price fields for true quotes.
contract BasefeeGasOracle is AggregatorV3Interface, AccessControl {
    // ERRORS
    error INVALID_MULTIPLIER();      // multiplierBps outside [MIN_MULTIPLIER_BPS, MAX_MULTIPLIER_BPS]
    error INVALID_PRIORITY_FEE();    // priorityFeeWei > MAX_PRIORITY_FEE_WEI
    error ZERO_ADDRESS();

    // EVENTS
    event MultiplierUpdated(uint256 oldMultiplierBps, uint256 newMultiplierBps);
    event PriorityFeeUpdated(uint256 oldPriorityFeeWei, uint256 newPriorityFeeWei);

    // ROLES — reuses the platform-wide role string (SuperGovernor.sol:98)
    bytes32 public constant GAS_MANAGER_ROLE = keccak256("GAS_MANAGER_ROLE");

    // BOUNDS
    uint256 public constant MIN_MULTIPLIER_BPS = 5_000;            // 0.5x
    uint256 public constant MAX_MULTIPLIER_BPS = 30_000;           // 3x
    uint256 public constant MAX_PRIORITY_FEE_WEI = 10 gwei;
    uint256 private constant BPS_DENOMINATOR = 10_000;

    // STATE (packed: both fit one slot)
    uint128 public multiplierBps;
    uint128 public priorityFeeWei;
    /// @notice Timestamp of the last knob change (off-chain stale-config monitoring)
    uint256 public paramsLastUpdatedAt;

    uint8 private constant DECIMALS = 0;
    string private constant DESCRIPTION = "Basefee Gas / Wei";
    uint256 private constant VERSION = 1;

    /// @param admin_ receives DEFAULT_ADMIN_ROLE (protocol multisig)
    /// @param gasManager_ receives GAS_MANAGER_ROLE (MUST differ from admin_ key in prod)
    constructor(uint256 multiplierBps_, uint256 priorityFeeWei_, address admin_, address gasManager_) {
        if (admin_ == address(0) || gasManager_ == address(0)) revert ZERO_ADDRESS();
        _setMultiplierBps(multiplierBps_);      // constructor-validated bounds (evm-security §1.5)
        _setPriorityFeeWei(priorityFeeWei_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GAS_MANAGER_ROLE, gasManager_);
    }

    function setMultiplierBps(uint256 v) external onlyRole(GAS_MANAGER_ROLE) { _setMultiplierBps(v); }
    function setPriorityFeeWei(uint256 v) external onlyRole(GAS_MANAGER_ROLE) { _setPriorityFeeWei(v); }

    function _setMultiplierBps(uint256 v) internal {
        if (v < MIN_MULTIPLIER_BPS || v > MAX_MULTIPLIER_BPS) revert INVALID_MULTIPLIER();
        emit MultiplierUpdated(multiplierBps, v);
        multiplierBps = uint128(v);             // safe: bounded <= 30_000
        paramsLastUpdatedAt = block.timestamp;
    }
    // _setPriorityFeeWei analogous with MAX_PRIORITY_FEE_WEI bound

    function _answer() internal view returns (int256) {
        // multiply-then-divide (vulnerabilities.md §3.2); SafeCast is belt-and-suspenders —
        // bounded formula is < 2^255 for any physically reachable basefee
        return SafeCast.toInt256(block.basefee * multiplierBps / BPS_DENOMINATOR + priorityFeeWei);
    }

    /// @dev roundId = answeredInRound = uint80(block.number): nonzero, monotonic — satisfies
    ///      both modern (updatedAt) and legacy (answeredInRound >= roundId) consumer checks.
    ///      getRoundData returns current data for any requested round (sibling convention).
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        uint80 rid = uint80(block.number);
        return (rid, _answer(), block.timestamp, block.timestamp, rid);
    }
    function getRoundData(uint80) external view override returns (uint80, int256, uint256, uint256, uint80) {
        uint80 rid = uint80(block.number);
        return (rid, _answer(), block.timestamp, block.timestamp, rid);
    }
    function decimals() external pure override returns (uint8) { return DECIMALS; }
    function description() external pure override returns (string memory) { return DESCRIPTION; }
    function version() external pure override returns (uint256) { return VERSION; }
    /// @notice Legacy interface parity with SuperformGasOracle
    function latestAnswer() external view returns (int256) { return _answer(); }
}
```

Style: boxed section headers, `/// @notice` on errors, full `@param` docs on events, `@inheritdoc`
on interface functions — mirror `SuperformGasOracle.sol` exactly. `forge fmt` + lint clean
(`number_underscore = "thousands"`; `unsafe-typecast` avoided via SafeCast).

**Deliberate deviations from the sibling contract** (each grounded in research):
- No `useBlockTimestamp` toggle — value is fresh by construction (FixedPriceOracle precedent).
- `roundId` from `block.number`, not a stored counter — there are no pushed rounds.
- Separate `admin_`/`gasManager_` constructor params — the sibling's single-`owner` pattern is
  the exact anti-pattern flagged in security research §1.5.
- Description says "Wei", not "Gwei" — the incumbent's "Fast Gas / Gwei" name over a
  wei-denominated answer is a documented 1e9-trap.

### Initial calibration (constructor args)

| Knob | Value | Rationale |
|---|---|---|
| `multiplierBps` | `20_000` (2x) | **Deliberate over-recovery policy (decided 2026-08-18, revising the initial 1x):** charge more than the Fast Gas feed did. Fast Gas runs ~1.1-1.5x raw basefee, so 2x basefee lands at ~1.3-1.8x of today's charge — above the old feed, below the 3x contract ceiling. |
| `priorityFeeWei` | `1_000_000` (0.001 gwei) | ~10x the node-suggested tip on 2026-08-18 (1e5 wei); dominated by basefee. |

Expected answer at deploy ≈ 2× basefee — measured 1.35-1.75x the live Fast Gas answer across fork
blocks on 2026-08-18. CREATE2 note: constructor args feed the deterministic address — freeze them
before deploy.

### Governance migration (mainnet)

Single action, additive registration:

```
bases    = [GAS_QUOTE]   // 0x2facc608f385d9435b7c3773f83bd2a8902fdca0
quotes   = [WEI_QUOTE]   // 0x0687868a5f4b140eb03f4a07ba66b35601c6fc8f
providers= [keccak256("SUPERFORM")]
feeds    = [<BasefeeGasOracle>]
SuperGovernor.queueOracleUpdate(...)   // _ORACLE_MANAGER_ROLE
... 1 week (TIMELOCK_PERIOD, SuperOracleBase.sol:40) ...
SuperGovernor.executeOracleUpdate()    // _ORACLE_MANAGER_ROLE — NOT permissionless
```

Post-execute state: AVERAGE over {Fast Gas (CHAINLINK), BasefeeGasOracle (SUPERFORM)}. When Fast
Gas freezes: ≤ 24h blended with the frozen answer, then dropped; our feed (never stale) carries
the pair. The "revert → free upkeep forever" mode becomes structurally unreachable.

**Operational runbook (from specflow findings — all mandatory):**
1. **Pending-slot lock:** `pendingUpdate` is one global struct overwritten without collision check
   (`SuperOracleBase.sol:126-147`). From queue until execute, no other `queueOracleUpdate` may be
   submitted org-wide. Before execute, assert on-chain that `pendingUpdate` still matches the
   queued payload.
2. **Execute owner:** `executeOracleUpdate` is `_ORACLE_MANAGER_ROLE`-gated, not permissionless.
   Name the role holder and calendar the execute for timelock-expiry day. Queue by **Aug 25-26**
   → execute ~Sep 1-2. Deadline is soft (a late execute costs only leaked upkeep revenue during
   any freeze gap, not uptime).
3. **Rollback = re-queue only.** Provider-wide removal is ruled out: SUPERFORM also serves UP→USD
   on mainnet (FixedPriceOracle `0x66b30A0Dda7F868796ADC3d70232950D65F3565c`, verified live) —
   removing the provider would break the USD→UP hop of upkeep pricing itself. A bad oracle is
   remediated by re-queueing a corrected feed at the same pair slot (another 7-day timelock,
   during which the bad feed is still averaged — hence the fork-test gate below is the real
   defense). No per-pair removal exists (`_validateOracleInputs` rejects `feed == address(0)`).
4. **Update `_checkSuperOracle`** (`DeployV2Periphery.s.sol:445,797`) to also verify the SUPERFORM
   GAS→WEI registration, so smoke checks can confirm the migration and catch drift.

### Deploy script: `script/DeployBasefeeGasOracle.s.sol`

Clone `DeploySuperformGasOracle.s.sol` structure (DeployV2Base, `broadcast(env)`, deterministic
salt `keccak256("SuperformV2" + namespace + "BasefeeGasOracle" + "v2.0")`, post-deploy `require`
verification, `vm.writeJson` merge into `script/output/{env}/1/Ethereum-latest.json`, `runCheck`
read-only entrypoint) **with separate `admin`/`gasManager` args** (see deviation note above).
Add `ORACLE_BASEFEE_GAS_MAINNET` constant to `script/utils/ConfigBase.sol` next to
`ORACLE_GAS_TO_ETH` (:62-63).

## Attack Surface Analysis

### Oracle & Price
- [x] Unit confusion (1e9 wei/gwei class — §3.2, §26.4.2): wei/0-decimals matches incumbent
      exactly; multiply-before-divide; honest "Wei" description; fork-test unit-parity assertion
      vs the live Fast Gas answer at the same block.
- [x] Stale price handling (§4.2, §48.6): `updatedAt = block.timestamp` is semantically honest
      (per-block-fresh value; wstETH-adapter precedent). The only thing that can "go stale" is the
      knob pair → `paramsLastUpdatedAt` + setter events for monitoring.
- [x] Frozen deprecated co-feed (§18.1.4 — Venus/Blizz LUNA precedent): bounded to ≤ 24h blend by
      SuperOracle's drop-on-stale, then our feed carries the pair alone.
- [x] Manipulation resistance (§24.10): basefee ±12.5%/block; 2x ≈ 6 stuffed blocks with basefee
      burned; break-even needs ~100M+ reimbursed gas next block vs our 135k/update — economically
      irrational. Downward manipulation only self-griefs. NatSpec restricts use to fee charging.

### Access Control (§2.1, §4.3, §35)
- [x] Both setters `GAS_MANAGER_ROLE`-gated; bounds in constructor AND setters.
- [x] Key blast radius quantified: max answer `3 × basefee + 10 gwei` → ~3x (high-gas) to
      ~15-20x (low-gas) overcharge ceiling; cannot revert, return ≤ 0, or freeze the feed.
      A week's honest prefund at 10x overcharge dies in <1 day, not instantly — monitoring on
      setter events catches it in the window.
- [x] `admin_ ≠ gasManager_` enforced procedurally (deploy script args + runbook), DEFAULT_ADMIN
      on the protocol multisig. Setters are instant (no timelock) — accepted: fast-fix beats
      fat-finger risk given bounds cap the damage.
- [ ] N/A: reentrancy (no external calls, no state written on read path), token risks (no tokens),
      flash loans (nothing to borrow against), proxy/upgrade (not upgradeable), vault accounting.

### Downstream (consumer-side, pre-existing behavior — documented, not changed)
- Overcharge → `InsufficientUpkeep` → per-strategy auto-pause + ppsStale
  (`SuperVaultAggregator.sol:1299-1305`); recovery is per-strategy unpause + C1-RE_ANCHOR
  post-unpause signatures. Organic 30-50x gas days can trip this honestly for underfunded
  strategies — monitoring item, not a contract change.
- eth_call zero-basefee: off-chain quotes understate to `priorityFeeWei` unless gas-price fields
  are passed (geth PR #23027). Document for Superman/OMS.

### Exploit precedent check
| Precedent | Loss | Our mitigation |
|---|---|---|
| Synthetix sKRW unit-scaling (2019) | ~$1B notional | Unit-parity fork test; honest description; wei/0-dec match |
| Venus/Blizz frozen LUNA feed (2022) | ~$22M | Additive registration + SuperOracle drop-on-stale bounds freeze exposure to 24h |
| Rho Markets self-misconfiguration (2024) | $7.6M | Constructor+setter bounds; old/new events; monitoring |
| KiloEx ungated setter (2025) | ~$7.5M | Role-gated, bounded setters |
| Compound v3 basefee-only undercount (OZ audit) | — | `+ priorityFeeWei` term |

## Acceptance Criteria

- [ ] `BasefeeGasOracle.sol` implements AggregatorV3Interface + `latestAnswer()`, formula and
      round semantics as specified, bounds `[5_000, 30_000]` bps / `≤ 10 gwei` in constructor and
      setters, old/new events, `paramsLastUpdatedAt`, separate admin/gasManager grants.
- [ ] Unit tests (`test/oracles/BasefeeGasOracle.t.sol`): constructor validation (incl. zero
      addresses, out-of-bounds knobs), setter bounds ± 1, role gating (AccessControlUnauthorizedAccount),
      role revocation, formula exactness under `vm.fee` (explicit edges: 0, 1, 7 wei, 45M wei,
      100 gwei, 10_000 gwei), `testFuzz_` over basefee × both knobs, invariants: answer > 0
      whenever priorityFeeWei > 0 or basefee > 0; answer ≤ 3·basefee + 10 gwei; monotonicity;
      `updatedAt == block.timestamp`; `answeredInRound == roundId > 0` (block > 0); `decimals() == 0`.
- [ ] Fork tests (`test/integration/oracles/BasefeeGasOracleMigration.t.sol`, modeled on
      `UpOracleUpdate.t.sol`): storage-slot role grant (OZ 5.x slot 0), full
      queue → warp(1 weeks + 1) → execute flow (raising feed staleness post-warp per the
      UpOracleUpdate pattern), then:
      - unit parity: our answer within [0.2x, 5x] of live Fast Gas answer at the fork block;
      - end-to-end: `getUpkeepCostPerSingleUpdate(activePPSOracle)` within a [0.2x, 3x]
        policy-aware band of the **same fork block's pre-migration cost** (not a frozen constant —
        specflow finding: hardcoded baselines conflate registration correctness with gas-market
        drift; upper bound = MAX_MULTIPLIER_BPS since the 2x policy legitimately reaches ~2x of
        the Fast Gas charge when its fast-premium compresses), re-asserted under `vm.fee` shocks;
      - frozen-feed rehearsal: warp so Fast Gas exceeds staleness → assert it is dropped, our
        feed carries the pair, `updatePPS` still charges (upkeep NOT free);
      - auto-pause economics: strategy funded for N honest updates, knobs at max bounds → pause
        at ~N/f with ppsStale set, recovery path works.
- [ ] Deploy script with separate admin/gasManager, ConfigBase constant, `_checkSuperOracle`
      extended to verify the SUPERFORM GAS→WEI slot.
- [ ] `forge fmt` + lint clean; NatSpec on all externals; trust-model and eth_call caveats in
      contract-level NatSpec.

## Dependencies & Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Global pending-update slot clobbered during timelock week | Low | Migration silently lost | Org-wide queue freeze + pre-execute `pendingUpdate` assertion (runbook #1) |
| Execute step missed (role-gated, manual) | Medium | Free-upkeep leak extends | Named owner + calendar (runbook #2) |
| Fast Gas freezes before execute lands | Medium | ≤ few days free upkeep | Accepted (benign); queue on Aug 25 maximizes buffer |
| Unit-confusion bug ships | Low | 1e9 over/undercharge; overcharge → fleet auto-pause | Unit-parity + 2x fork gates block execute until green |
| GAS_MANAGER key compromise | Low | ≤ 3x·basefee + 10 gwei overcharge, hours-days to pause | Bounds + setter-event alerting; admin on multisig |
| Frozen-high Fast Gas blend window | Low | ≤ 24h inflated average | Bounded by staleness drop; divergence alert (monitoring) |

## Out of Scope (tracked separately)
- Superman/OMS/erebor sweep: revert-vs-zero handling + eth_call gas-price-fields requirement.
- v2-monitoring additions: Fast Gas `updatedAt` freeze alert, feed-divergence alert, strategy
  upkeep-balance vs max-bound-answer alert, `paramsLastUpdatedAt` staleness alert.
- Follow-up governance cleanup of the dead CHAINLINK slot (optional; system is correct without it).
- L2 chains (already on SuperformGasOracle).

## References
- Research: [research/repo-analysis.md](./research/repo-analysis.md),
  [research/best-practices.md](./research/best-practices.md),
  [research/framework-docs.md](./research/framework-docs.md),
  [research/evm-security.md](./research/evm-security.md),
  [research/specflow-analysis.md](./research/specflow-analysis.md)
- Interview: [interview-notes.md](./interview-notes.md)
- Key code: `src/oracles/SuperformGasOracle.sol` (template), `src/oracles/SuperOracleBase.sol:126-162`
  (timelock), `:329-388` (staleness/quote), `:425-485` (average), `src/SuperGovernor.sol:315-337, 815-845`,
  `src/SuperVault/SuperVaultAggregator.sol:283-305, 1237-1335`, `test/integration/oracles/UpOracleUpdate.t.sol`
  (fork-test template), `script/DeploySuperformGasOracle.s.sol` (deploy template)
- External: EIP-1559, EIP-3198 (motivation names this formula), geth PR #23027 (eth_call basefee=0),
  Chainlink deprecation policy, OZ Compound III audit (basefee-only flag), arXiv:2304.11478
  (basefee manipulation economics)
