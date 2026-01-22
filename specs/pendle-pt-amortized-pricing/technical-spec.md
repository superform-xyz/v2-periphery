# Pendle PT Amortized Pricing Oracle - Technical Specification

## Overview

A new oracle contract that provides **amortized cost pricing** for Pendle Principal Token (PT) positions held by SuperVaults. This replaces mark-to-market pricing (which causes PPS volatility) with a deterministic, linear pull-to-par pricing model suitable for the "Boring Strategy" (hold-to-maturity).

## Problem Statement

The current `PendlePTYieldSourceOracle` uses `getPtToAssetRate()` which returns:
- Mark-to-market pricing based on AMM supply/demand
- High volatility due to thin Pendle liquidity
- PPS swings even though PT converges to 1:1 at maturity

For a hold-to-maturity strategy, this volatility is misleading and unnecessary.

## Proposed Solution

**Purpose:** Properly price the PT token subset of SuperVault Strategy total assets for PPS calculation.

Implement **Book Value accounting** that:
1. **Stores only 2 variables:** `lastUpdateBookValue` (B(t0)) and `lastUpdateTime` (t0)
2. **Reads on-demand:** `ptAmount` from `IERC20(pt).balanceOf(strategy)`, `maturityTime` from `IPrincipalToken(pt).expiry()`
3. Calculates amortized value using linear interpolation to maturity
4. Emits events for monitoring

---

## Technical Approach

### Mathematical Framework

**Book Value Formula** (from SV-1095):

$$
B(t) = A - (A - B(t_0)) \times \frac{T - t}{T - t_0}
$$

Where:
- `B(t)` = Book value at time t
- `A` = Total PT amount held (face value at maturity)
- `B(t0)` = Book value at last state update
- `t0` = Timestamp of last state update
- `T` = PT maturity timestamp
- `t` = Current timestamp (`block.timestamp`)

**Properties:**
- At `t = t0`: `B(t0) = B(t0)` ✓
- At `t = T`: `B(T) = A` (converges to face value) ✓
- Linear interpolation between

### State Structure

```solidity
// Minimal storage - only track what can't be read from chain
struct BookValueState {
    uint128 lastUpdateBookValue;  // B(t0): Book value at last update
    uint64 lastUpdateTime;        // t0: Last state change timestamp
}
// Total: 1 storage slot (24 bytes)

// Variables read on-demand from chain:
// ptAmount (A) = IERC20(pt).balanceOf(strategy)
// maturityTime (T) = IPrincipalToken(pt).expiry()
```

### Update Rules

Only `lastUpdateBookValue` and `lastUpdateTime` are stored/updated. The keeper calls these functions when purchases/redemptions occur.

**Initialization (First Purchase):**
```
lastUpdateBookValue = sySpent
lastUpdateTime = block.timestamp
```

**Subsequent Purchase (Buying ΔA PTs for sySpent):**
```
B_current = getBookValue()  // B(t) at current time
lastUpdateBookValue = B_current + sySpent
lastUpdateTime = block.timestamp
```

**Redemption (Selling ΔA PTs):**
```
A = IERC20(pt).balanceOf(strategy)  // read current amount BEFORE redemption
B_current = getBookValue()           // B(t) at current time
costBasis = B_current / A            // Average cost per PT
lastUpdateBookValue = B_current - (ΔA × costBasis)
lastUpdateTime = block.timestamp
```

---

## Implementation

### Contract: PendlePTAmortizedOracle.sol

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPPrincipalToken} from "@pendle/interfaces/IPPrincipalToken.sol";

/// @title PendlePTAmortizedOracle
/// @author Superform Labs
/// @notice Provides amortized cost pricing for Pendle PT positions
/// @dev Uses Book Value accounting with linear pull-to-par amortization
/// @dev Only stores 2 variables; reads ptAmount and maturity from chain
contract PendlePTAmortizedOracle is AccessControl {
    using Math for uint256;
    using SafeCast for uint256;

    // ============ Constants ============

    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // ============ Structs ============

    /// @notice Minimal state - only what can't be read from chain
    /// @dev Packed into 1 storage slot (24 bytes)
    struct BookValueState {
        uint128 lastUpdateBookValue;  // B(t0): Book value at last update
        uint64 lastUpdateTime;        // t0: Timestamp of last update
    }

    // ============ Storage ============

    /// @notice Book value state per vault per strategy per PT
    mapping(address vault => mapping(address strategy => mapping(address pt => BookValueState))) public bookValues;

    // ============ Events ============

    event BookValueUpdated(
        address indexed vault,
        address indexed strategy,
        address indexed pt,
        uint256 newBookValue,
        uint256 timestamp
    );

    // ============ Errors ============

    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error NO_POSITION();
    error MARKET_EXPIRED();
    error INSUFFICIENT_POSITION();
    error BOOK_VALUE_EXCEEDS_FACE_VALUE();

    // ============ Constructor ============

    constructor(address admin) {
        if (admin == address(0)) revert ZERO_ADDRESS();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _setRoleAdmin(KEEPER_ROLE, MANAGER_ROLE);
    }

    // ============ Keeper Functions ============

    /// @notice Record a PT purchase - updates lastUpdateBookValue and lastUpdateTime
    /// @param vault The SuperVault address
    /// @param strategy The strategy address holding the PT
    /// @param pt The PT token address
    /// @param sySpent Amount of SY spent (book value increment)
    function recordPurchase(
        address vault,
        address strategy,
        address pt,
        uint256 sySpent
    ) external onlyRole(KEEPER_ROLE) {
        if (vault == address(0) || strategy == address(0) || pt == address(0)) revert ZERO_ADDRESS();
        if (sySpent == 0) revert ZERO_AMOUNT();

        uint256 maturity = IPPrincipalToken(pt).expiry();
        if (block.timestamp >= maturity) revert MARKET_EXPIRED();

        BookValueState storage state = bookValues[vault][strategy][pt];

        // Calculate current book value (if position exists) and add new purchase
        uint256 newBookValue;
        if (state.lastUpdateTime > 0) {
            uint256 currentBookValue = _calculateBookValue(vault, strategy, pt);
            newBookValue = currentBookValue + sySpent;
        } else {
            // First purchase
            newBookValue = sySpent;
        }

        // Sanity check: book value should not exceed face value (ptAmount)
        // This catches keeper errors where sySpent is recorded larger than actual
        uint256 ptAmount = IERC20(pt).balanceOf(strategy);
        if (newBookValue > ptAmount) revert BOOK_VALUE_EXCEEDS_FACE_VALUE();

        state.lastUpdateBookValue = newBookValue.toUint128();
        state.lastUpdateTime = block.timestamp.toUint64();

        emit BookValueUpdated(vault, strategy, pt, newBookValue, block.timestamp);
    }

    /// @notice Record a PT redemption - updates using cost basis accounting
    /// @dev Must be called BEFORE the redemption changes balanceOf
    /// @param vault The SuperVault address
    /// @param strategy The strategy address holding the PT
    /// @param pt The PT token address
    /// @param ptRedeemed Amount of PT being redeemed
    function recordRedemption(
        address vault,
        address strategy,
        address pt,
        uint256 ptRedeemed
    ) external onlyRole(KEEPER_ROLE) {
        if (vault == address(0) || strategy == address(0) || pt == address(0)) revert ZERO_ADDRESS();
        if (ptRedeemed == 0) revert ZERO_AMOUNT();

        BookValueState storage state = bookValues[vault][strategy][pt];
        if (state.lastUpdateTime == 0) revert NO_POSITION();

        // Read current PT amount BEFORE redemption
        uint256 ptAmount = IERC20(pt).balanceOf(strategy);
        if (ptRedeemed > ptAmount) revert INSUFFICIENT_POSITION();

        uint256 currentBookValue = _calculateBookValue(vault, strategy, pt);

        // Cost basis accounting
        uint256 costBasis = currentBookValue.mulDiv(ptRedeemed, ptAmount);
        uint256 newBookValue = currentBookValue - costBasis;

        state.lastUpdateBookValue = newBookValue.toUint128();
        state.lastUpdateTime = block.timestamp.toUint64();

        emit BookValueUpdated(vault, strategy, pt, newBookValue, block.timestamp);
    }

    // ============ View Functions ============

    /// @notice Get the current amortized book value for a position
    /// @param vault The SuperVault address
    /// @param strategy The strategy address holding the PT
    /// @param pt The PT token address
    /// @return bookValue Current amortized book value
    function getBookValue(
        address vault,
        address strategy,
        address pt
    ) external view returns (uint256 bookValue) {
        BookValueState memory state = bookValues[vault][strategy][pt];
        if (state.lastUpdateTime == 0) revert NO_POSITION();
        return _calculateBookValue(vault, strategy, pt);
    }

    // ============ Admin Functions ============

    function addKeeper(address keeper) external onlyRole(MANAGER_ROLE) {
        _grantRole(KEEPER_ROLE, keeper);
    }

    function removeKeeper(address keeper) external onlyRole(MANAGER_ROLE) {
        _revokeRole(KEEPER_ROLE, keeper);
    }

    // ============ Internal Functions ============

    /// @notice Calculate current book value using amortization formula
    /// @dev B(t) = A - (A - B(t0)) × (T - t) / (T - t0)
    /// @dev Reads ptAmount and maturity from chain
    function _calculateBookValue(
        address vault,
        address strategy,
        address pt
    ) internal view returns (uint256) {
        BookValueState memory state = bookValues[vault][strategy][pt];

        // Read from chain
        uint256 A = IERC20(pt).balanceOf(strategy);           // ptAmount
        uint256 T = IPPrincipalToken(pt).expiry();            // maturityTime
        uint256 B_t0 = state.lastUpdateBookValue;
        uint256 t0 = state.lastUpdateTime;

        // Edge case: no PT held
        if (A == 0) return 0;

        // At or after maturity, book value = face value (A)
        if (block.timestamp >= T) {
            return A;
        }

        // Before any time has passed, book value = B(t0)
        if (block.timestamp <= t0) {
            return B_t0;
        }

        // Linear amortization: B(t) = A - (A - B(t0)) × (T - t) / (T - t0)
        uint256 timeRemaining = T - block.timestamp;
        uint256 totalDuration = T - t0;

        uint256 unamortizedDiscount = (A - B_t0).mulDiv(timeRemaining, totalDuration);

        return A - unamortizedDiscount;
    }
}
```

---

## Acceptance Criteria

### Functional Requirements

- [ ] Oracle stores only 2 variables per vault/strategy/pt: `lastUpdateBookValue` and `lastUpdateTime`
- [ ] Oracle reads `ptAmount` from `IERC20(pt).balanceOf(strategy)` on-demand
- [ ] Oracle reads `maturityTime` from `IPPrincipalToken(pt).expiry()` on-demand
- [ ] `recordPurchase()` updates book value state per update rules
- [ ] `recordRedemption()` updates book value state using cost basis accounting
- [ ] `getBookValue()` returns linearly amortized value converging to face value at maturity
- [ ] Access control: KEEPER_ROLE for recording, MANAGER_ROLE for keeper management

### Non-Functional Requirements

- [ ] **Deterministic**: Same B(t) at same block.timestamp across all validators
- [ ] **Transparent**: All state changes emit `BookValueUpdated` event
- [ ] **Gas efficient**: Minimal storage (1 slot), reads from chain
- [ ] **Safe math**: Uses OpenZeppelin Math.mulDiv and SafeCast

### Edge Cases

- [ ] At maturity (t = T): Returns B(T) = A (face value)
- [ ] After maturity (t > T): Returns B(T) = A (capped, no extrapolation)
- [ ] No position exists: Reverts with `NO_POSITION`
- [ ] Purchase after maturity: Reverts with `MARKET_EXPIRED`
- [ ] Zero amounts: Reverts with `ZERO_AMOUNT`
- [ ] Zero PT balance: Returns 0
- [ ] Redemption exceeds holdings: Reverts with `INSUFFICIENT_POSITION`
- [ ] Book value exceeds face value: Reverts with `BOOK_VALUE_EXCEEDS_FACE_VALUE`

---

## Test Plan

### Unit Tests

- [ ] `_calculateBookValue()` returns correct values at t0, mid-duration, and maturity
- [ ] Purchase update rule: B(t) + sySpent
- [ ] Redemption update rule: cost basis accounting
- [ ] All error conditions revert with correct errors
- [ ] SafeCast reverts on overflow

### Integration Tests

- [ ] Full lifecycle: purchase → query → purchase → query → redemption → query
- [ ] Access control: keeper can record, non-keeper cannot
- [ ] Event emissions match state changes

### Fork Tests

- [ ] Against real Pendle PT tokens on Ethereum mainnet
- [ ] Verify `balanceOf()` reads work correctly
- [ ] Verify `expiry()` reads work correctly

---

## Dependencies & Prerequisites

- OpenZeppelin Contracts (AccessControl, Math, SafeCast, IERC20)
- Pendle Core V2 interfaces (IPPrincipalToken for `expiry()`)
- Keeper infrastructure to monitor strategy transactions and call recording functions

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Keeper records incorrect values | Medium | High | Event monitoring, sanity bounds checking |
| Keeper fails to record purchases | Medium | Medium | Monitoring alerts, fallback to TWAP |
| Integer overflow in calculations | Low | High | Use OpenZeppelin Math.mulDiv |
| Maturity timestamp manipulation | Very Low | High | Read from immutable PT contract |

---

## References

- [SV-1095 Proposal](/specs/pendle-pt-amortized-pricing/research/sv-1095-proposal.md)
- [Pendle Oracle Docs](https://docs.pendle.finance/pendle-v2/Developers/Oracles/)
- [Chaos Labs PT Risk Oracle](https://chaoslabs.xyz/posts/introducing-pendle-pt-risk-oracle)
- Current implementation: `v2-core/src/accounting/oracles/PendlePTYieldSourceOracle.sol`
