// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultExecutor } from "../interfaces/SuperVault/ISuperVaultExecutor.sol";

/// @title SuperVaultExecutor
/// @author Superform Labs
/// @notice Secondary manager contract that allows session key holders to call strategy functions
/// @dev Deployed as a non-upgradeable contract, added as secondary manager on strategies
contract SuperVaultExecutor is ISuperVaultExecutor, AccessControl, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of items in a batch operation to prevent block gas limit issues
    uint256 public constant MAX_BATCH_SIZE = 50;

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The SuperGovernor contract used to resolve the aggregator
    ISuperGovernor public immutable SUPER_GOVERNOR;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev strategy => sessionKey => SessionKeyData
    mapping(address => mapping(address => SessionKeyData)) private _sessionKeys;

    /// @dev strategy => generation counter (incremented to invalidate all session keys)
    mapping(address => uint256) private _strategyGeneration;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superGovernor_ The SuperGovernor address
    /// @param admin_ The admin address (receives DEFAULT_ADMIN_ROLE)
    /// @dev DEFAULT_ADMIN_ROLE is granted for admin functions (e.g., sweepETH) and future role-based extensions.
    ///      It is also the AccessControl role admin for all roles.
    constructor(address superGovernor_, address admin_) {
        if (superGovernor_ == address(0) || admin_ == address(0)) revert ZERO_ADDRESS();

        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
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
                        SESSION KEY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultExecutor
    function grantSessionKey(address strategy, address sessionKey, uint256 expiry) external {
        _validatePrimaryManager(strategy);
        _grantSessionKey(strategy, sessionKey, expiry);
    }

    /// @inheritdoc ISuperVaultExecutor
    function grantSessionKeysBatch(
        address[] calldata strategies,
        address[] calldata sessionKeys,
        uint256[] calldata expiries
    )
        external
    {
        uint256 len = strategies.length;
        if (len == 0) revert EMPTY_ARRAY();
        if (len > MAX_BATCH_SIZE) revert BATCH_SIZE_EXCEEDED();
        if (len != sessionKeys.length || len != expiries.length) revert ARRAY_LENGTH_MISMATCH();

        ISuperVaultAggregator aggregator = _getAggregator();
        for (uint256 i; i < len; ++i) {
            _validatePrimaryManager(strategies[i], aggregator);
            _grantSessionKey(strategies[i], sessionKeys[i], expiries[i]);
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
        uint256 newGeneration = ++_strategyGeneration[strategy];
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
        _validateSessionKey(strategy);

        // Track only the caller's overpayment, not stray ETH from other sources
        uint256 balanceBefore = address(this).balance - msg.value;
        ISuperVaultStrategy(strategy).executeHooks{ value: msg.value }(args);
        uint256 refund = address(this).balance - balanceBefore;

        if (refund > 0) {
            // Use assembly to prevent return bomb attack (avoids copying returndata)
            bool success;
            assembly {
                success := call(gas(), caller(), refund, 0, 0, 0, 0)
            }
            if (!success) revert ETH_REFUND_FAILED();
            emit ETHRefunded(msg.sender, refund);
        }
    }

    /// @inheritdoc ISuperVaultExecutor
    function fulfillCancelRedeemRequests(address strategy, address[] calldata controllers) external {
        _validateSessionKey(strategy);
        ISuperVaultStrategy(strategy).fulfillCancelRedeemRequests(controllers);
    }

    /// @inheritdoc ISuperVaultExecutor
    function fulfillRedeemRequests(
        address strategy,
        address[] calldata controllers,
        uint256[] calldata totalAssetsOut
    )
        external
    {
        _validateSessionKey(strategy);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, totalAssetsOut);
    }

    /// @inheritdoc ISuperVaultExecutor
    function skimPerformanceFee(address strategy) external {
        _validateSessionKey(strategy);
        ISuperVaultStrategy(strategy).skimPerformanceFee();
    }

    /// @inheritdoc ISuperVaultExecutor
    function pauseStrategy(address strategy) external {
        ISuperVaultAggregator aggregator = _getAggregator();
        _validateSessionKey(strategy, aggregator);
        aggregator.pauseStrategy(strategy);
    }

    /// @inheritdoc ISuperVaultExecutor
    function unpauseStrategy(address strategy) external {
        ISuperVaultAggregator aggregator = _getAggregator();
        _validateSessionKey(strategy, aggregator);
        aggregator.unpauseStrategy(strategy);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperVaultExecutor
    function sweepETH(address to) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) revert ZERO_ADDRESS();
        uint256 bal = address(this).balance;
        if (bal > 0) {
            // Use assembly to prevent return bomb attack
            bool success;
            assembly {
                success := call(gas(), to, bal, 0, 0, 0, 0)
            }
            if (!success) revert ETH_REFUND_FAILED();
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
    function getSessionKeyData(
        address strategy,
        address sessionKey
    )
        external
        view
        returns (uint256 expiry, address grantedByManager, uint256 generation)
    {
        SessionKeyData storage data = _sessionKeys[strategy][sessionKey];
        return (data.expiry, data.grantedByManager, data.generation);
    }

    /// @inheritdoc ISuperVaultExecutor
    function getStrategyGeneration(address strategy) external view returns (uint256) {
        return _strategyGeneration[strategy];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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

    /// @dev Validates that msg.sender holds a valid session key for the given strategy
    /// @dev Note: this implicitly validates strategy validity — a session key can only exist for a strategy
    ///      if a primary manager previously granted it via _validatePrimaryManager.
    /// @param strategy The strategy address to validate against
    function _validateSessionKey(address strategy) internal view {
        _validateSessionKey(strategy, _getAggregator());
    }

    /// @dev Overload with pre-cached aggregator for gas-efficient single-item operations
    /// @param strategy The strategy address to validate against
    /// @param aggregator The pre-cached aggregator instance
    function _validateSessionKey(address strategy, ISuperVaultAggregator aggregator) internal view {
        SessionKeyData storage data = _sessionKeys[strategy][msg.sender];
        if (data.expiry == 0) revert SESSION_KEY_NOT_AUTHORIZED();
        if (block.timestamp > data.expiry) revert SESSION_KEY_EXPIRED();
        if (data.generation != _strategyGeneration[strategy]) revert SESSION_KEY_GENERATION_MISMATCH();
        if (!aggregator.isMainManager(data.grantedByManager, strategy)) {
            revert PRIMARY_MANAGER_CHANGED();
        }
    }

    /// @dev Grants a session key for a strategy at the current generation
    /// @param strategy The strategy address
    /// @param sessionKey The session key address to authorize
    /// @param expiry The expiry timestamp for the session key
    function _grantSessionKey(address strategy, address sessionKey, uint256 expiry) internal {
        if (sessionKey == address(0)) revert ZERO_ADDRESS();
        if (expiry == 0) revert ZERO_EXPIRY();
        if (expiry <= block.timestamp) revert EXPIRY_IN_PAST();

        uint256 generation = _strategyGeneration[strategy];
        _sessionKeys[strategy][sessionKey] =
            SessionKeyData({ expiry: expiry, grantedByManager: msg.sender, generation: generation });

        emit SessionKeyGranted(strategy, sessionKey, expiry, msg.sender, generation);
    }

    /// @dev Revokes a session key for a strategy (no-op if key was never granted)
    /// @param strategy The strategy address
    /// @param sessionKey The session key address to revoke
    function _revokeSessionKey(address strategy, address sessionKey) internal {
        if (_sessionKeys[strategy][sessionKey].expiry == 0) return;
        delete _sessionKeys[strategy][sessionKey];
        emit SessionKeyRevoked(strategy, sessionKey);
    }

    /// @dev Resolves the aggregator dynamically via SuperGovernor
    /// @return The ISuperVaultAggregator instance resolved from the registry
    function _getAggregator() internal view returns (ISuperVaultAggregator) {
        return ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_GOVERNOR.SUPER_VAULT_AGGREGATOR()));
    }
}
