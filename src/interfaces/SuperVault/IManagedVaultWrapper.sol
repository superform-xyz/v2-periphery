// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title IManagedVaultWrapper
/// @author Superform Labs
/// @notice Interface for the ManagedVaultWrapper ERC-7540 vault contract
interface IManagedVaultWrapper {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when an address argument is zero
    error ZERO_ADDRESS();
    /// @notice Thrown when an amount argument is zero
    error ZERO_AMOUNT();
    /// @notice Thrown when the vault is paused
    error PAUSED();
    /// @notice Thrown when the caller is not authorized
    error UNAUTHORIZED();
    /// @notice Thrown when arrays have mismatched lengths
    error ARRAY_LENGTH_MISMATCH();
    /// @notice Thrown when the PPS from the aggregator is stale
    error PPS_STALE();
    /// @notice Thrown when the controller is not the gated allowlist
    error NOT_ALLOWLISTED();
    /// @notice Thrown when there are no claimable shares for the controller
    error NO_CLAIMABLE_SHARES();
    /// @notice Thrown when there are no claimable assets for the controller
    error NO_CLAIMABLE_ASSETS();
    /// @notice Thrown when the controller has no pending deposit request
    error NO_PENDING_DEPOSIT();
    /// @notice Thrown when the controller has no pending redeem request
    error NO_PENDING_REDEEM();
    /// @notice Thrown when the operator is not authorized
    error INVALID_OPERATOR();
    /// @notice Thrown when the signature has expired
    error DEADLINE_PASSED();
    /// @notice Thrown when the signature is invalid
    error INVALID_SIGNATURE();
    /// @notice Thrown when a nonce has already been used
    error NONCE_USED();
    /// @notice Thrown when the assets provided are insufficient for the operation
    error INSUFFICIENT_ASSETS();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the vault is initialized
    event Initialized(address asset, address svVault, address svStrategy, address mainManager);
    /// @notice Emitted when the vault is paused or unpaused
    event PauseSet(bool paused);
    /// @notice Emitted when the allowlist is updated
    event AllowlistSet(address indexed investor, bool allowed);
    /// @notice Emitted when deposit requests are fulfilled
    event DepositRequestsFulfilled(uint256 count, uint256 totalSharesMinted);
    /// @notice Emitted when redeem requests are fulfilled
    event RedeemRequestsFulfilled(uint256 count, uint256 totalSharesBurned, uint256 totalAssetsOut);

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the underlying asset address
    function asset() external view returns (address);

    /// @notice Returns the SuperVault address (ERC4626 whose shares this wrapper holds)
    function svVault() external view returns (address);

    /// @notice Returns the SuperVaultStrategy address (registered in aggregator for PPS)
    function svStrategy() external view returns (address);

    /// @notice Returns the SuperVaultAggregator address
    function aggregator() external view returns (address);

    /// @notice Returns the main manager address
    function mainManager() external view returns (address);

    /// @notice Returns whether the vault is paused
    function isPaused() external view returns (bool);

    /// @notice Returns whether the vault is gated (allowlist required)
    function isGated() external view returns (bool);

    /// @notice Returns total assets under management (SV shares × PPS from aggregator)
    function totalAssets() external view returns (uint256);

    /// @notice Returns whether the PPS from the aggregator is stale
    function isPPSStale() external view returns (bool);

    /// @notice Returns whether an investor is on the allowlist
    function allowlist(address investor) external view returns (bool);

    /// @notice Returns pending deposit assets for a controller
    function pendingDepositRequest(uint256 requestId, address controller) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Initialize the wrapper (called by factory via proxy)
    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_,
        address svVault_,
        address svStrategy_,
        address mainManager_,
        bool isGated_,
        address aggregator_
    )
        external;

    /// @notice Manager fulfills pending deposit requests by minting wrapper shares
    /// @param controllers List of controller addresses to fulfill
    function fulfillDepositRequests(address[] calldata controllers) external;

    /// @notice Manager fulfills pending redeem requests
    /// @param controllers List of controller addresses to fulfill
    /// @param assetsOut Amount of assets to distribute to each controller
    function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata assetsOut) external;

    /// @notice ERC-7540: Claim fulfilled deposit shares
    /// @param controller The controller of the request
    /// @param receiver The address to receive the shares
    function claimDeposit(address controller, address receiver) external returns (uint256 shares);

    /// @notice ERC-7540: Claim fulfilled redeem assets
    /// @param controller The controller of the request
    /// @param receiver The address to receive the assets
    function claimRedeem(address controller, address receiver) external returns (uint256 assets);

    /// @notice Manager can update the allowlist (gated vaults only)
    /// @param investors List of investor addresses
    /// @param allowed List of allowed statuses
    function setAllowlist(address[] calldata investors, bool[] calldata allowed) external;

    /// @notice Guardian/governor can pause the vault
    function setPaused(bool paused) external;
}
