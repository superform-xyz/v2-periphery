# Repository Analysis: Bridge Hook Patterns in v2-core

## Directory Structure

```
src/hooks/bridges/
├── across/
│   ├── AcrossSendFundsAndExecuteOnDstHook.sol
│   └── ApproveAndAcrossSendFundsAndExecuteOnDstHook.sol
├── circle/
│   ├── CircleGatewayAddDelegateHook.sol
│   ├── CircleGatewayMinterHook.sol
│   ├── CircleGatewayRemoveDelegateHook.sol
│   └── CircleGatewayWalletHook.sol
└── debridge/
    ├── DeBridgeCancelOrderHook.sol
    └── DeBridgeSendOrderAndExecuteOnDstHook.sol

src/vendor/bridges/
├── across/   (IAcrossSpokePoolV3.sol, IAcrossV3Receiver.sol)
└── debridge/ (IDeBridgeGate.sol, IDlnSource.sol, IExternalCallExecutor.sol)

test/unit/hooks/bridges/
├── BridgeHooks.t.sol
└── CircleGatewayUnitTests.sol
```

Pattern: one subdirectory per bridge vendor.

## Key Conventions (from hooks-master.md)

1. **inspect() MUST return only addresses** - never amounts or booleans
2. **inspect() visibility**: `view` if accessing immutables, `pure` if only reading data
3. **All contract addresses must be immutable constructor parameters**
4. **NatSpec data layout** uses `@notice` tags with exact byte offsets
5. **License**: `Apache-2.0` for src, `MIT` for test files
6. **Pragma**: `pragma solidity 0.8.30;` (exact)

## Constructor Pattern

```solidity
constructor(address target_, address validator_) BaseHook(HookType.NONACCOUNTING, HookSubTypes.BRIDGE) {
    if (target_ == address(0) || validator_ == address(0)) revert ADDRESS_NOT_VALID();
    TARGET = target_;
    VALIDATOR = validator_;
}
```

## Approve Pattern (4 executions)

```
approve(spender, 0)      → reset
approve(spender, amount)  → set exact
bridge_call()             → execute
approve(spender, 0)      → cleanup
```

## usePrevHookAmount Pattern

- Implements `ISuperHookContextAware`
- `Math.mulDiv(outputAmount, outAmount, inputAmount)` for proportional scaling
- Named constant for bool position offset

## Data Encoding

- Fixed-offset style (Across): all at known byte positions
- Walking-offset style (DeBridge): `vars.offset` for variable-length fields
- BytesLib for decoding: `toUint256`, `toAddress`, `toUint32`, `slice`

## Test Patterns

- Inherit `Helpers` (not `BaseTest`)
- `MockSignatureStorage` inline in test file
- `makeAddr("name")` for mock addresses
- `vm.mockCall()` for external dependencies
- Naming: `test_<Hook>_Build`, `test_<Hook>_Inspector`, etc.
