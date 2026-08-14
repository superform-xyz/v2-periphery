# Best Practices Research: Timelock + Veto Adapter

## 1. Reference designs

### OpenZeppelin TimelockController
- Identity: `id = hashOperation(target, value, data, predecessor, salt)` — content-addressed.
- State: single `mapping(bytes32 => uint256) _timestamps`; `0` = Unset, `1` = Done, `>1` = eta. v5 exposes derived `OperationState` enum (Unset/Waiting/Ready/Done) — state is *derived*, not stored.
- Replay: schedule reverts if id not Unset; execute requires Ready then writes done-marker.
- Cancel: deletes the timestamp — a *reset*, not a veto (re-scheduleable immediately).
- **No expiry** — a Ready op stays executable forever (gap to fix with Compound's grace period).
- Drop: predecessor chaining, batching, AccessControl roles, self-administration (updateDelay via self-call), payable plumbing.

### Compound Timelock
- Identity: `txHash = keccak256(abi.encode(target, value, signature, data, eta))` — eta acts as implicit nonce.
- Delay bounds: MIN 2 days / MAX 30 days checked at queue.
- **Expiry: `GRACE_PERIOD = 14 days`** — execute requires `eta <= now <= eta + GRACE_PERIOD`. Canonical stale-proposal mechanism; copy it.
- Replay: queued flag deleted *before* the external call (CEI).
- Drop: generic execution via `abi.encodePacked(bytes4(keccak256(signature)), data)`.

### Copy/drop matrix
| Mechanism | Verdict | From |
|---|---|---|
| Content-addressed id incl. exact args | Copy | OZ |
| Derived time-based states | Copy | OZ v5 |
| Done-marker / delete-before-call replay protection | Copy | OZ/Compound |
| GRACE_PERIOD expiry | Copy | Compound |
| Constructor sanity bounds on delays | Copy | Compound |
| Salt/nonce for re-proposing identical content | Copy (as nonce) | OZ/Compound |
| Cancel-resets-to-Unset | **Modify — veto must be terminal** | — |
| Generic target/value/data execution | Drop | Both |
| Mutable delay, roles, batching, self-admin | Drop | Both |

## 2. Proposal ID derivation

Recommended hybrid: `id = keccak256(abi.encode(ACTION_TYPE, args..., nonce++))` — content binding + guaranteed uniqueness + no user-supplied salt footgun. Include the action-type discriminator to prevent cross-action collisions. For tiny fixed-size payloads (address; bytes32+bytes32), **store the args in a struct** so `execute(id)` needs no re-supplied data — removes execute-time mismatch bugs (vs OZ Governor's resupply-and-hash pattern).

## 3. State machine

```solidity
enum ProposalStatus { None, Pending, Executed, Vetoed } // stored
// Derived: Pending && now >= eta                  -> Ready
//          Pending && now >  eta + GRACE_PERIOD   -> Expired
```
- Never store time-derived states (Expired/Ready) — derive them (OZ v5 model).
- Store actor-driven terminal states (Executed, Vetoed). Veto is **terminal** per instance — distinct error on execute-after-veto.
- Public `state(id)` view returning the full derived enum — most useful function for monitoring/tests.
- `eta = block.timestamp + REVIEW_WINDOW` computed internally — no user-supplied eta.

### Re-proposal after veto (key pitfall)
Identical content SHOULD be re-proposable with a fresh nonce — veto a *proposal instance*, not the content. A content-level permanent ban in an immutable ownerless contract is a self-inflicted deadlock. Any re-proposal restarts the full window and re-alerts the guardian, who can veto again at negligible cost. (Optional explicit guardian-writable content blocklist if permanent bans are wanted — a deliberate second power.)

## 4. Guardian/veto precedents — negative-only power

- **Optimism Guardian**: pause-only via SuperchainConfig; deputies get narrower single-use EIP-712-scoped powers (DeputyPauseModule). Stage-1 frameworks explicitly evaluate guardian roles being negative-only.
- **Aave Emergency Admin**: can pause, historically could not unpause — fast actor gets the safe direction only.
- **Compound Pause Guardian**: can pause mint/borrow/transfer/seize, never redeem/repay (users can always exit); enumerated per-function.

Application:
1. Veto is the guardian's only write (plus, in our design, the purely protective `invalidateAllSessionKeys`).
2. Veto scope = one proposal id per call; no global pause switch (bounded damage: status quo preserved).
3. Veto permanent per instance; allowed until the moment of execution (no Pending-only restriction — avoids execute-vs-veto boundary race).
4. Hold operator and guardian roles in Safes — key rotation happens inside the Safe without touching immutables.

## 5. Typed pass-throughs vs generic forwarding

Why typed wins: enumerable authority (ABI = full power set), compiler-checked args, no self-administration channel, timelock gating is a compile-time property not a calldata-parsing property.

Incident precedents for generic forwarders:
- **Socket/Bungee 2024 (~$3.3M)** — raw `.call()` with user calldata → `transferFrom` drained approvals
- **LI.FI 2024 (~$9.7M)** + 2022 — arbitrary call in facet, same class
- **Dexible 2023 (~$1.5M)** — user-defined router + calldata
- **Poly Network 2021 (~$611M)** — cross-chain manager arbitrary calls reached its own keeper management; a privileged forwarder's effective privilege is the transitive closure of everything reachable

Design details: each pass-through is operator-gated, typed args, calls exactly one target function, emits its own event. Note `executeHooks` genuinely takes opaque `bytes` hookCalldata — that is fine because the strategy itself validates hooks against merkle roots; the adapter isn't the policy layer there. Vault growing new manager functions ⇒ adapter redeploy — a feature (visible authority expansion).

## 6. Event design + manifest binding

Precedent: OZ Governor `descriptionHash` — execution cryptographically bound to the document reviewers saw. Apply as: `manifestHash` first-class arg of the root proposal, stored in proposal identity, emitted. Guardian policy: veto anything whose manifest doesn't fetch or doesn't reproduce the root. Document the hash construction (keccak256 of canonical manifest bytes; if IPFS, note CID digest ≠ keccak — pick one). Manifest must be deterministic (sorted leaves, fixed serialization).

```solidity
event ProposalQueued(bytes32 indexed id, uint8 indexed actionType,
    address yieldSource, address oracle, bytes32 root, bytes32 manifestHash,
    uint64 eta, uint64 expiry);
event ProposalVetoed(bytes32 indexed id, address indexed guardian);
event ProposalExecuted(bytes32 indexed id);
```
- Queue event carries full payload + both timestamps (watchers need zero eth_calls).
- Index `id` on all lifecycle events; don't index payload fields.
- Every typed pass-through emits its own event too (monitoring covers the non-timelocked surface).

## 7. Immutability

- Precedents: Liquity (fully immutable, 5+ years), Optimism module pattern (immutable modules, mutability lives in the Safes holding the role addresses).
- Constructor `(strategy, aggregator refs, operator, reviewWindow, gracePeriod)`, all immutable, sanity bounds (nonzero, window floors/ceilings). Post-deploy checklist: read back immutables, dry-run queue/veto/execute on a fork before wiring as manager.
- Key-loss matrix (must be documented, is fail-safe not fail-dead):
  - Operator lost: no new sources/roots; vault keeps operating with current config; recovery = SuperGovernor takeover → new adapter.
  - Guardian lost: degrades to plain timelock (window still enforced, nobody vetoes); mitigate with Safe rotation + periodic guardian liveness drills.
  - Guardian compromised: worst case = permanent veto of all changes — liveness attack on changes only, never a safety attack on funds.
  - In our system the "who can change the manager pointer" question is answered by SuperGovernor takeover — the recovery path already exists; the adapter does NOT need a queueSetManager handoff.

## Condensed recommendations
1. Typed propose functions; `id = keccak256(abi.encode(ACTION_TYPE, args, nonce++))`; args stored in struct; `execute(id)` takes no args.
2. `eta` internal; execute valid only in `[eta, eta + GRACE_PERIOD]`; Expired derived.
3. Stored: None/Pending/Executed/Vetoed; derived: Ready/Expired; public `state(id)`.
4. Veto guardian-only, per-proposal, terminal, allowed until execution; identical content re-proposable with new nonce.
5. No generic execute; every pass-through typed + evented; no fallback; `receive()` only because strategy refunds ETH (with sweep).
6. Queue events carry full payload/manifestHash/eta/expiry.
7. All config immutable; operator/guardian are Safes; key-loss matrix documented; recovery = SuperGovernor takeover.

(Se­e agent report for full source URLs: OZ TimelockController/Governor, Compound Timelock, OP Stack DeputyPauseModule/SuperchainConfig specs, Aave proposal 49, CertiK Socket analysis, BlockSec LI.FI analysis, rekt.news Poly Network, Liquity docs.)
