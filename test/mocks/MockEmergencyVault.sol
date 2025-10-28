// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/// @title MockEmergencyVault
/// @notice Emergency vault implementation for holding and managing tokens during emergency situations
contract MockEmergencyVault {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error UNAUTHORIZED();
    error ZERO_ADDRESS();
    error ZERO_AMOUNT();
    error INSUFFICIENT_BALANCE();
    error TRANSFER_FAILED();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when tokens are received by the emergency vault
    event TokensReceived(address indexed token, address indexed from, uint256 amount);

    /// @notice Emitted when tokens are withdrawn from the emergency vault
    event TokensWithdrawn(address indexed token, address indexed to, uint256 amount);

    /// @notice Emitted when tokens are reinvested into a vault
    event TokensReinvested(address indexed token, address indexed vault, uint256 amount, uint256 shares);

    /// @notice Emitted when owner is updated
    event OwnerUpdated(address indexed oldOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    mapping(address => uint256) public tokenBalances;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert UNAUTHORIZED();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the emergency vault
    /// @param owner_ The owner address of the vault
    constructor(address owner_) {
        if (owner_ == address(0)) revert ZERO_ADDRESS();
        owner = owner_;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraw tokens from the emergency vault to a recipient
    /// @param token_ The token address to withdraw
    /// @param to_ The recipient address
    function withdrawTokens(address token_, address to_) external onlyOwner {
        if (token_ == address(0)) revert ZERO_ADDRESS();
        if (to_ == address(0)) revert ZERO_ADDRESS();

        uint256 balance = getTokenBalance(token_);
        if (balance == 0) revert INSUFFICIENT_BALANCE();

        tokenBalances[token_] = 0;
        IERC20(token_).safeTransfer(to_, balance);

        emit TokensWithdrawn(token_, to_, balance);
    }

    /// @notice Reinvest tokens into a SuperVault or any ERC4626 vault
    /// @param token_ The token to reinvest
    /// @param vault_ The vault to deposit into
    /// @param amount_ The amount to reinvest
    /// @return shares The amount of shares received
    function reinvestIntoVault(address token_, address vault_, uint256 amount_, address receiver_) external onlyOwner returns (uint256 shares) {
        if (token_ == address(0)) revert ZERO_ADDRESS();
        if (vault_ == address(0)) revert ZERO_ADDRESS();
        if (amount_ == 0) revert ZERO_AMOUNT();
        if (getTokenBalance(token_) < amount_) revert INSUFFICIENT_BALANCE();

        // Verify vault accepts this token
        IERC4626 vault = IERC4626(vault_);
        if (vault.asset() != token_) revert TRANSFER_FAILED();

        if (tokenBalances[token_] > amount_) {
            tokenBalances[token_] -= amount_;
        } else {
            tokenBalances[token_] = 0;
        }
        
        // Approve vault to spend tokens
        IERC20(token_).approve(vault_, amount_);
        
        // Deposit into vault and receive shares
        shares = vault.deposit(amount_, receiver_);

        emit TokensReinvested(token_, vault_, amount_, shares);
    }

    /// @notice Update the owner of the emergency vault
    /// @param newOwner_ The new owner address
    function updateOwner(address newOwner_) external onlyOwner {
        if (newOwner_ == address(0)) revert ZERO_ADDRESS();
        
        address oldOwner = owner;
        owner = newOwner_;

        emit OwnerUpdated(oldOwner, newOwner_);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the balance of a specific token in the emergency vault
    /// @param token_ The token address
    /// @return The token balance
    function getTokenBalance(address token_) public view returns (uint256) {
        return tokenBalances[token_] + IERC20(token_).balanceOf(address(this));
    }
}