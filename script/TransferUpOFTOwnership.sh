#!/bin/bash
set -euo pipefail

# Transfer UpOFT delegate and ownership on HyperEVM and Flare
# Order: setDelegate FIRST, then transferOwnership (both are onlyOwner)
#
# Usage:
#   bash script/TransferUpOFTOwnership.sh                              # simulate (dry run)
#   bash script/TransferUpOFTOwnership.sh --execute --account deployer # real transactions

source .env

MODE="simulate"
ACCOUNT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute) MODE="execute"; shift ;;
    --account) ACCOUNT="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

if [ "$MODE" = "execute" ] && [ -z "$ACCOUNT" ]; then
  echo "ERROR: --execute requires --account <name>"
  exit 1
fi

HYPEREVM_NEW_OWNER="0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e"
FLARE_NEW_OWNER="0x0f0Db7CEDD49587D78d67175Ff59Ed7069A35874"

HYPEREVM_OFT="0x642fFC3496AcA19106BAB7A42F1F221a329654fe"
FLARE_OFT="0xe030A89fd2b7f858c8aA47725679CA25D467dFD1"

SIMULATE_FLAGS="--from 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8"

if [ "$MODE" = "simulate" ]; then
  echo "=== SIMULATE MODE (dry run) ==="
else
  echo "=== EXECUTE MODE (real transactions, account: $ACCOUNT) ==="
fi

echo "HyperEVM new delegate & owner: $HYPEREVM_NEW_OWNER"
echo "Flare    new delegate & owner: $FLARE_NEW_OWNER"
echo ""

# --- HyperEVM (chainId 999) ---
echo "=== HyperEVM (999) ==="

echo "[1/4] Setting delegate on HyperEVM..."
cast call "$HYPEREVM_OFT" "setDelegate(address)" "$HYPEREVM_NEW_OWNER" \
  --rpc-url "$HYPEREVM_RPC_URL" $SIMULATE_FLAGS
if [ "$MODE" = "execute" ]; then
  cast send "$HYPEREVM_OFT" "setDelegate(address)" "$HYPEREVM_NEW_OWNER" \
    --rpc-url "$HYPEREVM_RPC_URL" --account "$ACCOUNT"
fi

echo "[2/4] Transferring ownership on HyperEVM..."
cast call "$HYPEREVM_OFT" "transferOwnership(address)" "$HYPEREVM_NEW_OWNER" \
  --rpc-url "$HYPEREVM_RPC_URL" $SIMULATE_FLAGS
if [ "$MODE" = "execute" ]; then
  cast send "$HYPEREVM_OFT" "transferOwnership(address)" "$HYPEREVM_NEW_OWNER" \
    --rpc-url "$HYPEREVM_RPC_URL" --account "$ACCOUNT"
fi

# --- Flare (chainId 14) ---
echo ""
echo "=== Flare (14) ==="

echo "[3/4] Setting delegate on Flare..."
cast call "$FLARE_OFT" "setDelegate(address)" "$FLARE_NEW_OWNER" \
  --rpc-url "$FLARE_RPC_URL" $SIMULATE_FLAGS
if [ "$MODE" = "execute" ]; then
  cast send "$FLARE_OFT" "setDelegate(address)" "$FLARE_NEW_OWNER" \
    --rpc-url "$FLARE_RPC_URL" --account "$ACCOUNT"
fi

echo "[4/4] Transferring ownership on Flare..."
cast call "$FLARE_OFT" "transferOwnership(address)" "$FLARE_NEW_OWNER" \
  --rpc-url "$FLARE_RPC_URL" $SIMULATE_FLAGS
if [ "$MODE" = "execute" ]; then
  cast send "$FLARE_OFT" "transferOwnership(address)" "$FLARE_NEW_OWNER" \
    --rpc-url "$FLARE_RPC_URL" --account "$ACCOUNT"
fi

# --- Verification ---
echo ""
echo "=== Verifying ==="

HYPEREVM_OWNER=$(cast call "$HYPEREVM_OFT" "owner()(address)" --rpc-url "$HYPEREVM_RPC_URL")
FLARE_OWNER=$(cast call "$FLARE_OFT" "owner()(address)" --rpc-url "$FLARE_RPC_URL")

HYPEREVM_LZ_ENDPOINT="0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9"
FLARE_LZ_ENDPOINT="0x1a44076050125825900e736c501f859c50fE728c"

HYPEREVM_DELEGATE=$(cast call "$HYPEREVM_LZ_ENDPOINT" "delegates(address)(address)" "$HYPEREVM_OFT" --rpc-url "$HYPEREVM_RPC_URL")
FLARE_DELEGATE=$(cast call "$FLARE_LZ_ENDPOINT" "delegates(address)(address)" "$FLARE_OFT" --rpc-url "$FLARE_RPC_URL")

echo "HyperEVM - owner: $HYPEREVM_OWNER | delegate: $HYPEREVM_DELEGATE (expected: $HYPEREVM_NEW_OWNER)"
echo "Flare    - owner: $FLARE_OWNER | delegate: $FLARE_DELEGATE (expected: $FLARE_NEW_OWNER)"
echo ""

if [ "$HYPEREVM_OWNER" = "$HYPEREVM_NEW_OWNER" ] && [ "$HYPEREVM_DELEGATE" = "$HYPEREVM_NEW_OWNER" ] && \
   [ "$FLARE_OWNER" = "$FLARE_NEW_OWNER" ] && [ "$FLARE_DELEGATE" = "$FLARE_NEW_OWNER" ]; then
  echo "SUCCESS: All transfers verified!"
else
  echo "WARNING: Some values don't match expected. Check above."
fi
