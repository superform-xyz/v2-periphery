#!/bin/bash
# Update Flare DVN configs: 4 DVNs (Nethermind, LZ Labs, Canary, Horizen), 20 confirmations, all pathways send+receive
FLARE_MAINNET=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/FLARE_RPC_URL/credential 2>/dev/null)
if [ -z "$FLARE_MAINNET" ]; then
    FLARE_MAINNET="https://flare-api.flare.network/ext/C/rpc"
fi
SENDER=$(cast wallet address --account v2-supervaults)
forge script script/UpdateDVNs.s.sol:UpdateDVNsFlare --rpc-url "$FLARE_MAINNET" --chain 14 --account v2-supervaults --sender "$SENDER" --broadcast -vvv
