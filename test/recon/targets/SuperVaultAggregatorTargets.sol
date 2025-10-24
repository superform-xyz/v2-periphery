// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import {Panic} from "@recon/Panic.sol";

import {ISuperVaultStrategy} from "src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import "src/SuperVault/SuperVaultAggregator.sol";

import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";

abstract contract SuperVaultAggregatorTargets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    function superVaultAggregator_proposeChangePrimaryManager_clamped() public {
        superVaultAggregator_proposeChangePrimaryManager(
            address(superVaultStrategy),
            _getActor()
        );
    }

    function superVaultAggregator_executeChangePrimaryManager_clamped() public {
        superVaultAggregator_executeChangePrimaryManager(
            address(superVaultStrategy)
        );
    }

    function superVaultAggregator_createVault_clamped(
        uint256 minUpdateInterval,
        uint256 maxStaleness,
        uint256 performanceFeeBps,
        uint256 managementFeeBps
    ) public {
        // Clamp values to reasonable ranges
        minUpdateInterval = minUpdateInterval % 3601; // Max 1 hour
        maxStaleness = (maxStaleness % 86400) + 301; // Between 5 minutes and 1 day
        performanceFeeBps = performanceFeeBps % 9001; // Max 90%
        managementFeeBps = managementFeeBps % 5001; // Max 50%

        // Create secondary managers array
        address[] memory secondaryManagers = new address[](1);

        ISuperVaultAggregator.VaultCreationParams
            memory params = ISuperVaultAggregator.VaultCreationParams({
                asset: _getAsset(),
                name: "SuperVault",
                symbol: "SV",
                mainManager: address(this),
                secondaryManagers: secondaryManagers,
                minUpdateInterval: minUpdateInterval,
                maxStaleness: maxStaleness,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: performanceFeeBps,
                    managementFeeBps: managementFeeBps,
                    recipient: address(this)
                })
            });

        superVaultAggregator_createVault(params);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function superVaultAggregator_addAuthorizedCaller(
        address strategy,
        address caller
    ) public asAdmin {
        superVaultAggregator.addAuthorizedCaller(strategy, caller);
    }

    function superVaultAggregator_addSecondaryManager(
        address strategy,
        address manager
    ) public asActor {
        superVaultAggregator.addSecondaryManager(strategy, manager);
    }

    /// @dev removed because only callable by oracle
    // function superVaultAggregator_batchForwardPPS(
    //     ISuperVaultAggregator.BatchForwardPPSArgs memory args
    // ) public asActor {
    //     superVaultAggregator.batchForwardPPS(args);
    // }

    /// @dev irrelevant for testing because we're bypassing hook validation
    // function superVaultAggregator_changeGlobalLeavesStatus(
    //     bytes32[] memory leaves,
    //     bool[] memory statuses,
    //     address strategy
    // ) public asActor {
    //     superVaultAggregator.changeGlobalLeavesStatus(
    //         leaves,
    //         statuses,
    //         strategy
    //     );
    // }

    function superVaultAggregator_claimUpkeep(uint256 amount) public asActor {
        superVaultAggregator.claimUpkeep(amount);
    }

    function superVaultAggregator_createVault(
        ISuperVaultAggregator.VaultCreationParams memory params
    ) public asActor {
        (
            address _superVault,
            address _strategy,
            address _escrow
        ) = superVaultAggregator.createVault(params);

        superVault = SuperVault(_superVault);
        superVaultStrategy = SuperVaultStrategy(payable(_strategy));
        superVaultEscrow = SuperVaultEscrow(_escrow);

        hasDeployedNewVault = true;
    }

    function superVaultAggregator_depositStake(
        address manager,
        uint256 amount
    ) public asActor {
        superVaultAggregator.depositStake(manager, amount);
    }

    function superVaultAggregator_depositUpkeep(uint256 amount) public asActor {
        superVaultAggregator.depositUpkeep(_getActor(), amount);
    }

    function superVaultAggregator_executeChangePrimaryManager(
        address strategy
    ) public asActor {
        superVaultAggregator.executeChangePrimaryManager(strategy);
    }

    /// @dev removed because we're bypassing hook validation
    // function superVaultAggregator_executeStrategyHooksRootUpdate(
    //     address strategy
    // ) public asActor {
    //     superVaultAggregator.executeStrategyHooksRootUpdate(strategy);
    // }

    /// @dev removed because only callable by oracle
    // function superVaultAggregator_forwardPPS(
    //     address updateAuthority,
    //     ISuperVaultAggregator.ForwardPPSArgs memory args
    // ) public asActor {
    //     superVaultAggregator.forwardPPS(updateAuthority, args);
    // }

    function superVaultAggregator_proposeChangePrimaryManager(
        address strategy,
        address newManager
    ) public asActor {
        superVaultAggregator.proposeChangePrimaryManager(strategy, newManager);
    }

    /// @dev removed because we're bypassing hook validation
    // function superVaultAggregator_proposeStrategyHooksRoot(
    //     address strategy,
    //     bytes32 newRoot
    // ) public asActor {
    //     superVaultAggregator.proposeStrategyHooksRoot(strategy, newRoot);
    // }

    function superVaultAggregator_removeAuthorizedCaller(
        address strategy,
        address caller
    ) public asActor {
        superVaultAggregator.removeAuthorizedCaller(strategy, caller);
    }

    function superVaultAggregator_removeSecondaryManager(
        address strategy,
        address manager
    ) public asActor {
        superVaultAggregator.removeSecondaryManager(strategy, manager);
    }

    function superVaultAggregator_updatePPSVerificationThresholds(
        address strategy,
        uint256 dispersionThreshold_,
        uint256 deviationThreshold_,
        uint256 mnThreshold_
    ) public asActor {
        superVaultAggregator.updatePPSVerificationThresholds(
            strategy,
            dispersionThreshold_,
            deviationThreshold_,
            mnThreshold_
        );
    }

    function superVaultAggregator_withdrawStake(uint256 amount) public asActor {
        superVaultAggregator.withdrawStake(amount);
    }

    function superVaultAggregator_withdrawUpkeep(
        uint256 amount
    ) public asActor {
        superVaultAggregator.withdrawUpkeep(amount);
    }
}
