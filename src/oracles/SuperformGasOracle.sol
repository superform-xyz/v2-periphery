// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";

/// @title SuperformGasOracle
/// @notice A Chainlink-compatible oracle that returns gas price in Gwei, updated by a keeper
/// @dev Used as a gas price oracle on L2s where Chainlink's Fast Gas feed is not available.
///      Tracks round ID and update timestamp for proper staleness checks.
contract SuperformGasOracle is AggregatorV3Interface, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to set a zero gas price
    error INVALID_GAS_PRICE();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the gas price is updated
    /// @param oldGasPrice The previous gas price
    /// @param newGasPrice The new gas price
    event GasPriceUpdated(int256 oldGasPrice, int256 newGasPrice);

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The gas price in Gwei
    int256 private _answer;

    /// @notice Timestamp when the price was last updated
    uint256 private _updatedAt;

    /// @notice Current round ID (increments with each update)
    uint80 private _roundId;

    /// @notice The number of decimals (0 for Gwei)
    uint8 private constant DECIMALS = 0;

    /// @notice Description of the oracle
    string private constant DESCRIPTION = "Superform Fast Gas / Gwei";

    /// @notice Version of the oracle
    uint256 private constant VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the oracle with an initial gas price
    /// @param initialGasPrice The initial gas price in Gwei (must be > 0)
    /// @param owner_ The owner who can update the gas price (typically a keeper)
    constructor(int256 initialGasPrice, address owner_) Ownable(owner_) {
        if (initialGasPrice <= 0) revert INVALID_GAS_PRICE();
        _answer = initialGasPrice;
        _updatedAt = block.timestamp;
        _roundId = 1;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the gas price (called by keeper)
    /// @param newGasPrice The new gas price in Gwei (must be > 0)
    function setGasPrice(int256 newGasPrice) external onlyOwner {
        if (newGasPrice <= 0) revert INVALID_GAS_PRICE();
        int256 oldGasPrice = _answer;
        _answer = newGasPrice;
        _updatedAt = block.timestamp;
        unchecked {
            ++_roundId;
        }
        emit GasPriceUpdated(oldGasPrice, newGasPrice);
    }

    /*//////////////////////////////////////////////////////////////
                        AGGREGATOR V3 INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc AggregatorV3Interface
    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    /// @inheritdoc AggregatorV3Interface
    function description() external pure override returns (string memory) {
        return DESCRIPTION;
    }

    /// @inheritdoc AggregatorV3Interface
    function version() external pure override returns (uint256) {
        return VERSION;
    }

    /// @inheritdoc AggregatorV3Interface
    /// @dev This oracle only stores the latest round, so any roundId returns current data
    function getRoundData(uint80)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _roundId);
    }

    /// @inheritdoc AggregatorV3Interface
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _roundId);
    }

    /*//////////////////////////////////////////////////////////////
                            LEGACY INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the latest gas price (legacy interface)
    /// @return The gas price in Gwei
    function latestAnswer() external view returns (int256) {
        return _answer;
    }
}
