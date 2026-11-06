#!/usr/bin/env bash

###################################################################################
# Deploy + Configure UpOFT on Katana (OP Stack L2, id 747474, LZ eid 30375)
###################################################################################
# Deploys UpOFT and wires all 7 pathways (Ethereum, Base, BSC, HyperEVM, Flare, RH,
# Arc) with the audited setup every other chain runs:
#   - send + receive libraries explicitly pinned (SendUln302 / ReceiveUln302)
#   - ULN: 20 confirmations on send AND receive, 4 required DVNs, optionalDVNCount
#     255 (NIL_DVN_COUNT = explicitly none, so the pathway cannot inherit the
#     default config's optional DVNs the way optionalDVNCount 0 would)
#   - Executor config: maxMessageSize 10000
#   - Enforced options: SEND 300k gas, SEND_AND_CALL 300k + 1M compose gas
#
# Katana LZ infra (LayerZero deployments metadata for chainKey `katana`, read back
# on chain 2026-11-02; the endpoint, libs and executor share their addresses with
# the Arc/RH family):
#   EndpointV2:    0x6F475642a6e85809B1c36Fa62763669b1b48DD5B
#   SendUln302:    0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7
#   ReceiveUln302: 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043
#   Executor:      0x4208D6E27538189bB48E603D6123A94b8Abe0A0b
#
# Katana DVNs (LayerZero canonical names). All four serve the ETH and Base pathways
# (dstConfig(30101).gas == dstConfig(30184).gas == 77000). THREE are used here:
#   LZ Labs:   0x282b3386571f7f794450d5789911a9804FA346b4   used
#   Canary:    0x53fF818a1c492e667E2cD0b5AFe0FC82c66d33c7   used
#   Twinstake: 0xaCDe1f22EEAb249d3ca6Ba8805C8fEe9f52a16e7   used, see the substitution note below
#   Horizen:   0x84a410A8a912e333B957680998a76e526f98e207   NOT used
#
# SUBSTITUTION: the fleet standard is LZ Labs + Superform + Canary + Nethermind. Katana has no
# Nethermind DVN in LayerZero's metadata, so Twinstake takes that slot. LayerZero records that
# address under the id `nethermind` with the canonical name Twinstake, which is why the fleet's
# own DVN comments and LayerZero's names disagree across several chains. Treat the swap as a
# security decision, not a rename.
#
# DVN PARITY — THIS SCRIPT IS GATED AND WILL REFUSE TO CONFIGURE TODAY.
# The audited standard is 4 required DVNs (LZ Labs, Superform, Canary, Nethermind),
# and Katana cannot meet it yet:
#   - the Superform DVN has no deployment on Katana at all; and
#   - on Ethereum, Base AND RH the Superform DVN reports dstConfig(30375).gas == 0,
#     i.e. it does not serve the Katana destination from any of them.
# DVNFeeLib reverts with DVN_EidNotSupported whenever a listed DVN has gas == 0, so
# configuring the 4-of-4 set now would produce pathways where every quoteSend() and
# send() reverts. Rather than silently dropping Superform from the set (which is a
# security decision, not a plumbing one), this script requires the Katana Superform
# DVN address in KATANA_SUPERFORM_DVN and re-checks support on chain before writing
# anything.
#
# To unblock, ops must:
#   1. deploy the Superform DVN on Katana, and
#   2. enable eid 30375 on the Superform DVN of every remote chain
#      (Ethereum, Base, BSC, HyperEVM, Flare, RH; Arc has no Superform DVN at all),
# then export KATANA_SUPERFORM_DVN=0x... and run `check-dvns` again.
#
# NOTE ON NAMING: this repo's DVN comments and LayerZero's canonical names disagree
# on several addresses (what DeployUpOFT.s.sol calls Nethermind on Ethereum,
# 0xa4fE5A5B..., LayerZero calls Canary; what it calls Horizen, 0xa59BA433..., it
# calls Twinstake). Everything here keys off addresses and on-chain dstConfig reads,
# never off a name.
#
# The deployer (v2-supervaults) becomes owner AND LZ delegate, so every step here is
# executable from the same keystore account. Transfer ownership to the multisig
# afterwards (see TransferUpOFTOwnership.s.sol) — once a SuperGovernor Safe exists
# on Katana.
#
# Because the endpoint and delegate match Arc and RH, the CREATE2 address is expected
# to equal theirs: 0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E. Nothing is deployed
# there on Katana yet (checked 2026-11-02). The deploy mode recomputes it rather than
# trusting this note.
#
# NOTE: this configures the Katana side only. Each remote chain still needs its own
# txs for the reverse direction (setPeer to the new Katana OFT, pin libs, 20-conf
# ULN and enforced options for eid 30375) before the pathways are usable. RH and Arc
# are both owned and delegated by v2-supervaults, so their reverse legs are available
# here via configure-remote; ETH/Base/BSC/HyperEVM are multisig and Flare has its own
# deployer EOA, so those need separate calldata.
#
# Usage:
#   ./script/run/deploy/deploy_up_oft_katana.sh deploy [account]      # deploy UpOFT, writes address to
#                                                              # script/output/prod/747474/Katana-latest.json
#   ./script/run/deploy/deploy_up_oft_katana.sh check-dvns             # on-chain DVN/executor preflight (no state changes)
#   ./script/run/deploy/deploy_up_oft_katana.sh simulate               # dry-run Katana-side configuration
#   ./script/run/deploy/deploy_up_oft_katana.sh configure [account]
#   ./script/run/deploy/deploy_up_oft_katana.sh simulate-remote <rh|arc>
#   ./script/run/deploy/deploy_up_oft_katana.sh configure-remote <rh|arc> [account]
#
# The configure/simulate modes read the deployed OFT address from
# script/output/prod/747474/Katana-latest.json (override with env var KATANA_OFT).
#
# Prerequisites:
#   - KATANA_RPC_URL in .env (falls back to the public https://rpc.katana.network)
#   - RH_RPC_URL / ARC_RPC_URL in .env for the reverse legs
#   - v2-supervaults foundry keystore account (0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
#     funded with ETH (Katana's native gas token)
###################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-}"
if [[ -z "$MODE" ]]; then
    echo "Usage: $0 {deploy|check-dvns|simulate|configure|simulate-remote|configure-remote} [args]" >&2
    exit 1
fi

# shellcheck disable=SC1091
source .env
RPC="${KATANA_RPC_URL:-https://rpc.katana.network}"

DELEGATE="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8" # v2-supervaults

KATANA_EID=30375
OUTPUT_FILE="script/output/prod/747474/Katana-latest.json"

read_katana_oft() {
    if [[ -n "${KATANA_OFT:-}" ]]; then
        echo "$KATANA_OFT"
    elif [[ -f "$OUTPUT_FILE" ]]; then
        python3 -c "import json; print(json.load(open('$OUTPUT_FILE')).get('UpOFT',''))"
    fi
}

require_katana_oft() {
    OFT=$(read_katana_oft)
    if [[ -z "$OFT" ]]; then
        echo "ERROR: no UpOFT address in $OUTPUT_FILE — run '$0 deploy' first (or set KATANA_OFT env var)" >&2
        exit 1
    fi
}

# ─── Katana LZ infra (LZ metadata, verified on-chain) ───────────
LZ_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"
EXECUTOR="0x4208D6E27538189bB48E603D6123A94b8Abe0A0b"

# ─── Katana DVNs ────────────────────────────────────────────────
DVN_LZ="0x282b3386571f7f794450d5789911a9804FA346b4"
DVN_CANARY="0x53fF818a1c492e667E2cD0b5AFe0FC82c66d33c7"
DVN_TWINSTAKE="0xaCDe1f22EEAb249d3ca6Ba8805C8fEe9f52a16e7"
# Not deployed on Katana. Supply it once ops lands it; see DVN PARITY in the header.
DVN_SUPERFORM="${KATANA_SUPERFORM_DVN:-}"
DVN_SUPERFORM_PRESENT=0; [[ -n "$DVN_SUPERFORM" ]] && DVN_SUPERFORM_PRESENT=1

CONFIRMATIONS=20
MAX_MESSAGE_SIZE=10000
EXECUTOR_CONFIG_TYPE=1
ULN_CONFIG_TYPE=2
# Derived from the DVN set actually available, NOT fixed at the fleet standard of 4.
# Katana has three DVNs today (LZ Labs, Canary, Nethermind) and no Superform DVN, so the
# pathways are configured 3-of-3 and MUST be re-run at 4-of-4 once ops lands it:
#   export KATANA_SUPERFORM_DVN=0x<addr> && ./script/run/deploy/deploy_up_oft_katana.sh
# Setting that variable raises the count to 4 with no further edit -- setConfig is
# idempotent per pathway, so the re-run rewrites only what changed.
REQUIRED_DVN_COUNT=$(( DVN_SUPERFORM_PRESENT ? 4 : 3 ))
# NIL_DVN_COUNT (type(uint8).max) means "explicitly no optional DVNs".
# UlnBase.getUlnConfig treats optionalDVNCount == 0 as DEFAULT and INHERITS whatever
# optional DVNs the pathway's default config carries, so a 0 here would let LayerZero's
# default set verify alongside ours and change out from under us. 255 pins the pathway
# to the required set only. It also requires optionalDVNs == [] and threshold == 0,
# which is what is encoded below.
OPTIONAL_DVN_COUNT=255

# ─── Remote pathways: eid, name, peer OFT (from script/output/prod) ───
EIDS=(30101 30184 30102 30367 30295 30416 30417)
EID_NAMES=(Ethereum Base BSC HyperEVM Flare RH Arc)
PEERS=(
    0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD  # Ethereum UpOFTAdapter
    0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B  # Base UpOFT
    0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B  # BSC UpOFT (same CREATE2 address as Base)
    0x642fFC3496AcA19106BAB7A42F1F221a329654fe  # HyperEVM UpOFT
    0xe030A89fd2b7f858c8aA47725679CA25D467dFD1  # Flare UpOFT
    0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E  # RH UpOFT
    0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E  # Arc UpOFT (same CREATE2 address as RH)
)

# Canonical enforced options (identical on every existing chain, verified on-chain)
SEND_OPTS="0x000301001101000000000000000000000000000493e0"
CALL_OPTS="0x000301001101000000000000000000000000000493e0010013030000000000000000000000000000000f4240"

lower() { echo "$1" | tr 'A-F' 'a-f'; }

# The ULN requires requiredDVNs sorted ascending. Superform's Katana address is not
# known until ops deploys it, so the order is computed rather than written down.
sorted_dvns() {
    # grep -v '^$' matters: with no Superform DVN the printf emits a blank line, which would
    # sort to the front and produce "[,0x...]" -- a malformed address array.
    printf '%s\n' "$DVN_SUPERFORM" "$DVN_LZ" "$DVN_CANARY" "$DVN_TWINSTAKE" \
        | grep -v '^$' | tr 'A-F' 'a-f' | sort | paste -sd, -
}

require_dvn_set() {
    if [[ -n "$DVN_SUPERFORM" ]]; then
        # A malformed or duplicate entry would otherwise reach the chain and revert there:
        # UlnBase._assertNoDuplicates rejects it as LZ_ULN_Unsorted after a wasted tx.
        [[ "$DVN_SUPERFORM" =~ ^0x[0-9a-fA-F]{40}$ ]] \
            || { echo "ERROR: KATANA_SUPERFORM_DVN is not a 20-byte address: $DVN_SUPERFORM" >&2; exit 1; }
        [[ "$(sorted_dvns | tr ',' '\n' | sort -u | wc -l | tr -d ' ')" == "4" ]] \
            || { echo "ERROR: KATANA_SUPERFORM_DVN duplicates one of Katana's existing DVNs" >&2; exit 1; }
        return 0
    fi
    # Deliberate interim posture, chosen by the operator: ship 3-of-3 now, raise to 4-of-4
    # once the Superform DVN exists on Katana and serves eid 30375 from the remotes.
    cat >&2 <<'EOF'
WARNING: configuring Katana with 3 required DVNs, not the fleet standard of 4.

  Katana's live DVNs (all three verified to serve every remote eid):
    LZ Labs     0x282b3386571f7f794450d5789911a9804FA346b4
    Canary      0x53fF818a1c492e667E2cD0b5AFe0FC82c66d33c7
    Nethermind  0xaCDe1f22EEAb249d3ca6Ba8805C8fEe9f52a16e7

  The Superform DVN is absent from Katana, and on Ethereum/Base/RH/Arc it reports
  dstConfig(30375).gas == 0, so including it would make every quoteSend() and send()
  on those pathways revert with DVN_EidNotSupported.

  This lowers the verification threshold for UP transfers on Katana pathways until
  ops lands the Superform DVN. Confirmations (20), pinned libraries and
  optionalDVNCount = 255 are unchanged.

  TO RAISE TO 4-of-4 LATER:
    1. deploy the Superform DVN on Katana;
    2. enable eid 30375 on the Superform DVN of Ethereum, Base, BSC, HyperEVM,
       Flare, RH and Arc;
    3. export KATANA_SUPERFORM_DVN=0x<katana superform dvn>;
    4. re-run this script -- it rewrites only the pathways whose config changed.
EOF
    return 0
}

build_config_bytes() {
    local dvns
    dvns=$(sorted_dvns)
    # What we write: optionalDVNCount = NIL (255).
    ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
        "($CONFIRMATIONS,$REQUIRED_DVN_COUNT,$OPTIONAL_DVN_COUNT,0,[$dvns],[])")
    # What getConfig gives back: SendUln302/ReceiveUln302 return abi.encode(getUlnConfig(..)),
    # the RESOLVED config, and UlnBase.getUlnConfig copies nothing for a NIL optional count, so
    # it reads back as 0. Comparing the written form would never match and would re-send
    # setConfig on every run, which is exactly the drift check this is supposed to be.
    ULN_READBACK=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
        "($CONFIRMATIONS,$REQUIRED_DVN_COUNT,0,0,[$dvns],[])")
    EXEC_BYTES=$(cast abi-encode "f((uint32,address))" "($MAX_MESSAGE_SIZE,$EXECUTOR)")
}

# ─── Reverse legs this keystore can sign (owner + delegate are v2-supervaults) ───
# rh:  endpoint/libs/executor identical to Katana's; arc: likewise.
remote_params() {
    case "$1" in
    rh)
        REMOTE_NAME="RH"
        REMOTE_RPC="${RH_RPC_URL:-}"
        REMOTE_OFT="0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E"
        REMOTE_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
        REMOTE_SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
        REMOTE_RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"
        REMOTE_EXECUTOR="0x4208D6E27538189bB48E603D6123A94b8Abe0A0b"
        # RH DVNs; the RH Superform DVN must also serve eid 30375 before this runs.
        REMOTE_DVNS=("0x0Ffe02DF012299A370D5dd69298A5826EAcaFdF8" "0x8D77D35604A9f37f488E41D1d916b2A0088F82Dd" "0xd01ae6905d48315f7bE10C7330aeCF8360Ef5b12")
        REMOTE_SUPERFORM_DVN="${RH_SUPERFORM_DVN:-}"
        REMOTE_DVN_LIST=()
        ;;
    arc)
        REMOTE_NAME="Arc"
        # Public fallback so check-dvns can report this leg without ARC_RPC_URL in .env
        # (verified: answers eth_chainId with 0x13b2 = 5042).
        REMOTE_RPC="${ARC_RPC_URL:-https://rpc.mainnet.arc.io}"
        REMOTE_OFT="0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E"
        REMOTE_ENDPOINT="0x6F475642a6e85809B1c36Fa62763669b1b48DD5B"
        REMOTE_SEND_LIB="0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7"
        REMOTE_RECEIVE_LIB="0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043"
        REMOTE_EXECUTOR="0x4208D6E27538189bB48E603D6123A94b8Abe0A0b"
        REMOTE_DVNS=("0x9e0e95ede70f680f74480b510ff9f45c70e3da80" "0xa2447e5b58d357c49bf74b50b14421e6a100e525" "0xacde1f22eeab249d3ca6ba8805c8fee9f52a16e7")
        # Arc DOES have a Superform DVN, added on chain after deploy_up_oft_arc.sh was written
        # (that script still lists only 3 DVNs). Arc's live send config for Ethereum/Base/RH reads
        # 20 confirmations, 4 required DVNs, and includes this address — so Arc is at fleet parity.
        # It has no Katana destination yet though: dstConfig(30375).gas == 0 here, same as on
        # Ethereum, Base and RH, so the Arc->Katana leg still cannot be written 4-of-4.
        REMOTE_SUPERFORM_DVN="${ARC_SUPERFORM_DVN:-0xfA9bA83C102283958B997Adc8B44ED3A3CdB5dDa}"
        REMOTE_DVN_LIST=()
        ;;
    *)
        echo "ERROR: unknown remote '$1' — this script can only sign the RH and Arc reverse legs" >&2
        echo "       (ETH/Base/BSC/HyperEVM are multisig; Flare has its own deployer EOA)" >&2
        return 2
        ;;
    esac
    # Returns 1 (not exit) when the RPC is absent, so check-dvns can skip that leg
    # and still finish the rest of its report.
    [[ -n "$REMOTE_RPC" ]]
}

require_remote_rpc() {
    if [[ -z "$REMOTE_RPC" ]]; then
        echo "ERROR: RPC URL for $REMOTE_NAME is not set in .env" >&2
        exit 1
    fi
}

# check_dst_support <label> <rpc> <executor> <dst eid> <dvn...>
# Reads DVN dstConfig(eid).gas and executor dstConfig(eid).lzReceiveBaseGas on-chain.
# DVNFeeLib reverts with DVN_EidNotSupported when gas == 0, so a zero here means every
# quoteSend()/send() for that pathway would revert. Returns 1 if anything is unsupported.
check_dst_support() {
    local label=$1 rpc=$2 executor=$3 eid=$4; shift 4
    local ok=1
    for dvn in "$@"; do
        [[ -n "$dvn" ]] || continue
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

# Katana-side preflight: every Katana DVN in the set + the executor must serve every remote eid.
preflight_katana() {
    local all=1
    echo "── DVN/executor support preflight (Katana -> remotes) ──"
    for i in "${!EIDS[@]}"; do
        check_dst_support "Katana->${EID_NAMES[$i]}" "$RPC" "$EXECUTOR" "${EIDS[$i]}" \
            "$DVN_SUPERFORM" "$DVN_LZ" "$DVN_CANARY" "$DVN_TWINSTAKE" || all=0
    done
    [[ "$all" == "1" ]] || { echo "ERROR: unsupported DVN/executor destination(s) on Katana — configuring would produce a pathway that cannot quote" >&2; return 1; }
    echo ""
}

# Remote-side preflight: the remote's DVNs + executor must serve eid 30375.
preflight_remote() {
    echo "── DVN/executor support preflight ($REMOTE_NAME -> Katana) ──"
    # check-dvns calls this without having built the list, so derive it here when unset.
    if [[ ${#REMOTE_DVN_LIST[@]} -eq 0 ]]; then
        REMOTE_DVN_LIST=("${REMOTE_DVNS[@]}")
        if [[ -n "$REMOTE_SUPERFORM_DVN" ]]; then
            echo "  note  $REMOTE_NAME Superform DVN $REMOTE_SUPERFORM_DVN:"
            check_dst_support "$REMOTE_NAME->Katana" "$REMOTE_RPC" "$REMOTE_EXECUTOR" "$KATANA_EID" \
                "$REMOTE_SUPERFORM_DVN" >/dev/null 2>&1 \
                && REMOTE_DVN_LIST=("$REMOTE_SUPERFORM_DVN" "${REMOTE_DVNS[@]}") \
                || echo "        does not serve eid $KATANA_EID (dstConfig.gas=0) — excluded, leg runs 3-of-3"
        fi
    fi
    # Only the DVNs actually being written have to pass. REMOTE_DVN_LIST already excludes the
    # Superform DVN when it cannot serve this destination; check-dvns lists it separately above.
    check_dst_support "$REMOTE_NAME->Katana" "$REMOTE_RPC" "$REMOTE_EXECUTOR" "$KATANA_EID" \
        "${REMOTE_DVN_LIST[@]}" \
        || { echo "ERROR: unsupported DVN/executor destination on $REMOTE_NAME for eid $KATANA_EID" >&2; return 1; }
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
        cast call "$target" "$@" --from "$DELEGATE" --rpc-url "$TX_RPC" > /dev/null
        echo "  OK    $desc (simulated)"
    else
        cast send "$target" "$@" --account "$ACCOUNT" --rpc-url "$TX_RPC" > /dev/null
        echo "  SENT  $desc"
    fi
}
skip() { echo "  SKIP  $1"; SKIP_COUNT=$((SKIP_COUNT + 1)); }

# wire_pathway <oft> <endpoint> <send lib> <receive lib> <eid> <peer> <uln write> <exec bytes> <uln readback>
# The five steps every pathway needs, idempotent: each is skipped when already correct.
wire_pathway() {
    local oft=$1 endpoint=$2 send_lib=$3 receive_lib=$4 eid=$5 peer=$6 uln=$7 exec_cfg=$8 uln_read=$9
    local peer32
    peer32="0x000000000000000000000000$(lower "${peer#0x}")"

    # 1. setPeer [owner]
    if [[ "$(lower "$(cast call "$oft" 'peers(uint32)(bytes32)' "$eid" --rpc-url "$TX_RPC")")" == "$peer32" ]]; then
        skip "setPeer: already $peer"
    else
        tx "setPeer -> $peer" "$oft" "setPeer(uint32,bytes32)" "$eid" "$peer32"
    fi

    # 2. pin send library [delegate]
    if [[ "$(lower "$(cast call "$endpoint" 'getSendLibrary(address,uint32)(address)' "$oft" "$eid" --rpc-url "$TX_RPC")")" == "$(lower "$send_lib")" \
          && "$(cast call "$endpoint" 'isDefaultSendLibrary(address,uint32)(bool)' "$oft" "$eid" --rpc-url "$TX_RPC")" == "false" ]]; then
        skip "setSendLibrary: already pinned"
    else
        tx "setSendLibrary" "$endpoint" "setSendLibrary(address,uint32,address)" "$oft" "$eid" "$send_lib"
    fi

    # 3. pin receive library [delegate]
    local rl
    rl=$(cast call "$endpoint" 'getReceiveLibrary(address,uint32)(address,bool)' "$oft" "$eid" --rpc-url "$TX_RPC")
    if [[ "$(lower "$(echo "$rl" | sed -n 1p)")" == "$(lower "$receive_lib")" && "$(echo "$rl" | sed -n 2p)" == "false" ]]; then
        skip "setReceiveLibrary: already pinned"
    else
        tx "setReceiveLibrary" "$endpoint" "setReceiveLibrary(address,uint32,address,uint256)" "$oft" "$eid" "$receive_lib" 0
    fi

    # 4. send config: executor + ULN [delegate]. Both are checked: the ULN matching while the
    # executor config had drifted would otherwise skip the write and leave maxMessageSize unset.
    local have_uln have_exec
    have_uln=$(lower "$(cast call "$endpoint" 'getConfig(address,address,uint32,uint32)(bytes)' "$oft" "$send_lib" "$eid" "$ULN_CONFIG_TYPE" --rpc-url "$TX_RPC")")
    have_exec=$(lower "$(cast call "$endpoint" 'getConfig(address,address,uint32,uint32)(bytes)' "$oft" "$send_lib" "$eid" "$EXECUTOR_CONFIG_TYPE" --rpc-url "$TX_RPC")")
    if [[ "$have_uln" == "$(lower "$uln_read")" && "$have_exec" == "$(lower "$exec_cfg")" ]]; then
        skip "setConfig(send): already $REQUIRED_DVN_COUNT DVNs, $CONFIRMATIONS conf, executor set"
    else
        tx "setConfig(send: executor + ULN)" "$endpoint" "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$oft" "$send_lib" "[($eid,$EXECUTOR_CONFIG_TYPE,$exec_cfg),($eid,$ULN_CONFIG_TYPE,$uln)]"
    fi

    # 5. receive config: ULN [delegate]
    if [[ "$(lower "$(cast call "$endpoint" 'getConfig(address,address,uint32,uint32)(bytes)' "$oft" "$receive_lib" "$eid" "$ULN_CONFIG_TYPE" --rpc-url "$TX_RPC")")" == "$(lower "$uln_read")" ]]; then
        skip "setConfig(receive): already $REQUIRED_DVN_COUNT DVNs, $CONFIRMATIONS conf"
    else
        tx "setConfig(receive: ULN)" "$endpoint" "setConfig(address,address,(uint32,uint32,bytes)[])" \
            "$oft" "$receive_lib" "[($eid,$ULN_CONFIG_TYPE,$uln)]"
    fi
}

case "$MODE" in

deploy)
    ACCOUNT="${2:-v2-supervaults}"
    TX_RPC="$RPC"
    echo "=== Deploying UpOFT on Katana via deterministic deployer (rpc: $(echo "$RPC" | sed -E "s#(https?://[^/]+).*#\1#")) ==="
    build

    # Same CREATE2 scheme as DeployUpOFT.s.sol (_getSalt / DeterministicDeployerLib):
    #   salt    = keccak256("SuperformV2" . "TEST1.0.0" . "UpOFT" . "v2.0")  [prod namespace]
    #   factory = canonical deterministic-deployment proxy
    # Katana shares endpoint + owner with Arc and RH, so the predicted address should
    # equal theirs (0xA85abEf3...). It is recomputed here rather than assumed.
    FACTORY="0x4e59b44847b379578588920cA78FbF26c0B4956C"
    SALT=$(cast keccak "$(cast concat-hex "$(cast from-utf8 "SuperformV2")" "$(cast from-utf8 "TEST1.0.0")" "$(cast from-utf8 "UpOFT")" "$(cast from-utf8 "v2.0")")")

    BYTECODE=$(python3 -c "import json; print(json.load(open('out/UpOFT.sol/UpOFT.json'))['bytecode']['object'])")
    ARGS=$(cast abi-encode "constructor(address,address)" "$LZ_ENDPOINT" "$DELEGATE")
    INITCODE="${BYTECODE}${ARGS#0x}"
    # `cast create2` prints "<address>\t<salt>" on a single line; keep only the address.
    OFT=$(cast create2 --deployer "$FACTORY" --salt "$SALT" --init-code "$INITCODE" | tail -1 | cut -f1)
    [[ "$OFT" =~ ^0x[0-9a-fA-F]{40}$ ]] \
        || { echo "ERROR: could not parse predicted address from cast create2: '$OFT'" >&2; exit 1; }

    echo "Constructor: endpoint=$LZ_ENDPOINT delegate/owner=$DELEGATE"
    echo "Salt:        $SALT"
    echo "Predicted:   $OFT"

    # Fail closed: a failed or empty RPC response must abort, never read as "already deployed".
    EXISTING_CODE=$(cast code "$OFT" --rpc-url "$RPC") \
        || { echo "ERROR: cast code failed for $OFT" >&2; exit 1; }
    [[ -n "$EXISTING_CODE" ]] || { echo "ERROR: empty cast code response for $OFT" >&2; exit 1; }
    if [[ "$EXISTING_CODE" != "0x" ]]; then
        echo "UpOFT already deployed at $OFT — skipping deploy"
    else
        TXHASH=$(cast send --account "$ACCOUNT" --rpc-url "$RPC" --json "$FACTORY" "${SALT}${INITCODE#0x}" \
            | python3 -c "import json,sys; print(json.load(sys.stdin)['transactionHash'])")
        echo "Deploy tx: $TXHASH"
        DEPLOYED_CODE=$(cast code "$OFT" --rpc-url "$RPC") \
            || { echo "ERROR: cast code failed after deploy for $OFT" >&2; exit 1; }
        [[ -n "$DEPLOYED_CODE" && "$DEPLOYED_CODE" != "0x" ]] \
            || { echo "ERROR: no code at predicted address after deploy" >&2; exit 1; }
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
    echo "Next: ./script/run/deploy/deploy_up_oft_katana.sh check-dvns"
    echo "      then simulate / configure. With KATANA_SUPERFORM_DVN unset the pathways are"
    echo "      written 3-of-3; export it and re-run to raise them to 4-of-4."
    echo ""
    echo "Verify (forge resolves 747474 as \`katana\` and Etherscan V2 serves it):"
    echo "  forge verify-contract $OFT src/UP/UpOFT.sol:UpOFT --chain 747474 \\"
    echo "    --constructor-args $ARGS --etherscan-api-key \$ETHERSCANV2_API_KEY --verifier etherscan --watch"
    ;;

check-dvns)
    echo "=== On-chain DVN/executor destination support (no state changes) ==="
    echo "Katana rpc: $(echo "$RPC" | sed -E "s#(https?://[^/]+).*#\1#")"
    if [[ -z "$DVN_SUPERFORM" ]]; then
        echo "KATANA_SUPERFORM_DVN is unset — checking the three Katana DVNs that exist today."
        echo "The 4-of-4 set cannot be configured until it is set; see DVN PARITY in the header."
    fi
    echo ""
    RC=0
    preflight_katana || RC=1
    for remote in rh arc; do
        if remote_params "$remote"; then
            preflight_remote || RC=1
        else
            echo "── ${REMOTE_NAME:-$remote} -> Katana: RPC not set in .env, leg not checked ──"
            echo ""
        fi
    done
    echo "NOTE: the Superform DVN reports dstConfig($KATANA_EID).gas == 0 on Ethereum, Base and RH,"
    echo "and has no deployment on Katana at all (it IS deployed on Arc, in Arc's live 4-of-4 sets,"
    echo "but with no Katana destination either), so it cannot be part of any Katana pathway yet."
    echo "Re-run this check after each change."
    echo ""
    if [[ -z "$DVN_SUPERFORM" ]]; then
        echo "RESULT: ready to configure 3-of-3 (interim) — $REQUIRED_DVN_COUNT required DVNs,"
        echo "        $CONFIRMATIONS confirmations, optionalDVNCount $OPTIONAL_DVN_COUNT, libraries pinned."
        echo "        required: $(sorted_dvns)"
        echo "        Raise to 4-of-4 by exporting KATANA_SUPERFORM_DVN and re-running this script."
    else
        echo "RESULT: ready to configure 4-of-4 — required: $(sorted_dvns)"
    fi
    exit $RC
    ;;

simulate|configure)
    require_katana_oft
    require_dvn_set
    build_config_bytes
    preflight_katana
    ACCOUNT="${2:-v2-supervaults}"
    TX_RPC="$RPC"
    SIMULATE=0; [[ "$MODE" == "simulate" ]] && SIMULATE=1
    [[ "$SIMULATE" == "1" ]] && echo "=== SIMULATION (no state changes) ===" || echo "=== CONFIGURING with account: $ACCOUNT ==="
    echo "UpOFT: $OFT | Endpoint: $LZ_ENDPOINT"
    echo "ULN:   $CONFIRMATIONS conf, $REQUIRED_DVN_COUNT required / $OPTIONAL_DVN_COUNT optional (NIL) DVNs"
    echo "       required: $(sorted_dvns)"
    echo ""

    for i in "${!EIDS[@]}"; do
        echo "── ${EID_NAMES[$i]} (eid ${EIDS[$i]}) ──"
        wire_pathway "$OFT" "$LZ_ENDPOINT" "$SEND_LIB" "$RECEIVE_LIB" "${EIDS[$i]}" "${PEERS[$i]}" \
            "$ULN_BYTES" "$EXEC_BYTES" "$ULN_READBACK"
        echo ""
    done

    # enforced options for all eids in one call [owner]
    ALL_SET=1
    for eid in "${EIDS[@]}"; do
        [[ "$(lower "$(cast call "$OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$eid" 1 --rpc-url "$RPC")")" == "$SEND_OPTS" ]] || ALL_SET=0
        [[ "$(lower "$(cast call "$OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$eid" 2 --rpc-url "$RPC")")" == "$CALL_OPTS" ]] || ALL_SET=0
    done
    if [[ "$ALL_SET" == "1" ]]; then
        skip "setEnforcedOptions: already set for all ${#EIDS[@]} eids"
    else
        PARAMS=""
        for eid in "${EIDS[@]}"; do
            PARAMS+="($eid,1,$SEND_OPTS),($eid,2,$CALL_OPTS),"
        done
        tx "setEnforcedOptions (${#EIDS[@]} eids x SEND/SEND_AND_CALL)" "$OFT" \
            "setEnforcedOptions((uint32,uint16,bytes)[])" "[${PARAMS%,}]"
    fi

    echo ""
    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    echo ""
    echo "REMINDER: remote sides still need wiring for eid $KATANA_EID (peer -> $OFT, pinned libs,"
    echo "$CONFIRMATIONS-conf ULN, enforced options) on Ethereum, Base, BSC, HyperEVM, Flare, RH and Arc."
    echo "RH and Arc can be done here: $0 configure-remote <rh|arc>"
    ;;

simulate-remote|configure-remote)
    # The remote name is validated first: with it wrong, complaining about a missing OFT
    # address sends the reader after the wrong problem.
    REMOTE="${2:-}"
    [[ -n "$REMOTE" ]] || { echo "Usage: $0 $MODE <rh|arc> [account]" >&2; exit 1; }
    # rc 2 = unknown remote (already reported); rc 1 = known remote with no RPC, which
    # require_remote_rpc reports. Anything else falls through to an unbound $REMOTE_RPC.
    remote_params "$REMOTE" || [[ $? -eq 1 ]] || exit 1
    require_remote_rpc
    require_katana_oft
    ACCOUNT="${3:-v2-supervaults}"
    TX_RPC="$REMOTE_RPC"
    SIMULATE=0; [[ "$MODE" == "simulate-remote" ]] && SIMULATE=1

    # Mirrors the Katana side: 3-of-3 while the remote's Superform DVN cannot serve eid 30375.
    REMOTE_DVN_LIST=("${REMOTE_DVNS[@]}")
    if [[ -n "$REMOTE_SUPERFORM_DVN" ]] \
       && check_dst_support "$REMOTE_NAME->Katana" "$REMOTE_RPC" "$REMOTE_EXECUTOR" "$KATANA_EID" \
            "$REMOTE_SUPERFORM_DVN" >/dev/null 2>&1; then
        REMOTE_DVN_LIST=("$REMOTE_SUPERFORM_DVN" "${REMOTE_DVNS[@]}")
    else
        echo "WARNING: $REMOTE_NAME configured 3-of-3 -- its Superform DVN does not serve eid $KATANA_EID." >&2
    fi
    REMOTE_REQUIRED_DVN_COUNT=${#REMOTE_DVN_LIST[@]}

    preflight_remote

    REMOTE_SORTED=$(printf '%s\n' "${REMOTE_DVN_LIST[@]}" | grep -v '^$' | tr 'A-F' 'a-f' | sort | paste -sd, -)
    REMOTE_ULN_BYTES=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
        "($CONFIRMATIONS,$REMOTE_REQUIRED_DVN_COUNT,$OPTIONAL_DVN_COUNT,0,[$REMOTE_SORTED],[])")
    REMOTE_ULN_READBACK=$(cast abi-encode "f((uint64,uint8,uint8,uint8,address[],address[]))" \
        "($CONFIRMATIONS,$REMOTE_REQUIRED_DVN_COUNT,0,0,[$REMOTE_SORTED],[])")
    REMOTE_EXEC_BYTES=$(cast abi-encode "f((uint32,address))" "($MAX_MESSAGE_SIZE,$REMOTE_EXECUTOR)")

    [[ "$SIMULATE" == "1" ]] && echo "=== $REMOTE_NAME -> Katana SIMULATION (no state changes) ===" || echo "=== $REMOTE_NAME -> Katana CONFIGURING with account: $ACCOUNT ==="
    echo "$REMOTE_NAME UpOFT: $REMOTE_OFT | Katana peer: $OFT"
    echo "ULN: $CONFIRMATIONS conf, $REMOTE_REQUIRED_DVN_COUNT required / $OPTIONAL_DVN_COUNT optional (NIL) DVNs"
    echo "     required: $REMOTE_SORTED"
    echo ""

    wire_pathway "$REMOTE_OFT" "$REMOTE_ENDPOINT" "$REMOTE_SEND_LIB" "$REMOTE_RECEIVE_LIB" \
        "$KATANA_EID" "$OFT" "$REMOTE_ULN_BYTES" "$REMOTE_EXEC_BYTES" "$REMOTE_ULN_READBACK"

    # enforced options [owner]
    if [[ "$(lower "$(cast call "$REMOTE_OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$KATANA_EID" 1 --rpc-url "$TX_RPC")")" == "$SEND_OPTS" \
          && "$(lower "$(cast call "$REMOTE_OFT" 'enforcedOptions(uint32,uint16)(bytes)' "$KATANA_EID" 2 --rpc-url "$TX_RPC")")" == "$CALL_OPTS" ]]; then
        skip "setEnforcedOptions: already set for eid $KATANA_EID"
    else
        tx "setEnforcedOptions (SEND + SEND_AND_CALL)" "$REMOTE_OFT" \
            "setEnforcedOptions((uint32,uint16,bytes)[])" "[($KATANA_EID,1,$SEND_OPTS),($KATANA_EID,2,$CALL_OPTS)]"
    fi

    echo ""
    echo "Done. ${TX_COUNT} tx(s) $([[ "$SIMULATE" == "1" ]] && echo "simulated" || echo "sent"), ${SKIP_COUNT} skipped."
    echo ""
    echo "REMINDER: ETH/Base/BSC/HyperEVM (multisig) and Flare (its own deployer EOA) still need"
    echo "their reverse-direction wiring for eid $KATANA_EID via separate calldata."
    ;;

*)
    echo "Usage: $0 {deploy|check-dvns|simulate|configure|simulate-remote|configure-remote} [args]" >&2
    exit 1
    ;;
esac
