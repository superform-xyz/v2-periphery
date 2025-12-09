// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";

/**
 * @title SetUpOFTPeers
 * @notice Sets up peer connections between UpOFTAdapter (Ethereum) and UpOFT (Base)
 * @dev This script must be run twice - once on each chain:
 *
 *      On Ethereum (to set Base as peer):
 *      OAPP_ADDRESS=<adapter_address> PEER_ADDRESS=<base_oft_address> PEER_EID=30184 \
 *      forge script script/SetUpOFTPeers.s.sol --rpc-url $ETHEREUM_RPC --broadcast
 *
 *      On Base (to set Ethereum as peer):
 *      OAPP_ADDRESS=<base_oft_address> PEER_ADDRESS=<adapter_address> PEER_EID=30101 \
 *      forge script script/SetUpOFTPeers.s.sol --rpc-url $BASE_RPC --broadcast
 *
 * Environment variables:
 *   - PRIVATE_KEY: Owner private key
 *   - OAPP_ADDRESS: Address of the OFT/OFTAdapter on the current chain
 *   - PEER_ADDRESS: Address of the OFT/OFTAdapter on the remote chain
 *   - PEER_EID: LayerZero Endpoint ID of the remote chain
 *
 * LayerZero Endpoint IDs (mainnet):
 *   - Ethereum: 30101
 *   - Base: 30184
 */
contract SetUpOFTPeers is Script {
    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address oappAddress = vm.envAddress("OAPP_ADDRESS");
        address peerAddress = vm.envAddress("PEER_ADDRESS");
        uint32 peerEid = uint32(vm.envUint("PEER_EID"));

        // Convert address to bytes32 format required by LayerZero
        bytes32 peerBytes32 = bytes32(uint256(uint160(peerAddress)));

        vm.startBroadcast(deployerPrivateKey);

        IOAppCore(oappAddress).setPeer(peerEid, peerBytes32);

        vm.stopBroadcast();

        console2.log("Peer set successfully!");
        console2.log("  OApp:", oappAddress);
        console2.log("  Peer EID:", peerEid);
        console2.log("  Peer Address:", peerAddress);
    }
}
