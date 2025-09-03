#!/bin/bash

###################################################################################
# Merge Periphery to Core S3 Script
###################################################################################
# Description:
#   This script merges V2 Periphery contract addresses into the core vnet-state
#   S3 bucket. It reads periphery deployments from the periphery-deployments bucket
#   and merges them into the specified folder in vnet-state bucket.
#
# Usage:
#   ./merge_periphery_to_core_s3.sh <environment_folder>
#   
#   Parameters:
#     environment_folder: Target folder in vnet-state bucket (e.g., "demo", "main", "dev")
#
# Functionality:
#   - Reads periphery addresses from periphery-deployments bucket
#   - Downloads existing core state from vnet-state bucket
#   - Checks if periphery addresses already exist in core state
#   - Substitutes existing addresses or appends new ones at the bottom
#   - Uploads merged state back to vnet-state bucket
#
# Requirements:
#   - jq: For JSON processing
#   - aws: For S3 operations
#
# Author: Superform Team
# Version: 1.0.0
###################################################################################

set -euo pipefail  # Exit on error, undefined var, pipe failure

###################################################################################
# Helper Functions
###################################################################################

# Colors for better visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored header
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}║${WHITE}                🔄 Merge Periphery to Core S3 Script 🔄                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}              (Periphery → vnet-state bucket merge)                              ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print section separator
print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Logging function for consistent output
log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

# Network name mapping
get_network_slug() {
    local network_id=$1
    case "$network_id" in
        1)
            echo "Ethereum"
            ;;
        8453)
            echo "Base"
            ;;
        10)
            echo "Optimism"
            ;;
        *)
            log "ERROR" "Unknown network ID: $network_id"
            return 1
            ;;
    esac
}

###################################################################################
# Configuration
###################################################################################

# Script Arguments
ENVIRONMENT_FOLDER=$1

# S3 Bucket Configuration
PERIPHERY_BUCKET="periphery-deployments"
CORE_BUCKET="vnet-state"

# Allowed periphery contracts to merge
ALLOWED_PERIPHERY_CONTRACTS=("SuperGovernor" "SuperVaultAggregator" "ECDSAPPSOracle")

# Validation
if [ -z "$ENVIRONMENT_FOLDER" ]; then
    echo -e "${RED}❌ Error: Environment folder is required${NC}"
    echo -e "${YELLOW}Usage: $0 <environment_folder>${NC}"
    echo -e "${CYAN}  environment_folder: Target folder in vnet-state bucket (e.g., demo, main, dev)${NC}"
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 demo${NC}"
    echo -e "${CYAN}  $0 main${NC}"
    echo -e "${CYAN}  $0 dev${NC}"
    exit 1
fi

print_header
log "INFO" "Starting merge process for environment: $ENVIRONMENT_FOLDER"

###################################################################################
# S3 Operations
###################################################################################

# Function to read latest file from periphery bucket
read_periphery_from_s3() {
    local environment=$1
    local latest_file_path="/tmp/periphery_latest.json"

    log "INFO" "Reading periphery deployments from S3..."
    if aws s3 cp "s3://$PERIPHERY_BUCKET/$environment/latest.json" "$latest_file_path" --quiet 2>/dev/null; then
        log "INFO" "Successfully downloaded periphery latest.json from S3"
        
        # Read the file and validate JSON
        local content=$(cat "$latest_file_path")
        
        # Check if content is empty or just whitespace
        if [ -z "$(echo "$content" | tr -d '[:space:]')" ]; then
            log "ERROR" "Periphery S3 file is empty"
            return 1
        elif ! echo "$content" | jq '.' >/dev/null 2>&1; then
            log "ERROR" "Invalid JSON in periphery latest file"
            return 1
        else
            log "INFO" "Successfully validated periphery latest.json from S3"
        fi
    else
        log "ERROR" "Periphery latest.json not found in S3 for environment: $environment"
        return 1
    fi
   
    echo "$content"
}

# Function to read latest file from core bucket
read_core_from_s3() {
    local environment=$1
    local latest_file_path="/tmp/core_latest.json"

    log "INFO" "Reading core state from vnet-state bucket..."
    if aws s3 cp "s3://$CORE_BUCKET/$environment/latest.json" "$latest_file_path" --quiet 2>/dev/null; then
        log "INFO" "Successfully downloaded core latest.json from S3"
        
        # Read the file and validate JSON
        local content=$(cat "$latest_file_path")
        
        # Check if content is empty or just whitespace
        if [ -z "$(echo "$content" | tr -d '[:space:]')" ]; then
            log "WARN" "Core S3 file is empty, initializing default content"
            content="{\"networks\":{},\"updated_at\":null}"
        elif ! echo "$content" | jq '.' >/dev/null 2>&1; then
            log "ERROR" "Invalid JSON in core latest file, resetting to default"
            content="{\"networks\":{},\"updated_at\":null}"
        else
            log "INFO" "Successfully validated core latest.json from S3"
        fi
    else
        log "WARN" "Core latest.json not found in S3 for environment: $environment, initializing empty file"
        content="{\"networks\":{},\"updated_at\":null}"
    fi
   
    echo "$content"
}

# Function to filter and extract only allowed periphery contracts from the JSON
filter_allowed_periphery_contracts() {
    local contracts_json=$1
    local network_name=$2
    
    log "INFO" "Filtering contracts for $network_name to only include allowed periphery contracts"
    
    # Create filtered JSON with only allowed contracts
    local filtered_json="{}"
    
    for allowed in "${ALLOWED_PERIPHERY_CONTRACTS[@]}"; do
        local contract_address=$(echo "$contracts_json" | jq -r ".$allowed // empty")
        if [ -n "$contract_address" ] && [ "$contract_address" != "null" ] && [ "$contract_address" != "empty" ]; then
            filtered_json=$(echo "$filtered_json" | jq --arg contract "$allowed" --arg addr "$contract_address" '.[$contract] = $addr')
            log "INFO" "Found and extracted $allowed: $contract_address for $network_name"
        else
            log "WARN" "Contract $allowed not found in periphery deployment for $network_name"
        fi
    done
    
    echo "$filtered_json"
}

###################################################################################
# Main Merge Logic
###################################################################################

# Function to process all periphery contract merges in batch
process_periphery_merge() {
    local environment=$1
    
    log "INFO" "Processing periphery contract merge for environment: $environment"
    
    # Read periphery deployments
    local periphery_content
    if ! periphery_content=$(read_periphery_from_s3 "$environment"); then
        log "ERROR" "Failed to read periphery deployments"
        return 1
    fi
    
    # Read core state
    local core_content
    if ! core_content=$(read_core_from_s3 "$environment"); then
        log "ERROR" "Failed to read core state"
        return 1
    fi
    
    local updated_content="$core_content"
    
    # Track updates for summary
    declare -a update_summary=()
    local total_networks=0
    local successful_networks=0
    local failed_networks=0
    
    # Get all networks from periphery deployments
    local networks=$(echo "$periphery_content" | jq -r '.networks | keys[]' 2>/dev/null || echo "")
    
    if [ -z "$networks" ]; then
        log "ERROR" "No networks found in periphery deployments"
        return 1
    fi
    
    # Process each network
    for network_name in $networks; do
        total_networks=$((total_networks + 1))
        
        echo -e "${PURPLE}╭─────────────────────────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${PURPLE}│${WHITE}                  🔄 Processing $network_name Periphery Merge 🔄                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}╰─────────────────────────────────────────────────────────────────────────────────────╯${NC}"
        
        # Get periphery contracts for this network
        local periphery_contracts=$(echo "$periphery_content" | jq -r ".networks[\"$network_name\"].contracts // {}")
        
        if [ "$periphery_contracts" = "{}" ] || [ "$periphery_contracts" = "null" ]; then
            log "WARN" "No contracts found in periphery deployment for $network_name"
            update_summary+=("⚠️ $network_name: No periphery contracts found")
            failed_networks=$((failed_networks + 1))
            continue
        fi
        
        # Filter to only allowed periphery contracts
        local filtered_contracts=$(filter_allowed_periphery_contracts "$periphery_contracts" "$network_name")
        local contract_count=$(echo "$filtered_contracts" | jq 'length')
        
        if [ "$contract_count" -eq 0 ]; then
            log "WARN" "No allowed periphery contracts found for $network_name"
            update_summary+=("⚠️ $network_name: No allowed periphery contracts found")
            failed_networks=$((failed_networks + 1))
            continue
        fi
        
        # Check if network exists in core state
        local network_exists=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"] // empty")
        
        if [ -z "$network_exists" ] || [ "$network_exists" = "null" ]; then
            log "INFO" "Network $network_name does not exist in core state, appending new network"
            
            # Get periphery network metadata (vnet_id, counter if available)
            local vnet_id=$(echo "$periphery_content" | jq -r ".networks[\"$network_name\"].vnet_id // empty")
            local counter=$(echo "$periphery_content" | jq -r ".networks[\"$network_name\"].counter // 1")
            
            # Create new network entry with periphery contracts
            updated_content=$(echo "$updated_content" | jq \
                --arg network "$network_name" \
                --arg vnet "$vnet_id" \
                --arg counter "$counter" \
                --argjson contracts "$filtered_contracts" \
                '.networks[$network] = {
                    "counter": ($counter|tonumber),
                    "vnet_id": $vnet,
                    "contracts": $contracts
                }')
            
            update_summary+=("✅ $network_name: Added new network with periphery contracts")
        else
            log "INFO" "Network $network_name exists in core state, merging periphery contracts"
            
            # Extract existing contracts and merge periphery contracts
            local existing_contracts=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"].contracts // {}")
            
            local updates_made=()
            
            # Update each periphery contract individually
            for contract in "${ALLOWED_PERIPHERY_CONTRACTS[@]}"; do
                local contract_address=$(echo "$filtered_contracts" | jq -r ".$contract // empty")
                if [ -n "$contract_address" ] && [ "$contract_address" != "empty" ]; then
                    # Check if contract already exists
                    local existing_address=$(echo "$existing_contracts" | jq -r ".$contract // empty")
                    if [ -n "$existing_address" ] && [ "$existing_address" != "empty" ] && [ "$existing_address" != "null" ]; then
                        log "INFO" "Substituting existing $contract: $existing_address → $contract_address"
                        updates_made+=("$contract: substituted")
                    else
                        log "INFO" "Appending new $contract: $contract_address"
                        updates_made+=("$contract: appended")
                    fi
                    
                    existing_contracts=$(echo "$existing_contracts" | jq --arg contract "$contract" --arg addr "$contract_address" '.[$contract] = $addr')
                fi
            done
            
            # Update the core content with merged contracts (preserve existing counter and vnet_id)
            updated_content=$(echo "$updated_content" | jq \
                --arg network "$network_name" \
                --argjson contracts "$existing_contracts" \
                '.networks[$network].contracts = $contracts')
            
            if [ ${#updates_made[@]} -gt 0 ]; then
                update_summary+=("✅ $network_name: ${updates_made[*]}")
            else
                update_summary+=("⚠️ $network_name: No periphery contracts to merge")
            fi
        fi
        
        successful_networks=$((successful_networks + 1))
    done
    
    # Update timestamp
    updated_content=$(echo "$updated_content" | jq --arg time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.updated_at = $time')
    
    # Display summary of all changes
    print_separator
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                          📋 MERGE SUMMARY 📋                                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Environment: ${WHITE}$environment${NC}"
    echo -e "${CYAN}Source Bucket: ${WHITE}$PERIPHERY_BUCKET${NC}"
    echo -e "${CYAN}Target Bucket: ${WHITE}$CORE_BUCKET${NC}"
    echo -e "${CYAN}Total Networks: ${WHITE}$total_networks${NC}"
    echo -e "${GREEN}Successful: ${WHITE}$successful_networks${NC}"
    echo -e "${RED}Failed: ${WHITE}$failed_networks${NC}"
    echo ""
    
    for summary_line in "${update_summary[@]}"; do
        echo -e "  $summary_line"
    done
    
    echo ""
    
    if [ $successful_networks -eq 0 ]; then
        echo -e "${RED}❌ No successful merges to upload${NC}"
        return 1
    fi
    
    # Show networks that will be updated in core S3
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Networks that will be updated in core S3:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Show updated networks with periphery contracts
    for network_name in $networks; do
        local network_exists=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"] // empty")
        if [ -n "$network_exists" ] && [ "$network_exists" != "null" ]; then
            echo -e "${CYAN}📍 $network_name:${NC}"
            
            # Show only periphery contracts that were merged
            local periphery_contracts_display="{}"
            for contract in "${ALLOWED_PERIPHERY_CONTRACTS[@]}"; do
                local contract_addr=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"].contracts.$contract // empty")
                if [ -n "$contract_addr" ] && [ "$contract_addr" != "empty" ] && [ "$contract_addr" != "null" ]; then
                    periphery_contracts_display=$(echo "$periphery_contracts_display" | jq --arg contract "$contract" --arg addr "$contract_addr" '.[$contract] = $addr')
                fi
            done
            
            if [ "$(echo "$periphery_contracts_display" | jq 'length')" -gt 0 ]; then
                echo "$periphery_contracts_display" | jq '.'
            else
                echo -e "${YELLOW}   No periphery contracts found${NC}"
            fi
            echo ""
        fi
    done
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Ask for confirmation to upload all changes
    printf "${WHITE}Do you want to upload the merged state to core S3 bucket? (y/n): ${NC}"
    read -r confirmation
    echo ""
    
    if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
        log "INFO" "Merge upload cancelled by user"
        echo -e "${YELLOW}⚠️ Merge upload cancelled${NC}"
        return 1
    fi
    
    # Upload to core S3 bucket
    local latest_file_path="/tmp/core_merged_upload.json"
    echo "$updated_content" | jq '.' > "$latest_file_path"
    
    if aws s3 cp "$latest_file_path" "s3://$CORE_BUCKET/$environment/latest.json" --quiet; then
        log "SUCCESS" "Successfully uploaded merged state to core S3 for $environment"
        echo -e "${GREEN}✅ Successfully uploaded merged state to core S3${NC}"
        return 0
    else
        log "ERROR" "Failed to upload merged state to core S3"
        echo -e "${RED}❌ Failed to upload merged state to core S3${NC}"
        return 1
    fi
}

###################################################################################
# Main Execution
###################################################################################

print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Environment: $ENVIRONMENT_FOLDER${NC}"
echo -e "${CYAN}   • Source Bucket: $PERIPHERY_BUCKET${NC}"
echo -e "${CYAN}   • Target Bucket: $CORE_BUCKET${NC}"
echo -e "${CYAN}   • Allowed Contracts: ${ALLOWED_PERIPHERY_CONTRACTS[*]}${NC}"
print_separator

echo -e "${BLUE}🔍 Starting periphery to core merge process...${NC}"

# Process the merge
if process_periphery_merge "$ENVIRONMENT_FOLDER"; then
    print_separator
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                                      ║${NC}"
    echo -e "${GREEN}║${WHITE}              🎉 Periphery to Core Merge Completed Successfully! 🎉                ${GREEN}║${NC}"
    echo -e "${GREEN}║                                                                                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}🔗 Merged state uploaded to: s3://$CORE_BUCKET/$ENVIRONMENT_FOLDER/latest.json${NC}"
else
    print_separator
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                                                      ║${NC}"
    echo -e "${RED}║${WHITE}                        ❌ Merge Process Failed ❌                                  ${RED}║${NC}"
    echo -e "${RED}║                                                                                      ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi

print_separator
