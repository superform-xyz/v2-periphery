#!/usr/bin/env bash

###################################################################################
# SetGasInfo Emergency Script
###################################################################################
# Description:
#   Emergency script to set gas info for ECDSAPPSOracle on SuperGovernor.
#   This script is mainnet-only and should be used if gas info was not set
#   during deployment or needs to be updated.
#
# Usage:
#   ./set_gas_info.sh --env <env> --chain-id <chain_id> [--simulate] [--rpc-url <url>]
#
#   Parameters:
#     --env        Environment: 0 = production, 2 = staging (required)
#     --chain-id   Chain ID (must be 1 for mainnet) (required)
#     --simulate   Run in simulation mode without broadcasting (optional)
#     --rpc-url    RPC URL (optional, defaults to ETH_RPC_URL env var)
#
# Examples:
#   # Simulate on mainnet production
#   ./set_gas_info.sh --env 0 --chain-id 1 --simulate
#
#   # Execute on mainnet production
#   ./set_gas_info.sh --env 0 --chain-id 1
#
#   # Execute on mainnet staging
#   ./set_gas_info.sh --env 2 --chain-id 1
#
# Prerequisites:
#   - ETH_RPC_URL environment variable set (or use --rpc-url)
#   - ETH_PRIVATE_KEY environment variable set (or use 1Password)
#   - Deployer must have DEFAULT_ADMIN_ROLE on SuperGovernor
#
# Note:
#   Salt namespace is fixed based on environment:
#   - Production (env=0): PROD1.0.0
#   - Staging (env=2): STAGING1.0.0
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

###################################################################################
# Helper Functions
###################################################################################

log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

usage() {
    cat << EOF
Usage: $0 --env <env> --chain-id <chain_id> [--simulate] [--rpc-url <url>]

Options:
    --env        Environment: 0 = production, 2 = staging (required)
    --chain-id   Chain ID (must be 1 for mainnet) (required)
    --simulate   Run in simulation mode without broadcasting
    --rpc-url    RPC URL (optional, defaults to ETH_RPC_URL env var)
    --help       Show this help message

Note: Salt namespace is fixed based on environment (PROD1.0.0 or STAGING1.0.0)

Examples:
    # Simulate on mainnet production
    $0 --env 0 --chain-id 1 --simulate

    # Execute on mainnet production
    $0 --env 0 --chain-id 1

    # Execute on mainnet staging
    $0 --env 2 --chain-id 1
EOF
    exit 1
}

get_private_key() {
    # Try 1Password first
    if command -v op &> /dev/null; then
        log "INFO" "Attempting to get private key from 1Password..."
        local private_key
        if private_key=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/DEPLOYER_PRIVATE_KEY/credential 2>/dev/null); then
            echo "$private_key"
            return 0
        fi
    fi

    # Fallback to environment variable
    if [ -n "${ETH_PRIVATE_KEY:-}" ]; then
        log "INFO" "Using private key from ETH_PRIVATE_KEY environment variable"
        echo "$ETH_PRIVATE_KEY"
        return 0
    fi

    log "ERROR" "No private key found. Set ETH_PRIVATE_KEY or configure 1Password CLI"
    exit 1
}

get_rpc_url() {
    local provided_rpc="${1:-}"

    if [ -n "$provided_rpc" ]; then
        echo "$provided_rpc"
        return 0
    fi

    if [ -n "${ETH_RPC_URL:-}" ]; then
        echo "$ETH_RPC_URL"
        return 0
    fi

    log "ERROR" "No RPC URL provided. Use --rpc-url or set ETH_RPC_URL environment variable"
    exit 1
}

###################################################################################
# Main
###################################################################################

main() {
    local env=""
    local chain_id=""
    local simulate=false
    local rpc_url=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env)
                env="$2"
                shift 2
                ;;
            --chain-id)
                chain_id="$2"
                shift 2
                ;;
            --simulate)
                simulate=true
                shift
                ;;
            --rpc-url)
                rpc_url="$2"
                shift 2
                ;;
            --help)
                usage
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$env" ]; then
        log "ERROR" "Missing required argument: --env"
        usage
    fi

    if [ -z "$chain_id" ]; then
        log "ERROR" "Missing required argument: --chain-id"
        usage
    fi

    # Validate env
    if [ "$env" != "0" ] && [ "$env" != "2" ]; then
        log "ERROR" "Invalid environment: $env. Must be 0 (production) or 2 (staging)"
        exit 1
    fi

    # Validate chain ID (mainnet only)
    if [ "$chain_id" != "1" ]; then
        log "ERROR" "Invalid chain ID: $chain_id. Gas info is only set on mainnet (chain ID 1)"
        exit 1
    fi

    # Get RPC URL
    rpc_url=$(get_rpc_url "$rpc_url")

    # Determine salt based on environment (for display only - script uses fixed salt internally)
    local salt
    if [ "$env" = "0" ]; then
        salt="PROD1.0.0"
    else
        salt="STAGING1.0.0"
    fi

    log "INFO" "============================================"
    log "INFO" "SetGasInfo Script"
    log "INFO" "============================================"
    log "INFO" "Environment: $env"
    log "INFO" "Chain ID: $chain_id"
    log "INFO" "Salt (fixed): $salt"
    log "INFO" "Simulate: $simulate"
    log "INFO" "RPC URL: ${rpc_url:0:50}..."
    log "INFO" "============================================"

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" ${PROJECT_ROOT}/script/SetGasInfo.s.sol:SetGasInfo"
    forge_cmd+=" --sig 'run(uint256,uint64)' $env $chain_id"
    forge_cmd+=" --rpc-url '$rpc_url'"

    if [ "$simulate" = true ]; then
        log "INFO" "Running in SIMULATION mode (no broadcast)"
    else
        log "INFO" "Running in BROADCAST mode"
        forge_cmd+=" --broadcast"

        # Get private key for broadcast mode
        local private_key
        private_key=$(get_private_key)
        forge_cmd+=" --private-key '$private_key'"
    fi

    # Add verbosity
    forge_cmd+=" -vvvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    # Execute
    eval "$forge_cmd"
    local exit_code=$?

    log "INFO" ""
    if [ $exit_code -eq 0 ]; then
        log "INFO" "============================================"
        log "INFO" "SetGasInfo completed successfully!"
        log "INFO" "============================================"
    else
        log "ERROR" "============================================"
        log "ERROR" "SetGasInfo FAILED with exit code: $exit_code"
        log "ERROR" "============================================"
        exit $exit_code
    fi
}

main "$@"
