// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IManagedSuperVaultController } from "../interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";

/// @title ManagedExecutionLib
/// @author Superform Labs
/// @notice Execution-policy engine for ManagedSuperVaultController, factored into an internal library to
///         keep the controller's execution logic isolated and readable.
/// @dev Functions are `internal`, so they inline into the controller (no separate deployment or linking).
///      Errors and the ManagedCallExecuted event are re-declared here with signatures identical to
///      IManagedSuperVaultController so selectors/topics match exactly. If the controller ever needs more
///      headroom under EIP-170, these can be switched to `public` to delegatecall out of its bytecode
///      (at the cost of deploy-time library linking).
library ManagedExecutionLib {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    // Sensitive value-moving selectors that require argument constraints (spec 6.5)
    bytes4 private constant SELECTOR_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SELECTOR_APPROVE = 0x095ea7b3; // approve(address,uint256)
    bytes4 private constant SELECTOR_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)
    bytes4 private constant SELECTOR_INCREASE_ALLOWANCE = 0x39509351; // increaseAllowance(address,uint256)
    bytes4 private constant SELECTOR_SET_APPROVAL_FOR_ALL = 0xa22cb465; // setApprovalForAll(address,bool)

    /*//////////////////////////////////////////////////////////////
                        ERRORS (selector-compatible)
    //////////////////////////////////////////////////////////////*/
    error ZERO_ADDRESS();
    error TARGET_FORBIDDEN();
    error CALL_NOT_ALLOWED();
    error VALUE_NOT_ALLOWED();
    error VALUE_EXCEEDS_CAP();
    error VALUE_EXCEEDS_WINDOW_CAP();
    error ARG_CONSTRAINT_VIOLATED();
    error ARG_CONSTRAINT_REQUIRED();
    error INVALID_CALL_RULE();
    error EXECUTION_FAILED(uint256 index, bytes returnData);

    /*//////////////////////////////////////////////////////////////
                        EVENT (topic-compatible)
    //////////////////////////////////////////////////////////////*/
    event ManagedCallExecuted(
        address indexed executor,
        address indexed target,
        bytes4 indexed selector,
        uint256 value,
        bytes32 operationId,
        bytes32 calldataHash
    );

    /// @notice System addresses a managed call may never target (passed by the controller)
    struct ForbiddenTargets {
        address vault;
        address controller;
        address escrow;
        address aggregator;
        address governor;
    }

    /*//////////////////////////////////////////////////////////////
                            POLICY VALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validate a (target, selector) call rule before it is stored (setCallRule)
    /// @dev Enforces explicit/consistent value config, a mandatory rolling-window cap for value-moving
    ///      rules (spec 6.9), and argument constraints for sensitive ERC-20/721 selectors (spec 6.5)
    function validateCallRule(IManagedSuperVaultController.CallRule calldata rule, bytes4 selector) internal pure {
        if (rule.allowed) {
            if (!rule.valueAllowed && (rule.maxValuePerCall != 0 || rule.windowValueCap != 0)) {
                revert INVALID_CALL_RULE();
            }
            if (rule.valueAllowed && rule.maxValuePerCall == 0) revert INVALID_CALL_RULE();
            // No per-call cap without a cumulative/windowed cap; a value-moving rule must always carry a
            // rolling-window cap (and non-zero duration) as the real backstop.
            if (rule.valueAllowed && (rule.windowValueCap == 0 || rule.windowDuration == 0)) {
                revert INVALID_CALL_RULE();
            }
            if (rule.windowValueCap != 0 && rule.windowValueCap < rule.maxValuePerCall) revert INVALID_CALL_RULE();

            (bool required, uint8 requiredArg) = _sensitiveArg(selector);
            if (required) {
                bool found;
                for (uint256 i; i < rule.constrainedArgs.length; ++i) {
                    if (rule.constrainedArgs[i] == requiredArg) {
                        found = true;
                        break;
                    }
                }
                if (!found) revert ARG_CONSTRAINT_REQUIRED();
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validate a single managed call against the onchain policy and execute it
    /// @dev Inlined into the controller, so the external call originates from the controller (operational
    ///      custody) and the event is emitted from the controller's address.
    function executeSingle(
        mapping(address => mapping(bytes4 => IManagedSuperVaultController.CallRule)) storage callRules,
        mapping(address => mapping(bytes4 => IManagedSuperVaultController.WindowUsage)) storage windowUsage,
        mapping(address => mapping(bytes4 => mapping(uint8 => mapping(address => bool)))) storage allowedArgValues,
        IManagedSuperVaultController.ManagedCall calldata call,
        ForbiddenTargets memory forbidden,
        bytes32 operationId,
        uint256 index
    )
        internal
    {
        if (call.target == address(0)) revert ZERO_ADDRESS();
        if (
            call.target == forbidden.vault || call.target == forbidden.controller || call.target == forbidden.escrow
                || call.target == forbidden.aggregator || call.target == forbidden.governor
        ) revert TARGET_FORBIDDEN();

        // Selector extraction: empty calldata is treated as selector 0 (plain native transfer);
        // malformed short calldata is never allowed
        bytes4 selector;
        uint256 dataLength = call.data.length;
        if (dataLength == 0) {
            selector = bytes4(0);
        } else if (dataLength < 4) {
            revert CALL_NOT_ALLOWED();
        } else {
            selector = bytes4(call.data[:4]);
        }

        IManagedSuperVaultController.CallRule storage rule = callRules[call.target][selector];
        if (!rule.allowed) revert CALL_NOT_ALLOWED();

        // Native value checks: per-call cap and rolling-window cumulative cap
        if (call.value > 0) {
            if (!rule.valueAllowed) revert VALUE_NOT_ALLOWED();
            if (call.value > rule.maxValuePerCall) revert VALUE_EXCEEDS_CAP();

            if (rule.windowValueCap != 0) {
                IManagedSuperVaultController.WindowUsage storage usage = windowUsage[call.target][selector];
                if (block.timestamp >= usage.windowStart + rule.windowDuration) {
                    usage.windowStart = uint64(block.timestamp);
                    usage.valueUsed = 0;
                }
                if (usage.valueUsed + call.value > rule.windowValueCap) revert VALUE_EXCEEDS_WINDOW_CAP();
                usage.valueUsed += call.value;
            }
        }

        // Argument constraints: constrained static words must decode to allowlisted addresses
        uint256 constrainedLen = rule.constrainedArgs.length;
        for (uint256 i; i < constrainedLen; ++i) {
            uint8 argIndex = rule.constrainedArgs[i];
            uint256 offset = 4 + uint256(argIndex) * 32;
            if (dataLength < offset + 32) revert ARG_CONSTRAINT_VIOLATED();

            bytes32 word = bytes32(call.data[offset:offset + 32]);
            // A properly ABI-encoded address arg has its upper 12 bytes zeroed
            if (uint256(word) > type(uint160).max) revert ARG_CONSTRAINT_VIOLATED();

            address argValue = address(uint160(uint256(word)));
            if (!allowedArgValues[call.target][selector][argIndex][argValue]) revert ARG_CONSTRAINT_VIOLATED();
        }

        (bool success, bytes memory returnData) = call.target.call{ value: call.value }(call.data);
        if (!success) revert EXECUTION_FAILED(index, returnData);

        emit ManagedCallExecuted(msg.sender, call.target, selector, call.value, operationId, keccak256(call.data));
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether a selector is a sensitive value-moving selector requiring argument constraints
    function _sensitiveArg(bytes4 selector) private pure returns (bool required, uint8 argIndex) {
        if (
            selector == SELECTOR_TRANSFER || selector == SELECTOR_APPROVE || selector == SELECTOR_INCREASE_ALLOWANCE
                || selector == SELECTOR_SET_APPROVAL_FOR_ALL
        ) {
            return (true, 0);
        }
        if (selector == SELECTOR_TRANSFER_FROM) {
            return (true, 1);
        }
        return (false, 0);
    }
}
