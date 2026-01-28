// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPMarket } from "@pendle/interfaces/IPMarket.sol";
import { IPPrincipalToken } from "@pendle/interfaces/IPPrincipalToken.sol";

/// @title PendlePTAmortizedOracle
/// @author Superform Labs
/// @notice Provides amortized cost pricing for Pendle PT positions held by strategies
/// @dev Uses Book Value accounting with linear pull-to-par amortization
/// @dev Strategies call recordPurchase/recordRedemption directly via hooks
/// @dev recordPurchase: Called AFTER deposit - ptAmount is PT received from deposit hook
/// @dev recordRedemption: Called AFTER redeem - ptSold is PT that was sold
///
/// @dev TRUST MODEL: This oracle is permissionless - any address can record purchases/redemptions.
/// @dev Book values are stored per-caller (strategy => market => state), so callers can only
/// @dev affect their own recorded positions. A malicious caller cannot corrupt data for other strategies.
/// @dev The oracle simply tracks what each caller reports; it does not validate actual PT holdings.
contract PendlePTAmortizedOracle is AccessControl {
    using Math for uint256;
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Role for managers who can correct book values
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice State for tracking book value - stores values at last update
    /// @dev Packed into 2 storage slots (48 bytes)
    struct BookValueState {
        uint128 lastUpdateBookValue; // B(t0): Book value at last update
        uint64 lastUpdateTime; // t0: Timestamp of last update
        uint128 lastUpdatePtAmount; // A(t0): PT amount at last update (for amortization calc)
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Book value state per strategy per market
    /// @dev strategy => market => BookValueState
    mapping(address strategy => mapping(address market => BookValueState)) public bookValues;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when book value state is updated
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @param newBookValue The new book value after the update
    /// @param timestamp The timestamp of the update
    event BookValueUpdated(address indexed strategy, address indexed market, uint256 newBookValue, uint256 timestamp);

    /// @notice Emitted when book value is manually corrected by admin
    /// @param strategy The strategy address
    /// @param market The Pendle market address
    /// @param oldBookValue The previous book value
    /// @param newBookValue The corrected book value
    /// @param correctedBy The admin who made the correction
    event BookValueCorrected(
        address indexed strategy,
        address indexed market,
        uint256 oldBookValue,
        uint256 newBookValue,
        address indexed correctedBy
    );

    /// @notice Emitted when a PT purchase is recorded
    /// @param strategy The strategy address (msg.sender)
    /// @param market The Pendle market address
    /// @param sySpent Amount of SY spent on the purchase
    /// @param ptAmount Amount of PT received
    event PurchaseRecorded(
        address indexed strategy,
        address indexed market,
        uint256 sySpent,
        uint256 ptAmount
    );

    /// @notice Emitted when a PT redemption is recorded
    /// @param strategy The strategy address (msg.sender)
    /// @param market The Pendle market address
    /// @param ptSold Amount of PT sold/redeemed
    event RedemptionRecorded(
        address indexed strategy,
        address indexed market,
        uint256 ptSold
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when a zero address is provided
    error ZERO_ADDRESS();

    /// @notice Thrown when a zero amount is provided
    error ZERO_AMOUNT();

    /// @notice Thrown when querying a position that doesn't exist
    error NO_POSITION();

    /// @notice Thrown when trying to record a purchase after market has expired
    error MARKET_EXPIRED();

    /// @notice Thrown when redemption amount exceeds current holdings
    error INSUFFICIENT_POSITION();

    /// @notice Thrown when book value would exceed face value (sanity check)
    error BOOK_VALUE_EXCEEDS_FACE_VALUE();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the oracle with an admin
    /// @param admin The admin address who receives DEFAULT_ADMIN_ROLE and MANAGER_ROLE
    constructor(address admin) {
        if (admin == address(0)) revert ZERO_ADDRESS();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    /*//////////////////////////////////////////////////////////////
                          STRATEGY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Record a PT purchase - called by strategy via hooks AFTER deposit
    /// @dev msg.sender is the strategy being updated
    /// @dev Called AFTER deposit hook - ptAmount comes from deposit hook output (usePrevHookAmount)
    /// @param market The Pendle market address
    /// @param sySpent Amount of SY spent on the purchase (book value increment)
    /// @param ptAmount Amount of PT received from the purchase
    function recordPurchase(
        address market,
        uint256 sySpent,
        uint256 ptAmount
    )
        external
    {
        address strategy = msg.sender;
        if (market == address(0)) revert ZERO_ADDRESS();
        if (sySpent == 0 || ptAmount == 0) revert ZERO_AMOUNT();

        // Get PT address and maturity from market
        (, IPPrincipalToken pt,) = IPMarket(market).readTokens();
        uint256 maturity = pt.expiry();
        if (block.timestamp >= maturity) revert MARKET_EXPIRED();

        BookValueState storage state = bookValues[strategy][market];

        // Calculate current book value (if position exists) and add new purchase
        uint256 newBookValue;
        uint256 newPtAmount;
        if (state.lastUpdateTime > 0) {
            // Existing position: amortize and add
            uint256 currentBookValue = _calculateAmortizedBookValue(state, maturity);
            newBookValue = currentBookValue + sySpent;
            newPtAmount = state.lastUpdatePtAmount + ptAmount;
        } else {
            // First purchase
            newBookValue = sySpent;
            newPtAmount = ptAmount;
        }

        // Sanity check: book value should not exceed face value
        if (newBookValue > newPtAmount) revert BOOK_VALUE_EXCEEDS_FACE_VALUE();

        state.lastUpdateBookValue = newBookValue.toUint128();
        state.lastUpdateTime = block.timestamp.toUint64();
        state.lastUpdatePtAmount = newPtAmount.toUint128();

        emit PurchaseRecorded(strategy, market, sySpent, ptAmount);
        emit BookValueUpdated(strategy, market, newBookValue, block.timestamp);
    }

    /// @notice Record a PT redemption - called by strategy via hooks AFTER redeem
    /// @dev msg.sender is the strategy being updated
    /// @dev Called AFTER redeem hook - ptSold is the PT amount that was sold
    /// @param market The Pendle market address
    /// @param ptSold Amount of PT that was sold/redeemed
    function recordRedemption(
        address market,
        uint256 ptSold
    )
        external
    {
        address strategy = msg.sender;
        if (market == address(0)) revert ZERO_ADDRESS();
        if (ptSold == 0) revert ZERO_AMOUNT();

        BookValueState storage state = bookValues[strategy][market];
        if (state.lastUpdateTime == 0) revert NO_POSITION();

        // Get PT address and maturity from market
        (, IPPrincipalToken pt,) = IPMarket(market).readTokens();
        uint256 maturity = pt.expiry();

        // Get stored PT amount (this was the amount BEFORE redemption)
        uint256 oldPtAmount = state.lastUpdatePtAmount;
        if (ptSold > oldPtAmount) revert INSUFFICIENT_POSITION();

        // Calculate current book value using stored ptAmount
        uint256 currentBookValue = _calculateAmortizedBookValue(state, maturity);

        // Cost basis accounting: proportionally reduce book value
        uint256 costBasis = currentBookValue.mulDiv(ptSold, oldPtAmount);
        uint256 newBookValue = currentBookValue - costBasis;

        // Calculate new PT amount after redemption
        uint256 newPtAmount = oldPtAmount - ptSold;

        state.lastUpdateBookValue = newBookValue.toUint128();
        state.lastUpdateTime = block.timestamp.toUint64();
        state.lastUpdatePtAmount = newPtAmount.toUint128();

        emit RedemptionRecorded(strategy, market, ptSold);
        emit BookValueUpdated(strategy, market, newBookValue, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the current amortized book value for a position
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @return bookValue Current amortized book value
    function getBookValue(address strategy, address market) external view returns (uint256 bookValue) {
        BookValueState memory state = bookValues[strategy][market];
        if (state.lastUpdateTime == 0) revert NO_POSITION();
        return _calculateBookValue(strategy, market);
    }

    /// @notice Check if a position exists
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @return exists True if position has been recorded
    function hasPosition(address strategy, address market) external view returns (bool exists) {
        return bookValues[strategy][market].lastUpdateTime > 0;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Correct book value state in case of errors
    /// @dev Can only be called by manager. Use with caution - only for error recovery.
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @param newBookValue The corrected book value
    /// @param newPtAmount The corrected PT amount (should match current balance or expected state)
    function correctBookValue(
        address strategy,
        address market,
        uint128 newBookValue,
        uint128 newPtAmount
    )
        external
        onlyRole(MANAGER_ROLE)
    {
        if (strategy == address(0) || market == address(0)) revert ZERO_ADDRESS();

        // Get PT address to validate (read to ensure market is valid)
        IPMarket(market).readTokens();

        // Sanity check: corrected book value should not exceed PT amount
        if (newBookValue > newPtAmount) revert BOOK_VALUE_EXCEEDS_FACE_VALUE();

        BookValueState storage state = bookValues[strategy][market];
        uint256 oldBookValue = state.lastUpdateBookValue;

        state.lastUpdateBookValue = newBookValue;
        state.lastUpdateTime = block.timestamp.toUint64();
        state.lastUpdatePtAmount = newPtAmount;

        emit BookValueCorrected(strategy, market, oldBookValue, newBookValue, msg.sender);
        emit BookValueUpdated(strategy, market, newBookValue, block.timestamp);
    }

    /// @notice Delete a position entirely (for cleanup of erroneous entries)
    /// @dev Can only be called by manager. Resets all state for the position.
    /// @param strategy The strategy address
    /// @param market The Pendle market address
    function deletePosition(address strategy, address market) external onlyRole(MANAGER_ROLE) {
        if (strategy == address(0) || market == address(0)) revert ZERO_ADDRESS();

        BookValueState storage state = bookValues[strategy][market];
        if (state.lastUpdateTime == 0) revert NO_POSITION();

        uint256 oldBookValue = state.lastUpdateBookValue;

        delete bookValues[strategy][market];

        emit BookValueCorrected(strategy, market, oldBookValue, 0, msg.sender);
        emit BookValueUpdated(strategy, market, 0, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate current book value for external view (reads current balanceOf and scales)
    /// @dev Used by getBookValue() - handles case where PT balance changed without recording
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @return Current amortized book value scaled to current PT balance
    function _calculateBookValue(address strategy, address market) internal view returns (uint256) {
        BookValueState memory state = bookValues[strategy][market];

        // Get PT address from market
        (, IPPrincipalToken pt,) = IPMarket(market).readTokens();

        // Read current PT amount from chain
        uint256 currentPtAmount = IERC20(address(pt)).balanceOf(strategy);
        uint256 maturity = pt.expiry();

        // Edge case: no PT held
        if (currentPtAmount == 0) return 0;

        // At or after maturity, book value = face value (current amount)
        if (block.timestamp >= maturity) {
            return currentPtAmount;
        }

        // Calculate amortized book value using stored amount
        uint256 storedPtAmount = state.lastUpdatePtAmount;
        uint256 amortizedValue = _calculateAmortizedBookValue(state, maturity);

        // Scale by current PT amount if different (handles unrecorded changes)
        if (currentPtAmount != storedPtAmount && storedPtAmount > 0) {
            return amortizedValue.mulDiv(currentPtAmount, storedPtAmount);
        }

        return amortizedValue;
    }

    /// @notice Core amortization formula using stored values
    /// @dev B(t) = A - (A - B(t0)) * (T - t) / (T - t0)
    /// @dev Used by both _calculateBookValue and strategy functions
    /// @param state The stored book value state
    /// @param maturity The PT maturity timestamp
    /// @return Amortized book value using stored ptAmount
    function _calculateAmortizedBookValue(
        BookValueState memory state,
        uint256 maturity
    )
        internal
        view
        returns (uint256)
    {
        uint256 A = state.lastUpdatePtAmount;
        uint256 B_t0 = state.lastUpdateBookValue;
        uint256 t0 = state.lastUpdateTime;

        // Edge case: no PT stored
        if (A == 0) return 0;

        // At or after maturity, book value = face value
        if (block.timestamp >= maturity) {
            return A;
        }

        // Before any time has passed, book value = B(t0)
        if (block.timestamp <= t0) {
            return B_t0;
        }

        // Linear amortization: B(t) = A - (A - B(t0)) * (T - t) / (T - t0)
        uint256 timeRemaining = maturity - block.timestamp;
        uint256 totalDuration = maturity - t0;

        if (A >= B_t0) {
            uint256 unamortizedDiscount = (A - B_t0).mulDiv(timeRemaining, totalDuration);
            return A - unamortizedDiscount;
        } else {
            // Defensive: shouldn't happen (book value > face value is invalid for zero-coupon bond)
            // Cap at face value to avoid propagating corrupted data
            return A;
        }
    }
}
