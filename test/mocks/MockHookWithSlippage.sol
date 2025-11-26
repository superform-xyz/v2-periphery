// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Execution } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { BaseHook } from "@superform-v2-core/src/hooks/BaseHook.sol";
import { ISuperHook } from "@superform-v2-core/src/interfaces/ISuperHook.sol";

/// @notice Mock hook that extends BaseHook for slippage testing
contract MockHookWithSlippage is BaseHook {
    address public targetToReturn;
    uint256 public outputAmount;

    constructor(
        address _target,
        uint256 _outputAmount
    )
        BaseHook(ISuperHook.HookType.NONACCOUNTING, keccak256("MockHookWithSlippage"))
    {
        targetToReturn = _target;
        outputAmount = _outputAmount;
    }

    function setOutputAmount(uint256 _amount) external {
        outputAmount = _amount;
    }

    /// @notice Override _buildHookExecutions to provide custom execution logic
    function _buildHookExecutions(address, address, bytes calldata)
        internal
        view
        override
        returns (Execution[] memory)
    {
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: targetToReturn, value: 0, callData: abi.encodeWithSignature("execute()") });
        return executions;
    }

    /// @notice Override inspect to return the target address
    function inspect(bytes calldata) external view override returns (bytes memory) {
        return abi.encodePacked(targetToReturn);
    }

    /// @notice Override _preExecute to set the output amount
    function _preExecute(address, address account, bytes calldata) internal override {
        // Set the output amount in transient storage using the internal setter
        _setOutAmount(outputAmount, account);
    }

    /// @notice Override _postExecute (required by BaseHook)
    function _postExecute(address, address, bytes calldata) internal override {
        // No post-execution logic needed for this mock
    }
}
