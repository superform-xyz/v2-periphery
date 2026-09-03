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

    function setActiveRoot(address strategy, bytes32 root) external {
        activeRoot[strategy] = root;
    }

    function setProposedRoot(address strategy, bytes32 root) external {
        proposedRoot[strategy] = root;
    }

    function getStrategyHooksRoot(address strategy) external view returns (bytes32) {
        return activeRoot[strategy];
    }

    function getProposedStrategyHooksRoot(address strategy) external view returns (bytes32, uint256) {
        return (proposedRoot[strategy], block.timestamp + 1 days);
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
