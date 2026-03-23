// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { ISuperGovernor } from "../ISuperGovernor.sol";
import { ISuperVaultStrategy } from "./ISuperVaultStrategy.sol";

/// @title ISuperVaultManager
/// @author Superform Labs
/// @notice Interface for SuperVaultManager - time-bounded delegation of secondary manager functions
interface ISuperVaultManager {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct SessionKeyData {
        uint256 expiry; // 0 = not authorized
        address grantedByManager; // primary manager at grant time
        uint256 generation; // strategy generation at grant time
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_ADDRESS();
    error ZERO_EXPIRY();
    error EXPIRY_IN_PAST();
    error ARRAY_LENGTH_MISMATCH();
    error CALLER_NOT_PRIMARY_MANAGER();
    error SESSION_KEY_NOT_AUTHORIZED();
    error SESSION_KEY_EXPIRED();
    error SESSION_KEY_GENERATION_MISMATCH();
    error PRIMARY_MANAGER_CHANGED();
    error ETH_REFUND_FAILED();
    error EMPTY_ARRAY();
    error BATCH_SIZE_EXCEEDED();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a session key is granted for a strategy
    /// @param strategy The strategy address
    /// @param sessionKey The session key address
    /// @param expiry The expiry timestamp
    /// @param grantedByManager The primary manager who granted the key
    /// @param generation The strategy generation at grant time
    event SessionKeyGranted(
        address indexed strategy,
        address indexed sessionKey,
        uint256 expiry,
        address indexed grantedByManager,
        uint256 generation
    );

    /// @notice Emitted when a session key is revoked for a strategy
    /// @param strategy The strategy address
    /// @param sessionKey The session key address
    event SessionKeyRevoked(address indexed strategy, address indexed sessionKey);

    /// @notice Emitted when all session keys for a strategy are invalidated via generation bump
    /// @param strategy The strategy address
    /// @param newGeneration The new generation counter value
    event AllSessionKeysInvalidated(address indexed strategy, uint256 newGeneration);

    /// @notice Emitted when leftover ETH is refunded to the caller after executeHooks
    /// @param recipient The address receiving the refund
    /// @param amount The amount of ETH refunded
    event ETHRefunded(address indexed recipient, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                        SESSION KEY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Grants a session key for a strategy
    /// @param strategy The strategy address
    /// @param sessionKey The session key address to authorize
    /// @param expiry The expiry timestamp for the session key
    function grantSessionKey(address strategy, address sessionKey, uint256 expiry) external;

    /// @notice Batch grants session keys for multiple strategies
    /// @param strategies The strategy addresses
    /// @param sessionKeys The session key addresses to authorize
    /// @param expiries The expiry timestamps for each session key
    function grantSessionKeysBatch(
        address[] calldata strategies,
        address[] calldata sessionKeys,
        uint256[] calldata expiries
    )
        external;

    /// @notice Revokes a session key for a strategy
    /// @param strategy The strategy address
    /// @param sessionKey The session key address to revoke
    function revokeSessionKey(address strategy, address sessionKey) external;

    /// @notice Batch revokes session keys for multiple strategies
    /// @param strategies The strategy addresses
    /// @param sessionKeys The session key addresses to revoke
    function revokeSessionKeysBatch(address[] calldata strategies, address[] calldata sessionKeys) external;

    /// @notice Invalidates all session keys for a strategy by incrementing the generation counter
    /// @param strategy The strategy address
    function invalidateAllSessionKeys(address strategy) external;

    /*//////////////////////////////////////////////////////////////
                        FORWARDING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Forwards executeHooks to a strategy
    /// @param strategy The strategy to forward to
    /// @param args The execution arguments
    function executeHooks(address strategy, ISuperVaultStrategy.ExecuteArgs calldata args) external payable;

    /// @notice Forwards fulfillCancelRedeemRequests to a strategy
    /// @param strategy The strategy to forward to
    /// @param controllers Array of controller addresses with pending cancel requests
    function fulfillCancelRedeemRequests(address strategy, address[] calldata controllers) external;

    /// @notice Forwards fulfillRedeemRequests to a strategy
    /// @param strategy The strategy to forward to
    /// @param controllers Ordered/unique controllers with pending requests
    /// @param totalAssetsOut Total PRE-FEE assets available for each controller
    function fulfillRedeemRequests(
        address strategy,
        address[] calldata controllers,
        uint256[] calldata totalAssetsOut
    )
        external;

    /// @notice Forwards skimPerformanceFee to a strategy
    /// @param strategy The strategy to forward to
    function skimPerformanceFee(address strategy) external;

    /// @notice Forwards pauseStrategy to the aggregator
    /// @param strategy The strategy to pause
    function pauseStrategy(address strategy) external;

    /// @notice Forwards unpauseStrategy to the aggregator
    /// @param strategy The strategy to unpause
    function unpauseStrategy(address strategy) external;

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sweeps stuck ETH from the contract to a recipient
    /// @dev Only callable by DEFAULT_ADMIN_ROLE. Uses assembly to prevent return bomb.
    /// @param to The address to send ETH to
    function sweepETH(address to) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice The SuperGovernor contract used to resolve the aggregator
    function SUPER_GOVERNOR() external view returns (ISuperGovernor);

    /// @notice Maximum number of items in a batch operation
    function MAX_BATCH_SIZE() external view returns (uint256);

    /// @notice Checks if a session key is currently valid for a strategy
    /// @param strategy The strategy address
    /// @param sessionKey The session key address
    /// @return True if the session key is valid (not expired, correct generation, granting manager is still primary)
    function isSessionKeyValid(address strategy, address sessionKey) external view returns (bool);

    /// @notice Gets the session key data for a strategy
    /// @param strategy The strategy address
    /// @param sessionKey The session key address
    /// @return expiry The expiry timestamp
    /// @return grantedByManager The primary manager who granted the key
    /// @return generation The strategy generation at grant time
    function getSessionKeyData(
        address strategy,
        address sessionKey
    )
        external
        view
        returns (uint256 expiry, address grantedByManager, uint256 generation);

    /// @notice Gets the current generation counter for a strategy
    /// @param strategy The strategy address
    /// @return The current generation counter
    function getStrategyGeneration(address strategy) external view returns (uint256);
}
