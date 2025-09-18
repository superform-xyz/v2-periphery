// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { PeripheryHelpers } from "./utils/PeripheryHelpers.sol";
import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

// Import core BaseTest
import { BaseTest as CoreBaseTest } from "@superform-v2-core/test/BaseTest.t.sol";
import { ISuperLedgerConfiguration } from "@superform-v2-core/src/interfaces/accounting/ISuperLedgerConfiguration.sol";
// Periphery-specific imports
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { SuperBank } from "../src/SuperBank.sol";
import { SuperOracle } from "../src/oracles/SuperOracle.sol";
import { SuperVaultAggregator } from "../src/SuperVault/SuperVaultAggregator.sol";
import { SuperVault } from "../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../src/SuperVault/SuperVaultEscrow.sol";
import { ECDSAPPSOracle } from "../src/oracles/ECDSAPPSOracle.sol";

// Mock contracts for address prediction
import { Mock4626Vault } from "./mocks/Mock4626Vault.sol";
import { RuggableVault } from "./mocks/RuggableVault.sol";
import { RuggableConvertVault } from "./mocks/RuggableConvertVault.sol";
import { MockNativeETHHook } from "./mocks/MockNativeETHHook.sol";
import { MockETHReceiver } from "./mocks/MockETHReceiver.sol";
import { Create2 } from "openzeppelin-contracts/contracts/utils/Create2.sol";

import "forge-std/console2.sol";

struct PeripheryAddresses {
    SuperGovernor superGovernor;
    SuperBank superBank;
    SuperOracle oracleRegistry;
    SuperVaultAggregator superVaultAggregator;
    ECDSAPPSOracle ecdsappsOracle;
    MockNativeETHHook mockNativeETHHook;
    MockETHReceiver mockETHReceiver;
}

contract BaseTest is PeripheryHelpers, CoreBaseTest {
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                           PERIPHERY STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Constants for test vault deployment
    string constant TEST_SALT = "TEST";

    // Global addresses for SuperVault strategies
    address public globalSVStrategy;
    address public globalSVGearStrategy;
    address public globalRuggableVault;
    address public globalSV5115Strategy;


    // Test vault addresses for deterministic testing
    address public test1_DynamicAllocation_MockVault;
    address public test3_UnderlyingVaults_StressTest;
    address public test6_yieldAccumulation_vault1;
    address public test6_yieldAccumulation_vault2;

    address public test6_yieldAccumulation_vault3;
    address public test6_yieldAccumulation_WithRebalancing_vault1;
    address public test6_yieldAccumulation_WithRebalancing_vault2;
    address public test6_yieldAccumulation_WithRebalancing_vault3;
    address public test10_RuggableVault_Deposit;
    address public test10_RuggableVault_Withdraw;
    address public test10_RuggableVault_Withdraw_ConvertDistortion;
    address public test11_Allocate_NewYieldSource;

    address public test1_SuperVault_5115_ReAllocateFrom4626To5115_Vault1;
    address public test2_SuperVault_5115_ReAllocateFrom4626To5115_Vault2;

    // Periphery-specific merkle hooks
    address[] public globalMerkleHooksPeriphery;
    string[] public globalMerkleHookNamesPeriphery;

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Call core setup first
        super.setUp();
        deployPeripheryAccounts();

        // Deploy periphery contracts
        PeripheryAddresses[] memory PA = new PeripheryAddresses[](chainIds.length);
        PA = _deployPeripheryContracts(PA);

        // Update treasury in SuperLedgerConfiguration to point to SuperBank
        _updateTreasuryInSuperLedgerConfiguration();

        // Configure periphery
        _configurePeripheryGovernor(PA);

        // Register periphery hooks
        _registerPeripheryHooks(PA);
    }

    /*//////////////////////////////////////////////////////////////
                          PERIPHERY DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    function _deployPeripheryContracts(PeripheryAddresses[] memory PA) internal returns (PeripheryAddresses[] memory) {
        for (uint256 i = 0; i < chainIds.length; ++i) {
            vm.selectFork(FORKS[chainIds[i]]);

            // Use 0xDEAD as placeholder for chains where Polymer prover is not available
            address proverAddress = POLYMER_PROVER[chainIds[i]];
            if (proverAddress == address(0)) {
                proverAddress = address(0xDEAD);
            }

            PA[i].superGovernor =
                new SuperGovernor{ salt: SALT }(address(this), address(this), address(this), address(this), TREASURY, proverAddress);
            vm.label(address(PA[i].superGovernor), SUPER_GOVERNOR_KEY);
            contractAddresses[chainIds[i]][SUPER_GOVERNOR_KEY] = address(PA[i].superGovernor);

            PA[i].superBank = new SuperBank{ salt: SALT }(address(PA[i].superGovernor));
            vm.label(address(PA[i].superBank), SUPER_BANK_KEY);
            contractAddresses[chainIds[i]][SUPER_BANK_KEY] = address(PA[i].superBank);

            // Update TREASURY to point to SuperBank
            TREASURY = address(PA[i].superBank);

            PA[i].oracleRegistry = new SuperOracle{ salt: SALT }(
                address(this), new address[](0), new address[](0), new bytes32[](0), new address[](0)
            );
            vm.label(address(PA[i].oracleRegistry), SUPER_ORACLE_KEY);
            contractAddresses[chainIds[i]][SUPER_ORACLE_KEY] = address(PA[i].oracleRegistry);

            PA[i].ecdsappsOracle =
                new ECDSAPPSOracle(address(PA[i].superGovernor), ECDSAPPS_ORACLE_KEY, ECDSAPPS_ORACLE_VERSION);
            vm.label(address(PA[i].ecdsappsOracle), ECDSAPPS_ORACLE_KEY);
            contractAddresses[chainIds[i]][ECDSAPPS_ORACLE_KEY] = address(PA[i].ecdsappsOracle);

            // Deploy implementation contracts first
            address vaultImpl = address(new SuperVault(address(PA[i].superGovernor)));
            address strategyImpl = address(new SuperVaultStrategy(address(PA[i].superGovernor)));
            address escrowImpl = address(new SuperVaultEscrow());

            PA[i].superVaultAggregator =
                new SuperVaultAggregator(address(PA[i].superGovernor), vaultImpl, strategyImpl, escrowImpl);
            vm.label(address(PA[i].superVaultAggregator), SUPER_VAULT_AGGREGATOR_KEY);
            contractAddresses[chainIds[i]][SUPER_VAULT_AGGREGATOR_KEY] = address(PA[i].superVaultAggregator);

            if (chainIds[i] == ETH) {
                /// @dev set any new sv addresses here
                address aggregator = address(PA[i].superVaultAggregator);
                globalSVStrategy = SuperVaultAggregator(aggregator).STRATEGY_IMPLEMENTATION()
                    .predictDeterministicAddress(
                    keccak256(
                        abi.encode(
                            SV_MANAGER, existingUnderlyingTokens[ETH][USDC_KEY], "SuperVault", "SV_USDC", uint256(0)
                        )
                    ),
                    aggregator
                );
                globalSVGearStrategy = SuperVaultAggregator(aggregator).STRATEGY_IMPLEMENTATION()
                    .predictDeterministicAddress(
                    keccak256(
                        abi.encode(
                            SV_MANAGER, existingUnderlyingTokens[ETH][USDC_KEY], "SuperVault", "svGearbox", uint256(1)
                        )
                    ),
                    aggregator
                );

                globalRuggableVault = SuperVaultAggregator(aggregator).STRATEGY_IMPLEMENTATION()
                    .predictDeterministicAddress(
                    keccak256(
                        abi.encode(
                            SV_MANAGER, existingUnderlyingTokens[ETH][USDC_KEY], "SuperVault", "SV_USDC_RUG", uint256(1)
                        )
                    ),
                    aggregator
                );

                globalSV5115Strategy = SuperVaultAggregator(aggregator).STRATEGY_IMPLEMENTATION()
                    .predictDeterministicAddress(
                    keccak256(
                        abi.encode(
                            //SV_MANAGER, existingUnderlyingTokens[ETH][USDE_KEY], "SuperVault", "sv5115", uint256(1)
                            SV_MANAGER, CHAIN_1_SUSDE, "SuperVault", "sv5115", uint256(1)
                        )
                    ),
                    aggregator
                );


                // Deploy MockETHReceiver first (needed for MockNativeETHHook constructor) - ETH only
                PA[i].mockETHReceiver = new MockETHReceiver{ salt: SALT }(existingUnderlyingTokens[ETH][USDC_KEY]);
                vm.label(address(PA[i].mockETHReceiver), "MOCK_ETH_RECEIVER");
                contractAddresses[ETH]["MOCK_ETH_RECEIVER"] = address(PA[i].mockETHReceiver);

                // Deploy MockNativeETHHook for testing native ETH handling - ETH only
                PA[i].mockNativeETHHook = new MockNativeETHHook{ salt: SALT }(address(PA[i].mockETHReceiver));
                vm.label(address(PA[i].mockNativeETHHook), "MOCK_NATIVE_ETH_HOOK");
                contractAddresses[ETH]["MOCK_NATIVE_ETH_HOOK"] = address(PA[i].mockNativeETHHook);

                // Predict test vault addresses
                _predictTestVaultAddresses();
            }

            // Set up governor configurations
            PA[i].superGovernor.setActivePPSOracle(address(PA[i].ecdsappsOracle));
            PA[i].superGovernor.addValidator(VALIDATOR);
        }
        return PA;
    }

    /// @notice Predicts CREATE2 addresses for test vaults used in integration tests
    /// @dev Uses Create2.deploy() method for consistent prediction and deployment
    function _predictTestVaultAddresses() internal {
        address deployer = address(this);
        address assetAddress = existingUnderlyingTokens[ETH][USDC_KEY];

        // Test 1: DynamicAllocation MockVault - uses salt "TEST"
        test1_DynamicAllocation_MockVault =
            _predictMock4626VaultAddress(deployer, assetAddress, "New Vault", "NV", TEST_SALT);

        // Test 3: UnderlyingVaults StressTest (RuggableVault) - uses salt "TEST"
        test3_UnderlyingVaults_StressTest = _predictRuggableVaultAddress(
            deployer,
            assetAddress,
            "Ruggable Vault",
            "RUG",
            true, // rug on deposit
            true, // rug on withdraw
            10, // rug percentage
            TEST_SALT
        );

        // Test 6: yieldAccumulation vaults - use salt "TEST"
        test6_yieldAccumulation_vault1 =
            _predictMock4626VaultAddress(deployer, assetAddress, "Mock4626Vault 3%", "MV3", TEST_SALT);
        test6_yieldAccumulation_vault2 =
            _predictMock4626VaultAddress(deployer, assetAddress, "Mock4626Vault 5%", "MV5", TEST_SALT);
        test6_yieldAccumulation_vault3 =
            _predictMock4626VaultAddress(deployer, assetAddress, "Mock4626Vault 10%", "MV10", TEST_SALT);

        // Test 6: yieldAccumulation WithRebalancing vaults - use salt "TEST"
        test6_yieldAccumulation_WithRebalancing_vault1 =
            _predictMock4626VaultAddress(deployer, assetAddress, "Mock Vault 3%", "MV3", TEST_SALT);
        test6_yieldAccumulation_WithRebalancing_vault2 =
            _predictMock4626VaultAddress(deployer, assetAddress, "Mock Vault 5%", "MV5", TEST_SALT);
        test6_yieldAccumulation_WithRebalancing_vault3 =
            _predictMock4626VaultAddress(deployer, assetAddress, "Mock Vault 10%", "MV10", TEST_SALT);

        // Test 10: RuggableVault tests - use salt "TEST"
        test10_RuggableVault_Deposit = _predictRuggableVaultAddress(
            deployer,
            assetAddress,
            "Ruggable Vault",
            "RUG",
            true, // rug on deposit
            false, // don't rug on withdraw
            5000, // 50% rug
            TEST_SALT
        );
        test10_RuggableVault_Withdraw = _predictRuggableVaultAddress(
            deployer,
            assetAddress,
            "Ruggable Vault",
            "RUG",
            false, // don't rug on deposit
            true, // rug on withdraw
            5000, // 50% rug
            TEST_SALT
        );
        test10_RuggableVault_Withdraw_ConvertDistortion = _predictRuggableConvertVaultAddress(
            deployer,
            assetAddress,
            "Ruggable Convert Vault",
            "RUGC",
            5000, // 50% rug
            true, // rug enabled
            TEST_SALT
        );

        // Test 11: Allocate NewYieldSource - uses salt "TEST"
        test11_Allocate_NewYieldSource =
            _predictMock4626VaultAddress(deployer, assetAddress, "New Vault", "NV", TEST_SALT);

        // Test 1: SuperVault 5115 ReAllocateFrom4626To5115 - uses salt "TEST"
        test1_SuperVault_5115_ReAllocateFrom4626To5115_Vault1 =
            _predictMock4626VaultAddress(deployer, assetAddress, "SuperVault 5115 ReAllocateFrom4626To5115 Vault1", "SV5115R1", TEST_SALT);
        test2_SuperVault_5115_ReAllocateFrom4626To5115_Vault2 =
            _predictMock4626VaultAddress(deployer, assetAddress, "SuperVault 5115 ReAllocateFrom4626To5115 Vault2", "SV5115R2", TEST_SALT);
    }

    /// @notice Updates test vault predictions with the correct deployer address
    /// @dev Should be called from test contracts where address(this) gives the actual deployer
    function updateTestVaultPredictions() public {
        _predictTestVaultAddresses();
    }

    /// @notice Predicts CREATE2 address for Mock4626Vault using same method as Create2.deploy()
    function _predictMock4626VaultAddress(
        address deployer,
        address asset,
        string memory name,
        string memory symbol,
        string memory salt
    )
        internal
        pure
        returns (address)
    {
        bytes memory bytecode = abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(asset, name, symbol));
        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 saltHash = keccak256(abi.encodePacked(salt));

        return Create2.computeAddress(saltHash, bytecodeHash, deployer);
    }

    /// @notice Predicts CREATE2 address for RuggableVault using same method as Create2.deploy()
    function _predictRuggableVaultAddress(
        address deployer,
        address asset,
        string memory name,
        string memory symbol,
        bool rugOnDeposit,
        bool rugOnWithdraw,
        uint256 rugPercentage,
        string memory salt
    )
        internal
        pure
        returns (address)
    {
        bytes memory bytecode = abi.encodePacked(
            type(RuggableVault).creationCode,
            abi.encode(asset, name, symbol, rugOnDeposit, rugOnWithdraw, rugPercentage)
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 saltHash = keccak256(abi.encodePacked(salt));
        return Create2.computeAddress(saltHash, bytecodeHash, deployer);
    }

    /// @notice Predicts CREATE2 address for RuggableConvertVault using same method as Create2.deploy()
    function _predictRuggableConvertVaultAddress(
        address deployer,
        address asset,
        string memory name,
        string memory symbol,
        uint256 rugPercentage,
        bool rugEnabled,
        string memory salt
    )
        internal
        pure
        returns (address)
    {
        bytes memory bytecode = abi.encodePacked(
            type(RuggableConvertVault).creationCode, abi.encode(asset, name, symbol, rugPercentage, rugEnabled)
        );
        bytes32 bytecodeHash = keccak256(bytecode);
        bytes32 saltHash = keccak256(abi.encodePacked(salt));
        return Create2.computeAddress(saltHash, bytecodeHash, deployer);
    }

    function _configurePeripheryGovernor(PeripheryAddresses[] memory PA) internal {
        for (uint256 i = 0; i < chainIds.length; ++i) {
            vm.selectFork(FORKS[chainIds[i]]);

            SuperGovernor superGovernor = PA[i].superGovernor;

            superGovernor.setAddress(superGovernor.SUPER_VAULT_AGGREGATOR(), address(PA[i].superVaultAggregator));

            superGovernor.setAddress(superGovernor.TREASURY(), TREASURY);
        }
    }

    /**
     * @notice Registers periphery-specific hooks with the governor
     * @param PA Array of PeripheryAddresses structs containing periphery contract addresses
     */
    function _registerPeripheryHooks(PeripheryAddresses[] memory PA) internal {
        if (DEBUG) console2.log("---------------- REGISTERING PERIPHERY HOOKS ----------------");
        for (uint256 i = 0; i < chainIds.length; ++i) {
            vm.selectFork(FORKS[chainIds[i]]);

            SuperGovernor superGovernor = PA[i].superGovernor;

            console2.log("Registering periphery hooks for chain", chainIds[i]);

            // Register fulfillRequests hooks
            superGovernor.registerHook(hookAddresses[chainIds[i]][DEPOSIT_4626_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][REDEEM_4626_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][DEPOSIT_5115_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][DEPOSIT_7540_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][REDEEM_5115_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][WITHDRAW_7540_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][REDEEM_7540_VAULT_HOOK_KEY], true);

            // Register remaining hooks
            superGovernor.registerHook(hookAddresses[chainIds[i]][APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][APPROVE_AND_DEPOSIT_5115_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(
                hookAddresses[chainIds[i]][APPROVE_AND_REQUEST_DEPOSIT_7540_VAULT_HOOK_KEY], false
            );
            superGovernor.registerHook(hookAddresses[chainIds[i]][REQUEST_DEPOSIT_7540_VAULT_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][REQUEST_REDEEM_7540_VAULT_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][APPROVE_ERC20_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][TRANSFER_ERC20_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][DEPOSIT_7540_VAULT_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][WITHDRAW_7540_VAULT_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][SWAP_1INCH_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][SWAP_ODOSV2_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][APPROVE_AND_SWAP_ODOSV2_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][ACROSS_SEND_FUNDS_AND_EXECUTE_ON_DST_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][FLUID_CLAIM_REWARD_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][FLUID_STAKE_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][APPROVE_AND_FLUID_STAKE_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][FLUID_UNSTAKE_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][GEARBOX_CLAIM_REWARD_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][GEARBOX_STAKE_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][GEARBOX_APPROVE_AND_STAKE_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][GEARBOX_UNSTAKE_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][YEARN_CLAIM_ONE_REWARD_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][CANCEL_DEPOSIT_REQUEST_7540_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][CANCEL_REDEEM_REQUEST_7540_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][CLAIM_CANCEL_DEPOSIT_REQUEST_7540_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][CLAIM_CANCEL_REDEEM_REQUEST_7540_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][CANCEL_REDEEM_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][MINT_SUPERPOSITIONS_HOOK_KEY], false);

            // Register MockNativeETHHook for testing - ETH only
            if (chainIds[i] == ETH) {
                superGovernor.registerHook(address(PA[i].mockNativeETHHook), true);

                // Initialize periphery-specific merkle hooks - include all hooks that can fulfill requests (true)
                globalMerkleHooksPeriphery = new address[](14);
                globalMerkleHooksPeriphery[0] = hookAddresses[chainIds[i]][DEPOSIT_4626_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[1] = hookAddresses[chainIds[i]][REDEEM_4626_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[2] = hookAddresses[chainIds[i]][DEPOSIT_5115_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[3] = hookAddresses[chainIds[i]][REDEEM_5115_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[4] = hookAddresses[chainIds[i]][APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[5] = hookAddresses[chainIds[i]][APPROVE_AND_DEPOSIT_5115_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[6] =
                    hookAddresses[chainIds[i]][APPROVE_AND_REQUEST_DEPOSIT_7540_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[7] = hookAddresses[chainIds[i]][DEPOSIT_7540_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[8] = address(PA[i].mockNativeETHHook);
                // Add missing hooks from globalMerkleHooks
                globalMerkleHooksPeriphery[9] = hookAddresses[chainIds[i]][GEARBOX_APPROVE_AND_STAKE_HOOK_KEY];
                globalMerkleHooksPeriphery[10] = hookAddresses[chainIds[i]][GEARBOX_UNSTAKE_HOOK_KEY];
                globalMerkleHooksPeriphery[11] = hookAddresses[chainIds[i]][WITHDRAW_7540_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[12] = hookAddresses[chainIds[i]][REDEEM_7540_VAULT_HOOK_KEY];
                globalMerkleHooksPeriphery[13] = hookAddresses[chainIds[i]][REQUEST_REDEEM_7540_VAULT_HOOK_KEY];

                globalMerkleHookNamesPeriphery = new string[](14);
                globalMerkleHookNamesPeriphery[0] = "DEPOSIT_4626_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[1] = "REDEEM_4626_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[2] = "DEPOSIT_5115_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[3] = "REDEEM_5115_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[4] = "APPROVE_AND_DEPOSIT_4626_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[5] = "APPROVE_AND_DEPOSIT_5115_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[6] = "APPROVE_AND_REQUEST_DEPOSIT_7540_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[7] = "DEPOSIT_7540_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[8] = "MOCK_NATIVE_ETH_HOOK";
                globalMerkleHookNamesPeriphery[9] = "APPROVE_AND_GEARBOX_STAKE_HOOK";
                globalMerkleHookNamesPeriphery[10] = "GEARBOX_UNSTAKE_HOOK";
                globalMerkleHookNamesPeriphery[11] = "WITHDRAW_7540_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[12] = "REDEEM_7540_VAULT_HOOK";
                globalMerkleHookNamesPeriphery[13] = "REQUEST_REDEEM_7540_VAULT_HOOK";
            }

            // EXPERIMENTAL HOOKS FROM HERE ONWARDS
            superGovernor.registerHook(hookAddresses[chainIds[i]][ETHENA_COOLDOWN_SHARES_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][ETHENA_UNSTAKE_HOOK_KEY], true);
            superGovernor.registerHook(hookAddresses[chainIds[i]][MORPHO_BORROW_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][MORPHO_REPAY_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][MORPHO_REPAY_AND_WITHDRAW_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][PENDLE_ROUTER_REDEEM_HOOK_KEY], false);
            superGovernor.registerHook(hookAddresses[chainIds[i]][OFFRAMP_TOKENS_HOOK_KEY], false);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          PERIPHERY GETTERS
    //////////////////////////////////////////////////////////////*/

    function _getPeripheryContract(uint64 chainId, string memory contractName) internal view returns (address) {
        return contractAddresses[chainId][contractName];
    }

    /*//////////////////////////////////////////////////////////////
                         HELPERS
    //////////////////////////////////////////////////////////////*/

    function _updateTreasuryInSuperLedgerConfiguration() internal {
        for (uint256 i = 0; i < chainIds.length; ++i) {
            vm.selectFork(FORKS[chainIds[i]]);

            // Get the yield source oracle IDs that were created in _setupSuperLedger
            bytes32[] memory yieldSourceOracleIds = new bytes32[](4);
            yieldSourceOracleIds[0] =
                keccak256(abi.encodePacked(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER));
            yieldSourceOracleIds[1] =
                keccak256(abi.encodePacked(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER));
            yieldSourceOracleIds[2] =
                keccak256(abi.encodePacked(bytes32(bytes(ERC5115_YIELD_SOURCE_ORACLE_KEY)), MANAGER));
            yieldSourceOracleIds[3] =
                keccak256(abi.encodePacked(bytes32(bytes(STAKING_YIELD_SOURCE_ORACLE_KEY)), MANAGER));

            // Read current configs to preserve existing settings
            ISuperLedgerConfiguration.YieldSourceOracleConfig[] memory currentConfigs = ISuperLedgerConfiguration(
                _getContract(chainIds[i], SUPER_LEDGER_CONFIGURATION_KEY)
            ).getYieldSourceOracleConfigs(yieldSourceOracleIds);

            // Create new config proposals with updated treasury
            ISuperLedgerConfiguration.YieldSourceOracleConfigArgs[] memory newConfigs =
                new ISuperLedgerConfiguration.YieldSourceOracleConfigArgs[](4);

            newConfigs[0] = ISuperLedgerConfiguration.YieldSourceOracleConfigArgs({
                yieldSourceOracle: currentConfigs[0].yieldSourceOracle,
                feePercent: currentConfigs[0].feePercent,
                feeRecipient: TREASURY, // Updated treasury (SuperBank)
                ledger: currentConfigs[0].ledger
            });
            newConfigs[1] = ISuperLedgerConfiguration.YieldSourceOracleConfigArgs({
                yieldSourceOracle: currentConfigs[1].yieldSourceOracle,
                feePercent: currentConfigs[1].feePercent,
                feeRecipient: TREASURY, // Updated treasury (SuperBank)
                ledger: currentConfigs[1].ledger
            });
            newConfigs[2] = ISuperLedgerConfiguration.YieldSourceOracleConfigArgs({
                yieldSourceOracle: currentConfigs[2].yieldSourceOracle,
                feePercent: currentConfigs[2].feePercent,
                feeRecipient: TREASURY, // Updated treasury (SuperBank)
                ledger: currentConfigs[2].ledger
            });
            newConfigs[3] = ISuperLedgerConfiguration.YieldSourceOracleConfigArgs({
                yieldSourceOracle: currentConfigs[3].yieldSourceOracle,
                feePercent: currentConfigs[3].feePercent,
                feeRecipient: TREASURY, // Updated treasury (SuperBank)
                ledger: currentConfigs[3].ledger
            });

            vm.startPrank(MANAGER);

            // Propose the configuration changes
            ISuperLedgerConfiguration(_getContract(chainIds[i], SUPER_LEDGER_CONFIGURATION_KEY))
                .proposeYieldSourceOracleConfig(yieldSourceOracleIds, newConfigs);

            vm.stopPrank();

            // Advance time past the proposal expiration period (1 week)
            vm.warp(block.timestamp + 1 weeks + 1);

            vm.startPrank(MANAGER);

            // Accept the proposed configuration changes
            ISuperLedgerConfiguration(_getContract(chainIds[i], SUPER_LEDGER_CONFIGURATION_KEY))
                .acceptYieldSourceOracleConfigProposal(yieldSourceOracleIds);

            vm.stopPrank();
        }
    }
}
