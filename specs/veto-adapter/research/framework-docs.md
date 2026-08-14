# Framework Research: SuperVaultVetoAdapter (Foundry + OZ)

## 1. Toolchain and versions

| Item | Value | Source |
|---|---|---|
| Solc | `0.8.30` (pinned, `auto_detect_solc = false`) | `foundry.toml:13` |
| EVM version | `prague` | `foundry.toml:62` |
| Optimizer | on, 200 runs | `foundry.toml:9-10` |
| Fuzz runs | 10 default, 10_000 in `[profile.ci]` | `foundry.toml:7,77` |
| OpenZeppelin (non-upgradeable) | **5.3.0** via v2-core: `@openzeppelin/contracts/=lib/v2-core/lib/openzeppelin-contracts/contracts/` | `foundry.toml:22` |
| forge-std | 1.10.0 | `foundry.toml:51` |
| Chimera/Recon invariant framework | `@chimera/`, `@recon/` | `foundry.toml:24-25` |
| Also available | solady, surl, halmos-cheatcodes, erc7540-reusable-properties | `foundry.toml:29,33,39,52` |

No `[rpc_endpoints]` — RPC via env vars. No `[invariant]` section — use inline `/// forge-config:`.

## 2. OZ 5.3.0 pieces

- **ReentrancyGuard** — `@openzeppelin/contracts/utils/ReentrancyGuard.sol`; custom error `ReentrancyGuardReentrantCall()`. Transient-storage variant `ReentrancyGuardTransient.sol` works on Base/prague (cheaper).
- **EnumerableSet** — `Bytes32Set` useful for tracking live proposal IDs. Caveats: no remove-while-iterating; `values()` copies whole set (view-only use).
- **TimelockController internals to borrow** (`governance/TimelockController.sol`):
  - `enum OperationState { Unset, Waiting, Ready, Done }` :34 — extend shape with Vetoed/Expired (OZ has no expiry; cancel = delete-to-Unset)
  - `mapping(bytes32 => uint256) _timestamps` sentinel model :29-31; `getOperationState` :206 derives state from timestamp — with veto+expiry a small struct is cleaner
  - `hashOperation` :232 = `keccak256(abi.encode(...))` (full ABI encode, not packed)
  - Error pattern `TimelockUnexpectedOperationState(bytes32 id, bytes32 expectedStates)` with `_encodeStateBitmap` :58 — one error for all wrong-state reverts
  - OZ marks done *after* external calls; for adapter prefer CEI (mark before forward) + ReentrancyGuard
- **SafeERC20** — needed only for `sweepERC20` (upkeep tokens can land on adapter). **AccessControl** — not needed; immutable operator + live `isGuardian` call with custom-error modifiers.

## 3. Fork-testing conventions (this repo)

```solidity
vm.createSelectFork(vm.envString("BASE_RPC_URL"));              // latest
vm.createSelectFork(vm.envString("BASE_RPC_URL"), FORK_BLOCK);  // pinned
```
- Examples: `test/integration/ValidatorBonding.fork.t.sol:55` (latest), `test/integration/SuperVault/UpdatePPSUpkeepIntegrationBase.t.sol:95` (pinned)
- Env vars injected by Makefile from 1Password (`Makefile:7-9`); fork tests in `test/integration/` with `.fork.t.sol` suffix
- **Best template to copy**: `test/integration/ValidatorBonding.fork.t.sol` — deploys a new periphery contract against live Base SuperVault + SuperGovernor; prod address constants :21-27, `makeAddr` actors :38-45, fork sanity assert :62, deal+prank helpers :76-86
- **Role granting on forks** (OZ 5.x `_roles` at slot 0; used at `ValidatorBonding.fork.t.sol:350-352`):
```solidity
bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
vm.store(SUPER_GOVERNOR, hasRoleSlot, bytes32(uint256(1)));
```
Needed to: give the test SUPER_GOVERNOR_ROLE to call the emergency `changePrimaryManager` (installing the adapter), and GUARDIAN_ROLE for a test guardian.
- **Timelock bypass**: `vm.warp(block.timestamp + WINDOW + 1)`
- Other local cheatcode use: `vm.store` state surgery in `test/unit/SuperVault.t.sol` (:536, :1225, :2692), `vm.expectRevert` with custom-error selectors, `vm.expectEmit`

## 4. Invariant/fuzz testing

**Option A — forge-std StdInvariant** (recommended, lighter): handler contract with `propose/veto/execute/warp` actions, ghost variables (`ghost_proposed`, `ghost_executed`, `ghost_vetoed`), `targetContract(handler)` + `targetSelector`. Inline config:
```solidity
/// forge-config: default.invariant.runs = 256
/// forge-config: default.invariant.depth = 100
/// forge-config: default.invariant.fail-on-revert = false
```
Invariants: vetoed id never executes; executed id never re-executes/vetoes; execute before eta reverts; expired never executes; adapter token/ETH balance returns to zero after sweep. Time advanced only by an explicit `warp` handler action.

**Option B — Chimera/Recon** (`test/recon/` — Setup.sol, TargetFunctions.sol, Properties.sol, CryticTester.sol/CryticToFoundry.sol): repo's established deep-fuzzing pattern; heavier, better if the adapter should join the standing suite.

Default fuzz runs are 10 locally (`foundry.toml:7`) — run `FOUNDRY_PROFILE=ci` for real depth.

## Key references
- `foundry.toml`; `lib/v2-core/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol:29-39,206-232,435`
- `test/integration/ValidatorBonding.fork.t.sol` (fork template)
- `lib/forge-std/src/StdInvariant.sol:40-72`; `test/recon/`
- OZ 5.x docs: https://docs.openzeppelin.com/contracts/5.x/api/governance#TimelockController
- Foundry Book: https://getfoundry.sh/guides/invariant-testing
