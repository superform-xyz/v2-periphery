// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { PendlePTAmortizedOracle } from "../../../src/oracles/vaults/PendlePTAmortizedOracle.sol";

// Mock contracts for testing
import { MockPendleMarket, MockPrincipalToken } from "./mocks/MockPendleContracts.sol";

/// @notice Test harness to expose internal storage for testing defensive code paths
contract PendlePTAmortizedOracleHarness is PendlePTAmortizedOracle {
    constructor(address admin, address superLedgerConfiguration) PendlePTAmortizedOracle(admin, superLedgerConfiguration) { }

    /// @notice Directly set book value state (for testing invalid states)
    function setBookValueState(
        address strategy,
        address market,
        uint128 bookValue,
        uint64 time
    ) external {
        bookValues[strategy][market].lastUpdateBookValue = bookValue;
        bookValues[strategy][market].lastUpdateTime = time;
    }
}

/// @title PendlePTAmortizedOracleTest
/// @notice Unit tests for PendlePTAmortizedOracle - Amortized cost pricing for Pendle PT positions
/// @dev Strategies call recordPurchase/recordRedemption directly (msg.sender is the strategy)
contract PendlePTAmortizedOracleTest is Test {
    PendlePTAmortizedOracle public oracle;
    MockPendleMarket public market;
    MockPrincipalToken public pt;

    address public admin;
    address public strategy;
    address public superLedgerConfiguration;

    // Roles
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Test constants
    uint256 constant MATURITY = 100 days;
    uint256 constant INITIAL_TIME = 1000;

    // Events
    event BookValueUpdated(address indexed strategy, address indexed market, uint256 newBookValue, uint256 timestamp);
    event BookValueCorrected(
        address indexed strategy,
        address indexed market,
        uint256 oldBookValue,
        uint256 newBookValue,
        address indexed correctedBy
    );
    event PurchaseRecorded(
        address indexed strategy,
        address indexed market,
        uint256 sySpent,
        uint256 ptAmount
    );
    event RedemptionRecorded(
        address indexed strategy,
        address indexed market,
        uint256 ptSold
    );

    function setUp() public {
        admin = address(this);
        strategy = makeAddr("strategy");
        superLedgerConfiguration = makeAddr("superLedgerConfiguration");

        // Set initial timestamp
        vm.warp(INITIAL_TIME);

        // Deploy mock PT with maturity 100 days from now
        pt = new MockPrincipalToken(block.timestamp + MATURITY);

        // Deploy mock market
        market = new MockPendleMarket(address(pt));

        // Deploy oracle
        oracle = new PendlePTAmortizedOracle(admin, superLedgerConfiguration);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test constructor initializes state correctly
    function test_Constructor_InitializesCorrectly() public view {
        assertTrue(oracle.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(oracle.hasRole(MANAGER_ROLE, admin));
    }

    /// @notice Test constructor reverts with zero admin address
    function test_Constructor_RevertsOnZeroAddress() public {
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        new PendlePTAmortizedOracle(address(0), superLedgerConfiguration);
    }

    /// @notice Test constructor reverts with zero superLedgerConfiguration address
    function test_Constructor_RevertsOnZeroSuperLedgerConfiguration() public {
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        new PendlePTAmortizedOracle(admin, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        RECORD PURCHASE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test recording a first purchase
    function test_RecordPurchase_FirstPurchase() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18; // 10% discount

        // Mint PT to strategy
        pt.mint(strategy, ptAmount);

        vm.prank(strategy);
        vm.expectEmit(true, true, false, true);
        emit PurchaseRecorded(strategy, address(market), sySpent, ptAmount);
        vm.expectEmit(true, true, false, true);
        emit BookValueUpdated(strategy, address(market), sySpent, block.timestamp);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Verify state
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, sySpent);
        assertTrue(oracle.hasPosition(strategy, address(market)));
    }

    /// @notice Test recording a subsequent purchase
    function test_RecordPurchase_SubsequentPurchase() public {
        uint256 ptAmount1 = 100e18;
        uint256 sySpent1 = 90e18;

        // First purchase
        pt.mint(strategy, ptAmount1);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent1, ptAmount1);

        // Advance time halfway to maturity
        vm.warp(block.timestamp + MATURITY / 2);

        // Calculate expected book value after amortization
        // B(t) = A - (A - B(t0)) * (T - t) / (T - t0)
        // After 50% of time: B = 100 - (100 - 90) * 0.5 = 100 - 5 = 95
        uint256 expectedBookValueBefore = 95e18;

        // Second purchase
        uint256 ptAmount2 = 50e18;
        uint256 sySpent2 = 46e18; // 8% discount
        pt.mint(strategy, ptAmount2);

        vm.prank(strategy);
        vm.expectEmit(true, true, false, true);
        emit PurchaseRecorded(strategy, address(market), sySpent2, ptAmount2);
        oracle.recordPurchase(address(market), sySpent2, ptAmount2);

        // New book value = current amortized value + sySpent
        uint256 expectedNewBookValue = expectedBookValueBefore + sySpent2;
        uint256 actualBookValue = oracle.getBookValue(strategy, address(market));

        assertEq(actualBookValue, expectedNewBookValue);
    }

    /// @notice Test recordPurchase reverts for zero market address
    function test_RecordPurchase_RevertsZeroMarketAddress() public {
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.recordPurchase(address(0), 90e18, 100e18);
    }

    /// @notice Test recordPurchase reverts for zero sySpent
    function test_RecordPurchase_RevertsZeroSySpent() public {
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_AMOUNT.selector);
        oracle.recordPurchase(address(market), 0, 100e18);
    }

    /// @notice Test recordPurchase reverts for zero ptAmount
    function test_RecordPurchase_RevertsZeroPtAmount() public {
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_AMOUNT.selector);
        oracle.recordPurchase(address(market), 90e18, 0);
    }

    /// @notice Test recordPurchase reverts after market expiry
    function test_RecordPurchase_RevertsMarketExpired() public {
        pt.mint(strategy, 100e18);

        // Warp past maturity
        vm.warp(block.timestamp + MATURITY + 1);

        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.MARKET_EXPIRED.selector);
        oracle.recordPurchase(address(market), 90e18, 100e18);
    }

    /// @notice Test recordPurchase reverts if book value exceeds face value
    function test_RecordPurchase_RevertsBookValueExceedsFaceValue() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        // Try to record a purchase where sySpent > ptAmount
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.BOOK_VALUE_EXCEEDS_FACE_VALUE.selector);
        oracle.recordPurchase(address(market), 101e18, ptAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        RECORD REDEMPTION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test recording a partial redemption
    /// @dev recordRedemption is called AFTER the PT has been burned (per hook design)
    function test_RecordRedemption_PartialRedemption() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Advance time to 20% of duration
        vm.warp(block.timestamp + MATURITY / 5);

        // Book value at 20%: B = 100 - (100 - 90) * 0.8 = 100 - 8 = 92
        // Redeem 60 PT out of 100
        // Cost basis for 60 PT: 92 * 60 / 100 = 55.2
        // New book value: 92 - 55.2 = 36.8

        uint256 ptToRedeem = 60e18;

        // Burn the PT BEFORE recording (simulates hook being called after redeem)
        pt.burn(strategy, ptToRedeem);

        vm.prank(strategy);
        vm.expectEmit(true, true, false, true);
        emit RedemptionRecorded(strategy, address(market), ptToRedeem);
        oracle.recordRedemption(address(market), ptToRedeem);

        uint256 bookValue = oracle.getBookValue(strategy, address(market));

        // Expected: 92 - (92 * 60 / 100) = 92 - 55.2 = 36.8
        // With integer math: 92e18 - (92e18 * 60e18 / 100e18) = 92e18 - 55.2e18 = 36.8e18
        assertApproxEqRel(bookValue, 36.8e18, 0.001e18); // 0.1% tolerance
    }

    /// @notice Test recording a full redemption
    /// @dev recordRedemption is called AFTER the PT has been burned (per hook design)
    function test_RecordRedemption_FullRedemption() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Advance time
        vm.warp(block.timestamp + MATURITY / 2);

        // Burn the PT BEFORE recording (simulates hook being called after redeem)
        pt.burn(strategy, ptAmount);

        // Full redemption
        vm.prank(strategy);
        vm.expectEmit(true, true, false, true);
        emit RedemptionRecorded(strategy, address(market), ptAmount);
        oracle.recordRedemption(address(market), ptAmount);

        // Book value should be 0 after full redemption
        // Note: getBookValue will return 0 since ptAmount is 0, but state was updated
        (uint128 lastBookValue, uint64 lastTime) =
            oracle.bookValues(strategy, address(market));
        assertEq(lastBookValue, 0);
        assertGt(lastTime, 0);
    }

    /// @notice Test recordRedemption reverts for zero market address
    function test_RecordRedemption_RevertsZeroMarketAddress() public {
        pt.mint(strategy, 100e18);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, 100e18);

        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.recordRedemption(address(0), 50e18);
    }

    /// @notice Test recordRedemption reverts for zero amount
    function test_RecordRedemption_RevertsZeroAmount() public {
        pt.mint(strategy, 100e18);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, 100e18);

        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_AMOUNT.selector);
        oracle.recordRedemption(address(market), 0);
    }

    /// @notice Test recordRedemption reverts when no position exists
    function test_RecordRedemption_RevertsNoPosition() public {
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracle.NO_POSITION.selector);
        oracle.recordRedemption(address(market), 50e18);
    }

    /// @notice Test recordRedemption at maturity uses face value for book value calculation
    /// @dev Tests the path: if (block.timestamp >= maturity) { return A; } in _calculateAmortizedBookValue
    /// @dev recordRedemption is called AFTER the PT has been burned (per hook design)
    function test_RecordRedemption_AtMaturityUsesFaceValue() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Record purchase before maturity
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Warp to exactly maturity
        vm.warp(block.timestamp + MATURITY);

        // At maturity, _calculateAmortizedBookValue returns A (face value = 100e18)
        // Redeem 50 PT: cost basis = 100 * 50 / 100 = 50
        // New book value = 100 - 50 = 50
        uint256 redeemAmount = 50e18;

        // Burn the PT BEFORE recording (simulates hook being called after redeem)
        pt.burn(strategy, redeemAmount);

        vm.prank(strategy);
        vm.expectEmit(true, true, false, true);
        emit RedemptionRecorded(strategy, address(market), redeemAmount);
        oracle.recordRedemption(address(market), redeemAmount);

        // After redemption, stored book value should be 50e18 (half of face value)
        (uint128 storedBookValue,) = oracle.bookValues(strategy, address(market));
        assertEq(storedBookValue, 50e18);
    }

    /// @notice Test recordRedemption after maturity uses face value for book value calculation
    /// @dev Tests the path: if (block.timestamp >= maturity) { return A; } in _calculateAmortizedBookValue
    /// @dev recordRedemption is called AFTER the PT has been burned (per hook design)
    function test_RecordRedemption_AfterMaturityUsesFaceValue() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Record purchase before maturity
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Warp past maturity
        vm.warp(block.timestamp + MATURITY + 30 days);

        // After maturity, _calculateAmortizedBookValue returns A (face value = 100e18)
        // Redeem 60 PT: cost basis = 100 * 60 / 100 = 60
        // New book value = 100 - 60 = 40
        uint256 redeemAmount = 60e18;

        // Burn the PT BEFORE recording (simulates hook being called after redeem)
        pt.burn(strategy, redeemAmount);

        vm.prank(strategy);
        vm.expectEmit(true, true, false, true);
        emit RedemptionRecorded(strategy, address(market), redeemAmount);
        oracle.recordRedemption(address(market), redeemAmount);

        // After redemption, stored book value should be 40e18
        (uint128 storedBookValue,) = oracle.bookValues(strategy, address(market));
        assertEq(storedBookValue, 40e18);
    }

    /*//////////////////////////////////////////////////////////////
                        GET BOOK VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test getBookValue at various time points
    function test_GetBookValue_LinearAmortization() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18; // 10% discount

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // At t0: should equal sySpent
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);

        // At 25% of duration: B = 100 - (100 - 90) * 0.75 = 92.5
        vm.warp(block.timestamp + MATURITY / 4);
        assertApproxEqRel(oracle.getBookValue(strategy, address(market)), 92.5e18, 0.001e18);

        // At 50% of duration: B = 100 - (100 - 90) * 0.5 = 95
        vm.warp(block.timestamp + MATURITY / 4);
        assertApproxEqRel(oracle.getBookValue(strategy, address(market)), 95e18, 0.001e18);

        // At 75% of duration: B = 100 - (100 - 90) * 0.25 = 97.5
        vm.warp(block.timestamp + MATURITY / 4);
        assertApproxEqRel(oracle.getBookValue(strategy, address(market)), 97.5e18, 0.001e18);

        // At maturity: B = 100 (face value)
        vm.warp(block.timestamp + MATURITY / 4);
        assertEq(oracle.getBookValue(strategy, address(market)), ptAmount);
    }

    /// @notice Test getBookValue after maturity
    function test_GetBookValue_AfterMaturity() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Warp well past maturity
        vm.warp(block.timestamp + MATURITY * 2);

        // Should return face value, not extrapolate
        assertEq(oracle.getBookValue(strategy, address(market)), ptAmount);
    }

    /// @notice Test getBookValue when PT balance is zero
    function test_GetBookValue_ZeroBalance() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Burn all PT (simulate full redemption without calling recordRedemption)
        pt.burn(strategy, ptAmount);

        // Should return 0 when balance is 0
        assertEq(oracle.getBookValue(strategy, address(market)), 0);
    }

    /// @notice Test getBookValue reverts when no position exists
    function test_GetBookValue_RevertsNoPosition() public {
        vm.expectRevert(PendlePTAmortizedOracle.NO_POSITION.selector);
        oracle.getBookValue(strategy, address(market));
    }

    /// @notice Test getBookValue when balance increased without recording (same block)
    /// @dev With the new implementation, uses current balance in amortization formula
    function test_GetBookValue_BalanceIncreasedSameBlock() public {
        uint256 initialPtAmount = 100e18;
        uint256 sySpent = 90e18;

        // Record purchase
        pt.mint(strategy, initialPtAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, initialPtAmount);

        // Verify initial book value (same block, no time passed)
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);

        // Increase balance without recording (direct transfer in)
        uint256 additionalPt = 50e18;
        pt.mint(strategy, additionalPt);

        // Current balance is 150e18
        // With new formula: B(t) = A - (A - B_t0) * (T - t) / (T - t0)
        // At t = t0: B(t) = B_t0 = 90e18 (no time passed)
        // The formula returns B_t0 when no time has passed
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Test getBookValue when balance decreased without recording (same block)
    /// @dev With the new implementation, uses current balance in amortization formula
    function test_GetBookValue_BalanceDecreasedSameBlock() public {
        uint256 initialPtAmount = 100e18;
        uint256 sySpent = 90e18;

        // Record purchase
        pt.mint(strategy, initialPtAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, initialPtAmount);

        // Verify initial book value (same block, no time passed)
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);

        // Decrease balance without recording (direct transfer out)
        uint256 burnAmount = 40e18;
        pt.burn(strategy, burnAmount);

        // Current balance is 60e18
        // At t = t0: B(t) = B_t0 = 90e18 (no time passed)
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Test getBookValue returns book value when balance unchanged (same block)
    function test_GetBookValue_BalanceUnchangedSameBlock() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Record purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Book value should be exactly sySpent
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Test getBookValue with balance change uses current balance in formula (time has passed)
    function test_GetBookValue_BalanceIncreasedAfterTimePassed() public {
        uint256 initialPtAmount = 100e18;
        uint256 sySpent = 90e18;

        // Record purchase
        pt.mint(strategy, initialPtAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, initialPtAmount);

        // Advance time to 50% of maturity
        vm.warp(block.timestamp + MATURITY / 2);

        // Amortized value at 50%: 100 - (100 - 90) * 0.5 = 95
        uint256 amortizedValue = oracle.getBookValue(strategy, address(market));
        assertEq(amortizedValue, 95e18);

        // Increase balance without recording (direct transfer in)
        pt.mint(strategy, 50e18); // Now 150e18 total

        // With new formula using current balance A=150:
        // B(t) = 150 - (150 - 90) * 0.5 = 150 - 30 = 120
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, 120e18);
    }

    /// @notice Test getBookValue with balance decrease uses current balance in formula (time has passed)
    function test_GetBookValue_BalanceDecreasedAfterTimePassed() public {
        uint256 initialPtAmount = 100e18;
        uint256 sySpent = 90e18;

        // Record purchase
        pt.mint(strategy, initialPtAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, initialPtAmount);

        // Advance time to 50% of maturity
        vm.warp(block.timestamp + MATURITY / 2);

        // Amortized value at 50%: 100 - (100 - 90) * 0.5 = 95
        uint256 amortizedValue = oracle.getBookValue(strategy, address(market));
        assertEq(amortizedValue, 95e18);

        // Decrease balance without recording (direct transfer out)
        pt.burn(strategy, 40e18); // Now 60e18 total

        // With new formula using current balance A=60:
        // B(t) = 60 - (60 - 90) * 0.5 = 60 - (-15) = 60 + 15 = 75
        // But since A < B_t0, defensive branch caps at A = 60
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, 60e18);
    }

    /*//////////////////////////////////////////////////////////////
                    CORRECT BOOK VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test correctBookValue by manager
    function test_CorrectBookValue_ByManager() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Correct the book value
        uint128 newBookValue = 85e18;

        vm.expectEmit(true, true, true, true);
        emit BookValueCorrected(strategy, address(market), sySpent, newBookValue, admin);
        oracle.correctBookValue(strategy, address(market), newBookValue);

        assertEq(oracle.getBookValue(strategy, address(market)), newBookValue);
    }

    /// @notice Test correctBookValue reverts for non-manager
    function test_CorrectBookValue_RevertsNonManager() public {
        pt.mint(strategy, 100e18);

        address nonManager = makeAddr("nonManager");

        vm.prank(nonManager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonManager, MANAGER_ROLE)
        );
        oracle.correctBookValue(strategy, address(market), 85e18);
    }

    /// @notice Test correctBookValue reverts for zero address
    function test_CorrectBookValue_RevertsZeroAddress() public {
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.correctBookValue(address(0), address(market), 85e18);

        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.correctBookValue(strategy, address(0), 85e18);
    }

    /// @notice Test correctBookValue reverts if book value exceeds current PT balance
    function test_CorrectBookValue_RevertsBookValueExceedsFaceValue() public {
        pt.mint(strategy, 100e18);

        vm.expectRevert(PendlePTAmortizedOracle.BOOK_VALUE_EXCEEDS_FACE_VALUE.selector);
        oracle.correctBookValue(strategy, address(market), 101e18);
    }

    /// @notice Test correctBookValue can create new position
    function test_CorrectBookValue_CanCreateNewPosition() public {
        pt.mint(strategy, 100e18);

        // No position exists yet
        assertFalse(oracle.hasPosition(strategy, address(market)));

        // Create position via correction
        oracle.correctBookValue(strategy, address(market), 90e18);

        assertTrue(oracle.hasPosition(strategy, address(market)));
        assertEq(oracle.getBookValue(strategy, address(market)), 90e18);
    }

    /// @notice Test correctBookValue preserves amortization after correction
    function test_CorrectBookValue_AmortizationContinues() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Advance time 25%
        vm.warp(block.timestamp + MATURITY / 4);

        // Correct the book value to a new value (80e18)
        oracle.correctBookValue(strategy, address(market), 80e18);

        // Immediately after correction, book value should be 80e18
        assertEq(oracle.getBookValue(strategy, address(market)), 80e18);

        // Advance time another 25% (now at 50% of remaining time)
        vm.warp(block.timestamp + MATURITY / 4);

        // Book value should have amortized from 80 towards 100
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertGt(bookValue, 80e18, "Book value should have increased");
        assertLt(bookValue, ptAmount, "Book value should be less than face value");
    }

    /// @notice Test correctBookValue with zero book value
    function test_CorrectBookValue_ZeroBookValue() public {
        pt.mint(strategy, 100e18);

        // Create position with zero book value (edge case)
        oracle.correctBookValue(strategy, address(market), 0);

        assertTrue(oracle.hasPosition(strategy, address(market)));
        // Book value should be 0 initially, then amortize to face value
        assertEq(oracle.getBookValue(strategy, address(market)), 0);

        // After maturity, should equal face value
        vm.warp(block.timestamp + MATURITY + 1);
        assertEq(oracle.getBookValue(strategy, address(market)), 100e18);
    }

    /// @notice Test correctBookValue updates timestamp
    function test_CorrectBookValue_UpdatesTimestamp() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, ptAmount);

        (, uint64 initialTime) = oracle.bookValues(strategy, address(market));

        // Advance time
        vm.warp(block.timestamp + 1 days);

        // Correct book value
        oracle.correctBookValue(strategy, address(market), 85e18);

        (, uint64 newTime) = oracle.bookValues(strategy, address(market));

        assertGt(newTime, initialTime, "Timestamp should be updated");
        assertEq(newTime, block.timestamp, "Timestamp should be current");
    }

    /// @notice Test correctBookValue emits both events
    function test_CorrectBookValue_EmitsBothEvents() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, ptAmount);

        // Expect both events
        vm.expectEmit(true, true, true, true);
        emit BookValueCorrected(strategy, address(market), 90e18, 85e18, admin);
        vm.expectEmit(true, true, false, true);
        emit BookValueUpdated(strategy, address(market), 85e18, block.timestamp);

        oracle.correctBookValue(strategy, address(market), 85e18);
    }

    /*//////////////////////////////////////////////////////////////
                    DELETE POSITION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test deletePosition by manager
    function test_DeletePosition_ByManager() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        assertTrue(oracle.hasPosition(strategy, address(market)));

        vm.expectEmit(true, true, true, true);
        emit BookValueCorrected(strategy, address(market), sySpent, 0, admin);
        oracle.deletePosition(strategy, address(market));

        assertFalse(oracle.hasPosition(strategy, address(market)));
    }

    /// @notice Test deletePosition reverts for non-manager
    function test_DeletePosition_RevertsNonManager() public {
        pt.mint(strategy, 100e18);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, 100e18);

        address nonManager = makeAddr("nonManager");

        vm.prank(nonManager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonManager, MANAGER_ROLE)
        );
        oracle.deletePosition(strategy, address(market));
    }

    /// @notice Test deletePosition reverts for zero address
    function test_DeletePosition_RevertsZeroAddress() public {
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.deletePosition(address(0), address(market));

        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.deletePosition(strategy, address(0));
    }

    /// @notice Test deletePosition reverts when no position exists
    function test_DeletePosition_RevertsNoPosition() public {
        vm.expectRevert(PendlePTAmortizedOracle.NO_POSITION.selector);
        oracle.deletePosition(strategy, address(market));
    }

    /// @notice Test position can be recreated after deletion
    function test_DeletePosition_CanRecreatePosition() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Create position
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        assertTrue(oracle.hasPosition(strategy, address(market)));

        // Delete position
        oracle.deletePosition(strategy, address(market));
        assertFalse(oracle.hasPosition(strategy, address(market)));

        // Recreate position
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        assertTrue(oracle.hasPosition(strategy, address(market)));
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Test deletePosition clears all state
    function test_DeletePosition_ClearsAllState() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, ptAmount);

        // Verify state exists
        (uint128 bookValue, uint64 time) = oracle.bookValues(strategy, address(market));
        assertGt(bookValue, 0);
        assertGt(time, 0);

        // Delete position
        oracle.deletePosition(strategy, address(market));

        // Verify all state is cleared
        (bookValue, time) = oracle.bookValues(strategy, address(market));
        assertEq(bookValue, 0);
        assertEq(time, 0);
    }

    /// @notice Test getBookValue reverts after deletion
    function test_DeletePosition_GetBookValueReverts() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, ptAmount);

        // Delete position
        oracle.deletePosition(strategy, address(market));

        // getBookValue should revert
        vm.expectRevert(PendlePTAmortizedOracle.NO_POSITION.selector);
        oracle.getBookValue(strategy, address(market));
    }

    /*//////////////////////////////////////////////////////////////
                        NUMERICAL EXAMPLE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test the numerical example from SV-1095 proposal
    function test_NumericalExample_FromProposal() public {
        // Setup: T = 100 (using 100 seconds for simplicity)
        uint256 maturity = block.timestamp + 100;
        MockPrincipalToken shortPt = new MockPrincipalToken(maturity);
        MockPendleMarket shortMarket = new MockPendleMarket(address(shortPt));

        // Trade 1: t=0, Buy 100 PT at P=0.90, A=100, B(t)=90
        shortPt.mint(strategy, 100e18);
        vm.prank(strategy);
        oracle.recordPurchase(address(shortMarket), 90e18, 100e18);
        assertEq(oracle.getBookValue(strategy, address(shortMarket)), 90e18);

        // Trade 2: t=20, Buy 50 PT at P=0.92, A=150, B(t)=138
        vm.warp(block.timestamp + 20);
        // B(20) from previous position: 100 - (100 - 90) * (100 - 20) / 100 = 100 - 8 = 92
        uint256 bookAt20 = oracle.getBookValue(strategy, address(shortMarket));
        assertEq(bookAt20, 92e18);

        shortPt.mint(strategy, 50e18);
        vm.prank(strategy);
        oracle.recordPurchase(address(shortMarket), 46e18, 50e18); // 50 * 0.92 = 46

        // New book value = 92 + 46 = 138
        assertEq(oracle.getBookValue(strategy, address(shortMarket)), 138e18);

        // Trade 3: t=50, Buy 25 PT at P=0.95, A=175, B(t)=166.25
        vm.warp(block.timestamp + 30); // Now at t=50
        // B(50): 150 - (150 - 138) * (100 - 50) / (100 - 20) = 150 - 12 * 50 / 80 = 150 - 7.5 = 142.5
        uint256 bookAt50 = oracle.getBookValue(strategy, address(shortMarket));
        assertEq(bookAt50, 142.5e18);

        shortPt.mint(strategy, 25e18);
        vm.prank(strategy);
        oracle.recordPurchase(address(shortMarket), 23.75e18, 25e18); // 25 * 0.95 = 23.75

        // New book value = 142.5 + 23.75 = 166.25
        assertEq(oracle.getBookValue(strategy, address(shortMarket)), 166.25e18);

        // Trade 4: t=70, Sell 60 PT at P=0.96
        vm.warp(block.timestamp + 20); // Now at t=70
        // B(70): 175 - (175 - 166.25) * (100 - 70) / (100 - 50) = 175 - 8.75 * 30 / 50 = 175 - 5.25 = 169.75
        uint256 bookAt70 = oracle.getBookValue(strategy, address(shortMarket));
        assertApproxEqRel(bookAt70, 169.75e18, 0.001e18);

        // Cost basis: c(t) = B(t) / A = 169.75 / 175 = 0.97
        // Selling 60 PT: book value reduction = 60 * 0.97 = 58.2
        // New book value = 169.75 - 58.2 = 111.55

        // Burn PT BEFORE recording (simulates hook being called after redeem)
        shortPt.burn(strategy, 60e18);

        vm.prank(strategy);
        oracle.recordRedemption(address(shortMarket), 60e18);

        uint256 finalBookValue = oracle.getBookValue(strategy, address(shortMarket));
        assertApproxEqRel(finalBookValue, 111.55e18, 0.01e18); // 1% tolerance for rounding
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fuzz test for purchase amounts
    function testFuzz_RecordPurchase_ValidAmounts(uint128 ptAmount, uint128 sySpent) public {
        vm.assume(ptAmount > 0 && ptAmount <= type(uint128).max);
        vm.assume(sySpent > 0 && sySpent <= ptAmount); // Can't spend more than face value

        pt.mint(strategy, ptAmount);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Fuzz test for amortization at random time points
    function testFuzz_Amortization_TimePoints(uint256 timePassed) public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        vm.assume(timePassed <= MATURITY);

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        vm.warp(block.timestamp + timePassed);

        uint256 bookValue = oracle.getBookValue(strategy, address(market));

        // Book value should always be between sySpent and ptAmount
        assertGe(bookValue, sySpent);
        assertLe(bookValue, ptAmount);

        // Should be monotonically increasing
        if (timePassed > 0) {
            vm.warp(block.timestamp + 1);
            uint256 laterBookValue = oracle.getBookValue(strategy, address(market));
            assertGe(laterBookValue, bookValue);
        }
    }

    /// @notice Fuzz test for partial redemptions
    /// @dev recordRedemption is called AFTER the PT has been burned (per hook design)
    function testFuzz_RecordRedemption_PartialAmounts(uint128 ptAmount, uint128 ptRedeemed) public {
        // Bound inputs to reasonable ranges to avoid integer math edge cases
        // ptAmount: between 1e18 and 1e30 (reasonable token amounts)
        // ptRedeemed: between 1% and 99% of ptAmount to ensure meaningful remainder
        ptAmount = uint128(bound(ptAmount, 1e18, 1e30));
        ptRedeemed = uint128(bound(ptRedeemed, ptAmount / 100, ptAmount * 99 / 100));

        uint256 sySpent = uint256(ptAmount) * 90 / 100; // 10% discount

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Burn PT BEFORE recording (simulates hook being called after redeem)
        pt.burn(strategy, ptRedeemed);

        vm.prank(strategy);
        oracle.recordRedemption(address(market), ptRedeemed);

        // Verify book value is proportionally reduced
        uint256 remainingPt = ptAmount - ptRedeemed;
        if (remainingPt > 0) {
            uint256 bookValue = oracle.getBookValue(strategy, address(market));
            // Book value should be approximately sySpent * remainingPt / ptAmount
            uint256 expectedBookValue = sySpent * remainingPt / ptAmount;
            assertApproxEqRel(bookValue, expectedBookValue, 0.01e18); // 1% tolerance
        }
    }

    /*//////////////////////////////////////////////////////////////
                    INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test full lifecycle: purchase -> amortize -> correct -> redeem
    /// @dev recordRedemption is called AFTER the PT has been burned (per hook design)
    function test_FullLifecycle_WithCorrection() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // 1. Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);

        // 2. Advance time and verify amortization
        vm.warp(block.timestamp + MATURITY / 4);
        uint256 amortizedValue = oracle.getBookValue(strategy, address(market));
        assertGt(amortizedValue, sySpent);

        // 3. Correct book value (simulate fixing an error)
        uint128 correctedValue = 88e18;
        oracle.correctBookValue(strategy, address(market), correctedValue);
        assertEq(oracle.getBookValue(strategy, address(market)), correctedValue);

        // 4. Redeem half - burn PT BEFORE recording
        uint256 redeemAmount = ptAmount / 2;
        pt.burn(strategy, redeemAmount);

        vm.prank(strategy);
        oracle.recordRedemption(address(market), redeemAmount);

        // Book value should be approximately half
        uint256 finalBookValue = oracle.getBookValue(strategy, address(market));
        assertApproxEqRel(finalBookValue, correctedValue / 2, 0.01e18);
    }

    /// @notice Test multiple strategies with same market
    function test_MultipleStrategies_SameMarket() public {
        address strategy2 = makeAddr("strategy2");
        uint256 ptAmount = 100e18;

        // Strategy 1 purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, ptAmount);

        // Strategy 2 purchase (different price)
        pt.mint(strategy2, ptAmount);
        vm.prank(strategy2);
        oracle.recordPurchase(address(market), 85e18, ptAmount);

        // Verify independent book values
        assertEq(oracle.getBookValue(strategy, address(market)), 90e18);
        assertEq(oracle.getBookValue(strategy2, address(market)), 85e18);

        // Delete strategy 1, strategy 2 unaffected
        oracle.deletePosition(strategy, address(market));
        assertFalse(oracle.hasPosition(strategy, address(market)));
        assertTrue(oracle.hasPosition(strategy2, address(market)));
        assertEq(oracle.getBookValue(strategy2, address(market)), 85e18);
    }

    /// @notice Test same strategy with multiple markets
    function test_SameStrategy_MultipleMarkets() public {
        // Create second market
        MockPrincipalToken pt2 = new MockPrincipalToken(block.timestamp + MATURITY);
        MockPendleMarket market2 = new MockPendleMarket(address(pt2));

        uint256 ptAmount = 100e18;

        // Purchase in market 1
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), 90e18, ptAmount);

        // Purchase in market 2
        pt2.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market2), 85e18, ptAmount);

        // Verify independent book values
        assertEq(oracle.getBookValue(strategy, address(market)), 90e18);
        assertEq(oracle.getBookValue(strategy, address(market2)), 85e18);

        // Correct market 1, market 2 unaffected
        oracle.correctBookValue(strategy, address(market), 80e18);
        assertEq(oracle.getBookValue(strategy, address(market)), 80e18);
        assertEq(oracle.getBookValue(strategy, address(market2)), 85e18);
    }

    /*//////////////////////////////////////////////////////////////
                    EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test recording purchase at boundary of maturity
    function test_RecordPurchase_JustBeforeMaturity() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 99e18; // Very small discount near maturity

        pt.mint(strategy, ptAmount);

        // Warp to just before maturity (1 second before)
        vm.warp(block.timestamp + MATURITY - 1);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), sySpent, ptAmount);

        // Book value should be very close to face value immediately
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, sySpent);

        // After 1 second (at maturity), should equal face value
        vm.warp(block.timestamp + 1);
        assertEq(oracle.getBookValue(strategy, address(market)), ptAmount);
    }

    /// @notice Test correctBookValue validates against current PT balance
    function test_CorrectBookValue_ValidatesAgainstCurrentBalance() public {
        pt.mint(strategy, 100e18);

        // Correct with book value less than current balance
        oracle.correctBookValue(strategy, address(market), 45e18);

        // Position exists with the specified book value
        (uint128 bookValue,) = oracle.bookValues(strategy, address(market));
        assertEq(bookValue, 45e18);

        // Book value uses current balance for amortization
        assertEq(oracle.getBookValue(strategy, address(market)), 45e18);
    }

    /*//////////////////////////////////////////////////////////////
            DEFENSIVE CODE PATH TESTS (INVALID STATE HANDLING)
    //////////////////////////////////////////////////////////////*/

    /// @notice Test getBookValue defensive path when book value exceeds face value (invalid state)
    /// @dev This tests the defensive branch: if (A >= B_t0) ... else { return A; }
    /// @dev This state shouldn't happen through normal operations, but we test the defensive handling
    function test_GetBookValue_DefensivePathWhenBookValueExceedsFaceValue() public {
        uint256 ptAmount = 100e18;

        // Mint PT to strategy
        pt.mint(strategy, ptAmount);

        // Use harness to directly set invalid state where B_t0 > current balance
        PendlePTAmortizedOracleHarness harness = new PendlePTAmortizedOracleHarness(admin, superLedgerConfiguration);

        // Set invalid state: bookValue = 150e18, but PT balance = 100e18 (bookValue > faceValue)
        harness.setBookValueState(strategy, address(market), 150e18, uint64(block.timestamp));

        // Advance time so we're in the amortization phase (t > t0 but t < maturity)
        vm.warp(block.timestamp + MATURITY / 2);

        // Now getBookValue should hit the defensive branch
        // When A (current balance) < B_t0: defensive branch caps at face value A
        // Result should be A = 100e18 (face value, not corrupted B_t0)
        uint256 bookValue = harness.getBookValue(strategy, address(market));
        assertEq(bookValue, ptAmount, "Defensive path should cap at face value");
    }

    /// @notice Test getBookValue defensive path with increased balance
    function test_GetBookValue_DefensivePathWithBalanceIncrease() public {
        uint256 ptAmount = 100e18;

        // Mint PT to strategy
        pt.mint(strategy, ptAmount);

        // Use harness to directly set invalid state where B_t0 > current balance
        PendlePTAmortizedOracleHarness harness = new PendlePTAmortizedOracleHarness(admin, superLedgerConfiguration);

        // Set invalid state: bookValue = 150e18, but PT balance = 100e18
        harness.setBookValueState(strategy, address(market), 150e18, uint64(block.timestamp));

        // Advance time so we're in the amortization phase
        vm.warp(block.timestamp + MATURITY / 2);

        // Change balance to 150e18 (50% increase)
        pt.mint(strategy, 50e18);

        // Now getBookValue uses current balance A = 150e18
        // Since A (150) < B_t0 (150), defensive branch is NOT hit
        // B(t) = 150 - (150 - 150) * remaining / total = 150
        uint256 bookValue = harness.getBookValue(strategy, address(market));
        assertEq(bookValue, 150e18);
    }

    /// @notice Test _calculateAmortizedBookValue defensive path during redemption
    function test_RecordRedemption_DefensivePathCapsFaceValue() public {
        uint256 ptAmount = 100e18;

        // Mint PT to strategy
        pt.mint(strategy, ptAmount);

        // Use harness to directly set invalid state where B_t0 > balance
        PendlePTAmortizedOracleHarness harness = new PendlePTAmortizedOracleHarness(admin, superLedgerConfiguration);

        // Set invalid state: bookValue = 150e18, but PT balance = 100e18 (bookValue > faceValue)
        harness.setBookValueState(strategy, address(market), 150e18, uint64(block.timestamp));

        // Advance time
        vm.warp(block.timestamp + MATURITY / 2);

        // Redeem 50 PT
        // Previous balance = 100 + 50 = 150 (derived from current balance 100 - 50 burned, but burn happens after)
        // Wait, redemption happens before this call, so:
        // - Current balance after redemption = 50e18 (we need to burn first)
        pt.burn(strategy, 50e18); // Balance is now 50e18

        // Now record redemption with ptSold = 50e18
        // Previous balance = 50 + 50 = 100e18
        // _calculateAmortizedBookValue with A=100, B_t0=150
        // Since A < B_t0, defensive branch caps at A = 100e18
        // Cost basis = 100 * 50 / 100 = 50
        // New book value = 100 - 50 = 50
        vm.prank(strategy);
        harness.recordRedemption(address(market), 50e18);

        // Verify the state was updated correctly
        (uint128 storedBookValue,) = harness.bookValues(strategy, address(market));
        assertEq(storedBookValue, 50e18);
    }

    /// @notice Test using harness to directly set invalid state
    function test_Harness_SetInvalidState() public {
        PendlePTAmortizedOracleHarness harness = new PendlePTAmortizedOracleHarness(admin, superLedgerConfiguration);

        pt.mint(strategy, 100e18);

        // Set invalid state where bookValue > ptBalance
        harness.setBookValueState(strategy, address(market), 150e18, uint64(block.timestamp));

        // Advance time
        vm.warp(block.timestamp + MATURITY / 2);

        // Defensive branch should cap at face value (current balance)
        uint256 bookValue = harness.getBookValue(strategy, address(market));
        assertEq(bookValue, 100e18);
    }
}
