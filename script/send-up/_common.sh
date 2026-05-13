#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

setup() {
    MODE=${1:-simulate}
    ACCOUNT=${2:-v2-supervaults}

    if ! cast wallet list 2>/dev/null | sed 's/ (Local)//' | grep -q "^$ACCOUNT$"; then
        echo -e "${RED}Account '$ACCOUNT' not found${NC}"
        cast wallet list 2>/dev/null | sed 's/ (Local)//' | sed 's/^/  • /'
        exit 1
    fi

    ACCOUNT_ADDRESS=$(cast wallet address --account "$ACCOUNT" 2>/dev/null)
    echo -e "${GREEN}Account: $ACCOUNT ($ACCOUNT_ADDRESS)${NC}"

    if [ "$MODE" = "simulate" ]; then
        BROADCAST_FLAG=""
        SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
        ACCOUNT_FLAG=""
        echo -e "${YELLOW}Mode: simulate${NC}"
    elif [ "$MODE" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
        ACCOUNT_FLAG="--account $ACCOUNT"
        echo -e "${GREEN}Mode: execute${NC}"
    else
        echo -e "${RED}Invalid mode: $MODE (use simulate or execute)${NC}"
        exit 1
    fi
}

load_rpc() {
    local op_key=$1
    local var_name=$2
    local chain_name=$3

    echo -e "${BLUE}Loading $chain_name RPC from 1Password...${NC}"
    local rpc_url
    rpc_url=$(op read "op://5ylebqljbh3x6zomdxi3qd7tsa/$op_key/credential" 2>/dev/null) || true
    if [ -z "$rpc_url" ]; then
        echo -e "${RED}Failed to load $op_key from 1Password${NC}"
        exit 1
    fi
    eval "export $var_name=\"$rpc_url\""
    echo -e "${GREEN}$chain_name RPC loaded${NC}"
}

run_forge() {
    local script_path=$1
    local rpc_url=$2
    local chain_id=$3

    cd "$PROJECT_ROOT"

    forge script "$script_path" \
        --rpc-url "$rpc_url" \
        --chain "$chain_id" \
        $ACCOUNT_FLAG \
        $SENDER_FLAG \
        $BROADCAST_FLAG \
        -vvv

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}Done!${NC}"
}
