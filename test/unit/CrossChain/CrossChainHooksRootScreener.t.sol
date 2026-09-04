// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { CrossChainHooksRootScreener } from "../../../src/CrossChain/CrossChainHooksRootScreener.sol";
import { ICrossChainHooksRootScreener } from "../../../src/interfaces/CrossChain/ICrossChainHooksRootScreener.sol";
import { MockGovernorLite } from "./mocks/MockGovernorLite.sol";

/// @dev Aggregator stand-in exposing only the root getters the screener reads.
contract MockAggregatorRoots {
    mapping(address => bytes32) public activeRoot;
    mapping(address => bytes32) public proposedRoot;
    bytes32 public globalRoot;
    bytes32 public proposedGlobalRoot;

    function setActiveRoot(address strategy, bytes32 root) external {
        activeRoot[strategy] = root;
    }

    function setProposedRoot(address strategy, bytes32 root) external {
        proposedRoot[strategy] = root;
    }

    function setGlobalRoot(bytes32 root) external {
        globalRoot = root;
    }

    function setProposedGlobalRoot(bytes32 root) external {
        proposedGlobalRoot = root;
    }

    function getStrategyHooksRoot(address strategy) external view returns (bytes32) {
        return activeRoot[strategy];
    }

    function getProposedStrategyHooksRoot(address strategy) external view returns (bytes32, uint256) {
        return (proposedRoot[strategy], block.timestamp + 1 days);
    }

    function getGlobalHooksRoot() external view returns (bytes32) {
        return globalRoot;
    }

    function getProposedGlobalHooksRoot() external view returns (bytes32, uint256) {
        return (proposedGlobalRoot, block.timestamp + 1 days);
    }
}

contract CrossChainHooksRootScreenerTest is Test {
    CrossChainHooksRootScreener internal screener;
    MockGovernorLite internal governor;
    MockAggregatorRoots internal aggregator;

    address internal strategy = makeAddr("strategy");
    address internal rawBridgeHook = makeAddr("rawAcrossBridgeHook"); // banned raw value-exit hook
    address internal goodHook = makeAddr("cappedBridgeHook"); // allowed leaf sharing the tree

    bytes32 internal constant SUPER_VAULT_AGGREGATOR = keccak256("SUPER_VAULT_AGGREGATOR");

    bytes32 internal bannedLeaf;
    bytes32 internal goodLeaf;
    bytes32 internal root; // two-leaf tree: [bannedLeaf, goodLeaf]

    function setUp() public {
        governor = new MockGovernorLite();
        aggregator = new MockAggregatorRoots();
        screener = new CrossChainHooksRootScreener(address(governor));

        governor.setAddress(SUPER_VAULT_AGGREGATOR, address(aggregator));
        governor.grantRole(governor.GOVERNOR_ROLE(), address(this));

        screener.setBannedHook(rawBridgeHook, true);
        screener.setScreenedStrategy(strategy, true);

        // Standard leaf construction + OZ commutative pair hash.
        bannedLeaf = _leaf(rawBridgeHook, abi.encodePacked(makeAddr("token"), makeAddr("spender")));
        goodLeaf = _leaf(goodHook, abi.encodePacked(makeAddr("adapter")));
        root = _hashPair(bannedLeaf, goodLeaf);
    }

    function _leaf(address hook, bytes memory hookArgs) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    function _bannedProof() internal view returns (bytes32[] memory proof) {
        proof = new bytes32[](1);
        proof[0] = goodLeaf;
    }

    function _bannedArgs() internal returns (bytes memory) {
        return abi.encodePacked(makeAddr("token"), makeAddr("spender"));
    }

    /*//////////////////////////////////////////////////////////////
                        PERMISSIONLESS CHALLENGE
    //////////////////////////////////////////////////////////////*/

    /// K3: anyone who can open the PROPOSED root to a banned raw value-exit leaf vetoes it
    /// on-chain — the timelock window race is closed by machine, not by a monitored promise.
    function test_ChallengeProposedRoot_Vetoes() public {
        aggregator.setProposedRoot(strategy, root);

        vm.prank(makeAddr("anyWatcher")); // permissionless
        screener.challengeRoot(strategy, rawBridgeHook, _bannedArgs(), _bannedProof(), true);

        assertTrue(governor.strategyVetoed(strategy), "proposed root must be vetoed");
    }

    /// K3: an ACTIVE root containing a banned leaf is equally challengeable (stops execution).
    function test_ChallengeActiveRoot_Vetoes() public {
        aggregator.setActiveRoot(strategy, root);

        vm.prank(makeAddr("anyWatcher"));
        screener.challengeRoot(strategy, rawBridgeHook, _bannedArgs(), _bannedProof(), false);

        assertTrue(governor.strategyVetoed(strategy), "active root must be vetoed");
    }

    /// A single-leaf tree (root == leaf) challenges with an empty proof.
    function test_ChallengeSingleLeafRoot_EmptyProof() public {
        aggregator.setProposedRoot(strategy, bannedLeaf);
        screener.challengeRoot(strategy, rawBridgeHook, _bannedArgs(), new bytes32[](0), true);
        assertTrue(governor.strategyVetoed(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                              REJECTIONS
    //////////////////////////////////////////////////////////////*/

    function test_RevertIf_HookNotBanned() public {
        aggregator.setProposedRoot(strategy, root);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bannedLeaf;
        vm.expectRevert(ICrossChainHooksRootScreener.HOOK_NOT_BANNED.selector);
        screener.challengeRoot(strategy, goodHook, abi.encodePacked(makeAddr("adapter")), proof, true);
    }

    function test_RevertIf_StrategyNotScreened() public {
        address other = makeAddr("otherStrategy");
        aggregator.setProposedRoot(other, root);
        vm.expectRevert(ICrossChainHooksRootScreener.STRATEGY_NOT_SCREENED.selector);
        screener.challengeRoot(other, rawBridgeHook, _bannedArgs(), _bannedProof(), true);
    }

    function test_RevertIf_NoRoot() public {
        vm.expectRevert(ICrossChainHooksRootScreener.NO_ROOT.selector);
        screener.challengeRoot(strategy, rawBridgeHook, _bannedArgs(), _bannedProof(), true);
    }

    function test_RevertIf_BadProof() public {
        aggregator.setProposedRoot(strategy, root);
        bytes32[] memory badProof = new bytes32[](1);
        badProof[0] = keccak256("not-in-tree");
        vm.expectRevert(ICrossChainHooksRootScreener.INVALID_PROOF.selector);
        screener.challengeRoot(strategy, rawBridgeHook, _bannedArgs(), badProof, true);
    }

    /// A banned hook with DIFFERENT args than the committed leaf cannot forge a challenge.
    function test_RevertIf_ArgsDoNotMatchLeaf() public {
        aggregator.setProposedRoot(strategy, root);
        vm.expectRevert(ICrossChainHooksRootScreener.INVALID_PROOF.selector);
        screener.challengeRoot(
            strategy, rawBridgeHook, abi.encodePacked(makeAddr("differentArgs")), _bannedProof(), true
        );
    }

    /*//////////////////////////////////////////////////////////////
              GLOBAL-ROOT CHALLENGE (R2-K3 failure mode 1)
    //////////////////////////////////////////////////////////////*/

    /// R2-K3: the global root authorizes hooks for EVERY strategy — a banned leaf provable in it
    /// lets anyone veto the global root itself.
    function test_ChallengeGlobalRoot_ActiveVetoes() public {
        aggregator.setGlobalRoot(root);
        vm.prank(makeAddr("anyWatcher"));
        screener.challengeGlobalRoot(rawBridgeHook, _bannedArgs(), _bannedProof(), false);
        assertTrue(governor.globalVetoed(), "global root must be vetoed");
    }

    function test_ChallengeGlobalRoot_ProposedVetoes() public {
        aggregator.setProposedGlobalRoot(root);
        screener.challengeGlobalRoot(rawBridgeHook, _bannedArgs(), _bannedProof(), true);
        assertTrue(governor.globalVetoed());
    }

    function test_ChallengeGlobalRoot_RevertBadProof() public {
        aggregator.setGlobalRoot(root);
        bytes32[] memory badProof = new bytes32[](1);
        badProof[0] = keccak256("not-in-tree");
        vm.expectRevert(ICrossChainHooksRootScreener.INVALID_PROOF.selector);
        screener.challengeGlobalRoot(rawBridgeHook, _bannedArgs(), badProof, false);
    }

    function test_ChallengeGlobalRoot_RevertUnbannedHook() public {
        aggregator.setGlobalRoot(root);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = bannedLeaf;
        vm.expectRevert(ICrossChainHooksRootScreener.HOOK_NOT_BANNED.selector);
        screener.challengeGlobalRoot(goodHook, abi.encodePacked(makeAddr("adapter")), proof, false);
    }

    /*//////////////////////////////////////////////////////////////
            DEFAULT-DENY ROOT CLEARANCE (R2-K3 failure mode 2)
    //////////////////////////////////////////////////////////////*/

    /// R2-K3: an opaque proposed root (leaf set withheld, unchallengeable) is default-DENIED —
    /// anyone can veto a screened strategy whose pending root governance has not cleared.
    function test_EnforceProposalClearance_VetoesUnclearedRoot() public {
        aggregator.setProposedRoot(strategy, keccak256("opaque-root-no-leaves-published"));
        vm.prank(makeAddr("anyWatcher"));
        screener.enforceProposalClearance(strategy);
        assertTrue(governor.strategyVetoed(strategy), "uncleared opaque proposal must be vetoable");
    }

    function test_EnforceProposalClearance_ClearedRootSurvives() public {
        bytes32 goodRoot = keccak256("reviewed-and-published-root");
        aggregator.setProposedRoot(strategy, goodRoot);
        screener.setRootClearance(strategy, goodRoot, true); // governance reviewed the leaf set

        vm.expectRevert(ICrossChainHooksRootScreener.ROOT_CLEARED.selector);
        screener.enforceProposalClearance(strategy);
        assertFalse(governor.strategyVetoed(strategy), "cleared root must not be vetoable this way");
    }

    function test_EnforceProposalClearance_RevertNoProposal() public {
        vm.expectRevert(ICrossChainHooksRootScreener.NO_ROOT.selector);
        screener.enforceProposalClearance(strategy);
    }

    function test_EnforceProposalClearance_RevertNotScreened() public {
        address other = makeAddr("otherStrategy");
        aggregator.setProposedRoot(other, keccak256("whatever"));
        vm.expectRevert(ICrossChainHooksRootScreener.STRATEGY_NOT_SCREENED.selector);
        screener.enforceProposalClearance(other);
    }

    function test_SetRootClearance_GovernorOnly() public {
        vm.prank(makeAddr("rando"));
        vm.expectRevert(ICrossChainHooksRootScreener.UNAUTHORIZED.selector);
        screener.setRootClearance(strategy, keccak256("r"), true);

        screener.setRootClearance(strategy, keccak256("r"), true);
        assertTrue(screener.clearedRoot(strategy, keccak256("r")));
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    function test_Setters_GovernorOnly() public {
        vm.startPrank(makeAddr("rando"));
        vm.expectRevert(ICrossChainHooksRootScreener.UNAUTHORIZED.selector);
        screener.setBannedHook(rawBridgeHook, false);
        vm.expectRevert(ICrossChainHooksRootScreener.UNAUTHORIZED.selector);
        screener.setScreenedStrategy(strategy, false);
        vm.stopPrank();

        screener.setBannedHook(rawBridgeHook, false);
        assertFalse(screener.bannedHook(rawBridgeHook));
        screener.setScreenedStrategy(strategy, false);
        assertFalse(screener.screenedStrategy(strategy));
    }

    function test_Constructor_RevertZeroGovernor() public {
        vm.expectRevert(ICrossChainHooksRootScreener.ZERO_ADDRESS.selector);
        new CrossChainHooksRootScreener(address(0));
    }
}
