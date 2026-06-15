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
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function run(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        address admin = _getAdminForChain(chainId);
        address operator = _getOperatorForEnvAndChain(env, chainId);
        _deploy(env, chainId, admin, operator, branchName);
    }

    /// @notice Deploy SuperVaultBatchOperator on multiple chains
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainIds Array of chain IDs to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runMultiChain(uint256 env, uint64[] calldata chainIds, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);

        console2.log("====== Deploying SuperVaultBatchOperator (Multi-Chain) ======");
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("Number of chains:", chainIds.length);
        console2.log("");

        for (uint256 i = 0; i < chainIds.length; i++) {
            address admin = _getAdminForChain(chainIds[i]);
            address operator = _getOperatorForEnvAndChain(env, chainIds[i]);
            _deploy(env, chainIds[i], admin, operator, branchName);
            console2.log("");
        }

        console2.log("====== Multi-Chain Deployment Complete ======");
    }

    /// @notice Check if SuperVaultBatchOperator is deployed
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runCheck(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        address admin = _getAdminForChain(chainId);
        address operator = _getOperatorForEnvAndChain(env, chainId);

        console2.log("====== SuperVaultBatchOperator Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("Admin:", admin);
        if (chainId == FLARE_CHAIN_ID) {
            console2.log("Note: Flare uses deployer as admin (no Gnosis Safe available)");
        }
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

    /// @notice Get admin address based on chain
    /// @dev Flare uses deployer (msg.sender) since Gnosis Safe is not available on Flare
    /// @param chainId Chain ID
    function _getAdminForChain(uint64 chainId) internal view returns (address) {
        if (chainId == FLARE_CHAIN_ID) {
            return msg.sender;
        }
        return SUPER_GOVERNOR_ADDRESS;
    }

    /// @notice Get operator address based on environment and chain
    /// @dev Flare uses a dedicated operator since Gnosis Safe is not available
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    function _getOperatorForEnvAndChain(uint256 env, uint64 chainId) internal pure returns (address) {
        if (chainId == FLARE_CHAIN_ID) {
            return BATCH_OPERATOR_FLARE;
        }
        if (env == 0) {
            return BATCH_OPERATOR_PROD;
        }
        // vnet and staging use the same operator
        return BATCH_OPERATOR_STAGING;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal deployment function
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param admin Admin address
    /// @param operator Operator address
    /// @param branchName Branch name for vnet deployments
    function _deploy(uint256 env, uint64 chainId, address admin, address operator, string calldata branchName) internal {
        _setBaseConfiguration(env, branchName);

        console2.log("====== Deploying SuperVaultBatchOperator ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
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
        _writeBatchOperatorJson(env, chainId, batchOperatorAddr, branchName);

        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Merge SuperVaultBatchOperator address into {ChainName}-latest.json
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param batchOperatorAddr Deployed batch operator address
    /// @param branchName Branch name for vnet deployments
    function _writeBatchOperatorJson(
        uint256 env,
        uint64 chainId,
        address batchOperatorAddr,
        string calldata branchName
    )
        internal
    {
        string memory root = vm.projectRoot();
        string memory envFolder;
        if (env == 0) {
            envFolder = "prod";
        } else if (env == 1) {
            envFolder = branchName;
        } else {
            envFolder = "staging";
        }

        string memory chainName = chainNames[chainId];
        string memory outputFolder =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/"));

        // Create directory if it doesn't exist
        vm.createDir(outputFolder, true);

        string memory outputPath = string(abi.encodePacked(outputFolder, chainName, "-latest.json"));

        // Merge SuperVaultBatchOperator address into existing JSON
        // vm.writeJson with path selector will create file if it doesn't exist or update existing
        vm.writeJson(vm.toString(batchOperatorAddr), outputPath, ".SuperVaultBatchOperator");

        console2.log("");
        console2.log("SuperVaultBatchOperator merged into:", outputPath);
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
