// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { BasefeeGasOracle } from "../../src/oracles/BasefeeGasOracle.sol";

/// @title BasefeeGasOracleTest
/// @notice Unit tests for BasefeeGasOracle - basefee-derived Chainlink compatible gas price oracle
contract BasefeeGasOracleTest is Test {
    BasefeeGasOracle public oracle;
    address public admin;
    address public gasManager;

    // Initial calibration (see technical spec)
    uint256 constant INITIAL_MULTIPLIER_BPS = 20_000; // 2x - deliberate over-recovery vs raw basefee
    uint256 constant INITIAL_PRIORITY_FEE_WEI = 1_000_000; // 0.001 gwei

    // Bounds (mirrors contract constants)
    uint256 constant MIN_MULTIPLIER_BPS = 5000;
    uint256 constant MAX_MULTIPLIER_BPS = 30_000;
    uint256 constant MAX_PRIORITY_FEE_WEI = 10 gwei;

    // Realistic mainnet basefee at spec time (~0.045 gwei)
    uint256 constant REALISTIC_BASEFEE = 44_748_267;

    // Roles
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant GAS_MANAGER_ROLE = keccak256("GAS_MANAGER_ROLE");

    // Events
    event MultiplierUpdated(uint256 oldMultiplierBps, uint256 newMultiplierBps);
    event PriorityFeeUpdated(uint256 oldPriorityFeeWei, uint256 newPriorityFeeWei);

    function setUp() public {
        admin = makeAddr("admin");
        gasManager = makeAddr("gasManager");
        oracle = new BasefeeGasOracle(INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI, admin, gasManager);
    }

    /// @dev Reference formula the contract must match exactly
    function _expectedAnswer(
        uint256 basefee,
        uint256 multiplierBps,
        uint256 priorityFeeWei
    )
        internal
        pure
        returns (int256)
    {
        return int256(basefee * multiplierBps / 10_000 + priorityFeeWei);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test constructor initializes state correctly
    function test_Constructor_InitializesCorrectly() public view {
        assertEq(oracle.decimals(), 0);
        assertEq(oracle.description(), "Basefee Gas / Wei");
        assertEq(oracle.version(), 1);
        assertEq(oracle.multiplierBps(), INITIAL_MULTIPLIER_BPS);
        assertEq(oracle.priorityFeeWei(), INITIAL_PRIORITY_FEE_WEI);
        assertEq(oracle.paramsLastUpdatedAt(), block.timestamp);
        assertTrue(oracle.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(oracle.hasRole(GAS_MANAGER_ROLE, gasManager));
        // Split-key deployment: admin must not implicitly hold the manager role and vice versa
        assertFalse(oracle.hasRole(GAS_MANAGER_ROLE, admin));
        assertFalse(oracle.hasRole(DEFAULT_ADMIN_ROLE, gasManager));
    }

    /// @notice Test constructor enforces the multiplier bounds
    function test_Constructor_RevertsOnMultiplierOutOfBounds() public {
        vm.expectRevert(BasefeeGasOracle.INVALID_MULTIPLIER.selector);
        new BasefeeGasOracle(MIN_MULTIPLIER_BPS - 1, INITIAL_PRIORITY_FEE_WEI, admin, gasManager);

        vm.expectRevert(BasefeeGasOracle.INVALID_MULTIPLIER.selector);
        new BasefeeGasOracle(MAX_MULTIPLIER_BPS + 1, INITIAL_PRIORITY_FEE_WEI, admin, gasManager);

        vm.expectRevert(BasefeeGasOracle.INVALID_MULTIPLIER.selector);
        new BasefeeGasOracle(0, INITIAL_PRIORITY_FEE_WEI, admin, gasManager);
    }

    /// @notice Test constructor enforces the priority fee bound
    function test_Constructor_RevertsOnPriorityFeeOutOfBounds() public {
        vm.expectRevert(BasefeeGasOracle.INVALID_PRIORITY_FEE.selector);
        new BasefeeGasOracle(INITIAL_MULTIPLIER_BPS, MAX_PRIORITY_FEE_WEI + 1, admin, gasManager);
    }

    /// @notice Test constructor rejects zero role holders
    function test_Constructor_RevertsOnZeroAddresses() public {
        vm.expectRevert(BasefeeGasOracle.ZERO_ADDRESS.selector);
        new BasefeeGasOracle(INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI, address(0), gasManager);

        vm.expectRevert(BasefeeGasOracle.ZERO_ADDRESS.selector);
        new BasefeeGasOracle(INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI, admin, address(0));
    }

    /// @notice Test constructor accepts the exact bound values
    function test_Constructor_AcceptsBoundValues() public {
        BasefeeGasOracle atMin = new BasefeeGasOracle(MIN_MULTIPLIER_BPS, 0, admin, gasManager);
        assertEq(atMin.multiplierBps(), MIN_MULTIPLIER_BPS);
        assertEq(atMin.priorityFeeWei(), 0);

        BasefeeGasOracle atMax = new BasefeeGasOracle(MAX_MULTIPLIER_BPS, MAX_PRIORITY_FEE_WEI, admin, gasManager);
        assertEq(atMax.multiplierBps(), MAX_MULTIPLIER_BPS);
        assertEq(atMax.priorityFeeWei(), MAX_PRIORITY_FEE_WEI);
    }

    /*//////////////////////////////////////////////////////////////
                             FORMULA TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test the answer matches the reference formula at a realistic mainnet basefee
    function test_Answer_MatchesFormulaAtRealisticBasefee() public {
        vm.fee(REALISTIC_BASEFEE);
        assertEq(
            oracle.latestAnswer(), _expectedAnswer(REALISTIC_BASEFEE, INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI)
        );
    }

    /// @notice Test explicit basefee edge values (mainnet floor is ~7 wei; 0 only in simulation)
    function test_Answer_ExplicitEdges() public {
        uint256[6] memory basefees = [uint256(0), 1, 7, REALISTIC_BASEFEE, 100 gwei, 10_000 gwei];
        for (uint256 i; i < basefees.length; ++i) {
            vm.fee(basefees[i]);
            assertEq(
                oracle.latestAnswer(),
                _expectedAnswer(basefees[i], INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI),
                "formula mismatch"
            );
        }
    }

    /// @notice Test the eth_call simulation context: at basefee 0 the answer is exactly priorityFeeWei
    function test_Answer_AtZeroBasefeeIsPriorityFee() public {
        vm.fee(0);
        assertEq(oracle.latestAnswer(), int256(INITIAL_PRIORITY_FEE_WEI));
    }

    /// @notice Test sub-10_000-wei basefees are not zeroed out (multiply-before-divide)
    function test_Answer_PrecisionAtTinyBasefee() public {
        BasefeeGasOracle noTip = new BasefeeGasOracle(MAX_MULTIPLIER_BPS, 0, admin, gasManager);
        vm.fee(7);
        // 7 * 30_000 / 10_000 = 21; divide-first would floor to 0
        assertEq(noTip.latestAnswer(), 21);
    }

    /// @notice Test round data fields: fresh timestamps, nonzero monotonic round ids
    function test_RoundData_FieldSemantics() public {
        vm.fee(REALISTIC_BASEFEE);
        vm.roll(23_000_000);
        vm.warp(1_800_000_000);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        assertEq(roundId, 23_000_000);
        assertEq(answer, _expectedAnswer(REALISTIC_BASEFEE, INITIAL_MULTIPLIER_BPS, INITIAL_PRIORITY_FEE_WEI));
        assertEq(startedAt, 1_800_000_000);
        assertEq(updatedAt, 1_800_000_000);
        assertEq(answeredInRound, roundId);
        assertGt(roundId, 0);
    }

    /// @notice Test getRoundData returns current data for any requested round (no rounds exist)
    function test_GetRoundData_ReturnsCurrentDataForAnyRound() public {
        vm.fee(REALISTIC_BASEFEE);
        (, int256 latestAnswer_,,,) = oracle.latestRoundData();
        (, int256 arbitraryRoundAnswer,,,) = oracle.getRoundData(42);
        assertEq(arbitraryRoundAnswer, latestAnswer_);
    }

    /*//////////////////////////////////////////////////////////////
                              SETTER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test multiplier update by gas manager emits old/new event and stamps params timestamp
    function test_SetMultiplierBps_UpdatesAndEmits() public {
        vm.warp(block.timestamp + 100);

        vm.expectEmit(true, true, false, true);
        emit MultiplierUpdated(INITIAL_MULTIPLIER_BPS, 12_000);

        vm.prank(gasManager);
        oracle.setMultiplierBps(12_000);

        assertEq(oracle.multiplierBps(), 12_000);
        assertEq(oracle.paramsLastUpdatedAt(), block.timestamp);
    }

    /// @notice Test priority fee update by gas manager emits old/new event
    function test_SetPriorityFeeWei_UpdatesAndEmits() public {
        vm.expectEmit(true, true, false, true);
        emit PriorityFeeUpdated(INITIAL_PRIORITY_FEE_WEI, 2 gwei);

        vm.prank(gasManager);
        oracle.setPriorityFeeWei(2 gwei);

        assertEq(oracle.priorityFeeWei(), 2 gwei);
    }

    /// @notice Test setter bounds: one past each edge reverts, the edge itself succeeds
    function test_Setters_EnforceBounds() public {
        vm.startPrank(gasManager);

        vm.expectRevert(BasefeeGasOracle.INVALID_MULTIPLIER.selector);
        oracle.setMultiplierBps(MIN_MULTIPLIER_BPS - 1);

        vm.expectRevert(BasefeeGasOracle.INVALID_MULTIPLIER.selector);
        oracle.setMultiplierBps(MAX_MULTIPLIER_BPS + 1);

        vm.expectRevert(BasefeeGasOracle.INVALID_PRIORITY_FEE.selector);
        oracle.setPriorityFeeWei(MAX_PRIORITY_FEE_WEI + 1);

        oracle.setMultiplierBps(MIN_MULTIPLIER_BPS);
        assertEq(oracle.multiplierBps(), MIN_MULTIPLIER_BPS);
        oracle.setMultiplierBps(MAX_MULTIPLIER_BPS);
        assertEq(oracle.multiplierBps(), MAX_MULTIPLIER_BPS);
        oracle.setPriorityFeeWei(MAX_PRIORITY_FEE_WEI);
        assertEq(oracle.priorityFeeWei(), MAX_PRIORITY_FEE_WEI);

        vm.stopPrank();
    }

    /// @notice Test setters revert for the admin (roles are split) and for strangers
    function test_Setters_RevertForNonGasManager() public {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, admin, GAS_MANAGER_ROLE)
        );
        vm.prank(admin);
        oracle.setMultiplierBps(12_000);

        address stranger = makeAddr("stranger");
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, stranger, GAS_MANAGER_ROLE)
        );
        vm.prank(stranger);
        oracle.setPriorityFeeWei(1 gwei);
    }

    /*//////////////////////////////////////////////////////////////
                          ROLE MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test admin can grant and revoke the gas manager role
    function test_Roles_AdminGrantsAndRevokes() public {
        address newManager = makeAddr("newManager");

        vm.prank(admin);
        oracle.grantRole(GAS_MANAGER_ROLE, newManager);
        vm.prank(newManager);
        oracle.setMultiplierBps(12_000);
        assertEq(oracle.multiplierBps(), 12_000);

        vm.prank(admin);
        oracle.revokeRole(GAS_MANAGER_ROLE, gasManager);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, gasManager, GAS_MANAGER_ROLE
            )
        );
        vm.prank(gasManager);
        oracle.setMultiplierBps(11_000);
    }

    /// @notice Test gas manager cannot grant roles (only admin administers roles)
    function test_Roles_GasManagerCannotGrant() public {
        address newManager = makeAddr("newManager");
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, gasManager, DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(gasManager);
        oracle.grantRole(GAS_MANAGER_ROLE, newManager);
    }

    /*//////////////////////////////////////////////////////////////
                               FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fuzz the full formula domain: answer is exact, positive, bounded, and monotone
    function testFuzz_Answer_FormulaAndInvariants(
        uint256 basefee,
        uint256 multiplierBps_,
        uint256 priorityFeeWei_
    )
        public
    {
        basefee = bound(basefee, 0, 10_000 gwei);
        multiplierBps_ = bound(multiplierBps_, MIN_MULTIPLIER_BPS, MAX_MULTIPLIER_BPS);
        priorityFeeWei_ = bound(priorityFeeWei_, 0, MAX_PRIORITY_FEE_WEI);

        BasefeeGasOracle o = new BasefeeGasOracle(multiplierBps_, priorityFeeWei_, admin, gasManager);
        vm.fee(basefee);

        int256 answer = o.latestAnswer();

        // Exactness
        assertEq(answer, _expectedAnswer(basefee, multiplierBps_, priorityFeeWei_));
        // Positivity whenever any input is nonzero (basefee >= 1 with min multiplier still floors to 0
        // only below 2 wei, so assert the strict domain)
        if (priorityFeeWei_ > 0 || basefee * multiplierBps_ >= 10_000) {
            assertGt(answer, 0);
        }
        assertGe(answer, 0);
        // Upper bound the downstream risk analysis rests on: 3x basefee + 10 gwei
        assertLe(uint256(answer), 3 * basefee + 10 gwei);
        // Monotone in basefee
        vm.fee(basefee + 1 gwei);
        assertGe(o.latestAnswer(), answer);
    }

    /// @notice Fuzz round data freshness across arbitrary block contexts
    function testFuzz_RoundData_AlwaysFresh(uint256 blockNumber, uint256 timestamp, uint256 basefee) public {
        blockNumber = bound(blockNumber, 1, type(uint80).max);
        timestamp = bound(timestamp, 1, type(uint64).max);
        basefee = bound(basefee, 0, 10_000 gwei);

        vm.roll(blockNumber);
        vm.warp(timestamp);
        vm.fee(basefee);

        (uint80 roundId,, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = oracle.latestRoundData();
        assertEq(roundId, uint80(blockNumber));
        assertEq(startedAt, timestamp);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, roundId);
        assertGt(roundId, 0);
    }
}
