// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { FixedPriceOracle } from "../../src/oracles/FixedPriceOracle.sol";
import { MockAggregator } from "../mocks/MockAggregator.sol";

/// @title FixedPriceOracleTest
/// @notice Unit tests for FixedPriceOracle - Chainlink compatible fixed price oracle
contract FixedPriceOracleTest is Test {
    FixedPriceOracle public fixedPriceOracle;
    address public owner;

    // Test constants
    int256 constant INITIAL_UP_PRICE = 0.09e18; // $0.09 with 18 decimals
    uint8 constant UP_DECIMALS = 18;

    function setUp() public {
        owner = address(this);

        // Create FixedPriceOracle for UP/USD at $0.09
        fixedPriceOracle = new FixedPriceOracle(INITIAL_UP_PRICE, UP_DECIMALS, owner);
    }

    /// @notice Test basic FixedPriceOracle functionality
    function test_FixedPriceOracle_BasicFunctionality() public view {
        // Check decimals
        assertEq(fixedPriceOracle.decimals(), UP_DECIMALS);

        // Check latestRoundData
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            fixedPriceOracle.latestRoundData();

        assertEq(roundId, 1);
        assertEq(answer, INITIAL_UP_PRICE);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);

        // Check latestAnswer
        assertEq(fixedPriceOracle.latestAnswer(), uint256(INITIAL_UP_PRICE));

        // Check owner
        assertEq(fixedPriceOracle.owner(), owner);
    }

    /// @notice Test price update by owner
    function test_FixedPriceOracle_SetPrice() public {
        int256 newPrice = 0.10e18; // $0.10

        fixedPriceOracle.setPrice(newPrice);

        (, int256 answer,,,) = fixedPriceOracle.latestRoundData();
        assertEq(answer, newPrice);
    }

    /// @notice Test that non-owner cannot set price
    function test_FixedPriceOracle_SetPrice_RevertNonOwner() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        fixedPriceOracle.setPrice(0.10e18);
    }

    /// @notice Test that zero/negative price cannot be set
    function test_FixedPriceOracle_SetPrice_RevertInvalidPrice() public {
        vm.expectRevert(FixedPriceOracle.INVALID_PRICE.selector);
        fixedPriceOracle.setPrice(0);

        vm.expectRevert(FixedPriceOracle.INVALID_PRICE.selector);
        fixedPriceOracle.setPrice(-1);
    }

    /// @notice Test decimals update by owner
    function test_FixedPriceOracle_SetDecimals() public {
        uint8 newDecimals = 8;

        fixedPriceOracle.setDecimals(newDecimals);

        assertEq(fixedPriceOracle.decimals(), newDecimals);
    }

    /// @notice Test staleness - FixedPriceOracle should never be stale
    function test_FixedPriceOracle_NeverStale() public {
        // Record initial timestamp
        uint256 initialTimestamp = block.timestamp;

        // Warp time forward significantly (1 year)
        vm.warp(initialTimestamp + 365 days);

        // latestRoundData should return current timestamp (not stale)
        (, int256 answer, uint256 startedAt, uint256 updatedAt, ) = fixedPriceOracle.latestRoundData();

        assertEq(answer, INITIAL_UP_PRICE, "Price should remain the same");
        assertEq(startedAt, block.timestamp, "startedAt should be current timestamp");
        assertEq(updatedAt, block.timestamp, "updatedAt should be current timestamp (never stale)");

        // getTimestamp should also return current timestamp
        assertEq(fixedPriceOracle.getTimestamp(1), block.timestamp);
    }

    /// @notice Test getRoundData returns same as latestRoundData
    function test_FixedPriceOracle_GetRoundData() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            fixedPriceOracle.getRoundData(42); // Any round ID

        assertEq(roundId, 42); // Returns the requested round ID
        assertEq(answer, INITIAL_UP_PRICE);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 42);
    }

    /// @notice Test other Chainlink interface functions
    function test_FixedPriceOracle_ChainlinkInterface() public view {
        assertEq(fixedPriceOracle.description(), "Fixed Price Oracle");
        assertEq(fixedPriceOracle.version(), 1);
        assertEq(fixedPriceOracle.phaseId(), 1);
        assertEq(fixedPriceOracle.phaseAggregators(1), address(fixedPriceOracle));
        assertEq(fixedPriceOracle.phaseAggregators(2), address(0));
    }

    /// @notice Test price calculation example - simulating what _convertGasToUp would do
    function test_FixedPriceOracle_PriceCalculationExample() public view {
        // This test demonstrates how the oracle would be used in price calculations
        // Simulating: 10k gas at 30 gwei with ETH=$2500 -> how many UP tokens at $0.09?

        uint256 gasAmount = 10_000;
        uint256 gasPriceWei = 30e9; // 30 gwei
        uint256 ethUsdPrice = 2500e18; // $2500 with 18 decimals for consistency

        // Step 1: Gas to Wei
        uint256 weiAmount = gasAmount * gasPriceWei; // 3e14 wei = 0.0003 ETH

        // Step 2: Wei to USD (using 18 decimals)
        uint256 usdAmount = (weiAmount * ethUsdPrice) / 1e18; // $0.75 with 18 decimals

        // Step 3: USD to UP using FixedPriceOracle
        (, int256 upPricePerToken,,,) = fixedPriceOracle.latestRoundData();
        // upPricePerToken = 0.09e18 (price of 1 UP in USD)
        // requiredUp = usdAmount / upPricePerToken
        uint256 requiredUpTokens = (usdAmount * 1e18) / uint256(upPricePerToken);

        console2.log("=== Price Calculation Example ===");
        console2.log("");
        console2.log("Input: 10,000 gas units at 30 gwei");
        console2.log("");
        console2.log("Step 1 - Gas to Wei:");
        console2.log("  Wei amount: %s (0.0003 ETH)", weiAmount);
        console2.log("");
        console2.log("Step 2 - Wei to USD (ETH=$2500):");
        console2.log("  USD amount: %s (with 18 decimals)", usdAmount);
        uint256 usdWhole = usdAmount / 1e18;
        uint256 usdCents = (usdAmount % 1e18) / 1e16;
        console2.log("  USD value: $%s.%s", usdWhole, usdCents);
        console2.log("");
        console2.log("Step 3 - USD to UP (UP=$0.09):");
        console2.log("  UP price from oracle: %s", uint256(upPricePerToken));
        console2.log("  Required UP tokens: %s (with 18 decimals)", requiredUpTokens);
        uint256 upWhole = requiredUpTokens / 1e18;
        uint256 upFrac = (requiredUpTokens % 1e18) / 1e14;
        console2.log("  Required UP: %s.%s UP", upWhole, upFrac);
        console2.log("");

        // Verify the calculation
        // $0.75 / $0.09 = 8.333... UP tokens
        // With 18 decimals: 0.75e18 / 0.09e18 * 1e18 = 8.333...e18
        assertGt(requiredUpTokens, 8e18, "Should need more than 8 UP tokens");
        assertLt(requiredUpTokens, 9e18, "Should need less than 9 UP tokens");

        // Calculate and log the dollar value verification
        uint256 dollarValue = (requiredUpTokens * uint256(upPricePerToken)) / 1e18;
        console2.log("--- Verification ---");
        console2.log("Dollar value of UP tokens: %s (should be ~0.75e18)", dollarValue);
    }

    /// @notice Test with different UP prices to understand token economics
    function test_FixedPriceOracle_DifferentPrices() public {
        console2.log("=== UP Token Cost at Different Prices ===");
        console2.log("(For 10k gas at 30 gwei, ETH=$2500 = $0.75 cost)");
        console2.log("");

        int256[] memory prices = new int256[](5);
        prices[0] = 0.05e18;  // $0.05
        prices[1] = 0.09e18;  // $0.09
        prices[2] = 0.10e18;  // $0.10
        prices[3] = 0.50e18;  // $0.50
        prices[4] = 1.00e18;  // $1.00

        uint256 usdCost = 0.75e18; // $0.75 in 18 decimals

        for (uint256 i = 0; i < prices.length; i++) {
            // Update UP price
            fixedPriceOracle.setPrice(prices[i]);

            // Calculate required UP tokens
            uint256 requiredUp = (usdCost * 1e18) / uint256(prices[i]);

            uint256 priceInCents = uint256(prices[i]) / 1e16;
            uint256 upWhole = requiredUp / 1e18;
            uint256 upFrac = (requiredUp % 1e18) / 1e14;

            console2.log("UP Price: $0.%s", priceInCents);
            console2.log("  UP tokens needed: %s.%s", upWhole, upFrac);
            console2.log("");
        }
    }
}
