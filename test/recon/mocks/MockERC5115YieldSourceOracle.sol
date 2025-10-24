// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IYieldSourceOracle} from "@superform-v2-core/src/interfaces/accounting/IYieldSourceOracle.sol";
import {MockERC5115Tester} from "./MockERC5115Tester.sol";

/// @title MockERC5115YieldSourceOracle
/// @notice Mock oracle for ERC5115 (Standardized Yield) vaults in testing
contract MockERC5115YieldSourceOracle is IYieldSourceOracle {
    mapping(address => bool) public validAssetMap;
    
    function setValidAsset(address asset, bool isValid) external {
        validAssetMap[asset] = isValid;
    }
    
    function decimals(address) external pure returns (uint8) {
        // ERC5115 always uses 18 decimals
        return 18;
    }
    
    function getShareOutput(
        address yieldSourceAddress,
        address assetIn,
        uint256 assetsIn
    ) external view returns (uint256) {
        return MockERC5115Tester(yieldSourceAddress).previewDeposit(assetIn, assetsIn);
    }
    
    function getAssetOutput(
        address yieldSourceAddress,
        address assetOut,
        uint256 sharesIn
    ) public view returns (uint256) {
        return MockERC5115Tester(yieldSourceAddress).previewRedeem(assetOut, sharesIn);
    }
    
    function getPricePerShare(address yieldSourceAddress) external view returns (uint256) {
        return MockERC5115Tester(yieldSourceAddress).exchangeRate();
    }
    
    function getBalanceOfOwner(
        address yieldSourceAddress,
        address ownerOfShares
    ) external view returns (uint256) {
        return MockERC5115Tester(yieldSourceAddress).balanceOf(ownerOfShares);
    }
    
    function getTVLByOwnerOfShares(
        address yieldSourceAddress,
        address ownerOfShares
    ) external view returns (uint256) {
        uint256 shares = MockERC5115Tester(yieldSourceAddress).balanceOf(ownerOfShares);
        uint256 exchangeRate = MockERC5115Tester(yieldSourceAddress).exchangeRate();
        return (shares * exchangeRate) / 1e18;
    }
    
    function getTVL(address yieldSourceAddress) external view returns (uint256) {
        uint256 totalShares = MockERC5115Tester(yieldSourceAddress).totalSupply();
        uint256 exchangeRate = MockERC5115Tester(yieldSourceAddress).exchangeRate();
        return (totalShares * exchangeRate) / 1e18;
    }
    
    function getPricePerShareMultiple(
        address[] memory yieldSourceAddresses
    ) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](yieldSourceAddresses.length);
        for (uint256 i = 0; i < yieldSourceAddresses.length; i++) {
            prices[i] = MockERC5115Tester(yieldSourceAddresses[i]).exchangeRate();
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
            uint256 exchangeRate = MockERC5115Tester(yieldSourceAddresses[i]).exchangeRate();
            for (uint256 j = 0; j < ownersOfShares[i].length; j++) {
                uint256 shares = MockERC5115Tester(yieldSourceAddresses[i]).balanceOf(ownersOfShares[i][j]);
                result[i][j] = (shares * exchangeRate) / 1e18;
            }
        }
        return result;
    }
    
    function getTVLMultiple(
        address[] memory yieldSourceAddresses
    ) external view returns (uint256[] memory) {
        uint256[] memory tvls = new uint256[](yieldSourceAddresses.length);
        for (uint256 i = 0; i < yieldSourceAddresses.length; i++) {
            uint256 totalShares = MockERC5115Tester(yieldSourceAddresses[i]).totalSupply();
            uint256 exchangeRate = MockERC5115Tester(yieldSourceAddresses[i]).exchangeRate();
            tvls[i] = (totalShares * exchangeRate) / 1e18;
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
        address assetOut,
        address,
        uint256 sharesIn
    ) external view returns (uint256) {
        return MockERC5115Tester(yieldSourceAddress).previewRedeem(assetOut, sharesIn);
    }
}