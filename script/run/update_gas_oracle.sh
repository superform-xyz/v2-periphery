#!/usr/bin/env bash

###################################################################################
# Update Gas Oracle Script (BasefeeGasOracle migration)
###################################################################################
#
# Migrates SuperOracle's GAS_QUOTE -> WEI_QUOTE upkeep pricing off the deprecated
# Chainlink Fast Gas feed by registering BasefeeGasOracle under the SUPERFORM
# provider (additive - CHAINLINK slot untouched). Two-step flow with SuperOracle's
# 1-week timelock in between:
#
#   1. queue     - SuperGovernor.queueOracleUpdate (logs the queue timestamp - SAVE IT)
#   2. finalize  - SuperGovernor.executeOracleUpdate (requires the queue timestamp
#                  as a clobber guard: the pending slot is global and overwritable)
#
# Mainnet (1) only. BasefeeGasOracle must already be deployed and present in
# script/output/{env}/1/Ethereum-latest.json (run deploy_basefee_gas_oracle.sh first).
#
# Usage:
#   ./update_gas_oracle.sh <environment> <action> [mode] [account] [queue_timestamp]
#
# Parameters:
#   environment      "prod" or "staging"
#   action           "check", "queue", or "finalize"
#   mode             "simulate" or "execute" (required for queue/finalize)
#   account          Account name for execute mode (e.g., "v2-deployer")
#   queue_timestamp  Timestamp logged by queue (required for finalize; 0 skips guard)
#
# Examples:
#   ./update_gas_oracle.sh staging check
#   ./update_gas_oracle.sh staging queue simulate
#   ./update_gas_oracle.sh prod queue execute v2-deployer
#   ./update_gas_oracle.sh prod finalize simulate 1787000000
#   ./update_gas_oracle.sh prod finalize execute v2-deployer 1787000000
#
# Built-in safety rails (in the Solidity script):
#   - queue aborts if another oracle update is already pending (global slot!)
#   - queue enforces on-chain unit parity vs the live Fast Gas feed
#   - finalize verifies the pending slot still holds our queue (timestamp match)
#   - finalize post-verifies registration + upkeep cost within [0.2x, 3x] band
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - Broadcaster must hold ORACLE_MANAGER_ROLE on SuperGovernor (or DEFAULT_ADMIN,
#     in which case the role is granted temporarily and revoked after)
#
# PRODUCTION NOTE: on mainnet, DEFAULT_ADMIN is renounced and ORACLE_MANAGER_ROLE is
# held only by the Fireblocks-managed oracle-manager signer. Use "check" and
# "simulate" modes here for rehearsal/verification; broadcast the real transactions
# via v2-toolbox: queue_oracle_update / execute_oracle_update (Fireblocks signing).
#
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Mainnet only - the migration targets the Ethereum SuperOracle
readonly CHAIN_ID=1

# Sender for simulate mode (v2 deployer keystore address)
readonly SIMULATE_SENDER="${SIMULATE_SENDER:-0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8}"

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
Usage: $0 <environment> <action> [mode] [account] [queue_timestamp]

Arguments:
    environment      Environment: "prod" or "staging" (required)
    action           Action: "check", "queue", or "finalize" (required)
    mode             "simulate" or "execute" (required for queue/finalize)
    account          Account name (required for execute mode, e.g., "v2-deployer")
    queue_timestamp  Queue timestamp from the queue step (required for finalize;
                     pass 0 to skip the clobber guard - discouraged)

Examples:
    # Read-only migration status
    $0 staging check

    # Simulate / execute the queue step
    $0 staging queue simulate
    $0 prod queue execute v2-deployer

    # Simulate / execute the finalize step (after the 1-week timelock)
    $0 prod finalize simulate 1787000000
    $0 prod finalize execute v2-deployer 1787000000

Mainnet only. Deploy BasefeeGasOracle first (deploy_basefee_gas_oracle.sh).

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

###################################################################################
# Main
###################################################################################

main() {
    if [ $# -lt 2 ]; then
        log "ERROR" "Missing required arguments"
        usage
    fi

    local environment="$1"
    local action="$2"
    local mode="${3:-}"
    local account=""
    local queue_timestamp=""

    # Validate environment
    if [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; then
        log "ERROR" "Invalid environment: $environment (must be 'staging' or 'prod')"
        exit 1
    fi

    # Validate action
    if [ "$action" != "check" ] && [ "$action" != "queue" ] && [ "$action" != "finalize" ]; then
        log "ERROR" "Invalid action: $action (must be 'check', 'queue', or 'finalize')"
        exit 1
    fi

    # check is read-only: no mode/account needed
    if [ "$action" != "check" ]; then
        if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ]; then
            log "ERROR" "Invalid or missing mode for '$action': must be 'simulate' or 'execute'"
            usage
        fi

        # Remaining args: [account] [queue_timestamp] - account for execute, timestamp for finalize
        local arg4="${4:-}"
        local arg5="${5:-}"
        if [ "$mode" = "execute" ]; then
            account="$arg4"
            queue_timestamp="$arg5"
            if [ -z "$account" ]; then
                log "ERROR" "Account name is required for execute mode"
                usage
            fi
        else
            # simulate: arg4 may be the timestamp (finalize) or an account name (ignored)
            if [[ "$arg4" =~ ^[0-9]+$ ]]; then
                queue_timestamp="$arg4"
            else
                queue_timestamp="$arg5"
            fi
        fi

        if [ "$action" = "finalize" ]; then
            if [ -z "$queue_timestamp" ] || ! [[ "$queue_timestamp" =~ ^[0-9]+$ ]]; then
                log "ERROR" "finalize requires the numeric queue_timestamp logged by the queue step"
                log "ERROR" "(pass 0 to skip the clobber guard - discouraged)"
                usage
            fi
        fi
    fi

    # Map environment to env number
    local env
    case "$environment" in
        prod) env=0 ;;
        staging) env=2 ;;
    esac

    # Load network config + Ethereum RPC
    source_network_config "$environment"
    log "INFO" "Loading RPC URLs..."
    load_rpc_urls

    local rpc_url="${ETH_MAINNET:-}"
    if [ -z "$rpc_url" ]; then
        log "ERROR" "Ethereum RPC URL not available (ETH_MAINNET empty)"
        exit 1
    fi

    log "INFO" "============================================"
    log "INFO" "Update Gas Oracle (BasefeeGasOracle migration)"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Action: $action"
    [ -n "$mode" ] && log "INFO" "Mode: $mode"
    [ -n "$queue_timestamp" ] && log "INFO" "Queue timestamp: $queue_timestamp"
    log "INFO" "Chain: Ethereum ($CHAIN_ID)"
    log "INFO" "============================================"

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" script/UpdateGasOracle.s.sol:UpdateGasOracle"

    case "$action" in
        check)
            forge_cmd+=" --sig 'runCheck(uint256,uint64)' $env $CHAIN_ID"
            ;;
        queue)
            forge_cmd+=" --sig 'runQueue(uint256,uint64)' $env $CHAIN_ID"
            ;;
        finalize)
            forge_cmd+=" --sig 'runFinalize(uint256,uint64,uint256)' $env $CHAIN_ID $queue_timestamp"
            ;;
    esac

    forge_cmd+=" --rpc-url '$rpc_url'"
    forge_cmd+=" --chain $CHAIN_ID"

    if [ "$action" != "check" ] && [ "$mode" = "execute" ]; then
        forge_cmd+=" --account $account --broadcast"
        log "INFO" "Broadcasting with account: $account"
    else
        forge_cmd+=" --sender $SIMULATE_SENDER"
        log "INFO" "Simulating with sender: $SIMULATE_SENDER"
    fi

    forge_cmd+=" -vvvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "$action failed with exit code: $exit_code"
        exit $exit_code
    fi

    log "INFO" ""
    log "INFO" "$action completed successfully"
    if [ "$action" = "queue" ] && [ "$mode" = "execute" ]; then
        log "INFO" "NEXT: save the queue timestamp from the logs above; run finalize after 1 week."
        log "INFO" "      Until then, NO other queueOracleUpdate may be submitted (global slot)."
    fi
}

main "$@"
