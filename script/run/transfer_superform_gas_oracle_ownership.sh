#!/usr/bin/env bash

###################################################################################
# Transfer SuperformGasOracle Ownership Script
###################################################################################
# Description:
#   Transfers SuperformGasOracle ownership from the deployer (v2-supervaults) to
#   SUPER_GOVERNOR_ADDRESS (0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e).
#
# Usage:
#   ./transfer_superform_gas_oracle_ownership.sh <environment> <mode> [account]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate", "execute", or "check"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#
# Examples:
#   # Check ownership status on Base staging
#   ./transfer_superform_gas_oracle_ownership.sh staging check
#
#   # Simulate transfer on Base staging
#   ./transfer_superform_gas_oracle_ownership.sh staging simulate
#
#   # Execute transfer on Base staging
#   ./transfer_superform_gas_oracle_ownership.sh staging execute v2-supervaults
#
#   # Execute transfer on Base prod
#   ./transfer_superform_gas_oracle_ownership.sh prod execute v2-supervaults
#
# Prerequisites:
#   - SuperformGasOracle must be deployed
#   - Current owner must be the deployer (v2-supervaults)
#   - For execute mode: Foundry account (v2-supervaults) configured
#
# Note:
#   - This script only operates on Base chain (ID: 8453)
#   - New owner: SUPER_GOVERNOR_ADDRESS (0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e)
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Current owner (v2-supervaults keystore - DEPLOYER)
readonly CURRENT_OWNER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

# New owner (SUPER_GOVERNOR_ADDRESS)
readonly NEW_OWNER="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

# Base chain only
readonly CHAIN_ID=8453
readonly CHAIN_NAME="base"

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
    mode         Mode: "simulate", "execute", or "check" (required)
    account      Account name (required for execute mode, e.g., "v2-supervaults")

Examples:
    # Check ownership status on Base staging
    $0 staging check

    # Simulate transfer on Base staging
    $0 staging simulate

    # Execute transfer on Base staging
    $0 staging execute v2-supervaults

    # Execute transfer on Base prod
    $0 prod execute v2-supervaults

Note:
  - This script only operates on Base chain (ID: 8453)
  - Transfers ownership to SUPER_GOVERNOR_ADDRESS ($NEW_OWNER)

EOF
    exit 1
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
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ] && [ "$mode" != "check" ]; then
        log "ERROR" "Invalid mode: $mode"
        log "ERROR" "Must be 'simulate', 'execute', or 'check'"
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

    # Validate inputs
    validate_environment "$environment"
    validate_mode "$mode"

    # Source network configuration
    source_network_config "$environment"

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
    case "$environment" in
        prod)
            env=0
            ;;
        staging)
            env=2
            ;;
    esac

    # Load RPC URLs from 1Password
    log "INFO" "Loading RPC URLs..."
    load_rpc_urls

    # Get RPC URL for Base (use BASE_MAINNET directly after load_rpc_urls)
    local rpc_url="${BASE_MAINNET:-}"
    if [ -z "$rpc_url" ]; then
        log "ERROR" "BASE_MAINNET RPC URL not loaded. Check 1Password configuration."
        exit 1
    fi

    log "INFO" "============================================"
    log "INFO" "Transfer SuperformGasOracle Ownership"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Chain: $CHAIN_NAME (ID: $CHAIN_ID)"
    log "INFO" "Mode: $mode"
    log "INFO" "Current Owner: $CURRENT_OWNER"
    log "INFO" "New Owner (SUPER_GOVERNOR_ADDRESS): $NEW_OWNER"
    log "INFO" "RPC URL: ${rpc_url:0:50}..."
    log "INFO" "============================================"

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" script/TransferSuperformGasOracleOwnership.s.sol:TransferSuperformGasOracleOwnership"

    if [ "$mode" = "check" ]; then
        # Check mode - just verify ownership status
        forge_cmd+=" --sig 'runCheck(uint256,uint64,address)' $env $CHAIN_ID $CURRENT_OWNER"
    else
        # Transfer mode (simulate or execute)
        forge_cmd+=" --sig 'run(uint256,uint64,address)' $env $CHAIN_ID $CURRENT_OWNER"
    fi

    forge_cmd+=" --rpc-url '$rpc_url'"

    # Set up forge flags based on mode
    if [ "$mode" = "execute" ]; then
        forge_cmd+=" --account $account --broadcast"
        log "INFO" "Mode: Execute (will broadcast transaction using account: $account)"
    elif [ "$mode" = "simulate" ]; then
        forge_cmd+=" --sender $CURRENT_OWNER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $CURRENT_OWNER)"
    else
        # Check mode
        log "INFO" "Mode: Check (read-only)"
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
        log "INFO" "Ownership transfer completed successfully!"
        log "INFO" "============================================"
    else
        log "ERROR" "============================================"
        log "ERROR" "Ownership transfer FAILED with exit code: $exit_code"
        log "ERROR" "============================================"
        exit $exit_code
    fi
}

main "$@"
