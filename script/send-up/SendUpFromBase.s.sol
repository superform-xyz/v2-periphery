// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { IOFT, SendParam } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

/// @notice Send 1 UP token from Base to HyperEVM
contract SendUpBaseToHyperEVM is Script {
    address internal constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    uint32 internal constant HYPEREVM_EID = 30367;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 8453, "Must run on Base");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: Base -> HyperEVM ======");
        console2.log("Sender/Recipient:", sender);
        console2.log("");

        SendParam memory sendParam = SendParam({
            dstEid: HYPEREVM_EID,
            to: recipient,
            amountLD: AMOUNT,
            minAmountLD: MIN_AMOUNT,
            extraOptions: hex"",
            composeMsg: hex"",
            oftCmd: hex""
        });

        MessagingFee memory fee = IOFT(BASE_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(BASE_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to HyperEVM!");
        vm.stopBroadcast();
    }
}

/// @notice Send 1 UP token from Base to Flare
contract SendUpBaseToFlare is Script {
    address internal constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    uint32 internal constant FLARE_EID = 30295;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 8453, "Must run on Base");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: Base -> Flare ======");
        console2.log("Sender/Recipient:", sender);
        console2.log("");

        SendParam memory sendParam = SendParam({
            dstEid: FLARE_EID,
            to: recipient,
            amountLD: AMOUNT,
            minAmountLD: MIN_AMOUNT,
            extraOptions: hex"",
            composeMsg: hex"",
            oftCmd: hex""
        });

        MessagingFee memory fee = IOFT(BASE_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(BASE_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to Flare!");
        vm.stopBroadcast();
    }
}
