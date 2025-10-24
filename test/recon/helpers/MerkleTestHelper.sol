// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MerkleTestHelper
/// @notice Helper contract for generating test Merkle roots and proofs for hook validation
contract MerkleTestHelper {
    /// @notice Generate a test Merkle root for ERC4626 deposit and redeem hooks
    /// @param depositHook Address of the Deposit4626VaultHook or ApproveAndDeposit4626VaultHook contract
    /// @param redeemHook Address of the Redeem4626VaultHook contract  
    /// @param mockVault Address of the mock ERC4626 vault
    /// @param mockToken Address of the mock token (unused but kept for compatibility)
    /// @return root The Merkle root for the tree
    /// @return proofs Array of proofs for each leaf [depositProof, redeemProof]
    function generateTestHooksRoot(
        address depositHook,
        address redeemHook,
        address mockVault,
        address mockToken
    ) public pure returns (bytes32 root, bytes32[][] memory proofs) {
        // Create leaves for the two hooks following the exact format from SuperVaultAggregator._createLeaf()
        bytes32[] memory leaves = new bytes32[](2);
        
        // Leaf 1: Deposit hook with yield source only (what inspect() returns)
        // The inspect() function only returns abi.encodePacked(yieldSource)
        bytes memory depositArgs = abi.encodePacked(mockVault); // Only yield source address
        leaves[0] = keccak256(bytes.concat(keccak256(abi.encode(depositHook, depositArgs))));
        
        // Leaf 2: Redeem hook with yield source only (what inspect() returns)
        // The inspect() function only returns abi.encodePacked(yieldSource)
        bytes memory redeemArgs = abi.encodePacked(mockVault); // Only yield source address
        leaves[1] = keccak256(bytes.concat(keccak256(abi.encode(redeemHook, redeemArgs))));
        
        // Sort leaves to match standard Merkle tree ordering
        if (leaves[0] > leaves[1]) {
            (leaves[0], leaves[1]) = (leaves[1], leaves[0]);
        }
        
        // For a 2-leaf tree, root is hash of the sorted leaves
        root = keccak256(abi.encodePacked(leaves[0], leaves[1]));
        
        // Store original leaf hashes for proof assignment
        bytes32 depositLeaf = keccak256(bytes.concat(keccak256(abi.encode(depositHook, depositArgs))));
        bytes32 redeemLeaf = keccak256(bytes.concat(keccak256(abi.encode(redeemHook, redeemArgs))));
        
        // Generate proofs for each leaf
        proofs = new bytes32[][](2);
        proofs[0] = new bytes32[](1); // Proof for deposit hook
        proofs[1] = new bytes32[](1); // Proof for redeem hook
        
        // In a 2-leaf tree, each leaf's proof is just its sibling
        // Find which position each leaf ended up in after sorting
        if (leaves[0] == depositLeaf) {
            // depositHook is first leaf after sorting
            proofs[0][0] = leaves[1]; // Sibling of deposit leaf
            proofs[1][0] = leaves[0]; // Sibling of redeem leaf  
        } else {
            // redeemHook is first leaf after sorting
            proofs[0][0] = leaves[1]; // Sibling of deposit leaf
            proofs[1][0] = leaves[0]; // Sibling of redeem leaf
        }
        
        return (root, proofs);
    }
    
    /// @notice Generate encoded hook arguments for Deposit4626VaultHook
    /// @param yieldSource Address of the yield source vault
    /// @param amount Amount to deposit
    /// @param usePrevHookAmount Whether to use previous hook amount
    /// @return Encoded hook arguments
    function encodeDepositHookArgs(
        address yieldSource,
        uint256 amount,
        bool usePrevHookAmount
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            bytes32(0), // yieldSourceOracleId placeholder
            yieldSource,
            amount,
            usePrevHookAmount
        );
    }
    
    /// @notice Generate encoded hook arguments for Redeem4626VaultHook
    /// @param yieldSource Address of the yield source vault
    /// @param owner Address of the owner
    /// @param shares Number of shares to redeem
    /// @param usePrevHookAmount Whether to use previous hook amount
    /// @return Encoded hook arguments
    function encodeRedeemHookArgs(
        address yieldSource,
        address owner,
        uint256 shares,
        bool usePrevHookAmount
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            bytes32(0), // yieldSourceOracleId placeholder
            yieldSource,
            owner,
            shares,
            usePrevHookAmount
        );
    }
    
    /// @notice Generate encoded hook arguments for ApproveAndDeposit4626VaultHook
    /// @param yieldSource Address of the yield source vault
    /// @param token Address of the token to approve and deposit
    /// @param amount Amount to deposit
    /// @param usePrevHookAmount Whether to use previous hook amount
    /// @return Encoded hook arguments
    function encodeApproveAndDepositHookArgs(
        address yieldSource,
        address token,
        uint256 amount,
        bool usePrevHookAmount
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            bytes32(0), // yieldSourceOracleId placeholder
            yieldSource,
            token,
            amount,
            usePrevHookAmount
        );
    }
    
    /// @notice Create a leaf hash for a specific hook and arguments
    /// @param hookAddress Address of the hook contract
    /// @param hookArgs Encoded hook arguments
    /// @return leaf The leaf hash
    function createLeaf(address hookAddress, bytes memory hookArgs) public pure returns (bytes32 leaf) {
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
    }
    
    /// @notice Verify a Merkle proof against a root
    /// @param proof Array of proof elements
    /// @param root Merkle root
    /// @param leaf Leaf to verify
    /// @return True if proof is valid
    function verifyProof(bytes32[] memory proof, bytes32 root, bytes32 leaf) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}