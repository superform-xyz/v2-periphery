// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { FoundryAsserts } from "@chimera/FoundryAsserts.sol";
import { MockERC20 } from "@recon/MockERC20.sol";
import { MockERC4626Tester } from "test/recon/mocks/MockERC4626Tester.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Deposit4626VaultHook } from "lib/v2-core/src/hooks/vaults/4626/Deposit4626VaultHook.sol";
import { ApproveAndDeposit4626VaultHook } from "lib/v2-core/src/hooks/vaults/4626/ApproveAndDeposit4626VaultHook.sol";
import { Redeem4626VaultHook } from "lib/v2-core/src/hooks/vaults/4626/Redeem4626VaultHook.sol";
import { ISuperGovernor, FeeType } from "src/interfaces/ISuperGovernor.sol";

import { IECDSAPPSOracle } from "src/interfaces/oracles/IECDSAPPSOracle.sol";
import { ISuperVaultStrategy } from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultAggregator } from "src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { YieldSourceType } from "test/recon/managers/YieldManager.sol";

import { MerkleTestHelper } from "./helpers/MerkleTestHelper.sol";
import { TargetFunctions } from "./TargetFunctions.sol";
import { MockERC4626Tester } from "./mocks/MockERC4626Tester.sol";
import { YieldSourceType } from "./managers/YieldManager.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
        merkleHelper = new MerkleTestHelper();
    }

    /// Reproducers

    /// Triaged

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_13 -vvv
    /// @dev Test: property - previewMint and convertToAssets equivalence
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_comparePreviewMintAndConvertToAssets_13() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 1000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_1 -vvv
    /// @dev Test: property - previewMint and previewDeposit equivalence (from assets)
    /// @dev NOTE: same as above, see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_previewEquivalenceFromAssets_1() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 1000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 605_012);

        vm.roll(block.number + 1);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_previewEquivalenceFromAssets(1);
    }

    /// @dev Test: property - previewDeposit and convertToShares equivalence
    function test_property_comparePreviewDepositAndConvertToShares() public {
        property_comparePreviewDepositAndConvertToShares(1e18);
    }

    /// @dev Test: property - transfer only updates shares
    function test_property_transferOnlyUpdatesShares() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        vm.prank(_getActor());
        uint256 shares = superVault.mint(1e18, _getActor());
        superVault_transfer(1, shares);
    }

    /// @dev Test: property - transferFrom only updates shares
    function test_property_transferFromOnlyUpdatesShares() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        switchActor(0);
        vm.prank(_getActor());
        uint256 shares = superVault.mint(1e18, _getActor());
        superVault_transferFrom(0, 1, shares);
    }

    // forge test --match-test test_property_previewEquivalenceFromShares_1 -vvv
    /// @dev Test: property - previewMint and previewDeposit equivalence (from shares)
    /// @dev NOTE: optimization tests in optimize_previewMintSharesGreater and optimize_previewDepositSharesGreater
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/55
    function test_property_previewEquivalenceFromShares_1() public {
        vm.warp(block.timestamp + 5);
        property_previewEquivalenceFromShares(1e18);
    }

    // forge test --match-test test_doomsday_maxWithdrawResetsAfterFullWithdrawal_17 -vvv
    /// @dev Test: maxWithdraw resets after full withdrawal (doomsday)
    function test_doomsday_maxWithdrawResetsAfterFullWithdrawal_17() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        uint256 depositAmount = 3000e6;

        superVaultStrategy_manageYieldSource_clamped(0);
        address yieldSource = _getYieldSource();

        uint256 sharesUnderlying = MockERC4626Tester(yieldSource).previewDeposit(depositAmount);

        yieldSource_mint(sharesUnderlying, address(superVaultStrategy));

        doomsday_maxWithdrawResetsAfterFullWithdrawal(depositAmount);
    }

    // forge test --match-test test_property_sumOfClaimable_5 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/67
    /// @dev Test: property - sum of all claimable is <= balance available
    function test_property_sumOfClaimable_5() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVault_deposit(3);

        superVault_requestRedeem_clamped(1);

        property_sumOfClaimable();
    }

    // forge test --match-test test_property_assetBacking_10 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/68
    /// @dev Test: property - if totalSupply() > 0, then totalAssets() > 0
    function test_property_assetBacking_10() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVault_deposit(40_000);
        uint256 shares = superVault.balanceOf(_getActor());

        uint256 sharesUnderlying = MockERC4626Tester(_getYieldSource()).previewDeposit(40_000);

        yieldSource_mint(sharesUnderlying, address(superVaultStrategy));

        superVault_requestRedeem(shares);

        yieldSource_simulateGain(100_000_003);

        ECDSAPPSOracle_updatePPS_clamped(1e18);

        superVaultStrategy_fulfillRedeemRequests_clamped(shares);

        uint256 maxWithdraw = superVault.maxWithdraw(_getActor());

        superVault_withdraw(maxWithdraw);

        int256 difference = optimize_assetBackingDifference();
        console2.log("difference: ", difference);

        // have 2 unbacked shares
        console2.log("totalSupply: ", superVault.totalSupply());
        property_assetBacking();
    }

    ///@dev Test: property - averageWithdrawPrice should never decrease when new redemptions are fulfilled at a higher
    /// PPS
    function test_property_avgPPSMonotonicity_PPSIncrease() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        address asset = superVault.asset();

        // 1. Deposit
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());

        // 2. Deposit assets into yield strategy via executeHooks
        // This is needed because the user's assets are currently in the strategy contract
        // but not yet deposited into the underlying yield source
        uint256 strategyAssetBalance = MockERC20(asset).balanceOf(address(superVaultStrategy));
        if (strategyAssetBalance > 0) {
            ISuperVaultStrategy.ExecuteArgs memory depositArgs = _createExecuteDepositArgs(strategyAssetBalance);

            superVaultStrategy.executeHooks(depositArgs);
        }

        // 3. Request Redemption
        uint256 sharesActor = superVault.balanceOf(_getActor());

        vm.prank(_getActor());
        superVault.requestRedeem(sharesActor, _getActor(), _getActor());

        // 5. Update PPS
        ECDSAPPSOracle_updatePPS_clamped(1_700_000_000_000_000_000);

        // 6. Fulfill Redemption request
        superVaultStrategy_fulfillRedeemRequests_clamped(sharesActor);
        property_avgPPSMonotonicity();
    }

    ///@dev Test: property - averageWithdrawPrice monotonicity when PPS decreases
    function test_property_avgPPSMonotonicity_PPSDecrease() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        address asset = superVault.asset();

        // 1. Deposit
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());

        // 2. Deposit assets into yield strategy via executeHooks
        // This is needed because the user's assets are currently in the strategy contract
        // but not yet deposited into the underlying yield source
        uint256 strategyAssetBalance = MockERC20(asset).balanceOf(address(superVaultStrategy));
        if (strategyAssetBalance > 0) {
            ISuperVaultStrategy.ExecuteArgs memory depositArgs = _createExecuteDepositArgs(strategyAssetBalance);

            superVaultStrategy.executeHooks(depositArgs);
        }

        // 3. Request Redemption
        uint256 sharesActor = superVault.balanceOf(_getActor());

        vm.prank(_getActor());
        superVault.requestRedeem(sharesActor, _getActor(), _getActor());

        // 5. Update PPS
        ECDSAPPSOracle_updatePPS_clamped(900_000_000_000_000_000);

        // 6. Fulfill Redemption request
        superVaultStrategy_fulfillRedeemRequests_clamped(sharesActor);
        property_avgPPSMonotonicity();
    }

    ///@dev Test: property - averageWithdrawPrice monotonicity when there are sequential redemptions at higher PPS
    /// values
    function test_property_avgPPSMonotonicity_SequentialRedemptions() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        address asset = superVault.asset();

        // 1. Deposits
        switchActor(0);
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());
        uint256 shares0 = superVault.balanceOf(_getActor());

        switchActor(1);
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());
        uint256 shares1 = superVault.balanceOf(_getActor());

        switchActor(2);
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());
        uint256 shares2 = superVault.balanceOf(_getActor());

        // 2. Deposit assets into yield strategy via executeHooks
        // This is needed because the user's assets are currently in the strategy contract
        // but not yet deposited into the underlying yield source
        uint256 strategyAssetBalance = MockERC20(asset).balanceOf(address(superVaultStrategy));
        if (strategyAssetBalance > 0) {
            ISuperVaultStrategy.ExecuteArgs memory depositArgs = _createExecuteDepositArgs(strategyAssetBalance);

            superVaultStrategy.executeHooks(depositArgs);
        }

        // 3. Request Redemption for first actor
        switchActor(0);
        vm.prank(_getActor());
        superVault.requestRedeem(shares0, _getActor(), _getActor());

        // 5. Update PPS after first actor's redemption
        ECDSAPPSOracle_updatePPS_clamped(900_000_000_000_000_000);

        // 6. Request Redemption for second actor
        switchActor(1);
        vm.prank(_getActor());
        superVault.requestRedeem(shares1, _getActor(), _getActor());

        // 7. Update PPS after second actor's redemption
        ECDSAPPSOracle_updatePPS_clamped(1_100_000_000_000_000_000);

        // 8. Request Redemption for third actor
        switchActor(2);
        vm.prank(_getActor());
        superVault.requestRedeem(shares2, _getActor(), _getActor());

        // 9. Update PPS after third actor's redemption
        ECDSAPPSOracle_updatePPS_clamped(1_990_000_000_000_000_000);

        // 10. Fulfill Redemption requests
        uint256 totalShares = shares0 + shares1 + shares2;
        address[] memory controllers = new address[](3);
        switchActor(1);
        controllers[0] = _getActor();
        switchActor(2);
        controllers[1] = _getActor();
        switchActor(0);
        controllers[2] = _getActor();

        superVaultStrategy_fulfillRedeemRequests(totalShares, controllers);

        property_avgPPSMonotonicity();
    }

    // forge test --match-test test_crytic_erc7540_4_redeem_1 -vvv
    function test_crytic_erc7540_4_redeem_1() public {
        superVaultStrategy_manageYieldSource_clamped(0);

        ECDSAPPSOracle_updatePPS_clamped(1e18);

        superVault_deposit(3000e6);

        uint256 shares = superVault.balanceOf(_getActor());

        yieldSource_mint(shares, address(superVaultStrategy));

        vm.warp(block.timestamp + 1 days);
        superVault_requestRedeem_clamped(shares);

        ECDSAPPSOracle_updatePPS_clamped(1e18);

        console2.log("avg withdraw price before fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));

        yieldSource_simulateGain(1_121_895);

        address[] memory controllers = new address[](1);
        controllers[0] = _getActor();

        superVaultStrategy_fulfillRedeemRequests_clamped(shares);

        console2.log("avg withdraw price after fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));

        uint256 maxDep = superVault.maxRedeem(_getActor());
        vm.expectRevert();
        superVault.redeem(maxDep + 1, _getActor(), _getActor());
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_ -vvv
    /// @dev Test: property - previewMint and previewDeposit equivalence
    function test_property_previewEquivalenceFromAssets_() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 1000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);
        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_previewEquivalenceFromAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromShares_ -vvv
    function test_property_previewEquivalenceFromShares_() public {
        property_previewEquivalenceFromShares(1);
    }

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_ -vvv
    function test_property_comparePreviewMintAndConvertToAssets_() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 100, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);
    }

    /// @dev Test: Multi-actor deposit, withdrawal request, loss simulation, and distribution validation
    /// @dev Test: All users can withdraw after a loss on withdrawal property
    function test_multiActorDepositWithdrawLossDistribution() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);

        // Add yield source
        superVaultStrategy_manageYieldSource_clamped(0);

        uint256 depositAmount = 1000e18;

        // Deposit
        console2.log(_getActor());
        superVault_deposit(depositAmount);
        switchActor(1);
        console2.log(_getActor());
        superVault_deposit(depositAmount);
        switchActor(0); // Back to 0

        uint256 shares0 = superVault.balanceOf(_getActor());
        console2.log("Actor 0 Shares", shares0);
        switchActor(1);
        uint256 shares1 = superVault.balanceOf(_getActor());
        console2.log("Actor 1 Shares", shares1);
        uint256 totalShares = shares0 + shares1;

        uint256 sharesUnderlying = MockERC4626Tester(_getYieldSource()).previewDeposit(depositAmount * 2);
        console2.log("Strategy Shares in underlying vault", sharesUnderlying);
        yieldSource_mint(sharesUnderlying, address(superVaultStrategy));

        // // Set loss on withdraw for ERC4626
        uint256 lossOnWithdraw = 1000;
        console2.log("Loss on Withdraw", lossOnWithdraw);
        MockERC4626Tester(_getYieldSource()).setLossOnWithdraw(lossOnWithdraw);

        // Request all redemptions
        switchActor(0); // Back to 0
        superVaultStrategy.setRedeemSlippage(9999);
        console2.log("Slippage: ", superVaultStrategy.getSuperVaultState(_getActor()).redeemSlippageBps);
        superVault_requestRedeem_clamped(shares0);

        switchActor(1);
        vm.prank(_getActor());
        superVaultStrategy.setRedeemSlippage(9999);
        console2.log("Slippage: ", superVaultStrategy.getSuperVaultState(_getActor()).redeemSlippageBps);
        superVault_requestRedeem_clamped(shares1);

        ECDSAPPSOracle_updatePPS_clamped(1e18);
        console2.log("PPS: 1e18");

        address[] memory controllers = new address[](2);
        controllers[0] = _getActor();
        switchActor(0);
        controllers[1] = _getActor();

        assert(controllers[0] != controllers[1]);

        superVaultStrategy_fulfillRedeemRequests_WithLoss(lossOnWithdraw, totalShares, controllers);

        // Compute the insolvency
        uint256 maxWithdrawAcc;
        for (uint256 i; i < _getActors().length; i++) {
            maxWithdrawAcc += superVault.maxWithdraw(_getActors()[i]);
        }

        // Withdraw both actors with maxWithdraw
        doomsday_allUsersCanWithdraw();
    }

    // forge test --match-test test_superVaultStrategy_fulfillRedeemRequests_clamped_0 -vvv
    function test_superVaultStrategy_fulfillRedeemRequests_clamped_0() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1, address(superVaultStrategy));

        superVault_deposit(2);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 5);
        superVault_requestRedeem_clamped(1);

        ECDSAPPSOracle_updatePPS_clamped(1e18);

        yieldSource_simulateGain(1_121_895);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);
    }

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_1 -vvv
    /// @dev Test: property - previewMint and convertToAssets equivalence
    function test_property_comparePreviewMintAndConvertToAssets_1() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 1000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1e18);
    }

    /// @dev Test: property - previewMint and convertToAssets equivalence
    function test_comparePreviewMintAndConvertToAssets_4() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 9999, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1e18);
    }

    /// @dev Test: property - previewDeposit and deposit equivalence
    function test_doomsday_previewDepositEquivalence() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        doomsday_previewDepositEquivalence(assetsToDeposit);
    }

    /// @dev Test: property - previewMint and mint equivalence
    function test_doomsday_previewMintEquivalence() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 sharesToMint = 1000;

        doomsday_previewMintEquivalence(sharesToMint);
    }

    /// @dev Test: property - balanceOf(escrow) >= SUM(controllers.pendingRedeemRequest)
    function test_property_escrowBalance() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        superVault_deposit(assetsToDeposit);
        uint256 shares = superVault.balanceOf(_getActor());

        uint256 underlyingShares = MockERC4626Tester(_getYieldSource()).previewDeposit(assetsToDeposit);

        yieldSource_mint(underlyingShares, address(superVaultStrategy));

        superVault_requestRedeem(shares);

        ECDSAPPSOracle_updatePPS_clamped(1e18);

        property_escrowBalance();
    }

    /// @dev Test: property - SuperVault::totalSupply == SUM(user balances) + balanceOf(escrow)  (solvency)
    function test_property_shareSolvency() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        switchActor(0);
        superVault_deposit(assetsToDeposit);
        uint256 shares = superVault.balanceOf(_getActor());

        switchActor(1);
        superVault_deposit(assetsToDeposit);

        uint256 underlyingShares = MockERC4626Tester(_getYieldSource()).previewDeposit(assetsToDeposit);

        yieldSource_mint(underlyingShares, address(superVaultStrategy));

        switchActor(0);
        superVault_requestRedeem(shares);

        ECDSAPPSOracle_updatePPS_clamped(1e18);

        property_shareSolvency();
    }

    /// @dev Test: property - SUM(shares) * PPS == totalAssets
    function test_property_totalAssets() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        switchActor(0);
        superVault_deposit(assetsToDeposit);

        switchActor(1);
        superVault_deposit(assetsToDeposit);

        property_totalAssets();
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_2 -vvv
    /// @dev Test: property - previewMint and previewDeposit equivalence
    function test_property_previewEquivalenceFromAssets_2() public {
        property_previewEquivalenceFromAssets(1e18);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_3 -vvv
    /// @dev Test: property - previewMint and previewDeposit equivalence
    function test_property_previewEquivalenceFromAssets_3() public {
        property_previewEquivalenceFromAssets(1);
    }

    /// @dev Test: property - maxRedeem and maxWithdraw should always be equivalent
    function test_property_maxRedeemMaxWithdrawSymmetry() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        address asset = superVault.asset();

        // 1. Deposit
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());

        // 2. Deposit assets into yield strategy via executeHooks
        // This is needed because the user's assets are currently in the strategy contract
        // but not yet deposited into the underlying yield source
        uint256 strategyAssetBalance = MockERC20(asset).balanceOf(address(superVaultStrategy));
        if (strategyAssetBalance > 0) {
            ISuperVaultStrategy.ExecuteArgs memory depositArgs = _createExecuteDepositArgs(strategyAssetBalance);

            superVaultStrategy.executeHooks(depositArgs);
        }

        // 3. Request Redemption
        superVault.balanceOf(_getActor());
        // get shares of strategy in the deposited yield source
        uint256 shares = _getSuperVaultStrategyShares();

        vm.prank(_getActor());
        superVault.requestRedeem(shares, _getActor(), _getActor());

        // 4. Fulfill Redemption from yield strategy
        (ISuperVaultStrategy.ExecuteArgs memory executeArgs, address[] memory controllers) =
            _createExecuteRedeemFromArgs(shares);

        // 4. Execute the redeem from the yield strategy to get assets back
        superVaultStrategy.executeHooks(executeArgs);

        uint256[] memory totalAssetsOut = calculateLiquidityOnlyFulfillment(superVaultStrategy, asset, controllers);

        // called by admin address(this)
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy.fulfillRedeemRequests(controllers, totalAssetsOut);

        property_maxRedeemMaxWithdrawSymmetry();
    }

    /// @dev Test: property - fulfillRedeemRequests should only burn the requested amount of shares
    function test_property_fulfillOnlyBurnsRequestedAmount() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        address asset = superVault.asset();

        // 1. Deposit
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());

        // 2. Deposit assets into yield strategy via executeHooks
        // This is needed because the user's assets are currently in the strategy contract
        // but not yet deposited into the underlying yield source
        uint256 strategyAssetBalance = MockERC20(asset).balanceOf(address(superVaultStrategy));
        if (strategyAssetBalance > 0) {
            ISuperVaultStrategy.ExecuteArgs memory depositArgs = _createExecuteDepositArgs(strategyAssetBalance);

            superVaultStrategy.executeHooks(depositArgs);
        }

        // 3. Request Redemption
        superVault.balanceOf(_getActor());
        // get shares of strategy in the deposited yield source
        uint256 shares = _getSuperVaultStrategyShares();

        vm.prank(_getActor());
        superVault.requestRedeem(shares, _getActor(), _getActor());

        // 4. Fulfill Redemption from yield strategy
        (ISuperVaultStrategy.ExecuteArgs memory executeArgs,) = _createExecuteRedeemFromArgs(shares);

        // 4. Execute the redeem from the yield strategy to get assets back
        superVaultStrategy.executeHooks(executeArgs);

        // called by admin address(this)
        ECDSAPPSOracle_updatePPS_clamped(1e18);

        address[] memory controllers = new address[](1);
        controllers[0] = _getActor();

        uint256[] memory totalAssetsOut = calculateLiquidityOnlyFulfillment(superVaultStrategy, asset, controllers);

        superVaultStrategy.fulfillRedeemRequests(controllers, totalAssetsOut);

        property_fulfillOnlyBurnsRequestedAmount();
    }

    // forge test --match-test test_superVault_cancelRedeem_3 -vvv
    /// @dev Test: cancelRedeem should never alter the supply of SuperVault tokens
    /// @dev Test: pendingRedeemRequest should be 0 after a user calls cancelRedeem
    /// @dev Test: averageRequestPPS should be 0 after a user calls cancelRedeem
    /// @dev Test: user shouldn't receive more than convertToAssets(pendingRedeemRequest) after cancelRedeem
    function test_superVault_cancelRedeem_3() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVault_deposit(40_000);
        uint256 shares = superVault.balanceOf(_getActor());
        vm.warp(block.timestamp + 1 days);

        vm.prank(_getActor());
        superVault_requestRedeem(shares);
        superVault_cancelRedeem();
    }

    /// @dev Test: cancelRedeem should never alter the supply of SuperVault tokens
    function test_property_cancelDoesntChangeTotalSupply() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVault_deposit(40_000);
        uint256 shares = superVault.balanceOf(_getActor());
        vm.warp(block.timestamp + 1 days);

        vm.prank(_getActor());
        superVault_requestRedeem(shares);
        property_cancelDoesntChangeTotalSupply();
    }

    /// @dev Test: property total shares don't decrease on redemption request
    function test_property_totalSharesDontDecreaseOnRedemptionRequest() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVault_deposit(40_000);
        uint256 shares = superVault.balanceOf(_getActor());
        vm.warp(block.timestamp + 1 days);

        vm.prank(_getActor());
        superVault_requestRedeem(shares);
        property_totalSharesDontDecreaseOnRedemptionRequest();
    }

    // forge test --match-test test_doomsday_mintRedeemSymmetrical_6 -vvv
    /// @dev Test: mint/redeem doesn't cause loss to user (doomsday)
    function test_doomsday_mintRedeemSymmetrical_6() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        doomsday_mintRedeemSymmetrical(40_000);
    }

    /// @dev Test: property - deposit/withdraw doesn't cause loss to user (doomsday)
    function test_doomsday_depositWithdrawSymmetrical() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        doomsday_depositWithdrawSymmetrical(40_000);
    }

    /// @dev Test: Primary manager always changeable (doomsday)
    function test_doomsday_primaryManagerAlwaysChangeable() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        doomsday_primaryManagerAlwaysChangeable();
    }

    // forge test --match-test test_doomsday_cannotClaimMoreThanRequested -vvv
    /// @dev Test: cannot claim more than requested (doomsday)
    function test_doomsday_cannotClaimMoreThanRequested() public {
        ECDSAPPSOracle_updatePPS_clamped(1e18);
        superVaultStrategy_manageYieldSource_clamped(0);
        uint256 assetsToDeposit = 1000;

        // 1. Deposit to get shares
        vm.prank(_getActor());
        superVault.deposit(assetsToDeposit, _getActor());

        uint256 shares = superVault.balanceOf(_getActor());

        uint256 underlyingShares = MockERC4626Tester(_getYieldSource()).previewDeposit(assetsToDeposit);

        yieldSource_mint(underlyingShares, address(superVaultStrategy));

        ECDSAPPSOracle_updatePPS_clamped(1e18);

        doomsday_cannotClaimMoreThanRequested(shares);
    }
}
