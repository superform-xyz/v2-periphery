// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Execution } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { BaseHook } from "@superform-v2-core/src/hooks/BaseHook.sol";
import { ISuperHook } from "@superform-v2-core/src/interfaces/ISuperHook.sol";

/// @notice Mock SuperHook implementation for testing
contract MockSuperHook is BaseHook {
    // Events for testing
    event PreExecuteCalled(address prevHook, address sender, bytes data);
    event PostExecuteCalled(address prevHook, address sender, bytes data);

    // Control parameters
    bool public shouldFailBuild;
    bool public shouldReturnEmptyExecutions;
    address public targetToReturn;
    bytes public callDataToReturn;

    constructor(address _targetToReturn) BaseHook(ISuperHook.HookType.NONACCOUNTING, keccak256("MockSuperHook")) {
        targetToReturn = _targetToReturn;
        callDataToReturn = abi.encodeWithSignature("execute()");
    }

    function setShouldFailBuild(bool _shouldFail) external {
        shouldFailBuild = _shouldFail;
    }

    function setShouldReturnEmptyExecutions(bool _shouldReturnEmpty) external {
        shouldReturnEmptyExecutions = _shouldReturnEmpty;
    }

    function setCallData(bytes calldata _callData) external {
        callDataToReturn = _callData;
    }

    /// @notice Override _buildHookExecutions to provide custom execution logic
    function _buildHookExecutions(address, address, bytes calldata)
        internal
        view
        override
        returns (Execution[] memory)
    {
        if (shouldFailBuild) {
            revert("MockSuperHook: build failed");
        }

        if (shouldReturnEmptyExecutions) {
            return new Execution[](0);
        }

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: targetToReturn, value: 0, callData: callDataToReturn });

        return executions;
    }

    /// @notice Override inspect to return the target address
    function inspect(bytes calldata) external view override returns (bytes memory) {
        return abi.encodePacked(targetToReturn);
    }

    /// @notice Override _preExecute
    function _preExecute(address prevHook, address sender, bytes calldata data) internal override {
        emit PreExecuteCalled(prevHook, sender, data);
        // Set output amount to 0 for non-accounting mock
        _setOutAmount(0, sender);
    }

    /// @notice Override _postExecute
    function _postExecute(address prevHook, address sender, bytes calldata data) internal override {
        emit PostExecuteCalled(prevHook, sender, data);
    }
}
