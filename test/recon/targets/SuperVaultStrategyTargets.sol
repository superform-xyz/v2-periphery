// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";

import {vm} from "@chimera/Hevm.sol";
import {Panic} from "@recon/Panic.sol";
import {MockERC20} from "@recon/MockERC20.sol";

import "src/SuperVault/SuperVaultStrategy.sol";

import {YieldSourceType} from "test/recon/managers/YieldManager.sol";
import {BeforeAfter, OpType} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";

abstract contract SuperVaultStrategyTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// @dev Clamps the action type to 0 to add a vault as a yield source
    function superVaultStrategy_manageYieldSource_clamped(
        uint256 sourceType
    ) public {
        YieldSourceType clampedType = YieldSourceType(sourceType % 3); // 0=ERC4626, 1=ERC5115, 2=ERC7540
        address yieldSourceOracle = _getYieldSourceOracleForType(clampedType);

        superVaultStrategy_manageYieldSource(
            _getYieldSource(),
            yieldSourceOracle,
            0
        );
    }

    function superVaultStrategy_handleOperations7540_clamped(
        uint256 operation,
        uint256 amount
    ) public {
        operation %= 7; // clamp by the possible operation types in the enum
        superVaultStrategy_handleOperations7540(
            ISuperVaultStrategy.Operation(operation),
            _getActor(),
            _getActor(),
            amount
        );
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function superVaultStrategy_executeVaultFeeConfigUpdate() public asActor {
        superVaultStrategy.executeVaultFeeConfigUpdate();
    }

    function superVaultStrategy_handleOperations4626Deposit(
        address controller,
        uint256 assetsGross
    ) public asActor {
        superVaultStrategy.handleOperations4626Deposit(controller, assetsGross);
    }

    function superVaultStrategy_handleOperations4626Mint(
        address controller,
        uint256 sharesNet,
        uint256 assetsGross,
        uint256 assetsNet
    ) public asActor {
        superVaultStrategy.handleOperations4626Mint(
            controller,
            sharesNet,
            assetsGross,
            assetsNet
        );
    }

    function superVaultStrategy_handleOperations7540(
        ISuperVaultStrategy.Operation operation,
        address controller,
        address receiver,
        uint256 amount
    ) public asActor {
        superVaultStrategy.handleOperations7540(
            operation,
            controller,
            receiver,
            amount
        );
    }

    function superVaultStrategy_manageEmergencyWithdraw(
        uint8 action,
        address recipient,
        uint256 amount
    ) public asActor {
        superVaultStrategy.manageEmergencyWithdraw(action, recipient, amount);
    }

    function superVaultStrategy_manageYieldSource(
        address source,
        address oracle,
        uint8 actionType
    ) public asActor {
        superVaultStrategy.manageYieldSource(source, oracle, actionType);
    }

    function superVaultStrategy_manageYieldSources(
        address[] memory sources,
        address[] memory oracles,
        uint8[] memory actionTypes
    ) public asActor {
        superVaultStrategy.manageYieldSources(sources, oracles, actionTypes);
    }

    function superVaultStrategy_moveAccumulatorOnTransfer(
        address from,
        address to,
        uint256 shares
    ) public asActor {
        superVaultStrategy.moveAccumulatorOnTransfer(from, to, shares);
    }

    function superVaultStrategy_proposeVaultFeeConfigUpdate(
        uint256 performanceFeeBps,
        uint256 managementFeeBps,
        address recipient
    ) public asActor {
        superVaultStrategy.proposeVaultFeeConfigUpdate(
            performanceFeeBps,
            managementFeeBps,
            recipient
        );
    }

    function superVaultStrategy_updateMaxPPSSlippage(
        uint256 maxSlippageBps
    ) public asActor {
        superVaultStrategy.updateMaxPPSSlippage(maxSlippageBps);
    }
}
