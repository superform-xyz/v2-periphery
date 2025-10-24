// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";

import {EnumerableSet} from "@recon/EnumerableSet.sol";
import {MockERC20} from "@recon/MockERC20.sol";

import {MockERC4626Tester} from "../mocks/MockERC4626Tester.sol";
import {MockERC5115Tester} from "../mocks/MockERC5115Tester.sol";
import {MockERC7540Tester} from "../mocks/MockERC7540Tester.sol";

/// @dev Source of truth for the yield sources being used in the test
/// @notice No yield sources should be used in the test suite without being added from here first
/// @notice Enum to specify the type of yield source to deploy
enum YieldSourceType {
    ERC4626,
    ERC5115,
    ERC7540
}

abstract contract YieldManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice The current target for this set of variables
    address private __yieldSource;

    /// @notice The current yield source type
    YieldSourceType private __currentYieldSourceType;

    /// @notice The list of all yield sources being used
    EnumerableSet.AddressSet private _yieldSources;

    // If the current target is address(0) then it has not been setup yet and should revert
    error YieldSourceNotSetup();
    // Do not allow duplicates
    error YieldSourceExists();
    // Enable only added yield sources
    error YieldSourceNotAdded();
    // Invalid yield source type
    error InvalidYieldSourceType();

    /// @notice Returns the current active yield source
    function _getYieldSource() internal view returns (address) {
        if (__yieldSource == address(0)) {
            revert YieldSourceNotSetup();
        }

        return __yieldSource;
    }

    /// @notice Returns all yield sources being used
    function _getYieldSources() internal view returns (address[] memory) {
        return _yieldSources.values();
    }

    /// @notice Returns the current yield source type
    function _getCurrentYieldSourceType() internal view returns (YieldSourceType) {
        return __currentYieldSourceType;
    }

    /// @notice Creates a new yield source and adds it to the list of yield sources
    /// @param asset The asset to create the yield source for
    /// @param yieldSourceType The type of yield source to deploy
    /// @return The address of the new yield source
    function _newYieldSource(address asset, YieldSourceType yieldSourceType) internal returns (address) {
        address yieldSource_;
        
        if (yieldSourceType == YieldSourceType.ERC4626) {
            yieldSource_ = address(new MockERC4626Tester(asset));
        } else if (yieldSourceType == YieldSourceType.ERC5115) {
            yieldSource_ = address(new MockERC5115Tester(asset));
        } else if (yieldSourceType == YieldSourceType.ERC7540) {
            yieldSource_ = address(new MockERC7540Tester(asset));
        } else {
            revert InvalidYieldSourceType();
        }
        
        _addYieldSource(yieldSource_);
        __yieldSource = yieldSource_; // sets the yield source as the current yield source
        __currentYieldSourceType = yieldSourceType;
        return yieldSource_;
    }

    /// @notice Creates a new yield source with ERC4626 by default (backward compatibility)
    /// @param asset The asset to create the yield source for
    /// @return The address of the new yield source
    function _newYieldSource(address asset) internal returns (address) {
        return _newYieldSource(asset, YieldSourceType.ERC4626);
    }

    /// @notice Legacy function name for backward compatibility
    /// @param asset The asset to create the yield source for
    /// @return The address of the new yield source
    function _newVault(address asset) internal returns (address) {
        return _newYieldSource(asset, YieldSourceType.ERC4626);
    }

    /// @notice Adds a yield source to the list of yield sources
    /// @param target The address of the yield source to add
    function _addYieldSource(address target) internal {
        if (_yieldSources.contains(target)) {
            revert YieldSourceExists();
        }

        _yieldSources.add(target);
    }

    /// @notice Legacy function name for backward compatibility
    /// @param target The address of the yield source to add
    function _addVault(address target) internal {
        _addYieldSource(target);
    }

    /// @notice Removes a yield source from the list of yield sources
    /// @param target The address of the yield source to remove
    function _removeYieldSource(address target) internal {
        if (!_yieldSources.contains(target)) {
            revert YieldSourceNotAdded();
        }

        _yieldSources.remove(target);
    }

    /// @notice Legacy function name for backward compatibility
    /// @param target The address of the yield source to remove
    function _removeVault(address target) internal {
        _removeYieldSource(target);
    }

    /// @notice Switches the current yield source based on the entropy
    /// @param entropy The entropy to choose a random yield source in the array for switching
    function _switchYieldSource(uint256 entropy) internal {
        address target = _yieldSources.at(entropy % _yieldSources.length());
        __yieldSource = target;
    }

    /// @notice Legacy function name for backward compatibility
    /// @param entropy The entropy to choose a random yield source in the array for switching
    function _switchVault(uint256 entropy) internal {
        _switchYieldSource(entropy);
    }

    /// @notice Switches to a different yield source type by deploying a new yield source
    /// @param asset The asset to create the new yield source for
    /// @param newYieldSourceType The new yield source type to switch to
    /// @return The address of the new yield source
    function _switchYieldSourceType(address asset, YieldSourceType newYieldSourceType) internal returns (address) {
        return _newYieldSource(asset, newYieldSourceType);
    }
}
