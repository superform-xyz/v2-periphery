// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { ICodeRegistry } from "./ICodeRegistry.sol";

/// @title ISuperBuilderCodeRegistry
/// @notice Admin-issued builder codes with permanent partner identity and address-controlled metadata.
interface ISuperBuilderCodeRegistry is ICodeRegistry {
    /// @notice A required governance or payout address is zero.
    error ZERO_ADDRESS();
    /// @notice The code does not match [a-z0-9_]{1,32}.
    error INVALID_CODE();
    /// @notice Partner identity cannot be zero.
    error INVALID_PARTNER_ID();
    /// @notice The code has already been permanently assigned.
    error CODE_ALREADY_REGISTERED();
    /// @notice Metadata cannot be updated before registration.
    error CODE_NOT_REGISTERED();
    /// @notice Only the code's current payout address may update its metadata or transfer control.
    error NOT_CODE_OWNER();
    /// @notice The metadata URI exceeds the byte limit.
    error URI_TOO_LONG();

    /// @notice Records the raw code and its immutable partner identity, plus initial metadata.
    event CodeRegistered(
        bytes32 indexed codeHash, bytes32 indexed partnerId, string code, address payoutAddress, string codeURI
    );

    /// @notice Records a payout and management change; partner identity is unaffected.
    event PayoutAddressUpdated(bytes32 indexed codeHash, address previousPayoutAddress, address newPayoutAddress);

    /// @notice Records a URI change; partner identity is unaffected.
    event CodeURIUpdated(bytes32 indexed codeHash, string previousURI, string newURI);

    /// @notice Permanently associate a code with a partner. Only an admin may call.
    /// @param code Exact code; no normalization is performed.
    /// @param partnerId_ Nonzero opaque identity issued by Persephone, independent of wallets/signers.
    /// @param payoutAddress_ Nonzero address that receives attribution payouts and controls this code's metadata.
    /// @param codeURI_ Metadata URI of at most 2,048 bytes; may be empty.
    function registerCode(
        string calldata code,
        bytes32 partnerId_,
        address payoutAddress_,
        string calldata codeURI_
    )
        external;

    /// @notice Return the permanent partner identity, or zero for an unregistered code.
    /// @param code Exact attribution code.
    function partnerId(string calldata code) external view returns (bytes32);

    /// @notice Update payout address and transfer control. Only the current payout address may call.
    /// @dev No admin override or acceptance step. An unchanged value emits no event.
    /// @param code An already registered code.
    /// @param payoutAddress_ Nonzero replacement payout address.
    function setPayoutAddress(string calldata code, address payoutAddress_) external;

    /// @notice Update URI metadata. Only the current payout address may call.
    /// @dev An unchanged value succeeds without emitting an event.
    /// @param code An already registered code.
    /// @param codeURI_ Replacement URI of at most 2,048 bytes; may be empty.
    function setCodeURI(string calldata code, string calldata codeURI_) external;
}
