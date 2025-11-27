// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title MockMultisig
/// @notice Simulates a multisig wallet that can batch multiple calls in a single transaction
/// @dev Used for testing governance operations that would be batched in production
contract MockMultisig {
    /// @notice Execute multiple calls in a single transaction
    /// @param targets Array of target contract addresses
    /// @param data Array of calldata for each call
    /// @return results Array of return data from each call
    function executeBatch(
        address[] calldata targets,
        bytes[] calldata data
    ) external returns (bytes[] memory results) {
        require(targets.length == data.length, "Length mismatch");

        results = new bytes[](targets.length);

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].call(data[i]);
            require(success, "Call failed");
            results[i] = result;
        }
    }

    /// @notice Execute a single call (for granting roles, etc.)
    /// @param target Target contract address
    /// @param data Calldata for the call
    /// @return result Return data from the call
    function execute(address target, bytes calldata data) external returns (bytes memory result) {
        (bool success, bytes memory returnData) = target.call(data);
        require(success, "Call failed");
        return returnData;
    }
}
