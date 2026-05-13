// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IOFT, SendParam } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

/// @notice Send 1 UP token from ETH to HyperEVM via the OFTAdapter
/// @dev Run with: forge script script/SendUpToHyperEVM.s.sol:SendUpToHyperEVM --rpc-url $ETH_RPC --broadcast --account v2-supervaults -vvv
contract SendUpToHyperEVM is Script {
    address internal constant UP_TOKEN = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;
    address internal constant OFT_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;

    uint32 internal constant HYPEREVM_EID = 30367;
    uint256 internal constant AMOUNT = 1 ether; // 1 UP (18 decimals)
    uint256 internal constant MIN_AMOUNT = 0.995 ether; // 0.5% slippage

    function run() public {
        require(block.chainid == 1, "Must run on Ethereum");

        address sender = msg.sender;
        bytes32 recipient = bytes32(uint256(uint160(sender)));

        console2.log("====== Send 1 UP: ETH -> HyperEVM ======");
        console2.log("Sender/Recipient:", sender);
        console2.log("OFTAdapter:", OFT_ADAPTER);
        console2.log("Destination EID:", HYPEREVM_EID);
        console2.log("");

        // Build SendParam
        SendParam memory sendParam = SendParam({
            dstEid: HYPEREVM_EID,
            to: recipient,
            amountLD: AMOUNT,
            minAmountLD: MIN_AMOUNT,
            extraOptions: hex"",
            composeMsg: hex"",
            oftCmd: hex""
        });

        // Quote the fee
        MessagingFee memory fee = IOFT(OFT_ADAPTER).quoteSend(sendParam, false);
        console2.log("Native fee:", fee.nativeFee);
        console2.log("");

        vm.startBroadcast();

        // Approve OFTAdapter to spend UP
        IERC20(UP_TOKEN).approve(OFT_ADAPTER, AMOUNT);
        console2.log("Approved OFTAdapter to spend 1 UP");

        // Send
        IOFT(OFT_ADAPTER).send{ value: fee.nativeFee }(sendParam, fee, sender);
        console2.log("Sent 1 UP to HyperEVM!");

        vm.stopBroadcast();
    }
}
