#!/usr/bin/env bash

###################################################################################
# Merge Periphery to Core Local Script - Production
###################################################################################
# Description:
#   This script merges V2 Periphery contract addresses into the core deployment
#   state locally (no S3). It reads from v2-core submodule and outputs to
#   script/output/prod/latest.json.
#
# Usage:
#   ./merge_periphery_to_core_local_prod.sh
#
# Functionality:
#   - Sources production network configuration
#   - Reads v2-core state from lib/v2-core/script/output/prod/latest.json
#   - Reads periphery addresses from script/output/prod/{chainId}/{Network}-latest.json
#   - Merges periphery contract addresses into core state
#   - Prompts to archive previous version to historical/ folder
#   - Saves merged state to script/output/prod/latest.json
#
# Requirements:
#   - jq: For JSON processing
#   - networks-production.sh: Network configuration file
#
# Author: Superform Team
# Version: 1.0.0
###################################################################################

set -euo pipefail  # Exit on error, undefined var, pipe failure

###################################################################################
# Configuration
###################################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Repository root (two levels up from script/run/)
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Core state path (from v2-core submodule)
CORE_STATE_PATH="$REPO_ROOT/lib/v2-core/script/output/prod/latest.json"

# Output paths
OUTPUT_DIR="$REPO_ROOT/script/output/prod"
OUTPUT_FILE="$OUTPUT_DIR/latest.json"
HISTORICAL_DIR="$OUTPUT_DIR/historical"

# Allowed periphery contracts to merge
ALLOWED_PERIPHERY_CONTRACTS=("SuperGovernor" "SuperVault" "SuperVaultAggregator" "SuperVaultStrategy" "SuperVaultEscrow" "SuperVaultBatchOperator" "ECDSAPPSOracle" "FixedPriceOracle" "SuperOracle" "SuperOracleL2" "SuperBank" "PendlePTAmortizedOracle" "PendlePTAmortizedOracleV2")

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
    echo -e "${CYAN}║${WHITE}              🔄 Merge Periphery to Core Local Script - PROD 🔄                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}           (Periphery → script/output/prod/latest.json)                             ${CYAN}║${NC}"
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

# Source network configuration for production
source_network_config() {
    local network_config_file="$SCRIPT_DIR/networks-production.sh"

    if [ ! -f "$network_config_file" ]; then
        log "ERROR" "Network config not found: $network_config_file"
        exit 1
    fi

    log "INFO" "Loading network configuration from: $network_config_file"
    source "$network_config_file"
}

###################################################################################
# File Operations
###################################################################################

# Function to read core state from v2-core submodule
read_core_from_local() {
    log "INFO" "Reading core state from v2-core submodule..."
    log "INFO" "Path: $CORE_STATE_PATH"

    if [ -f "$CORE_STATE_PATH" ]; then
        local content=$(cat "$CORE_STATE_PATH")

        # Check if content is empty or just whitespace
        if [ -z "$(echo "$content" | tr -d '[:space:]')" ]; then
            log "WARN" "Core state file is empty, initializing default content"
            content='{"networks":{},"updated_at":null}'
        elif ! echo "$content" | jq '.' >/dev/null 2>&1; then
            log "ERROR" "Invalid JSON in core latest file, resetting to default"
            content='{"networks":{},"updated_at":null}'
        else
            log "INFO" "Successfully validated core latest.json from v2-core submodule"
        fi
    else
        log "WARN" "Core latest.json not found at: $CORE_STATE_PATH"
        log "WARN" "Initializing empty file"
        content='{"networks":{},"updated_at":null}'
    fi

    echo "$content"
}

# Function to read periphery deployment from local output directory
read_periphery_from_local() {
    local network_id=$1
    local network_name=$2

    local local_file_path="$OUTPUT_DIR/${network_id}/${network_name}-latest.json"

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

# Function to archive existing latest.json
archive_existing_file() {
    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}An existing latest.json was found at: $OUTPUT_FILE${NC}"
        printf "${WHITE}Do you want to archive it before overwriting? (y/n): ${NC}"
        read -r archive_confirmation
        echo ""

        if [ "$archive_confirmation" = "y" ] || [ "$archive_confirmation" = "Y" ]; then
            # Create historical directory if it doesn't exist
            mkdir -p "$HISTORICAL_DIR"

            # Generate timestamp for archive filename (use dashes instead of colons for filesystem compatibility)
            local timestamp=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
            local archive_file="$HISTORICAL_DIR/latest_${timestamp}.json"

            cp "$OUTPUT_FILE" "$archive_file"
            log "INFO" "Archived existing file to: $archive_file"
            echo -e "${GREEN}✅ Archived to: $archive_file${NC}"
        else
            log "INFO" "Skipping archive"
        fi
    fi
}

###################################################################################
# Main Merge Logic
###################################################################################

# Function to process periphery contract merge for production environment
process_periphery_merge() {
    log "INFO" "Processing periphery contract merge for production environment"

    # Read core state from v2-core submodule
    local core_content
    if ! core_content=$(read_core_from_local); then
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
    echo -e "${CYAN}Environment: ${WHITE}prod${NC}"
    echo -e "${CYAN}Output: ${WHITE}$OUTPUT_FILE${NC}"
    echo -e "${CYAN}Total Networks: ${WHITE}$total_networks${NC}"
    echo -e "${GREEN}Successful: ${WHITE}$successful_networks${NC}"
    echo -e "${RED}Failed: ${WHITE}$failed_networks${NC}"
    echo ""

    for summary_line in "${update_summary[@]}"; do
        echo -e "  $summary_line"
    done

    echo ""

    if [ $successful_networks -eq 0 ]; then
        echo -e "${RED}❌ No successful merges to save${NC}"
        return 1
    fi

    # Show periphery contracts that will be merged
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Periphery contracts that will be merged:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Show updated networks with periphery contracts
    for network_id in $supported_network_ids; do
        local network_name=$(get_network_name "$network_id")
        if [ $? -ne 0 ]; then
            continue
        fi

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

    # Ask for confirmation to save
    printf "${WHITE}Do you want to save the merged state to $OUTPUT_FILE? (y/n): ${NC}"
    read -r confirmation
    echo ""

    if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
        log "INFO" "Merge save cancelled by user"
        echo -e "${YELLOW}⚠️ Merge save cancelled${NC}"
        return 1
    fi

    # Archive existing file if user wants
    archive_existing_file

    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"

    # Save to local file
    echo "$updated_content" | jq '.' > "$OUTPUT_FILE"

    if [ -f "$OUTPUT_FILE" ]; then
        log "SUCCESS" "Successfully saved merged state to: $OUTPUT_FILE"
        echo -e "${GREEN}✅ Successfully saved merged state to: $OUTPUT_FILE${NC}"
        return 0
    else
        log "ERROR" "Failed to save merged state"
        echo -e "${RED}❌ Failed to save merged state${NC}"
        return 1
    fi
}

###################################################################################
# Main Execution
###################################################################################

# Source network configuration
source_network_config

print_header
print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

# Print network information
print_network_info

echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Environment: prod${NC}"
echo -e "${CYAN}   • Core State: $CORE_STATE_PATH${NC}"
echo -e "${CYAN}   • Output: $OUTPUT_FILE${NC}"
echo -e "${CYAN}   • Allowed Contracts: ${ALLOWED_PERIPHERY_CONTRACTS[*]}${NC}"
print_separator

echo -e "${BLUE}🔍 Starting periphery to core merge process...${NC}"

# Process the merge
if process_periphery_merge; then
    print_separator
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                                      ║${NC}"
    echo -e "${GREEN}║${WHITE}              🎉 Periphery to Core Merge Completed Successfully! 🎉                ${GREEN}║${NC}"
    echo -e "${GREEN}║                                                                                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}🔗 Merged state saved to: $OUTPUT_FILE${NC}"
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
