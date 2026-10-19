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
    echo -e "${CYAN}║${WHITE}                  Update DVNs (HyperEVM + Flare) — 1 to 3 DVNs                        ${CYAN}║${NC}"
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
export FLARE_MAINNET
echo -e "${GREEN}   Flare RPC loaded${NC}"

echo -e "${GREEN}Configuration loaded successfully${NC}"
echo -e "${CYAN}   Account: $ACCOUNT ($ACCOUNT_ADDRESS)${NC}"
echo -e "${CYAN}   Mode: $MODE${NC}"

cd "$PROJECT_ROOT"

# ============ Show DVN info ============

print_separator
echo -e "${CYAN}DVN Configuration:${NC}"
echo ""
echo -e "${WHITE}  HyperEVM (3 required DVNs):${NC}"
echo -e "${CYAN}    1. Deutsche Telekom: 0x32fFd21260172518A8844feC76A88C8F239C384b${NC}"
echo -e "${CYAN}    2. LayerZero Labs:   0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f${NC}"
echo -e "${CYAN}    3. Nethermind:       0x8E49eF1DfAe17e547CA0E7526FfDA81FbaCA810A${NC}"
echo ""
echo -e "${WHITE}  Flare (3 required DVNs):${NC}"
echo -e "${CYAN}    1. Polyhedra zkBridge: 0x8ddF05F9A5c488b4973897E278B58895bF87Cb24${NC}"
echo -e "${CYAN}    2. Nethermind:         0x9bCd17A654bffAa6f8fEa38D19661a7210e22196${NC}"
echo -e "${CYAN}    3. LayerZero Labs:     0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD${NC}"
echo ""
echo -e "${YELLOW}  Note: 4th DVN (Superform) will be added after deployment${NC}"

# ============ Execution confirmation ============

if [ "$MODE" = "execute" ]; then
    print_separator
    echo -e "${YELLOW}  DVN UPDATE CONFIRMATION REQUIRED${NC}"
    echo -e "${CYAN}You are about to update DVN configs on:${NC}"
    echo -e "${CYAN}  1. HyperEVM (chain 999) - 3 DVNs x 3 pathways (ETH, Base, Flare)${NC}"
    echo -e "${CYAN}  2. Flare (chain 14) - 3 DVNs x 3 pathways (ETH, Base, HyperEVM)${NC}"
    echo ""
    echo -e "${RED}  WARNING: This will change DVN security config!${NC}"
    echo -e "${RED}  Ensure the corresponding DVN configs on ETH/Base sides match.${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"UPDATE\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "UPDATE" ]; then
        echo -e "${RED}Update aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}Update confirmed${NC}"
fi

# ============ Step 1: Update DVNs on HyperEVM ============

print_separator
echo -e "${BLUE}Updating DVN configs on HyperEVM (chain 999)...${NC}"

forge script script/UpdateDVNs.s.sol:UpdateDVNsHyperEVM \
    --rpc-url "$HYPEREVM_MAINNET" \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update DVN configs on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}HyperEVM DVN update complete${NC}"

# ============ Step 2: Update DVNs on Flare ============

print_separator
echo -e "${BLUE}Updating DVN configs on Flare (chain 14)...${NC}"

forge script script/UpdateDVNs.s.sol:UpdateDVNsFlare \
    --rpc-url "$FLARE_MAINNET" \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update DVN configs on Flare${NC}"
    exit 1
fi
echo -e "${GREEN}Flare DVN update complete${NC}"

# ============ Done ============

print_separator
echo -e "${GREEN}DVN Update Complete!${NC}"
echo -e "${CYAN}   HyperEVM: 3 DVNs (Deutsche Telekom, LZ Labs, Nethermind) x 3 pathways${NC}"
echo -e "${CYAN}   Flare: 3 DVNs (Polyhedra zkBridge, Nethermind, LZ Labs) x 3 pathways${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "${CYAN}   1. Update DVN configs on ETH/Base sides to match (3-of-3)${NC}"
echo -e "${CYAN}   2. Deploy Superform DVN on HyperEVM and Flare${NC}"
echo -e "${CYAN}   3. Add Superform DVN as 4th required DVN on all chains${NC}"
