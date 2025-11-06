// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

/// @title MerkleTreeBuilder
/// @notice Pure Solidity Merkle tree generation for testing hook configurations
/// @dev Generates Merkle trees matching OpenZeppelin's StandardMerkleTree.of() format
library MerkleTreeBuilder {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Represents a hook configuration for Merkle tree generation
    struct HookConfig {
        address hookAddress;
        bytes encodedArgs;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Builds a Merkle tree from hook configurations
    /// @param configs Array of hook configurations to include in the tree
    /// @return root The Merkle root hash
    function buildTree(HookConfig[] memory configs) internal pure returns (bytes32 root) {
        if (configs.length == 0) return bytes32(0);

        // Generate all leaves
        bytes32[] memory leaves = new bytes32[](configs.length);
        for (uint256 i; i < configs.length; i++) {
            leaves[i] = _createLeaf(configs[i].hookAddress, configs[i].encodedArgs);
        }

        // Sort leaves for deterministic tree
        leaves = _sortLeaves(leaves);

        // Build tree bottom-up
        return _buildTreeFromLeaves(leaves);
    }

    /// @notice Gets a Merkle proof for a specific hook configuration
    /// @param configs All configurations in the tree
    /// @param hookAddress The hook address to generate proof for
    /// @param hookArgs The hook arguments to generate proof for
    /// @return proof The Merkle proof (empty array for single-leaf trees)
    function getProof(
        HookConfig[] memory configs,
        address hookAddress,
        bytes memory hookArgs
    )
        internal
        pure
        returns (bytes32[] memory proof)
    {
        if (configs.length == 0) return new bytes32[](0);

        bytes32 targetLeaf = _createLeaf(hookAddress, hookArgs);

        // Generate all leaves
        bytes32[] memory leaves = new bytes32[](configs.length);
        for (uint256 i; i < configs.length; i++) {
            leaves[i] = _createLeaf(configs[i].hookAddress, configs[i].encodedArgs);
        }

        // Sort leaves
        leaves = _sortLeaves(leaves);

        // For single-leaf trees, return empty proof
        if (leaves.length == 1) {
            require(leaves[0] == targetLeaf, "MerkleTreeBuilder: leaf not in tree");
            return new bytes32[](0);
        }

        // Compute proof
        return _computeProof(leaves, targetLeaf);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a Merkle leaf for a hook configuration
    /// @dev Matches StandardMerkleTree.of() leaf format: keccak256(bytes.concat(keccak256(abi.encode(...))))
    /// @param hookAddress Address of the hook contract
    /// @param hookArgs Encoded arguments from inspect()
    /// @return leaf The Merkle leaf hash
    function _createLeaf(address hookAddress, bytes memory hookArgs) private pure returns (bytes32 leaf) {
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
    }

    /// @notice Sorts an array of bytes32 leaves
    /// @param leaves Array of leaf hashes to sort
    /// @return sorted The sorted array
    function _sortLeaves(bytes32[] memory leaves) private pure returns (bytes32[] memory sorted) {
        sorted = leaves;
        uint256 n = sorted.length;

        // Bubble sort (simple for small arrays in tests)
        for (uint256 i; i < n; i++) {
            for (uint256 j = i + 1; j < n; j++) {
                if (uint256(sorted[i]) > uint256(sorted[j])) {
                    bytes32 temp = sorted[i];
                    sorted[i] = sorted[j];
                    sorted[j] = temp;
                }
            }
        }

        return sorted;
    }

    /// @notice Builds a Merkle tree from sorted leaves
    /// @param leaves Array of sorted leaf hashes
    /// @return root The Merkle root hash
    function _buildTreeFromLeaves(bytes32[] memory leaves) private pure returns (bytes32 root) {
        uint256 n = leaves.length;

        if (n == 1) return leaves[0];

        // Build tree level by level
        bytes32[] memory currentLevel = leaves;

        while (currentLevel.length > 1) {
            uint256 nextLevelSize = (currentLevel.length + 1) / 2;
            bytes32[] memory nextLevel = new bytes32[](nextLevelSize);

            for (uint256 i; i < nextLevelSize; i++) {
                uint256 leftIndex = i * 2;
                uint256 rightIndex = leftIndex + 1;

                if (rightIndex < currentLevel.length) {
                    // Pair exists
                    nextLevel[i] = _hashPair(currentLevel[leftIndex], currentLevel[rightIndex]);
                } else {
                    // Odd element - promote to next level
                    nextLevel[i] = currentLevel[leftIndex];
                }
            }

            currentLevel = nextLevel;
        }

        return currentLevel[0];
    }

    /// @notice Computes a Merkle proof for a target leaf
    /// @param leaves Array of sorted leaf hashes
    /// @param targetLeaf The leaf to generate proof for
    /// @return proof Array of sibling hashes forming the proof
    function _computeProof(bytes32[] memory leaves, bytes32 targetLeaf) private pure returns (bytes32[] memory proof) {
        // Find the target leaf index
        int256 targetIndex = -1;
        for (uint256 i; i < leaves.length; i++) {
            if (leaves[i] == targetLeaf) {
                targetIndex = int256(i);
                break;
            }
        }

        require(targetIndex >= 0, "MerkleTreeBuilder: leaf not in tree");

        // Calculate proof depth
        uint256 depth = 0;
        uint256 tempSize = leaves.length;
        while (tempSize > 1) {
            depth++;
            tempSize = (tempSize + 1) / 2;
        }

        // Allocate proof array
        proof = new bytes32[](depth);
        uint256 proofIndex = 0;

        // Build proof by traversing up the tree
        bytes32[] memory currentLevel = leaves;
        uint256 currentIndex = uint256(targetIndex);

        while (currentLevel.length > 1) {
            // Find sibling index
            uint256 siblingIndex;
            if (currentIndex % 2 == 0) {
                // Current is left child, sibling is right
                siblingIndex = currentIndex + 1;
            } else {
                // Current is right child, sibling is left
                siblingIndex = currentIndex - 1;
            }

            // Add sibling to proof (if it exists)
            if (siblingIndex < currentLevel.length) {
                proof[proofIndex] = currentLevel[siblingIndex];
                proofIndex++;
            }

            // Move to next level
            uint256 nextLevelSize = (currentLevel.length + 1) / 2;
            bytes32[] memory nextLevel = new bytes32[](nextLevelSize);

            for (uint256 i; i < nextLevelSize; i++) {
                uint256 leftIndex = i * 2;
                uint256 rightIndex = leftIndex + 1;

                if (rightIndex < currentLevel.length) {
                    nextLevel[i] = _hashPair(currentLevel[leftIndex], currentLevel[rightIndex]);
                } else {
                    nextLevel[i] = currentLevel[leftIndex];
                }
            }

            currentLevel = nextLevel;
            currentIndex = currentIndex / 2;
        }

        // Resize proof array to actual size (may be smaller than depth if tree is unbalanced)
        if (proofIndex < depth) {
            bytes32[] memory resizedProof = new bytes32[](proofIndex);
            for (uint256 i; i < proofIndex; i++) {
                resizedProof[i] = proof[i];
            }
            return resizedProof;
        }

        return proof;
    }

    /// @notice Hashes a pair of nodes (always smaller hash first for consistency)
    /// @param left Left node hash
    /// @param right Right node hash
    /// @return hash The combined hash
    function _hashPair(bytes32 left, bytes32 right) private pure returns (bytes32 hash) {
        // Sort to maintain consistency with OpenZeppelin's StandardMerkleTree
        if (uint256(left) < uint256(right)) {
            return keccak256(abi.encodePacked(left, right));
        } else {
            return keccak256(abi.encodePacked(right, left));
        }
    }
}
