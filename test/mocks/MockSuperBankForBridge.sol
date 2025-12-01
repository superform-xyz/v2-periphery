// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ISuperBank } from "../../src/interfaces/ISuperBank.sol";
import { IHookExecutionData } from "../../src/interfaces/IHookExecutionData.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {
    ISuperHook,
    ISuperHookResult,
    Execution
} from "@superform-v2-core/src/interfaces/ISuperHook.sol";

/// @title MockSuperBankForBridge
/// @notice Mock SuperBank that executes real hooks for bridge testing without validation
contract MockSuperBankForBridge is ISuperBank, ReentrancyGuard {
    error ZERO_LENGTH_ARRAY();
    error INVALID_ARRAY_LENGTH();
    error ZERO_ADDRESS();
    error HOOK_EXECUTION_FAILED();
    error MINIMUM_OUTPUT_AMOUNT_NOT_MET();

    event HooksExecuted(address[] hooks, bytes[] data);

    /// @notice Execute hooks using the same logic as Bank._executeHooks but without registration and validation
    function executeHooks(IHookExecutionData.HookExecutionData calldata executionData) external payable nonReentrant {
        uint256 hooksLength = executionData.hooks.length;
        if (hooksLength == 0) revert ZERO_LENGTH_ARRAY();

        // Validate arrays have matching lengths
        if (
            hooksLength != executionData.data.length || hooksLength != executionData.merkleProofs.length
                || hooksLength != executionData.expectedAssetsOrSharesOut.length
        ) {
            revert INVALID_ARRAY_LENGTH();
        }

        address prevHook;
        address hookAddress;
        bytes memory hookData;
        ISuperHook hook;
        Execution[] memory executions;
        Execution memory executionStep;
        bool success;
        uint256 expectedOutput;
        uint256 actualOutput;

        for (uint256 i; i < hooksLength; i++) {
            hookAddress = executionData.hooks[i];

            // Validate hook address is not zero
            if (hookAddress == address(0)) revert ZERO_ADDRESS();

            hookData = executionData.data[i];
            expectedOutput = executionData.expectedAssetsOrSharesOut[i];

            hook = ISuperHook(hookAddress);

            // Set execution context
            hook.setExecutionContext(address(this));

            // Build Execution Steps
            executions = hook.build(prevHook, address(this), hookData);

            uint256 len = executions.length;

            // Execute all steps
            for (uint256 j; j < len; ++j) {
                executionStep = executions[j];

                uint256 valueToSend = executionStep.value;
                address targetToCall = executionStep.target;
                bytes memory callData = executionStep.callData;

                // Execute the call using assembly like in Bank.sol
                assembly {
                    success := call(
                        gas(), // gas - forwards all remaining gas
                        targetToCall, // recipient
                        valueToSend, // ether value
                        add(callData, 0x20), // inloc
                        mload(callData), // inlen
                        0, // outloc
                        0 // outlen
                    )
                }

                if (!success) {
                    revert HOOK_EXECUTION_FAILED();
                }
            }

            // Validate output amount if expected output is greater than 0
            if (expectedOutput > 0) {
                // Query the hook for actual output amount
                actualOutput = ISuperHookResult(address(hook)).getOutAmount(address(this));

                // Validate actual output meets or exceeds expected output
                if (actualOutput < expectedOutput) {
                    revert MINIMUM_OUTPUT_AMOUNT_NOT_MET();
                }
            }

            // Reset execution state after each hook
            hook.resetExecutionState(address(this));

            prevHook = hookAddress;
        }

        emit HooksExecuted(executionData.hooks, executionData.data);
    }

    /// @notice Mock distribute function
    function distribute(uint256) external pure {
        // Do nothing - just for interface compliance
    }

    /// @notice Allow contract to receive ETH
    receive() external payable {}
}