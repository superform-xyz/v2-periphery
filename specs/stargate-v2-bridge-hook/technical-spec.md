# Stargate V2 Bridge Hook - Technical Specification

## Overview

Create two bridge hooks for SuperBank in v2-core that bridge tokens cross-chain using LayerZero's OFT (Omnichain Fungible Token) standard. This enables bridging on chains where Across and DeBridge are unavailable (notably Flare).

The hooks call `IOFT.send()` on a target OFT/OFTAdapter contract. Both support native ETH and LZ token fee payment modes.

## Problem Statement / Motivation

Superform needs cross-chain bridging on Flare (chain 14) where Across and DeBridge are not available. Stargate V2 / LayerZero OFT is available on Flare. A bridge hook following existing patterns (Across, DeBridge) is needed.

## Proposed Solution

Two contracts in `src/hooks/bridges/stargate/`:

1. **StargateV2SendHook** - Calls `IOFT.send()` directly. For native ETH bridging or pre-approved ERC20 tokens.
2. **ApproveAndStargateV2SendHook** - ERC20-only. Adds the approve(0)->approve(amount)->send->approve(0) pattern.

A minimal vendor interface `IOFT.sol` in `src/vendor/bridges/stargate/`.

## Technical Approach

### Architecture

Both hooks follow the identical pattern to `AcrossSendFundsAndExecuteOnDstHook` / `ApproveAndAcrossSendFundsAndExecuteOnDstHook`:

- Inherit `BaseHook`, implement `ISuperHookContextAware`
- `HookType.NONACCOUNTING`, `HookSubTypes.BRIDGE`
- Immutables: `OFT` (public) and `VALIDATOR` (private)
- Tightly packed hook data decoded via `BytesLib`
- `inspect()` returns only packed addresses
- `usePrevHookAmount` support via `Math.mulDiv` proportional scaling
- Signature injection for destination message via `ISuperSignatureStorage`

### Vendor Interface

**File:** `src/vendor/bridges/stargate/IOFT.sol`

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

struct SendParam {
    uint32 dstEid;
    bytes32 to;
    uint256 amountLD;
    uint256 minAmountLD;
    bytes extraOptions;
    bytes composeMsg;
    bytes oftCmd;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct OFTReceipt {
    uint256 amountSentLD;
    uint256 amountReceivedLD;
}

interface IOFT {
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory, OFTReceipt memory);

    function token() external view returns (address);
    function approvalRequired() external view returns (bool);
}
```

### Hook Data Layout (StargateV2SendHook)

Tightly packed bytes, fixed-offset style:

```
offset   0  → uint256  value              (ETH to send: nativeFee + bridgeAmount for native OFT)
offset  32  → uint32   dstEid             (LayerZero destination endpoint ID)
offset  36  → bytes32  to                 (destination recipient, bytes32-padded)
offset  68  → uint256  amountLD           (amount in local decimals)
offset 100  → uint256  minAmountLD        (minimum amount, slippage protection)
offset 132  → uint256  nativeFee          (pre-quoted native fee from quoteSend)
offset 164  → uint256  lzTokenFee         (pre-quoted LZ token fee, 0 if paying native)
offset 196  → bool     usePrevHookAmount  (use output from previous hook)
offset 197  → uint256  extraOptionsLength (length of extraOptions bytes)
offset 229  → bytes    extraOptions       (LZ executor options, variable length)
         …  → uint256  composeMsgLength   (length of composeMsg bytes)
         …  → bytes    composeMsg         (composed message, variable length)
         …  → uint256  oftCmdLength       (length of oftCmd bytes)
         …  → bytes    oftCmd             (OFT command, variable length)
```

Minimum data length: 197 bytes (with all variable-length fields empty).

### StargateV2SendHook Implementation

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { Execution } from "modulekit/accounts/erc7579/lib/ExecutionLib.sol";
import { BytesLib } from "../../../vendor/BytesLib.sol";
import { IOFT, SendParam, MessagingFee } from "../../../vendor/bridges/stargate/IOFT.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

// Superform
import { BaseHook } from "../../BaseHook.sol";
import { HookSubTypes } from "../../../libraries/HookSubTypes.sol";
import { ISuperSignatureStorage } from "../../../interfaces/ISuperSignatureStorage.sol";
import { ISuperHookResult, ISuperHookContextAware, ISuperHookInspector } from "../../../interfaces/ISuperHook.sol";

/// @title StargateV2SendHook
/// @author Superform Labs
/// @dev Bridges tokens cross-chain via LayerZero OFT send()
/// @dev amountLD and minAmountLD have to be predicted by the SuperBundler
/// @dev nativeFee and lzTokenFee must be pre-quoted via quoteSend()
/// @dev `composeMsg` field won't contain the signature for the destination executor
/// @dev      signature is retrieved from the validator contract transient storage
/// @dev data has the following structure
/// @notice         uint256 value = BytesLib.toUint256(data, 0);
/// @notice         uint32 dstEid = BytesLib.toUint32(data, 32);
/// @notice         bytes32 to = BytesLib.toBytes32(data, 36);
/// @notice         uint256 amountLD = BytesLib.toUint256(data, 68);
/// @notice         uint256 minAmountLD = BytesLib.toUint256(data, 100);
/// @notice         uint256 nativeFee = BytesLib.toUint256(data, 132);
/// @notice         uint256 lzTokenFee = BytesLib.toUint256(data, 164);
/// @notice         bool usePrevHookAmount = _decodeBool(data, 196);
/// @notice         bytes extraOptions = [variable, starting at 197]
/// @notice         bytes composeMsg = [variable, after extraOptions]
/// @notice         bytes oftCmd = [variable, after composeMsg]
contract StargateV2SendHook is BaseHook, ISuperHookContextAware {
    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    address public immutable OFT_CONTRACT;
    address private immutable VALIDATOR;
    uint256 private constant USE_PREV_HOOK_AMOUNT_POSITION = 196;
    uint256 private constant MIN_DATA_LENGTH = 197;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error DATA_NOT_VALID();

    constructor(address oft_, address validator_) BaseHook(HookType.NONACCOUNTING, HookSubTypes.BRIDGE) {
        if (oft_ == address(0) || validator_ == address(0)) revert ADDRESS_NOT_VALID();
        OFT_CONTRACT = oft_;
        VALIDATOR = validator_;
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseHook
    function _buildHookExecutions(
        address prevHook,
        address account,
        bytes calldata data
    )
        internal
        view
        override
        returns (Execution[] memory executions)
    {
        if (data.length < MIN_DATA_LENGTH) revert DATA_NOT_VALID();

        // Decode fixed fields
        uint256 value = BytesLib.toUint256(data, 0);
        uint32 dstEid = BytesLib.toUint32(data, 32);
        bytes32 to = BytesLib.toBytes32(data, 36);
        uint256 amountLD = BytesLib.toUint256(data, 68);
        uint256 minAmountLD = BytesLib.toUint256(data, 100);
        uint256 nativeFee = BytesLib.toUint256(data, 132);
        uint256 lzTokenFee = BytesLib.toUint256(data, 164);
        bool usePrevHookAmount = _decodeBool(data, USE_PREV_HOOK_AMOUNT_POSITION);

        // Decode variable-length fields
        uint256 offset = MIN_DATA_LENGTH;
        (bytes memory extraOptions, uint256 newOffset) = _decodeBytes(data, offset);
        offset = newOffset;
        (bytes memory composeMsg, uint256 newOffset2) = _decodeBytes(data, offset);
        offset = newOffset2;
        (bytes memory oftCmd,) = _decodeBytes(data, offset);

        // Handle usePrevHookAmount
        if (usePrevHookAmount) {
            uint256 outAmount = ISuperHookResult(prevHook).getOutAmount(account);

            if (amountLD > 0 && minAmountLD > 0) {
                minAmountLD = Math.mulDiv(minAmountLD, outAmount, amountLD);
            }

            amountLD = outAmount;
        }

        if (amountLD == 0) revert AMOUNT_NOT_VALID();
        if (to == bytes32(0)) revert ADDRESS_NOT_VALID();

        // Append signature to composeMsg if present
        if (composeMsg.length > 0) {
            bytes memory signature = ISuperSignatureStorage(VALIDATOR).retrieveSignatureData(account);
            (
                bytes memory initData,
                bytes memory executorCalldata,
                address _account,
                address[] memory dstTokens,
                uint256[] memory intentAmounts
            ) = abi.decode(composeMsg, (bytes, bytes, address, address[], uint256[]));
            composeMsg = abi.encode(initData, executorCalldata, _account, dstTokens, intentAmounts, signature);
        }

        // Build SendParam
        SendParam memory sendParam = SendParam({
            dstEid: dstEid,
            to: to,
            amountLD: amountLD,
            minAmountLD: minAmountLD,
            extraOptions: extraOptions,
            composeMsg: composeMsg,
            oftCmd: oftCmd
        });

        MessagingFee memory fee = MessagingFee({ nativeFee: nativeFee, lzTokenFee: lzTokenFee });

        // Build execution
        executions = new Execution[](1);
        executions[0] = Execution({
            target: OFT_CONTRACT,
            value: value,
            callData: abi.encodeCall(IOFT.send, (sendParam, fee, account))
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperHookContextAware
    function decodeUsePrevHookAmount(bytes memory data) external pure returns (bool) {
        return _decodeBool(data, USE_PREV_HOOK_AMOUNT_POSITION);
    }

    /// @inheritdoc ISuperHookInspector
    function inspect(bytes calldata data) external view override returns (bytes memory) {
        return abi.encodePacked(
            OFT_CONTRACT,
            BytesLib.toAddress(data, 48)  // recipient address from bytes32 'to' (last 20 bytes)
        );
    }

    /*//////////////////////////////////////////////////////////////
                                 PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    /// @dev Decodes a length-prefixed bytes field from calldata
    function _decodeBytes(
        bytes calldata data,
        uint256 offset
    )
        private
        pure
        returns (bytes memory result, uint256 newOffset)
    {
        uint256 len = BytesLib.toUint256(data, offset);
        offset += 32;
        if (len > 0) {
            result = BytesLib.slice(data, offset, len);
        } else {
            result = "";
        }
        newOffset = offset + len;
    }
}
```

### ApproveAndStargateV2SendHook Implementation

Same data layout and decoding. Differences:

```solidity
/// @title ApproveAndStargateV2SendHook
/// @author Superform Labs
/// @dev ERC20-only version with approval pattern: approve(0)->approve(amount)->send->approve(0)
/// @dev For native token transfers, use StargateV2SendHook instead

// _buildHookExecutions returns 4 executions:
executions = new Execution[](4);

address inputToken = IOFT(OFT_CONTRACT).token();

// Execution 0: Reset approval to 0
executions[0] = Execution({
    target: inputToken,
    value: 0,
    callData: abi.encodeCall(IERC20.approve, (OFT_CONTRACT, 0))
});

// Execution 1: Approve exact amount
executions[1] = Execution({
    target: inputToken,
    value: 0,
    callData: abi.encodeCall(IERC20.approve, (OFT_CONTRACT, amountLD))
});

// Execution 2: Bridge call
executions[2] = Execution({
    target: OFT_CONTRACT,
    value: value,
    callData: abi.encodeCall(IOFT.send, (sendParam, fee, account))
});

// Execution 3: Cleanup approval to 0
executions[3] = Execution({
    target: inputToken,
    value: 0,
    callData: abi.encodeCall(IERC20.approve, (OFT_CONTRACT, 0))
});
```

Key difference: `inspect()` also includes the token address:

```solidity
function inspect(bytes calldata data) external view override returns (bytes memory) {
    return abi.encodePacked(
        OFT_CONTRACT,
        IOFT(OFT_CONTRACT).token(),
        BytesLib.toAddress(data, 48)  // recipient
    );
}
```

Note: `inspect()` uses `view` (not `pure`) because it reads `OFT_CONTRACT` immutable and calls `IOFT.token()`.

### LZ Token Fee Path

When `lzTokenFee > 0` (user chose to pay in ZRO):
- The smart account must already hold ZRO tokens
- ZRO approval to the OFT contract is needed
- The OFT internally calls `_payLzToken()` which does `safeTransferFrom(msg.sender, endpoint, lzTokenFee)`
- For ApproveAndStargateV2SendHook: additional approve executions for ZRO token would be needed

**Design decision:** The LZ token fee path does NOT add extra approve executions for ZRO. The smart account must pre-approve ZRO to the OFT contract via a separate hook execution in the bundle. This keeps the hook simpler and follows the same pattern as the Across hook (which doesn't handle relayer token approvals internally).

## Attack Surface Analysis

### Token Approval
- [x] approve(0) before approve(amount) pattern (USDT compatibility)
- [x] Cleanup approve(0) after send
- [x] Approval amount uses pre-dust-removal `amountLD`

### msg.value Handling
- [x] `value` field in data separates fee from bridge amount
- [x] refundAddress = account (excess ETH returned to smart account)
- [x] LZ endpoint validates `msg.value == nativeFee` internally

### Cross-Chain
- [x] composeMsg signature injection follows existing pattern
- [x] Empty composeMsg for simple bridge (no callback risk)
- [x] dstEid is LZ endpoint ID (uint32), not chainId

### Access Control
- [x] OFT address is immutable constructor parameter
- [x] VALIDATOR address is immutable constructor parameter
- [x] Hook registered via SuperGovernor merkle tree

### Dust/Rounding
- [x] minAmountLD scaled proportionally with usePrevHookAmount
- [x] Bundler responsible for dust-aware minAmountLD calculation

## Acceptance Criteria

### Functional Requirements
- [ ] StargateV2SendHook calls `IOFT.send()` with correct parameters
- [ ] ApproveAndStargateV2SendHook adds 4-execution approve pattern
- [ ] Both support native ETH fee payment (`lzTokenFee = 0`)
- [ ] Both support LZ token fee payment (`lzTokenFee > 0`)
- [ ] usePrevHookAmount correctly scales amountLD and minAmountLD
- [ ] composeMsg signature injection works (matches Across pattern)
- [ ] inspect() returns only addresses (OFT address + recipient)
- [ ] Constructor validates zero addresses

### Non-Functional Requirements
- [ ] ~200 LOC per hook
- [ ] Follows all v2-core conventions (license, pragma, imports, NatSpec)
- [ ] Unit tests with full coverage
- [ ] Integration tests on mainnet fork

## File Structure

```
src/hooks/bridges/stargate/
├── StargateV2SendHook.sol
└── ApproveAndStargateV2SendHook.sol

src/vendor/bridges/stargate/
└── IOFT.sol

test/unit/hooks/bridges/
└── StargateHooks.t.sol
```

## References

- `src/hooks/bridges/across/AcrossSendFundsAndExecuteOnDstHook.sol` - Primary pattern reference
- `src/hooks/bridges/across/ApproveAndAcrossSendFundsAndExecuteOnDstHook.sol` - Approve pattern reference
- `lib/devtools/packages/oft-evm/contracts/interfaces/IOFT.sol` - Canonical IOFT interface
- `lib/devtools/packages/oft-evm/contracts/OFTCore.sol` - OFT send() implementation
- `.claude/agents/hooks-master.md` - Hook building conventions
