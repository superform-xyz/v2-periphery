// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICodeRegistry } from "../interfaces/ICodeRegistry.sol";
import { ISuperBuilderCodeRegistry } from "../interfaces/ISuperBuilderCodeRegistry.sol";

/// @title SuperBuilderCodeRegistry
/// @author Superform Labs
/// @notice Admin-issued ERC-8021 codes with permanent partner assignments and address-controlled metadata.
/// @dev Non-upgradeable and non-custodial. Partner assignments cannot be deleted or reassigned.
///      Each code's current payout address controls its metadata and may transfer that control.
///      Registration events establish history; indexers determine registration-before-action ordering.
///      Namespace a code by registry chain, registry address, and exact code text.
contract SuperBuilderCodeRegistry is AccessControl, ISuperBuilderCodeRegistry {
    /// @notice Maximum ASCII code length in bytes.
    uint256 public constant MAX_CODE_LENGTH = 32;
    /// @notice Maximum metadata URI length in bytes, including UTF-8 encoding.
    uint256 public constant MAX_URI_LENGTH = 2048;

    struct Registration {
        bytes32 partner;
        address payout;
        string uri;
    }

    mapping(bytes32 codeHash => Registration registration) private _registrations;

    /// @notice Grant DEFAULT_ADMIN_ROLE to governance, allowing it to register codes and manage admins.
    /// @param governance Nonzero governance address. The deployer receives no implicit authority.
    constructor(address governance) {
        if (governance == address(0)) revert ZERO_ADDRESS();
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
    }

    /// @inheritdoc ISuperBuilderCodeRegistry
    function registerCode(
        string calldata code,
        bytes32 partnerId_,
        address payoutAddress_,
        string calldata codeURI_
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!isValidCode(code)) revert INVALID_CODE();
        if (partnerId_ == bytes32(0)) revert INVALID_PARTNER_ID();
        if (payoutAddress_ == address(0)) revert ZERO_ADDRESS();
        if (bytes(codeURI_).length > MAX_URI_LENGTH) revert URI_TOO_LONG();

        bytes32 codeHash = keccak256(bytes(code));
        if (_registrations[codeHash].partner != bytes32(0)) revert CODE_ALREADY_REGISTERED();
        _registrations[codeHash] = Registration({ partner: partnerId_, payout: payoutAddress_, uri: codeURI_ });
        emit CodeRegistered(codeHash, partnerId_, code, payoutAddress_, codeURI_);
    }

    /// @inheritdoc ISuperBuilderCodeRegistry
    function partnerId(string calldata code) external view returns (bytes32) {
        return _registrations[keccak256(bytes(code))].partner;
    }

    /// @inheritdoc ICodeRegistry
    function payoutAddress(string calldata code) external view returns (address) {
        return _registrations[keccak256(bytes(code))].payout;
    }

    /// @inheritdoc ICodeRegistry
    function codeURI(string calldata code) external view returns (string memory) {
        return _registrations[keccak256(bytes(code))].uri;
    }

    /// @inheritdoc ICodeRegistry
    function isRegistered(string calldata code) external view returns (bool) {
        return _registrations[keccak256(bytes(code))].partner != bytes32(0);
    }

    /// @inheritdoc ICodeRegistry
    function isValidCode(string calldata code) public pure returns (bool) {
        bytes calldata raw = bytes(code);
        uint256 length = raw.length;
        if (length == 0 || length > MAX_CODE_LENGTH) return false;
        for (uint256 i; i < length; ++i) {
            bytes1 c = raw[i];
            if ((c < 0x61 || c > 0x7a) && (c < 0x30 || c > 0x39) && c != 0x5f) return false;
        }
        return true;
    }

    /// @inheritdoc ISuperBuilderCodeRegistry
    function setPayoutAddress(string calldata code, address payoutAddress_) external {
        bytes32 codeHash = keccak256(bytes(code));
        Registration storage registration = _ownedRegistration(codeHash);
        if (payoutAddress_ == address(0)) revert ZERO_ADDRESS();
        address previous = registration.payout;
        if (previous == payoutAddress_) return;
        registration.payout = payoutAddress_;
        emit PayoutAddressUpdated(codeHash, previous, payoutAddress_);
    }

    /// @inheritdoc ISuperBuilderCodeRegistry
    function setCodeURI(string calldata code, string calldata codeURI_) external {
        bytes32 codeHash = keccak256(bytes(code));
        Registration storage registration = _ownedRegistration(codeHash);
        if (bytes(codeURI_).length > MAX_URI_LENGTH) revert URI_TOO_LONG();
        string memory previous = registration.uri;
        if (keccak256(bytes(previous)) == keccak256(bytes(codeURI_))) return;
        registration.uri = codeURI_;
        emit CodeURIUpdated(codeHash, previous, codeURI_);
    }

    function _ownedRegistration(bytes32 codeHash) private view returns (Registration storage registration) {
        registration = _registrations[codeHash];
        if (registration.partner == bytes32(0)) revert CODE_NOT_REGISTERED();
        if (registration.payout != _msgSender()) revert NOT_CODE_OWNER();
    }
}
