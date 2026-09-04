// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ICrossChainHooksRootScreener
/// @author Superform Labs
/// @notice Permissionless default-deny CHALLENGE layer for the SEC-1/K3 invariant ("no raw
///         value-exit hooks on a cap-enabled strategy"), built ADDITIVELY on the deployed stack:
///         the screener holds GUARDIAN_ROLE and anyone can (a) veto a strategy/global root by
///         proving it contains a banned leaf, or (b) veto a screened strategy whose proposed root
///         governance has not cleared. TRUST MODEL (stated plainly): the deployed aggregator does
///         NOT consult this contract during root activation or hook validation, so enforcement
///         requires AT LEAST ONE live watcher transaction landing before an uncleared root
///         activates — a trusted-availability assumption, not synchronous machine enforcement.
///         Synchronous in-path enforcement (activation requiring clearance; validateHook
///         rejecting banned hooks for screened strategies) is queued for the next
///         SuperVaultAggregator release. Operational rules that make the window small: clear
///         every root BEFORE proposing it; never keep raw value-exit leaves in the global root;
///         run redundant watchers.
interface ICrossChainHooksRootScreener {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event BannedHookUpdated(address indexed hook, bool banned);
    event ScreenedStrategyUpdated(address indexed strategy, bool screened);
    event RootClearanceUpdated(address indexed strategy, bytes32 indexed root, bool cleared);
    event RootVetoed(
        address indexed strategy,
        bytes32 indexed root,
        address indexed bannedHook,
        bool proposedRoot,
        address challenger
    );
    event GlobalRootVetoed(bytes32 indexed root, address indexed bannedHook, bool proposedRoot, address challenger);
    event UnclearedProposalVetoed(address indexed strategy, bytes32 indexed root, address challenger);
    event ClearanceGracePeriodUpdated(uint256 period);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZERO_ADDRESS();
    error UNAUTHORIZED();
    error HOOK_NOT_BANNED();
    error STRATEGY_NOT_SCREENED();
    error NO_ROOT();
    error INVALID_PROOF();
    error ROOT_CLEARED();
    error PROPOSAL_IN_GRACE_PERIOD();
    error INVALID_GRACE_PERIOD();

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice Ban/unban a hook as a raw value-exit path (raw bridge/transfer hooks that bypass
    ///         the cross-chain cap). GOVERNOR_ROLE-only.
    function setBannedHook(address hook, bool banned) external;

    /// @notice Enroll/unenroll a cap-enabled strategy under screening. GOVERNOR_ROLE-only.
    function setScreenedStrategy(address strategy, bool screened) external;

    /// @notice Clear (or un-clear) an exact root hash for a screened strategy after governance has
    ///         reviewed its PUBLISHED leaf set (R2-K3 failure mode 2: an opaque root the manager
    ///         withholds leaves for must be default-DENIED, not default-allowed). Only cleared
    ///         roots survive `enforceProposalClearance`. GOVERNOR_ROLE-only.
    function setRootClearance(address strategy, bytes32 root, bool cleared) external;

    /// @notice Grace period after a root proposal before `enforceProposalClearance` may fire
    ///         (R3-PF3: governance's window to clear a benign root before anyone can veto the
    ///         strategy). Bounded to one day. GOVERNOR_ROLE-only.
    function setClearanceGracePeriod(uint256 period) external;

    /*//////////////////////////////////////////////////////////////
                            PERMISSIONLESS
    //////////////////////////////////////////////////////////////*/

    /// @notice Prove that a screened strategy's hooks root (proposed when `proposedRoot`, active
    ///         otherwise) contains a leaf for a banned hook, and veto it on-chain. Permissionless:
    ///         the Merkle opening IS the authorization. Leaves follow the standard construction
    ///         `keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))))`.
    /// @dev Un-vetoing stays with the human guardian/governor via the normal SuperGovernor path.
    function challengeRoot(
        address strategy,
        address hook,
        bytes calldata hookArgs,
        bytes32[] calldata proof,
        bool proposedRoot
    )
        external;

    /// @notice Prove that the GLOBAL hooks root (proposed when `proposedRoot`, active otherwise)
    ///         contains a banned hook's leaf, and veto the global root on-chain (R2-K3 failure
    ///         mode 1: the global root authorizes hooks for EVERY strategy, so a banned raw
    ///         value-exit leaf in it bypasses per-strategy screening). Permissionless.
    function challengeGlobalRoot(
        address hook,
        bytes calldata hookArgs,
        bytes32[] calldata proof,
        bool proposedRoot
    )
        external;

    /// @notice Default-deny for opaque strategy roots (R2-K3 failure mode 2): if a screened
    ///         strategy has a PROPOSED hooks root that governance has not explicitly cleared
    ///         (leaf set published + reviewed), anyone may veto the strategy immediately —
    ///         closing the withhold-the-leaves / race-the-timelock path. Permissionless.
    function enforceProposalClearance(address strategy) external;

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    function bannedHook(address hook) external view returns (bool);
    function screenedStrategy(address strategy) external view returns (bool);
    function clearedRoot(address strategy, bytes32 root) external view returns (bool);
    function banPolicyEpoch() external view returns (uint256);
    function clearanceGracePeriod() external view returns (uint256);
}
