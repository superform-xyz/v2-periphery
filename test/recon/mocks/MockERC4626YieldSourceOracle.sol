// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IYieldSourceOracle} from "@superform-v2-core/src/interfaces/accounting/IYieldSourceOracle.sol";

/// @title MockERC4626YieldSourceOracle
/// @notice Mock oracle for ERC4626 vaults in testing
contract MockERC4626YieldSourceOracle is IYieldSourceOracle {
    mapping(address => bool) public validAssetMap;
    
    function setValidAsset(address asset, bool isValid) external {
        validAssetMap[asset] = isValid;
    }
    
    function decimals(address yieldSourceAddress) external view returns (uint8) {
        return IERC4626(yieldSourceAddress).decimals();
    }
    
    function getShareOutput(
        address yieldSourceAddress,
        address,
        uint256 assetsIn
    ) external view returns (uint256) {
        return IERC4626(yieldSourceAddress).previewDeposit(assetsIn);
    }
    
    function getAssetOutput(
        address yieldSourceAddress,
        address,
        uint256 sharesIn
    ) public view returns (uint256) {
        return IERC4626(yieldSourceAddress).previewRedeem(sharesIn);
    }
    
    function getPricePerShare(address yieldSourceAddress) external view returns (uint256) {
        IERC4626 yieldSource = IERC4626(yieldSourceAddress);
        uint256 _decimals = yieldSource.decimals();
        return yieldSource.convertToAssets(10 ** _decimals);
    }
    
    function getBalanceOfOwner(
        address yieldSourceAddress,
        address ownerOfShares
    ) external view returns (uint256) {
        return IERC4626(yieldSourceAddress).balanceOf(ownerOfShares);
    }
    
    function getTVLByOwnerOfShares(
        address yieldSourceAddress,
        address ownerOfShares
    ) external view returns (uint256) {
        uint256 shares = IERC4626(yieldSourceAddress).balanceOf(ownerOfShares);
        return IERC4626(yieldSourceAddress).convertToAssets(shares);
    }
    
    function getTVL(address yieldSourceAddress) external view returns (uint256) {
        return IERC4626(yieldSourceAddress).totalAssets();
    }
    
    function getPricePerShareMultiple(
        address[] memory yieldSourceAddresses
    ) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](yieldSourceAddresses.length);
        for (uint256 i = 0; i < yieldSourceAddresses.length; i++) {
            IERC4626 yieldSource = IERC4626(yieldSourceAddresses[i]);
            uint256 _decimals = yieldSource.decimals();
            prices[i] = yieldSource.convertToAssets(10 ** _decimals);
        }
        return prices;
    }
    
    function getTVLByOwnerOfSharesMultiple(
        address[] memory yieldSourceAddresses,
        address[][] memory ownersOfShares
    ) external view returns (uint256[][] memory) {
        uint256[][] memory result = new uint256[][](yieldSourceAddresses.length);
        for (uint256 i = 0; i < yieldSourceAddresses.length; i++) {
            result[i] = new uint256[](ownersOfShares[i].length);
            for (uint256 j = 0; j < ownersOfShares[i].length; j++) {
                uint256 shares = IERC4626(yieldSourceAddresses[i]).balanceOf(ownersOfShares[i][j]);
                result[i][j] = IERC4626(yieldSourceAddresses[i]).convertToAssets(shares);
            }
        }
        return result;
    }
    
    function getTVLMultiple(
        address[] memory yieldSourceAddresses
    ) external view returns (uint256[] memory) {
        uint256[] memory tvls = new uint256[](yieldSourceAddresses.length);
        for (uint256 i = 0; i < yieldSourceAddresses.length; i++) {
            tvls[i] = IERC4626(yieldSourceAddresses[i]).totalAssets();
        }
        return tvls;
    }
    
    function isValidUnderlyingAsset(address, address asset) external view returns (bool) {
        return validAssetMap[asset];
    }
    
    function isValidUnderlyingAssets(
        address[] memory,
        address[] memory assets
    ) external view returns (bool[] memory) {
        bool[] memory validities = new bool[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            validities[i] = validAssetMap[assets[i]];
        }
        return validities;
    }
    
    function getAssetOutputWithFees(
        bytes32,
        address yieldSourceAddress,
        address,
        address,
        uint256 sharesIn
    ) external view returns (uint256) {
        return IERC4626(yieldSourceAddress).previewRedeem(sharesIn);
    }
}