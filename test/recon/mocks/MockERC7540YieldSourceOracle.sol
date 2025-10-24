// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IYieldSourceOracle} from "@superform-v2-core/src/interfaces/accounting/IYieldSourceOracle.sol";
import {MockERC7540Tester} from "./MockERC7540Tester.sol";

/// @title MockERC7540YieldSourceOracle
/// @notice Mock oracle for ERC7540 (Asynchronous Tokenized Vaults) in testing
contract MockERC7540YieldSourceOracle is IYieldSourceOracle {
    mapping(address => bool) public validAssetMap;
    
    function setValidAsset(address asset, bool isValid) external {
        validAssetMap[asset] = isValid;
    }
    
    function decimals(address yieldSourceAddress) external view returns (uint8) {
        address share = MockERC7540Tester(yieldSourceAddress).share();
        return IERC20Metadata(share).decimals();
    }
    
    function getShareOutput(
        address yieldSourceAddress,
        address,
        uint256 assetsIn
    ) external view returns (uint256) {
        return MockERC7540Tester(yieldSourceAddress).convertToShares(assetsIn);
    }
    
    function getAssetOutput(
        address yieldSourceAddress,
        address,
        uint256 sharesIn
    ) public view returns (uint256) {
        return MockERC7540Tester(yieldSourceAddress).convertToAssets(sharesIn);
    }
    
    function getPricePerShare(address yieldSourceAddress) external view returns (uint256) {
        address share = MockERC7540Tester(yieldSourceAddress).share();
        uint256 _decimals = IERC20Metadata(share).decimals();
        return MockERC7540Tester(yieldSourceAddress).convertToAssets(10 ** _decimals);
    }
    
    function getBalanceOfOwner(
        address yieldSourceAddress,
        address ownerOfShares
    ) external view returns (uint256) {
        return IERC20(MockERC7540Tester(yieldSourceAddress).share()).balanceOf(ownerOfShares);
    }
    
    function getTVLByOwnerOfShares(
        address yieldSourceAddress,
        address ownerOfShares
    ) external view returns (uint256) {
        address share = MockERC7540Tester(yieldSourceAddress).share();
        uint256 shares = IERC20(share).balanceOf(ownerOfShares);
        return MockERC7540Tester(yieldSourceAddress).convertToAssets(shares);
    }
    
    function getTVL(address yieldSourceAddress) external view returns (uint256) {
        return MockERC7540Tester(yieldSourceAddress).totalAssets();
    }
    
    function getPricePerShareMultiple(
        address[] memory yieldSourceAddresses
    ) external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](yieldSourceAddresses.length);
        for (uint256 i = 0; i < yieldSourceAddresses.length; i++) {
            address share = MockERC7540Tester(yieldSourceAddresses[i]).share();
            uint256 _decimals = IERC20Metadata(share).decimals();
            prices[i] = MockERC7540Tester(yieldSourceAddresses[i]).convertToAssets(10 ** _decimals);
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
            address share = MockERC7540Tester(yieldSourceAddresses[i]).share();
            for (uint256 j = 0; j < ownersOfShares[i].length; j++) {
                uint256 shares = IERC20(share).balanceOf(ownersOfShares[i][j]);
                result[i][j] = MockERC7540Tester(yieldSourceAddresses[i]).convertToAssets(shares);
            }
        }
        return result;
    }
    
    function getTVLMultiple(
        address[] memory yieldSourceAddresses
    ) external view returns (uint256[] memory) {
        uint256[] memory tvls = new uint256[](yieldSourceAddresses.length);
        for (uint256 i = 0; i < yieldSourceAddresses.length; i++) {
            tvls[i] = MockERC7540Tester(yieldSourceAddresses[i]).totalAssets();
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
        return MockERC7540Tester(yieldSourceAddress).convertToAssets(sharesIn);
    }
}