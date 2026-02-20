#!/usr/bin/env bash

###################################################################################
# Configure HyperEVM LZ Endpoint (TX 3-6)
###################################################################################
# Description:
#   Configures LayerZero Endpoint for ETH/Base -> HyperEVM OFT pathways.
#   These are TX 3-6 from the full configuration:
#     - TX 3: setSendLibrary
#     - TX 4: setReceiveLibrary
#     - TX 5: setConfig (SendLib - Executor + ULN)
#     - TX 6: setConfig (ReceiveLib - ULN only)
#
#   NOTE: TX 1-2 (setPeer, setEnforcedOptions) require the OFT owner (MPC wallet)
#         and must be executed separately via Etherscan/Basescan with Porto.
#
# Authorization:
#   These transactions can be executed by the DELEGATE (deployer address).
#   Current delegate for both OFTs: 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8
#
# Usage:
#   ./configure_hyperevm_lz_endpoint.sh <mode> [account] [chain]
#
#   Parameters:
#     mode: "simulate" or "execute"
#     account: Account name (required for execute mode, e.g., "v2-supervaults")
#     chain: Optional - "eth", "base", or "all" (default: all)
#
# Examples:
#   # Simulate on all chains
#   ./configure_hyperevm_lz_endpoint.sh simulate
#
#   # Simulate on Ethereum only
#   ./configure_hyperevm_lz_endpoint.sh simulate "" eth
#
#   # Simulate on Base only
#   ./configure_hyperevm_lz_endpoint.sh simulate "" base
#
#   # Execute on all chains
#   ./configure_hyperevm_lz_endpoint.sh execute v2-supervaults
#
#   # Execute on Ethereum only
#   ./configure_hyperevm_lz_endpoint.sh execute v2-supervaults eth
#
# Prerequisites:
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

# Deployer address (delegate for LZ Endpoint calls)
readonly DEPLOYER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

# RPC URLs (using public endpoints)
readonly ETH_RPC_URL="https://ethereum-rpc.publicnode.com"
readonly BASE_RPC_URL="https://base-rpc.publicnode.com"

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
Usage: $0 <mode> [account] [chain]

Arguments:
    mode     Mode: "simulate" or "execute" (required)
    account  Account name (required for execute mode, e.g., "v2-supervaults")
    chain    Chain to configure: "eth", "base", or "all" (default: all)

Examples:
    # Simulate on all chains
    $0 simulate

    # Simulate on Ethereum only
    $0 simulate "" eth

    # Simulate on Base only
    $0 simulate "" base

    # Execute on all chains
    $0 execute v2-supervaults

    # Execute on Ethereum only
    $0 execute v2-supervaults eth

EOF
    exit 1
}

validate_mode() {
    local mode=$1
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ]; then
        log "ERROR" "Invalid mode: $mode"
        log "ERROR" "Must be 'simulate' or 'execute'"
        exit 1
    fi
}

validate_chain() {
    local chain=$1
    if [ "$chain" != "eth" ] && [ "$chain" != "base" ] && [ "$chain" != "all" ]; then
        log "ERROR" "Invalid chain: $chain"
        log "ERROR" "Must be 'eth', 'base', or 'all'"
        exit 1
    fi
}

###################################################################################
# Configuration Functions
###################################################################################

configure_ethereum() {
    local mode=$1
    local account=$2

    log "INFO" "============================================"
    log "INFO" "Configuring Ethereum -> HyperEVM pathway"
    log "INFO" "============================================"

    local BROADCAST_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        ACCOUNT_FLAG="--account $account"
        log "INFO" "Mode: Execute (will broadcast using account: $account)"
    else
        SENDER_FLAG="--sender $DEPLOYER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $DEPLOYER)"
    fi

    local forge_cmd="forge script"
    forge_cmd+=" script/ConfigureHyperEVMLZEndpoint.s.sol:ConfigureHyperEVMLZEndpointETH"
    forge_cmd+=" --rpc-url $ETH_RPC_URL"
    forge_cmd+=" --chain 1"
    [ -n "$ACCOUNT_FLAG" ] && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ] && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ] && forge_cmd+=" $BROADCAST_FLAG"
    forge_cmd+=" -vvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Ethereum configuration failed with exit code: $exit_code"
        return $exit_code
    fi

    log "INFO" "Ethereum configuration successful!"
    return 0
}

configure_base() {
    local mode=$1
    local account=$2

    log "INFO" "============================================"
    log "INFO" "Configuring Base -> HyperEVM pathway"
    log "INFO" "============================================"

    local BROADCAST_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        ACCOUNT_FLAG="--account $account"
        log "INFO" "Mode: Execute (will broadcast using account: $account)"
    else
        SENDER_FLAG="--sender $DEPLOYER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $DEPLOYER)"
    fi

    local forge_cmd="forge script"
    forge_cmd+=" script/ConfigureHyperEVMLZEndpoint.s.sol:ConfigureHyperEVMLZEndpointBase"
    forge_cmd+=" --rpc-url $BASE_RPC_URL"
    forge_cmd+=" --chain 8453"
    [ -n "$ACCOUNT_FLAG" ] && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ] && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ] && forge_cmd+=" $BROADCAST_FLAG"
    forge_cmd+=" -vvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Base configuration failed with exit code: $exit_code"
        return $exit_code
    fi

    log "INFO" "Base configuration successful!"
    return 0
}

###################################################################################
# Main
###################################################################################

main() {
    if [ $# -lt 1 ]; then
        log "ERROR" "Missing required arguments"
        usage
    fi

    local mode="$1"
    local account="${2:-}"
    local chain="${3:-all}"

    validate_mode "$mode"
    validate_chain "$chain"

    # Validate account for execute mode
    if [ "$mode" = "execute" ]; then
        if [ -z "$account" ]; then
            log "ERROR" "Account name is required for execute mode"
            log "ERROR" "Usage: $0 execute <account_name> [chain]"
            exit 1
        fi
        log "INFO" "Using account: $account"
    fi

    log "INFO" "============================================"
    log "INFO" "HyperEVM LZ Endpoint Configuration (TX 3-6)"
    log "INFO" "============================================"
    log "INFO" "Mode: $mode"
    log "INFO" "Chain(s): $chain"
    log "INFO" "Delegate: $DEPLOYER"
    log "INFO" ""

    local eth_result=0
    local base_result=0

    # Configure based on chain selection
    if [ "$chain" = "eth" ] || [ "$chain" = "all" ]; then
        configure_ethereum "$mode" "$account" || eth_result=$?
        echo ""
    fi

    if [ "$chain" = "base" ] || [ "$chain" = "all" ]; then
        configure_base "$mode" "$account" || base_result=$?
        echo ""
    fi

    # Summary
    log "INFO" "============================================"
    log "INFO" "Summary"
    log "INFO" "============================================"

    if [ "$chain" = "eth" ] || [ "$chain" = "all" ]; then
        if [ $eth_result -eq 0 ]; then
            log "INFO" "Ethereum: SUCCESS"
        else
            log "ERROR" "Ethereum: FAILED"
        fi
    fi

    if [ "$chain" = "base" ] || [ "$chain" = "all" ]; then
        if [ $base_result -eq 0 ]; then
            log "INFO" "Base: SUCCESS"
        else
            log "ERROR" "Base: FAILED"
        fi
    fi

    log "INFO" ""
    log "INFO" "NOTE: TX 1-2 (setPeer, setEnforcedOptions) must be executed"
    log "INFO" "      separately via Porto wallet on Etherscan/Basescan."
    log "INFO" "      See: docs/HyperEVM_Configuration_Calldata.md"

    # Return failure if any chain failed
    if [ $eth_result -ne 0 ] || [ $base_result -ne 0 ]; then
        exit 1
    fi
}

main "$@"
