// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { Execution } from "modulekit/accounts/erc7579/lib/ExecutionLib.sol";

// Superform
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { BaseHook } from "@superform-v2-core/src/hooks/BaseHook.sol";
import { HookSubTypes } from "@superform-v2-core/src/libraries/HookSubTypes.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

/// @title SuperVaultManageYieldSourceHook
/// @author Superform Labs
/// @dev Hook that allows calling manageYieldSources on a SuperVaultStrategy through the hook system
/// @notice data has the following structure:
/// @notice         ManageYieldSourcesArgs args (ABI encoded)
contract SuperVaultManageYieldSourceHook is BaseHook {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable strategy;

    struct ManageYieldSourcesArgs {
        address[] sources;
        address[] oracles;
        uint8[] actionTypes;
    }

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
        // Decode the ManageYieldSourcesArgs from the data
        ManageYieldSourcesArgs memory args = abi.decode(data, (ManageYieldSourcesArgs));

        executions = new Execution[](1);
        executions[0] = Execution({
            target: strategy,
            value: 0,
            callData: abi.encodeCall(
                ISuperVaultStrategy.manageYieldSources, (args.sources, args.oracles, args.actionTypes)
            )
        });
    }

    /// @inheritdoc ISuperHookInspector
    function inspect(bytes calldata data) external pure override returns (bytes memory addressData) {
        // Decode the ManageYieldSourcesArgs to extract yield source addresses for inspection
        ManageYieldSourcesArgs memory args = abi.decode(data, (ManageYieldSourcesArgs));

        for (uint256 i = 0; i < args.sources.length; i++) {
            addressData = bytes.concat(addressData, bytes20(args.sources[i]));
            addressData = bytes.concat(addressData, bytes20(args.oracles[i]));
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
