// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { FixedPriceOracle } from "../../../src/oracles/FixedPriceOracle.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";

/// @title MockChainlinkUpOracle
/// @notice A mock Chainlink-compatible oracle that returns $1 per UP token
/// @dev Simulates what a real Chainlink UP/USD feed would look like
contract MockChainlinkUpOracle {
    int256 private _answer;
    uint8 private _decimals;

    constructor(int256 initialPrice, uint8 decimals_) {
        _answer = initialPrice;
        _decimals = decimals_;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function description() external pure returns (string memory) {
        return "UP / USD";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, _answer, block.timestamp, block.timestamp, 1);
    }

    function setPrice(int256 newPrice) external {
        _answer = newPrice;
    }
}

/// @title UpOracleUpdateIntegrationTest
/// @notice Integration test for updating the UP token price oracle from FixedPriceOracle to a new Chainlink oracle
/// @dev Tests the full flow:
///      1. Fork mainnet with real deployed contracts
///      2. Deploy a new mock Chainlink oracle returning $1/UP
///      3. Queue the oracle update via SuperGovernor
///      4. Wait for timelock and execute the update
///      5. Verify getQuoteFromProvider returns new price
///      6. Simulate upkeep payment computation with new oracle
contract UpOracleUpdateIntegrationTest is Test {
    // Production addresses from Ethereum-latest.json
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant SUPER_ORACLE = 0x8943128DbAb4279D561654dEED2930Bb975AA070;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;

    // Chainlink oracle addresses (from trace analysis)
    address constant CHAINLINK_GAS_ORACLE = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;
    address constant CHAINLINK_ETH_USD_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // UP token address on mainnet (from SuperGovernor registry)
    // We'll fetch this dynamically from the governor
    address public upToken;

    // Oracle constants (must match SuperGovernor)
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // Provider identifiers
    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // New UP price: $1 with 18 decimals (matches FixedPriceOracle format)
    int256 constant NEW_UP_PRICE = 1e18; // $1.00
    uint8 constant UP_PRICE_DECIMALS = 18;

    // Timelock period (must match SuperOracleBase)
    uint256 constant TIMELOCK_PERIOD = 1 weeks;

    // Contracts
    SuperGovernor public governor;
    SuperOracle public superOracle;
    MockChainlinkUpOracle public newChainlinkOracle;

    // Test accounts - we'll impersonate the actual roles
    address public oracleManager;
    address public superGovernorRole;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        // Back off the chain tip: forking at "latest" against a load-balanced RPC can pin a
        // lagging block while feeds' updatedAt come from head, underflowing SuperOracle's
        // staleness check (block.timestamp - updatedAt). 32 blocks is within every full
        // node's recent-state window, so no archive access is needed.
        vm.rollFork(block.number - 32);

        // Load production contracts
        governor = SuperGovernor(SUPER_GOVERNOR);
        superOracle = SuperOracle(SUPER_ORACLE);

        // Get UP token address from governor registry
        upToken = governor.getAddress(governor.UP());

        // Get role holders from governor
        // We need to find accounts with the appropriate roles
        // For testing, we'll use the default admin which has all roles
        superGovernorRole = _findRoleHolder(governor.SUPER_GOVERNOR_ROLE());
        oracleManager = _findRoleHolder(governor.ORACLE_MANAGER_ROLE());

        console2.log("=== Production Contract Addresses ===");
        console2.log("SuperGovernor:", address(governor));
        console2.log("SuperOracle:", address(superOracle));
        console2.log("Current FixedPriceOracle:", FIXED_PRICE_ORACLE);
        console2.log("UP Token:", upToken);
        console2.log("Oracle Manager:", oracleManager);
        console2.log("Super Governor Role:", superGovernorRole);

        // Deploy new mock Chainlink oracle for UP/USD at $1
        newChainlinkOracle = new MockChainlinkUpOracle(NEW_UP_PRICE, UP_PRICE_DECIMALS);
        console2.log("New Mock Chainlink Oracle deployed at:", address(newChainlinkOracle));
    }

    /// @notice Helper to find an account with a specific role
    /// @dev Uses vm.store to grant the role directly via storage manipulation
    function _findRoleHolder(bytes32 role) internal returns (address) {
        // Create a test address and grant it the role via storage manipulation
        // This works because we're in a fork test
        address testRoleHolder = makeAddr("roleHolder");

        // Grant the role using vm.store
        _grantRoleViaStorage(role, testRoleHolder);

        return testRoleHolder;
    }

    /// @notice Grant a role by directly manipulating storage
    /// @dev This works because we're in a fork test
    function _grantRoleViaStorage(bytes32 role, address account) internal {
        // AccessControl stores roles in: _roles[role].members[account] = true
        // RoleData struct is: { mapping(address => bool) members; bytes32 adminRole; }
        // Location: keccak256(account . keccak256(role . slot))
        // where slot = 0 for _roles mapping

        // First compute the slot for _roles[role]
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        // Then compute the slot for _roles[role].members[account]
        bytes32 memberSlot = keccak256(abi.encode(account, roleSlot));

        // Set the value to true (1)
        vm.store(address(governor), memberSlot, bytes32(uint256(1)));

        // Verify it worked
        require(governor.hasRole(role, account), "Failed to grant role via storage");
    }

    /// @notice Test querying current UP price from FixedPriceOracle
    function test_CurrentUpPrice() public view {
        console2.log("\n=== Current UP Price Test ===");

        // Get current UP/USD price using the SUPERFORM provider
        (uint256 quoteAmount, uint256 deviation, uint256 totalProviders, uint256 availableProviders) =
            superOracle.getQuoteFromProvider(1e18, upToken, USD_TOKEN, PROVIDER_SUPERFORM);

        console2.log("Quote for 1 UP (1e18 wei) in USD:");
        console2.log("  Quote amount (USD):", quoteAmount);
        console2.log("  Deviation:", deviation);
        console2.log("  Total providers:", totalProviders);
        console2.log("  Available providers:", availableProviders);

        // The current FixedPriceOracle should return the configured price
        assertGt(quoteAmount, 0, "UP price should be > 0");
    }

    /// @notice Test the full oracle update flow
    function test_UpdateUpOracleToChainlink() public {
        console2.log("\n=== Oracle Update Flow Test ===");

        // Step 1: Get current price before update
        (uint256 oldQuote,,,) = superOracle.getQuoteFromProvider(1e18, upToken, USD_TOKEN, PROVIDER_SUPERFORM);
        console2.log("Step 1: Current UP price (for 1 UP):", oldQuote);

        // Step 2: Queue oracle update via SuperGovernor
        console2.log("\nStep 2: Queueing oracle update...");
        _queueOracleUpdate();

        // Note: pendingUpdate struct with dynamic arrays can't be easily retrieved via the auto-generated getter
        // We'll verify the update was queued by checking OracleUpdateQueued event or by executing and verifying
        console2.log("  Oracle update queued successfully");

        // Step 3: Warp time past timelock
        console2.log("\nStep 3: Warping time past 1 week timelock...");
        vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);

        // Step 4: Execute oracle update
        console2.log("\nStep 4: Executing oracle update...");
        _executeOracleUpdate();

        // Step 5: Verify new oracle is active
        console2.log("\nStep 5: Verifying new oracle...");
        address configuredOracle = superOracle.getOracleAddress(upToken, USD_TOKEN, PROVIDER_SUPERFORM);
        assertEq(configuredOracle, address(newChainlinkOracle), "Oracle should be updated to new Chainlink oracle");
        console2.log("  Configured oracle for UP/USD:", configuredOracle);

        // Step 6: Query new price
        (uint256 newQuote,,,) = superOracle.getQuoteFromProvider(1e18, upToken, USD_TOKEN, PROVIDER_SUPERFORM);
        console2.log("\nStep 6: New UP price query result:");
        console2.log("  Old price (for 1 UP):", oldQuote);
        console2.log("  New price (for 1 UP):", newQuote);

        // With $1/UP and 18 decimals input, we expect ~1e6 output (USD has 6 decimals typically)
        // But since USD_TOKEN is synthetic (address 840), it uses 8 decimals by convention
        assertGt(newQuote, 0, "New quote should be > 0");
    }

    /// @notice Test upkeep payment computation with the new oracle
    function test_UpkeepComputationWithNewOracle() public {
        console2.log("\n=== Upkeep Computation Test ===");

        // First update the oracle
        _queueOracleUpdate();
        vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
        _executeOracleUpdate();

        // Set staleness for ALL feeds (including Chainlink feeds which become stale after time warp)
        _setAllFeedsMaxStaleness(30 days);

        // Get upkeep cost with new oracle
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        console2.log("Upkeep cost per single update (in UP tokens):", upkeepCost);

        // With $1/UP, the upkeep cost should be roughly:
        // gas_cost_in_usd / 1 = gas_cost_in_up_tokens
        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");

        // Log the breakdown
        console2.log("\n=== Upkeep Cost Breakdown ===");
        console2.log("ECDSA PPS Oracle:", ECDSA_PPS_ORACLE);
        console2.log("Gas per entry:", governor.getGasInfo(ECDSA_PPS_ORACLE));
        console2.log("Upkeep cost in UP tokens:", upkeepCost);
    }

    /// @notice Test comparing old vs new oracle upkeep costs
    function test_CompareUpkeepCosts() public {
        console2.log("\n=== Compare Upkeep Costs: Old vs New Oracle ===");

        // Get upkeep cost with OLD oracle (FixedPriceOracle)
        uint256 oldUpkeepCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost with OLD oracle (FixedPriceOracle):", oldUpkeepCost);

        // Update to new oracle
        _queueOracleUpdate();
        vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
        _executeOracleUpdate();

        // Set staleness for ALL feeds (including Chainlink feeds which become stale after time warp)
        _setAllFeedsMaxStaleness(30 days);

        // Get upkeep cost with NEW oracle (MockChainlinkUpOracle @ $1)
        uint256 newUpkeepCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost with NEW oracle ($1/UP):", newUpkeepCost);

        // Calculate difference
        if (newUpkeepCost > oldUpkeepCost) {
            console2.log("Cost INCREASED by:", newUpkeepCost - oldUpkeepCost);
            console2.log("Percentage increase:", ((newUpkeepCost - oldUpkeepCost) * 100) / oldUpkeepCost, "%");
        } else if (newUpkeepCost < oldUpkeepCost) {
            console2.log("Cost DECREASED by:", oldUpkeepCost - newUpkeepCost);
            console2.log("Percentage decrease:", ((oldUpkeepCost - newUpkeepCost) * 100) / oldUpkeepCost, "%");
        } else {
            console2.log("Cost unchanged");
        }
    }

    /// @notice Test that price changes in the new oracle affect upkeep computation
    function test_PriceChangeAffectsUpkeep() public {
        console2.log("\n=== Price Change Effect on Upkeep Test ===");

        // Update to new oracle
        _queueOracleUpdate();
        vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
        _executeOracleUpdate();

        // Set staleness for ALL feeds (including Chainlink feeds which become stale after time warp)
        _setAllFeedsMaxStaleness(30 days);

        // Get upkeep at $1/UP
        uint256 upkeepAt1Dollar = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost at $1/UP:", upkeepAt1Dollar);

        // Change price to $2/UP
        newChainlinkOracle.setPrice(2e18);
        uint256 upkeepAt2Dollars = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost at $2/UP:", upkeepAt2Dollars);

        // Change price to $0.50/UP
        newChainlinkOracle.setPrice(0.5e18);
        uint256 upkeepAtHalfDollar = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost at $0.50/UP:", upkeepAtHalfDollar);

        // Verify inverse relationship: higher UP price = fewer UP tokens needed for same USD cost
        assertTrue(upkeepAt2Dollars < upkeepAt1Dollar, "Higher UP price should mean lower UP token cost");
        assertTrue(upkeepAtHalfDollar > upkeepAt1Dollar, "Lower UP price should mean higher UP token cost");

        // Verify approximate 2x relationship
        // At $2/UP, should need ~half the tokens; at $0.50/UP, should need ~2x tokens
        console2.log("\nRatio checks:");
        console2.log("upkeepAt1Dollar / upkeepAt2Dollars:", upkeepAt1Dollar * 100 / upkeepAt2Dollars, "% (expect ~200%)");
        console2.log(
            "upkeepAtHalfDollar / upkeepAt1Dollar:", upkeepAtHalfDollar * 100 / upkeepAt1Dollar, "% (expect ~200%)"
        );
    }

    /// @notice Internal helper to queue oracle update
    function _queueOracleUpdate() internal {
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = upToken;
        quotes[0] = USD_TOKEN;
        providers[0] = PROVIDER_SUPERFORM; // Keep using SUPERFORM provider
        feeds[0] = address(newChainlinkOracle);

        vm.prank(oracleManager);
        governor.queueOracleUpdate(bases, quotes, providers, feeds);
    }

    /// @notice Internal helper to execute oracle update
    function _executeOracleUpdate() internal {
        vm.prank(oracleManager);
        governor.executeOracleUpdate();
    }

    /// @notice Helper to set staleness for all feeds after time warp
    /// @dev This is needed because warping time makes Chainlink oracle data appear stale
    function _setAllFeedsMaxStaleness(uint256 staleness) internal {
        vm.startPrank(oracleManager);

        // First set default staleness
        governor.setOracleMaxStaleness(staleness);

        // Set staleness for all feeds
        address[] memory feeds = new address[](4);
        feeds[0] = address(newChainlinkOracle); // New UP oracle
        feeds[1] = CHAINLINK_GAS_ORACLE; // GAS -> WEI
        feeds[2] = CHAINLINK_ETH_USD_ORACLE; // ETH -> USD
        feeds[3] = FIXED_PRICE_ORACLE; // Old FixedPriceOracle (might still be checked)

        uint256[] memory stalenesses = new uint256[](4);
        stalenesses[0] = staleness;
        stalenesses[1] = staleness;
        stalenesses[2] = staleness;
        stalenesses[3] = staleness;

        governor.setOracleFeedMaxStalenessBatch(feeds, stalenesses);

        vm.stopPrank();
    }
}
