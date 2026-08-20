#!/usr/bin/env bash

###################################################################################
# Deploy SuperVaultCounsel Script
###################################################################################
# Description:
#   Deploys SuperVaultCounsel - the immutable, veto-gated adapter that occupies
#   a SuperVault strategy's primary-manager/curator seat. One instance per
#   strategy (the CREATE2 salt embeds the strategy address).
#
#   "All strategies" = the CURATED fleet in script/utils/counsel-fleet.json
#   (the 12 production strategies), NOT the full aggregator registry. The
#   operator Safe and deviation bounds also come from that config - no extra
#   CLI params needed. Every fleet strategy is validated against the on-chain
#   registry; already-deployed Counsels are skipped (idempotent re-runs).
#
#   Operator rules: simulate works with the config operator unset (a placeholder
#   is used and computed addresses will differ); any BROADCAST requires the real
#   operator Safe in counsel-fleet.json - the forge script reverts otherwise.
#
#   Each deployment is saved to the chain output JSON under
#   ".SuperVaultCounsel_<strategyAddress>".
#
# Usage:
#   ./deploy_supervault_counsel.sh <environment> <mode> [account] [chain_id] [strategy]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate", "execute", or "check"
#     account: Account name (required for execute mode)
#     chain_id: Chain ID (optional; omit to run all fleet chains: 1, 8453, 14)
#     strategy: Strategy address (optional; omit for the whole fleet on the
#               chain; required for check mode)
#
# Examples:
#   # Simulate the whole fleet on every chain
#   ./deploy_supervault_counsel.sh staging simulate v2-supervaults
#
#   # Simulate the fleet on Ethereum only
#   ./deploy_supervault_counsel.sh staging simulate v2-supervaults 1
#
#   # Execute the fleet on Base (operator must be set in counsel-fleet.json)
#   ./deploy_supervault_counsel.sh prod execute v2-supervaults 8453
#
#   # Deploy / check a single strategy
#   ./deploy_supervault_counsel.sh prod execute v2-supervaults 8453 0x5bE8c059A8E101d24B107aFb5A013feF505280b9
#   ./deploy_supervault_counsel.sh prod check 8453 0x5bE8c059A8E101d24B107aFb5A013feF505280b9
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account configured
#   - SuperGovernor, SuperVaultAggregator, and SuperVaultExecutor deployed on the
#     target chain (present in script/output/<env>/<chain>/<Chain>-latest.json)
#   - Bytecode artifacts generated (run tooling/regenerate_bytecode.sh first)
#
# Post-Deployment Steps (ENROLLMENT RUNBOOK - order matters):
#   0. Audit the strategy's secondary-manager list is clean BEFORE enrollment
#   1. SuperGovernor msig: changePrimaryManager(strategy, counsel, feeRecipient)
#   2-3. ../config/configure_supervault_counsel.sh (enrollExecutor + invalidateAllSessionKeys)
#   4. Operator: counsel.grantSessionKeysBatch(...) (re-onboard keepers)
#   NEVER call SuperGovernor.freezeManagerTakeover() while a Counsel is enrolled.
#
# Author: Superform Team
###################################################################################

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Sender for simulate mode (v2 deployer keystore address)
readonly SIMULATE_SENDER="${SIMULATE_SENDER:-0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8}"

# Chains covered by the counsel fleet config
readonly SUPPORTED_CHAINS=(
    "1:Ethereum"
    "8453:Base"
    "14:Flare"
)

log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

usage() {
    cat << EOF
Usage: $0 <environment> <mode> [account] [chain_id] [strategy]

Arguments:
    environment  "prod" or "staging" (required)
    mode         "simulate", "execute", or "check" (required)
    account      Account name (required for execute mode)
    chain_id     Chain ID (optional; omit for all fleet chains: 1, 8453, 14)
    strategy     Strategy address (optional; whole fleet if omitted;
                 required for check mode)

Operator + deviation bounds come from script/utils/counsel-fleet.json.
Simulate works without the operator set (placeholder); broadcast requires it.

Examples:
    $0 staging simulate v2-supervaults
    $0 staging simulate v2-supervaults 1
    $0 prod execute v2-supervaults 8453
    $0 prod check 8453 0x5bE8c059A8E101d24B107aFb5A013feF505280b9

EOF
    exit 1
}

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

get_chain_rpc_url() {
    local chain_id=$1
    local rpc_var
    rpc_var=$(get_rpc_var "$chain_id" 2>/dev/null) || { echo ""; return; }
    echo "${!rpc_var:-}"
}

run_for_chain() {
    local env=$1 chain_id=$2 chain_name=$3 mode=$4 account=$5 rpc_url=$6 strategy=$7

    log "INFO" "--------------------------------------------"
    if [ -n "$strategy" ]; then
        log "INFO" "Chain $chain_name ($chain_id) - single strategy: $strategy"
    else
        log "INFO" "Chain $chain_name ($chain_id) - curated fleet"
    fi
    log "INFO" "--------------------------------------------"

    local forge_cmd="forge script script/DeploySuperVaultCounsel.s.sol:DeploySuperVaultCounsel"
    if [ "$mode" = "check" ]; then
        forge_cmd+=" --sig 'runCheckOne(uint256,uint64,string,address)' $env $chain_id '\"\"' $strategy"
    elif [ -n "$strategy" ]; then
        forge_cmd+=" --sig 'runOne(uint256,uint64,string,address)' $env $chain_id '\"\"' $strategy"
    else
        forge_cmd+=" --sig 'runAll(uint256,uint64,string)' $env $chain_id '\"\"'"
    fi
    forge_cmd+=" --rpc-url '$rpc_url' --chain $chain_id"

    if [ "$mode" = "execute" ]; then
        forge_cmd+=" --account $account --broadcast"
        # Etherscan verification only where supported (not HyperEVM/Flare)
        if [ "$chain_id" != "999" ] && [ "$chain_id" != "14" ]; then
            forge_cmd+=" --verify --etherscan-api-key ${ETHERSCANV2_API_KEY:-} --verifier etherscan"
        fi
    elif [ "$mode" = "simulate" ]; then
        forge_cmd+=" --sender $SIMULATE_SENDER"
    fi
    forge_cmd+=" -vvvv"

    local exit_code=0
    eval "$forge_cmd" || exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "$chain_name ($chain_id) failed with exit code: $exit_code"
        return $exit_code
    fi
    log "INFO" "$chain_name ($chain_id) $mode successful"
    return 0
}

main() {
    if [ $# -lt 2 ]; then
        log "ERROR" "Missing required arguments"
        usage
    fi

    local environment="$1"
    local mode="$2"
    local account=""
    local target_chain_id=""
    local target_strategy=""

    # Flexible tail args: [account] [chain_id] [strategy] - 0x... = strategy, numeric = chain
    shift 2
    for arg in "$@"; do
        if [[ "$arg" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
            target_strategy="$arg"
        elif [[ "$arg" =~ ^[0-9]+$ ]]; then
            target_chain_id="$arg"
        else
            account="$arg"
        fi
    done

    if [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; then
        log "ERROR" "Invalid environment: $environment"; exit 1
    fi
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ] && [ "$mode" != "check" ]; then
        log "ERROR" "Invalid mode: $mode"; exit 1
    fi
    if [ "$mode" = "execute" ] && [ -z "$account" ]; then
        log "ERROR" "Account name is required for execute mode"; usage
    fi
    if [ "$mode" = "check" ] && [ -z "$target_strategy" ]; then
        log "ERROR" "check mode requires a strategy address"; usage
    fi
    if [ -n "$target_strategy" ] && [ -z "$target_chain_id" ]; then
        log "ERROR" "A strategy address requires an explicit chain_id"; usage
    fi

    local env
    case "$environment" in
        prod) env=0 ;;
        staging) env=2 ;;
    esac

    source_network_config "$environment"
    log "INFO" "Loading RPC URLs..."
    load_rpc_urls

    if [ "$mode" = "execute" ]; then
        log "INFO" "Loading Etherscan API credentials..."
        load_etherscan_api_key || log "WARN" "Etherscan key unavailable - verification will not work"
    fi
    export ETHERSCANV2_API_KEY_TEST="${ETHERSCANV2_API_KEY_TEST:-}"

    log "INFO" "============================================"
    log "INFO" "Deploy SuperVaultCounsel (fleet from counsel-fleet.json)"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    [ -n "$target_chain_id" ] && log "INFO" "Chain filter: $target_chain_id"
    [ -n "$target_strategy" ] && log "INFO" "Strategy filter: $target_strategy"
    log "INFO" "============================================"

    local ok=() failed=() skipped=()
    for entry in "${SUPPORTED_CHAINS[@]}"; do
        IFS=':' read -r chain_id chain_name <<< "$entry"
        [ -n "$target_chain_id" ] && [ "$chain_id" != "$target_chain_id" ] && continue

        local rpc_url
        rpc_url=$(get_chain_rpc_url "$chain_id")
        if [ -z "$rpc_url" ]; then
            log "WARN" "Skipping $chain_name ($chain_id) - RPC URL not available"
            skipped+=("$chain_name ($chain_id)")
            continue
        fi

        if run_for_chain "$env" "$chain_id" "$chain_name" "$mode" "$account" "$rpc_url" "$target_strategy"; then
            ok+=("$chain_name ($chain_id)")
        else
            failed+=("$chain_name ($chain_id)")
        fi
        log "INFO" ""
    done

    log "INFO" "============================================"
    log "INFO" "Summary"
    log "INFO" "============================================"
    for c in "${ok[@]:-}"; do [ -n "$c" ] && log "INFO" "  OK $c"; done
    for c in "${skipped[@]:-}"; do [ -n "$c" ] && log "INFO" "  -- $c (skipped)"; done
    for c in "${failed[@]:-}"; do [ -n "$c" ] && log "WARN" "  XX $c (failed)"; done

    if [ ${#failed[@]} -gt 0 ]; then
        log "ERROR" "Completed with failures"
        exit 1
    fi
    log "INFO" "Completed successfully!"
}

main "$@"
