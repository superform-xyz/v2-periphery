// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ICrossChainPositionRegistry } from "../interfaces/CrossChain/ICrossChainPositionRegistry.sol";

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

    /// @notice Minimum age of a never-observed Pending position before GOVERNANCE may invalidate it
    ///         (R6: time alone never uncounts - expiry only makes the trusted resolution eligible)
    uint256 public constant POSITION_CONFIRMATION_TIMEOUT = 2 hours;

    /// @notice Minimum age of an unconsumed (never-registered) reservation before GOVERNANCE may
    ///         release it with a no-fill/refund attestation (K1 / R6). Also the upper bound the
    ///         Across cap hook imposes on fillDeadlineOffset, so no Across fill can land after a
    ///         reservation became releasable.
    uint256 public constant RESERVATION_TIMEOUT = 2 hours;

    /// @notice R2-B1/K1: minimum first-report value, as a fraction of the reservation's
    ///         deployedAmount, for a Pending position to CONFIRM (and settle its reservation).
    ///         Prevents a partial destination execution (e.g. deposit 1 of a bridged 100) from
    ///         retiring the full 100-unit reservation on any non-zero report: below the threshold
    ///         the position stays Pending (still counted as in-flight) until it either reports a
    ///         near-full value or governance explicitly reconciles/invalidates it. 90% leaves
    ///         room for bridge relayer fees/slippage; both are bounded well under 10% in practice.
    uint256 public constant MIN_CONFIRMATION_BPS = 9000;

    /// @notice R4: maximum first-report value, as a fraction of the reservation's deployedAmount,
    ///         for a Pending position to CONFIRM. Without a ceiling, `prev == 0` skips the oracle's
    ///         per-position deviation band, so a compromised quorum could confirm a position at
    ///         many multiples of what was actually bridged (headroom/AUM manufacturing). 110%
    ///         admits benign over-delivery (e.g. a relayer filling above the requested minimum);
    ///         anything further out of band is recorded as an observation and stays Pending until
    ///         governance reconciles it.
    uint256 public constant MAX_CONFIRMATION_BPS = 11_000;

    /// @notice Hard cap on live positions per strategy - bounds every full-set loop (SEC-9)
    uint256 public constant MAX_POSITIONS_PER_STRATEGY = 64;

    /// @notice Basis-point denominator for the confirmation band
    uint256 public constant BPS_PRECISION = 10_000;

    bytes32 private constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice SuperGovernor - source of roles and contract-registry lookups
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @dev GOVERNOR_ROLE id cached at construction (a constant on SuperGovernor) so governor-gated
    ///      paths do not pay an external call per invocation just to learn the role id
    bytes32 private immutable GOVERNOR_ROLE_ID;

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

    /// @dev R4: strategy => number of Open (not-yet-consumed) reservations. Together with the live
    ///      position set this upper-bounds the strategy's future position count, so recordBridgedOut
    ///      can refuse a send that provably could never be registered (MAX_POSITIONS_PER_STRATEGY).
    mapping(address => uint256) public openReservationCount;

    /// @dev R5: positive excess of a Pending position's OBSERVED (out-of-band) destination value
    ///      over its still-counted reservation, aggregated per strategy and per chain. A counted
    ///      reservation is a conservative exposure proxy only while reservation >= observed value;
    ///      once a quorum reports a HIGHER destination value, cap-facing exposure must count
    ///      max(reservation, observed) = reservation + this excess, or an above-ceiling first
    ///      report would be stored but economically invisible to both cap checks.
    mapping(address => uint256) public pendingObservedExcess;
    mapping(address => mapping(uint64 => uint256)) public pendingObservedExcessByChain;

    /// @dev hook => whether it may record in-flight exposure (governor-managed allowlist)
    mapping(address => bool) public authorizedBridgeHook;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        GOVERNOR_ROLE_ID = ISuperGovernor(superGovernor_).GOVERNOR_ROLE();
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
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(GOVERNOR_ROLE_ID, msg.sender)) {
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
        // Open = normal flow. Released = governance released it after the timeout (or its position was
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

        // R4: deliberately NO destination-approval re-check here. The reservation IS the proof
        // that the cap hook validated the destination at send time — by registration time the
        // capital has already left the hub, so refusing to track it would only push REAL landed
        // exposure off-book (revoke destination between send and registration -> registration
        // reverts -> reservation stranded until a governance release -> exposure reads 0 while funds sit
        // deployed). An approval revocation stops NEW sends at the cap hook; landed fills must
        // always be bookable.

        EnumerableSet.Bytes32Set storage set = _strategyPositions[strategy];
        if (set.length() >= MAX_POSITIONS_PER_STRATEGY) revert MAX_POSITIONS_REACHED();

        // SEC-12: salted id so re-deploying to the same destination after Exit/Invalidation
        // yields a distinct id, and concurrent deployments never collide.
        uint256 salt = _positionSalt[strategy]++;
        positionId = keccak256(abi.encode(strategy, chainId, destinationVault, salt));

        bool recounted = res.status == ReservationStatus.Released;
        if (recounted) _countReservation(res);
        else --openReservationCount[strategy]; // Open -> Consumed (Released was already un-counted)
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
    /// @dev B2/R5: returns the value actually booked into the oracle's committed aggregate, so the
    ///      oracle can cache exactly what the registry accepted. For every id the oracle's
    ///      canonical-set validation admits, the booked value EQUALS the supplied value except for
    ///      terminal ids (which book 0 and which the oracle excludes from its candidate total) —
    ///      the oracle hard-asserts that equality at commit (VALIDATION_COMMIT_MISMATCH), so the
    ///      validated snapshot and the published snapshot can never diverge.
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
            // R3-PF1/R4: a first report confirms only inside the [floor, ceiling] band around the
            // reservation amount - even after the timeout (a late but full landing must be
            // bookable, mirroring the reservation re-consume philosophy). The strict `value > 0`
            // keeps a 1-wei reservation (whose floor rounds to 0) from "confirming" on a zero
            // report; the ceiling keeps an unbounded first value from CONFIRMING the position and
            // settling its reservation - the observed value itself is booked (R5) and matched
            // 1:1 in cap exposure through the observed excess, so it can never open headroom.
            if (
                value > 0 && value >= Math.mulDiv(pos.deployedAmount, MIN_CONFIRMATION_BPS, BPS_PRECISION)
                    && value <= Math.mulDiv(pos.deployedAmount, MAX_CONFIRMATION_BPS, BPS_PRECISION)
            ) {
                pos.status = PositionStatus.Active;
                // R5: a prior above-ceiling observation's excess leaves the numerator here — the
                // confirmed value is booked through positionValue from now on.
                _setPendingExcess(pos, 0);
                // fall through to the value update below (which also settles the reservation)
            } else if (value > 0) {
                // R3-PF1: a positive out-of-band value (below floor OR above ceiling) means
                // capital LANDED but not as reserved. Record the observation and stay Pending
                // with the FULL reservation still counted - the landed value must never become
                // invisible, and invalidation is barred once any positive value was observed.
                // Resolution: a later in-band report confirms, or governance explicitly
                // reconciles the delivery (reconcileUnderDeliveredPosition).
                // R5: the observation is BOOKED into the committed aggregate (returned) so the
                // oracle's validated candidate equals its committed total, and any excess over
                // the reservation is counted in cap-facing exposure — a first report above the
                // ceiling can never be stored yet invisible to the caps. Below the floor the
                // reservation (>= observed) remains the conservative numerator; the denominator
                // still books the true landed value.
                _setPendingExcess(pos, value);
                pos.lastReportedValue = value;
                pos.lastReportTimestamp = timestamp;
                emit PendingValueObserved(strategy, positionId, value);
                return value;
            } else {
                // Zero value: stays Pending with its reservation counted - expired or not. R6: a
                // zero report past the timeout is NOT evidence the fill never landed (registration
                // followed fill detection), so the report path never uncounts it; only governance
                // (invalidateExpiredPending) resolves a genuinely never-landed position.
                return 0;
            }
        }

        // Active/WindingDown (and just-confirmed): update value. R4: the reservation settles on
        // the first COMMITTED report that books the position - normal confirmations settle right
        // here in the confirming call, while a governance-reconciled position (Active with a still
        // Consumed reservation) keeps its reservation counted until this point, so the oracle's
        // in-flight anchor covers its value for the report that first books it.
        if (_reservations[pos.reservationId].status == ReservationStatus.Consumed) {
            _settlePositionReservation(pos.reservationId, positionId);
        }
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
        if (strategy == address(0)) revert ZERO_ADDRESS();
        if (amount == 0) revert RESERVATION_NOT_CONSUMABLE();
        // R4: refuse a send that provably could never be registered — live positions plus Open
        // reservations already upper-bound the future position set at MAX_POSITIONS_PER_STRATEGY.
        // Failing here (before funds move) beats stranding a landed fill behind MAX_POSITIONS_REACHED.
        if (_strategyPositions[strategy].length() + openReservationCount[strategy] >= MAX_POSITIONS_PER_STRATEGY) {
            revert MAX_POSITIONS_REACHED();
        }

        reservationId = keccak256(abi.encode(strategy, chainId, destinationVault, amount, _reservationSalt++));
        BridgeReservation storage res = _reservations[reservationId];
        res.strategy = strategy;
        res.chainId = chainId;
        res.destinationVault = destinationVault;
        res.hook = msg.sender; // provenance: which cap hook minted it (evidence routing for the governance attestation)
        res.amount = amount;
        res.createdAt = block.timestamp;
        res.status = ReservationStatus.Open;

        _countReservation(res);
        ++openReservationCount[strategy];
        emit BridgedOutRecorded(strategy, chainId, destinationVault, amount, reservationId);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev R6: TIME ALONE NEVER UNCOUNTS EXPOSURE. Expiry only opens the door; the release itself is
    ///      an affirmative no-fill/refund attestation by GOVERNANCE after verifying the bridge-side
    ///      state (Across: deposit expired past its <= RESERVATION_TIMEOUT deadline and refunded on
    ///      origin; deBridge: order cancelled by the account's order authority or provably
    ///      unfilled; Stargate: message verified not delivered). Neither a wall clock nor the
    ///      registrar may do it: a clock cannot distinguish "never filled" from "filled but not yet
    ///      registered", and the registrar - which can withhold registration - must never gain a
    ///      unilateral way to reduce exposure (withhold, release, let the manager resend, register
    ///      late = headroom recycling). A wrong attestation is bounded: a late fill still
    ///      re-consumes the Released reservation (K1), so the worst case is a transient window.
    function releaseExpiredReservation(bytes32 reservationId) external onlyGovernor {
        BridgeReservation storage res = _reservations[reservationId];
        if (res.status != ReservationStatus.Open) revert RESERVATION_NOT_CONSUMABLE();
        if (block.timestamp <= res.createdAt + RESERVATION_TIMEOUT) revert RESERVATION_NOT_EXPIRED();

        res.status = ReservationStatus.Released;
        _uncountReservation(res);
        --openReservationCount[res.strategy];
        emit ReservationReleased(reservationId);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev R6: GOVERNANCE-ONLY trusted resolution (was permissionless, P2-1). A registered Pending
    ///      position is a fill the registrar already DETECTED - "no positive oracle observation
    ///      within the timeout" is a reporting delay, not evidence that the capital never landed.
    ///      Letting a wall clock release its reservation let anyone erase landed exposure and,
    ///      with a still-fresh AUM snapshot, reuse the same cap headroom. Governance invalidates
    ///      only after verifying the fill never happened / was refunded; the position and its
    ///      counted reservation otherwise stay on the book (the oracle keeps requiring it in every
    ///      report, so a late landing can still confirm through the report path).
    function invalidateExpiredPending(address strategy, bytes32 positionId) external onlyGovernor {
        CrossChainPosition storage pos = _positions[positionId];
        if (pos.strategy != strategy || pos.status != PositionStatus.Pending) revert INVALID_POSITION_STATUS();
        if (block.timestamp <= pos.registeredAt + POSITION_CONFIRMATION_TIMEOUT) revert POSITION_NOT_EXPIRED();
        // R3-PF1: once any positive destination value has been observed, capital LANDED - a
        // wall-clock timeout must not uncount it. Only reconcileUnderDeliveredPosition (trusted,
        // governance) or a later >= floor confirmation can resolve such a position.
        if (pos.lastReportedValue != 0) revert POSITION_HAS_LANDED_VALUE();

        pos.status = PositionStatus.Invalidated;
        _releasePositionReservation(pos.reservationId);
        _strategyPositions[strategy].remove(positionId);
        emit PositionInvalidated(strategy, positionId);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev R3-PF1: the EXPLICIT trusted reconciliation for an out-of-band delivery — a Pending
    ///      position past its timeout whose observed value is positive but outside the
    ///      confirmation band. Governance (not the registrar, not a wall clock) accepts the
    ///      difference between the reservation and the observed value as bridge loss/fees (or
    ///      over-delivery) and confirms the position at its observed value.
    ///      R4: the reservation is deliberately NOT settled here — it stays Consumed (counted)
    ///      until the next committed oracle report books the position (syncPositionFromReport
    ///      settles it inside that commit). Settling in a standalone governance tx would remove
    ///      the value from the oracle's in-flight anchor before any report has booked it, wedging
    ///      every subsequent honest report into the deviation breaker. Until that first commit the
    ///      position's value is conservatively double-counted in cap-facing exposure (reservation
    ///      + reported value) — fail-safe for caps, resolved by the next report.
    function reconcileUnderDeliveredPosition(address strategy, bytes32 positionId) external onlyGovernor {
        CrossChainPosition storage pos = _positions[positionId];
        if (pos.strategy != strategy || pos.status != PositionStatus.Pending) revert INVALID_POSITION_STATUS();
        if (block.timestamp <= pos.registeredAt + POSITION_CONFIRMATION_TIMEOUT) revert POSITION_NOT_EXPIRED();
        if (pos.lastReportedValue == 0) revert POSITION_NOT_DRAINED();

        // R5: once Active the observed value is booked through positionValue, so its Pending
        // excess leaves the numerator (the still-Consumed reservation keeps the temporary
        // conservative double-count described above until the first committing report).
        _setPendingExcess(pos, 0);
        pos.status = PositionStatus.Active;
        emit PositionReconciledUnderDelivery(strategy, positionId, pos.lastReportedValue, pos.deployedAmount);
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
    /// @dev R5: + the positive Pending observed excess, so every Pending position contributes
    ///      max(counted reservation, observed destination value).
    function getEffectiveCrossChainExposure(address strategy) external view returns (uint256) {
        return getCrossChainAUM(strategy) + bridgedOut[strategy] + pendingObservedExcess[strategy];
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function getEffectiveChainExposure(address strategy, uint64 chainId) external view returns (uint256) {
        return getChainExposure(strategy, chainId) + bridgedOutByChain[strategy][chainId]
            + pendingObservedExcessByChain[strategy][chainId];
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

    /// @dev R5: re-point a Pending position's contribution to the observed-excess aggregates from
    ///      its CURRENT observation (lastReportedValue, still unmodified by the caller) to
    ///      `newObserved`. Pass 0 when the position leaves the observed-Pending state (in-band
    ///      confirmation or governance reconciliation), so the excess is added and removed exactly
    ///      once per observation lifecycle — no clamping needed.
    function _setPendingExcess(CrossChainPosition storage pos, uint256 newObserved) internal {
        uint256 deployed = pos.deployedAmount;
        uint256 oldExcess = pos.lastReportedValue > deployed ? pos.lastReportedValue - deployed : 0;
        uint256 newExcess = newObserved > deployed ? newObserved - deployed : 0;
        if (newExcess == oldExcess) return;
        if (newExcess > oldExcess) {
            uint256 delta = newExcess - oldExcess;
            pendingObservedExcess[pos.strategy] += delta;
            pendingObservedExcessByChain[pos.strategy][pos.chainId] += delta;
        } else {
            uint256 delta = oldExcess - newExcess;
            pendingObservedExcess[pos.strategy] -= delta;
            pendingObservedExcessByChain[pos.strategy][pos.chainId] -= delta;
        }
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
