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
    event DestinationAdapterUpdated(uint64 indexed chainId, address indexed adapter, bool approved);
    event DestinationHooksUpdated(uint64 indexed chainId, address approveHook, address depositHook);
    event EidChainIdUpdated(uint32 indexed eid, uint64 chainId);
    event DestinationVaultAssetUpdated(uint64 indexed chainId, address indexed vault, address asset);
    event StargateRouteUpdated(address indexed srcPool, uint64 indexed chainId, address dstToken);
    event StargateMinDeliveryBpsUpdated(uint256 bps);
    event StrategyHubAssetUpdated(address indexed strategy, address asset);
    event StrategyDestinationAssetUpdated(address indexed strategy, uint64 indexed chainId, address asset);
    event StargateFeeLibUpdated(address indexed pool, address feeLib);

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
    /// @notice R7: the registry's cap-facing exposure is below the oracle's committed cross-chain
    ///         total - impossible by construction unless the registry address-book key was
    ///         rotated mid-flight (orphaned positions); allocations fail closed
    error REGISTRY_ORACLE_DESYNC();

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

    /// @notice Approve/revoke a destination TRANSPORT adapter (AcrossV3Adapter / DebridgeAdapter /
    ///         StargateAdapter deployment on `chainId`). The cap hooks require the bridge transport
    ///         receiver to be an approved adapter — the adapter is never the economic destination
    ///         (B1). GOVERNOR_ROLE-only.
    function setDestinationAdapter(uint64 chainId, address adapter, bool approved) external;

    /// @notice Pin the canonical destination hook pair for `chainId`: the ApproveERC20Hook and the
    ///         Deposit4626VaultHook deployments a capped bridge's destination action must use
    ///         (exactly [approve, deposit]) — anything else is an untyped destination action and
    ///         is rejected by the cap hooks (B1). GOVERNOR_ROLE-only.
    function setDestinationHooks(uint64 chainId, address approveHook, address depositHook) external;

    /// @notice Map a LayerZero endpoint id to its canonical EVM chain id (e.g. 30184 -> 8453), so
    ///         Stargate exposure shares the same per-chain cap namespace as Across/deBridge (B4).
    ///         chainId == 0 unmaps (fail closed). GOVERNOR_ROLE-only.
    function setEidChainId(uint32 eid, uint64 chainId) external;

    /// @notice Pin the asset of an approved destination vault (R3-RF3): the cap hooks require a
    ///         VAULT_DEPOSIT action's token to equal this, so an output-token / vault-asset
    ///         mismatch can never reach a destination revert that strands delivered funds.
    ///         asset == address(0) unpins (fails closed for that vault). GOVERNOR_ROLE-only.
    function setDestinationVaultAsset(uint64 chainId, address vault, address asset) external;

    /// @notice Pin the destination-side token a Stargate source pool delivers on `chainId`
    ///         (R3-RF1: the OFT destination token is not hub-derivable, so governance supplies
    ///         it and the cap hook binds the action token to it, fail closed when unset).
    ///         R4 route-activation rule: the pinned token MUST be the destination representation
    ///         of the strategy's hub asset with EQUAL decimals (same-asset invariant; not
    ///         machine-checkable cross-chain — enforce at route review). GOVERNOR_ROLE-only.
    function setStargateRoute(address srcPool, uint64 chainId, address dstToken) external;

    /// @notice Pin the ONLY input token the cap hook family may bridge for `strategy` — its hub
    ///         denomination asset (R4, hub-verifiable half of the same-asset invariant; the
    ///         core-side cap hooks bind their decoded input token to this at send time, fail
    ///         closed when unpinned). address(0) unpins. GOVERNOR_ROLE-only.
    function setStrategyHubAsset(address strategy, address asset) external;

    /// @notice Pin the ONLY destination token the cap hook family may route `strategy`'s capital
    ///         into on `chainId` — the destination representation of its hub asset (R5-H, the
    ///         address-level destination half of the same-asset invariant; the core cap hooks bind
    ///         the typed destination action's token to this at send time, fail closed when
    ///         unpinned). address(0) unpins. GOVERNOR_ROLE-only.
    function setStrategyDestinationAsset(address strategy, uint64 chainId, address asset) external;

    /// @notice Pin the fee library a Stargate `pool` was reviewed with (R4-P1 trust residual): the
    ///         core Stargate cap hook compares the pool's live `getAddressConfig().feeLib` to this
    ///         at send time and fails closed on mismatch, so a fee-library rotation by Stargate
    ///         governance can never silently change the quote/send equivalence the exact-delivery
    ///         check relies on. address(0) unpins (Stargate sends for that pool fail closed).
    ///         GOVERNOR_ROLE-only.
    function setStargateFeeLib(address pool, address feeLib) external;

    /// @notice Stargate route ENABLE switch (R3-RF1 / R4-F3 / R4-P1): 10_000 enables cap-enabled
    ///         Stargate sends, 0 disables them (fail closed); nothing else is accepted. Exactness is
    ///         NOT derived from this value — the core hook requires the encoded minAmountLD to
    ///         EQUAL amountLD and quotes the pool at send time (quoteOFT), reverting unless
    ///         amountSentLD == amountReceivedLD == amount, so a fee state AND a reward state (credit
    ///         above the amount) both fail closed before any approval or send. GOVERNOR_ROLE-only.
    function setStargateMinDeliveryBps(uint256 bps) external;

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

    /// @notice Whether `adapter` is an approved transport adapter for `chainId` (cap-hook read)
    function isApprovedAdapter(uint64 chainId, address adapter) external view returns (bool);

    /// @notice The canonical destination hook pair for `chainId` (cap-hook read); (0,0) = unset,
    ///         which blocks every VAULT_DEPOSIT destination action for that chain
    function destinationHooks(uint64 chainId) external view returns (address approveHook, address depositHook);

    /// @notice Canonical EVM chain id for a LayerZero endpoint id; 0 = unmapped (cap-hook read)
    function chainIdForEid(uint32 eid) external view returns (uint64);

    /// @notice The pinned asset of an approved destination vault; 0 = unpinned (cap-hook read)
    function destinationVaultAsset(uint64 chainId, address vault) external view returns (address);

    /// @notice The destination token a Stargate source pool delivers on a chain; 0 = unmapped
    function stargateDstToken(address srcPool, uint64 chainId) external view returns (address);

    /// @notice Stargate route enable switch: 10_000 = enabled, 0 = disabled (fail closed). Exactness is
    ///         enforced by the core hook (minAmountLD == amountLD + runtime quoteOFT), not by this value
    function stargateMinDeliveryBps() external view returns (uint256);
    function strategyHubAsset(address strategy) external view returns (address);
    function strategyDestinationAsset(address strategy, uint64 chainId) external view returns (address);
    function stargateFeeLib(address pool) external view returns (address);
}
