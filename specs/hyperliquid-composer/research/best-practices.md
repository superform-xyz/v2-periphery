# Best Practices for HyperLiquid Composer Deployment

## 1. Block Size Management

**Critical**: HyperEVM uses two block types with different gas limits:

| Block Type | Block Time | Gas Limit | Use Case |
|------------|-----------|-----------|----------|
| Small (default) | 1 second | 2M gas | Normal transactions |
| Big | 1 minute | 30M gas | Contract deployments |

**Deployment Workflow**:
```bash
# Step 1: Switch to big blocks before deployment
npx @layerzerolabs/hyperliquid-composer set-block --size big --network mainnet --private-key $PRIVATE_KEY

# Step 2: Deploy contracts

# Step 3: Switch back to small blocks
npx @layerzerolabs/hyperliquid-composer set-block --size small --network mainnet --private-key $PRIVATE_KEY
```

---

## 2. Security Considerations

### Must-Have Security Validations

**1. Validate Caller Identity in `lzCompose`**:
```solidity
function lzCompose(...) external payable override nonReentrant {
    if (msg.sender != ENDPOINT) revert OnlyEndpoint();
    if (OFT != _oft) revert InvalidComposeCaller(address(OFT), _oft);
    // ... rest
}
```

**2. ReentrancyGuard**: The reference implementation uses OpenZeppelin's `ReentrancyGuard` on `lzCompose`.

**3. Self-Call Pattern**: External operations use try-catch with self-calls for isolation.

### Gas and Value Assumptions

**Warning**: Do not rely on specified gas limits and `msg.value` in `lzReceive`/`lzCompose`. These are off-chain executor agreements only.

**Mitigation strategies**:
- Encode expected `msg.value` in the payload
- Enforce minimum gas requirements before critical operations

---

## 3. Asset Bridge Funding and Capacity Management

### Critical Warning

> Hyperliquid has **no checks** for asset bridge capacity. If you try to bridge more tokens than available on the destination side of the bridge, **all tokens will be locked in the asset bridge address forever**.

### Funding Requirements

1. **Full Supply Minting**: Mint the **entire** HIP-1 token supply to the HyperCore asset bridge address
2. **No Partial Funding**: Partially funding the bridge creates orphaned tokens
3. **Compute Bridge Address**: `0x2000000000000000000000000000000000000000 + coreIndexId`

---

## 4. Composer Activation on HyperCore

### Activation Requirements

**Both deployer and Composer addresses must be activated on HyperCore**:
- Send at least **$1 worth of USDC or HYPE** to each address on HyperCore
- Required for L1 operations including block switching and CoreWriter actions

**Error if not activated**: `L1 error: User or API Wallet <public key> does not exist`

---

## 5. Error Handling and Refund Mechanisms

### Multi-Layer Refund Architecture

**Layer 1**: Message Decode Failure → Stored in `failedMessages` for cross-chain refund
**Layer 2**: HyperCore Transfer Failure → Auto-refund to HyperEVM
**Layer 3**: Manual cross-chain refund via `refundToSrc(guid)`

### Common Error Scenarios

| Scenario | Behavior | Recovery |
|----------|----------|----------|
| Malformed composeMsg | Stored in `failedMessages` | Call `refundToSrc(guid)` |
| Inactive receiver | Reverts `handleTransfersToHyperCore` | Auto-refund to HyperEVM |
| Insufficient bridge capacity | Prevented by `quoteHyperCoreAmount` | Auto-refund to HyperEVM |
| Insufficient gas | Reverts with `InsufficientGas` | Retry with more gas |

---

## 6. Gas Optimization

### Minimum Gas Requirements

- `MIN_GAS() = 150_000` (without native value transfer)
- `MIN_GAS_WITH_VALUE() = 200_000` (with native value transfer)

### LayerZero Options Configuration

```typescript
const options = Options.newOptions()
    .addExecutorLzReceiveOption(50000, 0)
    .addExecutorLzComposeOption(0, 200000, 0);
```

---

## 7. Production Deployment Checklist

### Pre-Deployment
- [ ] Deployer address funded with $1+ USDC/HYPE on HyperCore
- [ ] Private key secured
- [ ] All peers configured for cross-chain OFT wiring
- [ ] Gas limits profiled

### Composer Deployment
- [ ] Switch to big blocks before deployment
- [ ] Deploy Composer contract
- [ ] Switch back to small blocks
- [ ] Fund Composer address with $1+ on HyperCore
- [ ] Verify Composer activation via `coreUserExists` precompile

### Post-Deployment Verification
- [ ] Test compose message delivery end-to-end
- [ ] Test refund mechanisms
- [ ] Verify decimal scaling between EVM and HyperCore
- [ ] Monitor bridge capacity and balances

---

## Common Pitfalls to Avoid

| Pitfall | Consequence | Prevention |
|---------|-------------|------------|
| Deploying without big blocks | Transaction fails (exceeds 2M gas) | Always switch to big blocks first |
| Not activating addresses on HyperCore | L1 operations fail | Fund with $1+ USDC/HYPE |
| Partial bridge funding | Orphaned tokens, cannot withdraw | Mint full supply to bridge |
| Insufficient compose gas | Silent message failures | Profile and set adequate gas |
| Not validating `msg.sender` in `lzCompose` | Unauthorized execution | Always check `ENDPOINT` and `OFT` |
