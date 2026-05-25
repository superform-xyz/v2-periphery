# ValidatorStaking Contract Design

## Context

Superform currently runs a single trusted validator for PPS (price-per-share) oracle updates. The goal is to decentralize this by allowing external validators to self-register by staking UP tokens, with an optimistic dispute mechanism for slashing incorrect PPS submissions. This must work across multiple chains from day one (validators stake UP/UpOFT on each chain where they operate).

**No changes to SuperGovernor or SuperVaultAggregator.** A new `StakedECDSAPPSOracle` replaces the current `ECDSAPPSOracle` — it reads the validator set directly from `ValidatorStaking`'s live staking state instead of SuperGovernor's stored set. SuperGovernor's `setActivePPSOracle()` is pointed to the new oracle. The `ValidatorManager` wrapper from the previous design is no longer needed.

---

## Architecture Overview

```
Validators stake UP
        |
        v
  ValidatorStaking                          SuperGovernor
  (staking, slashing,                       setActivePPSOracle(newOracle)
   disputes)                                       |
        |                                          v
        |--- isValidator(signer) ------>  StakedECDSAPPSOracle  (new, replaces ECDSAPPSOracle)
        |--- getQuorum() -------------->        |
        |--- getActiveValidatorCount() ->       |
        |                                  forwardPPS()
        v                                       |
  Slashing/Disputes                             v
  (optimistic model)                   SuperVaultAggregator (unchanged)
```

### Key Insight: Registry vs. Active Set (Ethereum-style)

Following the same pattern as Ethereum's beacon chain, the validator set is split into two layers:

**Validator Registry** (`_registry` EnumerableSet) — append-only. When someone first stakes, they get a permanent index. Slashing does NOT remove from the registry; it sets a flag. Voluntary exits only remove after full cooldown completes. This is the stable set that the off-chain p2p network syncs against — it rarely changes.

**Active Set** — a derived view over registry + staking state. At any block:

```solidity
function isActiveValidator(address account) external view returns (bool) {
    ValidatorRecord storage v = _validators[account];
    return v.registered
        && v.effectiveStake >= minimumStake
        && v.status == ValidatorStatus.Active;  // not Slashed, not Exiting, not Exited
}
```

The active set fluctuates (slashing, partial unstakes dropping below threshold, cooldown periods) but these changes **never modify the registry** and **never create a new config version**. The p2p network sees a stable registry and derives who's active locally.

**Config version** — only incremented on registry changes (new validator joins, voluntary full exit completes). Slashing does NOT create a new version. This keeps the off-chain network stable between rounds.

```solidity
enum ValidatorStatus {
    Unregistered,    // Not in registry
    Active,          // Staked >= minimum, participating
    Exiting,         // Unstake requested, in cooldown
    Exited,          // Cooldown complete, withdrawn (still in registry for historical reference)
    Slashed          // Slashed, permanently excluded from active set
}

function getActiveValidatorCount() external view returns (uint256) {
    return _activeCount;  // maintained counter, O(1)
}

function getQuorum() external view returns (uint256) {
    return Math.max(1, (_activeCount * 2 / 3) + 1);
}

function getRegisteredValidators() external view returns (address[] memory) {
    return _registry.values();  // full registry, stable across rounds
}

function getActiveValidators() external view returns (address[] memory) {
    // iterate registry, filter by isActiveValidator — for off-chain consumers only
}
```

**Why this matters for the p2p network:**
- Registry is stable — no churn from slashing events or threshold changes
- Off-chain nodes sync the registry once per config version, then derive active set locally
- A slash mid-round doesn't disrupt in-flight signing — the slashed validator's signatures are simply rejected by the oracle at verification time
- Multiple state changes in the same block (slash + unstake + new stake) all resolve consistently — no ordering dependencies
- Given a block number, the active set is deterministically fixed

### Contract: `StakedECDSAPPSOracle.sol` (Replaces ECDSAPPSOracle)

Nearly identical to the current `ECDSAPPSOracle` except validator checks read from `ValidatorStaking` instead of `SuperGovernor`:

```solidity
// Current ECDSAPPSOracle (line 177):
if (!SUPER_GOVERNOR.isValidator(signer)) revert INVALID_VALIDATOR();

// New StakedECDSAPPSOracle:
if (!VALIDATOR_STAKING.isActiveValidator(signer)) revert INVALID_VALIDATOR();
```

```solidity
// Current ECDSAPPSOracle (line 196):
uint256 requiredQuorum = SUPER_GOVERNOR.getPPSOracleQuorum();

// New StakedECDSAPPSOracle:
uint256 requiredQuorum = VALIDATOR_STAKING.getQuorum();
```

Everything else stays the same: EIP-712 signatures, nonce management, batch processing, forwarding to SuperVaultAggregator.

**Deployment flow:**
1. Deploy `ValidatorStaking`
2. Deploy `StakedECDSAPPSOracle` pointing to `ValidatorStaking` and `SuperGovernor`
3. Call `SuperGovernor.setActivePPSOracle(newOracle)` (requires `SUPER_GOVERNOR_ROLE`, 7-day timelock)
4. Old ECDSAPPSOracle becomes inactive — no code change needed, just not pointed to anymore

---

## Contract: `ValidatorStaking.sol`

### Storage

```solidity
// --- Participation Layer ($UP) ---
IERC20 public immutable UP_TOKEN;                 // $UP token (participation rights)
uint256 public minimumUpStake;                     // Min $UP to join validator set (alignment threshold)
uint256 public unstakeCooldown;                    // Default: 7 days

// --- Security Layer (ETH + Blue Chips) ---
struct SecurityToken {
    address priceFeed;               // Chainlink price feed for USD valuation
    uint8 decimals;                  // Token decimals (cached at registration)
    bool active;                     // Whether this token is currently accepted
}
mapping(address token => SecurityToken) public securityTokens;
EnumerableSet.AddressSet private _acceptedSecurityTokens;  // Registry of accepted tokens
uint256 public minimumSecurityStakeUSD;            // Min USD value of security stake (e.g., $50K in 18 decimals)

enum ValidatorStatus {
    Unregistered,    // Not in registry
    Active,          // Meets both UP and security thresholds, participating
    Exiting,         // Unstake requested, in cooldown
    Exited,          // Cooldown complete, withdrawn
    Slashed          // Permanently excluded from active set
}

struct ValidatorRecord {
    // Participation layer ($UP)
    uint256 upStake;                 // Total $UP deposited
    uint256 effectiveUpStake;        // upStake - upUnstakeAmount

    // Security layer (multi-asset)
    mapping(address token => uint256) securityStakes;  // Per-token security deposits
    uint256 unstakeRequestTime;      // 0 = no pending unstake
    uint256 upUnstakeAmount;         // $UP amount requested for unstake
    mapping(address token => uint256) securityUnstakeAmounts;  // Per-token unstake amounts

    bytes publicKey;                 // Ed25519 key for off-chain coordination
    ValidatorStatus status;
}
mapping(address => ValidatorRecord) public validators;

// --- Registry (stable, append-only except on full exit) ---
EnumerableSet.AddressSet private _registry;
uint256 public configVersion;       // Incremented only on registry changes (join/full exit)

// --- Active set (derived, tracked via counter for O(1) reads) ---
uint256 public activeCount;         // Maintained on stake/unstake/slash — avoids iteration

// Quorum is derived: max(1, floor(activeCount * 2 / 3) + 1)
// No configurable numerator/denominator — BFT-safe by construction

// --- Disputes ---
uint256 public disputeWindow;       // e.g., 1 hour after PPS forwarded
uint256 public disputeBond;         // $UP amount challenger must post
uint256 public deviationThresholdBps; // e.g., 100 = 1% — max acceptable deviation

struct Dispute {
    address challenger;
    address validator;              // Validator being challenged
    address strategy;
    uint256 submittedPPS;
    uint256 referencePPS;
    uint256[] chainIds;             // Chains involved in computation (input state pinning)
    uint256[] blockNumbers;         // Pinned block per chain (same index as chainIds)
    uint256 timestamp;
    uint256 bondAmount;
    DisputeStatus status;           // Pending, Resolved, Rejected
}
mapping(uint256 => Dispute) public disputes;
uint256 public disputeCount;

// --- Slashing ---
address public remediationPool;     // Receives slashed security tokens for depositor claims

// --- Governance ---
// Uses OZ AccessControl (DEFAULT_ADMIN_ROLE for Fireblocks multisig)
```

### Active Validator Check (Dual-Layer)

A validator is active only if they meet **both** thresholds:

```solidity
function isActiveValidator(address account) external view returns (bool) {
    ValidatorRecord storage v = validators[account];
    return v.status == ValidatorStatus.Active
        && v.effectiveUpStake >= minimumUpStake           // participation check
        && totalSecurityStakeUSD(account) >= minimumSecurityStakeUSD;  // security check
}

function totalSecurityStakeUSD(address account) public view returns (uint256 totalUSD) {
    ValidatorRecord storage v = validators[account];
    uint256 length = _acceptedSecurityTokens.length();
    for (uint256 i; i < length; ++i) {
        address token = _acceptedSecurityTokens.at(i);
        uint256 amount = v.securityStakes[token];
        if (amount > 0) {
            totalUSD += _getUSDValue(token, amount);
        }
    }
}
```

**Note:** `totalSecurityStakeUSD()` iterates accepted tokens — O(k) where k = number of accepted token types (expected: 4-6). NOT called in the hot path of signature verification; `isActiveValidator()` can cache a `lastKnownSecurityUSD` that is updated on stake/unstake and periodically refreshed to account for price movements.

### Slashing Targets (Separated)

On slash, security tokens are the **primary** target and $UP is the **secondary** target:

```solidity
// Primary: slash security stake (real economic deterrent)
// Slashed tokens flow to remediationPool for depositor claims
uint256 securitySlashBps = 5000;  // e.g., 50% of security stake

// Secondary: slash $UP (alignment penalty)
uint256 upSlashBps = 1000;        // e.g., 10% of $UP stake
```

### View Functions (Read by StakedECDSAPPSOracle)

| Function | Returns | Description |
|---|---|---|
| `isActiveValidator(address)` | `bool` | Dual-layer check: UP stake >= minimum AND security stake USD >= minimum AND status == Active |
| `getQuorum()` | `uint256` | `max(1, floor(activeCount * 2 / 3) + 1)` — BFT-safe (O(1)) |
| `getActiveValidatorCount()` | `uint256` | Returns `activeCount` counter (O(1)) |
| `getActiveValidators()` | `address[]` | Iterates registry, filters active (for off-chain consumers, not called on-chain) |
| `getRegisteredValidators()` | `address[]` | Full registry (stable set for p2p network sync) |
| `getConfigVersion()` | `uint256` | Current registry version (only changes on join/full exit) |
| `totalSecurityStakeUSD(address)` | `uint256` | Aggregate USD value of validator's security deposits across all accepted tokens |
| `getAcceptedSecurityTokens()` | `address[]` | List of tokens accepted as security stake |

### External Functions

#### Validator Lifecycle

| Function | Access | Description |
|---|---|---|
| `stakeUP(uint256 amount, bytes calldata publicKey)` | Anyone | Stake $UP tokens. Adds to registry if new (increments configVersion). Checks both thresholds for active set |
| `stakeSecurityToken(address token, uint256 amount)` | Registered validator | Deposit security collateral (ETH, WBTC, etc.). May transition to Active if crossing USD threshold |
| `addUpStake(uint256 amount)` | Registered validator | Add more $UP. May transition to Active if crossing UP threshold |
| `requestUnstakeUP(uint256 amount)` | Active/Registered | Start cooldown for $UP. Reduces effectiveUpStake immediately. Decrements activeCount if dropping below threshold |
| `requestUnstakeSecurityToken(address token, uint256 amount)` | Active/Registered | Start cooldown for security token. Decrements activeCount if USD value drops below threshold |
| `executeUnstake()` | Exiting validator | Withdraw all pending unstakes (UP + security) after cooldown expires. If full exit: status=Exited, removed from registry |
| `cancelUnstake()` | Exiting validator | Cancel all pending unstakes, restore stakes. May re-enter active set |

**Registry vs. Active set updates:**
- `stakeUP()` (new validator) → registry grows, configVersion++, activeCount++ (if both thresholds met)
- `stakeSecurityToken()` → registry unchanged, activeCount may increment (if security threshold now met)
- `addUpStake()` → registry unchanged, activeCount may increment
- `requestUnstakeUP()` / `requestUnstakeSecurityToken()` → registry unchanged, activeCount may decrement, configVersion unchanged
- `executeUnstake()` (full) → registry shrinks, configVersion++
- Slashing → registry unchanged, configVersion unchanged, activeCount decremented

No sync step needed — the oracle reads live state via `isActiveValidator()`.

#### Dispute Mechanism (Optimistic)

Two reference models are available. Both can coexist — Option B is the primary path (no contract changes to the oracle), Option C adds an on-chain audit trail at the cost of extra storage writes.

##### Option B — Consensus-Based Reference (Preferred)

The round leader (who collects BFT consensus + signatures off-chain) submits the dispute. The reference PPS is the consensus value that the honest quorum agreed on.

| Function | Access | Description |
|---|---|---|
| `disputeWithConsensus(address validator, address strategy, uint256 deviantPPS, bytes calldata deviantSig, uint256 consensusPPS, bytes[] calldata quorumSigs)` | Anyone (bonds UP) | Challenge a validator using consensus PPS as reference |
| `resolveDispute(uint256 disputeId)` | Anyone (after window) | Resolve based on verified evidence |
| `resolveDisputeByAdmin(uint256 disputeId, bool slashValidator)` | Admin | Override resolution for edge cases |

**Flow:**
1. Challenger calls `disputeWithConsensus()`, posting `disputeBond` in UP tokens
2. Contract verifies the consensus PPS has valid quorum signatures using the same EIP-712 domain separator and `UPDATE_PPS_TYPEHASH` as `StakedECDSAPPSOracle`
3. Contract recovers the deviant validator's address from `deviantSig` and verifies they signed a different PPS for the same strategy+nonce
4. Resolution checks `|deviantPPS - consensusPPS| / consensusPPS > deviationThresholdBps`
5. If deviation exceeds threshold: validator slashed, challenger gets bond back + reward
6. If within threshold: challenger loses bond (distributed to disputed validator)

**Why this works:** The consensus PPS is the value the honest majority agreed on via BFT. A validator who signed a significantly different value was either malicious or faulty. No on-chain PPS storage needed — the signatures themselves are the evidence.

**Limitation:** Requires the challenger to have collected the quorum signatures off-chain. In practice, the round leader always has these.

##### Option C — PPS Log Reference (On-Chain Audit Trail)

`StakedECDSAPPSOracle` stores accepted PPS values on successful `forwardPPS()` calls, providing an on-chain reference for disputes.

**Additional storage in StakedECDSAPPSOracle:**
```solidity
struct PPSRecord {
    uint256 pps;
    uint256 timestamp;
}
mapping(address strategy => PPSRecord) public lastAcceptedPPS;
```

On every successful `forwardPPS()`, the oracle writes `lastAcceptedPPS[strategy] = PPSRecord(pps, block.timestamp)`.

| Function | Access | Description |
|---|---|---|
| `disputeWithLog(address validator, address strategy, uint256 deviantPPS, bytes calldata deviantSig)` | Anyone (bonds UP) | Challenge a validator using the on-chain PPS log as reference |
| `resolveDispute(uint256 disputeId)` | Anyone (after window) | Resolve based on on-chain log |
| `resolveDisputeByAdmin(uint256 disputeId, bool slashValidator)` | Admin | Override resolution for edge cases |

**Flow:**
1. Challenger calls `disputeWithLog()`, posting `disputeBond` in UP tokens
2. Contract reads `lastAcceptedPPS[strategy]` from `StakedECDSAPPSOracle` as the reference
3. Contract recovers the deviant validator from `deviantSig` and verifies the signed PPS
4. Resolution checks deviation against on-chain reference
5. Same slash/bond resolution as Option B

**Trade-off:** Extra SSTORE on every `forwardPPS()` call (~20k gas for cold slot, ~5k warm), but provides a fully on-chain dispute path without needing off-chain signature collection. Useful as a fallback if the round leader is unavailable or compromised.

##### Common Dispute Infrastructure

Both options share:
- `disputeBond`: UP amount challenger must post
- `deviationThresholdBps`: e.g., 100 = 1% max acceptable deviation
- `disputeWindow`: time after PPS forwarded during which disputes can be raised
- `DisputeStatus`: Pending → Resolved | Rejected
- Admin override via `resolveDisputeByAdmin()` for edge cases

#### Incorrect PPS Slashing

**Background:** The oracle uses off-chain reporting (OCR), not on-chain aggregation. The round leader collects signatures from validators during the proposal phase and submits one aggregated result on-chain. This means each validator produces exactly one ECDSA signature per strategy per nonce — equivocation (two different ECDSA signatures for the same nonce) is not possible by design.

**What IS possible:** A validator consistently reports incorrect PPS values during the off-chain proposal phase. The validator's Ed25519 signature (used in the p2p network for proposal signing) serves as proof of what they attested to. The round leader or any observer with access to the proposal messages can challenge this.

| Function | Access | Description |
|---|---|---|
| `slashValidator(address validator, address strategy, uint256 reportedPPS, bytes calldata validatorProposalSig, uint256 consensusPPS, bytes[] calldata quorumSigs)` | Anyone (bonds UP) | Prove a validator reported incorrect PPS during off-chain proposal phase |

**Flow:**
1. Challenger submits the validator's Ed25519 proposal signature proving they attested to `reportedPPS`
2. Contract verifies the consensus PPS via quorum ECDSA signatures (same as Option B dispute)
3. Contract verifies the Ed25519 signature against the validator's registered `publicKey` (stored at registration in `ValidatorRecord.publicKey`)
4. If `|reportedPPS - consensusPPS| / consensusPPS > deviationThresholdBps`, the validator is slashed
5. No dispute window needed — the evidence is cryptographically verifiable

**Ed25519 verification:** Requires an Ed25519 precompile or library. If not available on the target chain, this falls back to the optimistic dispute mechanism (Option B) where the round leader submits the challenge and the contract relies on the ECDSA quorum signatures as the reference without verifying the proposal signature directly.

**On slash:** `validators[addr].status = Slashed`, `activeCount--`. The validator remains in the registry (configVersion unchanged, p2p network unaffected) but is immediately excluded from `isActiveValidator()` checks. No sync needed — the oracle's view function returns false for slashed addresses. In-flight rounds using the slashed validator's signatures will fail quorum at verification time.

#### Admin Functions

| Function | Access | Description |
|---|---|---|
| `setMinimumUpStake(uint256)` | Admin | Update minimum $UP stake (with timelock) |
| `setMinimumSecurityStakeUSD(uint256)` | Admin | Update minimum security stake in USD (with timelock) |
| `addSecurityToken(address token, address priceFeed)` | Admin | Add accepted security token with its Chainlink price feed |
| `removeSecurityToken(address token)` | Admin | Remove security token from accepted list (with timelock + grace period for validators to rebalance) |
| `setDisputeWindow(uint256)` | Admin | Update dispute window duration |
| `setDisputeBond(uint256)` | Admin | Update challenger bond amount |
| `setDeviationThreshold(uint256)` | Admin | Update acceptable deviation |
| `setRemediationPool(address)` | Admin | Set/update the remediation pool address |
| `emergencySlash(address validator)` | Admin | Slash validator immediately (governance escape hatch) |

All parameter changes should have a **timelock** (e.g., 3 days) to prevent governance attacks, except emergency functions.

---

## Quorum Calculation (BFT-Safe)

BFT requires `n ≥ 3f + 1` where `f` is max Byzantine validators. To guarantee safety, any two quorums must overlap by more than `f` nodes, which requires:

```
quorum = max(1, floor(activeValidatorCount * 2 / 3) + 1)
```

This ensures two competing quorums overlap by at least `quorum * 2 - n` validators, which always exceeds `f`.

| Validators (n) | Quorum | Max Byzantine (f) | Quorum Overlap | Safe? |
|---|---|---|---|---|
| 1 | 1 | 0 | — | Yes |
| 2 | 2 | 0 | 2 | Yes |
| 3 | 3 | 0 | 3 | Yes |
| 4 | 3 | 1 | 2 > 1 | Yes |
| 5 | 4 | 1 | 3 > 1 | Yes |
| 7 | 5 | 2 | 3 > 2 | Yes |
| 10 | 7 | 3 | 4 > 3 | Yes |
| 13 | 9 | 4 | 5 > 4 | Yes |

**Why not configurable numerator/denominator?** With a naive 67/100 ratio, `n=10` gives quorum=6. Two quorums of 6 overlap by only 2, while `f=3` — a single Byzantine coalition could get two conflicting proposals approved. The `floor(n*2/3)+1` formula is the standard BFT-safe threshold and is hardcoded to prevent misconfiguration.

---

## Multi-Chain Design

Each chain gets its own `ValidatorStaking` + `StakedECDSAPPSOracle` deployment. Validators must stake independently on each chain where they want to operate. This is simpler than cross-chain staking and matches the existing model where SuperGovernor + ECDSAPPSOracle are per-chain.

**Cross-chain coordination is off-chain** — validators coordinate which chains they serve through off-chain channels.

**Future optimization:** A cross-chain slashing relay via LayerZero could propagate slashing events across chains, but this is not needed for v1.

---

## Canonical PPS Computation Specification (Reference Algorithm)

### The Problem

The dispute mechanism compares a validator's `submittedPPS` against a reference and slashes if deviation exceeds `deviationThresholdBps`. But PPS for a SuperVault is not an objectively observable market quantity — it is the **output of a computation model** that combines:

- Morpho lending position valuations
- Pendle PT amortized oracle pricing (model-dependent — linear interpolation from purchase price to maturity)
- Cross-chain asset valuations
- Fee accounting (unrealized performance fees, HWM tracking)
- Hook-specific position valuations for future vault types

Two honest validators running slightly different implementations can produce legitimately different PPS values. Differences arise from:

- **Rounding**: `mulDiv` with `Math.Rounding.Floor` vs `Math.Rounding.Ceil` at any intermediate step
- **Oracle read ordering**: reading Pendle oracle before vs after Morpho oracle within the same block can yield different intermediate values if one oracle was updated in between
- **Edge case handling**: how to price a PT whose underlying SY has temporarily depegged, or a Morpho market at 100% utilization where the IRM produces extreme values
- **Fee timing**: whether unrealized fees are netted before or after position valuation

This means `deviationThresholdBps` is not measuring fraud — it is measuring **implementation divergence**. Setting it too tight slashes honest validators with slightly different code. Setting it too loose lets actual manipulation through. There is no correct threshold without a single correct algorithm.

### What's Needed

A **Canonical PPS Computation Specification**: a versioned, deterministic, step-by-step algorithm that is the sole authoritative definition of PPS for each vault type. It must specify:

- The exact sequence of oracle reads and the order in which positions are valued
- The exact rounding mode at every arithmetic step
- The exact handling of every edge case (depegged underlyings, stale sub-oracles, zero-liquidity positions, negative yield scenarios)
- The exact fee accounting method (gross vs net, when unrealized fees are deducted)
- The exact formula per vault type (encoded in `IValidatorStakingVaultPPSHelper` — not an independent "reference price" computation, but a **verifier** for the canonical algorithm's output)

This transforms the dispute mechanism from "is this PPS correct?" (subjective, undecidable) into "does this PPS match the output of Algorithm v3.2 given inputs I?" (objective, verifiable).

### Architectural Consequence: Optimistic Verification

The `IValidatorStakingVaultPPSHelper` should NOT be an independent on-chain PPS calculator (which would be as complex and error-prone as the off-chain computation). Instead, it should be a **verifier contract** that, given a claimed PPS and the input state, can confirm or deny that the canonical algorithm produces that output.

This works as follows:

1. The canonical algorithm is implemented as an **open-source reference client** (e.g., Python or TypeScript package) that all validators must run
2. The `IValidatorStakingVaultPPSHelper` implements the same logic in Solidity, or a simplified version that checks key intermediate values (position valuations, fee amounts) rather than re-deriving everything from scratch
3. Disputes submit not just the `submittedPPS` and `referencePPS`, but also the **intermediate computation trace** (position values, oracle readings), which the on-chain verifier can spot-check

This is essentially **an optimistic rollup architecture for PPS computation**: assume the validator's output is correct, allow challenges that demonstrate a different output from the canonical algorithm given the same inputs, and slash on proven divergence.

---

## Deterministic Input State Definition

### The Problem

Even with a single canonical algorithm, two validators can produce different PPS values if they read chain state at different moments. On-chain state changes every block: oracle prices update, positions accrue interest, fees accumulate. The algorithm is a pure function `f(state) → PPS`, but if Validator A reads state at block N and Validator B reads at block N+1, they compute different PPS values — both correctly.

PPS updates happen 5-10 times per day, not every block. Each round must pin the exact input state.

### Solution: Explicit Multi-Block Specification (Option C)

Each PPS update round specifies an **input block number per chain**. The round leader proposes: "this round computes PPS for SuperUSDC-Flagship using Ethereum block 21,456,789 and Base block 34,567,890." All validators compute `f(state_at_those_blocks) → PPS` and sign the result.

This is analogous to Ethereum's attestation mechanism: validators attest to a specific state root at a specific slot, not to "whatever the state is when I happen to check."

**Why not timestamp-based or anchor-chain pinning?** Timestamp-based pinning (use latest block on each chain where `timestamp ≤ T`) introduces edge cases with non-monotonic block timestamps and reorgs. Anchor-chain pinning (derive foreign blocks from home chain timestamp) has the same problem. Explicit block numbers per chain are unambiguous — the round leader proposes them, validators either agree or don't.

### Multi-Chain State Pinning

For vaults with cross-chain positions (e.g., a vault on Base holding Ethereum mainnet positions via Bundler), the round includes block numbers for every chain whose state is needed:

```solidity
struct PPSRoundInput {
    address strategy;
    uint256[] chainIds;        // chains involved in computation
    uint256[] blockNumbers;    // pinned block per chain (same index)
    uint256 algorithmVersion;  // canonical algorithm version (see §Algorithm Versioning)
}
```

The EIP-712 signing payload includes these pinned blocks — validators sign "PPS = X for strategy S given state at blocks [B1, B2, ...]", not just "PPS = X for strategy S."

### On-Chain Verification Constraint

The on-chain verifier **cannot access historical state** — `BLOCKHASH` only goes back 256 blocks (~50 minutes on mainnet). Disputes raised hours later cannot re-read state at the pinned blocks.

This makes the **computation trace mandatory** for disputes. The dispute must include the intermediate oracle readings and position values that were true at those blocks. The verifier checks:

1. **Internal consistency**: given these claimed inputs, does the canonical algorithm produce the claimed PPS?
2. **Input authenticity** (optional, if within 256 blocks): do the claimed inputs match actual state at the pinned blocks via `BLOCKHASH` verification?

If the dispute is raised outside the 256-block window, input authenticity relies on the optimistic assumption — the trace is accepted unless a counter-challenge proves the inputs were fabricated. This is a two-layer fraud proof: first prove the algorithm was applied incorrectly (given claimed inputs), then optionally prove the claimed inputs were wrong.

### Updated Dispute Struct

```solidity
struct Dispute {
    address challenger;
    address validator;
    address strategy;
    uint256 submittedPPS;
    uint256 referencePPS;
    uint256[] chainIds;          // chains involved in computation
    uint256[] blockNumbers;      // pinned block per chain (same index as chainIds)
    uint256 timestamp;
    uint256 bondAmount;
    DisputeStatus status;
}
```

---

## Algorithm Versioning & Upgrade Protocol

### The Problem

SuperVaults are not static. New vault types get integrated (new Pendle markets, new Morpho deployments, new hook types, future protocol integrations). When the canonical PPS algorithm must change — to support a new position type, fix a pricing edge case, or update fee logic — all validators must switch to the new version simultaneously. If they don't:

- Some validators run v3.1, others run v3.2
- Both groups produce "correct" PPS according to their respective algorithm versions
- Neither group may reach quorum alone
- The dispute mechanism can't distinguish version mismatch from fraud

This is exactly what happens in Ethereum hard forks if nodes don't upgrade in time.

### Solution: Algorithm Version Registry

An explicit registry, either in `ValidatorStaking` or a dedicated governance contract:

```solidity
struct AlgorithmVersion {
    uint256 activationRound;     // first round where this version is required
    uint256 gracePeriodRounds;   // rounds after activation where previous version is also accepted
    bytes32 codeHash;            // hash of reference client at this version (coordination signal)
}

// vaultType → current version number
mapping(bytes32 vaultType => uint256) public currentAlgorithmVersion;

// vaultType → version number → AlgorithmVersion
mapping(bytes32 vaultType => mapping(uint256 => AlgorithmVersion)) public algorithmVersions;
```

**Governance flow:**
1. Propose: "starting from round N, vaultType X uses algorithm v3.2" (timelocked, e.g., 3 days)
2. During grace period (rounds N to N + gracePeriodRounds): both v3.1 and v3.2 outputs are accepted
3. After grace period: only v3.2 is accepted, v3.1 submissions are disputable

**Grace period semantics:** During the transition window, a PPS submission is valid if it matches *either* the old or new algorithm version. This is a union model — prioritizes liveness over strict correctness. The alternative (require quorum agreement on the same version) is safer but risks stalling updates if validators upgrade at different speeds.

### Updated Signing Payload

The PPS signature includes the algorithm version, making every attestation self-describing:

```
// Current ECDSAPPSOracle:
// sign(strategy, pps, timestamp, strategyNonce)

// Proposed StakedECDSAPPSOracle:
// sign(strategy, pps, timestamp, strategyNonce, algorithmVersion, chainIds, blockNumbers)
```

`UPDATE_PPS_TYPEHASH` changes to:
```solidity
keccak256("UpdatePPS(address strategy,uint256 pps,uint256 timestamp,uint256 strategyNonce,uint256 algorithmVersion,uint256[] chainIds,uint256[] blockNumbers)")
```

This is a breaking change from the current `ECDSAPPSOracle` signing format — one of the reasons `StakedECDSAPPSOracle` is a new contract rather than a modification.

### Reference Client Requirements

- The canonical algorithm is an **open-source reference client** (Python or TypeScript), tagged per version (git tags, deterministic builds)
- The `codeHash` in the registry is the hash of the reference client at that tag — a coordination signal so validators can verify they're running the correct version
- The `codeHash` is NOT enforced on-chain (the contract can't verify what code a validator actually ran). Output divergence is caught by the dispute mechanism regardless
- Multiple independent implementations are possible (like Ethereum's multi-client model) as long as they produce identical outputs for the canonical algorithm spec

### Interaction with Disputes

- Disputes verify against the algorithm version that was active at the time of submission
- A PPS submitted under v3.1 during v3.1's active period cannot be retroactively disputed using v3.2 logic
- If v3.1 had a known bug, governance uses `emergencySlash` — the automated dispute mechanism only handles version-consistent verification
- During the grace period, the dispute must specify which version the challenger is verifying against

---

## Economic Security Architecture

### The Problem: Circular Security

$UP-only staking creates a circular dependency: $UP must have sufficient market value for slashing to be credible, but $UP derives value partly from the validator network it's supposed to secure. Until $UP achieves deep liquidity, a rational actor can compute that the profit from manipulating PPS exceeds the cost of being slashed — making slashing a fee on fraud, not a deterrent.

### Solution: Dual-Layer Staking

Separate the two functions that staking serves:

**Layer 1 — Participation Rights ($UP):** $UP staking grants the right to be a validator. This is an alignment function — validators must hold and stake $UP to participate. $UP is NOT the primary slashing target.

**Layer 2 — Economic Security (ETH + Blue Chips):** ETH, WETH, wstETH, WBTC, cbBTC provide the economic security bond. These assets have deep liquidity and stable USD-denominated value. Slashing from these assets constitutes real economic loss regardless of $UP price dynamics.

### Slashing Flow

```
On slash:
1. Security tokens slashed first (primary deterrent)
   → Slashed tokens flow to RemediationPool for depositor claims
2. $UP slashed second (alignment penalty)
   → $UP burned or sent to protocol treasury
```

### USD Valuation

`totalSecurityStakeUSD(validator)` aggregates the USD value of security deposits across accepted tokens using Chainlink price feeds. For v1, only highly liquid assets with battle-tested Chainlink feeds (ETH/USD, WBTC/USD, cbBTC/USD) are accepted, minimizing oracle dependency risk.

### Roadmap

**Phase 1 — Native Multi-Asset Staking (v1):**
- ValidatorStaking accepts $UP + ETH/WBTC/cbBTC directly
- Chainlink price feeds for USD valuation
- Simple, no external dependencies beyond Chainlink
- Sufficient for initial validator set of 3-10 validators

**Phase 2 — AVS Restaking (medium-term):**
- Register PPS validation as an EigenLayer AVS or Symbiotic vault
- Validators restake ETH/LSTs through the AVS, inheriting Ethereum's economic security
- Slashing conditions defined by the canonical PPS algorithm's dispute mechanism
- Dramatically increases available security without validators sourcing new capital

**Phase 3 — Dynamic Security Ratio (long-term):**
- Define `securityRatio = totalValidatorSecurityStakeUSD / totalSecuredTVL`
- Enforce `securityRatio >= minimumSecurityRatio` (e.g., 5%)
- When ratio drops: incentive mode activates first (higher validator rewards from performance fees), throttle mode as circuit breaker if ratio drops below critical threshold
- The ValidatorStaking interface should be designed now to not preclude this, even though it's not implemented in v1

### Interface Future-Proofing for AVS

Even in v1, the contract should expose:

```solidity
// Future AVS adapters can report restaked collateral through this interface
function reportExternalSecurityStake(address validator, uint256 usdValue) external;  // reserved, not implemented in v1
```

This function is a no-op in v1 but reserves the interface slot for Phase 2 AVS integration without requiring contract redeployment.

---

## Post-Dispute Remediation

### The Gap

The dispute flow terminates at: challenger wins → validator slashed, challenger rewarded. There is no mechanism for addressing the **economic damage inflicted on users** who transacted against an incorrect PPS during the window between PPS submission and dispute resolution.

Slashing is deterrence (punishing the validator) and incentive (rewarding the challenger). It is not restitution (making harmed users whole).

### The Damage Model

**Case A — PPS Too High (Overstated NAV):**
- Depositors harmed: received fewer shares than deserved (paid inflated price per share)
- Redeemers benefit: received more assets than shares were worth
- Net effect: remaining depositors diluted

**Case B — PPS Too Low (Understated NAV):**
- Depositors benefit: received more shares than deserved, diluting existing holders
- Redeemers harmed: received fewer assets than shares were worth
- Net effect: existing depositors diluted by underpriced new shares

**ERC-7540 complication:** SuperVaults use async redemptions where `requestRedeem()` and `executeRequest()` happen at different blocks. The damage computation must trace which PPS was active at each operation. All data is on-chain but non-trivial to reconstruct.

### Primary Mitigation: Soft Finalization (Recommended)

**PPS updates should have a soft finalization period during which user operations execute at the previous (undisputed) PPS, not the newly submitted one.** The new PPS becomes active only after the dispute window closes without a challenge.

This eliminates the exposure window entirely. The latency cost is minimal — PPS updates happen 5-10 times per day, so users already transact at prices that are hours stale. Adding one dispute window (~1 hour) of additional staleness is negligible.

```solidity
// In StakedECDSAPPSOracle / SuperVaultAggregator:
struct PendingPPS {
    uint256 pps;
    uint256 submittedAt;
    bool finalized;
}
mapping(address strategy => PendingPPS) public pendingUpdates;

// User operations use the last finalized PPS, not the pending one
function getActivePPS(address strategy) external view returns (uint256) {
    return finalizedPPS[strategy];  // not pendingUpdates[strategy].pps
}

// After dispute window passes without challenge:
function finalizePPS(address strategy) external {
    PendingPPS storage p = pendingUpdates[strategy];
    require(block.timestamp >= p.submittedAt + disputeWindow, "DISPUTE_WINDOW_OPEN");
    finalizedPPS[strategy] = p.pps;
    p.finalized = true;
}
```

Soft finalization should be the default for all vaults. Governance can opt specific vaults out (for time-sensitive operations) at the cost of accepting remediation risk.

### Fallback: Remediation Pool + Claims

For cases where soft finalization is bypassed or insufficient (edge cases, bugs in delay mechanism), a remediation pool provides post-facto compensation.

#### Slashed Fund Routing

```solidity
uint256 public challengerShareBps = 3000;  // 30% to challenger (incentive)
// Remaining 70% to remediation pool (restitution)
```

On successful dispute resolution:
1. Security tokens slashed → 70% to `RemediationPool`, 30% to challenger
2. $UP slashed → 70% to `RemediationPool`, 30% to challenger
3. Challenger also recovers their dispute bond

#### Damage Estimation (Off-Chain)

When a dispute resolves, an off-chain process estimates per-user damage:

```
For each transaction T during the disputed PPS window:
    if T is deposit/mint:
        loss = |T.amount / submittedPPS - T.amount / correctPPS| * correctPPS
    if T is redeem/withdraw:
        loss = |T.shares * submittedPPS - T.shares * correctPPS|
    claimable[T.user] += loss
```

The `correctPPS` is the `referencePPS` from the successful dispute (canonical algorithm output for the pinned input state).

#### Claims Process (Merkle-Based)

```solidity
contract RemediationPool {
    // Funded by slashing events
    mapping(uint256 disputeId => bytes32) public remediationRoots;
    mapping(uint256 disputeId => mapping(address => bool)) public claimed;

    function publishRemediationRoot(
        uint256 disputeId,
        bytes32 merkleRoot,
        uint256 totalClaimable
    ) external onlyGovernance;

    function claim(
        uint256 disputeId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;
}
```

1. Dispute resolves → `resolveDispute()` emits event with disputed PPS, correct PPS, affected time window, strategy
2. Off-chain damage estimation produces merkle tree of (address, claimAmount) pairs
3. Governance publishes merkle root to `RemediationPool`
4. Affected users claim against proof

#### The Insufficiency Problem

Slashed amounts will almost certainly not cover full damage in severe cases. Example:
- Validator security stake: $50K in ETH. Slash 50% → $25K slashed
- Remediation pool receives 70% = $17.5K
- During 1-hour dispute window: $2M in deposits at PPS that's 50bps off
- User losses: $2M * 0.005 = $10K → pool covers it
- But at $20M volume: losses = $100K → pool covers 17.5%

**Resolution: pro-rata distribution.** If the pool covers 52% of total claims, every claimant receives 52% of their individual claim. Fairest and simplest.

#### Three-Tier Safety Net

1. **Validator stake** → slashed, funds to remediation pool (automatic)
2. **Insurance Fund** → tops up remediation pool when slashed amount insufficient (governance-authorized transfer)
3. **Pro-rata haircut** → if both are insufficient, distribute available funds proportionally

### Dispute Window Implications

- The dispute window is the maximum exposure window (with soft finalization, exposure is zero for normal operations)
- `resolveDispute()` must emit sufficient data for off-chain damage estimation: disputed PPS, correct PPS, affected strategy, time window start/end
- The slashing flow must route funds to `remediationPool` address, not 100% to challenger

### Implementation Priority

The interfaces should be designed now (event signatures, fund routing, `remediationPool` address in storage). Full claims mechanism can follow:
- **v1**: Soft finalization + `remediationPool` address + fund routing + events
- **v1.1**: `RemediationPool` contract with merkle claims
- **v2**: Automated damage estimation, insurance fund integration

---

## Security Considerations

1. **No GOVERNOR_ROLE needed**: ValidatorStaking doesn't need any role on SuperGovernor. The validator set is read directly by StakedECDSAPPSOracle via view functions. The only governance action is pointing `setActivePPSOracle()` to the new oracle (one-time, done by existing SUPER_GOVERNOR_ROLE).

2. **O(1) hot path**: `isActiveValidator()` and `getQuorum()` are both O(1) — no iteration. `activeCount` is maintained as a counter on every state transition. `getActiveValidators()` iterates the registry but is only for off-chain consumers, never called in a transaction context.

3. **Registry stability for p2p network**: The registry (`_registry` EnumerableSet) and `configVersion` only change on new joins and full exits. Slashing, partial unstakes, and threshold changes do NOT touch the registry or version — they only affect the derived active set. This means the off-chain p2p network can rely on a stable validator list between config versions and derive the active subset locally.

4. **Dispute reference accuracy**: Option B uses the BFT consensus PPS as reference (reliable — it's what the honest majority agreed on). Option C uses the last accepted on-chain PPS (may lag if updates are infrequent). The `deviationThresholdBps` must be generous enough (e.g., 100-500 bps) to avoid false positives, especially for Option C where timing differences between the log and the dispute can cause drift.

5. **Admin escape hatch**: `emergencySlash` exists for cases where the dispute mechanism fails (e.g., a validator submits slightly-off PPS values that stay within threshold but are still manipulative over time).

6. **Reentrancy**: Use `ReentrancyGuard` on all functions that transfer tokens (stake, unstake, dispute resolution).

7. **Unstake cooldown vs. dispute window**: The unstake cooldown must be longer than the dispute window. Otherwise a validator could submit a bad PPS, immediately unstake, and withdraw before being challenged.

8. **Chainlink dependency for security valuation**: The security stake USD valuation depends on Chainlink price feeds. A stale or manipulated feed could cause incorrect slash amounts. Mitigations: only accept tokens with highly liquid Chainlink feeds (ETH, WBTC, cbBTC), add staleness checks (revert if feed hasn't updated within N hours), and use TWAP or multi-oracle fallbacks for additional safety.

9. **Security stake price volatility**: A validator's security stake in ETH/WBTC can drop below `minimumSecurityStakeUSD` due to market movements without any unstake action. The contract should periodically check (or allow anyone to trigger a check) whether validators still meet the security threshold, and remove from active set if not. This is a liveness check, not a slash — the validator can top up their security stake to re-enter.

---

## Files to Create

| File | Description |
|---|---|
| `src/ValidatorStaking.sol` | Dual-layer staking (UP + security tokens), slashing, disputes |
| `src/oracles/StakedECDSAPPSOracle.sol` | New PPS oracle reading from ValidatorStaking (fork of ECDSAPPSOracle) |
| `src/interfaces/IValidatorStaking.sol` | Interface with errors, events, structs (dual-layer types) |
| `src/RemediationPool.sol` | Receives slashed security tokens, handles depositor claims (can be minimal in v1) |
| `test/ValidatorStaking.t.sol` | Unit tests (UP staking, security staking, dual-threshold checks, slashing both layers) |
| `test/oracles/StakedECDSAPPSOracle.t.sol` | Oracle unit tests |
| `test/integration/ValidatorStakingE2E.t.sol` | Full integration test |

## Files to Read (no modifications)

| File | Why |
|---|---|
| `src/SuperGovernor.sol` | `setActivePPSOracle()` for deployment, role system |
| `src/oracles/ECDSAPPSOracle.sol` | Fork base for StakedECDSAPPSOracle |
| `src/interfaces/ISuperGovernor.sol` | Interface dependency |
| `src/interfaces/oracles/IECDSAPPSOracle.sol` | Interface to preserve for compatibility |
| `src/SuperVault/SuperVaultExecutor.sol` | Code style reference (immutable + AccessControl pattern) |

---

## Verification

1. **Unit tests**: Stake/unstake lifecycle, quorum calculation, dispute flow, equivocation slashing, admin functions, edge cases (minimum stake boundary, cooldown timing, slash during unstake)
2. **Integration test**: Full flow — validator stakes → StakedECDSAPPSOracle reads live set → sign PPS → forward to aggregator → dispute submitted → resolution → slashed validator excluded from next update
3. **Invariants**:
   - `isActiveValidator()` always consistent with staking state at current block
   - `activeCount` matches the actual count of validators with `effectiveStake >= minimumStake && status == Active`
   - Quorum always >= 1
   - Slashed validator can never pass `isActiveValidator()` check
   - `configVersion` only changes on registry mutations (join/full exit), never on slash/partial unstake
   - Registry is a superset of active set at all times
