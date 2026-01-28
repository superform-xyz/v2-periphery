#!/usr/bin/env bash

###################################################################################
# Regenerate Bytecode Script - Periphery
###################################################################################
# Description:
#   This script regenerates bytecode artifacts for periphery V2 contracts by
#   copying from compiled outputs to generated-bytecode folder for VNET deployments.
#
# Usage:
#   ./script/run/regenerate_bytecode.sh [CONTRACT_NAME]
#
# Arguments:
#   CONTRACT_NAME (optional): Name of specific contract to regenerate.
#                            If provided, must exist in out/ folder.
#                            If omitted, regenerates all contracts.
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

# Parse command line arguments
CONTRACT_NAME=""
if [ $# -gt 0 ]; then
    CONTRACT_NAME="$1"
    log "INFO" "${BLUE}🔧 Regenerating Bytecode for Contract: ${CONTRACT_NAME}${NC}"
else
    log "INFO" "${BLUE}🔧 Regenerating Bytecode for All V2 Periphery Contracts${NC}"
fi

# Ensure we're in the right directory
if [ ! -f "foundry.toml" ]; then
    log "ERROR" "${RED}foundry.toml not found. Please run this script from the v2-periphery root directory.${NC}"
    exit 1
fi

# If specific contract is requested, validate it exists in out folder
if [ -n "$CONTRACT_NAME" ]; then
    CONTRACT_PATH="out/${CONTRACT_NAME}.sol/${CONTRACT_NAME}.json"
    if [ ! -f "$CONTRACT_PATH" ]; then
        log "ERROR" "${RED}Contract '${CONTRACT_NAME}' not found at ${CONTRACT_PATH}${NC}"
        log "ERROR" "${RED}Please ensure the contract exists and has been compiled.${NC}"
        exit 1
    fi
    log "INFO" "${GREEN}✅ Contract '${CONTRACT_NAME}' found in out folder${NC}"
fi

# Build contracts
log "INFO" "${YELLOW}📦 Building contracts...${NC}"
if ! forge build; then
    log "ERROR" "${RED}Failed to build contracts${NC}"
    exit 1
fi

# Create generated-bytecode directory if it doesn't exist
mkdir -p script/generated-bytecode

log "INFO" "${BLUE}📋 Copying periphery contract artifacts...${NC}"

# Define arrays of contracts to copy
# Core periphery contracts
CORE_PERIPHERY_CONTRACTS=(
    "SuperGovernor"
    "SuperVault"
    "SuperVaultAggregator"
    "SuperVaultStrategy"
    "SuperVaultEscrow"
    "SuperVaultBatchOperator"
    "ECDSAPPSOracle"
    "FixedPriceOracle"
    "SuperOracle"
    "SuperOracleL2"
    "SuperBank"
    "UpOFT"
    "UpOFTAdapter"
    "SuperformGasOracle"
    "PendlePTAmortizedOracle"
)

# Function to copy contract artifact
copy_contract() {
    local contract_name=$1
    local source_path
    local dest_path="script/generated-bytecode/${contract_name}.json"

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

# Process contracts based on argument
if [ -n "$CONTRACT_NAME" ]; then
    # Single contract mode
    log "INFO" "${BLUE}📦 Copying specific contract: ${CONTRACT_NAME}...${NC}"
    if copy_contract "$CONTRACT_NAME"; then
        log "INFO" "${GREEN}🎉 Contract ${CONTRACT_NAME} successfully updated in generated-bytecode!${NC}"
        exit 0
    else
        log "ERROR" "${RED}❌ Failed to copy contract ${CONTRACT_NAME}${NC}"
        exit 1
    fi
else
    # All contracts mode (original behavior)
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
        log "INFO" "${GREEN}🎉 All periphery contracts successfully updated in generated-bytecode!${NC}"
        exit 0
    else
        log "ERROR" "${RED}❌ ${total_failed} contracts failed to copy. Please check the error messages above.${NC}"
        exit 1
    fi
fi
