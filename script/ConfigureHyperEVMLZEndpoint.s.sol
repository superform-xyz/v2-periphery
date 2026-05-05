// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console2 } from "forge-std/Script.sol";

interface ILayerZeroEndpointV2 {
    struct SetConfigParam {
        uint32 eid;
        uint32 configType;
        bytes config;
    }

    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external;
    function setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod) external;
    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external;
}

/// @title ConfigureHyperEVMLZEndpoint
/// @notice Configures LZ Endpoint for ETH/Base -> HyperEVM OFT pathways (TX 3-6)
/// @dev These transactions can be executed by the delegate (deployer: 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8)
///
/// Simulate on Ethereum:
///   forge script script/ConfigureHyperEVMLZEndpoint.s.sol:ConfigureHyperEVMLZEndpointETH -f ethereum -vvv
///
/// Execute on Ethereum:
///   forge script script/ConfigureHyperEVMLZEndpoint.s.sol:ConfigureHyperEVMLZEndpointETH -f ethereum --broadcast -vvv
///
/// Simulate on Base:
///   forge script script/ConfigureHyperEVMLZEndpoint.s.sol:ConfigureHyperEVMLZEndpointBase -f base -vvv
///
/// Execute on Base:
///   forge script script/ConfigureHyperEVMLZEndpoint.s.sol:ConfigureHyperEVMLZEndpointBase -f base --broadcast -vvv
contract ConfigureHyperEVMLZEndpointETH is Script {
    // LayerZero constants
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 constant HYPEREVM_EID = 30367;

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

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        // TX 3: setSendLibrary
        console2.log("TX 3: Setting send library...");
        endpoint.setSendLibrary(ETH_ADAPTER, HYPEREVM_EID, SEND_LIB_ETH);
        console2.log("  Done: setSendLibrary");

        // TX 4: setReceiveLibrary
        console2.log("TX 4: Setting receive library...");
        endpoint.setReceiveLibrary(ETH_ADAPTER, HYPEREVM_EID, RECEIVE_LIB_ETH, 0);
        console2.log("  Done: setReceiveLibrary");

        // TX 5: setConfig for SendLib (Executor + ULN)
        console2.log("TX 5: Setting send config...");
        _setSendConfig(endpoint);
        console2.log("  Done: setConfig (SendLib)");

        // TX 6: setConfig for ReceiveLib (ULN only)
        console2.log("TX 6: Setting receive config...");
        _setReceiveConfig(endpoint);
        console2.log("  Done: setConfig (ReceiveLib)");

        vm.stopBroadcast();

        console2.log("");
        console2.log("All Ethereum LZ Endpoint configurations complete!");
    }

    function _setSendConfig(ILayerZeroEndpointV2 endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_ETH;

        address[] memory optionalDVNs = new address[](0);

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ExecutorConfig memory execConfig = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_ETH });

        ILayerZeroEndpointV2.SetConfigParam[] memory params = new ILayerZeroEndpointV2.SetConfigParam[](2);
        params[0] = ILayerZeroEndpointV2.SetConfigParam({
            eid: HYPEREVM_EID,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(execConfig)
        });
        params[1] = ILayerZeroEndpointV2.SetConfigParam({
            eid: HYPEREVM_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(ETH_ADAPTER, SEND_LIB_ETH, params);
    }

    function _setReceiveConfig(ILayerZeroEndpointV2 endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_ETH;

        address[] memory optionalDVNs = new address[](0);

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 1, // HyperEVM confirmations
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ILayerZeroEndpointV2.SetConfigParam[] memory params = new ILayerZeroEndpointV2.SetConfigParam[](1);
        params[0] = ILayerZeroEndpointV2.SetConfigParam({
            eid: HYPEREVM_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(ETH_ADAPTER, RECEIVE_LIB_ETH, params);
    }
}

contract ConfigureHyperEVMLZEndpointBase is Script {
    // LayerZero constants
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 constant HYPEREVM_EID = 30367;

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

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        // TX 3: setSendLibrary
        console2.log("TX 3: Setting send library...");
        endpoint.setSendLibrary(BASE_OFT, HYPEREVM_EID, SEND_LIB_BASE);
        console2.log("  Done: setSendLibrary");

        // TX 4: setReceiveLibrary
        console2.log("TX 4: Setting receive library...");
        endpoint.setReceiveLibrary(BASE_OFT, HYPEREVM_EID, RECEIVE_LIB_BASE, 0);
        console2.log("  Done: setReceiveLibrary");

        // TX 5: setConfig for SendLib (Executor + ULN)
        console2.log("TX 5: Setting send config...");
        _setSendConfig(endpoint);
        console2.log("  Done: setConfig (SendLib)");

        // TX 6: setConfig for ReceiveLib (ULN only)
        console2.log("TX 6: Setting receive config...");
        _setReceiveConfig(endpoint);
        console2.log("  Done: setConfig (ReceiveLib)");

        vm.stopBroadcast();

        console2.log("");
        console2.log("All Base LZ Endpoint configurations complete!");
    }

    function _setSendConfig(ILayerZeroEndpointV2 endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_BASE;

        address[] memory optionalDVNs = new address[](0);

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ExecutorConfig memory execConfig = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_BASE });

        ILayerZeroEndpointV2.SetConfigParam[] memory params = new ILayerZeroEndpointV2.SetConfigParam[](2);
        params[0] = ILayerZeroEndpointV2.SetConfigParam({
            eid: HYPEREVM_EID,
            configType: EXECUTOR_CONFIG_TYPE,
            config: abi.encode(execConfig)
        });
        params[1] = ILayerZeroEndpointV2.SetConfigParam({
            eid: HYPEREVM_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(BASE_OFT, SEND_LIB_BASE, params);
    }

    function _setReceiveConfig(ILayerZeroEndpointV2 endpoint) internal {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = DVN1_BASE;

        address[] memory optionalDVNs = new address[](0);

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: 1, // HyperEVM confirmations
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ILayerZeroEndpointV2.SetConfigParam[] memory params = new ILayerZeroEndpointV2.SetConfigParam[](1);
        params[0] = ILayerZeroEndpointV2.SetConfigParam({
            eid: HYPEREVM_EID,
            configType: ULN_CONFIG_TYPE,
            config: abi.encode(ulnConfig)
        });

        endpoint.setConfig(BASE_OFT, RECEIVE_LIB_BASE, params);
    }
}
