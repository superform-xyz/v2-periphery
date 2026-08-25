// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IVetoRegistry } from "../interfaces/SuperVault/IVetoRegistry.sol";

/// @title SuperVaultVetoRegistry
/// @author Superform Labs
/// @notice Minimal fixed-membership veto registry for a SuperVaultCounsel: a batch of
///         guardians set once at deployment, no admin, no mutators. Deployed one-per-strategy
///         alongside the Counsel when the fleet config names a bare (codeless) address as the
///         veto authority.
/// @dev The registry is the membership oracle the Counsel consults via isGuardian(); the
///      guardians themselves can be any addresses, including EOAs. The set is effectively
///      immutable by construction - the same trust model as the Counsel: changing the veto
///      authority requires deploying a new registry and a new Counsel pointing at it.
contract SuperVaultVetoRegistry is IVetoRegistry {
    /// @notice Guardian membership, fixed at construction
    mapping(address guardian => bool isMember) private _isGuardian;

    /// @notice The full guardian set, fixed at construction
    address[] private _guardians;

    /// @notice Thrown when the guardian batch is empty
    error EMPTY_GUARDIANS();

    /// @notice Thrown when a guardian constructor arg is the zero address
    error ZERO_ADDRESS();

    /// @notice Thrown when the same guardian appears twice in the batch
    error DUPLICATE_GUARDIAN(address guardian);

    /// @param guardians_ The addresses allowed to veto on Counsels using this registry
    constructor(address[] memory guardians_) {
        uint256 len = guardians_.length;
        if (len == 0) revert EMPTY_GUARDIANS();
        for (uint256 i; i < len; ++i) {
            address guardian = guardians_[i];
            if (guardian == address(0)) revert ZERO_ADDRESS();
            if (_isGuardian[guardian]) revert DUPLICATE_GUARDIAN(guardian);
            _isGuardian[guardian] = true;
            _guardians.push(guardian);
        }
    }

    /// @inheritdoc IVetoRegistry
    function isGuardian(address account) external view returns (bool) {
        return _isGuardian[account];
    }

    /// @notice The full guardian set
    function getGuardians() external view returns (address[] memory) {
        return _guardians;
    }
}
