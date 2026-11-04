# Katana reverse legs: Safe transactions

Six transaction lists, one per chain, enabling `<chain> -> Katana` at 4-of-4 DVNs.
The Katana side (Katana to all seven remotes) is already configured.

| Leg | Owner | Status |
|---|---|---|
| Katana -> all 7 | deployer EOA | done |
| Arc -> Katana | deployer EOA | done |
| [Ethereum -> Katana](./ethereum-to-katana.md) | Safe `0x89226a5F…` | pending |
| [Base -> Katana](./base-to-katana.md) | Safe `0x89226a5F…` | pending |
| [BSC -> Katana](./bsc-to-katana.md) | Safe `0x89226a5F…` | pending |
| [HyperEVM -> Katana](./hyperevm-to-katana.md) | Safe `0x89226a5F…` | pending |
| [RH -> Katana](./rh-to-katana.md) | Safe `0x89226a5F…` | pending |
| [Flare -> Katana](./flare-to-katana.md) | Safe `0x0f0Db7CE…` | pending |

Shared: Katana eid 30375, peer `0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E`,
20 confirmations, 4 required DVNs, optional count 255, max message size 10000.
DVNs, libraries and executors are per chain.

All 24 DVNs and 6 executors were verified on chain to serve eid 30375. On every
chain `peers(30375)` is unset and enforced options are empty, so no transaction
is a no-op.

Note: `deploy_up_oft_katana.sh` claims it can sign the RH and Flare legs. Both are
now Safe-owned, so it cannot; `configure-remote rh` reverts with
`OwnableUnauthorizedAccount`.
