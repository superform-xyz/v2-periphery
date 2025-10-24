// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Recon deps
import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import {Panic} from "@recon/Panic.sol";
import {MockERC20} from "@recon/MockERC20.sol";

import "src/SuperVault/SuperVault.sol";

import {BeforeAfter, OpType} from "test/recon/BeforeAfter.sol";
import {Properties} from "../Properties.sol";

/// @dev All receivers are inherently clamped to actors to make checking properties easier
abstract contract SuperVaultTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    function superVault_requestRedeem_clamped(uint256 shares) public {
        shares %= superVault.balanceOf(_getActor()) + 1;

        superVault_requestRedeem(shares);
    }

    function superVault_redeem_clamped(uint256 shares) public {
        uint256 claimableAssets = superVault.maxWithdraw(_getActor());
        uint256 claimableShares = superVault.convertToShares(claimableAssets);

        shares %= claimableShares + 1;

        superVault_redeem(shares);
    }

    function superVault_withdraw_clamped(uint256 assets) public {
        uint256 claimableAssets = superVault.maxWithdraw(_getActor());
        assets %= claimableAssets + 1;

        superVault_withdraw(assets);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function superVault_approve(address spender, uint256 value) public asActor {
        superVault.approve(spender, value);
    }

    function superVault_burnShares(uint256 amount) public asActor {
        superVault.burnShares(amount);
    }

    /// @dev Property: pendingRedeemRequest should be 0 after a user calls cancelRedeem
    /// @dev Property: averageRequestPPS should be 0 after a user calls cancelRedeem
    /// @dev Property: user shouldn't receive more than convertToAssets(pendingRedeemRequest) after cancelRedeem
    function superVault_cancelRedeem()
        public
        updateGhostsWithOpType(OpType.CANCEL)
    {
        uint256 pendingRedeemRequestsBefore = superVault.pendingRedeemRequest(
            0,
            _getActor()
        );
        uint256 pendingRedeemRequestsAsAssets = superVault.convertToAssets(
            pendingRedeemRequestsBefore
        );
        uint256 balanceBefore = MockERC20(superVault.asset()).balanceOf(
            _getActor()
        );

        vm.prank(_getActor());
        superVault.cancelRedeem(_getActor());

        uint256 pendingRedeemRequestsAfter = superVault.pendingRedeemRequest(
            0,
            _getActor()
        );
        uint256 averageRequestPPS = superVaultStrategy
            .getSuperVaultState(_getActor())
            .averageRequestPPS;
        uint256 balanceAfter = MockERC20(superVault.asset()).balanceOf(
            _getActor()
        );

        // Checks
        eq(
            pendingRedeemRequestsAfter,
            0,
            "pendingRedeemRequests should be 0 after cancelling a redemption"
        );
        eq(
            averageRequestPPS,
            0,
            "averageRequestPPS should be 0 after cancelling a redemption"
        );
        lte(
            balanceAfter - balanceBefore,
            pendingRedeemRequestsAsAssets,
            "user shouldn't receive more than convertToAssets(pendingRedeemRequest) after cancelRedeem"
        );
    }

    /// @dev Property: previewDeposit returns the correct amounts compared to executing a deposit
    function superVault_deposit(
        uint256 assets
    ) public updateGhostsWithOpType(OpType.ADD) {
        uint256 previewShares = superVault.previewDeposit(assets);

        vm.prank(_getActor());
        uint256 shares = superVault.deposit(assets, _getActor());

        eq(
            previewShares,
            shares,
            "previewDeposit returns the correct amounts compared to executing a deposit"
        );
    }

    /// @dev Property: previewMint returns the correct amounts compared to executing a mint
    function superVault_mint(
        uint256 shares
    ) public updateGhostsWithOpType(OpType.ADD) {
        uint256 previewMint = superVault.previewMint(shares);

        vm.prank(_getActor());
        uint256 assets = superVault.mint(shares, _getActor());

        eq(
            assets,
            previewMint,
            "previewMint returns the correct amounts compared to executing a mint"
        );
    }

    function superVault_invalidateNonce(bytes32 nonce) public asActor {
        superVault.invalidateNonce(nonce);
    }

    function superVault_redeem(
        uint256 shares
    ) public updateGhostsWithOpType(OpType.REMOVE) asActor {
        superVault.redeem(shares, _getActor(), _getActor());
    }

    function superVault_withdraw(
        uint256 assets
    ) public updateGhostsWithOpType(OpType.REMOVE) asActor {
        superVault.withdraw(assets, _getActor(), _getActor());
    }

    function superVault_requestRedeem(
        uint256 shares
    ) public updateGhostsWithOpType(OpType.REQUEST) asActor {
        superVault.requestRedeem(shares, _getActor(), _getActor());
    }

    function superVault_setOperator(
        uint256 entropy,
        bool approved
    ) public asActor {
        address operator = _getRandomActor(entropy);
        superVault.setOperator(operator, approved);
    }

    /// @dev Propery: _update should never revert
    /// @dev Property: Transfers of shares should transfer the exact amount of accumulatorShares to the recipient
    /// @dev Property: Transfers of shares should transfer the exact amount of accumulatorCostBasis to the recipient
    // NOTE: _update only gets called on transfer of Vault shares
    function superVault_transfer(
        uint256 entropy,
        uint256 value
    ) public updateGhostsWithOpType(OpType.TRANSFER) {
        address to = _getRandomActor(entropy);
        ISuperVaultStrategy.SuperVaultState
            memory stateSenderBefore = superVaultStrategy.getSuperVaultState(
                _getActor()
            );
        ISuperVaultStrategy.SuperVaultState
            memory stateRecipientBefore = superVaultStrategy.getSuperVaultState(
                to
            );

        vm.prank(_getActor());
        try superVault.transfer(to, value) {
            ISuperVaultStrategy.SuperVaultState
                memory stateSenderAfter = superVaultStrategy.getSuperVaultState(
                    _getActor()
                );
            ISuperVaultStrategy.SuperVaultState
                memory stateRecipientAfter = superVaultStrategy
                    .getSuperVaultState(to);

            eq(
                stateSenderBefore.accumulatorShares -
                    stateSenderAfter.accumulatorShares,
                stateRecipientAfter.accumulatorShares -
                    stateRecipientBefore.accumulatorShares,
                "shares are lost on transfer"
            );
            eq(
                stateSenderBefore.accumulatorCostBasis -
                    stateSenderAfter.accumulatorCostBasis,
                stateRecipientAfter.accumulatorCostBasis -
                    stateRecipientBefore.accumulatorCostBasis,
                "cost basis is lost on transfer"
            );
        } catch (bytes memory err) {
            bool expectedError;
            expectedError = checkError(
                err,
                "ERC20InsufficientBalance(address,uint256,uint256)"
            );
            t(expectedError, "_update should never revert in transfer");
        }
    }

    /// @dev Propery: _update should never revert
    // NOTE: _update only gets called on transfer of Vault shares
    function superVault_transferFrom(
        uint256 entropyFrom,
        uint256 entropyTo,
        uint256 value
    ) public updateGhostsWithOpType(OpType.TRANSFER) {
        address from = _getRandomActor(entropyFrom);
        address to = _getRandomActor(entropyTo);

        vm.prank(_getActor());
        try superVault.transferFrom(from, to, value) {} catch (
            bytes memory err
        ) {
            bool expectedError;
            expectedError =
                checkError(
                    err,
                    "ERC20InsufficientBalance(address,uint256,uint256)"
                ) ||
                checkError(
                    err,
                    "ERC20InsufficientAllowance(address,uint256,uint256)"
                );
            t(expectedError, "_update should never revert in transferFrom");
        }
    }

    /// @dev removed because signature components not fuzzable
    // function superVault_authorizeOperator(
    //     address controller,
    //     address operator,
    //     bool approved,
    //     bytes32 nonce,
    //     uint256 deadline,
    //     bytes memory signature
    // ) public asActor {
    //     superVault.authorizeOperator(
    //         controller,
    //         operator,
    //         approved,
    //         nonce,
    //         deadline,
    //         signature
    //     );
    // }
}
