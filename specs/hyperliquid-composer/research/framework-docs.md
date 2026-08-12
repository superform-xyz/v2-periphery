# LayerZero HyperLiquid Composer Framework Documentation

## 1. HyperLiquidComposer Contract Interface

**File**: `lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidComposer.sol`

### Contract Declaration

```solidity
contract HyperLiquidComposer is HyperLiquidCore, ReentrancyGuard, IHyperLiquidComposer, IOAppComposer
```

### Key Constants

```solidity
uint256 public constant VALID_COMPOSE_MSG_LEN = 64;  // abi.encode(uint256,address)
int8 public constant MIN_DECIMAL_DIFF = -2;
int8 public constant MAX_DECIMAL_DIFF = 18;
```

### Immutable State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `ENDPOINT` | `address` | LayerZero endpoint address |
| `OFT` | `address` | Associated OFT contract address |
| `ERC20` | `address` | Underlying ERC20 token address |
| `ERC20_ASSET_BRIDGE` | `address` | ERC20 asset bridge address |
| `ERC20_DECIMAL_DIFF` | `int8` | ERC20 decimal difference |
| `ERC20_CORE_INDEX_ID` | `uint64` | ERC20 core index ID |

### Core Functions

#### `lzCompose` - Main Entry Point

```solidity
function lzCompose(
    address _oft,
    bytes32 _guid,
    bytes calldata _message,
    address /*_executor*/,
    bytes calldata /*_extraData*/
) external payable virtual override nonReentrant
```

#### `handleTransfersToHyperCore`

```solidity
function handleTransfersToHyperCore(address _to, uint256 _amountLD) external payable
```

#### `decodeMessage`

```solidity
function decodeMessage(bytes calldata _composeMessage) external pure returns (uint256 minMsgValue, address to)
```

#### `quoteHyperCoreAmount`

```solidity
function quoteHyperCoreAmount(
    uint64 _coreIndexId,
    int8 _decimalDiff,
    address _bridgeAddress,
    uint256 _amountLD
) public view returns (IHyperAssetAmount memory)
```

---

## 2. HyperLiquidCore Precompile Interactions

**File**: `lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidCore.sol`

### Precompile Addresses

```solidity
address internal constant HLP_CORE_WRITER = 0x3333333333333333333333333333333333333333;
address internal constant SPOT_BALANCE_PRECOMPILE_ADDRESS = 0x0000000000000000000000000000000000000801;
address internal constant CORE_USER_EXISTS_PRECOMPILE_ADDRESS = 0x0000000000000000000000000000000000000810;
address internal constant HYPE_ASSET_BRIDGE = 0x2222222222222222222222222222222222222222;
```

### Precompile Functions

```solidity
function spotBalance(address user, uint64 token) public view returns (SpotBalance memory);
function coreUserExists(address user) public view returns (CoreUserExists memory);
function _submitCoreWriterTransfer(address _to, uint64 _coreIndex, uint64 _coreAmount) internal virtual;
```

---

## 3. HyperLiquidComposerCodec

**File**: `lib/devtools/packages/hyperliquid-composer/contracts/library/HyperLiquidComposerCodec.sol`

### Key Constants

```solidity
address public constant BASE_ASSET_BRIDGE_ADDRESS = 0x2000000000000000000000000000000000000000;
```

### Core Functions

```solidity
function into_assetBridgeAddress(uint64 _coreIndexId) internal pure returns (address);
function into_tokenId(address _assetBridgeAddress) internal pure returns (uint64);
function into_hyperAssetAmount(uint256 _amount, uint64 _assetBridgeSupply, int8 _decimalDiff) internal pure returns (IHyperAssetAmount memory);
```

---

## 4. IOAppComposer Interface

**File**: `lib/devtools/packages/oapp-evm/contracts/oapp/interfaces/IOAppComposer.sol`

```solidity
interface ILayerZeroComposer {
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}
```

---

## 5. Constructor Parameters

```solidity
constructor(address _oft, uint64 _coreIndexId, int8 _assetDecimalDiff)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `_oft` | `address` | The OFT contract address on HyperEVM |
| `_coreIndexId` | `uint64` | The HyperCore token index ID |
| `_assetDecimalDiff` | `int8` | `EVM_decimals - Core_decimals` (range: [-2, 18]) |

---

## 6. lzCompose Message Format

### OFTComposeMsgCodec Format

The message passed to `lzCompose` is encoded by the OFT contract:

| Offset | Bytes | Field | Description |
|--------|-------|-------|-------------|
| 0-7 | 8 | nonce | Message nonce |
| 8-11 | 4 | srcEid | Source endpoint ID |
| 12-43 | 32 | amountLD | Amount in local decimals |
| 44-75 | 32 | composeFrom | Original sender (bytes32) |
| 76+ | variable | composeMsg | Custom compose message |

### Expected composeMsg Format

```solidity
abi.encode(uint256 minMsgValue, address receiver)  // Exactly 64 bytes
```

---

## 7. Failed Message Recovery (refundToSrc)

```solidity
function refundToSrc(bytes32 _guid) external payable virtual;
```

- Permissionless - anyone can call it
- Uses stored `msgValue` plus additional `msg.value` for LayerZero fees
- Sends tokens back to original sender on source chain

---

## 8. Extension Patterns

### RecoverableComposer

```solidity
abstract contract RecoverableComposer is HyperLiquidComposer {
    address public immutable RECOVERY_ADDRESS;

    function retrieveCoreERC20(uint64 _coreAmount) external;
    function retrieveCoreHYPE(uint64 _coreAmount) external;
    function recoverEvmERC20(uint256 _evmAmount) external;
    function recoverEvmNative(uint256 _evmAmount) external;
}
```

### FeeToken (for USDC, USDT0)

```solidity
abstract contract FeeToken is HyperLiquidComposer {
    function _getFinalCoreAmount(address _to, uint64 _coreAmount) internal view override returns (uint64);
    function activationFee() public view virtual returns (uint64);
}
```

---

## Common Issues and Solutions

| Issue | Error | Solution |
|-------|-------|----------|
| User not activated | `CoreUserNotActivated` | Use FeeToken extension or pre-activate user |
| Transfer exceeds bridge | `TransferAmtExceedsAssetBridgeBalance` | Ensure bridge has sufficient balance |
| Invalid compose message | `ComposeMsgLengthNot64Bytes` | Use `abi.encode(uint256, address)` |
| Insufficient gas | `InsufficientGas` | Provide 150k+ gas |
