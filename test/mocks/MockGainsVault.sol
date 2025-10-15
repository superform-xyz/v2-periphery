// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

contract MockGainsVault is ERC4626 {
    address public _asset;
    IERC20 private immutable assetInstance;

    uint256 public immutable PRECISION;

    constructor(
        address asset_,
        string memory name_,
        string memory symbol_
    )
        ERC4626(IERC20(asset_))
        ERC20(name_, symbol_)
    {
        _asset = asset_;
        assetInstance = IERC20(asset_);

        PRECISION = 10 ** IERC20Metadata(asset_).decimals();
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function previewDeposit(uint256 assets) public pure override returns (uint256 shares) {
        return assets;
    }

    function previewWithdraw(uint256 shares) public pure override returns (uint256 assets) {
        return shares;
    }

    function previewRedeem(uint256 shares) public pure override returns (uint256 assets) {
        return shares * 400;
    }

    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        uint256 pps = 1e18;
        return Math.mulDiv(shares, pps, PRECISION, Math.Rounding.Floor);
    }

    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        uint256 pps = 1e18;
        return Math.mulDiv(assets, PRECISION, pps, Math.Rounding.Floor);
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        shares = assets;

        IERC20(_asset).transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        assets = shares * 400;

        IERC20(_asset).transfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function totalAssets() public pure override returns (uint256) {
        // For simplicity, we don't include accrued yield in totalAssets
        return 1e18;
    }
}
