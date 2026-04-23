// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { ILayerZeroEndpointV2 } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

/// @notice Update DVN send configs on Ethereum - ETH->Base, ETH->HyperEVM, ETH->Flare
/// DVNs: LayerZero Labs, Superform, Nethermind, Google Cloud (4 required, sorted ascending)
contract UpdateDVNsETH is Script {
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant UP_OFT_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address internal constant SEND_LIB = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;

    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant HYPEREVM_EID = 30367;
    uint32 internal constant FLARE_EID = 30295;
    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // DVNs on Ethereum (sorted ascending)
    address internal constant DVN_LZ = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address internal constant DVN_SUPERFORM = 0x7518f30bd5867b5fA86702556245Dead173afE46;
    address internal constant DVN_NETHERMIND = 0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5;
    address internal constant DVN_GOOGLE = 0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc;

    function run() public {
        require(block.chainid == 1, "Must run on Ethereum");
        require(DVN_LZ < DVN_SUPERFORM && DVN_SUPERFORM < DVN_NETHERMIND && DVN_NETHERMIND < DVN_GOOGLE, "DVNs not sorted");

        console2.log("====== Update DVN Send Configs on Ethereum ======");
        console2.log("OApp:", UP_OFT_ADAPTER);
        console2.log("Send Library:", SEND_LIB);
        console2.log("");
        console2.log("DVNs (sorted ascending):");
        console2.log("  1. LayerZero Labs:", DVN_LZ);
        console2.log("  2. Superform:", DVN_SUPERFORM);
        console2.log("  3. Nethermind:", DVN_NETHERMIND);
        console2.log("  4. Google Cloud:", DVN_GOOGLE);
        console2.log("");

        address[] memory dvns = new address[](4);
        dvns[0] = DVN_LZ;
        dvns[1] = DVN_SUPERFORM;
        dvns[2] = DVN_NETHERMIND;
        dvns[3] = DVN_GOOGLE;

        UlnConfig memory ulnSendToBase = _makeUlnConfig(15, dvns);
        UlnConfig memory ulnSendToHyperEVM = _makeUlnConfig(15, dvns);
        UlnConfig memory ulnSendToFlare = _makeUlnConfig(15, dvns);

        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        console2.log("Setting send config for ETH -> Base...");
        _setUlnConfig(endpoint, UP_OFT_ADAPTER, SEND_LIB, BASE_EID, ulnSendToBase);

        console2.log("Setting send config for ETH -> HyperEVM...");
        _setUlnConfig(endpoint, UP_OFT_ADAPTER, SEND_LIB, HYPEREVM_EID, ulnSendToHyperEVM);

        console2.log("Setting send config for ETH -> Flare...");
        _setUlnConfig(endpoint, UP_OFT_ADAPTER, SEND_LIB, FLARE_EID, ulnSendToFlare);

        vm.stopBroadcast();

        console2.log("");
        console2.log("DVN send configs updated successfully on Ethereum!");
    }

    function _setUlnConfig(
        ILayerZeroEndpointV2 endpoint,
        address oapp,
        address lib,
        uint32 remoteEid,
        UlnConfig memory uln
    ) internal {
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));
        endpoint.setConfig(oapp, lib, params);
    }

    function _makeUlnConfig(uint64 confirmations, address[] memory dvns) internal pure returns (UlnConfig memory) {
        return UlnConfig({
            confirmations: confirmations,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });
    }
}

/// @notice Update DVN send configs on Base - Base->ETH, Base->HyperEVM, Base->Flare
/// DVNs: LayerZero Labs, Nethermind, Google Cloud, Superform (4 required, sorted ascending)
contract UpdateDVNsBase is Script {
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant UP_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address internal constant SEND_LIB = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant HYPEREVM_EID = 30367;
    uint32 internal constant FLARE_EID = 30295;
    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // DVNs on Base (sorted ascending)
    address internal constant DVN_LZ = 0x9e059a54699a285714207b43B055483E78FAac25;
    address internal constant DVN_NETHERMIND = 0xcd37CA043f8479064e10635020c65FfC005d36f6;
    address internal constant DVN_GOOGLE = 0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc;
    address internal constant DVN_SUPERFORM = 0xEb62f578497Bdc351dD650853a751135212fAF49;

    function run() public {
        require(block.chainid == 8453, "Must run on Base");
        require(DVN_LZ < DVN_NETHERMIND && DVN_NETHERMIND < DVN_GOOGLE && DVN_GOOGLE < DVN_SUPERFORM, "DVNs not sorted");

        console2.log("====== Update DVN Send Configs on Base ======");
        console2.log("OApp:", UP_OFT);
        console2.log("Send Library:", SEND_LIB);
        console2.log("");
        console2.log("DVNs (sorted ascending):");
        console2.log("  1. LayerZero Labs:", DVN_LZ);
        console2.log("  2. Nethermind:", DVN_NETHERMIND);
        console2.log("  3. Google Cloud:", DVN_GOOGLE);
        console2.log("  4. Superform:", DVN_SUPERFORM);
        console2.log("");

        address[] memory dvns = new address[](4);
        dvns[0] = DVN_LZ;
        dvns[1] = DVN_NETHERMIND;
        dvns[2] = DVN_GOOGLE;
        dvns[3] = DVN_SUPERFORM;

        UlnConfig memory ulnSendToEth = _makeUlnConfig(10, dvns);
        UlnConfig memory ulnSendToHyperEVM = _makeUlnConfig(10, dvns);
        UlnConfig memory ulnSendToFlare = _makeUlnConfig(10, dvns);

        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        console2.log("Setting send config for Base -> ETH...");
        _setUlnConfig(endpoint, UP_OFT, SEND_LIB, ETH_EID, ulnSendToEth);

        console2.log("Setting send config for Base -> HyperEVM...");
        _setUlnConfig(endpoint, UP_OFT, SEND_LIB, HYPEREVM_EID, ulnSendToHyperEVM);

        console2.log("Setting send config for Base -> Flare...");
        _setUlnConfig(endpoint, UP_OFT, SEND_LIB, FLARE_EID, ulnSendToFlare);

        vm.stopBroadcast();

        console2.log("");
        console2.log("DVN send configs updated successfully on Base!");
    }

    function _setUlnConfig(
        ILayerZeroEndpointV2 endpoint,
        address oapp,
        address lib,
        uint32 remoteEid,
        UlnConfig memory uln
    ) internal {
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));
        endpoint.setConfig(oapp, lib, params);
    }

    function _makeUlnConfig(uint64 confirmations, address[] memory dvns) internal pure returns (UlnConfig memory) {
        return UlnConfig({
            confirmations: confirmations,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });
    }
}
