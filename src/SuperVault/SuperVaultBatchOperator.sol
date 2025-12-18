// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { ISuperVault } from "../interfaces/SuperVault/ISuperVault.sol";

/// @title SuperVaultBatchOperator
/// @author Superform Labs
/// @notice Batch operator for SuperVaults allowing batched withdrawals and redeems
/// @dev Uses delegatecall to preserve msg.sender when calling vault functions
contract SuperVaultBatchOperator {
    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/
    struct BatchRequest {
        address vault;
        address owner;
        uint256 assets;
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Batch withdraw assets from a vault for multiple owners
    /// @param vaultRequests The array of batch withdrawal requests
    /// @dev Uses delegatecall to preserve msg.sender as the original operator
    function batchWithdraw(BatchRequest[] calldata vaultRequests) external {
        for (uint256 i = 0; i < vaultRequests.length; ++i) {
            BatchRequest calldata req = vaultRequests[i];
            _delegatecallWithdraw(req.vault, req.assets, req.owner, req.owner);
        }
    }

    /// @notice Batch redeem shares from a vault for multiple owners
    /// @param vaultRequests The array of batch redemption requests
    /// @dev Uses delegatecall to preserve msg.sender as the original operator
    function batchRedeem(BatchRequest[] calldata vaultRequests) external {
        for (uint256 i = 0; i < vaultRequests.length; ++i) {
            BatchRequest calldata req = vaultRequests[i];
            _delegatecallRedeem(req.vault, req.assets, req.owner, req.owner);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Perform delegatecall to withdraw function on vault
    /// @param vault The vault address to call
    /// @param assets The amount of assets to withdraw
    /// @param owner The owner address
    /// @param receiver The receiver address
    function _delegatecallWithdraw(address vault, uint256 assets, address owner, address receiver) internal {
        // Encode the withdraw function call
        bytes memory callData = abi.encodeWithSelector(ISuperVault.withdraw.selector, assets, owner, receiver);

        // Perform delegatecall to preserve msg.sender
        (bool success,) = vault.delegatecall(callData);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /// @notice Perform delegatecall to redeem function on vault
    /// @param vault The vault address to call
    /// @param assets The amount of assets to redeem
    /// @param owner The owner address
    /// @param receiver The receiver address
    function _delegatecallRedeem(address vault, uint256 assets, address owner, address receiver) internal {
        // Encode the redeem function call
        bytes memory callData = abi.encodeWithSelector(ISuperVault.redeem.selector, assets, owner, receiver);

        // Perform delegatecall to preserve msg.sender
        (bool success,) = vault.delegatecall(callData);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
