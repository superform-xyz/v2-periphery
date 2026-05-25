#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
setup "$@"
load_rpc "FLARE_RPC_URL" "FLARE_MAINNET" "Flare"
echo -e "${CYAN}Send 1 UP: Flare -> Base${NC}"
run_forge "script/send-up/SendUpFromFlare.s.sol:SendUpFlareToBase" "$FLARE_MAINNET" 14
