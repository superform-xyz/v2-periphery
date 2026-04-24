# SpecFlow Analysis: Stargate V2 Bridge Hook

## User Flow Overview

### Flow 1 - StargateV2SendHook: Simple Bridge (pre-approved ERC20 or native ETH)

```
Bank._executeHooks()
  -> _isHookRegistered(hookAddress)
  -> _getMerkleRootForHook(hookAddress)
  -> _validateHookConfiguration(...)  [calls hook.inspect(data)]
  -> hook.setExecutionContext(bank)
  -> hook.build(prevHook, bank, data)
       -> _buildHookExecutions()
            -> decode: dstEid, to, amountLD, minAmountLD, nativeFee, lzTokenFee,
                       usePrevHookAmount, extraOptions, composeMsg, oftCmd
            -> if usePrevHookAmount: scale amountLD + minAmountLD from prevHook.getOutAmount()
            -> if composeMsg.length > 0: append sig from VALIDATOR transient storage
            -> build 1 Execution: IOFT.send(SendParam, MessagingFee, account)
               with value = data[0..31] (the uint256 value field)
       -> wrap in [preExecute, send(), postExecute]
  -> execute each step via low-level call
  -> check getOutAmount(bank) >= expectedAssetsOrSharesOut[i]
  -> hook.resetExecutionState(bank)
```

### Flow 2 - ApproveAndStargateV2SendHook: ERC20 with Approve Pattern

Same as Flow 1 except `_buildHookExecutions()` returns 4 executions:

```
[approve(OFT, 0), approve(OFT, amountLD), IOFT.send(...), approve(OFT, 0)]
```

Wrapped inside preExecute/postExecute giving 6 total steps.

### Flow 3 - usePrevHookAmount = true (chained hook)

Preceding hook sets outAmount in transient storage. This hook reads `prevHook.getOutAmount(account)`, scales `amountLD` and `minAmountLD` proportionally via `Math.mulDiv`, and uses the new amount.

### Flow 4 - Governance / Registration

```
GOVERNOR_ROLE: registerHook(hookAddress)
GOVERNOR_ROLE: proposeSuperBankHookMerkleRoot(hookAddress, root)
  [wait 7 days]
anyone:        executeSuperBankHookMerkleRootUpdate(hookAddress)
BANK_MANAGER_ROLE: SuperBank.executeHooks(HookExecutionData)
```

## Flow Permutations Matrix

| Dimension | Variant A | Variant B | Variant C |
|---|---|---|---|
| Contract | StargateV2SendHook | ApproveAndStargateV2SendHook | Either |
| Token type | Native ETH (value > 0) | Pre-approved ERC20 (value = 0) | LZ token fee (lzTokenFee > 0) |
| usePrevHookAmount | false (static amounts) | true (scaled from prev hook) | - |
| composeMsg present | No (empty, simple bridge) | Yes (with callback, sig injected) | - |
| Hook position | First hook (prevHook = address(0)) | Middle/last (prevHook set) | - |
| expectedAssetsOrSharesOut | 0 (skip check) | > 0 (slippage enforced) | - |
| Merkle tree | Single leaf (root == leaf, proof empty) | Multi-leaf (proof provided) | - |
| Fee payment | nativeFee only (lzTokenFee = 0) | lzTokenFee only (nativeFee = 0) | Both non-zero |

## Gap Analysis

### Critical Gaps

1. **inspect() return value**: Must return at least one address (Bank rejects empty). Technical spec resolves this: `abi.encodePacked(OFT_CONTRACT, BytesLib.toAddress(data, 48))` for StargateV2SendHook; add `IOFT(OFT_CONTRACT).token()` for ApproveAndStargateV2SendHook.

2. **LZ Token Fee Pre-Approval**: `_payLzToken()` calls `safeTransferFrom(msg.sender, endpoint, lzTokenFee)`. Smart account must pre-approve ZRO to OFT contract via separate hook in bundle. Design decision documented in spec.

3. **value field semantics**: Encodes total ETH to forward (nativeFee + bridgeAmount for native OFT, nativeFee only for ERC20 OFT). Bundler responsible for correct computation.

4. **composeMsg wire format**: Follows Across pattern - decode as `(bytes, bytes, address, address[], uint256[])`, append signature, re-encode.

### Important Gaps (Resolved by Technical Spec)

5. **Minimum data length**: `if (data.length < 197) revert DATA_NOT_VALID()` - matches Across pattern.

6. **usePrevHookAmount with zero prevHook**: No guard (matches Across), will revert via `HOOK_EXECUTION_FAILED`.

7. **minAmountLD scaling**: Uses `Math.mulDiv(minAmountLD, outAmount, amountLD)` matching Across.

8. **outAmount for downstream hooks**: Bridge hooks are terminal - no `_preExecute`/`_postExecute` override needed (matches Across/DeBridge).

9. **Zero-address constructor check**: Revert unconditionally for both `oft_` and `validator_` (matches Across).

10. **HookSubTypes**: Use `HookSubTypes.BRIDGE`.

11. **ISuperHookContextAware**: Both hooks implement it with `decodeUsePrevHookAmount()`.

### Nice-to-Have

12. **ApproveAndStargateV2SendHook value > 0**: No explicit revert. ERC20 OFTs accept `msg.value == nativeFee` which can be non-zero for native fee payment.
