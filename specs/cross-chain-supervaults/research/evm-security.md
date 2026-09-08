# EVM Security Research - Cross-Chain SuperVaults

## 1. Relevant Vulnerability Patterns

### 1.1 Oracle Manipulation for Cross-Chain AUM
**Risk:** The `CrossChainAUMOracle` is the primary trust boundary. If compromised or manipulated:
- Inflated AUM -> inflated PPS -> new depositors overpay -> attacker withdraws at true value
- Deflated AUM -> deflated PPS -> existing depositors get diluted -> attacker deposits cheap

**Superform context:** Existing `ECDSAPPSOracle` has M-of-N quorum validation. The AUM oracle must use the same or stronger quorum.

### 1.2 False Position Registration (Phantom Positions)
**Risk:** Registering non-existent cross-chain positions inflates reported AUM.
- Malicious/compromised registrar registers fake $10M position on chain B
- PPS inflates, new depositors pay inflated price
- Position never existed, vault is insolvent

**Mitigation:** Three-layer validation (role + Merkle proof + oracle confirmation)

### 1.3 Position Deregistration Race Condition
**Risk:** When assets return from remote chain, brief double-counting occurs.
- Assets arrive on hub chain AND position still registered = double AUM
- AUM oracle sees both, PPS spikes temporarily

**Mitigation:** Atomic position deregistration when bridge callback confirms return

### 1.4 AUM Update Front-Running (MEV)
**Risk:** If `CrossChainAUMOracle.updateAUM()` transaction is visible in mempool:
- Deposit before AUM increase -> get shares at old (lower) PPS
- Redeem before AUM decrease -> lock in higher PPS

**Superform context:** Existing `_validateStrategyState()` (line 1102-1106) checks pause/stale/expiration but lacks AUM-specific freshness check

### 1.5 Position Cap Bypass Vectors
- **Multi-tx splitting:** Multiple small bridge calls, each below cap, cumulative exceeds
- **Flash loan amplification:** Inflate hub deposits -> pass cap on inflated denominator -> repay
- **Direct bridge call:** Strategy smart account calls bridge outside hook system, bypassing cap enforcement in `executeHooks()`
- **Race condition:** Cap checked before Across/deBridge hook fires, subsequent hooks compound allocation

### 1.6 Stale Cross-Chain Position Data
- **Liquidation lag:** Lending position on chain B liquidated, registry still shows pre-liquidation value
- **Yield desynchronization:** Cross-chain yield accrues continuously but oracle updates periodically
- **Reorg-induced inconsistency:** Chain B reorg reverses deposit, registry still reflects it

### 1.7 Bridge Finality Assumptions
- **Assets-in-transit gap:** Between `depositV3Now()` and bridge fill, assets are neither on source nor confirmed on destination. Double-counting risk
- **Fill failure:** Across relayers may not fill within `fillDeadlineOffset`, deBridge orders may not be fulfilled
- **Optimistic chain reorg:** L2s with 7-day withdrawal periods -- positions appear confirmed but are within challenge window

## 2. Exploit Precedents

### 2.1 Wormhole Bridge ($320M, Feb 2022)
- **Mechanism:** Forged guardian signatures via deprecated Solana system program
- **Relevance:** CrossChainAUMOracle and CrossChainPositionRegistry must validate signatures from authenticated sources. Existing ECDSA oracle uses `SUPER_GOVERNOR.isValidator(signer)` -- same pattern required for position registration
- **Lesson:** Never trust upstream message authenticity without independent verification

### 2.2 Ronin Bridge ($625M, Mar 2022)
- **Mechanism:** 5 of 9 validator keys compromised via social engineering (Lazarus Group)
- **Relevance:** Single-key registrar role is insufficient. ECDSAPPSOracle uses M-of-N quorum -- same must apply to position registration
- **Lesson:** Single-key roles for critical cross-chain operations are a critical vulnerability

### 2.3 Euler Finance ($197M, Mar 2023)
- **Mechanism:** Donation attack - donated assets to pool without minting shares, exploited inflated conversion rate
- **Relevance:** SuperVault uses oracle-driven PPS (`_getStoredPPS()`) not balance-derived, which is a key defense. But if CrossChainAUMOracle feeds balance-derived data, donation attacks on remote yield sources could inflate reported AUM
- **Lesson:** Never derive pricing from on-chain balances that can be externally manipulated

### 2.4 Multichain/Anyswap ($130M+)
- **Mechanism:** CEO's private keys controlled MPC infrastructure. Compromised/seized keys drained bridge contracts
- **Relevance:** Registrar role must not be a single EOA or centralized MPC. Consider requiring on-chain proof of bridge finality
- **Lesson:** Centralized key management masquerading as MPC is a single point of failure

### 2.5 Term Finance ($8.5M, 2025)
- **Mechanism:** Vault accounting misconfiguration, drained via deposit/withdrawal sequence manipulation
- **Relevance:** Complex multi-step operations (deposit -> bridge -> register -> update AUM -> compute PPS) create large state machines with exploitable intermediate states

## 3. Attack Surface Map

### Position Registration
| Attack Vector | Impact | Severity |
|---|---|---|
| False position registration | AUM inflation, PPS manipulation | Critical |
| Stale position data (fail to deregister) | Double-counting, inflated PPS | High |
| Replay of old registrations | Phantom position creation | High |
| Register before bridge confirms | Assets-in-transit counted twice | High |
| Registrar key compromise | Total position data control | Critical |

### AUM Oracle
| Attack Vector | Impact | Severity |
|---|---|---|
| Front-run AUM update to deposit cheaply | Unfair share minting | High |
| Stale AUM leading to wrong PPS | Incorrect pricing for all users | High |
| Selective chain inclusion | Bias PPS up/down at will | Critical |
| AUM update without deviation check | Sudden large PPS changes | Medium |

### Cap Enforcement
| Attack Vector | Impact | Severity |
|---|---|---|
| Multi-tx splitting | Cumulative cap bypass | High |
| Flash loan to inflate denominator | Cap passes on inflated AUM | High |
| Direct bridge call bypassing hooks | Complete cap bypass | Critical |
| Stale AUM in cap calculation | Cap check uses wrong denominator | High |

### PPS Computation
| Attack Vector | Impact | Severity |
|---|---|---|
| Cross-chain data inconsistency window | PPS arbitrage between updates | High |
| Liquidation lag on remote chain | Overstated PPS, depositors diluted | High |
| Donation to remote yield source | Inflate AUM via balance manipulation | Medium |

### Bridge Finality
| Attack Vector | Impact | Severity |
|---|---|---|
| Assets reported but not delivered | PPS inflation, phantom positions | High |
| L2 reorg reverses bridge deposit | Assets evaporate, registry stale | High |
| Bridge relayer censorship | Stuck assets, AUM discrepancy | Medium |

## 4. Recommended Security Patterns

### 4.1 Timelocks on Position Registration
> **SUPERSEDED**: the adopted design has no `proposePosition`/`confirmPosition` timelock pair.
> Confirmation is implicit - Pending -> Active on first inclusion in a quorum-signed AUM
> report (`registry.syncPositionFromReport`), with `POSITION_CONFIRMATION_TIMEOUT` (2h)
> invalidating unconfirmed positions. See technical-spec.md Phase 1/2.

Two-phase registration mirroring existing patterns:
- `proposePosition()` with POSITION_REGISTRATION_DELAY (30 min suggested)
- `confirmPosition()` after timelock expires
- Mirrors hooks root update timelock (15 min) and parameter change timelock (3 days)

### 4.2 Multi-Oracle Quorum for Cross-Chain Data
- Reuse ECDSAPPSOracle quorum model with EIP-712 typed data
- Separate typehash: `UPDATE_AUM_TYPEHASH`
- Same validator infrastructure, potentially different quorum threshold
- Ascending unique signer validation (prevents duplicates)

### 4.3 Position Cap Enforcement at Hook Level
> **SUPERSEDED**: enforcement is atomic inside `CapGuardedBridgeHook` (cap check + bridge
> send in ONE hook - the only authorized bridging leaf); no `executeHooks()` /
> `_processSingleHookExecution()` / SuperVaultStrategy changes. See technical-spec.md
> Integration Point 2. The per-batch concern is addressed because each bridge send
> individually re-checks caps against current registry exposure.

- Must be enforced **per-batch** (entire `executeHooks()` call), not per-hook
- Use post-execution cross-chain allocation (including all bridge hooks in batch)
- Must extend `_processSingleHookExecution()` (line 753) to block calls to CrossChainPositionRegistry and CrossChainAUMOracle in addition to aggregator

### 4.4 Deviation Checks on AUM Updates
- Reuse Property 10 pattern from PPS oracle (line 1277-1290)
- Relative deviation: `abs(new - current) / current`
- Auto-pause or require governance intervention on threshold breach

### 4.5 AUM Freshness Gate on Deposits
- Block deposits/rebalances when AUM data is stale
- Integrate with existing `_canAcceptDeposits()` check

### 4.6 Emergency Cross-Chain Pause
- Independent of per-strategy pause
- Specific `crossChainPaused` flag
- Blocks bridge hook execution without affecting hub-chain operations

### 4.7 Bridge Confirmation Tracking
- Track in-flight bridge operations (pending vs confirmed)
- Never register positions at bridge initiation, only after confirmed delivery
- Verify bridge fill events (Across) or order fulfillment (deBridge)

## 5. Testing Recommendations

### 5.1 Invariant Tests
- Sum of registered positions <= Total AUM from oracle
- No position exists without corresponding confirmed bridge operation
- Cross-chain allocation percentage never exceeds cap
- PPS * totalSupply ~= totalAUM (within tolerance)

### 5.2 Fuzz Tests
- Cap enforcement boundary conditions with varied hub balance, cross-chain allocation, bridge amounts, cap BPS
- Cumulative cap enforcement across sequential bridge operations

### 5.3 Scenario Tests
- Stale AUM blocks deposits
- Position liquidation on remote chain reflects in PPS
- Bridge fill timeout does not register phantom positions
- Concurrent AUM and PPS update ordering invariants

### 5.4 Reentrancy Tests
- Bridge callback reentrancy into SuperVault.deposit()
- Position registration during deposit execution
- Hook execution cannot call aggregator, registry, or AUM oracle

### 5.5 Attack Simulation Tests
- Flash loan + deposit + bridge cap bypass
- Registrar role transfer cleans pending positions
- Double-count during deregistration race condition

## 6. Critical Findings Summary

> **NOTE**: items 2 and 6 are SUPERSEDED by the adopted design (see notes in 4.1/4.3):
> cap enforcement is atomic in CapGuardedBridgeHook (no executeHooks changes), and there is
> no registration timelock (implicit confirmation via signed reports + Pending timeout).

### Must Implement Before Launch
1. Multi-oracle quorum for position registration (not single key)
2. Per-batch atomic cap enforcement in executeHooks()
3. Bridge confirmation tracking (not initiation-based)
4. AUM deviation checks matching PPS oracle pattern
5. Flash loan resistance in cap checks (oracle-reported AUM, not balances)

### Must Implement Before Mainnet
6. Timelocks on position registration
7. AUM freshness gate blocking deposits when stale
8. Independent cross-chain pause mechanism
9. Double-counting prevention during bridge returns

### Implement for Robustness
10. Minimum deposit amounts
11. Comprehensive invariant test suite
12. Monitoring/alerting for AUM-PPS divergence
