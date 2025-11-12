# Superform v2 Periphery Security Analysis 

## SuperVault System Invariants

### Function-Level Properties

#### Deposit Operations (`deposit()` & `mint()`)

**Critical Invariants:**
- **PPS Validity**: `currentPPS > 0` always (reverts on `INVALID_PPS()`)
- **State Validation**: Strategy not paused, PPS not stale, PPS recently updated
- **Asset Transfer**: Exact `assets` amount transferred from `msg.sender` to strategy before minting
- **Fee Deduction**: Management fees deducted from gross assets, transferred to fee recipient
- **Share Calculation**: Net shares minted equal `floor(assetsNet * PRECISION / currentPPS)`
- **Zero Amount Protection**: Both functions revert on zero amounts
- **No HWM Update**: Deposits are PPS-neutral by design (no performance fee trigger)

**Mathematical Properties:**
```solidity
// For deposit(assets):
feeAssets = ceil(assets * managementFeeBps / BPS_PRECISION)
assetsNet = assets - feeAssets
shares = floor(assetsNet * PRECISION / currentPPS)

// For mint(shares):
assetsNet = ceil(shares * currentPPS / PRECISION)
assetsGross = ceil(assetsNet * BPS_PRECISION / (BPS_PRECISION - managementFeeBps))
// Fee = assetsGross - assetsNet
```

**Flow:**
1. Vault transfers assets from user to strategy
2. Strategy skims management fee (if configured)
3. Strategy calculates shares on net assets
4. Vault mints shares to receiver

#### Redeem Request Operations (`requestRedeem()`)

**State Transition Invariants:**
- **Balance Decrease**: `balanceOf(owner)` decreases by exactly `shares`
- **Escrow Increase**: `balanceOf(escrow)` increases by exactly `shares`
- **Pending Request**: `strategy.pendingRedeemRequest(controller)` increases by `shares`
- **Average PPS Update**: `strategy.averageRequestPPS(controller)` updated with weighted average
- **Supply Conservation**: `totalSupply()` remains unchanged (shares moved, not burned)
- **Controller Validation**: Currently enforced that `controller == owner` (auditor requirement)

#### Fulfillment Operations (`fulfillRedeemRequests()`)

**Fulfillment Invariants:**
- **Manager Only**: Only authorized managers can fulfill
- **State Validation**: Strategy not paused, PPS not stale, PPS recently updated
- **Sorted Controllers**: Controllers array must be strictly ascending (prevents duplicates)
- **Non-Zero Fulfillment**: Cannot fulfill for controllers with zero pending shares
- **Slippage Bounds**: `minAssets ≤ totalAssetsOut ≤ theoreticalAssets` for each controller
- **Share Burning**: Exact pending shares burned from escrow for all controllers
- **Asset Transfer**: Total assets transferred to escrow for user claims
- **State Updates**: `pendingRedeemRequest` cleared, `maxWithdraw` incremented, `averageWithdrawPrice` updated (weighted)

**Slippage Validation:**
```solidity
// Per-controller bounds check
slippageBps = user.redeemSlippageBps > 0 ? user.redeemSlippageBps : DEFAULT_REDEEM_SLIPPAGE_BPS
minAssets = computeMinNetOut(pendingShares, avgRequestPPS, slippageBps, PRECISION)
theoreticalAssets = pendingShares * currentPPS / PRECISION
require(totalAssetsOut >= minAssets && totalAssetsOut <= theoreticalAssets)
```

**Weighted Average Withdraw Price:**
```solidity
// Tracks historical fulfillment prices across multiple partial fulfillments
newAvgPrice = (oldMaxWithdraw * oldAvgPrice + pendingShares * newFulfillmentPrice) / newMaxWithdraw
```

#### Cancel Redeem Operations (`cancelRedeemRequest()` & `claimCancelRedeemRequest()`)

**Cancellation Flow:**
1. **Request Cancel**: User calls `cancelRedeemRequest()` → sets `pendingCancelRedeemRequest = true`
2. **Manager Fulfills**: Manager calls `fulfillCancelRedeemRequests()` → moves pending shares to `claimableCancelRedeemRequest`, clears `pendingRedeemRequest` and `averageRequestPPS`
3. **User Claims**: User calls `claimCancelRedeemRequest()` → escrow returns shares, clears `claimableCancelRedeemRequest`

**Reversal Invariants:**
- **Pending Flag**: `pendingCancelRedeemRequest` must be true during cancellation
- **Share Conservation**: Shares remain in escrow until claim
- **State Clearing**: All request state cleared after successful claim
- **Supply Conservation**: `totalSupply()` unchanged (shares never burned)

#### Withdraw/Redeem Claims (`withdraw()` & `redeem()`)

**Claim Invariants:**
- **Price Consistency**: Uses `strategy.getAverageWithdrawPrice(controller)` for share/asset conversion
- **Amount Limits**: Cannot exceed `maxWithdraw(controller)` or `maxRedeem(controller)`
- **Asset Transfer**: Assets extracted from escrow and sent to receiver
- **State Updates**: `maxWithdraw` decremented by claimed assets
- **No Share Burning**: Shares were already burned during fulfillment

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

### Per-User Redemption State

**SuperVaultState Tracking (per controller):**
```solidity
struct SuperVaultState {
    uint256 pendingRedeemRequest;        // Shares awaiting fulfillment
    uint256 averageRequestPPS;           // Weighted average PPS at request time(s)
    uint256 maxWithdraw;                 // Claimable assets after fulfillment
    uint256 averageWithdrawPrice;        // Weighted average fulfillment price
    uint16 redeemSlippageBps;            // User-configured slippage tolerance
    bool pendingCancelRedeemRequest;     // Cancellation in progress
    uint256 claimableCancelRedeemRequest; // Shares claimable from cancellation
}
```

**Request Lifecycle:**
1. **Request**: `requestRedeem()` → shares moved to escrow, `pendingRedeemRequest` incremented, `averageRequestPPS` updated (weighted)
2. **Fulfillment**: Manager executes hooks, calls `fulfillRedeemRequests()` → validates slippage bounds, updates `maxWithdraw` and `averageWithdrawPrice` (weighted), burns shares
3. **Claim**: User calls `withdraw()` or `redeem()` → transfers assets from escrow, decrements `maxWithdraw`

**Weighted Average PPS Protection:**
```solidity
// Multiple requests: weighted average prevents PPS manipulation
if (existingPending > 0) {
    avgPPS = (existingShares * oldPPS + newShares * currentPPS) / totalShares
}
// First request: baseline PPS for slippage protection
else {
    avgPPS = currentPPS
}
```

**Fulfillment Validation:**
```solidity
// Manager must fulfill within slippage bounds
minAssets = computeMinNetOut(shares, avgRequestPPS, slippageBps, PRECISION)
theoreticalAssets = shares * currentPPS / PRECISION
require(totalAssetsOut >= minAssets && totalAssetsOut <= theoreticalAssets)
```

### Fee Correctness Properties

**Management Fee (Entry Fee):**
```solidity
// Charged on deposits/mints as asset-side fee before share calculation
feeBps = feeConfig.managementFeeBps  // Max: 100% (10000 BPS)
feeAssets = ceil(assetsGross * feeBps / BPS_PRECISION)
assetsNet = assetsGross - feeAssets
sharesNet = floor(assetsNet * PRECISION / currentPPS)
```

**Performance Fee (PPS-Based High Water Mark):**
```solidity
// Global vault HWM tracking
vaultHwmPps  // Initialized to 1.0 (PRECISION), updated only on skim/fee config changes

// Skim calculation (only when currentPPS > vaultHwmPps)
ppsGrowth = currentPPS - vaultHwmPps
profit = floor(ppsGrowth * totalSupply / PRECISION)
fee = ceil(profit * performanceFeeBps / BPS_PRECISION)  // Max: 51% (5100 BPS)

// Fee split between Superform treasury and strategy recipient
sfFee = floor(fee * PERFORMANCE_FEE_SHARE / BPS_PRECISION)
recipientFee = fee - sfFee

// PPS reduction after fee extraction
ppsReduction = floor(fee * PRECISION / totalSupply)
newPPS = currentPPS - ppsReduction
vaultHwmPps = newPPS  // Update HWM to post-fee PPS
```

**Fee Invariants:**
- **Profit-Only Fees**: Performance fees only charged when `currentPPS > vaultHwmPps`
- **Fee Bounds**: Management ≤ 100%, Performance ≤ 51% (MAX_PERFORMANCE_FEE)
- **Recipient Validation**: Fee recipients must be non-zero when fees > 0
- **Rounding Direction**: Fees use ceiling (favor protocol), shares use floor (favor vault)
- **PPS Consistency**: HWM reset on fee config changes prevents incorrect calculations

**Skim Operation Security:**
- **12-Hour Post-Unpause Timelock**: `skimPerformanceFee()` blocked for `POST_UNPAUSE_SKIM_TIMELOCK` after unpause
- **Rationale**: Prevents manager exploitation of potentially aberrant PPS after catastrophic events
- **Mechanism**: Fee extraction reduces vault assets → lowers PPS → new HWM set to post-fee PPS
- **Decoupled Design**: Skim separated from PPS updates enables critical safety check
- **Defense-in-Depth**: Additional protection layer despite manager being considered trusted

**HWM Lifecycle:**
1. **Initialization**: Set to 1.0 (PRECISION) at deployment
2. **Normal Operation**: Only increases via skimPerformanceFee() to post-fee PPS
3. **Fee Config Change**: Reset to current PPS to avoid incorrect fee calculations with new structure
4. **Never Decreases**: Except during controlled skim operations

---

## ECDSAPPSOracle Security Properties

**Note:** For comprehensive security properties documentation, see `security_properties.md`

### Batch Processing & Validation

**Batch Constraints:**
```solidity
MAX_STRATEGIES = 300  // Maximum strategies per batch
```

**Batch-Level Validations:**
- **Sorted Strategies**: Input strategies must be strictly ascending (prevents nonce burning via duplicates)
- **Array Length Matching**: `strategies.length == proofsArray.length == ppss.length == timestamps.length`
- **Total Validator Check**: `SUPER_GOVERNOR.getValidatorsCount() > 0`
- **Quorum Snapshot**: Quorum fetched once at batch start (consistent for all strategies)

**Individual Strategy Processing:**
```solidity
// For each strategy in batch:
1. Validate proofs (quorum, ordering, registry)
2. On success: Mark as valid, emit PPSValidated
3. On failure: Mark as invalid, emit ProofValidationFailed, continue to next
4. Collect valid entries into resized arrays
5. Forward only valid entries to SuperVaultAggregator
```

**Graceful Degradation:**
- Invalid strategies skipped (not reverted) to allow batch to continue
- Partial batch success possible (some valid, some invalid)
- Nonce increment only for successfully forwarded strategies

### Signature Validation Invariants

**Quorum Requirements:**
```solidity
validSignatures >= SUPER_GOVERNOR.getPPSOracleQuorum()
validatorSet == proofs.length  // Per-strategy validator count
totalValidators == SUPER_GOVERNOR.getValidatorsCount()  // Network-wide
```

**Signature Ordering (Duplicate Prevention):**
- **Ascending Order**: Signer addresses must be strictly ascending (`signer > lastSigner`)
- **Reverts on Duplicate**: `signer <= lastSigner` triggers `INVALID_PROOF()`
- **Validator Registry**: Each signer must be registered via `SUPER_GOVERNOR.isValidator(signer)`
- **Per-Signature Check**: Every signature recovered and validated individually

**EIP-712 Message Integrity:**
```solidity
// UPDATE_PPS_TYPEHASH: "UpdatePPS(address strategy,uint256 pps,uint256 timestamp,uint256 strategyNonce)"
digest = _hashTypedDataV4(
    keccak256(
        abi.encodePacked(
            UPDATE_PPS_TYPEHASH,
            strategy,
            pps,
            timestamp,
            noncePerStrategy[strategy]  // Binds signature to current nonce
        )
    )
)
// Each validator signs: ECDSA(digest, privateKey)
// Recovery: signer = ECDSA.recover(digest, signature)
```

**Domain Separation:**
- EIP-712 domain includes: name (e.g., "SuperformOraclePPS"), version (e.g., "1"), chainId, verifyingContract
- Domain separator MUST match between on-chain and off-chain signing
- Domain parameters immutable after deployment

### Oracle State Management

**Per-Strategy Nonce Model (Property 1 & 2):**
```solidity
mapping(address strategy => uint256 nonce) public noncePerStrategy;

// Nonce increment logic:
try SuperVaultAggregator.forwardPPS(...) {
    // SUCCESS PATH: forwardPPS() returned normally (no revert)
    for (each valid strategy) {
        noncePerStrategy[strategy]++;  // Increment even for business logic rejections
    }
} catch {
    // FAILURE PATH: forwardPPS() reverted (contract error)
    // Nonces unchanged - retry possible with same signatures
}
```

**Nonce Increment Conditions (Property 2):**

*Increments (signature burned):*
1. ✓ Legitimate PPS updates accepted and stored
2. ✓ Business logic rejections using `return` or `continue` (rate limits, deviation, insufficient upkeep, pause, staleness)
3. ✓ Any scenario where `forwardPPS()` completes without revert

*Preserved (retry allowed):*
1. ✗ Contract reverts (system errors)
2. ✗ Out of gas conditions
3. ✗ Network/RPC failures
4. ✗ Any scenario where `forwardPPS()` reverts (catch blocks)

**Nonce Burning Rationale:**
- **Prevents Replay**: Invalid data cannot be retried with same signatures
- **Batch Continuity**: Failed strategy validation doesn't halt entire batch
- **Intentional Design**: Forces validators to re-sign after business logic changes (e.g., unpause, upkeep deposit)

**Active Oracle Validation:**
- **Authorization Check**: SuperVaultAggregator verifies `SUPER_GOVERNOR.isActivePPSOracle(oracle)` before accepting updates
- **Single Source**: Only one active oracle can submit updates at a time
- **Oracle Rotation**: Governance can change active oracle via SuperGovernor

---

## SuperBank & Hook Execution Security

### Hook Validation Properties (Bank.sol Pattern)

**Merkle Leaf Structure:**
```solidity
// Hook configuration validation via inspect method
hookArgs = ISuperHookInspector(hookAddress).inspect(hookData)  // Extract hook arguments
leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
require(MerkleProof.verify(proof, merkleRoot, leaf))
```

**Validation Requirements:**
- **inspect() Method**: Hooks must implement `ISuperHookInspector.inspect()` to extract configuration arguments
- **Configuration-Level**: Validates entire hook configuration (hookAddress + hookArgs from inspect)
- **Unified Pattern**: SuperBank and SuperVaultStrategy use identical validation logic via Bank.sol base contract
- **Single-Leaf Trees**: Empty proof array valid when `merkleRoot == leaf`
- **Non-Empty Arguments**: Hooks with empty inspect() results are rejected

**Hook Execution Flow (5 Phases):**
1. **Registration Check**: Verify hook is registered in SuperGovernor
2. **Configuration Validation**: Validate hook configuration via Merkle proof against governance-controlled root
3. **Context Setting**: `hook.setExecutionContext(address(this))`
4. **Build & Execute**: `executions = hook.build(prevHook, address(this), hookData)` → execute all steps with unlimited gas (hooks are trusted)
5. **Cleanup**: `hook.resetExecutionState(address(this))`

**Security Properties:**
- **Governance Control**: Merkle root managed by SuperGovernor with 7-day timelock
- **Hook Registration**: Only registered hooks can execute
- **Configuration Immutability**: Once validated against Merkle tree, hookArgs define allowed operations
- **Unlimited Gas**: Hooks execute with all available gas (acceptable since hooks are governance-approved)
- **Atomic Execution**: Any step failure reverts entire hook execution

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

**Share Custody (Request → Fulfill/Cancel):**
- **Approval Mechanism**: Vault approves escrow for share transfers
- **Escrow Transfer**: `escrowShares()` moves shares from user to escrow during `requestRedeem()`
- **Return Mechanism**: `returnShares()` returns shares to user during cancellation claim
- **Burn Authorization**: Only strategy (via vault) can trigger `burnShares()` from escrow during fulfillment

**Asset Custody (Fulfill → Claim):**
- **Asset Storage**: Escrow holds assets after fulfillment until user claims
- **Asset Transfer**: Strategy transfers fulfilled assets to escrow during `fulfillRedeemRequests()`
- **Asset Return**: `returnAssets()` sends assets to receiver during `withdraw()`/`redeem()` claim

**State Invariants:**
```solidity
// During redemption lifecycle:
escrowShareBalance >= Σ(pendingRedeemRequest + claimableCancelRedeemRequest)
escrowAssetBalance >= Σ(maxWithdraw)
```

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

**Malicious Hook Configurations:**
- **Merkle Root Veto**: Guardian can veto malicious hook roots (both global and strategy-specific)
- **Configuration Validation**: Entire hook configuration (hookAddress + hookArgs) must be in approved Merkle tree
- **inspect() Dependency**: Hook configuration extracted via `ISuperHookInspector.inspect()` - if inspect() fails, hook rejected
- **Empty hookArgs Rejection**: Hooks with no address parameters (empty inspect() result) are rejected

**Execution Context & Isolation:**
- **Context Binding**: `setExecutionContext(address(this))` binds hook to executor (SuperBank or SuperVaultStrategy)
- **State Isolation**: Each hook's state reset via `resetExecutionState(address(this))` after execution
- **Unlimited Gas**: Hooks execute with all available gas (acceptable since hooks are governance-approved and registered)
- **Atomic Failure**: Any execution step failure reverts entire hook (not just that step)

**Hook Ordering & Dependencies:**
- **Sequential Execution**: Hooks processed in array order, each can access previous hook via `prevHook` parameter
- **Dependency Chain**: Later hooks can read state from earlier hooks via `ISuperHookResult(prevHook).getOutAmount()`
- **Failure Propagation**: First hook failure halts entire hook sequence (atomic batch)

**SuperVaultStrategy-Specific Risks:**
- **Slippage Protection**: Manager must set `expectedAssetsOrSharesOut` to protect against honest errors
- **Bypass Risk**: Manager setting `expectedAssetsOrSharesOut = 0` bypasses slippage protection (off-chain enforcement via slashing)
- **Hook Validation**: Dual Merkle proof system (global root + strategy root) with strategy-level leaf banning

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
5. PPS must always be > 0
6. totalSupply = Σ user balances + balanceOf(escrow) 
7. requestRedeem() & cancelRedeem() should never alter the supply of SuperVault tokens (calculated by summing user share balances)
8. redeeming maxRedeem should never revert
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

## Security Assumptions

### Trust Model

**Manager Trust (Extensive)**:
- **Core Responsibilities**: Fulfillment timing, totalAssetsOut calculations, fee updates, yield source whitelisting, emergency operations, solvency maintenance
- **MEV Protection**: Discretionary censorship power to delay MEV-positive redemptions until yield contribution
- **Staleness Configuration**: Trusted to set meaningful `maxStaleness` thresholds per strategy
- **Off-Chain Accountability**: Managers are KYC'd and trusted. Enforcement via off-chain mechanisms (legal agreements, reputation, business relationships) for misbehavior (fulfillment manipulation, PPS threshold abuse, front-running)
- **Mitigation Layers**: Guardian veto power, 7-day timelocks, SuperGovernor emergency takeover, 24-hour upkeep withdrawal timelock
- **No On-Chain Slashing**: V2 does not include on-chain staking/slashing system. Relies on trusted manager model with real-world enforcement. On-chain slashing planned for V2.1 when democratizing manager access.

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

---

## Upkeep Payment Security

### Per-Strategy Upkeep System

**Design:** SuperVaultAggregator uses **per-strategy upkeep** tracking to prevent unauthorized upkeep drain attacks.

**Implementation:**
```solidity
// Storage: Per-strategy upkeep balance (isolated)
mapping(address strategy => uint256 upkeep) private _strategyUpkeepBalance;

// Deposit: Anyone can deposit to any strategy
function depositUpkeep(address strategy, uint256 amount) external validStrategy(strategy);

// Withdraw: ONLY mainManager can withdraw from their strategy
function withdrawUpkeep(address strategy, uint256 amount) external validStrategy(strategy) {
    require(msg.sender == _strategyData[strategy].mainManager);  // CRITICAL
}

// PPS Updates: Deduct from strategy balance, not manager balance
function _forwardPPS(PPSUpdateData memory args) internal {
    uint256 strategyUpkeepBalance = _strategyUpkeepBalance[args.strategy];
    if (strategyUpkeepBalance < args.upkeepCost) {
        // Pause only this strategy, no cross-strategy impact
        _strategyData[args.strategy].isPaused = true;
    }
}
```

### Security Properties

**Complete Isolation:**
- Each strategy has independent upkeep balance
- Attacker-created strategies start with $0 upkeep
- PPS updates deduct from specific strategy balance only
- No cross-strategy contamination possible

**Access Control:**
- `depositUpkeep()`: Permissionless (anyone can deposit to any strategy)
- `withdrawUpkeep()`: **Restricted to mainManager only** (not `isAnyManager()`)
- Critical security control prevents secondary managers from draining funds


### Edge Cases

**Secondary Manager Scenarios:**
1. **Attacker is secondary, tries to withdraw:** Transaction reverts (`UNAUTHORIZED_UPDATE_AUTHORITY`)
2. **Attacker adds victim as secondary:** Victim has no upkeep in attacker's strategy, can't withdraw
3. **Manager takeover (7-day timelock):** Limited to single strategy, victim can withdraw during timelock

**Acknowledged Behaviors:**
- Managers can be added to strategies without consent (manager association griefing)
- **No fund theft possible** unless victim explicitly deposits upkeep into that strategy
- Strategy upkeep inheritance follows strategy ownership (like TVL)

### Audit Focus

**Critical Invariants:**
```solidity
1. withdrawUpkeep() MUST check mainManager (NOT isAnyManager())
2. _strategyUpkeepBalance[strategyA] cannot affect _strategyUpkeepBalance[strategyB]
3. Insufficient upkeep pauses only that specific strategy
4. Upkeep deduction occurs BEFORE storing new PPS (fail-safe)