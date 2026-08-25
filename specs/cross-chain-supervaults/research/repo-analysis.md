# Repository Analysis - Cross-Chain SuperVaults

## 1. Existing SuperVault Architecture

### Core Contracts
| Component | File | Key Lines |
|-----------|------|-----------|
| SuperVault | `src/SuperVault/SuperVault.sol` | ERC4626+ERC7540+ERC7741 |
| SuperVaultStrategy | `src/SuperVault/SuperVaultStrategy.sol` | Hooks, accounting, fees |
| SuperVaultAggregator | `src/SuperVault/SuperVaultAggregator.sol` | Factory, PPS oracle, governance |
| SuperVaultEscrow | `src/SuperVault/SuperVaultEscrow.sol` | Share/asset custody |
| SuperVaultExecutor | `src/SuperVault/SuperVaultExecutor.sol` | Session keys, ERC-4337 |
| SuperVaultBatchOperator | `src/SuperVault/SuperVaultBatchOperator.sol` | Batch claims |

### Registry Pattern (SuperVaultAggregator)
- Uses `EnumerableSet.AddressSet` for tracking deployed vaults, strategies, escrows (lines 57-59)
- Deterministic deployment using `Clones.cloneDeterministic()` with salt based on deployer + asset + name + symbol + nonce (lines 162-168)
- **Pattern for Cross-Chain:** Use `EnumerableSet.Bytes32Set` for position IDs with mapping to position data

### Strategy Data Storage (Optimized Packing)
- Packs address (20 bytes) + 3 booleans (1 byte each) into single slot
- StrategyData struct: pps, lastUpdateTimestamp, minUpdateInterval, maxStaleness, mainManager + packed flags
- **Recommendation:** Pack `registrar (20 bytes) + isPaused (1 byte) + padding (11 bytes) = 32 bytes` per position

## 2. PPS Oracle Mechanisms

### forwardPPS() Validation Chain (Lines 239-307, 1238-1335)
1. **Future timestamp rejection** (258-261) - prevents pre-signed updates
2. **Pause rejection** (265-272) - skips paused strategies
3. **Staleness enforcement** (274-281) - reverts if data too old
4. **Timestamp monotonicity** (1243-1249) - prevents out-of-order
5. **Rate limiting** (1260-1266) - prevents spam
6. **Deviation threshold** (1271-1290) - auto-pauses on suspicious changes (>50% default)
7. **Upkeep balance** (1292-1315) - auto-pauses if insufficient payment

**Key insight:** None of these checks revert internally during batch processing - they emit + return to allow subsequent strategies to process.

### Pattern for Cross-Chain AUM Oracle
Replicate the entire validation chain for AUM feeds with potentially different staleness/deviation parameters.

## 3. Hook Validation System

### Dual Merkle Root System (Lines 1127-1192)
- **Global Hooks Root** (governance-controlled) - lines 84-87
- **Strategy-Specific Hooks Root** (manager-controlled) - stored in StrategyData

### Leaf Creation Pattern (Lines 1341-1348)
```solidity
function _createLeaf(address hookAddress, bytes calldata hookArgs)
    internal pure returns (bytes32)
{
    return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
}
```
- Includes BOTH address AND args to prevent cross-hook replay
- hookArgs extracted via `ISuperHookInspector.inspect(hookCalldata)`

### Security Features
- Single-leaf optimization (lines 1393-1395)
- Banned leaf feature (lines 1387-1390) for instant blocking
- Veto capability disables all hooks instantly

## 4. Access Control Patterns

### SuperGovernor Central Registry (`src/SuperGovernor.sol`)
- Roles: SUPER_GOVERNOR, GOVERNOR, BANK_MANAGER, GUARDIAN, GAS_MANAGER, ORACLE_MANAGER
- Address registry: `mapping(bytes32 id => address)` with keys like SUPER_VAULT_AGGREGATOR
- **New keys needed:** `CROSS_CHAIN_POSITION_REGISTRY`, `CROSS_CHAIN_AUM_ORACLE`

### Manager Hierarchy (Two-Tier)
- **Primary Manager:** Can execute most functions
- **Secondary Managers:** Can propose primary manager changes (7-day timelock)
- **SuperGovernor override:** Immediate change (line 575)
- **Max 5 secondary managers** - prevents DoS (line 68)
- **Security cleanup on manager change:** Clears all pending proposals and removes all secondary managers (lines 595-624)

## 5. Composable Contract Pattern

### SuperVaultExecutor as Reference
- Non-upgradeable, added as secondary manager on strategies
- Session key system for delegated authority
- ERC-4337 EntryPoint integration
- Immutables: SUPER_GOVERNOR, SUPER_VAULT_AGGREGATOR_KEY, ENTRY_POINT

### Pattern for CrossChainPositionRegistry
1. Non-upgradeable deployment (or upgradeable if needed)
2. Registered in SuperGovernor address registry
3. Store authorized oracles for cross-chain AUM
4. Gate function execution with role-based checks
5. Compose with existing SuperVaultStrategy through hooks

## 6. Bridge Hook Patterns

### Across Bridge Hook Data Structure
```solidity
struct AcrossV3DepositAndExecuteData {
    uint256 value;
    address recipient;
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 outputAmount;
    uint256 destinationChainId;
    address exclusiveRelayer;
    uint32 fillDeadlineOffset;
    uint32 exclusivityPeriod;
    bool usePrevHookAmount;
    bytes destinationMessage;
}
```

### Key Patterns
- **Previous hook amount chaining** via `usePrevHookAmount` (lines 100-119)
- **Signature injection** - signature stored in transient storage, appended at execution
- **NONACCOUNTING hook type** - bridge hooks don't track accounting state directly
- Both Across and deBridge hooks follow same pattern

## 7. Deployment Patterns

### Deterministic Proxy Deployment
```solidity
vars.salt = keccak256(abi.encode(msg.sender, params.asset, params.name, params.symbol, vars.currentNonce));
superVault = VAULT_IMPLEMENTATION.cloneDeterministic(vars.salt);
```
- Cheaper than UUPS proxies
- Deterministic addresses (compute off-chain)
- Same vault on multiple chains at deterministic addresses

## 8. Timelock Patterns

| Operation | Duration | Code Reference |
|-----------|----------|---------------|
| Upkeep withdrawal | 24 hours | Line 75 |
| Manager change | 7 days | Line 77 |
| Hooks root update | 15 minutes | Line 78 |
| Parameter change | 3 days | Line 81 |
| Oracle feed addition | 1 week | SuperOracleBase |
| Oracle feed removal | 1 hour | SuperOracleBase |

## 9. Recommended Architecture for New Contracts

### CrossChainPositionRegistry
- Extends SuperVaultAggregator registry pattern (EnumerableSet)
- Position data struct with chain IDs, allocations, AUM, timestamps
- Registrar role gated by SuperGovernor
- Pause/unpause per position
- Position lifecycle: Register -> Pending -> Confirmed -> Active -> Winding Down -> Exited

### CrossChainAUMOracle
- Extends SuperOracleBase + forwardPPS pattern
- Receives AUM feed submissions with full validation chain
- Supports multiple providers per position (max 10)
- Queue-execute pattern for feed updates

### PositionCapGuard
- Follows hook validation pattern with Merkle proofs
- Validates allocations pre-execution during executeHooks()
- Per-chain caps, per-protocol caps, global cross-chain cap
- Banned caps feature for emergency disabling

### Integration Points
- SuperVaultStrategy: Execute cross-chain hooks through existing system
- SuperVaultAggregator: Leverage pause/veto mechanisms
- SuperGovernor: Use address registry for oracle addresses
- Upkeep System: Reuse upkeep token mechanics for AUM oracle payment
