#!/usr/bin/env bash

###################################################################################
# Merge Periphery to Core S3 Script - Staging & Production
###################################################################################
# Description:
#   This script merges V2 Periphery contract addresses into the core deployment
#   state in the superform-deployment-state S3 bucket.
#
# Usage:
#   ./merge_periphery_to_core_s3_staging.sh <environment>
#
#   Parameters:
#     environment: "staging" or "prod"
#
#   Examples:
#     ./merge_periphery_to_core_s3_staging.sh staging
#     ./merge_periphery_to_core_s3_staging.sh prod
#
# Functionality:
#   - Sources appropriate network configuration based on environment
#   - Reads periphery addresses from LOCAL script/output directory
#   - Downloads existing core state from s3://superform-deployment-state/{env}/latest.json
#   - Merges or replaces periphery contract addresses
#   - Uploads merged state back to s3://superform-deployment-state/{env}/latest.json
#
# Requirements:
#   - jq: For JSON processing
#   - aws: For S3 operations
#   - networks-staging.sh or networks-production.sh: Network configuration file
#
# Author: Superform Team
# Version: 2.0.0
###################################################################################

set -euo pipefail  # Exit on error, undefined var, pipe failure

###################################################################################
# Configuration
###################################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# S3 Bucket Configuration
BUCKET="superform-deployment-state"

# Environment will be set from command line argument
ENVIRONMENT=""

# Network configuration will be sourced after environment is determined

# Allowed periphery contracts to merge
ALLOWED_PERIPHERY_CONTRACTS=("SuperGovernor" "SuperVault" "SuperVaultAggregator" "SuperVaultStrategy" "SuperVaultEscrow" "SuperVaultBatchOperator" "ECDSAPPSOracle" "FixedPriceOracle" "SuperOracle" "SuperOracleL2" "SuperBank")

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
    local env_display="${ENVIRONMENT^^}"
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}║${WHITE}              🔄 Merge Periphery to Core S3 Script - ${env_display} 🔄                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}           (Periphery → superform-deployment-state/${ENVIRONMENT})                      ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Validate environment parameter
validate_environment() {
    local environment=$1
    if [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; then
        log "ERROR" "Invalid environment: $environment"
        log "ERROR" "Must be either 'staging' or 'prod'"
        exit 1
    fi
}

# Source network configuration based on environment
source_network_config() {
    local environment=$1
    local network_config_file

    if [ "$environment" = "staging" ]; then
        network_config_file="$SCRIPT_DIR/networks-staging.sh"
    else
        network_config_file="$SCRIPT_DIR/networks-production.sh"
    fi

    if [ ! -f "$network_config_file" ]; then
        log "ERROR" "Network config not found: $network_config_file"
        exit 1
    fi

    log "INFO" "Loading network configuration from: $network_config_file"
    source "$network_config_file"
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

###################################################################################
# File Operations
###################################################################################

# Function to read periphery deployment from local output directory
read_periphery_from_local() {
    local network_id=$1
    local network_name=$2

    # Only staging path
    local local_file_path="$SCRIPT_DIR/../output/staging/${network_id}/${network_name}-latest.json"

    log "INFO" "Reading periphery deployment for $network_name (chain $network_id) from local output..."

    if [ -f "$local_file_path" ]; then
        log "INFO" "Found periphery file at: $local_file_path"

        # Read the file and validate JSON
        local content=$(cat "$local_file_path")

        # Check if content is empty or just whitespace
        if [ -z "$(echo "$content" | tr -d '[:space:]')" ]; then
            log "ERROR" "Periphery file for $network_name is empty"
            return 1
        elif ! echo "$content" | jq '.' >/dev/null 2>&1; then
            log "ERROR" "Invalid JSON in periphery file for $network_name"
            return 1
        else
            log "INFO" "Successfully validated ${network_name}-latest.json from local output"
            echo "$content"
            return 0
        fi
    fi

    log "ERROR" "Periphery ${network_name}-latest.json not found at: $local_file_path"
    return 1
}

# Function to read core state from staging
read_core_from_s3() {
    local environment=$1
    local latest_file_path="/tmp/core_staging_latest.json"

    log "INFO" "Reading core state from staging bucket..."
    if aws s3 cp "s3://$BUCKET/$environment/latest.json" "$latest_file_path" --quiet 2>/dev/null; then
        log "INFO" "Successfully downloaded core latest.json from S3"

        # Read the file and validate JSON
        local content=$(cat "$latest_file_path")

        # Check if content is empty or just whitespace
        if [ -z "$(echo "$content" | tr -d '[:space:]')" ]; then
            log "WARN" "Core S3 file is empty, initializing default content"
            content='{"networks":{},"updated_at":null}'
        elif ! echo "$content" | jq '.' >/dev/null 2>&1; then
            log "ERROR" "Invalid JSON in core latest file, resetting to default"
            content='{"networks":{},"updated_at":null}'
        else
            log "INFO" "Successfully validated core latest.json from S3"
        fi
    else
        log "WARN" "Core latest.json not found in S3 for environment: $environment, initializing empty file"
        content='{"networks":{},"updated_at":null}'
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

# Function to process periphery contract merge for a specific network
process_periphery_merge() {
    local environment=$1

    log "INFO" "Processing periphery contract merge for staging environment"

    # Read core state once
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

    # Get all supported networks from network configuration
    local supported_network_ids=$(get_supported_networks)

    if [ -z "$supported_network_ids" ]; then
        log "ERROR" "No networks found in network configuration"
        return 1
    fi

    # Process each network
    for network_id in $supported_network_ids; do
        total_networks=$((total_networks + 1))

        # Get network name from ID
        local network_name=$(get_network_name "$network_id")
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to get network name for ID: $network_id"
            failed_networks=$((failed_networks + 1))
            update_summary+=("❌ Network ID $network_id: Unknown network")
            continue
        fi

        echo -e "${PURPLE}╭─────────────────────────────────────────────────────────────────────────────────────╮${NC}"
        echo -e "${PURPLE}│${WHITE}                  🔄 Processing $network_name Periphery Merge 🔄                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}╰─────────────────────────────────────────────────────────────────────────────────────╯${NC}"

        # Read periphery deployment for this network from local output
        local periphery_content
        if ! periphery_content=$(read_periphery_from_local "$network_id" "$network_name"); then
            log "WARN" "Failed to read periphery deployment for $network_name, skipping"
            failed_networks=$((failed_networks + 1))
            update_summary+=("⚠️ $network_name: Failed to read periphery deployment")
            continue
        fi

        # The periphery file is a flat JSON with contracts directly
        local periphery_contracts="$periphery_content"

        if [ "$periphery_contracts" = "{}" ] || [ "$periphery_contracts" = "null" ] || [ -z "$periphery_contracts" ]; then
            log "ERROR" "No contracts found in periphery deployment for $network_name"
            echo -e "${RED}❌ No periphery contracts found${NC}"
            failed_networks=$((failed_networks + 1))
            update_summary+=("❌ $network_name: No periphery contracts found")
            continue
        fi

        # Filter to only allowed periphery contracts
        local filtered_contracts=$(filter_allowed_periphery_contracts "$periphery_contracts" "$network_name")
        local contract_count=$(echo "$filtered_contracts" | jq 'length')

        if [ "$contract_count" -eq 0 ]; then
            log "ERROR" "No allowed periphery contracts found for $network_name"
            echo -e "${RED}❌ No allowed periphery contracts found${NC}"
            failed_networks=$((failed_networks + 1))
            update_summary+=("❌ $network_name: No allowed periphery contracts found")
            continue
        fi

        log "INFO" "Found $contract_count allowed periphery contracts"

        # Check if network exists in core state
        local network_exists=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"] // empty")

        if [ -z "$network_exists" ] || [ "$network_exists" = "null" ]; then
            log "INFO" "Network $network_name does not exist in core state, creating new network entry"

            # Create new network entry with periphery contracts
            updated_content=$(echo "$updated_content" | jq \
                --arg network "$network_name" \
                --arg chain_id "$network_id" \
                --argjson contracts "$filtered_contracts" \
                '.networks[$network] = {
                    "counter": 1,
                    "chain_id": $chain_id,
                    "contracts": $contracts
                }')

            update_summary+=("✅ $network_name: Created new network with ${contract_count} periphery contracts")
        else
            log "INFO" "Network $network_name exists in core state, merging periphery contracts"

            # Extract existing contracts and merge periphery contracts
            local existing_contracts=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"].contracts // {}")

            local updates_made=()

            # Update each periphery contract individually
            for contract in "${ALLOWED_PERIPHERY_CONTRACTS[@]}"; do
                local contract_address=$(echo "$filtered_contracts" | jq -r ".$contract // empty")
                if [ -n "$contract_address" ] && [ "$contract_address" != "empty" ] && [ "$contract_address" != "null" ]; then
                    # Check if contract already exists
                    local existing_address=$(echo "$existing_contracts" | jq -r ".$contract // empty")
                    if [ -n "$existing_address" ] && [ "$existing_address" != "empty" ] && [ "$existing_address" != "null" ]; then
                        if [ "$existing_address" != "$contract_address" ]; then
                            log "INFO" "Replacing existing $contract: $existing_address → $contract_address"
                            updates_made+=("$contract: replaced")
                        else
                            log "INFO" "$contract: address unchanged"
                            updates_made+=("$contract: unchanged")
                        fi
                    else
                        log "INFO" "Adding new $contract: $contract_address"
                        updates_made+=("$contract: added")
                    fi

                    existing_contracts=$(echo "$existing_contracts" | jq --arg contract "$contract" --arg addr "$contract_address" '.[$contract] = $addr')
                fi
            done

            # Update the core content with merged contracts (preserve existing counter and chain_id)
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
    echo -e "${CYAN}Bucket: ${WHITE}$BUCKET${NC}"
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

    # Show diff of what will change compared to current S3 state (only differences)
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Changes to be applied to core S3 state:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local any_changes=false

    for network_id in $supported_network_ids; do
        local network_name=$(get_network_name "$network_id")
        if [ $? -ne 0 ]; then
            continue
        fi

        local new_network=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"] // empty")
        if [ -z "$new_network" ] || [ "$new_network" = "null" ]; then
            continue
        fi

        # Collect changes for this network first
        local network_changes=""

        for contract in "${ALLOWED_PERIPHERY_CONTRACTS[@]}"; do
            local old_addr=$(echo "$core_content" | jq -r ".networks[\"$network_name\"].contracts.$contract // empty")
            local new_addr=$(echo "$updated_content" | jq -r ".networks[\"$network_name\"].contracts.$contract // empty")

            # Normalize empties
            [ "$old_addr" = "null" ] && old_addr=""
            [ "$new_addr" = "null" ] && new_addr=""

            if [ -n "$new_addr" ] && [ -z "$old_addr" ]; then
                # New contract being added
                network_changes+="    ${GREEN}+ $contract: $new_addr${NC}\n"
            elif [ -n "$new_addr" ] && [ "$old_addr" != "$new_addr" ]; then
                # Contract address changed
                network_changes+="    ${RED}- $contract: $old_addr${NC}\n"
                network_changes+="    ${GREEN}+ $contract: $new_addr${NC}\n"
            fi
        done

        # Only print network header if there are changes
        if [ -n "$network_changes" ]; then
            echo -e "${CYAN}  $network_name:${NC}"
            echo -e "$network_changes"
            any_changes=true
        fi
    done

    if [ "$any_changes" = false ]; then
        echo -e "${WHITE}  (no changes to apply)${NC}"
        echo ""
    fi

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Ask for confirmation to upload all changes
    printf "${WHITE}Do you want to upload the merged state to S3? (y/n): ${NC}"
    read -r confirmation
    echo ""

    if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
        log "INFO" "Merge upload cancelled by user"
        echo -e "${YELLOW}⚠️ Merge upload cancelled${NC}"
        return 1
    fi

    # Upload to S3 bucket
    local latest_file_path="/tmp/core_merged_upload_staging.json"
    echo "$updated_content" | jq '.' > "$latest_file_path"

    if aws s3 cp "$latest_file_path" "s3://$BUCKET/$environment/latest.json" --quiet; then
        log "SUCCESS" "Successfully uploaded merged state to S3 for $environment"
        echo -e "${GREEN}✅ Successfully uploaded merged state to S3${NC}"
    else
        log "ERROR" "Failed to upload merged state to S3"
        echo -e "${RED}❌ Failed to upload merged state to S3${NC}"
        return 1
    fi

    # Also save locally so other scripts can use it
    local local_latest_path="$SCRIPT_DIR/../output/$environment/latest.json"
    if echo "$updated_content" | jq '.' > "$local_latest_path"; then
        log "SUCCESS" "Successfully saved merged state locally to: $local_latest_path"
        echo -e "${GREEN}✅ Successfully saved merged state locally${NC}"
    else
        log "WARN" "Failed to save merged state locally"
        echo -e "${YELLOW}⚠️ Failed to save merged state locally (S3 upload succeeded)${NC}"
    fi

    return 0
}

###################################################################################
# Main Execution
###################################################################################

# Check for required argument
if [ $# -lt 1 ]; then
    echo -e "${RED}❌ Error: Missing required argument${NC}"
    echo ""
    echo -e "${YELLOW}Usage: $0 <environment>${NC}"
    echo -e "${YELLOW}  environment: 'staging' or 'prod'${NC}"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "${YELLOW}  $0 staging${NC}"
    echo -e "${YELLOW}  $0 prod${NC}"
    exit 1
fi

# Set environment from argument
ENVIRONMENT=$1

# Validate environment
validate_environment "$ENVIRONMENT"

# Source network configuration based on environment
source_network_config "$ENVIRONMENT"

print_header
print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

# Print network information
print_network_info

echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Environment: $ENVIRONMENT${NC}"
echo -e "${CYAN}   • Bucket: $BUCKET${NC}"
echo -e "${CYAN}   • Allowed Contracts: ${ALLOWED_PERIPHERY_CONTRACTS[*]}${NC}"
print_separator

echo -e "${BLUE}🔍 Starting periphery to core merge process...${NC}"

# Process the merge
if process_periphery_merge "$ENVIRONMENT"; then
    print_separator
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                                      ║${NC}"
    echo -e "${GREEN}║${WHITE}              🎉 Periphery to Core Merge Completed Successfully! 🎉                ${GREEN}║${NC}"
    echo -e "${GREEN}║                                                                                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}🔗 Merged state uploaded to: s3://$BUCKET/$ENVIRONMENT/latest.json${NC}"
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
