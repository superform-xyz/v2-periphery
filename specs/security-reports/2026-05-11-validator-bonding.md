# Security Analysis Report

## Metadata
- **Target:** `src/ValidatorBonding.sol`, `src/interfaces/IValidatorBonding.sol`
- **Mode:** review
- **Date:** 2026-05-11
- **Contract Types Detected:** General (staking/bonding with AccessControl)
- **Files Analyzed:** 2
- **Lines of Solidity:** ~529 (implementation) + ~357 (interface)

## Summary
| Severity | Count | Blocks Merge |
|----------|-------|-------------|
| P0 Critical | 0 | Yes |
| P1 High | 0 | Yes |
| P2 Medium | 4 | No |
| P3 Low | 6 | No |

## Verdict
**PASS** - No P0 or P1 findings. Safe to proceed with recommended fixes.

---

## P0 Findings (Critical - Must Fix)
None found.

## P1 Findings (High - Must Fix)
None found.

---

## P2 Findings (Medium - Should Fix)

### [P2-1] `executeUnbond()` sets status=Bonded without checking minimumBond

- **File:** `src/ValidatorBonding.sol:253-258`
- **SWC:** N/A
- **Category:** State Machine Logic
- **Description:** When `addBond()` is called during `Unbonding` status, it increases `bond_.amount` without resetting the unbond. After `executeUnbond()`, if the remaining amount (the added tokens) is less than `minimumBond`, the operator ends up with `status == Bonded` but `amount < minimumBond`. They remain in the `_operators` set despite `isBonded()` returning false -- an inconsistent state.
- **Exploit Scenario:** Operator bonds 100 sUP (minimum=50), requests full unbond, calls `addBond(10)` during unbonding. After `executeUnbond()`: amount=10, status=Bonded, but 10 < 50 minimumBond. Operator pollutes `_operators` set and `getOperators()`.
- **Vulnerable Code:**
```solidity
if (bond_.amount == 0) {
    bond_.status = ValidatorStatus.Unbonded;
    _operators.remove(operator);
} else {
    bond_.status = ValidatorStatus.Bonded; // no minimumBond check
}
```
- **Secure Pattern:**
```solidity
if (bond_.amount == 0) {
    bond_.status = ValidatorStatus.Unbonded;
    _operators.remove(operator);
} else if (bond_.amount >= minimumBond) {
    bond_.status = ValidatorStatus.Bonded;
} else {
    bond_.status = ValidatorStatus.Unbonded;
    _operators.remove(operator);
}
```

### [P2-2] Events emitted after external calls in `executeUnbond()` and `slash()`

- **File:** `src/ValidatorBonding.sol:261-263` and `src/ValidatorBonding.sol:338-340`
- **SWC:** N/A
- **Category:** CEI Pattern Violation
- **Description:** `emit UnbondExecuted` (line 263) and `emit Slashed` (line 340) are emitted after `safeTransfer` calls. While `nonReentrant` prevents exploitation, strict CEI ordering requires events (effects) before interactions. If the token has callbacks (ERC-777 style), the event order could mislead off-chain indexers.
- **Vulnerable Code:**
```solidity
// executeUnbond
SUP_TOKEN.safeTransfer(beneficiary, amount);
emit UnbondExecuted(operator, beneficiary, amount); // after interaction

// slash
SUP_TOKEN.safeTransfer(recipient, amount);
emit Slashed(operator, amount, recipient, bond_.amount); // after interaction
```
- **Secure Pattern:** Move `emit` statements before the `safeTransfer` calls.

### [P2-3] Front-running `slash()` with `executeUnbond()` to escape slashing

- **File:** `src/ValidatorBonding.sol:237-264` / `src/ValidatorBonding.sol:291-341`
- **SWC:** SWC-114
- **Category:** Front-running / MEV
- **Description:** If an operator's unbonding deadline has passed, they can front-run a pending `slash()` transaction with `executeUnbond()`, withdrawing tokens before the slash lands. The slash then reverts with `NOTHING_TO_SLASH()`.
- **Exploit Scenario:** Governor submits `slash(operator, fullAmount, treasury)`. Operator sees it in the mempool and front-runs with `executeUnbond(operator)`, withdrawing all tokens to beneficiary. Slash reverts.
- **Secure Pattern:** Operational mitigation: always slash before the unbonding deadline expires. For on-chain defense, consider using a private mempool for slash transactions on Base, or add a governor-callable "freeze" that temporarily blocks `executeUnbond()`.

### [P2-4] `setParameterTimelock()` takes effect instantly (no timelock on itself)

- **File:** `src/ValidatorBonding.sol:416-423`
- **SWC:** N/A
- **Category:** Timelock Bypass
- **Description:** A compromised admin can instantly reduce `parameterTimelock` to `MIN_PARAMETER_TIMELOCK` (1 day), then a compromised governor can push parameter changes in 24h. The contract documents this accepted risk (lines 19-24), relying on the admin multisig having >= 24h execution delay.
- **Vulnerable Code:**
```solidity
function setParameterTimelock(uint256 newTimelock) external onlyRole(DEFAULT_ADMIN_ROLE) {
    // ... instant effect
    parameterTimelock = newTimelock;
}
```
- **Secure Pattern:** Consider making `setParameterTimelock` itself timelocked (propose-then-execute), or use `AccessControlDefaultAdminRules` for 2-step admin with delay.

---

## P3 Findings (Low - Consider Fixing)

### [P3-1] Unsafe `uint48` cast without SafeCast

- **File:** `src/ValidatorBonding.sol:226`
- **SWC:** N/A
- **Category:** Arithmetic
- **Description:** `uint48(deadline)` silently truncates on overflow. While `uint48` max is year ~8.9M (no realistic risk), OpenZeppelin best practice is `SafeCast.toUint48()` which reverts on overflow instead of silently truncating.
- **Secure Pattern:** `bond_.unbondingDeadline = SafeCast.toUint48(deadline);`

### [P3-2] `bondFor()` beneficiary/delegateKey not pre-committed by operator

- **File:** `src/ValidatorBonding.sol:136-138`
- **SWC:** SWC-114
- **Category:** Front-running / MEV
- **Description:** The operator approves a bonder address but does not commit to `beneficiary` or `delegateKey`. A trusted-but-malicious bonder could set an unexpected beneficiary. Impact is limited because the bonder pays the tokens.
- **Secure Pattern:** Consider extending `approveBondFor` to include `beneficiary` and `delegateKey` parameters that the bonder must match.

### [P3-3] Permissionless `executeMinimumBondUpdate()` / `executeUnbondingPeriodUpdate()`

- **File:** `src/ValidatorBonding.sol:362-403`
- **SWC:** SWC-114
- **Category:** Front-running / MEV
- **Description:** Anyone can execute parameter updates after timelock. An MEV bot could time the execution unfavorably for operators. This is an accepted design tradeoff.

### [P3-4] `cancelUnbond()` restricted to initiator only

- **File:** `src/ValidatorBonding.sol:267-284`
- **SWC:** N/A
- **Category:** State Machine Logic
- **Description:** If the operator initiates unbond, the beneficiary cannot cancel (and vice versa). In the Foundation loan model, this means the operator can force an unbond that the Foundation cannot cancel (though tokens still go to the Foundation/beneficiary). The unbonding period serves as the detection window.
- **Secure Pattern:** Consider allowing both operator and beneficiary to cancel, or granting GOVERNOR_ROLE emergency cancel authority.

### [P3-5] No public getter for pending parameter changes

- **File:** `src/ValidatorBonding.sol:93-94`
- **SWC:** N/A
- **Category:** Observability
- **Description:** `_pendingValues` and `_pendingEffectiveTimes` are private with no public getter. Off-chain governance UIs and operators can only discover pending changes via events, not direct state queries.
- **Secure Pattern:** Add `getPendingChange(bytes32 key) returns (uint256 value, uint256 effectiveTime)`.

### [P3-6] `minimumBond` SLOAD in loop body of `getActiveOperators()`

- **File:** `src/ValidatorBonding.sol:456`
- **SWC:** N/A
- **Category:** Gas Optimization
- **Description:** `minimumBond` is read from storage on every loop iteration. Cache in a local variable.
- **Secure Pattern:**
```solidity
uint256 _minimumBond = minimumBond;
for (uint256 i; i < len; ++i) {
    // ... use _minimumBond instead of minimumBond
}
```

---

## Attack Surface Summary

- **External Entry Points:** `bond`, `bondFor`, `approveBondFor`, `revokeBondForApproval`, `addBond`, `updateDelegateKey`, `requestUnbond`, `executeUnbond`, `cancelUnbond`, `slash`, `proposeMinimumBond`, `executeMinimumBondUpdate`, `proposeUnbondingPeriod`, `executeUnbondingPeriodUpdate`, `cancelProposedChange`, `setParameterTimelock`
- **Value Transfer Points:** `safeTransferFrom` (bond/addBond), `safeTransfer` (executeUnbond, slash)
- **Oracle Dependencies:** None
- **Cross-Contract Interactions:** sUP token (ERC20 via SafeERC20)
- **Upgrade Mechanisms:** None (non-upgradeable)

## Coding Standards Findings
- CEI violation: 2 events after external calls (P2)
- Missing observability: no public getter for pending changes (P3)
- Gas: uncached SLOAD in loop (P3)
- NatSpec: generally thorough, minor improvements possible on `isBonded()` documentation

## Security Knowledge Sources
- **Vulnerability categories checked:** Reentrancy, Access Control, Arithmetic, Unchecked Returns, State Machine, DoS, Token Integration, Flash Loans, MEV, Timelock, Governance, Storage, Cross-function, Edge Cases
- **External references:** OWASP Smart Contract Top 10 2025, EigenLayer slashing findings, Balancer V2 rounding exploit, OpenZeppelin AccessControl docs, Lido V3 stVault patterns
- **Historical exploits cross-referenced:** EigenLayer queued withdrawal slash bug, Balancer $128M rounding error, industry $953M access control losses (2024)
