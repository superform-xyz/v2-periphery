# ValidatorBonding Spec

## Metadata
- Project: v2-periphery
- Milestone: Validator Onboarding
- Linear Issue: N/A
- Interview Date: 2026-05-06
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

Non-upgradeable Solidity contract on Base for validator sUP token bonding. Validators bond a minimum of 1M sUP as economic commitment for PPS oracle participation. Supports Foundation loans via operator/beneficiary separation — the Foundation can bond sUP on behalf of a validator and recover it on unbond. SuperGovernor can slash misbehaving validators proportionally and remove them from the oracle set atomically via Safe multisig batching.

This is a standalone module — no on-chain coupling to ECDSAPPSOracle. The validator set is still managed by `SuperGovernor.setValidatorConfig()`. Off-chain tooling cross-references bonded operators with the oracle validator set.

## Requirements

### Functional
1. Validators self-bond sUP via `bond()` or Foundation bonds on their behalf via `bondFor()`
2. Beneficiary is immutable after first bond (prevents loan redirection)
3. Operator OR beneficiary can initiate/execute unbonding; only initiator can cancel
4. 7-day unbonding period (configurable by governor), stored as absolute deadline
5. GOVERNOR_ROLE can slash proportionally across bonded + unbonding portions
6. Slash below minimumBond → status Unbonded, removed from registry, unbonding state reset
7. Recovery path: `addBond()` for Unbonded operators with residual bond
8. delegateKey updatable by operator or beneficiary

### Non-Functional
- Non-upgradeable (manual migration for V2)
- Base-only deployment
- 5-10 validators at launch
- Gas efficiency not a priority at this scale

## Technical Design

### Architecture
```
                          ValidatorBonding (Base only)
                          ┌─────────────────────────┐
  Validator/Foundation    │  bond() / bondFor()      │
  ───── sUP ──────────>  │  requestUnbond()         │
                          │  executeUnbond()         │
                          │                          │
  Safe Multisig ────┬──>  │  slash()                 │  (GOVERNOR_ROLE)
    (batched tx)    │     └─────────────────────────┘
                    │
                    └──>  setValidatorConfig()  ──> ECDSAPPSOracle
```

### Data Model
```solidity
struct BondRecord {
    uint256 amount;              // Total sUP held (includes unbondingAmount)
    address beneficiary;         // Receives sUP on unbond (immutable)
    address delegateKey;         // Validator signing key
    uint256 unbondingDeadline;   // Absolute timestamp
    uint256 unbondingAmount;     // Portion being unbonded
    address unbondingInitiator;  // Only they can cancelUnbond
    ValidatorStatus status;      // Unbonded | Bonded | Unbonding
}
```

### Key Contracts
- `src/ValidatorBonding.sol` — Main contract (AccessControl, ReentrancyGuard, EnumerableSet)
- `src/interfaces/IValidatorBonding.sol` — Interface, errors, events

### Dependencies
- OpenZeppelin 5.3.0: AccessControl, EnumerableSet, SafeERC20, ReentrancyGuard, Math
- sUP token (standard ERC20 on Base)

## Implementation Plan

### Phase 1: Contract + Interface
- [ ] Create `IValidatorBonding.sol` (errors, events, structs, function signatures)
- [ ] Create `ValidatorBonding.sol` (full implementation)
- [ ] Constructor with validation and role setup

### Phase 2: Tests
- [ ] Unit tests for all bonding functions
- [ ] Unit tests for unbonding lifecycle
- [ ] Unit tests for slashing (proportional, edge cases)
- [ ] Unit tests for admin functions
- [ ] Access control tests
- [ ] Fuzz tests for accounting invariants

### Phase 3: Deployment
- [ ] Deployment script
- [ ] Config for Base mainnet (sUP address, minimumBond, roles)

## Test Plan
- [ ] Unit tests for: bond, bondFor, addBond, requestUnbond, executeUnbond, cancelUnbond, slash, admin setters, view functions
- [ ] Fuzz tests for: proportional slash math, bond accounting invariant, registry consistency
- [ ] Access control tests for: all role-gated functions
- [ ] Edge cases: zero amounts, slash to zero, slash below minimum with pending unbond, addBond recovery

## Risks & Mitigations
| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| Front-run executeUnbond before slash | MEV | Low | Medium | Accept for V1 (KYB'd validators), private mempool for slash txs | EigenLayer deallocation manipulation |
| Division by zero in slash | Arithmetic | Low | High | Guard: `if (bond.amount == 0) revert NOTHING_TO_SLASH()` | — |
| Proportional slash rounding | Arithmetic | Medium | Low | Math.mulDiv (overflow-safe, deterministic rounding) | EigenYields slashing |
| sUP gains transfer hooks | Token Behavior | Very Low | High | ReentrancyGuard + CEI pattern as defense-in-depth | — |
| Beneficiary overwrite via re-bond | Access Control | Medium | High | bondFor reverts if status != Unbonded or residual exists | — |
| Cancel-griefing on unbond | Operational | Medium | Medium | unbondingInitiator: only initiator can cancel | — |

## Open Questions (Resolved)
| Question | Answer | Decided By |
|----------|--------|------------|
| Permanent slash exclusion? | No — re-bonding allowed, gated by setValidatorConfig | Product |
| On-chain delegateKey uniqueness? | No — off-chain detection (complexity vs risk at 5-10 validators) | Engineering |
| Atomic slash + removal mechanism? | Safe multisig batching (SuperGovernor has no multicall) | Engineering |
| Who can request unbond? | Both operator and beneficiary | Product |
| Cancel-griefing prevention? | unbondingInitiator field — only initiator can cancel | Engineering |
| unbondingPeriod mid-flight behavior? | unbondingDeadline is absolute timestamp — existing unbonds unaffected | Engineering |
| sUP or UP for bonding? | sUP — avoids confusion with "staking UP to get sUP" | Product |

## Interview Notes
See: [interview-notes.md](./interview-notes.md)

## Technical Details
See: [technical-spec.md](./technical-spec.md)

## Research
See: [research/](./research/)

---

## Approval
- [ ] Pod Leader Approved
- Approved date: ___

## Next Steps
After approval, run: `/superform:work specs/validator-bonding/technical-spec.md`
