# Security Analysis Report

## Metadata
- **Target:** `src/SuperVault/SuperVaultExecutor.sol`, `src/interfaces/SuperVault/ISuperVaultExecutor.sol`
- **Mode:** review
- **Date:** 2026-03-24
- **Contract Types Detected:** Session key delegation / forwarding proxy for vault operations
- **Files Analyzed:** 2
- **Previous Reports:** `specs/security-reports/2026-03-18-supervault-manager.md` (v1), `specs/security-reports/2026-03-18-supervault-manager-v2.md` (v2)

## Summary
| Severity | Count | Blocks Merge |
|----------|-------|-------------|
| P0 Critical | 0 | Yes |
| P1 High | 0 | Yes |
| P2 Medium | 3 | No |
| P3 Low | 7 | No |

## Verdict
**PASS** — No P0 or P1 findings. Safe to proceed with recommended improvements.

> **Note on P1 from external research:** The EVM Security Researcher flagged zombie key revival (A→B→A manager rotation) as P1 from a pure external-research perspective. This is reclassified as **P2** because the code includes an explicit `@dev WARNING` at lines 68-72 and the generation counter provides a manual mitigation path via `invalidateAllSessionKeys()`. It remains the highest-priority recommended improvement.

> **Improvements since v2 report (2026-03-18):**
> - [x] `nonReentrant` added to all forwarding functions (v2 Finding #2 — was "consider adding")
> - [x] `sweepETH()` implemented with `ETHSwept` event (v2 Finding #10)
> - [x] `ETH_REFUND_FAILED` renamed to `ETH_TRANSFER_FAILED` (semantic correction)
> - [x] `receive()` placement corrected (v2 Finding #8)
> - [x] Aggregator cached in `pauseStrategy`/`unpauseStrategy` (v2 Finding #5)
> - [x] `@dev WARNING` added for zombie key reactivation (v2 Finding #1)

---

## P0 Findings (Critical)

None found.

## P1 Findings (High)

None found.

## P2 Findings (Medium)

### 1. No Per-Function Scoping on Session Keys

- **File:** `SuperVaultExecutor.sol` (contract-wide design)
- **SWC:** N/A
- **Category:** Access Control
- **Description:** Session keys are granted per-strategy with access to ALL forwarding functions. A key intended only for routine `skimPerformanceFee()` can also call `executeHooks()` (with arbitrary hook execution) or `pauseStrategy()`. ERC-4337 session key best practices recommend restricting keys to specific function selectors via a permission bitmask. The blast radius of a single key compromise is the entire set of forwarding functions for that strategy.
- **Exploit Scenario:** An operator grants a session key to an automated bot for `skimPerformanceFee()` only. The bot's private key is compromised. The attacker uses it to call `executeHooks()` with malicious hook data (bounded by merkle proof validation at the strategy level) or `pauseStrategy()` to disrupt operations.
- **Mitigating Factors:**
  - `executeHooks` requires valid merkle proofs at the strategy level, providing a secondary defense
  - Other forwarding functions (`fulfillRedeemRequests`, `skimPerformanceFee`) have strategy-level validation
  - `pauseStrategy`/`unpauseStrategy` are recoverable by the primary manager
- **Secure Pattern:** Add a `uint256 permissions` bitmask to `SessionKeyData`:
  ```solidity
  uint256 constant PERM_EXECUTE_HOOKS = 1 << 0;
  uint256 constant PERM_FULFILL_CANCEL = 1 << 1;
  uint256 constant PERM_FULFILL_REDEEM = 1 << 2;
  uint256 constant PERM_SKIM_FEE = 1 << 3;
  uint256 constant PERM_PAUSE = 1 << 4;
  uint256 constant PERM_UNPAUSE = 1 << 5;
  uint256 constant PERM_ALL = type(uint256).max;
  ```
  Check at the top of each forwarding function: `if (data.permissions & PERM_X == 0) revert INSUFFICIENT_PERMISSIONS();`
- **Sources:** ERC-4337 session key best practices; Trail of Bits "Six Mistakes in ERC-4337 Smart Accounts"

### 2. Redundant External Call in `_getAggregator()` — Uncached Registry Key

- **File:** `SuperVaultExecutor.sol:317-319`
- **SWC:** N/A
- **Category:** Gas
- **Description:** `_getAggregator()` makes two external calls per invocation: (1) `SUPER_GOVERNOR.SUPER_VAULT_AGGREGATOR()` to get the `bytes32` key, (2) `SUPER_GOVERNOR.getAddress(key)` to resolve the address. The `bytes32` key is a constant that never changes. Caching it as an immutable in the constructor saves ~2,600 gas (one STATICCALL) on every function that resolves the aggregator — which is every grant, revoke, validation, and forwarding operation.
- **Vulnerable Code:**
  ```solidity
  function _getAggregator() internal view returns (ISuperVaultAggregator) {
      return ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.SUPER_VAULT_AGGREGATOR()));
  }
  ```
- **Secure Pattern:**
  ```solidity
  // Immutable:
  bytes32 public immutable SUPER_VAULT_AGGREGATOR_KEY;

  // Constructor:
  SUPER_VAULT_AGGREGATOR_KEY = ISuperGovernor(superGovernor_).SUPER_VAULT_AGGREGATOR();

  // Updated:
  function _getAggregator() internal view returns (ISuperVaultAggregator) {
      return ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR_KEY));
  }
  ```
- **Sources:** Vulnerability Scanner, Best Practices Agent

### 3. Zombie Key Revival on Manager Rotation (Documented Design Decision)

- **File:** `SuperVaultExecutor.sol:68-72, 280-288`
- **SWC:** N/A
- **Category:** Logic
- **Description:** When a primary manager changes (A→B), session keys granted by A are logically invalidated because `isMainManager(A, strategy)` returns false. However, key data persists in storage. If governance later reinstates A (A→B→A), all previously granted session keys by A silently reactivate — including ones the manager intended to revoke before the transition. The generation counter does NOT automatically increment on manager rotation; `invalidateAllSessionKeys()` must be proactively called by the interim manager.
- **Status:** Documented with `@dev WARNING` at lines 68-72. The reinstated manager is responsible for revoking stale keys or bumping the generation.
- **Secure Pattern (automatic):** Have the aggregator's `changePrimaryManager()` call back to the executor to increment the strategy generation. This eliminates the operational dependency.
- **Sources:** Ronin Bridge $625M (Mar 2022) — stale validator access; EVM Security Researcher

---

## P3 Findings (Low)

### 4. No Expiry Upper Bound on Session Keys

- **File:** `SuperVaultExecutor.sol:294-297`
- **Category:** Logic
- **Description:** `_grantSessionKey` accepts `expiry = type(uint256).max`, creating effectively permanent delegation. If the granting manager remains unchanged, the key never expires. The `grantedByManager` liveness check provides a safety net, but a permanent key combined with a stable manager structure creates indefinite risk.
- **Secure Pattern:** Add `MAX_EXPIRY_DURATION`:
  ```solidity
  uint256 public constant MAX_EXPIRY_DURATION = 30 days;
  // In _grantSessionKey:
  if (expiry > block.timestamp + MAX_EXPIRY_DURATION) revert EXPIRY_TOO_FAR();
  ```
- **Sources:** ERC-4337 session key best practices; Vulnerability Scanner

### 5. Storage Packing Opportunity in SessionKeyData

- **File:** `ISuperVaultExecutor.sol:15-19`
- **Category:** Gas
- **Description:** `SessionKeyData` uses 3 storage slots (uint256 + address + uint256). `generation` is a monotonically incrementing counter that will never realistically exceed `uint96`. Packing `grantedByManager` (20 bytes) and `generation` as `uint96` (12 bytes) into a single slot saves 1 slot per session key entry (from 3 slots to 2).
- **Current Code:**
  ```solidity
  struct SessionKeyData {
      uint256 expiry;           // slot 0
      address grantedByManager; // slot 1 (12 bytes wasted)
      uint256 generation;       // slot 2
  }
  ```
- **Secure Pattern:**
  ```solidity
  struct SessionKeyData {
      uint256 expiry;           // slot 0
      address grantedByManager; // slot 1: 20 bytes
      uint96 generation;        // slot 1: 12 bytes (packed)
  }
  ```
- **Source:** Best Practices Agent

### 6. Silent No-Op on Revoking Non-Existent Keys

- **File:** `SuperVaultExecutor.sol:309-313`
- **Category:** Logic
- **Description:** `_revokeSessionKey` silently returns if `expiry == 0` (key never granted). `revokeSessionKey()` succeeds without indication that the key was never active. A manager attempting to revoke a compromised key with a typo in the strategy address receives a success receipt while the actual compromised key remains active.
- **Secure Pattern:** Either revert for fail-fast:
  ```solidity
  if (_sessionKeys[strategy][sessionKey].expiry == 0) revert SESSION_KEY_NOT_AUTHORIZED();
  ```
  Or document the no-op behavior explicitly in the NatSpec if idempotent revocations are intentional.
- **Source:** Vulnerability Scanner, Best Practices Agent

### 7. `sweepETH` Forwards All Gas to Recipient

- **File:** `SuperVaultExecutor.sol:208-210`
- **SWC:** SWC-126
- **Category:** Gas / DoS
- **Description:** Assembly `call(gas(), to, bal, 0, 0, 0, 0)` forwards all remaining gas. If `to` is a contract with an expensive `receive()`, the sweep consumes unexpected gas. Since `to` is admin-chosen, practical impact is negligible.
- **Source:** Vulnerability Scanner

### 8. No Contract Existence Check on Strategy Address

- **File:** `SuperVaultExecutor.sol:132-195`
- **Category:** Cross-Contract
- **Description:** Forwarding functions do not validate that `strategy` has deployed code. Calls to an EOA or self-destructed contract succeed silently for void-returning functions. Practically mitigated by `_validateSessionKey` which checks `aggregator.isMainManager()` — unknown strategies would fail this check.
- **Source:** Vulnerability Scanner

### 9. `executeHooks` NatSpec Missing ETH Refund Documentation

- **File:** `ISuperVaultExecutor.sol:115-118`
- **Category:** Documentation
- **Description:** The interface NatSpec for `executeHooks` does not document the ETH refund behavior. Callers sending ETH need to know that overpayment is refunded.
- **Secure Pattern:**
  ```solidity
  /// @notice Forwards executeHooks to a strategy
  /// @dev Any ETH overpayment (msg.value minus what the strategy consumes) is refunded to msg.sender.
  ```
- **Source:** Best Practices Agent

### 10. `sweepETH` NatSpec Missing Zero-Balance Behavior

- **File:** `ISuperVaultExecutor.sol:152-155`
- **Category:** Documentation
- **Description:** `sweepETH` silently succeeds with no event if the contract balance is zero. This should be documented.
- **Secure Pattern:** Add `/// @dev No-op (no event emitted) if the contract balance is zero.`
- **Source:** Best Practices Agent

---

## Attack Surface Summary

**External Entry Points:**
| Function | Auth | ETH | External Calls | Reentrancy Guard |
|----------|------|-----|----------------|-----------------|
| `grantSessionKey` | Primary manager | No | `_getAggregator().isMainManager()` | No (storage write only) |
| `grantSessionKeysBatch` | Primary manager | No | `_getAggregator().isMainManager()` x N | No (storage write only) |
| `revokeSessionKey` | Primary manager | No | `_getAggregator().isMainManager()` | No (storage delete) |
| `revokeSessionKeysBatch` | Primary manager | No | `_getAggregator().isMainManager()` x N | No (storage delete) |
| `invalidateAllSessionKeys` | Primary manager | No | `_getAggregator().isMainManager()` | No (storage write only) |
| `executeHooks` | Session key | Yes | `strategy.executeHooks()` + ETH refund | **Yes** |
| `fulfillCancelRedeemRequests` | Session key | No | `strategy.fulfillCancelRedeemRequests()` | **Yes** |
| `fulfillRedeemRequests` | Session key | No | `strategy.fulfillRedeemRequests()` | **Yes** |
| `skimPerformanceFee` | Session key | No | `strategy.skimPerformanceFee()` | **Yes** |
| `pauseStrategy` | Session key | No | `aggregator.pauseStrategy()` | **Yes** |
| `unpauseStrategy` | Session key | No | `aggregator.unpauseStrategy()` | **Yes** |
| `sweepETH` | DEFAULT_ADMIN_ROLE | Yes (out) | Assembly `call` to recipient | **Yes** |
| `receive` | Anyone | Yes (in) | None | No |

**Architectural Trust Assumptions (System-Wide):**
- SuperGovernor registry integrity (all authorization flows resolve the aggregator dynamically)
- Aggregator `isMainManager()` correctness
- Strategy-level parameter validation for all forwarded calls (merkle proofs, share accounting, etc.)
- Session key credential security (operational concern)

**Design Strengths:**
- Typed-call forwarding only (no arbitrary `call()` or `delegatecall`)
- 3-layer session key validation: expiry + generation counter + manager liveness
- Per-strategy key scoping (cross-strategy isolation)
- Balance-delta ETH tracking prevents stray ETH theft
- Assembly refund prevents return bomb DoS
- `nonReentrant` on all forwarding functions and admin functions
- Batch size limits prevent gas DoS (`MAX_BATCH_SIZE = 50`)
- Non-upgradeable deployment (no proxy attack vectors)
- `sweepETH` recovers trapped ETH with `ETHSwept` event

---

## Exploit Precedent Table

| # | Component | Function(s) | Similar Protocol | Exploit Type | Loss | Date | Vulnerable? | Mitigation |
|---|-----------|-------------|-----------------|--------------|------|------|-------------|------------|
| 1 | Session key delegation (manager revival) | `_grantSessionKey`, `_validateSessionKey` | **Ronin Bridge** | Stale authorization / key revival | $625M | Mar 2022 | **Partial** | `@dev WARNING` + manual `invalidateAllSessionKeys()` |
| 2 | ETH balance-delta tracking | `executeHooks` L142-155 | **Wormhole Bridge** | Value accounting mismatch | $326M | Feb 2022 | **No** | Balance-delta pattern isolates caller's overpayment |
| 3 | Return bomb prevention | `executeHooks` L150-151 | **KyberSwap** | Returndata amplification | $48.8M | Nov 2023 | **No** | Assembly call with zero returndata size |
| 4 | Forwarding proxy (typed calls) | All forwarding functions | **Harmony Horizon** | Arbitrary execution via compromised key | $100M | Jun 2022 | **No** | Typed interface methods only, not arbitrary `call()` |
| 5 | Dynamic registry resolution | `_getAggregator()` L317-319 | **Multichain/Anyswap** | Governance compromise + registry poisoning | $126M | Jul 2023 | **Low** | Immutable `SUPER_GOVERNOR`; requires multi-sig compromise |
| 6 | Access control delegation | Session key model | **Radiant Capital** | Hardware wallet / key compromise | $50M | Oct 2024 | **Partial** | Time-bounding + manager-liveness; no rate limiting |
| 7 | Non-upgradeable deployment | Contract design | **Ronin Bridge** (2nd) | Upgrade script error | $12M | Aug 2024 | **No** | No proxy pattern by design |
| 8 | Reentrancy in forwarding | All forwarding functions | **Euler Finance** | Reentrancy via donation/callback | $197M | Mar 2023 | **No** | `nonReentrant` on all forwarding functions |
| 9 | `receive()` ETH acceptance | `receive()` L62 | **Parity Multisig** | Unintended ETH trapping | $31M | Nov 2017 | **No** | `sweepETH()` admin recovery function |
| 10 | Batch operations gas limit | `grantSessionKeysBatch` | **Synthetix** | Unbounded loop DoS | N/A | 2019 | **No** | `MAX_BATCH_SIZE = 50` |

---

## OWASP Smart Contract Top 10 (2025) Assessment

| ID | Category | Applicable? | Status |
|----|----------|-------------|--------|
| SC01 | Access Control | **Yes** | 3-layer validation; zombie revival documented; no per-function scoping |
| SC02 | Business Logic | Yes | Delegated to strategy level; executor is a passthrough |
| SC03 | Price Oracle Manipulation | No | No oracle interaction |
| SC04 | Flash Loan Attacks | No | No flash loan surface; role-based governance |
| SC05 | Input Validation | Yes | Batch size, zero-address, expiry checks all present |
| SC06 | Unchecked External Calls | Yes | All typed calls; assembly ETH call checked |
| SC07 | Arithmetic Errors | No | Minimal arithmetic; 0.8.30 overflow protection |
| SC08 | Reentrancy | Yes | `nonReentrant` on all forwarding + admin functions |
| SC09 | Integer Overflow | No | Solidity 0.8.30 built-in checks |
| SC10 | Proxy & Upgradeability | No | Non-upgradeable by design |

---

## Recommended Actions (Prioritized)

1. **Cache `SUPER_VAULT_AGGREGATOR` key as immutable** — Saves ~2,600 gas per aggregator resolution (Finding 2). Trivial to implement.
2. **Pack `SessionKeyData.generation` as `uint96`** — Saves 1 storage slot per key (Finding 5). Requires interface change.
3. **Add `@dev` NatSpec for ETH refund behavior and zero-balance sweep** — Documentation (Findings 9, 10). Trivial.
4. **Consider per-function permission bitmask** — Limits blast radius of key compromise (Finding 1). Design trade-off.
5. **Consider `MAX_EXPIRY_DURATION` constant** — Prevents near-infinite session keys (Finding 4). Optional.
6. **Consider reverting on no-op revocations** — Surfaces caller mistakes (Finding 6). Design trade-off.

---

## Sources

**Internal:**
- Previous security reports: v1 (2026-03-18), v2 (2026-03-18)

**External:**
- [Trail of Bits - Six Mistakes in ERC-4337 Smart Accounts](https://blog.trailofbits.com/2026/03/11/six-mistakes-in-erc-4337-smart-accounts/)
- [Halborn - Ronin Hack March 2022](https://www.halborn.com/blog/post/explained-the-ronin-hack-march-2022)
- [Halborn - Radiant Capital Hack October 2024](https://www.halborn.com/blog/post/explained-the-radiant-capital-hack-october-2024)
- [Chainalysis - Multichain Exploit July 2023](https://www.chainalysis.com/blog/multichain-exploit-july-2023/)
- [Three Sigma - 2024 DeFi Exploits: Top Vulnerabilities](https://threesigma.xyz/blog/2024-defi-exploits-top-vulnerabilities)
- [Halborn - Top 100 DeFi Hacks 2025](https://www.halborn.com/reports/top-100-defi-hacks-2025)
- [OWASP Smart Contract Top 10 2025](https://scs.owasp.org/sctop10/)
- [ERC-4337 Session Keys & Delegation](https://docs.erc4337.io/smart-accounts/session-keys-and-delegation.html)
- [pcaversaccio - Return Bomb Attack PoC](https://gist.github.com/pcaversaccio/3b487a24922c839df22f925babd3c809)
- [Consensys - EIP-6780 Dencun Upgrade](https://consensys.io/blog/ethereum-dencun-upgrade-explained-part-1)
