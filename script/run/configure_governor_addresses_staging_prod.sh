#!/usr/bin/env bash

###################################################################################
# Configure SuperGovernor Core Addresses Script
###################################################################################
# Description:
#   This script registers core contract addresses (SUPER_VAULT_AGGREGATOR,
#   SUPER_ORACLE, SUPER_BANK) in SuperGovernor after deployment.
#
#   Use this when the deployment script exits early because all contracts are
#   already deployed, but the configuration step was never run.
#
# Usage:
#   ./configure_governor_addresses_staging_prod.sh <environment> <mode> [account]
#
# Examples:
#   ./configure_governor_addresses_staging_prod.sh staging simulate
#   ./configure_governor_addresses_staging_prod.sh prod configure v2
###################################################################################

set -euo pipefail

# ===== NETWORK FILTER CONFIGURATION =====
# Networks to SKIP (these are already configured)
# Comment out networks you want to configure
SKIP_NETWORKS=(
    "1"      # Ethereum - already configured
    "8453"   # Base - already configured
)

# Function to check if a network should be skipped
should_skip_network() {
    local network_id=$1
    for skip_id in "${SKIP_NETWORKS[@]}"; do
        if [ "$network_id" = "$skip_id" ]; then
            return 0  # Should skip
        fi
    done
    return 1  # Should not skip
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}           Configure SuperGovernor Core Addresses                                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_header

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 <environment> <mode> [account]${NC}"
    echo -e "${CYAN}  environment: staging or prod${NC}"
    echo -e "${CYAN}  mode: simulate or configure${NC}"
    echo -e "${CYAN}  account: foundry account (required for configure mode)${NC}"
    exit 1
fi

ENVIRONMENT=$1
MODE=$2
ACCOUNT="${3:-}"

# Validate environment
if [ "$ENVIRONMENT" = "staging" ]; then
    echo -e "${CYAN}Loading staging network configuration...${NC}"
    source "$SCRIPT_DIR/networks-staging.sh"
    FORGE_ENV=2
elif [ "$ENVIRONMENT" = "prod" ]; then
    echo -e "${CYAN}Loading production network configuration...${NC}"
    source "$SCRIPT_DIR/networks-production.sh"
    FORGE_ENV=0
else
    echo -e "${RED}Invalid environment: $ENVIRONMENT${NC}"
    exit 1
fi

# Set up forge flags
if [ "$MODE" = "simulate" ]; then
    echo -e "${YELLOW}Running in SIMULATION mode (no broadcast)${NC}"
    BROADCAST_FLAG=""
    SENDER_FLAG="--sender 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"
    ACCOUNT_FLAG=""
elif [ "$MODE" = "configure" ]; then
    if [ -z "$ACCOUNT" ]; then
        echo -e "${RED}Account required for configure mode${NC}"
        exit 1
    fi
    echo -e "${GREEN}Running in CONFIGURE mode (will broadcast)${NC}"
    BROADCAST_FLAG="--broadcast"
    SENDER_FLAG=""
    ACCOUNT_FLAG="--account $ACCOUNT"
else
    echo -e "${RED}Invalid mode: $MODE${NC}"
    exit 1
fi

# Load RPC URLs
echo -e "${CYAN}Loading RPC URLs...${NC}"
if ! load_rpc_urls; then
    echo -e "${RED}Failed to load RPC URLs${NC}"
    exit 1
fi

cd "$PROJECT_ROOT"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Display skip list
if [ ${#SKIP_NETWORKS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Networks to skip: ${SKIP_NETWORKS[*]}${NC}"
    echo -e "${CYAN}(Edit SKIP_NETWORKS in script to change)${NC}"
fi
echo ""

# Configure each network
for network_def in "${NETWORKS[@]}"; do
    IFS=':' read -r network_id network_name rpc_var <<< "$network_def"

    # Check if network should be skipped
    if should_skip_network "$network_id"; then
        echo -e "${YELLOW}SKIP: $network_name (Chain ID: $network_id) - in SKIP_NETWORKS list${NC}"
        continue
    fi

    echo -e "${CYAN}Configuring SuperGovernor on $network_name (Chain ID: $network_id)...${NC}"

    rpc_url="${!rpc_var}"
    if [ -z "$rpc_url" ]; then
        echo -e "${RED}  RPC URL not set for $network_name, skipping${NC}"
        continue
    fi

    # Skip etherscan verification for HyperEVM
    VERIFY_FLAGS=""
    SLOW_FLAG=""
    if [ "$network_id" = "999" ]; then
        SLOW_FLAG="--slow"
    fi

    if forge script script/ConfigureGovernorAddresses.s.sol:ConfigureGovernorAddresses \
        --sig 'run(uint256,uint64)' $FORGE_ENV $network_id \
        --rpc-url "$rpc_url" \
        --chain $network_id \
        $ACCOUNT_FLAG \
        $SENDER_FLAG \
        $BROADCAST_FLAG \
        $SLOW_FLAG \
        -vvv; then
        echo -e "${GREEN}✅ Successfully configured $network_name${NC}"
    else
        echo -e "${RED}❌ Failed to configure $network_name${NC}"
    fi

    echo ""
done

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${WHITE}                     Configuration Complete                                           ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
