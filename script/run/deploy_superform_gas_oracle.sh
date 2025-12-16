#!/usr/bin/env bash

###################################################################################
# Deploy SuperformGasOracle Script
###################################################################################
# Description:
#   Deploys SuperformGasOracle - a keeper-updated gas price oracle for Base chain
#   where Chainlink's Fast Gas feed is not available.
#
# Usage:
#   ./deploy_superform_gas_oracle.sh <environment> <mode> [account] [gas_price]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate", "execute", or "check"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#     gas_price: Initial gas price in Gwei (optional, default: 30)
#
# Examples:
#   # Check deployment status on Base staging
#   ./deploy_superform_gas_oracle.sh staging check
#
#   # Simulate deployment on Base staging
#   ./deploy_superform_gas_oracle.sh staging simulate
#
#   # Execute deployment on Base staging
#   ./deploy_superform_gas_oracle.sh staging execute v2-supervaults
#
#   # Execute deployment on Base prod
#   ./deploy_superform_gas_oracle.sh prod execute v2-supervaults
#
#   # Execute with custom gas price (50 Gwei)
#   ./deploy_superform_gas_oracle.sh staging execute v2-supervaults 50
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account (v2-supervaults) configured
#
# Note:
#   - This script only deploys on Base chain (ID: 8453)
#   - Owner is set to v2-supervaults keystore address
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default gas price with 9 decimals (1000000 = 0.001 Gwei - realistic for Base)
# Examples: 0.001 Gwei = 1000000, 0.04 Gwei = 40000000, 1 Gwei = 1000000000
readonly DEFAULT_GAS_PRICE=1000000

# Owner address (v2-supervaults keystore - DEPLOYER)
readonly OWNER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

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
Usage: $0 <environment> <mode> [account] [gas_price]

Arguments:
    environment  Environment: "prod" or "staging" (required)
    mode         Mode: "simulate", "execute", or "check" (required)
    account      Account name (required for execute mode, e.g., "v2-supervaults")
    gas_price    Initial gas price in Gwei (optional, default: $DEFAULT_GAS_PRICE)

Examples:
    # Check deployment status on Base staging
    $0 staging check

    # Simulate deployment on Base staging
    $0 staging simulate

    # Execute deployment on Base staging
    $0 staging execute v2-supervaults

    # Execute deployment on Base prod
    $0 prod execute v2-supervaults

    # Execute with custom gas price (50 Gwei)
    $0 staging execute v2-supervaults 50

Note: This script deploys only on Base chain (ID: 8453)

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
    local gas_price="${4:-$DEFAULT_GAS_PRICE}"

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

    # Load Etherscan API key for verification
    if [ "$mode" = "execute" ]; then
        log "INFO" "Loading Etherscan API credentials..."
        if ! load_etherscan_api_key; then
            log "ERROR" "Failed to load Etherscan API key. Verification will not work."
            exit 1
        fi
    fi

    log "INFO" "============================================"
    log "INFO" "Deploy SuperformGasOracle"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Chain: $CHAIN_NAME (ID: $CHAIN_ID)"
    log "INFO" "Mode: $mode"
    log "INFO" "Owner (v2-supervaults): $OWNER"
    log "INFO" "Initial Gas Price: $gas_price (9 decimals, 1000000 = 0.001 Gwei)"
    log "INFO" "RPC URL: ${rpc_url:0:50}..."
    log "INFO" "============================================"

    # Set flags based on mode
    local BROADCAST_FLAG=""
    local VERIFY_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""
    local ETHERSCAN_FLAGS=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        VERIFY_FLAG="--verify"
        ACCOUNT_FLAG="--account $account"
        ETHERSCAN_FLAGS="--etherscan-api-key $ETHERSCANV2_API_KEY --verifier etherscan"
        log "INFO" "Mode: Execute (will broadcast and verify using account: $account)"
    elif [ "$mode" = "simulate" ]; then
        SENDER_FLAG="--sender $OWNER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $OWNER)"
    else
        # Check mode
        log "INFO" "Mode: Check (read-only)"
    fi

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" script/DeploySuperformGasOracle.s.sol:DeploySuperformGasOracle"

    if [ "$mode" = "check" ]; then
        # Check mode - just verify deployment status
        forge_cmd+=" --sig 'runCheck(uint256,uint64,address)' $env $CHAIN_ID $OWNER"
    else
        # Deploy mode (simulate or execute)
        forge_cmd+=" --sig 'run(uint256,uint64,int256,address)' $env $CHAIN_ID $gas_price $OWNER"
    fi

    forge_cmd+=" --rpc-url '$rpc_url'"
    forge_cmd+=" --chain $CHAIN_ID"
    [ -n "$ACCOUNT_FLAG" ] && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ] && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ] && forge_cmd+=" $BROADCAST_FLAG"
    [ -n "$VERIFY_FLAG" ] && forge_cmd+=" $VERIFY_FLAG"
    [ -n "$ETHERSCAN_FLAGS" ] && forge_cmd+=" $ETHERSCAN_FLAGS"

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
        log "INFO" "SuperformGasOracle deployment completed successfully!"
        log "INFO" "============================================"
    else
        log "ERROR" "============================================"
        log "ERROR" "SuperformGasOracle deployment FAILED with exit code: $exit_code"
        log "ERROR" "============================================"
        exit $exit_code
    fi
}

main "$@"
