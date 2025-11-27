// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// Superform

import { SuperOracleBase } from "./SuperOracleBase.sol";
import { ISuperOracleL2 } from "../interfaces/oracles/ISuperOracleL2.sol";

// external
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { BoringERC20 } from "../vendor/BoringSolidity/BoringERC20.sol";
import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title SuperOracleL2
/// @author Superform Labs
/// @notice Layer 2 Oracle for Superform
contract SuperOracleL2 is SuperOracleBase, ISuperOracleL2 {
    using BoringERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(address dataOracle => address uptimeOracle) public uptimeFeeds;
    mapping(address uptimeOracle => uint256 gracePeriod) public gracePeriods;

    /// @notice Default grace period after L2 sequencer restart (1 hour)
    /// @dev Prevents stale prices from being used immediately after sequencer downtime.
    ///      Price feeds collected during downtime may be unreliable or manipulated.
    uint256 private constant DEFAULT_GRACE_PERIOD_TIME = 3600;

    /// @notice Minimum allowed grace period (10 minutes)
    /// @dev Lower bound to ensure reasonable protection against stale data after sequencer restart
    uint256 private constant MIN_GRACE_PERIOD_TIME = 600;

    constructor(
        address superGovernor_,
        address[] memory bases,
        address[] memory quotes,
        bytes32[] memory providers,
        address[] memory feeds
    )
        SuperOracleBase(superGovernor_, bases, quotes, providers, feeds)
    { }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperOracleL2
    function batchSetUptimeFeed(
        address[] calldata dataOracles,
        address[] calldata uptimeOracles,
        uint256[] calldata gracePeriods_
    )
        external
        override
    {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        uint256 length = dataOracles.length;
        if (length == 0) revert ZERO_ARRAY_LENGTH();
        if (length != uptimeOracles.length || length != gracePeriods_.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i; i < length; ++i) {
            address dataOracle = dataOracles[i];
            address uptimeOracle = uptimeOracles[i];
            uint256 gracePeriod = gracePeriods_[i];
            if (gracePeriod != 0 && gracePeriod < MIN_GRACE_PERIOD_TIME) revert GRACE_PERIOD_TOO_LOW();

            if (dataOracle == address(0) || uptimeOracle == address(0)) revert ZERO_ADDRESS();

            uptimeFeeds[dataOracle] = uptimeOracle;
            gracePeriods[uptimeOracle] = gracePeriod;

            emit UptimeFeedSet(dataOracle, uptimeOracle);
            emit GracePeriodSet(uptimeOracle, gracePeriod);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _getQuoteFromOracle(
        address oracle,
        uint256 baseAmount,
        address base,
        address quote,
        bool revertOnError
    )
        internal
        view
        override
        returns (uint256 quoteAmount)
    {
        int256 answer;
        uint256 updatedAt;

        {
            address uptimeOracle = uptimeFeeds[oracle];
            if (uptimeOracle == address(0)) {
                if (revertOnError) revert NO_UPTIME_FEED();
                return 0;
            }

            // --- Get uptime round data ---
            uint256 gasBeforeUptime = gasleft();
            int256 uptimeAnswer;
            uint256 startedAt;

            try AggregatorV3Interface(uptimeOracle).latestRoundData() returns (
                uint80, int256 _uptimeAnswer, uint256 _startedAt, uint256, uint80
            ) {
                uptimeAnswer = _uptimeAnswer;
                startedAt = _startedAt;
            } catch {
                // EIP-150: Ensure at least 1/64 of gas remained to prevent out-of-gas reverts being misinterpreted as
                // oracle failures
                if (gasleft() <= gasBeforeUptime / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();

                if (revertOnError) revert ORACLE_ROUND_DATA_CALL_FAIL(uptimeOracle);
                return 0;
            }

            // Answer == 0: Sequencer is up
            // Answer == 1: Sequencer is down
            bool isSequencerUp = uptimeAnswer == 0;
            if (!isSequencerUp) {
                if (revertOnError) revert SEQUENCER_DOWN();
                return 0;
            }

            // Make sure the grace period has passed after the
            // sequencer is back up.
            uint256 timeSinceUp = block.timestamp - startedAt;
            uint256 gracePeriod = gracePeriods[uptimeOracle];
            if (gracePeriod == 0) {
                gracePeriod = DEFAULT_GRACE_PERIOD_TIME;
            }
            if (timeSinceUp <= gracePeriod) {
                if (revertOnError) revert GRACE_PERIOD_NOT_OVER();
                return 0;
            }
        }

        // --- Get data oracle round data ---
        {
            uint256 gasBeforeData = gasleft();

            try AggregatorV3Interface(oracle).latestRoundData() returns (
                uint80, int256 _answer, uint256, uint256 _updatedAt, uint80
            ) {
                answer = _answer;
                updatedAt = _updatedAt;
            } catch {
                // EIP-150: Ensure at least 1/64 of gas remained to prevent out-of-gas reverts being misinterpreted as
                // oracle failures
                if (gasleft() <= gasBeforeData / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();

                if (revertOnError) revert ORACLE_ROUND_DATA_CALL_FAIL(oracle);
                return 0;
            }
        }

        // Validate data
        uint256 limit =
            feedMaxStaleness[oracle] == 0 ? defaultStaleness : Math.min(feedMaxStaleness[oracle], defaultStaleness);
        if (answer <= 0 || block.timestamp - updatedAt > limit) {
            if (revertOnError) revert ORACLE_UNTRUSTED_DATA();
            return 0;
        }

        // Get decimals with error handling
        uint256 gasBefore = gasleft();
        try AggregatorV3Interface(oracle).decimals() returns (uint8 feedDecimals) {
            uint8 baseDecimals = IERC20(base).safeDecimals();
            uint8 quoteDecimals = IERC20(quote).safeDecimals();

            // Calculate quote amount with proper decimal scaling using shared function
            // casting to 'uint256' is safe because the answer is a valid int256
            // forge-lint: disable-next-line(unsafe-typecast)
            quoteAmount = _scaleQuoteAmount(baseAmount, uint256(answer), feedDecimals, baseDecimals, quoteDecimals);
        } catch {
            // EIP-150: Ensure at least 1/64 of gas remained to prevent out-of-gas reverts being misinterpreted as
            // oracle failures
            if (gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();
            if (revertOnError) revert ORACLE_DECIMALS_CALL_FAIL(oracle);
            return 0;
        }
    }
}
