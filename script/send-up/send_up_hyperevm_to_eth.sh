#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
setup "$@"
load_rpc "HYPEREVM_RPC_URL" "HYPEREVM_MAINNET" "HyperEVM"
echo -e "${CYAN}Send 1 UP: HyperEVM -> ETH${NC}"
run_forge "script/send-up/SendUpFromHyperEVM.s.sol:SendUpHyperEVMToETH" "$HYPEREVM_MAINNET" 999
