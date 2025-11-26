// SPDX-License-Identifier: Apache-2.0
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
    error ZERO_AMOUNT();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when escrow is initialized
    /// @param vault The vault contract address
    event Initialized(address indexed vault);

    /// @notice Emitted when shares are transferred to escrow
    /// @param from The address shares were transferred from
    /// @param amount The amount of shares escrowed
    event SharesEscrowed(address indexed from, uint256 amount);

    /// @notice Emitted when shares are returned from escrow
    /// @param to The address shares were returned to
    /// @param amount The amount of shares returned
    event SharesReturned(address indexed to, uint256 amount);

    /// @notice Emitted when assets are returned from escrow
    /// @param to The address assets were returned to
    /// @param amount The amount of assets returned
    event AssetsReturned(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the escrow with required parameters
    /// @param vaultAddress The vault contract address
    function initialize(address vaultAddress) external;

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
