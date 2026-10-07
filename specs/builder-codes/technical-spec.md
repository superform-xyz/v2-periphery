# Builder codes: v2-periphery registry

Source: [v2-core Notion specification](https://app.notion.com/p/3f135672200c8122b202f03af59fb11e).
Implementation, simplified-role revision and move to v2-periphery authorized October 7, 2026; deployment limited to Base mainnet (8453). The user-approved model and repository placement supersede the original Notion proposal.

## Registry decisions

`SuperBuilderCodeRegistry` is a standalone, non-upgradeable ERC-8021 registry. It holds no funds and provides no payout operation.

- Exact ASCII codes match `[a-z0-9_]{1,32}`. No trimming or normalization.
- A nonzero, opaque `bytes32` partner ID is assigned once. Persephone owns the external ID encoding; it must be stable across signer and payout changes. Multiple codes can share it.
- A nonzero payout address and a URI of 0–2,048 **bytes** are mutable metadata. The current payout address exclusively controls updates to that code. Changing it immediately transfers both payout and management authority; the old address loses access.
- `isValidCode` checks grammar even for unregistered codes. `isRegistered`, `partnerId`, `payoutAddress`, and `codeURI` return false/zero/empty for unknown codes.
- `DEFAULT_ADMIN_ROLE` is the only role used by the registry. It registers codes and manages admin membership, and is granted only to governance by the constructor. There are no registrar or metadata-manager roles. Neither the deterministic factory nor the transaction signer gets implicit permissions. Admins cannot override the current payout address's metadata control.
- Registration cannot be repeated or deleted; the code-to-partner assignment cannot be changed. Management is per code, even for codes sharing one partner ID. Metadata setters require the current payout address even when unchanged, and return without an event for an authorized no-op.
- The assigned payout address must be able to call this registry. Address changes have no acceptance step or admin recovery; confirm the destination address before transferring control.
- Registration records indexed code hash and partner ID plus raw code, payout, and URI. Metadata changes record the code hash and previous/new value. AccessControl records role changes.

Code identity includes `(registry chain ID, registry address, exact code)`. Indexers use canonical registration logs and action history to decide eligibility. Timestamp/confirmation/reorg rules across chains remain Persephone decisions; the registry does not guess those rules.

## Execution contract compatibility

No production executor, validator, adapter, hook, or vault implementation changes are required.

The pinned [ERC-8021 author draft](https://github.com/ilikesymmetry/ERCs/blob/457532f5c064a4619868ee5e4950f0cc32a7917e/ERCS/erc-8021.md) and Bundler encoder use:

`registryAddress[20] || chainID[N] || N[1] || code[L] || L[1] || 0x01 || 0x80218021802180218021802180218021`

Chain IDs use minimal nonempty big-endian bytes. Shared vectors are in `test/fixtures/builder-codes.json`, matching Bundler's `pkg/erc8021/testdata/builder_codes.json`. Fixture registry addresses are examples, not deployment addresses.

Append before hashing/signing, outside the complete Nexus `execute` arguments or destination inner `execute(bytes)` arguments. Legacy Across/deBridge and Across V2 preserve the signed bytes. Adding, changing, or removing the suffix after signing must fail proof verification.

The exact 228-byte destination entry with no hooks must remain unchanged. A suffix makes it enter the execution path and fail `NO_HOOKS`. Inputs of 0–3 bytes still fail the existing selector bounds check. These behaviors are tested rather than changed.

Direct EOA vault deposit, requestRedeem, and redeem accept the trailing suffix. Approval/helper calls remain Bundler's responsibility. Registry calls are never inserted into a user execution.

## Repository ownership and verification

The user requested moving the registry from v2-core to v2-periphery. Registry source, interfaces, unit/deployment tests, ABI/Go binding, bytecode artifacts, deployment tooling and history now live here. Core execution contracts require no production changes; additional calldata compatibility checks were run in the local core checkout. The four real SuperVault lifecycle comparisons now run natively in this repository.

```sh
# Target the feature and its complete dependency graph in this checkout.
FOUNDRY_SRC=src/attribution FOUNDRY_SCRIPT=src/attribution FOUNDRY_TEST=test/unit/attribution forge build --skip test
FOUNDRY_SRC=src/attribution FOUNDRY_SCRIPT=src/attribution FOUNDRY_TEST=test/unit/attribution forge test --fuzz-runs 256 -vv
make generate CONTRACT=SuperBuilderCodeRegistry
```

The broad periphery build has pre-existing missing nested modulekit ERC-4337 and Nexus solarray node_modules. The targeted roots keep the same compiler/optimizer/EVM settings and include the actual registry, deployment script, and real vault dependencies. They do not substitute mocks for the registry, governor, vault, strategy, escrow or aggregator; only the vault test's asset and price oracle are mocks. Periphery has no root Go module; the generated standalone binding was compiled using v2-core's pinned Go dependency environment.

Validation: 32 periphery tests passed (23 registry, 5 deployment, 4 real-vault lifecycle), with 256 fuzz runs. All 32 also passed in an isolated checkout using the repository's recorded core revision `3ea4574b40aa4c0aa115789e7fb7f3f0cdd8955d` and matching nested dependencies. The 16 additional destination tests passed in the local core checkout after moving the implementation. Previous 5 deployed Base Nexus tests at block 52,285,543 remain valid: their source and fixture are unchanged. Periphery's fresh ABI, creation and runtime bytecode match the reviewed core implementation exactly. Scoped binding generation preserves all existing bindings byte-for-byte.

## Base deployment and handoff

The explicitly selected constructor admin is periphery's `GOVERNOR`: **`0x9e01f41da2212C1FBc32A041CfAEF72479FA48eC`**. It is distinct from `SUPER_GOVERNOR_ADDRESS` (`0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e`) and the Base `SuperGovernor` contract (`0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4`). The user confirmed the selected address knowing it currently has no contract code on Base. An admin need not be a deployed contract.

`script/DeploySuperBuilderCodeRegistry.s.sol` rejects other chains and uses the fixed production governor, existing deterministic factory and salt namespace. It verifies fresh versus locked creation bytecode and deployed runtime/admin. The script never writes manifests; publication happens only after an independently confirmed successful receipt. Additional admins receive full admin membership management as well as code issuance; no additional admins or codes are assigned during deployment.

```sh
FOUNDRY_SRC=src/attribution FOUNDRY_SCRIPT=src/attribution FOUNDRY_TEST=test/unit/attribution \
  forge script script/DeploySuperBuilderCodeRegistry.s.sol:DeploySuperBuilderCodeRegistry \
  --sig 'run(bool)' true --rpc-url https://mainnet.base.org
# Authorized deployment uses false plus --broadcast and secure signer options.
```

The salt remains `0xa00ad207f01692f1fc9f5c1905902c1cd6eac62c182819a6475f1f6e133e24dd`. Changing the constructor admin changes the CREATE2 address even though runtime bytecode remains identical.

Historical Base deployments are preserved under `archive/`: the initial three-role registry at `0xAa47CcbbD7074e33F89fE4ee98a6eAc304762888` and the simplified registry with the previous admin at `0x5E02efd9443CEEd45af408E45bbB5e28c35A3cE0`. Each archived receipt points to its own immutable artifact. Historical action attribution retains its original registry namespace. The current Base registry is [`0x5f4a89321917279547468ade27bED8CbCfA267d3`](https://basescan.org/address/0x5f4a89321917279547468ade27bED8CbCfA267d3#code), transaction [`0x9c799b681e3d1d8210d1610533a89dd3647be7f37715ab5611c273aedfc1d31e`](https://basescan.org/tx/0x9c799b681e3d1d8210d1610533a89dd3647be7f37715ab5611c273aedfc1d31e), confirmed at block **52,288,551**. Explorer verification reports the source already verified. The runtime matches the periphery compiled/locked artifact exactly (`0xbc9f8c0f27c261d9f38b72dda5939dc050f401fa8495447fe7fc7b79d6a6dd8e`); the new initcode hash is `0xb069e4899e596c923acddb0aa212d3fa224185d14835d99e8e8a3bfb0456fe98`.

Receipt and live role checks confirm only the selected GOVERNOR has initial admin; the prior SuperGovernor Safe, SuperGovernor contract, deployment signer and factory do not. No codes or additional admins were created. Both historical registries had no CodeRegistered events through block 52,288,513.

Machine-readable handoff: `deployment-base.json`. Actual gas: 1,013,197; execution plus L1 fee: 5,439,718,024,494 wei. Periphery Base/aggregate manifests contain the new registry; core's active registry entries were removed. All other contracts and networks are unchanged, including pre-existing differences between periphery's Base and aggregate manifests. Temporary signing material and sensitive Forge caches were removed.

Bundler and Persephone must consume the new registry chain/address/deployment block and ABI. Admin issuance replaces the original separate-registrar flow; metadata changes come from the code's current payout address. Updating external service configuration is outside this repository migration.

## Work tracking

- [x] Move registry, interfaces, tests, tooling, binding and archived provenance to periphery.
- [x] Validate 32 native periphery tests and 16 local core compatibility checks; independent migration review.
- [x] Base deployment with selected governor, source verification and manifest handoff.
