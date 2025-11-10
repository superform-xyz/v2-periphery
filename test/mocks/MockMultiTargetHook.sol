// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Execution } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { BaseHook } from "@superform-v2-core/src/hooks/BaseHook.sol";
import { ISuperHook } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Mock hook that calls multiple external targets in a single execution
/// @dev This demonstrates the fix for the Merkle proof reuse issue - previously, hooks
///      with multiple external targets would fail because one proof was reused for all targets.
///      With the new approach, we validate the hook configuration (hook + args) instead of
///      individual targets, allowing this pattern to work correctly.
contract MockMultiTargetHook is BaseHook {
    // Events for testing
    event PreExecuteCalled(address prevHook, address sender, bytes data);
    event PostExecuteCalled(address prevHook, address sender, bytes data);

    // Storage
    address public token;
    address public recipient1;
    address public recipient2;
    address public recipient3;
    uint256 public amount;

    /// @notice Constructor
    /// @param _token The ERC20 token to transfer
    /// @param _recipient1 First recipient address
    /// @param _recipient2 Second recipient address
    /// @param _recipient3 Third recipient address
    /// @param _amount Amount to transfer to each recipient
    constructor(
        address _token,
        address _recipient1,
        address _recipient2,
        address _recipient3,
        uint256 _amount
    )
        BaseHook(ISuperHook.HookType.NONACCOUNTING, keccak256("MockMultiTargetHook"))
    {
        token = _token;
        recipient1 = _recipient1;
        recipient2 = _recipient2;
        recipient3 = _recipient3;
        amount = _amount;
    }

    /// @notice Override _buildHookExecutions - builds array with 3 external targets
    /// @dev This is the critical test case: 3 different external targets in one hook
    ///      OLD SYSTEM: Would fail - tries to use one Merkle proof for 3 different targets
    ///      NEW SYSTEM: Works - validates hook configuration once, then executes all targets
    function _buildHookExecutions(address, address, bytes calldata)
        internal
        view
        override
        returns (Execution[] memory)
    {
        Execution[] memory executions = new Execution[](3);

        // 1. Transfer to recipient1 (EXTERNAL TARGET 1)
        executions[0] = Execution({
            target: token, value: 0, callData: abi.encodeWithSelector(IERC20.transfer.selector, recipient1, amount)
        });

        // 2. Transfer to recipient2 (EXTERNAL TARGET 2)
        executions[1] = Execution({
            target: token, value: 0, callData: abi.encodeWithSelector(IERC20.transfer.selector, recipient2, amount)
        });

        // 3. Transfer to recipient3 (EXTERNAL TARGET 3)
        executions[2] = Execution({
            target: token, value: 0, callData: abi.encodeWithSelector(IERC20.transfer.selector, recipient3, amount)
        });

        return executions;
    }

    /// @notice Override inspect to return all external target addresses
    /// @dev In the new system, this is used to create the Merkle leaf for validation.
    ///      The leaf will be: keccak256(bytes.concat(keccak256(abi.encode(hookAddress, encodedArgs))))
    ///      where encodedArgs = abi.encodePacked(token, recipient1, recipient2, recipient3)
    function inspect(bytes calldata) external view override returns (bytes memory) {
        // Return all addresses that this hook will interact with (excluding self)
        return abi.encodePacked(token, recipient1, recipient2, recipient3);
    }

    /// @notice Override _preExecute
    function _preExecute(address prevHook, address sender, bytes calldata data) internal override {
        emit PreExecuteCalled(prevHook, sender, data);
        _setOutAmount(0, sender);
    }

    /// @notice Override _postExecute
    function _postExecute(address prevHook, address sender, bytes calldata data) internal override {
        emit PostExecuteCalled(prevHook, sender, data);
    }
}
