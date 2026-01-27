// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { PendlePTAmortizedOracle } from "../../../src/oracles/vaults/PendlePTAmortizedOracle.sol";

// Mock contracts for testing
import { MockPendleMarket, MockPrincipalToken } from "./mocks/MockPendleContracts.sol";

/// @title PendlePTAmortizedOracleTest
/// @notice Unit tests for PendlePTAmortizedOracle - Amortized cost pricing for Pendle PT positions
contract PendlePTAmortizedOracleTest is Test {
    PendlePTAmortizedOracle public oracle;
    MockPendleMarket public market;
    MockPrincipalToken public pt;

    address public admin;
    address public keeper;
    address public strategy;

    // Roles
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Test constants
    uint256 constant MATURITY = 100 days;
    uint256 constant INITIAL_TIME = 1000;

    // Events
    event BookValueUpdated(address indexed strategy, address indexed market, uint256 newBookValue, uint256 timestamp);
    event PurchaseRecorded(
        address indexed strategy,
        address indexed market,
        bytes32 indexed buyOrderId,
        uint256 sySpent,
        uint256 newBookValue,
        uint256 timestamp
    );
    event KeeperAdded(address indexed keeper);
    event KeeperRemoved(address indexed keeper);
    event BookValueCorrected(
        address indexed strategy,
        address indexed market,
        uint256 oldBookValue,
        uint256 newBookValue,
        address indexed correctedBy
    );

    function setUp() public {
        admin = address(this);
        keeper = makeAddr("keeper");
        strategy = makeAddr("strategy");

        // Set initial timestamp
        vm.warp(INITIAL_TIME);

        // Deploy mock PT with maturity 100 days from now
        pt = new MockPrincipalToken(block.timestamp + MATURITY);

        // Deploy mock market
        market = new MockPendleMarket(address(pt));

        // Deploy oracle
        oracle = new PendlePTAmortizedOracle(admin);

        // Grant keeper role
        oracle.addKeeper(keeper);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test constructor initializes state correctly
    function test_Constructor_InitializesCorrectly() public view {
        assertTrue(oracle.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(oracle.hasRole(MANAGER_ROLE, admin));
        assertTrue(oracle.hasRole(KEEPER_ROLE, keeper));
    }

    /// @notice Test constructor reverts with zero address
    function test_Constructor_RevertsOnZeroAddress() public {
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        new PendlePTAmortizedOracle(address(0));
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

        vm.prank(keeper);
        vm.expectEmit(true, true, false, true);
        emit BookValueUpdated(strategy, address(market), sySpent, block.timestamp);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Verify state
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, sySpent);
        assertTrue(oracle.hasPosition(strategy, address(market)));
    }

    /// @notice Test recording a first purchase with zero expectedPtAmount (skip verification)
    function test_RecordPurchase_FirstPurchase_NoVerification() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, 0, bytes32(0)); // 0 = skip verification

        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, sySpent);
    }

    /// @notice Test recording a subsequent purchase
    function test_RecordPurchase_SubsequentPurchase() public {
        uint256 ptAmount1 = 100e18;
        uint256 sySpent1 = 90e18;

        // First purchase
        pt.mint(strategy, ptAmount1);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent1, ptAmount1, bytes32(0));

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

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent2, ptAmount1 + ptAmount2, bytes32(0));

        // New book value = current amortized value + sySpent
        uint256 expectedNewBookValue = expectedBookValueBefore + sySpent2;
        uint256 actualBookValue = oracle.getBookValue(strategy, address(market));

        assertEq(actualBookValue, expectedNewBookValue);
    }

    /// @notice Test recordPurchase reverts for non-keeper
    function test_RecordPurchase_RevertsNonKeeper() public {
        address nonKeeper = makeAddr("nonKeeper");
        pt.mint(strategy, 100e18);

        vm.prank(nonKeeper);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonKeeper, KEEPER_ROLE)
        );
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));
    }

    /// @notice Test recordPurchase reverts for zero address
    function test_RecordPurchase_RevertsZeroAddress() public {
        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.recordPurchase(address(0), address(market), 90e18, 100e18, bytes32(0));

        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.recordPurchase(strategy, address(0), 90e18, 100e18, bytes32(0));
    }

    /// @notice Test recordPurchase reverts for zero amount
    function test_RecordPurchase_RevertsZeroAmount() public {
        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_AMOUNT.selector);
        oracle.recordPurchase(strategy, address(market), 0, 100e18, bytes32(0));
    }

    /// @notice Test recordPurchase reverts after market expiry
    function test_RecordPurchase_RevertsMarketExpired() public {
        pt.mint(strategy, 100e18);

        // Warp past maturity
        vm.warp(block.timestamp + MATURITY + 1);

        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.MARKET_EXPIRED.selector);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));
    }

    /// @notice Test recordPurchase reverts if book value exceeds face value
    function test_RecordPurchase_RevertsBookValueExceedsFaceValue() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        // Try to record a purchase where sySpent > ptAmount (keeper error)
        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.BOOK_VALUE_EXCEEDS_FACE_VALUE.selector);
        oracle.recordPurchase(strategy, address(market), 101e18, ptAmount, bytes32(0));
    }

    /// @notice Test recordPurchase reverts if strategy has no PT balance
    function test_RecordPurchase_RevertsNoPTBalance() public {
        // Don't mint any PT to strategy

        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.NO_PT_BALANCE.selector);
        oracle.recordPurchase(strategy, address(market), 90e18, 0, bytes32(0));
    }

    /// @notice Test recordPurchase reverts if PT balance doesn't match expected
    function test_RecordPurchase_RevertsPTBalanceMismatch() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        // Pass wrong expected amount
        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.PT_BALANCE_MISMATCH.selector);
        oracle.recordPurchase(strategy, address(market), 90e18, 50e18, bytes32(0)); // Expected 50, actual 100
    }

    /// @notice Test recordPurchase reverts when paused
    function test_RecordPurchase_RevertsWhenPaused() public {
        pt.mint(strategy, 100e18);

        // Pause the oracle
        oracle.pause();

        vm.prank(keeper);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));
    }

    /*//////////////////////////////////////////////////////////////
                        RECORD REDEMPTION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test recording a partial redemption
    function test_RecordRedemption_PartialRedemption() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Advance time to 20% of duration
        vm.warp(block.timestamp + MATURITY / 5);

        // Book value at 20%: B = 100 - (100 - 90) * 0.8 = 100 - 8 = 92
        // Redeem 60 PT out of 100
        // Cost basis for 60 PT: 92 * 60 / 100 = 55.2
        // New book value: 92 - 55.2 = 36.8

        uint256 ptToRedeem = 60e18;
        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(market), ptToRedeem);

        // Burn the PT after recording
        pt.burn(strategy, ptToRedeem);

        uint256 bookValue = oracle.getBookValue(strategy, address(market));

        // Expected: 92 - (92 * 60 / 100) = 92 - 55.2 = 36.8
        // With integer math: 92e18 - (92e18 * 60e18 / 100e18) = 92e18 - 55.2e18 = 36.8e18
        assertApproxEqRel(bookValue, 36.8e18, 0.001e18); // 0.1% tolerance
    }

    /// @notice Test recording a full redemption
    function test_RecordRedemption_FullRedemption() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Advance time
        vm.warp(block.timestamp + MATURITY / 2);

        // Full redemption
        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(market), ptAmount);

        // Burn the PT
        pt.burn(strategy, ptAmount);

        // Book value should be 0 after full redemption
        // Note: getBookValue will return 0 since ptAmount is 0, but state was updated
        (uint128 lastBookValue, uint64 lastTime, uint128 lastPtAmount) =
            oracle.bookValues(strategy, address(market));
        assertEq(lastBookValue, 0);
        assertGt(lastTime, 0);
        assertEq(lastPtAmount, 0);
    }

    /// @notice Test recordRedemption reverts for non-keeper
    function test_RecordRedemption_RevertsNonKeeper() public {
        pt.mint(strategy, 100e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));

        address nonKeeper = makeAddr("nonKeeper");
        vm.prank(nonKeeper);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonKeeper, KEEPER_ROLE)
        );
        oracle.recordRedemption(strategy, address(market), 50e18);
    }

    /// @notice Test recordRedemption reverts for zero address
    function test_RecordRedemption_RevertsZeroAddress() public {
        pt.mint(strategy, 100e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));

        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.recordRedemption(address(0), address(market), 50e18);

        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.recordRedemption(strategy, address(0), 50e18);
    }

    /// @notice Test recordRedemption reverts for zero amount
    function test_RecordRedemption_RevertsZeroAmount() public {
        pt.mint(strategy, 100e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));

        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_AMOUNT.selector);
        oracle.recordRedemption(strategy, address(market), 0);
    }

    /// @notice Test recordRedemption reverts when no position exists
    function test_RecordRedemption_RevertsNoPosition() public {
        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.NO_POSITION.selector);
        oracle.recordRedemption(strategy, address(market), 50e18);
    }

    /// @notice Test recordRedemption reverts when amount exceeds holdings
    function test_RecordRedemption_RevertsInsufficientPosition() public {
        pt.mint(strategy, 100e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));

        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.INSUFFICIENT_POSITION.selector);
        oracle.recordRedemption(strategy, address(market), 101e18);
    }

    /// @notice Test recordRedemption reverts when paused
    function test_RecordRedemption_RevertsWhenPaused() public {
        pt.mint(strategy, 100e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));

        // Pause the oracle
        oracle.pause();

        vm.prank(keeper);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        oracle.recordRedemption(strategy, address(market), 50e18);
    }

    /*//////////////////////////////////////////////////////////////
                        GET BOOK VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test getBookValue at various time points
    function test_GetBookValue_LinearAmortization() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18; // 10% discount

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

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
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

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
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

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

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test addKeeper by manager
    function test_AddKeeper_ByManager() public {
        address newKeeper = makeAddr("newKeeper");

        assertFalse(oracle.hasRole(KEEPER_ROLE, newKeeper));

        vm.expectEmit(true, false, false, false);
        emit KeeperAdded(newKeeper);
        oracle.addKeeper(newKeeper);

        assertTrue(oracle.hasRole(KEEPER_ROLE, newKeeper));
    }

    /// @notice Test addKeeper reverts for zero address
    function test_AddKeeper_RevertsZeroAddress() public {
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.addKeeper(address(0));
    }

    /// @notice Test addKeeper reverts for non-manager
    function test_AddKeeper_RevertsNonManager() public {
        address nonManager = makeAddr("nonManager");

        vm.prank(nonManager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonManager, MANAGER_ROLE)
        );
        oracle.addKeeper(makeAddr("newKeeper"));
    }

    /// @notice Test removeKeeper by manager
    function test_RemoveKeeper_ByManager() public {
        assertTrue(oracle.hasRole(KEEPER_ROLE, keeper));

        vm.expectEmit(true, false, false, false);
        emit KeeperRemoved(keeper);
        oracle.removeKeeper(keeper);

        assertFalse(oracle.hasRole(KEEPER_ROLE, keeper));
    }

    /// @notice Test removeKeeper reverts for non-manager
    function test_RemoveKeeper_RevertsNonManager() public {
        address nonManager = makeAddr("nonManager");

        vm.prank(nonManager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonManager, MANAGER_ROLE)
        );
        oracle.removeKeeper(keeper);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test pause by admin
    function test_Pause_ByAdmin() public {
        assertFalse(oracle.paused());

        oracle.pause();

        assertTrue(oracle.paused());
    }

    /// @notice Test pause reverts for non-admin
    function test_Pause_RevertsNonAdmin() public {
        address nonAdmin = makeAddr("nonAdmin");

        vm.prank(nonAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, DEFAULT_ADMIN_ROLE
            )
        );
        oracle.pause();
    }

    /// @notice Test unpause by admin
    function test_Unpause_ByAdmin() public {
        oracle.pause();
        assertTrue(oracle.paused());

        oracle.unpause();

        assertFalse(oracle.paused());
    }

    /// @notice Test unpause reverts for non-admin
    function test_Unpause_RevertsNonAdmin() public {
        oracle.pause();

        address nonAdmin = makeAddr("nonAdmin");

        vm.prank(nonAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, nonAdmin, DEFAULT_ADMIN_ROLE
            )
        );
        oracle.unpause();
    }

    /*//////////////////////////////////////////////////////////////
                    CORRECT BOOK VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test correctBookValue by manager
    function test_CorrectBookValue_ByManager() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Correct the book value
        uint128 newBookValue = 85e18;
        uint128 newPtAmount = uint128(ptAmount);

        vm.expectEmit(true, true, true, true);
        emit BookValueCorrected(strategy, address(market), sySpent, newBookValue, admin);
        oracle.correctBookValue(strategy, address(market), newBookValue, newPtAmount);

        assertEq(oracle.getBookValue(strategy, address(market)), newBookValue);
    }

    /// @notice Test correctBookValue reverts for non-manager
    function test_CorrectBookValue_RevertsNonManager() public {
        address nonManager = makeAddr("nonManager");

        vm.prank(nonManager);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, nonManager, MANAGER_ROLE)
        );
        oracle.correctBookValue(strategy, address(market), 85e18, 100e18);
    }

    /// @notice Test correctBookValue reverts for zero address
    function test_CorrectBookValue_RevertsZeroAddress() public {
        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.correctBookValue(address(0), address(market), 85e18, 100e18);

        vm.expectRevert(PendlePTAmortizedOracle.ZERO_ADDRESS.selector);
        oracle.correctBookValue(strategy, address(0), 85e18, 100e18);
    }

    /// @notice Test correctBookValue reverts if book value exceeds PT amount
    function test_CorrectBookValue_RevertsBookValueExceedsFaceValue() public {
        vm.expectRevert(PendlePTAmortizedOracle.BOOK_VALUE_EXCEEDS_FACE_VALUE.selector);
        oracle.correctBookValue(strategy, address(market), 101e18, 100e18);
    }

    /// @notice Test correctBookValue can create new position
    function test_CorrectBookValue_CanCreateNewPosition() public {
        pt.mint(strategy, 100e18);

        // No position exists yet
        assertFalse(oracle.hasPosition(strategy, address(market)));

        // Create position via correction
        oracle.correctBookValue(strategy, address(market), 90e18, 100e18);

        assertTrue(oracle.hasPosition(strategy, address(market)));
        assertEq(oracle.getBookValue(strategy, address(market)), 90e18);
    }

    /*//////////////////////////////////////////////////////////////
                    DELETE POSITION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test deletePosition by manager
    function test_DeletePosition_ByManager() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        assertTrue(oracle.hasPosition(strategy, address(market)));

        vm.expectEmit(true, true, true, true);
        emit BookValueCorrected(strategy, address(market), sySpent, 0, admin);
        oracle.deletePosition(strategy, address(market));

        assertFalse(oracle.hasPosition(strategy, address(market)));
    }

    /// @notice Test deletePosition reverts for non-manager
    function test_DeletePosition_RevertsNonManager() public {
        pt.mint(strategy, 100e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));

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
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(shortMarket), 90e18, 100e18, bytes32(0));
        assertEq(oracle.getBookValue(strategy, address(shortMarket)), 90e18);

        // Trade 2: t=20, Buy 50 PT at P=0.92, A=150, B(t)=138
        vm.warp(block.timestamp + 20);
        // B(20) from previous position: 100 - (100 - 90) * (100 - 20) / 100 = 100 - 8 = 92
        uint256 bookAt20 = oracle.getBookValue(strategy, address(shortMarket));
        assertEq(bookAt20, 92e18);

        shortPt.mint(strategy, 50e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(shortMarket), 46e18, 150e18, bytes32(0)); // 50 * 0.92 = 46

        // New book value = 92 + 46 = 138
        assertEq(oracle.getBookValue(strategy, address(shortMarket)), 138e18);

        // Trade 3: t=50, Buy 25 PT at P=0.95, A=175, B(t)=166.25
        vm.warp(block.timestamp + 30); // Now at t=50
        // B(50): 150 - (150 - 138) * (100 - 50) / (100 - 20) = 150 - 12 * 50 / 80 = 150 - 7.5 = 142.5
        uint256 bookAt50 = oracle.getBookValue(strategy, address(shortMarket));
        assertEq(bookAt50, 142.5e18);

        shortPt.mint(strategy, 25e18);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(shortMarket), 23.75e18, 175e18, bytes32(0)); // 25 * 0.95 = 23.75

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
        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(shortMarket), 60e18);
        shortPt.burn(strategy, 60e18);

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

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Fuzz test for amortization at random time points
    function testFuzz_Amortization_TimePoints(uint256 timePassed) public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        vm.assume(timePassed <= MATURITY);

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

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
    function testFuzz_RecordRedemption_PartialAmounts(uint128 ptAmount, uint128 ptRedeemed) public {
        // Bound inputs to reasonable ranges to avoid integer math edge cases
        // ptAmount: between 1e18 and 1e30 (reasonable token amounts)
        // ptRedeemed: between 1% and 99% of ptAmount to ensure meaningful remainder
        ptAmount = uint128(bound(ptAmount, 1e18, 1e30));
        ptRedeemed = uint128(bound(ptRedeemed, ptAmount / 100, ptAmount * 99 / 100));

        uint256 sySpent = uint256(ptAmount) * 90 / 100; // 10% discount

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(market), ptRedeemed);

        pt.burn(strategy, ptRedeemed);

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
                    ADDITIONAL PAUSE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test operations resume after unpause
    function test_Unpause_OperationsResume() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);

        // Pause
        oracle.pause();
        assertTrue(oracle.paused());

        // Verify operations fail when paused
        vm.prank(keeper);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Unpause
        oracle.unpause();
        assertFalse(oracle.paused());

        // Verify operations work after unpause
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Test pause when already paused reverts
    function test_Pause_WhenAlreadyPaused_Reverts() public {
        oracle.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);
        oracle.pause();
    }

    /// @notice Test unpause when not paused reverts
    function test_Unpause_WhenNotPaused_Reverts() public {
        vm.expectRevert(Pausable.ExpectedPause.selector);
        oracle.unpause();
    }

    /// @notice Test correctBookValue works while paused (admin recovery)
    function test_CorrectBookValue_WorksWhilePaused() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Pause the oracle
        oracle.pause();

        // correctBookValue should still work (admin function)
        oracle.correctBookValue(strategy, address(market), 85e18, uint128(ptAmount));

        assertEq(oracle.getBookValue(strategy, address(market)), 85e18);
    }

    /// @notice Test deletePosition works while paused (admin recovery)
    function test_DeletePosition_WorksWhilePaused() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Pause the oracle
        oracle.pause();

        // deletePosition should still work (admin function)
        oracle.deletePosition(strategy, address(market));

        assertFalse(oracle.hasPosition(strategy, address(market)));
    }

    /*//////////////////////////////////////////////////////////////
                ADDITIONAL CORRECT BOOK VALUE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test correctBookValue preserves amortization after correction
    function test_CorrectBookValue_AmortizationContinues() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Advance time 25%
        vm.warp(block.timestamp + MATURITY / 4);

        // Correct the book value to a new value (80e18)
        oracle.correctBookValue(strategy, address(market), 80e18, uint128(ptAmount));

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
        oracle.correctBookValue(strategy, address(market), 0, 100e18);

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

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount, bytes32(0));

        (, uint64 initialTime,) = oracle.bookValues(strategy, address(market));

        // Advance time
        vm.warp(block.timestamp + 1 days);

        // Correct book value
        oracle.correctBookValue(strategy, address(market), 85e18, uint128(ptAmount));

        (, uint64 newTime,) = oracle.bookValues(strategy, address(market));

        assertGt(newTime, initialTime, "Timestamp should be updated");
        assertEq(newTime, block.timestamp, "Timestamp should be current");
    }

    /// @notice Test correctBookValue emits both events
    function test_CorrectBookValue_EmitsBothEvents() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount, bytes32(0));

        // Expect both events
        vm.expectEmit(true, true, true, true);
        emit BookValueCorrected(strategy, address(market), 90e18, 85e18, admin);
        vm.expectEmit(true, true, false, true);
        emit BookValueUpdated(strategy, address(market), 85e18, block.timestamp);

        oracle.correctBookValue(strategy, address(market), 85e18, uint128(ptAmount));
    }

    /*//////////////////////////////////////////////////////////////
                ADDITIONAL DELETE POSITION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test position can be recreated after deletion
    function test_DeletePosition_CanRecreatePosition() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Create position
        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        assertTrue(oracle.hasPosition(strategy, address(market)));

        // Delete position
        oracle.deletePosition(strategy, address(market));
        assertFalse(oracle.hasPosition(strategy, address(market)));

        // Recreate position
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        assertTrue(oracle.hasPosition(strategy, address(market)));
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Test deletePosition clears all state
    function test_DeletePosition_ClearsAllState() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount, bytes32(0));

        // Verify state exists
        (uint128 bookValue, uint64 time, uint128 storedPtAmount) = oracle.bookValues(strategy, address(market));
        assertGt(bookValue, 0);
        assertGt(time, 0);
        assertGt(storedPtAmount, 0);

        // Delete position
        oracle.deletePosition(strategy, address(market));

        // Verify all state is cleared
        (bookValue, time, storedPtAmount) = oracle.bookValues(strategy, address(market));
        assertEq(bookValue, 0);
        assertEq(time, 0);
        assertEq(storedPtAmount, 0);
    }

    /// @notice Test getBookValue reverts after deletion
    function test_DeletePosition_GetBookValueReverts() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount, bytes32(0));

        // Delete position
        oracle.deletePosition(strategy, address(market));

        // getBookValue should revert
        vm.expectRevert(PendlePTAmortizedOracle.NO_POSITION.selector);
        oracle.getBookValue(strategy, address(market));
    }

    /*//////////////////////////////////////////////////////////////
            ADDITIONAL PT BALANCE VERIFICATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test recordPurchase with exact balance match
    function test_RecordPurchase_ExactBalanceMatch() public {
        uint256 ptAmount = 100e18;
        pt.mint(strategy, ptAmount);

        // Should succeed with exact match
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount, bytes32(0));

        assertEq(oracle.getBookValue(strategy, address(market)), 90e18);
    }

    /// @notice Test recordPurchase fails with balance higher than expected
    function test_RecordPurchase_BalanceHigherThanExpected() public {
        pt.mint(strategy, 100e18);

        // Expect 50, but actual is 100
        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.PT_BALANCE_MISMATCH.selector);
        oracle.recordPurchase(strategy, address(market), 45e18, 50e18, bytes32(0));
    }

    /// @notice Test recordPurchase fails with balance lower than expected
    function test_RecordPurchase_BalanceLowerThanExpected() public {
        pt.mint(strategy, 50e18);

        // Expect 100, but actual is 50
        vm.prank(keeper);
        vm.expectRevert(PendlePTAmortizedOracle.PT_BALANCE_MISMATCH.selector);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));
    }

    /// @notice Test subsequent purchase with verification
    function test_RecordPurchase_SubsequentWithVerification() public {
        uint256 ptAmount1 = 100e18;
        uint256 ptAmount2 = 50e18;

        // First purchase
        pt.mint(strategy, ptAmount1);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount1, bytes32(0));

        // Second purchase - must specify total expected balance
        pt.mint(strategy, ptAmount2);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 45e18, ptAmount1 + ptAmount2, bytes32(0));

        assertEq(oracle.getBookValue(strategy, address(market)), 90e18 + 45e18);
    }

    /*//////////////////////////////////////////////////////////////
                    KEEPER EVENT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test KeeperAdded event is emitted
    function test_AddKeeper_EmitsEvent() public {
        address newKeeper = makeAddr("newKeeper");

        vm.expectEmit(true, false, false, false);
        emit KeeperAdded(newKeeper);

        oracle.addKeeper(newKeeper);
    }

    /// @notice Test KeeperRemoved event is emitted
    function test_RemoveKeeper_EmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit KeeperRemoved(keeper);

        oracle.removeKeeper(keeper);
    }

    /*//////////////////////////////////////////////////////////////
                    INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test full lifecycle: purchase -> amortize -> correct -> redeem
    function test_FullLifecycle_WithCorrection() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // 1. Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);

        // 2. Advance time and verify amortization
        vm.warp(block.timestamp + MATURITY / 4);
        uint256 amortizedValue = oracle.getBookValue(strategy, address(market));
        assertGt(amortizedValue, sySpent);

        // 3. Correct book value (simulate fixing an error)
        uint128 correctedValue = 88e18;
        oracle.correctBookValue(strategy, address(market), correctedValue, uint128(ptAmount));
        assertEq(oracle.getBookValue(strategy, address(market)), correctedValue);

        // 4. Redeem half
        uint256 redeemAmount = ptAmount / 2;
        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(market), redeemAmount);
        pt.burn(strategy, redeemAmount);

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
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount, bytes32(0));

        // Strategy 2 purchase (different price)
        pt.mint(strategy2, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy2, address(market), 85e18, ptAmount, bytes32(0));

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
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), 90e18, ptAmount, bytes32(0));

        // Purchase in market 2
        pt2.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market2), 85e18, ptAmount, bytes32(0));

        // Verify independent book values
        assertEq(oracle.getBookValue(strategy, address(market)), 90e18);
        assertEq(oracle.getBookValue(strategy, address(market2)), 85e18);

        // Correct market 1, market 2 unaffected
        oracle.correctBookValue(strategy, address(market), 80e18, uint128(ptAmount));
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

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Book value should be very close to face value immediately
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, sySpent);

        // After 1 second (at maturity), should equal face value
        vm.warp(block.timestamp + 1);
        assertEq(oracle.getBookValue(strategy, address(market)), ptAmount);
    }

    /// @notice Test correctBookValue with ptAmount different from actual balance
    function test_CorrectBookValue_PtAmountDiffersFromBalance() public {
        pt.mint(strategy, 100e18);

        // Correct with different ptAmount (for pre-correction of expected state)
        // This allows admin to set state before actual balance change
        oracle.correctBookValue(strategy, address(market), 45e18, 50e18);

        // Position exists with the specified values
        (uint128 bookValue,, uint128 storedPtAmount) = oracle.bookValues(strategy, address(market));
        assertEq(bookValue, 45e18);
        assertEq(storedPtAmount, 50e18);
    }

    /// @notice Test that keeper cannot bypass pause with direct role check
    function test_Pause_KeeperCannotBypass() public {
        pt.mint(strategy, 100e18);

        oracle.pause();

        // Even though keeper has KEEPER_ROLE, they cannot record when paused
        assertTrue(oracle.hasRole(KEEPER_ROLE, keeper));

        vm.prank(keeper);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, bytes32(0));

        vm.prank(keeper);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        oracle.recordRedemption(strategy, address(market), 50e18);
    }

    /*//////////////////////////////////////////////////////////////
                        BUY ORDER ID TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test PurchaseRecorded event is emitted with buyOrderId
    function test_RecordPurchase_EmitsPurchaseRecordedEvent() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;
        bytes32 buyOrderId = keccak256("order-123");

        pt.mint(strategy, ptAmount);

        vm.prank(keeper);
        vm.expectEmit(true, true, true, true);
        emit PurchaseRecorded(strategy, address(market), buyOrderId, sySpent, sySpent, block.timestamp);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, buyOrderId);
    }

    /// @notice Test PurchaseRecorded event with zero buyOrderId
    function test_RecordPurchase_ZeroBuyOrderId() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);

        vm.prank(keeper);
        vm.expectEmit(true, true, true, true);
        emit PurchaseRecorded(strategy, address(market), bytes32(0), sySpent, sySpent, block.timestamp);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));
    }

    /// @notice Test multiple purchases with different buyOrderIds
    function test_RecordPurchase_MultipleBuyOrderIds() public {
        bytes32 orderId1 = keccak256("order-1");
        bytes32 orderId2 = keccak256("order-2");

        // First purchase
        pt.mint(strategy, 100e18);
        vm.prank(keeper);
        vm.expectEmit(true, true, true, true);
        emit PurchaseRecorded(strategy, address(market), orderId1, 90e18, 90e18, block.timestamp);
        oracle.recordPurchase(strategy, address(market), 90e18, 100e18, orderId1);

        // Advance time
        vm.warp(block.timestamp + MATURITY / 2);

        // Second purchase with different order ID
        pt.mint(strategy, 50e18);
        uint256 expectedBookValue = 95e18 + 45e18; // Amortized from 90 to ~95 + new 45

        vm.prank(keeper);
        vm.expectEmit(true, true, true, true);
        emit PurchaseRecorded(strategy, address(market), orderId2, 45e18, expectedBookValue, block.timestamp);
        oracle.recordPurchase(strategy, address(market), 45e18, 150e18, orderId2);
    }

    /// @notice Fuzz test for buyOrderId
    function testFuzz_RecordPurchase_BuyOrderId(bytes32 buyOrderId) public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        pt.mint(strategy, ptAmount);

        vm.prank(keeper);
        vm.expectEmit(true, true, true, true);
        emit PurchaseRecorded(strategy, address(market), buyOrderId, sySpent, sySpent, block.timestamp);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, buyOrderId);

        // Verify state is correct regardless of buyOrderId
        assertEq(oracle.getBookValue(strategy, address(market)), sySpent);
    }

    /// @notice Test both events are emitted on purchase
    function test_RecordPurchase_EmitsBothEvents() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;
        bytes32 buyOrderId = keccak256("test-order");

        pt.mint(strategy, ptAmount);

        // Expect both events
        vm.expectEmit(true, true, false, true);
        emit BookValueUpdated(strategy, address(market), sySpent, block.timestamp);
        vm.expectEmit(true, true, true, true);
        emit PurchaseRecorded(strategy, address(market), buyOrderId, sySpent, sySpent, block.timestamp);

        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, buyOrderId);
    }

    /*//////////////////////////////////////////////////////////////
                ZERO STORED AMOUNT EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test getBookValue when stored amount is 0 but current balance is non-zero
    /// @dev After full redemption (storedPtAmount = 0), if PT is added without recording,
    ///      book value should return face value consistently (before and after maturity)
    function test_GetBookValue_ZeroStoredAmountNonZeroBalance() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Full redemption - storedPtAmount becomes 0
        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(market), ptAmount);
        pt.burn(strategy, ptAmount);

        // Verify storedPtAmount is 0
        (,, uint128 storedPtAmount) = oracle.bookValues(strategy, address(market));
        assertEq(storedPtAmount, 0, "Stored PT amount should be 0 after full redemption");

        // Add PT without recording (simulates transfer in without recordPurchase)
        uint256 newPtAmount = 50e18;
        pt.mint(strategy, newPtAmount);

        // Book value should return face value (conservative estimate)
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, newPtAmount, "Book value should equal face value when stored amount is 0");
    }

    /// @notice Test consistency of book value at maturity when stored amount is 0
    function test_GetBookValue_ZeroStoredAmountAtMaturity() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Full redemption
        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(market), ptAmount);
        pt.burn(strategy, ptAmount);

        // Add PT without recording
        uint256 newPtAmount = 75e18;
        pt.mint(strategy, newPtAmount);

        // Check book value before maturity
        uint256 bookValueBeforeMaturity = oracle.getBookValue(strategy, address(market));

        // Warp to maturity
        vm.warp(block.timestamp + MATURITY);
        uint256 bookValueAtMaturity = oracle.getBookValue(strategy, address(market));

        // Both should return face value (consistent behavior)
        assertEq(bookValueBeforeMaturity, newPtAmount, "Book value before maturity should be face value");
        assertEq(bookValueAtMaturity, newPtAmount, "Book value at maturity should be face value");
        assertEq(bookValueBeforeMaturity, bookValueAtMaturity, "Book values should be consistent");
    }

    /// @notice Test book value returns 0 when both stored and current amounts are 0
    function test_GetBookValue_ZeroStoredAmountZeroBalance() public {
        uint256 ptAmount = 100e18;
        uint256 sySpent = 90e18;

        // Initial purchase
        pt.mint(strategy, ptAmount);
        vm.prank(keeper);
        oracle.recordPurchase(strategy, address(market), sySpent, ptAmount, bytes32(0));

        // Full redemption
        vm.prank(keeper);
        oracle.recordRedemption(strategy, address(market), ptAmount);
        pt.burn(strategy, ptAmount);

        // Both stored and current are 0
        uint256 bookValue = oracle.getBookValue(strategy, address(market));
        assertEq(bookValue, 0, "Book value should be 0 when no PT held");
    }
}
