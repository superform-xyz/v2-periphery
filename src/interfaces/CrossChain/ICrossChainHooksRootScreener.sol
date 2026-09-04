// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @title ICrossChainHooksRootScreener
/// @author Superform Labs
/// @notice Machine enforcement for the SEC-1/K3 invariant ("no raw value-exit hooks on a
///         cap-enabled strategy"), built ADDITIVELY on the deployed stack: the screener holds
///         GUARDIAN_ROLE on SuperGovernor, and ANYONE who can open a strategy's hooks root to a
///         governance-banned hook leaf triggers an on-chain veto of that root. No deployed
///         contract changes — enforcement rides the existing veto path
///         (SuperGovernor.setStrategyHooksRootVetoStatus -> SuperVaultAggregator).
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
}
