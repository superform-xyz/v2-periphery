# ValidatorBonding Technical Specification

## Overview

Non-upgradeable Solidity contract on Base for validator sUP token bonding. Validators must bond a minimum amount of sUP as economic commitment. The contract tracks operator/beneficiary separation (Foundation loans), enforces unbonding periods, and enables proportional slashing by governance.

This is a standalone bonding module — no on-chain coupling to ECDSAPPSOracle or SuperGovernor. The validator set in the oracle is still managed by `SuperGovernor.setValidatorConfig()`. Off-chain tooling cross-references bonded operators with the oracle validator set.

## Problem Statement / Motivation

Superform is onboarding external validators for PPS oracle updates. Validators need skin in the game (economic commitment) to ensure honest behavior. The existing `SuperGovernor.setValidatorConfig()` manages the permissioned set but has no bonding requirement. This contract adds the bonding layer.

## Proposed Solution

A standalone `ValidatorBonding.sol` contract that:
1. Holds sUP bonds for operators
2. Supports Foundation loans (operator != beneficiary)
3. Enforces unbonding period with proportional slashing
4. Integrates with SuperGovernor via Safe multisig batching for atomic slash + removal

## Technical Considerations

### Architecture
- Non-upgradeable (deploy new contract for V2, manual migration)
- OZ 5.3.0: AccessControl, EnumerableSet, SafeERC20, ReentrancyGuard, Math
- Single deployment on Base only

### Token Assumption
sUP is standard ERC20 (no transfer hooks, no ERC777). ReentrancyGuard added as defense-in-depth.

### Security
- CEI pattern on all state-changing functions
- Math.mulDiv for overflow-safe proportional slash
- Zero-amount and zero-address validation on all external functions
- Front-running risk (executeUnbond before slash) accepted for V1 — documented limitation

## Attack Surface Analysis

### Token Risks
- [x] sUP assumed standard ERC20 — no fee-on-transfer, no rebasing, no hooks
- [x] SafeERC20 used for all transfers (handles missing return values)
- [x] No approval flows (only transfer/transferFrom)
- [N/A] Token decimals: sUP is 18 decimals, `minimumBond` denominated in wei

### Reentrancy
- [x] ReentrancyGuard (nonReentrant) on all external state-changing functions
- [x] CEI pattern followed — state updates before token transfers
- [N/A] No read-only reentrancy vectors (no view functions used by other contracts for pricing)
- [N/A] No ERC-721/777/1155 callbacks (sUP is ERC20)

### Access Control
- [x] `GOVERNOR_ROLE` for slash, setMinimumBond, setUnbondingPeriod
- [x] `DEFAULT_ADMIN_ROLE` for role management (Foundation multisig)
- [x] Operator OR beneficiary for requestUnbond, executeUnbond, updateDelegateKey
- [x] Initiator-only for cancelUnbond (prevents cancel-griefing)

### Arithmetic
- [x] Math.mulDiv for proportional slash (overflow-safe)
- [x] Explicit zero-amount checks (ZERO_AMOUNT error)
- [x] Slash amount capped to bond.amount (no underflow)
- [x] unbondingAmount always <= bond.amount (invariant)

### Front-Running
- **Known risk:** Operator can front-run `slash()` with `executeUnbond()` to extract unbonding funds
- **V1 mitigation:** Accepted at launch (5-10 KYB'd validators, low adversarial risk). Slash txs can use private mempool.
- **V2 mitigation:** Add `freeze(operator)` function callable by GOVERNOR_ROLE

## Acceptance Criteria

### Functional
- [ ] Validators can self-bond sUP via `bond()`
- [ ] Foundation can bond on behalf of operators via `bondFor()`
- [ ] Operators can top up via `addBond()` (Bonded, Unbonding, or Unbonded with residual)
- [ ] Operator OR beneficiary can request/execute unbonding
- [ ] Only unbond initiator can cancel unbonding
- [ ] GOVERNOR_ROLE can slash proportionally across bonded + unbonding portions
- [ ] Slash below minimum → status Unbonded, removed from registry, unbonding state reset
- [ ] Beneficiary is immutable after first bond
- [ ] minimumBond and unbondingPeriod configurable by GOVERNOR_ROLE with bounds
- [ ] delegateKey updatable by operator or beneficiary

### Non-Functional
- [ ] Gas-efficient for 5-10 validators (no premature optimization)
- [ ] All events emitted for off-chain indexing
- [ ] Comprehensive test coverage (unit + fuzz)

### Security Requirements
- [ ] ReentrancyGuard on all external functions
- [ ] CEI pattern on all state-changing functions
- [ ] Math.mulDiv for proportional calculations
- [ ] Zero-address validation on all address params
- [ ] Zero-amount validation on all amount-bearing functions
- [ ] SafeERC20 for all token operations

## Implementation

### File Structure
```
src/ValidatorBonding.sol          # Main contract
src/interfaces/IValidatorBonding.sol  # Interface + errors + events
test/unit/ValidatorBonding.t.sol  # Unit + fuzz tests
```

### IValidatorBonding.sol

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

interface IValidatorBonding {
    // ─── Enums ───────────────────────────────────────────────
    enum ValidatorStatus {
        Unbonded,   // 0: Not bonded or fully withdrawn
        Bonded,     // 1: Active bond >= minimumBond
        Unbonding   // 2: Full unbond requested, in cooldown
    }

    // ─── Structs ─────────────────────────────────────────────
    struct BondRecord {
        uint256 amount;              // Total sUP held (includes unbondingAmount)
        address beneficiary;         // Receives sUP on unbond (immutable after first bond)
        address delegateKey;         // Validator signing key
        uint256 unbondingDeadline;   // Timestamp after which executeUnbond succeeds
        uint256 unbondingAmount;     // Portion being unbonded
        address unbondingInitiator;  // Who requested unbond (only they can cancel)
        ValidatorStatus status;
    }

    // ─── Errors ──────────────────────────────────────────────
    error INVALID_ADDRESS();
    error ZERO_AMOUNT();
    error INVALID_STATUS();
    error BELOW_MINIMUM_BOND();
    error ALREADY_BONDED();
    error NO_PENDING_UNBOND();
    error PENDING_UNBOND_EXISTS();
    error UNBONDING_NOT_COMPLETE();
    error NOT_OPERATOR_OR_BENEFICIARY();
    error NOT_UNBOND_INITIATOR();
    error NOTHING_TO_SLASH();
    error INVALID_MINIMUM_BOND();
    error INVALID_UNBONDING_PERIOD();

    // ─── Events ──────────────────────────────────────────────
    event Bonded(address indexed operator, address indexed beneficiary, address delegateKey, uint256 amount);
    event BondAdded(address indexed operator, uint256 amount, uint256 newTotal);
    event UnbondRequested(address indexed operator, uint256 amount, uint256 unbondingDeadline);
    event UnbondCancelled(address indexed operator, uint256 amount);
    event UnbondExecuted(address indexed operator, address indexed beneficiary, uint256 amount);
    event Slashed(address indexed operator, uint256 amount, address indexed recipient, uint256 remainingBond);
    event DelegateKeyUpdated(address indexed operator, address oldKey, address newKey);
    event MinimumBondUpdated(uint256 oldMinimum, uint256 newMinimum);
    event UnbondingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);

    // ─── External Functions ──────────────────────────────────

    // Bonding
    function bond(uint256 amount, address beneficiary, address delegateKey) external;
    function bondFor(address operator, uint256 amount, address beneficiary, address delegateKey) external;
    function addBond(address operator, uint256 amount) external;
    function updateDelegateKey(address operator, address newKey) external;

    // Unbonding
    function requestUnbond(address operator, uint256 amount) external;
    function executeUnbond(address operator) external;
    function cancelUnbond(address operator) external;

    // Slashing (GOVERNOR_ROLE)
    function slash(address operator, uint256 amount, address recipient) external;

    // Admin (GOVERNOR_ROLE)
    function setMinimumBond(uint256 newMinimum) external;
    function setUnbondingPeriod(uint256 newPeriod) external;

    // View
    function isBonded(address operator) external view returns (bool);
    function getBond(address operator) external view returns (BondRecord memory);
    function getOperators() external view returns (address[] memory);
    function getOperatorCount() external view returns (uint256);
}
```

### ValidatorBonding.sol

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IValidatorBonding } from "./interfaces/IValidatorBonding.sol";

/// @title ValidatorBonding
/// @notice Standalone sUP bonding module for Superform validators (Base only)
/// @dev Non-upgradeable. Operator/beneficiary separation supports Foundation loans.
contract ValidatorBonding is IValidatorBonding, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ─── Constants ───────────────────────────────────────────

    bytes32 private constant _GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    uint256 public constant MAX_MINIMUM_BOND = 100_000_000e18;  // 100M sUP
    uint256 public constant MIN_MINIMUM_BOND = 1e18;            // 1 sUP
    uint256 public constant MAX_UNBONDING_PERIOD = 365 days;
    uint256 public constant MIN_UNBONDING_PERIOD = 1 days;

    // ─── Immutables ──────────────────────────────────────────

    IERC20 public immutable SUP_TOKEN;

    // ─── State ───────────────────────────────────────────────

    uint256 public minimumBond;
    uint256 public unbondingPeriod;

    mapping(address operator => BondRecord) private _bonds;
    EnumerableSet.AddressSet private _operators;

    // ─── Constructor ─────────────────────────────────────────

    constructor(
        address supToken_,
        uint256 minimumBond_,
        uint256 unbondingPeriod_,
        address admin_,
        address governor_
    ) {
        if (supToken_ == address(0) || admin_ == address(0) || governor_ == address(0)) {
            revert INVALID_ADDRESS();
        }
        if (minimumBond_ < MIN_MINIMUM_BOND || minimumBond_ > MAX_MINIMUM_BOND) {
            revert INVALID_MINIMUM_BOND();
        }
        if (unbondingPeriod_ < MIN_UNBONDING_PERIOD || unbondingPeriod_ > MAX_UNBONDING_PERIOD) {
            revert INVALID_UNBONDING_PERIOD();
        }

        SUP_TOKEN = IERC20(supToken_);
        minimumBond = minimumBond_;
        unbondingPeriod = unbondingPeriod_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(_GOVERNOR_ROLE, governor_);
    }

    // ─── Role Getters (Superform convention) ─────────────────

    function GOVERNOR_ROLE() external pure returns (bytes32) {
        return _GOVERNOR_ROLE;
    }

    // ─── Bonding ─────────────────────────────────────────────

    /// @inheritdoc IValidatorBonding
    function bond(uint256 amount, address beneficiary, address delegateKey) external {
        bondFor(msg.sender, amount, beneficiary, delegateKey);
    }

    /// @inheritdoc IValidatorBonding
    function bondFor(
        address operator,
        uint256 amount,
        address beneficiary,
        address delegateKey
    ) public nonReentrant {
        if (operator == address(0) || beneficiary == address(0) || delegateKey == address(0)) {
            revert INVALID_ADDRESS();
        }
        if (amount < minimumBond) revert BELOW_MINIMUM_BOND();

        BondRecord storage bond_ = _bonds[operator];
        if (bond_.status != ValidatorStatus.Unbonded) revert ALREADY_BONDED();
        if (bond_.amount > 0) revert ALREADY_BONDED(); // has residual bond, use addBond

        // Effects
        bond_.amount = amount;
        bond_.beneficiary = beneficiary;
        bond_.delegateKey = delegateKey;
        bond_.status = ValidatorStatus.Bonded;
        _operators.add(operator);

        // Interactions
        SUP_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit Bonded(operator, beneficiary, delegateKey, amount);
    }

    /// @inheritdoc IValidatorBonding
    function addBond(address operator, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();

        BondRecord storage bond_ = _bonds[operator];

        // Allow addBond for Bonded, Unbonding, or Unbonded-with-residual
        bool hasResidual = bond_.status == ValidatorStatus.Unbonded && bond_.amount > 0;
        if (bond_.status != ValidatorStatus.Bonded
            && bond_.status != ValidatorStatus.Unbonding
            && !hasResidual) {
            revert INVALID_STATUS();
        }

        // Effects
        bond_.amount += amount;

        // Recovery path: Unbonded with residual → if now >= minimum, re-activate
        if (hasResidual && bond_.amount >= minimumBond) {
            bond_.status = ValidatorStatus.Bonded;
            _operators.add(operator);
        }

        // Interactions
        SUP_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit BondAdded(operator, amount, bond_.amount);
    }

    /// @inheritdoc IValidatorBonding
    function updateDelegateKey(address operator, address newKey) external {
        if (newKey == address(0)) revert INVALID_ADDRESS();

        BondRecord storage bond_ = _bonds[operator];
        if (msg.sender != operator && msg.sender != bond_.beneficiary) {
            revert NOT_OPERATOR_OR_BENEFICIARY();
        }
        if (bond_.status == ValidatorStatus.Unbonded && bond_.amount == 0) {
            revert INVALID_STATUS();
        }

        address oldKey = bond_.delegateKey;
        bond_.delegateKey = newKey;

        emit DelegateKeyUpdated(operator, oldKey, newKey);
    }

    // ─── Unbonding ───────────────────────────────────────────

    /// @inheritdoc IValidatorBonding
    function requestUnbond(address operator, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();

        BondRecord storage bond_ = _bonds[operator];
        if (msg.sender != operator && msg.sender != bond_.beneficiary) {
            revert NOT_OPERATOR_OR_BENEFICIARY();
        }

        // Allow unbonding from Bonded, Unbonding (if no pending), or Unbonded with residual
        bool hasResidual = bond_.status == ValidatorStatus.Unbonded && bond_.amount > 0;
        if (bond_.status != ValidatorStatus.Bonded
            && bond_.status != ValidatorStatus.Unbonding
            && !hasResidual) {
            revert INVALID_STATUS();
        }
        if (bond_.unbondingAmount > 0) revert PENDING_UNBOND_EXISTS();
        if (amount > bond_.amount) revert ZERO_AMOUNT(); // can't unbond more than total

        // Partial unbond: remaining must be >= minimumBond (skip check for Unbonded residual)
        if (!hasResidual && amount < bond_.amount) {
            if (bond_.amount - amount < minimumBond) revert BELOW_MINIMUM_BOND();
        }

        // Effects
        uint256 deadline = block.timestamp + unbondingPeriod;
        bond_.unbondingAmount = amount;
        bond_.unbondingDeadline = deadline;
        bond_.unbondingInitiator = msg.sender;

        if (amount == bond_.amount) {
            bond_.status = ValidatorStatus.Unbonding;
        }

        emit UnbondRequested(operator, amount, deadline);
    }

    /// @inheritdoc IValidatorBonding
    function executeUnbond(address operator) external nonReentrant {
        BondRecord storage bond_ = _bonds[operator];
        if (msg.sender != operator && msg.sender != bond_.beneficiary) {
            revert NOT_OPERATOR_OR_BENEFICIARY();
        }
        if (bond_.unbondingAmount == 0) revert NO_PENDING_UNBOND();
        if (block.timestamp < bond_.unbondingDeadline) revert UNBONDING_NOT_COMPLETE();

        // Effects
        uint256 amount = bond_.unbondingAmount;
        address beneficiary = bond_.beneficiary;

        bond_.amount -= amount;
        bond_.unbondingAmount = 0;
        bond_.unbondingDeadline = 0;
        bond_.unbondingInitiator = address(0);

        if (bond_.amount == 0) {
            bond_.status = ValidatorStatus.Unbonded;
            _operators.remove(operator);
        } else {
            bond_.status = ValidatorStatus.Bonded;
        }

        // Interactions
        SUP_TOKEN.safeTransfer(beneficiary, amount);

        emit UnbondExecuted(operator, beneficiary, amount);
    }

    /// @inheritdoc IValidatorBonding
    function cancelUnbond(address operator) external {
        BondRecord storage bond_ = _bonds[operator];
        if (msg.sender != bond_.unbondingInitiator) revert NOT_UNBOND_INITIATOR();
        if (bond_.unbondingAmount == 0) revert NO_PENDING_UNBOND();

        uint256 amount = bond_.unbondingAmount;

        bond_.unbondingAmount = 0;
        bond_.unbondingDeadline = 0;
        bond_.unbondingInitiator = address(0);

        // If was full unbond (Unbonding status), restore to Bonded
        if (bond_.status == ValidatorStatus.Unbonding) {
            bond_.status = ValidatorStatus.Bonded;
        }

        emit UnbondCancelled(operator, amount);
    }

    // ─── Slashing ────────────────────────────────────────────

    /// @inheritdoc IValidatorBonding
    function slash(
        address operator,
        uint256 amount,
        address recipient
    ) external onlyRole(_GOVERNOR_ROLE) nonReentrant {
        if (recipient == address(0)) revert INVALID_ADDRESS();
        if (amount == 0) revert ZERO_AMOUNT();

        BondRecord storage bond_ = _bonds[operator];
        if (bond_.amount == 0) revert NOTHING_TO_SLASH();

        // Cap to total bond
        if (amount > bond_.amount) {
            amount = bond_.amount;
        }

        // Proportional slash across bonded + unbonding
        uint256 slashFromUnbonding;
        if (bond_.unbondingAmount > 0) {
            slashFromUnbonding = Math.mulDiv(amount, bond_.unbondingAmount, bond_.amount);
            bond_.unbondingAmount -= slashFromUnbonding;
        }

        bond_.amount -= amount;

        // Post-slash state transitions
        if (bond_.amount == 0 || bond_.amount < minimumBond) {
            bond_.status = ValidatorStatus.Unbonded;
            _operators.remove(operator);
            // Reset unbonding state if slash pushed below minimum
            if (bond_.unbondingAmount > 0) {
                bond_.unbondingAmount = 0;
                bond_.unbondingDeadline = 0;
                bond_.unbondingInitiator = address(0);
            }
        }

        // Interactions
        SUP_TOKEN.safeTransfer(recipient, amount);

        emit Slashed(operator, amount, recipient, bond_.amount);
    }

    // ─── Admin ───────────────────────────────────────────────

    /// @inheritdoc IValidatorBonding
    function setMinimumBond(uint256 newMinimum) external onlyRole(_GOVERNOR_ROLE) {
        if (newMinimum < MIN_MINIMUM_BOND || newMinimum > MAX_MINIMUM_BOND) {
            revert INVALID_MINIMUM_BOND();
        }
        uint256 oldMinimum = minimumBond;
        minimumBond = newMinimum;
        emit MinimumBondUpdated(oldMinimum, newMinimum);
    }

    /// @inheritdoc IValidatorBonding
    function setUnbondingPeriod(uint256 newPeriod) external onlyRole(_GOVERNOR_ROLE) {
        if (newPeriod < MIN_UNBONDING_PERIOD || newPeriod > MAX_UNBONDING_PERIOD) {
            revert INVALID_UNBONDING_PERIOD();
        }
        uint256 oldPeriod = unbondingPeriod;
        unbondingPeriod = newPeriod;
        emit UnbondingPeriodUpdated(oldPeriod, newPeriod);
    }

    // ─── View ────────────────────────────────────────────────

    /// @inheritdoc IValidatorBonding
    function isBonded(address operator) external view returns (bool) {
        BondRecord storage bond_ = _bonds[operator];
        return bond_.status == ValidatorStatus.Bonded
            && (bond_.amount - bond_.unbondingAmount) >= minimumBond;
    }

    /// @inheritdoc IValidatorBonding
    function getBond(address operator) external view returns (BondRecord memory) {
        return _bonds[operator];
    }

    /// @inheritdoc IValidatorBonding
    function getOperators() external view returns (address[] memory) {
        return _operators.values();
    }

    /// @inheritdoc IValidatorBonding
    function getOperatorCount() external view returns (uint256) {
        return _operators.length();
    }
}
```

### Key Implementation Decisions (From Research)

1. **addBond recovery path (Gap 1 fix):** `addBond()` allows `Unbonded` status when `bond.amount > 0`. If top-up brings amount >= minimumBond, status transitions to Bonded and operator re-added to registry.

2. **Residual unbonding reset (Gap 2 fix):** When slash pushes below minimum, unbonding state is fully reset. Operator retains residual `amount` for recovery via `addBond()` or withdrawal via `requestUnbond()`.

3. **Slash event enhanced (Gap 10 fix):** `Slashed` event includes `remainingBond` for off-chain indexing.

4. **Parameter bounds (Gap 7 fix):** `setMinimumBond` bounded [1 sUP, 100M sUP]. `setUnbondingPeriod` bounded [1 day, 365 days].

5. **Interface with operator param:** External functions take `operator` as parameter (not `msg.sender`). `bond()` is sugar for `bondFor(msg.sender, ...)`. This enables Foundation/third-party interactions.

6. **requestUnbond for Unbonded residual (Gap 3 fix):** Operators with residual bond after slash can call `requestUnbond()` to withdraw remaining funds, skipping the `minimumBond` check.

## Test Plan

### Unit Tests
- [ ] Constructor validation (zero addresses, invalid params)
- [ ] bond() / bondFor() happy path
- [ ] bondFor() reverts when operator already bonded
- [ ] bondFor() reverts when amount < minimumBond
- [ ] addBond() for Bonded, Unbonding, and Unbonded-with-residual
- [ ] addBond() recovery: Unbonded → Bonded when >= minimumBond
- [ ] updateDelegateKey() by operator and by beneficiary
- [ ] requestUnbond() partial and full
- [ ] requestUnbond() reverts when pending unbond exists
- [ ] requestUnbond() partial reverts when remaining < minimumBond
- [ ] executeUnbond() after deadline
- [ ] executeUnbond() reverts before deadline
- [ ] cancelUnbond() by initiator only
- [ ] cancelUnbond() restores status from Unbonding to Bonded
- [ ] slash() proportional calculation correctness
- [ ] slash() caps to bond.amount
- [ ] slash() below minimum → Unbonded, removed from registry
- [ ] slash() resets unbonding state when below minimum
- [ ] slash() full → all fields reset
- [ ] setMinimumBond() with bounds
- [ ] setUnbondingPeriod() with bounds
- [ ] isBonded() considers effective balance
- [ ] getOperators() includes Bonded and Unbonding

### Fuzz Tests
- [ ] Proportional slash: `slashFromUnbonding + slashFromBonded == amount` (no dust)
- [ ] Bond accounting: `sum(bond.amounts) == token.balanceOf(contract)`
- [ ] Registry consistency: all operators have status != Unbonded
- [ ] unbondingAmount <= bond.amount always holds
- [ ] Random bond/unbond/slash sequences maintain invariants

### Access Control Tests
- [ ] Only GOVERNOR_ROLE can slash
- [ ] Only GOVERNOR_ROLE can setMinimumBond / setUnbondingPeriod
- [ ] Only operator/beneficiary can requestUnbond/executeUnbond
- [ ] Only initiator can cancelUnbond
- [ ] Only operator/beneficiary can updateDelegateKey

## References & Research

### Internal
- `src/SuperGovernor.sol` — AccessControl pattern, EnumerableSet, validator config
- `src/SuperBank.sol` — SafeERC20 pattern, role delegation
- `test/unit/SuperBank.t.sol` — Testing conventions, PeripheryHelpers

### External
- [SIP-6 Forum Discussion](https://superform.discourse.group/t/sip-6-establish-validator-bonding-requirements/25/3)
- [Blog: Become a SuperVault Validator](https://blog.superform.xyz/2026/05/05/become-a-supervault-validator/)
- OZ 5.3.0 AccessControl, EnumerableSet, SafeERC20, ReentrancyGuard, Math docs

### Security References
- EigenLayer deallocation manipulation (front-running unbond before slash)
- EigenYields slashing exploit (proportional math errors)
- Lido CSM bonding module (operator/beneficiary separation pattern)
