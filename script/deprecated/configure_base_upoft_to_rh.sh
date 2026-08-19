#!/usr/bin/env bash

###################################################################################
# ONE-OFF: Base UpOFT -> RH Pathway — Delegate Transactions (TX 2-5)
###################################################################################
# Executes the delegate-permissioned LZ endpoint transactions on Base for the
# UpOFT -> RH pathway (setSendLibrary, setReceiveLibrary, send/receive setConfig)
# via script/ConfigureBaseUpOFTPathwayToRH.s.sol. Idempotent — already-applied
# steps are skipped, and each built calldata is asserted against the reviewed
# calldata from script/output/rh-pathway-calldata/base-to-rh.md.
#
# The two owner-permissioned transactions (setPeer, setEnforcedOptions) stay in
# base-to-rh.md for the multisig.
#
# DELETE THIS FILE (and the .s.sol) AFTER EXECUTION.
#
# Usage:
#   ./script/run/configure_base_upoft_to_rh.sh simulate
#   ./script/run/configure_base_upoft_to_rh.sh execute [account]
#
#   simulate: dry-run against Base with the delegate EOA as sender (no broadcast)
#   execute:  broadcast with the local keystore account (default: v2-supervaults)
#
# Prerequisites:
#   - BASE_RPC_URL set in .env
#   - Keystore account that is the UpOFT's registered LZ delegate on Base
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

if [[ -z "${BASE_RPC_URL:-}" ]]; then
    echo "ERROR: BASE_RPC_URL is not set in .env" >&2
    exit 1
fi

# FOUNDRY_TEST + --skip work around test files on this branch that are stale vs the
# bumped v2-core submodule and would otherwise fail compilation.
FORGE_ARGS=(
    script/ConfigureBaseUpOFTPathwayToRH.s.sol
    --rpc-url "$BASE_RPC_URL"
    --skip "*RevenueDistribution*"
    -vv
)

case "$MODE" in
    simulate)
        echo "=== SIMULATION (no broadcast) ==="
        FOUNDRY_TEST=test/integration/SuperBank forge script "${FORGE_ARGS[@]}" \
            --sender "$DELEGATE_EOA"
        ;;
    execute)
        echo "=== BROADCASTING with account: $ACCOUNT ==="
        FOUNDRY_TEST=test/integration/SuperBank forge script "${FORGE_ARGS[@]}" \
            --account "$ACCOUNT" \
            --broadcast
        echo ""
        echo "Done. Remaining for the multisig (see script/output/rh-pathway-calldata/base-to-rh.md):"
        echo "  setPeer + setEnforcedOptions on the UpOFT"
        ;;
    *)
        echo "Usage: $0 {simulate|execute} [account]" >&2
        exit 1
        ;;
esac
