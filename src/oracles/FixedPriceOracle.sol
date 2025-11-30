// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title FixedPriceOracle
/// @notice A Chainlink-compatible oracle that returns a fixed price set by the admin
/// @dev Used as a temporary UP/USD oracle. Always returns block.timestamp for updatedAt
///      to avoid staleness issues with oracle consumers.
contract FixedPriceOracle is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to set a zero price
    error INVALID_PRICE();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the fixed price is updated
    /// @param oldPrice The previous price
    /// @param newPrice The new price
    event PriceUpdated(int256 oldPrice, int256 newPrice);

    /// @notice Emitted when decimals are updated
    /// @param oldDecimals The previous decimals
    /// @param newDecimals The new decimals
    event DecimalsUpdated(uint8 oldDecimals, uint8 newDecimals);

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The fixed price to return
    int256 private _answer;

    /// @notice The number of decimals for the price
    uint8 private _decimals;

    /// @notice Description of the oracle
    string private constant DESCRIPTION = "Fixed Price Oracle";

    /// @notice Version of the oracle
    uint256 private constant VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the oracle with a fixed price and decimals
    /// @param initialPrice The initial fixed price (must be > 0)
    /// @param decimals_ The number of decimals (typically 8 for USD pairs)
    /// @param owner_ The owner who can update the price
    constructor(int256 initialPrice, uint8 decimals_, address owner_) Ownable(owner_) {
        if (initialPrice <= 0) revert INVALID_PRICE();
        _answer = initialPrice;
        _decimals = decimals_;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the fixed price
    /// @param newPrice The new price to set (must be > 0)
    function setPrice(int256 newPrice) external onlyOwner {
        if (newPrice <= 0) revert INVALID_PRICE();
        int256 oldPrice = _answer;
        _answer = newPrice;
        emit PriceUpdated(oldPrice, newPrice);
    }

    /// @notice Sets the decimals
    /// @param newDecimals The new decimals value
    function setDecimals(uint8 newDecimals) external onlyOwner {
        uint8 oldDecimals = _decimals;
        _decimals = newDecimals;
        emit DecimalsUpdated(oldDecimals, newDecimals);
    }

    /*//////////////////////////////////////////////////////////////
                        CHAINLINK INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the number of decimals
    /// @return The decimals value
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /// @notice Returns the description of this oracle
    /// @return The description string
    function description() external pure returns (string memory) {
        return DESCRIPTION;
    }

    /// @notice Returns the version of this oracle
    /// @return The version number
    function version() external pure returns (uint256) {
        return VERSION;
    }

    /// @notice Returns data for a specific round
    /// @dev Always returns the current fixed price with current timestamp
    /// @param _roundId The round ID (ignored, always returns current data)
    /// @return roundId The round ID (always 1)
    /// @return answer The fixed price
    /// @return startedAt The current block timestamp
    /// @return updatedAt The current block timestamp (prevents staleness issues)
    /// @return answeredInRound The round ID (always 1)
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, block.timestamp, block.timestamp, _roundId);
    }

    /// @notice Returns the latest round data
    /// @dev Always returns block.timestamp for updatedAt to avoid staleness issues
    /// @return roundId The round ID (always 1)
    /// @return answer The fixed price
    /// @return startedAt The current block timestamp
    /// @return updatedAt The current block timestamp (prevents staleness issues)
    /// @return answeredInRound The round ID (always 1)
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (1, _answer, block.timestamp, block.timestamp, 1);
    }

    /// @notice Returns the latest answer
    /// @return The fixed price as uint256
    function latestAnswer() external view returns (uint256) {
        // Safe cast: _answer is always > 0 (enforced in constructor and setPrice)
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(_answer);
    }

    /// @notice Returns the timestamp for a round
    /// @dev Always returns current block timestamp
    /// @param _roundId The round ID (ignored)
    /// @return The current block timestamp
    function getTimestamp(uint256 _roundId) external view returns (uint256) {
        // Silence unused parameter warning
        _roundId;
        return block.timestamp;
    }

    /// @notice Returns the current phase ID
    /// @return Always returns 1
    function phaseId() external pure returns (uint16) {
        return 1;
    }

    /// @notice Returns the aggregator for a phase
    /// @dev Returns this contract's address for phase 1, zero otherwise
    /// @param _phaseId The phase ID
    /// @return The aggregator address
    function phaseAggregators(uint16 _phaseId) external view returns (address) {
        if (_phaseId == 1) return address(this);
        return address(0);
    }
}
