// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { console2 } from "forge-std/console2.sol";
import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperBuilderCodeRegistry } from "../src/attribution/SuperBuilderCodeRegistry.sol";
import { DeterministicDeployerLib } from "@superform-v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";

/// @title DeploySuperBuilderCodeRegistry
/// @notice Deploy only the builder registry on Base mainnet, using production locked bytecode.
/// @dev The configured production GOVERNOR receives admin and may register codes immediately.
contract DeploySuperBuilderCodeRegistry is DeployV2Base {
    string internal constant REGISTRY_KEY = "SuperBuilderCodeRegistry";
    address internal constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    error WRONG_CHAIN();
    error DEPENDENCY_NOT_DEPLOYED();
    error LOCKED_BYTECODE_MISMATCH();
    error RUNTIME_BYTECODE_MISMATCH();
    error GOVERNANCE_MISMATCH();

    /// @notice Check or deploy the Base production registry without redeploying any core contracts.
    /// @param check If true, validate and print the deterministic address without broadcasting or writing files.
    /// @return registry The deterministic registry address.
    function run(bool check) external returns (address registry) {
        _validateChain();
        _setBaseConfiguration(0, "");
        if (CREATE2_DEPLOYER.code.length == 0) {
            revert DEPENDENCY_NOT_DEPLOYED();
        }
        bytes memory bytecode = __getBytecode(REGISTRY_KEY, 0);
        _validateBytecode(bytecode);
        bytes memory creationCode = abi.encodePacked(bytecode, abi.encode(GOVERNOR));
        registry = DeterministicDeployerLib.computeAddress(creationCode, __getSalt(REGISTRY_KEY));
        if (registry.code.length > 0) _verifyRegistry(registry);

        console2.log("Base registry:", registry);
        console2.log("Governance:", GOVERNOR);
        console2.log("Already deployed:", registry.code.length > 0);
        if (check) return registry;

        vm.startBroadcast();
        registry = __deployContract(REGISTRY_KEY, BASE_CHAIN_ID, __getSalt(REGISTRY_KEY), creationCode);
        vm.stopBroadcast();
        _verifyRegistry(registry);

        // Forge simulates the script before broadcast. Update manifests only after independently
        // confirming the on-chain receipt, runtime and roles in postflight.
    }

    function _validateChain() internal view {
        if (block.chainid != BASE_CHAIN_ID) revert WRONG_CHAIN();
    }

    // Foundry's dynamic test linking resolves creationCode through its artifact cheatcode.
    function _validateBytecode(bytes memory bytecode) internal {
        if (keccak256(bytecode) != keccak256(type(SuperBuilderCodeRegistry).creationCode)) {
            revert LOCKED_BYTECODE_MISMATCH();
        }
    }

    function _verifyRegistry(address registry) internal view {
        if (registry.codehash != keccak256(type(SuperBuilderCodeRegistry).runtimeCode)) {
            revert RUNTIME_BYTECODE_MISMATCH();
        }
        if (!SuperBuilderCodeRegistry(registry).hasRole(bytes32(0), GOVERNOR)) {
            revert GOVERNANCE_MISMATCH();
        }
    }
}
