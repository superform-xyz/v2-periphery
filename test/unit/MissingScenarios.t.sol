// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../src/interfaces/SuperVault/ISuperVault.sol";
import { IECDSAPPSOracle } from "../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { ECDSAPPSOracle } from "../../src/oracles/ECDSAPPSOracle.sol";
import { Bank } from "../../src/Bank.sol";
import { SuperBank } from "../../src/SuperBank.sol";
import { ISuperBank } from "../../src/interfaces/ISuperBank.sol";
import { IHookExecutionData } from "../../src/interfaces/IHookExecutionData.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";
import { MockSuperHook } from "../mocks/MockSuperHook.sol";
import { MockHookTarget } from "../mocks/MockHookTarget.sol";

import "forge-std/console2.sol";

/// @title MissingScenariosTest
/// @notice Tests for scenarios identified as missing in the test coverage analysis
/// @dev Covers: Batch Processing, Payment Independence, inspect() Failure, Unregistered Hooks,
///      Context Isolation, Atomic Execution, and High Volatility scenarios
contract MissingScenariosTest is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    SuperBank internal superBank;
    ECDSAPPSOracle internal ecdsaPPSOracle;
    MockERC20 internal asset;

    // Roles & Addresses
    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal oracleManager;
    address internal user;
    address internal manager;
    address internal superOracle;
    address internal upToken;

    /// @notice Sets up the test environment before each test case
    function setUp() public {
        // Deploy accounts
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        oracleManager = _deployAccount(0x4, "OracleManager");
        user = _deployAccount(0x5, "User");
        manager = _deployAccount(0x6, "Manager");
        superOracle = address(new MockSuperOracle(1e18));

        // Deploy contracts
        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, oracleManager, governor, treasury);

        // Deploy implementation contracts
        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        // Deploy ECDSAPPSOracle
        ecdsaPPSOracle = new ECDSAPPSOracle(address(superGovernor), "ECDSAPPSOracle", "1");

        // Deploy SuperBank
        superBank = new SuperBank(address(superGovernor));

        // Register dependencies on SuperGovernor
        upToken = address(new MockUp(address(this)));
        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), address(superBank));
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(superVaultAggregator));
        vm.stopPrank();

        // Create a vault and strategy for testing
        vm.prank(manager);
        (address vaultAddress, address strategyAddress,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault",
                symbol: "TV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: manager
                })
            })
        );

        vault = SuperVault(vaultAddress);
        strategy = SuperVaultStrategy(payable(strategyAddress));
    }

    /*//////////////////////////////////////////////////////////////
                    1. BATCH PROCESSING TESTS
                    (Graceful Degradation - Return vs Revert)
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests batch forwardPPS continues processing after encountering an unknown strategy
    /// @dev Verifies graceful degradation: batch continues even if one strategy is invalid
    function test_BatchForwardPPS_ContinuesAfterUnknownStrategy() public {
        // Create a second valid strategy
        vm.prank(manager);
        (, address strategy2Address,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault 2",
                symbol: "TV2",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: manager
                })
            })
        );

        // Set ecdsaPPSOracle as active (use sGovernor which has SUPER_GOVERNOR_ROLE)
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(ecdsaPPSOracle));

        // Setup batch with one invalid strategy in the middle
        address[] memory strategies = new address[](3);
        strategies[0] = address(strategy);
        strategies[1] = address(0xDEAD); // Invalid/unknown strategy
        strategies[2] = strategy2Address;

        uint256[] memory ppss = new uint256[](3);
        ppss[0] = 1.1e18;
        ppss[1] = 1.1e18;
        ppss[2] = 1.1e18;

        uint256[] memory timestamps = new uint256[](3);
        timestamps[0] = block.timestamp;
        timestamps[1] = block.timestamp;
        timestamps[2] = block.timestamp;

        // Execute batch as PPS oracle - should emit UnknownStrategy but continue
        vm.prank(address(ecdsaPPSOracle));
        vm.expectEmit(true, false, false, false);
        emit ISuperVaultAggregator.UnknownStrategy(address(0xDEAD));
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: manager
            })
        );

        // Verify valid strategies were updated (or at least processed without revert)
        // The batch completed without reverting
    }

    /// @notice Tests batch forwardPPS continues processing after encountering a paused strategy
    /// @dev Verifies graceful degradation: batch continues even if one strategy is paused
    function test_BatchForwardPPS_ContinuesAfterPausedStrategy() public {
        // Create a second valid strategy
        vm.prank(manager);
        (, address strategy2Address,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault 2",
                symbol: "TV2",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: manager
                })
            })
        );

        // Set ecdsaPPSOracle as active
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(ecdsaPPSOracle));

        // Pause the first strategy
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Setup batch with paused strategy first
        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy); // Paused
        strategies[1] = strategy2Address; // Active

        uint256[] memory ppss = new uint256[](2);
        ppss[0] = 1.1e18;
        ppss[1] = 1.1e18;

        uint256[] memory timestamps = new uint256[](2);
        timestamps[0] = block.timestamp;
        timestamps[1] = block.timestamp;

        // Execute batch - should emit PPSUpdateRejectedStrategyPaused but continue
        vm.prank(address(ecdsaPPSOracle));
        vm.expectEmit(true, false, false, false);
        emit ISuperVaultAggregator.PPSUpdateRejectedStrategyPaused(address(strategy));
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: manager
            })
        );
    }

    /// @notice Tests batch forwardPPS continues after stale timestamp
    /// @dev Verifies graceful degradation: batch continues even if one update is stale
    function test_BatchForwardPPS_ContinuesAfterStaleTimestamp() public {
        // Create a second valid strategy
        vm.prank(manager);
        (, address strategy2Address,) = superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Test Vault 2",
                symbol: "TV2",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: manager
                })
            })
        );

        // Set ecdsaPPSOracle as active
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(ecdsaPPSOracle));

        // Warp to a reasonable time to avoid underflow
        vm.warp(1000);
        uint256 currentTime = block.timestamp;

        // Setup batch with stale timestamp for first strategy
        address[] memory strategies = new address[](2);
        strategies[0] = address(strategy);
        strategies[1] = strategy2Address;

        uint256[] memory ppss = new uint256[](2);
        ppss[0] = 1.1e18;
        ppss[1] = 1.1e18;

        uint256[] memory timestamps = new uint256[](2);
        timestamps[0] = currentTime - 400; // Stale (maxStaleness is 300)
        timestamps[1] = currentTime; // Fresh

        // Execute batch - should emit StaleUpdate but continue
        vm.prank(address(ecdsaPPSOracle));
        vm.expectEmit(true, true, false, false);
        emit ISuperVaultAggregator.StaleUpdate(address(strategy), manager, timestamps[0]);
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: manager
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                    2. PAYMENT INDEPENDENCE TESTS
                    (Pause Works Regardless of Upkeep Balance)
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that pause check works with zero upkeep balance
    /// @dev Verifies pause is enforced regardless of upkeep payment status
    function test_PauseEnforced_WithZeroUpkeepBalance() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Verify strategy has zero upkeep balance
        uint256 upkeepBalance = superVaultAggregator.getUpkeepBalance(address(strategy));
        assertEq(upkeepBalance, 0, "Strategy should have zero upkeep balance");

        // Pause the strategy (manager can always pause)
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Verify paused
        assertTrue(superVaultAggregator.isStrategyPaused(address(strategy)), "Strategy should be paused");

        // Try to deposit - should fail with STRATEGY_PAUSED regardless of upkeep balance
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        vault.deposit(1000e18, testUser);
    }

    /// @notice Tests that pause check works with non-zero upkeep balance
    /// @dev Verifies pause is enforced even when strategy has plenty of upkeep
    function test_PauseEnforced_WithNonZeroUpkeepBalance() public {
        address testUser = _deployAccount(0xABC, "TestUser");

        // Setup: Give user assets and approval
        deal(address(asset), testUser, 10000e18);

        vm.startPrank(testUser);
        asset.approve(address(vault), 10000e18);
        vm.stopPrank();

        // Deposit upkeep for the strategy (using UP token)
        uint256 upkeepAmount = 1000e18;
        MockUp(upToken).mint(manager, upkeepAmount);
        vm.startPrank(manager);
        MockUp(upToken).approve(address(superVaultAggregator), upkeepAmount);
        superVaultAggregator.depositUpkeep(address(strategy), upkeepAmount);
        vm.stopPrank();

        // Verify strategy has upkeep balance
        uint256 upkeepBalance = superVaultAggregator.getUpkeepBalance(address(strategy));
        assertEq(upkeepBalance, upkeepAmount, "Strategy should have upkeep balance");

        // Pause the strategy
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        // Try to deposit - should still fail with STRATEGY_PAUSED
        vm.prank(testUser);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        vault.deposit(1000e18, testUser);
    }

    /*//////////////////////////////////////////////////////////////
                    3. INSPECT() FAILURE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests hook rejection when inspect() reverts
    /// @dev Covers the catch branch in _validateHookConfiguration when inspect() throws
    function test_HookRejected_WhenInspectReverts() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create a hook that reverts in inspect()
        MockHookInspectReverts mockHook = new MockHookInspectReverts();

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Try to execute - should fail due to inspect() reverting
        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: data,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        // Mock a valid Merkle root
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(bytes32(uint256(1)))
        );

        // Should revert with HOOK_VALIDATION_FAILED due to inspect() reverting
        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
    }

    /// @notice Tests hook rejection when hook doesn't implement ISuperHookInspector
    /// @dev Covers the catch branch when interface is missing entirely
    function test_HookRejected_WhenNoInspectMethod() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create a hook that doesn't implement inspect()
        MockHookNoInspectMethod mockHook = new MockHookNoInspectMethod();

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Try to execute
        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: data,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        // Mock a valid Merkle root
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(bytes32(uint256(1)))
        );

        // Should revert with HOOK_VALIDATION_FAILED due to missing inspect()
        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
    }

    /*//////////////////////////////////////////////////////////////
                    4. UNREGISTERED HOOKS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that unregistered hooks are rejected
    /// @dev Verifies HOOK_NOT_REGISTERED error when hook not in SuperGovernor
    function test_HookRejected_WhenNotRegistered() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create a hook but DON'T register it
        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook unregisteredHook = new MockSuperHook(address(mockTarget));

        // Verify hook is not registered
        assertFalse(superGovernor.isHookRegistered(address(unregisteredHook)), "Hook should not be registered");

        // Try to execute with unregistered hook
        address[] memory hooks = new address[](1);
        hooks[0] = address(unregisteredHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: data,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        // Should revert with HOOK_NOT_REGISTERED
        vm.expectRevert(Bank.HOOK_NOT_REGISTERED.selector);
        superBank.executeHooks(executionData);
    }

    /*//////////////////////////////////////////////////////////////
                    5. CONTEXT ISOLATION TESTS
                    (prevHook Parameter)
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that hooks receive correct prevHook parameter via preExecute events
    /// @dev Verifies context isolation: first hook gets address(0), subsequent hooks get previous hook address
    /// Note: This test verifies the hook framework passes prevHook correctly by checking emitted events
    function test_HookReceivesCorrectPrevHook() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create two hooks that emit their prevHook in preExecute
        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook hook1 = new MockSuperHook(address(mockTarget));
        MockSuperHook hook2 = new MockSuperHook(address(mockTarget));

        // Register both hooks
        vm.startPrank(governor);
        superGovernor.registerHook(address(hook1));
        superGovernor.registerHook(address(hook2));
        vm.stopPrank();

        // Create Merkle roots for hooks
        bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encode(address(hook1), abi.encodePacked(mockTarget)))));
        bytes32 leaf2 = keccak256(bytes.concat(keccak256(abi.encode(address(hook2), abi.encodePacked(mockTarget)))));

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(hook1)),
            abi.encode(leaf1)
        );
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(hook2)),
            abi.encode(leaf2)
        );

        // Execute two hooks in sequence
        address[] memory hooks = new address[](2);
        hooks[0] = address(hook1);
        hooks[1] = address(hook2);

        bytes[] memory data = new bytes[](2);
        data[0] = "data1";
        data[1] = "data2";

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0);
        merkleProofs[1] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 0;
        expectedOutputs[1] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: data,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        // Expect PreExecuteCalled events with correct prevHook values
        // First hook should receive prevHook = address(0)
        vm.expectEmit(true, true, false, false);
        emit MockSuperHook.PreExecuteCalled(address(0), address(superBank), "data1");

        // Second hook should receive prevHook = address(hook1)
        vm.expectEmit(true, true, false, false);
        emit MockSuperHook.PreExecuteCalled(address(hook1), address(superBank), "data2");

        // Execute - this will emit PreExecuteCalled events
        superBank.executeHooks(executionData);
    }

    /*//////////////////////////////////////////////////////////////
                    6. ATOMIC EXECUTION TESTS
                    (Hook Sequence Revert Behavior)
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that a failure in any hook reverts the entire sequence
    /// @dev Verifies atomic execution: if hook fails with build() error, entire sequence reverts
    function test_HookSequence_RevertsAtomically() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create two hooks: first succeeds, second has build() that fails
        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook successHook = new MockSuperHook(address(mockTarget));
        MockSuperHook failHook = new MockSuperHook(address(mockTarget));

        // Set failHook to fail during build
        failHook.setShouldFailBuild(true);

        // Register both hooks
        vm.startPrank(governor);
        superGovernor.registerHook(address(successHook));
        superGovernor.registerHook(address(failHook));
        vm.stopPrank();

        // Create Merkle roots
        bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encode(address(successHook), abi.encodePacked(mockTarget)))));
        bytes32 leaf2 = keccak256(bytes.concat(keccak256(abi.encode(address(failHook), abi.encodePacked(mockTarget)))));

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(successHook)),
            abi.encode(leaf1)
        );
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(failHook)),
            abi.encode(leaf2)
        );

        // Execute sequence where second hook fails during build
        address[] memory hooks = new address[](2);
        hooks[0] = address(successHook);
        hooks[1] = address(failHook);

        bytes[] memory data = new bytes[](2);
        data[0] = "data1";
        data[1] = "data2";

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0);
        merkleProofs[1] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 0;
        expectedOutputs[1] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: data,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        // Should revert - second hook's build() fails
        vm.expectRevert("MockSuperHook: build failed");
        superBank.executeHooks(executionData);
    }

    /*//////////////////////////////////////////////////////////////
                    7. HIGH VOLATILITY / RAPID PPS CHANGE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests behavior under rapid PPS changes with deviation threshold
    /// @dev Verifies slippage protection when PPS changes rapidly
    function test_RapidPPSChanges_DeviationThresholdEnforced() public {
        // Set ecdsaPPSOracle as active
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(ecdsaPPSOracle));

        // Set a tight deviation threshold (5% = 500 bps)
        vm.prank(manager);
        superVaultAggregator.updateDeviationThreshold(address(strategy), 500);

        uint256 initialPPS = superVaultAggregator.getPPS(address(strategy));

        // Wait for minUpdateInterval
        vm.warp(block.timestamp + 10);

        // Try to push a PPS that exceeds the deviation threshold (20% increase)
        uint256 highPPS = (initialPPS * 120) / 100;

        address[] memory strategies = new address[](1);
        strategies[0] = address(strategy);

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = highPPS;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        // Execute - should emit event for deviation check and potentially pause strategy
        vm.prank(address(ecdsaPPSOracle));
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: manager
            })
        );

        // Check if strategy was paused due to deviation
        bool isPaused = superVaultAggregator.isStrategyPaused(address(strategy));
        // If deviation threshold is exceeded, strategy should be paused
        assertTrue(isPaused, "Strategy should be paused after exceeding deviation threshold");
    }

    /// @notice Tests that multiple rapid PPS updates within minUpdateInterval are rejected
    /// @dev Verifies rate limiting on PPS updates
    function test_RapidPPSUpdates_MinIntervalEnforced() public {
        // Set ecdsaPPSOracle as active
        vm.prank(sGovernor);
        superGovernor.setActivePPSOracle(address(ecdsaPPSOracle));

        // Disable deviation threshold to isolate minUpdateInterval test
        vm.prank(manager);
        superVaultAggregator.updateDeviationThreshold(address(strategy), type(uint256).max);

        // Warp to a time after deployment (deployment was at timestamp 1)
        vm.warp(100);

        // First update should succeed
        address[] memory strategies = new address[](1);
        strategies[0] = address(strategy);

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = 1.01e18;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        vm.prank(address(ecdsaPPSOracle));
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: manager
            })
        );

        // Record PPS after first update
        uint256 ppsAfterFirst = superVaultAggregator.getPPS(address(strategy));
        assertEq(ppsAfterFirst, 1.01e18, "First update should have succeeded");

        // Advance time by 2 seconds (within minUpdateInterval of 5 seconds)
        vm.warp(block.timestamp + 2);

        // Try second update with new timestamp
        ppss[0] = 1.02e18;
        timestamps[0] = block.timestamp;

        // Second update should be skipped due to minUpdateInterval (2 < 5 seconds)
        vm.prank(address(ecdsaPPSOracle));
        vm.expectEmit(false, false, false, false);
        emit ISuperVaultAggregator.UpdateTooFrequent();
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: manager
            })
        );

        // Verify PPS unchanged
        uint256 ppsAfterSecond = superVaultAggregator.getPPS(address(strategy));
        assertEq(ppsAfterSecond, ppsAfterFirst, "PPS should be unchanged after too-soon update");
    }
}

/*//////////////////////////////////////////////////////////////
                    MOCK CONTRACTS FOR TESTS
//////////////////////////////////////////////////////////////*/

/// @notice Mock hook that reverts in inspect() method
contract MockHookInspectReverts {
    function inspect(bytes memory) external pure returns (bytes memory) {
        revert("Inspect intentionally failed");
    }
}

/// @notice Mock hook that doesn't implement ISuperHookInspector interface at all
contract MockHookNoInspectMethod {
    // No inspect() method - doesn't implement ISuperHookInspector
    function someOtherMethod() external pure returns (uint256) {
        return 42;
    }
}
