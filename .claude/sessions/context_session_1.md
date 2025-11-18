# Session 1: V2-Periphery Staging Deployment Scripts

## Overview
Creating deployment scripts for v2-periphery staging environment based on v2-core patterns.

## Objective
Set up deployment infrastructure for v2-periphery contracts to staging environment (BASE 8453).

## Key Decisions
- **Bytecode Directory**: Reuse `script/locked-bytecode/` for both staging and prod
- **Configuration**: Keep hook configuration separate (ConfigureV2Periphery.s.sol)
- **Deployment Strategy**: Idempotent - skip already deployed contracts
- **Script Naming**: Rename `update_locked_bytecode.sh` to `regenerate_bytecode_periphery.sh`

## Components to Deploy (6 contracts)
1. SuperGovernor - Central governance and registry
2. SuperVaultAggregator - Vault factory/aggregator
3. SuperVault - Vault implementation
4. SuperVaultStrategy - Strategy implementation
5. SuperVaultEscrow - Escrow implementation
6. ECDSAPPSOracle - ECDSA-based PPS oracle

## Staging Network
- **Chain**: BASE
- **Chain ID**: 8453
- **RPC**: Loaded from 1Password (BASE_MAINNET)

## Implementation Plan

### Files Created
1. `script/run/networks-staging.sh` - Network configuration for staging
2. `script/run/deploy_v2_periphery_staging_prod.sh` - Main deployment script
3. `script/output/staging/8453/` - Output directory for deployment artifacts
4. `script/output/prod/8453/` - Output directory for future prod deployments

### Files Modified
1. Rename `script/run/update_locked_bytecode.sh` → `script/run/regenerate_bytecode_periphery.sh`

## Script Features
- Bytecode availability analysis
- Network loop support (expandable to multiple chains)
- Pre-deployment address checking
- Smart deployment (only deploy missing contracts)
- 1Password integration for credentials
- Comprehensive status display

## Status
✅ **COMPLETED** - All deployment scripts created and ready for testing

## Implementation Details

### 1. networks-staging.sh
Created network configuration script for staging environment:
- **Location**: `script/run/networks-staging.sh`
- **Network Array**: Single network `"8453:Base:BASE_MAINNET"`
- **Functions Implemented**:
  - `get_network_name()` - Maps chain ID to network name
  - `get_rpc_var()` - Returns RPC variable name for chain ID
  - `get_rpc_url()` - Returns actual RPC URL from environment
  - `is_network_supported()` - Validates if chain ID is supported
  - `get_supported_networks()` - Lists all supported chain IDs
  - `load_rpc_urls()` - Loads BASE_MAINNET RPC from 1Password
  - `load_etherscan_api_key()` - Loads ETHERSCANV2_API_KEY from 1Password
  - `print_network_info()` - Displays network configuration
- **1Password Integration**: Uses vault ID `5ylebqljbh3x6zomdxi3qd7tsa`
- **Expandable**: Easy to add more networks by updating the NETWORKS array

### 2. deploy_v2_periphery_staging_prod.sh
Created main deployment script with full functionality:
- **Location**: `script/run/deploy_v2_periphery_staging_prod.sh`
- **Arguments**: `<environment> <mode> <account>`
  - environment: `staging` or `prod`
  - mode: `simulate` or `deploy`
  - account: foundry wallet name (e.g., `v2`)
- **Key Features**:
  - ✅ Bytecode availability analysis (checks all 6 contracts)
  - ✅ Network loop support (iterates through NETWORKS array)
  - ✅ Pre-deployment address checking via `runCheck()` function
  - ✅ Smart deployment (idempotent - skips already deployed contracts)
  - ✅ 1Password credential management
  - ✅ Comprehensive status display with color coding
  - ✅ Deployment confirmation for deploy mode
  - ✅ Error handling and network connectivity validation
- **Deployment Flow**:
  1. Validate arguments and load network configuration
  2. Check locked bytecode availability (6 contracts)
  3. Check deployed contract addresses on each network
  4. Analyze deployment status across all networks
  5. Exit if all deployed, or continue if deployment needed
  6. Confirmation prompt for deploy mode
  7. Deploy missing contracts to each network
  8. Display deployment summary
- **Output**: Saves deployment artifacts to `script/output/{environment}/{chainId}/`

### 3. regenerate_bytecode_periphery.sh
Renamed existing bytecode regeneration script:
- **Old Name**: `script/run/update_locked_bytecode.sh`
- **New Name**: `script/run/regenerate_bytecode_periphery.sh`
- **Reason**: Consistency with v2-core naming conventions
- **Functionality**: Unchanged - builds contracts and copies artifacts to `script/locked-bytecode/`
- **Contracts**: Manages 6 core periphery contract artifacts

### 4. Output Directory Structure
Created directory structure for deployment artifacts:
```
script/output/
├── staging/
│   └── 8453/           # BASE staging deployments
└── prod/
    └── 8453/           # BASE production deployments
```

## How to Use

### Testing (Simulate Mode)
```bash
./script/run/deploy_v2_periphery_staging_prod.sh staging simulate v2
```
This will:
- Check bytecode availability
- Check which contracts are deployed on BASE
- Show deployment status
- **NOT** broadcast transactions
- Exit with status

### Actual Deployment
```bash
./script/run/deploy_v2_periphery_staging_prod.sh staging deploy v2
```
This will:
- Perform all checks
- Ask for confirmation ("DEPLOY")
- Deploy only missing contracts
- Verify contracts on Etherscan
- Save deployment artifacts

## Key Design Decisions

### Same Bytecode Folder for Staging and Prod
- Uses `script/locked-bytecode/` for both environments
- Simpler than v2-core's separate folders approach
- Appropriate since periphery has only 6 contracts
- Reduces confusion and maintenance overhead

### Network Loop Architecture
- Supports single network (BASE 8453) initially
- **Designed for expansion**: Easy to add more networks
- Script iterates through NETWORKS array from `networks-staging.sh`
- Each network checked and deployed independently

### Idempotent Deployment
- Script can be run multiple times safely
- Already deployed contracts are skipped
- Only missing contracts are deployed
- Uses `runCheck()` function to query deployment status

### Integration with DeployV2Periphery.s.sol
- Uses existing Solidity script: `DeployV2Periphery.s.sol`
- Calls `runCheck(uint256,uint64)` for address checking
- Calls `run(uint256,uint64)` for deployment
- No modifications to Solidity scripts required

## Future Expansion

### Adding More Networks to Staging
Edit `script/run/networks-staging.sh`:
1. Add network to NETWORKS array: `"<CHAIN_ID>:<Name>:<RPC_VAR>"`
2. Add case to `get_network_name()`
3. Add case to `get_rpc_var()`
4. Add case to `get_rpc_url()`
5. Add RPC loading to `load_rpc_urls()`

Example for adding Arbitrum:
```bash
NETWORKS=(
    "8453:Base:BASE_MAINNET"
    "42161:Arbitrum:ARBITRUM_MAINNET"
)
```

### Creating Production Configuration
Create `script/run/networks-production.sh` following same pattern as staging.
The deployment script will automatically use it when called with `prod` environment.

## Testing Checklist

User will test:
- [ ] Run simulate mode on BASE staging
- [ ] Verify bytecode availability check works
- [ ] Verify deployment status detection works
- [ ] Run actual deployment (if contracts not deployed)
- [ ] Verify idempotency (re-run should skip all)
- [ ] Check deployment artifacts saved correctly

## Notes
- Script follows v2-core patterns but simplified for periphery (only 6 contracts vs 50+)
- No hooks to deploy (hooks are in v2-core)
- Configuration kept separate in `ConfigureV2Periphery.s.sol`
- All scripts are executable and ready to use

## Bug Fix: Contract Name Mismatch

### Issue Discovered
When testing the deployment script, encountered error:
```
vm.getCode: failed to read from "script/locked-bytecode/SuperVaultImplementation.json": No such file or directory
```

### Root Cause
The Solidity script `DeployV2Periphery.s.sol` expects implementation contracts with "Implementation" suffix:
- `SuperVaultImplementation`
- `SuperVaultStrategyImplementation`
- `SuperVaultEscrowImplementation`

But `regenerate_bytecode_periphery.sh` was creating files without the suffix:
- `SuperVault.json`
- `SuperVaultStrategy.json`
- `SuperVaultEscrow.json`

The vnet deployment script (`deploy_v2_vnet_s3.sh`) worked because it runs `update_locked_bytecode.sh` (now `regenerate_bytecode_periphery.sh`) BEFORE each deployment at line 779, regenerating bytecode from `out/` fresh each time.

### Solution Applied
Updated `regenerate_bytecode_periphery.sh` to:
1. Support `source:destination` naming format in CORE_PERIPHERY_CONTRACTS array
2. Modified `copy_contract()` function to parse the format and use different names for source and destination
3. Changed array to:
   ```bash
   CORE_PERIPHERY_CONTRACTS=(
       "SuperGovernor"
       "SuperVault:SuperVaultImplementation"
       "SuperVaultAggregator"
       "SuperVaultStrategy:SuperVaultStrategyImplementation"
       "SuperVaultEscrow:SuperVaultEscrowImplementation"
       "ECDSAPPSOracle"
   )
   ```

This copies `out/SuperVault.sol/SuperVault.json` → `script/locked-bytecode/SuperVaultImplementation.json`

### Next Steps
Run `./script/run/regenerate_bytecode_periphery.sh` to regenerate locked bytecode with correct names before testing deployment again.
