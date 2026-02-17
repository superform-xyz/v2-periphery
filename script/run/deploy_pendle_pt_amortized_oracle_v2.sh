#!/usr/bin/env bash

###################################################################################
# Deploy PendlePTAmortizedOracleV2 Script
###################################################################################
# Description:
#   Deploys PendlePTAmortizedOracleV2 - an amortized cost pricing oracle for
#   Pendle PT positions with on-chain PT rate calculation.
#
#   V2 Key Differences from V1:
#   - recordPurchase calculates sySpent from on-chain PT rate (no off-chain dependency)
#   - twapDuration passed per-call via hook (no market config storage)
#
# Usage:
#   ./deploy_pendle_pt_amortized_oracle_v2.sh <environment> <mode> [account] [chain_id]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate", "execute", or "check"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#     chain_id: Optional chain ID (default: deploys on all supported chains)
#
# Examples:
#   # Check deployment status on all staging chains
#   ./deploy_pendle_pt_amortized_oracle_v2.sh staging check
#
#   # Check deployment status on specific chain
#   ./deploy_pendle_pt_amortized_oracle_v2.sh staging check "" 1
#
#   # Simulate deployment on all staging chains
#   ./deploy_pendle_pt_amortized_oracle_v2.sh staging simulate
#
#   # Simulate deployment on specific chain
#   ./deploy_pendle_pt_amortized_oracle_v2.sh staging simulate "" 8453
#
#   # Execute deployment on all staging chains
#   ./deploy_pendle_pt_amortized_oracle_v2.sh staging execute v2-supervaults
#
#   # Execute deployment on specific chain
#   ./deploy_pendle_pt_amortized_oracle_v2.sh staging execute v2-supervaults 1
#
#   # Execute deployment on all prod chains
#   ./deploy_pendle_pt_amortized_oracle_v2.sh prod execute v2-supervaults
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account (v2-supervaults) configured
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Admin address (DEPLOYER) - used for --sender in simulate mode
# Roles will be transferred to SUPER_GOVERNOR_ADDRESS later using transfer script
readonly ADMIN="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

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
    chain_id     Optional chain ID to deploy on a specific chain

Examples:
    # Check deployment status on all staging chains
    $0 staging check

    # Check deployment status on specific chain
    $0 staging check "" 1

    # Simulate deployment on all staging chains
    $0 staging simulate

    # Simulate deployment on specific chain
    $0 staging simulate "" 8453

    # Execute deployment on all staging chains
    $0 staging execute v2-supervaults

    # Execute deployment on specific chain
    $0 staging execute v2-supervaults 1

    # Execute deployment on all prod chains
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

# Get chain name from chain ID
get_chain_name() {
    local chain_id=$1
    case "$chain_id" in
        1) echo "Ethereum" ;;
        8453) echo "Base" ;;
        10) echo "Optimism" ;;
        42161) echo "Arbitrum" ;;
        56) echo "BNB" ;;
        999) echo "HyperEVM" ;;
        137) echo "Polygon" ;;
        43114) echo "Avalanche" ;;
        80094) echo "Berachain" ;;
        146) echo "Sonic" ;;
        100) echo "Gnosis" ;;
        130) echo "Unichain" ;;
        480) echo "Worldchain" ;;
        *) echo "Unknown" ;;
    esac
}

# Update JSON file with deployed address
update_json_output() {
    local env=$1
    local chain_id=$2
    local address=$3
    local environment=$4

    local chain_name
    chain_name=$(get_chain_name "$chain_id")

    local env_folder
    if [ "$environment" = "prod" ]; then
        env_folder="prod"
    else
        env_folder="staging"
    fi

    local output_dir="$PROJECT_ROOT/script/output/$env_folder/$chain_id"
    local output_file="$output_dir/${chain_name}-latest.json"

    # Create directory if it doesn't exist
    mkdir -p "$output_dir"

    # Create or update JSON file
    if [ -f "$output_file" ] && [ -s "$output_file" ]; then
        # Update existing file - check if it's valid JSON first
        if jq empty "$output_file" 2>/dev/null; then
            local tmp_file=$(mktemp)
            if jq --arg addr "$address" '.PendlePTAmortizedOracleV2 = $addr' "$output_file" > "$tmp_file" 2>/dev/null; then
                mv "$tmp_file" "$output_file"
                log "INFO" "Updated existing JSON: $output_file"
            else
                rm -f "$tmp_file"
                log "ERROR" "Failed to update JSON file"
                return 1
            fi
        else
            log "WARN" "Existing file is not valid JSON, creating new file"
            echo "{\"PendlePTAmortizedOracleV2\": \"$address\"}" > "$output_file"
            log "INFO" "Created new JSON: $output_file"
        fi
    else
        # Create new file
        echo "{\"PendlePTAmortizedOracleV2\": \"$address\"}" > "$output_file"
        log "INFO" "Created new JSON: $output_file"
    fi
}

# Deploy on a single chain
deploy_on_chain() {
    local env=$1
    local chain_id=$2
    local mode=$3
    local account=$4
    local rpc_url=$5
    local environment=$6

    log "INFO" "--------------------------------------------"
    log "INFO" "Deploying on chain: $chain_id"
    log "INFO" "--------------------------------------------"

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
        SENDER_FLAG="--sender $ADMIN"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $ADMIN)"
    else
        log "INFO" "Mode: Check (read-only)"
    fi

    # Build forge command - V2 script
    local forge_cmd="forge script"
    forge_cmd+=" script/DeployPendlePTAmortizedOracleV2.s.sol:DeployPendlePTAmortizedOracleV2"

    if [ "$mode" = "check" ]; then
        # Pass empty string for branchName (only used for vnet env=1)
        forge_cmd+=" --sig 'runCheck(uint256,uint64,string)' $env $chain_id \"\""
    else
        # Pass empty string for branchName (only used for vnet env=1)
        forge_cmd+=" --sig 'run(uint256,uint64,string)' $env $chain_id \"\""
    fi

    forge_cmd+=" --rpc-url $rpc_url"
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

    # Execute and capture output (capture exit code to prevent set -e from exiting)
    local exit_code=0
    local output
    output=$(eval "$forge_cmd" 2>&1) || exit_code=$?

    # Print output
    echo "$output"

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Deployment failed on chain $chain_id with exit code: $exit_code"
        return $exit_code
    fi

    # Extract deployed address from output and update JSON (for simulate and execute modes)
    if [ "$mode" != "check" ]; then
        local deployed_address
        # Extract the 0x address that appears after "PendlePTAmortizedOracleV2 deployed at:"
        # Use grep to find the line, then grep again to extract just the address
        deployed_address=$(echo "$output" | grep 'PendlePTAmortizedOracleV2 deployed at:' | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)

        if [ -n "$deployed_address" ] && [[ "$deployed_address" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
            log "INFO" "Extracted deployed address: $deployed_address"
            update_json_output "$env" "$chain_id" "$deployed_address" "$environment"
        else
            log "WARN" "Could not extract deployed address from output"
        fi
    fi

    log "INFO" "Chain $chain_id deployment successful"
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

    # Load Etherscan API key for verification
    if [ "$mode" = "execute" ]; then
        log "INFO" "Loading Etherscan API credentials..."
        if ! load_etherscan_api_key; then
            log "ERROR" "Failed to load Etherscan API key. Verification will not work."
            exit 1
        fi
    fi

    log "INFO" "============================================"
    log "INFO" "Deploy PendlePTAmortizedOracleV2"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    log "INFO" "Admin (DEPLOYER): $ADMIN"
    if [ -n "$specific_chain" ]; then
        log "INFO" "Target Chain: $specific_chain"
    else
        log "INFO" "Target Chains: All supported chains"
    fi
    log "INFO" "============================================"
    log "INFO" "V2 Features:"
    log "INFO" "  - On-chain PT rate calculation (no off-chain dependency)"
    log "INFO" "  - twapDuration passed per-call via hook"
    log "INFO" "  - MIN_TWAP_DURATION protection (default 300s, configurable per market)"
    log "INFO" "============================================"

    local failed_chains=()
    local success_count=0

    # Get chains to deploy on
    local chains_to_deploy
    if [ -n "$specific_chain" ]; then
        chains_to_deploy=("$specific_chain")
    else
        # Get all supported networks from the config
        mapfile -t chains_to_deploy < <(get_supported_networks)
    fi

    # Deploy on each chain
    for chain_id in "${chains_to_deploy[@]}"; do
        # Get RPC URL for this chain
        local rpc_url
        rpc_url=$(get_rpc_url "$chain_id")

        if [ -z "$rpc_url" ]; then
            log "WARN" "Skipping chain $chain_id - RPC URL not available"
            failed_chains+=("$chain_id")
            continue
        fi

        if deploy_on_chain "$env" "$chain_id" "$mode" "$account" "$rpc_url" "$environment"; then
            ((++success_count))
        else
            failed_chains+=("$chain_id")
        fi

        log "INFO" ""
    done

    # Summary
    log "INFO" "============================================"
    log "INFO" "Deployment Summary"
    log "INFO" "============================================"
    log "INFO" "Successful: $success_count"
    log "INFO" "Failed: ${#failed_chains[@]}"

    if [ ${#failed_chains[@]} -gt 0 ]; then
        log "WARN" "Failed chains: ${failed_chains[*]}"
        exit 1
    fi

    log "INFO" "============================================"
    log "INFO" "PendlePTAmortizedOracleV2 deployment completed successfully!"
    log "INFO" "============================================"
}

main "$@"
