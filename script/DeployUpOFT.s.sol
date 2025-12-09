// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { UpOFT } from "../src/UP/UpOFT.sol";

/**
 * @title DeployUpOFT
 * @notice Deploys the UpOFT on destination chains (e.g., Base)
 * @dev Run with:
 *      forge script script/DeployUpOFT.s.sol --rpc-url $BASE_RPC --broadcast --verify
 *
 * Environment variables:
 *   - PRIVATE_KEY: Deployer private key
 *   - OWNER_ADDRESS: Owner/delegate address for the OFT
 *   - LZ_ENDPOINT: LayerZero V2 endpoint address for the target chain
 */
contract DeployUpOFT is Script {
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice LayerZero V2 Endpoint on Base mainnet
    /// @dev Change this if deploying to a different chain
    address internal constant LZ_ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;

    function run() external {
        address owner = vm.envAddress("OWNER_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Use env var if provided, otherwise default to Base
        address lzEndpoint = vm.envOr("LZ_ENDPOINT", LZ_ENDPOINT_BASE);

        vm.startBroadcast(deployerPrivateKey);

        UpOFT oft = new UpOFT(lzEndpoint, owner);

        vm.stopBroadcast();

        console2.log("UpOFT deployed to:", address(oft));
        console2.log("  LZ Endpoint:", lzEndpoint);
        console2.log("  Owner:", owner);
    }
}
