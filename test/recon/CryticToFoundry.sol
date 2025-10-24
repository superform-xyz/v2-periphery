// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {MockERC20} from "@recon/MockERC20.sol";
import {MockERC4626Tester} from "test/recon/mocks/MockERC4626Tester.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Deposit4626VaultHook} from "lib/v2-core/src/hooks/vaults/4626/Deposit4626VaultHook.sol";
import {ApproveAndDeposit4626VaultHook} from "lib/v2-core/src/hooks/vaults/4626/ApproveAndDeposit4626VaultHook.sol";
import {Redeem4626VaultHook} from "lib/v2-core/src/hooks/vaults/4626/Redeem4626VaultHook.sol";
import {ISuperGovernor, FeeType} from "src/interfaces/ISuperGovernor.sol";

import {IECDSAPPSOracle} from "src/interfaces/oracles/IECDSAPPSOracle.sol";
import {ISuperVaultStrategy} from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import {ISuperVaultAggregator} from "src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import {YieldSourceType} from "test/recon/managers/YieldManager.sol";

import {MerkleTestHelper} from "./helpers/MerkleTestHelper.sol";
import {TargetFunctions} from "./TargetFunctions.sol";
import {MockERC4626Tester} from "./mocks/MockERC4626Tester.sol";
import {YieldSourceType} from "./managers/YieldManager.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
    }

    /// Reproducers

    /// Triaged

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_13 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_comparePreviewMintAndConvertToAssets_13() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(
            0,
            10000,
            0x00000000000000000000000000000000DeaDBeef
        );

        vm.warp(block.timestamp + 237093);

        vm.roll(block.number + 1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 367768);
        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_1 -vvv
    // NOTE: same as above, see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_previewEquivalenceFromAssets_1() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(
            0,
            10000,
            0x00000000000000000000000000000000DeaDBeef
        );

        vm.warp(block.timestamp + 605012);

        vm.roll(block.number + 1);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_previewEquivalenceFromAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromShares_1 -vvv
    // NOTE: optimization tests in optimize_previewMintSharesGreater and optimize_previewDepositSharesGreater
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/55
    function test_property_previewEquivalenceFromShares_1() public {
        vm.warp(block.timestamp + 5);

        vm.roll(block.number + 1);

        ECDSAPPSOracle_updatePPS_clamped(1);

        console2.log("precision: ", superVault.PRECISION());
        property_previewEquivalenceFromShares(1);
    }

    // forge test --match-test test_doomsday_mintRedeemSymmetrical_5 -vvv
    // NOTE: see issue: https://github.com/Recon-Fuzz/superform-review/issues/61
    function test_doomsday_mintRedeemSymmetrical_5() public {
        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1, 0x0000000000000000000000000000000000000000);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 5);
        ECDSAPPSOracle_updatePPS_clamped(
            45875423970713493951589436881765514280565129916122376120788407117094766
        );

        yieldSource_simulateGain(157404);

        doomsday_mintRedeemSymmetrical(2);
    }

    // forge test --match-test test_property_accumulatorSharesDecreaseOnFulfill_exact_6 -vvv
    // NOTE: see issue: https://github.com/Recon-Fuzz/superform-review/issues/62
    function test_property_accumulatorSharesDecreaseOnFulfill_exact_6() public {
        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(4);

        superVault_requestRedeem_clamped(2);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);

        property_accumulatorSharesDecreaseOnFulfill_exact();
    }

    // forge test --match-test test_doomsday_maxWithdrawResetsAfterFullWithdrawal_17 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/66
    function test_doomsday_maxWithdrawResetsAfterFullWithdrawal_17() public {
        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(3);

        superVault_requestRedeem_clamped(1);

        vm.warp(block.timestamp + 5);

        vm.roll(block.number + 1);

        ECDSAPPSOracle_updatePPS_clamped(
            700960855099362077226925743595804258294593977845093495232344554
        );

        yieldSource_simulateGain(973782);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);

        superVault_requestRedeem_clamped(1);

        doomsday_maxWithdrawResetsAfterFullWithdrawal(988620);
    }

    // forge test --match-test test_property_sumOfClaimable_5 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/67
    function test_property_sumOfClaimable_5() public {
        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(3);

        superVault_requestRedeem_clamped(1);

        vm.warp(block.timestamp + 5);

        vm.roll(block.number + 1);

        ECDSAPPSOracle_updatePPS_clamped(
            700960855099362077226925743595804258294593977845093495232344554
        );

        yieldSource_simulateGain(973782);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);

        superVault_requestRedeem_clamped(1);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);

        property_sumOfClaimable();
    }

    // forge test --match-test test_property_assetBacking_10 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/68
    function test_property_assetBacking_10() public {
        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(4);

        superVault_deposit(4);

        superVault_requestRedeem_clamped(5);

        vm.warp(block.timestamp + 5);

        vm.roll(block.number + 1);

        ECDSAPPSOracle_updatePPS_clamped(
            115792089237316195423570985008687907853269984665640564039457584007913129639931
        );

        yieldSource_simulateGain(100000003);

        superVaultStrategy_fulfillRedeemRequests_clamped(4);

        superVault_withdraw(87234118);

        int256 difference = optimize_assetBackingDifference();
        console2.log("difference: ", difference);

        // have 2 unbacked shares
        // console2.log("totalSupply: ", superVault.totalSupply());
        // property_assetBacking();
    }

    // forge test --match-test test_crytic_erc7540_4_redeem_1 -vvv
    // see issue here: https://github.com/Recon-Fuzz/superform-review/issues/76
    // NOTE: incorrect return value in maxRedeem causes the property to break but fundamentally is an issue with the share calculation in maxRedeem because user doesn't end up redeeming more than their max available
    function test_crytic_erc7540_4_redeem_1() public {
        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVaultStrategy_manageYieldSource_clamped(0);

        superVault_deposit(3);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 5);
        superVault_requestRedeem_clamped(2);

        console2.log(
            "PPS before: %e",
            superVaultAggregator.getPPS(address(superVaultStrategy))
        );
        ECDSAPPSOracle_updatePPS_clamped(950051690458586526);
        console2.log(
            "PPS after: %e",
            superVaultAggregator.getPPS(address(superVaultStrategy))
        );

        console2.log(
            "avg withdraw price before fulfill: %e",
            superVaultStrategy.getAverageWithdrawPrice(_getActor())
        );
        superVaultStrategy_fulfillRedeemRequests_clamped(2);

        console2.log(
            "avg withdraw price after fulfill: %e",
            superVaultStrategy.getAverageWithdrawPrice(_getActor())
        );
        crytic_erc7540_4_redeem(1);
    }

    /// To Triage

    /// Gotchas

    // forge test --match-test test_property_naivePPSDoesntChangeOnDepositOrMint_2 -vvv
    // NOTE: naive PPS isn't used anywhere but useful to know that donations alter naive PPS
    // function test_property_naivePPSDoesntChangeOnDepositOrMint_2() public {
    //     yieldSource_mint(1, 0x0000000000000000000000000000000000000000);

    //     // crytic_erc7540_7_deposit(2);

    //     superVault_mint(1);

    //     property_naivePPSDoesntChangeOnDepositOrMint();
    // }

    // NOTE: naive PPS isn't used anywhere but useful to know
    // NOTE: shares are burned on fulfillment but assets only get transferred on withdraw/redeem so implied PPS changes after assets get transferred to user
    // function test_property_naivePPSDoesntChangeOnRedeemOrWithdraw() public {
    //     superVault_deposit(4);
    //     superVault_requestRedeem_clamped(2);
    //     superVaultStrategy_manageYieldSource_clamped(0);

    //     uint256[] memory hookTypeInts = new uint256[](1);
    //     hookTypeInts[
    //         0
    //     ] = 3366039565052519506129160632812429979925236647654304654821762322802056013872;
    //     uint256[] memory amountsToInvest = new uint256[](1);
    //     amountsToInvest[0] = 2;
    //     bool[] memory usePrevHookAmounts = new bool[](1);
    //     usePrevHookAmounts[0] = false;
    //     superVaultStrategy_executeHooks_clamped(
    //         hookTypeInts,
    //         amountsToInvest,
    //         usePrevHookAmounts
    //     );
    //     superVaultStrategy_fulfillRedeemRequests_clamped(2);
    //     superVault_withdraw_clamped(1);
    //     property_naivePPSDoesntChangeOnRedeemOrWithdraw();
    // }

    // forge test --match-test test_property_previewEquivalenceFromAssets_ -vvv
    function test_property_previewEquivalenceFromAssets_() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(
            0,
            10000,
            0x00000000000000000000000000000000DeaDBeef
        );

        vm.warp(block.timestamp + 577107);

        vm.roll(block.number + 1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 27732);
        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_previewEquivalenceFromAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromShares_ -vvv
    function test_property_previewEquivalenceFromShares_() public {
        vm.warp(block.timestamp + 5);

        vm.roll(block.number + 1);

        ECDSAPPSOracle_updatePPS_clamped(100000); /// @audit Something dangerous tied to how prices work!?

        property_previewEquivalenceFromShares(1);
    }

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_ -vvv
    function test_property_comparePreviewMintAndConvertToAssets_() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(
            0,
            10000,
            0x00000000000000000000000000000000DeaDBeef
        );

        vm.warp(block.timestamp + 604912);

        vm.roll(block.number + 1);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);
    }

    /// @dev Test: Multi-actor deposit, withdrawal request, loss simulation, and distribution validation
    function test_multiActorDepositWithdrawLossDistribution() public {
        console2.log(
            "Assets in Strategy B4",
            MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy))
        );
        console2.log(
            "Shares in vault B4",
            MockERC20(_getYieldSource()).balanceOf(address(superVaultStrategy))
        );
        console2.log(
            "Max Redeem B4",
            MockERC4626Tester(_getYieldSource()).maxRedeem(
                address(superVaultStrategy)
            )
        );

        // Deposit
        superVault_deposit(1000e18);
        switchActor(1);
        superVault_deposit(1000e18);

        switchActor(0); // Back to 0

        // Add yield source
        superVaultStrategy_manageYieldSource_clamped(0);

        // Deposit into it
        uint256[] memory hookTypeInts = new uint256[](1);
        hookTypeInts[0] = 0; // ApproveAndDeposit4626

        uint256[] memory amountsToInvest = new uint256[](1);
        amountsToInvest[0] = MockERC20(superVault.asset()).balanceOf(
            address(superVaultStrategy)
        );

        bool[] memory usePrevAmounts = new bool[](1);
        usePrevAmounts[0] = false;

        superVaultStrategy_executeHooks_clamped(
            hookTypeInts,
            amountsToInvest,
            usePrevAmounts
        );

        console2.log(
            "Assets in Strategy",
            MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy))
        );
        console2.log(
            "Shares in vault",
            MockERC20(_getYieldSource()).balanceOf(address(superVaultStrategy))
        );
        console2.log(
            "Max Redeem",
            MockERC4626Tester(_getYieldSource()).maxRedeem(
                address(superVaultStrategy)
            )
        );

        // // Set loss on withdraw for ERC4626
        MockERC4626Tester(_getYieldSource()).setLossOnWithdraw(1000);

        // Request all redemptions
        superVault_requestRedeem_clamped(superVault.balanceOf(_getActor()));
        switchActor(1);
        superVault_requestRedeem_clamped(superVault.balanceOf(_getActor()));

        switchActor(0);
        superVaultStrategy_fulfillRedeemRequests_clamped(
            superVaultStrategy.pendingRedeemRequest(_getActor())
        );
        console2.log("pendingRedeemRequest", "0");
        switchActor(1);
        superVaultStrategy_fulfillRedeemRequests_clamped(
            superVaultStrategy.pendingRedeemRequest(_getActor())
        );
        console2.log("pendingRedeemRequest", "1");
        switchActor(0);

        // Compute the insolvency
        uint256 maxWithdrawAcc;
        for (uint256 i; i < _getActors().length; i++) {
            maxWithdrawAcc += superVault.maxWithdraw(_getActors()[i]);
        }

        console2.log("Max Withdraw Acc", maxWithdrawAcc);
        console2.log(
            "Strategy Balance Solvency",
            MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy))
        );

        // Show the revert
        console2.log("Max Withdraw", superVault.maxWithdraw(_getActor()));
        superVault_withdraw(superVault.maxWithdraw(_getActor()));
        switchActor(1);
        console2.log("Max Withdraw", superVault.maxWithdraw(_getActor()));
        superVault_withdraw(superVault.maxWithdraw(_getActor()));

        // Check if solvent / insolvent due to cached PPS
    }
}
