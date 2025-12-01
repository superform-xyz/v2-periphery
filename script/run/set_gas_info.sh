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
#   ./set_gas_info.sh <environment> [simulate]
#
#   Parameters:
#     environment  Environment: "production" or "staging" (required)
#     simulate     Optional: add "simulate" to run without broadcasting
#
# Examples:
#   # Simulate on mainnet staging
#   ./set_gas_info.sh staging simulate
#
#   # Execute on mainnet staging
#   ./set_gas_info.sh staging
#
#   # Simulate on mainnet production
#   ./set_gas_info.sh production simulate
#
#   # Execute on mainnet production
#   ./set_gas_info.sh production
#
# Prerequisites:
#   - ETH_RPC_URL environment variable set
#   - ETH_PRIVATE_KEY environment variable set (or use 1Password)
#   - Deployer must have DEFAULT_ADMIN_ROLE on SuperGovernor
#
# Note:
#   - This script only runs on mainnet (chain ID 1)
#   - Salt namespace is fixed based on environment:
#     - Production: PROD1.0.0
#     - Staging: STAGING1.0.0
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly CHAIN_ID=1  # Mainnet only

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
Usage: $0 <environment> [simulate]

Arguments:
    environment  Environment: "production" or "staging" (required)
    simulate     Optional: add "simulate" to run without broadcasting

Examples:
    # Simulate on mainnet staging
    $0 staging simulate

    # Execute on mainnet staging
    $0 staging

    # Simulate on mainnet production
    $0 production simulate

    # Execute on mainnet production
    $0 production

Note: This script only runs on mainnet (chain ID 1)
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
    if [ -n "${ETH_RPC_URL:-}" ]; then
        echo "$ETH_RPC_URL"
        return 0
    fi

    log "ERROR" "No RPC URL found. Set ETH_RPC_URL environment variable"
    exit 1
}

###################################################################################
# Main
###################################################################################

main() {
    # Check minimum arguments
    if [ $# -lt 1 ]; then
        log "ERROR" "Missing required argument: environment"
        usage
    fi

    local environment="$1"
    local simulate=false

    # Check for simulate flag
    if [ $# -ge 2 ] && [ "$2" = "simulate" ]; then
        simulate=true
    fi

    # Map environment to env number
    local env
    local salt
    case "$environment" in
        production|prod)
            env=0
            salt="PROD1.0.0"
            ;;
        staging)
            env=2
            salt="STAGING1.0.0"
            ;;
        *)
            log "ERROR" "Invalid environment: $environment. Must be 'production' or 'staging'"
            usage
            ;;
    esac

    # Get RPC URL
    local rpc_url
    rpc_url=$(get_rpc_url)

    log "INFO" "============================================"
    log "INFO" "SetGasInfo Script"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Chain ID: $CHAIN_ID (mainnet)"
    log "INFO" "Salt: $salt"
    log "INFO" "Simulate: $simulate"
    log "INFO" "RPC URL: ${rpc_url:0:50}..."
    log "INFO" "============================================"

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" ${PROJECT_ROOT}/script/SetGasInfo.s.sol:SetGasInfo"
    forge_cmd+=" --sig 'run(uint256,uint64)' $env $CHAIN_ID"
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
