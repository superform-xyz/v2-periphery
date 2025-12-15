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
    echo -e "${CYAN}║${WHITE}                        🚀 UP OFT Deployment Script 🚀                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ $# -lt 3 ]; then
    echo -e "${RED}❌ Error: Missing required arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <environment> <mode> <account>${NC}"
    echo -e "${CYAN}  environment: staging or prod${NC}"
    echo -e "${CYAN}  mode: simulate or deploy${NC}"
    echo -e "${CYAN}  account: foundry account name (e.g., v2-supervaults)${NC}"
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 staging simulate v2-supervaults${NC}"
    echo -e "${CYAN}  $0 prod deploy v2-supervaults${NC}"
    echo -e "${CYAN}Available accounts: $(cast wallet list 2>/dev/null | sed 's/ (Local)//' | tr '\n' ' ' || echo 'Run "cast wallet list" to see available accounts')${NC}"
    exit 1
fi

ENVIRONMENT=$1
MODE=$2
ACCOUNT=$3

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo -e "${YELLOW}Environment must be either 'staging' or 'prod'${NC}"
    exit 1
fi

if ! cast wallet list 2>/dev/null | sed 's/ (Local)//' | grep -q "^$ACCOUNT$"; then
    echo -e "${RED}❌ Account '$ACCOUNT' not found in foundry wallet list${NC}"
    echo -e "${YELLOW}Available accounts:${NC}"
    cast wallet list 2>/dev/null | sed 's/ (Local)//' | sed 's/^/  • /' || echo -e "${RED}  No accounts found. Run 'cast wallet import' to add accounts.${NC}"
    exit 1
fi

echo -e "${CYAN}   • Getting account address...${NC}"
ACCOUNT_ADDRESS=$(cast wallet address --account "$ACCOUNT" 2>/dev/null)
if [ -z "$ACCOUNT_ADDRESS" ]; then
    echo -e "${RED}❌ Could not get address for account '$ACCOUNT'${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Account address: $ACCOUNT_ADDRESS${NC}"

if [ "$MODE" = "simulate" ]; then
    echo -e "${YELLOW}🔍 Running in simulation mode for $ENVIRONMENT...${NC}"
    BROADCAST_FLAG=""
    VERIFY_FLAG=""
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG=""
elif [ "$MODE" = "deploy" ]; then
    echo -e "${GREEN}🚀 Running in deployment mode for $ENVIRONMENT...${NC}"
    BROADCAST_FLAG="--broadcast"
    VERIFY_FLAG="--verify"
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG="--account $ACCOUNT"
else
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    echo -e "${YELLOW}Mode must be either 'simulate' or 'deploy'${NC}"
    exit 1
fi

print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

echo -e "${CYAN}   • Loading RPC URLs from 1Password...${NC}"
if ! export ETH_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential 2>/dev/null); then
    echo -e "${RED}❌ Failed to load ETHEREUM_RPC_URL from 1Password${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Ethereum RPC loaded${NC}"

if ! export BASE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential 2>/dev/null); then
    echo -e "${RED}❌ Failed to load BASE_RPC_URL from 1Password${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Base RPC loaded${NC}"

echo -e "${CYAN}   • Loading Etherscan API key...${NC}"
if ! export ETHERSCANV2_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHERSCANV2_API_KEY/credential 2>/dev/null); then
    echo -e "${RED}❌ Failed to load ETHERSCANV2_API_KEY from 1Password${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ Etherscan API key loaded${NC}"

if [ "$ENVIRONMENT" = "staging" ]; then
    FORGE_ENV=2
elif [ "$ENVIRONMENT" = "prod" ]; then
    FORGE_ENV=0
fi

echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Environment: $ENVIRONMENT (env=$FORGE_ENV)${NC}"
echo -e "${CYAN}   • Account: $ACCOUNT${NC}"

cd "$PROJECT_ROOT"

print_separator

if [ "$MODE" = "deploy" ]; then
    echo -e "${YELLOW}⚠️  DEPLOYMENT CONFIRMATION REQUIRED ⚠️${NC}"
    echo -e "${CYAN}You are about to deploy UP OFT contracts:${NC}"
    echo -e "${CYAN}  • Environment: ${WHITE}$ENVIRONMENT${NC}"
    echo -e "${CYAN}  • Account: ${WHITE}$ACCOUNT${NC}"
    echo -e "${CYAN}  • Account Address: ${WHITE}$ACCOUNT_ADDRESS${NC}"
    echo -e "${CYAN}  • Steps:${NC}"
    echo -e "${CYAN}     1. Deploy UpOFTAdapter on Ethereum (Chain ID: 1)${NC}"
    echo -e "${CYAN}     2. Deploy UpOFT on Base (Chain ID: 8453)${NC}"
    echo -e "${CYAN}     3. Configure peer on Ethereum (point to Base UpOFT)${NC}"
    echo -e "${CYAN}     4. Configure peer on Base (point to Ethereum UpOFTAdapter)${NC}"
    echo -e "${CYAN}     5. Set enforced options on Ethereum${NC}"
    echo -e "${CYAN}     6. Set enforced options on Base${NC}"
    echo -e "${CYAN}     7. Configure libraries + ULN/DVN on Ethereum${NC}"
    echo -e "${CYAN}     8. Configure libraries + ULN/DVN on Base${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"DEPLOY\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "DEPLOY" ]; then
        echo -e "${RED}❌ Deployment aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Deployment confirmed${NC}"
    print_separator
fi

echo -e "${BLUE}🚀 Deploying UpOFTAdapter on Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'deployAdapter(uint256)' $FORGE_ENV \
    --rpc-url $ETH_MAINNET \
    --chain 1 \
    --etherscan-api-key $ETHERSCANV2_API_KEY \
    --verifier etherscan \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    $VERIFY_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy UpOFTAdapter on Ethereum${NC}"
    exit 1
fi
echo -e "${GREEN}✅ UpOFTAdapter deployment complete${NC}"

print_separator

echo -e "${BLUE}🚀 Deploying UpOFT on Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'deployOFT(uint256)' $FORGE_ENV \
    --rpc-url $BASE_MAINNET \
    --chain 8453 \
    --etherscan-api-key $ETHERSCANV2_API_KEY \
    --verifier etherscan \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    $VERIFY_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy UpOFT on Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ UpOFT deployment complete${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peers on Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnEthereum(uint256)' $FORGE_ENV \
    --rpc-url $ETH_MAINNET \
    --chain 1 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on Ethereum${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Ethereum peer configured${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peers on Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnBase(uint256)' $FORGE_ENV \
    --rpc-url $BASE_MAINNET \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Base peer configured${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnEthereum(uint256)' $FORGE_ENV \
    --rpc-url $ETH_MAINNET \
    --chain 1 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on Ethereum${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Ethereum enforced options set${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnBase(uint256)' $FORGE_ENV \
    --rpc-url $BASE_MAINNET \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Base enforced options set${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnEthereum(uint256)' $FORGE_ENV \
    --rpc-url $ETH_MAINNET \
    --chain 1 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on Ethereum${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Ethereum libraries + ULN configured${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnBase(uint256)' $FORGE_ENV \
    --rpc-url $BASE_MAINNET \
    --chain 8453 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Base libraries + ULN configured${NC}"

print_separator

echo -e "${GREEN}🎉 UP OFT Deployment Complete!${NC}"
echo -e "${CYAN}   • UpOFTAdapter deployed on Ethereum${NC}"
echo -e "${CYAN}   • UpOFT deployed on Base${NC}"
echo -e "${CYAN}   • Peers configured bidirectionally${NC}"
echo -e "${CYAN}   • Enforced options set on both chains${NC}"
echo -e "${CYAN}   • Libraries + ULN/DVN configured on both chains${NC}"
