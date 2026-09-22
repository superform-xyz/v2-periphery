#!/usr/bin/env bash

###################################################################################
# Deploy + Configure UpOFT on Arc (Circle Arc L1, id 5042, LZ eid 30417)
###################################################################################
# Deploys UpOFT and wires all 6 pathways (Ethereum, Base, BSC, HyperEVM, Flare, RH)
# with the same setup as every other chain:
#   - send + receive libraries explicitly pinned (SendUln302 / ReceiveUln302)
#   - ULN: 20 confirmations, 3 required DVNs, no optional DVNs
#   - Executor config: maxMessageSize 10000
#   - Enforced options: SEND 300k gas, SEND_AND_CALL 300k + 1M compose gas
#
# Arc LZ infra (LZ metadata registry, verified on-chain 2026-09-18; the endpoint, libs and
# executor share their addresses with RH):
#   EndpointV2:    0x6F475642a6e85809B1c36Fa62763669b1b48DD5B
#   SendUln302:    0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7
#   ReceiveUln302: 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043
#   Executor:      0x4208d6E27538189bB48E603D6123A94b8Abe0A0b
#
# Arc DVNs (sorted ascending as ULN requires):
#   Nethermind: 0x9e0e95ede70f680f74480b510ff9f45c70e3da80
#   LZ Labs:    0xa2447e5b58d357c49bf74b50b14421e6a100e525
#   Canary:     0xacde1f22eeab249d3ca6ba8805c8fee9f52a16e7
#
# DVN PARITY — audited on-chain 2026-09-18 across all 30 live pathways (ETH/Base/BSC/HyperEVM/
# Flare/RH): every one is pinned SendUln302/ReceiveUln302, 20 confirmations on send AND receive,
# 4 required DVNs (LZ Labs, Superform, Canary, Nethermind), 0 optional, executor maxMessageSize
# 10000, identical enforced options. Arc CANNOT match the 4-DVN set today:
#   - the Superform DVN has no deployment on Arc (no code at 0xf4c489af...), and on every remote
#     chain its dstConfig(30417).gas == 0, i.e. it does not serve the Arc destination at all;
#   - on ETH/Base/BSC/HyperEVM the LZ Labs and Nethermind DVNs also have dstConfig(30417).gas == 0
#     (only Canary serves Arc from those chains today); on Flare and RH all three serve Arc.
#   DVNFeeLib reverts with DVN_EidNotSupported when dstConfig.gas == 0, so listing an unsupported
#   DVN makes every quoteSend()/send() to Arc revert. Hence Arc runs 3-of-3 (Nethermind, LZ Labs,
#   Canary) on its side, and the reverse legs must use the same 3 DVNs (never Superform). Run
#   `check-dvns` (below) before configuring: it re-reads dstConfig on-chain and aborts on gas == 0.
#   Restoring 4-of-4 parity requires deploying the Superform DVN on Arc and enabling eid 30417 on
#   the Superform DVNs of every remote chain.
#
# The deployer (v2-supervaults) becomes owner AND LZ delegate, so every step here
# is executable from the same keystore account. Transfer ownership to the multisig
# afterwards (see TransferUpOFTOwnership.s.sol) - once the SuperGovernor Safe exists on Arc.
#
# Because the endpoint and delegate are the same as on RH, the CREATE2 address equals the
# RH UpOFT: 0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E (UP_TOKEN_ARC in ConfigBase.sol).
#
# NOTE: this configures the Arc side only. Each remote chain still needs its own
# txs for the reverse direction (setPeer to the new Arc OFT, pin libs, ULN and
# enforced options for eid 30417) before the pathways are usable.
#
# Usage:
#   ./script/run/deploy_up_oft_arc.sh deploy [account]        # deploy UpOFT, writes address to
#                                                             # script/output/prod/5042/Arc-latest.json
#   ./script/run/deploy_up_oft_arc.sh check-dvns              # on-chain DVN/executor support preflight
#   ./script/run/deploy_up_oft_arc.sh simulate                # dry-run Arc-side configuration
#   ./script/run/deploy_up_oft_arc.sh configure [account]
#   ./script/run/deploy_up_oft_arc.sh simulate-rh             # dry-run RH -> Arc wiring
#   ./script/run/deploy_up_oft_arc.sh configure-rh [account]
#
# The configure/simulate modes read the deployed OFT address from
# script/output/prod/5042/Arc-latest.json (override with env var ARC_OFT if needed).
#
# configure    = Arc side only (peers, libs, ULN, options on Arc — all v2-supervaults).
# configure-rh = the RH -> Arc reverse direction (RH UpOFT owner + delegate are also
#                v2-supervaults, verified on-chain). The remaining reverse directions
#                (ETH/Base/BSC/HyperEVM = multisig, Flare = its own deployer EOA) need
#                separate calldata.
#
# Prerequisites:
#   - ARC_RPC_URL in .env (falls back to the public https://rpc.mainnet.arc.io)
#   - v2-supervaults foundry keystore account (0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
#     funded with USDC (Arc's native gas token, 18 decimals)
###################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
    echo "Usage: $0 {deploy|check-dvns|simulate|configure|simulate-rh|configure-rh} [args]" >&2
    exit 1
fi

# shellcheck disable=SC1091
source .env
RPC="${ARC_RPC_URL:-https://rpc.mainnet.arc.io}"

DELEGATE="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8" # v2-supervaults

OUTPUT_FILE="script/output/prod/5042/Arc-latest.json"

read_arc_oft() {
    if [[ -n "${ARC_OFT:-}" ]]; then
        echo "$ARC_OFT"
    elif [[ -f "$OUTPUT_FILE" ]]; then
        python3 -c "import json; print(json.load(open('$OUTPUT_FILE')).get('UpOFT',''))"
    fi
}

require_arc_oft() {
    OFT=$(read_arc_oft)
    if [[ -z "$OFT" ]]; then
        echo "ERROR: no UpOFT address in $OUTPUT_FILE — run '$0 deploy' first (or set ARC_OFT env var)" >&2
        exit 1
    fi
}

# ─── Arc LZ infra (verified on-chain + LZ metadata) ─────────────
LZ_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"
EXECUTOR="0x4208d6E27538189bB48E603D6123A94b8Abe0A0b"

# ─── Arc DVNs (sorted ascending; Superform DVN not on Arc) ──────
DVN_NETHERMIND="0x9e0e95ede70f680f74480b510ff9f45c70e3da80"
DVN_LZ="0xa2447e5b58d357c49bf74b50b14421e6a100e525"
DVN_CANARY="0xacde1f22eeab249d3ca6ba8805c8fee9f52a16e7"

CONFIRMATIONS=20
MAX_MESSAGE_SIZE=10000
EXECUTOR_CONFIG_TYPE=1
ULN_CONFIG_TYPE=2

# ─── Remote pathways: eid, name, peer OFT (verified on-chain) ───
EIDS=(30101 30184 30102 30367 30295 30416)
EID_NAMES=(Ethereum Base BSC HyperEVM Flare RH)
PEERS=(
    0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD  # Ethereum UpOFTAdapter
    0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B  # Base UpOFT
    0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B  # BSC UpOFT (same CREATE2 address as Base)
    0x642fFC3496AcA19106BAB7A42F1F221a329654fe  # HyperEVM UpOFT
    0xe030A89fd2b7f858c8aA47725679CA25D467dFD1  # Flare UpOFT
    0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E  # RH UpOFT
)

# Canonical enforced options (identical on every existing chain, verified on-chain)
SEND_OPTS="0x000301001101000000000000000000000000000493e0"
CALL_OPTS="0x000301001101000000000000000000000000000493e0010013030000000000000000000000000000000f4240"

ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
    "($CONFIRMATIONS,3,0,0,[$DVN_NETHERMIND,$DVN_LZ,$DVN_CANARY],[])")
EXEC_BYTES=$(cast abi-encode "f((uint32,address))" "($MAX_MESSAGE_SIZE,$EXECUTOR)")

lower() { echo "$1" | tr 'A-F' 'a-f'; }

# ─── RH side (reverse leg RH -> Arc; verified on-chain) ──────────
RH_OFT="0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E"
RH_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
RH_SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
RH_RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"
RH_EXECUTOR="0x4208d6E27538189bB48E603D6123A94b8Abe0A0b"
ARC_EID=30417
# RH DVNs that serve eid 30417 (sorted ascending). The RH Superform DVN (0xA45Caa85...) has
# dstConfig(30417).gas == 0 and is deliberately excluded — see DVN PARITY note above.
RH_DVN_NETHERMIND="0x0Ffe02DF012299A370D5dd69298A5826EAcaFdF8"
RH_DVN_CANARY="0x8D77D35604A9f37f488E41D1d916b2A0088F82Dd"
RH_DVN_LZ="0xd01ae6905d48315f7bE10C7330aeCF8360Ef5b12"

# check_dst_support <label> <rpc> <executor> <dst eid> <dvn...>
# Reads DVN dstConfig(eid).gas and executor dstConfig(eid).lzReceiveBaseGas on-chain.
# DVNFeeLib reverts with DVN_EidNotSupported when gas == 0, so a zero here means every
# quoteSend()/send() for that pathway would revert. Returns 1 if anything is unsupported.
check_dst_support() {
    local label=$1 rpc=$2 executor=$3 eid=$4; shift 4
    local ok=1
    for dvn in "$@"; do
        local gas
        gas=$(cast call "$dvn" 'dstConfig(uint32)(uint64,uint16,uint128)' "$eid" --rpc-url "$rpc" 2>/dev/null | sed -n 1p | awk '{print $1}')
        if [[ -z "$gas" || "$gas" == "0" ]]; then
            echo "  FAIL  $label: DVN $dvn does not serve eid $eid (dstConfig.gas=${gas:-?})"; ok=0
        else
            echo "  ok    $label: DVN $dvn serves eid $eid (gas=$gas)"
        fi
    done
    local egas
    egas=$(cast call "$executor" 'dstConfig(uint32)(uint64,uint16,uint128,uint128,uint64)' "$eid" --rpc-url "$rpc" 2>/dev/null | sed -n 1p | awk '{print $1}')
    if [[ -z "$egas" || "$egas" == "0" ]]; then
        echo "  FAIL  $label: executor $executor does not serve eid $eid (lzReceiveBaseGas=${egas:-?})"; ok=0
    else
        echo "  ok    $label: executor serves eid $eid (lzReceiveBaseGas=$egas)"
    fi
    [[ "$ok" == "1" ]]
}

# Arc-side preflight: the 3 Arc DVNs + Arc executor must serve every remote eid.
preflight_arc() {
    local all=1
    echo "── DVN/executor support preflight (Arc -> remotes) ──"
    for i in "${!EIDS[@]}"; do
        check_dst_support "Arc->${EID_NAMES[$i]}" "$RPC" "$EXECUTOR" "${EIDS[$i]}" "$DVN_NETHERMIND" "$DVN_LZ" "$DVN_CANARY" || all=0
    done
    [[ "$all" == "1" ]] || { echo "ERROR: unsupported DVN/executor destination(s) on Arc — configuring would produce a pathway that cannot quote" >&2; return 1; }
    echo ""
}

# RH-side preflight: the 3 RH DVNs + RH executor must serve eid 30417.
preflight_rh() {
    local rh_rpc=$1
    echo "── DVN/executor support preflight (RH -> Arc) ──"
    check_dst_support "RH->Arc" "$rh_rpc" "$RH_EXECUTOR" "$ARC_EID" "$RH_DVN_NETHERMIND" "$RH_DVN_CANARY" "$RH_DVN_LZ" \
        || { echo "ERROR: unsupported DVN/executor destination on RH for eid $ARC_EID" >&2; return 1; }
    echo ""
}

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
    echo "=== Deploying UpOFT on Arc via deterministic deployer (rpc: $(echo "$RPC" | sed -E "s#(https?://[^/]+).*#\1#")) ==="
    build

    # Same CREATE2 scheme as DeployUpOFT.s.sol (_getSalt / DeterministicDeployerLib):
    #   salt    = keccak256("SuperformV2" . "TEST1.0.0" . "UpOFT" . "v2.0")  [prod namespace]
    #   factory = canonical deterministic-deployment proxy
    # Arc shares endpoint + owner with RH, so the predicted address equals RH's UpOFT.
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
    echo "Next: ./script/run/deploy_up_oft_arc.sh simulate"
    echo "Then: ./script/run/deploy_up_oft_arc.sh configure"
    echo ""
    echo "Verify on the Arc explorer (Etherscan-compatible legacy API, best-effort; override with ARC_VERIFIER_URL):"
    echo "  forge verify-contract $OFT src/UP/UpOFT.sol:UpOFT --chain 5042 \\"
    echo "    --constructor-args $ARGS --verifier etherscan --verifier-url \${ARC_VERIFIER_URL:-https://arc.exploreme.pro/api} --skip-is-verified-check"
    ;;

check-dvns)
    echo "=== On-chain DVN/executor destination support (no state changes) ==="
    echo "Arc rpc: $(echo "$RPC" | sed -E "s#(https?://[^/]+).*#\1#")"
    RC=0
    preflight_arc || RC=1
    if [[ -n "${RH_RPC_URL:-}" ]]; then
        preflight_rh "$RH_RPC_URL" || RC=1
    else
        echo "RH_RPC_URL not set in .env — skipping the RH -> Arc check"
    fi
    echo "NOTE: on ETH/Base/BSC/HyperEVM only the Canary DVN serves eid $ARC_EID today (LZ Labs and"
    echo "Nethermind report dstConfig.gas == 0); those reverse legs cannot be configured with the"
    echo "3-DVN set until those DVN operators enable Arc. Re-run this check before wiring them."
    exit $RC
    ;;

simulate|configure)
    require_arc_oft
    preflight_arc
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
            skip "setConfig(send): already 3 DVNs / 20 conf"
        else
            tx "setConfig(send: executor + ULN)" "$LZ_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
                "$OFT" "$SEND_LIB" "[($eid,$EXECUTOR_CONFIG_TYPE,$EXEC_BYTES),($eid,$ULN_CONFIG_TYPE,$ULN_BYTES)]"
        fi

        # 5. receive config: ULN [delegate]
        if [[ "$(lower "$(cast call "$LZ_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$OFT" "$RECEIVE_LIB" "$eid" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")")" == "$(lower "$ULN_BYTES")" ]]; then
            skip "setConfig(receive): already 3 DVNs / 20 conf"
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
        skip "setEnforcedOptions: already set for all 6 eids"
    else
        PARAMS=""
        for eid in "${EIDS[@]}"; do
            PARAMS+="($eid,1,$SEND_OPTS),($eid,2,$CALL_OPTS),"
        done
        tx "setEnforcedOptions (6 eids x SEND/SEND_AND_CALL)" "$OFT" \
            "setEnforcedOptions((uint32,uint16,bytes)[])" "[${PARAMS%,}]"
    fi

    echo ""
    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    echo ""
    echo "REMINDER: remote sides still need wiring for eid 30417 (peer -> $OFT, pinned"
    echo "libs, 20-conf ULN, enforced options) on Ethereum, Base, BSC, HyperEVM, Flare, RH."
    ;;

simulate-rh|configure-rh)
    require_arc_oft
    ACCOUNT="${2:-v2-supervaults}"
    SIMULATE=0; [[ "$MODE" == "simulate-rh" ]] && SIMULATE=1

    if [[ -z "${RH_RPC_URL:-}" ]]; then
        echo "ERROR: RH_RPC_URL is not set in .env" >&2
        exit 1
    fi
    RPC="$RH_RPC_URL"

    preflight_rh "$RPC"

    # RH -> Arc ULN: 20 confirmations, 3-of-3 (Nethermind, Canary, LZ Labs) — the RH Superform DVN
    # does not serve eid 30417, so it must not be listed here (see DVN PARITY note in the header).
    RH_ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
        "($CONFIRMATIONS,3,0,0,[$RH_DVN_NETHERMIND,$RH_DVN_CANARY,$RH_DVN_LZ],[])")
    RH_EXEC_BYTES=$(cast abi-encode "f((uint32,address))" "($MAX_MESSAGE_SIZE,$RH_EXECUTOR)")

    [[ "$SIMULATE" == "1" ]] && echo "=== RH -> Arc SIMULATION (no state changes) ===" || echo "=== RH -> Arc CONFIGURING with account: $ACCOUNT ==="
    echo "RH UpOFT: $RH_OFT | Arc peer: $OFT"
    echo ""

    peer32="0x000000000000000000000000$(lower "${OFT#0x}")"

    # 1. setPeer [owner]
    if [[ "$(lower "$(cast call "$RH_OFT" 'peers(uint32)(bytes32)' "$ARC_EID" --rpc-url "$RPC")")" == "$peer32" ]]; then
        skip "setPeer: already $OFT"
    else
        tx "setPeer -> $OFT" "$RH_OFT" "setPeer(uint32,bytes32)" "$ARC_EID" "$peer32"
    fi

    # 2. pin send library [delegate]
    if [[ "$(lower "$(cast call "$RH_ENDPOINT" 'getSendLibrary(address,uint32)(address)' "$RH_OFT" "$ARC_EID" --rpc-url "$RPC")")" == "$(lower "$RH_SEND_LIB")" \
          && "$(cast call "$RH_ENDPOINT" 'isDefaultSendLibrary(address,uint32)(bool)' "$RH_OFT" "$ARC_EID" --rpc-url "$RPC")" == "false" ]]; then
        skip "setSendLibrary: already pinned"
    else
        tx "setSendLibrary" "$RH_ENDPOINT" "setSendLibrary(address,uint32,address)" "$RH_OFT" "$ARC_EID" "$RH_SEND_LIB"
    fi

    # 3. pin receive library [delegate]
    rl=$(cast call "$RH_ENDPOINT" 'getReceiveLibrary(address,uint32)(address,bool)' "$RH_OFT" "$ARC_EID" --rpc-url "$RPC")
    if [[ "$(lower "$(echo "$rl" | sed -n 1p)")" == "$(lower "$RH_RECEIVE_LIB")" && "$(echo "$rl" | sed -n 2p)" == "false" ]]; then
        skip "setReceiveLibrary: already pinned"
    else
        tx "setReceiveLibrary" "$RH_ENDPOINT" "setReceiveLibrary(address,uint32,address,uint256)" "$RH_OFT" "$ARC_EID" "$RH_RECEIVE_LIB" 0
    fi

    # 4. send config: executor + ULN [delegate]
    if [[ "$(lower "$(cast call "$RH_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$RH_OFT" "$RH_SEND_LIB" "$ARC_EID" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")")" == "$(lower "$RH_ULN_BYTES")" ]]; then
        skip "setConfig(send): already 3 DVNs / 20 conf"
    else
        tx "setConfig(send: executor + ULN)" "$RH_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$RH_OFT" "$RH_SEND_LIB" "[($ARC_EID,$EXECUTOR_CONFIG_TYPE,$RH_EXEC_BYTES),($ARC_EID,$ULN_CONFIG_TYPE,$RH_ULN_BYTES)]"
    fi

    # 5. receive config: ULN [delegate]
    if [[ "$(lower "$(cast call "$RH_ENDPOINT" 'getConfig(address,address,uint32,uint32)(bytes)' "$RH_OFT" "$RH_RECEIVE_LIB" "$ARC_EID" "$ULN_CONFIG_TYPE" --rpc-url "$RPC")")" == "$(lower "$RH_ULN_BYTES")" ]]; then
        skip "setConfig(receive): already 3 DVNs / 20 conf"
    else
        tx "setConfig(receive: ULN)" "$RH_ENDPOINT" "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$RH_OFT" "$RH_RECEIVE_LIB" "[($ARC_EID,$ULN_CONFIG_TYPE,$RH_ULN_BYTES)]"
    fi

    # 6. enforced options [owner]
    if [[ "$(lower "$(cast call "$RH_OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$ARC_EID" 1 --rpc-url "$RPC")")" == "$SEND_OPTS" \
          && "$(lower "$(cast call "$RH_OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$ARC_EID" 2 --rpc-url "$RPC")")" == "$CALL_OPTS" ]]; then
        skip "setEnforcedOptions: already set for eid $ARC_EID"
    else
        tx "setEnforcedOptions (SEND + SEND_AND_CALL)" "$RH_OFT" \
            "setEnforcedOptions((uint32,uint16,bytes)[])" "[($ARC_EID,1,$SEND_OPTS),($ARC_EID,2,$CALL_OPTS)]"
    fi

    echo ""
    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    echo ""
    echo "REMINDER: ETH/Base/BSC/HyperEVM (multisig) and Flare (deployer 0x0f0Db7CE...) still"
    echo "need their reverse-direction wiring for eid 30417 via separate calldata."
    ;;

*)
    echo "Usage: $0 {deploy|check-dvns|simulate|configure|simulate-rh|configure-rh} [args]" >&2
    exit 1
    ;;
esac
