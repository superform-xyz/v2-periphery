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
    echo -e "${CYAN}║${WHITE}                   UP OFT Ownership Transfer Script                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ $# -lt 3 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <environment> <mode> <account>${NC}"
    echo -e "${CYAN}  environment: staging or prod${NC}"
    echo -e "${CYAN}  mode: simulate or execute${NC}"
    echo -e "${CYAN}  account: foundry account name (e.g., v2-supervaults)${NC}"
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 staging simulate v2-supervaults${NC}"
    echo -e "${CYAN}  $0 prod execute v2-supervaults${NC}"
    echo -e "${CYAN}Available accounts: $(cast wallet list 2>/dev/null | sed 's/ (Local)//' | tr '\n' ' ' || echo 'Run "cast wallet list" to see available accounts')${NC}"
    exit 1
fi

ENVIRONMENT=$1
MODE=$2
ACCOUNT=$3

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo -e "${RED}Invalid environment: $ENVIRONMENT${NC}"
    echo -e "${YELLOW}Environment must be either 'staging' or 'prod'${NC}"
    exit 1
fi

if ! cast wallet list 2>/dev/null | sed 's/ (Local)//' | grep -q "^$ACCOUNT$"; then
    echo -e "${RED}Account '$ACCOUNT' not found in foundry wallet list${NC}"
    echo -e "${YELLOW}Available accounts:${NC}"
    cast wallet list 2>/dev/null | sed 's/ (Local)//' | sed 's/^/  • /' || echo -e "${RED}  No accounts found. Run 'cast wallet import' to add accounts.${NC}"
    exit 1
fi

echo -e "${CYAN}   • Getting account address...${NC}"
ACCOUNT_ADDRESS=$(cast wallet address --account "$ACCOUNT" 2>/dev/null)
if [ -z "$ACCOUNT_ADDRESS" ]; then
    echo -e "${RED}Could not get address for account '$ACCOUNT'${NC}"
    exit 1
fi
echo -e "${GREEN}   Account address: $ACCOUNT_ADDRESS${NC}"

if [ "$MODE" = "simulate" ]; then
    echo -e "${YELLOW}Running in simulation mode for $ENVIRONMENT...${NC}"
    BROADCAST_FLAG=""
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG=""
elif [ "$MODE" = "execute" ]; then
    echo -e "${GREEN}Running in execution mode for $ENVIRONMENT...${NC}"
    BROADCAST_FLAG="--broadcast"
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG="--account $ACCOUNT"
else
    echo -e "${RED}Invalid mode: $MODE${NC}"
    echo -e "${YELLOW}Mode must be either 'simulate' or 'execute'${NC}"
    exit 1
fi

print_separator
echo -e "${BLUE}Loading Configuration...${NC}"

echo -e "${CYAN}   • Loading RPC URLs from 1Password...${NC}"
if ! export ETH_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential 2>/dev/null); then
    echo -e "${RED}Failed to load ETHEREUM_RPC_URL from 1Password${NC}"
    exit 1
fi
echo -e "${GREEN}   Ethereum RPC loaded${NC}"

if ! export BASE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential 2>/dev/null); then
    echo -e "${RED}Failed to load BASE_RPC_URL from 1Password${NC}"
    exit 1
fi
echo -e "${GREEN}   Base RPC loaded${NC}"

if [ "$ENVIRONMENT" = "staging" ]; then
    FORGE_ENV=2
elif [ "$ENVIRONMENT" = "prod" ]; then
    FORGE_ENV=0
fi

echo -e "${GREEN}Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Environment: $ENVIRONMENT (env=$FORGE_ENV)${NC}"
echo -e "${CYAN}   • Account: $ACCOUNT${NC}"
echo -e "${CYAN}   • Account Address: $ACCOUNT_ADDRESS${NC}"

cd "$PROJECT_ROOT"

print_separator

if [ "$MODE" = "execute" ]; then
    echo -e "${YELLOW}  OWNERSHIP TRANSFER CONFIRMATION REQUIRED ${NC}"
    echo -e "${CYAN}You are about to transfer ownership of UP OFT contracts:${NC}"
    echo -e "${CYAN}  • Environment: ${WHITE}$ENVIRONMENT${NC}"
    echo -e "${CYAN}  • Current Owner: ${WHITE}$ACCOUNT_ADDRESS${NC}"
    echo -e "${CYAN}  • Steps:${NC}"
    echo -e "${CYAN}     1. Transfer UpOFTAdapter ownership on Ethereum (Chain ID: 1)${NC}"
    echo -e "${CYAN}     2. Transfer UpOFT ownership on Base (Chain ID: 8453)${NC}"
    echo ""
    echo -e "${RED}  WARNING: This action is irreversible!${NC}"
    echo -e "${RED}  Make sure NEW_OWNER is set correctly in TransferUpOFTOwnership.s.sol${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"TRANSFER\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "TRANSFER" ]; then
        echo -e "${RED}Transfer aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}Transfer confirmed${NC}"
    print_separator
fi

echo -e "${BLUE}Transferring UpOFTAdapter ownership on Ethereum...${NC}"

forge script script/TransferUpOFTOwnership.s.sol:TransferUpOFTOwnership \
    --sig 'transferAdapterOwnership(uint256)' $FORGE_ENV \
    --rpc-url $ETH_MAINNET \
    --chain 1 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to transfer UpOFTAdapter ownership on Ethereum${NC}"
    exit 1
fi
echo -e "${GREEN}UpOFTAdapter ownership transfer complete${NC}"

print_separator

echo -e "${BLUE}Transferring UpOFT ownership on Base...${NC}"

forge script script/TransferUpOFTOwnership.s.sol:TransferUpOFTOwnership \
    --sig 'transferOFTOwnership(uint256)' $FORGE_ENV \
    --rpc-url $BASE_MAINNET \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to transfer UpOFT ownership on Base${NC}"
    exit 1
fi
echo -e "${GREEN}UpOFT ownership transfer complete${NC}"

print_separator

echo -e "${GREEN}UP OFT Ownership Transfer Complete!${NC}"
echo -e "${CYAN}   • UpOFTAdapter ownership transferred on Ethereum${NC}"
echo -e "${CYAN}   • UpOFT ownership transferred on Base${NC}"
