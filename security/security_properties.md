# Security Properties Documentation

## Table of Contents
1. [Overview](#overview)
2. [Property Execution Flow](#property-execution-flow)
3. [Detailed Properties](#detailed-properties)
4. [Combined Defense-in-Depth](#combined-defense-in-depth)

---

## 1. Overview

This document describes all security properties enforced by the PPS oracle and aggregator system. Properties are listed in the order they execute during a PPS update flow, from signature validation through final storage.

**Key Design Principles:**
- **Defense in Depth:** Multiple overlapping security checks
- **Graceful Degradation:** Business logic rejections use `return` (not `revert`) to allow batch processing
- **Nonce Burning Strategy:** Invalid signatures burn nonces to prevent replay, accepting temporary DoS as trade-off
- **Fail-Safe Defaults:** Reject unless explicitly valid

---

## 2. Property Execution Flow

**Properties execute in the following order:**

1. **ECDSAPPSOracle._validateProofs()** → Property 1
2. **ECDSAPPSOracle._forwardValidEntries()** → Properties 2-3
3. **SuperVaultAggregator.forwardPPS()** → Properties 4-6
4. **SuperVaultAggregator._forwardPPS()** → Properties 7-12

```
┌─────────────────────────────────────────────────────────────┐
│                    ECDSAPPSOracle                           │
├─────────────────────────────────────────────────────────────┤
│ Property 1: Signature Validation & Nonce in Digest         │
│   - Build EIP-712 digest with current nonce                │
│   - Validate signatures from registered validators         │
│   - Quorum requirement                                      │
├─────────────────────────────────────────────────────────────┤
│               Try: forwardPPS()                             │
├─────────────────────────────────────────────────────────────┤
│                SuperVaultAggregator.forwardPPS()            │
├─────────────────────────────────────────────────────────────┤
│ Property 4: Future Timestamp Rejection                     │
│ Property 5: Pause Rejection                                │
│ Property 6: Staleness Enforcement (if payments enabled)    │
├─────────────────────────────────────────────────────────────┤
│                SuperVaultAggregator._forwardPPS()           │
├─────────────────────────────────────────────────────────────┤
│ Property 7: Timestamp Monotonicity                         │
│ Property 8: Post-Unpause Timestamp Validation              │
│ Property 9: Rate Limit Enforcement                         │
│ Property 10: Deviation Threshold                           │
│ Property 11: M/N Threshold Validation                      │
│ Property 12: Upkeep Balance Check                          │
├─────────────────────────────────────────────────────────────┤
│               Success: Store PPS                            │
├─────────────────────────────────────────────────────────────┤
│                    ECDSAPPSOracle                           │
├─────────────────────────────────────────────────────────────┤
│ Property 2: Nonce Increment (after successful forwarding)  │
│ Property 3: Limited Retry Capability (on revert)           │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Properties

### Property 1: Signature Validation & Nonce in Digest

**Formal Specification:**
```
∀ PPS update signature σ for strategy S with current nonce N:
  digest = EIP-712(strategy, pps, timestamp, N)
  σ must be signed by registered validator over digest
  After successful update → N increments to N+1
  Future signatures with nonce N become invalid
```

**Implementation:** `ECDSAPPSOracle._validateProofs()` line 127-141  
**Location:** `src/oracles/ECDSAPPSOracle.sol`  
**Status:** ✓ Verified

**Purpose:** Binds signatures to specific nonce values, preventing replay attacks. Once a nonce increments, previously signed data becomes cryptographically invalid.

**Code Reference:**
```solidity
bytes32 digest = _hashTypedDataV4(
    keccak256(
        abi.encodePacked(
            UPDATE_PPS_TYPEHASH,
            params.strategy,
            params.pps,
            params.timestamp,
            noncePerStrategy[params.strategy]  // Current nonce
        )
    )
);
```

---

### Property 2: Nonce-Based Replay Protection

**Formal Specification:**
```
∀ signature σ with nonce N:
  forwardPPS() succeeds (try block) → nonce increments to N+1
  forwardPPS() reverts (catch block) → nonce remains N
  
  Nonce increments on:
    1. Legitimate PPS updates (accepted)
    2. Business logic rejections using 'return' or 'continue'
  
  Nonce preserved on:
    1. Contract reverts (system errors)
    2. Out of gas conditions
    3. External failures
```

**Implementation:** `ECDSAPPSOracle._forwardValidEntries()` line 260-273  
**Location:** `src/oracles/ECDSAPPSOracle.sol`  
**Status:** ✓ Verified

**Critical Insight:** Nonce burning on business logic rejections is INTENTIONAL to:
- Prevent replay of fundamentally invalid signatures
- Avoid batch DoS (if one strategy reverted, all would fail)
- Force new signatures for invalid data

**Why This Design:**
Using `revert` for business logic rejections would DoS the entire batch. Using `return`/`continue` allows:
- Graceful rejection of invalid signatures
- Batch processing continues for valid strategies
- Nonce burning forces new signatures (prevents retry of fundamentally invalid data)
- No griefing vector for attackers to DoS legitimate updates

---

### Property 3: Limited Retry Capability

**Formal Specification:**
```
∀ signature σ with nonce N:
  EXTERNAL failure (revert/OOG/network) → nonce remains N → can retry
  BUSINESS LOGIC rejection (return/continue) → nonce increments → cannot retry
```

**Retry Possible (External Failures):**
- Contract reverts (system errors)
- Out of gas
- Network/RPC failures

**Retry NOT Possible (Business Logic Rejections):**
- Rate limit exceeded
- Strategy paused
- Insufficient upkeep balance
- Deviation threshold failures
- Pre-unpause signatures (C1-RE_ANCHOR)
- Staleness violations

**Implementation:** `ECDSAPPSOracle._forwardValidEntries()` try-catch (line 249-283)  
**Location:** `src/oracles/ECDSAPPSOracle.sol`  
**Status:** ✓ Verified

**Architectural Trade-off:** Solidity's try-catch is binary:
- `revert` = catch block = nonces preserved
- `return`/`continue` = try success = nonces burn

All business logic rejections use `return`/`continue` to prevent batch DoS. This is the correct architectural trade-off.

---

### Property 4: Future Timestamp Rejection

**Formal Specification:**
```
∀ PPS update with timestamp T at current time C:
  T > C → MUST be rejected
  T ≤ C → may be accepted (if other checks pass)
```

**Implementation:** `forwardPPS()` line 237-243  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified

**Purpose:** Prevents validators from creating signatures with future timestamps that could be held and used later when conditions change.

**Attack Prevention:** Without this check, validators could sign PPS values with future timestamps during favorable market conditions, then submit them later when conditions are less favorable.

---

### Property 5: Pause Rejection

**Formal Specification:**
```
∀ strategy S:
  S.isPaused = true → ALL PPS updates rejected
  S.isPaused = false → may be accepted (if other checks pass)
```

**Implementation:** `forwardPPS()` line 247-254  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified

**Note:** Check is independent of payment settings. Paused strategies are always skipped early to save gas.

**Design Decision:** Moved outside payment check block to ensure paused strategies cannot receive updates even when payments are disabled.

---

### Property 6: Staleness Enforcement (Absolute Time)

**Formal Specification:**
```
∀ PPS updates with timestamp T at current time C:
  C - T > maxStaleness → MUST be rejected (continue; skips processing)
  C - T ≤ maxStaleness → may be accepted (if other checks pass)
```

**Implementation:** `forwardPPS()` line 258-266  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified (Fix Option A)

**Note:** Staleness check uses `continue` which means the function returns normally (no revert). From the oracle's perspective, the try block succeeds and nonces burn for the stale strategy. This is correct behavior to prevent replay of stale signatures.

**Defense-in-Depth:** Works in conjunction with Property 8 (Post-Unpause) to provide complete protection against stale PPS replay attacks.

---

### Property 7: Timestamp Monotonicity

**Formal Specification:**
```
∀ PPS updates (U1, U2) for strategy S:
  timestamp(U2) > timestamp(U1) → U2 may be accepted
  timestamp(U2) ≤ timestamp(U1) → U2 MUST be rejected
```

**Implementation:** `_forwardPPS()` line 1203-1210  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified

**Purpose:** Ensures timestamps are strictly increasing to prevent out-of-order updates. Guarantees that PPS updates reflect the true chronological order of market conditions.

**Attack Prevention:** Prevents attackers from replaying old (but valid) PPS values by ensuring each new update must have a timestamp greater than the previous.

---

### Property 8: Post-Unpause Timestamp Validation (C1-RE_ANCHOR)

**Formal Specification:**
```
∀ strategy S with lastUnpauseTimestamp U:
  U > 0 ∧ timestamp ≤ U → MUST be rejected
  timestamp > U → may be accepted (if other checks pass)
```

**Implementation:** `_forwardPPS()` line 1212-1222  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified (C1-RE_ANCHOR Fix)

**Purpose:** Prevents replay of pre-unpause signatures. After unpause, only accepts signatures timestamped AFTER the unpause event. Prevents stale signatures from pause period being replayed.

**Attack Scenario Prevented:**
```
Timeline:
T1 (Jan 2): Strategy operational, PPS = 100
T2 (Jan 3): Validators sign PPS = 105, signatures NOT submitted
T3 (Jan 4): Strategy PAUSED (security incident)
T4 (Feb 4): Strategy UNPAUSED (1 month later), real PPS should be 200
T5 (Feb 5): Attacker attempts to replay Jan 3 signatures

Without C1-RE_ANCHOR: Signatures would pass (nonce matches, monotonic check passes)
With C1-RE_ANCHOR: Rejected because T2 (Jan 3) ≤ T4 (Feb 4)
```

**Note:** Uses `return` (not `revert`) to allow batch processing to continue. Nonce burning is intentional for pre-unpause signatures.

---

### Property 9: Rate Limit Enforcement

**Formal Specification:**
```
∀ PPS update with timestamp T for strategy S:
  T - lastUpdate < minInterval ∧ !isPaused → MUST be rejected
  T - lastUpdate ≥ minInterval ∨ isPaused → may be accepted
```

**Implementation:** `_forwardPPS()` line 1222-1230  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified

**Purpose:** Enforces minimum time interval between updates to prevent spam. Allows immediate update after unpause (skip check if paused).

**Rate Limit Calculation:**
```solidity
uint256 minInterval = Math.min(
    _strategyData[args.strategy].minUpdateInterval,
    _strategyData[args.strategy].maxStaleness
);
```

Ensures `minInterval` never exceeds `maxStaleness` to prevent impossible update conditions.

---

### Property 10: Deviation Threshold (C1 Check)

**Formal Specification:**
```
∀ PPS update for strategy S with current PPS C:
  |newPPS - C| / C > deviationThreshold → check fails → auto-pause
  Check skipped if: threshold disabled, no previous PPS, or PPS marked stale
```

**Implementation:** `_forwardPPS()` line 1240-1259  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified

**Purpose:** Detects abnormal PPS deviations that may indicate data errors or extreme market conditions. Auto-pauses strategy and marks PPS stale on failure.

**Escape Hatch:** Check is skipped when PPS is already marked stale, allowing emergency updates during liquidation scenarios.

**Auto-Pause Behavior:**
```solidity
if (checksFailed && !_strategyData[args.strategy].isPaused) {
    _strategyData[args.strategy].isPaused = true;
    _strategyData[args.strategy].ppsStale = true;
    emit StrategyPaused(args.strategy);
    emit StrategyPPSStale(args.strategy);
}
```

---

### Property 11: M/N Threshold Validation (C2 Check)

**Formal Specification:**
```
∀ PPS update with M validators signed out of N total:
  M/N < mnThreshold → check fails → auto-pause
  M/N ≥ mnThreshold → check passes
```

**Implementation:** `_forwardPPS()` line 1255-1267  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified

**Purpose:** Ensures sufficient validator participation. Low participation may indicate consensus issues. Auto-pauses strategy and marks PPS stale on failure.

**Participation Calculation:**
```solidity
uint256 participationRate = Math.mulDiv(args.validatorSet, 1e18, args.totalValidators);
if (participationRate < _strategyData[args.strategy].mnThreshold) {
    checksFailed = true;
}
```

---

### Property 12: Upkeep Balance Check

**Formal Specification:**
```
∀ non-exempt PPS update:
  managerBalance < upkeepCost → rejected, auto-pause, mark stale
  managerBalance ≥ upkeepCost → accepted, cost deducted
```

**Implementation:** `_forwardPPS()` line 1277-1292  
**Location:** `src/SuperVault/SuperVaultAggregator.sol`  
**Status:** ✓ Verified

**Purpose:** Ensures strategy manager has sufficient upkeep balance to pay for oracle updates. Protects against continued operation without proper funding.

**Auto-Pause on Insufficient Balance:**
```solidity
if (managerUpkeepBalance < args.upkeepCost) {
    _strategyData[args.strategy].isPaused = true;
    _strategyData[args.strategy].ppsStale = true;
    emit StrategyPaused(args.strategy);
    emit StrategyPPSStale(args.strategy);
    emit InsufficientUpkeep(...);
    return;
}
```

---

### Property 13: Frontrunning Resistance

**Formal Specification:**
```
∀ attacker attempting to burn nonces without updating PPS:
  Most rejection paths require privileged access (manager, oracle)
  Main exploitable vector (rate limit) has medium economic cost ($12-30)
  Sustained attacks economically irrational ($4,320/day with no profit)
  Pre-flight validation by validators mitigates rate limit frontrunning
```

**Attack Vectors Analyzed:**
1. Rate limit frontrun: MEDIUM-LOW risk (exploitable but costly)
2. Strategy pause: LOW risk (requires manager role)
3. Upkeep drain: VERY LOW risk (requires oracle role)
4. Deviation trigger: LOW risk (self-defeating)
5. Staleness: NONE (attacker cannot delay victim transactions)
6. Timestamp non-monotonic: NONE (requires validator error)
7. C1-RE_ANCHOR: NONE (intended security feature)

**Implementation:** Enhanced monitoring + validator pre-flight checks recommended  
**Status:** ✓ Analyzed - MEDIUM-LOW overall risk, safe for production

**See:** `frontrunning_attack_analysis.md` for detailed economic and feasibility analysis.

---

## 4. Combined Defense-in-Depth

### Property 14: Complete Validation Chain

**All Checks in Order:**
```
For any PPS update to be accepted, it must pass ALL checks in order:

Oracle Layer (ECDSAPPSOracle):
  1. Quorum met (sufficient signatures)
  2. Signatures valid with correct nonce in digest (Property 1)
  3. All signers are registered validators

Aggregator Layer (SuperVaultAggregator.forwardPPS):
  4. Timestamp not in future (Property 4)
  5. Strategy not paused (Property 5)
  6. Timestamp not stale (Property 6, if payments enabled)

Strategy Layer (SuperVaultAggregator._forwardPPS):
  7. Timestamp monotonically increasing (Property 7)
  8. Timestamp after last unpause (Property 8, if ever paused)
  9. Within rate limit interval (Property 9, if not paused)
  10. Deviation within threshold (Property 10, if enabled)
  11. Sufficient validator participation (Property 11, if enabled)
  12. Sufficient upkeep balance (Property 12, if not exempt)

Post-Success (ECDSAPPSOracle._forwardValidEntries):
  13. Nonce increments (Property 2)
```

**Status:** ✓ Verified (all checks implemented in order)