// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";

/// @title SuperformGasOracle
/// @notice A Chainlink-compatible oracle that returns gas price in Gwei, updated by a keeper
/// @dev Used as a gas price oracle on L2s where Chainlink's Fast Gas feed is not available.
///      Tracks round ID and update timestamp for proper staleness checks.
///      Returns gas price directly in Gwei with 0 decimals.
///      Example: 1 = 1 Gwei, 1000000 = 1,000,000 Gwei.
contract SuperformGasOracle is AggregatorV3Interface, AccessControl {
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

    /// @notice Emitted when useBlockTimestamp flag is changed
    /// @param enabled Whether block.timestamp is now used for timestamps
    event UseBlockTimestampChanged(bool enabled);

    /*//////////////////////////////////////////////////////////////
                                 ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role that can update the gas price
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The gas price in Gwei (0 decimals)
    int256 private _answer;

    /// @notice Timestamp when the price was last updated
    uint256 private _updatedAt;

    /// @notice Current round ID (increments with each update)
    uint80 private _roundId;

    /// @notice If true, return block.timestamp for startedAt/updatedAt instead of stored timestamp
    bool private _useBlockTimestamp = true;

    /// @notice The number of decimals (0 - value is directly in Gwei)
    /// @dev Gwei already has 9 decimals inherently (1 Gwei = 10^9 wei)
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
    /// @dev Example: 1 = 1 Gwei, 50 = 50 Gwei
    /// @param admin_ The admin who can grant/revoke roles (receives DEFAULT_ADMIN_ROLE)
    constructor(int256 initialGasPrice, address admin_) {
        if (initialGasPrice <= 0) revert INVALID_GAS_PRICE();
        _answer = initialGasPrice;
        _updatedAt = block.timestamp;
        _roundId = 1;

        // Grant admin role (can grant/revoke KEEPER_ROLE)
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        // Grant keeper role to admin initially
        _grantRole(KEEPER_ROLE, admin_);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the gas price (called by keeper or admin)
    /// @param newGasPrice The new gas price in Gwei (must be > 0)
    /// @dev Example: 1 = 1 Gwei, 50 = 50 Gwei
    function setGasPrice(int256 newGasPrice) external onlyRole(KEEPER_ROLE) {
        if (newGasPrice <= 0) revert INVALID_GAS_PRICE();
        int256 oldGasPrice = _answer;
        _answer = newGasPrice;
        _updatedAt = block.timestamp;
        unchecked {
            ++_roundId;
        }
        emit GasPriceUpdated(oldGasPrice, newGasPrice);
    }

    /// @notice Sets whether to use block.timestamp for startedAt/updatedAt
    /// @param enabled If true, getRoundData and latestRoundData return block.timestamp
    /// @dev When enabled, staleness checks will always pass (timestamp is always fresh)
    function setUseBlockTimestamp(bool enabled) external onlyRole(KEEPER_ROLE) {
        _useBlockTimestamp = enabled;
        emit UseBlockTimestampChanged(enabled);
    }

    /// @notice Returns whether block.timestamp is used for startedAt/updatedAt
    function useBlockTimestamp() external view returns (bool) {
        return _useBlockTimestamp;
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
        uint256 timestamp = _useBlockTimestamp ? block.timestamp : _updatedAt;
        return (_roundId, _answer, timestamp, timestamp, _roundId);
    }

    /// @inheritdoc AggregatorV3Interface
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint256 timestamp = _useBlockTimestamp ? block.timestamp : _updatedAt;
        return (_roundId, _answer, timestamp, timestamp, _roundId);
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
