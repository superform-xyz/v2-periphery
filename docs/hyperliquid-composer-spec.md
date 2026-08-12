# HyperLiquid Composer Integration Spec

## Context

From LZ/HyperLiquid call (Feb 23, 2025):

- **Step 1**: OFT deployment — ✅ Deployed on Base + HyperEVM
- **Step 2**: HyperLiquid Composer deployment on HyperEVM ← **THIS TICKET**
- **Step 3**: Connect market on HyperCore to OFT (separate TOK ticket)

## What the Composer Does

Enables OFT bridging from any source chain directly into HyperLiquid spot trading:
- Messages forwarded from EVM endpoint to HyperLiquid native bridge
- Assets deposited to `0x2000...` address, which puts them in spot trading
- Without Composer, users can only bridge to HyperEVM — not directly into HyperCore

## Current Deployment State

| Component | Status | Address |
|-----------|--------|---------|
| UP OFT on Base | ✅ Deployed | `0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B` |
| UP OFT on HyperEVM | ✅ Deployed | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` |
| UP OFT Adapter on Ethereum | ✅ Deployed | See `script/output/prod/1/UpOFT-latest.json` |
| HyperLiquid Composer | ❌ Not deployed | — |
| UP on HyperCore (HIP-1) | ❌ Not created | Step 3 dependency |

## Architecture

### Message Flow

```
Source Chain (Base, Ethereum, etc.)
         │
         │ OFT.send() with composeMsg
         ▼
┌─────────────────────────────────────────────────────────────────┐
│  HyperEVM                                                        │
│  ┌─────────────┐     lzCompose()      ┌────────────────────────┐│
│  │ UP OFT      │ ───────────────────► │ HyperLiquidComposer    ││
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

### Without Composer (Current)
```
Base → OFT bridge → HyperEVM (tokens stuck on EVM side)
```

### With Composer (Goal)
```
Base → OFT bridge → HyperEVM → Composer → HyperCore Spot Trading
```

## Technical Details

### OFT Compose Support

The existing UP OFT deployment **already supports compose**. From `DeployUpOFT.s.sol`:

```solidity
uint128 internal constant GAS_LIMIT = 300_000;
uint128 internal constant COMPOSE_GAS_LIMIT = 1_000_000;

function _setEnforcedOptions(address oapp, uint32 dstEid) internal {
    bytes memory sendOptions = OptionsBuilder.newOptions()
        .addExecutorLzReceiveOption(GAS_LIMIT, 0);

    bytes memory sendAndCallOptions = OptionsBuilder.newOptions()
        .addExecutorLzReceiveOption(GAS_LIMIT, 0)
        .addExecutorLzComposeOption(0, COMPOSE_GAS_LIMIT, 0);  // Compose enabled

    EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
    enforcedOptions[0] = EnforcedOptionParam({ eid: dstEid, msgType: SEND, options: sendOptions });
    enforcedOptions[1] = EnforcedOptionParam({ eid: dstEid, msgType: SEND_AND_CALL, options: sendAndCallOptions });

    IOAppOptionsType3(oapp).setEnforcedOptions(enforcedOptions);
}
```

**No changes needed to existing OFT contracts.**

### HyperLiquidComposer Contract

The Composer contract is available in the devtools library:
- Location: `lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidComposer.sol`
- Example: `lib/devtools/examples/oft-hyperliquid/contracts/MyHyperLiquidComposer.sol`

**One Composer per token** - each Composer is tied to a specific OFT and HyperCore token index.

### Constructor Parameters

```solidity
constructor(
    address _oft,           // UP OFT on HyperEVM: 0x642fFC3496AcA19106BAB7A42F1F221a329654fe
    uint64 _coreIndexId,    // HyperCore token index (FROM STEP 3)
    int8 _assetDecimalDiff  // EVM decimals (18) - Core decimals (TBD)
)
```

| Parameter | Value | Notes |
|-----------|-------|-------|
| `_oft` | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` | UP OFT on HyperEVM |
| `_coreIndexId` | **TBD** | Created when UP is listed on HyperCore (Step 3) |
| `_assetDecimalDiff` | `10` or `12` | UP EVM (18) - UP Core (6 or 8) |

### Asset Bridge Address

The asset bridge address is computed from the Core Index ID:
```
Asset Bridge = 0x2000000000000000000000000000000000000000 + _coreIndexId
```

Example: If `_coreIndexId = 1234`, bridge = `0x20000000000000000000000000000000000004D2`

### Key Precompiles on HyperEVM

```solidity
address constant HLP_CORE_WRITER = 0x3333333333333333333333333333333333333333;
address constant SPOT_BALANCE_PRECOMPILE = 0x0000000000000000000000000000000000000801;
address constant CORE_USER_EXISTS_PRECOMPILE = 0x0000000000000000000000000000000000000810;
address constant HYPE_ASSET_BRIDGE = 0x2222222222222222222222222222222222222222;
```

## Dependencies

### Step 3 Must Happen First (Partially)

The Composer **requires the `_coreIndexId`** at deployment time. Order:

1. **Step 3 (partial)**: List UP as HIP-1 token on HyperCore
   - Creates the Core Index ID
   - Determines asset bridge address

2. **Step 2**: Deploy Composer with the known index ID

3. **Step 3 (completion)**: Link EVM ERC20 ↔ HIP-1 via asset bridge
   - `requestEvmContract` from HyperCore
   - `finalizeEvmContract` from HyperEVM

### Questions for Step 3 Team

1. **What is the Core Index ID for UP?** (needed for Composer deployment)
2. **What decimals will UP HIP-1 have?** (6 or 8 - affects `_assetDecimalDiff`)
3. **Has the asset bridge been funded?**

## Post-Deployment Requirements

### 1. Activate Composer on HyperCore

The Composer contract address must be "activated" on HyperCore before it can execute `CoreWriter` transfers.

### 2. Fund Asset Bridge

Mint `u64.max` (18,446,744,073,709,551,615) UP HIP-1 tokens to the bridge address on HyperCore side.

**Critical Warning**: "If you try to bridge more tokens than available on the destination side of the bridge, all tokens will be locked in the asset bridge address forever."

### 3. Enable Big Blocks (if needed)

For large deployments:
```bash
npx @layerzerolabs/hyperliquid-composer set-block --size big \
  --network mainnet --private-key $PRIVATE_KEY
```

Or submit L1 action:
```json
{"type": "evmUserModify", "usingBigBlocks": true}
```

## User Integration

### How Users Send with Compose

```solidity
// Encode the compose message (standardized 64-byte format)
bytes memory composeMsg = abi.encode(
    uint256(0),              // minMsgValue (0 if no HYPE needed)
    receiverOnHyperCore      // Final recipient address
);

SendParam memory params = SendParam({
    dstEid: HYPEREVM_EID,                              // 30367
    to: bytes32(uint256(uint160(composerAddress))),   // Send TO the Composer
    amountLD: amount,
    minAmountLD: minAmount,
    extraOptions: options,
    composeMsg: composeMsg,                            // Triggers compose
    oftCmd: ""
});

upOft.send(params, fee, refundAddress);
```

### Error Handling

Failed messages are stored in `failedMessages` mapping for crosschain refund:
- Failed transfers refund tokens to receiver on HyperEVM
- Can call `refundToSrc(guid)` to refund back to source chain

## Gas Requirements

| Operation | Gas Limit |
|-----------|-----------|
| `lzReceive` | 300,000 |
| `lzCompose` | 1,000,000 |
| Composer `MIN_GAS()` | 150,000 |
| Composer `MIN_GAS_WITH_VALUE()` | 200,000 |

The 1,000,000 compose gas limit is sufficient for the Composer operations.

## Files Reference

### Existing Contracts
- `src/UP/UpOFT.sol` - Native OFT on non-Ethereum chains
- `src/UP/UpOFTAdapter.sol` - OFT Adapter on Ethereum
- `script/DeployUpOFT.s.sol` - Deployment and configuration script

### Deployment Outputs
- `script/output/prod/999/UpOFT-latest.json` - HyperEVM OFT address
- `script/output/prod/8453/UpOFT-latest.json` - Base OFT address
- `script/output/prod/1/UpOFT-latest.json` - Ethereum Adapter address

### LayerZero Composer Library
- `lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidComposer.sol`
- `lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidCore.sol`
- `lib/devtools/packages/hyperliquid-composer/contracts/interfaces/IHyperLiquidComposer.sol`
- `lib/devtools/packages/hyperliquid-composer/contracts/library/HyperLiquidComposerCodec.sol`
- `lib/devtools/examples/oft-hyperliquid/contracts/MyHyperLiquidComposer.sol`

## Implementation Tasks

1. [ ] Get Core Index ID from Step 3 team
2. [ ] Confirm UP HIP-1 decimals (6 or 8)
3. [ ] Create `UpHyperLiquidComposer.sol` contract (thin wrapper)
4. [ ] Create deployment script `DeployUpComposer.s.sol`
5. [ ] Deploy Composer on HyperEVM mainnet
6. [ ] Activate Composer address on HyperCore
7. [ ] Verify asset bridge is funded
8. [ ] Test end-to-end: Base → HyperEVM → HyperCore
9. [ ] Update documentation

## Documentation References

- [HyperLiquid Composer Concepts](https://docs.layerzero.network/v2/developers/hyperliquid/hyperliquid-concepts#11-hyperliquid-composer)
- [Asset Bridge Documentation](https://docs.layerzero.network/v2/developers/hyperliquid/hyperliquid-concepts#8-the-asset-bridge-linking-evm-spot-erc20-and-core-spot-hip-1)
- [HyperLiquid GitBook](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm)
