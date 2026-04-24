// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultExecutor } from "../interfaces/SuperVault/ISuperVaultExecutor.sol";
import { PackedUserOperation } from "../vendor/erc4337/PackedUserOperation.sol";
import { IAccount } from "../vendor/erc4337/IAccount.sol";

/// @title SuperVaultExecutor
/// @author Superform Labs
/// @notice Secondary manager contract that allows session key holders to call strategy functions
/// @dev Deployed as a non-upgradeable contract, added as secondary manager on strategies
contract SuperVaultExecutor is ISuperVaultExecutor, IAccount, AccessControl, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of items in a batch operation to prevent block gas limit issues
    uint256 public constant MAX_BATCH_SIZE = 50;

    /// @notice Gas limit for ETH transfers via assembly call.
    ///         Caps gas forwarded to the recipient to prevent gas-griefing via expensive receive()
    ///         functions while still accommodating multisig wallets (Safe ~65k gas on receive).
    uint256 internal constant ETH_TRANSFER_GAS_LIMIT = 100_000;

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The SuperGovernor contract used to resolve the aggregator
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @notice Cached registry key for the SuperVaultAggregator (avoids extra external call)
    bytes32 public immutable SUPER_VAULT_AGGREGATOR_KEY;

    /// @notice The canonical ERC-4337 v0.7 EntryPoint address
    address public immutable ENTRY_POINT;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev strategy => sessionKey => SessionKeyData
    mapping(address => mapping(address => SessionKeyData)) private _sessionKeys;

    /// @dev strategy => generation counter (incremented to invalidate all session keys)
    mapping(address => uint88) private _strategyGeneration;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superGovernor_ The SuperGovernor address
    /// @param admin_ The admin address (receives DEFAULT_ADMIN_ROLE)
    /// @param entryPoint_ The canonical ERC-4337 v0.7 EntryPoint address
    /// @dev DEFAULT_ADMIN_ROLE is granted for admin functions (e.g., sweepETH) and future role-based extensions.
    ///      It is also the AccessControl role admin for all roles.
    constructor(address superGovernor_, address admin_, address entryPoint_) {
        if (superGovernor_ == address(0) || admin_ == address(0) || entryPoint_ == address(0)) {
            revert ZERO_ADDRESS();
        }

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
        SUPER_VAULT_AGGREGATOR_KEY = ISuperGovernor(superGovernor_).SUPER_VAULT_AGGREGATOR();
        ENTRY_POINT = entryPoint_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /*//////////////////////////////////////////////////////////////
                          RECEIVE / FALLBACK
    //////////////////////////////////////////////////////////////*/

    /// @notice Accept ETH (from strategy refunds during executeHooks)
    /// @dev Required for the balance-delta refund pattern in executeHooks. ETH sent outside
    ///      executeHooks context is recoverable via sweepETH (DEFAULT_ADMIN_ROLE).
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
    ///      granted by A will silently reactivate. The generation counter does NOT automatically protect
    ///      against this — invalidateAllSessionKeys() must be proactively called during the interim period
    ///      to prevent stale key revival.

    /// @inheritdoc ISuperVaultExecutor
    function grantSessionKey(
        address strategy,
        address sessionKey,
        uint256 expiry,
        Permission[] calldata permissions
    )
        external
    {
        _validatePrimaryManager(strategy);
        _grantSessionKey(strategy, sessionKey, expiry, _permissionsToMask(permissions));
    }

    /// @inheritdoc ISuperVaultExecutor
    function grantSessionKeysBatch(
        address[] calldata strategies,
        address[] calldata sessionKeys,
        uint256[] calldata expiries,
        Permission[][] calldata permissions
    )
        external
    {
        uint256 len = strategies.length;
        if (len == 0) revert EMPTY_ARRAY();
        if (len > MAX_BATCH_SIZE) revert BATCH_SIZE_EXCEEDED();
        if (len != sessionKeys.length || len != expiries.length || len != permissions.length) {
            revert ARRAY_LENGTH_MISMATCH();
        }

        ISuperVaultAggregator aggregator = _getAggregator();
        for (uint256 i; i < len; ++i) {
            _validatePrimaryManager(strategies[i], aggregator);
            _grantSessionKey(strategies[i], sessionKeys[i], expiries[i], _permissionsToMask(permissions[i]));
        }
    }

    /// @inheritdoc ISuperVaultExecutor
    function revokeSessionKey(address strategy, address sessionKey) external {
        _validatePrimaryManager(strategy);
        _revokeSessionKey(strategy, sessionKey);
    }

    /// @inheritdoc ISuperVaultExecutor
    function revokeSessionKeysBatch(address[] calldata strategies, address[] calldata sessionKeys) external {
        uint256 len = strategies.length;
        if (len == 0) revert EMPTY_ARRAY();
        if (len > MAX_BATCH_SIZE) revert BATCH_SIZE_EXCEEDED();
        if (len != sessionKeys.length) revert ARRAY_LENGTH_MISMATCH();

        ISuperVaultAggregator aggregator = _getAggregator();
        for (uint256 i; i < len; ++i) {
            _validatePrimaryManager(strategies[i], aggregator);
            _revokeSessionKey(strategies[i], sessionKeys[i]);
        }
    }

    /// @inheritdoc ISuperVaultExecutor
    function invalidateAllSessionKeys(address strategy) external {
        _validatePrimaryManager(strategy);
        uint88 newGeneration = ++_strategyGeneration[strategy];
        emit AllSessionKeysInvalidated(strategy, newGeneration);
    }

    /*//////////////////////////////////////////////////////////////
                        FORWARDING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultExecutor
    function executeHooks(
        address strategy,
        ISuperVaultStrategy.ExecuteArgs calldata args
    )
        external
        payable
        nonReentrant
    {
        _validateSessionKey(strategy, _toBit(Permission.ExecuteHooks));
        _executeHooksInternal(strategy, args, msg.sender);
    }

    /// @inheritdoc ISuperVaultExecutor
    function fulfillCancelRedeemRequests(address strategy, address[] calldata controllers) external nonReentrant {
        _validateSessionKey(strategy, _toBit(Permission.FulfillCancelRedeem));
        ISuperVaultStrategy(strategy).fulfillCancelRedeemRequests(controllers);
    }

    /// @inheritdoc ISuperVaultExecutor
    function fulfillRedeemRequests(
        address strategy,
        address[] calldata controllers,
        uint256[] calldata totalAssetsOut
    )
        external
        nonReentrant
    {
        _validateSessionKey(strategy, _toBit(Permission.FulfillRedeem));
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @inheritdoc ISuperVaultExecutor
    function skimPerformanceFee(address strategy) external nonReentrant {
        _validateSessionKey(strategy, _toBit(Permission.SkimFee));
        ISuperVaultStrategy(strategy).skimPerformanceFee();
    }

    /// @inheritdoc ISuperVaultExecutor
    function pauseStrategy(address strategy) external nonReentrant {
        ISuperVaultAggregator aggregator = _getAggregator();
        _validateSessionKey(strategy, aggregator, _toBit(Permission.Pause));
        aggregator.pauseStrategy(strategy);
    }

    /// @inheritdoc ISuperVaultExecutor
    function unpauseStrategy(address strategy) external nonReentrant {
        ISuperVaultAggregator aggregator = _getAggregator();
        _validateSessionKey(strategy, aggregator, _toBit(Permission.Unpause));
        aggregator.unpauseStrategy(strategy);
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
        override(IAccount, ISuperVaultExecutor)
        onlyEntryPoint
        returns (uint256 validationData)
    {
        // 1. Assert callData targets executeFromEntryPoint
        if (userOp.callData.length < 36) revert INVALID_CALLDATA_SELECTOR();
        bytes4 selector = bytes4(userOp.callData[:4]);
        if (selector != this.executeFromEntryPoint.selector) revert INVALID_CALLDATA_SELECTOR();

        // 2. Extract strategy address (first ABI-encoded parameter after selector)
        address strategy = abi.decode(userOp.callData[4:36], (address));

        // 3. Recover session key from EIP-191 prefixed signature
        address sessionKey = ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(userOpHash), userOp.signature);

        // 4. Validate session key has ExecuteHooks permission
        (bool valid, uint256 expiry) =
            _isSessionKeyValidForPermission(strategy, sessionKey, _toBit(Permission.ExecuteHooks));

        if (!valid) {
            return 1; // SIG_VALIDATION_FAILED
        }

        // 5. Pre-fund EntryPoint if required (non-zero when no paymaster is used).
        //    Per ERC-4337: the account SHOULD pay missingAccountFunds to the EntryPoint (msg.sender).
        //    Ignore failure — the EntryPoint will verify the deposit independently.
        if (missingAccountFunds > 0) {
            assembly {
                pop(call(gas(), caller(), missingAccountFunds, 0, 0, 0, 0))
            }
        }

        // 6. Pack validationData: sigAuthorizer(0) | validUntil << 160 | validAfter(0) << 208
        //    validUntil = 0 means indefinite per ERC-4337
        uint48 validUntil = expiry >= type(uint48).max ? uint48(0) : uint48(expiry);
        return uint256(validUntil) << 160;
    }

    /// @inheritdoc ISuperVaultExecutor
    function executeFromEntryPoint(
        address strategy,
        ISuperVaultStrategy.ExecuteArgs calldata args
    )
        external
        payable
        onlyEntryPoint
        nonReentrant
    {
        // Session key was already validated in validateUserOp; refund to self (admin-sweepable)
        _executeHooksInternal(strategy, args, address(this));
        emit ExecutedFromEntryPoint(strategy);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultExecutor
    function sweepETH(address to) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) revert ZERO_ADDRESS();
        uint256 bal = address(this).balance;
        if (bal > 0) {
            // Use assembly to prevent return bomb attack; cap gas to accommodate multisig wallets
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

    /// @inheritdoc ISuperVaultExecutor
    function isSessionKeyValid(address strategy, address sessionKey) external view returns (bool) {
        SessionKeyData storage data = _sessionKeys[strategy][sessionKey];
        if (data.expiry == 0 || block.timestamp > data.expiry) return false;
        if (data.generation != _strategyGeneration[strategy]) return false;
        return _getAggregator().isMainManager(data.grantedByManager, strategy);
    }

    /// @inheritdoc ISuperVaultExecutor
    function isSessionKeyValidForPermission(
        address strategy,
        address sessionKey,
        Permission permission
    )
        external
        view
        returns (bool)
    {
        SessionKeyData storage data = _sessionKeys[strategy][sessionKey];
        if (data.expiry == 0 || block.timestamp > data.expiry) return false;
        if (data.generation != _strategyGeneration[strategy]) return false;
        if ((data.permissions & _toBit(permission)) == 0) return false;
        return _getAggregator().isMainManager(data.grantedByManager, strategy);
    }

    /// @inheritdoc ISuperVaultExecutor
    function getSessionKeyPermissions(address strategy, address sessionKey) external view returns (uint8) {
        return _sessionKeys[strategy][sessionKey].permissions;
    }

    /// @inheritdoc ISuperVaultExecutor
    function getSessionKeyData(
        address strategy,
        address sessionKey
    )
        external
        view
        returns (uint256 expiry, address grantedByManager, uint88 generation, uint8 permissions)
    {
        SessionKeyData storage data = _sessionKeys[strategy][sessionKey];
        return (data.expiry, data.grantedByManager, data.generation, data.permissions);
    }

    /// @inheritdoc ISuperVaultExecutor
    function getStrategyGeneration(address strategy) external view returns (uint88) {
        return _strategyGeneration[strategy];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Shared logic for executeHooks: tracks ETH balance, calls strategy, refunds overpayment
    /// @param strategy The strategy to execute hooks on
    /// @param args The execution arguments
    /// @param refundRecipient The address to refund excess ETH to
    function _executeHooksInternal(
        address strategy,
        ISuperVaultStrategy.ExecuteArgs calldata args,
        address refundRecipient
    )
        internal
    {
        // Track only the caller's overpayment, not stray ETH from other sources
        uint256 balanceBefore = address(this).balance - msg.value;
        ISuperVaultStrategy(strategy).executeHooks{ value: msg.value }(args);
        uint256 refund = address(this).balance - balanceBefore;

        if (refund > 0) {
            // Use assembly to prevent return bomb attack (avoids copying returndata);
            // cap gas to prevent gas-griefing via expensive receive() functions.
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
    /// @param strategy The strategy address
    /// @param sessionKey The session key address to validate
    /// @param requiredPermission The permission bit required
    /// @return valid True if the session key is valid with the required permission
    /// @return expiry The session key's expiry timestamp (0 if invalid)
    function _isSessionKeyValidForPermission(
        address strategy,
        address sessionKey,
        uint8 requiredPermission
    )
        internal
        view
        returns (bool valid, uint256 expiry)
    {
        SessionKeyData storage data = _sessionKeys[strategy][sessionKey];
        if (data.expiry == 0) return (false, 0);
        if (block.timestamp > data.expiry) return (false, 0);
        if (data.generation != _strategyGeneration[strategy]) return (false, 0);
        if ((data.permissions & requiredPermission) == 0) return (false, 0);
        if (!_getAggregator().isMainManager(data.grantedByManager, strategy)) return (false, 0);
        return (true, data.expiry);
    }

    /// @dev Converts a single Permission enum value to its bitmask bit
    function _toBit(Permission p) internal pure returns (uint8) {
        return uint8(1 << uint8(p));
    }

    /// @dev Converts a Permission[] array to a uint8 bitmask
    /// @param permissions The permissions to convert
    /// @return mask The resulting bitmask
    function _permissionsToMask(Permission[] calldata permissions) internal pure returns (uint8 mask) {
        uint256 len = permissions.length;
        if (len == 0) revert ZERO_PERMISSIONS();
        for (uint256 i; i < len; ++i) {
            mask |= _toBit(permissions[i]);
        }
    }

    /// @dev Validates that msg.sender is the primary manager of the given strategy
    /// @dev Note: this implicitly validates that `strategy` is a known strategy address —
    ///      isMainManager returns false for unknown strategies (no manager set), so the call reverts.
    /// @param strategy The strategy address to validate against
    function _validatePrimaryManager(address strategy) internal view {
        if (!_getAggregator().isMainManager(msg.sender, strategy)) {
            revert CALLER_NOT_PRIMARY_MANAGER();
        }
    }

    /// @dev Overload with pre-cached aggregator for gas-efficient batch loops
    /// @param strategy The strategy address to validate against
    /// @param aggregator The pre-cached aggregator instance
    function _validatePrimaryManager(address strategy, ISuperVaultAggregator aggregator) internal view {
        if (!aggregator.isMainManager(msg.sender, strategy)) {
            revert CALLER_NOT_PRIMARY_MANAGER();
        }
    }

    /// @dev Validates that msg.sender holds a valid session key with the required permission
    /// @dev Note: this implicitly validates strategy validity — a session key can only exist for a strategy
    ///      if a primary manager previously granted it via _validatePrimaryManager.
    /// @param strategy The strategy address to validate against
    /// @param requiredPermission The permission bit required for this function
    function _validateSessionKey(address strategy, uint8 requiredPermission) internal view {
        _validateSessionKey(strategy, _getAggregator(), requiredPermission);
    }

    /// @dev Overload with pre-cached aggregator for gas-efficient single-item operations
    /// @param strategy The strategy address to validate against
    /// @param aggregator The pre-cached aggregator instance
    /// @param requiredPermission The permission bit required for this function
    function _validateSessionKey(
        address strategy,
        ISuperVaultAggregator aggregator,
        uint8 requiredPermission
    )
        internal
        view
    {
        SessionKeyData storage data = _sessionKeys[strategy][msg.sender];
        if (data.expiry == 0) revert SESSION_KEY_NOT_AUTHORIZED();
        if (block.timestamp > data.expiry) revert SESSION_KEY_EXPIRED();
        if (data.generation != _strategyGeneration[strategy]) revert SESSION_KEY_GENERATION_MISMATCH();
        if ((data.permissions & requiredPermission) == 0) revert SESSION_KEY_PERMISSION_DENIED();
        if (!aggregator.isMainManager(data.grantedByManager, strategy)) {
            revert PRIMARY_MANAGER_CHANGED();
        }
    }

    /// @dev Grants a session key for a strategy at the current generation with specified permissions
    /// @param strategy The strategy address
    /// @param sessionKey The session key address to authorize
    /// @param expiry The expiry timestamp for the session key. Can be type(uint256).max for a key that never expires.
    /// @param permissions The permission bitmask
    function _grantSessionKey(address strategy, address sessionKey, uint256 expiry, uint8 permissions) internal {
        if (sessionKey == address(0)) revert ZERO_ADDRESS();
        if (expiry == 0) revert ZERO_EXPIRY();
        if (expiry <= block.timestamp) revert EXPIRY_IN_PAST();

        uint88 generation = _strategyGeneration[strategy];
        _sessionKeys[strategy][sessionKey] = SessionKeyData({
            expiry: expiry,
            grantedByManager: msg.sender,
            generation: generation,
            permissions: permissions
        });

        emit SessionKeyGranted(strategy, sessionKey, expiry, msg.sender, generation, permissions);
    }

    /// @dev Revokes a session key for a strategy (reverts if key was never granted)
    /// @param strategy The strategy address
    /// @param sessionKey The session key address to revoke
    function _revokeSessionKey(address strategy, address sessionKey) internal {
        if (_sessionKeys[strategy][sessionKey].expiry == 0) revert SESSION_KEY_NOT_AUTHORIZED();
        delete _sessionKeys[strategy][sessionKey];
        emit SessionKeyRevoked(strategy, sessionKey);
    }

    /// @dev Resolves the aggregator dynamically via SuperGovernor using cached registry key
    /// @return The ISuperVaultAggregator instance resolved from the registry
    function _getAggregator() internal view returns (ISuperVaultAggregator) {
        return ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR_KEY));
    }
}
