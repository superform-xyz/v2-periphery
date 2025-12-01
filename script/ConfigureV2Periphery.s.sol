// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ISuperGovernor } from "../src/interfaces/ISuperGovernor.sol";
import { console2 } from "forge-std/console2.sol";

contract ConfigureV2Periphery is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Gas increase per entry batch for ECDSAPPSOracle upkeep cost calculation
    /// @dev Based on gas measurements: updatePPS costs ~62,125 gas per entry (includes ECDSA validation)
    uint256 internal constant GAS_PER_ENTRY = 65_000;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Core hook addresses from v2-core deployment
    struct HookAddresses {
        address approveErc20Hook;
        address transferErc20Hook;
        address batchTransferHook;
        address batchTransferFromHook;
        address deposit4626VaultHook;
        address approveAndDeposit4626VaultHook;
        address redeem4626VaultHook;
        address deposit5115VaultHook;
        address redeem5115VaultHook;
        address approveAndDeposit5115VaultHook;
        address deposit7540VaultHook;
        address requestDeposit7540VaultHook;
        address approveAndRequestDeposit7540VaultHook;
        address redeem7540VaultHook;
        address requestRedeem7540VaultHook;
        address swap1InchHook;
        address swapOdosHook;
        address approveAndSwapOdosHook;
        address cancelDepositRequest7540Hook;
        address cancelRedeemRequest7540Hook;
        address claimCancelDepositRequest7540Hook;
        address claimCancelRedeemRequest7540Hook;
        address merklClaimRewardHook;
        address pendleRouterRedeemHook;
        address pendleRouterSwapHook;
        address acrossSendFundsAndExecuteOnDstHook;
    }

    /// @notice Configuration parameters for hook setup
    struct ConfigParams {
        uint256 env;
        uint64 chainId;
        string saltNamespace;
        string coreSalt;
        address superGovernor;
    }

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Configure SuperGovernor with all v2-core hooks (with default core salt)
    /// @param env Environment (0/2 = production, 1 = test)
    /// @param chainId Chain ID for deployment
    /// @param saltNamespace Salt namespace for deployment
    function run(uint256 env, uint64 chainId, string calldata saltNamespace) external broadcast(env) {
        _configure(env, chainId, saltNamespace, "");
    }

    /// @notice Configure SuperGovernor with all v2-core hooks (with specific core salt)
    /// @param env Environment (0/2 = production, 1 = test)
    /// @param chainId Chain ID for deployment
    /// @param saltNamespace Salt namespace for deployment
    /// @param coreSalt Core deployment salt to use (empty for default behavior)
    function run(
        uint256 env,
        uint64 chainId,
        string calldata saltNamespace,
        string calldata coreSalt
    )
        external
        broadcast(env)
    {
        _configure(env, chainId, saltNamespace, coreSalt);
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal configuration function
    function _configure(uint256 env, uint64 chainId, string memory saltNamespace, string memory coreSalt) internal {
        // Set base configuration
        _setBaseConfiguration(env, saltNamespace);

        // Create config params
        ConfigParams memory params = ConfigParams({
            env: env,
            chainId: chainId,
            saltNamespace: saltNamespace,
            coreSalt: coreSalt,
            superGovernor: address(0) // Will be populated
        });

        console2.log("=== Configuring V2 Periphery Hooks ===");
        console2.log("Chain ID:", chainId);
        console2.log("Environment:", env);
        console2.log("Salt Namespace:", saltNamespace);
        console2.log("Core Salt:", coreSalt);

        // Get SuperGovernor address
        params.superGovernor = _getSuperGovernorAddress(params);
        if (params.superGovernor == address(0)) {
            console2.log("ERROR: SuperGovernor not deployed or not found");
            return;
        }

        console2.log("SuperGovernor address:", params.superGovernor);

        // Get core hook addresses
        HookAddresses memory hooks = _getCoreHookAddresses(params);

        // Register all hooks with SuperGovernor
        _registerAllHooks(params.superGovernor, hooks);

        // Set UP and UPKEEP_TOKEN addresses in SuperGovernor
        _setTokenAddresses(params.superGovernor, params.chainId);

        // Set gas info for ECDSAPPSOracle (mainnet only)
        _setGasInfo(params);

        console2.log("=== Configuration Complete ===");
    }

    /// @notice Set UP and UPKEEP_TOKEN addresses in SuperGovernor
    /// @dev On mainnet: Both UP and UPKEEP_TOKEN are set to UP_TOKEN
    /// @dev On L2s: UP is set to address(0) (not available), UPKEEP_TOKEN is set to WETH
    function _setTokenAddresses(address superGovernor, uint64 chainId) internal {
        ISuperGovernor governor = ISuperGovernor(superGovernor);

        console2.log("Setting token addresses in SuperGovernor...");

        if (chainId == MAINNET_CHAIN_ID) {
            // Mainnet: Both UP and UPKEEP_TOKEN are the UP token
            console2.log("  Chain: Mainnet");
            console2.log("  UP token:", UP_TOKEN);
            console2.log("  UPKEEP_TOKEN:", UPKEEP_TOKEN_MAINNET);

            governor.setAddress(keccak256("UP"), UP_TOKEN);
            governor.setAddress(keccak256("UPKEEP_TOKEN"), UPKEEP_TOKEN_MAINNET);

            console2.log("SUCCESS: UP and UPKEEP_TOKEN addresses set (mainnet)");
        } else if (chainId == BASE_CHAIN_ID) {
            // Base: Only UPKEEP_TOKEN is set (UP token doesn't exist on L2s)
            console2.log("  Chain: Base");
            console2.log("  UP token: NOT SET (only on mainnet)");
            console2.log("  UPKEEP_TOKEN:", UPKEEP_TOKEN_BASE);

            // Note: We don't set UP on L2s - it will remain address(0)
            // SuperBank.distribute() will revert if called on L2s (by design)
            governor.setAddress(keccak256("UPKEEP_TOKEN"), UPKEEP_TOKEN_BASE);

            console2.log("SUCCESS: UPKEEP_TOKEN address set (Base)");
        } else {
            console2.log("WARNING: Unknown chain ID, skipping token address setup");
        }
    }

    /// @notice Set gas info for ECDSAPPSOracle (mainnet only)
    /// @dev This sets the gas increase per entry batch used to calculate upkeep costs
    /// @dev Temporarily grants GAS_MANAGER_ROLE to deployer if not already held, then revokes it
    function _setGasInfo(ConfigParams memory params) internal {
        // Only set gas info on mainnet
        if (params.chainId != MAINNET_CHAIN_ID) {
            console2.log("Skipping setGasInfo (only for mainnet, current chain:", params.chainId, ")");
            return;
        }

        console2.log("Setting gas info for ECDSAPPSOracle on mainnet...");

        ISuperGovernor governor = ISuperGovernor(params.superGovernor);

        // Get ECDSAPPSOracle address from periphery deployment
        string memory peripheryJson =
            _readPeripheryContractsFromOutput(params.chainId, params.env, params.saltNamespace);

        address ecdsaPPSOracle = address(0);
        if (bytes(peripheryJson).length > 0) {
            ecdsaPPSOracle = _safeParseJsonAddress(peripheryJson, ".ECDSAPPSOracle");
        }

        if (ecdsaPPSOracle == address(0)) {
            console2.log("WARNING: ECDSAPPSOracle not found, skipping setGasInfo");
            return;
        }

        console2.log("  ECDSAPPSOracle address:", ecdsaPPSOracle);
        console2.log("  Gas per entry:", GAS_PER_ENTRY);

        // Get GAS_MANAGER_ROLE
        bytes32 gasManagerRole = governor.GAS_MANAGER_ROLE();

        // Check if deployer already has the role
        bool hadRole = governor.hasRole(gasManagerRole, msg.sender);
        console2.log("  Deployer has GAS_MANAGER_ROLE:", hadRole);

        // Grant role temporarily if needed (deployer has DEFAULT_ADMIN_ROLE)
        if (!hadRole) {
            governor.grantRole(gasManagerRole, msg.sender);
            console2.log("  Granted GAS_MANAGER_ROLE to deployer");
        }

        // Call setGasInfo
        governor.setGasInfo(ecdsaPPSOracle, GAS_PER_ENTRY);
        console2.log("SUCCESS: setGasInfo called successfully");

        // Revoke temporary role if it was granted
        if (!hadRole) {
            governor.revokeRole(gasManagerRole, msg.sender);
            console2.log("  Revoked GAS_MANAGER_ROLE from deployer");
        }
    }

    /// @notice Get SuperGovernor address from deployment files
    function _getSuperGovernorAddress(ConfigParams memory params) internal view returns (address) {
        // Try to get from local contract addresses first (if already deployed in this session)
        address superGovernor = _getContract(params.chainId, "SuperGovernor");
        if (superGovernor != address(0)) {
            console2.log("Found SuperGovernor from local deployment:", superGovernor);
            return superGovernor;
        }

        // If not found locally, read from periphery deployment JSON files
        string memory peripheryJson =
            _readPeripheryContractsFromOutput(params.chainId, params.env, params.saltNamespace);

        if (bytes(peripheryJson).length > 0) {
            address governorAddr = _safeParseJsonAddress(peripheryJson, ".SuperGovernor");
            if (governorAddr != address(0)) {
                console2.log("Found SuperGovernor from periphery deployment file:", governorAddr);
                return governorAddr;
            }
        }

        console2.log("SuperGovernor not found in deployment files");
        return address(0);
    }

    /// @notice Get all core hook addresses from v2-core deployment
    function _getCoreHookAddresses(ConfigParams memory params) internal view returns (HookAddresses memory hooks) {
        console2.log("Loading core hook addresses from deployment files...");

        // Read core deployment JSON using the same pattern as v2-core
        string memory coreJson = _readCoreContractsFromOutput(params.chainId, params.env, params.saltNamespace);

        if (bytes(coreJson).length > 0) {
            console2.log("Successfully loaded core contracts from deployment files");

            // Parse JSON to extract hook addresses using vm.parseJsonAddress
            hooks = _parseHookAddresses(coreJson);
            console2.log("Core hook addresses parsed from deployment files");
        } else {
            console2.log("WARNING: Failed to load core contracts, using empty addresses");
            // Return empty struct - all addresses will be zero
        }

        return hooks;
    }

    /// @notice Parse hook addresses from core deployment JSON using vm.parseJsonAddress
    function _parseHookAddresses(string memory coreJson) internal pure returns (HookAddresses memory hooks) {
        // Parse each hook address from the JSON structure using the actual JSON keys from deployment
        // Keys match the contract names in the v2-core deployment JSON files

        hooks.approveErc20Hook = _safeParseJsonAddress(coreJson, ".ApproveERC20Hook");
        hooks.transferErc20Hook = _safeParseJsonAddress(coreJson, ".TransferERC20Hook");
        hooks.batchTransferHook = _safeParseJsonAddress(coreJson, ".BatchTransferHook");
        hooks.batchTransferFromHook = _safeParseJsonAddress(coreJson, ".BatchTransferFromHook");
        hooks.deposit4626VaultHook = _safeParseJsonAddress(coreJson, ".Deposit4626VaultHook");
        hooks.approveAndDeposit4626VaultHook = _safeParseJsonAddress(coreJson, ".ApproveAndDeposit4626VaultHook");
        hooks.redeem4626VaultHook = _safeParseJsonAddress(coreJson, ".Redeem4626VaultHook");
        hooks.deposit5115VaultHook = _safeParseJsonAddress(coreJson, ".Deposit5115VaultHook");
        hooks.redeem5115VaultHook = _safeParseJsonAddress(coreJson, ".Redeem5115VaultHook");
        hooks.approveAndDeposit5115VaultHook = _safeParseJsonAddress(coreJson, ".ApproveAndDeposit5115VaultHook");
        hooks.deposit7540VaultHook = _safeParseJsonAddress(coreJson, ".Deposit7540VaultHook");
        hooks.requestDeposit7540VaultHook = _safeParseJsonAddress(coreJson, ".RequestDeposit7540VaultHook");
        hooks.approveAndRequestDeposit7540VaultHook =
            _safeParseJsonAddress(coreJson, ".ApproveAndRequestDeposit7540VaultHook");
        hooks.redeem7540VaultHook = _safeParseJsonAddress(coreJson, ".Redeem7540VaultHook");
        hooks.requestRedeem7540VaultHook = _safeParseJsonAddress(coreJson, ".RequestRedeem7540VaultHook");
        hooks.swap1InchHook = _safeParseJsonAddress(coreJson, ".Swap1InchHook");
        hooks.swapOdosHook = _safeParseJsonAddress(coreJson, ".SwapOdosV2Hook");
        hooks.approveAndSwapOdosHook = _safeParseJsonAddress(coreJson, ".ApproveAndSwapOdosV2Hook");
        hooks.cancelDepositRequest7540Hook = _safeParseJsonAddress(coreJson, ".CancelDepositRequest7540Hook");
        hooks.cancelRedeemRequest7540Hook = _safeParseJsonAddress(coreJson, ".CancelRedeemRequest7540Hook");
        hooks.claimCancelDepositRequest7540Hook = _safeParseJsonAddress(coreJson, ".ClaimCancelDepositRequest7540Hook");
        hooks.claimCancelRedeemRequest7540Hook = _safeParseJsonAddress(coreJson, ".ClaimCancelRedeemRequest7540Hook");
        hooks.merklClaimRewardHook = _safeParseJsonAddress(coreJson, ".MerklClaimRewardHook");
        hooks.pendleRouterRedeemHook = _safeParseJsonAddress(coreJson, ".PendleRouterRedeemHook");
        hooks.pendleRouterSwapHook = _safeParseJsonAddress(coreJson, ".PendleRouterSwapHook");
        hooks.acrossSendFundsAndExecuteOnDstHook =
            _safeParseJsonAddress(coreJson, ".AcrossSendFundsAndExecuteOnDstHook");
    }

    /// @notice Safely parse an address from JSON, returning zero address on failure
    function _safeParseJsonAddress(string memory json, string memory key) internal pure returns (address) {
        try vm.parseJsonAddress(json, key) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }

    /// @notice Read core contracts from output files (following v2-core pattern)
    function _readCoreContractsFromOutput(
        uint64 chainId,
        uint256 env,
        string memory branchName
    )
        internal
        view
        returns (string memory)
    {
        // Use the v2-core project root to read core deployment files
        string memory coreRoot = string.concat(vm.projectRoot(), "/lib/v2-core");

        // Map chain ID to chain name
        string memory chainName = _getChainName(chainId);

        string memory envName;
        if (env == 0) {
            envName = "prod";
        } else if (env == 1) {
            require(bytes(branchName).length > 0, "BRANCH_NAME_REQUIRED_FOR_ENV_1");
            envName = branchName;
        } else {
            envName = "staging"; // env=2
        }

        // Construct path: lib/v2-core/script/output/{env}/{chainId}/{ChainName}-latest.json
        string memory outputPath = string(
            abi.encodePacked(
                coreRoot, "/script/output/", envName, "/", vm.toString(uint256(chainId)), "/", chainName, "-latest.json"
            )
        );

        console2.log("Reading core contracts from:", outputPath);

        try vm.readFile(outputPath) returns (string memory fileContent) {
            console2.log("Successfully read core deployment file");
            return fileContent;
        } catch {
            console2.log("Failed to read core deployment file:", outputPath);
            return "";
        }
    }

    /// @notice Read periphery contracts from output files
    function _readPeripheryContractsFromOutput(
        uint64 chainId,
        uint256 env,
        string memory branchName
    )
        internal
        view
        returns (string memory)
    {
        // Use the current project root for periphery deployment files
        string memory peripheryRoot = vm.projectRoot();

        // Map chain ID to chain name
        string memory chainName = _getChainName(chainId);

        string memory envName;
        if (env == 0) {
            envName = "prod";
        } else if (env == 1) {
            require(bytes(branchName).length > 0, "BRANCH_NAME_REQUIRED_FOR_ENV_1");
            envName = branchName;
        } else {
            envName = "staging"; // env=2
        }

        // Construct path: script/output/{env}/{chainId}/{ChainName}-latest.json
        string memory outputPath = string(
            abi.encodePacked(
                peripheryRoot,
                "/script/output/",
                envName,
                "/",
                vm.toString(uint256(chainId)),
                "/",
                chainName,
                "-latest.json"
            )
        );

        console2.log("Reading periphery contracts from:", outputPath);

        try vm.readFile(outputPath) returns (string memory fileContent) {
            console2.log("Successfully read periphery deployment file");
            return fileContent;
        } catch {
            console2.log("Failed to read periphery deployment file:", outputPath);
            return "";
        }
    }

    /// @notice Get chain name from chain ID
    function _getChainName(uint64 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum";
        if (chainId == 8453) return "Base";
        if (chainId == 10) return "Optimism";
        return "Unknown";
    }

    /// @notice Register all hooks with SuperGovernor
    function _registerAllHooks(address superGovernor, HookAddresses memory hooks) internal {
        ISuperGovernor governor = ISuperGovernor(superGovernor);
        uint256 totalHooks = 26; // Total number of hooks in HookAddresses struct
        uint256 successCount = 0;

        console2.log("Registering hooks with SuperGovernor...");
        console2.log("All hooks currently allowed as fulfill request hooks! WARNING...");

        // Register each hook (skip zero addresses)
        successCount += _registerHook(governor, hooks.approveErc20Hook, "approveErc20Hook");
        successCount += _registerHook(governor, hooks.transferErc20Hook, "transferErc20Hook");
        successCount += _registerHook(governor, hooks.batchTransferHook, "batchTransferHook");
        successCount += _registerHook(governor, hooks.batchTransferFromHook, "batchTransferFromHook");

        // Vault hooks
        successCount += _registerHook(governor, hooks.deposit4626VaultHook, "deposit4626VaultHook");
        successCount += _registerHook(governor, hooks.approveAndDeposit4626VaultHook, "approveAndDeposit4626VaultHook");
        successCount += _registerHook(governor, hooks.redeem4626VaultHook, "redeem4626VaultHook");
        successCount += _registerHook(governor, hooks.deposit5115VaultHook, "deposit5115VaultHook");
        successCount += _registerHook(governor, hooks.redeem5115VaultHook, "redeem5115VaultHook");
        successCount += _registerHook(governor, hooks.approveAndDeposit5115VaultHook, "approveAndDeposit5115VaultHook");
        successCount += _registerHook(governor, hooks.deposit7540VaultHook, "deposit7540VaultHook");
        successCount += _registerHook(governor, hooks.redeem7540VaultHook, "redeem7540VaultHook");
        successCount += _registerHook(
            governor, hooks.approveAndRequestDeposit7540VaultHook, "approveAndRequestDeposit7540VaultHook"
        );

        // Async request hooks
        successCount += _registerHook(governor, hooks.requestDeposit7540VaultHook, "requestDeposit7540VaultHook");
        successCount += _registerHook(governor, hooks.requestRedeem7540VaultHook, "requestRedeem7540VaultHook");
        successCount += _registerHook(
            governor, hooks.claimCancelDepositRequest7540Hook, "claimCancelDepositRequest7540Hook"
        );
        successCount += _registerHook(
            governor, hooks.claimCancelRedeemRequest7540Hook, "claimCancelRedeemRequest7540Hook"
        );

        // Other vault hooks
        successCount += _registerHook(governor, hooks.cancelDepositRequest7540Hook, "cancelDepositRequest7540Hook");
        successCount += _registerHook(governor, hooks.cancelRedeemRequest7540Hook, "cancelRedeemRequest7540Hook");

        // Swap hooks
        successCount += _registerHook(governor, hooks.swap1InchHook, "swap1InchHook");
        successCount += _registerHook(governor, hooks.swapOdosHook, "swapOdosHook");
        successCount += _registerHook(governor, hooks.approveAndSwapOdosHook, "approveAndSwapOdosHook");

        // Protocol-specific hooks
        successCount += _registerHook(governor, hooks.merklClaimRewardHook, "merklClaimRewardHook");

        // Pendle hooks
        successCount += _registerHook(governor, hooks.pendleRouterRedeemHook, "pendleRouterRedeemHook");
        successCount += _registerHook(governor, hooks.pendleRouterSwapHook, "pendleRouterSwapHook");

        // Across bridge hooks
        successCount +=
            _registerHook(governor, hooks.acrossSendFundsAndExecuteOnDstHook, "acrossSendFundsAndExecuteOnDstHook");

        console2.log("Hook registration complete:");
        console2.log("- Successfully registered:", successCount);
        console2.log("- Total hooks processed:", totalHooks);
    }

    /// @notice Register a single hook with SuperGovernor
    function _registerHook(
        ISuperGovernor governor,
        address hookAddress,
        string memory hookName
    )
        internal
        returns (uint256)
    {
        if (hookAddress == address(0)) {
            console2.log("SKIP: %s (not deployed on this chain)", hookName);
            return 0;
        }

        try governor.registerHook(hookAddress) {
            console2.log("SUCCESS: Registered %s at %s", hookName, hookAddress);
            return 1;
        } catch Error(string memory reason) {
            console2.log("FAILED: %s registration failed - %s", hookName, reason);
            return 0;
        } catch {
            console2.log("FAILED: %s registration failed - unknown error", hookName);
            return 0;
        }
    }
}
