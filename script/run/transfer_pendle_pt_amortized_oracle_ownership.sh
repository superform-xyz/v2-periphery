#!/usr/bin/env bash

###################################################################################
# Transfer PendlePTAmortizedOracle Ownership Script
###################################################################################
# Description:
#   Transfers all roles (DEFAULT_ADMIN_ROLE, MANAGER_ROLE, KEEPER_ROLE) from
#   DEPLOYER to SUPER_GOVERNOR_ADDRESS for PendlePTAmortizedOracle.
#
# Usage:
#   ./transfer_pendle_pt_amortized_oracle_ownership.sh <environment> <mode> [account] [chain_id]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate", "execute", or "check"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#     chain_id: Optional chain ID (default: transfers on all supported chains)
#
# Examples:
#   # Check role status on all staging chains
#   ./transfer_pendle_pt_amortized_oracle_ownership.sh staging check
#
#   # Check role status on specific chain
#   ./transfer_pendle_pt_amortized_oracle_ownership.sh staging check "" 1
#
#   # Simulate transfer on all staging chains
#   ./transfer_pendle_pt_amortized_oracle_ownership.sh staging simulate
#
#   # Execute transfer on specific chain
#   ./transfer_pendle_pt_amortized_oracle_ownership.sh staging execute v2-supervaults 1
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account (v2-supervaults) configured
#   - Oracle must be deployed first using deploy_pendle_pt_amortized_oracle.sh
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# DEPLOYER address - used for --sender in simulate mode
readonly DEPLOYER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

# SUPER_GOVERNOR_ADDRESS - target for role transfer
readonly SUPER_GOVERNOR="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

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
Usage: $0 <environment> <mode> [account] [chain_id]

Arguments:
    environment  Environment: "prod" or "staging" (required)
    mode         Mode: "simulate", "execute", or "check" (required)
    account      Account name (required for execute mode, e.g., "v2-supervaults")
    chain_id     Optional chain ID to transfer on a specific chain

Examples:
    # Check role status on all staging chains
    $0 staging check

    # Check role status on specific chain
    $0 staging check "" 1

    # Simulate transfer on all staging chains
    $0 staging simulate

    # Execute transfer on specific chain
    $0 staging execute v2-supervaults 1

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

# Transfer on a single chain
transfer_on_chain() {
    local env=$1
    local chain_id=$2
    local mode=$3
    local account=$4
    local rpc_url=$5

    log "INFO" "--------------------------------------------"
    log "INFO" "Transferring on chain: $chain_id"
    log "INFO" "--------------------------------------------"

    # Set flags based on mode
    local BROADCAST_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        ACCOUNT_FLAG="--account $account"
        log "INFO" "Mode: Execute (will broadcast using account: $account)"
    elif [ "$mode" = "simulate" ]; then
        SENDER_FLAG="--sender $DEPLOYER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $DEPLOYER)"
    else
        log "INFO" "Mode: Check (read-only)"
    fi

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" script/TransferPendlePTAmortizedOracleOwnership.s.sol:TransferPendlePTAmortizedOracleOwnership"

    if [ "$mode" = "check" ]; then
        forge_cmd+=" --sig 'runCheck(uint256,uint64)' $env $chain_id"
    else
        forge_cmd+=" --sig 'run(uint256,uint64)' $env $chain_id"
    fi

    forge_cmd+=" --rpc-url $rpc_url"
    forge_cmd+=" --chain $chain_id"
    [ -n "$ACCOUNT_FLAG" ] && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ] && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ] && forge_cmd+=" $BROADCAST_FLAG"

    # Add verbosity
    forge_cmd+=" -vvvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    # Execute (capture exit code to prevent set -e from exiting)
    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Transfer failed on chain $chain_id with exit code: $exit_code"
        return $exit_code
    fi

    log "INFO" "Chain $chain_id transfer successful"
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
    local specific_chain="${4:-}"

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

    log "INFO" "============================================"
    log "INFO" "Transfer PendlePTAmortizedOracle Ownership"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    log "INFO" "From (DEPLOYER): $DEPLOYER"
    log "INFO" "To (SUPER_GOVERNOR): $SUPER_GOVERNOR"
    if [ -n "$specific_chain" ]; then
        log "INFO" "Target Chain: $specific_chain"
    else
        log "INFO" "Target Chains: All supported chains"
    fi
    log "INFO" "============================================"

    local failed_chains=()
    local success_count=0

    # Get chains to transfer on
    local chains_to_transfer
    if [ -n "$specific_chain" ]; then
        chains_to_transfer=("$specific_chain")
    else
        # Get all supported networks from the config
        mapfile -t chains_to_transfer < <(get_supported_networks)
    fi

    # Transfer on each chain
    for chain_id in "${chains_to_transfer[@]}"; do
        # Get RPC URL for this chain
        local rpc_url
        rpc_url=$(get_rpc_url "$chain_id")

        if [ -z "$rpc_url" ]; then
            log "WARN" "Skipping chain $chain_id - RPC URL not available"
            failed_chains+=("$chain_id")
            continue
        fi

        if transfer_on_chain "$env" "$chain_id" "$mode" "$account" "$rpc_url"; then
            ((++success_count))
        else
            failed_chains+=("$chain_id")
        fi

        log "INFO" ""
    done

    # Summary
    log "INFO" "============================================"
    log "INFO" "Transfer Summary"
    log "INFO" "============================================"
    log "INFO" "Successful: $success_count"
    log "INFO" "Failed: ${#failed_chains[@]}"

    if [ ${#failed_chains[@]} -gt 0 ]; then
        log "WARN" "Failed chains: ${failed_chains[*]}"
        exit 1
    fi

    log "INFO" "============================================"
    log "INFO" "PendlePTAmortizedOracle ownership transfer completed successfully!"
    log "INFO" "============================================"
}

main "$@"
