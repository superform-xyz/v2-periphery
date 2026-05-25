// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { ILayerZeroEndpointV2 } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

/// @notice Replace Horizen DVN with Superform DVN on HyperEVM OFT
/// Previous DVNs: Canary, Nethermind, Horizen, LZ Labs (4 required)
/// New DVNs:      Superform, Canary, Nethermind, LZ Labs (4 required, sorted ascending)
contract ReplaceDVNHyperEVM is Script {
    // ============ OFT ============

    address internal constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

    // ============ LayerZero Infra (HyperEVM) ============

    address internal constant LZ_ENDPOINT_HYPEREVM = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
    address internal constant SEND_LIB_HYPEREVM = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
    address internal constant RECEIVE_LIB_HYPEREVM = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;

    // ============ EIDs ============

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant FLARE_EID = 30295;

    // ============ Config Types ============

    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // ============ Confirmations (matches current on-chain config) ============

    uint64 internal constant CONFIRMATIONS = 20;

    // ============ DVN Addresses on HyperEVM (sorted ascending) ============
    // Superform:  0x8024Cb9EF7AC7bD51994BAf25F52BD43d924A331
    // Canary:     0x83342EC538dF0460e730a8F543Fe63063e2D44C4
    // Nethermind: 0x8E49eF1DfAe17e547CA0E7526FfDA81FbaCA810A
    // LZ Labs:    0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f

    address internal constant DVN_SUPERFORM_HYPEREVM = 0x8024Cb9EF7AC7bD51994BAf25F52BD43d924A331;
    address internal constant DVN_CANARY_HYPEREVM = 0x83342EC538dF0460e730a8F543Fe63063e2D44C4;
    address internal constant DVN_NETHERMIND_HYPEREVM = 0x8E49eF1DfAe17e547CA0E7526FfDA81FbaCA810A;
    address internal constant DVN_LZ_HYPEREVM = 0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f;

    // Horizen DVN being replaced (for reference only)
    address internal constant DVN_HORIZEN_HYPEREVM = 0xBB83Ecf372CbB6daa629ea9A9A53BEC6d601F229;

    function run() public {
        require(block.chainid == 999, "Must run on HyperEVM");

        console2.log("====== Replace Horizen DVN with Superform on HyperEVM ======");
        console2.log("OFT:", HYPEREVM_OFT);
        console2.log("");
        console2.log("Removing Horizen:", DVN_HORIZEN_HYPEREVM);
        console2.log("Adding Superform:", DVN_SUPERFORM_HYPEREVM);
        console2.log("");
        console2.log("New DVNs (sorted ascending):");
        console2.log("  1. Superform:", DVN_SUPERFORM_HYPEREVM);
        console2.log("  2. Canary:", DVN_CANARY_HYPEREVM);
        console2.log("  3. Nethermind:", DVN_NETHERMIND_HYPEREVM);
        console2.log("  4. LZ Labs:", DVN_LZ_HYPEREVM);
        console2.log("");

        // Sanity check: DVNs must be sorted ascending
        require(DVN_SUPERFORM_HYPEREVM < DVN_CANARY_HYPEREVM, "DVNs not sorted: Superform >= Canary");
        require(DVN_CANARY_HYPEREVM < DVN_NETHERMIND_HYPEREVM, "DVNs not sorted: Canary >= Nethermind");
        require(DVN_NETHERMIND_HYPEREVM < DVN_LZ_HYPEREVM, "DVNs not sorted: Nethermind >= LZ");

        address[] memory dvns = new address[](4);
        dvns[0] = DVN_SUPERFORM_HYPEREVM;
        dvns[1] = DVN_CANARY_HYPEREVM;
        dvns[2] = DVN_NETHERMIND_HYPEREVM;
        dvns[3] = DVN_LZ_HYPEREVM;

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: CONFIRMATIONS,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT_HYPEREVM);

        // --- ETH pathway (send + receive) ---
        console2.log("Setting send config for ETH pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, SEND_LIB_HYPEREVM, ETH_EID, ulnConfig);
        console2.log("Setting receive config for ETH pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, RECEIVE_LIB_HYPEREVM, ETH_EID, ulnConfig);

        // --- Base pathway (send + receive) ---
        console2.log("Setting send config for Base pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, SEND_LIB_HYPEREVM, BASE_EID, ulnConfig);
        console2.log("Setting receive config for Base pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, RECEIVE_LIB_HYPEREVM, BASE_EID, ulnConfig);

        // --- Flare pathway (send + receive) ---
        console2.log("Setting send config for Flare pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, SEND_LIB_HYPEREVM, FLARE_EID, ulnConfig);
        console2.log("Setting receive config for Flare pathway...");
        _setUlnConfig(endpoint, HYPEREVM_OFT, RECEIVE_LIB_HYPEREVM, FLARE_EID, ulnConfig);

        vm.stopBroadcast();

        console2.log("");
        console2.log("Horizen replaced with Superform on HyperEVM!");
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

/// @notice Replace Horizen DVN with Superform DVN on Flare OFT
/// Previous DVNs: Nethermind, LZ Labs, Canary, Horizen (4 required)
/// New DVNs:      Superform, Nethermind, LZ Labs, Canary (4 required, sorted ascending)
contract ReplaceDVNFlare is Script {
    // ============ OFT ============

    address internal constant FLARE_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;

    // ============ LayerZero Infra (Flare) ============

    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant SEND_LIB_FLARE = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address internal constant RECEIVE_LIB_FLARE = 0x2367325334447C5E1E0f1b3a6fB947b262F58312;

    // ============ EIDs ============

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant HYPEREVM_EID = 30367;

    // ============ Config Types ============

    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // ============ Confirmations (matches current on-chain config) ============

    uint64 internal constant CONFIRMATIONS = 20;

    // ============ DVN Addresses on Flare (sorted ascending) ============
    // Superform:  0x9B0f8cAdA2f412c17E6f848ebBd3CbDd09226A29
    // Nethermind: 0x9bCd17A654bffAa6f8fEa38D19661a7210e22196
    // LZ Labs:    0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD
    // Canary:     0xD791948db16AB4373FA394B74C727DDb7FB02520

    address internal constant DVN_SUPERFORM_FLARE = 0x9B0f8cAdA2f412c17E6f848ebBd3CbDd09226A29;
    address internal constant DVN_NETHERMIND_FLARE = 0x9bCd17A654bffAa6f8fEa38D19661a7210e22196;
    address internal constant DVN_LZ_FLARE = 0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD;
    address internal constant DVN_CANARY_FLARE = 0xD791948db16AB4373FA394B74C727DDb7FB02520;

    // Horizen DVN being replaced (for reference only)
    address internal constant DVN_HORIZEN_FLARE = 0xeAA5a170d2588F84773f965281F8611D61312832;

    function run() public {
        require(block.chainid == 14, "Must run on Flare");

        console2.log("====== Replace Horizen DVN with Superform on Flare ======");
        console2.log("OFT:", FLARE_OFT);
        console2.log("");
        console2.log("Removing Horizen:", DVN_HORIZEN_FLARE);
        console2.log("Adding Superform:", DVN_SUPERFORM_FLARE);
        console2.log("");
        console2.log("New DVNs (sorted ascending):");
        console2.log("  1. Superform:", DVN_SUPERFORM_FLARE);
        console2.log("  2. Nethermind:", DVN_NETHERMIND_FLARE);
        console2.log("  3. LZ Labs:", DVN_LZ_FLARE);
        console2.log("  4. Canary:", DVN_CANARY_FLARE);
        console2.log("");

        // Sanity check: DVNs must be sorted ascending
        require(DVN_SUPERFORM_FLARE < DVN_NETHERMIND_FLARE, "DVNs not sorted: Superform >= Nethermind");
        require(DVN_NETHERMIND_FLARE < DVN_LZ_FLARE, "DVNs not sorted: Nethermind >= LZ");
        require(DVN_LZ_FLARE < DVN_CANARY_FLARE, "DVNs not sorted: LZ >= Canary");

        address[] memory dvns = new address[](4);
        dvns[0] = DVN_SUPERFORM_FLARE;
        dvns[1] = DVN_NETHERMIND_FLARE;
        dvns[2] = DVN_LZ_FLARE;
        dvns[3] = DVN_CANARY_FLARE;

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: CONFIRMATIONS,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });

        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        // --- ETH pathway (send + receive) ---
        console2.log("Setting send config for ETH pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, SEND_LIB_FLARE, ETH_EID, ulnConfig);
        console2.log("Setting receive config for ETH pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, RECEIVE_LIB_FLARE, ETH_EID, ulnConfig);

        // --- Base pathway (send + receive) ---
        console2.log("Setting send config for Base pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, SEND_LIB_FLARE, BASE_EID, ulnConfig);
        console2.log("Setting receive config for Base pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, RECEIVE_LIB_FLARE, BASE_EID, ulnConfig);

        // --- HyperEVM pathway (send + receive) ---
        console2.log("Setting send config for HyperEVM pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, SEND_LIB_FLARE, HYPEREVM_EID, ulnConfig);
        console2.log("Setting receive config for HyperEVM pathway...");
        _setUlnConfig(endpoint, FLARE_OFT, RECEIVE_LIB_FLARE, HYPEREVM_EID, ulnConfig);

        vm.stopBroadcast();

        console2.log("");
        console2.log("Horizen replaced with Superform on Flare!");
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
