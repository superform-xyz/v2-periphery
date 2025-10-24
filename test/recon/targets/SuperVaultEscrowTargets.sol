// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/SuperVault/SuperVaultEscrow.sol";

abstract contract SuperVaultEscrowTargets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///


    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function superVaultEscrow_escrowShares(address from, uint256 amount) public asActor {
        superVaultEscrow.escrowShares(from, amount);
    }

    function superVaultEscrow_initialize(address vaultAddress, address strategyAddress) public asActor {
        superVaultEscrow.initialize(vaultAddress, strategyAddress);
    }

    function superVaultEscrow_returnShares(address to, uint256 amount) public asActor {
        superVaultEscrow.returnShares(to, amount);
    }
}