// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ISuperVaultBatchOperator
/// @author Superform Labs
/// @notice Interface for SuperVaultBatchOperator - batch withdrawal/redeem operator for SuperVaults
interface ISuperVaultBatchOperator {
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
                                TYPES
    //////////////////////////////////////////////////////////////*/

    struct BatchRequest {
        address vault;
        address controller; // address that controls the shares and receives assets (must have approved this operator)
        uint256 amount; // assets for withdraw, shares for redeem
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Batch withdraw assets from multiple vaults for multiple owners
    /// @param requests The array of batch withdrawal requests
    /// @dev Requires this contract to be approved as operator for each controller on each vault
    /// @dev Individual request failures do not revert the batch - they are skipped
    function batchWithdraw(BatchRequest[] calldata requests) external;

    /// @notice Batch redeem shares from multiple vaults for multiple owners
    /// @param requests The array of batch redemption requests
    /// @dev Requires this contract to be approved as operator for each controller on each vault
    /// @dev Individual request failures do not revert the batch - they are skipped
    function batchRedeem(BatchRequest[] calldata requests) external;

    /// @notice Batch emergency withdraw tokens stuck in this contract
    /// @param tokens The array of token addresses to withdraw
    /// @param to The recipient address
    /// @dev Only callable by admin. Withdraws entire balance of each token.
    function batchEmergencyWithdraw(address[] calldata tokens, address to) external;
}
