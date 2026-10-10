# Spec: HyperLiquid Composer for UpOFT

**Status:** Ready for Implementation (pending Step 3 dependencies)
**Priority:** High
**Blocked By:** Core Index ID and weiDecimals from Step 3 team

---

## Summary

Deploy a HyperLiquidComposer contract on HyperEVM that enables UP token bridging directly into HyperCore spot trading. This is Step 2 of the LayerZero/HyperLiquid integration.

## Context

| Step | Description | Status |
|------|-------------|--------|
| 1 | OFT deployment on Base + HyperEVM | ✅ Complete |
| 2 | HyperLiquid Composer deployment | 🔄 This ticket |
| 3 | HIP-1 token creation on HyperCore | ⏳ Blocking |

**Current State:** Users can bridge UP to HyperEVM but tokens are stuck there. Cannot access HyperCore spot trading.

**Goal State:** Users bridge UP from Base/Ethereum → tokens arrive directly in HyperCore spot wallet.

## Requirements

### Functional
1. Deploy `UpHyperLiquidComposer` contract on HyperEVM (extends RecoverableComposer)
2. Enable compose flow: Source chain → HyperEVM OFT → Composer → HyperCore
3. Handle failed message refunds via `refundToSrc(guid)`
4. Enable emergency fund recovery via RecoverableComposer functions

### Non-Functional
1. Gas efficient - must work within 1M compose gas limit (requires ~150-200k)
2. Deterministic deployment using existing salt pattern
3. Ownership transferable (deployer → MPC wallet)

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Contract type | RecoverableComposer | Enables emergency fund recovery |
| Recovery address | MPC wallet | `0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153` |
| Core decimals | **Recommend 18** | Avoids precision loss (configurable in Step 3) |

## Dependencies

### Blocking (from Step 3 team)
- [ ] Core Index ID for UP on HyperCore
- [ ] weiDecimals for UP HIP-1 token (recommend 18)

### Non-Blocking
- [ ] Asset bridge funding (post-deployment)
- [ ] Composer activation on HyperCore ($1 USDC/HYPE)

## Deliverables

1. **Contract:** `src/UP/UpHyperLiquidComposer.sol`
2. **Deploy Script:** `script/DeployUpComposer.s.sol`
3. **Output:** `script/output/prod/999/UpComposer-latest.json`

## Implementation Steps

1. [ ] Create `UpHyperLiquidComposer.sol` (extends RecoverableComposer)
2. [ ] Create deployment script with big block handling
3. [ ] Wait for Core Index ID + weiDecimals from Step 3
4. [ ] Deploy to HyperEVM mainnet
5. [ ] Activate Composer on HyperCore
6. [ ] Transfer ownership to MPC wallet
7. [ ] Verify end-to-end flow
8. [ ] Test recovery functions

## Key Addresses

| Contract | Address |
|----------|---------|
| UP OFT (HyperEVM) | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` |
| LZ Endpoint | `0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9` |
| MPC Wallet (final owner) | `0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153` |
| Deployer | `0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8` |

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Core Index ID delays | Blocks deployment | Prepare all code, deploy immediately when available |
| Asset bridge not funded | Tokens refund to HyperEVM instead of Core | Ensure bridge funded before user testing |
| Precision loss (if <18 decimals) | Dust amounts lost | Recommend 18 decimals to Step 3 team |

## References

- [Technical Spec](./technical-spec.md)
- [Interview Notes](./interview-notes.md)
- [Framework Docs](./research/framework-docs.md)
- [Best Practices](./research/best-practices.md)
- [Repo Analysis](./research/repo-analysis.md)
