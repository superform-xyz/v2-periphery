// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ValidatorBonding } from "../src/ValidatorBonding.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

/// @title DeployValidatorBonding
/// @notice Deployment script for ValidatorBonding - sUP bonding module for Superform validators
/// @dev Base-only deployment. Uses deterministic addresses via DeterministicDeployerLib.
contract DeployValidatorBonding is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Contract key for ValidatorBonding
    string internal constant VALIDATOR_BONDING_KEY = "ValidatorBonding";

    /// @notice sUP SuperVault address on Base mainnet (asset = UP)
    address internal constant SUP_VAULT_BASE = 0x2c71f70e2Ec720AE061Ae7E0316fC9654d94f417;

    /// @notice Minimum bond requirement: 1M sUP
    uint256 internal constant MINIMUM_BOND = 1_000_000e18;

    /// @notice Unbonding period: 7 days
    uint256 internal constant UNBONDING_PERIOD = 7 days;

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy ValidatorBonding on Base
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function run(uint256 env, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        address superGovernor = _getSuperGovernorForEnv(env, BASE_CHAIN_ID, branchName);
        address admin = SUPER_GOVERNOR_ADDRESS;
        address supToken = _getSupTokenForEnv(env);

        _deploy(env, superGovernor, admin, supToken, branchName);
    }

    /// @notice Check if ValidatorBonding is deployed on Base
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param branchName Branch name for vnet deployments (required when env == 1, ignored otherwise)
    function runCheck(uint256 env, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        address superGovernor = _getSuperGovernorForEnv(env, BASE_CHAIN_ID, branchName);
        address admin = SUPER_GOVERNOR_ADDRESS;
        address supToken = _getSupTokenForEnv(env);

        console2.log("====== ValidatorBonding Deployment Check ======");
        console2.log("Chain ID:", BASE_CHAIN_ID);
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("sUP Token:", supToken);
        console2.log("Admin (SUPER_GOVERNOR_ADDRESS):", admin);
        console2.log("Governor (SuperGovernor):", superGovernor);
        console2.log("Minimum Bond:", MINIMUM_BOND);
        console2.log("Unbonding Period:", UNBONDING_PERIOD);
        console2.log("");

        address bondingAddr = _computeAddress(env, supToken, admin, superGovernor);
        bool isDeployed = bondingAddr.code.length > 0;

        console2.log("Computed address:", bondingAddr);
        console2.log("Is deployed:", isDeployed);

        if (isDeployed) {
            ValidatorBonding bondingContract = ValidatorBonding(bondingAddr);
            console2.log("");
            console2.log("=== Bonding State ===");
            console2.log("SUP_TOKEN:", address(bondingContract.SUP_TOKEN()));
            console2.log("minimumBond:", bondingContract.minimumBond());
            console2.log("unbondingPeriod:", bondingContract.unbondingPeriod());
            console2.log(
                "Has DEFAULT_ADMIN_ROLE:", bondingContract.hasRole(bondingContract.DEFAULT_ADMIN_ROLE(), admin)
            );
            console2.log(
                "Has GOVERNOR_ROLE:", bondingContract.hasRole(bondingContract.GOVERNOR_ROLE(), superGovernor)
            );
            console2.log("Operator count:", bondingContract.getOperatorCount());
        }

        console2.log("");
        console2.log("====== Check Complete ======");
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get sUP token address for the given environment
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @return supToken The sUP token address
    function _getSupTokenForEnv(uint256 env) internal pure returns (address supToken) {
        if (env == 0) {
            // Production: known sUP SuperVault on Base
            supToken = SUP_VAULT_BASE;
        } else {
            // Staging/vnet: use the same address for now (update when staging sUP exists)
            supToken = SUP_VAULT_BASE;
        }
    }

    /// @notice Get SuperGovernor address for the given environment on Base
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param chainId Chain ID
    /// @param branchName Branch name for vnet deployments
    /// @return superGovernor The SuperGovernor address
    function _getSuperGovernorForEnv(
        uint256 env,
        uint64 chainId,
        string calldata branchName
    )
        internal
        view
        returns (address superGovernor)
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
        string memory jsonPath = string(
            abi.encodePacked(
                root,
                "/script/output/",
                envFolder,
                "/",
                vm.toString(uint256(chainId)),
                "/",
                chainName,
                "-latest.json"
            )
        );

        string memory json = vm.readFile(jsonPath);
        superGovernor = vm.parseJsonAddress(json, ".SuperGovernor");

        require(superGovernor != address(0), "SUPER_GOVERNOR_NOT_FOUND_IN_OUTPUT");

        if (superGovernor.code.length == 0) {
            console2.log("WARNING: SuperGovernor not deployed on chain", chainId);
            console2.log("Address from output JSON:", superGovernor);
        }
    }

    /// @notice Internal deployment function
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param superGovernor SuperGovernor address (receives GOVERNOR_ROLE)
    /// @param admin Admin address (receives DEFAULT_ADMIN_ROLE)
    /// @param supToken sUP token address
    /// @param branchName Branch name for vnet deployments
    function _deploy(
        uint256 env,
        address superGovernor,
        address admin,
        address supToken,
        string calldata branchName
    )
        internal
    {
        _setBaseConfiguration(env, branchName);

        console2.log("====== Deploying ValidatorBonding ======");
        console2.log("Chain ID:", BASE_CHAIN_ID);
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("sUP Token:", supToken);
        console2.log("Admin:", admin);
        console2.log("Governor:", superGovernor);
        console2.log("Minimum Bond:", MINIMUM_BOND);
        console2.log("Unbonding Period:", UNBONDING_PERIOD);
        console2.log("");

        // Validate inputs
        require(supToken != address(0), "INVALID_SUP_TOKEN");
        require(admin != address(0), "INVALID_ADMIN");
        require(superGovernor != address(0), "INVALID_GOVERNOR");

        // Get bytecode from generated artifacts
        bytes memory bytecode = __getBytecode(VALIDATOR_BONDING_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");

        // Deploy
        address bondingAddr = __deployContract(
            VALIDATOR_BONDING_KEY,
            BASE_CHAIN_ID,
            __getSalt(VALIDATOR_BONDING_KEY),
            abi.encodePacked(bytecode, abi.encode(supToken, MINIMUM_BOND, UNBONDING_PERIOD, admin, superGovernor))
        );

        // Verify deployment
        ValidatorBonding bondingContract = ValidatorBonding(bondingAddr);
        require(address(bondingContract.SUP_TOKEN()) == supToken, "SUP_TOKEN_MISMATCH");
        require(bondingContract.minimumBond() == MINIMUM_BOND, "MINIMUM_BOND_MISMATCH");
        require(bondingContract.unbondingPeriod() == UNBONDING_PERIOD, "UNBONDING_PERIOD_MISMATCH");
        require(bondingContract.hasRole(bondingContract.DEFAULT_ADMIN_ROLE(), admin), "ADMIN_ROLE_MISMATCH");
        require(bondingContract.hasRole(bondingContract.GOVERNOR_ROLE(), superGovernor), "GOVERNOR_ROLE_MISMATCH");

        console2.log("");
        console2.log("=== Deployment Verification ===");
        console2.log("ValidatorBonding deployed at:", bondingAddr);
        console2.log("sUP Token verified:", supToken);
        console2.log("Admin verified:", admin);
        console2.log("Governor verified:", superGovernor);
        console2.log("Minimum Bond verified:", MINIMUM_BOND);
        console2.log("Unbonding Period verified:", UNBONDING_PERIOD);

        // Write JSON output
        _writeBondingJson(env, bondingAddr, branchName);

        console2.log("");
        console2.log("====== Deployment Complete ======");
    }

    /// @notice Merge ValidatorBonding address into {ChainName}-latest.json
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param bondingAddr Deployed ValidatorBonding address
    /// @param branchName Branch name for vnet deployments
    function _writeBondingJson(uint256 env, address bondingAddr, string calldata branchName) internal {
        string memory root = vm.projectRoot();
        string memory envFolder;
        if (env == 0) {
            envFolder = "prod";
        } else if (env == 1) {
            envFolder = branchName;
        } else {
            envFolder = "staging";
        }

        string memory chainName = chainNames[BASE_CHAIN_ID];
        string memory outputFolder = string(
            abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(BASE_CHAIN_ID)), "/")
        );

        // Create directory if it doesn't exist
        vm.createDir(outputFolder, true);

        string memory outputPath = string(abi.encodePacked(outputFolder, chainName, "-latest.json"));

        // Merge ValidatorBonding address into existing JSON
        vm.writeJson(vm.toString(bondingAddr), outputPath, ".ValidatorBonding");

        console2.log("");
        console2.log("ValidatorBonding merged into:", outputPath);
    }

    /// @notice Compute the deterministic address for ValidatorBonding
    /// @param env Environment (0 = prod, 1 = vnet, 2 = staging)
    /// @param supToken sUP token address
    /// @param admin Admin address
    /// @param superGovernor SuperGovernor address
    function _computeAddress(
        uint256 env,
        address supToken,
        address admin,
        address superGovernor
    )
        internal
        view
        returns (address)
    {
        bytes memory bytecode = __getBytecode(VALIDATOR_BONDING_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND");
        return DeterministicDeployerLib.computeAddress(
            abi.encodePacked(bytecode, abi.encode(supToken, MINIMUM_BOND, UNBONDING_PERIOD, admin, superGovernor)),
            __getSalt(VALIDATOR_BONDING_KEY)
        );
    }
}
