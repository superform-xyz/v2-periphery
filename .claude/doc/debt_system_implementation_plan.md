# Debt System Implementation Plan for SuperVault Slashing

## Executive Summary

This document provides a comprehensive implementation plan for introducing a debt system to prevent frontrunning exploits in the SuperVault slashing mechanism. The current system allows managers to frontrun slashing calls by withdrawing their stake, either completely or partially, which undermines the economic security model.

**CRITICAL DESIGN PRINCIPLE**: Debt is ALWAYS tracked and checked on the MAIN manager of a strategy, NOT on secondary managers. This is because the economic security of the vault comes from the main manager's stake. Secondary managers are operational helpers without their own economic security requirements.

---

## 1. Current System Analysis

### 1.1 Existing Slashing Implementation

**Location**: `src/SuperVault/SuperVaultAggregator.sol:485-515`

**Current Flow**:
1. `slashStake(address manager, uint256 amount)` is called by `SUPER_GOVERNOR` (via `SuperGovernor.sol:675-680`)
2. Validates that `_managerStakeBalance[manager] >= amount`
3. If insufficient, reverts with `INSUFFICIENT_STAKE_BALANCE()`
4. Reduces stake balance: `_managerStakeBalance[manager] -= amount`
5. Clears pending withdrawal requests
6. Transfers slashed tokens to `SuperBank`

**Vulnerability**:
- Manager can frontrun the slashing transaction by calling `requestStakeWithdrawal()` or `completeStakeWithdrawal()`
- Even partial withdrawal (leaving `amount - 1`) causes the slash to fail
- No penalty or tracking for attempted frontrunning

### 1.2 Stake Management System

**Storage**:
```solidity
// Line 54
mapping(address manager => uint256 stake) private _managerStakeBalance;

// Line 57
mapping(address manager => WithdrawStakeRequest withdrawalRequest) public managerWithdrawalRequests;
```

**Key Functions**:

1. **depositStake** (Line 418-432):
   - Anyone can deposit stake for a manager
   - Increases `_managerStakeBalance[manager]`
   - No restrictions

2. **requestStakeWithdrawal** (Line 435-447):
   - Manager requests to withdraw `amount`
   - Creates withdrawal request with 7-day timelock
   - Only checks if balance >= amount

3. **completeStakeWithdrawal** (Line 449-480):
   - Executes after 7-day timelock
   - Must be executed within 10 days (expires after)
   - Re-checks balance (for slashing that occurred during timelock)
   - If balance < requested amount, reverts

4. **getStakeBalance** (Line 925-935):
   - Returns effective balance (actual balance - pending withdrawal amount)
   - View-only function

### 1.3 Manager System Integration

**Manager Types**:
- **Main Manager**: Primary authority for strategy (stored in `_strategyData[strategy].mainManager`)
  - Provides economic security via stake
  - Has full control over strategy operations
  - Can pause/unpause strategy
  - Debt is ALWAYS tracked on main manager
- **Secondary Managers**: Additional authorized managers (stored in `_strategyData[strategy].secondaryManagers`)
  - Operational helpers with limited permissions
  - NO economic security requirements (no stake requirement)
  - Cannot unpause strategy (only main manager can unpause)
  - When secondary manager performs operations, debt is checked on the MAIN manager of the strategy

**Manager Responsibilities**:
- **Main Manager**: Provides economic security via stake, pays for upkeep, full control
- **Secondary Managers**: Operational assistance only, no stake requirement

**Critical Insight**:
- Upkeep and stake are separate balances
- Economic security comes from MAIN MANAGER's stake only
- Secondary managers have NO stake requirements and NO debt tracking
- All debt checks must reference the main manager of the strategy, not the caller

### 1.4 Dependencies and External Interactions

**SuperGovernor Role**:
- Only `SUPER_GOVERNOR` role (via `SuperGovernor.sol`) can call `slashStake()`
- Governance-driven slashing for misbehavior

**SuperBank Integration**:
- Slashed tokens are transferred directly to `SuperBank`
- Used for protocol revenue/security

**UP Token**:
- Both upkeep and stake use UP tokens
- Retrieved via `SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP())`

---

## 2. Architecture Design

### 2.1 Debt System Overview

**Core Concept**:
- Instead of reverting when stake is insufficient, create a debt
- Debt = amount that couldn't be slashed
- Debt persists until repaid
- Managers with debt face operational restrictions
- **CRITICAL**: Debt is ALWAYS checked on the MAIN manager, even when secondary managers perform actions

**State Machine**:

```
┌─────────────────────────────────────────────────────────────┐
│              Main Manager State Machine                      │
└─────────────────────────────────────────────────────────────┘

    [ACTIVE - No Debt]
       │
       │ Slashing occurs, insufficient stake
       ▼
    [IN_DEBT]
       │
       │ Restrictions apply to:
       │ - Main manager operations
       │ - Secondary manager operations (checked against main manager debt)
       │
       │ Debt repayment via depositStake()
       ▼
    [ACTIVE - No Debt]
```

### 2.2 Data Structures

**New Storage Variables**:

```solidity
/// @notice Debt owed by managers from insufficient stake during slashing
/// @dev Debt must be repaid before manager can perform certain actions
/// @dev IMPORTANT: Debt is tracked on MAIN managers only
mapping(address manager => uint256 debt) private _managerDebt;

/// @notice Global default minimum stake requirement
/// @dev Applied to all MAIN managers
uint256 private _globalMinStake;

/// @notice Proposed global minimum stake (for timelock pattern)
uint256 private _proposedGlobalMinStake;

/// @notice Effective time for proposed global minimum stake
uint256 private _proposedGlobalMinStakeEffectiveTime;
```

**Rationale**:
- `_managerDebt`: Core debt tracking, ONLY for main managers
- `_globalMinStake`: Applies to all main managers, provides baseline economic security
- Timelock pattern for global min stake changes ensures stability

### 2.3 Debt Creation Logic

**Modified slashStake Function**:

```solidity
function slashStake(address manager, uint256 amount) external {
    // Only SUPER_GOVERNOR can slash stake
    if (msg.sender != address(SUPER_GOVERNOR)) {
        revert CALLER_NOT_AUTHORIZED();
    }

    // Validate inputs
    if (manager == address(0)) revert ZERO_ADDRESS();
    if (amount == 0) revert ZERO_AMOUNT();

    // Calculate how much can actually be slashed
    uint256 currentBalance = _managerStakeBalance[manager];
    uint256 slashableAmount = Math.min(currentBalance, amount);

    // Calculate debt if slash amount exceeds balance
    uint256 debtCreated = 0;
    if (amount > currentBalance) {
        debtCreated = amount - currentBalance;
        _managerDebt[manager] += debtCreated;
    }

    // Reduce manager's stake balance by slashable amount
    if (slashableAmount > 0) {
        _managerStakeBalance[manager] -= slashableAmount;
    }

    // Clear any pending withdrawal requests
    delete managerWithdrawalRequests[manager];

    // Get the UP token address and SuperBank address
    address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());
    address superBank = _getSuperBank();

    // Transfer slashed amount to SuperBank (only what was actually slashed)
    if (slashableAmount > 0) {
        IERC20(upToken).safeTransfer(superBank, slashableAmount);
    }

    // Emit events
    emit StakeSlashed(manager, slashableAmount, debtCreated);
    if (debtCreated > 0) {
        emit ManagerDebtCreated(manager, debtCreated, _managerDebt[manager]);
    }
}
```

**Key Changes**:
1. No longer reverts on insufficient balance
2. Slashes `min(balance, amount)`
3. Creates debt for remainder
4. Emits separate events for slashing and debt creation

### 2.4 Debt Repayment Mechanism

**Modified depositStake Function**:

```solidity
function depositStake(address manager, uint256 amount) external {
    if (amount == 0) revert ZERO_AMOUNT();
    if (manager == address(0)) revert ZERO_ADDRESS();

    // Get the UP token address from SUPER_GOVERNOR
    address upToken = SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.UP());

    // Transfer UP tokens from msg.sender to this contract
    IERC20(upToken).safeTransferFrom(msg.sender, address(this), amount);

    // Check if manager has outstanding debt
    uint256 currentDebt = _managerDebt[manager];

    if (currentDebt > 0) {
        // Apply deposited amount to debt first
        uint256 debtRepayment = Math.min(currentDebt, amount);
        _managerDebt[manager] -= debtRepayment;

        // Transfer debt repayment to SuperBank (where slashed funds go)
        address superBank = _getSuperBank();
        IERC20(upToken).safeTransfer(superBank, debtRepayment);

        // Remaining amount (if any) goes to stake balance
        uint256 remainingAmount = amount - debtRepayment;
        if (remainingAmount > 0) {
            _managerStakeBalance[manager] += remainingAmount;
        }

        emit DebtRepaid(manager, debtRepayment, _managerDebt[manager]);
        if (remainingAmount > 0) {
            emit StakeDeposited(manager, remainingAmount);
        }
    } else {
        // No debt: all amount goes to stake balance
        _managerStakeBalance[manager] += amount;
        emit StakeDeposited(manager, amount);
    }
}
```

**Key Features**:
1. Automatic debt repayment priority
2. Debt payment goes to SuperBank (same destination as slashed funds)
3. Excess after debt repayment goes to stake
4. Clear event tracking

### 2.5 Minimum Stake Enforcement

**Validation Function**:

```solidity
/// @notice Internal function to check if main manager meets minimum stake requirements
/// @param manager The main manager to check
/// @return hasMinStake True if manager has sufficient stake
/// @return requiredStake The minimum stake required
function _hasMinimumStake(address manager) internal view returns (bool hasMinStake, uint256 requiredStake) {
    // Use global minimum stake
    requiredStake = _globalMinStake;

    // If no minimum is set, always passes
    if (requiredStake == 0) {
        return (true, 0);
    }

    // Check if effective balance meets requirement
    uint256 effectiveBalance = _getEffectiveStakeBalance(manager);
    hasMinStake = effectiveBalance >= requiredStake;
}

/// @notice Gets effective stake balance (actual balance minus pending withdrawals)
/// @param manager The manager to check
/// @return Effective stake balance
function _getEffectiveStakeBalance(address manager) internal view returns (uint256) {
    uint256 balance = _managerStakeBalance[manager];
    uint256 pendingWithdrawal = managerWithdrawalRequests[manager].amount;

    if (pendingWithdrawal > balance) {
        return 0;
    }
    return balance - pendingWithdrawal;
}
```

**Integration Points**:
- Check before critical operations (see 2.6)
- View functions for frontends to check eligibility
- Governance functions to set minimum

### 2.6 Action Restrictions When in Debt

**CRITICAL DESIGN RULE**: When any manager (main or secondary) performs an operation on a strategy, the debt check must be performed on the MAIN manager of that strategy.

**Restricted Operations**:

1. **Stake Withdrawal** (Modified `requestStakeWithdrawal`):
```solidity
function requestStakeWithdrawal(uint256 amount) external {
    if (amount == 0) revert ZERO_AMOUNT();

    // DEBT CHECK: Cannot request withdrawal if in debt
    // (Only main managers have stake, so msg.sender is always a main manager here)
    if (_managerDebt[msg.sender] > 0) {
        revert MANAGER_HAS_DEBT();
    }

    // Check sufficient balance
    if (_managerStakeBalance[msg.sender] < amount) {
        revert INSUFFICIENT_STAKE_BALANCE();
    }

    // MINIMUM STAKE CHECK: Cannot withdraw below minimum
    uint256 balanceAfterWithdrawal = _managerStakeBalance[msg.sender] - amount;
    (bool hasMinStake, uint256 requiredStake) = _hasMinimumStake(msg.sender);
    if (!hasMinStake) {
        // Check if withdrawal would violate minimum
        if (balanceAfterWithdrawal < requiredStake) {
            revert WITHDRAWAL_BELOW_MINIMUM_STAKE();
        }
    }

    // Create withdrawal request
    managerWithdrawalRequests[msg.sender] = WithdrawStakeRequest({
        amount: amount,
        timestamp: block.timestamp
    });

    emit StakeWithdrawRequested(msg.sender, amount);
}
```

2. **Manager Operations** (New validation in various functions):

Add debt/minimum stake checks to functions that require active manager status:
- `pauseStrategy()` - Manager with debt can still pause for safety
- `unpauseStrategy()` - **ONLY main manager can call** (NOT secondary managers), blocked if main manager has debt
- `addAuthorizedCaller()` - BLOCKED if MAIN manager of strategy has debt
- `removeAuthorizedCaller()` - BLOCKED if MAIN manager of strategy has debt
- `addSecondaryManager()` - BLOCKED if MAIN manager (caller) has debt
- `removeSecondaryManager()` - BLOCKED if MAIN manager (caller) has debt
- `updatePPSVerificationThresholds()` - BLOCKED if MAIN manager (caller) has debt
- `changeGlobalLeavesStatus()` - BLOCKED if MAIN manager (caller) has debt
- `proposeChangePrimaryManager()` - BLOCKED if proposer (secondary manager) OR NEW proposed main manager has debt
- `proposeStrategyHooksRoot()` - BLOCKED if MAIN manager (caller) has debt

**Implementation Pattern**:
```solidity
/// @notice Modifier to check if the MAIN manager of a strategy has debt
/// @param strategy The strategy to check the main manager for
modifier mainManagerNoDebt(address strategy) {
    address mainManager = _strategyData[strategy].mainManager;
    if (_managerDebt[mainManager] > 0) {
        revert MANAGER_HAS_DEBT();
    }
    _;
}

/// @notice Modifier to check if a specific manager (main manager) has debt
/// @dev Only use when caller is known to be a main manager
modifier noDebt(address manager) {
    if (_managerDebt[manager] > 0) {
        revert MANAGER_HAS_DEBT();
    }
    _;
}

/// @notice Modifier to check if the MAIN manager meets minimum stake requirement
/// @param strategy The strategy to check the main manager for
modifier mainManagerMeetsMinimumStake(address strategy) {
    address mainManager = _strategyData[strategy].mainManager;
    (bool hasMinStake, uint256 requiredStake) = _hasMinimumStake(mainManager);
    if (!hasMinStake) {
        revert INSUFFICIENT_STAKE_FOR_OPERATION(requiredStake);
    }
    _;
}

/// @notice Modifier to check if a specific manager (main manager) meets minimum stake
modifier meetsMinimumStake(address manager) {
    (bool hasMinStake, uint256 requiredStake) = _hasMinimumStake(manager);
    if (!hasMinStake) {
        revert INSUFFICIENT_STAKE_FOR_OPERATION(requiredStake);
    }
    _;
}
```

**Rationale**:
- Debt blocks non-emergency operations
- Emergency operations (pause) still allowed
- **Unpause is NOT an emergency operation** - only main manager can unpause, ensures main manager has economic security
- Minimum stake ensures ongoing economic security
- Debt is ALWAYS checked on main manager, never on secondary managers
- Clear error messages for frontends

---

## 3. Implementation Tasks

### 3.1 Storage Variables (File: `SuperVaultAggregator.sol`)

**Location**: After line 57 (after stake withdrawal requests mapping)

```solidity
// Debt tracking (MAIN MANAGERS ONLY)
mapping(address manager => uint256 debt) private _managerDebt;

// Minimum stake requirements (MAIN MANAGERS ONLY)
uint256 private _globalMinStake;
uint256 private _proposedGlobalMinStake;
uint256 private _proposedGlobalMinStakeEffectiveTime;
```

**Constants** (add after line 78):
```solidity
// Timelock for minimum stake changes (7 days, same as other critical changes)
uint256 private constant _MIN_STAKE_CHANGE_TIMELOCK = 7 days;
```

### 3.2 Events (File: `ISuperVaultAggregator.sol`)

**Location**: Add after line 218 (after StakeSlashed event)

```solidity
/// @notice Emitted when a manager incurs debt from insufficient stake during slashing
/// @param manager The manager who incurred debt (always a main manager)
/// @param debtAmount The amount of debt created
/// @param totalDebt The manager's total debt after this operation
event ManagerDebtCreated(address indexed manager, uint256 debtAmount, uint256 totalDebt);

/// @notice Emitted when a manager repays debt
/// @param manager The manager who repaid debt (always a main manager)
/// @param repaymentAmount The amount of debt repaid
/// @param remainingDebt The manager's remaining debt after repayment
event DebtRepaid(address indexed manager, uint256 repaymentAmount, uint256 remainingDebt);

/// @notice Emitted when a global minimum stake is proposed
/// @param proposedMinStake The proposed new global minimum stake
/// @param effectiveTime The timestamp when the change becomes effective
event GlobalMinStakeProposed(uint256 proposedMinStake, uint256 effectiveTime);

/// @notice Emitted when the global minimum stake is updated
/// @param newMinStake The new global minimum stake requirement
event GlobalMinStakeUpdated(uint256 newMinStake);

/// @notice Modified: Add debtCreated parameter to existing StakeSlashed event
/// @param manager The manager whose stake was slashed (always a main manager)
/// @param slashedAmount The amount of stake actually slashed (may be less than requested)
/// @param debtCreated The amount of debt created if slashedAmount < requested amount
event StakeSlashed(address indexed manager, uint256 slashedAmount, uint256 debtCreated);
```

### 3.3 Errors (File: `ISuperVaultAggregator.sol`)

**Location**: Add after line 423 (after INSUFFICIENT_STAKE_BALANCE)

```solidity
/// @notice Thrown when a main manager has outstanding debt
error MANAGER_HAS_DEBT();

/// @notice Thrown when a main manager doesn't meet minimum stake requirements
/// @param required The minimum stake required
error INSUFFICIENT_STAKE_FOR_OPERATION(uint256 required);

/// @notice Thrown when attempting to withdraw stake below minimum requirement
error WITHDRAWAL_BELOW_MINIMUM_STAKE();

/// @notice Thrown when no pending minimum stake proposal exists
error NO_PENDING_MIN_STAKE_PROPOSAL();
```

### 3.4 Modified Functions

#### 3.4.1 `slashStake()` (SuperVaultAggregator.sol:485-515)

**Changes**:
1. Remove the revert on insufficient balance (line 496-498)
2. Calculate `slashableAmount = min(balance, amount)`
3. Calculate and track debt
4. Update event emission

**Full Implementation**: See section 2.3

#### 3.4.2 `depositStake()` (SuperVaultAggregator.sol:418-432)

**Changes**:
1. Check for existing debt before updating stake
2. Apply deposit to debt first (send to SuperBank)
3. Apply remainder to stake balance
4. Emit appropriate events

**Full Implementation**: See section 2.4

#### 3.4.3 `requestStakeWithdrawal()` (SuperVaultAggregator.sol:435-447)

**Changes**:
1. Add debt check (revert if `_managerDebt[msg.sender] > 0`)
2. Add minimum stake check for active managers
3. Ensure withdrawal doesn't drop below minimum

**Full Implementation**: See section 2.6

#### 3.4.4 `getStakeBalance()` (SuperVaultAggregator.sol:925-935)

**Changes**: Keep existing logic (returns effective balance accounting for pending withdrawals)

**Optional Enhancement**:
```solidity
/// @notice Gets comprehensive stake information for a manager
/// @param manager Address of the manager (should be a main manager)
/// @return balance Current stake balance
/// @return debt Outstanding debt amount
/// @return pendingWithdrawal Amount pending in withdrawal request
/// @return effectiveBalance Usable balance (balance - pendingWithdrawal)
/// @return minRequired Minimum stake required (0 if none)
function getManagerStakeInfo(address manager)
    external
    view
    returns (
        uint256 balance,
        uint256 debt,
        uint256 pendingWithdrawal,
        uint256 effectiveBalance,
        uint256 minRequired
    )
{
    balance = _managerStakeBalance[manager];
    debt = _managerDebt[manager];
    pendingWithdrawal = managerWithdrawalRequests[manager].amount;

    if (pendingWithdrawal > balance) {
        effectiveBalance = 0;
    } else {
        effectiveBalance = balance - pendingWithdrawal;
    }

    minRequired = _globalMinStake;
}
```

### 3.5 New Functions

#### 3.5.1 Debt Management

```solidity
/// @notice Gets the debt owed by a manager
/// @param manager Address of the manager (should be a main manager)
/// @return debt The debt amount
function getManagerDebt(address manager) external view returns (uint256 debt) {
    return _managerDebt[manager];
}

/// @notice Checks if a manager has any outstanding debt
/// @param manager Address of the manager (should be a main manager)
/// @return hasDebt True if manager has debt
function hasDebt(address manager) external view returns (bool hasDebt) {
    return _managerDebt[manager] > 0;
}
```

#### 3.5.2 Minimum Stake Management (Governance)

```solidity
/// @notice Proposes a new global minimum stake requirement
/// @dev Only callable by SUPER_GOVERNOR, requires timelock
/// @param newMinStake The proposed minimum stake amount
function proposeGlobalMinStake(uint256 newMinStake) external {
    if (msg.sender != address(SUPER_GOVERNOR)) {
        revert CALLER_NOT_AUTHORIZED();
    }

    _proposedGlobalMinStake = newMinStake;
    _proposedGlobalMinStakeEffectiveTime = block.timestamp + _MIN_STAKE_CHANGE_TIMELOCK;

    emit GlobalMinStakeProposed(newMinStake, _proposedGlobalMinStakeEffectiveTime);
}

/// @notice Executes a previously proposed global minimum stake change
/// @dev Can be called by anyone after timelock expires
function executeGlobalMinStakeChange() external {
    if (_proposedGlobalMinStakeEffectiveTime == 0) {
        revert NO_PENDING_MIN_STAKE_PROPOSAL();
    }
    if (block.timestamp < _proposedGlobalMinStakeEffectiveTime) {
        revert TIMELOCK_NOT_EXPIRED();
    }

    uint256 newMinStake = _proposedGlobalMinStake;
    _globalMinStake = newMinStake;

    // Reset proposal
    _proposedGlobalMinStake = 0;
    _proposedGlobalMinStakeEffectiveTime = 0;

    emit GlobalMinStakeUpdated(newMinStake);
}

/// @notice Gets the global minimum stake requirement
/// @return minStake The minimum stake required for all main managers
function getGlobalMinStake() external view returns (uint256 minStake) {
    return _globalMinStake;
}

/// @notice Gets the proposed global minimum stake and effective time
/// @return proposedMinStake The proposed minimum stake
/// @return effectiveTime When the proposal becomes executable
function getProposedGlobalMinStake()
    external
    view
    returns (uint256 proposedMinStake, uint256 effectiveTime)
{
    return (_proposedGlobalMinStake, _proposedGlobalMinStakeEffectiveTime);
}
```

#### 3.5.3 Internal Helper Functions

```solidity
/// @notice Internal function to get the main manager of a strategy
/// @param strategy The strategy address
/// @return The main manager address
function _getMainManager(address strategy) internal view returns (address) {
    return _strategyData[strategy].mainManager;
}

/// @notice Internal function to check if main manager meets minimum stake requirements
/// @param manager The main manager to check
/// @return hasMinStake True if manager has sufficient stake
/// @return requiredStake The minimum stake required
function _hasMinimumStake(address manager)
    internal
    view
    returns (bool hasMinStake, uint256 requiredStake)
{
    // Implementation in section 2.5
}

/// @notice Gets effective stake balance (actual balance minus pending withdrawals)
/// @param manager The manager to check
/// @return Effective stake balance
function _getEffectiveStakeBalance(address manager) internal view returns (uint256) {
    // Implementation in section 2.5
}

/// @notice Internal validation for manager operations requiring no debt on MAIN manager
/// @param strategy The strategy to check
function _requireMainManagerNoDebt(address strategy) internal view {
    address mainManager = _strategyData[strategy].mainManager;
    if (_managerDebt[mainManager] > 0) {
        revert MANAGER_HAS_DEBT();
    }
}

/// @notice Internal validation for manager operations requiring no debt
/// @dev Only use when manager is known to be a main manager
/// @param manager The main manager to validate
function _requireNoDebt(address manager) internal view {
    if (_managerDebt[manager] > 0) {
        revert MANAGER_HAS_DEBT();
    }
}

/// @notice Internal validation for operations requiring main manager minimum stake
/// @param strategy The strategy to check
function _requireMainManagerMinimumStake(address strategy) internal view {
    address mainManager = _strategyData[strategy].mainManager;
    (bool hasMinStake, uint256 requiredStake) = _hasMinimumStake(mainManager);
    if (!hasMinStake) {
        revert INSUFFICIENT_STAKE_FOR_OPERATION(requiredStake);
    }
}

/// @notice Internal validation for manager operations requiring minimum stake
/// @dev Only use when manager is known to be a main manager
/// @param manager The main manager to validate
function _requireMinimumStake(address manager) internal view {
    (bool hasMinStake, uint256 requiredStake) = _hasMinimumStake(manager);
    if (!hasMinStake) {
        revert INSUFFICIENT_STAKE_FOR_OPERATION(requiredStake);
    }
}
```

### 3.6 Integration with Existing Manager Functions

**Pattern**: Add validation calls at the start of each function, checking the MAIN manager

**Functions to Modify**:

1. **addAuthorizedCaller** (Line 521):
```solidity
function addAuthorizedCaller(address strategy, address caller) external validStrategy(strategy) {
    // Either primary or secondary manager can add authorized callers
    if (!isAnyManager(msg.sender, strategy)) revert UNAUTHORIZED_UPDATE_AUTHORITY();

    // NEW: Check debt and minimum stake on MAIN manager
    _requireMainManagerNoDebt(strategy);
    _requireMainManagerMinimumStake(strategy);

    // ... rest of existing logic
}
```

2. **removeAuthorizedCaller** (Line 540):
```solidity
function removeAuthorizedCaller(address strategy, address caller) external validStrategy(strategy) {
    // Either primary or secondary manager can remove authorized callers
    if (!isAnyManager(msg.sender, strategy)) revert UNAUTHORIZED_UPDATE_AUTHORITY();

    // NEW: Check debt and minimum stake on MAIN manager
    _requireMainManagerNoDebt(strategy);
    _requireMainManagerMinimumStake(strategy);

    // ... rest of existing logic
}
```

3. **addSecondaryManager** (Line 555):
```solidity
function addSecondaryManager(address strategy, address manager) external validStrategy(strategy) {
    // Only the primary manager can add secondary managers
    if (msg.sender != _strategyData[strategy].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

    // NEW: Check debt and minimum stake on main manager (caller)
    _requireNoDebt(msg.sender);
    _requireMinimumStake(msg.sender);

    // ... rest of existing logic
}
```

4. **removeSecondaryManager** (Line 576):
```solidity
function removeSecondaryManager(address strategy, address manager) external validStrategy(strategy) {
    // Only the primary manager can remove secondary managers
    if (msg.sender != _strategyData[strategy].mainManager) revert UNAUTHORIZED_UPDATE_AUTHORITY();

    // NEW: Check debt and minimum stake on main manager (caller)
    _requireNoDebt(msg.sender);
    _requireMinimumStake(msg.sender);

    // ... rest of existing logic
}
```

5. **updatePPSVerificationThresholds** (Line 587):
```solidity
function updatePPSVerificationThresholds(
    address strategy,
    uint256 deviationThreshold_,
    uint256 mnThreshold_
)
    external
    validStrategy(strategy)
{
    // Since this is a risky call, we only allow main managers as callers
    if (msg.sender != _strategyData[strategy].mainManager) {
        revert UNAUTHORIZED_UPDATE_AUTHORITY();
    }

    // NEW: Check debt and minimum stake on main manager (caller)
    _requireNoDebt(msg.sender);
    _requireMinimumStake(msg.sender);

    // ... rest of existing logic
}
```

6. **changeGlobalLeavesStatus** (Line 609):
```solidity
function changeGlobalLeavesStatus(
    bytes32[] memory leaves,
    bool[] memory statuses,
    address strategy
)
    external
    validStrategy(strategy)
{
    // Only the primary manager can change global leaves status
    if (msg.sender != _strategyData[strategy].mainManager) {
        revert UNAUTHORIZED_UPDATE_AUTHORITY();
    }

    // NEW: Check debt and minimum stake on main manager (caller)
    _requireNoDebt(msg.sender);
    _requireMinimumStake(msg.sender);

    // ... rest of existing logic
}
```

7. **proposeChangePrimaryManager** (Line 674):
```solidity
function proposeChangePrimaryManager(address strategy, address newManager) external validStrategy(strategy) {
    // Only secondary managers can propose changes to the primary manager
    if (!_strategyData[strategy].secondaryManagers.contains(msg.sender)) {
        revert UNAUTHORIZED_UPDATE_AUTHORITY();
    }

    // NEW: Check debt and minimum stake on proposer (secondary manager checks main manager)
    _requireMainManagerNoDebt(strategy);
    _requireMainManagerMinimumStake(strategy);

    // NEW: CRITICAL - Check that the NEW proposed main manager has:
    // 1. Zero debt (fully repaid)
    // 2. Sufficient stake meeting minimum requirements
    if (_managerDebt[newManager] > 0) {
        revert MANAGER_HAS_DEBT();
    }
    _requireMinimumStake(newManager);

    // ... rest of existing logic
}
```

8. **proposeStrategyHooksRoot** (Line 794):
```solidity
function proposeStrategyHooksRoot(address strategy, bytes32 newRoot) external validStrategy(strategy) {
    // Only the main manager can propose strategy-specific hooks root
    if (_strategyData[strategy].mainManager != msg.sender) {
        revert UNAUTHORIZED_UPDATE_AUTHORITY();
    }

    // NEW: Check debt and minimum stake on main manager (caller)
    _requireNoDebt(msg.sender);
    _requireMinimumStake(msg.sender);

    // ... rest of existing logic
}
```

9. **unpauseStrategy** (IMPORTANT - NEW RESTRICTION):
```solidity
function unpauseStrategy(address strategy) external validStrategy(strategy) {
    // CRITICAL: ONLY the main manager can unpause
    // This ensures economic security is in place before resuming operations
    if (msg.sender != _strategyData[strategy].mainManager) {
        revert UNAUTHORIZED_UPDATE_AUTHORITY();
    }

    // NEW: Check debt and minimum stake on main manager (caller)
    _requireNoDebt(msg.sender);
    _requireMinimumStake(msg.sender);

    // ... rest of existing logic
}
```

**Note**: `pauseStrategy()` (Line 375) should NOT have debt checks - managers should always be able to pause for safety, even with debt.

### 3.7 SuperGovernor Integration (File: `SuperGovernor.sol`)

**New Functions to Add** (after line 680):

```solidity
/// @notice Proposes a new global minimum stake requirement
/// @param newMinStake The proposed minimum stake amount
function proposeGlobalMinStake(uint256 newMinStake) external onlyRole(_SUPER_GOVERNOR_ROLE) {
    address aggregator = _addressRegistry[SUPER_VAULT_AGGREGATOR];
    if (aggregator == address(0)) revert CONTRACT_NOT_FOUND();

    ISuperVaultAggregator(aggregator).proposeGlobalMinStake(newMinStake);
}
```

### 3.8 Interface Updates (File: `ISuperVaultAggregator.sol`)

**Add after line 571** (after slashStake function):

```solidity
/*//////////////////////////////////////////////////////////////
                        DEBT MANAGEMENT
//////////////////////////////////////////////////////////////*/

/// @notice Gets the debt owed by a manager
/// @param manager Address of the manager (should be a main manager)
/// @return debt The debt amount
function getManagerDebt(address manager) external view returns (uint256 debt);

/// @notice Checks if a manager has any outstanding debt
/// @param manager Address of the manager (should be a main manager)
/// @return hasDebt True if manager has debt
function hasDebt(address manager) external view returns (bool hasDebt);

/*//////////////////////////////////////////////////////////////
                    MINIMUM STAKE MANAGEMENT
//////////////////////////////////////////////////////////////*/

/// @notice Proposes a new global minimum stake requirement
/// @param newMinStake The proposed minimum stake amount
function proposeGlobalMinStake(uint256 newMinStake) external;

/// @notice Executes a previously proposed global minimum stake change
function executeGlobalMinStakeChange() external;

/// @notice Gets the global minimum stake requirement
/// @return minStake The minimum stake required for all main managers
function getGlobalMinStake() external view returns (uint256 minStake);

/// @notice Gets the proposed global minimum stake and effective time
/// @return proposedMinStake The proposed minimum stake
/// @return effectiveTime When the proposal becomes executable
function getProposedGlobalMinStake()
    external
    view
    returns (uint256 proposedMinStake, uint256 effectiveTime);

/// @notice Gets comprehensive stake information for a manager
/// @param manager Address of the manager (should be a main manager)
/// @return balance Current stake balance
/// @return debt Outstanding debt amount
/// @return pendingWithdrawal Amount pending in withdrawal request
/// @return effectiveBalance Usable balance (balance - pendingWithdrawal)
/// @return minRequired Minimum stake required (0 if none)
function getManagerStakeInfo(address manager)
    external
    view
    returns (
        uint256 balance,
        uint256 debt,
        uint256 pendingWithdrawal,
        uint256 effectiveBalance,
        uint256 minRequired
    );
```

---

## 4. Security Considerations

### 4.1 Frontrunning Mitigation

**Attack Vector**: Manager monitors mempool for slashing transaction and attempts to withdraw

**Mitigations**:
1. **Debt Creation**: Even if withdrawal completes, debt is created and tracked
2. **7-Day Timelock**: `requestStakeWithdrawal()` requires 7-day wait, slashing likely completes first
3. **Withdrawal Blocking**: Once in debt, cannot request new withdrawals
4. **Minimum Stake**: Active managers must maintain minimum, limiting withdrawal ability

**Remaining Risk**: Manager could have withdrawal request pending before misbehavior. During the 7-day wait, they could be slashed and go into debt, but withdrawal still completes (at line 467-480 of current code).

**Additional Mitigation**:
```solidity
// In completeStakeWithdrawal(), add debt check before transfer:
function completeStakeWithdrawal() external {
    WithdrawStakeRequest memory request = managerWithdrawalRequests[msg.sender];

    if (request.amount == 0 || request.timestamp == 0) revert WITHDRAW_STAKE_REQUEST_NOT_FOUND();

    if (request.timestamp + WITHDRAW_STAKE_TIMELOCK > block.timestamp) {
        revert WITHDRAW_STAKE_REQUEST_NOT_READY();
    }

    if (block.timestamp > request.timestamp + WITHDRAWAL_REQUEST_TIMEOUT) {
        revert WITHDRAWAL_REQUEST_EXPIRED();
    }

    // NEW: Check for debt before allowing withdrawal
    if (_managerDebt[msg.sender] > 0) {
        // Cancel the withdrawal request
        delete managerWithdrawalRequests[msg.sender];
        revert MANAGER_HAS_DEBT();
    }

    // ... rest of existing logic
}
```

### 4.2 Main Manager vs Secondary Manager Security

**Critical Security Principle**: Economic security comes from MAIN manager stake only

**Security Boundaries**:
1. **Debt Tracking**: Only main managers have debt tracked
2. **Stake Requirements**: Only main managers have stake and minimum requirements
3. **Unpause Restriction**: Only main managers can unpause strategies
4. **Debt Checks**: When secondary managers act, check debt on main manager

**Attack Scenarios**:
- **Secondary Manager Bypass**: Cannot bypass debt checks - all operations check main manager debt
- **Unstaked Secondary**: Acceptable - secondary managers don't need stake
- **Main Manager Change**: New main manager must have zero debt and sufficient stake

### 4.3 Main Manager Change Security

**Critical Validation in `proposeChangePrimaryManager`**:
```solidity
// NEW proposed main manager MUST have:
// 1. Zero debt (fully repaid)
if (_managerDebt[newManager] > 0) {
    revert MANAGER_HAS_DEBT();
}
// 2. Sufficient stake meeting minimum requirements
_requireMinimumStake(newManager);
```

**Rationale**:
- Ensures continuous economic security
- Prevents debt-laden managers from taking control
- Requires clean financial state before assuming main manager role

### 4.4 Debt Overflow Protection

**Risk**: Multiple slashing events could overflow debt tracking

**Mitigation**: Use OpenZeppelin's SafeMath (built into Solidity 0.8+)
- All arithmetic operations automatically check for overflow
- `_managerDebt[manager] += debtCreated` will revert on overflow
- Practical limit: uint256 max ≈ 1.15e77, unrealistic debt amount

### 4.5 Reentrancy Protection

**Current Status**: Contract already uses OpenZeppelin's `SafeERC20` for token transfers

**Risk Points**:
1. `slashStake()` - Makes external call to transfer to SuperBank
2. `depositStake()` - Makes external calls for token transfers and SuperBank transfer

**Mitigation**:
- Already follows checks-effects-interactions pattern
- State updates occur before external calls
- No additional reentrancy guards needed for debt system

**Verification**:
```solidity
// In slashStake():
// 1. State updates first
_managerDebt[manager] += debtCreated;
_managerStakeBalance[manager] -= slashableAmount;
delete managerWithdrawalRequests[manager];

// 2. External calls last
IERC20(upToken).safeTransfer(superBank, slashableAmount);
```

### 4.6 Minimum Stake Configuration Risks

**Risk 1**: Setting minimum too high locks out managers

**Mitigation**:
- Global minimum has 7-day timelock
- Governance-controlled (SUPER_GOVERNOR role)

**Risk 2**: Setting minimum to zero disables enforcement

**Mitigation**:
- Acceptable - allows opt-out enforcement
- Can re-enable via governance

**Risk 3**: Minimum changes affect existing managers

**Mitigation**:
- Minimums only checked at operation time, not retroactively
- Managers below new minimum can still operate if no debt
- Can deposit stake to meet new minimum

### 4.7 Access Control

**Critical Functions** and their access:

1. **slashStake**: Only SUPER_GOVERNOR (slashes main managers only)
2. **proposeGlobalMinStake**: Only SUPER_GOVERNOR
3. **executeGlobalMinStakeChange**: Anyone (after timelock)
4. **depositStake**: Anyone (permissionless by design)
5. **requestStakeWithdrawal**: Only manager themselves (main managers only have stake)
6. **unpauseStrategy**: Only main manager (NEW RESTRICTION)

**Verification**: All access controls preserved from current system

---

## 5. Testing Strategy

### 5.1 Core Debt System Tests
- Debt creation with sufficient/insufficient balance
- Debt repayment (full, partial, none)
- Debt overflow scenarios
- Concurrent slashing operations
- Funds flow verification (to SuperBank)

### 5.2 Main Manager vs Secondary Manager Tests
- Secondary manager operations check main manager debt
- Main manager operations check own debt
- Unpause restricted to main manager only
- Main manager change validation (zero debt, sufficient stake)
- Secondary manager cannot bypass debt checks

### 5.3 Withdrawal and Restriction Tests
- Withdrawal blocked when in debt
- Withdrawal below minimum stake blocked
- Manager operations blocked when main manager has debt
- Pause still works with debt (emergency operation)
- Unpause blocked when main manager has debt

### 5.4 Minimum Stake Tests
- Global minimum with timelock
- Operations blocked below minimum
- Withdrawal prevented below minimum

### 5.5 Main Manager Change Tests
- Propose change requires proposer's main manager has no debt
- Propose change requires NEW main manager has zero debt
- Propose change requires NEW main manager has sufficient stake
- Change fails if new manager doesn't meet requirements

### 5.6 Frontrunning Prevention Tests
- Withdrawal request cleared by slashing
- Debt prevents withdrawal completion
- 7-day timelock vs slashing timing
- Multiple slashing accumulates debt

### 5.7 Integration Tests
- Backward compatibility with existing stake workflow
- Manager operations work with sufficient stake
- Cross-function interaction (debt, withdrawal, minimums)
- Event emission verification

### 5.8 Edge Cases
- Zero amount/address reverts
- Access control violations
- Comprehensive stake info queries
- Gas usage profiling

---

## 6. Summary and Next Steps

### 6.1 Key Architectural Decisions

1. **Debt Creation**: Slash `min(balance, amount)`, create debt for remainder
2. **Debt Tracking**: ONLY on main managers, never on secondary managers
3. **Debt Checks**: When ANY manager acts, check debt on MAIN manager of strategy
4. **Debt Repayment**: Automatic via `depositStake()`, funds go to SuperBank
5. **Restrictions**: Debt blocks withdrawals and non-emergency operations
6. **Unpause Restriction**: ONLY main manager can unpause (NOT secondary managers)
7. **Main Manager Change**: New main manager must have zero debt and sufficient stake
8. **Minimum Stake**: Global minimum only, governance-controlled with 7-day timelock
9. **Access Control**: Maintains existing SUPER_GOVERNOR control for slashing

### 6.2 Critical Implementation Notes

**MUST IMPLEMENT CORRECTLY**:
1. All debt checks must reference the MAIN manager of the strategy, not the caller (when caller is secondary)
2. Unpause function ONLY callable by main manager (not secondary managers)
3. Main manager change validation MUST check new manager has zero debt AND sufficient stake
4. Secondary managers have NO stake requirements and NO debt tracking
5. Economic security comes from MAIN manager stake only

### 6.3 Main Implementation Tasks

1. **Storage** (3 new variables): debt mapping, global min stake, proposal tracking
2. **Events** (4 new events): debt creation/repayment, min stake updates, modified slash event
3. **Errors** (4 new errors): debt-related, min stake violations
4. **Modified Functions** (4): `slashStake`, `depositStake`, `requestStakeWithdrawal`, `completeStakeWithdrawal`
5. **New Functions** (7): debt queries, min stake management, comprehensive views
6. **Integration** (9 functions): add debt/min stake checks to manager operations, restrict unpause
7. **Governance** (1 new function in SuperGovernor): min stake configuration
8. **Internal Helpers** (6 functions): debt/minimum checks for main manager

### 6.4 Critical Security Considerations

1. **Frontrunning**: Mitigated via debt tracking, withdrawal timelock, and pending request blocking
2. **Main Manager Security**: Economic security tied to main manager stake only
3. **Secondary Manager Bypass**: Prevented by checking main manager debt on all operations
4. **Main Manager Change**: New main manager must have zero debt and sufficient stake
5. **Unpause Control**: Restricted to main manager only for economic security
6. **Overflow**: Protected by Solidity 0.8+ built-in checks
7. **Reentrancy**: Existing checks-effects-interactions pattern maintained
8. **Access Control**: All sensitive operations remain governance-controlled
9. **State Consistency**: Debt and balance always updated together

### 6.5 Recommended Implementation Order

1. **First**: Implement debt system (storage, slashStake, depositStake)
2. **Second**: Add debt query functions and helper functions
3. **Third**: Implement withdrawal blocking (requestStakeWithdrawal, completeStakeWithdrawal)
4. **Fourth**: Add minimum stake system
5. **Fifth**: Integrate with manager operations (add main manager debt checks)
6. **Sixth**: Restrict unpause to main manager only
7. **Seventh**: Add main manager change validation
8. **Eighth**: Comprehensive testing
9. **Ninth**: Documentation and audit prep

---

## Appendix A: Complete Code Checklist

### Files to Modify

#### `src/SuperVault/SuperVaultAggregator.sol`
- [ ] Add storage variables (3 new)
- [ ] Modify `slashStake()` (lines 485-515)
- [ ] Modify `depositStake()` (lines 418-432)
- [ ] Modify `requestStakeWithdrawal()` (lines 435-447)
- [ ] Modify `completeStakeWithdrawal()` (lines 449-480) - add debt check
- [ ] Modify `unpauseStrategy()` - restrict to main manager only
- [ ] Add debt query functions (2 new)
- [ ] Add min stake management functions (4 new)
- [ ] Add internal helper functions (6 new) - include main manager checks
- [ ] Add `getManagerStakeInfo()` view function
- [ ] Integrate debt/min stake checks into 8 manager functions (checking MAIN manager)
- [ ] Add validation to `proposeChangePrimaryManager()` for new main manager

#### `src/interfaces/SuperVault/ISuperVaultAggregator.sol`
- [ ] Add new errors (4)
- [ ] Modify `StakeSlashed` event signature
- [ ] Add new events (4)
- [ ] Add debt management function signatures (2)
- [ ] Add min stake management function signatures (4)
- [ ] Add `getManagerStakeInfo()` signature

#### `src/SuperGovernor.sol`
- [ ] Add `proposeGlobalMinStake()` function

#### `src/interfaces/ISuperGovernor.sol`
- [ ] Add function signature for min stake governance (1)

### Testing Files to Create

#### `test/unit/SuperVaultAggregator.t.sol`
- [ ] Debt creation tests (10+ tests)
- [ ] Debt repayment tests (8+ tests)
- [ ] Withdrawal blocking tests (5+ tests)
- [ ] Minimum stake tests (10+ tests)
- [ ] Manager operation restriction tests (10+ tests)
- [ ] Main manager vs secondary manager tests (8+ tests)
- [ ] Unpause restriction tests (3+ tests)
- [ ] Main manager change validation tests (5+ tests)
- [ ] Edge cases and failure modes (8+ tests)
- [ ] Gas optimization tests (3+ tests)

#### `test/integration/DebtSystemIntegration.t.sol`
- [ ] Frontrunning scenario tests (5+ tests)
- [ ] Concurrent slashing tests (3+ tests)
- [ ] Cross-function interaction tests (5+ tests)
- [ ] Backward compatibility tests (4+ tests)

---

## Appendix B: Event and Error Reference

### Complete Event List

```solidity
// Modified
event StakeSlashed(address indexed manager, uint256 slashedAmount, uint256 debtCreated);

// New
event ManagerDebtCreated(address indexed manager, uint256 debtAmount, uint256 totalDebt);
event DebtRepaid(address indexed manager, uint256 repaymentAmount, uint256 remainingDebt);
event GlobalMinStakeProposed(uint256 proposedMinStake, uint256 effectiveTime);
event GlobalMinStakeUpdated(uint256 newMinStake);
```

### Complete Error List

```solidity
// New
error MANAGER_HAS_DEBT();
error INSUFFICIENT_STAKE_FOR_OPERATION(uint256 required);
error WITHDRAWAL_BELOW_MINIMUM_STAKE();
error NO_PENDING_MIN_STAKE_PROPOSAL();
```

---

## Appendix C: Storage Layout

### Before (Current System)
```
Slot 50: mapping(address => uint256) _managerUpkeepBalance
Slot 51: mapping(address => uint256) _managerStakeBalance
Slot 52: mapping(address => WithdrawStakeRequest) managerWithdrawalRequests
```

### After (With Debt System)
```
Slot 50: mapping(address => uint256) _managerUpkeepBalance
Slot 51: mapping(address => uint256) _managerStakeBalance
Slot 52: mapping(address => WithdrawStakeRequest) managerWithdrawalRequests
Slot 53: mapping(address => uint256) _managerDebt [NEW - MAIN MANAGERS ONLY]
Slot 54: uint256 _globalMinStake [NEW]
Slot 55: uint256 _proposedGlobalMinStake [NEW]
Slot 56: uint256 _proposedGlobalMinStakeEffectiveTime [NEW]
```

**Note**: Actual slot numbers depend on other storage variables. This is a logical representation.

---

## Appendix D: Executive Summary for Auditors

### Problem Statement

The SuperVault slashing mechanism contains a critical frontrunning vulnerability. When governance initiates slashing against a misbehaving manager, the manager can monitor the mempool and frontrun the slashing transaction by withdrawing their stake. This completely undermines the economic security model of the protocol, as managers face no real consequences for malicious behavior.

**Current Vulnerability Flow**:
1. Manager misbehaves (e.g., proposes malicious hooks)
2. Governance calls `slashStake(manager, amount)`
3. Manager sees pending transaction in mempool
4. Manager frontruns with `completeStakeWithdrawal()` (if already requested) or `requestStakeWithdrawal()` + fast-forward
5. Slashing transaction reverts due to `INSUFFICIENT_STAKE_BALANCE()`
6. Manager escapes punishment with their stake intact

### Solution Overview: Debt System

Instead of reverting when stake is insufficient, we implement a **debt tracking system** that ensures accountability even when managers successfully withdraw their stake.

**Key Mechanisms**:

1. **Non-Reverting Slashing**: `slashStake()` now slashes whatever stake is available and creates a debt for the shortfall
2. **Debt Tracking**: Debt is tracked only on main managers (who provide economic security)
3. **Operational Restrictions**: Managers with debt cannot:
   - Request new stake withdrawals
   - Complete pending withdrawals
   - Perform non-emergency operations (unpause, modify strategy, etc.)
   - Transfer main manager role to another address
4. **Automatic Debt Repayment**: Any stake deposits automatically pay down debt first before increasing stake balance
5. **Global Minimum Stake**: A timelock-protected global minimum ensures baseline economic security for all main managers

**Design Principle**: Economic security comes exclusively from the **main manager's stake**. Secondary managers are operational helpers with no stake requirements. All debt checks reference the main manager, even when secondary managers perform actions.

### Key Changes to Code

**Storage Variables (3 new)**:
```solidity
mapping(address => uint256) _managerDebt;           // Tracks debt for main managers
uint256 _globalMinStake;                             // Minimum stake for all main managers
uint256 _proposedGlobalMinStake;                     // Timelock proposal for changes
uint256 _proposedGlobalMinStakeEffectiveTime;        // When proposal becomes effective
```

**Modified Functions**:
- `slashStake()`: Creates debt instead of reverting, slashes `min(balance, amount)`
- `depositStake()`: Automatically applies deposits to debt first, then to stake
- `requestStakeWithdrawal()`: Blocks if manager has debt or withdrawal violates minimum
- `completeStakeWithdrawal()`: Blocks if manager has debt (prevents frontrun completion)

**New Functions**:
- `getManagerDebt()`, `hasDebt()`: Query debt status
- `proposeGlobalMinStake()`, `executeGlobalMinStakeChange()`: Governance-controlled minimum stake with 7-day timelock
- `getManagerStakeInfo()`: Comprehensive view of manager's stake, debt, and restrictions

**Integration Changes** (9 functions modified):
- Added debt/minimum stake checks to critical manager operations
- `unpauseStrategy()`: Now restricted to main manager only (ensures economic security before resuming)
- `proposeChangePrimaryManager()`: New main manager must have zero debt and sufficient stake
- All secondary manager operations check debt on the **main manager** of the strategy

### Security Considerations

**Frontrunning Mitigation**:
- Even if withdrawal completes, debt is created and tracked
- Debt prevents completion of pending withdrawals
- 7-day withdrawal timelock gives governance time to execute slashing
- Minimum stake limits how much can be withdrawn while actively managing

**Main Manager vs Secondary Manager**:
- Only main managers can have debt (they're the only ones with stake)
- When secondary managers act, we check debt on the main manager of that strategy
- Prevents secondary managers from bypassing debt restrictions
- Unpause restricted to main manager ensures economic security before resuming operations

**Main Manager Transitions**:
- New main manager must have **zero debt** before assuming role
- New main manager must meet **minimum stake requirement**
- Prevents transfer of compromised strategies to undercapitalized managers

**Reentrancy & Overflow**:
- Existing checks-effects-interactions pattern preserved
- Solidity 0.8+ built-in overflow protection
- State updates before external calls in all modified functions

**Access Control**:
- Only `SUPER_GOVERNOR` can slash or set minimum stakes
- Timelock on global minimum prevents sudden lockout of managers
- Emergency pause operations remain unrestricted (managers can always pause for safety)

### Test Coverage

The implementation includes comprehensive test coverage across 8 categories:

1. **Core Debt System**: Debt creation, repayment, overflow scenarios
2. **Manager Role Tests**: Main vs secondary manager debt checks, unpause restrictions
3. **Withdrawal Restrictions**: Debt blocking, minimum stake enforcement
4. **Minimum Stake**: Global minimum with timelock, operation blocking
5. **Main Manager Changes**: Debt and stake validation for transitions
6. **Frontrunning Prevention**: Withdrawal clearing, debt accumulation, timing scenarios
7. **Integration Tests**: Backward compatibility, cross-function interactions
8. **Edge Cases**: Zero values, access control violations, gas profiling

**Expected Coverage**: 70+ unit tests + 17+ integration tests

### Impact Assessment

**Changes Summary**:
- **3 new storage variables** (all for main manager debt/minimum tracking)
- **4 modified functions** (slashing, staking, withdrawals)
- **12 new functions** (debt queries, minimum stake management, helpers)
- **9 integrated functions** (manager operations with debt checks)
- **4 new events**, **4 new errors**

**Backward Compatibility**:
- Fully backward compatible with existing stake management
- No changes to existing external interfaces (only additions)
- Existing manager operations continue to work identically if no debt
- No migration required for existing managers

**Gas Impact**:
- `slashStake()`: ~5-10k gas increase (debt tracking + conditional logic)
- `depositStake()`: ~10-15k gas increase (debt repayment logic + SuperBank transfer)
- Manager operations: ~2-5k gas increase (debt/minimum checks)
- No impact on operations when manager has no debt (fast-path optimized)

**Security Posture Improvement**:
- **Eliminates frontrunning vulnerability** (primary goal achieved)
- **Maintains economic security** through minimum stake enforcement
- **Preserves emergency capabilities** (pause always available)
- **Enforces accountability** through persistent debt tracking

### Audit Focus Areas

We recommend auditors focus on:

1. **Debt Creation Logic** (`slashStake`): Verify arithmetic correctness, no edge cases allow debt bypass
2. **Debt Repayment Flow** (`depositStake`): Ensure funds always flow correctly to SuperBank, no way to bypass debt payment
3. **Main Manager Debt Checks**: Verify all secondary manager operations correctly check main manager's debt
4. **Withdrawal Prevention**: Confirm no path allows withdrawal completion with outstanding debt
5. **Main Manager Transitions**: Validate new manager must have zero debt and sufficient stake
6. **Reentrancy**: Verify state updates occur before external calls in all modified functions
7. **Access Control**: Confirm only SUPER_GOVERNOR can slash and set minimums
8. **Edge Cases**: Zero amounts, maximum debt values, concurrent operations

**Critical Invariants to Verify**:
- Debt can only increase via slashing, only decrease via deposits
- Total slashed + debt created = requested slash amount
- Manager with debt cannot withdraw stake
- Secondary manager operations always check main manager's debt
- New main manager always has zero debt and meets minimum stake

---

**End of Implementation Plan**

**Document Version**: 3.0
**Last Updated**: 2025-11-04
**Status**: Ready for Implementation Review
