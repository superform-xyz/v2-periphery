// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

/// @title ISuperVaultEscrow
/// @notice Interface for SuperVault escrow contract that holds shares during request/claim process
/// @author Superform Labs
interface ISuperVaultEscrow {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error ALREADY_INITIALIZED();
    error UNAUTHORIZED();
    error ZERO_ADDRESS();

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the escrow with required parameters
    /// @param vaultAddress The vault contract address
    /// @param strategyAddress The strategy contract address
    function initialize(address vaultAddress, address strategyAddress) external;

    /*//////////////////////////////////////////////////////////////
                            VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer shares from user to escrow during redeem request
    /// @param from The address to transfer shares from
    /// @param amount The amount of shares to transfer
    function escrowShares(address from, uint256 amount) external;

    /// @notice Return shares from escrow to user during redeem cancellation
    /// @param to The address to return shares to
    /// @param amount The amount of shares to return
    function returnShares(address to, uint256 amount) external;

    /// @notice Return assets from escrow to vault during deposit cancellation
    /// @param to The address to return assets to
    /// @param amount The amount of assets to return
    function returnAssets(address to, uint256 amount) external;
}
