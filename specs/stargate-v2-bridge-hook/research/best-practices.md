# Best Practices: Stargate V2 / LayerZero OFT Bridge Integration

## IOFT.send() Interface

```solidity
function send(
    SendParam calldata _sendParam,
    MessagingFee calldata _fee,
    address _refundAddress
) external payable returns (MessagingReceipt memory, OFTReceipt memory);
```

### SendParam struct
```solidity
struct SendParam {
    uint32 dstEid;        // Destination endpoint ID
    bytes32 to;           // Recipient (bytes32 for non-EVM support)
    uint256 amountLD;     // Amount in local decimals
    uint256 minAmountLD;  // Minimum (slippage protection)
    bytes extraOptions;   // LZ executor options
    bytes composeMsg;     // Composed message for dst execution
    bytes oftCmd;         // OFT-specific command (unused in default)
}
```

### MessagingFee struct
```solidity
struct MessagingFee {
    uint256 nativeFee;    // Native gas token fee
    uint256 lzTokenFee;   // LZ/ZRO token fee (alternative)
}
```

## Fee Payment Modes

1. **Native ETH** (`_payInLzToken = false`):
   - `msg.value` must equal `fee.nativeFee` exactly
   - `_payNative()` enforces: `if (msg.value != _nativeFee) revert NotEnoughNative(msg.value)`

2. **LZ Token** (`_payInLzToken = true`):
   - `fee.lzTokenFee > 0`
   - `_payLzToken()` calls `IERC20(lzToken).safeTransferFrom(msg.sender, endpoint, lzTokenFee)`
   - Caller needs LZ token balance + approval to OFT contract

## Dust/Rounding

- OFT uses 6 shared decimals (`sharedDecimals = 6`)
- For 18-decimal tokens: `decimalConversionRate = 10^12`
- Amounts truncated: `amountSD = uint64(amountLD / decimalConversionRate)`
- Sub-`1e12` dust is lost on conversion
- `minAmountLD` provides slippage protection after dust removal

## Token Approval

- OFTAdapter requires `approve(adapter, amountLD)` before send
- OFT (burn/mint) burns from `msg.sender` directly - still needs approval
- `approvalRequired()` view function indicates if approval needed

## Key Considerations

1. **Pre-quote fees off-chain**: Use `quoteSend()` before constructing hook data
2. **refundAddress**: Should be the smart account (excess ETH refunded there)
3. **bytes32 recipient**: `bytes32(uint256(uint160(address)))` for EVM chains
4. **extraOptions**: Use OptionsBuilder for gas limits on destination
5. **composeMsg**: For executing code on destination (uses lzCompose)
