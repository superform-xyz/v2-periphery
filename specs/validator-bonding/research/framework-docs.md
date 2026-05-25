# Framework Documentation: ValidatorBonding Dependencies

## OpenZeppelin 5.3.0

### AccessControl
- Non-upgradeable version: `@openzeppelin/contracts/access/AccessControl.sol`
- Role constants: Use `bytes32 private constant` with external pure getters (Superform convention)
- `DEFAULT_ADMIN_ROLE` = `0x00` (admin of all roles by default)
- Grant roles in constructor: `_grantRole(DEFAULT_ADMIN_ROLE, admin)`
- `onlyRole(role)` modifier for access control
- No `renounceRole` override needed (default behavior fine for V1)

### EnumerableSet
- `import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";`
- `using EnumerableSet for EnumerableSet.AddressSet;`
- Operations: `.add(value)`, `.remove(value)`, `.contains(value)`, `.length()`, `.values()`, `.at(index)`
- All O(1) except `.values()` which is O(n)
- `.add()` returns `false` if already present (no revert)
- `.remove()` returns `false` if not present (no revert)
- **NEVER** use Solidity `delete` on EnumerableSet — always use `.remove()`

### SafeERC20
- `import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";`
- `using SafeERC20 for IERC20;`
- `safeTransfer(token, to, amount)` and `safeTransferFrom(token, from, to, amount)`
- Handles tokens with missing return values (bool)
- No need for `forceApprove` in ValidatorBonding (no approvals set)

### ReentrancyGuard
- `import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";`
- Use standard `nonReentrant` modifier (NOT `ReentrancyGuardTransient` — matches Superform convention)
- Apply to: `bond()`, `bondFor()`, `addBond()`, `requestUnbond()`, `executeUnbond()`, `cancelUnbond()`, `slash()`
- Gas cost: ~2,100 per guarded call (cold SLOAD + SSTORE)

### Math
- `import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";`
- `Math.mulDiv(a, b, c)` = `a * b / c` overflow-safe
- `Math.mulDiv(a, b, c, Math.Rounding.Floor)` — explicit rounding
- Use for proportional slash: `Math.mulDiv(amount, bond.unbondingAmount, bond.amount)`

## Foundry Testing

### Test Structure
```solidity
import { Test } from "forge-std/Test.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";

contract ValidatorBondingTest is PeripheryHelpers {
    function setUp() public { ... }
    function test_FunctionName_Scenario() public { ... }
    function testFuzz_FunctionName(uint256 amount) public { ... }
}
```

### Useful Cheatcodes
- `vm.prank(addr)` / `vm.startPrank(addr)` — impersonate caller
- `vm.expectRevert(IContract.ERROR.selector)` — expect revert
- `vm.expectEmit(true, true, true, true)` — expect event
- `vm.warp(timestamp)` — set block.timestamp
- `vm.deal(addr, amount)` — set ETH balance
- `deal(token, addr, amount)` — set ERC20 balance
- `vm.store(addr, slot, value)` — write storage directly (for role granting)

### Fuzz Testing
- Foundry auto-generates inputs for `testFuzz_*` functions
- Use `vm.assume()` or `bound()` to constrain inputs
- `bound(x, min, max)` — constrain fuzz input to range
- Default runs: 256 (configurable in foundry.toml)
