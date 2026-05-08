# Repository Analysis: ValidatorBonding

## Toolchain & Dependencies

- **Solidity**: 0.8.30
- **EVM target**: prague
- **Optimizer**: 200 runs
- **OpenZeppelin**: 5.3.0 (non-upgradeable)
- **Foundry**: forge build/test with `--ffi`

## Relevant Codebase Patterns

### AccessControl Pattern (SuperGovernor.sol)
- Roles defined as `bytes32 private constant` with external pure getters
- Example: `bytes32 private constant _GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");`
- Public getter: `function GOVERNOR_ROLE() external pure returns (bytes32) { return _GOVERNOR_ROLE; }`
- Constructor grants `DEFAULT_ADMIN_ROLE` and specific roles

### EnumerableSet Usage (SuperGovernor.sol)
- `EnumerableSet.AddressSet private _validators;`
- `.add()`, `.remove()`, `.contains()`, `.values()`, `.length()`
- Never use Solidity `delete` on EnumerableSet

### SafeERC20 (SuperBank.sol)
- `using SafeERC20 for IERC20;`
- Uses `safeTransfer`, `safeTransferFrom`
- No `forceApprove` needed (ValidatorBonding only transfers, no approvals)

### Error Convention
- SCREAMING_SNAKE_CASE custom errors
- Examples: `INVALID_ADDRESS()`, `INVALID_BANK_MANAGER()`, `ZERO_AMOUNT()`
- Defined in interface files

### File Organization
- Source: `src/ValidatorBonding.sol`
- Interface: `src/interfaces/IValidatorBonding.sol`
- Tests: `test/unit/ValidatorBonding.t.sol`
- Deploy: `script/DeployValidatorBonding.s.sol`

### Testing Patterns
- Base class: `PeripheryHelpers` (from `test/utils/PeripheryHelpers.sol`)
- Account setup: `_deployAccount(seed, label)` from `InternalHelpers`
- Role granting in fork tests via `vm.store` on AccessControl storage slots:
  ```solidity
  bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
  bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
  vm.store(contractAddr, hasRoleSlot, bytes32(uint256(1)));
  ```
- Event testing: `vm.expectEmit(true, true, true, true)`
- Revert testing: `vm.expectRevert(IContract.ERROR_NAME.selector)`

### Deployment Pattern
- `DeterministicDeployerLib` from v2-core for deterministic deploys
- Constructor params passed at deploy time (non-upgradeable)
- Config structs in `script/utils/ConfigPeriphery.sol`

### SuperGovernor Integration Points
- `setValidatorConfig(address[] validators, uint256 quorum, ...)` - manages oracle validator set
- Has no `multicall` function - atomic slash+removal relies on Safe multisig batching
- Roles: `SUPER_GOVERNOR_ROLE`, `GOVERNOR_ROLE`, `ORACLE_MANAGER_ROLE`, etc.

## Key Addresses (Base Mainnet)
| Contract | Address |
|----------|---------|
| SuperGovernor | `0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4` |
| SuperBank | `0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15` |
