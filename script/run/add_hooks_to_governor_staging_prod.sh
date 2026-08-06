#!/usr/bin/env bash

###################################################################################
# Superform V2 Periphery Hook Configuration Script - Staging & Production
###################################################################################
# Description:
#   This script configures SuperGovernor with all v2-core hooks for staging and
#   production environments. It reads contract addresses from S3 and uses the
#   appropriate configuration based on the environment and mode.
#
# Usage:
#   ./add_hooks_to_governor_staging_prod.sh <environment> <mode> [account] [chain_id]
#
#   Parameters:
#     environment: "staging" or "prod"
#     mode: "simulate" or "configure"
#     account: Account name (required for configure mode, e.g., "v2-supervaults")
#     chain_id: (optional) Run only on this chain ID (e.g., 4663 for RH)
#
#   Examples:
#     ./add_hooks_to_governor_staging_prod.sh staging simulate
#     ./add_hooks_to_governor_staging_prod.sh staging configure v2-supervaults
#     ./add_hooks_to_governor_staging_prod.sh prod simulate
#     ./add_hooks_to_governor_staging_prod.sh prod configure v2-supervaults
#     ./add_hooks_to_governor_staging_prod.sh prod simulate "" 4663
#     ./add_hooks_to_governor_staging_prod.sh prod configure v2-supervaults 4663
#
# Prerequisites:
#   - v2-core contracts must be deployed on target networks
#   - v2-periphery contracts must be deployed (SuperGovernor required)
#   - Core and periphery addresses merged in S3 (run merge script first)
#   - For configure mode: Foundry account with GOVERNOR_ROLE permissions
#   - AWS CLI configured for S3 access
#
# Author: Superform Team
# Version: 1.0.0
###################################################################################

set -euo pipefail  # Exit on error, undefined var, pipe failure

###################################################################################
# Network Filter Configuration
###################################################################################

# Networks to SKIP (these are already configured)
# Comment out networks you want to configure
SKIP_NETWORKS=(
    "1"      # Ethereum - already configured
    "8453"   # Base - already configured
)

# Function to check if a network should be skipped
should_skip_network() {
    local network_id=$1
    for skip_id in "${SKIP_NETWORKS[@]}"; do
        if [ "$network_id" = "$skip_id" ]; then
            return 0  # Should skip
        fi
    done
    return 1  # Should not skip
}

###################################################################################
# Script Configuration
###################################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Network configuration will be sourced after environment is determined
# See source_network_config function

# S3 bucket for fetching contract addresses
readonly BUCKET="superform-deployment-state"

# Salt namespaces (must match ConfigBase.sol)
readonly STAGING_SALT_NAMESPACE="STAGING1.0.0"
readonly PRODUCTION_SALT_NAMESPACE="PROD1.0.0"

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

# Logging function for consistent output
log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

# Print header
print_header() {
    local environment=$1
    local mode=$2

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}║${WHITE}           🔧 SuperGovernor Hook Configuration - ${environment^^} 🔧                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}                          Mode: ${mode^^}                                            ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Print section separator
print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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

# Validate mode parameter
validate_mode() {
    local mode=$1
    if [ "$mode" != "simulate" ] && [ "$mode" != "configure" ]; then
        log "ERROR" "Invalid mode: $mode"
        log "ERROR" "Must be either 'simulate' or 'configure'"
        exit 1
    fi
}

# Get forge environment value
get_forge_env() {
    local environment=$1
    if [ "$environment" = "staging" ]; then
        echo "2"
    else
        echo "0"
    fi
}

# Get salt namespace
get_salt_namespace() {
    local environment=$1
    if [ "$environment" = "staging" ]; then
        echo "$STAGING_SALT_NAMESPACE"
    else
        echo "$PRODUCTION_SALT_NAMESPACE"
    fi
}

# Check AWS access
check_aws_access() {
    if ! command -v aws &> /dev/null; then
        log "ERROR" "AWS CLI not found. Required for fetching contract addresses from S3"
        exit 1
    fi

    if ! aws sts get-caller-identity &>/dev/null; then
        log "ERROR" "AWS CLI not configured properly"
        exit 1
    fi

    log "INFO" "AWS CLI configured successfully"
}

# Read merged state from S3 (for staging)
read_merged_state_from_s3() {
    local environment=$1
    local s3_path="s3://$BUCKET/$environment/latest.json"
    local temp_file="/tmp/${environment}_merged_state.json"

    log "INFO" "Reading merged state from S3: $s3_path"

    if aws s3 cp "$s3_path" "$temp_file" --quiet 2>/dev/null; then
        log "INFO" "Successfully downloaded merged state from S3"

        # Validate JSON
        if ! jq '.' "$temp_file" >/dev/null 2>&1; then
            log "ERROR" "Invalid JSON in merged state file"
            return 1
        fi

        echo "$temp_file"
        return 0
    else
        log "ERROR" "Failed to read merged state from S3: $s3_path"
        log "ERROR" "Make sure you have run the merge script first"
        return 1
    fi
}

# Read merged state from local file (for prod)
read_merged_state_from_local() {
    local environment=$1
    local local_path="$SCRIPT_DIR/../output/$environment/latest.json"

    log "INFO" "Reading merged state from local: $local_path"

    if [ -f "$local_path" ]; then
        # Validate JSON
        if ! jq '.' "$local_path" >/dev/null 2>&1; then
            log "ERROR" "Invalid JSON in local merged state file"
            return 1
        fi

        log "INFO" "Successfully validated local merged state"
        echo "$local_path"
        return 0
    else
        log "ERROR" "Local merged state not found: $local_path"
        log "ERROR" "Run merge_periphery_to_core_local_prod.sh first"
        return 1
    fi
}

# Check if SuperGovernor exists for a network
check_supergovernor_exists() {
    local merged_state_file=$1
    local network_name=$2
    local network_id=$3
    local environment=$4

    local governor_addr

    # First, try to get from merged state file
    governor_addr=$(jq -r ".networks[\"$network_name\"].contracts.SuperGovernor // empty" "$merged_state_file" 2>/dev/null)

    if [ -n "$governor_addr" ] && [ "$governor_addr" != "null" ]; then
        echo "$governor_addr"
        return 0
    fi

    # Fallback: try to read from individual chain output file
    local individual_file="$SCRIPT_DIR/../output/$environment/$network_id/$network_name-latest.json"
    if [ -f "$individual_file" ]; then
        governor_addr=$(jq -r '.SuperGovernor // empty' "$individual_file" 2>/dev/null)
        if [ -n "$governor_addr" ] && [ "$governor_addr" != "null" ]; then
            log "INFO" "Found SuperGovernor in individual output file: $individual_file"
            echo "$governor_addr"
            return 0
        fi
    fi

    return 1
}

# Load RPC URLs from credential manager
load_rpc_urls() {
    log "INFO" "Loading staging RPC URLs from credential manager..."

    local failed_rpcs=()

    echo "  • Loading Base RPC..."
    if ! export BASE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential 2>/dev/null); then
        failed_rpcs+=("BASE_RPC_URL")
    fi

    if [[ ${#failed_rpcs[@]} -gt 0 ]]; then
        echo "❌ Failed to load the following RPC URLs from 1Password:"
        for failed_rpc in "${failed_rpcs[@]}"; do
            echo "   • $failed_rpc"
        done
        log "ERROR" "Failed to load RPC URLs"
        return 1
    fi

    log "INFO" "✅ RPC URLs loaded successfully (Base)"
}

###################################################################################
# Configuration Execution
###################################################################################

# Configure hooks on a single network
configure_network() {
    local environment=$1
    local mode=$2
    local network_id=$3
    local network_name=$4
    local salt_namespace=$5
    local forge_env=$6
    local account=$7

    log "INFO" "Configuring hooks on $network_name (Chain ID: $network_id)"

    # Get RPC URL
    local rpc_url
    rpc_url=$(get_rpc_url "$network_id")
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to get RPC URL for network $network_id"
        return 1
    fi

    log "INFO" "Using RPC: ${rpc_url:0:30}..."

    # Set up forge flags based on mode
    local forge_flags=""
    if [ "$mode" = "configure" ]; then
        # Configure mode: Use --account flag with --broadcast
        forge_flags="--account $account --broadcast"
        log "INFO" "Mode: Configure (will broadcast transactions using account: $account)"
    else
        # Simulate mode: Use deployer address with --sender (no broadcast)
        local deployer="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"
        forge_flags="--sender $deployer"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $deployer)"
    fi

    log "INFO" "Executing ConfigureV2Periphery script..."
    log "INFO" "  - Environment: $forge_env"
    log "INFO" "  - Chain ID: $network_id"
    log "INFO" "  - Salt Namespace: $salt_namespace"

    # Execute the configuration script
    if forge script script/ConfigureV2Periphery.s.sol:ConfigureV2Periphery \
        --sig 'run(uint256,uint64,string)' "$forge_env" "$network_id" "$salt_namespace" \
        --rpc-url "$rpc_url" \
        $forge_flags \
        -vvv; then

        log "INFO" "✅ Successfully configured hooks on $network_name"
        return 0
    else
        log "ERROR" "❌ Failed to configure hooks on $network_name"
        return 1
    fi
}

# Configure all supported networks
configure_all_networks() {
    local environment=$1
    local mode=$2
    local salt_namespace=$3
    local forge_env=$4
    local account=$5

    log "INFO" "Starting hook configuration for all networks..."

    # Read merged state - use local file for prod, S3 for staging
    local merged_state_file
    if [ "$environment" = "prod" ]; then
        if ! merged_state_file=$(read_merged_state_from_local "$environment"); then
            log "ERROR" "Failed to read merged state from local"
            return 1
        fi
    else
        # staging - continue using S3
        if ! merged_state_file=$(read_merged_state_from_s3 "$environment"); then
            log "ERROR" "Failed to read merged state from S3"
            return 1
        fi
    fi

    local success_count=0
    local total_count=0
    local skipped_count=0

    # Get all supported networks
    local supported_network_ids=$(get_supported_networks)

    if [ -z "$supported_network_ids" ]; then
        log "ERROR" "No networks found in network configuration"
        return 1
    fi

    # Display skip list
    if [ ${#SKIP_NETWORKS[@]} -gt 0 ]; then
        log "INFO" "Networks to skip: ${SKIP_NETWORKS[*]}"
        log "INFO" "(Edit SKIP_NETWORKS in script to change)"
    fi

    # Process each network
    for network_id in $supported_network_ids; do
        total_count=$((total_count + 1))

        # Check if network should be skipped
        if should_skip_network "$network_id"; then
            local skip_network_name=$(get_network_name "$network_id" 2>/dev/null || echo "Unknown")
            log "INFO" "SKIP: $skip_network_name (Chain ID: $network_id) - in SKIP_NETWORKS list"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        # Get network name
        local network_name=$(get_network_name "$network_id")
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to get network name for ID: $network_id"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        echo ""
        print_separator
        log "INFO" "Processing $network_name (Chain ID: $network_id)"
        print_separator

        # Check if SuperGovernor exists for this network
        local governor_addr
        if ! governor_addr=$(check_supergovernor_exists "$merged_state_file" "$network_name" "$network_id" "$environment"); then
            log "WARNING" "SuperGovernor not found for $network_name - skipping"
            log "WARNING" "Make sure periphery contracts have been deployed and merged"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        log "INFO" "Found SuperGovernor at: $governor_addr"

        # Configure hooks on this network
        if configure_network "$environment" "$mode" "$network_id" "$network_name" "$salt_namespace" "$forge_env" "$account"; then
            success_count=$((success_count + 1))
        else
            log "ERROR" "Configuration failed for $network_name"
        fi
    done

    # Final summary
    echo ""
    print_separator
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                      📋 CONFIGURATION SUMMARY 📋                                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Environment: ${WHITE}$environment${NC}"
    echo -e "${CYAN}Mode: ${WHITE}$mode${NC}"
    echo -e "${CYAN}Total Networks: ${WHITE}$total_count${NC}"
    echo -e "${GREEN}Successful: ${WHITE}$success_count${NC}"
    echo -e "${YELLOW}Skipped: ${WHITE}$skipped_count${NC}"
    echo -e "${RED}Failed: ${WHITE}$((total_count - success_count - skipped_count))${NC}"
    print_separator

    if [ "$success_count" -eq "$total_count" ]; then
        log "INFO" "🎉 All network configurations completed successfully!"
        return 0
    elif [ "$success_count" -gt 0 ]; then
        log "WARNING" "⚠️ Some network configurations completed, but not all"
        return 0
    else
        log "ERROR" "❌ No network configurations succeeded"
        return 1
    fi
}

###################################################################################
# Main Execution Flow
###################################################################################

main() {
    # Check arguments
    if [ $# -lt 2 ]; then
        log "ERROR" "Usage: $0 <environment> <mode> [account] [chain_id]"
        log "ERROR" "  environment: 'staging' or 'prod'"
        log "ERROR" "  mode: 'simulate' or 'configure'"
        log "ERROR" "  account: Account name (required for configure mode)"
        log "ERROR" "  chain_id: (optional) Run only on this chain ID"
        log "ERROR" ""
        log "ERROR" "Examples:"
        log "ERROR" "  $0 staging simulate"
        log "ERROR" "  $0 staging configure v2-supervaults"
        log "ERROR" "  $0 prod simulate"
        log "ERROR" "  $0 prod configure v2-supervaults"
        log "ERROR" "  $0 prod simulate \"\" 4663"
        log "ERROR" "  $0 prod configure v2-supervaults 4663"
        exit 1
    fi

    local environment=$1
    local mode=$2
    local account="${3:-}"
    local chain_filter="${4:-}"

    # Validate environment
    validate_environment "$environment"

    # Source network configuration based on environment
    source_network_config "$environment"

    # Apply chain filter if provided (overrides SKIP_NETWORKS)
    if [[ -n "$chain_filter" ]]; then
        log "INFO" "Chain filter applied: only targeting chain $chain_filter"
        # Override SKIP_NETWORKS: skip everything except the target chain
        local all_network_ids
        all_network_ids=$(get_supported_networks)
        SKIP_NETWORKS=()
        for nid in $all_network_ids; do
            if [[ "$nid" != "$chain_filter" ]]; then
                SKIP_NETWORKS+=("$nid")
            fi
        done
        log "INFO" "Filtered to chain $chain_filter only"
    fi

    # Validate mode
    validate_mode "$mode"

    # Validate account for configure mode
    if [ "$mode" = "configure" ]; then
        if [ -z "$account" ]; then
            log "ERROR" "Account name is required for configure mode"
            log "ERROR" "Usage: $0 $environment configure <account_name>"
            exit 1
        fi

        log "INFO" "Using account: $account"
        log "INFO" "Note: Account validation will happen during forge script execution"
    fi

    # Print header
    print_header "$environment" "$mode"

    log "INFO" "Starting Superform V2 Periphery Hook Configuration"
    log "INFO" "Environment: $environment"
    log "INFO" "Mode: $mode"
    if [ -n "$account" ]; then
        log "INFO" "Account: $account"
    fi

    # Get configuration values
    local forge_env
    forge_env=$(get_forge_env "$environment")

    local salt_namespace
    salt_namespace=$(get_salt_namespace "$environment")

    log "INFO" "Forge Environment: $forge_env"
    log "INFO" "Salt Namespace: $salt_namespace"

    print_separator

    # Check prerequisites
    log "INFO" "Checking prerequisites..."

    # Check AWS access (only needed for staging)
    if [ "$environment" = "staging" ]; then
        check_aws_access
    fi

    # Load RPC URLs
    load_rpc_urls

    # Print network information
    print_network_info

    log "INFO" "All prerequisites met"
    print_separator

    # Start configuration process
    log "INFO" "Starting hook configuration process..."

    if configure_all_networks "$environment" "$mode" "$salt_namespace" "$forge_env" "$account"; then
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                                                      ║${NC}"
        echo -e "${GREEN}║${WHITE}              🎉 Hook Configuration Completed Successfully! 🎉                    ${GREEN}║${NC}"
        echo -e "${GREEN}║                                                                                      ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        log "INFO" "SuperGovernor is now configured with all available v2-core hooks"
    else
        echo ""
        echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                                                                                      ║${NC}"
        echo -e "${RED}║${WHITE}                 ❌ Hook Configuration Failed ❌                                  ${RED}║${NC}"
        echo -e "${RED}║                                                                                      ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"
