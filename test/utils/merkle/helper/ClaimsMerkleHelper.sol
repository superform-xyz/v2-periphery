// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MerkleTreeHelper } from "@superform-v2-core/test/utils/MerkleTreeHelper.sol";

abstract contract ClaimsMerkleHelper is MerkleTreeHelper {
    function _createClaimsTree(
        address[] memory users,
        address[] memory tokens,
        uint256[] memory amounts
    )
        internal
        pure
        returns (bytes32[][] memory proofs, bytes32 root, bytes32[] memory leaves)
    {
        leaves = new bytes32[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            // what Merkl distributor claim() does:
            // bytes32 leaf = keccak256(abi.encode(user, token, amount));
            leaves[i] = keccak256(abi.encode(users[i], tokens[i], amounts[i]));
        }

        (proofs, root) = _createValidatorMerkleTree(leaves);
    }
}
