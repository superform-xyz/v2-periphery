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
    function registerPosition(
        address strategy,
        uint64 chainId,
        PositionKind kind,
        address destinationVault,
        uint256 deployedAmount,
        uint256 sharesHeld
    )
        external
        onlyRegistrar(strategy)
        returns (bytes32 positionId)
    {
        // Constrained model: SuperVault kind must name an approved (chain, vault); Idle must be
        // an enabled escrow with no vault/shares.
        ICrossChainPositionCapGuard capGuard =
            ICrossChainPositionCapGuard(SUPER_GOVERNOR.getAddress(CROSS_CHAIN_CAP_GUARD));
        if (kind == PositionKind.SuperVault) {
            if (destinationVault == address(0) || sharesHeld == 0) revert INVALID_KIND_CONFIG();
            if (!capGuard.isApprovedDestination(strategy, chainId, destinationVault)) {
                revert DESTINATION_NOT_APPROVED();
            }
        } else {
            if (destinationVault != address(0) || sharesHeld != 0) revert INVALID_KIND_CONFIG();
            if (!capGuard.isApprovedDestination(strategy, chainId, address(0))) revert DESTINATION_NOT_APPROVED();
        }

        EnumerableSet.Bytes32Set storage set = _strategyPositions[strategy];
        if (set.length() >= MAX_POSITIONS_PER_STRATEGY) revert MAX_POSITIONS_REACHED();

        // SEC-12: salted id so re-deploying to the same destination after Exit/Invalidation
        // yields a distinct id, and concurrent deployments never collide.
        uint256 salt = _positionSalt[strategy]++;
        positionId = keccak256(abi.encode(strategy, chainId, destinationVault, salt));

        _positions[positionId] = CrossChainPosition({
            strategy: strategy,
            chainId: chainId,
            kind: kind,
            destinationVault: destinationVault,
            deployedAmount: deployedAmount,
            sharesHeld: sharesHeld,
            lastReportedValue: 0,
            lastReportTimestamp: 0,
            registeredAt: block.timestamp,
            status: PositionStatus.Pending
        });
        set.add(positionId);

        emit PositionRegistered(strategy, positionId, chainId, kind, destinationVault);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    function beginPositionExit(address strategy, bytes32 positionId) external onlyRegistrar(strategy) {
        CrossChainPosition storage pos = _positions[positionId];
        if (pos.status != PositionStatus.Active) revert INVALID_POSITION_STATUS();
        pos.status = PositionStatus.WindingDown;
        emit PositionExitStarted(strategy, positionId);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev SEC-6: only removable once the oracle has reported the position at ~0 value
    ///      (confirmed drain), not on the registrar's say-so alone.
    function deregisterPosition(address strategy, bytes32 positionId) external onlyRegistrar(strategy) {
        CrossChainPosition storage pos = _positions[positionId];
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
    function syncPositionFromReport(
        address strategy,
        bytes32 positionId,
        uint256 value,
        uint256 timestamp
    )
        external
        onlyAUMOracle
    {
        CrossChainPosition storage pos = _positions[positionId];

        // P2-3: the position must belong to `strategy`. A None/foreign id (strategy == 0 or a
        // different strategy) is skipped, never reverted, so a stray id in a report cannot corrupt
        // another strategy's value nor brick the report (SEC-9).
        if (pos.strategy != strategy) return;

        PositionStatus status = pos.status;

        // Exited/Invalidated: skip, never revert - a position that exited between off-chain signing
        // and on-chain submission must not brick the whole report (SEC-9).
        if (status == PositionStatus.Exited || status == PositionStatus.Invalidated) {
            return;
        }

        if (status == PositionStatus.Pending) {
            if (block.timestamp > pos.registeredAt + POSITION_CONFIRMATION_TIMEOUT) {
                // Timed out: never entered AUM. Release its in-flight reservation and evict.
                pos.status = PositionStatus.Invalidated;
                _releaseBridgedOut(strategy, pos.chainId, pos.deployedAmount);
                _strategyPositions[strategy].remove(positionId);
                emit PositionInvalidated(strategy, positionId);
                return;
            }
            if (value == 0) {
                // Signers attest "not yet verified" - stays Pending (positive confirmation only).
                return;
            }
            // First funded inclusion = confirmation. Hand off in-flight -> counted exposure.
            pos.status = PositionStatus.Active;
            _releaseBridgedOut(strategy, pos.chainId, pos.deployedAmount);
        }

        // Active/WindingDown (and just-confirmed): update value.
        pos.lastReportedValue = value;
        pos.lastReportTimestamp = timestamp;
        emit PositionSynced(positionId, pos.status, value, timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                               HOOK WRITE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionRegistry
    function recordBridgedOut(address strategy, uint64 chainId, uint256 amount) external {
        if (!authorizedBridgeHook[msg.sender]) revert UNAUTHORIZED_BRIDGE_HOOK();
        bridgedOut[strategy] += amount;
        bridgedOutByChain[strategy][chainId] += amount;
        emit BridgedOutRecorded(strategy, chainId, amount);
    }

    /// @inheritdoc ICrossChainPositionRegistry
    /// @dev P2-1: permissionless cleanup for a Pending position that timed out without confirming
    ///      (e.g. a failed bridge). Releases its in-flight reservation and evicts it, so a
    ///      never-confirmed bridge cannot permanently reserve cap headroom or a position slot. The
    ///      oracle's completeness rule stops requiring expired Pending positions, so without this
    ///      they would otherwise never be cleaned up.
    function invalidateExpiredPending(address strategy, bytes32 positionId) external {
        CrossChainPosition storage pos = _positions[positionId];
        if (pos.strategy != strategy || pos.status != PositionStatus.Pending) revert INVALID_POSITION_STATUS();
        if (block.timestamp <= pos.registeredAt + POSITION_CONFIRMATION_TIMEOUT) revert POSITION_NOT_EXPIRED();

        pos.status = PositionStatus.Invalidated;
        _releaseBridgedOut(strategy, pos.chainId, pos.deployedAmount);
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

    /// @dev Release an in-flight reservation. P2-2: clamp the global and per-chain decrements by a
    ///      SINGLE value (bounded by the per-chain outstanding, which is <= the global), so the two
    ///      counters can never diverge and a position on one chain can never consume another chain's
    ///      reservation. (Residual: positions sharing the same (strategy, chainId) still draw from a
    ///      common per-chain pool - acceptable, as they share one cap dimension.)
    function _releaseBridgedOut(address strategy, uint64 chainId, uint256 amount) internal {
        uint256 chainOutstanding = bridgedOutByChain[strategy][chainId];
        uint256 release = amount > chainOutstanding ? chainOutstanding : amount;
        bridgedOutByChain[strategy][chainId] = chainOutstanding - release;
        bridgedOut[strategy] -= release; // release <= chainOutstanding <= bridgedOut[strategy]
    }
}
