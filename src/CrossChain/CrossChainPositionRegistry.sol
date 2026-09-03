// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ICrossChainPositionRegistry } from "../interfaces/CrossChain/ICrossChainPositionRegistry.sol";
import { ICrossChainPositionCapGuard } from "../interfaces/CrossChain/ICrossChainPositionCapGuard.sol";

/// @title CrossChainPositionRegistry
/// @author Superform Labs
/// @notice Tracks a strategy's cross-chain positions (idle hub-escrow asset, or shares of an
///         approved destination SuperVault). Written by a per-strategy registrar and, for value,
///         only by the quorum-backed CrossChainAUMOracle. See technical-spec.md.
contract CrossChainPositionRegistry is ICrossChainPositionRegistry {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Max time a Pending position may exist before it can be invalidated
    uint256 public constant POSITION_CONFIRMATION_TIMEOUT = 2 hours;

    /// @notice Max time an unconsumed (never-registered) reservation stays counted before it can
    ///         be released permissionlessly (K1)
    uint256 public constant RESERVATION_TIMEOUT = 2 hours;

    /// @notice Hard cap on live positions per strategy - bounds every full-set loop (SEC-9)
    uint256 public constant MAX_POSITIONS_PER_STRATEGY = 64;

    bytes32 private constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");
    bytes32 private constant CROSS_CHAIN_CAP_GUARD = keccak256("CROSS_CHAIN_CAP_GUARD");

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice SuperGovernor - source of roles and contract-registry lookups
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @dev strategy => set of live position ids (Invalidated/Exited are evicted)
    mapping(address => EnumerableSet.Bytes32Set) private _strategyPositions;

    /// @dev positionId => position data
    mapping(bytes32 => CrossChainPosition) private _positions;

    /// @dev strategy => registrar (SEC-4: appointed by GOVERNOR_ROLE, not the manager)
    mapping(address => address) public registrars;

    /// @dev strategy => monotonic salt for unique position ids (SEC-12)
    mapping(address => uint256) private _positionSalt;

    /// @dev K1: reservationId => reservation; the single ledger binding a cap-hook send to one
    ///      position lifecycle. `bridgedOut`/`bridgedOutByChain` are pure aggregates over counted
    ///      (Open/Consumed) reservations — every increment/decrement is an exact reservation
    ///      amount, so the counters can never drift or need clamping.
    mapping(bytes32 => BridgeReservation) private _reservations;
    uint256 private _reservationSalt;

    /// @dev strategy => in-flight bridged-but-unconfirmed exposure (SEC-3)
    mapping(address => uint256) public bridgedOut;
    mapping(address => mapping(uint64 => uint256)) public bridgedOutByChain;

    /// @dev hook => whether it may record in-flight exposure (governor-managed allowlist)
    mapping(address => bool) public authorizedBridgeHook;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyRegistrar(address strategy) {
        if (msg.sender != registrars[strategy]) revert UNAUTHORIZED_REGISTRAR();
        _;
    }

    modifier onlyAUMOracle() {
        if (msg.sender != SUPER_GOVERNOR.getAddress(CROSS_CHAIN_AUM_ORACLE)) revert UNAUTHORIZED_AUM_ORACLE();
        _;
    }

    modifier onlyGovernor() {
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.GOVERNOR_ROLE(), msg.sender)) {
            revert UNAUTHORIZED_CONFIG();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              REGISTRAR WRITES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev K1: the registrar names a reservation, not a destination — chain, vault and amount all
    ///      come from what the cap hook validated at send time. One reservation, one position.
    function registerPosition(
        address strategy,
        bytes32 reservationId,
        PositionKind kind,
        uint256 sharesHeld
    )
        external
        onlyRegistrar(strategy)
        returns (bytes32 positionId)
    {
        BridgeReservation storage res = _reservations[reservationId];
        if (res.strategy != strategy) revert RESERVATION_NOT_CONSUMABLE();
        // Open = normal flow. Released = the reservation timed out (or its position was
        // invalidated) and the fill landed late: consuming re-counts it, so landed capital is
        // never untracked. Consumed/Settled reservations are never re-bindable.
        if (res.status != ReservationStatus.Open && res.status != ReservationStatus.Released) {
            revert RESERVATION_NOT_CONSUMABLE();
        }

        uint64 chainId = res.chainId;
        address destinationVault = res.destinationVault;

        // The declared kind must match the reservation's destination shape.
        if (kind == PositionKind.SuperVault) {
            if (destinationVault == address(0) || sharesHeld == 0) revert RESERVATION_KIND_MISMATCH();
        } else {
            if (destinationVault != address(0) || sharesHeld != 0) revert RESERVATION_KIND_MISMATCH();
        }

        // Constrained model: the destination must still be approved at registration time (an
        // approval revoked between send and registration blocks the position).
        ICrossChainPositionCapGuard capGuard =
            ICrossChainPositionCapGuard(SUPER_GOVERNOR.getAddress(CROSS_CHAIN_CAP_GUARD));
        if (!capGuard.isApprovedDestination(strategy, chainId, destinationVault)) revert DESTINATION_NOT_APPROVED();

        EnumerableSet.Bytes32Set storage set = _strategyPositions[strategy];
        if (set.length() >= MAX_POSITIONS_PER_STRATEGY) revert MAX_POSITIONS_REACHED();

        // SEC-12: salted id so re-deploying to the same destination after Exit/Invalidation
        // yields a distinct id, and concurrent deployments never collide.
        uint256 salt = _positionSalt[strategy]++;
        positionId = keccak256(abi.encode(strategy, chainId, destinationVault, salt));

        bool recounted = res.status == ReservationStatus.Released;
        if (recounted) _countReservation(res);
        res.status = ReservationStatus.Consumed;
        res.positionId = positionId;

        _positions[positionId] = CrossChainPosition({
            strategy: strategy,
            chainId: chainId,
            kind: kind,
            destinationVault: destinationVault,
            deployedAmount: res.amount,
            sharesHeld: sharesHeld,
            lastReportedValue: 0,
            lastReportTimestamp: 0,
            registeredAt: block.timestamp,
            status: PositionStatus.Pending,
            reservationId: reservationId
        });
        set.add(positionId);

        emit ReservationConsumed(reservationId, positionId, recounted);
        emit PositionRegistered(strategy, positionId, chainId, kind, destinationVault);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function beginPositionExit(address strategy, bytes32 positionId) external onlyRegistrar(strategy) {
        CrossChainPosition storage pos = _positions[positionId];
        // B3: the modifier authorizes the caller for `strategy`; the position must actually be
        // owned by that strategy, or one registrar could mutate another strategy's lifecycle.
        if (pos.strategy != strategy) revert POSITION_STRATEGY_MISMATCH();
        if (pos.status != PositionStatus.Active) revert INVALID_POSITION_STATUS();
        pos.status = PositionStatus.WindingDown;
        emit PositionExitStarted(strategy, positionId);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev SEC-6: only removable once the oracle has reported the position at ~0 value
    ///      (confirmed drain), not on the registrar's say-so alone.
    function deregisterPosition(address strategy, bytes32 positionId) external onlyRegistrar(strategy) {
        CrossChainPosition storage pos = _positions[positionId];
        // B3: same ownership binding as beginPositionExit - removal must target the owner's set.
        if (pos.strategy != strategy) revert POSITION_STRATEGY_MISMATCH();
        if (pos.status != PositionStatus.WindingDown) revert INVALID_POSITION_STATUS();
        if (pos.lastReportedValue != 0) revert POSITION_NOT_DRAINED();

        pos.status = PositionStatus.Exited;
        _strategyPositions[strategy].remove(positionId);
        emit PositionDeregistered(strategy, positionId);
    }

    /*//////////////////////////////////////////////////////////////
                               ORACLE WRITE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev B2: returns the value actually booked into AUM (0 when the entry is skipped), so the
    ///      oracle can cache an aggregate equal to what the registry accepted, never the raw sum.
    function syncPositionFromReport(
        address strategy,
        bytes32 positionId,
        uint256 value,
        uint256 timestamp
    )
        external
        onlyAUMOracle
        returns (uint256 acceptedValue)
    {
        CrossChainPosition storage pos = _positions[positionId];

        // P2-3: the position must belong to `strategy`. A None/foreign id (strategy == 0 or a
        // different strategy) is skipped, never reverted, so a stray id in a report cannot corrupt
        // another strategy's value nor brick the report (SEC-9). The oracle's canonical-set
        // validation rejects such ids up front; this is defense in depth.
        if (pos.strategy != strategy) return 0;

        PositionStatus status = pos.status;

        // Exited/Invalidated: skip, never revert (SEC-9 defense in depth - the oracle's
        // canonical-set validation already rejects these ids).
        if (status == PositionStatus.Exited || status == PositionStatus.Invalidated) {
            return 0;
        }

        if (status == PositionStatus.Pending) {
            if (block.timestamp > pos.registeredAt + POSITION_CONFIRMATION_TIMEOUT) {
                // Timed out: never entered AUM. Release its reservation (re-consumable if the
                // fill lands even later) and evict.
                pos.status = PositionStatus.Invalidated;
                _releasePositionReservation(pos.reservationId);
                _strategyPositions[strategy].remove(positionId);
                emit PositionInvalidated(strategy, positionId);
                return 0;
            }
            if (value == 0) {
                // Signers attest "not yet verified" - stays Pending (positive confirmation only).
                return 0;
            }
            // First funded inclusion = confirmation. Settle the reservation: in-flight ->
            // counted exposure, terminally reconciled (K1).
            pos.status = PositionStatus.Active;
            _settlePositionReservation(pos.reservationId, positionId);
        }

        // Active/WindingDown (and just-confirmed): update value.
        pos.lastReportedValue = value;
        pos.lastReportTimestamp = timestamp;
        emit PositionSynced(positionId, pos.status, value, timestamp);
        return value;
    }

    /*//////////////////////////////////////////////////////////////
                               HOOK WRITE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionRegistry
    function recordBridgedOut(
        address strategy,
        uint64 chainId,
        address destinationVault,
        uint256 amount
    )
        external
        returns (bytes32 reservationId)
    {
        if (!authorizedBridgeHook[msg.sender]) revert UNAUTHORIZED_BRIDGE_HOOK();
        if (amount == 0) revert RESERVATION_NOT_CONSUMABLE();

        reservationId = keccak256(abi.encode(strategy, chainId, destinationVault, amount, _reservationSalt++));
        BridgeReservation storage res = _reservations[reservationId];
        res.strategy = strategy;
        res.chainId = chainId;
        res.destinationVault = destinationVault;
        res.amount = amount;
        res.createdAt = block.timestamp;
        res.status = ReservationStatus.Open;

        _countReservation(res);
        emit BridgedOutRecorded(strategy, chainId, destinationVault, amount, reservationId);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function releaseExpiredReservation(bytes32 reservationId) external {
        BridgeReservation storage res = _reservations[reservationId];
        if (res.status != ReservationStatus.Open) revert RESERVATION_NOT_CONSUMABLE();
        if (block.timestamp <= res.createdAt + RESERVATION_TIMEOUT) revert RESERVATION_NOT_EXPIRED();

        res.status = ReservationStatus.Released;
        _uncountReservation(res);
        emit ReservationReleased(reservationId);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev P2-1: permissionless cleanup for a Pending position that timed out without confirming
    ///      (e.g. a failed bridge). Releases its reservation and evicts it, so a never-confirmed
    ///      bridge cannot permanently reserve cap headroom or a position slot. The oracle's
    ///      completeness rule stops requiring expired Pending positions, so without this they
    ///      would otherwise never be cleaned up.
    function invalidateExpiredPending(address strategy, bytes32 positionId) external {
        CrossChainPosition storage pos = _positions[positionId];
        if (pos.strategy != strategy || pos.status != PositionStatus.Pending) revert INVALID_POSITION_STATUS();
        if (block.timestamp <= pos.registeredAt + POSITION_CONFIRMATION_TIMEOUT) revert POSITION_NOT_EXPIRED();

        pos.status = PositionStatus.Invalidated;
        _releasePositionReservation(pos.reservationId);
        _strategyPositions[strategy].remove(positionId);
        emit PositionInvalidated(strategy, positionId);
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionRegistry
    function setRegistrar(address strategy, address registrar) external onlyGovernor {
        if (strategy == address(0) || registrar == address(0)) revert ZERO_ADDRESS();
        registrars[strategy] = registrar;
        emit RegistrarUpdated(strategy, registrar);
    }

    /// @notice Authorize/deauthorize a SuperVault*CapBridgeHook to record in-flight exposure
    /// @dev GOVERNOR_ROLE only. Pairs with the SEC-1 config invariant (only capped bridge hooks
    ///      are registered on cross-chain host chains).
    function setBridgeHookAuthorization(address hook, bool authorized) external onlyGovernor {
        if (hook == address(0)) revert ZERO_ADDRESS();
        authorizedBridgeHook[hook] = authorized;
        emit BridgeHookAuthorizationUpdated(hook, authorized);
    }

    /*//////////////////////////////////////////////////////////////
                              VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionRegistry
    function positions(bytes32 positionId) external view returns (CrossChainPosition memory) {
        return _positions[positionId];
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function reservations(bytes32 reservationId) external view returns (BridgeReservation memory) {
        return _reservations[reservationId];
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function getPositionIds(address strategy) external view returns (bytes32[] memory) {
        return _strategyPositions[strategy].values();
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function positionValue(bytes32 positionId) external view returns (uint256) {
        CrossChainPosition memory pos = _positions[positionId];
        return
            (pos.status == PositionStatus.Active || pos.status == PositionStatus.WindingDown)
                ? pos.lastReportedValue
                : 0;
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function getCrossChainAUM(address strategy) public view returns (uint256 total) {
        bytes32[] memory ids = _strategyPositions[strategy].values();
        uint256 len = ids.length;
        for (uint256 i; i < len; ++i) {
            CrossChainPosition storage pos = _positions[ids[i]];
            if (pos.status == PositionStatus.Active || pos.status == PositionStatus.WindingDown) {
                total += pos.lastReportedValue;
            }
        }
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function getChainExposure(address strategy, uint64 chainId) public view returns (uint256 total) {
        bytes32[] memory ids = _strategyPositions[strategy].values();
        uint256 len = ids.length;
        for (uint256 i; i < len; ++i) {
            CrossChainPosition storage pos = _positions[ids[i]];
            if (
                pos.chainId == chainId
                    && (pos.status == PositionStatus.Active || pos.status == PositionStatus.WindingDown)
            ) {
                total += pos.lastReportedValue;
            }
        }
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function getEffectiveCrossChainExposure(address strategy) external view returns (uint256) {
        return getCrossChainAUM(strategy) + bridgedOut[strategy];
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function getEffectiveChainExposure(address strategy, uint64 chainId) external view returns (uint256) {
        return getChainExposure(strategy, chainId) + bridgedOutByChain[strategy][chainId];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Count a reservation into the in-flight aggregates. Every counted reservation is
    ///      uncounted exactly once (settle/release), so the K1 accounting is exact — no clamping
    ///      (the pre-K1 P2-2 clamp) is needed or wanted.
    function _countReservation(BridgeReservation storage res) internal {
        bridgedOut[res.strategy] += res.amount;
        bridgedOutByChain[res.strategy][res.chainId] += res.amount;
    }

    /// @dev Uncount a reservation from the in-flight aggregates (exact inverse of _count).
    function _uncountReservation(BridgeReservation storage res) internal {
        bridgedOut[res.strategy] -= res.amount;
        bridgedOutByChain[res.strategy][res.chainId] -= res.amount;
    }

    /// @dev Terminal reconciliation: the position this reservation funded was oracle-confirmed.
    function _settlePositionReservation(bytes32 reservationId, bytes32 positionId) internal {
        BridgeReservation storage res = _reservations[reservationId];
        res.status = ReservationStatus.Settled;
        _uncountReservation(res);
        emit ReservationSettled(reservationId, positionId);
    }

    /// @dev Non-terminal release: the position this reservation funded was invalidated before
    ///      confirmation. The reservation may be re-consumed by a later registration (late fill).
    function _releasePositionReservation(bytes32 reservationId) internal {
        BridgeReservation storage res = _reservations[reservationId];
        res.status = ReservationStatus.Released;
        _uncountReservation(res);
        emit ReservationReleased(reservationId);
    }
}
