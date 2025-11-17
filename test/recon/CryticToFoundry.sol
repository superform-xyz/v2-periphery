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
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_comparePreviewMintAndConvertToAssets_13() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 1000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_1 -vvv
    // NOTE: same as above, see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_previewEquivalenceFromAssets_1() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 1000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 605_012);

        vm.roll(block.number + 1);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_previewEquivalenceFromAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromShares_1 -vvv
    // NOTE: optimization tests in optimize_previewMintSharesGreater and optimize_previewDepositSharesGreater
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/55
    function test_property_previewEquivalenceFromShares_1() public {
        vm.warp(block.timestamp + 5);
        property_previewEquivalenceFromShares(1e18);
    }

    // forge test --match-test test_doomsday_maxWithdrawResetsAfterFullWithdrawal_17 -vvv
    function test_doomsday_maxWithdrawResetsAfterFullWithdrawal_17() public {
        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);
        uint256 depositAmount = 3000e6;

        superVaultStrategy_manageYieldSource_clamped(0);
        address yieldSource = _getYieldSource();

        uint256 sharesUnderlying = MockERC4626Tester(yieldSource).previewDeposit(depositAmount);

        yieldSource_mint(sharesUnderlying, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        doomsday_maxWithdrawResetsAfterFullWithdrawal(depositAmount);
    }

    // forge test --match-test test_property_sumOfClaimable_5 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/67
    function test_property_sumOfClaimable_5() public {
        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);
        superVault_deposit(3);

        superVault_requestRedeem_clamped(1);

        property_sumOfClaimable();
    }

    // forge test --match-test test_property_assetBacking_10 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/68
    function test_property_assetBacking_10() public {
        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);
        superVault_deposit(40_000);
        uint256 shares = superVault.balanceOf(_getActor());

        uint256 sharesUnderlying = MockERC4626Tester(_getYieldSource()).previewDeposit(40_000);

        yieldSource_mint(sharesUnderlying, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_requestRedeem(shares);

        yieldSource_simulateGain(100_000_003);

        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);

        superVaultStrategy_fulfillRedeemRequests_clamped(shares);

        uint256 maxWithdraw = superVault.maxWithdraw(_getActor());

        superVault_withdraw(maxWithdraw);

        int256 difference = optimize_assetBackingDifference();
        console2.log("difference: ", difference);

        // have 2 unbacked shares
        console2.log("totalSupply: ", superVault.totalSupply());
        property_assetBacking();
    }

    // forge test --match-test test_crytic_erc7540_4_redeem_1 -vvv
    function test_crytic_erc7540_4_redeem_1() public {
        superVaultStrategy_manageYieldSource_clamped(0);

        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);

        superVault_deposit(3000e6);

        uint256 shares = superVault.balanceOf(_getActor());

        yieldSource_mint(shares, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        vm.warp(block.timestamp + 1 days);
        superVault_requestRedeem_clamped(shares);

        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);

        console2.log("avg withdraw price before fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));

        yieldSource_simulateGain(1_121_895);

        address[] memory controllers = new address[](1);
        controllers[0] = _getActor();

        superVaultStrategy_fulfillRedeemRequests_clamped(shares);

        console2.log("avg withdraw price after fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));

        uint256 maxDep = superVault.maxRedeem(_getActor());
        vm.expectRevert();
        superVault.redeem(maxDep + 1, _getActor(), _getActor());

        doomsday_redemptionsNeverReverts(shares);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_ -vvv
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
        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);

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
        yieldSource_mint(sharesUnderlying, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

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

        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);
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
        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);
        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(2);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 5);
        superVault_requestRedeem_clamped(1);

        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);

        yieldSource_simulateGain(1_121_895);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);
    }

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_1 -vvv
    function test_property_comparePreviewMintAndConvertToAssets_1() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 1000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1e18);
    }

    function test_comparePreviewMintAndConvertToAssets_4() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 9999, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 2 weeks);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1e18);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_2 -vvv
    function test_property_previewEquivalenceFromAssets_2() public {
        property_previewEquivalenceFromAssets(1e18);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_3 -vvv
    function test_property_previewEquivalenceFromAssets_3() public {
        property_previewEquivalenceFromAssets(1);
    }

    // forge test --match-test test_superVault_cancelRedeem_3 -vvv
    function test_superVault_cancelRedeem_3() public {
        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);
        superVault_deposit(40_000);
        uint256 shares = superVault.balanceOf(_getActor());
        vm.warp(block.timestamp + 1 days);

        vm.prank(_getActor());
        superVault_requestRedeem(shares);
        superVault_cancelRedeem();
    }

    // forge test --match-test test_doomsday_mintRedeemSymmetrical_6 -vvv
    function test_doomsday_mintRedeemSymmetrical_6() public {
        ECDSAPPSOracle_updatePPS_clamped(1_000_000_000_000_000_000);
        doomsday_mintRedeemSymmetrical(40_000);
    }
}
