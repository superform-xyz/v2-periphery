#!/usr/bin/env bash

###################################################################################
# Deploy SuperVaultCounsel Script
###################################################################################
# Description:
#   Deploys SuperVaultCounsel - the immutable, veto-gated adapter that occupies
#   a SuperVault strategy's primary-manager/curator seat. One instance per strategy
#   (the CREATE2 salt embeds the strategy address).
#
#   SuperGovernor, Aggregator, and SuperVaultExecutor are resolved from the chain's
#   output JSON; the operator Safe and deviation-threshold bounds are supplied here.
#   Veto window (3 days) and expiry (7 days) are spec-pinned in the forge script.
#
# Usage:
#   ./deploy_supervault_counsel.sh <environment> <mode> <account> <chain_id> <strategy> <operator> [min_dev] [max_dev]
#
#   Parameters:
#     environment: "prod" or "staging"
#     mode: "simulate", "execute", or "check"
#     account: Account name (required for execute mode, use "" otherwise)
#     chain_id: Chain ID (required - Counsel deployments are per-strategy, per-chain)
#     strategy: SuperVaultStrategy address the Counsel will manage
#     operator: Operator Safe address (proposer + executor + day-to-day)
#     min_dev: Optional deviation-threshold floor (default: 1000000000000000 = 0.1%)
#     max_dev: Optional deviation-threshold ceiling (default: 990000000000000000 = 99%)
#
# Examples:
#   # Check deployment + enrollment status on Base staging
#   ./deploy_supervault_counsel.sh staging check "" 8453 0xStrategy... 0xOperatorSafe...
#
#   # Simulate deployment on Base staging
#   ./deploy_supervault_counsel.sh staging simulate "" 8453 0xStrategy... 0xOperatorSafe...
#
#   # Execute deployment on Base staging
#   ./deploy_supervault_counsel.sh staging execute v2-supervaults 8453 0xStrategy... 0xOperatorSafe...
#
#   # Execute with custom deviation bounds (floor 1%, ceiling 90%)
#   ./deploy_supervault_counsel.sh staging execute v2-supervaults 8453 0xStrategy... 0xOperatorSafe... 10000000000000000 900000000000000000
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account configured
#   - SuperGovernor, SuperVaultAggregator, and SuperVaultExecutor deployed on the
#     target chain (present in script/output/<env>/<chain>/<Chain>-latest.json)
#   - Bytecode artifacts generated (run regenerate_bytecode.sh first)
#
# Post-Deployment Steps (ENROLLMENT RUNBOOK - order matters):
#   0. Audit the strategy's secondary-manager list is clean BEFORE enrollment
#      (a hostile pre-existing secondary can race proposeChangePrimaryManager)
#   1. SuperGovernor msig: changePrimaryManager(strategy, counsel, feeRecipient)
#   2. Operator: counsel.enrollExecutor()          (enrollment wipes all secondaries)
#   3. Operator or guardian: counsel.invalidateAllSessionKeys()
#   4. Operator: counsel.grantSessionKeysBatch(...) (re-onboard keepers)
#   NEVER call SuperGovernor.freezeManagerTakeover() while a Counsel is enrolled -
#   it is permanent and removes the only adapter-replacement path.
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Admin address (SUPER_GOVERNOR_ADDRESS) - used for --sender in simulate mode
readonly ADMIN="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

# Spec defaults for the immutable deviation-threshold bounds
readonly DEFAULT_MIN_DEV="1000000000000000"    # 1e15 = 0.1%
readonly DEFAULT_MAX_DEV="990000000000000000"  # 99e16 = 99%

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
Usage: $0 <environment> <mode> <account> <chain_id> <strategy> <operator> [min_dev] [max_dev]

Arguments:
    environment  Environment: "prod" or "staging" (required)
    mode         Mode: "simulate", "execute", or "check" (required)
    account      Account name (required for execute mode, use "" otherwise)
    chain_id     Chain ID (required - per-strategy, per-chain deployment)
    strategy     SuperVaultStrategy address the Counsel will manage (required)
    operator     Operator Safe address (required)
    min_dev      Optional deviation-threshold floor (default: ${DEFAULT_MIN_DEV})
    max_dev      Optional deviation-threshold ceiling (default: ${DEFAULT_MAX_DEV})

Examples:
    # Check deployment + enrollment status on Base staging
    $0 staging check "" 8453 0xStrategy... 0xOperatorSafe...

    # Simulate deployment on Base staging
    $0 staging simulate "" 8453 0xStrategy... 0xOperatorSafe...

    # Execute deployment on Base staging
    $0 staging execute v2-supervaults 8453 0xStrategy... 0xOperatorSafe...

EOF
    exit 1
}

# Source network configuration based on environment
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

validate_environment() {
    local environment=$1
    if [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; then
        log "ERROR" "Invalid environment: $environment (must be 'staging' or 'prod')"
        exit 1
    fi
}

validate_mode() {
    local mode=$1
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ] && [ "$mode" != "check" ]; then
        log "ERROR" "Invalid mode: $mode (must be 'simulate', 'execute', or 'check')"
        exit 1
    fi
}

validate_address() {
    local name=$1
    local value=$2
    if [[ ! "$value" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
        log "ERROR" "Invalid $name address: $value"
        exit 1
    fi
    if [ "$value" = "0x0000000000000000000000000000000000000000" ]; then
        log "ERROR" "$name address cannot be zero"
        exit 1
    fi
}

###################################################################################
# Main
###################################################################################

main() {
    if [ $# -lt 6 ]; then
        log "ERROR" "Missing required arguments"
        usage
    fi

    local environment="$1"
    local mode="$2"
    local account="$3"
    local chain_id="$4"
    local strategy="$5"
    local operator="$6"
    local min_dev="${7:-$DEFAULT_MIN_DEV}"
    local max_dev="${8:-$DEFAULT_MAX_DEV}"

    # Validate inputs
    validate_environment "$environment"
    validate_mode "$mode"
    validate_address "strategy" "$strategy"
    validate_address "operator" "$operator"

    if [ "$mode" = "execute" ] && [ -z "$account" ]; then
        log "ERROR" "Account name is required for execute mode"
        exit 1
    fi

    # Source network configuration
    source_network_config "$environment"

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

    # Get RPC URL for the target chain
    local rpc_url
    rpc_url=$(get_rpc_url "$chain_id")
    if [ -z "$rpc_url" ]; then
        log "ERROR" "RPC URL not available for chain $chain_id"
        exit 1
    fi

    log "INFO" "============================================"
    log "INFO" "Deploy SuperVaultCounsel"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    log "INFO" "Chain ID: $chain_id"
    log "INFO" "Strategy: $strategy"
    log "INFO" "Operator: $operator"
    log "INFO" "Deviation bounds: [$min_dev, $max_dev]"
    log "INFO" "Veto window / expiry: 3 days / 7 days (spec-pinned)"
    log "INFO" "============================================"

    # Set flags based on mode
    local BROADCAST_FLAG=""
    local VERIFY_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""
    local ETHERSCAN_FLAGS=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        ACCOUNT_FLAG="--account $account"
        # Skip etherscan verification for HyperEVM, Flare, and RH (no etherscan support)
        if [ "$chain_id" != "999" ] && [ "$chain_id" != "14" ] && [ "$chain_id" != "4663" ]; then
            VERIFY_FLAG="--verify"
            ETHERSCAN_FLAGS="--etherscan-api-key $ETHERSCANV2_API_KEY --verifier etherscan"
        fi
        log "INFO" "Mode: Execute (will broadcast using account: $account)"
    elif [ "$mode" = "simulate" ]; then
        SENDER_FLAG="--sender $ADMIN"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $ADMIN)"
    else
        log "INFO" "Mode: Check (read-only)"
    fi

    # Build forge command
    local sig_fn="run"
    [ "$mode" = "check" ] && sig_fn="runCheck"

    local forge_cmd="forge script"
    forge_cmd+=" script/DeploySuperVaultCounsel.s.sol:DeploySuperVaultCounsel"
    # NOTE: sig order is (env, chainId, branchName, operator, strategy, minDev, maxDev)
    forge_cmd+=" --sig '${sig_fn}(uint256,uint64,string,address,address,uint256,uint256)'"
    forge_cmd+=" $env $chain_id \"\" $operator $strategy $min_dev $max_dev"
    forge_cmd+=" --rpc-url $rpc_url"
    forge_cmd+=" --chain $chain_id"
    [ -n "$ACCOUNT_FLAG" ] && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ] && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ] && forge_cmd+=" $BROADCAST_FLAG"
    [ -n "$VERIFY_FLAG" ] && forge_cmd+=" $VERIFY_FLAG"
    [ -n "$ETHERSCAN_FLAGS" ] && forge_cmd+=" $ETHERSCAN_FLAGS"
    forge_cmd+=" -vvvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Deployment failed on chain $chain_id with exit code: $exit_code"
        exit $exit_code
    fi

    log "INFO" "============================================"
    log "INFO" "SuperVaultCounsel $mode completed successfully!"
    if [ "$mode" = "execute" ]; then
        log "INFO" ""
        log "INFO" "NEXT STEPS (enrollment runbook - order matters):"
        log "INFO" "  0. Audit strategy secondary-manager list is clean"
        log "INFO" "  1. SuperGovernor msig: changePrimaryManager(strategy, counsel, feeRecipient)"
        log "INFO" "  2. Operator: counsel.enrollExecutor()"
        log "INFO" "  3. Operator/guardian: counsel.invalidateAllSessionKeys()"
        log "INFO" "  4. Operator: counsel.grantSessionKeysBatch(...)"
        log "INFO" "  NEVER freezeManagerTakeover() while a Counsel is enrolled"
    fi
    log "INFO" "============================================"
}

main "$@"
