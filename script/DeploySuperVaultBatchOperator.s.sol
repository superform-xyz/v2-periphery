// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperVaultBatchOperator } from "../src/SuperVault/SuperVaultBatchOperator.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeploySuperVaultBatchOperator
/// @notice Deployment script for SuperVaultBatchOperator - batch withdrawal/redeem operator for SuperVaults
/// @dev Deploys across multiple chains with deterministic addresses
contract DeploySuperVaultBatchOperator is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for SuperVaultBatchOperator
    string internal constant BATCH_OPERATOR_KEY = "SuperVaultBatchOperator";

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy SuperVaultBatchOperator on a single chain
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    function run(uint256 env, uint64 chainId) external broadcast(env) {
        address admin = SUPER_GOVERNOR_ADDRESS;
        address operator = _getOperatorForEnv(env);
        _deploy(env, chainId, admin, operator);
    }

    /// @notice Deploy SuperVaultBatchOperator on multiple chains
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainIds Array of chain IDs to deploy on
    function runMultiChain(uint256 env, uint64[] calldata chainIds) external broadcast(env) {
        address admin = SUPER_GOVERNOR_ADDRESS;
        address operator = _getOperatorForEnv(env);

        console2.log("====== Deploying SuperVaultBatchOperator (Multi-Chain) ======");
        console2.log("Environment:", env);
        console2.log("Admin (SUPER_GOVERNOR_ADDRESS):", admin);
        console2.log("Operator:", operator);
        console2.log("Number of chains:", chainIds.length);
        console2.log("");

        for (uint256 i = 0; i < chainIds.length; i++) {
            _deploy(env, chainIds[i], admin, operator);
            console2.log("");
        }

        console2.log("====== Multi-Chain Deployment Complete ======");
    }

    /// @notice Check if SuperVaultBatchOperator is deployed
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    function runCheck(uint256 env, uint64 chainId) external broadcast(env) {
        _setBaseConfiguration(env, "");

        address admin = SUPER_GOVERNOR_ADDRESS;
        address operator = _getOperatorForEnv(env);

        console2.log("====== SuperVaultBatchOperator Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Admin (SUPER_GOVERNOR_ADDRESS):", admin);
        console2.log("Operator:", operator);
        console2.log("");

        address batchOperatorAddr = _computeAddress(env, admin, operator);
        bool isDeployed = batchOperatorAddr.code.length > 0;

        console2.log("Computed address:", batchOperatorAddr);
        console2.log("Is deployed:", isDeployed);

        if (isDeployed) {
            SuperVaultBatchOperator batchOperator = SuperVaultBatchOperator(batchOperatorAddr);
            console2.log("");
            console2.log("=== Operator State ===");
            console2.log("Has DEFAULT_ADMIN_ROLE:", batchOperator.hasRole(batchOperator.DEFAULT_ADMIN_ROLE(), admin));
            console2.log("Has OPERATOR_ROLE (operator):", batchOperator.hasRole(batchOperator.OPERATOR_ROLE(), operator));
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /// @notice Get operator address based on environment
    /// @param env Environment (0 = prod, 2 = staging)
    function _getOperatorForEnv(uint256 env) internal pure returns (address) {
        if (env == 0) {
            return BATCH_OPERATOR_PROD;
        } else {
            return BATCH_OPERATOR_STAGING;
        }
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal deployment function
    function _deploy(uint256 env, uint64 chainId, address admin, address operator) internal {
        _setBaseConfiguration(env, "");

        console2.log("====== Deploying SuperVaultBatchOperator ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Admin:", admin);
        console2.log("Operator:", operator);
        console2.log("");

        // Validate inputs
        require(admin != address(0), "INVALID_ADMIN");
        require(operator != address(0), "INVALID_OPERATOR");

        // Get bytecode from generated artifacts
        bytes memory bytecode = __getBytecode(BATCH_OPERATOR_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");

        // Deploy
        address batchOperatorAddr = __deployContract(
            BATCH_OPERATOR_KEY,
            chainId,
            __getSalt(BATCH_OPERATOR_KEY),
            abi.encodePacked(bytecode, abi.encode(admin, operator))
        );

        // Verify deployment
        SuperVaultBatchOperator batchOperator = SuperVaultBatchOperator(batchOperatorAddr);
        require(batchOperator.hasRole(batchOperator.DEFAULT_ADMIN_ROLE(), admin), "ADMIN_ROLE_MISMATCH");
        require(batchOperator.hasRole(batchOperator.OPERATOR_ROLE(), operator), "OPERATOR_ROLE_MISMATCH");

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("Batch Operator deployed at:", batchOperatorAddr);
        console2.log("Admin verified:", admin);
        console2.log("Operator verified:", operator);

        // Write JSON output
        _writeBatchOperatorJson(env, chainId, batchOperatorAddr, admin, operator);

        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Write SuperVaultBatchOperator-latest.json to script/output/{env}/{chainId}/
    function _writeBatchOperatorJson(
        uint256 env,
        uint64 chainId,
        address batchOperatorAddr,
        address admin,
        address operator
    )
        internal
    {
        string memory root = vm.projectRoot();
        string memory envFolder = env == 0 ? "prod" : "staging";
        string memory outputFolder =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/"));

        // Create directory if it doesn't exist
        vm.createDir(outputFolder, true);

        // Create JSON content
        string memory json = vm.serializeAddress("SuperVaultBatchOperator", "address", batchOperatorAddr);
        json = vm.serializeAddress("SuperVaultBatchOperator", "admin", admin);
        json = vm.serializeAddress("SuperVaultBatchOperator", "operator", operator);
        json = vm.serializeUint("SuperVaultBatchOperator", "chainId", chainId);

        // Write to file
        string memory outputPath = string(abi.encodePacked(outputFolder, "SuperVaultBatchOperator-latest.json"));
        vm.writeJson(json, outputPath);

        console2.log("");
        console2.log("JSON output written to:", outputPath);
    }

    /// @notice Compute the deterministic address for SuperVaultBatchOperator
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param admin Admin address
    /// @param operator Operator address
    function _computeAddress(uint256 env, address admin, address operator) internal view returns (address) {
        bytes memory bytecode = __getBytecode(BATCH_OPERATOR_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(bytecode, abi.encode(admin, operator)),
            __getSalt(BATCH_OPERATOR_KEY)
        );
    }
}
