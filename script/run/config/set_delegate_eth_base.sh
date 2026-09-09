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
    echo -e "${CYAN}║${WHITE}           Set LZ Delegate to SuperGovernor on ETH + Base OFTs                        ${CYAN}║${NC}"
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

ETH_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential 2>/dev/null) || true
if [ -z "$ETH_MAINNET" ]; then
    echo -e "${RED}Failed to load ETHEREUM_RPC_URL from 1Password${NC}"
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

# ============ Show info ============

print_separator
echo -e "${CYAN}Delegate Configuration:${NC}"
echo ""
echo -e "${WHITE}  New Delegate (SuperGovernor): 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e${NC}"
echo ""
echo -e "${CYAN}  ETH UpOFTAdapter: 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD${NC}"
echo -e "${CYAN}  Base UpOFT:       0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B${NC}"
echo ""
echo -e "${YELLOW}  This transfers LZ endpoint config rights to the SuperGovernor multisig.${NC}"
echo -e "${YELLOW}  After this, only the SuperGovernor can call setConfig on these OApps.${NC}"

# ============ Check current delegates ============

print_separator
echo -e "${BLUE}Checking current delegates...${NC}"

echo -ne "${CYAN}  ETH UpOFTAdapter delegate:  ${NC}"
cast call 0x1a44076050125825900e736c501f859c50fE728c "delegates(address)(address)" 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD --rpc-url "$ETH_MAINNET"

echo -ne "${CYAN}  Base UpOFT delegate:        ${NC}"
cast call 0x1a44076050125825900e736c501f859c50fE728c "delegates(address)(address)" 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B --rpc-url "$BASE_MAINNET"

# ============ Execution confirmation ============

if [ "$MODE" = "execute" ]; then
    print_separator
    echo -e "${YELLOW}  DELEGATE CHANGE CONFIRMATION REQUIRED${NC}"
    echo -e "${CYAN}You are about to set the LZ endpoint delegate to SuperGovernor on:${NC}"
    echo -e "${CYAN}  1. Ethereum UpOFTAdapter${NC}"
    echo -e "${CYAN}  2. Base UpOFT${NC}"
    echo ""
    echo -e "${RED}  WARNING: After this, only the SuperGovernor multisig can change LZ configs!${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"DELEGATE\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "DELEGATE" ]; then
        echo -e "${RED}Delegate change aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}Delegate change confirmed${NC}"
fi

# ============ Step 1: Set delegate on Ethereum ============

print_separator
echo -e "${BLUE}Setting delegate on Ethereum UpOFTAdapter (chain 1)...${NC}"

forge script script/SetDelegateETHBase.s.sol:SetDelegateETH \
    --rpc-url "$ETH_MAINNET" \
    --chain 1 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to set delegate on Ethereum${NC}"
    exit 1
fi
echo -e "${GREEN}Ethereum delegate set complete${NC}"

# ============ Step 2: Set delegate on Base ============

print_separator
echo -e "${BLUE}Setting delegate on Base UpOFT (chain 8453)...${NC}"

forge script script/SetDelegateETHBase.s.sol:SetDelegateBase \
    --rpc-url "$BASE_MAINNET" \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to set delegate on Base${NC}"
    exit 1
fi
echo -e "${GREEN}Base delegate set complete${NC}"

# ============ Verify on-chain ============

print_separator
echo -e "${BLUE}Verifying delegates on-chain...${NC}"

echo -ne "${CYAN}  ETH UpOFTAdapter delegate:  ${NC}"
cast call 0x1a44076050125825900e736c501f859c50fE728c "delegates(address)(address)" 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD --rpc-url "$ETH_MAINNET"

echo -ne "${CYAN}  Base UpOFT delegate:        ${NC}"
cast call 0x1a44076050125825900e736c501f859c50fE728c "delegates(address)(address)" 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B --rpc-url "$BASE_MAINNET"

print_separator
echo -e "${GREEN}Delegate Update Complete!${NC}"
echo -e "${CYAN}   Both OFTs now delegate to SuperGovernor: 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e${NC}"
