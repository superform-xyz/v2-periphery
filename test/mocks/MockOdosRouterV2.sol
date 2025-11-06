// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IOdosRouterV2 } from "@superform-v2-core/src/vendor/odos/IOdosRouterV2.sol";

/// @notice Mock Odos Router V2 that properly handles non-standard ERC20 tokens like USDT
/// @dev Uses SafeERC20 to handle tokens that don't return bool from transfer/transferFrom
contract MockOdosRouterV2 {
    using SafeERC20 for IERC20;

    /// @notice Simulates a swap with a 0.5% fee
    /// @param tokenInfo Swap token information
    /// @return amountOut The minimum output amount
    function swap(
        IOdosRouterV2.swapTokenInfo memory tokenInfo,
        bytes calldata,
        address,
        uint32
    )
        external
        payable
        returns (uint256 amountOut)
    {
        if (tokenInfo.inputToken != address(0)) {
            IERC20(tokenInfo.inputToken).safeTransferFrom(msg.sender, address(this), tokenInfo.inputAmount);
        }

        if (tokenInfo.outputToken != address(0)) {
            // Apply 0.5% fee simulation
            uint256 outputAmount = tokenInfo.outputQuote - (tokenInfo.outputQuote * 50 / 10_000);
            IERC20(tokenInfo.outputToken).safeTransfer(msg.sender, outputAmount);
        } else {
            payable(msg.sender).transfer(tokenInfo.outputQuote);
        }

        return tokenInfo.outputMin;
    }

    /// @notice Compact swap placeholder
    function swapCompact() external payable returns (uint256) {
        return 0;
    }
}
