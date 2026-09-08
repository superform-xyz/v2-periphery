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
    /// @dev R7: a snapshot must not outlive two reservation/confirmation cycles (2 x 2h) - a longer
    ///      freshness window let one stale denominator back many allocation cycles.
    uint256 public constant MAX_MAX_STALENESS = 4 hours;
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

    /// @dev R4 (P1): wall-clock time of the last COMMITTED report. The signed-timestamp rate
    ///      limit alone would let a compromised quorum ladder many minUpdateInterval-spaced
    ///      reports into a single block, compounding the deviation band arbitrarily fast in real
    ///      time (1.5^n in one block). Commits are therefore paced in wall-clock time as well.
    mapping(address => uint256) public lastCommitAt;

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
        if (strategy == address(0)) revert ZERO_ADDRESS();
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

        // Derive the aggregate on-chain. R4-F1: the CANDIDATE total (terminal entries excluded)
        // — every security band below must be computed over exactly what the registry can book,
        // or a tolerated terminal id's caller-supplied value could pad validation and vanish at
        // commit (cap-headroom reopening).
        uint256 total = _candidateTotal(positionIds, values);
        AUMReport memory current = _latestReport[strategy];

        // P2-4: bound the signed hubAssets too - it feeds getTotalAUM (the cap denominator) but is
        // otherwise unconstrained when the SEC-8 band is inactive (no live PPS source). A single
        // inflated hubAssets would otherwise enlarge cap headroom unchecked.
        // R7 (lifecycle-aware, like _aggregateBreach): only an UPWARD move of the PUBLISHED TOTAL
        // (hubAssets + candidate cross-chain) can open headroom, so that is what is banded - against
        // the previously committed total plus in-flight reservations (minus the observed-Pending
        // overlap), grown by θ. A downward hub move is the expected result of every cap-hook send
        // (the hub shrinks by exactly the reserved amount while the reservation enters in-flight),
        // an exit returns capital hub-ward with the cross-chain side shrinking by the same amount,
        // and a deposit up to θ of AUM commits - all through the normal path - while the
        // denominator envelope per report stays exactly the pre-R7 (1 + θ)·(total + in-flight):
        // a quorum cannot book value into the hub AND keep it cross-chain in the same report.
        // Downward moves are deliberately unbounded (quorum-trusted, denominator-shrinking only).
        // Soft-fails WITHOUT feeding the breaker: a large deposit is user-inducible (same
        // reasoning as the consistency band).
        if (current.hubAssets > 0) {
            if (_publishedTotalBreach(
                    strategy,
                    positionIds,
                    values,
                    total,
                    hubAssets,
                    current.hubAssets + current.totalCrossChainAssets,
                    config.deviationThreshold
                )) {
                emit AUMDeviationExceeded(strategy, current.hubAssets, hubAssets);
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

        // Aggregate deviation with lifecycle-aware anchoring (R4, generalizes SEC-16).
        if (_aggregateBreach(strategy, positionIds, values, total, current.totalCrossChainAssets, config)) {
            emit AUMDeviationExceeded(strategy, current.totalCrossChainAssets, total);
            _recordDeviationBreach(strategy, config);
            return;
        }

        // SEC-14: per-position deviation.
        if (_perPositionBreach(strategy, positionIds, values, config.perPositionDeviationThreshold)) {
            _recordDeviationBreach(strategy, config);
            return;
        }

        // SEC-8: PPS<->AUM consistency band. R4: soft-fail WITHOUT feeding the breaker — a
        // consistency divergence is attacker-inducible (any depositor can move vault.totalAssets
        // between report signing and submission), so it must not be able to trip the breaker;
        // persistent divergence still fails safe through report staleness.
        if (_consistencyBreach(strategy, hubAssets + total, config.consistencyToleranceBps)) {
            return;
        }

        uint256 committed = _syncAndCommit(strategy, positionIds, values, total, hubAssets, timestamp, usedNonce);
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

        // R4-F1: candidate total (terminal entries excluded) — see forwardAUM.
        uint256 total = _candidateTotal(positionIds, values);

        // K2: force recovery is ONLY available while the PPS x supply backstop is live — with no
        // implied-assets source the SEC-8 band would be vacuous and quorum + ORACLE_MANAGER could
        // force an arbitrary complete report and clear the breaker unchecked (PR #336 review K2).
        if (_impliedAssets(strategy) == 0) revert FORCE_REQUIRES_PPS_SOURCE();

        // Deviation checks SKIPPED. Consistency band STILL enforced (the backstop). R4: like the
        // normal path, a consistency soft-fail does not feed the breaker (attacker-inducible).
        if (_consistencyBreach(strategy, hubAssets + total, config.consistencyToleranceBps)) {
            return;
        }

        uint256 committed = _syncAndCommit(strategy, positionIds, values, total, hubAssets, timestamp, usedNonce);
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
        // R4 (P1): the interval must also elapse in WALL-CLOCK time since the last commit —
        // signed timestamps alone are attacker-chosen and allow same-block report ladders.
        uint256 lastCommit = lastCommitAt[strategy];
        if (lastCommit != 0 && block.timestamp < lastCommit + config.minUpdateInterval) revert RATE_LIMITED();

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
    ///      (no duplicates), every id owned by `strategy` and in the reportable status/time domain,
    ///      and every required position covered (SEC-9/SEC-14 completeness). Terminal (Exited/
    ///      Invalidated) strategy-owned ids are TOLERATED for sign-vs-submit races, but their
    ///      values are excluded from every validation total via _candidateTotal (R4-F1), so the
    ///      validated aggregate equals what the registry will accept. R5: that equality is now
    ///      exact and hard-asserted at commit (VALIDATION_COMMIT_MISMATCH) - an out-of-band
    ///      Pending observation is BOOKED by the registry (with its excess over the reservation
    ///      counted in cap exposure), so no supplied non-terminal value can pass validation and
    ///      then vanish from, or be understated in, the published snapshot.
    function _validateReportSet(address strategy, bytes32[] calldata positionIds, uint256 timestamp) internal view {
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(_registry());
        uint256 len = positionIds.length;
        if (len > registry.MAX_POSITIONS_PER_STRATEGY()) revert REPORT_TOO_LARGE();

        bytes32 prev;
        for (uint256 i; i < len; ++i) {
            bytes32 id = positionIds[i];
            if (i > 0 && id <= prev) revert UNSORTED_REPORT();
            prev = id;
            if (!_positionRequired(registry, strategy, id, timestamp)) {
                // R4 liveness: a position that flipped to a TERMINAL state between off-chain
                // signing and submission (deregistered exit, expired Pending invalidated — incl.
                // by a governance invalidation landing first) is tolerated, not reverted: the
                // registry safely skips terminal ids (books 0), so the report can still commit
                // without a full re-sign. Foreign/unknown ids still hard-revert.
                ICrossChainPositionRegistry.CrossChainPosition memory p = registry.positions(id);
                if (
                    p.strategy != strategy
                        || (p.status != ICrossChainPositionRegistry.PositionStatus.Exited
                            && p.status != ICrossChainPositionRegistry.PositionStatus.Invalidated)
                ) revert UNKNOWN_POSITION_ID();
            }
        }

        bytes32[] memory ids = registry.getPositionIds(strategy);
        uint256 openLen = ids.length;
        for (uint256 i; i < openLen; ++i) {
            if (_positionRequired(registry, strategy, ids[i], timestamp) && !_contains(positionIds, ids[i])) {
                revert INCOMPLETE_REPORT();
            }
        }
    }

    /// @dev Whether a position must be covered by a report for `strategy` timestamped at
    ///      `timestamp`. Foreign/None/Exited/Invalidated ids are never required.
    function _positionRequired(
        ICrossChainPositionRegistry registry,
        address strategy,
        bytes32 id,
        uint256 timestamp
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
        // R4: a Pending position registered before the report timestamp is ALWAYS required —
        // while unexpired it must be watched, and after expiry it must STILL be covered so that a
        // late landing can confirm through the report path (R3-PF1). R6: an expired Pending that
        // keeps reporting zero simply stays Pending with its reservation counted (never uncounted
        // by a wall clock); governance resolves a genuinely never-landed position.
        return p.status == ICrossChainPositionRegistry.PositionStatus.Pending && p.registeredAt < timestamp;
    }

    /// @dev R4 lifecycle-aware aggregate band (generalizes SEC-16 to every report, not only
    ///      zero-crossings). UPWARD: the raw total is bounded by the committed cache PLUS capital
    ///      currently in flight (Open/Consumed reservations), grown by the threshold — a
    ///      confirming position's value is backed 1:1 by its still-counted reservation at
    ///      validation time (settlement happens inside the commit), so a legitimate landing of
    ///      any size never breaches. DOWNWARD: bounded by the cache minus the previously
    ///      committed value of WindingDown positions this report drains to zero (the expected
    ///      terminal report of an exit), grown by the threshold.
    function _aggregateBreach(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 total,
        uint256 cache,
        AUMOracleConfig memory config
    )
        internal
        view
        returns (bool)
    {
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(_registry());
        (uint256 drained, uint256 overlap) = _anchorAdjustments(registry, positionIds, values);

        // R5-H: an observed Pending position's booked value sits in `cache` while its reservation
        // is still in bridgedOut - subtract the overlap so the upper anchor is not loose by up to
        // the reservation for as long as the position stays Pending.
        uint256 inFlight = registry.bridgedOut(strategy);
        uint256 upperBase = cache + (inFlight > overlap ? inFlight - overlap : 0);
        if (total > upperBase + (upperBase * config.deviationThreshold) / 1e18) return true;

        uint256 lowerBase = cache > drained ? cache - drained : 0;
        return total < lowerBase - (lowerBase * config.deviationThreshold) / 1e18;
    }

    /// @dev R7: the published-total band. hubAssets + candidate total must not exceed
    ///      (prevTotal + inFlight - overlap)·(1 + θ) - the same envelope the aggregate band grants
    ///      the cross-chain side alone, so adding the hub dimension cannot widen it (see forwardAUM).
    function _publishedTotalBreach(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 total,
        uint256 hubAssets,
        uint256 prevTotal,
        uint256 threshold
    )
        internal
        view
        returns (bool)
    {
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(_registry());
        (, uint256 overlap) = _anchorAdjustments(registry, positionIds, values);
        uint256 inFlight = registry.bridgedOut(strategy);
        uint256 anchor = prevTotal + (inFlight > overlap ? inFlight - overlap : 0);
        return hubAssets + total > anchor + (anchor * threshold) / 1e18;
    }

    /// @dev Anchor adjustments for _aggregateBreach (split out to keep the stack shallow):
    ///      `drained` = previously committed value of WindingDown positions this report drains to
    ///      zero (the expected terminal report of an exit); `overlap` = for every observed Pending
    ///      position, the part of its counted reservation already represented by its booked
    ///      observation, min(reservation, observed) (R5-H).
    function _anchorAdjustments(
        ICrossChainPositionRegistry registry,
        bytes32[] calldata positionIds,
        uint256[] calldata values
    )
        internal
        view
        returns (uint256 drained, uint256 overlap)
    {
        uint256 len = positionIds.length;
        for (uint256 i; i < len; ++i) {
            ICrossChainPositionRegistry.CrossChainPosition memory p = registry.positions(positionIds[i]);
            if (p.status == ICrossChainPositionRegistry.PositionStatus.WindingDown) {
                if (values[i] == 0) drained += p.lastReportedValue;
            } else if (p.status == ICrossChainPositionRegistry.PositionStatus.Pending && p.lastReportedValue > 0) {
                overlap += p.lastReportedValue < p.deployedAmount ? p.lastReportedValue : p.deployedAmount;
            }
        }
    }

    /// @dev True if any covered position moves more than the per-position bound. R5-H: the anchor
    ///      is the position's last BOOKED value - a confirmed (Active/WindingDown) value or an
    ///      out-of-band Pending observation (booked since R5) - so an observed-Pending value is
    ///      bounded exactly like a confirmed one instead of floating freely until confirmation. A
    ///      never-observed Pending (prev == 0) is bounded by the aggregate band's in-flight anchor.
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
            ICrossChainPositionRegistry.CrossChainPosition memory p = registry.positions(positionIds[i]);
            bool live = p.status == ICrossChainPositionRegistry.PositionStatus.Active
                || p.status == ICrossChainPositionRegistry.PositionStatus.WindingDown
                || p.status == ICrossChainPositionRegistry.PositionStatus.Pending;
            uint256 prev = live ? p.lastReportedValue : 0;
            if (prev > 0 && _relDiff(values[i], prev) > threshold) {
                // R4: a WindingDown position draining to ZERO is the expected terminal report of
                // an exit (double-gated: the registrar began the exit AND a quorum signed the
                // zero), not a market move. Without this carve-out no exit could ever complete
                // through the report path — a zero report is definitionally a 100% deviation.
                if (values[i] == 0 && p.status == ICrossChainPositionRegistry.PositionStatus.WindingDown) continue;
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
    ///      - the strategy does not expose getVaultInfo() (an UNSET aggregator key makes
    ///        SuperGovernor.getAddress revert, i.e. reports fail closed, not tolerant);
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
    ///      R5 snapshot invariant: the booked sum must EQUAL `validatedTotal` — the candidate every
    ///      security band (aggregate, per-position, PPS consistency) was computed over. The
    ///      registry books every non-terminal supplied value (including out-of-band Pending
    ///      observations, whose excess it counts in cap exposure) and the candidate excludes the
    ///      terminal ids the registry skips, so equality holds by construction; a divergence
    ///      means a validated-vs-published mismatch and the whole report reverts instead of
    ///      renewing AUM freshness on a snapshot nobody validated.
    function _syncAndCommit(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 validatedTotal,
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
        if (committed != validatedTotal) revert VALIDATION_COMMIT_MISMATCH();
        _latestReport[strategy] = AUMReport({
            totalCrossChainAssets: committed, hubAssets: hubAssets, timestamp: timestamp, nonce: usedNonce
        });
        lastCommitAt[strategy] = block.timestamp; // R4: wall-clock commit pacing
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

    /// @dev R4-F1: the candidate aggregate used by EVERY validation band. Entries whose position
    ///      is already terminal (Exited/Invalidated - tolerated in the set for sign-vs-submit
    ///      races) are skipped by the registry during commit, so they must be skipped here too:
    ///      otherwise a quorum could pad the aggregate/consistency checks with a terminal id's
    ///      caller-supplied value and commit a much lower live total, silently reopening cap
    ///      headroom (validation-vs-commit mismatch). R5: this is the EXACT total the registry
    ///      books (every other admitted id books its supplied value), and _syncAndCommit reverts
    ///      if the registry ever disagrees.
    function _candidateTotal(
        bytes32[] calldata positionIds,
        uint256[] calldata values
    )
        internal
        view
        returns (uint256 s)
    {
        // Ownership of every id was already enforced by _validateReportSet before any total is
        // computed; only the terminal-status skip matters here.
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(_registry());
        uint256 len = positionIds.length;
        for (uint256 i; i < len; ++i) {
            ICrossChainPositionRegistry.PositionStatus status = registry.positions(positionIds[i]).status;
            if (
                status == ICrossChainPositionRegistry.PositionStatus.Exited
                    || status == ICrossChainPositionRegistry.PositionStatus.Invalidated
            ) continue;
            s += values[i];
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
