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

A composable extension to the existing SuperVault system with three new contracts:

1. **CrossChainPositionRegistry** - Tracks cross-chain positions with privileged registrar role and oracle confirmation
2. **CrossChainAUMOracle** - Receives AUM feed for PPS computation and cap enforcement, independent of PPS oracle
3. **CrossChainPositionCapGuard** - Hook validation layer that checks cross-chain allocation caps during `executeHooks()`

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
                    Bridge Hooks (Across V3 / deBridge)
                    [EXISTING - UNCHANGED]
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
1. Manager submits executeHooks() with bridge hook calldata
2. CrossChainPositionCapGuard validates allocation within caps
3. Bridge hook (Across/deBridge) sends assets to destination chain
4. Off-chain registrar detects bridge fill event
5. Registrar calls CrossChainPositionRegistry.registerPosition()
6. CrossChainAUMOracle confirms position with quorum-signed update
7. Position enters Active status, included in AUM calculations
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
        Pending,      // Registered by manager, awaiting oracle confirmation
        Active,       // Confirmed by oracle, included in AUM
        WindingDown,  // Being unwound, assets returning to hub
        Exited        // Fully exited, no longer in AUM
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

    /// @dev strategy => registrar address (role-based, set by primary manager)
    mapping(address => address) public registrars;

    /// @dev Maximum time a Pending position can exist before auto-invalidation
    uint256 public constant POSITION_CONFIRMATION_TIMEOUT = 2 hours;

    // --- Events ---

    event PositionRegistered(address indexed strategy, bytes32 indexed positionId, uint64 chainId);
    event PositionConfirmed(address indexed strategy, bytes32 indexed positionId);
    event PositionValueUpdated(bytes32 indexed positionId, uint256 newValue, uint256 timestamp);
    event PositionStatusChanged(bytes32 indexed positionId, PositionStatus newStatus);
    event RegistrarUpdated(address indexed strategy, address indexed registrar);

    // --- Core Functions ---

    /// @notice Register a new cross-chain position (registrar only)
    /// @dev Position starts as Pending, must be confirmed by AUM oracle
    function registerPosition(
        address strategy,
        uint64 chainId,
        address targetProtocol,
        address targetAsset,
        uint256 deployedAmount
    ) external onlyRegistrar(strategy) returns (bytes32 positionId) {
        positionId = _computePositionId(strategy, chainId, targetProtocol, targetAsset);
        // ... create position with Pending status
    }

    /// @notice Oracle confirms position exists on destination chain
    function confirmPosition(
        address strategy,
        bytes32 positionId
    ) external onlyAUMOracle {
        // ... transition Pending -> Active
    }

    /// @notice Oracle updates position value
    function updatePositionValue(
        address strategy,
        bytes32 positionId,
        uint256 newValue,
        uint256 timestamp
    ) external onlyAUMOracle {
        // ... update lastReportedValue, lastReportTimestamp
    }

    /// @notice Mark position as winding down
    function beginPositionExit(
        address strategy,
        bytes32 positionId
    ) external onlyRegistrar(strategy) {
        // ... transition Active -> WindingDown
    }

    /// @notice Deregister fully exited position
    function deregisterPosition(
        address strategy,
        bytes32 positionId
    ) external onlyRegistrar(strategy) {
        // ... transition WindingDown -> Exited, remove from set
    }

    // --- View Functions ---

    /// @notice Total value of all Active cross-chain positions for a strategy
    function getCrossChainAUM(address strategy) external view returns (uint256 total) {
        bytes32[] memory posIds = _strategyPositions[strategy].values();
        for (uint256 i; i < posIds.length; i++) {
            CrossChainPosition memory pos = positions[posIds[i]];
            if (pos.status == PositionStatus.Active || pos.status == PositionStatus.WindingDown) {
                total += pos.lastReportedValue;
            }
        }
    }

    /// @notice Get all active position IDs for a strategy
    function getPositionIds(address strategy) external view returns (bytes32[] memory) {
        return _strategyPositions[strategy].values();
    }

    // --- Internal ---

    function _computePositionId(
        address strategy,
        uint64 chainId,
        address targetProtocol,
        address targetAsset
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(strategy, chainId, targetProtocol, targetAsset));
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
- Registrar role is per-strategy (set by primary manager, changeable)
- Oracle confirmation required before position counts toward AUM

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

    struct AUMReport {
        uint256 totalCrossChainAssets;  // Sum of cross-chain position values
        uint256 timestamp;
        uint256 nonce;
    }

    // --- Storage ---

    ISuperGovernor public immutable SUPER_GOVERNOR;

    bytes32 public constant UPDATE_AUM_TYPEHASH = keccak256(
        "UpdateAUM(address strategy,uint256 totalCrossChainAssets,uint256 timestamp,uint256 nonce)"
    );

    /// @dev strategy => latest AUM report
    mapping(address => AUMReport) public latestReport;

    /// @dev strategy => nonce for replay protection
    mapping(address => uint256) public noncePerStrategy;

    /// @dev strategy => AUM oracle config
    mapping(address => AUMOracleConfig) public configs;

    struct AUMOracleConfig {
        uint256 maxStaleness;        // Max age of AUM data before blocking
        uint256 minUpdateInterval;   // Rate limiting
        uint256 deviationThreshold;  // Max relative change per update (1e18 scale)
    }

    // --- Core Functions ---

    /// @notice Submit AUM update with quorum-signed proofs
    /// @dev Follows ECDSAPPSOracle validation pattern
    function forwardAUM(
        address strategy,
        uint256 totalCrossChainAssets,
        uint256 timestamp,
        bytes[] calldata proofs
    ) external {
        // 1. Validate quorum (reuse SUPER_GOVERNOR.getPPSOracleQuorum())
        uint256 requiredQuorum = SUPER_GOVERNOR.getPPSOracleQuorum();
        if (proofs.length < requiredQuorum) revert QUORUM_NOT_MET();

        // 2. Verify EIP-712 signatures (ascending unique signers)
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            UPDATE_AUM_TYPEHASH,
            strategy,
            totalCrossChainAssets,
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

        // 3. Validate timestamp (monotonicity, staleness, rate limit)
        AUMReport memory current = latestReport[strategy];
        AUMOracleConfig memory config = configs[strategy];

        if (timestamp > block.timestamp) revert FUTURE_TIMESTAMP();
        if (timestamp <= current.timestamp) revert STALE_UPDATE();
        if (timestamp - current.timestamp < config.minUpdateInterval) revert RATE_LIMITED();
        if (block.timestamp - timestamp > config.maxStaleness) revert DATA_TOO_STALE();

        // 4. Deviation check
        if (current.totalCrossChainAssets > 0 && config.deviationThreshold != type(uint256).max) {
            uint256 absDiff = totalCrossChainAssets > current.totalCrossChainAssets
                ? totalCrossChainAssets - current.totalCrossChainAssets
                : current.totalCrossChainAssets - totalCrossChainAssets;
            uint256 deviation = (absDiff * 1e18) / current.totalCrossChainAssets;
            if (deviation > config.deviationThreshold) {
                emit AUMDeviationExceeded(strategy, current.totalCrossChainAssets, totalCrossChainAssets);
                return; // Soft fail, don't update
            }
        }

        // 5. Update
        noncePerStrategy[strategy]++;
        latestReport[strategy] = AUMReport({
            totalCrossChainAssets: totalCrossChainAssets,
            timestamp: timestamp,
            nonce: noncePerStrategy[strategy]
        });

        // 6. Update position registry values
        _syncPositionRegistry(strategy, totalCrossChainAssets);

        emit AUMUpdated(strategy, totalCrossChainAssets, timestamp);
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
- Same ECDSA quorum pattern as ECDSAPPSOracle (reuse validator infrastructure)
- Separate from PPS to avoid circular dependency (AUM doesn't depend on PPS)
- All PPS oracle validation properties replicated: timestamp checks, monotonicity, rate limiting, deviation threshold
- Soft-fail on deviation (emit + return) to prevent oracle DoS
- AUM freshness check usable by other contracts (cap guard, deposit gate)

#### Phase 3: CrossChainPositionCapGuard

Hook validation layer for cap enforcement during `executeHooks()`.

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";

contract CrossChainPositionCapGuard {

    // --- Types ---

    struct CapConfig {
        uint256 maxCrossChainBps;         // Global max % of AUM cross-chain (e.g., 7000 = 70%)
        mapping(uint64 => uint256) perChainCap;  // Max amount per chain
    }

    // --- Storage ---

    ISuperGovernor public immutable SUPER_GOVERNOR;
    uint256 public constant BPS_PRECISION = 10_000;

    /// @dev strategy => cap configuration
    mapping(address => CapConfig) private _caps;

    // --- Core Functions ---

    /// @notice Check if a cross-chain deployment is within caps
    /// @dev Called by executeHooks() validation layer before bridge hooks
    function validateAllocation(
        address strategy,
        uint64 destinationChainId,
        uint256 amount
    ) external view returns (bool) {
        // Get AUM oracle
        address aumOracleAddr = SUPER_GOVERNOR.getAddress(
            keccak256("CROSS_CHAIN_AUM_ORACLE")
        );
        ICrossChainAUMOracle aumOracle = ICrossChainAUMOracle(aumOracleAddr);

        // Require fresh AUM data
        if (!aumOracle.isAUMFresh(strategy)) return false;

        uint256 totalAUM = aumOracle.getTotalAUM(strategy);
        if (totalAUM == 0) return false;

        // Get current cross-chain allocation
        address registryAddr = SUPER_GOVERNOR.getAddress(
            keccak256("CROSS_CHAIN_POSITION_REGISTRY")
        );
        uint256 currentCrossChain = ICrossChainPositionRegistry(registryAddr)
            .getCrossChainAUM(strategy);

        // Global cap check
        CapConfig storage caps = _caps[strategy];
        uint256 newCrossChain = currentCrossChain + amount;
        if (newCrossChain * BPS_PRECISION > totalAUM * caps.maxCrossChainBps) {
            return false;
        }

        // Per-chain cap check
        uint256 perChainMax = caps.perChainCap[destinationChainId];
        if (perChainMax > 0) {
            uint256 chainExposure = ICrossChainPositionRegistry(registryAddr)
                .getChainExposure(strategy, destinationChainId);
            if (chainExposure + amount > perChainMax) return false;
        }

        return true;
    }

    /// @notice Set cap configuration (primary manager or governor)
    function setCapConfig(
        address strategy,
        uint256 maxCrossChainBps,
        uint64[] calldata chainIds,
        uint256[] calldata chainCaps
    ) external onlyManagerOrGovernor(strategy) {
        if (maxCrossChainBps > BPS_PRECISION) revert INVALID_CAP();
        _caps[strategy].maxCrossChainBps = maxCrossChainBps;

        for (uint256 i; i < chainIds.length; i++) {
            _caps[strategy].perChainCap[chainIds[i]] = chainCaps[i];
        }

        emit CapConfigUpdated(strategy, maxCrossChainBps);
    }
}
```

**Key Design Decisions:**
- Pure validation contract (view functions for cap checks)
- Uses AUM oracle data (not on-chain balances) to prevent flash loan manipulation
- Requires fresh AUM data -- stale data blocks all cross-chain deployments (fail-safe)
- Per-chain caps provide granular risk control
- Set by primary manager or governor (follows existing role hierarchy)

### Integration Points

#### 1. SuperGovernor Address Registry
Register new contracts in SuperGovernor:
```solidity
bytes32 public constant CROSS_CHAIN_POSITION_REGISTRY = keccak256("CROSS_CHAIN_POSITION_REGISTRY");
bytes32 public constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");
bytes32 public constant CROSS_CHAIN_CAP_GUARD = keccak256("CROSS_CHAIN_CAP_GUARD");
```

#### 2. executeHooks() Cap Check Integration
The PositionCapGuard must be checked when bridge hooks are executed. This can be done either:
- **Option A:** As a pre-execution hook in the Merkle-validated hook chain
- **Option B:** As a modifier/check in a wrapper around `executeHooks()`
- **Recommended: Option A** -- register PositionCapGuard as a hook that must appear before any bridge hook in the chain. This uses the existing Merkle validation system without modifying SuperVaultStrategy.

#### 3. PPS Oracle Extension
The off-chain PPS oracle aggregation service extends to:
1. Query position values across all chains where the vault has positions
2. Compute `totalAssets = hubChainAssets + sum(crossChainPositionValues)`
3. Compute `PPS = totalAssets / totalSupply`
4. Submit via existing `forwardPPS()` (no contract changes)
5. Separately submit AUM via `forwardAUM()` (new endpoint)

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
- [x] Proper access control: Registrar role per strategy, AUM oracle role via SuperGovernor
- [x] Admin timelock: Follow existing patterns (parameter changes = 3 days, manager changes = 7 days)
- [x] Position registration timelock: Pending -> Confirmed flow with 2-hour timeout

### DeFi Interaction Risks
- [x] Flash loan: Cap enforcement uses oracle AUM (stale-by-design, not flashable)
- [x] MEV/sandwich: AUM updates are M-of-N signed, not mempool-visible single-key txs
- [x] Cross-chain trust: Quorum-signed position data, not single registrar key
- [x] First depositor: Existing SuperVault mitigations apply (oracle-driven PPS, not balance-derived)

### Exploit Precedent Check

| Similar Protocol | Exploit | Loss | Relevance | Our Mitigation |
|---|---|---|---|---|
| Wormhole | Forged guardian signatures | $320M | AUM oracle signature validation | M-of-N ECDSA quorum with validator registry |
| Ronin | Compromised 5/9 validator keys | $625M | Registrar key compromise | Quorum-based position registration, not single key |
| Euler | Donation attack (balance manipulation) | $197M | AUM inflation via balance manipulation | Oracle-driven AUM, not on-chain balance queries |
| Multichain | Centralized key management | $130M+ | Single registrar EOA | Multi-sig/quorum requirement for critical operations |

## Acceptance Criteria

### Functional Requirements
- [ ] CrossChainPositionRegistry tracks positions with full lifecycle (Pending -> Active -> WindingDown -> Exited)
- [ ] Registrar role can register/deregister positions (per-strategy, set by primary manager)
- [ ] AUM oracle confirms positions with M-of-N quorum signatures
- [ ] Unconfirmed positions auto-invalidate after timeout (2 hours)
- [ ] CrossChainAUMOracle receives quorum-signed AUM updates
- [ ] AUM oracle validates: timestamp monotonicity, staleness, rate limiting, deviation threshold
- [ ] Position cap guard enforces global cross-chain allocation limit (BPS)
- [ ] Position cap guard enforces per-chain allocation limits
- [ ] Stale AUM data blocks new cross-chain deployments (fail-safe)
- [ ] All new contracts registered in SuperGovernor address registry
- [ ] Cap guard integrates with existing hook validation (as a pre-bridge hook)
- [ ] Cross-chain deposits work via existing SuperExecutor flow (no changes)
- [ ] Withdrawals work via existing ERC7540 async flow (no changes)

### Non-Functional Requirements
- [ ] No modifications to existing SuperVault, SuperVaultStrategy, SuperVaultAggregator
- [ ] Gas-efficient: packed storage, EnumerableSet for O(1) lookups
- [ ] All validation checks follow soft-fail pattern (emit + return) for batch compatibility

### Security Requirements
- [ ] Multi-oracle quorum for AUM updates (not single-key)
- [ ] Position registration requires role + oracle confirmation (two-layer validation)
- [ ] Cap enforcement uses oracle-reported AUM (flash-loan resistant)
- [ ] Deviation threshold auto-flags suspicious AUM changes
- [ ] Bridge hooks remain NONACCOUNTING (no position auto-registration)

### Testing Requirements
- [ ] Unit tests for each new contract in isolation
- [ ] Fork tests with simulated cross-chain messaging
- [ ] Invariant tests: positions <= AUM, cap always respected, PPS * supply ~= AUM
- [ ] Fuzz tests for cap boundary conditions
- [ ] Scenario tests: stale AUM blocks deposits, liquidation reflects in PPS, bridge timeout handling

## Success Metrics
- Cross-chain positions accurately reflected in PPS within oracle update cadence
- Position caps enforced on-chain with zero bypass incidents
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
| False position registration inflates PPS | Position Registration | Low | Critical | Quorum-based registration + oracle confirmation |
| AUM oracle compromise | Oracle | Low | Critical | M-of-N quorum + deviation threshold + staleness checks |
| Cap bypass via flash loan | Flash Loan | Medium | High | Oracle-reported AUM (not on-chain balances) for cap denominator |
| Bridge fill failure | Cross-Chain | Medium | Medium | Pending status, no AUM impact until confirmed |
| Double-counting during position exit | Vault Accounting | Medium | High | Atomic deregistration on bridge callback confirmation |
| Registrar key compromise | Access Control | Low | High | Multi-sig or quorum for registrar role |
| Stale position data after liquidation | Oracle | Medium | High | Deviation threshold flags large AUM drops |

## Implementation

### New Files

```
src/
  CrossChain/
    CrossChainPositionRegistry.sol     # Position tracking
    CrossChainAUMOracle.sol            # AUM feed with quorum
    CrossChainPositionCapGuard.sol     # Cap enforcement hook
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
  fork/
    CrossChainIntegration.t.sol
  recon/
    targets/
      CrossChainTargets.sol            # Invariant test targets
script/
  DeployCrossChain.s.sol
```

### Existing Files Modified
- `src/SuperGovernor.sol` -- Add new address registry keys (CROSS_CHAIN_POSITION_REGISTRY, CROSS_CHAIN_AUM_ORACLE, CROSS_CHAIN_CAP_GUARD)
- No other existing files modified

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
