// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IOracle } from "../../src/vendor/awesome-oracles/IOracle.sol";

// Mock SuperOracle implementation for testing
contract MockSuperOracle is IOracle {
    uint256 public quoteAmount;

    constructor(uint256 _quoteAmount) {
        quoteAmount = _quoteAmount;
    }

    function setQuoteAmount(uint256 _quoteAmount) external {
        quoteAmount = _quoteAmount;
    }

    function getQuote(uint256, address, address) external view returns (uint256) {
        return quoteAmount;
    }
    
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function getQuoteFromProvider(
        uint256,
        address,
        address,
        bytes32
    )
        external
        view
        returns (uint256, uint256, uint256, uint256) {
        return (quoteAmount, 0, 1, 1);
    }
}
