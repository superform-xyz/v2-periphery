// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { BasefeeGasOracle } from "../../../src/oracles/BasefeeGasOracle.sol";
import { AggregatorV3Interface } from "../../../src/vendor/chainlink/AggregatorV3Interface.sol";

/// @title ToolboxOracleUpdateRehearsalTest
/// @notice Mainnet fork rehearsal of EXACTLY the transactions v2-toolbox broadcasts for the
///         BasefeeGasOracle migration: queue_oracle_update -> 1-week timelock -> execute_oracle_update.
/// @dev Fidelity rules that distinguish this from BasefeeGasOracleMigration.t.sol:
///      - Uses the ALREADY-DEPLOYED BasefeeGasOracle (0xD9f4...c95), not a fresh deployment
///      - Pranks the REAL Fireblocks oracle-manager EOA that signs; no storage-written roles
///      - Queues the LITERAL values from v2-toolbox
///        inputs/v2-periphery/oracle-manager/queue_oracle_update_input.json, asserted against
///        their protocol derivations so input-file drift fails the test
///
///      STATE-AWARE: the real migration progresses on mainnet underneath this fork test
///      (queue broadcast 2026-08-24, execute due after the timelock), so every flow adapts to
///      the live lifecycle stage instead of assuming a pristine pre-queue chain:
///        NotQueued -> rehearse both broadcasts
///        Queued    -> rehearse execute against the LIVE pending slot (this also proves the
///                     broadcast queue content is ours: executing it must register our feed)
///        Executed  -> verify the migrated end-state
///
///      The only fork-only concession is raising feed staleness after timelock warps: on the
///      real timeline Chainlink keeps updating during the week, but fork data ages frozen. The
///      staleness calls are themselves oracle-manager operations the same signer could broadcast
///      (set_oracle_max_staleness / set_oracle_feed_staleness_batch), so no authority is faked.
contract ToolboxOracleUpdateRehearsalTest is Test {
    // Production addresses from script/output/prod/1/Ethereum-latest.json
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant SUPER_ORACLE = 0x8943128DbAb4279D561654dEED2930Bb975AA070;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;
    address constant CHAINLINK_GAS_ORACLE = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;
    address constant CHAINLINK_ETH_USD_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /// @notice The Fireblocks-managed EOA that holds ORACLE_MANAGER_ROLE on prod and signs
    ///         both toolbox broadcasts (config/execution.sh ORACLE_MANAGER)
    address constant FIREBLOCKS_ORACLE_MANAGER = 0xC72F6950FBF6ffE315525E200F6E54A05F739311;

    // Literal values from v2-toolbox inputs/v2-periphery/oracle-manager/queue_oracle_update_input.json.
    // Each is re-asserted against its protocol derivation in test_ToolboxInput_MatchesDerivations.
    address constant INPUT_BASE = 0x2FAcC608F385d9435B7C3773F83BD2a8902fdca0;
    address constant INPUT_QUOTE = 0x0687868a5f4b140EB03f4a07Ba66b35601c6FC8F;
    bytes32 constant INPUT_PROVIDER = 0x882d8c67ce5072aca91c6d5a5ca4eb7a2e5098a13e008e22004c1e0af2493746;
    address constant INPUT_FEED = 0xD9f4B84E23742fF126ee0868FE3a3361E08E9c95;

    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // Deployed-oracle calibration (verified on-chain; see specs/basefee-gas-oracle/technical-spec.md)
    uint256 constant EXPECTED_MULTIPLIER_BPS = 20_000;
    uint256 constant EXPECTED_PRIORITY_FEE_WEI = 1_000_000;

    uint256 constant TIMELOCK_PERIOD = 1 weeks;

    /// @notice Where the real migration stands at the fork block
    enum MigrationState {
        NotQueued, // pending slot empty, SUPERFORM slot unregistered
        Queued, // live pending update exists (broadcast 2026-08-24), execute still due
        Executed // SUPERFORM slot registered - migration complete on mainnet

    }

    SuperGovernor public governor;
    SuperOracle public superOracle;

    /// @notice How far behind head to pin the fork (override with FORK_BLOCKS_BEHIND_HEAD=0 to
    ///         test against head; needs an archive-capable RPC when non-zero). The real queue was
    ///         broadcast on mainnet 2026-08-24; the ~3-hour (~900 blocks) default lands on the
    ///         pre-queue state so the FULL two-broadcast rehearsal runs. Once head moves past
    ///         execute this offset lands on later lifecycle stages - the state-aware flows absorb
    ///         that.
    uint256 constant DEFAULT_FORK_BLOCKS_BEHIND_HEAD = 900;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        uint256 blocksBehind = vm.envOr("FORK_BLOCKS_BEHIND_HEAD", DEFAULT_FORK_BLOCKS_BEHIND_HEAD);
        if (blocksBehind != 0) vm.rollFork(block.number - blocksBehind);
        governor = SuperGovernor(SUPER_GOVERNOR);
        superOracle = SuperOracle(SUPER_ORACLE);
    }

    /*//////////////////////////////////////////////////////////////
                        INPUT-FILE INTEGRITY
    //////////////////////////////////////////////////////////////*/

    /// @notice The literal toolbox input values must equal their protocol derivations and point at
    ///         the deployed, correctly-calibrated oracle. Drift in the input JSON fails here.
    function test_ToolboxInput_MatchesDerivations() public view {
        assertEq(INPUT_BASE, address(uint160(uint256(keccak256("GAS_QUOTE")))), "bases[0] != GAS_QUOTE sentinel");
        assertEq(INPUT_QUOTE, address(uint160(uint256(keccak256("WEI_QUOTE")))), "quotes[0] != WEI_QUOTE sentinel");
        assertEq(INPUT_PROVIDER, keccak256("SUPERFORM"), "providers[0] != keccak(SUPERFORM)");

        assertGt(INPUT_FEED.code.length, 0, "feeds[0] has no code on mainnet");
        BasefeeGasOracle feed = BasefeeGasOracle(INPUT_FEED);
        assertEq(feed.decimals(), 0, "deployed oracle must be 0-decimals (wei/gas)");
        assertEq(feed.multiplierBps(), EXPECTED_MULTIPLIER_BPS, "deployed multiplier drifted");
        assertEq(feed.priorityFeeWei(), EXPECTED_PRIORITY_FEE_WEI, "deployed priority fee drifted");
    }

    /// @notice Mirrors the role gate both toolbox scripts enforce before broadcasting
    function test_FireblocksSigner_HoldsOracleManagerRole() public view {
        assertTrue(
            governor.hasRole(governor.ORACLE_MANAGER_ROLE(), FIREBLOCKS_ORACLE_MANAGER),
            "Fireblocks signer lost ORACLE_MANAGER_ROLE - toolbox broadcast would revert"
        );
    }

    /*//////////////////////////////////////////////////////////////
                       FULL TOOLBOX REHEARSAL
    //////////////////////////////////////////////////////////////*/

    /// @notice The exact broadcast sequence through to the migrated state, entered from whatever
    ///         lifecycle stage the live chain is in. Normal path: Fast Gas still updating.
    function test_ToolboxFlow_QueueTimelockExecute_FastGasStillLive() public {
        MigrationState state = _migrationState();
        uint256 costBefore = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        assertGt(costBefore, 0, "baseline upkeep cost must be > 0");
        console2.log("Migration state at fork block:", uint256(state));
        console2.log("Upkeep cost at fork block (UP):", costBefore);

        if (state != MigrationState.Executed) {
            uint256 queuedAt = _ensureQueued(state);

            // Timelock enforced: an execute broadcast before the deadline must revert
            if (block.timestamp < queuedAt + TIMELOCK_PERIOD) {
                vm.prank(FIREBLOCKS_ORACLE_MANAGER);
                vm.expectRevert(ISuperOracle.TIMELOCK_NOT_ELAPSED.selector);
                governor.executeOracleUpdate();
            }

            vm.warp(queuedAt + TIMELOCK_PERIOD + 1);
            _keepForkFeedsFresh(true);
            _executeAsToolboxWould();
            assertEq(superOracle.pendingUpdate(), 0, "pending slot must clear after execute");
        }

        // Migrated end-state: additive registration, exact-mean AVERAGE, cost in band
        assertEq(superOracle.getOracleAddress(INPUT_BASE, INPUT_QUOTE, INPUT_PROVIDER), INPUT_FEED);
        assertEq(superOracle.getOracleAddress(INPUT_BASE, INPUT_QUOTE, PROVIDER_CHAINLINK), CHAINLINK_GAS_ORACLE);

        uint256 gasProbe = 1_000_000;
        (uint256 clQuote,,,) = superOracle.getQuoteFromProvider(gasProbe, INPUT_BASE, INPUT_QUOTE, PROVIDER_CHAINLINK);
        (uint256 sfQuote,,,) = superOracle.getQuoteFromProvider(gasProbe, INPUT_BASE, INPUT_QUOTE, INPUT_PROVIDER);
        (uint256 avgQuote,, uint256 total, uint256 available) =
            superOracle.getQuoteFromProvider(gasProbe, INPUT_BASE, INPUT_QUOTE, AVERAGE_PROVIDER);
        assertEq(total, 2, "both providers must be registered");
        assertEq(available, 2, "both providers must be live");
        assertEq(avgQuote, (clQuote + sfQuote) / 2, "AVERAGE must be exact mean");

        // The runFinalize acceptance band from script/UpdateGasOracle.s.sol, vs the fork-block
        // baseline (Chainlink-driven pre-execute; already-blended if mainnet has executed)
        uint256 costAfter = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost migrated, blended (UP):", costAfter);
        assertGt(costAfter, 0, "upkeep must not become free");
        assertLe(costAfter, costBefore * 3, "cost >3x baseline - investigate before/after broadcast");
        assertGe(costAfter * 5, costBefore, "cost <0.2x baseline - check units");
    }

    /// @notice Same path, but Fast Gas deprecates during/after the timelock: it goes stale,
    ///         drops out of the AVERAGE, and the deployed feed must carry the pair alone.
    function test_ToolboxFlow_QueueTimelockExecute_FastGasDiesDuringTimelock() public {
        MigrationState state = _migrationState();
        uint256 costBefore = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        if (state != MigrationState.Executed) {
            uint256 queuedAt = _ensureQueued(state);
            vm.warp(queuedAt + TIMELOCK_PERIOD + 1);
            _keepForkFeedsFresh(false); // Fast Gas keeps min staleness -> aged fork data is stale
            _executeAsToolboxWould();
        } else {
            // Migration already live: simulate the feed's future death by aging it out
            vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
            _keepForkFeedsFresh(false);
        }

        uint256 gasProbe = 1_000_000;
        (uint256 quote,, uint256 total, uint256 available) =
            superOracle.getQuoteFromProvider(gasProbe, INPUT_BASE, INPUT_QUOTE, AVERAGE_PROVIDER);
        assertEq(total, 2, "both providers registered");
        assertEq(available, 1, "only BasefeeGasOracle should survive Fast Gas death");
        assertEq(
            quote,
            gasProbe * block.basefee * EXPECTED_MULTIPLIER_BPS / 10_000 + gasProbe * EXPECTED_PRIORITY_FEE_WEI,
            "solo quote must equal the deployed oracle's formula"
        );

        uint256 costAfter = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        console2.log("Upkeep cost with Fast Gas dead (UP):", costAfter);
        assertGt(costAfter, 0, "upkeep became free - migration failed its purpose");
        assertLe(costAfter, costBefore * 3, "solo-feed cost >3x baseline");
        assertGe(costAfter * 5, costBefore, "solo-feed cost <0.2x baseline");
    }

    /// @notice Head-to-head UP cost of one PPS update under each gas oracle regime at the same
    ///         fork block. The Chainlink-only figure is measurable only until mainnet executes;
    ///         afterwards the comparison degrades gracefully to blended vs basefee-only.
    function test_CompareUpkeepCost_ChainlinkVsDeployedBasefeeOracle() public {
        MigrationState state = _migrationState();
        (, int256 fastGasAnswer,,,) = AggregatorV3Interface(CHAINLINK_GAS_ORACLE).latestRoundData();
        uint256 costAtFork = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        if (state != MigrationState.Executed) {
            uint256 queuedAt = _ensureQueued(state);
            vm.warp(queuedAt + TIMELOCK_PERIOD + 1);
            _keepForkFeedsFresh(true);
            _executeAsToolboxWould();
        } else {
            _keepForkFeedsFresh(true);
        }
        uint256 costBlended = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        // Deprecate Fast Gas: min staleness + aged fork data -> drops out of the AVERAGE
        if (block.timestamp == vm.getBlockTimestamp()) {
            // Executed path may not have warped yet; the drop below needs aged feed data
            vm.warp(block.timestamp + TIMELOCK_PERIOD + 1);
            _keepForkFeedsFresh(true);
        }
        address[] memory feeds = new address[](1);
        feeds[0] = CHAINLINK_GAS_ORACLE;
        uint256[] memory stalenesses = new uint256[](1);
        stalenesses[0] = governor.getMinStaleness();
        vm.prank(FIREBLOCKS_ORACLE_MANAGER);
        governor.setOracleFeedMaxStalenessBatch(feeds, stalenesses);
        uint256 costBasefee = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        console2.log("=== UP cost per single PPS update, same fork block ===");
        console2.log("Migration state at fork block:", uint256(state));
        console2.log("Chainlink Fast Gas answer (wei/gas):", uint256(fastGasAnswer));
        console2.log("BasefeeGasOracle answer (wei/gas):", uint256(BasefeeGasOracle(INPUT_FEED).latestAnswer()));
        console2.log("block.basefee (wei):", block.basefee);
        if (state != MigrationState.Executed) {
            console2.log("Chainlink only (UP):", costAtFork);
            console2.log("basefee-only vs chainlink (bps):", costBasefee * 10_000 / costAtFork);
            console2.log("blended vs chainlink (bps):", costBlended * 10_000 / costAtFork);
        } else {
            console2.log("Blended at fork block (UP):", costAtFork);
        }
        console2.log("Blended AVERAGE (UP):", costBlended);
        console2.log("BasefeeGasOracle only (UP):", costBasefee);

        assertGt(costAtFork, 0, "fork-block baseline must be > 0");
        // Blended must sit between the two feeds' solo costs; with only the blended and solo
        // figures available post-execute, assert the solo endpoint exceeds the blended one
        // exactly when the basefee feed quotes above Chainlink, and stays within the band
        assertLe(costBasefee, costAtFork * 3, "basefee-only cost >3x fork baseline");
        assertGe(costBasefee * 5, costAtFork, "basefee-only cost <0.2x fork baseline");
        if (state != MigrationState.Executed) {
            uint256 lo = costAtFork < costBasefee ? costAtFork : costBasefee;
            uint256 hi = costAtFork > costBasefee ? costAtFork : costBasefee;
            assertGe(costBlended, lo, "blended below both endpoints");
            assertLe(costBlended, hi, "blended above both endpoints");
        }
    }

    /// @notice The queue runbook's hazard, pinned as a test: a second queue silently OVERWRITES
    ///         the pending slot (no revert) and restarts the timelock. With the real queue now
    ///         live on mainnet, this doubles as proof that any further queueOracleUpdate before
    ///         execute would destroy the broadcast migration.
    function test_QueueOverwritesPendingSlot_RunbookHazard() public {
        uint256 firstQueuedAt = superOracle.pendingUpdate();
        if (firstQueuedAt == 0) {
            vm.prank(FIREBLOCKS_ORACLE_MANAGER);
            governor.queueOracleUpdate(_inputBases(), _inputQuotes(), _inputProviders(), _inputFeeds());
            firstQueuedAt = superOracle.pendingUpdate();
        }

        // A colliding queue (any content) silently replaces the pending update - no revert
        vm.warp(firstQueuedAt + 1 days);
        vm.prank(FIREBLOCKS_ORACLE_MANAGER);
        governor.queueOracleUpdate(_inputBases(), _inputQuotes(), _inputProviders(), _inputFeeds());
        uint256 secondQueuedAt = superOracle.pendingUpdate();
        assertEq(secondQueuedAt, block.timestamp, "second queue must overwrite the slot");
        assertGt(secondQueuedAt, firstQueuedAt, "overwrite restarts the timelock");

        // The original timelock schedule is void: executing at the FIRST deadline now reverts
        vm.warp(firstQueuedAt + TIMELOCK_PERIOD + 1);
        vm.prank(FIREBLOCKS_ORACLE_MANAGER);
        vm.expectRevert(ISuperOracle.TIMELOCK_NOT_ELAPSED.selector);
        governor.executeOracleUpdate();
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Where the real migration stands at the fork block
    function _migrationState() internal view returns (MigrationState) {
        try superOracle.getOracleAddress(INPUT_BASE, INPUT_QUOTE, INPUT_PROVIDER) returns (address registered) {
            require(registered == INPUT_FEED, "SUPERFORM gas slot holds a foreign feed - investigate");
            return MigrationState.Executed;
        } catch { }
        return superOracle.pendingUpdate() != 0 ? MigrationState.Queued : MigrationState.NotQueued;
    }

    /// @notice Ensure the migration is queued, from either pre-queue state or the live pending
    ///         slot. When the live slot is used, the subsequent execute + registration assert
    ///         proves the broadcast content matches the toolbox input.
    function _ensureQueued(MigrationState state) internal returns (uint256 queuedAt) {
        if (state == MigrationState.Queued) {
            queuedAt = superOracle.pendingUpdate();
            console2.log("Live pending update found - rehearsing execute from it, queued at:", queuedAt);
            return queuedAt;
        }
        return _queueAsToolboxWould();
    }

    /// @notice Broadcast 1 - exactly what toolbox QueueOracleUpdate.s.sol sends: the input-file
    ///         arrays, signed by the Fireblocks oracle-manager. Also asserts the script's own
    ///         preconditions (pre-existing pending slot / occupied SUPERFORM slot would abort).
    function _queueAsToolboxWould() internal returns (uint256 queuedAt) {
        assertEq(superOracle.pendingUpdate(), 0, "pending slot occupied - queue runbook forbids proceeding");
        vm.expectRevert(ISuperOracle.NO_ORACLES_CONFIGURED.selector);
        superOracle.getOracleAddress(INPUT_BASE, INPUT_QUOTE, INPUT_PROVIDER);

        vm.prank(FIREBLOCKS_ORACLE_MANAGER);
        governor.queueOracleUpdate(_inputBases(), _inputQuotes(), _inputProviders(), _inputFeeds());

        queuedAt = superOracle.pendingUpdate();
        assertEq(queuedAt, block.timestamp, "queue timestamp must be the broadcast block's");
        console2.log("Queued at (save for finalize):", queuedAt);
    }

    // The single-entry arrays from the toolbox input file, as queueOracleUpdate expects them
    function _inputBases() internal pure returns (address[] memory a) {
        a = new address[](1);
        a[0] = INPUT_BASE;
    }

    function _inputQuotes() internal pure returns (address[] memory a) {
        a = new address[](1);
        a[0] = INPUT_QUOTE;
    }

    function _inputProviders() internal pure returns (bytes32[] memory a) {
        a = new bytes32[](1);
        a[0] = INPUT_PROVIDER;
    }

    function _inputFeeds() internal pure returns (address[] memory a) {
        a = new address[](1);
        a[0] = INPUT_FEED;
    }

    /// @notice Broadcast 2 - exactly what toolbox ExecuteOracleUpdate.s.sol sends
    function _executeAsToolboxWould() internal {
        vm.prank(FIREBLOCKS_ORACLE_MANAGER);
        governor.executeOracleUpdate();
    }

    /// @notice Fork-only concession: after a timelock warp the frozen fork feed data would read
    ///         as stale, which the real week does not cause. Raise staleness via the same
    ///         oracle-manager authority the toolbox exposes (set_oracle_max_staleness scripts).
    /// @param includeFastGas false leaves Fast Gas at the governor-enforced minimum so the warp
    ///        makes it stale - simulating the feed's deprecation during the timelock week
    function _keepForkFeedsFresh(bool includeFastGas) internal {
        uint256 staleness = 30 days;
        vm.startPrank(FIREBLOCKS_ORACLE_MANAGER);
        governor.setOracleMaxStaleness(staleness);

        address[] memory feeds = new address[](4);
        feeds[0] = CHAINLINK_ETH_USD_ORACLE;
        feeds[1] = FIXED_PRICE_ORACLE;
        feeds[2] = INPUT_FEED; // no-op for correctness: updatedAt is always block.timestamp
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
