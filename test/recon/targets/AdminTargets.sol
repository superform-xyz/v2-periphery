// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// External dependencies
import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import {Panic} from "@recon/Panic.sol";
import {MockERC20} from "@recon/MockERC20.sol";

// System dependencies
import {ISuperVaultStrategy} from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

// Test dependencies
import {YieldSourceType} from "test/recon/managers/YieldManager.sol";
import {BeforeAfter, OpType} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";

abstract contract AdminTargets is BaseTargetFunctions, Properties {
    enum HookType {
        // ERC4626 Hooks
        ApproveAndDeposit4626,
        Deposit4626,
        Redeem4626,
        // ERC5115 Hooks
        ApproveAndDeposit5115,
        Deposit5115,
        Redeem5115,
        // ERC7540 Hooks
        Deposit7540,
        Redeem7540,
        RequestDeposit7540,
        RequestRedeem7540,
        ApproveAndRequestDeposit7540,
        CancelDepositRequest7540,
        CancelRedeemRequest7540,
        ClaimCancelDepositRequest7540,
        ClaimCancelRedeemRequest7540,
        Withdraw7540,
        // Super Vault Hooks
        CancelRedeem,
        SuperVaultWithdraw7540
    }

    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    function superVaultStrategy_executeHooks_clamped(
        uint256[] memory hookTypeInts,
        uint256[] memory amountsToInvest,
        bool[] memory usePrevHookAmounts
    ) public payable {
        // Limit the number of hooks to 10 maximum
        uint256 numHooks = hookTypeInts.length;
        if (numHooks > 10) {
            numHooks = 10;
        }

        // Ensure all arrays have the same length
        if (amountsToInvest.length < numHooks) {
            numHooks = amountsToInvest.length;
        }
        if (usePrevHookAmounts.length < numHooks) {
            numHooks = usePrevHookAmounts.length;
        }

        // Return early if no hooks to execute
        if (numHooks == 0) {
            return;
        }

        // Create ExecuteArgs for the hooks
        ISuperVaultStrategy.ExecuteArgs memory executeArgs = ISuperVaultStrategy
            .ExecuteArgs({
                hooks: new address[](numHooks),
                hookCalldata: new bytes[](numHooks),
                expectedAssetsOrSharesOut: new uint256[](numHooks),
                globalProofs: new bytes32[][](numHooks),
                strategyProofs: new bytes32[][](numHooks)
            });

        // Process each hook
        uint256 totalAmountToDeposit;
        for (uint256 i = 0; i < numHooks; i++) {
            // Convert integer to enum (will wrap around if > max enum value)
            HookType hookType = HookType(hookTypeInts[i] % 17); // 17 is the total number of hooks

            // Clamp to the strategy's asset balance (not SuperVault's balance)
            uint256 clampedAmount = amountsToInvest[i] %
                (MockERC20(superVault.asset()).balanceOf(
                    address(superVaultStrategy)
                ) + 1);

            // Get the hook address and calldata
            (
                address hookAddress,
                bytes memory hookCalldata
            ) = _getHookAddressAndCalldata(
                    hookType,
                    clampedAmount,
                    usePrevHookAmounts[i]
                );

            executeArgs.hooks[i] = hookAddress;
            executeArgs.hookCalldata[i] = hookCalldata;
            executeArgs.expectedAssetsOrSharesOut[i] = clampedAmount;
            executeArgs.globalProofs[i] = new bytes32[](1);
            executeArgs.strategyProofs[i] = new bytes32[](1);

            totalAmountToDeposit += clampedAmount;
        }

        // Check that amount to be invested is less than the claimable assets so that it doesn't reinvest and prevent users from claiming
        if (_claimableMoreThanInvested(totalAmountToDeposit)) return;

        // Execute all hooks
        this.superVaultStrategy_executeHooks{value: msg.value}(executeArgs);
    }

    function _getHookAddressAndCalldata(
        HookType hookType,
        uint256 amountToInvest,
        bool usePrevHookAmount
    ) internal view returns (address hookAddress, bytes memory hookCalldata) {
        if (hookType == HookType.ApproveAndDeposit4626) {
            hookAddress = address(approveAndDeposit4626Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                superVault.asset(), // Address of the token to approve and deposit
                amountToInvest, // Amount to deposit
                usePrevHookAmount
            );
        } else if (hookType == HookType.Deposit4626) {
            hookAddress = address(deposit4626Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to deposit
                usePrevHookAmount
            );
        } else if (hookType == HookType.Redeem4626) {
            hookAddress = address(redeem4626Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to redeem
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy) // Owner
            );
        } else if (hookType == HookType.ApproveAndDeposit5115) {
            hookAddress = address(approveAndDeposit5115Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                superVault.asset(), // Address of the token to approve and deposit
                bytes32(0), // tokenId (for ERC5115)
                amountToInvest, // Amount to deposit
                usePrevHookAmount
            );
        } else if (hookType == HookType.Deposit5115) {
            hookAddress = address(deposit5115Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                bytes32(0), // tokenId (for ERC5115)
                amountToInvest, // Amount to deposit
                usePrevHookAmount
            );
        } else if (hookType == HookType.Redeem5115) {
            hookAddress = address(redeem5115Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                bytes32(0), // tokenId (for ERC5115)
                amountToInvest, // Amount to redeem
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy) // Owner
            );
        } else if (hookType == HookType.Deposit7540) {
            hookAddress = address(deposit7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to deposit
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.Redeem7540) {
            hookAddress = address(redeem7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to redeem
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy), // Owner
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.RequestDeposit7540) {
            hookAddress = address(requestDeposit7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to request deposit
                address(superVaultStrategy), // Owner
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.RequestRedeem7540) {
            hookAddress = address(requestRedeem7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to request redeem
                address(superVaultStrategy), // Owner
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.ApproveAndRequestDeposit7540) {
            hookAddress = address(approveAndRequestDeposit7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                superVault.asset(), // Address of the token to approve
                amountToInvest, // Amount to request deposit
                address(superVaultStrategy), // Owner
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.CancelDepositRequest7540) {
            hookAddress = address(cancelDepositRequest7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.CancelRedeemRequest7540) {
            hookAddress = address(cancelRedeemRequest7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.ClaimCancelDepositRequest7540) {
            hookAddress = address(claimCancelDepositRequest7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.ClaimCancelRedeemRequest7540) {
            hookAddress = address(claimCancelRedeemRequest7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.Withdraw7540) {
            hookAddress = address(withdraw7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to withdraw
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy), // Owner
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.CancelRedeem) {
            hookAddress = address(cancelRedeemHook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                address(superVaultStrategy) // Controller
            );
        } else if (hookType == HookType.SuperVaultWithdraw7540) {
            hookAddress = address(superVaultWithdraw7540Hook);
            hookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Address of the yield source
                amountToInvest, // Amount to withdraw
                address(superVaultStrategy), // Receiver
                address(superVaultStrategy), // Owner
                address(superVaultStrategy) // Controller
            );
        }
    }

    function superVaultStrategy_fulfillRedeemRequests_clamped(
        uint256 redeemAmount
    ) public {
        // Find a controller that has pending redeem requests
        address selectedController = _getActor();
        uint256 pendingAmount = superVaultStrategy.pendingRedeemRequest(
            selectedController
        );

        // Clamp using the actor's pending amount
        uint256 actualRedeemAmount = redeemAmount % (pendingAmount + 1);

        address[] memory controllers = new address[](1);
        controllers[0] = selectedController;

        // Determine yield source type from currently active yield source
        YieldSourceType activeYieldSourceType = _getYieldSourceTypeFromAddress(
            _getYieldSource()
        );
        address redeemHook = _getRedeemHookForType(activeYieldSourceType);

        // Create realistic hook calldata for redeem operation
        bytes memory redeemHookCalldata;

        if (
            activeYieldSourceType == YieldSourceType.ERC4626 ||
            activeYieldSourceType == YieldSourceType.ERC5115
        ) {
            // ERC4626/ERC5115 Layout: bytes32 oracleId, address yieldSource, address owner, uint256 shares, bool usePrevAmount
            redeemHookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Current active yield source
                address(superVaultStrategy), // Owner (strategy owns the yield source shares)
                actualRedeemAmount, // Amount to redeem (matches controller's pending request)
                false // Don't use previous hook amount
            );
        } else {
            // ERC7540 Layout: bytes32 oracleId, address yieldSource, uint256 shares, bool usePrevAmount
            redeemHookCalldata = abi.encodePacked(
                bytes32(0), // yieldSourceOracleId placeholder
                _getYieldSource(), // Current active yield source
                actualRedeemAmount, // Amount to redeem (matches controller's pending request)
                false // Don't use previous hook amount
            );
        }

        // Create arrays for FulfillArgs
        address[] memory hooks = new address[](1);
        hooks[0] = redeemHook;

        bytes[] memory hookCalldata = new bytes[](1);
        hookCalldata[0] = redeemHookCalldata;

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = 1; // @audit Allow max losse amount matching the actual redeem

        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0); // Empty proof for UnsafeSuperVaultAggregator

        bytes32[][] memory strategyProofs = new bytes32[][](1);
        strategyProofs[0] = new bytes32[](0); // Empty proof

        // Create the FulfillArgs struct
        ISuperVaultStrategy.FulfillArgs memory fulfillArgs = ISuperVaultStrategy
            .FulfillArgs({
                controllers: controllers,
                hooks: hooks,
                hookCalldata: hookCalldata,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: globalProofs,
                strategyProofs: strategyProofs
            });

        // Execute the function
        superVaultStrategy_fulfillRedeemRequests(fulfillArgs);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function superVaultStrategy_executeHooks(
        ISuperVaultStrategy.ExecuteArgs memory args
    ) public payable asAdmin {
        superVaultStrategy.executeHooks{value: msg.value}(args);

        executeHooksSuccess = true;
    }

    /// @dev Property: superVaultStrategy does not incur loss on fulfillment
    function superVaultStrategy_fulfillRedeemRequests(
        ISuperVaultStrategy.FulfillArgs memory args
    ) public updateGhostsWithOpType(OpType.FULFILL) {
        uint256 summedExpectedAssets;
        for (uint256 i; i < args.expectedAssetsOrSharesOut.length; i++) {
            summedExpectedAssets += args.expectedAssetsOrSharesOut[i];
        }

        // no need to prank because called as admin address(this)
        superVaultStrategy.fulfillRedeemRequests(args);

        uint256 assetBalanceAfter = MockERC20(superVault.asset()).balanceOf(
            address(superVaultStrategy)
        );

        gte(
            assetBalanceAfter,
            summedExpectedAssets,
            "strategy incurs loss on fulfillment"
        );
    }

    // Functions that require SuperGovernor access
    /// @dev removed because we're bypassing hook validation
    // function superVaultAggregator_setHooksRootUpdateTimelock(
    //     uint256 newTimelock
    // ) public asAdmin {
    //     superVaultAggregator.setHooksRootUpdateTimelock(newTimelock);
    // }

    /// @dev removed because we're bypassing hook validation
    // function superVaultAggregator_proposeGlobalHooksRoot(
    //     bytes32 newRoot
    // ) public asAdmin {
    //     superVaultAggregator.proposeGlobalHooksRoot(newRoot);
    // }

    /// @dev removed because we're bypassing hook validation
    // function superVaultAggregator_executeGlobalHooksRootUpdate()
    //     public
    //     asAdmin
    // {
    //     superVaultAggregator.executeGlobalHooksRootUpdate();
    // }

    /// @dev removed because we're bypassing hook validation
    // function superVaultAggregator_setGlobalHooksRootVetoStatus(
    //     bool vetoed
    // ) public asAdmin {
    //     superVaultAggregator.setGlobalHooksRootVetoStatus(vetoed);
    // }

    /// @dev removed because we're bypassing hook validation
    // function superVaultAggregator_setStrategyHooksRootVetoStatus(
    //     address strategy,
    //     bool vetoed
    // ) public asAdmin {
    //     superVaultAggregator.setStrategyHooksRootVetoStatus(strategy, vetoed);
    // }

    function superVaultAggregator_changePrimaryManager(
        address strategy,
        address newManager
    ) public asAdmin {
        superVaultAggregator.changePrimaryManager(strategy, newManager);
    }

    /// @dev won't achieve coverage until issue outlined here is resolved: https://github.com/Recon-Fuzz/superform-review/issues/5
    function superVaultAggregator_slashStake(
        address manager,
        uint256 amount
    ) public asAdmin {
        superVaultAggregator.slashStake(manager, amount);
    }

    /// Helpers

    function _requestedSharesForControllers(
        address[] memory controllers
    ) internal returns (uint256) {
        uint256 totalRequested;
        for (uint256 i; i < controllers.length; i++) {
            totalRequested += superVault.pendingRedeemRequest(
                0,
                controllers[i]
            );
        }

        return totalRequested;
    }

    function _sumSuperVaultValsForControllers(
        address[] memory controllers
    )
        internal
        view
        returns (uint256 sumAccumulatorShares, uint256 sumAccumulatorCostBasis)
    {
        for (uint256 i; i < controllers.length; i++) {
            sumAccumulatorShares += superVaultStrategy
                .getSuperVaultState(controllers[i])
                .accumulatorShares;
            sumAccumulatorCostBasis += superVaultStrategy
                .getSuperVaultState(controllers[i])
                .accumulatorCostBasis;
        }
    }

    function _claimableMoreThanInvested(
        uint256 totalAmountToDeposit
    ) internal returns (bool) {
        address[] memory actors = _getActors();
        uint256 totalClaimable;
        for (uint256 i; i < actors.length; i++) {
            uint256 claimableRedemptions = superVault.claimableRedeemRequest(
                0,
                actors[i]
            );
            uint256 claimableRedemptionsAsAssets = superVault.convertToAssets(
                claimableRedemptions
            );
            totalClaimable += claimableRedemptionsAsAssets;
        }

        uint256 currentStrategyBalance = MockERC20(superVault.asset())
            .balanceOf(address(superVaultStrategy));

        // Don't allow investing more than the claimable amount
        if (totalAmountToDeposit > totalClaimable) {
            return true;
        }

        // Ensure strategy has sufficient assets remaining after investment to cover claimable amounts
        uint256 remainingStrategyBalance = currentStrategyBalance -
            totalAmountToDeposit;
        if (remainingStrategyBalance < totalClaimable) {
            return true;
        }

        return false;
    }
}
