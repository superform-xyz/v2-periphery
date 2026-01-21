# Best Practices for Amortized Cost Pricing in Solidity

## 1. Weighted Average Cost Basis Tracking

### Core Pattern
```solidity
struct Position {
    uint256 totalFaceValue;      // Total face value of bonds held
    uint256 totalCostBasis;      // Total amount paid for bonds
    uint256 weightedAvgPrice;    // WAC per unit (18 decimals)
    uint256 lastUpdateTimestamp;
}

function recordPurchase(uint256 faceValue, uint256 purchasePrice) external {
    Position storage pos = positions[user][asset];

    uint256 newTotalFace = pos.totalFaceValue + faceValue;
    uint256 newTotalCost = pos.totalCostBasis + purchasePrice;

    // WAC = totalCostBasis / totalFaceValue
    pos.weightedAvgPrice = newTotalCost.mulDiv(PRECISION, newTotalFace, Math.Rounding.Floor);

    pos.totalFaceValue = newTotalFace;
    pos.totalCostBasis = newTotalCost;
}
```

## 2. Linear Pull-to-Par Implementation

### Formula
```
P(t) = P0 + (1 - P0) × (t - T0) / (T_maturity - T0)
```

### Solidity Implementation
```solidity
function getAmortizedPrice(Position memory pos) public view returns (uint256) {
    if (block.timestamp >= pos.maturityTimestamp) {
        return PRECISION;  // Par value
    }

    uint256 totalDuration = pos.maturityTimestamp - pos.purchaseTimestamp;
    uint256 elapsed = block.timestamp - pos.purchaseTimestamp;

    uint256 discount = PRECISION - pos.purchasePrice;
    uint256 accretion = discount.mulDiv(elapsed, totalDuration, Math.Rounding.Floor);

    return pos.purchasePrice + accretion;
}
```

## 3. Fixed-Point Math Best Practices

### Use OpenZeppelin Math.mulDiv
```solidity
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Safe: (a * b) / c with full 512-bit precision
result = a.mulDiv(b, c, Math.Rounding.Floor);
```

### Rounding Direction
- **Floor (down)**: Conservative valuation, use for asset outputs
- **Ceil (up)**: Use for share inputs (how many shares needed)

## 4. Gas Optimization for View Functions

### Storage Packing
```solidity
// BAD: 3 storage slots
struct UnpackedPosition {
    uint256 timestamp;   // Slot 0
    uint256 price;       // Slot 1
    uint256 amount;      // Slot 2
}

// GOOD: 2 storage slots
struct PackedPosition {
    uint128 amount;              // Slot 0 (16 bytes)
    uint128 purchasePrice;       // Slot 0 (16 bytes)
    uint64 purchaseTimestamp;    // Slot 1 (8 bytes)
    uint64 maturityTimestamp;    // Slot 1 (8 bytes)
    uint128 bookValue;           // Slot 1 (16 bytes)
}
```

### Use unchecked for Safe Math
```solidity
unchecked {
    // Safe: maturityTimestamp > purchaseTimestamp (validated on creation)
    uint256 totalDuration = pos.maturityTimestamp - pos.purchaseTimestamp;
    uint256 elapsed = block.timestamp - pos.purchaseTimestamp;
}
```

## 5. Time-Based Calculations

### 15-Second Rule
If your time-dependent calculation can tolerate 15 seconds of variance, `block.timestamp` is safe to use. For bond pricing over days/months, this is acceptable.

### Minimum Duration Validation
```solidity
uint256 public constant MIN_DURATION = 1 days;

function createPosition(uint256 maturity) external {
    uint256 duration = maturity - block.timestamp;
    require(duration >= MIN_DURATION, "Duration too short");
}
```

## 6. Access Control Patterns

### Role-Based with OpenZeppelin
```solidity
bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

constructor(address admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(MANAGER_ROLE, admin);

    // Set MANAGER as admin of KEEPER role
    _setRoleAdmin(KEEPER_ROLE, MANAGER_ROLE);
}
```

## 7. Event Logging

```solidity
event PositionOpened(
    address indexed vault,
    address indexed market,
    uint256 ptAmount,
    uint256 bookValue,
    uint256 maturityTimestamp
);

event BookValueUpdated(
    address indexed vault,
    address indexed market,
    uint256 previousValue,
    uint256 newValue,
    uint256 timestamp
);
```
