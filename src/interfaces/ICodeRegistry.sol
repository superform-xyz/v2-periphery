// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ICodeRegistry
/// @notice ERC-8021 registry read interface. Format validity is independent of registration.
interface ICodeRegistry {
    /// @notice Return the payout address, or zero if the code is unregistered.
    /// @param code Exact attribution code, without normalization.
    function payoutAddress(string calldata code) external view returns (address);

    /// @notice Return the metadata URI, or an empty string if the code is unregistered.
    /// @param code Exact attribution code, without normalization.
    function codeURI(string calldata code) external view returns (string memory);

    /// @notice Check the registry's code grammar, independently of whether it is registered.
    /// @param code Exact attribution code; an empty string is invalid.
    function isValidCode(string calldata code) external view returns (bool);

    /// @notice Return whether the exact code has been registered.
    /// @param code Exact attribution code, without normalization.
    function isRegistered(string calldata code) external view returns (bool);
}
