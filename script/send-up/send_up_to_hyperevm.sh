#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
setup "$@"
load_rpc "ETHEREUM_RPC_URL" "ETH_MAINNET" "ETH"
echo -e "${CYAN}Send 1 UP: ETH -> HyperEVM${NC}"
run_forge "script/send-up/SendUpToHyperEVM.s.sol:SendUpToHyperEVM" "$ETH_MAINNET" 1
