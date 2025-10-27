// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { FoundryAsserts } from "@chimera/FoundryAsserts.sol";
import { MockERC20 } from "@recon/MockERC20.sol";
import { MockERC4626Tester } from "test/recon/mocks/MockERC4626Tester.sol";
import { Test, console2 } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
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
    }

    /// Reproducers

    /// Triaged

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_13 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_comparePreviewMintAndConvertToAssets_13() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 10_000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 237_093);

        vm.roll(block.number + 1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 367_768);
        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromAssets_1 -vvv
    // NOTE: same as above, see issue here: https://github.com/Recon-Fuzz/superform-review/issues/49
    function test_property_previewEquivalenceFromAssets_1() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 10_000, 0x00000000000000000000000000000000DeaDBeef);

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
            45_875_423_970_713_493_951_589_436_881_765_514_280_565_129_916_122_376_120_788_407_117_094_766
        );

        yieldSource_simulateGain(157_404);

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
            700_960_855_099_362_077_226_925_743_595_804_258_294_593_977_845_093_495_232_344_554
        );

        yieldSource_simulateGain(973_782);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);

        superVault_requestRedeem_clamped(1);

        doomsday_maxWithdrawResetsAfterFullWithdrawal(988_620);
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
            700_960_855_099_362_077_226_925_743_595_804_258_294_593_977_845_093_495_232_344_554
        );

        yieldSource_simulateGain(973_782);

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
            115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_913_129_639_931
        );

        yieldSource_simulateGain(100_000_003);

        superVaultStrategy_fulfillRedeemRequests_clamped(4);

        superVault_withdraw(87_234_118);

        int256 difference = optimize_assetBackingDifference();
        console2.log("difference: ", difference);

        // have 2 unbacked shares
        // console2.log("totalSupply: ", superVault.totalSupply());
        // property_assetBacking();
    }

    // forge test --match-test test_crytic_erc7540_4_redeem_1 -vvv
    // see issue here: https://github.com/Recon-Fuzz/superform-review/issues/76
    // NOTE: incorrect return value in maxRedeem causes the property to break but fundamentally is an issue with the
    // share calculation in maxRedeem because user doesn't end up redeeming more than their max available
    function test_crytic_erc7540_4_redeem_1() public {
        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVaultStrategy_manageYieldSource_clamped(0);

        superVault_deposit(3);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 5);
        superVault_requestRedeem_clamped(2);

        console2.log("PPS before: %e", superVaultAggregator.getPPS(address(superVaultStrategy)));
        ECDSAPPSOracle_updatePPS_clamped(950_051_690_458_586_526);
        console2.log("PPS after: %e", superVaultAggregator.getPPS(address(superVaultStrategy)));

        console2.log("avg withdraw price before fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));
        superVaultStrategy_fulfillRedeemRequests_clamped(2);

        console2.log("avg withdraw price after fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));
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
    // NOTE: shares are burned on fulfillment but assets only get transferred on withdraw/redeem so implied PPS changes
    // after assets get transferred to user
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
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 10_000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 577_107);

        vm.roll(block.number + 1);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 27_732);
        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_previewEquivalenceFromAssets(1);
    }

    // forge test --match-test test_property_previewEquivalenceFromShares_ -vvv
    function test_property_previewEquivalenceFromShares_() public {
        vm.warp(block.timestamp + 5);

        vm.roll(block.number + 1);

        ECDSAPPSOracle_updatePPS_clamped(100_000);

        /// @audit Something dangerous tied to how prices work!?

        property_previewEquivalenceFromShares(1);
    }

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_ -vvv
    function test_property_comparePreviewMintAndConvertToAssets_() public {
        superVaultStrategy_proposeVaultFeeConfigUpdate(0, 10_000, 0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 604_912);

        vm.roll(block.number + 1);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);
    }

    /// @dev Test: Multi-actor deposit, withdrawal request, loss simulation, and distribution validation
    function test_multiActorDepositWithdrawLossDistribution() public {
        console2.log("Assets in Strategy B4", MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy)));
        console2.log("Shares in vault B4", MockERC20(_getYieldSource()).balanceOf(address(superVaultStrategy)));
        console2.log("Max Redeem B4", MockERC4626Tester(_getYieldSource()).maxRedeem(address(superVaultStrategy)));

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
        amountsToInvest[0] = MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        bool[] memory usePrevAmounts = new bool[](1);
        usePrevAmounts[0] = false;

        superVaultStrategy_executeHooks_clamped(hookTypeInts, amountsToInvest, usePrevAmounts);

        console2.log("Assets in Strategy", MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy)));
        console2.log("Shares in vault", MockERC20(_getYieldSource()).balanceOf(address(superVaultStrategy)));
        console2.log("Max Redeem", MockERC4626Tester(_getYieldSource()).maxRedeem(address(superVaultStrategy)));

        // // Set loss on withdraw for ERC4626
        MockERC4626Tester(_getYieldSource()).setLossOnWithdraw(1000);

        // Request all redemptions
        superVault_requestRedeem_clamped(superVault.balanceOf(_getActor()));
        switchActor(1);
        superVault_requestRedeem_clamped(superVault.balanceOf(_getActor()));

        switchActor(0);
        superVaultStrategy_fulfillRedeemRequests_clamped(superVaultStrategy.pendingRedeemRequest(_getActor()));
        console2.log("pendingRedeemRequest", "0");
        switchActor(1);
        superVaultStrategy_fulfillRedeemRequests_clamped(superVaultStrategy.pendingRedeemRequest(_getActor()));
        console2.log("pendingRedeemRequest", "1");
        switchActor(0);

        // Compute the insolvency
        uint256 maxWithdrawAcc;
        for (uint256 i; i < _getActors().length; i++) {
            maxWithdrawAcc += superVault.maxWithdraw(_getActors()[i]);
        }

        console2.log("Max Withdraw Acc", maxWithdrawAcc);
        console2.log("Strategy Balance Solvency", MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy)));

        // Show the revert
        console2.log("Max Withdraw", superVault.maxWithdraw(_getActor()));
        superVault_withdraw(superVault.maxWithdraw(_getActor()));
        switchActor(1);
        console2.log("Max Withdraw", superVault.maxWithdraw(_getActor()));
        superVault_withdraw(superVault.maxWithdraw(_getActor()));

        // Check if solvent / insolvent due to cached PPS
    }

    // forge test --match-test test_superVaultStrategy_fulfillRedeemRequests_clamped_0 -vvv 
    function test_superVaultStrategy_fulfillRedeemRequests_clamped_0() public {

        superVaultStrategy_manageYieldSource_clamped(0);

        yieldSource_mint(1,0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(2);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 5);
        superVault_requestRedeem_clamped(1);

        ECDSAPPSOracle_updatePPS_clamped(94828176912403810418829620192424272151546062289895417675768111400040900);

        yieldSource_simulateGain(1121895);

        superVaultStrategy_fulfillRedeemRequests_clamped(1);

     }

    // forge test --match-test test_property_comparePreviewMintAndConvertToAssets_1 -vvv 
    function test_property_comparePreviewMintAndConvertToAssets_1() public {

        superVaultStrategy_proposeVaultFeeConfigUpdate(0,10000,0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 605309);

        vm.roll(block.number + 1);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_comparePreviewMintAndConvertToAssets(1);

     }

    // forge test --match-test test_property_previewEquivalenceFromAssets_2 -vvv 
    function test_property_previewEquivalenceFromAssets_2() public {

        superVaultStrategy_proposeVaultFeeConfigUpdate(0,10000,0x00000000000000000000000000000000DeaDBeef);

        vm.warp(block.timestamp + 604955);

        vm.roll(block.number + 1);

        superVaultStrategy_executeVaultFeeConfigUpdate();

        property_previewEquivalenceFromAssets(1);

     }

    // forge test --match-test test_superVault_cancelRedeem_3 -vvv 
    function test_superVault_cancelRedeem_3() public {

        vm.roll(block.number + 4946);
        vm.warp(block.timestamp + 71);
        vm.prank(0x0000000000000000000000000000000000030000);

        vm.roll(block.number + 33177);
        vm.warp(block.timestamp + 56338);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultAggregator_withdrawUpkeep(773);

        vm.roll(block.number + 4993);
        vm.warp(block.timestamp + 360627);
        vm.prank(0x0000000000000000000000000000000000030000);
        doomsday_fulfillDoesntOverRedeemMultipleActors([25745827526823561024891231478258289767804686917109141879174001242360053860738, 115792089237316195423570985008687907853269984665640564039457584007913129639855, 115792089237316195423570985008687907853269984665640564039456584007913129639937],[82328900353182693953483431499541251369999704770935067864968406142454586285695, 1999999, 110805778917703835489735893837548947380928973615891727587347928841829835991991]);

        vm.roll(block.number + 11349);
        vm.warp(block.timestamp + 360623);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_maxMintZeroWhenPaused();

        vm.roll(block.number + 45819);
        vm.warp(block.timestamp + 5000);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_withdraw(10375962933709971713186397585391106866622301945795493612535581072075858922494,0x00000000000000000000000000000002fFffFffD,0xe3496509013042BFE1a67B4224b72a93FE97084C);

        vm.roll(block.number + 33);
        vm.warp(block.timestamp + 322078);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVault_redeem_clamped(55243915138253595273905444630851956477277042572997613017737496089671826022625);

        vm.roll(block.number + 5000);
        vm.warp(block.timestamp + 136);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_requestRedeem(901,0x0000000000000000000000000000000000000100,0x00000000000000000000000000000001fffffffE);

        vm.roll(block.number + 4896);
        vm.warp(block.timestamp + 253);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVault_invalidateNonce(hex"73686172657320617265206c6f7374206f6e207472616e6665724e554c4e554c4e554c4e554c4e554cce");

        vm.roll(block.number + 55767);
        vm.warp(block.timestamp + 55);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVault_transferFrom(115792089237316195423570985008687907853269984665640564039457584007913129639921,36,112138039163542769390426844856125371791670786193129819891472661210324163441928);

        vm.roll(block.number + 73);
        vm.warp(block.timestamp + 322140);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_executeChangePrimaryManager_clamped();

        vm.roll(block.number + 101);
        vm.warp(block.timestamp + 2003);
        vm.prank(0x0000000000000000000000000000000000010000);
        superGovernor_executeUpkeepClaim(1313373043);

        vm.roll(block.number + 3603);
        vm.warp(block.timestamp + 322367);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_transferFrom(115792089237316195423570985008687907853269984665640564039457584007913129639921,36,81437930387965456392714585375751139200071685079674799609373104683112727819533);

        vm.roll(block.number + 25918);
        vm.warp(block.timestamp + 360621);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_claimUpkeep(1313373039);

        vm.roll(block.number + 27177);
        vm.warp(block.timestamp + 360626);
        vm.prank(0x0000000000000000000000000000000000020000);
        crytic_erc7540_2();

        vm.roll(block.number + 58783);
        vm.warp(block.timestamp + 207834);
        vm.prank(0x0000000000000000000000000000000000020000);
        crytic_erc7540_4_mint(36);

        vm.roll(block.number + 1426);
        vm.warp(block.timestamp + 136780);
        vm.prank(0x0000000000000000000000000000000000020000);
        yieldSource_switchRandom(383);

        vm.roll(block.number + 80);
        vm.warp(block.timestamp + 9003);
        vm.prank(0x0000000000000000000000000000000000010000);

        vm.roll(block.number + 41617);
        vm.warp(block.timestamp + 321475);
        vm.prank(0x0000000000000000000000000000000000020000);
        yieldSourceOracle_setValidAsset_clamped();

        vm.roll(block.number + 87);
        vm.warp(block.timestamp + 5004);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultAggregator_executeChangePrimaryManager(0x96d3F6c20EEd2697647F543fE6C08bC2Fbf39758);

        vm.roll(block.number + 33177);
        vm.warp(block.timestamp + 257);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_transferFrom(40115522929131880273780226976971848011349004905469689462313728119460108004298,91300265465447204144831738337820179076654073235475458717726937116291721478038,115792089237316195423570985008687907853269984665640564039457584007913129639933);

        vm.roll(block.number + 4943);
        vm.warp(block.timestamp + 87712);
        vm.prank(0x0000000000000000000000000000000000030000);
        doomsday_maxWithdrawResetsAfterFullWithdrawal(96972910349986830645469728782180246643732913539629359045687824461922921438363);

        vm.roll(block.number + 23887);
        vm.warp(block.timestamp + 318776);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultAggregator_withdrawUpkeep(103748966049045066875145476108063375745934726087303022325716594074012299105888);

        vm.roll(block.number + 59981);
        vm.warp(block.timestamp + 209930);
        vm.prank(0x0000000000000000000000000000000000030000);
        switch_asset(115792089237316195423570985008687907853269984665640564039457584007913129637938);

        vm.roll(block.number + 4124);
        vm.warp(block.timestamp + 5000);
        vm.prank(0x0000000000000000000000000000000000030000);
        erc7540_4_withdraw(0x00000000000000000000000000000002fFffFffD,499);

        vm.roll(block.number + 236);
        vm.warp(block.timestamp + 336129);
        vm.prank(0x0000000000000000000000000000000000010000);
        doomsday_primaryManagerAlwaysChangeable();

        vm.roll(block.number + 897);
        vm.warp(block.timestamp + 322269);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_simulateLoss(74893053038213412084592568882170756944108294226511832904065221220246494806330);

        vm.roll(block.number + 64);
        vm.warp(block.timestamp + 207837);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_lossSocialization();

        vm.roll(block.number + 41622);
        vm.warp(block.timestamp + 322369);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_mint(43870100496510228088780190708311142794838283286018710467901168644540277031418);

        vm.roll(block.number + 4967);
        vm.warp(block.timestamp + 317374);
        vm.prank(0x0000000000000000000000000000000000030000);
        property_accumulatorSharesIncrease();

        vm.roll(block.number + 53349);
        vm.warp(block.timestamp + 321372);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultStrategy_handleOperations4626Mint(0x00000000000000000000000000000002fFffFffD,17,115792089237316195423570985008687907853269984665640564039457584007913129630933,115792089237316195423570985008687907853269984665640564039457584007913129639932);

        vm.roll(block.number + 60469);
        vm.warp(block.timestamp + 317374);
        vm.prank(0x0000000000000000000000000000000000030000);
        property_previewEquivalenceFromShares(86402);

        vm.roll(block.number + 138);
        vm.warp(block.timestamp + 322119);
        vm.prank(0x0000000000000000000000000000000000020000);
        mockERC5115YieldSourceOracle_setValidAsset(0x00000000000000000000000000000001fffffffE,true);

        vm.roll(block.number + 72);
        vm.warp(block.timestamp + 236072);
        vm.prank(0x0000000000000000000000000000000000020000);
        yieldSource_redeem5115(0x00000000000000000000000000000001fffffffE,85213126995154247068080919536710638991246300430827272888631997157826993350672,0x00000000000000000000000000000002fFffFffD,27,false);

        vm.roll(block.number + 28127);
        vm.warp(block.timestamp + 360626);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_setRevertBehavior5115(14);

        vm.roll(block.number + 31);
        vm.warp(block.timestamp + 231);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVault_transferFrom(52963764191599942638965546595587767174340441614897468706170567331651356303344,115792089237316195423570985008687907853269984665640564039457584007913129634936,125928544085643288803984676289412233502294685761733916797399964805813506114);

        vm.roll(block.number + 896);
        vm.warp(block.timestamp + 490446);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_executeChangePrimaryManager_clamped();

        vm.roll(block.number + 24906);
        vm.warp(block.timestamp + 185594);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_setOperator(130392294642208293035575300194450347645240937011912275136,true);

        vm.roll(block.number + 4927);
        vm.warp(block.timestamp + 7994);
        vm.prank(0x0000000000000000000000000000000000020000);
        property_avgPPSMonotonicity();

        vm.roll(block.number + 1001);
        vm.warp(block.timestamp + 236466);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultStrategy_manageYieldSource_clamped(52031352948037041595250525172976833834878987986110955112757915432675939470611);

        vm.roll(block.number + 5021);
        vm.warp(block.timestamp + 372707);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_requestRedeem(32288112093976471197764269922920868053440386515988590243973469892796778526593);

        vm.roll(block.number + 298);
        vm.warp(block.timestamp + 322073);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVault_approve(0x00000000000000000000000000000000FFFFfFFF,0);

        vm.roll(block.number + 36555);
        vm.warp(block.timestamp + 360626);
        vm.prank(0x0000000000000000000000000000000000030000);
        property_accumulatorSharesSolvency();

        vm.roll(block.number + 5037);
        vm.warp(block.timestamp + 386816);
        vm.prank(0x0000000000000000000000000000000000030000);
        setPreviewSharesGreater(93);

        vm.roll(block.number + 1426);
        vm.warp(block.timestamp + 566552);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultAggregator_depositStake(0x00000000000000000000000000000000FFFFfFFF,37439836327923360225337895871394760624280537466773280374265222508165906222593);

        vm.roll(block.number + 4956);
        vm.warp(block.timestamp + 24044);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVault_redeem_clamped(94885414644755857251539466547848618250271969671412066099013281252117949336721);

        vm.roll(block.number + 134);
        vm.warp(block.timestamp + 1001);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultAggregator_proposeChangePrimaryManager(0x00000000000000000000000000000001fffffffE,0x00000000000000000000000000000002fFffFffD);

        vm.roll(block.number + 53678);
        vm.warp(block.timestamp + 3867);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_mint(420);

        vm.roll(block.number + 22909);
        vm.warp(block.timestamp + 440699);
        vm.prank(0x0000000000000000000000000000000000020000);
        yieldSource_cancelDepositRequest(115792089237316195423570985008687907853269984665640564039457584007913129639835,0x00000000000000000000000000000002fFffFffD);

        vm.roll(block.number + 4723);
        vm.warp(block.timestamp + 258);
        vm.prank(0x0000000000000000000000000000000000030000);

        vm.roll(block.number + 5037);
        vm.warp(block.timestamp + 311180);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultAggregator_claimUpkeep(83164046402136288767567101597651710240018450220453736318397247470801921976857);

        vm.roll(block.number + 13785);
        vm.warp(block.timestamp + 81);
        vm.prank(0x0000000000000000000000000000000000020000);
        yieldSource_switchRandom(33179873326728164774339612485881420772770996318071074564960648168199612679487);

        vm.roll(block.number + 37381);
        vm.warp(block.timestamp + 2003);
        vm.prank(0x0000000000000000000000000000000000020000);
        asset_approve(0x00000000000000000000000000000001fffffffE,197362997495200162233323913443337993297);

     }

    // forge test --match-test test_property_previewEquivalenceFromShares_4 -vvv 
    function test_property_previewEquivalenceFromShares_4() public {

        vm.roll(block.number + 24906);
        vm.warp(block.timestamp + 66543);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_changePrimaryManager(0x00000000000000000000000000000000FFFFfFFF,0x00000000000000000000000000000000FFFFfFFF);

        vm.roll(block.number + 4985);
        vm.warp(block.timestamp + 254414);
        vm.prank(0x0000000000000000000000000000000000010000);

        vm.roll(block.number + 40596);
        vm.warp(block.timestamp + 253);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultAggregator_claimUpkeep(53428707326380677990058551147420484089323222448351783943895124008664451471173);

        vm.roll(block.number + 4527);
        vm.warp(block.timestamp + 314383);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_withdraw(33958009586084337413836718322182798420714603986689552980546020140600314003313);

        vm.roll(block.number + 4523);
        vm.warp(block.timestamp + 542553);
        vm.prank(0x0000000000000000000000000000000000010000);
        // superVaultStrategy_manageEmergencyWithdraw(195,0x00000000000000000000000000000000FFFFfFFF,86367609042062270596932846984720848957160891212973284338034594110571691142315);

        vm.roll(block.number + 5015);
        vm.warp(block.timestamp + 198598);
        vm.prank(0x0000000000000000000000000000000000030000);
        doomsday_mintRedeemSymmetrical(498);

        vm.roll(block.number + 23978);
        vm.warp(block.timestamp + 5);
        vm.prank(0x0000000000000000000000000000000000030000);
        crytic_erc7540_4_withdraw(3599);

        vm.roll(block.number + 60469);
        vm.warp(block.timestamp + 127);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultAggregator_updatePPSVerificationThresholds(0xa0Cb889707d426A7A386870A03bc70d1b0697598,18944438876983479726009849191614505257359890364994665806301818993556058863404,12,29069285465454005618120123644381231509185402544382665627410470033677601400006);

        vm.roll(block.number + 1088);
        vm.warp(block.timestamp + 71);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_requestRedeem(20);

        vm.roll(block.number + 120);
        vm.warp(block.timestamp + 225906);
        vm.prank(0x0000000000000000000000000000000000020000);
        property_oraclePPSDoesntChangeOnAddOrRemove();

        vm.roll(block.number + 32330);
        vm.warp(block.timestamp + 482712);
        vm.prank(0x0000000000000000000000000000000000020000);
        superGovernor_proposeGlobalHooksRoot_clamped(hex"4d6f636b4552433432365465737465724e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c95");

        vm.roll(block.number + 1027);
        vm.warp(block.timestamp + 322345);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_accumulatorSharesSolvency();

        vm.roll(block.number + 299);
        vm.warp(block.timestamp + 383969);
        vm.prank(0x0000000000000000000000000000000000020000);
        property_naivePPSDoesntChangeOnDepositOrMint();

        vm.roll(block.number + 28);
        vm.warp(block.timestamp + 322236);
        vm.prank(0x0000000000000000000000000000000000010000);
        superGovernor_proposeUpkeepPaymentsChange_clamped();

        vm.roll(block.number + 27133);
        vm.warp(block.timestamp + 236461);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_depositUpkeep(17215259209224116763165824453469496913761537375337189502200038625522844047215);

        vm.roll(block.number + 9922);
        vm.warp(block.timestamp + 235976);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_oraclePPSDoesntChangeOnAddOrRemove();

        vm.roll(block.number + 4890);
        vm.warp(block.timestamp + 86403);
        vm.prank(0x0000000000000000000000000000000000020000);
        yieldSource_switchToERC7540();

        vm.roll(block.number + 896);
        vm.warp(block.timestamp + 126793);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_mint(21865469541050783575930466213871146151290755655013538058129355681260461773823);

        vm.roll(block.number + 36859);
        vm.warp(block.timestamp + 102);
        vm.prank(0x0000000000000000000000000000000000010000);
        doomsday_fulfillDoesntOverRedeemMultipleActors([12303642812405422463315294961415770874932961248837269219292429324430671698051, 100000000, 100731995502229702857652079652417642489197336584428501814213748244028780069671],[604799, 115792089237316195423570985008687907853269984665640564039457584007913129639849, 79349306313693868977220099084696187138359835857253918371904658202391463309767]);

        vm.roll(block.number + 58183);
        vm.warp(block.timestamp + 322121);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_addAuthorizedCaller(0x212224D2F2d262cd093eE13240ca4873fcCBbA3C,0x00000000000000000000000000000001fffffffE);

        vm.roll(block.number + 23);
        vm.warp(block.timestamp + 321477);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultAggregator_proposeChangePrimaryManager(0xa80C1cacF809ECE71Eb724D7BF3a0C968c95EC69,0xD16d567549A2a2a2005aEACf7fB193851603dd70);

        vm.roll(block.number + 33173);
        vm.warp(block.timestamp + 321374);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_transferFrom(97368847849410423958695613801576076927009045756524049260044652053947185268678,115792089237316195423570985008687907853269984665640564039457584007913129639880,95);

        vm.roll(block.number + 43124);
        vm.warp(block.timestamp + 195583);
        vm.prank(0x0000000000000000000000000000000000030000);
        property_accumulatorSharesIncrease();

     }

    // forge test --match-test test_doomsday_mintRedeemSymmetrical_5 -vvv 
    function test_doomsday_mintRedeemSymmetrical_5() public {

        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_mint(1,0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultStrategy_manageYieldSource_clamped(0);

        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultStrategy_manageYieldSource_clamped(0);

        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_mint(1,0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_deposit(4);

        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_deposit(4);

        vm.roll(block.number + 26960);
        vm.warp(block.timestamp + 2001);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_redeem(86400);

        vm.roll(block.number + 26960);
        vm.warp(block.timestamp + 2001);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_redeem(86400);

        vm.roll(block.number + 16252);
        vm.warp(block.timestamp + 5);
        vm.prank(0x0000000000000000000000000000000000030000);
        erc7540_7_deposit(0x00000000000000000000000000000000FFFFfFFF,64506548807183500226435556029037627273345675520051923536211228509064127878857);

        vm.roll(block.number + 16252);
        vm.warp(block.timestamp + 5);
        vm.prank(0x0000000000000000000000000000000000030000);
        erc7540_7_deposit(0x00000000000000000000000000000000FFFFfFFF,64506548807183500226435556029037627273345675520051923536211228509064127878857);

        vm.roll(block.number + 49252);
        vm.warp(block.timestamp + 236467);
        vm.prank(0x0000000000000000000000000000000000030000);
        property_accumulatorSharesSolvency();

        vm.roll(block.number + 24987);
        vm.warp(block.timestamp + 3601);
        vm.prank(0x0000000000000000000000000000000000020000);
        crytic_erc7540_1();

        vm.roll(block.number + 2497);
        vm.warp(block.timestamp + 1);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_withdraw_clamped(115792089237316195423570985008687907853269984665640564039457584007913129639908);

        vm.roll(block.number + 2512);
        vm.warp(block.timestamp + 127251);
        vm.prank(0x0000000000000000000000000000000000030000);
        doomsday_previewMintEquivalence(115792089237316195423570985008687907853269984665640564039457584007913129636335);

        vm.roll(block.number + 25522);
        vm.warp(block.timestamp + 322358);
        vm.prank(0x0000000000000000000000000000000000020000);
        property_totalSharesDontDecreaseOnRedemptionRequest();

        vm.roll(block.number + 27);
        vm.warp(block.timestamp + 150273);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_accumulatorSharesSolvency();

        vm.roll(block.number + 9733);
        vm.warp(block.timestamp + 499);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_totalAssets();

        vm.roll(block.number + 4925);
        vm.warp(block.timestamp + 569114);
        vm.prank(0x0000000000000000000000000000000000020000);
        setpreviewAssetsGreater(95928775947738535382762797757914142225352280976433310053813184987792761999221);

        vm.roll(block.number + 56507);
        vm.warp(block.timestamp + 312374);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSourceOracle_setValidAsset_clamped();

        vm.roll(block.number + 23887);
        vm.warp(block.timestamp + 464717);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVault_requestRedeem_clamped(51088088980074378833363519653851895615025092963642611589839292085648419754832);

        vm.roll(block.number + 23722);
        vm.warp(block.timestamp + 566553);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSourceOracle_setValidAsset_clamped();

        vm.roll(block.number + 22);
        vm.warp(block.timestamp + 322375);
        vm.prank(0x0000000000000000000000000000000000030000);

        vm.roll(block.number + 4001);
        vm.warp(block.timestamp + 322142);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_withdraw_clamped(31);

        vm.roll(block.number + 1026);
        vm.warp(block.timestamp + 63);
        vm.prank(0x0000000000000000000000000000000000020000);
        doomsday_mintRedeemSymmetrical(77);

        vm.roll(block.number + 16258);
        vm.warp(block.timestamp + 236462);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultAggregator_withdrawStake(100000000000000000000000002);

        vm.roll(block.number + 4975);
        vm.warp(block.timestamp + 75);
        vm.prank(0x0000000000000000000000000000000000030000);
        yieldSource_cancelRedeemRequest(38317203283189314315941905178310652191657527748060384572725924885776999469223,0xfef63E1aB7eCA4BB8aAF9af11955053054a49e93);

        vm.roll(block.number + 95);
        vm.warp(block.timestamp + 73038);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultStrategy_handleOperations7540(121,0x00000000000000000000000000000001fffffffE,0xa80C1cacF809ECE71Eb724D7BF3a0C968c95EC69,115792089237316195423570985008687907853269984665640564039457584007913129639438);

        vm.roll(block.number + 4992);
        vm.warp(block.timestamp + 38);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_accumulatorCostBasisSolvency();

        vm.roll(block.number + 28950);
        vm.warp(block.timestamp + 322352);
        vm.prank(0x0000000000000000000000000000000000030000);
        property_avgPPSMonotonicity();

        vm.roll(block.number + 1088);
        vm.warp(block.timestamp + 126618);
        vm.prank(0x0000000000000000000000000000000000030000);
        yieldSource_setDecimalsOffset(17);

        vm.roll(block.number + 1784);
        vm.warp(block.timestamp + 459675);
        vm.prank(0x0000000000000000000000000000000000030000);
        mockERC7540YieldSourceOracle_setValidAsset(0x00000000000000000000000000000000FFFFfFFF,true);

        vm.roll(block.number + 27137);
        vm.warp(block.timestamp + 402112);
        vm.prank(0x0000000000000000000000000000000000010000);
        setpreviewAssetsGreater(115792089237316195423570985008687907853269984665640564039457584007913129639851);

        vm.roll(block.number + 4931);
        vm.warp(block.timestamp + 449616);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultStrategy_manageYieldSource_clamped(96074594460416826815957180909358217072398063484082004046658713411875880155435);

        vm.roll(block.number + 3025);
        vm.warp(block.timestamp + 1);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultAggregator_depositStake(0xc7183455a4C133Ae270771860664b6B7ec320bB1,115792089237316195423570985008687907853269984665640564039456584007913129639936);

        vm.roll(block.number + 17456);
        vm.warp(block.timestamp + 247528);
        vm.prank(0x0000000000000000000000000000000000010000);
        erc7540_4_mint(0x00000000000000000000000000000001fffffffE,18446744073709551614);

        vm.roll(block.number + 4001);
        vm.warp(block.timestamp + 136775);
        vm.prank(0x0000000000000000000000000000000000010000);
        ECDSAPPSOracle_updatePPS_clamped(4);

        vm.roll(block.number + 7321);
        vm.warp(block.timestamp + 322318);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultStrategy_handleOperations7540(205,0xEd0c7986cB7a7a1eED89B520d604B796D9101466,0x85f7E11b9AA93Eb7b43b4B8Ab497C4A829F4FEF0,9163284140466355026291114174552343145013288025031506028490720498473781436380);

        vm.roll(block.number + 120);
        vm.warp(block.timestamp + 3599);
        vm.prank(0x0000000000000000000000000000000000030000);
        superGovernor_proposeGlobalHooksRoot_clamped(hex"6fadd0fd68e17a5354582df8be1839798ebe0ecf772ead924e994b5482d0af24492d");

        vm.roll(block.number + 5017);
        vm.warp(block.timestamp + 80);
        vm.prank(0x0000000000000000000000000000000000020000);
        doomsday_depositWithdrawSymmetrical(604798);

        vm.roll(block.number + 3599);
        vm.warp(block.timestamp + 385873);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_maxRedeemMaxWithdrawSymmetry();

        vm.roll(block.number + 55501);
        vm.warp(block.timestamp + 317377);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultAggregator_executeChangePrimaryManager_clamped();

        vm.roll(block.number + 4527);
        vm.warp(block.timestamp + 322279);
        vm.prank(0x0000000000000000000000000000000000020000);
        erc7540_4_mint(0xDB25A7b768311dE128BBDa7B8426c3f9C74f3240,115792089237316195423570985008687907853269984665640564039457584007913129639637);

        vm.roll(block.number + 757);
        vm.warp(block.timestamp + 320376);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_mint(115792089237316195423570985008687907853269984665640564039457584007913129639931);

        vm.roll(block.number + 253);
        vm.warp(block.timestamp + 336897);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultAggregator_addSecondaryManager(0x00000000000000000000000000000001fffffffE,0x00000000000000000000000000000000FFFFfFFF);

        vm.roll(block.number + 2526);
        vm.warp(block.timestamp + 236464);
        vm.prank(0x0000000000000000000000000000000000030000);
        yieldSource_setRevertBehavior4626(35,48);

        vm.roll(block.number + 4956);
        vm.warp(block.timestamp + 139);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_addSecondaryManager(0x0000000000000000000000000000000000000000,0xc7183455a4C133Ae270771860664b6B7ec320bB1);

        vm.roll(block.number + 27091);
        vm.warp(block.timestamp + 322303);
        vm.prank(0x0000000000000000000000000000000000010000);
        add_new_asset(116);

        vm.roll(block.number + 27132);
        vm.warp(block.timestamp + 54);
        vm.prank(0x0000000000000000000000000000000000030000);
        crytic_erc7540_7_withdraw(61119263489409915792387055657499519916182231998562080298766116314734956789195);

        vm.roll(block.number + 37);
        vm.warp(block.timestamp + 313374);
        vm.prank(0x0000000000000000000000000000000000030000);
        property_accumulatorCostBasisSolvency();

        vm.roll(block.number + 36252);
        vm.warp(block.timestamp + 322281);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultStrategy_manageYieldSource_clamped(17762607913530997621099683701834669100452427793565455808210185329579624199580);

        vm.roll(block.number + 4767);
        vm.warp(block.timestamp + 256);
        vm.prank(0x0000000000000000000000000000000000010000);
        setPreviewSharesGreater(115792089237316195423570985008687907853269984665640564039457584007913129639889);

     }

    // forge test --match-test test_property_sumOfClaimable_6 -vvv 
    function test_property_sumOfClaimable_6() public {

        vm.roll(block.number + 19933);
        vm.warp(block.timestamp + 317373);
        vm.prank(0x0000000000000000000000000000000000010000);
        property_accumulatorCostBasisIncrease();

        vm.roll(block.number + 32332);
        vm.warp(block.timestamp + 440097);
        vm.prank(0x0000000000000000000000000000000000010000);
        superGovernor_proposeGlobalHooksRoot_clamped(hex"5045524d49545f444541444c494e455f455850495245444e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c4e554c");

        vm.roll(block.number + 32767);
        vm.warp(block.timestamp + 321374);
        vm.prank(0x0000000000000000000000000000000000010000);
        superGovernor_executeFeeUpdate(169);

        vm.roll(block.number + 7320);
        vm.warp(block.timestamp + 10003);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_withdraw(97254394749276200956379658795175723443944885431369453161720808616897199678139,0x00000000000000000000000000000000FFFFfFFF,0x71Dc6Ab31DF856f599685c90c3e641cCE92b3957);

        vm.roll(block.number + 24908);
        vm.warp(block.timestamp + 195584);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_switchRandom(8533758431372259325528106735089698244534293979259046214837205444925825937350);

        vm.roll(block.number + 86);
        vm.warp(block.timestamp + 497);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVault_deposit(12);

        vm.roll(block.number + 11112);
        vm.warp(block.timestamp + 93);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_proposeChangePrimaryManager_clamped();

        vm.roll(block.number + 87);
        vm.warp(block.timestamp + 322277);
        vm.prank(0x0000000000000000000000000000000000010000);
        yieldSource_setRevertBehavior4626(158,16);

        vm.roll(block.number + 1998);
        vm.warp(block.timestamp + 73037);
        vm.prank(0x0000000000000000000000000000000000020000);
        property_avgPPSMonotonicity();

        vm.roll(block.number + 4991);
        vm.warp(block.timestamp + 372713);
        vm.prank(0x0000000000000000000000000000000000010000);
        add_new_asset(231);

        vm.roll(block.number + 32334);
        vm.warp(block.timestamp + 16122);
        vm.prank(0x0000000000000000000000000000000000030000);
        setpreviewAssetsGreater(115792089237316195423570985008687907853269984665640564039457584007913129035136);

        vm.roll(block.number + 8447);
        vm.warp(block.timestamp + 566555);
        vm.prank(0x0000000000000000000000000000000000010000);
        superVaultStrategy_fulfillRedeemRequests_clamped(27429629597240894542773995349569366381711346390148788245915006849532456144561);

        vm.roll(block.number + 15698);
        vm.warp(block.timestamp + 243101);
        vm.prank(0x0000000000000000000000000000000000030000);
        superVaultStrategy_handleOperations7540(97,0x00000000000000000000000000000002fFffFffD,0x00000000000000000000000000000002fFffFffD,28738967044078783442992553521440142983252121339704895228240406024710320946245);

        vm.roll(block.number + 55503);
        vm.warp(block.timestamp + 588255);
        vm.prank(0x0000000000000000000000000000000000010000);
        doomsday_redemptionsNeverReverts(1);

        vm.roll(block.number + 34);
        vm.warp(block.timestamp + 949);
        vm.prank(0x0000000000000000000000000000000000020000);
        crytic_erc7540_2();

        vm.roll(block.number + 46422);
        vm.warp(block.timestamp + 318378);
        vm.prank(0x0000000000000000000000000000000000020000);
        superVaultAggregator_withdrawStake(12032075403133495294540839763961344592976976640321497592740195302354860813040);
    }
}
