# Technical Specification: HyperLiquid Composer for UpOFT

**Version:** 1.0
**Date:** 2026-02-24
**Status:** Draft - Pending Core Index ID from Step 3
**Author:** Claude Code

---

## 1. Overview

### 1.1 Purpose

Deploy a HyperLiquidComposer contract on HyperEVM that enables UP token holders to bridge directly from Base/Ethereum into HyperCore spot trading, bypassing the need for manual HyperEVM → HyperCore transfers.

### 1.2 Background

This is **Step 2** of a 3-step LayerZero/HyperLiquid integration:

| Step | Description | Status |
|------|-------------|--------|
| 1 | OFT deployment on Base + HyperEVM | ✅ Complete |
| 2 | HyperLiquid Composer deployment | 🔄 This ticket |
| 3 | Connect market on HyperCore (TOK team) | ⏳ Pending |

### 1.3 Message Flow

```
Source Chain (Base/Ethereum)
         │
         │ OFT.send() with composeMsg
         ▼
┌─────────────────────────────────────────────────────────────────┐
│  HyperEVM                                                        │
│  ┌─────────────┐     lzCompose()      ┌────────────────────────┐│
│  │ UP OFT      │ ───────────────────► │ UpHyperLiquidComposer  ││
│  │ 0x642f...fe │                      │                        ││
│  └─────────────┘                      │ 1. Decode receiver     ││
│                                       │ 2. Transfer to bridge  ││
│                                       │    (0x2000...+indexId) ││
│                                       │ 3. CoreWriter.spotSend ││
│                                       └────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
                                   ┌─────────────────────────────┐
                                   │  HyperCore (L1 Spot Trading)│
                                   │  UP HIP-1 token credited    │
                                   │  to receiver's spot wallet  │
                                   └─────────────────────────────┘
```

---

## 2. Contract Specification

### 2.1 Contract: UpHyperLiquidComposer

**Location:** `src/UP/UpHyperLiquidComposer.sol`

**Inheritance:**
```solidity
contract UpHyperLiquidComposer is RecoverableComposer
```

**Implementation Pattern:** Extends RecoverableComposer for emergency fund recovery capabilities.

**Reference:** [RecoverableComposer.sol](https://github.com/LayerZero-Labs/devtools/blob/e149a722de12a8a47bf77c85895f16c3fa82d8bb/packages/hyperliquid-composer/contracts/extensions/RecoverableComposer.sol)

### 2.2 Constructor Parameters

```solidity
constructor(
    address _oft,
    uint64 _coreIndexId,
    int8 _assetDecimalDiff,
    address _recoveryAddress
) HyperLiquidComposer(_oft, _coreIndexId, _assetDecimalDiff) RecoverableComposer(_recoveryAddress)
```

| Parameter | Value | Source |
|-----------|-------|--------|
| `_oft` | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` | UP OFT on HyperEVM |
| `_coreIndexId` | **TBD** | From Step 3 team |
| `_assetDecimalDiff` | **TBD** | See note below |
| `_recoveryAddress` | `0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153` | MPC wallet |

**Note on `_assetDecimalDiff`:** This value is `EVM_decimals - Core_decimals` and depends on the weiDecimals chosen during HIP-1 deployment in Step 3. Valid range is [-2, 18].

| Core weiDecimals | assetDecimalDiff | Precision | Notes |
|-----------------|------------------|-----------|-------|
| 18 | 0 | 1:1 with EVM | No scaling, simplest |
| 8 | 10 | 1e10 EVM = 1 Core | Like HYPE token |
| 6 | 12 | 1e12 EVM = 1 Core | Like USDC |

**Recommendation:** Use 18 decimals on HyperCore (same as EVM) to avoid precision loss and simplify integration. This is supported via the HyperLiquid API (UI limits to 0-8, but API supports 0-15).

### 2.3 Inherited Immutables

From `HyperLiquidComposer`:

| Variable | Type | Description |
|----------|------|-------------|
| `ENDPOINT` | `address` | LayerZero endpoint: `0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9` |
| `OFT` | `address` | UP OFT: `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` |
| `ERC20` | `address` | UP ERC20 (same as OFT on HyperEVM) |
| `ERC20_ASSET_BRIDGE` | `address` | Computed: `0x2000...0000 + _coreIndexId` |
| `ERC20_DECIMAL_DIFF` | `int8` | `10` |
| `ERC20_CORE_INDEX_ID` | `uint64` | From constructor |

### 2.4 Key Functions

#### `lzCompose` (Entry Point)

```solidity
function lzCompose(
    address _oft,
    bytes32 _guid,
    bytes calldata _message,
    address /*_executor*/,
    bytes calldata /*_extraData*/
) external payable virtual override nonReentrant
```

**Security Validations:**
1. `msg.sender == ENDPOINT` - Only LayerZero endpoint can call
2. `_oft == OFT` - Only accepts messages from the configured OFT

**Message Format:**
- Compose message must be exactly 64 bytes
- Format: `abi.encode(uint256 minMsgValue, address receiver)`

#### `handleTransfersToHyperCore`

```solidity
function handleTransfersToHyperCore(address _to, uint256 _amountLD) external payable
```

Transfers tokens from HyperEVM to HyperCore spot trading for the specified receiver.

#### `refundToSrc`

```solidity
function refundToSrc(bytes32 _guid) external payable virtual
```

Permissionless function to refund failed messages back to source chain.

### 2.5 Recovery Functions (from RecoverableComposer)

All recovery functions are restricted to `RECOVERY_ADDRESS` (MPC wallet).

#### `retrieveCoreERC20`

```solidity
function retrieveCoreERC20(uint64 _coreAmount) public onlyRecoveryAddress
```

Pull UP tokens from Composer's HyperCore balance back to the asset bridge.

#### `retrieveCoreHYPE`

```solidity
function retrieveCoreHYPE(uint64 _coreAmount) public onlyRecoveryAddress
```

Pull HYPE tokens from Composer's HyperCore balance back to the HYPE bridge.

#### `recoverEvmERC20`

```solidity
function recoverEvmERC20(uint256 _evmAmount) public onlyRecoveryAddress
```

Recover UP tokens stuck on HyperEVM side to the recovery address.

#### `recoverEvmNative`

```solidity
function recoverEvmNative(uint256 _evmAmount) public onlyRecoveryAddress
```

Recover native HYPE stuck on HyperEVM side to the recovery address.

**Note:** Pass `0` for `_coreAmount` or `_evmAmount` to recover the full balance.

---

## 3. Decimal Handling

### 3.1 HyperCore Decimals Are Configurable

**Important:** HyperCore decimals are NOT fixed. They are chosen during HIP-1 token deployment (Step 3).

| Configuration | weiDecimals | Valid Range |
|--------------|-------------|-------------|
| Via HyperLiquid UI | 0-8 | Limited by UI |
| Via HyperLiquid API | 0-15 | Full range |

**Protocol Constraint:** `assetDecimalDiff = EVM_decimals - Core_decimals` must be in range `[-2, 18]`.

### 3.2 Conversion Logic (Example: 8 Core Decimals)

If Core weiDecimals = 8 (like HYPE):

| Chain | Decimals | Example |
|-------|----------|---------|
| Base/Ethereum/HyperEVM | 18 | `1.0 UP = 1e18` |
| HyperCore (HIP-1) | 8 | `1.0 UP = 1e8` |

**Conversion:** `coreAmount = evmAmount / 1e10` (truncating division)

### 3.3 Precision Loss (Only if decimals differ)

If using 8 core decimals:
- **Minimum bridgeable amount:** ~0.00000001 UP (1e10 wei)
- **Dust handling:** Amounts < 1e10 wei will result in 0 core tokens
- **Rounding:** Truncation (floor), not rounding

**Example (with 8 core decimals):**
```
Input:  1.123456789123456789 UP (1123456789123456789 wei)
Output: 1.12345678 UP on HyperCore (112345678 core units)
Lost:   0.000000009123456789 UP (dust)
```

### 3.4 Recommendation: Use 18 Decimals

If you configure HyperCore with 18 weiDecimals (same as EVM), there is **no precision loss** and `assetDecimalDiff = 0`. This is the simplest configuration.

---

## 4. Error Handling

### 4.1 Error Scenarios

| Scenario | Error | Recovery |
|----------|-------|----------|
| Malformed compose message | `ComposeMsgLengthNot64Bytes` | Stored in `failedMessages`, call `refundToSrc(guid)` |
| Inactive receiver on HyperCore | `CoreUserNotActivated` | Auto-refund to HyperEVM |
| Insufficient bridge capacity | `TransferAmtExceedsAssetBridgeBalance` | Auto-refund to HyperEVM |
| Insufficient gas | `InsufficientGas` | Retry with more gas |

### 4.2 Refund Flow

```
1. lzCompose fails → tokens stored with guid
2. Anyone calls refundToSrc(guid)
3. LayerZero sends tokens back to source chain
4. Original sender receives tokens on Base/Ethereum
```

---

## 5. Gas Configuration

### 5.1 Current Configuration (from OFT deployment)

| Operation | Gas Limit | Notes |
|-----------|-----------|-------|
| `lzReceive` | 300,000 | OFT token receipt |
| `lzCompose` | 1,000,000 | Composer execution |

### 5.2 Composer Requirements

| Scenario | Minimum Gas |
|----------|-------------|
| Without native value | 150,000 |
| With native value | 200,000 |

**Assessment:** 1,000,000 gas limit is sufficient (5-6x headroom).

---

## 6. Deployment

### 6.1 Prerequisites

| Requirement | Status | Blocker |
|-------------|--------|---------|
| Core Index ID from Step 3 | ⏳ Pending | **Yes** |
| Deployer wallet funded on HyperCore | ⏳ | No |
| Composer address activated on HyperCore | Post-deploy | No |

### 6.2 Deployment Script

**Location:** `script/DeployUpComposer.s.sol`

```solidity
// Deployment steps:
// 1. Switch to big blocks (if contract > 2M gas)
// 2. Deploy UpHyperLiquidComposer
// 3. Switch back to small blocks
// 4. Fund Composer address with $1+ USDC/HYPE on HyperCore
// 5. Transfer ownership to MPC wallet
```

### 6.3 Deployment Parameters

| Parameter | Value |
|-----------|-------|
| Chain | HyperEVM (999) |
| Salt Namespace | Same as OFT deployment |
| Initial Owner | Deployer: `0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8` |
| Final Owner | MPC: `0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153` |

### 6.4 Output

**Location:** `script/output/prod/999/UpComposer-latest.json`

```json
{
  "UpHyperLiquidComposer": "<deployed_address>"
}
```

---

## 7. Security Considerations

### 7.1 Access Control

| Function | Access |
|----------|--------|
| `lzCompose` | LayerZero Endpoint only |
| `refundToSrc` | Permissionless |
| `handleTransfersToHyperCore` | Public (self-call pattern) |
| `retrieveCoreERC20` | Recovery address only (MPC wallet) |
| `retrieveCoreHYPE` | Recovery address only (MPC wallet) |
| `recoverEvmERC20` | Recovery address only (MPC wallet) |
| `recoverEvmNative` | Recovery address only (MPC wallet) |

### 7.2 Reentrancy Protection

- `lzCompose` uses `nonReentrant` modifier from OpenZeppelin
- External calls use self-call pattern with try-catch for isolation

### 7.3 Validation Checks

1. Caller validation: `msg.sender == ENDPOINT`
2. OFT validation: `_oft == OFT`
3. Message length: exactly 64 bytes
4. Gas check: `gasleft() >= MIN_GAS()`

---

## 8. Integration

### 8.1 User Flow (Sending with Compose)

```solidity
// On Base/Ethereum
bytes memory composeMsg = abi.encode(
    uint256(0),              // minMsgValue (0 if no HYPE needed)
    receiverOnHyperCore      // Final recipient address
);

SendParam memory params = SendParam({
    dstEid: 30367,                                        // HyperEVM
    to: bytes32(uint256(uint160(composerAddress))),       // Composer
    amountLD: amount,
    minAmountLD: minAmount,
    extraOptions: options,
    composeMsg: composeMsg,
    oftCmd: ""
});

upOft.send(params, fee, refundAddress);
```

### 8.2 LayerZero Endpoint IDs

| Chain | EID |
|-------|-----|
| Ethereum | 30101 |
| Base | 30184 |
| HyperEVM | 30367 |

---

## 9. Testing Strategy

### 9.1 Unit Tests

| Test | Description |
|------|-------------|
| Constructor validation | Verify all immutables set correctly |
| Decimal conversion | Test edge cases (dust, max amounts) |
| Access control | Verify only endpoint can call lzCompose |
| Message decoding | Test valid and invalid message formats |

### 9.2 Integration Tests

| Test | Description |
|------|-------------|
| Happy path | Base → HyperEVM → HyperCore |
| Refund flow | Failed compose → refundToSrc |
| Gas limits | Verify operations within gas budget |

### 9.3 Fork Tests

Mock HyperLiquid precompiles for local testing:
- `HLP_CORE_WRITER` (0x3333...)
- `SPOT_BALANCE_PRECOMPILE` (0x0801)
- `CORE_USER_EXISTS_PRECOMPILE` (0x0810)

---

## 10. Post-Deployment Checklist

### 10.1 Immediate Actions

- [ ] Verify contract deployment on HyperEVM explorer
- [ ] Fund Composer address with $1+ USDC/HYPE on HyperCore
- [ ] Verify Composer activation via `coreUserExists` precompile
- [ ] Transfer ownership to MPC wallet

### 10.2 Verification

- [ ] Test compose message delivery end-to-end (testnet first)
- [ ] Test refund mechanism
- [ ] Verify decimal scaling accuracy
- [ ] Monitor bridge capacity

### 10.3 Documentation

- [ ] Update user documentation with bridge instructions
- [ ] Add Composer address to deployment outputs
- [ ] Create support runbook for failure scenarios

---

## 11. Dependencies

### 11.1 External Contracts

| Contract | Address | Purpose |
|----------|---------|---------|
| LayerZero Endpoint | `0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9` | Message routing |
| UP OFT (HyperEVM) | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` | Token contract |
| HLP Core Writer | `0x3333333333333333333333333333333333333333` | HyperCore precompile |

### 11.2 Library Dependencies

- `lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidComposer.sol`
- `lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidCore.sol`
- `lib/devtools/packages/hyperliquid-composer/contracts/extensions/RecoverableComposer.sol`
- OpenZeppelin ReentrancyGuard
- OpenZeppelin SafeERC20

---

## 12. Open Questions

### 12.1 Blocking (Must resolve before deployment)

| # | Question | Owner |
|---|----------|-------|
| 1 | What is the Core Index ID for UP on HyperCore? | Step 3 Team |
| 2 | What weiDecimals will UP HIP-1 use on HyperCore? | Step 3 Team |

**Recommendation for #2:** Use 18 weiDecimals (same as EVM) for zero precision loss. This is supported via the HyperLiquid API (not the UI which limits to 0-8).

### 12.2 Non-Blocking (Can resolve post-deployment)

| # | Question | Default Assumption |
|---|----------|-------------------|
| 3 | Is asset bridge funding required before first transfer? | Yes, fund full supply |

---

## 13. Appendix

### 13.1 HyperLiquid System Addresses

```solidity
address constant HLP_CORE_WRITER = 0x3333333333333333333333333333333333333333;
address constant SPOT_BALANCE_PRECOMPILE = 0x0000000000000000000000000000000000000801;
address constant CORE_USER_EXISTS_PRECOMPILE = 0x0000000000000000000000000000000000000810;
address constant HYPE_ASSET_BRIDGE = 0x2222222222222222222222222222222222222222;
address constant BASE_ASSET_BRIDGE = 0x2000000000000000000000000000000000000000;
```

### 13.2 Asset Bridge Address Computation

```solidity
// For a token with coreIndexId = N:
assetBridge = 0x2000000000000000000000000000000000000000 + N
```

Example: If `coreIndexId = 1234` (0x4D2):
```
assetBridge = 0x20000000000000000000000000000000000004D2
```

### 13.3 Compose Message Encoding

```solidity
// Exactly 64 bytes
bytes memory composeMsg = abi.encode(
    uint256 minMsgValue,    // bytes 0-31: min msg.value for HyperCore ops
    address receiver        // bytes 32-63: recipient on HyperCore
);
```
