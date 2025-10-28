# Proposal 2: non atomic fulfillRedeemRequests with netAssetsOut

### 1. Refactor fulfillRedeemRequests

```solidity
/// @inheritdoc ISuperVaultStrategy
/// @dev Replaces old fulfillRedeemRequests: Exact net assets per controller (post-fee).
/// @dev PRE: Off-chain sort/unique controllers. Call executeHooks(sum(netAssetsOut)) first.
/// @dev Social: netAssetsOut[i] = theoreticalNet[i] (full). Selective: netAssetsOut[i] < theo.
/// @param controllers Ordered/unique controllers with pending requests.
/// @param netAssetsOut Exact POST-FEE assets to assign each controller[i].
function fulfillRedeemRequests(
    address[] calldata controllers,
    uint256[] calldata netAssetsOut
) external payable nonReentrant {
    _isManager(msg.sender);
    if (_isPaused()) revert STRATEGY_PAUSED();
    if (_isPPSStale()) revert STALE_PPS();

    uint256 len = controllers.length;
    if (len == 0 || netAssetsOut.length != len) revert INVALID_ARRAY_LENGTH();

    uint256 currentPPS = getStoredPPS();
    if (currentPPS == 0) revert INVALID_PPS();
    ISuperVaultAggregator aggregator = _getSuperVaultAggregator();
    _verifyPPSUpdated(aggregator);

    uint256 lastPPSUpdate = aggregator.getLastUpdateTimestamp(address(this));
    if (block.timestamp - lastPPSUpdate > ppsStalenessThreshold) revert STALE_PPS();

    // Pre-validate total shares (exact burn)
    uint256 totalRequestedShares;
    for (uint256 i; i < len; ++i) {
        totalRequestedShares += superVaultState[controllers[i]].pendingRedeemRequest;
    }

    uint256 processedShares;
    for (uint256 i; i < len; ++i) {
        processedShares += _processExactFulfillment(controllers[i], netAssetsOut[i], currentPPS);
    }

    if (processedShares != totalRequestedShares) revert INVALID_REDEEM_FILL();

    ISuperVault(_vault).burnShares(processedShares);
    emit RedeemRequestsFulfilled(controllers, processedShares, currentPPS);
}
```

### 2. Adapt _processLiquidityRedeemFulfillment into _processExactFulfillment

```solidity
function _processExactFulfillment(
    address controller,
    uint256 netAssetsOut,
    uint256 currentPPS
) internal returns (uint256 processedShares) {
    SuperVaultState storage state = superVaultState[controller];
    LiquidityRedeemVars memory vars;  // Reuse existing struct
    vars.requestedShares = state.pendingRedeemRequest;
    if (vars.requestedShares == 0) return 0;

    // 1. EXACT SAME: Cost basis update
    (vars.historicalAssets, state.accumulatorShares, state.accumulatorCostBasis) =
        SuperVaultAccountingLib.calculateCostBasis(
            state.accumulatorShares,
            state.accumulatorCostBasis,
            vars.requestedShares
        );

    // 2. EXACT SAME: Theoretical @ currentPPS + Fees (profit on FULL theo)
    vars.claimableAssetsWithFees = vars.requestedShares.mulDiv(currentPPS, PRECISION, Math.Rounding.Floor);
    (vars.totalFee, vars.superformFee, vars.recipientFee) =
        SuperVaultAccountingLib.calculatePerformanceFee(
            vars.claimableAssetsWithFees,
            vars.historicalAssets,
            feeConfig.performanceFeeBps,
            superGovernor.getFee(FeeType.SUPER_VAULT_PERFORMANCE_FEE)
        );

    // Transfer fees FIRST (EXACT SAME)
    if (vars.superformFee > 0) {
        _safeTokenTransfer(address(_asset), superGovernor.getAddress(superGovernor.TREASURY()), vars.superformFee);
        emit FeePaid(superGovernor.getAddress(superGovernor.TREASURY()), vars.superformFee, feeConfig.performanceFeeBps);
    }
    if (vars.recipientFee > 0) {
        _safeTokenTransfer(address(_asset), feeConfig.recipient, vars.recipientFee);
        emit FeePaid(feeConfig.recipient, vars.recipientFee, feeConfig.performanceFeeBps);
    }

    uint256 theoNetOut = vars.claimableAssetsWithFees - vars.totalFee;

    // 3. STRICT BOUNDS (NEW)
    vars.slippageBps = state.redeemSlippageBps > 0 ? state.redeemSlippageBps : DEFAULT_REDEEM_SLIPPAGE_BPS;
    **uint256 minNetOut = SuperVaultAccountingLib.computeMinNetOut(
        vars.requestedShares,
        state.averageRequestPPS,
        vars.slippageBps,
        vars.totalFee,
        PRECISION
    );**
    **if (netAssetsOut < minNetOut || netAssetsOut > theoNetOut) revert BOUNDS_EXCEEDED();**

    // 4. LIQUIDITY CHECK (PER-USER, POST ALL PRIOR FEES)
    **uint256 strategyBalance = _getTokenBalance(address(_asset), address(this));**
    **if (strategyBalance < netAssetsOut) revert INSUFFICIENT_LIQUIDITY();**

    // 5. EXACT ASSIGN + SAME UPDATES
    vars.claimableAssets = netAssetsOut;
    if (vars.requestedShares > 0) {
        state.averageWithdrawPrice = SuperVaultAccountingLib.calculateAverageWithdrawPrice(
            state.maxWithdraw,
            state.averageWithdrawPrice,
            vars.requestedShares,
            vars.claimableAssetsWithFees,  // Use theo for avg price
            PRECISION
        );
    }

    // Reset state (SAME)
    state.pendingRedeemRequest = 0;
    state.maxWithdraw += vars.claimableAssets;
    state.averageRequestPPS = 0;
    state.pendingCancelRedeemRequest = false;
    state.claimableCancelRedeemRequest = 0;

    // Escrow transfer (SAME, but exact netOut)
    _onRedeemClaimable(
        controller,
        vars.claimableAssets,
        vars.requestedShares,
        state.averageWithdrawPrice,
        state.accumulatorShares,
        state.accumulatorCostBasis
    );

    processedShares = vars.requestedShares;
}
```

### 3. Lib changes

```solidity
/// @notice Compute MIN net claimable (slippage floor, post-fee). For exact mode.
/// @return minNetOut User's minimum acceptable post-fee assets.
function computeMinNetOut(
    uint256 requestedShares,
    uint256 averageRequestPPS,
    uint16 slippageBps,
    uint256 totalFee,
    uint256 precision
) internal pure returns (uint256 minNetOut) {
    uint256 expectedGross = requestedShares.mulDiv(averageRequestPPS, precision, Math.Rounding.Floor);
    uint256 minGrossOut = expectedGross.mulDiv(BPS_PRECISION - slippageBps, BPS_PRECISION, Math.Rounding.Floor);
    minNetOut = minGrossOut > totalFee ? minGrossOut - totalFee : 0;
}

// remove calculateClaimableAssets
```

### 4. Optional preview function

```solidity
/// @dev Off-chain: theoNet[i] - loss → netOut[i]
function previewExactRedeem(address controller) external view returns (
    uint256 shares, uint256 theoGross, uint256 totalFee, uint256 theoNet, uint256 minNet
) {
    SuperVaultState memory state = superVaultState[controller];
    shares = state.pendingRedeemRequest;
    uint256 pps = getStoredPPS();
    theoGross = shares.mulDiv(pps, PRECISION, Math.Rounding.Floor);
    // ... compute fee via lib
    theoNet = theoGross - totalFee;
    minNet = SuperVaultAccountingLib.computeMinNetOut(shares, state.averageRequestPPS, state.redeemSlippageBps, totalFee, PRECISION);
}
```