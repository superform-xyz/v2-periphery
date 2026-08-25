// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { SuperVaultCounsel } from "../../src/SuperVault/SuperVaultCounsel.sol";
import { ISuperVaultCounsel } from "../../src/interfaces/SuperVault/ISuperVaultCounsel.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultExecutor } from "../../src/interfaces/SuperVault/ISuperVaultExecutor.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/*//////////////////////////////////////////////////////////////
                            MOCKS
//////////////////////////////////////////////////////////////*/

contract MockCounselSuperGovernor {
    mapping(address => bool) public guardians;

    function setGuardian(address who, bool status) external {
        guardians[who] = status;
    }

    function isGuardian(address who) external view returns (bool) {
        return guardians[who];
    }
}

/// @dev Records the last call per target function so tests can assert exact forwarding
contract MockCounselStrategy {
    address public lastSource;
    address public lastOracle;
    ISuperVaultStrategy.YieldSourceAction public lastAction;
    uint256 public manageYieldSourceCalls;
    uint256 public lastMsgValue;
    uint256 public hooksLen;
    bool public skimCalled;
    uint256 public feePerf;
    uint256 public feeMgmt;
    address public feeRecipient;
    bool public feeExecuted;
    ISuperVaultStrategy.PPSExpirationAction public lastPPSAction;
    uint256 public lastPPSValue;
    address[] public lastControllers;

    function manageYieldSource(address source, address oracle, ISuperVaultStrategy.YieldSourceAction action) external {
        lastSource = source;
        lastOracle = oracle;
        lastAction = action;
        ++manageYieldSourceCalls;
    }

    function executeHooks(ISuperVaultStrategy.ExecuteArgs calldata args) external payable {
        lastMsgValue = msg.value;
        hooksLen = args.hooks.length;
    }

    function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata) external {
        lastControllers = controllers;
    }

    function fulfillCancelRedeemRequests(address[] calldata controllers) external {
        lastControllers = controllers;
    }

    function skimPerformanceFee() external {
        skimCalled = true;
    }

    function proposeVaultFeeConfigUpdate(uint256 perfBps, uint256 mgmtBps, address recipient) external {
        feePerf = perfBps;
        feeMgmt = mgmtBps;
        feeRecipient = recipient;
    }

    function executeVaultFeeConfigUpdate() external {
        feeExecuted = true;
    }

    function managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction action, uint256 value) external {
        lastPPSAction = action;
        lastPPSValue = value;
    }
}

contract MockCounselAggregator {
    address public lastStrategy;
    bytes32 public lastRoot;
    uint256 public lastThreshold;
    bool public paused;
    bool public rootExecuted;
    bool public upkeepProposed;
    bool public upkeepExecuted;
    address public lastSecondaryAdded;
    address public lastSecondaryRemoved;
    bool public managerChangeCancelled;

    function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) external {
        lastStrategy = strategy;
        lastRoot = newRoot;
    }

    function updateDeviationThreshold(address strategy, uint256 threshold) external {
        lastStrategy = strategy;
        lastThreshold = threshold;
    }

    function pauseStrategy(address) external {
        paused = true;
    }

    function unpauseStrategy(address) external {
        paused = false;
    }

    function executeStrategyHooksRootUpdate(address) external {
        rootExecuted = true;
    }

    function proposeWithdrawUpkeep(address) external {
        upkeepProposed = true;
    }

    function executeWithdrawUpkeep(address) external {
        upkeepExecuted = true;
    }

    function addSecondaryManager(address, address manager) external {
        lastSecondaryAdded = manager;
    }

    function removeSecondaryManager(address, address manager) external {
        lastSecondaryRemoved = manager;
    }

    function cancelChangePrimaryManager(address) external {
        managerChangeCancelled = true;
    }

    address public proposedPrimaryManager;
    address public proposedFeeRecipient;

    function proposeChangePrimaryManager(address strategy, address newManager, address feeRecipient) external {
        lastStrategy = strategy;
        proposedPrimaryManager = newManager;
        proposedFeeRecipient = feeRecipient;
    }

    bytes32[] public lastLeaves;
    bool[] public lastStatuses;
    uint256 public lastMinUpdateInterval;
    bool public minIntervalExecuted;
    bool public minIntervalCancelled;

    function changeGlobalLeavesStatus(bytes32[] memory leaves, bool[] memory statuses, address strategy) external {
        lastStrategy = strategy;
        lastLeaves = leaves;
        lastStatuses = statuses;
    }

    function proposeMinUpdateIntervalChange(address strategy, uint256 newMinUpdateInterval) external {
        lastStrategy = strategy;
        lastMinUpdateInterval = newMinUpdateInterval;
    }

    function executeMinUpdateIntervalChange(address) external {
        minIntervalExecuted = true;
    }

    function cancelMinUpdateIntervalChange(address) external {
        minIntervalCancelled = true;
    }

    function lastLeavesLength() external view returns (uint256) {
        return lastLeaves.length;
    }
}

contract MockCounselExecutor {
    address public lastStrategy;
    address public lastSessionKey;
    uint256 public lastExpiry;
    uint256 public batchLen;
    address public lastRevoked;
    uint256 public generation;

    function grantSessionKey(
        address strategy,
        address sessionKey,
        uint256 expiry,
        ISuperVaultExecutor.Permission[] calldata
    )
        external
    {
        lastStrategy = strategy;
        lastSessionKey = sessionKey;
        lastExpiry = expiry;
    }

    function grantSessionKeysBatch(
        address[] calldata strategies,
        address[] calldata sessionKeys,
        uint256[] calldata,
        ISuperVaultExecutor.Permission[][] calldata
    )
        external
    {
        batchLen = sessionKeys.length;
        lastStrategy = strategies[0];
    }

    function revokeSessionKey(address strategy, address sessionKey) external {
        lastStrategy = strategy;
        lastRevoked = sessionKey;
    }

    function revokeSessionKeysBatch(address[] calldata strategies, address[] calldata sessionKeys) external {
        batchLen = sessionKeys.length;
        lastStrategy = strategies[0];
    }

    function invalidateAllSessionKeys(address strategy) external {
        lastStrategy = strategy;
        ++generation;
    }
}

/// @dev ERC20 that takes a 10% fee on transfer (sweep must tolerate)
contract MockCounselFeeOnTransferToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += (amount * 90) / 100;
        return true;
    }
}

/// @dev Forces ETH into the Counsel via selfdestruct
contract ForceFeeder {
    constructor() payable { }

    function feed(address target) external {
        selfdestruct(payable(target));
    }
}

/// @dev Token whose transfer re-enters the Counsel's sweep functions
contract ReentrantToken {
    SuperVaultCounsel public counsel;
    mapping(address => uint256) public balanceOf;
    bool public attackNative;

    function setCounsel(SuperVaultCounsel counsel_, bool attackNative_) external {
        counsel = counsel_;
        attackNative = attackNative_;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        if (attackNative) counsel.sweepNative();
        else counsel.sweepERC20(address(this));
        return true;
    }
}

/// @dev Strategy whose executeHooks re-enters the Counsel's payable relay
contract ReentrantStrategy {
    SuperVaultCounsel public counsel;

    function setCounsel(SuperVaultCounsel counsel_) external {
        counsel = counsel_;
    }

    function executeHooks(ISuperVaultStrategy.ExecuteArgs calldata args) external payable {
        counsel.executeHooks(args); // must be blocked by nonReentrant
    }
}

/// @dev SuperGovernor whose isGuardian always reverts (dead-registry scenario)
contract RevertingSuperGovernor {
    function isGuardian(address) external pure returns (bool) {
        revert("REGISTRY_DEAD");
    }
}

/*//////////////////////////////////////////////////////////////
                            TESTS
//////////////////////////////////////////////////////////////*/

contract SuperVaultCounselTest is Test {
    uint256 internal constant VETO_WINDOW = 3 days;
    uint256 internal constant EXPIRY = 7 days;
    uint256 internal constant MIN_DEV = 1e16; // 1%
    uint256 internal constant MAX_DEV = 9e17; // 90%

    SuperVaultCounsel internal counsel;
    MockCounselSuperGovernor internal superGovernor;
    MockCounselStrategy internal strategy;
    MockCounselAggregator internal aggregator;
    MockCounselExecutor internal executor;

    address internal operator = makeAddr("operator");
    address internal guardian = makeAddr("guardian");
    address internal guardian2 = makeAddr("guardian2");
    address internal attacker = makeAddr("attacker");

    function setUp() public {
        superGovernor = new MockCounselSuperGovernor();
        strategy = new MockCounselStrategy();
        aggregator = new MockCounselAggregator();
        executor = new MockCounselExecutor();
        superGovernor.setGuardian(guardian, true);

        counsel = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        vm.deal(operator, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function test_constructor_setsImmutables() public view {
        assertEq(counsel.OPERATOR(), operator);
        assertEq(address(counsel.SUPER_GOVERNOR()), address(superGovernor));
        assertEq(address(counsel.AGGREGATOR()), address(aggregator));
        assertEq(address(counsel.STRATEGY()), address(strategy));
        assertEq(address(counsel.EXECUTOR()), address(executor));
        assertEq(counsel.VETO_WINDOW(), VETO_WINDOW);
        assertEq(counsel.EXPIRY(), EXPIRY);
        assertEq(counsel.MIN_DEVIATION_THRESHOLD(), MIN_DEV);
        assertEq(counsel.MAX_DEVIATION_THRESHOLD(), MAX_DEV);
    }

    function test_constructor_revertsOnZeroAddresses() public {
        vm.expectRevert(ISuperVaultCounsel.ZERO_ADDRESS.selector);
        new SuperVaultCounsel(
            address(0),
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
    }

    function test_constructor_revertsOnBadTiming() public {
        // zero window
        vm.expectRevert(ISuperVaultCounsel.INVALID_CONFIG.selector);
        new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            0,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        // expiry <= window
        vm.expectRevert(ISuperVaultCounsel.INVALID_CONFIG.selector);
        new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            VETO_WINDOW,
            MIN_DEV,
            MAX_DEV
        );
    }

    function test_constructor_revertsOnBadBounds() public {
        // max < min
        vm.expectRevert(ISuperVaultCounsel.INVALID_CONFIG.selector);
        new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MAX_DEV,
            MIN_DEV
        );
        // max == type(uint256).max would disable PPS checks
        vm.expectRevert(ISuperVaultCounsel.INVALID_CONFIG.selector);
        new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            type(uint256).max
        );
    }

    /*//////////////////////////////////////////////////////////////
                        PROPOSAL LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    function _proposeAdd() internal returns (uint256 id) {
        vm.prank(operator);
        id = counsel.proposeYieldSourceAdd(makeAddr("source"), makeAddr("oracle"));
    }

    function test_propose_onlyOperator() public {
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.proposeYieldSourceAdd(makeAddr("source"), makeAddr("oracle"));
    }

    function test_propose_idsMonotonic() public {
        uint256 id0 = _proposeAdd();
        uint256 id1 = _proposeAdd();
        assertEq(id0, 0);
        assertEq(id1, 1);
        assertEq(counsel.nextProposalId(), 2);
    }

    function test_propose_storesExactArgs() public {
        vm.prank(operator);
        uint256 id = counsel.proposeStrategyRoot(bytes32(uint256(1)), bytes32(uint256(2)));
        ISuperVaultCounsel.Proposal memory p = counsel.getProposal(id);
        assertEq(uint8(p.actionType), uint8(ISuperVaultCounsel.ActionType.StrategyRoot));
        assertEq(p.root, bytes32(uint256(1)));
        assertEq(p.manifestHash, bytes32(uint256(2)));
        assertEq(p.proposedAt, block.timestamp);
    }

    function test_propose_validatesInputs() public {
        vm.startPrank(operator);
        vm.expectRevert(ISuperVaultCounsel.ZERO_ADDRESS.selector);
        counsel.proposeYieldSourceAdd(address(0), makeAddr("oracle"));
        vm.expectRevert(ISuperVaultCounsel.INVALID_ROOT.selector);
        counsel.proposeStrategyRoot(bytes32(0), bytes32(uint256(2)));
        vm.expectRevert(ISuperVaultCounsel.INVALID_ROOT.selector);
        counsel.proposeStrategyRoot(bytes32(uint256(1)), bytes32(0));
        vm.stopPrank();
    }

    function test_proposeDeviationThreshold_bounds() public {
        vm.startPrank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(ISuperVaultCounsel.THRESHOLD_OUT_OF_BOUNDS.selector, MIN_DEV - 1, MIN_DEV, MAX_DEV)
        );
        counsel.proposeDeviationThreshold(MIN_DEV - 1);
        vm.expectRevert(
            abi.encodeWithSelector(ISuperVaultCounsel.THRESHOLD_OUT_OF_BOUNDS.selector, MAX_DEV + 1, MIN_DEV, MAX_DEV)
        );
        counsel.proposeDeviationThreshold(MAX_DEV + 1);
        // boundaries themselves are valid
        counsel.proposeDeviationThreshold(MIN_DEV);
        counsel.proposeDeviationThreshold(MAX_DEV);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        STATE DERIVATION & BOUNDARIES
    //////////////////////////////////////////////////////////////*/

    function test_state_lifecycle() public {
        uint256 id = _proposeAdd();
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Pending));

        // one second before the window ends: still Pending
        vm.warp(block.timestamp + VETO_WINDOW - 1);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Pending));

        // exactly at proposedAt + VETO_WINDOW: Ready (inclusive lower bound)
        vm.warp(block.timestamp + 1);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Ready));
    }

    function test_state_expiryBoundary() public {
        uint256 proposedAt = block.timestamp;
        uint256 id = _proposeAdd();

        // one second before expiry: Ready
        vm.warp(proposedAt + EXPIRY - 1);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Ready));

        // exactly at proposedAt + EXPIRY: Expired (exclusive upper bound)
        vm.warp(proposedAt + EXPIRY);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Expired));
    }

    function test_state_unknownIdIsNone() public view {
        assertEq(uint8(counsel.state(999)), uint8(ISuperVaultCounsel.ProposalStatus.None));
    }

    /*//////////////////////////////////////////////////////////////
                                EXECUTE
    //////////////////////////////////////////////////////////////*/

    function test_execute_revertsBeforeWindow() public {
        uint256 id = _proposeAdd();
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Pending
            )
        );
        counsel.execute(id);
    }

    function test_execute_revertsAfterExpiry() public {
        uint256 proposedAt = block.timestamp;
        uint256 id = _proposeAdd();
        vm.warp(proposedAt + EXPIRY);
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Expired
            )
        );
        counsel.execute(id);
    }

    function test_execute_onlyOperator() public {
        uint256 id = _proposeAdd();
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.execute(id);
        // even a guardian cannot execute
        vm.prank(guardian);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.execute(id);
    }

    function test_execute_yieldSourceAdd_forwardsExactStoredArgs() public {
        address source = makeAddr("source");
        address oracle = makeAddr("oracle");
        vm.prank(operator);
        uint256 id = counsel.proposeYieldSourceAdd(source, oracle);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertEq(strategy.lastSource(), source);
        assertEq(strategy.lastOracle(), oracle);
        assertEq(uint8(strategy.lastAction()), uint8(ISuperVaultStrategy.YieldSourceAction.Add));
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Executed));
    }

    function test_execute_strategyRoot_forwardsToAggregatorPropose() public {
        vm.prank(operator);
        uint256 id = counsel.proposeStrategyRoot(bytes32(uint256(0xabc)), bytes32(uint256(0xdef)));
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertEq(aggregator.lastStrategy(), address(strategy));
        assertEq(aggregator.lastRoot(), bytes32(uint256(0xabc)));
    }

    function test_execute_deviationThreshold_forwards() public {
        vm.prank(operator);
        uint256 id = counsel.proposeDeviationThreshold(5e17);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertEq(aggregator.lastThreshold(), 5e17);
    }

    function test_execute_cannotReplay() public {
        uint256 id = _proposeAdd();
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.startPrank(operator);
        counsel.execute(id);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Executed
            )
        );
        counsel.execute(id);
        vm.stopPrank();
        assertEq(strategy.manageYieldSourceCalls(), 1);
    }

    /*//////////////////////////////////////////////////////////////
                                VETO
    //////////////////////////////////////////////////////////////*/

    function test_veto_onlyLiveGuardian() public {
        uint256 id = _proposeAdd();
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_GUARDIAN.selector);
        counsel.veto(id);
        // operator is not a guardian either
        vm.prank(operator);
        vm.expectRevert(ISuperVaultCounsel.NOT_GUARDIAN.selector);
        counsel.veto(id);
    }

    function test_veto_duringWindow() public {
        uint256 id = _proposeAdd();
        vm.prank(guardian);
        counsel.veto(id);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Vetoed));
    }

    function test_veto_validUntilExecution_evenWhenReady() public {
        uint256 id = _proposeAdd();
        vm.warp(block.timestamp + VETO_WINDOW + 1 days); // proposal is Ready
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Ready));
        vm.prank(guardian);
        counsel.veto(id);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Vetoed));
        // and the vetoed proposal can never execute
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Vetoed
            )
        );
        counsel.execute(id);
    }

    function test_veto_terminal_cannotReVeto() public {
        uint256 id = _proposeAdd();
        vm.prank(guardian);
        counsel.veto(id);
        vm.prank(guardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_VETOABLE.selector, id, ISuperVaultCounsel.ProposalStatus.Vetoed
            )
        );
        counsel.veto(id);
    }

    function test_veto_revertsOnExecutedOrExpired() public {
        uint256 proposedAt = block.timestamp;
        uint256 id = _proposeAdd();
        vm.warp(proposedAt + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        vm.prank(guardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_VETOABLE.selector, id, ISuperVaultCounsel.ProposalStatus.Executed
            )
        );
        counsel.veto(id);

        uint256 id2 = _proposeAdd();
        vm.warp(block.timestamp + EXPIRY);
        vm.prank(guardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_VETOABLE.selector, id2, ISuperVaultCounsel.ProposalStatus.Expired
            )
        );
        counsel.veto(id2);
    }

    function test_veto_guardianRotationMidWindow() public {
        uint256 id = _proposeAdd();
        // guardian revoked mid-window loses veto power immediately
        superGovernor.setGuardian(guardian, false);
        vm.prank(guardian);
        vm.expectRevert(ISuperVaultCounsel.NOT_GUARDIAN.selector);
        counsel.veto(id);
        // guardian added mid-window can veto immediately
        superGovernor.setGuardian(guardian2, true);
        vm.prank(guardian2);
        counsel.veto(id);
        assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Vetoed));
    }

    function test_sameBlock_vetoThenExecute_vetoWins() public {
        uint256 id = _proposeAdd();
        vm.warp(block.timestamp + VETO_WINDOW); // Ready
        vm.prank(guardian);
        counsel.veto(id);
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Vetoed
            )
        );
        counsel.execute(id);
    }

    function test_sameBlock_executeThenVeto_executeWins() public {
        uint256 id = _proposeAdd();
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        vm.prank(guardian);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_VETOABLE.selector, id, ISuperVaultCounsel.ProposalStatus.Executed
            )
        );
        counsel.veto(id);
    }

    function test_expiredContent_reproposableUnderFreshId() public {
        uint256 proposedAt = block.timestamp;
        address source = makeAddr("source");
        address oracle = makeAddr("oracle");
        vm.prank(operator);
        uint256 id = counsel.proposeYieldSourceAdd(source, oracle);
        vm.warp(proposedAt + EXPIRY);
        // re-propose identical content: fresh id, fresh full window
        vm.prank(operator);
        uint256 id2 = counsel.proposeYieldSourceAdd(source, oracle);
        assertEq(id2, id + 1);
        assertEq(uint8(counsel.state(id2)), uint8(ISuperVaultCounsel.ProposalStatus.Pending));
        vm.prank(operator);
        vm.expectRevert(); // old id stays expired
        counsel.execute(id);
    }

    /*//////////////////////////////////////////////////////////////
                        DAY-TO-DAY FORWARDS
    //////////////////////////////////////////////////////////////*/

    function test_forwards_authMatrix() public {
        // every operator forward reverts for attacker and guardian alike
        address[2] memory badCallers = [attacker, guardian];
        for (uint256 i; i < 2; ++i) {
            vm.startPrank(badCallers[i]);
            vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
            counsel.skimPerformanceFee();
            vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
            counsel.pauseStrategy();
            vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
            counsel.removeYieldSource(makeAddr("source"));
            vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
            counsel.enrollExecutor();
            vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
            counsel.grantSessionKey(makeAddr("key"), block.timestamp + 1 days, new ISuperVaultExecutor.Permission[](0));
            vm.stopPrank();
        }
    }

    function test_executeHooks_relaysExactMsgValue() public {
        ISuperVaultStrategy.ExecuteArgs memory args;
        // seed the counsel with resident dust that must NOT be forwarded
        vm.deal(address(counsel), 5 ether);
        vm.prank(operator);
        counsel.executeHooks{ value: 1 ether }(args);
        assertEq(strategy.lastMsgValue(), 1 ether);
        assertEq(address(counsel).balance, 5 ether); // dust untouched
    }

    function test_removeYieldSource_removeEnumHardcoded() public {
        vm.prank(operator);
        counsel.removeYieldSource(makeAddr("source"));
        assertEq(uint8(strategy.lastAction()), uint8(ISuperVaultStrategy.YieldSourceAction.Remove));
    }

    function test_enrollExecutor_hardcodedTarget() public {
        vm.prank(operator);
        counsel.enrollExecutor();
        assertEq(aggregator.lastSecondaryAdded(), address(executor));
    }

    function test_aggregatorForwards() public {
        vm.startPrank(operator);
        counsel.pauseStrategy();
        assertTrue(aggregator.paused());
        counsel.unpauseStrategy();
        assertFalse(aggregator.paused());
        counsel.executeStrategyHooksRootUpdate();
        assertTrue(aggregator.rootExecuted());
        counsel.proposeWithdrawUpkeep();
        assertTrue(aggregator.upkeepProposed());
        counsel.executeWithdrawUpkeep();
        assertTrue(aggregator.upkeepExecuted());
        counsel.removeSecondaryManager(makeAddr("mgr"));
        assertEq(aggregator.lastSecondaryRemoved(), makeAddr("mgr"));
        counsel.cancelChangePrimaryManager();
        assertTrue(aggregator.managerChangeCancelled());
        vm.stopPrank();
    }

    /// @notice Redemption-fulfillment forwards relay to the strategy (previously uncovered)
    function test_fulfillForwards() public {
        address[] memory controllers = new address[](2);
        controllers[0] = makeAddr("c1");
        controllers[1] = makeAddr("c2");
        uint256[] memory assetsOut = new uint256[](2);

        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.fulfillRedeemRequests(controllers, assetsOut);
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.fulfillCancelRedeemRequests(controllers);

        vm.startPrank(operator);
        counsel.fulfillRedeemRequests(controllers, assetsOut);
        assertEq(strategy.lastControllers(0), controllers[0]);
        assertEq(strategy.lastControllers(1), controllers[1]);
        counsel.fulfillCancelRedeemRequests(controllers);
        assertEq(strategy.lastControllers(1), controllers[1]);
        vm.stopPrank();
    }

    /// @notice The zero-oracle disjunct of proposeYieldSourceAdd (zero-source already covered)
    function test_proposeYieldSourceAdd_zeroOracleRejected() public {
        vm.prank(operator);
        vm.expectRevert(ISuperVaultCounsel.ZERO_ADDRESS.selector);
        counsel.proposeYieldSourceAdd(makeAddr("source"), address(0));
    }

    function test_strategyForwards() public {
        vm.startPrank(operator);
        counsel.skimPerformanceFee();
        assertTrue(strategy.skimCalled());
        counsel.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Propose, 1 hours);
        assertEq(uint8(strategy.lastPPSAction()), uint8(ISuperVaultStrategy.PPSExpirationAction.Propose));
        assertEq(strategy.lastPPSValue(), 1 hours);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    FEE CONFIG (VETO-GATED, P1)
    //////////////////////////////////////////////////////////////*/

    /// @notice Fee config no longer forwards immediately: it is a veto-gated proposal whose
    ///         execute pushes the strategy's own 1-week fee timelock (second leg)
    function test_feeConfig_isVetoGated_twoLeg() public {
        vm.prank(operator);
        uint256 id = counsel.proposeVaultFeeConfigUpdate(1000, 50, makeAddr("recipient"));

        // NOT forwarded at propose time
        assertEq(strategy.feePerf(), 0);
        assertEq(strategy.feeRecipient(), address(0));

        ISuperVaultCounsel.Proposal memory p = counsel.getProposal(id);
        assertEq(uint8(p.actionType), uint8(ISuperVaultCounsel.ActionType.FeeConfig));
        assertEq(p.performanceFeeBps, 1000);
        assertEq(p.managementFeeBps, 50);
        assertEq(p.feeRecipient, makeAddr("recipient"));

        // Execute after the window -> pushes the strategy's own fee proposal (leg 1 -> leg 2)
        vm.warp(block.timestamp + VETO_WINDOW + 1);
        vm.prank(operator);
        counsel.execute(id);
        assertEq(strategy.feePerf(), 1000);
        assertEq(strategy.feeMgmt(), 50);
        assertEq(strategy.feeRecipient(), makeAddr("recipient"));

        // Second-leg forward unchanged
        vm.prank(operator);
        counsel.executeVaultFeeConfigUpdate();
        assertTrue(strategy.feeExecuted());
    }

    /// @notice A guardian can veto a fee-config proposal before execution
    function test_feeConfig_guardianCanVeto() public {
        vm.prank(operator);
        uint256 id = counsel.proposeVaultFeeConfigUpdate(5100, 10_000, makeAddr("rug"));

        vm.prank(guardian);
        counsel.veto(id);

        vm.warp(block.timestamp + VETO_WINDOW + 1);
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISuperVaultCounsel.PROPOSAL_NOT_READY.selector, id, ISuperVaultCounsel.ProposalStatus.Vetoed
            )
        );
        counsel.execute(id);
        assertEq(strategy.feePerf(), 0);
    }

    /// @notice Propose-time bounds mirror the strategy caps; zero recipient rejected
    function test_feeConfig_boundsValidation() public {
        vm.startPrank(operator);
        vm.expectRevert(abi.encodeWithSelector(ISuperVaultCounsel.INVALID_FEE_CONFIG.selector, 5101, 0));
        counsel.proposeVaultFeeConfigUpdate(5101, 0, makeAddr("recipient"));

        vm.expectRevert(abi.encodeWithSelector(ISuperVaultCounsel.INVALID_FEE_CONFIG.selector, 0, 10_001));
        counsel.proposeVaultFeeConfigUpdate(0, 10_001, makeAddr("recipient"));

        vm.expectRevert(abi.encodeWithSelector(ISuperVaultCounsel.INVALID_FEE_CONFIG.selector, 100, 100));
        counsel.proposeVaultFeeConfigUpdate(100, 100, address(0));

        // exact caps accepted
        counsel.proposeVaultFeeConfigUpdate(5100, 10_000, makeAddr("recipient"));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        VETO REGISTRY (P7)
    //////////////////////////////////////////////////////////////*/

    /// @notice address(0) registry defaults to the SuperGovernor (backwards-compatible)
    function test_vetoRegistry_zeroDefaultsToSuperGovernor() public view {
        assertEq(address(counsel.VETO_REGISTRY()), address(superGovernor));
        assertTrue(counsel.canVeto(guardian));
    }

    /// @notice FeeConfig propose is operator-only like every other proposal
    function test_feeConfig_proposeOnlyOperator() public {
        address[2] memory badCallers = [attacker, guardian];
        for (uint256 i; i < 2; ++i) {
            vm.prank(badCallers[i]);
            vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
            counsel.proposeVaultFeeConfigUpdate(100, 100, makeAddr("recipient"));
        }
    }

    /// @notice The custom registry also gates the guardian path of invalidateAllSessionKeys
    function test_vetoRegistry_gatesInvalidateAllSessionKeys() public {
        MockCounselSuperGovernor registry = new MockCounselSuperGovernor();
        SuperVaultCounsel c = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(registry),
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        // governor guardian is NOT authorized on this instance
        vm.prank(guardian);
        vm.expectRevert(ISuperVaultCounsel.NOT_AUTHORIZED.selector);
        c.invalidateAllSessionKeys();

        // registry guardian is; operator always is
        address newtonVetoer = makeAddr("newtonVetoer");
        registry.setGuardian(newtonVetoer, true);
        vm.prank(newtonVetoer);
        c.invalidateAllSessionKeys();
        assertEq(executor.generation(), 1);
        vm.prank(operator);
        c.invalidateAllSessionKeys();
        assertEq(executor.generation(), 2);
    }

    /// @notice A custom registry fully replaces the governor for veto authority
    function test_vetoRegistry_customRegistryDrivesVetoAuth() public {
        MockCounselSuperGovernor registry = new MockCounselSuperGovernor();
        SuperVaultCounsel c = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(registry),
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        assertEq(address(c.VETO_REGISTRY()), address(registry));
        // governor guardian has NO veto power on this instance
        assertFalse(c.canVeto(guardian));

        address newtonVetoer = makeAddr("newtonVetoer");
        registry.setGuardian(newtonVetoer, true);
        assertTrue(c.canVeto(newtonVetoer));

        vm.prank(operator);
        uint256 id = c.proposeDeviationThreshold(MIN_DEV);
        vm.prank(guardian);
        vm.expectRevert(ISuperVaultCounsel.NOT_GUARDIAN.selector);
        c.veto(id);
        vm.prank(newtonVetoer);
        c.veto(id);
        assertEq(uint8(c.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Vetoed));
    }

    /*//////////////////////////////////////////////////////////////
                            SESSION KEYS
    //////////////////////////////////////////////////////////////*/

    function test_sessionKeys_forwardWithImmutableStrategy() public {
        vm.startPrank(operator);
        counsel.grantSessionKey(makeAddr("key"), block.timestamp + 1 days, new ISuperVaultExecutor.Permission[](0));
        assertEq(executor.lastStrategy(), address(strategy));
        assertEq(executor.lastSessionKey(), makeAddr("key"));

        address[] memory keys = new address[](2);
        keys[0] = makeAddr("k1");
        keys[1] = makeAddr("k2");
        uint256[] memory expiries = new uint256[](2);
        expiries[0] = block.timestamp + 1 days;
        expiries[1] = block.timestamp + 2 days;
        ISuperVaultExecutor.Permission[][] memory perms = new ISuperVaultExecutor.Permission[][](2);
        counsel.grantSessionKeysBatch(keys, expiries, perms);
        assertEq(executor.batchLen(), 2);

        counsel.revokeSessionKey(makeAddr("k1"));
        assertEq(executor.lastRevoked(), makeAddr("k1"));

        counsel.revokeSessionKeysBatch(keys);
        assertEq(executor.batchLen(), 2);
        vm.stopPrank();
    }

    function test_invalidateAllSessionKeys_operatorOrGuardian() public {
        vm.prank(operator);
        counsel.invalidateAllSessionKeys();
        assertEq(executor.generation(), 1);

        vm.prank(guardian);
        counsel.invalidateAllSessionKeys();
        assertEq(executor.generation(), 2);

        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_AUTHORIZED.selector);
        counsel.invalidateAllSessionKeys();
    }

    /*//////////////////////////////////////////////////////////////
                                SWEEPS
    //////////////////////////////////////////////////////////////*/

    function test_sweepERC20_permissionless_toOperatorOnly() public {
        MockERC20 token = new MockERC20("T", "T", 18);
        token.mint(address(counsel), 100e18);
        vm.prank(attacker); // anyone can trigger
        counsel.sweepERC20(address(token));
        assertEq(token.balanceOf(operator), 100e18);
        assertEq(token.balanceOf(address(counsel)), 0);
    }

    function test_sweepERC20_feeOnTransferTolerated() public {
        MockCounselFeeOnTransferToken fot = new MockCounselFeeOnTransferToken();
        fot.mint(address(counsel), 100e18);
        vm.prank(attacker);
        counsel.sweepERC20(address(fot));
        assertEq(fot.balanceOf(operator), 90e18); // 10% fee taken in transit — sweep must not revert
        assertEq(fot.balanceOf(address(counsel)), 0);
    }

    function test_sweepERC20_revertsOnEOATokenAddress() public {
        vm.expectRevert();
        counsel.sweepERC20(makeAddr("notAToken"));
    }

    function test_sweepNative_permissionless_toOperatorOnly() public {
        vm.deal(address(counsel), 3 ether);
        uint256 before = operator.balance;
        vm.prank(attacker);
        counsel.sweepNative();
        assertEq(operator.balance, before + 3 ether);
        assertEq(address(counsel).balance, 0);
    }

    function test_sweepNative_forcedEtherIsSweepable() public {
        // selfdestruct-forced ETH cannot corrupt anything: no logic is balance-derived
        ForceFeeder feeder = new ForceFeeder{ value: 1 ether }();
        feeder.feed(address(counsel));
        assertEq(address(counsel).balance, 1 ether);
        uint256 before = operator.balance;
        counsel.sweepNative();
        assertEq(operator.balance, before + 1 ether);
    }

    function test_receive_acceptsEth() public {
        vm.prank(operator);
        (bool ok,) = address(counsel).call{ value: 1 ether }("");
        assertTrue(ok);
        assertEq(address(counsel).balance, 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    function test_canVeto_tracksLiveRegistry() public {
        assertTrue(counsel.canVeto(guardian));
        assertFalse(counsel.canVeto(attacker));
        superGovernor.setGuardian(guardian, false);
        assertFalse(counsel.canVeto(guardian));
    }

    /*//////////////////////////////////////////////////////////////
                                FUZZ
    //////////////////////////////////////////////////////////////*/

    function testFuzz_executeWindow(uint256 delta) public {
        delta = bound(delta, 0, EXPIRY + 30 days);
        uint256 proposedAt = block.timestamp;
        uint256 id = _proposeAdd();
        vm.warp(proposedAt + delta);
        bool shouldSucceed = delta >= VETO_WINDOW && delta < EXPIRY;
        vm.prank(operator);
        if (shouldSucceed) {
            counsel.execute(id);
            assertEq(uint8(counsel.state(id)), uint8(ISuperVaultCounsel.ProposalStatus.Executed));
        } else {
            vm.expectRevert();
            counsel.execute(id);
        }
    }

    function testFuzz_vetoAlwaysBeatsExecuteWhilePending(uint256 delta) public {
        delta = bound(delta, 0, EXPIRY - 1);
        uint256 proposedAt = block.timestamp;
        uint256 id = _proposeAdd();
        vm.warp(proposedAt + delta);
        vm.prank(guardian);
        counsel.veto(id); // must succeed at any point before expiry
        vm.prank(operator);
        vm.expectRevert();
        counsel.execute(id);
    }

    function testFuzz_thresholdBounds(uint256 threshold) public {
        vm.prank(operator);
        if (threshold >= MIN_DEV && threshold <= MAX_DEV) {
            counsel.proposeDeviationThreshold(threshold);
        } else {
            vm.expectRevert(
                abi.encodeWithSelector(ISuperVaultCounsel.THRESHOLD_OUT_OF_BOUNDS.selector, threshold, MIN_DEV, MAX_DEV)
            );
            counsel.proposeDeviationThreshold(threshold);
        }
    }

    function testFuzz_stateNeverInvalid_afterArbitraryWarp(uint64 warpTo) public {
        uint256 id = _proposeAdd();
        vm.warp(uint256(warpTo) < block.timestamp ? block.timestamp : uint256(warpTo));
        uint8 s = uint8(counsel.state(id));
        // stored Pending only ever derives to Pending/Ready/Expired
        assertTrue(
            s == uint8(ISuperVaultCounsel.ProposalStatus.Pending) || s == uint8(ISuperVaultCounsel.ProposalStatus.Ready)
                || s == uint8(ISuperVaultCounsel.ProposalStatus.Expired)
        );
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    function test_event_proposalCreated_absoluteDeadlines() public {
        address source = makeAddr("source");
        address oracle = makeAddr("oracle");
        ISuperVaultCounsel.Proposal memory expected;
        expected.proposedAt = uint64(block.timestamp);
        expected.status = ISuperVaultCounsel.ProposalStatus.Pending;
        expected.actionType = ISuperVaultCounsel.ActionType.YieldSourceAdd;
        expected.source = source;
        expected.oracle = oracle;
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultCounsel.ProposalCreated(
            0,
            ISuperVaultCounsel.ActionType.YieldSourceAdd,
            operator,
            expected,
            block.timestamp + VETO_WINDOW,
            block.timestamp + EXPIRY
        );
        vm.prank(operator);
        counsel.proposeYieldSourceAdd(source, oracle);
    }

    function test_event_proposalVetoed_recordsGuardian() public {
        uint256 id = _proposeAdd();
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultCounsel.ProposalVetoed(id, guardian);
        vm.prank(guardian);
        counsel.veto(id);
    }

    function test_event_proposalExecuted() public {
        uint256 id = _proposeAdd();
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultCounsel.ProposalExecuted(id, operator);
        vm.prank(operator);
        counsel.execute(id);
    }

    function test_event_operatorActionExecuted_selector() public {
        vm.expectEmit(true, false, false, false);
        emit ISuperVaultCounsel.OperatorActionExecuted(counsel.skimPerformanceFee.selector);
        vm.prank(operator);
        counsel.skimPerformanceFee();
    }

    function test_event_executorEnrolled() public {
        vm.expectEmit(false, false, false, false);
        emit ISuperVaultCounsel.ExecutorEnrolled();
        vm.prank(operator);
        counsel.enrollExecutor();
    }

    function test_event_allSessionKeysInvalidated_recordsCaller() public {
        vm.expectEmit(true, false, false, false);
        emit ISuperVaultCounsel.AllSessionKeysInvalidated(guardian);
        vm.prank(guardian);
        counsel.invalidateAllSessionKeys();
    }

    function test_event_sweeps() public {
        MockERC20 token = new MockERC20("T", "T", 18);
        token.mint(address(counsel), 7e18);
        vm.expectEmit(true, false, false, true);
        emit ISuperVaultCounsel.ERC20Swept(address(token), 7e18);
        counsel.sweepERC20(address(token));

        vm.deal(address(counsel), 2 ether);
        vm.expectEmit(false, false, false, true);
        emit ISuperVaultCounsel.NativeSwept(2 ether);
        counsel.sweepNative();
    }

    /*//////////////////////////////////////////////////////////////
                            REENTRANCY
    //////////////////////////////////////////////////////////////*/

    function test_reentrancy_sweepERC20_blocked() public {
        ReentrantToken evil = new ReentrantToken();
        evil.setCounsel(counsel, false);
        evil.mint(address(counsel), 1e18);
        // the re-entering transfer reverts inside SafeERC20, bubbling ReentrancyGuard's error
        vm.expectRevert();
        counsel.sweepERC20(address(evil));
    }

    function test_reentrancy_sweepNative_crossFunction_blocked() public {
        ReentrantToken evil = new ReentrantToken();
        evil.setCounsel(counsel, true); // re-enters sweepNative during sweepERC20
        evil.mint(address(counsel), 1e18);
        vm.deal(address(counsel), 1 ether);
        vm.expectRevert();
        counsel.sweepERC20(address(evil));
    }

    function test_reentrancy_executeHooks_blocked() public {
        ReentrantStrategy evilStrategy = new ReentrantStrategy();
        SuperVaultCounsel counsel2 = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(evilStrategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        evilStrategy.setCounsel(counsel2);
        ISuperVaultStrategy.ExecuteArgs memory args;
        vm.prank(operator);
        vm.expectRevert();
        counsel2.executeHooks{ value: 1 ether }(args);
    }

    /*//////////////////////////////////////////////////////////////
                        DEAD REGISTRY SEMANTICS
    //////////////////////////////////////////////////////////////*/

    function test_deadRegistry_vetoRevertsButOperatorFlowLives() public {
        // documents the accepted live-lookup semantics: if isGuardian reverts, the veto path is
        // dead (bubbles the registry revert) while propose/execute continue — this is why
        // guardian-registry health is a first-class off-chain monitoring requirement
        RevertingSuperGovernor deadRegistry = new RevertingSuperGovernor();
        SuperVaultCounsel counsel2 = new SuperVaultCounsel(
            operator,
            address(deadRegistry),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        vm.prank(operator);
        uint256 id = counsel2.proposeYieldSourceAdd(makeAddr("source"), makeAddr("oracle"));

        vm.prank(guardian);
        vm.expectRevert("REGISTRY_DEAD");
        counsel2.veto(id);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel2.execute(id); // operator flow unaffected
    }

    /*//////////////////////////////////////////////////////////////
                    CONCURRENT PROPOSAL INDEPENDENCE
    //////////////////////////////////////////////////////////////*/

    function test_concurrentProposals_fullyIndependent() public {
        vm.startPrank(operator);
        uint256 idAdd = counsel.proposeYieldSourceAdd(makeAddr("source"), makeAddr("oracle"));
        uint256 idRoot = counsel.proposeStrategyRoot(bytes32(uint256(1)), bytes32(uint256(2)));
        uint256 idThreshold = counsel.proposeDeviationThreshold(5e17);
        vm.stopPrank();

        // veto one, execute another, let the third expire
        vm.prank(guardian);
        counsel.veto(idRoot);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(idAdd);

        vm.warp(block.timestamp + EXPIRY);
        assertEq(uint8(counsel.state(idAdd)), uint8(ISuperVaultCounsel.ProposalStatus.Executed));
        assertEq(uint8(counsel.state(idRoot)), uint8(ISuperVaultCounsel.ProposalStatus.Vetoed));
        assertEq(uint8(counsel.state(idThreshold)), uint8(ISuperVaultCounsel.ProposalStatus.Expired));
        // only the executed Add ever reached the strategy
        assertEq(strategy.manageYieldSourceCalls(), 1);
        assertEq(aggregator.lastRoot(), bytes32(0));
        assertEq(aggregator.lastThreshold(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                    COUNSEL MIGRATION (propose-and-accept)
    //////////////////////////////////////////////////////////////*/

    function _deploySuccessor() internal returns (SuperVaultCounsel successor) {
        successor = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
    }

    function test_proposeCounselMigration_validatesTarget() public {
        vm.startPrank(operator);
        // zero address
        vm.expectRevert(ISuperVaultCounsel.INVALID_MIGRATION_TARGET.selector);
        counsel.proposeCounselMigration(address(0));
        // self
        vm.expectRevert(ISuperVaultCounsel.INVALID_MIGRATION_TARGET.selector);
        counsel.proposeCounselMigration(address(counsel));
        // EOA / codeless
        vm.expectRevert(ISuperVaultCounsel.INVALID_MIGRATION_TARGET.selector);
        counsel.proposeCounselMigration(makeAddr("eoa"));
        vm.stopPrank();
    }

    function test_proposeCounselMigration_rejectsMismatchedWiring() public {
        // successor wired to a DIFFERENT strategy
        MockCounselStrategy otherStrategy = new MockCounselStrategy();
        SuperVaultCounsel wrongStrategyCounsel = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(otherStrategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        vm.prank(operator);
        vm.expectRevert(ISuperVaultCounsel.INVALID_MIGRATION_TARGET.selector);
        counsel.proposeCounselMigration(address(wrongStrategyCounsel));

        // successor wired to a DIFFERENT aggregator
        MockCounselAggregator otherAggregator = new MockCounselAggregator();
        SuperVaultCounsel wrongAggregatorCounsel = new SuperVaultCounsel(
            operator,
            address(superGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(otherAggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        vm.prank(operator);
        vm.expectRevert(ISuperVaultCounsel.INVALID_MIGRATION_TARGET.selector);
        counsel.proposeCounselMigration(address(wrongAggregatorCounsel));

        // successor wired to a DIFFERENT SuperGovernor - fake veto machinery (P3 hardening)
        MockCounselSuperGovernor otherGovernor = new MockCounselSuperGovernor();
        SuperVaultCounsel wrongGovernorCounsel = new SuperVaultCounsel(
            operator,
            address(otherGovernor),
            address(0), // vetoRegistry: defaults to superGovernor
            address(aggregator),
            address(strategy),
            address(executor),
            VETO_WINDOW,
            EXPIRY,
            MIN_DEV,
            MAX_DEV
        );
        vm.prank(operator);
        vm.expectRevert(ISuperVaultCounsel.INVALID_MIGRATION_TARGET.selector);
        counsel.proposeCounselMigration(address(wrongGovernorCounsel));
    }

    function test_counselMigration_offerSeatsSuccessorAsSecondaryOnly() public {
        SuperVaultCounsel successor = _deploySuccessor();
        vm.prank(operator);
        uint256 id = counsel.proposeCounselMigration(address(successor));

        ISuperVaultCounsel.Proposal memory p = counsel.getProposal(id);
        assertEq(uint8(p.actionType), uint8(ISuperVaultCounsel.ActionType.CounselMigration));
        assertEq(p.newCounsel, address(successor));

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);

        // the offer only adds a secondary — no primary-manager proposal exists yet
        assertEq(aggregator.lastSecondaryAdded(), address(successor));
        assertEq(aggregator.proposedPrimaryManager(), address(0));
    }

    function test_counselMigration_guardianVetoBlocksOffer() public {
        SuperVaultCounsel successor = _deploySuccessor();
        vm.prank(operator);
        uint256 id = counsel.proposeCounselMigration(address(successor));
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
        assertEq(aggregator.lastSecondaryAdded(), address(0));
    }

    function test_acceptCounselSeat_proposesSelfAsPrimary() public {
        address feeRecipient = makeAddr("feeRecipient");
        vm.expectEmit(true, false, false, false);
        emit ISuperVaultCounsel.CounselSeatAccepted(feeRecipient);
        vm.prank(operator);
        counsel.acceptCounselSeat(feeRecipient);
        assertEq(aggregator.proposedPrimaryManager(), address(counsel)); // always self
        assertEq(aggregator.proposedFeeRecipient(), feeRecipient);
        assertEq(aggregator.lastStrategy(), address(strategy));
    }

    function test_acceptCounselSeat_authAndValidation() public {
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.acceptCounselSeat(makeAddr("feeRecipient"));
        vm.prank(guardian);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.acceptCounselSeat(makeAddr("feeRecipient"));
        vm.prank(operator);
        vm.expectRevert(ISuperVaultCounsel.ZERO_ADDRESS.selector);
        counsel.acceptCounselSeat(address(0));
    }

    /*//////////////////////////////////////////////////////////////
            GLOBAL LEAVES / MIN INTERVAL / SECONDARY ADD (veto-gated)
    //////////////////////////////////////////////////////////////*/

    function test_proposeGlobalLeavesStatus_validation() public {
        bytes32[] memory leaves = new bytes32[](0);
        bool[] memory statuses = new bool[](0);
        vm.startPrank(operator);
        vm.expectRevert(ISuperVaultCounsel.INVALID_LEAVES.selector);
        counsel.proposeGlobalLeavesStatus(leaves, statuses);
        leaves = new bytes32[](2);
        statuses = new bool[](1);
        vm.expectRevert(ISuperVaultCounsel.INVALID_LEAVES.selector);
        counsel.proposeGlobalLeavesStatus(leaves, statuses);
        vm.stopPrank();
    }

    function test_globalLeavesStatus_endToEnd() public {
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256("leaf-a");
        leaves[1] = keccak256("leaf-b");
        bool[] memory statuses = new bool[](2);
        statuses[0] = true; // ban
        statuses[1] = false; // unban

        vm.prank(operator);
        uint256 id = counsel.proposeGlobalLeavesStatus(leaves, statuses);
        ISuperVaultCounsel.Proposal memory p = counsel.getProposal(id);
        assertEq(p.leaves.length, 2);
        assertEq(p.leaves[0], leaves[0]);
        assertEq(p.statuses[0], true);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertEq(aggregator.lastLeavesLength(), 2);
        assertEq(aggregator.lastLeaves(1), leaves[1]);
        assertEq(aggregator.lastStrategy(), address(strategy));
    }

    function test_globalLeavesStatus_vetoBlocks() public {
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = keccak256("leaf");
        bool[] memory statuses = new bool[](1);
        vm.prank(operator);
        uint256 id = counsel.proposeGlobalLeavesStatus(leaves, statuses);
        vm.prank(guardian);
        counsel.veto(id);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        vm.expectRevert();
        counsel.execute(id);
        assertEq(aggregator.lastLeavesLength(), 0);
    }

    function test_minUpdateInterval_twoLeg_endToEnd() public {
        vm.prank(operator);
        uint256 id = counsel.proposeMinUpdateInterval(30 minutes);
        assertEq(counsel.getProposal(id).newMinUpdateInterval, 30 minutes);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id); // leg 1: forwards the aggregator's own propose
        assertEq(aggregator.lastMinUpdateInterval(), 30 minutes);

        // leg 2 convenience forward + defensive cancel
        vm.prank(operator);
        counsel.executeMinUpdateIntervalChange();
        assertTrue(aggregator.minIntervalExecuted());
        vm.prank(operator);
        counsel.cancelMinUpdateIntervalChange();
        assertTrue(aggregator.minIntervalCancelled());

        // both forwards are operator-only
        vm.prank(attacker);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.executeMinUpdateIntervalChange();
        vm.prank(guardian);
        vm.expectRevert(ISuperVaultCounsel.NOT_OPERATOR.selector);
        counsel.cancelMinUpdateIntervalChange();
    }

    function test_secondaryManagerAdd_endToEnd() public {
        address manager = makeAddr("newSecondary");
        vm.prank(operator);
        vm.expectRevert(ISuperVaultCounsel.ZERO_ADDRESS.selector);
        counsel.proposeSecondaryManagerAdd(address(0));

        vm.prank(operator);
        uint256 id = counsel.proposeSecondaryManagerAdd(manager);
        assertEq(counsel.getProposal(id).newSecondaryManager, manager);

        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        counsel.execute(id);
        assertEq(aggregator.lastSecondaryAdded(), manager);
    }

    function test_secondaryManagerAdd_vetoBlocks() public {
        vm.prank(operator);
        uint256 id = counsel.proposeSecondaryManagerAdd(makeAddr("newSecondary"));
        vm.prank(guardian);
        counsel.veto(id);
        vm.warp(block.timestamp + VETO_WINDOW);
        vm.prank(operator);
        vm.expectRevert();
        counsel.execute(id);
        assertEq(aggregator.lastSecondaryAdded(), address(0));
    }

    function test_getProposal_deviationFields() public {
        vm.prank(operator);
        uint256 id = counsel.proposeDeviationThreshold(5e17);
        ISuperVaultCounsel.Proposal memory p = counsel.getProposal(id);
        assertEq(uint8(p.actionType), uint8(ISuperVaultCounsel.ActionType.DeviationThreshold));
        assertEq(p.newThreshold, 5e17);
        assertEq(p.source, address(0));
        assertEq(p.root, bytes32(0));
    }
}
