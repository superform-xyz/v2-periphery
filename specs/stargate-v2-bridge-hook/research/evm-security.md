# EVM Security Research: Stargate V2 / LayerZero OFT Bridge Hook

## Critical Findings Summary

| Priority | Finding | Mitigation |
|----------|---------|------------|
| **P0** | OFT address must be immutable, not user-controlled | Constructor parameter with zero-address check |
| **P0** | `_refundAddress` must be the smart account, not the hook | Hardcode `account` as refundAddress |
| **P0** | `msg.value` must exactly match `fee.nativeFee` | Pre-quoted fee encoded in hook data |
| **P1** | Approval pattern for OFTAdapter tokens | approve(0) -> approve(amount) -> send -> approve(0) |
| **P1** | `minAmountLD` must account for dust + Stargate protocol fee | Use `quoteOFT().amountReceivedLD` as basis |
| **P1** | `bytes32 to` encoding must be correct | `bytes32(uint256(uint160(address)))` |
| **P2** | LZ token fee path needs separate approval | Additional approve execution for ZRO token |
| **P2** | `dstEid` is LZ endpoint ID, not chainId | Document clearly in NatSpec |
| **P3** | `extraOptions` duplication with enforced options | Pass empty for Stargate pools |

## Relevant Vulnerability Patterns

### 1. Token Approval
- ERC20 approve race condition (SWC-114)
- USDT requires approve(0) before approve(amount)
- Mitigation: 4-step pattern (reset, set, execute, reset) per existing codebase convention

### 2. msg.value Handling
- `_payNative()` enforces `msg.value == nativeFee` exactly (reverts on mismatch)
- For NativeOFTAdapter: `msg.value` = LZ fee + bridge amount
- For ERC20 OFTAdapter: `msg.value` = LZ fee only
- Excess ETH refunded to `_refundAddress`

### 3. Cross-Chain Message Security
- `composeMsg` callbacks don't have built-in source verification (unlike `lzReceive`)
- Composer contract must verify `msg.sender == endpoint` and `_from == expectedOFT`
- For SuperBank: keep `composeMsg` empty unless explicitly needed

### 4. Reentrancy
- LOW risk: OFT.send() calls into LZ endpoint, not back to caller
- BaseHook mutex provides additional protection
- SuperExecutorBase `nonReentrant` provides outer guard

### 5. Dust/Rounding
- OFT uses 6 shared decimals, `decimalConversionRate = 10^12` for 18-decimal tokens
- Sub-`1e12` amounts silently truncated
- Setting `minAmountLD = amountLD` for non-aligned amounts causes `SlippageExceeded`
- Approval must be for pre-dust-removal amount (adapter pulls full `amountLD`)

## Exploit Precedents

| Protocol | Date | Loss | Relevance |
|----------|------|------|-----------|
| KelpDAO rsETH | Apr 2025 | $292M | 1-of-1 DVN config catastrophically insecure |
| Across OFT | 2024 | Audit finding | `_refundAddress` set to contract, not user |
| Code4rena Decent | Jan 2024 | Finding | Bridge adapter forwarded excess ETH incorrectly |
| Nomad Bridge | Aug 2022 | $190M | Message validation bypass |
| Ronin Bridge | Mar 2022 | $625M | Validator key compromise |

## Attack Surface Map

### Token Approval Manipulation
- Front-running approval between approve(amount) and send()
- Mitigated by: approve(0) reset pattern + single-tx atomic execution

### Fee Manipulation
- Stale fee quotes causing reverts or overpayment
- Mitigated by: bundler quotes at assembly time, refund to account

### msg.value Forwarding
- ETH sent as value to ERC20 OFT (only fee should be forwarded)
- Mitigated by: clear separation in hook data layout

### Cross-Chain Message Injection
- Attacker injecting compose messages on destination
- Mitigated by: keeping composeMsg empty for simple bridge operations

### usePrevHookAmount Scaling
- Proportional scaling with mulDiv could underflow on very small amounts
- Mitigated by: amount != 0 check after scaling

## Recommended Security Patterns

1. CEI (Checks-Effects-Interactions) for external calls
2. approve(0) -> approve(amount) -> execute -> approve(0) pattern
3. `msg.value` validation via LZ endpoint's `_payNative()` (automatic)
4. Input validation: zero-address checks, amount != 0, data length check
5. Immutable OFT address (not user-controllable)
6. `account` as refundAddress (not hook contract)

## Testing Recommendations

### Fuzz Tests
- Random amounts through send() - verify dust handling
- Random fee values - verify msg.value forwarding
- usePrevHookAmount with random prev amounts - verify mulDiv scaling
- Edge case: amount < decimalConversionRate (entirely lost to dust)

### Invariant Tests
- Approvals always zero after hook execution
- refundAddress always equals account
- msg.value in execution matches encoded fee
- inspect() returns only addresses

### Integration Tests (Mainnet Fork)
- Bridge ERC20 via OFTAdapter with native fee
- Bridge with usePrevHookAmount
- Verify dust handling on non-aligned amounts
- Verify fee refund to account
