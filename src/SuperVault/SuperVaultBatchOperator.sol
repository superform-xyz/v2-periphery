// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { ISuperVault } from "../interfaces/SuperVault/ISuperVault.sol";

/// @title SuperVaultBatchOperator
/// @author Superform Labs
/// @notice Batch operator for SuperVaults allowing batched withdrawals and redeems
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
    function batchWithdraw(BatchRequest[] calldata vaultRequests) external {
        for (uint256 i = 0; i < vaultRequests.length; ++i) {
            BatchRequest calldata req = vaultRequests[i];
            ISuperVault(req.vault).withdraw(req.assets, req.owner, req.owner);
        }
    }

    /// @notice Batch redeem shares from a vault for multiple owners
    /// @param vaultRequests The array of batch redemption requests
    function batchRedeem(BatchRequest[] calldata vaultRequests) external {
        for (uint256 i = 0; i < vaultRequests.length; ++i) {
            BatchRequest calldata req = vaultRequests[i];
            ISuperVault(req.vault).redeem(req.assets, req.owner, req.owner);
        }
    }
}
