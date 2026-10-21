# EVM Security Research — Managed Vault Wrapper

## 1. Relevant Vulnerability Patterns

### 1.1 ERC-7540 Async Vault Specific

| # | Pattern | Risk | Severity |
|---|---------|------|----------|
| A | **Pending → Claimable state transition bug** | Assets counted twice or not at all during fulfillment, enabling over-withdrawal or locked funds | Critical |
| B | **Unbacked share issuance** | Minting shares before assets arrive (or after they leave) creates under-collateralized period | High |
| C | **Settlement DoS** | Vault holds no on-chain liquidity at redeem time because assets deployed to SV; no fallback | Medium |
| D | **Dust attacks** | Tiny deposit requests that stall the fulfillment queue or cause rounding to zero shares | Low |
| E | **Race between requestRedeem and fulfillRedeemRequests** | Manager can reorder fulfill calls to front-run user redemptions at a favorable NAV | High |

### 1.2 NAV Attestation / Oracle

| # | Pattern | Risk | Severity |
|---|---------|------|----------|
| F | **Manager NAV sandwich** | Manager lowers NAV → fulfills redeems (gives fewer assets per share) → raises NAV. Users get fewer assets than fair value. | High (trusted party) |
| G | **Oracle singleton blast radius** | ManagedECDSAAppsOracle is `_activePPSOracle`. A bug in the managed attestation path (updatePPSManaged) could corrupt PPS for ALL automated SV strategies too. | Critical |
| H | **Unauthorized managed strategy call** | If `isManagedStrategy` check is missing or bypassable, unauthorized caller sets arbitrary PPS | Critical |
| I | **Replay attack** | If managed path has no nonce/timestamp, old PPS values can be re-submitted to revert NAV to a stale value | Medium |
| J | **Cross-strategy PPS corruption** | ECDSA path processes a batch that includes managed strategy addresses, causing their PPS to be set via validator signatures instead of manager attestation | Medium |

### 1.3 Share Accounting

| # | Pattern | Risk | Severity |
|---|---------|------|----------|
| K | **First depositor inflation attack** | Attacker deposits 1 wei, directly transfers SV shares to the wrapper, inflating totalAssets/totalSupply ratio, causing second depositor to receive 0 shares | High |
| L | **Wrapper-in-wrapper double counting** | ManagedVaultWrapper holds SV shares; totalAssets counts SV share price. If SV PPS is also manipulated, wrapper NAV compounds the error. | Medium |
| M | **Redeem queue accounting drift** | `pendingRedeemRequests` balances not matching actual SV shares held causes under/over-fulfillment | High |

### 1.4 Access Control

| # | Pattern | Risk | Severity |
|---|---------|------|----------|
| N | **Investor allowlist bypass** | Gated vaults with on-chain mapping can be bypassed if the mapping is not checked on `requestDeposit` (only on `deposit`) | Medium |
| O | **Manager role transfer** | If manager can set `updatePPSManaged` access to any address without governor approval, access escalation possible | Medium |

### 1.5 Reentrancy

| # | Pattern | Risk | Severity |
|---|---------|------|----------|
| P | **Fulfill reentrancy** | `fulfillRedeemRequests` transfers assets and calls external SV `burnShares` - if SV shares are ERC-777 or have hooks, reentrancy possible | Medium |
| Q | **Allowlist check reentrancy** | If allowlist uses ERC-1155/721 NFT ownership check and receiver is a contract, callback during `requestDeposit` could re-enter | Low |

---

## 2. Attack Surface Map

```
Investor → [requestDeposit] → Pending State
                                    ↕ NAV set by manager/oracle
Manager  → [updatePPSManaged] → ManagedECDSAAppsOracle → forwardPPS → SV Aggregator
Manager  → [fulfillDepositRequests] → mints wrapper shares (at current PPS)
                                    ↕
Investor → [claimDeposit] → receives wrapper shares

Investor → [requestRedeem] → shares locked in wrapper
Manager  → [updatePPSManaged] → NAV can be changed BEFORE fulfillment
Manager  → [fulfillRedeemRequests] → burns shares, transfers SV shares to escrow
Investor → [claimRedeem] → receives SV shares (or unwrapped assets)
```

**Critical chokepoints:**
1. `updatePPSManaged` — no timelock, manager-only, direct NAV control
2. `fulfillRedeemRequests` — reads current PPS to calculate asset distribution
3. `requestDeposit` — must check allowlist before accepting funds
4. ManagedECDSAAppsOracle `isActivePPSOracle` — singleton, all SV strategies affected

---

## 2b. Additional Critical Finding: Request-Time PPS Snapshot Lock

The security research agent identified a **Critical** pattern specific to this architecture:

**Manager can sandwich NAV update between `requestRedeem` and `fulfillRedeemRequests`:**
1. Investor submits `requestRedeem(50 shares)` at PPS = $1.10
2. Manager calls `updatePPSManaged(wrapper, $0.80)` — lowers NAV
3. Manager calls `fulfillRedeemRequests([investor], [$40])` — investor expected $55 but receives $40

**Mitigation (recommended):** Snapshot PPS at `requestRedeem` time. Fulfillment uses `min(requestTimePPS, currentPPS)`:
```solidity
mapping(address controller => uint256 lockedPPS) public requestTimePPS;

function requestRedeem(uint256 shares, address controller, address owner) external {
    requestTimePPS[controller] = storedPPS; // snapshot at request time
    // ...
}

function fulfillRedeemRequests(address[] calldata controllers, uint256[] calldata assetsOut) external {
    for (uint256 i; i < controllers.length; i++) {
        uint256 ppsFloor = requestTimePPS[controllers[i]];
        uint256 minExpected = pendingRedeemRequest[controllers[i]] * ppsFloor / PRECISION;
        require(assetsOut[i] >= minExpected, "INSUFFICIENT_ASSETS_OUT");
        // ...
    }
}
```

This is the standard pattern used by Maple Finance and Centrifuge: NAV at request time is the floor for investor protection.

---

## 3. Recommended Defensive Patterns

### 3.1 First Depositor Protection
```solidity
// In ManagedVaultWrapper constructor/initialize:
uint256 constant DEAD_SHARES = 1000;
_mint(address(0xdead), DEAD_SHARES); // Lock dead shares permanently
```
Or use virtual assets offset (OZ ERC4626 pattern):
```solidity
function _decimalsOffset() internal pure override returns (uint8) { return 3; }
```

### 3.2 NAV Sandwich Mitigation
Add `minPPS` / `maxPPS` deviation bounds checked on `updatePPSManaged`:
```solidity
uint256 constant MAX_NAV_CHANGE_BPS = 1000; // 10% max single-update change
```
Store `lastPPS` and revert if `|newPPS - lastPPS| / lastPPS > MAX_NAV_CHANGE_BPS`.

Alternatively, add a **fulfill lock period**: once `fulfillRedeemRequests` is called, a short cooldown (e.g., 1 hour) before NAV can be changed. (This is a UX tradeoff.)

### 3.3 Oracle Singleton Protection
Add a **managed vs automated routing guard** in ManagedECDSAAppsOracle:
```solidity
function updatePPSManaged(address strategy, uint256 pps) external {
    if (!isManagedStrategy[strategy]) revert NOT_MANAGED_STRATEGY();
    // ... forward to aggregator
}

function updatePPS(UpdatePPSArgs calldata args) external override {
    // Validate none of args.strategies are managed strategies
    for (uint256 i; i < args.strategies.length; i++) {
        if (isManagedStrategy[args.strategies[i]]) revert USE_MANAGED_PATH();
    }
    super.updatePPS(args); // existing ECDSA validation
}
```

### 3.4 ReentrancyGuard on All State-Changing Functions
```solidity
function fulfillDepositRequests(...) external nonReentrant { ... }
function fulfillRedeemRequests(...) external nonReentrant { ... }
function requestDeposit(...) external nonReentrant { ... }
function requestRedeem(...) external nonReentrant { ... }
```

### 3.5 CEI Pattern in Fulfillment
```solidity
// Checks
require(pendingDeposit[controller] > 0);
uint256 assets = pendingDeposit[controller];

// Effects (update state BEFORE external calls)
pendingDeposit[controller] = 0;
claimableShares[controller] = sharesToMint;

// Interactions (external calls last)
_mint(address(escrow), sharesToMint);
```

---

## 4. Exploit Precedents

| Protocol | Exploit | Loss | Relevance to ManagedVaultWrapper |
|----------|---------|------|----------------------------------|
| **Lagoon Finance** (2024) | Audit: pending→claimable state transition bugs; race conditions in async redeem | $0 (caught in audit) | Direct: same ERC-7540 architecture; Nethermind found lifecycle inconsistencies |
| **Harvest Finance** (2020) | Flash loan inflated vault price, attacker deposited, price restored | $34M | Relevant: if external price of SV shares is manipulable, wrapper NAV inherits the risk |
| **Yearn yUSD** (2021) | Price manipulation of underlying vault before manager deposit | ~$11M | Relevant: manager-controlled NAV without bounds can be used similarly |
| **Maple Finance** (2022-2023) | Off-chain NAV manipulation; loans defaulted but NAV wasn't updated | $54M aggregate bad debt | Relevant: trusted off-chain NAV attestation is the core risk in ManagedVaultWrapper |

---

## 5. Key Invariants for Testing

```
// INVARIANT 1: Total wrapper shares ≤ claimable + pending
assert(totalSupply() == sum(claimableShares) + pendingRedeemTotal);

// INVARIANT 2: Total assets ≥ claimable assets owed
assert(totalAssets() >= sum(claimableAssets));

// INVARIANT 3: fulfillRedeemRequests can never distribute more assets than held
assert(assetsDistributed <= svSharesHeld * svSharePrice);

// INVARIANT 4: updatePPSManaged only affects managed strategies
assert(forall strategy: !isManagedStrategy[strategy] → ppsNotChangedByManagedPath);

// INVARIANT 5: Non-allowlisted address cannot increase pendingDeposit in gated vaults
assert(isGated && !allowlist[caller] → pendingDeposit[caller] == 0 after requestDeposit);
```

---

## 6. Comparable Protocol Designs

- **Lagoon Finance**: ERC-7540, async RWA vaults, off-chain NAV, Nethermind-audited 5x
- **Centrifuge Pools**: ERC-7540 on Substrate/EVM bridge, epoch-based settlement
- **Maple Finance**: Off-chain NAV attestation, trusted pool managers, permissioned depositors
- **Superform v1 Async Vaults**: `ISuperVaultStrategy.fulfillRedeemRequests` pattern (exists in codebase)
