// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { BasefeeGasOracle } from "../../../src/oracles/BasefeeGasOracle.sol";
import { AggregatorV3Interface } from "../../../src/vendor/chainlink/AggregatorV3Interface.sol";

/// @notice Legacy Chainlink aggregator interface (v2) - latestAnswer() is not part of the
///         vendored AggregatorV3Interface but is implemented by Chainlink's EACAggregatorProxy
interface IAggregatorLegacy {
    function latestAnswer() external view returns (int256);
}

/// @title UpkeepCostRealFlowTest
/// @notice Mainnet fork tests exercising the REAL production upkeep-cost flow end to end:
///         SuperGovernor.getUpkeepCostPerSingleUpdate -> SuperOracle 3-hop conversion
///         (GAS->WEI, NATIVE->USD, UP->USD) -> Math.mulDiv ceil, against live deployed
///         contracts and live feed data - no mocks.
/// @dev Three groups:
///      1. Chainlink-only (current production state): the live Fast Gas feed drives the cost;
///         we replicate the 3-hop math manually and assert bit-exact equality.
///      2. Basefee-only (post-migration, Fast Gas staled out): BasefeeGasOracle drives the cost;
///         same bit-exact replication from block.basefee.
///      3. Comparisons: raw answers, per-provider GAS->WEI quotes, and full upkeep costs across
///         the three regimes (Chainlink-only / blended AVERAGE / basefee-only).
contract UpkeepCostRealFlowTest is Test {
    // Production addresses from Ethereum-latest.json
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant SUPER_ORACLE = 0x8943128DbAb4279D561654dEED2930Bb975AA070;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;

    // Chainlink mainnet feeds (the feeds SuperOracle was deployed with)
    address constant CHAINLINK_GAS_ORACLE = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;
    address constant CHAINLINK_ETH_USD_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // Synthetic pair addresses (must match SuperGovernor)
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // Provider identifiers
    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // Initial calibration (see technical spec)
    uint256 constant INITIAL_MULTIPLIER_BPS = 20_000; // 2x - deliberate over-recovery vs raw basefee
    uint256 constant INITIAL_PRIORITY_FEE_WEI = 1_000_000; // 0.001 gwei

    uint256 constant TIMELOCK_PERIOD = 1 weeks;

    SuperGovernor public governor;
    SuperOracle public superOracle;
    BasefeeGasOracle public basefeeOracle;

    address public oracleManager;
    address public upkeepToken;
    uint256 public tokenUnit;
    uint256 public gasPerEntry;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        // Back off the chain tip: forking at "latest" against a load-balanced RPC can pin a
        // lagging block while feeds' updatedAt come from head, underflowing SuperOracle's
        // staleness check (block.timestamp - updatedAt). 32 blocks is within every full
        // node's recent-state window, so no archive access is needed.
        vm.rollFork(block.number - 32);

        governor = SuperGovernor(SUPER_GOVERNOR);
        superOracle = SuperOracle(SUPER_ORACLE);

        oracleManager = makeAddr("oracleManager");
        _grantRoleViaStorage(governor.ORACLE_MANAGER_ROLE(), oracleManager);

        basefeeOracle = new BasefeeGasOracle(
            INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI, makeAddr("admin"), makeAddr("gasManager")
        );

        // Real registry state used by the production cost flow
        upkeepToken = governor.getAddress(governor.UPKEEP_TOKEN());
        tokenUnit = 10 ** IERC20Metadata(upkeepToken).decimals();
        gasPerEntry = governor.getGasInfo(ECDSA_PPS_ORACLE);

        assertGt(gasPerEntry, 0, "PPS oracle must have gasPerEntry configured on mainnet");
    }

    /*//////////////////////////////////////////////////////////////
                 GROUP 1: CHAINLINK-ONLY (PRODUCTION STATE)
    //////////////////////////////////////////////////////////////*/

    /// @notice The GAS->WEI quote through SuperOracle must equal the raw Fast Gas feed answer
    ///         scaled by the gas amount (0-decimals feed, 18/18 pseudo-token decimals cancel)
    function test_RealFlow_Chainlink_GasWeiQuote_MatchesRawFeedAnswer() public view {
        (, int256 fastGasAnswer,,,) = AggregatorV3Interface(CHAINLINK_GAS_ORACLE).latestRoundData();

        (uint256 quote,,, uint256 availableProviders) =
            superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK);

        console2.log("Fast Gas raw answer (wei/gas):", uint256(fastGasAnswer));
        console2.log("SuperOracle CHAINLINK quote for gasPerEntry:", quote);

        assertEq(availableProviders, 1, "single provider expected on the direct-provider path");
        assertEq(quote, gasPerEntry * uint256(fastGasAnswer), "quote must be raw answer * gas amount");
    }

    /// @notice Replicate the production 3-hop conversion manually from live AVERAGE quotes and
    ///         assert bit-exact equality with getUpkeepCostPerSingleUpdate (Chainlink-driven)
    function test_RealFlow_Chainlink_UpkeepCost_MatchesManual3Hop() public view {
        uint256 actualCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        uint256 expectedCost = _manual3HopCost();

        console2.log("gasPerEntry:", gasPerEntry);
        console2.log("Manual 3-hop cost (UP):", expectedCost);
        console2.log("getUpkeepCostPerSingleUpdate (UP):", actualCost);

        assertGt(actualCost, 0, "live upkeep cost must be > 0");
        assertEq(actualCost, expectedCost, "real flow must match manual 3-hop replication exactly");
    }

    /*//////////////////////////////////////////////////////////////
              GROUP 2: BASEFEE-ONLY (POST-MIGRATION STATE)
    //////////////////////////////////////////////////////////////*/

    /// @notice After migration and Fast Gas going stale, the GAS->WEI quote must equal the raw
    ///         BasefeeGasOracle answer scaled by the gas amount
    function test_RealFlow_Basefee_GasWeiQuote_MatchesRawOracleAnswer() public {
        _migrate();
        _setFeedsMaxStaleness(30 days, false); // Fast Gas stale -> dropped

        int256 rawAnswer = basefeeOracle.latestAnswer();
        (uint256 quote,,, uint256 availableProviders) =
            superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM);

        console2.log("Basefee oracle raw answer (wei/gas):", uint256(rawAnswer));
        console2.log("SuperOracle SUPERFORM quote for gasPerEntry:", quote);
        console2.log("block.basefee:", block.basefee);

        assertEq(availableProviders, 1);
        assertEq(quote, gasPerEntry * uint256(rawAnswer), "quote must be raw answer * gas amount");
        assertEq(
            uint256(rawAnswer),
            block.basefee * INITIAL_MULTIPLIER_BPS / 10_000 + INITIAL_PRIORITY_FEE_WEI,
            "raw answer must match the basefee formula"
        );
    }

    /// @notice With Fast Gas dead, replicate the 3-hop conversion from block.basefee and assert
    ///         bit-exact equality with getUpkeepCostPerSingleUpdate (basefee-driven)
    function test_RealFlow_Basefee_UpkeepCost_MatchesManual3Hop() public {
        _migrate();
        _setFeedsMaxStaleness(30 days, false); // Fast Gas stale -> our feed carries the pair alone

        uint256 actualCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        uint256 expectedCost = _manual3HopCost();

        console2.log("block.basefee:", block.basefee);
        console2.log("Manual 3-hop cost from basefee (UP):", expectedCost);
        console2.log("getUpkeepCostPerSingleUpdate (UP):", actualCost);

        assertGt(actualCost, 0, "upkeep must still be charged with Fast Gas dead");
        assertEq(actualCost, expectedCost, "real flow must match manual 3-hop replication exactly");

        // The direct CHAINLINK-provider path must now revert on the stale feed - the real flow
        // only survives because the AVERAGE path drops it
        vm.expectRevert(ISuperOracle.ORACLE_UNTRUSTED_DATA.selector);
        superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK);
    }

    /*//////////////////////////////////////////////////////////////
                       GROUP 3: COMPARISON TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Raw feed level: BasefeeGasOracle vs the live Chainlink Fast Gas feed it replaces
    function test_Compare_RawAnswers_BasefeeVsChainlink() public view {
        (, int256 clAnswer,, uint256 clUpdatedAt,) = AggregatorV3Interface(CHAINLINK_GAS_ORACLE).latestRoundData();
        int256 bfAnswer = basefeeOracle.latestAnswer();

        console2.log("=== Raw answer comparison (wei per gas) ===");
        console2.log("Chainlink Fast Gas:", uint256(clAnswer));
        console2.log("  updatedAt:", clUpdatedAt);
        console2.log("BasefeeGasOracle:", uint256(bfAnswer));
        console2.log("  block.basefee:", block.basefee);
        console2.log("Ratio basefee/chainlink (bps):", uint256(bfAnswer) * 10_000 / uint256(clAnswer));

        // Identical unit convention - the drop-in requirement
        assertEq(
            basefeeOracle.decimals(), AggregatorV3Interface(CHAINLINK_GAS_ORACLE).decimals(), "decimals must match"
        );
        // Same order of magnitude: a 1e9 unit error in either direction blows this band
        assertLe(uint256(bfAnswer), uint256(clAnswer) * 5, "basefee answer >5x Chainlink");
        assertGe(uint256(bfAnswer) * 5, uint256(clAnswer), "basefee answer <0.2x Chainlink");
    }

    /// @notice Legacy-interface level: latestAnswer() on BasefeeGasOracle and on the live
    ///         Chainlink Fast Gas proxy must be denominated identically - both 0 decimals,
    ///         both wei per gas, and both internally consistent with latestRoundData()
    function test_Compare_LatestAnswer_SameDecimalsAndUnit() public view {
        // Both feeds must declare 0 decimals - the answer is directly wei per gas unit
        assertEq(basefeeOracle.decimals(), 0, "BasefeeGasOracle decimals must be 0");
        assertEq(AggregatorV3Interface(CHAINLINK_GAS_ORACLE).decimals(), 0, "Fast Gas decimals must be 0");

        // Legacy latestAnswer() must agree with latestRoundData().answer on each feed
        int256 bfLegacy = basefeeOracle.latestAnswer();
        (, int256 bfRound,,,) = basefeeOracle.latestRoundData();
        assertEq(bfLegacy, bfRound, "BasefeeGasOracle latestAnswer != latestRoundData answer");

        int256 clLegacy = IAggregatorLegacy(CHAINLINK_GAS_ORACLE).latestAnswer();
        (, int256 clRound,,,) = AggregatorV3Interface(CHAINLINK_GAS_ORACLE).latestRoundData();
        assertEq(clLegacy, clRound, "Fast Gas latestAnswer != latestRoundData answer");

        console2.log("=== latestAnswer() comparison (wei per gas, 0 decimals) ===");
        console2.log("Chainlink Fast Gas latestAnswer:", uint256(clLegacy));
        console2.log("BasefeeGasOracle latestAnswer:", uint256(bfLegacy));

        // Same unit: the two legacy answers must be the same order of magnitude - a decimals
        // or wei/gwei mismatch (1e9-scale) blows this band by ~8 orders of magnitude
        assertGt(clLegacy, 0, "Fast Gas legacy answer must be positive");
        assertGt(bfLegacy, 0, "BasefeeGasOracle legacy answer must be positive");
        assertLe(uint256(bfLegacy), uint256(clLegacy) * 5, "latestAnswer >5x Fast Gas: unit mismatch");
        assertGe(uint256(bfLegacy) * 5, uint256(clLegacy), "latestAnswer <0.2x Fast Gas: unit mismatch");
    }

    /// @notice Provider level: after migration both providers serve GAS->WEI; the AVERAGE path
    ///         must be exactly the mean of the two live quotes
    function test_Compare_ProviderQuotes_AndAverageIsExactMean() public {
        _migrate();
        _setFeedsMaxStaleness(30 days, true); // both feeds live

        (uint256 clQuote,,,) = superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK);
        (uint256 sfQuote,,,) = superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM);
        (uint256 avgQuote,, uint256 totalProviders, uint256 availableProviders) =
            superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);

        console2.log("=== GAS->WEI quotes for gasPerEntry gas units ===");
        console2.log("CHAINLINK provider:", clQuote);
        console2.log("SUPERFORM provider:", sfQuote);
        console2.log("AVERAGE:", avgQuote);

        assertEq(totalProviders, 2, "both providers registered");
        assertEq(availableProviders, 2, "both providers live");
        assertEq(avgQuote, (clQuote + sfQuote) / 2, "AVERAGE must be the exact integer mean");
        // Sanity band between the sources themselves
        assertLe(sfQuote, clQuote * 5, "SUPERFORM quote >5x CHAINLINK");
        assertGe(sfQuote * 5, clQuote, "SUPERFORM quote <0.2x CHAINLINK");
    }

    /// @notice Full-cost level: upkeep cost across the three regimes on the same fork block -
    ///         Chainlink-only (production today), blended AVERAGE, and basefee-only (post-freeze)
    function test_Compare_UpkeepCost_AcrossAllThreeRegimes() public {
        // Regime 1: production today - Chainlink Fast Gas only
        uint256 chainlinkOnlyCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        // Regime 2: post-migration, both feeds live - blended AVERAGE
        _migrate();
        _setFeedsMaxStaleness(30 days, true);
        uint256 blendedCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        // Regime 3: Fast Gas frozen/stale - basefee only
        _setFastGasStale();
        uint256 basefeeOnlyCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        console2.log("=== Upkeep cost per single update (UP token) ===");
        console2.log("Regime 1 - Chainlink only:", chainlinkOnlyCost);
        console2.log("Regime 2 - blended AVERAGE:", blendedCost);
        console2.log("Regime 3 - basefee only:", basefeeOnlyCost);
        console2.log("basefee/chainlink cost ratio (bps):", basefeeOnlyCost * 10_000 / chainlinkOnlyCost);

        assertGt(chainlinkOnlyCost, 0);
        assertGt(blendedCost, 0);
        assertGt(basefeeOnlyCost, 0);

        // The blend sits between the two solo regimes (cost is monotone in the gas quote;
        // tolerance covers per-hop integer rounding)
        uint256 lo = Math.min(chainlinkOnlyCost, basefeeOnlyCost);
        uint256 hi = Math.max(chainlinkOnlyCost, basefeeOnlyCost);
        assertGe(blendedCost + 2, lo, "blended cost below both solo regimes");
        assertLe(blendedCost, hi + 2, "blended cost above both solo regimes");

        // Migration acceptance band: the new pricing source stays within 2x of what the
        // deployed Chainlink feed charges on this same block
        // Band [0.2x, 3x]: catches unit errors while tolerating the deliberate 2x multiplier -
        // 2x basefee legitimately approaches/exceeds 2x the Fast Gas cost when the feed's
        // fast-premium compresses toward 1.0. Upper bound = MAX_MULTIPLIER_BPS (3x).
        assertLe(basefeeOnlyCost, chainlinkOnlyCost * 3, "basefee cost >3x Chainlink cost");
        assertGe(basefeeOnlyCost * 5, chainlinkOnlyCost, "basefee cost <0.2x Chainlink cost");
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Bit-exact replication of SuperGovernor._convertGasToUpkeepToken using the live
    ///         SuperOracle AVERAGE quotes (the real production flow)
    function _manual3HopCost() internal view returns (uint256) {
        // Step 1: gas -> native (wei)
        (uint256 weiAmount,,,) = superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        // Step 2: native -> USD
        (uint256 nativeToUsd,,,) =
            superOracle.getQuoteFromProvider(weiAmount, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        // Step 3: USD per 1 UPKEEP_TOKEN
        (uint256 usdPerUpkeepToken,,,) =
            superOracle.getQuoteFromProvider(tokenUnit, upkeepToken, USD_TOKEN, AVERAGE_PROVIDER);
        // Final: required UPKEEP_TOKEN, rounded up (SuperGovernor.sol:845)
        return Math.mulDiv(nativeToUsd, tokenUnit, usdPerUpkeepToken, Math.Rounding.Ceil);
    }

    /// @notice Grant a SuperGovernor role by writing OZ 5.x AccessControl storage (slot 0) directly
    /// @dev Why storage manipulation: on a mainnet fork no test account holds ORACLE_MANAGER_ROLE and
    ///      DEFAULT_ADMIN_ROLE has been renounced on the live governor, so a role cannot be granted
    ///      through the contract API at all. Slot 0 is where non-upgradeable OZ 5.x AccessControl
    ///      keeps _roles; if SuperGovernor's inheritance order ever changes, the require below fails
    ///      loudly rather than silently corrupting state.
    function _grantRoleViaStorage(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 memberSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(address(governor), memberSlot, bytes32(uint256(1)));
        require(governor.hasRole(role, account), "Failed to grant role via storage");
    }

    /// @notice Queue + execute the additive SUPERFORM registration through real governance
    function _migrate() internal {
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_SUPERFORM;
        feeds[0] = address(basefeeOracle);

        vm.prank(oracleManager);
        governor.queueOracleUpdate(bases, quotes, providers, feeds);
        vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
        vm.prank(oracleManager);
        governor.executeOracleUpdate();
    }

    /// @notice Raise staleness so post-warp fork data stays valid for the 3-hop conversion
    /// @param includeFastGas When false, Fast Gas keeps the governor-enforced minimum staleness
    ///        and is therefore stale after the 1-week timelock warp
    function _setFeedsMaxStaleness(uint256 staleness, bool includeFastGas) internal {
        vm.startPrank(oracleManager);
        governor.setOracleMaxStaleness(staleness);

        address[] memory feeds = new address[](4);
        feeds[0] = CHAINLINK_ETH_USD_ORACLE;
        feeds[1] = FIXED_PRICE_ORACLE;
        feeds[2] = address(basefeeOracle);
        feeds[3] = CHAINLINK_GAS_ORACLE;

        uint256[] memory stalenesses = new uint256[](4);
        stalenesses[0] = staleness;
        stalenesses[1] = staleness;
        stalenesses[2] = staleness;
        stalenesses[3] = includeFastGas ? staleness : governor.getMinStaleness();

        governor.setOracleFeedMaxStalenessBatch(feeds, stalenesses);
        vm.stopPrank();
    }

    /// @notice Flip only the Fast Gas feed to the minimum staleness so it drops out of the AVERAGE
    function _setFastGasStale() internal {
        address[] memory feeds = new address[](1);
        feeds[0] = CHAINLINK_GAS_ORACLE;
        uint256[] memory stalenesses = new uint256[](1);
        stalenesses[0] = governor.getMinStaleness();

        vm.prank(oracleManager);
        governor.setOracleFeedMaxStalenessBatch(feeds, stalenesses);
    }
}
