# EVM Security Research: ValidatorBonding

## P0 - Critical Findings

### 1. Division by Zero in Slash
**Location:** `slash()` proportional calculation
**Pattern:** `slashFromUnbonding = amount * bond.unbondingAmount / bond.amount`
**Risk:** If `bond.amount == 0`, division by zero reverts unexpectedly
**Mitigation:** Early return or guard: `if (bond.amount == 0) revert NOTHING_TO_SLASH()`
**Ref:** vulnerabilities.md Section 3 (Arithmetic)

### 2. Front-Running executeUnbond Before Slash
**Pattern:** Operator sees pending slash tx in mempool, front-runs with `executeUnbond()` to extract unbonding funds before slash lands
**Risk:** Reduces effective slash amount; operator extracts funds that should have been slashed
**Mitigation Options:**
- a) Operator freeze: `GOVERNOR_ROLE` calls `freeze(operator)` to block `executeUnbond()` before slash
- b) Accept the risk at launch (5-10 validators, all KYB'd, low adversarial risk)
- c) Use private mempool / Flashbots Protect for slash transactions
**Recommendation:** Option (b) for V1 simplicity, document the limitation
**Precedent:** EigenLayer deallocation manipulation (2024), EigenYields slashing exploit

### 3. Status Transitions After Slash Below Minimum
**Scenario:** Operator has `amount = 1.5M`, `unbondingAmount = 0.5M`, gets slashed 600k.
- Post-slash: `amount = 900k` (below 1M minimum), `unbondingAmount = 300k`
- Spec says: status = `Unbonded`, removed from `_operators`
- **Issue:** `unbondingAmount` is still non-zero, but status is `Unbonded` and operator removed from registry
- What happens to the 300k unbonding amount? Is it stuck?
**Mitigation:** When slash drives below minimum → reset `unbondingAmount = 0`, `unbondingDeadline = 0`, `unbondingInitiator = address(0)`. The remaining `amount` (900k) can be recovered via `addBond()` (if status allows) or a new `bond()` after full withdrawal.
**Spec gap:** Need to define how residual unbonding amount is handled when status forced to Unbonded.

### 4. Zero-Amount Edge Cases
| Function | Zero Amount | Expected Behavior |
|----------|------------|-------------------|
| `bond()` | 0 | Revert (below minimumBond) |
| `addBond()` | 0 | Revert (`ZERO_AMOUNT`) |
| `requestUnbond()` | 0 | Revert (`ZERO_AMOUNT`) |
| `slash()` | 0 | Early return or revert |
**Mitigation:** Explicit `if (amount == 0) revert ZERO_AMOUNT()` on all amount-bearing functions

## P1 - Important Findings

### 5. addBond Cannot Recover Unbonded Status
**Gap:** If operator is slashed below minimum → status = `Unbonded` → `addBond()` requires `Bonded || Unbonding`
**Result:** Operator with residual bond after partial slash cannot top up via `addBond()`
**Fix:** Either:
- a) Allow `addBond()` for `Unbonded` status (if `bond.amount > 0`)
- b) Require full `bond()` cycle (withdraw remaining via `withdrawResidual()`, then fresh `bond()`)
**Recommendation:** Option (a) is simpler, add: `require(status == Bonded || status == Unbonding || (status == Unbonded && bond.amount > 0))`

### 6. Reentrancy via sUP Token Callbacks
**Current assumption:** sUP is standard ERC20 (no transfer hooks)
**Risk:** If sUP is ever upgraded to include hooks (ERC777, ERC4626), reentrancy possible
**Mitigation:** Add `ReentrancyGuard` (nonReentrant modifier) as defense-in-depth
**Cost:** ~2,100 gas per guarded function (cold SLOAD + SSTORE)

### 7. Math.mulDiv for Overflow-Safe Proportional Calculation
**Pattern:** `amount * bond.unbondingAmount / bond.amount` could overflow for large values
**Mitigation:** Use `Math.mulDiv(amount, bond.unbondingAmount, bond.amount)` from OZ
**Benefit:** Overflow-safe, rounds down by default, explicit rounding direction

## P2 - Moderate Findings

### 8. Parameter Bounds on Admin Functions
| Function | Missing Bound | Risk |
|----------|--------------|------|
| `setMinimumBond()` | No upper/lower bound | Could be set to 0 (no bonding required) or type(uint256).max (nobody can bond) |
| `setUnbondingPeriod()` | No upper bound | Could be set to years (funds locked forever) |
**Mitigation:** Add reasonable bounds, e.g., `minimumBond >= 1e18 && minimumBond <= 100_000_000e18`, `unbondingPeriod <= 365 days`

### 9. CEI Pattern Compliance
All state-changing functions must follow Checks-Effects-Interactions:
1. Validate inputs (checks)
2. Update storage (effects)
3. Transfer tokens (interactions)
**Specific concern:** `slash()` must update `bond.amount` and `bond.unbondingAmount` BEFORE calling `safeTransfer`

### 10. Event Ordering for Off-Chain Indexing
Events should be emitted AFTER state changes but BEFORE external calls (or at end of function if CEI is followed). This ensures indexers see consistent state.

## Exploit Precedents

| Protocol | Attack | Loss | Relevance |
|----------|--------|------|-----------|
| EigenLayer | Deallocation manipulation | N/A (found pre-exploit) | Unbonding front-run before slash |
| EigenYields | Slashing exploit | ~$1M | Proportional slash math errors |
| Lido CSM | Bonding module design | N/A (reference) | Similar operator/beneficiary separation |
| Rocket Pool | Node operator slash | N/A (reference) | Unbonding period + slash interaction |

## Recommended Security Patterns

1. **ReentrancyGuard** on all external functions (defense-in-depth)
2. **CEI pattern** strictly followed in all functions
3. **Math.mulDiv** for proportional slash calculation
4. **Explicit zero-amount checks** on all amount-bearing functions
5. **Zero-address validation** on all address parameters
6. **SafeERC20** for all token operations (even though sUP is standard)
7. **Event emission** after state changes for reliable indexing

## Fuzz Test Recommendations

1. **Proportional slash invariant:** `slashFromUnbonding + slashFromBonded == slashAmount` (no dust lost)
2. **Bond accounting invariant:** `sum(all bond.amounts) == token.balanceOf(contract)`
3. **Registry consistency:** Every address in `_operators` has status != `Unbonded`
4. **Unbonding math:** `bond.amount >= bond.unbondingAmount` always holds
5. **Slash cap:** Post-slash `bond.amount >= 0` (no underflow)
6. **Status transitions:** Only valid: Unbonded→Bonded, Bonded→Unbonding, Unbonding→Bonded, Unbonding→Unbonded, Bonded→Unbonded (via slash)
