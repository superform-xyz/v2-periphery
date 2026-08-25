// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ICrossChainPositionRegistry
/// @author Superform Labs
/// @notice Tracks a strategy's cross-chain positions under the Constrained Destination Model:
///         bridged capital is either held idle in a hub escrow or deposited into an approved
///         destination SuperVault (the hub holds that vault's shares). No arbitrary-protocol
///         positions exist. See specs/cross-chain-supervaults/technical-spec.md.
interface ICrossChainPositionRegistry {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice Lifecycle of a cross-chain position
    enum PositionStatus {
        None, // 0: default / never registered
        Pending, // Registered by the registrar, awaiting first quorum-signed report
        Active, // Included (funded) in a signed report, counted in AUM
        WindingDown, // Being unwound, assets returning to hub (still counted in AUM)
        Exited, // Fully exited, no longer tracked
        Invalidated // Pending position not confirmed within the timeout - never entered AUM
    }

    /// @notice The only two things bridged capital may become on a destination chain
    enum PositionKind {
        Idle, // Bridged asset held in the hub-controlled destination escrow
        SuperVault // Deposited into an approved destination SuperVault; hub holds its shares
    }

    /// @notice A tracked cross-chain position
    /// @param chainId Destination chain id
    /// @param kind Idle or SuperVault
    /// @param destinationVault Approved destination SuperVault (address(0) for Idle)
    /// @param deployedAmount Asset amount bridged out (hub-asset decimals)
    /// @param sharesHeld Destination-vault shares held (0 for Idle)
    /// @param lastReportedValue Last oracle-reported value (SuperVault: shares * destPPS)
    /// @param lastReportTimestamp When the value was last reported
    /// @param registeredAt Registration timestamp (drives the confirmation timeout)
    /// @param status Current lifecycle status
    struct CrossChainPosition {
        address strategy; // owner strategy (bound at registration; checked on every oracle sync)
        uint64 chainId;
        PositionKind kind;
        address destinationVault;
        uint256 deployedAmount;
        uint256 sharesHeld;
        uint256 lastReportedValue;
        uint256 lastReportTimestamp;
        uint256 registeredAt;
        PositionStatus status;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event PositionRegistered(
        address indexed strategy,
        bytes32 indexed positionId,
        uint64 chainId,
        PositionKind kind,
        address destinationVault
    );
    event PositionSynced(bytes32 indexed positionId, PositionStatus newStatus, uint256 value, uint256 timestamp);
    event PositionExitStarted(address indexed strategy, bytes32 indexed positionId);
    event PositionDeregistered(address indexed strategy, bytes32 indexed positionId);
    event PositionInvalidated(address indexed strategy, bytes32 indexed positionId);
    event RegistrarUpdated(address indexed strategy, address indexed registrar);
    event BridgedOutRecorded(address indexed strategy, uint64 indexed chainId, uint256 amount);
    event BridgeHookAuthorizationUpdated(address indexed hook, bool authorized);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_ADDRESS();
    error UNAUTHORIZED_REGISTRAR();
    error UNAUTHORIZED_AUM_ORACLE();
    error UNAUTHORIZED_BRIDGE_HOOK();
    error UNAUTHORIZED_CONFIG();
    error INVALID_MAINNET_CHAIN();
    error MAX_POSITIONS_REACHED();
    error POSITION_NOT_FOUND();
    error INVALID_POSITION_STATUS();
    error INVALID_KIND_CONFIG();
    error DESTINATION_NOT_APPROVED();
    error POSITION_NOT_DRAINED();
    error POSITION_NOT_EXPIRED();

    /*//////////////////////////////////////////////////////////////
                              REGISTRAR WRITES
    //////////////////////////////////////////////////////////////*/

    /// @notice Register a new cross-chain position (registrar only). Starts Pending.
    function registerPosition(
        address strategy,
        uint64 chainId,
        PositionKind kind,
        address destinationVault,
        uint256 deployedAmount,
        uint256 sharesHeld
    )
        external
        returns (bytes32 positionId);

    /// @notice Transition an Active position to WindingDown (registrar only)
    function beginPositionExit(address strategy, bytes32 positionId) external;

    /// @notice Remove a fully-drained WindingDown position (registrar only). Requires the latest
    ///         report to value it at ~0 (oracle-confirmed drain).
    function deregisterPosition(address strategy, bytes32 positionId) external;

    /// @notice Permissionless cleanup of a Pending position past the confirmation timeout: releases
    ///         its in-flight reservation and evicts it (P2-1).
    function invalidateExpiredPending(address strategy, bytes32 positionId) external;

    /*//////////////////////////////////////////////////////////////
                               ORACLE WRITE
    //////////////////////////////////////////////////////////////*/

    /// @notice Single oracle write path: sync one position from a quorum-signed AUM report
    /// @dev onlyAUMOracle. Pending+nonzero -> Active; Pending+timeout -> Invalidated;
    ///      Active/WindingDown -> value update; Exited/Invalidated -> skipped (no revert).
    function syncPositionFromReport(address strategy, bytes32 positionId, uint256 value, uint256 timestamp) external;

    /*//////////////////////////////////////////////////////////////
                               HOOK WRITE
    //////////////////////////////////////////////////////////////*/

    /// @notice Record in-flight bridged-but-unconfirmed exposure (capped-bridge-hook only)
    function recordBridgedOut(address strategy, uint64 chainId, uint256 amount) external;

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the per-strategy registrar (GOVERNOR_ROLE only, SEC-4)
    function setRegistrar(address strategy, address registrar) external;

    /// @notice Authorize/deauthorize a capped bridge hook to record in-flight exposure (GOVERNOR_ROLE)
    function setBridgeHookAuthorization(address hook, bool authorized) external;

    /*//////////////////////////////////////////////////////////////
                              VIEWS
    //////////////////////////////////////////////////////////////*/

    function POSITION_CONFIRMATION_TIMEOUT() external view returns (uint256);
    function positions(bytes32 positionId) external view returns (CrossChainPosition memory);
    function registrars(address strategy) external view returns (address);
    function authorizedBridgeHook(address hook) external view returns (bool);
    function bridgedOut(address strategy) external view returns (uint256);
    function bridgedOutByChain(address strategy, uint64 chainId) external view returns (uint256);
    function getPositionIds(address strategy) external view returns (bytes32[] memory);
    function positionValue(bytes32 positionId) external view returns (uint256);

    /// @notice Confirmed value of all Active/WindingDown positions
    function getCrossChainAUM(address strategy) external view returns (uint256);

    /// @notice Confirmed value of Active/WindingDown positions on one destination chain
    function getChainExposure(address strategy, uint64 chainId) external view returns (uint256);

    /// @notice Cap-facing exposure = confirmed AUM + in-flight bridgedOut (SEC-3)
    function getEffectiveCrossChainExposure(address strategy) external view returns (uint256);

    /// @notice Per-chain cap-facing exposure = confirmed chain exposure + in-flight to that chain
    function getEffectiveChainExposure(address strategy, uint64 chainId) external view returns (uint256);
}
