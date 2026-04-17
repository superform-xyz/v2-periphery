// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { PackedUserOperation } from "./PackedUserOperation.sol";

/// @dev ERC-4337 v0.7 IAccount interface (vendored from eth-infinitism/account-abstraction)
interface IAccount {
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256 validationData);
}
