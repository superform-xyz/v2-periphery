// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console2 } from "forge-std/Script.sol";

interface ILayerZeroEndpointV2Flare {
    struct SetConfigParam {
        uint32 eid;
        uint32 configType;
        bytes config;
    }

    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external;
    function setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod) external;
    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external;
}

/// @title ConfigureFlareLZEndpointETH
/// @notice Configures LZ Endpoint for ETH -> Flare OFT pathway
/// @dev These transactions can be executed by the delegate (deployer: 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
///
/// Simulate on Ethereum:
///   forge script script/ConfigureFlareLZEndpoint.s.sol:ConfigureFlareLZEndpointETH -f ethereum -vvv
///
/// Execute on Ethereum:
///   forge script script/ConfigureFlareLZEndpoint.s.sol:ConfigureFlareLZEndpointETH -f ethereum --broadcast -vvv
contract ConfigureFlareLZEndpointETH is Script {
    // LayerZero constants
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 constant FLARE_EID = 30295;

    // Config types
    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;

    // Ethereum addresses
    address constant ETH_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address constant SEND_LIB_ETH = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address constant RECEIVE_LIB_ETH = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;
    address constant DVN1_ETH = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address constant EXECUTOR_ETH = 0x173272739Bd7Aa6e4e214714048a9fE699453059;

    // ULN Config struct
    struct UlnConfig {
        uint64 confirmations;
        uint8 requiredDVNCount;
        uint8 optionalDVNCount;
        uint8 optionalDVNThreshold;
        address[] requiredDVNs;
        address[] optionalDVNs;
    }

    // Executor Config struct
    struct ExecutorConfig {
        uint32 maxMessageSize;
        address executor;
    }

    function run() public {
        vm.startBroadcast();

        ILayerZeroEndpointV2Flare endpoint = ILayerZeroEndpointV2Flare(LZ_ENDPOINT);

        // TX 1: setSendLibrary (ETH -> Flare)
        console2.log("TX 1: Setting send library for Flare pathway...");
        endpoint.setSendLibrary(ETH_ADAPTER, FLARE_EID, SEND_LIB_ETH);
        console2.log("  Done: setSendLibrary");

        // TX 2: setReceiveLibrary (ETH <- Flare)
        console2.log("TX 2: Setting receive library for Flare pathway...");
        endpoint.setReceiveLibrary(ETH_ADAPTER, FLARE_EID, RECEIVE_LIB_ETH, 0);
        console2.log("  Done: setReceiveLibrary");

        // TX 3: setConfig for SendLib (Executor + ULN) - ETH -> Flare
        console2.log("TX 3: Setting send config (ETH -> Flare)...");
        _setSendConfig(endpoint);
        console2.log("  Done: setConfig (SendLib)");

        // TX 4: setConfig for ReceiveLib (ULN only) - ETH <- Flare
        console2.log("TX 4: Setting receive config (ETH <- Flare)...");
        _setReceiveConfig(endpoint);
        console2.log("  Done: setConfig (ReceiveLib)");

        vm.stopBroadcast();

        console2.log("");
        console2.log("All Ethereum -> Flare LZ Endpoint configurations complete!");
    }

    function _setSendConfig(ILayerZeroEndpointV2Flare endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_ETH;

        address[] memory optionalDVNs = new address[](0);

        // ETH -> Flare: 15 ETH confirmations (matches Flare receive config)
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ExecutorConfig memory execConfig = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_ETH });

        ILayerZeroEndpointV2Flare.SetConfigParam[] memory params =
            new ILayerZeroEndpointV2Flare.SetConfigParam[](2);
        params[0] = ILayerZeroEndpointV2Flare.SetConfigParam({
            eid: FLARE_EID,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(execConfig)
        });
        params[1] = ILayerZeroEndpointV2Flare.SetConfigParam({
            eid: FLARE_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(ETH_ADAPTER, SEND_LIB_ETH, params);
    }

    function _setReceiveConfig(ILayerZeroEndpointV2Flare endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_ETH;

        address[] memory optionalDVNs = new address[](0);

        // ETH <- Flare: 1 Flare confirmation (matches Flare send config)
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ILayerZeroEndpointV2Flare.SetConfigParam[] memory params =
            new ILayerZeroEndpointV2Flare.SetConfigParam[](1);
        params[0] = ILayerZeroEndpointV2Flare.SetConfigParam({
            eid: FLARE_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(ETH_ADAPTER, RECEIVE_LIB_ETH, params);
    }
}

/// @title ConfigureFlareLZEndpointBase
/// @notice Configures LZ Endpoint for Base -> Flare OFT pathway
/// @dev These transactions can be executed by the delegate (deployer: 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
///
/// Simulate on Base:
///   forge script script/ConfigureFlareLZEndpoint.s.sol:ConfigureFlareLZEndpointBase -f base -vvv
///
/// Execute on Base:
///   forge script script/ConfigureFlareLZEndpoint.s.sol:ConfigureFlareLZEndpointBase -f base --broadcast -vvv
contract ConfigureFlareLZEndpointBase is Script {
    // LayerZero constants
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 constant FLARE_EID = 30295;

    // Config types
    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;

    // Base addresses
    address constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address constant SEND_LIB_BASE = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address constant RECEIVE_LIB_BASE = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address constant DVN1_BASE = 0x9e059a54699a285714207b43B055483E78FAac25;
    address constant EXECUTOR_BASE = 0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4;

    // ULN Config struct
    struct UlnConfig {
        uint64 confirmations;
        uint8 requiredDVNCount;
        uint8 optionalDVNCount;
        uint8 optionalDVNThreshold;
        address[] requiredDVNs;
        address[] optionalDVNs;
    }

    // Executor Config struct
    struct ExecutorConfig {
        uint32 maxMessageSize;
        address executor;
    }

    function run() public {
        vm.startBroadcast();

        ILayerZeroEndpointV2Flare endpoint = ILayerZeroEndpointV2Flare(LZ_ENDPOINT);

        // TX 1: setSendLibrary (Base -> Flare)
        console2.log("TX 1: Setting send library for Flare pathway...");
        endpoint.setSendLibrary(BASE_OFT, FLARE_EID, SEND_LIB_BASE);
        console2.log("  Done: setSendLibrary");

        // TX 2: setReceiveLibrary (Base <- Flare)
        console2.log("TX 2: Setting receive library for Flare pathway...");
        endpoint.setReceiveLibrary(BASE_OFT, FLARE_EID, RECEIVE_LIB_BASE, 0);
        console2.log("  Done: setReceiveLibrary");

        // TX 3: setConfig for SendLib (Executor + ULN) - Base -> Flare
        console2.log("TX 3: Setting send config (Base -> Flare)...");
        _setSendConfig(endpoint);
        console2.log("  Done: setConfig (SendLib)");

        // TX 4: setConfig for ReceiveLib (ULN only) - Base <- Flare
        console2.log("TX 4: Setting receive config (Base <- Flare)...");
        _setReceiveConfig(endpoint);
        console2.log("  Done: setConfig (ReceiveLib)");

        vm.stopBroadcast();

        console2.log("");
        console2.log("All Base -> Flare LZ Endpoint configurations complete!");
    }

    function _setSendConfig(ILayerZeroEndpointV2Flare endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_BASE;

        address[] memory optionalDVNs = new address[](0);

        // Base -> Flare: 10 Base confirmations (matches Flare receive config)
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ExecutorConfig memory execConfig = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_BASE });

        ILayerZeroEndpointV2Flare.SetConfigParam[] memory params =
            new ILayerZeroEndpointV2Flare.SetConfigParam[](2);
        params[0] = ILayerZeroEndpointV2Flare.SetConfigParam({
            eid: FLARE_EID,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(execConfig)
        });
        params[1] = ILayerZeroEndpointV2Flare.SetConfigParam({
            eid: FLARE_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(BASE_OFT, SEND_LIB_BASE, params);
    }

    function _setReceiveConfig(ILayerZeroEndpointV2Flare endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_BASE;

        address[] memory optionalDVNs = new address[](0);

        // Base <- Flare: 1 Flare confirmation (matches Flare send config)
        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ILayerZeroEndpointV2Flare.SetConfigParam[] memory params =
            new ILayerZeroEndpointV2Flare.SetConfigParam[](1);
        params[0] = ILayerZeroEndpointV2Flare.SetConfigParam({
            eid: FLARE_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(BASE_OFT, RECEIVE_LIB_BASE, params);
    }
}
