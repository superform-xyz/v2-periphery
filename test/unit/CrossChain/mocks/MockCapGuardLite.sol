// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @notice Minimal cap-guard stand-in for registry tests: only isApprovedDestination.
contract MockCapGuardLite {
    mapping(bytes32 => bool) private _approved;

    function setApproved(address strategy, uint64 chainId, address vault, bool ok) external {
        _approved[keccak256(abi.encode(strategy, chainId, vault))] = ok;
    }

    function isApprovedDestination(address strategy, uint64 chainId, address vault) external view returns (bool) {
        return _approved[keccak256(abi.encode(strategy, chainId, vault))];
    }
}
