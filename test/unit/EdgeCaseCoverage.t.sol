// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { ISuperGovernor, FeeType } from "../../src/interfaces/ISuperGovernor.sol";
import { SuperVaultAggregator } from "../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { SuperVault } from "../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultEscrow } from "../../src/interfaces/SuperVault/ISuperVaultEscrow.sol";
import { SuperVaultAccountingLib } from "../../src/libraries/SuperVaultAccountingLib.sol";
import { FixedPriceOracle } from "../../src/oracles/FixedPriceOracle.sol";
import { ISuperVault } from "../../src/interfaces/SuperVault/ISuperVault.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { MockUp } from "../mocks/MockUp.sol";
import { MockSuperOracle } from "../mocks/MockSuperOracle.sol";

/// @title EdgeCaseCoverageTest
/// @notice Edge case tests for remaining coverage gaps
contract EdgeCaseCoverageTest is PeripheryHelpers {
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
    // SuperVaultAggregator: onlyPPSOracle modifier (line 101-104)
    // =========================================================================
    function test_ForwardPPS_RevertsOnNonPPSOracle() public {
        address[] memory strategies = new address[](1);
        strategies[0] = address(strategy);
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = 1e18;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        vm.prank(user); // user is not the PPS oracle
        vm.expectRevert(ISuperVaultAggregator.UNAUTHORIZED_PPS_ORACLE.selector);
        superVaultAggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies,
                ppss: ppss,
                timestamps: timestamps,
                updateAuthority: user
            })
        );
    }

    // =========================================================================
    // SuperVaultAggregator: updatePPSAfterSkim - PPS_MUST_DECREASE (line 321)
    // =========================================================================
    function test_UpdatePPSAfterSkim_RevertsOnPPSNotDecreasing() public {
        uint256 currentPPS = superVaultAggregator.getPPS(address(strategy));
        assertGt(currentPPS, 0);

        // Try to set newPPS >= currentPPS (should revert)
        vm.prank(address(strategy));
        vm.expectRevert(ISuperVaultAggregator.PPS_MUST_DECREASE_AFTER_SKIM.selector);
        superVaultAggregator.updatePPSAfterSkim(currentPPS, 100e18);
    }

    function test_UpdatePPSAfterSkim_RevertsOnPPSIncrease() public {
        uint256 currentPPS = superVaultAggregator.getPPS(address(strategy));

        vm.prank(address(strategy));
        vm.expectRevert(ISuperVaultAggregator.PPS_MUST_DECREASE_AFTER_SKIM.selector);
        superVaultAggregator.updatePPSAfterSkim(currentPPS + 1, 100e18);
    }

    // =========================================================================
    // SuperVaultAggregator: updatePPSAfterSkim - PPS_DEDUCTION_TOO_LARGE (line 332)
    // =========================================================================
    function test_UpdatePPSAfterSkim_RevertsOnDeductionTooLarge() public {
        uint256 currentPPS = superVaultAggregator.getPPS(address(strategy));

        // Set newPPS very low (e.g., 1 wei) - this should trigger PPS_DEDUCTION_TOO_LARGE
        // MAX_PERFORMANCE_FEE is 5100 (51%), so minAllowedPPS = currentPPS * 4900 / 10000 = ~49% of current
        // Setting to 1 wei is way below that
        vm.prank(address(strategy));
        vm.expectRevert(ISuperVaultAggregator.PPS_DEDUCTION_TOO_LARGE.selector);
        superVaultAggregator.updatePPSAfterSkim(1, 100e18);
    }

    // =========================================================================
    // SuperGovernor: getActivePPSOracle revert NO_ACTIVE_PPS_ORACLE (line 739)
    // =========================================================================
    function test_GetActivePPSOracle_RevertsWhenNotSet() public {
        // Deploy a fresh SuperGovernor without PPS oracle set
        SuperGovernor freshGovernor =
            new SuperGovernor(sGovernor, governor, governor, governor, governor, governor, treasury, false);

        vm.expectRevert(ISuperGovernor.NO_ACTIVE_PPS_ORACLE.selector);
        freshGovernor.getActivePPSOracle();
    }

    // =========================================================================
    // SuperGovernor: getAddress revert CONTRACT_NOT_FOUND (line 669)
    // =========================================================================
    function test_GetAddress_RevertsOnNotFound() public {
        vm.expectRevert(ISuperGovernor.CONTRACT_NOT_FOUND.selector);
        superGovernor.getAddress(keccak256("NON_EXISTENT_KEY"));
    }

    // =========================================================================
    // SuperVaultAccountingLib: calculateAverageWithdrawPrice edge case
    // When both currentMaxWithdraw and requestedShares lead to newTotalShares == 0
    // =========================================================================
    function test_CalculateAverageWithdrawPrice_ZeroShares() public pure {
        // When currentMaxWithdraw == 0 and requestedShares == 0
        // newTotalShares == 0, so return 0
        uint256 result = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
            0, // currentMaxWithdraw
            0, // currentAverageWithdrawPrice
            0, // requestedShares
            0, // fulfilledAssets
            1e18 // precision
        );
        assertEq(result, 0);
    }

    function test_CalculateAverageWithdrawPrice_WithExistingPosition() public pure {
        // currentMaxWithdraw = 1000, currentAverageWithdrawPrice = 1e18
        // requestedShares = 500, fulfilledAssets = 500
        uint256 result = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
            1000e18, // currentMaxWithdraw
            1e18, // currentAverageWithdrawPrice
            500e18, // requestedShares
            500e18, // fulfilledAssets
            1e18 // precision
        );
        assertGt(result, 0);
    }

    function test_CalculateAverageWithdrawPrice_ZeroCurrentMaxWithdraw() public pure {
        // When currentMaxWithdraw == 0 but requestedShares > 0
        // existingShares = 0, existingAssets = 0
        // newTotalShares = 0 + 100e18 = 100e18
        // newTotalAssets = 0 + 200e18 = 200e18
        // result = 200e18 * 1e18 / 100e18 = 2e18
        uint256 result = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
            0, // currentMaxWithdraw
            0, // currentAverageWithdrawPrice
            100e18, // requestedShares
            200e18, // fulfilledAssets
            1e18 // precision
        );
        assertEq(result, 2e18);
    }

    // =========================================================================
    // SuperVaultAccountingLib: computeMinNetOut
    // =========================================================================
    function test_ComputeMinNetOut_BasicCalculation() public pure {
        // requestedShares = 100e18, averageRequestPPS = 1e18, slippageBps = 50 (0.5%)
        uint256 result = SuperVaultAccountingLib.computeMinNetOut(
            100e18, // requestedShares
            1e18, // averageRequestPPS
            50, // slippageBps
            1e18 // precision
        );
        // expected = 100e18 * (10000 - 50) / 10000 = 100e18 * 9950 / 10000 = 99.5e18
        assertEq(result, 99.5e18);
    }

    // =========================================================================
    // FixedPriceOracle: phaseAggregators branch (line 164-166)
    // =========================================================================
    function test_FixedPriceOracle_PhaseAggregators_Phase1() public {
        FixedPriceOracle oracle = new FixedPriceOracle(1e8, 8, address(this));
        assertEq(oracle.phaseAggregators(1), address(oracle));
    }

    function test_FixedPriceOracle_PhaseAggregators_NonPhase1() public {
        FixedPriceOracle oracle = new FixedPriceOracle(1e8, 8, address(this));
        assertEq(oracle.phaseAggregators(0), address(0));
        assertEq(oracle.phaseAggregators(2), address(0));
    }

    function test_FixedPriceOracle_Constructor_RevertsOnZeroPrice() public {
        vm.expectRevert(FixedPriceOracle.INVALID_PRICE.selector);
        new FixedPriceOracle(0, 8, address(this));
    }

    function test_FixedPriceOracle_Constructor_RevertsOnNegativePrice() public {
        vm.expectRevert(FixedPriceOracle.INVALID_PRICE.selector);
        new FixedPriceOracle(-1, 8, address(this));
    }

    function test_FixedPriceOracle_LatestRoundData() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();
        assertEq(roundId, 1);
        assertEq(answer, 42e8);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 1);
    }

    function test_FixedPriceOracle_GetRoundData() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        (uint80 roundId, int256 answer,,, uint80 answeredInRound) = oracle.getRoundData(5);
        assertEq(roundId, 5);
        assertEq(answer, 42e8);
        assertEq(answeredInRound, 5);
    }

    function test_FixedPriceOracle_LatestAnswer() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        assertEq(oracle.latestAnswer(), uint256(42e8));
    }

    function test_FixedPriceOracle_GetTimestamp() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        assertEq(oracle.getTimestamp(99), block.timestamp);
    }

    function test_FixedPriceOracle_PhaseId() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        assertEq(oracle.phaseId(), 1);
    }

    function test_FixedPriceOracle_Version() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        assertEq(oracle.version(), 1);
    }

    function test_FixedPriceOracle_Description() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        assertEq(oracle.description(), "Fixed Price Oracle");
    }

    function test_FixedPriceOracle_Decimals() public {
        FixedPriceOracle oracle = new FixedPriceOracle(42e8, 8, address(this));
        assertEq(oracle.decimals(), 8);
    }

    function test_FixedPriceOracle_SetPrice() public {
        FixedPriceOracle oracle = new FixedPriceOracle(1e8, 8, address(this));
        oracle.setPrice(2e8);
        assertEq(oracle.latestAnswer(), 2e8);
    }

    function test_FixedPriceOracle_SetPrice_RevertsOnZero() public {
        FixedPriceOracle oracle = new FixedPriceOracle(1e8, 8, address(this));
        vm.expectRevert(FixedPriceOracle.INVALID_PRICE.selector);
        oracle.setPrice(0);
    }

    function test_FixedPriceOracle_SetDecimals() public {
        FixedPriceOracle oracle = new FixedPriceOracle(1e8, 8, address(this));
        oracle.setDecimals(18);
        assertEq(oracle.decimals(), 18);
    }

    // =========================================================================
    // SuperVaultEscrow: onlyVault modifier revert (line 30)
    // =========================================================================
    function test_SuperVaultEscrow_OnlyVault_RevertsOnUnauthorized() public {
        address escrow = vault.escrow();

        vm.prank(user);
        vm.expectRevert(ISuperVaultEscrow.UNAUTHORIZED.selector);
        ISuperVaultEscrow(escrow).escrowShares(user, 100e18);

        vm.prank(user);
        vm.expectRevert(ISuperVaultEscrow.UNAUTHORIZED.selector);
        ISuperVaultEscrow(escrow).returnShares(user, 100e18);

        vm.prank(user);
        vm.expectRevert(ISuperVaultEscrow.UNAUTHORIZED.selector);
        ISuperVaultEscrow(escrow).returnAssets(user, 100e18);
    }

    // =========================================================================
    // SuperVaultStrategy: initialize revert - fee>0 + zero recipient (line 129)
    // =========================================================================
    function test_CreateVault_RevertsOnFeeWithZeroRecipient() public {
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.ZERO_ADDRESS.selector);
        superVaultAggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Bad Vault",
                symbol: "BV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: address(0) // zero recipient with fee > 0 should revert
                })
            })
        );
    }

    // =========================================================================
    // SuperVaultStrategy: cancelRedeemRequest when already pending (line 1010)
    // =========================================================================
    function test_RequestRedeem_RevertsWhenCancelPending() public {
        // Setup: deposit and request redeem with only some shares
        uint256 depositAmount = 1000e18;
        asset.mint(user, depositAmount);
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        uint256 shares = vault.balanceOf(user);

        // Request half the shares
        vault.requestRedeem(shares / 2, user, user);

        // Cancel the redeem request
        vault.cancelRedeemRequest(0, user);

        // Can't re-request while cancel is pending (strategy checks pendingCancelRedeemRequest)
        vm.expectRevert(ISuperVault.CANCELLATION_REDEEM_REQUEST_PENDING.selector);
        vault.requestRedeem(shares / 4, user, user);
        vm.stopPrank();
    }

    // =========================================================================
    // SuperVaultStrategy: handleOperations4626Deposit with veto (line 166)
    // =========================================================================
    function test_DepositRevertsWhenGlobalHooksRootVetoed() public {
        // Veto the global hooks root (governor has GUARDIAN_ROLE in our setup)
        vm.prank(governor);
        superGovernor.setGlobalHooksRootVetoStatus(true);

        // Deposit should now revert
        uint256 depositAmount = 100e18;
        asset.mint(user, depositAmount);
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vm.expectRevert(ISuperVaultStrategy.OPERATIONS_BLOCKED_BY_VETO.selector);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
    }

    // =========================================================================
    // SuperVaultStrategy: mint reverts when veto is active (line 214)
    // =========================================================================
    function test_MintRevertsWhenGlobalHooksRootVetoed() public {
        vm.prank(governor);
        superGovernor.setGlobalHooksRootVetoStatus(true);

        uint256 mintAmount = 100e18;
        asset.mint(user, mintAmount * 2);
        vm.startPrank(user);
        asset.approve(address(vault), mintAmount * 2);
        vm.expectRevert(ISuperVaultStrategy.OPERATIONS_BLOCKED_BY_VETO.selector);
        vault.mint(mintAmount, user);
        vm.stopPrank();
    }

    // =========================================================================
    // SuperVaultStrategy: _isPrimaryManager revert with secondary manager
    // =========================================================================
    // =========================================================================
    // SuperVaultStrategy: double cancel revert (line 1010)
    // =========================================================================
    function test_CancelRedeemRequest_RevertsOnDoubleCancelAtStrategy() public {
        // Deposit
        uint256 depositAmount = 1000e18;
        asset.mint(user, depositAmount);
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        uint256 shares = vault.balanceOf(user);

        // Request redeem with half shares
        vault.requestRedeem(shares / 2, user, user);

        // First cancel succeeds (sets pendingCancelRedeemRequest = true)
        vault.cancelRedeemRequest(0, user);

        // Second cancel should revert from strategy: pendingCancelRedeemRequest is already true
        vm.expectRevert(ISuperVaultStrategy.CANCELLATION_REDEEM_REQUEST_PENDING.selector);
        vault.cancelRedeemRequest(0, user);
        vm.stopPrank();
    }

    function test_ManageYieldSource_RevertsForSecondaryManager() public {
        address secondaryManager = makeAddr("secondary");

        // Add secondary manager to strategy
        vm.prank(manager);
        superVaultAggregator.addSecondaryManager(address(strategy), secondaryManager);

        // Secondary manager should NOT be able to call primary-manager-only functions
        vm.prank(secondaryManager);
        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.manageYieldSource(makeAddr("source"), makeAddr("oracle"), ISuperVaultStrategy.YieldSourceAction.Add);
    }
}
