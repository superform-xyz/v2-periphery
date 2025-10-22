# Solidity Technical Change Proposals for SuperVaultStrategy

## Document Overview
This document outlines four critical bugs identified in the `SuperVaultStrategy` contract's vesting mechanism for Price Per Share (PPS) calculations. The bugs relate to vesting simulation failures, inconsistent timestamps, immediate application of initial jumps, and a dilution-based attack vector during vesting periods. Each bug is described in detail, including its root cause, potential impacts (e.g., fairness issues, MEV risks, or economic exploits), and example scenarios. The proposed solutions draw from Yearn Finance V3's profit unlocking approach where applicable, adapted to a PPS-only model (no `totalSupply` or `totalAssets` dependencies). Specific code changes are provided with before/after snippets.

The solutions focus on merging jumps, capping on decreases while preserving targets, consistent timestamps, and proper initialization. These use the existing `VestingData` struct and in-memory PPS computations for vesting.

## Assumptions and General Changes
- PPS is sourced off-chain via `ISuperVaultAggregator`.
- No changes to struct; all fixes via logic adjustments.
- Test for: multiple jumps, dilutions, losses, first jump, views vs. actual updates.

---

## Bug 1: Premature Completion of Ongoing Vesting on New Jumps
### Description
This bug occurs when a new PPS increase (jump) is detected during an active vesting period. The current logic in both simulation (view functions) and actual updates forces the effective PPS to immediately jump to the previous `targetPPS`, completing the ongoing vesting prematurely. It then starts a new vesting from this completed point to the new PPS. This effectively abandons any remaining unvested portion of the original vesting delta, causing an unexpected acceleration of yield realization.

**Root Cause**: The update and simulation logic resets the vesting state without first vesting (degrading) the existing delta up to the current timestamp. Instead, it treats the new jump as a hard reset, overwriting the in-progress vesting.

**Potential Impacts**:
- **Fairness Issues**: Users experience erratic PPS changes; frequent harvests (via `executeHooks`) could accelerate yields unevenly, benefiting or harming users based on timing.
- **MEV Risks**: Managers or frontrunners could time jumps to manipulate effective PPS for deposits/redeems.
- **Predictability Loss**: Vesting becomes non-linear and non-smooth, undermining the MEV-protection intent of gradual unlocking.

**Example Scenario**:
- At T=0: PPS jumps to 1.1; vesting starts from 1.0 to 1.1 over 10 days.
- At T=5: Effective PPS = 1.05 (50% vested).
- New jump to 1.2 at T=5: Logic jumps effective to 1.1 (abandons remaining 0.05 unvested from first), then vests 1.1 to 1.2. Users see sudden +0.05 jump, not gradual.

### Solution
Merge new jumps: Vest (degrade) the existing delta to the current timestamp, add the new delta to the remaining unvested portion, update `targetPPS` accordingly, and reset the timer. This delays but fully preserves the old unvested yield, ensuring smooth accumulation without acceleration.

### Code Changes
#### Change to `updateVesting` (in SuperVaultStrategy)
**Before:**
```solidity
function updateVesting() public returns (uint256 currentPPS, VestingData memory vData) {
    // ... original logic with if (currentPPS > vData.targetPPS) { reset to targetPPS } ...
}
```

**After:**
```solidity
function updateVesting() public returns (uint256 currentPPS, VestingData memory vData) {
    ISuperVaultAggregator aggregator = _getSuperVaultAggregator();
    currentPPS = aggregator.getPPS(address(this));
    uint256 currentTs = aggregator.getLastUpdateTimestamp(address(this));
    vData = vestingData;

    if (vData.duration == 0) return (currentPPS, vData);  // No vesting

    // Degrade existing vesting
    uint256 elapsed = currentTs > vData.startTime ? currentTs - vData.startTime : 0;
    uint256 delta = uint256(vData.targetPPS) - uint256(vData.startPPS);
    uint256 vested = 0;
    if (delta > 0) {
        if (elapsed >= vData.duration) {
            vested = delta;
        } else {
            vested = delta.mulDiv(elapsed, vData.duration, Math.Rounding.Floor);
        }
    }

    // Update startPPS with vested
    uint256 newStartPPS = uint256(vData.startPPS) + vested;

    // Handle new PPS value
    uint256 newTargetPPS = vData.targetPPS;
    if (currentPPS > vData.targetPPS) {
        // Merge increase: Add new delta to remaining unvested
        uint256 remainingUnvested = delta - vested;
        uint256 newDelta = currentPPS - vData.targetPPS;
        newTargetPPS = newStartPPS + remainingUnvested + newDelta;
        vData.startTime = uint48(currentTs);  // Reset timer
    } else if (currentPPS < vData.targetPPS) {
        // New: Handle decrease (dilution/loss)
        uint256 currentEffective = newStartPPS;
        newStartPPS = Math.min(currentEffective, currentPPS);
        // Preserve targetPPS to unlock full yield
        vData.startTime = uint48(currentTs);  // Reset timer
        uint256 remainingDuration = vData.duration > elapsed ? vData.duration - elapsed : 1;  // Avoid div0
        vData.duration = uint48(remainingDuration);  // Adjust to remaining
        emit VestingDecreaseHandled(currentPPS, newTargetPPS, remainingDuration);
    } else {
        // No change: Just update target with remaining unvested
        newTargetPPS = newStartPPS + (delta - vested);
    }

    vData.startPPS = uint80(newStartPPS);
    vData.targetPPS = uint80(newTargetPPS);

    vestingData = vData;
    emit VestingUpdated(currentPPS, vData.duration, currentTs);
    return (currentPPS, vData);
}
```

Add new event:
```solidity
event VestingDecreaseHandled(uint256 newPPS, uint256 preservedTarget, uint256 remainingDuration);
```

---

## Bug 2: Incorrect startTime in Simulation
### Description
In view functions like `getEffectivePPS`, the simulation for new PPS jumps uses `block.timestamp` as the simulated `startTime`, while actual updates in `updateVesting` use the aggregator's `lastUpdateTimestamp` (potentially earlier, e.g., oracle update time). This mismatch causes view functions to return inconsistent or underestimated effective PPS if there's a delay between the PPS jump and calling `updateVesting`. Users querying views see stale/low values, which could enable front-running (e.g., deposit at low simulated PPS, then trigger update for gains).

**Root Cause**: Discrepancy between simulation timestamp (`block.timestamp`) and actual start (`lastUpdateTimestamp`), especially for passive/oracle-based PPS accruals.

**Potential Impacts**:
- **Front-Running Risks**: Attackers exploit low simulated PPS for deposits/redeems before updates.
- **User Confusion**: Views don't accurately predict post-update PPS, leading to poor decisions.
- **Inconsistency**: Pre- and post-call PPS differ unexpectedly.

**Example Scenario**:
- PPS jumps at T=0 (lastUpdate=0), but update delayed.
- At T=3 (view): Simulates start=3, elapsed=0, effective=old PPS (underestimate).
- Call update at T=3: start=0, elapsed=3, effective=30% vested. Sudden jump enables arb.

### Solution
Use `lastUpdateTimestamp` consistently for simulated jump starts in views, ensuring views match the state after an actual update call.

### Code Changes
#### Change to `calculateEffectivePPS` (in SuperVaultAccountingLib)
**Before:**
```solidity
function calculateEffectivePPS(
    uint256 currentPPS,
    ISuperVaultStrategy.VestingData memory vData,
    uint256 lastUpdateTimestamp
) internal pure returns (uint256) {
    // ... simulation with startTime = lastUpdateTimestamp (already partial, but expand for merge/decrease) ...
}
```

**After:**
```solidity
function calculateEffectivePPS(
    uint256 currentPPS,
    ISuperVaultStrategy.VestingData memory vData,
    uint256 ts  // lastUpdateTimestamp or block.timestamp for actual
) internal pure returns (uint256) {
    uint256 targetPPS = currentPPS;
    uint256 startPPS = vData.startPPS;
    uint256 startTime = vData.startTime;

    if (targetPPS > vData.targetPPS) {
        // Simulate merge for increase
        uint256 elapsedOld = ts > startTime ? ts - startTime : 0;
        uint256 delta = uint256(vData.targetPPS) - uint256(startPPS);
        uint256 vestedOld = elapsedOld >= vData.duration ? delta : delta.mulDiv(elapsedOld, vData.duration, Math.Rounding.Floor);
        uint256 simStart = uint256(startPPS) + vestedOld;
        uint256 remainingUnvested = delta - vestedOld;
        uint256 newDelta = targetPPS - vData.targetPPS;
        targetPPS = simStart + remainingUnvested + newDelta;
        startTime = ts;  // Simulate reset with ts (lastUpdateTimestamp)
    } else if (targetPPS < vData.targetPPS) {
        // Simulate cap for decrease
        uint256 elapsed = ts > startTime ? ts - startTime : 0;
        if (vData.duration == 0 || elapsed == 0) return targetPPS;
        uint256 currentEffective = elapsed >= vData.duration ? vData.targetPPS :
            uint256(startPPS) + (uint256(vData.targetPPS - startPPS).mulDiv(elapsed, vData.duration, Math.Rounding.Floor));
        startPPS = Math.min(currentEffective, targetPPS);
        // Preserve targetPPS
        uint256 remaining = vData.duration > elapsed ? vData.duration - elapsed : 1;
        vData.duration = uint48(remaining);  // Simulate adjust
        startTime = ts;  // Simulate reset
    }

    if (targetPPS <= startPPS) return targetPPS;
    if (ts <= startTime) return startPPS;
    uint256 elapsed = ts - startTime;
    if (elapsed >= vData.duration) return targetPPS;
    uint256 vested = (targetPPS - startPPS).mulDiv(elapsed, vData.duration, Math.Rounding.Floor);
    return startPPS + vested;
}
```

#### Change to `getEffectivePPS` (in SuperVaultStrategy)
**Before:**
```solidity
function getEffectivePPS() public view returns (uint256) {
    // ... call with block.timestamp ...
}
```

**After:**
```solidity
function getEffectivePPS() public view returns (uint256) {
    ISuperVaultAggregator aggregator = _getSuperVaultAggregator();
    uint256 currentPPS = aggregator.getPPS(address(this));
    uint256 lastTs = aggregator.getLastUpdateTimestamp(address(this));
    VestingData memory vData = vestingData;
    uint256 effective = SuperVaultAccountingLib.calculateEffectivePPS(currentPPS, vData, lastTs);
    return Math.min(effective, currentPPS);  // Cap to prevent > real
}
```

---

## Bug 3: First Jump Applies Immediately
### Description
In the initial contract state (post-initialization), `targetPPS == 0`. When the first PPS jump occurs, the logic sets `startPPS = targetPPS` (the new PPS), resulting in `startPPS == targetPPS`. This causes the effective PPS to immediately equal the full jumped value, bypassing the vesting duration entirely. Subsequent jumps vest normally, but this inconsistency treats the first yield event differently.

**Root Cause**: No initial base PPS set; logic falls back to setting `startPPS = currentPPS` when `targetPPS == 0`, skipping delta calculation.

**Potential Impacts**:
- **Unfairness**: Early adopters get instant yields, while later ones get vested—disproportionate benefits.
- **Inconsistency**: Undermines the protocol's vesting promise for all yield increases.
- **Edge Case Exploits**: If init PPS is low, first harvest could be manipulated for instant gains.

**Example Scenario**:
- Init: vesting all 0.
- First jump to 1.1: Sets startPPS=1.1, targetPPS=1.1; effective=1.1 instantly (no 10-day vest).
- Next jump to 1.2: Vests 1.1 to 1.2 over 10 days. Initial users advantaged.

### Solution
Initialize `startPPS` and `targetPPS` to `PRECISION` (1.0 equivalent), so the first jump creates a delta and vests gradually, consistent with later jumps.

### Code Changes
#### Change to `initialize` (in SuperVaultStrategy)
**Before:**
```solidity
function initialize(address vaultAddress, FeeConfig memory feeConfigData) external initializer {
    // ... 
    vestingData.duration = 10 days;
    emit Initialized(_vault);
}
```

**After:**
```solidity
function initialize(address vaultAddress, FeeConfig memory feeConfigData) external initializer {
    // ... 
    vestingData.duration = 10 days;
    vestingData.startPPS = uint80(PRECISION);  // Base 1.0
    vestingData.targetPPS = uint80(PRECISION);
    vestingData.startTime = uint48(block.timestamp);
    emit Initialized(_vault);
}
```

---

## Bug 4: Dilution Attack Vector During Vesting
### Description
An attacker can exploit vesting by depositing a large amount early in a vesting period (at low effective PPS), diluting the real PPS. If the logic ignores PPS decreases (e.g., dilution makes real PPS < target), effective PPS continues rising toward the stale target, exceeding real PPS. The attacker then redeems at the overstated effective PPS, draining yields (over-redemption).

**Root Cause**: Vesting only handles increases; decreases are ignored, allowing effective > real PPS mismatch.

**Potential Impacts**:
- **Economic Exploit**: Attacker steals yields (e.g., full 10% yield with 10x TVL deposit).
- **Honest User Loss**: Remaining users lose unvested yields; low-TVL vaults vulnerable.
- **Requires Capital**: Needs large flash-loanable funds; mitigated by async redeems/guardians, but theoretical risk.

**Example Scenario**:
- Vesting 1.0 to 1.1 over 10 days.
- Day 1 (effective=1.01): Attacker deposits 10x TVL, dilutes real PPS to 1.018.
- If decrease ignored, effective rises to 1.02 (day 2).
- Redeem at 1.02: Gets > deposited, steals yield.

### Solution
On decreases, cap `startPPS` to min(current effective, currentPPS) to prevent effective > real, but preserve `targetPPS` (unlocks full yield). Reset timer and adjust duration to remaining elapsed for smoothness.

### Code Changes
Integrated into Bug 1's `updateVesting` (else if currentPPS < targetPPS branch) and `calculateEffectivePPS` simulation.

#### Additional Change to `getVestingProgress` (in SuperVaultStrategy)
**Before:**
```solidity
function getVestingProgress() external view returns (...) {
    // ... 
}
```

**After:**
```solidity
function getVestingProgress() external view returns (uint256 currentPPS, uint256 effectivePPS, uint256 startPPS, uint256 targetPPS, uint256 elapsed, uint256 duration, bool vestingComplete) {
    ISuperVaultAggregator aggregator = _getSuperVaultAggregator();
    currentPPS = aggregator.getPPS(address(this));
    uint256 lastTs = aggregator.getLastUpdateTimestamp(address(this));
    VestingData memory vData = vestingData;
    effectivePPS = SuperVaultAccountingLib.calculateEffectivePPS(currentPPS, vData, lastTs);
    effectivePPS = Math.min(effectivePPS, currentPPS);  // Cap
    startPPS = vData.startPPS;
    targetPPS = vData.targetPPS;
    elapsed = block.timestamp > vData.startTime ? block.timestamp - vData.startTime : 0;
    duration = vData.duration;
    vestingComplete = (elapsed >= duration);
    return (currentPPS, effectivePPS, startPPS, targetPPS, elapsed, duration, vestingComplete);
}
```

---

## Implementation Notes
- **Deployment**: No struct changes; compatible with existing.
- **Testing**: Scenarios: mid-vesting dilution (cap effective, preserve target), rapid jumps (merge preserves), first jump (vests), view delays (consistent sim).
- **Gas**: Similar to original; pure PPS math efficient.
- **Security**: Audit for div0, overflows in mulDiv.

This resolves all bugs with PPS-only logic.