# Stargate V2 Bridge Hook Spec

## Metadata
- Project: v2-core
- Milestone: Flare Chain Support
- Linear Issue: SUP-19393
- Interview Date: 2026-04-23
- Status: [x] Draft / [ ] Ready for Review / [ ] Approved

## Summary

Create two bridge hooks for SuperBank in v2-core that bridge tokens cross-chain using LayerZero's OFT (Omnichain Fungible Token) standard. This enables bridging on chains where Across and DeBridge are unavailable (notably Flare, chain 14).

The hooks call `IOFT.send()` on a target OFT/OFTAdapter contract. Both support native ETH and LZ token fee payment modes. The implementation follows existing Across bridge hook patterns exactly.

## Requirements

### Functional
1. `StargateV2SendHook` calls `IOFT.send()` with correct `SendParam`, `MessagingFee`, and `refundAddress`
2. `ApproveAndStargateV2SendHook` adds 4-execution approve pattern: `approve(0) -> approve(amount) -> send -> approve(0)`
3. Both support native ETH fee payment (`lzTokenFee = 0`, `msg.value = nativeFee`)
4. Both support LZ token fee payment (`lzTokenFee > 0`, smart account must pre-approve ZRO)
5. `usePrevHookAmount` correctly scales `amountLD` and `minAmountLD` via `Math.mulDiv`
6. `composeMsg` signature injection appends signature from VALIDATOR transient storage
7. `inspect()` returns only packed addresses (OFT contract + recipient)
8. Constructor validates zero addresses for both `oft_` and `validator_`

### Non-Functional
- ~200 LOC per hook (consistent with Across hooks)
- `HookType.NONACCOUNTING`, `HookSubTypes.BRIDGE`
- Apache-2.0 license, `pragma solidity 0.8.30;`
- Full unit test coverage

## Technical Design

### Architecture

Two contracts in `src/hooks/bridges/stargate/`, one vendor interface in `src/vendor/bridges/stargate/`:

```
src/hooks/bridges/stargate/
├── StargateV2SendHook.sol          (1 execution: send)
└── ApproveAndStargateV2SendHook.sol (4 executions: approve(0), approve(amt), send, approve(0))

src/vendor/bridges/stargate/
└── IOFT.sol                        (SendParam, MessagingFee, MessagingReceipt, OFTReceipt, IOFT)

test/unit/hooks/bridges/
└── StargateHooks.t.sol
```

Both hooks inherit `BaseHook` and implement `ISuperHookContextAware`. OFT address is an immutable constructor parameter (one hook instance per OFT target, matching the Across pattern where `SPOKE_POOL_V3` is immutable).

### Data Model

Tightly packed hook data (BytesLib, fixed-offset style):

| Offset | Type | Field | Description |
|--------|------|-------|-------------|
| 0 | uint256 | value | ETH to send (nativeFee + bridgeAmount for native OFT) |
| 32 | uint32 | dstEid | LZ destination endpoint ID |
| 36 | bytes32 | to | Recipient address (bytes32-padded) |
| 68 | uint256 | amountLD | Amount in local decimals |
| 100 | uint256 | minAmountLD | Minimum amount (slippage) |
| 132 | uint256 | nativeFee | Pre-quoted native fee |
| 164 | uint256 | lzTokenFee | Pre-quoted LZ token fee (0 = native) |
| 196 | bool | usePrevHookAmount | Use previous hook output |
| 197+ | bytes | extraOptions, composeMsg, oftCmd | Variable-length, length-prefixed |

### API Changes

New vendor interface `IOFT.sol`:
```solidity
interface IOFT {
    function send(SendParam calldata, MessagingFee calldata, address refundAddress)
        external payable returns (MessagingReceipt memory, OFTReceipt memory);
    function token() external view returns (address);
    function approvalRequired() external view returns (bool);
}
```

## Implementation Plan

### Phase 1: Contracts
- [ ] Create `src/vendor/bridges/stargate/IOFT.sol` with structs and interface
- [ ] Create `src/hooks/bridges/stargate/StargateV2SendHook.sol`
- [ ] Create `src/hooks/bridges/stargate/ApproveAndStargateV2SendHook.sol`

### Phase 2: Tests
- [ ] Create `test/unit/hooks/bridges/StargateHooks.t.sol`
- [ ] Constructor validation tests (zero address revert)
- [ ] `_buildHookExecutions` tests (execution count, targets, callData)
- [ ] `inspect()` tests (returns only addresses)
- [ ] `usePrevHookAmount` scaling tests
- [ ] `composeMsg` signature injection tests
- [ ] Both fee payment mode tests

## Test Plan
- [ ] Unit tests for: constructor validation, build execution count & calldata, inspect output, usePrevHookAmount scaling, composeMsg signature injection, both fee modes
- [ ] Integration tests for: mainnet fork bridge via OFTAdapter with native fee, bridge with usePrevHookAmount, dust handling on non-aligned amounts
- [ ] Fuzz tests for: random amounts through send (dust handling), random fee values, usePrevHookAmount with random prev amounts

## Risks & Mitigations
| Risk | Category | Likelihood | Impact | Mitigation | Precedent |
|------|----------|------------|--------|------------|-----------|
| OFT address controlled by attacker | Access Control | Low | Critical | Immutable constructor parameter | Across OFT audit finding |
| refundAddress set to hook contract | Operational | Medium | High | Hardcode `account` as refundAddress | Across OFT audit 2024 |
| USDT approve race condition | Token Behavior | Medium | Medium | 4-step approve(0)->approve(amt)->send->approve(0) | SWC-114 |
| Stale fee quotes causing reverts | Operational | Medium | Low | Bundler quotes at assembly time, LZ endpoint validates | - |
| OFT dust truncation (6 shared decimals) | Business Logic | High | Low | minAmountLD slippage protection, bundler dust-aware | - |
| composeMsg injection on destination | Cross-Chain | Low | High | Keep composeMsg empty for simple bridges, LZ nonce replay protection | Nomad 2022 - $190M |
| LZ token approval not handled in hook | Token Behavior | Low | Low | Smart account pre-approves ZRO via separate hook in bundle | Design decision |

## Open Questions (Resolved)
| Question | Answer | Decided By |
|----------|--------|------------|
| OFT address: immutable or in hookData? | Immutable constructor param (one instance per OFT) | Matches Across/DeBridge pattern |
| LZ token fee: extra approve executions? | No, smart account pre-approves ZRO separately | Keeps hook simpler |
| inspect() returns? | Only addresses: OFT + recipient | hooks-master.md convention |
| Fee encoding? | Both nativeFee and lzTokenFee in data, bundler sets one to 0 | Supports both modes |

## Interview Notes
See: [interview-notes.md](./interview-notes.md)

## Technical Details
See: [technical-spec.md](./technical-spec.md)

## Research
See: [research/](./research/)

---

## Approval
- [ ] Pod Leader Approved
- Approved date: ___

## Next Steps
After approval, run: `/superform:work specs/stargate-v2-bridge-hook/technical-spec.md`
