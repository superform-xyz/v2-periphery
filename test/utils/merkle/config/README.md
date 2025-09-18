# Hook Setup Guide

This guide explains how to add new hooks to the Superform v2 merkle tree system for automated proof generation.

## Overview

The merkle tree system automatically generates proofs for hook execution by:
1. Detecting hook addresses from BaseTest deployment
2. Using hook configurations to generate argument combinations
3. Building merkle trees with all possible hook calls
4. Creating optimized lookup caches for efficient proof retrieval

## Step-by-Step Process

### Step 1: Add Hook to BaseTest.t.sol

Ensure your hook is included in `globalMerkleHooksPeriphery` array in BaseTest.t.sol:

```solidity
// In BaseTest.t.sol, around line 410-425
globalMerkleHooksPeriphery[X] = address(yourNewHook); // Replace X with next available index
```

**Important**: The hook must be deployed and accessible via `address(yourHook)` or from `hookAddresses[chainId][HOOK_KEY]`.

Add your hook address to the console logs in `GetAddressesFromBaseTest.s.sol`.
The console output from `GetAddressesFromBaseTest.s.sol` should show:
```
YourNewHook: 0x1234567890123456789012345678901234567890
```

### Step 2: Add Hook Configuration

Add your hook's argument definition to `hook_configs.json`:

```json
{
  "YourNewHook": {
    "args": [
      {
        "name": "argumentName",
        "type": "argumentType"
      }
    ]
  }
}
```

**Argument Types**:
- `"token"` - ERC20 token addresses from `tokens` section
- `"yieldSource"` - Vault/yield source addresses from `yieldSources` section  
- `"beneficiary"` - Owner/beneficiary addresses from `beneficiaries` section
- `"staking"` - Staking contract addresses from `staking` section

**Example Configurations**:

```json
{
  "ApproveAndDeposit4626VaultHook": {
    "args": [
      {
        "name": "yieldSource",
        "type": "yieldSource"
      },
      {
        "name": "token", 
        "type": "token"
      }
    ]
  },
  "MockNativeETHHook": {
    "args": [
      {
        "name": "yieldSource",
        "type": "yieldSource"
      }
    ]
  }
}
```

### Step 3: Add Required Addresses

Update `address_registry.json` with any new addresses your hook needs:

#### Adding Tokens
```json
{
  "tokens": {
    "1": [
      {
        "symbol": "NEWTOKEN",
        "address": "0x...",
        "category": "stablecoin|eth|governance"
      }
    ]
  }
}
```

#### Adding Yield Sources
```json
{
  "yieldSources": {
    "1": [
      {
        "symbol": "NewVault",
        "address": "0x...",
        "category": "lending|yield|rwa|leverage"
      }
    ]
  }
}
```

#### Adding Beneficiaries (new SuperVaults, basically the "owner" param in a hook)
```json
{
  "beneficiaries": {
    "1": [
      "0x1234567890123456789012345678901234567890"
    ]
  }
}
```

#### Adding Staking Addresses (these are yield sources, but for comprehension they are separated)
```json
{
  "staking": {
    "1": [
      {
        "symbol": "NewStaking",
        "address": "0x...",
        "category": "defi"
      }
    ]
  }
}
```

### Step 4: Regenerate Merkle Cache

Run the regeneration command:

```bash
make regenerate-merkle-cache
```

### Step 5: Verify Setup

Check that your hook is working:

```bash
make test-vvv  # or your specific test
```

The system should automatically:
- Detect your hook from console output
- Load its configuration from `hook_configs.json`
- Generate argument combinations using addresses from `address_registry.json`
- Include it in the global merkle tree
- Create lookup cache entries for efficient proof retrieval

## File Structure

```
test/utils/merkle/config/
├── README.md                 # This guide
├── hook_configs.json         # Hook argument definitions
├── address_registry.json     # Master address registry
└── GetAddressesFromBaseTest.s.sol  # Address extraction script
```

## Troubleshooting

### Dependancies Missing
- This process requires both `@openzeppelin/merkle-tree` and `ethers` packages, they can be installed in the root directory via:
  ```
  bash
  pnpm add -D @openzeppelin/merkle-tree
  pnpm add ethers@5.7.2
  ```
  Note: `ethers` must be installed at a version `<6.x`

### Hook Not Detected
- Verify hook is in `globalMerkleHooksPeriphery` array
- Check console output shows `YourHookName: 0x...` format
- Ensure hook name ends with "Hook" suffix

### Missing Configuration Error
- Add hook definition to `hook_configs.json`
- Verify JSON syntax is valid
- Check argument types match available address types

### No Addresses for Argument Type
- Add required addresses to `address_registry.json`
- Ensure addresses exist for the correct chain ID
- Verify address format is valid (0x...)

### Cache Not Updating
- Run `make force-regenerate-merkle-cache`
- Check for JavaScript errors in console output
- Verify all JSON files have valid syntax

### Categories
Use categories to organize and filter addresses:
- **Tokens**: `stablecoin`, `eth`, `governance`
- **Yield Sources**: `lending`, `yield`, `rwa`, `leverage`
- **Staking**: `defi`

## Example: Adding a New Swap Hook

1. **BaseTest.t.sol**:
```solidity
globalMerkleHooksPeriphery[12] = address(newSwapHook);
```

2. **hook_configs.json**:
```json
{
  "SwapHook": {
    "args": [
      {
        "name": "tokenIn",
        "type": "token"
      },
      {
        "name": "tokenOut", 
        "type": "token"
      }
    ]
  }
}
```

3. **address_registry.json** (if new tokens needed):
```json
{
  "tokens": {
    "1": [
      {
        "symbol": "NEWTOKEN",
        "address": "0x...",
        "category": "governance"
      }
    ]
  }
}
```

4. **Regenerate**:
```bash
make regenerate-merkle-cache
```

The system will automatically generate all combinations of `tokenIn` × `tokenOut` for the SwapHook and include them in the merkle tree.
