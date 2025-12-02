#!/usr/bin/env bash

###################################################################################
# SuperVault Parameters Listing Script
###################################################################################
# Description:
#   Lists all parameters of deployed SuperVaults for cross-checking production
#   configurations.
#
# Usage:
#   ./script/run/list_sv_params.sh <chain_id>
#
#   Parameters:
#     chain_id  Chain ID (e.g., 1 for Ethereum mainnet)
#
# Examples:
#   ./script/run/list_sv_params.sh 1
#
# Author: Superform Team
###################################################################################

set -euo pipefail

# Colors for better visual output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

###################################################################################
# SuperVault Addresses (Ethereum Mainnet - Chain ID 1)
###################################################################################

# superUSDC - Flagship USDC SuperVault
SUPER_USDC_VAULT="0xf6EbeA08a0Dfd44825f67Fa9963911c81BE2a947"
SUPER_USDC_STRATEGY="0x41A9Eb398518D2487301c61D2b33E4e966A9F1DD"
SUPER_USDC_ESCROW="0x11c016dFb1745A81587e5e3Fa8fc75f5693F427b"

# superWBTC - Flagship WBTC SuperVault
SUPER_WBTC_VAULT="0x8c365aF7094Eaac29314eDeE577B435892CA93A3"
SUPER_WBTC_STRATEGY="0xa96060B0B6907406EdBDf3cCc9438abf0F78Cf83"
SUPER_WBTC_ESCROW="0xdE61F1c76b1E169EF76faA2b97955F8714cd69d4"

# superWETH - Flagship WETH SuperVault
SUPER_WETH_VAULT="0xa036823b9A24F63c32553367bf181Ee04229c3AC"
SUPER_WETH_STRATEGY="0x1199a6B2587Ed96446E76Dee3FB660bb8fCfd0b2"
SUPER_WETH_ESCROW="0x41941100b24765ea0f31Bcc95094c5874D27c93d"

# sUP - UP SuperVault
SUP_VAULT="0x179aA9A1bDE3D2B8e9d10388D4Dde818a93FEED2"
SUP_STRATEGY="0xB66C9757CF54AD53F4fA0F68E72eE2F80f737943"
SUP_ESCROW="0x01C114c8Bc73E4ad34fa40D24cDAb5D83E67C16F"

# Global contracts
AGGREGATOR="0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698"
MAIN_MANAGER="0x3A4B6F0Cef9774E1Ee5B2d7409e9F10A8A837376"

###################################################################################
# Helper Functions
###################################################################################

print_header() {
    echo -e "${CYAN}+==========================================================================================+${NC}"
    echo -e "${CYAN}|                                                                                          |${NC}"
    echo -e "${CYAN}|${WHITE}                       SuperVault Parameters Listing Script                          ${CYAN}|${NC}"
    echo -e "${CYAN}|                                                                                          |${NC}"
    echo -e "${CYAN}+==========================================================================================+${NC}"
}

print_separator() {
    echo -e "${BLUE}--------------------------------------------------------------------------------------------${NC}"
}

print_vault_header() {
    local name=$1
    echo ""
    echo -e "${PURPLE}+-------------------------------------------------------------------------------------------+${NC}"
    echo -e "${PURPLE}|${WHITE}                                   $name${PURPLE}|${NC}"
    echo -e "${PURPLE}+-------------------------------------------------------------------------------------------+${NC}"
}

usage() {
    cat << EOF
Usage: $0 <chain_id>

Arguments:
    chain_id  Chain ID (e.g., 1 for Ethereum mainnet)

Examples:
    $0 1
EOF
    exit 1
}

# Get RPC URL based on chain ID
get_rpc_url() {
    local chain_id=$1
    case "$chain_id" in
        1)
            if [[ -n "${ETHEREUM_RPC_URL:-}" ]]; then
                echo "$ETHEREUM_RPC_URL"
            elif [[ -n "${ETH_MAINNET:-}" ]]; then
                echo "$ETH_MAINNET"
            else
                echo "https://eth.llamarpc.com"
            fi
            ;;
        *)
            echo "ERROR: Unsupported chain ID: $chain_id" >&2
            return 1
            ;;
    esac
}

# Call contract function and decode result
call_contract() {
    local contract=$1
    local sig=$2
    local rpc_url=$3

    FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$contract" "$sig" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR"
}

# Format address for display
format_address() {
    local addr=$1
    if [[ "$addr" == "ERROR" ]]; then
        echo -e "${RED}ERROR${NC}"
    else
        echo -e "${WHITE}$addr${NC}"
    fi
}

# Format number for display
format_number() {
    local num=$1
    if [[ "$num" == "ERROR" ]]; then
        echo -e "${RED}ERROR${NC}"
    else
        echo -e "${WHITE}$num${NC}"
    fi
}

# Format boolean for display
format_bool() {
    local val=$1
    if [[ "$val" == "true" || "$val" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]]; then
        echo -e "${GREEN}true${NC}"
    elif [[ "$val" == "false" || "$val" == "0x0000000000000000000000000000000000000000000000000000000000000000" ]]; then
        echo -e "${YELLOW}false${NC}"
    elif [[ "$val" == "ERROR" ]]; then
        echo -e "${RED}ERROR${NC}"
    else
        echo -e "${WHITE}$val${NC}"
    fi
}

# List parameters for a single SuperVault
list_vault_params() {
    local name=$1
    local vault=$2
    local strategy=$3
    local escrow=$4
    local rpc_url=$5

    print_vault_header "$name"

    echo -e "${CYAN}Addresses:${NC}"
    echo -e "  Vault:    ${WHITE}$vault${NC}"
    echo -e "  Strategy: ${WHITE}$strategy${NC}"
    echo -e "  Escrow:   ${WHITE}$escrow${NC}"

    echo ""
    echo -e "${CYAN}=== Vault (ERC4626/ERC7540) ===${NC}"

    # Vault basic info
    local vault_name=$(call_contract "$vault" "name()(string)" "$rpc_url")
    local vault_symbol=$(call_contract "$vault" "symbol()(string)" "$rpc_url")
    local vault_decimals=$(call_contract "$vault" "decimals()(uint8)" "$rpc_url")
    local vault_asset=$(call_contract "$vault" "asset()(address)" "$rpc_url")
    local vault_total_supply=$(call_contract "$vault" "totalSupply()(uint256)" "$rpc_url")
    local vault_total_assets=$(call_contract "$vault" "totalAssets()(uint256)" "$rpc_url")
    local vault_precision=$(call_contract "$vault" "PRECISION()(uint256)" "$rpc_url")
    local vault_strategy=$(call_contract "$vault" "strategy()(address)" "$rpc_url")
    local vault_escrow=$(call_contract "$vault" "escrow()(address)" "$rpc_url")
    local vault_share=$(call_contract "$vault" "share()(address)" "$rpc_url")
    local vault_super_governor=$(call_contract "$vault" "SUPER_GOVERNOR()(address)" "$rpc_url")

    echo -e "  Name:           $(format_address "$vault_name")"
    echo -e "  Symbol:         $(format_address "$vault_symbol")"
    echo -e "  Decimals:       $(format_number "$vault_decimals")"
    echo -e "  Asset:          $(format_address "$vault_asset")"
    echo -e "  Total Supply:   $(format_number "$vault_total_supply")"
    echo -e "  Total Assets:   $(format_number "$vault_total_assets")"
    echo -e "  PRECISION:      $(format_number "$vault_precision")"
    echo -e "  Strategy:       $(format_address "$vault_strategy")"
    echo -e "  Escrow:         $(format_address "$vault_escrow")"
    echo -e "  Share:          $(format_address "$vault_share")"
    echo -e "  SuperGovernor:  $(format_address "$vault_super_governor")"

    echo ""
    echo -e "${CYAN}=== Strategy ===${NC}"

    # Strategy info via getVaultInfo()
    local vault_info=$(call_contract "$strategy" "getVaultInfo()(address,address,uint8)" "$rpc_url")
    echo -e "  getVaultInfo(): $(format_address "$vault_info")"

    # Fee config via getConfigInfo()
    local config_info=$(call_contract "$strategy" "getConfigInfo()((uint256,uint256,address))" "$rpc_url")
    echo -e "  Fee Config (performanceFeeBps, managementFeeBps, recipient):"
    echo -e "    Raw:          $(format_address "$config_info")"

    # Individual fee config fields
    local perf_fee=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$strategy" "getConfigInfo()((uint256,uint256,address))" --rpc-url "$rpc_url" 2>/dev/null | head -1 || echo "ERROR")

    # PPS related
    local stored_pps=$(call_contract "$strategy" "getStoredPPS()(uint256)" "$rpc_url")
    local vault_hwm_pps=$(call_contract "$strategy" "vaultHwmPps()(uint256)" "$rpc_url")
    local pps_expiration=$(call_contract "$strategy" "ppsExpiration()(uint256)" "$rpc_url")
    local proposed_pps_expiry=$(call_contract "$strategy" "proposedPPSExpiryThreshold()(uint256)" "$rpc_url")
    local pps_expiry_effective=$(call_contract "$strategy" "ppsExpiryThresholdEffectiveTime()(uint256)" "$rpc_url")
    local precision=$(call_contract "$strategy" "PRECISION()(uint256)" "$rpc_url")

    echo -e "  Stored PPS:             $(format_number "$stored_pps")"
    echo -e "  Vault HWM PPS:          $(format_number "$vault_hwm_pps")"
    echo -e "  PPS Expiration:         $(format_number "$pps_expiration")"
    echo -e "  Proposed PPS Expiry:    $(format_number "$proposed_pps_expiry")"
    echo -e "  PPS Expiry Effective:   $(format_number "$pps_expiry_effective")"
    echo -e "  PRECISION:              $(format_number "$precision")"

    # SuperGovernor
    local super_governor=$(call_contract "$strategy" "SUPER_GOVERNOR()(address)" "$rpc_url")
    echo -e "  SuperGovernor:          $(format_address "$super_governor")"

    # Yield sources
    local yield_sources_count=$(call_contract "$strategy" "getYieldSourcesCount()(uint256)" "$rpc_url")
    echo -e "  Yield Sources Count:    $(format_number "$yield_sources_count")"

    local yield_sources=$(call_contract "$strategy" "getYieldSources()(address[])" "$rpc_url")
    echo -e "  Yield Sources:          $(format_address "$yield_sources")"

    # Unrealized profit
    local unrealized_profit=$(call_contract "$strategy" "vaultUnrealizedProfit()(uint256)" "$rpc_url")
    echo -e "  Unrealized Profit:      $(format_number "$unrealized_profit")"

    echo ""
    echo -e "${CYAN}=== Aggregator Data for Strategy ===${NC}"

    # Aggregator data
    local agg_pps=$(call_contract "$AGGREGATOR" "getPPS(address)(uint256)" "$rpc_url" "$strategy" 2>/dev/null || \
                   FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getPPS(address)(uint256)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local last_update=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getLastUpdateTimestamp(address)(uint256)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local min_interval=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getMinUpdateInterval(address)(uint256)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local max_staleness=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getMaxStaleness(address)(uint256)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local deviation_threshold=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getDeviationThreshold(address)(uint256)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local is_paused=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "isStrategyPaused(address)(bool)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local is_pps_stale=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "isPPSStale(address)(bool)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local main_manager=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getMainManager(address)(address)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local secondary_managers=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getSecondaryManagers(address)(address[])" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local upkeep_balance=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getUpkeepBalance(address)(uint256)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local last_unpause=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getLastUnpauseTimestamp(address)(uint256)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local global_hooks_root=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getGlobalHooksRoot()(bytes32)" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local strategy_hooks_root=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getStrategyHooksRoot(address)(bytes32)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local is_global_vetoed=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "isGlobalHooksRootVetoed()(bool)" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local is_strategy_vetoed=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "isStrategyHooksRootVetoed(address)(bool)" "$strategy" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")

    echo -e "  PPS:                    $(format_number "$agg_pps")"
    echo -e "  Last Update Timestamp:  $(format_number "$last_update")"
    echo -e "  Min Update Interval:    $(format_number "$min_interval")"
    echo -e "  Max Staleness:          $(format_number "$max_staleness")"
    echo -e "  Deviation Threshold:    $(format_number "$deviation_threshold")"
    echo -e "  Is Paused:              $(format_bool "$is_paused")"
    echo -e "  Is PPS Stale:           $(format_bool "$is_pps_stale")"
    echo -e "  Main Manager:           $(format_address "$main_manager")"
    echo -e "  Secondary Managers:     $(format_address "$secondary_managers")"
    echo -e "  Upkeep Balance:         $(format_number "$upkeep_balance")"
    echo -e "  Last Unpause Timestamp: $(format_number "$last_unpause")"
    echo -e "  Global Hooks Root:      $(format_address "$global_hooks_root")"
    echo -e "  Strategy Hooks Root:    $(format_address "$strategy_hooks_root")"
    echo -e "  Global Root Vetoed:     $(format_bool "$is_global_vetoed")"
    echo -e "  Strategy Root Vetoed:   $(format_bool "$is_strategy_vetoed")"

    echo ""
    echo -e "${CYAN}=== Escrow ===${NC}"

    # Escrow balance
    local escrowed_assets=$(call_contract "$vault" "getEscrowedAssets()(uint256)" "$rpc_url")
    echo -e "  Escrowed Assets:        $(format_number "$escrowed_assets")"
}

###################################################################################
# Main
###################################################################################

main() {
    print_header

    # Check if arguments are provided
    if [ $# -lt 1 ]; then
        echo -e "${RED}Error: Missing required argument: chain_id${NC}"
        usage
    fi

    local chain_id="$1"

    # Get RPC URL
    local rpc_url
    rpc_url=$(get_rpc_url "$chain_id")
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to get RPC URL for chain $chain_id${NC}"
        exit 1
    fi

    print_separator
    echo -e "${BLUE}Configuration${NC}"
    echo -e "${CYAN}  Chain ID: ${WHITE}$chain_id${NC}"
    echo -e "${CYAN}  RPC URL:  ${WHITE}${rpc_url:0:50}...${NC}"
    echo -e "${CYAN}  Aggregator: ${WHITE}$AGGREGATOR${NC}"
    echo -e "${CYAN}  Main Manager: ${WHITE}$MAIN_MANAGER${NC}"
    print_separator

    # Global aggregator info
    echo ""
    echo -e "${PURPLE}+-------------------------------------------------------------------------------------------+${NC}"
    echo -e "${PURPLE}|${WHITE}                              Global Aggregator Info                                  ${PURPLE}|${NC}"
    echo -e "${PURPLE}+-------------------------------------------------------------------------------------------+${NC}"

    local sv_count=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getSuperVaultsCount()(uint256)" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local hooks_timelock=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getHooksRootUpdateTimelock()(uint256)" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")
    local current_nonce=$(FOUNDRY_DISABLE_NIGHTLY_WARNING=1 cast call "$AGGREGATOR" "getCurrentNonce()(uint256)" --rpc-url "$rpc_url" 2>/dev/null || echo "ERROR")

    echo -e "  SuperVaults Count:      $(format_number "$sv_count")"
    echo -e "  Hooks Root Timelock:    $(format_number "$hooks_timelock")"
    echo -e "  Current Nonce:          $(format_number "$current_nonce")"

    # List all vault params
    list_vault_params "superUSDC - Flagship USDC SuperVault" "$SUPER_USDC_VAULT" "$SUPER_USDC_STRATEGY" "$SUPER_USDC_ESCROW" "$rpc_url"
    list_vault_params "superWBTC - Flagship WBTC SuperVault" "$SUPER_WBTC_VAULT" "$SUPER_WBTC_STRATEGY" "$SUPER_WBTC_ESCROW" "$rpc_url"
    list_vault_params "superWETH - Flagship WETH SuperVault" "$SUPER_WETH_VAULT" "$SUPER_WETH_STRATEGY" "$SUPER_WETH_ESCROW" "$rpc_url"
    list_vault_params "sUP - UP SuperVault                 " "$SUP_VAULT" "$SUP_STRATEGY" "$SUP_ESCROW" "$rpc_url"

    print_separator
    echo -e "${GREEN}Done listing SuperVault parameters!${NC}"
}

main "$@"
