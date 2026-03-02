#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}  Update HyperEVM LZ Config - ETH<>HL Path${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"

if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <mode> <account>${NC}"
    echo -e "${CYAN}  mode: simulate or execute${NC}"
    echo -e "${CYAN}  account: foundry account name${NC}"
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 simulate base1${NC}"
    echo -e "${CYAN}  $0 execute base1${NC}"
    exit 1
fi

MODE=$1
ACCOUNT=$2

if [ "$MODE" != "simulate" ] && [ "$MODE" != "execute" ]; then
    echo -e "${RED}Invalid mode: $MODE (must be 'simulate' or 'execute')${NC}"
    exit 1
fi

if ! cast wallet list 2>/dev/null | sed 's/ (Local)//' | grep -q "^$ACCOUNT$"; then
    echo -e "${RED}Account '$ACCOUNT' not found in foundry wallet list${NC}"
    echo -e "${YELLOW}Available accounts:${NC}"
    cast wallet list 2>/dev/null | sed 's/ (Local)//' | sed 's/^/  - /'
    exit 1
fi

ACCOUNT_ADDRESS=$(cast wallet address --account "$ACCOUNT" 2>/dev/null)
if [ -z "$ACCOUNT_ADDRESS" ]; then
    echo -e "${RED}Could not get address for account '$ACCOUNT'${NC}"
    exit 1
fi

echo -e "${CYAN}  Account: $ACCOUNT ($ACCOUNT_ADDRESS)${NC}"

if [ "$MODE" = "simulate" ]; then
    echo -e "${YELLOW}  Mode: SIMULATION${NC}"
    BROADCAST_FLAG=""
    ACCOUNT_FLAG=""
elif [ "$MODE" = "execute" ]; then
    echo -e "${GREEN}  Mode: BROADCAST${NC}"
    BROADCAST_FLAG="--broadcast"
    ACCOUNT_FLAG="--account $ACCOUNT"
fi

# Load HyperEVM RPC
echo -e "${CYAN}  Loading HyperEVM RPC...${NC}"
if ! HYPEREVM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/HYPEREVM_RPC_URL/credential 2>/dev/null); then
    export HYPEREVM_MAINNET="https://rpc.hyperliquid.xyz/evm"
    echo -e "${YELLOW}  Using default RPC${NC}"
else
    export HYPEREVM_MAINNET
    echo -e "${GREEN}  RPC loaded from 1Password${NC}"
fi

# Satisfy foundry.toml env var references
export ETHERSCANV2_API_KEY_TEST="${ETHERSCANV2_API_KEY_TEST:-}"

cd "$PROJECT_ROOT"

echo ""
echo -e "${CYAN}  Changes:${NC}"
echo -e "${CYAN}    1. HL->ETH send config: confirmations 15 -> 1${NC}"
echo ""

if [ "$MODE" = "execute" ]; then
    echo -e "${YELLOW}  BROADCAST CONFIRMATION REQUIRED${NC}"
    read -p "$(echo -e ${YELLOW}  Type \"EXECUTE\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "EXECUTE" ]; then
        echo -e "${RED}  Aborted${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}  Running UpdateHyperEVMLZConfig.runEth()...${NC}"

forge script script/UpdateHyperEVMLZConfig.s.sol:UpdateHyperEVMLZConfig \
    --sig 'runEth()' \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    --sender $ACCOUNT_ADDRESS \
    $ACCOUNT_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}  Failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}  ETH<>HL config update complete!${NC}"
