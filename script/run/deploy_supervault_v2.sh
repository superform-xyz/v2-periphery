#!/usr/bin/env bash

###################################################################################
# Deploy SuperVault V2 Script
###################################################################################
# Description:
#   Deploys the SuperVault V2 implementation suite:
#     - SuperVaultV2          (vault, uses AssetMetadataLibV2 for B20 precompile support)
#     - SuperVaultStrategyV2  (strategy, adds ERC721/ERC1155/ERC1271/ERC165 receivers)
#     - SuperVaultEscrow      (escrow impl under V2 salt, same bytecode as V1)
#     - SuperVaultAggregatorV2 (registry/PPS oracle pointing at V2 implementations)
#
#   The script does NOT update SuperGovernor to point to the V2 aggregator.
#   That is a separate governance action performed after verifying the deployment.
#
# Usage:
#   ./deploy_supervault_v2.sh <environment> <mode> [account] [chain_id]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode:        "simulate", "execute", or "check"
#     account:     Foundry keystore account name (required for execute mode)
#     chain_id:    Optional — deploy on one chain only (default: all supported chains)
#
# Examples:
#   # Check deployment status on all staging chains
#   ./deploy_supervault_v2.sh staging check
#
#   # Check on a single chain
#   ./deploy_supervault_v2.sh staging check "" 8453
#
#   # Simulate on all staging chains
#   ./deploy_supervault_v2.sh staging simulate
#
#   # Execute on staging (all chains)
#   ./deploy_supervault_v2.sh staging execute v2-supervaults
#
#   # Execute on a single staging chain
#   ./deploy_supervault_v2.sh staging execute v2-supervaults 8453
#
#   # Execute on production (all chains)
#   ./deploy_supervault_v2.sh prod execute v2-supervaults
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry keystore account (v2-supervaults) configured
#   - SuperGovernor must be deployed on target chains
#   - Locked bytecode must be generated for V2 contracts:
#       SuperVaultV2.json, SuperVaultStrategyV2.json,
#       SuperVaultEscrowV2.json (or SuperVaultEscrow.json), SuperVaultAggregatorV2.json
#       Run: ./regenerate_bytecode.sh  (or copy V1 escrow artifact as SuperVaultEscrowV2)
#
# Post-Deployment Steps:
#   1. Verify output in script/output/<env>/<chainId>/<ChainName>-latest.json
#      (keys: SuperVaultV2, SuperVaultStrategyV2, SuperVaultEscrowV2, SuperVaultAggregatorV2)
#   2. Register V2 aggregator with SuperGovernor via governance action:
#        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, <SuperVaultAggregatorV2 address>)
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Admin address (SUPER_GOVERNOR_ADDRESS) — used as --sender in simulate mode
readonly ADMIN="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

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
    environment  "prod" or "staging"
    mode         "simulate", "execute", or "check"
    account      Foundry keystore account name (required for execute mode)
    chain_id     Optional chain ID to deploy on a single chain

Examples:
    $0 staging check
    $0 staging check "" 8453
    $0 staging simulate
    $0 staging simulate "" 8453
    $0 staging execute v2-supervaults
    $0 staging execute v2-supervaults 8453
    $0 prod execute v2-supervaults

EOF
    exit 1
}

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

validate_environment() {
    local environment=$1
    if [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; then
        log "ERROR" "Invalid environment: $environment. Must be 'staging' or 'prod'"
        exit 1
    fi
}

validate_mode() {
    local mode=$1
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ] && [ "$mode" != "check" ]; then
        log "ERROR" "Invalid mode: $mode. Must be 'simulate', 'execute', or 'check'"
        exit 1
    fi
}

deploy_on_chain() {
    local env=$1
    local chain_id=$2
    local mode=$3
    local account=$4
    local rpc_url=$5

    log "INFO" "--------------------------------------------"
    log "INFO" "Chain: $chain_id | Mode: $mode"
    log "INFO" "--------------------------------------------"

    local BROADCAST_FLAG=""
    local VERIFY_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""
    local ETHERSCAN_FLAGS=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        ACCOUNT_FLAG="--account $account"
        # HyperEVM (999) and Flare (14) have no Etherscan support
        if [ "$chain_id" != "999" ] && [ "$chain_id" != "14" ]; then
            VERIFY_FLAG="--verify"
            ETHERSCAN_FLAGS="--etherscan-api-key $ETHERSCANV2_API_KEY --verifier etherscan"
        fi
        log "INFO" "Mode: Execute (account: $account)"
    elif [ "$mode" = "simulate" ]; then
        SENDER_FLAG="--sender $ADMIN"
        log "INFO" "Mode: Simulate (sender: $ADMIN)"
    else
        log "INFO" "Mode: Check (read-only)"
    fi

    local forge_cmd="forge script"
    forge_cmd+=" script/DeploySuperVaultV2.s.sol:DeploySuperVaultV2"

    if [ "$mode" = "check" ]; then
        forge_cmd+=" --sig 'runCheck(uint256,uint64,string)' $env $chain_id \"\""
    else
        forge_cmd+=" --sig 'run(uint256,uint64,string)' $env $chain_id \"\""
    fi

    forge_cmd+=" --rpc-url $rpc_url"
    forge_cmd+=" --chain $chain_id"
    [ -n "$ACCOUNT_FLAG" ]    && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ]     && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ]  && forge_cmd+=" $BROADCAST_FLAG"
    [ -n "$VERIFY_FLAG" ]     && forge_cmd+=" $VERIFY_FLAG"
    [ -n "$ETHERSCAN_FLAGS" ] && forge_cmd+=" $ETHERSCAN_FLAGS"
    forge_cmd+=" -vvvv"

    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Failed on chain $chain_id (exit code: $exit_code)"
        return $exit_code
    fi

    log "INFO" "Chain $chain_id: success"
    return 0
}

###################################################################################
# Main
###################################################################################

main() {
    if [ $# -lt 2 ]; then
        log "ERROR" "Missing required arguments"
        usage
    fi

    local environment="$1"
    local mode="$2"
    local account="${3:-}"
    local specific_chain="${4:-}"

    validate_environment "$environment"
    validate_mode "$mode"

    source_network_config "$environment"

    if [ "$mode" = "execute" ] && [ -z "$account" ]; then
        log "ERROR" "Account name is required for execute mode"
        log "ERROR" "Usage: $0 $environment execute <account_name>"
        exit 1
    fi

    local env
    case "$environment" in
        prod)    env=0 ;;
        staging) env=2 ;;
    esac

    log "INFO" "Loading RPC URLs..."
    load_rpc_urls

    export ETHERSCANV2_API_KEY_TEST="${ETHERSCANV2_API_KEY_TEST:-}"

    if [ "$mode" = "execute" ]; then
        log "INFO" "Loading Etherscan API credentials..."
        if ! load_etherscan_api_key; then
            log "ERROR" "Failed to load Etherscan API key. Verification will not work."
            exit 1
        fi
    fi

    log "INFO" "============================================"
    log "INFO" "Deploy SuperVault V2"
    log "INFO" "============================================"
    log "INFO" "Environment : $environment (env=$env)"
    log "INFO" "Mode        : $mode"
    log "INFO" "Admin       : $ADMIN"
    if [ -n "$specific_chain" ]; then
        log "INFO" "Target Chain: $specific_chain"
    else
        log "INFO" "Target Chains: All supported chains"
    fi
    log "INFO" "============================================"
    log "INFO" ""
    log "INFO" "Contracts to deploy:"
    log "INFO" "  SuperVaultV2             (AssetMetadataLibV2, B20 precompile support)"
    log "INFO" "  SuperVaultStrategyV2     (ERC721/ERC1155/ERC1271/ERC165 receivers)"
    log "INFO" "  SuperVaultEscrow         (V2 salt)"
    log "INFO" "  SuperVaultAggregatorV2   (registry/PPS oracle)"
    log "INFO" ""
    log "INFO" "NOTE: SuperGovernor SUPER_VAULT_AGGREGATOR will NOT be updated by this script."
    log "INFO" "      That requires a separate governance action after verifying deployment."
    log "INFO" "============================================"

    local failed_chains=()
    local success_count=0

    local chains_to_deploy
    if [ -n "$specific_chain" ]; then
        chains_to_deploy=("$specific_chain")
    else
        mapfile -t chains_to_deploy < <(get_supported_networks)
    fi

    for chain_id in "${chains_to_deploy[@]}"; do
        local rpc_url
        rpc_url=$(get_rpc_url "$chain_id")

        if [ -z "$rpc_url" ]; then
            log "WARN" "Skipping chain $chain_id — RPC URL not available"
            failed_chains+=("$chain_id")
            continue
        fi

        if deploy_on_chain "$env" "$chain_id" "$mode" "$account" "$rpc_url"; then
            ((++success_count))
        else
            failed_chains+=("$chain_id")
        fi

        log "INFO" ""
    done

    log "INFO" "============================================"
    log "INFO" "Deployment Summary"
    log "INFO" "============================================"
    log "INFO" "Successful : $success_count"
    log "INFO" "Failed     : ${#failed_chains[@]}"

    if [ ${#failed_chains[@]} -gt 0 ]; then
        log "WARN" "Failed chains: ${failed_chains[*]}"
        exit 1
    fi

    log "INFO" "============================================"
    log "INFO" "SuperVault V2 deployment complete!"
    log "INFO" ""
    log "INFO" "Post-deployment checklist:"
    log "INFO" "  1. Verify addresses in script/output/<env>/<chainId>/<Chain>-latest.json"
    log "INFO" "     Keys: SuperVaultV2, SuperVaultStrategyV2, SuperVaultEscrowV2, SuperVaultAggregatorV2"
    log "INFO" "  2. Run governance action to update SuperGovernor:"
    log "INFO" "       superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, <SuperVaultAggregatorV2>)"
    log "INFO" "============================================"
}

main "$@"
