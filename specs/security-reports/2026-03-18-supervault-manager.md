# Security Analysis Report

## Metadata
- **Target:** `src/SuperVault/SuperVaultManager.sol`, `src/interfaces/SuperVault/ISuperVaultManager.sol`
- **Mode:** review
- **Date:** 2026-03-18
- **Contract Types Detected:** Session key delegation / forwarding proxy for vault operations
- **Files Analyzed:** 2

## Summary
| Severity | Count | Blocks Merge |
|----------|-------|-------------|
| P0 Critical | 0 | Yes |
| P1 High | 0 | Yes |
| P2 Medium | 4 | No |
| P3 Low | 8 | No |

## Verdict
**PASS** - No P0 or P1 findings. Safe to proceed with recommended improvements.

> **Note on P1 findings from external research:** The research agent flagged registry poisoning (SuperGovernor compromise), parameter forwarding trust, and session key credential compromise as P1. These are **architectural trust assumptions** shared across the entire Superform system, not vulnerabilities specific to SuperVaultManager. SuperVaultManager correctly inherits the same trust model as all other contracts in the system. These are noted in the Attack Surface Summary below but do not block merge.

---

## P0 Findings (Critical)

None found.

## P1 Findings (High)

None found.

## P2 Findings (Medium)

### 1. ETH Refund Sends Entire Contract Balance, Not Caller's Overpayment

- **File:** `SuperVaultManager.sol:107`
- **SWC:** SWC-107
- **Category:** Reentrancy / ETH Handling
- **Description:** `executeHooks` refunds `address(this).balance` after the strategy call. Since `receive()` accepts ETH from anyone, stray ETH in the contract (accidental sends, self-destructs) would be claimed by the next `executeHooks` caller. Combined with the lack of a reentrancy guard, a malicious session key contract could re-enter during the refund callback.
- **Exploit Scenario:** Someone accidentally sends 10 ETH to the manager. Any session key holder calls `executeHooks` with `msg.value = 0` and claims all 10 ETH. With reentrancy, they could amplify this across strategies.
- **Vulnerable Code:**
  ```solidity
  uint256 remaining = address(this).balance;
  if (remaining > 0) {
      (bool success,) = msg.sender.call{ value: remaining }("");
  ```
- **Secure Pattern:**
  ```solidity
  // Track only the caller's overpayment
  uint256 balanceBefore = address(this).balance - msg.value;
  ISuperVaultStrategy(strategy).executeHooks{ value: msg.value }(args);
  uint256 refund = address(this).balance - balanceBefore;
  if (refund > 0) {
      (bool success,) = msg.sender.call{ value: refund }("");
      if (!success) revert ETH_REFUND_FAILED();
  }
  ```

### 2. Missing Reentrancy Guard on `executeHooks`

- **File:** `SuperVaultManager.sol:102`
- **SWC:** SWC-107
- **Category:** Reentrancy
- **Description:** `executeHooks` makes an external call to the strategy, then sends ETH to `msg.sender`. No `nonReentrant` modifier protects against callback re-entry. While the strategy's own `nonReentrant` prevents re-entering the same strategy, a malicious session key could re-enter targeting a different strategy.
- **Secure Pattern:** Add `ReentrancyGuard` from OpenZeppelin and apply `nonReentrant` to `executeHooks`.

### 3. Return Bomb Attack on ETH Refund

- **File:** `SuperVaultManager.sol:109`
- **SWC:** N/A
- **Category:** DoS / Gas
- **Description:** The low-level `.call{value: remaining}("")` to `msg.sender` copies all returndata into memory. A malicious session key contract could return enormous data in its `receive()`, causing memory expansion to consume all gas. The strategy call would have already succeeded, but the ETH refund would fail, leaving ETH stuck in the contract.
- **Secure Pattern:** Use assembly to avoid returndata copy:
  ```solidity
  assembly {
      let s := call(gas(), caller(), remaining, 0, 0, 0, 0)
      if iszero(s) { revert(0, 0) }
  }
  ```

### 4. Stale Session Keys Reactivate if Manager is Re-instated

- **File:** `SuperVaultManager.sol:193-200`
- **SWC:** N/A
- **Category:** Logic
- **Description:** When a primary manager changes (A -> B), session keys granted by A are logically invalidated because `isMainManager(A, strategy)` returns false. However, the key data remains in storage. If governance later re-instates A as primary manager (A -> B -> A), all previously granted session keys by A become valid again, even ones that were intended to be invalidated by the manager change.
- **Secure Pattern:** Document this behavior and require the re-instated manager to proactively revoke stale keys. Alternatively, add a per-strategy generation counter that increments on each manager change.

---

## P3 Findings (Low)

### 5. Open `receive()` Allows Unrecoverable ETH Accumulation

- **File:** `SuperVaultManager.sol:175`
- **Category:** ETH Handling
- **Description:** `receive()` accepts ETH from anyone. ETH sent outside `executeHooks` context has no recovery mechanism. Combined with Finding 1, this ETH is claimable by the next `executeHooks` caller.

### 6. Session Key Overwrite Without Existence Check

- **File:** `SuperVaultManager.sol:203-211`
- **Category:** Logic
- **Description:** `_grantSessionKey` silently overwrites existing keys. No maximum expiry cap exists -- a manager could set `expiry = type(uint256).max`. The `grantedByManager` invalidation provides a safety net, but a long expiry is still risky if the manager stays unchanged.

### 7. Revoking Non-existent Keys Emits Misleading Events

- **File:** `SuperVaultManager.sol:214-217`
- **Category:** Logic
- **Description:** `_revokeSessionKey` emits `SessionKeyRevoked` even for keys that were never granted, confusing off-chain monitoring.

### 8. Missing ETH Refund Event

- **File:** `SuperVaultManager.sol:107-111`
- **Category:** Best Practices
- **Description:** ETH refund transfer emits no event, making it untrackable off-chain.

### 9. `memory` Instead of `calldata` for `controllers` Parameter

- **File:** `SuperVaultManager.sol:115`, `ISuperVaultManager.sol:86`
- **Category:** Gas
- **Description:** `fulfillCancelRedeemRequests` uses `memory` for `controllers`. Using `calldata` saves gas on ABI decode.

### 10. Redundant `_getAggregator()` Calls in Batch Loops

- **File:** `SuperVaultManager.sol:73-76, 91-94`
- **Category:** Gas
- **Description:** `_validatePrimaryManager` calls `_getAggregator()` on every iteration (2 external calls per loop). Caching the aggregator before the loop saves `2*(n-1)` external calls.

### 11. Unbounded Batch Array Size

- **File:** `SuperVaultManager.sol:62-77, 86-95`
- **SWC:** SWC-128
- **Category:** DoS / Gas
- **Description:** No upper bound on batch size. Large arrays with external calls per iteration could exceed block gas limit.

### 12. `DEFAULT_ADMIN_ROLE` is Unused Post-Construction

- **File:** `SuperVaultManager.sol:48`
- **Category:** Access Control
- **Description:** `DEFAULT_ADMIN_ROLE` is granted but never checked in any function. Consider renouncing it or documenting its intended purpose.

---

## Attack Surface Summary

**External Entry Points:**
| Function | Auth | ETH | External Calls |
|----------|------|-----|----------------|
| `grantSessionKey` | Primary manager | No | `_getAggregator().isMainManager()` |
| `grantSessionKeysBatch` | Primary manager | No | `_getAggregator().isMainManager()` x N |
| `revokeSessionKey` | Primary manager | No | `_getAggregator().isMainManager()` |
| `revokeSessionKeysBatch` | Primary manager | No | `_getAggregator().isMainManager()` x N |
| `executeHooks` | Session key | Yes | `strategy.executeHooks()` + ETH refund |
| `fulfillCancelRedeemRequests` | Session key | No | `strategy.fulfillCancelRedeemRequests()` |
| `fulfillRedeemRequests` | Session key | No | `strategy.fulfillRedeemRequests()` |
| `skimPerformanceFee` | Session key | No | `strategy.skimPerformanceFee()` |
| `pauseStrategy` | Session key | No | `aggregator.pauseStrategy()` |
| `unpauseStrategy` | Session key | No | `aggregator.unpauseStrategy()` |
| `receive` | Anyone | Yes | None |

**Architectural Trust Assumptions:**
- SuperGovernor integrity (registry resolution)
- Aggregator `isMainManager()` correctness
- Strategy-level parameter validation for all forwarded calls
- Session key credential security (operational concern)

**Design Strengths:**
- Session keys are per-strategy scoped (cross-strategy isolation)
- Primary manager changes automatically invalidate all session keys
- Two-tier validation (expiry + manager liveness) prevents stale authorizations
- No upgradability (immutable deployment)

---

## Recommended Actions (Prioritized)

1. **Add `ReentrancyGuard` to `executeHooks`** - Defense in depth (Findings 1, 2)
2. **Track caller's overpayment instead of `address(this).balance`** - Prevents ETH misattribution (Finding 1)
3. **Use assembly for ETH refund** - Prevents return bomb (Finding 3)
4. **Emit event for ETH refunds** - Auditability (Finding 8)
5. **Document manager re-instatement behavior** - Risk awareness (Finding 4)
6. **Consider `calldata` for `controllers`** - Gas optimization (Finding 9)
7. **Cache `_getAggregator()` in batch loops** - Gas optimization (Finding 10)
