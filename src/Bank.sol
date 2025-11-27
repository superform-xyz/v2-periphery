// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// external
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Superform
import { IHookExecutionData } from "./interfaces/IHookExecutionData.sol";
import {
    ISuperHook,
    ISuperHookInspector,
    ISuperHookResult,
    Execution
} from "@superform-v2-core/src/interfaces/ISuperHook.sol";

abstract contract Bank is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error INVALID_HOOK();
    error INVALID_MERKLE_PROOF();
    error HOOK_VALIDATION_FAILED();
    error HOOK_EXECUTION_FAILED();
    error HOOK_NOT_REGISTERED();
    error ZERO_LENGTH_ARRAY();
    error ZERO_AMOUNT();
    error INVALID_ARRAY_LENGTH();
    error ZERO_ADDRESS();
    error MINIMUM_OUTPUT_AMOUNT_NOT_MET();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when hooks are executed.
    /// @param hooks The addresses of the hooks that were executed.
    /// @param data The data passed to each hook.
    event HooksExecuted(address[] hooks, bytes[] data);

    /*//////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _getMerkleRootForHook(address hookAddress) internal view virtual returns (bytes32);

    /// @notice Checks if a hook is registered.
    /// @param hookAddress The hook address to check.
    /// @return registered True if the hook is registered.
    function _isHookRegistered(address hookAddress) internal view virtual returns (bool);

    function _executeHooks(IHookExecutionData.HookExecutionData calldata executionData) internal virtual nonReentrant {
        uint256 hooksLength = executionData.hooks.length;
        if (hooksLength == 0) revert ZERO_LENGTH_ARRAY();

        // Validate arrays have matching lengths
        if (
            hooksLength != executionData.data.length || hooksLength != executionData.merkleProofs.length
                || hooksLength != executionData.expectedAssetsOrSharesOut.length
        ) {
            revert INVALID_ARRAY_LENGTH();
        }

        address prevHook;
        address hookAddress;
        bytes memory hookData;
        bytes32[] memory merkleProof;
        ISuperHook hook;
        bytes32 merkleRoot;
        Execution[] memory executions;
        Execution memory executionStep;
        bool success;
        uint256 expectedOutput;
        uint256 actualOutput;

        for (uint256 i; i < hooksLength; i++) {
            hookAddress = executionData.hooks[i];

            // Validate hook address is not zero
            if (hookAddress == address(0)) revert ZERO_ADDRESS();

            hookData = executionData.data[i];
            merkleProof = executionData.merkleProofs[i];
            expectedOutput = executionData.expectedAssetsOrSharesOut[i];

            hook = ISuperHook(hookAddress);

            // 1. Verify hook is registered
            if (!_isHookRegistered(hookAddress)) revert HOOK_NOT_REGISTERED();

            // 2. Get the Merkle root specific to this hook
            merkleRoot = _getMerkleRootForHook(hookAddress);

            // 3. VALIDATE HOOK CONFIGURATION
            if (!_validateHookConfiguration(hookAddress, hookData, merkleProof, merkleRoot)) {
                revert HOOK_VALIDATION_FAILED();
            }

            // 4. Set execution context
            hook.setExecutionContext(address(this));

            // 5. Build Execution Steps
            executions = hook.build(prevHook, address(this), hookData);

            uint256 len = executions.length;

            // 6. Execute all steps (no per-target validation needed)
            // Note: Uses all available gas for hook execution. Hooks are trusted and registered,
            // so unlimited gas is acceptable. This allows hooks to perform complex operations.
            // Note: Return data is discarded for gas efficiency. Hook failures will result in
            // generic HOOK_EXECUTION_FAILED error. For debugging, check hook contract logs or
            // use off-chain tooling to inspect failed transactions.
            for (uint256 j; j < len; ++j) {
                executionStep = executions[j];

                uint256 valueToSend = executionStep.value;
                address targetToCall = executionStep.target;
                bytes memory callData = executionStep.callData;

                // Execute the call
                // We call via assembly to avoid memcopying the returndata
                assembly {
                    success := call(
                        gas(), // gas - forwards all remaining gas (hooks are trusted)
                        targetToCall, // recipient
                        valueToSend, // ether value
                        add(callData, 0x20), // inloc
                        mload(callData), // inlen
                        0, // outloc
                        0 // outlen
                    )
                }

                if (!success) {
                    revert HOOK_EXECUTION_FAILED();
                }
            }

            // 6.5. VALIDATE OUTPUT AMOUNT (Slippage Protection)
            // Query the hook for actual output amount
            actualOutput = ISuperHookResult(address(hook)).getOutAmount(address(this));

            // Validate actual output meets or exceeds expected output
            // This protects against:
            // - MEV/front-running attacks
            // - Operator mistakes with wrong parameters
            // - Excessive slippage in swaps/conversions
            if (actualOutput < expectedOutput) {
                revert MINIMUM_OUTPUT_AMOUNT_NOT_MET();
            }

            // 7. Reset execution state after each hook
            hook.resetExecutionState(address(this));

            prevHook = hookAddress;
        }

        emit HooksExecuted(executionData.hooks, executionData.data);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a hook configuration using Merkle proof.
    /// @dev Validates the hook configuration (hook address + arguments from inspect()) instead of individual targets.
    /// @param hookAddress Address of the hook contract.
    /// @param hookData Calldata to pass to the hook.
    /// @param proof Merkle proof for this hook configuration.
    /// @param root Merkle root to verify against.
    /// @return valid True if the hook configuration is approved.
    function _validateHookConfiguration(
        address hookAddress,
        bytes memory hookData,
        bytes32[] memory proof,
        bytes32 root
    )
        private
        view
        returns (bool valid)
    {
        // If root is not set, reject
        if (root == bytes32(0)) return false;

        // Extract hook arguments using inspect()
        bytes memory hookArgs;
        try ISuperHookInspector(hookAddress).inspect(hookData) returns (bytes memory args) {
            hookArgs = args;
        } catch {
            // If hook doesn't implement ISuperHookInspector or inspect() fails, reject
            return false;
        }

        // Reject hooks with no address parameters (empty args)
        if (hookArgs.length == 0) return false;

        // Create leaf: keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
        bytes32 leaf = _createHookLeaf(hookAddress, hookArgs);

        // For single-leaf trees, empty proof is valid when root equals leaf
        if (proof.length == 0) {
            return root == leaf;
        }

        // Verify Merkle proof
        return MerkleProof.verify(proof, root, leaf);
    }

    /// @notice Creates a Merkle leaf for a hook configuration.
    /// @dev Matches StandardMerkleTree.of() leaf hashing: keccak256(bytes.concat(keccak256(abi.encode(...))))
    /// @param hookAddress Address of the hook contract.
    /// @param hookArgs Encoded arguments from inspect().
    /// @return leaf The Merkle leaf hash.
    function _createHookLeaf(address hookAddress, bytes memory hookArgs) private pure returns (bytes32 leaf) {
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
    }
}
