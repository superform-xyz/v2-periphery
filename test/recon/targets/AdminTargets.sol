// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// External dependencies
import { vm } from "@chimera/Hevm.sol";
import { Panic } from "@recon/Panic.sol";
import { MockERC20 } from "@recon/MockERC20.sol";
import { BaseTargetFunctions } from "@chimera/BaseTargetFunctions.sol";

// System dependencies
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { ISuperVaultStrategy } from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";

// Test dependencies
import { MockERC7540Tester } from "test/recon/mocks/MockERC7540Tester.sol";
import { YieldSourceType } from "test/recon/managers/YieldManager.sol";
import { IStandardizedYield } from "@superform-v2-core/src/vendor/pendle/IStandardizedYield.sol";
import { BeforeAfter, OpType } from "../BeforeAfter.sol";
import { Properties } from "../Properties.sol";

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
    )
        public
        payable
    {
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
        ISuperVaultStrategy.ExecuteArgs memory executeArgs = ISuperVaultStrategy.ExecuteArgs({
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
            uint256 clampedAmount =
                amountsToInvest[i] % (MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy)) + 1);

            // Get the hook address and calldata
            (address hookAddress, bytes memory hookCalldata) =
                _getHookAddressAndCalldata(hookType, clampedAmount, usePrevHookAmounts[i]);

            executeArgs.hooks[i] = hookAddress;
            executeArgs.hookCalldata[i] = hookCalldata;
            executeArgs.expectedAssetsOrSharesOut[i] = clampedAmount;
            executeArgs.globalProofs[i] = new bytes32[](1);
            executeArgs.strategyProofs[i] = new bytes32[](1);

            totalAmountToDeposit += clampedAmount;
        }

        // Check that amount to be invested is less than the claimable assets so that it doesn't reinvest and prevent
        // users from claiming
        if (_claimableMoreThanInvested(totalAmountToDeposit)) return;

        // Execute all hooks
        this.superVaultStrategy_executeHooks{ value: msg.value }(executeArgs);

        executeHooksClampedSuccess = true;
    }

    function _getHookAddressAndCalldata(
        HookType hookType,
        uint256 amountToInvest,
        bool usePrevHookAmount
    )
        internal
        view
        returns (address hookAddress, bytes memory hookCalldata)
    {
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
        }
    }

    function superVaultStrategy_fulfillRedeemRequests_clamped(uint256 redeemAmount) public {
        // Find a controller that has pending redeem requests
        address selectedController = _getActor();

        address[] memory controllers = new address[](1);
        controllers[0] = selectedController;

        uint256 balanceBefore = MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        _executeRedeemFulfillment(redeemAmount, controllers);

        uint256 balanceAfter = MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        gte(balanceAfter, balanceBefore, "strategy incurs loss on fulfillment");
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function superVaultStrategy_executeHooks(ISuperVaultStrategy.ExecuteArgs memory args) public payable asAdmin {
        superVaultStrategy.executeHooks{ value: msg.value }(args);

        executeHooksSuccess = true;
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
        address newManager,
        address feeRecipient
    )
        public
        asAdmin
    {
        superVaultAggregator.changePrimaryManager(strategy, newManager, feeRecipient);
    }

    /// Helpers

    /// @dev Property: superVaultStrategy does not incur loss on fulfillment
    function superVaultStrategy_fulfillRedeemRequests(
        uint256 redeemShares,
        address[] memory controllers
    )
        public
        updateGhostsWithOpType(OpType.FULFILL)
    {
        uint256 assetBalanceBefore = IERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        _executeRedeemFulfillment(redeemShares, controllers);

        uint256 assetBalanceAfter = IERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        gte(assetBalanceAfter, assetBalanceBefore, "strategy incurs loss on fulfillment");

        fulfillRedeemRequestsSuccess = true;
    }

    /// @dev Same as superVaultStrategy_fulfillRedeemRequests but with lowered exepectedAssetsOrSharesOut so that hook
    /// execution goes through
    function superVaultStrategy_fulfillRedeemRequests_WithLoss(
        uint256 lossOnWithdraw,
        uint256 redeemShares,
        address[] memory controllers
    )
        public
    {
        uint256 assetBalanceBefore = IERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        _executeRedeemFulfillmentWithLoss(lossOnWithdraw, redeemShares, controllers);

        uint256 assetBalanceAfter = IERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        gte(assetBalanceAfter, assetBalanceBefore, "strategy incurs loss on fulfillment");

        fulfillRedeemRequestsSuccess = true;
    }

    function _requestedSharesForControllers(address[] memory controllers) internal view returns (uint256) {
        uint256 totalRequested;
        for (uint256 i; i < controllers.length; i++) {
            totalRequested += superVault.pendingRedeemRequest(0, controllers[i]);
        }

        return totalRequested;
    }

    function _claimableMoreThanInvested(uint256 totalAmountToDeposit) internal view returns (bool) {
        address[] memory actors = _getActors();
        uint256 totalClaimable;
        for (uint256 i; i < actors.length; i++) {
            uint256 claimableRedemptions = superVault.claimableRedeemRequest(0, actors[i]);
            uint256 claimableRedemptionsAsAssets = superVault.convertToAssets(claimableRedemptions);
            totalClaimable += claimableRedemptionsAsAssets;
        }

        uint256 currentStrategyBalance = MockERC20(superVault.asset()).balanceOf(address(superVaultStrategy));

        // Don't allow investing more than the claimable amount
        if (totalAmountToDeposit > totalClaimable) {
            return true;
        }

        // Ensure strategy has sufficient assets remaining after investment to cover claimable amounts
        uint256 remainingStrategyBalance = currentStrategyBalance - totalAmountToDeposit;
        if (remainingStrategyBalance < totalClaimable) {
            return true;
        }

        return false;
    }

    function _executeRedeemFulfillment(uint256 totalRedeemShares, address[] memory requestingUsers) internal {
        (uint256 expectedAssetsOut, address hookAddress, bytes memory hookData) =
            _convertSVStoUnderlyingShares(totalRedeemShares);

        address[] memory hooks = new address[](1);
        hooks[0] = hookAddress;

        bytes[] memory hooksDataArray = new bytes[](1);
        hooksDataArray[0] = hookData;

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = expectedAssetsOut;

        bytes[] memory hookCalldata = new bytes[](1);
        hookCalldata[0] = hookData;

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(hookAddress).inspect(hookData);

        superVaultStrategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooks,
                hookCalldata: hookCalldata,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: new bytes32[][](1),
                strategyProofs: new bytes32[][](1)
            })
        );

        uint256[] memory totalAssetsOut =
            calculateLiquidityOnlyFulfillment(superVaultStrategy, superVault.asset(), requestingUsers);

        // Fulfill the redemption requests from liquidity
        superVaultStrategy.fulfillRedeemRequests(requestingUsers, totalAssetsOut);
    }

    function _executeRedeemFulfillmentWithLoss(
        uint256 lossOnWithdraw,
        uint256 totalRedeemShares,
        address[] memory requestingUsers
    )
        internal
    {
        (uint256 expectedAssets,,) = _convertSVStoUnderlyingShares_WithLoss(totalRedeemShares, lossOnWithdraw);
        _executeRedeemHooksWithLoss(totalRedeemShares, lossOnWithdraw);

        uint256[] memory expectedAssetsArr = new uint256[](1);
        expectedAssetsArr[0] = expectedAssets;

        uint256[] memory totalAssetsOut =
            calculateAdjustedFulfillment(superVaultStrategy, requestingUsers, expectedAssetsArr);

        superVaultStrategy.fulfillRedeemRequests(requestingUsers, totalAssetsOut);
    }

    function _executeRedeemHooksWithLoss(uint256 totalRedeemShares, uint256 lossOnWithdraw) internal {
        (, address hookAddress, bytes memory hookData) =
            _convertSVStoUnderlyingShares_WithLoss(totalRedeemShares, lossOnWithdraw);

        address[] memory hooks = new address[](1);
        hooks[0] = hookAddress;

        bytes[] memory hooksDataArray = new bytes[](1);
        hooksDataArray[0] = hookData;

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = 1;

        bytes[] memory hookCalldata = new bytes[](1);
        hookCalldata[0] = hookData;

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(hookAddress).inspect(hookData);

        superVaultStrategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooks,
                hookCalldata: hookCalldata,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: new bytes32[][](1),
                strategyProofs: new bytes32[][](1)
            })
        );
    }

    function _convertSVStoUnderlyingShares_WithLoss(
        uint256 redeemShares,
        uint256 lossOnWithdraw
    )
        internal
        view
        returns (uint256 expectedAssetsOrSharesOut, address hookAddress, bytes memory hookData)
    {
        address underlyingVault = _getYieldSource();
        YieldSourceType activeYieldSourceType = _getYieldSourceTypeFromAddress(underlyingVault);

        uint256 sharesAsAssetsFromSV = superVault.convertToAssets(redeemShares);

        uint256 underlyingShares;
        if (activeYieldSourceType == YieldSourceType.ERC4626) {
            underlyingShares = IERC20(underlyingVault).balanceOf(address(superVaultStrategy));

            uint256 expectedAssets = IERC4626(underlyingVault).previewRedeem(underlyingShares);

            expectedAssetsOrSharesOut = expectedAssets - ((expectedAssets * lossOnWithdraw) / 10_000);

            hookAddress = address(redeem4626Hook);

            hookData =
                abi.encodePacked(bytes32(0), underlyingVault, address(superVaultStrategy), underlyingShares, false);
        } else if (activeYieldSourceType == YieldSourceType.ERC5115) {
            uint256 assetsPerShare = IStandardizedYield(underlyingVault).previewRedeem(superVault.asset(), 1e18);
            underlyingShares = Math.mulDiv(sharesAsAssetsFromSV, 1e18, assetsPerShare, Math.Rounding.Ceil);

            expectedAssetsOrSharesOut =
                IStandardizedYield(underlyingVault).previewRedeem(superVault.asset(), underlyingShares);

            hookAddress = address(redeem5115Hook);

            hookData =
                abi.encodePacked(bytes32(0), underlyingVault, address(superVaultStrategy), underlyingShares, false);
        } else {
            underlyingShares = MockERC7540Tester(underlyingVault).previewWithdraw(sharesAsAssetsFromSV);

            expectedAssetsOrSharesOut = MockERC7540Tester(underlyingVault).previewRedeem(underlyingShares);

            hookAddress = address(redeem7540Hook);

            hookData = abi.encodePacked(bytes32(0), underlyingVault, underlyingShares, false);
        }
    }

    function _convertSVStoUnderlyingShares(uint256 redeemShares)
        internal
        view
        returns (uint256 expectedAssetsOrSharesOut, address hookAddress, bytes memory hookData)
    {
        address underlyingVault = _getYieldSource();
        YieldSourceType activeYieldSourceType = _getYieldSourceTypeFromAddress(underlyingVault);

        uint256 sharesAsAssetsFromSV = superVault.convertToAssets(redeemShares);

        uint256 underlyingShares;
        if (activeYieldSourceType == YieldSourceType.ERC4626) {
            underlyingShares = IERC20(underlyingVault).balanceOf(address(superVaultStrategy));

            expectedAssetsOrSharesOut = IERC4626(underlyingVault).previewRedeem(underlyingShares);

            hookAddress = address(redeem4626Hook);

            hookData =
                abi.encodePacked(bytes32(0), underlyingVault, address(superVaultStrategy), underlyingShares, false);
        } else if (activeYieldSourceType == YieldSourceType.ERC5115) {
            uint256 assetsPerShare = IStandardizedYield(underlyingVault).previewRedeem(superVault.asset(), 1e18);
            underlyingShares = Math.mulDiv(sharesAsAssetsFromSV, 1e18, assetsPerShare, Math.Rounding.Ceil);

            expectedAssetsOrSharesOut =
                IStandardizedYield(underlyingVault).previewRedeem(superVault.asset(), underlyingShares);

            hookAddress = address(redeem5115Hook);

            hookData =
                abi.encodePacked(bytes32(0), underlyingVault, address(superVaultStrategy), underlyingShares, false);
        } else {
            underlyingShares = MockERC7540Tester(underlyingVault).previewWithdraw(sharesAsAssetsFromSV);

            expectedAssetsOrSharesOut = MockERC7540Tester(underlyingVault).previewRedeem(underlyingShares);

            hookAddress = address(redeem7540Hook);

            hookData = abi.encodePacked(bytes32(0), underlyingVault, underlyingShares, false);
        }
    }

    function _truncateToActualBalance(
        uint256 expectedShares,
        address underlyingVault,
        uint256 toleranceBps
    )
        internal
        view
        returns (uint256 adjustedShares)
    {
        YieldSourceType activeYieldSourceType = _getYieldSourceTypeFromAddress(_getYieldSource());

        address vaultShareToken;
        if (activeYieldSourceType == YieldSourceType.ERC7540) {
            vaultShareToken = MockERC7540Tester(_getYieldSource()).share();
        } else {
            vaultShareToken = underlyingVault;
        }

        uint256 actualBalance = IERC20(vaultShareToken).balanceOf(address(superVaultStrategy));
        if (actualBalance >= expectedShares) {
            // Balance is sufficient, no truncation needed
            return expectedShares;
        }

        // Calculate minimum acceptable balance based on tolerance
        uint256 minAcceptableBalance = expectedShares * (10_000 - toleranceBps) / 10_000;

        if (actualBalance < minAcceptableBalance) {
            revert();
        }

        // Balance is lower but within tolerance, truncate to actual
        return actualBalance;
    }
}
