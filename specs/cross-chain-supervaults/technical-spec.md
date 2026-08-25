# Cross-Chain SuperVaults Technical Specification

## Overview

Enable SuperVaults to deploy yield across multiple chains while maintaining accounting integrity on a hub chain. The architecture is generic and composable -- it adds new contracts alongside the existing SuperVault system without modifying core contracts. The first implementation targets the FXRP vault on Flare with Stellar yield sources (Bizantine partnership).

## Problem Statement

Currently, SuperVaults can only deploy capital to yield sources on the same chain where the vault is deployed. This limits yield optimization to a single chain's DeFi ecosystem. Cross-chain yield opportunities (basis trades on HyperCore, Stellar lending via Bizantine, multi-chain Aave/Morpho markets) are inaccessible.

**Key challenges:**
1. Accurate accounting of assets deployed across multiple chains
2. Preventing false position registration that could inflate PPS
3. Enforcing position caps to limit cross-chain risk exposure
4. Handling the inherent asynchrony of cross-chain operations
5. Maintaining the existing security model (oracle quorum, hook validation, role hierarchy)

## Proposed Solution

A composable extension to the existing SuperVault system with four new contracts:

1. **CrossChainPositionRegistry** - Tracks cross-chain positions with privileged registrar role and oracle confirmation
2. **CrossChainAUMOracle** - Receives per-position AUM reports for cap enforcement, independent of PPS oracle
3. **CrossChainPositionCapGuard** - Cap policy contract (view checks + cap configuration)
4. **CapGuardedBridgeHook** - The ONLY authorized cross-chain bridge hook: performs the cap check and the bridge send atomically in one hook, so the check cannot be omitted from a hook chain

These contracts compose with the existing system:
- SuperVault + SuperVaultStrategy remain untouched
- Cross-chain deposits use existing SuperExecutor intent flow
- PPS updates use existing `SuperVaultAggregator.forwardPPS()` (oracle just aggregates more data)
- Async redemptions use existing ERC7540 flow
- Bridge hooks (Across V3, deBridge) are already implemented

## Technical Approach

### Architecture

```
                        HUB CHAIN (per-vault, e.g., Flare for FXRP)
    +----------------------------------------------------------+
    |                                                          |
    |  SuperVault (ERC4626 + ERC7540) [UNCHANGED]             |
    |     |                                                    |
    |  SuperVaultStrategy [UNCHANGED]                          |
    |     |                                                    |
    |  CrossChainPositionRegistry [NEW]  <--  CrossChainAUMOracle [NEW]
    |     |         |                              |           |
    |  CrossChainPositionCapGuard [NEW]    ECDSAPPSOracle [UNCHANGED]
    |               |                                          |
    |  SuperVaultAggregator (PPS storage) [UNCHANGED]         |
    |                                                          |
    +---------------------------+------------------------------+
                                |
                    CapGuardedBridgeHook [NEW]
                    (atomic: cap check + bridge send;
                    wraps Across V3 / deBridge [EXISTING])
                                |
              +-----------------+-----------------+
              |                                   |
    +---------v--------+              +-----------v------+
    | SPOKE CHAIN A    |              | SPOKE CHAIN B    |
    | (Arbitrum, etc.) |              | (Base, etc.)     |
    |                  |              |                  |
    | Yield Sources    |              | Yield Sources    |
    +------------------+              +------------------+

              External (Bizantine-managed):
              Stellar yield sources (out of scope for SuperVaults)
```

### Data Flow

#### Cross-Chain Deposit (Spoke -> Hub)
```
1. User signs merkle root intent on source chain
2. Across/deBridge hook sends assets + calldata to hub chain
3. SuperDestinationExecutor validates signature, executes deposit
4. SuperVault.deposit() mints shares to user's smart account on hub
```
*No new contracts needed -- existing SuperExecutor flow handles this.*

#### Cross-Chain Yield Deployment (Hub -> Spoke)
```
1. Manager submits executeHooks() with CapGuardedBridgeHook calldata
2. Inside that hook (atomic): CrossChainPositionCapGuard.validateAllocation()
   checks the ACTUAL bridge amount against caps - reverts if a cap is
   exceeded or AUM data is stale (fail-safe)
3. Same hook performs the bridge send (Across/deBridge) to the destination chain
4. Off-chain registrar detects bridge fill event
5. Registrar calls CrossChainPositionRegistry.registerPosition() (status: Pending)
6. Position appears in the next quorum-signed forwardAUM() report ->
   Pending transitions to Active (confirmation = first signed inclusion)
7. Active positions are included in AUM and cap calculations
```

#### PPS Computation
```
1. Off-chain oracle aggregates: hub-chain assets + remote position values
2. Oracle computes PPS = totalAssets / totalSupply
3. Oracle calls SuperVaultAggregator.forwardPPS() (existing flow)
4. Separately, oracle calls CrossChainAUMOracle.forwardAUM() for cap enforcement
```

#### Withdrawal (Hub -> User)
```
Case A: Buffer sufficient
  1. User calls SuperVault.withdraw() -> immediate (existing flow)

Case B: Buffer insufficient
  1. User calls SuperVault.requestRedeem() -> ERC7540 async request
  2. Manager bridges assets back from remote chains
  3. Manager calls fulfillRedeemRequests() (existing flow)
```

### Implementation Phases

#### Phase 1: CrossChainPositionRegistry

Core position tracking contract.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";

contract CrossChainPositionRegistry {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // --- Types ---

    enum PositionStatus {
        Pending,      // Registered by the registrar, awaiting first quorum-signed report
        Active,       // Included in a signed report, counted in AUM
        WindingDown,  // Being unwound, assets returning to hub (still counted in AUM)
        Exited,       // Fully exited, no longer in AUM
        Invalidated   // Pending position not confirmed within timeout - never entered AUM
    }

    struct CrossChainPosition {
        uint64 chainId;              // Destination chain
        address targetProtocol;      // Protocol on destination (e.g., Aave, Morpho)
        address targetAsset;         // Asset on destination chain
        uint256 deployedAmount;      // Amount deployed (hub asset decimals)
        uint256 lastReportedValue;   // Last oracle-reported value
        uint256 lastReportTimestamp; // When value was last reported
        PositionStatus status;
        uint256 registeredAt;       // Registration timestamp (for timeout)
    }

    // --- Storage ---

    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @dev strategy => set of position IDs
    mapping(address => EnumerableSet.Bytes32Set) private _strategyPositions;

    /// @dev positionId => position data
    mapping(bytes32 => CrossChainPosition) public positions;

    /// @dev strategy => registrar address (role-based). SEC-4: appointment is GOVERNOR/
    ///      ORACLE_MANAGER co-approved, NOT the primary manager alone - the registrar controls
    ///      the cap numerator and the un-quorumed exit path, so it must not be under the sole
    ///      control of the party the caps bound. Registrar SHOULD be a multisig.
    mapping(address => address) public registrars;

    /// @dev strategy => amount bridged out via CapGuardedBridgeHook but not yet reflected in an
    ///      Active position (SEC-3). The hook increments this at send time; syncPositionFrom
    ///      Report decrements it when a Pending position first goes Active (funded), and the
    ///      2h timeout path decrements it on Invalidation. Counted in the cap numerator so
    ///      in-flight capital is never invisible.
    mapping(address => uint256) public bridgedOut;               // strategy => in-flight amount
    mapping(address => mapping(uint64 => uint256)) public bridgedOutByChain;

    /// @dev Maximum time a Pending position can exist before auto-invalidation
    uint256 public constant POSITION_CONFIRMATION_TIMEOUT = 2 hours;

    /// @dev Hard cap on live positions per strategy (SEC-9 DoS): bounds every full-set loop
    ///      (getCrossChainAUM / getChainExposure / forwardAUM completeness). Invalidated and
    ///      Exited positions are EVICTED from the set so it cannot grow unbounded.
    uint256 public constant MAX_POSITIONS_PER_STRATEGY = 64;

    // --- Events ---

    event PositionRegistered(address indexed strategy, bytes32 indexed positionId, uint64 chainId);
    event PositionConfirmed(address indexed strategy, bytes32 indexed positionId);
    event PositionValueUpdated(bytes32 indexed positionId, uint256 newValue, uint256 timestamp);
    event PositionStatusChanged(bytes32 indexed positionId, PositionStatus newStatus);
    event RegistrarUpdated(address indexed strategy, address indexed registrar);

    // --- Core Functions ---

    /// @notice Register a new cross-chain position (registrar only)
    /// @dev Position starts as Pending, confirmed by first funded inclusion in an AUM report.
    ///      SEC-9: reverts if the strategy already holds MAX_POSITIONS_PER_STRATEGY live
    ///      positions. SEC-12: positionId carries a monotonic per-strategy salt so re-deploying
    ///      to the same (chain, protocol, asset) after Exit/Invalidation yields a DISTINCT id -
    ///      an in-set id can never be overwritten or resurrected, and two concurrent deployments
    ///      to the same market are tracked separately.
    function registerPosition(
        address strategy,
        uint64 chainId,
        address targetProtocol,
        address targetAsset,
        uint256 deployedAmount
    ) external onlyRegistrar(strategy) returns (bytes32 positionId) {
        positionId = _computePositionId(strategy, chainId, targetProtocol, targetAsset, _nextSalt(strategy));
        // ... require live-position count < MAX; create position with Pending status
    }

    /// @notice Single oracle write path: sync one position from a quorum-signed AUM report
    /// @dev Called by CrossChainAUMOracle.forwardAUM() for every position in the report.
    ///      - Pending, value > 0, within POSITION_CONFIRMATION_TIMEOUT of registeredAt:
    ///        transition to Active (this IS the confirmation - the quorum vouching for a
    ///        nonzero value implies the position exists on the destination chain)
    ///      - Pending, value == 0: stays Pending (signers attest "not yet verified" -
    ///        confirmation is a positive quorum statement, not an automatic side effect)
    ///      - Pending, past registeredAt + POSITION_CONFIRMATION_TIMEOUT: transition to
    ///        Invalidated, ignore the value (timed-out claims never enter AUM)
    ///      - Active/WindingDown: update lastReportedValue + lastReportTimestamp
    ///      - Exited/Invalidated: SKIP (do NOT revert) - a position that exited between
    ///        off-chain signing and on-chain submission must not brick the whole report
    ///        (SEC-9 report-griefing). On Pending->Active and on Pending->Invalidated,
    ///        decrement bridgedOut[strategy]/bridgedOutByChain (SEC-3) so in-flight capital
    ///        is handed off to (or released from) tracked exposure exactly once.
    function syncPositionFromReport(
        address strategy,
        bytes32 positionId,
        uint256 value,
        uint256 timestamp
    ) external onlyAUMOracle {
        // ... status transition + value/timestamp update + bridgedOut handoff as above
    }

    /// @notice Set the registrar for a strategy
    /// @dev SEC-4: NOT the primary manager alone. Caller must hold GOVERNOR_ROLE (or a
    ///      governor + ORACLE_MANAGER co-approval), since the registrar governs the cap
    ///      numerator and the exit path. Emits RegistrarUpdated.
    function setRegistrar(address strategy, address registrar) external {
        // ... require GOVERNOR_ROLE (co-approval), then set + emit
    }

    /// @notice Mark position as winding down
    function beginPositionExit(
        address strategy,
        bytes32 positionId
    ) external onlyRegistrar(strategy) {
        // ... transition Active -> WindingDown
    }

    /// @notice Deregister fully exited position
    /// @dev SEC-3/SEC-4/SEC-6: exit is NOT a bare registrar transaction. A WindingDown
    ///      position may only be removed once a quorum-signed report has reported its value at
    ///      (approximately) zero AND the returned amount has been reconciled on the hub - i.e.
    ///      deregistration requires oracle confirmation of the drain, not just the registrar's
    ///      say-so. This closes the "registrar deflates the numerator while funds stay remote"
    ///      bypass and the WindingDown double-count window. A position may not remain
    ///      WindingDown past MAX_WINDDOWN_DURATION without being force-reported.
    function deregisterPosition(
        address strategy,
        bytes32 positionId
    ) external onlyRegistrar(strategy) {
        // ... require latest report value ~0 for this position; transition WindingDown ->
        //     Exited, EVICT from _strategyPositions (SEC-9)
    }

    // --- View Functions ---

    /// @notice Confirmed value of all Active and WindingDown cross-chain positions
    function getCrossChainAUM(address strategy) public view returns (uint256 total) {
        bytes32[] memory posIds = _strategyPositions[strategy].values();
        for (uint256 i; i < posIds.length; i++) {
            CrossChainPosition memory pos = positions[posIds[i]];
            if (pos.status == PositionStatus.Active || pos.status == PositionStatus.WindingDown) {
                total += pos.lastReportedValue;
            }
        }
    }

    /// @notice Cap-facing exposure: confirmed positions PLUS in-flight bridged-but-unconfirmed
    ///         capital (SEC-3). This is what validateAllocation must use as the numerator so
    ///         pipelined bridges in the async window cannot each pass against a stale zero.
    function getEffectiveCrossChainExposure(address strategy) external view returns (uint256) {
        return getCrossChainAUM(strategy) + bridgedOut[strategy];
    }

    /// @notice Per-chain equivalent (confirmed chain exposure + in-flight to that chain)
    function getEffectiveChainExposure(address strategy, uint64 chainId) external view returns (uint256) {
        return getChainExposure(strategy, chainId) + bridgedOutByChain[strategy][chainId];
    }

    /// @notice Get all tracked position IDs for a strategy (any status still in the set)
    function getPositionIds(address strategy) external view returns (bytes32[] memory) {
        return _strategyPositions[strategy].values();
    }

    /// @notice Total value of Active/WindingDown positions on one destination chain
    /// @dev Used by CrossChainPositionCapGuard for per-chain cap checks
    function getChainExposure(address strategy, uint64 chainId) public view returns (uint256 total) {
        bytes32[] memory posIds = _strategyPositions[strategy].values();
        for (uint256 i; i < posIds.length; i++) {
            CrossChainPosition memory pos = positions[posIds[i]];
            if (
                pos.chainId == chainId
                    && (pos.status == PositionStatus.Active || pos.status == PositionStatus.WindingDown)
            ) {
                total += pos.lastReportedValue;
            }
        }
    }

    // --- Internal ---

    /// @dev SEC-12: salt makes each deployment's id unique, so distinct concurrent deployments
    ///      to the same market do not collide and an Exited/Invalidated id can never be reused.
    function _computePositionId(
        address strategy,
        uint64 chainId,
        address targetProtocol,
        address targetAsset,
        uint256 salt
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(strategy, chainId, targetProtocol, targetAsset, salt));
    }

    modifier onlyRegistrar(address strategy) {
        if (msg.sender != registrars[strategy]) revert UNAUTHORIZED_REGISTRAR();
        _;
    }

    modifier onlyAUMOracle() {
        address aumOracle = SUPER_GOVERNOR.getAddress(
            keccak256("CROSS_CHAIN_AUM_ORACLE")
        );
        if (msg.sender != aumOracle) revert UNAUTHORIZED_AUM_ORACLE();
        _;
    }
}
```

**Key Design Decisions:**
- `EnumerableSet.Bytes32Set` for O(1) membership checks (matches SuperVaultAggregator pattern)
- Position ID = deterministic hash of strategy + chainId + protocol + asset (no collisions)
- Pending status with 2-hour timeout prevents phantom positions
- Registrar role is per-strategy, changeable; appointment is GOVERNOR/ORACLE_MANAGER-gated, NOT the primary manager alone (SEC-4)
- Oracle confirmation required before position counts toward AUM; confirmation is implicit -
  a Pending position becomes Active on its FIRST inclusion in a quorum-signed AUM report
  (no separate confirm transaction)
- The AUM oracle is the ONLY writer of position values (`syncPositionFromReport`,
  `onlyAUMOracle`), so the registry's per-position values and the oracle's aggregate share a
  single write path and cannot diverge

#### Phase 2: CrossChainAUMOracle

Independent AUM feed for cap enforcement and PPS computation input.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";

contract CrossChainAUMOracle is EIP712 {

    // --- Types ---

    /// @dev The quorum signs PER-POSITION values; the aggregate is DERIVED on-chain as their
    ///      sum. This keeps the registry's per-position values and the cached aggregate
    ///      consistent by construction (one signed payload, one write path) and gives the cap
    ///      guard the per-chain granularity its checks require.
    struct AUMReport {
        uint256 totalCrossChainAssets;  // Derived on-chain: sum(values) of last accepted report
        uint256 timestamp;
        uint256 nonce;
    }

    struct AUMOracleConfig {
        uint256 maxStaleness;        // Max age of AUM data before blocking (0 = unconfigured -> everything blocked)
        uint256 minUpdateInterval;   // Rate limiting
        uint256 deviationThreshold;  // Max relative change of the AGGREGATE per update (1e18 scale)
    }

    // --- Storage ---

    ISuperGovernor public immutable SUPER_GOVERNOR;

    bytes32 public constant UPDATE_AUM_TYPEHASH = keccak256(
        "UpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 timestamp,uint256 nonce)"
    );

    // Hard bounds: even ORACLE_MANAGER_ROLE cannot set degenerate config values
    uint256 public constant MIN_MAX_STALENESS = 10 minutes;
    uint256 public constant MAX_MAX_STALENESS = 24 hours;
    uint256 public constant MAX_DEVIATION_THRESHOLD = 0.5e18; // 50%
    uint256 public constant MIN_UPDATE_INTERVAL = 1 minutes;  // rate-limiter floor (SEC-15)

    /// @dev strategy => latest accepted report (aggregate cache)
    mapping(address => AUMReport) public latestReport;

    /// @dev strategy => nonce for replay protection
    mapping(address => uint256) public noncePerStrategy;

    /// @dev strategy => AUM oracle config
    mapping(address => AUMOracleConfig) public configs;

    // --- Configuration ---

    /// @notice Set per-strategy oracle integrity parameters
    /// @dev ORACLE_MANAGER_ROLE only (mirrors SuperOracle staleness administration:
    ///      setOracleMaxStaleness / setOracleFeedMaxStalenessBatch). Deliberately NOT the
    ///      strategy manager: maxStaleness is the fail-safe that blocks the manager's
    ///      cross-chain deployments when AUM data is stale, and the party being bounded by a
    ///      control must not be able to loosen it.
    function setAUMOracleConfig(address strategy, AUMOracleConfig calldata config) external {
        if (!SUPER_GOVERNOR.hasRole(SUPER_GOVERNOR.ORACLE_MANAGER_ROLE(), msg.sender)) {
            revert UNAUTHORIZED_CONFIG();
        }
        if (config.maxStaleness < MIN_MAX_STALENESS || config.maxStaleness > MAX_MAX_STALENESS) {
            revert INVALID_CONFIG();
        }
        if (config.deviationThreshold == 0 || config.deviationThreshold > MAX_DEVIATION_THRESHOLD) {
            revert INVALID_CONFIG(); // bounded to (0, 50%] - no disable value
        }
        // Lower bound on the rate limiter (SEC-15): without it a compromised ORACLE_MANAGER
        // could set minUpdateInterval = 0 and let a colluding quorum walk the aggregate in
        // unlimited back-to-back <=50% steps within one block window.
        if (config.minUpdateInterval < MIN_UPDATE_INTERVAL || config.minUpdateInterval >= config.maxStaleness) {
            revert INVALID_CONFIG();
        }

        configs[strategy] = config;
        emit AUMOracleConfigUpdated(strategy, config.maxStaleness, config.minUpdateInterval, config.deviationThreshold);
    }

    // --- Core Functions ---

    /// @notice Submit a quorum-signed PER-POSITION AUM report
    /// @dev Follows ECDSAPPSOracle validation pattern. The report must be COMPLETE: it must
    ///      cover every Active/WindingDown position plus every non-expired Pending position
    ///      REGISTERED BEFORE the report timestamp, so (a) the off-chain service cannot
    ///      silently drop a losing position to dodge the deviation check, and (b) a
    ///      registration landing between off-chain signing and on-chain submission cannot
    ///      invalidate an in-flight report (registrar DoS). Signers attest value 0 for
    ///      Pending positions they have not yet verified (position stays Pending).
    function forwardAUM(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 timestamp,
        bytes[] calldata proofs
    ) external {
        if (positionIds.length != values.length) revert LENGTH_MISMATCH();

        // 1. Validate quorum (reuse SUPER_GOVERNOR.getPPSOracleQuorum())
        uint256 requiredQuorum = SUPER_GOVERNOR.getPPSOracleQuorum();
        if (proofs.length < requiredQuorum) revert QUORUM_NOT_MET();

        // 2. Verify EIP-712 signatures (ascending unique signers) over the FULL report
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            UPDATE_AUM_TYPEHASH,
            strategy,
            keccak256(abi.encodePacked(positionIds)),
            keccak256(abi.encodePacked(values)),
            timestamp,
            noncePerStrategy[strategy]
        )));

        address lastSigner;
        for (uint256 i; i < proofs.length; i++) {
            address signer = ECDSA.recover(digest, proofs[i]);
            if (!SUPER_GOVERNOR.isValidator(signer)) revert INVALID_VALIDATOR();
            if (signer <= lastSigner) revert INVALID_PROOF();
            lastSigner = signer;
        }

        // 3. Validate config + timestamp (monotonicity, staleness, rate limit)
        AUMReport memory current = latestReport[strategy];
        AUMOracleConfig memory config = configs[strategy];

        if (config.maxStaleness == 0) revert UNCONFIGURED_STRATEGY(); // fail-safe: no reports before onboarding
        if (timestamp > block.timestamp) revert FUTURE_TIMESTAMP();
        if (timestamp <= current.timestamp) revert STALE_UPDATE();
        if (timestamp - current.timestamp < config.minUpdateInterval) revert RATE_LIMITED();
        if (block.timestamp - timestamp > config.maxStaleness) revert DATA_TOO_STALE();

        // 4. Consume the nonce for ANY quorum-valid submission - including deviation
        //    soft-fails below - so a rejected signed payload can never be replayed later
        uint256 usedNonce = noncePerStrategy[strategy]++;

        // 5. Completeness check: every Active/WindingDown position, plus every non-expired
        //    Pending position registered before `timestamp`, must be covered by the report
        ICrossChainPositionRegistry registry = ICrossChainPositionRegistry(
            SUPER_GOVERNOR.getAddress(keccak256("CROSS_CHAIN_POSITION_REGISTRY"))
        );
        if (!_coversAllOpenPositions(registry, strategy, positionIds, timestamp)) revert INCOMPLETE_REPORT();

        // 6. Derive the aggregate on-chain and apply the deviation check to it
        //    (deviationThreshold is bounded to (0, 50%] by the setter - no disable sentinel)
        uint256 total;
        for (uint256 i; i < values.length; i++) {
            total += values[i];
        }
        if (current.totalCrossChainAssets > 0) {
            uint256 absDiff = total > current.totalCrossChainAssets
                ? total - current.totalCrossChainAssets
                : current.totalCrossChainAssets - total;
            uint256 deviation = (absDiff * 1e18) / current.totalCrossChainAssets;
            if (deviation > config.deviationThreshold) {
                emit AUMDeviationExceeded(strategy, current.totalCrossChainAssets, total);
                return; // Soft fail: no state update, but the nonce IS consumed (step 4)
            }
        }

        // 7. Single write path: sync every position (see syncPositionFromReport rules)
        for (uint256 i; i < positionIds.length; i++) {
            registry.syncPositionFromReport(strategy, positionIds[i], values[i], timestamp);
        }

        // 8. Update aggregate cache
        latestReport[strategy] = AUMReport({
            totalCrossChainAssets: total,
            timestamp: timestamp,
            nonce: usedNonce
        });

        emit AUMUpdated(strategy, total, timestamp);
    }

    /// @notice Check if AUM data is fresh enough for operations
    function isAUMFresh(address strategy) external view returns (bool) {
        AUMReport memory report = latestReport[strategy];
        AUMOracleConfig memory config = configs[strategy];
        return block.timestamp - report.timestamp <= config.maxStaleness;
    }

    /// @notice Get total AUM (hub + cross-chain) for cap calculation
    function getTotalAUM(address strategy) external view returns (uint256) {
        // Hub chain assets queried on-chain + cross-chain from oracle
        uint256 hubAssets = _getHubChainAssets(strategy);
        return hubAssets + latestReport[strategy].totalCrossChainAssets;
    }
}
```

**Key Design Decisions:**
- Same ECDSA quorum core as ECDSAPPSOracle (validator set, `getPPSOracleQuorum`,
  `_hashTypedDataV4`, ascending-unique signers, per-strategy nonce). Two deliberate
  deviations, which off-chain signer infra MUST account for: (a) ECDSAPPSOracle builds its
  struct hash with non-standard `abi.encodePacked`; this contract uses standard `abi.encode`
  per EIP-712 - signatures are NOT byte-compatible between the two; (b) in the PPS path the
  timestamp/staleness/rate-limit/deviation checks live in `SuperVaultAggregator.forwardPPS`,
  not the oracle - here they are folded into `forwardAUM` itself (there is no aggregator in
  this path). Nonce consumption on soft-reject matches the PPS system (nonce advances even
  when the update is rejected)
- Separate from PPS to avoid circular dependency (AUM doesn't depend on PPS)
- **Per-position signed reports, aggregate derived on-chain**: the quorum signs
  `(positionIds[], values[])`, never a bare total. This gives the registry its per-position
  values, the cap guard its per-chain exposure, and makes the cached aggregate equal to the
  registry sum by construction - no second source of truth
- **Completeness rule**: a report must cover every non-Exited position (registry
  cross-check), so a losing position cannot be silently omitted to evade the deviation check
- **Config is ORACLE_MANAGER_ROLE-gated with hard bounds** - not the strategy manager, whose
  deployments these parameters exist to block; bounds constants cap the damage of a
  compromised oracle-manager key (mirrors BasefeeGasOracle's MIN/MAX_MULTIPLIER_BPS pattern)
- **Unconfigured strategy = fail-safe**: zero `maxStaleness` makes `isAUMFresh` return false,
  blocking all cross-chain deployments until onboarding is complete. Onboarding order:
  register contracts -> `setAUMOracleConfig` -> `setCapConfig` -> approve CapGuardedBridgeHook leaf
- All PPS-path validation properties replicated: timestamp checks, monotonicity, rate limiting, deviation threshold
- Soft-fail on deviation (emit + return, nonce still consumed) to prevent oracle DoS without enabling replay
- AUM freshness check usable by other contracts (consumed by the cap guard)
- `_getHubChainAssets` (used by `getTotalAUM`) must be pinned down at implementation time: it
  must read the strategy's on-chain asset accounting in a flash-loan-robust way (oracle/PPS
  derived, not raw spot balances), or the cap denominator becomes manipulable

#### Phase 3: CrossChainPositionCapGuard

Cap policy contract (view checks + cap configuration), invoked atomically by
CapGuardedBridgeHook (Phase 4) — never wired into `executeHooks()` directly.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";

contract CrossChainPositionCapGuard {

    // --- Types ---

    struct CapConfig {
        uint256 maxCrossChainBps;                // Global max % of AUM cross-chain (e.g., 7000 = 70%)
        mapping(uint64 => uint256) perChainCap;  // Max amount per chain (only meaningful if chainEnabled)
        mapping(uint64 => bool) chainEnabled;    // Allowlist: unlisted chain is BLOCKED, not unlimited (SEC-11)
    }

    // --- Storage ---

    ISuperGovernor public immutable SUPER_GOVERNOR;
    uint256 public constant BPS_PRECISION = 10_000;

    /// @dev strategy => cap configuration
    mapping(address => CapConfig) private _caps;

    // --- Core Functions ---

    /// @notice Validate a cross-chain deployment against caps; reverts with a typed error
    ///         on any violation (no bool return - the revert reason is the diagnostic)
    /// @dev Called by CapGuardedBridgeHook atomically before the bridge send; the hook
    ///      propagates the revert, aborting the entire executeHooks() batch
    function validateAllocation(
        address strategy,
        uint64 destinationChainId,
        uint256 amount
    ) external view {
        // Get AUM oracle
        address aumOracleAddr = SUPER_GOVERNOR.getAddress(
            keccak256("CROSS_CHAIN_AUM_ORACLE")
        );
        ICrossChainAUMOracle aumOracle = ICrossChainAUMOracle(aumOracleAddr);

        // Require fresh AUM data (also false for unconfigured strategies - fail-safe)
        if (!aumOracle.isAUMFresh(strategy)) revert AUM_DATA_STALE();

        uint256 totalAUM = aumOracle.getTotalAUM(strategy);
        if (totalAUM == 0) revert ZERO_TOTAL_AUM();

        // Current cross-chain allocation. NOTE (SEC-3): this MUST include in-flight and
        // Pending exposure (the bridgedOut accumulator), not just Active/WindingDown - see the
        // Security Findings section. `getEffectiveCrossChainExposure` returns
        // getCrossChainAUM + unconfirmed bridgedOut so pipelined bridges in the async window
        // cannot each validate against a stale zero numerator.
        address registryAddr = SUPER_GOVERNOR.getAddress(
            keccak256("CROSS_CHAIN_POSITION_REGISTRY")
        );
        uint256 currentCrossChain = ICrossChainPositionRegistry(registryAddr)
            .getEffectiveCrossChainExposure(strategy);

        // Global cap check
        CapConfig storage caps = _caps[strategy];
        uint256 newCrossChain = currentCrossChain + amount;
        if (newCrossChain * BPS_PRECISION > totalAUM * caps.maxCrossChainBps) {
            revert CROSS_CHAIN_CAP_EXCEEDED();
        }

        // Per-chain cap check - FAIL CLOSED (SEC-11): a chain with no configured cap is
        // BLOCKED, not unlimited. Governance must explicitly allowlist each destination.
        if (!caps.chainEnabled[destinationChainId]) revert CHAIN_NOT_ENABLED();
        uint256 perChainMax = caps.perChainCap[destinationChainId];
        uint256 chainExposure = ICrossChainPositionRegistry(registryAddr)
            .getEffectiveChainExposure(strategy, destinationChainId);
        if (chainExposure + amount > perChainMax) revert PER_CHAIN_CAP_EXCEEDED();
    }

    /// @notice Set cap configuration
    /// @dev Split authority (SEC-2): TIGHTENING (lower maxCrossChainBps, lower/disable a
    ///      per-chain cap) is allowed for the primary manager immediately - a manager may
    ///      always de-risk. LOOSENING (raise maxCrossChainBps, raise a cap, enable a new
    ///      chain) is GOVERNOR_ROLE-only and subject to a timelock + guardian veto, because a
    ///      manager must not be able to raise their own risk ceiling (same reasoning as
    ///      setAUMOracleConfig). Enforced by comparing against current values per key.
    function setCapConfig(
        address strategy,
        uint256 maxCrossChainBps,
        uint64[] calldata chainIds,
        uint256[] calldata chainCaps,
        bool[] calldata chainEnabled
    ) external {
        if (chainIds.length != chainCaps.length || chainIds.length != chainEnabled.length) {
            revert LENGTH_MISMATCH();
        }
        if (maxCrossChainBps > BPS_PRECISION) revert INVALID_CAP();

        bool loosening = maxCrossChainBps > _caps[strategy].maxCrossChainBps;
        for (uint256 i; i < chainIds.length; i++) {
            if (chainEnabled[i] && !_caps[strategy].chainEnabled[chainIds[i]]) loosening = true;
            if (chainCaps[i] > _caps[strategy].perChainCap[chainIds[i]]) loosening = true;
        }
        // Tightening: primary manager or governor. Loosening: governor (timelocked) only.
        if (loosening) _requireGovernorTimelocked(strategy);
        else _requireManagerOrGovernor(strategy);

        _caps[strategy].maxCrossChainBps = maxCrossChainBps;
        for (uint256 i; i < chainIds.length; i++) {
            _caps[strategy].perChainCap[chainIds[i]] = chainCaps[i];
            _caps[strategy].chainEnabled[chainIds[i]] = chainEnabled[i];
        }
        emit CapConfigUpdated(strategy, maxCrossChainBps);
    }
}
```

**Key Design Decisions:**
- Pure validation contract (view functions for cap checks); the enforcing caller is
  `CapGuardedBridgeHook`, which reverts the whole `executeHooks()` batch on a false return
- Uses AUM oracle data (not on-chain balances) to prevent flash loan manipulation
- Requires fresh AUM data -- stale data blocks all cross-chain deployments (fail-safe)
- Per-chain caps provide granular risk control (`registry.getChainExposure`)
- Numerator (registry position sums) and denominator (oracle aggregate + hub assets) derive
  from the SAME per-position report via the single `syncPositionFromReport` write path, so
  the cap ratio cannot drift between two sources of truth
- Cap LIMITS (`setCapConfig`) are the strategy manager's risk dials (manager-or-governor);
  oracle INTEGRITY parameters (`setAUMOracleConfig`) are deliberately not (ORACLE_MANAGER_ROLE)

#### Phase 4: CapGuardedBridgeHook

The enforcement adapter: the only leaf that can move funds cross-chain, containing the cap
check and the bridge send in one atomic execution (rationale in Integration Point 2).

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";

contract CapGuardedBridgeHook /* is BaseHook, ISuperHookInspector */ {

    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @dev hookData layout:
    ///      abi.encode(
    ///          uint64  destinationChainId,  // cap-check + leaf dimension
    ///          address bridgeTarget,        // underlying Across V3 / deBridge target
    ///          uint256 amount,              // used ONLY when usePrevHookAmount == false
    ///          bool    usePrevHookAmount,   // SEC-5: mirror the wrapped bridge hook's flag
    ///          bytes   bridgeCalldata       // pre-encoded call for bridgeTarget
    ///      )
    ///
    /// @dev EXECUTION MODEL (SEC-17): real hooks do NOT run in the strategy's frame. The
    ///      strategy calls `build(prevHook, account, data)` (a view) to get an Execution[]
    ///      that the STRATEGY then .calls. So: strategy == the `account` build param (NOT
    ///      msg.sender), and the cap check must be the FIRST returned Execution so the
    ///      strategy's revert-on-failure gives atomicity. Shown flattened for readability.
    function build(address prevHook, address account, bytes calldata hookData)
        external
        view
        returns (Execution[] memory executions)
    {
        address strategy = account; // SEC-17: from build param, never msg.sender

        (uint64 chainId, address bridgeTarget, uint256 staticAmount, bool usePrevHookAmount, bytes memory bridgeCalldata) =
            abi.decode(hookData, (uint64, address, uint256, bool, bytes));

        // SEC-5: the amount VALIDATED must be the amount BRIDGED. When usePrevHookAmount is
        // set (swap->bridge chains), the wrapped Across hook reads the real amount from
        // prevHook.getOutAmount(account) at build time - so we resolve the SAME value here and
        // validate that, never a static hookData amount that could diverge from the send.
        uint256 amount = usePrevHookAmount
            ? ISuperHookResult(prevHook).getOutAmount(account)
            : staticAmount;

        // Execution[0]: atomic cap check - reverts (AUM_DATA_STALE / CROSS_CHAIN_CAP_EXCEEDED /
        // PER_CHAIN_CAP_EXCEEDED / CHAIN_NOT_ENABLED), aborting the whole executeHooks() batch.
        // Also records in-flight exposure: registry.recordBridgedOut(strategy, chainId, amount)
        // (SEC-3) so pipelined bridges in the async window are counted immediately. recordBridged
        // Out is CROSS_CHAIN_CAP_GUARD/hook-gated on the registry side.
        // Execution[1]: approve `amount` to bridgeTarget and execute the bridge send
        // (mirrors existing Across/deBridge mechanics; NONACCOUNTING).
        // ...
    }

    /// @notice Merkle leaf contents: pins the route + amount MODE, keeps the amount dynamic
    /// @dev leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, inspect(hookData)))))
    function inspect(bytes calldata hookData) external view returns (bytes memory) {
        (uint64 chainId, address bridgeTarget,, bool usePrevHookAmount,) =
            abi.decode(hookData, (uint64, address, uint256, bool, bytes));
        address capGuard = SUPER_GOVERNOR.getAddress(keccak256("CROSS_CHAIN_CAP_GUARD"));
        // usePrevHookAmount is pinned in the leaf so governance approves the amount SOURCE
        return abi.encodePacked(capGuard, bridgeTarget, chainId, usePrevHookAmount);
    }
}
```

**Key Design Decisions:**
- Strategy resolved from the `account` build parameter (SEC-17), never from `hookData`
- Cap check is Execution[0]; the strategy's revert-on-failure provides atomicity
- SEC-5: when `usePrevHookAmount` is set, the validated amount is re-derived from
  `prevHook.getOutAmount()` - the exact amount the bridge will send - closing the
  declared-vs-actual gap for swap->bridge chains
- SEC-3: records in-flight `bridgedOut` on the registry at send time so the cap numerator
  counts bridged-but-unconfirmed capital
- `inspect()` pins (cap guard, bridge target, destination chain, amount-source) per leaf
- NONACCOUNTING like the raw bridge hooks it wraps - no position auto-registration
  (Alternative D remains rejected)
- Registered via the standard hook lifecycle (`registerHook` + hooks-root proposal)

### Integration Points

#### 1. SuperGovernor Address Registry
No SuperGovernor changes needed (it is a deployed, non-upgradeable contract):
`setAddress(bytes32 key, address value)` (SUPER_GOVERNOR_ROLE) accepts arbitrary keys and
`getAddress(bytes32)` resolves them. Register the three keys operationally:
```solidity
superGovernor.setAddress(keccak256("CROSS_CHAIN_POSITION_REGISTRY"), registry);
superGovernor.setAddress(keccak256("CROSS_CHAIN_AUM_ORACLE"), aumOracle);
superGovernor.setAddress(keccak256("CROSS_CHAIN_CAP_GUARD"), capGuard);
```
Implementation note: `ISuperGovernor` exposes `ORACLE_MANAGER_ROLE()`, `getAddress`,
`isValidator`, `getPPSOracleQuorum` but NOT `hasRole` - role checks in the new contracts
must cast to OZ `IAccessControl` (or add `hasRole` to the interface).

#### 2. executeHooks() Cap Check Integration: CapGuardedBridgeHook (atomic)

**Why not a standalone pre-bridge check hook:** the Merkle hook validation layer
(`SuperVaultAggregator.validateHooks`, `src/SuperVault/SuperVaultAggregator.sol:1151`)
authorizes each hook INDEPENDENTLY against the roots - it validates a set of leaves, never a
sequence. "Hook A must appear before hook B" is not expressible, so a manager could submit
`executeHooks()` containing only the (individually authorized) raw bridge hook and skip the
cap check entirely. A separate guard hook is enforceable only by convention.

**Design: one hook that checks and bridges atomically.** `CapGuardedBridgeHook` (via its
`build()` returning an `Execution[]` the strategy runs in order):

1. Resolves `strategy` from the `account` build parameter (SEC-17), never from `hookData`, so
   a manager cannot validate against another strategy's caps; decodes the bridge parameters
2. Resolves the amount that will ACTUALLY be bridged - re-deriving it from
   `prevHook.getOutAmount()` when `usePrevHookAmount` is set (SEC-5) - and emits, as
   Execution[0], `CrossChainPositionCapGuard.validateAllocation(strategy, chainId, amount)`
   which REVERTS with a typed error (`CROSS_CHAIN_CAP_EXCEEDED` / `PER_CHAIN_CAP_EXCEEDED` /
   `CHAIN_NOT_ENABLED` / `AUM_DATA_STALE`), and records in-flight `bridgedOut` (SEC-3)
3. Emits the underlying bridge send (Across V3 / deBridge) as the following Execution(s)

Making the check atomic removes the *ordering* bypass (a manager cannot authorize the guarded
hook and then bridge with a different one that skips the check within the same batch). But it
does NOT by itself make bridging exclusive - see the critical caveat below.

**Merkle leaf contents:** `inspect()` returns (cap guard address, underlying bridge target,
destinationChainId, usePrevHookAmount), making each approved leaf route-, chain-, and
amount-source-specific. The amount value stays dynamic (outside the leaf).

**CRITICAL CAVEAT - "only bridging leaf" is NOT on-chain-enforceable (SEC-1).** Hook
registration (`SuperGovernor.registerHook`, GOVERNOR_ROLE) is a single GLOBAL set, and
`SuperVaultStrategy.executeHooks` accepts any hook that is globally registered AND present in
EITHER the global root OR the strategy's own manager-authored root (`validateHooks`,
`SuperVaultAggregator.sol:1151`). The raw Across/deBridge hooks are already globally
registered for existing single-chain flows. So a malicious/compromised main manager simply
proposes a strategy root containing a leaf for the RAW bridge hook and bridges directly,
never touching CapGuardedBridgeHook or the cap guard. Off-chain root-lint + monitoring cannot
stop an on-chain manager-authored root. The atomic hook adds a *safe* way to bridge; it does
not remove the *unsafe* ones. This is the headline residual risk - see Security Findings
SEC-1 for the three candidate mitigations (deploy-time exclusion of raw bridge hooks on
cross-chain host chains / cap-aware raw bridge hooks / on-chain root screening).

**Guardian veto reality (verified against `SuperVaultAggregator`).** The strategy root is
proposed by the main manager behind `_hooksRootUpdateTimelock`, a SINGLE GLOBAL variable that
**defaults to 15 minutes** and is settable only by SuperGovernor globally. So the earlier
suggestion to "raise the timelock for cross-chain strategies" is NOT implementable - the
timelock is global, and raising it slows legitimate hook updates for EVERY strategy. There is
no per-proposal rejection: `setStrategyHooksRootVetoStatus` is a whole-strategy kill switch
that fails ALL hook validation (halting every operation), does not cancel the pending root,
and the bad root re-arms when the veto lifts. Realistic mitigations (SEC-10): gate
cross-chain-enabled strategies' root proposals behind GOVERNOR_ROLE, or add a per-strategy
timelock / per-proposal cancel (both require an aggregator change). The root-lint + monitoring
(superman/superbank-roots pipeline rejecting raw bridge leaves; alerting on
`StrategyHooksRootProposed`) remains a necessary defence-in-depth layer but is NOT sufficient
alone.

#### 3. PPS Oracle Extension
The off-chain PPS oracle aggregation service extends to:
1. Query position values across all chains where the vault has positions
2. Compute `totalAssets = hubChainAssets + sum(crossChainPositionValues)`
3. Compute `PPS = totalAssets / totalSupply`
4. Submit via existing `forwardPPS()` (no contract changes)
5. Separately submit the per-position AUM report via `forwardAUM(positionIds[], values[], ...)`
   (new endpoint; must cover every non-Exited position - see completeness rule)

#### 4. Cross-Chain Deposits
No changes needed. Existing flow:
1. User signs intent on source chain
2. Bridge hook sends assets to hub chain
3. SuperDestinationExecutor validates and executes deposit
4. Shares minted on hub chain

#### 5. Withdrawals
No changes needed. Existing flow:
- Immediate: `SuperVault.withdraw()` if buffer sufficient
- Async: `SuperVault.requestRedeem()` -> manager bridges back -> `fulfillRedeemRequests()`

## Alternative Approaches Considered

### A: OFT Share Token
**Rejected.** Making shares an OFT adds cross-chain total supply tracking, cross-chain redemption routing, and bridging latency for no clear benefit. Shares living on the hub chain is simpler and sufficient.

### B: DepositRouter on Spoke Chains
**Rejected.** New DepositRouter contracts are unnecessary since the existing SuperExecutor intent flow already handles cross-chain deposits.

### C: Satellite Vault Pattern (per-chain vault instances)
**Rejected.** Independent vault instances per chain create fragmented liquidity and complex cross-chain accounting. Single hub-chain vault with position tracking is cleaner.

### D: Hook-Based Auto-Registration
**Rejected.** Allowing bridge hooks to automatically register positions creates a critical attack vector -- anyone who can invoke a hook could register false positions. Role-based off-chain registration with oracle confirmation is safer.

### E: On-Chain Balance Queries for AUM
**Rejected.** Synchronous cross-chain balance queries are not possible. Oracle-based push model is the only viable approach for multi-chain AUM.

## Security Findings & Required Mitigations

Source: three parallel adversarial reviews (2026-08-25) verified against the live
`SuperGovernor`, `SuperVaultAggregator`, `SuperVaultStrategy`, and v2-core hooks. The
oracle/quorum layer was found sound (EIP-712 domain separation, per-strategy nonce consumed
on soft-fail, ascending-unique signers, unconfigured-strategy fail-safe). The **cap subsystem
was the break**: it is defended against check *omission* but was not, as first specified,
defended against the manager owning the controls the check reads. Each finding below has been
folded into the design above (SEC-tag comments) except where marked OPEN — those require a
threat-model decision or an aggregator change and are called out explicitly.

Status legend: RESOLVED (design updated above) / OPEN (decision or external change needed).

### CRITICAL

- **SEC-1 — "Only bridging leaf" is not on-chain-enforceable. [OPEN — decision required]**
  Raw Across/deBridge hooks are globally registered; a main manager authors their own strategy
  root and can place a raw bridge leaf in it, bridging directly and never touching
  CapGuardedBridgeHook. `validateHooks` accepts a hook in the global OR strategy root, so
  off-chain root-lint cannot stop it. Fully bypasses caps → 100% of a capped vault cross-chain.
  *Candidate mitigations (pick one, all have trade-offs):* (a) do NOT globally register raw
  bridge hooks on any chain hosting a cross-chain strategy (loses raw bridging there);
  (b) make the raw bridge hooks themselves cap-aware; (c) add on-chain strategy-root screening
  for bridge-subtype hooks (requires an aggregator change, which the "no core changes"
  constraint forbids). Until one is chosen, the cap system is advisory against a rogue manager.

- **SEC-2 — Manager sets their own cap value. [RESOLVED]** `setCapConfig` was manager-settable,
  immediate, up to 100%. Now split: tightening is manager-allowed; loosening (raise BPS, raise
  a per-chain cap, enable a chain) is GOVERNOR_ROLE + timelock + veto. Same reasoning the spec
  already applied to `setAUMOracleConfig`.

- **SEC-3 — In-flight / Pending capital excluded from the cap numerator → geometric bypass.
  [RESOLVED]** `getCrossChainAUM` counted only Active/WindingDown, so pipelined bridges in the
  multi-minute-to-hours confirmation window each validated against a stale-low numerator (70%
  cap → ~97-100% deployed). Fixed with an on-chain `bridgedOut` accumulator incremented by the
  hook at send time and counted via `getEffectiveCrossChainExposure`; handed off to the
  position (or released) exactly once on Active/Invalidated. NOTE: `build()` is `view`, so the
  hook records `bridgedOut` through a gated registry call in its Execution set, not directly.

- **SEC-4 — Manager-appointed registrar controls the numerator and an un-quorumed exit path.
  [RESOLVED, needs role wiring]** The registrar (formerly manager-appointed) could omit
  registrations (numerator stays 0) or unilaterally `deregisterPosition` funded positions to
  reset headroom. Now: `setRegistrar` is GOVERNOR/ORACLE_MANAGER-gated (not manager-alone), and
  `deregisterPosition` requires oracle confirmation the position reported ~0 (see SEC-6).

### HIGH

- **SEC-5 — `usePrevHookAmount` reintroduced the declared-vs-actual amount gap. [RESOLVED]**
  The wrapped Across hook can read the real bridged amount from `prevHook.getOutAmount()` at
  build time (needed for swap→bridge). The hook now re-derives and validates that exact dynamic
  amount, and pins `usePrevHookAmount` in the leaf so governance approves the amount source.

- **SEC-6 — Unbounded/un-reconciled exit → double-count + numerator deflation. [RESOLVED]**
  `deregisterPosition` now requires a quorum-reported ~0 value and hub-side reconciliation; a
  position may not sit WindingDown past `MAX_WINDDOWN_DURATION` without a forced report. Closes
  the "funds home but still counted / funds remote but deregistered" windows.

- **SEC-7 — `_getHubChainAssets` (cap denominator) unspecified. [OPEN — must define]** Must NOT
  read spot balances or one-block-manipulable exchange rates (flash-inflatable denominator).
  Recommended: include a quorum-signed `hubAssets` field in the same AUM report (one internally
  consistent snapshot), or derive as `lastPPS × totalSupply − crossChainAggregate` (note the
  PPS-lag coupling with SEC-8).

- **SEC-8 — PPS and AUM are two unreconciled feeds → redemption arbitrage. [OPEN — must add
  check]** On a large remote P&L event the public `AUMUpdated`/`AUMDeviationExceeded` events
  signal exactly when PPS is stale, enabling front-run redeem/deposit at the mispriced PPS.
  Recommended: enforce `|PPS·totalSupply − getTotalAUM| ≤ tolerance` on-chain at `forwardPPS`
  time for cross-chain strategies, and/or a shared report timestamp across both submissions.

- **SEC-9 — Registrar-driven unbounded set → gas DoS + report-griefing. [RESOLVED]**
  `MAX_POSITIONS_PER_STRATEGY` cap, eviction of Invalidated/Exited from the set, and
  `syncPositionFromReport` SKIPPING (not reverting on) positions that exited between signing and
  submission.

- **SEC-10 — Guardian veto inadequate; hooks-root timelock is global, not per-strategy. [OPEN —
  aggregator change or governor-gate]** The earlier "raise the timelock" advice is
  unimplementable (global 15-min default). Realistic: gate cross-chain strategy root proposals
  behind GOVERNOR_ROLE, or add a per-strategy timelock / per-proposal cancel (aggregator
  change). Related to SEC-1.

### MEDIUM / LOW

- **SEC-11 — Per-chain cap failed open (unconfigured chain = unlimited). [RESOLVED]** Added a
  `chainEnabled` allowlist; an unlisted destination is BLOCKED (`CHAIN_NOT_ENABLED`).
- **SEC-12 — Deterministic positionId collisions / unsafe reuse. [RESOLVED]** positionId now
  carries a monotonic per-strategy salt; in-set ids cannot be overwritten or resurrected.
- **SEC-13 — Deviation soft-fail deadlock: a real >50% loss is unbookable, freezing stale-high
  AUM (and, via a single-position FXRP strategy, always applicable). [OPEN — must add path]**
  Recommended: on repeated deviation breaches trip a circuit breaker (pause / block redemptions)
  instead of silently returning, plus an ORACLE_MANAGER-gated, still-quorum-signed forced-update
  path so catastrophic losses can be booked promptly.
- **SEC-14 — `values[]` denomination/decimals undefined; per-chain value-shift passes under the
  aggregate-only deviation check. [OPEN — must specify]** State normatively that `values[]` are
  hub-asset-denominated at hub decimals (in the typed-data signers commit to), and add a
  per-position deviation bound alongside the aggregate one.
- **SEC-15 — `minUpdateInterval` had no lower bound. [RESOLVED]** Added `MIN_UPDATE_INTERVAL`.
- **SEC-16 — Deviation check disarmed whenever the last aggregate is 0 (bootstrap / post-full-
  exit). [OPEN — bound it]** Anchor first/zero-crossing reports against an independent bound
  (e.g. cumulative `bridgedOut`), so a compromised quorum's largest single-step lever is capped.
- **SEC-17 — Phase-4 hook pseudocode used the wrong execution model. [RESOLVED]** Corrected to
  `build(prevHook, account, data)` returning `Execution[]`, strategy from `account`, cap check
  as Execution[0]. (Also documents why `build()` being `view` forces the SEC-3 accumulator
  through a registry call rather than in-hook state.)

### Open items summary (require a decision before build)
SEC-1 (raw-bridge exclusivity), SEC-7 (hub-assets source), SEC-8 (PPS↔AUM consistency check),
SEC-10 (root-proposal authority / per-strategy timelock), SEC-13 (loss-booking circuit
breaker), SEC-14 (`values[]` denomination), SEC-16 (zero-crossing anchor). SEC-1 and SEC-10
are the load-bearing ones: without one of their mitigations, a rogue main manager can still
move ~100% of a capped vault cross-chain, and the atomic-hook guarantee is limited to
preventing *ordering* bypass only.

## Attack Surface Analysis

### Token Compatibility
- [x] Fee-on-transfer: Handled by existing hook accounting (NONACCOUNTING bridge hooks)
- [x] Rebasing: Not applicable (FXRP is not rebasing)
- [x] Missing return values: Existing SafeERC20 usage throughout codebase
- [x] >18 decimals: Handled by existing decimal normalization in PPS computation
- [x] Pausable/blocklist: Manager discretion on yield source selection

### Reentrancy
- [x] CEI pattern: New contracts are primarily view functions + access-controlled state updates
- [x] Read-only reentrancy: Position values are oracle-reported, not computed from balances
- [x] Cross-contract reentrancy: Bridge hooks are NONACCOUNTING, position registry updates are separate transactions
- [x] ERC callback reentrancy: No token callbacks in new contracts

### Oracle & Price
- [x] Oracle manipulation: Multi-oracle quorum (M-of-N ECDSA) for both PPS and AUM
- [x] Stale price handling: maxStaleness check on AUM data, blocks deployments if stale
- [x] Multi-oracle fallback: Quorum ensures no single oracle can manipulate data
- [x] Flash-loan resistant: Cap enforcement uses oracle-reported AUM, not on-chain balances

### Access Control & Upgrades
- [x] Config gating: `setAUMOracleConfig` (ORACLE_MANAGER_ROLE + hard bounds); `setCapConfig` split - tighten=manager, loosen=governor+timelock (SEC-2)
- [x] Registrar appointment: GOVERNOR/ORACLE_MANAGER-gated, not manager-alone (SEC-4)
- [x] Position confirmation: Pending -> Active via first quorum-signed inclusion, with 2-hour invalidation timeout for unconfirmed claims
- [ ] **OPEN SEC-1/SEC-10**: raw bridge hooks are globally registered and a manager authors their own strategy root, so "only bridging leaf" is not on-chain-enforceable and the guardian window is a global 15-min timelock - see Security Findings

### DeFi Interaction Risks
- [x] Flash loan: Cap denominator uses oracle AUM, not spot balances - CONTINGENT on `_getHubChainAssets` (SEC-7, OPEN) being oracle/PPS-derived
- [x] MEV/sandwich: AUM updates are M-of-N signed, not mempool-visible single-key txs
- [x] In-flight exposure counted toward caps via `bridgedOut` accumulator (SEC-3)
- [ ] **OPEN SEC-8**: PPS and AUM are two feeds from one service - add on-chain consistency band to prevent stale-PPS redemption arbitrage
- [x] First depositor: Existing SuperVault mitigations apply (oracle-driven PPS, not balance-derived)

### Exploit Precedent Check

| Similar Protocol | Exploit | Loss | Relevance | Our Mitigation |
|---|---|---|---|---|
| Wormhole | Forged guardian signatures | $320M | AUM oracle signature validation | M-of-N ECDSA quorum with validator registry |
| Ronin | Compromised 5/9 validator keys | $625M | Registrar key compromise | Single-key registration is harmless alone: positions enter AUM only via quorum-signed reports; registrar SHOULD be a multisig |
| Euler | Donation attack (balance manipulation) | $197M | AUM inflation via balance manipulation | Oracle-driven AUM, not on-chain balance queries |
| Multichain | Centralized key management | $130M+ | Single registrar EOA | Registrar SHOULD be a multisig; AUM entry requires validator quorum regardless |

## Acceptance Criteria

### Functional Requirements
- [ ] CrossChainPositionRegistry tracks positions with full lifecycle (Pending -> Active -> WindingDown -> Exited)
- [ ] Registrar can register/deregister positions (per-strategy); appointment is GOVERNOR/ORACLE_MANAGER-gated, not manager-alone (SEC-4)
- [ ] `deregisterPosition` requires oracle-confirmed ~0 value + hub reconciliation, not a bare registrar tx (SEC-6)
- [ ] positionId carries a per-strategy salt; in-set ids cannot be overwritten/resurrected (SEC-12)
- [ ] Live positions per strategy bounded by MAX_POSITIONS_PER_STRATEGY; Invalidated/Exited evicted from the set (SEC-9)
- [ ] Positions are confirmed (Pending -> Active) by first inclusion in a quorum-signed AUM report
- [ ] Unconfirmed positions auto-invalidate after timeout (2 hours)
- [ ] CrossChainAUMOracle receives quorum-signed PER-POSITION reports; the aggregate is derived on-chain as their sum
- [ ] Reports are complete: a submission missing any Active/WindingDown position, or any non-expired Pending position registered before the report timestamp, reverts (INCOMPLETE_REPORT)
- [ ] Pending -> Active requires a NONZERO reported value; signers attest 0 for unverified positions (stays Pending); expired Pending positions transition to Invalidated
- [ ] AUM oracle validates: timestamp monotonicity, staleness, rate limiting, deviation threshold (on the aggregate)
- [ ] `setAUMOracleConfig` is ORACLE_MANAGER_ROLE-gated with hard bounds on all parameters
- [ ] Unconfigured strategies (zero maxStaleness) block all cross-chain deployments (fail-safe default)
- [ ] Global cap numerator includes in-flight/Pending exposure via `bridgedOut` (getEffectiveCrossChainExposure), not just Active/WindingDown (SEC-3)
- [ ] Per-chain cap fails CLOSED: unlisted destination chain is blocked, not unlimited (SEC-11)
- [ ] `setCapConfig` loosening is governor+timelock; tightening is manager (SEC-2)
- [ ] Stale AUM data blocks new cross-chain deployments (fail-safe)
- [ ] All new contracts registered in SuperGovernor address registry
- [ ] Cap enforcement is atomic in CapGuardedBridgeHook (validate + bridge in one hook); validated amount == bridged amount even under usePrevHookAmount (SEC-5)
- [ ] **OPEN SEC-1**: choose and implement raw-bridge-exclusivity mitigation (deploy-time exclusion / cap-aware bridge hooks / on-chain root screening) - off-chain lint alone is insufficient
- [ ] **OPEN SEC-10**: cross-chain strategy root proposals gated by GOVERNOR_ROLE or a per-strategy timelock (global timelock cannot be raised per-strategy)
- [ ] **OPEN SEC-7**: `_getHubChainAssets` defined against a flash-loan-robust source (signed hubAssets field or PPS-derived)
- [ ] **OPEN SEC-8**: on-chain PPS<->AUM consistency band for cross-chain strategies
- [ ] **OPEN SEC-13**: circuit breaker + governance-gated forced-update path so a real >50% loss can be booked
- [ ] **OPEN SEC-14**: `values[]` normatively hub-asset-denominated at hub decimals + per-position deviation bound
- [ ] **OPEN SEC-16**: zero-crossing/first report anchored against an independent bound
- [ ] Cross-chain deposits work via existing SuperExecutor flow (no changes)
- [ ] Withdrawals work via existing ERC7540 async flow (no changes)

### Non-Functional Requirements
- [ ] No modifications to existing SuperVault, SuperVaultStrategy, SuperVaultAggregator - NOTE: the strongest SEC-1/SEC-10 mitigations (on-chain root screening, per-strategy hooks-root timelock) would require an aggregator change; if the no-core-changes constraint is kept, SEC-1 must be handled by deploy-time exclusion of raw bridge hooks + governor-gated root proposals instead
- [ ] Gas-efficient: packed storage, EnumerableSet for O(1) lookups
- [ ] AUM deviation check soft-fails (emit + return, nonce consumed); cap enforcement in CapGuardedBridgeHook hard-reverts by design (the revert IS the enforcement)

### Security Requirements
- [ ] Multi-oracle quorum for AUM updates (not single-key)
- [ ] Position registration requires registrar role + quorum-signed NONZERO value attestation before entering AUM (two-layer validation; confirmation is a positive quorum statement, not automatic)
- [ ] Cap enforcement uses oracle-reported AUM (flash-loan resistant)
- [ ] Deviation threshold auto-flags suspicious AUM changes
- [ ] Bridge hooks remain NONACCOUNTING (no position auto-registration)

### Testing Requirements
- [ ] Unit tests for each new contract in isolation
- [ ] Fork tests with simulated cross-chain messaging
- [ ] Invariant tests: positions <= AUM, cap always respected, PPS * supply ~= AUM
- [ ] Fuzz tests for cap boundary conditions
- [ ] Scenario tests: stale AUM blocks cross-chain deployments, liquidation reflects in PPS, bridge timeout handling, Pending timeout invalidation, report-vs-registration race
- [ ] Adversarial (rogue-manager) tests: pipelined bridges in the async window respect the cap (SEC-3); usePrevHookAmount cannot desync validated vs bridged amount (SEC-5); registrar cannot deflate the numerator by deregistering funded positions (SEC-4/6); phantom-position gas DoS bounded (SEC-9); unlisted destination chain blocked (SEC-11); >50% loss booking path (SEC-13)

## Success Metrics
- Cross-chain positions accurately reflected in PPS within oracle update cadence
- Position caps enforced on-chain with zero bypass incidents (GATED on resolving SEC-1/SEC-10 - until then caps do not bind a rogue main manager)
- No false position registration possible without oracle quorum compromise
- Existing vault operations (deposits, withdrawals, rebalancing) unaffected

## Dependencies & Prerequisites
- Off-chain oracle infrastructure extended to monitor cross-chain positions
- Off-chain registrar service to track bridge events and register positions
- Bridge integrations (Across V3, deBridge) already deployed and operational
- SuperGovernor address registry available for new contract registration
- For FXRP vault: Bizantine confirms yield sources on Stellar

## Risk Analysis & Mitigation

| Risk | Category | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| False position registration inflates PPS | Position Registration | Low | Critical | Registration is single-key (registrar) but harmless alone: positions enter AUM only via quorum-signed reports (implicit confirmation) |
| AUM oracle compromise | Oracle | Low | Critical | M-of-N quorum + deviation threshold + staleness checks |
| Cap bypass via flash loan | Flash Loan | Medium | High | Oracle-reported AUM (not on-chain balances) for cap denominator - CONTINGENT on SEC-7 (`_getHubChainAssets`) |
| Bridge fill failure | Cross-Chain | Medium | Medium | Pending status, no AUM impact until confirmed |
| Double-counting during position exit | Vault Accounting | Medium | High | SEC-6: deregister requires oracle-confirmed ~0 value + hub reconciliation; MAX_WINDDOWN_DURATION bounds the window |
| Registrar key compromise | Access Control | Low | High | SEC-4/9: appointment governor-gated, exit oracle-confirmed, phantom-position DoS bounded; registrar SHOULD be a multisig |
| Stale position data after liquidation | Oracle | Medium | High | SEC-13 (OPEN): deviation soft-fail currently BLOCKS booking a >50% loss - needs circuit breaker + forced-update path |
| **Rogue manager bridges via raw bridge leaf in own strategy root** | Access Control | **Medium** | **Critical** | **SEC-1 (OPEN)**: atomic hook prevents ordering bypass only; raw bridge hooks are globally registered and reachable via a manager-authored strategy root - off-chain lint insufficient, needs deploy-time exclusion / cap-aware bridge hooks / on-chain root screening |
| Rogue manager raises own cap | Access Control | Medium | Critical | SEC-2: cap loosening is governor+timelock, tightening only for manager |
| Cap overshoot via pipelined in-flight bridges | Cross-Chain | Medium | High | SEC-3: `bridgedOut` accumulator counts bridged-but-unconfirmed capital in the numerator |
| usePrevHookAmount desyncs validated vs bridged amount | Access Control | Medium | High | SEC-5: hook re-derives and validates the exact dynamic amount; amount source pinned in leaf |
| PPS/AUM divergence redemption arbitrage | Oracle | Medium | High | SEC-8 (OPEN): add on-chain PPS<->AUM consistency band |
| Guardian veto too slow / global timelock | Access Control | Medium | High | SEC-10 (OPEN): governor-gate cross-chain root proposals or per-strategy timelock |
| Oracle omits losing positions from report | Oracle | Medium | High | Completeness check: report must cover every open position or revert |
| Manager loosens AUM staleness/deviation config | Access Control | Low | High | Config is ORACLE_MANAGER_ROLE-gated (not manager) with hard min/max bounds incl. minUpdateInterval floor (SEC-15) |

## Implementation

### New Files

```
src/
  CrossChain/
    CrossChainPositionRegistry.sol     # Position tracking
    CrossChainAUMOracle.sol            # Per-position AUM reports with quorum
    CrossChainPositionCapGuard.sol     # Cap policy (views + config)
    CapGuardedBridgeHook.sol           # Atomic cap check + bridge send (the only bridging leaf)
  interfaces/
    CrossChain/
      ICrossChainPositionRegistry.sol
      ICrossChainAUMOracle.sol
      ICrossChainPositionCapGuard.sol
test/
  unit/
    CrossChainPositionRegistry.t.sol
    CrossChainAUMOracle.t.sol
    CrossChainPositionCapGuard.t.sol
    CapGuardedBridgeHook.t.sol
  fork/
    CrossChainIntegration.t.sol
  recon/
    targets/
      CrossChainTargets.sol            # Invariant test targets
script/
  DeployCrossChain.s.sol
```

### Existing Files Modified
- **None.** SuperGovernor is deployed and non-upgradeable; the three registry keys are set
  operationally via `setAddress()` (SUPER_GOVERNOR_ROLE) - see Integration Point 1.

### Deployment / Onboarding Order (per strategy)
1. Deploy the four contracts; register the three registry keys in SuperGovernor
2. Register `CapGuardedBridgeHook` via the standard hook lifecycle (`registerHook`)
3. `setAUMOracleConfig` (ORACLE_MANAGER_ROLE) -- until this is set, `isAUMFresh` is false and
   all cross-chain deployments are blocked (fail-safe default)
4. `setCapConfig` (primary manager or governor)
5. Propose + execute the strategy hooks root containing the CapGuardedBridgeHook leaf
   (root lint verifies no raw bridge hook leaves)
6. Set the per-strategy registrar in CrossChainPositionRegistry

## Future Considerations

1. **ZK-proof reserve verification** (Ethena/Chaos Labs model) for trustless cross-chain balance verification
2. **Threshold signature schemes (BLS)** to reduce on-chain quorum verification from O(M) to O(1)
3. **Optimistic oracle with dispute period** (UMA-inspired) for less time-sensitive AUM data
4. **Per-protocol caps** in addition to per-chain caps
5. **Automated rebalancing** based on yield differentials across chains
6. **Non-EVM position tracking** for Stellar positions (currently handled externally by Bizantine)

## References & Research

### Internal References
- SuperVaultAggregator PPS oracle: `src/SuperVault/SuperVaultAggregator.sol:239-307`
- Hook validation system: `src/SuperVault/SuperVaultAggregator.sol:1127-1192`
- ECDSAPPSOracle quorum: `src/oracles/ECDSAPPSOracle.sol`
- Access control hierarchy: `src/SuperGovernor.sol:94-99`
- Bridge hooks: `lib/v2-core/src/hooks/bridges/across/AcrossSendFundsAndExecuteOnDstHook.sol`
- SuperDestinationExecutor: `lib/v2-core/src/executors/SuperDestinationExecutor.sol:94-144`
- Composable contract pattern: `src/SuperVault/SuperVaultExecutor.sol:19-73`

### External References
- [Yearn V3 Tech Spec](https://github.com/yearn/yearn-vaults-v3/blob/master/TECH_SPEC.md)
- [LayerZero OVault Standard](https://docs.layerzero.network/v2/concepts/applications/ovault-standard)
- [ERC-7540 Async Vaults](https://eips.ethereum.org/EIPS/eip-7540)
- [Chainlink Proof of Reserve](https://chain.link/proof-of-reserve)
- [Wormhole Hack Analysis](https://immunebytes.com/blog/wormhole-bridge-hack-feb-2-2022-detailed-hack-analysis/)
- [Ronin Network Exploit](https://www.merklescience.com/blog/hack-track-analysis-of-ronin-network-exploit)
- [ERC-4626 Exchange Rate Manipulation](https://www.euler.finance/blog/exchange-rate-manipulation-in-erc4626-vaults)

### Research Files
- [Repository Analysis](./research/repo-analysis.md)
- [Best Practices](./research/best-practices.md)
- [EVM Security](./research/evm-security.md)
