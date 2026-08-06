#!/usr/bin/env bash

###################################################################################
# V2 Periphery Smoke Test Script
###################################################################################
# Description:
#   Runs smoke tests for V2 Periphery contracts on all chains for the environment.
#
# Usage:
#   ./smoke_test_v2_periphery.sh <environment>
#
#   Parameters:
#     environment  Environment: "production" (or "prod") or "staging" (required)
#
# Chains by environment:
#   - production: Mainnet (chain ID 1)
#   - staging: Base (chain ID 8453)
#
# Examples:
#   ./smoke_test_v2_periphery.sh staging
#   ./smoke_test_v2_periphery.sh prod
#   ./smoke_test_v2_periphery.sh production
#
# Author: Superform Team
###################################################################################

set -euo pipefail

# Colors for better visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script directory and project root setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

###################################################################################
# Helper Functions
###################################################################################

print_header() {
    echo -e "${CYAN}+==========================================================================================+${NC}"
    echo -e "${CYAN}|                                                                                          |${NC}"
    echo -e "${CYAN}|${WHITE}                       V2 Periphery Smoke Test Script                                ${CYAN}|${NC}"
    echo -e "${CYAN}|                                                                                          |${NC}"
    echo -e "${CYAN}+==========================================================================================+${NC}"
}

print_separator() {
    echo -e "${BLUE}--------------------------------------------------------------------------------------------${NC}"
}

print_network_header() {
    local network=$1
    local chain_id=$2
    echo -e "${PURPLE}+-------------------------------------------------------------------------------------------+${NC}"
    echo -e "${PURPLE}|${WHITE}                    Running Smoke Tests on ${network} (Chain ID: ${chain_id})                    ${PURPLE}|${NC}"
    echo -e "${PURPLE}+-------------------------------------------------------------------------------------------+${NC}"
}

log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

usage() {
    cat << EOF
Usage: $0 <environment> [chain_id]

Arguments:
    environment  Environment: "production" (or "prod") or "staging" (required)
    chain_id     (optional) Run only on this chain ID (e.g., 4663 for RH)

Chains by environment:
    - production: Mainnet (chain ID 1)
    - staging: Base (chain ID 8453)

Examples:
    $0 staging
    $0 prod
    $0 production
EOF
    exit 1
}

run_smoke_test() {
    local chain_id=$1
    local network_name=$2
    local rpc_url=$3
    local forge_env=$4

    print_network_header "$network_name" "$chain_id"
    echo ""

    log "INFO" "Running smoke tests on $network_name..."

    if forge script script/SmokeTestV2Periphery.s.sol:SmokeTestV2Periphery \
        --sig 'run(uint256,uint64)' "$forge_env" "$chain_id" \
        --rpc-url "$rpc_url" \
        --chain "$chain_id" \
        -vvv; then
        echo -e "${GREEN}Smoke tests PASSED on $network_name${NC}"
        return 0
    else
        echo -e "${RED}Smoke tests FAILED on $network_name${NC}"
        return 1
    fi
}

###################################################################################
# Main
###################################################################################

main() {
    print_header

    # Check if arguments are provided
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing required argument: environment${NC}"
        usage
    fi

    local environment="$1"
    local chain_filter="${2:-}"

    # Normalize environment name
    case "$environment" in
        production|prod)
            environment="prod"
            ;;
        staging)
            environment="staging"
            ;;
        *)
            echo -e "${RED}Invalid environment: $environment${NC}"
            echo -e "${YELLOW}Environment must be 'production', 'prod', or 'staging'${NC}"
            exit 1
            ;;
    esac

    # Set environment-specific configuration
    local forge_env
    local networks_file
    local is_ci_environment="${CI:-false}"

    if [ "$environment" = "prod" ]; then
        log "INFO" "Loading production network configuration..."
        networks_file="$SCRIPT_DIR/networks-production.sh"
        forge_env=0
        export GITHUB_REF_NAME="${GITHUB_REF_NAME:-prod}"
    else
        log "INFO" "Loading staging network configuration..."
        networks_file="$SCRIPT_DIR/networks-staging.sh"
        forge_env=2
        export GITHUB_REF_NAME="${GITHUB_REF_NAME:-staging}"
    fi

    # Source network configuration
    if [ ! -f "$networks_file" ]; then
        echo -e "${RED}Network configuration file not found: $networks_file${NC}"
        exit 1
    fi
    source "$networks_file"

    echo -e "${GREEN}Network configuration loaded for $environment environment${NC}"

    # Filter networks if chain_id argument is provided
    if [[ -n "$chain_filter" ]]; then
        local filtered=()
        for network_def in "${NETWORKS[@]}"; do
            IFS=':' read -r network_id _ _ <<< "$network_def"
            if [[ "$network_id" == "$chain_filter" ]]; then
                filtered+=("$network_def")
            fi
        done
        if [[ ${#filtered[@]} -eq 0 ]]; then
            echo -e "${RED}Chain ID $chain_filter not found in $environment network configuration${NC}"
            exit 1
        fi
        NETWORKS=("${filtered[@]}")
        echo -e "${YELLOW}Filtered to chain $chain_filter only${NC}"
    fi

    # Load RPC URLs - use different method for CI vs local
    echo -e "${CYAN}Loading RPC URLs...${NC}"
    if [[ "$is_ci_environment" == "true" ]]; then
        # CI environment - load from environment variables
        if ! load_rpc_urls_ci; then
            echo -e "${RED}Failed to load RPC URLs from environment variables${NC}"
            echo -e "${YELLOW}Make sure ETHEREUM_RPC_URL is set in GitHub secrets${NC}"
            exit 1
        fi
    else
        # Local environment - load from 1Password
        if ! load_rpc_urls; then
            echo -e "${RED}Failed to load some RPC URLs from credential manager${NC}"
            exit 1
        fi
    fi

    print_separator
    echo -e "${BLUE}Smoke Test Configuration${NC}"
    echo -e "${CYAN}  Environment: ${WHITE}$environment${NC}"
    echo -e "${CYAN}  Networks:${NC}"
    for network_def in "${NETWORKS[@]}"; do
        IFS=':' read -r network_id network_name _ <<< "$network_def"
        echo -e "${CYAN}    - ${WHITE}$network_name${CYAN} (Chain ID: ${WHITE}$network_id${CYAN})${NC}"
    done
    print_separator

    # Change to project root directory for forge commands
    cd "$PROJECT_ROOT"

    # Export PROJECT_ROOT as environment variable for Solidity scripts
    export SUPERFORM_PROJECT_ROOT="$PROJECT_ROOT"

    echo -e "${BLUE}Running V2 Periphery Smoke Tests on all networks...${NC}"
    echo ""

    # Track results
    local passed=0
    local failed=0
    local failed_networks=()

    # Run smoke tests on all networks
    for network_def in "${NETWORKS[@]}"; do
        IFS=':' read -r network_id network_name rpc_var <<< "$network_def"
        local rpc_url="${!rpc_var}"

        if [ -z "$rpc_url" ]; then
            echo -e "${YELLOW}Skipping $network_name: RPC URL not configured${NC}"
            failed=$((failed + 1))
            failed_networks+=("$network_name (no RPC)")
            continue
        fi

        if run_smoke_test "$network_id" "$network_name" "$rpc_url" "$forge_env"; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
            failed_networks+=("$network_name")
        fi

        echo ""
    done

    # Print summary
    print_separator
    echo -e "${BLUE}Smoke Test Summary${NC}"
    echo -e "${CYAN}  Environment: ${WHITE}$environment${NC}"
    echo -e "${GREEN}  Passed: ${WHITE}$passed${NC}"
    echo -e "${RED}  Failed: ${WHITE}$failed${NC}"

    if [ ${#failed_networks[@]} -gt 0 ]; then
        echo -e "${RED}  Failed networks:${NC}"
        for network in "${failed_networks[@]}"; do
            echo -e "${RED}    - $network${NC}"
        done
    fi

    print_separator

    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All V2 Periphery Smoke Tests PASSED!${NC}"
        exit 0
    else
        echo -e "${RED}Some V2 Periphery Smoke Tests FAILED${NC}"
        exit 1
    fi
}

main "$@"
