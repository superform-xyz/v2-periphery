// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { SuperformGasOracle } from "../../src/oracles/SuperformGasOracle.sol";

/// @title SuperformGasOracleTest
/// @notice Unit tests for SuperformGasOracle - Chainlink compatible gas price oracle
contract SuperformGasOracleTest is Test {
    SuperformGasOracle public gasOracle;
    address public admin;

    // Test constants (0 decimals - value directly in Gwei)
    int256 constant INITIAL_GAS_PRICE = 1_000_000;

    // Roles
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    // Events
    event GasPriceUpdated(int256 oldGasPrice, int256 newGasPrice);
    event UseBlockTimestampChanged(bool enabled);

    function setUp() public {
        admin = address(this);
        gasOracle = new SuperformGasOracle(INITIAL_GAS_PRICE, admin);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test constructor initializes state correctly
    function test_Constructor_InitializesCorrectly() public view {
        assertEq(gasOracle.decimals(), 0);
        assertEq(gasOracle.description(), "Superform Fast Gas / Gwei");
        assertEq(gasOracle.version(), 1);
        assertTrue(gasOracle.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(gasOracle.hasRole(KEEPER_ROLE, admin));
        assertEq(gasOracle.latestAnswer(), INITIAL_GAS_PRICE);
        assertTrue(gasOracle.useBlockTimestamp());
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
        new SuperformGasOracle(0, admin);
    }

    /// @notice Test constructor reverts with negative gas price
    function test_Constructor_RevertsOnNegativePrice() public {
        vm.expectRevert(SuperformGasOracle.INVALID_GAS_PRICE.selector);
        new SuperformGasOracle(-1, admin);
    }

    /*//////////////////////////////////////////////////////////////
                            SET GAS PRICE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test gas price update by admin (who has KEEPER_ROLE)
    function test_SetGasPrice_UpdatesPrice() public {
        int256 newGasPrice = 50;

        gasOracle.setGasPrice(newGasPrice);

        assertEq(gasOracle.latestAnswer(), newGasPrice);
    }

    /// @notice Test gas price update by keeper
    function test_SetGasPrice_UpdatesPriceByKeeper() public {
        address keeper = makeAddr("keeper");

        // Grant keeper role
        gasOracle.grantRole(KEEPER_ROLE, keeper);

        // Keeper updates price
        vm.prank(keeper);
        gasOracle.setGasPrice(2_000_000);

        assertEq(gasOracle.latestAnswer(), 2_000_000);
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
        // Set a known starting timestamp
        uint256 startTime = 1000;
        vm.warp(startTime);

        // Deploy fresh oracle at known time
        SuperformGasOracle freshOracle = new SuperformGasOracle(INITIAL_GAS_PRICE, admin);

        // Warp time forward
        vm.warp(startTime + 1 hours);

        freshOracle.setGasPrice(40);

        (,, uint256 startedAt, uint256 updatedAt,) = freshOracle.latestRoundData();
        assertEq(startedAt, startTime + 1 hours);
        assertEq(updatedAt, startTime + 1 hours);
    }

    /// @notice Test gas price update emits event
    function test_SetGasPrice_EmitsEvent() public {
        int256 newGasPrice = 50;

        vm.expectEmit(true, true, false, true);
        emit GasPriceUpdated(INITIAL_GAS_PRICE, newGasPrice);

        gasOracle.setGasPrice(newGasPrice);
    }

    /// @notice Test that non-keeper cannot set gas price
    function test_SetGasPrice_RevertsNonKeeper() public {
        address nonKeeper = makeAddr("nonKeeper");

        vm.prank(nonKeeper);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonKeeper, KEEPER_ROLE)
        );
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

    /// @notice Test decimals returns 0 (Gwei precision)
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

    /// @notice Test that updatedAt reflects actual update time when useBlockTimestamp is false
    function test_Staleness_TracksActualUpdateTime() public {
        // Set a known starting timestamp
        uint256 deployTime = 1000;
        vm.warp(deployTime);

        // Deploy fresh oracle at known time
        SuperformGasOracle freshOracle = new SuperformGasOracle(INITIAL_GAS_PRICE, admin);

        // Disable useBlockTimestamp to test stored timestamp behavior
        freshOracle.setUseBlockTimestamp(false);

        // Warp time forward significantly (1 day)
        vm.warp(deployTime + 1 days);

        // updatedAt should still be the original deployment time
        (,, uint256 startedAt, uint256 updatedAt,) = freshOracle.latestRoundData();

        assertEq(startedAt, deployTime, "startedAt should be original deployment time");
        assertEq(updatedAt, deployTime, "updatedAt should be original deployment time");
        assertLt(updatedAt, block.timestamp, "updatedAt should be less than current time");
    }

    /// @notice Test staleness detection scenario when useBlockTimestamp is false
    function test_Staleness_CanDetectStalePrice() public {
        uint256 maxStaleness = 1 hours;
        uint256 initialTime = block.timestamp;

        // Disable useBlockTimestamp to test staleness detection
        gasOracle.setUseBlockTimestamp(false);

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
                        USE BLOCK TIMESTAMP TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test setUseBlockTimestamp by keeper
    function test_SetUseBlockTimestamp_ToggledByKeeper() public {
        assertTrue(gasOracle.useBlockTimestamp());

        gasOracle.setUseBlockTimestamp(false);
        assertFalse(gasOracle.useBlockTimestamp());

        gasOracle.setUseBlockTimestamp(true);
        assertTrue(gasOracle.useBlockTimestamp());
    }

    /// @notice Test that non-keeper cannot set useBlockTimestamp
    function test_SetUseBlockTimestamp_RevertsNonKeeper() public {
        address nonKeeper = makeAddr("nonKeeper");

        vm.prank(nonKeeper);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonKeeper, KEEPER_ROLE)
        );
        gasOracle.setUseBlockTimestamp(true);
    }

    /// @notice Test setUseBlockTimestamp emits event
    function test_SetUseBlockTimestamp_EmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit UseBlockTimestampChanged(true);
        gasOracle.setUseBlockTimestamp(true);

        vm.expectEmit(true, true, false, true);
        emit UseBlockTimestampChanged(false);
        gasOracle.setUseBlockTimestamp(false);
    }

    /// @notice Test that useBlockTimestamp flag controls timestamp behavior
    function test_UseBlockTimestamp_ControlsTimestampBehavior() public {
        // Set a known starting timestamp
        uint256 deployTime = 1000;
        vm.warp(deployTime);

        // Deploy fresh oracle at known time
        SuperformGasOracle freshOracle = new SuperformGasOracle(INITIAL_GAS_PRICE, admin);

        // Warp forward
        vm.warp(deployTime + 1 days);

        // With flag enabled (default), should return block.timestamp
        (,, uint256 startedAt, uint256 updatedAt,) = freshOracle.latestRoundData();
        assertEq(startedAt, block.timestamp, "Should return block.timestamp when enabled");
        assertEq(updatedAt, block.timestamp, "Should return block.timestamp when enabled");

        // Disable flag
        freshOracle.setUseBlockTimestamp(false);

        // Without flag, should return stored timestamp
        (,, startedAt, updatedAt,) = freshOracle.latestRoundData();
        assertEq(startedAt, deployTime, "Should return stored timestamp when disabled");
        assertEq(updatedAt, deployTime, "Should return stored timestamp when disabled");
    }

    /// @notice Test useBlockTimestamp prevents staleness (enabled by default)
    function test_UseBlockTimestamp_PreventsStaleness() public {
        uint256 maxStaleness = 1 hours;
        uint256 initialTime = block.timestamp;

        // Warp forward beyond staleness threshold
        vm.warp(initialTime + 2 hours);

        // With flag enabled (default), price appears fresh
        (,,, uint256 updatedAt,) = gasOracle.latestRoundData();
        assertEq(updatedAt, block.timestamp, "Should return current timestamp");
        assertGe(updatedAt + maxStaleness, block.timestamp, "Price should appear fresh");

        // Disable flag
        gasOracle.setUseBlockTimestamp(false);

        // Without flag, price is stale
        (,,, updatedAt,) = gasOracle.latestRoundData();
        assertLt(updatedAt + maxStaleness, block.timestamp, "Price should be stale when disabled");
    }

    /// @notice Test getRoundData also respects useBlockTimestamp flag (enabled by default)
    function test_UseBlockTimestamp_GetRoundData() public {
        // Set a known starting timestamp
        uint256 deployTime = 1000;
        vm.warp(deployTime);

        // Deploy fresh oracle at known time
        SuperformGasOracle freshOracle = new SuperformGasOracle(INITIAL_GAS_PRICE, admin);

        // Warp forward
        vm.warp(deployTime + 1 days);

        // getRoundData should return block.timestamp (flag enabled by default)
        (,, uint256 startedAt, uint256 updatedAt,) = freshOracle.getRoundData(1);
        assertEq(startedAt, block.timestamp, "getRoundData should return block.timestamp");
        assertEq(updatedAt, block.timestamp, "getRoundData should return block.timestamp");

        // Disable flag
        freshOracle.setUseBlockTimestamp(false);

        // getRoundData should now return stored timestamp
        (,, startedAt, updatedAt,) = freshOracle.getRoundData(1);
        assertEq(startedAt, deployTime, "getRoundData should return stored timestamp when disabled");
        assertEq(updatedAt, deployTime, "getRoundData should return stored timestamp when disabled");
    }

    /*//////////////////////////////////////////////////////////////
                            ROLE MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test granting keeper role
    function test_GrantKeeperRole() public {
        address newKeeper = makeAddr("newKeeper");

        // Initially doesn't have keeper role
        assertFalse(gasOracle.hasRole(KEEPER_ROLE, newKeeper));

        // Grant keeper role
        gasOracle.grantRole(KEEPER_ROLE, newKeeper);

        // Now has keeper role
        assertTrue(gasOracle.hasRole(KEEPER_ROLE, newKeeper));

        // New keeper can set gas price
        vm.prank(newKeeper);
        gasOracle.setGasPrice(100);

        assertEq(gasOracle.latestAnswer(), 100);
    }

    /// @notice Test revoking keeper role
    function test_RevokeKeeperRole() public {
        address keeper = makeAddr("keeper");

        // Grant then revoke
        gasOracle.grantRole(KEEPER_ROLE, keeper);
        assertTrue(gasOracle.hasRole(KEEPER_ROLE, keeper));

        gasOracle.revokeRole(KEEPER_ROLE, keeper);
        assertFalse(gasOracle.hasRole(KEEPER_ROLE, keeper));

        // Revoked keeper can no longer set gas price
        vm.prank(keeper);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, keeper, KEEPER_ROLE)
        );
        gasOracle.setGasPrice(100);
    }

    /// @notice Test transferring admin role
    function test_TransferAdminRole() public {
        address newAdmin = makeAddr("newAdmin");

        // Grant admin role to new admin
        gasOracle.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        assertTrue(gasOracle.hasRole(DEFAULT_ADMIN_ROLE, newAdmin));

        // Revoke admin from original
        gasOracle.revokeRole(DEFAULT_ADMIN_ROLE, admin);
        assertFalse(gasOracle.hasRole(DEFAULT_ADMIN_ROLE, admin));

        // Original admin can no longer grant roles
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, admin, DEFAULT_ADMIN_ROLE)
        );
        gasOracle.grantRole(KEEPER_ROLE, makeAddr("someone"));

        // New admin can grant roles
        vm.prank(newAdmin);
        gasOracle.grantRole(KEEPER_ROLE, makeAddr("newKeeper"));
    }

    /// @notice Test that non-admin cannot grant roles
    function test_GrantRole_RevertsNonAdmin() public {
        address nonAdmin = makeAddr("nonAdmin");
        address newKeeper = makeAddr("newKeeper");

        vm.prank(nonAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, DEFAULT_ADMIN_ROLE)
        );
        gasOracle.grantRole(KEEPER_ROLE, newKeeper);
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

    /// @notice Test gas cost calculation example for Base L2
    function test_GasCostCalculation_Example() public view {
        // Simulate calculating upkeep cost in USD on Base
        // Gas price: 1_000_000 Gwei (oracle has 0 decimals, value is directly in Gwei)
        // Gas used: 135,000 (GAS_PER_ENTRY constant)
        // ETH price: $2,500

        int256 gasPrice = gasOracle.latestAnswer(); // 1_000_000 Gwei (0 decimals)
        uint256 gasUsed = 135_000;
        uint256 ethPriceUsd = 2500e18; // $2,500 with 18 decimals

        // Calculate cost in wei: gasUsed * gasPrice (gasPrice is in Gwei, but we use it as wei-per-gas for this example)
        // Note: In production, you'd multiply by 1e9 to convert Gwei to Wei
        // This simplified example treats the raw value as wei-per-gas for demonstration
        uint256 costInWei = gasUsed * uint256(gasPrice);

        // Calculate cost in USD: (costInWei * ethPriceUsd) / 1e18
        uint256 costInUsd = (costInWei * ethPriceUsd) / 1e18;

        console2.log("=== Gas Cost Calculation Example (Base L2) ===");
        console2.log("Gas price (0 decimals, Gwei):", uint256(gasPrice));
        console2.log("Gas used:", gasUsed);
        console2.log("ETH price: $2,500");
        console2.log("");
        console2.log("Cost in Wei:", costInWei);
        console2.log("Cost in USD (18 decimals):", costInUsd);

        // 135,000 * 1_000_000 = 1.35e11 wei
        // 1.35e11 wei * $2,500 / 1e18 = $0.0003375
        assertEq(costInWei, 1.35e11);
        assertGt(costInUsd, 0.0003e18); // > $0.0003
        assertLt(costInUsd, 0.0004e18); // < $0.0004
    }
}
