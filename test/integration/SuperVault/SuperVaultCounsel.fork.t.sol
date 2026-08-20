// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { SuperVaultCounsel } from "../../../src/SuperVault/SuperVaultCounsel.sol";
import { ISuperVaultCounsel } from "../../../src/interfaces/SuperVault/ISuperVaultCounsel.sol";
import { SuperVaultExecutor } from "../../../src/SuperVault/SuperVaultExecutor.sol";
import { ISuperVaultExecutor } from "../../../src/interfaces/SuperVault/ISuperVaultExecutor.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";

/// @title SuperVaultCounselForkTest
/// @notice Fork tests against real Base mainnet SuperVault contracts
/// @dev Uses the production Aggregator and flagship USDC strategy. The Counsel's guardian
///      registry is a freshly deployed REAL SuperGovernor (actual AccessControl machinery) so
///      guardian grant/revoke semantics are exercised for real, while manager checks run against
///      the production aggregator. Enrollment is performed by pranking the production
///      SuperGovernor contract address on aggregator.changePrimaryManager — the exact call the
///      real takeover path makes.
contract SuperVaultCounselForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                        PRODUCTION ADDRESSES (BASE)
    //////////////////////////////////////////////////////////////*/

    address constant PROD_SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address constant MAIN_MANAGER = 0xb3dCDaA89B0A43bcC59a9BDEEb5583EC2071066c;
    address constant USDC_STRATEGY = 0x5bE8c059A8E101d24B107aFb5A013feF505280b9;
    address constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    uint256 constant VETO_WINDOW = 3 days;
    uint256 constant EXPIRY = 7 days;
    uint256 constant MIN_DEV = 1e15; // 0.1%
    uint256 constant MAX_DEV = 99e16; // 99%

    /*//////////////////////////////////////////////////////////////
                            TEST STATE
    //////////////////////////////////////////////////////////////*/

    SuperVaultCounsel public counsel;
    SuperGovernor public counselGovernor; // real SuperGovernor instance driving isGuardian
    SuperVaultExecutor public executor;
    ISuperVaultAggregator public aggregator;
    ISuperVaultStrategy public strategy;

    address public govAdmin = makeAddr("govAdmin"); // holds DEFAULT_ADMIN + SUPER_GOVERNOR roles
    address public operator = makeAddr("operator");
    address public guardian = makeAddr("guardian");
    address public sessionKey = makeAddr("sessionKey");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        aggregator = ISuperVaultAggregator(AGGREGATOR);
        strategy = ISuperVaultStrategy(USDC_STRATEGY);

        // Real SuperGovernor with real AccessControl role machinery for the Counsel's guardian gate
        counselGovernor = new SuperGovernor(
            govAdmin, // superGovernor (DEFAULT_ADMIN + SUPER_GOVERNOR roles)
            makeAddr("governor"),
            makeAddr("bankManager"),
            makeAddr("oracleManager"),
            makeAddr("gasManager"),
            guardian,
            makeAddr("treasury"),
            false
        );

        // Real executor wired to the PROD SuperGovernor (resolves the prod aggregator for
        // primary-manager validation)
        executor = new SuperVaultExecutor(PROD_SUPER_GOVERNOR, makeAddr("executorAdmin"), ENTRY_POINT);

        counsel = new SuperVaultCounsel(
            operator,
            address(counselGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            AGGREGATOR,
            USDC_STRATEGY,
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );

        vm.deal(operator, 100 ether);
    }

    /// @dev Enroll the Counsel as primary manager exactly the way the real takeover does:
    ///      the production SuperGovernor contract calls aggregator.changePrimaryManager
    function _enrollCounsel() internal {
        vm.prank(PROD_SUPER_GOVERNOR);
        aggregator.changePrimaryManager(USDC_STRATEGY, address(counsel), operator);
    }

    function _permAll() internal pure returns (ISuperVaultExecutor.Permission[] memory perms) {
        perms = new ISuperVaultExecutor.Permission[](6);
        perms[0] = ISuperVaultExecutor.Permission.ExecuteHooks;
        perms[1] = ISuperVaultExecutor.Permission.FulfillCancelRedeem;
        perms[2] = ISuperVaultExecutor.Permission.FulfillRedeem;
        perms[3] = ISuperVaultExecutor.Permission.SkimFee;
        perms[4] = ISuperVaultExecutor.Permission.Pause;
        perms[5] = ISuperVaultExecutor.Permission.Unpause;
    }

    /*//////////////////////////////////////////////////////////////
                        ENROLLMENT & EXECUTOR GAP
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Enrollment_CounselBecomesMainManager() public {
        assertFalse(aggregator.isMainManager(address(counsel), USDC_STRATEGY));
        _enrollCounsel();
        assertTrue(aggregator.isMainManager(address(counsel), USDC_STRATEGY));
        assertEq(aggregator.getMainManager(USDC_STRATEGY), address(counsel));
    }

    function test_Fork_Enrollment_WipesAllSecondaryManagers() public {
        // production strategy has secondaries before enrollment
        _enrollCounsel();
        assertEq(aggregator.getSecondaryManagers(USDC_STRATEGY).length, 0);
    }

    function test_Fork_EnrollExecutor_RestoresKeeperPath() public {
        _enrollCounsel();
        assertFalse(aggregator.isSecondaryManager(address(executor), USDC_STRATEGY));

        vm.prank(operator);
        counsel.enrollExecutor();
        assertTrue(aggregator.isSecondaryManager(address(executor), USDC_STRATEGY));

        // full keeper round-trip: Counsel (real mainManager) grants a session key on the real
        // executor, whose validity check resolves the prod aggregator's isMainManager live
        vm.prank(operator);
        counsel.grantSessionKey(sessionKey, block.timestamp + 1 days, _permAll());
        assertTrue(executor.isSessionKeyValid(USDC_STRATEGY, sessionKey));
    }

    function test_Fork_EnrollExecutor_OnlyOperator() public {
        _enrollCounsel();
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.enrollExecutor();
    }

    /*//////////////////////////////////////////////////////////////
                    VETO-GATED: DEVIATION THRESHOLD
    //////////////////////////////////////////////////////////////*/

    function test_Fork_DeviationThreshold_EndToEnd() public {
        _enrollCounsel();
        uint256 before = aggregator.getDeviationThreshold(USDC_STRATEGY);
        uint256 target = 4e17; // 40%
        assertTrue(before != target);

        vm.prank(operator);
        uint256 id = counsel.proposeDeviationThreshold(target);

        // cannot execute inside the veto window
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Pending
            )
        );
        counsel.execute(id);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertEq(aggregator.getDeviationThreshold(USDC_STRATEGY), target);
    }

    function test_Fork_DeviationThreshold_VetoBlocksRealChange() public {
        _enrollCounsel();
        uint256 before = aggregator.getDeviationThreshold(USDC_STRATEGY);

        vm.prank(operator);
        uint256 id = counsel.proposeDeviationThreshold(4e17);

        vm.prank(guardian);
        counsel.veto(id);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Vetoed
            )
        );
        counsel.execute(id);
        assertEq(aggregator.getDeviationThreshold(USDC_STRATEGY), before);
    }

    /*//////////////////////////////////////////////////////////////
                    VETO-GATED: STRATEGY ROOT (two-leg)
    //////////////////////////////////////////////////////////////*/

    function test_Fork_StrategyRoot_TwoLeg_EndToEnd() public {
        _enrollCounsel();
        bytes32 newRoot = keccak256("counsel-fork-test-root");
        bytes32 manifestHash = keccak256("published-manifest");

        // Leg 1: Counsel-internal proposal + 3-day guardian window
        vm.prank(operator);
        uint256 id = counsel.proposeStrategyRoot(newRoot, manifestHash);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id); // pushes aggregator.proposeStrategyHooksRoot

        (bytes32 pendingRoot, uint256 effectiveTime) = aggregator.getProposedStrategyHooksRoot(USDC_STRATEGY);
        assertEq(pendingRoot, newRoot);
        assertTrue(effectiveTime > block.timestamp);

        // Leg 2: the aggregator's own (15-min) timelock, then permissionless execute via forward
        vm.warp(effectiveTime);
        vm.prank(operator);
        counsel.executeStrategyHooksRootUpdate();
        assertEq(aggregator.getStrategyHooksRoot(USDC_STRATEGY), newRoot);
    }

    /*//////////////////////////////////////////////////////////////
                VETO-GATED: YIELD SOURCE REMOVE → RE-ADD
    //////////////////////////////////////////////////////////////*/

    function test_Fork_YieldSource_RemoveThenReAdd_EndToEnd() public {
        _enrollCounsel();

        // pick a real yield source + its real oracle from the production strategy
        ISuperVaultStrategy.YieldSourceInfo[] memory sources = strategy.getYieldSourcesList();
        assertTrue(sources.length > 0);
        address source = sources[0].sourceAddress;
        address oracle = sources[0].oracle;
        uint256 countBefore = strategy.getYieldSourcesCount();

        // immediate removal (Remove enum hard-coded in the adapter)
        vm.prank(operator);
        counsel.removeYieldSource(source);
        assertEq(strategy.getYieldSourcesCount(), countBefore - 1);

        // re-add only via the full propose → window → execute flow
        vm.prank(operator);
        uint256 id = counsel.proposeYieldSourceAdd(source, oracle);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);

        assertEq(strategy.getYieldSourcesCount(), countBefore);
        assertEq(strategy.getYieldSource(source).oracle, oracle);
    }

    function test_Fork_YieldSourceAdd_GuardianVetoPreventsAdd() public {
        _enrollCounsel();
        ISuperVaultStrategy.YieldSourceInfo[] memory sources = strategy.getYieldSourcesList();
        address source = sources[0].sourceAddress;
        address oracle = sources[0].oracle;

        vm.prank(operator);
        counsel.removeYieldSource(source);

        vm.prank(operator);
        uint256 id = counsel.proposeYieldSourceAdd(source, oracle);
        vm.prank(guardian);
        counsel.veto(id);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        vm.expectRevert();
        counsel.execute(id);
        assertEq(strategy.getYieldSource(source).oracle, address(0)); // still removed
    }

    /*//////////////////////////////////////////////////////////////
                REAL GUARDIAN ROLE MACHINERY (grant/revoke)
    //////////////////////////////////////////////////////////////*/

    function test_Fork_GuardianRotation_RealAccessControl() public {
        _enrollCounsel();
        vm.prank(operator);
        uint256 id = counsel.proposeDeviationThreshold(4e17);

        // revoke the guardian role on the REAL SuperGovernor mid-window
        bytes32 guardianRole = counselGovernor.GUARDIAN_ROLE();
        vm.prank(govAdmin);
        counselGovernor.revokeRole(guardianRole, guardian);
        assertFalse(counsel.canVeto(guardian));
        vm.prank(guardian);
        vm.expectRevert(ISuperVaultCounsel.NOT_GUARDIAN.selector);
        counsel.veto(id);

        // grant a NEW guardian mid-window — can veto the in-flight proposal immediately
        address newGuardian = makeAddr("newGuardian");
        vm.prank(govAdmin);
        counselGovernor.grantRole(guardianRole, newGuardian);
        assertTrue(counsel.canVeto(newGuardian));
        vm.prank(newGuardian);
        counsel.veto(id);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Vetoed));
    }

    /*//////////////////////////////////////////////////////////////
                    HOSTILE SECONDARY DEFENSE
    //////////////////////////////////////////////////////////////*/

    function test_Fork_CancelChangePrimaryManager_Defense() public {
        _enrollCounsel();
        vm.prank(operator);
        counsel.enrollExecutor(); // executor becomes a secondary manager

        // simulate a hostile secondary proposing the Counsel's replacement
        vm.prank(address(executor));
        aggregator.proposeChangePrimaryManager(USDC_STRATEGY, attacker, attacker);
        (address proposedManager,) = aggregator.getPendingManagerChange(USDC_STRATEGY);
        assertEq(proposedManager, attacker);

        // the Counsel defends its seat
        vm.prank(operator);
        counsel.cancelChangePrimaryManager();
        (proposedManager,) = aggregator.getPendingManagerChange(USDC_STRATEGY);
        assertEq(proposedManager, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE / UNPAUSE FORWARDS
    //////////////////////////////////////////////////////////////*/

    function test_Fork_PauseUnpause_RealAggregator() public {
        _enrollCounsel();
        vm.prank(operator);
        counsel.pauseStrategy();
        vm.prank(operator);
        counsel.unpauseStrategy();
        // non-operator cannot reach the forwards even though it would pass aggregator checks
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.pauseStrategy();
    }

    /*//////////////////////////////////////////////////////////////
                    TAKEOVER / EXIT / SESSION-KEY REVIVAL
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Takeover_ReplacesCounsel_ForwardsGoDead() public {
        _enrollCounsel();
        vm.prank(operator);
        uint256 id = counsel.proposeDeviationThreshold(4e17);

        // SuperGovernor takes the seat back mid-window
        vm.prank(PROD_SUPER_GOVERNOR);
        aggregator.changePrimaryManager(USDC_STRATEGY, MAIN_MANAGER, MAIN_MANAGER);
        assertFalse(aggregator.isMainManager(address(counsel), USDC_STRATEGY));

        // orphaned proposal: Counsel-side state still advances to Ready, but execution reverts
        // downstream at the aggregator's manager check — harmless by unreachability
        vm.warp(block.timestamp + VETO_WINDOW);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Ready));
        vm.prank(operator);
        vm.expectRevert();
        counsel.execute(id);

        // day-to-day forwards also go dead downstream
        vm.prank(operator);
        vm.expectRevert();
        counsel.pauseStrategy();
    }

    function test_Fork_SessionKeys_DieOnTakeover_ReviveOnReinstatement() public {
        _enrollCounsel();
        vm.startPrank(operator);
        counsel.enrollExecutor();
        counsel.grantSessionKey(sessionKey, block.timestamp + 30 days, _permAll());
        vm.stopPrank();
        assertTrue(executor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // takeover: keys granted by the Counsel die instantly (grantedByManager != mainManager)
        vm.prank(PROD_SUPER_GOVERNOR);
        aggregator.changePrimaryManager(USDC_STRATEGY, MAIN_MANAGER, MAIN_MANAGER);
        assertFalse(executor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // reinstatement: the SAME keys silently revive — the documented hazard
        _enrollCounsel();
        assertTrue(executor.isSessionKeyValid(USDC_STRATEGY, sessionKey));

        // runbook mitigation: guardian (or operator) invalidates all keys via generation bump
        vm.prank(guardian);
        counsel.invalidateAllSessionKeys();
        assertFalse(executor.isSessionKeyValid(USDC_STRATEGY, sessionKey));
    }

    /*//////////////////////////////////////////////////////////////
        GLOBAL LEAVES / MIN INTERVAL / SECONDARY ADD (veto-gated)
    //////////////////////////////////////////////////////////////*/

    event GlobalLeavesStatusChanged(address indexed strategy, bytes32[] leaves, bool[] statuses);

    function test_Fork_GlobalLeavesStatus_EndToEnd() public {
        _enrollCounsel();
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256("counsel-fork-leaf-a");
        leaves[1] = keccak256("counsel-fork-leaf-b");
        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.prank(operator);
        uint256 id = counsel.proposeGlobalLeavesStatus(leaves, statuses);
        vm.warp(block.timestamp + VETO_WINDOW);

        // the real aggregator emits its event with the exact stored arrays
        vm.expectEmit(true, false, false, true, AGGREGATOR);
        emit GlobalLeavesStatusChanged(USDC_STRATEGY, leaves, statuses);
        vm.prank(operator);
        counsel.execute(id);
    }

    function test_Fork_MinUpdateInterval_TwoLeg_EndToEnd() public {
        _enrollCounsel();
        uint256 maxStaleness = aggregator.getMaxStaleness(USDC_STRATEGY);
        uint256 target = maxStaleness / 2;
        assertTrue(target != aggregator.getMinUpdateInterval(USDC_STRATEGY));

        // Leg 1: Counsel veto window, then forward the aggregator's own propose
        vm.prank(operator);
        uint256 id = counsel.proposeMinUpdateInterval(target);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);

        // Leg 2: the aggregator's real 3-day parameter timelock, then the convenience forward
        vm.warp(block.timestamp + 3 days);
        vm.prank(operator);
        counsel.executeMinUpdateIntervalChange();
        assertEq(aggregator.getMinUpdateInterval(USDC_STRATEGY), target);
    }

    function test_Fork_MinUpdateInterval_DefensiveCancel() public {
        _enrollCounsel();
        uint256 target = aggregator.getMaxStaleness(USDC_STRATEGY) / 2;
        vm.prank(operator);
        uint256 id = counsel.proposeMinUpdateInterval(target);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);

        vm.prank(operator);
        counsel.cancelMinUpdateIntervalChange();
        vm.warp(block.timestamp + 3 days);
        vm.prank(operator);
        vm.expectRevert();
        counsel.executeMinUpdateIntervalChange(); // pending change was cancelled
    }

    function test_Fork_SecondaryManagerAdd_EndToEnd_WithRetraction() public {
        _enrollCounsel();
        address manager = makeAddr("humanSecondary");

        vm.prank(operator);
        uint256 id = counsel.proposeSecondaryManagerAdd(manager);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertTrue(aggregator.isSecondaryManager(manager, USDC_STRATEGY));

        // the standing defenses against the 7-day bypass remain intact:
        // the hostile secondary proposes replacement, the Counsel cancels and removes it
        vm.prank(manager);
        aggregator.proposeChangePrimaryManager(USDC_STRATEGY, attacker, attacker);
        vm.startPrank(operator);
        counsel.cancelChangePrimaryManager();
        counsel.removeSecondaryManager(manager);
        vm.stopPrank();
        assertFalse(aggregator.isSecondaryManager(manager, USDC_STRATEGY));
        assertTrue(aggregator.isMainManager(address(counsel), USDC_STRATEGY));
    }

    /*//////////////////////////////////////////////////////////////
                COUNSEL MIGRATION (propose-and-accept)
    //////////////////////////////////////////////////////////////*/

    function _deploySuccessorCounsel(address successorOperator) internal returns (SuperVaultCounsel successor) {
        successor = new SuperVaultCounsel(
            successorOperator,
            address(counselGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            AGGREGATOR,
            USDC_STRATEGY,
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
    }

    function test_Fork_CounselMigration_ProposeAcceptEndToEnd() public {
        _enrollCounsel();
        address operator2 = makeAddr("operator2");
        SuperVaultCounsel successor = _deploySuccessorCounsel(operator2);

        // Offer: veto-gated on the old Counsel; execute seats the successor as SECONDARY only
        vm.prank(operator);
        uint256 id = counsel.proposeCounselMigration(address(successor));
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertTrue(aggregator.isSecondaryManager(address(successor), USDC_STRATEGY));
        assertTrue(aggregator.isMainManager(address(counsel), USDC_STRATEGY)); // seat unchanged

        // Accept: only the offered contract can claim (aggregator's secondary-only gate)
        vm.prank(operator2);
        successor.acceptCounselSeat(operator2);
        (address proposedManager, uint256 effectiveTime) = aggregator.getPendingManagerChange(USDC_STRATEGY);
        assertEq(proposedManager, address(successor));

        // Real 7-day aggregator timelock, then permissionless completion
        vm.warp(effectiveTime);
        aggregator.executeChangePrimaryManager(USDC_STRATEGY);

        assertTrue(aggregator.isMainManager(address(successor), USDC_STRATEGY));
        assertFalse(aggregator.isMainManager(address(counsel), USDC_STRATEGY));
        assertEq(aggregator.getSecondaryManagers(USDC_STRATEGY).length, 0); // wiped as usual

        // successor runs the enrollment runbook and is fully operational
        vm.startPrank(operator2);
        successor.enrollExecutor();
        successor.invalidateAllSessionKeys();
        successor.pauseStrategy();
        successor.unpauseStrategy();
        vm.stopPrank();

        // the old Counsel's forwards are dead downstream
        vm.prank(operator);
        vm.expectRevert();
        counsel.pauseStrategy();
    }

    function test_Fork_CounselMigration_UnacceptedOfferMovesNothing() public {
        _enrollCounsel();
        SuperVaultCounsel successor = _deploySuccessorCounsel(makeAddr("operator2"));

        vm.prank(operator);
        uint256 id = counsel.proposeCounselMigration(address(successor));
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);

        // without acceptance, nothing changes no matter how long passes
        vm.warp(block.timestamp + 30 days);
        assertTrue(aggregator.isMainManager(address(counsel), USDC_STRATEGY));
        vm.expectRevert();
        aggregator.executeChangePrimaryManager(USDC_STRATEGY); // no pending change exists
    }

    function test_Fork_CounselMigration_RetractionBeforeAcceptance() public {
        _enrollCounsel();
        SuperVaultCounsel successor = _deploySuccessorCounsel(makeAddr("operator2"));

        vm.prank(operator);
        uint256 id = counsel.proposeCounselMigration(address(successor));
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);

        // old operator retracts the offer before the successor accepts
        vm.prank(operator);
        counsel.removeSecondaryManager(address(successor));
        assertFalse(aggregator.isSecondaryManager(address(successor), USDC_STRATEGY));

        // acceptance is now structurally impossible (not a secondary)
        vm.prank(makeAddr("operator2"));
        vm.expectRevert();
        successor.acceptCounselSeat(makeAddr("operator2"));
    }

    function test_Fork_CounselMigration_CancelDuringAggregatorTimelock() public {
        _enrollCounsel();
        address operator2 = makeAddr("operator2");
        SuperVaultCounsel successor = _deploySuccessorCounsel(operator2);

        vm.prank(operator);
        uint256 id = counsel.proposeCounselMigration(address(successor));
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        vm.prank(operator2);
        successor.acceptCounselSeat(operator2);

        // old operator aborts during the 7-day aggregator timelock
        vm.prank(operator);
        counsel.cancelChangePrimaryManager();
        (address proposedManager,) = aggregator.getPendingManagerChange(USDC_STRATEGY);
        assertEq(proposedManager, address(0));

        vm.warp(block.timestamp + 8 days);
        vm.expectRevert();
        aggregator.executeChangePrimaryManager(USDC_STRATEGY);
        assertTrue(aggregator.isMainManager(address(counsel), USDC_STRATEGY));
    }

    function test_Fork_CounselMigration_GuardianVetoBlocksOffer() public {
        _enrollCounsel();
        SuperVaultCounsel successor = _deploySuccessorCounsel(makeAddr("operator2"));

        vm.prank(operator);
        uint256 id = counsel.proposeCounselMigration(address(successor));
        vm.prank(guardian);
        counsel.veto(id);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        vm.expectRevert();
        counsel.execute(id);
        assertFalse(aggregator.isSecondaryManager(address(successor), USDC_STRATEGY));
    }

    /*//////////////////////////////////////////////////////////////
                    CLOSED SURFACES (fork sanity)
    //////////////////////////////////////////////////////////////*/

    function test_Fork_CounselCannotBeReplacedViaSevenDayPath_WithoutSecondary() public {
        _enrollCounsel();
        // no secondary managers exist and the Counsel exposes no addSecondaryManager beyond the
        // hard-coded executor — a fresh attacker cannot start the 7-day replacement path
        vm.prank(attacker);
        vm.expectRevert();
        aggregator.proposeChangePrimaryManager(USDC_STRATEGY, attacker, attacker);
    }

    function test_Fork_DirectAggregatorCalls_RevertForNonManager() public {
        _enrollCounsel();
        // the Counsel holds the seat: neither operator nor attacker can bypass it and call the
        // aggregator's manager-gated functions directly
        vm.prank(operator);
        vm.expectRevert();
        aggregator.updateDeviationThreshold(USDC_STRATEGY, 4e17);
        vm.prank(attacker);
        vm.expectRevert();
        aggregator.updateDeviationThreshold(USDC_STRATEGY, 4e17);
    }
}
