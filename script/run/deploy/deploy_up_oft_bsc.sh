#!/usr/bin/env bash

###################################################################################
# Deploy + Configure UpOFT on BSC (BNB Chain, id 56, LZ eid 30102)
###################################################################################
# Deploys UpOFT and wires all 5 pathways (Ethereum, Base, HyperEVM, Flare, RH)
# with the same setup as every other chain (verified on-chain 2026-08-14):
#   - send + receive libraries explicitly pinned (SendUln302 / ReceiveUln302)
#   - ULN: 20 confirmations, 4 required DVNs, no optional DVNs
#   - Executor config: maxMessageSize 10000
#   - Enforced options: SEND 300k gas, SEND_AND_CALL 300k + 1M compose gas
#
# BSC DVNs (LZ metadata registry, verified on-chain; sorted ascending as ULN requires):
#   Nethermind: 0x31f748a368a893bdb5abb67ec95f232507601a73
#   Superform:  0xf4c489afd83625f510947e63ff8f90dfee0ae46c
#   Canary:     0xfa9ba83c102283958b997adc8b44ed3a3cdb5dda
#   LZ Labs:    0xfd6865c841c2d64565562fcc7e05e619a30615f0
#
# The deployer (v2-supervaults) becomes owner AND LZ delegate, so every step here
# is executable from the same keystore account. Transfer ownership to the multisig
# afterwards (see TransferUpOFTOwnership.s.sol).
#
# NOTE: this configures the BSC side only. Each remote chain still needs its own
# txs for the reverse direction (setPeer to the new BSC OFT, pin libs, ULN and
# enforced options for eid 30102) before the pathways are usable.
#
# Usage:
#   ./script/run/deploy/deploy_up_oft_bsc.sh deploy [account]        # deploy UpOFT, writes address to
#                                                             # script/output/prod/56/BNB-latest.json
#   ./script/run/deploy/deploy_up_oft_bsc.sh simulate                # dry-run BSC-side configuration
#   ./script/run/deploy/deploy_up_oft_bsc.sh configure [account]
#   ./script/run/deploy/deploy_up_oft_bsc.sh simulate-rh             # dry-run RH -> BSC wiring
#   ./script/run/deploy/deploy_up_oft_bsc.sh configure-rh [account]
#
# The configure/simulate modes read the deployed OFT address from
# script/output/prod/56/BNB-latest.json (override with env var BSC_OFT if needed).
#
# configure    = BSC side only (peers, libs, ULN, options on BSC — all v2-supervaults).
# configure-rh = the RH -> BSC reverse direction (RH UpOFT owner + delegate are also
#                v2-supervaults, verified on-chain). The remaining reverse directions
#                (ETH/Base/HyperEVM = multisig, Flare = its own deployer EOA) need
#                separate calldata.
#
# Prerequisites:
#   - BNB_RPC_URL in .env (falls back to the public https://bsc-dataseed.binance.org)
#   - v2-supervaults foundry keystore account (0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
###################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
    echo "Usage: $0 {deploy|simulate|configure|simulate-rh|configure-rh} [args]" >&2
    exit 1
fi

# shellcheck disable=SC1091
source .env
RPC="${BNB_RPC_URL:-https://bsc-dataseed.binance.org}"

DELEGATE="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8" # v2-supervaults

OUTPUT_FILE="script/output/prod/56/BNB-latest.json"

read_bsc_oft() {
    if [[ -n "${BSC_OFT:-}" ]]; then
        echo "$BSC_OFT"
    elif [[ -f "$OUTPUT_FILE" ]]; then
        python3 -c "import json; print(json.load(open('$OUTPUT_FILE')).get('UpOFT',''))"
    fi
}

require_bsc_oft() {
    OFT=$(read_bsc_oft)
    if [[ -z "$OFT" ]]; then
        echo "ERROR: no UpOFT address in $OUTPUT_FILE — run '$0 deploy' first (or set BSC_OFT env var)" >&2
        exit 1
    fi
}

# ─── BSC LZ infra (verified on-chain + LZ metadata) ─────────────
LZ_ENDPOINT="0x1a44076050125825900e736c501f859c50fE728c"
SEND_LIB="0x9f8C645F2D0b2159767Bd6E0839DE4BE49e823DE"
RECEIVE_LIB="0xB217266c3A98C8B2709Ee26836C98cf12f6cCEC1"
EXECUTOR="0x3ebD570ed38B1b3b4BC886999fcF507e9D584859"

# ─── BSC DVNs (sorted ascending) ────────────────────────────────
DVN_NETHERMIND="0x31f748a368a893bdb5abb67ec95f232507601a73"
DVN_SUPERFORM="0xf4c489afd83625f510947e63ff8f90dfee0ae46c"
DVN_CANARY="0xfa9ba83c102283958b997adc8b44ed3a3cdb5dda"
DVN_LZ="0xfd6865c841c2d64565562fcc7e05e619a30615f0"

CONFIRMATIONS=20
MAX_MESSAGE_SIZE=10000
EXECUTOR_CONFIG_TYPE=1
ULN_CONFIG_TYPE=2

# ─── Remote pathways: eid, name, peer OFT (verified on-chain) ───
EIDS=(30101 30184 30367 30295 30416)
EID_NAMES=(Ethereum Base HyperEVM Flare RH)
PEERS=(
    0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD  # Ethereum UpOFTAdapter
    0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B  # Base UpOFT
    0x642fFC3496AcA19106BAB7A42F1F221a329654fe  # HyperEVM UpOFT
    0xe030A89fd2b7f858c8aA47725679CA25D467dFD1  # Flare UpOFT
    0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E  # RH UpOFT
)

# Canonical enforced options (identical on every existing chain, verified on-chain)
SEND_OPTS="0x000301001101000000000000000000000000000493e0"
CALL_OPTS="0x000301001101000000000000000000000000000493e0010013030000000000000000000000000000000f4240"

ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
    "($CONFIRMATIONS,4,0,0,[$DVN_NETHERMIND,$DVN_SUPERFORM,$DVN_CANARY,$DVN_LZ],[])")
EXEC_BYTES=$(cast abi-encode "f((uint32,address))" "($MAX_MESSAGE_SIZE,$EXECUTOR)")

lower() { echo "$1" | tr 'A-F' 'a-f'; }

# FOUNDRY_TEST + --skip work around stale test files vs the bumped v2-core submodule
build() {
    FOUNDRY_TEST=test/integration/SuperBank forge build --skip "*RevenueDistribution*" > /dev/null
}

# tx <description> <target> <sig+args...>  — simulate (cast call) or execute (cast send)
TX_COUNT=0
SKIP_COUNT=0
tx() {
    local desc="$1" target="$2"; shift 2
    TX_COUNT=$((TX_COUNT + 1))
    if [[ "$SIMULATE" == "1" ]]; then
        cast call "$target" "$@" --from "$DELEGATE" --rpc-url "$RPC" > /dev/null
        echo "  OK    $desc (simulated)"
    else
        cast send "$target" "$@" --account "$ACCOUNT" --rpc-url "$RPC" > /dev/null
        echo "  SENT  $desc"
    fi
}
skip() { echo "  SKIP  $1"; SKIP_COUNT=$((SKIP_COUNT + 1)); }

case "$MODE" in

deploy)
    ACCOUNT="${2:-v2-supervaults}"
    echo "=== Deploying UpOFT on BSC via deterministic deployer (rpc: ${RPC%%/rpc*}) ==="
    build

    # Same CREATE2 scheme as DeployUpOFT.s.sol (_getSalt / DeterministicDeployerLib):
    #   salt    = keccak256("SuperformV2" . "TEST1.0.0" . "UpOFT" . "v2.0")  [prod namespace]
    #   factory = canonical deterministic-deployment proxy
    # BSC shares endpoint + owner with Base, so the predicted address equals Base's UpOFT.
    FACTORY="0x4e59b44847b379578588920cA78FbF26c0B4956C"
    SALT=$(cast keccak "$(cast concat-hex "$(cast from-utf8 "SuperformV2")" "$(cast from-utf8 "TEST1.0.0")" "$(cast from-utf8 "UpOFT")" "$(cast from-utf8 "v2.0")")")

    BYTECODE=$(python3 -c "import json; print(json.load(open('out/UpOFT.sol/UpOFT.json'))['bytecode']['object'])")
    ARGS=$(cast abi-encode "constructor(address,address)" "$LZ_ENDPOINT" "$DELEGATE")
    INITCODE="${BYTECODE}${ARGS#0x}"
    OFT=$(cast create2 --deployer "$FACTORY" --salt "$SALT" --init-code "$INITCODE" | tail -1)

    echo "Constructor: endpoint=$LZ_ENDPOINT delegate/owner=$DELEGATE"
    echo "Salt:        $SALT"
    echo "Predicted:   $OFT"

    if [[ "$(cast code "$OFT" --rpc-url "$RPC")" != "0x" ]]; then
        echo "UpOFT already deployed at $OFT — skipping deploy"
    else
        TXHASH=$(cast send --account "$ACCOUNT" --rpc-url "$RPC" --json "$FACTORY" "${SALT}${INITCODE#0x}" \
            | python3 -c "import json,sys; print(json.load(sys.stdin)['transactionHash'])")
        echo "Deploy tx: $TXHASH"
        [[ "$(cast code "$OFT" --rpc-url "$RPC")" != "0x" ]] || { echo "ERROR: no code at predicted address after deploy" >&2; exit 1; }
        echo "Deployed UpOFT at: $OFT"
    fi

    mkdir -p "$(dirname "$OUTPUT_FILE")"
    python3 - "$OUTPUT_FILE" "$OFT" <<'PY'
import json, os, sys
path, addr = sys.argv[1], sys.argv[2]
data = json.load(open(path)) if os.path.exists(path) else {}
data["UpOFT"] = addr
json.dump(data, open(path, "w"), indent=2)
open(path, "a").write("\n")
PY
    echo "Recorded in $OUTPUT_FILE"
    echo ""
    echo "Next: ./script/run/deploy/deploy_up_oft_bsc.sh simulate"
    echo "Then: ./script/run/deploy/deploy_up_oft_bsc.sh configure"
    echo ""
    echo "Verify on BscScan:"
    echo "  forge verify-contract $OFT src/UP/UpOFT.sol:UpOFT --chain 56 \\"
    echo "    --constructor-args $ARGS --etherscan-api-key \$ETHERSCAN_API_KEY --watch"
    ;;

simulate|configure)
    require_bsc_oft
    ACCOUNT="${2:-v2-supervaults}"
    SIMULATE=0; [[ "$MODE" == "simulate" ]] && SIMULATE=1
    [[ "$SIMULATE" == "1" ]] && echo "=== SIMULATION (no state changes) ===" || echo "=== CONFIGURING with account: $ACCOUNT ==="
    echo "UpOFT: $OFT | Endpoint: $LZ_ENDPOINT"
    echo ""

    for i in "${!EIDS[@]}"; do
        eid=${EIDS[$i]}; name=${EID_NAMES[$i]}; peer=${PEERS[$i]}
        peer32="0x000000000000000000000000$(lower "${peer#0x}")"
        echo "── $name (eid $eid) ──"

        # 1. setPeer [owner]
        if [[ "$(lower "$(cast call "$OFT" 'peers(uint32)(bytes32)' "$eid" --rpc-url "$RPC")")" == "$peer32" ]]; then
            skip "setPeer: already $peer"
        else
            tx "setPeer -> $peer" "$OFT" "setPeer(uint32,bytes32)" "$eid" "$peer32"
        fi

        # 2. pin send library [delegate]
        if [[ "$(lower "$(cast call "$LZ_ENDPOINT" 'getSendLibrary(address,uint32)(address)' "$OFT" "$eid" --rpc-url "$RPC")")" == "$(lower "$SEND_LIB")" \
              && "$(cast call "$LZ_ENDPOINT" 'isDefaultSendLibrary(address,uint32)(bool)' "$OFT" "$eid" --rpc-url "$RPC")" == "false" ]]; then
            skip "setSendLibrary: already pinned"
        else
            tx "setSendLibrary" "$LZ_ENDPOINT" "setSendLibrary(address,uint32,address)" "$OFT" "$eid" "$SEND_LIB"
        fi

        # 3. pin receive library [delegate]
        rl=$(cast call "$LZ_ENDPOINT" 'getReceiveLibrary(address,uint32)(address,bool)' "$OFT" "$eid" --rpc-url "$RPC")
        if [[ "$(lower "$(echo "$rl" | sed -n 1p)")" == "$(lower "$RECEIVE_LIB")" && "$(echo "$rl" | sed -n 2p)" == "false" ]]; then
            skip "setReceiveLibrary: already pinned"
        else
            tx "setReceiveLibrary" "$LZ_ENDPOINT" "setReceiveLibrary(address,uint32,address,uint256)" "$OFT" "$eid" "$RECEIVE_LIB" 0
        fi

        # 4. send config: executor + ULN [delegate]
        if [[ "$(lower "$(cast call "$LZ_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$OFT" "$SEND_LIB" "$eid" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")")" == "$(lower "$ULN_BYTES")" ]]; then
            skip "setConfig(send): already 4 DVNs / 20 conf"
        else
            tx "setConfig(send: executor + ULN)" "$LZ_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
                "$OFT" "$SEND_LIB" "[($eid,$EXECUTOR_CONFIG_TYPE,$EXEC_BYTES),($eid,$ULN_CONFIG_TYPE,$ULN_BYTES)]"
        fi

        # 5. receive config: ULN [delegate]
        if [[ "$(lower "$(cast call "$LZ_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$OFT" "$RECEIVE_LIB" "$eid" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")")" == "$(lower "$ULN_BYTES")" ]]; then
            skip "setConfig(receive): already 4 DVNs / 20 conf"
        else
            tx "setConfig(receive: ULN)" "$LZ_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
                "$OFT" "$RECEIVE_LIB" "[($eid,$ULN_CONFIG_TYPE,$ULN_BYTES)]"
        fi
        echo ""
    done

    # 6. enforced options for all eids in one call [owner]
    ALL_SET=1
    for eid in "${EIDS[@]}"; do
        [[ "$(lower "$(cast call "$OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$eid" 1 --rpc-url "$RPC")")" == "$SEND_OPTS" ]] || ALL_SET=0
        [[ "$(lower "$(cast call "$OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$eid" 2 --rpc-url "$RPC")")" == "$CALL_OPTS" ]] || ALL_SET=0
    done
    if [[ "$ALL_SET" == "1" ]]; then
        skip "setEnforcedOptions: already set for all 5 eids"
    else
        PARAMS=""
        for eid in "${EIDS[@]}"; do
            PARAMS+="($eid,1,$SEND_OPTS),($eid,2,$CALL_OPTS),"
        done
        tx "setEnforcedOptions (5 eids x SEND/SEND_AND_CALL)" "$OFT" \
            "setEnforcedOptions((uint32,uint16,bytes)[])" "[${PARAMS%,}]"
    fi

    echo ""
    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    echo ""
    echo "REMINDER: remote sides still need wiring for eid 30102 (peer -> $OFT, pinned"
    echo "libs, 20-conf/4-DVN ULN, enforced options) on Ethereum, Base, HyperEVM, Flare, RH."
    ;;

simulate-rh|configure-rh)
    require_bsc_oft
    ACCOUNT="${2:-v2-supervaults}"
    SIMULATE=0; [[ "$MODE" == "simulate-rh" ]] && SIMULATE=1

    if [[ -z "${RH_RPC_URL:-}" ]]; then
        echo "ERROR: RH_RPC_URL is not set in .env" >&2
        exit 1
    fi
    RPC="$RH_RPC_URL"

    # ─── RH LZ infra (verified on-chain) ────────────────────────
    RH_OFT="0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E"
    RH_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
    RH_SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
    RH_RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"
    RH_EXECUTOR="0x4208d6E27538189bB48E603D6123A94b8Abe0A0b"
    BSC_EID=30102

    # RH 4-DVN set (sorted ascending; matches the live RH configs post Superform-DVN update)
    RH_ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
        "($CONFIRMATIONS,4,0,0,[0x0Ffe02DF012299A370D5dd69298A5826EAcaFdF8,0x8D77D35604A9f37f488E41D1d916b2A0088F82Dd,0xa45CAa85283f2d8153F6250686f6d0A16fAd92DA,0xd01ae6905d48315f7bE10C7330aeCF8360Ef5b12],[])")
    RH_EXEC_BYTES=$(cast abi-encode "f((uint32,address))" "($MAX_MESSAGE_SIZE,$RH_EXECUTOR)")

    [[ "$SIMULATE" == "1" ]] && echo "=== RH -> BSC SIMULATION (no state changes) ===" || echo "=== RH -> BSC CONFIGURING with account: $ACCOUNT ==="
    echo "RH UpOFT: $RH_OFT | BSC peer: $OFT"
    echo ""

    peer32="0x000000000000000000000000$(lower "${OFT#0x}")"

    # 1. setPeer [owner]
    if [[ "$(lower "$(cast call "$RH_OFT" 'peers(uint32)(bytes32)' "$BSC_EID" --rpc-url "$RPC")")" == "$peer32" ]]; then
        skip "setPeer: already $OFT"
    else
        tx "setPeer -> $OFT" "$RH_OFT" "setPeer(uint32,bytes32)" "$BSC_EID" "$peer32"
    fi

    # 2. pin send library [delegate]
    if [[ "$(lower "$(cast call "$RH_ENDPOINT" 'getSendLibrary(address,uint32)(address)' "$RH_OFT" "$BSC_EID" --rpc-url "$RPC")")" == "$(lower "$RH_SEND_LIB")" \
          && "$(cast call "$RH_ENDPOINT" 'isDefaultSendLibrary(address,uint32)(bool)' "$RH_OFT" "$BSC_EID" --rpc-url "$RPC")" == "false" ]]; then
        skip "setSendLibrary: already pinned"
    else
        tx "setSendLibrary" "$RH_ENDPOINT" "setSendLibrary(address,uint32,address)" "$RH_OFT" "$BSC_EID" "$RH_SEND_LIB"
    fi

    # 3. pin receive library [delegate]
    rl=$(cast call "$RH_ENDPOINT" 'getReceiveLibrary(address,uint32)(address,bool)' "$RH_OFT" "$BSC_EID" --rpc-url "$RPC")
    if [[ "$(lower "$(echo "$rl" | sed -n 1p)")" == "$(lower "$RH_RECEIVE_LIB")" && "$(echo "$rl" | sed -n 2p)" == "false" ]]; then
        skip "setReceiveLibrary: already pinned"
    else
        tx "setReceiveLibrary" "$RH_ENDPOINT" "setReceiveLibrary(address,uint32,address,uint256)" "$RH_OFT" "$BSC_EID" "$RH_RECEIVE_LIB" 0
    fi

    # 4. send config: executor + ULN [delegate]
    if [[ "$(lower "$(cast call "$RH_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$RH_OFT" "$RH_SEND_LIB" "$BSC_EID" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")")" == "$(lower "$RH_ULN_BYTES")" ]]; then
        skip "setConfig(send): already 4 DVNs / 20 conf"
    else
        tx "setConfig(send: executor + ULN)" "$RH_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$RH_OFT" "$RH_SEND_LIB" "[($BSC_EID,$EXECUTOR_CONFIG_TYPE,$RH_EXEC_BYTES),($BSC_EID,$ULN_CONFIG_TYPE,$RH_ULN_BYTES)]"
    fi

    # 5. receive config: ULN [delegate]
    if [[ "$(lower "$(cast call "$RH_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$RH_OFT" "$RH_RECEIVE_LIB" "$BSC_EID" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")")" == "$(lower "$RH_ULN_BYTES")" ]]; then
        skip "setConfig(receive): already 4 DVNs / 20 conf"
    else
        tx "setConfig(receive: ULN)" "$RH_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$RH_OFT" "$RH_RECEIVE_LIB" "[($BSC_EID,$ULN_CONFIG_TYPE,$RH_ULN_BYTES)]"
    fi

    # 6. enforced options [owner]
    if [[ "$(lower "$(cast call "$RH_OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$BSC_EID" 1 --rpc-url "$RPC")")" == "$SEND_OPTS" \
          && "$(lower "$(cast call "$RH_OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$BSC_EID" 2 --rpc-url "$RPC")")" == "$CALL_OPTS" ]]; then
        skip "setEnforcedOptions: already set for eid $BSC_EID"
    else
        tx "setEnforcedOptions (SEND + SEND_AND_CALL)" "$RH_OFT" \
            "setEnforcedOptions((uint32,uint16,bytes)[])" "[($BSC_EID,1,$SEND_OPTS),($BSC_EID,2,$CALL_OPTS)]"
    fi

    echo ""
    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    echo ""
    echo "REMINDER: ETH/Base/HyperEVM (multisig) and Flare (deployer 0x0f0Db7CE...) still"
    echo "need their reverse-direction wiring for eid 30102 via separate calldata."
    ;;

*)
    echo "Usage: $0 {deploy|simulate|configure|simulate-rh|configure-rh} [args]" >&2
    exit 1
    ;;
esac
