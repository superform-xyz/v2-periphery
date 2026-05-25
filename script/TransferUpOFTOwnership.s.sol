// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract TransferUpOFTOwnership is Script {
    // ============ Configuration ============

    /// @notice The new owner address for both UpOFTAdapter and UpOFT
    address internal constant NEW_OWNER = 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e;

    uint64 internal constant MAINNET_CHAIN_ID = 1;
    uint64 internal constant BASE_CHAIN_ID = 8453;

    string internal constant MNEMONIC = "test test test test test test test test test test test junk";

    // ============ Modifiers ============

    modifier broadcast(uint256 env) {
        if (env == 1) {
            (address deployer,) = deriveRememberKey(MNEMONIC, 0);
            console2.log("Deployer:", deployer);
            vm.startBroadcast(deployer);
            _;
            vm.stopBroadcast();
        } else {
            console2.log("Broadcast msg.sender:", msg.sender);
            vm.startBroadcast();
            _;
            vm.stopBroadcast();
        }
    }

    // ============ Public Functions ============

    /// @notice Transfer ownership of UpOFTAdapter on Ethereum
    function transferAdapterOwnership(uint256 env) public {
        _transferAdapterOwnershipWithBroadcast(env);
    }

    /// @notice Transfer ownership of UpOFT on Base
    function transferOFTOwnership(uint256 env) public {
        _transferOFTOwnershipWithBroadcast(env);
    }

    // ============ Internal Functions ============

    function _transferAdapterOwnershipWithBroadcast(uint256 env) internal broadcast(env) {
        require(block.chainid == MAINNET_CHAIN_ID, "Must run on Ethereum");
        require(NEW_OWNER != address(0), "NEW_OWNER not set");

        address adapter = _readAdapterAddress(env);

        console2.log("");
        console2.log("====== Transferring UpOFTAdapter Ownership ======");
        console2.log("Chain ID:", block.chainid);
        console2.log("UpOFTAdapter:", adapter);
        console2.log("New Owner:", NEW_OWNER);

        require(adapter.code.length > 0, "UpOFTAdapter not deployed");

        address actualOwner = Ownable(adapter).owner();
        console2.log("Current Owner (on-chain):", actualOwner);

        if (actualOwner == NEW_OWNER) {
            console2.log("[!] Ownership already transferred to NEW_OWNER, skipping...");
            return;
        }

        Ownable(adapter).transferOwnership(NEW_OWNER);

        console2.log("");
        console2.log("[+] Ownership transferred successfully!");
        console2.log("================================================");
    }

    function _transferOFTOwnershipWithBroadcast(uint256 env) internal broadcast(env) {
        require(block.chainid == BASE_CHAIN_ID, "Must run on Base");
        require(NEW_OWNER != address(0), "NEW_OWNER not set");

        address oft = _readOFTAddress(env);

        console2.log("");
        console2.log("====== Transferring UpOFT Ownership ======");
        console2.log("Chain ID:", block.chainid);
        console2.log("UpOFT:", oft);
        console2.log("New Owner:", NEW_OWNER);

        require(oft.code.length > 0, "UpOFT not deployed");

        address actualOwner = Ownable(oft).owner();
        console2.log("Current Owner (on-chain):", actualOwner);

        if (actualOwner == NEW_OWNER) {
            console2.log("[!] Ownership already transferred to NEW_OWNER, skipping...");
            return;
        }

        Ownable(oft).transferOwnership(NEW_OWNER);

        console2.log("");
        console2.log("[+] Ownership transferred successfully!");
        console2.log("==========================================");
    }

    // ============ Helper Functions ============

    function _getEnvName(uint256 env) internal pure returns (string memory) {
        if (env == 0) return "prod";
        if (env == 2) return "staging";
        return "local";
    }

    function _readAdapterAddress(uint256 env) internal view returns (address) {
        string memory envName = _getEnvName(env);
        string memory root = vm.projectRoot();
        string memory path = string(abi.encodePacked(root, "/script/output/", envName, "/1/Ethereum-latest.json"));

        string memory json = vm.readFile(path);
        address adapter = vm.parseJsonAddress(json, ".UpOFTAdapter");

        console2.log("Read UpOFTAdapter address from:", path);
        return adapter;
    }

    function _readOFTAddress(uint256 env) internal view returns (address) {
        string memory envName = _getEnvName(env);
        string memory root = vm.projectRoot();
        string memory path = string(abi.encodePacked(root, "/script/output/", envName, "/8453/Base-latest.json"));

        string memory json = vm.readFile(path);
        address oft = vm.parseJsonAddress(json, ".UpOFT");

        console2.log("Read UpOFT address from:", path);
        return oft;
    }
}
