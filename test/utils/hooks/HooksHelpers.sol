// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

abstract contract HooksHelpers {
    function _createApproveAndDeposit5115HookData(
        bytes32 yieldSourceOracleId,
        address vault,
        address tokenIn,
        uint256 amount,
        uint256 minSharesOut,
        bool usePrevHookAmount
    )
        internal
        pure
        returns (bytes memory hookData)
    {
        hookData = abi.encodePacked(yieldSourceOracleId, vault, tokenIn, amount, minSharesOut, usePrevHookAmount);
    }
}
