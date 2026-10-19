// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title IVetoRegistry
/// @author Superform Labs
/// @notice Minimal veto-authority lookup used by SuperVaultCounsel. SuperGovernor satisfies this
///         interface natively (isGuardian); a per-instance registry lets veto authority be
///         plugged at deploy time (e.g. a Newton attestation shim) without granting the vetoer
///         a protocol-wide GUARDIAN_ROLE.
interface IVetoRegistry {
    /// @notice Whether an address currently holds veto authority
    /// @param account The address to check
    /// @return Whether the account may veto
    function isGuardian(address account) external view returns (bool);
}
