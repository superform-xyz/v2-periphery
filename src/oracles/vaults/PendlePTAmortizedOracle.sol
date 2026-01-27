// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPMarket } from "@pendle/interfaces/IPMarket.sol";
import { IPPrincipalToken } from "@pendle/interfaces/IPPrincipalToken.sol";

/// @title PendlePTAmortizedOracle
/// @author Superform Labs
/// @notice Provides amortized cost pricing for Pendle PT positions held by strategies
/// @dev Uses Book Value accounting with linear pull-to-par amortization
/// @dev Stores book value, timestamp, and PT amount at last update; reads maturity from chain
contract PendlePTAmortizedOracle is AccessControl, Pausable {
    using Math for uint256;
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Role for keepers who can record purchases and redemptions
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    /// @notice Role for managers who can manage keepers
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

    /// @notice Emitted when a purchase is recorded
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @param buyOrderId External order ID for tracking/reconciliation
    /// @param sySpent Amount of SY spent on the purchase
    /// @param newBookValue The new book value after the purchase
    /// @param timestamp The timestamp of the purchase
    event PurchaseRecorded(
        address indexed strategy,
        address indexed market,
        bytes32 indexed buyOrderId,
        uint256 sySpent,
        uint256 newBookValue,
        uint256 timestamp
    );

    /// @notice Emitted when a keeper is added
    /// @param keeper The keeper address that was added
    event KeeperAdded(address indexed keeper);

    /// @notice Emitted when a keeper is removed
    /// @param keeper The keeper address that was removed
    event KeeperRemoved(address indexed keeper);

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

    /// @notice Thrown when strategy has no PT balance for the market
    error NO_PT_BALANCE();

    /// @notice Thrown when PT balance doesn't match expected amount after purchase
    error PT_BALANCE_MISMATCH();

    /// @notice Thrown when PT balance exists but no purchase was recorded (data integrity issue)
    error UNRECORDED_PT_BALANCE();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the oracle with an admin
    /// @param admin The admin address who receives DEFAULT_ADMIN_ROLE and MANAGER_ROLE
    constructor(address admin) {
        if (admin == address(0)) revert ZERO_ADDRESS();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _setRoleAdmin(KEEPER_ROLE, MANAGER_ROLE);
    }

    /*//////////////////////////////////////////////////////////////
                            KEEPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Record a PT purchase - updates lastUpdateBookValue and lastUpdateTime
    /// @dev Must be called AFTER the purchase transaction completes (so balanceOf reflects new PT amount)
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @param sySpent Amount of SY spent (book value increment)
    /// @param expectedPtAmount Expected PT balance after purchase (for verification)
    /// @param buyOrderId External order ID for tracking/reconciliation (can be bytes32(0) if not needed)
    function recordPurchase(
        address strategy,
        address market,
        uint256 sySpent,
        uint256 expectedPtAmount,
        bytes32 buyOrderId
    )
        external
        onlyRole(KEEPER_ROLE)
        whenNotPaused
    {
        if (strategy == address(0) || market == address(0)) revert ZERO_ADDRESS();
        if (sySpent == 0) revert ZERO_AMOUNT();

        // Get PT address and maturity from market
        (, IPPrincipalToken pt,) = IPMarket(market).readTokens();
        uint256 maturity = pt.expiry();
        if (block.timestamp >= maturity) revert MARKET_EXPIRED();

        BookValueState storage state = bookValues[strategy][market];

        // Get current PT amount (after purchase)
        uint256 ptAmount = IERC20(address(pt)).balanceOf(strategy);

        // Verify PT balance matches expected amount (prevents timing/ordering errors)
        if (expectedPtAmount > 0 && ptAmount != expectedPtAmount) revert PT_BALANCE_MISMATCH();

        // Validate strategy actually holds PT
        if (ptAmount == 0) revert NO_PT_BALANCE();

        // Calculate current book value (if position exists) and add new purchase
        uint256 newBookValue;
        if (state.lastUpdateTime > 0) {
            // Use stored ptAmount for amortization calculation (not current balanceOf)
            uint256 currentBookValue = _calculateBookValueWithStoredAmount(state, maturity);
            newBookValue = currentBookValue + sySpent;
        } else {
            // First purchase
            newBookValue = sySpent;
        }

        // Sanity check: book value should not exceed face value (ptAmount)
        // This catches keeper errors where sySpent is recorded larger than actual
        if (newBookValue > ptAmount) revert BOOK_VALUE_EXCEEDS_FACE_VALUE();

        state.lastUpdateBookValue = newBookValue.toUint128();
        state.lastUpdateTime = block.timestamp.toUint64();
        state.lastUpdatePtAmount = ptAmount.toUint128();

        emit BookValueUpdated(strategy, market, newBookValue, block.timestamp);
        emit PurchaseRecorded(strategy, market, buyOrderId, sySpent, newBookValue, block.timestamp);
    }

    /// @notice Record a PT redemption - updates using cost basis accounting
    /// @dev Must be called BEFORE the redemption changes balanceOf
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @param ptRedeemed Amount of PT being redeemed
    function recordRedemption(
        address strategy,
        address market,
        uint256 ptRedeemed
    )
        external
        onlyRole(KEEPER_ROLE)
        whenNotPaused
    {
        if (strategy == address(0) || market == address(0)) revert ZERO_ADDRESS();
        if (ptRedeemed == 0) revert ZERO_AMOUNT();

        BookValueState storage state = bookValues[strategy][market];
        if (state.lastUpdateTime == 0) revert NO_POSITION();

        // Get PT address and maturity from market
        (, IPPrincipalToken pt,) = IPMarket(market).readTokens();
        uint256 maturity = pt.expiry();

        // Read current PT amount BEFORE redemption
        uint256 ptAmount = IERC20(address(pt)).balanceOf(strategy);
        if (ptRedeemed > ptAmount) revert INSUFFICIENT_POSITION();

        // Check for unrecorded PT balance (storedPtAmount == 0 but actual balance > 0)
        // This prevents "laundering" unrecorded purchases through redemption
        uint256 storedPtAmount = state.lastUpdatePtAmount;
        if (storedPtAmount == 0 && ptAmount > 0) revert UNRECORDED_PT_BALANCE();

        // Calculate current book value using stored ptAmount
        uint256 currentBookValue = _calculateBookValueWithStoredAmount(state, maturity);

        // Handle discrepancy between stored and current balance
        // Scale book value to current balance for accurate cost basis (matches _calculateBookValue behavior)
        if (ptAmount != storedPtAmount && storedPtAmount > 0) {
            currentBookValue = currentBookValue.mulDiv(ptAmount, storedPtAmount);
        }

        // Cost basis accounting: proportionally reduce book value
        uint256 costBasis = currentBookValue.mulDiv(ptRedeemed, ptAmount);
        uint256 newBookValue = currentBookValue - costBasis;

        // Update state - ptAmount will be reduced after this call
        uint256 newPtAmount = ptAmount - ptRedeemed;
        state.lastUpdateBookValue = newBookValue.toUint128();
        state.lastUpdateTime = block.timestamp.toUint64();
        state.lastUpdatePtAmount = newPtAmount.toUint128();

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

    /// @notice Add a keeper who can record purchases and redemptions
    /// @param keeper The address to grant KEEPER_ROLE
    function addKeeper(address keeper) external onlyRole(MANAGER_ROLE) {
        if (keeper == address(0)) revert ZERO_ADDRESS();
        _grantRole(KEEPER_ROLE, keeper);
        emit KeeperAdded(keeper);
    }

    /// @notice Remove a keeper
    /// @param keeper The address to revoke KEEPER_ROLE from
    function removeKeeper(address keeper) external onlyRole(MANAGER_ROLE) {
        _revokeRole(KEEPER_ROLE, keeper);
        emit KeeperRemoved(keeper);
    }

    /// @notice Pause the oracle - prevents new recordings
    /// @dev Can only be called by admin in emergency situations
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the oracle - resumes normal operations
    /// @dev Can only be called by admin
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Correct book value state in case of keeper errors
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
        // Allow correction even if newPtAmount differs from balance (for pre-correction of expected state)
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
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate current book value using amortization formula with current balanceOf
    /// @dev B(t) = A - (A - B(t0)) * (T - t) / (T - t0)
    /// @dev Used by getBookValue() - reads current ptAmount from balanceOf
    /// @param strategy The strategy address holding the PT
    /// @param market The Pendle market address
    /// @return Current amortized book value
    function _calculateBookValue(address strategy, address market) internal view returns (uint256) {
        BookValueState memory state = bookValues[strategy][market];

        // Get PT address from market
        (, IPPrincipalToken pt,) = IPMarket(market).readTokens();

        // Read current PT amount from chain
        uint256 currentPtAmount = IERC20(address(pt)).balanceOf(strategy);
        uint256 T = pt.expiry();

        // Edge case: no PT held
        if (currentPtAmount == 0) return 0;

        // At or after maturity, book value = face value (current amount)
        if (block.timestamp >= T) {
            return currentPtAmount;
        }

        // Use stored ptAmount for amortization calculation
        uint256 A_t0 = state.lastUpdatePtAmount;
        uint256 B_t0 = state.lastUpdateBookValue;
        uint256 t0 = state.lastUpdateTime;

        // If stored amount is 0 but current amount is non-zero, PT was added without recording
        // This is a data integrity issue - revert to force proper recording via recordPurchase or correctBookValue
        if (A_t0 == 0) {
            revert UNRECORDED_PT_BALANCE();
        }

        // Before any time has passed, book value = B(t0) scaled by current amount
        if (block.timestamp <= t0) {
            // If PT amount changed without recording, scale proportionally
            if (currentPtAmount != A_t0 && A_t0 > 0) {
                return B_t0.mulDiv(currentPtAmount, A_t0);
            }
            return B_t0;
        }

        // Calculate amortized book value at t0's ptAmount
        // B(t) = A(t0) - (A(t0) - B(t0)) * (T - t) / (T - t0)
        uint256 timeRemaining = T - block.timestamp;
        uint256 totalDuration = T - t0;

        uint256 amortizedValueAtOldAmount;
        if (A_t0 >= B_t0) {
            uint256 unamortizedDiscount = (A_t0 - B_t0).mulDiv(timeRemaining, totalDuration);
            amortizedValueAtOldAmount = A_t0 - unamortizedDiscount;
        } else {
            // Defensive: shouldn't happen, but handle gracefully
            amortizedValueAtOldAmount = B_t0;
        }

        // Scale by current PT amount if different (handles partial redemptions not recorded)
        if (currentPtAmount != A_t0 && A_t0 > 0) {
            return amortizedValueAtOldAmount.mulDiv(currentPtAmount, A_t0);
        }

        return amortizedValueAtOldAmount;
    }

    /// @notice Calculate book value using stored ptAmount (for keeper updates)
    /// @dev Used internally by recordPurchase and recordRedemption
    /// @param state The stored book value state
    /// @param maturity The PT maturity timestamp
    /// @return Amortized book value using stored ptAmount
    function _calculateBookValueWithStoredAmount(
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
            // Defensive: shouldn't happen
            return B_t0;
        }
    }
}
