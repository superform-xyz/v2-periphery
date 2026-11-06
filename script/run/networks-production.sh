#!/usr/bin/env bash

# Production Network Configuration for V2 Periphery Deployment
# This file contains all production network definitions (full mainnet deployment)

# Define production networks
# Format: "CHAIN_ID:NetworkName:RPC_VAR"
NETWORKS=(
    # All production networks are active. Comment a chain out to exclude it from the
    # deploy/check/estimate loops of the staging_prod runners.
    "1:Ethereum:ETH_MAINNET"
    "8453:Base:BASE_MAINNET"
    "56:BNB:BSC_MAINNET"
    "42161:Arbitrum:ARBITRUM_MAINNET"
    "10:Optimism:OPTIMISM_MAINNET"
    "137:Polygon:POLYGON_MAINNET"
    "130:Unichain:UNICHAIN_MAINNET"
    "43114:Avalanche:AVALANCHE_MAINNET"
    "80094:Berachain:BERACHAIN_MAINNET"
    "146:Sonic:SONIC_MAINNET"
    "100:Gnosis:GNOSIS_MAINNET"
    "480:Worldchain:WORLDCHAIN_MAINNET"
    "999:HyperEVM:HYPEREVM_MAINNET"
    "14:Flare:FLARE_MAINNET"
    "4663:RH:RH_MAINNET"
    "5042:Arc:ARC_MAINNET"
    "747474:Katana:KATANA_MAINNET"
)

# Network name mapping function
get_network_name() {
    local network_id=$1
    case "$network_id" in
        1)
            echo "Ethereum"
            ;;
        8453)
            echo "Base"
            ;;
        56)
            echo "BNB"
            ;;
        42161)
            echo "Arbitrum"
            ;;
        10)
            echo "Optimism"
            ;;
        137)
            echo "Polygon"
            ;;
        130)
            echo "Unichain"
            ;;
        43114)
            echo "Avalanche"
            ;;
        80094)
            echo "Berachain"
            ;;
        146)
            echo "Sonic"
            ;;
        100)
            echo "Gnosis"
            ;;
        480)
            echo "Worldchain"
            ;;
        999)
            echo "HyperEVM"
            ;;
        14)
            echo "Flare"
            ;;
        4663)
            echo "RH"
            ;;
        5042)
            echo "Arc"
            ;;
        747474)
            echo "Katana"
            ;;
        *)
            echo "ERROR: Unknown production network ID: $network_id" >&2
            return 1
            ;;
    esac
}

# Get RPC URL variable name for network
get_rpc_var() {
    local network_id=$1
    case "$network_id" in
        1)
            echo "ETH_MAINNET"
            ;;
        8453)
            echo "BASE_MAINNET"
            ;;
        56)
            echo "BSC_MAINNET"
            ;;
        42161)
            echo "ARBITRUM_MAINNET"
            ;;
        10)
            echo "OPTIMISM_MAINNET"
            ;;
        137)
            echo "POLYGON_MAINNET"
            ;;
        130)
            echo "UNICHAIN_MAINNET"
            ;;
        43114)
            echo "AVALANCHE_MAINNET"
            ;;
        80094)
            echo "BERACHAIN_MAINNET"
            ;;
        146)
            echo "SONIC_MAINNET"
            ;;
        100)
            echo "GNOSIS_MAINNET"
            ;;
        480)
            echo "WORLDCHAIN_MAINNET"
            ;;
        999)
            echo "HYPEREVM_MAINNET"
            ;;
        14)
            echo "FLARE_MAINNET"
            ;;
        4663)
            echo "RH_MAINNET"
            ;;
        5042)
            echo "ARC_MAINNET"
            ;;
        747474)
            echo "KATANA_MAINNET"
            ;;
        *)
            echo "ERROR: Unknown production network ID for RPC: $network_id" >&2
            return 1
            ;;
    esac
}

# Get RPC URL value for network
get_rpc_url() {
    local network_id=$1
    case "$network_id" in
        1)
            echo "$ETH_MAINNET"
            ;;
        8453)
            echo "$BASE_MAINNET"
            ;;
        56)
            echo "$BSC_MAINNET"
            ;;
        42161)
            echo "$ARBITRUM_MAINNET"
            ;;
        10)
            echo "$OPTIMISM_MAINNET"
            ;;
        137)
            echo "$POLYGON_MAINNET"
            ;;
        130)
            echo "$UNICHAIN_MAINNET"
            ;;
        43114)
            echo "$AVALANCHE_MAINNET"
            ;;
        80094)
            echo "$BERACHAIN_MAINNET"
            ;;
        146)
            echo "$SONIC_MAINNET"
            ;;
        100)
            echo "$GNOSIS_MAINNET"
            ;;
        480)
            echo "$WORLDCHAIN_MAINNET"
            ;;
        999)
            echo "$HYPEREVM_MAINNET"
            ;;
        14)
            echo "$FLARE_MAINNET"
            ;;
        4663)
            echo "$RH_MAINNET"
            ;;
        5042)
            echo "$ARC_MAINNET"
            ;;
        747474)
            echo "$KATANA_MAINNET"
            ;;
        *)
            echo "ERROR: Unknown production network ID for RPC: $network_id" >&2
            return 1
            ;;
    esac
}

# Validate that a network ID is supported in production
is_network_supported() {
    local network_id=$1
    for network_def in "${NETWORKS[@]}"; do
        IFS=':' read -r id _ _ <<< "$network_def"
        if [ "$id" = "$network_id" ]; then
            return 0
        fi
    done
    return 1
}

# Get all supported production network IDs
get_supported_networks() {
    for network_def in "${NETWORKS[@]}"; do
        IFS=':' read -r network_id _ _ <<< "$network_def"
        echo "$network_id"
    done
}

# Load RPC URLs from environment variables for CI
load_rpc_urls_ci() {
    echo "Loading production RPC URLs from environment variables..."

    local failed_rpcs=()

    # Load core networks from environment variables
    echo "  • Loading Ethereum RPC..."
    if [[ -n "${ETHEREUM_RPC_URL:-}" ]]; then
        export ETH_MAINNET="$ETHEREUM_RPC_URL"
    else
        failed_rpcs+=("ETHEREUM_RPC_URL")
    fi

    echo "  • Loading Base RPC..."
    if [[ -n "${BASE_RPC_URL:-}" ]]; then
        export BASE_MAINNET="$BASE_RPC_URL"
    else
        failed_rpcs+=("BASE_RPC_URL")
    fi

    echo "  • Loading BSC RPC..."
    if [[ -n "${BSC_RPC_URL:-}" ]]; then
        export BSC_MAINNET="$BSC_RPC_URL"
    else
        echo "  • BSC_RPC_URL not set, using default public RPC"
        export BSC_MAINNET="https://bsc-rpc.publicnode.com"
    fi

    echo "  • Loading Arbitrum RPC..."
    if [[ -n "${ARBITRUM_RPC_URL:-}" ]]; then
        export ARBITRUM_MAINNET="$ARBITRUM_RPC_URL"
    else
        echo "  • ARBITRUM_RPC_URL not set, using default public RPC"
        export ARBITRUM_MAINNET="https://arbitrum-one-rpc.publicnode.com"
    fi

    # Load production-only networks from environment variables
    echo "  • Loading Optimism RPC..."
    if [[ -n "${OPTIMISM_RPC_URL:-}" ]]; then
        export OPTIMISM_MAINNET="$OPTIMISM_RPC_URL"
    else
        failed_rpcs+=("OPTIMISM_RPC_URL")
    fi

    echo "  • Loading Polygon RPC..."
    if [[ -n "${POLYGON_RPC_URL:-}" ]]; then
        export POLYGON_MAINNET="$POLYGON_RPC_URL"
    else
        echo "  • POLYGON_RPC_URL not set, using default public RPC"
        export POLYGON_MAINNET="https://polygon-bor-rpc.publicnode.com"
    fi

    echo "  • Loading Unichain RPC..."
    if [[ -n "${UNICHAIN_RPC_URL:-}" ]]; then
        export UNICHAIN_MAINNET="$UNICHAIN_RPC_URL"
    else
        echo "  • UNICHAIN_RPC_URL not set, using default public RPC"
        export UNICHAIN_MAINNET="https://unichain-rpc.publicnode.com"
    fi

    echo "  • Loading Avalanche RPC..."
    if [[ -n "${AVALANCHE_RPC_URL:-}" ]]; then
        export AVALANCHE_MAINNET="$AVALANCHE_RPC_URL"
    else
        echo "  • AVALANCHE_RPC_URL not set, using default public RPC"
        export AVALANCHE_MAINNET="https://avalanche-c-chain-rpc.publicnode.com"
    fi

    echo "  • Loading Berachain RPC..."
    if [[ -n "${BERACHAIN_RPC_URL:-}" ]]; then
        export BERACHAIN_MAINNET="$BERACHAIN_RPC_URL"
    else
        echo "  • BERACHAIN_RPC_URL not set, using default public RPC"
        export BERACHAIN_MAINNET="https://rpc.berachain.com"
    fi

    echo "  • Loading Sonic RPC..."
    if [[ -n "${SONIC_RPC_URL:-}" ]]; then
        export SONIC_MAINNET="$SONIC_RPC_URL"
    else
        echo "  • SONIC_RPC_URL not set, using default public RPC"
        export SONIC_MAINNET="https://sonic-rpc.publicnode.com"
    fi

    echo "  • Loading Gnosis RPC..."
    if [[ -n "${GNOSIS_RPC_URL:-}" ]]; then
        export GNOSIS_MAINNET="$GNOSIS_RPC_URL"
    else
        echo "  • GNOSIS_RPC_URL not set, using default public RPC"
        export GNOSIS_MAINNET="https://gnosis-rpc.publicnode.com"
    fi

    echo "  • Loading Worldchain RPC..."
    if [[ -n "${WORLDCHAIN_RPC_URL:-}" ]]; then
        export WORLDCHAIN_MAINNET="$WORLDCHAIN_RPC_URL"
    else
        echo "  • WORLDCHAIN_RPC_URL not set, using default public RPC"
        export WORLDCHAIN_MAINNET="https://worldchain-mainnet.g.alchemy.com/public"
    fi

    echo "  • Loading HyperEVM RPC..."
    if [[ -n "${HYPEREVM_RPC_URL:-}" ]]; then
        export HYPEREVM_MAINNET="$HYPEREVM_RPC_URL"
    else
        echo "  • HYPEREVM_RPC_URL not set, using default RPC"
        export HYPEREVM_MAINNET="https://rpc.hyperliquid.xyz/evm"
    fi

    echo "  • Loading Flare RPC..."
    if [[ -n "${FLARE_RPC_URL:-}" ]]; then
        export FLARE_MAINNET="$FLARE_RPC_URL"
    else
        echo "  • FLARE_RPC_URL not set, using default RPC"
        export FLARE_MAINNET="https://flare-api.flare.network/ext/C/rpc"
    fi

    echo "  • Loading RH RPC..."
    if [[ -n "${RH_RPC_URL:-}" ]]; then
        export RH_MAINNET="$RH_RPC_URL"
    else
        echo "  • RH_RPC_URL not set, using default RPC"
        export RH_MAINNET="https://rpc.mainnet.chain.robinhood.com"
    fi

    echo "  • Loading Arc RPC..."
    if [[ -n "${ARC_RPC_URL:-}" ]]; then
        export ARC_MAINNET="$ARC_RPC_URL"
    else
        echo "  • ARC_RPC_URL not set, using default public RPC"
        export ARC_MAINNET="https://rpc.mainnet.arc.io"
    fi

    echo "  • Loading Katana RPC..."
    if [[ -n "${KATANA_RPC_URL:-}" ]]; then
        export KATANA_MAINNET="$KATANA_RPC_URL"
    else
        echo "  • KATANA_RPC_URL not set, using default public RPC"
        export KATANA_MAINNET="https://rpc.katana.network"
    fi

    if [[ ${#failed_rpcs[@]} -gt 0 ]]; then
        echo "❌ Failed to load the following RPC URLs from environment:"
        for failed_rpc in "${failed_rpcs[@]}"; do
            echo "   • $failed_rpc"
        done
        echo "⚠️  Some networks may not be accessible during testing"
        return 1
    fi

    echo "✅ Production RPC URLs loaded successfully from environment (Ethereum, Base, BSC, Arbitrum, Optimism, Polygon, Unichain, Avalanche, Berachain, Sonic, Gnosis, Worldchain, HyperEVM, Flare, RH, Arc, Katana)"
}

# Load RPC URLs from credential manager for all production networks
load_rpc_urls() {
    echo "Loading production RPC URLs from credential manager..."

    local failed_rpcs=()

    # Load core networks (same as staging)
    echo "  • Loading Ethereum RPC..."
    ETH_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential 2>/dev/null) || true
    if [ -z "$ETH_MAINNET" ]; then
        failed_rpcs+=("ETHEREUM_RPC_URL")
    else
        export ETH_MAINNET
    fi

    echo "  • Loading Base RPC..."
    BASE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential 2>/dev/null) || true
    if [ -z "$BASE_MAINNET" ]; then
        failed_rpcs+=("BASE_RPC_URL")
    else
        export BASE_MAINNET
    fi

    echo "  • Loading BSC RPC..."
    BSC_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BSC_RPC_URL/credential 2>/dev/null) || true
    if [ -z "$BSC_MAINNET" ]; then
        echo "  • BSC_RPC_URL not in 1Password, using default public RPC"
        export BSC_MAINNET="https://bsc-dataseed.binance.org"
    else
        export BSC_MAINNET
    fi

    echo "  • Loading Arbitrum RPC..."
    if ! export ARBITRUM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential 2>/dev/null); then
        echo "  • ARBITRUM_RPC_URL unavailable, using default public RPC"
        export ARBITRUM_MAINNET="https://arbitrum-one-rpc.publicnode.com"
    fi

    # Load production-only networks
    echo "  • Loading Optimism RPC..."
    if ! export OPTIMISM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/OPTIMISM_RPC_URL/credential 2>/dev/null); then
        failed_rpcs+=("OPTIMISM_RPC_URL")
    fi

    echo "  • Loading Polygon RPC..."
    if ! export POLYGON_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential 2>/dev/null); then
        echo "  • POLYGON_RPC_URL unavailable, using default public RPC"
        export POLYGON_MAINNET="https://polygon-bor-rpc.publicnode.com"
    fi

    echo "  • Loading Unichain RPC..."
    if ! export UNICHAIN_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/UNICHAIN_RPC_URL/credential 2>/dev/null); then
        echo "  • UNICHAIN_RPC_URL unavailable, using default public RPC"
        export UNICHAIN_MAINNET="https://unichain-rpc.publicnode.com"
    fi

    echo "  • Loading Avalanche RPC..."
    if ! export AVALANCHE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential 2>/dev/null); then
        echo "  • AVALANCHE_RPC_URL unavailable, using default public RPC"
        export AVALANCHE_MAINNET="https://avalanche-c-chain-rpc.publicnode.com"
    fi

    echo "  • Loading Berachain RPC..."
    if ! export BERACHAIN_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BERACHAIN_RPC_URL/credential 2>/dev/null); then
        echo "  • BERACHAIN_RPC_URL unavailable, using default public RPC"
        export BERACHAIN_MAINNET="https://rpc.berachain.com"
    fi

    echo "  • Loading Sonic RPC..."
    if ! export SONIC_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/SONIC_RPC_URL/credential 2>/dev/null); then
        echo "  • SONIC_RPC_URL unavailable, using default public RPC"
        export SONIC_MAINNET="https://sonic-rpc.publicnode.com"
    fi

    echo "  • Loading Gnosis RPC..."
    if ! export GNOSIS_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/GNOSIS_RPC_URL/credential 2>/dev/null); then
        echo "  • GNOSIS_RPC_URL unavailable, using default public RPC"
        export GNOSIS_MAINNET="https://gnosis-rpc.publicnode.com"
    fi

    echo "  • Loading Worldchain RPC..."
    if ! export WORLDCHAIN_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/WORLDCHAIN_RPC_URL/credential 2>/dev/null); then
        echo "  • WORLDCHAIN_RPC_URL unavailable, using default public RPC"
        export WORLDCHAIN_MAINNET="https://worldchain-mainnet.g.alchemy.com/public"
    fi

    echo "  • Loading HyperEVM RPC..."
    HYPEREVM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/HYPEREVM_RPC_URL/credential 2>/dev/null) || true
    if [ -z "$HYPEREVM_MAINNET" ]; then
        echo "  • HYPEREVM_RPC_URL not in 1Password, using default RPC"
        export HYPEREVM_MAINNET="https://rpc.hyperliquid.xyz/evm"
    else
        export HYPEREVM_MAINNET
    fi

    echo "  • Loading Flare RPC..."
    FLARE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FLARE_RPC_URL/credential 2>/dev/null) || true
    if [ -z "$FLARE_MAINNET" ]; then
        echo "  • FLARE_RPC_URL not in 1Password, using default RPC"
        export FLARE_MAINNET="https://flare-api.flare.network/ext/C/rpc"
    else
        export FLARE_MAINNET
    fi

    echo "  • Loading RH RPC..."
    RH_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/RH_RPC_URL/credential 2>/dev/null) || true
    if [ -z "$RH_MAINNET" ]; then
        echo "  • RH_RPC_URL not in 1Password, using default RPC"
        export RH_MAINNET="https://rpc.mainnet.chain.robinhood.com"
    else
        export RH_MAINNET
    fi

    echo "  • Loading Arc RPC..."
    ARC_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARC_RPC_URL/credential 2>/dev/null) || true
    if [ -z "$ARC_MAINNET" ]; then
        echo "  • ARC_RPC_URL not in 1Password, using default public RPC"
        export ARC_MAINNET="https://rpc.mainnet.arc.io"
    else
        export ARC_MAINNET
    fi

    echo "  • Loading Katana RPC..."
    # An exported KATANA_RPC_URL wins. Otherwise take the vault item, but probe it first:
    # it can resolve to a provider URL missing its auth token, which answers HTTP 401 while
    # still being non-empty -- an emptiness check passes it through and forge then fails.
    KATANA_MAINNET="${KATANA_RPC_URL:-}"
    if [ -z "$KATANA_MAINNET" ]; then
        KATANA_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/KATANA_RPC_URL/credential 2>/dev/null) || true
    fi
    if [ -n "$KATANA_MAINNET" ] && ! curl -sf --max-time 10 -X POST "$KATANA_MAINNET" \
        -H 'content-type: application/json' \
        --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' \
        | grep -q '"result"'; then
        echo "  • Configured Katana RPC did not answer eth_chainId, falling back to public RPC"
        KATANA_MAINNET=""
    fi
    if [ -z "$KATANA_MAINNET" ]; then
        echo "  • Using default public Katana RPC"
        KATANA_MAINNET="https://rpc.katana.network"
    fi
    export KATANA_MAINNET

    if [[ ${#failed_rpcs[@]} -gt 0 ]]; then
        echo "❌ Failed to load the following RPC URLs from 1Password:"
        for failed_rpc in "${failed_rpcs[@]}"; do
            echo "   • $failed_rpc"
        done
        echo "⚠️  Some networks may not be accessible during deployment"
        return 1
    fi

    echo "✅ Production RPC URLs loaded successfully (Ethereum, Base, BSC, Arbitrum, Optimism, Polygon, Unichain, Avalanche, Berachain, Sonic, Gnosis, Worldchain, HyperEVM, Flare, RH, Arc, Katana)"
}

# Load Etherscan V2 API key for verification
load_etherscan_api_key() {
    echo "Loading Etherscan V2 API key for production verification..."
    # NOTE: `export VAR=$(cmd)` always succeeds (the exit status is export's, not cmd's), which used
    # to print a green "loaded" line with an EMPTY key when the 1Password session had expired - forge
    # then failed with "a value is required for '--etherscan-api-key'". Capture, then check non-empty.
    # Honour an already-exported key (CI, or a one-off run without a 1Password session).
    if [ -n "${ETHERSCANV2_API_KEY:-}" ]; then
        export ETHERSCANV2_API_KEY
        echo "✅ Etherscan V2 API key taken from the environment"
        return 0
    fi
    ETHERSCANV2_API_KEY=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHERSCANV2_API_KEY/credential 2>/dev/null) || true
    if [ -z "$ETHERSCANV2_API_KEY" ]; then
        echo "❌ Failed to load ETHERSCANV2_API_KEY from 1Password (is the op session signed in? try: eval \$(op signin))"
        echo "   Contract verification will not work without this credential"
        return 1
    fi
    export ETHERSCANV2_API_KEY
    echo "✅ Etherscan V2 API key loaded for production"
}

# Print production network information
print_network_info() {
    echo "Production Networks Configuration:"
    for network_def in "${NETWORKS[@]}"; do
        IFS=':' read -r network_id network_name rpc_var <<< "$network_def"
        echo "  - $network_name (Chain ID: $network_id)"
    done
}
