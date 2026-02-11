// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { PendlePTAmortizedOracleV2 } from "../../../src/oracles/vaults/PendlePTAmortizedOracleV2.sol";

// Mock contracts for testing
import { MockPendleMarket, MockPrincipalToken, MockTwapOracle } from "./mocks/MockPendleContracts.sol";

/// @notice Test harness to expose internal storage for testing defensive code paths
contract PendlePTAmortizedOracleV2Harness is PendlePTAmortizedOracleV2 {
    constructor(address admin, address superLedgerConfiguration) PendlePTAmortizedOracleV2(admin, superLedgerConfiguration) { }

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

/// @title PendlePTAmortizedOracleV2Test
/// @notice Unit tests for PendlePTAmortizedOracleV2 - Amortized cost pricing with on-chain PT rate calculation
/// @dev V2 key differences:
///      - recordPurchase calculates sySpent from PT rate (no off-chain price dependency)
///      - twapDuration is passed per-call (no market config storage)
contract PendlePTAmortizedOracleV2Test is Test {
    PendlePTAmortizedOracleV2 public oracle;
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
    uint32 constant DEFAULT_TWAP_DURATION = 900;
    uint32 constant TWAP_SPOT = 0;

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
        uint256 ptBought,
        uint256 calculatedSySpent,
        uint32 twapDuration
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

        // Deploy oracle - V2 has no market config, twapDuration passed per-call
        oracle = new PendlePTAmortizedOracleV2(admin, superLedgerConfiguration);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_InitializesCorrectly() public view {
        assertTrue(oracle.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(oracle.hasRole(MANAGER_ROLE, admin));
    }

    function test_Constructor_RevertsOnZeroAddress() public {
        vm.expectRevert(PendlePTAmortizedOracleV2.ZERO_ADDRESS.selector);
        new PendlePTAmortizedOracleV2(address(0), superLedgerConfiguration);
    }

    function test_Constructor_RevertsOnZeroSuperLedgerConfiguration() public {
        vm.expectRevert(PendlePTAmortizedOracleV2.ZERO_ADDRESS.selector);
        new PendlePTAmortizedOracleV2(admin, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        RECORD PURCHASE TESTS (V2)
    //////////////////////////////////////////////////////////////*/

    /// @notice V2: recordPurchase takes market, ptBought, and twapDuration
    function test_RecordPurchase_FirstPurchase() public {
        uint256 ptAmount = 100e18;

        // Mint PT to strategy
        pt.mint(strategy, ptAmount);

        // V2: Oracle calculates sySpent from PT rate
        // Mock market returns ~0.9 rate before maturity
        uint256 expectedSySpent = ptAmount * 9 / 10; // ~90e18

        vm.prank(strategy);
        vm.expectEmit(true, true, false, false); // Don't check exact sySpent due to Pendle math
        emit PurchaseRecorded(strategy, address(market), ptAmount, expectedSySpent, DEFAULT_TWAP_DURATION);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Verify position exists
        assertTrue(oracle.hasPosition(strategy, address(market)));

        // Book value should be approximately ptAmount * ptRate
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertApproxEqRel(bookValue, expectedSySpent, 0.02e18); // 2% tolerance for Pendle math
    }

    /// @notice V2: Test with different TWAP durations
    function test_RecordPurchase_DifferentTwapDurations() public {
        uint256 ptAmount = 100e18;

        pt.mint(strategy, ptAmount);

        // Use 600s (10 min) TWAP - different from default 900s
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, 600);

        assertTrue(oracle.hasPosition(strategy, address(market)));
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        // Book value should be approximately ptAmount * ptRate (~0.9)
        assertApproxEqRel(bookValue, ptAmount * 9 / 10, 0.02e18);
    }

    /// @notice V2: Test subsequent purchase with amortization
    function test_RecordPurchase_SubsequentPurchase() public {
        uint256 ptAmount1 = 100e18;

        // First purchase
        pt.mint(strategy, ptAmount1);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount1, DEFAULT_TWAP_DURATION);

        uint256 initialBookValue = oracle.getBookValue(strategy, address(market));

        // Advance time halfway to maturity
        vm.warp(block.timestamp + MATURITY / 2);

        // Second purchase
        uint256 ptAmount2 = 50e18;
        pt.mint(strategy, ptAmount2);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount2, DEFAULT_TWAP_DURATION);

        // Book value should have increased
        uint256 newBookValue = oracle.getBookValue(strategy, address(market));
        assertGt(newBookValue, initialBookValue);
    }

    function test_RecordPurchase_RevertsZeroMarketAddress() public {
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracleV2.ZERO_ADDRESS.selector);
        oracle.recordPurchase(address(0), 100e18, DEFAULT_TWAP_DURATION);
    }

    function test_RecordPurchase_RevertsZeroPtAmount() public {
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracleV2.ZERO_AMOUNT.selector);
        oracle.recordPurchase(address(market), 0, DEFAULT_TWAP_DURATION);
    }

    function test_RecordPurchase_RevertsMarketExpired() public {
        pt.mint(strategy, 100e18);

        // Warp past maturity
        vm.warp(block.timestamp + MATURITY + 1);

        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracleV2.MARKET_EXPIRED.selector);
        oracle.recordPurchase(address(market), 100e18, DEFAULT_TWAP_DURATION);
    }

    /*//////////////////////////////////////////////////////////////
                        RECORD REDEMPTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RecordRedemption_PartialRedemption() public {
        uint256 ptAmount = 100e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Advance time
        vm.warp(block.timestamp + MATURITY / 5);

        uint256 ptToRedeem = 60e18;

        // Burn the PT BEFORE recording (simulates hook being called after redeem)
        pt.burn(strategy, ptToRedeem);

        vm.prank(strategy);
        vm.expectEmit(true, true, false, true);
        emit RedemptionRecorded(strategy, address(market), ptToRedeem);
        oracle.recordRedemption(address(market), ptToRedeem);

        // Book value should be reduced proportionally
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertGt(bookValue, 0);
    }

    function test_RecordRedemption_FullRedemption() public {
        uint256 ptAmount = 100e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Advance time
        vm.warp(block.timestamp + MATURITY / 2);

        // Burn the PT BEFORE recording
        pt.burn(strategy, ptAmount);

        // Full redemption
        vm.prank(strategy);
        oracle.recordRedemption(address(market), ptAmount);

        // Book value should be 0
        (uint128 lastBookValue,) = oracle.bookValues(strategy, address(market));
        assertEq(lastBookValue, 0);
    }

    function test_RecordRedemption_RevertsNoPosition() public {
        vm.prank(strategy);
        vm.expectRevert(PendlePTAmortizedOracleV2.NO_POSITION.selector);
        oracle.recordRedemption(address(market), 50e18);
    }

    /*//////////////////////////////////////////////////////////////
                        GET BOOK VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetBookValue_LinearAmortization() public {
        uint256 ptAmount = 100e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        uint256 initialBookValue = oracle.getBookValue(strategy, address(market));

        // At 50% of duration, book value should be closer to face value
        vm.warp(block.timestamp + MATURITY / 2);
        uint256 midBookValue = oracle.getBookValue(strategy, address(market));
        assertGt(midBookValue, initialBookValue);

        // At maturity, book value = face value
        vm.warp(block.timestamp + MATURITY / 2);
        assertEq(oracle.getBookValue(strategy, address(market)), ptAmount);
    }

    function test_GetBookValue_AfterMaturity() public {
        uint256 ptAmount = 100e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Warp well past maturity
        vm.warp(block.timestamp + MATURITY * 2);

        // Should return face value
        assertEq(oracle.getBookValue(strategy, address(market)), ptAmount);
    }

    function test_GetBookValue_ZeroBalance() public {
        uint256 ptAmount = 100e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Burn all PT
        pt.burn(strategy, ptAmount);

        // Should return 0 when balance is 0
        assertEq(oracle.getBookValue(strategy, address(market)), 0);
    }

    function test_GetBookValue_RevertsNoPosition() public {
        vm.expectRevert(PendlePTAmortizedOracleV2.NO_POSITION.selector);
        oracle.getBookValue(strategy, address(market));
    }

    /*//////////////////////////////////////////////////////////////
                    CORRECT BOOK VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CorrectBookValue_ByManager() public {
        uint256 ptAmount = 100e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        uint256 oldBookValue = oracle.getBookValue(strategy, address(market));

        // Correct the book value
        uint128 newBookValue = 85e18;

        vm.expectEmit(true, true, true, true);
        emit BookValueCorrected(strategy, address(market), oldBookValue, newBookValue, admin);
        oracle.correctBookValue(strategy, address(market), newBookValue);

        assertEq(oracle.getBookValue(strategy, address(market)), newBookValue);
    }

    function test_CorrectBookValue_RevertsNonManager() public {
        pt.mint(strategy, 100e18);

        address nonManager = makeAddr("nonManager");

        vm.prank(nonManager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonManager, MANAGER_ROLE)
        );
        oracle.correctBookValue(strategy, address(market), 85e18);
    }

    function test_CorrectBookValue_RevertsBookValueExceedsFaceValue() public {
        pt.mint(strategy, 100e18);

        vm.expectRevert(PendlePTAmortizedOracleV2.BOOK_VALUE_EXCEEDS_FACE_VALUE.selector);
        oracle.correctBookValue(strategy, address(market), 101e18);
    }

    /*//////////////////////////////////////////////////////////////
                    DELETE POSITION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DeletePosition_ByManager() public {
        uint256 ptAmount = 100e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        assertTrue(oracle.hasPosition(strategy, address(market)));

        oracle.deletePosition(strategy, address(market));

        assertFalse(oracle.hasPosition(strategy, address(market)));
    }

    function test_DeletePosition_RevertsNoPosition() public {
        vm.expectRevert(PendlePTAmortizedOracleV2.NO_POSITION.selector);
        oracle.deletePosition(strategy, address(market));
    }

    /*//////////////////////////////////////////////////////////////
                    IYIELDSOURCEORACLE IMPLEMENTATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetPricePerShare_UsesDefaultDuration() public {
        // V2: Uses DEFAULT_TWAP_DURATION constant for IYieldSourceOracle compatibility
        uint256 price = oracle.getPricePerShare(address(market));
        assertApproxEqRel(price, 0.9e18, 0.02e18);
    }

    function test_GetTVLByOwnerOfShares_ReturnsAmortizedValue() public {
        uint256 ptAmount = 100e18;

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Advance to 50% of maturity
        vm.warp(block.timestamp + MATURITY / 2);

        uint256 tvl = oracle.getTVLByOwnerOfShares(address(market), strategy);

        // Should be between initial book value and face value
        assertGt(tvl, 85e18);
        assertLt(tvl, ptAmount);
    }

    function test_GetTVLByOwnerOfShares_FallbackToMarketPrice() public {
        // Mint PT but don't record purchase
        pt.mint(strategy, 100e18);

        uint256 tvl = oracle.getTVLByOwnerOfShares(address(market), strategy);

        // Falls back to getAssetOutput
        assertApproxEqRel(tvl, 90e18, 0.02e18);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTIPLE STRATEGIES/MARKETS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MultipleStrategies_SameMarket() public {
        address strategy2 = makeAddr("strategy2");
        uint256 ptAmount = 100e18;

        // Strategy 1 purchase
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Strategy 2 purchase
        pt.mint(strategy2, ptAmount);
        vm.prank(strategy2);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Verify independent positions
        assertTrue(oracle.hasPosition(strategy, address(market)));
        assertTrue(oracle.hasPosition(strategy2, address(market)));

        // Delete strategy 1, strategy 2 unaffected
        oracle.deletePosition(strategy, address(market));
        assertFalse(oracle.hasPosition(strategy, address(market)));
        assertTrue(oracle.hasPosition(strategy2, address(market)));
    }

    function test_SameStrategy_MultipleMarkets() public {
        // Create second market
        MockPrincipalToken pt2 = new MockPrincipalToken(block.timestamp + MATURITY);
        MockPendleMarket market2 = new MockPendleMarket(address(pt2));

        uint256 ptAmount = 100e18;

        // Purchase in market 1
        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        // Purchase in market 2
        pt2.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market2), ptAmount, DEFAULT_TWAP_DURATION);

        // Verify independent positions
        assertTrue(oracle.hasPosition(strategy, address(market)));
        assertTrue(oracle.hasPosition(strategy, address(market2)));
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_RecordPurchase_ValidAmounts(uint128 ptAmount, uint32 twapDuration) public {
        vm.assume(ptAmount > 1e10 && ptAmount <= 1e30);
        // Bound twapDuration to reasonable values that won't cause overflow in observe()
        // Must be less than block.timestamp (which is INITIAL_TIME = 1000)
        twapDuration = uint32(bound(twapDuration, 1, 900)); // 1s to 15 min TWAP

        pt.mint(strategy, ptAmount);

        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, twapDuration);

        assertTrue(oracle.hasPosition(strategy, address(market)));
    }

    function testFuzz_Amortization_TimePoints(uint256 timePassed) public {
        uint256 ptAmount = 100e18;

        vm.assume(timePassed <= MATURITY);

        pt.mint(strategy, ptAmount);
        vm.prank(strategy);
        oracle.recordPurchase(address(market), ptAmount, DEFAULT_TWAP_DURATION);

        uint256 initialBookValue = oracle.getBookValue(strategy, address(market));

        vm.warp(block.timestamp + timePassed);

        uint256 bookValue = oracle.getBookValue(strategy, address(market));

        // Book value should be between initial and face value
        assertGe(bookValue, initialBookValue);
        assertLe(bookValue, ptAmount);
    }
}
