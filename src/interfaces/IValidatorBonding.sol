// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IValidatorBonding
/// @author Superform Labs
/// @notice Interface for the ValidatorBonding contract — standalone sUP bonding module for validators
interface IValidatorBonding is IAccessControl {
    /*//////////////////////////////////////////////////////////////
                                  ENUMS
    //////////////////////////////////////////////////////////////*/

    /// @notice Status of a validator's bond
    enum ValidatorStatus {
        Unbonded, // Not bonded or fully withdrawn
        Bonded, // Active bond >= minimumBond
        Unbonding // Full unbond requested, in cooldown
    }

    /*//////////////////////////////////////////////////////////////
                                  STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Record of a validator's bond (packed: 5 storage slots)
    /// @param amount Total sUP held (includes unbondingAmount until executeUnbond)
    /// @param beneficiary Who receives sUP on unbond. Immutable for the lifetime of the bond — the only
    ///        way to change beneficiary is a full unbond → wait unbondingPeriod → executeUnbond → re-bond cycle.
    ///        If the beneficiary key is compromised, the operator cannot fast-path redirect exit tokens.
    /// @param unbondingDeadline Timestamp after which executeUnbond succeeds (0 = no pending unbond)
    /// @param status Current validator status. WARNING: status == Bonded does NOT guarantee isBonded() == true.
    ///        After a slash during unbonding followed by executeUnbond, an operator may have status == Bonded
    ///        but amount < minimumBond. Always use isBonded() for active-bond checks.
    /// @param delegateKey Validator's signing key for off-chain coordination
    /// @param unbondingAmount Portion of amount being unbonded
    /// @param unbondingInitiator Who called requestUnbond (only they can cancelUnbond)
    struct BondRecord {
        uint256 amount; // slot 0
        address beneficiary; // slot 1: 20 bytes
        uint48 unbondingDeadline; // slot 1: 6 bytes
        ValidatorStatus status; // slot 1: 1 byte
        address delegateKey; // slot 2: 20 bytes
        uint256 unbondingAmount; // slot 3
        address unbondingInitiator; // slot 4
    }

    /*//////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when providing a zero address where a valid address is required
    error INVALID_ADDRESS();
    /// @notice Thrown when providing a zero amount where a non-zero amount is required
    error ZERO_AMOUNT();
    /// @notice Thrown when the operator's status does not allow the requested action
    error INVALID_STATUS();
    /// @notice Thrown when the bond amount is below the minimum required
    error BELOW_MINIMUM_BOND();
    /// @notice Thrown when trying to bond for an operator that already has an active bond
    error ALREADY_BONDED();
    /// @notice Thrown when trying to execute or cancel an unbond with no pending unbond
    error NO_PENDING_UNBOND();
    /// @notice Thrown when trying to request unbond while one is already pending
    error PENDING_UNBOND_EXISTS();
    /// @notice Thrown when trying to execute unbond before the deadline has passed
    error UNBONDING_NOT_COMPLETE();
    /// @notice Thrown when caller is not the operator or beneficiary
    error NOT_OPERATOR_OR_BENEFICIARY();
    /// @notice Thrown when caller is not the unbond initiator (for cancelUnbond)
    error NOT_UNBOND_INITIATOR();
    /// @notice Thrown when trying to slash an operator with zero bond
    error NOTHING_TO_SLASH();
    /// @notice Thrown when providing an invalid minimum bond value (out of bounds)
    error INVALID_MINIMUM_BOND();
    /// @notice Thrown when providing an invalid unbonding period (out of bounds)
    error INVALID_UNBONDING_PERIOD();
    /// @notice Thrown when the unbond amount exceeds the operator's total bond
    error EXCEEDS_BOND_AMOUNT();
    /// @notice Thrown when caller is not an approved bonder for the operator
    error NOT_APPROVED_BONDER();
    /// @notice Thrown when no parameter change is pending
    error NO_PENDING_CHANGE();
    /// @notice Thrown when the parameter timelock has not expired
    error TIMELOCK_NOT_EXPIRED();
    /// @notice Thrown when the parameter timelock value is out of bounds
    error INVALID_PARAMETER_TIMELOCK();

    /*//////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an operator bonds sUP
    /// @param operator The operator address
    /// @param beneficiary The beneficiary address (receives sUP on unbond)
    /// @param funder The address that provided the sUP tokens
    /// @param delegateKey The validator's signing key
    /// @param amount The amount of sUP bonded
    event Bonded(
        address indexed operator, address indexed beneficiary, address funder, address delegateKey, uint256 amount
    );

    /// @notice Emitted when additional sUP is added to an existing bond
    /// @param operator The operator address
    /// @param funder The address that provided the sUP tokens
    /// @param amount The additional amount bonded
    /// @param newTotal The new total bond amount
    event BondAdded(address indexed operator, address funder, uint256 amount, uint256 newTotal);

    /// @notice Emitted when an unbond is requested
    /// @param operator The operator address
    /// @param amount The amount being unbonded
    /// @param unbondingDeadline The timestamp after which executeUnbond succeeds
    event UnbondRequested(address indexed operator, uint256 amount, uint256 unbondingDeadline);

    /// @notice Emitted when a pending unbond is cancelled
    /// @param operator The operator address
    /// @param amount The amount that was being unbonded
    event UnbondCancelled(address indexed operator, uint256 amount);

    /// @notice Emitted when an unbond is executed and sUP is transferred to beneficiary
    /// @param operator The operator address
    /// @param beneficiary The beneficiary who received the sUP
    /// @param amount The amount of sUP transferred
    event UnbondExecuted(address indexed operator, address indexed beneficiary, uint256 amount);

    /// @notice Emitted when an operator is slashed
    /// @param operator The operator address
    /// @param amount The amount slashed
    /// @param recipient The recipient of slashed sUP
    /// @param remainingBond The operator's remaining bond after slash
    event Slashed(address indexed operator, uint256 amount, address indexed recipient, uint256 remainingBond);

    /// @notice Emitted when an operator's delegate key is updated
    /// @param operator The operator address
    /// @param oldKey The previous delegate key
    /// @param newKey The new delegate key
    event DelegateKeyUpdated(address indexed operator, address oldKey, address newKey);

    /// @notice Emitted when a minimum bond update is proposed
    /// @param currentMinimum The current minimum bond
    /// @param proposedMinimum The proposed new minimum bond
    /// @param effectiveTime The timestamp when the change can be executed
    event MinimumBondProposed(uint256 currentMinimum, uint256 proposedMinimum, uint256 effectiveTime);

    /// @notice Emitted when the minimum bond is updated (after timelock)
    /// @param oldMinimum The previous minimum bond
    /// @param newMinimum The new minimum bond
    event MinimumBondUpdated(uint256 oldMinimum, uint256 newMinimum);

    /// @notice Emitted when an unbonding period update is proposed
    /// @param currentPeriod The current unbonding period
    /// @param proposedPeriod The proposed new unbonding period
    /// @param effectiveTime The timestamp when the change can be executed
    event UnbondingPeriodProposed(uint256 currentPeriod, uint256 proposedPeriod, uint256 effectiveTime);

    /// @notice Emitted when the unbonding period is updated (after timelock)
    /// @param oldPeriod The previous unbonding period
    /// @param newPeriod The new unbonding period
    event UnbondingPeriodUpdated(uint256 oldPeriod, uint256 newPeriod);

    /// @notice Emitted when a pending parameter change is cancelled
    /// @param paramKey The parameter key that was cancelled
    event ParameterChangeCancelled(bytes32 indexed paramKey);

    /// @notice Emitted when the parameter timelock is updated
    /// @param oldTimelock The previous timelock duration
    /// @param newTimelock The new timelock duration
    event ParameterTimelockUpdated(uint256 oldTimelock, uint256 newTimelock);

    /// @notice Emitted when an operator approves a bonder for bondFor()
    /// @param operator The operator granting approval
    /// @param bonder The approved bonder address
    event BondForApproved(address indexed operator, address indexed bonder);

    /// @notice Emitted when an operator revokes bondFor approval
    /// @param operator The operator revoking approval
    event BondForApprovalRevoked(address indexed operator);

    /*//////////////////////////////////////////////////////////////
                          BONDING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Bond sUP as the calling operator
    /// @param amount Amount of sUP to bond (must be >= minimumBond)
    /// @param beneficiary Address that receives sUP on unbond (immutable during active bond)
    /// @param delegateKey Validator's signing key for off-chain coordination
    function bond(uint256 amount, address beneficiary, address delegateKey) external;

    /// @notice Bond sUP on behalf of an operator (requires prior approval via approveBondFor)
    /// @param operator The operator address
    /// @param amount Amount of sUP to bond (must be >= minimumBond)
    /// @param beneficiary Address that receives sUP on unbond (immutable during active bond)
    /// @param delegateKey Validator's signing key for off-chain coordination
    function bondFor(address operator, uint256 amount, address beneficiary, address delegateKey) external;

    /// @notice Approve an address to call bondFor on behalf of msg.sender
    /// @param bonder The address to approve as a bonder
    function approveBondFor(address bonder) external;

    /// @notice Revoke bondFor approval for msg.sender
    function revokeBondForApproval() external;

    /// @notice Add more sUP to an existing bond
    /// @dev Allowed in Bonded, Unbonding, or Unbonded-with-residual status. Only operator or beneficiary.
    ///      NOTE: Adding bond while in Unbonding status does NOT cancel the pending unbond. The added tokens
    ///      increase the total amount but the unbondingAmount stays unchanged. After executeUnbond(), the
    ///      newly added tokens remain in the bond.
    /// @param operator The operator to add bond for
    /// @param amount Amount of sUP to add
    function addBond(address operator, uint256 amount) external;

    /// @notice Update the delegate key for an operator
    /// @dev Callable by operator or beneficiary
    /// @param operator The operator to update
    /// @param newKey The new delegate key
    function updateDelegateKey(address operator, address newKey) external;

    /*//////////////////////////////////////////////////////////////
                         UNBONDING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Request unbonding of sUP (partial or full)
    /// @dev Callable by operator or beneficiary
    /// @param operator The operator to unbond
    /// @param amount Amount to unbond (partial: remaining must be >= minimumBond)
    function requestUnbond(address operator, uint256 amount) external;

    /// @notice Execute a pending unbond after the deadline has passed
    /// @dev Transfers unbondingAmount to beneficiary
    /// @param operator The operator whose unbond to execute
    function executeUnbond(address operator) external;

    /// @notice Cancel a pending unbond
    /// @dev Only callable by the address that initiated the unbond
    /// @param operator The operator whose unbond to cancel
    function cancelUnbond(address operator) external;

    /*//////////////////////////////////////////////////////////////
                         SLASHING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Slash an operator's bond
    /// @dev Only callable by GOVERNOR_ROLE. Slash is proportional across bonded + unbonding portions.
    /// @param operator The operator to slash
    /// @param amount Amount to slash (capped to bond.amount)
    /// @param recipient Address to receive slashed sUP
    function slash(address operator, uint256 amount, address recipient) external;

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Propose a new minimum bond (subject to timelock)
    /// @dev Only callable by GOVERNOR_ROLE
    /// @param newMinimum The proposed minimum bond (bounded by MIN_MINIMUM_BOND and MAX_MINIMUM_BOND)
    function proposeMinimumBond(uint256 newMinimum) external;

    /// @notice Execute a pending minimum bond update after timelock expires
    /// @dev Permissionless after timelock
    function executeMinimumBondUpdate() external;

    /// @notice Propose a new unbonding period (subject to timelock)
    /// @dev Only callable by GOVERNOR_ROLE
    /// @param newPeriod The proposed unbonding period (bounded by MIN_UNBONDING_PERIOD and MAX_UNBONDING_PERIOD)
    function proposeUnbondingPeriod(uint256 newPeriod) external;

    /// @notice Execute a pending unbonding period update after timelock expires
    /// @dev Permissionless after timelock
    function executeUnbondingPeriodUpdate() external;

    /// @notice Cancel a pending parameter change
    /// @dev Only callable by GOVERNOR_ROLE
    /// @param paramKey The parameter key to cancel (MINIMUM_BOND_KEY or UNBONDING_PERIOD_KEY)
    function cancelProposedChange(bytes32 paramKey) external;

    /// @notice Update the parameter timelock duration
    /// @dev Only callable by DEFAULT_ADMIN_ROLE
    /// @param newTimelock The new timelock duration
    function setParameterTimelock(uint256 newTimelock) external;

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if an operator is actively bonded with sufficient capital
    /// @dev Returns true if status == Bonded AND effective balance >= minimumBond
    /// @param operator The operator to check
    /// @return True if the operator is actively bonded
    function isBonded(address operator) external view returns (bool);

    /// @notice Get the full bond record for an operator
    /// @dev WARNING: Do not use record.status alone to determine active-bond status. Use isBonded() instead.
    /// @param operator The operator to query
    /// @return The operator's BondRecord
    function getBond(address operator) external view returns (BondRecord memory);

    /// @notice Get all operators in the registry (Bonded + Unbonding)
    /// @return Array of operator addresses
    function getOperators() external view returns (address[] memory);

    /// @notice Get only actively bonded operators (status == Bonded, effective balance >= minimumBond)
    /// @return Array of actively bonded operator addresses
    function getActiveOperators() external view returns (address[] memory);

    /// @notice Get the count of operators in the registry
    /// @return Number of operators
    function getOperatorCount() external view returns (uint256);

    /// @notice Get the approved bonder for an operator
    /// @param operator The operator to query
    /// @return The approved bonder address (address(0) if none)
    function getBondForApproval(address operator) external view returns (address);

    /// @notice The identifier of the role that grants access to slashing and parameter updates
    function GOVERNOR_ROLE() external pure returns (bytes32);

    /// @notice The sUP token used for bonding
    function SUP_TOKEN() external view returns (IERC20);

    /// @notice Upper bound for the minimum bond parameter
    function MAX_MINIMUM_BOND() external pure returns (uint256);

    /// @notice Lower bound for the minimum bond parameter
    function MIN_MINIMUM_BOND() external pure returns (uint256);

    /// @notice Upper bound for the unbonding period parameter
    function MAX_UNBONDING_PERIOD() external pure returns (uint256);

    /// @notice Lower bound for the unbonding period parameter
    function MIN_UNBONDING_PERIOD() external pure returns (uint256);

    /// @notice The minimum amount of sUP required for an active bond
    function minimumBond() external view returns (uint256);

    /// @notice The cooldown period in seconds before an unbond can be executed
    function unbondingPeriod() external view returns (uint256);

    /// @notice The timelock duration for parameter changes
    function parameterTimelock() external view returns (uint256);

    /// @notice Default parameter timelock duration
    function DEFAULT_PARAMETER_TIMELOCK() external pure returns (uint256);

    /// @notice Minimum parameter timelock duration
    function MIN_PARAMETER_TIMELOCK() external pure returns (uint256);

    /// @notice Maximum parameter timelock duration
    function MAX_PARAMETER_TIMELOCK() external pure returns (uint256);

    /// @notice Key for minimum bond parameter changes
    function MINIMUM_BOND_KEY() external pure returns (bytes32);

    /// @notice Key for unbonding period parameter changes
    function UNBONDING_PERIOD_KEY() external pure returns (bytes32);
}
