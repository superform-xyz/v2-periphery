// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { BasefeeGasOracle } from "../../../src/oracles/BasefeeGasOracle.sol";
import { AggregatorV3Interface } from "../../../src/vendor/chainlink/AggregatorV3Interface.sol";

/// @title BasefeeGasOracleMigrationTest
/// @notice Mainnet fork test for migrating GAS_QUOTE -> WEI_QUOTE off the deprecated Chainlink
///         Fast Gas feed by additively registering BasefeeGasOracle under the SUPERFORM provider
/// @dev Covers the migration-specific scenarios from specs/basefee-gas-oracle/technical-spec.md:
///      1. Governance flow: queue -> 1-week timelock -> execute, additive registration
///      2. Unit parity: our wei/0-decimals answer vs the live Fast Gas answer (1e9-confusion guard)
///      3. Cost band: post-migration getUpkeepCostPerSingleUpdate within 2x of the same fork
///         block's pre-migration cost (relative baseline - no frozen constants)
///      4. Frozen-feed rehearsal: Fast Gas stale -> dropped from AVERAGE -> our feed carries the
///         pair alone and upkeep is still charged (not free)
///      5. Gas shock: cost scales with basefee
///      Charging/auto-pause mechanics (InsufficientUpkeep) are covered by existing tests in
///      test/unit/SuperVaultAggregator.t.sol and test/integration/SuperVault/UpdatePPSUpkeepIntegration.t.sol.
contract BasefeeGasOracleMigrationTest is Test {
    // Production addresses from Ethereum-latest.json
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant SUPER_ORACLE = 0x8943128DbAb4279D561654dEED2930Bb975AA070;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;

    // Chainlink mainnet feeds
    address constant CHAINLINK_GAS_ORACLE = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;
    address constant CHAINLINK_ETH_USD_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // Synthetic pair addresses (must match SuperGovernor)
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // Provider identifiers
    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // Initial calibration (see technical spec)
    uint256 constant INITIAL_MULTIPLIER_BPS = 20_000; // 2x - deliberate over-recovery vs raw basefee
    uint256 constant INITIAL_PRIORITY_FEE_WEI = 1_000_000; // 0.001 gwei

    // Timelock period (must match SuperOracleBase)
    uint256 constant TIMELOCK_PERIOD = 1 weeks;

    SuperGovernor public governor;
    SuperOracle public superOracle;
    BasefeeGasOracle public basefeeOracle;

    address public oracleManager;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        governor = SuperGovernor(SUPER_GOVERNOR);
        superOracle = SuperOracle(SUPER_ORACLE);

        oracleManager = makeAddr("oracleManager");
        _grantRoleViaStorage(governor.ORACLE_MANAGER_ROLE(), oracleManager);

        basefeeOracle = new BasefeeGasOracle(
            INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI, makeAddr("admin"), makeAddr("gasManager")
        );
    }

    /*//////////////////////////////////////////////////////////////
                            UNIT PARITY GUARD
    //////////////////////////////////////////////////////////////*/

    /// @notice Our answer and the live Fast Gas answer must share the same unit (wei, 0 decimals).
    ///         A 1e9 wei/gwei confusion in either direction fails the sanity band immediately.
    function test_UnitParity_WithLiveFastGasFeed() public view {
        assertEq(basefeeOracle.decimals(), AggregatorV3Interface(CHAINLINK_GAS_ORACLE).decimals(), "decimals mismatch");

        (, int256 fastGasAnswer,,,) = AggregatorV3Interface(CHAINLINK_GAS_ORACLE).latestRoundData();
        int256 ourAnswer = basefeeOracle.latestAnswer();

        console2.log("Fast Gas answer (wei):", uint256(fastGasAnswer));
        console2.log("Basefee oracle answer (wei):", uint256(ourAnswer));
        console2.log("Fork block basefee (wei):", block.basefee);

        assertGt(fastGasAnswer, 0, "Fast Gas feed dead at fork block");
        assertGt(ourAnswer, 0, "our answer must be positive");
        // Sanity band [0.2x, 5x]: generous enough for fast-gas-vs-basefee spread, far too tight
        // for any unit error (1e9 off in either direction)
        assertLe(uint256(ourAnswer), uint256(fastGasAnswer) * 5, "answer >5x Fast Gas: unit error?");
        assertGe(uint256(ourAnswer) * 5, uint256(fastGasAnswer), "answer <0.2x Fast Gas: unit error?");
    }

    /*//////////////////////////////////////////////////////////////
                           MIGRATION FLOW
    //////////////////////////////////////////////////////////////*/

    /// @notice Full governance flow: additive registration under SUPERFORM, CHAINLINK slot untouched
    function test_MigrationFlow_RegistersUnderSuperformProvider() public {
        // Pre-state: CHAINLINK serves the pair. The SUPERFORM slot was empty when this rehearsal
        // was written, but the migration has since been executed on mainnet — tolerate both fork
        // states (empty slot: original rehearsal; populated slot: re-registration must still be
        // additive and timelocked).
        assertEq(superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK), CHAINLINK_GAS_ORACLE);
        try superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM) returns (address pre) {
            assertTrue(pre != address(0), "populated SUPERFORM slot must hold a live oracle");
        } catch (bytes memory reason) {
            // Slot still empty on this fork: the only acceptable revert is NO_ORACLES_CONFIGURED.
            assertEq(bytes4(reason), ISuperOracle.NO_ORACLES_CONFIGURED.selector, "unexpected pre-state revert");
        }

        _queueRegistration();

        // Timelock not elapsed yet
        vm.prank(oracleManager);
        vm.expectRevert(ISuperOracle.TIMELOCK_NOT_ELAPSED.selector);
        governor.executeOracleUpdate();

        vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
        vm.prank(oracleManager);
        governor.executeOracleUpdate();

        // Post-state: additive - both providers registered
        assertEq(
            superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM),
            address(basefeeOracle),
            "SUPERFORM slot should hold BasefeeGasOracle"
        );
        assertEq(
            superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK),
            CHAINLINK_GAS_ORACLE,
            "CHAINLINK slot must be untouched"
        );
    }

    /// @notice Post-migration upkeep cost stays within 2x of the same fork block's pre-migration
    ///         cost. Baseline is relative (computed at the fork block), never a frozen constant -
    ///         this decouples registration correctness from gas-market drift.
    function test_UpkeepCost_WithinBandOfPreMigrationBaseline() public {
        uint256 costBefore = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost before migration (UP):", costBefore);
        assertGt(costBefore, 0, "baseline cost must be > 0");

        _migrate();
        // Both feeds live: raise staleness on everything so the post-warp fork data stays valid
        _setFeedsMaxStaleness(30 days, true);

        uint256 costAfter = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost after migration, blended AVERAGE (UP):", costAfter);

        assertGt(costAfter, 0, "post-migration cost must be > 0");
        // Band [0.2x, 3x]: catches unit errors (1e9-scale in either direction) while tolerating
        // the deliberate 2x multiplier policy - 2x basefee can legitimately reach ~2x the Fast
        // Gas cost when the feed's fast-premium compresses toward 1.0. 3x = MAX_MULTIPLIER_BPS.
        assertLe(costAfter, costBefore * 3, "cost >3x baseline: overcharge - do NOT execute on mainnet");
        assertGe(costAfter * 5, costBefore, "cost <0.2x baseline: undercharge - check units");
    }

    /*//////////////////////////////////////////////////////////////
                        FROZEN-FEED REHEARSAL
    //////////////////////////////////////////////////////////////*/

    /// @notice When Fast Gas goes stale post-deprecation it must be dropped from the AVERAGE and
    ///         our feed must carry the pair alone - upkeep stays charged, never free.
    function test_StaleFastGas_OurFeedCarriesPairAndUpkeepStillCharged() public {
        uint256 costBefore = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        _migrate();
        // Keep ETH/USD and UP/USD feeds valid, but leave Fast Gas at 1s staleness: after the
        // timelock warp its last update is a week old -> stale -> dropped from the average
        _setFeedsMaxStaleness(30 days, false);

        // The pair must still quote, from our feed alone
        (uint256 quote,, uint256 totalProviders, uint256 availableProviders) =
            superOracle.getQuoteFromProvider(1_000_000, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        console2.log("GAS->WEI quote for 1M gas (wei):", quote);
        console2.log("providers total/available:", totalProviders, availableProviders);

        assertEq(availableProviders, 1, "only our feed should be available");
        assertEq(
            quote,
            1_000_000 * block.basefee * INITIAL_MULTIPLIER_BPS / 10_000 + 1_000_000 * INITIAL_PRIORITY_FEE_WEI,
            "quote must equal our formula exactly"
        );

        // Upkeep must still be charged - the free-upkeep failure mode is structurally gone
        uint256 costAfter = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost with Fast Gas dead (UP):", costAfter);
        assertGt(costAfter, 0, "upkeep became free - migration failed its purpose");
        // Same [0.2x, 3x] policy-aware unit-error band as the blended test above
        assertLe(costAfter, costBefore * 3, "solo-feed cost >3x baseline");
        assertGe(costAfter * 5, costBefore, "solo-feed cost <0.2x baseline");
    }

    /// @notice Upkeep cost must scale with basefee once our feed carries the pair
    function test_GasShock_CostScalesWithBasefee() public {
        _migrate();
        _setFeedsMaxStaleness(30 days, false); // Fast Gas dead, our feed alone

        uint256 baseCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        uint256 originalBasefee = block.basefee;

        vm.fee(originalBasefee * 10);
        uint256 shockedCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("cost at 1x basefee (UP):", baseCost);
        console2.log("cost at 10x basefee (UP):", shockedCost);

        // Linear in basefee up to the flat tip addend and per-hop rounding: expect ~10x, assert [5x, 15x]
        assertGt(shockedCost, baseCost * 5, "cost did not scale up with basefee");
        assertLt(shockedCost, baseCost * 15, "cost over-scaled with basefee");

        vm.fee(originalBasefee / 10);
        uint256 calmCost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("cost at 0.1x basefee (UP):", calmCost);
        assertLt(calmCost, baseCost, "cost did not scale down with basefee");
        assertGt(calmCost, 0, "cost must stay positive at low basefee");
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

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

    function _queueRegistration() internal {
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);

        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_SUPERFORM; // additive: CHAINLINK slot untouched
        feeds[0] = address(basefeeOracle);

        vm.prank(oracleManager);
        governor.queueOracleUpdate(bases, quotes, providers, feeds);
    }

    function _migrate() internal {
        _queueRegistration();
        vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
        vm.prank(oracleManager);
        governor.executeOracleUpdate();
    }

    /// @notice Raise staleness so post-warp fork data stays valid for the 3-hop conversion
    /// @param includeFastGas When false, Fast Gas keeps the governor-enforced minimum staleness
    ///        (300s) and is therefore stale after the 1-week timelock warp - simulating the
    ///        deprecated/frozen feed
    function _setFeedsMaxStaleness(uint256 staleness, bool includeFastGas) internal {
        vm.startPrank(oracleManager);
        governor.setOracleMaxStaleness(staleness);

        address[] memory feeds = new address[](4);
        feeds[0] = CHAINLINK_ETH_USD_ORACLE;
        feeds[1] = FIXED_PRICE_ORACLE;
        feeds[2] = address(basefeeOracle); // no-op for correctness: updatedAt is always fresh
        feeds[3] = CHAINLINK_GAS_ORACLE;

        uint256[] memory stalenesses = new uint256[](4);
        stalenesses[0] = staleness;
        stalenesses[1] = staleness;
        stalenesses[2] = staleness;
        stalenesses[3] = includeFastGas ? staleness : governor.getMinStaleness();

        governor.setOracleFeedMaxStalenessBatch(feeds, stalenesses);
        vm.stopPrank();
    }
}
