// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";

import { UpHyperLiquidComposer } from "../src/UP/UpHyperLiquidComposer.sol";

/**
 * @title DeployUpComposer
 * @author Superform Foundation
 * @notice Deployment script for UpHyperLiquidComposer on HyperEVM.
 * @dev This is Step 2 of the LayerZero/HyperLiquid integration.
 *
 *      Prerequisites:
 *      - Step 1: UP OFT deployed on HyperEVM (complete)
 *      - Step 3: Core Index ID from HIP-1 token creation (BLOCKING - see TODOs below)
 *
 *      Post-deployment:
 *      - Activate Composer on HyperCore (send $1+ USDC/HYPE)
 *      - Transfer ownership if needed
 */
contract DeployUpComposer is Script {
    // ============ TODO: Update these values from Step 3 team ============
    //
    // BLOCKING: These values must be provided by the Step 3 team before deployment
    //
    /// @dev TODO: Get Core Index ID from Step 3 team (HIP-1 token creation)
    uint64 internal constant CORE_INDEX_ID = 0; // TODO: Replace with actual value
    //
    /// @dev TODO: Get weiDecimals from Step 3 team
    /// @dev assetDecimalDiff = EVM_decimals (18) - Core_decimals
    /// @dev If Core uses 18 decimals: assetDecimalDiff = 0 (recommended)
    /// @dev If Core uses 8 decimals:  assetDecimalDiff = 10 (like HYPE)
    int8 internal constant ASSET_DECIMAL_DIFF = 0; // TODO: Replace with actual value
    //
    // ====================================================================

    // UP OFT on HyperEVM (from Step 1 deployment)
    address internal constant UP_OFT_HYPEREVM = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;

    // MPC wallet for recovery operations
    address internal constant MPC_WALLET = 0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153;

    // HyperEVM chain configuration
    uint64 internal constant HYPEREVM_CHAIN_ID = 999;

    string internal constant MNEMONIC = "test test test test test test test test test test test junk";

    bytes internal SALT_NAMESPACE;

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

    function _setConfiguration(uint256 env, string memory saltNamespace) internal {
        require(env == 0 || env == 1 || env == 2, "INVALID_ENV");

        if (env == 0) {
            SALT_NAMESPACE = bytes("TEST1.0.0");
        } else if (env == 2) {
            SALT_NAMESPACE = bytes("STAGING1.0.0");
        } else {
            require(bytes(saltNamespace).length > 0, "TEST_ENV_REQUIRES_SALT_NAMESPACE");
            SALT_NAMESPACE = bytes(saltNamespace);
        }
    }

    // ============ Deployment Functions ============

    function deployComposer(uint256 env) public {
        _deployComposerWithBroadcast(env, "");
    }

    function deployComposer(uint256 env, string memory saltNamespace) public {
        _deployComposerWithBroadcast(env, saltNamespace);
    }

    function _deployComposerWithBroadcast(uint256 env, string memory saltNamespace) internal broadcast(env) {
        _setConfiguration(env, saltNamespace);
        require(block.chainid == HYPEREVM_CHAIN_ID, "Must run on HyperEVM");

        // Validate blocking parameters are set
        require(CORE_INDEX_ID != 0, "CORE_INDEX_ID not set - get value from Step 3 team");

        console2.log("");
        console2.log("====== Deploying UpHyperLiquidComposer on HyperEVM ======");
        console2.log("Chain ID:", block.chainid);
        console2.log("UP OFT:", UP_OFT_HYPEREVM);
        console2.log("Core Index ID:", CORE_INDEX_ID);
        console2.log("Asset Decimal Diff:", uint8(ASSET_DECIMAL_DIFF));
        console2.log("Recovery Address (MPC):", MPC_WALLET);

        address deployed = _deployComposer();

        console2.log("");
        console2.log("UpHyperLiquidComposer deployed:", deployed);
        console2.log("=========================================================");
        console2.log("");
        console2.log("Post-deployment steps:");
        console2.log("1. Activate Composer on HyperCore (send $1+ USDC/HYPE to", deployed, ")");
        console2.log("2. Verify Composer activation via coreUserExists precompile");
        console2.log("3. Test end-to-end compose flow");
    }

    function _deployComposer() internal returns (address) {
        bytes32 salt = _getSalt("UpHyperLiquidComposer");
        bytes memory bytecode = abi.encodePacked(
            type(UpHyperLiquidComposer).creationCode,
            abi.encode(UP_OFT_HYPEREVM, CORE_INDEX_ID, ASSET_DECIMAL_DIFF, MPC_WALLET)
        );

        address predicted = DeterministicDeployerLib.computeAddress(bytecode, salt);

        if (predicted.code.length > 0) {
            console2.log("[!] UpHyperLiquidComposer already deployed, skipping...");
            return predicted;
        }

        address deployed = DeterministicDeployerLib.deploy(bytecode, salt);
        require(deployed == predicted, "Address mismatch");
        require(deployed.code.length > 0, "Deployment failed");

        return deployed;
    }

    // ============ Address Computation ============

    function computeAddress(uint256 env) public returns (address) {
        return _computeAddress(env, "");
    }

    function computeAddress(uint256 env, string memory saltNamespace) public returns (address) {
        return _computeAddress(env, saltNamespace);
    }

    function _computeAddress(uint256 env, string memory saltNamespace) internal returns (address) {
        _setConfiguration(env, saltNamespace);

        bytes memory bytecode = abi.encodePacked(
            type(UpHyperLiquidComposer).creationCode,
            abi.encode(UP_OFT_HYPEREVM, CORE_INDEX_ID, ASSET_DECIMAL_DIFF, MPC_WALLET)
        );

        return DeterministicDeployerLib.computeAddress(bytecode, _getSalt("UpHyperLiquidComposer"));
    }

    // ============ Export Functions ============

    mapping(uint64 chainId => string contracts) private exportedContracts;
    mapping(uint64 chainId => uint256 count) private contractCount;

    function _exportContract(string memory contractName, address addr, uint64 chainId) internal {
        contractCount[chainId]++;
        string memory objectKey = string(abi.encodePacked("UP_COMPOSER_EXPORTS_", vm.toString(uint256(chainId))));
        exportedContracts[chainId] = vm.serializeAddress(objectKey, contractName, addr);
    }

    function _writeExportedContracts(uint64 chainId, string memory envName) internal {
        if (contractCount[chainId] == 0) return;

        string memory root = vm.projectRoot();
        string memory chainOutputFolder =
            string(abi.encodePacked("/script/output/", envName, "/", vm.toString(uint256(chainId)), "/"));

        // Create directory if it doesn't exist
        vm.createDir(string(abi.encodePacked(root, chainOutputFolder)), true);

        // Write to UpComposer-latest.json
        string memory outputPath = string(abi.encodePacked(root, chainOutputFolder, "UpComposer-latest.json"));
        vm.writeJson(exportedContracts[chainId], outputPath);

        console2.log("Exported", contractCount[chainId], "contracts to:", outputPath);
    }

    function _getEnvName(uint256 env) internal pure returns (string memory) {
        if (env == 0) return "prod";
        if (env == 2) return "staging";
        return "local";
    }

    /// @notice Export deployed contract addresses to JSON files
    /// @dev Call this after deployment to write address to script/output/{env}/999/UpComposer-latest.json
    function exportAddresses(uint256 env) public {
        _exportAddresses(env, "");
    }

    function exportAddresses(uint256 env, string memory saltNamespace) public {
        _exportAddresses(env, saltNamespace);
    }

    function _exportAddresses(uint256 env, string memory saltNamespace) internal {
        _setConfiguration(env, saltNamespace);

        address composerAddress = _computeAddress(env, saltNamespace);
        string memory envName = _getEnvName(env);

        console2.log("");
        console2.log("====== Exporting UpHyperLiquidComposer Address ======");
        console2.log("Environment:", envName);

        _exportContract("UpHyperLiquidComposer", composerAddress, HYPEREVM_CHAIN_ID);
        _writeExportedContracts(HYPEREVM_CHAIN_ID, envName);

        console2.log("");
        console2.log("====== Export Complete ======");
        console2.log("UpHyperLiquidComposer (HyperEVM):", composerAddress);
    }

    function _getSalt(string memory name) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("SuperformV2", SALT_NAMESPACE, name, "v2.0"));
    }
}
