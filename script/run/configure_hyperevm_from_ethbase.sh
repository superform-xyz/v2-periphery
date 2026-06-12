#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

###################################################################################
# Fireblocks Configuration
###################################################################################
FIREBLOCKS_POLLING_INTERVAL_MS=5000
FIREBLOCKS_TX_TIMEOUT_SECONDS=300

print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}      🔧 Configure ETH/Base -> HyperEVM (Fireblocks Wallet Required) 🔧               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

###################################################################################
# Fireblocks Helpers
###################################################################################

load_fireblocks_credentials() {
    echo -e "${CYAN}   • Loading Fireblocks credentials from 1Password...${NC}"

    if [ -z "${FIREBLOCKS_API_KEY_OP_PATH:-}" ]; then
        echo -e "${RED}❌ FIREBLOCKS_API_KEY_OP_PATH not set${NC}"
        echo -e "${YELLOW}Set the 1Password path for the Fireblocks API key${NC}"
        exit 1
    fi
    if [ -z "${FIREBLOCKS_SECRET_OP_PATH:-}" ]; then
        echo -e "${RED}❌ FIREBLOCKS_SECRET_OP_PATH not set${NC}"
        echo -e "${YELLOW}Set the 1Password path for the Fireblocks private key${NC}"
        exit 1
    fi

    export FIREBLOCKS_API_KEY=$(op read "$FIREBLOCKS_API_KEY_OP_PATH" 2>/dev/null || echo "")
    export FIREBLOCKS_API_PRIVATE_KEY_PATH=$(op read "$FIREBLOCKS_SECRET_OP_PATH" 2>/dev/null || echo "")

    if [ -n "${FIREBLOCKS_VAULT_ID:-}" ]; then
        export FIREBLOCKS_VAULT_ACCOUNT_IDS="$FIREBLOCKS_VAULT_ID"
    fi

    if [ -z "$FIREBLOCKS_API_KEY" ]; then
        echo -e "${RED}❌ Failed to load Fireblocks API key from 1Password${NC}"
        echo -e "${YELLOW}Path: $FIREBLOCKS_API_KEY_OP_PATH${NC}"
        exit 1
    fi
    if [ -z "$FIREBLOCKS_API_PRIVATE_KEY_PATH" ]; then
        echo -e "${RED}❌ Failed to load Fireblocks private key from 1Password${NC}"
        echo -e "${YELLOW}Path: $FIREBLOCKS_SECRET_OP_PATH${NC}"
        exit 1
    fi

    echo -e "${GREEN}   ✅ Fireblocks credentials loaded (API key: ${FIREBLOCKS_API_KEY:0:8}...)${NC}"
}

# Run a forge script via Fireblocks (execute) or directly (simulate)
# Arguments: $1=sig $2=args $3=rpc_url $4=chain_id
fireblocks_forge() {
    local sig=$1
    local args=$2
    local rpc_url=$3
    local chain_id=$4

    if [ "$MODE" = "simulate" ]; then
        forge script script/DeployUpOFT.s.sol:DeployUpOFT \
            --sig "$sig" $args \
            --rpc-url "$rpc_url" \
            --chain "$chain_id" \
            --sender "$SENDER_ADDRESS" \
            -vvv
    else
        local tx_hash=$(echo -n "configure_hyperevm:${sig}:${chain_id}:${SENDER_ADDRESS}:$(date +%Y%m%d)" | openssl dgst -md5 | sed 's/.*= //' | head -c 16)
        local tx_id="up-oft-hyperevm-${chain_id}-${tx_hash}"

        echo -e "${CYAN}   Fireblocks TX ID: $tx_id${NC}"

        fireblocks-json-rpc --http \
            --pollingInterval "$FIREBLOCKS_POLLING_INTERVAL_MS" \
            --externalTxId "$tx_id" \
            -- forge script script/DeployUpOFT.s.sol:DeployUpOFT \
            --sig "$sig" $args \
            --sender "$SENDER_ADDRESS" \
            --rpc-url {} \
            --broadcast \
            --unlocked \
            --timeout "$FIREBLOCKS_TX_TIMEOUT_SECONDS" \
            -vvv
    fi
}

###################################################################################
# Main Script
###################################################################################

print_header

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ $# -lt 3 ]; then
    echo -e "${RED}❌ Error: Missing required arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <environment> <mode> <sender-address>${NC}"
    echo -e "${CYAN}  environment: staging or prod${NC}"
    echo -e "${CYAN}  mode: simulate or execute${NC}"
    echo -e "${CYAN}  sender-address: address of the Fireblocks wallet that owns ETH/Base OFTs${NC}"
    echo ""
    echo -e "${CYAN}Required env vars for execute mode:${NC}"
    echo -e "${CYAN}  FIREBLOCKS_API_KEY_OP_PATH  - 1Password path for Fireblocks API key${NC}"
    echo -e "${CYAN}  FIREBLOCKS_SECRET_OP_PATH   - 1Password path for Fireblocks private key${NC}"
    echo -e "${CYAN}  FIREBLOCKS_VAULT_ID          - Fireblocks vault account ID (optional)${NC}"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 staging simulate 0x1234...abcd${NC}"
    echo -e "${CYAN}  FIREBLOCKS_API_KEY_OP_PATH=\"op://vault/item/field\" \\\\${NC}"
    echo -e "${CYAN}  FIREBLOCKS_SECRET_OP_PATH=\"op://vault/item/field\" \\\\${NC}"
    echo -e "${CYAN}  $0 prod execute 0x1234...abcd${NC}"
    exit 1
fi

ENVIRONMENT=$1
MODE=$2
SENDER_ADDRESS=$3

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo -e "${YELLOW}Environment must be either 'staging' or 'prod'${NC}"
    exit 1
fi

if [ "$MODE" != "simulate" ] && [ "$MODE" != "execute" ]; then
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    echo -e "${YELLOW}Mode must be either 'simulate' or 'execute'${NC}"
    exit 1
fi

if ! echo "$SENDER_ADDRESS" | grep -qE '^0x[0-9a-fA-F]{40}$'; then
    echo -e "${RED}❌ Invalid sender address: $SENDER_ADDRESS${NC}"
    echo -e "${YELLOW}Must be a valid 0x-prefixed Ethereum address${NC}"
    exit 1
fi

echo -e "${GREEN}   ✅ Sender address: $SENDER_ADDRESS${NC}"

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

# Satisfy foundry.toml [etherscan] env var references (resolved eagerly by forge on startup)
export ETHERSCANV2_API_KEY_TEST="${ETHERSCANV2_API_KEY_TEST:-}"

if [ "$ENVIRONMENT" = "staging" ]; then
    FORGE_ENV=2
    ENV_NAME="staging"
elif [ "$ENVIRONMENT" = "prod" ]; then
    FORGE_ENV=0
    ENV_NAME="prod"
fi

echo -e "${CYAN}   • Loading HyperEVM OFT address from deployment output...${NC}"
HYPEREVM_OFT_JSON="$PROJECT_ROOT/script/output/$ENV_NAME/999/HyperEVM-latest.json"
if [ ! -f "$HYPEREVM_OFT_JSON" ]; then
    echo -e "${RED}❌ HyperEVM OFT deployment output not found: $HYPEREVM_OFT_JSON${NC}"
    echo -e "${YELLOW}Run deploy_up_oft_hyperevm.sh first to deploy and export addresses${NC}"
    exit 1
fi
HYPEREVM_OFT_ADDRESS=$(jq -r '.UpOFT' "$HYPEREVM_OFT_JSON" 2>/dev/null)
if [ -z "$HYPEREVM_OFT_ADDRESS" ] || [ "$HYPEREVM_OFT_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Could not read UpOFT address from $HYPEREVM_OFT_JSON${NC}"
    exit 1
fi
if ! echo "$HYPEREVM_OFT_ADDRESS" | grep -qE '^0x[0-9a-fA-F]{40}$'; then
    echo -e "${RED}❌ Invalid HyperEVM OFT address in JSON: $HYPEREVM_OFT_ADDRESS${NC}"
    exit 1
fi
echo -e "${GREEN}   ✅ HyperEVM OFT address: $HYPEREVM_OFT_ADDRESS${NC}"

# Load Fireblocks credentials for execute mode
if [ "$MODE" = "execute" ]; then
    load_fireblocks_credentials
fi

echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Environment: $ENVIRONMENT (env=$FORGE_ENV)${NC}"
echo -e "${CYAN}   • Sender: $SENDER_ADDRESS${NC}"
echo -e "${CYAN}   • HyperEVM OFT: $HYPEREVM_OFT_ADDRESS${NC}"

cd "$PROJECT_ROOT"

print_separator

if [ "$MODE" = "execute" ]; then
    echo -e "${YELLOW}⚠️  CONFIGURATION CONFIRMATION REQUIRED ⚠️${NC}"
    echo -e "${CYAN}You are about to configure ETH/Base -> HyperEVM pathways:${NC}"
    echo -e "${CYAN}  • Environment: ${WHITE}$ENVIRONMENT${NC}"
    echo -e "${CYAN}  • Sender (Fireblocks): ${WHITE}$SENDER_ADDRESS${NC}"
    echo -e "${CYAN}  • HyperEVM OFT: ${WHITE}$HYPEREVM_OFT_ADDRESS${NC}"
    echo -e "${CYAN}  • Steps:${NC}"
    echo -e "${CYAN}     1. Configure peer on Ethereum -> HyperEVM${NC}"
    echo -e "${CYAN}     2. Configure peer on Base -> HyperEVM${NC}"
    echo -e "${CYAN}     3. Set enforced options on Ethereum for HyperEVM${NC}"
    echo -e "${CYAN}     4. Set enforced options on Base for HyperEVM${NC}"
    echo -e "${CYAN}     5. Configure libraries on Ethereum for HyperEVM${NC}"
    echo -e "${CYAN}     6. Configure libraries on Base for HyperEVM${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"CONFIGURE\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "CONFIGURE" ]; then
        echo -e "${RED}❌ Configuration aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Configuration confirmed${NC}"
    print_separator
fi

echo -e "${BLUE}🔧 Configuring peer on Ethereum for HyperEVM...${NC}"
fireblocks_forge \
    'configurePeerOnEthereumForHyperEVM(uint256,address)' \
    "$FORGE_ENV $HYPEREVM_OFT_ADDRESS" \
    "$ETH_MAINNET" \
    1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on Ethereum for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Ethereum peer configured for HyperEVM${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring peer on Base for HyperEVM...${NC}"
fireblocks_forge \
    'configurePeerOnBaseForHyperEVM(uint256,address)' \
    "$FORGE_ENV $HYPEREVM_OFT_ADDRESS" \
    "$BASE_MAINNET" \
    8453
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure peer on Base for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Base peer configured for HyperEVM${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on Ethereum for HyperEVM...${NC}"
fireblocks_forge \
    'setEnforcedOptionsOnEthereumForHyperEVM(uint256)' \
    "$FORGE_ENV" \
    "$ETH_MAINNET" \
    1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on Ethereum for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Ethereum enforced options set for HyperEVM${NC}"

print_separator

echo -e "${BLUE}🔧 Setting enforced options on Base for HyperEVM...${NC}"
fireblocks_forge \
    'setEnforcedOptionsOnBaseForHyperEVM(uint256)' \
    "$FORGE_ENV" \
    "$BASE_MAINNET" \
    8453
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to set enforced options on Base for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Base enforced options set for HyperEVM${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries on Ethereum for HyperEVM...${NC}"
fireblocks_forge \
    'configureLibrariesOnEthereumForHyperEVM(uint256)' \
    "$FORGE_ENV" \
    "$ETH_MAINNET" \
    1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on Ethereum for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Ethereum libraries configured for HyperEVM${NC}"

print_separator

echo -e "${BLUE}🔧 Configuring libraries on Base for HyperEVM...${NC}"
fireblocks_forge \
    'configureLibrariesOnBaseForHyperEVM(uint256)' \
    "$FORGE_ENV" \
    "$BASE_MAINNET" \
    8453
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to configure libraries on Base for HyperEVM${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Base libraries configured for HyperEVM${NC}"

print_separator

echo -e "${GREEN}🎉 ETH/Base -> HyperEVM Configuration Complete!${NC}"
echo -e "${CYAN}   • Ethereum -> HyperEVM peer configured${NC}"
echo -e "${CYAN}   • Base -> HyperEVM peer configured${NC}"
echo -e "${CYAN}   • Ethereum -> HyperEVM enforced options set${NC}"
echo -e "${CYAN}   • Base -> HyperEVM enforced options set${NC}"
echo -e "${CYAN}   • Ethereum -> HyperEVM libraries + ULN/DVN configured${NC}"
echo -e "${CYAN}   • Base -> HyperEVM libraries + ULN/DVN configured${NC}"
echo ""
echo -e "${GREEN}🔗 Bidirectional configuration is now complete:${NC}"
echo -e "${CYAN}   • ETH <-> HyperEVM${NC}"
echo -e "${CYAN}   • Base <-> HyperEVM${NC}"
