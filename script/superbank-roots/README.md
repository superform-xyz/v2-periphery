# SuperBank Merkle Root Generation

Migrated from the archived **superman** repo (`scripts/roots_management/prod/generate_superbank_roots.py`
plus its merkle library and config dependencies). Output is byte-identical to the superman generator
(validated by running both against the same config and diffing all files).

SuperBank uses **one merkle tree per hook** (unlike SuperVault's single global tree). Each tree's
leaves are `keccak256(keccak256(abi.encode(hookAddress, hook.inspect(hookData))))` over the argument
combinations declared in `config/superbank_hook_config.json`.

## Layout

```
script/superbank-roots/
├── generate_superbank_roots.py   # CLI entry point
├── superbank_tree_builder.py     # Per-hook tree construction + proof generation
├── tree_builder.py               # Merkle math (sorted-pair keccak, OZ-compatible) + tag FilterEngine
├── config_loader.py              # address_registry loader
├── deployments_resolver.py       # hook name -> deployed address (config/deployments.json)
├── config/
│   ├── superbank_hook_config.json  # Per-hook argument specs (the SuperBank leaf definitions)
│   ├── address_registry.json       # Per-chain token whitelists + tags (feeds `type: "token"` args)
│   └── deployments.json            # Hook name -> address per chain/env (snapshot from superman)
├── generated/prod/{chainId}/       # Output: hook_0x<address>.json (leaves+proofs) + trees_summary.json
└── roots_to_propose.md             # Current proposal list + cast commands
```

## Usage

```bash
pip install -r script/superbank-roots/requirements.txt   # eth-abi, eth-utils

make generate-superbank-roots CHAIN_ID=8453
# or directly:
ENVIRONMENT=prod python3 script/superbank-roots/generate_superbank_roots.py --chain-id 1
# regenerate a subset of hooks only:
python3 script/superbank-roots/generate_superbank_roots.py --chain-id 999 --hooks SwapKyberSwapHook
```

Heads-up: chain 1 takes ~35 minutes (the merged PendleUnifiedHook tree has 33k leaves and proof
generation is O(n²)). The other chains finish in seconds.

## Proposing roots on-chain

Roots go through SuperGovernor (same address on all chains: `0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4`):

1. `registerHook(address)` — required once per (re)deployed hook, else propose reverts `HOOK_NOT_APPROVED()`
2. `proposeSuperBankHookMerkleRoot(address hook, bytes32 root)` — needs `GOVERNOR_ROLE`
3. 7-day timelock
4. `executeSuperBankHookMerkleRootUpdate(address hook)` — permissionless

See `roots_to_propose.md` for the current per-chain hook/root table and ready-made cast commands.

## Keeping addresses current

`config/deployments.json` is a snapshot of the archived superman repo's `contracts/deployments.json`.
When hooks are redeployed, update the relevant hook addresses there (authoritative sources:
`script/output/{env}/{chainId}/*-latest.json` here and in v2-core) before regenerating.

## Hook argument types

Each hook's `args` list in `config/superbank_hook_config.json` is packed in order to reproduce the hook's on-chain
`inspect()` output (`abi.encodePacked`). Supported `type`s:

| type | source of values | packed as |
|---|---|---|
| `token`, `yieldSource`, `feeRecipient` | `address_registry.json` entries (tag-filterable) | 20 bytes |
| `contract` (+ `subtype`) | contract registry | 20 bytes |
| `superbank`, `beneficiary` | the SuperBank address | 20 bytes |
| `zero_address` | `address(0)` | 20 bytes |
| `uint256` (+ `values`) | explicit constants listed in the config, one leaf per value | 32-byte big-endian word |

`uint256` exists for hooks whose `inspect()` commits a non-address parameter, e.g. the health-check guards'
`minHealthFactor` (v2-core PR #1037): a leaf there is `(marketKey, ..., lltv, minHealthFactor)`, so the threshold must
be enumerated explicitly:

```json
"MorphoHealthCheckHook": {
  "args": [
    { "name": "marketKey", "type": "contract", "subtype": "morpho_market" },
    ...
    { "name": "minHealthFactor", "type": "uint256", "values": ["1500000000000000000", "2000000000000000000"] }
  ]
}
```

Values may be decimal or `0x`-hex strings (or ints) and are range-checked; the leaf changes whenever the value does.

## Known state / caveats (as of 2026-07-29)

- `config/superbank_hook_config.json` includes Base WETH (`0x4200…0006`) and Base cbBTC (`0xcbB7…3Bf`)
  as Across `outputToken` additionalAddresses (added for WETH/WBTC ETH→Base bridging). Chain 1 trees
  were regenerated with this config (Across roots `0x8f9ac93a…` / `0xe9993d52…`, 1188 leaves).
  **Chains 999/8453/14 `generated/` snapshots predate that config change** and match the roots
  proposed on-chain; regenerating them will grow the Across trees (e.g. 999: 6 → 10 leaves) and
  produce new roots that would need re-proposal.
- The ApproveERC20Hook trees have **no spender leaf** for the KyberSwap router
  (`0x6131B5fae19EA4f9D964eAc0408E4408b66337b5`) or the HyperEVM Across SpokePool
  (`0x35E63eA3eb0fb7A3bc543C71FB66412e1F6B0E04`). Standalone `SwapKyberSwapHook` (all chains) and
  standalone Across on 999 therefore have no production approval path — only the `ApproveAnd…`
  combined hooks are executable end-to-end. Add those spenders to the ApproveERC20Hook
  `additionalAddresses` and regenerate if the standalone hooks should become usable.
- The integration tests in `test/integration/SuperBank/*V2.t.sol` embed roots/proofs taken from
  `generated/prod/` — regenerate → update the test constants when configs change.
