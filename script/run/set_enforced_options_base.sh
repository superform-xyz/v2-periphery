#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

MODE=${1:-simulate}

if [ "$MODE" != "simulate" ] && [ "$MODE" != "execute" ]; then
    echo -e "${RED}Usage: $0 <simulate|execute>${NC}"
    exit 1
fi

ACCOUNT="v2-supervaults"
ACCOUNT_ADDRESS=$(cast wallet address --account "$ACCOUNT")
echo -e "${CYAN}Account: $ACCOUNT ($ACCOUNT_ADDRESS)${NC}"

source .env

FORGE_ENV=0 # prod
RPC_URL="$BASE_RPC_URL"

OFT_OWNER="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

if [ "$MODE" = "simulate" ]; then
    echo -e "${YELLOW}Running in SIMULATION mode (from OFT owner $OFT_OWNER)${NC}"
    BROADCAST_FLAG=""
    ACCOUNT_FLAG=""
    SENDER_FLAG="--sender $OFT_OWNER"
else
    echo -e "${GREEN}Running in EXECUTE mode${NC}"
    BROADCAST_FLAG="--broadcast"
    ACCOUNT_FLAG="--account $ACCOUNT"
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"

    read -p "$(echo -e ${YELLOW}Type EXECUTE to confirm: ${NC})" confirmation
    if [ "$confirmation" != "EXECUTE" ]; then
        echo -e "${RED}Aborted${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Setting enforced options on Base for HyperEVM...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnBaseForHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $RPC_URL \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

echo -e "${GREEN}Done: Base -> HyperEVM${NC}"

echo -e "${BLUE}Setting enforced options on Base for Flare...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnBaseForFlare(uint256)' $FORGE_ENV \
    --rpc-url $RPC_URL \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

echo -e "${GREEN}Done: Base -> Flare${NC}"
echo -e "${GREEN}All enforced options set on Base${NC}"
