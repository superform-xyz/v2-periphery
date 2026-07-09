// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultAggregator } from "../../src/ManagedSuperVault/ManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

/// @notice Unit tests for the FORK-SPECIFIC behavior of ManagedSuperVaultAggregator.
/// @dev Only the diffs vs src/SuperVault/SuperVaultAggregator.sol are covered here:
///      (1) forwardPPS gated to the stored navOracle (one-time initial set + timelocked change),
///      (2) upkeep subsystem removed (PPS pushes need no funding),
///      (3) governance re-gated from `msg.sender == SUPER_GOVERNOR` to SuperGovernor ROLE holders,
///      (4) createVault clones a quartet + registers NAV attestation config atomically,
///      (5) updateDeviationThreshold hardened to (0, 1e18].
///      Inherited-identical logic is covered by the main family's suite.
contract ManagedSuperVaultAggregatorTest is ManagedSuperVaultTestBase {
    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _singlePPSArgs(
        address strategy_,
        uint256 pps,
        uint256 ts
    )
        internal
        view
        returns (IManagedSuperVaultAggregator.ForwardPPSArgs memory args)
    {
        address[] memory strategies = new address[](1);
        strategies[0] = strategy_;
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = pps;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = ts;

        args = IManagedSuperVaultAggregator.ForwardPPSArgs({
            strategies: strategies,
            ppss: ppss,
            timestamps: timestamps,
            updateAuthority: manager
        });
    }

    /// @dev Pushes a fresh PPS directly from the NAV oracle (no upkeep funding exists in this family)
    function _pushFreshPPS(uint256 newPPS) internal {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(address(navOracle));
        aggregator.forwardPPS(_singlePPSArgs(address(strategy), newPPS, block.timestamp));
    }

    /// @dev Deploys a fresh (oracle-unwired) managed aggregator reusing the base implementations
    function _freshAggregator() internal returns (ManagedSuperVaultAggregator fresh) {
        fresh = new ManagedSuperVaultAggregator(
            address(superGovernor),
            aggregator.VAULT_IMPLEMENTATION(),
            aggregator.STRATEGY_IMPLEMENTATION(),
            aggregator.ESCROW_IMPLEMENTATION(),
            aggregator.QUEUE_IMPLEMENTATION()
        );
    }

    /*//////////////////////////////////////////////////////////////
                    CONSTRUCTOR + INITIAL NAV ORACLE WIRING
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_RevertZeroAddresses() public {
        address v = aggregator.VAULT_IMPLEMENTATION();
        address s = aggregator.STRATEGY_IMPLEMENTATION();
        address e = aggregator.ESCROW_IMPLEMENTATION();
        address q = aggregator.QUEUE_IMPLEMENTATION();
        address g = address(superGovernor);

        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        new ManagedSuperVaultAggregator(address(0), v, s, e, q);

        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        new ManagedSuperVaultAggregator(g, address(0), s, e, q);

        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        new ManagedSuperVaultAggregator(g, v, address(0), e, q);

        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        new ManagedSuperVaultAggregator(g, v, s, address(0), q);

        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        new ManagedSuperVaultAggregator(g, v, s, e, address(0));
    }

    function test_SetInitialNavOracle_SuperGovernorRoleSucceeds() public {
        ManagedSuperVaultAggregator fresh = _freshAggregator();
        address oracle = makeAddr("initialOracle");
        assertEq(fresh.navOracle(), address(0));

        vm.expectEmit(true, true, true, true, address(fresh));
        emit IManagedSuperVaultAggregator.NavOracleChanged(address(0), oracle);
        vm.prank(sGovernor);
        fresh.setInitialNavOracle(oracle);

        assertEq(fresh.navOracle(), oracle);
    }

    function test_SetInitialNavOracle_RevertWrongRole() public {
        ManagedSuperVaultAggregator fresh = _freshAggregator();
        address oracle = makeAddr("initialOracle");

        address[4] memory badCallers = [governor, guardian, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            fresh.setInitialNavOracle(oracle);
        }
        assertEq(fresh.navOracle(), address(0));
    }

    function test_SetInitialNavOracle_RevertZeroAddress() public {
        ManagedSuperVaultAggregator fresh = _freshAggregator();

        vm.prank(sGovernor);
        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        fresh.setInitialNavOracle(address(0));
    }

    function test_SetInitialNavOracle_RevertAlreadySet() public {
        // The base fixture already wired an oracle — a second first-set must revert
        assertEq(aggregator.navOracle(), address(navOracle));

        vm.prank(sGovernor);
        vm.expectRevert(IManagedSuperVaultAggregator.NAV_ORACLE_ALREADY_SET.selector);
        aggregator.setInitialNavOracle(makeAddr("secondOracle"));

        assertEq(aggregator.navOracle(), address(navOracle));
    }

    function test_UnwiredAggregator_IsInert() public {
        ManagedSuperVaultAggregator fresh = _freshAggregator();
        assertEq(fresh.navOracle(), address(0));

        // forwardPPS is unauthorized for everyone (navOracle == address(0))
        IManagedSuperVaultAggregator.ForwardPPSArgs memory args =
            _singlePPSArgs(address(strategy), INITIAL_PPS, block.timestamp);
        vm.prank(user);
        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_PPS_ORACLE.selector);
        fresh.forwardPPS(args);
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_PPS_ORACLE.selector);
        fresh.forwardPPS(args);

        // createVault reverts: the atomic attestation-config registration targets address(0) (no code)
        vm.prank(manager);
        vm.expectRevert();
        fresh.createVault(_defaultParams());
    }

    /*//////////////////////////////////////////////////////////////
                          CREATE VAULT WIRING
    //////////////////////////////////////////////////////////////*/

    function test_CreateVault_RegistersQuartet() public view {
        // Registry: one of each, all matching the setUp deployment
        assertEq(aggregator.getSuperVaultsCount(), 1);
        assertEq(aggregator.getSuperVaultStrategiesCount(), 1);
        assertEq(aggregator.getSuperVaultEscrowsCount(), 1);
        assertEq(aggregator.getAllDepositQueues().length, 1);

        assertEq(aggregator.getAllSuperVaults()[0], address(vault));
        assertEq(aggregator.getAllSuperVaultStrategies()[0], address(strategy));
        assertEq(aggregator.getAllSuperVaultEscrows()[0], address(escrow));
        assertEq(aggregator.getAllDepositQueues()[0], address(queue));

        // Deposit queue lookups (4th-clone diff)
        assertEq(aggregator.getDepositQueue(address(vault)), address(queue));
        assertTrue(aggregator.isDepositQueue(address(queue)));
        assertFalse(aggregator.isDepositQueue(address(vault)));
        assertEq(vault.depositQueue(), address(queue));

        // Vault + strategy resolve THIS aggregator (initialize-stored, not the registry key):
        // getStoredPPS round-trips through the managed aggregator and getPPS would revert
        // UNKNOWN_STRATEGY on any other aggregator
        assertEq(strategy.getStoredPPS(), INITIAL_PPS);
        assertEq(aggregator.getPPS(address(strategy)), INITIAL_PPS);

        // _canAcceptDeposits hits the right aggregator (queue-gated sync deposits)
        assertEq(vault.maxDeposit(address(queue)), type(uint256).max);
        assertEq(vault.maxDeposit(user), 0);

        // Default deviation threshold applied
        assertEq(aggregator.getDeviationThreshold(address(strategy)), 5e17);
        assertEq(aggregator.getCurrentNonce(), 1);
    }

    function test_CreateVault_NavConfigRegisteredAtomically() public view {
        address[] memory attestors = navOracle.getNAVAttestors(address(strategy));
        assertEq(attestors.length, 2);
        assertEq(attestors[0], attestor);
        assertEq(attestors[1], attestor2);
        assertEq(navOracle.getNAVAttestationThreshold(address(strategy)), 1);
        assertTrue(navOracle.isNAVAttestor(address(strategy), attestor));
        assertTrue(navOracle.isNAVAttestor(address(strategy), attestor2));
        assertFalse(navOracle.isNAVAttestor(address(strategy), manager));
    }

    function test_CreateVault_EmitsDeploymentEvents() public {
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();

        uint256 nonce = aggregator.getCurrentNonce();
        bytes32 salt = keccak256(abi.encode(manager, params.asset, params.name, params.symbol, nonce));
        address predictedVault =
            Clones.predictDeterministicAddress(aggregator.VAULT_IMPLEMENTATION(), salt, address(aggregator));
        address predictedEscrow =
            Clones.predictDeterministicAddress(aggregator.ESCROW_IMPLEMENTATION(), salt, address(aggregator));
        address predictedStrategy =
            Clones.predictDeterministicAddress(aggregator.STRATEGY_IMPLEMENTATION(), salt, address(aggregator));
        address predictedQueue =
            Clones.predictDeterministicAddress(aggregator.QUEUE_IMPLEMENTATION(), salt, address(aggregator));

        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.ManagedVaultDeployed(
            predictedVault,
            predictedStrategy,
            predictedEscrow,
            predictedQueue,
            params.asset,
            params.name,
            params.symbol,
            nonce
        );
        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.MetadataURIUpdated(predictedStrategy, params.metadataURI);
        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.PPSUpdated(predictedStrategy, INITIAL_PPS, block.timestamp);

        vm.prank(manager);
        (address vault_, address strategy_, address escrow_, address queue_) = aggregator.createVault(params);

        assertEq(vault_, predictedVault);
        assertEq(strategy_, predictedStrategy);
        assertEq(escrow_, predictedEscrow);
        assertEq(queue_, predictedQueue);
    }

    function test_CreateVault_RevertZeroAddressParams() public {
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();

        params.asset = address(0);
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        aggregator.createVault(params);

        params = _defaultParams();
        params.mainManager = address(0);
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        aggregator.createVault(params);

        params = _defaultParams();
        params.feeConfig.recipient = address(0);
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        aggregator.createVault(params);
    }

    function test_CreateVault_RevertEmptyNameOrSymbol() public {
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();

        params.name = "";
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_VAULT_PARAMS.selector);
        aggregator.createVault(params);

        params = _defaultParams();
        params.symbol = "";
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_VAULT_PARAMS.selector);
        aggregator.createVault(params);
    }

    function test_CreateVault_RevertMaxStalenessTooLow() public {
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();
        params.maxStaleness = superGovernor.getMinStaleness() - 1;

        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.MAX_STALENESS_TOO_LOW.selector);
        aggregator.createVault(params);
    }

    function test_CreateVault_RevertMinUpdateIntervalGteMaxStaleness() public {
        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();
        params.minUpdateInterval = params.maxStaleness;

        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_VAULT_PARAMS.selector);
        aggregator.createVault(params);

        params.minUpdateInterval = params.maxStaleness + 1;
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_VAULT_PARAMS.selector);
        aggregator.createVault(params);
    }

    function test_CreateVault_SecondVaultGetsDistinctClones() public {
        // Identical params — only the creation nonce salts the clones apart
        (address vaultB, address strategyB, address escrowB, address queueB) = _createManagedVault(_defaultParams());
        (address vaultC, address strategyC, address escrowC, address queueC) = _createManagedVault(_defaultParams());

        assertTrue(vaultB != vaultC && vaultB != address(vault) && vaultC != address(vault));
        assertTrue(strategyB != strategyC && strategyB != address(strategy) && strategyC != address(strategy));
        assertTrue(escrowB != escrowC && escrowB != address(escrow) && escrowC != address(escrow));
        assertTrue(queueB != queueC && queueB != address(queue) && queueC != address(queue));

        assertEq(aggregator.getCurrentNonce(), 3);
        assertEq(aggregator.getSuperVaultsCount(), 3);
        assertEq(aggregator.getAllDepositQueues().length, 3);
        assertEq(aggregator.getDepositQueue(vaultB), queueB);
        assertEq(aggregator.getDepositQueue(vaultC), queueC);
        assertEq(ManagedSuperVault(vaultB).depositQueue(), queueB);
    }

    /*//////////////////////////////////////////////////////////////
                           FORWARD PPS GATING
    //////////////////////////////////////////////////////////////*/

    function test_ForwardPPS_RevertNotNavOracle() public {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        IManagedSuperVaultAggregator.ForwardPPSArgs memory args =
            _singlePPSArgs(address(strategy), 1.1e18, block.timestamp);

        address[3] memory badCallers = [manager, sGovernor, user];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_PPS_ORACLE.selector);
            aggregator.forwardPPS(args);
        }

        // PPS untouched
        assertEq(aggregator.getPPS(address(strategy)), INITIAL_PPS);
    }

    function test_ForwardPPS_FromNavOracleSucceeds() public {
        // No upkeep subsystem exists in the managed family: the push works with zero funding
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        uint256 ts = block.timestamp;

        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.PPSUpdated(address(strategy), 1.2e18, ts);
        vm.prank(address(navOracle));
        aggregator.forwardPPS(_singlePPSArgs(address(strategy), 1.2e18, ts));

        assertEq(aggregator.getPPS(address(strategy)), 1.2e18);
        assertEq(aggregator.getLastUpdateTimestamp(address(strategy)), ts);
        assertFalse(aggregator.isStrategyPaused(address(strategy)));
        assertFalse(aggregator.isPPSStale(address(strategy)));
    }

    /*//////////////////////////////////////////////////////////////
                      NAV ORACLE CHANGE LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    function test_ProposeNavOracle_SuperGovernorRoleSucceeds() public {
        assertEq(aggregator.NAV_ORACLE_CHANGE_TIMELOCK(), 7 days);

        address newOracle = makeAddr("newNavOracle");
        uint256 expectedEffective = block.timestamp + aggregator.NAV_ORACLE_CHANGE_TIMELOCK();

        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.NavOracleProposed(newOracle, expectedEffective);
        vm.prank(sGovernor);
        aggregator.proposeNavOracle(newOracle);

        assertEq(aggregator.proposedNavOracle(), newOracle);
        assertEq(aggregator.navOracleEffectiveTime(), expectedEffective);
        // The active oracle is untouched until execution
        assertEq(aggregator.navOracle(), address(navOracle));
    }

    function test_ProposeNavOracle_RevertWrongRole() public {
        address newOracle = makeAddr("newNavOracle");

        // The raw SuperGovernor CONTRACT address is also rejected — the gate moved from
        // `msg.sender == address(SUPER_GOVERNOR)` to role-holders calling directly
        address[4] memory badCallers = [governor, guardian, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.proposeNavOracle(newOracle);
        }
    }

    function test_ProposeNavOracle_RevertZeroAddress() public {
        vm.prank(sGovernor);
        vm.expectRevert(IManagedSuperVaultAggregator.ZERO_ADDRESS.selector);
        aggregator.proposeNavOracle(address(0));
    }

    function test_ExecuteNavOracleChange_SwapsAfterTimelock() public {
        address newOracle = makeAddr("newNavOracle");
        vm.prank(sGovernor);
        aggregator.proposeNavOracle(newOracle);

        // Before the timelock expires
        vm.expectRevert(IManagedSuperVaultAggregator.TIMELOCK_NOT_EXPIRED.selector);
        aggregator.executeNavOracleChange();

        vm.warp(block.timestamp + 7 days);

        // Execution is permissionless once the timelock elapsed
        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.NavOracleChanged(address(navOracle), newOracle);
        vm.prank(user);
        aggregator.executeNavOracleChange();

        assertEq(aggregator.navOracle(), newOracle);
        assertEq(aggregator.proposedNavOracle(), address(0));
        assertEq(aggregator.navOracleEffectiveTime(), 0);

        // The OLD oracle is no longer authorized...
        IManagedSuperVaultAggregator.ForwardPPSArgs memory args =
            _singlePPSArgs(address(strategy), 1.05e18, block.timestamp);
        vm.prank(address(navOracle));
        vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_PPS_ORACLE.selector);
        aggregator.forwardPPS(args);

        // ...and the NEW one is
        vm.prank(newOracle);
        aggregator.forwardPPS(args);
        assertEq(aggregator.getPPS(address(strategy)), 1.05e18);
    }

    function test_ExecuteNavOracleChange_RevertNoPending() public {
        vm.expectRevert(IManagedSuperVaultAggregator.NO_PENDING_NAV_ORACLE_CHANGE.selector);
        aggregator.executeNavOracleChange();
    }

    function test_CancelNavOracleChange() public {
        address newOracle = makeAddr("newNavOracle");
        vm.prank(sGovernor);
        aggregator.proposeNavOracle(newOracle);

        // Role-gated: non SUPER_GOVERNOR_ROLE holders cannot cancel
        address[4] memory badCallers = [governor, guardian, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.cancelNavOracleChange();
        }

        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.NavOracleChangeCancelled(newOracle);
        vm.prank(sGovernor);
        aggregator.cancelNavOracleChange();

        assertEq(aggregator.proposedNavOracle(), address(0));
        assertEq(aggregator.navOracleEffectiveTime(), 0);
        assertEq(aggregator.navOracle(), address(navOracle));

        // Pending fully cleared: execute + a second cancel both revert
        vm.warp(block.timestamp + 7 days);
        vm.expectRevert(IManagedSuperVaultAggregator.NO_PENDING_NAV_ORACLE_CHANGE.selector);
        aggregator.executeNavOracleChange();

        vm.prank(sGovernor);
        vm.expectRevert(IManagedSuperVaultAggregator.NO_PENDING_NAV_ORACLE_CHANGE.selector);
        aggregator.cancelNavOracleChange();
    }

    /*//////////////////////////////////////////////////////////////
                        ROLE RE-GATING MATRIX
    //////////////////////////////////////////////////////////////*/

    function test_ChangePrimaryManager_SuperGovernorRoleSucceeds() public {
        // Seed a pending manager-change proposal so we can verify the override clears it
        vm.prank(secondaryManager);
        aggregator.proposeChangePrimaryManager(address(strategy), user, treasury);
        (address pendingBefore,) = aggregator.getPendingManagerChange(address(strategy));
        assertEq(pendingBefore, user);
        assertEq(aggregator.getSecondaryManagers(address(strategy)).length, 1);

        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.SecondaryManagerRemoved(address(strategy), secondaryManager);
        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.PrimaryManagerChanged(address(strategy), manager, user2, treasury);
        vm.prank(sGovernor);
        aggregator.changePrimaryManager(address(strategy), user2, treasury);

        // New primary manager installed, secondary managers + pending proposals wiped
        assertEq(aggregator.getMainManager(address(strategy)), user2);
        assertEq(aggregator.getSecondaryManagers(address(strategy)).length, 0);
        (address pendingAfter, uint256 effectiveAfter) = aggregator.getPendingManagerChange(address(strategy));
        assertEq(pendingAfter, address(0));
        assertEq(effectiveAfter, 0);

        // Fee recipient swapped on the strategy
        assertEq(strategy.getConfigInfo().recipient, treasury);
    }

    function test_ChangePrimaryManager_RevertWrongRole() public {
        address[4] memory badCallers = [governor, guardian, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.changePrimaryManager(address(strategy), user2, treasury);
        }
        assertEq(aggregator.getMainManager(address(strategy)), manager);
    }

    function test_ChangePrimaryManager_RevertWhenTakeoversFrozen() public {
        // freezeManagerTakeover is SUPER_GOVERNOR_ROLE gated on the SuperGovernor itself
        vm.prank(sGovernor);
        superGovernor.freezeManagerTakeover();
        assertTrue(superGovernor.isManagerTakeoverFrozen());

        vm.prank(sGovernor);
        vm.expectRevert(IManagedSuperVaultAggregator.MANAGER_TAKEOVERS_FROZEN.selector);
        aggregator.changePrimaryManager(address(strategy), user2, treasury);
    }

    function test_ResetHighWaterMark_SuperGovernorRoleSucceeds() public {
        // Grow PPS so the reset moves the HWM to a distinct value
        _pushFreshPPS(1.2e18);
        assertEq(strategy.vaultHwmPps(), INITIAL_PPS);

        vm.expectEmit(true, true, true, true, address(strategy));
        emit ISuperVaultStrategy.HighWaterMarkReset(1.2e18);
        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.HighWaterMarkReset(address(strategy), 1.2e18);
        vm.prank(sGovernor);
        aggregator.resetHighWaterMark(address(strategy));

        assertEq(strategy.vaultHwmPps(), 1.2e18);
    }

    function test_ResetHighWaterMark_RevertWrongRole() public {
        address[4] memory badCallers = [governor, guardian, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.resetHighWaterMark(address(strategy));
        }
    }

    function test_SetHooksRootUpdateTimelock_SuperGovernorRoleSucceeds() public {
        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.HooksRootUpdateTimelockChanged(1 hours);
        vm.prank(sGovernor);
        aggregator.setHooksRootUpdateTimelock(1 hours);

        assertEq(aggregator.getHooksRootUpdateTimelock(), 1 hours);
    }

    function test_SetHooksRootUpdateTimelock_RevertWrongRole() public {
        address[4] memory badCallers = [governor, guardian, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.setHooksRootUpdateTimelock(1 hours);
        }
    }

    function test_ProposeGlobalHooksRoot_GovernorRoleSucceeds() public {
        bytes32 root = keccak256("global-hooks-root");
        uint256 expectedEffective = block.timestamp + aggregator.getHooksRootUpdateTimelock();

        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.GlobalHooksRootUpdateProposed(root, expectedEffective);
        vm.prank(governor);
        aggregator.proposeGlobalHooksRoot(root);

        (bytes32 proposedRoot, uint256 effectiveTime) = aggregator.getProposedGlobalHooksRoot();
        assertEq(proposedRoot, root);
        assertEq(effectiveTime, expectedEffective);

        // After the timelock, execution is permissionless and installs the root
        vm.warp(expectedEffective);
        vm.expectEmit(true, true, true, true, address(aggregator));
        emit IManagedSuperVaultAggregator.GlobalHooksRootUpdated(bytes32(0), root);
        vm.prank(user);
        aggregator.executeGlobalHooksRootUpdate();

        assertEq(aggregator.getGlobalHooksRoot(), root);
    }

    function test_ProposeGlobalHooksRoot_RevertWrongRole() public {
        // Note: sGovernor holds SUPER_GOVERNOR_ROLE + DEFAULT_ADMIN, but NOT GOVERNOR_ROLE
        address[4] memory badCallers = [sGovernor, guardian, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.proposeGlobalHooksRoot(keccak256("global-hooks-root"));
        }
    }

    function test_SetGlobalHooksRootVetoStatus_GuardianRoleSucceeds() public {
        assertFalse(aggregator.isGlobalHooksRootVetoed());

        vm.prank(guardian);
        aggregator.setGlobalHooksRootVetoStatus(true);
        assertTrue(aggregator.isGlobalHooksRootVetoed());

        vm.prank(guardian);
        aggregator.setGlobalHooksRootVetoStatus(false);
        assertFalse(aggregator.isGlobalHooksRootVetoed());
    }

    function test_SetGlobalHooksRootVetoStatus_RevertWrongRole() public {
        address[4] memory badCallers = [sGovernor, governor, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.setGlobalHooksRootVetoStatus(true);
        }
    }

    function test_SetStrategyHooksRootVetoStatus_GuardianRoleSucceeds() public {
        assertFalse(aggregator.isStrategyHooksRootVetoed(address(strategy)));

        vm.prank(guardian);
        aggregator.setStrategyHooksRootVetoStatus(address(strategy), true);
        assertTrue(aggregator.isStrategyHooksRootVetoed(address(strategy)));

        vm.prank(guardian);
        aggregator.setStrategyHooksRootVetoStatus(address(strategy), false);
        assertFalse(aggregator.isStrategyHooksRootVetoed(address(strategy)));
    }

    function test_SetStrategyHooksRootVetoStatus_RevertWrongRole() public {
        address[4] memory badCallers = [sGovernor, governor, manager, address(superGovernor)];
        for (uint256 i; i < badCallers.length; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(IManagedSuperVaultAggregator.UNAUTHORIZED_UPDATE_AUTHORITY.selector);
            aggregator.setStrategyHooksRootVetoStatus(address(strategy), true);
        }
    }

    /*//////////////////////////////////////////////////////////////
                   DEVIATION THRESHOLD HARDENING
    //////////////////////////////////////////////////////////////*/

    function test_UpdateDeviationThreshold_BoundsEnforced() public {
        // Upper bound inclusive: exactly 100% is allowed
        vm.prank(manager);
        aggregator.updateDeviationThreshold(address(strategy), 1e18);
        assertEq(aggregator.getDeviationThreshold(address(strategy)), 1e18);

        // Interior value allowed
        vm.prank(manager);
        aggregator.updateDeviationThreshold(address(strategy), 3e17);
        assertEq(aggregator.getDeviationThreshold(address(strategy)), 3e17);

        // Zero would block every update
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_DEVIATION_THRESHOLD.selector);
        aggregator.updateDeviationThreshold(address(strategy), 0);

        // Above 100% rejected
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_DEVIATION_THRESHOLD.selector);
        aggregator.updateDeviationThreshold(address(strategy), 1e18 + 1);

        // type(uint256).max (the main family's "disable" sentinel) cannot disable the check here
        vm.prank(manager);
        vm.expectRevert(IManagedSuperVaultAggregator.INVALID_DEVIATION_THRESHOLD.selector);
        aggregator.updateDeviationThreshold(address(strategy), type(uint256).max);

        assertEq(aggregator.getDeviationThreshold(address(strategy)), 3e17);
    }

    /*//////////////////////////////////////////////////////////////
                        DUAL-STACK REGRESSION
    //////////////////////////////////////////////////////////////*/

    /// @notice Main-family and managed-family stacks coexist: the main clones resolve their aggregator
    ///         via the SUPER_VAULT_AGGREGATOR registry key while managed clones use the address stored
    ///         at initialize, and pause state never bleeds across families.
    function test_DualStack_MainAndManagedResolveIndependently() public {
        // Deploy a MAIN-family stack alongside the managed one
        SuperVaultAggregator mainAggregator = new SuperVaultAggregator(
            address(superGovernor),
            address(new SuperVault(address(superGovernor))),
            address(new SuperVaultStrategy(address(superGovernor))),
            address(new SuperVaultEscrow())
        );

        // Register it under the MAIN registry key (managed clones never read this key)
        bytes32 mainAggregatorKey = superGovernor.SUPER_VAULT_AGGREGATOR();
        vm.prank(sGovernor);
        superGovernor.setAddress(mainAggregatorKey, address(mainAggregator));
        assertEq(superGovernor.getAddress(mainAggregatorKey), address(mainAggregator));

        vm.prank(manager);
        (address mainVault, address mainStrategy,) = mainAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Main Vault",
                symbol: "MNV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: MIN_UPDATE_INTERVAL,
                maxStaleness: MAX_STALENESS,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: feeRecipient
                })
            })
        );

        // Each strategy resolves ITS aggregator: both stored-PPS reads work independently
        // (getPPS reverts UNKNOWN_STRATEGY on a foreign aggregator, so success proves resolution)
        assertEq(SuperVaultStrategy(payable(mainStrategy)).getStoredPPS(), INITIAL_PPS);
        assertEq(strategy.getStoredPPS(), INITIAL_PPS);

        // Registries are disjoint
        vm.expectRevert(ISuperVaultAggregator.UNKNOWN_STRATEGY.selector);
        mainAggregator.getPPS(address(strategy));
        vm.expectRevert(IManagedSuperVaultAggregator.UNKNOWN_STRATEGY.selector);
        aggregator.getPPS(mainStrategy);

        // Both vaults accept deposits
        assertEq(SuperVault(mainVault).maxDeposit(user), type(uint256).max);
        assertEq(vault.maxDeposit(address(queue)), type(uint256).max);

        // Pausing the MANAGED strategy does not affect the MAIN vault
        vm.prank(manager);
        aggregator.pauseStrategy(address(strategy));
        assertEq(vault.maxDeposit(address(queue)), 0);
        assertEq(SuperVault(mainVault).maxDeposit(user), type(uint256).max);
        assertFalse(mainAggregator.isStrategyPaused(mainStrategy));

        // Recover the managed strategy: unpause + fresh NAV-oracle push clears the stale flag
        vm.prank(manager);
        aggregator.unpauseStrategy(address(strategy));
        _pushFreshPPS(INITIAL_PPS);
        assertEq(vault.maxDeposit(address(queue)), type(uint256).max);

        // Pausing the MAIN strategy does not affect the MANAGED vault
        vm.prank(manager);
        mainAggregator.pauseStrategy(mainStrategy);
        assertEq(SuperVault(mainVault).maxDeposit(user), 0);
        assertEq(vault.maxDeposit(address(queue)), type(uint256).max);
        assertFalse(aggregator.isStrategyPaused(address(strategy)));
    }
}
