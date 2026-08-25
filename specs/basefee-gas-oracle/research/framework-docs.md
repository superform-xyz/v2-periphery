# Framework Docs — BasefeeGasOracle

Source: framework-docs-researcher agent, 2026-08-18. All facts verified against installed library sources.

## Installed versions

| Library | Version | Path |
|---|---|---|
| openzeppelin-contracts (what `@openzeppelin/contracts/` maps to) | **5.3.0** | `lib/v2-core/lib/openzeppelin-contracts` (via v2-core submodule — top-level `lib/openzeppelin-contracts` does not exist) |
| forge-std | 1.10.0 | `lib/forge-std` |
| solc | 0.8.30 pinned, `evm_version = "prague"`, optimizer 200, fuzz runs = 10 (10_000 in CI profile) | `foundry.toml` |

## OZ AccessControl 5.3.0

Storage (matters for `vm.store` on forks): `_roles` mapping at **slot 0**; `RoleData.hasRole` at struct offset 0 — the CLAUDE.md recipe is confirmed:
```solidity
bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
vm.store(target, hasRoleSlot, bytes32(uint256(1)));
```
(Upgradeable 5.x uses ERC-7201 namespaced storage instead — NOT slot 0. SuperGovernor is non-upgradeable, so slot 0 applies.)

Semantics:
- `DEFAULT_ADMIN_ROLE = bytes32(0)`; default admin of every role; its own admin.
- `onlyRole` reverts with custom error `AccessControlUnauthorizedAccount(address, bytes32)` (5.x; no revert strings).
- Constructor: internal `_grantRole(...)` (no restriction, emits `RoleGranted`); `_setupRole` removed in 5.x.
- `_grantRole`/`_revokeRole` return bool in 5.x.
- `renounceRole(role, callerConfirmation)` requires confirmation == msg.sender (`AccessControlBadConfirmation`).

## Foundry cheatcodes (forge-std 1.10.0)

- `vm.fee(uint256)` — sets `block.basefee` (Vm.sol:2064). Default basefee in non-fork tests is **0** (repo doesn't set `block_base_fee_per_gas`). Works after `createSelectFork` (overrides fork basefee).
- `vm.expectRevert(bytes4)` for zero-arg custom errors; `abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, account, ROLE)` for parameterized; `vm.expectPartialRevert(bytes4)` exists for selector-only matching of parameterized errors.
- `vm.expectEmit()` modern zero-arg form; repo convention redeclares events locally in tests (≥0.8.21 allows `Contract.Event` references instead).
- `bound()` (uint256 and int256 overloads) preferred over `vm.assume`.
- Fork: `vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"))` — env-var RPCs, no `rpc_endpoints` table; block-pinning overload available.
- Fuzz runs = 10 locally — write explicit edge-case tests, don't rely on fuzz depth.

## `block.basefee` in Solidity 0.8.30

- Available since 0.8.7 (EIP-3198/London); type `uint256` (wei).
- **eth_call caveat (important):** geth-family nodes disable basefee enforcement in `eth_call` when gas-price fields are omitted — `block.basefee` reads **0** in that context. Off-chain reads (`cast call` without `--gas-price`/maxFeePerGas, monitoring dashboards) will see `answer = priorityFeeWei` only, and post-migration `getUpkeepCostPerSingleUpdate` quotes will be understated. On-chain callers (any real tx, including staticcalls between contracts) always see the true basefee. Foundry fork tests see the forked block's basefee. **Mitigation: document that off-chain consumers must pass explicit gas-price fields for true quotes.**
- `int256(block.basefee)` cast: wrap requires ≥ 2^255 (~5.8e76 wei) — physically unreachable; OZ `SafeCast.toInt256` (`@openzeppelin/contracts/utils/math/SafeCast.sol`) is cheap belt-and-suspenders.

## AggregatorV3Interface (vendored, `src/vendor/chainlink/AggregatorV3Interface.sol`)

```solidity
function decimals() external view returns (uint8);
function description() external view returns (string memory);
function version() external view returns (uint256);
function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80);
function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
```
- `pure` may override `view` (sibling contract does this for decimals/description/version).
- `getRoundData(uint80)` should not revert for unknown rounds (sibling returns latest for any id) — keep consistent, document.
- Consumers commonly check `answeredInRound >= roundId` and `updatedAt != 0` — return block-derived roundId with `answeredInRound == roundId`.
- Include legacy `latestAnswer()` for parity with SuperformGasOracle.

## Pitfalls checklist

1. OZ version is 5.3.0 via v2-core remap — don't assume top-level lib path.
2. Unit tests must `vm.fee(...)` explicitly (default 0); decide read behavior at basefee 0 (don't revert on read — unlike SuperformGasOracle's setter validation).
3. Exact-match semantics of `vm.expectRevert(bytes4)`.
4. `getRoundData` non-reverting convention.
5. Shallow local fuzz (10 runs) — explicit edge cases needed.
