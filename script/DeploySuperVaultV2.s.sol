// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { DeterministicDeployerLib } from "lib/v2-core/src/vendor/nexus/DeterministicDeployerLib.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperVaultV2 } from "../src/SuperVault/SuperVaultV2.sol";
import { SuperVaultStrategyV2 } from "../src/SuperVault/SuperVaultStrategyV2.sol";
import { SuperVaultEscrow } from "../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultAggregatorV2 } from "../src/SuperVault/SuperVaultAggregatorV2.sol";

/// @title DeploySuperVaultV2
/// @notice Deployment script for the SuperVault V2 implementation suite:
///         SuperVaultV2, SuperVaultStrategyV2, SuperVaultEscrow (V2 salt), SuperVaultAggregatorV2.
///
/// @dev V2 changes vs V1:
///      - AssetMetadataLibV2: no code.length guard, supports Base B20 precompile assets
///      - SuperVaultStrategyV2: adds ERC721Receiver, ERC1155Receiver, ERC1271, ERC165
///      - SuperVaultV2: supportsInterface declares IERC7540CancelRedeem; share() is a view fn (no storage slot)
///
/// @dev This script does NOT update SuperGovernor.SUPER_VAULT_AGGREGATOR to point at V2.
///      That is a separate governance action performed after verifying the V2 aggregator
///      and migrating any required state from the V1 aggregator.
contract DeploySuperVaultV2 is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                              STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct V2Contracts {
        address vaultImpl;
        address strategyImpl;
        address escrowImpl;
        address aggregatorV2;
        address superGovernor;
    }

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy SuperVault V2 contracts on a single chain
    /// @param env Environment (0 = prod, 2 = staging, 1 = vnet)
    /// @param chainId Chain ID to deploy on
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    function run(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        address superGovernor = _getSuperGovernorFromOutput(env, chainId, branchName);
        _deploy(env, chainId, superGovernor, branchName);
    }

    /// @notice Deploy SuperVault V2 contracts on multiple chains
    /// @param env Environment (0 = prod, 2 = staging, 1 = vnet)
    /// @param chainIds Array of chain IDs
    /// @param branchName Branch name for vnet deployments (required when env == 1)
    function runMultiChain(uint256 env, uint64[] calldata chainIds, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);

        console2.log("====== Deploying SuperVault V2 (Multi-Chain) ======");
        console2.log("Environment:", env);
        if (env == 1) {
            console2.log("Branch Name:", branchName);
        }
        console2.log("Number of chains:", chainIds.length);
        console2.log("");

        for (uint256 i = 0; i < chainIds.length; i++) {
            address superGovernor = _getSuperGovernorFromOutput(env, chainIds[i], branchName);
            _deploy(env, chainIds[i], superGovernor, branchName);
            console2.log("");
        }

        console2.log("====== Multi-Chain Deployment Complete ======");
    }

    /// @notice Check deployment status without broadcasting
    /// @param env Environment (0 = prod, 2 = staging, 1 = vnet)
    /// @param chainId Chain ID to check
    /// @param branchName Branch name for vnet deployments
    function runCheck(uint256 env, uint64 chainId, string calldata branchName) external broadcast(env) {
        _validateEnvAndBranchName(env, branchName);
        _setBaseConfiguration(env, branchName);
        _runCheckInternal(env, chainId, branchName);
    }

    function _runCheckInternal(uint256 env, uint64 chainId, string calldata branchName) internal {
        address superGovernor = _getSuperGovernorFromOutput(env, chainId, branchName);
        console2.log("====== SuperVault V2 Deployment Check ======");
        console2.log("Chain ID:", chainId);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("");

        _checkImpls(env, chainId, superGovernor);
        _checkAggregatorV2(env, chainId, superGovernor);

        _logDeploymentSummary(chainId);
        console2.log("NOTE: After deployment register the V2 aggregator with SuperGovernor.");
    }

    function _checkImpls(uint256 env, uint64 chainId, address superGovernor) internal {
        bytes memory govArgs = abi.encode(superGovernor);
        __checkContractOnChain(SUPER_VAULT_V2_KEY, __getSalt(SUPER_VAULT_V2_KEY), govArgs, chainId, env);
        __checkContractOnChain(SUPER_VAULT_STRATEGY_V2_KEY, __getSalt(SUPER_VAULT_STRATEGY_V2_KEY), govArgs, chainId, env);
        __checkContractOnChain(SUPER_VAULT_ESCROW_V2_KEY, __getSalt(SUPER_VAULT_ESCROW_V2_KEY), "", chainId, env);
    }

    function _checkAggregatorV2(uint256 env, uint64 chainId, address superGovernor) internal {
        address vaultImpl = _computeV2Addr(SUPER_VAULT_V2_KEY, superGovernor, env);
        address strategyImpl = _computeV2Addr(SUPER_VAULT_STRATEGY_V2_KEY, superGovernor, env);
        address escrowImpl = _computeEscrowAddr(env);
        bytes memory aggArgs = abi.encode(superGovernor, vaultImpl, strategyImpl, escrowImpl);
        __checkContractOnChain(SUPER_VAULT_AGGREGATOR_V2_KEY, __getSalt(SUPER_VAULT_AGGREGATOR_V2_KEY), aggArgs, chainId, env);
    }

    function _computeV2Addr(string memory key, address superGovernor, uint256 env) internal view returns (address) {
        bytes memory bc = __getBytecode(key, env);
        if (bc.length == 0) return address(0);
        return DeterministicDeployerLib.computeAddress(abi.encodePacked(bc, abi.encode(superGovernor)), __getSalt(key));
    }

    function _computeEscrowAddr(uint256 env) internal view returns (address) {
        bytes memory bc = __getBytecode(SUPER_VAULT_ESCROW_V2_KEY, env);
        if (bc.length == 0) bc = __getBytecode(SUPER_VAULT_ESCROW_KEY, env);
        if (bc.length == 0) return address(0);
        return DeterministicDeployerLib.computeAddress(bc, __getSalt(SUPER_VAULT_ESCROW_V2_KEY));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _deploy(uint256 env, uint64 chainId, address superGovernor, string calldata branchName) internal {
        console2.log("====== Deploying SuperVault V2 ======");
        console2.log("Chain ID:", chainId);
        console2.log("SuperGovernor:", superGovernor);
        console2.log("");

        require(superGovernor != address(0), "INVALID_SUPER_GOVERNOR");

        V2Contracts memory c;
        c.superGovernor = superGovernor;
        c.vaultImpl = _deployVaultImpl(env, chainId, superGovernor);
        c.strategyImpl = _deployStrategyImpl(env, chainId, superGovernor);
        c.escrowImpl = _deployEscrowImpl(env, chainId);
        c.aggregatorV2 = _deployAggregatorV2(env, chainId, superGovernor, c.vaultImpl, c.strategyImpl, c.escrowImpl);

        _verify(c);
        _writeOutputJson(env, chainId, branchName, c);

        console2.log("");
        console2.log("====== SuperVault V2 Deployment Complete ======");
        console2.log("NEXT STEP: Register V2 aggregator with SuperGovernor (requires GOVERNOR_ROLE):");
        console2.log("  superGovernor.setAddress(SUPER_VAULT_AGGREGATOR, aggregatorV2)");
        console2.log("  aggregatorV2:", c.aggregatorV2);
    }

    function _deployVaultImpl(uint256 env, uint64 chainId, address superGovernor) internal returns (address) {
        bytes memory bytecode = __getBytecode(SUPER_VAULT_V2_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND: SuperVaultV2");
        return __deployContract(
            SUPER_VAULT_V2_KEY,
            chainId,
            __getSalt(SUPER_VAULT_V2_KEY),
            abi.encodePacked(bytecode, abi.encode(superGovernor))
        );
    }

    function _deployStrategyImpl(uint256 env, uint64 chainId, address superGovernor) internal returns (address) {
        bytes memory bytecode = __getBytecode(SUPER_VAULT_STRATEGY_V2_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND: SuperVaultStrategyV2");
        return __deployContract(
            SUPER_VAULT_STRATEGY_V2_KEY,
            chainId,
            __getSalt(SUPER_VAULT_STRATEGY_V2_KEY),
            abi.encodePacked(bytecode, abi.encode(superGovernor))
        );
    }

    function _deployEscrowImpl(uint256 env, uint64 chainId) internal returns (address) {
        bytes memory bytecode = __getBytecode(SUPER_VAULT_ESCROW_V2_KEY, env);
        if (bytecode.length == 0) {
            // Fall back to V1 escrow bytecode if V2-keyed artifact doesn't exist yet
            bytecode = __getBytecode(SUPER_VAULT_ESCROW_KEY, env);
        }
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND: SuperVaultEscrow");
        return __deployContract(SUPER_VAULT_ESCROW_V2_KEY, chainId, __getSalt(SUPER_VAULT_ESCROW_V2_KEY), bytecode);
    }

    function _deployAggregatorV2(
        uint256 env,
        uint64 chainId,
        address superGovernor,
        address vaultImpl,
        address strategyImpl,
        address escrowImpl
    )
        internal
        returns (address)
    {
        bytes memory bytecode = __getBytecode(SUPER_VAULT_AGGREGATOR_V2_KEY, env);
        require(bytecode.length > 0, "BYTECODE_NOT_FOUND: SuperVaultAggregatorV2");
        return __deployContract(
            SUPER_VAULT_AGGREGATOR_V2_KEY,
            chainId,
            __getSalt(SUPER_VAULT_AGGREGATOR_V2_KEY),
            abi.encodePacked(bytecode, abi.encode(superGovernor, vaultImpl, strategyImpl, escrowImpl))
        );
    }

    function _verify(V2Contracts memory c) internal view {
        console2.log("");
        console2.log("=== Deployment Verification ===");

        require(c.vaultImpl.code.length > 0, "VERIFY: SuperVaultV2 not deployed");
        require(c.strategyImpl.code.length > 0, "VERIFY: SuperVaultStrategyV2 not deployed");
        require(c.escrowImpl.code.length > 0, "VERIFY: SuperVaultEscrow not deployed");
        require(c.aggregatorV2.code.length > 0, "VERIFY: SuperVaultAggregatorV2 not deployed");

        _verifyGovernorRefs(c);
        _verifyAggregatorRefs(c);

        console2.log("[OK] SuperVaultV2 impl:", c.vaultImpl);
        console2.log("[OK] SuperVaultStrategyV2 impl:", c.strategyImpl);
        console2.log("[OK] SuperVaultEscrow impl (V2 salt):", c.escrowImpl);
        console2.log("[OK] SuperVaultAggregatorV2:", c.aggregatorV2);
    }

    function _verifyGovernorRefs(V2Contracts memory c) internal view {
        require(
            address(SuperVaultV2(c.vaultImpl).SUPER_GOVERNOR()) == c.superGovernor,
            "VERIFY: SuperVaultV2.SUPER_GOVERNOR mismatch"
        );
        require(
            address(SuperVaultStrategyV2(payable(c.strategyImpl)).SUPER_GOVERNOR()) == c.superGovernor,
            "VERIFY: SuperVaultStrategyV2.SUPER_GOVERNOR mismatch"
        );
        require(
            address(SuperVaultAggregatorV2(c.aggregatorV2).SUPER_GOVERNOR()) == c.superGovernor,
            "VERIFY: SuperVaultAggregatorV2.SUPER_GOVERNOR mismatch"
        );
    }

    function _verifyAggregatorRefs(V2Contracts memory c) internal view {
        SuperVaultAggregatorV2 agg = SuperVaultAggregatorV2(c.aggregatorV2);
        require(agg.VAULT_IMPLEMENTATION() == c.vaultImpl, "VERIFY: VAULT_IMPLEMENTATION mismatch");
        require(agg.STRATEGY_IMPLEMENTATION() == c.strategyImpl, "VERIFY: STRATEGY_IMPLEMENTATION mismatch");
        require(agg.ESCROW_IMPLEMENTATION() == c.escrowImpl, "VERIFY: ESCROW_IMPLEMENTATION mismatch");
    }

    function _writeOutputJson(
        uint256 env,
        uint64 chainId,
        string calldata branchName,
        V2Contracts memory c
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
        string memory outputPath = string(
            abi.encodePacked(
                root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/", chainName, "-latest.json"
            )
        );

        vm.createDir(
            string(
                abi.encodePacked(root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/")
            ),
            true
        );

        // Merge into existing JSON so other entries are preserved
        vm.writeJson(vm.toString(c.vaultImpl), outputPath, ".SuperVaultV2");
        vm.writeJson(vm.toString(c.strategyImpl), outputPath, ".SuperVaultStrategyV2");
        vm.writeJson(vm.toString(c.escrowImpl), outputPath, ".SuperVaultEscrowV2");
        vm.writeJson(vm.toString(c.aggregatorV2), outputPath, ".SuperVaultAggregatorV2");

        console2.log("");
        console2.log("Output written to:", outputPath);
    }

    function _getSuperGovernorFromOutput(
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
                root, "/script/output/", envFolder, "/", vm.toString(uint256(chainId)), "/", chainName, "-latest.json"
            )
        );

        string memory json = vm.readFile(jsonPath);
        superGovernor = vm.parseJsonAddress(json, ".SuperGovernor");

        require(superGovernor != address(0), "SUPER_GOVERNOR_NOT_FOUND_IN_OUTPUT");

        if (superGovernor.code.length == 0) {
            console2.log("WARNING: SuperGovernor has no code on chain", chainId);
            console2.log("Address from output JSON:", superGovernor);
        }
    }

}
