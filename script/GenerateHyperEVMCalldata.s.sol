// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script, console2 } from "forge-std/Script.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

interface IOAppCore {
    function setPeer(uint32 _eid, bytes32 _peer) external;
}

interface IOAppOptionsType3 {
    struct EnforcedOptionParam {
        uint32 eid;
        uint16 msgType;
        bytes options;
    }

    function setEnforcedOptions(EnforcedOptionParam[] calldata _enforcedOptions) external;
}

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

/// @title GenerateHyperEVMCalldata
/// @notice Generates calldata for configuring ETH/Base -> HyperEVM OFT pathways
/// @dev Run with: forge script script/GenerateHyperEVMCalldata.s.sol -vvv
contract GenerateHyperEVMCalldata is Script {
    using OptionsBuilder for bytes;

    // LayerZero constants
    address constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 constant HYPEREVM_EID = 30367;

    // Gas limits
    uint128 constant GAS_LIMIT = 300_000;
    uint128 constant COMPOSE_GAS_LIMIT = 1_000_000;

    // Message types
    uint16 constant SEND = 1;
    uint16 constant SEND_AND_CALL = 2;

    // Config types
    uint32 constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 constant ULN_CONFIG_TYPE = 2;

    // Ethereum libraries
    address constant SEND_LIB_ETH = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address constant RECEIVE_LIB_ETH = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;
    address constant DVN1_ETH = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address constant EXECUTOR_ETH = 0x173272739Bd7Aa6e4e214714048a9fE699453059;

    // Base libraries
    address constant SEND_LIB_BASE = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address constant RECEIVE_LIB_BASE = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address constant DVN1_BASE = 0x9e059a54699a285714207b43B055483E78FAac25;
    address constant EXECUTOR_BASE = 0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4;

    // Prod OFT addresses
    address constant ETH_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

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

    function run() public view {
        console2.log("================================================================================");
        console2.log("CALLDATA FOR ETH/BASE -> HYPEREVM CONFIGURATION");
        console2.log("================================================================================");
        console2.log("");

        _generateEthereumCalldata();
        _generateBaseCalldata();
    }

    function _generateEthereumCalldata() internal view {
        console2.log("================== ETHEREUM TRANSACTIONS ==================");
        console2.log("Target OFT Adapter:", ETH_ADAPTER);
        console2.log("LZ Endpoint:", LZ_ENDPOINT);
        console2.log("");

        // 1. setPeer
        console2.log("--- TX 1: setPeer on UpOFTAdapter ---");
        console2.log("To:", ETH_ADAPTER);
        bytes memory setPeerCalldata = abi.encodeWithSelector(
            IOAppCore.setPeer.selector, HYPEREVM_EID, bytes32(uint256(uint160(HYPEREVM_OFT)))
        );
        console2.log("Calldata:");
        console2.logBytes(setPeerCalldata);
        console2.log("");

        // 2. setEnforcedOptions
        console2.log("--- TX 2: setEnforcedOptions on UpOFTAdapter ---");
        console2.log("To:", ETH_ADAPTER);
        bytes memory enforcedOptionsCalldata = _getEnforcedOptionsCalldata(HYPEREVM_EID);
        console2.log("Calldata:");
        console2.logBytes(enforcedOptionsCalldata);
        console2.log("");

        // 3. setSendLibrary
        console2.log("--- TX 3: setSendLibrary on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setSendLibCalldata =
            abi.encodeWithSelector(ILayerZeroEndpointV2.setSendLibrary.selector, ETH_ADAPTER, HYPEREVM_EID, SEND_LIB_ETH);
        console2.log("Calldata:");
        console2.logBytes(setSendLibCalldata);
        console2.log("");

        // 4. setReceiveLibrary
        console2.log("--- TX 4: setReceiveLibrary on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setReceiveLibCalldata = abi.encodeWithSelector(
            ILayerZeroEndpointV2.setReceiveLibrary.selector,
            ETH_ADAPTER,
            HYPEREVM_EID,
            RECEIVE_LIB_ETH,
            0 // gracePeriod
        );
        console2.log("Calldata:");
        console2.logBytes(setReceiveLibCalldata);
        console2.log("");

        // 5. setConfig for SendLib (Executor + ULN)
        console2.log("--- TX 5: setConfig (SendLib) on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setSendConfigCalldata = _getSendConfigCalldata(ETH_ADAPTER, SEND_LIB_ETH, true);
        console2.log("Calldata:");
        console2.logBytes(setSendConfigCalldata);
        console2.log("");

        // 6. setConfig for ReceiveLib (ULN only)
        console2.log("--- TX 6: setConfig (ReceiveLib) on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setReceiveConfigCalldata = _getReceiveConfigCalldata(ETH_ADAPTER, RECEIVE_LIB_ETH, true);
        console2.log("Calldata:");
        console2.logBytes(setReceiveConfigCalldata);
        console2.log("");
    }

    function _generateBaseCalldata() internal view {
        console2.log("================== BASE TRANSACTIONS ==================");
        console2.log("Target OFT:", BASE_OFT);
        console2.log("LZ Endpoint:", LZ_ENDPOINT);
        console2.log("");

        // 1. setPeer
        console2.log("--- TX 1: setPeer on UpOFT ---");
        console2.log("To:", BASE_OFT);
        bytes memory setPeerCalldata = abi.encodeWithSelector(
            IOAppCore.setPeer.selector, HYPEREVM_EID, bytes32(uint256(uint160(HYPEREVM_OFT)))
        );
        console2.log("Calldata:");
        console2.logBytes(setPeerCalldata);
        console2.log("");

        // 2. setEnforcedOptions
        console2.log("--- TX 2: setEnforcedOptions on UpOFT ---");
        console2.log("To:", BASE_OFT);
        bytes memory enforcedOptionsCalldata = _getEnforcedOptionsCalldata(HYPEREVM_EID);
        console2.log("Calldata:");
        console2.logBytes(enforcedOptionsCalldata);
        console2.log("");

        // 3. setSendLibrary
        console2.log("--- TX 3: setSendLibrary on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setSendLibCalldata =
            abi.encodeWithSelector(ILayerZeroEndpointV2.setSendLibrary.selector, BASE_OFT, HYPEREVM_EID, SEND_LIB_BASE);
        console2.log("Calldata:");
        console2.logBytes(setSendLibCalldata);
        console2.log("");

        // 4. setReceiveLibrary
        console2.log("--- TX 4: setReceiveLibrary on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setReceiveLibCalldata = abi.encodeWithSelector(
            ILayerZeroEndpointV2.setReceiveLibrary.selector,
            BASE_OFT,
            HYPEREVM_EID,
            RECEIVE_LIB_BASE,
            0 // gracePeriod
        );
        console2.log("Calldata:");
        console2.logBytes(setReceiveLibCalldata);
        console2.log("");

        // 5. setConfig for SendLib (Executor + ULN)
        console2.log("--- TX 5: setConfig (SendLib) on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setSendConfigCalldata = _getSendConfigCalldata(BASE_OFT, SEND_LIB_BASE, false);
        console2.log("Calldata:");
        console2.logBytes(setSendConfigCalldata);
        console2.log("");

        // 6. setConfig for ReceiveLib (ULN only)
        console2.log("--- TX 6: setConfig (ReceiveLib) on LZ Endpoint ---");
        console2.log("To:", LZ_ENDPOINT);
        bytes memory setReceiveConfigCalldata = _getReceiveConfigCalldata(BASE_OFT, RECEIVE_LIB_BASE, false);
        console2.log("Calldata:");
        console2.logBytes(setReceiveConfigCalldata);
        console2.log("");
    }

    function _getEnforcedOptionsCalldata(uint32 dstEid) internal view returns (bytes memory) {
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);

        bytes memory sendAndCallOptions =
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0).addExecutorLzComposeOption(
                0, COMPOSE_GAS_LIMIT, 0
            );

        IOAppOptionsType3.EnforcedOptionParam[] memory enforcedOptions =
            new IOAppOptionsType3.EnforcedOptionParam[](2);
        enforcedOptions[0] =
            IOAppOptionsType3.EnforcedOptionParam({ eid: dstEid, msgType: SEND, options: sendOptions });
        enforcedOptions[1] =
            IOAppOptionsType3.EnforcedOptionParam({ eid: dstEid, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        return abi.encodeWithSelector(IOAppOptionsType3.setEnforcedOptions.selector, enforcedOptions);
    }

    function _getSendConfigCalldata(
        address oapp,
        address sendLib,
        bool isEthereum
    )
        internal
        pure
        returns (bytes memory)
    {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = isEthereum ? DVN1_ETH : DVN1_BASE;

        address[] memory optionalDVNs = new address[](0);

        UlnConfig memory ulnConfig = UlnConfig({
            confirmations: isEthereum ? 15 : 10,
            requiredDVNCount: 1,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: optionalDVNs
        });

        ExecutorConfig memory execConfig =
            ExecutorConfig({ maxMessageSize: 10_000, executor: isEthereum ? EXECUTOR_ETH : EXECUTOR_BASE });

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

        return abi.encodeWithSelector(ILayerZeroEndpointV2.setConfig.selector, oapp, sendLib, params);
    }

    function _getReceiveConfigCalldata(
        address oapp,
        address receiveLib,
        bool isEthereum
    )
        internal
        pure
        returns (bytes memory)
    {
        address[] memory requiredDVNs = new address[](1);
        requiredDVNs[0] = isEthereum ? DVN1_ETH : DVN1_BASE;

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

        return abi.encodeWithSelector(ILayerZeroEndpointV2.setConfig.selector, oapp, receiveLib, params);
    }
}
