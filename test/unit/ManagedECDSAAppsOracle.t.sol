// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ManagedECDSAAppsOracle } from "../../src/oracles/ManagedECDSAAppsOracle.sol";
import { IManagedECDSAAppsOracle } from "../../src/interfaces/oracles/IManagedECDSAAppsOracle.sol";
import { IECDSAPPSOracle } from "../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { MockSuperVaultAggregator } from "../mocks/MockSuperVaultAggregator.sol";

/// @notice Unit tests for ManagedECDSAAppsOracle
contract ManagedECDSAAppsOracleTest is Test {
    // Role hashes
    bytes32 internal constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 internal constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");
    bytes32 internal constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    SuperGovernor internal superGovernor;
    ManagedECDSAAppsOracle internal oracle;
    MockSuperVaultAggregator internal aggregator;

    address internal sGovernor;
    address internal governor;
    address internal oracleManager;
    address internal manager;
    address internal stranger;
    address internal svStrategy;

    function setUp() public {
        sGovernor = makeAddr("sGovernor");
        governor = makeAddr("governor");
        oracleManager = makeAddr("oracleManager");
        manager = makeAddr("manager");
        stranger = makeAddr("stranger");
        svStrategy = makeAddr("svStrategy");

        superGovernor = new SuperGovernor(
            sGovernor,
            governor,
            governor,
            oracleManager,
            governor,
            governor,
            makeAddr("treasury"),
            false
        );

        aggregator = new MockSuperVaultAggregator();
        aggregator.setMainManager(svStrategy, manager);
        aggregator.setMaxStaleness(svStrategy, 1 days);
        aggregator.setPPS(svStrategy, 1e6);

        // Register aggregator in superGovernor
        vm.prank(sGovernor);
        superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, address(aggregator));

        oracle = new ManagedECDSAAppsOracle(address(superGovernor), "ManagedOracle", "1");
    }

    // =============================================================
    // Constructor
    // =============================================================

    function test_Constructor_StoresGovernor() public view {
        assertEq(address(oracle.SUPER_GOVERNOR()), address(superGovernor));
    }

    function test_Constructor_RevertZeroGovernor() public {
        vm.expectRevert(IECDSAPPSOracle.INVALID_VALIDATOR.selector);
        new ManagedECDSAAppsOracle(address(0), "Oracle", "1");
    }

    // =============================================================
    // setManagedStrategy
    // =============================================================

    function test_SetManagedStrategy_GovernorCanSet() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);
        assertTrue(oracle.isManagedStrategy(svStrategy));
    }

    function test_SetManagedStrategy_EmitsEvent() public {
        vm.expectEmit(true, true, true, true, address(oracle));
        emit IManagedECDSAAppsOracle.ManagedStrategySet(svStrategy, true);
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);
    }

    function test_SetManagedStrategy_CanUnset() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);
        assertTrue(oracle.isManagedStrategy(svStrategy));

        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, false);
        assertFalse(oracle.isManagedStrategy(svStrategy));
    }

    function test_SetManagedStrategy_RevertUnauthorized() public {
        vm.expectRevert(IManagedECDSAAppsOracle.UNAUTHORIZED.selector);
        vm.prank(stranger);
        oracle.setManagedStrategy(svStrategy, true);
    }

    function test_SetManagedStrategy_RevertNonGovernor_Manager() public {
        vm.expectRevert(IManagedECDSAAppsOracle.UNAUTHORIZED.selector);
        vm.prank(manager);
        oracle.setManagedStrategy(svStrategy, true);
    }

    // =============================================================
    // updatePPSManaged
    // =============================================================

    function test_UpdatePPSManaged_ManagerCanUpdate() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);

        uint256 newPPS = 1_050_000;
        vm.prank(manager);
        oracle.updatePPSManaged(svStrategy, newPPS);

        // Aggregator should have the new PPS
        assertEq(aggregator.getPPS(svStrategy), newPPS);
    }

    function test_UpdatePPSManaged_OracleManagerCanUpdate() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);

        uint256 newPPS = 1_100_000;
        vm.prank(oracleManager);
        oracle.updatePPSManaged(svStrategy, newPPS);

        assertEq(aggregator.getPPS(svStrategy), newPPS);
    }

    function test_UpdatePPSManaged_EmitsEvent() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);

        uint256 newPPS = 1_050_000;
        vm.expectEmit(true, true, true, true, address(oracle));
        emit IManagedECDSAAppsOracle.ManagedPPSUpdated(svStrategy, newPPS, manager);

        vm.prank(manager);
        oracle.updatePPSManaged(svStrategy, newPPS);
    }

    function test_UpdatePPSManaged_RevertNotManagedStrategy() public {
        // svStrategy not registered as managed
        vm.expectRevert(IManagedECDSAAppsOracle.NOT_MANAGED_STRATEGY.selector);
        vm.prank(manager);
        oracle.updatePPSManaged(svStrategy, 1e6);
    }

    function test_UpdatePPSManaged_RevertUnauthorizedStranger() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);

        vm.expectRevert(IManagedECDSAAppsOracle.UNAUTHORIZED.selector);
        vm.prank(stranger);
        oracle.updatePPSManaged(svStrategy, 1e6);
    }

    function test_UpdatePPSManaged_ForwardsToAggregator() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);

        uint256 newPPS = 2_000_000;
        vm.prank(manager);
        oracle.updatePPSManaged(svStrategy, newPPS);

        // Verify aggregator received the call
        assertEq(aggregator.lastForwardedStrategies(0), svStrategy);
        assertEq(aggregator.lastForwardedPpss(0), newPPS);
    }

    // =============================================================
    // updatePPS routing guard (blocks managed strategies)
    // =============================================================

    function test_UpdatePPS_RevertIfManagedStrategyIncluded() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);

        address[] memory strategies = new address[](1);
        strategies[0] = svStrategy;
        bytes[][] memory proofs = new bytes[][](1);
        proofs[0] = new bytes[](0);
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = 1e6;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        vm.expectRevert(IManagedECDSAAppsOracle.MANAGED_STRATEGY_IN_ECDSA_PATH.selector);
        oracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofs,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_RevertIfManagedStrategyInBatch() public {
        address nonManaged = makeAddr("nonManaged");
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);

        // Batch with both managed and non-managed — must revert
        address[] memory strategies = new address[](2);
        strategies[0] = nonManaged;
        strategies[1] = svStrategy;

        bytes[][] memory proofs = new bytes[][](2);
        proofs[0] = new bytes[](0);
        proofs[1] = new bytes[](0);

        uint256[] memory ppss = new uint256[](2);
        ppss[0] = 1e6;
        ppss[1] = 1e6;

        uint256[] memory timestamps = new uint256[](2);
        timestamps[0] = block.timestamp;
        timestamps[1] = block.timestamp;

        vm.expectRevert(IManagedECDSAAppsOracle.MANAGED_STRATEGY_IN_ECDSA_PATH.selector);
        oracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofs,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    function test_UpdatePPS_PassesThroughForNonManagedStrategy() public {
        // A non-managed strategy should reach the parent updatePPS logic.
        // We expect it to fail with ZERO_LENGTH_ARRAY or signature validation
        // (since we pass empty proofs), NOT with MANAGED_STRATEGY_IN_ECDSA_PATH.
        address nonManaged = makeAddr("nonManaged");
        address[] memory strategies = new address[](1);
        strategies[0] = nonManaged;

        bytes[][] memory proofs = new bytes[][](1);
        proofs[0] = new bytes[](0); // empty proofs → will fail at ZERO_LENGTH_ARRAY in parent

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = 1e6;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        // Should reach parent logic and revert with parent error (not routing guard error).
        // Parent reverts with INVALID_TOTAL_VALIDATORS because no validators are registered.
        vm.expectRevert(IECDSAPPSOracle.INVALID_TOTAL_VALIDATORS.selector);
        oracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofs,
                ppss: ppss,
                timestamps: timestamps
            })
        );
    }

    // =============================================================
    // isManagedStrategy view
    // =============================================================

    function test_IsManagedStrategy_FalseByDefault() public view {
        assertFalse(oracle.isManagedStrategy(svStrategy));
    }

    function test_IsManagedStrategy_TrueAfterSet() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);
        assertTrue(oracle.isManagedStrategy(svStrategy));
    }

    function test_IsManagedStrategy_FalseAfterUnset() public {
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, true);
        vm.prank(governor);
        oracle.setManagedStrategy(svStrategy, false);
        assertFalse(oracle.isManagedStrategy(svStrategy));
    }
}
