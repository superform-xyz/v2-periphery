// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { console2 } from "forge-std/console2.sol";

/// @title ProposeUpkeepPause
/// @notice Emergency script to propose pausing upkeep payments on SuperGovernor
/// @dev This script should only be run on mainnet (chain ID 1)
/// @dev The script proposes to disable upkeep payments, which starts a timelock period
contract ProposeUpkeepPause is Script {
    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Production SuperGovernor address on mainnet
    address internal constant PROD_SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    /// @notice Staging SuperGovernor address on mainnet
    address internal constant STAGING_SUPER_GOVERNOR = 0x17FBa36DBc6122C8996F7690E3378de304ac7e52;

    /// @notice Mainnet chain ID
    uint64 internal constant MAINNET_CHAIN_ID = 1;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Propose pausing upkeep payments (mainnet only)
    /// @param env Environment (0 = production, 2 = staging)
    /// @param chainId Chain ID (must be mainnet = 1)
    function run(uint256 env, uint64 chainId) external {
        console2.log("=== Proposing Upkeep Payments Pause ===");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);

        // Validate chain ID (mainnet only)
        require(chainId == MAINNET_CHAIN_ID, "UPKEEP_PAUSE_MAINNET_ONLY");
        console2.log("Chain validation passed: mainnet");

        // Get SuperGovernor address
        address superGovernorAddr = _getSuperGovernorAddress(env);
        require(superGovernorAddr != address(0), "SUPER_GOVERNOR_NOT_FOUND");
        console2.log("SuperGovernor address:", superGovernorAddr);

        SuperGovernor governor = SuperGovernor(superGovernorAddr);

        // Check initial state
        console2.log("");
        console2.log("=== Initial State ===");
        bool currentStatus = governor.isUpkeepPaymentsEnabled();
        console2.log("Upkeep payments currently enabled:", currentStatus);

        // Check for pending changes
        (bool proposedStatus, uint256 effectiveTime) = governor.getProposedUpkeepPaymentsStatus();
        if (effectiveTime > 0) {
            console2.log("WARNING: There is already a pending upkeep payments change");
            console2.log("  Proposed status:", proposedStatus);
            console2.log("  Effective time:", effectiveTime);
        }

        // Start broadcast
        vm.startBroadcast();

        // Propose to disable upkeep payments
        console2.log("");
        console2.log("[Step 1] Proposing to disable upkeep payments...");
        governor.proposeUpkeepPaymentsChange(false);
        console2.log("[Step 1] DONE - Proposed upkeep payments change");

        vm.stopBroadcast();

        // Verify the proposal
        _verifyProposal(governor);

        console2.log("");
        console2.log("=== Upkeep Pause Proposal Complete ===");
        console2.log("NOTE: This is a proposal only. After the timelock period,");
        console2.log("      executeUpkeepPaymentsChange() must be called to finalize.");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Verify the proposal was registered correctly
    function _verifyProposal(SuperGovernor governor) internal view {
        console2.log("");
        console2.log("=== Verifying Proposal ===");

        (bool proposedStatus, uint256 effectiveTime) = governor.getProposedUpkeepPaymentsStatus();
        console2.log("Proposed status (should be false):", proposedStatus);
        console2.log("Effective time:", effectiveTime);
        console2.log("Current block timestamp:", block.timestamp);

        require(!proposedStatus, "VERIFICATION_FAILED: Proposed status should be false (disabled)");
        require(effectiveTime > block.timestamp, "VERIFICATION_FAILED: Effective time should be in the future");

        console2.log("PASSED: Proposal verified successfully");
    }

    /// @notice Get SuperGovernor address based on environment
    /// @dev Uses hardcoded addresses for mainnet prod/staging for reliability
    function _getSuperGovernorAddress(uint256 env) internal pure returns (address) {
        if (env == 0) {
            return PROD_SUPER_GOVERNOR;
        } else if (env == 2) {
            return STAGING_SUPER_GOVERNOR;
        }
        return address(0);
    }
}
