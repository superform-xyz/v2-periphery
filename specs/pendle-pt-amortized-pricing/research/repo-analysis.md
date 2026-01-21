# Repository Research Summary

## Architecture & Structure

### Core Oracle Files in v2-core

| File Path | Description |
|-----------|-------------|
| `v2-core/src/interfaces/accounting/IYieldSourceOracle.sol` | Interface defining all methods a YieldSourceOracle must implement |
| `v2-core/src/accounting/oracles/AbstractYieldSourceOracle.sol` | Abstract base class with common functionality and batch methods |
| `v2-core/src/accounting/oracles/PendlePTYieldSourceOracle.sol` | Current Pendle PT oracle using mark-to-market TWAP pricing |

### IYieldSourceOracle Interface

**Required Methods:**
```solidity
// Core pricing methods
function decimals(address yieldSourceAddress) external view returns (uint8);
function getShareOutput(address yieldSourceAddress, address assetIn, uint256 assetsIn) external view returns (uint256);
function getWithdrawalShareOutput(address yieldSourceAddress, address assetIn, uint256 assetsIn) external view returns (uint256);
function getAssetOutput(address yieldSourceAddress, address assetIn, uint256 sharesIn) external view returns (uint256);
function getPricePerShare(address yieldSourceAddress) external view returns (uint256);

// TVL methods
function getTVLByOwnerOfShares(address yieldSourceAddress, address ownerOfShares) external view returns (uint256);
function getBalanceOfOwner(address yieldSourceAddress, address ownerOfShares) external view returns (uint256);
function getTVL(address yieldSourceAddress) external view returns (uint256);
```

### Current PendlePTYieldSourceOracle

```solidity
// Key constants
uint32 public immutable TWAP_DURATION;  // 15 minutes default
uint256 private constant PRICE_DECIMALS = 18;

// Core pricing - uses Pendle's TWAP oracle (mark-to-market)
function getPricePerShare(address market) public view override returns (uint256 price) {
    price = IPMarket(market).getPtToAssetRate(TWAP_DURATION);
}
```

---

## Cost-Basis Tracking Patterns

### BaseLedger.sol Pattern

**State Variables:**
```solidity
// Tracks total shares per user per yield source
mapping(address user => mapping(address yieldSource => uint256 shares)) public usersAccumulatorShares;

// Tracks total cost basis (in asset terms) per user per yield source
mapping(address user => mapping(address yieldSource => uint256 costBasis)) public usersAccumulatorCostBasis;
```

**Weighted Average Cost Basis Calculation:**
```solidity
function calculateCostBasisView(address user, address yieldSource, uint256 usedShares)
    public view returns (uint256 costBasis, uint256 shares)
{
    uint256 accumulatorShares = usersAccumulatorShares[user][yieldSource];
    uint256 accumulatorCostBasis = usersAccumulatorCostBasis[user][yieldSource];

    // Proportional cost basis calculation
    costBasis = usedShares > 0 ? Math.mulDiv(accumulatorCostBasis, usedShares, accumulatorShares) : 0;
}
```

---

## Access Control Patterns - KEEPER_ROLE

### SuperformGasOracle.sol Pattern

```solidity
bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

contract SuperformGasOracle is AggregatorV3Interface, AccessControl {
    constructor(int256 initialGasPrice, address admin_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(KEEPER_ROLE, admin_);
    }

    function setGasPrice(int256 newGasPrice) external onlyRole(KEEPER_ROLE) {
        // ...
    }
}
```

---

## SuperVaultStrategy Integration

### Yield Source Management

```solidity
// Yield source to oracle mapping
mapping(address source => address oracle) private yieldSources;

function manageYieldSource(address source, address oracle, YieldSourceAction actionType) external {
    _isPrimaryManager(msg.sender);
    _manageYieldSource(source, oracle, actionType);
}
```

### PPS Integration

```solidity
function getStoredPPS() public view returns (uint256) {
    return _getSuperVaultAggregator().getPPS(address(this));
}
```

---

## Test Patterns

### Fork Test Setup
```solidity
function test_PendlePtOracle_takeSnapshot() public {
    uint256 ethFork = vm.createFork(vm.envString(ETHEREUM_RPC_URL_KEY), 22_579_300);
    vm.selectFork(ethFork);

    address market = address(0x8539B41CA14148d1F7400d399723827a80579414);
    PendlePTYieldSourceOracle tempOracle = new PendlePTYieldSourceOracle(address(ledgerConfig));
    // ...
}
```

### Access Control Tests
```solidity
function test_SetGasPrice_RevertsNonKeeper() public {
    address nonKeeper = makeAddr("nonKeeper");
    vm.prank(nonKeeper);
    vm.expectRevert(
        abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonKeeper, KEEPER_ROLE)
    );
    gasOracle.setGasPrice(50);
}
```
