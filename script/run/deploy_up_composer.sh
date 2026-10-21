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
    echo -e "${CYAN}║${WHITE}              🚀 UP HyperLiquid Composer Deployment Script 🚀                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_header

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ==================== Argument Parsing ====================

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
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo -e "${CYAN}  1. UP OFT deployed on HyperEVM (Step 1 - deploy_up_oft_hyperevm.sh)${NC}"
    echo -e "${CYAN}  2. CORE_INDEX_ID and ASSET_DECIMAL_DIFF set in DeployUpComposer.s.sol (from Step 3 team)${NC}"
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

# ==================== Account Validation ====================

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

# ==================== Mode Configuration ====================

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

# ==================== Load Configuration ====================

print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

echo -e "${CYAN}   • Loading HyperEVM RPC URL from 1Password...${NC}"
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
echo -e "${CYAN}   • Chain: HyperEVM (999)${NC}"

cd "$PROJECT_ROOT"

# ==================== Deployment Confirmation ====================

print_separator

if [ "$MODE" = "deploy" ]; then
    echo -e "${YELLOW}⚠️  DEPLOYMENT CONFIRMATION REQUIRED ⚠️${NC}"
    echo -e "${CYAN}You are about to deploy UpHyperLiquidComposer on HyperEVM:${NC}"
    echo -e "${CYAN}  • Environment: ${WHITE}$ENVIRONMENT${NC}"
    echo -e "${CYAN}  • Account: ${WHITE}$ACCOUNT${NC}"
    echo -e "${CYAN}  • Account Address: ${WHITE}$ACCOUNT_ADDRESS${NC}"
    echo -e "${CYAN}  • Steps:${NC}"
    echo -e "${CYAN}     1. Deploy UpHyperLiquidComposer on HyperEVM (Chain ID: 999)${NC}"
    echo -e "${CYAN}     2. Export address to JSON files${NC}"
    echo ""
    echo -e "${YELLOW}  Post-deployment (manual):${NC}"
    echo -e "${CYAN}     3. Activate Composer on HyperCore (send \$1+ USDC/HYPE to deployed address)${NC}"
    echo -e "${CYAN}     4. Verify activation via coreUserExists precompile${NC}"
    echo -e "${CYAN}     5. Test end-to-end compose flow${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"DEPLOY\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "DEPLOY" ]; then
        echo -e "${RED}❌ Deployment aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Deployment confirmed${NC}"
    print_separator
fi

# ==================== Step 1: Deploy Composer ====================

echo -e "${BLUE}🚀 Deploying UpHyperLiquidComposer on HyperEVM...${NC}"

forge script script/DeployUpComposer.s.sol:DeployUpComposer \
    --sig 'deployComposer(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy UpHyperLiquidComposer on HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ UpHyperLiquidComposer deployment complete${NC}"

# ==================== Step 2: Export Addresses ====================

print_separator

echo -e "${BLUE}📄 Exporting contract addresses to JSON...${NC}"

forge script script/DeployUpComposer.s.sol:DeployUpComposer \
    --sig 'exportAddresses(uint256)' $FORGE_ENV \
    $SENDER_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to export addresses${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Addresses exported to script/output/$ENVIRONMENT/999/UpComposer-latest.json${NC}"

# ==================== Summary ====================

print_separator

echo -e "${GREEN}🎉 UpHyperLiquidComposer Deployment Complete!${NC}"
echo -e "${CYAN}   • UpHyperLiquidComposer deployed on HyperEVM (Chain ID: 999)${NC}"
echo -e "${CYAN}   • Address exported to script/output/$ENVIRONMENT/999/UpComposer-latest.json${NC}"
echo ""
echo -e "${YELLOW}⚠️  POST-DEPLOYMENT STEPS (required before Composer is functional):${NC}"
echo -e "${CYAN}   1. Activate Composer on HyperCore:${NC}"
echo -e "${CYAN}      Send \$1+ USDC or HYPE to the deployed Composer address${NC}"
echo -e "${CYAN}   2. Verify activation:${NC}"
echo -e "${WHITE}      cast call 0x0000000000000000000000000000000000000810 \\${NC}"
echo -e "${WHITE}        \$(cast abi-encode 'f(address)' <COMPOSER_ADDRESS>) \\${NC}"
echo -e "${WHITE}        --rpc-url $HYPEREVM_MAINNET${NC}"
echo -e "${CYAN}   3. Test end-to-end compose flow from source chain${NC}"
