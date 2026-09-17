---
title: HyperLiquid Composer Integration for UP Token
category: new-feature
date: 2026-02-25
spec: /specs/hyperliquid-composer/spec.md
components: [src/UP/UpHyperLiquidComposer.sol, script/DeployUpComposer.s.sol]
tags: [layerzero, hyperliquid, oft, composer, hypercore, cross-chain]
---

# HyperLiquid Composer Integration for UP Token

## Summary

Implemented a HyperLiquidComposer contract that enables UP token holders to bridge directly from Base/Ethereum into HyperCore spot trading. The Composer acts as a middleware that receives LayerZero composed messages and forwards tokens to HyperCore via precompiles.

Key insight: HyperCore decimals are **configurable** during HIP-1 deployment (0-15 via API, 0-8 via UI), not fixed at 8. Recommend using 18 decimals (same as EVM) to avoid precision loss.

## Implementation Details

### Key Decisions

1. **Extend RecoverableComposer** - Provides emergency fund recovery functions for stuck tokens on both HyperEVM and HyperCore sides.

2. **MPC Wallet as Recovery Address** - The MPC wallet (`0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153`) is set as the recovery address, not the deployer.

3. **Deterministic Deployment** - Uses the same CREATE2 salt pattern as existing UP OFT contracts for address predictability.

4. **Placeholder Values** - Deployment script uses TODO markers for `CORE_INDEX_ID` and `ASSET_DECIMAL_DIFF` since these depend on Step 3 team.

### Constructor Pattern for RecoverableComposer

When extending `RecoverableComposer`, you must call both parent constructors explicitly:

```solidity
import { HyperLiquidComposer } from "lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidComposer.sol";
import { RecoverableComposer } from "lib/devtools/packages/hyperliquid-composer/contracts/extensions/RecoverableComposer.sol";

contract UpHyperLiquidComposer is RecoverableComposer {
    constructor(
        address _oft,
        uint64 _coreIndexId,
        int8 _assetDecimalDiff,
        address _recoveryAddress
    )
        RecoverableComposer(_recoveryAddress)
        HyperLiquidComposer(_oft, _coreIndexId, _assetDecimalDiff)
    { }
}
```

**Important**: You must import `HyperLiquidComposer` directly even though `RecoverableComposer` extends it. Otherwise you get "Identifier not found" errors.

### HyperCore Decimals Are Configurable

The `assetDecimalDiff` parameter is `EVM_decimals - Core_decimals`:

| Core weiDecimals | assetDecimalDiff | Notes |
|-----------------|------------------|-------|
| 18 | 0 | No scaling, simplest (recommended) |
| 8 | 10 | Like HYPE token |
| 6 | 12 | Like USDC |

**Source**: HyperLiquid API supports 0-15 decimals (UI limits to 0-8). This is decided during HIP-1 token deployment.

### Recovery Functions Available

From `RecoverableComposer`:
- `retrieveCoreERC20(uint64)` - Pull tokens from HyperCore back to asset bridge
- `retrieveCoreHYPE(uint64)` - Pull HYPE from HyperCore back to HYPE bridge
- `recoverEvmERC20(uint256)` - Recover ERC20 stuck on HyperEVM
- `recoverEvmNative(uint256)` - Recover native HYPE stuck on HyperEVM

Pass `0` to recover full balance.

## Testing Strategy

1. **Compilation Test** - Verify contract compiles with `forge build`
2. **Fork Test** - Mock HyperLiquid precompiles for local testing:
   - `HLP_CORE_WRITER` (0x3333...)
   - `SPOT_BALANCE_PRECOMPILE` (0x0801)
   - `CORE_USER_EXISTS_PRECOMPILE` (0x0810)
3. **End-to-End Test** - Test full flow: Base → HyperEVM → HyperCore (requires testnet)

## Prevention & Best Practices

### Deployment Checklist

1. **Before deployment**:
   - Get `CORE_INDEX_ID` from Step 3 team
   - Get `weiDecimals` choice from Step 3 team
   - Calculate `assetDecimalDiff = 18 - weiDecimals`
   - Update constants in `DeployUpComposer.s.sol`

2. **During deployment**:
   - HyperEVM uses big blocks (30M gas) for deployments, small blocks (2M gas) normally
   - May need to switch block size: `npx @layerzerolabs/hyperliquid-composer set-block --size big`

3. **After deployment**:
   - Activate Composer on HyperCore (send $1+ USDC/HYPE)
   - Verify via `coreUserExists` precompile
   - Test compose flow end-to-end

### Common Pitfalls

| Pitfall | Prevention |
|---------|------------|
| Deploying without Core Index ID | Check `CORE_INDEX_ID != 0` in deploy script |
| Wrong decimal diff | Confirm with Step 3 team before deployment |
| Composer not activated | Send $1+ to Composer address on HyperCore |
| Forgetting to import HyperLiquidComposer | Always import both parent contracts |

## Related Documentation

- [LayerZero HyperLiquid Composer Docs](https://docs.layerzero.network/v2/developers/hyperliquid/hyperliquid-concepts#11-hyperliquid-composer)
- [HIP-1 Token Standard](https://hyperliquid.gitbook.io/hyperliquid-docs/hyperliquid-improvement-proposals-hips/hip-1-native-token-standard)
- [RecoverableComposer Source](https://github.com/LayerZero-Labs/devtools/blob/e149a722de12a8a47bf77c85895f16c3fa82d8bb/packages/hyperliquid-composer/contracts/extensions/RecoverableComposer.sol)
- Technical Spec: `/specs/hyperliquid-composer/technical-spec.md`
