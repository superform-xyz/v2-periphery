// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

contract MockAssetNoDecimals {
    string public name;
    string public symbol;

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function decimals() public pure returns (uint8) {
        revert("Not implemented");
    }
}