// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {
    IERC7540Deposit,
    IERC7540Redeem,
    IERC7540CancelDeposit,
    IERC7540CancelRedeem
} from "../../vendor/standards/ERC7540/IERC7540Vault.sol";
import { IERC7741 } from "../../vendor/standards/ERC7741/IERC7741.sol";

/// @title IManagedSuperVault
/// @notice Interface for the ManagedSuperVault share token: a fully-async ERC-7540 vault with
///         async deposit request/claim rails and async redeem request/claim rails.
/// @dev Synchronous ERC-4626 two-arg deposit(uint256,address) and mint(uint256,address) revert with
///      NOT_IMPLEMENTED. The ERC-7540 three-arg deposit/mint overloads are the deposit claim step,
///      priced at the weighted average fulfillment PPS (mirroring the redeem-side claim grammar).
/// @dev Deposit cancellation is instantly fulfilled (pending assets sit idle in escrow), so
///      cancelDepositRequest refunds in the same transaction; pendingCancelDepositRequest is always
///      false and claimableCancelDepositRequest is always 0.
/// @dev Share conversions use the latest attested manual NAV/PPS stored in the
///      ManagedSuperVaultAggregator.
/// @author Superform Labs
interface IManagedSuperVault is
    IERC4626,
    IERC7540Deposit,
    IERC7540Redeem,
    IERC7741,
    IERC7540CancelDeposit,
    IERC7540CancelRedeem
{
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
    error INVALID_DEPOSIT_PRICE();
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

    event Initialized(address indexed asset, address indexed controller, address indexed escrow);

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL METHODS
    //////////////////////////////////////////////////////////////*/
    /// @notice Burn shares held in escrow, only callable by the controller
    /// @param amount The amount of shares to burn
    function burnShares(uint256 amount) external;

    /// @notice Get the amount of assets held in escrow (pending deposits + fulfilled redemptions)
    function getEscrowedAssets() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                            VIEW METHODS
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the escrow address
    function escrow() external view returns (address);
}
