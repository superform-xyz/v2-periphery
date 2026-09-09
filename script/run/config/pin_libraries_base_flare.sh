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
    echo -e "${CYAN}║${WHITE}              Pin Send/Receive Libraries on Base for Flare pathway                  ${CYAN}║${NC}"
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

# ============ Load RPC URL from 1Password ============

print_separator
echo -e "${BLUE}Loading Base RPC URL from 1Password...${NC}"

BASE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential 2>/dev/null) || true
if [ -z "$BASE_MAINNET" ]; then
    echo -e "${RED}Failed to load BASE_RPC_URL from 1Password${NC}"
    exit 1
fi
export BASE_MAINNET
echo -e "${GREEN}   Base RPC loaded${NC}"

echo -e "${GREEN}Configuration loaded successfully${NC}"
echo -e "${CYAN}   Account: $ACCOUNT ($ACCOUNT_ADDRESS)${NC}"
echo -e "${CYAN}   Mode: $MODE${NC}"

cd "$PROJECT_ROOT"

# ============ Show info ============

print_separator
echo -e "${CYAN}Pin Libraries Configuration:${NC}"
echo ""
echo -e "${WHITE}  Base OFT:         0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B${NC}"
echo -e "${WHITE}  Send Library:     0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2${NC}"
echo -e "${WHITE}  Receive Library:  0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf${NC}"
echo -e "${WHITE}  Remote EID:       30295 (Flare)${NC}"

# ============ Execution confirmation ============

if [ "$MODE" = "execute" ]; then
    print_separator
    echo -e "${YELLOW}  LIBRARY PINNING CONFIRMATION REQUIRED${NC}"
    echo -e "${CYAN}You are about to pin send/receive libraries on Base for the Flare pathway.${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"PIN\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "PIN" ]; then
        echo -e "${RED}Pinning aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}Pinning confirmed${NC}"
fi

# ============ Pin libraries ============

print_separator
echo -e "${BLUE}Pinning libraries on Base for Flare pathway (chain 8453)...${NC}"

forge script script/PinLibrariesBaseFlare.s.sol:PinLibrariesBaseFlare \
    --rpc-url "$BASE_MAINNET" \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to pin libraries on Base${NC}"
    exit 1
fi

# ============ Done ============

print_separator
echo -e "${GREEN}Libraries pinned on Base for Flare pathway!${NC}"
echo -e "${CYAN}   setSendLibrary:    Base OFT -> Flare (EID 30295)${NC}"
echo -e "${CYAN}   setReceiveLibrary: Base OFT <- Flare (EID 30295)${NC}"
