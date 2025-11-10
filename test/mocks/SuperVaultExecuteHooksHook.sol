// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { Execution } from "modulekit/accounts/erc7579/lib/ExecutionLib.sol";

// Superform
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { BaseHook } from "@superform-v2-core/src/hooks/BaseHook.sol";
import { HookSubTypes } from "@superform-v2-core/src/libraries/HookSubTypes.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

/// @title SuperVaultExecuteHooksHook
/// @author Superform Labs
/// @dev Hook that allows calling executeHooks on a SuperVaultStrategy through the hook system
/// @notice data has the following structure:
/// @notice         ISuperVaultStrategy.ExecuteArgs executeArgs (ABI encoded)
contract SuperVaultExecuteHooksHook is BaseHook {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable strategy;

    constructor(address _strategy) BaseHook(HookType.NONACCOUNTING, HookSubTypes.CLAIM) {
        if (_strategy == address(0)) revert ADDRESS_NOT_VALID();
        strategy = _strategy;
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseHook
    function _buildHookExecutions(
        address,
        address,
        bytes calldata data
    )
        internal
        view
        override
        returns (Execution[] memory executions)
    {
        // Decode the ExecuteArgs from the data
        ISuperVaultStrategy.ExecuteArgs memory executeArgs = abi.decode(data, (ISuperVaultStrategy.ExecuteArgs));

        executions = new Execution[](1);
        executions[0] = Execution({
            target: strategy, value: 0, callData: abi.encodeCall(ISuperVaultStrategy.executeHooks, (executeArgs))
        });
    }

    /// @inheritdoc ISuperHookInspector
    function inspect(bytes calldata data) external pure override returns (bytes memory addressData) {
        // Decode the ExecuteArgs to extract hook addresses for inspection
        ISuperVaultStrategy.ExecuteArgs memory executeArgs = abi.decode(data, (ISuperVaultStrategy.ExecuteArgs));

        uint256 length = executeArgs.hooks.length;
        for (uint256 i; i < length; i++) {
            addressData = bytes.concat(addressData, bytes20(executeArgs.hooks[i]));
        }

        return addressData;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    function _preExecute(address, address account, bytes calldata) internal override {
        _setOutAmount(0, account);
    }

    function _postExecute(address, address account, bytes calldata) internal override {
        _setOutAmount(0, account);
    }
}
