# ValidatorBonding Contract Design (Launch v1)

## Context

Superform is onboarding external validators for PPS oracle updates. Validators must bond sUP tokens as economic commitment. This is a **simple launch version** — Base-only, admin-slashable, no automated disputes.

The existing `SuperGovernor.setValidatorConfig()` (called by `ORACLE_MANAGER_ROLE`) continues to manage the active validator set and quorum for `ECDSAPPSOracle`. **ValidatorBonding is a standalone bonding module** — it does NOT replace or modify the oracle pipeline. SuperGovernor remains the source of truth for who can sign PPS updates.

The bonding module's purpose is:
1. Require validators to have skin in the game (1M sUP minimum)
2. Enable slashing for misbehavior
3. Track the separation between stake owner vs. stake beneficiary (Foundation loans)

---

## Architecture

```
                          ValidatorBonding (Base only)
                          ┌─────────────────────────┐
  Validator/Foundation    │  stake() / stakeFor()    │
  ───── sUP ──────────>  │  requestUnstake()        │
                          │  executeUnstake()        │
                          │                          │
  SuperGovernor ─────┬──> │  slash()                 │  (called by SuperGovernor)
    (multicall)      │    └─────────────────────────┘
                     │
                     └──> setValidatorConfig()  ──> ECDSAPPSOracle
                          (remove slashed validator from active set)
```

**Key design:** Slashing and validator removal happen atomically via SuperGovernor multicall. When a validator misbehaves, SuperGovernor calls both `ValidatorBonding.slash()` and `setValidatorConfig()` (with the updated set minus the slashed operator) in a single transaction. This ensures a slashed validator is immediately removed from the oracle's permissioned set — no window where they're slashed but still signing.

ValidatorBonding itself has no on-chain integration with ECDSAPPSOracle. The atomic guarantee comes from SuperGovernor's multicall, not from contract-to-contract coupling.

---

## Contract: `ValidatorBonding.sol`

Non-upgradeable. Deployed on Base only. Uses OZ `AccessControl`.

### Storage

```solidity
IERC20 public immutable SUP_TOKEN;       // sUP token on Base
uint256 public minimumBond;              // e.g., 1_000_000e18 (1M sUP)
uint256 public unbondingPeriod;          // e.g., 7 days

enum ValidatorStatus {
    Unbonded,     // Not bonded or fully withdrawn
    Bonded,       // Active bond >= minimumBond
    Unbonding     // Unstake requested, in cooldown
}

struct BondRecord {
    uint256 amount;              // Total sUP bonded
    address beneficiary;         // Who receives sUP on unstake (validator or Foundation)
    address delegateKey;         // Validator's signing key (for off-chain coordination)
    uint256 unbondingStartTime;  // 0 = no pending unbond
    uint256 unbondingAmount;     // Amount being unbonded
    ValidatorStatus status;
}

mapping(address operator => BondRecord) public bonds;

// Registry for enumeration
EnumerableSet.AddressSet private _operators;
```

### Owner vs. Beneficiary Separation

Two scenarios at stake time:

**Self-bonding:** A validator stakes their own sUP.
- `operator` = validator address
- `beneficiary` = validator address
- On unstake, sUP returns to the validator

**Foundation loan:** The Superform Foundation provides sUP to a KYB'ed entity.
- `operator` = the entity's address (they operate the validator)
- `beneficiary` = Foundation multisig address
- On unstake, sUP returns to the Foundation
- The entity only provides a `delegateKey` for signing — they never own the sUP

The `beneficiary` is immutable once set (cannot be changed after staking). This prevents an operator with a Foundation loan from redirecting tokens to themselves.

### External Functions

#### Staking

| Function | Access | Description |
|----------|--------|-------------|
| `stake(uint256 amount, address beneficiary, address delegateKey)` | Anyone | Bond sUP. Sugar for `stakeFor(msg.sender, ...)`. |
| `stakeFor(address operator, uint256 amount, address beneficiary, address delegateKey)` | Anyone | Bond sUP on behalf of an operator. Allows Foundation to stake in a single tx. |
| `addBond(uint256 amount)` | Bonded operator | Add more sUP to existing bond. |
| `updateDelegateKey(address newKey)` | Bonded operator | Change the signing key. |

**`stakeFor()` logic:**
1. `transferFrom(msg.sender, address(this), amount)` — sUP comes from caller (could be operator or Foundation)
2. `amount >= minimumBond` required
3. Sets `beneficiary`, `delegateKey`, status = `Bonded`
4. Adds to `_operators` registry

#### Unstaking

| Function | Access | Description |
|----------|--------|-------------|
| `requestUnstake(uint256 amount)` | Operator OR beneficiary | Start unbonding. Partial (remaining >= minimumBond) or full. |
| `executeUnstake()` | Operator OR beneficiary | After `unbondingPeriod`, sends sUP to `beneficiary`. |
| `cancelUnstake()` | Operator OR beneficiary | Cancel pending unbond, re-bond tokens. |

Both the operator and beneficiary can initiate/execute/cancel unstaking. This ensures the Foundation (as beneficiary) can pull back a loan without needing the operator's cooperation.

**`requestUnstake()` logic:**
1. `msg.sender == operator || msg.sender == beneficiary`
2. If partial: `bond.amount - amount >= minimumBond` required
3. If full (`amount == bond.amount`): status = `Unbonding`
4. Sets `unbondingStartTime = block.timestamp`, `unbondingAmount = amount`
5. Only one pending unbond at a time (simplicity)

**`executeUnstake()` logic:**
1. `block.timestamp >= unbondingStartTime + unbondingPeriod` required
2. Transfers `unbondingAmount` of sUP to `beneficiary` (NOT to operator)
3. If full unstake: status = `Unbonded`, removed from `_operators`
4. If partial: status stays `Bonded`, `amount -= unbondingAmount`

#### Slashing

| Function | Access | Description |
|----------|--------|-------------|
| `slash(address operator, uint256 amount, address recipient)` | `GOVERNOR_ROLE` | Slash operator's bond. Sends slashed sUP to `recipient`. |

**`slash()` logic:**
1. Reduces `bond.amount` by `amount` (capped to available balance)
2. If operator has pending unbond, unbonding amount is reduced proportionally
3. Transfers slashed sUP to `recipient` (treasury, remediation pool, etc.)
4. If remaining bond == 0: status = `Unbonded`, removed from `_operators`
5. Emits `Slashed(operator, amount, recipient)`

**No permanent exclusion status.** Slashing just reduces the bond. Whether the operator can re-bond later is a governance decision — they'd need to `stake()` again AND be re-added to `setValidatorConfig()`. The real gatekeeping is the permissioned validator set in SuperGovernor.

**Atomic slash + removal flow (via SuperGovernor multicall):**
1. SuperGovernor batches two calls in one tx:
   - `ValidatorBonding.slash(operator, amount, treasury)`
   - `setValidatorConfig(newValidators, newQuorum, ...)` — updated set without the slashed operator
2. Validator is slashed and removed from the oracle's permissioned set atomically
3. No window where a slashed validator can still sign PPS updates

**Why slashing is admin-only:** At launch, "canonical PPS" is determined off-chain by the Superform team. Automated dispute mechanisms are future work. If a validator submits bad PPS, the team investigates off-chain and slashes via governance if warranted.

#### Admin

| Function | Access | Description |
|----------|--------|-------------|
| `setMinimumBond(uint256 newMinimum)` | `GOVERNOR_ROLE` | Update minimum bond. Existing validators below new minimum are NOT auto-ejected. |
| `setUnbondingPeriod(uint256 newPeriod)` | `GOVERNOR_ROLE` | Update unbonding period. Existing pending unbonds use their original period. |

### View Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `isBonded(address operator)` | `bool` | Status == Bonded AND amount >= minimumBond |
| `getBond(address operator)` | `BondRecord` | Full bond details |
| `getBondedOperators()` | `address[]` | All currently bonded operators |
| `getBondedOperatorCount()` | `uint256` | Count of bonded operators |
| `getDelegateKey(address operator)` | `address` | Operator's signing key |
| `getBeneficiary(address operator)` | `address` | Who receives sUP on unstake |

### Events

```solidity
event Bonded(address indexed operator, address indexed beneficiary, address delegateKey, uint256 amount);
event BondAdded(address indexed operator, uint256 amount, uint256 newTotal);
event UnstakeRequested(address indexed operator, uint256 amount, uint256 executeAfter);
event UnstakeCancelled(address indexed operator, uint256 amount);
event UnstakeExecuted(address indexed operator, address indexed beneficiary, uint256 amount);
event Slashed(address indexed operator, uint256 amount, address indexed recipient);
event DelegateKeyUpdated(address indexed operator, address oldKey, address newKey);
event MinimumBondUpdated(uint256 oldMinimum, uint256 newMinimum);
event UnbondingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);
```

---

## Upgradeability

**Non-upgradeable.** If the module needs to become more complex later (automated disputes, cross-chain, etc.), deploy a new contract and have validators migrate manually:

1. Deploy `ValidatorBondingV2`
2. Validators `requestUnstake()` from V1, wait for unbonding, `stake()` in V2
3. Or: admin function on V2 that accepts direct migration

Given the small validator set at launch (5-10), manual migration is fine.

---

## Delegation / Liquid Staking (Future Consideration)

From [SIP-6 discussion](https://superform.discourse.group/t/sip-6-establish-validator-bonding-requirements/25/3): individual sUP holders could delegate to KYB'ed validators, receiving a tokenized staking receipt (LST-like).

This is **not part of ValidatorBonding** but the architecture supports it:

- A wrapper contract could:
  1. Accept sUP deposits from delegators
  2. Call `stakeFor(validatorOperator, totalDelegated, wrapperAddress, delegateKey)`
  3. Mint an ERC20 receipt token (e.g., `vbSUP`)
  4. On withdrawal: `requestUnstake()`, wait, return sUP to delegator
- The `beneficiary` field supports this naturally — wrapper is the beneficiary
- Slashing risk passes through to delegators proportionally

Can be built as a separate contract on top of ValidatorBonding without changes to the bonding module.

---

## What This Defers (see `validator-staking.md` for full version)

| Feature | Status |
|---------|--------|
| StakedECDSAPPSOracle | Deferred — SuperGovernor still manages validator set |
| Automated disputes | Deferred — slashing is admin-governed |
| Dual-layer staking (sUP + security tokens) | Deferred — sUP only |
| Multi-chain deployment | Deferred — Base only |
| Algorithm versioning | Deferred |
| Remediation pool / claims | Deferred |
| Quorum derived from bond | Deferred — quorum set manually in SuperGovernor |

---

## Deployment

1. Deploy `ValidatorBonding` on Base:
   - `SUP_TOKEN` = sUP address on Base
   - `minimumBond` = 1,000,000e18
   - `unbondingPeriod` = 7 days
   - `DEFAULT_ADMIN_ROLE` = Superform Foundation multisig (role admin)
   - `GOVERNOR_ROLE` = SuperGovernor address (slashing, param updates)

2. Foundation stakes on behalf of loan-receiving validators via `stakeFor()`

3. Self-funding validators call `stake()` directly

4. Off-chain tooling verifies every address in `SuperGovernor.setValidatorConfig()` is also bonded in ValidatorBonding
