# Repo Analysis — BasefeeGasOracle conventions

Source: repo-research-analyst agent, 2026-08-18.

## 1. Oracle contract conventions (src/oracles/)

Reference contracts: `src/oracles/SuperformGasOracle.sol` (closest analogue — AggregatorV3 + AccessControl) and `src/oracles/FixedPriceOracle.sol` (Ownable variant).

- **SPDX/pragma**: `// SPDX-License-Identifier: MIT` + `pragma solidity ^0.8.30;` for src contracts (SuperformGasOracle.sol:1-2). Tests/scripts use `UNLICENSED`.
- **Imports**: named imports with bracket spacing: `import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";` (SuperformGasOracle.sol:4); Chainlink interface via relative path (:5).
- **Contract-level NatSpec**: `/// @title`, `/// @notice`, multi-line `/// @dev` continuation (SuperformGasOracle.sol:7-12).
- **Section headers**: boxed comments in order: ERRORS, EVENTS, ROLES, STATE, CONSTRUCTOR, ADMIN FUNCTIONS, AGGREGATOR V3 INTERFACE, LEGACY INTERFACE.
- **Errors**: SCREAMING_SNAKE custom errors with `/// @notice Thrown when ...`: `error INVALID_GAS_PRICE();` (SuperformGasOracle.sol:18-19). Pattern: `if (x <= 0) revert INVALID_GAS_PRICE();`.
- **Events**: PascalCase, old/new value pairs, no indexed params, full `@param` docs (SuperformGasOracle.sol:25-32). Emit after state write, old value captured first (:94-103).
- **Roles**: `bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");` (:38-39). Constructor grants `DEFAULT_ADMIN_ROLE` + operational role to same `admin_` (:81-84). **`GAS_MANAGER_ROLE` already exists platform-wide**: `src/SuperGovernor.sol:98` (`_GAS_MANAGER_ROLE = keccak256("GAS_MANAGER_ROLE")`, exposed at :652); `GAS_MANAGER` address constant at `script/utils/ConfigBase.sol:48`. Reuse the exact role string.
- **State**: private storage + public getters; private `constant DECIMALS`/`DESCRIPTION`/`VERSION` (:45-65). Trailing underscore for constructor params (`admin_`).
- **AggregatorV3 style**: `/// @inheritdoc AggregatorV3Interface` + `override` on all five functions (:122-158), plus legacy `latestAnswer()` (:164-168). Round data returns `(_roundId, answer, ts, ts, _roundId)`. FixedPriceOracle always returns `block.timestamp` (:128-134) — the right model for a basefee oracle (fresh by construction, no toggle needed).
- **Lint pragmas**: `// forge-lint: disable-next-line(unsafe-typecast)` with "Safe cast" justification (FixedPriceOracle.sol:139-141). Lint covers src/ only.

## 2. AggregatorV3Interface vendor import

`src/vendor/chainlink/AggregatorV3Interface.sol` — imported as `import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";`. `pragma ^0.8.0`, all five functions `view` (implementations may tighten to `pure`).

## 3. Test conventions

- Unit test location: `test/oracles/BasefeeGasOracle.t.sol` (SuperformGasOracle's test is at `test/oracles/SuperformGasOracle.t.sol`, NOT test/unit/).
- **Base contract**: plain `forge-std/Test` (no BaseTest for oracle unit tests). `pragma solidity 0.8.30` pinned, `UNLICENSED`.
- **Naming**: `test_<Subject>_<Behavior>` (e.g. `test_SetGasPrice_RevertsNonKeeper`), `testFuzz_` for fuzz. No `testRevert_` prefix in repo — use `test_..._RevertsOn...`.
- **Structure**: boxed section headers, `/// @notice` on every test, events re-declared locally for `vm.expectEmit(true, true, false, true)`.
- **AccessControl asserts**: `abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, account, ROLE)`. Custom errors: `vm.expectRevert(X.ERROR.selector)`.
- **`vm.fee()` used nowhere in repo yet**; default test env has `block.basefee = 0`, so tests must set it explicitly.
- **Fork test pattern** (`test/integration/oracles/UpOracleUpdate.t.sol`):
  - `vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"))` in setUp (:103).
  - Hardcoded prod constants (:61-68) incl. `CHAINLINK_GAS_ORACLE = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C`.
  - Local `GAS_QUOTE`/`WEI_QUOTE` constants (:77-78).
  - Role acquisition via storage write `_grantRoleViaStorage` (OZ 5.x slot-0 recipe) + `require(hasRole)` verify (:146-162).
  - Oracle swap flow: `vm.prank(oracleManager); governor.queueOracleUpdate(...)` (:323-336) → `vm.warp(+1 weeks + 1)` → `executeOracleUpdate()` (:339-342) → assert `superOracle.getOracleAddress(...)` (:208).
  - **After warping, all feeds must have staleness raised** via `governor.setOracleMaxStaleness` + `setOracleFeedMaxStalenessBatch` (:346-368) or Chainlink reads revert stale.

## 4. Deploy script conventions

Template: `script/DeploySuperformGasOracle.s.sol`, extends `DeployV2Base`:
- `run(uint256 env, uint64 chainId, ...)` with `broadcast(env)` modifier (DeployV2Base.s.sol:33-48); read-only `runCheck(...)` (:49-81).
- `_setBaseConfiguration(env, "")` first; string `require`s SCREAMING_SNAKE; deterministic deploy via `__deployContract(KEY, chainId, __getSalt(KEY), creationCode+args)`.
- Salt: `keccak256(abi.encodePacked("SuperformV2", SALT_NAMESPACE, name, "v2.0"))` (DeployV2Base.s.sol:437-441) — constructor args must be stable for stable address.
- Post-deploy `require` verification, then `vm.writeJson` merge into `script/output/{env}/{chainId}/{Chain}-latest.json`.
- ConfigBase: new constant goes next to `ORACLE_GAS_TO_ETH` (ConfigBase.sol:62-63); mainnet feed selection is in `DeployV2Periphery.s.sol:443-446` (`_checkSuperOracle`).

## 5. foundry.toml

- `solc = "0.8.30"` pinned, `evm_version = "prague"` (basefee + vm.fee fine), optimizer 200 runs.
- Fuzz runs: 10 default, 10_000 in `[profile.ci]`.
- `[fmt]`: line 120, `bracket_spacing`, `number_underscore = "thousands"`, double quotes — run `forge fmt`.
- `[lint]`: `lint_on_build = true`, src/ linted; `unsafe-typecast` needs inline disable comment.

## 6. Applicable coding rules (superform-specs/guidelines/solidity/coding-rules.md)

- Explicit visibility + NatSpec on all public/external functions.
- Custom errors, not revert strings.
- OZ AccessControl for permissions; events for all state changes (old/new pattern).
- Immutables for construction-time values; storage packing (multiplierBps can share a slot with priorityFeeWei).
- Document wei denomination and `decimals() = 0` prominently (mirroring SuperformGasOracle's Gwei docs).
- Testing: unit + fuzz + fork integration.

## Recommendations

- Model contract 1:1 on SuperformGasOracle.sol; return `block.timestamp` in round data like FixedPriceOracle (no toggle).
- Reuse role string `GAS_MANAGER_ROLE` (already platform-standard).
- Unit test in `test/oracles/BasefeeGasOracle.t.sol`; fork test modeled on UpOracleUpdate.t.sol with storage-slot role grants.
- Deploy script cloned from DeploySuperformGasOracle.s.sol; ConfigBase constant + `_checkSuperOracle` mainnet branch update at cutover.
