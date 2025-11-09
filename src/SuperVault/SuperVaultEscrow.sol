// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SuperVaultEscrow
/// @author Superform Labs
/// @notice Escrow contract for SuperVault shares during request/claim process
contract SuperVaultEscrow {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error ALREADY_INITIALIZED();
    error UNAUTHORIZED();
    error ZERO_ADDRESS();

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/
    bool public initialized;
    address public vault;
    address public strategy;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyVault() {
        if (msg.sender != vault) revert UNAUTHORIZED();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the escrow with required parameters
    /// @param vaultAddress The vault contract address
    /// @param strategyAddress The strategy contract address
    function initialize(address vaultAddress, address strategyAddress) external {
        if (initialized) revert ALREADY_INITIALIZED();
        if (vaultAddress == address(0) || strategyAddress == address(0)) revert ZERO_ADDRESS();

        initialized = true;
        vault = vaultAddress;
        strategy = strategyAddress;
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer shares from user to escrow during redeem request
    /// @param from The address to transfer shares from
    /// @param amount The amount of shares to transfer
    function escrowShares(address from, uint256 amount) external onlyVault {
        IERC20(vault).safeTransferFrom(from, address(this), amount);
    }

    /// @notice Return shares from escrow to user during redeem cancellation
    /// @param to The address to return shares to
    /// @param amount The amount of shares to return
    function returnShares(address to, uint256 amount) external onlyVault {
        IERC20(vault).safeTransfer(to, amount);
    }

    /// @notice Return assets from escrow to vault during deposit cancellation
    /// @param to The address to return assets to
    /// @param amount The amount of assets to return
    function returnAssets(address to, uint256 amount) external onlyVault {
        IERC20(IERC4626(vault).asset()).safeTransfer(to, amount);
    }
}
