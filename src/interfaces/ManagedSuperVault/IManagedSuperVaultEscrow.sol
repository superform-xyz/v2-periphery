// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title IManagedSuperVaultEscrow
/// @notice Interface for the ManagedSuperVault escrow contract that holds shares during redeem request/claim
///         processing and underlying assets during pending deposit requests
/// @author Superform Labs
interface IManagedSuperVaultEscrow {
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
    /// @param controller The controller contract address
    event Initialized(address indexed vault, address indexed controller);

    /// @notice Emitted when shares are transferred to escrow during a redeem request
    /// @param from The address shares were transferred from
    /// @param amount The amount of shares escrowed
    event SharesEscrowed(address indexed from, uint256 amount);

    /// @notice Emitted when shares are returned from escrow during a redeem cancellation claim
    /// @param to The address shares were returned to
    /// @param amount The amount of shares returned
    event SharesReturned(address indexed to, uint256 amount);

    /// @notice Emitted when assets are returned from escrow during a redeem claim
    /// @param to The address assets were returned to
    /// @param amount The amount of assets returned
    event AssetsReturned(address indexed to, uint256 amount);

    /// @notice Emitted when pending deposit assets are refunded to a depositor (cancel or reject)
    /// @param to The address assets were refunded to
    /// @param amount The amount of assets refunded
    event DepositAssetsRefunded(address indexed to, uint256 amount);

    /// @notice Emitted when pending deposit assets are released to the controller on fulfillment
    /// @param to The address assets were released to
    /// @param amount The amount of assets released
    event DepositAssetsReleased(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the escrow with required parameters
    /// @param vaultAddress The vault contract address
    /// @param controllerAddress The controller contract address
    function initialize(address vaultAddress, address controllerAddress) external;

    /*//////////////////////////////////////////////////////////////
                            VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer shares from user to escrow during redeem request
    /// @param from The address to transfer shares from
    /// @param amount The amount of shares to transfer
    function escrowShares(address from, uint256 amount) external;

    /// @notice Return shares from escrow to user during redeem cancellation claim
    /// @param to The address to return shares to
    /// @param amount The amount of shares to return
    function returnShares(address to, uint256 amount) external;

    /// @notice Return assets from escrow to receiver during redeem claim
    /// @param to The address to return assets to
    /// @param amount The amount of assets to return
    function returnAssets(address to, uint256 amount) external;

    /// @notice Refund pending deposit assets to a depositor on cancellation (vault) or rejection (controller)
    /// @param to The address to refund assets to
    /// @param amount The amount of assets to refund
    function refundDepositAssets(address to, uint256 amount) external;

    /// @notice Release pending deposit assets to the controller on deposit fulfillment
    /// @param to The address to release assets to
    /// @param amount The amount of assets to release
    function releaseDepositAssets(address to, uint256 amount) external;
}
