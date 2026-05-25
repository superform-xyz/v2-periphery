// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";

/// @notice Reset OFT peers on HyperEVM — peers were incorrectly set to address(0)
contract ResetOFTPeersHyperEVM is Script {
    // ============ Addresses ============

    address internal constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    address internal constant ETH_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address internal constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address internal constant FLARE_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;

    // ============ LayerZero EIDs ============

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant FLARE_EID = 30295;

    function run() public {
        require(block.chainid == 999, "Must run on HyperEVM");

        IOAppCore oft = IOAppCore(HYPEREVM_OFT);

        console2.log("====== Reset OFT Peers on HyperEVM ======");
        console2.log("OFT:", HYPEREVM_OFT);
        console2.log("");

        // Log current state
        console2.log("Current peers:");
        console2.log("  ETH (30101):", vm.toString(oft.peers(ETH_EID)));
        console2.log("  Base (30184):", vm.toString(oft.peers(BASE_EID)));
        console2.log("  Flare (30295):", vm.toString(oft.peers(FLARE_EID)));
        console2.log("");

        bytes32 ethPeer = bytes32(uint256(uint160(ETH_ADAPTER)));
        bytes32 basePeer = bytes32(uint256(uint160(BASE_OFT)));
        bytes32 flarePeer = bytes32(uint256(uint160(FLARE_OFT)));

        vm.startBroadcast();

        oft.setPeer(ETH_EID, ethPeer);
        oft.setPeer(BASE_EID, basePeer);
        oft.setPeer(FLARE_EID, flarePeer);

        vm.stopBroadcast();

        // Verify
        require(oft.peers(ETH_EID) == ethPeer, "ETH peer mismatch");
        require(oft.peers(BASE_EID) == basePeer, "Base peer mismatch");
        require(oft.peers(FLARE_EID) == flarePeer, "Flare peer mismatch");

        console2.log("Peers set and verified successfully!");
    }
}

/// @notice Reset OFT peers on Flare — peers were incorrectly set to address(0)
contract ResetOFTPeersFlare is Script {
    // ============ Addresses ============

    address internal constant FLARE_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;
    address internal constant ETH_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address internal constant BASE_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address internal constant HYPEREVM_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

    // ============ LayerZero EIDs ============

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant HYPEREVM_EID = 30367;

    function run() public {
        require(block.chainid == 14, "Must run on Flare");

        IOAppCore oft = IOAppCore(FLARE_OFT);

        console2.log("====== Reset OFT Peers on Flare ======");
        console2.log("OFT:", FLARE_OFT);
        console2.log("");

        // Log current state
        console2.log("Current peers:");
        console2.log("  ETH (30101):", vm.toString(oft.peers(ETH_EID)));
        console2.log("  Base (30184):", vm.toString(oft.peers(BASE_EID)));
        console2.log("  HyperEVM (30367):", vm.toString(oft.peers(HYPEREVM_EID)));
        console2.log("");

        bytes32 ethPeer = bytes32(uint256(uint160(ETH_ADAPTER)));
        bytes32 basePeer = bytes32(uint256(uint160(BASE_OFT)));
        bytes32 hyperEvmPeer = bytes32(uint256(uint160(HYPEREVM_OFT)));

        vm.startBroadcast();

        oft.setPeer(ETH_EID, ethPeer);
        oft.setPeer(BASE_EID, basePeer);
        oft.setPeer(HYPEREVM_EID, hyperEvmPeer);

        vm.stopBroadcast();

        // Verify
        require(oft.peers(ETH_EID) == ethPeer, "ETH peer mismatch");
        require(oft.peers(BASE_EID) == basePeer, "Base peer mismatch");
        require(oft.peers(HYPEREVM_EID) == hyperEvmPeer, "HyperEVM peer mismatch");

        console2.log("Peers set and verified successfully!");
    }
}
