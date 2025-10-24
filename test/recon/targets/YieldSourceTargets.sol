// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import {Properties} from "../Properties.sol";
import {MockERC4626Tester, FunctionType, RevertType} from "../mocks/MockERC4626Tester.sol";
import {MockERC5115Tester, RevertType as RevertType5115} from "../mocks/MockERC5115Tester.sol";
import {MockERC7540Tester} from "../mocks/MockERC7540Tester.sol";
import {YieldSourceType} from "../managers/YieldManager.sol";

/// @dev Target functions for yield source testers which are used as yield sources in SuperVaultStrategy
abstract contract YieldSourceTargets is BaseTargetFunctions, Properties {
    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    /// ERC20 functions (available across all types as they inherit from MockERC20) ///
    function yieldSource_approve(
        address spender,
        uint256 value
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).approve(spender, value);
        } else if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).approve(spender, value);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).approve(spender, value);
        }
    }

    function yieldSource_setDecimalsOffset(
        uint8 targetDecimalsOffset
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).setDecimalsOffset(
                targetDecimalsOffset
            );
        }
        // Note: ERC5115 and ERC7540 don't have setDecimalsOffset function
    }

    function yieldSource_transfer(address to, uint256 value) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).transfer(to, value);
        } else if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).transfer(to, value);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).transfer(to, value);
        }
    }

    function yieldSource_transferFrom(
        address from,
        address to,
        uint256 value
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).transferFrom(from, to, value);
        } else if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).transferFrom(from, to, value);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).transferFrom(from, to, value);
        }
    }

    /// Core Vault Functions (ERC4626/ERC4626-like) ///
    function yieldSource_deposit(
        uint256 assets,
        address receiver
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).deposit(assets, receiver);
        }
        // Note: ERC5115 has different deposit signature, handled separately
        // Note: ERC7540 has different deposit signature, handled separately
    }

    function yieldSource_mint(uint256 shares, address receiver) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).mint(shares, receiver);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).mint(shares, receiver);
        }
        // Note: ERC5115 doesn't have mint function
    }

    function yieldSource_withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).withdraw(assets, receiver, owner);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).withdraw(assets, receiver, owner);
        }
        // Note: ERC5115 doesn't have withdraw function
    }

    function yieldSource_redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).redeem(shares, receiver, owner);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).redeem(shares, receiver, owner);
        }
        // Note: ERC5115 has different redeem signature, handled separately
    }

    /// ERC5115-specific functions ///
    function yieldSource_deposit5115(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut,
        bool depositFromInternalBalance
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).deposit(
                receiver,
                tokenIn,
                amountTokenToDeposit,
                minSharesOut,
                depositFromInternalBalance
            );
        }
    }

    function yieldSource_redeem5115(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).redeem(
                receiver,
                amountSharesToRedeem,
                tokenOut,
                minTokenOut,
                burnFromInternalBalance
            );
        }
    }

    /// ERC7540-specific functions ///
    function yieldSource_setOperator(
        address operator,
        bool approved
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).setOperator(operator, approved);
        }
    }

    function yieldSource_requestDeposit(
        uint256 assets,
        address controller,
        address owner
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).requestDeposit(
                assets,
                controller,
                owner
            );
        }
    }

    function yieldSource_requestRedeem(
        uint256 shares,
        address controller,
        address owner
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).requestRedeem(
                shares,
                controller,
                owner
            );
        }
    }

    function yieldSource_cancelDepositRequest(
        uint256 requestId,
        address controller
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).cancelDepositRequest(
                requestId,
                controller
            );
        }
    }

    function yieldSource_cancelRedeemRequest(
        uint256 requestId,
        address controller
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).cancelRedeemRequest(
                requestId,
                controller
            );
        }
    }

    function yieldSource_claimCancelDepositRequest(
        uint256 requestId,
        address receiver,
        address controller
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).claimCancelDepositRequest(
                requestId,
                receiver,
                controller
            );
        }
    }

    function yieldSource_claimCancelRedeemRequest(
        uint256 requestId,
        address receiver,
        address controller
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).claimCancelRedeemRequest(
                requestId,
                receiver,
                controller
            );
        }
    }

    function yieldSource_deposit7540(
        uint256 assets,
        address receiver,
        address controller
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).deposit(
                assets,
                receiver,
                controller
            );
        }
    }

    /// Testing-specific functions (ERC4626 only) ///
    function yieldSource_setRevertBehavior4626(
        uint8 functionType,
        uint8 revertType
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).setRevertBehavior(
                FunctionType(functionType),
                RevertType(revertType)
            );
        }
    }

    /// Testing-specific functions (ERC5115 only) ///
    function yieldSource_setRevertBehavior5115(
        uint8 revertType
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).setRevertBehavior(
                RevertType5115(revertType)
            );
        }
    }

    /// Common yield manipulation functions ///

    function yieldSource_simulateLoss(uint256 lossAmount) public {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).simulateLoss(lossAmount);
        } else if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).simulateLoss(lossAmount);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).simulateLoss(lossAmount);
        }
    }

    function yieldSource_simulateGain(uint256 gainAmount) public {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).simulateGain(gainAmount);
        } else if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).simulateGain(gainAmount);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).simulateGain(gainAmount);
        }
    }

    function yieldSource_setLossOnWithdraw(
        uint256 lossOnWithdraw
    ) public asActor {
        YieldSourceType currentType = _getCurrentYieldSourceType();
        address yieldSource = _getYieldSource();

        if (currentType == YieldSourceType.ERC4626) {
            MockERC4626Tester(yieldSource).setLossOnWithdraw(lossOnWithdraw);
        } else if (currentType == YieldSourceType.ERC5115) {
            MockERC5115Tester(yieldSource).setLossOnWithdraw(lossOnWithdraw);
        } else if (currentType == YieldSourceType.ERC7540) {
            MockERC7540Tester(yieldSource).setLossOnWithdraw(lossOnWithdraw);
        }
    }

    /// Yield source management functions ///
    function yieldSource_switchToERC4626() public {
        _switchYieldSource(0); // Switch to first yield source (ERC4626)
    }

    function yieldSource_switchToERC5115() public {
        _switchYieldSource(1); // Switch to second yield source (ERC5115)
    }

    function yieldSource_switchToERC7540() public {
        _switchYieldSource(2); // Switch to third yield source (ERC7540)
    }

    function yieldSource_switchRandom(uint256 entropy) public {
        // Randomly switch between the three deployed yield sources
        _switchYieldSource(entropy);
    }
}
