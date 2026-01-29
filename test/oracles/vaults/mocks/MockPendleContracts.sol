// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IStandardizedYield } from "@pendle/interfaces/IStandardizedYield.sol";
import { IPPrincipalToken } from "@pendle/interfaces/IPPrincipalToken.sol";
import { IPYieldToken } from "@pendle/interfaces/IPYieldToken.sol";

/// @title MockPrincipalToken
/// @notice Minimal mock Pendle Principal Token for testing - only implements what we need
contract MockPrincipalToken {
    uint256 private _expiry;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    string public constant name = "Mock PT";
    string public constant symbol = "mPT";
    uint8 public constant decimals = 18;

    constructor(uint256 expiryTimestamp) {
        _expiry = expiryTimestamp;
    }

    function expiry() external view returns (uint256) {
        return _expiry;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }

    function burn(address from, uint256 amount) external {
        require(_balances[from] >= amount, "Insufficient balance");
        _balances[from] -= amount;
        _totalSupply -= amount;
    }

    // ERC20 interface (minimal)
    function transfer(address, uint256) external pure returns (bool) {
        return true;
    }

    function approve(address, uint256) external pure returns (bool) {
        return true;
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        return true;
    }

    function allowance(address, address) external pure returns (uint256) {
        return type(uint256).max;
    }
}

/// @title MockPendleMarket
/// @notice Minimal mock Pendle Market for testing - implements readTokens() and getPtToAssetRate()
contract MockPendleMarket {
    address private immutable _sy;
    address private immutable _pt;
    address private immutable _yt;

    constructor(address ptAddress) {
        _sy = address(new MockSY());
        _pt = ptAddress;
        _yt = address(new MockYT());
    }

    function readTokens()
        external
        view
        returns (IStandardizedYield sy, IPPrincipalToken pt, IPYieldToken yt)
    {
        return (IStandardizedYield(_sy), IPPrincipalToken(_pt), IPYieldToken(_yt));
    }

    function expiry() external view returns (uint256) {
        return MockPrincipalToken(_pt).expiry();
    }

    /// @notice Returns PT to asset TWAP rate - at maturity returns 1e18 (1:1)
    /// @dev For testing, returns 1e18 at/after maturity, 0.9e18 before
    function getPtToAssetRate(uint32) external view returns (uint256) {
        uint256 maturity = MockPrincipalToken(_pt).expiry();
        if (block.timestamp >= maturity) {
            return 1e18; // At maturity, 1 PT = 1 underlying
        }
        return 0.9e18; // Before maturity, 1 PT = 0.9 underlying (10% discount)
    }
}

/// @title MockSY
/// @notice Minimal mock SY for market.readTokens() and getAssetOutput()
contract MockSY {
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @notice Returns asset info for pricing calculations
    /// @return assetType Always 0 (TOKEN) for this mock
    /// @return assetAddress Zero address (not used in our calculations)
    /// @return assetDecimals 18 decimals (matches PT decimals for consistent testing)
    function assetInfo() external pure returns (uint8 assetType, address assetAddress, uint8 assetDecimals) {
        return (0, address(0), 18);
    }

    /// @notice Returns exchange rate - used by Pendle oracle library
    /// @dev Returns 1e18 (1:1) for simplicity in unit tests
    function exchangeRate() external pure returns (uint256) {
        return 1e18;
    }
}

/// @title MockYT
/// @notice Minimal mock YT for market.readTokens() and Pendle oracle library
contract MockYT {
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /// @notice Returns stored PY index - used by Pendle oracle library
    /// @dev Returns 1e18 (1:1) for simplicity in unit tests
    function pyIndexStored() external pure returns (uint256) {
        return 1e18;
    }

    /// @notice Whether to cache index in same block - used by Pendle oracle library
    function doCacheIndexSameBlock() external pure returns (bool) {
        return false;
    }

    /// @notice Returns current PY index - used by Pendle oracle library
    function pyIndexCurrent() external pure returns (uint256) {
        return 1e18;
    }
}
