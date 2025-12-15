// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import { EnforcedOptionParam } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { IOAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import { ILayerZeroEndpointV2 } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { SetConfigParam } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import { ExecutorConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";


import { UpOFT } from "../src/UP/UpOFT.sol";
import { UpOFTAdapter } from "../src/UP/UpOFTAdapter.sol";

contract DeployUpOFT is Script {
    using OptionsBuilder for bytes;

    address internal constant UP_TOKEN = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;

    uint64 internal constant MAINNET_CHAIN_ID = 1;
    uint64 internal constant BASE_CHAIN_ID = 8453;

    uint16 internal constant SEND = 1;
    uint16 internal constant SEND_AND_CALL = 2;

    uint128 internal constant GAS_LIMIT = 300_000;
    uint128 internal constant COMPOSE_GAS_LIMIT = 1_000_000;

    uint32 internal constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // https://docs.layerzero.network/v2/deployments/deployed-contracts
    address internal constant DVN1_BASE = 0x9e059a54699a285714207b43B055483E78FAac25; // DVN LZ Base
    address internal constant DVN2_BASE = 0xEb62f578497Bdc351dD650853a751135212fAF49; // DVN Superform Base

    address internal constant DVN1_ETH = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b; // DVN LZ Eth
    address internal constant DVN2_ETH = 0x7518f30bd5867b5fA86702556245Dead173afE46; // DVN Superform Eth

    address internal constant SEND_LIB_BASE = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address internal constant RECEIVE_LIB_BASE = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;

    address internal constant SEND_LIB_ETH = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address internal constant RECEIVE_LIB_ETH = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;

    address internal constant EXECUTOR_ETH = 0x173272739Bd7Aa6e4e214714048a9fE699453059;
    address internal constant EXECUTOR_BASE = 0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4;

    uint32 internal constant GRACE_PERIOD = 0;

    string internal constant MNEMONIC = "test test test test test test test test test test test junk";

    bytes internal SALT_NAMESPACE;

    UlnConfig ulnEthToBase;
    UlnConfig ulnBaseToEth;

    ExecutorConfig execEthToBase;
    ExecutorConfig execBaseToEth;

    struct OFTContracts {
        address adapter;
        address oft;
    }

    modifier broadcast(uint256 env) {
        if (env == 1) {
            (address deployer,) = deriveRememberKey(MNEMONIC, 0);
            console2.log("Deployer:", deployer);
            vm.startBroadcast(deployer);
            _;
            vm.stopBroadcast();
        } else {
            console2.log("Broadcast msg.sender:", msg.sender);
            vm.startBroadcast();
            _;
            vm.stopBroadcast();
        }
    }

    function _setConfiguration(uint256 env, string memory saltNamespace) internal {
        require(env == 0 || env == 1 || env == 2, "INVALID_ENV");

        if (env == 0) {
            SALT_NAMESPACE = bytes("PROD1.0.0");
        } else if (env == 2) {
            SALT_NAMESPACE = bytes("STAGING1.0.0");
        } else {
            require(bytes(saltNamespace).length > 0, "TEST_ENV_REQUIRES_SALT_NAMESPACE");
            SALT_NAMESPACE = bytes(saltNamespace);
        }

        address[] memory dvnsEth = new address[](2);
        dvnsEth[0] = DVN1_ETH;
        dvnsEth[1] = DVN2_ETH;
        ulnEthToBase = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsEth,
            optionalDVNs: new address[](0)
        });

        address[] memory dvnsBase = new address[](2);
        dvnsBase[0] = DVN1_BASE;
        dvnsBase[1] = DVN2_BASE;
        ulnBaseToEth = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 2,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsBase,
            optionalDVNs: new address[](0)
        });

        execEthToBase = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_BASE
        });

        execBaseToEth = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_ETH
        });
    }

    function run(uint256 env) public {
        _setConfiguration(env, "");
        _deployAndConfigure(env);
    }

    function run(uint256 env, string memory saltNamespace) public {
        _setConfiguration(env, saltNamespace);
        _deployAndConfigure(env);
    }

    function runCheck(uint256 env) public {
        runCheck(env, "");
    }

    function runCheck(uint256 env, string memory saltNamespace) public {
        _setConfiguration(env, saltNamespace);
        console2.log("====== UP OFT Address Verification ======");
        console2.log("Environment:", env);
        console2.log("");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("=== Computed Addresses ===");
        console2.log("UpOFTAdapter (Ethereum):", contracts.adapter);
        console2.log("UpOFT (Base):", contracts.oft);
        console2.log("");

        string memory ethRpc = vm.envString("ETHEREUM_RPC_URL");
        string memory baseRpc = vm.envString("BASE_RPC_URL");

        uint256 ethFork = vm.createFork(ethRpc);
        uint256 baseFork = vm.createFork(baseRpc);

        vm.selectFork(ethFork);
        console2.log("=== Ethereum (Chain ID: %s) ===", block.chainid);
        console2.log("UpOFTAdapter:");
        console2.log("  Address:", contracts.adapter);
        console2.log("  Code size:", contracts.adapter.code.length);
        console2.log("  Deployed:", contracts.adapter.code.length > 0 ? "YES" : "NO");

        vm.selectFork(baseFork);
        console2.log("");
        console2.log("=== Base (Chain ID: %s) ===", block.chainid);
        console2.log("UpOFT:");
        console2.log("  Address:", contracts.oft);
        console2.log("  Code size:", contracts.oft.code.length);
        console2.log("  Deployed:", contracts.oft.code.length > 0 ? "YES" : "NO");
        console2.log("");
    }

    function deployAdapter(uint256 env) public {
        _deployAdapterWithBroadcast(env, "");
    }

    function deployAdapter(uint256 env, string memory saltNamespace) public {
        _deployAdapterWithBroadcast(env, saltNamespace);
    }

    function _deployAdapterWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        address deployed = _deployAdapter();
        console2.log("UpOFTAdapter deployed:", deployed);
    }

    function deployOFT(uint256 env) public {
        _deployOFTWithBroadcast(env, "");
    }

    function deployOFT(uint256 env, string memory saltNamespace) public {
        _deployOFTWithBroadcast(env, saltNamespace);
    }

    function _deployOFTWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        address deployed = _deployOFT();
        console2.log("UpOFT deployed:", deployed);
    }

    function configurePeerOnEthereum(uint256 env) public {
        _configurePeerOnEthereumWithBroadcast(env, "");
    }

    function configurePeerOnEthereum(uint256 env, string memory saltNamespace) public {
        _configurePeerOnEthereumWithBroadcast(env, saltNamespace);
    }

    function _configurePeerOnEthereumWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();
        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.adapter, BASE_EID, contracts.oft);
        console2.log("Ethereum adapter peer set to Base OFT:", contracts.oft);
    }

    function configurePeerOnBase(uint256 env) public {
        _configurePeerOnBaseWithBroadcast(env, "");
    }

    function configurePeerOnBase(uint256 env, string memory saltNamespace) public {
        _configurePeerOnBaseWithBroadcast(env, saltNamespace);
    }

    function _configurePeerOnBaseWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();
        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oft, ETH_EID, contracts.adapter);
        console2.log("Base OFT peer set to Ethereum adapter:", contracts.adapter);
    }

    function setEnforcedOptionsOnEthereum(uint256 env) public {
        _setEnforcedOptionsOnEthereumWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnEthereum(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnEthereumWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnEthereumWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();
        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.adapter, BASE_EID);
        console2.log("Ethereum adapter enforced options set for Base destination");
    }

    function setEnforcedOptionsOnBase(uint256 env) public {
        _setEnforcedOptionsOnBaseWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnBase(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnBaseWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnBaseWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();
        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oft, ETH_EID);
        console2.log("Base OFT enforced options set for Ethereum destination");
    }

    function _deployAndConfigure(uint256 env) internal {
        address deployer;
        if (env == 1) {
            (deployer,) = deriveRememberKey(MNEMONIC, 0);
        } else {
            deployer = msg.sender;
        }

        OFTContracts memory contracts = _computeAddresses(deployer);

        console2.log("====== Deploying UP OFT System ======");
        console2.log("Environment:", env);
        console2.log("Deployer:", deployer);
        console2.log("");
        console2.log("Computed addresses:");
        console2.log("  UpOFTAdapter (Ethereum):", contracts.adapter);
        console2.log("  UpOFT (Base):", contracts.oft);
        console2.log("");

        string memory ethRpc = vm.envString("ETHEREUM_RPC_URL");
        string memory baseRpc = vm.envString("BASE_RPC_URL");

        uint256 ethFork = vm.createFork(ethRpc);
        uint256 baseFork = vm.createFork(baseRpc);

        vm.selectFork(ethFork);
        console2.log("=== Deploying on Ethereum (Chain ID: %s) ===", block.chainid);

        if (env == 1) {
            vm.startBroadcast(deployer);
        } else {
            vm.startBroadcast();
        }

        contracts.adapter = _deployAdapter();
        console2.log("UpOFTAdapter deployed:", contracts.adapter);

        vm.stopBroadcast();

        vm.selectFork(baseFork);
        console2.log("");
        console2.log("=== Deploying on Base (Chain ID: %s) ===", block.chainid);

        if (env == 1) {
            vm.startBroadcast(deployer);
        } else {
            vm.startBroadcast();
        }

        contracts.oft = _deployOFT();
        console2.log("UpOFT deployed:", contracts.oft);

        vm.stopBroadcast();

        console2.log("");
        console2.log("=== Configuring Peers ===");

        vm.selectFork(ethFork);
        if (env == 1) {
            vm.startBroadcast(deployer);
        } else {
            vm.startBroadcast();
        }

        _setPeer(contracts.adapter, BASE_EID, contracts.oft);
        console2.log("Ethereum adapter peer set to Base OFT");

        vm.stopBroadcast();

        vm.selectFork(baseFork);
        if (env == 1) {
            vm.startBroadcast(deployer);
        } else {
            vm.startBroadcast();
        }

        _setPeer(contracts.oft, ETH_EID, contracts.adapter);
        console2.log("Base OFT peer set to Ethereum adapter");

        vm.stopBroadcast();

        console2.log("");
        console2.log("=== Configuring Enforced Options ===");

        vm.selectFork(ethFork);
        if (env == 1) {
            vm.startBroadcast(deployer);
        } else {
            vm.startBroadcast();
        }

        _setEnforcedOptions(contracts.adapter, BASE_EID);
        console2.log("Ethereum adapter enforced options set for Base destination");

        vm.stopBroadcast();

        vm.selectFork(baseFork);
        if (env == 1) {
            vm.startBroadcast(deployer);
        } else {
            vm.startBroadcast();
        }

        _setEnforcedOptions(contracts.oft, ETH_EID);
        console2.log("Base OFT enforced options set for Ethereum destination");

        vm.stopBroadcast();

        console2.log("");
        console2.log("=== Configuring Libraries + ULN/Executor Configs ===");
        
        // Ethereum side (Adapter)
        vm.selectFork(ethFork);
        if (env == 1) {
            vm.startBroadcast(deployer);
        } else { 
            vm.startBroadcast(); 
        }
        _setLibraries({
            oapp: contracts.adapter,
            dstEid: BASE_EID,
            srcEid: BASE_EID,
            sendLib: SEND_LIB_ETH,
            receiveLib: RECEIVE_LIB_ETH,
            gracePeriod: GRACE_PERIOD
        });

        _setSendConfig({
            oapp: contracts.adapter,
            remoteEid: BASE_EID,
            sendLib: SEND_LIB_ETH,
            uln: ulnEthToBase,
            exec: execEthToBase 
        });

        _setReceiveConfig({
            oapp: contracts.adapter,
            remoteEid: BASE_EID,
            receiveLib: RECEIVE_LIB_ETH,
            uln: ulnBaseToEth
        });
        vm.stopBroadcast();

        // Base side (UpOFT)
        vm.selectFork(baseFork);
        if (env == 1) {
            vm.startBroadcast(deployer);
        } else { 
            vm.startBroadcast(); 
        }
        _setLibraries({
            oapp: contracts.oft,
            dstEid: ETH_EID,
            srcEid: ETH_EID,
            sendLib: SEND_LIB_BASE,
            receiveLib: RECEIVE_LIB_BASE,
            gracePeriod: GRACE_PERIOD
        });

        _setSendConfig({
            oapp: contracts.oft,
            remoteEid: ETH_EID,
            sendLib: SEND_LIB_BASE,
            uln: ulnBaseToEth,
            exec: execBaseToEth
        });

        _setReceiveConfig({
            oapp: contracts.oft,
            remoteEid: ETH_EID,
            receiveLib: RECEIVE_LIB_BASE,
            uln: ulnEthToBase
        });

        
        vm.stopBroadcast();


        console2.log("");
        console2.log("====== Deployment Complete ======");
        console2.log("UpOFTAdapter (Ethereum):", contracts.adapter);
        console2.log("UpOFT (Base):", contracts.oft);
    }

    function _computeAddresses() internal returns (OFTContracts memory contracts) {
        return _computeAddresses(msg.sender);
    }

    function _computeAddresses(address owner) internal view returns (OFTContracts memory contracts) {
        bytes memory adapterBytecode =
            abi.encodePacked(type(UpOFTAdapter).creationCode, abi.encode(UP_TOKEN, LZ_ENDPOINT, owner));
        contracts.adapter = DeterministicDeployerLib.computeAddress(adapterBytecode, _getSalt("UpOFTAdapter"));

        bytes memory oftBytecode = abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT, owner));
        contracts.oft = DeterministicDeployerLib.computeAddress(oftBytecode, _getSalt("UpOFT"));
    }

    function _deployAdapter() internal returns (address) {
        bytes32 salt = _getSalt("UpOFTAdapter");
        bytes memory bytecode =
            abi.encodePacked(type(UpOFTAdapter).creationCode, abi.encode(UP_TOKEN, LZ_ENDPOINT, msg.sender));

        address predicted = DeterministicDeployerLib.computeAddress(bytecode, salt);

        if (predicted.code.length > 0) {
            console2.log("[!] UpOFTAdapter already deployed, skipping...");
            return predicted;
        }

        address deployed = DeterministicDeployerLib.deploy(bytecode, salt);
        require(deployed == predicted, "Address mismatch");
        require(deployed.code.length > 0, "Deployment failed");

        return deployed;
    }

    function _deployOFT() internal returns (address) {
        bytes32 salt = _getSalt("UpOFT");
        bytes memory bytecode = abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT, msg.sender));

        address predicted = DeterministicDeployerLib.computeAddress(bytecode, salt);

        if (predicted.code.length > 0) {
            console2.log("[!] UpOFT already deployed, skipping...");
            return predicted;
        }

        address deployed = DeterministicDeployerLib.deploy(bytecode, salt);
        require(deployed == predicted, "Address mismatch");
        require(deployed.code.length > 0, "Deployment failed");

        return deployed;
    }

    function _setPeer(address oapp, uint32 peerEid, address peerAddress) internal {
        bytes32 peerBytes32 = bytes32(uint256(uint160(peerAddress)));

        if (oapp.code.length > 0) {
            bytes32 currentPeer = IOAppCore(oapp).peers(peerEid);
            if (currentPeer == peerBytes32) {
                console2.log("[!] Peer already set, skipping...");
                return;
            }
        }

        IOAppCore(oapp).setPeer(peerEid, peerBytes32);
    }

    function _setEnforcedOptions(address oapp, uint32 dstEid) internal {
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);

        bytes memory sendAndCallOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, COMPOSE_GAS_LIMIT, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({ eid: dstEid, msgType: SEND, options: sendOptions });
        enforcedOptions[1] = EnforcedOptionParam({ eid: dstEid, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        IOAppOptionsType3(oapp).setEnforcedOptions(enforcedOptions);
    }

    function _setLibraries(
        address oapp,
        uint32 dstEid,
        uint32 srcEid,
        address sendLib,
        address receiveLib,
        uint32 gracePeriod
    ) internal {
        // outbound messages to dstEid use sendLib
        ILayerZeroEndpointV2(LZ_ENDPOINT).setSendLibrary(oapp, dstEid, sendLib);

        // inbound messages from srcEid use receiveLib
        ILayerZeroEndpointV2(LZ_ENDPOINT).setReceiveLibrary(oapp, srcEid, receiveLib, gracePeriod);
    }

    function _setSendConfig(
        address oapp,
        uint32 remoteEid,
        address sendLib,
        UlnConfig memory uln,
        ExecutorConfig memory exec
    ) internal {
        SetConfigParam[] memory params = new SetConfigParam[](2);
        params[0] = SetConfigParam(remoteEid, EXECUTOR_CONFIG_TYPE, abi.encode(exec));
        params[1] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));

        ILayerZeroEndpointV2(LZ_ENDPOINT).setConfig(oapp, sendLib, params);
    }

    function _setReceiveConfig(
        address oapp,
        uint32 remoteEid,
        address receiveLib,
        UlnConfig memory uln
    ) internal {
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));

        ILayerZeroEndpointV2(LZ_ENDPOINT).setConfig(oapp, receiveLib, params);
    }

    function _getSalt(string memory name) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("SuperformV2", SALT_NAMESPACE, name, "v2.0"));
    }
}
