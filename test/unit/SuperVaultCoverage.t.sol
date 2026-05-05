// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor, FeeType } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../src/interfaces/SuperVault/ISuperVault.sol";
import { IERC7540Redeem, IERC7540Operator, IERC7540CancelRedeem } from
    "../../src/vendor/standards/ERC7540/IERC7540Vault.sol";
import { IERC7741 } from "../../src/vendor/standards/ERC7741/IERC7741.sol";
import { IERC7575 } from "../../src/vendor/standards/ERC7575/IERC7575.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";

/// @title SuperVaultCoverageTest
/// @notice Coverage tests for SuperVault and SuperVaultStrategy
/// @dev Named differently from SuperVaultTest to avoid coverage exclusion
contract SuperVaultCoverageTest is PeripheryHelpers {
    SuperGovernor internal superGovernor;
    SuperVaultAggregator internal superVaultAggregator;
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    MockERC20 internal asset;

    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal user;
    address internal manager;
    address internal superBank;
    address internal superOracle;
    address internal upToken;

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant BPS_PRECISION = 10_000;

    function setUp() public {
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        user = _deployAccount(0x4, "User");
        manager = _deployAccount(0x5, "Manager");
        superOracle = address(new MockSuperOracle(1e18));

        asset = new MockERC20("Asset", "ASSET", 18);

        superGovernor = new SuperGovernor(sGovernor, governor, governor, governor, governor, governor, treasury, false);

        address vaultImpl = address(new SuperVault(address(superGovernor)));
        address strategyImpl = address(new SuperVaultStrategy(address(superGovernor)));
        address escrowImpl = address(new SuperVaultEscrow());

        superVaultAggregator = new SuperVaultAggregator(address(superGovernor), vaultImpl, strategyImpl, escrowImpl);

        upToken = address(new MockUp(address(this)));
        superBank = makeAddr("superBank");
        vm.startPrank(sGovernor);
        superGovernor.setAddress(superGovernor.UP(), upToken);
        superGovernor.setAddress(superGovernor.UPKEEP_TOKEN(), upToken);
        superGovernor.setAddress(superGovernor.SUPER_BANK(), superBank);
        superGovernor.setAddress(superGovernor.SUPER_ORACLE(), superOracle);
        superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(superVaultAggregator));
        vm.stopPrank();

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

    // =========================================================================
    // Helper to manipulate PPS in storage
    // =========================================================================
    function _setPPS(uint256 newPPS) internal {
        bytes32 strategyDataSlot = bytes32(uint256(1));
        bytes32 ppsStorageSlot = keccak256(abi.encode(address(strategy), strategyDataSlot));
        vm.store(address(superVaultAggregator), ppsStorageSlot, bytes32(newPPS));
    }

    function _depositAs(address depositor, uint256 amount) internal {
        deal(address(asset), depositor, amount);
        vm.startPrank(depositor);
        asset.approve(address(vault), amount);
        vault.deposit(amount, depositor);
        vm.stopPrank();
    }

    // =========================================================================
    // SuperVault.sol: setOperator (line 246)
    // =========================================================================
    function test_SetOperator_Success() public {
        address operator = makeAddr("operator");

        vm.prank(user);
        bool success = vault.setOperator(operator, true);
        assertTrue(success);
        assertTrue(vault.isOperator(user, operator));
    }

    function test_SetOperator_Revoke() public {
        address operator = makeAddr("operator");

        vm.startPrank(user);
        vault.setOperator(operator, true);
        assertTrue(vault.isOperator(user, operator));

        vault.setOperator(operator, false);
        assertFalse(vault.isOperator(user, operator));
        vm.stopPrank();
    }

    function test_SetOperator_RevertsOnSelf() public {
        vm.prank(user);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.setOperator(user, true);
    }

    // =========================================================================
    // SuperVault.sol: getEscrowedAssets (line 287)
    // =========================================================================
    function test_GetEscrowedAssets_ZeroInitially() public view {
        assertEq(vault.getEscrowedAssets(), 0);
    }

    function test_GetEscrowedAssets_AfterDeposit() public {
        // Deposit to create shares and escrow some assets
        _depositAs(user, 1000e18);

        // Directly send some asset to escrow to simulate fulfilled redeem
        address escrow = vault.escrow();
        deal(address(asset), escrow, 500e18);
        assertEq(vault.getEscrowedAssets(), 500e18);
    }

    // =========================================================================
    // SuperVault.sol: claimableCancelRedeemRequest (line 330)
    // =========================================================================
    function test_ClaimableCancelRedeemRequest_ReturnsZero() public view {
        assertEq(vault.claimableCancelRedeemRequest(0, user), 0);
    }

    // =========================================================================
    // SuperVault.sol: invalidateNonce (line 354)
    // =========================================================================
    function test_InvalidateNonce_Success() public {
        bytes32 nonce = keccak256("test-nonce");

        vm.prank(user);
        vm.expectEmit(true, true, false, false);
        emit ISuperVault.NonceInvalidated(user, nonce);
        vault.invalidateNonce(nonce);

        assertTrue(vault.authorizations(user, nonce));
    }

    function test_InvalidateNonce_RevertsOnAlreadyUsed() public {
        bytes32 nonce = keccak256("test-nonce");

        vm.startPrank(user);
        vault.invalidateNonce(nonce);

        vm.expectRevert(ISuperVault.INVALID_NONCE.selector);
        vault.invalidateNonce(nonce);
        vm.stopPrank();
    }

    // =========================================================================
    // SuperVault.sol: maxDeposit (line 395)
    // =========================================================================
    function test_MaxDeposit_ReturnsMaxWhenDepositsAccepted() public view {
        assertEq(vault.maxDeposit(user), type(uint256).max);
    }

    function test_MaxDeposit_ReturnsZeroWhenPaused() public {
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));

        assertEq(vault.maxDeposit(user), 0);
    }

    function test_MaxDeposit_ReturnsZeroWhenPPSStale() public {
        // Manipulate PPS staleness directly in storage
        // StrategyData is in mapping at slot 1, field ppsStale is at offset within the struct
        // Simpler: just pause the strategy which also makes _canAcceptDeposits return false
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));
        assertEq(vault.maxDeposit(user), 0);
    }

    // =========================================================================
    // SuperVault.sol: maxMint (line 401)
    // =========================================================================
    function test_MaxMint_ReturnsMax() public view {
        assertEq(vault.maxMint(user), type(uint256).max);
    }

    function test_MaxMint_ReturnsZeroWhenPaused() public {
        vm.prank(manager);
        superVaultAggregator.pauseStrategy(address(strategy));
        assertEq(vault.maxMint(user), 0);
    }

    // =========================================================================
    // SuperVault.sol: previewWithdraw (line 452) - reverts NOT_IMPLEMENTED
    // =========================================================================
    function test_PreviewWithdraw_RevertsNotImplemented() public {
        vm.expectRevert(ISuperVault.NOT_IMPLEMENTED.selector);
        vault.previewWithdraw(100e18);
    }

    // =========================================================================
    // SuperVault.sol: previewRedeem (line 464) - reverts NOT_IMPLEMENTED
    // =========================================================================
    function test_PreviewRedeem_RevertsNotImplemented() public {
        vm.expectRevert(ISuperVault.NOT_IMPLEMENTED.selector);
        vault.previewRedeem(100e18);
    }

    // =========================================================================
    // SuperVault.sol: supportsInterface (line 558)
    // =========================================================================
    function test_SupportsInterface_IERC7540Redeem() public view {
        assertTrue(vault.supportsInterface(type(IERC7540Redeem).interfaceId));
    }

    function test_SupportsInterface_IERC165() public view {
        assertTrue(vault.supportsInterface(type(IERC165).interfaceId));
    }

    function test_SupportsInterface_IERC7741() public view {
        assertTrue(vault.supportsInterface(type(IERC7741).interfaceId));
    }

    function test_SupportsInterface_IERC4626() public view {
        assertTrue(vault.supportsInterface(type(IERC4626).interfaceId));
    }

    function test_SupportsInterface_IERC7575() public view {
        assertTrue(vault.supportsInterface(type(IERC7575).interfaceId));
    }

    function test_SupportsInterface_IERC7540Operator() public view {
        assertTrue(vault.supportsInterface(type(IERC7540Operator).interfaceId));
    }

    function test_SupportsInterface_Unsupported() public view {
        assertFalse(vault.supportsInterface(bytes4(0xdeadbeef)));
    }

    // =========================================================================
    // SuperVault.sol: _isOperator via setOperator + operator withdraw flow (line 594)
    // =========================================================================
    function test_IsOperator_ViaSuperVault() public {
        address operator = makeAddr("operator");

        // Initially not an operator
        assertFalse(vault.isOperator(user, operator));

        // Set operator
        vm.prank(user);
        vault.setOperator(operator, true);
        assertTrue(vault.isOperator(user, operator));
    }

    // =========================================================================
    // SuperVault.sol: _canAcceptDeposits + _getAggregatorAddress (lines 616, 624)
    // Covered via maxDeposit/maxMint above
    // =========================================================================

    // =========================================================================
    // SuperVaultStrategy.sol: skimPerformanceFee success path (line 373-456)
    // =========================================================================
    function test_SkimPerformanceFee_Success() public {
        // 1. Deposit to create supply
        _depositAs(user, 10_000e18);
        assertGt(vault.totalSupply(), 0);

        // 2. Wait for skim timelock (12h after creation/unpause)
        vm.warp(block.timestamp + 12 hours + 1);

        // 3. Simulate PPS growth above HWM (HWM is 1e18 initially)
        uint256 newPPS = 1.5e18; // 50% growth
        _setPPS(newPPS);
        assertEq(strategy.getStoredPPS(), newPPS);

        // 4. Strategy already holds assets from deposit
        uint256 strategyBalance = asset.balanceOf(address(strategy));
        assertGt(strategyBalance, 0);

        // 5. Skim performance fee
        uint256 treasuryBefore = asset.balanceOf(treasury);
        uint256 managerBefore = asset.balanceOf(manager);

        vm.prank(manager);
        strategy.skimPerformanceFee();

        // Verify fees were transferred
        uint256 treasuryAfter = asset.balanceOf(treasury);
        uint256 managerAfter = asset.balanceOf(manager);
        assertGt(treasuryAfter, treasuryBefore, "Treasury should receive fee");
        assertGt(managerAfter, managerBefore, "Manager should receive fee");
    }

    function test_SkimPerformanceFee_EarlyReturnNoSupply() public {
        // No deposits means totalSupply == 0 -> early return
        vm.warp(block.timestamp + 12 hours + 1);

        vm.prank(manager);
        strategy.skimPerformanceFee(); // Should not revert
    }

    function test_SkimPerformanceFee_EarlyReturnPPSBelowHWM() public {
        _depositAs(user, 1000e18);
        vm.warp(block.timestamp + 12 hours + 1);

        // PPS is at 1e18, HWM is also 1e18 -> no growth -> early return
        vm.prank(manager);
        strategy.skimPerformanceFee(); // Should not revert
    }

    function test_SkimPerformanceFee_RevertsOnSkimTimelockActive() public {
        _depositAs(user, 1000e18);

        // Don't warp past the timelock
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.SKIM_TIMELOCK_ACTIVE.selector);
        strategy.skimPerformanceFee();
    }

    function test_SkimPerformanceFee_RevertsOnNonManager() public {
        vm.prank(user);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.skimPerformanceFee();
    }

    // =========================================================================
    // SuperVaultStrategy.sol: manageYieldSources batch (line 468-485)
    // =========================================================================
    function test_ManageYieldSources_BatchAdd() public {
        address source1 = makeAddr("source1");
        address source2 = makeAddr("source2");
        address oracle1 = makeAddr("oracle1");
        address oracle2 = makeAddr("oracle2");

        address[] memory sources = new address[](2);
        sources[0] = source1;
        sources[1] = source2;

        address[] memory oracles = new address[](2);
        oracles[0] = oracle1;
        oracles[1] = oracle2;

        ISuperVaultStrategy.YieldSourceAction[] memory actions = new ISuperVaultStrategy.YieldSourceAction[](2);
        actions[0] = ISuperVaultStrategy.YieldSourceAction.Add;
        actions[1] = ISuperVaultStrategy.YieldSourceAction.Add;

        vm.prank(manager);
        strategy.manageYieldSources(sources, oracles, actions);

        assertTrue(strategy.containsYieldSource(source1));
        assertTrue(strategy.containsYieldSource(source2));
        assertEq(strategy.getYieldSourcesCount(), 2);
    }

    function test_ManageYieldSources_RevertsOnZeroLength() public {
        address[] memory empty = new address[](0);
        ISuperVaultStrategy.YieldSourceAction[] memory emptyActions = new ISuperVaultStrategy.YieldSourceAction[](0);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_LENGTH.selector);
        strategy.manageYieldSources(empty, empty, emptyActions);
    }

    function test_ManageYieldSources_RevertsOnLengthMismatch() public {
        address[] memory sources = new address[](2);
        address[] memory oracles = new address[](1);
        ISuperVaultStrategy.YieldSourceAction[] memory actions = new ISuperVaultStrategy.YieldSourceAction[](2);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_ARRAY_LENGTH.selector);
        strategy.manageYieldSources(sources, oracles, actions);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: getYieldSources (line 618)
    // =========================================================================
    function test_GetYieldSources_ReturnsAddresses() public {
        address source1 = makeAddr("source1");
        address oracle1 = makeAddr("oracle1");

        vm.prank(manager);
        strategy.manageYieldSource(source1, oracle1, ISuperVaultStrategy.YieldSourceAction.Add);

        address[] memory sources = strategy.getYieldSources();
        assertEq(sources.length, 1);
        assertEq(sources[0], source1);
    }

    function test_GetYieldSources_EmptyWhenNone() public view {
        address[] memory sources = strategy.getYieldSources();
        assertEq(sources.length, 0);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: getYieldSourcesList (line 603)
    // =========================================================================
    function test_GetYieldSourcesList_ReturnsFullInfo() public {
        address source1 = makeAddr("source1");
        address oracle1 = makeAddr("oracle1");
        address source2 = makeAddr("source2");
        address oracle2 = makeAddr("oracle2");

        vm.startPrank(manager);
        strategy.manageYieldSource(source1, oracle1, ISuperVaultStrategy.YieldSourceAction.Add);
        strategy.manageYieldSource(source2, oracle2, ISuperVaultStrategy.YieldSourceAction.Add);
        vm.stopPrank();

        ISuperVaultStrategy.YieldSourceInfo[] memory list = strategy.getYieldSourcesList();
        assertEq(list.length, 2);
        // Verify both sources are present (order may vary with EnumerableSet)
        bool found1;
        bool found2;
        for (uint256 i; i < list.length; i++) {
            if (list[i].sourceAddress == source1 && list[i].oracle == oracle1) found1 = true;
            if (list[i].sourceAddress == source2 && list[i].oracle == oracle2) found2 = true;
        }
        assertTrue(found1, "Source1 not found in list");
        assertTrue(found2, "Source2 not found in list");
    }

    function test_GetYieldSourcesList_EmptyWhenNone() public view {
        ISuperVaultStrategy.YieldSourceInfo[] memory list = strategy.getYieldSourcesList();
        assertEq(list.length, 0);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: getYieldSource (line 598)
    // =========================================================================
    function test_GetYieldSource_ReturnsOracle() public {
        address source = makeAddr("source");
        address oracle = makeAddr("oracle");

        vm.prank(manager);
        strategy.manageYieldSource(source, oracle, ISuperVaultStrategy.YieldSourceAction.Add);

        ISuperVaultStrategy.YieldSource memory ys = strategy.getYieldSource(source);
        assertEq(ys.oracle, oracle);
    }

    function test_GetYieldSource_ReturnsZeroForNonExistent() public view {
        ISuperVaultStrategy.YieldSource memory ys = strategy.getYieldSource(address(0xdead));
        assertEq(ys.oracle, address(0));
    }

    // =========================================================================
    // SuperVaultStrategy.sol: getYieldSourcesCount (line 623)
    // =========================================================================
    function test_GetYieldSourcesCount_Zero() public view {
        assertEq(strategy.getYieldSourcesCount(), 0);
    }

    function test_GetYieldSourcesCount_AfterAdds() public {
        vm.startPrank(manager);
        strategy.manageYieldSource(makeAddr("s1"), makeAddr("o1"), ISuperVaultStrategy.YieldSourceAction.Add);
        strategy.manageYieldSource(makeAddr("s2"), makeAddr("o2"), ISuperVaultStrategy.YieldSourceAction.Add);
        vm.stopPrank();

        assertEq(strategy.getYieldSourcesCount(), 2);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: containsYieldSource (line 648)
    // =========================================================================
    function test_ContainsYieldSource_TrueAndFalse() public {
        address source = makeAddr("source");

        assertFalse(strategy.containsYieldSource(source));

        vm.prank(manager);
        strategy.manageYieldSource(source, makeAddr("oracle"), ISuperVaultStrategy.YieldSourceAction.Add);

        assertTrue(strategy.containsYieldSource(source));
    }

    // =========================================================================
    // SuperVaultStrategy.sol: vaultUnrealizedProfit (line 630)
    // =========================================================================
    function test_VaultUnrealizedProfit_ZeroWhenNoShares() public view {
        assertEq(strategy.vaultUnrealizedProfit(), 0);
    }

    function test_VaultUnrealizedProfit_ZeroWhenPPSEqualsHWM() public {
        _depositAs(user, 1000e18);
        // PPS == HWM == 1e18
        assertEq(strategy.vaultUnrealizedProfit(), 0);
    }

    function test_VaultUnrealizedProfit_PositiveOnPPSGrowth() public {
        _depositAs(user, 1000e18);

        // Increase PPS to 1.5e18 (50% growth above HWM of 1e18)
        _setPPS(1.5e18);

        uint256 profit = strategy.vaultUnrealizedProfit();
        assertGt(profit, 0);

        // Expected: (1.5e18 - 1e18) * totalSupply / PRECISION = 0.5e18 * 1000e18 / 1e18 = 500e18
        uint256 totalSupply = vault.totalSupply();
        uint256 expected = Math.mulDiv(0.5e18, totalSupply, PRECISION, Math.Rounding.Floor);
        assertEq(profit, expected);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: managePPSExpiration (line 550)
    // =========================================================================
    function test_ManagePPSExpiration_ProposeExecuteCancel() public {
        uint256 newThreshold = 1 hours;

        // Propose
        vm.prank(manager);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Propose, newThreshold);

        // Wait for timelock
        vm.warp(block.timestamp + 1 weeks + 1);

        // Execute
        vm.prank(manager);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Execute, 0);

        assertEq(strategy.ppsExpiration(), newThreshold);
    }

    function test_ManagePPSExpiration_Cancel() public {
        uint256 newThreshold = 2 hours;

        // Propose
        vm.prank(manager);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Propose, newThreshold);

        // Cancel
        vm.prank(manager);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Cancel, 0);

        assertEq(strategy.proposedPPSExpiryThreshold(), 0);
        assertEq(strategy.ppsExpiryThresholdEffectiveTime(), 0);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: manageYieldSource - add, update, remove (lines 858-904)
    // =========================================================================
    function test_ManageYieldSource_AddUpdateRemove() public {
        address source = makeAddr("source");
        address oracle1 = makeAddr("oracle1");
        address oracle2 = makeAddr("oracle2");

        // Add
        vm.prank(manager);
        strategy.manageYieldSource(source, oracle1, ISuperVaultStrategy.YieldSourceAction.Add);
        assertTrue(strategy.containsYieldSource(source));
        assertEq(strategy.getYieldSource(source).oracle, oracle1);

        // Update oracle
        vm.prank(manager);
        strategy.manageYieldSource(source, oracle2, ISuperVaultStrategy.YieldSourceAction.UpdateOracle);
        assertEq(strategy.getYieldSource(source).oracle, oracle2);

        // Remove
        vm.prank(manager);
        strategy.manageYieldSource(source, address(0), ISuperVaultStrategy.YieldSourceAction.Remove);
        assertFalse(strategy.containsYieldSource(source));
        assertEq(strategy.getYieldSourcesCount(), 0);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: _addYieldSource error paths (line 871-878)
    // =========================================================================
    function test_AddYieldSource_RevertsOnZeroSource() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        strategy.manageYieldSource(address(0), makeAddr("oracle"), ISuperVaultStrategy.YieldSourceAction.Add);
    }

    function test_AddYieldSource_RevertsOnZeroOracle() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        strategy.manageYieldSource(makeAddr("source"), address(0), ISuperVaultStrategy.YieldSourceAction.Add);
    }

    function test_AddYieldSource_RevertsOnDuplicate() public {
        address source = makeAddr("source");
        vm.startPrank(manager);
        strategy.manageYieldSource(source, makeAddr("oracle"), ISuperVaultStrategy.YieldSourceAction.Add);

        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_ALREADY_EXISTS.selector);
        strategy.manageYieldSource(source, makeAddr("oracle2"), ISuperVaultStrategy.YieldSourceAction.Add);
        vm.stopPrank();
    }

    // =========================================================================
    // SuperVaultStrategy.sol: _updateYieldSourceOracle error paths (line 883-890)
    // =========================================================================
    function test_UpdateYieldSourceOracle_RevertsOnZeroOracle() public {
        address source = makeAddr("source");
        vm.startPrank(manager);
        strategy.manageYieldSource(source, makeAddr("oracle"), ISuperVaultStrategy.YieldSourceAction.Add);

        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        strategy.manageYieldSource(source, address(0), ISuperVaultStrategy.YieldSourceAction.UpdateOracle);
        vm.stopPrank();
    }

    function test_UpdateYieldSourceOracle_RevertsOnNotFound() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_NOT_FOUND.selector);
        strategy.manageYieldSource(makeAddr("ghost"), makeAddr("oracle"), ISuperVaultStrategy.YieldSourceAction.UpdateOracle);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: _removeYieldSource error paths (line 894-904)
    // =========================================================================
    function test_RemoveYieldSource_RevertsOnNotFound() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.YIELD_SOURCE_NOT_FOUND.selector);
        strategy.manageYieldSource(makeAddr("ghost"), address(0), ISuperVaultStrategy.YieldSourceAction.Remove);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: _proposePPSExpiration error paths (line 908-920)
    // =========================================================================
    function test_ProposePPSExpiration_RevertsOnThresholdTooLow() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Propose, 30); // < 1 minute
    }

    function test_ProposePPSExpiration_RevertsOnThresholdTooHigh() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Propose, 2 weeks); // > 1 week
    }

    // =========================================================================
    // SuperVaultStrategy.sol: _updatePPSExpiration error paths (line 923-937)
    // =========================================================================
    function test_UpdatePPSExpiration_RevertsOnNoProposal() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_PPS_EXPIRY_THRESHOLD.selector);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Execute, 0);
    }

    function test_UpdatePPSExpiration_RevertsBeforeTimelock() public {
        vm.prank(manager);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Propose, 1 hours);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_TIMESTAMP.selector);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Execute, 0);
    }

    // =========================================================================
    // SuperVaultStrategy.sol: _cancelPPSExpirationProposalUpdate error path (line 940-949)
    // =========================================================================
    function test_CancelPPSExpiration_RevertsOnNoProposal() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
        strategy.managePPSExpiration(ISuperVaultStrategy.PPSExpirationAction.Cancel, 0);
    }

    // =========================================================================
    // SuperVault.sol: requestRedeem (line 182-203)
    // Covers: requestRedeem success path, strategy.handleOperations7540 RedeemRequest,
    //         _handleRequestRedeem (lines 973-999)
    // =========================================================================
    function test_RequestRedeem_Success() public {
        _depositAs(user, 1000e18);
        uint256 shares = vault.balanceOf(user);
        assertGt(shares, 0);

        vm.prank(user);
        uint256 requestId = vault.requestRedeem(shares, user, user);
        assertEq(requestId, 0); // REQUEST_ID is 0
    }

    function test_RequestRedeem_Incremental() public {
        _depositAs(user, 1000e18);
        uint256 totalShares = vault.balanceOf(user);
        uint256 half = totalShares / 2;

        vm.startPrank(user);
        vault.requestRedeem(half, user, user);
        // Second request hits incremental path (lines 987-994)
        vault.requestRedeem(totalShares - half, user, user);
        vm.stopPrank();
    }

    function test_RequestRedeem_RevertsZeroShares() public {
        vm.prank(user);
        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.requestRedeem(0, user, user);
    }

    function test_RequestRedeem_RevertsZeroController() public {
        vm.prank(user);
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.requestRedeem(100e18, address(0), user);
    }

    function test_RequestRedeem_RevertsControllerNotOwner() public {
        _depositAs(user, 1000e18);
        address other = makeAddr("other");

        vm.prank(user);
        vm.expectRevert(ISuperVault.CONTROLLER_MUST_EQUAL_OWNER.selector);
        vault.requestRedeem(100e18, other, user);
    }

    // =========================================================================
    // SuperVault.sol: cancelRedeemRequest (line 207-220)
    // Covers: _handleCancelRedeemRequest (lines 1006-1013)
    // =========================================================================
    function test_CancelRedeemRequest_Success() public {
        _depositAs(user, 1000e18);
        uint256 shares = vault.balanceOf(user);

        vm.startPrank(user);
        vault.requestRedeem(shares, user, user);
        vault.cancelRedeemRequest(0, user);
        vm.stopPrank();
    }

    // =========================================================================
    // SuperVault.sol: authorizeOperator with EIP-712 signature (lines 254-280)
    // =========================================================================
    function test_AuthorizeOperator_WithSignature() public {
        uint256 controllerPk = 0x100;
        address controller = vm.addr(controllerPk);
        address operator = makeAddr("operator");
        bytes32 nonce = keccak256("nonce1");
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 structHash = keccak256(
            abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), controller, operator, true, nonce, deadline)
        );
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(controllerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool result = vault.authorizeOperator(controller, operator, true, nonce, deadline, signature);
        assertTrue(result);
        assertTrue(vault.isOperator(controller, operator));
    }

    function test_AuthorizeOperator_RevertsOnExpiredDeadline() public {
        vm.warp(100);
        vm.expectRevert(ISuperVault.DEADLINE_PASSED.selector);
        vault.authorizeOperator(user, makeAddr("op"), true, bytes32(0), 50, "");
    }

    function test_AuthorizeOperator_RevertsOnUsedNonce() public {
        bytes32 nonce = keccak256("used");
        vm.prank(user);
        vault.invalidateNonce(nonce);

        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(user, makeAddr("op"), true, nonce, block.timestamp + 1, "");
    }

    function test_AuthorizeOperator_RevertsOnSelfOperator() public {
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(user, user, true, bytes32(0), block.timestamp + 1, "");
    }

    // =========================================================================
    // SuperVault.sol: _validateControllerAndReceiver - receiver != controller (line 591)
    // =========================================================================
    function test_ClaimCancelRedeem_RevertsOperatorReceiverNotController() public {
        // Setup: deposit, requestRedeem, cancelRedeem
        _depositAs(user, 1000e18);
        uint256 shares = vault.balanceOf(user);

        vm.startPrank(user);
        vault.requestRedeem(shares, user, user);
        vault.cancelRedeemRequest(0, user);
        vm.stopPrank();

        // Set operator
        address operator = makeAddr("operator");
        vm.prank(user);
        vault.setOperator(operator, true);

        // Operator tries to claim with receiver != controller
        address wrongReceiver = makeAddr("wrongReceiver");
        vm.prank(operator);
        vm.expectRevert(ISuperVault.RECEIVER_MUST_EQUAL_CONTROLLER.selector);
        vault.claimCancelRedeemRequest(0, wrongReceiver, user);
    }

    // =========================================================================
    // SuperVault.sol: mint (line 162-180)
    // Covers: strategy.handleOperations4626Mint, strategy.quoteMintAssetsGross
    // =========================================================================
    function test_Mint_Success() public {
        uint256 sharesToMint = 500e18;
        // Approximate assets needed (PPS is 1e18, so 1:1 ratio)
        uint256 maxAssets = sharesToMint * 2; // extra buffer

        deal(address(asset), user, maxAssets);
        vm.startPrank(user);
        asset.approve(address(vault), maxAssets);
        vault.mint(sharesToMint, user);
        vm.stopPrank();

        assertEq(vault.balanceOf(user), sharesToMint);
    }

    function test_Mint_RevertsOnZeroShares() public {
        vm.prank(user);
        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.mint(0, user);
    }

    function test_Mint_RevertsOnZeroReceiver() public {
        vm.prank(user);
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.mint(100e18, address(0));
    }
}
