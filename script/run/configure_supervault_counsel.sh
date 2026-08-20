#!/usr/bin/env bash

###################################################################################
# Configure SuperVaultCounsel Script (enrollment steps 2-3)
###################################################################################
#
# Runs the post-seating enrollment for SuperVaultCounsel on each strategy:
#   2. counsel.enrollExecutor()            (seating wiped all secondary managers)
#   3. counsel.invalidateAllSessionKeys()  (kills keys from any prior tenure)
#
# PREREQUISITES (per strategy):
#   - Counsel deployed (deploy_supervault_counsel.sh) and present in the chain
#     output JSON under .SuperVaultCounsel_<strategy>
#   - Runbook step 1 already executed by the SuperGovernor msig:
#       changePrimaryManager(strategy, counsel, feeRecipient)
#     The script pre-checks this and fails cleanly if the seat is not transferred.
#   - The BROADCASTER must be the Counsel's OPERATOR (both calls are
#     operator-gated). If the operator is a Safe, drive these two calls through
#     the Safe instead; use this script's "check" mode to verify state.
#
# Step 4 (grantSessionKeysBatch to re-onboard keepers) is keeper-specific and
# deliberately not automated here - run it as a follow-up operator action.
#
# Usage:
#   ./configure_supervault_counsel.sh <environment> <mode> [account] [chain_id] [strategy]
#
# Parameters:
#   environment  "prod" or "staging"
#   mode         "simulate", "execute", or "check"
#   account      Account name for execute mode (must be the operator key)
#   chain_id     Target chain ID (optional; omit for all chains)
#   strategy     Single strategy address (optional; omit for all on the chain)
#
# Environment variables:
#   OPERATOR   Operator address; used as --sender in simulate mode so the
#              operator-gate pre-checks pass (required for simulate)
#
# Examples:
#   ./configure_supervault_counsel.sh prod check 8453
#   OPERATOR=0x... ./configure_supervault_counsel.sh prod simulate 8453 0x5bE8c059A8E101d24B107aFb5A013feF505280b9
#   ./configure_supervault_counsel.sh prod execute counsel-operator 8453
#
###################################################################################

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Fleet: "CHAIN_ID:STRATEGY:LABEL" (must match deploy_supervault_counsel.sh)
readonly FLEET=(
    "1:0x41A9Eb398518D2487301c61D2b33E4e966A9F1DD:SuperUSDC"
    "1:0x1199a6B2587Ed96446E76Dee3FB660bb8fCfd0b2:SuperETH"
    "1:0xa96060B0B6907406EdBDf3cCc9438abf0F78Cf83:SuperWBTC"
    "8453:0x5bE8c059A8E101d24B107aFb5A013feF505280b9:FlagshipUSDC"
    "8453:0x2787a17fe04C73AD109370C90917d62D1899Eb6A:FlagshipWETH"
    "8453:0x0c14c751b19D4362f14f4A1D1cB963180B63fB87:FlagshipCBBTC"
    "8453:0x837F9936D8493d0F867b6fD21128dee410b8B8d3:StocksUSDC"
    "8453:0xEcb97e12af8C3730a5d8414604910c16E5BAbBc9:SPCX"
    "8453:0xB80755d52Ae022152fA4606c05bc0e2fdB405De5:TSLA"
    "8453:0xEF83ABC641B98af01f0652E3Af49a25d65C601A5:NVDA"
    "14:0x3B5f2031447270b29dda0e78E037D28ba69690DA:BizantineUSDT0"
    "14:0xA2C060a2aF858Fa1CA0C76588D8478456dd3037F:BizantineFXRP"
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
    account      Account name (required for execute mode - MUST be the operator key)
    chain_id     Target chain ID (optional; 1, 8453, or 14)
    strategy     Single strategy address (optional)

Env vars:
    OPERATOR     Required for simulate mode (used as --sender so operator gates pass)

Examples:
    $0 prod check 8453
    OPERATOR=0x... $0 prod simulate 8453
    $0 prod execute counsel-operator 8453 0x5bE8c059A8E101d24B107aFb5A013feF505280b9

Note: runbook step 1 (SuperGovernor msig changePrimaryManager) must be done first;
this script verifies and fails per-strategy if the Counsel is not seated yet.

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

get_chain_rpc_url() {
    local chain_id=$1
    local rpc_var
    rpc_var=$(get_rpc_var "$chain_id" 2>/dev/null) || { echo ""; return; }
    echo "${!rpc_var:-}"
}

run_for_strategy() {
    local env=$1 chain_id=$2 strategy=$3 label=$4 mode=$5 account=$6 rpc_url=$7

    log "INFO" "--------------------------------------------"
    log "INFO" "Strategy: $label ($strategy) on chain $chain_id"
    log "INFO" "--------------------------------------------"

    local sig
    if [ "$mode" = "check" ]; then
        sig="runCheck(uint256,uint64,string,address)"
    else
        sig="run(uint256,uint64,string,address)"
    fi

    local forge_cmd="forge script script/ConfigureSuperVaultCounsel.s.sol:ConfigureSuperVaultCounsel"
    forge_cmd+=" --sig '$sig' $env $chain_id '\"\"' $strategy"
    forge_cmd+=" --rpc-url '$rpc_url' --chain $chain_id"

    if [ "$mode" = "execute" ]; then
        forge_cmd+=" --account $account --broadcast"
    elif [ "$mode" = "simulate" ]; then
        forge_cmd+=" --sender $OPERATOR"
    fi
    forge_cmd+=" -vvvv"

    local exit_code=0
    eval "$forge_cmd" || exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log "ERROR" "$label ($chain_id) failed with exit code: $exit_code"
        return $exit_code
    fi
    log "INFO" "$label ($chain_id) $mode successful"
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
        log "ERROR" "Account name is required for execute mode (must be the operator key)"; usage
    fi
    if [ "$mode" = "simulate" ] && [ -z "${OPERATOR:-}" ]; then
        log "ERROR" "OPERATOR env var is required for simulate mode (used as --sender)"; usage
    fi

    local env
    case "$environment" in
        prod) env=0 ;;
        staging) env=2 ;;
    esac

    source_network_config "$environment"
    log "INFO" "Loading RPC URLs..."
    load_rpc_urls

    log "INFO" "============================================"
    log "INFO" "Configure SuperVaultCounsel (enrollment steps 2-3)"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    [ -n "${OPERATOR:-}" ] && log "INFO" "Operator (simulate sender): $OPERATOR"
    [ -n "$target_chain_id" ] && log "INFO" "Chain filter: $target_chain_id"
    [ -n "$target_strategy" ] && log "INFO" "Strategy filter: $target_strategy"
    log "INFO" "============================================"

    local ok=() failed=() skipped=()
    for entry in "${FLEET[@]}"; do
        IFS=':' read -r chain_id strategy label <<< "$entry"
        [ -n "$target_chain_id" ] && [ "$chain_id" != "$target_chain_id" ] && continue
        if [ -n "$target_strategy" ] && [ "$(echo "$strategy" | tr 'A-F' 'a-f')" != "$(echo "$target_strategy" | tr 'A-F' 'a-f')" ]; then
            continue
        fi

        local rpc_url
        rpc_url=$(get_chain_rpc_url "$chain_id")
        if [ -z "$rpc_url" ]; then
            log "WARN" "Skipping $label ($chain_id) - RPC URL not available"
            skipped+=("$label ($chain_id)")
            continue
        fi

        if run_for_strategy "$env" "$chain_id" "$strategy" "$label" "$mode" "$account" "$rpc_url"; then
            ok+=("$label ($chain_id)")
        else
            failed+=("$label ($chain_id)")
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
    if [ "$mode" = "execute" ]; then
        log "INFO" "NEXT (step 4): operator runs counsel.grantSessionKeysBatch(...) per strategy"
        log "INFO" "NEVER call SuperGovernor.freezeManagerTakeover() while a Counsel is enrolled"
    fi
}

main "$@"
