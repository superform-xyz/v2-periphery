# Cross-Chain SuperVaults Technical Specification

## Overview

Enable a hub-chain SuperVault to route capital to MULTIPLE other chains while maintaining accounting integrity on the hub. The architecture adds new contracts alongside the existing SuperVault system without modifying core contracts.

**CONSTRAINED DESTINATION MODEL (the defining design decision).** On a destination chain, bridged capital may do exactly TWO things and nothing else:

1. **Idle hold** - sit in a hub-controlled escrow (e.g. staged for a redemption bridge-back), or
2. **Deposit into an APPROVED destination SuperVault** - the hub receives that vault's shares.

There is deliberately NO arbitrary strategy execution on the destination chain: no LP, no looping, no carry/basis trade, no bespoke hook chains. Any complex strategy lives INSIDE the destination SuperVault, which already has its own PPS oracle, harnesses, guardian, and accounting. Rationale (Ronny, 2026-08-25): otherwise every single-chain operation needs a bespoke cross-chain harness that tracks back on the hub chain - an unbounded surface - and the hub vault "drifts" into a tangle of un-unwindable multi-leg positions on other chains. Constraining the destination to "hold or deposit-into-a-vault" means a cross-chain position is always a clean, redeemable instrument (idle asset or vault shares), valued by the destination vault's own canonical PPS. Multi-chain is fully supported: the hub may hold positions across many approved `(chainId, superVault)` destinations simultaneously.

## Problem Statement

Currently, SuperVaults can only deploy capital on the same chain where the vault is deployed. This limits a curator to a single chain's SuperVault ecosystem. The goal is to let a hub vault allocate to approved SuperVaults on OTHER chains (and hold idle bridged asset for redemptions), without importing those chains' strategy complexity onto the hub.

**Key challenges:**
1. Accurate accounting of assets deployed across multiple chains
2. Preventing false position registration that could inflate PPS
3. Enforcing position caps to limit cross-chain risk exposure
4. Handling the inherent asynchrony of cross-chain operations
5. Maintaining the existing security model (oracle quorum, hook validation, role hierarchy)

## Proposed Solution

A composable extension to the existing SuperVault system with four new contracts:

1. **CrossChainPositionRegistry** - Tracks cross-chain positions, each typed IDLE (bridged asset held on the destination) or SUPERVAULT (shares of an approved destination vault). Privileged registrar + oracle confirmation.
2. **CrossChainAUMOracle** - Receives per-position value reports for cap enforcement, independent of PPS oracle. For SUPERVAULT positions the reported value is anchored to the destination vault's own canonical PPS (shares x destinationPPS), not a bespoke valuation.
3. **CrossChainPositionCapGuard** - Cap policy (view checks + config) over an allowlist of approved `(chainId, superVault)` destinations (multi-chain).
4. **CapGuardedBridgeHook** - The ONLY authorized cross-chain bridge hook: atomically checks caps + bridges, and constrains the destination action to an approved-vault deposit or idle-hold.

These contracts compose with the existing system:
- SuperVault + SuperVaultStrategy remain untouched
- The DESTINATION-chain deposit reuses the existing SuperExecutor / SuperDestinationExecutor deposit flow into the approved destination SuperVault (no new destination machinery)
- PPS updates use existing `SuperVaultAggregator.forwardPPS()` (hub oracle values cross-chain positions via the destination vault's PPS)
- Async redemptions use existing ERC7540 flow; a hub redemption exceeding the idle buffer bridges back (inheriting the destination vault's async-redeem latency - the idle buffer covers the gap)
- Bridge hooks (Across V3, deBridge) are already implemented and wrapped by CapGuardedBridgeHook

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
    +---------v----------+          +-------------v------+
    | DEST CHAIN A       |          | DEST CHAIN B       |
    | (Arbitrum, etc.)   |          | (Base, etc.)       |
    |                    |          |                    |
    | ONLY one of:       |          | ONLY one of:       |
    |  - idle hold       |          |  - idle hold       |
    |    (hub escrow)    |          |    (hub escrow)    |
    |  - deposit into an |          |  - deposit into an |
    |    APPROVED        |          |    APPROVED        |
    |    SuperVault      |          |    SuperVault      |
    |    (hub holds its  |          |    (hub holds its  |
    |     shares; that   |          |     shares; that   |
    |     vault runs the |          |     vault runs the |
    |     strategy)      |          |     strategy)      |
    +--------------------+          +--------------------+
        (many approved (chainId, superVault) destinations)
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

#### Cross-Chain Deployment (Hub -> Destination vault)
```
1. Manager submits executeHooks() with CapGuardedBridgeHook calldata naming an
   APPROVED (destinationChainId, destinationSuperVault) destination
2. Inside that hook (atomic): CrossChainPositionCapGuard.validateAllocation()
   checks (a) the destination is an approved (chainId, vault) pair and
   (b) the ACTUAL bridge amount against caps - reverts on breach or stale AUM
3. Same hook bridges (Across/deBridge) to the destination, with the destination
   message targeting ONLY the approved SuperVault deposit (or an idle-hold escrow)
4. On the destination: bridged asset is deposited into the approved SuperVault via
   the existing SuperDestinationExecutor deposit flow -> hub-controlled account
   receives that vault's shares (or the asset sits idle in the hub escrow)
5. Off-chain registrar detects the fill; calls registerPosition() (status: Pending)
   with kind = SUPERVAULT (+ destination vault) or IDLE
6. Position appears in the next quorum-signed forwardAUM() report -> Pending -> Active
   (SUPERVAULT value = sharesHeld x destinationVault.PPS; IDLE value = asset held)
7. Active positions are included in AUM and cap calculations
```

#### PPS Computation
```
1. Off-chain oracle aggregates: hub-chain assets + remote position values (idle asset held, or destination-vault shares x that vault's PPS)
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

    /// @dev The ONLY two things bridged capital may become on a destination chain (see the
    ///      Constrained Destination Model). No arbitrary-protocol kind exists by design.
    enum PositionKind {
        Idle,         // Bridged asset held in the hub-controlled destination escrow
        SuperVault    // Deposited into an approved destination SuperVault; hub holds its shares
    }

    struct CrossChainPosition {
        uint64 chainId;              // Destination chain
        PositionKind kind;           // Idle or SuperVault (no arbitrary protocol)
        address destinationVault;    // Approved destination SuperVault (address(0) for Idle)
        uint256 deployedAmount;      // Asset amount bridged (hub asset decimals)
        uint256 sharesHeld;          // Destination-vault shares held (0 for Idle)
        uint256 lastReportedValue;   // Last oracle-reported value (SuperVault: shares x destPPS)
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
    ///      to the same destination after Exit/Invalidation yields a DISTINCT id - an in-set id
    ///      can never be overwritten or resurrected, and two concurrent deployments to the same
    ///      destination are tracked separately.
    ///
    ///      CONSTRAINED MODEL: a SuperVault position MUST name an APPROVED (chainId,
    ///      destinationVault) pair - the registrar cannot register a position against an
    ///      unapproved vault (checked via CapGuardedPositionCapGuard's allowlist). An Idle
    ///      position has destinationVault == address(0) and sharesHeld == 0.
    function registerPosition(
        address strategy,
        uint64 chainId,
        PositionKind kind,
        address destinationVault,   // approved SuperVault (SuperVault kind) or address(0) (Idle)
        uint256 deployedAmount,
        uint256 sharesHeld          // destination-vault shares (0 for Idle)
    ) external onlyRegistrar(strategy) returns (bytes32 positionId) {
        // require kind == SuperVault -> capGuard.isApprovedDestination(strategy, chainId, destinationVault)
        //         kind == Idle       -> destinationVault == address(0) && sharesHeld == 0
        positionId = _computePositionId(strategy, chainId, destinationVault, _nextSalt(strategy));
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

    /// @notice Last oracle-reported value of a position (0 if not Active/WindingDown).
    /// @dev Used by the AUM oracle's per-position deviation check (SEC-14).
    function positionValue(bytes32 positionId) external view returns (uint256) {
        CrossChainPosition memory pos = positions[positionId];
        return (pos.status == PositionStatus.Active || pos.status == PositionStatus.WindingDown)
            ? pos.lastReportedValue
            : 0;
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
    ///      to the same destination do not collide and an Exited/Invalidated id can never be reused.
    function _computePositionId(
        address strategy,
        uint64 chainId,
        address destinationVault,   // address(0) for Idle
        uint256 salt
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(strategy, chainId, destinationVault, salt));
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

    /// @dev The quorum signs PER-POSITION values AND the hub-chain assets; the cross-chain
    ///      aggregate is DERIVED on-chain as sum(values). This keeps the registry's per-position
    ///      values and the cached aggregate consistent by construction (one signed payload, one
    ///      write path), gives the cap guard per-chain granularity, and (SEC-7) provides the cap
    ///      DENOMINATOR from the same internally-consistent snapshot rather than a live on-chain
    ///      read that could be flash-manipulated.
    ///
    ///      DENOMINATION (SEC-14): `values[]` and `hubAssets` are ALWAYS hub-asset-denominated
    ///      at hub-asset decimals. Every off-chain decimal/FX conversion from the spoke asset is
    ///      the signers' responsibility and is committed to in the typed data; on-chain code
    ///      never re-derives units, so the quorum owns unit correctness.
    struct AUMReport {
        uint256 totalCrossChainAssets;  // Derived on-chain: sum(values) of last accepted report
        uint256 hubAssets;              // SEC-7: signed hub-chain assets (hub-asset decimals)
        uint256 timestamp;
        uint256 nonce;
    }

    struct AUMOracleConfig {
        uint256 maxStaleness;                 // Max age of AUM data before blocking (0 = unconfigured -> everything blocked)
        uint256 minUpdateInterval;            // Rate limiting
        uint256 deviationThreshold;           // Max relative change of the AGGREGATE per update (1e18 scale)
        uint256 perPositionDeviationThreshold;// SEC-14: max relative change of ANY single position (1e18)
        uint256 consistencyToleranceBps;      // SEC-8: max |PPS*supply - totalAssets| / totalAssets, in bps
        uint256 maxConsecutiveDeviationBreaches; // SEC-13: consecutive soft-fails before the breaker trips
    }

    // --- Storage ---

    ISuperGovernor public immutable SUPER_GOVERNOR;

    // hubAssets is signed (SEC-7); values are hub-asset-denominated (SEC-14)
    bytes32 public constant UPDATE_AUM_TYPEHASH = keccak256(
        "UpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );
    // SEC-13: DISTINCT typehash so a forced-update signature can never be replayed as a normal
    // update (or vice-versa) - the two paths are cryptographically separated
    bytes32 public constant FORCE_UPDATE_AUM_TYPEHASH = keccak256(
        "ForceUpdateAUM(address strategy,bytes32 positionIdsHash,bytes32 valuesHash,uint256 hubAssets,uint256 timestamp,uint256 nonce)"
    );

    // Hard bounds: even ORACLE_MANAGER_ROLE cannot set degenerate config values
    uint256 public constant MIN_MAX_STALENESS = 10 minutes;
    uint256 public constant MAX_MAX_STALENESS = 24 hours;
    uint256 public constant MAX_DEVIATION_THRESHOLD = 0.5e18;         // 50% (aggregate)
    uint256 public constant MAX_POSITION_DEVIATION_THRESHOLD = 0.75e18;// 75% (per-position, SEC-14)
    uint256 public constant MIN_UPDATE_INTERVAL = 1 minutes;         // rate-limiter floor (SEC-15)
    uint256 public constant MAX_CONSISTENCY_TOLERANCE_BPS = 500;      // 5% PPS<->AUM band ceiling (SEC-8)
    uint256 public constant MAX_CONSECUTIVE_BREACHES = 10;            // SEC-13 breaker ceiling

    /// @dev strategy => latest accepted report (aggregate cache)
    mapping(address => AUMReport) public latestReport;

    /// @dev strategy => nonce for replay protection
    mapping(address => uint256) public noncePerStrategy;

    /// @dev strategy => AUM oracle config
    mapping(address => AUMOracleConfig) public configs;

    // --- SEC-13 circuit breaker ---
    /// @dev A genuine move larger than the deviation threshold (e.g. a >50% loss from a
    ///      destination-vault drawdown) soft-fails forwardAUM repeatedly. Rather than silently
    ///      freezing a stale-high AUM, count consecutive breaches; once >= config max, TRIP the
    ///      breaker: isAUMFresh returns false (blocks all deployments, fail-safe) and a loud
    ///      event fires for guardian/redemption-gating. Recovery is forceAUMUpdate (below).
    mapping(address => uint256) public consecutiveBreaches;
    mapping(address => bool) public aumBreakerTripped;

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
        // SEC-14: per-position bound must be set and no looser than the per-position ceiling.
        if (
            config.perPositionDeviationThreshold == 0
                || config.perPositionDeviationThreshold > MAX_POSITION_DEVIATION_THRESHOLD
        ) revert INVALID_CONFIG();
        // SEC-8: consistency band must be set and no looser than the ceiling (0 would disable it).
        if (config.consistencyToleranceBps == 0 || config.consistencyToleranceBps > MAX_CONSISTENCY_TOLERANCE_BPS) {
            revert INVALID_CONFIG();
        }
        // SEC-13: breaker must trip within a bounded number of consecutive breaches.
        if (
            config.maxConsecutiveDeviationBreaches == 0
                || config.maxConsecutiveDeviationBreaches > MAX_CONSECUTIVE_BREACHES
        ) revert INVALID_CONFIG();

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
        uint256 hubAssets,          // SEC-7: signed hub-chain assets, hub-asset decimals
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
            hubAssets,
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
                _recordDeviationBreach(strategy, config);  // SEC-13: count toward the breaker
                return; // Soft fail: no state update, but the nonce IS consumed (step 4)
            }
        } else {
            // SEC-16: zero-crossing (first report / post-full-exit) has no prior aggregate to
            // bound against, so anchor it to actually-bridged capital. bridgedOut at this point
            // reflects the in-flight amount these first positions correspond to (it is
            // decremented only during the sync loop below). A report claiming materially more
            // AUM than was ever bridged out is rejected - the largest single-step lever at
            // bootstrap is capped rather than unbounded.
            uint256 anchor = registry.bridgedOut(strategy);
            if (total > anchor + (anchor * config.deviationThreshold) / 1e18) {
                emit AUMDeviationExceeded(strategy, 0, total);
                _recordDeviationBreach(strategy, config);
                return; // soft fail, nonce consumed
            }
        }

        // 6b. SEC-14: per-position deviation. Catches value-shifting between positions/chains
        //     that leaves the aggregate unchanged (A:0, B:A+B) and so passes the aggregate check
        //     while freeing per-chain cap headroom. A single position moving more than the
        //     per-position bound soft-fails the WHOLE report (keeping aggregate == sum of applied
        //     values); legitimate large single-position swings use the SEC-13 forced-update path.
        for (uint256 i; i < positionIds.length; i++) {
            uint256 prev = registry.positionValue(positionIds[i]); // 0 for a new/Pending position
            if (prev > 0) {
                uint256 d = values[i] > prev ? values[i] - prev : prev - values[i];
                if ((d * 1e18) / prev > config.perPositionDeviationThreshold) {
                    emit PositionDeviationExceeded(strategy, positionIds[i], prev, values[i]);
                    _recordDeviationBreach(strategy, config);
                    return; // soft fail, nonce consumed
                }
            }
        }

        // 6c. SEC-8: PPS<->AUM consistency band. Both feeds come from one off-chain service;
        //     bind them on-chain so a stale/diverging PPS cannot be arbitraged against fresh AUM
        //     (or vice-versa). totalAssets = signed hubAssets + cross-chain aggregate.
        uint256 totalAssets = hubAssets + total;
        {
            // pps: the strategy's stored PPS from the existing SuperVaultAggregator pipeline;
            // supply: the SuperVault share totalSupply. Both are reads of existing state - the
            // exact getters are wired at implementation time (aggregator PPS store + vault).
            uint256 pps = _storedPPS(strategy);
            uint256 supply = _vaultTotalSupply(strategy);
            uint256 impliedAssets = (pps * supply) / 1e18;              // PPS is 1e18-scaled
            if (impliedAssets > 0) {
                uint256 d = totalAssets > impliedAssets ? totalAssets - impliedAssets : impliedAssets - totalAssets;
                if ((d * 10_000) / impliedAssets > config.consistencyToleranceBps) {
                    emit PPSConsistencyBreached(strategy, impliedAssets, totalAssets);
                    _recordDeviationBreach(strategy, config); // counts toward the breaker too
                    return; // soft fail - forces PPS and AUM to be reported together
                }
            }
        }

        // 7. Single write path: sync every position (see syncPositionFromReport rules)
        for (uint256 i; i < positionIds.length; i++) {
            registry.syncPositionFromReport(strategy, positionIds[i], values[i], timestamp);
        }

        // 8. Update cache + clear the SEC-13 breaker (a clean accepted report means the feed is
        //    healthy again)
        _commitReport(strategy, total, hubAssets, timestamp, usedNonce);
    }

    /// @notice SEC-13 RECOVERY: book a move that legitimately exceeds the deviation threshold
    ///         (e.g. a >50% destination-vault drawdown), when the ordinary path can only soft-fail.
    /// @dev DUAL-GATED and NOT a bypass:
    ///      - requires the FULL validator quorum in `proofs` (same signatures as forwardAUM), AND
    ///      - the submitter must additionally hold ORACLE_MANAGER_ROLE (a second, human-in-the-loop
    ///        authorization for an out-of-band move)
    ///      It skips ONLY the aggregate/per-position/zero-crossing deviation checks. It STILL
    ///      enforces the SEC-8 PPS<->AUM consistency band - so a forced update can only book a
    ///      large move that PPS ALREADY reflects (under the constrained model, PPS moved because
    ///      the destination vault's own canonical PPS moved). That band is what makes this safe:
    ///      a compromised quorum cannot set AUM to an arbitrary value inconsistent with PPS.
    ///      On success it clears the circuit breaker. Same completeness/timestamp/nonce rules.
    function forceAUMUpdate(
        address strategy,
        bytes32[] calldata positionIds,
        uint256[] calldata values,
        uint256 hubAssets,
        uint256 timestamp,
        bytes[] calldata proofs
    ) external {
        if (!SUPER_GOVERNOR.hasRole(SUPER_GOVERNOR.ORACLE_MANAGER_ROLE(), msg.sender)) {
            revert UNAUTHORIZED_FORCE_UPDATE();
        }
        // ... IDENTICAL to forwardAUM steps 1-5 (quorum, signatures over a distinct
        //     FORCE_UPDATE_AUM_TYPEHASH, config, timestamp, nonce, completeness), then derive
        //     `total`, SKIP the deviation checks (steps 6/6b and the zero-crossing anchor),
        //     ENFORCE the SEC-8 consistency band (step 6c), sync positions (step 7), and:
        _commitReport(strategy, total, hubAssets, timestamp, usedNonce);
        emit AUMForceUpdated(strategy, total, timestamp);
    }

    /// @notice Check if AUM data is fresh enough for operations
    function isAUMFresh(address strategy) external view returns (bool) {
        AUMReport memory report = latestReport[strategy];
        AUMOracleConfig memory config = configs[strategy];
        if (config.maxStaleness == 0 || report.timestamp == 0) return false; // fail-safe
        if (aumBreakerTripped[strategy]) return false;                       // SEC-13: tripped -> blocked
        return block.timestamp - report.timestamp <= config.maxStaleness;
    }

    /// @notice Total AUM (hub + cross-chain) for cap calculation
    /// @dev SEC-7: hubAssets comes from the SAME quorum-signed, deviation-checked report as the
    ///      cross-chain aggregate - NOT a live on-chain balance read. This makes the cap
    ///      denominator flash-loan-robust (a donation/flash-deposit cannot inflate it mid-tx)
    ///      and keeps numerator and denominator on one internally consistent snapshot. There is
    ///      no `_getHubChainAssets` on-chain reader.
    function getTotalAUM(address strategy) external view returns (uint256) {
        AUMReport memory r = latestReport[strategy];
        return r.hubAssets + r.totalCrossChainAssets;
    }

    // --- SEC-13 breaker internals ---

    /// @dev Count a soft-fail toward the breaker; trip once the configured limit is reached.
    function _recordDeviationBreach(address strategy, AUMOracleConfig memory config) internal {
        uint256 n = ++consecutiveBreaches[strategy];
        if (n >= config.maxConsecutiveDeviationBreaches && !aumBreakerTripped[strategy]) {
            aumBreakerTripped[strategy] = true;
            emit AUMBreakerTripped(strategy, n); // loud signal for guardian / redemption-gating
        }
    }

    /// @dev Commit an accepted report and clear the breaker - the feed is healthy again.
    function _commitReport(address strategy, uint256 total, uint256 hubAssets, uint256 timestamp, uint256 usedNonce)
        internal
    {
        latestReport[strategy] =
            AUMReport({ totalCrossChainAssets: total, hubAssets: hubAssets, timestamp: timestamp, nonce: usedNonce });
        consecutiveBreaches[strategy] = 0;
        if (aumBreakerTripped[strategy]) {
            aumBreakerTripped[strategy] = false;
            emit AUMBreakerReset(strategy);
        }
        emit AUMUpdated(strategy, total, timestamp);
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
- **Signed hub assets (SEC-7)**: `hubAssets` is part of the quorum-signed report, so
  `getTotalAUM`'s denominator comes from the same deviation-checked snapshot as the numerator -
  no live on-chain balance read to flash-manipulate, and numerator/denominator stay consistent
- **Per-position deviation (SEC-14)** alongside the aggregate one: catches value-shifting
  between positions/chains that leaves the sum unchanged; `values[]`/`hubAssets` are normatively
  hub-asset-denominated (units are the quorum's responsibility, committed in the typed data)
- **Anchored valuation (constrained model)**: for a SuperVault position the signed value is
  `sharesHeld x destinationVault.PPS`, where the destination PPS is itself a canonical,
  independently-attested value from that vault's own PPS pipeline - the quorum attests a share
  balance against a public price, not a bespoke position valuation. This makes each reported
  value reconstructable/auditable off-chain and materially shrinks the SEC-8/SEC-14 trust
  surface versus valuing arbitrary DeFi positions
- **PPS<->AUM consistency band (SEC-8)**: `forwardAUM` binds `hubAssets + aggregate` to
  `PPS x totalSupply` within `consistencyToleranceBps`, so the two feeds cannot diverge into a
  stale-PPS redemption arbitrage; a breach soft-fails, forcing PPS and AUM to be reported together
- **Zero-crossing anchor (SEC-16)**: first/post-full-exit reports (no prior aggregate) are
  bounded against cumulative `bridgedOut`, capping the single-step lever at bootstrap
- **Circuit breaker + forced-update recovery (SEC-13)**: repeated deviation/consistency
  soft-fails (a genuine >50% move can only soft-fail the ordinary path) trip a per-strategy
  breaker that makes `isAUMFresh` false (blocks deployments, fail-safe) and fires a loud event
  for guardian/redemption-gating. Recovery is `forceAUMUpdate` - dual-gated (validator quorum
  in `proofs` AND an ORACLE_MANAGER submitter, distinct typehash) - which skips ONLY the
  deviation checks but STILL enforces the SEC-8 consistency band, so it can book a large move
  only when PPS already reflects it. Not a bypass: it cannot set AUM inconsistent with PPS.
  This also unblocks SEC-14's legitimate large single-position moves.

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
        // Constrained model: only these (chain, vault) destinations may receive a SuperVault
        // deposit. An unlisted vault is BLOCKED. Idle-hold escrows are configured per chain.
        mapping(uint64 => mapping(address => bool)) approvedDestinationVault;
    }

    // --- Storage ---

    ISuperGovernor public immutable SUPER_GOVERNOR;
    uint256 public constant BPS_PRECISION = 10_000;

    /// @dev strategy => cap configuration
    mapping(address => CapConfig) private _caps;

    /// @dev strategy => chainId => whether an idle-hold escrow is permitted on that chain
    mapping(address => mapping(uint64 => bool)) private _idleHoldEnabled;

    // --- Destination allowlist (constrained model) ---

    /// @notice Approve/revoke a destination SuperVault or an idle-hold escrow for a chain.
    /// @dev Enabling a destination is a LOOSENING action -> GOVERNOR_ROLE + timelock (same
    ///      authority split as setCapConfig, SEC-2). Disabling is allowed for the manager.
    ///      The destination SuperVault SHOULD be a Superform-recognised vault; approving it here
    ///      is what lets the registrar open a SuperVault-kind position and the hook bridge to it.
    function setApprovedDestination(
        address strategy,
        uint64 chainId,
        address destinationVault,   // address(0) toggles the idle-hold escrow for the chain
        bool approved
    ) external {
        if (approved) _requireGovernorTimelocked(strategy);
        else _requireManagerOrGovernor(strategy);
        if (destinationVault == address(0)) _idleHoldEnabled[strategy][chainId] = approved;
        else _caps[strategy].approvedDestinationVault[chainId][destinationVault] = approved;
        emit DestinationApprovalUpdated(strategy, chainId, destinationVault, approved);
    }

    /// @notice Is a destination usable (approved vault, or enabled idle-hold for address(0))?
    function isApprovedDestination(address strategy, uint64 chainId, address destinationVault)
        external
        view
        returns (bool)
    {
        return destinationVault == address(0)
            ? _idleHoldEnabled[strategy][chainId]
            : _caps[strategy].approvedDestinationVault[chainId][destinationVault];
    }

    // --- Core Functions ---

    /// @notice Validate a cross-chain deployment against caps; reverts with a typed error
    ///         on any violation (no bool return - the revert reason is the diagnostic)
    /// @dev Called by CapGuardedBridgeHook atomically before the bridge send; the hook
    ///      propagates the revert, aborting the entire executeHooks() batch
    function validateAllocation(
        address strategy,
        uint64 destinationChainId,
        address destinationVault,   // approved SuperVault, or address(0) for an idle-hold escrow
        uint256 amount
    ) external view {
        // Constrained model: the destination must be an approved (chain, vault) pair (or an
        // approved idle-hold escrow). This is the FIRST gate - an unapproved destination is
        // blocked before any cap arithmetic.
        if (destinationVault == address(0)) {
            if (!_idleHoldEnabled[strategy][destinationChainId]) revert IDLE_HOLD_NOT_ENABLED();
        } else if (!_caps[strategy].approvedDestinationVault[destinationChainId][destinationVault]) {
            revert DESTINATION_VAULT_NOT_APPROVED();
        }

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

    /// @dev hookData layout (CONSTRAINED destination):
    ///      abi.encode(
    ///          uint64  destinationChainId,  // cap-check + leaf dimension
    ///          address destinationVault,    // approved dest SuperVault, or address(0) idle-hold
    ///          uint256 amount,              // used ONLY when usePrevHookAmount == false
    ///          bool    usePrevHookAmount,   // SEC-5: mirror the wrapped bridge hook's flag
    ///          bytes   bridgeMessage        // pre-encoded destination message (see below)
    ///      )
    ///      The `bridgeMessage` may ONLY encode one of two destination actions: a deposit into
    ///      `destinationVault` via the existing SuperDestinationExecutor deposit flow, or a
    ///      transfer to the hub-controlled idle-hold escrow. Arbitrary destination calldata is
    ///      NOT permitted - this is what keeps the hub from importing strategy complexity.
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

        (uint64 chainId, address destinationVault, uint256 staticAmount, bool usePrevHookAmount, bytes memory bridgeMessage) =
            abi.decode(hookData, (uint64, address, uint256, bool, bytes));

        // SEC-5: the amount VALIDATED must be the amount BRIDGED. When usePrevHookAmount is
        // set (swap->bridge chains), the wrapped Across hook reads the real amount from
        // prevHook.getOutAmount(account) at build time - so we resolve the SAME value here and
        // validate that, never a static hookData amount that could diverge from the send.
        uint256 amount = usePrevHookAmount
            ? ISuperHookResult(prevHook).getOutAmount(account)
            : staticAmount;

        // Execution[0]: atomic cap + destination-allowlist check - reverts
        // (DESTINATION_VAULT_NOT_APPROVED / IDLE_HOLD_NOT_ENABLED / AUM_DATA_STALE /
        // CROSS_CHAIN_CAP_EXCEEDED / PER_CHAIN_CAP_EXCEEDED / CHAIN_NOT_ENABLED), aborting the
        // whole executeHooks() batch. capGuard.validateAllocation(strategy, chainId,
        // destinationVault, amount). Also records in-flight exposure via
        // registry.recordBridgedOut(strategy, chainId, amount) (SEC-3).
        // Execution[1]: bridge send whose destination message targets ONLY the approved-vault
        // deposit or the idle-hold escrow (mirrors existing Across/deBridge mechanics;
        // NONACCOUNTING). The hook asserts bridgeMessage encodes one of those two shapes.
        // ...
    }

    /// @notice Merkle leaf contents: pins the destination + amount MODE, keeps the amount dynamic
    /// @dev leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, inspect(hookData)))))
    function inspect(bytes calldata hookData) external view returns (bytes memory) {
        (uint64 chainId, address destinationVault,, bool usePrevHookAmount,) =
            abi.decode(hookData, (uint64, address, uint256, bool, bytes));
        address capGuard = SUPER_GOVERNOR.getAddress(keccak256("CROSS_CHAIN_CAP_GUARD"));
        // destinationVault pinned so each leaf authorizes ONE approved destination; usePrevHook
        // Amount pinned so governance approves the amount SOURCE
        return abi.encodePacked(capGuard, destinationVault, chainId, usePrevHookAmount);
    }
}
```

**Key Design Decisions:**
- Strategy resolved from the `account` build parameter (SEC-17), never from `hookData`
- Cap check is Execution[0]; the strategy's revert-on-failure provides atomicity
- **Constrained destination**: the hook validates the destination is an approved (chain, vault)
  pair (or an enabled idle-hold escrow) and only emits a bridge whose message is an
  approved-vault deposit or an idle-hold transfer - no arbitrary destination calldata
- SEC-5: when `usePrevHookAmount` is set, the validated amount is re-derived from
  `prevHook.getOutAmount()` - the exact amount the bridge will send - closing the
  declared-vs-actual gap for swap->bridge chains
- SEC-3: records in-flight `bridgedOut` on the registry at send time so the cap numerator
  counts bridged-but-unconfirmed capital
- `inspect()` pins (cap guard, destination vault, destination chain, amount-source) per leaf
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
   Execution[0], `validateAllocation(strategy, chainId, destinationVault, amount)` which REVERTS
   with a typed error (`DESTINATION_VAULT_NOT_APPROVED` / `IDLE_HOLD_NOT_ENABLED` /
   `CROSS_CHAIN_CAP_EXCEEDED` / `PER_CHAIN_CAP_EXCEEDED` / `CHAIN_NOT_ENABLED` /
   `AUM_DATA_STALE`), and records in-flight `bridgedOut` (SEC-3)
3. Emits the constrained bridge send (Across V3 / deBridge) whose destination message is an
   approved-vault deposit or an idle-hold transfer - never arbitrary destination calldata

Making the check atomic removes the *ordering* bypass (a manager cannot authorize the guarded
hook and then bridge with a different one that skips the check within the same batch). But it
does NOT by itself make bridging exclusive - see the critical caveat below.

**Merkle leaf contents:** `inspect()` returns (cap guard address, approved destinationVault,
destinationChainId, usePrevHookAmount), so each approved leaf authorizes ONE approved
destination and amount-source. The amount value stays dynamic (outside the leaf).

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
2. Compute `totalAssets = hubChainAssets + sum(idleHeld + destVaultShares x destVaultPPS)`
3. Compute `PPS = totalAssets / totalSupply`
4. Submit via existing `forwardPPS()` (no contract changes)
5. Submit the per-position AUM report via `forwardAUM(positionIds[], values[], hubAssets, ...)`
   (new endpoint; must cover every non-Exited position - completeness rule). CRITICAL (SEC-8):
   `forwardAUM` enforces `|PPS x totalSupply - (hubAssets + sum(values))| <=
   consistencyToleranceBps`, so the AUM report MUST be submitted with (or immediately after) a
   PPS update reflecting the same `totalAssets` - the two feeds can no longer drift apart.
   `hubAssets` and every `values[]` entry are hub-asset-denominated at hub decimals (SEC-14).

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

### F: Arbitrary destination-chain strategy execution
**Rejected (Ronny, 2026-08-25) - this is the Constrained Destination Model.** Letting the hub run arbitrary strategies on destination chains (LP, looping, carry/basis, bespoke hook chains) would require a cross-chain harness for every single-chain operation, each tracking value back on the hub - an unbounded surface - and would let a hub vault "drift" into a tangle of un-unwindable multi-leg positions on other chains, with every position needing a bespoke off-chain valuation the AUM quorum must be trusted for. Instead the ONLY destination actions are (1) idle hold in a hub escrow and (2) deposit into an APPROVED destination SuperVault. Complex strategy lives inside that destination vault (which already has PPS oracle, harnesses, guardian); the hub holds a clean, redeemable instrument valued by the destination vault's own canonical PPS. Multi-chain is retained via the approved `(chainId, superVault)` allowlist.

## Security Findings & Required Mitigations

Source: three parallel adversarial reviews (2026-08-25) verified against the live
`SuperGovernor`, `SuperVaultAggregator`, `SuperVaultStrategy`, and v2-core hooks. The
oracle/quorum layer was found sound (EIP-712 domain separation, per-strategy nonce consumed
on soft-fail, ascending-unique signers, unconfigured-strategy fail-safe). The **cap subsystem
was the break**: it is defended against check *omission* but was not, as first specified,
defended against the manager owning the controls the check reads. Each finding below has been
folded into the design above (SEC-tag comments) or, for SEC-1, closed by a configuration
invariant. **Only SEC-10 remains OPEN** (a governance-authority decision / optional aggregator change).

Status legend: RESOLVED (design updated above) / OPEN (decision or external change needed).

### CRITICAL

- **SEC-1 — "Only bridging leaf" is not on-chain-enforceable. [RESOLVED by configuration]**
  Raw Across/deBridge hooks are globally registered; a main manager authors their own strategy
  root and could place a raw bridge leaf in it, bridging directly and never touching
  CapGuardedBridgeHook. *Chosen resolution:* a **deployment/configuration invariant** - on any
  chain hosting a cross-chain strategy, governance registers ONLY `CapGuardedBridgeHook`, never
  the raw bridge hooks. `executeHooks` checks `isHookRegistered` (global) before the leaf, so a
  raw bridge leaf in a manager root has no registered hook to resolve to and cannot execute.
  See "SEC-1 resolution" below for the runbook/assertion/monitoring requirements and the caveat
  if raw bridging is ever needed on that chain for other products.

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

- **SEC-7 — Cap denominator (`hubAssets`) integrity. [RESOLVED]** `hubAssets` is now a
  quorum-signed field in the AUM report (added to `AUMReport` and `UPDATE_AUM_TYPEHASH`), and
  `getTotalAUM` returns `hubAssets + crossChainAggregate` from that one deviation-checked
  snapshot. There is no on-chain `_getHubChainAssets` reader, so the denominator cannot be
  flash-inflated by a same-tx donation/deposit, and numerator/denominator stay consistent.

- **SEC-8 — PPS<->AUM divergence arbitrage. [RESOLVED]** `forwardAUM` now enforces an on-chain
  consistency band: `|PPS x totalSupply - (hubAssets + aggregate)| / impliedAssets <=
  consistencyToleranceBps` (config-bounded to <=5%). A breach soft-fails the report, so AUM
  cannot be accepted while it disagrees with PPS - the two feeds must move together, closing the
  stale-PPS redemption/deposit arbitrage window.

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
- **SEC-13 — Deviation soft-fail deadlock: a real >50% loss was unbookable, freezing stale-high
  AUM. [RESOLVED]** Two-part fix: (1) a per-strategy **circuit breaker** - `maxConsecutive
  DeviationBreaches` consecutive deviation/consistency soft-fails trip it, making `isAUMFresh`
  false (blocks all deployments, fail-safe) and firing `AUMBreakerTripped` for guardian /
  off-chain redemption-gating; (2) **`forceAUMUpdate`** recovery, dual-gated (full validator
  quorum in `proofs` AND an ORACLE_MANAGER submitter, distinct `FORCE_UPDATE_AUM_TYPEHASH`),
  which skips ONLY the deviation checks but STILL enforces the SEC-8 PPS<->AUM consistency band.
  That band is the backstop: a forced update can book a large move ONLY when PPS already
  reflects it (under the constrained model, PPS moved because the destination vault's canonical
  PPS moved), so it is a recovery path, never an arbitrary-value bypass. A clean accepted report
  (normal or forced) clears the breaker.
- **SEC-14 — `values[]` denomination + per-chain value-shift. [RESOLVED]** The report struct
  and typehash now normatively fix `values[]`/`hubAssets` as hub-asset-denominated at hub
  decimals (units are the quorum's committed responsibility). A `perPositionDeviationThreshold`
  (config-bounded to <=75%) is checked per position in `forwardAUM`; a single position moving
  beyond it soft-fails the whole report, catching value-shifting (A:0, B:A+B) that the
  aggregate check misses. Legit large single-position swings use the SEC-13 forceAUMUpdate path.
- **SEC-15 — `minUpdateInterval` had no lower bound. [RESOLVED]** Added `MIN_UPDATE_INTERVAL`.
- **SEC-16 — Deviation check disarmed at zero-crossings. [RESOLVED]** `forwardAUM` now anchors
  first/post-full-exit reports (no prior aggregate) against cumulative `bridgedOut` - a report
  claiming materially more AUM than was ever bridged out is rejected, capping the bootstrap lever.
- **SEC-17 — Phase-4 hook pseudocode used the wrong execution model. [RESOLVED]** Corrected to
  `build(prevHook, account, data)` returning `Execution[]`, strategy from `account`, cap check
  as Execution[0]. (Also documents why `build()` being `view` forces the SEC-3 accumulator
  through a registry call rather than in-hook state.)

### SEC-1 resolution — CONFIGURATION invariant (not a code change)
SEC-1 is closed operationally, not in these contracts: on any chain hosting a cross-chain
strategy, governance MUST NOT `registerHook` the raw Across/deBridge bridge hooks - only
`CapGuardedBridgeHook` is registered. Because `executeHooks` checks `isHookRegistered` (global)
before validating the leaf, a raw bridge leaf placed in a manager-authored strategy root simply
fails to execute - there is no registered raw bridge hook for it to resolve to. This also
defangs SEC-10's worst case (a malicious strategy root cannot reach a raw bridge). Requirements:
(1) deployment runbook + on-chain assertion that no raw bridge hook is registered on cross-chain
host chains; (2) monitoring alert if one ever is; (3) if raw bridging is needed on that chain
for other products, this invariant does not hold and SEC-1 must instead use cap-aware bridge
hooks or on-chain root screening (aggregator change).

### Open items summary
Remaining OPEN: **SEC-10** only (root-proposal authority - largely mitigated by the SEC-1
configuration invariant above; a governor-gate on cross-chain strategy root proposals is the
robust fix and does NOT need a core change, while a per-strategy hooks-root timelock would).
All other findings (SEC-1..9, 11..17) are resolved in-design or by the SEC-1 configuration
invariant. SEC-13's circuit breaker + `forceAUMUpdate` also unblocks SEC-14's legitimate large
single-position moves.

## Attack Surface Analysis

### Token Compatibility
- [x] Fee-on-transfer: Handled by existing hook accounting (NONACCOUNTING bridge hooks)
- [x] Rebasing: Not applicable (FXRP is not rebasing)
- [x] Missing return values: Existing SafeERC20 usage throughout codebase
- [x] >18 decimals: Handled by existing decimal normalization in PPS computation
- [x] Pausable/blocklist: destinations are a governance-approved (chain, vault) allowlist, not manager discretion over arbitrary protocols

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
- [x] SEC-1 (config): raw bridge hooks are NOT registered on cross-chain host chains, so a raw bridge leaf in a manager root fails isHookRegistered and cannot execute
- [ ] **OPEN SEC-10**: defence-in-depth - gate cross-chain root proposals behind GOVERNOR_ROLE / per-strategy timelock (global 15-min timelock cannot be raised per-strategy)

### DeFi Interaction Risks
- [x] Flash loan: Cap denominator is the signed `hubAssets` field (SEC-7), not a spot balance read - not flash-inflatable
- [x] MEV/sandwich: AUM updates are M-of-N signed, not mempool-visible single-key txs
- [x] In-flight exposure counted toward caps via `bridgedOut` accumulator (SEC-3)
- [x] SEC-8: `forwardAUM` enforces an on-chain PPS<->AUM consistency band, so a stale-PPS redemption cannot be arbitraged against fresh AUM
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
- [ ] Constrained destination model: a position is ONLY Idle (hub escrow) or SuperVault (approved destination vault shares); no arbitrary-protocol positions exist
- [ ] Destination allowlist: SuperVault positions and bridge sends require an approved (chainId, destinationVault) pair; idle-hold requires an enabled escrow; both fail closed
- [ ] `setApprovedDestination` loosening (approve) is governor+timelock; revoke is manager (SEC-2 authority split)
- [ ] SuperVault position value is reported as `sharesHeld x destinationVault.PPS` (anchored to the destination vault's canonical PPS), not a bespoke valuation
- [ ] The bridge hook only emits a destination message that is an approved-vault deposit or an idle-hold transfer (no arbitrary destination calldata)
- [ ] Multi-chain: a strategy may hold positions across many approved (chainId, vault) destinations simultaneously
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
- [ ] SEC-7: cap denominator (`hubAssets`) is a signed field of the AUM report; getTotalAUM uses that snapshot, no on-chain balance read
- [ ] SEC-8: `forwardAUM` enforces the PPS<->AUM consistency band (soft-fail on breach)
- [ ] SEC-14: `values[]`/`hubAssets` hub-asset-denominated (typehash); per-position deviation bound enforced
- [ ] SEC-16: first/zero-crossing reports anchored against cumulative `bridgedOut`
- [ ] **SEC-1 (config invariant)**: deployment asserts + monitors that NO raw bridge hook is `registerHook`ed on any cross-chain host chain; only CapGuardedBridgeHook is
- [ ] **OPEN SEC-10**: cross-chain strategy root proposals gated by GOVERNOR_ROLE or a per-strategy timelock (defence-in-depth; SEC-1 config already blocks the raw-bridge path)
- [ ] SEC-13: repeated deviation/consistency soft-fails trip the circuit breaker (isAUMFresh false + AUMBreakerTripped event); `forceAUMUpdate` (quorum + ORACLE_MANAGER, distinct typehash, still SEC-8-bound) books the move and clears the breaker
- [ ] Cross-chain deposits work via existing SuperExecutor flow (no changes)
- [ ] Withdrawals work via existing ERC7540 async flow (no changes)

### Non-Functional Requirements
- [ ] No modifications to existing SuperVault, SuperVaultStrategy, SuperVaultAggregator - upheld: SEC-1 is closed by a deployment/configuration invariant (don't register raw bridge hooks on cross-chain host chains), no core change needed. Only the OPEN SEC-10 robust fix (per-strategy hooks-root timelock / on-chain root screening) would require an aggregator change; the governor-gate alternative does not
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
- [ ] Adversarial (rogue-manager) tests: pipelined bridges in the async window respect the cap (SEC-3); usePrevHookAmount cannot desync validated vs bridged amount (SEC-5); registrar cannot deflate the numerator by deregistering funded positions (SEC-4/6); phantom-position gas DoS bounded (SEC-9); unlisted destination chain/vault blocked (SEC-11, constrained model)
- [ ] SEC-13 tests: N consecutive deviation soft-fails trip the breaker and isAUMFresh goes false (deployments blocked); `forceAUMUpdate` books a >50% loss ONLY when PPS reflects it (SEC-8 band still enforced) and clears the breaker; a forced update inconsistent with PPS reverts; force/normal signatures are not cross-replayable (distinct typehash)

## Success Metrics
- Cross-chain positions accurately reflected in PPS within oracle update cadence
- Position caps enforced on-chain with zero bypass incidents (GATED on resolving SEC-1/SEC-10 - until then caps do not bind a rogue main manager)
- No false position registration possible without oracle quorum compromise
- No "drift": every cross-chain position is a clean, redeemable instrument (idle asset or approved-vault shares) - never an arbitrary multi-leg position on another chain
- Existing vault operations (deposits, withdrawals, rebalancing) unaffected

## Dependencies & Prerequisites
- Off-chain oracle infrastructure extended to monitor cross-chain positions
- Off-chain registrar service to track bridge events and register positions
- Bridge integrations (Across V3, deBridge) already deployed and operational
- SuperGovernor address registry available for new contract registration
- Approved destination SuperVault(s) exist on each target chain (governance-approved (chainId, vault) allowlist)

## Risk Analysis & Mitigation

| Risk | Category | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| False position registration inflates PPS | Position Registration | Low | Critical | Registration is single-key (registrar) but harmless alone: positions enter AUM only via quorum-signed reports (implicit confirmation) |
| AUM oracle compromise | Oracle | Low | Critical | M-of-N quorum + deviation threshold + staleness checks |
| Cap bypass via flash loan | Flash Loan | Medium | High | SEC-7: denominator is the signed `hubAssets` field, not a spot balance - not flash-inflatable |
| Bridge fill failure | Cross-Chain | Medium | Medium | Pending status, no AUM impact until confirmed |
| Double-counting during position exit | Vault Accounting | Medium | High | SEC-6: deregister requires oracle-confirmed ~0 value + hub reconciliation; MAX_WINDDOWN_DURATION bounds the window |
| Registrar key compromise | Access Control | Low | High | SEC-4/9: appointment governor-gated, exit oracle-confirmed, phantom-position DoS bounded; registrar SHOULD be a multisig |
| Stale position data after liquidation | Oracle | Medium | High | SEC-13: circuit breaker trips on repeated soft-fails (blocks deployments + alerts); `forceAUMUpdate` books the loss, gated by quorum + ORACLE_MANAGER and still bound to PPS via SEC-8 |
| Rogue manager bridges via raw bridge leaf in own strategy root | Access Control | Medium | Critical | SEC-1 (config invariant): raw bridge hooks are NOT registered on cross-chain host chains, so the leaf fails isHookRegistered; deploy-time assertion + monitoring enforce it |
| Rogue manager raises own cap | Access Control | Medium | Critical | SEC-2: cap loosening is governor+timelock, tightening only for manager |
| Cap overshoot via pipelined in-flight bridges | Cross-Chain | Medium | High | SEC-3: `bridgedOut` accumulator counts bridged-but-unconfirmed capital in the numerator |
| usePrevHookAmount desyncs validated vs bridged amount | Access Control | Medium | High | SEC-5: hook re-derives and validates the exact dynamic amount; amount source pinned in leaf |
| PPS/AUM divergence redemption arbitrage | Oracle | Medium | High | SEC-8: `forwardAUM` enforces an on-chain PPS<->AUM consistency band (soft-fail on breach) |
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
0. **SEC-1 chain invariant (once per chain):** assert that NO raw Across/deBridge bridge hook is
   `registerHook`ed on this chain; register ONLY `CapGuardedBridgeHook`. Wire a monitoring alert
   on `HookRegistered` for any raw bridge subtype. This is what makes cap enforcement binding.
1. Deploy the four contracts; register the three registry keys in SuperGovernor
2. Register `CapGuardedBridgeHook` via the standard hook lifecycle (`registerHook`)
3. `setAUMOracleConfig` (ORACLE_MANAGER_ROLE, all fields incl. perPositionDeviationThreshold,
   consistencyToleranceBps, maxConsecutiveDeviationBreaches) -- until set, `isAUMFresh` is false
   and all deployments are blocked
4. `setCapConfig`: initial caps + per-chain allowlist. Loosening later is governor-timelocked
5. Propose + execute the strategy hooks root containing the CapGuardedBridgeHook leaf
   (root lint verifies no raw bridge hook leaves; ideally governor-gated per SEC-10)
6. Set the per-strategy registrar (GOVERNOR/ORACLE_MANAGER-gated, SEC-4) in the registry

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
