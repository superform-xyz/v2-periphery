// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { CrossChainPositionCapGuard } from "../../../src/CrossChain/CrossChainPositionCapGuard.sol";
import { ICrossChainPositionCapGuard } from "../../../src/interfaces/CrossChain/ICrossChainPositionCapGuard.sol";
import { MockGovernorLite } from "./mocks/MockGovernorLite.sol";
import { MockAumOracleLite, MockRegistryExposureLite, MockAggregatorLite } from "./mocks/MockCapGuardDeps.sol";

contract CrossChainPositionCapGuardTest is Test {
    CrossChainPositionCapGuard internal guard;
    MockGovernorLite internal governor;
    MockAumOracleLite internal aum;
    MockRegistryExposureLite internal registry;
    MockAggregatorLite internal aggregator;

    address internal strategy = makeAddr("strategy");
    address internal destVault = makeAddr("destVault");
    address internal manager = makeAddr("manager");

    uint64 internal constant CHAIN_A = 8453;
    uint64 internal constant CHAIN_B = 42_161;
    uint256 internal constant CAP_70 = 7000;

    bytes32 internal constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");
    bytes32 internal constant CROSS_CHAIN_POSITION_REGISTRY = keccak256("CROSS_CHAIN_POSITION_REGISTRY");
    bytes32 internal constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    function setUp() public {
        governor = new MockGovernorLite();
        aum = new MockAumOracleLite();
        registry = new MockRegistryExposureLite();
        aggregator = new MockAggregatorLite();
        guard = new CrossChainPositionCapGuard(address(governor));

        governor.setAddress(CROSS_CHAIN_AUM_ORACLE, address(aum));
        governor.setAddress(CROSS_CHAIN_POSITION_REGISTRY, address(registry));
        governor.setAddress(SUPER_VAULT_AGGREGATOR, address(aggregator));
        governor.grantRole(governor.GOVERNOR_ROLE(), address(this)); // this test acts as governor
        aggregator.setMainManager(manager, strategy, true);

        // Default config (as governor - initial set is loosening): 70% global, CHAIN_A enabled cap 500, vault approved.
        _setConfig(CAP_70, CHAIN_A, 500e18, true);
        guard.setApprovedDestination(strategy, CHAIN_A, destVault, true);

        aum.setFresh(strategy, true);
        aum.setTotal(strategy, 1000e18);
    }

    function _setConfig(uint256 bps, uint64 chainId, uint256 cap, bool enabled) internal {
        uint64[] memory chains = new uint64[](1);
        chains[0] = chainId;
        uint256[] memory caps = new uint256[](1);
        caps[0] = cap;
        bool[] memory en = new bool[](1);
        en[0] = enabled;
        guard.setCapConfig(strategy, bps, chains, caps, en);
    }

    /*//////////////////////////////////////////////////////////////
                              VALIDATE
    //////////////////////////////////////////////////////////////*/

    function test_Validate_HappyPath() public view {
        guard.validateAllocation(strategy, CHAIN_A, destVault, 100e18); // 10% <= 70%, chain cap ok
    }

    function test_Validate_RevertUnapprovedVault() public {
        vm.expectRevert(ICrossChainPositionCapGuard.DESTINATION_VAULT_NOT_APPROVED.selector);
        guard.validateAllocation(strategy, CHAIN_A, makeAddr("otherVault"), 1e18);
    }

    function test_Validate_RevertIdleNotEnabled() public {
        vm.expectRevert(ICrossChainPositionCapGuard.IDLE_HOLD_NOT_ENABLED.selector);
        guard.validateAllocation(strategy, CHAIN_A, address(0), 1e18);
    }

    function test_Validate_IdleEnabledOK() public {
        guard.setApprovedDestination(strategy, CHAIN_A, address(0), true); // enable idle-hold
        guard.validateAllocation(strategy, CHAIN_A, address(0), 100e18);
    }

    function test_Validate_RevertStaleAUM() public {
        aum.setFresh(strategy, false);
        vm.expectRevert(ICrossChainPositionCapGuard.AUM_DATA_STALE.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 1e18);
    }

    function test_Validate_RevertZeroTotalAUM() public {
        aum.setTotal(strategy, 0);
        vm.expectRevert(ICrossChainPositionCapGuard.ZERO_TOTAL_AUM.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 1e18);
    }

    function test_Validate_RevertGlobalCapExceeded() public {
        // total 1000, cap 70% -> limit 700. existing effective 650 + 100 = 750 > 700.
        registry.setEff(strategy, 650e18);
        vm.expectRevert(ICrossChainPositionCapGuard.CROSS_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 100e18);
    }

    function test_Validate_InFlightCountedInNumerator() public {
        // effective exposure includes in-flight bridgedOut; 690 + 20 = 710 > 700.
        registry.setEff(strategy, 690e18);
        vm.expectRevert(ICrossChainPositionCapGuard.CROSS_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 20e18);
    }

    function test_Validate_RevertPerChainCapExceeded() public {
        _setConfig(CAP_70, CHAIN_A, 50e18, true); // tighten per-chain cap to 50 (tightening; governor)
        // global ok (100 <= 700) but chain 0 + 100 > 50
        vm.expectRevert(ICrossChainPositionCapGuard.PER_CHAIN_CAP_EXCEEDED.selector);
        guard.validateAllocation(strategy, CHAIN_A, destVault, 100e18);
    }

    function test_Validate_RevertChainNotEnabled() public {
        // approve a vault on CHAIN_B but never enable CHAIN_B -> destination passes, chain fails.
        guard.setApprovedDestination(strategy, CHAIN_B, destVault, true);
        vm.expectRevert(ICrossChainPositionCapGuard.CHAIN_NOT_ENABLED.selector);
        guard.validateAllocation(strategy, CHAIN_B, destVault, 1e18);
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORITY (SEC-2)
    //////////////////////////////////////////////////////////////*/

    function test_SetCapConfig_ManagerCanTighten() public {
        vm.prank(manager);
        _setConfig(5000, CHAIN_A, 400e18, true); // lower global + lower per-chain cap = tightening
        assertEq(guard.maxCrossChainBps(strategy), 5000);
    }

    function test_SetCapConfig_ManagerCannotLoosen() public {
        vm.prank(manager);
        vm.expectRevert(ICrossChainPositionCapGuard.UNAUTHORIZED.selector);
        _setConfig(8000, CHAIN_A, 500e18, true); // raising global cap = loosening -> governor only
    }

    function test_SetCapConfig_ManagerCannotEnableNewChain() public {
        vm.prank(manager);
        vm.expectRevert(ICrossChainPositionCapGuard.UNAUTHORIZED.selector);
        _setConfig(CAP_70, CHAIN_B, 100e18, true); // enabling CHAIN_B = loosening
    }

    function test_SetApprovedDestination_ManagerCannotApprove() public {
        vm.prank(manager);
        vm.expectRevert(ICrossChainPositionCapGuard.UNAUTHORIZED.selector);
        guard.setApprovedDestination(strategy, CHAIN_A, makeAddr("newVault"), true);
    }

    function test_SetApprovedDestination_ManagerCanRevoke() public {
        vm.prank(manager);
        guard.setApprovedDestination(strategy, CHAIN_A, destVault, false);
        assertFalse(guard.isApprovedDestination(strategy, CHAIN_A, destVault));
    }

    function test_SetCapConfig_RevertLengthMismatch() public {
        uint64[] memory chains = new uint64[](2);
        uint256[] memory caps = new uint256[](1);
        bool[] memory en = new bool[](2);
        vm.expectRevert(ICrossChainPositionCapGuard.LENGTH_MISMATCH.selector);
        guard.setCapConfig(strategy, CAP_70, chains, caps, en);
    }
}
