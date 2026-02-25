// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { OFTComposeMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import { SendParam } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

import { UpHyperLiquidComposer } from "../../../src/UP/UpHyperLiquidComposer.sol";
import { MockOFTForComposer } from "../../mocks/MockOFTForComposer.sol";

import {
    IHyperLiquidComposer,
    IHyperAssetAmount
} from "lib/devtools/packages/hyperliquid-composer/contracts/interfaces/IHyperLiquidComposer.sol";
import { IRecoverableComposer } from
    "lib/devtools/packages/hyperliquid-composer/contracts/interfaces/IRecoverableComposer.sol";
import { ICoreWriter } from "lib/devtools/packages/hyperliquid-composer/contracts/interfaces/ICoreWriter.sol";
import { HyperLiquidComposerCodec } from
    "lib/devtools/packages/hyperliquid-composer/contracts/library/HyperLiquidComposerCodec.sol";
import { SpotBalance } from "lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidCore.sol";

// ============ Precompile Mocks (local copies for pragma compatibility) ============

contract SpotBalancePrecompileMock {
    mapping(address user => mapping(uint64 tokenId => SpotBalance balance)) private _balances;

    function setSpotBalance(address user, uint64 tokenId, uint64 balance) external {
        _balances[user][tokenId] = SpotBalance({ total: balance, hold: 0, entryNtl: 0 });
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        (address user, uint64 tokenId) = abi.decode(data, (address, uint64));
        return abi.encode(_balances[user][tokenId]);
    }
}

contract CoreUserExistsMock {
    mapping(address user => bool isActive) private _exists;

    function setUserExists(address user, bool exists) external {
        _exists[user] = exists;
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        address user = abi.decode(data, (address));
        return abi.encode(_exists[user]);
    }
}

contract CoreWriterMock is ICoreWriter {
    function sendRawAction(bytes calldata data) external override {
        emit RawAction(msg.sender, data);
    }
}

// ============ Unit Tests ============

contract UpHyperLiquidComposerUnitTest is Test {
    // HyperLiquid precompile addresses
    address constant SPOT_BALANCE_PRECOMPILE = 0x0000000000000000000000000000000000000801;
    address constant CORE_USER_EXISTS_PRECOMPILE = 0x0000000000000000000000000000000000000810;
    address constant HYPE_ASSET_BRIDGE = 0x2222222222222222222222222222222222222222;
    address constant CORE_WRITER = 0x3333333333333333333333333333333333333333;

    // Test configuration
    uint64 constant CORE_INDEX_ID = 42;
    int8 constant DECIMAL_DIFF = 10; // 18 EVM - 8 Core
    uint256 constant SCALE = 10 ** 10;

    // Test actors
    address public endpoint;
    address public recovery;
    address public userA;
    address public userB;
    address public attacker;

    // Contracts
    MockOFTForComposer public oft;
    UpHyperLiquidComposer public composer;
    address public erc20AssetBridge;

    function setUp() public {
        // Set chain ID to HyperEVM mainnet
        vm.chainId(999);

        endpoint = makeAddr("endpoint");
        recovery = makeAddr("recovery");
        userA = makeAddr("userA");
        userB = makeAddr("userB");
        attacker = makeAddr("attacker");

        // Etch precompile mocks
        vm.etch(SPOT_BALANCE_PRECOMPILE, address(new SpotBalancePrecompileMock()).code);
        vm.etch(CORE_USER_EXISTS_PRECOMPILE, address(new CoreUserExistsMock()).code);
        vm.etch(CORE_WRITER, address(new CoreWriterMock()).code);

        // Deploy mock OFT
        oft = new MockOFTForComposer("UP", "UP", endpoint);

        // Deploy composer
        composer = new UpHyperLiquidComposer(address(oft), CORE_INDEX_ID, DECIMAL_DIFF, recovery);

        // Compute ERC20 asset bridge address
        erc20AssetBridge = HyperLiquidComposerCodec.into_assetBridgeAddress(CORE_INDEX_ID);

        // Set up precompile state: max bridge balance for both assets
        SpotBalancePrecompileMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(
            erc20AssetBridge, CORE_INDEX_ID, type(uint64).max
        );
        SpotBalancePrecompileMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(
            HYPE_ASSET_BRIDGE, 150, type(uint64).max // HYPE core index on mainnet = 150
        );

        // Activate test users on HyperCore
        CoreUserExistsMock(CORE_USER_EXISTS_PRECOMPILE).setUserExists(userA, true);
        CoreUserExistsMock(CORE_USER_EXISTS_PRECOMPILE).setUserExists(userB, true);

        // Fund endpoint for msg.value tests
        vm.deal(endpoint, 100 ether);

        // Etch HYPE asset bridge with a payable fallback
        vm.etch(HYPE_ASSET_BRIDGE, hex"00"); // minimal code so it can receive ETH
    }

    // ==================== Constructor / Deployment ====================

    function test_deployment_correctImmutables() public view {
        assertEq(composer.OFT(), address(oft));
        assertEq(composer.ENDPOINT(), endpoint);
        assertEq(composer.ERC20(), address(oft)); // token() returns self for native OFTs
        assertEq(composer.ERC20_ASSET_BRIDGE(), erc20AssetBridge);
        assertEq(composer.ERC20_CORE_INDEX_ID(), CORE_INDEX_ID);
        assertEq(composer.ERC20_DECIMAL_DIFF(), DECIMAL_DIFF);
        assertEq(composer.RECOVERY_ADDRESS(), recovery);
        assertEq(composer.NATIVE_ASSET_BRIDGE(), HYPE_ASSET_BRIDGE);
        assertEq(composer.NATIVE_CORE_INDEX_ID(), 150); // mainnet HYPE index
        assertEq(composer.NATIVE_DECIMAL_DIFF(), 10); // HYPE decimal diff
    }

    function test_deployment_revertsZeroOFT() public {
        vm.expectRevert(IHyperLiquidComposer.InvalidOFTAddress.selector);
        new UpHyperLiquidComposer(address(0), CORE_INDEX_ID, DECIMAL_DIFF, recovery);
    }

    function test_deployment_revertsZeroRecoveryAddress() public {
        vm.expectRevert(IRecoverableComposer.InvalidRecoveryAddress.selector);
        new UpHyperLiquidComposer(address(oft), CORE_INDEX_ID, DECIMAL_DIFF, address(0));
    }

    function test_deployment_revertsInvalidDecimalDiff_tooLow() public {
        vm.expectRevert(
            abi.encodeWithSelector(IHyperLiquidComposer.InvalidDecimalDiff.selector, int8(-3), int8(-2), int8(18))
        );
        new UpHyperLiquidComposer(address(oft), CORE_INDEX_ID, -3, recovery);
    }

    function test_deployment_revertsInvalidDecimalDiff_tooHigh() public {
        vm.expectRevert(
            abi.encodeWithSelector(IHyperLiquidComposer.InvalidDecimalDiff.selector, int8(19), int8(-2), int8(18))
        );
        new UpHyperLiquidComposer(address(oft), CORE_INDEX_ID, 19, recovery);
    }

    // ==================== lzCompose — Success Paths ====================

    function test_lzCompose_transferERC20ToHyperCore() public {
        uint256 amount = 1 ether;

        // Mint tokens to composer (simulates OFT lzReceive)
        oft.mint(address(composer), amount);

        // Build compose message: minMsgValue=0, receiver=userB
        bytes memory composeMsg = abi.encode(uint256(0), userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        // Expect ERC20 transfer to asset bridge
        uint256 expectedEvmAmount = amount - (amount % SCALE);
        vm.expectEmit(address(oft));
        emit IERC20.Transfer(address(composer), erc20AssetBridge, expectedEvmAmount);

        vm.prank(endpoint);
        composer.lzCompose(address(oft), bytes32(uint256(1)), composerMsg, address(0), "");

        // Composer should have no remaining token balance (all sent to bridge)
        assertEq(oft.balanceOf(address(composer)), amount - expectedEvmAmount);
    }

    function test_lzCompose_transferERC20AndHYPE() public {
        uint256 amount = 1 ether;
        uint256 nativeAmount = 0.001 ether;

        oft.mint(address(composer), amount);

        // Build compose message: minMsgValue=nativeAmount, receiver=userB
        bytes memory composeMsg = abi.encode(nativeAmount, userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        uint256 bridgeBalanceBefore = HYPE_ASSET_BRIDGE.balance;

        vm.prank(endpoint);
        composer.lzCompose{ value: nativeAmount }(address(oft), bytes32(uint256(2)), composerMsg, address(0), "");

        // ERC20 sent to asset bridge
        uint256 expectedEvmAmount = amount - (amount % SCALE);
        assertEq(oft.balanceOf(address(composer)), amount - expectedEvmAmount);

        // HYPE sent to HYPE asset bridge
        uint256 expectedHypeEvm = nativeAmount - (nativeAmount % SCALE);
        assertEq(HYPE_ASSET_BRIDGE.balance, bridgeBalanceBefore + expectedHypeEvm);
    }

    // ==================== lzCompose — Revert Paths ====================

    function test_lzCompose_revertsNotEndpoint() public {
        vm.expectRevert(IHyperLiquidComposer.OnlyEndpoint.selector);
        composer.lzCompose(address(oft), bytes32(0), "", address(0), "");
    }

    function test_lzCompose_revertsWrongOFT() public {
        vm.expectRevert(
            abi.encodeWithSelector(IHyperLiquidComposer.InvalidComposeCaller.selector, address(oft), address(0))
        );
        vm.prank(endpoint);
        composer.lzCompose(address(0), bytes32(0), "", address(0), "");
    }

    function test_lzCompose_revertsInsufficientGas() public {
        oft.mint(address(composer), 1 ether);

        bytes memory composeMsg = abi.encode(uint256(0), userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, 1 ether, abi.encodePacked(_toBytes32(userA), composeMsg));

        vm.expectRevert();
        vm.prank(endpoint);
        composer.lzCompose{ gas: 150_000 }(address(oft), bytes32(0), composerMsg, address(0), "");
    }

    function test_lzCompose_revertsInsufficientMsgValue() public {
        uint256 amount = 1 ether;
        uint256 requiredValue = 0.01 ether;

        oft.mint(address(composer), amount);

        // Build compose message requiring 0.01 ether but send only 0.001 ether
        bytes memory composeMsg = abi.encode(requiredValue, userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        vm.expectRevert(
            abi.encodeWithSelector(IHyperLiquidComposer.InsufficientMsgValue.selector, 0.001 ether, requiredValue)
        );
        vm.prank(endpoint);
        composer.lzCompose{ value: 0.001 ether }(address(oft), bytes32(uint256(3)), composerMsg, address(0), "");
    }

    // ==================== lzCompose — Refund Paths ====================

    function test_lzCompose_refundToHyperEvm_userNotActivated() public {
        uint256 amount = 1 ether;
        uint256 nativeAmount = 0.001 ether;
        address unactivatedUser = makeAddr("unactivated");
        CoreUserExistsMock(CORE_USER_EXISTS_PRECOMPILE).setUserExists(unactivatedUser, false);

        oft.mint(address(composer), amount);

        bytes memory composeMsg = abi.encode(nativeAmount, unactivatedUser);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        // Expect ERC20 refund to unactivated user
        vm.expectEmit(address(oft));
        emit IERC20.Transfer(address(composer), unactivatedUser, amount);

        vm.prank(endpoint);
        composer.lzCompose{ value: nativeAmount }(address(oft), bytes32(uint256(4)), composerMsg, address(0), "");

        // Unactivated user receives both ERC20 and native on HyperEVM
        assertEq(oft.balanceOf(unactivatedUser), amount);
        assertEq(unactivatedUser.balance, nativeAmount);
        assertEq(oft.balanceOf(address(composer)), 0);
        assertEq(address(composer).balance, 0);
    }

    function test_lzCompose_failedMessageStored_malformedPayload() public {
        uint256 amount = 1 ether;

        oft.mint(address(composer), amount);

        // Send a compose message with wrong length (not 64 bytes)
        bytes memory composeMsg = abi.encode(uint256(0), userB, uint256(999)); // 96 bytes instead of 64
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        bytes32 guid = bytes32(uint256(5));

        vm.prank(endpoint);
        composer.lzCompose(address(oft), guid, composerMsg, address(0), "");

        // Check failed message stored
        (SendParam memory refundParam, uint256 msgValue) = composer.failedMessages(guid);
        assertEq(refundParam.to, _toBytes32(userA));
        assertEq(refundParam.amountLD, amount);
        assertEq(msgValue, 0);
    }

    function test_lzCompose_failedMessageStored_wrongLength() public {
        uint256 amount = 1 ether;
        uint256 nativeAmount = 0.001 ether;

        oft.mint(address(composer), amount);

        // 32 bytes instead of 64 — triggers decode failure
        bytes memory composeMsg = abi.encode(userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        bytes32 guid = bytes32(uint256(6));

        vm.prank(endpoint);
        composer.lzCompose{ value: nativeAmount }(address(oft), guid, composerMsg, address(0), "");

        (SendParam memory refundParam, uint256 msgValue) = composer.failedMessages(guid);
        assertEq(refundParam.to, _toBytes32(userA));
        assertEq(refundParam.amountLD, amount);
        assertEq(msgValue, nativeAmount);
    }

    // ==================== decodeMessage ====================

    function test_decodeMessage_valid() public view {
        uint256 expectedMinMsgValue = 0.01 ether;
        address expectedReceiver = userB;

        bytes memory composeMsg = abi.encode(expectedMinMsgValue, expectedReceiver);
        (uint256 minMsgValue, address to) = composer.decodeMessage(composeMsg);

        assertEq(minMsgValue, expectedMinMsgValue);
        assertEq(to, expectedReceiver);
    }

    function test_decodeMessage_revertsInvalidLength() public {
        bytes memory shortMsg = abi.encode(uint256(0)); // 32 bytes
        vm.expectRevert(abi.encodeWithSelector(IHyperLiquidComposer.ComposeMsgLengthNot64Bytes.selector, 32));
        composer.decodeMessage(shortMsg);
    }

    // ==================== handleTransfersToHyperCore ====================

    function test_handleTransfersToHyperCore_revertsNotSelf() public {
        vm.expectRevert(abi.encodeWithSelector(IHyperLiquidComposer.OnlySelf.selector, address(this)));
        composer.handleTransfersToHyperCore(userB, 1 ether);
    }

    // ==================== quoteHyperCoreAmount ====================

    function test_quoteHyperCoreAmount_correctConversion() public view {
        uint256 amount = 1 ether; // 1e18

        IHyperAssetAmount memory result =
            composer.quoteHyperCoreAmount(CORE_INDEX_ID, DECIMAL_DIFF, erc20AssetBridge, amount);

        // With decimalDiff=10: core = 1e18 / 1e10 = 1e8
        assertEq(result.evm, amount);
        assertEq(result.core, uint64(amount / SCALE));
        assertEq(result.coreBalanceAssetBridge, type(uint64).max);
    }

    function test_quoteHyperCoreAmount_revertsExceedsBridgeBalance() public {
        // Set a low bridge balance
        SpotBalancePrecompileMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(erc20AssetBridge, CORE_INDEX_ID, 100);

        // 100 core units = 100 * 1e10 = 1e12 evm units max
        // Try to send more than that
        uint256 tooMuch = 1e13; // 10x the bridge balance

        vm.expectRevert();
        composer.quoteHyperCoreAmount(CORE_INDEX_ID, DECIMAL_DIFF, erc20AssetBridge, tooMuch);
    }

    // ==================== refundToSrc ====================

    function test_refundToSrc_success() public {
        uint256 amount = 1 ether;

        // First, create a failed message by sending a malformed compose
        oft.mint(address(composer), amount);

        bytes memory composeMsg = abi.encode(uint256(0), userB, uint256(999)); // wrong length
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, 30101, amount, abi.encodePacked(_toBytes32(userA), composeMsg));
        bytes32 guid = bytes32(uint256(10));

        vm.prank(endpoint);
        composer.lzCompose(address(oft), guid, composerMsg, address(0), "");

        // Verify failed message exists
        (SendParam memory refundParam,) = composer.failedMessages(guid);
        assertEq(refundParam.amountLD, amount);

        // Approve composer to spend tokens for refund
        vm.prank(address(composer));
        oft.approve(address(oft), amount);

        // Call refundToSrc — the mock OFT.send() will burn the tokens
        vm.expectEmit(address(composer));
        emit IHyperLiquidComposer.RefundSuccessful(guid);

        composer.refundToSrc(guid);

        // Verify failed message deleted
        (SendParam memory deletedParam,) = composer.failedMessages(guid);
        assertEq(deletedParam.dstEid, 0);

        // Verify OFT.send was called
        assertTrue(oft.sendCalled());
    }

    function test_refundToSrc_revertsMessageNotFound() public {
        bytes32 nonExistentGuid = bytes32(uint256(999));
        vm.expectRevert(abi.encodeWithSelector(IHyperLiquidComposer.FailedMessageNotFound.selector, nonExistentGuid));
        composer.refundToSrc(nonExistentGuid);
    }

    // ==================== Recovery Functions ====================

    function test_recoverEvmERC20_partialAmount() public {
        uint256 amount = 10 ether;
        uint256 recoverAmount = 3 ether;

        oft.mint(address(composer), amount);

        vm.expectEmit(address(composer));
        emit IRecoverableComposer.Recovered(recovery, recoverAmount);

        vm.prank(recovery);
        composer.recoverEvmERC20(recoverAmount);

        assertEq(oft.balanceOf(recovery), recoverAmount);
        assertEq(oft.balanceOf(address(composer)), amount - recoverAmount);
    }

    function test_recoverEvmERC20_fullTransfer() public {
        uint256 amount = 10 ether;

        oft.mint(address(composer), amount);

        vm.expectEmit(address(composer));
        emit IRecoverableComposer.Recovered(recovery, amount);

        vm.prank(recovery);
        composer.recoverEvmERC20(0); // FULL_TRANSFER = 0

        assertEq(oft.balanceOf(recovery), amount);
        assertEq(oft.balanceOf(address(composer)), 0);
    }

    function test_recoverEvmERC20_revertsNotRecoveryAddress() public {
        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.recoverEvmERC20(1 ether);
    }

    function test_recoverEvmNative_partialAmount() public {
        uint256 amount = 10 ether;
        uint256 recoverAmount = 3 ether;

        vm.deal(address(composer), amount);

        vm.expectEmit(address(composer));
        emit IRecoverableComposer.Recovered(recovery, recoverAmount);

        vm.prank(recovery);
        composer.recoverEvmNative(recoverAmount);

        assertEq(recovery.balance, recoverAmount);
        assertEq(address(composer).balance, amount - recoverAmount);
    }

    function test_recoverEvmNative_fullTransfer() public {
        uint256 amount = 10 ether;

        vm.deal(address(composer), amount);

        vm.expectEmit(address(composer));
        emit IRecoverableComposer.Recovered(recovery, amount);

        vm.prank(recovery);
        composer.recoverEvmNative(0); // FULL_TRANSFER = 0

        assertEq(recovery.balance, amount);
        assertEq(address(composer).balance, 0);
    }

    function test_recoverEvmNative_revertsNotRecoveryAddress() public {
        vm.deal(address(composer), 1 ether);
        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.recoverEvmNative(1 ether);
    }

    function test_retrieveCoreERC20_success() public {
        uint64 coreAmount = 1000;

        // Set composer's core balance
        SpotBalancePrecompileMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(
            address(composer), CORE_INDEX_ID, coreAmount
        );

        vm.expectEmit(address(composer));
        emit IRecoverableComposer.Retrieved(CORE_INDEX_ID, coreAmount, erc20AssetBridge);

        vm.prank(recovery);
        composer.retrieveCoreERC20(coreAmount);
    }

    function test_retrieveCoreERC20_revertsNotRecoveryAddress() public {
        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.retrieveCoreERC20(100);
    }

    function test_retrieveCoreERC20_revertsExceedsMax() public {
        uint64 balance = 100;
        uint64 requested = 200;

        SpotBalancePrecompileMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(
            address(composer), CORE_INDEX_ID, balance
        );

        vm.expectRevert(
            abi.encodeWithSelector(IRecoverableComposer.MaxRetrieveAmountExceeded.selector, balance, requested)
        );
        vm.prank(recovery);
        composer.retrieveCoreERC20(requested);
    }

    function test_retrieveCoreHYPE_success() public {
        uint64 coreAmount = 500;

        // Set composer's HYPE core balance (mainnet index = 150)
        SpotBalancePrecompileMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(address(composer), 150, coreAmount);

        vm.expectEmit(address(composer));
        emit IRecoverableComposer.Retrieved(150, coreAmount, HYPE_ASSET_BRIDGE);

        vm.prank(recovery);
        composer.retrieveCoreHYPE(coreAmount);
    }

    function test_retrieveCoreHYPE_revertsNotRecoveryAddress() public {
        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.retrieveCoreHYPE(100);
    }

    // ==================== Constants ====================

    function test_constants() public {
        assertEq(composer.VALID_COMPOSE_MSG_LEN(), 64);
        assertEq(composer.MIN_GAS(), 150_000);
        assertEq(composer.MIN_GAS_WITH_VALUE(), 200_000);
        assertEq(composer.FULL_TRANSFER(), 0);
        assertEq(composer.USDC_CORE_INDEX(), 0);
    }

    // ==================== Receive ====================

    function test_receive_acceptsNative() public {
        vm.deal(address(this), 1 ether);
        (bool success,) = payable(address(composer)).call{ value: 1 ether }("");
        assertTrue(success);
        assertEq(address(composer).balance, 1 ether);
    }

    // ==================== Helpers ====================

    function _toBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
