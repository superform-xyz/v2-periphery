// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISuperVault } from "../interfaces/SuperVault/ISuperVault.sol";

/// @title SuperVaultBatchOperator
/// @author Superform Labs
/// @notice Batch operator for SuperVaults allowing batched withdrawals and redeems
/// @dev Users must approve this contract as an operator via vault.setOperator(address(this), true)
/// @dev Only addresses with OPERATOR_ROLE can call batch methods
contract SuperVaultBatchOperator is AccessControl {
    using SafeERC20 for IERC20;

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

    /// @notice Emitted when a withdrawal request is skipped due to invalid parameters
    /// @param index The index of the skipped request in the batch
    /// @param vault The vault address
    /// @param controller The controller address
    /// @param amount The requested amount
    event WithdrawRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount);

    /// @notice Emitted when a withdrawal request fails during execution
    /// @param index The index of the failed request in the batch
    /// @param vault The vault address
    /// @param controller The controller address
    /// @param amount The requested amount
    event WithdrawFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount);

    /// @notice Emitted when a redemption request is skipped due to invalid parameters
    /// @param index The index of the skipped request in the batch
    /// @param vault The vault address
    /// @param controller The controller address
    /// @param amount The requested amount
    event RedeemRequestSkipped(uint256 indexed index, address indexed vault, address controller, uint256 amount);

    /// @notice Emitted when a redemption request fails during execution
    /// @param index The index of the failed request in the batch
    /// @param vault The vault address
    /// @param controller The controller address
    /// @param amount The requested amount
    event RedeemFailed(uint256 indexed index, address indexed vault, address controller, uint256 amount);

    /// @notice Emitted when tokens are rescued via batch emergency withdraw
    /// @param tokens The token addresses that were withdrawn
    /// @param to The recipient address
    /// @param amounts The amounts of tokens withdrawn
    event BatchEmergencyWithdraw(address[] tokens, address indexed to, uint256[] amounts);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error EMPTY_REQUESTS();
    error ZERO_ADMIN_ADDRESS();
    error ZERO_OPERATOR_ADDRESS();
    error ZERO_TOKEN_ADDRESS();
    error ZERO_TO_ADDRESS();

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/
    struct BatchRequest {
        address vault;
        address controller; // address that controls the shares and receives assets (must have approved this operator)
        uint256 amount; // assets for withdraw, shares for redeem
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the batch operator with admin and operator
    /// @param admin The address that will have DEFAULT_ADMIN_ROLE
    /// @param operator The address that will have OPERATOR_ROLE
    constructor(address admin, address operator) {
        if (admin == address(0)) revert ZERO_ADMIN_ADDRESS();
        if (operator == address(0)) revert ZERO_OPERATOR_ADDRESS();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, operator);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Batch withdraw assets from multiple vaults for multiple owners
    /// @param requests The array of batch withdrawal requests
    /// @dev Requires this contract to be approved as operator for each controller on each vault
    /// @dev Individual request failures do not revert the batch - they are skipped
    function batchWithdraw(BatchRequest[] calldata requests) external onlyRole(OPERATOR_ROLE) {
        if (requests.length == 0) revert EMPTY_REQUESTS();

        uint256 successCount;
        for (uint256 i = 0; i < requests.length; ++i) {
            BatchRequest calldata req = requests[i];

            // Skip invalid requests without reverting the batch
            if (!_isValidRequest(req)) {
                emit WithdrawRequestSkipped(i, req.vault, req.controller, req.amount);
                continue;
            }

            // receiver == controller is enforced on the vault side
            try ISuperVault(req.vault).withdraw(req.amount, req.controller, req.controller) {
                ++successCount;
            } catch {
                emit WithdrawFailed(i, req.vault, req.controller, req.amount);
            }
        }

        emit BatchWithdrawExecuted(msg.sender, successCount);
    }

    /// @notice Batch redeem shares from multiple vaults for multiple owners
    /// @param requests The array of batch redemption requests
    /// @dev Requires this contract to be approved as operator for each controller on each vault
    /// @dev Individual request failures do not revert the batch - they are skipped
    function batchRedeem(BatchRequest[] calldata requests) external onlyRole(OPERATOR_ROLE) {
        if (requests.length == 0) revert EMPTY_REQUESTS();

        uint256 successCount;
        for (uint256 i = 0; i < requests.length; ++i) {
            BatchRequest calldata req = requests[i];

            // Skip invalid requests without reverting the batch
            if (!_isValidRequest(req)) {
                emit RedeemRequestSkipped(i, req.vault, req.controller, req.amount);
                continue;
            }

            // receiver == controller is enforced on the vault side
            try ISuperVault(req.vault).redeem(req.amount, req.controller, req.controller) {
                ++successCount;
            } catch {
                emit RedeemFailed(i, req.vault, req.controller, req.amount);
            }
        }

        emit BatchRedeemExecuted(msg.sender, successCount);
    }

    /// @notice Batch emergency withdraw tokens stuck in this contract
    /// @param tokens The array of token addresses to withdraw
    /// @param to The recipient address
    /// @dev Only callable by admin. Withdraws entire balance of each token.
    function batchEmergencyWithdraw(address[] calldata tokens, address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) revert ZERO_TO_ADDRESS();

        uint256[] memory amounts = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            if (token == address(0)) revert ZERO_TOKEN_ADDRESS();
            uint256 balance = IERC20(token).balanceOf(address(this));
            amounts[i] = balance;
            if (balance > 0) {
                IERC20(token).safeTransfer(to, balance);
            }
        }

        emit BatchEmergencyWithdraw(tokens, to, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if a batch request is valid
    /// @param req The batch request to validate
    /// @return isValid True if the request has valid parameters
    function _isValidRequest(BatchRequest calldata req) internal pure returns (bool isValid) {
        return req.vault != address(0) && req.controller != address(0) && req.amount != 0;
    }
}
