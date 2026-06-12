// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IValidatorBonding } from "./interfaces/IValidatorBonding.sol";

/// @title ValidatorBonding
/// @author Superform Labs
/// @notice Standalone sUP bonding module for Superform validators (Base only)
/// @dev Non-upgradeable. Operator/beneficiary separation supports Foundation loans.
///      sUP is the share token of a SuperVault whose asset is UP. ReentrancyGuard is defense-in-depth.
///
///      ROLE ARCHITECTURE:
///        - DEFAULT_ADMIN_ROLE: Expected to be a multisig (SUPER_GOVERNOR_ADDRESS). Controls role grants
///          and proposeParameterTimelock(). parameterTimelock changes are subject to the current timelock
///          duration before taking effect.
///        - GOVERNOR_ROLE: Held by the governance address. Has authority over both slashing (slash())
///          and parameter proposals (proposeMinimumBond, proposeUnbondingPeriod). slash() accepts any
///          non-zero recipient by design to allow flexible slashing destinations (treasury, insurance
///          fund, burn address). If role separation is desired in the future, GOVERNOR_ROLE can be
///          split into SLASHER_ROLE and PROPOSER_ROLE without contract redeployment via admin role grants.
///
///      OPERATIONAL COUPLING:
///        ValidatorBonding and SuperGovernor are deliberately decoupled on-chain. An operator can be
///        bonded here but not in the SuperGovernor validator set, and vice versa. Slashing should be
///        a multi-step Safe multicall: (1) slash in ValidatorBonding, (2) remove from SuperGovernor
///        validator config via setValidatorConfig(). Off-chain tooling monitors for mismatches between
///        the bonded set (getActiveOperators()) and the validator config.
contract ValidatorBonding is IValidatorBonding, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    /// @inheritdoc IValidatorBonding
    uint256 public constant MAX_MINIMUM_BOND = 100_000_000e18;
    /// @inheritdoc IValidatorBonding
    uint256 public constant MIN_MINIMUM_BOND = 1e18;
    /// @inheritdoc IValidatorBonding
    uint256 public constant MAX_UNBONDING_PERIOD = 365 days;
    /// @inheritdoc IValidatorBonding
    uint256 public constant MIN_UNBONDING_PERIOD = 1 days;

    /// @inheritdoc IValidatorBonding
    uint256 public constant DEFAULT_PARAMETER_TIMELOCK = 2 days;
    /// @inheritdoc IValidatorBonding
    uint256 public constant MIN_PARAMETER_TIMELOCK = 1 days;
    /// @inheritdoc IValidatorBonding
    uint256 public constant MAX_PARAMETER_TIMELOCK = 30 days;

    /// @inheritdoc IValidatorBonding
    bytes32 public constant MINIMUM_BOND_KEY = keccak256("minimumBond");
    /// @inheritdoc IValidatorBonding
    bytes32 public constant UNBONDING_PERIOD_KEY = keccak256("unbondingPeriod");
    /// @inheritdoc IValidatorBonding
    bytes32 public constant PARAMETER_TIMELOCK_KEY = keccak256("parameterTimelock");

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    IERC20 public immutable SUP_TOKEN;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    uint256 public minimumBond;
    /// @inheritdoc IValidatorBonding
    uint256 public unbondingPeriod;
    /// @inheritdoc IValidatorBonding
    uint256 public parameterTimelock;

    mapping(address operator => BondRecord) private _bonds;
    EnumerableSet.AddressSet private _operators;

    /// @dev Pre-committed approval for each operator (for bondFor)
    mapping(address operator => BondForApproval) private _bondForApprovals;

    /// @dev Pending parameter changes: key => (value, effectiveTime)
    mapping(bytes32 key => uint256 value) private _pendingValues;
    mapping(bytes32 key => uint256 effectiveTime) private _pendingEffectiveTimes;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address supToken_,
        uint256 minimumBond_,
        uint256 unbondingPeriod_,
        address admin_,
        address governor_
    ) {
        if (supToken_ == address(0) || admin_ == address(0) || governor_ == address(0)) {
            revert INVALID_ADDRESS();
        }
        if (minimumBond_ < MIN_MINIMUM_BOND || minimumBond_ > MAX_MINIMUM_BOND) {
            revert INVALID_MINIMUM_BOND();
        }
        if (unbondingPeriod_ < MIN_UNBONDING_PERIOD || unbondingPeriod_ > MAX_UNBONDING_PERIOD) {
            revert INVALID_UNBONDING_PERIOD();
        }

        SUP_TOKEN = IERC20(supToken_);
        minimumBond = minimumBond_;
        unbondingPeriod = unbondingPeriod_;
        parameterTimelock = DEFAULT_PARAMETER_TIMELOCK;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GOVERNOR_ROLE, governor_);
    }

    /*//////////////////////////////////////////////////////////////
                               BONDING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    function bond(uint256 amount, address beneficiary, address delegateKey) external {
        _bondFor(msg.sender, amount, beneficiary, delegateKey);
    }

    /// @inheritdoc IValidatorBonding
    function bondFor(address operator, uint256 amount) external {
        BondForApproval memory approval = _bondForApprovals[operator];
        if (approval.bonder != msg.sender) revert NOT_APPROVED_BONDER();
        delete _bondForApprovals[operator];
        _bondFor(operator, amount, approval.beneficiary, approval.delegateKey);
    }

    /// @inheritdoc IValidatorBonding
    function approveBondFor(address bonder, address beneficiary, address delegateKey) external {
        if (bonder == address(0) || beneficiary == address(0) || delegateKey == address(0)) {
            revert INVALID_ADDRESS();
        }
        _bondForApprovals[msg.sender] = BondForApproval(bonder, beneficiary, delegateKey);
        emit BondForApproved(msg.sender, bonder, beneficiary, delegateKey);
    }

    /// @inheritdoc IValidatorBonding
    function revokeBondForApproval() external {
        delete _bondForApprovals[msg.sender];
        emit BondForApprovalRevoked(msg.sender);
    }


    /// @inheritdoc IValidatorBonding
    function addBond(address operator, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();

        BondRecord storage bond_ = _bonds[operator];
        _onlyOperatorOrBeneficiary(bond_, operator);

        // Allow addBond for Bonded, Unbonding, or Unbonded-with-residual
        bool hasResidual = bond_.status == ValidatorStatus.Unbonded && bond_.amount > 0;
        if (bond_.status != ValidatorStatus.Bonded && bond_.status != ValidatorStatus.Unbonding && !hasResidual) {
            revert INVALID_STATUS();
        }

        // Effects
        bond_.amount += amount;

        // Recovery path: Unbonded with residual → if now >= minimum, re-activate
        if (hasResidual && bond_.amount >= minimumBond) {
            bond_.status = ValidatorStatus.Bonded;
            _operators.add(operator);
        }

        emit BondAdded(operator, msg.sender, amount, bond_.amount);

        // Interactions
        SUP_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IValidatorBonding
    function updateDelegateKey(address operator, address newKey) external nonReentrant {
        if (newKey == address(0)) revert INVALID_ADDRESS();

        BondRecord storage bond_ = _bonds[operator];
        _onlyOperatorOrBeneficiary(bond_, operator);

        if (bond_.status == ValidatorStatus.Unbonded && bond_.amount == 0) {
            revert INVALID_STATUS();
        }

        address oldKey = bond_.delegateKey;
        bond_.delegateKey = newKey;

        emit DelegateKeyUpdated(operator, oldKey, newKey);
    }

    /*//////////////////////////////////////////////////////////////
                              UNBONDING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    function requestUnbond(address operator, uint256 amount) external nonReentrant {
        if (amount == 0) revert ZERO_AMOUNT();

        BondRecord storage bond_ = _bonds[operator];
        _onlyOperatorOrBeneficiary(bond_, operator);

        // Allow unbonding from Bonded, Unbonding (if no pending), or Unbonded with residual
        bool hasResidual = bond_.status == ValidatorStatus.Unbonded && bond_.amount > 0;
        if (bond_.status != ValidatorStatus.Bonded && bond_.status != ValidatorStatus.Unbonding && !hasResidual) {
            revert INVALID_STATUS();
        }
        if (bond_.unbondingAmount > 0) revert PENDING_UNBOND_EXISTS();
        if (amount > bond_.amount) revert EXCEEDS_BOND_AMOUNT();

        // Partial unbond: remaining must be >= minimumBond (skip check for Unbonded residual withdrawal)
        if (!hasResidual && amount < bond_.amount) {
            if (bond_.amount - amount < minimumBond) revert BELOW_MINIMUM_BOND();
        }

        // Effects
        uint256 deadline = block.timestamp + unbondingPeriod;
        bond_.unbondingAmount = amount;
        bond_.unbondingDeadline = SafeCast.toUint48(deadline);
        bond_.unbondingInitiator = msg.sender;

        if (amount == bond_.amount) {
            bond_.status = ValidatorStatus.Unbonding;
        }

        emit UnbondRequested(operator, amount, deadline);
    }

    /// @inheritdoc IValidatorBonding
    function executeUnbond(address operator) external nonReentrant {
        BondRecord storage bond_ = _bonds[operator];
        _onlyOperatorOrBeneficiary(bond_, operator);

        if (bond_.unbondingAmount == 0) revert NO_PENDING_UNBOND();
        if (block.timestamp < bond_.unbondingDeadline) revert UNBONDING_NOT_COMPLETE();

        // Effects
        uint256 amount = bond_.unbondingAmount;
        address beneficiary = bond_.beneficiary;

        bond_.amount -= amount;
        bond_.unbondingAmount = 0;
        bond_.unbondingDeadline = 0;
        bond_.unbondingInitiator = address(0);

        if (bond_.amount == 0) {
            bond_.status = ValidatorStatus.Unbonded;
            _operators.remove(operator);
        } else if (bond_.amount >= minimumBond) {
            bond_.status = ValidatorStatus.Bonded;
        } else {
            // Residual below minimum (e.g. addBond during unbonding added < minimumBond)
            bond_.status = ValidatorStatus.Unbonded;
            _operators.remove(operator);
        }

        emit UnbondExecuted(operator, beneficiary, amount);

        // Interactions
        SUP_TOKEN.safeTransfer(beneficiary, amount);
    }

    /// @inheritdoc IValidatorBonding
    function cancelUnbond(address operator) external nonReentrant {
        BondRecord storage bond_ = _bonds[operator];
        if (bond_.unbondingAmount == 0) revert NO_PENDING_UNBOND();
        _onlyOperatorOrBeneficiary(bond_, operator);

        uint256 amount = bond_.unbondingAmount;

        bond_.unbondingAmount = 0;
        bond_.unbondingDeadline = 0;
        bond_.unbondingInitiator = address(0);

        // If was full unbond, restore to Bonded
        if (bond_.status == ValidatorStatus.Unbonding) {
            bond_.status = ValidatorStatus.Bonded;
        }

        emit UnbondCancelled(operator, amount);
    }

    /*//////////////////////////////////////////////////////////////
                              SLASHING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    /// @dev Operates on any non-zero bond.amount regardless of status. An Unbonded operator with residual
    ///      tokens (e.g. from a prior partial slash) can still be slashed since those tokens are real capital.
    function slash(
        address operator,
        uint256 amount,
        address recipient
    )
        external
        onlyRole(GOVERNOR_ROLE)
        nonReentrant
    {
        if (recipient == address(0)) revert INVALID_ADDRESS();
        if (amount == 0) revert ZERO_AMOUNT();

        BondRecord storage bond_ = _bonds[operator];
        if (bond_.amount == 0) revert NOTHING_TO_SLASH();

        // Cap to total bond
        if (amount > bond_.amount) {
            amount = bond_.amount;
        }

        // Proportional slash across bonded and unbonding portions (round up against operator)
        if (bond_.unbondingAmount > 0) {
            uint256 slashFromUnbonding =
                Math.mulDiv(amount, bond_.unbondingAmount, bond_.amount, Math.Rounding.Ceil);
            // Cap to actual unbonding amount (ceil rounding could exceed)
            if (slashFromUnbonding > bond_.unbondingAmount) {
                slashFromUnbonding = bond_.unbondingAmount;
            }
            bond_.unbondingAmount -= slashFromUnbonding;
        }

        bond_.amount -= amount;

        // Post-slash state transitions
        if (bond_.amount < minimumBond) {
            bond_.status = ValidatorStatus.Unbonded;
            _operators.remove(operator);

            // Reset unbonding state when slash pushes below minimum
            if (bond_.unbondingAmount > 0) {
                bond_.unbondingAmount = 0;
                bond_.unbondingDeadline = 0;
                bond_.unbondingInitiator = address(0);
            }
        }

        emit Slashed(operator, amount, recipient, bond_.amount);

        // Interactions
        SUP_TOKEN.safeTransfer(recipient, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    /// @dev Re-proposing while a previous proposal is pending silently replaces it and resets the
    ///      timelock clock. This is accepted under the trusted multisig governance model.
    function proposeMinimumBond(uint256 newMinimum) external onlyRole(GOVERNOR_ROLE) {
        if (newMinimum < MIN_MINIMUM_BOND || newMinimum > MAX_MINIMUM_BOND) {
            revert INVALID_MINIMUM_BOND();
        }
        if (_pendingEffectiveTimes[MINIMUM_BOND_KEY] != 0) {
            emit ParameterChangeCancelled(MINIMUM_BOND_KEY);
        }
        uint256 effectiveTime = block.timestamp + parameterTimelock;
        _pendingValues[MINIMUM_BOND_KEY] = newMinimum;
        _pendingEffectiveTimes[MINIMUM_BOND_KEY] = effectiveTime;
        emit MinimumBondProposed(minimumBond, newMinimum, effectiveTime);
    }

    /// @inheritdoc IValidatorBonding
    function executeMinimumBondUpdate() external {
        uint256 effectiveTime = _pendingEffectiveTimes[MINIMUM_BOND_KEY];
        if (effectiveTime == 0) revert NO_PENDING_CHANGE();
        if (block.timestamp < effectiveTime) revert TIMELOCK_NOT_EXPIRED();

        uint256 oldMinimum = minimumBond;
        minimumBond = _pendingValues[MINIMUM_BOND_KEY];

        delete _pendingValues[MINIMUM_BOND_KEY];
        delete _pendingEffectiveTimes[MINIMUM_BOND_KEY];

        emit MinimumBondUpdated(oldMinimum, minimumBond);
    }

    /// @inheritdoc IValidatorBonding
    /// @dev Re-proposing while a previous proposal is pending silently replaces it and resets the
    ///      timelock clock. This is accepted under the trusted multisig governance model.
    function proposeUnbondingPeriod(uint256 newPeriod) external onlyRole(GOVERNOR_ROLE) {
        if (newPeriod < MIN_UNBONDING_PERIOD || newPeriod > MAX_UNBONDING_PERIOD) {
            revert INVALID_UNBONDING_PERIOD();
        }
        if (_pendingEffectiveTimes[UNBONDING_PERIOD_KEY] != 0) {
            emit ParameterChangeCancelled(UNBONDING_PERIOD_KEY);
        }
        uint256 effectiveTime = block.timestamp + parameterTimelock;
        _pendingValues[UNBONDING_PERIOD_KEY] = newPeriod;
        _pendingEffectiveTimes[UNBONDING_PERIOD_KEY] = effectiveTime;
        emit UnbondingPeriodProposed(unbondingPeriod, newPeriod, effectiveTime);
    }

    /// @inheritdoc IValidatorBonding
    function executeUnbondingPeriodUpdate() external {
        uint256 effectiveTime = _pendingEffectiveTimes[UNBONDING_PERIOD_KEY];
        if (effectiveTime == 0) revert NO_PENDING_CHANGE();
        if (block.timestamp < effectiveTime) revert TIMELOCK_NOT_EXPIRED();

        uint256 oldPeriod = unbondingPeriod;
        unbondingPeriod = _pendingValues[UNBONDING_PERIOD_KEY];

        delete _pendingValues[UNBONDING_PERIOD_KEY];
        delete _pendingEffectiveTimes[UNBONDING_PERIOD_KEY];

        emit UnbondingPeriodUpdated(oldPeriod, unbondingPeriod);
    }

    /// @inheritdoc IValidatorBonding
    function cancelProposedChange(bytes32 paramKey) external {
        if (paramKey == PARAMETER_TIMELOCK_KEY) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        } else {
            _checkRole(GOVERNOR_ROLE);
        }
        if (_pendingEffectiveTimes[paramKey] == 0) revert NO_PENDING_CHANGE();

        delete _pendingValues[paramKey];
        delete _pendingEffectiveTimes[paramKey];

        emit ParameterChangeCancelled(paramKey);
    }

    /// @inheritdoc IValidatorBonding
    /// @dev Re-proposing while a previous proposal is pending silently replaces it and resets the
    ///      timelock clock. This is accepted under the trusted multisig governance model.
    function proposeParameterTimelock(uint256 newTimelock) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTimelock < MIN_PARAMETER_TIMELOCK || newTimelock > MAX_PARAMETER_TIMELOCK) {
            revert INVALID_PARAMETER_TIMELOCK();
        }
        if (_pendingEffectiveTimes[PARAMETER_TIMELOCK_KEY] != 0) {
            emit ParameterChangeCancelled(PARAMETER_TIMELOCK_KEY);
        }
        uint256 effectiveTime = block.timestamp + parameterTimelock;
        _pendingValues[PARAMETER_TIMELOCK_KEY] = newTimelock;
        _pendingEffectiveTimes[PARAMETER_TIMELOCK_KEY] = effectiveTime;
        emit ParameterTimelockProposed(parameterTimelock, newTimelock, effectiveTime);
    }

    /// @inheritdoc IValidatorBonding
    function executeParameterTimelockUpdate() external {
        uint256 effectiveTime = _pendingEffectiveTimes[PARAMETER_TIMELOCK_KEY];
        if (effectiveTime == 0) revert NO_PENDING_CHANGE();
        if (block.timestamp < effectiveTime) revert TIMELOCK_NOT_EXPIRED();

        uint256 oldTimelock = parameterTimelock;
        parameterTimelock = _pendingValues[PARAMETER_TIMELOCK_KEY];

        delete _pendingValues[PARAMETER_TIMELOCK_KEY];
        delete _pendingEffectiveTimes[PARAMETER_TIMELOCK_KEY];

        emit ParameterTimelockUpdated(oldTimelock, parameterTimelock);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
    function isBonded(address operator) external view returns (bool) {
        BondRecord storage bond_ = _bonds[operator];
        if (bond_.status != ValidatorStatus.Bonded || bond_.unbondingAmount > bond_.amount) return false;
        return (bond_.amount - bond_.unbondingAmount) >= minimumBond;
    }

    /// @inheritdoc IValidatorBonding
    function getBond(address operator) external view returns (BondRecord memory) {
        return _bonds[operator];
    }

    /// @inheritdoc IValidatorBonding
    function getOperators() external view returns (address[] memory) {
        return _operators.values();
    }

    /// @inheritdoc IValidatorBonding
    function getActiveOperators() external view returns (address[] memory) {
        uint256 len = _operators.length();
        uint256 _minimumBond = minimumBond;
        address[] memory active = new address[](len);
        uint256 count;
        for (uint256 i; i < len; ++i) {
            address op = _operators.at(i);
            BondRecord storage bond_ = _bonds[op];
            if (
                bond_.status == ValidatorStatus.Bonded && bond_.unbondingAmount <= bond_.amount
                    && (bond_.amount - bond_.unbondingAmount) >= _minimumBond
            ) {
                active[count++] = op;
            }
        }
        assembly {
            mstore(active, count)
        }
        return active;
    }

    /// @inheritdoc IValidatorBonding
    function getOperatorCount() external view returns (uint256) {
        return _operators.length();
    }

    /// @inheritdoc IValidatorBonding
    function getBondForApproval(address operator) external view returns (BondForApproval memory) {
        return _bondForApprovals[operator];
    }

    /// @inheritdoc IValidatorBonding
    function getPendingChange(bytes32 key) external view returns (uint256 value, uint256 effectiveTime) {
        return (_pendingValues[key], _pendingEffectiveTimes[key]);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal implementation for initial bond creation
    /// @dev Validates inputs, creates a new BondRecord, transfers sUP from msg.sender
    /// @param operator The operator address to bond for
    /// @param amount Amount of sUP to bond (must be >= minimumBond)
    /// @param beneficiary Address that receives sUP on unbond
    /// @param delegateKey Validator's signing key for off-chain coordination
    function _bondFor(
        address operator,
        uint256 amount,
        address beneficiary,
        address delegateKey
    )
        internal
        nonReentrant
    {
        if (operator == address(0) || beneficiary == address(0) || delegateKey == address(0)) {
            revert INVALID_ADDRESS();
        }
        if (amount < minimumBond) revert BELOW_MINIMUM_BOND();

        BondRecord storage bond_ = _bonds[operator];

        // Cannot re-bond an existing operator — must fully unbond first
        if (bond_.status != ValidatorStatus.Unbonded) revert ALREADY_BONDED();
        // Has residual bond from partial slash — must use addBond() or withdraw first
        if (bond_.amount > 0) revert ALREADY_BONDED();

        // Effects
        bond_.amount = amount;
        bond_.beneficiary = beneficiary;
        bond_.delegateKey = delegateKey;
        bond_.status = ValidatorStatus.Bonded;
        _operators.add(operator);

        emit Bonded(operator, beneficiary, msg.sender, delegateKey, amount);

        // Interactions
        SUP_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Reverts if msg.sender is neither the operator nor the beneficiary
    /// @param bond_ The bond record to check against
    /// @param operator The operator address
    function _onlyOperatorOrBeneficiary(BondRecord storage bond_, address operator) internal view {
        if (msg.sender != operator && msg.sender != bond_.beneficiary) {
            revert NOT_OPERATOR_OR_BENEFICIARY();
        }
    }
}
