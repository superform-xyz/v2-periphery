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
    uint32 internal constant HYPEREVM_EID = 30367;
    uint32 internal constant FLARE_EID = 30295;

    uint64 internal constant MAINNET_CHAIN_ID = 1;
    uint64 internal constant BASE_CHAIN_ID = 8453;
    uint64 internal constant HYPEREVM_CHAIN_ID = 999;
    uint64 internal constant FLARE_CHAIN_ID = 14;

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

    // HyperEVM LayerZero V2 contracts
    address internal constant LZ_ENDPOINT_HYPEREVM = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
    address internal constant DVN_LZ_HYPEREVM = 0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f; // DVN LZ HyperEVM
    address internal constant SEND_LIB_HYPEREVM = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
    address internal constant RECEIVE_LIB_HYPEREVM = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;
    address internal constant EXECUTOR_HYPEREVM = 0x41Bdb4aa4A63a5b2Efc531858d3118392B1A1C3d;

    // Flare LayerZero V2 contracts (uses standard LZ_ENDPOINT)
    address internal constant DVN_LZ_FLARE = 0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD; // DVN LZ Flare
    address internal constant SEND_LIB_FLARE = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address internal constant RECEIVE_LIB_FLARE = 0x2367325334447C5E1E0f1b3a6fB947b262F58312;
    address internal constant EXECUTOR_FLARE = 0xcCE466a522984415bC91338c232d98869193D46e;

    uint32 internal constant GRACE_PERIOD = 0;

    string internal constant MNEMONIC = "test test test test test test test test test test test junk";

    bytes internal SALT_NAMESPACE;

    UlnConfig ulnEthToBase;
    UlnConfig ulnBaseToEth;
    UlnConfig ulnEthToHyperEVM;
    UlnConfig ulnHyperEVMToEth;
    UlnConfig ulnBaseToHyperEVM;
    UlnConfig ulnHyperEVMToBase;
    // Receive configs (different confirmations than send for HyperEVM pathways)
    UlnConfig ulnHyperEVMReceiveFromEth;
    UlnConfig ulnHyperEVMReceiveFromBase;
    UlnConfig ulnEthReceiveFromHyperEVM;
    UlnConfig ulnBaseReceiveFromHyperEVM;

    // Flare pathway configs (single DVN - LayerZero Labs only)
    UlnConfig ulnFlareToEth;
    UlnConfig ulnFlareToBase;
    UlnConfig ulnFlareToHyperEVM;
    // Flare receive configs
    UlnConfig ulnFlareReceiveFromEth;
    UlnConfig ulnFlareReceiveFromBase;
    UlnConfig ulnFlareReceiveFromHyperEVM;
    // Other chains' configs for Flare pathways
    UlnConfig ulnEthToFlare;
    UlnConfig ulnEthReceiveFromFlare;
    UlnConfig ulnBaseToFlare;
    UlnConfig ulnBaseReceiveFromFlare;
    UlnConfig ulnHyperEVMToFlare;
    UlnConfig ulnHyperEVMReceiveFromFlare;

    ExecutorConfig execEthToBase;
    ExecutorConfig execBaseToEth;
    ExecutorConfig execEthToHyperEVM;
    ExecutorConfig execHyperEVMToEth;
    ExecutorConfig execBaseToHyperEVM;
    ExecutorConfig execHyperEVMToBase;
    ExecutorConfig execFlareToEth;
    ExecutorConfig execFlareToBase;
    ExecutorConfig execFlareToHyperEVM;
    ExecutorConfig execEthToFlare;
    ExecutorConfig execBaseToFlare;
    ExecutorConfig execHyperEVMToFlare;

    struct OFTContracts {
        address adapter;
        address oft;
        address oftHyperEVM;
        address oftFlare;
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
            SALT_NAMESPACE = bytes("TEST1.0.0");
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
            executor: EXECUTOR_ETH
        });

        execBaseToEth = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_BASE
        });

        // HyperEVM pathway configs (single DVN - LayerZero Labs only)
        // NOTE: LZ requires send config confirmations to match receive config confirmations on the other side.
        //   HL→ETH: HL send=1, ETH receive=1 (1 HL block)
        //   ETH→HL: ETH send=15, HL receive=15 (15 ETH blocks)
        //   HL→Base: HL send=1, Base receive=1 (1 HL block)
        //   Base→HL: Base send=10, HL receive=10 (10 Base blocks)

        address[] memory dvnsHyperEVM = new address[](1);
        dvnsHyperEVM[0] = DVN_LZ_HYPEREVM;

        // HL→ETH send config (1 HL block, matches ETH receive)
        ulnHyperEVMToEth = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyperEVM,
            optionalDVNs: new address[](0)
        });

        // HL receive from ETH config (15 ETH blocks, matches ETH send)
        ulnHyperEVMReceiveFromEth = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyperEVM,
            optionalDVNs: new address[](0)
        });

        // ETH→HL send config (15 ETH blocks)
        address[] memory dvnsEthForHyperEVM = new address[](1);
        dvnsEthForHyperEVM[0] = DVN1_ETH; // Only LZ Labs DVN for HyperEVM pathway
        ulnEthToHyperEVM = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsEthForHyperEVM,
            optionalDVNs: new address[](0)
        });

        // ETH receive from HL config (1 HL block, matches HL send)
        ulnEthReceiveFromHyperEVM = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsEthForHyperEVM,
            optionalDVNs: new address[](0)
        });

        execEthToHyperEVM = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_ETH
        });

        execHyperEVMToEth = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_HYPEREVM
        });

        // Base→HL send config (10 Base blocks)
        address[] memory dvnsBaseForHyperEVM = new address[](1);
        dvnsBaseForHyperEVM[0] = DVN1_BASE; // Only LZ Labs DVN for HyperEVM pathway
        ulnBaseToHyperEVM = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsBaseForHyperEVM,
            optionalDVNs: new address[](0)
        });

        // Base receive from HL config (1 HL block, matches HL send)
        ulnBaseReceiveFromHyperEVM = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsBaseForHyperEVM,
            optionalDVNs: new address[](0)
        });

        // HL→Base send config (1 HL block, matches Base receive)
        ulnHyperEVMToBase = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyperEVM,
            optionalDVNs: new address[](0)
        });

        // HL receive from Base config (10 Base blocks, matches Base send)
        ulnHyperEVMReceiveFromBase = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyperEVM,
            optionalDVNs: new address[](0)
        });

        execBaseToHyperEVM = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_BASE
        });

        execHyperEVMToBase = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_HYPEREVM
        });

        // Flare pathway configs (single DVN - LayerZero Labs only)
        // NOTE: LZ requires send config confirmations to match receive config confirmations on the other side.
        //   Flare→ETH: Flare send=1, ETH receive=1 (1 Flare block)
        //   ETH→Flare: ETH send=15, Flare receive=15 (15 ETH blocks)
        //   Flare→Base: Flare send=1, Base receive=1 (1 Flare block)
        //   Base→Flare: Base send=10, Flare receive=10 (10 Base blocks)
        //   Flare→HL: Flare send=1, HL receive=1 (1 Flare block)
        //   HL→Flare: HL send=1, Flare receive=1 (1 HL block)

        address[] memory dvnsFlare = new address[](1);
        dvnsFlare[0] = DVN_LZ_FLARE;

        // Flare→ETH send config (1 Flare block, matches ETH receive)
        ulnFlareToEth = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });

        // Flare→Base send config (1 Flare block, matches Base receive)
        ulnFlareToBase = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });

        // Flare→HyperEVM send config (1 Flare block, matches HyperEVM receive)
        ulnFlareToHyperEVM = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });

        // Flare receive from ETH config (15 ETH blocks, matches ETH send)
        ulnFlareReceiveFromEth = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });

        // Flare receive from Base config (10 Base blocks, matches Base send)
        ulnFlareReceiveFromBase = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });

        // Flare receive from HyperEVM config (1 HL block, matches HL send)
        ulnFlareReceiveFromHyperEVM = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });

        // ETH→Flare send config (15 ETH blocks)
        address[] memory dvnsEthForFlare = new address[](1);
        dvnsEthForFlare[0] = DVN1_ETH; // Only LZ Labs DVN for Flare pathway
        ulnEthToFlare = UlnConfig({
            confirmations: 15,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsEthForFlare,
            optionalDVNs: new address[](0)
        });

        // ETH receive from Flare config (1 Flare block, matches Flare send)
        ulnEthReceiveFromFlare = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsEthForFlare,
            optionalDVNs: new address[](0)
        });

        // Base→Flare send config (10 Base blocks)
        address[] memory dvnsBaseForFlare = new address[](1);
        dvnsBaseForFlare[0] = DVN1_BASE; // Only LZ Labs DVN for Flare pathway
        ulnBaseToFlare = UlnConfig({
            confirmations: 10,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsBaseForFlare,
            optionalDVNs: new address[](0)
        });

        // Base receive from Flare config (1 Flare block, matches Flare send)
        ulnBaseReceiveFromFlare = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsBaseForFlare,
            optionalDVNs: new address[](0)
        });

        // HyperEVM→Flare send config (1 HL block)
        // Reuses dvnsHyperEVM from above
        ulnHyperEVMToFlare = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyperEVM,
            optionalDVNs: new address[](0)
        });

        // HyperEVM receive from Flare config (1 Flare block, matches Flare send)
        ulnHyperEVMReceiveFromFlare = UlnConfig({
            confirmations: 1,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyperEVM,
            optionalDVNs: new address[](0)
        });

        execFlareToEth = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_FLARE
        });

        execFlareToBase = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_FLARE
        });

        execFlareToHyperEVM = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_FLARE
        });

        execEthToFlare = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_ETH
        });

        execBaseToFlare = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_BASE
        });

        execHyperEVMToFlare = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_HYPEREVM
        });
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

        address owner;
        if (env == 1) {
            (owner,) = deriveRememberKey(MNEMONIC, 0);
        } else {
            owner = msg.sender;
        }

        console2.log("");
        console2.log("====== Deploying UpOFTAdapter on Ethereum ======");
        console2.log("Chain ID:", block.chainid);
        console2.log("Owner:", owner);

        address deployed = _deployAdapter(owner);

        console2.log("");
        console2.log("UpOFTAdapter deployed:", deployed);
        console2.log("================================================");
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

        address owner;
        if (env == 1) {
            (owner,) = deriveRememberKey(MNEMONIC, 0);
        } else {
            owner = msg.sender;
        }

        console2.log("");
        console2.log("====== Deploying UpOFT on Base ======");
        console2.log("Chain ID:", block.chainid);
        console2.log("Owner:", owner);

        address deployed = _deployOFT(owner);

        console2.log("");
        console2.log("UpOFT deployed:", deployed);
        console2.log("=====================================");
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

        console2.log("");
        console2.log("====== Configuring Peer on Ethereum ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("Peer (Base UpOFT):", contracts.oft);

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.adapter, BASE_EID, contracts.oft);
        console2.log("[+] Peer configured successfully");
        console2.log("==========================================");
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

        console2.log("");
        console2.log("====== Configuring Peer on Base ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("Peer (Ethereum UpOFTAdapter):", contracts.adapter);

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oft, ETH_EID, contracts.adapter);
        console2.log("[+] Peer configured successfully");
        console2.log("======================================");
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

        console2.log("");
        console2.log("====== Setting Enforced Options on Ethereum ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("Destination: Base (EID:", BASE_EID, ")");

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.adapter, BASE_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("==================================================");
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

        console2.log("");
        console2.log("====== Setting Enforced Options on Base ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("Destination: Ethereum (EID:", ETH_EID, ")");

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oft, ETH_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("==============================================");
    }

    function configureLibrariesOnEthereum(uint256 env) public {
        _configureLibrariesOnEthereumWithBroadcast(env, "");
    }

    function configureLibrariesOnEthereum(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnEthereumWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnEthereumWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Ethereum ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("SendLib:", SEND_LIB_ETH);
        console2.log("ReceiveLib:", RECEIVE_LIB_ETH);
        console2.log("DVN1 (LZ Labs):", DVN1_ETH);
        console2.log("DVN2 (Superform):", DVN2_ETH);
        console2.log("Executor:", EXECUTOR_BASE);

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.adapter,
            dstEid: BASE_EID,
            srcEid: BASE_EID,
            sendLib: SEND_LIB_ETH,
            receiveLib: RECEIVE_LIB_ETH,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.adapter,
            remoteEid: BASE_EID,
            sendLib: SEND_LIB_ETH,
            uln: ulnEthToBase,
            exec: execEthToBase
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.adapter,
            remoteEid: BASE_EID,
            receiveLib: RECEIVE_LIB_ETH,
            uln: ulnEthToBase
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("================================================");
    }

    function configureLibrariesOnBase(uint256 env) public {
        _configureLibrariesOnBaseWithBroadcast(env, "");
    }

    function configureLibrariesOnBase(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnBaseWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnBaseWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Base ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("SendLib:", SEND_LIB_BASE);
        console2.log("ReceiveLib:", RECEIVE_LIB_BASE);
        console2.log("DVN1 (LZ Labs):", DVN1_BASE);
        console2.log("DVN2 (Superform):", DVN2_BASE);
        console2.log("Executor:", EXECUTOR_ETH);

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.oft,
            dstEid: ETH_EID,
            srcEid: ETH_EID,
            sendLib: SEND_LIB_BASE,
            receiveLib: RECEIVE_LIB_BASE,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.oft,
            remoteEid: ETH_EID,
            sendLib: SEND_LIB_BASE,
            uln: ulnBaseToEth,
            exec: execBaseToEth
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.oft,
            remoteEid: ETH_EID,
            receiveLib: RECEIVE_LIB_BASE,
            uln: ulnBaseToEth
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("============================================");
    }

    // ============ HyperEVM Functions ============

    function deployOFTOnHyperEVM(uint256 env) public {
        _deployOFTOnHyperEVMWithBroadcast(env, "");
    }

    function deployOFTOnHyperEVM(uint256 env, string memory saltNamespace) public {
        _deployOFTOnHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _deployOFTOnHyperEVMWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        address owner;
        if (env == 1) {
            (owner,) = deriveRememberKey(MNEMONIC, 0);
        } else {
            owner = msg.sender;
        }

        console2.log("");
        console2.log("====== Deploying UpOFT on HyperEVM ======");
        console2.log("Chain ID:", block.chainid);
        console2.log("Owner:", owner);

        address deployed = _deployOFTHyperEVM(owner);

        console2.log("");
        console2.log("UpOFT deployed:", deployed);
        console2.log("=========================================");
    }

    function configurePeerOnHyperEVM(uint256 env) public {
        _configurePeerOnHyperEVMWithBroadcast(env, "");
    }

    function configurePeerOnHyperEVM(uint256 env, string memory saltNamespace) public {
        _configurePeerOnHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _configurePeerOnHyperEVMWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Peer on HyperEVM ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("Peer (Ethereum UpOFTAdapter):", contracts.adapter);

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oftHyperEVM, ETH_EID, contracts.adapter);
        console2.log("[+] Peer configured successfully");
        console2.log("==========================================");
    }

    function configurePeerOnEthereumForHyperEVM(uint256 env) public {
        _configurePeerOnEthereumForHyperEVMWithBroadcast(env, "", address(0));
    }

    function configurePeerOnEthereumForHyperEVM(uint256 env, string memory saltNamespace) public {
        _configurePeerOnEthereumForHyperEVMWithBroadcast(env, saltNamespace, address(0));
    }

    /// @param hyperEvmOft Explicit HyperEVM UpOFT address (use when caller is not the HyperEVM deployer)
    function configurePeerOnEthereumForHyperEVM(uint256 env, address hyperEvmOft) public {
        _configurePeerOnEthereumForHyperEVMWithBroadcast(env, "", hyperEvmOft);
    }

    function _configurePeerOnEthereumForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace,
        address hyperEvmOftOverride
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();
        address hyperEvmOft = hyperEvmOftOverride != address(0) ? hyperEvmOftOverride : contracts.oftHyperEVM;

        console2.log("");
        console2.log("====== Configuring Peer on Ethereum for HyperEVM ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("Peer (HyperEVM UpOFT):", hyperEvmOft);

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.adapter, HYPEREVM_EID, hyperEvmOft);
        console2.log("[+] Peer configured successfully");
        console2.log("========================================================");
    }

    function setEnforcedOptionsOnHyperEVM(uint256 env) public {
        _setEnforcedOptionsOnHyperEVMWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnHyperEVM(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on HyperEVM ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("Destination: Ethereum (EID:", ETH_EID, ")");

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oftHyperEVM, ETH_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("==================================================");
    }

    function setEnforcedOptionsOnEthereumForHyperEVM(uint256 env) public {
        _setEnforcedOptionsOnEthereumForHyperEVMWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnEthereumForHyperEVM(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnEthereumForHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnEthereumForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on Ethereum for HyperEVM ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("Destination: HyperEVM (EID:", HYPEREVM_EID, ")");

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.adapter, HYPEREVM_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("================================================================");
    }

    function configureLibrariesOnHyperEVM(uint256 env) public {
        _configureLibrariesOnHyperEVMWithBroadcast(env, "");
    }

    function configureLibrariesOnHyperEVM(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on HyperEVM ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("SendLib:", SEND_LIB_HYPEREVM);
        console2.log("ReceiveLib:", RECEIVE_LIB_HYPEREVM);
        console2.log("DVN (LZ Labs):", DVN_LZ_HYPEREVM);
        console2.log("Executor:", EXECUTOR_HYPEREVM);

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibrariesHyperEVM({
            oapp: contracts.oftHyperEVM,
            dstEid: ETH_EID,
            srcEid: ETH_EID,
            sendLib: SEND_LIB_HYPEREVM,
            receiveLib: RECEIVE_LIB_HYPEREVM,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfigHyperEVM({
            oapp: contracts.oftHyperEVM,
            remoteEid: ETH_EID,
            sendLib: SEND_LIB_HYPEREVM,
            uln: ulnHyperEVMToEth,
            exec: execHyperEVMToEth
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfigHyperEVM({
            oapp: contracts.oftHyperEVM,
            remoteEid: ETH_EID,
            receiveLib: RECEIVE_LIB_HYPEREVM,
            uln: ulnHyperEVMReceiveFromEth
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("================================================");
    }

    function configureLibrariesOnEthereumForHyperEVM(uint256 env) public {
        _configureLibrariesOnEthereumForHyperEVMWithBroadcast(env, "");
    }

    function configureLibrariesOnEthereumForHyperEVM(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnEthereumForHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnEthereumForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Ethereum for HyperEVM ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("SendLib:", SEND_LIB_ETH);
        console2.log("ReceiveLib:", RECEIVE_LIB_ETH);
        console2.log("DVN (LZ Labs):", DVN1_ETH);
        console2.log("Executor:", EXECUTOR_ETH);

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.adapter,
            dstEid: HYPEREVM_EID,
            srcEid: HYPEREVM_EID,
            sendLib: SEND_LIB_ETH,
            receiveLib: RECEIVE_LIB_ETH,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.adapter,
            remoteEid: HYPEREVM_EID,
            sendLib: SEND_LIB_ETH,
            uln: ulnEthToHyperEVM,
            exec: execEthToHyperEVM
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.adapter,
            remoteEid: HYPEREVM_EID,
            receiveLib: RECEIVE_LIB_ETH,
            uln: ulnEthReceiveFromHyperEVM
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("============================================================");
    }

    // ============ HyperEVM <-> Base Functions ============

    function configurePeerOnHyperEVMForBase(uint256 env) public {
        _configurePeerOnHyperEVMForBaseWithBroadcast(env, "");
    }

    function configurePeerOnHyperEVMForBase(uint256 env, string memory saltNamespace) public {
        _configurePeerOnHyperEVMForBaseWithBroadcast(env, saltNamespace);
    }

    function _configurePeerOnHyperEVMForBaseWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Peer on HyperEVM for Base ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("Peer (Base UpOFT):", contracts.oft);

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oftHyperEVM, BASE_EID, contracts.oft);
        console2.log("[+] Peer configured successfully");
        console2.log("==================================================");
    }

    function configurePeerOnBaseForHyperEVM(uint256 env) public {
        _configurePeerOnBaseForHyperEVMWithBroadcast(env, "", address(0));
    }

    function configurePeerOnBaseForHyperEVM(uint256 env, string memory saltNamespace) public {
        _configurePeerOnBaseForHyperEVMWithBroadcast(env, saltNamespace, address(0));
    }

    /// @param hyperEvmOft Explicit HyperEVM UpOFT address (use when caller is not the HyperEVM deployer)
    function configurePeerOnBaseForHyperEVM(uint256 env, address hyperEvmOft) public {
        _configurePeerOnBaseForHyperEVMWithBroadcast(env, "", hyperEvmOft);
    }

    function _configurePeerOnBaseForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace,
        address hyperEvmOftOverride
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();
        address hyperEvmOft = hyperEvmOftOverride != address(0) ? hyperEvmOftOverride : contracts.oftHyperEVM;

        console2.log("");
        console2.log("====== Configuring Peer on Base for HyperEVM ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("Peer (HyperEVM UpOFT):", hyperEvmOft);

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oft, HYPEREVM_EID, hyperEvmOft);
        console2.log("[+] Peer configured successfully");
        console2.log("==================================================");
    }

    function setEnforcedOptionsOnHyperEVMForBase(uint256 env) public {
        _setEnforcedOptionsOnHyperEVMForBaseWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnHyperEVMForBase(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnHyperEVMForBaseWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnHyperEVMForBaseWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on HyperEVM for Base ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("Destination: Base (EID:", BASE_EID, ")");

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oftHyperEVM, BASE_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("==========================================================");
    }

    function setEnforcedOptionsOnBaseForHyperEVM(uint256 env) public {
        _setEnforcedOptionsOnBaseForHyperEVMWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnBaseForHyperEVM(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnBaseForHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnBaseForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on Base for HyperEVM ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("Destination: HyperEVM (EID:", HYPEREVM_EID, ")");

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oft, HYPEREVM_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("==========================================================");
    }

    function configureLibrariesOnHyperEVMForBase(uint256 env) public {
        _configureLibrariesOnHyperEVMForBaseWithBroadcast(env, "");
    }

    function configureLibrariesOnHyperEVMForBase(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnHyperEVMForBaseWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnHyperEVMForBaseWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on HyperEVM for Base ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("SendLib:", SEND_LIB_HYPEREVM);
        console2.log("ReceiveLib:", RECEIVE_LIB_HYPEREVM);
        console2.log("DVN (LZ Labs):", DVN_LZ_HYPEREVM);
        console2.log("Executor:", EXECUTOR_HYPEREVM);

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibrariesHyperEVM({
            oapp: contracts.oftHyperEVM,
            dstEid: BASE_EID,
            srcEid: BASE_EID,
            sendLib: SEND_LIB_HYPEREVM,
            receiveLib: RECEIVE_LIB_HYPEREVM,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfigHyperEVM({
            oapp: contracts.oftHyperEVM,
            remoteEid: BASE_EID,
            sendLib: SEND_LIB_HYPEREVM,
            uln: ulnHyperEVMToBase,
            exec: execHyperEVMToBase
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfigHyperEVM({
            oapp: contracts.oftHyperEVM,
            remoteEid: BASE_EID,
            receiveLib: RECEIVE_LIB_HYPEREVM,
            uln: ulnHyperEVMReceiveFromBase
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("========================================================");
    }

    function configureLibrariesOnBaseForHyperEVM(uint256 env) public {
        _configureLibrariesOnBaseForHyperEVMWithBroadcast(env, "");
    }

    function configureLibrariesOnBaseForHyperEVM(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnBaseForHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnBaseForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Base for HyperEVM ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("SendLib:", SEND_LIB_BASE);
        console2.log("ReceiveLib:", RECEIVE_LIB_BASE);
        console2.log("DVN (LZ Labs):", DVN1_BASE);
        console2.log("Executor:", EXECUTOR_BASE);

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.oft,
            dstEid: HYPEREVM_EID,
            srcEid: HYPEREVM_EID,
            sendLib: SEND_LIB_BASE,
            receiveLib: RECEIVE_LIB_BASE,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.oft,
            remoteEid: HYPEREVM_EID,
            sendLib: SEND_LIB_BASE,
            uln: ulnBaseToHyperEVM,
            exec: execBaseToHyperEVM
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.oft,
            remoteEid: HYPEREVM_EID,
            receiveLib: RECEIVE_LIB_BASE,
            uln: ulnBaseReceiveFromHyperEVM
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("========================================================");
    }

    // ============ Flare Functions ============

    function deployOFTOnFlare(uint256 env) public {
        _deployOFTOnFlareWithBroadcast(env, "");
    }

    function deployOFTOnFlare(uint256 env, string memory saltNamespace) public {
        _deployOFTOnFlareWithBroadcast(env, saltNamespace);
    }

    function _deployOFTOnFlareWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        address owner;
        if (env == 1) {
            (owner,) = deriveRememberKey(MNEMONIC, 0);
        } else {
            owner = msg.sender;
        }

        console2.log("");
        console2.log("====== Deploying UpOFT on Flare ======");
        console2.log("Chain ID:", block.chainid);
        console2.log("Owner:", owner);

        address deployed = _deployOFTFlare(owner);

        console2.log("");
        console2.log("UpOFT deployed:", deployed);
        console2.log("======================================");
    }

    // ============ Flare <-> Ethereum Functions ============

    function configurePeerOnFlare(uint256 env) public {
        _configurePeerOnFlareWithBroadcast(env, "");
    }

    function configurePeerOnFlare(uint256 env, string memory saltNamespace) public {
        _configurePeerOnFlareWithBroadcast(env, saltNamespace);
    }

    function _configurePeerOnFlareWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Peer on Flare ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("Peer (Ethereum UpOFTAdapter):", contracts.adapter);

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oftFlare, ETH_EID, contracts.adapter);
        console2.log("[+] Peer configured successfully");
        console2.log("=======================================");
    }

    function configurePeerOnEthereumForFlare(uint256 env) public {
        _configurePeerOnEthereumForFlareWithBroadcast(env, "", address(0));
    }

    function configurePeerOnEthereumForFlare(uint256 env, string memory saltNamespace) public {
        _configurePeerOnEthereumForFlareWithBroadcast(env, saltNamespace, address(0));
    }

    /// @param flareOft Explicit Flare UpOFT address (use when caller is not the Flare deployer)
    function configurePeerOnEthereumForFlare(uint256 env, address flareOft) public {
        _configurePeerOnEthereumForFlareWithBroadcast(env, "", flareOft);
    }

    function _configurePeerOnEthereumForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace,
        address flareOftOverride
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();
        address flareOft = flareOftOverride != address(0) ? flareOftOverride : contracts.oftFlare;

        console2.log("");
        console2.log("====== Configuring Peer on Ethereum for Flare ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("Peer (Flare UpOFT):", flareOft);

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.adapter, FLARE_EID, flareOft);
        console2.log("[+] Peer configured successfully");
        console2.log("====================================================");
    }

    function setEnforcedOptionsOnFlare(uint256 env) public {
        _setEnforcedOptionsOnFlareWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnFlare(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnFlareWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on Flare ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("Destination: Ethereum (EID:", ETH_EID, ")");

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oftFlare, ETH_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("================================================");
    }

    function setEnforcedOptionsOnEthereumForFlare(uint256 env) public {
        _setEnforcedOptionsOnEthereumForFlareWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnEthereumForFlare(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnEthereumForFlareWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnEthereumForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on Ethereum for Flare ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("Destination: Flare (EID:", FLARE_EID, ")");

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.adapter, FLARE_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("=============================================================");
    }

    function configureLibrariesOnFlare(uint256 env) public {
        _configureLibrariesOnFlareWithBroadcast(env, "");
    }

    function configureLibrariesOnFlare(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnFlareWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Flare ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("SendLib:", SEND_LIB_FLARE);
        console2.log("ReceiveLib:", RECEIVE_LIB_FLARE);
        console2.log("DVN (LZ Labs):", DVN_LZ_FLARE);
        console2.log("Executor:", EXECUTOR_FLARE);

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.oftFlare,
            dstEid: ETH_EID,
            srcEid: ETH_EID,
            sendLib: SEND_LIB_FLARE,
            receiveLib: RECEIVE_LIB_FLARE,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.oftFlare,
            remoteEid: ETH_EID,
            sendLib: SEND_LIB_FLARE,
            uln: ulnFlareToEth,
            exec: execFlareToEth
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.oftFlare,
            remoteEid: ETH_EID,
            receiveLib: RECEIVE_LIB_FLARE,
            uln: ulnFlareReceiveFromEth
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("=============================================");
    }

    function configureLibrariesOnEthereumForFlare(uint256 env) public {
        _configureLibrariesOnEthereumForFlareWithBroadcast(env, "");
    }

    function configureLibrariesOnEthereumForFlare(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnEthereumForFlareWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnEthereumForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Ethereum for Flare ======");
        console2.log("UpOFTAdapter:", contracts.adapter);
        console2.log("SendLib:", SEND_LIB_ETH);
        console2.log("ReceiveLib:", RECEIVE_LIB_ETH);
        console2.log("DVN (LZ Labs):", DVN1_ETH);
        console2.log("Executor:", EXECUTOR_ETH);

        if (contracts.adapter.code.length == 0) {
            console2.log("[!] UpOFTAdapter not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.adapter,
            dstEid: FLARE_EID,
            srcEid: FLARE_EID,
            sendLib: SEND_LIB_ETH,
            receiveLib: RECEIVE_LIB_ETH,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.adapter,
            remoteEid: FLARE_EID,
            sendLib: SEND_LIB_ETH,
            uln: ulnEthToFlare,
            exec: execEthToFlare
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.adapter,
            remoteEid: FLARE_EID,
            receiveLib: RECEIVE_LIB_ETH,
            uln: ulnEthReceiveFromFlare
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("=========================================================");
    }

    // ============ Flare <-> Base Functions ============

    function configurePeerOnFlareForBase(uint256 env) public {
        _configurePeerOnFlareForBaseWithBroadcast(env, "");
    }

    function configurePeerOnFlareForBase(uint256 env, string memory saltNamespace) public {
        _configurePeerOnFlareForBaseWithBroadcast(env, saltNamespace);
    }

    function _configurePeerOnFlareForBaseWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Peer on Flare for Base ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("Peer (Base UpOFT):", contracts.oft);

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oftFlare, BASE_EID, contracts.oft);
        console2.log("[+] Peer configured successfully");
        console2.log("================================================");
    }

    function configurePeerOnBaseForFlare(uint256 env) public {
        _configurePeerOnBaseForFlareWithBroadcast(env, "", address(0));
    }

    function configurePeerOnBaseForFlare(uint256 env, string memory saltNamespace) public {
        _configurePeerOnBaseForFlareWithBroadcast(env, saltNamespace, address(0));
    }

    /// @param flareOft Explicit Flare UpOFT address (use when caller is not the Flare deployer)
    function configurePeerOnBaseForFlare(uint256 env, address flareOft) public {
        _configurePeerOnBaseForFlareWithBroadcast(env, "", flareOft);
    }

    function _configurePeerOnBaseForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace,
        address flareOftOverride
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();
        address flareOft = flareOftOverride != address(0) ? flareOftOverride : contracts.oftFlare;

        console2.log("");
        console2.log("====== Configuring Peer on Base for Flare ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("Peer (Flare UpOFT):", flareOft);

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oft, FLARE_EID, flareOft);
        console2.log("[+] Peer configured successfully");
        console2.log("================================================");
    }

    function setEnforcedOptionsOnFlareForBase(uint256 env) public {
        _setEnforcedOptionsOnFlareForBaseWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnFlareForBase(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnFlareForBaseWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnFlareForBaseWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on Flare for Base ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("Destination: Base (EID:", BASE_EID, ")");

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oftFlare, BASE_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("========================================================");
    }

    function setEnforcedOptionsOnBaseForFlare(uint256 env) public {
        _setEnforcedOptionsOnBaseForFlareWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnBaseForFlare(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnBaseForFlareWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnBaseForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on Base for Flare ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("Destination: Flare (EID:", FLARE_EID, ")");

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oft, FLARE_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("========================================================");
    }

    function configureLibrariesOnFlareForBase(uint256 env) public {
        _configureLibrariesOnFlareForBaseWithBroadcast(env, "");
    }

    function configureLibrariesOnFlareForBase(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnFlareForBaseWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnFlareForBaseWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Flare for Base ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("SendLib:", SEND_LIB_FLARE);
        console2.log("ReceiveLib:", RECEIVE_LIB_FLARE);
        console2.log("DVN (LZ Labs):", DVN_LZ_FLARE);
        console2.log("Executor:", EXECUTOR_FLARE);

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.oftFlare,
            dstEid: BASE_EID,
            srcEid: BASE_EID,
            sendLib: SEND_LIB_FLARE,
            receiveLib: RECEIVE_LIB_FLARE,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.oftFlare,
            remoteEid: BASE_EID,
            sendLib: SEND_LIB_FLARE,
            uln: ulnFlareToBase,
            exec: execFlareToBase
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.oftFlare,
            remoteEid: BASE_EID,
            receiveLib: RECEIVE_LIB_FLARE,
            uln: ulnFlareReceiveFromBase
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("====================================================");
    }

    function configureLibrariesOnBaseForFlare(uint256 env) public {
        _configureLibrariesOnBaseForFlareWithBroadcast(env, "");
    }

    function configureLibrariesOnBaseForFlare(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnBaseForFlareWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnBaseForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Base for Flare ======");
        console2.log("UpOFT:", contracts.oft);
        console2.log("SendLib:", SEND_LIB_BASE);
        console2.log("ReceiveLib:", RECEIVE_LIB_BASE);
        console2.log("DVN (LZ Labs):", DVN1_BASE);
        console2.log("Executor:", EXECUTOR_BASE);

        if (contracts.oft.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.oft,
            dstEid: FLARE_EID,
            srcEid: FLARE_EID,
            sendLib: SEND_LIB_BASE,
            receiveLib: RECEIVE_LIB_BASE,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.oft,
            remoteEid: FLARE_EID,
            sendLib: SEND_LIB_BASE,
            uln: ulnBaseToFlare,
            exec: execBaseToFlare
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.oft,
            remoteEid: FLARE_EID,
            receiveLib: RECEIVE_LIB_BASE,
            uln: ulnBaseReceiveFromFlare
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("====================================================");
    }

    // ============ Flare <-> HyperEVM Functions ============

    function configurePeerOnFlareForHyperEVM(uint256 env) public {
        _configurePeerOnFlareForHyperEVMWithBroadcast(env, "");
    }

    function configurePeerOnFlareForHyperEVM(uint256 env, string memory saltNamespace) public {
        _configurePeerOnFlareForHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _configurePeerOnFlareForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Peer on Flare for HyperEVM ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("Peer (HyperEVM UpOFT):", contracts.oftHyperEVM);

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oftFlare, HYPEREVM_EID, contracts.oftHyperEVM);
        console2.log("[+] Peer configured successfully");
        console2.log("====================================================");
    }

    function configurePeerOnHyperEVMForFlare(uint256 env) public {
        _configurePeerOnHyperEVMForFlareWithBroadcast(env, "", address(0));
    }

    function configurePeerOnHyperEVMForFlare(uint256 env, string memory saltNamespace) public {
        _configurePeerOnHyperEVMForFlareWithBroadcast(env, saltNamespace, address(0));
    }

    /// @param flareOft Explicit Flare UpOFT address (use when caller is not the Flare deployer)
    function configurePeerOnHyperEVMForFlare(uint256 env, address flareOft) public {
        _configurePeerOnHyperEVMForFlareWithBroadcast(env, "", flareOft);
    }

    function _configurePeerOnHyperEVMForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace,
        address flareOftOverride
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();
        address flareOft = flareOftOverride != address(0) ? flareOftOverride : contracts.oftFlare;

        console2.log("");
        console2.log("====== Configuring Peer on HyperEVM for Flare ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("Peer (Flare UpOFT):", flareOft);

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping peer configuration");
            return;
        }
        _setPeer(contracts.oftHyperEVM, FLARE_EID, flareOft);
        console2.log("[+] Peer configured successfully");
        console2.log("====================================================");
    }

    function setEnforcedOptionsOnFlareForHyperEVM(uint256 env) public {
        _setEnforcedOptionsOnFlareForHyperEVMWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnFlareForHyperEVM(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnFlareForHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnFlareForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on Flare for HyperEVM ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("Destination: HyperEVM (EID:", HYPEREVM_EID, ")");

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oftFlare, HYPEREVM_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("=============================================================");
    }

    function setEnforcedOptionsOnHyperEVMForFlare(uint256 env) public {
        _setEnforcedOptionsOnHyperEVMForFlareWithBroadcast(env, "");
    }

    function setEnforcedOptionsOnHyperEVMForFlare(uint256 env, string memory saltNamespace) public {
        _setEnforcedOptionsOnHyperEVMForFlareWithBroadcast(env, saltNamespace);
    }

    function _setEnforcedOptionsOnHyperEVMForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Setting Enforced Options on HyperEVM for Flare ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("Destination: Flare (EID:", FLARE_EID, ")");

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping enforced options");
            return;
        }
        _setEnforcedOptions(contracts.oftHyperEVM, FLARE_EID);
        console2.log("[+] Enforced options set successfully");
        console2.log("=============================================================");
    }

    function configureLibrariesOnFlareForHyperEVM(uint256 env) public {
        _configureLibrariesOnFlareForHyperEVMWithBroadcast(env, "");
    }

    function configureLibrariesOnFlareForHyperEVM(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnFlareForHyperEVMWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnFlareForHyperEVMWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == FLARE_CHAIN_ID, "Must run on Flare");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on Flare for HyperEVM ======");
        console2.log("UpOFT:", contracts.oftFlare);
        console2.log("SendLib:", SEND_LIB_FLARE);
        console2.log("ReceiveLib:", RECEIVE_LIB_FLARE);
        console2.log("DVN (LZ Labs):", DVN_LZ_FLARE);
        console2.log("Executor:", EXECUTOR_FLARE);

        if (contracts.oftFlare.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibraries({
            oapp: contracts.oftFlare,
            dstEid: HYPEREVM_EID,
            srcEid: HYPEREVM_EID,
            sendLib: SEND_LIB_FLARE,
            receiveLib: RECEIVE_LIB_FLARE,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfig({
            oapp: contracts.oftFlare,
            remoteEid: HYPEREVM_EID,
            sendLib: SEND_LIB_FLARE,
            uln: ulnFlareToHyperEVM,
            exec: execFlareToHyperEVM
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfig({
            oapp: contracts.oftFlare,
            remoteEid: HYPEREVM_EID,
            receiveLib: RECEIVE_LIB_FLARE,
            uln: ulnFlareReceiveFromHyperEVM
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("=========================================================");
    }

    function configureLibrariesOnHyperEVMForFlare(uint256 env) public {
        _configureLibrariesOnHyperEVMForFlareWithBroadcast(env, "");
    }

    function configureLibrariesOnHyperEVMForFlare(uint256 env, string memory saltNamespace) public {
        _configureLibrariesOnHyperEVMForFlareWithBroadcast(env, saltNamespace);
    }

    function _configureLibrariesOnHyperEVMForFlareWithBroadcast(
        uint256 env,
        string memory saltNamespace
    )
        internal
        broadcast(env)
    {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        OFTContracts memory contracts = _computeAddresses();

        console2.log("");
        console2.log("====== Configuring Libraries on HyperEVM for Flare ======");
        console2.log("UpOFT:", contracts.oftHyperEVM);
        console2.log("SendLib:", SEND_LIB_HYPEREVM);
        console2.log("ReceiveLib:", RECEIVE_LIB_HYPEREVM);
        console2.log("DVN (LZ Labs):", DVN_LZ_HYPEREVM);
        console2.log("Executor:", EXECUTOR_HYPEREVM);

        if (contracts.oftHyperEVM.code.length == 0) {
            console2.log("[!] UpOFT not deployed yet, skipping library configuration");
            return;
        }

        _setLibrariesHyperEVM({
            oapp: contracts.oftHyperEVM,
            dstEid: FLARE_EID,
            srcEid: FLARE_EID,
            sendLib: SEND_LIB_HYPEREVM,
            receiveLib: RECEIVE_LIB_HYPEREVM,
            gracePeriod: GRACE_PERIOD
        });
        console2.log("[+] Send/Receive libraries set");

        _setSendConfigHyperEVM({
            oapp: contracts.oftHyperEVM,
            remoteEid: FLARE_EID,
            sendLib: SEND_LIB_HYPEREVM,
            uln: ulnHyperEVMToFlare,
            exec: execHyperEVMToFlare
        });
        console2.log("[+] Send config (ULN + Executor) set");

        _setReceiveConfigHyperEVM({
            oapp: contracts.oftHyperEVM,
            remoteEid: FLARE_EID,
            receiveLib: RECEIVE_LIB_HYPEREVM,
            uln: ulnHyperEVMReceiveFromFlare
        });
        console2.log("[+] Receive config (ULN) set");

        console2.log("=========================================================");
    }

    function _computeAddresses() internal returns (OFTContracts memory contracts) {
        return _computeAddresses(msg.sender);
    }

    function _computeAddresses(address owner) internal returns (OFTContracts memory contracts) {
        bytes memory adapterBytecode =
            abi.encodePacked(type(UpOFTAdapter).creationCode, abi.encode(UP_TOKEN, LZ_ENDPOINT, owner));
        contracts.adapter = DeterministicDeployerLib.computeAddress(adapterBytecode, _getSalt("UpOFTAdapter"));

        bytes memory oftBytecode = abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT, owner));
        contracts.oft = DeterministicDeployerLib.computeAddress(oftBytecode, _getSalt("UpOFT"));

        bytes memory oftHyperEVMBytecode =
            abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT_HYPEREVM, owner));
        contracts.oftHyperEVM = DeterministicDeployerLib.computeAddress(oftHyperEVMBytecode, _getSalt("UpOFT"));

        // Flare uses standard LZ_ENDPOINT (same as Base), so needs a different salt
        bytes memory oftFlareBytecode =
            abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT, owner));
        contracts.oftFlare = DeterministicDeployerLib.computeAddress(oftFlareBytecode, _getSalt("UpOFTFlare"));
    }

    function _deployAdapter(address owner) internal returns (address) {
        bytes32 salt = _getSalt("UpOFTAdapter");
        bytes memory bytecode =
            abi.encodePacked(type(UpOFTAdapter).creationCode, abi.encode(UP_TOKEN, LZ_ENDPOINT, owner));

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

    function _deployOFT(address owner) internal returns (address) {
        bytes32 salt = _getSalt("UpOFT");
        bytes memory bytecode = abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT, owner));

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

    function _deployOFTHyperEVM(address owner) internal returns (address) {
        bytes32 salt = _getSalt("UpOFT");
        bytes memory bytecode = abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT_HYPEREVM, owner));

        address predicted = DeterministicDeployerLib.computeAddress(bytecode, salt);

        if (predicted.code.length > 0) {
            console2.log("[!] UpOFT HyperEVM already deployed, skipping...");
            return predicted;
        }

        address deployed = DeterministicDeployerLib.deploy(bytecode, salt);
        require(deployed == predicted, "Address mismatch");
        require(deployed.code.length > 0, "Deployment failed");

        return deployed;
    }

    function _deployOFTFlare(address owner) internal returns (address) {
        // Flare uses standard LZ_ENDPOINT but different salt to get unique address
        bytes32 salt = _getSalt("UpOFTFlare");
        bytes memory bytecode = abi.encodePacked(type(UpOFT).creationCode, abi.encode(LZ_ENDPOINT, owner));

        address predicted = DeterministicDeployerLib.computeAddress(bytecode, salt);

        if (predicted.code.length > 0) {
            console2.log("[!] UpOFT Flare already deployed, skipping...");
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

    // HyperEVM-specific library functions (use LZ_ENDPOINT_HYPEREVM)
    function _setLibrariesHyperEVM(
        address oapp,
        uint32 dstEid,
        uint32 srcEid,
        address sendLib,
        address receiveLib,
        uint32 gracePeriod
    ) internal {
        // outbound messages to dstEid use sendLib
        ILayerZeroEndpointV2(LZ_ENDPOINT_HYPEREVM).setSendLibrary(oapp, dstEid, sendLib);

        // inbound messages from srcEid use receiveLib
        ILayerZeroEndpointV2(LZ_ENDPOINT_HYPEREVM).setReceiveLibrary(oapp, srcEid, receiveLib, gracePeriod);
    }

    function _setSendConfigHyperEVM(
        address oapp,
        uint32 remoteEid,
        address sendLib,
        UlnConfig memory uln,
        ExecutorConfig memory exec
    ) internal {
        SetConfigParam[] memory params = new SetConfigParam[](2);
        params[0] = SetConfigParam(remoteEid, EXECUTOR_CONFIG_TYPE, abi.encode(exec));
        params[1] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));

        ILayerZeroEndpointV2(LZ_ENDPOINT_HYPEREVM).setConfig(oapp, sendLib, params);
    }

    function _setReceiveConfigHyperEVM(
        address oapp,
        uint32 remoteEid,
        address receiveLib,
        UlnConfig memory uln
    ) internal {
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));

        ILayerZeroEndpointV2(LZ_ENDPOINT_HYPEREVM).setConfig(oapp, receiveLib, params);
    }

    function _getSalt(string memory name) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("SuperformV2", SALT_NAMESPACE, name, "v2.0"));
    }

    // ============ Export Functions ============

    mapping(uint64 chainId => string contracts) private exportedContracts;
    mapping(uint64 chainId => uint256 count) private contractCount;

    function _exportContract(string memory contractName, address addr, uint64 chainId) internal {
        contractCount[chainId]++;
        string memory objectKey = string(abi.encodePacked("UP_OFT_EXPORTS_", vm.toString(uint256(chainId))));
        exportedContracts[chainId] = vm.serializeAddress(objectKey, contractName, addr);
    }

    function _writeExportedContracts(uint64 chainId, string memory envName) internal {
        if (contractCount[chainId] == 0) return;

        string memory root = vm.projectRoot();
        string memory chainOutputFolder =
            string(abi.encodePacked("/script/output/", envName, "/", vm.toString(uint256(chainId)), "/"));

        // Create directory if it doesn't exist
        vm.createDir(string(abi.encodePacked(root, chainOutputFolder)), true);

        string memory chainName = _getChainName(chainId);
        string memory outputPath = string(abi.encodePacked(root, chainOutputFolder, chainName, "-latest.json"));

        string[] memory contractNames = vm.parseJsonKeys(exportedContracts[chainId], "$");
        for (uint256 i = 0; i < contractNames.length; i++) {
            string memory jsonPath = string(abi.encodePacked(".", contractNames[i]));
            address contractAddress = vm.parseJsonAddress(exportedContracts[chainId], jsonPath);
            vm.writeJson(vm.toString(contractAddress), outputPath, jsonPath);
        }

        console2.log("Exported", contractCount[chainId], "contracts to:", outputPath);
    }

    function _getChainName(uint64 chainId) internal pure returns (string memory) {
        if (chainId == MAINNET_CHAIN_ID) return "Ethereum";
        if (chainId == BASE_CHAIN_ID) return "Base";
        if (chainId == HYPEREVM_CHAIN_ID) return "HyperEVM";
        if (chainId == FLARE_CHAIN_ID) return "Flare";
        revert("UNSUPPORTED_CHAIN");
    }

    function _getEnvName(uint256 env) internal pure returns (string memory) {
        if (env == 0) return "prod";
        if (env == 2) return "staging";
        return "local";
    }

    /// @notice Export deployed contract addresses to JSON files
    /// @dev Call this after deployment to write addresses to script/output/{env}/{chainId}/{ChainName}-latest.json
    function exportAddresses(uint256 env) public {
        _exportAddresses(env, "");
    }

    function exportAddresses(uint256 env, string memory saltNamespace) public {
        _exportAddresses(env, saltNamespace);
    }

    function _exportAddresses(uint256 env, string memory saltNamespace) internal {
        _setConfiguration(env, saltNamespace);

        address owner = msg.sender;
        if (env == 1) {
            (owner,) = deriveRememberKey(MNEMONIC, 0);
        }

        OFTContracts memory contracts = _computeAddresses(owner);
        string memory envName = _getEnvName(env);

        console2.log("");
        console2.log("====== Exporting UP OFT Addresses ======");
        console2.log("Environment:", envName);
        console2.log("Owner:", owner);

        // Export Ethereum contracts
        _exportContract("UpOFTAdapter", contracts.adapter, MAINNET_CHAIN_ID);
        _writeExportedContracts(MAINNET_CHAIN_ID, envName);

        // Reset for Base
        contractCount[MAINNET_CHAIN_ID] = 0;

        // Export Base contracts
        _exportContract("UpOFT", contracts.oft, BASE_CHAIN_ID);
        _writeExportedContracts(BASE_CHAIN_ID, envName);

        // Reset for HyperEVM
        contractCount[BASE_CHAIN_ID] = 0;

        // Export HyperEVM contracts
        _exportContract("UpOFT", contracts.oftHyperEVM, HYPEREVM_CHAIN_ID);
        _writeExportedContracts(HYPEREVM_CHAIN_ID, envName);

        // Reset for Flare
        contractCount[HYPEREVM_CHAIN_ID] = 0;

        // Export Flare contracts
        _exportContract("UpOFT", contracts.oftFlare, FLARE_CHAIN_ID);
        _writeExportedContracts(FLARE_CHAIN_ID, envName);

        console2.log("");
        console2.log("====== Export Complete ======");
        console2.log("UpOFTAdapter (Ethereum):", contracts.adapter);
        console2.log("UpOFT (Base):", contracts.oft);
        console2.log("UpOFT (HyperEVM):", contracts.oftHyperEVM);
        console2.log("UpOFT (Flare):", contracts.oftFlare);
    }
}
