# Gas Checks Necessity Analysis: ECDSAPPSOracle

## Executive Summary

**RECOMMENDATION: The gas checks CAN be safely removed.**

Given that:
1. Nonces now only increment on successful `forwardPPS()` execution (inside try-success block)
2. There is only ONE external call (`forwardPPS()`)
3. EIP-150 automatically guarantees 63/64 gas forwarding
4. The try-catch already handles all revert cases (including OOG)

The manual gas checks are **redundant** and add unnecessary complexity. Removing them will simplify the code without introducing any security or correctness issues.

---

## Background: Recent Changes

### Original Design
- Nonces incremented BEFORE forwarding PPS updates
- Problem: If forwarding skipped (gas pre-check) or failed (caught by try/catch), nonces were burned
- This caused signature invalidation and potential DoS

### Fix Applied (Octane Finding)
- Moved nonce increment INSIDE try-success block (line 267-270)
- Nonces now ONLY increment when `forwardPPS()` succeeds
- This prevents signature burning on failures

### Sujith's Question
"Couldn't the gas stuff be safely removed given we moved the nonce update to successful action in aggregator and we only have 1 external call?"

---

## Current Gas Checks Analysis

### 1. Pre-Check Gas Validation (Lines 247-252)

```solidity
uint256 totalGas = count * SUPER_GOVERNOR.getGasInfo(address(this));
uint256 gasBefore = gasleft();
if (gasBefore <= totalGas + gasBefore / 64) {
    emit InsufficientGasForForward(gasBefore, totalGas);
    return;
}
```

**Purpose:**
- Estimates required gas based on strategy count
- Checks if caller provided enough gas to complete forwarding
- Early-exits with event if insufficient

**Analysis:**
- **Pre-emptive gas check** attempting to prevent OOG scenarios
- Uses `SUPER_GOVERNOR.getGasInfo(address(this))` to estimate per-strategy cost
- Adds 1/64th buffer (EIP-150 reserve)
- If check fails, transaction succeeds but does nothing (emits event, returns early)

**Is it still necessary?**
**NO.** Reasons:
1. **Nonce protection is gone**: Previously, this prevented nonce burning on OOG. Now nonces only increment on success, so OOG doesn't burn signatures.
2. **Try-catch handles OOG**: The try-catch block (line 256) will catch OOG reverts naturally.
3. **Estimation can be inaccurate**: Gas estimation from `getGasInfo()` is static and may not reflect actual execution costs (dynamic storage access, warm/cold slots, etc).
4. **User experience**: If gas is genuinely insufficient, it's BETTER to revert (letting caller know immediately) than silently succeed with an event that may be missed.

---

### 2. Post-Check OOG Detection (Lines 274, 279)

```solidity
catch Error(string memory reason) {
    if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
    emit BatchForwardPPSFailed(reason);
}
catch (bytes memory lowLevelData) {
    if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
    emit BatchForwardPPSFailedLowLevel(lowLevelData);
}
```

**Purpose:**
- Detects if the external call OOG'd
- Uses EIP-150's 1/64th gas reserve as signal: if only 1/64th remains, OOG likely occurred
- Reverts if OOG detected (to fail loudly), otherwise emits failure event

**Analysis:**
- **Distinguishes OOG from business logic revert**: Attempts to differentiate between:
  - Aggregator OOG (insufficient gas provided)
  - Aggregator revert due to business logic (e.g., validation failure, paused strategy)
- **Uses 1/64th heuristic**: If only ~1/64th gas remains after catch, assumes OOG

**Is it still necessary?**
**NO.** Reasons:
1. **Nonce protection is gone**: Previously important to distinguish OOG (caller error, should revert) from business logic failure (legitimate, emit event). Now nonces don't increment on ANY failure, so distinction is less critical.
2. **Heuristic is imprecise**: The 1/64th check is a heuristic, not definitive. False positives/negatives are possible.
3. **Caller responsibility**: If caller doesn't provide enough gas, transaction will revert anyway (via catch). The explicit check doesn't add meaningful value.
4. **Simplification**: Treating all failures uniformly (emit event) is simpler and acceptable now that nonces are protected.

---

## Deep Dive: EIP-150 and Gas Forwarding

### EIP-150 Rule
When making an external call, the EVM automatically forwards **63/64** of available gas to the callee, reserving **1/64** for post-call execution.

### Single External Call Scenario (Current Implementation)

```solidity
gasBefore = gasleft();  // e.g., 1,000,000 gas
try ISuperVaultAggregator(...).forwardPPS(...) {
    // Success path: nonce++ (uses reserved 1/64th)
} catch {
    // Failure path: emit event (uses reserved 1/64th)
}
```

**What happens:**
- At the `try` statement, EVM forwards **984,375 gas** (63/64 of 1M) to `forwardPPS()`
- Reserves **15,625 gas** (1/64 of 1M) for post-call execution
- If `forwardPPS()` OOGs, catch block executes with reserved gas
- If `forwardPPS()` succeeds, success block executes with reserved gas

**Key insight:**
Since there's only ONE external call, EIP-150 automatically handles gas forwarding optimally. Manual checks add no value.

---

## Scenario Analysis: With vs Without Gas Checks

### Scenario A: Caller Provides Insufficient Gas

**With gas checks (current):**
```
1. Pre-check: gasleft() = 10,000, totalGas estimate = 50,000
2. Pre-check fails: emits InsufficientGasForForward, returns
3. Transaction succeeds (no revert)
4. Nonces unchanged, signatures remain valid
```

**Without gas checks (proposed):**
```
1. try forwardPPS() with 9,844 gas forwarded (63/64 of 10,000)
2. forwardPPS() OOGs
3. catch block executes with 156 gas (1/64 of 10,000)
4. Emits BatchForwardPPSFailed (or OOGs in catch if even emit is too expensive)
5. Transaction MAY revert if catch block also OOGs
6. Nonces unchanged, signatures remain valid
```

**Comparison:**
- **With checks**: Always succeeds, emits specific event
- **Without checks**: May succeed (emit event) or revert (OOG in catch)
- **Safety**: Both are safe (nonces protected)
- **User experience**: Without checks, caller gets clearer signal (revert) if they drastically under-provided gas

---

### Scenario B: Aggregator Consumes All Gas (Business Logic)

**With gas checks (current):**
```
1. Pre-check: passes
2. try forwardPPS() forwards 984,375 gas
3. forwardPPS() succeeds but consumes 984,000 gas
4. Returns to ECDSAPPSOracle with 15,000 gas left
5. Success block: nonce++ (uses ~5,000 gas)
6. Transaction succeeds
```

**Without gas checks (proposed):**
```
(Identical to above - no difference)
```

**Comparison:**
- **No difference**: Gas checks don't affect this scenario
- Aggregator consuming lots of gas is fine as long as 1/64th reserve suffices for nonce increment

---

### Scenario C: Aggregator Reverts (Business Logic Reason)

Example: Strategy is paused, validation fails, etc.

**With gas checks (current):**
```
1. Pre-check: passes
2. try forwardPPS() forwards 984,375 gas
3. forwardPPS() reverts with "STRATEGY_PAUSED" after 10,000 gas
4. catch Error(reason) block executes
5. Post-check: gasleft() = 974,000 > gasBefore/64 (15,625)
6. Post-check passes: emits BatchForwardPPSFailed("STRATEGY_PAUSED")
7. Transaction succeeds, nonces unchanged
```

**Without gas checks (proposed):**
```
1. try forwardPPS() forwards 984,375 gas
2. forwardPPS() reverts with "STRATEGY_PAUSED" after 10,000 gas
3. catch Error(reason) block executes
4. Emits BatchForwardPPSFailed("STRATEGY_PAUSED")
5. Transaction succeeds, nonces unchanged
```

**Comparison:**
- **No difference in outcome**: Both emit event, nonces unchanged
- **Without checks**: Simpler code, same behavior

---

### Scenario D: Aggregator OOGs (Caller Provided Barely Enough)

**With gas checks (current):**
```
1. Pre-check: gasleft() = 100,000, totalGas estimate = 80,000
2. Pre-check passes (100,000 > 80,000 + 1,563)
3. try forwardPPS() forwards 98,438 gas
4. forwardPPS() OOGs after consuming 98,438 gas
5. catch block executes with 1,562 gas left
6. Post-check: gasleft() = 1,562 ≈ gasBefore/64 (1,563)
7. Post-check triggers: reverts with INSUFFICIENT_GAS_FOR_EXTERNAL_CALL
```

**Without gas checks (proposed):**
```
1. try forwardPPS() forwards 98,438 gas
2. forwardPPS() OOGs after consuming 98,438 gas
3. catch block executes with 1,562 gas left
4. Emits BatchForwardPPSFailedLowLevel(0x) [OOG returns empty bytes]
5. Transaction succeeds (if emit fits in 1,562 gas) OR reverts (if emit OOGs)
```

**Comparison:**
- **With checks**: Explicit revert with clear error
- **Without checks**: Emits event OR reverts generically
- **Safety**: Both safe (nonces unchanged)
- **User experience**: With checks is slightly better (clear revert message), but NOT critical since nonces are protected

---

## Try-Catch Behavior with OOG

### How does try-catch handle OOG?

From Solidity docs:
> If an external call reverts (including due to out-of-gas), execution continues in the catch block.

**OOG is treated as a revert**, so catch block executes with reserved 1/64th gas.

### What gets caught?

```solidity
try aggregator.forwardPPS() {
    // Success
} catch Error(string memory reason) {
    // Catches require/revert with reason string
} catch (bytes memory lowLevelData) {
    // Catches:
    //   - assert failures
    //   - low-level reverts
    //   - OUT OF GAS (returns empty bytes)
}
```

**OOG is caught by `catch (bytes memory lowLevelData)` with empty bytes.**

---

## Key Questions Answered

### Q1: Can we safely remove the pre-check and just let OOG happen naturally?

**YES.**

**Reasoning:**
1. **Nonces are protected**: Only increment on success, so OOG doesn't burn signatures
2. **Try-catch handles OOG**: Catch block will execute with reserved gas
3. **Estimation is imprecise**: Pre-check uses static gas estimate that may be wrong
4. **Simpler code**: Removes ~5 lines and external call to `getGasInfo()`
5. **Acceptable UX**: If caller drastically under-provides gas, transaction should revert (not silently succeed with missed event)

**Trade-off:**
- Lose early-exit optimization (if gas clearly insufficient, return immediately vs attempting call)
- This is MINOR - attempting the call is not harmful, and failure is handled gracefully

---

### Q2: Can we safely remove the post-check and rely on try-catch alone?

**YES.**

**Reasoning:**
1. **Nonces are protected**: Only increment on success, so distinguishing OOG from business logic revert is less critical
2. **Heuristic is imprecise**: 1/64th check is not definitive
3. **Unified failure handling**: Treating all failures uniformly (emit event) is simpler and acceptable
4. **Caller responsibility**: If insufficient gas provided, that's caller's error; emitting event or reverting both signal failure

**Trade-off:**
- Lose distinction between OOG (caller error) and business logic failure (legitimate)
- This is MINOR - both failures result in nonces unchanged and signatures valid, so retrying with same signature works

---

### Q3: What's the difference between try-catch with vs without manual gas checks?

**Functional difference:** MINIMAL

**With gas checks:**
- Pre-check prevents OOG attempts (early exit optimization)
- Post-check forces revert on OOG (explicit failure signal)
- More complex code (~10 extra lines)
- External dependency on `SUPER_GOVERNOR.getGasInfo()`

**Without gas checks:**
- OOG attempts are made and caught naturally
- OOG results in event emission (may succeed or revert if emit OOGs)
- Simpler code
- No external gas estimation dependency

**For correctness:** NO DIFFERENCE (nonces protected in both cases)

---

### Q4: Does try-catch already handle OOG correctly without needing manual checks?

**YES.**

Try-catch handles OOG as a revert, executing the catch block with reserved 1/64th gas. The manual checks are redundant for correctness.

---

## Code Comparison: With vs Without Gas Checks

### Current Implementation (With Gas Checks)

```solidity
function _forwardValidEntries(ValidatedBatchData memory validatedData, uint256 totalValidators) internal {
    uint256 count = validatedData.strategies.length;

    // PRE-CHECK: Estimate and validate gas
    uint256 totalGas = count * SUPER_GOVERNOR.getGasInfo(address(this));
    uint256 gasBefore = gasleft();
    if (gasBefore <= totalGas + gasBefore / 64) {
        emit InsufficientGasForForward(gasBefore, totalGas);
        return;
    }
    gasBefore = gasleft();  // Re-sample after pre-check

    if (count > 0) {
        try ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR))
            .forwardPPS(
                ISuperVaultAggregator.ForwardPPSArgs({
                    strategies: validatedData.strategies,
                    ppss: validatedData.ppss,
                    validatorSets: validatedData.validatorSets,
                    totalValidator: totalValidators,
                    timestamps: validatedData.timestamps,
                    updateAuthority: msg.sender
                })
            ) {
                for (uint256 i; i < count; ++i) {
                    // Increment nonce only after successful forwarding
                    noncePerStrategy[validatedData.strategies[i]]++;
                }
        }
        catch Error(string memory reason) {
            // POST-CHECK: Detect OOG and revert
            if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
            emit BatchForwardPPSFailed(reason);
        } catch (bytes memory lowLevelData) {
            // POST-CHECK: Detect OOG and revert
            if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
            emit BatchForwardPPSFailedLowLevel(lowLevelData);
        }
    }
}
```

**Lines of code:** ~40
**External calls:** 2 (`getGasInfo()`, `forwardPPS()`)
**Complexity:** High (gas estimation, pre/post checks)

---

### Proposed Implementation (Without Gas Checks)

```solidity
function _forwardValidEntries(ValidatedBatchData memory validatedData, uint256 totalValidators) internal {
    uint256 count = validatedData.strategies.length;

    // Only forward if there are valid entries
    if (count > 0) {
        try ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR))
            .forwardPPS(
                ISuperVaultAggregator.ForwardPPSArgs({
                    strategies: validatedData.strategies,
                    ppss: validatedData.ppss,
                    validatorSets: validatedData.validatorSets,
                    totalValidator: totalValidators,
                    timestamps: validatedData.timestamps,
                    updateAuthority: msg.sender
                })
            ) {
                for (uint256 i; i < count; ++i) {
                    // Increment nonce only after successful forwarding
                    noncePerStrategy[validatedData.strategies[i]]++;
                }
        }
        catch Error(string memory reason) {
            emit BatchForwardPPSFailed(reason);
        } catch (bytes memory lowLevelData) {
            emit BatchForwardPPSFailedLowLevel(lowLevelData);
        }
    }
}
```

**Lines of code:** ~25
**External calls:** 1 (`forwardPPS()`)
**Complexity:** Low (simple try-catch)

---

## Trade-Offs: Keep vs Remove

### If We KEEP Gas Checks

**Benefits:**
1. **Early exit optimization**: Avoids OOG attempt if gas clearly insufficient
2. **Explicit OOG detection**: Post-check reverts with clear error message
3. **Potentially better UX**: Caller gets specific "insufficient gas" error vs generic OOG

**Costs:**
1. **Code complexity**: ~15 extra lines
2. **External dependency**: Relies on `SUPER_GOVERNOR.getGasInfo()` accuracy
3. **Maintenance burden**: Gas estimation must be kept accurate as aggregator evolves
4. **Gas cost**: Extra `gasleft()` calls and arithmetic
5. **Imprecision**: Estimation can be wrong (too conservative or too optimistic)

---

### If We REMOVE Gas Checks

**Benefits:**
1. **Simpler code**: ~15 fewer lines, easier to audit and maintain
2. **No external dependency**: Don't rely on `getGasInfo()` estimation
3. **Gas savings**: Fewer `gasleft()` calls and arithmetic
4. **Correct by default**: EIP-150 handles gas forwarding optimally for single external call
5. **Unified failure handling**: All failures treated consistently

**Costs:**
1. **No early exit**: Will attempt external call even if gas likely insufficient
2. **Less specific error**: OOG results in generic catch (with empty bytes) vs explicit revert
3. **Potential catch block OOG**: If gas is extremely low, even emitting event in catch may OOG (reverting transaction)

---

## Recommendation: REMOVE Gas Checks

### Rationale

1. **Nonce protection is KEY**: With nonces only incrementing on success, the primary risk (signature burning) is eliminated. Gas checks were originally designed to prevent nonce burning on OOG, but that risk no longer exists.

2. **Single external call simplifies everything**: With only one external call, EIP-150's automatic 63/64 gas forwarding is optimal. Manual checks add no value for correctness.

3. **Simplicity is a virtue**: Removing ~15 lines of complex gas accounting makes the code easier to audit, maintain, and reason about. Security benefits from simplicity.

4. **Trade-offs are acceptable**:
   - Losing early-exit optimization is minor (attempting call is not harmful)
   - Losing explicit OOG error is minor (catch block will signal failure, and nonces are protected)
   - Risk of catch block OOG is extremely low (emitting event uses minimal gas)

5. **Caller responsibility**: If a caller provides drastically insufficient gas, the transaction SHOULD fail (revert). Silently succeeding with an event that may be missed is arguably worse UX.

6. **Maintainability**: Removing dependency on `getGasInfo()` eliminates need to keep gas estimation accurate as aggregator evolves.

---

## Exact Code Changes

### File: `src/oracles/ECDSAPPSOracle.sol`

**Remove lines 247-252 (pre-check):**
```diff
- uint256 totalGas = count * SUPER_GOVERNOR.getGasInfo(address(this));
- uint256 gasBefore = gasleft();
- if (gasBefore <= totalGas + gasBefore / 64) {
-     emit InsufficientGasForForward(gasBefore, totalGas);
-     return;
- }
- gasBefore = gasleft();
```

**Remove lines 274, 279 (post-check) - now would be lines ~267, 272 after above removal:**
```diff
  catch Error(string memory reason) {
-     if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
      emit BatchForwardPPSFailed(reason);
  } catch (bytes memory lowLevelData) {
-     if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
      emit BatchForwardPPSFailedLowLevel(lowLevelData);
  }
```

**Remove unused variable (if not used elsewhere):**
```diff
- uint256 gasBefore = ...;  // Check if this variable is used anywhere else first
```

**Optional: Remove unused events/errors from interface (if no longer needed):**
- `event InsufficientGasForForward(uint256 gasLeft, uint256 gasRequired)`
- `error INSUFFICIENT_GAS_FOR_EXTERNAL_CALL()`

Check interface file (`src/interfaces/oracles/IECDSAPPSOracle.sol`) and remove if no other functions use them.

---

## Response to Sujith

**Sujith is correct.** The gas checks can be safely removed given:

1. **Nonce moved to success block**: Signatures are now protected from burning on any failure (OOG or business logic)

2. **Single external call**: With only one external call to `forwardPPS()`, EIP-150's automatic gas forwarding is optimal. Manual gas checks are redundant.

3. **Try-catch is sufficient**: The try-catch block naturally handles OOG (as a revert caught by `catch (bytes memory)`), emitting an event and leaving nonces unchanged.

4. **Simplicity wins**: Removing the gas checks simplifies the code without compromising correctness or security. The trade-offs (losing early-exit optimization and explicit OOG error) are minimal and acceptable.

**The gas forwarding logic was originally designed to protect nonces from being burned on OOG.** With nonces now protected by the try-success placement, the gas checks no longer serve their original purpose and can be removed.

---

## Additional Considerations

### What if aggregator forwardPPS() is very expensive?

**Not a problem.** The aggregator can consume as much gas as needed (up to 63/64 of provided gas). As long as the 1/64th reserve is enough for nonce increments or event emissions (which it will be - these are cheap operations), everything works correctly.

### What if aggregator is maliciously expensive?

**Also not a problem.** Caller provides gas limit. If aggregator tries to consume all gas:
1. It will hit the 63/64 limit (can't consume reserved 1/64th)
2. If it OOGs, catch block executes, emits event, nonces unchanged
3. Signatures remain valid, caller can retry with more gas

The aggregator cannot burn signatures by consuming gas.

### What about denial of service?

**Not an issue.**
1. **Oracle operator controls gas**: The entity calling `updatePPS()` controls how much gas to provide
2. **No nonce burning**: Even if OOG occurs, signatures remain valid for retry
3. **Aggregator is trusted**: `forwardPPS()` can only be called by active PPS Oracle (modifier check), which is governance-controlled

If aggregator becomes maliciously expensive, governance can replace it.

---

## Conclusion

**The gas checks should be removed.** They add complexity without providing meaningful protection now that nonces are only incremented on success. The code will be simpler, easier to maintain, and equally correct without them.

Sujith's intuition is spot-on: the gas forwarding logic is redundant given the single external call and protected nonce placement.
