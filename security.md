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
TIMELOCK = 7 days // For most governance changes
_hooksRootUpdateTimelock = 15 minutes // For hook root updates
```

**Timelock Invariants:**
- **Proposal Period**: Changes must be proposed before effective time
- **Effective Time**: `block.timestamp >= effectiveTime` required for execution
- **Single Use**: Proposals consumed upon execution

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

### Dust and Rounding Edge Cases

**Tolerance Constants:**
- **TOLERANCE_CONSTANT**: 10 wei tolerance in `_handleClaimRedeem`
- **Rounding Behavior**: Ensure consistent rounding direction (floor for users, ceil for protocol)
- **Dust Prevention**: Prevent over-claims through tolerance mechanisms

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

**Strategist Trust:**
- **Primary Strategist**: Has significant control over vault strategies
- **Hook Selection**: Can choose hooks from approved global set
- **Fee Management**: Can propose fee changes within bounds
- **Mitigation**: Guardian veto, timelock delays, SuperGovernor takeover

**Validator Trust:**
- **Honest Majority**: Assumes majority of validators act honestly
- **Signature Security**: Private keys properly secured
- **Availability**: Sufficient validators available for quorum

**Oracle Dependencies:**
- **PPS Accuracy**: External aggregator provides accurate PPS data
- **Validator Signatures**: Validators sign off-chain, oracle validates on-chain
- **Staleness Prevention**: Multi-layered staleness checks (absolute time + post-unpause)
- **Manipulation Resistance**: Multiple validators + quorum requirements + deviation thresholds
- **Nonce Security**: Per-strategy nonces prevent cross-strategy replay attacks

### External Dependencies

**ERC4626 Compliance:**
- **Standard Deviation**: SuperVault deviates from standard ERC4626 for async redeems by using ERC7540 for redemptions. Also, pause state doesn't affect claims in 7540 operations
- **Preview Functions**: `previewWithdraw` and `previewRedeem` intentionally unimplemented
- **Rounding Direction**: Follows ERC4626 rounding conventions where applicable

**Cross-Chain Assumptions:**
- **Bridge Security**: VaultBank cross-chain operations assume secure bridging
- **Finality**: Cross-chain state finality assumptions
- **Replay Protection**: Nonce-based replay attack prevention
