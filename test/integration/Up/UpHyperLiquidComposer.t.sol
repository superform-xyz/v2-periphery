// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { OFTComposeMsgCodec } from "@layerzerolabs/oft-evm/contracts/libs/OFTComposeMsgCodec.sol";
import { IOFT, SendParam } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

import { UpHyperLiquidComposer } from "../../../src/UP/UpHyperLiquidComposer.sol";

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

// ============ Precompile Mocks (etched onto real precompile addresses) ============

contract SpotBalanceMock {
    mapping(address => mapping(uint64 => SpotBalance)) private _balances;

    function setSpotBalance(address user, uint64 tokenId, uint64 balance) external {
        _balances[user][tokenId] = SpotBalance({ total: balance, hold: 0, entryNtl: 0 });
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        (address user, uint64 tokenId) = abi.decode(data, (address, uint64));
        return abi.encode(_balances[user][tokenId]);
    }
}

contract CoreUserMock {
    mapping(address => bool) private _exists;

    function setUserExists(address user, bool exists) external {
        _exists[user] = exists;
    }

    fallback(bytes calldata data) external returns (bytes memory) {
        address user = abi.decode(data, (address));
        return abi.encode(_exists[user]);
    }
}

/**
 * @title UpHyperLiquidComposer Integration Tests
 * @notice Forks HyperEVM mainnet and uses real deployed UP OFT + LZ Endpoint addresses.
 *         Precompiles (SpotBalance, CoreUserExists) are mocked via vm.etch since they are
 *         HyperCore L1 precompiles that don't work on EVM forks.
 */
contract UpHyperLiquidComposerIntegrationTest is Test {
    // ==================== Real Deployed Addresses ====================

    /// @dev UP OFT on HyperEVM — from script/output/prod/999/UpOFT-latest.json
    address constant UP_OFT_HYPEREVM = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

    /// @dev LayerZero Endpoint V2 on HyperEVM mainnet
    address constant LZ_ENDPOINT_HYPEREVM = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;

    /// @dev MPC wallet for recovery — from DeployUpComposer.s.sol
    address constant MPC_WALLET = 0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153;

    // ==================== HyperLiquid Precompile Addresses ====================

    address constant SPOT_BALANCE_PRECOMPILE = 0x0000000000000000000000000000000000000801;
    address constant CORE_USER_EXISTS_PRECOMPILE = 0x0000000000000000000000000000000000000810;
    address constant HYPE_ASSET_BRIDGE = 0x2222222222222222222222222222222222222222;
    address constant CORE_WRITER = 0x3333333333333333333333333333333333333333;

    // ==================== Test Configuration ====================

    /// @dev Using test values for CORE_INDEX_ID and DECIMAL_DIFF since Step 3 (HIP-1 listing) is pending.
    ///      These match the HYPE pattern: 18 EVM decimals - 8 Core decimals = 10.
    uint64 constant CORE_INDEX_ID = 42;
    int8 constant DECIMAL_DIFF = 10;
    uint256 constant SCALE = 10 ** 10;

    uint32 constant ETH_EID = 30101;
    uint32 constant HYPEREVM_EID = 30367;

    // ==================== State ====================

    UpHyperLiquidComposer public composer;
    IOFT public upOft;
    address public erc20AssetBridge;

    address public userA;
    address public userB;

    function setUp() public {
        // Fork HyperEVM mainnet
        string memory rpcUrl;
        try vm.envString("HYPEREVM_RPC_URL") returns (string memory _rpcUrl) {
            rpcUrl = _rpcUrl;
        } catch {
            rpcUrl = "https://rpc.hyperliquid.xyz/evm";
        }

        try vm.createSelectFork(rpcUrl) {} catch {
            console2.log("HyperEVM fork failed for:", rpcUrl);
            vm.skip(true);
        }

        // Verify we're on HyperEVM
        assertEq(block.chainid, 999, "Must be on HyperEVM mainnet fork");

        // Verify real UP OFT is deployed
        assertTrue(UP_OFT_HYPEREVM.code.length > 0, "UP OFT not deployed on HyperEVM");

        upOft = IOFT(UP_OFT_HYPEREVM);

        // Etch mock precompiles (real L1 precompiles don't work on EVM forks)
        vm.etch(SPOT_BALANCE_PRECOMPILE, address(new SpotBalanceMock()).code);
        vm.etch(CORE_USER_EXISTS_PRECOMPILE, address(new CoreUserMock()).code);

        // Deploy UpHyperLiquidComposer using the REAL UP OFT address
        composer = new UpHyperLiquidComposer(UP_OFT_HYPEREVM, CORE_INDEX_ID, DECIMAL_DIFF, MPC_WALLET);

        erc20AssetBridge = HyperLiquidComposerCodec.into_assetBridgeAddress(CORE_INDEX_ID);

        // Set max bridge balances for both ERC20 and HYPE
        SpotBalanceMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(erc20AssetBridge, CORE_INDEX_ID, type(uint64).max);
        SpotBalanceMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(HYPE_ASSET_BRIDGE, 150, type(uint64).max);

        // Set up test users (activated on HyperCore)
        userA = makeAddr("userA");
        userB = makeAddr("userB");
        CoreUserMock(CORE_USER_EXISTS_PRECOMPILE).setUserExists(userA, true);
        CoreUserMock(CORE_USER_EXISTS_PRECOMPILE).setUserExists(userB, true);

        // Fund the LZ endpoint for msg.value tests
        vm.deal(LZ_ENDPOINT_HYPEREVM, 100 ether);
    }

    // ==================== Deployment Validation ====================

    function test_deployment_usesRealOFT() public view {
        assertEq(composer.OFT(), UP_OFT_HYPEREVM, "OFT should be real UP OFT");
        assertEq(composer.ENDPOINT(), LZ_ENDPOINT_HYPEREVM, "Endpoint should be real LZ endpoint");
        assertEq(composer.ERC20(), upOft.token(), "ERC20 should match OFT.token()");
        assertEq(composer.RECOVERY_ADDRESS(), MPC_WALLET, "Recovery should be MPC wallet");
        assertEq(composer.ERC20_CORE_INDEX_ID(), CORE_INDEX_ID);
        assertEq(composer.ERC20_DECIMAL_DIFF(), DECIMAL_DIFF);
        assertEq(composer.NATIVE_CORE_INDEX_ID(), 150, "HYPE core index on mainnet");
        assertEq(composer.NATIVE_DECIMAL_DIFF(), 10, "HYPE decimal diff");
    }

    // ==================== Full Compose Flow: ERC20 Only ====================

    function test_fullComposeFlow_ERC20Only() public {
        uint256 amount = 1 ether;

        // Simulate OFT lzReceive minting tokens to composer
        address upToken = upOft.token();
        deal(upToken, address(composer), amount);
        assertEq(IERC20(upToken).balanceOf(address(composer)), amount);

        // Build compose message: minMsgValue=0, receiver=userB
        bytes memory composeMsg = abi.encode(uint256(0), userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, ETH_EID, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        // Expected: full amount transferred (1 ether is evenly divisible by SCALE)
        uint256 expectedEvmAmount = amount - (amount % SCALE);
        assertEq(expectedEvmAmount, amount, "1 ether should have no dust with decimalDiff=10");

        // Expect ERC20 Transfer event to asset bridge
        vm.expectEmit(upToken);
        emit IERC20.Transfer(address(composer), erc20AssetBridge, expectedEvmAmount);

        // Expect CoreWriter called
        uint64 expectedCoreAmount = uint64(expectedEvmAmount / SCALE);
        bytes memory expectedAction = abi.encode(userB, CORE_INDEX_ID, expectedCoreAmount);
        bytes memory expectedPayload = abi.encodePacked(composer.SPOT_SEND_HEADER(), expectedAction);
        vm.expectEmit(CORE_WRITER);
        emit ICoreWriter.RawAction(address(composer), expectedPayload);

        // Execute: LZ Endpoint calls lzCompose
        vm.prank(LZ_ENDPOINT_HYPEREVM);
        composer.lzCompose(UP_OFT_HYPEREVM, bytes32(uint256(1)), composerMsg, address(0), "");

        // Verify: tokens moved from composer to asset bridge
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0);
        assertEq(IERC20(upToken).balanceOf(erc20AssetBridge), expectedEvmAmount);
    }

    // ==================== Full Compose Flow: ERC20 + HYPE ====================

    function test_fullComposeFlow_ERC20AndHYPE() public {
        uint256 erc20Amount = 2 ether;
        uint256 hypeAmount = 0.01 ether;
        address upToken = upOft.token();

        deal(upToken, address(composer), erc20Amount);

        bytes memory composeMsg = abi.encode(hypeAmount, userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, ETH_EID, erc20Amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        uint256 bridgeBalBefore = HYPE_ASSET_BRIDGE.balance;

        vm.prank(LZ_ENDPOINT_HYPEREVM);
        composer.lzCompose{ value: hypeAmount }(UP_OFT_HYPEREVM, bytes32(uint256(2)), composerMsg, address(0), "");

        // ERC20 fully transferred to bridge
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0);

        // HYPE transferred to HYPE bridge (dust stripped)
        uint256 expectedHypeEvm = hypeAmount - (hypeAmount % SCALE);
        assertEq(HYPE_ASSET_BRIDGE.balance, bridgeBalBefore + expectedHypeEvm);

        // No leftover native in composer
        assertEq(address(composer).balance, 0);
    }

    // ==================== Failed Message → Refund Lifecycle ====================

    function test_failedMessageThenRefund() public {
        uint256 amount = 3 ether;
        bytes32 guid = bytes32(uint256(100));
        address upToken = upOft.token();

        deal(upToken, address(composer), amount);

        // Malformed compose msg (96 bytes, not 64) → triggers failed message storage
        bytes memory badComposeMsg = abi.encode(uint256(0), userB, uint256(0));
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, ETH_EID, amount, abi.encodePacked(_toBytes32(userA), badComposeMsg));

        vm.prank(LZ_ENDPOINT_HYPEREVM);
        composer.lzCompose(UP_OFT_HYPEREVM, guid, composerMsg, address(0), "");

        // Verify failed message stored with correct refund params
        (SendParam memory refundParam, uint256 msgValue) = composer.failedMessages(guid);
        assertEq(refundParam.dstEid, ETH_EID);
        assertEq(refundParam.to, _toBytes32(userA));
        assertEq(refundParam.amountLD, amount);
        assertEq(msgValue, 0);

        // Tokens still held by composer
        assertEq(IERC20(upToken).balanceOf(address(composer)), amount);
    }

    // ==================== Refund → Recovery Lifecycle ====================

    function test_refundToHyperEvmThenRecover() public {
        uint256 amount = 4 ether;
        uint256 nativeAmount = 0.05 ether;
        address upToken = upOft.token();
        address unactivated = makeAddr("unactivated");
        CoreUserMock(CORE_USER_EXISTS_PRECOMPILE).setUserExists(unactivated, false);

        deal(upToken, address(composer), amount);

        // lzCompose with unactivated user → refund to HyperEVM
        bytes memory composeMsg = abi.encode(nativeAmount, unactivated);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, ETH_EID, amount, abi.encodePacked(_toBytes32(userA), composeMsg));

        vm.prank(LZ_ENDPOINT_HYPEREVM);
        composer.lzCompose{ value: nativeAmount }(UP_OFT_HYPEREVM, bytes32(uint256(3)), composerMsg, address(0), "");

        // Unactivated user gets both ERC20 and native refunded on HyperEVM
        assertEq(IERC20(upToken).balanceOf(unactivated), amount);
        assertEq(unactivated.balance, nativeAmount);

        // Composer is empty
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0);
        assertEq(address(composer).balance, 0);

        // Recovery scenario: tokens get stuck in composer from another operation
        deal(upToken, address(composer), 2 ether);
        vm.deal(address(composer), 0.5 ether);

        // MPC wallet recovers ERC20
        vm.prank(MPC_WALLET);
        composer.recoverEvmERC20(0); // FULL_TRANSFER
        assertEq(IERC20(upToken).balanceOf(MPC_WALLET), 2 ether);

        // MPC wallet recovers native
        vm.prank(MPC_WALLET);
        composer.recoverEvmNative(0); // FULL_TRANSFER
        assertEq(MPC_WALLET.balance, 0.5 ether);
    }

    // ==================== Recovery Integration: ERC20 ====================

    function test_recoveryWorkflow_ERC20() public {
        address upToken = upOft.token();
        uint256 stuckAmount = 10 ether;

        deal(upToken, address(composer), stuckAmount);

        // Set composer's core balance (simulates tokens bridged to core)
        uint64 coreBalance = 5000;
        SpotBalanceMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(address(composer), CORE_INDEX_ID, coreBalance);

        // Step 1: MPC retrieves from HyperCore → asset bridge
        vm.prank(MPC_WALLET);
        composer.retrieveCoreERC20(coreBalance);

        // Step 2: MPC recovers ERC20 from HyperEVM
        vm.prank(MPC_WALLET);
        composer.recoverEvmERC20(stuckAmount);

        assertEq(IERC20(upToken).balanceOf(MPC_WALLET), stuckAmount);
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0);
    }

    // ==================== Recovery Integration: Native ====================

    function test_recoveryWorkflow_native() public {
        vm.deal(address(composer), 5 ether);

        // Set composer's HYPE core balance
        uint64 hypeCoreBalance = 3000;
        SpotBalanceMock(SPOT_BALANCE_PRECOMPILE).setSpotBalance(address(composer), 150, hypeCoreBalance);

        // Step 1: MPC retrieves HYPE from core
        vm.prank(MPC_WALLET);
        composer.retrieveCoreHYPE(hypeCoreBalance);

        // Step 2: MPC recovers native from HyperEVM
        vm.prank(MPC_WALLET);
        composer.recoverEvmNative(0); // FULL_TRANSFER

        assertEq(MPC_WALLET.balance, 5 ether);
        assertEq(address(composer).balance, 0);
    }

    // ==================== Access Control with Real MPC ====================

    function test_recovery_onlyMPCWallet() public {
        address upToken = upOft.token();
        deal(upToken, address(composer), 1 ether);
        vm.deal(address(composer), 1 ether);

        address attacker = makeAddr("attacker");

        // Attacker cannot recover ERC20
        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.recoverEvmERC20(1 ether);

        // Attacker cannot recover native
        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.recoverEvmNative(1 ether);

        // Attacker cannot retrieve from HyperCore
        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.retrieveCoreERC20(100);

        vm.expectRevert(IRecoverableComposer.NotRecoveryAddress.selector);
        vm.prank(attacker);
        composer.retrieveCoreHYPE(100);

        // Funds are untouched after attacker attempts
        assertEq(IERC20(upToken).balanceOf(address(composer)), 1 ether);
        assertEq(address(composer).balance, 1 ether);

        // MPC wallet (authorized recovery address) CAN recover ERC20
        uint256 mpcErc20Before = IERC20(upToken).balanceOf(MPC_WALLET);
        vm.prank(MPC_WALLET);
        composer.recoverEvmERC20(0); // FULL_TRANSFER
        assertEq(IERC20(upToken).balanceOf(MPC_WALLET), mpcErc20Before + 1 ether);
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0);

        // MPC wallet CAN recover native
        uint256 mpcNativeBefore = MPC_WALLET.balance;
        vm.prank(MPC_WALLET);
        composer.recoverEvmNative(0); // FULL_TRANSFER
        assertEq(MPC_WALLET.balance, mpcNativeBefore + 1 ether);
        assertEq(address(composer).balance, 0);
    }

    // ==================== E2E: Source Chain → OFT Bridge → HyperCore Spot Trading ====================

    /// @notice Full end-to-end test simulating the complete user journey:
    ///         Source Chain OFT.send(composeMsg) → HyperEVM OFT lzReceive → lzCompose →
    ///         UpHyperLiquidComposer → Asset Bridge (0x2000...) → CoreWriter spotSend → HyperCore Spot Trading
    ///
    /// @dev Without the Composer, users can only bridge to HyperEVM (ERC20 on the EVM side).
    ///      The Composer enables bridging directly into HyperCore spot trading in a single
    ///      cross-chain transaction by forwarding tokens to the native asset bridge.
    function test_e2e_sourceChainToHyperCoreSpotTrading() public {
        address upToken = upOft.token();
        uint256 bridgeAmount = 5 ether; // 5 UP tokens bridged from source chain
        uint256 hypeForTrading = 0.01 ether; // HYPE to deposit for gas/trading

        // ============ Step 1: Source Chain — User prepares bridge + compose ============
        // On the source chain (e.g., Base/Ethereum), the user calls OFT.send() with:
        //   - dstEid: HyperEVM endpoint ID
        //   - to: bytes32(composerAddress) — tokens go to the composer, not the user
        //   - composeMsg: abi.encode(minMsgValue, receiver) — 64-byte instruction for HyperCore
        //
        // The compose message tells the Composer:
        //   - minMsgValue: HYPE to deposit alongside the ERC20 (for trading/gas on HyperCore)
        //   - receiver: the HyperCore address that should receive the spot balance

        bytes memory composeMsg = abi.encode(hypeForTrading, userB);
        assertEq(composeMsg.length, 64, "Compose message must be exactly 64 bytes");

        // ============ Step 2: HyperEVM — OFT.lzReceive mints tokens to Composer ============
        // LayerZero delivers the message on HyperEVM. The OFT's lzReceive callback:
        //   1. Mints `bridgeAmount` UP tokens to the Composer address (the `to` field)
        //   2. Triggers the Endpoint to call lzCompose() with the compose message

        deal(upToken, address(composer), bridgeAmount);

        // Snapshot balances before compose execution
        uint256 bridgeErc20Before = IERC20(upToken).balanceOf(erc20AssetBridge);
        uint256 bridgeHypeBefore = HYPE_ASSET_BRIDGE.balance;

        // ============ Step 3: HyperEVM — Endpoint calls lzCompose() on Composer ============
        // The LZ Endpoint builds the full OFTComposeMsgCodec-encoded message and calls:
        //   composer.lzCompose{value: hypeForTrading}(oftAddress, guid, message, ...)
        //
        // Inside lzCompose(), the Composer:
        //   a) Validates caller is the Endpoint, OFT address matches
        //   b) Decodes composeMsg: extracts minMsgValue and receiver
        //   c) Checks receiver is activated on HyperCore (coreUserExists precompile)
        //   d) Transfers UP tokens to asset bridge: 0x2000...+coreIndexId
        //      (depositing them into HyperCore spot trading)
        //   e) Calls CoreWriter.spotSend to credit receiver's HyperCore balance
        //   f) Transfers HYPE to HYPE asset bridge (0x2222...)
        //   g) Calls CoreWriter.spotSend for HYPE credit

        bytes32 guid = keccak256("e2e-source-to-hypercore");

        // Expected amounts after decimal conversion (EVM 18 decimals to Core 8 decimals)
        uint256 expectedErc20Evm = bridgeAmount - (bridgeAmount % SCALE);
        uint256 expectedHypeEvm = hypeForTrading - (hypeForTrading % SCALE);

        // Set up expected events for the compose execution
        {
            uint64 erc20Core = uint64(expectedErc20Evm / SCALE);
            uint64 hypeCore = uint64(expectedHypeEvm / SCALE);

            // Event: UP tokens transferred to asset bridge
            vm.expectEmit(upToken);
            emit IERC20.Transfer(address(composer), erc20AssetBridge, expectedErc20Evm);

            // Event: CoreWriter spotSend for UP (receiver gets credited on HyperCore)
            vm.expectEmit(CORE_WRITER);
            emit ICoreWriter.RawAction(
                address(composer),
                abi.encodePacked(composer.SPOT_SEND_HEADER(), abi.encode(userB, CORE_INDEX_ID, erc20Core))
            );

            // Event: CoreWriter spotSend for HYPE
            vm.expectEmit(CORE_WRITER);
            emit ICoreWriter.RawAction(
                address(composer),
                abi.encodePacked(composer.SPOT_SEND_HEADER(), abi.encode(userB, uint64(150), hypeCore))
            );
        }

        // Execute: Endpoint delivers the composed message
        vm.prank(LZ_ENDPOINT_HYPEREVM);
        composer.lzCompose{ value: hypeForTrading }(
            UP_OFT_HYPEREVM,
            guid,
            OFTComposeMsgCodec.encode(1, ETH_EID, bridgeAmount, abi.encodePacked(_toBytes32(userA), composeMsg)),
            address(0),
            ""
        );

        // ============ Step 4: Verify — Tokens are now in HyperCore Spot Trading ============
        // The Composer is a pass-through: it holds zero tokens after execution.
        // All assets have been deposited to the native bridge addresses, putting them
        // directly into HyperCore spot trading for the receiver.

        // UP tokens deposited to asset bridge (enters HyperCore spot trading)
        assertEq(IERC20(upToken).balanceOf(erc20AssetBridge), bridgeErc20Before + expectedErc20Evm);

        // HYPE deposited to HYPE bridge (available on HyperCore for trading/gas)
        assertEq(HYPE_ASSET_BRIDGE.balance, bridgeHypeBefore + expectedHypeEvm);

        // Composer is a pass-through — holds no residual tokens
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0);
        assertEq(address(composer).balance, 0);

        // No failed message stored — clean compose execution
        (SendParam memory failedParam,) = composer.failedMessages(guid);
        assertEq(failedParam.dstEid, 0);
    }

    /// @notice E2E test: Unactivated user → refund to HyperEVM → MPC recovery
    /// @dev Demonstrates the safety net when a receiver hasn't activated on HyperCore.
    ///      Instead of losing tokens, they're refunded on HyperEVM. If the user still
    ///      can't access them, MPC (recovery address) can retrieve on their behalf.
    function test_e2e_unactivatedUserRefundAndRecovery() public {
        address upToken = upOft.token();
        address unactivatedReceiver = makeAddr("newUser");
        CoreUserMock(CORE_USER_EXISTS_PRECOMPILE).setUserExists(unactivatedReceiver, false);

        uint256 bridgeAmount = 3 ether;
        uint256 hypeAmount = 0.02 ether;

        // Step 1: Tokens arrive at Composer but receiver isn't on HyperCore
        deal(upToken, address(composer), bridgeAmount);

        bytes memory composeMsg = abi.encode(hypeAmount, unactivatedReceiver);
        bytes memory fullMessage = OFTComposeMsgCodec.encode(
            1, ETH_EID, bridgeAmount, abi.encodePacked(_toBytes32(userA), composeMsg)
        );

        vm.prank(LZ_ENDPOINT_HYPEREVM);
        composer.lzCompose{ value: hypeAmount }(
            UP_OFT_HYPEREVM, bytes32(uint256(50)), fullMessage, address(0), ""
        );

        // Step 2: Tokens refunded to unactivated user on HyperEVM (not lost!)
        assertEq(IERC20(upToken).balanceOf(unactivatedReceiver), bridgeAmount, "ERC20 refunded on HyperEVM");
        assertEq(unactivatedReceiver.balance, hypeAmount, "HYPE refunded on HyperEVM");
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0, "Composer empty after refund");

        // Step 3: Simulate scenario where tokens get stuck in composer (e.g., from a different failure path)
        deal(upToken, address(composer), 1 ether);
        vm.deal(address(composer), 0.5 ether);

        // Step 4: MPC wallet performs emergency recovery
        vm.prank(MPC_WALLET);
        composer.recoverEvmERC20(0); // FULL_TRANSFER

        vm.prank(MPC_WALLET);
        composer.recoverEvmNative(0); // FULL_TRANSFER

        // Step 5: MPC has recovered all stuck funds
        assertGt(IERC20(upToken).balanceOf(MPC_WALLET), 0, "MPC recovered ERC20");
        assertGt(MPC_WALLET.balance, 0, "MPC recovered HYPE");
        assertEq(IERC20(upToken).balanceOf(address(composer)), 0, "Composer fully drained");
        assertEq(address(composer).balance, 0, "No residual native");
    }

    // ==================== Compose with Real Endpoint Validation ====================

    function test_lzCompose_revertsNonEndpoint() public {
        address upToken = upOft.token();
        deal(upToken, address(composer), 1 ether);

        bytes memory composeMsg = abi.encode(uint256(0), userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, ETH_EID, 1 ether, abi.encodePacked(_toBytes32(userA), composeMsg));

        // Random caller (not the real LZ endpoint) should revert
        vm.expectRevert(IHyperLiquidComposer.OnlyEndpoint.selector);
        vm.prank(makeAddr("random"));
        composer.lzCompose(UP_OFT_HYPEREVM, bytes32(0), composerMsg, address(0), "");
    }

    function test_lzCompose_revertsWrongOFT() public {
        address upToken = upOft.token();
        deal(upToken, address(composer), 1 ether);

        bytes memory composeMsg = abi.encode(uint256(0), userB);
        bytes memory composerMsg =
            OFTComposeMsgCodec.encode(0, ETH_EID, 1 ether, abi.encodePacked(_toBytes32(userA), composeMsg));

        // Real endpoint, but wrong OFT address
        vm.expectRevert(
            abi.encodeWithSelector(IHyperLiquidComposer.InvalidComposeCaller.selector, UP_OFT_HYPEREVM, address(0x1))
        );
        vm.prank(LZ_ENDPOINT_HYPEREVM);
        composer.lzCompose(address(0x1), bytes32(0), composerMsg, address(0), "");
    }

    // ==================== Helpers ====================

    function _toBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
