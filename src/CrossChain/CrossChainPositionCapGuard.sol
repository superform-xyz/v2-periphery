// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ICrossChainPositionCapGuard } from "../interfaces/CrossChain/ICrossChainPositionCapGuard.sol";
import { ICrossChainAUMOracle } from "../interfaces/CrossChain/ICrossChainAUMOracle.sol";
import { ICrossChainPositionRegistry } from "../interfaces/CrossChain/ICrossChainPositionRegistry.sol";

/// @title CrossChainPositionCapGuard
/// @author Superform Labs
/// @notice Cap policy + destination allowlist for cross-chain SuperVault positions. Pure policy:
///         `validateAllocation` is a view that reverts; the enforcing caller is a
///         SuperVault*CapBridgeHook. See specs/cross-chain-supervaults/technical-spec.md.
contract CrossChainPositionCapGuard is ICrossChainPositionCapGuard {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant BPS_PRECISION = 10_000;

    bytes32 private constant CROSS_CHAIN_AUM_ORACLE = keccak256("CROSS_CHAIN_AUM_ORACLE");
    bytes32 private constant CROSS_CHAIN_POSITION_REGISTRY = keccak256("CROSS_CHAIN_POSITION_REGISTRY");
    bytes32 private constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Per-strategy cap configuration
    struct CapConfig {
        uint256 maxCrossChainBps; // global max % of AUM cross-chain
        mapping(uint64 => uint256) perChainCap; // per-chain cap (meaningful only if enabled)
        mapping(uint64 => bool) chainEnabled; // per-chain allowlist (unlisted = blocked, SEC-11)
        mapping(uint64 => mapping(address => bool)) approvedDestinationVault; // (chain, vault) allowlist
        mapping(uint64 => bool) idleHoldEnabled; // per-chain idle-hold escrow allowlist
    }

    /// @notice Canonical destination hook pair per chain (B1: the ONLY hooks a capped bridge's
    ///         destination action may execute — exactly [approve, deposit])
    struct DestinationHooks {
        address approveHook;
        address depositHook;
    }

    ISuperGovernor public immutable SUPER_GOVERNOR;

    mapping(address => CapConfig) private _caps;

    /// @dev B1: chain => approved transport adapters (the bridge receivers that forward to
    ///      SuperDestinationExecutor); global infra config, not a per-strategy risk dial
    mapping(uint64 => mapping(address => bool)) public isApprovedAdapter;

    /// @dev B1: chain => canonical destination hook pair
    mapping(uint64 => DestinationHooks) private _destinationHooks;

    /// @dev B4: LayerZero endpoint id => canonical EVM chain id (0 = unmapped, fail closed)
    mapping(uint32 => uint64) public chainIdForEid;

    /// @dev R3-RF3: (chainId, vault) => pinned vault asset (0 = unpinned, fail closed)
    mapping(uint64 => mapping(address => address)) public destinationVaultAsset;

    /// @dev R3-RF1: (stargate src pool, chainId) => delivered destination token (0 = unmapped)
    mapping(address => mapping(uint64 => address)) public stargateDstToken;

    /// @dev R3-RF1: hard minimum minAmountLD/amountLD ratio for Stargate sends (0 = unset)
    uint256 public stargateMinDeliveryBps;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
    }

    /*//////////////////////////////////////////////////////////////
                              ENFORCEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionCapGuard
    function validateAllocation(
        address strategy,
        uint64 destinationChainId,
        address destinationVault,
        uint256 amount
    )
        external
        view
    {
        CapConfig storage caps = _caps[strategy];

        // 1. Destination allowlist (constrained model) - the first gate.
        if (destinationVault == address(0)) {
            if (!caps.idleHoldEnabled[destinationChainId]) revert IDLE_HOLD_NOT_ENABLED();
        } else if (!caps.approvedDestinationVault[destinationChainId][destinationVault]) {
            revert DESTINATION_VAULT_NOT_APPROVED();
        }

        ICrossChainAUMOracle aumOracle = ICrossChainAUMOracle(SUPER_GOVERNOR.getAddress(CROSS_CHAIN_AUM_ORACLE));
        ICrossChainPositionRegistry registry =
            ICrossChainPositionRegistry(SUPER_GOVERNOR.getAddress(CROSS_CHAIN_POSITION_REGISTRY));

        // 2. Fresh AUM (also false for unconfigured strategies / tripped breaker - fail-safe).
        if (!aumOracle.isAUMFresh(strategy)) revert AUM_DATA_STALE();

        uint256 totalAUM = aumOracle.getTotalAUM(strategy);
        if (totalAUM == 0) revert ZERO_TOTAL_AUM();

        // 3. Global cap - numerator includes in-flight bridged-but-unconfirmed exposure (SEC-3).
        uint256 newCrossChain = registry.getEffectiveCrossChainExposure(strategy) + amount;
        if (newCrossChain * BPS_PRECISION > totalAUM * caps.maxCrossChainBps) revert CROSS_CHAIN_CAP_EXCEEDED();

        // 4. Per-chain cap - fail closed (SEC-11).
        if (!caps.chainEnabled[destinationChainId]) revert CHAIN_NOT_ENABLED();
        uint256 chainExposure = registry.getEffectiveChainExposure(strategy, destinationChainId) + amount;
        if (chainExposure > caps.perChainCap[destinationChainId]) revert PER_CHAIN_CAP_EXCEEDED();
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionCapGuard
    function setCapConfig(
        address strategy,
        uint256 maxCrossChainBps_,
        uint64[] calldata chainIds,
        uint256[] calldata chainCaps,
        bool[] calldata chainEnabled_
    )
        external
    {
        if (strategy == address(0)) revert ZERO_ADDRESS();
        if (chainIds.length != chainCaps.length || chainIds.length != chainEnabled_.length) revert LENGTH_MISMATCH();
        if (maxCrossChainBps_ > BPS_PRECISION) revert INVALID_CAP();

        CapConfig storage caps = _caps[strategy];

        // Loosening = raising the global cap, raising any per-chain cap, or enabling a chain.
        bool loosening = maxCrossChainBps_ > caps.maxCrossChainBps;
        for (uint256 i; i < chainIds.length; ++i) {
            if (chainCaps[i] > caps.perChainCap[chainIds[i]]) loosening = true;
            if (chainEnabled_[i] && !caps.chainEnabled[chainIds[i]]) loosening = true;
        }

        // SEC-2: loosening is governor-only; tightening may also be done by the primary manager.
        if (loosening) _requireGovernor(msg.sender);
        else _requireManagerOrGovernor(strategy, msg.sender);

        caps.maxCrossChainBps = maxCrossChainBps_;
        for (uint256 i; i < chainIds.length; ++i) {
            caps.perChainCap[chainIds[i]] = chainCaps[i];
            caps.chainEnabled[chainIds[i]] = chainEnabled_[i];
        }
        emit CapConfigUpdated(strategy, maxCrossChainBps_);
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function setApprovedDestination(
        address strategy,
        uint64 chainId,
        address destinationVault,
        bool approved
    )
        external
    {
        // Approving (enabling) is a loosening action -> governor-only (SEC-2). Revoking may also
        // be done by the primary manager (de-risk).
        if (strategy == address(0)) revert ZERO_ADDRESS();
        if (approved) _requireGovernor(msg.sender);
        else _requireManagerOrGovernor(strategy, msg.sender);

        if (destinationVault == address(0)) {
            _caps[strategy].idleHoldEnabled[chainId] = approved;
        } else {
            _caps[strategy].approvedDestinationVault[chainId][destinationVault] = approved;
        }
        emit DestinationApprovalUpdated(strategy, chainId, destinationVault, approved);
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function setDestinationAdapter(uint64 chainId, address adapter, bool approved) external {
        _requireGovernor(msg.sender);
        if (adapter == address(0)) revert ZERO_ADDRESS();
        isApprovedAdapter[chainId][adapter] = approved;
        emit DestinationAdapterUpdated(chainId, adapter, approved);
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    /// @dev Setting either hook to zero blocks every VAULT_DEPOSIT action for the chain (the cap
    ///      hooks fail closed on an unset pair); idle-hold actions are unaffected.
    function setDestinationHooks(uint64 chainId, address approveHook, address depositHook) external {
        _requireGovernor(msg.sender);
        _destinationHooks[chainId] = DestinationHooks({ approveHook: approveHook, depositHook: depositHook });
        emit DestinationHooksUpdated(chainId, approveHook, depositHook);
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function setEidChainId(uint32 eid, uint64 chainId) external {
        _requireGovernor(msg.sender);
        chainIdForEid[eid] = chainId;
        emit EidChainIdUpdated(eid, chainId);
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function setDestinationVaultAsset(uint64 chainId, address vault, address asset) external {
        _requireGovernor(msg.sender);
        if (vault == address(0)) revert ZERO_ADDRESS();
        destinationVaultAsset[chainId][vault] = asset;
        emit DestinationVaultAssetUpdated(chainId, vault, asset);
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function setStargateRoute(address srcPool, uint64 chainId, address dstToken) external {
        _requireGovernor(msg.sender);
        if (srcPool == address(0)) revert ZERO_ADDRESS();
        stargateDstToken[srcPool][chainId] = dstToken;
        emit StargateRouteUpdated(srcPool, chainId, dstToken);
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function setStargateMinDeliveryBps(uint256 bps) external {
        _requireGovernor(msg.sender);
        if (bps != 0 && (bps < 9000 || bps > BPS_PRECISION)) revert INVALID_CAP();
        stargateMinDeliveryBps = bps;
        emit StargateMinDeliveryBpsUpdated(bps);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainPositionCapGuard
    function isApprovedDestination(
        address strategy,
        uint64 chainId,
        address destinationVault
    )
        external
        view
        returns (bool)
    {
        return destinationVault == address(0)
            ? _caps[strategy].idleHoldEnabled[chainId]
            : _caps[strategy].approvedDestinationVault[chainId][destinationVault];
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function maxCrossChainBps(address strategy) external view returns (uint256) {
        return _caps[strategy].maxCrossChainBps;
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function perChainCap(address strategy, uint64 chainId) external view returns (uint256) {
        return _caps[strategy].perChainCap[chainId];
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function chainEnabled(address strategy, uint64 chainId) external view returns (bool) {
        return _caps[strategy].chainEnabled[chainId];
    }

    /// @inheritdoc ICrossChainPositionCapGuard
    function destinationHooks(uint64 chainId) external view returns (address approveHook, address depositHook) {
        DestinationHooks storage hooks = _destinationHooks[chainId];
        return (hooks.approveHook, hooks.depositHook);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @dev GOVERNOR_ROLE only. NOTE (SEC-2 follow-up): loosening should additionally be behind a
    ///      timelock + guardian veto; the governor here is a Safe multisig, and the timelock is a
    ///      documented follow-up (see technical-spec.md).
    function _requireGovernor(address account) internal view {
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.GOVERNOR_ROLE(), account)) {
            revert UNAUTHORIZED();
        }
    }

    /// @dev The strategy's primary manager (via the aggregator) or GOVERNOR_ROLE.
    function _requireManagerOrGovernor(address strategy, address account) internal view {
        if (IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.GOVERNOR_ROLE(), account)) return;
        address aggregator = SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR);
        if (aggregator != address(0) && ISuperVaultAggregator(aggregator).isMainManager(account, strategy)) return;
        revert UNAUTHORIZED();
    }
}
