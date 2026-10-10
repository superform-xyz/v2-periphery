// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ISuperVaultAggregator } from "../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";

/// @notice Minimal mock of SuperVaultAggregator for unit tests
/// @dev Only implements the functions needed by ManagedVaultWrapper and ManagedECDSAAppsOracle
contract MockSuperVaultAggregator {
    mapping(address => uint256) public pps;
    mapping(address => uint256) public lastUpdateTimestamps;
    mapping(address => uint256) public maxStalenesses;
    mapping(address => address) public mainManagers;

    // Records the last forwardPPS call for assertions
    address[] public lastForwardedStrategies;
    uint256[] public lastForwardedPpss;

    function getPPS(address strategy) external view returns (uint256) {
        return pps[strategy];
    }

    function getLastUpdateTimestamp(address strategy) external view returns (uint256) {
        return lastUpdateTimestamps[strategy];
    }

    function getMaxStaleness(address strategy) external view returns (uint256) {
        return maxStalenesses[strategy];
    }

    function getMainManager(address strategy) external view returns (address) {
        return mainManagers[strategy];
    }

    function forwardPPS(ISuperVaultAggregator.ForwardPPSArgs calldata args) external {
        delete lastForwardedStrategies;
        delete lastForwardedPpss;
        for (uint256 i; i < args.strategies.length; ++i) {
            pps[args.strategies[i]] = args.ppss[i];
            lastUpdateTimestamps[args.strategies[i]] = args.timestamps[i];
            lastForwardedStrategies.push(args.strategies[i]);
            lastForwardedPpss.push(args.ppss[i]);
        }
    }

    // --- Test helpers ---
    function setMainManager(address strategy, address manager) external {
        mainManagers[strategy] = manager;
    }

    function setMaxStaleness(address strategy, uint256 staleness) external {
        maxStalenesses[strategy] = staleness;
    }

    function setPPS(address strategy, uint256 pps_) external {
        pps[strategy] = pps_;
        lastUpdateTimestamps[strategy] = block.timestamp;
    }
}
