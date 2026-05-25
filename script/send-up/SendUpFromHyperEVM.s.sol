// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { IOFT, SendParam } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

/// @notice Send 1 UP token from HyperEVM to ETH
contract SendUpHyperEVMToETH is Script {
    address internal constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    uint32 internal constant ETH_EID = 30101;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 999, "Must run on HyperEVM");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: HyperEVM -> ETH ======");
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

        MessagingFee memory fee = IOFT(HYPEREVM_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(HYPEREVM_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to ETH!");
        vm.stopBroadcast();
    }
}

/// @notice Send 1 UP token from HyperEVM to Base
contract SendUpHyperEVMToBase is Script {
    address internal constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    uint32 internal constant BASE_EID = 30184;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 999, "Must run on HyperEVM");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: HyperEVM -> Base ======");
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

        MessagingFee memory fee = IOFT(HYPEREVM_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(HYPEREVM_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to Base!");
        vm.stopBroadcast();
    }
}

/// @notice Send 1 UP token from HyperEVM to Flare
contract SendUpHyperEVMToFlare is Script {
    address internal constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    uint32 internal constant FLARE_EID = 30295;
    uint256 internal constant AMOUNT = 1 ether;
    uint256 internal constant MIN_AMOUNT = 0.995 ether;

    function run() public {
        require(block.chainid == 999, "Must run on HyperEVM");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: HyperEVM -> Flare ======");
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

        MessagingFee memory fee = IOFT(HYPEREVM_OFT).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);

        vm.startBroadcast();
        IOFT(HYPEREVM_OFT).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to Flare!");
        vm.stopBroadcast();
    }
}
