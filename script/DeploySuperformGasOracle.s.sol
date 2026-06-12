// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperformGasOracle } from "../src/oracles/SuperformGasOracle.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeploySuperformGasOracle
/// @notice Deployment script for SuperformGasOracle - a keeper-updated gas price oracle for L2s
/// @dev Used on L2 chains where Chainlink's Fast Gas feed is not available
contract DeploySuperformGasOracle is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for SuperformGasOracle
    string internal constant SUPERFORM_GAS_ORACLE_KEY = "SuperformGasOracle";

    /// @notice Default initial gas price in Gwei (oracle has 0 decimals - value is directly in Gwei)
    /// @dev This value is used for deterministic address computation and must match the deployed oracle.
    int256 internal constant DEFAULT_INITIAL_GAS_PRICE = 1_000_000;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy SuperformGasOracle with default gas price
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param owner Address that can update the gas price (keeper)
    function run(uint256 env, uint64 chainId, address owner) external broadcast(env) {
        _deploy(env, chainId, DEFAULT_INITIAL_GAS_PRICE, owner);
    }

    /// @notice Deploy SuperformGasOracle with custom initial gas price
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to deploy on
    /// @param initialGasPrice Initial gas price in Gwei
    /// @param owner Address that can update the gas price (keeper)
    function run(uint256 env, uint64 chainId, int256 initialGasPrice, address owner) external broadcast(env) {
        _deploy(env, chainId, initialGasPrice, owner);
    }

    /// @notice Check if SuperformGasOracle is deployed
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID to check
    /// @param owner Owner address used in deployment
    function runCheck(uint256 env, uint64 chainId, address owner) external broadcast(env) {
        _setBaseConfiguration(env, "");

        console2.log("====== SuperformGasOracle Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Owner:", owner);
        console2.log("");

        address oracleAddr = _computeAddress(DEFAULT_INITIAL_GAS_PRICE, owner);
        bool isDeployed = oracleAddr.code.length > 0;

        console2.log("Computed address:", oracleAddr);
        console2.log("Is deployed:", isDeployed);

        if (isDeployed) {
            SuperformGasOracle oracle = SuperformGasOracle(oracleAddr);
            console2.log("");
            console2.log("=== Oracle State ===");
            console2.log("Has DEFAULT_ADMIN_ROLE:", oracle.hasRole(oracle.DEFAULT_ADMIN_ROLE(), owner));
            console2.log("Has KEEPER_ROLE:", oracle.hasRole(oracle.KEEPER_ROLE(), owner));
            console2.log("Decimals:", oracle.decimals());
            console2.log("Description:", oracle.description());

            (uint80 roundId, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();
            console2.log("Round ID:", roundId);
            console2.log("Gas Price (Gwei):", uint256(answer));
            console2.log("Last Updated:", updatedAt);
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal deployment function
    function _deploy(uint256 env, uint64 chainId, int256 initialGasPrice, address owner) internal {
        _setBaseConfiguration(env, "");

        console2.log("====== Deploying SuperformGasOracle ======");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Initial Gas Price (Gwei):", uint256(initialGasPrice));
        console2.log("Owner:", owner);
        console2.log("");

        // Validate inputs
        require(initialGasPrice > 0, "INVALID_GAS_PRICE");
        require(owner != address(0), "INVALID_OWNER");

        // Deploy
        address oracleAddr = __deployContract(
            SUPERFORM_GAS_ORACLE_KEY,
            chainId,
            __getSalt(SUPERFORM_GAS_ORACLE_KEY),
            abi.encodePacked(type(SuperformGasOracle).creationCode, abi.encode(initialGasPrice, owner))
        );

        // Verify deployment
        SuperformGasOracle oracle = SuperformGasOracle(oracleAddr);
        require(oracle.hasRole(oracle.DEFAULT_ADMIN_ROLE(), owner), "ADMIN_ROLE_MISMATCH");
        require(oracle.hasRole(oracle.KEEPER_ROLE(), owner), "KEEPER_ROLE_MISMATCH");
        require(oracle.latestAnswer() == initialGasPrice, "GAS_PRICE_MISMATCH");

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("Oracle deployed at:", oracleAddr);
        console2.log("Admin verified:", owner);
        console2.log("Keeper verified:", owner);
        console2.log("Gas price verified:", uint256(oracle.latestAnswer()));
        console2.log("Decimals:", oracle.decimals());

        // Write JSON output
        _writeGasOracleJson(env, chainId, oracleAddr);

        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Merge SuperformGasOracle address into {ChainName}-latest.json
    function _writeGasOracleJson(uint256 env, uint64 chainId, address oracleAddr) internal {
        string memory root = vm.projectRoot();
        string memory envFolder = env == 0 ? "prod" : "staging";
        string memory outputFolder =
            string(abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/"));

        vm.createDir(outputFolder, true);

        string memory chainName = chainNames[chainId];
        require(bytes(chainName).length > 0, "UNSUPPORTED_CHAIN_NAME");

        string memory outputPath = string(abi.encodePacked(outputFolder, chainName, "-latest.json"));
        vm.writeJson(vm.toString(oracleAddr), outputPath, ".SuperformGasOracle");

        console2.log("");
        console2.log("SuperformGasOracle merged into:", outputPath);
    }

    /// @notice Compute the deterministic address for SuperformGasOracle
    function _computeAddress(int256 initialGasPrice, address owner) internal returns (address) {
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(type(SuperformGasOracle).creationCode, abi.encode(initialGasPrice, owner)),
            __getSalt(SUPERFORM_GAS_ORACLE_KEY)
        );
    }
}
