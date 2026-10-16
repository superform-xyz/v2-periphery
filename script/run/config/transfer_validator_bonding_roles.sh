#!/usr/bin/env bash

###################################################################################
# Transfer ValidatorBonding Roles Script
###################################################################################
# Description:
#   Transfers ValidatorBonding roles from deployer to production addresses:
#     - DEFAULT_ADMIN_ROLE → SUPER_GOVERNOR_ADDRESS (0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e)
#     - GOVERNOR_ROLE → GOVERNOR (0x9e01f41da2212C1FBc32A041CfAEF72479FA48eC)
#
# Usage:
#   ./transfer_validator_bonding_roles.sh <environment> <mode> <contract_address> [account] [--slow]
#
#   Parameters:
#     environment: "staging" or "prod"
#     mode: "simulate", "execute", or "check"
#     contract_address: The deployed ValidatorBonding address
#     account: Account name (required for execute mode)
#     --slow: Optional flag for polling-based tx confirmation
#
#   Examples:
#     # Check role status
#     ./transfer_validator_bonding_roles.sh prod check 0x1234...
#
#     # Simulate transfer
#     ./transfer_validator_bonding_roles.sh prod simulate 0x1234...
#
#     # Execute transfer
#     ./transfer_validator_bonding_roles.sh prod execute 0x1234... v2-supervaults
#
# IMPORTANT:
#   This is a one-way operation! Once roles are transferred, the deployer
#   will no longer have admin access to the ValidatorBonding contract.
#
# Author: Superform Team
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Deployer address (current admin)
readonly DEPLOYER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

# Target addresses (must match ConfigBase.sol)
readonly SUPER_GOVERNOR_ADDRESS="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"
readonly GOVERNOR="0x9e01f41da2212C1FBc32A041CfAEF72479FA48eC"

# Base chain ID (ValidatorBonding is Base-only)
readonly BASE_CHAIN_ID="8453"

###################################################################################
# Helper Functions
###################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

usage() {
    cat << EOF
Usage: $0 <environment> <mode> <contract_address> [account] [--slow]

Arguments:
    environment       Environment: "prod" or "staging" (required)
    mode              Mode: "simulate", "execute", or "check" (required)
    contract_address  Deployed ValidatorBonding address (required)
    account           Account name (required for execute mode, e.g., "v2-supervaults")
    --slow            Optional flag for polling-based tx confirmation

Examples:
    # Check role status
    $0 prod check 0x1234...

    # Simulate transfer
    $0 prod simulate 0x1234...

    # Execute transfer
    $0 prod execute 0x1234... v2-supervaults

Role Transfer:
    DEFAULT_ADMIN_ROLE → $SUPER_GOVERNOR_ADDRESS (SUPER_GOVERNOR_ADDRESS)
    GOVERNOR_ROLE      → $GOVERNOR (GOVERNOR)

EOF
    exit 1
}

###################################################################################
# Main
###################################################################################

main() {
    # Check minimum arguments
    if [ $# -lt 3 ]; then
        echo -e "${RED}Error: Missing required arguments${NC}"
        usage
    fi

    local environment="$1"
    local mode="$2"
    local contract_address="$3"
    local account=""
    local slow_flag=""

    # Parse remaining arguments
    shift 3
    while [ $# -gt 0 ]; do
        case "$1" in
            --slow)
                slow_flag="--slow"
                ;;
            *)
                if [ -z "$account" ]; then
                    account="$1"
                fi
                ;;
        esac
        shift
    done

    # Validate environment
    if [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; then
        echo -e "${RED}Invalid environment: $environment (must be 'staging' or 'prod')${NC}"
        exit 1
    fi

    # Validate mode
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ] && [ "$mode" != "check" ]; then
        echo -e "${RED}Invalid mode: $mode (must be 'simulate', 'execute', or 'check')${NC}"
        exit 1
    fi

    # Require account for execute mode
    if [ "$mode" = "execute" ] && [ -z "$account" ]; then
        echo -e "${RED}Account name required for execute mode${NC}"
        exit 1
    fi

    # Map environment to forge env number
    local forge_env
    case "$environment" in
        prod) forge_env=0 ;;
        staging) forge_env=2 ;;
    esac

    # Source network configuration
    local network_config_file
    if [ "$environment" = "staging" ]; then
        network_config_file="$SCRIPT_DIR/../utils/networks-staging.sh"
    else
        network_config_file="$SCRIPT_DIR/../utils/networks-production.sh"
    fi

    if [ ! -f "$network_config_file" ]; then
        echo -e "${RED}Network config not found: $network_config_file${NC}"
        exit 1
    fi
    source "$network_config_file"

    # Load RPC URLs
    log "Loading RPC URLs..."
    load_rpc_urls

    local rpc_url
    rpc_url=$(get_rpc_url "$BASE_CHAIN_ID")
    if [ -z "$rpc_url" ]; then
        echo -e "${RED}Base RPC URL not available${NC}"
        exit 1
    fi

    # Print header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}       Transfer ValidatorBonding Roles                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log "Environment: $environment (env=$forge_env)"
    log "Mode: $mode"
    log "ValidatorBonding: $contract_address"
    log "Current Admin (Deployer): $DEPLOYER"
    log "New Admin (SUPER_GOVERNOR_ADDRESS): $SUPER_GOVERNOR_ADDRESS"
    log "New Governor (GOVERNOR): $GOVERNOR"
    if [ -n "$account" ]; then
        log "Account: $account"
    fi
    echo ""

    # Set up forge flags
    local forge_flags=""
    local sig_func=""

    if [ "$mode" = "check" ]; then
        sig_func="runCheck(uint256,address,address)"
        forge_flags="--sender $DEPLOYER"
    elif [ "$mode" = "execute" ]; then
        sig_func="run(uint256,address,address)"
        forge_flags="--account $account --broadcast"

        echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${WHITE}                    WARNING                                  ${RED}║${NC}"
        echo -e "${RED}║${WHITE}  You are about to transfer ValidatorBonding roles.          ${RED}║${NC}"
        echo -e "${RED}║${WHITE}  This is a ONE-WAY operation!                               ${RED}║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log "Operation cancelled by user"
            exit 0
        fi
    else
        sig_func="run(uint256,address,address)"
        forge_flags="--sender $DEPLOYER"
    fi

    # Change to project root
    cd "$PROJECT_ROOT"

    log "Executing TransferValidatorBondingRoles..."
    echo ""

    forge script script/TransferValidatorBondingRoles.s.sol:TransferValidatorBondingRoles \
        --sig "$sig_func" "$forge_env" "$contract_address" "$DEPLOYER" \
        --rpc-url "$rpc_url" \
        --chain "$BASE_CHAIN_ID" \
        $forge_flags \
        $slow_flag \
        -vvv

    echo ""
    if [ "$mode" = "check" ]; then
        echo -e "${GREEN}Role check complete.${NC}"
    else
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${WHITE}       ValidatorBonding Role Transfer Complete!              ${GREEN}║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    fi
}

main "$@"
