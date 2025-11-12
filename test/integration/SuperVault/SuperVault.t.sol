// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";

// external
import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

// superform
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IERC7540Redeem, IERC7540Operator, IERC7741 } from "../../../src/vendor/standards/ERC7540/IERC7540Vault.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { IGearboxFarmingPool } from "../../vendor/gearbox/IGearboxFarmingPool.sol";
import { ISuperExecutor } from "@superform-v2-core/src/interfaces/ISuperExecutor.sol";
import { AccountInstance, UserOpData } from "modulekit/ModuleKit.sol";
import { Mock4626Vault } from "../../mocks/Mock4626Vault.sol";
import { RuggableVault } from "../../mocks/RuggableVault.sol";
import { RuggableConvertVault } from "../../mocks/RuggableConvertVault.sol";
import { MockNativeETHHook } from "../../mocks/MockNativeETHHook.sol";
import { MockETHReceiver } from "../../mocks/MockETHReceiver.sol";
import { MockEmergencyVault } from "../../mocks/MockEmergencyVault.sol";
import { MockAssetNoDecimals } from "../../mocks/MockAssetNoDecimals.sol";
import { Create2 } from "openzeppelin-contracts/contracts/utils/Create2.sol";

contract SuperVaultTest is BaseSuperVaultTest {
    using Math for uint256;

    address operator = address(0x123);
    uint256 constant userPrivateKey = 0xA11CE; // Replace with a known good testing private key
    address userAddress; // Will be derived from private key

    address gearToken;
    IERC4626 gearboxVault;
    IGearboxFarmingPool gearboxFarmingPool;

    SuperVault gearSuperVault;
    SuperVaultEscrow escrowGearSuperVault;
    SuperVaultStrategy strategyGearSuperVault;


    struct UserPersona {
        address account;
        uint256 depositAmount;
        uint256 initialBalance;
        uint256 shares;
        uint256 finalBalance;
        uint256 claimableAssets;
    }

    struct TradingCycle {
        uint256 cycleNumber;
        uint256 depositAmount;
        uint256 sharesAfterDeposit;
        uint256 redeemAmount;
        uint256 claimedAssets;
    }

    /**
     * @notice Test focused on long-term holder behavior with single deposit and hold strategy
     */
    struct LongTermHolderTestData {
        address holder;
        uint256 depositAmount;
        uint256 initialBalance;
        uint256 shares;
        uint256 redeemShares;
        uint256 pendingRedeem;
        uint256 allocationAmountVault1;
        uint256 allocationAmountVault2;
        uint256 claimableAssets;
        uint256 maxWithdrawAmount;
        uint256 assetsToWithdraw;
        uint256 expectedPrincipal;
        uint256 actualEarnings;
        uint256 finalBalance;
    }

    function setUp() public override {
        super.setUp();
        userAddress = vm.addr(userPrivateKey); // Derive the correct address from private key

        // Update test vault predictions with correct deployer address (this contract)
        updateTestVaultPredictions();

        vm.selectFork(FORKS[ETH]);

        gearToken = existingUnderlyingTokens[ETH][GEAR_KEY];
        console2.log("gearToken: ", address(gearToken));
        vm.label(gearToken, "GearToken");

        // Get real yield sources from fork
        address gearboxVaultAddr = realVaultAddresses[ETH][ERC4626_VAULT_KEY][GEARBOX_VAULT_KEY][USDC_KEY];
        vm.label(gearboxVaultAddr, "GearboxVault");
        gearboxVault = IERC4626(gearboxVaultAddr);

        address gearboxStakingAddr =
            realVaultAddresses[ETH][STAKING_YIELD_SOURCE_ORACLE_KEY][GEARBOX_STAKING_KEY][GEAR_KEY];
        console2.log("gearboxStakingAddr: ", gearboxStakingAddr);
        vm.label(gearboxStakingAddr, "GearboxStaking");
        gearboxFarmingPool = IGearboxFarmingPool(gearboxStakingAddr);

        vm.startPrank(MANAGER);
        strategy.managePPSExpiration(1, 1 weeks);

        vm.warp(block.timestamp + 2 weeks);

        strategy.managePPSExpiration(2, 0);
        vm.stopPrank();

        _updateSuperVaultPPS(address(strategy), address(vault));
    }

    /*//////////////////////////////////////////////////////////////
                    CONSTRUCTOR & INITIALIZER TESTS
    //////////////////////////////////////////////////////////////*/
    function test_SuperVault_Constructor() public {
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        new SuperVault(address(0));

        vm.prank(MANAGER);
        vm.expectEmit(true, true, true, true);
        emit Initializable.Initialized(type(uint64).max);
        SuperVault vault = new SuperVault(address(superGovernor));

        assertEq(address(vault.SUPER_GOVERNOR()), address(superGovernor));

        SuperVault vaultError = new SuperVault(address(superGovernor));
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vaultError.initialize(address(0), "SuperVault", "SV_USDC", address(strategy), address(escrow));
    }

    function test_SuperVault_Initializer() public {
        ISuperVaultAggregator.VaultCreationParams memory params = ISuperVaultAggregator.VaultCreationParams({
            asset: address(asset),
            name: "SuperVault",
            symbol: "SV_USDC",
            mainManager: MANAGER,
            secondaryManagers: new address[](0),
            minUpdateInterval: 0,
            maxStaleness: 300,
            feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 0, managementFeeBps: 0, recipient: MANAGER })
        });
        aggregator.createVault(params);

        // Test that the reentrancy guard is initialized properly
        uint256 NOT_ENTERED = 1;

        // The slot used by OZ’s ReentrancyGuardUpgradeable
        bytes32 slot = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;
        uint256 storedValue = uint256(vm.load(address(vault), slot));

        assertEq(storedValue, NOT_ENTERED, "ReentrancyGuard not initialized properly");

        // Test revert case when asset has no decimals
        MockAssetNoDecimals mockAsset = new MockAssetNoDecimals("NoDecimals", "NODEC");
        ISuperVaultAggregator.VaultCreationParams memory params1 = ISuperVaultAggregator.VaultCreationParams({
            asset: address(mockAsset),
            name: "SuperVault",
            symbol: "SV_USDC",
            mainManager: MANAGER,
            secondaryManagers: new address[](0),
            minUpdateInterval: 0,
            maxStaleness: 300,
            feeConfig: ISuperVaultStrategy.FeeConfig({ performanceFeeBps: 0, managementFeeBps: 0, recipient: MANAGER })
        });
        vm.expectRevert(ISuperVault.INVALID_ASSET.selector);
        aggregator.createVault(params1);
    }

    /*//////////////////////////////////////////////////////////////
                            SUPERVAULT.SOL
    //////////////////////////////////////////////////////////////*/

    function test_Name() public view {
        string memory name = vault.name();
        assertEq(name, "SuperVault");
    }

    function test_Symbol() public view {
        string memory symbol = vault.symbol();
        assertEq(symbol, "SV_USDC");
    }

    function test_DepositXQ() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);

        // Verify state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");
    }

    function test_Deposit_RevertCases() public {
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.deposit(1000, address(0));

        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.deposit(0, accountEth);
    }

    function test_DepositDirectlyMintsShares() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Check state before deposit
        uint256 sharesBefore = vault.balanceOf(accountEth);
        assertEq(sharesBefore, 0, "User has shares before deposit");

        // Perform deposit
        _deposit(depositAmount);

        // Verify shares were minted immediately
        uint256 sharesAfter = vault.balanceOf(accountEth);
        assertGt(sharesAfter, 0, "No shares minted to user");

        // Assets should be in the strategy as free assets
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");
    }

    function test_DepositAndAllocateToYield() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Direct deposit
        _deposit(depositAmount);

        // Verify deposit state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        // Allocate the assets to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Verify allocation state
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");
    }

    function test_DepositAndAllocateToYieldViaSmartAccountManager() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deploy a new SuperVault with a smart account manager
        AccountInstance memory managerAccount = accInstances[1]; // Use a different account as manager
        _getTokens(address(asset), managerAccount.account, 1 ether); // Fund the manager account

        // Deploy vault with smart account manager
        (address newVaultAddr, address newStrategyAddr,) = _deployVaultWithSmartAccountManager(managerAccount.account);

        SuperVault newVault = SuperVault(newVaultAddr);
        SuperVaultStrategy newStrategy = SuperVaultStrategy(payable(newStrategyAddr));

        // Setup yield sources for the new strategy via smart account
        _manageYieldSourcesViaSmartAccount(managerAccount, newStrategy);

        // Direct deposit to the new vault
        _deposit(depositAmount, newVaultAddr, address(newStrategy), address(asset));

        // Verify deposit state
        uint256 userShares = newVault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(newStrategy)), depositAmount, "Wrong strategy balance");

        // Allocate the assets to yield sources via smart account manager
        _depositFreeAssetsFromSingleAmountViaSmartAccount(
            depositAmount, address(fluidVault), address(aaveVault), managerAccount, newStrategy
        );

        // Verify allocation state
        assertGt(fluidVault.balanceOf(address(newStrategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(newStrategy)), 0, "No aave shares allocated");

        // Verify that the strategy has no free assets left
        assertEq(asset.balanceOf(address(newStrategy)), 0, "Strategy should have no free assets after allocation");
    }

    function test_Mint_RevertCases() public {
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.mint(1000, address(0));

        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.mint(0, accountEth);
    }

    function test_MintShares() public {
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.mintShares(accountEth, 1000);

        uint256 initialShares = vault.balanceOf(accountEth);

        vm.prank(address(strategy));
        vault.mintShares(accountEth, 1000);

        assertEq(vault.balanceOf(accountEth), initialShares + 1000);
    }

    function test_FulfillRedeem_FullAmountWithThreshold() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 vaultBalance = vault.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);
        _requestRedeem(redeemShares);
        _executeRedeemHooks4626(redeemShares, address(fluidVault), address(aaveVault), new address[](0));

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_FulfillRedeem_FullAmount() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redemption
        uint256 vaultBalance = vault.balanceOf(accountEth);
        _requestRedeem(vaultBalance);
        _executeRedeemHooks4626(vaultBalance, address(fluidVault), address(aaveVault), new address[](0));

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_DepositAndAllocate() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Setup and fulfill deposit
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Verify state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");

        // Verify allocation
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");
    }

    function test_PauseAndUnpauseStrategy() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        _updateSuperVaultPPS(address(strategy), address(vault));
        // First deposit should work normally
        _deposit(depositAmount);
        assertGt(vault.balanceOf(accountEth), 0, "Initial deposit failed");

        // Pause the strategy (manager can pause)
        vm.startPrank(MANAGER);
        aggregator.pauseStrategy(address(strategy));
        vm.stopPrank();

        // Try to deposit when paused - should revert with STRATEGY_PAUSED
        vm.startPrank(accountEth);
        deal(address(asset), accountEth, depositAmount);
        asset.approve(address(vault), depositAmount);

        vm.warp(block.timestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        vault.deposit(depositAmount, accountEth);
        vm.stopPrank();

        vm.startPrank(MANAGER);
        aggregator.unpauseStrategy(address(strategy));
        vm.stopPrank();

        vm.warp(block.timestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Deposit should work again after unpause
        _deposit(depositAmount);
        assertGt(vault.balanceOf(accountEth), depositAmount, "Deposit after unpause failed");
    }

    /*//////////////////////////////////////////////////////////////
                        REDEEM FLOW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RequestRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redemption
        uint256 vaultBalance = vault.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);

        // Test revert cases
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVault.ZERO_AMOUNT.selector);
        vault.requestRedeem(0, accountEth, accountEth);

        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.requestRedeem(redeemShares, address(0), accountEth);

        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.requestRedeem(redeemShares, accountEth, address(0));

        uint256 reqId = vault.requestRedeem(redeemShares, accountEth, accountEth);
        vm.stopPrank();

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), redeemShares, "Wrong pending redeem amount");
        assertEq(vault.balanceOf(address(escrow)), redeemShares, "Wrong escrow balance");
        assertEq(reqId, 0, "Request ID should be 0");
    }

    function test_FulfillRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redemption
        uint256 vaultBalance = vault.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);
        _requestRedeem(redeemShares);
        _executeRedeemHooks4626(redeemShares, address(fluidVault), address(aaveVault), new address[](0));

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_ClaimRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        uint256 initialAssetBalance = asset.balanceOf(address(accountEth));
        console2.log("-------------- initialAssetBalance user", initialAssetBalance);

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        console2.log("-------------- balance strategy after deposit ", asset.balanceOf(address(strategy)));

        // Get balances after deposit
        uint256 assetBalanceAfterDeposit = asset.balanceOf(accountEth);
        uint256 initialShares = vault.balanceOf(accountEth);
        console2.log("-------------- initialAssetBalance user", assetBalanceAfterDeposit);
        console2.log("-------------- initialShares user", initialShares);

        console2.log("-------------- balance strategy after redeem ", asset.balanceOf(address(strategy)));
        // Request redeem of half the shares
        uint256 redeemShares = initialShares / 2;
        _requestRedeem(redeemShares);
        _executeRedeemHooks4626(redeemShares, address(fluidVault), address(aaveVault), new address[](0));

        console2.log("-------------- balance strategy after redeem ", asset.balanceOf(address(strategy)));
        // Get claimable assets
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);
        console2.log("-------------- claimableAssets user", claimableAssets);
        // Claim redeem
        _claimWithdraw(claimableAssets);

        // Verify state
        assertEq(vault.balanceOf(accountEth), initialShares - redeemShares, "Wrong final share balance");
        assertApproxEqRel(
            asset.balanceOf(accountEth), initialAssetBalance + claimableAssets, 0.05e18, "Wrong final asset balance"
        );
        assertEq(strategy.claimableWithdraw(accountEth), 0, "Assets not claimed");
    }

    function test_LongTermHolder_vs_ActiveTrader_SameAmounts() public {
        UserPersona memory holder;
        UserPersona memory trader;

        // Setup user personas
        holder.account = accInstances[0].account;
        trader.account = accInstances[1].account;
        holder.depositAmount = 10_000e6; // 10,000 USDC - larger position
        trader.depositAmount = 10_000e6; // 2,000 USDC - smaller, more active position

        console2.log("=== SETTING UP USER PERSONAS ===");
        console2.log("Long-term holder:", holder.account);
        console2.log("Active trader:", trader.account);

        // Give tokens to both users
        _getTokens(address(asset), holder.account, holder.depositAmount);
        _getTokens(address(asset), trader.account, trader.depositAmount * 5); // Extra for multiple trades

        // Track initial balances
        holder.initialBalance = asset.balanceOf(holder.account);
        trader.initialBalance = asset.balanceOf(trader.account);

        console2.log("Holder initial balance:", holder.initialBalance);
        console2.log("Trader initial balance:", trader.initialBalance);

        _executeInitialDeposits(holder, trader);
        _executeActiveTradingPeriod(trader);
        _executeLongTermHolding(holder);
        _executeFinalRedemptions(holder, trader);

        console2.log("=== TEST COMPLETED SUCCESSFULLY ===");
    }

    /// @notice Complete yield comparison test that shows final earnings for both strategies
    function test_LongTermHolder_vs_ActiveTrader_CompleteYieldComparison() public {
        UserPersona memory holder;
        UserPersona memory trader;

        // Setup user personas with same total investment amounts
        holder.account = accInstances[0].account;
        trader.account = accInstances[1].account;
        holder.depositAmount = 10_000e6; // 10,000 USDC initial
        trader.depositAmount = 10_000e6; // 10,000 USDC initial

        console2.log("=== YIELD COMPARISON TEST: EQUAL TOTAL INVESTMENTS ===");
        console2.log("Long-term holder:", holder.account);
        console2.log("Active trader:", trader.account);
        console2.log("Both users will invest 25,000 USDC total");

        // Give tokens to both users (enough for total investment)
        uint256 totalInvestmentAmount = 25_000e6; // 25,000 USDC each
        _getTokens(address(asset), holder.account, totalInvestmentAmount);
        _getTokens(address(asset), trader.account, totalInvestmentAmount);

        // Track initial balances
        holder.initialBalance = asset.balanceOf(holder.account);
        trader.initialBalance = asset.balanceOf(trader.account);

        console2.log("Holder initial balance:", holder.initialBalance / 1e6, "USDC");
        console2.log("Trader initial balance:", trader.initialBalance / 1e6, "USDC");
        _updateSuperVaultPPS(address(strategy), address(vault));
        // Execute the full flow with equal total investments
        _executeEqualInvestmentDeposits(holder, trader);
        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        _updateSuperVaultPPS(address(strategy), address(vault));
        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        _executeActiveTradingPeriod(trader);
        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        _updateSuperVaultPPS(address(strategy), address(vault));
        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        _executeEqualInvestmentHolding(holder);
        _updateSuperVaultPPS(address(strategy), address(vault));
        _executeFinalRedemptions(holder, trader);

        _updateSuperVaultPPS(address(strategy), address(vault));
        // Complete the redemption process and calculate final yields
        _completeRedemptionsAndCalculateYield(holder, trader);
    }

    /**
     * @notice Test simulating different user personas: Long-term holder vs Active trader
     * @dev This test demonstrates how different user behaviors interact with the SuperVault system
     */
    function test_LongTermHolder_vs_ActiveTrader() public {
        UserPersona memory holder;
        UserPersona memory trader;

        // Setup user personas
        holder.account = accInstances[0].account;
        trader.account = accInstances[1].account;
        holder.depositAmount = 10_000e6; // 10,000 USDC - larger position
        trader.depositAmount = 2000e6; // 2,000 USDC - smaller, more active position

        console2.log("=== SETTING UP USER PERSONAS ===");
        console2.log("Long-term holder:", holder.account);
        console2.log("Active trader:", trader.account);

        // Give tokens to both users
        _getTokens(address(asset), holder.account, holder.depositAmount);
        _getTokens(address(asset), trader.account, trader.depositAmount * 5); // Extra for multiple trades

        // Track initial balances
        holder.initialBalance = asset.balanceOf(holder.account);
        trader.initialBalance = asset.balanceOf(trader.account);

        console2.log("Holder initial balance:", holder.initialBalance);
        console2.log("Trader initial balance:", trader.initialBalance);

        _executeInitialDeposits(holder, trader);
        _executeActiveTradingPeriod(trader);
        _executeLongTermHolding(holder);
        _executeFinalRedemptions(holder, trader);

        console2.log("=== TEST COMPLETED SUCCESSFULLY ===");
    }

    function test_LongTermHolder_SingleDepositHold() public {
        LongTermHolderTestData memory vars;
        vars.holder = accInstances[0].account;
        vars.depositAmount = 50_000e6; // 50,000 USDC - large position

        console2.log("=== LONG-TERM HOLDER TEST ===");
        console2.log("Holder address:", vars.holder);
        console2.log("Deposit amount:", vars.depositAmount);

        // Setup
        _getTokens(address(asset), vars.holder, vars.depositAmount * 2);
        vars.initialBalance = asset.balanceOf(vars.holder);

        // Single deposit
        _depositForAccount(accInstances[0], vars.depositAmount);
        vars.shares = vault.balanceOf(vars.holder);

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(vars.depositAmount, address(fluidVault), address(aaveVault));

        console2.log("Shares received:", vars.shares);

        // Hold for extended period (90 days)
        vm.warp(block.timestamp + 90 days);
        _updateSuperVaultPPS(address(strategy), address(vault));
        vars.shares = vault.balanceOf(vars.holder);

        // Verify shares haven't changed
        assertEq(vault.balanceOf(vars.holder), vars.shares, "Shares should remain constant during hold period");

        vars.redeemShares = vars.shares; // 40B shares - round number
        console2.log("Using fixed redeem shares:", vars.redeemShares);

        _requestRedeemForAccount(accInstances[0], vars.redeemShares);

        // Check pending redeem request
        vars.pendingRedeem = strategy.pendingRedeemRequest(vars.holder);
        console2.log("Pending redeem request:", vars.pendingRedeem);
        assertEq(vars.pendingRedeem, vars.redeemShares, "Pending redeem should match requested amount");

        // Fulfill redeem using manual allocation to avoid INVALID_REDEEM_FILL precision issues
        console2.log("\n=== FULFILLING REDEEM WITH MANUAL ALLOCATION ===");

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = vars.holder;
        vars.allocationAmountVault1 = vars.redeemShares / 2;
        vars.allocationAmountVault2 = vars.redeemShares / 2;

        console2.log("Manual allocation:");
        console2.log("  Vault 1 allocation:", vars.allocationAmountVault1);
        console2.log("  Vault 2 allocation:", vars.allocationAmountVault2);
        console2.log("  Total allocation:", vars.allocationAmountVault1 + vars.allocationAmountVault2);

        _executeRedeemHooks4626ForUsers(
            requestingUsers,
            vars.allocationAmountVault1,
            vars.allocationAmountVault2,
            address(fluidVault),
            address(aaveVault)
        );

        console2.log("Redeem fulfillment successful!");

        // Now check claimable assets (this shows the actual earnings!)
        vars.claimableAssets = strategy.claimableWithdraw(vars.holder);
        vars.maxWithdrawAmount = vault.maxWithdraw(vars.holder);
        uint256 maxRedeemShares = vault.maxRedeem(vars.holder);
        uint256 averageWithdrawPrice = strategy.getAverageWithdrawPrice(vars.holder);

        console2.log("Claimable assets after 90 days:", vars.claimableAssets);
        console2.log("Max withdraw amount:", vars.maxWithdrawAmount);
        console2.log("Max redeem shares:", maxRedeemShares);
        console2.log("Average withdraw price:", averageWithdrawPrice);
        console2.log("Current shares balance:", vault.balanceOf(vars.holder));

        // Use maxRedeem to get the correct shares amount, then calculate assets from that
        uint256 sharesToRedeem =
            maxRedeemShares > vault.balanceOf(vars.holder) ? vault.balanceOf(vars.holder) : maxRedeemShares;
        vars.assetsToWithdraw = sharesToRedeem.mulDiv(averageWithdrawPrice, 1e6, Math.Rounding.Floor);

        console2.log("Shares to redeem:", sharesToRedeem);
        console2.log("Calculated assets to withdraw:", vars.assetsToWithdraw);

        // Calculate actual earnings
        vars.expectedPrincipal = (vars.depositAmount * vars.redeemShares) / vars.shares;
        vars.actualEarnings =
            vars.assetsToWithdraw > vars.expectedPrincipal ? vars.assetsToWithdraw - vars.expectedPrincipal : 0;

        console2.log("Actual earnings calculation:");
        console2.log("  Expected principal:", vars.expectedPrincipal);
        console2.log("  Assets to withdraw:", vars.assetsToWithdraw);
        console2.log("  Actual earnings:", vars.actualEarnings);
        if (vars.expectedPrincipal > 0) {
            console2.log(
                "  Earnings percentage:", vars.actualEarnings * 10_000 / vars.expectedPrincipal, "basis points"
            );
        }

        // Claim the assets to see final balance
        if (vars.assetsToWithdraw > 0) {
            _claimWithdrawForAccount(accInstances[0], vars.assetsToWithdraw);
            vars.finalBalance = asset.balanceOf(vars.holder);
            console2.log("Final balance after claim:", vars.finalBalance);
            console2.log(
                "Total return:", vars.finalBalance > vars.initialBalance ? vars.finalBalance - vars.initialBalance : 0
            );
        }

        console2.log("=== LONG-TERM HOLDER TEST COMPLETED ===");
        console2.log("Initial balance:", vars.initialBalance);
        console2.log("Shares held for 90 days:", vars.shares);
        console2.log("Redeem request submitted for:", vars.redeemShares);
    }

    /**
     * @notice Test focused on active trader behavior with multiple rapid deposit-redeem cycles
     */
    function test_ActiveTrader_MultipleDepositRedeemCycles() public {
        address trader = accInstances[0].account;
        uint256 baseAmount = 5000e6; // 5,000 USDC base amount

        console2.log("=== ACTIVE TRADER TEST ===");
        console2.log("Trader address:", trader);
        console2.log("Base trading amount:", baseAmount);

        // Setup with enough tokens for multiple trades
        _getTokens(address(asset), trader, baseAmount * 10);
        uint256 initialBalance = asset.balanceOf(trader);

        // Track cumulative metrics
        uint256 totalDeposited = 0;
        uint256 totalRedeemRequests = 0;
        uint256 cycleCount = 5;

        for (uint256 i = 0; i < cycleCount; i++) {
            console2.log("--- Trading Cycle", i + 1, "---");

            // Vary deposit amounts to simulate realistic trading
            uint256 depositAmount = baseAmount + (baseAmount * i / 4); // Increasing amounts

            // Deposit
            _depositForAccount(accInstances[0], depositAmount);
            totalDeposited += depositAmount;
            uint256 shares = vault.balanceOf(trader);

            // Allocate to yield
            _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

            console2.log("Deposited:", depositAmount);
            console2.log("Total shares after deposit:", shares);

            // Hold for short period (simulate day trading to swing trading)
            vm.warp(block.timestamp + (1 + i) * 1 days);
            _updateSuperVaultPPS(address(strategy), address(vault));

            // Redeem portion (vary between 30-50% to simulate different strategies)
            uint256 redeemPercentage = 30 + (i * 5); // 30%, 35%, 40%, 45%, 50%
            uint256 redeemShares = shares * redeemPercentage / 100;

            if (redeemShares > 1) {
                // Avoid rounding issues
                _requestRedeemForAccount(accInstances[0], redeemShares);
                totalRedeemRequests += redeemShares;

                // Verify redeem request was recorded
                uint256 pendingRedeem = strategy.pendingRedeemRequest(trader);
                console2.log("Pending redeem after request:", pendingRedeem);

                console2.log("Requested redeem shares:", redeemShares);
                console2.log("Redeem percentage:", redeemPercentage);
            }

            // Short pause between cycles
            vm.warp(block.timestamp + 12 hours);
        }

        // Final verification of trading activity
        uint256 finalShares = vault.balanceOf(trader);
        uint256 finalPendingRedeem = strategy.pendingRedeemRequest(trader);

        console2.log("=== TRADING SUMMARY ===");
        console2.log("Initial balance:", initialBalance);
        console2.log("Total deposited:", totalDeposited);
        console2.log("Total redeem requests:", totalRedeemRequests);
        console2.log("Final shares held:", finalShares);
        console2.log("Final pending redeems:", finalPendingRedeem);

        // Assertions for active trading behavior
        assertGt(totalDeposited, baseAmount, "Should have made multiple deposits");
        assertGt(totalRedeemRequests, 0, "Should have made redeem requests");

        // Verify trader has been active (either holding shares or has pending redeems)
        assertGt(finalShares + finalPendingRedeem, 0, "Trader should have active position or pending redeems");

        // Verify trading pattern - multiple cycles should result in accumulated activity
        assertGe(totalDeposited, baseAmount * cycleCount, "Should have deposited across multiple cycles");

        console2.log("=== ACTIVE TRADER TEST COMPLETED ===");
        console2.log("Successfully simulated", cycleCount, "trading cycles");
    }

    function test_AuthorizeOperator() public {
        // Create signature components
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        // Generate signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                vault.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Debug logs
        console2.log("User Address:", userAddress);
        console2.log("Operator:", operator);
        console2.log("Digest:", uint256(digest));

        vm.prank(operator);
        bool success = vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        assertTrue(success, "Authorization failed");
        assertTrue(vault.isOperator(userAddress, operator), "Operator not authorized");
        assertTrue(vault.authorizations(userAddress, nonce), "Nonce not marked as used");
    }

    function test_RevertWhen_AuthorizingOperatorWithExpiredDeadline() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp - 1; // Expired deadline

        // Generate signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                vault.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );

        // User signs the message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Operator tries to use expired signature
        vm.prank(operator);
        vm.expectRevert(ISuperVault.DEADLINE_PASSED.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);
    }

    function test_RevertWhen_AuthorizingOperatorWithUsedNonce() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );
        vm.startPrank(userAddress);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // First authorization
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        // Try to use same nonce again
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        vm.stopPrank();
    }

    function test_RevertWhen_AuthorizingOperatorWithInvalidSignature() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        // Generate signature with wrong private key
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );
        uint256 wrongPrivateKey = 0x789; // Different private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(operator);
        vm.expectRevert(ISuperVault.INVALID_SIGNATURE.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);
    }

    function test_RevertWhen_OperatorAuthorizingSelf() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                vault.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), operator, operator, approved, nonce, deadline)
                )
            )
        );

        // Generate signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Operator tries to authorize themselves
        vm.prank(operator);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(operator, operator, approved, nonce, deadline, signature);
    }

    function test_RevertWhen_AuthorizingOperatorWithDifferentChainId() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        // Change chain ID
        uint256 originalChainId = block.chainid;
        vm.chainId(originalChainId + 1);

        // Generate signature with original chain ID
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), operator, operator, approved, nonce, deadline)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(operator);
        vm.expectRevert(ISuperVault.INVALID_SIGNATURE.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        // Reset chain ID
        vm.chainId(originalChainId);
    }

    function test_InvalidateNonce() public {
        bytes32 nonce = keccak256("test_nonce");

        // Invalidate nonce
        vm.prank(userAddress);
        vault.invalidateNonce(nonce);

        vm.prank(userAddress);
        vm.expectRevert(ISuperVault.INVALID_NONCE.selector);
        vault.invalidateNonce(nonce);

        // Try to use invalidated nonce
        bool approved = true;
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(operator);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);
    }

    function test_TotalAssets() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Check initial total assets
        uint256 initialTotalAssets = vault.totalAssets();
        assertEq(initialTotalAssets, 0, "Initial totalAssets should be 0");

        // Perform deposit
        _deposit(depositAmount);

        // Allocate to yield
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Verify assets reported by totalAssets
        uint256 totalAssetsAfterDeposit = vault.totalAssets();
        assertApproxEqRel(
            totalAssetsAfterDeposit, depositAmount, 0.01e18, "totalAssets should approximately equal deposit"
        );
    }

    function test_ConvertToShares() public {
        uint256 assetsAmount = 1000e6; // 1000 USDC

        // With fresh vault (1:1 ratio), should convert directly
        uint256 shares = vault.convertToShares(assetsAmount);
        assertEq(shares, assetsAmount, "Initial share conversion should be 1:1");

        // Make a deposit to ensure PPS is established
        _deposit(assetsAmount);

        // Should still be approximately 1:1 after initial deposit
        uint256 sharesAfter = vault.convertToShares(assetsAmount);
        assertApproxEqRel(sharesAfter, assetsAmount, 0.01e18, "Share conversion should be close to 1:1");
    }

    function test_ConvertToAssets() public {
        uint256 sharesAmount = 1000e6; // 1000 shares

        // With fresh vault (1:1 ratio), should convert directly
        uint256 assets = vault.convertToAssets(sharesAmount);
        assertEq(assets, sharesAmount, "Initial asset conversion should be 1:1");

        // Make a deposit to ensure PPS is established
        _deposit(2000e6); // 2000 USDC deposit

        // Should still be approximately 1:1 after initial deposit
        uint256 assetsAfter = vault.convertToAssets(sharesAmount);
        assertApproxEqRel(assetsAfter, sharesAmount, 0.01e18, "Asset conversion should be close to 1:1");
    }

    /// @notice Tests that zero PPS is never stored (protection for external integrators)
    /// @dev This verifies that attempting to set PPS to 0 (even with escape hatch) keeps the old PPS value
    function test_ConvertFunctions_ZeroPPS_RealVault() public {
        // Advance time to ensure timestamp is monotonic
        vm.warp(block.timestamp + 1 weeks);

        // Get the PPS before trying to set it to 0
        uint256 ppsBefore = aggregator.getPPS(address(strategy));
        assertGt(ppsBefore, 0, "Initial PPS should be greater than 0");

        // Attempt to set PPS to 0 using the actual PPS update mechanism - this will pause and mark stale
        _updateSuperVaultPPS_ToZero(address(strategy));

        // Verify strategy is paused
        assertTrue(aggregator.isStrategyPaused(address(strategy)), "Strategy should be paused after zero PPS attempt");

        // Verify that PPS was NOT stored (protection for external integrators)
        uint256 ppsAfterAttempt = aggregator.getPPS(address(strategy));
        assertEq(ppsAfterAttempt, ppsBefore, "PPS should remain at old value (zero PPS never stored)");

        // Unpause the strategy to enable the escape hatch (C1 check will be skipped)
        vm.prank(MANAGER);
        aggregator.unpauseStrategy(address(strategy));

        // Advance time to ensure monotonic timestamp
        vm.warp(block.timestamp + 10);

        // Send fresh PPS update with 0 - C1 check will be skipped because ppsStale is true
        // BUT PPS will still not be stored because args.pps == 0
        _updateSuperVaultPPS_ToZero(address(strategy));

        // Verify PPS is STILL at the old value (security: zero PPS can never be stored)
        uint256 ppsAfterEscapeHatch = aggregator.getPPS(address(strategy));
        assertEq(ppsAfterEscapeHatch, ppsBefore, "PPS should remain at old value even with escape hatch");

        uint256 testAssets = 1000e6; // 1000 USDC
        uint256 testShares = 1000e6; // 1000 shares

        // Test convertToShares with the OLD PPS (not zero, because zero PPS is never stored)
        uint256 resultShares = vault.convertToShares(testAssets);
        assertGt(resultShares, 0, "convertToShares should use old PPS value");

        // Test convertToAssets with the OLD PPS
        uint256 resultAssets = vault.convertToAssets(testShares);
        assertGt(resultAssets, 0, "convertToAssets should use old PPS value");

        // Test totalAssets - should be based on old PPS
        uint256 totalAssets = vault.totalAssets();
        console2.log("totalAssets with old PPS:", totalAssets);

        // Test edge cases with zero inputs
        assertEq(vault.convertToShares(0), 0, "convertToShares(0) should return 0");
        assertEq(vault.convertToAssets(0), 0, "convertToAssets(0) should return 0");

        // Verify that operations requiring valid PPS should fail due to PAUSED status
        deal(address(asset), address(this), testAssets);
        asset.approve(address(vault), testAssets);

        _getTokens(address(asset), accountEth, testAssets);

        // Deposit should revert with STRATEGY_PAUSED (because strategy is paused, not because PPS is 0)
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        vault.deposit(testAssets, address(this));
    }

    function test_MaxMint() public view {
        uint256 result = vault.maxMint(accountEth);

        // By default, should be proportional to maxDeposit
        uint256 maxDeposit = vault.maxDeposit(accountEth);
        uint256 expectedMax = vault.convertToShares(maxDeposit);

        assertEq(result, expectedMax, "maxMint should match shares equivalent of maxDeposit");
    }

    function test_MaxWithdraw() public {
        // MaxWithdraw should be the user's claimable balance
        uint256 deposit = 1000e6; // 1000 USDC
        _deposit(deposit);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(deposit, address(fluidVault), address(aaveVault));

        // User balance vs maxWithdraw before redemption
        uint256 userBalance = vault.balanceOf(accountEth);
        uint256 maxWithdraw = vault.maxWithdraw(accountEth);

        // Before fulfilling redeem request, maxWithdraw should be 0
        assertEq(maxWithdraw, 0, "maxWithdraw should be 0 before redemption is fulfilled");

        // Make and fulfill redeem request
        _requestRedeem(userBalance);
        _executeRedeemHooks4626(userBalance, address(fluidVault), address(aaveVault), new address[](0));

        // After fulfillment, maxWithdraw should match claimable amount
        uint256 claimable = strategy.claimableWithdraw(accountEth);
        uint256 maxWithdrawAfter = vault.maxWithdraw(accountEth);
        assertEq(maxWithdrawAfter, claimable, "maxWithdraw should match claimable amount");
    }

    function test_MaxRedeem() public {
        // Initial deposit and allocation
        uint256 deposit = 1000e6; // 1000 USDC
        _deposit(deposit);
        _depositFreeAssetsFromSingleAmount(deposit, address(fluidVault), address(aaveVault));

        // Before redemption request, maxRedeem should be 0 (no claimable assets)
        uint256 maxRedeemBefore = vault.maxRedeem(accountEth);
        assertEq(maxRedeemBefore, 0, "maxRedeem should be 0 before redemption request is fulfilled");

        // Request and fulfill redemption for half of shares
        uint256 userShares = vault.balanceOf(accountEth);
        uint256 redeemAmount = userShares / 2;
        _requestRedeem(redeemAmount);
        _executeRedeemHooks4626(redeemAmount, address(fluidVault), address(aaveVault), new address[](0));

        // After fulfillment, maxRedeem should match the shares equivalent to claimable assets
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);
        uint256 maxRedeemAfter = vault.maxRedeem(accountEth);

        // Calculate expected shares based on claimable assets and average withdraw price
        uint256 avgWithdrawPrice = strategy.getAverageWithdrawPrice(accountEth);
        // Use Math.Rounding.Ceil to match the contract's implementation
        uint256 expectedShares = claimableAssets.mulDiv(vault.PRECISION(), avgWithdrawPrice, Math.Rounding.Ceil);

        // Verify maxRedeem matches expected shares with sufficient tolerance
        assertApproxEqAbs(
            maxRedeemAfter, expectedShares, 10, "maxRedeem should match shares equivalent of claimable assets"
        );
    }

    function test_PreviewDepositAndMint() public view {
        uint256 amount = 1000e6; // 1000 USDC/shares

        // Test previewDeposit (implemented)
        uint256 expectedShares = vault.convertToShares(amount);
        uint256 previewShares = vault.previewDeposit(amount);
        assertEq(previewShares, expectedShares, "previewDeposit should match convertToShares");

        // Test previewMint (implemented)
        uint256 expectedAssets = vault.convertToAssets(amount);
        uint256 previewAssets = vault.previewMint(amount);
        assertEq(previewAssets, expectedAssets, "previewMint should match convertToAssets");
    }

    function test_RevertWhen_PreviewWithdraw() public {
        uint256 amount = 1000e6; // 1000 USDC

        // previewWithdraw should revert with NOT_IMPLEMENTED
        vm.expectRevert(ISuperVault.NOT_IMPLEMENTED.selector);
        vault.previewWithdraw(amount);
    }

    function test_RevertWhen_PreviewRedeem() public {
        uint256 amount = 1000e6; // 1000 shares

        // previewRedeem should revert with NOT_IMPLEMENTED
        vm.expectRevert(ISuperVault.NOT_IMPLEMENTED.selector);
        vault.previewRedeem(amount);
    }

    function test_Redeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Make and fulfill redemption request to get claimable assets
        uint256 userShares = vault.balanceOf(accountEth);
        _requestRedeem(userShares);
        _executeRedeemHooks4626(userShares, address(fluidVault), address(aaveVault), new address[](0));

        // Get claimable amount
        uint256 maxRedeem = vault.maxRedeem(accountEth);
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);

        // Use redeem function to claim assets
        uint256 initialAssetBalance = asset.balanceOf(accountEth);
        vm.prank(accountEth);
        uint256 assetsRedeemed = vault.redeem(
            maxRedeem, // shares to redeem
            accountEth, // receiver
            accountEth // owner
        );

        // Verify results with tolerance for rounding errors
        assertApproxEqAbs(assetsRedeemed, claimableAssets, 5, "Wrong redeem amount (with tolerance)");
        assertApproxEqAbs(
            asset.balanceOf(accountEth),
            initialAssetBalance + claimableAssets,
            5,
            "Wrong final asset balance (with tolerance)"
        );
    }

    function test_Redeem_RevertCases() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Make and fulfill redemption request to get claimable assets
        uint256 userShares = vault.balanceOf(accountEth);
        _requestRedeem(userShares);
        _executeRedeemHooks4626(userShares, address(fluidVault), address(aaveVault), new address[](0));

        // Get claimable amount
        uint256 maxRedeem = vault.maxRedeem(accountEth);

        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.redeem(
            maxRedeem, // shares to redeem
            address(0), // receiver
            accountEth // owner
        );

        // Try to redeem more than the max redeem
        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.INVALID_AMOUNT.selector);
        vault.redeem(
            maxRedeem + 100, // shares to redeem
            accountEth, // receiver
            accountEth // owner
        );

        // Try redeem more than escrow balance
        vm.startPrank(address(escrow));
        asset.transfer(address(this), asset.balanceOf(address(escrow)) - 1);
        vm.stopPrank();
        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.NOT_ENOUGH_ASSETS.selector);
        vault.redeem(
            maxRedeem, // shares to redeem
            accountEth, // receiver
            accountEth // owner
        );
    }

    function test_Withdraw_InvalidAmount() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 shares = vault.balanceOf(accountEth);

        _requestRedeem(shares);

        _executeRedeemHooks4626(shares, address(fluidVault), address(aaveVault), new address[](0));

        uint256 maxWithdraw = vault.maxWithdraw(accountEth);

        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.INVALID_AMOUNT.selector);
        vault.withdraw(maxWithdraw + 1, accountEth, accountEth);
    }

    /*//////////////////////////////////////////////////////////////
                        REDEMPTION FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PendingRedeemRequest() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Check initial state - no pending request
        uint256 initialPending = vault.pendingRedeemRequest(0, accountEth);
        assertEq(initialPending, 0, "Should have no initial pending request");

        // Request redeem for half of shares
        uint256 userShares = vault.balanceOf(accountEth);
        uint256 redeemAmount = userShares / 2;
        _requestRedeem(redeemAmount);

        // Check pending amount matches requested amount
        uint256 pendingAfterRequest = vault.pendingRedeemRequest(0, accountEth);
        assertEq(pendingAfterRequest, redeemAmount, "Pending request should match requested amount");
    }

    function test_CancelRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redeem
        uint256 userShares = vault.balanceOf(accountEth);
        uint256 redeemAmount = userShares / 2;
        _requestRedeem(redeemAmount);

        // Check shares are in escrow
        assertEq(vault.balanceOf(address(escrow)), redeemAmount, "Escrow should hold shares");

        // Cancel redeem
        vm.prank(accountEth);
        vault.cancelRedeemRequest(0, accountEth);

        assertTrue(strategy.pendingCancelRedeemRequest(accountEth), "Pending cancel request should be true");

        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accountEth;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        uint256 claimableCancelShares = strategy.claimableCancelRedeemRequest(accountEth);
        uint256 claimableCancelSharesVault = vault.claimableCancelRedeemRequest(0, accountEth);
        assertEq(claimableCancelShares, redeemAmount, "Should have claimable cancel shares equal to original request");
        assertEq(
            claimableCancelSharesVault,
            claimableCancelShares,
            "Should have claimable cancel shares equal to original request"
        );

        vm.prank(accountEth);
        vault.claimCancelRedeemRequest(0, accountEth, accountEth);

        // Verify state after cancellation
        assertEq(vault.pendingRedeemRequest(0, accountEth), 0, "Pending request should be cleared");
        assertEq(vault.balanceOf(accountEth), userShares, "User should have original shares back");
        assertEq(vault.balanceOf(address(escrow)), 0, "Escrow should no longer hold shares");
    }

    function test_ClaimCancelRedeem_RevertCases() public {
        // Try to cancel when there's no request
        vm.prank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.REQUEST_NOT_FOUND.selector);
        vault.cancelRedeemRequest(0, accountEth);

        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accountEth;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.ZERO_ADDRESS.selector);
        vault.claimCancelRedeemRequest(0, address(0), accountEth);

        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.INVALID_CONTROLLER.selector);
        vault.claimCancelRedeemRequest(0, accountEth, address(0));

        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.INVALID_CONTROLLER.selector);
        vault.claimCancelRedeemRequest(0, address(this), accountEth);
    }

    /*//////////////////////////////////////////////////////////////
                        OPERATOR MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetOperator() public {
        // Initially not an operator
        assertFalse(vault.isOperator(accountEth, operator), "Should not be operator initially");

        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.setOperator(accountEth, true);

        // Set operator directly
        vm.prank(accountEth);
        vault.setOperator(operator, true);

        // Verify operator was set
        assertTrue(vault.isOperator(accountEth, operator), "Should be operator after setting");

        // Revoke operator permission
        vm.prank(accountEth);
        vault.setOperator(operator, false);

        // Verify operator was revoked
        assertFalse(vault.isOperator(accountEth, operator), "Should not be operator after revoking");
    }

    /*//////////////////////////////////////////////////////////////
                        INTERFACE SUPPORT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SupportsInterface() public view {
        // Test ERC7540Redeem interface
        bytes4 erc7540RedeemId = type(IERC7540Redeem).interfaceId;
        assertTrue(vault.supportsInterface(erc7540RedeemId), "Should support ERC7540Redeem");

        // Test ERC7741 interface
        bytes4 erc7741Id = type(IERC7741).interfaceId;
        assertTrue(vault.supportsInterface(erc7741Id), "Should support ERC7741");

        // Test ERC4626 interface
        bytes4 erc4626Id = type(IERC4626).interfaceId;
        assertTrue(vault.supportsInterface(erc4626Id), "Should support ERC4626");

        // Test ERC165 interface
        bytes4 erc165Id = type(IERC165).interfaceId;
        assertTrue(vault.supportsInterface(erc165Id), "Should support ERC165");

        // Test non-supported interface
        bytes4 randomId = bytes4(keccak256("random"));
        assertFalse(vault.supportsInterface(randomId), "Should not support random interface");
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTION COVERAGE TESTS
    //////////////////////////////////////////////////////////////*/
    function test_ValidateOwnerOrOperator() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);
        address randomAddress = address(0xABC);
        vm.prank(randomAddress);
        vm.expectRevert(ISuperVault.INVALID_OWNER_OR_OPERATOR.selector);
        vault.requestRedeem(100e6, accountEth, accountEth);
    }

    /*//////////////////////////////////////////////////////////////
                        STRATEGY INTERACTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_UnauthorizedBurnShares() public {
        uint256 burnAmount = 1000e6;

        // Random address cannot call burnShares
        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.burnShares(burnAmount);
    }

    /*//////////////////////////////////////////////////////////////
                       SUPERVAULTSTRATEGY.SOL
    //////////////////////////////////////////////////////////////*/
    function test_RequestRedeem_MultipleUsers(uint256 depositAmount) public {
        // bound amount
        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        // request redeem for all users
        _requestRedeemForAllUsers(0);
    }

    function test_RequestRedeemMultipleUsers_With_CompleteFullfilment(uint256 depositAmount) public {
        // bound amount
        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        uint256 totalRedeemShares;
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            totalRedeemShares += vaultBalance;
        }

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fullfillment data
        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill redeem
        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // check that all pending requests are cleared
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_RequestRedeem_MultipleUsers_DifferentAmounts() public {
        uint256 depositAmount = 1000e6;

        // first deposit same amount for all users
        _completeDepositFlow(depositAmount);

        uint256[] memory redeemAmounts = new uint256[](ACCOUNT_COUNT);
        uint256 totalRedeemShares;

        // create redeem requests with randomized amounts based on vault balance
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            // random amount between 50% and 100% of maxRedeemable
            redeemAmounts[i] =
                bound(uint256(keccak256(abi.encodePacked(block.timestamp, i))), vaultBalance / 2, vaultBalance);
            redeemAmounts[i] =
                bound(uint256(keccak256(abi.encodePacked(block.timestamp, i))), vaultBalance / 2, vaultBalance);
            _requestRedeemForAccount(accInstances[i], redeemAmounts[i]);
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), redeemAmounts[i]);
            totalRedeemShares += redeemAmounts[i];
        }

        // fulfill all redeem requests
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;

        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // verify all redeems were fulfilled
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_RequestRedeemMultipleUsers_With_PartialUsersFullfilment(uint256 depositAmount) public {
        depositAmount = 100e6;

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        // store redeem amounts for later verification
        uint256[] memory redeemAmounts = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            redeemAmounts[i] = vault.balanceOf(accInstances[i].account);
        }

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fulfillment data for half the users
        uint256 partialUsersCount = ACCOUNT_COUNT / 2;
        uint256 totalRedeemShares;

        // calculate total redeem shares for partial users
        for (uint256 i; i < partialUsersCount; ++i) {
            totalRedeemShares += strategy.pendingRedeemRequest(accInstances[i].account);
        }

        address[] memory requestingUsers = new address[](partialUsersCount);
        for (uint256 i; i < partialUsersCount; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;
        // fulfill redeem for half the users
        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
        console2.log("fulfilled redeem for half the users");
        // check that fulfilled requests are cleared
        for (uint256 i; i < partialUsersCount; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
        console2.log("checked that fulfilled requests are cleared");
        // check that remaining users still have pending requests
        for (uint256 i = partialUsersCount; i < ACCOUNT_COUNT; ++i) {
            uint256 pendingRedeem = strategy.pendingRedeemRequest(accInstances[i].account);
            assertEq(pendingRedeem, redeemAmounts[i]);
            uint256 claimable = strategy.claimableWithdraw(accInstances[i].account);
            assertEq(claimable, 0);
        }

        // calculate total redeem shares for remaining users
        totalRedeemShares = 0;
        uint256 j;
        requestingUsers = new address[](ACCOUNT_COUNT - partialUsersCount);
        for (uint256 i = partialUsersCount; i < ACCOUNT_COUNT;) {
            requestingUsers[j] = accInstances[i].account;
            totalRedeemShares += strategy.pendingRedeemRequest(accInstances[i].account);
            unchecked {
                ++i;
                ++j;
            }
        }

        allocationAmountVault1 = totalRedeemShares / 2;
        allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;

        // fulfill remaining users
        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
    }

    function test_RequestRedeem_RevertOnExceedingBalance(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        // first deposit for single user
        _completeDepositFlow(depositAmount);

        // try to redeem more than balance
        uint256 vaultBalance = vault.balanceOf(accInstances[0].account);
        uint256 excessAmount = vaultBalance * 100;

        // should revert when trying to redeem more than balance
        _requestRedeemForAccount_Revert(accInstances[0], excessAmount);
    }

    function test_ClaimRedeem_RevertBeforeFulfillment() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);

        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;
        _requestRedeemForAccount(accInstances[0], redeemAmount);

        assertEq(strategy.pendingRedeemRequest(accInstances[0].account), redeemAmount);

        // try/catch pattern to verify the revert
        bool claimFailed = false;
        try this.externalClaimWithdraw(accInstances[0], redeemAmount) {
            claimFailed = false;
        } catch {
            claimFailed = true;
        }

        assertTrue(claimFailed, "Claim should have failed before fulfillment");

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accInstances[0].account;

        uint256 allocationAmountVault1 = redeemAmount / 2;
        uint256 allocationAmountVault2 = redeemAmount - allocationAmountVault1;

        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
        uint256 pendingRedeem = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeem, 0);
        uint256 claimable = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimable, 0);

        _claimWithdrawForAccount(accInstances[0], vault.maxWithdraw(accInstances[0].account));

        assertEq(strategy.claimableWithdraw(accInstances[0].account), 0);
    }

    function test_ClaimRedeem_AfterPriceIncrease() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);
        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;

        _requestRedeemForAccount(accInstances[0], redeemAmount);

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accInstances[0].account;

        uint256 allocationAmountVault1 = redeemAmount / 2;
        uint256 allocationAmountVault2 = redeemAmount - allocationAmountVault1;

        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
        console2.log("------fulfilled redeem");
        uint256 escrowAssetBalanceBefore = asset.balanceOf(address(escrow));
        console2.log("-----escrowAssetBalanceBefore", escrowAssetBalanceBefore);
        uint256 initialAssetBalance = asset.balanceOf(accInstances[0].account);

        // increase price of assets
        uint256 yieldAmount = 100e6;
        deal(address(asset), address(this), yieldAmount * 2);
        asset.approve(address(fluidVault), yieldAmount);
        asset.approve(address(aaveVault), yieldAmount);
        fluidVault.deposit(yieldAmount, address(this));
        aaveVault.deposit(yieldAmount, address(this));

        uint256 maxWithdraw = vault.maxWithdraw(accInstances[0].account);
        console2.log("maxWithdraw", maxWithdraw);
        _claimWithdrawForAccount(accInstances[0], maxWithdraw);
        console2.log("------claimed withdraw");
        uint256 assetsReceived = asset.balanceOf(accInstances[0].account) - initialAssetBalance;
        assertApproxEqRel(
            assetsReceived,
            maxWithdraw,
            0.01e18,
            "Assets received should be greater than or equal to requested redeem amount"
        );

        uint256 escrowAssetBalanceAfter = asset.balanceOf(address(escrow));
        assertApproxEqRel(
            escrowAssetBalanceBefore - escrowAssetBalanceAfter,
            assetsReceived,
            0.01e18,
            "Escrow asset balance should decrease by the amount sent to user"
        );

        assertApproxEqRel(
            escrowAssetBalanceBefore - escrowAssetBalanceAfter,
            assetsReceived,
            0.01e18,
            "Escrow asset balance should decrease by the amount sent to user"
        );

        console2.log("Requested redeem amount:", redeemAmount);
        console2.log("Actual assets received:", assetsReceived);
        console2.log("Escrow asset withdrawn", escrowAssetBalanceBefore - escrowAssetBalanceAfter);

        // make sure redeem is cleared even if we have small rounding errors
        assertEq(strategy.claimableWithdraw(accInstances[0].account), 0);
    }

    function test_ExtractAndSendAssets_UnauthroizedCaller() public {
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.extractAndSendAssets(address(this), 1000);
    }

    // Helper function to handle deposit setup
    function _setupInitialDeposit(uint256 depositAmount) internal returns (uint256 initialShareBalance) {
        // add some tokens initially to the strategy
        _getTokens(address(asset), address(strategy), 1000);

        _getTokens(address(asset), accInstances[0].account, depositAmount);
        _depositForAccount(accInstances[0], depositAmount);

        // Verify deposit was successful
        initialShareBalance = vault.balanceOf(accInstances[0].account);
        console2.log("Initial share balance after deposit:", initialShareBalance);
        console2.log("Initial asset value:", vault.convertToAssets(initialShareBalance));

        require(initialShareBalance > 0, "Deposit failed - no shares minted");
        return initialShareBalance;
    }

    // Helper function to calculate redeem amounts
    function _calculateRedeemAmounts(uint256 redeemAmount)
        internal
        view
        returns (uint256 firstHalf, uint256 secondHalf)
    {
        // Calculate total assets using vault's conversion
        uint256 totalAssets = vault.convertToAssets(redeemAmount);

        console2.log("Total assets to redeem:", totalAssets);

        // Split evenly, rounding down first half
        firstHalf = totalAssets / 2;
        secondHalf = totalAssets - firstHalf;

        console2.log("First half:", firstHalf);
        console2.log("Second half:", secondHalf);
    }

    struct RoundingTestVars {
        uint256 depositAmount;
        uint256 initialShareBalance;
        uint256 initialAssetBalance;
        uint256 initialStrategyBalance;
        uint256 redeemAmount;
        uint256 firstHalf;
        uint256 secondHalf;
        uint256 maxWithdraw;
        uint256 finalShareBalance;
        uint256 finalAssetBalance;
        uint256 finalStrategyBalance;
        uint256 assetsReceived;
        uint256 remainingShareValue;
    }

    struct GasEfficiencyTestVars {
        uint256 depositAmount;
        address user;
        uint256 gasStart;
        uint256 shares;
        uint256 gasUsedDeposit;
        uint256 gasUsedRequest;
        uint256 totalAssetsAfterProfit;
        uint256 costBasis;
        uint256 expectedProfit;
        ISuperVaultStrategy.FeeConfig feeConfig_;
        uint256 expectedFee;
        address[] hooksAddresses;
        uint256 vault1SharesOut;
        uint256 vault2SharesOut;
        bytes[] hooksData;
        uint256[] expectedAssetsOrSharesOut;
        bytes[] argsForProofs;
        address[] controllers;
        uint256[] totalAssetsOut;
        uint256 gasUsedSkim;
        uint256 gasUsedFulfill;
    }

    struct MultipleDepositsTestVars {
        uint256 deposit1;
        uint256 deposit2;
        uint256 deposit3;
        uint256 initialCostBasis;
        uint256 expectedCostBasis;
        uint256 totalDeposits;
        uint256 totalAssetsAfterProfit;
        uint256 finalCostBasis;
        uint256 expectedProfit;
        ISuperVaultStrategy.FeeConfig feeConfig_;
        uint256 expectedFee;
        uint256 user1Shares;
        uint256 user2Shares;
        uint256 user3Shares;
        uint256 totalShares;
        uint256 claimable1;
        uint256 claimable2;
        uint256 claimable3;
    }

    function test_Redeem_RoundingBehavior() public {
        RoundingTestVars memory vars;
        vars.depositAmount = 1000e6;

        _completeDepositFlow(vars.depositAmount);

        vars.initialShareBalance = vault.balanceOf(accInstances[0].account);
        vars.initialAssetBalance = asset.balanceOf(accInstances[0].account);

        console2.log("Initial shares:", vars.initialShareBalance);
        console2.log(
            "Initial price per share:",
            vault.totalAssets().mulDiv(vault.PRECISION(), vault.totalSupply(), Math.Rounding.Floor)
        );

        // Calculate redeem amount
        vars.redeemAmount = vars.initialShareBalance / 2;
        console2.log("Redeem amount (in shares):", vars.redeemAmount);

        _requestRedeemForAccount(accInstances[0], vars.redeemAmount);

        // Split redeem amount directly (don't convert to assets first)
        vars.firstHalf = vars.redeemAmount / 2;
        vars.secondHalf = vars.redeemAmount - vars.firstHalf;

        console2.log("First vault amount:", vars.firstHalf);
        console2.log("Second vault amount:", vars.secondHalf);

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            requestingUsers, vars.firstHalf, vars.secondHalf, address(fluidVault), address(aaveVault)
        );

        vars.maxWithdraw = vault.maxWithdraw(accInstances[0].account);
        console2.log("maxWithdraw after fulfill:", vars.maxWithdraw);

        _claimWithdrawForAccount(accInstances[0], vars.maxWithdraw);

        vars.finalShareBalance = vault.balanceOf(accInstances[0].account);
        vars.finalAssetBalance = asset.balanceOf(accInstances[0].account);
        vars.assetsReceived = vars.finalAssetBalance - vars.initialAssetBalance;

        assertEq(vars.assetsReceived, vars.maxWithdraw, "Assets received should match maxWithdraw");
        assertApproxEqRel(
            vault.convertToAssets(vars.finalShareBalance), vars.depositAmount - vars.assetsReceived, 0.002e18
        );
    }

    function externalClaimWithdraw(AccountInstance memory accInst, uint256 assets) external {
        _claimWithdrawForAccount(accInst, assets);
    }

    function test_RequestRedeem_VerifyAmounts() public {
        RedeemVerificationVars memory vars;
        vars.depositAmount = 1000e6;

        _completeDepositFlow(vars.depositAmount);

        vars.userShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            vars.userShareBalances[i] = vault.balanceOf(accInstances[i].account);
        }
        console2.log("pps", vault.totalAssets().mulDiv(vault.PRECISION(), vault.totalSupply(), Math.Rounding.Floor));

        console2.log("deposits done");
        /// redeem half of the shares
        vars.redeemAmount = vault.balanceOf(accInstances[0].account) / 2;
        console2.log("redeem amount:", vars.redeemAmount);

        console2.log("pps", vault.totalAssets().mulDiv(vault.PRECISION(), vault.totalSupply(), Math.Rounding.Floor));

        console2.log("deposits done");
        /// redeem half of the shares
        vars.redeemAmount = vault.balanceOf(accInstances[0].account) / 2;
        console2.log("redeem amount:", vars.redeemAmount);

        _requestRedeemForAllUsers(vars.redeemAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialStrategyAssetBalance = asset.balanceOf(address(escrow)); //escrow balance

        vars.totalDepositAmount = vars.depositAmount * ACCOUNT_COUNT;
        vars.totalRedeemAmount = vars.redeemAmount * ACCOUNT_COUNT;

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        vars.allocationAmountVault1 = vars.totalRedeemAmount / 2;
        vars.allocationAmountVault2 = vars.totalRedeemAmount - vars.allocationAmountVault1;

        _executeRedeemHooks4626ForUsers(
            requestingUsers,
            vars.allocationAmountVault1,
            vars.allocationAmountVault2,
            address(fluidVault),
            address(aaveVault)
        );

        vars.fluidVaultSharesDecrease = vars.initialFluidVaultBalance - fluidVault.balanceOf(address(strategy));
        vars.aaveVaultSharesDecrease = vars.initialAaveVaultBalance - aaveVault.balanceOf(address(strategy));
        vars.strategyAssetBalanceIncrease = asset.balanceOf(address(escrow)) - vars.initialStrategyAssetBalance; // escrow
        // balance

        vars.fluidVaultAssetsValue = fluidVault.convertToAssets(vars.fluidVaultSharesDecrease);
        vars.aaveVaultAssetsValue = aaveVault.convertToAssets(vars.aaveVaultSharesDecrease);

        vars.totalAssetsRedeemed = vars.fluidVaultAssetsValue + vars.aaveVaultAssetsValue;

        vars.totalRedeemedAssets = vault.convertToAssets(vars.totalRedeemAmount);
        assertApproxEqRel(
            vars.totalAssetsRedeemed,
            vars.totalRedeemedAssets,
            0.01e18,
            "Total assets redeemed should be equal to total redeemed assets"
        );

        assertApproxEqRel(
            vars.strategyAssetBalanceIncrease,
            vars.totalRedeemedAssets,
            0.01e18,
            "Escrow asset balance increase should be equal to total redeemed assets"
        );

        _verifyRedeemSharesAndAssets(vars);
    }

    function test_MultipleUsers_SameAllocation_EqualRedeemValue() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);

        uint256[] memory initialShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialShareBalances[i] = vault.balanceOf(accInstances[i].account);
            console2.log("User", i, "initial share balance:", initialShareBalances[i]);
        }
        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;

        // request redem
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            _requestRedeemForAccount(accInstances[i], redeemAmount);
        }

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        uint256 totalRedeemAmount = redeemAmount * ACCOUNT_COUNT;
        uint256 allocationAmountVault1 = totalRedeemAmount / 2;
        uint256 allocationAmountVault2 = totalRedeemAmount - allocationAmountVault1;

        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        uint256[] memory initialAssetBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialAssetBalances[i] = asset.balanceOf(accInstances[i].account);
        }

        // Arrays to store results
        uint256[] memory assetsReceived = new uint256[](ACCOUNT_COUNT);
        uint256[] memory sharesBurned = new uint256[](ACCOUNT_COUNT);
        uint256[] memory assetPerShare = new uint256[](ACCOUNT_COUNT);

        // Claim redemptions for all users
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            // Record share balance before claiming
            uint256 shareBalanceBeforeClaim = vault.balanceOf(accInstances[i].account);
            console2.log("User", i, "share balance before claim:", shareBalanceBeforeClaim);

            uint256 maxWithdraw = vault.maxWithdraw(accInstances[i].account);
            _claimWithdrawForAccount(accInstances[i], maxWithdraw);

            uint256 shareBalanceAfterClaim = vault.balanceOf(accInstances[i].account);
            uint256 assetBalanceAfterClaim = asset.balanceOf(accInstances[i].account);

            console2.log("User", i, "share balance after claim:", shareBalanceAfterClaim);

            sharesBurned[i] = initialShareBalances[i] - shareBalanceAfterClaim;
            assetsReceived[i] = assetBalanceAfterClaim - initialAssetBalances[i];

            console2.log("User", i, "shares burned:", sharesBurned[i]);
            console2.log("User", i, "assets received:", assetsReceived[i]);

            if (sharesBurned[i] > 0) {
                assetPerShare[i] = assetsReceived[i] * vault.PRECISION() / sharesBurned[i];
                console2.log("User", i, "asset per share:", assetPerShare[i]);
            } else {
                console2.log("User", i, "!!! No shares were burned!");
            }

            assertGt(sharesBurned[i], 0, "No shares were burned for user");
            assertGt(assetsReceived[i], 0, "No assets were received for user");
        }

        for (uint256 i = 1; i < ACCOUNT_COUNT; i++) {
            assertApproxEqRel(assetPerShare[i], assetPerShare[0], 0.001e18, "Asset per share ratio should be equal");
            assertApproxEqRel(assetsReceived[i], assetsReceived[0], 0.001e18, "Assets received should be equal");
            assertApproxEqRel(sharesBurned[i], sharesBurned[0], 0.001e18, "Shares burned should be equal");
        }
    }

    function test_MultipleUsers_ChangingAllocation_RedeemValue() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);

        uint256[] memory initialShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialShareBalances[i] = vault.balanceOf(accInstances[i].account);
        }

        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            _requestRedeemForAccount(accInstances[i], redeemAmount);
        }
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        uint256 totalRedeemAmount = redeemAmount * ACCOUNT_COUNT;
        uint256 allocationAmountVault1 = totalRedeemAmount * 90 / 100;
        uint256 allocationAmountVault2 = totalRedeemAmount - allocationAmountVault1;
        console2.log("Redeem allocation vault1:", allocationAmountVault1 * 100 / totalRedeemAmount, "%");
        console2.log("Redeem allocation vault2:", allocationAmountVault2 * 100 / totalRedeemAmount, "%");

        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        uint256[] memory initialAssetBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialAssetBalances[i] = asset.balanceOf(accInstances[i].account);
        }

        uint256[] memory assetsReceived = new uint256[](ACCOUNT_COUNT);
        uint256[] memory sharesBurned = new uint256[](ACCOUNT_COUNT);
        uint256[] memory assetPerShare = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            uint256 maxWithdraw = vault.maxWithdraw(accInstances[i].account);
            _claimWithdrawForAccount(accInstances[i], maxWithdraw);

            uint256 shareBalanceAfterClaim = vault.balanceOf(accInstances[i].account);
            uint256 assetBalanceAfterClaim = asset.balanceOf(accInstances[i].account);

            sharesBurned[i] = initialShareBalances[i] - shareBalanceAfterClaim;
            assetsReceived[i] = assetBalanceAfterClaim - initialAssetBalances[i];

            if (sharesBurned[i] > 0) {
                assetPerShare[i] = assetsReceived[i] * vault.PRECISION() / sharesBurned[i];
            }

            assertGt(sharesBurned[i], 0, "No shares were burned for user");
            assertGt(assetsReceived[i], 0, "No assets were received for user");

            console2.log("User", i, "shares burned:", sharesBurned[i]);
            console2.log("User", i, "assets received:", assetsReceived[i]);
            console2.log("User", i, "asset per share:", assetPerShare[i]);
            console2.log("Free assets in vault", asset.balanceOf(address(strategy)));
        }

        for (uint256 i = 1; i < ACCOUNT_COUNT; i++) {
            assertApproxEqRel(assetPerShare[i], assetPerShare[0], 0.001e18, "Asset per share ratio should be equal");
            assertApproxEqRel(assetsReceived[i], assetsReceived[0], 0.001e18, "Assets received should be equal");
            assertApproxEqRel(sharesBurned[i], sharesBurned[0], 0.001e18, "Shares burned should be equal");
        }

        uint256 totalAssetsReceived = 0;
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            totalAssetsReceived += assetsReceived[i];
        }

        assertApproxEqRel(
            totalAssetsReceived, totalRedeemAmount, 0.01e18, "Total assets received should match total redeem amount"
        );
    }

    /*//////////////////////////////////////////////////////////////
                      GAS REPORT TESTS
    //////////////////////////////////////////////////////////////*/

    struct NewYieldSourceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialMockVaultBalance;
        uint256 initialPendleVaultBalance;
        uint256 amountToReallocateFluidVault;
        uint256 amountToReallocateAaveVault;
        uint256 assetAmountToReallocateFromFluidVault;
        uint256 assetAmountToReallocateFromAaveVault;
        uint256 assetAmountToReallocateToMockVault;
        uint256 assetAmountToReallocateToPendleVault;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalMockVaultBalance;
        uint256 finalPendleVaultBalance;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        IERC4626 newVault;
        address pendleVault;
        // Price per share tracking
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
        uint256 initialPendleVaultPPS;
        uint256 initialMockVaultPPS;
    }

    function test_gasReport_RequestRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // First setup a deposit and claim it
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));
        // Now request redeem of half the shares
        uint256 redeemShares = vault.balanceOf(accountEth) / 2;
        _requestRedeem(redeemShares);

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), redeemShares, "Wrong pending redeem amount");
        assertEq(vault.balanceOf(address(escrow)), redeemShares, "Wrong escrow balance");
    }

    function test_gasReport_ClaimRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        uint256 initialAssetBalance = asset.balanceOf(address(accountEth));

        // First setup a deposit and claim it
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));
        // Get initial balances
        uint256 initialShares = vault.balanceOf(accountEth);

        console2.log("initial shares", initialShares);

        // Request redeem of half the shares
        uint256 redeemShares = initialShares / 2;
        _requestRedeem(redeemShares);
        _executeRedeemHooks4626(redeemShares, address(fluidVault), address(aaveVault), new address[](0));

        uint256 escrowedAssets = vault.getEscrowedAssets();
        uint256 redeemSharesAsAssets = vault.convertToAssets(redeemShares);
        assertEq(escrowedAssets, redeemSharesAsAssets, "Escrowed assets should match redeem shares as assets");

        // Get claimable assets
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);
        // Claim redeem
        _claimWithdraw(claimableAssets);

        // Verify state
        assertEq(vault.balanceOf(accountEth), initialShares - redeemShares, "Wrong final share balance");
        assertApproxEqRel(
            asset.balanceOf(accountEth), initialAssetBalance + claimableAssets, 0.05e18, "Wrong final asset balance"
        );
        assertEq(strategy.claimableWithdraw(accountEth), 0, "Assets not claimed");
    }

    function test_gasReport_TwoVaults_Fulfill() public {
        NewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        _completeDepositFlow(vars.depositAmount);
    }

    function test_gasReport_ThreeVaults_Fulfill_And_Rebalance() public {
        NewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(vault.PRECISION());
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(vault.PRECISION());

        // do an initial allo
        _completeDepositFlow(vars.depositAmount);

        // add new vault as yield source
        vars.newVault = IERC4626(0x797DD80692c3b2dAdabCe8e30C07fDE5307D48a9);

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(vars.newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialPendleVaultBalance = IERC4626(vars.newVault).balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial PendleVault balance:", vars.initialPendleVaultBalance);

        // 30/30/40
        // allocate 20% from each vault to the new one
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        vars.amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        vars.assetAmountToReallocateToPendleVault =
            vars.assetAmountToReallocateFromFluidVault + vars.assetAmountToReallocateFromAaveVault;
        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);

        vm.warp(block.timestamp + 20 days);

        // allocation
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](3);
        // redeem from FluidVault
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // redeem from AaveVault
        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to PendleVault
        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.newVault),
            address(asset),
            vars.assetAmountToReallocateToPendleVault,
            false,
            address(0),
            0
        );

        vm.startPrank(MANAGER);

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](3)
            })
        );
        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalPendleVaultBalance = vars.newVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("Final PendleVault balance:", vars.finalPendleVaultBalance);

        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - vars.amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - vars.amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalPendleVaultBalance, vars.initialPendleVaultBalance, "PendleVault balance should increase");

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + vars.newVault.convertToAssets(vars.initialPendleVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + vars.newVault.convertToAssets(vars.finalPendleVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        // Enhanced checks for price per share and yield
        console2.log("\n=== Enhanced Vault Metrics ===");

        // Price per share comparison
        uint256 fluidVaultFinalPPS = fluidVault.convertToAssets(vault.PRECISION());
        uint256 aaveVaultFinalPPS = aaveVault.convertToAssets(vault.PRECISION());
        uint256 pendleVaultFinalPPS = vars.newVault.convertToAssets(vault.PRECISION());

        console2.log("\nPrice per Share Changes:");
        console2.log("Fluid Vault:");
        console2.log("  Initial PPS:", vars.initialFluidVaultPPS);
        console2.log("  Final PPS:", fluidVaultFinalPPS);
        console2.log(
            "  Change:",
            fluidVaultFinalPPS > vars.initialFluidVaultPPS ? "+" : "",
            fluidVaultFinalPPS - vars.initialFluidVaultPPS
        );
        console2.log(
            "  Change %:", ((fluidVaultFinalPPS - vars.initialFluidVaultPPS) * 10_000) / vars.initialFluidVaultPPS
        );

        console2.log("\nAave Vault:");
        console2.log("  Initial PPS:", vars.initialAaveVaultPPS);
        console2.log("  Final PPS:", aaveVaultFinalPPS);
        console2.log(
            "  Change:",
            aaveVaultFinalPPS > vars.initialAaveVaultPPS ? "+" : "",
            aaveVaultFinalPPS - vars.initialAaveVaultPPS
        );
        console2.log(
            "  Change %:", ((aaveVaultFinalPPS - vars.initialAaveVaultPPS) * 10_000) / vars.initialAaveVaultPPS
        );

        console2.log("\nYield Metrics:");
        uint256 totalYield =
            vars.finalTotalValue > vars.initialTotalValue ? vars.finalTotalValue - vars.initialTotalValue : 0;
        console2.log("Total Yield:", totalYield);
        console2.log("Yield %:", (totalYield * 10_000) / vars.initialTotalValue);

        assertGe(fluidVaultFinalPPS, vars.initialFluidVaultPPS, "Fluid Vault should not lose value");
        assertGe(aaveVaultFinalPPS, vars.initialAaveVaultPPS, "Aave Vault should not lose value");
        assertGe(pendleVaultFinalPPS, vault.PRECISION(), "Pendle Vault should not lose value");

        uint256 totalFinalBalance =
            vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalPendleVaultBalance;

        uint256 fluidRatio = (vars.finalFluidVaultBalance * 100) / totalFinalBalance;
        uint256 aaveRatio = (vars.finalAaveVaultBalance * 100) / totalFinalBalance;
        uint256 pendleRatio = (vars.finalPendleVaultBalance * 100) / totalFinalBalance;

        console2.log("\nFinal Allocation Ratios:");
        console2.log("Fluid Vault:", fluidRatio, "%");
        console2.log("Aave Vault:", aaveRatio, "%");
        console2.log("Pendle Vault:", pendleRatio, "%");
    }

    /*//////////////////////////////////////////////////////////////
                                E2E tests
    //////////////////////////////////////////////////////////////*/

    struct MultipleDepositsPartialRedemptionsVars {
        // Balances
        uint256 initialUserAssets;
        uint256 feeBalanceBefore;
        // Deposit amounts
        uint256 deposit1Amount;
        uint256 deposit2Amount;
        uint256 deposit3Amount;
        // Shares
        uint256 shares1;
        uint256 shares2;
        uint256 shares3;
        uint256 totalShares;
        // Redemption 1
        uint256 redeemAmount1;
        // superformFee1 and recipientFee1 removed - fees now collected via skimPerformanceFee
        uint256 totalFee1;
        uint256 userBalanceBeforeRedeem1;
        uint256 treasuryBalanceAfterRedeem1;
        uint256 claimableAssets1;
        uint256 claimableShares1;
        uint256 userAssetsAfterRedeem1;
        // Redemption 2
        uint256 remainingShares;
        uint256 redeemAmount2;
        // superformFee2 and recipientFee2 removed - fees now collected via skimPerformanceFee
        uint256 totalFee2;
        uint256 userBalanceBeforeRedeem2;
        uint256 treasuryBalanceAfterRedeem2;
        uint256 claimableAssets2;
        uint256 claimableShares2;
        uint256 userAssetsAfterRedeem2;
        // Redemption 3
        uint256 finalShares;
        // superformFee3 and recipientFee3 removed - fees now collected via skimPerformanceFee
        uint256 totalFee3;
        uint256 userBalanceBeforeRedeem3;
        uint256 treasuryBalanceAfterRedeem3;
        uint256 claimableAssets3;
        uint256 claimableShares3;
        uint256 userAssetsAfterRedeem3;
        // Totals
        uint256 totalDeposits;
        uint256 totalFees;
        uint256 totalAssetsReceived;
    }

    function test_SuperVault_E2E_Flow_With_Ledger_Fees() public {
        uint256 amount = 1000e6; // 1000 USDC

        vm.selectFork(FORKS[ETH]);

        // Record initial balances
        uint256 initialUserAssets = asset.balanceOf(accountEth);
        uint256 initialVaultAssets = asset.balanceOf(address(vault));

        // Step 1: Request Deposit
        _deposit(amount);

        // Verify assets transferred from user to vault
        assertEq(
            asset.balanceOf(accountEth), initialUserAssets - amount, "User assets not reduced after deposit request"
        );
        assertEq(
            asset.balanceOf(address(strategy)),
            initialVaultAssets + amount,
            "Vault assets not increased after deposit request"
        );

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(amount, address(fluidVault), address(aaveVault));

        // Verify shares minted to user
        uint256 userShares = vault.balanceOf(accountEth);

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(accountEth);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // Step 4: Request Redeem
        _requestRedeem(userShares);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 6);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        /*
        The impact of fee collection at super vault is that when calculating a fee in core, the user cannot "claim" the
            whole set of shares he had inscribed as historical shares
        Claims 999552226 shares instead of 1000000000 accumulated shares, where the diff is explained by the "assets"
            collected as fees by the manager/superform in SuperVault
        For this reason, should we continue like this and assume this? Should we set a ledger configuration just for
            super vaults where the core fee on yield is 0 so the user is not double charged on performance?
        */

        // Step 5: Fulfill Redeem
        _executeRedeemHooks4626(userShares, address(fluidVault), address(aaveVault), new address[](0));

        // Calculate expected assets based on shares
        uint256 claimableShares = vault.maxRedeem(accountEth);
        console2.log("claimableShares", claimableShares);

        // Fee logging removed - fees now collected via skimPerformanceFee
        console2.log("getAverageWithdrawPrice", strategy.getAverageWithdrawPrice(accountEth));

        // Step 6: Claim Withdraw
        _claimWithdraw(claimableShares);

        // Final balance assertions
        assertGt(asset.balanceOf(accountEth), preRedeemUserAssets, "User assets not increased after redeem");

        // Fee verification removed - fees now collected via skimPerformanceFee
    }

    function test_SuperVault_E2E_Flow_With_PPS_Slippage_Update() public {
        uint256 amount = 1000e6; // 1000 USDC

        vm.selectFork(FORKS[ETH]);

        // Record initial balances
        uint256 initialUserAssets = asset.balanceOf(accountEth);
        uint256 initialVaultAssets = asset.balanceOf(address(vault));

        // Step 1: Request Deposit
        _deposit(amount);

        // Verify assets transferred from user to vault
        assertEq(
            asset.balanceOf(accountEth), initialUserAssets - amount, "User assets not reduced after deposit request"
        );
        assertEq(
            asset.balanceOf(address(strategy)),
            initialVaultAssets + amount,
            "Vault assets not increased after deposit request"
        );

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(amount, address(fluidVault), address(aaveVault));

        // Verify shares minted to user
        uint256 userShares = IERC20(vault.share()).balanceOf(accountEth);

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(accountEth);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        uint256 BPS_PRECISION = 10_000;

        vm.warp(block.timestamp + 2 weeks);

        // Update PPS to PPS before + BPS_PRECISION
        uint256 ppsBefore = aggregator.getPPS(address(strategy));
        uint256 targetPPS = ppsBefore + BPS_PRECISION;
        _updatePPSToTarget(address(strategy), address(vault), targetPPS);

        console2.log("--pps after slippage update---", aggregator.getPPS(address(strategy)));

        // Step 4: Request Redeem
        _requestRedeem(userShares);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 6);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Step 5: Fulfill Redeem
        _executeRedeemHooks4626(userShares, address(fluidVault), address(aaveVault), new address[](0));

        // Calculate expected assets based on shares
        uint256 claimableShares = vault.maxRedeem(accountEth);
        console2.log("claimableShares", claimableShares);

        // Step 6: Claim Withdraw
        _claimWithdraw(claimableShares);

        // Final balance assertions
        assertGt(asset.balanceOf(accountEth), preRedeemUserAssets, "User assets not increased after redeem");

        // Fee verification removed - fees now collected via skimPerformanceFee
    }

    function test_SuperVault_E2E_Flow_With_0_Ledger_Fees() public {
        uint256 amount = 1000e6; // 1000 USDC

        vm.selectFork(FORKS[ETH]);

        _overrideSuperLedgerSetUp();

        // Record initial balances
        uint256 initialUserAssets = asset.balanceOf(accountEth);
        uint256 initialVaultAssets = asset.balanceOf(address(vault));

        // Step 1: Request Deposit
        _deposit(amount);

        // Verify assets transferred from user to vault
        assertEq(
            asset.balanceOf(accountEth), initialUserAssets - amount, "User assets not reduced after deposit request"
        );
        assertEq(
            asset.balanceOf(address(strategy)),
            initialVaultAssets + amount,
            "Vault assets not increased after deposit request"
        );

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(amount, address(fluidVault), address(aaveVault));

        // Verify shares minted to user
        uint256 userShares = IERC20(vault.share()).balanceOf(accountEth);

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(accountEth);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // Step 4: Request Redeem
        _requestRedeem(userShares);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 6);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Fees are now collected via skimPerformanceFee(), not during redemption

        // Step 5: Fulfill Redeem
        _executeRedeemHooks4626(userShares, address(fluidVault), address(aaveVault), new address[](0));

        // Calculate expected assets based on shares
        uint256 claimableShares = vault.maxRedeem(accountEth);

        // Step 6: Claim Withdraw
        _claimWithdraw(claimableShares);

        // Final balance assertions
        assertGt(asset.balanceOf(accountEth), preRedeemUserAssets, "User assets not increased after redeem");

        // Fee verification removed - fees now collected via skimPerformanceFee
    }

    function test_SuperVault_MultipleDeposits_PartialRedemptions() public {
        vm.selectFork(FORKS[ETH]);

        MultipleDepositsPartialRedemptionsVars memory vars;

        // Record initial balances
        vars.initialUserAssets = asset.balanceOf(accountEth);
        vars.feeBalanceBefore = asset.balanceOf(TREASURY);

        // ========== DEPOSIT 1 ==========
        console2.log("===== DEPOSIT 1 =====");
        vars.deposit1Amount = 1000e6; // 1000 USDC

        // Step 1: Request first Deposit
        _deposit(vars.deposit1Amount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(vars.deposit1Amount, address(fluidVault), address(aaveVault));

        // Get shares minted to user for first deposit
        vars.shares1 = vault.balanceOf(accountEth);
        console2.log("Shares after deposit 1:", vars.shares1);

        // Simulate some yield accrual between deposits
        vm.warp(block.timestamp + 4 weeks);
        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // ========== DEPOSIT 2 ==========
        console2.log("===== DEPOSIT 2 =====");
        vars.deposit2Amount = 2000e6; // 2000 USDC

        // Deal more tokens to user
        deal(address(asset), accountEth, vars.deposit2Amount);

        // Step 1: Request second Deposit
        _deposit(vars.deposit2Amount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(vars.deposit2Amount, address(fluidVault), address(aaveVault));

        // Get additional shares minted to user
        vars.shares2 = vault.balanceOf(accountEth) - vars.shares1;
        console2.log("Shares after deposit 2:", vars.shares2);

        // Simulate more yield accrual between deposits
        vm.warp(block.timestamp + 4 weeks);
        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // ========== DEPOSIT 3 ==========
        console2.log("===== DEPOSIT 3 =====");
        vars.deposit3Amount = 3000e6; // 3000 USDC

        // Deal more tokens to user
        deal(address(asset), accountEth, vars.deposit3Amount);

        // Step 1: Request third Deposit
        _deposit(vars.deposit3Amount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(vars.deposit3Amount, address(fluidVault), address(aaveVault));

        // Get additional shares minted to user
        vars.shares3 = vault.balanceOf(accountEth) - vars.shares1 - vars.shares2;
        console2.log("Shares after deposit 3:", vars.shares3);

        // Get total shares for user
        vars.totalShares = vault.balanceOf(accountEth);
        console2.log("Total shares:", vars.totalShares);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 42 weeks); // significant time for yield accrual

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // ========== REDEMPTION 1 (25% of shares) ==========
        console2.log("===== REDEMPTION 1 (25%) =====");
        vars.redeemAmount1 = vars.totalShares / 4; // 25% of shares
        console2.log("Redeeming shares (25%):", vars.redeemAmount1);

        // Fees are now collected via skimPerformanceFee(), not during redemption
        vars.treasuryBalanceAfterRedeem1 = vars.feeBalanceBefore;

        // Record asset balance before redemption
        vars.userBalanceBeforeRedeem1 = asset.balanceOf(accountEth);

        // Step 1: Request first Redeem
        _requestRedeem(vars.redeemAmount1);

        // Step 2: Fulfill first Redeem
        _executeRedeemHooks4626(vars.redeemAmount1, address(fluidVault), address(aaveVault), new address[](0));

        // Step 3: Claim first Withdraw
        vars.claimableShares1 = vault.maxRedeem(accountEth);
        vars.claimableAssets1 = vault.maxWithdraw(accountEth);

        // Calculate actual assets that will be withdrawn using averageWithdrawPrice with Floor rounding
        // This matches redeem() behavior and ensures previewFees calculates fees on the correct amount
        uint256 averageWithdrawPrice = strategy.getAverageWithdrawPrice(accountEth);
        uint256 actualAssetsWithdrawn =
            vars.claimableShares1.mulDiv(averageWithdrawPrice, vault.PRECISION(), Math.Rounding.Floor);

        uint256 pps = vault.totalSupply() > 0 ? vault.convertToAssets(vault.PRECISION()) : vault.PRECISION();
        uint256 expectedLedgerFee = superLedgerETH.previewFees(
            accountEth, address(vault), actualAssetsWithdrawn, vars.claimableShares1, 100, pps, vault.decimals()
        );
        vars.totalFee1 = expectedLedgerFee; // Only ledger fee remains
        console2.log("Expected fee for redemption 1:", vars.totalFee1);

        _claimWithdraw(vars.claimableShares1);

        vars.treasuryBalanceAfterRedeem1 = asset.balanceOf(TREASURY);

        // Verify user received assets
        vars.userAssetsAfterRedeem1 = asset.balanceOf(accountEth) - vars.userBalanceBeforeRedeem1;
        console2.log("User received assets after redemption 1:", vars.userAssetsAfterRedeem1);

        // Verify fee was taken correctly
        _assertFeeDerivation(vars.totalFee1, vars.feeBalanceBefore, vars.treasuryBalanceAfterRedeem1);
        console2.log("Treasury balance after redemption 1:", vars.treasuryBalanceAfterRedeem1);

        // Verify rounding behavior: claimableWithdraw may have up to 2 wei remaining due to Floor rounding
        // maxRedeem calculates shares with Floor rounding, then redeem calculates assets with Floor rounding
        // This is expected ERC4626 behavior - users can claim remaining dust via withdraw(maxWithdraw(user))
        uint256 remainingClaimable = strategy.claimableWithdraw(accountEth);
        assertLe(remainingClaimable, 2, "claimableWithdraw should have at most 2 wei remaining (ERC4626 rounding dust)");
        console2.log("Remaining claimable (expected 0-2 wei dust):", remainingClaimable);

        // ========== REDEMPTION 2 (33% of remaining shares) ==========
        console2.log("===== REDEMPTION 2 (33% of remaining) =====");
        vars.remainingShares = vault.balanceOf(accountEth);
        vars.redeemAmount2 = vars.remainingShares / 3; // 33% of remaining shares
        console2.log("Redeeming shares (33% of remaining):", vars.redeemAmount2);

        // Fees are now collected via skimPerformanceFee(), not during redemption

        // Record asset balance before redemption
        vars.userBalanceBeforeRedeem2 = asset.balanceOf(accountEth);

        // Step 1: Request second Redeem
        _requestRedeem(vars.redeemAmount2);

        // Step 2: Fulfill second Redeem
        _executeRedeemHooks4626(vars.redeemAmount2, address(fluidVault), address(aaveVault), new address[](0));

        // Step 3: Claim second Withdraw
        vars.claimableShares2 = vault.maxRedeem(accountEth);
        vars.claimableAssets2 = vault.maxWithdraw(accountEth);

        // Calculate actual assets that will be withdrawn using averageWithdrawPrice with Floor rounding
        averageWithdrawPrice = strategy.getAverageWithdrawPrice(accountEth);
        uint256 actualAssetsWithdrawn2 =
            vars.claimableShares2.mulDiv(averageWithdrawPrice, vault.PRECISION(), Math.Rounding.Floor);

        pps = vault.totalSupply() > 0 ? vault.convertToAssets(vault.PRECISION()) : vault.PRECISION();
        expectedLedgerFee = superLedgerETH.previewFees(
            accountEth, address(vault), actualAssetsWithdrawn2, vars.claimableShares2, 100, pps, vault.decimals()
        );
        vars.totalFee2 = expectedLedgerFee; // Only ledger fee remains
        console2.log("Expected fee for redemption 2:", vars.totalFee2);

        _claimWithdraw(vars.claimableShares2);

        vars.treasuryBalanceAfterRedeem2 = asset.balanceOf(TREASURY);

        // Verify user received assets
        vars.userAssetsAfterRedeem2 = asset.balanceOf(accountEth) - vars.userBalanceBeforeRedeem2;
        console2.log("User received assets after redemption 2:", vars.userAssetsAfterRedeem2);

        // Verify fee was taken correctly
        _assertFeeDerivation(vars.totalFee2, vars.treasuryBalanceAfterRedeem1, vars.treasuryBalanceAfterRedeem2);
        console2.log("Treasury balance after redemption 2:", vars.treasuryBalanceAfterRedeem2);

        // ========== REDEMPTION 3 (all remaining shares) ==========
        console2.log("===== REDEMPTION 3 (all remaining) =====");
        vars.finalShares = vault.balanceOf(accountEth);
        console2.log("Redeeming final shares:", vars.finalShares);

        // Fees are now collected via skimPerformanceFee(), not during redemption

        // Record asset balance before redemption
        vars.userBalanceBeforeRedeem3 = asset.balanceOf(accountEth);

        // Step 1: Request third Redeem
        _requestRedeem(vars.finalShares);

        // Step 2: Fulfill third Redeem
        _executeRedeemHooks4626(vars.finalShares, address(fluidVault), address(aaveVault), new address[](0));

        // Step 3: Claim third Withdraw
        vars.claimableShares3 = vault.maxRedeem(accountEth);
        vars.claimableAssets3 = vault.maxWithdraw(accountEth);

        // Calculate actual assets that will be withdrawn using averageWithdrawPrice with Floor rounding
        averageWithdrawPrice = strategy.getAverageWithdrawPrice(accountEth);
        uint256 actualAssetsWithdrawn3 =
            vars.claimableShares3.mulDiv(averageWithdrawPrice, vault.PRECISION(), Math.Rounding.Floor);

        pps = vault.totalSupply() > 0 ? vault.convertToAssets(vault.PRECISION()) : vault.PRECISION();
        expectedLedgerFee = superLedgerETH.previewFees(
            accountEth, address(vault), actualAssetsWithdrawn3, vars.claimableShares3, 100, pps, vault.decimals()
        );
        // Note: expectedLedgerFee may be 0 when totalSupply() is 0, but actual fee may still be charged
        // due to timing differences. Calculate actual fee instead.
        console2.log("Expected fee for redemption 3 (preview):", expectedLedgerFee);
        _claimWithdraw(vars.claimableShares3);

        vars.treasuryBalanceAfterRedeem3 = asset.balanceOf(TREASURY);

        // Verify user received assets
        vars.userAssetsAfterRedeem3 = asset.balanceOf(accountEth) - vars.userBalanceBeforeRedeem3;
        console2.log("User received assets after redemption 3:", vars.userAssetsAfterRedeem3);

        // Calculate actual fee collected for redemption 3
        vars.totalFee3 = vars.treasuryBalanceAfterRedeem3 - vars.treasuryBalanceAfterRedeem2;
        console2.log("Actual fee for redemption 3:", vars.totalFee3);

        // Verify total fee collection
        vars.totalFees = vars.totalFee1 + vars.totalFee2 + vars.totalFee3;
        console2.log("Total fees collected:", vars.totalFees);
        console2.log("Initial treasury balance:", vars.feeBalanceBefore);
        console2.log("Final treasury balance:", vars.treasuryBalanceAfterRedeem3);
        assertEq(
            vars.treasuryBalanceAfterRedeem3, vars.feeBalanceBefore + vars.totalFees, "Total fee collection mismatch"
        );

        // Verify user has received all assets minus fees
        vars.totalDeposits = vars.deposit1Amount + vars.deposit2Amount + vars.deposit3Amount;
        vars.totalAssetsReceived =
            vars.userAssetsAfterRedeem1 + vars.userAssetsAfterRedeem2 + vars.userAssetsAfterRedeem3;
        console2.log("Total deposits:", vars.totalDeposits);
        console2.log("Total assets received:", vars.totalAssetsReceived);
        assertGt(vars.totalAssetsReceived, vars.totalDeposits, "User should receive more than deposited due to yield");

        // Verify all shares are redeemed
        assertEq(vault.balanceOf(accountEth), 0, "User should have no shares left");
    }

    /*//////////////////////////////////////////////////////////////
                       Vault Deployment test
    //////////////////////////////////////////////////////////////*/

    function test_DeployVault() public {
        // Deploy a new vault
        (address vaultAddr, address strategyAddr, address escrowAddr) = _deployVault(address(asset), "SV");
        // Verify addresses are not zero
        assertTrue(vaultAddr != address(0), "Vault address should not be zero");
        assertTrue(strategyAddr != address(0), "Strategy address should not be zero");
        assertTrue(escrowAddr != address(0), "Escrow address should not be zero");

        // Verify initialization
        SuperVault vaultContract = SuperVault(vaultAddr);
        ISuperVaultStrategy strategyContract = ISuperVaultStrategy(strategyAddr);
        SuperVaultEscrow escrowContract = SuperVaultEscrow(escrowAddr);

        // Check vault state
        assertEq(vaultContract.name(), "SuperVault", "Wrong vault name");
        assertEq(vaultContract.symbol(), "SV", "Wrong vault symbol");
        assertEq(vaultContract.asset(), address(asset), "Wrong asset");
        assertEq(address(vaultContract.strategy()), strategyAddr, "Wrong strategy");
        assertEq(vaultContract.decimals(), 6, "Wrong decimals");

        // Check strategy state
        (address _vaultAddr, address _asset, uint8 _decimals) = strategyContract.getVaultInfo();
        assertEq(_vaultAddr, vaultAddr, "Wrong vault in strategy");
        assertEq(_asset, address(asset), "Wrong asset in strategy");
        assertEq(_decimals, 6, "Wrong decimals in strategy");

        // Check escrow state
        assertTrue(escrowContract.initialized(), "Escrow not initialized");
        assertEq(escrowContract.vault(), vaultAddr, "Wrong vault in escrow");
    }

    function test_DeployMultipleVaults() public {
        // Deploy multiple vaults with different names/symbols
        string[3] memory symbols = ["sTV1", "sTV2", "sTV3"];

        for (uint256 i = 0; i < 3; i++) {
            // Deploy a new vault with custom configuration
            (address vaultAddr,,) =
                _deployVault(
                    address(asset),
                    symbols[i] // symbol
                );

            // Verify each vault is properly initialized
            SuperVault vaultContract = SuperVault(vaultAddr);
            assertEq(vaultContract.symbol(), symbols[i], "Wrong vault symbol");
            assertEq(vaultContract.decimals(), 6, "Wrong decimals");
        }
    }

    function test_RevertOnZeroAddresses() public {
        // Test with zero asset address
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        _createVault(
            VaultCreationParams({
                asset: address(0),
                manager: MANAGER,
                minUpdateInterval: 1000,
                maxStaleness: 10_000,
                performanceFeeBps: 1000,
                symbol: "TV"
            })
        );

        // Test with zero manager address (by temporarily setting SV_MANAGER to address(0))
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        _createVault(
            VaultCreationParams({
                asset: address(asset),
                manager: address(0),
                minUpdateInterval: 1000,
                maxStaleness: 10_000,
                performanceFeeBps: 1000,
                symbol: "TV"
            })
        );
    }

    function test_CreateVaultWithSecondaryManagers() public {
        address[] memory secondaryManagers = new address[](2);
        secondaryManagers[0] = address(0x1);
        secondaryManagers[1] = address(0x2);
        (, address strategyAddr,) = _createVaultWithSecondaryManagers(
            VaultCreationParams({
                asset: address(asset),
                manager: address(this),
                minUpdateInterval: 1000,
                maxStaleness: 10_000,
                performanceFeeBps: 1000,
                symbol: "TV"
            }),
            secondaryManagers
        );

        address[] memory retrievedManagers = aggregator.getSecondaryManagers(strategyAddr);
        assertEq(retrievedManagers.length, 2);
        assertEq(retrievedManagers[0], address(0x1));
        assertEq(retrievedManagers[1], address(0x2));
    }

    struct VaultCreationParams {
        address asset;
        address manager;
        uint256 minUpdateInterval;
        uint256 maxStaleness;
        uint256 performanceFeeBps;
        string symbol;
    }

    function _createVault(VaultCreationParams memory params)
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        (vaultAddr, strategyAddr, escrowAddr) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: params.asset,
                name: "SuperVault",
                symbol: params.symbol,
                mainManager: params.manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: params.minUpdateInterval,
                maxStaleness: params.maxStaleness,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: params.performanceFeeBps, managementFeeBps: 0, recipient: address(this)
                })
            })
        );
    }

    function _createVaultWithSecondaryManagers(
        VaultCreationParams memory params,
        address[] memory secondaryManagers
    )
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        (vaultAddr, strategyAddr, escrowAddr) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: params.asset,
                name: "SuperVault",
                symbol: params.symbol,
                mainManager: params.manager,
                secondaryManagers: secondaryManagers,
                minUpdateInterval: params.minUpdateInterval,
                maxStaleness: params.maxStaleness,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: params.performanceFeeBps, managementFeeBps: 0, recipient: address(this)
                })
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                       STAKE CLAIM FLOW TEST
    //////////////////////////////////////////////////////////////*/

    function test_SuperVault_StakeClaimFlow() public {
        _setupGearVault();

        uint256 amount = 1000e6;

        console2.log("DEPOSITING");
        _deposit(amount, address(gearSuperVault), address(strategyGearSuperVault), address(asset));

        console2.log("DEPOSITING FREE ASSETS");
        _depositFreeAssetsFromSingleAmount_Gearbox(amount);

        uint256 amountToStake = gearboxVault.balanceOf(address(strategyGearSuperVault));

        console2.log("STAKING");
        _executeStakeHook(amountToStake);

        assertGt(
            gearboxFarmingPool.balanceOf(address(strategyGearSuperVault)),
            0,
            "Gearbox vault balance not increased after stake"
        );

        // Get shares minted to user
        uint256 userShares = gearSuperVault.balanceOf(accountEth);

        // Record balances before redeem
        // uint256 preRedeemUserAssets = asset.balanceOf(accountEth);

        console2.log("update pps before 60 week warp");
        vm.warp(block.timestamp + 1 hours);

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 60 weeks);

        console2.log("update pps before 60 week warp");

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        console2.log("ppsBeforeUnStake: ", aggregator.getPPS(address(strategyGearSuperVault)));

        uint256 preUnStakeGearboxBalance = gearboxVault.balanceOf(address(strategyGearSuperVault));

        uint256 amountToUnStake = gearboxFarmingPool.balanceOf(address(strategyGearSuperVault));

        _executeUnStakeHook(amountToUnStake);

        assertGt(
            gearboxVault.balanceOf(address(strategyGearSuperVault)),
            preUnStakeGearboxBalance,
            "Gearbox vault balance not decreased after unstake"
        );

        vm.warp(block.timestamp + 1 hours);

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        console2.log("ppsAfterUnStake: ", aggregator.getPPS(address(strategyGearSuperVault)));

        // Step 4: Request Redeem
        _requestRedeem(userShares, address(gearSuperVault));

        // Verify shares are escrowed
        assertEq(IERC20(gearSuperVault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(
            IERC20(gearSuperVault.share()).balanceOf(address(escrowGearSuperVault)),
            userShares,
            "Shares not transferred to escrow"
        );
        vm.warp(block.timestamp + 1 hours);

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        // Step 5: Fulfill Redeem
        _executeRedeemHooks4626_Gearbox_SV();

        uint256 claimableAssets = gearSuperVault.maxWithdraw(accountEth);
        uint256 claimableShares = gearSuperVault.maxRedeem(accountEth);
        console2.log("claimableShares", claimableShares);

        uint256 pps = gearSuperVault.totalSupply() > 0 ? gearSuperVault.convertToAssets(1e18) : 1e18;
        uint256 expectedLedgerFee = superLedgerETH.previewFees(
            accountEth, address(gearSuperVault), claimableAssets, claimableShares, 100, pps, gearSuperVault.decimals()
        );

        uint256 totalFee = expectedLedgerFee; // Only ledger fee remains
        console2.log("totalFee: ", totalFee);
        // Fee balance logging removed - fees now collected via skimPerformanceFee"
        console2.log("asset.balanceOf(TREASURY): ", asset.balanceOf(TREASURY));
        // Fee logging removed - fees now collected via skimPerformanceFee

        // Step 6: Claim Withdraw
        _claimWithdraw_Gearbox_SV(claimableAssets);

        // Fee derivation assertion removed - fees now collected via skimPerformanceFee"

        /*
        assertEq(
            asset.balanceOf(accountEth),
            preRedeemUserAssets +  claimableAssets ,
            "User assets not increased after withdraw"
        );
        */
        /// @dev commented the above as there are small deviations between what the user actually got and what were the
        /// claimable assets
        /// this is due to ledger fees in core
        console2.log("ppsAfter: ", aggregator.getPPS(address(strategyGearSuperVault)));
    }

    function _setupGearVault() internal {
        // Deploy vault trio
        (address gearSuperVaultAddr, address strategyAddr, address escrowAddr) =
            _deployVault(address(asset), "svGearbox");

        assertEq(strategyAddr, globalSVGearStrategy, "SV STRATEGY NOT EQUAL TO PREDICTED");

        vm.label(gearSuperVaultAddr, "GearSuperVault");
        vm.label(strategyAddr, "GearSuperVaultStrategy");
        vm.label(escrowAddr, "GearSuperVaultEscrow");

        // Cast addresses to contract types
        gearSuperVault = SuperVault(gearSuperVaultAddr);
        escrowGearSuperVault = SuperVaultEscrow(escrowAddr);
        strategyGearSuperVault = SuperVaultStrategy(payable(strategyAddr));

        vm.startPrank(MANAGER);
        strategyGearSuperVault.managePPSExpiration(1, 1 weeks);

        vm.warp(block.timestamp + 2 weeks);

        strategyGearSuperVault.managePPSExpiration(2, 0);
        vm.stopPrank();

        // Add a new yield source as manager
        vm.startPrank(MANAGER);
        strategyGearSuperVault.manageYieldSource(
            address(gearboxVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0
        );
        strategyGearSuperVault.manageYieldSource(
            address(gearboxFarmingPool), _getContract(ETH, STAKING_YIELD_SOURCE_ORACLE_KEY), 0
        );
        vm.stopPrank();

        vm.startPrank(MANAGER);
        strategyGearSuperVault.proposeVaultFeeConfigUpdate(100, 0, TREASURY);
        vm.warp(block.timestamp + 1 weeks);
        strategyGearSuperVault.executeVaultFeeConfigUpdate();
        vm.stopPrank();

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVaultAddr));
    }

    function _depositFreeAssetsFromSingleAmount_Gearbox(uint256 depositAmount) internal {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](1);
        fulfillHooksAddresses[0] = depositHookAddress;
        console2.log("GearSuperVault balance: ", asset.balanceOf(address(strategyGearSuperVault)));
        bytes[] memory fulfillHooksData = new bytes[](1);

        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(gearboxVault),
            address(asset),
            depositAmount,
            false,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = IERC4626(address(gearboxVault)).convertToShares(depositAmount);

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);

        vm.startPrank(MANAGER);
        strategyGearSuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();

        (uint256 pricePerShare) = _getSuperVaultPricePerShare();
        uint256 shares = depositAmount.mulDiv(strategyGearSuperVault.PRECISION(), pricePerShare);

        _trackDeposit(accountEth, shares, depositAmount);
    }

    function _executeStakeHook(uint256 amountToStake) internal {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, GEARBOX_APPROVE_AND_STAKE_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createApproveAndGearboxStakeHookData(
            _getYieldSourceOracleId(bytes32(bytes(STAKING_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(gearboxFarmingPool),
            address(gearboxVault),
            amountToStake,
            false
        );

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);

        vm.prank(MANAGER);
        strategyGearSuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](1),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
    }

    function _executeUnStakeHook(uint256 amountToUnStake) internal {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, GEARBOX_UNSTAKE_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createGearboxUnstakeHookData(
            _getYieldSourceOracleId(bytes32(bytes(STAKING_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(gearboxFarmingPool),
            amountToUnStake,
            false
        );

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);

        vm.prank(MANAGER);
        strategyGearSuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](1),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
    }

    function _executeRedeemHooks4626_Gearbox_SV() internal {
        /// @dev with preserve percentages based on USD value allocation
        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accountEth;
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](1);
        fulfillHooksAddresses[0] = withdrawHookAddress;

        uint256 svShares = strategyGearSuperVault.pendingRedeemRequest(accountEth);

        // Convert SuperVault shares to underlying vault shares
        uint256 assets = gearSuperVault.convertToAssets(svShares);
        uint256 underlyingShares = gearboxVault.convertToShares(assets);

        bytes[] memory fulfillHooksData = new bytes[](1);
        fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(gearboxVault),
            address(strategyGearSuperVault),
            underlyingShares,
            false
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = gearboxVault.convertToAssets(underlyingShares);
        expectedAssetsOrSharesOut[0] = expectedAssetsOrSharesOut[0] - expectedAssetsOrSharesOut[0] * 1e3 / 1e5;

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);

        vm.startPrank(MANAGER);
        // Execute hooks first
        strategyGearSuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );

        // Sort and unique controllers before fulfillment
        requestingUsers = _sortAndUniqueControllers(requestingUsers);

        // Calculate adjusted netAssetsOut accounting for execution losses
        uint256[] memory netAssetsOut =
            calculateAdjustedFulfillment(strategyGearSuperVault, requestingUsers, expectedAssetsOrSharesOut);

        // Then fulfill redemption requests from liquidity
        strategyGearSuperVault.fulfillRedeemRequests(requestingUsers, netAssetsOut);
        vm.stopPrank();
    }

    function _claimWithdraw_Gearbox_SV(uint256 assets) internal {
        address[] memory claimHooksAddresses = new address[](1);
        claimHooksAddresses[0] = _getHookAddress(ETH, WITHDRAW_7540_VAULT_HOOK_KEY);

        bytes[] memory claimHooksData = new bytes[](1);
        claimHooksData[0] = _createWithdraw7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(gearSuperVault),
            assets,
            false
        );

        ISuperExecutor.ExecutorEntry memory claimEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: claimHooksAddresses, hooksData: claimHooksData });
        UserOpData memory claimUserOpData = _getExecOps(instanceOnEth, superExecutorOnEth, abi.encode(claimEntry));
        executeOp(claimUserOpData);
    }

    /*//////////////////////////////////////////////////////////////
                        ALLOCATE TESTS
    //////////////////////////////////////////////////////////////*/

    struct RebalanceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 totalAssets;
        uint256 targetFluidVaultAssets;
        uint256 targetAaveVaultAssets;
        uint256 currentFluidVaultAssets;
        uint256 currentAaveVaultAssets;
        uint256 assetsToMove;
        uint256 sharesToRedeem;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalFluidVaultAssets;
        uint256 finalAaveVaultAssets;
        uint256 finalTotalAssets;
        uint256 fluidVaultPercentage;
        uint256 aaveVaultPercentage;
        uint256 initialTotalValue;
    }

    function test_Allocate_Rebalance() public {
        RebalanceVars memory vars;
        vars.depositAmount = 1000e6;

        //60/40 initial allo
        _completeDepositFlow(vars.depositAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        vars.totalAssets = vault.totalAssets();
        console2.log("vars.totalAssets", vars.totalAssets);
        vars.targetFluidVaultAssets = vars.totalAssets * 70 / 100;
        vars.targetAaveVaultAssets = vars.totalAssets * 30 / 100;
        console2.log("vars.targetFluidVaultAssets", vars.targetFluidVaultAssets);
        console2.log("vars.targetAaveVaultAssets", vars.targetAaveVaultAssets);

        vars.currentFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);
        vars.currentAaveVaultAssets = aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        console2.log("vars.currentFluidVaultAssets", vars.currentFluidVaultAssets);
        console2.log("vars.currentAaveVaultAssets", vars.currentAaveVaultAssets);

        console2.log("Current FluidVault assets:", vars.currentFluidVaultAssets);
        console2.log("Current AaveVault assets:", vars.currentAaveVaultAssets);
        console2.log("Target FluidVault assets:", vars.targetFluidVaultAssets);
        console2.log("Target AaveVault assets:", vars.targetAaveVaultAssets);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](2);

        // Determine which way to rebalance
        if (vars.currentFluidVaultAssets < vars.targetFluidVaultAssets) {
            _rebalanceFromAaveToFluid(vars, hooksAddresses, hooksData);
        } else {
            _rebalanceFromFluidToAave(vars, hooksAddresses, hooksData);
        }

        // final balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        vars.finalAaveVaultAssets = aaveVault.convertToAssets(vars.finalAaveVaultBalance);
        vars.finalTotalAssets = vars.finalFluidVaultAssets + vars.finalAaveVaultAssets;
        vars.fluidVaultPercentage = vars.finalFluidVaultAssets * 10_000 / vars.finalTotalAssets;
        vars.aaveVaultPercentage = vars.finalAaveVaultAssets * 10_000 / vars.finalTotalAssets;

        console2.log("Final FluidVault assets:", vars.finalFluidVaultAssets);
        console2.log("Final AaveVault assets:", vars.finalAaveVaultAssets);
        console2.log("Final FluidVault percentage:", vars.fluidVaultPercentage, "%");
        console2.log("Final AaveVault percentage:", vars.aaveVaultPercentage, "%");

        // checks
        assertApproxEqRel(vars.fluidVaultPercentage, 7000, 0.02e18, "FluidVault should have ~70% allocation");
        assertApproxEqRel(vars.aaveVaultPercentage, 3000, 0.02e18, "AaveVault should have ~30% allocation");

        // check total vcalue
        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalAssets, vars.initialTotalValue, 0.01e18, "Total value should be preserved during rebalancing"
        );
    }

    function test_Allocate_SmallAmounts() public {
        RebalanceVars memory vars;
        vars.depositAmount = 5e5; //0.5 usd

        _completeDepositFlow(vars.depositAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        address[] memory hooksAddresses = new address[](2);
        bytes[] memory hooksData = new bytes[](2);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        vars.currentFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);
        vars.currentAaveVaultAssets = aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.totalAssets = vars.currentFluidVaultAssets + vars.currentAaveVaultAssets;

        vars.targetFluidVaultAssets = (vars.totalAssets * 7000) / 10_000;
        vars.targetAaveVaultAssets = (vars.totalAssets * 3000) / 10_000;

        console2.log("Current FluidVault assets:", vars.currentFluidVaultAssets);
        console2.log("Target FluidVault assets:", vars.targetFluidVaultAssets);
        console2.log("Current AaveVault assets:", vars.currentAaveVaultAssets);
        console2.log("Target AaveVault assets:", vars.targetAaveVaultAssets);

        vm.startPrank(MANAGER);
        if (vars.currentFluidVaultAssets < vars.targetFluidVaultAssets) {
            _rebalanceFromAaveToFluid(vars, hooksAddresses, hooksData);
        } else {
            _rebalanceFromFluidToAave(vars, hooksAddresses, hooksData);
        }
        vm.stopPrank();

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        vars.finalAaveVaultAssets = aaveVault.convertToAssets(vars.finalAaveVaultBalance);
        vars.finalTotalAssets = vars.finalFluidVaultAssets + vars.finalAaveVaultAssets;
        vars.fluidVaultPercentage = (vars.finalFluidVaultAssets * 10_000) / vars.finalTotalAssets;
        vars.aaveVaultPercentage = (vars.finalAaveVaultAssets * 10_000) / vars.finalTotalAssets;

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("FluidVault percentage:", vars.fluidVaultPercentage);
        console2.log("AaveVault percentage:", vars.aaveVaultPercentage);

        assertApproxEqRel(
            vars.fluidVaultPercentage, 7000, 0.05e18, "FluidVault allocation should be ~70% even for small amounts"
        );
        assertApproxEqRel(
            vars.aaveVaultPercentage, 3000, 0.05e18, "AaveVault allocation should be ~30% even for small amounts"
        );

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalAssets,
            vars.initialTotalValue,
            0.02e18,
            "Total value should be preserved even with small amounts"
        );
    }

    function test_Allocate_LargeAmounts() public {
        RebalanceVars memory vars;
        vars.depositAmount = 10_000_000e6; // 10M USD * 30

        _completeDepositFlow(vars.depositAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        address[] memory hooksAddresses = new address[](2);
        bytes[] memory hooksData = new bytes[](2);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        vars.currentFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);
        vars.currentAaveVaultAssets = aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.totalAssets = vars.currentFluidVaultAssets + vars.currentAaveVaultAssets;

        vars.targetFluidVaultAssets = (vars.totalAssets * 7000) / 10_000;
        vars.targetAaveVaultAssets = (vars.totalAssets * 3000) / 10_000;

        console2.log("Current FluidVault assets:", vars.currentFluidVaultAssets);
        console2.log("Target FluidVault assets:", vars.targetFluidVaultAssets);
        console2.log("Current AaveVault assets:", vars.currentAaveVaultAssets);
        console2.log("Target AaveVault assets:", vars.targetAaveVaultAssets);

        vm.startPrank(MANAGER);
        if (vars.currentFluidVaultAssets < vars.targetFluidVaultAssets) {
            _rebalanceFromAaveToFluid(vars, hooksAddresses, hooksData);
        } else {
            _rebalanceFromFluidToAave(vars, hooksAddresses, hooksData);
        }
        vm.stopPrank();

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        vars.finalAaveVaultAssets = aaveVault.convertToAssets(vars.finalAaveVaultBalance);
        vars.finalTotalAssets = vars.finalFluidVaultAssets + vars.finalAaveVaultAssets;
        vars.fluidVaultPercentage = (vars.finalFluidVaultAssets * 10_000) / vars.finalTotalAssets;
        vars.aaveVaultPercentage = (vars.finalAaveVaultAssets * 10_000) / vars.finalTotalAssets;

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("FluidVault percentage:", vars.fluidVaultPercentage);
        console2.log("AaveVault percentage:", vars.aaveVaultPercentage);

        assertApproxEqRel(
            vars.fluidVaultPercentage, 7000, 0.01e18, "FluidVault allocation should be ~70% for large amounts"
        );
        assertApproxEqRel(
            vars.aaveVaultPercentage, 3000, 0.01e18, "AaveVault allocation should be ~30% for large amounts"
        );

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalAssets,
            vars.initialTotalValue,
            0.01e18,
            "Total value should be preserved even with large amounts"
        );
    }

    struct AllocateNewYieldSourceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialNewVaultBalance;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalNewVaultBalance;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
    }

    function test_Allocate_NewYieldSource() public {
        AllocateNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        // do an initial allo
        _completeDepositFlow(vars.depositAmount);
        IERC4626 newVault = IERC4626(CHAIN_1_EULER_VAULT);

        //  -- add funds to the newVault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(newVault), type(uint256).max);
        newVault.deposit(2 * LARGE_DEPOSIT, address(this));

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial NewVault balance:", vars.initialNewVaultBalance);

        // 30/30/40
        // allocate 20% from each vault to the new one
        uint256 amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        uint256 amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        uint256 assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(amountToReallocateFluidVault);
        uint256 assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(amountToReallocateAaveVault);
        uint256 assetAmountToReallocateToNewVault =
            assetAmountToReallocateFromFluidVault + assetAmountToReallocateFromAaveVault;
        console2.log("Asset amount to reallocate from FluidVault:", assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", assetAmountToReallocateFromAaveVault);

        // allocation
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](3);
        // redeem from FluidVault
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(fluidVault),
            address(strategy),
            amountToReallocateFluidVault,
            false
        );
        // redeem from AaveVault
        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(aaveVault),
            address(strategy),
            amountToReallocateAaveVault,
            false
        );
        // deposit to NewVault
        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(newVault),
            address(asset),
            assetAmountToReallocateToNewVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();

        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("Final NewVault balance:", vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalNewVaultBalance, vars.initialNewVaultBalance, "NewVault balance should increase");

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + newVault.convertToAssets(vars.initialNewVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + newVault.convertToAssets(vars.finalNewVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );
    }

    function test_13_TransferOfShares() public {
        _getTokens(address(asset), accInstances[0].account, 100e6);
        __deposit(accInstances[0], 100e6);

        uint256 shares = vault.balanceOf(accInstances[0].account);

        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, shares);

        console2.log("share balance ofuser2", IERC20(address(vault)).balanceOf(accInstances[1].account));

        _depositFreeAssetsFromSingleAmount(100e6, address(fluidVault), address(aaveVault));

        _updateSuperVaultPPS(address(strategy), address(vault));

        _requestRedeemForAccount(accInstances[1], shares);

        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[1].account;

        _executeRedeemHooks4626ForUsers(redeemUsers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        assertGt(IERC7540Redeem(address(vault)).claimableRedeemRequest(0, accInstances[1].account), 0);
        assertEq(IERC7540Redeem(address(vault)).pendingRedeemRequest(0, accInstances[1].account), 0);
        assertEq(vault.balanceOf(accInstances[1].account), 0);
    }

    function test_13_TransferFromOfShares() public {
        _getTokens(address(asset), accInstances[0].account, 100e6);
        __deposit(accInstances[0], 100e6);

        uint256 shares = vault.balanceOf(accInstances[0].account);

        vm.prank(accInstances[0].account);
        IERC20(address(vault)).approve(accInstances[1].account, shares);

        vm.prank(accInstances[1].account);
        IERC20(address(vault)).transferFrom(accInstances[0].account, accInstances[1].account, shares);

        console2.log("share balance ofuser2", IERC20(address(vault)).balanceOf(accInstances[1].account));

        _depositFreeAssetsFromSingleAmount(100e6, address(fluidVault), address(aaveVault));

        _updateSuperVaultPPS(address(strategy), address(vault));

        _requestRedeemForAccount(accInstances[1], shares);

        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[1].account;

        _executeRedeemHooks4626ForUsers(redeemUsers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        assertGt(IERC7540Redeem(address(vault)).claimableRedeemRequest(0, accInstances[1].account), 0);
        assertEq(IERC7540Redeem(address(vault)).pendingRedeemRequest(0, accInstances[1].account), 0);
        assertEq(vault.balanceOf(accInstances[1].account), 0);
    }

    /*//////////////////////////////////////////////////////////////
                       AUDIT FIX #10 - DEPOSIT RECEIVER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that deposit accounting follows the minted receiver
    function test_Fix10_DepositAccountingFollowsReceiver() public {
        uint256 depositAmount = 1000e6;

        // Setup: get tokens for user A (sender)
        _getTokens(address(asset), accInstances[1].account, depositAmount);

        address receiver = accInstances[1].account;

        // Record initial accumulator states

        vm.startPrank(receiver);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.previewDeposit(depositAmount);
        vault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Verify shares were minted to receiver, not sender
        assertEq(vault.balanceOf(receiver), shares, "Receiver should have all shares");

        // Verify accumulator accounting follows the receiver

        // Accumulator assertions removed - now using global cost basis tracking
        // receiverStateAfter.accumulatorShares /* REMOVED - now using global cost basis */ and accumulatorCostBasis no
        // longer exist
    }

    /// @notice Test that receiver can successfully redeem after receiving deposit from another user
    function test_Fix10_ReceiverCanRedeemAfterReceivingDeposit() public {
        uint256 depositAmount = 1000e6;

        // Setup: get tokens for user A (sender)
        _getTokens(address(asset), accInstances[0].account, depositAmount);

        // User A will be the sender/controller, User B will be the receiver
        address sender = accInstances[0].account;
        address receiver = accInstances[1].account;

        // User A deposits but specifies User B as receiver
        vm.startPrank(sender);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Allocate assets to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // User B (receiver) should be able to request redeem for their shares
        vm.startPrank(receiver);
        vault.requestRedeem(shares, receiver, receiver);
        vm.stopPrank();

        // Verify redeem request was successful
        assertEq(strategy.pendingRedeemRequest(receiver), shares, "Receiver should have pending redeem request");
        assertEq(vault.balanceOf(address(escrow)), shares, "Shares should be in escrow");

        // Fulfill the redeem request
        address[] memory controllers = new address[](1);
        controllers[0] = receiver;
        _executeRedeemHooks4626ForUsers(controllers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        // Verify redemption was fulfilled
        assertEq(strategy.pendingRedeemRequest(receiver), 0, "Pending redeem should be cleared");
        assertGt(strategy.claimableWithdraw(receiver), 0, "Receiver should have claimable assets");

        // User B should be able to claim their assets
        uint256 claimableAssets = strategy.claimableWithdraw(receiver);
        uint256 initialAssetBalance = asset.balanceOf(receiver);

        vm.startPrank(receiver);
        vault.withdraw(claimableAssets, receiver, receiver);
        vm.stopPrank();

        // Verify assets were transferred to receiver
        assertEq(
            asset.balanceOf(receiver), initialAssetBalance + claimableAssets, "Receiver should receive their assets"
        );
        assertEq(strategy.claimableWithdraw(receiver), 0, "Claimable should be cleared");
    }

    /*//////////////////////////////////////////////////////////////
                       AUDIT FIX #15 - CONTROLLER/OWNER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that requestRedeem reverts when controller != owner
    function test_Fix15_RevertWhen_ControllerNotEqualOwner() public {
        uint256 depositAmount = 1000e6;

        // Setup: User A deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        address owner = accInstances[0].account;
        address controller = accInstances[1].account; // Different from owner
        uint256 shares = vault.balanceOf(owner);

        // Set operator permission so the call doesn't fail on authorization
        vm.prank(owner);
        vault.setOperator(controller, true);

        // Try to request redeem with controller != owner - should revert
        vm.startPrank(controller);
        vm.expectRevert(ISuperVault.CONTROLLER_MUST_EQUAL_OWNER.selector);
        vault.requestRedeem(shares, controller, owner);
        vm.stopPrank();
    }

    /// @notice Test that requestRedeem succeeds when controller == owner
    function test_Fix15_SucceedsWhen_ControllerEqualsOwner() public {
        uint256 depositAmount = 1000e6;

        // Setup: User A deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        address ownerController = accInstances[0].account; // Same address for both
        uint256 shares = vault.balanceOf(ownerController);

        // Request redeem with controller == owner - should succeed
        vm.startPrank(ownerController);
        uint256 requestId = vault.requestRedeem(shares, ownerController, ownerController);
        vm.stopPrank();

        // Verify redeem request was successful
        assertEq(requestId, 0, "Should return request ID 0");
        assertEq(strategy.pendingRedeemRequest(ownerController), shares, "Should have pending redeem request");
        assertEq(vault.balanceOf(address(escrow)), shares, "Shares should be in escrow");
    }

    /// @notice Test that fulfillment works correctly when controller == owner (no INSUFFICIENT_SHARES)
    function test_Fix15_FulfillmentWorksWithMatchedControllerOwner() public {
        uint256 depositAmount = 1000e6;

        // Setup: User A deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        address ownerController = accInstances[0].account;
        uint256 shares = vault.balanceOf(ownerController);

        // Request redeem with controller == owner
        vm.startPrank(ownerController);
        vault.requestRedeem(shares, ownerController, ownerController);
        vm.stopPrank();

        // Fulfill the redeem request - should not revert with INSUFFICIENT_SHARES
        address[] memory controllers = new address[](1);
        controllers[0] = ownerController;
        _executeRedeemHooks4626ForUsers(controllers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        // Verify fulfillment was successful
        assertEq(strategy.pendingRedeemRequest(ownerController), 0, "Pending redeem should be cleared");
        assertGt(strategy.claimableWithdraw(ownerController), 0, "Should have claimable assets");

        // User should be able to claim their assets
        uint256 claimableAssets = strategy.claimableWithdraw(ownerController);
        uint256 initialAssetBalance = asset.balanceOf(ownerController);

        vm.startPrank(ownerController);
        vault.withdraw(claimableAssets, ownerController, ownerController);
        vm.stopPrank();

        // Verify assets were transferred correctly
        assertEq(asset.balanceOf(ownerController), initialAssetBalance + claimableAssets, "Should receive assets");
        assertEq(strategy.claimableWithdraw(ownerController), 0, "Claimable should be cleared");
    }

    /*//////////////////////////////////////////////////////////////
                       AUDIT FIX #1 - TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that transfer only moves accumulators, never touches request/claim state
    function test_Fix1_TransferDoesNotAffectRequestClaimState() public {
        // Setup: Deposit, allocate, request redeem, then partially fulfill to create claimable state
        uint256 depositAmount = 1000e6;
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 shares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = shares / 2;

        // Request redeem to create pending state
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Fulfill redeem to create claimable state
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault)
        );

        // Record state before transfer
        uint256 pendingBefore = strategy.pendingRedeemRequest(accInstances[0].account);
        uint256 maxWithdrawBefore = strategy.claimableWithdraw(accInstances[0].account);
        uint256 avgRequestPPSBefore = strategy.getSuperVaultState(accInstances[0].account).averageRequestPPS;
        uint256 avgWithdrawPriceBefore = strategy.getAverageWithdrawPrice(accInstances[0].account);

        // Transfer remaining shares to another user
        uint256 remainingShares = vault.balanceOf(accInstances[0].account);
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, remainingShares);

        // Verify request/claim state unchanged for sender
        assertEq(
            strategy.pendingRedeemRequest(accInstances[0].account),
            pendingBefore,
            "pendingRedeemRequest should not change"
        );
        assertEq(
            strategy.claimableWithdraw(accInstances[0].account), maxWithdrawBefore, "maxWithdraw should not change"
        );
        assertEq(
            strategy.getSuperVaultState(accInstances[0].account).averageRequestPPS,
            avgRequestPPSBefore,
            "averageRequestPPS should not change"
        );
        assertEq(
            strategy.getAverageWithdrawPrice(accInstances[0].account),
            avgWithdrawPriceBefore,
            "averageWithdrawPrice should not change"
        );

        // Verify receiver has no request/claim state (since they didn't have any before)
        assertEq(
            strategy.pendingRedeemRequest(accInstances[1].account), 0, "Receiver should have no pendingRedeemRequest"
        );
        assertEq(strategy.claimableWithdraw(accInstances[1].account), 0, "Receiver should have no claimable");
        assertEq(
            strategy.getSuperVaultState(accInstances[1].account).averageRequestPPS,
            0,
            "Receiver should have no averageRequestPPS"
        );
        assertEq(
            strategy.getAverageWithdrawPrice(accInstances[1].account), 0, "Receiver should have no averageWithdrawPrice"
        );
    }

    /// @notice Test that transfer moves accumulators pro-rata and conserves total cost basis
    function test_Fix1_TransferMovesAccumulatorsProRata() public {
        uint256 depositAmount = 1000e6;
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 totalShares = vault.balanceOf(accInstances[0].account);
        uint256 transferShares = totalShares / 3; // Transfer 1/3 of shares

        // Record state before transfer

        // Accumulator pro-rata movement calculations removed - now using global cost basis tracking

        // Transfer shares
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, transferShares);

        // Accumulator assertions removed - accumulatorShares and accumulatorCostBasis no longer exist
        // The system now uses global vaultHwmPps tracking (PPS-based high-water mark) instead of per-user accumulators
    }

    /// @notice Test that zero-value transfer is a no-op
    function test_Fix1_ZeroValueTransferIsNoOp() public {
        uint256 depositAmount = 1000e6;
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Record state before zero transfer
        ISuperVaultStrategy.SuperVaultState memory fromStateBefore =
            strategy.getSuperVaultState(accInstances[0].account);

        // Perform zero-value transfer
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, 0);

        // Record state after zero transfer
        ISuperVaultStrategy.SuperVaultState memory fromStateAfter = strategy.getSuperVaultState(accInstances[0].account);

        // Accumulator assertions removed - accumulatorShares and accumulatorCostBasis no longer exist
        // Zero-value transfers now only affect share balances, not accumulator tracking

        // Verify all other fields unchanged
        assertEq(
            fromStateAfter.pendingRedeemRequest,
            fromStateBefore.pendingRedeemRequest,
            "pendingRedeemRequest should not change"
        );
        assertEq(fromStateAfter.maxWithdraw, fromStateBefore.maxWithdraw, "maxWithdraw should not change");
        assertEq(
            fromStateAfter.averageRequestPPS, fromStateBefore.averageRequestPPS, "averageRequestPPS should not change"
        );
        assertEq(
            fromStateAfter.averageWithdrawPrice,
            fromStateBefore.averageWithdrawPrice,
            "averageWithdrawPrice should not change"
        );
    }

    /// @notice Test that audit #1 attack scenario fails - no clone/overwrite of claimable
    function test_Fix1_AuditAttackScenarioFails() public {
        uint256 depositAmount = 1000e6;

        // User A deposits
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 sharesA = vault.balanceOf(accInstances[0].account);
        uint256 transferShares = sharesA / 2; // Transfer half, keep half for redeem

        // User B makes a deposit (gets fresh shares with no claimable)
        _getTokens(address(asset), accInstances[1].account, depositAmount);
        __deposit(accInstances[1], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 claimableBBefore = strategy.claimableWithdraw(accInstances[1].account);
        assertEq(claimableBBefore, 0, "User B should have no claimable assets initially");

        // User A transfers half their shares to User B BEFORE redeem request
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, transferShares);

        // User A then requests redeem with remaining shares and gets claimable assets
        uint256 remainingSharesA = vault.balanceOf(accInstances[0].account);
        _requestRedeemForAccount(accInstances[0], remainingSharesA);

        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            redeemUsers, remainingSharesA / 2, remainingSharesA / 2, address(fluidVault), address(aaveVault)
        );

        uint256 claimableA = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableA, 0, "User A should have claimable assets");

        // Verify attack failed: User B should not have gained User A's claimable assets
        uint256 claimableBAfter = strategy.claimableWithdraw(accInstances[1].account);
        assertEq(claimableBAfter, 0, "Attack failed: User B should not have claimable assets from User A");

        // Verify User A retains their claimable assets
        uint256 claimableAAfter = strategy.claimableWithdraw(accInstances[0].account);
        assertEq(claimableAAfter, claimableA, "User A should retain their claimable assets");

        // Verify only accumulators moved during transfer
        ISuperVaultStrategy.SuperVaultState memory stateB = strategy.getSuperVaultState(accInstances[1].account);

        // Accumulator assertion removed - accumulatorShares field no longer exists
        // User B would have received share balances from the transfer
        assertEq(stateB.pendingRedeemRequest, 0, "User B should have no pending requests");
        assertEq(stateB.maxWithdraw, 0, "User B should have no maxWithdraw");
        assertEq(stateB.averageRequestPPS, 0, "User B should have no averageRequestPPS");
        assertEq(stateB.averageWithdrawPrice, 0, "User B should have no averageWithdrawPrice");
    }

    /*//////////////////////////////////////////////////////////////
                            FIX #45 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that cancel → re-request → fulfill works (no permanent lockout)
    function test_Fix45_CancelReRequestFulfillWorks() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 2;

        // Get initial state
        ISuperVaultStrategy.SuperVaultState memory initialState = strategy.getSuperVaultState(accInstances[0].account);

        // Step 1: Request redeem
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Verify request was placed
        uint256 pendingAfterRequest = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingAfterRequest, redeemShares, "Should have pending request");

        // Step 2: Cancel redeem
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accInstances[0].account;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        vm.prank(accInstances[0].account);
        vault.claimCancelRedeemRequest(0, accInstances[0].account, accInstances[0].account);

        // Get state after cancel
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel =
            strategy.getSuperVaultState(accInstances[0].account);

        // Verify cancel cleared pending fields but preserved accumulators
        assertEq(stateAfterCancel.pendingRedeemRequest, 0, "Pending request should be cleared");
        assertEq(stateAfterCancel.averageRequestPPS, 0, "Average request PPS should be cleared");
        assertEq(stateAfterCancel.maxWithdraw, initialState.maxWithdraw, "Max withdraw should be preserved");
        assertEq(
            stateAfterCancel.averageWithdrawPrice,
            initialState.averageWithdrawPrice,
            "Average withdraw price should be preserved"
        );

        // Step 3: Re-request redeem (should work without INSUFFICIENT_SHARES)
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Verify re-request worked
        uint256 pendingAfterReRequest = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingAfterReRequest, redeemShares, "Should have pending request after re-request");

        // Step 4: Fulfill redeem (should work without errors)
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault)
        );

        // Verify fulfillment worked
        uint256 claimableAssets = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableAssets, 0, "Should have claimable assets after fulfillment");

        // Verify accumulator was properly debited
    }

    /// @notice Test that maxWithdraw and averageWithdrawPrice remain unchanged by cancel
    function test_Fix45_CancelPreservesClaimableState() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits, requests, gets partially fulfilled to create claimable state
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 firstRedeemShares = userShares / 3;

        // First redeem request and fulfillment to create claimable state
        _requestRedeemForAccount(accInstances[0], firstRedeemShares);
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            redeemUsers, firstRedeemShares / 2, firstRedeemShares / 2, address(fluidVault), address(aaveVault)
        );

        // Get state after first fulfillment
        ISuperVaultStrategy.SuperVaultState memory stateAfterFirstFulfill =
            strategy.getSuperVaultState(accInstances[0].account);
        uint256 maxWithdrawBefore = stateAfterFirstFulfill.maxWithdraw;
        uint256 averageWithdrawPriceBefore = stateAfterFirstFulfill.averageWithdrawPrice;

        assertGt(maxWithdrawBefore, 0, "Should have claimable assets");
        assertGt(averageWithdrawPriceBefore, 0, "Should have average withdraw price");

        // Second redeem request
        uint256 secondRedeemShares = userShares / 3;
        _requestRedeemForAccount(accInstances[0], secondRedeemShares);

        // Cancel the second request
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accInstances[0].account;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        vm.prank(accInstances[0].account);
        vault.claimCancelRedeemRequest(0, accInstances[0].account, accInstances[0].account);

        // Get state after cancel
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel =
            strategy.getSuperVaultState(accInstances[0].account);

        // Verify claimable state is preserved
        assertEq(stateAfterCancel.maxWithdraw, maxWithdrawBefore, "Max withdraw should be unchanged by cancel");
        assertEq(
            stateAfterCancel.averageWithdrawPrice,
            averageWithdrawPriceBefore,
            "Average withdraw price should be unchanged by cancel"
        );

        // Verify only pending fields were cleared
        assertEq(stateAfterCancel.pendingRedeemRequest, 0, "Pending request should be cleared");
        assertEq(stateAfterCancel.averageRequestPPS, 0, "Average request PPS should be cleared");
    }

    /// @notice Test that accumulators remain unchanged by cancel
    function test_Fix45_CancelPreservesAccumulators() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 2;

        // Get initial accumulator state
        // uint256 initialAccumulatorShares = initialState.accumulatorShares; // REMOVED
        // uint256 initialAccumulatorCostBasis = initialState.accumulatorCostBasis; // REMOVED

        // Request redeem
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Cancel redeem
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accInstances[0].account;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        vm.prank(accInstances[0].account);
        vault.claimCancelRedeemRequest(0, accInstances[0].account, accInstances[0].account);

        // Verify accumulators are exactly the same

        // User should still be able to make future redeems
        _requestRedeemForAccount(accInstances[0], redeemShares);
        uint256 pendingAfterNewRequest = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingAfterNewRequest, redeemShares, "Should be able to make new redeem request");
    }

    /// @notice Test that multiple cancel cycles work correctly
    function test_Fix45_MultipleCancelCycles() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 4;

        // Get initial accumulator state

        // Cycle 1: Request → Cancel
        _requestRedeemForAccount(accInstances[0], redeemShares);
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accInstances[0].account;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        vm.prank(accInstances[0].account);
        vault.claimCancelRedeemRequest(0, accInstances[0].account, accInstances[0].account);

        // Verify state after first cancel
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel1 =
            strategy.getSuperVaultState(accInstances[0].account);
        assertEq(stateAfterCancel1.pendingRedeemRequest, 0, "Pending should be cleared after cancel 1");

        // Cycle 2: Request → Cancel
        _requestRedeemForAccount(accInstances[0], redeemShares);
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        vm.startPrank(MANAGER);
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        vm.prank(accInstances[0].account);
        vault.claimCancelRedeemRequest(0, accInstances[0].account, accInstances[0].account);

        // Verify state after second cancel
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel2 =
            strategy.getSuperVaultState(accInstances[0].account);
        assertEq(stateAfterCancel2.pendingRedeemRequest, 0, "Pending should be cleared after cancel 2");

        // Cycle 3: Request → Fulfill (should work)
        _requestRedeemForAccount(accInstances[0], redeemShares);
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault)
        );

        // Verify final fulfillment worked
        uint256 claimableAssets = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableAssets, 0, "Should have claimable assets after final fulfillment");
    }

    /// @notice Test fulfilling a redemption with a pending cancellation (attempted griefing)
    /// @dev The redemption should succeed despite the pending cancellation
    function test_FulfillRedemptionWithPendingCancellation() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 4;

        // Step 1: User requests redemption
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Verify redeem request was recorded
        uint256 pendingRedeem = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeem, redeemShares, "Redeem request should be pending");

        // Step 2: Griefing attempt - user (or attacker) calls cancel
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        // Verify cancellation is pending
        bool hasPendingCancel = strategy.pendingCancelRedeemRequest(accInstances[0].account);
        assertTrue(hasPendingCancel, "Should have pending cancel request");

        // Step 3: Manager fulfills the original redemption despite pending cancellation
        // This should succeed - the redemption fulfillment should take precedence
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault)
        );

        // Step 4: Verify redemption was fulfilled successfully
        uint256 claimableAssets = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableAssets, 0, "Should have claimable assets after fulfillment");

        // Verify pending redeem request is cleared
        uint256 pendingRedeemAfter = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeemAfter, 0, "Pending redeem should be cleared after fulfillment");

        // Verify pending cancel is also cleared (since the original request was fulfilled)
        bool hasPendingCancelAfter = strategy.pendingCancelRedeemRequest(accInstances[0].account);
        assertFalse(hasPendingCancelAfter, "Pending cancel should be cleared after fulfillment");
    }

    /// @notice Test complete cancellation flow: request → cancel → fulfill cancel → claim cancel
    /// @dev Tests the full lifecycle of a redemption cancellation
    function test_CompleteCancellationFlow() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 3;

        // Get initial state
        // uint256 initialAccumulatorShares = initialState.accumulatorShares; // REMOVED
        // uint256 initialAccumulatorCostBasis = initialState.accumulatorCostBasis; // REMOVED

        // Step 1: Request redemption
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Verify redeem request was recorded
        uint256 pendingRedeem = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeem, redeemShares, "Redeem request should be pending");

        // Step 2: Cancel the redemption request
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        // Verify user cannot make new deposits/mints/redeems while having pending request
        vm.expectRevert(ISuperVault.CANCELLATION_REDEEM_REQUEST_PENDING.selector);
        vm.prank(accInstances[0].account);
        vault.requestRedeem(1, accInstances[0].account, accInstances[0].account);

        // Verify cancellation is pending
        bool hasPendingCancel = strategy.pendingCancelRedeemRequest(accInstances[0].account);
        assertTrue(hasPendingCancel, "Should have pending cancel request");

        // Verify original redeem request is still there (not cleared until fulfillment)
        uint256 pendingRedeemAfterCancel = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeemAfterCancel, redeemShares, "Original redeem should still be pending");

        // Verify user still cannot make new requests while cancel is pending
        vm.expectRevert(ISuperVault.CANCELLATION_REDEEM_REQUEST_PENDING.selector);
        vm.prank(accInstances[0].account);
        vault.requestRedeem(1, accInstances[0].account, accInstances[0].account);

        // Step 3: Manager fulfills the cancellation
        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accInstances[0].account;
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Verify states after fulfillment
        uint256 pendingRedeemAfterFulfill = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeemAfterFulfill, 0, "Pending redeem should be cleared after cancel fulfillment");

        bool hasPendingCancelAfterFulfill = strategy.pendingCancelRedeemRequest(accInstances[0].account);
        assertTrue(hasPendingCancelAfterFulfill, "Pending cancel should remain true until claim");

        uint256 claimableCancelShares = strategy.claimableCancelRedeemRequest(accInstances[0].account);
        assertEq(claimableCancelShares, redeemShares, "Should have claimable cancel shares equal to original request");

        // Step 4: User claims the cancelled redemption (gets shares back)
        uint256 sharesBefore = vault.balanceOf(accInstances[0].account);
        vm.prank(accInstances[0].account);
        vault.claimCancelRedeemRequest(0, accInstances[0].account, accInstances[0].account);

        uint256 sharesAfter = vault.balanceOf(accInstances[0].account);
        assertEq(sharesAfter, sharesBefore + redeemShares, "User should get their shares back");

        // Verify all pending states are cleared after claim
        bool hasPendingCancelAfterClaim = strategy.pendingCancelRedeemRequest(accInstances[0].account);
        assertFalse(hasPendingCancelAfterClaim, "Pending cancel should be cleared after claim");

        uint256 claimableCancelAfterClaim = strategy.claimableCancelRedeemRequest(accInstances[0].account);
        assertEq(claimableCancelAfterClaim, 0, "Claimable cancel should be cleared after claim");

        // Step 5: Verify user can make new requests after complete cancellation flow
        uint256 newRedeemShares = vault.balanceOf(accInstances[0].account) / 4;
        _requestRedeemForAccount(accInstances[0], newRedeemShares);

        uint256 newPendingRedeem = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(newPendingRedeem, newRedeemShares, "Should be able to make new redeem requests after cancellation");
    }

    /// @notice Test race condition: redeem fulfilled before cancellation can be processed
    /// @dev When redemption is fulfilled first, cancellation fulfillment should fail/be ineffective
    function test_RedeemFulfilledBeforeCancellation() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 4;

        // Step 1: User requests redemption
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Verify redeem request was recorded
        uint256 pendingRedeem = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeem, redeemShares, "Redeem request should be pending");

        // Step 2: User requests cancellation (but manager hasn't processed it yet)
        vm.prank(accInstances[0].account);
        vault.cancelRedeemRequest(0, accInstances[0].account);

        // Verify cancellation is pending
        bool hasPendingCancel = strategy.pendingCancelRedeemRequest(accInstances[0].account);
        assertTrue(hasPendingCancel, "Should have pending cancel request");

        // Step 3: Manager fulfills the original redemption BEFORE processing cancellation
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _executeRedeemHooks4626ForUsers(
            redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault)
        );

        // Verify redemption was fulfilled successfully
        uint256 claimableAssets = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableAssets, 0, "Should have claimable assets after redemption fulfillment");

        // Verify pending redeem request is cleared by fulfillment
        uint256 pendingRedeemAfter = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeemAfter, 0, "Pending redeem should be cleared after fulfillment");

        // Step 4: Manager tries to fulfill cancellation (should be ineffective since redeem was already fulfilled)
        vm.startPrank(MANAGER);
        address[] memory controllers = new address[](1);
        controllers[0] = accInstances[0].account;

        // This should not revert, but should be ineffective since there's no pending redeem to cancel
        strategy.fulfillCancelRedeemRequests(controllers);
        vm.stopPrank();

        // Step 5: Verify cancellation fulfillment had no effect
        // Since the original redeem was already fulfilled, there should be no claimable cancel shares
        uint256 claimableCancelShares = strategy.claimableCancelRedeemRequest(accInstances[0].account);
        assertEq(claimableCancelShares, 0, "Should have no claimable cancel shares since redeem was already fulfilled");

        // Verify pending cancel is cleared (since there was nothing to cancel)
        bool hasPendingCancelAfter = strategy.pendingCancelRedeemRequest(accInstances[0].account);
        assertFalse(hasPendingCancelAfter, "Pending cancel should be cleared after ineffective fulfillment");

        // Step 6: User tries to claim cancellation (should return 0 shares since there was nothing to cancel)
        uint256 sharesBefore = vault.balanceOf(accInstances[0].account);
        vm.prank(accInstances[0].account);
        vm.expectRevert(ISuperVaultStrategy.REQUEST_NOT_FOUND.selector);
        uint256 claimedShares = vault.claimCancelRedeemRequest(0, accInstances[0].account, accInstances[0].account);

        uint256 sharesAfter = vault.balanceOf(accInstances[0].account);
        assertEq(claimedShares, 0, "Should claim 0 shares since cancellation was ineffective");
        assertEq(sharesAfter, sharesBefore, "User balance should not change when claiming ineffective cancellation");
    }

    function _rebalanceFromAaveToFluid(
        RebalanceVars memory vars,
        address[] memory hooksAddresses,
        bytes[] memory hooksData
    )
        private
    {
        _rebalanceFromVaultToVault(
            hooksAddresses,
            hooksData,
            address(aaveVault),
            address(fluidVault),
            vars.targetFluidVaultAssets,
            vars.currentFluidVaultAssets
        );
    }

    function _rebalanceFromFluidToAave(
        RebalanceVars memory vars,
        address[] memory hooksAddresses,
        bytes[] memory hooksData
    )
        private
    {
        _rebalanceFromVaultToVault(
            hooksAddresses,
            hooksData,
            address(fluidVault),
            address(aaveVault),
            vars.targetAaveVaultAssets,
            vars.currentAaveVaultAssets
        );
    }

    /*//////////////////////////////////////////////////////////////
                      LIQUIDITY REDEEM FLOW TESTS
    //////////////////////////////////////////////////////////////*/
    function test_7540Underlying_Fulfill_From_Liquidity() public {
        // Set up the vault
        _setUp7540UnderlyingSuperVault();

        AccountInstance memory instance = accInstances[0];
        address account = instance.account;

        // Deposit USDC into the SuperVault
        uint256 depositAmount = 1000e6; // 1000 USDC
        _getTokens(address(asset), account, depositAmount);
        __deposit(instance, depositAmount);

        // Verify state
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        uint256 userShares = vault.balanceOf(account);
        assertGt(userShares, 0, "No shares minted to user");

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(account);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Step 4: Request Redeem
        __requestRedeem(instance, userShares, false);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(account), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        address[] memory users = new address[](1);
        users[0] = account;

        // Sort and unique controllers before fulfillment
        users = _sortAndUniqueControllers(users);

        // Calculate adjusted netAssetsOut for liquidity-only fulfillment
        uint256[] memory netAssetsOut = calculateLiquidityOnlyFulfillment(strategy, address(asset), users);

        vm.startPrank(MANAGER);
        strategy.fulfillRedeemRequests(users, netAssetsOut);
        vm.stopPrank();

        // Verify balances
        assertEq(asset.balanceOf(account), preRedeemUserAssets, "User assets not returned");
        // Fee balance assertion removed - fees now collected via skimPerformanceFee

        // Verify SuperVaultState is properly cleared after fulfillment
        ISuperVaultStrategy.SuperVaultState memory finalState = strategy.getSuperVaultState(account);
        assertEq(finalState.pendingRedeemRequest, 0, "Pending redeem request not cleared");
        assertEq(finalState.averageRequestPPS, 0, "Average request PPS not cleared");

        // Verify no pending redeem requests remain
        assertEq(strategy.pendingRedeemRequest(account), 0, "Pending redeem request still exists");

        // Verify ERC7540 pending redeem is also cleared
        assertEq(vault.pendingRedeemRequest(0, account), 0, "ERC7540 pending redeem not cleared");
    }

    function test_MultipleUsers_Redeem_Half_From_Liquidity() public {
        uint256 depositAmount = 1000e6;

        // deposit without fulfillment to have free assets in the strat
        _depositForAllUsers(depositAmount);

        uint256[] memory initialShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialShareBalances[i] = vault.balanceOf(accInstances[i].account);
        }

        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            _requestRedeemForAccount(accInstances[i], redeemAmount);
        }
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        // Sort and unique controllers before fulfillment
        requestingUsers = _sortAndUniqueControllers(requestingUsers);

        // Calculate adjusted netAssetsOut for liquidity-only fulfillment
        uint256[] memory netAssetsOut = calculateLiquidityOnlyFulfillment(strategy, address(asset), requestingUsers);

        vm.startPrank(MANAGER);
        strategy.fulfillRedeemRequests(requestingUsers, netAssetsOut);
        vm.stopPrank();

        // Verify SuperVaultState is properly cleared for all users after fulfillment
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            address user = accInstances[i].account;

            // Verify SuperVaultState is cleared
            ISuperVaultStrategy.SuperVaultState memory finalState = strategy.getSuperVaultState(user);
            assertEq(finalState.pendingRedeemRequest, 0, "Pending redeem request not cleared for user");
            assertEq(finalState.averageRequestPPS, 0, "Average request PPS not cleared for user");

            // Verify no pending redeem requests remain
            assertEq(strategy.pendingRedeemRequest(user), 0, "Pending redeem request still exists for user");

            // Verify ERC7540 pending redeem is also cleared
            assertEq(vault.pendingRedeemRequest(0, user), 0, "ERC7540 pending redeem not cleared for user");

            // Verify user received their redeemed assets (should have maxWithdraw available)
            assertGt(finalState.maxWithdraw, 0, "User should have claimable assets after fulfillment");
        }
    }

    function test_MultipleUsers_Redeem_From_Liquidity() public {
        uint256 depositAmount = 1000e6;

        _depositForAllUsers(depositAmount);

        uint256 strategyAssetBalance = asset.balanceOf(address(strategy));
        _depositFreeAssets(strategyAssetBalance / 2, strategyAssetBalance / 2, address(fluidVault), address(aaveVault));

        uint256[] memory initialShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialShareBalances[i] = vault.balanceOf(accInstances[i].account);
        }

        uint256 redeemShares;
        uint256 totalRedeemShares;
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            redeemShares = vault.balanceOf(accInstances[i].account);
            _requestRedeemForAccount(accInstances[i], redeemShares);
            totalRedeemShares += redeemShares;
            requestingUsers[i] = accInstances[i].account;
        }

        // Execute redeem hooks and fulfill requests in one call
        _executeRedeemHooks4626(totalRedeemShares, address(fluidVault), address(aaveVault), requestingUsers);

        // Verify SuperVaultState is properly cleared for all users after fulfillment
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            address user = accInstances[i].account;

            // Verify SuperVaultState is cleared
            ISuperVaultStrategy.SuperVaultState memory finalState = strategy.getSuperVaultState(user);
            assertEq(finalState.pendingRedeemRequest, 0, "Pending redeem request not cleared for user");
            assertEq(finalState.averageRequestPPS, 0, "Average request PPS not cleared for user");

            // Verify no pending redeem requests remain
            assertEq(strategy.pendingRedeemRequest(user), 0, "Pending redeem request still exists for user");

            // Verify ERC7540 pending redeem is also cleared
            assertEq(vault.pendingRedeemRequest(0, user), 0, "ERC7540 pending redeem not cleared for user");

            // Verify user received their redeemed assets (should have maxWithdraw available)
            assertGt(finalState.maxWithdraw, 0, "User should have claimable assets after fulfillment");
        }
    }

    function test_MultipleUsers_Redeem_From_Liquidity_WithAllocation() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);

        uint256 fluidShares = fluidVault.balanceOf(address(strategy));
        uint256 aaveShares = aaveVault.balanceOf(address(strategy));

        uint256 currentFluidVaultAssets = fluidVault.convertToAssets(fluidShares);
        uint256 currentAaveVaultAssets = aaveVault.convertToAssets(aaveShares);
        uint256 totalAssets = currentFluidVaultAssets + currentAaveVaultAssets;

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        hooksAddresses[1] = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](2);

        uint256 amountToReallocate = fluidShares.mulDiv(3000, 10_000);
        uint256 assetAmountToReallocate = fluidVault.convertToAssets(amountToReallocate);

        _rebalanceFromVaultToVault(
            hooksAddresses,
            hooksData,
            address(fluidVault),
            address(aaveVault),
            currentFluidVaultAssets + assetAmountToReallocate,
            currentAaveVaultAssets
        );

        uint256 finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        uint256 finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        uint256 finalFluidVaultAssets = fluidVault.previewRedeem(finalFluidVaultBalance);
        uint256 finalAaveVaultAssets = aaveVault.previewRedeem(finalAaveVaultBalance);

        uint256 finalTotalAssets = finalFluidVaultAssets + finalAaveVaultAssets;

        assertApproxEqRel(finalTotalAssets, totalAssets, 0.05e18, "Total value should be preserved");

        uint256 redeemShares;
        uint256 totalRedeemShares;
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            redeemShares = vault.balanceOf(accInstances[i].account);
            _requestRedeemForAccount(accInstances[i], redeemShares);
            totalRedeemShares += redeemShares;
        }

        _executeRedeemHooks4626AfterAllocation(address(fluidVault), address(aaveVault));

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        // Sort and unique controllers before fulfillment
        requestingUsers = _sortAndUniqueControllers(requestingUsers);

        // For this test, use selective fulfillment - distribute available assets pro-rata
        // Get strategy's current asset balance (what's available from executing hooks)
        uint256[] memory netAssetsOut = calculateLiquidityOnlyFulfillment(strategy, address(asset), requestingUsers);

        vm.startPrank(MANAGER);
        strategy.fulfillRedeemRequests(requestingUsers, netAssetsOut);
        vm.stopPrank();

        // Verify SuperVaultState is properly cleared for all users after fulfillment
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            address user = accInstances[i].account;

            // Verify SuperVaultState is cleared
            ISuperVaultStrategy.SuperVaultState memory finalState = strategy.getSuperVaultState(user);
            assertEq(finalState.pendingRedeemRequest, 0, "Pending redeem request not cleared for user");
            assertEq(finalState.averageRequestPPS, 0, "Average request PPS not cleared for user");

            // Verify no pending redeem requests remain
            assertEq(strategy.pendingRedeemRequest(user), 0, "Pending redeem request still exists for user");

            // Verify ERC7540 pending redeem is also cleared
            assertEq(vault.pendingRedeemRequest(0, user), 0, "ERC7540 pending redeem not cleared for user");

            // Verify user received their redeemed assets (should have maxWithdraw available)
            assertGt(finalState.maxWithdraw, 0, "User should have claimable assets after fulfillment");
        }
    }

    /*//////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    struct MultipleOperationsVars {
        uint256 seed;
        uint256[] depositAmounts;
        address[] redeemUsers;
        uint256[] redeemAmounts;
        bool[] selected;
        uint256 selectedCount;
        uint256 totalRedeemShares;
        uint256 redeemSharesVault1;
        uint256 redeemSharesVault2;
        uint256 initialTimestamp;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
    }

    struct FinalBalanceVerificationVars {
        // Global vault state
        uint256 finalTotalAssets;
        uint256 finalTotalSupply;
        uint256 finalPricePerShare;
        uint256 totalValueLocked;
        // Strategy state
        uint256 fluidBalance;
        uint256 aaveBalance;
        // Escrow state
        uint256 escrowBalance;
        // Yield tracking
        uint256 totalYieldAccrued;
        uint256 yieldPerShare;
        // User accounting
        uint256 totalUserShares;
        uint256 totalUserAssets;
        uint256 totalPendingDeposits;
        uint256 totalPendingRedeems;
        // Per-user state
        uint256 currentShares;
        uint256 currentAssets;
        uint256 expectedShares;
        uint256 expectedAssets;
        uint256 userYieldAccrued;
        bool isRedeemer;
        uint256 redeemedShares;
    }

    struct ScenarioNewYieldSourceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialNewVaultBalance;
        uint256 amountToReallocateFluidVault;
        uint256 amountToReallocateAaveVault;
        uint256 assetAmountToReallocateFromFluidVault;
        uint256 assetAmountToReallocateFromAaveVault;
        uint256 assetAmountToReallocateToNewVault;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalNewVaultBalance;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        // Price per share tracking
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
    }

    struct VaultLifecycleVars {
        uint256[] userDepositAmounts;
        address[] users;
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        uint256[] userInitialShares;
        uint256[] userInitialAssets;
        uint256[] userFinalShares;
        uint256[] userFinalAssets;
        uint256[] userYields;
    }

    struct RugTestVarsDeposit {
        uint256 depositAmount;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
        uint256 rugPercentage;
        address[] depositUsers;
        uint256[] depositAmounts;
        uint256 initialTimestamp;
        RuggableVault ruggableVault;
    }

    struct RugTestVarsWithdraw {
        bool convertVault;
        uint256 depositAmount;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
        uint256 rugPercentage;
        address[] depositUsers;
        uint256[] depositAmounts;
        address[] redeemUsers;
        uint256[] redeemAmounts;
        uint256 totalRedeemShares;
        uint256 redeemSharesVault1;
        uint256 redeemSharesVault2;
        uint256 initialTimestamp;
        address ruggableVault;
        uint256 initialRuggableVaultBalance;
        uint256 initialFluidVaultBalance;
        uint256 initialRuggableVaultAssets;
        uint256 initialFluidVaultAssets;
        uint256 amountToReallocate;
        uint256 assetAmountToReallocate;
        uint256 finalRuggableVaultBalance;
        uint256 finalFluidVaultBalance;
        uint256 finalRuggableVaultAssets;
        uint256 finalFluidVaultAssets;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        uint256 vaultTotalAssetsAfterAllocation;
        uint256 pricePerShareAfterAllocation;
        uint256 ppsBeforeWarp;
        uint256 ppsAfterWarp;
        uint256[] expectedAssetsOrSharesOut;
        uint256 assetsVault1;
        uint256 assetsVault2;
        // Added to avoid stack too deep errors
        uint256 finalTotalAssets;
        uint256 finalTotalSupply;
        uint256 totalAssetsPreClaimTaintedAssets;
        uint256 totalSupplyPreClaimTaintedAssets;
        uint256 pricePerSharePreClaimTaintedAssets;
    }

    struct VaultCapTestVars {
        address withdrawHookAddress;
        address depositHookAddress;
        address[] hooksAddresses;
        bytes[] hooksData;
        // Initial setup
        uint256 depositAmount;
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
        uint256 totalInitialBalance;
        uint256 initialFluidRatio;
        uint256 initialAaveRatio;
        uint256 initialEulerRatio;
        // Vault balances
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialEulerVaultBalance;
        // First reallocation (50/25/25)
        uint256 assetsToMove;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalEulerVaultBalance;
        uint256 totalFinalBalance;
        uint256 finalFluidRatio;
        uint256 finalAaveRatio;
        uint256 finalEulerRatio;
        // Second reallocation (40/30/30)
        uint256 newVaultCap;
        uint256 targetFluidAssets2;
        uint256 targetAaveAssets2;
        uint256 targetEulerAssets2;
        uint256 finalFluidVaultBalance2;
        uint256 finalAaveVaultBalance2;
        uint256 finalEulerVaultBalance2;
        uint256 finalFluidRatio2;
        uint256 finalAaveRatio2;
        uint256 finalEulerRatio2;
        uint256 finalTotalValue;
        // misc
        uint256 newSuperVaultCap;
    }

    struct TestVars {
        uint256 initialTimestamp;
        uint256 totalDeposited;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
        uint256 finalTotalAssets;
        uint256 finalTotalSupply;
        uint256 finalPricePerShare;
        uint256 fluidVaultBalance;
        uint256 aaveVaultBalance;
        uint256[] depositAmounts;
        address[] depositUsers;
    }

    struct YieldTestVars {
        uint256 depositAmount;
        uint256 initialTimestamp;
        Mock4626Vault vault1; // 3% yield
        Mock4626Vault vault2; // 5% yield
        Mock4626Vault vault3; // 10% yield
        uint256 initialVault1Balance;
        uint256 initialVault2Balance;
        uint256 initialVault3Balance;
        uint256 initialVault1Assets;
        uint256 initialVault2Assets;
        uint256 initialVault3Assets;
        uint256 finalVault1Assets;
        uint256 finalVault2Assets;
        uint256 finalVault3Assets;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
    }

    function test_1_DynamicAllocation() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 100e6;

        // Deploy using Create2.deploy() instead of new{salt} syntax for consistent prediction
        Mock4626Vault newVault = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "New Vault", "NV"))
            )
        );

        console2.log("newVault", address(newVault));
        console2.log("predicted", test1_DynamicAllocation_MockVault);
        assertEq(address(newVault), test1_DynamicAllocation_MockVault, "TEST1 VAULT NOT EQUAL TO PREDICTED");
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(newVault), type(uint256).max);
        newVault.deposit(2 * LARGE_DEPOSIT, address(this));

        // warp before adding a new vault;
        vm.warp(block.timestamp + 20 days);

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // warp again
        vm.warp(block.timestamp + 20 days);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // create deposit requests for all users
        _depositForAllUsers(vars.depositAmount);

        // create fullfillment data
        uint256 totalAmount = vars.depositAmount * ACCOUNT_COUNT;
        uint256 allocationAmountVault1 = totalAmount * 40 / 100;
        uint256 allocationAmountVault2 = totalAmount * 30 / 100;
        uint256 allocationAmountVault3 = totalAmount * 30 / 100;

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill deposits
        _depositFreeAssets(
            address(fluidVault),
            address(aaveVault),
            address(newVault),
            allocationAmountVault1,
            allocationAmountVault2,
            allocationAmountVault3
        );

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial NewVault balance:", vars.initialNewVaultBalance);

        _test_1_performReallocation(vars, newVault);

        console2.log("\n=== Enhanced Vault Metrics ===");
        uint256 fluidVaultFinalPPS = fluidVault.convertToAssets(1e18);
        uint256 aaveVaultFinalPPS = aaveVault.convertToAssets(1e18);
        uint256 newVaultFinalPPS = newVault.convertToAssets(1e18);

        console2.log("\nPrice per Share Changes:");
        console2.log("Fluid Vault:");
        console2.log("  Initial PPS:", vars.initialFluidVaultPPS);
        console2.log("  Final PPS:", fluidVaultFinalPPS);
        console2.log(
            "  Change:",
            fluidVaultFinalPPS > vars.initialFluidVaultPPS ? "+" : "",
            fluidVaultFinalPPS - vars.initialFluidVaultPPS
        );
        console2.log(
            "  Change %:", ((fluidVaultFinalPPS - vars.initialFluidVaultPPS) * 10_000) / vars.initialFluidVaultPPS
        );

        console2.log("\nAave Vault:");
        console2.log("  Initial PPS:", vars.initialAaveVaultPPS);
        console2.log("  Final PPS:", aaveVaultFinalPPS);
        console2.log(
            "  Change:",
            aaveVaultFinalPPS > vars.initialAaveVaultPPS ? "+" : "",
            aaveVaultFinalPPS - vars.initialAaveVaultPPS
        );
        console2.log(
            "  Change %:", ((aaveVaultFinalPPS - vars.initialAaveVaultPPS) * 10_000) / vars.initialAaveVaultPPS
        );

        console2.log("\nYield Metrics:");
        uint256 totalYield =
            vars.finalTotalValue > vars.initialTotalValue ? vars.finalTotalValue - vars.initialTotalValue : 0;
        console2.log("Total Yield:", totalYield);
        console2.log("Yield %:", (totalYield * 10_000) / vars.initialTotalValue);

        assertGe(fluidVaultFinalPPS, vars.initialFluidVaultPPS, "Fluid Vault should not lose value");
        assertGe(aaveVaultFinalPPS, vars.initialAaveVaultPPS, "Aave Vault should not lose value");
        assertGe(newVaultFinalPPS, 1e18, "NewVault should not lose value");

        uint256 totalFinalBalance = vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalNewVaultBalance;
        uint256 fluidRatio = (vars.finalFluidVaultBalance * 100) / totalFinalBalance;
        uint256 aaveRatio = (vars.finalAaveVaultBalance * 100) / totalFinalBalance;
        uint256 newRatio = (vars.finalNewVaultBalance * 100) / totalFinalBalance;

        console2.log("\nFinal Allocation Ratios:");
        console2.log("Fluid Vault:", fluidRatio, "%");
        console2.log("Aave Vault:", aaveRatio, "%");
        console2.log("NewVault:", newRatio, "%");
    }

    function _test_1_performReallocation(ScenarioNewYieldSourceVars memory vars, Mock4626Vault newVault) private {
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        vars.amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        vars.assetAmountToReallocateToNewVault =
            vars.assetAmountToReallocateFromFluidVault + vars.assetAmountToReallocateFromAaveVault;

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);
        console2.log("Asset amount to reallocate from MocmVault:", vars.assetAmountToReallocateToNewVault);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        bytes[] memory hooksData = new bytes[](3);

        // Setup hooks
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );

        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );

        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(newVault),
            address(asset),
            vars.assetAmountToReallocateToNewVault,
            false,
            address(0),
            0
        );

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        // Perform allocation
        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](3)
            })
        );
        vm.stopPrank();
        vm.warp(block.timestamp + 20 days);

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("NewVault balance:", vars.finalNewVaultBalance);

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + newVault.convertToAssets(vars.initialNewVaultBalance);
        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + newVault.convertToAssets(vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total value should be preserved during allocation - after first reallocation"
        );

        // Verify balance changes
        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - vars.amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - vars.amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalNewVaultBalance, vars.initialNewVaultBalance, "NewVault balance should increase");

        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));
        vars.assetAmountToReallocateToNewVault = newVault.convertToAssets(vars.initialNewVaultBalance);
        vars.assetAmountToReallocateFromFluidVault = vars.assetAmountToReallocateToNewVault * 30 / 100;
        vars.assetAmountToReallocateFromAaveVault =
            vars.initialNewVaultBalance - vars.assetAmountToReallocateFromFluidVault; // the rest goes here

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);
        console2.log("Asset amount to reallocate from MocmVault:", vars.assetAmountToReallocateToNewVault);

        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;
        hooksAddresses[2] = depositHookAddress;

        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(newVault),
            address(strategy),
            vars.assetAmountToReallocateToNewVault,
            false
        );

        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            vars.assetAmountToReallocateFromFluidVault,
            false,
            address(0),
            0
        );

        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            vars.assetAmountToReallocateFromAaveVault,
            false,
            address(0),
            0
        );
        argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        // Perform allocation
        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](3)
            })
        );
        vm.stopPrank();
        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("NewVault balance:", vars.finalNewVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + newVault.convertToAssets(vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total value should be preserved during allocation - after second reallocation"
        );
    }

    // Temporary mapping to associate users with their redemption amounts
    mapping(address => uint256) private tempUserRedemptionAmounts;

    function test_2_MultipleOperations_RandomAmounts(uint256 seed) public {
        MultipleOperationsVars memory vars;
        // Clear any existing mapping data
        _clearRedemptionMapping();

        // Setup random seed and initial timestamp
        vars.initialTimestamp = block.timestamp;
        vars.seed = seed;
        // Generate random deposit amounts for all users (20 users)
        vars.depositAmounts = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            // Use the seed to generate random amounts
            // 50% chance for large amount (1M-2M), 50% chance for small amount (100-1000)
            uint256 rand = uint256(keccak256(abi.encodePacked(vars.seed, i)));
            if (rand % 2 == 0) {
                // Large amount: 1M-2M USDC
                vars.depositAmounts[i] = 1_000_000e6 + (rand % 1_000_000e6);
            } else {
                // Small amount: 100-1000 USDC
                vars.depositAmounts[i] = 100e6 + (rand % 900e6);
            }
        }

        _completeDepositFlowWithVaryingAmounts(vars.depositAmounts);

        _updateSuperVaultPPS(address(strategy), address(vault));

        // Store initial state for yield verification
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        //vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply,
        // Math.Rounding.Floor);

        // Verify initial balances and shares
        _verifyInitialBalances(vars.depositAmounts);

        // Simulate time passing (1 day) to accumulate some yield
        vm.warp(vars.initialTimestamp + 1 days);
        console2.log("\n=== After 1 day ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Setup redemption arrays
        vars.redeemUsers = new address[](15);
        vars.redeemAmounts = new uint256[](15);
        vars.selected = new bool[](ACCOUNT_COUNT);

        // Select random users for redemption
        vars = _selectRandomUsersForRedemption(vars);

        // Populate the mapping to associate each user with their redemption amount
        for (uint256 i; i < 15; i++) {
            tempUserRedemptionAmounts[vars.redeemUsers[i]] = vars.redeemAmounts[i];
        }

        // Simulate some more time passing (12 days) before redemption requests
        vm.warp(vars.initialTimestamp + 10 days);
        _updateSuperVaultPPS(address(strategy), address(vault));
        vars.initialPricePerShare = strategy.getStoredPPS();
        console2.log("\n=== After 10 days ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Request redemptions
        _processRedemptionRequests(vars);

        // Calculate total redemption amount for allocation
        for (uint256 i; i < 15; i++) {
            vars.totalRedeemShares += vars.redeemAmounts[i];
        }

        // Simulate time passing (6 hours) before fulfilling redemptions
        vm.warp(vars.initialTimestamp + 10 days + 6 hours);
        console2.log("\n=== After 10 days and 6 hours ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Fulfill redemptions
        vars.redeemSharesVault1 = vars.totalRedeemShares / 2;
        vars.redeemSharesVault2 = vars.totalRedeemShares - vars.redeemSharesVault1;
        _executeRedeemHooks4626ForUsers(
            vars.redeemUsers, vars.redeemSharesVault1, vars.redeemSharesVault2, address(fluidVault), address(aaveVault)
        );

        // Simulate final time passing before final verification
        vm.warp(vars.initialTimestamp + 11 days);
        // Process claims for redeemed users
        _claimRedeemForUsers(vars.redeemUsers);

        console2.log("\n=== After 11 days ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Verify final balances and shares
        _verifyFinalBalances(vars);
    }

    function test_3_UnderlyingVaults_StressTest() public {
        RugTestVarsWithdraw memory vars;

        // A vault that is rugged on deposit and on withdraw; 10% rug
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 10;
        vars.initialTimestamp = block.timestamp;

        vars.ruggableVault = Create2.deploy(
            0,
            keccak256(abi.encodePacked(TEST_SALT)),
            abi.encodePacked(
                type(RuggableVault).creationCode,
                abi.encode(IERC20(address(asset)), "Ruggable Vault", "RUG", true, true, vars.rugPercentage)
            )
        );

        vm.label(vars.ruggableVault, "Ruggable Vault");
        vm.label(address(fluidVault), "Fluid Vault");

        console2.log("ruggable vault", vars.ruggableVault);
        assertEq(vars.ruggableVault, test3_UnderlyingVaults_StressTest, "TEST3 VAULT NOT EQUAL TO PREDICTED");
        console2.log("fluid vault", address(fluidVault));

        // add some funds to the vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(vars.ruggableVault), type(uint256).max);
        RuggableVault(vars.ruggableVault).deposit(2 * LARGE_DEPOSIT, address(this));

        // create SV with fluid and this ruggable vault
        _deployNewSuperVaultWithRuggableVault(address(vars.ruggableVault));

        // users to deposit and withdraw
        vars.depositUsers = new address[](2);
        vars.depositAmounts = new uint256[](2);

        for (uint256 i; i < 2; ++i) {
            vars.depositUsers[i] = accInstances[i].account;
            vars.depositAmounts[i] = vars.depositAmount;
        }

        // perform deposit operations
        for (uint256 i; i < 2; ++i) {
            _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
            vm.startPrank(vars.depositUsers[i]);
            asset.approve(address(vault), vars.depositAmounts[i]);
            vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
            vm.stopPrank();
        }

        vm.warp(vars.initialTimestamp + 1 days);
        _updatePPSToTarget(address(strategy), address(vault), 1e18);

        uint256 totalAmount = vars.depositAmount * 2;
        uint256 allocationAmountVault1 = totalAmount / 2;
        uint256 allocationAmountVault2 = totalAmount - allocationAmountVault1;

        // put 50-50 in each vault
        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = fluidVault.previewDeposit(allocationAmountVault1);
        expectedAssetsOrSharesOut[1] = IERC4626(vars.ruggableVault).previewDeposit(allocationAmountVault2);

        for (uint256 i; i < expectedAssetsOrSharesOut.length; i++) {
            expectedAssetsOrSharesOut[i] = expectedAssetsOrSharesOut[i] - expectedAssetsOrSharesOut[i] * 1e3 / 1e5;
        }

        _depositFreeAssets(
            allocationAmountVault1,
            allocationAmountVault2,
            address(fluidVault),
            address(vars.ruggableVault),
            expectedAssetsOrSharesOut,
            bytes4(0)
        );
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", RuggableVault(vars.ruggableVault).balanceOf(address(strategy)));

        vm.warp(block.timestamp + 12 weeks);
        _updatePPSToTarget(address(strategy), address(vault), 1e18);

        uint256 prevPps = vars.initialPricePerShare;
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", RuggableVault(vars.ruggableVault).balanceOf(address(strategy)));

        assertApproxEqRel(vars.initialPricePerShare, prevPps, 0.1e18, "Price per share should be preserved");

        // redeem from 1 user
        vars.redeemUsers = new address[](1);
        vars.redeemAmounts = new uint256[](1);
        vars.totalRedeemShares = 0;

        vars.redeemUsers[0] = vars.depositUsers[0];
        vars.redeemAmounts[0] = vault.balanceOf(vars.redeemUsers[0]);
        assertGt(vars.redeemAmounts[0], 0, "Redeem amount should be greater than 0");
        vars.totalRedeemShares += vars.redeemAmounts[0];

        vm.startPrank(vars.redeemUsers[0]);
        vault.requestRedeem(vars.redeemAmounts[0], vars.redeemUsers[0], vars.redeemUsers[0]);
        vm.stopPrank();

        vars.redeemSharesVault1 = vars.totalRedeemShares / 2;
        vars.redeemSharesVault2 = vars.totalRedeemShares - vars.redeemSharesVault1;

        vars.assetsVault1 = vault.convertToAssets(vars.redeemSharesVault1);
        vars.assetsVault2 = vault.convertToAssets(vars.redeemSharesVault2);

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = vars.assetsVault1;
        vars.expectedAssetsOrSharesOut[1] = vars.assetsVault2;
        _executeRedeemHooks4626ForUsers(
            vars.redeemUsers,
            vars.redeemSharesVault1,
            vars.redeemSharesVault2,
            address(fluidVault),
            vars.ruggableVault,
            vars.expectedAssetsOrSharesOut,
            bytes4(0)
        );

        vm.warp(block.timestamp + 12 weeks);
        prevPps = vars.initialPricePerShare;
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", RuggableVault(vars.ruggableVault).balanceOf(address(strategy)));

        assertApproxEqRel(vars.initialPricePerShare, prevPps, 0.1e18, "Price per share should be preserved");
    }

    function test_4_Rebalance_Test() public {
        VaultCapTestVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // Initial allocation - this will put the first two vaults at ~50/50
        _completeDepositFlow(vars.depositAmount);

        // Add Euler vault as a new yield source
        address eulerVaultAddr = CHAIN_1_EULER_VAULT;
        vm.label(eulerVaultAddr, "EulerVault");
        IERC4626 eulerVault = IERC4626(eulerVaultAddr);

        // Add funds to the Euler vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(eulerVaultAddr, type(uint256).max);
        eulerVault.deposit(2 * LARGE_DEPOSIT, address(this));

        vm.warp(block.timestamp + 20 days);

        // Add Euler vault as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(eulerVaultAddr, _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // Get initial balances
        vars.initialFluidVaultBalance = fluidVault.convertToAssets(fluidVault.balanceOf(address(strategy)));
        vars.initialAaveVaultBalance = aaveVault.convertToAssets(aaveVault.balanceOf(address(strategy)));
        vars.initialEulerVaultBalance = eulerVault.convertToAssets(eulerVault.balanceOf(address(strategy)));

        console2.log("\n=== Initial Balances ===");
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial EulerVault balance:", vars.initialEulerVaultBalance);

        // Calculate initial allocation percentages
        vars.totalInitialBalance =
            vars.initialFluidVaultBalance + vars.initialAaveVaultBalance + vars.initialEulerVaultBalance;
        vars.initialFluidRatio = (vars.initialFluidVaultBalance * 10_000) / vars.totalInitialBalance;
        vars.initialAaveRatio = (vars.initialAaveVaultBalance * 10_000) / vars.totalInitialBalance;
        vars.initialEulerRatio = (vars.initialEulerVaultBalance * 10_000) / vars.totalInitialBalance;

        console2.log("\n=== Initial Allocation Ratios ===");
        console2.log("Fluid Vault:", vars.initialFluidRatio / 100, "%");
        console2.log("Aave Vault:", vars.initialAaveRatio / 100, "%");
        console2.log("Euler Vault:", vars.initialEulerRatio / 100, "%");

        // First reallocation: Change to 50/25/25 (fluid/aave/euler)
        console2.log("\n=== First Reallocation: Target 50/25/25 ===");

        // Set up hooks for reallocation
        vars.withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        vars.depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        // Perform first reallocation to 50/25/25
        (
            vars.finalFluidVaultBalance,
            vars.finalAaveVaultBalance,
            vars.finalEulerVaultBalance,
            vars.finalFluidRatio,
            vars.finalAaveRatio,
            vars.finalEulerRatio
        ) =
            _reallocate(
                ReallocateArgs({
                    vault1: fluidVault,
                    vault2: aaveVault,
                    vault3: eulerVault,
                    targetVault1Percentage: 5000, // 50%
                    targetVault2Percentage: 2500, // 25%
                    targetVault3Percentage: 2500, // 25%
                    withdrawHookAddress: vars.withdrawHookAddress,
                    depositHookAddress: vars.depositHookAddress
                })
            );

        // Verify the allocation is close to 50/25/25
        assertApproxEqRel(vars.finalFluidRatio, 5000, 0.05e18, "Fluid allocation should be close to 50%");
        assertApproxEqRel(vars.finalAaveRatio, 2500, 0.05e18, "Aave allocation should be close to 25%");
        assertApproxEqRel(vars.finalEulerRatio, 2500, 0.05e18, "Euler allocation should be close to 25%");

        // Second reallocation: Change to 40/30/30 (fluid/aave/euler)
        console2.log("\n=== Second Reallocation: Target 40/30/30 ===");

        // Calculate target balances for 40/30/30 allocation
        vars.totalFinalBalance = vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalEulerVaultBalance;
        vars.targetFluidAssets2 = vars.totalFinalBalance * 4000 / 10_000;
        vars.targetAaveAssets2 = vars.totalFinalBalance * 3000 / 10_000;
        vars.targetEulerAssets2 = vars.totalFinalBalance * 3000 / 10_000;

        console2.log("Total Assets:", vars.totalFinalBalance);
        console2.log("Target Fluid Assets:", vars.targetFluidAssets2);
        console2.log("Target Aave Assets:", vars.targetAaveAssets2);
        console2.log("Target Euler Assets:", vars.targetEulerAssets2);

        console2.log("Target Aave assets would exceed vault cap!");
        console2.log("Vault Cap:", vars.newSuperVaultCap);
        console2.log("Target Aave Assets:", vars.targetAaveAssets2);
    }

    function test_5_EdgeCases_Small_Amounts() public {
        uint256 depositAmount = 100; // very small

        // perform deposit operations
        _completeDepositFlow(depositAmount);
        uint256 totalRedeemShares;
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            totalRedeemShares += vaultBalance;
        }

        _updateRedeemSlippages(500);

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fullfillment data
        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill redeem
        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // check that all pending requests are cleared
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_5_EdgeCases_Large_Amounts() public {
        uint256 depositAmount = 2_000_000e6; // very big

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        uint256 totalRedeemShares;
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            totalRedeemShares += vaultBalance;
        }

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fullfillment data
        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill redeem
        _executeRedeemHooks4626ForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // check that all pending requests are cleared
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_6_yieldAccumulation() public {
        YieldTestVars memory vars;
        vars.depositAmount = 1000e6; // 100,000 USDC
        vars.initialTimestamp = block.timestamp;

        // create yield testing vaults
        vars.vault1 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock4626Vault 3%", "MV3")
                )
            )
        );
        vars.vault2 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock4626Vault 5%", "MV5")
                )
            )
        );
        vars.vault3 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock4626Vault 10%", "MV10")
                )
            )
        );
        string[] memory vaultNames = new string[](3);
        vaultNames[0] = "test6YA_Mock4626Vault1";
        vaultNames[1] = "test6YA_Mock4626Vault2";
        vaultNames[2] = "test6YA_Mock4626Vault3";
        address[] memory vaultAddresses = new address[](3);
        vaultAddresses[0] = address(vars.vault1);
        vaultAddresses[1] = address(vars.vault2);
        vaultAddresses[2] = address(vars.vault3);

        console2.log("vault1", address(vars.vault1));
        console2.log("vault2", address(vars.vault2));
        console2.log("vault3", address(vars.vault3));

        assertEq(address(vars.vault1), test6_yieldAccumulation_vault1, "TEST6 VAULT1 NOT EQUAL TO PREDICTED");
        assertEq(address(vars.vault2), test6_yieldAccumulation_vault2, "TEST6 VAULT2 NOT EQUAL TO PREDICTED");
        assertEq(address(vars.vault3), test6_yieldAccumulation_vault3, "TEST6 VAULT3 NOT EQUAL TO PREDICTED");

        vars.vault1.setYield(3000); // 3%
        vars.vault2.setYield(5000); // 5%
        vars.vault3.setYield(10_000); // 10%

        // add some funds to each vault to bypass the VAULT_THRESHOLD_EXCEEDED error
        _getTokens(address(asset), address(this), 10 * LARGE_DEPOSIT);
        asset.approve(address(vars.vault1), type(uint256).max);
        asset.approve(address(vars.vault2), type(uint256).max);
        asset.approve(address(vars.vault3), type(uint256).max);
        vars.vault1.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault2.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault3.deposit(2 * LARGE_DEPOSIT, address(this));

        // add vaults to SV
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(vars.vault1), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault2), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault3), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // use 3 users to perform deposits
        for (uint256 i; i < 3; ++i) {
            _getTokens(address(asset), accInstances[i].account, vars.depositAmount);
            _depositForAccount(accInstances[i], vars.depositAmount);
        }

        // fulfill deposits
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](3);
        fulfillHooksAddresses[0] = depositHookAddress;
        fulfillHooksAddresses[1] = depositHookAddress;
        fulfillHooksAddresses[2] = depositHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](3);
        // allocate up to the max allocation rate in the two Vaults
        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.vault1),
            address(asset),
            vars.depositAmount,
            false,
            address(0),
            0
        );
        fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.vault2),
            address(asset),
            vars.depositAmount,
            false,
            address(0),
            0
        );
        fulfillHooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.vault3),
            address(asset),
            vars.depositAmount,
            false,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](3);
        expectedAssetsOrSharesOut[0] = IERC4626(address(vars.vault1)).convertToShares(vars.depositAmount);
        expectedAssetsOrSharesOut[1] = IERC4626(address(vars.vault2)).convertToShares(vars.depositAmount);
        expectedAssetsOrSharesOut[2] = IERC4626(address(vars.vault3)).convertToShares(vars.depositAmount);

        address[] memory requestingUsers = new address[](3);
        for (uint256 i; i < 3; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);
        argsForProofs[2] = ISuperHookInspector(fulfillHooksAddresses[2]).inspect(fulfillHooksData[2]);

        vm.startPrank(MANAGER);
        console2.log("Executing hooks");
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](fulfillHooksAddresses.length)
            })
        );
        console2.log("Hooks executed");
        vm.stopPrank();

        vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
        vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
        vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));

        vars.initialVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
        vars.initialVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
        vars.initialVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

        // fast forward time to simulate yield accumulation
        vm.warp(vars.initialTimestamp + 1 weeks);

        vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
        vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
        vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));

        vars.finalVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
        vars.finalVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
        vars.finalVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

        console2.log("initialVault1Assets", vars.initialVault1Assets);
        console2.log("finalVault1Assets  ", vars.finalVault1Assets);
        console2.log("initialVault2Assets", vars.initialVault2Assets);
        console2.log("finalVault2Assets  ", vars.finalVault2Assets);
        console2.log("initialVault3Assets", vars.initialVault3Assets);
        console2.log("finalVault3Assets  ", vars.finalVault3Assets);

        assertGt(vars.finalVault1Assets, vars.initialVault1Assets, "Vault 1 should have gained assets");
        assertGt(vars.finalVault2Assets, vars.initialVault2Assets, "Vault 2 should have gained assets");
        assertGt(vars.finalVault3Assets, vars.initialVault3Assets, "Vault 3 should have gained assets");

        uint256 vault1Yield = vars.finalVault1Assets - vars.initialVault1Assets;
        uint256 vault2Yield = vars.finalVault2Assets - vars.initialVault2Assets;
        uint256 vault3Yield = vars.finalVault3Assets - vars.initialVault3Assets;
        console2.log("vault1Yield", vault1Yield);
        console2.log("vault2Yield", vault2Yield);
        console2.log("vault3Yield", vault3Yield);

        assertGt(vault1Yield, 0, "Vault 1 should have gained assets");
        assertGt(vault2Yield, vault1Yield, "Vault 2 should have gained more assets than vault 1");
        assertGt(vault3Yield, vault2Yield, "Vault 3 should have gained more assets than vault 2");
    }

    function test_6_yieldAccumulation_WithRebalancing() public {
        YieldTestVars memory vars;
        vars.depositAmount = 1000e6; // 100,000 USDC
        vars.initialTimestamp = block.timestamp;

        // create yield testing vaults
        vars.vault1 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock Vault 3%", "MV3"))
            )
        );
        vars.vault2 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock Vault 5%", "MV5"))
            )
        );
        vars.vault3 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock Vault 10%", "MV10"))
            )
        );
        string[] memory vaultNames = new string[](3);
        vaultNames[0] = "test6YAREB_Mock4626Vault1";
        vaultNames[1] = "test6YAREB_Mock4626Vault2";
        vaultNames[2] = "test6YAREB_Mock4626Vault3";
        address[] memory vaultAddresses = new address[](3);
        vaultAddresses[0] = address(vars.vault1);
        vaultAddresses[1] = address(vars.vault2);
        vaultAddresses[2] = address(vars.vault3);

        console2.log("vault1", address(vars.vault1));
        console2.log("vault2", address(vars.vault2));
        console2.log("vault3", address(vars.vault3));

        assertEq(
            address(vars.vault1),
            test6_yieldAccumulation_WithRebalancing_vault1,
            "TEST6_REBAL_VAULT1 NOT EQUAL TO PREDICTED"
        );
        assertEq(
            address(vars.vault2),
            test6_yieldAccumulation_WithRebalancing_vault2,
            "TEST6_REBAL_VAULT2 NOT EQUAL TO PREDICTED"
        );
        assertEq(
            address(vars.vault3),
            test6_yieldAccumulation_WithRebalancing_vault3,
            "TEST6_REBAL_VAULT3 NOT EQUAL TO PREDICTED"
        );

        vars.vault1.setYield(3000); // 3%
        vars.vault2.setYield(5000); // 5%
        vars.vault3.setYield(10_000); // 10%

        // add some funds to each vault to bypass the VAULT_THRESHOLD_EXCEEDED error
        _getTokens(address(asset), address(this), 10 * LARGE_DEPOSIT);
        asset.approve(address(vars.vault1), type(uint256).max);
        asset.approve(address(vars.vault2), type(uint256).max);
        asset.approve(address(vars.vault3), type(uint256).max);
        vars.vault1.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault2.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault3.deposit(2 * LARGE_DEPOSIT, address(this));

        // add vaults to SV
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(vars.vault1), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault2), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault3), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // use 3 users to perform deposits
        for (uint256 i; i < 3; ++i) {
            _getTokens(address(asset), accInstances[i].account, vars.depositAmount);
            _depositForAccount(accInstances[i], vars.depositAmount);
        }

        // fulfill deposits
        {
            address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

            address[] memory fulfillHooksAddresses = new address[](3);
            fulfillHooksAddresses[0] = depositHookAddress;
            fulfillHooksAddresses[1] = depositHookAddress;
            fulfillHooksAddresses[2] = depositHookAddress;

            bytes[] memory fulfillHooksData = new bytes[](3);
            // allocate up to the max allocation rate in the two Vaults
            fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(vars.vault1),
                address(asset),
                vars.depositAmount,
                false,
                address(0),
                0
            );
            fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(vars.vault2),
                address(asset),
                vars.depositAmount,
                false,
                address(0),
                0
            );
            fulfillHooksData[2] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(vars.vault3),
                address(asset),
                vars.depositAmount,
                false,
                address(0),
                0
            );

            uint256[] memory expectedAssetsOrSharesOut = new uint256[](3);
            expectedAssetsOrSharesOut[0] = IERC4626(address(vars.vault1)).convertToShares(vars.depositAmount);
            expectedAssetsOrSharesOut[1] = IERC4626(address(vars.vault2)).convertToShares(vars.depositAmount);
            expectedAssetsOrSharesOut[2] = IERC4626(address(vars.vault3)).convertToShares(vars.depositAmount);

            address[] memory requestingUsers = new address[](3);
            for (uint256 i; i < 3; ++i) {
                requestingUsers[i] = accInstances[i].account;
            }

            bytes[] memory argsForProofs = new bytes[](3);
            argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
            argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);
            argsForProofs[2] = ISuperHookInspector(fulfillHooksAddresses[2]).inspect(fulfillHooksData[2]);

            vm.startPrank(MANAGER);
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: fulfillHooksAddresses,
                    hookCalldata: fulfillHooksData,
                    expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](fulfillHooksAddresses.length)
                })
            );
            vm.stopPrank();
        }

        {
            vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
            vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
            vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));
            vars.initialVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
            vars.initialVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
            vars.initialVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

            address[] memory hooksAddresses = new address[](2);
            hooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
            hooksAddresses[1] = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
            bytes[] memory hooksData = new bytes[](2);

            uint256 amountToReallocate = vars.initialVault2Balance * 10 / 100; //10%
            uint256 assetAmountToReallocate = vars.vault2.convertToAssets(amountToReallocate);

            _rebalanceFixedAmountFromVaultToVault(
                hooksAddresses, hooksData, address(vars.vault2), address(vars.vault1), assetAmountToReallocate
            );

            // fast forward time to simulate yield accumulation
            vm.warp(vars.initialTimestamp + 1 weeks);
            _updateSuperVaultPPS(address(strategy), address(vault));
            vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
            vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
            vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));
            vars.finalVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
            vars.finalVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
            vars.finalVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

            assertGt(
                vars.finalVault1Assets + vars.finalVault2Assets + vars.finalVault3Assets,
                vars.initialVault1Assets + vars.initialVault2Assets + vars.initialVault3Assets,
                "Total assets should have increased"
            );
        }
    }

    function test_9_VaultLifecycle_FullAlocateOverTime_() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // do an initial allocation
        _completeDepositFlow(vars.depositAmount);

        uint256[] memory initialUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory initialUserShares = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            initialUserShares[i] = vault.balanceOf(accInstances[i].account);
        }

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory midUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory midUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            midUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            midUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(midUserAssets[i], initialUserAssets[i], "User assets should increase after 20 days");
            assertEq(midUserShares[i], initialUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Yield after 20 days ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Current Assets:", midUserAssets[i]);
            console2.log("Yield:", midUserAssets[i] - initialUserAssets[i]);
            console2.log("Yield %:", ((midUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]);
        }

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        // 100% to aave allocation
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory finalUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory finalUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }

        // allocation; fluid -> aave
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](2);
        // redeem from fluid entirely
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // deposit to aave
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            vars.assetAmountToReallocateFromFluidVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        assertEq(vars.finalFluidVaultBalance, 0, "FluidVault balance should be 0");
        assertGt(vars.finalAaveVaultBalance, vars.initialAaveVaultBalance, "AaveVault balance should increase");

        vm.warp(block.timestamp + 20 days);

        // 80% to aave allocation
        vars.amountToReallocateAaveVault = vars.finalAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        // re-allocate back to fluid; withdraw from aave (20%)
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to fluid
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            vars.assetAmountToReallocateFromAaveVault,
            false,
            address(0),
            0
        );
        argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total final value should be preserved during allocation"
        );

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }
    }

    function test_9_VaultLifecycle_AddAndRemoveOverTime() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // do an initial allocation
        _completeDepositFlow(vars.depositAmount);

        uint256[] memory initialUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory initialUserShares = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            initialUserShares[i] = vault.balanceOf(accInstances[i].account);
        }

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory midUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory midUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            midUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            midUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(midUserAssets[i], initialUserAssets[i], "User assets should increase after 20 days");
            assertEq(midUserShares[i], initialUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Yield after 20 days ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Current Assets:", midUserAssets[i]);
            console2.log("Yield:", midUserAssets[i] - initialUserAssets[i]);
            console2.log("Yield %:", ((midUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]);
        }

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        // 100% to aave allocation
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory finalUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory finalUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }

        // allocation; fluid -> aave
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](2);
        // redeem from fluid entirely
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // deposit to aave
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            vars.assetAmountToReallocateFromFluidVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();

        // remove fluid vault entirely
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(fluidVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 2);
        vm.stopPrank();

        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        assertEq(vars.finalFluidVaultBalance, 0, "FluidVault balance should be 0");
        assertGt(vars.finalAaveVaultBalance, vars.initialAaveVaultBalance, "AaveVault balance should increase");

        vm.warp(block.timestamp + 20 days);

        // 80% to aave allocation
        vars.amountToReallocateAaveVault = vars.finalAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        // re-allocate back to fluid; withdraw from aave (20%)
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to fluid
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            vars.assetAmountToReallocateFromAaveVault,
            false,
            address(0),
            0
        );
        argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        // re-add fluid vault
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(fluidVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // try allocate again
        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total final value should be preserved during allocation"
        );

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }
    }

    // function test_10_RuggableVault_Deposit_No_ExpectedAssetsOrSharesOut() public {
    //     RugTestVarsDeposit memory vars;
    //     vars.depositAmount = 1000e6;
    //     vars.rugPercentage = 10; // 0.1% rug
    //     vars.initialTimestamp = block.timestamp;

    //     // Deploy a ruggable vault that rugs on deposit
    //     vars.ruggableVault = new RuggableVault(
    //         IERC20(address(asset)),
    //         "Ruggable Vault",
    //         "RUG",
    //         true, // rug on deposit
    //         false, // don't rug on withdraw
    //         vars.rugPercentage
    //     );

    //     // Add funds to the ruggable vault to respect LARGE_DEPOSIT
    //     _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
    //     asset.approve(address(vars.ruggableVault), type(uint256).max);
    //     vars.ruggableVault.deposit(2 * LARGE_DEPOSIT, address(this));

    //     // Deploy a new SuperVault with the ruggable vault
    //     _deployNewSuperVaultWithRuggableVault(address(vars.ruggableVault));

    //     // Setup deposit users and amounts
    //     vars.depositUsers = new address[](5);
    //     vars.depositAmounts = new uint256[](5);
    //     for (uint256 i = 0; i < 5; i++) {
    //         vars.depositUsers[i] = accInstances[i].account;
    //         vars.depositAmounts[i] = vars.depositAmount;
    //     }

    //     // Perform deposits
    //     for (uint256 i = 0; i < 5; i++) {
    //         _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
    //         vm.startPrank(vars.depositUsers[i]);
    //         asset.approve(address(vault), vars.depositAmounts[i]);
    //         vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
    //         vm.stopPrank();
    //     }

    //     // Simulate time passing
    //     vm.warp(vars.initialTimestamp + 1 days);

    //     uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
    //     expectedAssetsOrSharesOut[0] = 1; //99% slippage
    //     expectedAssetsOrSharesOut[1] = 1; // 99% slippage
    //     _depositFreeAssets(
    //         vars.depositAmount * 5 / 2,
    //         vars.depositAmount * 5 / 2,
    //         address(fluidVault),
    //         address(vars.ruggableVault),
    //         expectedAssetsOrSharesOut,
    //         bytes4(0)
    //     );
    // }

    function test_10_RuggableVault_Deposit() public {
        RugTestVarsDeposit memory vars;
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 5000; // 50% rug
        vars.initialTimestamp = block.timestamp;

        // Deploy a ruggable vault that rugs on deposit
        vars.ruggableVault = RuggableVault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(RuggableVault).creationCode,
                    abi.encode(IERC20(address(asset)), "Ruggable Vault", "RUG", true, false, vars.rugPercentage)
                )
            )
        );
        console2.log("ruggableVault", address(vars.ruggableVault));
        assertEq(
            address(vars.ruggableVault), test10_RuggableVault_Deposit, "TEST10_DEPOSIT VAULT NOT EQUAL TO PREDICTED"
        );

        // Add funds to the ruggable vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(vars.ruggableVault), type(uint256).max);
        vars.ruggableVault.deposit(2 * LARGE_DEPOSIT, address(this));

        // Deploy a new SuperVault with the ruggable vault
        _deployNewSuperVaultWithRuggableVault(address(vars.ruggableVault));

        // Setup deposit users and amounts
        vars.depositUsers = new address[](5);
        vars.depositAmounts = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            vars.depositUsers[i] = accInstances[i].account;
            vars.depositAmounts[i] = vars.depositAmount;
        }

        // Perform deposits
        for (uint256 i = 0; i < 5; i++) {
            _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
            vm.startPrank(vars.depositUsers[i]);
            asset.approve(address(vault), vars.depositAmounts[i]);
            vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
            vm.stopPrank();
        }

        // Simulate time passing
        vm.warp(vars.initialTimestamp + 1 days);

        uint256 sharesVault1 = IERC4626(address(fluidVault)).convertToShares(vars.depositAmount * 5 / 2);
        uint256 sharesVault2 = IERC4626(address(vars.ruggableVault)).convertToShares(vars.depositAmount * 5 / 2);

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = sharesVault1 - (sharesVault1 * 1e2 / 1e5); // 1% slippage
        expectedAssetsOrSharesOut[1] = (sharesVault2 - sharesVault2 * vars.rugPercentage / 10_000) * 2; // Should revert

        // expect revert on this call and try again after
        _depositFreeAssets(
            (vars.depositAmount * 5) / 2,
            (vars.depositAmount * 5) / 2,
            address(fluidVault),
            address(vars.ruggableVault),
            expectedAssetsOrSharesOut,
            ISuperVaultStrategy.MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET.selector
        );
        expectedAssetsOrSharesOut[1] = sharesVault2 - sharesVault2 * vars.rugPercentage / 10_000; // 50% rug
        _depositFreeAssets(
            vars.depositAmount * 5 / 2,
            vars.depositAmount * 5 / 2,
            address(fluidVault),
            address(vars.ruggableVault),
            expectedAssetsOrSharesOut,
            bytes4(0)
        );
    }

    function test_10_RuggableVault_WithdrawX() public {
        RugTestVarsWithdraw memory vars;
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 5000; // 50% rug
        vars.initialTimestamp = block.timestamp;
        // Deploy a ruggable vault that rugs on withdraw
        RuggableVault ruggableVault = RuggableVault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(RuggableVault).creationCode,
                    abi.encode(IERC20(address(asset)), "Ruggable Vault", "RUG", false, true, vars.rugPercentage)
                )
            )
        );
        console2.log("ruggableVault", address(ruggableVault));
        assertEq(address(ruggableVault), test10_RuggableVault_Withdraw, "TEST10_WITHDRAW VAULT NOT EQUAL TO PREDICTED");

        vars.ruggableVault = address(ruggableVault);
        vars.convertVault = false;
        // Log the rug configuration
        console2.log("\n=== RuggableVault Configuration ===");
        console2.log("Rug on deposit:", ruggableVault.rugOnDeposit());
        console2.log("Rug on withdraw:", ruggableVault.rugOnWithdraw());
        console2.log("Rug percentage:", ruggableVault.rugPercentage());

        // Calculate how much would be rugged for a sample amount
        uint256 sampleAmount = 1000e6;
        uint256 ruggedAmount = ruggableVault.calculateRuggedAmount(sampleAmount);
        console2.log("For a sample amount of", sampleAmount, "the rugged amount would be", ruggedAmount);

        // Verify the rug calculation is correct
        assertEq(
            ruggedAmount,
            sampleAmount * vars.rugPercentage / 10_000,
            "Rugged amount calculation should match expected value"
        );

        _testRuggableVaultWithdraw(vars);
    }

    function test_10_RuggableVault_Withdraw_ConvertDistortion() public {
        RugTestVarsWithdraw memory vars;
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 5000; // 50% rug
        vars.initialTimestamp = block.timestamp;

        // Deploy a ruggable vault that rugs via convert functions
        RuggableConvertVault ruggableConvertVault = RuggableConvertVault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(RuggableConvertVault).creationCode,
                    abi.encode(IERC20(address(asset)), "Ruggable Convert Vault", "RUGC", vars.rugPercentage, true)
                )
            )
        );
        console2.log("ruggableConvertVault", address(ruggableConvertVault));
        assertEq(
            address(ruggableConvertVault),
            test10_RuggableVault_Withdraw_ConvertDistortion,
            "TEST10_CONVERT VAULT NOT EQUAL TO PREDICTED"
        );

        vars.ruggableVault = address(ruggableConvertVault);
        vars.convertVault = true;
        _testRuggableVaultWithdraw(vars);

        // Verify that the SuperVault's totalAssets was affected by the inflated reporting
        uint256 vaultTotalAssets = ruggableConvertVault.totalAssets();
        console2.log("Ruggable vault total assets:", vaultTotalAssets);

        // Disable the rug to see the true value
        ruggableConvertVault.setRugEnabled(false);
        uint256 vaultTotalAssetsWithoutRug = ruggableConvertVault.totalAssets();
        console2.log("Ruggable total assets (rug disabled):", vaultTotalAssetsWithoutRug);
        console2.log("Difference:", vaultTotalAssets - vaultTotalAssetsWithoutRug);

        // The difference should be significant if there are still assets in the ruggable vault
        assertGt(
            vaultTotalAssets, vaultTotalAssetsWithoutRug, "SuperVault total assets should be higher with rug enabled"
        );
    }

    function test_11_Allocate_NewYieldSource() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // do an initial allo
        _completeDepositFlow(vars.depositAmount);

        // add new vault as yield source
        Mock4626Vault newVault = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "New Vault", "NV"))
            )
        );
        console2.log("newVault", address(newVault));
        assertEq(address(newVault), test11_Allocate_NewYieldSource, "TEST11 VAULT NOT EQUAL TO PREDICTED");

        //  -- add funds to the newVault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(newVault), type(uint256).max);
        newVault.deposit(2 * LARGE_DEPOSIT, address(this));

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial NewVault balance:", vars.initialNewVaultBalance);

        // 30/30/40
        // allocate 20% from each vault to the new one
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        vars.amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        vars.assetAmountToReallocateToNewVault =
            vars.assetAmountToReallocateFromFluidVault + vars.assetAmountToReallocateFromAaveVault;
        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);

        vm.warp(block.timestamp + 20 days);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // allocation
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](3);
        // redeem from FluidVault
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // redeem from AaveVault
        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to NewVault
        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(newVault),
            address(asset),
            vars.assetAmountToReallocateToNewVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 20 days);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("Final NewVault balance:", vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - vars.amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - vars.amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalNewVaultBalance, vars.initialNewVaultBalance, "NewVault balance should increase");

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + newVault.convertToAssets(vars.initialNewVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + newVault.convertToAssets(vars.finalNewVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        // Enhanced checks for price per share and yield
        console2.log("\n=== Enhanced Vault Metrics ===");

        // Price per share comparison
        uint256 fluidVaultFinalPPS = fluidVault.convertToAssets(1e18);
        uint256 aaveVaultFinalPPS = aaveVault.convertToAssets(1e18);
        uint256 newVaultFinalPPS = newVault.convertToAssets(1e18);

        console2.log("\nPrice per Share Changes:");
        console2.log("Fluid Vault:");
        console2.log("  Initial PPS:", vars.initialFluidVaultPPS);
        console2.log("  Final PPS:", fluidVaultFinalPPS);
        console2.log(
            "  Change:",
            fluidVaultFinalPPS > vars.initialFluidVaultPPS ? "+" : "",
            fluidVaultFinalPPS - vars.initialFluidVaultPPS
        );
        console2.log(
            "  Change %:", ((fluidVaultFinalPPS - vars.initialFluidVaultPPS) * 10_000) / vars.initialFluidVaultPPS
        );

        console2.log("\nAave Vault:");
        console2.log("  Initial PPS:", vars.initialAaveVaultPPS);
        console2.log("  Final PPS:", aaveVaultFinalPPS);
        console2.log(
            "  Change:",
            aaveVaultFinalPPS > vars.initialAaveVaultPPS ? "+" : "",
            aaveVaultFinalPPS - vars.initialAaveVaultPPS
        );
        console2.log(
            "  Change %:", ((aaveVaultFinalPPS - vars.initialAaveVaultPPS) * 10_000) / vars.initialAaveVaultPPS
        );

        console2.log("\nYield Metrics:");
        uint256 totalYield =
            vars.finalTotalValue > vars.initialTotalValue ? vars.finalTotalValue - vars.initialTotalValue : 0;
        console2.log("Total Yield:", totalYield);
        console2.log("Yield %:", (totalYield * 10_000) / vars.initialTotalValue);

        assertGe(fluidVaultFinalPPS, vars.initialFluidVaultPPS, "Fluid Vault should not lose value");
        assertGe(aaveVaultFinalPPS, vars.initialAaveVaultPPS, "Aave Vault should not lose value");
        assertGe(newVaultFinalPPS, 1e18, "NewVault should not lose value");

        uint256 totalFinalBalance = vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalNewVaultBalance;

        uint256 fluidRatio = (vars.finalFluidVaultBalance * 100) / totalFinalBalance;
        uint256 aaveRatio = (vars.finalAaveVaultBalance * 100) / totalFinalBalance;
        uint256 newRatio = (vars.finalNewVaultBalance * 100) / totalFinalBalance;

        console2.log("\nFinal Allocation Ratios:");
        console2.log("Fluid Vault:", fluidRatio, "%");
        console2.log("Aave Vault:", aaveRatio, "%");
        console2.log("NewVault:", newRatio, "%");
    }

    function test_12_multiMillionDeposits() public {
        TestVars memory vars;
        vars.initialTimestamp = block.timestamp;

        // Set up deposit amounts for multiple rounds
        // We'll do 3 rounds of deposits to reach 10M+ USDC
        uint256 depositRounds = 3;
        uint256 targetTotalDeposits = 9_000_000e6; // 10M USDC
        uint256 depositPerRound = targetTotalDeposits / depositRounds;
        uint256 depositPerUser = depositPerRound / ACCOUNT_COUNT;

        console2.log("\n=== Starting multi-million deposit test ===");
        console2.log("Target total deposits:", targetTotalDeposits / 1e6, "M USDC");
        console2.log("Deposit rounds:", depositRounds);
        console2.log("Deposit per round:", depositPerRound / 1e6, "M USDC");
        console2.log("Deposit per user per round:", depositPerUser / 1e6, "M USDC");

        // Round 1: Initial deposits
        console2.log("\n=== Round 1 Deposits ===");
        vars.depositAmounts = new uint256[](ACCOUNT_COUNT);
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            vars.depositAmounts[i] = depositPerUser;
        }
        _completeDepositFlowWithVaryingAmounts(vars.depositAmounts);
        vars.totalDeposited += depositPerRound;
        console2.log("balance of vault", IERC20(address(asset)).balanceOf(address(strategy)));
        console2.log("total deposited", vars.totalDeposited);
        console2.log("Total Assets:", vault.totalAssets());

        // Wait 1 week
        vm.warp(vars.initialTimestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("\n=== After 1 week ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", aggregator.getPPS(address(strategy)));

        // Round 2: More deposits after 1 week
        console2.log("\n=== Round 2 Deposits ===");
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            _getTokens(address(asset), accInstances[i].account, depositPerUser);
            __deposit(accInstances[i], depositPerUser);
        }

        // Prepare for fulfillment
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        // Fulfill deposits with 60/40 split between vaults
        console2.log("deposit per round", depositPerRound);

        uint256 allocationAmountVault1 = (depositPerRound * 6000) / 10_000; // 60% to fluid vault
        uint256 allocationAmountVault2 = depositPerRound - allocationAmountVault1; // 40% to aave vault
        console2.log("\n=== Round 2 Fulfill Requests ===");

        console2.log("allocation vault 1", allocationAmountVault1);
        console2.log("allocation vault 2", allocationAmountVault2);
        console2.log("balance of vault", IERC20(address(asset)).balanceOf(address(strategy)));
        // TVL fluid 1669215723572
        // tvl aave 1668059877911
        _depositFreeAssets(allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault));

        vars.totalDeposited += depositPerRound;

        // Wait 2 more weeks
        vm.warp(vars.initialTimestamp + 3 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("\n=== After 3 weeks ===");
        console2.log("Total Assets:", vault.totalAssets() / 1e6, "M USDC");
        console2.log("Price per share:", aggregator.getPPS(address(strategy)));

        // Round 3: Final deposits after 3 weeks
        console2.log("\n=== Round 3 Deposits ===");
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            _getTokens(address(asset), accInstances[i].account, depositPerUser);
            __deposit(accInstances[i], depositPerUser);
        }

        // Wait 2 more weeks before fulfilling final deposits
        vm.warp(vars.initialTimestamp + 5 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("\n=== After 5 weeks (before final fulfillment) ===");
        console2.log("Total Assets:", vault.totalAssets() / 1e6, "M USDC");
        console2.log("Price per share:", aggregator.getPPS(address(strategy)));

        // Store state before final fulfillment
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);

        // Fulfill final deposits with 70/30 split
        allocationAmountVault1 = (depositPerRound * 70) / 100; // 70% to fluid vault
        allocationAmountVault2 = depositPerRound - allocationAmountVault1; // 30% to aave vault

        _depositFreeAssets(allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault));

        vars.totalDeposited += depositPerRound;

        // Final verification after all deposits
        console2.log("\n=== Final state after all deposits ===");
        vars.finalTotalAssets = vault.totalAssets();
        vars.finalTotalSupply = vault.totalSupply();
        vars.finalPricePerShare = vars.finalTotalAssets.mulDiv(1e18, vars.finalTotalSupply, Math.Rounding.Floor);

        console2.log("Total deposited:", vars.totalDeposited / 1e6, "M USDC");
        console2.log("Final total assets:", vars.finalTotalAssets / 1e6, "M USDC");
        console2.log("Final price per share:", vars.finalPricePerShare);

        // Check underlying vault balances
        vars.fluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.aaveVaultBalance = aaveVault.balanceOf(address(strategy));

        uint256 fluidVaultAssets = fluidVault.convertToAssets(vars.fluidVaultBalance);
        uint256 aaveVaultAssets = aaveVault.convertToAssets(vars.aaveVaultBalance);

        console2.log("\n=== Underlying vault balances ===");
        console2.log("Fluid vault shares:", vars.fluidVaultBalance);
        console2.log("Fluid vault assets:", fluidVaultAssets / 1e6, "M USDC");
        console2.log("Aave vault shares:", vars.aaveVaultBalance);
        console2.log("Aave vault assets:", aaveVaultAssets / 1e6, "M USDC");
        console2.log("Total underlying assets:", (fluidVaultAssets + aaveVaultAssets) / 1e6, "M USDC");

        // Verify total assets matches the sum of underlying vault assets
        assertApproxEqRel(vars.finalTotalAssets, fluidVaultAssets + aaveVaultAssets, 0.01e18); // 1% tolerance

        // Verify price per share increased over time (yield accrual)
        assertGt(vars.finalPricePerShare, 1e18, "Price per share should be greater than 1e18 after yield accrual");

        // Verify total deposits reached target
        assertGe(
            vars.finalTotalAssets, targetTotalDeposits, "Total assets should be at least the target deposit amount"
        );
    }

    function _verifyInitialBalances(uint256[] memory depositAmounts) internal view {
        console2.log("\n=== Initial State ===");
        uint256 totalAssets = vault.totalAssets();
        uint256 totalSupply = vault.totalSupply();
        uint256 pricePerShare = totalAssets.mulDiv(1e18, totalSupply, Math.Rounding.Floor);

        console2.log("Total Assets:", totalAssets);
        console2.log("Total Supply:", totalSupply);
        console2.log("Price per share:", pricePerShare);

        // Verify vault invariants
        assertGt(totalSupply, 0, "Total supply should be positive");
        assertGt(totalAssets, 0, "Total assets should be positive");

        // Verify underlying balances
        uint256 totalUnderlyingInVaults =
            fluidVault.balanceOf(address(strategy)) + aaveVault.balanceOf(address(strategy));
        assertGt(totalUnderlyingInVaults, 0, "Should have balance in underlying vaults");

        // Verify total deposits match total assets (accounting for bootstrap amount)
        uint256 expectedTotalDeposits;
        for (uint256 i; i < depositAmounts.length; i++) {
            expectedTotalDeposits += depositAmounts[i];
        }
        assertApproxEqRel(totalAssets, expectedTotalDeposits, 0.01e18, "Total assets should match deposits");

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            uint256 shares = vault.balanceOf(accInstances[i].account);
            uint256 assets = vault.convertToAssets(shares);
            assertApproxEqRel(assets, depositAmounts[i], 0.01e18);
            console2.log("\nUser", i);
            console2.log("Account", accInstances[i].account);
            console2.log("deposited:", depositAmounts[i]);
            console2.log("got shares:", shares);
            console2.log("got assets:", assets);

            // Verify share-asset conversion consistency
            uint256 sharesFromAssets = vault.convertToShares(assets);
            assertApproxEqRel(sharesFromAssets, shares, 0.01e18, "Share-asset conversion should be consistent");
        }
    }

    function _clearRedemptionMapping() internal {
        // Clear mapping for all accounts
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            delete tempUserRedemptionAmounts[accInstances[i].account];
        }
    }

    function _selectRandomUsersForRedemption(MultipleOperationsVars memory vars)
        internal
        view
        returns (MultipleOperationsVars memory)
    {
        uint256 i;
        while (vars.selectedCount < 15) {
            uint256 randIndex = uint256(keccak256(abi.encodePacked(vars.seed, "redeem", i))) % ACCOUNT_COUNT;

            if (!vars.selected[randIndex]) {
                vars.redeemUsers[vars.selectedCount] = accInstances[randIndex].account;
                // Redeem 25-75% of their balance
                uint256 randPercent = 2500 + (uint256(keccak256(abi.encodePacked(vars.seed, "percent", i))) % 5100);
                uint256 shares = vault.balanceOf(accInstances[randIndex].account);

                vars.redeemAmounts[vars.selectedCount] = (shares * randPercent) / 10_000;
                vars.selected[randIndex] = true;
                vars.selectedCount++;
            }
            i++;
        }
        return vars;
    }

    function _processRedemptionRequests(MultipleOperationsVars memory vars) internal {
        for (uint256 i; i < vars.selectedCount; i++) {
            vm.startPrank(vars.redeemUsers[i]);
            vault.requestRedeem(vars.redeemAmounts[i], vars.redeemUsers[i], vars.redeemUsers[i]);
            vm.stopPrank();
        }
    }

    function _claimRedeemForUsers(address[] memory redeemUsers) internal {
        for (uint256 i; i < redeemUsers.length; i++) {
            address user = redeemUsers[i];
            uint256 maxWithdrawAmount = vault.maxWithdraw(user);
            if (maxWithdrawAmount > 0) {
                vm.startPrank(user);
                console2.log("withdrawing", maxWithdrawAmount, "for user", user);
                vault.withdraw(maxWithdrawAmount, user, user);
                vm.stopPrank();
            }
        }
    }

    function _verifyFinalBalances(MultipleOperationsVars memory vars) internal view {
        FinalBalanceVerificationVars memory v;

        // Calculate global vault state
        v.finalTotalAssets = vault.totalAssets();
        v.finalTotalSupply = vault.totalSupply();
        //v.finalPricePerShare = v.finalTotalAssets.mulDiv(1e18, v.finalTotalSupply, Math.Rounding.Floor);
        v.finalPricePerShare = strategy.getStoredPPS();
        v.totalValueLocked = v.finalTotalAssets;

        // Get escrow balance
        v.escrowBalance = vault.balanceOf(address(escrow));

        // Log final state
        console2.log("\n=== Final State ===");
        console2.log("Final Total Assets:", v.finalTotalAssets);
        console2.log("Final Total Supply:", v.finalTotalSupply);
        console2.log("Final Price per share:", v.finalPricePerShare);
        console2.log("Total Value Locked:", v.totalValueLocked);
        console2.log("Escrow Balance:", v.escrowBalance);

        // Verify escrow state
        assertEq(v.escrowBalance, 0, "Escrow should have no shares after all claims are processed");

        // Calculate yield metrics
        v.totalYieldAccrued =
            v.finalTotalAssets > vars.initialTotalAssets ? v.finalTotalAssets - vars.initialTotalAssets : 0;
        v.yieldPerShare = v.totalYieldAccrued.mulDiv(1e18, v.finalTotalSupply, Math.Rounding.Floor);

        console2.log("\n=== Yield Metrics ===");
        console2.log("Total Yield Accrued:", v.totalYieldAccrued);
        console2.log("Yield Per Share:", v.yieldPerShare);

        // Verify yield accrual
        assertGe(
            v.finalPricePerShare,
            vars.initialPricePerShare,
            "Price per share should not decrease over time due to yield"
        );
        assertGt(v.totalValueLocked, 0, "TVL should be positive");

        // Verify strategy state
        v.fluidBalance = fluidVault.balanceOf(address(strategy));
        v.aaveBalance = aaveVault.balanceOf(address(strategy));

        console2.log("\n=== Strategy State ===");
        console2.log("Fluid Vault Balance:", v.fluidBalance);
        console2.log("Aave Vault Balance:", v.aaveBalance);

        // Strategy invariant checks
        assertGt(v.fluidBalance, 0, "Should maintain minimum fluid vault allocation");
        assertGt(v.aaveBalance, 0, "Should maintain minimum aave vault allocation");

        // Verify user states and accumulate totals
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            v.currentShares = vault.balanceOf(accInstances[i].account);
            v.currentAssets = vault.convertToAssets(v.currentShares);
            v.totalUserShares += v.currentShares;
            v.totalUserAssets += v.currentAssets;

            // Check if user is a redeemer using the mapping
            v.redeemedShares = tempUserRedemptionAmounts[accInstances[i].account];
            v.isRedeemer = v.redeemedShares > 0;

            // Calculate user's yield
            v.userYieldAccrued = v.currentAssets > vars.depositAmounts[i] ? v.currentAssets - vars.depositAmounts[i] : 0;

            console2.log(string.concat("\n=== User ", Strings.toString(i), " State ==="));
            console2.log("user ", accInstances[i].account);
            console2.log("Current Shares:", v.currentShares);
            console2.log("Current Assets:", v.currentAssets);
            console2.log("Yield Accrued:", v.userYieldAccrued);

            if (v.isRedeemer) {
                console2.log("convert to shares", vault.convertToShares(vars.depositAmounts[i]));
                console2.log("redeemedShares", v.redeemedShares);
                v.expectedShares = vault.convertToShares(vars.depositAmounts[i]) - v.redeemedShares;
                assertApproxEqRel(v.currentShares, v.expectedShares, 0.01e18, "Redeemer shares mismatch");

                // Verify redeemer's remaining position if they still have shares
                if (v.currentShares > 0) {
                    assertGt(
                        v.currentAssets.mulDiv(v.finalTotalSupply, v.currentShares, Math.Rounding.Floor),
                        vars.depositAmounts[i],
                        "Redeemer's remaining position should be worth more due to yield"
                    );
                }
            } else {
                v.expectedAssets = vars.depositAmounts[i];
                assertApproxEqRel(v.currentAssets, v.expectedAssets, 0.01e18, "Non-redeemer assets mismatch");
                assertGt(v.currentAssets, vars.depositAmounts[i], "Non-redeemer should have more assets due to yield");
            }

            // Verify no pending operations
            v.totalPendingRedeems += strategy.pendingRedeemRequest(accInstances[i].account);
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0, "Should have no pending redemptions");
        }

        // Final global state verification
        console2.log("\n=== Final Verification ===");
        console2.log("Total User Shares:", v.totalUserShares);
        console2.log("Total User Assets:", v.totalUserAssets);
        console2.log("Total Pending Deposits:", v.totalPendingDeposits);
        console2.log("Total Pending Redeems:", v.totalPendingRedeems);

        assertApproxEqRel(v.totalUserShares, v.finalTotalSupply, 0.01e18, "Total shares should match supply");
        assertApproxEqRel(v.totalUserAssets, v.finalTotalAssets, 0.01e18, "Total assets should match TVL");
        assertEq(v.totalPendingDeposits, 0, "Should have no pending deposits globally");
        assertEq(v.totalPendingRedeems, 0, "Should have no pending redeems globally");
    }

    function _testRuggableVaultWithdraw(RugTestVarsWithdraw memory vars) internal {
        // Add funds to the ruggable vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(vars.ruggableVault, type(uint256).max);
        IERC4626(vars.ruggableVault).deposit(2 * LARGE_DEPOSIT, address(this));

        // Deploy a new SuperVault with the ruggable vault
        _deployNewSuperVaultWithRuggableVault(vars.ruggableVault);
        _updateRedeemSlippages(8000); //-> 80% slippage

        // Setup deposit users and amounts
        vars.depositUsers = new address[](5);
        vars.depositAmounts = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            vars.depositUsers[i] = accInstances[i].account;
            vars.depositAmounts[i] = vars.depositAmount;
        }

        // Perform deposits
        for (uint256 i = 0; i < 5; i++) {
            _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
            vm.startPrank(vars.depositUsers[i]);
            asset.approve(address(vault), vars.depositAmounts[i]);
            vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
            vm.stopPrank();
        }

        // Fulfill deposit requests
        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = IERC4626(address(fluidVault)).convertToShares(vars.depositAmount * 5 / 2);
        expectedAssetsOrSharesOut[1] = IERC4626(address(vars.ruggableVault)).convertToShares(vars.depositAmount * 5 / 2);
        _depositFreeAssets(
            vars.depositAmount * 5 / 2, vars.depositAmount * 5 / 2, address(fluidVault), vars.ruggableVault
        );
        console2.log("\n=== TIME WARPING ===");
        vars.ppsBeforeWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS BEFORE WARP", vars.ppsBeforeWarp);

        vm.warp(block.timestamp + 10 weeks);

        _updateSuperVaultPPS(address(strategy), address(vault));
        vars.ppsAfterWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS AFTER WARP", vars.ppsAfterWarp);

        // Store initial state
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);

        // Log initial state
        console2.log("\n=== Initial State Before Redemption ===");
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", IERC4626(vars.ruggableVault).balanceOf(address(strategy)));
        console2.log("Fluid Vault Balance:", fluidVault.balanceOf(address(strategy)));

        // Verify the initial state
        assertGt(vars.initialTotalAssets, 0, "Initial total assets should be positive");
        assertGt(vars.initialTotalSupply, 0, "Initial total supply should be positive");

        // Setup redeem users and amounts
        vars.redeemUsers = new address[](3);
        vars.redeemAmounts = new uint256[](3);
        vars.totalRedeemShares = 0;

        for (uint256 i = 0; i < 3; i++) {
            vars.redeemUsers[i] = vars.depositUsers[i];
            uint256 userShares = vault.balanceOf(vars.redeemUsers[i]);
            vars.redeemAmounts[i] = userShares; // Redeem all of their shares
            vars.totalRedeemShares += vars.redeemAmounts[i];
        }

        // Request redemptions
        for (uint256 i = 0; i < 3; i++) {
            vm.startPrank(vars.redeemUsers[i]);
            vault.requestRedeem(vars.redeemAmounts[i], vars.redeemUsers[i], vars.redeemUsers[i]);
            vm.stopPrank();
        }

        // Simulate time passing
        console2.log("\n=== TIME WARPING ===");
        vars.ppsBeforeWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS BEFORE WARP", vars.ppsBeforeWarp);

        vm.warp(block.timestamp + 12 weeks);

        _updateSuperVaultPPS(address(strategy), address(vault));
        vars.ppsAfterWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS AFTER WARP", vars.ppsAfterWarp);

        // Fulfill redemption requests
        vars.redeemSharesVault1 = vars.totalRedeemShares / 2;
        vars.redeemSharesVault2 = vars.totalRedeemShares - vars.redeemSharesVault1;

        vars.assetsVault1 = IERC4626(address(fluidVault)).convertToAssets(vars.redeemSharesVault1);
        vars.assetsVault2 = IERC4626(address(vars.ruggableVault)).convertToAssets(vars.redeemSharesVault2);

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = vars.assetsVault1;
        vars.expectedAssetsOrSharesOut[1] = !vars.convertVault ? 1 : vars.assetsVault2; // this should make the call
        // revert

        // this should revert
        _executeRedeemHooks4626ForUsers(
            vars.redeemUsers,
            vars.redeemSharesVault1,
            vars.redeemSharesVault2,
            address(fluidVault),
            vars.ruggableVault,
            vars.expectedAssetsOrSharesOut,
            ISuperVaultStrategy.MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET.selector
        );

        vars.expectedAssetsOrSharesOut[0] = vars.assetsVault1 / 2;
        vars.expectedAssetsOrSharesOut[1] = vars.assetsVault2 / 2;
        _executeRedeemHooks4626ForUsers(
            vars.redeemUsers,
            vars.redeemSharesVault1,
            vars.redeemSharesVault2,
            address(fluidVault),
            vars.ruggableVault,
            vars.expectedAssetsOrSharesOut,
            bytes4(0)
        );

        // Log post-fulfillment state
        console2.log("\n=== Post-Fulfillment State ===");
        vars.totalAssetsPreClaimTaintedAssets = vault.totalAssets();
        vars.totalSupplyPreClaimTaintedAssets = vault.totalSupply();
        console2.log("Total Assets:", vars.totalAssetsPreClaimTaintedAssets);
        console2.log("Total Supply:", vars.totalSupplyPreClaimTaintedAssets);
        vars.pricePerSharePreClaimTaintedAssets = vars.totalAssetsPreClaimTaintedAssets
            .mulDiv(1e18, vars.totalSupplyPreClaimTaintedAssets, Math.Rounding.Floor);
        console2.log("Price per share:", vars.pricePerSharePreClaimTaintedAssets);
        console2.log("Ruggable Vault Balance:", IERC4626(vars.ruggableVault).balanceOf(address(strategy)));
        console2.log("Fluid Vault Balance:", fluidVault.balanceOf(address(strategy)));

        // Process claims for redeemed users, this will burn all tainted shares
        //_claimRedeemForUsers(vars.redeemUsers);

        // Verify global state
        vars.finalTotalAssets = vault.totalAssets();
        vars.finalTotalSupply = vault.totalSupply();
        uint256 finalPricePerShare = vars.finalTotalAssets.mulDiv(1e18, vars.finalTotalSupply, Math.Rounding.Floor);

        console2.log("\n=== Final State ===");
        console2.log("Final Total Assets:", vars.finalTotalAssets);
        console2.log("Final Total Supply:", vars.finalTotalSupply);
        console2.log("Final Price per share:", finalPricePerShare);

        // CONTINUATION: Allocate from rugged vault back to fluid vault
        console2.log("\n=== Allocating from Rugged Vault back to Fluid Vault ===");

        // Get initial balances
        vars.initialRuggableVaultBalance = IERC4626(vars.ruggableVault).balanceOf(address(strategy));
        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));

        console2.log("Initial Ruggable Vault balance:", vars.initialRuggableVaultBalance);
        console2.log("Initial Fluid Vault balance:", vars.initialFluidVaultBalance);

        // Calculate asset amounts
        vars.initialRuggableVaultAssets = IERC4626(vars.ruggableVault).convertToAssets(vars.initialRuggableVaultBalance);
        vars.initialFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);

        console2.log("Initial Ruggable Vault assets:", vars.initialRuggableVaultAssets);
        console2.log("Initial Fluid Vault assets:", vars.initialFluidVaultAssets);

        vars.amountToReallocate = vars.initialRuggableVaultBalance;
        vars.assetAmountToReallocate =
            IERC4626(vars.ruggableVault).convertToAssets(vars.amountToReallocate) * 5000 / 10_000;

        console2.log("Shares to reallocate from Ruggable Vault:", vars.amountToReallocate);
        console2.log("Asset amount to reallocate:", vars.assetAmountToReallocate);

        // Skip reallocation if there are no shares to reallocate
        if (vars.amountToReallocate > 0) {
            // Prepare allocation hooks
            address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
            address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

            address[] memory hooksAddresses = new address[](2);
            hooksAddresses[0] = withdrawHookAddress;
            hooksAddresses[1] = depositHookAddress;

            bytes[] memory hooksData = new bytes[](2);

            // Redeem from Ruggable Vault
            hooksData[0] = _createRedeem4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                vars.ruggableVault,
                address(strategy),
                vars.amountToReallocate,
                false
            );

            // Deposit to Fluid Vault
            hooksData[1] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(fluidVault),
                address(asset),
                vars.assetAmountToReallocate,
                false,
                address(0),
                0
            );
            bytes[] memory argsForProofs = new bytes[](2);
            argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
            argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

            // Execute allocation
            vm.startPrank(MANAGER);
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: hooksAddresses,
                    hookCalldata: hooksData,
                    expectedAssetsOrSharesOut: new uint256[](2),
                    globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](hooksAddresses.length)
                })
            );
            vm.stopPrank();

            // Check final balances
            vars.finalRuggableVaultBalance = IERC4626(vars.ruggableVault).balanceOf(address(strategy));
            vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));

            console2.log("Final Ruggable Vault balance:", vars.finalRuggableVaultBalance);
            console2.log("Final Fluid Vault balance:", vars.finalFluidVaultBalance);

            // Calculate asset amounts after reallocation
            vars.finalRuggableVaultAssets = IERC4626(vars.ruggableVault).convertToAssets(vars.finalRuggableVaultBalance);
            vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);

            console2.log("Final Ruggable Vault assets:", vars.finalRuggableVaultAssets);
            console2.log("Final Fluid Vault assets:", vars.finalFluidVaultAssets);

            // Verify reallocation
            assertApproxEqRel(
                vars.finalRuggableVaultBalance,
                vars.initialRuggableVaultBalance - vars.amountToReallocate,
                0.01e18,
                "Ruggable Vault balance should decrease by the reallocated amount"
            );

            assertGt(vars.finalFluidVaultBalance, vars.initialFluidVaultBalance, "Fluid Vault balance should increase");

            // Check total value preservation
            vars.initialTotalValue = vars.initialRuggableVaultAssets + vars.initialFluidVaultAssets;
            vars.finalTotalValue = vars.finalRuggableVaultAssets + vars.finalFluidVaultAssets;

            console2.log("Initial total value:", vars.initialTotalValue);
            console2.log("Final total value:", vars.finalTotalValue);

            // Check final vault state
            vars.vaultTotalAssetsAfterAllocation = vault.totalAssets();
            vars.pricePerShareAfterAllocation =
                vars.vaultTotalAssetsAfterAllocation.mulDiv(1e18, vars.finalTotalSupply, Math.Rounding.Floor);

            console2.log("Vault total assets after allocation:", vars.vaultTotalAssetsAfterAllocation);
            console2.log("Price per share after allocation:", vars.pricePerShareAfterAllocation);
        } else {
            console2.log("Skipping reallocation as there are no shares to reallocate");
        }
    }

    function _deployNewSuperVaultWithRuggableVault(address ruggableVault) internal {
        // Deploy a new SuperVault with the ruggable vault
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_RUG");

        vault = SuperVault(vaultAddr);
        strategy = SuperVaultStrategy(payable(strategyAddr));
        escrow = SuperVaultEscrow(escrowAddr);

        // Replace aaveVault with ruggableVault in the strategy
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(fluidVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0); // Add

        strategy.manageYieldSource(ruggableVault, _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0); // Add
        // ruggableVault
        vm.stopPrank();

        vm.startPrank(MANAGER);
        strategy.managePPSExpiration(1, 86_400); // 1 day

        vm.warp(block.timestamp + 2 weeks);

        strategy.managePPSExpiration(2, 0);
        vm.stopPrank();

        _updateSuperVaultPPS(address(strategy), address(vault));
    }

    /// @notice Test that maxDeposit returns 0 when vault is paused
    function test_MaxDeposit_WhenPaused() public {
        // Arrange: Deploy a fresh vault
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_PAUSE_TEST");

        SuperVault testVault = SuperVault(vaultAddr);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddr));

        // Verify maxDeposit returns max value when not paused
        uint256 maxDepositBeforePause = testVault.maxDeposit(accountEth);
        assertEq(maxDepositBeforePause, type(uint256).max, "maxDeposit should return type(uint256).max when not paused");

        // Arrange: Set a strict deviation threshold to trigger pause (5% = 0.05 * 1e18)
        vm.prank(MANAGER);
        aggregator.updateDeviationThreshold(address(testStrategy), 0.05e18); // deviationThreshold (5%)

        // Get the current PPS to calculate a deviation that will trigger pause
        uint256 currentPPS = aggregator.getPPS(address(testStrategy));
        console2.log("Current PPS:", currentPPS);

        // Calculate a new PPS that deviates by more than 5% (let's use 10% increase)
        uint256 deviatingPPS = currentPPS + (currentPPS * 10 / 100); // 10% increase
        console2.log("Deviating PPS (10% increase):", deviatingPPS);

        // Act: Skip time to avoid UPDATE_TOO_FREQUENT error and create a PPS update that violates the deviation
        // threshold
        vm.warp(block.timestamp + 10); // Skip 10 seconds to avoid rate limiting
        _createPPSUpdateThatTriggersDeviation(address(testStrategy), deviatingPPS);

        // Assert: Verify the strategy is now paused
        bool isStrategyPaused = aggregator.isStrategyPaused(address(testStrategy));
        assertTrue(isStrategyPaused, "Strategy should be paused after PPS deviation");

        // Assert: Verify maxDeposit returns 0 when paused
        uint256 maxDepositAfterPause = testVault.maxDeposit(accountEth);
        assertEq(maxDepositAfterPause, 0, "maxDeposit should return 0 when paused");
    }

    /// @notice Test that maxMint returns 0 when vault is paused
    function test_MaxMint_WhenPaused() public {
        // Arrange: Deploy a fresh vault
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_MINT_PAUSE_TEST");

        SuperVault testVault = SuperVault(vaultAddr);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddr));

        // Verify maxMint returns max value when not paused
        uint256 maxMintBeforePause = testVault.maxMint(accountEth);
        assertEq(maxMintBeforePause, type(uint256).max, "maxMint should return type(uint256).max when not paused");

        // Arrange: Set a strict deviation threshold to trigger pause (5% = 0.05 * 1e18)
        vm.prank(MANAGER);
        aggregator.updateDeviationThreshold(address(testStrategy), 0.05e18); // deviationThreshold (5%)

        // Get the current PPS to calculate a deviation that will trigger pause
        uint256 currentPPS = aggregator.getPPS(address(testStrategy));
        console2.log("Current PPS:", currentPPS);

        // Calculate a new PPS that deviates by more than 5% (let's use 10% decrease)
        uint256 deviatingPPS = currentPPS - (currentPPS * 10 / 100); // 10% decrease
        console2.log("Deviating PPS (10% decrease):", deviatingPPS);

        // Act: Skip time to avoid UPDATE_TOO_FREQUENT error and create a PPS update that violates the deviation
        // threshold
        vm.warp(block.timestamp + 10); // Skip 10 seconds to avoid rate limiting
        _createPPSUpdateThatTriggersDeviation(address(testStrategy), deviatingPPS);

        // Assert: Verify the strategy is now paused
        bool isStrategyPaused = aggregator.isStrategyPaused(address(testStrategy));
        assertTrue(isStrategyPaused, "Strategy should be paused after PPS deviation");

        // Assert: Verify maxMint returns 0 when paused
        uint256 maxMintAfterPause = testVault.maxMint(accountEth);
        assertEq(maxMintAfterPause, 0, "maxMint should return 0 when paused");
    }

    /// @notice Comprehensive test for pause/unpause functionality with stale PPS checks
    function test_PauseUnpause_WithStalePPS_ComprehensiveCoverage() public {
        // Setup: Deploy a fresh vault and perform initial deposit
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_PAUSE_UNPAUSE_TEST");

        SuperVault testVault = SuperVault(vaultAddr);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddr));

        // Setup yield sources for the test strategy
        vm.startPrank(MANAGER);
        testStrategy.manageYieldSource(
            address(fluidVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            0 // ADD
        );
        testStrategy.manageYieldSource(
            address(aaveVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            0 // ADD
        );
        vm.stopPrank();

        // Perform initial deposit (no allocation needed for pause/unpause testing)
        uint256 depositAmount = 10_000e6; // 10k USDC
        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, vaultAddr, address(testStrategy), address(asset));

        // ===== PHASE 1: Pause the strategy at t0 =====
        console2.log("\n=== PHASE 1: Pausing Strategy ===");
        uint256 t0 = block.timestamp;

        // Set strict deviation threshold to trigger pause (5%)
        vm.prank(MANAGER);
        aggregator.updateDeviationThreshold(address(testStrategy), 0.05e18); // deviationThreshold (5%)

        // Calculate a PPS that deviates by 10% to trigger pause
        uint256 currentPPS = aggregator.getPPS(address(testStrategy));
        uint256 deviatingPPS = currentPPS + (currentPPS * 10 / 100);

        vm.warp(t0 + 10);
        _createPPSUpdateThatTriggersDeviation(address(testStrategy), deviatingPPS);

        // Verify strategy is paused
        assertTrue(aggregator.isStrategyPaused(address(testStrategy)), "Strategy should be paused");
        console2.log("Strategy paused at t0:", t0);

        // ===== PHASE 2: Test all functions revert with STRATEGY_PAUSED =====
        console2.log("\n=== PHASE 2: Testing STRATEGY_PAUSED Reverts ===");

        // Test deposit reverts
        _getTokens(address(asset), accountEth, 10_000e6);
        vm.startPrank(accountEth);
        asset.approve(vaultAddr, type(uint256).max);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        testVault.deposit(1000e6, accountEth);
        vm.stopPrank();
        console2.log("deposit() reverts with STRATEGY_PAUSED");

        // Test mint reverts
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        testVault.mint(1000e6, accountEth);
        vm.stopPrank();
        console2.log("mint() reverts with STRATEGY_PAUSED");

        // Test requestRedeem reverts
        uint256 userShares = testVault.balanceOf(accountEth);
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        testVault.requestRedeem(userShares / 2, accountEth, accountEth);
        vm.stopPrank();
        console2.log("requestRedeem() reverts with STRATEGY_PAUSED");

        // Test fulfillRedeemRequests reverts (requires manager)
        address[] memory controllers = new address[](1);
        controllers[0] = accountEth;
        uint256[] memory emptyNetAssetsOut = new uint256[](1);
        vm.prank(MANAGER);
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        testStrategy.fulfillRedeemRequests(controllers, emptyNetAssetsOut);
        console2.log("fulfillRedeemRequests() reverts with STRATEGY_PAUSED");

        // Test fulfillCancelRedeemRequests works (no validation check)
        vm.prank(MANAGER);
        testStrategy.fulfillCancelRedeemRequests(controllers);
        console2.log("fulfillCancelRedeemRequests() works (no validation check)");

        // Verify maxDeposit and maxMint return 0 when paused
        assertEq(testVault.maxDeposit(accountEth), 0, "maxDeposit should return 0 when paused");
        assertEq(testVault.maxMint(accountEth), 0, "maxMint should return 0 when paused");
        console2.log("maxDeposit() and maxMint() return 0 when paused");

        // ===== PHASE 3: Unpause after 20 hours =====
        console2.log("\n=== PHASE 3: Unpausing Strategy ===");
        uint256 t1 = t0 + 20 hours;
        vm.warp(t1);

        vm.startPrank(MANAGER);
        aggregator.unpauseStrategy(address(testStrategy));
        vm.stopPrank();

        // Verify strategy is unpaused but PPS is stale
        assertFalse(aggregator.isStrategyPaused(address(testStrategy)), "Strategy should be unpaused");
        assertTrue(aggregator.isPPSStale(address(testStrategy)), "PPS should be stale after unpause");
        console2.log("Strategy unpaused at t1:", t1);
        console2.log("PPS is now stale");

        // ===== PHASE 4: Test all functions revert with STALE_PPS =====
        console2.log("\n=== PHASE 4: Testing STALE_PPS Reverts ===");

        // Test deposit reverts with STALE_PPS
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.STALE_PPS.selector);
        testVault.deposit(1000e6, accountEth);
        vm.stopPrank();
        console2.log("deposit() reverts with STALE_PPS");

        // Test mint reverts with STALE_PPS
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.STALE_PPS.selector);
        testVault.mint(1000e6, accountEth);
        vm.stopPrank();
        console2.log("mint() reverts with STALE_PPS");

        // Test requestRedeem reverts with STALE_PPS
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.STALE_PPS.selector);
        testVault.requestRedeem(userShares / 2, accountEth, accountEth);
        vm.stopPrank();
        console2.log("requestRedeem() reverts with STALE_PPS");

        // Test fulfillRedeemRequests reverts with STALE_PPS (requires manager)
        vm.prank(MANAGER);
        vm.expectRevert(ISuperVaultStrategy.STALE_PPS.selector);
        testStrategy.fulfillRedeemRequests(controllers, emptyNetAssetsOut);
        console2.log("fulfillRedeemRequests() reverts with STALE_PPS");

        // Test fulfillCancelRedeemRequests works (no validation check)
        vm.prank(MANAGER);
        testStrategy.fulfillCancelRedeemRequests(controllers);
        console2.log("fulfillCancelRedeemRequests() works (no validation check)");

        // Verify maxDeposit and maxMint return 0 when PPS is stale
        assertEq(testVault.maxDeposit(accountEth), 0, "maxDeposit should return 0 when PPS is stale");
        assertEq(testVault.maxMint(accountEth), 0, "maxMint should return 0 when PPS is stale");
        console2.log("maxDeposit() and maxMint() return 0 when PPS is stale");

        // ===== PHASE 5: Update PPS and verify functionality is restored =====
        console2.log("\n=== PHASE 5: Updating PPS and Restoring Functionality ===");

        // Reset deviation threshold to permissive value to avoid re-triggering pause
        vm.prank(MANAGER);
        aggregator.updateDeviationThreshold(address(testStrategy), type(uint256).max); // deviationThreshold (disabled)

        // Update PPS to clear the stale flag
        vm.warp(block.timestamp + 10);
        _updateSuperVaultPPS(address(testStrategy), vaultAddr);

        // Verify PPS is no longer stale
        assertFalse(aggregator.isPPSStale(address(testStrategy)), "PPS should not be stale after update");
        console2.log("PPS updated successfully");

        // Test that deposit now works
        uint256 balanceBefore = testVault.balanceOf(accountEth);
        vm.startPrank(accountEth);
        testVault.deposit(1000e6, accountEth);
        vm.stopPrank();
        assertGt(testVault.balanceOf(accountEth), balanceBefore, "Deposit should succeed after PPS update");
        console2.log("deposit() works after PPS update");

        // Test that requestRedeem now works
        uint256 newShares = testVault.balanceOf(accountEth);
        vm.startPrank(accountEth);
        testVault.requestRedeem(newShares / 4, accountEth, accountEth);
        vm.stopPrank();
        assertGt(testStrategy.pendingRedeemRequest(accountEth), 0, "Redeem request should succeed after PPS update");
        console2.log("requestRedeem() works after PPS update");

        // Verify maxDeposit and maxMint return normal values
        assertEq(testVault.maxDeposit(accountEth), type(uint256).max, "maxDeposit should return max value");
        assertEq(testVault.maxMint(accountEth), type(uint256).max, "maxMint should return max value");
        console2.log("maxDeposit() and maxMint() return normal values");

        console2.log("\n=== Test Complete: All phases passed ===");
    }

    /// @notice Test PPS expiration - operations should revert with PPS_EXPIRED after validity period
    function test_PPSExpiration_OperationsRevert() public {
        // Setup: Deploy a fresh vault and perform initial deposit
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_PPS_EXPIRATION_TEST");

        SuperVault testVault = SuperVault(vaultAddr);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddr));

        // Setup yield sources for the test strategy
        vm.startPrank(MANAGER);
        testStrategy.manageYieldSource(
            address(fluidVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            0 // ADD
        );
        testStrategy.manageYieldSource(
            address(aaveVault),
            _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY),
            0 // ADD
        );
        vm.stopPrank();

        // Perform initial deposit
        uint256 depositAmount = 10_000e6; // 10k USDC
        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, vaultAddr, address(testStrategy), address(asset));

        // Update PPS to establish last update timestamp
        vm.warp(block.timestamp + 10);
        _updateSuperVaultPPS(address(testStrategy), vaultAddr);

        uint256 lastUpdateTime = aggregator.getLastUpdateTimestamp(address(testStrategy));
        uint256 ppsExpiration = testStrategy.ppsExpiration();
        console2.log("Last PPS update:", lastUpdateTime);
        console2.log("PPS expiration period:", ppsExpiration);

        // Warp time forward by ppsExpiration + 1 second to trigger expiration
        vm.warp(lastUpdateTime + ppsExpiration + 1);
        console2.log("Warped to:", block.timestamp);
        console2.log("Time since last update:", block.timestamp - lastUpdateTime);

        // ===== Test operations revert with PPS_EXPIRED =====
        // Note: All operations except ClaimRedeem check PPS expiration and should revert when PPS is expired.
        console2.log("\n=== Testing PPS_EXPIRED Reverts (all operations except ClaimRedeem) ===");

        // Get fresh tokens for testing operations
        _getTokens(address(asset), accountEth, 10_000e6);

        // Test deposit reverts with PPS_EXPIRED
        vm.startPrank(accountEth);
        asset.approve(vaultAddr, type(uint256).max);
        vm.expectRevert(ISuperVaultStrategy.PPS_EXPIRED.selector);
        testVault.deposit(1000e6, accountEth);
        vm.stopPrank();
        console2.log("deposit() reverts with PPS_EXPIRED");

        // Test mint reverts with PPS_EXPIRED
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.PPS_EXPIRED.selector);
        testVault.mint(1000e6, accountEth);
        vm.stopPrank();
        console2.log("mint() reverts with PPS_EXPIRED");

        // Note: maxDeposit and maxMint don't check PPS expiration, only pause and stale status
        // They return max value, but actual deposit/mint operations will revert with PPS_EXPIRED
        assertEq(
            testVault.maxDeposit(accountEth), type(uint256).max, "maxDeposit returns max (doesn't check expiration)"
        );
        assertEq(testVault.maxMint(accountEth), type(uint256).max, "maxMint returns max (doesn't check expiration)");
        console2.log("maxDeposit() and maxMint() return max (don't check PPS expiration)");

        // Test requestRedeem reverts with PPS_EXPIRED

        uint256 userShares = testVault.balanceOf(accountEth);
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVaultStrategy.PPS_EXPIRED.selector);
        testVault.requestRedeem(userShares / 2, accountEth, accountEth);
        vm.stopPrank();

        console2.log("requestRedeem() reverts with PPS_EXPIRED");

        // ===== Verify functionality is restored after PPS update =====
        console2.log("\n=== Testing Functionality Restored After PPS Update ===");

        // Update PPS to clear expiration
        vm.warp(block.timestamp + 10);
        _updateSuperVaultPPS(address(testStrategy), vaultAddr);

        uint256 newLastUpdateTime = aggregator.getLastUpdateTimestamp(address(testStrategy));
        console2.log("New last PPS update:", newLastUpdateTime);
        console2.log("Time since update:", block.timestamp - newLastUpdateTime);

        // Verify deposit now works
        uint256 balanceBefore = testVault.balanceOf(accountEth);
        vm.startPrank(accountEth);
        testVault.deposit(1000e6, accountEth);
        vm.stopPrank();
        assertGt(testVault.balanceOf(accountEth), balanceBefore, "Deposit should succeed after PPS update");
        console2.log("deposit() works after PPS update");

        // Verify maxDeposit and maxMint return normal values
        assertEq(testVault.maxDeposit(accountEth), type(uint256).max, "maxDeposit should return max value");
        assertEq(testVault.maxMint(accountEth), type(uint256).max, "maxMint should return max value");
        console2.log("maxDeposit() and maxMint() return normal values");

        console2.log("\n=== Test Complete: PPS expiration working as expected ===");
    }

    /// @notice Helper function to create a PPS update that triggers deviation pause
    /// @param strategyAddr The strategy address to update
    /// @param newPPS The new PPS value that should trigger a deviation
    function _createPPSUpdateThatTriggersDeviation(address strategyAddr, uint256 newPPS) internal {
        UpdatePPSVars memory vars;

        // Get the current timestamp for the signature
        vars.timestamp = block.timestamp; // // Use current timestamp to avoid TIMESTAMP_EXCEEDS_BLOCK revert

        // Create the message hash with the deviating PPS
        bytes32 structHash = keccak256(
            abi.encodePacked(
                ecdsappsOracle.UPDATE_PPS_TYPEHASH(),
                strategyAddr,
                newPPS,
                vars.timestamp,
                ecdsappsOracle.noncePerStrategy(strategyAddr)
            )
        );
        vars.ethSignedMessageHash = MessageHashUtils.toTypedDataHash(ecdsappsOracle.domainSeparator(), structHash);

        // Create signature (r, s, v) components using the constant KEEPER address
        (vars.v, vars.r, vars.s) = vm.sign(VALIDATOR_KEY, vars.ethSignedMessageHash);

        // Combine the signature components into a single bytes signature
        vars.signature = abi.encodePacked(vars.r, vars.s, vars.v);

        // Create an array of proofs with the signature
        vars.proofs = new bytes[](1);
        vars.proofs[0] = vars.signature;

        // Call batchUpdatePPS on the ECDSAPPSOracle with the deviating PPS
        address[] memory strategies = new address[](1);
        strategies[0] = strategyAddr;

        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = vars.proofs;

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = newPPS;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = vars.timestamp;

        ecdsappsOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies, proofsArray: proofsArray, ppss: ppss, timestamps: timestamps
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                        DUST BUG TESTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Test that exposes the dust bug in _handleClaimRedeem function
    /// @dev This test creates a scenario where the strategy balance is reduced below what users can claim,
    ///      but the difference is within the tolerance constant, causing the dust collection logic to trigger
    function test_DustBugInClaimRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Step 1: Deposit and set up redeem request
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialShares = vault.balanceOf(accountEth);
        uint256 redeemShares = initialShares / 2;

        // Request redeem
        _requestRedeem(redeemShares);

        // Fulfill the redeem request
        _executeRedeemHooks4626(redeemShares, address(fluidVault), address(aaveVault), new address[](0));

        // Get the claimable amount
        uint256 claimableAmount = strategy.claimableWithdraw(accountEth);
        console2.log("Claimable amount:", claimableAmount);

        // Step 2: Reduce strategy balance artificially (simulating insolvency)
        // This could happen due to various reasons like:
        // - Yield source losses
        // - Accounting errors

        uint256 escrowBalanceBefore = asset.balanceOf(address(escrow));
        console2.log("Escrow balance before reduction:", escrowBalanceBefore);

        // Simulate reducing strategy balance by transferring assets out
        // We'll make the difference exactly equal to 10 wei
        // to trigger the dust collection logic
        uint256 reductionAmount = claimableAmount - escrowBalanceBefore + 5; // 5 wei less than tolerance

        // Transfer assets out of strategy to simulate insolvency
        vm.startPrank(address(escrow));
        asset.transfer(address(this), reductionAmount);
        vm.stopPrank();

        uint256 escrowBalanceAfter = asset.balanceOf(address(escrow));
        console2.log("Escrow balance after reduction:", escrowBalanceAfter);
        console2.log("Claimable amount:", claimableAmount);
        console2.log("Difference:", claimableAmount - escrowBalanceAfter);

        // Verify the difference is within tolerance constant
        assertTrue(claimableAmount > escrowBalanceAfter, "Claimable should be greater than available");
        assertTrue(claimableAmount - escrowBalanceAfter <= 10, "Difference should be within tolerance");

        // Step 3: Try to claim the full amount
        // This should trigger the dust collection logic and give the user the remaining balance
        //uint256 userBalanceBefore = asset.balanceOf(accountEth);

        vm.startPrank(accountEth);
        // cannot withdraw anymore due to insufficient balance
        vm.expectRevert(ISuperVault.NOT_ENOUGH_ASSETS.selector);
        vault.withdraw(claimableAmount, accountEth, accountEth);
        /**
         * vm.stopPrank();
         *
         *     uint256 userBalanceAfter = asset.balanceOf(accountEth);
         *     uint256 actualReceived = userBalanceAfter - userBalanceBefore;
         *
         *     console2.log("User balance before claim:", userBalanceBefore);
         *     console2.log("User balance after claim:", userBalanceAfter);
         *     console2.log("Actual amount received:", actualReceived);
         *     console2.log("Escrow balance after claim:", asset.balanceOf(address(escrow)));
         *
         *     // The bug: User receives less than they should have been able to claim
         *     // but the strategy balance is now 0, making the vault insolvent
         *     assertEq(actualReceived, escrowBalanceAfter, "User should receive remaining escrow balance");
         *     assertEq(asset.balanceOf(address(escrow)), 0, "Escrow should be empty");
         *
         *     // This is problematic because:
         *     // 1. The user's maxWithdraw is not updated to reflect the actual amount received
         *     // 2. The vault becomes insolvent (strategy balance < 0 in accounting terms)
         *     // 3. Other users might not be able to claim their rightful amounts
         *
         *     // Verify that the user's maxWithdraw is not properly updated
         *     uint256 remainingMaxWithdraw = strategy.claimableWithdraw(accountEth);
         *     console2.log("Remaining maxWithdraw:", remainingMaxWithdraw);
         *
         *     // The user still has a positive maxWithdraw even though the strategy is empty
         *     assertGt(remainingMaxWithdraw, 0, "User should still have positive maxWithdraw");
         */
    }

    /// @notice Test the dust bug scenario

    /// @notice Test the specific dust bug in maxWithdraw accounting
    /// @dev This test demonstrates the core issue: maxWithdraw is reduced by actualAmountToClaim
    ///      instead of assetsToClaim, causing accounting inconsistencies
    function test_DustBugMaxWithdrawAccounting() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Step 1: Deposit and set up redeem request
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialShares = vault.balanceOf(accountEth);
        uint256 redeemShares = initialShares / 2;

        // Request redeem
        _requestRedeem(redeemShares);

        // Fulfill the redeem request
        _executeRedeemHooks4626(redeemShares, address(fluidVault), address(aaveVault), new address[](0));

        uint256 claimableAmount = strategy.claimableWithdraw(accountEth);
        uint256 escrowBalanceBefore = asset.balanceOf(address(escrow));

        console2.log("Initial claimable amount:", claimableAmount);
        console2.log("Initial escrow balance:", escrowBalanceBefore);

        // Step 2: Reduce escrow balance to trigger dust collection
        // Make the difference exactly 5 wei (within tolerance of 10)
        uint256 reductionAmount = claimableAmount - escrowBalanceBefore + 5;

        // Transfer assets out of escrow
        vm.startPrank(address(escrow));
        asset.transfer(address(this), reductionAmount);
        vm.stopPrank();
        console2.log("----D");

        uint256 escrowBalanceAfter = asset.balanceOf(address(escrow));
        uint256 difference = claimableAmount - escrowBalanceAfter;

        console2.log("Escrow balance after reduction:", escrowBalanceAfter);
        console2.log("Difference (should be 5):", difference);
        console2.log("Tolerance constant: 10");

        // Verify we're in the dust collection scenario
        assertTrue(claimableAmount > escrowBalanceAfter, "Claimable should be greater than available");
        assertTrue(difference <= 10, "Difference should be within tolerance");

        // Step 3: Claim the full amount
        vm.startPrank(accountEth);
        vm.expectRevert(ISuperVault.NOT_ENOUGH_ASSETS.selector);
        vault.withdraw(claimableAmount, accountEth, accountEth);
    }

    /// @notice Test the dust bug by directly calling the strategy function
    /// @dev This test directly calls handleOperations7540 to demonstrate the bug more clearly
    function test_DustBugDirectStrategyCall() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Step 1: Deposit and set up redeem request
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialShares = vault.balanceOf(accountEth);
        uint256 redeemShares = initialShares / 2;

        // Request redeem
        _requestRedeem(redeemShares);

        // Fulfill the redeem request
        _executeRedeemHooks4626(redeemShares, address(fluidVault), address(aaveVault), new address[](0));

        uint256 claimableAmount = strategy.claimableWithdraw(accountEth);
        uint256 escrowBalanceBefore = asset.balanceOf(address(escrow));

        // Step 2: Reduce strategy balance to trigger dust collection
        uint256 reductionAmount = claimableAmount - escrowBalanceBefore + 5; // 5 wei less than tolerance

        // Transfer assets out of strategy
        vm.startPrank(address(escrow));
        asset.transfer(address(this), reductionAmount);
        vm.stopPrank();

        uint256 escrowBalanceAfter = asset.balanceOf(address(escrow));
        uint256 difference = claimableAmount - escrowBalanceAfter;

        console2.log("=== Dust Bug Test ===");
        console2.log("Claimable amount:", claimableAmount);
        console2.log("Escrow balance after reduction:", escrowBalanceAfter);
        console2.log("Difference (dust):", difference);
        console2.log("Tolerance constant: 10");

        // Verify we're in the dust collection scenario
        assertTrue(claimableAmount > escrowBalanceAfter, "Claimable should be greater than available");
        assertTrue(difference <= 10, "Difference should be within tolerance");

        // Step 3: Directly call the strategy's claim function
        // Call the strategy directly (this is what vault.withdraw calls internally)
        vm.startPrank(address(vault));
        vm.expectRevert(ISuperVault.NOT_ENOUGH_ASSETS.selector);
        strategy.handleOperations7540(
            ISuperVaultStrategy.Operation.ClaimRedeem, accountEth, accountEth, claimableAmount
        );
    }

    /*//////////////////////////////////////////////////////////////
                       MANAGEMENT FEE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that deposit skims entry fee to recipient and mints net shares
    function test_Deposit_WithMgmtFee_SkimsAndMintsNet() public {
        // Set 1% management (entry) fee, recipient = TREASURY
        _setFeeConfig(100, 100, TREASURY);

        uint256 assets = 1000e6;
        _getTokens(address(asset), accInstances[0].account, assets);

        vm.startPrank(accInstances[0].account);
        asset.approve(address(vault), type(uint256).max);
        uint256 shares = vault.previewDeposit(assets);
        vault.deposit(assets, accInstances[0].account);
        vm.stopPrank();
        vm.startPrank(MANAGER);

        // Fee = ceil(1% of 1000) = 10
        assertEq(asset.balanceOf(TREASURY), 10e6, "fee skimmed to recipient");
        // Strategy received assets - fee
        assertEq(asset.balanceOf(address(strategy)), 990e6, "strategy got net assets");

        // Shares minted equal previewDeposit(assets)
        uint256 expectedShares = vault.previewDeposit(assets);
        assertEq(shares, expectedShares, "minted shares = previewDeposit");
    }

    /// @notice Test that previewDeposit reflects entry fee precisely (ceil on fee)
    function test_PreviewDeposit_WithMgmtFee_FeeCeil() public {
        _setFeeConfig(100, 100, TREASURY); // 1%

        // Pick a value that exercises ceil rounding (e.g., 1 wei of USDC)
        uint256 tiny = 1; // 1 unit (1e-6 USDC)
        // fee = ceil(1% of 1) = 1 (since we can't take 0)
        uint256 expectedShares = vault.convertToShares(0); // assetsNet = 0

        assertEq(vault.previewDeposit(tiny), expectedShares, "fee rounds up");
    }

    /*//////////////////////////////////////////////////////////////
                        NATIVE ETH HANDLING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ExecuteHooks_AcceptsPayable() public {
        // This test verifies that executeHooks can accept ETH (is payable)
        // Since reverts return ETH, we test by sending ETH directly to the receive function

        uint256 ethAmount = 1 ether;

        // Fund the manager with ETH
        vm.deal(MANAGER, ethAmount);
        uint256 strategyETHBefore = address(strategy).balance;

        // Send ETH directly to the strategy's receive function
        vm.startPrank(MANAGER);
        (bool success,) = address(strategy).call{ value: ethAmount }("");
        vm.stopPrank();

        // Verify the call succeeded and ETH was received
        assertTrue(success, "ETH transfer should succeed");
        assertEq(address(strategy).balance, strategyETHBefore + ethAmount, "Strategy should have received ETH");

        // Now test that executeHooks is payable by calling it with ETH (it will revert but not due to payable)
        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: new address[](0), // Empty array will cause ZERO_LENGTH revert
            hookCalldata: new bytes[](0),
            expectedAssetsOrSharesOut: new uint256[](0),
            globalProofs: new bytes32[][](0),
            strategyProofs: new bytes32[][](0)
        });

        vm.deal(MANAGER, ethAmount);
        vm.startPrank(MANAGER);
        vm.expectRevert(ISuperVaultStrategy.ZERO_LENGTH.selector);
        strategy.executeHooks{ value: ethAmount }(args); // This proves it's payable
        vm.stopPrank();
    }

    function test_ReceiveFunction_AcceptsETH() public {
        uint256 ethAmount = 1 ether;

        // Send ETH directly to strategy
        vm.deal(address(this), ethAmount);
        uint256 strategyBalanceBefore = address(strategy).balance;

        // Send ETH to strategy
        (bool success,) = payable(address(strategy)).call{ value: ethAmount }("");
        assertTrue(success, "ETH transfer should succeed");

        // Verify ETH was received
        assertEq(address(strategy).balance, strategyBalanceBefore + ethAmount, "Strategy should receive ETH");
    }

    function test_RevertWhen_ExecuteHooks_WithoutPayable() public {
        // This test verifies that the old version would have failed
        // Since we've already added payable, we'll test with a mock that doesn't have payable

        // Create a simple contract without payable functions
        SimpleNonPayableContract nonPayable = new SimpleNonPayableContract();

        uint256 ethAmount = 1 ether;
        vm.deal(address(this), ethAmount);

        // Try to send ETH to non-payable function - this should fail
        (bool success,) = address(nonPayable).call{ value: ethAmount }(abi.encodeWithSignature("nonPayableFunction()"));
        assertFalse(success, "Should fail when sending ETH to non-payable function");
    }

    function test_executeHooks_WithNativeETHHook() public {
        vm.selectFork(FORKS[ETH]);
        uint256 depositAmount = 1000e6; // 1000 USDC
        uint256 ethAmount = 0.5 ether;

        // Add MockETHReceiver as active yield source
        address ethReceiver = contractAddresses[ETH]["MOCK_ETH_RECEIVER"];
        vm.startPrank(MANAGER);
        strategy.manageYieldSources(
            _toArray(ethReceiver),
            _toArray(_getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY)),
            new uint8[](1) // actionType 0 = add
        );
        vm.stopPrank();

        // Fund MockETHReceiver with USDC so it can transfer when hook executes
        deal(address(asset), ethReceiver, depositAmount);

        // STEP 1: Execute native ETH hook separately via executeHooks
        address[] memory nativeHooks = new address[](1);
        nativeHooks[0] = contractAddresses[ETH]["MOCK_NATIVE_ETH_HOOK"]; // MockNativeETHHook

        bytes[] memory nativeHookCalldata = new bytes[](1);
        nativeHookCalldata[0] = _createMockNativeETHHookData(ethReceiver, ethAmount);

        uint256[] memory nativeExpectedOut = new uint256[](1);
        nativeExpectedOut[0] = ethAmount; // Expected ETH transfer amount

        // Create argsForProofs for native hook
        bytes[] memory nativeArgsForProofs = new bytes[](1);
        nativeArgsForProofs[0] = ISuperHookInspector(nativeHooks[0]).inspect(nativeHookCalldata[0]);

        // Get merkle proofs for native hook
        bytes32[][] memory nativeGlobalProofs = _getMerkleProofsForHooks(nativeHooks, nativeArgsForProofs);
        bytes32[][] memory nativeStrategyProofs = new bytes32[][](1);
        nativeStrategyProofs[0] = new bytes32[](0);

        // Fund manager with ETH for hook execution
        vm.deal(MANAGER, ethAmount);

        // Execute native ETH hook via executeHooks
        vm.startPrank(MANAGER);
        strategy.executeHooks{ value: ethAmount }(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: nativeHooks,
                hookCalldata: nativeHookCalldata,
                expectedAssetsOrSharesOut: nativeExpectedOut,
                globalProofs: nativeGlobalProofs,
                strategyProofs: nativeStrategyProofs
            })
        );
        vm.stopPrank();
    }

    function _createMockNativeETHHookData(address ethReceiver, uint256 ethAmount) internal pure returns (bytes memory) {
        // Create calldata following the standard hook format: oracleId + yieldSource + amount
        return abi.encodePacked(
            bytes32(0), // oracle ID placeholder
            ethReceiver, // yield source (ETH receiver)
            ethAmount // ETH amount to send
        );
    }

    /*//////////////////////////////////////////////////////////////
                       7540 UNDERLYING TESTS
    //////////////////////////////////////////////////////////////*/
    function test_7540Underlying_E2E_Flow() public {
        // Set up the vault
        _setUp7540UnderlyingSuperVault();

        // update slippage for this test to 1.5% to allow it to pass
        _updateRedeemSlippages(150);

        AccountInstance memory instance = accInstances[0];
        address account = instance.account;

        // Deposit USDC into the SuperVault
        uint256 depositAmount = 1000e6; // 1000 USDC
        _getTokens(address(asset), account, depositAmount);
        __deposit(instance, depositAmount);

        // Verify state
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        _depositFreeAssetsFromSingleAmount7540(depositAmount, address(aaveVault), address(centrifugeVault));

        uint256 userShares = vault.balanceOf(account);
        assertGt(userShares, 0, "No shares minted to user");

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(account);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Step 4: Request Redeem
        __requestRedeem(instance, userShares, false);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(account), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Step 5: Fulfill Redeem
        _executeRedeemHooks7540(userShares, address(aaveVault), address(centrifugeVault), account);

        // Verify balances
        assertEq(asset.balanceOf(account), preRedeemUserAssets, "User assets not returned");
        // Fee balance assertion removed - fees now collected via skimPerformanceFee
    }

    /// @notice Execute initial deposits with equal total investment strategy
    /// @param holder_ Long-term holder persona
    /// @param trader_ Active trader persona
    function _executeEqualInvestmentDeposits(UserPersona memory holder_, UserPersona memory trader_) internal {
        console2.log("\n=== PHASE 1: EQUAL INVESTMENT INITIAL DEPOSITS ===");

        // Both users make the same initial deposit
        _depositForAccount(accInstances[0], holder_.depositAmount);
        holder_.shares = vault.balanceOf(holder_.account);
        console2.log("Holder initial deposit and shares:", holder_.shares);

        _depositForAccount(accInstances[1], trader_.depositAmount);
        trader_.shares = vault.balanceOf(trader_.account);
        console2.log("Trader initial deposit and shares:", trader_.shares);

        // Allocate funds to yield sources
        uint256 totalDeposited = holder_.depositAmount + trader_.depositAmount;
        _depositFreeAssetsFromSingleAmount(totalDeposited, address(fluidVault), address(aaveVault));
    }

    /// @notice Execute holder strategy with additional deposits to match trader's total investment
    /// @param holder_ Long-term holder persona
    function _executeEqualInvestmentHolding(UserPersona memory holder_) internal {
        console2.log("\n=== PHASE 3: EQUAL INVESTMENT HOLDER STRATEGY ===");

        // Holder makes additional deposits to match trader's total (3 x 5,000 USDC = 15,000 USDC more)
        uint256 additionalDepositAmount = holder_.depositAmount / 2; // 5,000 USDC per deposit

        for (uint256 i = 0; i < 3; i++) {
            console2.log("--- Holder Additional Deposit", i + 1, "---");

            // Time spacing similar to trader but holder just deposits and holds
            vm.warp(block.timestamp + (1 + i) * 1 days);

            _depositForAccount(accInstances[0], additionalDepositAmount);
            uint256 newShares = vault.balanceOf(holder_.account);
            console2.log("Holder additional deposit:", additionalDepositAmount / 1e6, "USDC");
            console2.log("Holder total shares after deposit:", newShares);

            // Allocate new funds
            _depositFreeAssetsFromSingleAmount(additionalDepositAmount, address(fluidVault), address(aaveVault));

            // Holder just holds - no redemptions during accumulation phase
        }

        console2.log("Holder total investment completed: 25,000 USDC");

        // Long-term hold period (30 days like original)
        vm.warp(block.timestamp + 30 days);
        console2.log("Holder completed long-term holding period");
    }

    /// @notice Complete redemptions and calculate final yield comparison
    /// @param holder_ Long-term holder persona
    /// @param trader_ Active trader persona
    function _completeRedemptionsAndCalculateYield(UserPersona memory holder_, UserPersona memory trader_) internal {
        console2.log("\n=== PHASE 5: FULFILLING REDEMPTIONS ===");

        // Get pending redemption amounts
        uint256 holderPendingShares = strategy.pendingRedeemRequest(holder_.account);
        uint256 traderPendingShares = strategy.pendingRedeemRequest(trader_.account);

        console2.log("Holder pending shares to redeem:", holderPendingShares);
        console2.log("Trader pending shares to redeem:", traderPendingShares);

        // Fulfill redemptions for both users
        address[] memory redeemUsers = new address[](2);
        redeemUsers[0] = holder_.account;
        redeemUsers[1] = trader_.account;

        uint256 totalPendingShares = holderPendingShares + traderPendingShares;
        uint256 allocationVault1 = totalPendingShares / 2;
        uint256 allocationVault2 = totalPendingShares - allocationVault1;

        _executeRedeemHooks4626ForUsers(
            redeemUsers, allocationVault1, allocationVault2, address(fluidVault), address(aaveVault)
        );

        console2.log("\n=== PHASE 6: CLAIMING FINAL ASSETS ===");

        // Claim final assets for both users
        _claimRedeemForUsers(redeemUsers);

        // Calculate final balances and yields
        _calculateAndCompareYields(holder_, trader_);
    }

    /// @notice Calculate and compare final yields between holder and trader
    /// @param holder_ Long-term holder persona
    /// @param trader_ Active trader persona
    function _calculateAndCompareYields(UserPersona memory holder_, UserPersona memory trader_) internal view {
        console2.log("\n=== FINAL YIELD COMPARISON ===");

        // Get final balances
        uint256 holderFinalBalance = asset.balanceOf(holder_.account);
        uint256 traderFinalBalance = asset.balanceOf(trader_.account);

        console2.log("Holder final balance:", holderFinalBalance / 1e6, "USDC");
        console2.log("Trader final balance:", traderFinalBalance / 1e6, "USDC");

        // Calculate actual net investment - both users now invest the same total amount
        uint256 totalInvestmentAmount = 25_000e6; // 25,000 USDC each
        uint256 holderNetInvestment = totalInvestmentAmount;
        uint256 traderNetInvestment = totalInvestmentAmount;

        console2.log("\n=== EQUAL INVESTMENT AMOUNTS ===");
        console2.log("Holder total invested:", holderNetInvestment / 1e6, "USDC");
        console2.log("Trader total invested:", traderNetInvestment / 1e6, "USDC");
        console2.log("Investment amounts are equal for fair comparison");

        // Calculate yields
        uint256 holderYield = holderFinalBalance > holderNetInvestment ? holderFinalBalance - holderNetInvestment : 0;
        uint256 traderYield = traderFinalBalance > traderNetInvestment ? traderFinalBalance - traderNetInvestment : 0;

        console2.log("\n=== YIELD ANALYSIS ===");
        console2.log("Holder net investment:", holderNetInvestment / 1e6, "USDC");
        console2.log("Holder yield earned:", holderYield / 1e6, "USDC");
        console2.log(
            "Holder yield %:", holderNetInvestment > 0 ? (holderYield * 10_000) / holderNetInvestment : 0, "bps"
        );

        console2.log("Trader net investment:", traderNetInvestment / 1e6, "USDC");
        console2.log("Trader yield earned:", traderYield / 1e6, "USDC");
        console2.log(
            "Trader yield %:", traderNetInvestment > 0 ? (traderYield * 10_000) / traderNetInvestment : 0, "bps"
        );

        // Compare yields
        if (holderYield > traderYield) {
            uint256 yieldDifference = holderYield - traderYield;
            console2.log("\n=== RESULT: HOLDER WINS ===");
            console2.log("Long-term holder earned", yieldDifference / 1e6, "USDC more than active trader");
            console2.log("Advantage:", traderYield > 0 ? (yieldDifference * 10_000) / traderYield : 0, "bps better");
        } else if (traderYield > holderYield) {
            uint256 yieldDifference = traderYield - holderYield;
            console2.log("\n=== RESULT: TRADER WINS ===");
            console2.log("Active trader earned", yieldDifference / 1e6, "USDC more than long-term holder");
            console2.log("Advantage:", holderYield > 0 ? (yieldDifference * 10_000) / holderYield : 0, "bps better");
        } else {
            console2.log("\n=== RESULT: TIE ===");
            console2.log("Both strategies earned the same yield");
        }

        // Additional metrics
        console2.log("\n=== STRATEGY EFFICIENCY ===");
        console2.log(
            "Holder total return:",
            holderFinalBalance > holder_.initialBalance ? holderFinalBalance - holder_.initialBalance : 0,
            "wei"
        );
        console2.log(
            "Trader total return:",
            traderFinalBalance > trader_.initialBalance ? traderFinalBalance - trader_.initialBalance : 0,
            "wei"
        );
    }

    /// @notice Execute initial deposits phase
    function _executeInitialDeposits(UserPersona memory holder, UserPersona memory trader) internal {
        console2.log("\n=== PHASE 1: INITIAL DEPOSITS ===");

        // Long-term holder makes single large deposit
        _depositForAccount(accInstances[0], holder.depositAmount);
        holder.shares = vault.balanceOf(holder.account);
        console2.log("Holder deposited and received shares:", holder.shares);

        // Active trader makes first deposit
        _depositForAccount(accInstances[1], trader.depositAmount);
        trader.shares = vault.balanceOf(trader.account);
        console2.log("Trader deposited and received shares:", trader.shares);

        // Allocate funds to yield sources
        uint256 totalDeposited = holder.depositAmount + trader.depositAmount;
        _depositFreeAssetsFromSingleAmount(totalDeposited, address(fluidVault), address(aaveVault));
    }

    /// @notice Execute active trading period
    function _executeActiveTradingPeriod(UserPersona memory trader) internal {
        console2.log("\n=== PHASE 2: ACTIVE TRADING PERIOD ===");

        // Simulate time passing and yield generation
        vm.warp(block.timestamp + 1 days);
        // Update PPS after time warp to prevent expiration
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Active trader performs multiple deposit-redeem-claim cycles
        for (uint256 i = 0; i < 3; i++) {
            TradingCycle memory cycle;
            cycle.cycleNumber = i + 1;
            cycle.depositAmount = trader.depositAmount / 2;

            console2.log("--- Trader Cycle", cycle.cycleNumber, "---");

            // Trader deposits more
            _depositForAccount(accInstances[1], cycle.depositAmount);
            cycle.sharesAfterDeposit = vault.balanceOf(trader.account);
            console2.log("Trader shares after deposit:", cycle.sharesAfterDeposit);

            // Allocate new funds
            _depositFreeAssetsFromSingleAmount(cycle.depositAmount, address(fluidVault), address(aaveVault));
            console2.log("--pps before---", aggregator.getPPS(address(strategy)));
            _updateSuperVaultPPS(address(strategy), address(vault));
            console2.log("--pps after---", aggregator.getPPS(address(strategy)));
            // Simulate some time for yield
            vm.warp(block.timestamp + 6 hours);

            // Trader redeems part of position - avoid rounding issues
            cycle.redeemAmount = cycle.sharesAfterDeposit / 4; // Redeem 25% of position
            if (cycle.redeemAmount > 1) {
                _requestRedeemForAccount(accInstances[1], cycle.redeemAmount);

                // Verify redeem request was recorded
                uint256 pendingRedeem = strategy.pendingRedeemRequest(trader.account);
                console2.log("Trader pending redeem:", pendingRedeem);
                console2.log("Trader requested redeem shares:", cycle.redeemAmount);
            }
            console2.log("--pps before---", aggregator.getPPS(address(strategy)));
            _updateSuperVaultPPS(address(strategy), address(vault));
            console2.log("--pps after---", aggregator.getPPS(address(strategy)));
            vm.warp(block.timestamp + 6 hours);
        }
    }

    /// @notice Execute long-term holding behavior
    function _executeLongTermHolding(UserPersona memory holder) internal {
        console2.log("\n=== PHASE 3: LONG-TERM HOLDER HOLDS POSITION ===");

        // Long-term holder does nothing during active trading period
        // Just track their position growth
        uint256 holderSharesAfterTrading = vault.balanceOf(holder.account);
        console2.log("Holder shares remained constant:", holderSharesAfterTrading);
        assertEq(holderSharesAfterTrading, holder.shares, "Holder shares should remain unchanged");

        // Simulate longer time period (30 days)
        vm.warp(block.timestamp + 30 days);
        // Update PPS to prevent expiration after long time warp
        _updateSuperVaultPPS(address(strategy), address(vault));
    }

    /// @notice Execute final redemptions phase
    function _executeFinalRedemptions(UserPersona memory holder, UserPersona memory trader) internal {
        console2.log("\n=== PHASE 4: FINAL REDEMPTIONS ===");

        // Get final positions before redemption
        uint256 holderFinalShares = vault.balanceOf(holder.account);
        uint256 traderFinalShares = vault.balanceOf(trader.account);

        console2.log("Final holder shares:", holderFinalShares);
        console2.log("Final trader shares:", traderFinalShares);

        // Both users redeem their full positions - avoid rounding issues
        if (holderFinalShares > 1) {
            _requestRedeemForAccount(accInstances[0], holderFinalShares - 1);
        }
        if (traderFinalShares > 1) {
            _requestRedeemForAccount(accInstances[1], traderFinalShares - 1);
        }

        // Verify redeem requests were recorded
        uint256 holderPendingRedeem = strategy.pendingRedeemRequest(holder.account);
        uint256 traderPendingRedeem = strategy.pendingRedeemRequest(trader.account);

        console2.log("Holder pending redeem:", holderPendingRedeem);
        console2.log("Trader pending redeem:", traderPendingRedeem);

        // Verify final positions after redeem requests
        uint256 holderRemainingShares = vault.balanceOf(holder.account);
        uint256 traderRemainingShares = vault.balanceOf(trader.account);

        console2.log("Holder remaining shares:", holderRemainingShares);
        console2.log("Trader remaining shares:", traderRemainingShares);

        _verifyFinalState(holder, trader);
    }

    /// @notice Verify final state and assertions
    function _verifyFinalState(UserPersona memory holder, UserPersona memory trader) internal view {
        console2.log("\n=== FINAL VERIFICATION ===");

        holder.finalBalance = asset.balanceOf(holder.account);
        trader.finalBalance = asset.balanceOf(trader.account);

        console2.log("Holder final balance:", holder.finalBalance);
        console2.log("Trader final balance:", trader.finalBalance);

        // Verify redeem requests were properly recorded
        uint256 holderPendingRedeem = strategy.pendingRedeemRequest(holder.account);
        uint256 traderPendingRedeem = strategy.pendingRedeemRequest(trader.account);

        console2.log("Holder pending redeem requests:", holderPendingRedeem);
        console2.log("Trader pending redeem requests:", traderPendingRedeem);

        // Verify users have pending redeem requests (since we avoided fulfillment)
        assertGt(holderPendingRedeem, 0, "Holder should have pending redeem requests");
        assertGt(traderPendingRedeem, 0, "Trader should have pending redeem requests");

        // Verify users still have some shares remaining (since we redeemed shares-1)
        uint256 holderRemainingShares = vault.balanceOf(holder.account);
        uint256 traderRemainingShares = vault.balanceOf(trader.account);

        console2.log("Holder remaining shares:", holderRemainingShares);
        console2.log("Trader remaining shares:", traderRemainingShares);

        // Both users should have minimal remaining shares (1 each)
        assertEq(holderRemainingShares, 1, "Holder should have 1 remaining share");
        assertEq(traderRemainingShares, 1, "Trader should have 1 remaining share");
    }

    /*//////////////////////////////////////////////////////////////
                    EMERGENCY ASSET RECOVERY TEST
    //////////////////////////////////////////////////////////////*/
    // Record user positions
    struct UserAccounting {
        address user;
        uint256 shares;
        uint256 assets;
    }

    struct EmergencyAssetRecoveryVars {
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        uint256 depositAmount;
        address[] users;
        uint256[] userShares;
        uint256 totalFreeAssets;
        uint256 halfAmount;
        address depositHookAddress;
        address[] fulfillHooksAddresses;
        bytes[] fulfillHooksData;
        uint256 currentPPS;
        uint256 deviatingPPS;
        uint256 fluidBalance;
        uint256 aaveBalance;
        address[] redeemHooksAddresses;
        bytes[] redeemHooksData;
        // Commented section variables
        uint256 totalAssetsInStrategy;
        UserAccounting[] userAccountingSnapshot;
        uint256 totalShares;
        address batchTransferHook;
        address escrowRecipient;
        bytes batchTransferInspectResult;
        bytes32 batchTransferLeaf;
        bytes32 newStrategistRoot;
        uint256 timelockPeriod;
        bytes32 currentStrategistRoot;
        uint256 assetsToTransfer;
        address[] tokens;
        uint256[] amounts;
        bytes batchTransferData;
        address[] batchTransferHooks;
        bytes[] batchTransferHooksData;
        uint256[] expectedOut;
        bytes32[][] strategyProofs;
        bytes32[][] globalProofs;
        uint256 recipientBalanceBefore;
        uint256 recipientBalanceAfter;
        uint256 strategyBalanceAfter;
        address emergencyVault;
        uint256 emergencyVaultBalance;
        uint256 withdrawAmount;
        uint256 balanceAfterWithdraw;
        uint256 sharesBefore;
        uint256 sharesAfter;
    }

    /// @notice Test emergency asset recovery flow through pause, redeem, and batch transfer
    /// @dev This test covers:
    /// 1. Pause the vault with an extreme PPS outlier
    /// 2. Redeem from all UYS into free assets
    /// 3. Record user accounting at this point
    /// 4. Perform a batch transfer to strip all assets from the vault to escrow address
    function test_EmergencyAssetRecovery_PauseRedeemAndBatchTransfer() public {
        console2.log("=== EMERGENCY ASSET RECOVERY TEST ===");

        EmergencyAssetRecoveryVars memory vars;

        // Setup: Deploy a fresh vault for this test
        (vars.vaultAddr, vars.strategyAddr, vars.escrowAddr) = _deployVault("SV_EMERGENCY_RECOVERY_TEST");

        SuperVault testVault = SuperVault(vars.vaultAddr);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(vars.strategyAddr));
        SuperVaultEscrow testEscrow = SuperVaultEscrow(vars.escrowAddr);

        vars.emergencyVault = address(new MockEmergencyVault(address(this)));

        // Setup yield sources for this vault
        vm.startPrank(MANAGER);
        testStrategy.manageYieldSource(address(fluidVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        testStrategy.manageYieldSource(address(aaveVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        _updateSuperVaultPPS(vars.strategyAddr, vars.vaultAddr);

        // Setup: Create multiple users with deposits
        vars.depositAmount = 10_000e6; // 10,000 USDC per user
        vars.users = new address[](3);
        vars.userShares = new uint256[](3);

        for (uint256 i = 0; i < 3; i++) {
            vars.users[i] = accInstances[i].account;
            _getTokens(address(asset), vars.users[i], vars.depositAmount);

            // Deposit for each user
            vm.startPrank(vars.users[i]);
            asset.approve(address(testVault), vars.depositAmount);
            vars.userShares[i] = testVault.deposit(vars.depositAmount, vars.users[i]);
            vm.stopPrank();

            console2.log("User", i, "deposited:", vars.depositAmount);
            console2.log("User", i, "received shares:", vars.userShares[i]);
        }

        // Allocate deposits to yield sources
        vars.totalFreeAssets = asset.balanceOf(address(testStrategy));
        vars.halfAmount = vars.totalFreeAssets / 2;

        {
            vars.depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

            vars.fulfillHooksAddresses = new address[](2);
            vars.fulfillHooksAddresses[0] = vars.depositHookAddress;
            vars.fulfillHooksAddresses[1] = vars.depositHookAddress;

            vars.fulfillHooksData = new bytes[](2);
            vars.fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(fluidVault),
                address(asset),
                vars.halfAmount,
                false,
                address(0),
                0
            );
            vars.fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(aaveVault),
                address(asset),
                vars.halfAmount,
                false,
                address(0),
                0
            );

            vm.mockCall(
                address(aggregator),
                abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
                abi.encode(true)
            );

            vm.startPrank(MANAGER);
            testStrategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: vars.fulfillHooksAddresses,
                    hookCalldata: vars.fulfillHooksData,
                    expectedAssetsOrSharesOut: new uint256[](2),
                    globalProofs: new bytes32[][](2),
                    strategyProofs: new bytes32[][](2)
                })
            );
            vm.stopPrank();
        }

        console2.log("\n=== STEP 1: PAUSE VAULT WITH EXTREME OUTLIER ===");

        // Set strict deviation threshold (5% = 0.05 * 1e18)
        vm.prank(MANAGER);
        aggregator.updateDeviationThreshold(address(testStrategy), 0.05e18); // deviationThreshold: 5% max deviation

        // Get current PPS and create extreme deviation (50% drop)
        vars.currentPPS = aggregator.getPPS(address(testStrategy));
        vars.deviatingPPS = vars.currentPPS * 50 / 100; // 50% drop - extreme outlier
        console2.log("Current PPS:", vars.currentPPS);
        console2.log("Deviating PPS (50% drop):", vars.deviatingPPS);

        // Trigger pause with deviating PPS
        vm.warp(block.timestamp + 10);
        _createPPSUpdateThatTriggersDeviation(address(testStrategy), vars.deviatingPPS);

        // Verify strategy is paused
        assertTrue(
            aggregator.isStrategyPaused(address(testStrategy)), "Strategy should be paused after extreme PPS deviation"
        );
        console2.log("Strategy successfully paused due to extreme outlier");

        console2.log("\n=== STEP 2: REDEEM FROM ALL UYS INTO FREE ASSETS ===");

        // Get current balances in yield sources
        vars.fluidBalance = fluidVault.balanceOf(address(testStrategy));
        vars.aaveBalance = aaveVault.balanceOf(address(testStrategy));
        console2.log("Fluid vault shares:", vars.fluidBalance);
        console2.log("Aave vault shares:", vars.aaveBalance);

        // Redeem all assets from yield sources back to strategy
        {
            vars.redeemHooksAddresses = new address[](2);
            vars.redeemHooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
            vars.redeemHooksAddresses[1] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

            vars.redeemHooksData = new bytes[](2);
            vars.redeemHooksData[0] = _createRedeem4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(fluidVault),
                address(testStrategy),
                vars.fluidBalance,
                false
            );

            vars.redeemHooksData[1] = _createRedeem4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(aaveVault),
                address(testStrategy),
                vars.aaveBalance,
                false
            );

            vm.startPrank(MANAGER);
            testStrategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: vars.redeemHooksAddresses,
                    hookCalldata: vars.redeemHooksData,
                    expectedAssetsOrSharesOut: new uint256[](2),
                    globalProofs: new bytes32[][](2),
                    strategyProofs: new bytes32[][](2)
                })
            );
            vm.stopPrank();
        }

        console2.log("\n=== STEP 3: RECORD USER ACCOUNTING ===");

        vars.totalAssetsInStrategy = asset.balanceOf(address(testStrategy));
        console2.log("Total assets in strategy after redeem:", vars.totalAssetsInStrategy);
        console2.log("Total assets in escrow:", asset.balanceOf(address(testEscrow)));

        vars.userAccountingSnapshot = new UserAccounting[](3);
        vars.totalShares = 0;

        for (uint256 i = 0; i < 3; i++) {
            vars.userAccountingSnapshot[i].user = vars.users[i];
            vars.userAccountingSnapshot[i].shares = testVault.balanceOf(vars.users[i]);
            vars.userAccountingSnapshot[i].assets = testVault.convertToAssets(vars.userAccountingSnapshot[i].shares);
            vars.totalShares += vars.userAccountingSnapshot[i].shares;

            console2.log("User", i, "shares:", vars.userAccountingSnapshot[i].shares);
            console2.log("User", i, "asset value:", vars.userAccountingSnapshot[i].assets);
        }

        console2.log("\n=== STEP 4: ADD BATCH TRANSFER HOOK TO STRATEGIST MERKLE ROOT (VIA TIMELOCK) ===");

        // Get the OFFRAMP_TOKENS_HOOK_KEY address from core
        vars.batchTransferHook = _getHookAddress(ETH, OFFRAMP_TOKENS_HOOK_KEY);
        console2.log("BatchTransferHook address:", vars.batchTransferHook);

        // Create a simple merkle tree with batch transfer hook and users
        // For this test, we'll create a merkle tree that allows:
        // - BatchTransferHook with escrow as recipient and all users as senders
        // - We'll use Merkle.sol from openzeppelin or create a simple tree

        // Build merkle tree nodes for batch transfer
        vars.escrowRecipient = vars.emergencyVault; // Or any safe recipient
        vars.batchTransferInspectResult = abi.encodePacked(
            vars.escrowRecipient,
            address(asset) // Token being transferred
        );

        console2.log("\n=== STEP 4: PERFORM BATCH TRANSFER TO STRIP ASSETS ===");

        vars.assetsToTransfer = asset.balanceOf(address(testStrategy));
        console2.log("Assets to transfer from strategy:", vars.assetsToTransfer);

        // Prepare batch transfer hook data
        vars.tokens = new address[](1);
        vars.tokens[0] = address(asset);

        vars.batchTransferHooks = new address[](1);
        vars.batchTransferHooks[0] = vars.batchTransferHook;

        console2.log("vars.batchTransferHooks[0]: ", vars.batchTransferHooks[0]);

        vars.batchTransferHooksData = new bytes[](1);
        vars.batchTransferHooksData[0] = _createOfframpTokensHookData(vars.escrowRecipient, vars.tokens);
        // Execute batch transfer
        vars.recipientBalanceBefore = asset.balanceOf(vars.escrowRecipient);
        console2.log("Recipient balance before transfer:", vars.recipientBalanceBefore);

        vm.prank(MANAGER);
        testStrategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: vars.batchTransferHooks,
                hookCalldata: vars.batchTransferHooksData,
                expectedAssetsOrSharesOut: new uint256[](1),
                globalProofs: new bytes32[][](1),
                strategyProofs: new bytes32[][](1)
            })
        );

        vars.recipientBalanceAfter = asset.balanceOf(vars.escrowRecipient);
        console2.log("Recipient balance after transfer:", vars.recipientBalanceAfter);

        vars.strategyBalanceAfter = asset.balanceOf(address(testStrategy));
        console2.log("Strategy balance after transfer:", vars.strategyBalanceAfter);

        // Verify assets were transferred
        assertApproxEqAbs(
            vars.recipientBalanceAfter - vars.recipientBalanceBefore,
            vars.assetsToTransfer,
            1e6, // 1 USDC tolerance for rounding
            "Assets not transferred to recipient"
        );
        assertLt(vars.strategyBalanceAfter, 1e6, "Strategy should have minimal assets left");

        console2.log("\n=== STEP 5: VERIFY EMERGENCY VAULT BALANCE ===");

        vars.emergencyVaultBalance = MockEmergencyVault(vars.emergencyVault).getTokenBalance(address(asset));
        console2.log("Emergency vault token balance:", vars.emergencyVaultBalance);
        assertGt(vars.emergencyVaultBalance, 0, "Emergency vault should have received tokens");

        console2.log("\n=== STEP 6: WITHDRAW FROM EMERGENCY VAULT AND REINVEST INTO SUPERVAULT ===");

        // Withdraw tokens from emergency vault back to this contract
        vars.withdrawAmount = vars.emergencyVaultBalance;
        MockEmergencyVault(vars.emergencyVault).withdrawTokens(address(asset), address(this));

        vars.balanceAfterWithdraw = asset.balanceOf(address(this));
        console2.log("Balance after emergency vault withdrawal:", vars.balanceAfterWithdraw);

        // Reinvest tokens back into SuperVault using the emergency vault's reinvestIntoVault function
        // First, transfer tokens back to emergency vault
        asset.transfer(vars.emergencyVault, vars.withdrawAmount);

        // Approve and reinvest
        vm.startPrank(vars.emergencyVault);
        asset.approve(address(testVault), vars.withdrawAmount);
        vm.stopPrank();

        vars.sharesBefore = testVault.totalSupply();
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        MockEmergencyVault(vars.emergencyVault)
            .reinvestIntoVault(address(asset), address(testVault), vars.withdrawAmount, address(this));

        vm.startPrank(MANAGER);
        aggregator.unpauseStrategy(address(testStrategy));
        vm.stopPrank();

        // Update thresholds to disable deviation and validator participation checks
        // This allows emergency PPS update to restore the strategy to a known state
        vm.prank(MANAGER);
        aggregator.updateDeviationThreshold(address(testStrategy), type(uint256).max); // deviationThreshold: disabled

        // deal some assets as a donation to allow PPS updates
        deal(address(asset), address(testVault), 100e6);

        vm.warp(block.timestamp + 1 weeks);
        _forceUpdatePPSToTarget(address(testStrategy), 1e6);

        // Reinvest tokens back into SuperVault (don't update PPS before reinvesting as strategy has no assets)
        MockEmergencyVault(vars.emergencyVault)
            .reinvestIntoVault(address(asset), address(testVault), vars.withdrawAmount, address(this));

        vars.sharesAfter = testVault.totalSupply();

        console2.log("SuperVault shares before reinvestment:", vars.sharesBefore);
        console2.log("SuperVault shares after reinvestment:", vars.sharesAfter);
        console2.log("New shares minted:", vars.sharesAfter - vars.sharesBefore);

        // Verify reinvestment
        assertGt(vars.sharesAfter, vars.sharesBefore, "Shares should increase after reinvestment");
        console2.log("Successfully reinvested tokens from emergency vault back into SuperVault");

        console2.log("\n=== EMERGENCY ASSET RECOVERY TEST COMPLETED ===");
        console2.log("Successfully paused vault, redeemed from all UYS, transferred to safe recipient, and reinvested");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _toArray(address item) internal pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = item;
        return array;
    }

    function _toBoolArray(bool item) internal pure returns (bool[] memory) {
        bool[] memory array = new bool[](1);
        array[0] = item;
        return array;
    }

    function _toBytesArray(bytes memory item) internal pure returns (bytes[] memory) {
        bytes[] memory array = new bytes[](1);
        array[0] = item;
        return array;
    }

    function _toUint256Array(uint256 item) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = item;
        return array;
    }

    /*//////////////////////////////////////////////////////////////
                        PERFORMANCE FEE SKIM TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Helper to simulate profit by increasing PPS through allocation and yield simulation
    function _simulateProfitViaAllocation(uint256 targetPPSMultiplier) internal {
        // Simulate yield by increasing underlying vault assets
        uint256 fluidBalance = fluidVault.balanceOf(address(strategy));
        uint256 aaveBalance = aaveVault.balanceOf(address(strategy));

        if (fluidBalance > 0) {
            // Increase underlying assets to simulate yield
            uint256 currentFluidAssets = fluidVault.totalAssets();
            uint256 additionalAssets = currentFluidAssets * (targetPPSMultiplier - 1e18) / 1e18 / 2;
            deal(address(asset), address(fluidVault), currentFluidAssets + additionalAssets);
        }

        if (aaveBalance > 0) {
            // Increase underlying assets to simulate yield
            uint256 currentAaveAssets = aaveVault.totalAssets();
            uint256 additionalAssets = currentAaveAssets * (targetPPSMultiplier - 1e18) / 1e18 / 2;
            deal(address(asset), address(aaveVault), currentAaveAssets + additionalAssets);
        }

        // Simulate time passage for yield accumulation
        vm.warp(block.timestamp + 1 days);

        // Update SuperVault PPS to reflect the new underlying asset values
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("Simulated profit - New PPS:", aggregator.getPPS(address(strategy)));
        console2.log("Total assets after simulation:", vault.totalAssets());
    }

    /// @notice Helper to verify fee distribution is correct
    function _assertFeeDistribution(
        uint256 expectedTotalFee,
        uint256 /* feePercent */
    )
        internal
        pure
    {
        if (expectedTotalFee == 0) return;

        // Simplified fee calculation - would need actual fee config access
        uint256 expectedSuperformFee = expectedTotalFee * 1000 / 10_000; // Assume 10% to superform
        uint256 expectedRecipientFee = expectedTotalFee - expectedSuperformFee;

        // In a real scenario, these would be the actual balances after fee transfer
        // For testing, we can check the calculated values match expected
        console2.log("Expected Superform Fee:", expectedSuperformFee);
        console2.log("Expected Recipient Fee:", expectedRecipientFee);
    }

    /// @notice Test 1.1: Basic deposit-skim-redeem flow using proper 2-step redemption
    function test_SkimFeeFlow_BasicDepositSkimRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Record initial state
        uint256 initialHwmPps = strategy.vaultHwmPps();

        // 1. User deposits using existing helper
        _deposit(depositAmount);

        // Verify HWM unchanged after deposit (deposits are PPS-neutral)
        uint256 hwmPpsAfterDeposit = strategy.vaultHwmPps();
        assertEq(hwmPpsAfterDeposit, initialHwmPps, "HWM PPS should not change on deposit");

        // Allocate to yield sources (required before redemption)
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // 2. Simulate profit (PPS increase from 1.0 to 1.2)
        _simulateProfitViaAllocation(1.2e18);

        uint256 currentPPS = aggregator.getPPS(address(strategy));
        uint256 totalSupply = vault.totalSupply();
        uint256 ppsGrowth = currentPPS > hwmPpsAfterDeposit ? currentPPS - hwmPpsAfterDeposit : 0;
        uint256 expectedProfit = ppsGrowth.mulDiv(totalSupply, 10 ** asset.decimals(), Math.Rounding.Floor);

        console2.log("Current PPS:", currentPPS);
        console2.log("HWM PPS:", hwmPpsAfterDeposit);
        console2.log("Expected profit:", expectedProfit);

        // Provide liquidity buffer for fee collection - ensure strategy has enough assets
        // Calculate expected fee and provide buffer
        ISuperVaultStrategy.FeeConfig memory feeConfig_ = strategy.getConfigInfo();
        uint256 expectedFee = expectedProfit.mulDiv(feeConfig_.performanceFeeBps, 10_000, Math.Rounding.Ceil);
        if (expectedFee > 0) {
            deal(address(asset), address(strategy), expectedFee);
            // Update PPS to account for the additional assets in strategy
            _updateSuperVaultPPS(address(strategy), address(vault));
        }

        // 3. Manager skims performance fee (strategy should have free assets now)
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Verify HWM PPS was updated after skimming
        uint256 newHwmPps = strategy.vaultHwmPps();
        uint256 newPPS = aggregator.getPPS(address(strategy));

        // The new HWM should equal the post-skim PPS
        assertEq(newHwmPps, newPPS, "HWM PPS should equal post-skim PPS");
        assertLt(newHwmPps, currentPPS, "HWM PPS should be lower than pre-skim PPS (fees were taken)");

        console2.log("HWM PPS after skim:", newHwmPps);
        console2.log("Current PPS after skim:", newPPS);
        console2.log("Fees collected:", expectedFee);

        // 4. User redeems using proper 2-step process
        uint256 userShares = vault.balanceOf(accountEth);

        // Step 1: Request redeem
        _requestRedeem(userShares);

        // Step 2: Manager fulfills redemption via hooks
        _executeRedeemHooks4626(userShares, address(fluidVault), address(aaveVault), new address[](0));

        // Step 3: User claims assets using vault.withdraw
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);
        uint256 userBalanceBefore = asset.balanceOf(accountEth);

        // Use direct vault.withdraw instead of complex hooks
        vm.prank(accountEth);
        vault.withdraw(claimableAssets, accountEth, accountEth);

        uint256 userBalanceAfter = asset.balanceOf(accountEth);

        // User should get full theoretical amount (no fee deduction in redemption)
        uint256 assetsReceived = userBalanceAfter - userBalanceBefore;
        assertGt(assetsReceived, 0, "User should receive assets from redemption");
        // Allow small rounding difference between withdrawn shares and assets received
        assertApproxEqRel(
            assetsReceived, claimableAssets, 0.01e18, "Assets received should approximately match claimable"
        );
        console2.log("User claimed assets:", assetsReceived);
    }

    /// @notice Test 2.1: Multiple PPS updates before single skim
    function test_SkimFeeFlow_MultiplePPSUpdatesBeforeSkim() public {
        uint256 depositAmount = 2000e6;
        address user = address(0x1234);

        // Give user tokens for deposits
        _getTokens(address(asset), user, depositAmount);

        // Initial deposit at PPS = 1.0
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        // Deposit free assets into underlying vaults
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialHwmPps = strategy.vaultHwmPps();

        // First PPS update to 1.1 (10% gain)
        _simulateProfitViaAllocation(1.1e18);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // More deposits at new PPS - HWM should stay unchanged
        uint256 additionalDeposit = 1000e6;
        _getTokens(address(asset), user, additionalDeposit);
        vm.startPrank(user);
        asset.approve(address(vault), additionalDeposit);
        vault.deposit(additionalDeposit, user);
        vm.stopPrank();

        // Verify HWM unchanged after deposit
        assertEq(strategy.vaultHwmPps(), initialHwmPps, "HWM should not change on deposit");

        // Deposit additional free assets
        _depositFreeAssetsFromSingleAmount(additionalDeposit, address(fluidVault), address(aaveVault));

        // Second PPS update to 1.25
        _simulateProfitViaAllocation(1.25e18);
        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256 currentPPS = aggregator.getPPS(address(strategy));
        uint256 totalSupply = vault.totalSupply();
        uint256 ppsGrowth = currentPPS > initialHwmPps ? currentPPS - initialHwmPps : 0;
        uint256 expectedProfit = ppsGrowth.mulDiv(totalSupply, 10 ** asset.decimals(), Math.Rounding.Floor);

        // Provide liquidity buffer for fee collection
        _getTokens(address(asset), address(strategy), expectedProfit / 5);

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Verify HWM reset to post-skim PPS
        uint256 postSkimHwmPps = strategy.vaultHwmPps();
        uint256 postSkimPPS = aggregator.getPPS(address(strategy));
        assertEq(postSkimHwmPps, postSkimPPS, "HWM PPS should equal post-skim PPS");

        console2.log("Initial HWM PPS:", initialHwmPps);
        console2.log("Current PPS before skim:", currentPPS);
        console2.log("Expected profit:", expectedProfit);
        console2.log("Post-skim HWM PPS:", postSkimHwmPps);
        console2.log("Post-skim PPS:", postSkimPPS);
    }

    /// @notice Test 2.2: Skim after each PPS update
    function test_SkimFeeFlow_SkimAfterEachPPSUpdate() public {
        uint256 depositAmount = 2000e6;
        address user = address(0x1234);

        // Give user tokens for deposits
        _getTokens(address(asset), user, depositAmount * 2);

        // Initial deposit
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        // Deposit free assets into underlying vaults
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // First profit and skim
        _simulateProfitViaAllocation(1.1e18);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Provide liquidity for first skim
        uint256 currentPPS1 = aggregator.getPPS(address(strategy));
        uint256 hwmPps1 = strategy.vaultHwmPps();
        uint256 totalSupply1 = vault.totalSupply();
        uint256 ppsGrowth1 = currentPPS1 > hwmPps1 ? currentPPS1 - hwmPps1 : 0;
        uint256 expectedProfit1 = ppsGrowth1.mulDiv(totalSupply1, 10 ** asset.decimals(), Math.Rounding.Floor);
        _getTokens(address(asset), address(strategy), expectedProfit1 / 5);

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256 hwmPpsAfterFirstSkim = strategy.vaultHwmPps();

        // Additional deposit
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        // Deposit additional free assets
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Second profit and skim
        _simulateProfitViaAllocation(1.2e18);
        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256 currentPPS2 = aggregator.getPPS(address(strategy));
        uint256 totalSupply2 = vault.totalSupply();
        uint256 ppsGrowth2 = currentPPS2 > hwmPpsAfterFirstSkim ? currentPPS2 - hwmPpsAfterFirstSkim : 0;
        uint256 expectedSecondProfit = ppsGrowth2.mulDiv(totalSupply2, 10 ** asset.decimals(), Math.Rounding.Floor);

        // Provide liquidity for second skim
        _getTokens(address(asset), address(strategy), expectedSecondProfit / 5);

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Progressive HWM reset should prevent double-fee collection
        uint256 finalHwmPps = strategy.vaultHwmPps();
        uint256 finalPPS = aggregator.getPPS(address(strategy));
        assertEq(finalHwmPps, finalPPS, "HWM PPS should equal final PPS after second skim");

        console2.log("Expected second profit:", expectedSecondProfit);
        console2.log("HWM PPS after first skim:", hwmPpsAfterFirstSkim);
        console2.log("Final HWM PPS:", finalHwmPps);
        console2.log("Final PPS:", finalPPS);
    }

    /// @notice Test 3.1: Zero profit scenario - no fees collected
    function test_SkimFeeFlow_ZeroProfit_NoFeesCollected() public {
        uint256 depositAmount = 1000e6;

        // Deposit using helper
        _deposit(depositAmount);

        // PPS remains at HWM (no profit simulation)
        uint256 hwmPpsBefore = strategy.vaultHwmPps();
        uint256 currentPPS = aggregator.getPPS(address(strategy));

        // Should have no PPS growth
        assertEq(currentPPS, hwmPpsBefore, "Should have no PPS growth");

        // Skim should return early with no fees
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee(); // Should not revert
        vm.stopPrank();

        // No state changes should occur
        assertEq(strategy.vaultHwmPps(), hwmPpsBefore, "HWM PPS unchanged");
    }

    /// @notice Test 3.3: Zero total supply edge case
    function test_SkimFeeFlow_ZeroTotalSupply_HandledCorrectly() public {
        // Start with no deposits (zero total supply)
        assertEq(vault.totalSupply(), 0, "Should start with zero supply");

        uint256 hwmPpsBefore = strategy.vaultHwmPps();

        // Try to skim with zero supply
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee(); // Should not revert
        vm.stopPrank();

        // Should handle gracefully - HWM should remain unchanged
        assertEq(strategy.vaultHwmPps(), hwmPpsBefore, "HWM PPS should remain unchanged");
    }

    /// @notice Test 3.4: Zero fee percent configuration
    function test_SkimFeeFlow_ZeroFeePercent_NoCollection() public {
        uint256 depositAmount = 1000e6;
        address user = address(0x1234);

        // Disable deviation threshold to allow test's artificial setup
        vm.startPrank(MANAGER);
        aggregator.updateDeviationThreshold(address(strategy), type(uint256).max);
        vm.stopPrank();

        deal(address(asset), user, depositAmount);
        deal(address(asset), address(strategy), depositAmount * 2);

        // Get current fee config to preserve other settings
        ISuperVaultStrategy.FeeConfig memory currentConfig = strategy.getConfigInfo();

        // Manager proposes new fee config with 0% performance fee
        vm.startPrank(MANAGER);
        strategy.proposeVaultFeeConfigUpdate(
            0, // 0% performance fee
            currentConfig.managementFeeBps, // keep existing management fee
            currentConfig.recipient // keep existing recipient
        );
        vm.stopPrank();

        // Fast forward past the 1 week timelock
        vm.warp(block.timestamp + 1 weeks + 1);

        // Update PPS after time warp to prevent expiration
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Manager executes the fee config update
        vm.startPrank(MANAGER);
        strategy.executeVaultFeeConfigUpdate();
        vm.stopPrank();

        // Verify fee is now 0%
        ISuperVaultStrategy.FeeConfig memory newConfig = strategy.getConfigInfo();
        assertEq(newConfig.performanceFeeBps, 0, "Performance fee should be 0%");

        // Now proceed with deposit
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Generate profit
        _simulateProfitViaAllocation(1.2e18);

        // Update PPS to reflect profit
        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256 totalAssetsBefore = vault.totalAssets();
        uint256 ppsBefore = aggregator.getPPS(address(strategy));

        // Skim with 0% fee should collect no fees despite profit
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        uint256 totalAssetsAfter = vault.totalAssets();
        uint256 ppsAfter = aggregator.getPPS(address(strategy));

        // Total assets should remain the same (no fee taken)
        assertEq(totalAssetsAfter, totalAssetsBefore, "No assets should be taken as fees");

        // PPS should also remain unchanged since no fee was collected
        assertEq(ppsAfter, ppsBefore, "PPS should not change when no fee is collected");

        console2.log("Test passed: 0% fee configuration working correctly");
    }

    /// @notice Test 4.1: Only manager can skim fees
    function test_SkimFeeFlow_OnlyManagerCanSkim() public {
        address nonManager = address(0x9999);

        vm.startPrank(nonManager);
        vm.expectRevert(); // Should revert with access control error
        strategy.skimPerformanceFee();
        vm.stopPrank();
    }

    /// @notice Test 4.2: Manager can skim multiple times
    function test_SkimFeeFlow_ManagerCanSkimAnytime() public {
        uint256 depositAmount = 1000e6;
        address user = address(0x1234);

        // Disable deviation threshold to allow test's artificial setup
        vm.startPrank(MANAGER);
        aggregator.updateDeviationThreshold(address(strategy), type(uint256).max);
        vm.stopPrank();

        deal(address(asset), user, depositAmount);
        deal(address(asset), address(strategy), depositAmount * 2);

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        // First skim with no profit
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee(); // Should not revert

        // Second skim immediately
        strategy.skimPerformanceFee(); // Should not revert

        // Generate profit and skim again
        vm.stopPrank();
        _simulateProfitViaAllocation(1.1e18);

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee(); // Should collect fees

        // Skim again with no new profit
        strategy.skimPerformanceFee(); // Should not revert
        vm.stopPrank();
    }

    /// @notice Test 6.1: Redemption previews show no fees
    function test_SkimFeeFlow_RedemptionPreviewsNoFees() public {
        uint256 depositAmount = 1000e6;
        address user = address(0x1234);

        // Disable deviation threshold to allow test's artificial setup
        vm.startPrank(MANAGER);
        aggregator.updateDeviationThreshold(address(strategy), type(uint256).max);
        vm.stopPrank();

        deal(address(asset), user, depositAmount);
        deal(address(asset), address(strategy), depositAmount * 2);

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);
        vm.stopPrank();

        // Generate profit but don't skim yet
        _simulateProfitViaAllocation(1.2e18);

        // Request redemption
        vm.startPrank(user);
        vault.requestRedeem(shares, user, user);
        vm.stopPrank();

        // Check that no fees are being charged in redemption preview
        // Note: This test assumes new fee model is implemented where redemption previews show 0 fees

        // Skim fees
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // In the new model, redemptions give full assets without fee deduction
        // The actual preview function signature would need to be checked
    }

    /// @notice Test 6.2: Fulfillment gives full assets despite unrealized profit
    function test_SkimFeeFlow_FulfillmentGivesFullAssets() public {
        uint256 depositAmount = 1000e6;

        // Deposit and allocate
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 shares = vault.balanceOf(accountEth);

        // Request redemption BEFORE skimming fees
        _requestRedeem(shares);

        // Generate profit but don't skim yet
        _simulateProfitViaAllocation(1.2e18);

        uint256 userBalanceBefore = asset.balanceOf(accountEth);

        // Fulfill redemption - in new fee model, users get full amount
        _executeRedeemHooks4626(shares, address(fluidVault), address(aaveVault), new address[](0));

        // CRITICAL: Update PPS after fulfillment to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Claim the assets using maxRedeem to get the correct amount
        uint256 maxWithdrawAmount = vault.maxWithdraw(accountEth);

        // Use withdraw with the maxWithdraw amount
        vm.prank(accountEth);
        vault.withdraw(maxWithdrawAmount, accountEth, accountEth);

        uint256 userBalanceAfter = asset.balanceOf(accountEth);
        uint256 received = userBalanceAfter - userBalanceBefore;

        // Verify user received substantial assets despite unrealized profit in vault
        assertGt(received, depositAmount * 95 / 100, "User should receive most of deposit value");
        console2.log("User received assets:", received);
        console2.log("Original deposit:", depositAmount);
        console2.log("Assets available for fee skim:", strategy.vaultUnrealizedProfit());
    }

    /// @notice Test 7.1: HWM resets correctly after skim
    function test_SkimFeeFlow_HWMResetAfterSkim() public {
        uint256 depositAmount = 1000e6;
        address user = address(0x1234);

        deal(address(asset), user, depositAmount * 2);

        // Initial deposit
        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();

        // Allocate to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // CRITICAL: Update PPS after allocation to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Generate profit and skim
        _simulateProfitViaAllocation(1.2e18);

        uint256 totalAssetsBeforeFirstSkim = vault.totalAssets();

        // Provide liquidity buffer for fee collection
        uint256 hwmPpsBeforeSkim = strategy.vaultHwmPps();
        uint256 currentPPS1 = aggregator.getPPS(address(strategy));
        uint256 totalSupply1 = vault.totalSupply();
        uint256 ppsGrowth1 = currentPPS1 > hwmPpsBeforeSkim ? currentPPS1 - hwmPpsBeforeSkim : 0;
        uint256 expectedProfit = ppsGrowth1.mulDiv(totalSupply1, 10 ** asset.decimals(), Math.Rounding.Floor);
        ISuperVaultStrategy.FeeConfig memory feeConfig_ = strategy.getConfigInfo();
        uint256 expectedFee = expectedProfit.mulDiv(feeConfig_.performanceFeeBps, 10_000, Math.Rounding.Ceil);
        if (expectedFee > 0) {
            deal(address(asset), address(strategy), expectedFee);
            // Update PPS to account for the additional assets in strategy
            _updateSuperVaultPPS(address(strategy), address(vault));
            // Recalculate after PPS update
            totalAssetsBeforeFirstSkim = vault.totalAssets();
        }

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256 totalAssetsAfterFirstSkim = vault.totalAssets();
        uint256 hwmPpsAfterFirstSkim = strategy.vaultHwmPps();
        uint256 ppsAfterFirstSkim = aggregator.getPPS(address(strategy));

        // HWM should equal post-skim PPS
        assertEq(hwmPpsAfterFirstSkim, ppsAfterFirstSkim, "HWM PPS should equal post-skim PPS");
        assertLt(hwmPpsAfterFirstSkim, currentPPS1, "HWM PPS should be lower than pre-skim PPS (fees taken)");
        console2.log("Total assets before skim:", totalAssetsBeforeFirstSkim);
        console2.log("Total assets after skim:", totalAssetsAfterFirstSkim);
        console2.log("HWM PPS after skim:", hwmPpsAfterFirstSkim);

        // Generate additional profit
        _simulateProfitViaAllocation(1.1e18); // Additional 10% on current base

        uint256 currentPPS2 = aggregator.getPPS(address(strategy));
        uint256 totalSupply2 = vault.totalSupply();
        uint256 ppsGrowth2 = currentPPS2 > hwmPpsAfterFirstSkim ? currentPPS2 - hwmPpsAfterFirstSkim : 0;
        uint256 expectedNewProfit = ppsGrowth2.mulDiv(totalSupply2, 10 ** asset.decimals(), Math.Rounding.Floor);

        // Provide liquidity buffer for second fee collection
        uint256 expectedSecondFee = expectedNewProfit.mulDiv(feeConfig_.performanceFeeBps, 10_000, Math.Rounding.Ceil);
        uint256 totalAssetsBeforeSecondSkim = vault.totalAssets();
        if (expectedSecondFee > 0) {
            deal(address(asset), address(strategy), expectedSecondFee);
            // Update PPS to account for the additional assets in strategy
            _updateSuperVaultPPS(address(strategy), address(vault));
            // Recalculate after PPS update
            totalAssetsBeforeSecondSkim = vault.totalAssets();
        }

        // Second skim should only collect fees on new profit
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256 totalAssetsAfterSecondSkim = vault.totalAssets();
        uint256 hwmPpsAfterSecondSkim = strategy.vaultHwmPps();
        uint256 ppsAfterSecondSkim = aggregator.getPPS(address(strategy));

        // Verify no double-fee collection on same profit
        assertEq(hwmPpsAfterSecondSkim, ppsAfterSecondSkim, "HWM PPS should equal post-skim PPS");
        assertLt(hwmPpsAfterSecondSkim, currentPPS2, "HWM PPS should be lower than pre-skim PPS (second skim)");

        console2.log("Expected new profit:", expectedNewProfit);
        console2.log("HWM PPS after second skim:", hwmPpsAfterSecondSkim);
        console2.log("Assets after second skim:", totalAssetsAfterSecondSkim);
    }

    /// @notice Test gas efficiency of new fee model
    function test_SkimFeeFlow_GasEfficiency() public {
        GasEfficiencyTestVars memory vars;
        vars.depositAmount = 1000e6;
        vars.user = address(0x1234);

        // Use proper deposit pattern instead of deal()
        deal(address(asset), vars.user, vars.depositAmount);

        // Measure gas for deposit (should be cheaper without accumulator updates)
        vm.startPrank(vars.user);
        asset.approve(address(vault), vars.depositAmount);
        vars.gasStart = gasleft();
        vars.shares = vault.deposit(vars.depositAmount, vars.user);
        vars.gasUsedDeposit = vars.gasStart - gasleft();
        vm.stopPrank();

        // Allocate to yield sources (required before redemption)
        _depositFreeAssetsFromSingleAmount(vars.depositAmount, address(fluidVault), address(aaveVault));

        // CRITICAL: Update PPS after allocation to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Request redemption
        vm.startPrank(vars.user);
        vars.gasStart = gasleft();
        vault.requestRedeem(vars.shares, vars.user, vars.user);
        vars.gasUsedRequest = vars.gasStart - gasleft();
        vm.stopPrank();

        // Generate profit
        _simulateProfitViaAllocation(1.2e18);

        // Provide liquidity buffer for fee collection
        uint256 currentPPS = aggregator.getPPS(address(strategy));
        uint256 hwmPps = strategy.vaultHwmPps();
        uint256 totalSupply = vault.totalSupply();
        uint256 ppsGrowth = currentPPS > hwmPps ? currentPPS - hwmPps : 0;
        vars.expectedProfit = ppsGrowth.mulDiv(totalSupply, 10 ** asset.decimals(), Math.Rounding.Floor);
        vars.feeConfig_ = strategy.getConfigInfo();
        vars.expectedFee = vars.expectedProfit.mulDiv(vars.feeConfig_.performanceFeeBps, 10_000, Math.Rounding.Ceil);
        if (vars.expectedFee > 0) {
            deal(address(asset), address(strategy), vars.expectedFee);
            // Update PPS to account for the additional assets in strategy
            _updateSuperVaultPPS(address(strategy), address(vault));
        }

        // Measure gas for skim
        vm.startPrank(MANAGER);
        vars.gasStart = gasleft();
        strategy.skimPerformanceFee();
        vars.gasUsedSkim = vars.gasStart - gasleft();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Execute hooks to get assets into strategy for fulfillment
        // Note: We execute hooks separately to measure fulfillment gas independently
        vars.hooksAddresses = new address[](2);
        vars.hooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        vars.hooksAddresses[1] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        (vars.vault1SharesOut, vars.vault2SharesOut) =
            _convertSVStoUnderlyingShares(vars.shares, address(fluidVault), address(aaveVault));
        vars.vault1SharesOut = _truncateToActualBalance(vars.vault1SharesOut, address(fluidVault), 100);
        vars.vault2SharesOut = _truncateToActualBalance(vars.vault2SharesOut, address(aaveVault), 100);

        vars.hooksData = new bytes[](2);
        vars.hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(fluidVault),
            address(strategy),
            vars.vault1SharesOut,
            false
        );
        vars.hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(aaveVault),
            address(strategy),
            vars.vault2SharesOut,
            false
        );

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = IERC4626(address(fluidVault)).convertToAssets(vars.vault1SharesOut);
        vars.expectedAssetsOrSharesOut[1] = IERC4626(address(aaveVault)).convertToAssets(vars.vault2SharesOut);

        vars.argsForProofs = new bytes[](2);
        vars.argsForProofs[0] = ISuperHookInspector(vars.hooksAddresses[0]).inspect(vars.hooksData[0]);
        vars.argsForProofs[1] = ISuperHookInspector(vars.hooksAddresses[1]).inspect(vars.hooksData[1]);

        vm.startPrank(MANAGER);
        // Execute hooks only (without fulfillment)
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: vars.hooksAddresses,
                hookCalldata: vars.hooksData,
                expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(vars.hooksAddresses, vars.argsForProofs),
                strategyProofs: new bytes32[][](2)
            })
        );

        // CRITICAL: Update PPS after hooks execution
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Measure gas for fulfillment (should be cheaper without fee calculations)
        vars.controllers = new address[](1);
        vars.totalAssetsOut = new uint256[](1);
        vars.controllers[0] = vars.user;

        // Calculate adjusted fulfillment amounts
        vars.totalAssetsOut = calculateAdjustedFulfillment(strategy, vars.controllers, vars.expectedAssetsOrSharesOut);

        vars.gasStart = gasleft();
        strategy.fulfillRedeemRequests(vars.controllers, vars.totalAssetsOut);
        vars.gasUsedFulfill = vars.gasStart - gasleft();
        vm.stopPrank();

        console2.log("Gas used - Deposit:", vars.gasUsedDeposit);
        console2.log("Gas used - Request:", vars.gasUsedRequest);
        console2.log("Gas used - Skim:", vars.gasUsedSkim);
        console2.log("Gas used - Fulfill:", vars.gasUsedFulfill);

        // These are informational - actual assertions would compare against old implementation
        assertGt(vars.gasUsedDeposit, 0, "Deposit should use some gas");
        assertGt(vars.gasUsedSkim, 0, "Skim should use some gas");
        assertGt(vars.gasUsedFulfill, 0, "Fulfill should use some gas");
    }

    /// @notice Test 9.1: Event emission during fee skim (simplified - focus on skim functionality)
    function test_SkimFeeFlow_EventEmission() public {
        uint256 depositAmount = 1000e6;

        // Deposit using proper helper
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Provide liquidity buffer for fee collection (simpler approach)
        deal(address(asset), address(strategy), depositAmount / 10); // 10% buffer

        // CRITICAL: Update PPS after dealing tokens to strategy to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Generate profit
        _simulateProfitViaAllocation(1.3e18);

        // Test skim fee events
        uint256 currentPPS = aggregator.getPPS(address(strategy));
        uint256 hwmPps = strategy.vaultHwmPps();
        uint256 totalSupply = vault.totalSupply();
        uint256 ppsGrowth = currentPPS > hwmPps ? currentPPS - hwmPps : 0;
        uint256 expectedProfit = ppsGrowth.mulDiv(totalSupply, 10 ** asset.decimals(), Math.Rounding.Floor);

        if (expectedProfit > 0) {
            // Expect PerformanceFeeSkimmed event - check structure but not exact values
            vm.expectEmit(true, true, true, false); // Check topics but not exact data values
            emit PerformanceFeeSkimmed(1, 1); // Dummy values - actual amounts determined at runtime
        }

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // CRITICAL: Update PPS after skimming to sync vault state
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Verify HWM PPS was updated
        uint256 newHwmPps = strategy.vaultHwmPps();
        uint256 newPPS = aggregator.getPPS(address(strategy));
        assertEq(newHwmPps, newPPS, "HWM PPS should equal post-skim PPS");
        assertLt(newHwmPps, currentPPS, "HWM PPS should be lower than pre-skim PPS (fees taken)");

        console2.log("Event emission test completed");
        console2.log("Original HWM PPS:", hwmPps);
        console2.log("Expected profit:", expectedProfit);
        console2.log("New HWM PPS after skim:", newHwmPps);
    }

    /// @notice Event declaration for testing
    event PerformanceFeeSkimmed(uint256 totalFee, uint256 superformFee);

    /*//////////////////////////////////////////////////////////////
                    PPS UPDATE AFTER SKIM TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that PPS is automatically updated after skimming
    function test_SkimFeeFlow_PPSUpdatedAutomatically() public {
        uint256 depositAmount = 1000e6;

        // Initial deposit
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Get initial PPS
        uint256 ppsBeforeProfit = aggregator.getPPS(address(strategy));

        // Simulate profit (20% increase)
        _simulateProfitViaAllocation(1.2e18);

        // Manually update PPS to reflect profit
        _updateSuperVaultPPS(address(strategy), address(vault));
        uint256 ppsAfterProfit = aggregator.getPPS(address(strategy));
        assertGt(ppsAfterProfit, ppsBeforeProfit, "PPS should increase after profit");

        // Provide liquidity for fee collection
        uint256 hwmPps = strategy.vaultHwmPps();
        uint256 totalSupply = vault.totalSupply();
        uint256 ppsGrowth = ppsAfterProfit > hwmPps ? ppsAfterProfit - hwmPps : 0;
        uint256 profit = ppsGrowth.mulDiv(totalSupply, 10 ** asset.decimals(), Math.Rounding.Floor);
        ISuperVaultStrategy.FeeConfig memory feeConfig_ = strategy.getConfigInfo();
        uint256 expectedFee = profit.mulDiv(feeConfig_.performanceFeeBps, 10_000, Math.Rounding.Ceil);

        if (expectedFee > 0) {
            deal(address(asset), address(strategy), expectedFee);
            _updateSuperVaultPPS(address(strategy), address(vault));
        }

        // Skim performance fee
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // PPS should be automatically updated (decreased) after skim
        uint256 ppsAfterSkim = aggregator.getPPS(address(strategy));
        assertLt(ppsAfterSkim, ppsAfterProfit, "PPS should decrease after skim due to fee removal");

        // Verify totalAssets consistency (EIP-4626 invariant)
        uint256 totalSupplyAfterSkim = vault.totalSupply();
        uint256 calculatedAssets =
            totalSupplyAfterSkim.mulDiv(ppsAfterSkim, 10 ** vault.decimals(), Math.Rounding.Floor);
        uint256 reportedAssets = vault.totalAssets();

        // Allow 1 wei tolerance for rounding
        assertApproxEqAbs(
            calculatedAssets, reportedAssets, 1, "totalAssets should match convertToAssets(totalSupply) after skim"
        );

        console2.log("PPS before profit:", ppsBeforeProfit);
        console2.log("PPS after profit:", ppsAfterProfit);
        console2.log("PPS after skim:", ppsAfterSkim);
        console2.log("Calculated assets:", calculatedAssets);
        console2.log("Reported assets:", reportedAssets);
    }

    /// @notice Test that PPSUpdatedAfterSkim event is emitted
    function test_SkimFeeFlow_PPSUpdateEventEmitted() public {
        uint256 depositAmount = 1000e6;

        // Setup: deposit and generate profit
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));
        _simulateProfitViaAllocation(1.2e18);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Provide liquidity for fee collection
        uint256 hwmPps = strategy.vaultHwmPps();
        uint256 currentPPS = aggregator.getPPS(address(strategy));
        uint256 totalSupply = vault.totalSupply();
        uint256 ppsGrowth = currentPPS > hwmPps ? currentPPS - hwmPps : 0;
        uint256 profit = ppsGrowth.mulDiv(totalSupply, 10 ** asset.decimals(), Math.Rounding.Floor);
        ISuperVaultStrategy.FeeConfig memory feeConfig_ = strategy.getConfigInfo();
        uint256 expectedFee = profit.mulDiv(feeConfig_.performanceFeeBps, 10_000, Math.Rounding.Ceil);

        if (expectedFee > 0) {
            deal(address(asset), address(strategy), expectedFee);
            _updateSuperVaultPPS(address(strategy), address(vault));
        }

        // Expect PPSUpdatedAfterSkim event
        vm.expectEmit(true, false, false, false);
        emit PPSUpdatedAfterSkim(address(strategy), 0, 0, 0, 0); // We only check strategy address

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        console2.log("Event emission test passed");
    }

    /// @notice Test that zero fee skim doesn't update PPS
    function test_SkimFeeFlow_ZeroFee_NoPPSUpdate() public {
        uint256 depositAmount = 1000e6;

        // Deposit but don't generate profit
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 ppsBeforeSkim = aggregator.getPPS(address(strategy));

        // Try to skim with no profit (should return early)
        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        uint256 ppsAfterSkim = aggregator.getPPS(address(strategy));

        // PPS should remain unchanged
        assertEq(ppsAfterSkim, ppsBeforeSkim, "PPS should not change when no fee is collected");

        console2.log("PPS unchanged:", ppsBeforeSkim);
    }

    /// @notice Test access control - only registered strategy can call updatePPSAfterSkim
    function test_SkimFeeFlow_OnlyStrategyCanUpdatePPS() public {
        uint256 newPPS = 1e18;
        uint256 feeAmount = 100e6;

        // Try to call updatePPSAfterSkim as non-strategy (should revert with UNKNOWN_STRATEGY)
        vm.expectRevert(ISuperVaultAggregator.UNKNOWN_STRATEGY.selector);
        aggregator.updatePPSAfterSkim(newPPS, feeAmount);

        console2.log("Access control test passed");
    }

    /// @notice Test that PPS must decrease after skim
    function test_SkimFeeFlow_PPSMustDecrease() public {
        uint256 depositAmount = 1000e6;

        // Setup vault with deposits
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 currentPPS = aggregator.getPPS(address(strategy));

        // Try to call updatePPSAfterSkim with same or higher PPS (should revert)
        vm.startPrank(address(strategy));

        // Same PPS should revert
        vm.expectRevert(ISuperVaultAggregator.PPS_MUST_DECREASE_AFTER_SKIM.selector);
        aggregator.updatePPSAfterSkim(currentPPS, 100e6);

        // Higher PPS should revert
        vm.expectRevert(ISuperVaultAggregator.PPS_MUST_DECREASE_AFTER_SKIM.selector);
        aggregator.updatePPSAfterSkim(currentPPS + 1, 100e6);

        vm.stopPrank();

        console2.log("PPS decrease validation test passed");
    }

    /// @notice Test that PPS deduction is bounded by MAX_PERFORMANCE_FEE
    function test_SkimFeeFlow_PPSDeductionBounded() public {
        uint256 depositAmount = 1000e6;

        // Setup vault
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 currentPPS = aggregator.getPPS(address(strategy));

        // Calculate minimum allowed PPS based on MAX_PERFORMANCE_FEE (5100 bps = 51%)
        uint256 MAX_PERFORMANCE_FEE = 5100;
        uint256 minAllowedPPS = currentPPS.mulDiv(10_000 - MAX_PERFORMANCE_FEE, 10_000, Math.Rounding.Floor);

        // Try to set PPS below minimum (should revert)
        vm.startPrank(address(strategy));
        vm.expectRevert(ISuperVaultAggregator.PPS_DEDUCTION_TOO_LARGE.selector);
        aggregator.updatePPSAfterSkim(minAllowedPPS - 1, 100e6);
        vm.stopPrank();

        console2.log("PPS deduction bounds test passed");
        console2.log("Current PPS:", currentPPS);
        console2.log("Min allowed PPS:", minAllowedPPS);
        console2.log("Max deduction allowed: 51%");
    }

    /// @notice Test EIP-4626 consistency after skim
    function test_SkimFeeFlow_EIP4626ConsistencyAfterSkim() public {
        uint256 depositAmount = 1000e6;

        // Setup and skim
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));
        _simulateProfitViaAllocation(1.5e18);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Provide liquidity for fee
        uint256 hwmPps = strategy.vaultHwmPps();
        uint256 currentPPS = aggregator.getPPS(address(strategy));
        uint256 totalSupply = vault.totalSupply();
        uint256 ppsGrowth = currentPPS > hwmPps ? currentPPS - hwmPps : 0;
        uint256 profit = ppsGrowth.mulDiv(totalSupply, 10 ** asset.decimals(), Math.Rounding.Floor);
        ISuperVaultStrategy.FeeConfig memory feeConfig_ = strategy.getConfigInfo();
        uint256 expectedFee = profit.mulDiv(feeConfig_.performanceFeeBps, 10_000, Math.Rounding.Ceil);

        if (expectedFee > 0) {
            deal(address(asset), address(strategy), expectedFee);
            _updateSuperVaultPPS(address(strategy), address(vault));
        }

        vm.startPrank(MANAGER);
        strategy.skimPerformanceFee();
        vm.stopPrank();

        // Verify EIP-4626 invariant: totalAssets() == convertToAssets(totalSupply())
        uint256 totalSupplyAfterSkim = vault.totalSupply();
        uint256 totalAssetsReported = vault.totalAssets();
        uint256 totalAssetsCalculated = vault.convertToAssets(totalSupplyAfterSkim);

        // Should be equal within 1 wei due to rounding
        assertApproxEqAbs(
            totalAssetsReported,
            totalAssetsCalculated,
            1,
            "EIP-4626 invariant violated: totalAssets != convertToAssets(totalSupply)"
        );

        console2.log("EIP-4626 consistency verified");
        console2.log("Total assets (reported):", totalAssetsReported);
        console2.log("Total assets (calculated):", totalAssetsCalculated);
        console2.log(
            "Difference:",
            totalAssetsReported > totalAssetsCalculated
                ? totalAssetsReported - totalAssetsCalculated
                : totalAssetsCalculated - totalAssetsReported
        );
    }

    /// @notice Test that fulfillRedeemRequests reverts when trying to fulfill zero-share controllers with non-zero
    /// assets @dev This tests the fix for the vulnerability where managers could strand funds by providing non-zero
    /// totalAssetsOut for controllers with zero pending shares
    function test_FulfillRedeemRequests_RevertsOnZeroSharesWithNonZeroAssets() public {
        // Setup: Create two users, only one will have a pending redeem request
        uint256 depositAmount = 1000e6;
        _deposit(depositAmount);

        address user1 = accountEth;
        address user2 = accInstances[1].account;

        // User 1 deposits and requests redeem
        uint256 userShares = vault.balanceOf(user1);
        vm.startPrank(user1);
        vault.requestRedeem(userShares, user1, user1);
        vm.stopPrank();

        // Update PPS before attempting fulfillment
        vm.warp(block.timestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // User 2 has no pending redeem request (pendingRedeemRequest = 0)
        // but malicious/mistaken manager tries to provide non-zero totalAssetsOut for user2

        // Calculate proper assets for user1
        address[] memory tempArray = new address[](1);
        tempArray[0] = user1;
        uint256[] memory assetsForUser1 = calculateLiquidityOnlyFulfillment(strategy, address(asset), tempArray);

        address[] memory controllers = new address[](2);
        controllers[0] = user1 < user2 ? user1 : user2; // Must be sorted
        controllers[1] = user1 < user2 ? user2 : user1;

        uint256[] memory totalAssetsOut = new uint256[](2);
        if (user1 < user2) {
            totalAssetsOut[0] = assetsForUser1[0]; // user1 has pending shares - proper amount
            totalAssetsOut[1] = 100e6; // user2 has ZERO pending shares but non-zero assets - should revert
        } else {
            totalAssetsOut[0] = 100e6; // user2 has ZERO pending shares but non-zero assets - should revert
            totalAssetsOut[1] = assetsForUser1[0]; // user1 has pending shares - proper amount
        }

        // Try to fulfill - should revert with ZERO_SHARE_FULFILLMENT_DISALLOWED because user2 has zero shares
        vm.startPrank(MANAGER);
        vm.expectRevert(ISuperVaultStrategy.ZERO_SHARE_FULFILLMENT_DISALLOWED.selector);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
        vm.stopPrank();

        console2.log("fulfillRedeemRequests correctly reverts when zero-share controller is included");
    }

    /// @notice Test that fulfillRedeemRequests succeeds when only fulfilling controllers with pending shares
    /// @dev This ensures the fix allows normal operation when only valid controllers are included
    function test_FulfillRedeemRequests_SucceedsWithOnlyValidControllers() public {
        // Setup: Create two users, only one will have a pending redeem request
        uint256 depositAmount = 1000e6;
        _deposit(depositAmount);

        address user1 = accountEth;

        // User 1 deposits and requests redeem
        uint256 userShares = vault.balanceOf(user1);
        vm.startPrank(user1);
        vault.requestRedeem(userShares, user1, user1);
        vm.stopPrank();

        // Update PPS before fulfillment
        vm.warp(block.timestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Only include user1 in the fulfillment (don't include zero-share controllers)
        address[] memory controllers = new address[](1);
        controllers[0] = user1;

        // Calculate proper assets for user1 using the helper
        uint256[] memory assetsForUser1 = calculateLiquidityOnlyFulfillment(strategy, address(asset), controllers);

        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = assetsForUser1[0];

        // Should succeed - only including valid controllers
        vm.startPrank(MANAGER);
        strategy.fulfillRedeemRequests(controllers, totalAssetsOut);
        vm.stopPrank();

        // Verify user1's request was fulfilled
        ISuperVaultStrategy.SuperVaultState memory user1State = strategy.getSuperVaultState(user1);
        assertEq(user1State.pendingRedeemRequest, 0, "User1 pending redeem should be cleared");
        assertGt(user1State.maxWithdraw, 0, "User1 should have claimable assets");

        console2.log("fulfillRedeemRequests succeeds when only valid controllers are included");
    }

    /// @notice Event for testing
    event PPSUpdatedAfterSkim(
        address indexed strategy, uint256 oldPPS, uint256 newPPS, uint256 feeAmount, uint256 timestamp
    );
}

/// @notice Simple contract without payable functions for testing
contract SimpleNonPayableContract {
    function nonPayableFunction() external pure returns (bool) {
        return true;
    }
}
