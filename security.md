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

**Message Integrity:**
```solidity
structHash = keccak256(abi.encodePacked(
    UPDATE_PPS_TYPEHASH,
    strategy,
    pps,
    ppsStdev,
    validatorSet,
    totalValidators,
    timestamp,
    nonce
))
digest = _hashTypedDataV4(structHash)
```

### Oracle State Management

**Nonce Progression:**
- **Monotonic Increase**: Nonce increments on each successful update
- **Replay Protection**: Same nonce cannot be used twice

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
1. **Oracle Validation**: ECDSAPPSOracle validates signatures and quorum
2. **Aggregator Forwarding**: Validated PPS forwarded to aggregator
3. **Strategy Update**: Aggregator updates strategy's stored PPS
4. **Event Emission**: PPS update events emitted at each stage

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

**Oracle Downtime:**
- **Liveness Model**: Test negative cases (proper reversions) rather than always-success invariants
- **Fallback Mechanisms**: Strategy can pause/veto via aggregator
- **Stale Data**: Implement staleness checks for PPS updates

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

### Negative Testing Scenarios

**Paused State Testing:**
- **Deposit Blocking**: Verify deposits fail when strategy paused
- **Withdrawal Continuation**: Verify withdrawals continue when paused
- **Hook Execution**: Test hook execution during various pause states

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
- **PPS Updates**: Oracle → Aggregator → Strategy propagation

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
- **Staleness**: PPS updates occur within reasonable time windows
- **Manipulation Resistance**: Multiple validators prevent single-point manipulation

### External Dependencies

**ERC4626 Compliance:**
- **Standard Deviation**: SuperVault deviates from standard ERC4626 for async redeems by using ERC7540 for redemptions
- **Preview Functions**: `previewWithdraw` and `previewRedeem` intentionally unimplemented
- **Rounding Direction**: Follows ERC4626 rounding conventions where applicable

**Cross-Chain Assumptions:**
- **Bridge Security**: VaultBank cross-chain operations assume secure bridging
- **Finality**: Cross-chain state finality assumptions
- **Replay Protection**: Nonce-based replay attack prevention
