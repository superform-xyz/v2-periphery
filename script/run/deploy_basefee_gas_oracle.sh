#!/usr/bin/env bash

###################################################################################
# Deploy BasefeeGasOracle Script
###################################################################################
#
# Deploys BasefeeGasOracle - a basefee-derived gas price oracle replacing the
# deprecated Chainlink Fast Gas feed for SuperOracle's GAS_QUOTE -> WEI_QUOTE pair.
#
# Designed for Ethereum mainnet (1). Deployable on any supported chain, but note
# that on L2s block.basefee excludes L1 data fees (the Solidity script prints a
# warning for chainId != 1).
#
# Usage:
#   ./deploy_basefee_gas_oracle.sh <environment> <mode> [account] [chain_id]
#
# Parameters:
#   environment  "prod" or "staging"
#   mode         "simulate", "execute", or "check"
#   account      Account name for execute mode (e.g., "v2-deployer")
#   chain_id     Target chain ID (optional; omit to run on all supported chains)
#
# Examples:
#   ./deploy_basefee_gas_oracle.sh staging check 1
#   ./deploy_basefee_gas_oracle.sh staging simulate v2-deployer 1
#   ./deploy_basefee_gas_oracle.sh staging simulate 1
#   ./deploy_basefee_gas_oracle.sh prod execute v2-deployer 1
#   ./deploy_basefee_gas_oracle.sh prod simulate v2-deployer      # all chains
#
# Configuration (env var overrides):
#   ADMIN              DEFAULT_ADMIN_ROLE holder  (default: Superform Treasury multisig)
#   GAS_MANAGER_ADDR   GAS_MANAGER_ROLE holder    (default: platform GAS_MANAGER)
#   MULTIPLIER_BPS     Custom multiplier          (default: script's 20_000 = 2x)
#   PRIORITY_FEE_WEI   Custom priority fee        (default: script's 1_000_000 wei)
#   Note: ADMIN and GAS_MANAGER_ADDR must differ (enforced by the deploy script).
#   Custom knobs change the CREATE2 address - use the same values in check mode.
#
# Output:
#   Deployed address is merged into script/output/{env}/{chainId}/{Chain}-latest.json
#   by the Solidity script (".BasefeeGasOracle" key), same as other deployments.
#
# Prerequisites:
#   - 1Password CLI configured for RPC URL access
#   - For execute mode: Foundry account configured (e.g., "v2-deployer")
#
###################################################################################

set -euo pipefail

###################################################################################
# Constants
###################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# DEFAULT_ADMIN_ROLE holder (Superform Treasury multisig - ConfigBase.SUPERFORM_TREASURY)
readonly ADMIN="${ADMIN:-0x1dbD9b26b295A33f126456Ab4e498cd308622f08}"

# GAS_MANAGER_ROLE holder (platform gas manager - ConfigBase.GAS_MANAGER)
# Must be a different key than ADMIN (enforced by DeployBasefeeGasOracle)
readonly GAS_MANAGER_ADDR="${GAS_MANAGER_ADDR:-0x4d7AACD4b72e6BC6eA0eee6AA61A773A8b556B99}"

# Sender for simulate mode (v2 deployer keystore address)
readonly SIMULATE_SENDER="${SIMULATE_SENDER:-0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8}"

# Optional custom calibration (empty = use the Solidity script defaults: 20_000 bps, 1e6 wei)
readonly MULTIPLIER_BPS="${MULTIPLIER_BPS:-}"
readonly PRIORITY_FEE_WEI="${PRIORITY_FEE_WEI:-}"

# Supported chains: "CHAIN_ID:CHAIN_NAME" (mainnet is the primary target)
readonly SUPPORTED_CHAINS=(
    "1:Ethereum"
    "8453:Base"
    "999:HyperEVM"
    "14:Flare"
)

###################################################################################
# Helper Functions
###################################################################################

log() {
    local level=$1
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

usage() {
    cat << EOF
Usage: $0 <environment> <mode> [account] [chain_id]

Arguments:
    environment  Environment: "prod" or "staging" (required)
    mode         Mode: "simulate", "execute", or "check" (required)
    account      Account name (required for execute mode, e.g., "v2-deployer")
    chain_id     Target chain ID (optional; omit to run on all supported chains)

Examples:
    # Check deployment status on mainnet
    $0 staging check 1

    # Simulate deployment on mainnet
    $0 staging simulate v2-deployer 1

    # Execute deployment on mainnet (prod)
    $0 prod execute v2-deployer 1

    # Simulate on all supported chains
    $0 staging simulate v2-deployer

Supported chains: Ethereum (1), Base (8453), HyperEVM (999), Flare (14).
Primary target is Ethereum (1) - the oracle is basefee-derived and the Solidity
script warns on L2 deployments.

EOF
    exit 1
}

# Source network configuration based on environment
source_network_config() {
    local environment=$1
    local network_config_file

    if [ "$environment" = "staging" ]; then
        network_config_file="$SCRIPT_DIR/networks-staging.sh"
    else
        network_config_file="$SCRIPT_DIR/networks-production.sh"
    fi

    if [ ! -f "$network_config_file" ]; then
        log "ERROR" "Network config not found: $network_config_file"
        exit 1
    fi

    log "INFO" "Loading network configuration from: $network_config_file"
    source "$network_config_file"
}

# Validate environment parameter
validate_environment() {
    local environment=$1
    if [ "$environment" != "staging" ] && [ "$environment" != "prod" ]; then
        log "ERROR" "Invalid environment: $environment"
        log "ERROR" "Must be either 'staging' or 'prod'"
        exit 1
    fi
}

# Validate mode parameter
validate_mode() {
    local mode=$1
    if [ "$mode" != "simulate" ] && [ "$mode" != "execute" ] && [ "$mode" != "check" ]; then
        log "ERROR" "Invalid mode: $mode"
        log "ERROR" "Must be 'simulate', 'execute', or 'check'"
        exit 1
    fi
}

# Get RPC URL for a given chain ID (uses get_rpc_var from the networks config)
get_chain_rpc_url() {
    local chain_id=$1
    local rpc_var
    rpc_var=$(get_rpc_var "$chain_id" 2>/dev/null) || { echo ""; return; }
    echo "${!rpc_var:-}"
}

# Deploy on a single chain
deploy_on_chain() {
    local env=$1
    local chain_id=$2
    local chain_name=$3
    local mode=$4
    local account=$5
    local rpc_url=$6

    log "INFO" "--------------------------------------------"
    log "INFO" "Target chain: $chain_name (ID: $chain_id)"
    log "INFO" "--------------------------------------------"

    # Set flags based on mode
    local BROADCAST_FLAG=""
    local VERIFY_FLAG=""
    local SENDER_FLAG=""
    local ACCOUNT_FLAG=""
    local ETHERSCAN_FLAGS=""

    if [ "$mode" = "execute" ]; then
        BROADCAST_FLAG="--broadcast"
        ACCOUNT_FLAG="--account $account"
        # Only enable etherscan verification for chains that support it (not HyperEVM/Flare)
        if [ "$chain_id" != "999" ] && [ "$chain_id" != "14" ]; then
            VERIFY_FLAG="--verify"
            ETHERSCAN_FLAGS="--etherscan-api-key $ETHERSCANV2_API_KEY --verifier etherscan"
        fi
        log "INFO" "Mode: Execute (will broadcast using account: $account)"
    elif [ "$mode" = "simulate" ]; then
        SENDER_FLAG="--sender $SIMULATE_SENDER"
        log "INFO" "Mode: Simulate (no broadcast, using sender: $SIMULATE_SENDER)"
    else
        log "INFO" "Mode: Check (read-only)"
    fi

    # Build forge command
    local forge_cmd="forge script"
    forge_cmd+=" script/DeployBasefeeGasOracle.s.sol:DeployBasefeeGasOracle"

    if [ -n "$MULTIPLIER_BPS" ] || [ -n "$PRIORITY_FEE_WEI" ]; then
        # Custom calibration (both knobs required together to keep the CREATE2 address explicit)
        if [ -z "$MULTIPLIER_BPS" ] || [ -z "$PRIORITY_FEE_WEI" ]; then
            log "ERROR" "Set both MULTIPLIER_BPS and PRIORITY_FEE_WEI (or neither)"
            return 1
        fi
        if [ "$mode" = "check" ]; then
            forge_cmd+=" --sig 'runCheck(uint256,uint64,uint256,uint256,address,address)'"
        else
            forge_cmd+=" --sig 'run(uint256,uint64,uint256,uint256,address,address)'"
        fi
        forge_cmd+=" $env $chain_id $MULTIPLIER_BPS $PRIORITY_FEE_WEI $ADMIN $GAS_MANAGER_ADDR"
    else
        # Default calibration (20_000 bps = 2x, 1_000_000 wei tip)
        if [ "$mode" = "check" ]; then
            forge_cmd+=" --sig 'runCheck(uint256,uint64,address,address)'"
        else
            forge_cmd+=" --sig 'run(uint256,uint64,address,address)'"
        fi
        forge_cmd+=" $env $chain_id $ADMIN $GAS_MANAGER_ADDR"
    fi

    forge_cmd+=" --rpc-url '$rpc_url'"
    forge_cmd+=" --chain $chain_id"
    [ -n "$ACCOUNT_FLAG" ] && forge_cmd+=" $ACCOUNT_FLAG"
    [ -n "$SENDER_FLAG" ] && forge_cmd+=" $SENDER_FLAG"
    [ -n "$BROADCAST_FLAG" ] && forge_cmd+=" $BROADCAST_FLAG"
    [ -n "$VERIFY_FLAG" ] && forge_cmd+=" $VERIFY_FLAG"
    [ -n "$ETHERSCAN_FLAGS" ] && forge_cmd+=" $ETHERSCAN_FLAGS"

    # Add verbosity
    forge_cmd+=" -vvvv"

    log "INFO" "Executing forge script..."
    log "INFO" ""

    # Execute (capture exit code to prevent set -e from exiting)
    local exit_code=0
    eval "$forge_cmd" || exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log "ERROR" "Run failed on $chain_name ($chain_id) with exit code: $exit_code"
        return $exit_code
    fi

    log "INFO" "$chain_name ($chain_id) run successful"
    return 0
}

###################################################################################
# Main
###################################################################################

main() {
    # Check minimum arguments
    if [ $# -lt 2 ]; then
        log "ERROR" "Missing required arguments"
        usage
    fi

    local environment="$1"
    local mode="$2"
    local account=""
    local target_chain_id=""

    # Arg 3 can be an account name or a chain id; arg 4 (if present) is the chain id.
    # Supports: "staging simulate v2-deployer 1", "staging check 1", "staging simulate v2-deployer"
    if [ $# -ge 3 ]; then
        if [[ "$3" =~ ^[0-9]+$ ]]; then
            target_chain_id="$3"
        else
            account="$3"
            if [ $# -ge 4 ]; then
                if [[ "$4" =~ ^[0-9]+$ ]]; then
                    target_chain_id="$4"
                else
                    log "ERROR" "chain_id must be numeric, got: $4"
                    usage
                fi
            fi
        fi
    fi

    # Validate inputs
    validate_environment "$environment"
    validate_mode "$mode"

    # Source network configuration
    source_network_config "$environment"

    # Validate account for execute mode
    if [ "$mode" = "execute" ]; then
        if [ -z "$account" ]; then
            log "ERROR" "Account name is required for execute mode"
            log "ERROR" "Usage: $0 $environment execute <account_name> [chain_id]"
            exit 1
        fi
        log "INFO" "Using account: $account"
    fi

    # Validate target chain (if provided) against supported chains
    if [ -n "$target_chain_id" ]; then
        local found=""
        for chain_def in "${SUPPORTED_CHAINS[@]}"; do
            IFS=':' read -r cid _ <<< "$chain_def"
            [ "$cid" = "$target_chain_id" ] && found=1
        done
        if [ -z "$found" ]; then
            log "ERROR" "Unsupported chain ID: $target_chain_id"
            log "ERROR" "Supported: ${SUPPORTED_CHAINS[*]}"
            exit 1
        fi
    fi

    # Map environment to env number
    local env
    case "$environment" in
        prod)
            env=0
            ;;
        staging)
            env=2
            ;;
    esac

    # Load RPC URLs from 1Password (loads ETH_MAINNET, BASE_MAINNET, etc.)
    log "INFO" "Loading RPC URLs..."
    load_rpc_urls

    # Load HyperEVM RPC separately (not in network config)
    if [ -z "$target_chain_id" ] || [ "$target_chain_id" = "999" ]; then
        log "INFO" "Loading HyperEVM RPC URL..."
        if ! export HYPEREVM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/HYPEREVM_RPC_URL/credential 2>/dev/null); then
            log "WARN" "HYPEREVM_RPC_URL not in 1Password, using default RPC"
            export HYPEREVM_MAINNET="https://rpc.hyperliquid.xyz/evm"
        fi
    fi

    # Satisfy foundry.toml [etherscan] env var references
    export ETHERSCANV2_API_KEY_TEST="${ETHERSCANV2_API_KEY_TEST:-}"

    # Load Etherscan API key for verification (needed for Ethereum/Base)
    if [ "$mode" = "execute" ]; then
        log "INFO" "Loading Etherscan API credentials..."
        if ! load_etherscan_api_key; then
            log "WARN" "Failed to load Etherscan API key. Contract verification will not work."
        fi
    fi

    log "INFO" "============================================"
    log "INFO" "Deploy BasefeeGasOracle"
    log "INFO" "============================================"
    log "INFO" "Environment: $environment (env=$env)"
    log "INFO" "Mode: $mode"
    log "INFO" "Admin (DEFAULT_ADMIN_ROLE): $ADMIN"
    log "INFO" "Gas Manager (GAS_MANAGER_ROLE): $GAS_MANAGER_ADDR"
    if [ -n "$MULTIPLIER_BPS" ]; then
        log "INFO" "Calibration: ${MULTIPLIER_BPS} bps + ${PRIORITY_FEE_WEI} wei (custom)"
    else
        log "INFO" "Calibration: 20000 bps (2x) + 1000000 wei (script defaults)"
    fi
    if [ -n "$target_chain_id" ]; then
        log "INFO" "Target Chain: $target_chain_id"
    else
        log "INFO" "Target Chains: all supported (${SUPPORTED_CHAINS[*]})"
    fi
    log "INFO" "============================================"

    local successful_chains=()
    local skipped_chains=()
    local failed_chains=()

    # Run on each supported chain (filtered to target_chain_id when provided)
    for chain_def in "${SUPPORTED_CHAINS[@]}"; do
        IFS=':' read -r chain_id chain_name <<< "$chain_def"

        if [ -n "$target_chain_id" ] && [ "$chain_id" != "$target_chain_id" ]; then
            continue
        fi

        # Get RPC URL for this chain
        local rpc_url
        rpc_url=$(get_chain_rpc_url "$chain_id")

        if [ -z "$rpc_url" ]; then
            log "WARN" "Skipping $chain_name ($chain_id) - RPC URL not available"
            skipped_chains+=("$chain_name ($chain_id)")
            continue
        fi

        if deploy_on_chain "$env" "$chain_id" "$chain_name" "$mode" "$account" "$rpc_url"; then
            successful_chains+=("$chain_name ($chain_id)")
        else
            failed_chains+=("$chain_name ($chain_id)")
        fi

        log "INFO" ""
    done

    # Summary
    log "INFO" ""
    log "INFO" "============================================"
    log "INFO" "Run Summary"
    log "INFO" "============================================"

    if [ ${#successful_chains[@]} -gt 0 ]; then
        log "INFO" "Succeeded:"
        for chain in "${successful_chains[@]}"; do
            log "INFO" "  ✓ $chain"
        done
    fi

    if [ ${#skipped_chains[@]} -gt 0 ]; then
        log "INFO" "Skipped:"
        for chain in "${skipped_chains[@]}"; do
            log "INFO" "  - $chain"
        done
    fi

    if [ ${#failed_chains[@]} -gt 0 ]; then
        log "WARN" "Failed:"
        for chain in "${failed_chains[@]}"; do
            log "WARN" "  ✗ $chain"
        done
    fi

    log "INFO" "============================================"

    if [ ${#failed_chains[@]} -gt 0 ]; then
        log "ERROR" "Completed with failures"
        exit 1
    fi

    log "INFO" "Completed successfully!"
}

main "$@"
