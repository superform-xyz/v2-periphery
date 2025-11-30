// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { IOracle } from "../vendor/awesome-oracles/IOracle.sol";
import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { BoringERC20 } from "../vendor/BoringSolidity/BoringERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

// Superform
import { ISuperOracle } from "../interfaces/oracles/ISuperOracle.sol";

/// @title SuperOracle
/// @author Superform Labs
/// @notice Oracle for Superform
abstract contract SuperOracleBase is ISuperOracle, IOracle {
    using BoringERC20 for IERC20;

    /// @notice Mapping of feed to max staleness period
    mapping(address feed => uint256 maxStaleness) public feedMaxStaleness;

    uint256 public defaultStaleness;

    /// @notice Pending oracle update
    PendingUpdate public pendingUpdate;

    /// @notice Pending provider removal
    PendingRemoval public pendingRemoval;

    /// @notice Mapping of base asset to quote asset to oracle provider id to oracle feed address
    mapping(address base => mapping(address quote => mapping(bytes32 provider => address feed))) internal oracles;

    /// @notice Array of active provider ids
    bytes32[] public activeProviders;
    mapping(bytes32 provider => bool isSet) public isProviderSet;

    /// @notice Timelock period for oracle feed additions (1 week)
    /// @dev Long timelock protects against malicious oracle configurations that could manipulate pricing
    uint256 internal constant TIMELOCK_PERIOD = 1 weeks;
    /// @notice Short timelock period for provider removal (1 hour)
    /// @dev Trade-off: Short timelock enables rapid response to corrupted feeds (DoS prevention)
    ///      but provides limited time to detect malicious governance actions. Removal is safer
    ///      than addition since it only reduces available oracles rather than introducing new attack vectors.
    uint256 internal constant REMOVAL_TIMELOCK_PERIOD = 1 hours;
    /// @notice Maximum number of oracle providers to sample when calculating average price
    /// @dev Limits gas costs for getQuoteFromProvider(AVERAGE_PROVIDER).
    ///      10 providers balances price accuracy against gas costs (~300k gas for 10 oracle calls).
    ///      See _getAverageQuote() for sampling logic.
    uint256 internal constant MAX_SAMPLE_PROVIDERS = 10;
    /// @notice Maximum number of providers that can be removed in a single queued removal
    /// @dev Prevents excessive gas costs in executeProviderRemoval() loop.
    ///      Set to 20 (2x MAX_SAMPLE_PROVIDERS) to allow full provider rotation if needed.
    uint256 internal constant MAX_PROVIDER_REMOVALS = 20;
    bytes32 internal constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // SuperGovernor address
    address public immutable SUPER_GOVERNOR;

    /// @notice Initializes the oracle with governance authority and initial feed configurations
    /// @param superGovernor_ Immutable governance contract address (cannot be zero)
    /// @param bases Array of base asset addresses (token being priced)
    /// @param quotes Array of quote asset addresses (pricing denomination)
    /// @param providers Array of provider identifiers (e.g., keccak256("CHAINLINK"))
    /// @param feeds Array of Chainlink aggregator addresses for corresponding base/quote/provider triples
    /// @dev All arrays must have equal length. Sets default staleness to 1 day.
    constructor(
        address superGovernor_,
        address[] memory bases,
        address[] memory quotes,
        bytes32[] memory providers,
        address[] memory feeds
    ) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        SUPER_GOVERNOR = superGovernor_;
        defaultStaleness = 1 days;

        uint256 len = bases.length;
        if (len != quotes.length || len != providers.length || len != feeds.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        // validate oracle inputs
        _validateOracleInputs(bases, quotes, providers, feeds);

        // configure oracles
        _configureOracles(bases, quotes, providers, feeds);
        emit OraclesConfigured(bases, quotes, providers, feeds);
        uint256 length = feeds.length;
        for (uint256 i; i < length; ++i) {
            feedMaxStaleness[feeds[i]] = defaultStaleness;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperOracle
    function setDefaultStaleness(uint256 newMaxStaleness) external {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        defaultStaleness = newMaxStaleness;
        emit MaxStalenessUpdated(newMaxStaleness);
    }

    /// @inheritdoc ISuperOracle
    function setFeedMaxStaleness(address feed, uint256 newMaxStaleness) external {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        _setFeedMaxStaleness(feed, newMaxStaleness);
    }

    /// @inheritdoc ISuperOracle
    function setFeedMaxStalenessBatch(address[] calldata feeds, uint256[] calldata newMaxStalenessList) external {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        uint256 length = feeds.length;
        if (length == 0) revert ZERO_ARRAY_LENGTH();
        if (length != newMaxStalenessList.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i; i < length; ++i) {
            _setFeedMaxStaleness(feeds[i], newMaxStalenessList[i]);
        }
    }

    /// @inheritdoc ISuperOracle
    function queueOracleUpdate(
        address[] calldata bases,
        address[] calldata quotes,
        bytes32[] calldata providers,
        address[] calldata feeds
    )
        external
    {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        uint256 length = bases.length;
        if (length != quotes.length || length != providers.length || length != feeds.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        _validateOracleInputs(bases, quotes, providers, feeds);

        pendingUpdate = PendingUpdate({
            bases: bases, quotes: quotes, providers: providers, feeds: feeds, timestamp: block.timestamp
        });

        emit OracleUpdateQueued(bases, quotes, providers, feeds, block.timestamp);
    }

    /// @inheritdoc ISuperOracle
    function executeOracleUpdate() external {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        if (pendingUpdate.timestamp == 0) revert NO_PENDING_UPDATE();
        if (block.timestamp < pendingUpdate.timestamp + TIMELOCK_PERIOD) revert TIMELOCK_NOT_ELAPSED();

        _configureOracles(pendingUpdate.bases, pendingUpdate.quotes, pendingUpdate.providers, pendingUpdate.feeds);

        emit OracleUpdateExecuted(
            pendingUpdate.bases, pendingUpdate.quotes, pendingUpdate.providers, pendingUpdate.feeds
        );

        delete pendingUpdate;
    }

    /// @inheritdoc ISuperOracle
    function getOracleAddress(address base, address quote, bytes32 provider) external view returns (address oracle) {
        if (!isProviderSet[provider]) revert INVALID_ORACLE_PROVIDER();
        oracle = oracles[base][quote][provider];
        if (oracle == address(0)) revert NO_ORACLES_CONFIGURED();
    }

    /// @inheritdoc ISuperOracle
    function queueProviderRemoval(bytes32[] calldata providers) external {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();
        if (pendingRemoval.timestamp != 0) revert PENDING_UPDATE_EXISTS();

        uint256 length = providers.length;
        if (length == 0) revert ZERO_ARRAY_LENGTH();

        if (length > MAX_PROVIDER_REMOVALS) revert TOO_MANY_PROVIDERS();

        pendingRemoval = PendingRemoval({ providers: providers, timestamp: block.timestamp });

        emit ProviderRemovalQueued(providers, block.timestamp);
    }

    /// @inheritdoc ISuperOracle
    function executeProviderRemoval() external {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (pendingRemoval.timestamp == 0) revert NO_PENDING_UPDATE();
        if (block.timestamp < pendingRemoval.timestamp + REMOVAL_TIMELOCK_PERIOD) revert TIMELOCK_NOT_ELAPSED();

        bytes32[] memory providersToRemove = pendingRemoval.providers;

        // Loop through each provider to remove
        for (uint256 i; i < providersToRemove.length; i++) {
            bytes32 providerToRemove = providersToRemove[i];
            isProviderSet[providerToRemove] = false;

            // Find the provider in activeProviders array
            for (uint256 j; j < activeProviders.length; j++) {
                if (activeProviders[j] == providerToRemove) {
                    // Replace the provider to remove with the last provider in the array
                    if (j < activeProviders.length - 1) {
                        activeProviders[j] = activeProviders[activeProviders.length - 1];
                    }

                    // Remove the last element
                    activeProviders.pop();
                    break;
                }
            }
        }

        emit ProviderRemovalExecuted(providersToRemove);

        delete pendingRemoval;
    }

    /// @inheritdoc ISuperOracle
    function cancelProviderRemoval() external {
        if (msg.sender != SUPER_GOVERNOR) revert UNAUTHORIZED_UPDATE_AUTHORITY();

        if (pendingRemoval.timestamp == 0) revert NO_PENDING_UPDATE();

        bytes32[] memory cancelledProviders = pendingRemoval.providers;

        delete pendingRemoval;

        emit ProviderRemovalCancelled(cancelledProviders);
    }

    /// @inheritdoc ISuperOracle
    function getActiveProviders() external view returns (bytes32[] memory) {
        return activeProviders;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc ISuperOracle
    function getQuoteFromProvider(
        uint256 baseAmount,
        address base,
        address quote,
        bytes32 oracleProvider
    )
        public
        view
        virtual
        returns (uint256 quoteAmount, uint256 deviation, uint256 totalProviders, uint256 availableProviders)
    {
        // If average, calculate average of all oracles
        if (oracleProvider == AVERAGE_PROVIDER) {
            // activeProviders.length is already capped at MAX_SAMPLE_PROVIDERS by _configureOracles
            uint256 length = activeProviders.length;
            uint256[] memory validQuotes = new uint256[](length);
            uint256 count;
            (quoteAmount, validQuotes, totalProviders, count) = _getAverageQuote(base, quote, baseAmount, length);
            availableProviders = count;
            deviation = _calculateStdDev(validQuotes, count);
        } else {
            if (!isProviderSet[oracleProvider]) revert ORACLE_UNTRUSTED_DATA();
            address _oracle = oracles[base][quote][oracleProvider];
            if (_oracle == address(0)) revert NO_ORACLES_CONFIGURED();
            quoteAmount = _getQuoteFromOracle(_oracle, baseAmount, base, quote, true);
            deviation = 0;
            totalProviders = 1;
            availableProviders = 1;
        }
    }

    /// @inheritdoc IOracle
    function getQuote(
        uint256 baseAmount,
        address base,
        address quote
    )
        external
        view
        virtual
        returns (uint256 quoteAmount)
    {
        // using IOracle interface we always assume average provider
        (quoteAmount,,,) = getQuoteFromProvider(baseAmount, base, quote, AVERAGE_PROVIDER);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _validateOracleInputs(
        address[] memory bases,
        address[] memory quotes,
        bytes32[] memory providers,
        address[] memory feeds
    )
        internal
        pure
    {
        uint256 length = bases.length;
        for (uint256 i; i < length; ++i) {
            address base = bases[i];
            address quote = quotes[i];
            bytes32 provider = providers[i];
            address feed = feeds[i];

            if (provider == bytes32(0)) revert ZERO_PROVIDER();
            if (provider == AVERAGE_PROVIDER) revert AVERAGE_PROVIDER_NOT_ALLOWED();
            if (base == address(0) || quote == address(0) || feed == address(0)) revert ZERO_ADDRESS();
        }
    }

    /// @notice Internal setter for feed-specific staleness limits
    /// @param feed Oracle feed address
    /// @param newMaxStaleness Maximum staleness in seconds (0 means use defaultStaleness)
    /// @dev If newMaxStaleness > defaultStaleness, reverts with MAX_STALENESS_EXCEEDED.
    ///      Setting to 0 resets to defaultStaleness.
    function _setFeedMaxStaleness(address feed, uint256 newMaxStaleness) internal {
        if (newMaxStaleness > defaultStaleness) {
            revert MAX_STALENESS_EXCEEDED();
        }
        if (newMaxStaleness == 0) {
            newMaxStaleness = defaultStaleness;
        }
        feedMaxStaleness[feed] = newMaxStaleness;
        emit FeedMaxStalenessUpdated(feed, newMaxStaleness);
    }

    function _getQuoteFromOracle(
        address oracle,
        uint256 baseAmount,
        address base,
        address quote,
        bool revertOnError
    )
        internal
        view
        virtual
        returns (uint256 quoteAmount)
    {
        int256 answer;
        uint256 updatedAt;

        // --- Get round data ---
        uint256 gasBefore = gasleft();

        try AggregatorV3Interface(oracle).latestRoundData() returns (
            uint80, int256 _answer, uint256, uint256 _updatedAt, uint80
        ) {
            answer = _answer;
            updatedAt = _updatedAt;
        } catch {
            // Require that enough gas was provided to prevent an OOG revert
            // EIP-150: Ensure at least 1/64 of gas remained to prevent out-of-gas reverts being misinterpreted as
            // oracle failures
            if (revertOnError && gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();

            if (revertOnError) revert ORACLE_ROUND_DATA_CALL_FAIL(oracle);
            return 0;
        }

        // --- Validate data ---
        uint256 limit =
            feedMaxStaleness[oracle] == 0 ? defaultStaleness : Math.min(feedMaxStaleness[oracle], defaultStaleness);
        if (answer <= 0 || block.timestamp - updatedAt > limit) {
            if (revertOnError) revert ORACLE_UNTRUSTED_DATA();
            return 0;
        }

        gasBefore = gasleft();
        // --- Get decimals and compute scaled amount ---
        try AggregatorV3Interface(oracle).decimals() returns (uint8 feedDecimals) {
            uint8 baseDecimals = IERC20(base).safeDecimals();
            uint8 quoteDecimals = IERC20(quote).safeDecimals();

            // Calculate quote amount with proper decimal scaling
            // casting to 'uint256' is safe because the answer is a valid int256
            // forge-lint: disable-next-line(unsafe-typecast)
            quoteAmount = _scaleQuoteAmount(baseAmount, uint256(answer), feedDecimals, baseDecimals, quoteDecimals);
        } catch {
            // EIP-150: Ensure at least 1/64 of gas remained to prevent out-of-gas reverts being misinterpreted as
            // oracle failures
            if (revertOnError && gasleft() <= gasBefore / 64) revert INSUFFICIENT_GAS_FOR_EXTERNAL_CALL();

            if (revertOnError) revert ORACLE_DECIMALS_CALL_FAIL(oracle);
            return 0;
        }
    }

    /// @notice Scales quote amount using proper decimal conversion
    /// @param baseAmount Amount of base asset
    /// @param answer Oracle price answer
    /// @param feedDecimals Decimals of the oracle feed
    /// @param baseDecimals Decimals of the base asset
    /// @param quoteDecimals Decimals of the quote asset
    /// @return quoteAmount Scaled quote amount
    /// @dev Formula: quoteAmount = (baseAmount * answer * 10^quoteDecimals) / (10^(feedDecimals + baseDecimals))
    ///      This ensures proper decimal scaling across all three token types
    function _scaleQuoteAmount(
        uint256 baseAmount,
        uint256 answer,
        uint8 feedDecimals,
        uint8 baseDecimals,
        uint8 quoteDecimals
    )
        internal
        pure
        returns (uint256 quoteAmount)
    {
        return Math.mulDiv(baseAmount, uint256(answer) * 10 ** quoteDecimals, 10 ** (feedDecimals + baseDecimals));
    }

    /// @notice Calculates average quote across multiple oracle providers
    /// @param base Base asset address
    /// @param quote Quote asset address
    /// @param baseAmount Amount to convert
    /// @param numberOfProviders Maximum providers to sample (capped to activeProviders.length)
    /// @return quoteAmount Average of all valid oracle quotes
    /// @return validQuotes Array of valid quotes (only first `count` elements valid, rest are zero)
    /// @return totalCount Number of providers that have a configured oracle for this pair
    /// @return count Number of providers that successfully returned a valid quote
    /// @dev Gracefully skips providers without configured oracles or with untrusted data.
    ///      Early exits after MAX_SAMPLE_PROVIDERS valid quotes to bound gas costs.
    ///      Reverts only if NO valid quotes are found (all oracles failed or unconfigured).
    function _getAverageQuote(
        address base,
        address quote,
        uint256 baseAmount,
        uint256 numberOfProviders
    )
        internal
        view
        virtual
        returns (uint256 quoteAmount, uint256[] memory validQuotes, uint256 totalCount, uint256 count)
    {
        uint256 total;
        validQuotes = new uint256[](numberOfProviders);

        // Early exits after collecting MAX_SAMPLE_PROVIDERS valid quotes to bound gas usage.
        // Iterates through up to numberOfProviders registered oracles (capped at MAX_SAMPLE_PROVIDERS).
        for (uint256 i; i < numberOfProviders; ++i) {
            bytes32 provider = activeProviders[i];
            address providerOracle = oracles[base][quote][provider];
            // provider is in active list but has no available oracle address
            /*
            base = ETH
            quote = [USD, EUR]
            providers = [CHAINLINK, eORACLE]

            Let's say we have

            ETH -> USD -> CHAINLINK -> address(0x1)
            ETH -> USD - eORACLE -> address(0x2)
            ETH -> EUR -> CHAINLINK -> address(0x3)

            This would just continue for

            ETH -> EUR -> eOracle, because oracle address is 0
            */
            if (providerOracle == address(0)) continue;

            // We have one more registered oracle for this base asset
            unchecked {
                ++totalCount;
            }

            uint256 quote_ = _getQuoteFromOracle(providerOracle, baseAmount, base, quote, false);

            /// @dev we don't revert on error, we just skip the oracle value
            if (quote_ > 0) {
                total += quote_;
                validQuotes[count] = quote_;
                // This oracle is available
                unchecked {
                    ++count;
                }
                if (count == MAX_SAMPLE_PROVIDERS) {
                    break;
                }
            }
        }
        if (count == 0) revert NO_VALID_REPORTED_PRICES();

        quoteAmount = total / count;
    }

    function _getOracleDecimals(AggregatorV3Interface oracle_) internal view virtual returns (uint8) {
        return oracle_.decimals();
    }

    /// @notice Calculates standard deviation of oracle price quotes
    /// @param values Array of quote values
    /// @param length Number of valid elements in values array (first `length` elements)
    /// @return stddev Standard deviation (square root of variance)
    /// @dev Uses Babylonian square root method (_sqrt). Returns 0 if fewer than 2 values.
    ///      Used by getQuoteFromProvider() to measure price deviation across oracle providers.
    function _calculateStdDev(uint256[] memory values, uint256 length) internal pure virtual returns (uint256 stddev) {
        uint256 sum = 0;
        uint256 count = 0;
        for (uint256 i; i < length; ++i) {
            sum += values[i];
            count++;
        }
        if (count < 2) return 0;

        uint256 mean = sum / count;
        uint256 sumSquaredDiff = 0;
        for (uint256 i; i < length; ++i) {
            uint256 diff;
            if (values[i] >= mean) {
                diff = values[i] - mean;
            } else {
                diff = mean - values[i];
            }

            uint256 squaredDiff = Math.mulDiv(diff, diff, 1);
            sumSquaredDiff += squaredDiff;
        }

        uint256 variance = sumSquaredDiff / count;
        return _sqrt(variance);
    }

    /// @notice Calculates integer square root using Babylonian method
    /// @param x Value to calculate square root of
    /// @return y Integer square root (rounded down)
    /// @dev Iterative convergence algorithm. Safe for all uint256 values.
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /// @notice Internal function to configure oracle feeds and update active provider list
    /// @param bases Array of base asset addresses
    /// @param quotes Array of quote asset addresses
    /// @param providers Array of provider identifiers
    /// @param feeds Array of Chainlink aggregator addresses
    /// @dev Validates inputs via _validateOracleInputs() before calling.
    ///      Automatically adds new providers to activeProviders array (up to MAX_SAMPLE_PROVIDERS).
    ///      Reverts if adding a provider would exceed MAX_SAMPLE_PROVIDERS limit.
    function _configureOracles(
        address[] memory bases,
        address[] memory quotes,
        bytes32[] memory providers,
        address[] memory feeds
    )
        internal
    {
        uint256 length = bases.length;

        for (uint256 i; i < length; ++i) {
            address base = bases[i];
            address quote = quotes[i];
            bytes32 provider = providers[i];
            address feed = feeds[i];

            oracles[base][quote][provider] = feed;

            // Update activeProviders array - add provider if not already present
            bool providerExists = isProviderSet[provider];
            if (!providerExists) {
                if (activeProviders.length >= MAX_SAMPLE_PROVIDERS) {
                    revert TOO_MANY_PROVIDERS();
                }
                activeProviders.push(provider);
                isProviderSet[provider] = true;
            }
        }
    }
}
