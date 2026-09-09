#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                     Reset OFT Peers (HyperEVM + Flare)                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# ============ Usage ============

if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <mode> <account>${NC}"
    echo -e "${CYAN}  mode: simulate or execute${NC}"
    echo -e "${CYAN}  account: foundry account name (e.g., v2-supervaults)${NC}"
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 simulate v2-supervaults${NC}"
    echo -e "${CYAN}  $0 execute v2-supervaults${NC}"
    echo -e "${CYAN}Available accounts: $(cast wallet list 2>/dev/null | sed 's/ (Local)//' | tr '\n' ' ' || echo 'Run "cast wallet list" to see available accounts')${NC}"
    exit 1
fi

MODE=$1
ACCOUNT=$2

# ============ Validate account ============

if ! cast wallet list 2>/dev/null | sed 's/ (Local)//' | grep -q "^$ACCOUNT$"; then
    echo -e "${RED}Account '$ACCOUNT' not found in foundry wallet list${NC}"
    echo -e "${YELLOW}Available accounts:${NC}"
    cast wallet list 2>/dev/null | sed 's/ (Local)//' | sed 's/^/  • /' || echo -e "${RED}  No accounts found. Run 'cast wallet import' to add accounts.${NC}"
    exit 1
fi

echo -e "${CYAN}   Getting account address...${NC}"
ACCOUNT_ADDRESS=$(cast wallet address --account "$ACCOUNT" 2>/dev/null)
if [ -z "$ACCOUNT_ADDRESS" ]; then
    echo -e "${RED}Could not get address for account '$ACCOUNT'${NC}"
    exit 1
fi
echo -e "${GREEN}   Account address: $ACCOUNT_ADDRESS${NC}"

# ============ Validate mode ============

if [ "$MODE" = "simulate" ]; then
    echo -e "${YELLOW}Running in simulation mode...${NC}"
    BROADCAST_FLAG=""
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG=""
elif [ "$MODE" = "execute" ]; then
    echo -e "${GREEN}Running in execution mode...${NC}"
    BROADCAST_FLAG="--broadcast"
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG="--account $ACCOUNT"
else
    echo -e "${RED}Invalid mode: $MODE${NC}"
    echo -e "${YELLOW}Mode must be either 'simulate' or 'execute'${NC}"
    exit 1
fi

# ============ Load RPC URLs from 1Password ============

print_separator
echo -e "${BLUE}Loading RPC URLs from 1Password...${NC}"

HYPEREVM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/HYPEREVM_RPC_URL/credential 2>/dev/null) || true
if [ -z "$HYPEREVM_MAINNET" ]; then
    echo -e "${RED}Failed to load HYPEREVM_RPC_URL from 1Password${NC}"
    exit 1
fi
export HYPEREVM_MAINNET
echo -e "${GREEN}   HyperEVM RPC loaded${NC}"

FLARE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FLARE_RPC_URL/credential 2>/dev/null) || true
if [ -z "$FLARE_MAINNET" ]; then
    echo -e "${YELLOW}   Flare RPC not found in 1Password, using public RPC${NC}"
    FLARE_MAINNET="https://flare-api.flare.network/ext/C/rpc"
fi
echo -e "${GREEN}   Flare RPC loaded${NC}"

echo -e "${GREEN}Configuration loaded successfully${NC}"
echo -e "${CYAN}   Account: $ACCOUNT ($ACCOUNT_ADDRESS)${NC}"
echo -e "${CYAN}   Mode: $MODE${NC}"

cd "$PROJECT_ROOT"

# ============ Execution confirmation ============

if [ "$MODE" = "execute" ]; then
    print_separator
    echo -e "${YELLOW}  PEER RESET CONFIRMATION REQUIRED${NC}"
    echo -e "${CYAN}You are about to reset OFT peers on:${NC}"
    echo -e "${CYAN}  1. HyperEVM (chain 999) - set peers for ETH, Base, Flare${NC}"
    echo -e "${CYAN}  2. Flare (chain 14) - set peers for ETH, Base, HyperEVM${NC}"
    echo ""
    echo -e "${RED}  WARNING: This will overwrite current peer settings!${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"RESET\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "RESET" ]; then
        echo -e "${RED}Reset aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}Reset confirmed${NC}"
fi

# ============ Step 1: Reset peers on HyperEVM ============

print_separator
echo -e "${BLUE}Resetting OFT peers on HyperEVM (chain 999)...${NC}"

forge script script/ResetOFTPeers.s.sol:ResetOFTPeersHyperEVM \
    --rpc-url "$HYPEREVM_MAINNET" \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to reset OFT peers on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}HyperEVM peers reset complete${NC}"

# ============ Step 2: Reset peers on Flare ============

print_separator
echo -e "${BLUE}Resetting OFT peers on Flare (chain 14)...${NC}"

forge script script/ResetOFTPeers.s.sol:ResetOFTPeersFlare \
    --rpc-url "$FLARE_MAINNET" \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to reset OFT peers on Flare${NC}"
    exit 1
fi
echo -e "${GREEN}Flare peers reset complete${NC}"

# ============ Step 3: Verify on-chain ============

print_separator
echo -e "${BLUE}Verifying peers on-chain...${NC}"

echo -e "${CYAN}HyperEVM peers:${NC}"
echo -ne "  ETH (30101):   "
cast call 0x642fFC3496AcA19106BAB7A42F1F221a329654fe "peers(uint32)(bytes32)" 30101 --rpc-url "$HYPEREVM_MAINNET"
echo -ne "  Base (30184):  "
cast call 0x642fFC3496AcA19106BAB7A42F1F221a329654fe "peers(uint32)(bytes32)" 30184 --rpc-url "$HYPEREVM_MAINNET"
echo -ne "  Flare (30295): "
cast call 0x642fFC3496AcA19106BAB7A42F1F221a329654fe "peers(uint32)(bytes32)" 30295 --rpc-url "$HYPEREVM_MAINNET"

echo ""
echo -e "${CYAN}Flare peers:${NC}"
echo -ne "  ETH (30101):      "
cast call 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1 "peers(uint32)(bytes32)" 30101 --rpc-url "$FLARE_MAINNET"
echo -ne "  Base (30184):     "
cast call 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1 "peers(uint32)(bytes32)" 30184 --rpc-url "$FLARE_MAINNET"
echo -ne "  HyperEVM (30367): "
cast call 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1 "peers(uint32)(bytes32)" 30367 --rpc-url "$FLARE_MAINNET"

print_separator
echo -e "${GREEN}OFT Peer Reset Complete!${NC}"
echo -e "${CYAN}   HyperEVM peers set for ETH, Base, Flare${NC}"
echo -e "${CYAN}   Flare peers set for ETH, Base, HyperEVM${NC}"
