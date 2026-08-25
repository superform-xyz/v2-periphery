// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { AggregatorV3Interface } from "../vendor/chainlink/AggregatorV3Interface.sol";

/// @title BasefeeGasOracle
/// @notice A Chainlink-compatible gas price oracle that computes its answer from block.basefee at read time
/// @dev Replaces the deprecated Chainlink Fast Gas feed on Ethereum mainnet for SuperOracle's
///      GAS_QUOTE -> WEI_QUOTE pair. The answer is denominated in wei per gas unit with 0 decimals,
///      matching the Fast Gas feed's convention (which was wei-denominated despite its "Gwei" name).
///
///      answer = block.basefee * multiplierBps / 10_000 + priorityFeeWei
///
///      The value is intrinsically fresh every block, so updatedAt = block.timestamp is semantically
///      honest and the feed can never go stale. No keeper or update transaction exists.
///
///      TRUST MODEL: fit for fee charging only, where the charge executes in the same transaction
///      that reads the oracle (block.basefee at read time is exactly what the transaction pays).
///      basefee is proposer-influenceable by +-12.5% per block, so this oracle must NOT be reused
///      for collateral or settlement pricing.
///
///      OFF-CHAIN CAVEAT: in a fee-field-less eth_call, nodes force block.basefee to 0, so off-chain
///      reads return only priorityFeeWei. Pass explicit gas-price fields to get true quotes.
contract BasefeeGasOracle is AggregatorV3Interface, AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when multiplierBps is outside [MIN_MULTIPLIER_BPS, MAX_MULTIPLIER_BPS]
    error INVALID_MULTIPLIER();

    /// @notice Thrown when priorityFeeWei exceeds MAX_PRIORITY_FEE_WEI
    error INVALID_PRIORITY_FEE();

    /// @notice Thrown when a zero address is provided for a role holder
    error ZERO_ADDRESS();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the basefee multiplier is updated
    /// @param oldMultiplierBps The previous multiplier in basis points
    /// @param newMultiplierBps The new multiplier in basis points
    event MultiplierUpdated(uint256 oldMultiplierBps, uint256 newMultiplierBps);

    /// @notice Emitted when the priority fee is updated
    /// @param oldPriorityFeeWei The previous priority fee in wei
    /// @param newPriorityFeeWei The new priority fee in wei
    event PriorityFeeUpdated(uint256 oldPriorityFeeWei, uint256 newPriorityFeeWei);

    /*//////////////////////////////////////////////////////////////
                                 ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Role that can update the pricing knobs
    /// @dev Reuses the platform-wide role string used by SuperGovernor
    bytes32 public constant GAS_MANAGER_ROLE = keccak256("GAS_MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                 BOUNDS
    //////////////////////////////////////////////////////////////*/

    /// @notice Minimum basefee multiplier (0.5x)
    uint256 public constant MIN_MULTIPLIER_BPS = 5000;

    /// @notice Maximum basefee multiplier (3x)
    uint256 public constant MAX_MULTIPLIER_BPS = 30_000;

    /// @notice Maximum priority fee addend (10 gwei)
    uint256 public constant MAX_PRIORITY_FEE_WEI = 10 gwei;

    /// @notice Basis points denominator
    uint256 private constant BPS_DENOMINATOR = 10_000;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Basefee multiplier in basis points (10_000 = 1x)
    /// @dev Packed with priorityFeeWei into a single slot; bounded well below uint128
    uint128 public multiplierBps;

    /// @notice Flat priority-fee addend in wei per gas unit
    uint128 public priorityFeeWei;

    /// @notice Timestamp of the last knob change, for off-chain stale-configuration monitoring
    uint256 public paramsLastUpdatedAt;

    /// @notice The number of decimals (0 - the answer is directly in wei per gas unit)
    uint8 private constant DECIMALS = 0;

    /// @notice Description of the oracle
    /// @dev Says "Wei" deliberately: the predecessor's "Fast Gas / Gwei" name over a
    ///      wei-denominated answer is a documented unit-confusion trap
    string private constant DESCRIPTION = "Basefee Gas / Wei";

    /// @notice Version of the oracle
    uint256 private constant VERSION = 1;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the oracle with bounded pricing knobs and split role holders
    /// @param multiplierBps_ Initial basefee multiplier in basis points (must be within bounds)
    /// @param priorityFeeWei_ Initial priority fee in wei (must be within bounds)
    /// @param admin_ Receives DEFAULT_ADMIN_ROLE (protocol multisig)
    /// @param gasManager_ Receives GAS_MANAGER_ROLE
    /// @dev admin_ != gasManager_ is NOT enforced on-chain - it is a deploy-script-only guarantee
    ///      (DeployBasefeeGasOracle requires it). A direct deployment can collapse both roles onto
    ///      one key; keep them split in production so a manager-key compromise cannot touch role
    ///      administration. Note the knob-set events emitted here carry oldValue = 0 (the true
    ///      prior storage state) - indexers should read constructor emissions as initialization.
    constructor(uint256 multiplierBps_, uint256 priorityFeeWei_, address admin_, address gasManager_) {
        if (admin_ == address(0) || gasManager_ == address(0)) revert ZERO_ADDRESS();
        _setMultiplierBps(multiplierBps_);
        _setPriorityFeeWei(priorityFeeWei_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GAS_MANAGER_ROLE, gasManager_);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the basefee multiplier
    /// @param newMultiplierBps The new multiplier in basis points, within [MIN_MULTIPLIER_BPS, MAX_MULTIPLIER_BPS]
    function setMultiplierBps(uint256 newMultiplierBps) external onlyRole(GAS_MANAGER_ROLE) {
        _setMultiplierBps(newMultiplierBps);
    }

    /// @notice Sets the priority fee addend
    /// @param newPriorityFeeWei The new priority fee in wei, at most MAX_PRIORITY_FEE_WEI
    function setPriorityFeeWei(uint256 newPriorityFeeWei) external onlyRole(GAS_MANAGER_ROLE) {
        _setPriorityFeeWei(newPriorityFeeWei);
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
    /// @dev The value is computed on read, so any roundId returns current data (no rounds exist)
    function getRoundData(uint80)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return _roundData();
    }

    /// @inheritdoc AggregatorV3Interface
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return _roundData();
    }

    /*//////////////////////////////////////////////////////////////
                            LEGACY INTERFACE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the latest gas price (legacy interface)
    /// @return The gas price in wei per gas unit
    function latestAnswer() external view returns (int256) {
        return _answer();
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Validates bounds, applies the write, stamps paramsLastUpdatedAt, then emits old/new
    function _setMultiplierBps(uint256 newMultiplierBps) internal {
        if (newMultiplierBps < MIN_MULTIPLIER_BPS || newMultiplierBps > MAX_MULTIPLIER_BPS) {
            revert INVALID_MULTIPLIER();
        }
        uint256 oldMultiplierBps = multiplierBps;
        // Safe cast: bounded at MAX_MULTIPLIER_BPS, far below uint128
        // forge-lint: disable-next-line(unsafe-typecast)
        multiplierBps = uint128(newMultiplierBps);
        paramsLastUpdatedAt = block.timestamp;
        emit MultiplierUpdated(oldMultiplierBps, newMultiplierBps);
    }

    /// @dev Validates the bound, applies the write, stamps paramsLastUpdatedAt, then emits old/new
    function _setPriorityFeeWei(uint256 newPriorityFeeWei) internal {
        if (newPriorityFeeWei > MAX_PRIORITY_FEE_WEI) revert INVALID_PRIORITY_FEE();
        uint256 oldPriorityFeeWei = priorityFeeWei;
        // Safe cast: bounded at MAX_PRIORITY_FEE_WEI (10 gwei), far below uint128
        // forge-lint: disable-next-line(unsafe-typecast)
        priorityFeeWei = uint128(newPriorityFeeWei);
        paramsLastUpdatedAt = block.timestamp;
        emit PriorityFeeUpdated(oldPriorityFeeWei, newPriorityFeeWei);
    }

    /// @dev Multiply-then-divide preserves precision at sub-gwei basefees.
    ///      SafeCast is defense-in-depth: the bounded formula cannot reach 2^255 for any
    ///      physically reachable basefee.
    function _answer() internal view returns (int256) {
        return SafeCast.toInt256(block.basefee * multiplierBps / BPS_DENOMINATOR + priorityFeeWei);
    }

    /// @dev roundId = answeredInRound = uint80(block.number): nonzero and monotonic, satisfying
    ///      both modern (updatedAt) and legacy (answeredInRound >= roundId, roundId != 0)
    ///      consumer checks. startedAt is never 0 (some consumers treat 0 as round-incomplete).
    function _roundData()
        internal
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = uint80(block.number);
        return (roundId, _answer(), block.timestamp, block.timestamp, roundId);
    }
}
