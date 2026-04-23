// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { ILayerZeroEndpointV2 } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

/// @notice Update DVN configs on HyperEVM OFT — upgrade from 1 DVN (LZ Labs) to 3 DVNs
/// DVNs: LayerZero Labs, Nethermind, Deutsche Telekom (sorted ascending)
/// A 4th DVN (Superform) will be added later after deployment
contract UpdateDVNsHyperEVM is Script {
    // ============ OFT ============

    address internal constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

    // ============ LayerZero Infra (HyperEVM) ============

    address internal constant LZ_ENDPOINT_HYPEREVM = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
    address internal constant SEND_LIB_HYPEREVM = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
    address internal constant RECEIVE_LIB_HYPEREVM = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;
    address internal constant EXECUTOR_HYPEREVM = 0x41Bdb4aa4A63a5b2Efc531858d3118392B1A1C3d;

    // ============ EIDs ============

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant FLARE_EID = 30295;

    // ============ Config Types ============

    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // ============ DVN Addresses on HyperEVM (sorted ascending) ============
    // Deutsche Telekom: 0x32fFd21260172518A8844feC76A88C8F239C384b
    // LayerZero Labs:   0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f
    // Nethermind:       0x8E49eF1DfAe17e547CA0E7526FfDA81FbaCA810A

    address internal constant DVN_DEUTSCHE_TELEKOM_HYPEREVM = 0x32fFd21260172518A8844feC76A88C8F239C384b;
    address internal constant DVN_LZ_HYPEREVM = 0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f;
    address internal constant DVN_NETHERMIND_HYPEREVM = 0x8E49eF1DfAe17e547CA0E7526FfDA81FbaCA810A;

    function run() public {
        require(block.chainid == 999, "Must run on HyperEVM");

        console2.log("====== Update DVNs on HyperEVM ======");
        console2.log("OFT:", HYPEREVM_OFT);
        console2.log("");
        console2.log("DVNs (sorted ascending):");
        console2.log("  1. Deutsche Telekom:", DVN_DEUTSCHE_TELEKOM_HYPEREVM);
        console2.log("  2. LayerZero Labs:", DVN_LZ_HYPEREVM);
        console2.log("  3. Nethermind:", DVN_NETHERMIND_HYPEREVM);
        console2.log("");

        // Sanity check: DVNs must be sorted ascending
        require(DVN_DEUTSCHE_TELEKOM_HYPEREVM < DVN_LZ_HYPEREVM, "DVNs not sorted");
        require(DVN_LZ_HYPEREVM < DVN_NETHERMIND_HYPEREVM, "DVNs not sorted");

        address[] memory dvns = new address[](3);
        dvns[0] = DVN_DEUTSCHE_TELEKOM_HYPEREVM;
        dvns[1] = DVN_LZ_HYPEREVM;
        dvns[2] = DVN_NETHERMIND_HYPEREVM;

        // HL→ETH: 1 HL block confirmation
        UlnConfig memory ulnSendToEth = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // HL receive from ETH: 15 ETH block confirmations
        UlnConfig memory ulnReceiveFromEth = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // HL→Base: 1 HL block confirmation
        UlnConfig memory ulnSendToBase = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // HL receive from Base: 10 Base block confirmations
        UlnConfig memory ulnReceiveFromBase = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // HL→Flare: 1 HL block confirmation
        UlnConfig memory ulnSendToFlare = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // HL receive from Flare: 1 Flare block confirmation
        UlnConfig memory ulnReceiveFromFlare = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT_HYPEREVM);

        // --- ETH pathway ---
        console2.log("Setting send config for ETH pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, SEND_LIB_HYPEREVM, ETH_EID, ulnSendToEth);
        console2.log("Setting receive config for ETH pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, RECEIVE_LIB_HYPEREVM, ETH_EID, ulnReceiveFromEth);

        // --- Base pathway ---
        console2.log("Setting send config for Base pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, SEND_LIB_HYPEREVM, BASE_EID, ulnSendToBase);
        console2.log("Setting receive config for Base pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, RECEIVE_LIB_HYPEREVM, BASE_EID, ulnReceiveFromBase);

        // --- Flare pathway ---
        console2.log("Setting send config for Flare pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, SEND_LIB_HYPEREVM, FLARE_EID, ulnSendToFlare);
        console2.log("Setting receive config for Flare pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, RECEIVE_LIB_HYPEREVM, FLARE_EID, ulnReceiveFromFlare);

        vm.stopBroadcast();

        console2.log("");
        console2.log("DVN configs updated successfully on HyperEVM!");
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
}

/// @notice Update DVN configs on Flare OFT — upgrade from 1 DVN (LZ Labs) to 3 DVNs
/// DVNs: Polyhedra zkBridge, Nethermind, LayerZero Labs (sorted ascending)
/// A 4th DVN (Superform) will be added later after deployment
contract UpdateDVNsFlare is Script {
    // ============ OFT ============

    address internal constant FLARE_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;

    // ============ LayerZero Infra (Flare — uses standard LZ_ENDPOINT) ============

    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant SEND_LIB_FLARE = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address internal constant RECEIVE_LIB_FLARE = 0x2367325334447C5E1E0f1b3a6fB947b262F58312;
    address internal constant EXECUTOR_FLARE = 0xcCE466a522984415bC91338c232d98869193D46e;

    // ============ EIDs ============

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant HYPEREVM_EID = 30367;

    // ============ Config Types ============

    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // ============ DVN Addresses on Flare (sorted ascending) ============
    // Polyhedra zkBridge: 0x8ddF05F9A5c488b4973897E278B58895bF87Cb24
    // Nethermind:         0x9bCd17A654bffAa6f8fEa38D19661a7210e22196
    // LayerZero Labs:     0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD

    address internal constant DVN_POLYHEDRA_FLARE = 0x8ddF05F9A5c488b4973897E278B58895bF87Cb24;
    address internal constant DVN_NETHERMIND_FLARE = 0x9bCd17A654bffAa6f8fEa38D19661a7210e22196;
    address internal constant DVN_LZ_FLARE = 0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD;

    function run() public {
        require(block.chainid == 14, "Must run on Flare");

        console2.log("====== Update DVNs on Flare ======");
        console2.log("OFT:", FLARE_OFT);
        console2.log("");
        console2.log("DVNs (sorted ascending):");
        console2.log("  1. Polyhedra zkBridge:", DVN_POLYHEDRA_FLARE);
        console2.log("  2. Nethermind:", DVN_NETHERMIND_FLARE);
        console2.log("  3. LayerZero Labs:", DVN_LZ_FLARE);
        console2.log("");

        // Sanity check: DVNs must be sorted ascending
        require(DVN_POLYHEDRA_FLARE < DVN_NETHERMIND_FLARE, "DVNs not sorted");
        require(DVN_NETHERMIND_FLARE < DVN_LZ_FLARE, "DVNs not sorted");

        address[] memory dvns = new address[](3);
        dvns[0] = DVN_POLYHEDRA_FLARE;
        dvns[1] = DVN_NETHERMIND_FLARE;
        dvns[2] = DVN_LZ_FLARE;

        // Flare→ETH: 1 Flare block confirmation
        UlnConfig memory ulnSendToEth = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // Flare receive from ETH: 15 ETH block confirmations
        UlnConfig memory ulnReceiveFromEth = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // Flare→Base: 1 Flare block confirmation
        UlnConfig memory ulnSendToBase = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // Flare receive from Base: 10 Base block confirmations
        UlnConfig memory ulnReceiveFromBase = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // Flare→HyperEVM: 1 Flare block confirmation
        UlnConfig memory ulnSendToHyperEVM = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        // Flare receive from HyperEVM: 1 HL block confirmation
        UlnConfig memory ulnReceiveFromHyperEVM = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        // --- ETH pathway ---
        console2.log("Setting send config for ETH pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, SEND_LIB_FLARE, ETH_EID, ulnSendToEth);
        console2.log("Setting receive config for ETH pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, RECEIVE_LIB_FLARE, ETH_EID, ulnReceiveFromEth);

        // --- Base pathway ---
        console2.log("Setting send config for Base pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, SEND_LIB_FLARE, BASE_EID, ulnSendToBase);
        console2.log("Setting receive config for Base pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, RECEIVE_LIB_FLARE, BASE_EID, ulnReceiveFromBase);

        // --- HyperEVM pathway ---
        console2.log("Setting send config for HyperEVM pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, SEND_LIB_FLARE, HYPEREVM_EID, ulnSendToHyperEVM);
        console2.log("Setting receive config for HyperEVM pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, RECEIVE_LIB_FLARE, HYPEREVM_EID, ulnReceiveFromHyperEVM);

        vm.stopBroadcast();

        console2.log("");
        console2.log("DVN configs updated successfully on Flare!");
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
}
