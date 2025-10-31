# Performance Fee Refactor PRD

## Overview

This PRD outlines the migration from per-user cost basis tracking to a global High Water Mark (HWM) system for performance fee collection in SuperVaultStrategy. Performance fees will be collected via periodic `skimPerformanceFee()` calls instead of being calculated and deducted during redemption operations.

## Goals

1. **Simplify Redemption Flow**: Remove all fee calculations from redemption preview and fulfillment functions
2. **Centralize Fee Collection**: Fees collected via `skimPerformanceFee()` based on global HWM
3. **Improve Cash Flow**: Managers can call skim anytime after cooldown interval
4. **Reduce Gas Costs**: Eliminate per-user fee calculations during redemptions

## Current State

### Fee Calculation Points
- `previewExactRedeem()`: Calculates performance fees based on user's cost basis
- `previewPerformanceFee()`: Standalone fee preview function
- `_processExactFulfillmentBatch()`: Calculates and deducts fees during redemption fulfillment
- `fulfillRedeemRequests()`: Transfers calculated fees to treasury and recipient

### Per-User Tracking
- `SuperVaultState.accumulatorShares`: User's share balance for cost basis calculation
- `SuperVaultState.accumulatorCostBasis`: User's total cost basis
- `moveAccumulatorOnTransfer()`: Moves cost basis on token transfers

## Target State

### Fee Collection Model
- **Global HWM**: `vaultTotalCostBasis` tracks total cost basis across all deposits
- **Skim Function**: `skimPerformanceFee()` calculates fees based on global profit (assets - HWM)
- **No Redemption Fees**: All redemption operations return assets without fee deduction

### Simplified State
- Remove `accumulatorShares` and `accumulatorCostBasis` from `SuperVaultState`
- Keep redemption-specific fields: `pendingRedeemRequest`, `averageRequestPPS`, `maxWithdraw`, etc.

## Changes Required

### 1. State Changes

#### Add Global HWM Tracking
```solidity
uint256 public vaultTotalCostBasis;  // Total embedded cost (sum of all deposits)
```

#### Update SuperVaultState Struct
```solidity
struct SuperVaultState {
    // KEEP (redeem flow):
    uint256 pendingRedeemRequest;
    uint256 averageRequestPPS;
    uint256 maxWithdraw;
    uint256 averageWithdrawPrice;
    uint16 redeemSlippageBps;
    bool pendingCancelRedeemRequest;
    uint256 claimableCancelRedeemRequest;

    // DELETE:
    // uint256 accumulatorShares;
    // uint256 accumulatorCostBasis;
}
```

### 2. Deposit Operations

#### Update `handleOperations4626Deposit`
```solidity
function handleOperations4626Deposit(...) external returns (uint256 sharesNet) {
    // ... existing code ...
    
    // After calculating sharesNet from assetsNet:
    vaultTotalCostBasis += assetsNet;  // ADD: Track deposit cost basis
    
    // REMOVE:
    // state.accumulatorShares += sharesNet;
    // state.accumulatorCostBasis += assetsNet;
    
    emit VaultCostBasisUpdated(vaultTotalCostBasis);  // ADD: Optional event
    emit DepositHandled(controller, assetsNet, sharesNet);
    return sharesNet;
}
```

#### Update `handleOperations4626Mint`
```solidity
function handleOperations4626Mint(...) external {
    // ... existing code ...
    
    // After fee transfer:
    vaultTotalCostBasis += assetsNet;  // ADD: Track deposit cost basis
    
    // REMOVE:
    // state.accumulatorShares += sharesNet;
    // state.accumulatorCostBasis += assetsNet;
    
    emit VaultCostBasisUpdated(vaultTotalCostBasis);  // ADD: Optional event
    emit DepositHandled(controller, assetsNet, sharesNet);
}
```

### 3. Fee Collection Function

#### Add `skimPerformanceFee()`
```solidity
function skimPerformanceFee() external {
    _isManager(msg.sender);
    
    uint256 curTotalAssets = ISuperVault(_vault).totalAssets();
    uint256 totalSupplyLocal = ISuperVault(_vault).totalSupply();
    
    // HWM calculation (simplifies to vaultTotalCostBasis when supply > 0)
    uint256 hwm = totalSupplyLocal == 0 
        ? 0 
        : vaultTotalCostBasis;
    
    // Calculate profit above HWM
    uint256 profit = curTotalAssets > hwm ? curTotalAssets - hwm : 0;
    
    if (profit == 0) return;  // No profit, no fee
    
    uint256 fee = profit.mulDiv(feeConfig.performanceFeeBps, BPS_PRECISION);
    
    if (fee > 0) {
        // Split fees
        uint256 sfFee = fee.mulDiv(
            superGovernor.getFee(FeeType.SUPER_VAULT_PERFORMANCE_FEE), 
            BPS_PRECISION
        );
        
        // Transfer fees
        _safeTokenTransfer(
            address(_asset), 
            superGovernor.getAddress(superGovernor.TREASURY()), 
            sfFee
        );
        _safeTokenTransfer(
            address(_asset), 
            feeConfig.recipient, 
            fee - sfFee
        );
        
        emit PerformanceFeeSkimmed(fee, sfFee);
    }
    
    // Reset HWM to post-skim assets
    vaultTotalCostBasis = curTotalAssets - fee;
    
    emit VaultCostBasisUpdated(vaultTotalCostBasis);
}
```

### 4. Simplify Redemption Preview

#### Update `previewExactRedeem`
```solidity
function previewExactRedeem(address controller)
    external
    view
    returns (uint256 shares, uint256 theoGross, uint256 totalFee, uint256 theoNet, uint256 minNet)
{
    SuperVaultState memory state = superVaultState[controller];
    shares = state.pendingRedeemRequest;
    
    if (shares == 0) return (0, 0, 0, 0, 0);
    
    uint256 pps = getStoredPPS();
    theoGross = shares.mulDiv(pps, PRECISION, Math.Rounding.Floor);
    
    // REMOVE: All fee calculation logic
    // REMOVE: Historical assets calculation
    // REMOVE: SuperVaultAccountingLib.calculatePerformanceFee call
    
    // Fees are collected via skimPerformanceFee(), not during redemption
    totalFee = 0;
    theoNet = theoGross;
    
    // Slippage check uses 0 fees
    uint16 slippageBps = state.redeemSlippageBps > 0 
        ? state.redeemSlippageBps 
        : DEFAULT_REDEEM_SLIPPAGE_BPS;
    
    minNet = SuperVaultAccountingLib.computeMinNetOut(
        shares, 
        state.averageRequestPPS, 
        slippageBps, 
        0,  // No fees
        PRECISION
    );
    
    return (shares, theoGross, totalFee, theoNet, minNet);
}
```

### 5. Simplify Redemption Fulfillment

#### Update `_processExactFulfillmentBatch`
```solidity
function _processExactFulfillmentBatch(
    address controller,
    uint256 totalAssetsOut,
    uint256 currentPPS
)
    internal
    returns (uint256 processedShares, uint256 superformFee, uint256 recipientFee, uint256 netAssetsOut)
{
    SuperVaultState storage state = superVaultState[controller];
    processedShares = state.pendingRedeemRequest;
    
    if (processedShares == 0) return (0, 0, 0, 0);
    
    // REMOVE: All fee calculation logic
    // REMOVE: calculateCostBasis call
    // REMOVE: calculatePerformanceFee call
    // REMOVE: Historical assets calculation
    
    // Fees are collected via skimPerformanceFee(), not during redemption
    superformFee = 0;
    recipientFee = 0;
    netAssetsOut = totalAssetsOut;  // All assets go to user (no fee deduction)
    
    // KEEP: Slippage validation
    uint256 slippageBps = state.redeemSlippageBps > 0 
        ? state.redeemSlippageBps 
        : DEFAULT_REDEEM_SLIPPAGE_BPS;
    
    uint256 theoGross = processedShares.mulDiv(currentPPS, PRECISION, Math.Rounding.Floor);
    
    // Slippage check uses 0 fees
    uint256 minNetOut = SuperVaultAccountingLib.computeMinNetOut(
        processedShares, 
        state.averageRequestPPS, 
        slippageBps, 
        0,  // No fees
        PRECISION
    );
    
    // Bounds check: assetsOut must be between minNetOut and theoGross
    if (netAssetsOut < minNetOut || netAssetsOut > theoGross) {
        revert BOUNDS_EXCEEDED(minNetOut, theoGross, netAssetsOut);
    }
    
    // KEEP: Update average withdraw price (use theoGross)
    state.averageWithdrawPrice = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
        state.maxWithdraw,
        state.averageWithdrawPrice,
        processedShares,
        theoGross,  // Use theoretical gross (no fees)
        PRECISION
    );
    
    // KEEP: Reset state
    state.pendingRedeemRequest = 0;
    state.maxWithdraw += netAssetsOut;
    state.averageRequestPPS = 0;
    state.pendingCancelRedeemRequest = false;
    state.claimableCancelRedeemRequest = 0;
    
    // REMOVE: accumulatorShares and accumulatorCostBasis from event
    emit RedeemClaimable(
        controller,
        netAssetsOut,
        processedShares,
        state.averageWithdrawPrice,
        0,  // accumulatorShares = 0
        0   // accumulatorCostBasis = 0
    );
    
    return (processedShares, superformFee, recipientFee, netAssetsOut);
}
```

#### Update `fulfillRedeemRequests`
```solidity
function fulfillRedeemRequests(
    address[] calldata controllers,
    uint256[] calldata totalAssetsOut
)
    external
    payable
    nonReentrant
{
    _isManager(msg.sender);
    _validateStrategyState(_getSuperVaultAggregator());
    
    uint256 len = controllers.length;
    if (len == 0 || totalAssetsOut.length != len) revert INVALID_ARRAY_LENGTH();
    
    FulfillRedeemVars memory vars;
    vars.currentPPS = getStoredPPS();
    if (vars.currentPPS == 0) revert INVALID_PPS();
    
    // Validate controllers are sorted and unique
    for (uint256 i = 1; i < len; ++i) {
        if (controllers[i] <= controllers[i - 1]) revert CONTROLLERS_NOT_SORTED_UNIQUE();
    }
    
    // Pre-validate total shares
    for (uint256 i; i < len; ++i) {
        vars.totalRequestedShares += superVaultState[controllers[i]].pendingRedeemRequest;
    }
    
    // Process each controller
    for (uint256 i; i < len; ++i) {
        (uint256 shares, uint256 superformFee, uint256 recipientFee, uint256 netAssetsOut) =
            _processExactFulfillmentBatch(controllers[i], totalAssetsOut[i], vars.currentPPS);
        
        vars.processedShares += shares;
        vars.totalSuperformFee += superformFee;      // Will be 0
        vars.totalRecipientFee += recipientFee;     // Will be 0
        vars.totalNetAssetsOut += netAssetsOut;
    }
    
    if (vars.processedShares != vars.totalRequestedShares) revert INVALID_REDEEM_FILL();
    
    // Balance check (no fees expected)
    vars.strategyBalance = _getTokenBalance(address(_asset), address(this));
    if (vars.strategyBalance < vars.totalNetAssetsOut) {  // REMOVED: fee checks
        revert INSUFFICIENT_LIQUIDITY();
    }
    
    // Burn shares
    ISuperVault(_vault).burnShares(vars.processedShares);
    
    // REMOVE: Fee transfers (fees collected via skimPerformanceFee)

    // Transfer net assets to escrow
    if (vars.totalNetAssetsOut > 0) {
        _asset.safeTransfer(ISuperVault(_vault).escrow(), vars.totalNetAssetsOut);
    }
    
    emit RedeemRequestsFulfilled(controllers, vars.processedShares, vars.currentPPS);
}
```

### 6. Delete Functions

#### Remove `moveAccumulatorOnTransfer`
```solidity
// DELETE ENTIRE FUNCTION
// function moveAccumulatorOnTransfer(address from, address to, uint256 shares) external { ... }
```

#### Remove `previewPerformanceFee`
```solidity
// DELETE ENTIRE FUNCTION
// function previewPerformanceFee(address controller, uint256 sharesToRedeem) external view returns (...) { ... }
```

### 7. Update Library Functions

#### Update `SuperVaultAccountingLib.sol`

**DELETE:**
- `calculateCostBasis(...)` - No longer needed
- `calculatePerformanceFee(...)` - Fees collected via skim

**KEEP:**
- `computeMinNetOut(...)` - Update to remove fee parameter
- `calculateAverageWithdrawPrice(...)` - Still needed for redemption tracking
- `validateRedemptionBounds(...)` - If used elsewhere

### 8. Add View Function

#### Add `vaultUnrealizedProfit`
```solidity
function vaultUnrealizedProfit() external view returns (uint256) {
    uint256 totalAssetsLocal = ISuperVault(_vault).totalAssets();
    return totalAssetsLocal > vaultTotalCostBasis 
        ? totalAssetsLocal - vaultTotalCostBasis 
        : 0;
}
```

## Implementation Checklist

### State & Storage
- [ ] Add `vaultTotalCostBasis` state variable
- [ ] Remove `accumulatorShares` and `accumulatorCostBasis` from `SuperVaultState`
- [ ] Add `VaultCostBasisUpdated` event (optional)

### Deposit Functions
- [ ] Update `handleOperations4626Deposit()` to increment `vaultTotalCostBasis`
- [ ] Update `handleOperations4626Mint()` to increment `vaultTotalCostBasis`
- [ ] Remove accumulator updates from both functions

### Fee Collection
- [ ] Implement `skimPerformanceFee()` function
- [ ] Add cooldown mechanism (if interval-based)

### Redemption Functions
- [ ] Simplify `previewExactRedeem()` - remove all fee calculations and change returns
- [ ] Simplify `_processExactFulfillmentBatch()` - remove fee calculations and change returns
- [ ] Update `fulfillRedeemRequests()` - remove fee transfers
- [ ] Update `previewExactRedeemBatch()`

### Cleanup
- [ ] Delete `moveAccumulatorOnTransfer()` function
- [ ] Delete `previewPerformanceFee()` function
- [ ] Remove `calculateCostBasis()` from `SuperVaultAccountingLib`
- [ ] Remove `calculatePerformanceFee()` from `SuperVaultAccountingLib`
- [ ] Update `computeMinNetOut()` signature if needed (accept 0 fees)

### View Functions
- [ ] Add `vaultUnrealizedProfit()` view function
- [ ] Update events to remove accumulator fields

### Testing (don't do this for reference for now)
- [ ] Test deposit operations update `vaultTotalCostBasis` correctly
- [ ] Test `skimPerformanceFee()` calculates fees correctly
- [ ] Test `skimPerformanceFee()` resets HWM correctly
- [ ] Test redemption previews show 0 fees
- [ ] Test redemption fulfillment transfers all assets (no fee deduction)
- [ ] Test slippage validation still works with 0 fees
- [ ] Test cooldown mechanism (if implemented)

## Edge Cases & Considerations

1. **Initial State**: `vaultTotalCostBasis` should initialize to initial TVL or 0
2. **Zero Supply**: Handle case where `totalSupply == 0` in HWM calculation
3. **Negative Profit**: Ensure fees only collected when `profit > 0`
4. **Slippage Bounds**: Verify slippage calculations work correctly with 0 fees
5. **Gas Optimization**: Removing per-user calculations significantly reduces gas costs
6. **Migration**: Existing contracts may need migration path for accumulator state
