// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { IManagedSuperVaultController } from "./IManagedSuperVaultController.sol";
import { PackedUserOperation } from "../../vendor/erc4337/PackedUserOperation.sol";

/// @title IManagedSuperVaultExecutor
/// @author Superform Labs
/// @notice Interface for ManagedSuperVaultExecutor - time-bounded session-key delegation of Managed Vault
///         manager functions. Mirrors the SuperVaultExecutor pattern with managed-specific permissions.
interface IManagedSuperVaultExecutor {
    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    /// @dev Stored as a uint16 bitmask (1 << enum value). Max 16 permissions (indices 0-15).
    enum Permission {
        ExecuteCalls, // 0: execute whitelisted calldata
        FulfillDeposits, // 1: fulfill/reject pending deposit requests
        ManageApprovals, // 2: approve/reject/revoke depositors
        FulfillRedeem, // 3: fulfill pending redeem requests
        FulfillCancelRedeem, // 4: fulfill pending cancel redeem requests
        SkimFee, // 5: skim performance fees
        ProposeNAV, // 6: propose NAV updates
        Pause, // 7: pause the managed vault
        Unpause // 8: unpause the managed vault
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct SessionKeyData {
        uint256 expiry; // slot 0 (32 bytes)
        address grantedByManager; // slot 1 (20 bytes)
        uint80 generation; // slot 1 (10 bytes)
        uint16 permissions; // slot 1 (2 bytes) — bitmask of allowed functions
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_ADDRESS();
    error ZERO_EXPIRY();
    error EXPIRY_IN_PAST();
    error EMPTY_ARRAY();
    error BATCH_SIZE_EXCEEDED();
    error ARRAY_LENGTH_MISMATCH();
    error CALLER_NOT_PRIMARY_MANAGER();
    error SESSION_KEY_NOT_AUTHORIZED();
    error SESSION_KEY_EXPIRED();
    error SESSION_KEY_GENERATION_MISMATCH();
    error SESSION_KEY_PERMISSION_DENIED();
    error PRIMARY_MANAGER_CHANGED();
    error ZERO_PERMISSIONS();
    error ONLY_ENTRY_POINT();
    error INVALID_CALLDATA_SELECTOR();
    error ETH_TRANSFER_FAILED();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SessionKeyGranted(
        address indexed controller,
        address indexed sessionKey,
        uint256 expiry,
        address indexed grantedByManager,
        uint80 generation,
        uint16 permissions
    );
    event SessionKeyRevoked(address indexed controller, address indexed sessionKey);
    event AllSessionKeysInvalidated(address indexed controller, uint80 newGeneration);
    event ExecutedFromEntryPoint(address indexed controller);
    event ETHRefunded(address indexed recipient, uint256 amount);
    event ETHSwept(address indexed recipient, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                        SESSION KEY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Grant a session key for a controller (primary manager only)
    function grantSessionKey(
        address controller,
        address sessionKey,
        uint256 expiry,
        Permission[] calldata permissions
    )
        external;

    /// @notice Grant session keys for multiple controllers (primary manager of each)
    function grantSessionKeysBatch(
        address[] calldata controllers,
        address[] calldata sessionKeys,
        uint256[] calldata expiries,
        Permission[][] calldata permissions
    )
        external;

    /// @notice Revoke a session key (primary manager only)
    function revokeSessionKey(address controller, address sessionKey) external;

    /// @notice Revoke session keys for multiple controllers (primary manager of each)
    function revokeSessionKeysBatch(address[] calldata controllers, address[] calldata sessionKeys) external;

    /// @notice Invalidate all session keys for a controller by bumping its generation
    function invalidateAllSessionKeys(address controller) external;

    /*//////////////////////////////////////////////////////////////
                        FORWARDING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Execute a whitelisted call through the controller (Permission.ExecuteCalls)
    function executeManagedCall(
        address controller,
        IManagedSuperVaultController.ManagedCall calldata call,
        bytes32 operationId
    )
        external
        payable;

    /// @notice Execute a batch of whitelisted calls through the controller (Permission.ExecuteCalls)
    function executeManagedBatch(
        address controller,
        IManagedSuperVaultController.ManagedCall[] calldata calls,
        bytes32 operationId
    )
        external
        payable;

    /// @notice Fulfill pending deposit requests (Permission.FulfillDeposits)
    function fulfillDepositRequests(address controller, address[] calldata depositors) external;

    /// @notice Reject pending deposit requests (Permission.FulfillDeposits)
    function rejectDepositRequests(address controller, address[] calldata depositors, string calldata reason) external;

    /// @notice Approve depositors (Permission.ManageApprovals)
    function approveDepositors(address controller, address[] calldata depositors, bytes32[] calldata kycRefs) external;

    /// @notice Reject depositors (Permission.ManageApprovals)
    function rejectDepositors(address controller, address[] calldata depositors) external;

    /// @notice Revoke depositors (Permission.ManageApprovals)
    function revokeDepositors(address controller, address[] calldata depositors) external;

    /// @notice Fulfill pending redeem requests (Permission.FulfillRedeem)
    function fulfillRedeemRequests(
        address controller,
        address[] calldata redeemControllers,
        uint256[] calldata totalAssetsOut
    )
        external;

    /// @notice Fulfill pending cancel redeem requests (Permission.FulfillCancelRedeem)
    function fulfillCancelRedeemRequests(address controller, address[] calldata redeemControllers) external;

    /// @notice Skim performance fees (Permission.SkimFee)
    function skimPerformanceFee(address controller) external;

    /// @notice Propose a NAV update (Permission.ProposeNAV)
    function proposeNAVUpdate(
        address controller,
        uint256 newPPS,
        uint256 effectiveTimestamp,
        bytes32 evidenceHash,
        string calldata evidenceURI
    )
        external
        returns (uint256 proposalId);

    /// @notice Pause the managed vault (Permission.Pause)
    function pauseManagedVault(address controller) external;

    /// @notice Unpause the managed vault (Permission.Unpause)
    function unpauseManagedVault(address controller) external;

    /*//////////////////////////////////////////////////////////////
                      ERC-4337 COMPATIBILITY
    //////////////////////////////////////////////////////////////*/

    /// @notice ERC-4337 account validation; session key must hold Permission.ExecuteCalls
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256 validationData);

    /// @notice Execute a batch of whitelisted calls from the EntryPoint after userOp validation
    function executeFromEntryPoint(
        address controller,
        IManagedSuperVaultController.ManagedCall[] calldata calls,
        bytes32 operationId
    )
        external
        payable;

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sweep stray ETH (DEFAULT_ADMIN_ROLE)
    function sweepETH(address to) external;

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether a session key is currently valid for a controller
    function isSessionKeyValid(address controller, address sessionKey) external view returns (bool);

    /// @notice Whether a session key is currently valid with a specific permission
    function isSessionKeyValidForPermission(
        address controller,
        address sessionKey,
        Permission permission
    )
        external
        view
        returns (bool);

    /// @notice Get a session key's permission bitmask
    function getSessionKeyPermissions(address controller, address sessionKey) external view returns (uint16);

    /// @notice Get a session key's full data
    function getSessionKeyData(
        address controller,
        address sessionKey
    )
        external
        view
        returns (uint256 expiry, address grantedByManager, uint80 generation, uint16 permissions);

    /// @notice Get the current session-key generation for a controller
    function getControllerGeneration(address controller) external view returns (uint80);
}
