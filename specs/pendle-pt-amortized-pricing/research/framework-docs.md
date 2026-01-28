# Framework Documentation: Pendle V2 & OpenZeppelin

## 1. Pendle V2 Contracts

### IPMarket Interface

```solidity
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";

interface IPMarket {
    // Get market tokens
    function readTokens() external view returns (
        IStandardizedYield _SY,
        IPPrincipalToken _PT,
        IPYieldToken _YT
    );

    // Get maturity timestamp
    function expiry() external view returns (uint256);

    // Check if market has matured
    function isExpired() external view returns (bool);

    // Get PT to SY rate (TWAP)
    function getPtToSyRate(uint32 duration) external view returns (uint256);

    // Get PT to Asset rate (TWAP)
    function getPtToAssetRate(uint32 duration) external view returns (uint256);
}
```

### IPPrincipalToken Interface

```solidity
import "@pendle/core-v2/contracts/interfaces/IPPrincipalToken.sol";

interface IPPrincipalToken is IERC20Metadata {
    // Get the Standardized Yield token address
    function SY() external view returns (address);

    // Get maturity timestamp (CRITICAL for amortization)
    function expiry() external view returns (uint256);

    // Check if PT has matured
    function isExpired() external view returns (bool);
}
```

### IStandardizedYield Interface

```solidity
import "@pendle/core-v2/contracts/interfaces/IStandardizedYield.sol";

interface IStandardizedYield is IERC20Metadata {
    enum AssetType { TOKEN, LIQUIDITY }

    // Get underlying asset information
    function assetInfo() external view returns (
        AssetType assetType,
        address assetAddress,
        uint8 assetDecimals
    );

    // Get exchange rate (SY to underlying)
    function exchangeRate() external view returns (uint256);
}
```

### Usage Example

```solidity
// Get market info
IPMarket market = IPMarket(marketAddress);
(IStandardizedYield sy, IPPrincipalToken pt, ) = market.readTokens();

// Get maturity
uint256 maturity = pt.expiry();

// Get underlying asset
(, address underlyingAsset, uint8 decimals) = sy.assetInfo();
```

---

## 2. OpenZeppelin Math.mulDiv

### Import
```solidity
import "@openzeppelin/contracts/utils/math/Math.sol";
```

### Rounding Options
```solidity
enum Rounding {
    Floor,   // Toward negative infinity (default)
    Ceil,    // Toward positive infinity
    Trunc,   // Toward zero
    Expand   // Away from zero
}
```

### Usage
```solidity
using Math for uint256;

// Basic mulDiv - rounds down
uint256 result = x.mulDiv(y, denominator);

// With explicit rounding
uint256 result = x.mulDiv(y, denominator, Math.Rounding.Ceil);
```

---

## 3. OpenZeppelin AccessControl

### Import
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";
```

### Implementation Pattern
```solidity
contract MyContract is AccessControl {
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(KEEPER_ROLE, admin);
    }

    function restrictedFunction() external onlyRole(KEEPER_ROLE) {
        // Only keepers can call
    }

    function addKeeper(address keeper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(KEEPER_ROLE, keeper);
    }
}
```

---

## 4. Struct Storage Patterns

### Packed Struct (2 slots)
```solidity
struct Position {
    uint128 ptAmount;           // Slot 0 (16 bytes)
    uint128 bookValue;          // Slot 0 (16 bytes)
    uint64 lastUpdateTime;      // Slot 1 (8 bytes)
    uint64 maturityTimestamp;   // Slot 1 (8 bytes)
    uint128 _reserved;          // Slot 1 (16 bytes)
}
```

### Nested Mapping
```solidity
// vault => market => Position
mapping(address => mapping(address => Position)) public positions;
```

---

## 5. Event Patterns

```solidity
// Maximum 3 indexed parameters
event PositionOpened(
    address indexed vault,
    address indexed market,
    address indexed pt,
    uint256 ptAmount,
    uint256 bookValue,
    uint256 maturityTimestamp
);
```
