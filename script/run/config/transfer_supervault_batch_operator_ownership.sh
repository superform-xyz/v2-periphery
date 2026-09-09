#!/usr/bin/env bash

###################################################################################
# Transfer SuperVaultBatchOperator Ownership Script
###################################################################################
# Description:
#   Transfers SuperVaultBatchOperator DEFAULT_ADMIN_ROLE from deployer to
#   SUPER_GOVERNOR_ADDRESS (0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e)
#
# Usage:
#   ./transfer_supervault_batch_operator_ownership.sh <environment> <mode> <chain_id> <contract_address> [account] [--slow]
#
#   Parameters:
#     environment: "staging" or "prod"
#     mode: "simulate" or "execute"
#     chain_id: Chain ID (e.g., 8453 for Base)
#     contract_address: The deployed SuperVaultBatchOperator address
#     account: Account name (required for execute mode)
#     --slow: Optional flag for polling-based tx confirmation
#
#   Examples:
#     ./transfer_supervault_batch_operator_ownership.sh prod simulate 8453 0x3047601ea12565C65b715137799a458971BA070B
#     ./transfer_supervault_batch_operator_ownership.sh prod execute 8453 0x3047601ea12565C65b715137799a458971BA070B v2-supervaults
###################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Constants
DEPLOYER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"
SUPER_GOVERNOR_ADDRESS="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}       🔐 Transfer SuperVaultBatchOperator Ownership 🔐                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Check arguments
if [ $# -lt 4 ]; then
    echo -e "${RED}❌ Error: Missing required arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <environment> <mode> <chain_id> <contract_address> [account] [--slow]${NC}"
    echo -e "${CYAN}  environment: staging or prod${NC}"
    echo -e "${CYAN}  mode: simulate or execute${NC}"
    echo -e "${CYAN}  chain_id: Chain ID (e.g., 8453 for Base)${NC}"
    echo -e "${CYAN}  contract_address: Deployed SuperVaultBatchOperator address${NC}"
    echo -e "${CYAN}  account: Account name (required for execute mode)${NC}"
    echo -e "${CYAN}  --slow: Optional flag for polling-based tx confirmation${NC}"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 prod simulate 8453 0x3047601ea12565C65b715137799a458971BA070B${NC}"
    echo -e "${CYAN}  $0 prod execute 8453 0x3047601ea12565C65b715137799a458971BA070B v2-supervaults${NC}"
    exit 1
fi

ENVIRONMENT=$1
MODE=$2
CHAIN_ID=$3
CONTRACT_ADDRESS=$4
ACCOUNT=""
SLOW_FLAG=""

# Parse remaining arguments
shift 4
while [ $# -gt 0 ]; do
    case "$1" in
        --slow)
            SLOW_FLAG="--slow"
            ;;
        *)
            if [ -z "$ACCOUNT" ]; then
                ACCOUNT="$1"
            fi
            ;;
    esac
    shift
done

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    exit 1
fi

# Validate mode
if [ "$MODE" != "simulate" ] && [ "$MODE" != "execute" ]; then
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    exit 1
fi

# Require account for execute mode
if [ "$MODE" = "execute" ] && [ -z "$ACCOUNT" ]; then
    echo -e "${RED}❌ Account name required for execute mode${NC}"
    exit 1
fi

print_header

log "Environment: $ENVIRONMENT"
log "Mode: $MODE"
log "Chain ID: $CHAIN_ID"
log "Contract Address: $CONTRACT_ADDRESS"
log "Current Admin (Deployer): $DEPLOYER"
log "New Admin (SUPER_GOVERNOR): $SUPER_GOVERNOR_ADDRESS"
if [ -n "$ACCOUNT" ]; then
    log "Account: $ACCOUNT"
fi

# Source network config
if [ "$ENVIRONMENT" = "staging" ]; then
    source "$SCRIPT_DIR/../utils/networks-staging.sh"
    FORGE_ENV=2
else
    source "$SCRIPT_DIR/../utils/networks-production.sh"
    FORGE_ENV=0
fi

# Load RPC URLs
log "Loading RPC URLs..."
load_rpc_urls

# Get RPC URL for chain
RPC_URL=$(get_rpc_url "$CHAIN_ID")
if [ -z "$RPC_URL" ]; then
    echo -e "${RED}❌ RPC URL not found for chain $CHAIN_ID${NC}"
    exit 1
fi

log "RPC URL loaded for chain $CHAIN_ID"

# Set up forge flags
if [ "$MODE" = "execute" ]; then
    FORGE_FLAGS="--account $ACCOUNT --broadcast"

    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${WHITE}                         ⚠️  WARNING ⚠️                                              ${RED}║${NC}"
    echo -e "${RED}║${WHITE}  You are about to transfer SuperVaultBatchOperator admin role.                     ${RED}║${NC}"
    echo -e "${RED}║${WHITE}  This is a ONE-WAY operation!                                                      ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log "Operation cancelled by user"
        exit 0
    fi
else
    FORGE_FLAGS="--sender $DEPLOYER"
fi

# Change to project root
cd "$SCRIPT_DIR/../../.."

log "Executing TransferSuperVaultBatchOperatorOwnership..."

forge script script/TransferSuperVaultBatchOperatorOwnership.s.sol:TransferSuperVaultBatchOperatorOwnership \
    --sig 'run(uint256,uint64,address,address)' "$FORGE_ENV" "$CHAIN_ID" "$CONTRACT_ADDRESS" "$DEPLOYER" \
    --rpc-url "$RPC_URL" \
    $FORGE_FLAGS \
    $SLOW_FLAG \
    -vvv

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${WHITE}           🎉 SuperVaultBatchOperator Ownership Transfer Complete! 🎉               ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
