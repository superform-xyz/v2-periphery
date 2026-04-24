# Stargate V2 Bridge Hook - Interview Notes

## Date: 2026-04-23

## Context

The user needs a bridge hook for SuperBank that uses Stargate V2 (LayerZero OFT) for cross-chain token bridging. This is needed because Across and DeBridge are not available on Flare (chain 14), but Stargate V2 / LayerZero OFT is.

## Feature Summary

Create two new bridge hooks in v2-core:
1. **StargateV2SendHook** - for native ETH sends (no ERC20 approve needed, or pre-approved tokens)
2. **ApproveAndStargateV2SendHook** - approve + send pattern for ERC20 tokens

Both hooks must support two fee payment options:
- **Native ETH fee** - pay cross-chain messaging fee in ETH (`_payInLzToken = false`)
- **LZ token fee** - pay in LZ/ZRO token (`_payInLzToken = true`)

## Requirements

### Functional
1. Bridge tokens cross-chain using `IOFT.send()` from LayerZero OFT standard
2. Support both native ETH and LZ token fee payment (controlled by a flag in hook data)
3. Follow existing bridge hook patterns (Across, DeBridge) in v2-core
4. Implement `inspect()` for merkle leaf generation
5. Implement `_buildHookExecutions()` returning `Execution[]`
6. Support `usePrevHookAmount` for chaining with prior hooks
7. Support `composeMsg` for destination-chain execution (with signature appending via VALIDATOR)
8. ApproveAndStargateV2SendHook must handle approve(0) -> approve(amount) -> send -> approve(0) pattern

### Non-Functional
- ~200 LOC per hook (similar to Across)
- Hardcoded hook type: `HookType.NONACCOUNTING`, `HookSubTypes.BRIDGE`
- Must work with SuperBank's merkle tree registration flow

## Technical Decisions

### Target Contract
- Calls `IOFT.send()` on the OFT/OFTAdapter contract directly
- The OFT address is passed in hookData (not hardcoded as immutable, since there could be many OFTs)
- OR: OFT address is an immutable (one hook instance per OFT, matching Across pattern where SPOKE_POOL is immutable)

**Decision: OFT address as immutable** - consistent with Across/DeBridge patterns. Deploy one hook instance per OFT target.

### Fee Payment
- `payInLzToken` boolean flag in hook data
- When `payInLzToken = true`:
  - `quoteSend()` returns `MessagingFee` with `lzTokenFee > 0`
  - `send()` requires LZ token allowance from msg.sender to endpoint
  - For ApproveAndStargateV2SendHook: need additional approve for LZ token to OFT contract
- When `payInLzToken = false`:
  - Pay `msg.value` in native ETH
  - `fee.lzTokenFee == 0`

### Hook Data Layout (tightly packed bytes, BytesLib)
```
offset   0  → uint256  value              (ETH to send with call)
offset  32  → uint32   dstEid             (destination endpoint ID)
offset  36  → bytes32  to                 (destination recipient, bytes32 for non-EVM)
offset  68  → uint256  amountLD           (amount in local decimals)
offset 100  → uint256  minAmountLD        (minimum amount, slippage protection)
offset 132  → bool     usePrevHookAmount
offset 133  → bool     payInLzToken
offset 134  → uint256  nativeFee          (pre-quoted native fee)
offset 166  → uint256  lzTokenFee         (pre-quoted LZ token fee)
offset 198  → bytes    extraOptions       (variable length, prefixed with uint256 length)
offset ???  → bytes    composeMsg         (variable length, prefixed with uint256 length)
offset ???  → bytes    oftCmd             (variable length, prefixed with uint256 length)
```

### inspect() Returns
```solidity
abi.encodePacked(
    dstEid,       // uint32
    to,           // bytes32
    payInLzToken  // bool
)
```
These are the security-critical parameters that define what the hook is authorized to do.

### Signature Handling
If `composeMsg.length > 0`, decode as `(bytes initData, bytes executorCalldata, address account, address[] dstTokens, uint256[] intentAmounts)`, append signature from VALIDATOR, re-encode - matching the Across/DeBridge pattern.

## Risks & Security

1. **Fee manipulation**: Pre-quoted fees could be stale. The hook should use `quoteSend()` on-chain or accept pre-quoted fees and let LZ endpoint validate.
2. **Token approval**: ApproveAndStargateV2SendHook must zero approvals before and after.
3. **LZ token fee path**: When paying in LZ token, the smart account needs LZ token balance and approval.
4. **Dust/rounding**: OFT uses 6 shared decimals - amounts get truncated. `minAmountLD` provides slippage protection.
5. **Cross-chain message replay**: Handled by LayerZero protocol (nonces, GUIDs).
6. **usePrevHookAmount**: Must correctly scale `minAmountLD` proportionally (mulDiv pattern).

## Testing Strategy
- Unit tests for constructor validation
- Unit tests for `build()` execution count and calldata correctness
- Unit tests for `inspect()` output
- Unit tests for `usePrevHookAmount` scaling
- Unit tests for both fee payment modes
- Integration tests with forked mainnet OFT contracts
