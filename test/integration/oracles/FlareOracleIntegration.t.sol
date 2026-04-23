// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { FixedPriceOracle } from "../../../src/oracles/FixedPriceOracle.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";

/// @title FlareOracleIntegrationTest
/// @notice Integration test forking Flare to verify the full UP pricing flow with the 18-decimal FTSOv2 FLR/USD
/// adapter
/// @dev Tests:
///      1. FLR/USD oracle returns a valid price via FTSOv2 Chainlink adapter (18 decimals)
///      2. UP/USD returns fixed $0.09 via FixedPriceOracle
///      3. GAS→WEI oracle returns non-zero via SuperformGasOracle
///      4. Decimal scaling works correctly with 18-decimal feed
///      5. AVERAGE_PROVIDER aggregation matches single-provider result
contract FlareOracleIntegrationTest is Test {
    // Real Flare addresses from ConfigBase.sol
    address constant ORACLE_FLR_USD_FLARE = 0xbF9D1474E817C94163Fc7cc7Da5B4543CdA76697;
    address constant ORACLE_GAS_TO_WEI_FLARE = 0x473b88f017dE39d85a102DA01A35a1b3507eBcFc;
    address constant UP_TOKEN_FLARE = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;

    // Oracle constants (must match SuperGovernor / SuperOracleBase)
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // Provider identifiers
    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // UP fixed price: $0.09 with 18 decimals
    int256 constant INITIAL_UP_PRICE = 0.09e18;
    uint8 constant UP_PRICE_DECIMALS = 18;

    // Contracts
    SuperGovernor public governor;
    SuperOracle public superOracle;
    FixedPriceOracle public fixedPriceOracle;

    // Test accounts
    address public deployer;
    address public oracleManager;

    function setUp() public {
        // Fork Flare at latest block
        vm.createSelectFork(vm.envString("FLARE_RPC_URL"));

        deployer = makeAddr("deployer");
        oracleManager = makeAddr("oracleManager");

        vm.startPrank(deployer);

        // Deploy fresh SuperGovernor (deployer is superGovernor + governor + all roles for simplicity)
        governor = new SuperGovernor(
            deployer, // superGovernor
            deployer, // governor
            deployer, // bankManager
            oracleManager, // oracleManager
            deployer, // gasManager
            deployer, // guardian
            deployer, // treasury
            false // upkeepPaymentsEnabled
        );

        // Deploy FixedPriceOracle for UP/USD ($0.09, 18 decimals)
        fixedPriceOracle = new FixedPriceOracle(INITIAL_UP_PRICE, UP_PRICE_DECIMALS, deployer);

        // Deploy SuperOracle (not L2 — Flare is an L1 with no sequencer) with 3 feeds:
        //   [0] GAS→WEI:     real SuperformGasOracle
        //   [1] NATIVE→USD:  real FTSOv2 FLR/USD adapter (18 decimals)
        //   [2] UP→USD:      our fresh FixedPriceOracle
        address[] memory bases = new address[](3);
        address[] memory quotes = new address[](3);
        bytes32[] memory providers = new bytes32[](3);
        address[] memory feeds = new address[](3);

        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_CHAINLINK;
        feeds[0] = ORACLE_GAS_TO_WEI_FLARE;

        bases[1] = NATIVE_TOKEN;
        quotes[1] = USD_TOKEN;
        providers[1] = PROVIDER_CHAINLINK;
        feeds[1] = ORACLE_FLR_USD_FLARE;

        bases[2] = UP_TOKEN_FLARE;
        quotes[2] = USD_TOKEN;
        providers[2] = PROVIDER_SUPERFORM;
        feeds[2] = address(fixedPriceOracle);

        superOracle = new SuperOracle(address(governor), bases, quotes, providers, feeds);

        // Register SuperOracle in SuperGovernor
        governor.setAddress(governor.SUPER_ORACLE(), address(superOracle));

        vm.stopPrank();

        // Set generous staleness on all feeds (SuperformGasOracle is keeper-updated, may be stale)
        vm.startPrank(oracleManager);
        governor.setOracleMaxStaleness(30 days);
        address[] memory feedAddrs = new address[](3);
        uint256[] memory stalenesses = new uint256[](3);
        feedAddrs[0] = ORACLE_GAS_TO_WEI_FLARE;
        feedAddrs[1] = ORACLE_FLR_USD_FLARE;
        feedAddrs[2] = address(fixedPriceOracle);
        stalenesses[0] = 30 days;
        stalenesses[1] = 30 days;
        stalenesses[2] = 30 days;
        governor.setOracleFeedMaxStalenessBatch(feedAddrs, stalenesses);
        vm.stopPrank();
    }

    /// @notice FLR/USD oracle returns a valid price within $0.001–$1 range
    function test_flrUsdOracleReturnsValidPrice() public view {
        (uint256 quoteAmount,,,) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);

        console2.log("FLR/USD quote for 1 FLR (1e18 wei):", quoteAmount);

        assertGt(quoteAmount, 0, "FLR/USD price should be > 0");
        // FLR is typically between $0.001 and $1
        // safeDecimals() returns 18 for both NATIVE_TOKEN and USD_TOKEN (no code at those addresses)
        // With feedDecimals=18: quoteAmount = (1e18 * answer * 1e18) / 1e(18+18) = answer
        // So quoteAmount is in 18-decimal USD terms
        // $0.001 = 1e15, $1 = 1e18
        assertGt(quoteAmount, 1e15, "FLR price should be > $0.001");
        assertLt(quoteAmount, 1e18, "FLR price should be < $1");
    }

    /// @notice UP/USD returns exactly $0.09 via FixedPriceOracle
    function test_upUsdOracleReturnsFixedPrice() public view {
        (uint256 quoteAmount,,,) =
            superOracle.getQuoteFromProvider(1e18, UP_TOKEN_FLARE, USD_TOKEN, PROVIDER_SUPERFORM);

        console2.log("UP/USD quote for 1 UP (1e18 wei):", quoteAmount);

        // UP token has 18 decimals (it's an OFT)
        // FixedPriceOracle returns 0.09e18 with 18 decimals
        // safeDecimals() for UP_TOKEN_FLARE: calls decimals() on the real UpOFT → 18
        // safeDecimals() for USD_TOKEN: no code → returns 18
        // Formula: (1e18 * 0.09e18 * 1e18) / 1e(18+18) = 0.09e18
        assertEq(quoteAmount, 0.09e18, "UP price should be exactly $0.09 (18 decimals)");
    }

    /// @notice GAS→WEI oracle returns non-zero
    function test_gasToWeiOracleWorks() public view {
        (uint256 quoteAmount,,,) =
            superOracle.getQuoteFromProvider(1e18, GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK);

        console2.log("GAS->WEI quote for 1e18 gas units:", quoteAmount);

        assertGt(quoteAmount, 0, "GAS->WEI conversion should be > 0");
    }

    /// @notice Validates that the 18-decimal FLR/USD feed scales correctly
    /// @dev Manual calculation: (amount * answer * 10^quoteDecimals) / 10^(feedDecimals + baseDecimals)
    ///      With all 18-decimal values: (amount * answer * 1e18) / 1e36
    function test_flrToUsdDecimalScaling() public view {
        uint256 amount = 5e18; // 5 FLR

        (uint256 quoteAmount,,,) =
            superOracle.getQuoteFromProvider(amount, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);

        // Also query 1 FLR to get the raw price
        (uint256 oneFlrQuote,,,) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);

        console2.log("Quote for 5 FLR:", quoteAmount);
        console2.log("Quote for 1 FLR:", oneFlrQuote);

        // 5 FLR should cost exactly 5x the price of 1 FLR
        // Due to integer division in mulDiv, allow ±1 wei tolerance
        assertApproxEqAbs(quoteAmount, oneFlrQuote * 5, 1, "5 FLR quote should be 5x the 1 FLR quote");

        // Verify the formula manually:
        // quoteAmount = mulDiv(amount, answer * 10^quoteDecimals, 10^(feedDecimals + baseDecimals))
        // All decimals are 18, so: mulDiv(5e18, answer * 1e18, 1e36) = 5 * answer / 1e18 * 1e18 = 5 * answer
        // But answer itself is already scaled to 18 decimals (e.g., 0.02e18 for $0.02)
        // So quoteAmount = 5 * answer (in 18-decimal USD)
        // Which means quoteAmount = 5 * oneFlrQuote
        assertGt(quoteAmount, 0, "Scaled quote should be > 0");
    }

    /// @notice AVERAGE_PROVIDER result matches single-provider for NATIVE→USD
    /// @dev Since there's only one provider (CHAINLINK) configured for NATIVE→USD,
    ///      the average should equal the single-provider result exactly.
    function test_averageProviderWorks() public view {
        // Single provider
        (uint256 singleQuote,,,) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);

        // Average provider
        (uint256 avgQuote, uint256 deviation, uint256 totalProviders, uint256 availableProviders) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);

        console2.log("Single provider quote:", singleQuote);
        console2.log("Average provider quote:", avgQuote);
        console2.log("  Deviation:", deviation);
        console2.log("  Total providers:", totalProviders);
        console2.log("  Available providers:", availableProviders);

        // With only one provider for this pair, average == single
        assertEq(avgQuote, singleQuote, "Average should match single provider when only one exists");
        assertEq(deviation, 0, "Deviation should be 0 with single provider");
        assertEq(availableProviders, 1, "Should have 1 available provider");
    }
}
