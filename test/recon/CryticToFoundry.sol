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
        merkleHelper = new MerkleTestHelper();
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
        vm.roll(block.number + 5000);
        vm.warp(block.timestamp + 136);
        yieldSource_requestRedeem(901,0x0000000000000000000000000000000000000100,0x00000000000000000000000000000001fffffffE);

        vm.roll(block.number + 4967);
        vm.warp(block.timestamp + 317374);
        property_accumulatorSharesIncrease();

        vm.roll(block.number + 4927);
        vm.warp(block.timestamp + 7994);
        property_avgPPSMonotonicity();

        vm.roll(block.number + 36555);
        vm.warp(block.timestamp + 360626);
        property_accumulatorSharesSolvency();

        // TODO: Cancel redeem request
        vm.roll(block.number + 22909);
        vm.warp(block.timestamp + 440699);
        yieldSource_cancelDepositRequest(115792089237316195423570985008687907853269984665640564039457584007913129639835,0x00000000000000000000000000000002fFffFffD);
     }

    // forge test --match-test test_property_previewEquivalenceFromShares_4 -vvv 
    function test_property_previewEquivalenceFromShares_4() public {
        vm.roll(block.number + 24906);
        vm.warp(block.timestamp + 66543);
        superVaultAggregator_changePrimaryManager(0x00000000000000000000000000000000FFFFfFFF,0x00000000000000000000000000000000FFFFfFFF);

        vm.roll(block.number + 40596);
        vm.warp(block.timestamp + 253);
        superVaultAggregator_claimUpkeep(53428707326380677990058551147420484089323222448351783943895124008664451471173);

        vm.roll(block.number + 4527);
        vm.warp(block.timestamp + 314383);
        superVault_withdraw(33958009586084337413836718322182798420714603986689552980546020140600314003313);

        // vm.roll(block.number + 4523);
        // vm.warp(block.timestamp + 542553);
        // vm.prank(0x0000000000000000000000000000000000010000);
        // superVaultStrategy_manageEmergencyWithdraw(195,0x00000000000000000000000000000000FFFFfFFF,86367609042062270596932846984720848957160891212973284338034594110571691142315);

        vm.roll(block.number + 5015);
        vm.warp(block.timestamp + 198598);
        doomsday_mintRedeemSymmetrical(498);

        vm.roll(block.number + 23978);
        vm.warp(block.timestamp + 5);
        crytic_erc7540_4_withdraw(3599);

        vm.roll(block.number + 60469);
        vm.warp(block.timestamp + 127);
        superVaultAggregator_updatePPSVerificationThresholds(0xa0Cb889707d426A7A386870A03bc70d1b0697598,18944438876983479726009849191614505257359890364994665806301818993556058863404,12,29069285465454005618120123644381231509185402544382665627410470033677601400006);

        vm.roll(block.number + 1088);
        vm.warp(block.timestamp + 71);
        superVault_requestRedeem(20);

        vm.roll(block.number + 120);
        vm.warp(block.timestamp + 225906);
        property_oraclePPSDoesntChangeOnAddOrRemove();

        vm.roll(block.number + 32330);
        vm.warp(block.timestamp + 482712);
        (bytes32 testRoot,) = merkleHelper.generateTestHooksRoot(
            address(withdraw7540Hook), address(requestRedeem7540Hook), _getYieldSource(), superVault.asset()
        );
        superGovernor_proposeGlobalHooksRoot(testRoot);

        vm.roll(block.number + 1027);
        vm.warp(block.timestamp + 322345);
        property_accumulatorSharesSolvency();

        //vm.roll(block.number + 299);
        // vm.warp(block.timestamp + 383969);
        // property_naivePPSDoesntChangeOnDepositOrMint();

        vm.roll(block.number + 28);
        vm.warp(block.timestamp + 322236);
        superGovernor_proposeUpkeepPaymentsChange_clamped();

        vm.roll(block.number + 27133);
        vm.warp(block.timestamp + 236461);
        superVaultAggregator_depositUpkeep(17215259209224116763165824453469496913761537375337189502200038625522844047215);

        vm.roll(block.number + 9922);
        vm.warp(block.timestamp + 235976);
        property_oraclePPSDoesntChangeOnAddOrRemove();

        vm.roll(block.number + 4890);
        vm.warp(block.timestamp + 86403);
        yieldSource_switchToERC7540();

        vm.roll(block.number + 896);
        vm.warp(block.timestamp + 126793);
        superVault_mint(21865469541050783575930466213871146151290755655013538058129355681260461773823);

        vm.roll(block.number + 36859);
        vm.warp(block.timestamp + 102);
        doomsday_fulfillDoesntOverRedeemMultipleActors([12303642812405422463315294961415770874932961248837269219292429324430671698051, 100000000, 100731995502229702857652079652417642489197336584428501814213748244028780069671],[604799, 115792089237316195423570985008687907853269984665640564039457584007913129639849, 79349306313693868977220099084696187138359835857253918371904658202391463309767]);

        vm.roll(block.number + 58183);
        vm.warp(block.timestamp + 322121);
        superVaultAggregator_addAuthorizedCaller(0x212224D2F2d262cd093eE13240ca4873fcCBbA3C,0x00000000000000000000000000000001fffffffE);

        vm.roll(block.number + 23);
        vm.warp(block.timestamp + 321477);
        superVaultAggregator_proposeChangePrimaryManager(0xa80C1cacF809ECE71Eb724D7BF3a0C968c95EC69,0xD16d567549A2a2a2005aEACf7fB193851603dd70);

        vm.roll(block.number + 33173);
        vm.warp(block.timestamp + 321374);
        superVault_transferFrom(97368847849410423958695613801576076927009045756524049260044652053947185268678,115792089237316195423570985008687907853269984665640564039457584007913129639880,95);

        vm.roll(block.number + 43124);
        vm.warp(block.timestamp + 195583);
        property_accumulatorSharesIncrease();
     }

    // forge test --match-test test_doomsday_mintRedeemSymmetrical_5 -vvv 
    function test_doomsday_mintRedeemSymmetrical_6() public {
        yieldSource_mint(1,0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(4);

        superVault_deposit(4);

        superVault_redeem(86400);

        doomsday_mintRedeemSymmetrical(77);
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
}
