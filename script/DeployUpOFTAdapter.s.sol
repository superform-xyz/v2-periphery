// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { UpOFTAdapter } from "../src/UP/UpOFTAdapter.sol";

/**
 * @title DeployUpOFTAdapter
 * @notice Deploys the UpOFTAdapter on Ethereum mainnet
 * @dev Run with:
 *      forge script script/DeployUpOFTAdapter.s.sol --rpc-url $ETHEREUM_RPC --broadcast --verify
 *
 * Environment variables:
 *   - PRIVATE_KEY: Deployer private key
 *   - OWNER_ADDRESS: Owner/delegate address for the adapter
 */
contract DeployUpOFTAdapter is Script {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice UP token on Ethereum mainnet
    address internal constant UP_TOKEN = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;

    /// @notice LayerZero V2 Endpoint on Ethereum mainnet
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;

    function run() external {
        address owner = vm.envAddress("OWNER_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        UpOFTAdapter adapter = new UpOFTAdapter(UP_TOKEN, LZ_ENDPOINT, owner);

        vm.stopBroadcast();

        console2.log("UpOFTAdapter deployed to:", address(adapter));
        console2.log("  UP Token:", UP_TOKEN);
        console2.log("  LZ Endpoint:", LZ_ENDPOINT);
        console2.log("  Owner:", owner);
    }
}
