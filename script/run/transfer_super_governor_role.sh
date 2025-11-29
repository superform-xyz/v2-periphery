#!/usr/bin/env bash

###################################################################################
# Transfer SUPER_GOVERNOR_ROLE Script - Staging & Production
###################################################################################
# Description:
#   This script transfers SUPER_GOVERNOR_ROLE and DEFAULT_ADMIN_ROLE from the
#   deployer address to the production SUPER_GOVERNOR_ADDRESS after Fireblocks
#   is set up.
#
# Usage:
#   ./transfer_super_governor_role.sh <environment> <mode> [account]
#
#   Parameters:
#     environment: "staging" or "prod"
#     mode: "simulate" or "execute"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#
#   Examples:
#     ./transfer_super_governor_role.sh staging simulate
#     ./transfer_super_governor_role.sh staging execute v2-supervaults
#     ./transfer_super_governor_role.sh prod simulate
#     ./transfer_super_governor_role.sh prod execute v2-supervaults
#
# Prerequisites:
#   - SuperGovernor must be deployed on target networks
#   - Deployer must currently hold SUPER_GOVERNOR_ROLE and DEFAULT_ADMIN_ROLE
#   - For execute mode: Foundry account with deployer permissions
#   - AWS CLI configured for S3 access
#
# IMPORTANT:
#   This is a one-way operation! Once roles are transferred, the deployer
#   will no longer have admin access to the SuperGovernor contract.
#
# Author: Superform Team
# Version: 1.0.0
###################################################################################

set -euo pipefail  # Exit on error, undefined var, pipe failure

###################################################################################
# Script Configuration
###################################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# S3 bucket for fetching contract addresses
readonly BUCKET="superform-deployment-state"

# Salt namespaces
readonly STAGING_SALT_NAMESPACE="DEPLOYSTAGING1.0.0"
readonly PRODUCTION_SALT_NAMESPACE="DEPLOYPROD1.0.0"

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
    echo -e "${CYAN}║${WHITE}         🔐 Transfer SUPER_GOVERNOR_ROLE - ${environment^^} 🔐                        ${CYAN}║${NC}"
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
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ]; then
        log "ERROR" "Invalid mode: $mode"
        log "ERROR" "Must be either 'simulate' or 'execute'"
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

# Read merged state from S3
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
        return 1
    fi
}

# Check if SuperGovernor exists for a network
check_supergovernor_exists() {
    local merged_state_file=$1
    local network_name=$2

    local governor_addr
    governor_addr=$(jq -r ".networks[\"$network_name\"].contracts.SuperGovernor // empty" "$merged_state_file" 2>/dev/null)

    if [ -n "$governor_addr" ] && [ "$governor_addr" != "null" ]; then
        echo "$governor_addr"
        return 0
    else
        return 1
    fi
}

# Load RPC URLs from credential manager
load_rpc_urls() {
    log "INFO" "Loading RPC URLs from credential manager..."

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

    log "INFO" "✅ RPC URLs loaded successfully"
}

###################################################################################
# Role Transfer Execution
###################################################################################

# Transfer role on a single network
transfer_role_network() {
    local environment=$1
    local mode=$2
    local network_id=$3
    local network_name=$4
    local salt_namespace=$5
    local forge_env=$6
    local account=$7

    log "INFO" "Transferring SUPER_GOVERNOR_ROLE on $network_name (Chain ID: $network_id)"

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
    if [ "$mode" = "execute" ]; then
        # Execute mode: Use --account flag with --broadcast
        forge_flags="--account $account --broadcast"
        log "INFO" "Mode: Execute (will broadcast transactions using account: $account)"
    else
        # Simulate mode: Use deployer address with --sender (no broadcast)
        local deployer="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"
        forge_flags="--sender $deployer"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $deployer)"
    fi

    log "INFO" "Executing TransferSuperGovernorRole script..."
    log "INFO" "  - Environment: $forge_env"
    log "INFO" "  - Chain ID: $network_id"
    log "INFO" "  - Salt Namespace: $salt_namespace"

    # Execute the transfer script
    if forge script script/TransferSuperGovernorRole.s.sol:TransferSuperGovernorRole \
        --sig 'run(uint256,uint64,string)' "$forge_env" "$network_id" "$salt_namespace" \
        --rpc-url "$rpc_url" \
        $forge_flags \
        -vvv; then

        log "INFO" "✅ Successfully transferred role on $network_name"
        return 0
    else
        log "ERROR" "❌ Failed to transfer role on $network_name"
        return 1
    fi
}

# Transfer roles on all supported networks
transfer_all_networks() {
    local environment=$1
    local mode=$2
    local salt_namespace=$3
    local forge_env=$4
    local account=$5

    log "INFO" "Starting role transfer for all networks..."

    # Read merged state from S3
    local merged_state_file
    if ! merged_state_file=$(read_merged_state_from_s3 "$environment"); then
        log "ERROR" "Failed to read merged state from S3"
        return 1
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

    # Process each network
    for network_id in $supported_network_ids; do
        total_count=$((total_count + 1))

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
        if ! governor_addr=$(check_supergovernor_exists "$merged_state_file" "$network_name"); then
            log "WARNING" "SuperGovernor not found for $network_name - skipping"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        log "INFO" "Found SuperGovernor at: $governor_addr"

        # Transfer role on this network
        if transfer_role_network "$environment" "$mode" "$network_id" "$network_name" "$salt_namespace" "$forge_env" "$account"; then
            success_count=$((success_count + 1))
        else
            log "ERROR" "Role transfer failed for $network_name"
        fi
    done

    # Final summary
    echo ""
    print_separator
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                      📋 TRANSFER SUMMARY 📋                                          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Environment: ${WHITE}$environment${NC}"
    echo -e "${CYAN}Mode: ${WHITE}$mode${NC}"
    echo -e "${CYAN}Total Networks: ${WHITE}$total_count${NC}"
    echo -e "${GREEN}Successful: ${WHITE}$success_count${NC}"
    echo -e "${YELLOW}Skipped: ${WHITE}$skipped_count${NC}"
    echo -e "${RED}Failed: ${WHITE}$((total_count - success_count - skipped_count))${NC}"
    print_separator

    if [ "$success_count" -eq "$total_count" ]; then
        log "INFO" "🎉 All role transfers completed successfully!"
        return 0
    elif [ "$success_count" -gt 0 ]; then
        log "WARNING" "⚠️ Some role transfers completed, but not all"
        return 0
    else
        log "ERROR" "❌ No role transfers succeeded"
        return 1
    fi
}

###################################################################################
# Main Execution Flow
###################################################################################

main() {
    # Check arguments
    if [ $# -lt 2 ]; then
        log "ERROR" "Usage: $0 <environment> <mode> [account]"
        log "ERROR" "  environment: 'staging' or 'prod'"
        log "ERROR" "  mode: 'simulate' or 'execute'"
        log "ERROR" "  account: Account name (required for execute mode)"
        log "ERROR" ""
        log "ERROR" "Examples:"
        log "ERROR" "  $0 staging simulate"
        log "ERROR" "  $0 staging execute v2-supervaults"
        log "ERROR" "  $0 prod simulate"
        log "ERROR" "  $0 prod execute v2-supervaults"
        log "ERROR" ""
        log "ERROR" "⚠️  WARNING: This is a one-way operation!"
        log "ERROR" "    Once roles are transferred, the deployer will no longer"
        log "ERROR" "    have admin access to the SuperGovernor contract."
        exit 1
    fi

    local environment=$1
    local mode=$2
    local account="${3:-}"

    # Validate environment
    validate_environment "$environment"

    # Source network configuration based on environment
    source_network_config "$environment"

    # Validate mode
    validate_mode "$mode"

    # Validate account for execute mode
    if [ "$mode" = "execute" ]; then
        if [ -z "$account" ]; then
            log "ERROR" "Account name is required for execute mode"
            log "ERROR" "Usage: $0 $environment execute <account_name>"
            exit 1
        fi

        log "INFO" "Using account: $account"

        # Extra confirmation for execute mode
        echo ""
        echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${WHITE}                         ⚠️  WARNING ⚠️                                              ${RED}║${NC}"
        echo -e "${RED}║${WHITE}                                                                                    ${RED}║${NC}"
        echo -e "${RED}║${WHITE}  You are about to transfer SUPER_GOVERNOR_ROLE and DEFAULT_ADMIN_ROLE             ${RED}║${NC}"
        echo -e "${RED}║${WHITE}  from the deployer to the production address.                                      ${RED}║${NC}"
        echo -e "${RED}║${WHITE}                                                                                    ${RED}║${NC}"
        echo -e "${RED}║${WHITE}  This is a ONE-WAY operation! The deployer will lose all admin access.             ${RED}║${NC}"
        echo -e "${RED}║${WHITE}                                                                                    ${RED}║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log "INFO" "Operation cancelled by user"
            exit 0
        fi
    fi

    # Print header
    print_header "$environment" "$mode"

    log "INFO" "Starting SUPER_GOVERNOR_ROLE Transfer"
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

    # Check AWS access
    check_aws_access

    # Load RPC URLs
    load_rpc_urls

    # Print network information
    print_network_info

    log "INFO" "All prerequisites met"
    print_separator

    # Start transfer process
    log "INFO" "Starting role transfer process..."

    if transfer_all_networks "$environment" "$mode" "$salt_namespace" "$forge_env" "$account"; then
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                                                      ║${NC}"
        echo -e "${GREEN}║${WHITE}           🎉 Role Transfer Completed Successfully! 🎉                            ${GREEN}║${NC}"
        echo -e "${GREEN}║                                                                                      ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        log "INFO" "SUPER_GOVERNOR_ROLE has been transferred to the production address"
    else
        echo ""
        echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                                                                                      ║${NC}"
        echo -e "${RED}║${WHITE}                 ❌ Role Transfer Failed ❌                                        ${RED}║${NC}"
        echo -e "${RED}║                                                                                      ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"
