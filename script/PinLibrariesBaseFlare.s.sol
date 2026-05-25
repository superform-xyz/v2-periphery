// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { ILayerZeroEndpointV2 } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

/// @notice Pin send and receive libraries on Base for the Base <-> Flare pathway
/// This must be done before DVN configs can take effect for this pathway
contract PinLibrariesBaseFlare is Script {
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;

    address internal constant SEND_LIB_BASE = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address internal constant RECEIVE_LIB_BASE = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;

    uint32 internal constant FLARE_EID = 30295;

    function run() public {
        require(block.chainid == 8453, "Must run on Base");

        console2.log("====== Pin Libraries on Base for Flare pathway ======");
        console2.log("OFT:", BASE_OFT);
        console2.log("Send Library:", SEND_LIB_BASE);
        console2.log("Receive Library:", RECEIVE_LIB_BASE);
        console2.log("Remote EID (Flare):", FLARE_EID);
        console2.log("");

        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        console2.log("TX 1: setSendLibrary (Base -> Flare)...");
        endpoint.setSendLibrary(BASE_OFT, FLARE_EID, SEND_LIB_BASE);

        console2.log("TX 2: setReceiveLibrary (Base <- Flare)...");
        endpoint.setReceiveLibrary(BASE_OFT, FLARE_EID, RECEIVE_LIB_BASE, 0);

        vm.stopBroadcast();

        console2.log("");
        console2.log("Libraries pinned on Base for Flare pathway!");
    }
}
