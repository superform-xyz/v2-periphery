// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { console2 } from "forge-std/console2.sol";

/// @title UpkeepPauseExecute
/// @notice Script to execute a previously proposed upkeep payments pause on SuperGovernor
/// @dev This script should only be run on mainnet (chain ID 1)
/// @dev The script executes the proposed change after the timelock period has elapsed
contract UpkeepPauseExecute is Script {
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

    /// @notice Execute the pending upkeep payments change (mainnet only)
    /// @param env Environment (0 = production, 2 = staging)
    /// @param chainId Chain ID (must be mainnet = 1)
    function run(uint256 env, uint64 chainId) external {
        console2.log("=== Executing Upkeep Payments Change ===");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);

        // Validate chain ID (mainnet only)
        require(chainId == MAINNET_CHAIN_ID, "UPKEEP_PAUSE_EXECUTE_MAINNET_ONLY");
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
        console2.log("Proposed status:", proposedStatus);
        console2.log("Effective time:", effectiveTime);
        console2.log("Current block timestamp:", block.timestamp);

        require(effectiveTime > 0, "NO_PENDING_UPKEEP_CHANGE");
        require(block.timestamp >= effectiveTime, "TIMELOCK_NOT_EXPIRED");

        // Start broadcast
        vm.startBroadcast();

        // Execute the change
        console2.log("");
        console2.log("[Step 1] Executing upkeep payments change...");
        governor.executeUpkeepPaymentsChange();
        console2.log("[Step 1] DONE - Executed upkeep payments change");

        vm.stopBroadcast();

        // Verify the change
        _verifyExecution(governor, proposedStatus);

        console2.log("");
        console2.log("=== Upkeep Payments Change Executed Successfully ===");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Verify the change was executed correctly
    function _verifyExecution(SuperGovernor governor, bool expectedStatus) internal view {
        console2.log("");
        console2.log("=== Verifying Execution ===");

        bool newStatus = governor.isUpkeepPaymentsEnabled();
        console2.log("New upkeep payments status:", newStatus);
        console2.log("Expected status:", expectedStatus);

        require(newStatus == expectedStatus, "VERIFICATION_FAILED: Status mismatch");

        // Verify no pending change remains
        (, uint256 effectiveTime) = governor.getProposedUpkeepPaymentsStatus();
        console2.log("Pending effective time (should be 0):", effectiveTime);

        console2.log("PASSED: Execution verified successfully");
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
