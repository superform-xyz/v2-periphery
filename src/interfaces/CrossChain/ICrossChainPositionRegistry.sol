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

    /// @notice Lifecycle of a bridge reservation (K1: the single object binding a cap-hook send to
    ///         a position lifecycle)
    /// @dev Open       — minted by the cap hook at send time; counted as in-flight exposure
    ///      Consumed   — bound to exactly one Pending position; still counted
    ///      Released   — uncounted (reservation expiry, or its position was invalidated); may be
    ///                   re-consumed by a late registration (a slow fill that lands after a
    ///                   timeout), which re-counts it
    ///      Settled    — its position was oracle-confirmed; terminal, never re-consumable
    enum ReservationStatus {
        None,
        Open,
        Consumed,
        Released,
        Settled
    }

    /// @notice A cap-hook-minted reservation of in-flight bridged exposure
    struct BridgeReservation {
        address strategy;
        uint64 chainId; // canonical EVM destination chain id
        address destinationVault; // economic destination (address(0) = idle-hold)
        uint256 amount; // exact amount the cap hook validated and the bridge sent
        uint256 createdAt;
        ReservationStatus status;
        bytes32 positionId; // set when consumed
    }

    /// @notice A tracked cross-chain position
    /// @param chainId Destination chain id
    /// @param kind Idle or SuperVault
    /// @param destinationVault Approved destination SuperVault (address(0) for Idle)
    /// @param deployedAmount Asset amount bridged out (hub-asset decimals; always the consumed
    ///        reservation's amount — never registrar-supplied)
    /// @param sharesHeld Destination-vault shares held (0 for Idle)
    /// @param lastReportedValue Last oracle-reported value (SuperVault: shares * destPPS)
    /// @param lastReportTimestamp When the value was last reported
    /// @param registeredAt Registration timestamp (drives the confirmation timeout)
    /// @param status Current lifecycle status
    /// @param reservationId The consumed bridge reservation this position reconciles against (K1)
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
        bytes32 reservationId;
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
    event BridgedOutRecorded(
        address indexed strategy,
        uint64 indexed chainId,
        address indexed destinationVault,
        uint256 amount,
        bytes32 reservationId
    );
    event ReservationConsumed(bytes32 indexed reservationId, bytes32 indexed positionId, bool recounted);
    event ReservationSettled(bytes32 indexed reservationId, bytes32 indexed positionId);
    event ReservationReleased(bytes32 indexed reservationId);
    event PendingValueObserved(address indexed strategy, bytes32 indexed positionId, uint256 value);
    event PositionReconciledUnderDelivery(
        address indexed strategy, bytes32 indexed positionId, uint256 observedValue, uint256 reservedAmount
    );
    event BridgeHookAuthorizationUpdated(address indexed hook, bool authorized);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_ADDRESS();
    error UNAUTHORIZED_REGISTRAR();
    error UNAUTHORIZED_AUM_ORACLE();
    error UNAUTHORIZED_BRIDGE_HOOK();
    error UNAUTHORIZED_CONFIG();
    error MAX_POSITIONS_REACHED();
    error INVALID_POSITION_STATUS();
    error POSITION_NOT_DRAINED();
    error POSITION_NOT_EXPIRED();
    error POSITION_STRATEGY_MISMATCH();
    error RESERVATION_NOT_CONSUMABLE();
    error RESERVATION_KIND_MISMATCH();
    error RESERVATION_NOT_EXPIRED();
    error POSITION_HAS_LANDED_VALUE();

    /*//////////////////////////////////////////////////////////////
                              REGISTRAR WRITES
    //////////////////////////////////////////////////////////////*/

    /// @notice Register a new cross-chain position (registrar only). Starts Pending. K1: consumes
    ///         exactly one bridge reservation — the destination chain, vault and deployed amount
    ///         are taken FROM the reservation the cap hook minted, never supplied by the registrar.
    ///         A Released reservation (timed out, then the fill landed late) may be consumed too;
    ///         doing so re-counts its exposure so landed capital is never untracked.
    ///         R4: deliberately does NOT re-check destination approval — the reservation is the
    ///         send-time approval proof, and by registration time the capital has already left the
    ///         hub; refusing to track a landed fill would only push real exposure off-book.
    function registerPosition(
        address strategy,
        bytes32 reservationId,
        PositionKind kind,
        uint256 sharesHeld
    )
        external
        returns (bytes32 positionId);

    /// @notice Transition an Active position to WindingDown (registrar only)
    function beginPositionExit(address strategy, bytes32 positionId) external;

    /// @notice Remove a fully-drained WindingDown position (registrar only). Requires the latest
    ///         report to value it at ~0 (oracle-confirmed drain).
    function deregisterPosition(address strategy, bytes32 positionId) external;

    /// @notice Permissionless cleanup of a Pending position past the confirmation timeout that has
    ///         NEVER shown a positive value: releases its in-flight reservation and evicts it
    ///         (P2-1). Reverts once any positive value was observed (R3-PF1: landed capital must
    ///         not be uncounted by a wall clock).
    function invalidateExpiredPending(address strategy, bytes32 positionId) external;

    /// @notice Trusted governance reconciliation for an expired Pending position with a positive
    ///         but out-of-band observed value: confirms it at that value, explicitly accepting the
    ///         difference as bridge loss / over-delivery (R3-PF1). R4: the reservation stays
    ///         Consumed (counted) until the next committed oracle report books the position —
    ///         settling in a standalone tx would remove the value from the oracle's in-flight
    ///         anchor before any report contains it.
    function reconcileUnderDeliveredPosition(address strategy, bytes32 positionId) external;

    /*//////////////////////////////////////////////////////////////
                               ORACLE WRITE
    //////////////////////////////////////////////////////////////*/

    /// @notice Single oracle write path: sync one position from a quorum-signed AUM report
    /// @dev onlyAUMOracle. Normative Pending lifecycle (R3-PF1/R4):
    ///      - value in [MIN_CONFIRMATION_BPS, MAX_CONFIRMATION_BPS] of deployedAmount (and > 0)
    ///        -> Active + reservation settled (allowed even after the confirmation timeout: a
    ///        late full landing books);
    ///      - other positive value (below floor OR above ceiling) -> observation recorded, stays
    ///        Pending, reservation stays counted; the position can then never be invalidated by
    ///        the wall clock - only a later in-band report or governance
    ///        reconcileUnderDeliveredPosition resolves it;
    ///      - value == 0 past the timeout with NO prior observation -> Invalidated + released.
    ///      Active/WindingDown -> value update (a still-Consumed reservation — the reconcile
    ///      path — settles on this first committed booking); Exited/Invalidated -> skipped
    ///      (no revert).
    /// @return acceptedValue The value actually booked into AUM (0 when the entry was skipped), so
    ///         the oracle caches only registry-accepted totals (B2)
    function syncPositionFromReport(
        address strategy,
        bytes32 positionId,
        uint256 value,
        uint256 timestamp
    )
        external
        returns (uint256 acceptedValue);

    /*//////////////////////////////////////////////////////////////
                               HOOK WRITE
    //////////////////////////////////////////////////////////////*/

    /// @notice Record in-flight bridged-but-unconfirmed exposure (capped-bridge-hook only). K1:
    ///         mints a reservation bound to the exact (strategy, canonical chain, destination
    ///         vault, amount) tuple the hook validated; one registration consumes it, and
    ///         confirmation/invalidation/expiry reconcile that same reservation.
    function recordBridgedOut(
        address strategy,
        uint64 chainId,
        address destinationVault,
        uint256 amount
    )
        external
        returns (bytes32 reservationId);

    /// @notice Permissionless release of an Open reservation past the reservation timeout (the
    ///         bridge never filled / refunded on origin): uncounts its in-flight exposure. If the
    ///         fill lands later, the registrar can still consume the Released reservation, which
    ///         re-counts it (K1: no uncounted landed capital).
    function releaseExpiredReservation(bytes32 reservationId) external;

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
    function RESERVATION_TIMEOUT() external view returns (uint256);
    function MIN_CONFIRMATION_BPS() external view returns (uint256);
    function MAX_CONFIRMATION_BPS() external view returns (uint256);
    function MAX_POSITIONS_PER_STRATEGY() external view returns (uint256);

    /// @notice Number of Open (recorded but not yet consumed/released) reservations per strategy;
    ///         with the live position set this bounds recordBridgedOut (R4)
    function openReservationCount(address strategy) external view returns (uint256);
    function positions(bytes32 positionId) external view returns (CrossChainPosition memory);
    function reservations(bytes32 reservationId) external view returns (BridgeReservation memory);
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
