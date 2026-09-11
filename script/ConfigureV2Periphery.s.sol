// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { ISuperGovernor } from "../src/interfaces/ISuperGovernor.sol";
import { console2 } from "forge-std/console2.sol";

contract ConfigureV2Periphery is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

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

        // Load the core deployment JSON for this chain and register every hook in _hookKeys()
        string memory coreJson = _readCoreContractsFromOutput(params.chainId, params.env, params.saltNamespace);
        if (bytes(coreJson).length == 0) {
            console2.log("WARNING: Failed to load core contracts - no hooks will be registered");
        }
        _registerAllHooks(params.superGovernor, coreJson);

        // Set UP and UPKEEP_TOKEN addresses in SuperGovernor
        _setTokenAddresses(params.superGovernor, params.chainId, params.env);

        // NOTE: Gas info for ECDSAPPSOracle is now set during deployment in DeployV2Periphery.s.sol

        console2.log("=== Configuration Complete ===");
    }

    /// @notice Set UP and UPKEEP_TOKEN addresses in SuperGovernor
    /// @dev On mainnet: Both UP and UPKEEP_TOKEN are set to UP_TOKEN
    /// @dev On L2s: UP is set to address(0) (not available), UPKEEP_TOKEN is set to UP_TOKEN_BASE
    function _setTokenAddresses(address superGovernor, uint64 chainId, uint256 env) internal {
        ISuperGovernor governor = ISuperGovernor(superGovernor);

        console2.log("Setting token addresses in SuperGovernor...");

        if (chainId == MAINNET_CHAIN_ID) {
            // Mainnet: Both UP and UPKEEP_TOKEN are the UP token
            console2.log("  Chain: Mainnet");
            console2.log("  UP token:", UP_TOKEN);
            console2.log("  UPKEEP_TOKEN:", UPKEEP_TOKEN_MAINNET);

            // Check if already configured
            bool upAlreadySet = _isAddressSet(governor, keccak256("UP"), UP_TOKEN);
            bool upkeepAlreadySet = _isAddressSet(governor, keccak256("UPKEEP_TOKEN"), UPKEEP_TOKEN_MAINNET);

            if (upAlreadySet && upkeepAlreadySet) {
                console2.log("SKIPPED: Token addresses already configured correctly (mainnet)");
                return;
            }

            if (!upAlreadySet) {
                governor.setAddress(keccak256("UP"), UP_TOKEN);
                console2.log("  Set UP token");
            }
            if (!upkeepAlreadySet) {
                governor.setAddress(keccak256("UPKEEP_TOKEN"), UPKEEP_TOKEN_MAINNET);
                console2.log("  Set UPKEEP_TOKEN");
            }

            console2.log("SUCCESS: UP and UPKEEP_TOKEN addresses set (mainnet)");
        } else if (chainId == BASE_CHAIN_ID) {
            // Base: Both UP and UPKEEP_TOKEN are set to UP_TOKEN_BASE
            console2.log("  Chain: Base");
            console2.log("  UP token:", UP_TOKEN_BASE);
            console2.log("  UPKEEP_TOKEN:", UPKEEP_TOKEN_BASE);

            // Check if already configured
            bool upAlreadySet = _isAddressSet(governor, keccak256("UP"), UP_TOKEN_BASE);
            bool upkeepAlreadySet = _isAddressSet(governor, keccak256("UPKEEP_TOKEN"), UPKEEP_TOKEN_BASE);

            if (upAlreadySet && upkeepAlreadySet) {
                console2.log("SKIPPED: Token addresses already configured correctly (Base)");
                return;
            }

            if (!upAlreadySet) {
                governor.setAddress(keccak256("UP"), UP_TOKEN_BASE);
                console2.log("  Set UP token");
            }
            if (!upkeepAlreadySet) {
                governor.setAddress(keccak256("UPKEEP_TOKEN"), UPKEEP_TOKEN_BASE);
                console2.log("  Set UPKEEP_TOKEN");
            }

            console2.log("SUCCESS: UP and UPKEEP_TOKEN addresses set (Base)");
        } else if (chainId == HYPEREVM_CHAIN_ID) {
            // HyperEVM: Both UP and UPKEEP_TOKEN are the UpOFT token
            address upToken = env == 2 ? UP_TOKEN_HYPEREVM_STAGING : UP_TOKEN_HYPEREVM;
            address upkeepToken = env == 2 ? UPKEEP_TOKEN_HYPEREVM_STAGING : UPKEEP_TOKEN_HYPEREVM;
            console2.log("  Chain: HyperEVM");
            console2.log("  UP token:", upToken);
            console2.log("  UPKEEP_TOKEN:", upkeepToken);

            bool upAlreadySet = _isAddressSet(governor, keccak256("UP"), upToken);
            bool upkeepAlreadySet = _isAddressSet(governor, keccak256("UPKEEP_TOKEN"), upkeepToken);

            if (upAlreadySet && upkeepAlreadySet) {
                console2.log("SKIPPED: Token addresses already configured correctly (HyperEVM)");
                return;
            }

            if (!upAlreadySet) {
                governor.setAddress(keccak256("UP"), upToken);
                console2.log("  Set UP token");
            }
            if (!upkeepAlreadySet) {
                governor.setAddress(keccak256("UPKEEP_TOKEN"), upkeepToken);
                console2.log("  Set UPKEEP_TOKEN");
            }

            console2.log("SUCCESS: UP and UPKEEP_TOKEN addresses set (HyperEVM)");
        } else if (chainId == FLARE_CHAIN_ID) {
            // Flare: Both UP and UPKEEP_TOKEN are the UpOFT token
            address upToken = env == 2 ? UP_TOKEN_FLARE_STAGING : UP_TOKEN_FLARE;
            address upkeepToken = env == 2 ? UPKEEP_TOKEN_FLARE_STAGING : UPKEEP_TOKEN_FLARE;
            console2.log("  Chain: Flare");
            console2.log("  UP token:", upToken);
            console2.log("  UPKEEP_TOKEN:", upkeepToken);

            bool upAlreadySet = _isAddressSet(governor, keccak256("UP"), upToken);
            bool upkeepAlreadySet = _isAddressSet(governor, keccak256("UPKEEP_TOKEN"), upkeepToken);

            if (upAlreadySet && upkeepAlreadySet) {
                console2.log("SKIPPED: Token addresses already configured correctly (Flare)");
                return;
            }

            if (!upAlreadySet) {
                governor.setAddress(keccak256("UP"), upToken);
                console2.log("  Set UP token");
            }
            if (!upkeepAlreadySet) {
                governor.setAddress(keccak256("UPKEEP_TOKEN"), upkeepToken);
                console2.log("  Set UPKEEP_TOKEN");
            }

            console2.log("SUCCESS: UP and UPKEEP_TOKEN addresses set (Flare)");
        } else if (chainId == ROBINHOOD_CHAIN_ID) {
            // RH: Both UP and UPKEEP_TOKEN are the UpOFT token
            address upToken = UP_TOKEN_RH;
            address upkeepToken = UPKEEP_TOKEN_RH;
            console2.log("  Chain: RH");
            console2.log("  UP token:", upToken);
            console2.log("  UPKEEP_TOKEN:", upkeepToken);

            bool upAlreadySet = _isAddressSet(governor, keccak256("UP"), upToken);
            bool upkeepAlreadySet = _isAddressSet(governor, keccak256("UPKEEP_TOKEN"), upkeepToken);

            if (upAlreadySet && upkeepAlreadySet) {
                console2.log("SKIPPED: Token addresses already configured correctly (RH)");
                return;
            }

            if (!upAlreadySet) {
                governor.setAddress(keccak256("UP"), upToken);
                console2.log("  Set UP token");
            }
            if (!upkeepAlreadySet) {
                governor.setAddress(keccak256("UPKEEP_TOKEN"), upkeepToken);
                console2.log("  Set UPKEEP_TOKEN");
            }

            console2.log("SUCCESS: UP and UPKEEP_TOKEN addresses set (RH)");
        } else if (chainId == BNB_CHAIN_ID) {
            // BNB: Both UP and UPKEEP_TOKEN are the UpOFT token
            address upToken = UP_TOKEN_BNB;
            address upkeepToken = UPKEEP_TOKEN_BNB;
            console2.log("  Chain: BNB");
            console2.log("  UP token:", upToken);
            console2.log("  UPKEEP_TOKEN:", upkeepToken);

            bool upAlreadySet = _isAddressSet(governor, keccak256("UP"), upToken);
            bool upkeepAlreadySet = _isAddressSet(governor, keccak256("UPKEEP_TOKEN"), upkeepToken);

            if (upAlreadySet && upkeepAlreadySet) {
                console2.log("SKIPPED: Token addresses already configured correctly (BNB)");
                return;
            }

            if (!upAlreadySet) {
                governor.setAddress(keccak256("UP"), upToken);
                console2.log("  Set UP token");
            }
            if (!upkeepAlreadySet) {
                governor.setAddress(keccak256("UPKEEP_TOKEN"), upkeepToken);
                console2.log("  Set UPKEEP_TOKEN");
            }

            console2.log("SUCCESS: UP and UPKEEP_TOKEN addresses set (BNB)");
        } else {
            console2.log("WARNING: Unknown chain ID, skipping token address setup");
        }
    }

    /// @notice Check if an address is already set to the expected value
    /// @return True if the address is already set to the expected value
    function _isAddressSet(ISuperGovernor governor, bytes32 key, address expected) internal view returns (bool) {
        try governor.getAddress(key) returns (address current) {
            return current == expected;
        } catch {
            return false;
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
        PeripheryJsonData memory data =
            _readPeripheryContractsFromOutputWithChainName(params.chainId, params.env, params.saltNamespace);

        if (bytes(data.json).length > 0 && bytes(data.chainName).length > 0) {
            // Parse using the latest.json structure: .networks.{ChainName}.contracts.{ContractName}
            string memory key = string(abi.encodePacked(".networks.", data.chainName, ".contracts.SuperGovernor"));
            address governorAddr = _safeParseJsonAddress(data.json, key);
            if (governorAddr != address(0)) {
                console2.log("Found SuperGovernor from periphery deployment file:", governorAddr);
                return governorAddr;
            }
        }

        console2.log("SuperGovernor not found in deployment files");
        return address(0);
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

    /// @notice Struct to hold periphery JSON data and chain name for parsing
    struct PeripheryJsonData {
        string json;
        string chainName;
    }

    /// @notice Read periphery contracts from latest.json
    function _readPeripheryContractsFromOutput(
        uint64 chainId,
        uint256 env,
        string memory branchName
    )
        internal
        view
        returns (string memory)
    {
        PeripheryJsonData memory data = _readPeripheryContractsFromOutputWithChainName(chainId, env, branchName);
        return data.json;
    }

    /// @notice Read periphery contracts from latest.json with chain name
    function _readPeripheryContractsFromOutputWithChainName(
        uint64 chainId,
        uint256 env,
        string memory branchName
    )
        internal
        view
        returns (PeripheryJsonData memory data)
    {
        // Use the current project root for periphery deployment files
        string memory peripheryRoot = vm.projectRoot();

        string memory envName;
        if (env == 0) {
            envName = "prod";
        } else if (env == 1) {
            require(bytes(branchName).length > 0, "BRANCH_NAME_REQUIRED_FOR_ENV_1");
            envName = branchName;
        } else {
            envName = "staging"; // env=2
        }

        // Read from latest.json which contains all networks
        string memory latestPath = string(abi.encodePacked(peripheryRoot, "/script/output/", envName, "/latest.json"));

        console2.log("Reading periphery contracts from:", latestPath);

        try vm.readFile(latestPath) returns (string memory fileContent) {
            console2.log("Successfully read latest.json");

            // Extract the contracts for this specific chain
            string memory chainName = _getChainNameFromLatestJson(fileContent, chainId);
            if (bytes(chainName).length == 0) {
                console2.log("Chain ID not found in latest.json:", chainId);
                return data; // Return empty data
            }

            console2.log("Found network:", chainName);

            // Verify the contracts section exists for this network
            string memory contractsKey = string(abi.encodePacked(".networks.", chainName, ".contracts"));
            try vm.parseJson(fileContent, contractsKey) returns (bytes memory) {
                data.json = fileContent;
                data.chainName = chainName;
                return data;
            } catch {
                console2.log("Failed to parse contracts for network:", chainName);
                return data; // Return empty data
            }
        } catch {
            console2.log("Failed to read latest.json:", latestPath);
            return data; // Return empty data
        }
    }

    /// @notice Get chain name from chain ID (for file paths)
    function _getChainName(uint64 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum";
        if (chainId == 8453) return "Base";
        if (chainId == 10) return "Optimism";
        if (chainId == 42_161) return "Arbitrum";
        if (chainId == 137) return "Polygon";
        if (chainId == 43_114) return "Avalanche";
        if (chainId == 56) return "BNB";
        if (chainId == 80_094) return "Berachain";
        if (chainId == 146) return "Sonic";
        if (chainId == 100) return "Gnosis";
        if (chainId == 130) return "Unichain";
        if (chainId == 480) return "Worldchain";
        if (chainId == 999) return "HyperEVM";
        if (chainId == 14) return "Flare";
        if (chainId == 4663) return "RH";
        if (chainId == 56) return "BNB";
        return "Unknown";
    }

    /// @notice Get chain name from latest.json by searching for chain ID
    /// @dev Returns empty string for unknown chains (so caller can handle gracefully)
    function _getChainNameFromLatestJson(string memory, uint64 chainId) internal pure returns (string memory) {
        string memory name = _getChainName(chainId);
        // Return empty for "Unknown" so caller handles missing chains gracefully
        if (keccak256(bytes(name)) == keccak256(bytes("Unknown"))) {
            return "";
        }
        return name;
    }

    /// @notice Hook registration result codes
    /*//////////////////////////////////////////////////////////////
                              HOOK REGISTRY
    //////////////////////////////////////////////////////////////*/

    /// @notice v2-core deployment-JSON keys of every hook that must be registered in SuperGovernor
    /// @dev Source of truth (2026-09-10): the union of the hooks registered on the Ethereum and Base
    ///      SuperGovernors (getRegisteredHooks), resolved to their CURRENT contract names in the
    ///      v2-core output files. Older hook versions that remain registered on those chains under a
    ///      superseded address are intentionally NOT re-registered elsewhere - only the address the
    ///      core JSON currently maps to a name is used. A key that is missing from a chain's core JSON
    ///      (hook not deployed there) is skipped, so this list is safe to run on every chain.
    ///      Excluded on purpose: PendleRouterSwapHook (moved to hooks/swappers/pendle/deprecated in
    ///      v2-core; Base/Ethereum only carry its superseded address). The following keys are, as of
    ///      2026-09-10, registered on Base/Ethereum ONLY under superseded addresses - their current
    ///      address gets registered on new chains for name-parity: ApproveAndDeposit5115VaultHook,
    ///      BatchTransferFromHook, BatchTransferHook, Deposit5115VaultHook, PendleRouterRedeemHook,
    ///      RecordRedemptionPendlePTAmortizedOracleHook, Redeem5115VaultHook, SwapOdosV2Hook.
    ///      To add a hook: append its JSON key here; nothing else needs to change.
    function _hookKeys() internal pure returns (string[] memory keys) {
        keys = new string[](59);
        keys[0] = "AcrossSendFundsAndExecuteOnDstHook";
        keys[1] = "ApproveAndAcrossSendFundsAndExecuteOnDstHook";
        keys[2] = "ApproveAndAcrossSendFundsAndExecuteOnDstHookV2";
        keys[3] = "ApproveAndDeposit4626VaultHook";
        keys[4] = "ApproveAndDeposit5115VaultHook";
        keys[5] = "ApproveAndRequestDeposit7540VaultHook";
        keys[6] = "ApproveAndStargateSendHookV2";
        keys[7] = "ApproveAndSwapKyberSwapHook";
        keys[8] = "ApproveAndSwapOdosV2Hook";
        keys[9] = "ApproveAndSwapOdosV3Hook";
        keys[10] = "ApproveERC20Hook";
        keys[11] = "BatchTransferFromHook";
        keys[12] = "BatchTransferHook";
        keys[13] = "CancelDepositRequest7540Hook";
        keys[14] = "CancelDepositRequestWithId7540Hook";
        keys[15] = "CancelRedeemRequest7540Hook";
        keys[16] = "CancelRedeemRequestWithId7540Hook";
        keys[17] = "CircleGatewayWalletHook";
        keys[18] = "ClaimCancelDepositRequest7540Hook";
        keys[19] = "ClaimCancelDepositRequestWithId7540Hook";
        keys[20] = "ClaimCancelRedeemRequest7540Hook";
        keys[21] = "ClaimCancelRedeemRequestWithId7540Hook";
        keys[22] = "Deposit4626VaultHook";
        keys[23] = "Deposit5115VaultHook";
        keys[24] = "Deposit7540VaultHook";
        keys[25] = "FetchNativeFeeHook";
        keys[26] = "ForceDeallocateMorphoHook";
        keys[27] = "MerklClaimRewardHook";
        keys[28] = "MetaMorphoReallocateHook";
        keys[29] = "MorphoBorrowHook";
        keys[30] = "MorphoLendHook";
        keys[31] = "MorphoRepayAndWithdrawHook";
        keys[32] = "MorphoRepayHook";
        keys[33] = "MorphoSupplyAndBorrowHook";
        keys[34] = "MorphoSupplyHook";
        keys[35] = "MorphoWithdrawHook";
        keys[36] = "PendlePTHook";
        keys[37] = "PendleRouterRedeemHook";
        keys[38] = "PendleUnifiedHook";
        keys[39] = "RecordPurchasePendlePTAmortizedOracleHook";
        keys[40] = "RecordPurchasePendlePTAmortizedOracleHookV2";
        keys[41] = "RecordPurchasePendlePTHook";
        keys[42] = "RecordRedemptionPendlePTAmortizedOracleHook";
        keys[43] = "RecordRedemptionPendlePTAmortizedOracleHookV2";
        keys[44] = "RecordRedemptionPendlePTHook";
        keys[45] = "Redeem4626VaultHook";
        keys[46] = "Redeem5115VaultHook";
        keys[47] = "Redeem7540VaultHook";
        keys[48] = "RedeemWithId7540VaultHook";
        keys[49] = "RequestDeposit7540VaultHook";
        keys[50] = "RequestRedeem7540VaultHook";
        keys[51] = "SetOperator7540Hook";
        keys[52] = "Swap1InchHook";
        keys[53] = "SwapKyberSwapHook";
        keys[54] = "SwapOdosV2Hook";
        keys[55] = "TransferERC20Hook";
        keys[56] = "TransferHook";
        keys[57] = "Withdraw7540VaultHook";
        keys[58] = "WithdrawWithId7540VaultHook";
    }

    /// @notice Register every hook in _hookKeys() whose address is present in the core JSON
    /// @param superGovernor The SuperGovernor to register with
    /// @param coreJson The chain's v2-core deployment JSON (may be empty -> everything "not deployed")
    function _registerAllHooks(address superGovernor, string memory coreJson) internal {
        ISuperGovernor governor = ISuperGovernor(superGovernor);
        string[] memory keys = _hookKeys();
        uint256 newlyRegistered = 0;
        uint256 alreadyRegistered = 0;
        uint256 notDeployed = 0;
        uint256 failed = 0;

        console2.log("Registering hooks with SuperGovernor...");
        console2.log("Hook keys in registry:", keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            address hookAddr = bytes(coreJson).length == 0
                ? address(0)
                : _safeParseJsonAddress(coreJson, string(abi.encodePacked(".", keys[i])));
            uint256 result = _registerHook(governor, hookAddr, keys[i]);
            (newlyRegistered, alreadyRegistered, notDeployed, failed) =
                _updateCounts(result, newlyRegistered, alreadyRegistered, notDeployed, failed);
        }

        console2.log("");
        console2.log("=== Hook Registration Summary ===");
        console2.log("Total hooks processed:", keys.length);
        console2.log("- Newly registered:", newlyRegistered);
        console2.log("- Already registered (skipped):", alreadyRegistered);
        console2.log("- Not deployed on chain:", notDeployed);
        console2.log("- Failed:", failed);
    }

    uint256 internal constant HOOK_NOT_DEPLOYED = 0;
    uint256 internal constant HOOK_NEWLY_REGISTERED = 1;
    uint256 internal constant HOOK_ALREADY_REGISTERED = 2;
    uint256 internal constant HOOK_REGISTRATION_FAILED = 3;

    /// @notice Update hook registration counts based on result
    function _updateCounts(
        uint256 result,
        uint256 newlyRegistered,
        uint256 alreadyRegistered,
        uint256 notDeployed,
        uint256 failed
    )
        internal
        pure
        returns (uint256, uint256, uint256, uint256)
    {
        if (result == HOOK_NEWLY_REGISTERED) {
            return (newlyRegistered + 1, alreadyRegistered, notDeployed, failed);
        } else if (result == HOOK_ALREADY_REGISTERED) {
            return (newlyRegistered, alreadyRegistered + 1, notDeployed, failed);
        } else if (result == HOOK_NOT_DEPLOYED) {
            return (newlyRegistered, alreadyRegistered, notDeployed + 1, failed);
        } else {
            return (newlyRegistered, alreadyRegistered, notDeployed, failed + 1);
        }
    }

    /// @notice Register a single hook with SuperGovernor
    /// @return Result code: 0=not deployed, 1=newly registered, 2=already registered, 3=failed
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
            return HOOK_NOT_DEPLOYED;
        }

        // Check if hook is already registered
        if (governor.isHookRegistered(hookAddress)) {
            console2.log("SKIP: %s already registered at %s", hookName, hookAddress);
            return HOOK_ALREADY_REGISTERED;
        }

        try governor.registerHook(hookAddress) {
            console2.log("SUCCESS: Registered %s at %s", hookName, hookAddress);
            return HOOK_NEWLY_REGISTERED;
        } catch Error(string memory reason) {
            console2.log("FAILED: %s registration failed - %s", hookName, reason);
            return HOOK_REGISTRATION_FAILED;
        } catch {
            console2.log("FAILED: %s registration failed - unknown error", hookName);
            return HOOK_REGISTRATION_FAILED;
        }
    }
}
