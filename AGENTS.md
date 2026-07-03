# AGENTS.md

This file provides guidance to Codex when working with code in this repository (v2-periphery).

## SuperBank Merkle Tree Registration

SuperBank uses merkle trees to authorize hook executions. The flow is simpler than SuperVault.

### Leaf Construction

```
hookArgs = ISuperHookInspector(hook).inspect(hookData)
leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
```

What `inspect()` returns varies per hook:
- **ApproveERC20Hook**: `abi.encodePacked(token, spender)`
- **SwapOdosV2Hook**: `abi.encodePacked(executor)`
- **ApproveAndSwapOdosV2Hook**: `abi.encodePacked(executor)`

### Registration Flow (via SuperGovernor)

1. **Register hooks** (one-time, requires `GOVERNOR_ROLE`):
   ```solidity
   superGovernor.registerHook(hookAddress);
   ```

2. **Propose merkle root** (requires `GOVERNOR_ROLE`):
   ```solidity
   superGovernor.proposeSuperBankHookMerkleRoot(hook, root);
   ```

3. **Wait for timelock** (7 days, hardcoded in `SuperGovernor.sol:90` as `uint256 private constant TIMELOCK = 7 days`):
   - Unlike SuperVault where the timelock is configurable via `SuperVaultAggregator.setHooksRootUpdateTimelock()` (defaults to 15 minutes), SuperBank's timelock is a constant and cannot be changed without redeploying SuperGovernor.
   - In tests, bypass with `vm.warp(block.timestamp + 7 days + 1)`.

4. **Execute update** (permissionless after timelock):
   ```solidity
   superGovernor.executeSuperBankHookMerkleRootUpdate(hook);
   ```

### Single-Leaf Trees (Simplest Case)

For a single authorized hook configuration, root == leaf and the merkle proof is empty:
```solidity
bytes32[][] memory proofs = new bytes32[][](n);
proofs[i] = new bytes32[](0); // empty proof
```

### Execution via SuperBank

Requires `BANK_MANAGER_ROLE`:
```solidity
superBank.executeHooks(IHookExecutionData.HookExecutionData({
    hooks: hooks,           // address[] of hook contracts
    data: data,             // bytes[] of encoded hook data
    merkleProofs: proofs,   // bytes32[][] of merkle proofs
    expectedAssetsOrSharesOut: expectedOut  // uint256[] slippage checks (0 = skip)
}));
```

### Role Granting in Tests (Forked Contracts)

OZ 5.x (non-upgradeable) AccessControl stores `_roles` at slot 0:
```solidity
bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
vm.store(governorAddress, hasRoleSlot, bytes32(uint256(1)));
```

### Key Production Addresses (Base Mainnet)

| Contract | Address |
|----------|---------|
| SuperBank | `0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15` |
| SuperGovernor | `0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4` |
| ApproveERC20Hook | `0x8b789980dc6cC7d88E30C442D704646ff7F6d306` |
| SwapOdosV2Hook | `0x074F9973EBfB050D7abc75a5cB03491d675DA843` |
| Odos Router V2 | `0x19cEeAd7105607Cd444F5ad10dd51356436095a1` |

### Odos Integration in Tests

Use `OdosAPIParser` from v2-core (via surl, no shell scripts needed):
```solidity
import { OdosAPIParser } from "@superform-v2-core/test/utils/parsers/OdosAPIParser.sol";

// Fetch quote
string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, sender, chainId, false);
string memory assembledHex = surlCallAssemble(pathId, sender);
OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
```
