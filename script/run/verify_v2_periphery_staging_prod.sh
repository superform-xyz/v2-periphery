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

# Set locked bytecode directory based on environment
if [ "$ENVIRONMENT" = "staging" ]; then
    LOCKED_BYTECODE_DIR="$PROJECT_ROOT/script/locked-bytecode-dev"
else
    LOCKED_BYTECODE_DIR="$PROJECT_ROOT/script/locked-bytecode"
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
# Follows the exact same constructor arg patterns as:
#   - script/DeployV2Periphery.s.sol (main periphery contracts)
#   - script/DeploySuperformGasOracle.s.sol
#   - script/DeploySuperVaultBatchOperator.s.sol
#   - script/DeployUpOFT.s.sol
generate_constructor_args() {
    local contract_name=$1
    local chain_id=$2
    local json_file=$3

    # ===== Constants from ConfigBase.sol =====
    local DEPLOYER="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"
    local BANK_MANAGER="0xBe3B40a05BA6120B73F94c5018Bc90E49A6275E7"
    local ORACLE_MANAGER="0xC72F6950FBF6ffE315525E200F6E54A05F739311"
    local GAS_MANAGER="0x4d7AACD4b72e6BC6eA0eee6AA61A773A8b556B99"
    local GUARDIAN="0x5E8C68Ef250fdBcF696F838033CCcE23785DA03F"
    local SUPERFORM_TREASURY="0x1dbD9b26b295A33f126456Ab4e498cd308622f08"
    local SUPER_GOVERNOR_ADDR="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"

    # Oracle constant addresses (precomputed from Solidity keccak256)
    local GAS_QUOTE="0x2facc608f385d9435b7c3773f83bd2a8902fdca0"
    local WEI_QUOTE="0x0687868a5f4b140eb03f4a07ba66b35601c6fc8f"
    local NATIVE_TOKEN="0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    local USD_TOKEN="0x0000000000000000000000000000000000000348"
    local PROVIDER_CHAINLINK="0x531b25f722d0a8a71503c7385b01570de01ad80b519cff2a790a6255312abee0"
    local PROVIDER_SUPERFORM="0x882d8c67ce5072aca91c6d5a5ca4eb7a2e5098a13e008e22004c1e0af2493746"

    # Chain-specific oracle feed addresses
    local ORACLE_GAS_TO_ETH="0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C"
    local ORACLE_GAS_TO_WEI_BASE="0x473b88f017dE39d85a102DA01A35a1b3507eBcFc"
    local ORACLE_GAS_TO_WEI_HYPEREVM="0x473b88f017dE39d85a102DA01A35a1b3507eBcFc"
    local ORACLE_GAS_TO_WEI_HYPEREVM_STAGING="0xCa35c983e810fBFe952A6CA59120fd9a8d2d58e3"
    local ORACLE_ETH_USD_MAINNET="0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
    local ORACLE_ETH_USD_BASE="0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70"
    local ORACLE_ETH_USD_HYPEREVM="0x017151e74fB3a393673B5B5149F53578c0Fa55B0"

    # UP Token addresses per chain
    local UP_TOKEN="0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33"
    local UP_TOKEN_BASE="0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B"
    local UP_TOKEN_HYPEREVM="0x642fFC3496AcA19106BAB7A42F1F221a329654fe"
    local UP_TOKEN_HYPEREVM_STAGING="0x53749a9a8dE9847DAE54E7F432616F2fDfa32B7f"

    # LayerZero V2 endpoints
    local LZ_ENDPOINT="0x1a44076050125825900e736c501f859c50fE728c"
    local LZ_ENDPOINT_HYPEREVM="0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9"

    case $contract_name in
        "SuperGovernor")
            # DeployV2Periphery.s.sol L645-661: abi.encode(owner, governor, bankManager, oracleManager,
            #   gasManager, guardian, treasury, upkeepPaymentsEnabled)
            # upkeepPaymentsEnabled is true only for production
            local upkeep_enabled="false"
            if [ "$ENVIRONMENT" = "prod" ]; then
                upkeep_enabled="true"
            fi
            echo "$(cast abi-encode "constructor(address,address,address,address,address,address,address,bool)" \
                "$DEPLOYER" "$DEPLOYER" "$BANK_MANAGER" "$ORACLE_MANAGER" \
                "$GAS_MANAGER" "$GUARDIAN" "$SUPERFORM_TREASURY" "$upkeep_enabled")"
            ;;

        "SuperVault"|"SuperVaultStrategy")
            # DeployV2Periphery.s.sol L669/L676: abi.encode(superGovernor)
            local sg=$(jq -r '.SuperGovernor // empty' "$json_file")
            if [ -n "$sg" ]; then
                echo "$(cast abi-encode "constructor(address)" "$sg")"
            fi
            ;;

        "SuperVaultEscrow")
            # DeployV2Periphery.s.sol L683: no constructor args
            echo ""
            ;;

        "SuperVaultAggregator")
            # DeployV2Periphery.s.sol L693-698: abi.encode(superGovernor, vaultImpl, strategyImpl, escrowImpl)
            local sg=$(jq -r '.SuperGovernor // empty' "$json_file")
            local vault_impl=$(jq -r '.SuperVault // empty' "$json_file")
            local strategy_impl=$(jq -r '.SuperVaultStrategy // empty' "$json_file")
            local escrow_impl=$(jq -r '.SuperVaultEscrow // empty' "$json_file")
            if [ -n "$sg" ] && [ -n "$vault_impl" ] && [ -n "$strategy_impl" ] && [ -n "$escrow_impl" ]; then
                echo "$(cast abi-encode "constructor(address,address,address,address)" \
                    "$sg" "$vault_impl" "$strategy_impl" "$escrow_impl")"
            fi
            ;;

        "ECDSAPPSOracle")
            # DeployV2Periphery.s.sol L709: abi.encode(superGovernor, "ECDSAPPSOracle", "1.0")
            local sg=$(jq -r '.SuperGovernor // empty' "$json_file")
            if [ -n "$sg" ]; then
                echo "$(cast abi-encode "constructor(address,string,string)" "$sg" "ECDSAPPSOracle" "1.0")"
            fi
            ;;

        "FixedPriceOracle")
            # DeployV2Periphery.s.sol L721: abi.encode(INITIAL_UP_PRICE, UP_PRICE_DECIMALS, deployer)
            # INITIAL_UP_PRICE = 0.09e18 = 90000000000000000, UP_PRICE_DECIMALS = 18
            echo "$(cast abi-encode "constructor(int256,uint8,address)" 90000000000000000 18 "$DEPLOYER")"
            ;;

        "SuperOracle")
            # DeployV2Periphery.s.sol L836: abi.encode(superGovernor, bases, quotes, providers, feeds)
            # Used on mainnet (chain 1) and HyperEVM (chain 999)
            local sg=$(jq -r '.SuperGovernor // empty' "$json_file")
            local fixed_oracle=$(jq -r '.FixedPriceOracle // empty' "$json_file")
            if [ -z "$sg" ] || [ -z "$fixed_oracle" ]; then
                echo ""
                return
            fi

            local gas_oracle="" eth_usd_oracle="" up_token=""
            case $chain_id in
                "1")
                    gas_oracle="$ORACLE_GAS_TO_ETH"
                    eth_usd_oracle="$ORACLE_ETH_USD_MAINNET"
                    up_token="$UP_TOKEN"
                    ;;
                "999")
                    if [ "$ENVIRONMENT" = "staging" ]; then
                        gas_oracle="$ORACLE_GAS_TO_WEI_HYPEREVM_STAGING"
                        up_token="$UP_TOKEN_HYPEREVM_STAGING"
                    else
                        gas_oracle="$ORACLE_GAS_TO_WEI_HYPEREVM"
                        up_token="$UP_TOKEN_HYPEREVM"
                    fi
                    eth_usd_oracle="$ORACLE_ETH_USD_HYPEREVM"
                    ;;
                *)
                    echo ""
                    return
                    ;;
            esac

            echo "$(cast abi-encode "constructor(address,address[],address[],bytes32[],address[])" \
                "$sg" \
                "[$GAS_QUOTE,$NATIVE_TOKEN,$up_token]" \
                "[$WEI_QUOTE,$USD_TOKEN,$USD_TOKEN]" \
                "[$PROVIDER_CHAINLINK,$PROVIDER_CHAINLINK,$PROVIDER_SUPERFORM]" \
                "[$gas_oracle,$eth_usd_oracle,$fixed_oracle]")"
            ;;

        "SuperOracleL2")
            # DeployV2Periphery.s.sol L847: same constructor as SuperOracle, used on L2 chains
            local sg=$(jq -r '.SuperGovernor // empty' "$json_file")
            local fixed_oracle=$(jq -r '.FixedPriceOracle // empty' "$json_file")
            if [ -z "$sg" ] || [ -z "$fixed_oracle" ]; then
                echo ""
                return
            fi

            local gas_oracle="" eth_usd_oracle="" up_token=""
            case $chain_id in
                "8453")
                    gas_oracle="$ORACLE_GAS_TO_WEI_BASE"
                    eth_usd_oracle="$ORACLE_ETH_USD_BASE"
                    up_token="$UP_TOKEN_BASE"
                    ;;
                *)
                    echo ""
                    return
                    ;;
            esac

            echo "$(cast abi-encode "constructor(address,address[],address[],bytes32[],address[])" \
                "$sg" \
                "[$GAS_QUOTE,$NATIVE_TOKEN,$up_token]" \
                "[$WEI_QUOTE,$USD_TOKEN,$USD_TOKEN]" \
                "[$PROVIDER_CHAINLINK,$PROVIDER_CHAINLINK,$PROVIDER_SUPERFORM]" \
                "[$gas_oracle,$eth_usd_oracle,$fixed_oracle]")"
            ;;

        "SuperBank")
            # DeployV2Periphery.s.sol L741: abi.encode(superGovernor)
            local sg=$(jq -r '.SuperGovernor // empty' "$json_file")
            if [ -n "$sg" ]; then
                echo "$(cast abi-encode "constructor(address)" "$sg")"
            fi
            ;;

        "SuperformGasOracle")
            # DeploySuperformGasOracle.s.sol L107: abi.encode(initialGasPrice, owner)
            # DEFAULT_INITIAL_GAS_PRICE = 1_000_000
            local owner=$(jq -r '.owner // empty' "$json_file")
            if [ -n "$owner" ]; then
                echo "$(cast abi-encode "constructor(int256,address)" 1000000 "$owner")"
            fi
            ;;

        "SuperVaultBatchOperator")
            # DeploySuperVaultBatchOperator.s.sol L148: abi.encode(admin, operator)
            # Try reading from JSON (separate JSON has admin/operator fields)
            local admin=$(jq -r '.admin // empty' "$json_file")
            local operator=$(jq -r '.operator // empty' "$json_file")
            # Fall back to known constants when verifying from main deployment JSON
            if [ -z "$admin" ]; then
                admin="$SUPER_GOVERNOR_ADDR"
            fi
            if [ -z "$operator" ]; then
                if [ "$ENVIRONMENT" = "prod" ]; then
                    operator="0x92C0B875501611B91C6aF3D801424E724Ab039DE"
                else
                    operator="0x02cbf3dac926743ec757b5A51310f46580e25A04"
                fi
            fi
            echo "$(cast abi-encode "constructor(address,address)" "$admin" "$operator")"
            ;;

        "UpOFT")
            # DeployUpOFT.s.sol L1116: abi.encode(LZ_ENDPOINT, owner)
            local lz_endpoint="$LZ_ENDPOINT"
            if [ "$chain_id" = "999" ]; then
                lz_endpoint="$LZ_ENDPOINT_HYPEREVM"
            fi
            echo "$(cast abi-encode "constructor(address,address)" "$lz_endpoint" "$DEPLOYER")"
            ;;

        "UpOFTAdapter")
            # DeployUpOFT.s.sol L1098: abi.encode(UP_TOKEN, LZ_ENDPOINT, owner)
            echo "$(cast abi-encode "constructor(address,address,address)" "$UP_TOKEN" "$LZ_ENDPOINT" "$DEPLOYER")"
            ;;

        *)
            # Unknown contracts (e.g., PendlePTAmortizedOracle from v2-core) - skip constructor args
            echo ""
            ;;
    esac
}

# Compiler version for Etherscan API submissions
SOLC_VERSION="v0.8.30+commit.73712a01"

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

    # Check for Standard JSON Input in locked bytecode directory
    local standard_json_path="${LOCKED_BYTECODE_DIR}/${contract_name}.standard-json-input.json"

    if [ -f "$standard_json_path" ]; then
        echo -e "${CYAN}      Using saved Standard JSON Input from locked bytecodes${NC}"

        # Strip 0x prefix from constructor args for Etherscan API
        local constructor_args_no_0x=""
        if [ -n "$constructor_args" ]; then
            constructor_args_no_0x="${constructor_args#0x}"
            echo -e "${CYAN}      Constructor args: ${constructor_args_no_0x:0:40}...${NC}"
        fi

        # Submit to Etherscan V2 API
        local response
        response=$(curl -s -X POST "https://api.etherscan.io/v2/api?chainid=${chain_id}" \
            --data-urlencode "module=contract" \
            --data-urlencode "action=verifysourcecode" \
            --data-urlencode "apikey=${ETHERSCANV2_API_KEY}" \
            --data-urlencode "sourceCode@${standard_json_path}" \
            --data-urlencode "codeformat=solidity-standard-json-input" \
            --data-urlencode "contractaddress=${contract_address}" \
            --data-urlencode "contractname=${source_file}:${contract_name}" \
            --data-urlencode "compilerversion=${SOLC_VERSION}" \
            --data-urlencode "constructorArguements=${constructor_args_no_0x}" \
            --data-urlencode "evmversion=prague")

        local api_status
        api_status=$(echo "$response" | jq -r '.status')
        local api_result
        api_result=$(echo "$response" | jq -r '.result')

        if [ "$api_status" != "1" ]; then
            echo -e "${RED}   ❌ $contract_name submission failed: $api_result${NC}"
            echo ""
            return 1
        fi

        local guid="$api_result"
        echo -e "${CYAN}      Verification GUID: $guid${NC}"
        echo -e "${CYAN}      Polling for result...${NC}"

        # Poll for verification result
        local max_attempts=30
        local attempt=0
        while [ $attempt -lt $max_attempts ]; do
            sleep 5
            local check_response
            check_response=$(curl -s "https://api.etherscan.io/v2/api?chainid=${chain_id}&module=contract&action=checkverifystatus&guid=${guid}&apikey=${ETHERSCANV2_API_KEY}")
            local check_result
            check_result=$(echo "$check_response" | jq -r '.result')

            if echo "$check_result" | grep -qi "pass"; then
                echo -e "${GREEN}   ✅ $contract_name verified successfully${NC}"
                echo ""
                return 0
            elif echo "$check_result" | grep -qi "fail"; then
                echo -e "${RED}   ❌ $contract_name verification failed: $check_result${NC}"
                echo ""
                return 1
            fi

            # Still pending
            attempt=$((attempt + 1))
            echo -e "${CYAN}      Still pending (attempt $attempt/$max_attempts)...${NC}"
        done

        echo -e "${YELLOW}   ⚠️  $contract_name verification timed out after $max_attempts attempts${NC}"
        echo ""
        return 1
    else
        # Fallback: use forge verify-contract (no Standard JSON Input available)
        echo -e "${YELLOW}      No Standard JSON Input found, falling back to forge verify-contract${NC}"

        local verify_cmd="forge verify-contract \"$contract_address\" \"$source_file:$contract_name\" --rpc-url \"$rpc_url\" --chain \"$chain_id\" --etherscan-api-key \"$ETHERSCANV2_API_KEY\" --verifier etherscan --watch"

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
    fi
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
