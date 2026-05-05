# Security Analysis Report: SuperVaultExecutor

## Metadata
- **Target:** `src/SuperVault/SuperVaultExecutor.sol`
- **Mode:** review (3-agent parallel analysis)
- **Date:** 2026-04-17
- **Contract Types Detected:** ERC-4337 v0.7 IAccount, Session Key Manager, Delegation Forwarder, OpenZeppelin AccessControl
- **Files Analyzed:** 2 (SuperVaultExecutor.sol, ISuperVaultExecutor.sol)
- **Agents:** Vulnerability Scanner, Best Practices Reviewer, EVM Security Researcher

## Summary

| Severity | Count | Blocks Merge |
|----------|-------|-------------|
| P0 Critical | 0 | — |
| P1 High | 1 | Yes |
| P2 Medium | 2 | No |
| P3 Low | 6 | No |

## Verdict

**CONDITIONAL PASS** — 1 P1 finding is a documented design limitation requiring cross-contract changes (SuperVaultAggregator). No exploitable P0 bugs found. The P1 has a manual mitigation path (`invalidateAllSessionKeys`). P2/P3 findings are advisory.

---

## P0 Critical

None found.

---

## P1 High

### [P1-1] Session Key Reactivation on Manager Reinstatement

- **File:** `SuperVaultExecutor.sol:83-87` (documented), `:381-397` (code)
- **SWC:** N/A
- **Category:** Access Control

**Description:**
Session key validity depends on the granting manager remaining the primary manager via `_isSessionKeyValidForPermission` (line 395: `_getAggregator().isMainManager(data.grantedByManager, strategy)`). If manager A grants session keys, then is replaced by manager B, the keys become invalid. However, if A is later reinstated as primary manager, all previously-granted session keys silently reactivate — including keys intended to be permanently revoked via the manager change. The generation counter does NOT auto-increment on manager transitions.

The contract documents this risk (lines 83-87) and recommends calling `invalidateAllSessionKeys()` during the interim, but this is a manual operational procedure — not enforced in code.

**Exploit Scenario:**
Manager A grants a session key to operator X with ExecuteHooks permission. Manager A is replaced by B (all of A's keys are invalidated). Later, governance reinstates A as primary manager. Operator X's key silently reactivates without re-authorization.

**Vulnerable Code:**
```solidity
// Line 395 — Only checks current manager status, no generation bump on manager change
if (!_getAggregator().isMainManager(data.grantedByManager, strategy)) return (false, 0);
```

**Secure Pattern:**
Automatically bump the strategy generation when the primary manager changes. This requires a callback from SuperVaultAggregator:
```solidity
// In SuperVaultAggregator.changePrimaryManager (or via a hook):
ISuperVaultExecutor(executor).invalidateAllSessionKeys(strategy);
```

**References:**
- Contract WARNING comment lines 83-87
- Trail of Bits: "Six mistakes in ERC-4337 smart accounts"
- Openfort: "Smart Wallet Security Best Practices 2026"

---

## P2 Medium

### [P2-1] `missingAccountFunds` Not Handled in `validateUserOp`

- **File:** `SuperVaultExecutor.sol:213-246`
- **SWC:** N/A
- **Category:** Logic (ERC-4337 Compliance)

**Description:**
The ERC-4337 spec requires `validateUserOp` to transfer `missingAccountFunds` to the EntryPoint when non-zero. The contract ignores this parameter entirely. The interface NatSpec states "Always 0 when a paymaster is used," indicating this is by design — the contract assumes a paymaster is always present.

If the contract is ever used without a paymaster (e.g., paymaster rejects a UserOp, or protocol switches to self-funded mode), the EntryPoint will pass a non-zero `missingAccountFunds`. The contract won't pre-fund, causing the UserOp to revert.

**Vulnerable Code:**
```solidity
function validateUserOp(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash,
    uint256 missingAccountFunds  // completely ignored
)
```

**Secure Pattern:**
Either handle the pre-funding or explicitly document/enforce the paymaster-only constraint:
```solidity
// Option A: Handle pre-funding
if (missingAccountFunds > 0) {
    assembly {
        pop(call(gas(), caller(), missingAccountFunds, 0, 0, 0, 0))
    }
}

// Option B: Explicitly require paymaster (in validateUserOp)
// Already handled by operational assumption — document prominently
```

**References:**
- ERC-4337 specification: "The account SHOULD pay `missingAccountFunds`"
- aviggiano/security: ERC-4337 Audit Checklist

---

### [P2-2] Unbounded Gas Forwarding in ETH Refund (`_executeHooksInternal`)

- **File:** `SuperVaultExecutor.sol:367-368`
- **SWC:** SWC-126 (Insufficient Gas Griefing)
- **Category:** DoS / Consistency

**Description:**
The contract has two ETH transfer patterns with inconsistent gas forwarding:
- `sweepETH` (line 275): `call(100000, to, bal, 0, 0, 0, 0)` — capped at 100k gas
- `_executeHooksInternal` (line 368): `call(gas(), refundRecipient, refund, 0, 0, 0, 0)` — all remaining gas

When `executeHooks` is called directly, `refundRecipient` is `msg.sender`. A malicious contract with an expensive `receive()` could consume excessive gas. While `nonReentrant` prevents reentrancy, forwarding all gas is inconsistent with the `sweepETH` defensive pattern.

When called via `executeFromEntryPoint`, the refund goes to `address(this)` which is safe.

**Vulnerable Code:**
```solidity
// Line 367-368: forwards all remaining gas
assembly {
    success := call(gas(), refundRecipient, refund, 0, 0, 0, 0)
}
```

**Secure Pattern:**
Cap the gas consistently:
```solidity
assembly {
    success := call(100000, refundRecipient, refund, 0, 0, 0, 0)
}
```

**References:**
- pcaversaccio: Return Bomb Attack patterns
- SWC-126: Insufficient Gas Griefing

---

## P3 Low

### [P3-1] TOCTOU: Validate-Execute Separation in ERC-4337

- **File:** `SuperVaultExecutor.sol:213-261`
- **Category:** Logic (ERC-4337 Inherent)

**Description:**
Between `validateUserOp` and `executeFromEntryPoint`, state can change (session key revoked, generation bumped, manager changed). The `executeFromEntryPoint` function does NOT re-validate. This is inherent to ERC-4337's design — all validations run before all executions within a single `handleOps` transaction. The window is extremely narrow (within a single bundle), and cross-UserOp interference requires multiple UserOps in the same bundle targeting the same strategy.

**References:** Trail of Bits, Project Eleven EntryPoint v0.9 analysis

---

### [P3-2] Minimal Calldata Validation in `validateUserOp`

- **File:** `SuperVaultExecutor.sol:224-229`
- **Category:** Logic

**Description:**
`validateUserOp` checks `callData.length >= 36` and validates the selector, but does not verify the full `ExecuteArgs` structure. Malformed args could pass validation but fail during execution. This is mitigated by ERC-4337 bundler simulation (bundlers simulate before submitting).

---

### [P3-3] Implementation History in Interface Struct Comment

- **File:** `ISuperVaultExecutor.sol:34`
- **Category:** Code Quality

**Description:**
The `SessionKeyData.generation` field comment says `— was uint96`, which is implementation history that should not appear in a public interface. Interface consumers do not need to know the previous type.

**Current:** `uint88 generation; // slot 1 (11 bytes) — was uint96`
**Corrected:** `uint88 generation; // slot 1 (11 bytes)`

---

### [P3-4] Missing NatSpec on Interface Error Declarations

- **File:** `ISuperVaultExecutor.sol:42-57`
- **Category:** Code Quality

**Description:**
16 custom errors lack NatSpec documentation. Compare with `ISuperGovernor.sol` where every error has `/// @notice Thrown when ...`. Adding NatSpec would improve developer experience and consistency with project patterns.

---

### [P3-5] Magic Number `100000` Should Be a Named Constant

- **File:** `SuperVaultExecutor.sol:275`
- **Category:** Code Quality

**Description:**
The hardcoded `100000` gas limit in `sweepETH` should be extracted to a named constant for auditability. The constant would need to be loaded into a local variable before use in assembly.

---

### [P3-6] Modifier Declared After Functions That Use It

- **File:** `SuperVaultExecutor.sol:339-342`
- **Category:** Code Quality

**Description:**
The `onlyEntryPoint` modifier is declared in a MODIFIERS section between VIEW FUNCTIONS and INTERNAL FUNCTIONS, after the functions that use it (lines 213, 254). Per Solidity style guide, modifiers should appear before functions. Consider moving the MODIFIERS section to immediately after the RECEIVE section.

---

## Attack Surface Summary

| Surface | Details |
|---------|---------|
| **External Entry Points** | `grantSessionKey`, `grantSessionKeysBatch`, `revokeSessionKey`, `revokeSessionKeysBatch`, `invalidateAllSessionKeys`, `executeHooks`, `fulfillCancelRedeemRequests`, `fulfillRedeemRequests`, `skimPerformanceFee`, `pauseStrategy`, `unpauseStrategy`, `validateUserOp` (via EP), `executeFromEntryPoint` (via EP), `sweepETH` |
| **Value Transfer Points** | `executeHooks` (ETH → strategy → refund), `sweepETH` (ETH → recipient) |
| **Cross-Contract Interactions** | `ISuperGovernor.getAddress()`, `ISuperVaultAggregator.isMainManager()/.pauseStrategy()/.unpauseStrategy()`, `ISuperVaultStrategy.executeHooks()/.fulfillCancelRedeemRequests()/.fulfillRedeemRequests()/.skimPerformanceFee()` |
| **Trust Assumptions** | EntryPoint is trusted (canonical v0.7, immutable), SuperGovernor is trusted, aggregator is resolved dynamically via governor, strategies are implicitly validated via session key grants |
| **Access Control Layers** | DEFAULT_ADMIN_ROLE (sweepETH), Primary Manager (session key management via aggregator), Session Keys (forwarding functions via bitmask + expiry + generation + manager check), EntryPoint (validateUserOp + executeFromEntryPoint) |

---

## Coding Standards Summary

### Compliant:
- Locked pragma (`0.8.30`)
- Custom errors (no `require` strings)
- Events on all state changes
- `nonReentrant` on all external state-changing functions
- Named imports
- Return bomb protection (assembly `retSize=0`)
- Struct packing (2 slots for SessionKeyData)
- Constructor validation (zero address checks)
- Batch operations bounded by `MAX_BATCH_SIZE`

### Advisory:
- Missing NatSpec on errors/enums in interface
- Magic number in assembly
- Modifier placement order
- `was uint96` history in interface comment

---

## Security Knowledge Sources
- **vulnerabilities.md sections referenced:** 1 (Reentrancy), 2 (Access Control), 8 (Unchecked Returns), 9 (abi.encodePacked), 13 (Gas), 15 (Code Quality)
- **External sources checked:** Trail of Bits (ERC-4337), Fireblocks (UniPass), Verichains (UniswapV4), OWASP SC Top 10 (2025/2026), aviggiano/security (ERC-4337 checklist), pcaversaccio (return bomb), ERC-4337 specification
- **Historical exploits cross-referenced:** UniPass EntryPoint swap ($471K, 2023), Verichains UniswapV4Router04 ($42.1K, 2026)
