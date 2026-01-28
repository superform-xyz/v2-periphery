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
/// @notice Minimal mock Pendle Market for testing - only implements readTokens()
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
}

/// @title MockSY
/// @notice Minimal mock SY for market.readTokens()
contract MockSY {
    function decimals() external pure returns (uint8) {
        return 18;
    }
}

/// @title MockYT
/// @notice Minimal mock YT for market.readTokens()
contract MockYT {
    function decimals() external pure returns (uint8) {
        return 18;
    }
}
