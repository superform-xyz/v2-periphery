// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { UpOFT } from "../../../src/UP/UpOFT.sol";
import { UpOFTAdapter } from "../../../src/UP/UpOFTAdapter.sol";

import { IOFT, SendParam, OFTReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import { IOAppOptionsType3, EnforcedOptionParam } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { LayerZeroV2Helper } from "@pigeon/layerzero-v2/LayerZeroV2Helper.sol";

contract UpOftIntegrationTest is Test {
    using OptionsBuilder for bytes;

    address constant UP_TOKEN = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;
    address constant LZ_ENDPOINT_ETH = 0x1a44076050125825900e736c501f859c50fE728c;
    address constant LZ_ENDPOINT_BASE = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 constant ETH_EID = 30101;
    uint32 constant BASE_EID = 30184;
    uint16 constant SEND = 1;
    uint16 constant SEND_AND_CALL = 2;
    uint128 constant GAS_LIMIT = 300_000;
    uint128 constant COMPOSE_GAS_LIMIT = 1_000_000;
    uint256 constant BRIDGE_PERCENTAGE = 15;

    uint256 public ethForkId;
    uint256 public baseForkId;
    UpOFTAdapter public adapter;
    UpOFT public oft;
    IERC20 public upToken;
    address public owner;
    address public bridger;
    address public recipient;
    LayerZeroV2Helper public lzHelper;

    function setUp() public {
        ethForkId = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        baseForkId = vm.createFork(vm.envString("BASE_RPC_URL"));

        owner = makeAddr("owner");
        bridger = makeAddr("bridger");
        recipient = makeAddr("recipient");

        lzHelper = new LayerZeroV2Helper();

        vm.selectFork(ethForkId);
        upToken = IERC20(UP_TOKEN);

        vm.startPrank(owner);
        adapter = new UpOFTAdapter(UP_TOKEN, LZ_ENDPOINT_ETH, owner);
        vm.stopPrank();

        vm.selectFork(baseForkId);

        vm.startPrank(owner);
        oft = new UpOFT(LZ_ENDPOINT_BASE, owner);
        vm.stopPrank();

        //SetUpOFTPeers.s.sol on Ethereum (adapter -> Base OFT)
        //SetUpOFTPeers.s.sol on Base (OFT -> Ethereum adapter)
        //SetUpOFTEnforcedOptions.s.sol on Ethereum (for Base destination)
        //SetUpOFTEnforcedOptions.s.sol on Base (for Ethereum destination)
        _configurePeers();
        _setEnforcedOptions();
    }

    function _configurePeers() internal {
        bytes32 adapterBytes32 = bytes32(uint256(uint160(address(adapter))));
        bytes32 oftBytes32 = bytes32(uint256(uint160(address(oft))));

        vm.selectFork(ethForkId);
        vm.prank(owner);
        IOAppCore(address(adapter)).setPeer(BASE_EID, oftBytes32);

        vm.selectFork(baseForkId);
        vm.prank(owner);
        IOAppCore(address(oft)).setPeer(ETH_EID, adapterBytes32);
    }

    function _setEnforcedOptions() internal {
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);
        bytes memory sendAndCallOptions =
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0).addExecutorLzComposeOption(
                0, COMPOSE_GAS_LIMIT, 0
            );

        vm.selectFork(ethForkId);
        EnforcedOptionParam[] memory ethEnforcedOptions = new EnforcedOptionParam[](2);
        ethEnforcedOptions[0] = EnforcedOptionParam({ eid: BASE_EID, msgType: SEND, options: sendOptions });
        ethEnforcedOptions[1] = EnforcedOptionParam({ eid: BASE_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        vm.prank(owner);
        IOAppOptionsType3(address(adapter)).setEnforcedOptions(ethEnforcedOptions);

        vm.selectFork(baseForkId);
        EnforcedOptionParam[] memory baseEnforcedOptions = new EnforcedOptionParam[](2);
        baseEnforcedOptions[0] = EnforcedOptionParam({ eid: ETH_EID, msgType: SEND, options: sendOptions });
        baseEnforcedOptions[1] = EnforcedOptionParam({ eid: ETH_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        vm.prank(owner);
        IOAppOptionsType3(address(oft)).setEnforcedOptions(baseEnforcedOptions);
    }

    function test_upOft_deployment() public {
        vm.selectFork(ethForkId);
        assertEq(adapter.token(), UP_TOKEN);
        assertEq(adapter.owner(), owner);
        assertTrue(adapter.approvalRequired());

        vm.selectFork(baseForkId);
        assertEq(oft.token(), address(oft));
        assertEq(oft.owner(), owner);
        assertFalse(oft.approvalRequired());
        assertEq(oft.name(), "Superform");
        assertEq(oft.symbol(), "UP");
    }

    function test_upOft_peersConfigured() public {
        bytes32 adapterBytes32 = bytes32(uint256(uint160(address(adapter))));
        bytes32 oftBytes32 = bytes32(uint256(uint160(address(oft))));

        vm.selectFork(ethForkId);
        assertEq(IOAppCore(address(adapter)).peers(BASE_EID), oftBytes32);

        vm.selectFork(baseForkId);
        assertEq(IOAppCore(address(oft)).peers(ETH_EID), adapterBytes32);
    }

    function test_upOft_quoteBridge15PercentSupply() public {
        vm.selectFork(ethForkId);

        uint256 totalSupply = upToken.totalSupply();
        uint256 amountToBridge = (totalSupply * BRIDGE_PERCENTAGE) / 100;

        SendParam memory sendParam = SendParam({
            dstEid: BASE_EID,
            to: bytes32(uint256(uint160(recipient))),
            amountLD: amountToBridge,
            minAmountLD: (amountToBridge * 99) / 100,
            extraOptions: "",
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory fee = IOFT(address(adapter)).quoteSend(sendParam, false);

        assertGt(fee.nativeFee, 0);
        assertLt(fee.nativeFee, 1 ether);
    }

    function test_upOft_bridge15PercentSupply() public {
        vm.selectFork(ethForkId);

        uint256 totalSupply = upToken.totalSupply();
        uint256 amountToBridge = (totalSupply * BRIDGE_PERCENTAGE) / 100;

        deal(UP_TOKEN, bridger, amountToBridge);

        uint256 bridgerBalanceBefore = upToken.balanceOf(bridger);
        uint256 adapterBalanceBefore = upToken.balanceOf(address(adapter));

        SendParam memory sendParam = SendParam({
            dstEid: BASE_EID,
            to: bytes32(uint256(uint160(recipient))),
            amountLD: amountToBridge,
            minAmountLD: (amountToBridge * 99) / 100,
            extraOptions: "",
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory fee = IOFT(address(adapter)).quoteSend(sendParam, false);

        vm.deal(bridger, fee.nativeFee + 1 ether);

        vm.startPrank(bridger);
        upToken.approve(address(adapter), amountToBridge);

        (, OFTReceipt memory oftReceipt) =
            IOFT(address(adapter)).send{ value: fee.nativeFee }(sendParam, fee, bridger);
        vm.stopPrank();

        uint256 bridgerBalanceAfter = upToken.balanceOf(bridger);
        uint256 adapterBalanceAfter = upToken.balanceOf(address(adapter));

        assertEq(bridgerBalanceAfter, bridgerBalanceBefore - oftReceipt.amountSentLD);
        assertEq(adapterBalanceAfter, adapterBalanceBefore + oftReceipt.amountSentLD);
    }

    function test_upOft_oftVersion() public {
        vm.selectFork(ethForkId);
        (bytes4 adapterInterfaceId, uint64 adapterVersion) = IOFT(address(adapter)).oftVersion();

        vm.selectFork(baseForkId);
        (bytes4 oftInterfaceId, uint64 oftVersion) = IOFT(address(oft)).oftVersion();

        assertEq(adapterInterfaceId, oftInterfaceId);
        assertEq(adapterVersion, oftVersion);
        assertEq(adapterInterfaceId, bytes4(0x02e49c2c));
    }

    function test_upOft_sharedDecimals() public {
        vm.selectFork(ethForkId);
        uint8 adapterSharedDecimals = IOFT(address(adapter)).sharedDecimals();

        vm.selectFork(baseForkId);
        uint8 oftSharedDecimals = IOFT(address(oft)).sharedDecimals();

        assertEq(adapterSharedDecimals, oftSharedDecimals);
        assertEq(adapterSharedDecimals, 6);
    }

    function test_upOft_dustHandling() public {
        vm.selectFork(ethForkId);

        uint256 amountWithDust = 1.123456789012345678 ether;
        uint256 expectedAmountWithoutDust = 1.123456000000000000 ether;

        deal(UP_TOKEN, bridger, amountWithDust);

        SendParam memory sendParam = SendParam({
            dstEid: BASE_EID,
            to: bytes32(uint256(uint160(recipient))),
            amountLD: amountWithDust,
            minAmountLD: expectedAmountWithoutDust - 1,
            extraOptions: "",
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory fee = IOFT(address(adapter)).quoteSend(sendParam, false);
        vm.deal(bridger, fee.nativeFee + 1 ether);

        vm.startPrank(bridger);
        upToken.approve(address(adapter), amountWithDust);

        (, OFTReceipt memory oftReceipt) =
            IOFT(address(adapter)).send{ value: fee.nativeFee }(sendParam, fee, bridger);
        vm.stopPrank();

        assertEq(oftReceipt.amountSentLD, expectedAmountWithoutDust);
        assertEq(oftReceipt.amountReceivedLD, expectedAmountWithoutDust);

        uint256 bridgerBalance = upToken.balanceOf(bridger);
        assertEq(bridgerBalance, amountWithDust - expectedAmountWithoutDust);
    }

    function test_upOft_bridge15PercentSupplyE2E() public {
        vm.selectFork(ethForkId);

        uint256 totalSupply = upToken.totalSupply();
        uint256 amountToBridge = (totalSupply * BRIDGE_PERCENTAGE) / 100;

        deal(UP_TOKEN, bridger, amountToBridge);

        uint256 bridgerBalanceBefore = upToken.balanceOf(bridger);
        uint256 adapterBalanceBefore = upToken.balanceOf(address(adapter));

        SendParam memory sendParam = SendParam({
            dstEid: BASE_EID,
            to: bytes32(uint256(uint160(recipient))),
            amountLD: amountToBridge,
            minAmountLD: (amountToBridge * 99) / 100,
            extraOptions: "",
            composeMsg: "",
            oftCmd: ""
        });

        MessagingFee memory fee = IOFT(address(adapter)).quoteSend(sendParam, false);

        vm.deal(bridger, fee.nativeFee + 1 ether);

        vm.recordLogs();

        vm.startPrank(bridger);
        upToken.approve(address(adapter), amountToBridge);

        (, OFTReceipt memory oftReceipt) =
            IOFT(address(adapter)).send{ value: fee.nativeFee }(sendParam, fee, bridger);
        vm.stopPrank();

        Vm.Log[] memory logs = vm.getRecordedLogs();

        uint256 bridgerBalanceAfter = upToken.balanceOf(bridger);
        uint256 adapterBalanceAfter = upToken.balanceOf(address(adapter));

        assertEq(bridgerBalanceAfter, bridgerBalanceBefore - oftReceipt.amountSentLD);
        assertEq(adapterBalanceAfter, adapterBalanceBefore + oftReceipt.amountSentLD);

        vm.selectFork(baseForkId);
        uint256 recipientBalanceBefore = oft.balanceOf(recipient);
        assertEq(recipientBalanceBefore, 0);

        lzHelper.help(LZ_ENDPOINT_BASE, baseForkId, logs);

        uint256 recipientBalanceAfter = oft.balanceOf(recipient);
        assertEq(recipientBalanceAfter, oftReceipt.amountReceivedLD);
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
