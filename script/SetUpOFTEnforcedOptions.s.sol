// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import { EnforcedOptionParam } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { IOAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppOptionsType3.sol";

/**
 * @title SetUpOFTEnforcedOptions
 * @notice Sets enforced execution options for UP OFT/OFTAdapter
 * @dev CRITICAL: Without enforced options, send() will fail with LZ_ULN_InvalidWorkerOptions
 *
 *      Run on Ethereum (for Base destination):
 *      OAPP_ADDRESS=<adapter_address> DST_EID=30184 PRIVATE_KEY=<key> \
 *      forge script script/SetUpOFTEnforcedOptions.s.sol --rpc-url $ETHEREUM_RPC --broadcast
 *
 *      Run on Base (for Ethereum destination):
 *      OAPP_ADDRESS=<oft_address> DST_EID=30101 PRIVATE_KEY=<key> \
 *      forge script script/SetUpOFTEnforcedOptions.s.sol --rpc-url $BASE_RPC --broadcast
 *
 * Environment variables:
 *   - PRIVATE_KEY: Owner private key
 *   - OAPP_ADDRESS: Address of the OFT/OFTAdapter on the current chain
 *   - DST_EID: Destination LayerZero Endpoint ID
 *   - GAS_LIMIT: (Optional) Gas for lzReceive, defaults to 100000
 *
 * LayerZero Endpoint IDs (mainnet):
 *   - Ethereum: 30101
 *   - Base: 30184
 */
contract SetUpOFTEnforcedOptions is Script {
    using OptionsBuilder for bytes;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice OFT message type for standard token transfer
    uint16 internal constant SEND = 1;

    /// @notice OFT message type for token transfer with compose call
    uint16 internal constant SEND_AND_CALL = 2;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address oappAddress = vm.envAddress("OAPP_ADDRESS");
        uint32 dstEid = uint32(vm.envUint("DST_EID"));

        // Default gas limit for lzReceive (can be overridden via env var)
        // 100k is typically sufficient for simple OFT transfers
        uint128 gasLimit = uint128(vm.envOr("GAS_LIMIT", uint256(100_000)));

        // Build options using OptionsBuilder
        // addExecutorLzReceiveOption(gas, value) - gas for execution, value for native token
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gasLimit, 0);

        // Create enforced options for both message types
        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);

        // SEND message type (standard token transfer)
        enforcedOptions[0] = EnforcedOptionParam({ eid: dstEid, msgType: SEND, options: options });

        // SEND_AND_CALL message type (token transfer + compose call)
        enforcedOptions[1] = EnforcedOptionParam({ eid: dstEid, msgType: SEND_AND_CALL, options: options });

        vm.startBroadcast(deployerPrivateKey);

        IOAppOptionsType3(oappAddress).setEnforcedOptions(enforcedOptions);

        vm.stopBroadcast();

        console2.log("Enforced options set successfully!");
        console2.log("  OApp:", oappAddress);
        console2.log("  Destination EID:", dstEid);
        console2.log("  Gas Limit:", gasLimit);
    }
}
