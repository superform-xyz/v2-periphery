// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { MerkleTreeBuilder } from "./MerkleTreeBuilder.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";

/// @title SuperBankTestHelpers
/// @notice Helper functions for testing SuperBank with hook Merkle trees
library SuperBankTestHelpers {
    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a hook configuration for a hook with no arguments
    /// @param hookAddress The hook address
    /// @return config The hook configuration
    function createHookConfig(address hookAddress) internal pure returns (MerkleTreeBuilder.HookConfig memory config) {
        return MerkleTreeBuilder.HookConfig({ hookAddress: hookAddress, encodedArgs: "" });
    }

    /// @notice Creates a hook configuration with encoded arguments
    /// @param hookAddress The hook address
    /// @param encodedArgs The pre-encoded arguments
    /// @return config The hook configuration
    function createHookConfig(
        address hookAddress,
        bytes memory encodedArgs
    )
        internal
        pure
        returns (MerkleTreeBuilder.HookConfig memory config)
    {
        return MerkleTreeBuilder.HookConfig({ hookAddress: hookAddress, encodedArgs: encodedArgs });
    }

    /// @notice Creates a hook configuration by extracting args via inspect()
    /// @param hookAddress The hook address
    /// @param hookData The hook calldata
    /// @return config The hook configuration
    function createHookConfigFromData(
        address hookAddress,
        bytes memory hookData
    )
        internal
        view
        returns (MerkleTreeBuilder.HookConfig memory config)
    {
        bytes memory hookArgs;
        try ISuperHookInspector(hookAddress).inspect(hookData) returns (bytes memory args) {
            hookArgs = args;
        } catch {
            hookArgs = "";
        }

        return MerkleTreeBuilder.HookConfig({ hookAddress: hookAddress, encodedArgs: hookArgs });
    }

    /// @notice Builds a single-hook Merkle tree
    /// @param hookAddress The hook address
    /// @param encodedArgs The encoded arguments
    /// @return root The Merkle root
    /// @return proof The proof (empty for single-leaf tree)
    function setupSingleHookTree(
        address hookAddress,
        bytes memory encodedArgs
    )
        internal
        pure
        returns (bytes32 root, bytes32[] memory proof)
    {
        MerkleTreeBuilder.HookConfig[] memory configs = new MerkleTreeBuilder.HookConfig[](1);
        configs[0] = MerkleTreeBuilder.HookConfig({ hookAddress: hookAddress, encodedArgs: encodedArgs });

        root = MerkleTreeBuilder.buildTree(configs);
        proof = MerkleTreeBuilder.getProof(configs, hookAddress, encodedArgs);

        return (root, proof);
    }

    /// @notice Builds a multi-hook Merkle tree
    /// @param configs Array of hook configurations
    /// @return root The Merkle root
    function setupMultiHookTree(MerkleTreeBuilder.HookConfig[] memory configs) internal pure returns (bytes32 root) {
        return MerkleTreeBuilder.buildTree(configs);
    }

    /// @notice Gets a proof for a specific hook configuration in a multi-hook tree
    /// @param configs All configurations in the tree
    /// @param hookAddress The hook address to get proof for
    /// @param encodedArgs The encoded arguments for the hook
    /// @return proof The Merkle proof
    function getProofForHook(
        MerkleTreeBuilder.HookConfig[] memory configs,
        address hookAddress,
        bytes memory encodedArgs
    )
        internal
        pure
        returns (bytes32[] memory proof)
    {
        return MerkleTreeBuilder.getProof(configs, hookAddress, encodedArgs);
    }

    /// @notice Encodes arguments as addresses packed together
    /// @param addresses Array of addresses to encode
    /// @return encoded The packed addresses
    function encodeAddressArgs(address[] memory addresses) internal pure returns (bytes memory encoded) {
        return abi.encodePacked(addresses);
    }

    /// @notice Encodes two address arguments
    /// @param addr1 First address
    /// @param addr2 Second address
    /// @return encoded The packed addresses
    function encodeTwoAddresses(address addr1, address addr2) internal pure returns (bytes memory encoded) {
        return abi.encodePacked(addr1, addr2);
    }

    /// @notice Encodes three address arguments
    /// @param addr1 First address
    /// @param addr2 Second address
    /// @param addr3 Third address
    /// @return encoded The packed addresses
    function encodeThreeAddresses(
        address addr1,
        address addr2,
        address addr3
    )
        internal
        pure
        returns (bytes memory encoded)
    {
        return abi.encodePacked(addr1, addr2, addr3);
    }

    /// @notice Verifies a hook leaf matches expected format
    /// @param hookAddress The hook address
    /// @param encodedArgs The encoded arguments
    /// @return leaf The calculated leaf hash
    function calculateLeaf(address hookAddress, bytes memory encodedArgs) internal pure returns (bytes32 leaf) {
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, encodedArgs))));
    }
}
