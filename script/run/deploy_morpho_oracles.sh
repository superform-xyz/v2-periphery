#!/usr/bin/env bash

###################################################################################
# Deploy Morpho Oracles Script
###################################################################################
#
# Deploys MorphoLendYieldSourceOracle and MorphoBorrowCostOracle on chains
# where Morpho Blue is deployed (Ethereum, Base, Optimism, Arbitrum, BNB).
#
# Usage:
#   ./deploy_morpho_oracles.sh <environment> <mode> [account]
#
# Parameters:
#   environment  "prod" or "staging"
#   mode         "simulate", "execute", or "check"
#   account      Account name for execute mode (e.g., "v2-supervaults")
#
# Examples:
#   ./deploy_morpho_oracles.sh staging check
#   ./deploy_morpho_oracles.sh staging simulate
#   ./deploy_morpho_oracles.sh staging execute v2-supervaults
#   ./deploy_morpho_oracles.sh prod execute v2-supervaults
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account (v2-supervaults) configured
#
# Notes:
#   - Already-deployed chains are skipped automatically
#   - Admin (DEFAULT_ADMIN_ROLE + MANAGER_ROLE) is set to the deployer
#
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Deployer address (v2-supervaults keystore - DEPLOYER)
readonly DEPLOYER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

# Supported chains where Morpho Blue is deployed: "CHAIN_ID:CHAIN_NAME"
readonly SUPPORTED_CHAINS=(
    "1:Ethereum"
    "8453:Base"
)

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
    # Check deployment status on all chains
    $0 staging check

    # Simulate deployment on all chains
    $0 staging simulate

    # Execute deployment on all chains
    $0 staging execute v2-supervaults

    # Execute deployment on prod
    $0 prod execute v2-supervaults

Note: Deploys on Ethereum (1) and Base (8453). Already-deployed chains are skipped.

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

# Get RPC URL for a given chain ID
get_chain_rpc_url() {
    local chain_id=$1
    case "$chain_id" in
        1)
            echo "${ETH_MAINNET:-}"
            ;;
        8453)
            echo "${BASE_MAINNET:-}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Deploy on a single chain
deploy_on_chain() {
    local env=$1
    local chain_id=$2
    local chain_name=$3
    local mode=$4
    local account=$5
    local rpc_url=$6

    log "INFO" "--------------------------------------------"
    log "INFO" "Deploying on chain: $chain_name (ID: $chain_id)"
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
        SENDER_FLAG="--sender $DEPLOYER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $DEPLOYER)"
    else
        log "INFO" "Mode: Check (read-only)"
    fi

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" script/DeployMorphoOracles.s.sol:DeployMorphoOracles"

    if [ "$mode" = "check" ]; then
        forge_cmd+=" --sig 'runCheck(uint256,uint64)' $env $chain_id"
    else
        forge_cmd+=" --sig 'run(uint256,uint64)' $env $chain_id"
    fi

    forge_cmd+=" --rpc-url '$rpc_url'"
    forge_cmd+=" --chain $chain_id"
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
        log "ERROR" "Deployment failed on $chain_name ($chain_id) with exit code: $exit_code"
        return $exit_code
    fi

    log "INFO" "$chain_name ($chain_id) deployment successful"
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
            log "WARN" "Failed to load Etherscan API key. Verification will not work."
        fi
    fi

    log "INFO" "============================================"
    log "INFO" "Deploy Morpho Oracles"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    log "INFO" "Deployer (admin): $DEPLOYER"
    log "INFO" "Contracts: MorphoLendYieldSourceOracle, MorphoBorrowCostOracle"
    log "INFO" "Target Chains: Ethereum (1), Base (8453)"
    log "INFO" "============================================"

    local successful_chains=()
    local skipped_chains=()
    local failed_chains=()

    # Deploy on each supported chain
    for chain_def in "${SUPPORTED_CHAINS[@]}"; do
        IFS=':' read -r chain_id chain_name <<< "$chain_def"

        # Get RPC URL for this chain
        local rpc_url
        rpc_url=$(get_chain_rpc_url "$chain_id")

        if [ -z "$rpc_url" ]; then
            log "WARN" "Skipping $chain_name ($chain_id) - RPC URL not available"
            skipped_chains+=("$chain_name ($chain_id)")
            continue
        fi

        if deploy_on_chain "$env" "$chain_id" "$chain_name" "$mode" "$account" "$rpc_url"; then
            successful_chains+=("$chain_name ($chain_id)")
        else
            failed_chains+=("$chain_name ($chain_id)")
        fi

        log "INFO" ""
    done

    # Summary
    log "INFO" ""
    log "INFO" "============================================"
    log "INFO" "Deployment Summary"
    log "INFO" "============================================"

    if [ ${#successful_chains[@]} -gt 0 ]; then
        log "INFO" "Deployed:"
        for chain in "${successful_chains[@]}"; do
            log "INFO" "  + $chain"
        done
    fi

    if [ ${#skipped_chains[@]} -gt 0 ]; then
        log "INFO" "Skipped:"
        for chain in "${skipped_chains[@]}"; do
            log "INFO" "  - $chain"
        done
    fi

    if [ ${#failed_chains[@]} -gt 0 ]; then
        log "WARN" "Failed:"
        for chain in "${failed_chains[@]}"; do
            log "WARN" "  x $chain"
        done
    fi

    log "INFO" "============================================"

    if [ ${#failed_chains[@]} -gt 0 ]; then
        log "ERROR" "Deployment completed with failures"
        exit 1
    fi

    log "INFO" "Deployment completed successfully!"
}

main "$@"
