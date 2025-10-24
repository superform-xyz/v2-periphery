// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// External dependencies
import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {vm} from "@chimera/Hevm.sol";
import {Panic} from "@recon/Panic.sol";

// Source dependencies
import {IECDSAPPSOracle} from "src/interfaces/oracles/IECDSAPPSOracle.sol";
import "test/mocks/MockYieldSourceOracle.sol";
import "../mocks/MockERC4626YieldSourceOracle.sol";
import "../mocks/MockERC5115YieldSourceOracle.sol";
import "../mocks/MockERC7540YieldSourceOracle.sol";

// Test suite dependencies
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";

abstract contract OracleTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    function yieldSourceOracle_setValidAsset_clamped() public {
        mockERC4626YieldSourceOracle_setValidAsset(superVault.asset(), true);
    }

    function mockERC4626YieldSourceOracle_setValidAsset(
        address asset,
        bool isValid
    ) public asActor {
        MockERC4626YieldSourceOracle(address(erc4626YieldSourceOracle))
            .setValidAsset(asset, isValid);
    }

    function mockERC5115YieldSourceOracle_setValidAsset(
        address asset,
        bool isValid
    ) public asActor {
        MockERC5115YieldSourceOracle(address(erc5115YieldSourceOracle))
            .setValidAsset(asset, isValid);
    }

    function mockERC7540YieldSourceOracle_setValidAsset(
        address asset,
        bool isValid
    ) public asActor {
        MockERC7540YieldSourceOracle(address(erc7540YieldSourceOracle))
            .setValidAsset(asset, isValid);
    }

    function ECDSAPPSOracle_updatePPS_clamped(uint256 pps) public {
        pps %= (100_000_000 * 1e18) + 1; // clamp to a reasonable max price

        address[] memory strategies = new address[](1);
        strategies[0] = address(superVaultStrategy);

        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = new bytes[](0);

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = pps;

        uint256[] memory ppsStdevs = new uint256[](1);
        ppsStdevs[0] = 0;

        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = 0;

        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = 0;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        IECDSAPPSOracle.UpdatePPSArgs memory args = IECDSAPPSOracle
            .UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps
            });

        ECDSAPPSOracle_updatePPS(args);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
    function ECDSAPPSOracle_updatePPS(
        IECDSAPPSOracle.UpdatePPSArgs memory args
    ) public asActor {
        ECDSAPPSOracle.updatePPS(args);

        hasUpdatedPPS = true;
    }
}
