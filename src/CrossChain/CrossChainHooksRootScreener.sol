// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

// Superform
import { ISuperGovernor } from "../interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ICrossChainHooksRootScreener } from "../interfaces/CrossChain/ICrossChainHooksRootScreener.sol";

/// @title CrossChainHooksRootScreener
/// @author Superform Labs
/// @notice K3 (PR #336 review): machine enforcement of the SEC-1 invariant — a cap-enabled
///         strategy's hooks root must not contain a raw value-exit leaf (raw bridge/transfer
///         hooks that would bypass the cross-chain cap). Fully ADDITIVE to the deployed stack:
///         - governance bans the raw value-exit hook addresses and enrolls cap-enabled strategies;
///         - ANYONE who can open the strategy's proposed or active hooks root to a banned hook's
///           leaf calls `challengeRoot`, and the screener vetoes the root ON-CHAIN through the
///           existing SuperGovernor -> SuperVaultAggregator veto path.
///         The screener must be granted GUARDIAN_ROLE on SuperGovernor (a role grant, not a code
///         change). Proposed-root challenges close the timelock window race; active-root
///         challenges stop further executions under an already-live bad root. Un-vetoing stays
///         with the human guardian/governor.
/// @dev Off-chain, a watcher only needs the root's leaf set (published with every proposal) to
///      construct the opening — the challenge is then trustlessly verified here, so the guardian
///      reaction is no longer a monitored promise but a permissionless on-chain action.
contract CrossChainHooksRootScreener is ICrossChainHooksRootScreener {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    ISuperGovernor public immutable SUPER_GOVERNOR;

    /// @inheritdoc ICrossChainHooksRootScreener
    mapping(address => bool) public bannedHook;

    /// @inheritdoc ICrossChainHooksRootScreener
    mapping(address => bool) public screenedStrategy;

    /// @inheritdoc ICrossChainHooksRootScreener
    mapping(address => mapping(bytes32 => bool)) public clearedRoot;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert ZERO_ADDRESS();
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainHooksRootScreener
    function setBannedHook(address hook, bool banned) external {
        _requireGovernor(msg.sender);
        if (hook == address(0)) revert ZERO_ADDRESS();
        bannedHook[hook] = banned;
        emit BannedHookUpdated(hook, banned);
    }

    /// @inheritdoc ICrossChainHooksRootScreener
    function setScreenedStrategy(address strategy, bool screened) external {
        _requireGovernor(msg.sender);
        if (strategy == address(0)) revert ZERO_ADDRESS();
        screenedStrategy[strategy] = screened;
        emit ScreenedStrategyUpdated(strategy, screened);
    }

    /// @inheritdoc ICrossChainHooksRootScreener
    function setRootClearance(address strategy, bytes32 root, bool cleared) external {
        _requireGovernor(msg.sender);
        if (strategy == address(0) || root == bytes32(0)) revert ZERO_ADDRESS();
        clearedRoot[strategy][root] = cleared;
        emit RootClearanceUpdated(strategy, root, cleared);
    }

    /*//////////////////////////////////////////////////////////////
                            PERMISSIONLESS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICrossChainHooksRootScreener
    function challengeRoot(
        address strategy,
        address hook,
        bytes calldata hookArgs,
        bytes32[] calldata proof,
        bool proposedRoot
    )
        external
    {
        if (!screenedStrategy[strategy]) revert STRATEGY_NOT_SCREENED();
        if (!bannedHook[hook]) revert HOOK_NOT_BANNED();

        ISuperVaultAggregator aggregator = ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR));

        bytes32 root;
        if (proposedRoot) {
            (root,) = aggregator.getProposedStrategyHooksRoot(strategy);
        } else {
            root = aggregator.getStrategyHooksRoot(strategy);
        }
        if (root == bytes32(0)) revert NO_ROOT();

        // Standard leaf construction (StandardMerkleTree / hook-registration convention).
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));
        if (!MerkleProof.verify(proof, root, leaf)) revert INVALID_PROOF();

        // The opening IS the authorization: veto through the existing guardian path. (Vetoing is
        // idempotent-safe here; the aggregator no-ops event-wise on an unchanged status.)
        SUPER_GOVERNOR.setStrategyHooksRootVetoStatus(strategy, true);
        emit RootVetoed(strategy, root, hook, proposedRoot, msg.sender);
    }

    /// @inheritdoc ICrossChainHooksRootScreener
    /// @dev R2-K3 failure mode 1: `validateHook` authorizes through the GLOBAL root before the
    ///      strategy root, so a banned leaf there bypasses every per-strategy defense. The global
    ///      root is governance-proposed (leaf sets published with each proposal), so its openings
    ///      are always constructible — a provably-banned leaf lets ANYONE veto it. The global veto
    ///      halts hook execution protocol-wide until governance re-proposes a clean root: drastic,
    ///      and exactly the correct fail-safe for a value-exit leaf reachable by every strategy.
    function challengeGlobalRoot(
        address hook,
        bytes calldata hookArgs,
        bytes32[] calldata proof,
        bool proposedRoot
    )
        external
    {
        if (!bannedHook[hook]) revert HOOK_NOT_BANNED();

        ISuperVaultAggregator aggregator = ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR));

        bytes32 root;
        if (proposedRoot) {
            (root,) = aggregator.getProposedGlobalHooksRoot();
        } else {
            root = aggregator.getGlobalHooksRoot();
        }
        if (root == bytes32(0)) revert NO_ROOT();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));
        if (!MerkleProof.verify(proof, root, leaf)) revert INVALID_PROOF();

        SUPER_GOVERNOR.setGlobalHooksRootVetoStatus(true);
        emit GlobalRootVetoed(root, hook, proposedRoot, msg.sender);
    }

    /// @inheritdoc ICrossChainHooksRootScreener
    /// @dev R2-K3 failure mode 2: a proposed root is only a bytes32 commitment — a manager can
    ///      withhold its leaf set, making `challengeRoot` unconstructible during the timelock.
    ///      Default-deny inverts the burden: for a SCREENED strategy, any proposed root that
    ///      governance has not explicitly cleared (i.e. whose leaf set was published and reviewed)
    ///      is vetoable by anyone, immediately. The veto blocks ALL hook execution for the
    ///      strategy until the human guardian lifts it after clearance — an opaque root can never
    ///      ride the timelock into an executable state.
    function enforceProposalClearance(address strategy) external {
        if (!screenedStrategy[strategy]) revert STRATEGY_NOT_SCREENED();

        ISuperVaultAggregator aggregator = ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR));
        (bytes32 root,) = aggregator.getProposedStrategyHooksRoot(strategy);
        if (root == bytes32(0)) revert NO_ROOT();
        if (clearedRoot[strategy][root]) revert ROOT_CLEARED();

        SUPER_GOVERNOR.setStrategyHooksRootVetoStatus(strategy, true);
        emit UnclearedProposalVetoed(strategy, root, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _requireGovernor(address account) internal view {
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.GOVERNOR_ROLE(), account)) {
            revert UNAUTHORIZED();
        }
    }
}
