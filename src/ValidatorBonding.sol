// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IValidatorBonding } from "./interfaces/IValidatorBonding.sol";

/// @title ValidatorBonding
/// @author Superform Labs
/// @notice Standalone sUP bonding module for Superform validators (Base only)
/// @dev Non-upgradeable. Operator/beneficiary separation supports Foundation loans.
///      sUP is the share token of a SuperVault whose asset is UP. ReentrancyGuard is defense-in-depth.
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

    /// @dev Approved bonder for each operator (for bondFor)
    mapping(address operator => address approvedBonder) private _bondForApprovals;

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
    function bondFor(address operator, uint256 amount, address beneficiary, address delegateKey) external {
        if (_bondForApprovals[operator] != msg.sender) revert NOT_APPROVED_BONDER();
        _bondFor(operator, amount, beneficiary, delegateKey);
    }

    /// @inheritdoc IValidatorBonding
    function approveBondFor(address bonder) external {
        if (bonder == address(0)) revert INVALID_ADDRESS();
        _bondForApprovals[msg.sender] = bonder;
        emit BondForApproved(msg.sender, bonder);
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
        bond_.unbondingDeadline = uint48(deadline);
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
        } else {
            bond_.status = ValidatorStatus.Bonded;
        }

        // Interactions
        SUP_TOKEN.safeTransfer(beneficiary, amount);

        emit UnbondExecuted(operator, beneficiary, amount);
    }

    /// @inheritdoc IValidatorBonding
    function cancelUnbond(address operator) external nonReentrant {
        BondRecord storage bond_ = _bonds[operator];
        if (bond_.unbondingAmount == 0) revert NO_PENDING_UNBOND();
        if (msg.sender != bond_.unbondingInitiator) revert NOT_UNBOND_INITIATOR();

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

        // Interactions
        SUP_TOKEN.safeTransfer(recipient, amount);

        emit Slashed(operator, amount, recipient, bond_.amount);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValidatorBonding
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
    function cancelProposedChange(bytes32 paramKey) external onlyRole(GOVERNOR_ROLE) {
        if (_pendingEffectiveTimes[paramKey] == 0) revert NO_PENDING_CHANGE();

        delete _pendingValues[paramKey];
        delete _pendingEffectiveTimes[paramKey];

        emit ParameterChangeCancelled(paramKey);
    }

    /// @inheritdoc IValidatorBonding
    function setParameterTimelock(uint256 newTimelock) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTimelock < MIN_PARAMETER_TIMELOCK || newTimelock > MAX_PARAMETER_TIMELOCK) {
            revert INVALID_PARAMETER_TIMELOCK();
        }
        uint256 oldTimelock = parameterTimelock;
        parameterTimelock = newTimelock;
        emit ParameterTimelockUpdated(oldTimelock, newTimelock);
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
        address[] memory active = new address[](len);
        uint256 count;
        for (uint256 i; i < len; ++i) {
            address op = _operators.at(i);
            BondRecord storage bond_ = _bonds[op];
            if (
                bond_.status == ValidatorStatus.Bonded && bond_.unbondingAmount <= bond_.amount
                    && (bond_.amount - bond_.unbondingAmount) >= minimumBond
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
    function getBondForApproval(address operator) external view returns (address) {
        return _bondForApprovals[operator];
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
