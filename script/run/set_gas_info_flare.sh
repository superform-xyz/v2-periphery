#!/usr/bin/env bash

###################################################################################
# Set the ECDSAPPSOracle gas-per-update on Flare SuperGovernor (0 -> 135000)
###################################################################################
# Flare production has upkeep payments enabled but getGasInfo(ECDSAPPSOracle) == 0.
# SuperGovernor._convertGasToUpkeepToken quotes 0 gas -> 0 wei, SuperOracleBase discards
# the zero quote and reverts NO_VALID_REPORTED_PRICES; SuperVaultAggregator.forwardPPS
# catches that and sets upkeepCost = 0, so PPS updates run without charging upkeep.
#
# Fix: setGasInfo(oracle, 135000) — the same value every other chain and the repo's
# GAS_PER_ENTRY constant use. Only GAS_MANAGER_ROLE may call it. On Flare that role is
# held solely by an EOA we do not have locally, but the deployer (v2-supervaults keystore)
# holds DEFAULT_ADMIN_ROLE, which administers GAS_MANAGER_ROLE. So:
#
#   1. grantRole(GAS_MANAGER_ROLE, deployer)     (skipped if already held)
#   2. setGasInfo(ECDSAPPSOracle, 135000)        (skipped if already set)
#   3. revokeRole(GAS_MANAGER_ROLE, deployer)    (skipped if it was held before we started)
#
# Usage:
#   ./script/run/set_gas_info_flare.sh check                 # read-only: current state, roles, cost
#   ./script/run/set_gas_info_flare.sh simulate              # dry-run the calls as the signer
#   ./script/run/set_gas_info_flare.sh configure [account]   # send them (default account: v2-supervaults)
#
# Prerequisites:
#   - FLARE_RPC_URL in .env
#   - the v2-supervaults keystore account (must resolve to SIGNER below)
###################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
    echo "Usage: $0 {check|simulate|configure} [account]" >&2
    exit 1
fi

# shellcheck disable=SC1091
source .env
RPC="${FLARE_RPC_URL:?FLARE_RPC_URL not set in .env}"

# ─── Flare production ──────────────────────────────────────────
GOVERNOR=0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4
PPS_ORACLE=0x366d88F03B8EF34eb49F32a927ff6e1609F694F2
SIGNER=0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8   # deployer; DEFAULT_ADMIN_ROLE on Flare SuperGovernor
GAS_PER_ENTRY=135000                                 # script/utils/ConfigBase.sol GAS_PER_ENTRY
DEFAULT_ADMIN_ROLE=0x0000000000000000000000000000000000000000000000000000000000000000

lower() { echo "$1" | tr 'A-F' 'a-f'; }

GAS_MANAGER_ROLE=$(cast call "$GOVERNOR" 'GAS_MANAGER_ROLE()(bytes32)' --rpc-url "$RPC")

has_role()       { cast call "$GOVERNOR" 'hasRole(bytes32,address)(bool)' "$1" "$2" --rpc-url "$RPC"; }
gas_info()       { cast call "$GOVERNOR" 'getGasInfo(address)(uint256)' "$PPS_ORACLE" --rpc-url "$RPC" | awk '{print $1}'; }
upkeep_enabled() { cast call "$GOVERNOR" 'isUpkeepPaymentsEnabled()(bool)' --rpc-url "$RPC"; }
upkeep_cost()    { cast call "$GOVERNOR" 'getUpkeepCostPerSingleUpdate(address)(uint256)' "$PPS_ORACLE" --rpc-url "$RPC" 2>/dev/null | awk '{print $1}' || true; }

print_state() {
    local gi cost
    gi=$(gas_info); cost=$(upkeep_cost)
    echo "  upkeep payments enabled : $(upkeep_enabled)"
    echo "  getGasInfo(pps oracle)  : $gi $([[ "$gi" == "$GAS_PER_ENTRY" ]] && echo '(target)' || echo "(target $GAS_PER_ENTRY)")"
    if [[ -n "$cost" ]]; then
        echo "  upkeep cost per update  : $cost wei UP ($(cast from-wei "$cost") UP)"
    else
        echo "  upkeep cost per update  : REVERTS (NO_VALID_REPORTED_PRICES)"
    fi
    echo "  signer $SIGNER"
    echo "    DEFAULT_ADMIN_ROLE    : $(has_role "$DEFAULT_ADMIN_ROLE" "$SIGNER")"
    echo "    GAS_MANAGER_ROLE      : $(has_role "$GAS_MANAGER_ROLE" "$SIGNER")"
}

# tx <description> <verify-fn> <sig+args...>
# Retries on transient RPC errors; before each retry re-checks on-chain state via verify-fn
# so a tx that landed despite an RPC error is not re-sent.
TX_COUNT=0; SKIP_COUNT=0; MAX_ATTEMPTS=5
tx() {
    local desc="$1" verify="$2"; shift 2
    TX_COUNT=$((TX_COUNT + 1))
    if [[ "$SIMULATE" == "1" ]]; then
        cast call "$GOVERNOR" "$@" --from "$SIGNER" --rpc-url "$RPC" > /dev/null
        echo "  OK    $desc (simulated)"
        return 0
    fi
    local attempt=1 err
    while :; do
        if err=$(cast send "$GOVERNOR" "$@" --account "$ACCOUNT" --password "$KEYSTORE_PASSWORD" --rpc-url "$RPC" 2>&1 > /dev/null); then
            echo "  SENT  $desc"
            return 0
        fi
        sleep 3
        if "$verify"; then
            echo "  SENT  $desc (rpc error after broadcast, but state is on-chain)"
            return 0
        fi
        if (( attempt >= MAX_ATTEMPTS )); then
            echo "  FAIL  $desc after $attempt attempts: $err" >&2
            return 1
        fi
        echo "  RETRY $desc (attempt $attempt failed: ${err##*Error: })" >&2
        attempt=$((attempt + 1))
        sleep $((attempt * 2))
    done
}
skip() { echo "  SKIP  $1"; SKIP_COUNT=$((SKIP_COUNT + 1)); }

v_granted() { [[ "$(has_role "$GAS_MANAGER_ROLE" "$SIGNER")" == "true" ]]; }
v_revoked() { [[ "$(has_role "$GAS_MANAGER_ROLE" "$SIGNER")" == "false" ]]; }
v_gas_set() { [[ "$(gas_info)" == "$GAS_PER_ENTRY" ]]; }

case "$MODE" in

check)
    echo "=== Flare SuperGovernor gas info check (read-only) ==="
    echo "Governor: $GOVERNOR | ECDSAPPSOracle: $PPS_ORACLE"
    print_state
    ;;

simulate|configure)
    ACCOUNT="${2:-v2-supervaults}"
    SIMULATE=0; [[ "$MODE" == "simulate" ]] && SIMULATE=1

    KEYSTORE_PASSWORD=""
    if [[ "$SIMULATE" == "0" ]]; then
        read -r -s -p "Enter keystore password for '$ACCOUNT': " KEYSTORE_PASSWORD; echo
        signer=$(lower "$(cast wallet address --account "$ACCOUNT" --password "$KEYSTORE_PASSWORD" 2>/dev/null || true)")
        [[ -n "$signer" ]] || { echo "ERROR: could not unlock keystore account '$ACCOUNT'" >&2; exit 1; }
        [[ "$signer" == "$(lower "$SIGNER")" ]] || { echo "ERROR: account '$ACCOUNT' is $signer, expected $SIGNER" >&2; exit 1; }
    fi

    [[ "$SIMULATE" == "1" ]] && echo "=== SIMULATION (no state changes) ===" || echo "=== CONFIGURING with account: $ACCOUNT ==="
    echo "Governor: $GOVERNOR | ECDSAPPSOracle: $PPS_ORACLE"
    echo ""
    echo "── Before ──"; print_state; echo ""

    if v_gas_set; then
        echo "Gas info already $GAS_PER_ENTRY — nothing to do."
        exit 0
    fi

    HAD_ROLE=0; v_granted && HAD_ROLE=1
    if [[ "$HAD_ROLE" == "0" && "$(has_role "$DEFAULT_ADMIN_ROLE" "$SIGNER")" != "true" ]]; then
        echo "ERROR: $SIGNER holds neither GAS_MANAGER_ROLE nor DEFAULT_ADMIN_ROLE — cannot proceed" >&2
        exit 1
    fi

    # 1. grant
    if [[ "$HAD_ROLE" == "1" ]]; then
        skip "grantRole(GAS_MANAGER_ROLE): signer already holds it"
    else
        tx "grantRole(GAS_MANAGER_ROLE, signer)" v_granted \
            'grantRole(bytes32,address)' "$GAS_MANAGER_ROLE" "$SIGNER"
    fi

    # 2. set gas info. In simulate mode the grant has not landed, so the role check would
    #    fail against live state; note it rather than pretend it passed.
    if [[ "$SIMULATE" == "1" && "$HAD_ROLE" == "0" ]]; then
        echo "  NOTE  setGasInfo($PPS_ORACLE, $GAS_PER_ENTRY) not simulated: depends on the grant above landing first"
        echo "  NOTE  revokeRole(GAS_MANAGER_ROLE, signer) not simulated: same reason"
    else
        tx "setGasInfo($PPS_ORACLE, $GAS_PER_ENTRY)" v_gas_set \
            'setGasInfo(address,uint256)' "$PPS_ORACLE" "$GAS_PER_ENTRY"

        # 3. revoke, only if we granted it in this run
        if [[ "$HAD_ROLE" == "1" ]]; then
            skip "revokeRole(GAS_MANAGER_ROLE): signer held it before this run, leaving as-is"
        else
            tx "revokeRole(GAS_MANAGER_ROLE, signer)" v_revoked \
                'revokeRole(bytes32,address)' "$GAS_MANAGER_ROLE" "$SIGNER"
        fi
    fi

    echo ""
    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    if [[ "$SIMULATE" == "0" ]]; then
        echo ""
        echo "── After ──"; print_state
        v_gas_set || { echo "ERROR: gas info is not $GAS_PER_ENTRY after configure" >&2; exit 1; }
        [[ -n "$(upkeep_cost)" ]] || { echo "ERROR: getUpkeepCostPerSingleUpdate still reverts" >&2; exit 1; }
        if [[ "$HAD_ROLE" == "0" ]] && v_granted; then
            echo "WARNING: signer still holds GAS_MANAGER_ROLE — revoke did not land" >&2; exit 1
        fi
    fi
    ;;

*)
    echo "Usage: $0 {check|simulate|configure} [account]" >&2
    exit 1
    ;;
esac
