#!/bin/bash

###################################################################################
# Update Locked Bytecode Script - Periphery
###################################################################################
# Description:
#   This script updates the locked-bytecode folder with the latest compiled
#   artifacts for periphery V2 contracts that require deterministic
#   deployment addresses.
#
# Usage:
#   ./script/run/update_locked_bytecode.sh
#
# Requirements:
#   - forge: For contract compilation
#   - jq: For JSON processing (optional, for validation)
#
# Author: Superform Team
###################################################################################

set -euo pipefail  # Exit on error, undefined var, pipe failure

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

log "INFO" "${BLUE}🔧 Updating Locked Bytecode for V2 Periphery Contracts${NC}"

# Ensure we're in the right directory
if [ ! -f "foundry.toml" ]; then
    log "ERROR" "${RED}foundry.toml not found. Please run this script from the v2-periphery root directory.${NC}"
    exit 1
fi

# Build contracts
log "INFO" "${YELLOW}📦 Building contracts...${NC}"
if ! forge build; then
    log "ERROR" "${RED}Failed to build contracts${NC}"
    exit 1
fi

# Create locked-bytecode directory if it doesn't exist
mkdir -p script/locked-bytecode

log "INFO" "${BLUE}📋 Copying periphery contract artifacts...${NC}"

# Define arrays of contracts to copy
# Core periphery contracts (only 6 core contracts)
CORE_PERIPHERY_CONTRACTS=(
    "SuperGovernor"
    "SuperVault"
    "SuperVaultAggregator" 
    "SuperVaultStrategy"
    "SuperVaultEscrow"
    "ECDSAPPSOracle"
)

# Function to copy contract artifact
copy_contract() {
    local contract_name=$1
    local source_path
    local dest_path="script/locked-bytecode/${contract_name}.json"
    
    # Find the contract artifact - correct pattern for Foundry structure
    source_path="out/${contract_name}.sol/${contract_name}.json"
    
    if [ ! -f "$source_path" ]; then
        log "ERROR" "${RED}❌ Artifact not found for contract: ${contract_name} at ${source_path}${NC}"
        return 1
    fi
    
    # Copy the artifact
    cp "$source_path" "$dest_path"
    log "INFO" "${GREEN}✅ Copied ${contract_name}${NC}"
    
    return 0
}

# Copy all core periphery contracts
log "INFO" "${BLUE}📦 Copying core periphery contracts...${NC}"
failed_core=0
for contract in "${CORE_PERIPHERY_CONTRACTS[@]}"; do
    if ! copy_contract "$contract"; then
        failed_core=$((failed_core + 1))
    fi
done

# Summary
total_contracts=${#CORE_PERIPHERY_CONTRACTS[@]}
total_failed=$failed_core
total_success=$((total_contracts - total_failed))

log "INFO" "${BLUE}📊 Summary:${NC}"
log "INFO" "${GREEN}  ✅ Successfully copied: ${total_success}/${total_contracts} contracts${NC}"

if [ $failed_core -gt 0 ]; then
    log "WARN" "${YELLOW}  ⚠️  Failed core periphery contracts: ${failed_core}/${#CORE_PERIPHERY_CONTRACTS[@]}${NC}"
fi

if [ $total_failed -eq 0 ]; then
    log "INFO" "${GREEN}🎉 All periphery contracts successfully updated in locked-bytecode!${NC}"
    exit 0
else
    log "ERROR" "${RED}❌ ${total_failed} contracts failed to copy. Please check the error messages above.${NC}"
    exit 1
fi