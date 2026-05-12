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
    echo -e "${CYAN}║${WHITE}            Replace Horizen DVN with Superform (HyperEVM + Flare)                    ${CYAN}║${NC}"
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
echo -e "${WHITE}  HyperEVM (4 required DVNs — replacing Horizen with Superform):${NC}"
echo -e "${RED}    OLD: Canary, Nethermind, Horizen, LZ Labs${NC}"
echo -e "${GREEN}    NEW: Superform, Canary, Nethermind, LZ Labs (sorted ascending)${NC}"
echo -e "${CYAN}      1. Superform:  0x8024Cb9EF7AC7bD51994BAf25F52BD43d924A331${NC}"
echo -e "${CYAN}      2. Canary:     0x83342EC538dF0460e730a8F543Fe63063e2D44C4${NC}"
echo -e "${CYAN}      3. Nethermind: 0x8E49eF1DfAe17e547CA0E7526FfDA81FbaCA810A${NC}"
echo -e "${CYAN}      4. LZ Labs:    0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f${NC}"
echo ""
echo -e "${WHITE}  Flare (4 required DVNs — replacing Horizen with Superform):${NC}"
echo -e "${RED}    OLD: Nethermind, LZ Labs, Canary, Horizen${NC}"
echo -e "${GREEN}    NEW: Superform, Nethermind, LZ Labs, Canary (sorted ascending)${NC}"
echo -e "${CYAN}      1. Superform:  0x9B0f8cAdA2f412c17E6f848ebBd3CbDd09226A29${NC}"
echo -e "${CYAN}      2. Nethermind: 0x9bCd17A654bffAa6f8fEa38D19661a7210e22196${NC}"
echo -e "${CYAN}      3. LZ Labs:    0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD${NC}"
echo -e "${CYAN}      4. Canary:     0xD791948db16AB4373FA394B74C727DDb7FB02520${NC}"

# ============ Execution confirmation ============

if [ "$MODE" = "execute" ]; then
    print_separator
    echo -e "${YELLOW}  DVN REPLACEMENT CONFIRMATION REQUIRED${NC}"
    echo -e "${CYAN}You are about to replace Horizen DVN with Superform on:${NC}"
    echo -e "${CYAN}  1. HyperEVM (chain 999) - 4 DVNs x 3 pathways (ETH, Base, Flare) x send+receive${NC}"
    echo -e "${CYAN}  2. Flare (chain 14) - 4 DVNs x 3 pathways (ETH, Base, HyperEVM) x send+receive${NC}"
    echo ""
    echo -e "${RED}  WARNING: This will change DVN security config!${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"REPLACE\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "REPLACE" ]; then
        echo -e "${RED}Replacement aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}Replacement confirmed${NC}"
fi

# ============ Step 1: Replace DVN on HyperEVM ============

print_separator
echo -e "${BLUE}Replacing Horizen with Superform on HyperEVM (chain 999)...${NC}"

forge script script/ReplaceDVNHorizenWithSuperform.s.sol:ReplaceDVNHyperEVM \
    --rpc-url "$HYPEREVM_MAINNET" \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to replace DVN on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}HyperEVM DVN replacement complete${NC}"

# ============ Step 2: Replace DVN on Flare ============

print_separator
echo -e "${BLUE}Replacing Horizen with Superform on Flare (chain 14)...${NC}"

forge script script/ReplaceDVNHorizenWithSuperform.s.sol:ReplaceDVNFlare \
    --rpc-url "$FLARE_MAINNET" \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to replace DVN on Flare${NC}"
    exit 1
fi
echo -e "${GREEN}Flare DVN replacement complete${NC}"

# ============ Done ============

print_separator
echo -e "${GREEN}DVN Replacement Complete!${NC}"
echo -e "${CYAN}   HyperEVM: Horizen → Superform (4 DVNs x 3 pathways x send+receive)${NC}"
echo -e "${CYAN}   Flare: Horizen → Superform (4 DVNs x 3 pathways x send+receive)${NC}"
