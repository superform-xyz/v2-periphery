// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console2 } from "forge-std/Script.sol";

interface ILayerZeroEndpointV2 {
    struct SetConfigParam {
        uint32 eid;
        uint32 configType;
        bytes config;
    }

    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external;
}

/// @title UpdateHyperEVMLZConfig
/// @notice Updates LZ ULN confirmations on HyperEVM to match the other side's configs
/// @dev
///   Changes:
///     1. HL→ETH send config: confirmations 15 → 1 (to match ETH receive = 1)
///     2. HL→Base send config: confirmations 15 → 1 (to match Base receive = 1)
///     3. HL receive from Base: confirmations 15 → 10 (to match Base send = 10)
///
///   Simulate:
///     forge script script/UpdateHyperEVMLZConfig.s.sol:UpdateHyperEVMLZConfig -f hyperevm -vvv
///
///   Execute:
///     forge script script/UpdateHyperEVMLZConfig.s.sol:UpdateHyperEVMLZConfig -f hyperevm --broadcast -vvv
contract UpdateHyperEVMLZConfig is Script {
    // LayerZero constants
    address constant LZ_ENDPOINT = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
    uint32 constant ETH_EID = 30101;
    uint32 constant BASE_EID = 30184;

    // Config types
    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;

    // HyperEVM addresses
    address constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    address constant SEND_LIB = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
    address constant RECEIVE_LIB = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;
    address constant DVN_LZ = 0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f;

    // ULN Config struct
    struct UlnConfig {
        uint64 confirmations;
        uint8 requiredDVNCount;
        uint8 optionalDVNCount;
        uint8 optionalDVNThreshold;
        address[] requiredDVNs;
        address[] optionalDVNs;
    }

    /// @notice Run all updates (ETH + Base paths)
    function run() public {
        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        // 1. Update HL→ETH send config: confirmations 15 → 1
        console2.log("TX 1: Updating send config for ETH path (confirmations: 15 -> 1)...");
        _updateSendConfig(endpoint, ETH_EID, 1);
        console2.log("  Done");

        // 2. Update HL→Base send config: confirmations 15 → 1
        console2.log("TX 2: Updating send config for Base path (confirmations: 15 -> 1)...");
        _updateSendConfig(endpoint, BASE_EID, 1);
        console2.log("  Done");

        // 3. Update HL receive from Base: confirmations 15 → 10
        console2.log("TX 3: Updating receive config for Base path (confirmations: 15 -> 10)...");
        _updateReceiveConfig(endpoint, BASE_EID, 10);
        console2.log("  Done");

        vm.stopBroadcast();

        console2.log("");
        console2.log("All HyperEVM LZ config updates complete!");
    }

    /// @notice Run only Base<>HL path updates
    function runBase() public {
        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        // 1. Update HL→Base send config: confirmations 15 → 1
        console2.log("TX 1: Updating send config for Base path (confirmations: 15 -> 1)...");
        _updateSendConfig(endpoint, BASE_EID, 1);
        console2.log("  Done");

        // 2. Update HL receive from Base: confirmations 15 → 10
        console2.log("TX 2: Updating receive config for Base path (confirmations: 15 -> 10)...");
        _updateReceiveConfig(endpoint, BASE_EID, 10);
        console2.log("  Done");

        vm.stopBroadcast();

        console2.log("");
        console2.log("Base<>HL config updates complete!");
    }

    /// @notice Run only ETH<>HL path update
    function runEth() public {
        vm.startBroadcast();

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        // 1. Update HL→ETH send config: confirmations 15 → 1
        console2.log("TX 1: Updating send config for ETH path (confirmations: 15 -> 1)...");
        _updateSendConfig(endpoint, ETH_EID, 1);
        console2.log("  Done");

        vm.stopBroadcast();

        console2.log("");
        console2.log("ETH<>HL config update complete!");
    }

    function _updateSendConfig(ILayerZeroEndpointV2 endpoint, uint32 remoteEid, uint64 confirmations) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN_LZ;

        address[] memory optionalDVNs = new address[](0);

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: confirmations,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ILayerZeroEndpointV2.SetConfigParam[] memory params = new ILayerZeroEndpointV2.SetConfigParam[](1);
        params[0] = ILayerZeroEndpointV2.SetConfigParam({
            eid: remoteEid,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(HYPEREVM_OFT, SEND_LIB, params);
    }

    function _updateReceiveConfig(ILayerZeroEndpointV2 endpoint, uint32 remoteEid, uint64 confirmations) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN_LZ;

        address[] memory optionalDVNs = new address[](0);

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: confirmations,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ILayerZeroEndpointV2.SetConfigParam[] memory params = new ILayerZeroEndpointV2.SetConfigParam[](1);
        params[0] = ILayerZeroEndpointV2.SetConfigParam({
            eid: remoteEid,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(HYPEREVM_OFT, RECEIVE_LIB, params);
    }
}
