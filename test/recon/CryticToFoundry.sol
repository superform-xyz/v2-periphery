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
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/66
    function test_doomsday_maxWithdrawResetsAfterFullWithdrawal_17() public {
        superVaultStrategy_manageYieldSource_clamped(0);
        address yieldSource = _getYieldSource();

        superVault_deposit(3000e6);

        // Deposit into underlying yield source
        address[] memory hooks = new address[](1);
        hooks[0] = address(approveAndDeposit4626Hook);

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = MockERC4626Tester(yieldSource).previewDeposit(300e6);

        bytes[] memory hookCalldata = new bytes[](1);
        hookCalldata[0] = abi.encodePacked(bytes32(0), yieldSource, superVault.asset(), uint256(300e6), false);

        ISuperVaultStrategy.ExecuteArgs memory executeArgs = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: hookCalldata,
            expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
            globalProofs: new bytes32[][](1),
            strategyProofs: new bytes32[][](1)
        });

        superVaultStrategy_executeHooks(executeArgs);

        uint256 shares = superVault.balanceOf(_getActor());

        superVault_requestRedeem_clamped(shares);

        vm.warp(block.timestamp + 1 days);
        ECDSAPPSOracle_updatePPS_clamped(
            17_300_000_000_000_000_000
        );

        // yieldSource_simulateGain(973_782);

        address[] memory controllers = new address[](1);
        controllers[0] = _getActor();

        superVaultStrategy_fulfillRedeemRequests(shares, controllers);

        //superVault_requestRedeem_clamped(1);

        // doomsday_maxWithdrawResetsAfterFullWithdrawal(988_620);
    }

    // forge test --match-test test_property_sumOfClaimable_5 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/67
    function test_property_sumOfClaimable_5() public {

        superVault_deposit(3);

        superVault_requestRedeem_clamped(1);

        property_sumOfClaimable();
    }

    // forge test --match-test test_property_assetBacking_10 -vvv
    // NOTE: see issue here: https://github.com/Recon-Fuzz/superform-review/issues/68
    function test_property_assetBacking_10() public {
        superVault_deposit(40_000);

        yieldSource_deposit(40_000, address(superVaultStrategy));

        uint256 shares = superVault.balanceOf(_getActor());

        superVault_requestRedeem(shares);

        yieldSource_simulateGain(100_000_003);

        address[] memory controllers = new address[](1);
        controllers[0] = _getActor();

        superVaultStrategy_fulfillRedeemRequests(shares, controllers);

        superVault_withdraw(shares);

        int256 difference = optimize_assetBackingDifference();
        console2.log("difference: ", difference);

        // have 2 unbacked shares
        // console2.log("totalSupply: ", superVault.totalSupply());
        property_assetBacking();
    }

    // forge test --match-test test_crytic_erc7540_4_redeem_1 -vvv
    // see issue here: https://github.com/Recon-Fuzz/superform-review/issues/76
    // NOTE: incorrect return value in maxRedeem causes the property to break but fundamentally is an issue with the
    // share calculation in maxRedeem because user doesn't end up redeeming more than their max available
    function test_crytic_erc7540_4_redeem_1() public {
        superVaultStrategy_manageYieldSource_clamped(0);

        superVault_deposit(3000e6);

        uint256 shares = superVault.balanceOf(_getActor());

        vm.warp(block.timestamp + 1 days);
        superVault_requestRedeem_clamped(shares);

        console2.log("PPS before: %e", superVaultAggregator.getPPS(address(superVaultStrategy)));
        ECDSAPPSOracle_updatePPS_clamped(9_550_051_690_458_586_526);
        console2.log("PPS after: %e", superVaultAggregator.getPPS(address(superVaultStrategy)));

        console2.log("avg withdraw price before fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));

        address[] memory controllers = new address[](1);
        controllers[0] = _getActor();

        superVaultStrategy_fulfillRedeemRequests(shares, controllers);

        console2.log("avg withdraw price after fulfill: %e", superVaultStrategy.getAverageWithdrawPrice(_getActor()));
        crytic_erc7540_4_redeem(shares);
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

        uint256 shares0 = superVault.balanceOf(_getActor());
        switchActor(1);
        uint256 shares1 = superVault.balanceOf(_getActor());
        switchActor(0);

        // Request all redemptions
        superVault_requestRedeem_clamped(shares0);
        switchActor(1);
        superVault_requestRedeem_clamped(shares1);

        address[] memory controllers = new address[](2);
        controllers[0] = _getActor();
        switchActor(0);
        controllers[1] = _getActor();

        superVaultStrategy_fulfillRedeemRequests(shares0,controllers);

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

        yieldSource_mint(1, 0xc3C1658B1e3b9e017030807d0C50895456FD2379);

        superVault_deposit(2);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 5);
        superVault_requestRedeem_clamped(1);

        ECDSAPPSOracle_updatePPS_clamped(
            94_828_176_912_403_810_418_829_620_192_424_272_151_546_062_289_895_417_675_768_111_400_040_900
        );

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
        superVault_deposit(40_000);
        uint256 shares = superVault.balanceOf(_getActor());
        vm.warp(block.timestamp + 1 days);

        vm.prank(_getActor());
        superVault_requestRedeem(shares);
        superVault_cancelRedeem();
    }

    // forge test --match-test test_doomsday_mintRedeemSymmetrical_6 -vvv
    function test_doomsday_mintRedeemSymmetrical_6() public {
        doomsday_mintRedeemSymmetrical(40_000);
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
