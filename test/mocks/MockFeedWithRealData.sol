// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { AggregatorV3Interface } from "../../src/vendor/chainlink/AggregatorV3Interface.sol";

import "forge-std/console2.sol";

/// @dev the purpose of this contract is to mock a feed with real data
///      it sets data to the latest round data of a chainlink feed
///      but updates `updatedAt` to a specified timestamp.
///      Reason is to continue forking and `vm.warp` calls without
///      the feed being considered stale
contract MockFeedWithRealData {
    AggregatorV3Interface public feed;
    
    constructor(address feed_) {
        feed = AggregatorV3Interface(feed_);
    }

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        console2.log("latestRoundData ------ block.timestamp", block.timestamp);
        (roundId, answer, startedAt,updatedAt, answeredInRound) = AggregatorV3Interface(feed).latestRoundData();
        updatedAt = block.timestamp;
    }

    function decimals() external view returns (uint8) {
        return AggregatorV3Interface(feed).decimals();
    }
}