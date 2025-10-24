// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockERC20} from "@recon/MockERC20.sol";

abstract contract ERC5115 is MockERC20 {
    MockERC20 public immutable yieldToken;
    address[] public tokensIn;
    address[] public tokensOut;

    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountDeposited,
        uint256 amountSyOut
    );

    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed tokenOut,
        uint256 amountSyToRedeem,
        uint256 amountTokenOut
    );

    constructor(
        MockERC20 _yieldToken
    ) MockERC20("MockERC5115Tester", "SY5115", 18) {
        yieldToken = _yieldToken;
        tokensIn.push(address(_yieldToken));
        tokensOut.push(address(_yieldToken));
    }

    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut,
        bool depositFromInternalBalance
    ) public virtual returns (uint256 amountSharesOut) {
        amountSharesOut = previewDeposit(tokenIn, amountTokenToDeposit);

        MockERC20(tokenIn).transferFrom(
            msg.sender,
            address(this),
            amountTokenToDeposit
        );
        _mint(receiver, amountSharesOut);

        emit Deposit(
            msg.sender,
            receiver,
            tokenIn,
            amountTokenToDeposit,
            amountSharesOut
        );
    }

    function exchangeRate() public view virtual returns (uint256) {
        uint256 supply = totalSupply;
        if (supply == 0) return 1e18;
        return (yieldToken.balanceOf(address(this)) * 1e18) / supply;
    }

    function getTokensIn() public view virtual returns (address[] memory) {
        return tokensIn;
    }

    function getTokensOut() public view virtual returns (address[] memory) {
        return tokensOut;
    }

    function previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) public view virtual returns (uint256 amountSharesOut) {
        require(tokenIn == address(yieldToken), "Invalid token");
        uint256 supply = totalSupply;
        if (supply == 0) {
            return amountTokenToDeposit;
        }
        return
            (amountTokenToDeposit * supply) /
            yieldToken.balanceOf(address(this));
    }

    function previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) public view virtual returns (uint256 amountTokenOut) {
        require(tokenOut == address(yieldToken), "Invalid token");
        uint256 supply = totalSupply;
        if (supply == 0) {
            return amountSharesToRedeem;
        }
        return
            (amountSharesToRedeem * yieldToken.balanceOf(address(this))) /
            supply;
    }
}

enum RevertType {
    NONE,
    THROW,
    OOG,
    RETURN_BOMB,
    REVERT_BOMB
}

contract MockERC5115Tester is ERC5115 {
    RevertType public revertBehaviour;
    uint256 public totalLosses;
    uint256 public totalGains;
    uint256 public lossOnWithdraw;
    uint256 public MAX_BPS = 10_000;

    constructor(address _yieldToken) ERC5115(MockERC20(_yieldToken)) {}

    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToDeposit,
        uint256 minSharesOut,
        bool depositFromInternalBalance
    ) public override returns (uint256 amountSharesOut) {
        _performRevertBehaviour(revertBehaviour);
        return
            super.deposit(
                receiver,
                tokenIn,
                amountTokenToDeposit,
                minSharesOut,
                depositFromInternalBalance
            );
    }

    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) public virtual returns (uint256 amountTokenOut) {
        amountTokenOut = previewRedeem(tokenOut, amountSharesToRedeem);

        _burn(msg.sender, amountSharesToRedeem);
        uint256 lossyAmountTokenOut = amountTokenOut -
            ((amountTokenOut * lossOnWithdraw) / MAX_BPS);
        MockERC20(tokenOut).transfer(receiver, lossyAmountTokenOut);

        emit Redeem(
            msg.sender,
            receiver,
            tokenOut,
            amountSharesToRedeem,
            amountTokenOut
        );
    }

    function _performRevertBehaviour(RevertType action) internal pure {
        if (action == RevertType.THROW) {
            revert("A normal Revert");
        }

        if (action == RevertType.OOG) {
            uint256 i;
            while (true) {
                ++i;
            }
        }

        if (action == RevertType.RETURN_BOMB) {
            uint256 _bytes = 2_000_000;
            assembly {
                return(0, _bytes)
            }
        }

        if (action == RevertType.REVERT_BOMB) {
            uint256 _bytes = 2_000_000;
            assembly {
                revert(0, _bytes)
            }
        }

        return; // NONE
    }

    function setRevertBehavior(RevertType rt) public {
        revertBehaviour = rt;
    }

    function simulateLoss(uint256 lossAmount) external {
        MockERC20(yieldToken).transfer(address(0xbeef), lossAmount);
        totalLosses += lossAmount;
    }

    function simulateGain(uint256 gainAmount) external {
        MockERC20(yieldToken).transferFrom(
            msg.sender,
            address(this),
            gainAmount
        );
        totalGains += gainAmount;
    }

    /// @dev Set the loss on withdraw as percentage of the assets being withdrawn
    function setLossOnWithdraw(uint256 _lossOnWithdraw) public {
        _lossOnWithdraw %= MAX_BPS + 1; // clamp to ensure we set a max of 100%
        lossOnWithdraw = _lossOnWithdraw;
    }

    function increaseYield(uint256 increasePercentageFP4) public {
        require(increasePercentageFP4 <= 10000, "Invalid percentage");
        uint256 amount = (yieldToken.balanceOf(address(this)) *
            increasePercentageFP4) / 10000;
        MockERC20(yieldToken).transferFrom(msg.sender, address(this), amount);
    }

    function decreaseYield(uint256 decreasePercentageFP4) public {
        require(decreasePercentageFP4 <= 10000, "Invalid percentage");
        uint256 amount = (yieldToken.balanceOf(address(this)) *
            decreasePercentageFP4) / 10000;
        MockERC20(yieldToken).transfer(address(0xbeef), amount);
        totalLosses += amount;
    }
}
