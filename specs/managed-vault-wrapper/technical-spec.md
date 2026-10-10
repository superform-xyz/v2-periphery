# Managed Vault Wrapper — Technical Specification

## Overview

Managed Vaults is a new vault type in SuperformOS that gives portfolio managers **async ERC-7540 deposit/redeem rails** with **manual NAV attestation**, without requiring a fork of the existing SuperVault/SuperVaultStrategy/SuperVaultAggregator family.

The architecture introduces two new contracts and one oracle replacement:
1. **`ManagedECDSAAppsOracle`** — replaces `ECDSAPPSOracle` as the single `_activePPSOracle`. Handles both automated ECDSA-signed PPS updates (existing path) and new single-call managed NAV attestation.
2. **`ManagedVaultWrapper`** — standalone ERC-7540 vault wrapping SuperVault shares. Investors deposit assets, the vault deploys into an SV strategy, and NAV is attested by the manager.
3. **`ManagedVaultWrapperFactory`** — minimal-proxy deployer for creating new wrappers.

---

## Problem Statement

PR #326 added `ManagedSuperVaultAggregator`, `ManagedNAVOracle`, and `ManagedSuperVaultDepositQueue` — effectively forking the SV family. The root constraint was that `SuperGovernor._activePPSOracle` is a singleton: one address prices all strategies.

**Alternative (this spec):** A wrapper vault sits between the investor and the SV. The wrapper is its own ERC-7540 vault with its own PPS tracked in the existing SV aggregator. `ManagedECDSAAppsOracle` becomes the new single active oracle and routes the managed attestation path separately from the ECDSA automation path.

**No SV family fork required.**

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          INVESTOR                               │
└────────────────────┬────────────────────────────────────────────┘
                     │ requestDeposit(assets)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                  ManagedVaultWrapper (ERC-7540)                  │
│  - Holds SV shares as underlying asset                           │
│  - Maintains pending/claimable deposit & redeem queues           │
│  - isGated: optional investor allowlist                          │
│  - Uses PPS from SV Aggregator (forwarded by oracle)             │
└──────────────┬──────────────────────────────────┬───────────────┘
               │ manager calls                     │ holds SV shares
               ▼                                  ▼
┌──────────────────────────┐   ┌─────────────────────────────────┐
│  ManagedECDSAAppsOracle  │   │      SuperVaultStrategy         │
│  (= _activePPSOracle)    │   │  (existing, unmodified)         │
│                          │   └─────────────────────────────────┘
│  ECDSA path (automated): │
│  → validates N-of-M sigs │
│  → forwardPPS to aggreg. │
│                          │
│  Managed path:           │
│  → manager calls updateP │
│    PSManaged(strat, pps) │
│  → isManagedStrategy[s]  │
│  → forwardPPS to aggreg. │
└──────────────────────────┘
```

---

## New Contracts

### Contract 1: `ManagedECDSAAppsOracle`

**Location:** `src/oracles/ManagedECDSAAppsOracle.sol`

**Inherits:** `ECDSAPPSOracle` (or composes it)

**New Storage:**
```solidity
mapping(address strategy => bool) public isManagedStrategy;
```

**New Functions:**

```solidity
/// @notice Register or unregister a strategy as managed (governor only)
function setManagedStrategy(address strategy, bool managed)
    external
    onlyRole(GOVERNOR_ROLE);

/// @notice Manager attests NAV for a managed strategy directly (no ECDSA required)
/// @param strategy The managed strategy address (must be in isManagedStrategy)
/// @param pps The price-per-share value in PRECISION units
function updatePPSManaged(address strategy, uint256 pps)
    external;
    // Access: strategy's mainManager (checked via aggregator.getMainManager(strategy))
    //         OR ORACLE_MANAGER_ROLE holder

/// @notice Override ECDSA path to block managed strategies from being updated via ECDSA
function updatePPS(UpdatePPSArgs calldata args) external override;
    // Validates: none of args.strategies are in isManagedStrategy
    // Then: calls super.updatePPS(args)
```

**updatePPSManaged internals:**
```solidity
function updatePPSManaged(address strategy, uint256 pps) external {
    if (!isManagedStrategy[strategy]) revert NOT_MANAGED_STRATEGY();

    address aggregator = SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR);
    address mainManager = ISuperVaultAggregator(aggregator).getMainManager(strategy);

    bool isManager = (msg.sender == mainManager);
    bool isOracleManager = SUPER_GOVERNOR.hasRole(ORACLE_MANAGER_ROLE, msg.sender);
    if (!isManager && !isOracleManager) revert UNAUTHORIZED();

    ISuperVaultAggregator(aggregator).forwardPPS(
        ISuperVaultAggregator.ForwardPPSArgs({
            strategies:      _toArray(strategy),
            ppss:            _toArray(pps),
            timestamps:      _toArray(block.timestamp),
            updateAuthority: msg.sender
        })
    );

    emit ManagedPPSUpdated(strategy, pps, msg.sender);
}
```

**Events:**
```solidity
event ManagedPPSUpdated(address indexed strategy, uint256 pps, address indexed updatedBy);
event ManagedStrategySet(address indexed strategy, bool managed);
```

**Deployment / Migration:**
1. Deploy `ManagedECDSAAppsOracle`
2. Governor calls `superGovernor.setActivePPSOracle(address(newOracle))` (7-day timelock)
3. After timelock: `superGovernor.executeActivePPSOracleUpdate()`
4. Old `ECDSAPPSOracle` is retired

---

### Contract 2: `ManagedVaultWrapper`

**Location:** `src/SuperVault/ManagedVaultWrapper.sol`

**Implements:** `IERC7540Vault` (both deposit and redeem async)

**Key design decisions:**
- Asset = ERC-20 token (e.g., USDC)
- Shares = wrapper ERC-20 shares
- Underlying = SV strategy shares (held in this contract)
- NAV = derived automatically from the SV strategy's PPS in the aggregator. The wrapper does NOT maintain its own `storedPPS`. Instead, `ManagedECDSAAppsOracle.updatePPSManaged(svStrategy, pps)` calls `aggregator.forwardPPS(svStrategy, pps)`, and the wrapper reads `ISuperVaultAggregator(aggregator).getStoredPPS(svStrategy)` for all share/asset calculations.
- The `svStrategy` is the entity registered in `isManagedStrategy` (not the wrapper). The wrapper is NOT registered in the aggregator at all.

**Storage:**
```solidity
bool public isPaused;              // Guardian can pause

mapping(address controller => uint256 assets) public pendingDepositRequest;
mapping(address controller => uint256 shares) public claimableDepositShares;

mapping(address controller => uint256 shares) public pendingRedeemRequest;
mapping(address controller => uint256 assets) public claimableRedeemAssets;

uint256 public totalPendingDeposits;  // Sum of all pending deposit assets (used for share price calc)
uint256 public totalPendingRedeems;   // Sum of all pending redeem shares

bool public isGated;               // If true, only allowlisted addresses can requestDeposit
mapping(address investor => bool) public allowlist;

address public mainManager;
address public superGovernor;
address public svStrategy;         // The underlying SV strategy this wrapper invests into
address public aggregator;         // SuperVaultAggregator address (for PPS reads)
```

**Key Functions:**

```solidity
/// @notice ERC-7540: Submit a deposit request
function requestDeposit(uint256 assets, address controller, address owner)
    external
    nonReentrant
    returns (uint256 requestId);
    // Checks: if isGated, require allowlist[controller]
    // Checks: isPaused == false
    // Effects: pendingDepositRequest[controller] += assets
    // Interactions: asset.safeTransferFrom(owner, address(this), assets)

/// @notice Manager: fulfill pending deposit requests by minting wrapper shares
function fulfillDepositRequests(address[] calldata controllers)
    external
    nonReentrant;
    // Access: mainManager or secondary managers
    // Checks: !isPaused, svStrategy PPS is not stale (check aggregator timestamp)
    // Share price computation uses pre-deposit NAV to avoid double-counting:
    //   svPPS = aggregator.getStoredPPS(svStrategy)
    //   totalSVAssets = IERC20(svStrategy).balanceOf(address(this)) * svPPS / svPrecision
    //   priorAssets = totalSVAssets - totalPendingDeposits  // pre-deposit NAV
    //   priorSupply = totalSupply() - deadShares
    //   shares = pendingAssets * priorSupply / priorAssets  (or 1:1 if first deposit)
    //   claimableDepositShares[controller] = shares
    //   pendingDepositRequest[controller] = 0
    // Effects first, then _mint(address(this), totalSharesMinted)
    // Note: manager must have already deployed pending USDC into the SV strategy

/// @notice ERC-7540: Claim fulfilled deposit shares
function claimDeposit(address controller, address receiver)
    external
    nonReentrant
    returns (uint256 shares);
    // Effects: claimableDepositShares[controller] = 0
    // Interactions: _transfer(address(this), receiver, shares)

/// @notice ERC-7540: Submit a redeem request
function requestRedeem(uint256 shares, address controller, address owner)
    external
    nonReentrant
    returns (uint256 requestId);
    // Effects: pendingRedeemRequest[controller] += shares
    // Interactions: _transfer(owner, address(this), shares)

/// @notice Manager: fulfill pending redeem requests
function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata assetsOut)
    external
    nonReentrant;
    // Access: mainManager only
    // For each controller: verify assetsOut[i] ≥ pendingShares * svPPS / svPrecision (protect against NAV sandwich)
    //                      claimableRedeemAssets[controller] = assetsOut[i]
    //                      pendingRedeemRequest[controller] = 0
    // _burn(totalSharesBurned)
    // Note: manager must have already redeemed from SV and transferred assets to this contract

/// @notice ERC-7540: Claim fulfilled redeem assets
function claimRedeem(address controller, address receiver)
    external
    nonReentrant
    returns (uint256 assets);

/// @notice Manager can update allowlist (gated vaults only)
function setAllowlist(address[] calldata investors, bool[] calldata allowed)
    external;
    // Access: mainManager
```

**NAV Calculation:**
```solidity
function totalAssets() public view returns (uint256) {
    // Total SV shares held × SV PPS / SV PRECISION
    // PPS is set by manager via updatePPSManaged(svStrategy, pps) → aggregator.forwardPPS
    // Wrapper reads the SV strategy's PPS from the aggregator (no own storedPPS)
    uint256 svShares = IERC20(svStrategy).balanceOf(address(this));
    uint256 svPPS = ISuperVaultAggregator(aggregator).getStoredPPS(svStrategy);
    uint256 svPrecision = 10 ** IERC20Metadata(svStrategy).decimals();
    return (svShares * svPPS) / svPrecision;
}
```

**First Depositor Protection:**
```solidity
// In constructor/initialize:
_mint(DEAD_ADDRESS, DEAD_SHARES); // Burn 1000 dead shares
```

---

### Contract 3: `ManagedVaultWrapperFactory`

**Location:** `src/SuperVault/ManagedVaultWrapperFactory.sol`

```solidity
struct WrapperCreationParams {
    address asset;
    string name;
    string symbol;
    address mainManager;
    bool isGated;
    address svStrategy;      // Existing SV strategy to wrap
    uint256 maxStaleness;    // e.g., 1 weeks
    uint256 initialPPS;      // Starting NAV (e.g., PRECISION = 10^decimals)
}

function createWrapper(WrapperCreationParams calldata params)
    external
    returns (address wrapper);
    // Access: GOVERNOR_ROLE
    // Clone wrapperImpl via Clones.clone()
    // Initialize wrapper
    // Register wrapper as managed strategy in ManagedECDSAAppsOracle
    // emit WrapperCreated(wrapper, params.svStrategy, params.mainManager)
```

---

## Deposit Flow (Full)

```
1. [Investor]   requestDeposit(assets, controller, owner)
                → wrapper receives assets
                → pendingDepositRequest[controller] += assets

2. [Manager]    (Optional) Deploy pending assets into SV:
                IERC4626(svStrategy).deposit(pendingAssets, address(wrapper))
                → wrapper now holds SV shares

3. [Manager]    updatePPSManaged(svStrategy, currentPPS)
                → via ManagedECDSAAppsOracle → aggregator.forwardPPS(svStrategy, currentPPS)
                → aggregator stores svStrategy PPS; wrapper reads it in totalAssets()

4. [Manager]    fulfillDepositRequests([controller1, controller2, ...])
                → wrapper mints shares at current PPS
                → claimableDepositShares[controller] = assets * PRECISION / PPS

5. [Investor]   claimDeposit(controller, receiver)
                → receives wrapper shares
```

## Redeem Flow (Full)

```
1. [Investor]   requestRedeem(shares, controller, owner)
                → wrapper locks shares
                → pendingRedeemRequest[controller] += shares

2. [Manager]    (Off-chain) Redeems SV shares to get assets:
                ISuperVaultStrategy(svStrategy).requestRedeem(svShares, wrapper, wrapper)
                → (async SV redeem, wait for SV fulfillment)
                → ISuperVaultStrategy(svStrategy).claimRedeem(wrapper, wrapper)
                → wrapper now holds assets

3. [Manager]    updatePPSManaged(svStrategy, currentPPS)
                → aggregator.forwardPPS(svStrategy, currentPPS)

4. [Manager]    fulfillRedeemRequests([controller], [assetsOut])
                → burns wrapper shares
                → claimableRedeemAssets[controller] = assetsOut

5. [Investor]   claimRedeem(controller, receiver)
                → receives assets
```

---

## Attack Surface Analysis

### Token Risks
- [ ] Asset is standard ERC-20 (e.g., USDC) — no fee-on-transfer expected, add assertion on received amount
- [ ] SV shares are standard ERC-20 — not rebasing, no special hooks
- [ ] Wrapper shares are standard ERC-20

### Reentrancy
- [x] `nonReentrant` on all state-changing functions
- [x] CEI pattern: state updated before transfers
- [ ] Verify SV share contract has no ERC-777/ERC-1155 hooks

### NAV / Oracle
- [ ] `updatePPSManaged` has no timelock — **by design** (trusted manager)
- [ ] Add max deviation bound on single NAV update (10% BPS max)
- [ ] `isPPSStale()` check gates fulfill functions
- [x] Managed path blocked from ECDSA path (routing guard in ManagedECDSAAppsOracle)

### Share Accounting
- [x] First depositor: 1000 dead shares burned in constructor
- [ ] `totalAssets()` depends on aggregator's `svStrategy` PPS — stale PPS risks over-issuance of shares
- [x] Stale check: `aggregator.getStoredPPSTimestamp(svStrategy)` + `maxStaleness` gates fulfill functions

### Access Control
- [x] `fulfillDepositRequests` / `fulfillRedeemRequests` — only mainManager
- [x] `setPPS` — only active PPS oracle
- [x] `setManagedStrategy` — only GOVERNOR_ROLE
- [ ] Allowlist management — only mainManager (verify no self-grant)

### Vault Accounting Invariants
```
totalSupply == claimableSharesTotal + pendingRedeemTotal + heldSharesIssued
totalAssets >= claimableRedeemAssetsTotal
assets received in fulfill == pendingDepositTotal (pre-fulfill)
```

---

## Modified Contracts

### `SuperVaultAggregator` (unchanged)

`ManagedECDSAAppsOracle.updatePPSManaged(svStrategy, pps)` calls `aggregator.forwardPPS(svStrategy, pps)` — the same path as automated ECDSA updates, just without signatures. The wrapper is not registered in the aggregator; only the `svStrategy` is (as part of normal `createVault()`). No aggregator changes required.

### `SuperGovernor` (unchanged)

The `setActivePPSOracle` / `executeActivePPSOracleUpdate` flow is already implemented. Migration is a standard oracle rotation.

---

## Implementation Phases

### Phase 1: Oracle (1 week)
- [ ] `ManagedECDSAAppsOracle` contract
- [ ] Unit tests: routing guard, managed path authorization, ECDSA path unchanged
- [ ] Integration test: deploy as activePPSOracle, verify existing SV strategies still update

### Phase 2: Wrapper Vault (2 weeks)
- [ ] `ManagedVaultWrapper` ERC-7540 implementation
- [ ] Unit tests: deposit/redeem queues, PPS stale guard, first depositor protection
- [ ] Invariant fuzz tests (Echidna/Foundry): accounting invariants
- [ ] Integration test: full deposit → fulfillment → claim flow

### Phase 3: Factory + Migration (1 week)
- [ ] `ManagedVaultWrapperFactory`
- [ ] Integration test: create wrapper, register as managed, full lifecycle
- [ ] Fork test on Base mainnet: oracle rotation, wrapper alongside existing SV

---

## References

### Internal
- `src/oracles/ECDSAPPSOracle.sol` — oracle to extend
- `src/SuperGovernor.sol:433` — `setActivePPSOracle`
- `src/SuperGovernor.sol:744` — `isActivePPSOracle`
- `src/SuperVault/SuperVaultStrategy.sol:318` — `fulfillRedeemRequests` pattern
- `src/SuperVault/SuperVault.sol:182` — ERC-7540 redeem implementation (existing)
- `src/vendor/standards/ERC7540/IERC7540Vault.sol` — ERC-7540 interface
- `test/integration/SuperVault/BaseSuperVaultTest.t.sol` — setUp pattern

### External
- [EIP-7540](https://eips.ethereum.org/EIPS/eip-7540) — Async ERC-4626 standard
- [Lagoon Finance Nethermind Audit](https://www.nethermind.io/blog/securing-lagoons-asynchronous-erc-7540-vaults-as-the-protocol-scaled-from-v1-to-v5) — ERC-7540 security findings
- [OZ ERC4626 Inflation Attack Defense](https://www.openzeppelin.com/news/a-novel-defense-against-erc4626-inflation-attacks) — dead shares pattern
