# SpecFlow Analysis: ValidatorBonding

## Critical Gaps (Must Resolve Before Implementation)

### Gap 1: addBond Cannot Recover from Unbonded Status
**Flow:** Operator slashed below minimum → status = `Unbonded` → `addBond()` requires `Bonded || Unbonding`
**Impact:** Operator with residual bond (e.g., 900k after partial slash) cannot top up to re-meet minimum
**Resolution:** Allow `addBond()` when `status == Unbonded && bond.amount > 0`. This enables recovery path without requiring full unbond + re-bond cycle. Add status transition: if `addBond()` brings `amount >= minimumBond`, set status = `Bonded` and re-add to `_operators`.

### Gap 2: Residual Unbonding Amount After Slash Below Minimum
**Flow:** Operator has pending unbond, gets slashed below minimum → status forced to `Unbonded`
**Impact:** `unbondingAmount` > 0 but status = `Unbonded`. What can operator do?
**Resolution:** When slash forces status to `Unbonded`, reset unbonding state: `unbondingAmount = 0`, `unbondingDeadline = 0`, `unbondingInitiator = address(0)`. The full remaining `amount` is treated as bonded (available for withdrawal via new mechanism or `addBond()` recovery).

### Gap 3: No Withdrawal Path for Sub-Minimum Residual
**Flow:** After partial slash, operator has 900k sUP (below 1M minimum) and status = `Unbonded`
**Impact:** Cannot `requestUnbond()` (requires Bonded/Unbonding), cannot `addBond()` (Gap 1)
**Resolution:** Two options:
- a) Add `withdrawResidual()` function for `Unbonded` operators with `amount > 0`
- b) Fix Gap 1 (allow `addBond()` for Unbonded) AND allow `requestUnbond()` for Unbonded with `amount > 0`
**Recommendation:** Option (b) — allow `requestUnbond()` for Unbonded operators with residual bond

### Gap 4: Atomic Slash + Removal Mechanism
**Spec says:** SuperGovernor multicall batches `slash()` + `setValidatorConfig()`
**Reality:** SuperGovernor.sol has no `multicall()` function
**Resolution:** Relies on Safe multisig transaction batching (Safe supports batched calls natively). Document this clearly — the atomicity comes from the Safe, not SuperGovernor.

### Gap 5: GOVERNOR_ROLE Assignment
**Spec says:** `GOVERNOR_ROLE` = SuperGovernor address
**Reality:** SuperGovernor is the contract, but `GOVERNOR_ROLE` is typically granted to the `governor` EOA/multisig within SuperGovernor
**Resolution:** `GOVERNOR_ROLE` in ValidatorBonding should be granted to the SuperGovernor contract address. SuperGovernor then needs a function to call `ValidatorBonding.slash()` — either a direct wrapper or via the Safe batching the call through SuperGovernor's execute function.

## Important Gaps

### Gap 6: executeUnbond Access Control
**Spec says:** Callable by operator OR beneficiary
**Question:** Should it be permissionless after deadline? (Anyone can trigger withdrawal to beneficiary)
**Resolution:** Keep restricted to operator/beneficiary. Permissionless execution adds no value and could cause tax/accounting issues for beneficiary.

### Gap 7: Parameter Bounds
| Parameter | Current | Recommended Bounds |
|-----------|---------|-------------------|
| minimumBond | No bounds | `>= 1e18`, `<= 100_000_000e18` |
| unbondingPeriod | No bounds | `>= 1 day`, `<= 365 days` |
**Resolution:** Add bounds checks in setter functions.

### Gap 8: Constructor vs Init Params
**Design:** Non-upgradeable, so constructor sets immutables
**Needed in constructor:** `sUP token address`, `minimumBond`, `unbondingPeriod`, `admin`, `governor`
**Note:** `minimumBond` and `unbondingPeriod` are mutable (governance-settable), only `SUP_TOKEN` is immutable.

### Gap 9: Re-bonding After Full Slash
**Flow:** Operator fully slashed (amount = 0) → status = `Unbonded`, all fields reset → can `bond()` again
**Question:** Should fully slashed operators be blocked from re-bonding?
**Resolution:** No on-chain block. Re-bonding requires `bond()` (permissionless) + being added to `setValidatorConfig()` (permissioned). The governance gating via `setValidatorConfig()` is sufficient.

### Gap 10: Slash Event Should Include Post-Slash State
**Current:** `Slashed(operator, amount, recipient)`
**Better:** Include `remainingBond` and `newStatus` for off-chain indexing:
`Slashed(operator, amount, recipient, remainingBond)`

## Minor Gaps

### Gap 11: delegateKey Validation
- Not enforced for uniqueness on-chain (documented)
- Should still validate != address(0)
- Should validate != operator address? (Debatable — no security risk)

### Gap 12: Bond Record Struct Packing
Current struct uses 7 fields across multiple storage slots. Optimization possible:
```
Slot 1: amount (256 bits)
Slot 2: beneficiary (160) + status (8) + unbondingInitiator portion
Slot 3: delegateKey (160) + remaining bits
Slot 4: unbondingDeadline (64) + unbondingAmount (192 would overflow, need 256)
```
At 5-10 validators, gas optimization is not critical. Prioritize readability.

### Gap 13: View Function for Checking Unbonding Status
Add: `isUnbonding(address operator) returns (bool)` — useful for off-chain tooling

### Gap 14: Beneficiary Can Be a Contract
If beneficiary is a contract without `receive()`, sUP transfer in `executeUnbond()` could fail (but sUP is ERC20, not ETH, so this is fine — ERC20 transfers don't require `receive()`).

## User Flow Summary

### Happy Path: Self-Bond
1. Validator calls `bond(1_000_000e18, validatorAddr, delegateKey)`
2. Governance adds validator to oracle set via `setValidatorConfig()`
3. Validator operates, signs PPS updates
4. Validator calls `requestUnbond(1_000_000e18)` — full unbond
5. Wait 7 days
6. Validator calls `executeUnbond()` — sUP returned to validator

### Happy Path: Foundation Loan
1. Foundation calls `bondFor(operatorAddr, 1_000_000e18, foundationMultisig, delegateKey)`
2. Governance adds operator to oracle set
3. Operator runs validator using delegateKey
4. Foundation calls `requestUnbond(1_000_000e18)` — pulling back loan
5. Wait 7 days
6. Foundation calls `executeUnbond()` — sUP returned to Foundation

### Slash Path
1. Validator submits bad PPS
2. Team investigates off-chain
3. Safe batches: `ValidatorBonding.slash(operator, slashAmount, treasury)` + `setValidatorConfig(newSet)`
4. Slash and removal happen atomically in one tx
5. Slashed sUP goes to treasury

### Recovery After Partial Slash
1. Operator slashed from 1.5M to 900k → status = `Unbonded`
2. Operator calls `addBond(200_000e18)` — total now 1.1M (>= minimum)
3. Status transitions to `Bonded`, re-added to `_operators`
4. Governance re-adds to `setValidatorConfig()` if appropriate
