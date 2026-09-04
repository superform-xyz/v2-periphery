// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ICrossChainAUMOracle } from "../interfaces/CrossChain/ICrossChainAUMOracle.sol";
import { ICrossChainPositionRegistry } from "../interfaces/CrossChain/ICrossChainPositionRegistry.sol";

/// @title CrossChainAUMOracle
/// @author Superform Labs
/// @notice Receives quorum-signed PER-POSITION cross-chain value reports. The cross-chain
///         aggregate and the cap denominator are derived on-chain from one signed snapshot; a
///         circuit breaker + forceAUMUpdate handle moves larger than the deviation band. See
///         specs/cross-chain-supervaults/technical-spec.md.
contract CrossChainAUMOracle is ICrossChainAUMOracle, EIP712 {
    /// @dev Report fields bundled to keep the stack shallow during signature verification
    struct SubmissionData {
        bytes32 pidHash;
        bytes32 valHash;
        uint256 hubAssets;
        uint256 timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MIN_MAX_STALENESS = 10 minutes;
    uint256 public constant MAX_MAX_STALENESS = 24 hours;
    uint256 public constant MAX_DEVIATION_THRESHOLD = 0.5e18; // 50% (aggregate)
    uint256 public constant MAX_POSITION_DEVIATION_THRESHOLD = 0.75e18; // 75% (per-position)
    uint256 public constant MIN_UPDATE_INTERVAL = 1 minutes;
    uint256 public constant MAX_CONSISTENCY_TOLERANCE_BPS = 500; // 5%
    uint256 public constant MAX_CONSECUTIVE_BREACHES = 10;

    /// @dev hubAssets is signed (SEC-7); values are hub-asset-denominated (SEC-14)
    bytes32 public constant UPDATE_AUM_TYPEHASH = keccak256(
        "UpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );
    /// @dev SEC-13: distinct typehash so force/normal signatures are not cross-replayable
    bytes32 public constant FORCE_UPDATE_AUM_TYPEHASH = keccak256(
        "ForceUpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );

    bytes32 private constant CROSS_CHAIN_POSITION_REGISTRY = keccak256("CROSS_CHAIN_POSITION_REGISTRY");
    bytes32 private constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    ISuperGovernor public immutable SUPER_GOVERNOR;

    mapping(address => AUMReport) private _latestReport;
    mapping(address => AUMOracleConfig) private _configs;
    mapping(address => uint256) public noncePerStrategy;
    mapping(address => uint256) public consecutiveBreaches;
    mapping(address => bool) public aumBreakerTripped;

    /// @dev R2-AUM1: true once ANY report has been committed for the strategy. The hubAssets
    ///      bootstrap exemption keys on this flag, not on `current.hubAssets == 0` — a zero hub
    ///      balance is a legitimate steady state (fully deployed cross-chain) and must not
    ///      re-arm the unbounded first-report exemption.
    mapping(address => bool) public reportBootstrapped;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superGovernor_, string memory name_, string memory version_) EIP712(name_, version_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
    }

    /*//////////////////////////////////////////////////////////////
                              CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainAUMOracle
    function setAUMOracleConfig(address strategy, AUMOracleConfig calldata config) external {
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.ORACLE_MANAGER_ROLE(), msg.sender)) {
            revert UNAUTHORIZED_CONFIG();
        }
        if (config.maxStaleness < MIN_MAX_STALENESS || config.maxStaleness > MAX_MAX_STALENESS) {
            revert INVALID_CONFIG();
        }
        if (config.deviationThreshold == 0 || config.deviationThreshold > MAX_DEVIATION_THRESHOLD) {
            revert INVALID_CONFIG();
        }
        if (config.minUpdateInterval < MIN_UPDATE_INTERVAL || config.minUpdateInterval >= config.maxStaleness) {
            revert INVALID_CONFIG();
        }
        if (
            config.perPositionDeviationThreshold == 0
                || config.perPositionDeviationThreshold > MAX_POSITION_DEVIATION_THRESHOLD
        ) revert INVALID_CONFIG();
        if (config.consistencyToleranceBps == 0 || config.consistencyToleranceBps > MAX_CONSISTENCY_TOLERANCE_BPS) {
            revert INVALID_CONFIG();
        }
        if (
            config.maxConsecutiveDeviationBreaches == 0
                || config.maxConsecutiveDeviationBreaches > MAX_CONSECUTIVE_BREACHES
        ) {
            revert INVALID_CONFIG();
        }
        _configs[strategy] = config;
        emit AUMOracleConfigUpdated(strategy);
    }

    /*//////////////////////////////////////////////////////////////
                              REPORTS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainAUMOracle
    function forwardAUM(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 hubAssets,
        uint256 timestamp,
        bytes[] calldata proofs
    )
        external
    {
        if (positionIds.length != values.length) revert LENGTH_MISMATCH();
        AUMOracleConfig memory config = _configs[strategy];
        uint256 usedNonce =
            _verifyAndConsume(strategy, _bundle(positionIds, values, hubAssets, timestamp), proofs, config, false);
        _validateReportSet(strategy, positionIds, timestamp);

        // Derive aggregate on-chain.
        uint256 total = _sum(values);
        AUMReport memory current = _latestReport[strategy];

        // P2-4: bound the signed hubAssets too - it feeds getTotalAUM (the cap denominator) but is
        // otherwise unconstrained when the SEC-8 band is inactive (no live PPS source). A single
        // inflated hubAssets would otherwise enlarge cap headroom unchecked.
        if (current.hubAssets > 0) {
            if (_relDiff(hubAssets, current.hubAssets) > config.deviationThreshold) {
                emit AUMDeviationExceeded(strategy, current.hubAssets, hubAssets);
                _recordDeviationBreach(strategy, config);
                return;
            }
        } else if (reportBootstrapped[strategy] && hubAssets > 0 && _impliedAssets(strategy) == 0) {
            // R2-AUM1: only the strategy's true FIRST report is a trusted bootstrap. A later
            // zero-to-positive hubAssets transition (hub was legitimately empty) is unbounded by
            // the deviation check (prev == 0), so it may only commit while the PPS x supply
            // backstop is LIVE (the SEC-8 band below then constrains the total). With no live
            // source it soft-fails instead of enlarging the cap denominator unchecked.
            emit AUMDeviationExceeded(strategy, 0, hubAssets);
            _recordDeviationBreach(strategy, config);
            return;
        }

        // Aggregate deviation / zero-crossing anchor.
        if (current.totalCrossChainAssets > 0) {
            if (_relDiff(total, current.totalCrossChainAssets) > config.deviationThreshold) {
                emit AUMDeviationExceeded(strategy, current.totalCrossChainAssets, total);
                _recordDeviationBreach(strategy, config);
                return;
            }
        } else {
            // SEC-16: anchor a bootstrap/zero-crossing report to actually-bridged capital.
            uint256 anchor = ICrossChainPositionRegistry(_registry()).bridgedOut(strategy);
            if (total > anchor + (anchor * config.deviationThreshold) / 1e18) {
                emit AUMDeviationExceeded(strategy, 0, total);
                _recordDeviationBreach(strategy, config);
                return;
            }
        }

        // SEC-14: per-position deviation.
        if (_perPositionBreach(strategy, positionIds, values, config.perPositionDeviationThreshold)) {
            _recordDeviationBreach(strategy, config);
            return;
        }

        // SEC-8: PPS<->AUM consistency band.
        if (_consistencyBreach(strategy, hubAssets + total, config.consistencyToleranceBps)) {
            _recordDeviationBreach(strategy, config);
            return;
        }

        uint256 committed = _syncAndCommit(strategy, positionIds, values, hubAssets, timestamp, usedNonce);
        emit AUMUpdated(strategy, committed, timestamp);
    }

    /// @inheritdoc ICrossChainAUMOracle
    /// @dev SEC-13 recovery: dual-gated (quorum in proofs AND ORACLE_MANAGER submitter), skips
    ///      ONLY the deviation checks, STILL enforces the SEC-8 consistency band, clears breaker.
    ///      K2: unavailable/stale PPS source -> force recovery is BLOCKED (the band is the only
    ///      bound left on this path, so it must be live).
    function forceAUMUpdate(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 hubAssets,
        uint256 timestamp,
        bytes[] calldata proofs
    )
        external
    {
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.ORACLE_MANAGER_ROLE(), msg.sender)) {
            revert UNAUTHORIZED_FORCE_UPDATE();
        }
        if (positionIds.length != values.length) revert LENGTH_MISMATCH();
        AUMOracleConfig memory config = _configs[strategy];
        uint256 usedNonce =
            _verifyAndConsume(strategy, _bundle(positionIds, values, hubAssets, timestamp), proofs, config, true);
        _validateReportSet(strategy, positionIds, timestamp);

        uint256 total = _sum(values);

        // K2: force recovery is ONLY available while the PPS x supply backstop is live — with no
        // implied-assets source the SEC-8 band would be vacuous and quorum + ORACLE_MANAGER could
        // force an arbitrary complete report and clear the breaker unchecked (PR #336 review K2).
        if (_impliedAssets(strategy) == 0) revert FORCE_REQUIRES_PPS_SOURCE();

        // Deviation checks SKIPPED. Consistency band STILL enforced (the backstop).
        if (_consistencyBreach(strategy, hubAssets + total, config.consistencyToleranceBps)) {
            _recordDeviationBreach(strategy, config);
            return;
        }

        uint256 committed = _syncAndCommit(strategy, positionIds, values, hubAssets, timestamp, usedNonce);
        emit AUMForceUpdated(strategy, committed, timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP-712 domain separator (for off-chain signers / tests)
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @inheritdoc ICrossChainAUMOracle
    function isAUMFresh(address strategy) external view returns (bool) {
        AUMReport memory report = _latestReport[strategy];
        AUMOracleConfig memory config = _configs[strategy];
        if (config.maxStaleness == 0 || report.timestamp == 0) return false; // fail-safe
        if (aumBreakerTripped[strategy]) return false; // SEC-13
        return block.timestamp - report.timestamp <= config.maxStaleness;
    }

    /// @inheritdoc ICrossChainAUMOracle
    /// @dev SEC-7: hubAssets is a signed field of the latest report, not a live balance read.
    function getTotalAUM(address strategy) external view returns (uint256) {
        AUMReport memory r = _latestReport[strategy];
        return r.hubAssets + r.totalCrossChainAssets;
    }

    /// @inheritdoc ICrossChainAUMOracle
    function latestReport(address strategy) external view returns (AUMReport memory) {
        return _latestReport[strategy];
    }

    /// @inheritdoc ICrossChainAUMOracle
    function configs(address strategy) external view returns (AUMOracleConfig memory) {
        return _configs[strategy];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev Bundle report fields (keeps caller stacks shallow for the 7-field EIP-712 hash).
    function _bundle(
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 hubAssets,
        uint256 timestamp
    )
        internal
        pure
        returns (SubmissionData memory)
    {
        return SubmissionData({
            pidHash: keccak256(abi.encodePacked(positionIds)),
            valHash: keccak256(abi.encodePacked(values)),
            hubAssets: hubAssets,
            timestamp: timestamp
        });
    }

    /// @dev Quorum + signers + config + timestamp checks. Consumes and returns the nonce (so
    ///      soft-fails can't be replayed). Completeness is checked by the caller (needs the
    ///      positionIds array). Reverts on any hard failure.
    function _verifyAndConsume(
        address strategy,
        SubmissionData memory d,
        bytes[] calldata proofs,
        AUMOracleConfig memory config,
        bool isForce
    )
        internal
        returns (uint256 usedNonce)
    {
        if (proofs.length == 0) revert ZERO_LENGTH_ARRAY();
        // P3-8: fail fast on an unconfigured strategy BEFORE the expensive ecrecover loop.
        if (config.maxStaleness == 0) revert UNCONFIGURED_STRATEGY();
        // P3-2: local quorum floor - never accept a 1-of-N report if the PPS quorum is unset/0.
        uint256 quorum = SUPER_GOVERNOR.getPPSOracleQuorum();
        if (quorum == 0 || proofs.length < quorum) revert QUORUM_NOT_MET();

        _checkSigners(_digest(strategy, d, noncePerStrategy[strategy], isForce), proofs);

        uint256 lastTs = _latestReport[strategy].timestamp;
        if (d.timestamp > block.timestamp) revert FUTURE_TIMESTAMP();
        if (d.timestamp <= lastTs) revert STALE_UPDATE();
        if (d.timestamp - lastTs < config.minUpdateInterval) revert RATE_LIMITED();
        if (block.timestamp - d.timestamp > config.maxStaleness) revert DATA_TOO_STALE();

        // Consume nonce for any quorum-valid submission (soft-fails included).
        usedNonce = noncePerStrategy[strategy]++;
    }

    /// @dev EIP-712 digest for a report (normal or forced). Standard abi.encode encoding.
    function _digest(
        address strategy,
        SubmissionData memory d,
        uint256 nonce,
        bool isForce
    )
        internal
        view
        returns (bytes32)
    {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    isForce ? FORCE_UPDATE_AUM_TYPEHASH : UPDATE_AUM_TYPEHASH,
                    strategy,
                    d.pidHash,
                    d.valHash,
                    d.hubAssets,
                    d.timestamp,
                    nonce
                )
            )
        );
    }

    /// @dev Ascending-unique registered-validator signatures over `digest`.
    function _checkSigners(bytes32 digest, bytes[] calldata proofs) internal view {
        address last;
        uint256 len = proofs.length;
        for (uint256 i; i < len; ++i) {
            address signer = ECDSA.recover(digest, proofs[i]);
            if (!SUPER_GOVERNOR.isValidator(signer)) revert INVALID_VALIDATOR();
            if (signer <= last) revert INVALID_PROOF();
            last = signer;
        }
    }

    /// @dev B2: the submitted id set must EQUAL the canonical required set - strictly ascending
    ///      (no duplicates), every id owned by `strategy` and in the reportable status/time domain
    ///      (no extras), and every required position covered (SEC-9/SEC-14 completeness). This
    ///      guarantees the summed aggregate only contains entries the registry will accept.
    ///      A position that exits/expires between off-chain signing and submission now reverts the
    ///      report; the corrected set must be re-signed under the same (unconsumed) nonce.
    function _validateReportSet(address strategy, bytes32[] calldata positionIds, uint256 timestamp) internal view {
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(_registry());
        uint256 len = positionIds.length;
        if (len > registry.MAX_POSITIONS_PER_STRATEGY()) revert REPORT_TOO_LARGE();
        // P3-6: read the timeout from the registry (single source of truth) rather than a literal.
        uint256 timeout = registry.POSITION_CONFIRMATION_TIMEOUT();

        bytes32 prev;
        for (uint256 i; i < len; ++i) {
            bytes32 id = positionIds[i];
            if (i > 0 && id <= prev) revert UNSORTED_REPORT();
            prev = id;
            if (!_positionRequired(registry, strategy, id, timestamp, timeout)) revert UNKNOWN_POSITION_ID();
        }

        bytes32[] memory ids = registry.getPositionIds(strategy);
        uint256 openLen = ids.length;
        for (uint256 i; i < openLen; ++i) {
            if (_positionRequired(registry, strategy, ids[i], timestamp, timeout) && !_contains(positionIds, ids[i])) {
                revert INCOMPLETE_REPORT();
            }
        }
    }

    /// @dev Whether a position must be covered by a report for `strategy` timestamped at
    ///      `timestamp`. Foreign/None/Exited/Invalidated ids are never required (and, via
    ///      _validateReportSet, never accepted).
    function _positionRequired(
        ICrossChainPositionRegistry registry,
        address strategy,
        bytes32 id,
        uint256 timestamp,
        uint256 timeout
    )
        internal
        view
        returns (bool)
    {
        ICrossChainPositionRegistry.CrossChainPosition memory p = registry.positions(id);
        if (p.strategy != strategy) return false;
        if (
            p.status == ICrossChainPositionRegistry.PositionStatus.Active
                || p.status == ICrossChainPositionRegistry.PositionStatus.WindingDown
        ) return true;
        // Non-expired Pending registered before the report timestamp.
        return p.status == ICrossChainPositionRegistry.PositionStatus.Pending && p.registeredAt < timestamp
            && block.timestamp <= p.registeredAt + timeout;
    }

    /// @dev True if any covered position moves more than the per-position bound.
    function _perPositionBreach(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 threshold
    )
        internal
        returns (bool)
    {
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(_registry());
        uint256 len = positionIds.length;
        for (uint256 i; i < len; ++i) {
            uint256 prev = registry.positionValue(positionIds[i]);
            if (prev > 0 && _relDiff(values[i], prev) > threshold) {
                emit PositionDeviationExceeded(strategy, positionIds[i], prev, values[i]);
                return true;
            }
        }
        return false;
    }

    /// @dev SEC-8 band. Returns true (breach) when PPS and AUM disagree beyond tolerance. An
    ///      unavailable implied-assets source (0) leaves the band inactive on the NORMAL path
    ///      (deviation checks still bind there); the FORCE path hard-requires the source (K2).
    function _consistencyBreach(address strategy, uint256 totalAssets, uint256 toleranceBps) internal returns (bool) {
        uint256 implied = _impliedAssets(strategy);
        if (implied == 0) return false;
        if ((_absDiff(totalAssets, implied) * 10_000) / implied > toleranceBps) {
            emit PPSConsistencyBreached(strategy, implied, totalAssets);
            return true;
        }
        return false;
    }

    /// @dev K2: PPS x totalSupply for `strategy`, hub-asset-denominated. The strategy's SuperVault
    ///      computes exactly this as `totalAssets()` (totalSupply x storedPPS / 10^assetDecimals,
    ///      the PPS the ECDSA PPS-oracle quorum attested via the aggregator), so read it there:
    ///      strategy.getVaultInfo() -> vault -> vault.totalAssets().
    ///
    ///      Returns 0 — "no reliable source" — when any of the following holds, each read via a
    ///      tolerant staticcall so a non-SuperVault strategy can never brick a report:
    ///      - no aggregator registered, or the strategy does not expose getVaultInfo();
    ///      - the aggregator marks the strategy's PPS STALE (a stale PPS is not a backstop);
    ///      - the vault/totalAssets read fails or is zero (pre-seed vault).
    ///      A 0 result leaves the SEC-8 band inactive on the normal path and BLOCKS forceAUMUpdate.
    function _impliedAssets(address strategy) internal view virtual returns (uint256) {
        address aggregator = SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR);
        if (aggregator == address(0)) return 0;

        (bool ok, bytes memory ret) = strategy.staticcall(abi.encodeWithSignature("getVaultInfo()"));
        if (!ok || ret.length < 96) return 0;
        (address vault,,) = abi.decode(ret, (address, address, uint8));
        if (vault == address(0)) return 0;

        (ok, ret) = aggregator.staticcall(abi.encodeWithSignature("isPPSStale(address)", strategy));
        if (!ok || ret.length < 32 || abi.decode(ret, (bool))) return 0;

        (ok, ret) = vault.staticcall(abi.encodeWithSignature("totalAssets()"));
        if (!ok || ret.length < 32) return 0;
        return abi.decode(ret, (uint256));
    }

    /// @dev Push every reported value to the registry (single write path) and cache the report,
    ///      clearing the breaker (the feed is healthy again). B2: the cached aggregate is the sum
    ///      of what the registry ACCEPTED, never the raw submitted sum, so the cap denominator and
    ///      the registry numerator always derive from the same per-position snapshot.
    function _syncAndCommit(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 hubAssets,
        uint256 timestamp,
        uint256 usedNonce
    )
        internal
        returns (uint256 committed)
    {
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(_registry());
        uint256 len = positionIds.length;
        for (uint256 i; i < len; ++i) {
            committed += registry.syncPositionFromReport(strategy, positionIds[i], values[i], timestamp);
        }
        _latestReport[strategy] = AUMReport({
            totalCrossChainAssets: committed, hubAssets: hubAssets, timestamp: timestamp, nonce: usedNonce
        });
        reportBootstrapped[strategy] = true; // R2-AUM1: the bootstrap exemption is one-time
        consecutiveBreaches[strategy] = 0;
        if (aumBreakerTripped[strategy]) {
            aumBreakerTripped[strategy] = false;
            emit AUMBreakerReset(strategy);
        }
    }

    /// @dev Count a soft-fail toward the breaker; trip once the configured limit is reached.
    function _recordDeviationBreach(address strategy, AUMOracleConfig memory config) internal {
        uint256 n = ++consecutiveBreaches[strategy];
        if (n >= config.maxConsecutiveDeviationBreaches && !aumBreakerTripped[strategy]) {
            aumBreakerTripped[strategy] = true;
            emit AUMBreakerTripped(strategy, n);
        }
    }

    function _registry() internal view returns (address) {
        return SUPER_GOVERNOR.getAddress(CROSS_CHAIN_POSITION_REGISTRY);
    }

    function _sum(uint256[] calldata xs) internal pure returns (uint256 s) {
        uint256 len = xs.length;
        for (uint256 i; i < len; ++i) {
            s += xs[i];
        }
    }

    function _contains(bytes32[] calldata xs, bytes32 v) internal pure returns (bool) {
        uint256 len = xs.length;
        for (uint256 i; i < len; ++i) {
            if (xs[i] == v) return true;
        }
        return false;
    }

    function _absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function _relDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return b == 0 ? type(uint256).max : (_absDiff(a, b) * 1e18) / b;
    }
}
