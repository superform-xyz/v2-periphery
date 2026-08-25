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

    ISuperGovernor public immutable SUPER_GOVERNOR;

    mapping(address => CapConfig) private _caps;

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
        if (approved) _requireGovernor(msg.sender);
        else _requireManagerOrGovernor(strategy, msg.sender);

        if (destinationVault == address(0)) {
            _caps[strategy].idleHoldEnabled[chainId] = approved;
        } else {
            _caps[strategy].approvedDestinationVault[chainId][destinationVault] = approved;
        }
        emit DestinationApprovalUpdated(strategy, chainId, destinationVault, approved);
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
