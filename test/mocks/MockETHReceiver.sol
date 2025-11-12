// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title MockETHReceiver
/// @author Superform Labs
/// @notice Simple contract to receive and track ETH for testing, implements ERC4626 interface
contract MockETHReceiver is ERC20, IERC4626 {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total ETH received
    uint256 public totalReceived;

    /// @notice Number of times ETH was received
    uint256 public receiveCount;

    /// @notice Event emitted when ETH is received
    event ETHReceived(address sender, uint256 amount, uint256 totalReceived);

    /// @notice Event emitted when execute function is called
    event ExecuteCalled(address indexed sender, uint256 value);

    IERC20 public immutable USDC;

    constructor(address usdc_) ERC20("MockETHReceiver", "mETH") {
        USDC = IERC20(usdc_);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC4626 IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    function asset() external view override returns (address) {
        return address(USDC);
    }

    function totalAssets() external view override returns (uint256) {
        return USDC.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) external pure override returns (uint256) {
        return assets; // 1:1 conversion for simplicity
    }

    function convertToAssets(uint256 shares) external pure override returns (uint256) {
        return shares; // 1:1 conversion for simplicity
    }

    function maxDeposit(address) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) external view override returns (uint256) {
        return balanceOf(owner);
    }

    function maxRedeem(address owner) external view override returns (uint256) {
        return balanceOf(owner);
    }

    function previewDeposit(uint256 assets) external pure override returns (uint256) {
        return assets; // 1:1 conversion for simplicity
    }

    function previewMint(uint256 shares) external pure override returns (uint256) {
        return shares; // 1:1 conversion for simplicity
    }

    function previewWithdraw(uint256 assets) external pure override returns (uint256) {
        return assets; // 1:1 conversion for simplicity
    }

    function previewRedeem(uint256 shares) external pure override returns (uint256) {
        return shares; // 1:1 conversion for simplicity
    }

    function deposit(uint256 assets, address receiver) external override returns (uint256) {
        USDC.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, assets);
        emit Deposit(msg.sender, receiver, assets, assets);
        return assets;
    }

    function mint(uint256 shares, address receiver) external override returns (uint256) {
        USDC.transferFrom(msg.sender, address(this), shares);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, shares, shares);
        return shares;
    }

    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256) {
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, assets);
        }
        _burn(owner, assets);
        USDC.transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, assets);
        return assets;
    }

    function redeem(uint256 shares, address receiver, address owner) external override returns (uint256) {
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        _burn(owner, shares);
        USDC.transfer(receiver, shares);
        emit Withdraw(msg.sender, receiver, owner, shares, shares);
        return shares;
    }

    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Simple execute function that can be called by hooks
    function execute() external payable {
        emit ExecuteCalled(msg.sender, msg.value);
        totalReceived += msg.value;

        // Transfer USDC back to the caller (simulate yield generation)
        // Convert ETH (18 decimals) to USDC (6 decimals) - 1:1 value ratio
        if (msg.value > 0) {
            uint256 usdcAmount = msg.value / 1e12; // Convert from 18 decimals to 6 decimals
            if (IERC20(USDC).balanceOf(address(this)) >= usdcAmount) {
                IERC20(USDC).transfer(msg.sender, usdcAmount);
            }
        }
    }

    /// @notice Execute function with data parameter
    function executeWithData(bytes calldata) external payable {
        emit ExecuteCalled(msg.sender, msg.value);
        if (msg.value > 0) {
            totalReceived += msg.value;
            receiveCount++;
        }
    }

    /// @notice Reset counters for testing
    function reset() external {
        totalReceived = 0;
        receiveCount = 0;
    }

    /// @notice Withdraw all ETH (for cleanup)
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract to receive ETH
    receive() external payable {
        totalReceived += msg.value;
        receiveCount++;
        emit ETHReceived(msg.sender, msg.value, totalReceived);
    }
}
