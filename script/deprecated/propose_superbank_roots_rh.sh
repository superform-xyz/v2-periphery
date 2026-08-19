#!/usr/bin/env bash

###################################################################################
# ONE-OFF: SuperBank Merkle Root Proposals on Robinhood Chain (4663)
###################################################################################
# Registers the SuperBank hooks and proposes their production merkle roots on RH
# via script/ProposeSuperBankRootsRH.s.sol. Idempotent — safe to re-run; it never
# resets an in-flight 7-day timelock.
#
# DELETE THIS FILE (and the .s.sol) AFTER THE ROOTS ARE EXECUTED ON-CHAIN.
#
# Usage:
#   ./script/run/propose_superbank_roots_rh.sh simulate
#   ./script/run/propose_superbank_roots_rh.sh propose [account]
#
#   simulate: dry-run against RH with the governor EOA as sender (no broadcast)
#   propose:  broadcast with the local keystore account (default: v2-supervaults)
#
# Prerequisites:
#   - RH_RPC_URL set in .env
#   - Keystore account with GOVERNOR_ROLE on the RH SuperGovernor
#     (v2-supervaults = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
###################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

MODE="${1:-simulate}"
ACCOUNT="${2:-v2-supervaults}"
GOVERNOR_EOA="0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

# shellcheck disable=SC1091
source .env

if [[ -z "${RH_RPC_URL:-}" ]]; then
    echo "ERROR: RH_RPC_URL is not set in .env" >&2
    exit 1
fi

# FOUNDRY_TEST + --skip work around test files on this branch that are stale vs the
# bumped v2-core submodule and would otherwise fail compilation.
FORGE_ARGS=(
    script/ProposeSuperBankRootsRH.s.sol
    --rpc-url "$RH_RPC_URL"
    --skip "*RevenueDistribution*"
    -vv
)

case "$MODE" in
    simulate)
        echo "=== SIMULATION (no broadcast) ==="
        FOUNDRY_TEST=test/integration/SuperBank forge script "${FORGE_ARGS[@]}" \
            --sender "$GOVERNOR_EOA"
        ;;
    propose)
        echo "=== BROADCASTING with account: $ACCOUNT ==="
        FOUNDRY_TEST=test/integration/SuperBank forge script "${FORGE_ARGS[@]}" \
            --account "$ACCOUNT" \
            --broadcast
        echo ""
        echo "Proposals submitted. After the 7-day timelock, execute each root (permissionless),"
        echo "e.g. via the v2-toolbox 'execute_superbank_hook_merkle_root' script per hook."
        ;;
    *)
        echo "Usage: $0 {simulate|propose} [account]" >&2
        exit 1
        ;;
esac
