// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ICrossChainAUMOracle
/// @author Superform Labs
/// @notice Quorum-signed, per-position cross-chain AUM feed for cap enforcement, independent of
///         the PPS oracle. See specs/cross-chain-supervaults/technical-spec.md.
interface ICrossChainAUMOracle {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Cached, on-chain snapshot of the latest accepted report
    struct AUMReport {
        uint256 totalCrossChainAssets; // Derived on-chain: sum(values)
        uint256 hubAssets; // SEC-7: signed hub-chain assets (hub-asset decimals)
        uint256 timestamp;
        uint256 nonce;
    }

    /// @notice Per-strategy oracle integrity parameters (ORACLE_MANAGER_ROLE-set, hard-bounded)
    struct AUMOracleConfig {
        uint256 maxStaleness; // 0 = unconfigured -> everything blocked
        uint256 minUpdateInterval; // rate limit
        uint256 deviationThreshold; // max relative change of the AGGREGATE per update (1e18)
        uint256 perPositionDeviationThreshold; // SEC-14 (1e18)
        uint256 consistencyToleranceBps; // SEC-8 PPS<->AUM band (bps)
        uint256 maxConsecutiveDeviationBreaches; // SEC-13 breaker threshold
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event AUMUpdated(address indexed strategy, uint256 totalCrossChainAssets, uint256 timestamp);
    event AUMForceUpdated(address indexed strategy, uint256 totalCrossChainAssets, uint256 timestamp);
    event AUMDeviationExceeded(address indexed strategy, uint256 previous, uint256 proposed);
    event PositionDeviationExceeded(address indexed strategy, bytes32 indexed positionId, uint256 prev, uint256 next);
    event PPSConsistencyBreached(address indexed strategy, uint256 impliedAssets, uint256 totalAssets);
    event AUMBreakerTripped(address indexed strategy, uint256 consecutiveBreaches);
    event AUMBreakerReset(address indexed strategy);
    event AUMOracleConfigUpdated(address indexed strategy);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_ADDRESS();
    error UNAUTHORIZED_CONFIG();
    error UNAUTHORIZED_FORCE_UPDATE();
    error INVALID_CONFIG();
    error LENGTH_MISMATCH();
    error ZERO_LENGTH_ARRAY();
    error QUORUM_NOT_MET();
    error INVALID_VALIDATOR();
    error INVALID_PROOF();
    error UNCONFIGURED_STRATEGY();
    error FUTURE_TIMESTAMP();
    error STALE_UPDATE();
    error RATE_LIMITED();
    error DATA_TOO_STALE();
    error INCOMPLETE_REPORT();
    error UNSORTED_REPORT();
    error UNKNOWN_POSITION_ID();
    error REPORT_TOO_LARGE();
    error FORCE_REQUIRES_PPS_SOURCE();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setAUMOracleConfig(address strategy, AUMOracleConfig calldata config) external;

    function forwardAUM(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 hubAssets,
        uint256 timestamp,
        bytes[] calldata proofs
    )
        external;

    function forceAUMUpdate(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 hubAssets,
        uint256 timestamp,
        bytes[] calldata proofs
    )
        external;

    function isAUMFresh(address strategy) external view returns (bool);
    function getTotalAUM(address strategy) external view returns (uint256);
    function latestReport(address strategy) external view returns (AUMReport memory);
    function configs(address strategy) external view returns (AUMOracleConfig memory);
    function noncePerStrategy(address strategy) external view returns (uint256);
    function consecutiveBreaches(address strategy) external view returns (uint256);
    function aumBreakerTripped(address strategy) external view returns (bool);
}
