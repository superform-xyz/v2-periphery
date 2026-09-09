#!/usr/bin/env bash

###################################################################################
# Superform V2 Periphery Hook Configuration Script - Demo Branch Only
###################################################################################
# Description:
#   This script configures SuperGovernor with all v2-core hooks for demo branch only.
#   It uses the fixed core salt (1756754718) and reuses existing VNETs from deployments.
#   
#   Features:
#   - Configures SuperGovernor with all available v2-core hooks
#   - Reuses existing VNETs from core and periphery deployments
#   - Demo branch only restriction for safety
#   - Supports Ethereum, Base, and Optimism networks
#   - Uses private key from 1Password or ETH_PRIVATE_KEY environment variable
#   - Compatible with Makefile: export ETH_PRIVATE_KEY := $(shell op read op://...)
#
# Directory Structure:
#   script/output/
#   ├── demo/                         # Demo branch specific
#   │   ├── latest.json              # Latest deployment/config info
#   │   ├── 1/                       # Ethereum config outputs
#   │   ├── 8453/                   # Base config outputs
#   │   └── 10/                     # Optimism config outputs
#
# Usage:
#   ./configure_v2_periphery_demo.sh demo
#   
#   Parameters:
#     branch_name: Must be "demo" (required for safety)
#
# Prerequisites:
#   - v2-core contracts must be deployed on target networks
#   - v2-periphery contracts must be deployed (SuperGovernor required)
#   - TENDERLY_ACCESS_KEY available (from 1Password or environment)
#   - ETH_PRIVATE_KEY available (from 1Password or environment variable)
#   - AWS CLI configured for S3 access (to fetch core hook addresses)
#   - Appropriate permissions for hook registration (private key must have GOVERNOR_ROLE)
#
# Author: Superform Team
# Version: 1.0.0
###################################################################################

set -euo pipefail  # Exit on error, undefined var, pipe failure

###################################################################################
# Constants and Configuration
###################################################################################

# Network configuration
declare -A CHAIN_IDS=(
    ["ethereum"]="1"
    ["base"]="8453" 
    ["optimism"]="10"
)

# Demo branch fixed core salt (must match deployment)
readonly DEMO_CORE_SALT="1763631947"

# S3 bucket for fetching core hook addresses
readonly S3_BUCKET_NAME="vnet-state"

# Tenderly API configuration (same as deployment script)
readonly API_BASE_URL="https://api.tenderly.co/api/v1"
readonly TENDERLY_ACCOUNT="superform"
readonly TENDERLY_PROJECT="v2"

###################################################################################
# Helper Functions
###################################################################################

# Logging function for consistent output
log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

# Helper function to redact sensitive information for logging
redact_sensitive() {
    local input="$1"
    local type="$2"
    
    case "$type" in
        "rpc")
            # Redact RPC URL but keep the protocol and host
            echo "$input" | sed -E 's|(https?://[^/]+/).*|\1[REDACTED]|'
            ;;
        "vnet_id")
            # Show only the first 8 characters of VNET ID
            echo "${input:0:8}...[REDACTED]"
            ;;
        *)
            echo "[REDACTED]"
            ;;
    esac
}

# Environment detection
is_local_run() {
    # Check if branch name is 'local' or running locally
    [ "${BRANCH_NAME:-}" = "local" ] || [ "${CI:-}" != "true" ]
    return $?
}

# Network name mapping for RPC endpoints
get_network_slug() {
    local chain_id=$1
    case $chain_id in
        1) echo "mainnet" ;;
        8453) echo "base" ;;
        10) echo "optimism" ;;
        *) echo "unknown" ;;
    esac
}

# Validate branch name (demo only)
validate_branch() {
    local branch=$1
    if [ "$branch" != "demo" ]; then
        log "ERROR" "This script only supports demo branch. Provided: $branch"
        log "ERROR" "This is a safety restriction to prevent accidental production usage"
        exit 1
    fi
}

# Get Tenderly access key
get_tenderly_access_key() {
    if command -v op &> /dev/null; then
        log "INFO" "Getting Tenderly access key from 1Password..."
        local tenderly_key
        if tenderly_key=$(op read "op://5ylebqljbh3x6zomdxi3qd7tsa/TENDERLY_ACCESS_KEY_V2/credential" 2>/dev/null); then
            echo "$tenderly_key"
            return 0
        else
            log "WARNING" "Failed to get Tenderly access key from 1Password"
        fi
    fi
    
    # Fallback to environment variable
    if [ -n "${TENDERLY_ACCESS_KEY:-}" ]; then
        log "INFO" "Using Tenderly access key from environment variable"
        echo "$TENDERLY_ACCESS_KEY"
        return 0
    fi
    
    log "ERROR" "No Tenderly access key found. Set TENDERLY_ACCESS_KEY environment variable or ensure 1Password CLI is configured"
    exit 1
}

# Get private key for forge transactions
get_private_key() {
    if command -v op &> /dev/null; then
        log "INFO" "Getting private key from 1Password..."
        local private_key
        if private_key=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/THROWAWAY_PRIVATE_KEY/credential 2>/dev/null); then
            echo "$private_key"
            return 0
        else
            log "WARNING" "Failed to get private key from 1Password"
        fi
    fi
    
    # Fallback to environment variable
    if [ -n "${ETH_PRIVATE_KEY:-}" ]; then
        log "INFO" "Using private key from environment variable"
        echo "$ETH_PRIVATE_KEY"
        return 0
    fi
    
    log "ERROR" "No private key found. Set ETH_PRIVATE_KEY environment variable or ensure 1Password CLI is configured"
    exit 1
}

# Check if AWS CLI is configured
check_aws_access() {
    if ! command -v aws &> /dev/null; then
        log "ERROR" "AWS CLI not found. Required for fetching core hook addresses from S3"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &>/dev/null; then
        log "ERROR" "AWS CLI not configured properly"
        exit 1
    fi
    
    log "INFO" "AWS CLI configured successfully"
}

# Create output directory structure
setup_output_directory() {
    local branch=$1
    local base_dir="script/output/$branch"
    
    mkdir -p "$base_dir"/{1,8453,10}
    log "INFO" "Created output directory structure for branch: $branch"
}

# Check if core contracts are deployed (via S3)
check_core_deployment() {
    local branch=$1
    local s3_path="s3://$S3_BUCKET_NAME/$branch/latest.json"
    
    log "INFO" "Checking core deployment status from S3..."
    
    if aws s3 ls "$s3_path" &>/dev/null; then
        log "INFO" "Core deployment found in S3 for branch: $branch"
        return 0
    else
        log "ERROR" "Core deployment not found in S3 for branch: $branch"
        log "ERROR" "Core contracts must be deployed first"
        return 1
    fi
}

# Check if periphery contracts are deployed
check_periphery_deployment() {
    local branch=$1
    
    log "INFO" "Checking periphery deployment for branch: $branch"
    
    # Check for deployment files in each supported network
    local found_deployments=0
    for network in "${!CHAIN_IDS[@]}"; do
        local chain_id="${CHAIN_IDS[$network]}"
        local chain_name
        case $chain_id in
            1) chain_name="Ethereum" ;;
            8453) chain_name="Base" ;;
            10) chain_name="Optimism" ;;
        esac
        
        local periphery_file="script/output/$branch/$chain_id/$chain_name-latest.json"
        
        if [ -f "$periphery_file" ]; then
            log "INFO" "Found periphery deployment for $network: $periphery_file"
            
            # Try to extract SuperGovernor address
            if command -v jq &> /dev/null; then
                local governor_addr
                governor_addr=$(jq -r '.SuperGovernor // empty' "$periphery_file" 2>/dev/null)
                if [ -n "$governor_addr" ] && [ "$governor_addr" != "null" ]; then
                    log "INFO" "SuperGovernor address on $network: $governor_addr"
                    found_deployments=$((found_deployments + 1))
                else
                    log "WARNING" "SuperGovernor address not found in $network deployment file"
                fi
            fi
        else
            log "INFO" "No periphery deployment found for $network"
        fi
    done
    
    if [ "$found_deployments" -gt 0 ]; then
        log "INFO" "Periphery deployment validation successful ($found_deployments networks found)"
        return 0
    else
        log "ERROR" "No periphery deployments found for branch: $branch"
        log "ERROR" "Periphery contracts (SuperGovernor) must be deployed first"
        return 1
    fi
}

###################################################################################
# VNET Management (using same logic as deploy_v2_vnet_s3.sh)
###################################################################################

# Generate slug for VNET lookup (same as deployment script)
generate_slug() {
    local network=$1
    local output="${BRANCH_NAME//\//-}-${network}"
    # Convert to lowercase, replace spaces with hyphens, remove special chars
    local output=$(echo "$output" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    echo "$output"
}

# Check for existing VNET by slug (from deploy_v2_vnet_s3.sh - NO CREATION)
check_existing_vnet_by_slug() {
    local slug=$1
    local account=$2
    local project=$3
    local access_key=$4
    
    log "INFO" "Checking if a VNET with slug '$slug' already exists in Tenderly"
    
    # Validate inputs
    if [ -z "$slug" ] || [ -z "$account" ] || [ -z "$project" ] || [ -z "$access_key" ]; then
        log "ERROR" "Missing required parameters for VNET check"
        log "DEBUG" "slug=$slug, account=$account, project=$project, access_key=[${access_key:+SET}]"
        return 1
    fi
    
    # Get list of all VNETs from Tenderly
    log "DEBUG" "Making API call to list VNETs..."
    local vnet_list
    if ! vnet_list=$(curl -s -X GET \
        "${API_BASE_URL}/account/${account}/project/${project}/vnets" \
        -H "X-Access-Key: ${access_key}" 2>&1); then
        log "ERROR" "Failed to make API call to list VNETs"
        log "ERROR" "curl error: $vnet_list"
        return 1
    fi
    
    log "DEBUG" "API response received, length: ${#vnet_list}"
    
    # Check if response is valid JSON
    if ! echo "$vnet_list" | jq '.' >/dev/null 2>&1; then
        log "ERROR" "Invalid JSON response when listing VNETs"
        log "ERROR" "Response (first 500 chars): ${vnet_list:0:500}"
        return 1
    fi
    
    log "DEBUG" "API response is valid JSON, checking for existing VNET..."
    
    # Check if the VNET with this slug exists
    local existing_vnet_id
    if ! existing_vnet_id=$(echo "$vnet_list" | jq -r --arg slug "$slug" '.[] | select(.slug==$slug) | .id // empty' 2>&1); then
        log "ERROR" "Failed to parse VNET list with jq"
        log "ERROR" "jq error: $existing_vnet_id"
        return 1
    fi
    
    if [ -n "$existing_vnet_id" ]; then
        log "INFO" "Found existing VNET with slug '$slug', ID: $(redact_sensitive "$existing_vnet_id" "vnet_id")"
        
        # Get details of the VNET to extract RPC URL
        log "DEBUG" "Getting VNET details for ID: $(redact_sensitive "$existing_vnet_id" "vnet_id")"
        local vnet_details
        if ! vnet_details=$(curl -s -X GET \
            "${API_BASE_URL}/account/${account}/project/${project}/vnets/${existing_vnet_id}" \
            -H "X-Access-Key: ${access_key}" 2>&1); then
            log "ERROR" "Failed to get VNET details"
            log "ERROR" "curl error: $vnet_details"
            return 1
        fi
        
        local admin_rpc
        if ! admin_rpc=$(echo "$vnet_details" | jq -r '.rpcs[] | select(.name=="Admin RPC") | .url' 2>&1); then
            log "ERROR" "Failed to extract admin RPC from VNET details"
            log "ERROR" "jq error: $admin_rpc"
            return 1
        fi
        
        if [ -n "$admin_rpc" ]; then
            log "INFO" "Successfully extracted admin RPC: $(redact_sensitive "$admin_rpc" "rpc")"
            echo "${admin_rpc}|${existing_vnet_id}"
            return 0
        else
            log "WARN" "No admin RPC found in VNET details"
        fi
    else
        log "DEBUG" "No existing VNET found with slug '$slug'"
    fi
    
    # No existing VNET found or couldn't extract details
    return 1
}

# Get existing VNET by checking Tenderly directly (same logic as deployment)
get_existing_vnet_for_network() {
    local network_slug=$1
    local tenderly_key=$2
    
    # Generate the expected slug for this branch and network
    local slug
    slug=$(generate_slug "$network_slug")
    
    log "INFO" "Looking for VNET with slug: $slug"
    
    # Check for existing VNET by slug
    local existing_vnet
    set +e  # Temporarily disable exit on error
    existing_vnet=$(check_existing_vnet_by_slug "$slug" "$TENDERLY_ACCOUNT" "$TENDERLY_PROJECT" "$tenderly_key")
    local check_result=$?
    set -e
    
    if [ $check_result -eq 0 ]; then
        log "INFO" "Found existing VNET for $network_slug with slug: $slug"
        echo "$existing_vnet"
        return 0
    else
        log "WARNING" "No existing VNET found for $network_slug with slug: $slug"
        return 1
    fi
}


###################################################################################
# Configuration Execution
###################################################################################

# Configure hooks on a single network using VNET admin RPC
configure_network_with_vnet_rpc() {
    local branch=$1
    local chain_id=$2
    local admin_rpc=$3
    local vnet_id=$4
    local private_key=$5
    
    local network_slug
    network_slug=$(get_network_slug "$chain_id")
    
    log "INFO" "Configuring hooks on $network_slug (Chain ID: $chain_id)"
    log "INFO" "Using VNET: $(redact_sensitive "$vnet_id" "vnet_id")"
    log "INFO" "Admin RPC: $(redact_sensitive "$admin_rpc" "rpc")"
    
    # Run the configuration script
    log "INFO" "Executing ConfigureV2Periphery script..."
    
    # Use pre-loaded private key (no need to fetch from 1Password again)
    
    if forge script script/ConfigureV2Periphery.s.sol:ConfigureV2Periphery \
        --sig 'run(uint256,uint64,string,string)' 1 "$chain_id" "$branch" "$DEMO_CORE_SALT" \
        --rpc-url "$admin_rpc" \
        --private-key "$private_key" \
        --broadcast; then
        
        log "INFO" "Successfully configured hooks on $network_slug"
        
        # Update deployment record
        update_configuration_record "$branch" "$chain_id" "$vnet_id"
        
        return 0
    else
        log "ERROR" "Failed to configure hooks on $network_slug"
        return 1
    fi
}

# Update configuration record
update_configuration_record() {
    local branch=$1
    local chain_id=$2
    local vnet_id=$3
    
    local output_file="script/output/$branch/latest.json"
    local temp_file=$(mktemp)
    
    # Create or update the configuration record
    local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if [ -f "$output_file" ]; then
        # Update existing file
        jq --arg chain_id "$chain_id" \
           --arg vnet_id "$vnet_id" \
           --arg timestamp "$current_time" \
           '.[$chain_id].hook_configuration_status = "completed" |
            .[$chain_id].hook_configuration_timestamp = $timestamp |
            .[$chain_id].vnet_id = $vnet_id' \
           "$output_file" > "$temp_file"
    else
        # Create new file
        jq -n --arg chain_id "$chain_id" \
              --arg vnet_id "$vnet_id" \
              --arg timestamp "$current_time" \
              '{($chain_id): {
                hook_configuration_status: "completed",
                hook_configuration_timestamp: $timestamp,
                vnet_id: $vnet_id
              }}' > "$temp_file"
    fi
    
    # Atomically replace the file
    mv "$temp_file" "$output_file"
    
    log "INFO" "Updated configuration record for chain $chain_id"
}

###################################################################################
# Main Execution Flow
###################################################################################

# Pre-fetch all VNET information for networks
prefetch_vnet_info() {
    local branch=$1
    local tenderly_key=$2
    
    log "INFO" "Pre-fetching VNET information for all networks..."
    
    # Declare associative arrays for VNET data
    declare -gA VNET_RPCS
    declare -gA VNET_IDS
    
    for network in "${!CHAIN_IDS[@]}"; do
        local chain_id="${CHAIN_IDS[$network]}"
        
        # Get network slug for VNET lookup
        local network_slug
        case $chain_id in
            1) network_slug="Ethereum" ;;
            8453) network_slug="Base" ;;
            10) network_slug="Optimism" ;;
        esac
        
        log "INFO" "Looking up VNET for $network (Chain ID: $chain_id)"
        
        # Try to find existing VNET for this network
        local vnet_response
        if vnet_response=$(get_existing_vnet_for_network "$network_slug" "$tenderly_key"); then
            # Parse the response: admin_rpc|vnet_id
            local admin_rpc=$(echo "$vnet_response" | cut -d'|' -f1)
            local vnet_id=$(echo "$vnet_response" | cut -d'|' -f2)
            
            # Store the VNET information
            VNET_RPCS["$chain_id"]="$admin_rpc"
            VNET_IDS["$chain_id"]="$vnet_id"
            
            log "INFO" "Found VNET for $network: $(redact_sensitive "$vnet_id" "vnet_id")"
            log "INFO" "Admin RPC: $(redact_sensitive "$admin_rpc" "rpc")"
        else
            log "WARNING" "No existing VNET found for $network - will skip this network"
        fi
    done
    
    log "INFO" "VNET pre-fetch completed"
}

# Configure all supported networks
configure_all_networks() {
    local branch=$1
    local tenderly_key=$2
    local private_key=$3
    local success_count=0
    local total_count=0
    
    log "INFO" "Starting hook configuration for all networks..."
    
    for network in "${!CHAIN_IDS[@]}"; do
        local chain_id="${CHAIN_IDS[$network]}"
        total_count=$((total_count + 1))
        
        log "INFO" "Processing $network (Chain ID: $chain_id)"
        
        # Check if we have VNET info for this network (from pre-fetch)
        if [[ -n "${VNET_RPCS[$chain_id]:-}" ]] && [[ -n "${VNET_IDS[$chain_id]:-}" ]]; then
            local admin_rpc="${VNET_RPCS[$chain_id]}"
            local vnet_id="${VNET_IDS[$chain_id]}"
            
            log "INFO" "Using pre-fetched VNET for $network: $(redact_sensitive "$vnet_id" "vnet_id")"
            log "INFO" "Admin RPC: $(redact_sensitive "$admin_rpc" "rpc")"
            
            # Configure hooks on this network using the VNET RPC (with pre-loaded private key)
            if configure_network_with_vnet_rpc "$branch" "$chain_id" "$admin_rpc" "$vnet_id" "$private_key"; then
                success_count=$((success_count + 1))
            else
                log "ERROR" "Configuration failed for $network"
            fi
        else
            log "WARNING" "No VNET information available for $network - skipping"
            log "WARNING" "Make sure deployments have been run for this network"
        fi
        
        log "INFO" "Completed processing $network"
        echo "---"
    done
    
    # Final summary
    log "INFO" "Configuration Summary:"
    log "INFO" "- Networks processed: $total_count"
    log "INFO" "- Successful configurations: $success_count"
    log "INFO" "- Failed configurations: $((total_count - success_count))"
    
    if [ "$success_count" -eq "$total_count" ]; then
        log "INFO" "All network configurations completed successfully!"
        return 0
    else
        log "ERROR" "Some network configurations failed"
        return 1
    fi
}

###################################################################################
# Script Entry Point
###################################################################################

main() {
    # Check arguments
    if [ $# -ne 1 ]; then
        log "ERROR" "Usage: $0 <branch_name>"
        log "ERROR" "Example: $0 demo"
        exit 1
    fi
    
    local branch=$1
    
    # Validate branch (demo only)
    validate_branch "$branch"
    
    log "INFO" "Starting Superform V2 Periphery Hook Configuration"
    log "INFO" "Branch: $branch"
    log "INFO" "Core Salt: $DEMO_CORE_SALT"
    
    # Set branch name for environment detection
    export BRANCH_NAME="$branch"
    
    # Check prerequisites
    log "INFO" "Checking prerequisites..."
    
    # Check AWS access for S3 operations
    check_aws_access
    
    # Get Tenderly access key
    local tenderly_key
    tenderly_key=$(get_tenderly_access_key)
    export TENDERLY_ACCESS_KEY="$tenderly_key"
    
    # Get private key once (no need to validate separately)
    log "INFO" "Getting private key from 1Password..."
    local private_key
    private_key=$(get_private_key)
    if [ -z "$private_key" ]; then
        log "ERROR" "Failed to retrieve private key"
        exit 1
    fi
    log "INFO" "Private key validation successful"
    
    # Setup output directory
    setup_output_directory "$branch"
    
    # Check deployments
    if ! check_core_deployment "$branch"; then
        exit 1
    fi
    
    if ! check_periphery_deployment "$branch"; then
        exit 1
    fi
    
    log "INFO" "All prerequisites met"
    
    # Pre-fetch VNET information for all networks (optimization)
    if ! prefetch_vnet_info "$branch" "$tenderly_key"; then
        log "ERROR" "Failed to pre-fetch VNET information"
        exit 1
    fi
    
    # Start configuration process
    log "INFO" "Starting hook configuration process..."
    
    if configure_all_networks "$branch" "$tenderly_key" "$private_key"; then
        log "INFO" "🎉 Hook configuration completed successfully!"
        log "INFO" "SuperGovernor is now configured with all available v2-core hooks"
    else
        log "ERROR" "❌ Hook configuration failed on some networks"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"