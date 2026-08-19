#!/usr/bin/env bash

###################################################################################
# ONE-OFF: RH UpOFT — Bump ULN Configs from 3 to 4 DVNs (add Superform DVN)
###################################################################################
# The Superform DVN is now deployed on Robinhood Chain
# (0xa45CAa85283f2d8153F6250686f6d0A16fAd92DA), so RH's UpOFT ULN configs can be
# aligned with every other chain: 4 required DVNs (Nethermind, Canary, Superform,
# LZ Labs), 20 confirmations, no optional DVNs.
#
# Updates BOTH send and receive ULN configs on the RH LZ endpoint for all 4
# pathways (Ethereum, Base, HyperEVM, Flare) = up to 8 setConfig txs.
# Idempotent — already-matching configs are skipped.
#
# Prerequisite state (verified 2026-08-14): ETH/Base/HyperEVM/Flare all already
# send to RH with 4 DVNs incl. Superform, and their receive-from-RH configs
# require Superform — this update is the final piece that makes all 8 directions
# deliverable with the uniform 4-DVN set.
#
# DELETE THIS FILE AFTER EXECUTION.
#
# Usage:
#   ./script/deprecated/update_rh_dvns.sh simulate
#   ./script/deprecated/update_rh_dvns.sh execute [account]
#
#   simulate: dry-run every call via eth_call from the delegate EOA (no state change)
#   execute:  send txs with the local keystore account (default: v2-supervaults)
#
# Prerequisites:
#   - RH_RPC_URL set in .env
#   - Keystore account that is the UpOFT's LZ delegate on RH
#     (v2-supervaults = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
###################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-simulate}"
ACCOUNT="${2:-v2-supervaults}"
DELEGATE_EOA="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

# shellcheck disable=SC1091
source .env
if [[ -z "${RH_RPC_URL:-}" ]]; then
    echo "ERROR: RH_RPC_URL is not set in .env" >&2
    exit 1
fi

# ─── RH addresses ───────────────────────────────────────────────
UP_OFT="0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E"
LZ_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"

# ─── New 4-DVN set (RH addresses, sorted ascending as ULN requires) ─
DVN_NETHERMIND="0x0Ffe02DF012299A370D5dd69298A5826EAcaFdF8"
DVN_CANARY="0x8D77D35604A9f37f488E41D1d916b2A0088F82Dd"
DVN_SUPERFORM="0xa45CAa85283f2d8153F6250686f6d0A16fAd92DA"
DVN_LZ="0xd01ae6905d48315f7bE10C7330aeCF8360Ef5b12"

CONFIRMATIONS=20
ULN_CONFIG_TYPE=2

# Remote EIDs: Ethereum, Base, HyperEVM, Flare
EIDS=(30101 30184 30367 30295)
EID_NAMES=(Ethereum Base HyperEVM Flare)

ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
    "($CONFIRMATIONS,4,0,0,[$DVN_NETHERMIND,$DVN_CANARY,$DVN_SUPERFORM,$DVN_LZ],[])")

lower() { echo "$1" | tr 'A-F' 'a-f'; }

TX_COUNT=0
SKIP_COUNT=0

apply_config() { # <lib> <lib_label> <eid> <eid_name>
    local lib="$1" lib_label="$2" eid="$3" eid_name="$4"

    local current
    current=$(cast call "$LZ_ENDPOINT" "getConfig(address,address,uint32,uint32)(bytes)" \
        "$UP_OFT" "$lib" "$eid" "$ULN_CONFIG_TYPE" --rpc-url "$RH_RPC_URL")

    if [[ "$(lower "$current")" == "$(lower "$ULN_BYTES")" ]]; then
        echo "  SKIP  $lib_label / $eid_name ($eid): already 4 DVNs"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        return 0
    fi

    TX_COUNT=$((TX_COUNT + 1))
    if [[ "$MODE" == "simulate" ]]; then
        cast call "$LZ_ENDPOINT" \
            "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$UP_OFT" "$lib" "[($eid,$ULN_CONFIG_TYPE,$ULN_BYTES)]" \
            --from "$DELEGATE_EOA" --rpc-url "$RH_RPC_URL" > /dev/null
        echo "  OK    $lib_label / $eid_name ($eid): simulation passed (would update to 4 DVNs)"
    else
        cast send "$LZ_ENDPOINT" \
            "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$UP_OFT" "$lib" "[($eid,$ULN_CONFIG_TYPE,$ULN_BYTES)]" \
            --account "$ACCOUNT" --rpc-url "$RH_RPC_URL" > /dev/null
        echo "  SENT  $lib_label / $eid_name ($eid): updated to 4 DVNs"
    fi
}

case "$MODE" in
    simulate) echo "=== SIMULATION (no state changes) ===" ;;
    execute)  echo "=== EXECUTING with account: $ACCOUNT ===" ;;
    *) echo "Usage: $0 {simulate|execute} [account]" >&2; exit 1 ;;
esac

echo "RH endpoint: $LZ_ENDPOINT | UpOFT: $UP_OFT"
echo "New ULN: 20 confirmations, 4 DVNs (Nethermind, Canary, Superform, LZ Labs)"
echo ""

for i in "${!EIDS[@]}"; do
    apply_config "$SEND_LIB"    "send"    "${EIDS[$i]}" "${EID_NAMES[$i]}"
    apply_config "$RECEIVE_LIB" "receive" "${EIDS[$i]}" "${EID_NAMES[$i]}"
done

echo ""
echo "Done. ${TX_COUNT} config(s) $([[ "$MODE" == "simulate" ]] && echo "would be updated" || echo "updated"), ${SKIP_COUNT} already up to date."
if [[ "$MODE" == "execute" ]]; then
    echo "All RH pathways now run the uniform 4-DVN set. Verify with the smoke test if needed."
fi
