// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { IMessageLibManager, SetConfigParam } from
    "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import { ExecutorConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";

/// @title ConfigureBaseUpOFTPathwayToRH
/// @notice ONE-OFF: executes the delegate-permissioned transactions (TX 2-5) from
///         script/output/rh-pathway-calldata/base-to-rh.md on Base for the UpOFT -> RH pathway:
///         setSendLibrary, setReceiveLibrary, setConfig(send ULN + executor), setConfig(receive ULN).
///
///         The two owner-permissioned transactions (setPeer, setEnforcedOptions) remain in the md
///         file for the multisig. DELETE THIS FILE AFTER EXECUTION.
///
/// @dev Sender must be the UpOFT's registered delegate on the LZ endpoint
///      (deployer 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8 = v2-supervaults keystore).
///      Each built calldata is asserted byte-for-byte against the reviewed calldata in the md
///      before being sent. Already-applied steps are skipped.
///
/// Run: ./script/run/configure_base_upoft_to_rh.sh {simulate|execute}
contract ConfigureBaseUpOFTPathwayToRH is Script {
    uint256 internal constant BASE_CHAIN_ID = 8453;
    uint32 internal constant RH_EID = 30_416;

    address internal constant UP_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant SEND_LIB = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address internal constant RECEIVE_LIB = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address internal constant EXECUTOR = 0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4;

    // DVNs (sorted ascending): Nethermind, LZ, Horizen, Superform
    address internal constant DVN_NETHERMIND = 0x554833698Ae0FB22ECC90B01222903fD62CA4B47;
    address internal constant DVN_LZ = 0x9e059a54699a285714207b43B055483E78FAac25;
    address internal constant DVN_HORIZEN = 0xcd37CA043f8479064e10635020c65FfC005d36f6;
    address internal constant DVN_SUPERFORM = 0xEb62f578497Bdc351dD650853a751135212fAF49;

    uint64 internal constant CONFIRMATIONS = 20;
    uint32 internal constant MAX_MESSAGE_SIZE = 10_000;
    uint32 internal constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // keccak256 of the reviewed calldata in base-to-rh.md (TX 2-5) — built calldata must match
    bytes32 internal constant TX2_CALLDATA_HASH = 0x23b889830b8be4801cf6c635648ab580e56679daec754c8aeb4d8cb564211643;
    bytes32 internal constant TX3_CALLDATA_HASH = 0x9a812834d9a346701bf69d18e87f614199f05a0ae30d18c2e722da87ece084d6;
    bytes32 internal constant TX4_CALLDATA_HASH = 0x5a394614e25c24c428334bea47fc7fb208a2767db622abf02ea3a5dfb82c3c6c;
    bytes32 internal constant TX5_CALLDATA_HASH = 0xc37c549f8889ebb9c5d2e6b015e2f5a86c42342ab06aca4a407938de27f3bd90;

    function run() external {
        require(block.chainid == BASE_CHAIN_ID, "BASE_ONLY");

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(LZ_ENDPOINT);

        console2.log("=== Base UpOFT -> RH pathway: delegate transactions (TX 2-5) ===");
        console2.log("UpOFT:", UP_OFT);
        console2.log("Endpoint:", LZ_ENDPOINT);
        // delegates() is a public mapping on EndpointV2, not part of ILayerZeroEndpointV2
        (bool ok, bytes memory ret) = LZ_ENDPOINT.staticcall(abi.encodeWithSignature("delegates(address)", UP_OFT));
        require(ok, "DELEGATE_LOOKUP_FAILED");
        console2.log("Registered delegate:", abi.decode(ret, (address)));

        vm.startBroadcast();

        // ── TX 2: setSendLibrary ────────────────────────────────────────
        bool sendLibPinned =
            endpoint.getSendLibrary(UP_OFT, RH_EID) == SEND_LIB && !endpoint.isDefaultSendLibrary(UP_OFT, RH_EID);
        if (sendLibPinned) {
            console2.log("TX 2 setSendLibrary: already pinned - skipping");
        } else {
            bytes memory data = abi.encodeCall(IMessageLibManager.setSendLibrary, (UP_OFT, RH_EID, SEND_LIB));
            require(keccak256(data) == TX2_CALLDATA_HASH, "TX2_CALLDATA_MISMATCH");
            endpoint.setSendLibrary(UP_OFT, RH_EID, SEND_LIB);
            console2.log("TX 2 setSendLibrary: done");
        }

        // ── TX 3: setReceiveLibrary ─────────────────────────────────────
        (address recvLib, bool isDefault) = endpoint.getReceiveLibrary(UP_OFT, RH_EID);
        if (recvLib == RECEIVE_LIB && !isDefault) {
            console2.log("TX 3 setReceiveLibrary: already pinned - skipping");
        } else {
            bytes memory data = abi.encodeCall(IMessageLibManager.setReceiveLibrary, (UP_OFT, RH_EID, RECEIVE_LIB, 0));
            require(keccak256(data) == TX3_CALLDATA_HASH, "TX3_CALLDATA_MISMATCH");
            endpoint.setReceiveLibrary(UP_OFT, RH_EID, RECEIVE_LIB, 0);
            console2.log("TX 3 setReceiveLibrary: done");
        }

        bytes memory ulnBytes = abi.encode(_ulnConfig());

        // ── TX 4: setConfig on send lib (executor + ULN) ────────────────
        if (keccak256(endpoint.getConfig(UP_OFT, SEND_LIB, RH_EID, ULN_CONFIG_TYPE)) == keccak256(ulnBytes)) {
            console2.log("TX 4 setConfig(send): already applied - skipping");
        } else {
            SetConfigParam[] memory params = new SetConfigParam[](2);
            params[0] = SetConfigParam({
                eid: RH_EID,
                configType: EXECUTOR_CONFIG_TYPE,
                config: abi.encode(ExecutorConfig({ maxMessageSize: MAX_MESSAGE_SIZE, executor: EXECUTOR }))
            });
            params[1] = SetConfigParam({ eid: RH_EID, configType: ULN_CONFIG_TYPE, config: ulnBytes });

            bytes memory data = abi.encodeCall(IMessageLibManager.setConfig, (UP_OFT, SEND_LIB, params));
            require(keccak256(data) == TX4_CALLDATA_HASH, "TX4_CALLDATA_MISMATCH");
            endpoint.setConfig(UP_OFT, SEND_LIB, params);
            console2.log("TX 4 setConfig(send): done");
        }

        // ── TX 5: setConfig on receive lib (ULN) ────────────────────────
        if (keccak256(endpoint.getConfig(UP_OFT, RECEIVE_LIB, RH_EID, ULN_CONFIG_TYPE)) == keccak256(ulnBytes)) {
            console2.log("TX 5 setConfig(receive): already applied - skipping");
        } else {
            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: RH_EID, configType: ULN_CONFIG_TYPE, config: ulnBytes });

            bytes memory data = abi.encodeCall(IMessageLibManager.setConfig, (UP_OFT, RECEIVE_LIB, params));
            require(keccak256(data) == TX5_CALLDATA_HASH, "TX5_CALLDATA_MISMATCH");
            endpoint.setConfig(UP_OFT, RECEIVE_LIB, params);
            console2.log("TX 5 setConfig(receive): done");
        }

        vm.stopBroadcast();

        console2.log("");
        console2.log("Delegate transactions complete. Remaining for the multisig (see base-to-rh.md):");
        console2.log("  setPeer + setEnforcedOptions on the UpOFT");
    }

    function _ulnConfig() internal pure returns (UlnConfig memory) {
        address[] memory requiredDVNs = new address[](4);
        requiredDVNs[0] = DVN_NETHERMIND;
        requiredDVNs[1] = DVN_LZ;
        requiredDVNs[2] = DVN_HORIZEN;
        requiredDVNs[3] = DVN_SUPERFORM;

        return UlnConfig({
            confirmations: CONFIRMATIONS,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: requiredDVNs,
            optionalDVNs: new address[](0)
        });
    }
}
