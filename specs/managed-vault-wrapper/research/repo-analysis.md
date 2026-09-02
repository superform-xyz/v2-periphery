# Repository Analysis — Managed Vault Wrapper

## Key File Paths

| File | Purpose |
|------|---------|
| `src/SuperGovernor.sol:433` | `setActivePPSOracle` — sets oracle if none exists |
| `src/SuperGovernor.sol:447` | `proposeActivePPSOracle` — propose new oracle (7-day timelock) |
| `src/SuperGovernor.sol:457` | `executeActivePPSOracleChange` — execute after timelock |
| `src/SuperGovernor.sol:744` | `isActivePPSOracle(address)` — simple address equality |
| `src/SuperGovernor.sol:739` | `getActivePPSOracle()` |
| `src/oracles/ECDSAPPSOracle.sol` | Current active oracle — inherits from here |
| `src/SuperVault/SuperVaultAggregator.sol:239` | `forwardPPS(ForwardPPSArgs)` — requires `onlyPPSOracle` |
| `src/SuperVault/SuperVaultStrategy.sol:318` | `fulfillRedeemRequests(controllers[], totalAssetsOut[])` |
| `src/SuperVault/SuperVault.sol:182` | ERC-7540 redeem (async redeem already implemented) |
| `src/SuperVault/SuperVault.sol:145` | Synchronous ERC-4626 deposit |
| `src/vendor/standards/ERC7540/IERC7540Vault.sol` | `IERC7540Vault`, `IERC7540Deposit`, `IERC7540Redeem` |
| `src/vendor/vaults/7540/IERC7540.sol` | Full async ERC-7540 reference interface |
| `test/integration/SuperVault/BaseSuperVaultTest.t.sol` | setUp pattern for integration tests |
| `test/BaseTest.t.sol:109` | Full periphery deployment including oracle setup |

## Critical Finding: Aggregator Strategy Registration

`forwardPPS` in `SuperVaultAggregator` skips strategies not registered in `_superVaultStrategies`:
```solidity
// Line ~247 in SuperVaultAggregator.sol
if (!_superVaultStrategies.contains(strategy)) {
    emit UnknownStrategy(strategy);
    continue; // silently skips — PPS not updated!
}
```

**Implication:** `ManagedVaultWrapper` must be registered in `_superVaultStrategies` for `forwardPPS` to work.

**Options:**
1. **Use `aggregator.createVault()`** — creates full SV family (vault, strategy, escrow). ManagedVaultWrapper IS the vault. Manager still needs to fulfill manually. **Bloats deployment.**
2. **Add `aggregator.registerManagedWrapper(address)`** — minimal aggregator change to add wrapper to `_superVaultStrategies` without deploying SV family. **Requires one aggregator function.**
3. **ManagedECDSAAppsOracle calls `wrapper.setPPS()` directly** — bypasses aggregator entirely. ManagedVaultWrapper has its own `storedPPS`. Oracle is NOT required to go through aggregator. **No aggregator changes needed.**

**Recommended: Option 3.** Wrapper has own PPS storage. ManagedECDSAAppsOracle calls two functions:
- For automated SV strategies: `aggregator.forwardPPS(args)` (existing path)
- For managed wrapper strategies: `IManagedVaultWrapper(strategy).setPPS(pps)` (new path)

This is the cleanest separation with zero aggregator changes.

## Oracle Rotation Flow

```
// Step 1: Propose (SUPER_GOVERNOR_ROLE)
superGovernor.proposeActivePPSOracle(address(newManagedOracle));
// → emits ActivePPSOracleProposed(oracle, effectiveTime)

// Step 2: Wait 7 days (TIMELOCK = 7 days)
vm.warp(block.timestamp + 7 days + 1); // in tests

// Step 3: Execute (permissionless after timelock)
superGovernor.executeActivePPSOracleChange();
// → _activePPSOracle = newManagedOracle
// → emits ActivePPSOracleChanged(oldOracle, newOracle)
```

## Key Interface Signatures

```solidity
// ISuperVaultAggregator
struct ForwardPPSArgs {
    address[] strategies;
    uint256[] ppss;
    uint256[] timestamps;
    address updateAuthority;
}
function forwardPPS(ForwardPPSArgs calldata args) external; // onlyPPSOracle

// ISuperVaultStrategy (fulfill)
function fulfillRedeemRequests(
    address[] calldata controllers,
    uint256[] calldata totalAssetsOut
) external;

// IECDSAPPSOracle (existing oracle)
struct UpdatePPSArgs {
    address[] strategies;
    bytes[][] proofsArray;
    uint256[] ppss;
    uint256[] timestamps;
}
function updatePPS(UpdatePPSArgs calldata args) external;
```

## Existing ERC-7540 Implementation in SuperVault

SuperVault currently implements **async REDEEM only** (not async deposit). It inherits:
- `IERC7540Redeem` ✅
- `IERC7540Operator` ✅
- `IERC7540CancelRedeem` ✅
- `IERC7540Deposit` ❌ (not implemented — deposit is sync ERC-4626)

`REQUEST_ID` is hardcoded to `0` (single request per controller at a time).

`ManagedVaultWrapper` will need full `IERC7540Vault` (both deposit AND redeem async).

## Conventions

- **Clone pattern:** OZ `Clones.cloneDeterministic(impl, salt)` used in `SuperVaultAggregator`
- **PRECISION:** `10 ** decimals` used as PPS base unit in strategy
- **Role constants:** `keccak256("GOVERNOR_ROLE")` etc. — match exactly from SuperGovernor
- **Import paths:** relative paths for periphery, `@superform-v2-core/` for core
- **Licensing:** `// SPDX-License-Identifier: Apache-2.0`
- **Pragma:** `pragma solidity 0.8.30;`

## No Existing Managed Vault Files

None of the following exist yet:
- `ManagedECDSAAppsOracle`
- `ManagedVaultWrapper`
- `ManagedVaultWrapperFactory`
- `ManagedNAVOracle` (from PR #326 — different architecture)
- `ManagedSuperVaultDepositQueue` (from PR #326 — different architecture)
