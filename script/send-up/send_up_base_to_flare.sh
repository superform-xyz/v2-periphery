#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
setup "$@"
load_rpc "BASE_RPC_URL" "BASE_MAINNET" "Base"
echo -e "${CYAN}Send 1 UP: Base -> Flare${NC}"
run_forge "script/send-up/SendUpFromBase.s.sol:SendUpBaseToFlare" "$BASE_MAINNET" 8453
