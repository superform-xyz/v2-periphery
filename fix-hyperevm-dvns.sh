#!/bin/bash
# Update HyperEVM DVN configs: 4 DVNs (Canary, Nethermind, Horizen, LZ Labs), 20 confirmations, all pathways send+receive
HYPEREVM_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/HYPEREVM_RPC_URL/credential)
SENDER=$(cast wallet address --account v2-supervaults)
forge script script/UpdateDVNs.s.sol:UpdateDVNsHyperEVM --rpc-url "$HYPEREVM_MAINNET" --chain 999 --account v2-supervaults --sender "$SENDER" --broadcast -vvv
