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
#   ./set_gas_info.sh <environment> <mode> [account]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate" or "execute"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#
# Examples:
#   # Simulate on mainnet staging
#   ./set_gas_info.sh staging simulate
#
#   # Execute on mainnet staging
#   ./set_gas_info.sh staging execute v2-supervaults
#
#   # Simulate on mainnet prod
#   ./set_gas_info.sh prod simulate
#
#   # Execute on mainnet prod
#   ./set_gas_info.sh prod execute v2-supervaults
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account with DEFAULT_ADMIN_ROLE on SuperGovernor
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
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
readonly CHAIN_ID=1  # Mainnet only

# Deployer address for simulation
readonly DEPLOYER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

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
Usage: $0 <environment> <mode> [account]

Arguments:
    environment  Environment: "prod" or "staging" (required)
    mode         Mode: "simulate" or "execute" (required)
    account      Account name (required for execute mode, e.g., "v2-supervaults")

Examples:
    # Simulate on mainnet staging
    $0 staging simulate

    # Execute on mainnet staging
    $0 staging execute v2-supervaults

    # Simulate on mainnet prod
    $0 prod simulate

    # Execute on mainnet prod
    $0 prod execute v2-supervaults

Note: This script only runs on mainnet (chain ID 1)
EOF
    exit 1
}

# Source network configuration based on environment
source_network_config() {
    local environment=$1
    local network_config_file

    if [ "$environment" = "staging" ]; then
        network_config_file="$SCRIPT_DIR/../utils/networks-staging.sh"
    else
        network_config_file="$SCRIPT_DIR/../utils/networks-production.sh"
    fi

    if [ ! -f "$network_config_file" ]; then
        log "ERROR" "Network config not found: $network_config_file"
        exit 1
    fi

    log "INFO" "Loading network configuration from: $network_config_file"
    source "$network_config_file"
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

# Validate mode parameter
validate_mode() {
    local mode=$1
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ]; then
        log "ERROR" "Invalid mode: $mode"
        log "ERROR" "Must be either 'simulate' or 'execute'"
        exit 1
    fi
}

###################################################################################
# Main
###################################################################################

main() {
    # Check minimum arguments
    if [ $# -lt 2 ]; then
        log "ERROR" "Missing required arguments"
        usage
    fi

    local environment="$1"
    local mode="$2"
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
    fi

    # Map environment to env number
    local env
    local salt
    case "$environment" in
        prod)
            env=0
            salt="PROD1.0.0"
            ;;
        staging)
            env=2
            salt="STAGING1.0.0"
            ;;
    esac

    # Load RPC URLs from 1Password
    log "INFO" "Loading RPC URLs..."
    load_rpc_urls

    # Get Ethereum RPC URL
    local rpc_url="${ETH_MAINNET:-}"
    if [ -z "$rpc_url" ]; then
        log "ERROR" "ETH_MAINNET RPC URL not loaded. Check 1Password configuration."
        exit 1
    fi

    log "INFO" "============================================"
    log "INFO" "SetGasInfo Script"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Chain ID: $CHAIN_ID (mainnet)"
    log "INFO" "Salt: $salt"
    log "INFO" "Mode: $mode"
    log "INFO" "RPC URL: ${rpc_url:0:50}..."
    log "INFO" "============================================"

    # Build forge command (use relative path from project root)
    local forge_cmd="forge script"
    forge_cmd+=" script/SetGasInfo.s.sol:SetGasInfo"
    forge_cmd+=" --sig 'run(uint256,uint64)' $env $CHAIN_ID"
    forge_cmd+=" --rpc-url '$rpc_url'"

    # Set up forge flags based on mode
    if [ "$mode" = "execute" ]; then
        # Execute mode: Use --account flag with --broadcast
        forge_cmd+=" --account $account --broadcast"
        log "INFO" "Mode: Execute (will broadcast transactions using account: $account)"
    else
        # Simulate mode: Use deployer address with --sender (no broadcast)
        forge_cmd+=" --sender $DEPLOYER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $DEPLOYER)"
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
