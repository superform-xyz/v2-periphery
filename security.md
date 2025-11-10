# Superform v2 Periphery Security Analysis 

## SuperVault System Invariants

### Function-Level Properties

#### Deposit Operations (`deposit()` & `mint()`)

**Critical Invariants:**
- **PPS Validity**: `currentPPS > 0` always (reverts on `INVALID_PPS()`)
- **Share Calculation**: Net shares minted must equal `floor(assetsNet * PRECISION / currentPPS)`
- **Fee Deduction**: Management fees are deducted from gross assets before share calculation
- **Asset Transfer**: Exact `assets` amount transferred from `msg.sender` to strategy before minting
- **Zero Amount Protection**: Both functions revert on zero amounts

**Mathematical Properties:**
```solidity
// For deposit():
shares = floor((assets - managementFee) * PRECISION / currentPPS)

// For mint():
assetsGross = ceil(shares * currentPPS / PRECISION * BPS_PRECISION / (BPS_PRECISION - feeBps))
```

#### Redeem Request Operations (`requestRedeem()`)

**State Transition Invariants:**
- **Balance Decrease**: `balanceOf(owner)` decreases by exactly `shares`
- **Escrow Increase**: `balanceOf(escrow)` increases by exactly `shares`
- **Pending Request**: `strategy.pendingRedeemRequest(controller)` increases by `shares`
- **Average PPS Update**: `strategy.averageRequestPPS(controller)` updated with weighted average
- **Supply Conservation**: `totalSupply()` remains unchanged (shares moved, not burned)
- **Controller Validation**: Currently enforced that `controller == owner` (auditor requirement)

#### Cancel Redeem Operations (`cancelRedeem()`)

**Reversal Invariants:**
- **Pending Clearing**: `strategy.pendingRedeemRequest(controller)` set to 0
- **Average PPS Reset**: `strategy.averageRequestPPS(controller)` cleared
- **Share Return**: Escrow returns exact shares to controller
- **Supply Conservation**: `totalSupply()` unchanged throughout operation

#### Withdraw/Redeem Claims (`withdraw()` & `redeem()`)

**Claim Invariants:**
- **Price Consistency**: Uses `strategy.getAverageWithdrawPrice(controller)` for conversion
- **Amount Limits**: Cannot exceed `maxWithdraw(controller)` or `maxRedeem(controller)`
- **Share Burning**: Shares burned from escrow by exact fulfilled amount
- **Asset Distribution**: Assets sent directly to receiver from strategy

### System-Level Properties

#### Supply Accounting
```solidity
totalSupply() == Σ(balanceOf(user)) + balanceOf(escrow)
```

#### Share Movement Constraints
- **Burn Source**: Burns only occur from escrow contract
- **Burn Amount**: Burned shares exactly equal fulfilled redemption amounts
- **Asset Location**: Assets exist in strategy or have been transferred to receivers/fee recipients

#### Pause State Compliance
```solidity
if (aggregator.isStrategyPaused(strategy)) {
    maxDeposit(user) == 0
    maxMint(user) == 0
}
```

#### Escrow Sanity Checks
```solidity
balanceOf(escrow) >= Σ(controller.pendingRedeemRequest)
```

#### Average Withdraw Price Coherence
```solidity
if (maxWithdraw(C) == 0) then getAverageWithdrawPrice(C) == 0
if (getAverageWithdrawPrice(C) > 0) then maxRedeem(C) == floor(maxWithdraw(C) * PRECISION / avgWithdrawPrice)
```

#### Preview Function Behavior
- **Intentional Limitation**: `previewWithdraw()` and `previewRedeem()` revert by design
- **No Preview Parity**: Invariant tests should not expect preview parity for async withdrawal functions

### Accumulator Movement on Transfer

**Transfer Invariants (between external users):**
```solidity
// When transferring between users (not involving escrow/mint/burn):
from.accumulatorShares -= min(transferAmount, from.accumulatorShares)
to.accumulatorShares += same_amount
// Proportional cost basis movement
costBasisMoved = floor(transferAmount * from.accumulatorCostBasis / from.accumulatorShares)
from.accumulatorCostBasis -= costBasisMoved
to.accumulatorCostBasis += costBasisMoved

// Global conservation:
Σ(user.accumulatorShares) unchanged by pure transfers
Σ(user.accumulatorCostBasis) unchanged by pure transfers
```

### Cost Basis on Fulfill

**Fulfillment Accounting:**
```solidity
// When fulfilling requestedShares for controller C:
historicalCost = floor(requestedShares * C.accumulatorCostBasis / C.accumulatorShares)
C.accumulatorShares -= requestedShares
C.accumulatorCostBasis -= historicalCost
// Must not underflow: requestedShares <= C.accumulatorShares
```

### Fee Correctness Properties

**Fee Calculation Invariants:**
- **Profit-Only Fees**: Performance fees only charged on positive returns
- **Fee Bounds**: All fees respect configured bounds (0 ≤ fee ≤ BPS_PRECISION)
- **Recipient Validation**: Fee recipients must be non-zero addresses when fees > 0
- **Rounding Direction**: Fee calculations use ceiling for protocol benefit

**Skim Operation Security:**
- **12-Hour Post-Unpause Constraint**: `skim()` cannot execute within 12 hours after unpause
- **Rationale**: Prevents manager exploitation of potentially aberrant PPS after catastrophic events
- **Design**: Decoupling skim from PPS updates enables this critical safety check
- **Defense-in-Depth**: Additional protection layer despite manager being considered trusted

---

## ECDSAPPSOracle Security Properties

**Note:** For comprehensive security properties documentation, see `security_properties.md`

### Signature Validation Invariants

**Quorum Requirements:**
```solidity
validSignatures >= SUPER_GOVERNOR.getPPSOracleQuorum()
validatorSet == proofs.length
totalValidators == SUPER_GOVERNOR.getValidators().length
```

**Signature Ordering:**
- **Ascending Order**: Signer addresses must be in strictly ascending order
- **No Duplicates**: `signer > lastSigner` enforced for each proof
- **Validator Registry**: Each signer must be registered in `SUPER_GOVERNOR.isValidator(signer)`

**Message Integrity (EIP-712):**
```solidity
// UPDATE_PPS_TYPEHASH: "UpdatePPS(address strategy,uint256 pps,uint256 timestamp,uint256 strategyNonce)"
digest = _hashTypedDataV4(
    keccak256(
        abi.encodePacked(
            UPDATE_PPS_TYPEHASH,
            strategy,
            pps,
            timestamp,
            noncePerStrategy[strategy]  // Per-strategy nonce
        )
    )
)
```

### Oracle State Management

**Per-Strategy Nonce Model:**
- **Independent Nonces**: Each strategy maintains its own nonce counter
- **Increment Timing**: Nonce increments ONLY after successful `forwardPPS()` (try block succeeds)
- **Replay Protection**: Same nonce cannot be used twice for the same strategy
- **Retry Capability**: On external failures (reverts), nonce remains unchanged allowing retry with same signatures

**Nonce Burning Strategy:**
- **Business Logic Rejections**: When `forwardPPS()` returns normally (via `return` or `continue`), nonces increment
- **Intentional Design**: Burns signatures for fundamentally invalid data (prevents replay of invalid signatures)
- **Batch Protection**: Prevents DoS of entire batch when one strategy has invalid data

**Active Oracle Validation:**
- **Authorization Check**: Only active PPS oracle can submit updates
- **Single Source**: `SUPER_GOVERNOR.isActivePPSOracle(address(this))` must be true

---

## SuperBank & Hook Execution Security

### Hook Validation Properties

**Merkle Proof Requirements:**
```solidity
// For each execution step with target != hookAddress:
targetLeaf = keccak256(bytes.concat(keccak256(abi.encodePacked(executionStep.target))))
MerkleProof.verify(merkleProof, merkleRoot, targetLeaf) == true
```

**Hook Execution Flow:**
1. **Context Setting**: `hook.setExecutionContext(address(this))`
2. **Build Phase**: `executions = hook.build(prevHook, address(this), hookData)`
3. **Validation**: Each target verified against Merkle root
4. **Execution**: Calls executed with proper value and calldata
5. **Cleanup**: `hook.resetExecutionState(address(this))`

### Revenue Distribution Invariants

**Distribution Calculations:**
```solidity
revenueShare = SUPER_GOVERNOR.getFee(FeeType.REVENUE_SHARE)
supAmount = upAmount * revenueShare / BPS_MAX
treasuryAmount = upAmount - supAmount
```

**Balance Requirements:**
- **Sufficient Balance**: `UP.balanceOf(SuperBank) >= upAmount` before distribution
- **Exact Transfers**: Sum of transfers equals input amount
- **Non-Zero Recipients**: sUP and treasury addresses must be valid

---

## SuperGovernor Access Control & Governance

### Role-Based Security

**Role Hierarchy:**
- **DEFAULT_ADMIN_ROLE**: Can manage all other roles
- **SUPER_GOVERNOR_ROLE**: Critical system parameters
- **GOVERNOR_ROLE**: Daily operational parameters
- **BANK_MANAGER_ROLE**: Revenue distribution and hook execution
- **GUARDIAN_ROLE**: Emergency veto powers

### Timelock Mechanisms

**Critical Parameter Changes:**
```solidity
// SuperGovernor & Manager Changes
TIMELOCK = 7 days                    // Governance operations
_MANAGER_CHANGE_TIMELOCK = 7 days    // Manager changes
WITHDRAW_STAKE_TIMELOCK = 7 days     // Stake withdrawals

// Hook & Strategy Operations
_hooksRootUpdateTimelock = 15 minutes  // Hook root updates (configurable)
_MAX_UNPAUSE_TIMELOCK = 1 day         // Maximum unpause delay

// Fee & Emergency
FEE_CONFIG_UPDATE_TIMELOCK = 7 days   // Performance fee changes
EMERGENCY_WITHDRAWAL_TIMELOCK = 7 days // Emergency mode activation

// PPS Staleness (per-strategy configurable, max = getMinStaleness from SuperGovernor)
```

**Timelock Invariants:**
- **Proposal Period**: Changes must be proposed before effective time
- **Effective Time**: `block.timestamp >= effectiveTime` required for execution
- **Single Use**: Proposals consumed upon execution
- **Configurable vs Constant**: Some timelocks are governance-configurable (e.g., `_hooksRootUpdateTimelock`), others are immutable constants

### Registry Integrity

**Address Registry:**
- **Non-Zero Validation**: All registered addresses must be non-zero
- **Key Uniqueness**: Each key maps to exactly one address
- **Update Authorization**: Only authorized roles can update registry

---

## Cross-Contract Integration Properties

### SuperVault ↔ Strategy Integration

**State Synchronization:**
- **PPS Consistency**: Vault uses strategy's stored PPS for all calculations
- **Pause Propagation**: Strategy pause state affects vault deposit limits
- **Fee Configuration**: Strategy fee config used for vault preview functions

### Strategy ↔ Aggregator Integration

**PPS Update Flow:**
1. **Oracle Validation**: ECDSAPPSOracle validates signatures, quorum, and nonce binding
2. **Aggregator Forwarding**: Validated PPS forwarded to SuperVaultAggregator.forwardPPS()
3. **Multi-Layer Validation**: 
   - forwardPPS(): Future timestamp, pause state, staleness checks
   - _forwardPPS(): Monotonicity, post-unpause, rate limit, deviation, M/N, upkeep balance
4. **Strategy Update**: Aggregator updates strategy's stored PPS (if all checks pass)
5. **Nonce Increment**: Oracle increments nonce only after successful update
6. **Event Emission**: PPS update events emitted at each stage

**Validation Layers (14 Security Properties):**
- See `security_properties.md` for complete documentation
- Properties enforce defense-in-depth through multiple overlapping checks
- Graceful degradation using `return` (not `revert`) for business logic rejections

### Escrow ↔ Vault Integration

**Share Custody:**
- **Approval Mechanism**: Vault approves escrow for share transfers
- **Custody Transfer**: `escrowShares()` moves shares from user to escrow
- **Return Mechanism**: `returnShares()` moves shares back to user
- **Burn Authorization**: Only strategy can trigger share burns from escrow

---

## Potential Attack Vectors & Edge Cases

### PPS Manipulation Risks

**Rapid PPS Changes:**
- **Deposit Timing**: Adversarial PPS changes before deposit/mint operations
- **Redeem Timing**: PPS manipulation between requestRedeem and fulfill
- **Slippage Guards**: Ensure slippage protection mechanisms are enforced

**First Depositor Attack:**
- **Initial PPS**: Verify PPS == PRECISION when totalSupply == 0
- **Tiny PPS Risk**: Aggregator starting with tiny PPS enables outsized share minting
- **Detection**: Monitor for abnormal share/asset ratios on first deposits

**Stale PPS Replay Attacks:**
- **Timestamp Monotonicity**: Prevents out-of-order updates
- **Post-Unpause Validation**: C1-RE_ANCHOR prevents replay of pre-pause signatures
- **Absolute Staleness**: maxStaleness check rejects old timestamps
- **Defense-in-Depth**: Multiple overlapping protections prevent stale PPS acceptance

### Hook Execution Risks

**Malicious Hooks:**
- **Merkle Root Veto**: Guardian can veto malicious hook roots
- **Target Validation**: All execution targets must be in approved Merkle tree
- **Execution Context**: Hooks cannot escape their execution context

**Hook Ordering:**
- **Dependency Chain**: Hooks may depend on previous hook state
- **State Isolation**: Each hook's state properly reset after execution
- **Failure Handling**: Hook execution failures cause entire transaction revert

### Oracle & Validator Risks

**Validator Collusion:**
- **Quorum Requirements**: Minimum quorum prevents small validator sets
- **Signature Ordering**: Prevents duplicate validator signatures
- **Registry Validation**: Only registered validators can sign
- **M/N Threshold**: Configurable per-strategy participation requirements

**Oracle Downtime & Stale Data:**
- **Liveness Model**: Test negative cases (proper reversions) rather than always-success invariants
- **Fallback Mechanisms**: Strategy can pause via manager or auto-pause on anomalies
- **Staleness Enforcement**: Absolute time check (maxStaleness) rejects old timestamps
- **Post-Unpause Protection**: C1-RE_ANCHOR check prevents replay of pre-pause signatures
- **Rate Limiting**: Minimum update interval (minUpdateInterval) prevents spam

**Frontrunning Risks:**
- **Nonce Burning Attacks**: Attackers can burn nonces by triggering business logic rejections
- **Economic Cost**: Most attacks require privileged access or have medium economic cost
- **Mitigation**: Validator pre-flight validation, economic disincentives
- **Risk Level**: MEDIUM-LOW overall, safe for production
- **See**: `../.claude/doc/frontrunning_attack_analysis.md` for detailed analysis



---

## Critical Audit Focus Areas

### 1. Rounding & Precision Invariants

**Implementation Analysis:**
- All share/asset conversions follow consistent rounding rules
- User-favorable operations: floor (deposit, withdraw previews)
- Protocol-favorable operations: ceil (fees, over-claim prevention)

**Known Edge Case:**
- Scenario: Very small dust redemptions (< 10 wei range)
- Outcome: User may lose 1-2 wei due to conservative rounding
- Rationale: Prevents vault insolvency; acceptable tradeoff
- Severity: Not a security issue; documented expected behavior

**Critical Invariants to Verify:**
```solidity
// These must NEVER be violated:
1. Vault never loses assets due to rounding (direction check)
2. Sum of fulfilled claims ≤ totalAssetsOut set by manager
3. Escrow balance ≥ sum of pending requests
4. No user can extract more than their fair share
```

### 2. PPS Oracle DoS & Frontrunning Vectors

**Attack Surface Analysis:**

**A. Nonce Burning Attacks:**
- **Mechanism**: Attacker triggers business logic rejection to burn signature nonces
- **Entry Points**: Pause strategy, manipulate staleness, trigger deviation checks
- **Cost**: Most attacks require manager access or significant economic cost
- **Mitigation**: Intentional design - prevents replay of invalid signatures
- **Validators**: Pre-flight simulation prevents wasted submissions

**B. Batch DoS Attacks:**
- **Mechanism**: Manipulate per-strategy state to fail batch updates
- **Defense**: Graceful degradation using `return` instead of `revert`
- **Outcome**: Invalid strategies skip, batch continues
- **Trade-off**: Nonce burning accepted to prevent batch halting

**C. Validator Frontrunning:**
- **Mechanism**: Frontrun oracle submission to change strategy state
- **Examples**: Pause strategy, update PPS manually, exhaust upkeep
- **Economic Cost**: Medium - requires capital or privileged access
- **Mitigation**: Economic disincentives (forfeited upkeep), pre-flight validation

**D. Staleness Manipulation:**
- **Mechanism**: Delay fulfillment/hooks to make next PPS update stale
- **Constraints**: Manager-controlled maxStaleness provides liveness flexibility
- **Trade-off**: Liveness vs safety (manager trusted to configure appropriately)

**Validator Network Assumptions (Critical Context):**
```
1. Validators simulate transactions before submission (only submit if passing)
2. No updates before minimum interval (enforced on-chain)
3. No future timestamps (validators measure recent past)
4. No updates for paused strategies (checked in aggregator)
5. Economic incentives: follow rules to earn upkeep, violations forfeit payment
```

**14-Layer Defense-in-Depth:**
See `security_properties.md` for complete analysis of:
- Signature validation (quorum, ordering, registry)
- Timestamp checks (future, staleness, monotonicity)
- State validation (pause, re-anchor, upkeep)
- Economic limits (deviation, M/N participation, rate limiting)

**Risk Assessment:**
- **Overall**: MEDIUM-LOW
- **Production Ready**: Yes, with documented assumptions
- **Required Monitoring**: Off-chain validator behavior, nonce advancement patterns

**Audit Priorities:**
1. Verify all 14 validation layers function correctly
2. Check for bypass conditions in oracle → aggregator → strategy flow
3. Test pause/unpause boundary conditions for signature replay
4. Validate staleness configuration prevents both DoS and stale data acceptance
5. Review economic game theory of validator/manager incentives
6. Examine nonce management for race conditions or griefing vectors

---

## Testing Recommendations

### Invariant Testing Focus Areas

1. **ERC4626 Compliance**: Test deviations from standard due to ERC7540 integration
2. **Supply Conservation**: Verify total supply accounting across all operations
3. **Fee Calculation**: Test fee bounds and calculation accuracy
4. **Access Control**: Verify role-based restrictions are enforced
5. **Timelock Compliance**: Test premature execution prevention
6. **Oracle Quorum**: Test insufficient signature scenarios
7. **Hook Validation**: Test Merkle proof verification edge cases
8. **Nonce Management**: Test nonce increment timing and replay protection
9. **PPS Validation**: Test all 14 security properties (see [security_properties.md](security_properties.md))
10. **Pause State**: Test pause rejection independent of payment settings
11. **Batch Processing**: Test graceful rejection (return vs revert) for batch continuity

### Negative Testing Scenarios

**Paused State Testing:**
- **Deposit Blocking**: Verify deposits fail when strategy paused
- **PPS Update Blocking**: Verify PPS updates rejected when paused (PPSUpdateRejectedStrategyPaused event)
- **Withdrawal Continuation**: Verify withdrawals continue when paused
- **Hook Execution**: Test hook execution during various pause states
- **Payment Independence**: Verify pause check works regardless of payment settings

**Extreme Market Conditions:**
- **High Volatility**: Test rapid PPS changes and slippage protection
- **Zero Balances**: Test behavior with zero assets/shares
- **Maximum Values**: Test behavior at uint256 limits

### Property-Based Testing

**Mathematical Properties:**
- **Conversion Consistency**: `convertToShares(convertToAssets(x)) ≈ x`
- **Fee Calculation**: Verify fee deduction accuracy
- **Accumulator Movement**: Test pro-rata accumulator transfers

**State Transition Properties:**
- **Redeem Flow**: Request → Cancel/Fulfill state transitions
- **Share Movement**: Mint → Transfer → Burn lifecycle
- **PPS Updates**: Oracle (validation + nonce) → Aggregator (multi-layer checks) → Strategy (storage)
- **Nonce Lifecycle**: Validate → Forward → Success/Revert → Increment/Preserve

---

## Security Assumptions

### Trust Model

**Manager Trust (Extensive)**:
- **Core Responsibilities**: Fulfillment timing, totalAssetsOut calculations, fee updates, yield source whitelisting, emergency operations, solvency maintenance
- **MEV Protection**: Discretionary censorship power to delay MEV-positive redemptions until yield contribution
- **Staleness Configuration**: Trusted to set meaningful `maxStaleness` thresholds per strategy
- **Off-Chain Accountability**: Can be slashed for misbehavior (fulfillment manipulation, PPS threshold abuse, front-running)
- **Mitigation Layers**: Guardian veto power, 7-day timelocks, SuperGovernor takeover, economic security via stake deposits

**User Trust & Loss Socialization**:
- **Accepted Behavior**: Rebalance losses are socialized across depositors by design. Redeem losses are attributed to redeemers when fulfillment occurs
- **Protection Mechanism**: User-configurable slippage limits (default: 1% on redemptions) guard against excessive PPS variations
- **Expected Behavior**: Users should not abuse slippage parameter changes between request and fulfillment (off-chain enforcement)

**Validator Network Model**:
- **Untrusted for Liveness**: No guarantee of timely PPS updates; validator availability is best-effort
- **Honest Majority**: Assumes quorum of validators act honestly for PPS validation
- **Economic Incentives**: Validators follow rules to earn upkeep; violations forfeit rewards
- **Oracle Pre-Flight**: Off-chain simulation ensures transactions succeed before submission
- **Assumptions**: No updates before minimum interval, no future timestamps, no updates for paused strategies

**Oracle Dependencies**:
- **PPS Data Source**: External off-chain validator network calculates accurate PPS from strategy state
- **Signature Validation**: Validators sign off-chain; ECDSAPPSOracle validates on-chain
- **Staleness Defense**: Multi-layered checks (absolute time via `maxStaleness` + post-unpause re-anchoring)
- **Manipulation Resistance**: Multiple validators + quorum + deviation thresholds + M/N participation
- **Nonce Security**: Per-strategy nonces prevent cross-strategy and replay attacks

### Economic & Fee Design

**Performance Fee Skimming**:
- **Decoupled Design**: Skim operations separate from PPS updates for gas efficiency (hourly updates, less frequent skims)
- **Security Constraint**: 12-hour post-unpause cooldown before skim operations allowed
- **Rationale**: Prevents manager exploitation of aberrant PPS during recovery events

**Bid-Ask Pricing Model**:
- **Deposit (Ask)**: Users deposit at current `SV_PPS`
- **Redemption (Bid)**: Manager sets fulfillment price in range `[user_min_slippage, SV_PPS]`, absorbing withdrawal losses
- **ExpectedAmountOut**: Slippage protection guards honest managers from input errors during hook execution

### External Dependencies

**Token Compatibility (In-Scope)**:
- **Standard ERC20 Only**: Fee-on-transfer, ERC777, and rebasing tokens are explicitly OUT OF SCOPE
- **Yield Sources (Day 1)**: ERC4626 vaults (Morpho Markets) + PT tokens (Pendle)

**ERC4626/ERC7540 Compliance**:
- **Standard Deviation**: Async redemptions via ERC7540; pause state doesn't block 7540 claims
- **Preview Functions**: `previewWithdraw` and `previewRedeem` intentionally revert (async model)
- **Rounding Direction**: Floor for users, ceiling for protocol where applicable

**Cross-Chain Assumptions**:
- **Bridge Security**: VaultBank operations assume secure cross-chain messaging
- **Finality**: Cross-chain state finality and message ordering
- **Replay Protection**: Nonce-based mechanisms prevent cross-chain replay attacks
