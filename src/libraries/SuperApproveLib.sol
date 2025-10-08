// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

library SuperApproveLib {
    error NO_CONTRACT();
    error APPROVE_FAILED();

    function safeApprove(address token, address to, uint256 value) internal {
        require(token.code.length > 0, NO_CONTRACT());

        bool success;
        bytes memory data;
        (success, data) = token.call(abi.encodeCall(IERC20.approve, (to, 0)));
        require(success && (data.length == 0 || abi.decode(data, (bool))), APPROVE_FAILED());

        if (value > 0) {
            (success, data) = token.call(abi.encodeCall(IERC20.approve, (to, value)));
            require(success && (data.length == 0 || abi.decode(data, (bool))), APPROVE_FAILED());
        }
    }
}