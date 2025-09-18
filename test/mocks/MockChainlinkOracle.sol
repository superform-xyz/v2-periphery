// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

contract MockChainlinkOracle {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        roundId = 1;
        answer = 1e8;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}