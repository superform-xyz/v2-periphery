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
/// @notice K3 (PR #336 review): permissionless challenge layer for the SEC-1 invariant — a
///         cap-enabled strategy's hooks root must not contain a raw value-exit leaf (raw
///         bridge/transfer hooks that would bypass the cross-chain cap). Fully ADDITIVE to the
///         deployed stack:
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
///      REACTION is a permissionless on-chain action; the guarantee still depends on a live
///      watcher inside the timelock window (see the interface-level trust model).
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

    /// @notice Monotonic epoch of the banned-hook policy: every ban-list change invalidates all
    ///         prior root clearances (R3: a clearance must never outlive the policy it was
    ///         reviewed under).
    uint256 public banPolicyEpoch;

    /// @notice Grace period after a root proposal during which `enforceProposalClearance` cannot
    ///         fire — governance's window to land the clearance for a benign root before anyone
    ///         may veto the strategy (R3-PF3 availability mitigation). Best practice remains to
    ///         clear BEFORE proposing.
    uint256 public clearanceGracePeriod;

    /// @dev (strategy, root) => banPolicyEpoch + 1 at clearance time (0 = never cleared)
    mapping(address => mapping(bytes32 => uint256)) private _clearedAtEpoch;

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
    /// @dev R4: only a NEW ban bumps the policy epoch (all prior clearances were reviewed against
    ///      a weaker ban list, so they must be re-reviewed). Unbans and no-ops RELAX or keep the
    ///      policy — clearances reviewed under the stricter list remain valid, so a routine list
    ///      change cannot be used to grief every screened strategy into the uncleared-proposal
    ///      veto window.
    function setBannedHook(address hook, bool banned) external {
        _requireGovernor(msg.sender);
        if (hook == address(0)) revert ZERO_ADDRESS();
        if (banned && !bannedHook[hook]) ++banPolicyEpoch;
        bannedHook[hook] = banned;
        emit BannedHookUpdated(hook, banned);
    }

    /// @notice Set the proposal-clearance grace period (R3-PF3). GOVERNOR_ROLE-only; bounded to
    ///         one day AND strictly below the aggregator's root-update timelock — a grace period
    ///         that outlives the timelock would make the default-deny enforcement window empty
    ///         (the uncleared root activates before anyone may veto), structurally disarming K3
    ///         (R4-P1: the production timelock defaults to 15 minutes).
    function setClearanceGracePeriod(uint256 period) external {
        _requireGovernor(msg.sender);
        if (period > 1 days) revert INVALID_GRACE_PERIOD();
        ISuperVaultAggregator aggregator = ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR));
        if (address(aggregator) != address(0) && period >= aggregator.getHooksRootUpdateTimelock()) {
            revert INVALID_GRACE_PERIOD();
        }
        clearanceGracePeriod = period;
        emit ClearanceGracePeriodUpdated(period);
    }

    /// @inheritdoc ICrossChainHooksRootScreener
    function setScreenedStrategy(address strategy, bool screened) external {
        _requireGovernor(msg.sender);
        if (strategy == address(0)) revert ZERO_ADDRESS();
        screenedStrategy[strategy] = screened;
        emit ScreenedStrategyUpdated(strategy, screened);
    }

    /// @inheritdoc ICrossChainHooksRootScreener
    /// @dev A clearance is stamped with the CURRENT ban-policy epoch and is only valid while that
    ///      epoch lasts (see setBannedHook).
    function setRootClearance(address strategy, bytes32 root, bool cleared) external {
        _requireGovernor(msg.sender);
        if (strategy == address(0) || root == bytes32(0)) revert ZERO_ADDRESS();
        _clearedAtEpoch[strategy][root] = cleared ? banPolicyEpoch + 1 : 0;
        emit RootClearanceUpdated(strategy, root, cleared);
    }

    /// @inheritdoc ICrossChainHooksRootScreener
    function clearedRoot(address strategy, bytes32 root) public view returns (bool) {
        return _clearedAtEpoch[strategy][root] == banPolicyEpoch + 1;
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
    ///      is vetoable by anyone once the clearance grace period elapses. The veto blocks ALL
    ///      hook execution for the strategy until the human guardian lifts it after clearance.
    ///      HONEST LIMIT (R3-PF2): the deployed aggregator does not consult this contract, so an
    ///      uncleared root DOES activate if no one calls this function before its timelock
    ///      elapses (and activation clears the proposal slot this function reads). The guarantee
    ///      is only as strong as watcher availability during the timelock window — see the
    ///      interface-level trust model. Note the veto is STRATEGY-WIDE (the deployed flag is not
    ///      per-proposal), so firing this also halts the currently active root; the grace period
    ///      plus the clear-before-propose runbook rule keep benign proposals out of that path.
    function enforceProposalClearance(address strategy) external {
        if (!screenedStrategy[strategy]) revert STRATEGY_NOT_SCREENED();

        ISuperVaultAggregator aggregator = ISuperVaultAggregator(SUPER_GOVERNOR.getAddress(SUPER_VAULT_AGGREGATOR));
        (bytes32 root, uint256 effectiveTime) = aggregator.getProposedStrategyHooksRoot(strategy);
        if (root == bytes32(0)) revert NO_ROOT();
        if (clearedRoot(strategy, root)) revert ROOT_CLEARED();

        // R3-PF3: give governance a bounded window to clear a benign root before anyone may set
        // the (strategy-wide) veto. proposal time = effectiveTime - timelock. NOTE: this uses the
        // CURRENT timelock — a timelock change while a proposal is pending shifts the derived
        // proposal time (and with it the grace window) accordingly; the R4 clamp below keeps the
        // enforcement window non-empty regardless.
        uint256 timelock = aggregator.getHooksRootUpdateTimelock();
        uint256 proposedAt = effectiveTime - timelock;
        // R4-P1: if the configured grace would outlive the (possibly shrunk) timelock, fail
        // TOWARD enforceability — an empty enforcement window disarms default-deny entirely,
        // which is strictly worse than a skipped grace period.
        uint256 grace = clearanceGracePeriod >= timelock ? 0 : clearanceGracePeriod;
        if (block.timestamp < proposedAt + grace) revert PROPOSAL_IN_GRACE_PERIOD();

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
