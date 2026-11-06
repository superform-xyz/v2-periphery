# Framework Documentation Report: `SuperVaultCounsel` (Superform v2-periphery)

## 1. Summary and Version Information

**Vendored OpenZeppelin version: 5.3.0** (non-upgradeable), resolved via the remapping in `v2-periphery/foundry.toml`:

```
"@openzeppelin/contracts/=lib/v2-core/lib/openzeppelin-contracts/contracts/"
```

Confirmed from `lib/v2-core/lib/openzeppelin-contracts/package.json` (`"version": "5.3.0"`). The upgradeable package is also present but irrelevant for an immutable adapter — use the non-upgradeable `@openzeppelin/contracts/` path only.

File pragmas in this OZ checkout are `^0.8.20` (SafeERC20, Address, ReentrancyGuard) and `^0.8.24` (ReentrancyGuardTransient) — all compatible with the project's Solidity 0.8.30.

Relevant local precedents to mirror:
- `src/SuperGovernor.sol` — constructor zero-check style, `isGuardian(address) external view returns (bool)` at line 708.
- `src/SuperVault/SuperVaultExecutor.sol` — existing `sweepETH` pattern (line ~292) with return-bomb-safe assembly call and `nonReentrant`.
- `src/interfaces/ISuperGovernor.sol` — interface for the `isGuardian` check.

---

## 2. SafeERC20 (v5.3.0) for permissionless `sweepERC20(token)`

Exact API surface in this version:

```solidity
library SafeERC20 {
    error SafeERC20FailedOperation(address token);
    function safeTransfer(IERC20 token, address to, uint256 value) internal;
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal;
    function trySafeTransfer(IERC20 token, address to, uint256 value) internal returns (bool); // added in 5.3
    function forceApprove(IERC20 token, address spender, uint256 value) internal;
    // safeApprove does NOT exist in 5.x
}
```

Semantics that matter for the sweep:
- **No-return tokens (USDT-style)**: a successful call with zero return data is accepted — *but only if the token address has code*. A permissionless `sweepERC20(address token)` called with an EOA/empty address reverts cleanly with `SafeERC20FailedOperation(token)` instead of silently "succeeding" — a free safety property. No extra `token.code.length` check needed.
- **False-returning tokens**: any non-`1` return word reverts.
- **Reverting tokens**: raw revert data bubbled verbatim.

Fee-on-transfer handling — sweep sidesteps it via the **balance-snapshot pattern**:

```solidity
function sweepERC20(IERC20 token) external {
    uint256 bal = token.balanceOf(address(this));
    if (bal == 0) revert NothingToSweep();
    token.safeTransfer(TREASURY, bal);
    emit ERC20Swept(address(token), bal);
}
```

- Do not compare pre/post recipient balances — FOT tokens deliver `bal - fee`; asserting exact receipt would brick the function.
- No `amount` or `to` parameter on a **permissionless** sweep — destination must be a fixed immutable.
- Event logs the pre-transfer balance (what left the adapter).

## 3. `sweepNative()`: `Address.sendValue` vs low-level call

`Address.sendValue` in 5.3.0: forwards **all gas** (required for Safe recipients — Safe `receive()` exceeds the 2300 stipend of `transfer`/`send`), reverts on failure bubbling recipient revert data (`Errors.FailedCall()` when empty). Return-bomb caveat is irrelevant when the recipient is a fixed trusted Safe.

For `sweepNative()` with an **immutable trusted Safe recipient**, `Address.sendValue(payable(TREASURY), address(this).balance)` is the right call. In-house alternative: `SuperVaultExecutor.sweepETH` (raw assembly call, capped `ETH_TRANSFER_GAS_LIMIT`, zero returndata copy — return-bomb hardened). Use that only if reviewers insist. Never `payable(x).transfer()` — 2300 gas fails for Safes.

Add a bare `receive() external payable {}` only because refunds from the strategy's hook execution land on the adapter (documented linkage to sweepNative, matching `SuperVaultExecutor` line 81 comment style).

---

## 4. ReentrancyGuard: needed or not?

Strict reading: not load-bearing if CEI is followed and funds-in ≡ funds-out per call:
- **Holds no funds by invariant** — re-entering a sweep mid-sweep transfers a now-zero balance.
- **Proposal state machine**: mark `Executed` **before** the external relay call; reentry hits the status check.
- **`executeHooks` relay**: downstream hooks could call back, but callbacks fail auth (`msg.sender` is the executor, not the operator Safe) and sweeps are harmless.

However:
- Repo convention applies `nonReentrant` liberally (`SuperVaultExecutor` guards everything including `sweepETH`). Putting `nonReentrant` on the **payable `executeHooks` relay** is cheap defense-in-depth matching house style.
- 5.x specifics: error is `ReentrancyGuardReentrantCall()` (custom error); the guard is single and shared — two `nonReentrant` functions cannot call each other.
- `ReentrancyGuardTransient` requires EIP-1153 on **every** target chain — Superform deploys multi-chain, so stick with storage-based `ReentrancyGuard` (also what existing periphery contracts use).

---

## 5. Typed forwarding of payable calls relaying exact `msg.value`

```solidity
function executeHooks(/* same typed args */) external payable nonReentrant {
    if (msg.sender != OPERATOR) revert OnlyOperator();
    // effects BEFORE the call
    EXECUTOR.executeHooks{value: msg.value}(/* args */);
}
```

1. `{value: msg.value}` relays the exact wei received. Forward `msg.value`, **not** `address(this).balance` — forwarding balance would leak sweepable dust into the call.
2. Prefer the typed call over `Address.functionCallWithValue`: bubbles revert data natively, and Solidity ≥0.8 inserts an `extcodesize` check on typed calls (calling a codeless address reverts).
3. **Never use `msg.value` inside a loop** (multicall double-spend). One entry call → one forwarded call.
4. Mark only the relay `payable` (plus `receive()`); non-payable functions revert on value automatically in 0.8.

---

## 6. Enum-typed proposal state machine (None/Pending/Ready/Executed/Vetoed/Expired)

Reference precedent: OZ Governor's `ProposalState` enum + `GovernorUnexpectedProposalState` custom error (in this same 5.3.0 checkout).

```solidity
enum ProposalStatus { None, Pending, Ready, Executed, Vetoed, Expired }
```

- `None` first is load-bearing: unset mapping slots decode to `None` for free.
- Enums are uint8-backed; out-of-range cast reverts with panic 0x21 — never uint8-cast untrusted input into the enum.

Storage packing:

```solidity
struct Proposal {
    uint64 proposedAt;      // + ProposalStatus status (uint8) => single slot, one SLOAD/SSTORE per transition
    ProposalStatus status;
}
```

- Repo lints unsafe typecasts — prefer `SafeCast.toUint64(block.timestamp)` or an explicit lint-disable comment.
- **Derive `Ready` and `Expired` in a view, don't store them** (matches OZ Governor's fully-derived `state()`):

```solidity
function status(bytes32 id) public view returns (ProposalStatus) {
    Proposal memory p = _proposals[id];
    if (p.status == ProposalStatus.Pending) {
        if (block.timestamp > p.proposedAt + EXPIRY_WINDOW) return ProposalStatus.Expired;
        if (block.timestamp >= p.proposedAt + TIMELOCK_DELAY) return ProposalStatus.Ready;
    }
    return p.status;
}
```

Custom errors per transition (parameterized errors are the OZ 5.x convention; periphery house style is upper-case errors — match the periphery interfaces file):

```solidity
error ProposalNotFound(id); error ProposalNotReady(id, current); error ProposalAlreadyExists(id);
error ProposalNotPending(id, current); error ProposalExpired(id, proposedAt);
```

- Emit an event on every transition; CEI: set `Executed` before the external call.

---

## 7. Immutable constructor configuration (OZ 5.x conventions)

- `address public immutable OPERATOR; ISuperGovernor public immutable SUPER_GOVERNOR; uint256 public immutable TIMELOCK_DELAY; uint256 public immutable EXPIRY_WINDOW;` — immutables cost ~100 gas to read vs 2100 cold SLOAD.
- **Zero-check every address with a custom error** — house precedent at `SuperGovernor.sol:137-141`.
- **Range-check uints**: `if (timelockDelay_ == 0 || expiryWindow_ <= timelockDelay_) revert InvalidConfig();` — zero delay silently disables the timelock; expiry ≤ delay makes every proposal unexecutable.
- Store typed immutables (`ISuperGovernor`), not raw `address`, for contracts only ever called through the interface.
- No initializer/upgradeable machinery — everything from `@openzeppelin/contracts/`.

---

## 8. Safe (Gnosis Safe) operational notes — what the adapter must NOT assume

Operator and guardian are Safes; auth is `msg.sender == OPERATOR` and `SUPER_GOVERNOR.isGuardian(msg.sender)` (`SuperGovernor.sol:708`). That model is correct **because** it assumes nothing about the caller being a Safe:

1. **No EIP-1271 / signature verification.** Never add `ECDSA.recover` checks (a Safe signs via EIP-1271, not EOA ECDSA). Never use `tx.origin` (it's the relayer EOA, not the Safe).
2. **No code-existence checks at construction.** Safes are often counterfactual (CREATE2 predicted, not yet deployed). Constructor must not check `operator.code.length > 0` or call the operator/guardian — zero-address check only.
3. **No 2300-gas transfers to them.** Full-gas `call`/`sendValue` only.
4. **Don't assume how the Safe calls you.** `execTransaction`, an enabled module, or a delegatecalled library are indistinguishable — all give `msg.sender == safe`. Adapter security == the Safe's own owner/module configuration; document, don't detect.
5. **Don't assume atomic multi-call ordering.** A Safe MultiSend batch can hit multiple functions with identical `block.timestamp`. Pick and test the delay boundary explicitly (`>=` vs `>`); with `>=`, a zero delay would allow same-tx propose+execute — another reason to enforce nonzero delay in the constructor.
6. **Guardian set is dynamic.** Query `isGuardian` at veto time, never cache. A guardian valid at propose time may be revoked before veto time — intended semantics.
7. **Reverts should bubble cleanly.** Safe UIs surface revert data from simulation; parameterized custom errors give signers actionable failures.
8. **Gas**: Safe execution adds ~30-60k overhead but no gas ceiling on the inner call.

---

## 9. References

- SafeERC20 (v5.3.0): `lib/v2-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol`
- Address / sendValue: `.../contracts/utils/Address.sol`; shared errors in `.../contracts/utils/Errors.sol`
- ReentrancyGuard: `.../contracts/utils/ReentrancyGuard.sol`; transient variant EIP-1153 chains only
- SafeCast: `.../contracts/utils/math/SafeCast.sol`
- Governor state-machine precedent: `.../contracts/governance/Governor.sol`
- House patterns: `src/SuperGovernor.sol` (constructor validation, `isGuardian`), `src/SuperVault/SuperVaultExecutor.sol` (`sweepETH`, `nonReentrant` convention)

**Bottom line**: SafeERC20 `safeTransfer` of live balance to an immutable destination for `sweepERC20`; `Address.sendValue` (full gas) for `sweepNative`; storage-based `ReentrancyGuard` with `nonReentrant` on the payable `executeHooks` relay only (defense-in-depth; CEI makes it non-load-bearing); typed `{value: msg.value}` forwarding; `None`-first enum packed with `uint64 proposedAt` in one slot with `Ready`/`Expired` derived in a view; constructor zero- and range-checks with custom errors; pure `msg.sender`-equality auth with no code-length, EIP-1271, or `tx.origin` assumptions about the Safes.
