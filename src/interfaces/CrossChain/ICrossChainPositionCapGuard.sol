// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ICrossChainPositionCapGuard
/// @author Superform Labs
/// @notice Cap policy + destination allowlist for cross-chain SuperVault positions under the
///         Constrained Destination Model. The enforcing caller is a SuperVault*CapBridgeHook,
///         which propagates the revert to abort the executeHooks batch.
///         See specs/cross-chain-supervaults/technical-spec.md.
interface ICrossChainPositionCapGuard {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event CapConfigUpdated(address indexed strategy, uint256 maxCrossChainBps);
    event DestinationApprovalUpdated(
        address indexed strategy, uint64 indexed chainId, address indexed destinationVault, bool approved
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_ADDRESS();
    error UNAUTHORIZED();
    error INVALID_CAP();
    error LENGTH_MISMATCH();
    error AUM_DATA_STALE();
    error ZERO_TOTAL_AUM();
    error CROSS_CHAIN_CAP_EXCEEDED();
    error PER_CHAIN_CAP_EXCEEDED();
    error CHAIN_NOT_ENABLED();
    error DESTINATION_VAULT_NOT_APPROVED();
    error IDLE_HOLD_NOT_ENABLED();

    /*//////////////////////////////////////////////////////////////
                              ENFORCEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Validate a cross-chain deployment; reverts with a typed error on any violation.
    /// @dev Called by a SuperVault*CapBridgeHook atomically before its bridge send. Checks, in
    ///      order: destination approved -> AUM fresh -> non-zero total -> global BPS cap ->
    ///      per-chain cap. Numerator is the registry's EFFECTIVE exposure (incl. in-flight).
    function validateAllocation(
        address strategy,
        uint64 destinationChainId,
        address destinationVault,
        uint256 amount
    )
        external
        view;

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice Set cap configuration. Tightening is allowed for the primary manager or governor;
    ///         loosening (raise global BPS, raise a per-chain cap, enable a chain) is
    ///         GOVERNOR_ROLE-only (SEC-2).
    function setCapConfig(
        address strategy,
        uint256 maxCrossChainBps,
        uint64[] calldata chainIds,
        uint256[] calldata chainCaps,
        bool[] calldata chainEnabled
    )
        external;

    /// @notice Approve/revoke a destination SuperVault, or (destinationVault == address(0)) the
    ///         idle-hold escrow for a chain. Approving is GOVERNOR_ROLE-only; revoking is allowed
    ///         for the primary manager or governor.
    function setApprovedDestination(address strategy, uint64 chainId, address destinationVault, bool approved) external;

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether a destination is usable: an approved SuperVault, or an enabled idle-hold
    ///         escrow when `destinationVault == address(0)`.
    function isApprovedDestination(
        address strategy,
        uint64 chainId,
        address destinationVault
    )
        external
        view
        returns (bool);

    function maxCrossChainBps(address strategy) external view returns (uint256);
    function perChainCap(address strategy, uint64 chainId) external view returns (uint256);
    function chainEnabled(address strategy, uint64 chainId) external view returns (bool);
}
