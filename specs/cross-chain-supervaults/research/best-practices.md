# Best Practices Research - Cross-Chain SuperVaults

## 1. Industry Vault Architectures

### Yearn V3 (yvUSD Cross-Chain Vault)
- **Architecture:** `currentDebt` per strategy tracks capital allocation
- Reports from strategies reconcile P&L, charge fees, lock profit
- `totalAssets()` = idle assets + sum of `currentDebt` across all strategies
- Separate `DebtAllocator` periphery contract manages capital distribution
- On-chain APR Oracle informs allocation decisions
- Cross-chain vault `yvUSD` (launched Jan 2026): off-chain strategy layer for cross-chain ops, accounting on hub chain
- **Relevance:** `currentDebt` maps directly to CrossChainPositionRegistry. Key difference: cross-chain positions can't call `strategy.totalAssets()` synchronously -- requires oracle feed

### Morpho (MetaMorpho Vaults)
- **Architecture:** Morpho Blue (650-line immutable lending primitive) + MetaMorpho Vaults (curator-managed ERC-4626)
- Non-rebasing share model (simplifies accounting)
- Reallocations only redistribute existing assets
- Cross-chain rebalancing via intent-based layers (Eco Routes)
- **Relevance:** Independent chain instances with external bridging is simpler but less capital-efficient than unified hub-chain vault

### Ethena (USDe Reserve Oracle)
- **Architecture:** Chaos Labs Edge Proof of Reserves Oracle using ZK proofs
- Real-time reserve verification including off-chain and cross-chain assets
- Reserve data as standard oracle feeds
- Automatic cross-chain actions triggered on reserve condition failures
- **Relevance:** ZK-proof reserve verification is the gold standard for cross-chain balances without trust assumptions

### Sommelier Finance (Cosmos Validator Approach)
- **Architecture:** Independent Cosmos SDK blockchain with validators executing ERC-4626 "Cellars"
- Off-chain computation keeps strategies private
- Cross-chain execution via Axelar GMP
- Governance-approved strategies executed by validators
- **Relevance:** Separating strategy computation (off-chain) from execution (on-chain) parallels Superform's ECDSAPPSOracle pattern

## 2. Cross-Chain Position Registry Best Practices

### Recommended Data Model
```solidity
struct CrossChainPosition {
    uint64 chainId;
    address targetProtocol;
    address targetAsset;
    uint256 deployedAmount;
    uint256 lastReportedValue;
    uint256 lastReportTimestamp;
    bytes32 positionId;
    PositionStatus status; // Active, WindingDown, Exited
}
```

### Update Mechanisms
- **Pattern A (Push-based - Recommended primary):** Off-chain oracle monitors positions, pushes value updates to hub chain. Matches existing ECDSAPPSOracle pattern
- **Pattern B (Pull-based):** Hub chain queries spoke chains via cross-chain messaging
- **Pattern C (Hybrid - Recommended):** Regular push updates + pull-based verification on demand + emergency circuit breaker on staleness

### Position Lifecycle with Confirmation
```
Register -> Pending -> Confirmed -> Active -> Winding Down -> Exited
              ^             ^
              |             |
         Manager        AUM Oracle
        (on-chain)     (off-chain)
```
Position registered but not confirmed within timeout should be auto-invalidated.

## 3. Oracle Patterns for Multi-Chain AUM

### Breaking Circular Dependency
Critical separation: PPS computation vs AUM reporting

```
PPS = totalAssets / totalShares
totalAssets = hubChainAssets + sum(crossChainPositionValues)
```

If position caps depend on totalAssets, and totalAssets depends on PPS oracle, circular dependency emerges.

**Solution:** Separate AUM oracle feed for cap enforcement, independent of PPS oracle:
- **AUM Oracle (for caps):** Reports totalCrossChainAssets, can be slightly stale (hourly acceptable)
- **PPS Oracle (for pricing):** Reports pricePerShare, must be fresh (per strategy's ppsExpiration)

### Multi-Source Aggregation
- **Median/Weighted Average Pattern** - Sort reports, return median, reject if spread exceeds threshold
- **Chain-Specific Validator Subsets** - Different validators may have access to different chains
- **Chainlink PoR Model** - Decentralized oracle network independently verifies reserves

## 4. Position Cap Enforcement Patterns

### Industry Patterns
- **Morpho Supply Caps:** Per-market maximum supply, raising triggers timelock (1-7 days)
- **Yearn V3 Debt Limits:** `currentDebt[strategy] <= maxDebt[strategy]`, vault-level `deposit_limit`

### Recommended Cap Structure
```solidity
struct PositionCaps {
    mapping(uint64 chainId => uint256 maxDeployed) perChainCap;
    mapping(bytes32 protocolId => uint256 maxDeployed) perProtocolCap;
    uint256 maxCrossChainBps;        // e.g., 7000 = 70% max cross-chain
    uint256 maxSinglePositionBps;    // e.g., 2000 = no position > 20%
}
```

### Cap Enforcement Logic
```solidity
function canDeploy(address strategy, uint64 targetChainId, uint256 amount) external view returns (bool) {
    AUMReport memory aum = aumOracle.getLatestReport(strategy);
    if (block.timestamp - aum.timestamp > MAX_AUM_STALENESS) return false;

    uint256 totalAUM = aum.totalHubAssets + aum.totalCrossChainAssets;
    uint256 newCrossChain = aum.totalCrossChainAssets + amount;
    if (newCrossChain * BPS_PRECISION > totalAUM * caps.maxCrossChainBps) return false;

    uint256 chainExposure = getChainExposure(strategy, targetChainId) + amount;
    if (chainExposure > caps.perChainCap[targetChainId]) return false;
    return true;
}
```

## 5. Role-Based Position Registration

### Three-Layer Validation
1. **Role-based access:** Only primary manager can register positions
2. **Merkle proof validation:** Position parameters must be in approved hooks Merkle root (governance pre-approves valid targets)
3. **Oracle confirmation:** AUM oracle independently confirms position exists on target chain

### Industry Patterns
- **Yearn V3:** Governance-gated `add_strategy()` / `revoke_strategy()`
- **Sommelier:** Validator-approved strategy changes through governance vote

## 6. Multi-Oracle Quorum Patterns

### Existing ECDSAPPSOracle Pattern (to reuse)
- M-of-N ECDSA quorum with EIP-712 typed data
- Nonce-based replay protection
- Sorted/unique signer validation
- Per-strategy nonces

### Enhanced Patterns for Cross-Chain
- **Chain-Specific Validator Subsets** - validators with chain-specific expertise
- **Multi-Source Medianizer (MakerDAO-inspired)** - sort and take median of valid reports
- **Threshold Signature Schemes (TSS)** - single signature from M-of-N participants (O(1) verification)
- **Optimistic Oracle (UMA-inspired)** - propose + dispute period for less time-sensitive data like AUM caps

## 7. Hub-and-Spoke Reference: LayerZero OVault

### Architecture
- Hub chain hosts ERC-4626 vault + Composer contract
- Spoke chains have lightweight OFT endpoints
- Two OFT meshes: one for underlying asset, one for vault shares
- Two-phase: source-to-hub transfer, then hub operations

### Key Insight
OVault solves "accept deposits from any chain" but NOT "deploy yield across chains." Superform's model has assets leaving hub to chase yield -- the harder problem requiring position registry + AUM oracle.

## 8. ERC-7540 Async Vault Pattern (Already Implemented)
- Request lifecycle: Pending -> Claimable -> Claimed
- Superform already implements ERC-7540 for async redemptions in `SuperVault.sol`
- Extends naturally to cross-chain: assets recalled from remote chain before fulfilling redemption

## 9. Key Design Principles

1. **Hub chain is authoritative** - all accounting, share minting/burning, cap enforcement on hub
2. **Separate AUM from PPS** - independent feeds avoid circular dependencies
3. **Manager proposes, oracle confirms** - dual validation prevents false position registration
4. **Conservative cap enforcement** - stale AUM blocks new deployments (fail-safe)
5. **Graceful degradation** - if cross-chain fails, vault continues with hub-chain assets, PPS staleness triggers automatic deposit blocking
