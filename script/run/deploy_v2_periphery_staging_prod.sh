#!/usr/bin/env bash

# Colors for better visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Associative array to store deployment status for each network
declare -A NETWORK_DEPLOYMENT_STATUS

# Function to print colored header
print_header() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}║${WHITE}                 🚀 V2 Periphery Production/Staging Deployment Script 🚀            ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                                                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to print section separator
print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print network deployment header
print_network_header() {
    local network=$1
    echo -e "${PURPLE}╭─────────────────────────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│${WHITE}                           🌐 Deploying to ${network} Network 🌐                          ${PURPLE}│${NC}"
    echo -e "${PURPLE}╰─────────────────────────────────────────────────────────────────────────────────────╯${NC}"
}

# Logging function for consistent output
log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

# Function to extract contract names from regenerate_bytecode.sh
extract_contracts_from_regenerate_script() {
    local array_name=$1
    local script_path="$PROJECT_ROOT/script/run/regenerate_bytecode.sh"

    if [[ ! -f "$script_path" ]]; then
        return 1
    fi

    # Extract contract names from the specified array in regenerate_bytecode.sh
    # Find the array definition and stop at the closing parenthesis
    sed -n "/${array_name}=(/,/^)/p" "$script_path" | grep -o '"[^"]*"' | tr -d '"'
}

# Function to report bytecode availability (sourced from regenerate_bytecode.sh)
report_bytecode_availability() {
    log "INFO" "Analyzing bytecode availability from $LOCKED_BYTECODE_PATH..."

    local script_path="$PROJECT_ROOT/script/run/regenerate_bytecode.sh"
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}❌ Cannot find regenerate_bytecode.sh at: $script_path${NC}"
        return 1
    fi

    local missing_contracts=()
    local available_contracts=()

    # Extract and check core periphery contracts
    log "INFO" "Checking core periphery contracts from regenerate_bytecode.sh..."
    local core_contracts
    core_contracts=$(extract_contracts_from_regenerate_script "CORE_PERIPHERY_CONTRACTS")
    for contract in $core_contracts; do
        [[ -z "$contract" ]] && continue
        local file_path="$LOCKED_BYTECODE_PATH/${contract}.json"
        if [ ! -f "$file_path" ]; then
            missing_contracts+=("$contract")
        else
            available_contracts+=("$contract")
        fi
    done

    # Show summary
    local expected_total
    expected_total=$(get_expected_contract_count)
    echo -e "${CYAN}📊 Bytecode Availability Summary${NC}"
    echo -e "${GREEN}   Available contracts: ${#available_contracts[@]}${NC}"
    echo -e "${YELLOW}   Missing contracts: ${#missing_contracts[@]}${NC}"
    echo -e "${BLUE}   Expected total: $expected_total${NC}"
    echo ""

    if [ ${#missing_contracts[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Contracts that will be SKIPPED due to missing bytecode:${NC}"
        echo -e "${YELLOW}   Core Periphery Contracts (${#missing_contracts[@]}):${NC}"
        for contract in "${missing_contracts[@]}"; do
            echo -e "${YELLOW}     - $contract${NC}"
        done
        echo ""
        echo -e "${YELLOW}ℹ️  These contracts are defined in the system but will not be deployed.${NC}"
        echo -e "${YELLOW}   To deploy them, ensure their bytecode artifacts are present in: $LOCKED_BYTECODE_PATH${NC}"
        echo ""
    else
        echo -e "${GREEN}✅ All defined contracts have bytecode available${NC}"
        echo ""
    fi

    # Always return success to allow deployment to continue
    return 0
}

# Function to get expected contract count from regenerate_bytecode.sh
get_expected_contract_count() {
    local script_path="$PROJECT_ROOT/script/run/regenerate_bytecode.sh"

    if [[ ! -f "$script_path" ]]; then
        echo "6"
        return 0
    fi

    # Extract CORE_PERIPHERY_CONTRACTS array and count elements
    local core_count
    core_count=$(sed -n "/CORE_PERIPHERY_CONTRACTS=(/,/^)/p" "$script_path" | grep -o '"[^"]*"' | wc -l)

    echo "$core_count"
}

# Function to analyze deployment status across all networks and determine next steps
analyze_deployment_status() {
    echo -e "${BLUE}📊 Analyzing deployment status across all networks...${NC}"
    echo ""

    local all_fully_deployed=true
    local needs_deployment=false
    local networks_with_missing=()

    # Get expected contract count from regenerate_bytecode.sh
    local total_expected
    total_expected=$(get_expected_contract_count)

    if [[ $total_expected -eq 0 ]]; then
        echo -e "${RED}❌ Unable to determine expected contract count from regenerate_bytecode.sh${NC}"
        return 2
    fi

    echo -e "${CYAN}Expected contracts for V2 Periphery:${NC}"
    echo -e "${CYAN}  • Periphery contracts: ${WHITE}${total_expected}${NC}"
    echo ""

    # Analyze each network using their actual expected total
    for network_id in "${!NETWORK_DEPLOYMENT_STATUS[@]}"; do
        IFS=':' read -r deployed actual_expected network_name <<< "${NETWORK_DEPLOYMENT_STATUS[$network_id]}"

        # Use the actual expected total reported by the checking script
        if [[ $deployed -eq $actual_expected ]]; then
            echo -e "${GREEN}✅ $network_name (Chain $network_id): All $deployed/$actual_expected contracts deployed${NC}"
        elif [[ $deployed -lt $actual_expected ]]; then
            local missing=$((actual_expected - deployed))
            echo -e "${YELLOW}⚠️  $network_name (Chain $network_id): $deployed/$actual_expected contracts deployed (${missing} missing)${NC}"
            all_fully_deployed=false
            needs_deployment=true
            networks_with_missing+=("$network_name")
        elif [[ $deployed -gt $actual_expected ]]; then
            echo -e "${CYAN}ℹ️  $network_name (Chain $network_id): $deployed/$actual_expected contracts deployed (more than expected)${NC}"
            echo -e "${CYAN}    Note: This may include additional contracts not tracked by availability analysis${NC}"
        else
            echo -e "${RED}❌ $network_name (Chain $network_id): Error in deployment status${NC}"
            all_fully_deployed=false
        fi
    done

    echo ""

    # Determine action based on analysis
    if [[ $all_fully_deployed == true ]]; then
        echo -e "${GREEN}🎉 EXCELLENT! All contracts are already deployed on all networks!${NC}"
        echo -e "${GREEN}   Status: Fully deployed across all chains${NC}"
        echo -e "${GREEN}   No deployment needed - terminating with success${NC}"
        return 0  # All deployed - skip deployment
    elif [[ $needs_deployment == true ]]; then
        echo -e "${YELLOW}📋 DEPLOYMENT REQUIRED${NC}"
        echo -e "${CYAN}   The following networks have missing contracts:${NC}"
        for network in "${networks_with_missing[@]}"; do
            echo -e "${CYAN}   • $network${NC}"
        done
        echo ""
        echo -e "${WHITE}   Only missing contracts will be deployed (existing ones will be skipped)${NC}"
        return 1  # Needs deployment - continue with confirmation
    else
        echo -e "${RED}❌ Unable to determine deployment status${NC}"
        echo -e "${RED}   Please check the output above for specific network issues${NC}"
        return 2  # Error state
    fi
}

# Associative array to store estimated costs for each network
declare -A NETWORK_ESTIMATED_COSTS

# Function to check V2 Periphery addresses on a network and capture deployment status
check_v2_periphery_addresses() {
    local network_id=$1
    local network_name=$2
    local rpc_url_var=$3

    echo -e "${CYAN}Checking V2 Periphery addresses for $network_name (Chain ID: $network_id)...${NC}"

    # Check if RPC URL is set
    if [[ -z "${!rpc_url_var}" ]]; then
        echo -e "${RED}  ❌ ERROR: RPC URL variable $rpc_url_var is not set or empty${NC}"
        echo -e "${RED}     This indicates a configuration problem with network credentials${NC}"
        return 1
    fi

    # Capture the full output to parse deployment status
    local check_output
    local forge_exit_code

    # Run forge script and capture both output and exit code
    check_output=$(forge script script/DeployV2Periphery.s.sol:DeployV2Periphery \
        --sig 'runCheck(uint256,uint64)' $FORGE_ENV $network_id \
        --rpc-url ${!rpc_url_var} \
        --chain $network_id \
        -vv 2>&1)
    forge_exit_code=$?

    # Check if forge command failed
    if [[ $forge_exit_code -ne 0 ]]; then
        echo -e "${RED}  ❌ ERROR: Forge script failed with exit code $forge_exit_code${NC}"
        echo -e "${RED}     This likely indicates RPC connectivity issues or network problems${NC}"
        echo -e "${YELLOW}  📋 Forge output (last 10 lines):${NC}"
        echo "$check_output" | tail -10 | sed 's/^/     /'
        return 1
    fi

    # Display the relevant output lines
    echo "$check_output" | grep -e "Addr" -e "already deployed" -e "Code Size" -e "====" -e "====>"

    # Extract deployment counts from the summary line
    local summary_line
    summary_line=$(echo "$check_output" | grep "=====> On this chain we have")

    if [[ -n "$summary_line" ]]; then
        # Parse: "=====> On this chain we have X contracts already deployed out of Y"
        local deployed_count=$(echo "$summary_line" | grep -o "have [0-9]\+ contracts" | grep -o "[0-9]\+")
        local total_count=$(echo "$summary_line" | grep -o "out of [0-9]\+" | grep -o "[0-9]\+")

        if [[ -n "$deployed_count" && -n "$total_count" ]]; then
            # Store deployment status for this network
            NETWORK_DEPLOYMENT_STATUS["${network_id}"]="${deployed_count}:${total_count}:${network_name}"
            echo -e "${GREEN}  ✅ Successfully checked: ${deployed_count}/${total_count} contracts deployed${NC}"
            return 0
        else
            echo -e "${RED}  ❌ ERROR: Could not parse deployment counts from summary line${NC}"
            echo -e "${YELLOW}     Summary line: $summary_line${NC}"
            return 1
        fi
    else
        echo -e "${RED}  ❌ ERROR: Could not find deployment summary in forge output${NC}"
        echo -e "${RED}     This indicates the forge script didn't complete successfully${NC}"
        echo -e "${YELLOW}  📋 Full forge output:${NC}"
        echo "$check_output" | sed 's/^/     /'
        return 1
    fi
}

# Function to estimate deployment costs for a network
estimate_deployment_costs() {
    local network_id=$1
    local network_name=$2
    local rpc_url_var=$3

    echo -e "${CYAN}Estimating deployment costs for $network_name (Chain ID: $network_id)...${NC}"

    # Check if RPC URL is set
    if [[ -z "${!rpc_url_var}" ]]; then
        echo -e "${RED}  ❌ ERROR: RPC URL variable $rpc_url_var is not set or empty${NC}"
        return 1
    fi

    # Run the estimation script
    local estimate_output
    local forge_exit_code

    estimate_output=$(forge script script/DeployV2Periphery.s.sol:DeployV2Periphery \
        --sig 'runEstimate(uint256,uint64)' $FORGE_ENV $network_id \
        --rpc-url ${!rpc_url_var} \
        --chain $network_id \
        -vv 2>&1)
    forge_exit_code=$?

    if [[ $forge_exit_code -ne 0 ]]; then
        echo -e "${YELLOW}  ⚠️  Could not estimate costs for $network_name${NC}"
        return 1
    fi

    # Extract cost information
    local cost_wei=$(echo "$estimate_output" | grep "ESTIMATED_NATIVE_COST_WEI:" | grep -o "[0-9]\+$")
    local contracts_to_deploy=$(echo "$estimate_output" | grep "CONTRACTS_TO_DEPLOY:" | grep -o "[0-9]\+$")
    local gas_price_line=$(echo "$estimate_output" | grep "Current Gas Price:")

    if [[ -n "$cost_wei" ]]; then
        # Store the cost for this network
        NETWORK_ESTIMATED_COSTS["${network_id}"]="${cost_wei}:${contracts_to_deploy}:${network_name}"

        # Convert wei to more readable format
        # Using bc for floating point arithmetic if available, otherwise show wei
        if command -v bc &> /dev/null; then
            local cost_eth=$(echo "scale=6; $cost_wei / 1000000000000000000" | bc)
            echo -e "${GREEN}  💰 Estimated cost: ${cost_eth} ETH/Native (${cost_wei} wei)${NC}"
        else
            echo -e "${GREEN}  💰 Estimated cost: ${cost_wei} wei${NC}"
        fi
        echo -e "${CYAN}     Contracts to deploy: ${contracts_to_deploy}${NC}"
        if [[ -n "$gas_price_line" ]]; then
            echo -e "${CYAN}     ${gas_price_line}${NC}"
        fi
        return 0
    else
        echo -e "${YELLOW}  ⚠️  Could not parse cost estimation${NC}"
        return 1
    fi
}

# Function to print cost estimation summary
print_cost_estimation_summary() {
    if [[ ${#NETWORK_ESTIMATED_COSTS[@]} -eq 0 ]]; then
        return
    fi

    echo -e "${BLUE}💰 Deployment Cost Estimation Summary${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    local total_cost_wei=0
    local total_contracts=0

    printf "${WHITE}%-15s %-20s %-25s %-15s${NC}\n" "Chain ID" "Network" "Estimated Cost" "Contracts"
    printf "${CYAN}%-15s %-20s %-25s %-15s${NC}\n" "--------" "-------" "--------------" "---------"

    for network_id in "${!NETWORK_ESTIMATED_COSTS[@]}"; do
        IFS=':' read -r cost_wei contracts network_name <<< "${NETWORK_ESTIMATED_COSTS[$network_id]}"

        # Convert to ETH for display
        local cost_display
        if command -v bc &> /dev/null && [[ -n "$cost_wei" ]]; then
            cost_display=$(echo "scale=6; $cost_wei / 1000000000000000000" | bc)
            cost_display="${cost_display} ETH"
        else
            cost_display="${cost_wei} wei"
        fi

        if [[ "$contracts" == "0" ]]; then
            printf "${GREEN}%-15s %-20s %-25s %-15s${NC}\n" "$network_id" "$network_name" "0 (all deployed)" "$contracts"
        else
            printf "${YELLOW}%-15s %-20s %-25s %-15s${NC}\n" "$network_id" "$network_name" "$cost_display" "$contracts"
        fi

        # Accumulate totals
        if [[ -n "$cost_wei" ]]; then
            total_cost_wei=$((total_cost_wei + cost_wei))
        fi
        if [[ -n "$contracts" ]]; then
            total_contracts=$((total_contracts + contracts))
        fi
    done

    echo ""
    printf "${CYAN}%-15s %-20s %-25s %-15s${NC}\n" "--------" "-------" "--------------" "---------"

    # Print total
    local total_cost_display
    if command -v bc &> /dev/null; then
        total_cost_display=$(echo "scale=6; $total_cost_wei / 1000000000000000000" | bc)
        total_cost_display="${total_cost_display} ETH"
    else
        total_cost_display="${total_cost_wei} wei"
    fi

    printf "${WHITE}%-15s %-20s %-25s %-15s${NC}\n" "TOTAL" "All Networks" "$total_cost_display" "$total_contracts"
    echo ""
    echo -e "${YELLOW}⚠️  Note: These are estimates based on current gas prices. Actual costs may vary.${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_header

# Script directory and project root setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Find project root (go up from script/run/ to project root)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Locked bytecode path will be set based on environment
# - prod: locked-bytecode (audited, production-ready)
# - staging: locked-bytecode-dev (development/staging versions)
LOCKED_BYTECODE_PATH=""

# Network configuration will be sourced after environment is determined

# Check if arguments are provided
if [ $# -lt 3 ]; then
    echo -e "${RED}❌ Error: Missing required arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <environment> <mode> <account>${NC}"
    echo -e "${CYAN}  environment: staging or prod${NC}"
    echo -e "${CYAN}  mode: simulate or deploy${NC}"
    echo -e "${CYAN}  account: foundry account name (e.g., v2, deployer, main)${NC}"
    echo -e "${CYAN}Examples:${NC}"
    echo -e "${CYAN}  $0 staging simulate v2${NC}"
    echo -e "${CYAN}  $0 prod deploy deployer${NC}"
    echo -e "${CYAN}Available accounts: $(cast wallet list 2>/dev/null | sed 's/ (Local)//' | tr '\n' ' ' || echo 'Run "cast wallet list" to see available accounts')${NC}"
    exit 1
fi

ENVIRONMENT=$1
MODE=$2
ACCOUNT=$3

# Validate environment and source network configuration
if [ "$ENVIRONMENT" = "staging" ]; then
    echo -e "${CYAN}🌐 Loading staging network configuration...${NC}"
    LOCKED_BYTECODE_PATH="$PROJECT_ROOT/script/locked-bytecode-dev"
    echo -e "${CYAN}📁 Using locked bytecode folder: locked-bytecode-dev${NC}"
    source "$SCRIPT_DIR/networks-staging.sh"
elif [ "$ENVIRONMENT" = "prod" ]; then
    echo -e "${CYAN}🌐 Loading production network configuration...${NC}"
    LOCKED_BYTECODE_PATH="$PROJECT_ROOT/script/locked-bytecode"
    echo -e "${CYAN}📁 Using locked bytecode folder: locked-bytecode${NC}"
    source "$SCRIPT_DIR/networks-production.sh"
else
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo -e "${YELLOW}Environment must be either 'staging' or 'prod'${NC}"
    exit 1
fi

# Validate that the locked bytecode directory exists
if [[ ! -d "$LOCKED_BYTECODE_PATH" ]]; then
    echo -e "${RED}❌ Error: Locked bytecode directory does not exist: $LOCKED_BYTECODE_PATH${NC}"
    echo -e "${YELLOW}Please ensure the locked bytecode folder exists before deployment.${NC}"
    exit 1
fi

echo -e "${CYAN}✅ Network configuration loaded for $ENVIRONMENT environment${NC}"
print_network_info

# Validate account exists in foundry wallet list
if ! cast wallet list 2>/dev/null | sed 's/ (Local)//' | grep -q "^$ACCOUNT$"; then
    echo -e "${RED}❌ Account '$ACCOUNT' not found in foundry wallet list${NC}"
    echo -e "${YELLOW}Available accounts:${NC}"
    cast wallet list 2>/dev/null | sed 's/ (Local)//' | sed 's/^/  • /' || echo -e "${RED}  No accounts found. Run 'cast wallet import' to add accounts.${NC}"
    exit 1
fi

# Set flags based on mode
if [ "$MODE" = "simulate" ]; then
    echo -e "${YELLOW}🔍 Running in simulation mode for $ENVIRONMENT...${NC}"
    echo -e "${CYAN}   - No broadcasting to network${NC}"
    echo -e "${CYAN}   - No contract verification${NC}"
    echo -e "${CYAN}   - Using sender: 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8${NC}"
    BROADCAST_FLAG=""
    VERIFY_FLAG=""
    SENDER_FLAG="--sender 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"
    ACCOUNT_FLAG=""
elif [ "$MODE" = "deploy" ]; then
    echo -e "${GREEN}🚀 Running in deployment mode for $ENVIRONMENT...${NC}"
    echo -e "${CYAN}   - Broadcasting to network${NC}"
    echo -e "${CYAN}   - Tenderly public verification enabled${NC}"
    echo -e "${CYAN}   - Account: $ACCOUNT${NC}"
    echo -e "${CYAN}   - Expected deployer: 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8${NC}"
    echo -e "${YELLOW}   - Note: Account validation will happen during forge script execution${NC}"

    BROADCAST_FLAG="--broadcast"
    VERIFY_FLAG="--verify"
    SENDER_FLAG=""
    ACCOUNT_FLAG="--account $ACCOUNT"
else
    echo -e "${RED}❌ Invalid mode: $MODE${NC}"
    echo -e "${YELLOW}Mode must be either 'simulate' or 'deploy'${NC}"
    exit 1
fi

print_separator
echo -e "${BLUE}🔧 Loading Configuration...${NC}"

# Load RPC URLs using network-specific function
echo -e "${CYAN}   • Loading RPC URLs...${NC}"
if ! load_rpc_urls; then
    echo -e "${RED}❌ Failed to load some RPC URLs from credential manager${NC}"
    echo -e "${YELLOW}⚠️  This may cause connectivity issues during deployment verification${NC}"
    echo -e "${YELLOW}   Please ensure all required RPC URLs are configured in 1Password${NC}"
    # Continue but with warning - the address checking phase will catch specific failures
fi

# Load Etherscan V2 API key for verification
echo -e "${CYAN}   • Loading Etherscan V2 API credentials...${NC}"
if ! load_etherscan_api_key; then
    echo -e "${RED}❌ Failed to load Etherscan V2 API key${NC}"
    echo -e "${RED}   Contract verification will not work without this credential${NC}"
    exit 1
fi

# Create output directories for all networks in current environment
for network_def in "${NETWORKS[@]}"; do
    IFS=':' read -r network_id _ _ <<< "$network_def"
    mkdir -p "$PROJECT_ROOT/script/output/$ENVIRONMENT/$network_id"
done
echo -e "${CYAN}   • Created output directories for all networks${NC}"

# Deployment parameters
if [ "$ENVIRONMENT" = "staging" ]; then
    FORGE_ENV=2
    export CI=true
    export GITHUB_REF_NAME="staging"
elif [ "$ENVIRONMENT" = "prod" ]; then
    FORGE_ENV=0
    export CI=true
    export GITHUB_REF_NAME="prod"
fi

echo -e "${GREEN}✅ Configuration loaded successfully${NC}"
echo -e "${CYAN}   • Using Etherscan V2 verification${NC}"
echo -e "${CYAN}   • Environment: $ENVIRONMENT${NC}"
echo -e "${CYAN}   • Account: $ACCOUNT${NC}"

# Change to project root directory for forge commands
echo -e "${CYAN}   • Changing to project root: $PROJECT_ROOT${NC}"
cd "$PROJECT_ROOT"

# Export PROJECT_ROOT as environment variable for Solidity scripts
export SUPERFORM_PROJECT_ROOT="$PROJECT_ROOT"
echo -e "${CYAN}   • Exported SUPERFORM_PROJECT_ROOT: $SUPERFORM_PROJECT_ROOT${NC}"
print_separator

# ===== BYTECODE AVAILABILITY ANALYSIS =====
echo -e "${BLUE}🔍 Analyzing bytecode availability...${NC}"
report_bytecode_availability
echo -e "${GREEN}✅ Bytecode availability analysis completed${NC}"
echo -e "${CYAN}   Deployment will proceed, skipping any contracts with missing bytecode${NC}"
print_separator

# ===== ADDRESS CHECKING PHASE =====
echo -e "${BLUE}🔍 Checking V2 Periphery contract addresses...${NC}"
echo -e "${CYAN}This will show you which contracts are already deployed and which need to be deployed.${NC}"
echo ""

# Track networks with errors
declare -a FAILED_NETWORKS=()
declare -a SUCCESSFUL_NETWORKS=()

# Check addresses on all networks using current configuration
for network_def in "${NETWORKS[@]}"; do
    IFS=':' read -r network_id network_name rpc_var <<< "$network_def"

    if check_v2_periphery_addresses "$network_id" "$network_name" "$rpc_var"; then
        SUCCESSFUL_NETWORKS+=("$network_name (Chain $network_id)")
    else
        FAILED_NETWORKS+=("$network_name (Chain $network_id)")
        echo -e "${RED}  ⚠️  Failed to check deployment status for $network_name${NC}"
    fi
    echo ""
done

# Check if any networks failed
if [[ ${#FAILED_NETWORKS[@]} -gt 0 ]]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                                                                      ║${NC}"
    echo -e "${RED}║${WHITE}                    ❌ NETWORK CONNECTIVITY ERRORS DETECTED ❌                    ${RED}║${NC}"
    echo -e "${RED}║                                                                                      ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}🚨 CRITICAL ERROR: Unable to check deployment status on the following networks:${NC}"
    for failed_network in "${FAILED_NETWORKS[@]}"; do
        echo -e "${RED}   ❌ $failed_network${NC}"
    done
    echo ""
    echo -e "${YELLOW}📋 Possible causes:${NC}"
    echo -e "${YELLOW}   • RPC URL credentials not configured in 1Password${NC}"
    echo -e "${YELLOW}   • Network RPC endpoints are down or unreachable${NC}"
    echo -e "${YELLOW}   • Firewall or network connectivity issues${NC}"
    echo -e "${YELLOW}   • Invalid or expired RPC API keys${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Recommended actions:${NC}"
    echo -e "${YELLOW}   1. Verify RPC URLs are configured in 1Password vault${NC}"
    echo -e "${YELLOW}   2. Test RPC connectivity manually: curl -X POST <RPC_URL> -H 'Content-Type: application/json' -d '{\"method\":\"eth_chainId\",\"params\":[],\"id\":1,\"jsonrpc\":\"2.0\"}'${NC}"
    echo -e "${YELLOW}   3. Check if the networks are supported in your environment${NC}"
    echo ""

    if [[ ${#SUCCESSFUL_NETWORKS[@]} -gt 0 ]]; then
        echo -e "${GREEN}✅ Successfully checked networks:${NC}"
        for successful_network in "${SUCCESSFUL_NETWORKS[@]}"; do
            echo -e "${GREEN}   ✓ $successful_network${NC}"
        done
        echo ""
    fi

    echo -e "${RED}🛑 DEPLOYMENT ABORTED: Cannot proceed without verifying current deployment status${NC}"
    echo -e "${RED}   Please resolve the network connectivity issues before attempting deployment.${NC}"
    exit 1
fi

print_separator

# ===== ANALYZE DEPLOYMENT STATUS =====
analyze_deployment_status
ANALYSIS_RESULT=$?

if [[ $ANALYSIS_RESULT -eq 0 ]]; then
    # All contracts are deployed, exit successfully
    exit 0
elif [[ $ANALYSIS_RESULT -eq 2 ]]; then
    # Error in analysis, exit with error
    echo -e "${RED}🛑 Exiting due to deployment status analysis errors${NC}"
    exit 1
fi

# If we reach here, deployment is needed (ANALYSIS_RESULT == 1)

print_separator

# ===== COST ESTIMATION PHASE =====
echo -e "${BLUE}💰 Estimating deployment costs...${NC}"
echo -e "${CYAN}This will estimate the ETH/native token required for deployment on each chain.${NC}"
echo ""

for network_def in "${NETWORKS[@]}"; do
    IFS=':' read -r network_id network_name rpc_var <<< "$network_def"
    estimate_deployment_costs "$network_id" "$network_name" "$rpc_var"
    echo ""
done

# Print cost estimation summary
print_cost_estimation_summary

print_separator

# ===== DEPLOYMENT CONFIRMATION =====
if [ "$MODE" = "deploy" ]; then
    echo -e "${YELLOW}⚠️  DEPLOYMENT CONFIRMATION REQUIRED ⚠️${NC}"
    echo -e "${CYAN}You are about to deploy V2 Periphery contracts to:${NC}"
    echo -e "${CYAN}  • Environment: ${WHITE}$ENVIRONMENT${NC}"
    echo -e "${CYAN}  • Account: ${WHITE}$ACCOUNT${NC}"
    echo -e "${CYAN}  • Networks:${NC}"
    for network_def in "${NETWORKS[@]}"; do
        IFS=':' read -r network_id network_name _ <<< "$network_def"
        echo -e "${CYAN}     - $network_name (Chain ID: $network_id)${NC}"
    done
    echo ""
    echo -e "${WHITE}Only missing contracts will be deployed. Existing deployments will be preserved.${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Type \"DEPLOY\" to continue or anything else to abort: ${NC})" confirmation
    if [ "$confirmation" != "DEPLOY" ]; then
        echo -e "${RED}❌ Deployment aborted by user${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Deployment confirmed${NC}"
fi

print_separator

# ===== DEPLOYMENT PHASE =====
echo -e "${BLUE}🚀 Starting V2 Periphery Deployment...${NC}"
echo ""

declare -a DEPLOYMENT_FAILURES=()
declare -a DEPLOYMENT_SUCCESSES=()

for network_def in "${NETWORKS[@]}"; do
    IFS=':' read -r network_id network_name rpc_var <<< "$network_def"

    # Get deployment status for this network
    if [[ -n "${NETWORK_DEPLOYMENT_STATUS[$network_id]}" ]]; then
        IFS=':' read -r deployed total _ <<< "${NETWORK_DEPLOYMENT_STATUS[$network_id]}"

        # Only deploy if there are missing contracts
        if [[ $deployed -lt $total ]]; then
            print_network_header "$network_name"
            echo -e "${CYAN}Deploying missing contracts to $network_name (Chain ID: $network_id)...${NC}"
            echo -e "${CYAN}  • RPC: ${!rpc_var:0:30}...${NC}"
            echo -e "${CYAN}  • Status: $deployed/$total contracts already deployed${NC}"
            echo ""

            # Run deployment script
            if forge script script/DeployV2Periphery.s.sol:DeployV2Periphery \
                --sig 'run(uint256,uint64)' $FORGE_ENV $network_id \
                --rpc-url ${!rpc_var} \
                --chain $network_id \
                --etherscan-api-key $ETHERSCANV2_API_KEY \
                --verifier etherscan \
                $ACCOUNT_FLAG \
                $SENDER_FLAG \
                $BROADCAST_FLAG \
                $VERIFY_FLAG \
                -vvv; then

                echo -e "${GREEN}✅ Successfully deployed to $network_name${NC}"
                DEPLOYMENT_SUCCESSES+=("$network_name (Chain $network_id)")
            else
                echo -e "${RED}❌ Failed to deploy to $network_name${NC}"
                DEPLOYMENT_FAILURES+=("$network_name (Chain $network_id)")
            fi
            echo ""
        else
            echo -e "${GREEN}✅ $network_name: All contracts already deployed ($deployed/$total)${NC}"
            DEPLOYMENT_SUCCESSES+=("$network_name (Chain $network_id)")
        fi
    fi
done

print_separator

# ===== DEPLOYMENT SUMMARY =====
echo -e "${BLUE}📊 Deployment Summary${NC}"
echo ""

if [[ ${#DEPLOYMENT_SUCCESSES[@]} -gt 0 ]]; then
    echo -e "${GREEN}✅ Successful deployments:${NC}"
    for success in "${DEPLOYMENT_SUCCESSES[@]}"; do
        echo -e "${GREEN}   ✓ $success${NC}"
    done
    echo ""
fi

if [[ ${#DEPLOYMENT_FAILURES[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Failed deployments:${NC}"
    for failure in "${DEPLOYMENT_FAILURES[@]}"; do
        echo -e "${RED}   ✗ $failure${NC}"
    done
    echo ""
    echo -e "${RED}🛑 Deployment completed with errors${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 All deployments completed successfully!${NC}"
    echo -e "${CYAN}   Deployment artifacts saved to: script/output/$ENVIRONMENT/{{chainId}}/{{NetworkName}}-latest.json${NC}"
    exit 0
fi
