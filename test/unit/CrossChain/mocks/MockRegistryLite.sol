// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import {
    ICrossChainPositionRegistry as R
} from "../../../../src/interfaces/CrossChain/ICrossChainPositionRegistry.sol";

/// @notice Minimal registry stand-in for AUM oracle tests: settable positions, bridgedOut, and a
///         record of syncPositionFromReport calls. Only the surface the oracle reads/writes.
contract MockRegistryLite {
    bytes32[] internal _ids;
    mapping(bytes32 => R.CrossChainPosition) internal _pos;
    mapping(address => uint256) public bridgedOut;
    mapping(bytes32 => uint256) public syncedValue;
    mapping(bytes32 => bool) public wasSynced;

    function POSITION_CONFIRMATION_TIMEOUT() external pure returns (uint256) {
        return 2 hours;
    }

    function addPosition(
        bytes32 id,
        R.PositionStatus status,
        uint256 registeredAt,
        uint256 lastReportedValue
    )
        external
    {
        _ids.push(id);
        _pos[id] = R.CrossChainPosition({
            strategy: address(0),
            chainId: 1,
            kind: R.PositionKind.SuperVault,
            destinationVault: address(0xBEEF),
            deployedAmount: 0,
            sharesHeld: 1,
            lastReportedValue: lastReportedValue,
            lastReportTimestamp: 0,
            registeredAt: registeredAt,
            status: status
        });
    }

    function setBridgedOut(address strategy, uint256 v) external {
        bridgedOut[strategy] = v;
    }

    function getPositionIds(address) external view returns (bytes32[] memory) {
        return _ids;
    }

    function positions(bytes32 id) external view returns (R.CrossChainPosition memory) {
        return _pos[id];
    }

    function positionValue(bytes32 id) external view returns (uint256) {
        R.CrossChainPosition memory p = _pos[id];
        return
            (p.status == R.PositionStatus.Active || p.status == R.PositionStatus.WindingDown) ? p.lastReportedValue : 0;
    }

    function syncPositionFromReport(address, bytes32 id, uint256 value, uint256) external {
        syncedValue[id] = value;
        wasSynced[id] = true;
        _pos[id].lastReportedValue = value;
    }
}
