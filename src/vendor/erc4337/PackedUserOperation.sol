// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

/// @dev ERC-4337 v0.7 PackedUserOperation struct (vendored from eth-infinitism/account-abstraction)
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}
