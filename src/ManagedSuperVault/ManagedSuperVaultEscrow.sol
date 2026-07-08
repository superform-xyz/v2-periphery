// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IManagedSuperVaultEscrow } from "../interfaces/ManagedSuperVault/IManagedSuperVaultEscrow.sol";

/// @title ManagedSuperVaultEscrow
/// @author Superform Labs
/// @notice Escrow contract for Managed Vaults. Holds shares during redeem request/claim processing,
///         underlying assets during pending deposit requests, and fulfilled redemption assets until claimed.
/// @dev Share operations are vault-only. Deposit refunds (user cancel / manager reject) are callable by the
///      vault or controller; deposit release (fulfillment) is controller-only. Fund-moving functions carry a
///      nonReentrant guard as defense-in-depth on top of the vault/controller callers already being guarded.
///      The non-upgradeable ReentrancyGuard is clone-safe: the default zero _status reads as not-entered.
contract ManagedSuperVaultEscrow is IManagedSuperVaultEscrow, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    bool public initialized;
    address public vault;
    address public controller;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyVault() {
        _onlyVault();
        _;
    }

    modifier onlyController() {
        if (msg.sender != controller) revert UNAUTHORIZED();
        _;
    }

    modifier onlyVaultOrController() {
        _onlyVaultOrController();
        _;
    }

    function _onlyVault() internal view {
        if (msg.sender != vault) revert UNAUTHORIZED();
    }

    function _onlyVaultOrController() internal view {
        if (msg.sender != vault && msg.sender != controller) revert UNAUTHORIZED();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultEscrow
    function initialize(address vaultAddress, address controllerAddress) external {
        if (initialized) revert ALREADY_INITIALIZED();
        if (vaultAddress == address(0) || controllerAddress == address(0)) revert ZERO_ADDRESS();

        initialized = true;
        vault = vaultAddress;
        controller = controllerAddress;

        emit Initialized(vaultAddress, controllerAddress);
    }

    /*//////////////////////////////////////////////////////////////
                            SHARE FUNCTIONS (VAULT)
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultEscrow
    function escrowShares(address from, uint256 amount) external onlyVault nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();
        IERC20(vault).safeTransferFrom(from, address(this), amount);
        emit SharesEscrowed(from, amount);
    }

    /// @inheritdoc IManagedSuperVaultEscrow
    function returnShares(address to, uint256 amount) external onlyVault nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();
        IERC20(vault).safeTransfer(to, amount);
        emit SharesReturned(to, amount);
    }

    /// @inheritdoc IManagedSuperVaultEscrow
    function returnAssets(address to, uint256 amount) external onlyVault nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();
        if (to == address(0)) revert ZERO_ADDRESS();
        IERC20(IERC4626(vault).asset()).safeTransfer(to, amount);
        emit AssetsReturned(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT ASSET FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultEscrow
    /// @dev Refund path: user cancel (vault) or manager reject (controller)
    function refundDepositAssets(address to, uint256 amount) external onlyVaultOrController nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();
        if (to == address(0)) revert ZERO_ADDRESS();
        IERC20(IERC4626(vault).asset()).safeTransfer(to, amount);
        emit DepositAssetsRefunded(to, amount);
    }

    /// @inheritdoc IManagedSuperVaultEscrow
    /// @dev Release path: only the controller, on deposit fulfillment (moves pending assets into custody)
    function releaseDepositAssets(address to, uint256 amount) external onlyController nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();
        if (to == address(0)) revert ZERO_ADDRESS();
        IERC20(IERC4626(vault).asset()).safeTransfer(to, amount);
        emit DepositAssetsReleased(to, amount);
    }
}
