// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { IOFT, SendParam } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

/// @notice Send 1 UP token from Flare to ETH
contract SendUpFlareToETH is Script {
    address internal constant FLARE_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;
    uint32 internal constant ETH_EID = 30101;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 14, "Must run on Flare");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: Flare -> ETH ======");
        console2.log("Sender/Recipient:", sender);
        console2.log("");

        SendParam memory sendParam = SendParam({
            dstEid: ETH_EID,
            to: recipient,
            amountLD: AMOUNT,
            minAmountLD: MIN_AMOUNT,
            extraOptions: hex"",
            composeMsg: hex"",
            oftCmd: hex""
        });

        MessagingFee memory fee = IOFT(FLARE_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(FLARE_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to ETH!");
        vm.stopBroadcast();
    }
}

/// @notice Send 1 UP token from Flare to Base
contract SendUpFlareToBase is Script {
    address internal constant FLARE_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;
    uint32 internal constant BASE_EID = 30184;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 14, "Must run on Flare");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: Flare -> Base ======");
        console2.log("Sender/Recipient:", sender);
        console2.log("");

        SendParam memory sendParam = SendParam({
            dstEid: BASE_EID,
            to: recipient,
            amountLD: AMOUNT,
            minAmountLD: MIN_AMOUNT,
            extraOptions: hex"",
            composeMsg: hex"",
            oftCmd: hex""
        });

        MessagingFee memory fee = IOFT(FLARE_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(FLARE_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to Base!");
        vm.stopBroadcast();
    }
}

/// @notice Send 1 UP token from Flare to HyperEVM
contract SendUpFlareToHyperEVM is Script {
    address internal constant FLARE_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;
    uint32 internal constant HYPEREVM_EID = 30367;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 14, "Must run on Flare");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: Flare -> HyperEVM ======");
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

        MessagingFee memory fee = IOFT(FLARE_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(FLARE_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to HyperEVM!");
        vm.stopBroadcast();
    }
}
