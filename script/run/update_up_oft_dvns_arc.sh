#!/usr/bin/env bash

###################################################################################
# Update the UpOFT DVN set on Arc: 3-of-3 -> 4-of-4 (adds the Superform DVN)
###################################################################################
# Arc was originally wired 3-of-3 (Nethermind, LZ Labs, Canary) because the Superform
# DVN had no deployment on Arc and, on every remote chain, its dstConfig(30417).gas was
# 0 — see the DVN PARITY note in deploy_up_oft_arc.sh. Both halves of that have since
# changed, verified on-chain 2026-09-24:
#
#   - the Superform DVN IS deployed on Arc at 0xfa9ba83c102283958b997adc8b44ed3a3cdb5dda
#     and serves all six remote eids (dstConfig.gas = 77000 for each);
#   - the remote Superform DVNs now serve eid 30417 too (gas = 77000 on Ethereum, Base,
#     HyperEVM and Flare), so the reverse legs can match this 4-DVN set when they are wired.
#
# This script only touches the ULN config (config type 2) on Arc, for both the send and
# the receive library, on all six pathways. It does not touch peers, libraries, the
# executor config or enforced options — those are already correct from deploy_up_oft_arc.sh.
#
# Target ULN (identical on send and receive, matching every other chain):
#   confirmations 20, requiredDVNCount 4, optionalDVNCount 0, threshold 0
#   required DVNs, ascending as the ULN demands:
#     0x9e0e95ede70f680f74480b510ff9f45c70e3da80  Nethermind
#     0xa2447e5b58d357c49bf74b50b14421e6a100e525  LZ Labs
#     0xacde1f22eeab249d3ca6ba8805c8fee9f52a16e7  Canary
#     0xfa9ba83c102283958b997adc8b44ed3a3cdb5dda  Superform   <- added here
#
# ON THE RECEIVE SIDE, ORDER MATTERS. A destination's receive ULN names the DVNs whose
# attestation is REQUIRED for an inbound message to be delivered. Raising Arc's receive
# requirement to 4 while a remote's send config still pays only 3 would leave every message
# from that chain permanently unverifiable. That is safe today only because NO reverse leg
# is wired yet — all six remote UpOFTs have peers(30417) == 0, checked by `check` below and
# re-checked before configuring. Once a reverse leg IS wired, it must be wired with the
# 4-DVN set from the start.
#
# Usage:
#   ./script/run/update_up_oft_dvns_arc.sh check                 # read-only: DVN support, current vs target, reverse legs
#   ./script/run/update_up_oft_dvns_arc.sh simulate              # dry-run the setConfig calls
#   ./script/run/update_up_oft_dvns_arc.sh configure [account]   # send them (default account: v2-supervaults)
#
# Prerequisites:
#   - ARC_RPC_URL in .env (falls back to the public https://rpc.mainnet.arc.io)
#   - the v2-supervaults keystore account — it is the LZ delegate for the Arc UpOFT, which is
#     what setConfig requires (owner is only needed for peers/enforced options, untouched here).
#     The password is asked once at the start of `configure` and reused for every tx.
#   - optional: ETHEREUM_RPC_URL / BASE_RPC_URL / HYPEREVM_RPC_URL / FLARE_RPC_URL / RH_RPC_URL
#     to include the reverse-leg safety check for those chains
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
RPC="${ARC_RPC_URL:-https://rpc.mainnet.arc.io}"

DELEGATE="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8" # v2-supervaults; LZ delegate for the Arc UpOFT
OUTPUT_FILE="script/output/prod/5042/Arc-latest.json"

# ─── Arc LZ infra (shares addresses with RH) ────────────────────
LZ_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"

# ─── Arc DVNs, ascending (ULN requires sorted, unique) ──────────
DVN_NETHERMIND="0x9e0e95ede70f680f74480b510ff9f45c70e3da80"
DVN_LZ="0xa2447e5b58d357c49bf74b50b14421e6a100e525"
DVN_CANARY="0xacde1f22eeab249d3ca6ba8805c8fee9f52a16e7"
DVN_SUPERFORM="0xfa9ba83c102283958b997adc8b44ed3a3cdb5dda"

CONFIRMATIONS=20
ULN_CONFIG_TYPE=2
ARC_EID=30417

ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
    "($CONFIRMATIONS,4,0,0,[$DVN_NETHERMIND,$DVN_LZ,$DVN_CANARY,$DVN_SUPERFORM],[])")

# ─── Remote pathways (peer OFTs are only used for the reverse-leg check) ───
EIDS=(30101 30184 30102 30367 30295 30416)
EID_NAMES=(Ethereum Base BSC HyperEVM Flare RH)
REMOTE_OFTS=(
    0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD  # Ethereum UpOFTAdapter
    0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B  # Base UpOFT
    0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B  # BSC UpOFT
    0x642fFC3496AcA19106BAB7A42F1F221a329654fe  # HyperEVM UpOFT
    0xe030A89fd2b7f858c8aA47725679CA25D467dFD1  # Flare UpOFT
    0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E  # RH UpOFT
)
REMOTE_RPCS=(
    "${ETHEREUM_RPC_URL:-}"
    "${BASE_RPC_URL:-}"
    "${BSC_RPC_URL:-}"
    "${HYPEREVM_RPC_URL:-}"
    "${FLARE_RPC_URL:-}"
    "${RH_RPC_URL:-}"
)

lower() { echo "$1" | tr 'A-F' 'a-f'; }

read_arc_oft() {
    if [[ -n "${ARC_OFT:-}" ]]; then
        echo "$ARC_OFT"
    elif [[ -f "$OUTPUT_FILE" ]]; then
        python3 -c "import json; print(json.load(open('$OUTPUT_FILE')).get('UpOFT',''))"
    fi
}

OFT=$(read_arc_oft)
if [[ -z "$OFT" ]]; then
    echo "ERROR: no UpOFT address in $OUTPUT_FILE (or set ARC_OFT)" >&2
    exit 1
fi

# ─── Preflight: every DVN must serve every destination ──────────
# DVNFeeLib reverts DVN_EidNotSupported when dstConfig.gas == 0, so listing a DVN that does
# not serve a destination makes every quoteSend()/send() on that pathway revert.
preflight_dvns() {
    local all=1
    echo "── DVN destination support (Arc -> remotes) ──"
    if [[ "$(cast code "$DVN_SUPERFORM" --rpc-url "$RPC")" == "0x" ]]; then
        echo "  FAIL  Superform DVN $DVN_SUPERFORM has no code on Arc"
        return 1
    fi
    for i in "${!EIDS[@]}"; do
        local eid=${EIDS[$i]} name=${EID_NAMES[$i]} line=""
        for dvn in "$DVN_NETHERMIND" "$DVN_LZ" "$DVN_CANARY" "$DVN_SUPERFORM"; do
            local gas
            gas=$(cast call "$dvn" 'dstConfig(uint32)(uint64,uint16,uint128)' "$eid" --rpc-url "$RPC" 2>/dev/null | sed -n 1p | awk '{print $1}')
            if [[ -z "$gas" || "$gas" == "0" ]]; then
                line+=" FAIL(${dvn:0:10}…)"; all=0
            else
                line+=" ok(${dvn:0:10}…=$gas)"
            fi
        done
        printf "  %-9s eid %-6s%s\n" "$name" "$eid" "$line"
    done
    [[ "$all" == "1" ]] || { echo "ERROR: a DVN does not serve some destination — configuring would break quoting on that pathway" >&2; return 1; }
    echo ""
}

# ─── Safety: no reverse leg may already be wired with a smaller DVN set ───
# Arc's receive ULN says which DVNs MUST attest an inbound message. If a remote is already
# sending with 3 DVNs, raising Arc to 4 strands its messages. Unwired legs (peer == 0) are
# safe: they will be wired with the 4-DVN set.
check_reverse_legs() {
    local wired=0
    local arc_peer32="0x000000000000000000000000$(lower "${OFT#0x}")"
    echo "── Reverse legs (remote -> Arc): is eid $ARC_EID already peered? ──"
    for i in "${!EIDS[@]}"; do
        local name=${EID_NAMES[$i]} oft=${REMOTE_OFTS[$i]} rpc=${REMOTE_RPCS[$i]}
        if [[ -z "$rpc" ]]; then
            printf "  %-9s no RPC in .env — UNCHECKED\n" "$name"
            continue
        fi
        local p
        p=$(lower "$(cast call "$oft" 'peers(uint32)(bytes32)' "$ARC_EID" --rpc-url "$rpc" 2>/dev/null || echo "")")
        if [[ "$p" == "$arc_peer32" ]]; then
            printf "  %-9s WIRED — its send config must already list 4 DVNs\n" "$name"; wired=1
        elif [[ -z "$p" || "$p" == "0x0000000000000000000000000000000000000000000000000000000000000000" ]]; then
            printf "  %-9s not wired (safe)\n" "$name"
        else
            printf "  %-9s peer set to something else: %s\n" "$name" "$p"; wired=1
        fi
    done
    echo ""
    return $wired
}

# tx <description> <lib> <eid> <target> <sig+args...>
# Retries cast send on transient RPC errors (the public Arc RPC is load-balanced and a lagging
# node returns "request beyond head block" while polling the receipt). Before each retry the
# on-chain config is re-read: if the tx already landed, it is treated as sent, not re-sent.
TX_COUNT=0
SKIP_COUNT=0
MAX_ATTEMPTS=5
tx() {
    local desc="$1" lib="$2" eid="$3" target="$4"; shift 4
    TX_COUNT=$((TX_COUNT + 1))
    if [[ "$SIMULATE" == "1" ]]; then
        cast call "$target" "$@" --from "$DELEGATE" --rpc-url "$RPC" > /dev/null
        echo "  OK    $desc (simulated)"
        return 0
    fi
    local attempt=1 err
    while :; do
        if err=$(cast send "$target" "$@" --account "$ACCOUNT" --password "$KEYSTORE_PASSWORD" --rpc-url "$RPC" 2>&1 > /dev/null); then
            echo "  SENT  $desc"
            return 0
        fi
        sleep 3
        if [[ "$(current_uln "$lib" "$eid")" == "$(lower "$ULN_BYTES")" ]]; then
            echo "  SENT  $desc (rpc error after broadcast, but config is on-chain)"
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

current_uln() {
    local lib=$1 eid=$2
    lower "$(cast call "$LZ_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$OFT" "$lib" "$eid" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")"
}

case "$MODE" in

check)
    echo "=== Arc UpOFT DVN check (read-only) ==="
    echo "UpOFT: $OFT | Endpoint: $LZ_ENDPOINT"
    echo ""
    preflight_dvns || true
    check_reverse_legs || true
    echo "── Current ULN vs target (4 DVNs, 20 confirmations) ──"
    for i in "${!EIDS[@]}"; do
        eid=${EIDS[$i]}; name=${EID_NAMES[$i]}
        s=$(current_uln "$SEND_LIB" "$eid"); r=$(current_uln "$RECEIVE_LIB" "$eid")
        printf "  %-9s send %s   receive %s\n" "$name" \
            "$([[ "$s" == "$(lower "$ULN_BYTES")" ]] && echo "4 DVNs (done)" || echo "needs update")" \
            "$([[ "$r" == "$(lower "$ULN_BYTES")" ]] && echo "4 DVNs (done)" || echo "needs update")"
    done
    ;;

simulate|configure)
    ACCOUNT="${2:-v2-supervaults}"
    SIMULATE=0; [[ "$MODE" == "simulate" ]] && SIMULATE=1

    # Ask for the keystore password once; every cast send reuses it via --password.
    KEYSTORE_PASSWORD=""
    if [[ "$SIMULATE" == "0" ]]; then
        read -r -s -p "Enter keystore password for '$ACCOUNT': " KEYSTORE_PASSWORD; echo
        signer=$(lower "$(cast wallet address --account "$ACCOUNT" --password "$KEYSTORE_PASSWORD" 2>/dev/null || true)")
        if [[ -z "$signer" ]]; then
            echo "ERROR: could not unlock keystore account '$ACCOUNT' (wrong password or unknown account)" >&2; exit 1
        fi
        if [[ "$signer" != "$(lower "$DELEGATE")" ]]; then
            echo "ERROR: account '$ACCOUNT' is $signer, but the LZ delegate is $DELEGATE" >&2; exit 1
        fi
    fi

    preflight_dvns

    if ! check_reverse_legs; then
        echo "ERROR: a reverse leg is already wired. Raising Arc's receive requirement to 4 DVNs" >&2
        echo "       would strand inbound messages unless that chain's send config lists 4 DVNs." >&2
        echo "       Verify the remote send ULN first, then re-run with FORCE_RECEIVE=1." >&2
        [[ "${FORCE_RECEIVE:-0}" == "1" ]] || exit 1
        echo "       FORCE_RECEIVE=1 set — continuing anyway." >&2
    fi

    [[ "$SIMULATE" == "1" ]] && echo "=== SIMULATION (no state changes) ===" || echo "=== CONFIGURING with account: $ACCOUNT ==="
    echo "UpOFT: $OFT | adding Superform DVN $DVN_SUPERFORM"
    echo ""

    for i in "${!EIDS[@]}"; do
        eid=${EIDS[$i]}; name=${EID_NAMES[$i]}
        echo "── $name (eid $eid) ──"

        if [[ "$(current_uln "$SEND_LIB" "$eid")" == "$(lower "$ULN_BYTES")" ]]; then
            skip "setConfig(send): already 4 DVNs / 20 conf"
        else
            tx "setConfig(send: ULN 4 DVNs)" "$SEND_LIB" "$eid" "$LZ_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
                "$OFT" "$SEND_LIB" "[($eid,$ULN_CONFIG_TYPE,$ULN_BYTES)]"
        fi

        if [[ "$(current_uln "$RECEIVE_LIB" "$eid")" == "$(lower "$ULN_BYTES")" ]]; then
            skip "setConfig(receive): already 4 DVNs / 20 conf"
        else
            tx "setConfig(receive: ULN 4 DVNs)" "$RECEIVE_LIB" "$eid" "$LZ_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
                "$OFT" "$RECEIVE_LIB" "[($eid,$ULN_CONFIG_TYPE,$ULN_BYTES)]"
        fi
        echo ""
    done

    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    echo ""
    echo "REMINDER: deploy_up_oft_arc.sh still encodes the old 3-of-3 set (its ULN_BYTES and its"
    echo "RH reverse-leg constants). Update it before running its configure modes again, or it"
    echo "will propose rolling Arc back to 3 DVNs. Reverse legs must be wired 4-of-4 from the start."
    ;;

*)
    echo "Usage: $0 {check|simulate|configure} [account]" >&2
    exit 1
    ;;
esac
