// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISuperVaultEscrow } from "../interfaces/SuperVault/ISuperVaultEscrow.sol";

/// @title SuperVaultEscrow
/// @author Superform Labs
/// @notice Escrow contract for SuperVault shares during request/claim process
contract SuperVaultEscrow is ISuperVaultEscrow {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    bool public initialized;
    address public vault;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyVault() {
        _onlyVault();
        _;
    }

    function _onlyVault() internal view {
        if (msg.sender != vault) revert UNAUTHORIZED();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultEscrow
    function initialize(address vaultAddress) external {
        if (initialized) revert ALREADY_INITIALIZED();
        if (vaultAddress == address(0)) revert ZERO_ADDRESS();

        initialized = true;
        vault = vaultAddress;

        emit Initialized(vaultAddress);
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultEscrow
    function escrowShares(address from, uint256 amount) external onlyVault {
        if (amount == 0) revert ZERO_AMOUNT();
        IERC20(vault).safeTransferFrom(from, address(this), amount);
        emit SharesEscrowed(from, amount);
    }

    /// @inheritdoc ISuperVaultEscrow
    function returnShares(address to, uint256 amount) external onlyVault {
        if (amount == 0) revert ZERO_AMOUNT();
        IERC20(vault).safeTransfer(to, amount);
        emit SharesReturned(to, amount);
    }

    /// @inheritdoc ISuperVaultEscrow
    function returnAssets(address to, uint256 amount) external onlyVault {
        if (amount == 0) revert ZERO_AMOUNT();
        if (to == address(0)) revert ZERO_ADDRESS();
        IERC20(IERC4626(vault).asset()).safeTransfer(to, amount);
        emit AssetsReturned(to, amount);
    }
}
