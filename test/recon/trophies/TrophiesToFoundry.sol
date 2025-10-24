// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import {Test, console2} from "forge-std/Test.sol";

import {TargetFunctions} from "../TargetFunctions.sol";

// forge test --match-contract TrophiesToFoundry -vv
contract TrophiesToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();
    }
}
