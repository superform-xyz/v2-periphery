#!/usr/bin/env bash

###################################################################################
# Deploy SuperVaultCounsel Script
###################################################################################
#
# Deploys one SuperVaultCounsel per strategy - the immutable veto-gated adapter
# that occupies a SuperVault strategy's primary-manager/curator seat. The salt
# embeds the strategy address, so every strategy gets its own deterministic
# Counsel address.
#
# Fleet (12 strategies): Ethereum (3), Base (7 incl. stocks vaults), Flare (2
# Bizantine). Filter by chain_id and/or a single strategy address.
#
# For a single ad-hoc strategy with explicit positional params, use the
# per-strategy runner instead: ./deploy/deploy_supervault_counsel.sh
# This fleet runner and that script drive the same forge script.
#
# Usage:
#   ./deploy_supervault_counsel_fleet.sh <environment> <mode> [account] [chain_id] [strategy]
#
# Parameters:
#   environment  "prod" or "staging"
#   mode         "simulate", "execute", or "check"
#   account      Account name for execute mode (e.g., "v2-deployer")
#   chain_id     Target chain ID (optional; omit for all chains)
#   strategy     Single strategy address (optional; omit for all on the chain)
#
# Environment variables:
#   OPERATOR   REQUIRED - the operator Safe address (immutable; no safe default)
#   MIN_DEV    Deviation-threshold floor, 1e18 = 100%
#              (default 1000000000000000 = 0.1%, matching deploy/deploy_supervault_counsel.sh)
#   MAX_DEV    Deviation-threshold ceiling
#              (default 990000000000000000 = 99%, matching deploy/deploy_supervault_counsel.sh)
#
# Examples:
#   OPERATOR=0x... ./deploy_supervault_counsel_fleet.sh prod simulate v2-deployer 8453
#   OPERATOR=0x... ./deploy_supervault_counsel_fleet.sh prod execute v2-deployer 8453 0x5bE8c059A8E101d24B107aFb5A013feF505280b9
#   OPERATOR=0x... ./deploy_supervault_counsel_fleet.sh prod check 1
#
# After deployment, follow the enrollment runbook:
#   1. SuperGovernor msig: changePrimaryManager(strategy, counsel, feeRecipient)
#   2-3. ./configure_supervault_counsel.sh (this repo, script/run/)  (enrollExecutor + invalidateAllSessionKeys)
#   4. Operator: counsel.grantSessionKeysBatch(...)
#   NEVER call SuperGovernor.freezeManagerTakeover() while a Counsel is enrolled.
#
###################################################################################

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Sender for simulate mode (v2 deployer keystore address)
readonly SIMULATE_SENDER="${SIMULATE_SENDER:-0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8}"

# Fleet: "CHAIN_ID:STRATEGY:LABEL" (the 12 production strategies)
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
Usage: OPERATOR=0x... $0 <environment> <mode> [account] [chain_id] [strategy]

Arguments:
    environment  "prod" or "staging" (required)
    mode         "simulate", "execute", or "check" (required)
    account      Account name (required for execute mode)
    chain_id     Target chain ID (optional; omit for all chains: 1, 8453, 14)
    strategy     Single strategy address (optional; omit for all on the chain)

Env vars:
    OPERATOR   Operator Safe address (REQUIRED - immutable, no default)
    MIN_DEV    Deviation-threshold floor  (default 1000000000000000 = 0.1%)
    MAX_DEV    Deviation-threshold ceiling (default 990000000000000000 = 99%)

Examples:
    OPERATOR=0x... $0 prod simulate v2-deployer 8453
    OPERATOR=0x... $0 prod check 1

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
        sig="runCheck(uint256,uint64,string,address,address,uint256,uint256)"
    else
        sig="run(uint256,uint64,string,address,address,uint256,uint256)"
    fi

    local forge_cmd="forge script script/DeploySuperVaultCounsel.s.sol:DeploySuperVaultCounsel"
    forge_cmd+=" --sig '$sig' $env $chain_id '\"\"' $OPERATOR $strategy $MIN_DEV $MAX_DEV"
    forge_cmd+=" --rpc-url '$rpc_url' --chain $chain_id"

    if [ "$mode" = "execute" ]; then
        forge_cmd+=" --account $account --broadcast"
        # Etherscan verification only where supported (not HyperEVM/Flare)
        if [ "$chain_id" != "999" ] && [ "$chain_id" != "14" ]; then
            forge_cmd+=" --verify --etherscan-api-key ${ETHERSCANV2_API_KEY:-} --verifier etherscan"
        fi
    else
        forge_cmd+=" --sender $SIMULATE_SENDER"
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

    # Flexible tail args: [account] [chain_id] [strategy] - numeric = chain, 0x... = strategy
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

    # Immutable constructor params - operator has no safe default; bounds match the
    # per-strategy runner's defaults (0.1% floor, 99% ceiling)
    MIN_DEV="${MIN_DEV:-1000000000000000}"
    MAX_DEV="${MAX_DEV:-990000000000000000}"
    if [ -z "${OPERATOR:-}" ]; then
        log "ERROR" "OPERATOR env var is required (immutable constructor param - no default)"
        usage
    fi
    if ! [[ "$OPERATOR" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
        log "ERROR" "OPERATOR must be a 20-byte hex address"; exit 1
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
    log "INFO" "Deploy SuperVaultCounsel (per-strategy)"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    log "INFO" "Operator Safe: $OPERATOR"
    log "INFO" "Deviation bounds: $MIN_DEV .. $MAX_DEV (1e18 = 100%)"
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
}

main "$@"
