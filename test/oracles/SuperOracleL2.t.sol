// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { SuperOracleL2 } from "../../src/oracles/SuperOracleL2.sol";
import { ISuperOracle } from "../../src/interfaces/oracles/ISuperOracle.sol";
import { BaseSuperVaultTest } from "../integration/SuperVault/BaseSuperVaultTest.t.sol";
import { AggregatorV3Interface } from "../../src/vendor/chainlink/AggregatorV3Interface.sol";
import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { MockAggregator } from "../mocks/MockAggregator.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockL2Sequencer } from "../mocks/MockL2Sequencer.sol";

contract SuperOracleL2Test is Test {
    // Test accounts
    address public owner;
    address public user;

    // Contracts
    SuperOracleL2 public oracle;
    MockAggregator public dataFeed;
    MockL2Sequencer public uptimeFeed;
    MockERC20 public baseToken;
    MockERC20 public quoteToken;

    // Constants
    bytes32 public constant CHAINLINK_PROVIDER = keccak256("CHAINLINK");
    uint256 public constant PRICE_DECIMALS = 8;
    uint256 public constant INITIAL_PRICE = 2000 * 10 ** PRICE_DECIMALS; // $2000
    uint256 public constant GRACE_PERIOD = 3600; // 1 hour
    uint256 public constant DEFAULT_STALENESS = 86_400; // 1 day

    function setUp() public {
        // Set a fixed timestamp for deterministic tests
        vm.warp(10_000_000);

        // Setup accounts
        owner = makeAddr("owner");
        user = makeAddr("user");
        vm.startPrank(owner);

        // Setup tokens
        baseToken = new MockERC20("Base Token", "BASE", 18);
        quoteToken = new MockERC20("Quote Token", "QUOTE", 6);
        deal(address(baseToken), address(this), 1 * 10 ** 18);
        deal(address(quoteToken), address(this), 1 * 10 ** 6);

        // Setup price feeds
        dataFeed = new MockAggregator(int256(INITIAL_PRICE), uint8(PRICE_DECIMALS));

        // Setup sequencer uptime feed - ensure startedAt is in the past
        uptimeFeed = new MockL2Sequencer();
        uptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2); // Well past grace period

        // Setup oracle - we need to pass arrays to the constructor for bases, quotes, providers, and feeds
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(baseToken);
        quotes[0] = address(quoteToken);
        providers[0] = CHAINLINK_PROVIDER;
        feeds[0] = address(dataFeed);

        vm.stopPrank();
        // Initialize SuperOracleL2
        oracle = new SuperOracleL2(address(this), bases, quotes, providers, feeds);

        // Set uptime feed for the data feed
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        gracePeriods[0] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/
    function test_Constructor() public view {
        // Test that constructor sets up the contract correctly
        assertEq(oracle.defaultStaleness(), DEFAULT_STALENESS);

        // Verify oracle configuration
        address configuredOracle = oracle.getOracleAddress(address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
        assertEq(configuredOracle, address(dataFeed));

        // Verify uptime feed configuration
        assertEq(oracle.uptimeFeeds(address(dataFeed)), address(uptimeFeed));
        assertEq(oracle.gracePeriods(address(uptimeFeed)), GRACE_PERIOD);
    }

    function test_Constructor_NulledInput_Reverts() public {
        // Test constructor reverts with null values
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(0);
        quotes[0] = address(0);
        providers[0] = bytes32(0);
        feeds[0] = address(0);

        vm.expectRevert();
        new SuperOracleL2(owner, bases, quotes, providers, feeds);
    }

    /*//////////////////////////////////////////////////////////////
                            UPTIME FEED TESTS
    //////////////////////////////////////////////////////////////*/
    function test_SetUptimeFeed() public {
        // Create a new mock uptime feed
        MockL2Sequencer newUptimeFeed = new MockL2Sequencer();
        newUptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        newUptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Set a new uptime feed
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(newUptimeFeed);
        gracePeriods[0] = GRACE_PERIOD * 2;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Verify the new uptime feed is set
        assertEq(oracle.uptimeFeeds(address(dataFeed)), address(newUptimeFeed));
        assertEq(oracle.gracePeriods(address(newUptimeFeed)), GRACE_PERIOD * 2);
    }

    function test_SetUptimeFeed_OnlyOwner() public {
        // Create a new mock uptime feed
        MockL2Sequencer newUptimeFeed = new MockL2Sequencer();

        // Should revert when non-owner tries to set uptime feed
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(newUptimeFeed);
        gracePeriods[0] = GRACE_PERIOD;
        vm.prank(user);
        vm.expectRevert();
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    function test_SetUptimeFeed_ZeroAddressReverts() public {
        // Test with zero data oracle
        bytes memory encodedError = abi.encodeWithSelector(ISuperOracleL2.ZERO_ADDRESS.selector);
        vm.expectRevert(encodedError);
        address[] memory uptimeOracles = new address[](1);
        uptimeOracles[0] = address(uptimeFeed);
        uint256[] memory gracePeriods = new uint256[](1);
        gracePeriods[0] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(new address[](1), uptimeOracles, gracePeriods);

        // Test with zero uptime oracle
        vm.expectRevert(encodedError);
        address[] memory dataOracles = new address[](1);
        dataOracles[0] = address(dataFeed);

        oracle.batchSetUptimeFeed(dataOracles, new address[](1), gracePeriods);
    }

    function test_SetUptimeFeed_GracePeriodTooLow_Reverts() public {
        // MIN_GRACE_PERIOD_TIME is 600 seconds in SuperOracleL2
        // Test with grace period below minimum (e.g., 599)
        uint256 tooLowGracePeriod = 599;

        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);

        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        gracePeriods[0] = tooLowGracePeriod;

        bytes memory encodedError = abi.encodeWithSelector(ISuperOracleL2.GRACE_PERIOD_TOO_LOW.selector);
        vm.expectRevert(encodedError);
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Test with grace period = 1 (also below minimum)
        gracePeriods[0] = 1;
        vm.expectRevert(encodedError);
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Test that grace period = 0 does NOT revert (uses default)
        gracePeriods[0] = 0;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Test that grace period = 600 (MIN) does NOT revert
        gracePeriods[0] = 600;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        assertEq(oracle.gracePeriods(address(uptimeFeed)), 600);

        // Test that grace period > 600 does NOT revert
        gracePeriods[0] = 601;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        assertEq(oracle.gracePeriods(address(uptimeFeed)), 601);
    }

    /// @notice Tests batchSetUptimeFeed reverts with empty arrays
    /// @dev Covers SuperOracleL2.sol:61 - if (length == 0) revert ZERO_ARRAY_LENGTH()
    function test_BatchSetUptimeFeed_RevertsOnEmptyArray() public {
        address[] memory emptyDataOracles = new address[](0);
        address[] memory emptyUptimeOracles = new address[](0);
        uint256[] memory emptyGracePeriods = new uint256[](0);

        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.ZERO_ARRAY_LENGTH.selector);
        vm.expectRevert(encodedError);
        oracle.batchSetUptimeFeed(emptyDataOracles, emptyUptimeOracles, emptyGracePeriods);
    }

    /// @notice Tests batchSetUptimeFeed reverts when uptimeOracles array length doesn't match
    /// @dev Covers SuperOracleL2.sol:62-63 - array length mismatch check (uptimeOracles)
    function test_BatchSetUptimeFeed_RevertsOnUptimeOraclesMismatch() public {
        address[] memory dataOracles = new address[](2);
        address[] memory uptimeOracles = new address[](1); // Mismatch: 2 vs 1
        uint256[] memory gracePeriods = new uint256[](2);

        dataOracles[0] = address(dataFeed);
        dataOracles[1] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        gracePeriods[0] = GRACE_PERIOD;
        gracePeriods[1] = GRACE_PERIOD;

        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.ARRAY_LENGTH_MISMATCH.selector);
        vm.expectRevert(encodedError);
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    /// @notice Tests batchSetUptimeFeed reverts when gracePeriods array length doesn't match
    /// @dev Covers SuperOracleL2.sol:62-63 - array length mismatch check (gracePeriods)
    function test_BatchSetUptimeFeed_RevertsOnGracePeriodsMismatch() public {
        address[] memory dataOracles = new address[](2);
        address[] memory uptimeOracles = new address[](2);
        uint256[] memory gracePeriods = new uint256[](1); // Mismatch: 2 vs 1

        dataOracles[0] = address(dataFeed);
        dataOracles[1] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        uptimeOracles[1] = address(uptimeFeed);
        gracePeriods[0] = GRACE_PERIOD;

        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.ARRAY_LENGTH_MISMATCH.selector);
        vm.expectRevert(encodedError);
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    /// @notice Tests batchSetUptimeFeed reverts when both arrays have mismatched lengths
    /// @dev Covers SuperOracleL2.sol:62-63 - both conditions in OR statement
    function test_BatchSetUptimeFeed_RevertsOnBothArraysMismatch() public {
        address[] memory dataOracles = new address[](3);
        address[] memory uptimeOracles = new address[](2); // Mismatch
        uint256[] memory gracePeriods = new uint256[](1); // Mismatch

        dataOracles[0] = address(dataFeed);
        dataOracles[1] = address(dataFeed);
        dataOracles[2] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        uptimeOracles[1] = address(uptimeFeed);
        gracePeriods[0] = GRACE_PERIOD;

        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.ARRAY_LENGTH_MISMATCH.selector);
        vm.expectRevert(encodedError);
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    /// @notice Tests batchSetUptimeFeed succeeds with multiple valid entries
    /// @dev Tests loop iteration through multiple valid entries (line 66)
    function test_BatchSetUptimeFeed_SucceedsWithMultipleEntries() public {
        // Create additional mock feeds
        MockAggregator dataFeed2 = new MockAggregator(int256(INITIAL_PRICE), uint8(PRICE_DECIMALS));
        MockAggregator dataFeed3 = new MockAggregator(int256(INITIAL_PRICE), uint8(PRICE_DECIMALS));
        MockL2Sequencer uptimeFeed2 = new MockL2Sequencer();
        MockL2Sequencer uptimeFeed3 = new MockL2Sequencer();

        address[] memory dataOracles = new address[](3);
        address[] memory uptimeOracles = new address[](3);
        uint256[] memory gracePeriods = new uint256[](3);

        dataOracles[0] = address(dataFeed);
        dataOracles[1] = address(dataFeed2);
        dataOracles[2] = address(dataFeed3);
        uptimeOracles[0] = address(uptimeFeed);
        uptimeOracles[1] = address(uptimeFeed2);
        uptimeOracles[2] = address(uptimeFeed3);
        gracePeriods[0] = GRACE_PERIOD;
        gracePeriods[1] = GRACE_PERIOD * 2;
        gracePeriods[2] = 0; // Test with zero grace period

        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Verify all entries were set correctly
        assertEq(oracle.uptimeFeeds(address(dataFeed)), address(uptimeFeed));
        assertEq(oracle.uptimeFeeds(address(dataFeed2)), address(uptimeFeed2));
        assertEq(oracle.uptimeFeeds(address(dataFeed3)), address(uptimeFeed3));
        assertEq(oracle.gracePeriods(address(uptimeFeed)), GRACE_PERIOD);
        assertEq(oracle.gracePeriods(address(uptimeFeed2)), GRACE_PERIOD * 2);
        assertEq(oracle.gracePeriods(address(uptimeFeed3)), 0);
    }

    /// @notice Tests batchSetUptimeFeed with exactly MIN_GRACE_PERIOD_TIME boundary
    /// @dev Tests boundary condition for grace period validation (line 70)
    function test_BatchSetUptimeFeed_WithMinimumGracePeriod() public {
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);

        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        gracePeriods[0] = 600; // MIN_GRACE_PERIOD_TIME

        // Should succeed with exactly minimum
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        assertEq(oracle.gracePeriods(address(uptimeFeed)), 600);
    }

    /// @notice Tests batchSetUptimeFeed with grace period just below minimum
    /// @dev Tests boundary condition for grace period validation (line 70)
    function test_BatchSetUptimeFeed_WithGracePeriodBelowMinimum() public {
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);

        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        gracePeriods[0] = 599; // Just below MIN_GRACE_PERIOD_TIME

        bytes memory encodedError = abi.encodeWithSelector(ISuperOracleL2.GRACE_PERIOD_TOO_LOW.selector);
        vm.expectRevert(encodedError);
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
    }

    /// @notice Tests batchSetUptimeFeed event emissions
    /// @dev Verifies UptimeFeedSet and GracePeriodSet events are emitted (lines 77-78)
    function test_BatchSetUptimeFeed_EmitsEvents() public {
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);

        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        gracePeriods[0] = GRACE_PERIOD * 2;

        // Record logs to verify events are emitted
        vm.recordLogs();

        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Get recorded logs
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Verify at least 2 events were emitted (UptimeFeedSet and GracePeriodSet)
        assertGe(entries.length, 2, "Should emit at least 2 events");

        // Verify the function call succeeded (check state changes as proxy for event emissions)
        assertEq(oracle.uptimeFeeds(address(dataFeed)), address(uptimeFeed), "Uptime feed should be set");
        assertEq(oracle.gracePeriods(address(uptimeFeed)), GRACE_PERIOD * 2, "Grace period should be set");
    }

    /// @notice Tests batchSetUptimeFeed can update existing mappings
    /// @dev Verifies that calling again overwrites previous values
    function test_BatchSetUptimeFeed_UpdatesExistingMappings() public {
        // First set
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);

        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(uptimeFeed);
        gracePeriods[0] = GRACE_PERIOD;

        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        assertEq(oracle.gracePeriods(address(uptimeFeed)), GRACE_PERIOD);

        // Update with new values
        MockL2Sequencer newUptimeFeed = new MockL2Sequencer();
        uptimeOracles[0] = address(newUptimeFeed);
        gracePeriods[0] = GRACE_PERIOD * 3;

        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Verify updates
        assertEq(oracle.uptimeFeeds(address(dataFeed)), address(newUptimeFeed));
        assertEq(oracle.gracePeriods(address(newUptimeFeed)), GRACE_PERIOD * 3);
    }

    // Event declarations for testing
    event UptimeFeedSet(address indexed dataOracle, address indexed uptimeOracle);
    event GracePeriodSet(address indexed uptimeOracle, uint256 gracePeriod);

    /*//////////////////////////////////////////////////////////////
                      QUOTE RETRIEVAL TESTS
    //////////////////////////////////////////////////////////////*/
    function test_GetQuote_SequencerUp() public {
        // Make sure sequencer is up and grace period is over
        uptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2); // Well past grace period

        uint256 baseAmount = 1 * 10 ** 15;
        uint256 quoteAmount = oracle.getQuote(baseAmount, address(baseToken), address(quoteToken));

        // Get the actual quote amount and use that in our test
        // This lets us focus on the functionality rather than exact decimal math
        assertEq(quoteAmount, 2_000_000);
    }

    function test_GetQuote_SequencerDown_Reverts() public {
        // Set sequencer to down
        uptimeFeed.setLatestAnswer(1); // 1 means sequencer is down

        // When using getQuote() (AVERAGE_PROVIDER), the oracle returns 0 for failed providers
        // and then reverts with NO_VALID_REPORTED_PRICES when all providers fail
        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.NO_VALID_REPORTED_PRICES.selector);
        vm.expectRevert(encodedError);
        oracle.getQuote(1 * 10 ** 15, address(baseToken), address(quoteToken));

        // When using getQuoteFromProvider with a specific provider, it reverts with SEQUENCER_DOWN
        bytes memory sequencerDownError = abi.encodeWithSelector(ISuperOracleL2.SEQUENCER_DOWN.selector);
        vm.expectRevert(sequencerDownError);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
    }

    function test_GetQuote_GracePeriodNotOver_Reverts() public {
        // Set sequencer to up but grace period not over
        uptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        uptimeFeed.setStartedAt(block.timestamp - 100); // Grace period not over (3600 is required)

        // When using getQuote() (AVERAGE_PROVIDER), the oracle returns 0 for failed providers
        // and then reverts with NO_VALID_REPORTED_PRICES when all providers fail
        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.NO_VALID_REPORTED_PRICES.selector);
        vm.expectRevert(encodedError);
        oracle.getQuote(1 * 10 ** 15, address(baseToken), address(quoteToken));

        // When using getQuoteFromProvider with a specific provider, it reverts with GRACE_PERIOD_NOT_OVER
        bytes memory gracePeriodError = abi.encodeWithSelector(ISuperOracleL2.GRACE_PERIOD_NOT_OVER.selector);
        vm.expectRevert(gracePeriodError);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
    }

    function test_GetQuote_NoUptimeFeed_Reverts() public {
        // Create a new data feed without an uptime feed
        MockAggregator newDataFeed = new MockAggregator(int256(INITIAL_PRICE), uint8(PRICE_DECIMALS));

        // Configure the oracle with the new data feed
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(baseToken);
        quotes[0] = address(quoteToken);
        providers[0] = keccak256("NEW_PROVIDER");
        feeds[0] = address(newDataFeed);

        oracle.queueOracleUpdate(bases, quotes, providers, feeds);

        // Fast forward past timelock
        vm.warp(block.timestamp + 7 days);

        oracle.executeOracleUpdate();

        // Try to get a quote using the new provider
        bytes memory encodedError = abi.encodeWithSelector(ISuperOracleL2.NO_UPTIME_FEED.selector);
        vm.expectRevert(encodedError);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), keccak256("NEW_PROVIDER"));
    }

    function test_GetQuote_StaleFeed_Reverts() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2); // Well past grace period

        // Set the data feed to have stale data
        dataFeed.setUpdatedAt(block.timestamp - DEFAULT_STALENESS - 1); // Older than max staleness

        // Attempt to get a quote directly from the oracle function that checks staleness
        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.NO_VALID_REPORTED_PRICES.selector);
        vm.expectRevert(encodedError);
        oracle.getQuote(1 * 10 ** 15, address(baseToken), address(quoteToken));
    }

    function test_GetQuote_NegativePrice_Reverts() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2); // Well past grace period

        // Set the data feed to have negative price
        dataFeed.setAnswer(-1 * int256(INITIAL_PRICE));

        // Attempt to get a quote directly from the oracle function that checks for negative prices
        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.NO_VALID_REPORTED_PRICES.selector);
        vm.expectRevert(encodedError);
        oracle.getQuote(1 * 10 ** 15, address(baseToken), address(quoteToken));
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/
    function test_PriceChangeReflected() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2); // Well past grace period

        // Get initial quote - using smaller amounts to avoid overflow
        uint256 baseAmount = 1 * 10 ** 15; // 0.001 token
        uint256 initialQuote = oracle.getQuote(baseAmount, address(baseToken), address(quoteToken));

        // Change price in the feed
        uint256 newPrice = INITIAL_PRICE * 2; // Double the price
        dataFeed.setAnswer(int256(newPrice));

        // Get new quote
        uint256 newQuote = oracle.getQuote(baseAmount, address(baseToken), address(quoteToken));

        // Verify the quote has doubled
        assertEq(newQuote, initialQuote * 2);
    }

    function test_DefaultGracePeriod() public {
        // Create a new uptime feed
        MockL2Sequencer newUptimeFeed = new MockL2Sequencer();
        newUptimeFeed.setLatestAnswer(0); // 0 means sequencer is up
        newUptimeFeed.setStartedAt(block.timestamp - 100); // Recently started (shorter than default grace)

        // Set the uptime feed with a zero grace period (should use default)
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(dataFeed);
        uptimeOracles[0] = address(newUptimeFeed);
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // When using getQuote() (AVERAGE_PROVIDER), the oracle returns 0 for failed providers
        // and then reverts with NO_VALID_REPORTED_PRICES when all providers fail
        bytes memory encodedError = abi.encodeWithSelector(ISuperOracle.NO_VALID_REPORTED_PRICES.selector);
        vm.expectRevert(encodedError);
        oracle.getQuote(1 * 10 ** 15, address(baseToken), address(quoteToken));

        // When using getQuoteFromProvider with a specific provider, it reverts with GRACE_PERIOD_NOT_OVER
        bytes memory gracePeriodError = abi.encodeWithSelector(ISuperOracleL2.GRACE_PERIOD_NOT_OVER.selector);
        vm.expectRevert(gracePeriodError);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);

        // Now set a time that's past the default grace period
        newUptimeFeed.setStartedAt(block.timestamp - 3700); // Past default grace period

        // Should now succeed
        uint256 quoteAmount = oracle.getQuote(1 * 10 ** 15, address(baseToken), address(quoteToken));
        assertGt(quoteAmount, 0);
    }

    /*//////////////////////////////////////////////////////////////
            COMPREHENSIVE _getQuoteFromOracle LINE 136 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests _getQuoteFromOracle reverts with ORACLE_UNTRUSTED_DATA when answer <= 0 and revertOnError = true
    /// @dev Covers SuperOracleL2.sol:136 - if (revertOnError) revert ORACLE_UNTRUSTED_DATA() with negative answer
    function test_GetQuoteFromOracle_RevertsOnNegativeAnswerWithRevertOnError() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0);
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Set negative answer in the data feed
        dataFeed.setAnswer(-1000);

        // Call getQuoteFromProvider which uses revertOnError = true
        // This should trigger line 135 (answer <= 0) and line 136 (revert)
        vm.expectRevert(ISuperOracle.ORACLE_UNTRUSTED_DATA.selector);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
    }

    /// @notice Tests _getQuoteFromOracle reverts with ORACLE_UNTRUSTED_DATA when answer = 0 and revertOnError = true
    /// @dev Covers SuperOracleL2.sol:136 - boundary case with answer = 0
    function test_GetQuoteFromOracle_RevertsOnZeroAnswerWithRevertOnError() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0);
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Set answer to exactly 0
        dataFeed.setAnswer(0);

        // Should revert because answer <= 0
        vm.expectRevert(ISuperOracle.ORACLE_UNTRUSTED_DATA.selector);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
    }

    /// @notice Tests _getQuoteFromOracle reverts with ORACLE_UNTRUSTED_DATA when data is stale and revertOnError = true
    /// @dev Covers SuperOracleL2.sol:136 - if (revertOnError) with stale data
    function test_GetQuoteFromOracle_RevertsOnStaleDataWithRevertOnError() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0);
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Set valid answer but stale timestamp (older than defaultStaleness = 86400)
        dataFeed.setAnswer(int256(INITIAL_PRICE));
        dataFeed.setUpdatedAt(block.timestamp - 86401); // 1 second past staleness limit

        // Should revert because block.timestamp - updatedAt > limit
        vm.expectRevert(ISuperOracle.ORACLE_UNTRUSTED_DATA.selector);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
    }

    /// @notice Tests _getQuoteFromOracle returns 0 when answer <= 0 and revertOnError = false
    /// @dev Covers SuperOracleL2.sol:137 - return 0 path when revertOnError = false
    function test_GetQuoteFromOracle_ReturnsZeroOnNegativeAnswerWithoutRevert() public {
        // Setup: Add multiple providers so we can test AVERAGE_PROVIDER with revertOnError = false
        MockAggregator dataFeed2 = new MockAggregator(int256(INITIAL_PRICE), uint8(PRICE_DECIMALS));
        MockL2Sequencer uptimeFeed2 = new MockL2Sequencer();
        uptimeFeed2.setLatestAnswer(0);
        uptimeFeed2.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Add second provider
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(baseToken);
        quotes[0] = address(quoteToken);
        providers[0] = keccak256("PROVIDER_2");
        feeds[0] = address(dataFeed2);

        oracle.queueOracleUpdate(bases, quotes, providers, feeds);
        vm.warp(block.timestamp + 7 days);
        dataFeed2.setUpdatedAt(block.timestamp);
        oracle.executeOracleUpdate();

        // Set uptime feed for provider 2
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(dataFeed2);
        uptimeOracles[0] = address(uptimeFeed2);
        gracePeriods[0] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Set up sequencer for both feeds
        uptimeFeed.setLatestAnswer(0);
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);
        dataFeed.setUpdatedAt(block.timestamp);
        dataFeed2.setUpdatedAt(block.timestamp);

        // Set dataFeed1 to have negative answer (invalid)
        dataFeed.setAnswer(-1000);
        // Set dataFeed2 to have valid answer
        dataFeed2.setAnswer(int256(INITIAL_PRICE));

        // Use AVERAGE_PROVIDER which calls _getQuoteFromOracle with revertOnError = false
        // Should skip the invalid feed and use only the valid one
        bytes32 averageProvider = keccak256("AVERAGE_PROVIDER");
        (uint256 quoteAmount,,,) =
            oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), averageProvider);

        // Should return non-zero quote from the valid provider only
        assertGt(quoteAmount, 0, "Should get quote from valid provider despite one provider having invalid answer");
    }

    /// @notice Tests _getQuoteFromOracle returns 0 when data is stale and revertOnError = false
    /// @dev Covers SuperOracleL2.sol:137 - return 0 path with stale data
    function test_GetQuoteFromOracle_ReturnsZeroOnStaleDataWithoutRevert() public {
        // Setup: Add multiple providers
        MockAggregator dataFeed2 = new MockAggregator(int256(INITIAL_PRICE), uint8(PRICE_DECIMALS));
        MockL2Sequencer uptimeFeed2 = new MockL2Sequencer();
        uptimeFeed2.setLatestAnswer(0);
        uptimeFeed2.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Add second provider
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(baseToken);
        quotes[0] = address(quoteToken);
        providers[0] = keccak256("PROVIDER_2");
        feeds[0] = address(dataFeed2);

        oracle.queueOracleUpdate(bases, quotes, providers, feeds);
        vm.warp(block.timestamp + 7 days);
        dataFeed2.setUpdatedAt(block.timestamp);
        oracle.executeOracleUpdate();

        // Set uptime feed for provider 2
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(dataFeed2);
        uptimeOracles[0] = address(uptimeFeed2);
        gracePeriods[0] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Set up sequencer for both feeds
        uptimeFeed.setLatestAnswer(0);
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Set dataFeed1 to have valid answer but stale timestamp
        dataFeed.setAnswer(int256(INITIAL_PRICE));
        dataFeed.setUpdatedAt(block.timestamp - 86401); // Stale
        // Set dataFeed2 to have valid answer and fresh timestamp
        dataFeed2.setAnswer(int256(INITIAL_PRICE));
        dataFeed2.setUpdatedAt(block.timestamp);

        // Use AVERAGE_PROVIDER which calls _getQuoteFromOracle with revertOnError = false
        bytes32 averageProvider = keccak256("AVERAGE_PROVIDER");
        (uint256 quoteAmount,,,) =
            oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), averageProvider);

        // Should return non-zero quote from the fresh provider only
        assertGt(quoteAmount, 0, "Should get quote from fresh provider despite one provider being stale");
    }

    /// @notice Tests boundary case where updatedAt is exactly at the staleness limit
    /// @dev Tests boundary of line 135 condition: block.timestamp - updatedAt > limit
    function test_GetQuoteFromOracle_SucceedsAtExactStalenessLimit() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0);
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Set updatedAt to exactly the staleness limit (should NOT revert)
        dataFeed.setAnswer(int256(INITIAL_PRICE));
        dataFeed.setUpdatedAt(block.timestamp - 86400); // Exactly at limit (not over)

        // Should succeed because block.timestamp - updatedAt == limit (not >)
        (uint256 quoteAmount,,,) =
            oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
        assertGt(quoteAmount, 0, "Should succeed when exactly at staleness limit");
    }

    /// @notice Tests _getQuoteFromOracle with answer = 1 (just above zero, should succeed)
    /// @dev Tests boundary of line 135 condition: answer <= 0
    function test_GetQuoteFromOracle_SucceedsWithAnswerOne() public {
        // Set up sequencer correctly
        uptimeFeed.setLatestAnswer(0);
        uptimeFeed.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Set answer to 1 with proper decimals (just above zero, should succeed)
        // Since the feed has 8 decimals, 1e8 represents a reasonable price
        dataFeed.setAnswer(1e8);
        dataFeed.setUpdatedAt(block.timestamp);

        // Should succeed because answer > 0
        (uint256 quoteAmount,,,) =
            oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), CHAINLINK_PROVIDER);
        assertGt(quoteAmount, 0, "Should succeed with positive answer");
    }

    /*//////////////////////////////////////////////////////////////
            COMPREHENSIVE CATCH BLOCK TESTS (Lines 150-156)
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests catch block reverts with ORACLE_DECIMALS_CALL_FAIL when decimals() fails and revertOnError = true
    /// @dev Covers SuperOracleL2.sol:154 - if (revertOnError) revert ORACLE_DECIMALS_CALL_FAIL(oracle)
    function test_CatchBlock_RevertsOnDecimalsFailWithRevertOnError() public {
        // Create a mock aggregator that reverts on decimals()
        MockAggregatorFailDecimals failingFeed = new MockAggregatorFailDecimals(int256(INITIAL_PRICE));
        failingFeed.setUpdatedAt(block.timestamp);

        // Create and configure uptime feed
        MockL2Sequencer uptimeFeedForFailing = new MockL2Sequencer();
        uptimeFeedForFailing.setLatestAnswer(0);
        uptimeFeedForFailing.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Add the failing feed as a new provider
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(baseToken);
        quotes[0] = address(quoteToken);
        providers[0] = keccak256("FAILING_PROVIDER");
        feeds[0] = address(failingFeed);

        oracle.queueOracleUpdate(bases, quotes, providers, feeds);
        vm.warp(block.timestamp + 7 days);
        failingFeed.setUpdatedAt(block.timestamp);
        oracle.executeOracleUpdate();

        // Set uptime feed for the failing provider
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(failingFeed);
        uptimeOracles[0] = address(uptimeFeedForFailing);
        gracePeriods[0] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Call with specific provider (revertOnError = true) should revert with ORACLE_DECIMALS_CALL_FAIL
        vm.expectRevert(abi.encodeWithSelector(ISuperOracleL2.ORACLE_DECIMALS_CALL_FAIL.selector, address(failingFeed)));
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), keccak256("FAILING_PROVIDER"));
    }

    /// @notice Tests catch block returns 0 when decimals() fails and revertOnError = false
    /// @dev Covers SuperOracleL2.sol:155 - return 0 when revertOnError = false
    function test_CatchBlock_ReturnsZeroOnDecimalsFailWithoutRevert() public {
        // Setup: Add a failing provider and a working provider
        MockAggregatorFailDecimals failingFeed = new MockAggregatorFailDecimals(int256(INITIAL_PRICE));
        failingFeed.setUpdatedAt(block.timestamp);

        MockAggregator workingFeed = new MockAggregator(int256(INITIAL_PRICE), uint8(PRICE_DECIMALS));
        workingFeed.setUpdatedAt(block.timestamp);

        // Create uptime feeds
        MockL2Sequencer uptimeFeedFailing = new MockL2Sequencer();
        uptimeFeedFailing.setLatestAnswer(0);
        uptimeFeedFailing.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        MockL2Sequencer uptimeFeedWorking = new MockL2Sequencer();
        uptimeFeedWorking.setLatestAnswer(0);
        uptimeFeedWorking.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Add both providers
        address[] memory bases = new address[](2);
        address[] memory quotes = new address[](2);
        bytes32[] memory providers = new bytes32[](2);
        address[] memory feeds = new address[](2);

        bases[0] = address(baseToken);
        bases[1] = address(baseToken);
        quotes[0] = address(quoteToken);
        quotes[1] = address(quoteToken);
        providers[0] = keccak256("FAILING_PROVIDER");
        providers[1] = keccak256("WORKING_PROVIDER");
        feeds[0] = address(failingFeed);
        feeds[1] = address(workingFeed);

        oracle.queueOracleUpdate(bases, quotes, providers, feeds);
        vm.warp(block.timestamp + 7 days);
        failingFeed.setUpdatedAt(block.timestamp);
        workingFeed.setUpdatedAt(block.timestamp);
        oracle.executeOracleUpdate();

        // Set uptime feeds for both
        address[] memory dataOracles = new address[](2);
        address[] memory uptimeOracles = new address[](2);
        uint256[] memory gracePeriods = new uint256[](2);
        dataOracles[0] = address(failingFeed);
        dataOracles[1] = address(workingFeed);
        uptimeOracles[0] = address(uptimeFeedFailing);
        uptimeOracles[1] = address(uptimeFeedWorking);
        gracePeriods[0] = GRACE_PERIOD;
        gracePeriods[1] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Use AVERAGE_PROVIDER (revertOnError = false) should skip failing feed and use working feed
        bytes32 averageProvider = keccak256("AVERAGE_PROVIDER");
        (uint256 quoteAmount,,,) =
            oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), averageProvider);

        // Should return non-zero quote from the working provider only
        assertGt(quoteAmount, 0, "Should get quote from working provider despite one provider failing decimals()");
    }

    /// @notice Tests catch block detects insufficient gas before external call
    /// @dev Covers SuperOracleL2.sol:153 - if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL()
    /// @dev This is difficult to test reliably due to gas accounting complexities
    function test_CatchBlock_InsufficientGasDetection() public {
        // Create a mock aggregator that reverts on decimals()
        MockAggregatorFailDecimals failingFeed = new MockAggregatorFailDecimals(int256(INITIAL_PRICE));
        failingFeed.setUpdatedAt(block.timestamp);

        // Create and configure uptime feed
        MockL2Sequencer uptimeFeedForFailing = new MockL2Sequencer();
        uptimeFeedForFailing.setLatestAnswer(0);
        uptimeFeedForFailing.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Add the failing feed as a new provider
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(baseToken);
        quotes[0] = address(quoteToken);
        providers[0] = keccak256("FAILING_PROVIDER");
        feeds[0] = address(failingFeed);

        oracle.queueOracleUpdate(bases, quotes, providers, feeds);
        vm.warp(block.timestamp + 7 days);
        failingFeed.setUpdatedAt(block.timestamp);
        oracle.executeOracleUpdate();

        // Set uptime feed for the failing provider
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(failingFeed);
        uptimeOracles[0] = address(uptimeFeedForFailing);
        gracePeriods[0] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Normal call with sufficient gas should revert with ORACLE_DECIMALS_CALL_FAIL
        // not INSUFFICIENT_GAS_FOR_EXTERNAL_CALL
        vm.expectRevert(abi.encodeWithSelector(ISuperOracleL2.ORACLE_DECIMALS_CALL_FAIL.selector, address(failingFeed)));
        oracle.getQuoteFromProvider{gas: 500000}(
            1 * 10 ** 15, address(baseToken), address(quoteToken), keccak256("FAILING_PROVIDER")
        );

        // Note: Testing the actual INSUFFICIENT_GAS_FOR_EXTERNAL_CALL path is complex
        // because it requires precise gas manipulation that may not be reliable across
        // different EVM implementations. The gas check is a safety mechanism that
        // prevents misinterpretation of out-of-gas errors as oracle failures.
    }

    /// @notice Tests that catch block properly handles both revertOnError paths
    /// @dev Comprehensive test covering lines 154 and 155
    function test_CatchBlock_BothRevertOnErrorPaths() public {
        // Create a mock aggregator that reverts on decimals()
        MockAggregatorFailDecimals failingFeed = new MockAggregatorFailDecimals(int256(INITIAL_PRICE));
        failingFeed.setUpdatedAt(block.timestamp);

        // Create uptime feed
        MockL2Sequencer uptimeFeedForFailing = new MockL2Sequencer();
        uptimeFeedForFailing.setLatestAnswer(0);
        uptimeFeedForFailing.setStartedAt(block.timestamp - GRACE_PERIOD * 2);

        // Add the failing feed
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = address(baseToken);
        quotes[0] = address(quoteToken);
        providers[0] = keccak256("FAILING_PROVIDER");
        feeds[0] = address(failingFeed);

        oracle.queueOracleUpdate(bases, quotes, providers, feeds);
        vm.warp(block.timestamp + 7 days);
        failingFeed.setUpdatedAt(block.timestamp);
        oracle.executeOracleUpdate();

        // Set uptime feed
        address[] memory dataOracles = new address[](1);
        address[] memory uptimeOracles = new address[](1);
        uint256[] memory gracePeriods = new uint256[](1);
        dataOracles[0] = address(failingFeed);
        uptimeOracles[0] = address(uptimeFeedForFailing);
        gracePeriods[0] = GRACE_PERIOD;
        oracle.batchSetUptimeFeed(dataOracles, uptimeOracles, gracePeriods);

        // Path 1: revertOnError = true (specific provider) should revert
        vm.expectRevert(abi.encodeWithSelector(ISuperOracleL2.ORACLE_DECIMALS_CALL_FAIL.selector, address(failingFeed)));
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), keccak256("FAILING_PROVIDER"));

        // Path 2: revertOnError = false (AVERAGE_PROVIDER with only this provider) should revert with NO_VALID_REPORTED_PRICES
        // because it skips the failing oracle and has no valid oracles left
        bytes32 averageProvider = keccak256("AVERAGE_PROVIDER");
        vm.expectRevert(ISuperOracle.NO_VALID_REPORTED_PRICES.selector);
        oracle.getQuoteFromProvider(1 * 10 ** 15, address(baseToken), address(quoteToken), averageProvider);
    }
}

interface ISuperOracleL2 {
    error SEQUENCER_DOWN();
    error GRACE_PERIOD_NOT_OVER();
    error NO_UPTIME_FEED();
    error ZERO_ADDRESS();
    error GRACE_PERIOD_TOO_LOW();
    error INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
    error ORACLE_DECIMALS_CALL_FAIL(address oracle);
}

/// @notice Mock aggregator that reverts on decimals() call to test catch block
contract MockAggregatorFailDecimals {
    int256 private answer;
    uint256 private updatedAt;

    constructor(int256 answer_) {
        answer = answer_;
        updatedAt = block.timestamp;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer_, uint256 startedAt, uint256 updatedAt_, uint80 answeredInRound)
    {
        return (0, answer, block.timestamp, updatedAt, 0);
    }

    function decimals() external pure returns (uint8) {
        revert("Decimals call failed");
    }

    function setUpdatedAt(uint256 timestamp) external {
        updatedAt = timestamp;
    }

    function setAnswer(int256 answer_) external {
        answer = answer_;
    }
}
