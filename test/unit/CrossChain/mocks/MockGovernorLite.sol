// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @notice Minimal SuperGovernor stand-in exposing only the surface the CrossChain contracts
///         call: getAddress, GOVERNOR_ROLE, ORACLE_MANAGER_ROLE, hasRole, and the validator/quorum
///         views used by the AUM oracle. Implements selectors by hand (no ISuperGovernor
///         conformance needed - the contracts hold it as an address/interface and call by selector).
contract MockGovernorLite {
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");

    mapping(bytes32 => address) private _addrs;
    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(address => bool) private _validators;
    uint256 private _quorum;
    uint256 private _validatorCount;

    function setAddress(bytes32 key, address value) external {
        _addrs[key] = value;
    }

    function getAddress(bytes32 key) external view returns (address) {
        return _addrs[key];
    }

    function grantRole(bytes32 role, address account) external {
        _roles[role][account] = true;
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _roles[role][account];
    }

    function setValidator(address validator, bool ok) external {
        if (ok && !_validators[validator]) _validatorCount++;
        if (!ok && _validators[validator]) _validatorCount--;
        _validators[validator] = ok;
    }

    function isValidator(address validator) external view returns (bool) {
        return _validators[validator];
    }

    function getValidatorsCount() external view returns (uint256) {
        return _validatorCount;
    }

    function setQuorum(uint256 q) external {
        _quorum = q;
    }

    function getPPSOracleQuorum() external view returns (uint256) {
        return _quorum;
    }
}
