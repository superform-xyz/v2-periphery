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
    echo -e "${CYAN}║${WHITE}              Update DVN Send Configs on ETH + Base (4 DVNs each)                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

ETH_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential 2>/dev/null) || true
if [ -z "$ETH_MAINNET" ]; then
    echo -e "${RED}Failed to load ETH_RPC_URL from 1Password${NC}"
    exit 1
fi
export ETH_MAINNET
echo -e "${GREEN}   ETH RPC loaded${NC}"

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

# ============ Show DVN info ============

print_separator
echo -e "${CYAN}DVN Configuration:${NC}"
echo ""
echo -e "${WHITE}  Ethereum (4 required DVNs, sorted ascending):${NC}"
echo -e "${CYAN}    1. LayerZero Labs:   0x589dEDbD617e0CBcB916A9223F4d1300c294236b${NC}"
echo -e "${CYAN}    2. Superform:        0x7518f30bd5867b5fA86702556245Dead173afE46${NC}"
echo -e "${CYAN}    3. Nethermind:       0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5${NC}"
echo -e "${CYAN}    4. Google Cloud:     0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc${NC}"
echo ""
echo -e "${WHITE}  Base (4 required DVNs, sorted ascending):${NC}"
echo -e "${CYAN}    1. LayerZero Labs:   0x9e059a54699a285714207b43B055483E78FAac25${NC}"
echo -e "${CYAN}    2. Nethermind:       0xcd37CA043f8479064e10635020c65FfC005d36f6${NC}"
echo -e "${CYAN}    3. Google Cloud:     0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc${NC}"
echo -e "${CYAN}    4. Superform:        0xEb62f578497Bdc351dD650853a751135212fAF49${NC}"
echo ""
echo -e "${WHITE}  Pathways:${NC}"
echo -e "${CYAN}    ETH  -> Base, HyperEVM, Flare (15 ETH block confirmations)${NC}"
echo -e "${CYAN}    Base -> ETH, HyperEVM, Flare (10 Base block confirmations)${NC}"

# ============ Execution confirmation ============

if [ "$MODE" = "execute" ]; then
    print_separator
    echo -e "${YELLOW}  DVN UPDATE CONFIRMATION REQUIRED${NC}"
    echo -e "${CYAN}You are about to update DVN send configs on:${NC}"
    echo -e "${CYAN}  1. Ethereum (chain 1) - 4 DVNs x 3 pathways (Base, HyperEVM, Flare)${NC}"
    echo -e "${CYAN}  2. Base (chain 8453) - 4 DVNs x 3 pathways (ETH, HyperEVM, Flare)${NC}"
    echo ""
    echo -e "${RED}  WARNING: This will change DVN security config on ETH and Base!${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"UPDATE\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "UPDATE" ]; then
        echo -e "${RED}Update aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}Update confirmed${NC}"
fi

# ============ Step 1: Update DVNs on Ethereum ============

print_separator
echo -e "${BLUE}Updating DVN send configs on Ethereum (chain 1)...${NC}"

forge script script/UpdateDVNsETHBase.s.sol:UpdateDVNsETH \
    --rpc-url "$ETH_MAINNET" \
    --chain 1 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update DVN configs on Ethereum${NC}"
    exit 1
fi
echo -e "${GREEN}Ethereum DVN update complete${NC}"

# ============ Step 2: Update DVNs on Base ============

print_separator
echo -e "${BLUE}Updating DVN send configs on Base (chain 8453)...${NC}"

forge script script/UpdateDVNsETHBase.s.sol:UpdateDVNsBase \
    --rpc-url "$BASE_MAINNET" \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update DVN configs on Base${NC}"
    exit 1
fi
echo -e "${GREEN}Base DVN update complete${NC}"

# ============ Done ============

print_separator
echo -e "${GREEN}DVN Update Complete!${NC}"
echo -e "${CYAN}   Ethereum: 4 DVNs (LZ, Superform, Nethermind, Google) x 3 pathways${NC}"
echo -e "${CYAN}   Base: 4 DVNs (LZ, Nethermind, Google, Superform) x 3 pathways${NC}"
