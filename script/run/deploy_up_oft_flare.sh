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
    echo -e "${CYAN}║${WHITE}                     🚀 UP OFT Flare Deployment Script 🚀                            ${CYAN}║${NC}"
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
FLARE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FLARE_RPC_URL/credential 2>/dev/null) || true
if [ -z "$FLARE_MAINNET" ]; then
    echo -e "${YELLOW}⚠️  FLARE_RPC_URL not in 1Password, using default RPC...${NC}"
    export FLARE_MAINNET="https://flare-api.flare.network/ext/C/rpc"
else
    export FLARE_MAINNET
fi
echo -e "${GREEN}   ✅ Flare RPC loaded${NC}"

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
    echo -e "${CYAN}You are about to deploy UP OFT contracts on Flare:${NC}"
    echo -e "${CYAN}  • Environment: ${WHITE}$ENVIRONMENT${NC}"
    echo -e "${CYAN}  • Account: ${WHITE}$ACCOUNT${NC}"
    echo -e "${CYAN}  • Account Address: ${WHITE}$ACCOUNT_ADDRESS${NC}"
    echo -e "${CYAN}  • Steps:${NC}"
    echo -e "${CYAN}     1. Deploy UpOFT on Flare (Chain ID: 14)${NC}"
    echo -e "${CYAN}     2-4. Configure peers on Flare -> ETH/Base/HyperEVM${NC}"
    echo -e "${CYAN}     5-7. Set enforced options on Flare -> ETH/Base/HyperEVM${NC}"
    echo -e "${CYAN}     8-10. Configure libraries on Flare -> ETH/Base/HyperEVM${NC}"
    echo -e "${CYAN}     11-13. Configure HyperEVM -> Flare (peer, options, libraries)${NC}"
    echo -e "${CYAN}     14. Export addresses to JSON files${NC}"
    echo -e "${YELLOW}  NOTE: ETH/Base -> Flare LZ endpoint config requires delegate (ConfigureFlareLZEndpoint.s.sol)${NC}"
    echo -e "${YELLOW}        ETH/Base -> Flare peers + options require multisig${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"DEPLOY\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "DEPLOY" ]; then
        echo -e "${RED}❌ Deployment aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Deployment confirmed${NC}"
    print_separator
fi

echo -e "${BLUE}🚀 Deploying UpOFT on Flare...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'deployOFTOnFlare(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to deploy UpOFT on Flare${NC}"
    exit 1
fi
echo -e "${GREEN}✅ UpOFT deployment on Flare complete${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peer on Flare -> Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnFlare(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on Flare${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare peer configured for Ethereum${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peer on Flare -> Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnFlareForBase(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on Flare for Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare peer configured for Base${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peer on Flare -> HyperEVM...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnFlareForHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on Flare for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare peer configured for HyperEVM${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on Flare -> Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnFlare(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on Flare${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare enforced options set for Ethereum${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on Flare -> Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnFlareForBase(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on Flare for Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare enforced options set for Base${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on Flare -> HyperEVM...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnFlareForHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on Flare for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare enforced options set for HyperEVM${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on Flare -> Ethereum...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnFlare(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on Flare${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare libraries + ULN configured for Ethereum${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on Flare -> Base...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnFlareForBase(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on Flare for Base${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare libraries + ULN configured for Base${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on Flare -> HyperEVM...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnFlareForHyperEVM(uint256)' $FORGE_ENV \
    --rpc-url $FLARE_MAINNET \
    --chain 14 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on Flare for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flare libraries + ULN configured for HyperEVM${NC}"

print_separator

# ============ HyperEVM -> Flare (deployer-owned, can configure directly) ============

echo -e "${BLUE}🔧 Loading HyperEVM RPC for bidirectional config...${NC}"
if ! export HYPEREVM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/HYPEREVM_RPC_URL/credential 2>/dev/null); then
    echo -e "${YELLOW}⚠️  HYPEREVM_RPC_URL not in 1Password, using default RPC...${NC}"
    export HYPEREVM_MAINNET="https://rpc.hyperliquid.xyz/evm"
fi
echo -e "${GREEN}   ✅ HyperEVM RPC loaded${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peer on HyperEVM -> Flare...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configurePeerOnHyperEVMForFlare(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on HyperEVM for Flare${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM peer configured for Flare${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on HyperEVM -> Flare...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'setEnforcedOptionsOnHyperEVMForFlare(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on HyperEVM for Flare${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM enforced options set for Flare${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries + ULN on HyperEVM -> Flare...${NC}"

forge script script/DeployUpOFT.s.sol:DeployUpOFT \
    --sig 'configureLibrariesOnHyperEVMForFlare(uint256)' $FORGE_ENV \
    --rpc-url $HYPEREVM_MAINNET \
    --chain 999 \
    $ACCOUNT_FLAG \
    $SENDER_FLAG \
    $BROADCAST_FLAG \
    -vvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on HyperEVM for Flare${NC}"
    exit 1
fi
echo -e "${GREEN}✅ HyperEVM libraries + ULN configured for Flare${NC}"

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
echo -e "${GREEN}✅ Addresses exported to script/output/$ENVIRONMENT/14/Flare-latest.json${NC}"

print_separator

echo -e "${GREEN}🎉 UP OFT Flare Deployment Complete!${NC}"
echo -e "${CYAN}   • UpOFT deployed on Flare (Chain ID: 14)${NC}"
echo -e "${CYAN}   • Flare -> Ethereum peer configured${NC}"
echo -e "${CYAN}   • Flare -> Base peer configured${NC}"
echo -e "${CYAN}   • Flare -> HyperEVM peer configured${NC}"
echo -e "${CYAN}   • Flare -> Ethereum enforced options set${NC}"
echo -e "${CYAN}   • Flare -> Base enforced options set${NC}"
echo -e "${CYAN}   • Flare -> HyperEVM enforced options set${NC}"
echo -e "${CYAN}   • Flare -> Ethereum libraries + ULN/DVN configured${NC}"
echo -e "${CYAN}   • Flare -> Base libraries + ULN/DVN configured${NC}"
echo -e "${CYAN}   • Flare -> HyperEVM libraries + ULN/DVN configured${NC}"
echo -e "${CYAN}   • HyperEVM -> Flare peer configured (deployer-owned)${NC}"
echo -e "${CYAN}   • HyperEVM -> Flare enforced options set (deployer-owned)${NC}"
echo -e "${CYAN}   • HyperEVM -> Flare libraries + ULN/DVN configured (deployer-owned)${NC}"
echo -e "${CYAN}   • Addresses exported to JSON files${NC}"
echo ""
echo -e "${YELLOW}⚠️  NEXT STEPS (require delegate/multisig for ETH/Base OFTs):${NC}"
echo -e "${CYAN}   1. Configure LZ Endpoint for ETH -> Flare (delegate call):${NC}"
echo -e "${CYAN}      forge script script/ConfigureFlareLZEndpoint.s.sol:ConfigureFlareLZEndpointETH -f ethereum --broadcast -vvv${NC}"
echo -e "${CYAN}   2. Configure LZ Endpoint for Base -> Flare (delegate call):${NC}"
echo -e "${CYAN}      forge script script/ConfigureFlareLZEndpoint.s.sol:ConfigureFlareLZEndpointBase -f base --broadcast -vvv${NC}"
echo -e "${CYAN}   3. Configure ETH/Base -> Flare peers + enforced options via multisig${NC}"
