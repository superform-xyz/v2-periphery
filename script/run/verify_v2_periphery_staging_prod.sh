#!/usr/bin/env bash

# ===== CHAIN FILTER CONFIGURATION =====
# Specify which chains to verify (comment out to verify all chains)
# Leave empty array to verify all chains from network configuration
CHAINS_TO_VERIFY=()

# ===== CONTRACT FILTER CONFIGURATION =====
# Specify which contracts to verify (comment out to verify all contracts)
# Leave empty array to verify all contracts found in deployment JSON
CONTRACTS_TO_VERIFY=()

# Colors for better visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored header
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}║${WHITE}                   🔍 V2 Periphery Contract Verification 🔍                          ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print section separator
print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print network header
print_network_header() {
    local network=$1
    echo -e "${PURPLE}╭─────────────────────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│${WHITE}                         🌐 Verifying on ${network} Network 🌐                          ${PURPLE}│${NC}"
    echo -e "${PURPLE}╰─────────────────────────────────────────────────────────────────────────────────────╯${NC}"
}

print_header

# Script directory and project root setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check if arguments are provided
if [ $# -lt 1 ]; then
    echo -e "${RED}❌ Error: Missing required argument${NC}"
    echo -e "${YELLOW}Usage: $0 <environment>${NC}"
    echo -e "${CYAN}  environment: staging or prod${NC}"
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 staging${NC}"
    echo -e "${CYAN}  $0 prod${NC}"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment and source appropriate network configuration
if [ "$ENVIRONMENT" = "staging" ]; then
    echo -e "${CYAN}🌐 Loading staging network configuration...${NC}"
    source "$SCRIPT_DIR/networks-staging.sh"
elif [ "$ENVIRONMENT" = "prod" ]; then
    echo -e "${CYAN}🌐 Loading production network configuration...${NC}"
    source "$SCRIPT_DIR/networks-production.sh"
else
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo -e "${YELLOW}Environment must be either 'staging' or 'prod'${NC}"
    exit 1
fi

echo -e "${CYAN}✅ Network configuration loaded for $ENVIRONMENT environment${NC}"
print_network_info

print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

# Load RPC URLs using network-specific function
echo -e "${CYAN}   • Loading RPC URLs...${NC}"
if ! load_rpc_urls; then
    echo -e "${RED}❌ Failed to load some RPC URLs from credential manager${NC}"
    echo -e "${YELLOW}⚠️  This may cause connectivity issues during verification${NC}"
    echo -e "${YELLOW}   Please ensure all required RPC URLs are configured in 1Password${NC}"
    exit 1
fi

# Load Etherscan V2 API key for verification
echo -e "${CYAN}   • Loading Etherscan V2 API credentials...${NC}"
if ! load_etherscan_api_key; then
    echo -e "${RED}❌ Failed to load Etherscan V2 API key${NC}"
    echo -e "${RED}   Contract verification will not work without this credential${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Using Etherscan V2 verification${NC}"
echo -e "${CYAN}   • Environment: $ENVIRONMENT${NC}"

print_separator

# Get network suffix from chain id
get_network_suffix() {
    local chain_id=$1
    case $chain_id in
        "1") echo "Ethereum-latest" ;;
        "8453") echo "Base-latest" ;;
        "56") echo "BNB-latest" ;;
        "42161") echo "Arbitrum-latest" ;;
        "10") echo "Optimism-latest" ;;
        "137") echo "Polygon-latest" ;;
        "130") echo "Unichain-latest" ;;
        "43114") echo "Avalanche-latest" ;;
        "80094") echo "Berachain-latest" ;;
        "146") echo "Sonic-latest" ;;
        "100") echo "Gnosis-latest" ;;
        "480") echo "Worldchain-latest" ;;
        "999") echo "HyperEVM-latest" ;;
        *)
            local network_name=$(get_network_name "$chain_id")
            echo "${network_name}-latest"
            ;;
    esac
}

# Function to get contract address from JSON
get_contract_address() {
    local chain_id=$1
    local contract_name=$2
    local json_file=$3

    if [ -f "$json_file" ]; then
        local address=$(jq -r ".$contract_name // empty" "$json_file")
        echo "$address"
    else
        echo ""
    fi
}

# Function to get contract source file path
get_contract_source() {
    local contract_name=$1

    case $contract_name in
        # Oracles
        "SuperOracle") echo "src/oracles/SuperOracle.sol" ;;
        "SuperOracleL2") echo "src/oracles/SuperOracleL2.sol" ;;
        "SuperformGasOracle") echo "src/oracles/SuperformGasOracle.sol" ;;
        "FixedPriceOracle") echo "src/oracles/FixedPriceOracle.sol" ;;
        "ECDSAPPSOracle") echo "src/oracles/ECDSAPPSOracle.sol" ;;
        "PendlePTAmortizedOracle") echo "src/oracles/vaults/PendlePTAmortizedOracle.sol" ;;

        # SuperVault
        "SuperVault") echo "src/SuperVault/SuperVault.sol" ;;
        "SuperVaultAggregator") echo "src/SuperVault/SuperVaultAggregator.sol" ;;
        "SuperVaultEscrow") echo "src/SuperVault/SuperVaultEscrow.sol" ;;
        "SuperVaultStrategy") echo "src/SuperVault/SuperVaultStrategy.sol" ;;
        "SuperVaultBatchOperator") echo "src/SuperVault/SuperVaultBatchOperator.sol" ;;

        # Core
        "SuperBank") echo "src/SuperBank.sol" ;;
        "SuperGovernor") echo "src/SuperGovernor.sol" ;;

        # UP Token
        "UpOFT") echo "src/UP/UpOFT.sol" ;;
        "UpOFTAdapter") echo "src/UP/UpOFTAdapter.sol" ;;
        "Up") echo "src/UP/Up.sol" ;;

        *) echo "src/unknown/$contract_name.sol" ;;
    esac
}

# Function to generate constructor arguments based on deployment logic
generate_constructor_args() {
    local contract_name=$1
    local chain_id=$2
    local json_file=$3

    # Generate constructor arguments based on contract type
    case $contract_name in
        # Contracts with no constructor args
        "FixedPriceOracle"|"ECDSAPPSOracle"|"PendlePTAmortizedOracle"|"SuperOracle"|"SuperOracleL2")
            echo ""
            ;;

        # SuperVault contracts - typically have constructor args but need to check deployment scripts
        # These are upgradeable proxies, so the implementation contracts have no constructor args
        "SuperVault"|"SuperVaultAggregator"|"SuperVaultEscrow"|"SuperVaultStrategy"|"SuperBank"|"SuperGovernor"|"SuperVaultBatchOperator")
            echo ""
            ;;

        # SuperformGasOracle - special constructor (owner, decimals, description)
        "SuperformGasOracle")
            # This is typically deployed with specific args, but we'd need them from deployment
            echo ""
            ;;

        # UpOFT - LayerZero OFT, needs endpoint address
        "UpOFT")
            local lz_endpoint=""
            case $chain_id in
                "1") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # Ethereum LZ V2
                "8453") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # Base LZ V2
                "42161") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # Arbitrum LZ V2
                "10") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # Optimism LZ V2
                "137") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # Polygon LZ V2
                "43114") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # Avalanche LZ V2
                "56") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # BSC LZ V2
                "999") lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # HyperEVM LZ V2
                *) lz_endpoint="0x1a44076050125825900e736c501f859c50fE728c" ;;  # Default LZ V2
            esac
            # UpOFT constructor: (string name, string symbol, address lzEndpoint, address delegate)
            # Need to determine delegate address - typically the deployer or a multisig
            local delegate="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"  # Default delegate
            echo "$(cast abi-encode "constructor(string,string,address,address)" "UP" "UP" "$lz_endpoint" "$delegate")"
            ;;

        # All other contracts (no constructor args)
        *)
            echo ""
            ;;
    esac
}

# Function to verify a single contract
verify_contract() {
    local chain_id=$1
    local contract_name=$2
    local contract_address=$3
    local constructor_args=$4
    local source_file=$5
    local rpc_url=$6

    echo -e "${YELLOW}   🔍 Verifying $contract_name...${NC}"
    echo -e "${CYAN}      Address: $contract_address${NC}"
    echo -e "${CYAN}      Source: $source_file${NC}"
    echo -e "${CYAN}      Chain ID: $chain_id${NC}"

    local verify_cmd="forge verify-contract \"$contract_address\" \"$source_file:$contract_name\" --rpc-url \"$rpc_url\" --chain \"$chain_id\" --etherscan-api-key \"$ETHERSCANV2_API_KEY\" --verifier etherscan"

    if [ -n "$constructor_args" ]; then
        echo -e "${CYAN}      Constructor args: $constructor_args${NC}"
        verify_cmd="$verify_cmd --constructor-args \"$constructor_args\""
    fi

    eval $verify_cmd

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   ✅ $contract_name verified successfully${NC}"
    else
        echo -e "${RED}   ❌ $contract_name verification failed${NC}"
    fi

    echo ""
}

# Function to verify contracts from a single JSON file
verify_json_file() {
    local chain_id=$1
    local json_file=$2
    local rpc_url=$3
    local file_type=$4

    if [ ! -f "$json_file" ]; then
        return 0
    fi

    echo -e "${CYAN}   📄 Processing: $(basename "$json_file")${NC}"

    case $file_type in
        "main")
            # Standard JSON with contract_name: address format
            local all_contract_names=($(jq -r 'keys[]' "$json_file" 2>/dev/null))

            if [ ${#all_contract_names[@]} -eq 0 ]; then
                echo -e "${YELLOW}      ⚠️  No contracts found in file${NC}"
                return 0
            fi

            local contract_names=()

            # Apply contract filter if specified
            if [ ${#CONTRACTS_TO_VERIFY[@]} -eq 0 ]; then
                contract_names=("${all_contract_names[@]}")
            else
                for contract_name in "${CONTRACTS_TO_VERIFY[@]}"; do
                    for deployed_contract in "${all_contract_names[@]}"; do
                        if [ "$deployed_contract" = "$contract_name" ]; then
                            contract_names+=("$contract_name")
                            break
                        fi
                    done
                done
            fi

            for contract_name in "${contract_names[@]}"; do
                local contract_address=$(get_contract_address "$chain_id" "$contract_name" "$json_file")

                if [ -z "$contract_address" ] || [ "$contract_address" = "null" ]; then
                    echo -e "${YELLOW}      ⚠️  Skipping $contract_name (address not found)${NC}"
                    continue
                fi

                local constructor_args=$(generate_constructor_args "$contract_name" "$chain_id" "$json_file")
                local source_file=$(get_contract_source "$contract_name")

                verify_contract "$chain_id" "$contract_name" "$contract_address" "$constructor_args" "$source_file" "$rpc_url"
            done
            ;;

        "gas_oracle")
            # SuperformGasOracle JSON format: { address, chainId, decimals, description, owner }
            local contract_address=$(jq -r '.address // empty' "$json_file")
            if [ -n "$contract_address" ] && [ "$contract_address" != "null" ]; then
                # Check if we should verify this contract based on filter
                local should_verify=true
                if [ ${#CONTRACTS_TO_VERIFY[@]} -gt 0 ]; then
                    should_verify=false
                    for filter_contract in "${CONTRACTS_TO_VERIFY[@]}"; do
                        if [ "$filter_contract" = "SuperformGasOracle" ]; then
                            should_verify=true
                            break
                        fi
                    done
                fi

                if [ "$should_verify" = true ]; then
                    local source_file=$(get_contract_source "SuperformGasOracle")
                    local constructor_args=$(generate_constructor_args "SuperformGasOracle" "$chain_id" "$json_file")
                    verify_contract "$chain_id" "SuperformGasOracle" "$contract_address" "$constructor_args" "$source_file" "$rpc_url"
                fi
            fi
            ;;

        "up_oft")
            # UpOFT JSON format: { UpOFT: address }
            local contract_address=$(jq -r '.UpOFT // empty' "$json_file")
            if [ -n "$contract_address" ] && [ "$contract_address" != "null" ]; then
                # Check if we should verify this contract based on filter
                local should_verify=true
                if [ ${#CONTRACTS_TO_VERIFY[@]} -gt 0 ]; then
                    should_verify=false
                    for filter_contract in "${CONTRACTS_TO_VERIFY[@]}"; do
                        if [ "$filter_contract" = "UpOFT" ]; then
                            should_verify=true
                            break
                        fi
                    done
                fi

                if [ "$should_verify" = true ]; then
                    local source_file=$(get_contract_source "UpOFT")
                    local constructor_args=$(generate_constructor_args "UpOFT" "$chain_id" "$json_file")
                    verify_contract "$chain_id" "UpOFT" "$contract_address" "$constructor_args" "$source_file" "$rpc_url"
                fi
            fi
            ;;

        "super_vault_batch_operator")
            # SuperVaultBatchOperator JSON format: { address, admin, chainId, operator }
            local contract_address=$(jq -r '.address // empty' "$json_file")
            if [ -n "$contract_address" ] && [ "$contract_address" != "null" ]; then
                # Check if we should verify this contract based on filter
                local should_verify=true
                if [ ${#CONTRACTS_TO_VERIFY[@]} -gt 0 ]; then
                    should_verify=false
                    for filter_contract in "${CONTRACTS_TO_VERIFY[@]}"; do
                        if [ "$filter_contract" = "SuperVaultBatchOperator" ]; then
                            should_verify=true
                            break
                        fi
                    done
                fi

                if [ "$should_verify" = true ]; then
                    local source_file=$(get_contract_source "SuperVaultBatchOperator")
                    local constructor_args=$(generate_constructor_args "SuperVaultBatchOperator" "$chain_id" "$json_file")
                    verify_contract "$chain_id" "SuperVaultBatchOperator" "$contract_address" "$constructor_args" "$source_file" "$rpc_url"
                fi
            fi
            ;;
    esac
}

# Function to verify all contracts for a network
verify_network() {
    local chain_id=$1

    # Get network name and RPC URL from loaded configuration
    local network_name=$(get_network_name "$chain_id")
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Unknown network ID: $chain_id${NC}"
        return 1
    fi

    local rpc_url=$(get_rpc_url "$chain_id")
    if [ -z "$rpc_url" ]; then
        echo -e "${RED}❌ RPC URL not found for chain $chain_id${NC}"
        return 1
    fi

    print_network_header "$network_name"
    echo -e "${CYAN}   Chain ID: ${WHITE}$chain_id${NC}"
    echo -e "${CYAN}   RPC URL: ${WHITE}$rpc_url${NC}"
    echo -e "${CYAN}   Verification: ${WHITE}Etherscan V2${NC}"

    local chain_dir="script/output/$ENVIRONMENT/$chain_id"

    if [ ! -d "$chain_dir" ]; then
        echo -e "${YELLOW}   ⚠️  No deployment directory found for chain $chain_id${NC}"
        return 0
    fi

    echo -e "${CYAN}   📋 Starting contract verification...${NC}"

    # Get network suffix for main JSON file
    local network_suffix=$(get_network_suffix "$chain_id")
    local main_json="$chain_dir/$network_suffix.json"

    # Verify main contracts file (e.g., Base-latest.json)
    if [ -f "$main_json" ]; then
        verify_json_file "$chain_id" "$main_json" "$rpc_url" "main"
    fi

    # Verify SuperformGasOracle if exists
    local gas_oracle_json="$chain_dir/SuperformGasOracle-latest.json"
    if [ -f "$gas_oracle_json" ]; then
        verify_json_file "$chain_id" "$gas_oracle_json" "$rpc_url" "gas_oracle"
    fi

    # Verify UpOFT if exists
    local up_oft_json="$chain_dir/UpOFT-latest.json"
    if [ -f "$up_oft_json" ]; then
        verify_json_file "$chain_id" "$up_oft_json" "$rpc_url" "up_oft"
    fi

    # Verify SuperVaultBatchOperator if exists (separate file)
    local batch_operator_json="$chain_dir/SuperVaultBatchOperator-latest.json"
    if [ -f "$batch_operator_json" ]; then
        verify_json_file "$chain_id" "$batch_operator_json" "$rpc_url" "super_vault_batch_operator"
    fi

    echo -e "${GREEN}✅ Network $network_name verification completed${NC}"
}

# Main verification loop
main() {
    # Get chain IDs from the loaded network configuration or use filter
    local chains=()

    if [ ${#CHAINS_TO_VERIFY[@]} -eq 0 ]; then
        # No filter specified, use all chains from network configuration
        echo -e "${CYAN}📋 No chain filter specified, verifying all configured networks...${NC}"
        for network_def in "${NETWORKS[@]}"; do
            IFS=':' read -r network_id _ _ <<< "$network_def"
            chains+=("$network_id")
        done
    else
        # Use filtered chains
        echo -e "${CYAN}📋 Chain filter active, verifying only specified chains...${NC}"
        for chain_id in "${CHAINS_TO_VERIFY[@]}"; do
            # Verify the chain exists in network configuration
            local found=false
            for network_def in "${NETWORKS[@]}"; do
                IFS=':' read -r network_id _ _ <<< "$network_def"
                if [ "$network_id" = "$chain_id" ]; then
                    chains+=("$chain_id")
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                echo -e "${YELLOW}⚠️  Warning: Chain $chain_id not found in network configuration, skipping...${NC}"
            fi
        done
    fi

    echo -e "${BLUE}🔍 Starting verification for ${#chains[@]} networks in $ENVIRONMENT environment...${NC}"
    if [ ${#CHAINS_TO_VERIFY[@]} -gt 0 ]; then
        echo -e "${CYAN}   Filtered chains: ${CHAINS_TO_VERIFY[*]}${NC}"
    fi
    if [ ${#CONTRACTS_TO_VERIFY[@]} -gt 0 ]; then
        echo -e "${CYAN}   Filtered contracts: ${CONTRACTS_TO_VERIFY[*]}${NC}"
    fi
    echo ""

    local successful_networks=0
    local failed_networks=0

    for chain_id in "${chains[@]}"; do
        if verify_network "$chain_id"; then
            ((successful_networks++))
        else
            ((failed_networks++))
        fi
        print_separator
    done

    echo -e "${BLUE}📊 Verification Summary:${NC}"
    echo -e "${GREEN}   • Networks verified successfully: $successful_networks${NC}"
    if [ $failed_networks -gt 0 ]; then
        echo -e "${RED}   • Networks with verification failures: $failed_networks${NC}"
    fi
    echo ""

    if [ $failed_networks -eq 0 ]; then
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                                                                                      ║${NC}"
        echo -e "${GREEN}║${WHITE}          🎉 All V2 Periphery $ENVIRONMENT Contract Verification Completed! 🎉          ${GREEN}║${NC}"
        echo -e "${GREEN}║                                                                                      ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║                                                                                      ║${NC}"
        echo -e "${YELLOW}║${WHITE}             ⚠️  V2 Periphery $ENVIRONMENT Verification Completed with Issues ⚠️            ${YELLOW}║${NC}"
        echo -e "${YELLOW}║                                                                                      ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        exit 1
    fi
}

# Run the main function
main
