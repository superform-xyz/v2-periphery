// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC7540Redeem, IERC7540CancelRedeem } from "../../vendor/standards/ERC7540/IERC7540Vault.sol";
import { IERC7741 } from "../../vendor/standards/ERC7741/IERC7741.sol";

/// @title ISuperVault
/// @notice Interface for SuperVault core contract that manages share minting
/// @author Superform Labs
interface ISuperVault is IERC4626, IERC7540Redeem, IERC7741, IERC7540CancelRedeem {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error INVALID_ASSET();
    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error INVALID_AMOUNT();
    error UNAUTHORIZED();
    error DEADLINE_PASSED();
    error INVALID_SIGNATURE();
    error NOT_IMPLEMENTED();
    error INVALID_NONCE();
    error INVALID_WITHDRAW_PRICE();
    error INVALID_CONTROLLER();
    error CONTROLLER_MUST_EQUAL_OWNER();
    error RECEIVER_MUST_EQUAL_CONTROLLER();
    error NOT_ENOUGH_ASSETS();
    error CANCELLATION_REDEEM_REQUEST_PENDING();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event NonceInvalidated(address indexed sender, bytes32 indexed nonce);

    event SuperGovernorSet(address indexed superGovernor);

    event Initialized(address indexed asset, address indexed strategy, address indexed escrow);

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL METHODS
    //////////////////////////////////////////////////////////////*/
    /// @notice Burn shares, only callable by strategy
    /// @param amount The amount of shares to burn
    function burnShares(uint256 amount) external;

    /// @notice Get the amount of assets escrowed
    function getEscrowedAssets() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            VIEW METHODS
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the escrow address
    function escrow() external view returns (address);
}
