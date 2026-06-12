#!/usr/bin/env bash

###################################################################################
# Deploy ValidatorBonding Script
###################################################################################
# Description:
#   Deploys ValidatorBonding - sUP bonding module for Superform validators.
#   Base-only deployment (no cross-chain at launch).
#
# Usage:
#   ./deploy_validator_bonding.sh <environment> <mode> [account]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate", "execute", or "check"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#
# Examples:
#   # Check deployment status on Base
#   ./deploy_validator_bonding.sh staging check
#
#   # Simulate deployment on Base
#   ./deploy_validator_bonding.sh staging simulate
#
#   # Execute deployment on Base
#   ./deploy_validator_bonding.sh staging execute v2-supervaults
#
#   # Execute deployment on Base (production)
#   ./deploy_validator_bonding.sh prod execute v2-supervaults
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account (v2-supervaults) configured
#   - SuperGovernor must already be deployed on Base
#   - sUP SuperVault must be deployed on Base
#   - Locked bytecode must be generated (run regenerate_bytecode.sh first)
#
# Post-Deployment Steps:
#   1. Operators bond sUP via ValidatorBonding.bond()
#   2. Governor adds bonded operators to validator config via
#      SuperGovernor.setValidatorConfig()
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Admin address (SUPER_GOVERNOR_ADDRESS) - used for --sender in simulate mode
readonly ADMIN="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

# Base chain ID (ValidatorBonding is Base-only)
readonly BASE_CHAIN_ID="8453"

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
    # Check deployment status on Base
    $0 staging check

    # Simulate deployment on Base
    $0 staging simulate

    # Execute deployment on Base
    $0 staging execute v2-supervaults

    # Execute deployment on Base (production)
    $0 prod execute v2-supervaults

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

# Deploy on Base
deploy_on_base() {
    local env=$1
    local mode=$2
    local account=$3
    local rpc_url=$4

    log "INFO" "--------------------------------------------"
    log "INFO" "Deploying ValidatorBonding on Base (chain $BASE_CHAIN_ID)"
    log "INFO" "--------------------------------------------"

    # Set flags based on mode
    local BROADCAST_FLAG=""
    local VERIFY_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""
    local ETHERSCAN_FLAGS=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        ACCOUNT_FLAG="--account $account"
        VERIFY_FLAG="--verify"
        ETHERSCAN_FLAGS="--etherscan-api-key $ETHERSCANV2_API_KEY --verifier etherscan"
        log "INFO" "Mode: Execute (will broadcast using account: $account)"
    elif [ "$mode" = "simulate" ]; then
        SENDER_FLAG="--sender $ADMIN"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $ADMIN)"
    else
        log "INFO" "Mode: Check (read-only)"
    fi

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" script/DeployValidatorBonding.s.sol:DeployValidatorBonding"

    if [ "$mode" = "check" ]; then
        forge_cmd+=" --sig 'runCheck(uint256,string)' $env \"\""
    else
        forge_cmd+=" --sig 'run(uint256,string)' $env \"\""
    fi

    forge_cmd+=" --rpc-url $rpc_url"
    forge_cmd+=" --chain $BASE_CHAIN_ID"
    [ -n "$ACCOUNT_FLAG" ] && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ] && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ] && forge_cmd+=" $BROADCAST_FLAG"
    [ -n "$VERIFY_FLAG" ] && forge_cmd+=" $VERIFY_FLAG"
    [ -n "$ETHERSCAN_FLAGS" ] && forge_cmd+=" $ETHERSCAN_FLAGS"

    # Add verbosity
    forge_cmd+=" -vvvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    # Execute (capture exit code to prevent set -e from exiting)
    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Deployment failed on Base with exit code: $exit_code"
        return $exit_code
    fi

    log "INFO" "Base deployment successful"
    return 0
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

    # Satisfy foundry.toml [etherscan] env var references
    export ETHERSCANV2_API_KEY_TEST="${ETHERSCANV2_API_KEY_TEST:-}"

    # Load Etherscan API key for verification
    if [ "$mode" = "execute" ]; then
        log "INFO" "Loading Etherscan API credentials..."
        if ! load_etherscan_api_key; then
            log "ERROR" "Failed to load Etherscan API key. Verification will not work."
            exit 1
        fi
    fi

    log "INFO" "============================================"
    log "INFO" "Deploy ValidatorBonding (Base-only)"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    log "INFO" "Admin: $ADMIN (SUPER_GOVERNOR_ADDRESS)"
    log "INFO" "Target Chain: Base ($BASE_CHAIN_ID)"
    log "INFO" "============================================"

    # Get Base RPC URL
    local rpc_url
    rpc_url=$(get_rpc_url "$BASE_CHAIN_ID")

    if [ -z "$rpc_url" ]; then
        log "ERROR" "Base RPC URL not available"
        exit 1
    fi

    if deploy_on_base "$env" "$mode" "$account" "$rpc_url"; then
        log "INFO" "============================================"
        log "INFO" "ValidatorBonding deployment completed successfully!"
        log "INFO" "============================================"
    else
        log "ERROR" "ValidatorBonding deployment failed!"
        exit 1
    fi
}

main "$@"
