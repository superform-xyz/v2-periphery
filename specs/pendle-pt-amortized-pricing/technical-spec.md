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

Implement **Book Value accounting** that:
1. Tracks positions using (A, t0, B(t0), T) state per vault/market
2. Calculates amortized value using linear interpolation to maturity
3. Provides deterministic pricing for validator network consensus
4. Emits events for Hypernative monitoring

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
struct Position {
    uint128 ptAmount;        // A: Total PT held (slot 1)
    uint128 bookValue;       // B(t0): Book value at last update (slot 1)
    uint64 lastUpdateTime;   // t0: Last state change timestamp (slot 2)
    uint64 maturityTime;     // T: PT maturity timestamp (slot 2)
    uint128 _reserved;       // Future use / padding (slot 2)
}
// Total: 2 storage slots
```

### Update Rules

**Initialization (First Purchase):**
```
A = ptAmount
B(t0) = sySpent
t0 = block.timestamp
T = IPPrincipalToken(pt).expiry()
```

**Subsequent Purchase:**
```
B_current = calculateBookValue(position)  // B(t) at current time
A_new = A + additionalPT
B(t0)_new = B_current + sySpent
t0_new = block.timestamp
// T unchanged
```

**Redemption:**
```
B_current = calculateBookValue(position)
costBasis = B_current / A  // Average cost per PT
A_new = A - redeemedPT
B(t0)_new = B_current - (redeemedPT × costBasis)
t0_new = block.timestamp
// T unchanged
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
import {IPMarket} from "@pendle/interfaces/IPMarket.sol";
import {IPPrincipalToken} from "@pendle/interfaces/IPPrincipalToken.sol";
import {IStandardizedYield} from "@pendle/interfaces/IStandardizedYield.sol";

/// @title PendlePTAmortizedOracle
/// @author Superform Labs
/// @notice Provides amortized cost pricing for Pendle PT positions
/// @dev Uses Book Value accounting with linear pull-to-par amortization
contract PendlePTAmortizedOracle is AccessControl {
    using Math for uint256;
    using SafeCast for uint256;

    // ============ Constants ============

    uint256 public constant PRECISION = 1e18;
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // ============ Structs ============

    /// @notice Position state for a vault's PT holdings in a specific market
    /// @dev Packed into 2 storage slots for gas efficiency
    struct Position {
        uint128 ptAmount;        // A: Total PT held
        uint128 bookValue;       // B(t0): Book value at last update
        uint64 lastUpdateTime;   // t0: Timestamp of last update
        uint64 maturityTime;     // T: PT maturity timestamp
        uint128 _reserved;       // Reserved for future use
    }

    // ============ Storage ============

    /// @notice Position state per vault per market
    mapping(address vault => mapping(address market => Position)) public positions;

    /// @notice List of markets per vault for enumeration
    mapping(address vault => address[]) public vaultMarkets;

    // ============ Events ============

    event PositionOpened(
        address indexed vault,
        address indexed market,
        uint256 ptAmount,
        uint256 bookValue,
        uint256 maturityTimestamp
    );

    event PositionIncreased(
        address indexed vault,
        address indexed market,
        uint256 additionalPt,
        uint256 newTotalPt,
        uint256 newBookValue
    );

    event PositionReduced(
        address indexed vault,
        address indexed market,
        uint256 redeemedPt,
        uint256 remainingPt,
        uint256 remainingBookValue
    );

    event PositionClosed(
        address indexed vault,
        address indexed market
    );

    // ============ Errors ============

    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error NO_POSITION();
    error INSUFFICIENT_POSITION();
    error MARKET_EXPIRED();
    error INVALID_BOOK_VALUE();

    // ============ Constructor ============

    constructor(address admin) {
        if (admin == address(0)) revert ZERO_ADDRESS();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);

        // MANAGER can grant/revoke KEEPER_ROLE
        _setRoleAdmin(KEEPER_ROLE, MANAGER_ROLE);
    }

    // ============ Keeper Functions ============

    /// @notice Record a PT purchase for a vault
    /// @param vault The SuperVault address
    /// @param market The Pendle Market address
    /// @param ptAmount Amount of PT purchased
    /// @param sySpent Amount of SY spent (book value increment)
    function recordPurchase(
        address vault,
        address market,
        uint256 ptAmount,
        uint256 sySpent
    ) external onlyRole(KEEPER_ROLE) {
        if (vault == address(0) || market == address(0)) revert ZERO_ADDRESS();
        if (ptAmount == 0 || sySpent == 0) revert ZERO_AMOUNT();
        // Sanity check: PT trades at discount, so sySpent should be <= ptAmount
        if (sySpent > ptAmount) revert INVALID_BOOK_VALUE();

        // Get PT and check maturity
        (, IPPrincipalToken pt,) = IPMarket(market).readTokens();
        uint256 maturity = pt.expiry();
        if (block.timestamp >= maturity) revert MARKET_EXPIRED();

        Position storage pos = positions[vault][market];
        if (pos.ptAmount > 0) {
            // Update existing position
            _increasePosition(vault, market, ptAmount, sySpent);
        } else {
            // Initialize new position
            _openPosition(vault, market, ptAmount, sySpent, maturity);
        }
    }

    /// @notice Record a PT redemption/sale for a vault
    /// @param vault The SuperVault address
    /// @param market The Pendle Market address
    /// @param ptAmount Amount of PT redeemed/sold
    function recordRedemption(
        address vault,
        address market,
        uint256 ptAmount
    ) external onlyRole(KEEPER_ROLE) {
        if (vault == address(0) || market == address(0)) revert ZERO_ADDRESS();
        if (ptAmount == 0) revert ZERO_AMOUNT();

        Position storage pos = positions[vault][market];
        if (pos.ptAmount == 0) revert NO_POSITION();
        if (ptAmount > pos.ptAmount) revert INSUFFICIENT_POSITION();

        _reducePosition(vault, market, ptAmount);
    }

    // ============ View Functions ============

    /// @notice Get the current amortized book value for a position
    /// @param vault The SuperVault address
    /// @param market The Pendle Market address
    /// @return bookValue Current amortized book value
    function getBookValue(
        address vault,
        address market
    ) external view returns (uint256 bookValue) {
        Position memory pos = positions[vault][market];
        if (pos.ptAmount == 0) revert NO_POSITION();
        return _calculateBookValue(pos);
    }

    /// @notice Get the current price per PT (book value / amount)
    /// @param vault The SuperVault address
    /// @param market The Pendle Market address
    /// @return pricePerPt Price per PT in SY terms (scaled by PRECISION)
    function getPricePerPt(
        address vault,
        address market
    ) external view returns (uint256 pricePerPt) {
        Position memory pos = positions[vault][market];
        if (pos.ptAmount == 0) revert NO_POSITION();

        uint256 currentBookValue = _calculateBookValue(pos);
        return currentBookValue.mulDiv(PRECISION, pos.ptAmount);
    }

    /// @notice Get raw position state
    /// @param vault The SuperVault address
    /// @param market The Pendle Market address
    function getPosition(
        address vault,
        address market
    ) external view returns (
        uint256 ptAmount,
        uint256 lastBookValue,
        uint256 lastUpdateTime,
        uint256 maturityTime,
        uint256 currentBookValue
    ) {
        Position memory pos = positions[vault][market];
        ptAmount = pos.ptAmount;
        lastBookValue = pos.bookValue;
        lastUpdateTime = pos.lastUpdateTime;
        maturityTime = pos.maturityTime;
        currentBookValue = pos.ptAmount > 0 ? _calculateBookValue(pos) : 0;
    }

    /// @notice Get all markets with positions for a vault
    /// @param vault The SuperVault address
    function getVaultMarkets(address vault) external view returns (address[] memory) {
        return vaultMarkets[vault];
    }

    // ============ Admin Functions ============

    /// @notice Grant keeper role to an address
    /// @param keeper Address to grant keeper role
    function addKeeper(address keeper) external onlyRole(MANAGER_ROLE) {
        _grantRole(KEEPER_ROLE, keeper);
    }

    /// @notice Revoke keeper role from an address
    /// @param keeper Address to revoke keeper role
    function removeKeeper(address keeper) external onlyRole(MANAGER_ROLE) {
        _revokeRole(KEEPER_ROLE, keeper);
    }

    // ============ Internal Functions ============

    /// @notice Calculate current book value using amortization formula
    /// @dev B(t) = A - (A - B(t0)) × (T - t) / (T - t0)
    function _calculateBookValue(Position memory pos) internal view returns (uint256) {
        uint256 A = pos.ptAmount;
        uint256 B_t0 = pos.bookValue;
        uint256 t0 = pos.lastUpdateTime;
        uint256 T = pos.maturityTime;

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

        // (A - B(t0)) × (T - t) / (T - t0)
        uint256 unamortizedDiscount = (A - B_t0).mulDiv(timeRemaining, totalDuration);

        return A - unamortizedDiscount;
    }

    /// @notice Open a new position
    function _openPosition(
        address vault,
        address market,
        uint256 ptAmount,
        uint256 sySpent,
        uint256 maturity
    ) internal {
        positions[vault][market] = Position({
            ptAmount: ptAmount.toUint128(),
            bookValue: sySpent.toUint128(),
            lastUpdateTime: block.timestamp.toUint64(),
            maturityTime: maturity.toUint64(),
            _reserved: 0
        });

        vaultMarkets[vault].push(market);

        emit PositionOpened(vault, market, ptAmount, sySpent, maturity);
    }

    /// @notice Increase an existing position
    function _increasePosition(
        address vault,
        address market,
        uint256 additionalPt,
        uint256 sySpent
    ) internal {
        Position storage pos = positions[vault][market];

        // Calculate current book value before update
        uint256 currentBookValue = _calculateBookValue(pos);

        // Update state
        uint256 newTotalPt = uint256(pos.ptAmount) + additionalPt;
        uint256 newBookValue = currentBookValue + sySpent;

        pos.ptAmount = newTotalPt.toUint128();
        pos.bookValue = newBookValue.toUint128();
        pos.lastUpdateTime = block.timestamp.toUint64();
        // maturityTime unchanged

        emit PositionIncreased(vault, market, additionalPt, newTotalPt, newBookValue);
    }

    /// @notice Reduce a position (partial or full redemption)
    function _reducePosition(
        address vault,
        address market,
        uint256 redeemedPt
    ) internal {
        Position storage pos = positions[vault][market];

        // Calculate current book value and cost basis
        uint256 currentBookValue = _calculateBookValue(pos);
        uint256 costBasis = currentBookValue.mulDiv(redeemedPt, pos.ptAmount);

        // Update state
        uint256 remainingPt = uint256(pos.ptAmount) - redeemedPt;
        uint256 remainingBookValue = currentBookValue - costBasis;

        if (remainingPt == 0) {
            // Full redemption: clean up position
            delete positions[vault][market];
            emit PositionReduced(vault, market, redeemedPt, 0, 0);
            emit PositionClosed(vault, market);
        } else {
            pos.ptAmount = remainingPt.toUint128();
            pos.bookValue = remainingBookValue.toUint128();
            pos.lastUpdateTime = block.timestamp.toUint64();
            emit PositionReduced(vault, market, redeemedPt, remainingPt, remainingBookValue);
        }
    }
}
```

---

## Acceptance Criteria

### Functional Requirements

- [ ] Oracle tracks PT positions per vault/market with (A, t0, B(t0), T) state
- [ ] `recordPurchase()` initializes or updates position with weighted average
- [ ] `recordRedemption()` reduces position using cost basis accounting
- [ ] `getBookValue()` returns linearly amortized value converging to face value at maturity
- [ ] `getPricePerPt()` returns B(t)/A for compatibility with existing interfaces
- [ ] Supports multiple PT markets with different maturities per vault
- [ ] Access control: KEEPER_ROLE for recording, MANAGER_ROLE for keeper management

### Non-Functional Requirements

- [ ] **Deterministic**: Same B(t) at same block.timestamp across all validators
- [ ] **Transparent**: All state changes emit events for Hypernative
- [ ] **Gas efficient**: View functions < 10k gas, state updates < 50k gas
- [ ] **Safe math**: Uses OpenZeppelin Math.mulDiv and SafeCast for overflow-safe calculations
- [ ] **Input validation**: Sanity checks on keeper inputs (sySpent <= ptAmount)

### Edge Cases

- [ ] At maturity (t = T): Returns B(T) = A
- [ ] After maturity (t > T): Returns B(T) = A (capped, no extrapolation)
- [ ] No position exists: Reverts with `NO_POSITION`
- [ ] Purchase after maturity: Reverts with `MARKET_EXPIRED`
- [ ] Redemption exceeds holdings: Reverts with `INSUFFICIENT_POSITION`
- [ ] Zero amounts: Reverts with `ZERO_AMOUNT`
- [ ] Invalid book value (sySpent > ptAmount): Reverts with `INVALID_BOOK_VALUE`
- [ ] Full redemption: Deletes position, emits `PositionClosed`

---

## Test Plan

### Unit Tests

- [ ] `_calculateBookValue()` returns correct values at t0, mid-duration, and maturity
- [ ] Weighted average update on subsequent purchases
- [ ] Cost basis calculation on partial redemption
- [ ] All error conditions revert with correct errors
- [ ] SafeCast reverts on overflow
- [ ] Full redemption cleans up position and emits `PositionClosed`
- [ ] Sanity check rejects sySpent > ptAmount

### Integration Tests

- [ ] Full lifecycle: open → increase → query → reduce → query
- [ ] Multi-market: vault with 2+ different PT markets
- [ ] Access control: keeper can record, non-keeper cannot
- [ ] Event emissions match state changes

### Fork Tests

- [ ] Against real Pendle markets on Ethereum mainnet
- [ ] Verify maturity timestamp read from PT contract
- [ ] Verify integration with actual market addresses

---

## Dependencies & Prerequisites

- OpenZeppelin Contracts (AccessControl, Math, SafeCast)
- Pendle Core V2 interfaces (IPMarket, IPPrincipalToken)
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
