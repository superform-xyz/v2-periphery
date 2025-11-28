// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import { BaseTargetFunctions } from "@chimera/BaseTargetFunctions.sol";
import { Properties } from "../Properties.sol";

import { SuperGovernor, FeeType } from "src/SuperGovernor.sol";

abstract contract SuperGovernorTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    function superGovernor_proposeGlobalHooksRoot_clamped(bytes32 /*newRoot*/) public {
        (bytes32 testRoot, ) = merkleHelper.generateTestHooksRoot(
            address(approveAndDeposit4626Hook), address(redeem4626Hook), _getYieldSource(), superVault.asset()
        );

        superGovernor_proposeGlobalHooksRoot(testRoot);
    }

    function superGovernor_proposeUpkeepPaymentsChange_clamped() public {
        superGovernor_proposeUpkeepPaymentsChange(true);
    }

    function superGovernor_proposeFee_clamped(uint256 feeTypeAsUint, uint256 value) public {
        feeTypeAsUint %= 3;
        superGovernor_proposeFee(FeeType(feeTypeAsUint), value);
    }

    function superGovernor_executeFeeUpdate_clamped(uint256 feeTypeAsUint) public {
        feeTypeAsUint %= 3;
        superGovernor_executeFeeUpdate(FeeType(feeTypeAsUint));
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function superGovernor_proposeFee(FeeType feeType, uint256 value) public asAdmin {
        superGovernor.proposeFee(feeType, value);
    }

    function superGovernor_executeFeeUpdate(FeeType feeType) public asAdmin {
        superGovernor.executeFeeUpdate(feeType);
    }

    function superGovernor_proposeMinStaleness(uint256 newMinStaleness) public asAdmin {
        superGovernor.proposeMinStaleness(newMinStaleness);
    }

    function superGovernor_executeMinStalenessChange() public asAdmin {
        superGovernor.executeMinStalenessChange();
    }

    function superGovernor_executeUpkeepClaim(uint256 amount) public asAdmin {
        superGovernor.executeUpkeepClaim(amount);
    }

    function superGovernor_proposeUpkeepPaymentsChange(bool enabled) public asAdmin {
        superGovernor.proposeUpkeepPaymentsChange(enabled);
    }

    function superGovernor_executeUpkeepPaymentsChange() public asAdmin {
        superGovernor.executeUpkeepPaymentsChange();
    }

    function superGovernor_proposeGlobalHooksRoot(bytes32 newRoot) public asAdmin {
        superGovernor.proposeGlobalHooksRoot(newRoot);
    }
}
