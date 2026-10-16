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
    echo -e "${CYAN}║${WHITE}                   🚀 UP OFT HyperEVM Deployment Script 🚀                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

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
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG=""
elif [ "$MODE" = "deploy" ]; then
    echo -e "${GREEN}🚀 Running in deployment mode for $ENVIRONMENT...${NC}"
    BROADCAST_FLAG="--broadcast"
    SENDER_FLAG="--sender $ACCOUNT_ADDRESS"
    ACCOUNT_FLAG="--account $ACCOUNT"
else
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    echo -e "${YELLOW}Mode must be either 'simulate' or 'deploy'${NC}"
    exit 1
fi

print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

echo -e "${CYAN}   • Loading RPC URL from 1Password...${NC}"
if ! export HYPEREVM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/HYPEREVM_RPC_URL/credential 2>/dev/null); then
    echo -e "${YELLOW}⚠️  HYPEREVM_RPC_URL not in 1Password, using default RPC...${NC}"
    export HYPEREVM_MAINNET="https://rpc.hyperliquid.xyz/evm"
fi
echo -e "${GREEN}   ✅ HyperEVM RPC loaded${NC}"

# Satisfy foundry.toml [etherscan] env var references (resolved eagerly by forge on startup)
export ETHERSCANV2_API_KEY_TEST="${ETHERSCANV2_API_KEY_TEST:-}"

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
    echo -e "${CYAN}You are about to deploy UP OFT contracts on HyperEVM:${NC}"
    echo -e "${CYAN}  • Environment: ${WHITE}$ENVIRONMENT${NC}"
    echo -e "${CYAN}  • Account: ${WHITE}$ACCOUNT${NC}"
    echo -e "${CYAN}  • Account Address: ${WHITE}$ACCOUNT_ADDRESS${NC}"
    echo -e "${CYAN}  • Steps (HyperEVM side only):${NC}"
    echo -e "${CYAN}     1. Deploy UpOFT on HyperEVM (Chain ID: 999)${NC}"
    echo -e "${CYAN}     2. Configure peer on HyperEVM -> Ethereum${NC}"
    echo -e "${CYAN}     3. Configure peer on HyperEVM -> Base${NC}"
    echo -e "${CYAN}     4. Set enforced options on HyperEVM -> Ethereum${NC}"
    echo -e "${CYAN}     5. Set enforced options on HyperEVM -> Base${NC}"
    echo -e "${CYAN}     6. Configure libraries on HyperEVM -> Ethereum${NC}"
    echo -e "${CYAN}     7. Configure libraries on HyperEVM -> Base${NC}"
    echo -e "${CYAN}     8. Export addresses to JSON files${NC}"
    echo -e "${YELLOW}  NOTE: ETH/Base -> HyperEVM config requires MCP wallet (different owner)${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"DEPLOY\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "DEPLOY" ]; then
        echo -e "${RED}❌ Deployment aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Deployment confirmed${NC}"
    print_separator
fi

echo -e "${BLUE}🚀 Deploying UpOFT on HyperEVM...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'deployOFTOnHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy UpOFT on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ UpOFT deployment on HyperEVM complete${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peer on HyperEVM...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM peer configured${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peer on HyperEVM for Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnHyperEVMForBase(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on HyperEVM for Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM peer configured for Base${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on HyperEVM...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM enforced options set${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on HyperEVM for Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnHyperEVMForBase(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on HyperEVM for Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM enforced options set for Base${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on HyperEVM for Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM libraries + ULN configured${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on HyperEVM for Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnHyperEVMForBase(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on HyperEVM for Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM libraries + ULN configured for Base${NC}"

print_separator

echo -e "${BLUE}📄 Exporting contract addresses to JSON...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'exportAddresses(uint256)' $FORGE_ENV \
    $SENDER_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to export addresses${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Addresses exported to script/output/$ENVIRONMENT/999/HyperEVM-latest.json${NC}"

print_separator

echo -e "${GREEN}🎉 UP OFT HyperEVM Deployment Complete!${NC}"
echo -e "${CYAN}   • UpOFT deployed on HyperEVM (Chain ID: 999)${NC}"
echo -e "${CYAN}   • HyperEVM -> Ethereum peer configured${NC}"
echo -e "${CYAN}   • HyperEVM -> Base peer configured${NC}"
echo -e "${CYAN}   • HyperEVM -> Ethereum enforced options set${NC}"
echo -e "${CYAN}   • HyperEVM -> Base enforced options set${NC}"
echo -e "${CYAN}   • HyperEVM -> Ethereum libraries + ULN/DVN configured${NC}"
echo -e "${CYAN}   • HyperEVM -> Base libraries + ULN/DVN configured${NC}"
echo -e "${CYAN}   • Addresses exported to JSON files${NC}"
echo ""
echo -e "${YELLOW}⚠️  NEXT STEPS (require Fireblocks wallet that owns ETH/Base OFTs):${NC}"
echo -e "${CYAN}   Run the following script to complete bidirectional config:${NC}"
echo -e "${CYAN}   FIREBLOCKS_API_KEY_OP_PATH=\"op://vault/item/field\" \\${NC}"
echo -e "${CYAN}   FIREBLOCKS_SECRET_OP_PATH=\"op://vault/item/field\" \\${NC}"
echo -e "${CYAN}   ./script/run/config/configure_hyperevm_from_ethbase.sh $ENVIRONMENT execute <sender-address>${NC}"
echo -e "${CYAN}   (HyperEVM OFT address will be read from script/output/$ENVIRONMENT/999/HyperEVM-latest.json)${NC}"
