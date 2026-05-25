#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
setup "$@"
load_rpc "BASE_RPC_URL" "BASE_MAINNET" "Base"
echo -e "${CYAN}Send 1 UP: Base -> HyperEVM${NC}"
run_forge "script/send-up/SendUpFromBase.s.sol:SendUpBaseToHyperEVM" "$BASE_MAINNET" 8453
