// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperformGasOracle } from "../../src/oracles/SuperformGasOracle.sol";

/// @title SuperformGasOracleTest
/// @notice Unit tests for SuperformGasOracle - Chainlink compatible gas price oracle
contract SuperformGasOracleTest is Test {
    SuperformGasOracle public gasOracle;
    address public owner;

    // Test constants
    int256 constant INITIAL_GAS_PRICE = 30; // 30 Gwei

    // Events
    event GasPriceUpdated(int256 oldGasPrice, int256 newGasPrice);

    function setUp() public {
        owner = address(this);
        gasOracle = new SuperformGasOracle(INITIAL_GAS_PRICE, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test constructor initializes state correctly
    function test_Constructor_InitializesCorrectly() public view {
        assertEq(gasOracle.decimals(), 0);
        assertEq(gasOracle.description(), "Superform Fast Gas / Gwei");
        assertEq(gasOracle.version(), 1);
        assertEq(gasOracle.owner(), owner);
        assertEq(gasOracle.latestAnswer(), INITIAL_GAS_PRICE);
    }

    /// @notice Test constructor sets initial round data correctly
    function test_Constructor_SetsInitialRoundData() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            gasOracle.latestRoundData();

        assertEq(roundId, 1);
        assertEq(answer, INITIAL_GAS_PRICE);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }

    /// @notice Test constructor reverts with zero gas price
    function test_Constructor_RevertsOnZeroPrice() public {
        vm.expectRevert(SuperformGasOracle.INVALID_GAS_PRICE.selector);
        new SuperformGasOracle(0, owner);
    }

    /// @notice Test constructor reverts with negative gas price
    function test_Constructor_RevertsOnNegativePrice() public {
        vm.expectRevert(SuperformGasOracle.INVALID_GAS_PRICE.selector);
        new SuperformGasOracle(-1, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            SET GAS PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test gas price update by owner
    function test_SetGasPrice_UpdatesPrice() public {
        int256 newGasPrice = 50; // 50 Gwei

        gasOracle.setGasPrice(newGasPrice);

        assertEq(gasOracle.latestAnswer(), newGasPrice);
    }

    /// @notice Test gas price update increments round ID
    function test_SetGasPrice_IncrementsRoundId() public {
        // Initial round ID is 1
        (uint80 initialRoundId,,,,) = gasOracle.latestRoundData();
        assertEq(initialRoundId, 1);

        // Update price
        gasOracle.setGasPrice(40);

        (uint80 newRoundId,,,,) = gasOracle.latestRoundData();
        assertEq(newRoundId, 2);

        // Update again
        gasOracle.setGasPrice(50);

        (uint80 finalRoundId,,,,) = gasOracle.latestRoundData();
        assertEq(finalRoundId, 3);
    }

    /// @notice Test gas price update sets correct timestamp
    function test_SetGasPrice_UpdatesTimestamp() public {
        uint256 initialTime = block.timestamp;

        // Warp time forward
        vm.warp(initialTime + 1 hours);

        gasOracle.setGasPrice(40);

        (,, uint256 startedAt, uint256 updatedAt,) = gasOracle.latestRoundData();
        assertEq(startedAt, initialTime + 1 hours);
        assertEq(updatedAt, initialTime + 1 hours);
    }

    /// @notice Test gas price update emits event
    function test_SetGasPrice_EmitsEvent() public {
        int256 newGasPrice = 50;

        vm.expectEmit(true, true, false, true);
        emit GasPriceUpdated(INITIAL_GAS_PRICE, newGasPrice);

        gasOracle.setGasPrice(newGasPrice);
    }

    /// @notice Test that non-owner cannot set gas price
    function test_SetGasPrice_RevertsNonOwner() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        gasOracle.setGasPrice(50);
    }

    /// @notice Test that zero gas price cannot be set
    function test_SetGasPrice_RevertsOnZeroPrice() public {
        vm.expectRevert(SuperformGasOracle.INVALID_GAS_PRICE.selector);
        gasOracle.setGasPrice(0);
    }

    /// @notice Test that negative gas price cannot be set
    function test_SetGasPrice_RevertsOnNegativePrice() public {
        vm.expectRevert(SuperformGasOracle.INVALID_GAS_PRICE.selector);
        gasOracle.setGasPrice(-1);
    }

    /*//////////////////////////////////////////////////////////////
                        AGGREGATOR INTERFACE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test latestRoundData returns correct values
    function test_LatestRoundData_ReturnsCorrectValues() public {
        // Update price to have different values
        vm.warp(block.timestamp + 1 hours);
        gasOracle.setGasPrice(45);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            gasOracle.latestRoundData();

        assertEq(roundId, 2);
        assertEq(answer, 45);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 2);
    }

    /// @notice Test getRoundData returns current data (oracle only stores latest)
    function test_GetRoundData_ReturnsCurrentData() public view {
        // getRoundData should return current data regardless of roundId requested
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            gasOracle.getRoundData(999);

        // Should return current round data, not round 999
        assertEq(roundId, 1);
        assertEq(answer, INITIAL_GAS_PRICE);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }

    /// @notice Test latestAnswer returns correct value
    function test_LatestAnswer_ReturnsCorrectValue() public view {
        assertEq(gasOracle.latestAnswer(), INITIAL_GAS_PRICE);
    }

    /// @notice Test decimals returns 0 (Gwei)
    function test_Decimals_ReturnsZero() public view {
        assertEq(gasOracle.decimals(), 0);
    }

    /// @notice Test description returns correct string
    function test_Description_ReturnsCorrectString() public view {
        assertEq(gasOracle.description(), "Superform Fast Gas / Gwei");
    }

    /// @notice Test version returns 1
    function test_Version_ReturnsOne() public view {
        assertEq(gasOracle.version(), 1);
    }

    /*//////////////////////////////////////////////////////////////
                            STALENESS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that updatedAt reflects actual update time (not block.timestamp)
    function test_Staleness_TracksActualUpdateTime() public {
        uint256 updateTime = block.timestamp;

        // Warp time forward significantly (1 day)
        vm.warp(updateTime + 1 days);

        // updatedAt should still be the original update time
        (,, uint256 startedAt, uint256 updatedAt,) = gasOracle.latestRoundData();

        assertEq(startedAt, updateTime, "startedAt should be original deployment time");
        assertEq(updatedAt, updateTime, "updatedAt should be original deployment time");
        assertLt(updatedAt, block.timestamp, "updatedAt should be less than current time");
    }

    /// @notice Test staleness detection scenario
    function test_Staleness_CanDetectStalePrice() public {
        uint256 maxStaleness = 1 hours;
        uint256 initialTime = block.timestamp;

        // Price is fresh
        (,,, uint256 updatedAt,) = gasOracle.latestRoundData();
        assertGe(updatedAt + maxStaleness, block.timestamp, "Price should be fresh");

        // Warp time forward beyond staleness threshold
        vm.warp(initialTime + 2 hours);

        // Price is now stale
        (,,, updatedAt,) = gasOracle.latestRoundData();
        assertLt(updatedAt + maxStaleness, block.timestamp, "Price should be stale");

        // Update price - should be fresh again
        gasOracle.setGasPrice(35);
        (,,, updatedAt,) = gasOracle.latestRoundData();
        assertGe(updatedAt + maxStaleness, block.timestamp, "Price should be fresh after update");
    }

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test ownership transfer
    function test_TransferOwnership() public {
        address newOwner = makeAddr("newOwner");

        // Initial owner is this contract
        assertEq(gasOracle.owner(), owner);

        // Transfer ownership
        gasOracle.transferOwnership(newOwner);

        // Verify new owner
        assertEq(gasOracle.owner(), newOwner);

        // Old owner can no longer set gas price
        vm.expectRevert();
        gasOracle.setGasPrice(100);

        // New owner can set gas price
        vm.prank(newOwner);
        gasOracle.setGasPrice(100);

        assertEq(gasOracle.latestAnswer(), 100);
    }

    /// @notice Test that non-owner cannot transfer ownership
    function test_TransferOwnership_RevertsNonOwner() public {
        address nonOwner = makeAddr("nonOwner");
        address newOwner = makeAddr("newOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        gasOracle.transferOwnership(newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fuzz test for setGasPrice with valid prices
    function testFuzz_SetGasPrice_ValidPrices(int256 gasPrice) public {
        vm.assume(gasPrice > 0);

        gasOracle.setGasPrice(gasPrice);
        assertEq(gasOracle.latestAnswer(), gasPrice);
    }

    /// @notice Fuzz test for multiple updates
    function testFuzz_MultipleUpdates(uint8 updateCount) public {
        vm.assume(updateCount > 0 && updateCount <= 100);

        for (uint8 i = 1; i <= updateCount; i++) {
            gasOracle.setGasPrice(int256(uint256(i) * 10));
        }

        (uint80 roundId, int256 answer,,, uint80 answeredInRound) = gasOracle.latestRoundData();

        assertEq(roundId, uint80(updateCount) + 1); // +1 for initial round
        assertEq(answer, int256(uint256(updateCount) * 10));
        assertEq(answeredInRound, uint80(updateCount) + 1);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION EXAMPLE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test gas cost calculation example
    function test_GasCostCalculation_Example() public view {
        // Simulate calculating upkeep cost in USD
        // Gas price: 30 Gwei
        // Gas used: 135,000 (GAS_PER_ENTRY constant)
        // ETH price: $2,500

        int256 gasPrice = gasOracle.latestAnswer(); // 30 Gwei
        uint256 gasUsed = 135_000;
        uint256 ethPriceUsd = 2500e18; // $2,500 with 18 decimals

        // Calculate cost in wei: gasUsed * gasPrice * 1e9 (convert Gwei to Wei)
        uint256 costInWei = gasUsed * uint256(gasPrice) * 1e9;

        // Calculate cost in USD: (costInWei * ethPriceUsd) / 1e18
        uint256 costInUsd = (costInWei * ethPriceUsd) / 1e18;

        console2.log("=== Gas Cost Calculation Example ===");
        console2.log("Gas price (Gwei):", uint256(gasPrice));
        console2.log("Gas used:", gasUsed);
        console2.log("ETH price: $2,500");
        console2.log("");
        console2.log("Cost in Wei:", costInWei);
        console2.log("Cost in ETH:", costInWei / 1e18, ".", (costInWei % 1e18) / 1e14);
        console2.log("Cost in USD (18 decimals):", costInUsd);
        console2.log("Cost in USD: $", costInUsd / 1e18, ".", (costInUsd % 1e18) / 1e16);

        // 135,000 * 30 * 1e9 = 4.05e15 wei = 0.00405 ETH
        // 0.00405 ETH * $2,500 = $10.125
        assertEq(costInWei, 4.05e15);
        assertGt(costInUsd, 10e18); // > $10
        assertLt(costInUsd, 11e18); // < $11
    }
}
