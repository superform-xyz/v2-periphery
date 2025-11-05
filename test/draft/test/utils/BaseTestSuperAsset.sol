// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { PeripheryHelpers } from "../../../../test/utils/PeripheryHelpers.sol";
import { SuperRegistry } from "../../src/SuperRegistry.sol";
import { SuperGovernor } from "../../../../src/SuperGovernor.sol";

/// @title BaseTestSuperAsset
/// @notice Base test contract for SuperAsset and VaultBank tests that need SuperRegistry
abstract contract BaseTestSuperAsset is PeripheryHelpers {
    SuperRegistry public superRegistry;

    /// @notice Deploy SuperRegistry with the given admin addresses and prover
    /// @param superRegistryAdmin_ The address for super registry admin role
    /// @param registryAdmin_ The address for registry admin role
    /// @param prover_ The prover address
    function deploySuperRegistry(address superRegistryAdmin_, address registryAdmin_, address prover_) public {
        superRegistry = new SuperRegistry(superRegistryAdmin_, registryAdmin_, prover_);
    }
}
