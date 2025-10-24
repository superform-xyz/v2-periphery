// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {MockERC20} from "@recon/MockERC20.sol";
import {vm} from "@chimera/Hevm.sol";
import {ERC7540Properties} from "@properties-7540/ERC7540Properties.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ISuperVaultStrategy} from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";

import {OpType} from "test/recon/BeforeAfter.sol";
import {BeforeAfter} from "./BeforeAfter.sol";

abstract contract Properties is BeforeAfter, Asserts, ERC7540Properties {
    using Math for uint256;
    uint256 internal TOLERANCE = 10;

    /// @dev Property: oracle PPS doesn't change on deposit/mint/redeem/withdraw
    function property_oraclePPSDoesntChangeOnAddOrRemove() public {
        if (_currentOp == OpType.ADD || _currentOp == OpType.REMOVE) {
            eq(
                _before.oraclePPS,
                _after.oraclePPS,
                "deposit/withdrawal changes oracle PPS"
            );
        }
    }

    /// @dev Property: naive PPS doesn't change on deposit/mint
    // NOTE: removed because it's expected behavior that fulfillment burns shares but doesn't transfer assets to users so would change the naively calculated price
    // function property_naivePPSDoesntChangeOnDepositOrMint() public {
    //     if (
    //         (_currentOp == OpType.ADD) && _before.naivePPS != 0 // price starts as zero when no shares minted
    //     ) {
    //         gte(
    //             _after.naivePPS,
    //             _before.naivePPS,
    //             "deposit/mint cannot decrease naive PPS"
    //         );
    //     }
    // }

    /// @dev Property: naive PPS doesn't change on redeem/withdraw
    // NOTE: removed because it's expected behavior that fulfillment burns shares but doesn't transfer assets to users so would change the naively calculated price
    // function property_naivePPSDoesntChangeOnRedeemOrWithdraw() public {
    //     if (
    //         (_currentOp == OpType.REMOVE) && _before.naivePPS != 0 // price starts as zero when no shares minted
    //     ) {
    //         gte(
    //             _after.naivePPS,
    //             _before.naivePPS,
    //             "redeem/withdraw cannot decrease naive PPS"
    //         );
    //     }
    // }

    /// @dev Property: fulfillRedeemRequest doesn't change naive PPS
    // NOTE: removed because it's expected behavior that fulfillment burns shares but doesn't transfer assets to users so would change the naively calculated price
    // function property_naivePPSDoesntChangeOnRedeem() public {
    //     if (_currentOp == OpType.FULFILL) {
    //         eq(
    //             _before.naivePPS,
    //             _after.naivePPS,
    //             "fulfilling redemption changes naive PPS"
    //         );
    //     }
    // }

    /// @dev Property: maxRedeem and maxWithdraw should always be equivalent
    function property_maxRedeemMaxWithdrawSymmetry() public {
        uint256 maxWithdraw = superVault.maxWithdraw(_getActor());
        // convertToShares uses current price instead of avg from fulfillment
        uint256 withdrawPrice = superVaultStrategy.getAverageWithdrawPrice(
            _getActor()
        );
        uint256 maxWithdrawAsShares = maxWithdraw.mulDiv(
            superVault.PRECISION(),
            withdrawPrice,
            Math.Rounding.Floor
        );

        uint256 maxRedeem = superVault.maxRedeem(_getActor());

        eq(maxWithdrawAsShares, maxRedeem, "maxWithdrawAsShares != maxRedeem");
    }

    /// @dev Property: requestRedeem should never reduce SuperVault shares
    function property_totalSharesDontDecreaseOnRedemptionRequest() public {
        if (_currentOp == OpType.REQUEST) {
            eq(
                _before.summedTotalShares,
                _after.summedTotalShares,
                "requestRedeem should never reduce SuperVault shares"
            );
        }
    }

    /// @dev Property: `SuperVault::totalSupply` == SUM(user balances) + balanceOf(escrow)
    function property_shareSolvency() public {
        uint256 sumOfShares = _sumTotalShares();
        eq(superVault.totalSupply(), sumOfShares, "vault shares are insolvent");
    }

    /// @dev Property: balanceOf(escrow) >= SUM(controllers.pendingRedeemRequest)
    function property_escrowBalance() public {
        address[] memory actors = _getActors();

        uint256 escrowBalance = superVault.balanceOf(address(superVaultEscrow));
        uint256 pendingActorShares;
        for (uint256 i; i < actors.length; i++) {
            pendingActorShares += superVault.pendingRedeemRequest(0, actors[i]);
        }

        gte(
            escrowBalance,
            pendingActorShares,
            "balanceOf(escrow) < SUM(controllers.pendingRedeemRequest)"
        );
    }

    /// @dev Property: maxMint should be 0 when aggregator is paused
    function property_maxMintZeroWhenPaused() public {
        bool paused = superVaultAggregator.isStrategyPaused(
            address(superVaultStrategy)
        );
        uint256 maxMint = superVault.maxMint(_getActor());

        if (paused) {
            eq(maxMint, 0, "actor has nonzero maxMint when strategy is paused");
        }
    }

    /// @dev Property: maxDeposit should be 0 when strategy is paused
    function property_maxDepositZeroWhenPaused() public {
        bool paused = superVaultAggregator.isStrategyPaused(
            address(superVaultStrategy)
        );
        uint256 maxDeposit = superVault.maxDeposit(_getActor());

        if (paused) {
            eq(
                maxDeposit,
                0,
                "actor has nonzero maxDeposit when strategy is paused"
            );
        }
    }

    /// @dev Property: SUM(accumulatorShares) doesn't change on SuperVault share transfers
    function property_accumulatorSharesSolvency() public {
        if (_currentOp == OpType.TRANSFER) {
            eq(
                _before.summedAccumulatorShares,
                _after.summedAccumulatorShares, // TODO: think about way to handle transfer on recipient
                "SUM(accumulatorShares) changed on SuperVault share transfers"
            );
        }
    }

    /// @dev Property: SUM(accumulatorCostBasis) doesn't change on SuperVault share transfers
    function property_accumulatorCostBasisSolvency() public {
        if (_currentOp == OpType.TRANSFER) {
            eq(
                _before.summedAccumulatorCostBasis,
                _after.summedAccumulatorCostBasis,
                "SUM(accumulatorCostBasis) changed on SuperVault share transfers"
            );
        }
    }

    /// @dev Property: cancelRedeem should never alter the supply of SuperVault tokens
    function property_cancelDoesntChangeTotalSupply() public {
        if (_currentOp == OpType.CANCEL) {
            eq(
                _before.summedTotalShares,
                _after.summedTotalShares,
                "cancelRedeem should never alter the supply of SuperVault tokens"
            );
        }
    }

    /// @dev Property: if totalSupply > 0, then totalAssets > 0
    function property_assetBacking() public {
        uint256 summedTotalAssets = _sumStrategyAssets();

        if (superVault.totalSupply() > 0) {
            gt(
                summedTotalAssets,
                0,
                "if totalSupply > 0, then totalAssets > 0"
            );
        }
    }

    /// @dev Property: SUM(shares) * PPS == totalAssets
    function property_totalAssets() public {
        uint256 totalShares = _sumTotalShares();
        uint256 pps = superVaultAggregator.getPPS(address(superVaultStrategy));
        uint256 implicitTotalAssets = (totalShares * pps) /
            superVault.PRECISION();

        uint256 vaultTotalAssets = superVault.totalAssets();
        eq(
            implicitTotalAssets,
            vaultTotalAssets,
            "totalShares * pps != totalAssets"
        );
    }

    /// @dev Property: When a user requests a redemption and the PPS is >= the user PPS, user averageRequestPPS must not decrease
    function property_avgPPSDoesntDecrease() public {
        uint256 currentPrice = _before.oraclePPS;
        uint256 beforeAvgPPS = _before.state[_getActor()].averageRequestPPS;
        uint256 afterAvgPPS = _after.state[_getActor()].averageRequestPPS;

        if (_currentOp == OpType.REQUEST && currentPrice >= beforeAvgPPS) {
            gte(
                afterAvgPPS,
                beforeAvgPPS,
                "when a user requests a redemption and the PPS is >= the user PPS, user averageRequestPPS must not decrease"
            );
        }
    }

    /// @dev Property: previewMint and previewDeposit equivalence (from shares)
    function property_previewEquivalenceFromShares(uint256 shares) public {
        uint256 previewMintAssets = superVault.previewMint(shares);
        uint256 previewDepositShares = superVault.previewDeposit(
            previewMintAssets
        );
        uint256 price = superVaultStrategy.getStoredPPS();

        if (price > 0) {
            eq(
                shares,
                previewDepositShares,
                "previewMint and previewDeposit equivalence (from shares)"
            );
        }
    }

    /// @dev Property: previewMint and previewDeposit equivalence (from assets)
    function property_previewEquivalenceFromAssets(uint256 assets) public {
        uint256 previewDepositShares = superVault.previewDeposit(assets);
        uint256 previewMintAssets_under = superVault.previewMint(
            previewDepositShares
        );
        uint256 previewMintAssets_over = superVault.previewMint(
            previewDepositShares + 1
        );
        uint256 price = superVaultStrategy.getStoredPPS();

        if (price > 0) {
            gte(
                assets,
                previewMintAssets_under,
                "previewMint and previewDeposit equivalence under (from assets)"
            );

            lte(
                assets,
                previewMintAssets_over,
                "previewMint and previewDeposit equivalence over (from assets)"
            );
        }
    }

    /// @dev Property: previewMint is >= convertToAssets
    function property_comparePreviewMintAndConvertToAssets(
        uint256 shares
    ) public {
        uint256 previewMintAssets = superVault.previewMint(shares);
        uint256 convertToAssets = superVault.convertToAssets(shares);
        gte(
            previewMintAssets,
            convertToAssets,
            "previewMint is >= convertToAssets"
        );
    }

    /// @dev Property: convertToShares is >= previewDepositShares (equivalent without fees)
    function property_comparePreviewDepositAndConvertToShares(
        uint256 assets
    ) public {
        uint256 previewDepositShares = superVault.previewDeposit(assets);
        uint256 convertToShares = superVault.convertToShares(assets);
        gte(
            convertToShares,
            previewDepositShares,
            "convertToShares is higher than or equal to previewDepositShares (equivalent without fees)"
        );
    }

    // NOTE: Withdrawal properties are more nuanced, as we should ensure that no gain can be had and that losses are imputed to the controller receiving the assets

    /// @dev Property: After all redemptions are processed, the sum of all claimable is <= balance available
    function property_sumOfClaimable() public {
        address[] memory actors = _getActors();

        uint256 sumPending;
        uint256 sumClaimable;
        for (uint256 i; i < actors.length; i++) {
            sumPending += superVault.pendingRedeemRequest(0, actors[i]);
            sumClaimable += superVault.maxWithdraw(actors[i]);
        }

        uint256 strategyBalance = MockERC20(superVault.asset()).balanceOf(
            address(superVaultStrategy)
        );

        // precondition: all pending has been fulfilled
        if (sumPending == 0) {
            lte(
                sumClaimable,
                strategyBalance,
                "sum of all claimable is > balance available"
            );
        }
    }

    /// @dev Property: If the sum of assets in SuperVaultStrategy and yield strategies is 0, maxWithdraw should be 0
    function property_sumOfAssetsMaxWithdrawable() public {
        uint256 summedTotalAssets = _sumStrategyAssets();

        if (summedTotalAssets == 0) {
            uint256 maxWithdraw = superVault.maxWithdraw(_getActor());
            eq(
                maxWithdraw,
                0,
                "if sum of assets in SuperVaultStrategy and yield strategies is 0, maxWithdraw should be 0"
            );
        }
    }

    /// @dev Property: averageWithdrawPrice should never decrease when new redemptions are fulfilled at a higher PPS
    function property_avgPPSMonotonicity() public {
        if (
            _currentOp == OpType.FULFILL &&
            _before.oraclePPS > _before.state[_getActor()].averageRequestPPS && // fulfilled at a higher price
            _after.state[_getActor()].pendingRedeemRequest != 0 // redemptions have all been fulfilled/cancelled; avg gets reset to 0 in this case
        ) {
            gte(
                _after.state[_getActor()].averageRequestPPS,
                _before.state[_getActor()].averageRequestPPS,
                "averageWithdrawPrice should not decrease when fulfilled at a higher PPS"
            );
        }
    }

    /// @dev Property: state.accumulatorShares >= superVaultState[controllers[i]].pendingRedeemRequest for each user
    function property_accumulatorSharesGtPendingRequests() public {
        address[] memory actors = _getActors();

        for (uint256 i; i < actors.length; i++) {
            ISuperVaultStrategy.SuperVaultState
                memory state = superVaultStrategy.getSuperVaultState(actors[i]);
            gte(
                state.accumulatorShares,
                state.pendingRedeemRequest,
                "state.accumulatorShares < state.pendingRedeemRequest"
            );
        }
    }

    /// @dev Property: accumulatorShares is always accurately increased
    function property_accumulatorSharesIncrease() public {
        if (_currentOp == OpType.ADD) {
            uint256 accumulatorSharesBefore = _before
                .state[_getActor()]
                .accumulatorShares;
            uint256 accumulatorSharesAfter = _after
                .state[_getActor()]
                .accumulatorShares;
            uint256 actorSharesBefore = _before.superVaultShares[_getActor()];
            uint256 actorSharesAfter = _after.superVaultShares[_getActor()];
            eq(
                accumulatorSharesAfter - accumulatorSharesBefore,
                actorSharesAfter - actorSharesBefore,
                "accumulatorShares is always accurately updated"
            );
        }
    }

    /// @dev Property: accumulatorCostBasis is always accurately increased
    function property_accumulatorCostBasisIncrease() public {
        if (_currentOp == OpType.ADD) {
            uint256 accumulatorCostBasisBefore = _before
                .state[_getActor()]
                .accumulatorCostBasis;
            uint256 accumulatorCostBasisAfter = _after
                .state[_getActor()]
                .accumulatorCostBasis;
            eq(
                accumulatorCostBasisAfter - accumulatorCostBasisBefore,
                _after.strategyAssetBalance - _before.strategyAssetBalance,
                "accumulatorShares is always accurately updated"
            );
        }
    }

    /// @dev Property: redemptions only burn the requested amount of shares (within tolerance range)
    function property_fulfillOnlyBurnsRequestedAmount() public {
        uint256 TOLERANCE_CONSTANT = 10 wei; // taken from SuperVaultStrategy

        if (_currentOp == OpType.FULFILL) {
            uint256 pendingRedeemDelta = _before.summedPendingRedeem -
                _after.summedPendingRedeem;
            uint256 totalSupplyDelta = _before.summedTotalShares -
                _after.summedTotalShares;

            // Check that burned amount is within tolerance of requested amount
            if (totalSupplyDelta < pendingRedeemDelta) {
                // Burned less than requested - check within tolerance
                gte(
                    totalSupplyDelta,
                    pendingRedeemDelta - TOLERANCE_CONSTANT,
                    "burned less than requested beyond tolerance"
                );
            } else {
                // Burned more than requested - check within tolerance
                lte(
                    totalSupplyDelta,
                    pendingRedeemDelta + TOLERANCE_CONSTANT,
                    "burned more than requested beyond tolerance"
                );
            }
        }
    }

    /// @dev Property: accumulatorShares decreases by the exact amounts requested when fulfilling redemptions
    function property_accumulatorSharesDecreaseOnFulfill_exact() public {
        if (_currentOp == OpType.FULFILL) {
            uint256 accumulatorSharesDelta = _before.summedAccumulatorShares -
                _after.summedAccumulatorShares;
            uint256 totalSharesDelta = _before.summedTotalShares -
                _after.summedTotalShares;
            eq(
                accumulatorSharesDelta,
                totalSharesDelta,
                "accumulatorShares decreases by the exact amounts requested when fulfilling redemptions"
            );
        }
    }

    function property_accumulatorSharesDecreaseOnFulfill_with_tolerance()
        public
    {
        if (_currentOp == OpType.FULFILL) {
            uint256 accumulatorSharesDelta = _before.summedAccumulatorShares -
                _after.summedAccumulatorShares;
            uint256 totalSharesDelta = _before.summedTotalShares -
                _after.summedTotalShares;
            if (accumulatorSharesDelta >= totalSharesDelta) {
                lte(
                    accumulatorSharesDelta - totalSharesDelta,
                    TOLERANCE,
                    "accumulatorShares decreases by more than TOLERANCE when fulfilling redemptions"
                );
            } else {
                lte(
                    totalSharesDelta - accumulatorSharesDelta,
                    TOLERANCE,
                    "accumulatorShares decreases by less than TOLERANCE when fulfilling redemptions"
                );
            }
        }
    }

    /// Optimization Setters

    function setpreviewAssetsGreater(uint256 shares) public {
        uint256 previewMintAssets = superVault.previewMint(shares);
        uint256 previewDepositAssets = superVault.previewDeposit(
            previewMintAssets
        );

        if (previewMintAssets > previewDepositAssets) {
            previewMintAssetsGreater = int256(previewMintAssets);
        } else {
            previewDepositAssetsGreater = int256(previewDepositAssets);
        }
    }

    function setPreviewSharesGreater(uint256 assets) public {
        uint256 previewDepositShares = superVault.previewDeposit(assets);
        uint256 previewMintShares = superVault.previewMint(
            previewDepositShares
        );

        if (previewDepositShares > previewMintShares) {
            previewDepositSharesGreater =
                int256(previewDepositShares) -
                int256(previewMintShares);
        } else {
            previewMintSharesGreater =
                int256(previewMintShares) -
                int256(previewDepositShares);
        }
    }

    function setFulfilledDifference() public {
        if (_currentOp == OpType.FULFILL) {
            uint256 pendingRedeemDelta = _before.summedPendingRedeem -
                _after.summedPendingRedeem;
            uint256 totalSupplyDelta = _before.summedTotalShares -
                _after.summedTotalShares;

            // Check that burned amount is within tolerance of requested amount
            if (totalSupplyDelta < pendingRedeemDelta) {
                // Burned less than requested
                int256 burnedLessThanRequested = int256(pendingRedeemDelta) -
                    int256(totalSupplyDelta);
            } else {
                // Burned more than requested
                int256 burnedMoreThanRequested = int256(totalSupplyDelta) -
                    int256(pendingRedeemDelta);
            }
        }
    }

    /// Optimization Tests

    /// @dev Optimize the difference between the amount of assets in the system and claimable assets
    function optimize_maxDustAccumulation() public view returns (int256) {
        address[] memory actors = _getActors();

        uint256 summedClaimableRedemptionsAsAssets;
        for (uint256 i; i < actors.length; i++) {
            uint256 claimableRedemptions = superVault.claimableRedeemRequest(
                0,
                actors[i]
            );
            summedClaimableRedemptionsAsAssets += superVault.convertToAssets(
                claimableRedemptions
            );
        }

        uint256 totalAssets = _sumStrategyAssets();

        return int256(totalAssets) - int256(summedClaimableRedemptionsAsAssets);
    }

    /// @dev Optimize the difference between the amount of claimable assets and assets in the system
    function optimize_moreClaimableThanHeldDifference()
        public
        view
        returns (int256)
    {
        address[] memory actors = _getActors();

        uint256 summedClaimableRedemptionsAsAssets;
        for (uint256 i; i < actors.length; i++) {
            summedClaimableRedemptionsAsAssets += superVault.maxWithdraw(
                actors[i]
            );
        }

        uint256 totalAssets = _sumStrategyAssets();

        if (summedClaimableRedemptionsAsAssets > totalAssets) {
            return
                int256(summedClaimableRedemptionsAsAssets) -
                int256(totalAssets);
        }
    }

    function optimize_burnMoreThanRequestedInRedemption()
        public
        view
        returns (int256)
    {
        return burnedMoreThanRequested;
    }

    function optimize_burnLessThanRequestedInRedemption()
        public
        view
        returns (int256)
    {
        return burnedLessThanRequested;
    }

    // function optimize_previewMintSharesGreater() public view returns (int256) {
    //     return previewMintSharesGreater;
    // }

    // function optimize_previewDepositSharesGreater()
    //     public
    //     view
    //     returns (int256)
    // {
    //     return previewDepositSharesGreater;
    // }

    // function optimize_previewMintAssetsGreater() public view returns (int256) {
    //     return previewMintAssetsGreater;
    // }

    // function optimize_previewDepositAssetsGreater()
    //     public
    //     view
    //     returns (int256)
    // {
    //     return previewDepositAssetsGreater;
    // }

    function optimize_assetBackingDifference() public view returns (int256) {
        uint256 summedTotalAssets = _sumStrategyAssets();
        uint256 totalSupply = superVault.totalSupply();

        if (summedTotalAssets == 0 && totalSupply > 0) {
            return int256(totalSupply);
        }
    }

    // Canaries

    // function canary_deployedNewVault() public {
    //     t(!hasDeployedNewVault, "deployed new vault canary");
    // }

    // ERC7540 Properties from erc7540-reusable-properties

    /// @dev Property 7540-1: convertToAssets(totalSupply) == totalAssets unless price is 0.0
    function crytic_erc7540_1() public stateless {
        actor = _getActor();
        t(
            erc7540_1(address(superVault)),
            "ERC7540-1: convertToAssets(totalSupply) == totalAssets failed"
        );
    }

    /// @dev Property 7540-2: convertToShares(totalAssets) == totalSupply unless price is 0.0
    function crytic_erc7540_2() public stateless {
        actor = _getActor();
        t(
            erc7540_2(address(superVault)),
            "ERC7540-2: convertToShares(totalAssets) == totalSupply failed"
        );
    }

    /// @dev Property 7540-3: max* never reverts
    function crytic_erc7540_3() public stateless {
        actor = _getActor();
        t(
            erc7540_3(address(superVault)),
            "ERC7540-3: max* functions should never revert"
        );
    }

    /// @dev Property 7540-4: claiming more than max always reverts
    function crytic_erc7540_4_deposit(uint256 amt) public stateless {
        actor = _getActor();
        t(
            erc7540_4_deposit(address(superVault), amt),
            "ERC7540-4: deposit with more than max should revert"
        );
    }

    function crytic_erc7540_4_mint(uint256 amt) public stateless {
        actor = _getActor();
        t(
            erc7540_4_mint(address(superVault), amt),
            "ERC7540-4: mint with more than max should revert"
        );
    }

    function crytic_erc7540_4_withdraw(uint256 amt) public stateless {
        actor = _getActor();
        t(
            erc7540_4_withdraw(address(superVault), amt),
            "ERC7540-4: withdraw with more than max should revert"
        );
    }

    function crytic_erc7540_4_redeem(uint256 amt) public stateless {
        actor = _getActor();
        t(
            erc7540_4_redeem(address(superVault), amt),
            "ERC7540-4: redeem with more than max should revert"
        );
    }

    /// @dev Property 7540-5: requestRedeem reverts if the share balance is less than amount
    function crytic_erc7540_5(uint256 shares) public stateless {
        actor = _getActor();
        t(
            erc7540_5(address(superVault), address(superVault), shares),
            "ERC7540-5: requestRedeem should revert if insufficient share balance"
        );
    }

    /// @dev Property 7540-6: preview* always reverts
    // NOTE: previewMint and previewDeposit don't revert because deposits are sync
    // function crytic_erc7540_6() public {
    //     actor = _getActor();
    //     t(
    //         erc7540_6(address(superVault)),
    //         "ERC7540-6: preview* functions should always revert"
    //     );
    // }

    /// @dev Property 7540-7: if max[method] > 0, then [method] (max) should not revert
    // NOTE: maxDeposit always returns type(uint256).max
    // function crytic_erc7540_7_deposit(uint256 amt) public {
    //     actor = _getActor();
    //     t(
    //         erc7540_7_deposit(address(superVault), amt),
    //         "ERC7540-7: deposit should not revert when amount <= max"
    //     );
    // }

    // NOTE: maxMint always returns type(uint256).max
    // function crytic_erc7540_7_mint(uint256 amt) public stateless {
    //     actor = _getActor();
    //     t(
    //         erc7540_7_mint(address(superVault), amt),
    //         "ERC7540-7: mint should not revert when amount <= max"
    //     );
    // }

    function crytic_erc7540_7_withdraw(uint256 amt) public stateless {
        actor = _getActor();
        t(
            erc7540_7_withdraw(address(superVault), amt),
            "ERC7540-7: withdraw should not revert when amount <= max"
        );
    }

    // NOTE: this implements the check from ERC7540Properties directly because SuperVault logic implementation allows amt to be nonzero but round down to 0 when assets passed into redeem are calculated
    function crytic_erc7540_7_redeem(uint256 amt) public stateless {
        actor = _getActor();

        uint256 maxRedeem = superVault.maxRedeem(actor);
        amt = between(amt, 0, maxRedeem);

        if (amt == 0) {
            return; // Skip
        }

        uint256 averageWithdrawPrice = superVaultStrategy
            .getAverageWithdrawPrice(actor);

        // calculates assets in the same way as redeem to confirm that a nonzero amount is being requested
        uint256 assets = amt.mulDiv(
            averageWithdrawPrice,
            superVault.PRECISION(),
            Math.Rounding.Floor
        );

        try superVault.redeem(amt, actor, actor) {} catch {
            if (amt > 0 && assets > 0) {
                t(
                    false,
                    "ERC7540-7: redeem should not revert when amount <= max"
                );
            }
        }
    }
}
