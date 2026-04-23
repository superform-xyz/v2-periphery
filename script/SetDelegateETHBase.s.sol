// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";

/// @notice Set LZ endpoint delegate to SuperGovernor on Ethereum UpOFTAdapter
/// @dev Must be called by the current OFT owner (setDelegate is onlyOwner)
contract SetDelegateETH is Script {
    address internal constant UP_OFT_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address internal constant SUPER_GOVERNOR = 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e;

    function run() public {
        require(block.chainid == 1, "Must run on Ethereum");

        console2.log("====== Set Delegate on Ethereum UpOFTAdapter ======");
        console2.log("OApp:", UP_OFT_ADAPTER);
        console2.log("New delegate:", SUPER_GOVERNOR);

        vm.startBroadcast();
        IOAppCore(UP_OFT_ADAPTER).setDelegate(SUPER_GOVERNOR);
        vm.stopBroadcast();

        console2.log("Delegate set successfully!");
    }
}

/// @notice Set LZ endpoint delegate to SuperGovernor on Base UpOFT
/// @dev Must be called by the current OFT owner (setDelegate is onlyOwner)
contract SetDelegateBase is Script {
    address internal constant UP_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address internal constant SUPER_GOVERNOR = 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e;

    function run() public {
        require(block.chainid == 8453, "Must run on Base");

        console2.log("====== Set Delegate on Base UpOFT ======");
        console2.log("OApp:", UP_OFT);
        console2.log("New delegate:", SUPER_GOVERNOR);

        vm.startBroadcast();
        IOAppCore(UP_OFT).setDelegate(SUPER_GOVERNOR);
        vm.stopBroadcast();

        console2.log("Delegate set successfully!");
    }
}
