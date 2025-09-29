# ConfigureV2Periphery Implementation Plan

## Overview
This plan details the implementation of a new ConfigureV2Periphery Solidity script and corresponding bash script for demo branch configuration. The system will configure SuperGovernor with all v2-core hooks using the demo branch's locked salt pattern.

## File Structure

### Files to Create

1. **`script/ConfigureV2Periphery.s.sol`**
   - Main Solidity configuration script
   - Hook registration logic for SuperGovernor
   - Core dependency handling

2. **`script/run/configure_v2_periphery_demo.sh`**
   - Bash wrapper script following deploy_v2_vnet_s3.sh pattern  
   - VNET management and environment setup
   - Demo branch specific configuration

## Architecture & Components

### 1. ConfigureV2Periphery.s.sol Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ISuperGovernor} from "../src/interfaces/ISuperGovernor.sol";

contract ConfigureV2Periphery is Script {
    // Core addresses structure for retrieving deployed contracts
    struct CoreAddresses {
        // All HookAddresses struct fields (30 hooks)
        address approveErc20Hook;
        address transferErc20Hook;
        // ... (all 30 hook addresses)
    }
    
    // Configuration parameters
    struct ConfigParams {
        uint256 env;
        uint64 chainId;
        string saltNamespace;
        string coreSalt;
    }
    
    // Main entry points
    function run(uint256 env, uint64 chainId, string calldata saltNamespace) external;
    function run(uint256 env, uint64 chainId, string calldata saltNamespace, string calldata coreSalt) external;
    
    // Core functionality
    function configureHooks(ConfigParams memory params) internal;
    function registerAllHooks(address superGovernor, CoreAddresses memory coreAddr) internal;
    function getCoreAddresses(ConfigParams memory params) internal returns (CoreAddresses memory);
}
```

### 2. Key Functions Design

#### `configureHooks()` Function
- Retrieves SuperGovernor address from deployed periphery contracts
- Gets all hook addresses from v2-core deployment
- Registers each non-zero hook address with SuperGovernor
- Handles both regular hooks and fulfill-requests hooks appropriately

#### `getCoreAddresses()` Function  
- Reads deployed addresses from v2-core script output files
- Maps to CoreAddresses struct for type safety
- Validates addresses exist and have code deployed
- Uses salt namespace to locate correct deployment outputs

#### `registerAllHooks()` Function
- Iterates through all 30 hook addresses from HookAddresses struct
- Calls `ISuperGovernor.registerHook(hookAddress, isFulfillRequestsHook)`
- Determines `isFulfillRequestsHook` flag based on hook type:
  - `requestDeposit7540VaultHook` → true
  - `requestRedeem7540VaultHook` → true  
  - `claimCancelDepositRequest7540Hook` → true
  - `claimCancelRedeemRequest7540Hook` → true
  - All others → false
- Provides detailed logging for each registration
- Continues on failures but reports issues

### 3. Bash Script Structure - configure_v2_periphery_demo.sh

Following the pattern of `deploy_v2_vnet_s3.sh`:

```bash
#!/usr/bin/env bash

# Similar header structure with comprehensive documentation
# Environment validation and branch detection  
# VNET management (reuse existing VNETs from core deployment)
# Salt configuration (use demo branch locked salt: 1756754718)
# Configuration execution
# Error handling and cleanup
```

#### Key Components:

**Environment Setup**
- Branch name validation (demo branch only)  
- TENDERLY_ACCESS_KEY from 1Password or .env
- Chain ID constants (1, 8453, 10)
- VNET reuse logic from existing deployments

**Configuration Logic**  
- Uses fixed core salt `1756754718` for demo branch
- Calls ConfigureV2Periphery.s.sol script for each network
- Forge command pattern: `--sig 'run(uint256,uint64,string,string)'`
- Broadcast and verification settings

**Error Handling**
- Validates SuperGovernor deployment exists  
- Checks v2-core hooks are deployed
- Graceful failure handling with detailed logging
- Preserves existing S3 state on errors

## Implementation Details

### 1. Hook Discovery & Registration Approach

**Hook Address Resolution**
- Read from `script/output/{branch}/{chainId}/Ethereum-latest.json` (core deployment outputs)
- Parse JSON to extract all hook contract addresses
- Map to HookAddresses struct fields for type safety

**Hook Type Classification** 
- Regular hooks (most hooks) → `isFulfillRequestsHook = false`
- Async request hooks → `isFulfillRequestsHook = true`
  - Request deposit/redeem hooks for 7540 vaults
  - Claim cancel request hooks
  
**Registration Process**
- Skip zero addresses (hooks not available on chain)
- Call `ISuperGovernor.registerHook(address, bool)` for each hook
- Emit detailed logs for debugging and verification
- Continue processing on individual failures

### 2. Demo Branch Specific Configuration

**Salt Management**
- Core salt: `1756754718` (fixed for consistent addresses)
- Periphery salt: Use timestamp or fixed value as needed
- Validates salt format and range

**Deployment Dependencies**  
- Requires v2-core contracts deployed first
- Requires v2-periphery contracts deployed (SuperGovernor)
- Validates contract addresses and code existence

**Network Support**
- Ethereum (Chain ID 1)
- Base (Chain ID 8453) 
- Optimism (Chain ID 10)
- Uses existing VNET infrastructure

### 3. Integration with Existing Infrastructure

**VNET Reuse**
- Leverages existing VNETs from core/periphery deployments
- No new VNET creation needed
- Reuses RPC endpoints and configurations

**S3 State Management**
- Records configuration status in branch-specific S3 files
- Updates latest.json with configuration metadata
- Preserves existing deployment state

**Forge Integration**
- Uses standard forge script patterns
- Broadcast and verification support  
- Compatible with existing CI/CD pipelines

## Error Handling & Validation

### 1. Pre-execution Validation
- Branch name must be "demo" 
- Core contracts must be deployed and verified
- Periphery contracts must be deployed (SuperGovernor required)
- TENDERLY_ACCESS_KEY must be available

### 2. Runtime Error Handling  
- Individual hook registration failures don't stop entire process
- Detailed logging for troubleshooting
- Graceful degradation for missing/unavailable hooks
- State preservation on critical failures

### 3. Post-execution Verification
- Verify hook registration in SuperGovernor contract
- Compare expected vs actual registered hooks
- Generate configuration summary report
- Update S3 state files with results

## Security Considerations

### 1. Access Control
- Only GOVERNOR_ROLE can register hooks in SuperGovernor
- Ensure proper permissions before script execution  
- Validate hook contract authenticity

### 2. Address Validation
- Verify hook addresses have deployed code
- Cross-reference with expected deployment outputs
- Prevent registration of invalid/malicious addresses

### 3. Salt Management
- Use fixed demo salt for consistency
- Prevent accidental production usage
- Validate salt format and constraints

## Usage Instructions

### Prerequisites
- v2-core contracts deployed on target networks
- v2-periphery contracts deployed (SuperGovernor)
- Demo branch environment configured
- TENDERLY_ACCESS_KEY available
- Appropriate permissions for hook registration

### Execution Steps

1. **Run Configuration Script**
   ```bash
   ./script/run/configure_v2_periphery_demo.sh demo
   ```

2. **Verify Configuration** 
   - Check SuperGovernor registered hooks
   - Review configuration logs
   - Validate S3 state updates

3. **Monitor Results**
   - Track hook registration events
   - Verify expected hooks are available
   - Test hook functionality if needed

## Testing Strategy

### 1. Unit Testing
- Test hook address parsing from JSON
- Validate hook type classification logic
- Test registration batching and error handling

### 2. Integration Testing
- End-to-end configuration on testnet
- VNET environment testing
- S3 state management validation

### 3. Demo Environment Testing
- Full configuration workflow on demo branch
- Hook functionality validation
- Performance and error handling verification

## Important Implementation Notes

### 1. Hook Availability by Network
- Not all hooks are available on all networks
- Some hooks depend on external protocols (1inch, ODOS, Across, etc.)
- Script must handle missing hooks gracefully
- Zero addresses should be skipped during registration

### 2. Fulfill Requests Hook Classification
The following hooks should be registered with `isFulfillRequestsHook = true`:
- `requestDeposit7540VaultHook`
- `requestRedeem7540VaultHook`
- `claimCancelDepositRequest7540Hook` 
- `claimCancelRedeemRequest7540Hook`

All other hooks should use `isFulfillRequestsHook = false`.

### 3. Deployment Order Dependencies
Configuration script can only run after:
1. v2-core contracts deployed (provides hook addresses)
2. v2-periphery contracts deployed (provides SuperGovernor)

The script should validate these dependencies before proceeding.

### 4. Demo Branch Specifics
- Uses locked salt `1756754718` for consistent addresses
- Only runs on demo branch to prevent accidental production usage
- Leverages existing VNET infrastructure from deployments
- Integrates with existing S3 state management system

## Expected Outcomes

After successful execution:
- All available v2-core hooks registered in SuperGovernor on each network
- Detailed configuration logs available for verification
- S3 state files updated with configuration status
- SuperGovernor ready to validate hook-based operations
- Demo environment fully configured for testing hook functionality

## Maintenance Considerations

- Update hook list when new hooks are added to v2-core
- Monitor for hook availability changes by network
- Keep synchronized with v2-core HookAddresses struct changes
- Update salt configurations for new branches as needed
- Maintain compatibility with existing deployment infrastructure