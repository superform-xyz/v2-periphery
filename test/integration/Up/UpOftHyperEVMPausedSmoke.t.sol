// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IOFT, SendParam } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";

/// @title UpOftHyperEVMPausedSmoke
/// @notice Smoke tests verifying that the HyperEVM <-> ETH and HyperEVM <-> Base OFT pathways
///         are paused via `setPeer(peerEid, bytes32(0))` on the live mainnet deployments.
///
/// Forks live mainnets and asserts (for each of ETH adapter, Base OFT, HyperEVM OFT):
///   1. `peers(peerEid)` returns `bytes32(0)`.
///   2. `quoteSend(..., dstEid=peerEid, ...)` reverts with `NoPeer(peerEid)`.
///   3. `send{value: fee}(..., dstEid=peerEid, ...)` reverts with `NoPeer(peerEid)`
///      (after token debit), confirming no funds can actually leave toward the peer chain.
///
/// The HyperEVM leg tests are expected to FAIL until `setPeer(30101, 0)` and
/// `setPeer(30184, 0)` are submitted on 0x642f...654fe. Once those land, the tests
/// should go green without any further changes.
///
/// Run:
///   ETHEREUM_RPC_URL=... BASE_RPC_URL=... HYPEREVM_RPC_URL=... \
///     forge test --mc UpOftHyperEVMPausedSmoke -vvv
contract UpOftHyperEVMPausedSmoke is Test {
    // --- Deployed OFT contracts (prod) -----------------------------------------------------
    address constant ETH_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD; // UpOFTAdapter on ETH
    address constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B; // UpOFT on Base
    address constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe; // UpOFT on HyperEVM
    address constant UP_TOKEN = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33; // UP ERC20 on ETH

    // --- LayerZero endpoint IDs -----------------------------------------------------------
    uint32 constant ETH_EID = 30101;
    uint32 constant BASE_EID = 30184;
    uint32 constant HYPEREVM_EID = 30367;

    uint256 internal ethForkId;
    uint256 internal baseForkId;
    uint256 internal hyperEvmForkId;

    address internal bridger;

    function setUp() public {
        // HyperEVM has been unpaused on-chain; these smoke tests are now obsolete.
        vm.skip(true);

        ethForkId = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        baseForkId = vm.createFork(vm.envString("BASE_RPC_URL"));
        hyperEvmForkId = vm.createFork(vm.envString("HYPEREVM_RPC_URL"));
        bridger = makeAddr("bridger");
    }

    // --- peers() reads ---------------------------------------------------------------------

    function test_ethAdapter_peerToHyperEVM_isZero() public {
        vm.selectFork(ethForkId);
        bytes32 peer = IOAppCore(ETH_ADAPTER).peers(HYPEREVM_EID);
        assertEq(peer, bytes32(0), "ETH adapter peer for HyperEVM must be zero (paused)");
    }

    function test_baseOft_peerToHyperEVM_isZero() public {
        vm.selectFork(baseForkId);
        bytes32 peer = IOAppCore(BASE_OFT).peers(HYPEREVM_EID);
        assertEq(peer, bytes32(0), "Base OFT peer for HyperEVM must be zero (paused)");
    }

    // --- quoteSend reverts -----------------------------------------------------------------

    function test_ethAdapter_quoteSendToHyperEVM_reverts() public {
        vm.selectFork(ethForkId);

        SendParam memory sendParam = _makeSendParam(HYPEREVM_EID, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, HYPEREVM_EID));
        IOFT(ETH_ADAPTER).quoteSend(sendParam, false);
    }

    function test_baseOft_quoteSendToHyperEVM_reverts() public {
        vm.selectFork(baseForkId);

        SendParam memory sendParam = _makeSendParam(HYPEREVM_EID, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, HYPEREVM_EID));
        IOFT(BASE_OFT).quoteSend(sendParam, false);
    }

    // --- send reverts (after debit) --------------------------------------------------------

    function test_ethAdapter_sendToHyperEVM_reverts() public {
        vm.selectFork(ethForkId);

        uint256 amount = 1 ether;
        SendParam memory sendParam = _makeSendParam(HYPEREVM_EID, amount);
        MessagingFee memory fee = MessagingFee({ nativeFee: 1 ether, lzTokenFee: 0 });

        // Fund the bridger with UP and native, and pre-approve the adapter so _debit succeeds
        // and execution proceeds to _lzSend where _getPeerOrRevert fires.
        deal(UP_TOKEN, bridger, amount);
        vm.deal(bridger, fee.nativeFee);

        vm.prank(bridger);
        IERC20(UP_TOKEN).approve(ETH_ADAPTER, amount);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, HYPEREVM_EID));
        vm.prank(bridger);
        IOFT(ETH_ADAPTER).send{ value: fee.nativeFee }(sendParam, fee, bridger);
    }

    function test_baseOft_sendToHyperEVM_reverts() public {
        vm.selectFork(baseForkId);

        uint256 amount = 1 ether;
        SendParam memory sendParam = _makeSendParam(HYPEREVM_EID, amount);
        MessagingFee memory fee = MessagingFee({ nativeFee: 1 ether, lzTokenFee: 0 });

        // UpOFT is its own ERC20 (mint/burn) — deal directly into the bridger's balance.
        deal(BASE_OFT, bridger, amount);
        vm.deal(bridger, fee.nativeFee);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, HYPEREVM_EID));
        vm.prank(bridger);
        IOFT(BASE_OFT).send{ value: fee.nativeFee }(sendParam, fee, bridger);
    }

    // --- HyperEVM side: paused to ETH (eid 30101) ------------------------------------------
    // Expected to FAIL until setPeer(30101, 0) is submitted on 0x642f...654fe.

    function test_hyperEvmOft_peerToEth_isZero() public {
        vm.selectFork(hyperEvmForkId);
        bytes32 peer = IOAppCore(HYPEREVM_OFT).peers(ETH_EID);
        assertEq(peer, bytes32(0), "HyperEVM OFT peer for ETH must be zero (paused)");
    }

    function test_hyperEvmOft_quoteSendToEth_reverts() public {
        vm.selectFork(hyperEvmForkId);

        SendParam memory sendParam = _makeSendParam(ETH_EID, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, ETH_EID));
        IOFT(HYPEREVM_OFT).quoteSend(sendParam, false);
    }

    function test_hyperEvmOft_sendToEth_reverts() public {
        vm.selectFork(hyperEvmForkId);

        uint256 amount = 1 ether;
        SendParam memory sendParam = _makeSendParam(ETH_EID, amount);
        MessagingFee memory fee = MessagingFee({ nativeFee: 1 ether, lzTokenFee: 0 });

        // UpOFT on HyperEVM is its own ERC20 (mint/burn) — deal directly.
        deal(HYPEREVM_OFT, bridger, amount);
        vm.deal(bridger, fee.nativeFee);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, ETH_EID));
        vm.prank(bridger);
        IOFT(HYPEREVM_OFT).send{ value: fee.nativeFee }(sendParam, fee, bridger);
    }

    // --- HyperEVM side: paused to Base (eid 30184) -----------------------------------------
    // Expected to FAIL until setPeer(30184, 0) is submitted on 0x642f...654fe.

    function test_hyperEvmOft_peerToBase_isZero() public {
        vm.selectFork(hyperEvmForkId);
        bytes32 peer = IOAppCore(HYPEREVM_OFT).peers(BASE_EID);
        assertEq(peer, bytes32(0), "HyperEVM OFT peer for Base must be zero (paused)");
    }

    function test_hyperEvmOft_quoteSendToBase_reverts() public {
        vm.selectFork(hyperEvmForkId);

        SendParam memory sendParam = _makeSendParam(BASE_EID, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, BASE_EID));
        IOFT(HYPEREVM_OFT).quoteSend(sendParam, false);
    }

    function test_hyperEvmOft_sendToBase_reverts() public {
        vm.selectFork(hyperEvmForkId);

        uint256 amount = 1 ether;
        SendParam memory sendParam = _makeSendParam(BASE_EID, amount);
        MessagingFee memory fee = MessagingFee({ nativeFee: 1 ether, lzTokenFee: 0 });

        deal(HYPEREVM_OFT, bridger, amount);
        vm.deal(bridger, fee.nativeFee);

        vm.expectRevert(abi.encodeWithSelector(IOAppCore.NoPeer.selector, BASE_EID));
        vm.prank(bridger);
        IOFT(HYPEREVM_OFT).send{ value: fee.nativeFee }(sendParam, fee, bridger);
    }

    // --- helpers ---------------------------------------------------------------------------

    function _makeSendParam(uint32 dstEid, uint256 amount) internal view returns (SendParam memory) {
        return SendParam({
            dstEid: dstEid,
            to: bytes32(uint256(uint160(bridger))),
            amountLD: amount,
            minAmountLD: 0,
            extraOptions: "",
            composeMsg: "",
            oftCmd: ""
        });
    }
}
