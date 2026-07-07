// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { IManagedSuperVaultAggregator } from "../interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultController } from "../interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { IManagedSuperVaultExecutor } from "../interfaces/ManagedSuperVault/IManagedSuperVaultExecutor.sol";
import { PackedUserOperation } from "../vendor/erc4337/PackedUserOperation.sol";
import { IAccount } from "../vendor/erc4337/IAccount.sol";

/// @title ManagedSuperVaultExecutor
/// @author Superform Labs
/// @notice Secondary manager contract that allows session key holders to call Managed Vault controller
///         functions with scoped permissions, expiries, and generation invalidation. Mirrors the
///         SuperVaultExecutor pattern with managed-specific permissions.
/// @dev Deployed as a non-upgradeable singleton, added as a secondary manager on controllers
contract ManagedSuperVaultExecutor is IManagedSuperVaultExecutor, IAccount, AccessControl, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of items in a batch operation to prevent block gas limit issues
    uint256 public constant MAX_BATCH_SIZE = 50;

    /// @notice Gas limit for ETH transfers via assembly call
    uint256 internal constant ETH_TRANSFER_GAS_LIMIT = 100_000;

    /// @notice Registry key for the ManagedSuperVaultAggregator in the SuperGovernor address registry
    bytes32 public constant MANAGED_SUPER_VAULT_AGGREGATOR_KEY = keccak256("MANAGED_SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The SuperGovernor contract used to resolve the aggregator
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @notice The canonical ERC-4337 v0.7 EntryPoint address
    address public immutable ENTRY_POINT;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev controller => sessionKey => SessionKeyData
    mapping(address => mapping(address => SessionKeyData)) private _sessionKeys;

    /// @dev controller => generation counter (incremented to invalidate all session keys)
    mapping(address => uint80) private _controllerGeneration;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superGovernor_ The SuperGovernor address
    /// @param admin_ The admin address (receives DEFAULT_ADMIN_ROLE)
    /// @param entryPoint_ The canonical ERC-4337 v0.7 EntryPoint address
    constructor(address superGovernor_, address admin_, address entryPoint_) {
        if (superGovernor_ == address(0) || admin_ == address(0) || entryPoint_ == address(0)) {
            revert ZERO_ADDRESS();
        }

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        ENTRY_POINT = entryPoint_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /*//////////////////////////////////////////////////////////////
                          RECEIVE / FALLBACK
    //////////////////////////////////////////////////////////////*/

    /// @notice Accept ETH (refunds from managed call execution)
    receive() external payable { }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Restricts access to the canonical ERC-4337 EntryPoint
    modifier onlyEntryPoint() {
        if (msg.sender != ENTRY_POINT) revert ONLY_ENTRY_POINT();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        SESSION KEY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @dev WARNING: Session key validity depends on the granting manager remaining the primary manager.
    ///      If a primary manager is removed (A→B) and later reinstated (B→A), session keys previously
    ///      granted by A will silently reactivate. invalidateAllSessionKeys() must be proactively called
    ///      during the interim period to prevent stale key revival.

    /// @inheritdoc IManagedSuperVaultExecutor
    function grantSessionKey(
        address controller,
        address sessionKey,
        uint256 expiry,
        Permission[] calldata permissions
    )
        external
    {
        _validatePrimaryManager(controller);
        _grantSessionKey(controller, sessionKey, expiry, _permissionsToMask(permissions));
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function grantSessionKeysBatch(
        address[] calldata controllers,
        address[] calldata sessionKeys,
        uint256[] calldata expiries,
        Permission[][] calldata permissions
    )
        external
    {
        uint256 len = controllers.length;
        if (len == 0) revert EMPTY_ARRAY();
        if (len > MAX_BATCH_SIZE) revert BATCH_SIZE_EXCEEDED();
        if (len != sessionKeys.length || len != expiries.length || len != permissions.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        IManagedSuperVaultAggregator aggregator = _getAggregator();
        for (uint256 i; i < len; ++i) {
            _validatePrimaryManager(controllers[i], aggregator);
            _grantSessionKey(controllers[i], sessionKeys[i], expiries[i], _permissionsToMask(permissions[i]));
        }
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function revokeSessionKey(address controller, address sessionKey) external {
        _validatePrimaryManager(controller);
        _revokeSessionKey(controller, sessionKey);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function revokeSessionKeysBatch(address[] calldata controllers, address[] calldata sessionKeys) external {
        uint256 len = controllers.length;
        if (len == 0) revert EMPTY_ARRAY();
        if (len > MAX_BATCH_SIZE) revert BATCH_SIZE_EXCEEDED();
        if (len != sessionKeys.length) revert ARRAY_LENGTH_MISMATCH();

        IManagedSuperVaultAggregator aggregator = _getAggregator();
        for (uint256 i; i < len; ++i) {
            _validatePrimaryManager(controllers[i], aggregator);
            _revokeSessionKey(controllers[i], sessionKeys[i]);
        }
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function invalidateAllSessionKeys(address controller) external {
        _validatePrimaryManager(controller);
        uint80 newGeneration = ++_controllerGeneration[controller];
        emit AllSessionKeysInvalidated(controller, newGeneration);
    }

    /*//////////////////////////////////////////////////////////////
                        FORWARDING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultExecutor
    function executeManagedCall(
        address controller,
        IManagedSuperVaultController.ManagedCall calldata call,
        bytes32 operationId
    )
        external
        payable
        nonReentrant
    {
        _validateSessionKey(controller, _toBit(Permission.ExecuteCalls));
        _executeManagedCallInternal(controller, call, operationId, msg.sender);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function executeManagedBatch(
        address controller,
        IManagedSuperVaultController.ManagedCall[] calldata calls,
        bytes32 operationId
    )
        external
        payable
        nonReentrant
    {
        _validateSessionKey(controller, _toBit(Permission.ExecuteCalls));
        _executeManagedBatchInternal(controller, calls, operationId, msg.sender);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function fulfillDepositRequests(address controller, address[] calldata depositors) external nonReentrant {
        _validateSessionKey(controller, _toBit(Permission.FulfillDeposits));
        IManagedSuperVaultController(controller).fulfillDepositRequests(depositors);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function rejectDepositRequests(
        address controller,
        address[] calldata depositors,
        string calldata reason
    )
        external
        nonReentrant
    {
        _validateSessionKey(controller, _toBit(Permission.FulfillDeposits));
        IManagedSuperVaultController(controller).rejectDepositRequests(depositors, reason);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function approveDepositors(
        address controller,
        address[] calldata depositors,
        bytes32[] calldata kycRefs
    )
        external
        nonReentrant
    {
        _validateSessionKey(controller, _toBit(Permission.ManageApprovals));
        IManagedSuperVaultController(controller).approveDepositors(depositors, kycRefs);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function rejectDepositors(address controller, address[] calldata depositors) external nonReentrant {
        _validateSessionKey(controller, _toBit(Permission.ManageApprovals));
        IManagedSuperVaultController(controller).rejectDepositors(depositors);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function revokeDepositors(address controller, address[] calldata depositors) external nonReentrant {
        _validateSessionKey(controller, _toBit(Permission.ManageApprovals));
        IManagedSuperVaultController(controller).revokeDepositors(depositors);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function fulfillRedeemRequests(
        address controller,
        address[] calldata redeemControllers,
        uint256[] calldata totalAssetsOut
    )
        external
        nonReentrant
    {
        _validateSessionKey(controller, _toBit(Permission.FulfillRedeem));
        IManagedSuperVaultController(controller).fulfillRedeemRequests(redeemControllers, totalAssetsOut);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function fulfillCancelRedeemRequests(
        address controller,
        address[] calldata redeemControllers
    )
        external
        nonReentrant
    {
        _validateSessionKey(controller, _toBit(Permission.FulfillCancelRedeem));
        IManagedSuperVaultController(controller).fulfillCancelRedeemRequests(redeemControllers);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function skimPerformanceFee(address controller) external nonReentrant {
        _validateSessionKey(controller, _toBit(Permission.SkimFee));
        IManagedSuperVaultController(controller).skimPerformanceFee();
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function proposeNAVUpdate(
        address controller,
        uint256 newPPS,
        uint256 effectiveTimestamp,
        bytes32 evidenceHash,
        string calldata evidenceURI
    )
        external
        nonReentrant
        returns (uint256 proposalId)
    {
        _validateSessionKey(controller, _toBit(Permission.ProposeNAV));
        return IManagedSuperVaultController(controller)
            .proposeNAVUpdate(newPPS, effectiveTimestamp, evidenceHash, evidenceURI);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function pauseManagedVault(address controller) external nonReentrant {
        IManagedSuperVaultAggregator aggregator = _getAggregator();
        _validateSessionKey(controller, aggregator, _toBit(Permission.Pause));
        aggregator.pauseManagedVault(controller);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function unpauseManagedVault(address controller) external nonReentrant {
        IManagedSuperVaultAggregator aggregator = _getAggregator();
        _validateSessionKey(controller, aggregator, _toBit(Permission.Unpause));
        aggregator.unpauseManagedVault(controller);
    }

    /*//////////////////////////////////////////////////////////////
                      ERC-4337 COMPATIBILITY
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        override(IAccount, IManagedSuperVaultExecutor)
        onlyEntryPoint
        returns (uint256 validationData)
    {
        // 1. Assert callData targets executeFromEntryPoint
        if (userOp.callData.length < 36) revert INVALID_CALLDATA_SELECTOR();
        bytes4 selector = bytes4(userOp.callData[:4]);
        if (selector != this.executeFromEntryPoint.selector) revert INVALID_CALLDATA_SELECTOR();

        // 2. Extract controller address (first ABI-encoded parameter after selector)
        address controller = abi.decode(userOp.callData[4:36], (address));

        // 3. Recover session key from EIP-191 prefixed signature
        address sessionKey = ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(userOpHash), userOp.signature);

        // 4. Validate session key has ExecuteCalls permission
        (bool valid, uint256 expiry) =
            _isSessionKeyValidForPermission(controller, sessionKey, _toBit(Permission.ExecuteCalls));

        if (!valid) {
            return 1; // SIG_VALIDATION_FAILED
        }

        // 5. Pre-fund EntryPoint if required
        if (missingAccountFunds > 0) {
            assembly {
                pop(call(gas(), caller(), missingAccountFunds, 0, 0, 0, 0))
            }
        }

        // 6. Pack validationData: sigAuthorizer(0) | validUntil << 160 | validAfter(0) << 208
        uint48 validUntil = expiry >= type(uint48).max ? uint48(0) : uint48(expiry);
        return uint256(validUntil) << 160;
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function executeFromEntryPoint(
        address controller,
        IManagedSuperVaultController.ManagedCall[] calldata calls,
        bytes32 operationId
    )
        external
        payable
        onlyEntryPoint
        nonReentrant
    {
        // Session key was already validated in validateUserOp; refund to self (admin-sweepable)
        _executeManagedBatchInternal(controller, calls, operationId, address(this));
        emit ExecutedFromEntryPoint(controller);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultExecutor
    function sweepETH(address to) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) revert ZERO_ADDRESS();
        uint256 bal = address(this).balance;
        if (bal > 0) {
            bool success;
            uint256 gasLimit = ETH_TRANSFER_GAS_LIMIT;
            assembly {
                success := call(gasLimit, to, bal, 0, 0, 0, 0)
            }
            if (!success) revert ETH_TRANSFER_FAILED();
            emit ETHSwept(to, bal);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IManagedSuperVaultExecutor
    function isSessionKeyValid(address controller, address sessionKey) external view returns (bool) {
        SessionKeyData storage data = _sessionKeys[controller][sessionKey];
        if (data.expiry == 0 || block.timestamp > data.expiry) return false;
        if (data.generation != _controllerGeneration[controller]) return false;
        return _getAggregator().isMainManager(data.grantedByManager, controller);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function isSessionKeyValidForPermission(
        address controller,
        address sessionKey,
        Permission permission
    )
        external
        view
        returns (bool)
    {
        SessionKeyData storage data = _sessionKeys[controller][sessionKey];
        if (data.expiry == 0 || block.timestamp > data.expiry) return false;
        if (data.generation != _controllerGeneration[controller]) return false;
        if ((data.permissions & _toBit(permission)) == 0) return false;
        return _getAggregator().isMainManager(data.grantedByManager, controller);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function getSessionKeyPermissions(address controller, address sessionKey) external view returns (uint16) {
        return _sessionKeys[controller][sessionKey].permissions;
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function getSessionKeyData(
        address controller,
        address sessionKey
    )
        external
        view
        returns (uint256 expiry, address grantedByManager, uint80 generation, uint16 permissions)
    {
        SessionKeyData storage data = _sessionKeys[controller][sessionKey];
        return (data.expiry, data.grantedByManager, data.generation, data.permissions);
    }

    /// @inheritdoc IManagedSuperVaultExecutor
    function getControllerGeneration(address controller) external view returns (uint80) {
        return _controllerGeneration[controller];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Shared logic for executeManagedCall: tracks ETH balance, calls controller, refunds overpayment
    function _executeManagedCallInternal(
        address controller,
        IManagedSuperVaultController.ManagedCall calldata call,
        bytes32 operationId,
        address refundRecipient
    )
        internal
    {
        uint256 balanceBefore = address(this).balance - msg.value;
        IManagedSuperVaultController(controller).executeManagedCall{ value: msg.value }(call, operationId);
        _refundExcess(balanceBefore, refundRecipient);
    }

    /// @dev Shared logic for executeManagedBatch: tracks ETH balance, calls controller, refunds overpayment
    function _executeManagedBatchInternal(
        address controller,
        IManagedSuperVaultController.ManagedCall[] calldata calls,
        bytes32 operationId,
        address refundRecipient
    )
        internal
    {
        uint256 balanceBefore = address(this).balance - msg.value;
        IManagedSuperVaultController(controller).executeManagedBatch{ value: msg.value }(calls, operationId);
        _refundExcess(balanceBefore, refundRecipient);
    }

    /// @dev Refund any ETH above the pre-call balance to the recipient
    function _refundExcess(uint256 balanceBefore, address refundRecipient) internal {
        uint256 refund = address(this).balance - balanceBefore;

        if (refund > 0) {
            bool success;
            uint256 gasLimit = ETH_TRANSFER_GAS_LIMIT;
            assembly {
                success := call(gasLimit, refundRecipient, refund, 0, 0, 0, 0)
            }
            if (!success) revert ETH_TRANSFER_FAILED();
            emit ETHRefunded(refundRecipient, refund);
        }
    }

    /// @dev Checks session key validity and returns expiry for ERC-4337 time-bound validation
    function _isSessionKeyValidForPermission(
        address controller,
        address sessionKey,
        uint16 requiredPermission
    )
        internal
        view
        returns (bool valid, uint256 expiry)
    {
        SessionKeyData storage data = _sessionKeys[controller][sessionKey];
        if (data.expiry == 0) return (false, 0);
        if (block.timestamp > data.expiry) return (false, 0);
        if (data.generation != _controllerGeneration[controller]) return (false, 0);
        if ((data.permissions & requiredPermission) == 0) return (false, 0);
        if (!_getAggregator().isMainManager(data.grantedByManager, controller)) return (false, 0);
        return (true, data.expiry);
    }

    /// @dev Converts a single Permission enum value to its bitmask bit
    function _toBit(Permission p) internal pure returns (uint16) {
        return uint16(1 << uint8(p));
    }

    /// @dev Converts a Permission[] array to a uint16 bitmask
    function _permissionsToMask(Permission[] calldata permissions) internal pure returns (uint16 mask) {
        uint256 len = permissions.length;
        if (len == 0) revert ZERO_PERMISSIONS();
        for (uint256 i; i < len; ++i) {
            mask |= _toBit(permissions[i]);
        }
    }

    /// @dev Validates that msg.sender is the primary manager of the given controller
    function _validatePrimaryManager(address controller) internal view {
        if (!_getAggregator().isMainManager(msg.sender, controller)) {
            revert CALLER_NOT_PRIMARY_MANAGER();
        }
    }

    /// @dev Overload with pre-cached aggregator for gas-efficient batch loops
    function _validatePrimaryManager(address controller, IManagedSuperVaultAggregator aggregator) internal view {
        if (!aggregator.isMainManager(msg.sender, controller)) {
            revert CALLER_NOT_PRIMARY_MANAGER();
        }
    }

    /// @dev Validates that msg.sender holds a valid session key with the required permission
    function _validateSessionKey(address controller, uint16 requiredPermission) internal view {
        _validateSessionKey(controller, _getAggregator(), requiredPermission);
    }

    /// @dev Overload with pre-cached aggregator
    function _validateSessionKey(
        address controller,
        IManagedSuperVaultAggregator aggregator,
        uint16 requiredPermission
    )
        internal
        view
    {
        SessionKeyData storage data = _sessionKeys[controller][msg.sender];
        if (data.expiry == 0) revert SESSION_KEY_NOT_AUTHORIZED();
        if (block.timestamp > data.expiry) revert SESSION_KEY_EXPIRED();
        if (data.generation != _controllerGeneration[controller]) revert SESSION_KEY_GENERATION_MISMATCH();
        if ((data.permissions & requiredPermission) == 0) revert SESSION_KEY_PERMISSION_DENIED();
        if (!aggregator.isMainManager(data.grantedByManager, controller)) {
            revert PRIMARY_MANAGER_CHANGED();
        }
    }

    /// @dev Grants a session key for a controller at the current generation with specified permissions
    function _grantSessionKey(address controller, address sessionKey, uint256 expiry, uint16 permissions) internal {
        if (sessionKey == address(0)) revert ZERO_ADDRESS();
        if (expiry == 0) revert ZERO_EXPIRY();
        if (expiry <= block.timestamp) revert EXPIRY_IN_PAST();

        uint80 generation = _controllerGeneration[controller];
        _sessionKeys[controller][sessionKey] = SessionKeyData({
            expiry: expiry, grantedByManager: msg.sender, generation: generation, permissions: permissions
        });

        emit SessionKeyGranted(controller, sessionKey, expiry, msg.sender, generation, permissions);
    }

    /// @dev Revokes a session key for a controller (reverts if key was never granted)
    function _revokeSessionKey(address controller, address sessionKey) internal {
        if (_sessionKeys[controller][sessionKey].expiry == 0) revert SESSION_KEY_NOT_AUTHORIZED();
        delete _sessionKeys[controller][sessionKey];
        emit SessionKeyRevoked(controller, sessionKey);
    }

    /// @dev Resolves the aggregator dynamically via SuperGovernor
    function _getAggregator() internal view returns (IManagedSuperVaultAggregator) {
        return IManagedSuperVaultAggregator(SUPER_GOVERNOR.getAddress(MANAGED_SUPER_VAULT_AGGREGATOR_KEY));
    }
}
