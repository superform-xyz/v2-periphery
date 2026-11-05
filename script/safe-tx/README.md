# UP OFT: make every pathway work, and make them all identical

13 Safe runbooks here, plus one local script at `../run/arc_optional_dvn_255.sh`.
Executing all of it leaves **all 56 directed UP transfers working** across the 8
chains where UpOFT is deployed, with **every pathway configured identically**.

## Starting point

| | |
|---|---|
| Pathways configured | 49 of 56 |
| Transfers working | 42 of 56 |
| Pathways at `optionalDVNCount = 255` | 13 of 49 |

Confirmations (20), required DVN count (4), DVN operator sets, pinned libraries,
executor (maxMessageSize 10000) and enforced options are already uniform on all 49.
The two gaps are the 7 unconfigured pathways and `optionalDVNCount` on 36 of them.

## Part 1 — enable the 7 unconfigured pathways (42 transactions)

Each fixes **two** transfers, because a missing peer blocks both directions.

| Runbook | Safe | Chain |
|---|---|---|
| [ethereum-to-arc.md](./ethereum-to-arc.md) | `0x89226a5F…` | Ethereum |
| [base-to-arc.md](./base-to-arc.md) | `0x89226a5F…` | Base |
| [bsc-to-arc.md](./bsc-to-arc.md) | `0x89226a5F…` | BSC |
| [hyperevm-to-arc.md](./hyperevm-to-arc.md) | `0x89226a5F…` | HyperEVM |
| [rh-to-arc.md](./rh-to-arc.md) | `0x89226a5F…` | RH |
| [flare-to-arc.md](./flare-to-arc.md) | `0x0f0Db7CE…` | Flare |
| [flare-to-katana.md](./flare-to-katana.md) | `0x0f0Db7CE…` | Flare |

Six transactions each. `setPeer` is **last** in every one, deliberately: until the
peer exists the OApp can neither send nor receive on that eid, so tokens can never
move against a half-written config. Batch into one MultiSend where possible.

## Part 2 — normalise optionalDVNCount to 255 (14 transactions)

| Runbook | Safe | Pathways |
|---|---|---|
| [ethereum-optional-dvn-255.md](./ethereum-optional-dvn-255.md) | `0x89226a5F…` | 5 |
| [base-optional-dvn-255.md](./base-optional-dvn-255.md) | `0x89226a5F…` | 5 |
| [bsc-optional-dvn-255.md](./bsc-optional-dvn-255.md) | `0x89226a5F…` | 5 |
| [hyperevm-optional-dvn-255.md](./hyperevm-optional-dvn-255.md) | `0x89226a5F…` | 5 |
| [rh-optional-dvn-255.md](./rh-optional-dvn-255.md) | `0x89226a5F…` | 5 |
| [flare-optional-dvn-255.md](./flare-optional-dvn-255.md) | `0x0f0Db7CE…` | 5 |
| `../run/arc_optional_dvn_255.sh` | **EOA, not a Safe** | 6 |

Two transactions each, batching every eid for that chain. Only `optionalDVNCount`
changes; confirmations, required DVN count and the DVN addresses are re-sent exactly
as they are live now.

Arc is a shell script rather than a runbook because Arc's UpOFT is not Safe-governed.
Run `bash script/run/arc_optional_dvn_255.sh simulate` then `execute` with the
`v2-supervaults` keystore.

## End state

All 56 pathways at 20 confirmations, 4 required DVNs, `optionalDVNCount = 255`, empty
optional array, both libraries pinned rather than default, executor maxMessageSize
10000, and the same two enforced option strings. The four DVN operators (Canary,
LayerZero Labs, Superform, Twinstake) are the same on every chain; only their
addresses differ, which is unavoidable.

Total: 54 Safe transactions (42 + 12) plus 2 signed locally on Arc, 56 in all.

## Before you sign: Arc and Katana are EOA-governed

On both chains `owner()` and the endpoint `delegates()` are
`0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8`, a deployer keystore account with no
code. Every other chain uses a Safe with a threshold of 2.

That key can set an arbitrary peer, point the receive config at a DVN it controls,
self-verify a forged packet, mint UP freely on that chain, and bridge it to Ethereum
where the adapter releases real UP from the **250,603,335.46 UP** locked there.
`ethereum-to-arc.md` is what opens that route from Arc.

The exposure is **already live via Katana**: Ethereum's `peers(30375)` is set and
Katana is EOA-owned. Moving both to the Safes is one `transferOwnership` plus one `setDelegate` each,
signable by that key today, since UpOFT uses plain `Ownable`.

**Order matters here.** `arc_optional_dvn_255.sh` deliberately aborts if Arc's owner
is no longer that EOA. So run the Arc script FIRST, then transfer ownership. Transfer
first and the script refuses, leaving Arc's 6 pathways stuck at `optionalDVNCount = 0`
until someone writes a Safe runbook for them.

Suggested sequence: run the Arc script, execute the 13 Safe runbooks, run the canary,
then transfer Arc and Katana ownership to the Safes.

**Check Katana's Safe owner set before transferring to it.** The Safe at
`0x89226a5F…` exists on both Arc and Katana, but they differ: on Arc it has the same
4 owners as the rest of the fleet, while **on Katana it has only 3** — `0xc11E1891…`
is absent — and it has never been used (nonce 0). Transferring Katana's UpOFT there
puts it under a quorum unlike every other chain. Fix the owner set first, or transfer
Arc only. Flare's Safe is also version 1.3.0 where the others are 1.4.1, so do not
hardcode a single MultiSend address when batching.

## Nothing is stranded, so there is no need to rush

Arc and Katana both report `totalSupply() = 0`, outbound nonces from both are 0, and
inbound nonces for their eids are 0 at every destination. No UP has ever moved on an
Arc pathway.

## Verify as you go

```bash
cast call <UpOFT> 'peers(uint32)(bytes32)' <eid> --rpc-url <rpc>
cast call <endpoint> 'isDefaultSendLibrary(address,uint32)(bool)' <UpOFT> <eid> --rpc-url <rpc>
cast call <lib> 'getAppUlnConfig(address,uint32)((uint64,uint8,uint8,uint8,address[],address[]))' <UpOFT> <eid> --rpc-url <rpc>
```

Use `getAppUlnConfig`, not `getConfig`. `getConfig` resolves a NIL optional count back
to 0, so it reports 0 where 255 was written. If `getAppUlnConfig` shows 0, the write
did not land.

## Finish with a canary, on two pathways

**No LayerZero message has ever been delivered on any of the 56 pathways**, not just
the Arc ones. Every `outboundNonce`, `inboundNonce` and `lazyInboundNonce` across all
56 reads 0. The mesh was seeded by minting on each chain, not by bridging: the 7 remote
supplies sum to 250,603,335.459445 UP, exactly the balance locked in the mainnet
adapter.

So delivery is unproven everywhere, and a systemic gap in a DVN or executor backend
would surface only after you announce. `dstConfig` presence proves the on-chain route,
never that the operators actually run it.

Send 1 UP across **one newly opened pathway and one pre-existing one** before
announcing all 56 as live.
