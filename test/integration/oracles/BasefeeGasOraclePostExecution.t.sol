// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { BasefeeGasOracle } from "../../../src/oracles/BasefeeGasOracle.sol";

/// @title BasefeeGasOraclePostExecutionTest
/// @notice Verifies the LIVE, ALREADY-EXECUTED end state of the BasefeeGasOracle migration on an
///         Ethereum mainnet fork pinned at HEAD (execute was broadcast 2026-08-31). Distinct from:
///           - BasefeeGasOracleMigration.t.sol  : pre-migration parity + simulated execute flow
///           - ToolboxOracleUpdateRehearsal.t.sol: fidelity of the exact toolbox broadcasts
///         This file assumes the migration is DONE and checks the chain reflects it correctly.
///
/// @dev Why a fork and not a plain RPC eth_call: reading BasefeeGasOracle.latestAnswer() over a
///      normal eth_call returns only `priorityFeeWei` (~1e6 wei) because the BASEFEE opcode
///      evaluates to 0 in the call context on most RPC providers, collapsing
///      `_answer() = block.basefee*mult/1e4 + priorityFee` to just the priority term. A Foundry
///      fork sets `block.basefee` to the forked block's real base fee, so this is the only way to
///      observe (and assert) the true on-chain value. These tests PROVE the ~1e6 eth_call reading
///      is a measurement artifact, not a deployment defect.
///
///      Pins at head (no rollFork) because the executed state only exists at/after the execute
///      block. Needs a non-archive mainnet RPC in ETHEREUM_RPC_URL. Run:
///        ETHEREUM_RPC_URL=<rpc> forge test --match-contract BasefeeGasOraclePostExecutionTest -vv
contract BasefeeGasOraclePostExecutionTest is Test {
    // Production addresses from script/output/prod/1/Ethereum-latest.json
    address constant SUPER_ORACLE = 0x8943128DbAb4279D561654dEED2930Bb975AA070;
    address constant CHAINLINK_GAS_ORACLE = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;
    address constant BASEFEE_GAS_ORACLE = 0xD9f4B84E23742fF126ee0868FE3a3361E08E9c95;

    // GAS_QUOTE -> WEI_QUOTE pair under the SUPERFORM provider (the migrated registration)
    address constant GAS_QUOTE = 0x2FAcC608F385d9435B7C3773F83BD2a8902fdca0;
    address constant WEI_QUOTE = 0x0687868a5f4b140EB03f4a07Ba66b35601c6FC8F;
    bytes32 constant PROVIDER_SUPERFORM = 0x882d8c67ce5072aca91c6d5a5ca4eb7a2e5098a13e008e22004c1e0af2493746;
    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // Deployed-oracle calibration (see specs/basefee-gas-oracle/technical-spec.md)
    uint256 constant EXPECTED_MULTIPLIER_BPS = 20_000; // 2x
    uint256 constant EXPECTED_PRIORITY_FEE_WEI = 1_000_000; // 0.001 gwei
    uint256 constant BPS_DENOMINATOR = 10_000;

    SuperOracle public superOracle;
    BasefeeGasOracle public feed;

    function setUp() public {
        // Pin at head: the executed state only exists at/after the execute block.
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        superOracle = SuperOracle(SUPER_ORACLE);
        feed = BasefeeGasOracle(BASEFEE_GAS_ORACLE);

        // Guard: this file only makes sense once the migration is live on mainnet.
        assertEq(
            superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM),
            BASEFEE_GAS_ORACLE,
            "SUPERFORM slot not registered - migration not executed at this fork block"
        );
    }

    /// @dev Sanity that the fork actually supplies a real base fee, unlike a plain eth_call.
    ///      Every downstream assertion depends on this being non-zero.
    function _realBasefee() internal view returns (uint256 bf) {
        bf = block.basefee;
        assertGt(bf, 0, "fork block.basefee is 0 - RPC/fork not providing real basefee context");
    }

    /*//////////////////////////////////////////////////////////////
                        LIVE END-STATE STRUCTURE
    //////////////////////////////////////////////////////////////*/

    /// @notice Migration is executed and the registration is additive (Chainlink retained).
    function test_LiveState_ExecutedAndAdditive() public view {
        // Pending slot consumed by execute
        assertEq(superOracle.pendingUpdate(), 0, "pending slot must be cleared post-execute");

        // New SUPERFORM leaf points at our deployed basefee oracle
        assertEq(
            superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM),
            BASEFEE_GAS_ORACLE,
            "SUPERFORM provider must resolve to BasefeeGasOracle"
        );

        // Chainlink Fast Gas leaf is untouched (additive, not a replacement)
        assertEq(
            superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK),
            CHAINLINK_GAS_ORACLE,
            "Chainlink slot must remain registered (migration is additive)"
        );

        // Calibration unchanged on the live feed
        assertEq(feed.multiplierBps(), EXPECTED_MULTIPLIER_BPS, "multiplier drifted");
        assertEq(feed.priorityFeeWei(), EXPECTED_PRIORITY_FEE_WEI, "priority fee drifted");
        assertEq(feed.decimals(), 0, "feed must be 0-decimals (wei/gas)");
    }

    /*//////////////////////////////////////////////////////////////
                     REAL-BASEFEE PRICE CORRECTNESS
    //////////////////////////////////////////////////////////////*/

    /// @notice The core recheck: with a real base fee, latestAnswer follows the exact formula,
    ///         and is NOT the ~1e6 eth_call artifact.
    function test_LiveState_LatestAnswerMatchesFormula_NotEthCallArtifact() public view {
        uint256 bf = _realBasefee();
        uint256 expected = bf * EXPECTED_MULTIPLIER_BPS / BPS_DENOMINATOR + EXPECTED_PRIORITY_FEE_WEI;

        int256 ans = feed.latestAnswer();
        assertGt(ans, 0, "answer must be positive");
        assertEq(uint256(ans), expected, "latestAnswer != basefee*2 + priorityFee");

        // Explicitly prove this is the real value, not the eth_call collapse to priorityFee only.
        assertGt(
            uint256(ans),
            EXPECTED_PRIORITY_FEE_WEI,
            "answer collapsed to priorityFee - basefee not applied (would indicate the eth_call artifact)"
        );

        console2.log("block.basefee (wei):", bf);
        console2.log("latestAnswer  (wei):", uint256(ans));
    }

    /// @notice latestRoundData agrees with latestAnswer and carries sane round metadata.
    function test_LiveState_RoundDataConsistent() public view {
        _realBasefee();
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();

        assertEq(answer, feed.latestAnswer(), "roundData answer != latestAnswer");
        assertGt(roundId, 0, "roundId must be nonzero");
        assertEq(answeredInRound, roundId, "answeredInRound must equal roundId");
        assertEq(startedAt, block.timestamp, "startedAt must be current (computed-on-read feed)");
        assertEq(updatedAt, block.timestamp, "updatedAt must be current (never stale)");
    }

    /*//////////////////////////////////////////////////////////////
                     SUPERORACLE QUOTE PATH CORRECTNESS
    //////////////////////////////////////////////////////////////*/

    /// @notice Reading through SuperOracle under the SUPERFORM provider yields baseAmount * answer,
    ///         matching the raw feed (the sentinel base/quote decimals cancel; feed is 0-decimals).
    function test_LiveState_SuperformQuoteScalesWithGas() public view {
        _realBasefee();
        uint256 answer = uint256(feed.latestAnswer());

        uint256[3] memory gasProbes = [uint256(1), 1_000_000, 30_000_000];
        for (uint256 i; i < gasProbes.length; ++i) {
            (uint256 quoteAmount, uint256 deviation, uint256 totalProviders, uint256 availableProviders) =
                superOracle.getQuoteFromProvider(gasProbes[i], GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM);

            assertEq(quoteAmount, gasProbes[i] * answer, "SUPERFORM quote != gas * answer");
            assertEq(deviation, 0, "single-provider deviation must be 0");
            assertEq(totalProviders, 1, "single-provider totalProviders must be 1");
            assertEq(availableProviders, 1, "SUPERFORM (basefee) provider must always be available");
        }
    }

    /// @notice The AVERAGE provider blends both registered feeds. SUPERFORM (basefee) never goes
    ///         stale, so at least one provider is always available; when Chainlink is also fresh the
    ///         result is the exact mean of the two legs.
    function test_LiveState_AverageBlendsBothProviders() public view {
        _realBasefee();
        uint256 gasProbe = 1_000_000;

        (uint256 avgQuote,, uint256 totalProviders, uint256 availableProviders) =
            superOracle.getQuoteFromProvider(gasProbe, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);

        assertEq(totalProviders, 2, "two providers must be configured (Chainlink + Superform)");
        assertGe(availableProviders, 1, "at least the basefee provider must be available");
        assertGt(avgQuote, 0, "average quote must be positive");

        uint256 superformQuote = gasProbe * uint256(feed.latestAnswer());

        if (availableProviders == 2) {
            // Exact mean of the two legs
            (uint256 chainlinkQuote,,,) =
                superOracle.getQuoteFromProvider(gasProbe, GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK);
            assertEq(avgQuote, (superformQuote + chainlinkQuote) / 2, "AVERAGE != mean of the two legs");
            console2.log("superform leg (wei):", superformQuote);
            console2.log("chainlink leg (wei):", chainlinkQuote);
        } else {
            // Only the basefee leg fresh (Chainlink aged out at this fork block): average == it
            assertEq(avgQuote, superformQuote, "single available leg must equal SUPERFORM quote");
        }
        console2.log("available providers:", availableProviders);
        console2.log("blended quote (wei):", avgQuote);
    }

    /// @notice getQuote (IOracle path, implicit AVERAGE) returns the same blended figure.
    function test_LiveState_GetQuoteMatchesAverage() public view {
        _realBasefee();
        uint256 gasProbe = 1_000_000;

        uint256 iOracleQuote = superOracle.getQuote(gasProbe, GAS_QUOTE, WEI_QUOTE);
        (uint256 avgQuote,,,) = superOracle.getQuoteFromProvider(gasProbe, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);

        assertEq(iOracleQuote, avgQuote, "getQuote must equal AVERAGE provider quote");
    }
}
