# V2 Periphery Deployment Guide

Complete guide for deploying V2 Periphery contracts to staging and production environments.

## Prerequisites

- ✅ Foundry installed and configured
- ✅ AWS CLI configured with access to `superform-deployment-state` bucket
- ✅ 1Password CLI (`op`) configured for credential management
- ✅ Foundry account set up (e.g., `v2-supervaults`)
- ✅ V2 Core contracts already deployed on target networks
- ✅ `jq` installed for JSON processing

## Overview

The deployment process consists of 3 main steps:

1. **Deploy Periphery Contracts** - Deploy SuperGovernor, SuperVault system, and oracles
2. **Merge to Core State** - Merge periphery addresses with core deployment state in S3
3. **Configure Hooks** - Register v2-core hooks with SuperGovernor

---

## Step 1: Deploy Periphery Contracts

### 1.1 Update Locked Bytecode (if needed)

If you've made changes to the contracts, rebuild and update the locked bytecode:

```bash
# Build contracts
forge build

# Regenerate bytecode (for VNET/dev environments)
./script/run/regenerate_bytecode.sh
```

### 1.2 Simulate Deployment

**Always simulate first to verify everything works:**

```bash
# Staging simulation
./script/run/deploy_v2_periphery_staging_prod.sh staging simulate

# Production simulation
./script/run/deploy_v2_periphery_staging_prod.sh prod simulate
```

The simulation will:
- ✅ Check deployer address matches expected address
- ✅ Verify all contract bytecode is available
- ✅ Show which contracts will be deployed vs already deployed
- ✅ Display predicted addresses
- ❌ NOT broadcast any transactions

### 1.3 Deploy to Network

**Once simulation looks good, deploy:**

```bash
# Deploy to staging
./script/run/deploy_v2_periphery_staging_prod.sh staging deploy v2-supervaults

# Deploy to production
./script/run/deploy_v2_periphery_staging_prod.sh prod deploy v2-supervaults
```

The script will:
- ✅ Deploy missing contracts using CREATE2 (deterministic addresses)
- ✅ Skip contracts that are already deployed
- ✅ Verify contracts on Etherscan
- ✅ Save deployment addresses to `script/output/{environment}/{chainId}/{Network}-latest.json`

**Expected Output Location:**
```
script/output/
├── staging/
│   └── 8453/
│       └── Base-latest.json    # SuperGovernor, SuperVaultAggregator, etc.
└── prod/
    └── 8453/
        └── Base-latest.json
```

---

## Step 2: Merge Periphery to Core State

After deployment, merge the periphery contract addresses with the core deployment state in S3.

> **⚠️ Note for Production:** Production S3 state is merged **manually** (not via the merge script). The `merge_periphery_to_core_s3_staging.sh` script is only for staging environment. For production, manually update the S3 state or wait for the production merge script to be created.

### 2.1 Run Merge Script

```bash
# For staging only
./script/run/merge_periphery_to_core_s3_staging.sh
```

The script will:
- ✅ Read periphery contracts from local `script/output/staging/{chainId}/{Network}-latest.json`
- ✅ Download core state from `s3://superform-deployment-state/staging/latest.json`
- ✅ Filter to allowed periphery contracts (SuperGovernor, SuperVaultAggregator, ECDSAPPSOracle)
- ✅ Merge or replace addresses in core state
- ✅ Show preview of changes
- ❓ Ask for confirmation
- ✅ Upload merged state back to S3

**Allowed Periphery Contracts:**
- `SuperGovernor` - Governance and registry
- `SuperVaultAggregator` - Vault aggregator for multi-vault operations
- `ECDSAPPSOracle` - ECDSA-based price oracle

**Example Output:**
```
╔══════════════════════════════════════════════════════════════╗
║                    📋 MERGE SUMMARY 📋                      ║
╚══════════════════════════════════════════════════════════════╝
Environment: staging
Bucket: superform-deployment-state
Total Networks: 1
Successful: 1
Failed: 0

  ✅ Base: SuperGovernor: added, SuperVaultAggregator: added, ECDSAPPSOracle: added

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Periphery contracts that will be merged into core S3:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Base:
{
  "SuperGovernor": "0x02D27b6B1ffd449870703C47Cb58a683CE299FD2",
  "SuperVaultAggregator": "0xdf8B509B6B027c17497F629185D6fDA8912B765e",
  "ECDSAPPSOracle": "0x0B9c815df043F7716452A027114098D28003dE3e"
}

Do you want to upload the merged state to S3? (y/n):
```

### 2.2 Verify Merge

Check that the merge was successful:

```bash
# Download and view merged state
aws s3 cp s3://superform-deployment-state/staging/latest.json - | jq '.networks.Base.contracts | {SuperGovernor, SuperVaultAggregator, ECDSAPPSOracle}'
```

---

## Step 3: Configure Hooks on SuperGovernor

After merging, configure SuperGovernor with all v2-core hooks.

### 3.1 Simulate Configuration

**Always simulate first:**

```bash
# Staging simulation
./script/run/add_hooks_to_governor_staging_prod.sh staging simulate

# Production simulation
./script/run/add_hooks_to_governor_staging_prod.sh prod simulate
```

The simulation will:
- ✅ Read merged state from S3
- ✅ Verify SuperGovernor exists for each network
- ✅ Show which hooks will be registered
- ❌ NOT broadcast any transactions

### 3.2 Configure Hooks

**Once simulation looks good, configure:**

```bash
# Configure staging
./script/run/add_hooks_to_governor_staging_prod.sh staging configure v2-supervaults

# Configure production
./script/run/add_hooks_to_governor_staging_prod.sh prod configure v2-supervaults
```

The script will:
- ✅ Register all v2-core hooks with SuperGovernor
- ✅ Use proper salt namespace for the environment
- ✅ Broadcast transactions using the specified account
- ✅ Show detailed results per network

**Expected Output:**
```
╔══════════════════════════════════════════════════════════════╗
║              📋 CONFIGURATION SUMMARY 📋                    ║
╚══════════════════════════════════════════════════════════════╝
Environment: staging
Mode: configure
Total Networks: 1
Successful: 1
Skipped: 0
Failed: 0

╔══════════════════════════════════════════════════════════════╗
║       🎉 Hook Configuration Completed Successfully! 🎉      ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Complete Deployment Workflow

### For Staging:

```bash
# 1. Deploy periphery contracts
./script/run/deploy_v2_periphery_staging_prod.sh staging simulate         # Simulate first
./script/run/deploy_v2_periphery_staging_prod.sh staging deploy v2-supervaults

# 2. Merge periphery to core state in S3
./script/run/merge_periphery_to_core_s3_staging.sh

# 3. Configure hooks on SuperGovernor
./script/run/add_hooks_to_governor_staging_prod.sh staging simulate      # Simulate first
./script/run/add_hooks_to_governor_staging_prod.sh staging configure v2-supervaults
```

### For Production:

```bash
# 1. Deploy periphery contracts
./script/run/deploy_v2_periphery_staging_prod.sh prod simulate            # Simulate first
./script/run/deploy_v2_periphery_staging_prod.sh prod deploy v2-supervaults

# 2. Merge periphery to core state in S3
# ⚠️ MANUAL PROCESS: Production S3 state must be merged manually
# Option A: Manually update s3://superform-deployment-state/prod/latest.json
# Option B: Wait for merge_periphery_to_core_s3_prod.sh script to be created

# 3. Configure hooks on SuperGovernor
./script/run/add_hooks_to_governor_staging_prod.sh prod simulate         # Simulate first
./script/run/add_hooks_to_governor_staging_prod.sh prod configure v2-supervaults
```

---

## Network Configuration

Networks are configured in environment-specific files:
- **Staging**: `script/run/networks-staging.sh` (5 networks: Ethereum, Base, BNB, Arbitrum, Avalanche)
- **Production**: `script/run/networks-production.sh` (11 networks: all staging + Optimism, Polygon, Unichain, Sonic, Gnosis, Worldchain)

```bash
# Define networks (example from staging)
NETWORKS=(
    "1:Ethereum:ETH_MAINNET"
    "8453:Base:BASE_MAINNET"
    "56:BNB:BSC_MAINNET"
    "42161:Arbitrum:ARBITRUM_MAINNET"
    "43114:Avalanche:AVALANCHE_MAINNET"
)
```

To add more networks:
1. Add network definition to `NETWORKS` array in the appropriate file
2. Update `get_network_name()` function
3. Update `get_rpc_var()` and `get_rpc_url()` functions
4. Update `load_rpc_urls()` to load the RPC from 1Password

---

## Environment Variables

### Forge Environments:
- `FORGE_ENV=2` - Staging (uses `STAGING1.0.0` salt namespace)
- `FORGE_ENV=0` - Production (uses `PROD1.0.0` salt namespace)

### Required Credentials (from 1Password):
- `BASE_RPC_URL` - Base network RPC endpoint
- `ETHERSCANV2_API_KEY` - Etherscan API key for verification

### Accounts:
- **Deployer/Owner**: `0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8`
- **Foundry Account**: `v2-supervaults` (must be set up in Foundry keystore)


---

## Deployment Checklist

### Pre-Deployment:
- [ ] V2 Core contracts deployed on target networks
- [ ] AWS CLI configured with S3 access
- [ ] 1Password CLI configured
- [ ] Foundry account set up and tested
- [ ] RPC endpoints accessible
- [ ] Contracts built (`forge build`)
- [ ] Locked bytecode updated (if contracts changed)

### Deployment:
- [ ] Step 1: Simulate periphery deployment
- [ ] Step 1: Deploy periphery contracts
- [ ] Step 1: Verify contracts on Etherscan
- [ ] Step 2: Merge periphery to core S3 state
- [ ] Step 2: Verify merge in S3
- [ ] Step 3: Simulate hook configuration
- [ ] Step 3: Configure hooks on SuperGovernor
- [ ] Step 3: Verify hooks are registered

### Post-Deployment:
- [ ] Test SuperGovernor functionality
- [ ] Verify all hooks are accessible
- [ ] Test SuperVault operations
- [ ] Update documentation with deployed addresses
- [ ] Notify team of deployment completion

---

## Important Notes

### Salt Namespaces:
- **Staging**: `STAGING1.0.0` - Ensures different addresses from production
- **Production**: `PROD1.0.0` - Production-specific deterministic addresses

### CREATE2 Deployment:
All contracts use CREATE2 for deterministic addresses. Same bytecode + same salt = same address across all networks.

### Contract Upgrades:
Since contracts use deterministic deployment, to "upgrade":
1. Change contract code
2. Update locked bytecode
3. Deploy with new salt namespace (changes all addresses)

**OR** design contracts to be upgradeable (proxy pattern).

### Security:
- ✅ Always simulate before deploying
- ✅ Verify deployer address matches expected
- ✅ Verify contracts on Etherscan after deployment
- ✅ Test in staging before production
- ✅ Keep private keys secure (use Foundry keystore, never commit)

---

## Quick Reference

### File Locations:
```
script/
├── run/
│   ├── deploy_v2_periphery_staging_prod.sh          # Step 1: Deploy contracts
│   ├── merge_periphery_to_core_s3_staging.sh        # Step 2: Merge to S3
│   ├── add_hooks_to_governor_staging_prod.sh        # Step 3: Configure hooks
│   ├── regenerate_bytecode.sh                       # Regenerate bytecode for VNET
│   ├── networks-staging.sh                          # Staging network configuration
│   └── networks-production.sh                       # Production network configuration
├── output/
│   ├── staging/8453/Base-latest.json               # Local deployment output
│   └── prod/8453/Base-latest.json
├── locked-bytecode/                                # Production bytecode (audited)
│   ├── SuperGovernor.json
│   ├── SuperVault.json
│   └── ...
├── locked-bytecode-dev/                            # Dev/staging bytecode
│   └── ...
└── generated-bytecode/                             # Fresh bytecode from forge build
    └── ...
```

### S3 Structure:
```
s3://superform-deployment-state/
├── staging/
│   └── latest.json                                 # Merged core + periphery state
└── prod/
    └── latest.json
```

### Key Contracts:
- **SuperGovernor** - Central governance and registry
- **SuperVault** - ERC7540 vault implementation
- **SuperVaultStrategy** - Strategy execution logic
- **SuperVaultEscrow** - Escrow for delayed operations
- **SuperVaultAggregator** - Multi-vault aggregation
- **ECDSAPPSOracle** - ECDSA price signature oracle

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review script output logs (timestamps and detailed error messages)
3. Verify AWS S3 access and file contents
4. Check Foundry account configuration
5. Reach out to the team on Slack/Discord

---

**Last Updated:** 2025-11-18
**Version:** 1.0.0
