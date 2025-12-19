// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ISuperVault } from "../interfaces/SuperVault/ISuperVault.sol";

/// @title SuperVaultBatchOperator
/// @author Superform Labs
/// @notice Batch operator for SuperVaults allowing batched withdrawals and redeems
/// @dev Users must approve this contract as an operator via vault.setOperator(address(this), true)
/// @dev Only addresses with WITHDRAWER_ROLE can call batch methods
contract SuperVaultBatchOperator is AccessControl {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a batch withdrawal is executed
    /// @param caller The address that executed the batch withdrawal
    /// @param requestCount The number of withdrawal requests processed
    event BatchWithdrawExecuted(address indexed caller, uint256 requestCount);

    /// @notice Emitted when a batch redemption is executed
    /// @param caller The address that executed the batch redemption
    /// @param requestCount The number of redemption requests processed
    event BatchRedeemExecuted(address indexed caller, uint256 requestCount);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error EMPTY_REQUESTS();
    error ZERO_VAULT_ADDRESS();
    error ZERO_RECEIVER_ADDRESS();
    error ZERO_CONTROLLER_ADDRESS();
    error ZERO_AMOUNT();

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/
    struct BatchRequest {
        address vault;
        address receiver; // address that receives the withdrawn assets
        address controller; // address that controls the shares (must have approved this operator)
        uint256 amount; // assets for withdraw, shares for redeem
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the batch operator with admin
    /// @param admin The address that will have DEFAULT_ADMIN_ROLE
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Batch withdraw assets from multiple vaults for multiple owners
    /// @param requests The array of batch withdrawal requests
    /// @dev Requires this contract to be approved as operator for each controller on each vault
    function batchWithdraw(BatchRequest[] calldata requests) external onlyRole(WITHDRAWER_ROLE) {
        _validateRequests(requests);

        for (uint256 i = 0; i < requests.length; ++i) {
            BatchRequest calldata req = requests[i];
            // Vault signature: withdraw(uint256 assets, address receiver, address controller)
            ISuperVault(req.vault).withdraw(req.amount, req.receiver, req.controller);
        }

        emit BatchWithdrawExecuted(msg.sender, requests.length);
    }

    /// @notice Batch redeem shares from multiple vaults for multiple owners
    /// @param requests The array of batch redemption requests
    /// @dev Requires this contract to be approved as operator for each controller on each vault
    function batchRedeem(BatchRequest[] calldata requests) external onlyRole(WITHDRAWER_ROLE) {
        _validateRequests(requests);

        for (uint256 i = 0; i < requests.length; ++i) {
            BatchRequest calldata req = requests[i];
            // Vault signature: redeem(uint256 shares, address receiver, address controller)
            ISuperVault(req.vault).redeem(req.amount, req.receiver, req.controller);
        }

        emit BatchRedeemExecuted(msg.sender, requests.length);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates batch requests
    /// @param requests The array of batch requests to validate
    function _validateRequests(BatchRequest[] calldata requests) internal pure {
        if (requests.length == 0) revert EMPTY_REQUESTS();

        for (uint256 i = 0; i < requests.length; ++i) {
            BatchRequest calldata req = requests[i];

            if (req.vault == address(0)) revert ZERO_VAULT_ADDRESS();
            if (req.receiver == address(0)) revert ZERO_RECEIVER_ADDRESS();
            if (req.controller == address(0)) revert ZERO_CONTROLLER_ADDRESS();
            if (req.amount == 0) revert ZERO_AMOUNT();
        }
    }
}
