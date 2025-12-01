// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperVaultAggregator } from "../../../src/SuperVault/SuperVaultAggregator.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperOracleL2 } from "../../../src/oracles/SuperOracleL2.sol";
import { FixedPriceOracle } from "../../../src/oracles/FixedPriceOracle.sol";
import { ECDSAPPSOracle } from "../../../src/oracles/ECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { ISuperBank } from "../../../src/interfaces/ISuperBank.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { TransferERC20Hook } from "@superform-v2-core/src/hooks/tokens/erc20/TransferERC20Hook.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";

/// @title UpdatePPSUpkeepIntegrationBaseTest
/// @notice Integration test on Base for the full upkeep flow:
///         depositUpkeep -> PPS update -> upkeep moves to claimable -> claim moves to SuperBank
/// @dev Deploys fresh contracts on Base fork with real Base oracles
contract UpdatePPSUpkeepIntegrationBaseTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Base Chainlink oracle addresses
    address constant ORACLE_ETH_USD_BASE = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    address constant ORACLE_SEQUENCER_UPTIME_BASE = 0xBCF85224fc0756B9Fa45aA7892530B47e10b6433;

    // Base chain constants
    address constant WETH_BASE = 0x4200000000000000000000000000000000000006; // UPKEEP_TOKEN on Base
    address constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Native USDC on Base

    // Oracle constants (must match SuperGovernor)
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // UPKEEP_TOKEN price configuration (WETH priced in USD)
    int256 constant INITIAL_WETH_PRICE = 3000e18; // $3000 with 18 decimals
    uint8 constant WETH_PRICE_DECIMALS = 18;

    // Gas price configuration (for GAS->WEI oracle)
    // Chainlink Fast Gas oracle returns gas price in gwei with 18 decimals
    // So 30 gwei = 30 * 10^18 in the oracle format
    int256 constant GAS_PRICE_GWEI = 30e18; // 30 gwei represented with 18 decimals
    uint8 constant GAS_PRICE_DECIMALS = 18; // Same as Chainlink Fast Gas oracle

    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");

    // Contracts
    SuperGovernor public governor;
    SuperVaultAggregator public aggregator;
    SuperOracleL2 public superOracle;
    FixedPriceOracle public fixedPriceOracle; // WETH/USD oracle
    FixedPriceOracle public gasPriceOracle; // GAS/WEI oracle
    ECDSAPPSOracle public ecdsaOracle;
    SuperBank public superBank;

    // Test accounts
    address public deployer;
    address public manager;
    address public treasury;
    address public validator1;
    address public validator2;
    uint256 public validator1PrivateKey = 0x1234;
    uint256 public validator2PrivateKey = 0x5678;

    // Strategy
    address public strategy;
    address public vault;

    // Hook for SuperBank transfers
    TransferERC20Hook public transferHook;

    // Constants
    uint256 constant GAS_PER_ENTRY = 60_000;
    uint256 constant PPS = 1e6; // 1.0 in 6 decimals
    // Pin fork to a specific block for deterministic oracle prices
    uint256 constant FORK_BLOCK = 23_000_000;

    function setUp() public {
        // Fork Base at a specific block for deterministic tests
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), FORK_BLOCK);

        deployer = makeAddr("deployer");
        manager = makeAddr("manager");
        treasury = makeAddr("treasury");
        validator1 = vm.addr(validator1PrivateKey);
        validator2 = vm.addr(validator2PrivateKey);

        vm.startPrank(deployer);

        // Deploy SuperGovernor with deployer as all roles initially
        // upkeepPaymentsEnabled = false for L2s (we'll enable it for test)
        governor = new SuperGovernor(deployer, deployer, deployer, deployer, deployer, deployer, treasury, false);

        // Deploy implementation contracts
        address vaultImpl = address(new SuperVault(address(governor)));
        address strategyImpl = address(new SuperVaultStrategy(address(governor)));
        address escrowImpl = address(new SuperVaultEscrow());

        // Deploy SuperVaultAggregator
        aggregator = new SuperVaultAggregator(address(governor), vaultImpl, strategyImpl, escrowImpl);

        // Deploy SuperBank
        superBank = new SuperBank(address(governor));

        // Deploy FixedPriceOracle for WETH/USD (UPKEEP_TOKEN price)
        fixedPriceOracle = new FixedPriceOracle(INITIAL_WETH_PRICE, WETH_PRICE_DECIMALS, deployer);

        // Deploy FixedPriceOracle for GAS/WEI (gas price - no Chainlink gas oracle on Base)
        gasPriceOracle = new FixedPriceOracle(GAS_PRICE_GWEI, GAS_PRICE_DECIMALS, deployer);

        // Deploy SuperOracleL2 with Base feeds
        _deploySuperOracle();

        // Deploy ECDSAPPSOracle
        ecdsaOracle = new ECDSAPPSOracle(address(governor), "ECDSAPPS", "1");

        // Configure SuperGovernor
        _configureGovernor();

        // Create a vault and strategy
        _createVaultAndStrategy();

        // Deploy TransferERC20Hook for SuperBank operations
        transferHook = new TransferERC20Hook();

        // Register the hook with SuperGovernor
        governor.registerHook(address(transferHook));

        vm.stopPrank();
    }

    function _deploySuperOracle() internal {
        // Configure 3 feeds: GAS->WEI, ETH->USD, UPKEEP_TOKEN(WETH)->USD
        address[] memory bases = new address[](3);
        address[] memory quotes = new address[](3);
        bytes32[] memory providers = new bytes32[](3);
        address[] memory feeds = new address[](3);

        // Feed 1: GAS -> WEI (gas price oracle - using FixedPriceOracle since no Chainlink gas oracle on Base)
        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_SUPERFORM;
        feeds[0] = address(gasPriceOracle);

        // Feed 2: ETH -> USD (using Chainlink on Base)
        bases[1] = NATIVE_TOKEN;
        quotes[1] = USD_TOKEN;
        providers[1] = PROVIDER_CHAINLINK;
        feeds[1] = ORACLE_ETH_USD_BASE;

        // Feed 3: WETH (UPKEEP_TOKEN) -> USD (using FixedPriceOracle)
        bases[2] = WETH_BASE;
        quotes[2] = USD_TOKEN;
        providers[2] = PROVIDER_SUPERFORM;
        feeds[2] = address(fixedPriceOracle);

        superOracle = new SuperOracleL2(
            address(governor),
            bases,
            quotes,
            providers,
            feeds
        );

    }

    function _configureGovernor() internal {
        // Set SuperVaultAggregator
        governor.setAddress(governor.SUPER_VAULT_AGGREGATOR(), address(aggregator));

        // Set SuperOracle
        governor.setAddress(governor.SUPER_ORACLE(), address(superOracle));

        // Configure uptime feeds for L2 oracle - required by SuperOracleL2
        {
            address[] memory dataOracles = new address[](3);
            dataOracles[0] = address(gasPriceOracle);
            dataOracles[1] = ORACLE_ETH_USD_BASE;
            dataOracles[2] = address(fixedPriceOracle);

            address[] memory uptimeOracles = new address[](3);
            uptimeOracles[0] = ORACLE_SEQUENCER_UPTIME_BASE;
            uptimeOracles[1] = ORACLE_SEQUENCER_UPTIME_BASE;
            uptimeOracles[2] = ORACLE_SEQUENCER_UPTIME_BASE;

            // Default grace period (1 hour = 3600 seconds)
            uint256[] memory gracePeriods = new uint256[](3);
            gracePeriods[0] = 3600;
            gracePeriods[1] = 3600;
            gracePeriods[2] = 3600;

            governor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        }

        // Set SuperBank
        governor.setAddress(governor.SUPER_BANK(), address(superBank));

        // Set UPKEEP_TOKEN (WETH on Base)
        governor.setAddress(governor.UPKEEP_TOKEN(), WETH_BASE);

        // Set validators
        address[] memory validators = new address[](2);
        validators[0] = validator1;
        validators[1] = validator2;
        bytes[] memory publicKeys = new bytes[](2);
        publicKeys[0] = "";
        publicKeys[1] = "";

        governor.setValidatorConfig(1, validators, publicKeys, 2, "");

        // Set gas info for oracle
        governor.setGasInfo(address(ecdsaOracle), GAS_PER_ENTRY);

        // Activate PPS Oracle
        governor.proposeActivePPSOracle(address(ecdsaOracle));
        vm.warp(block.timestamp + 7 days);
        governor.executeActivePPSOracleChange();

        // Enable upkeep payments
        governor.proposeUpkeepPaymentsChange(true);
        vm.warp(block.timestamp + 8 days);
        governor.executeUpkeepPaymentsChange();

        // Increase oracle staleness tolerance to account for time warps (15+ days)
        governor.setOracleMaxStaleness(30 days);

        address[] memory feedAddresses = new address[](3);
        feedAddresses[0] = address(gasPriceOracle);
        feedAddresses[1] = ORACLE_ETH_USD_BASE;
        feedAddresses[2] = address(fixedPriceOracle);

        uint256[] memory staleness = new uint256[](3);
        staleness[0] = 30 days;
        staleness[1] = 30 days;
        staleness[2] = 30 days;

        governor.setOracleFeedMaxStalenessBatch(feedAddresses, staleness);
    }

    function _createVaultAndStrategy() internal {
        (, address strat,) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: USDC_BASE,
                name: "Test Vault Base",
                symbol: "TVB",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000,
                    managementFeeBps: 0,
                    recipient: treasury
                })
            })
        );

        strategy = strat;
    }

    /// @notice Test the full upkeep flow:
    /// depositUpkeep -> PPS update -> upkeep moves to claimable -> claim moves to SuperBank
    function test_FullUpkeepFlow_DepositUpdateClaimToSuperBank() public {
        // Step 1: Get upkeep cost and fund the manager with WETH
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        console2.log(" -- Gas info: ", governor.getGasInfo(address(ecdsaOracle)));
        console2.log("=== Step 1: Get upkeep cost ===");
        console2.log("Upkeep cost per entry (in WETH):", upkeepCost);

        // Verify upkeep cost is reasonable
        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");

        // Deal WETH to manager (10x the cost for safety)
        uint256 depositAmount = upkeepCost * 10;
        deal(WETH_BASE, manager, depositAmount);

        // Step 2: Manager deposits upkeep tokens
        console2.log("=== Step 2: Deposit upkeep ===");
        vm.startPrank(manager);
        IERC20(WETH_BASE).approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        uint256 strategyUpkeepAfterDeposit = aggregator.getUpkeepBalance(strategy);
        console2.log("Strategy upkeep balance after deposit:", strategyUpkeepAfterDeposit);
        assertEq(strategyUpkeepAfterDeposit, depositAmount, "Strategy upkeep should equal deposit amount");

        // Record state before PPS update
        uint256 claimableUpkeepBefore = aggregator.claimableUpkeep();
        uint256 superBankBalanceBefore = IERC20(WETH_BASE).balanceOf(address(superBank));
        console2.log("Claimable upkeep before PPS update:", claimableUpkeepBefore);
        console2.log("SuperBank WETH balance before:", superBankBalanceBefore);

        // Step 3: Run PPS update - this should deduct upkeep from strategy and add to claimable
        console2.log("=== Step 3: Run PPS update ===");

        // Move time forward to ensure timestamp > lastUpdateTimestamp
        vm.warp(block.timestamp + 10);

        // Create valid proofs and call updatePPS
        bytes[] memory proofs = _createValidProofs(strategy, PPS, block.timestamp);

        address[] memory strategies = new address[](1);
        strategies[0] = strategy;

        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        ecdsaOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );

        // Verify upkeep was moved from strategy to claimable
        uint256 strategyUpkeepAfterUpdate = aggregator.getUpkeepBalance(strategy);
        uint256 claimableUpkeepAfterUpdate = aggregator.claimableUpkeep();

        console2.log("Strategy upkeep after PPS update:", strategyUpkeepAfterUpdate);
        console2.log("Claimable upkeep after PPS update:", claimableUpkeepAfterUpdate);
        console2.log("Upkeep deducted from strategy:", strategyUpkeepAfterDeposit - strategyUpkeepAfterUpdate);
        console2.log("Upkeep added to claimable:", claimableUpkeepAfterUpdate - claimableUpkeepBefore);

        assertEq(
            strategyUpkeepAfterDeposit - strategyUpkeepAfterUpdate,
            upkeepCost,
            "Strategy upkeep should decrease by upkeep cost"
        );
        assertEq(
            claimableUpkeepAfterUpdate - claimableUpkeepBefore,
            upkeepCost,
            "Claimable upkeep should increase by upkeep cost"
        );

        // Step 4: Governor claims upkeep - this should move tokens to SuperBank
        console2.log("=== Step 4: Claim upkeep to SuperBank ===");

        uint256 claimAmount = claimableUpkeepAfterUpdate;
        vm.prank(deployer);
        governor.executeUpkeepClaim(claimAmount);

        // Verify tokens moved to SuperBank
        uint256 claimableUpkeepAfterClaim = aggregator.claimableUpkeep();
        uint256 superBankBalanceAfter = IERC20(WETH_BASE).balanceOf(address(superBank));

        console2.log("Claimable upkeep after claim:", claimableUpkeepAfterClaim);
        console2.log("SuperBank WETH balance after:", superBankBalanceAfter);
        console2.log("WETH transferred to SuperBank:", superBankBalanceAfter - superBankBalanceBefore);

        assertEq(claimableUpkeepAfterClaim, 0, "Claimable upkeep should be 0 after full claim");
        assertEq(
            superBankBalanceAfter - superBankBalanceBefore,
            claimAmount,
            "SuperBank should receive claimed upkeep"
        );

        console2.log("=== Full upkeep flow completed successfully! ===");
    }

    /// @notice Test multiple PPS updates accumulate claimable upkeep
    function test_MultipleUpdates_AccumulateClaimableUpkeep() public {
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        uint256 numUpdates = 3;
        uint256 depositAmount = upkeepCost * (numUpdates + 2); // Extra buffer

        // Fund and deposit upkeep
        deal(WETH_BASE, manager, depositAmount);
        vm.startPrank(manager);
        IERC20(WETH_BASE).approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        uint256 claimableStart = aggregator.claimableUpkeep();

        // Perform multiple PPS updates
        for (uint256 i = 0; i < numUpdates; i++) {
            vm.warp(block.timestamp + 10);

            bytes[] memory proofs = _createValidProofs(strategy, PPS + i, block.timestamp);

            address[] memory strategies = new address[](1);
            strategies[0] = strategy;

            bytes[][] memory proofsArray = new bytes[][](1);
            proofsArray[0] = proofs;

            uint256[] memory ppss = new uint256[](1);
            ppss[0] = PPS + i;

            uint256[] memory timestamps = new uint256[](1);
            timestamps[0] = block.timestamp;

            ecdsaOracle.updatePPS(
                IECDSAPPSOracle.UpdatePPSArgs({
                    strategies: strategies,
                    proofsArray: proofsArray,
                    ppss: ppss,
                    timestamps: timestamps
                })
            );
        }

        uint256 claimableEnd = aggregator.claimableUpkeep();
        uint256 totalUpkeepSpent = claimableEnd - claimableStart;

        console2.log("Upkeep cost per update:", upkeepCost);
        console2.log("Number of updates:", numUpdates);
        console2.log("Total upkeep accumulated:", totalUpkeepSpent);
        console2.log("Expected total:", upkeepCost * numUpdates);

        assertEq(totalUpkeepSpent, upkeepCost * numUpdates, "Total claimable should equal upkeep cost * updates");

        // Claim all to SuperBank
        uint256 superBankBefore = IERC20(WETH_BASE).balanceOf(address(superBank));
        vm.prank(deployer);
        governor.executeUpkeepClaim(totalUpkeepSpent);
        uint256 superBankAfter = IERC20(WETH_BASE).balanceOf(address(superBank));

        assertEq(
            superBankAfter - superBankBefore,
            totalUpkeepSpent,
            "SuperBank should receive all accumulated upkeep"
        );
    }

    /// @notice Test partial claim of upkeep to SuperBank
    function test_PartialClaim_ToSuperBank() public {
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        uint256 depositAmount = upkeepCost * 5;

        // Fund and deposit
        deal(WETH_BASE, manager, depositAmount);
        vm.startPrank(manager);
        IERC20(WETH_BASE).approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        // Run 2 PPS updates
        for (uint256 i = 0; i < 2; i++) {
            vm.warp(block.timestamp + 10);
            bytes[] memory proofs = _createValidProofs(strategy, PPS + i, block.timestamp);

            address[] memory strategies = new address[](1);
            strategies[0] = strategy;
            bytes[][] memory proofsArray = new bytes[][](1);
            proofsArray[0] = proofs;
            uint256[] memory ppss = new uint256[](1);
            ppss[0] = PPS + i;
            uint256[] memory timestamps = new uint256[](1);
            timestamps[0] = block.timestamp;

            ecdsaOracle.updatePPS(
                IECDSAPPSOracle.UpdatePPSArgs({
                    strategies: strategies,
                    proofsArray: proofsArray,
                    ppss: ppss,
                    timestamps: timestamps
                })
            );
        }

        uint256 totalClaimable = aggregator.claimableUpkeep();
        uint256 partialClaim = totalClaimable / 2;

        console2.log("Total claimable:", totalClaimable);
        console2.log("Partial claim amount:", partialClaim);

        // Partial claim
        uint256 superBankBefore = IERC20(WETH_BASE).balanceOf(address(superBank));
        vm.prank(deployer);
        governor.executeUpkeepClaim(partialClaim);

        uint256 remainingClaimable = aggregator.claimableUpkeep();
        uint256 superBankAfter = IERC20(WETH_BASE).balanceOf(address(superBank));

        assertEq(remainingClaimable, totalClaimable - partialClaim, "Remaining claimable should be correct");
        assertEq(superBankAfter - superBankBefore, partialClaim, "SuperBank should receive partial claim");

        // Claim the rest
        vm.prank(deployer);
        governor.executeUpkeepClaim(remainingClaimable);

        assertEq(aggregator.claimableUpkeep(), 0, "No claimable should remain");
    }

    /// @notice Test the full upkeep flow + transfer from SuperBank to treasury via executeHooks
    /// @dev This is an extension of test_FullUpkeepFlow_DepositUpdateClaimToSuperBank
    function test_FullUpkeepFlow_WithSuperBankHookTransferToTreasury() public {
        // ============================================================
        // STEP 1-4: Same as test_FullUpkeepFlow_DepositUpdateClaimToSuperBank
        // ============================================================

        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        console2.log("=== Step 1: Get upkeep cost ===");
        console2.log("Upkeep cost per entry (in WETH):", upkeepCost);

        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");

        uint256 depositAmount = upkeepCost * 10;
        deal(WETH_BASE, manager, depositAmount);

        console2.log("=== Step 2: Deposit upkeep ===");
        vm.startPrank(manager);
        IERC20(WETH_BASE).approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        uint256 strategyUpkeepAfterDeposit = aggregator.getUpkeepBalance(strategy);
        console2.log("Strategy upkeep balance after deposit:", strategyUpkeepAfterDeposit);

        console2.log("=== Step 3: Run PPS update ===");
        vm.warp(block.timestamp + 10);

        bytes[] memory proofs = _createValidProofs(strategy, PPS, block.timestamp);

        address[] memory strategies = new address[](1);
        strategies[0] = strategy;

        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = proofs;

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = PPS;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        ecdsaOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                timestamps: timestamps
            })
        );

        uint256 claimableUpkeepAfterUpdate = aggregator.claimableUpkeep();
        console2.log("Claimable upkeep after PPS update:", claimableUpkeepAfterUpdate);

        console2.log("=== Step 4: Claim upkeep to SuperBank ===");
        uint256 claimAmount = claimableUpkeepAfterUpdate;
        vm.prank(deployer);
        governor.executeUpkeepClaim(claimAmount);

        uint256 superBankBalanceAfterClaim = IERC20(WETH_BASE).balanceOf(address(superBank));
        console2.log("SuperBank WETH balance after claim:", superBankBalanceAfterClaim);
        assertGt(superBankBalanceAfterClaim, 0, "SuperBank should have WETH");

        // ============================================================
        // STEP 5: Set up merkle root for TransferERC20Hook on SuperBank
        // ============================================================
        console2.log("=== Step 5: Set up SuperBank hook merkle root ===");

        // Create the hook data for transferring WETH to treasury
        // Data format: token (20 bytes) + to (20 bytes) + amount (32 bytes) + usePrevHookAmount (1 byte)
        uint256 transferAmount = superBankBalanceAfterClaim;
        bytes memory hookData = abi.encodePacked(
            WETH_BASE,      // token (20 bytes)
            treasury,       // to (20 bytes)
            transferAmount, // amount (32 bytes)
            false           // usePrevHookAmount (1 byte) - use explicit amount
        );

        // Get hook args from inspect() - this is what goes into the merkle leaf
        bytes memory hookArgs = ISuperHookInspector(address(transferHook)).inspect(hookData);

        // Create merkle leaf: keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(address(transferHook), hookArgs))));

        // For a single-leaf tree, the root equals the leaf
        bytes32 merkleRoot = leaf;

        console2.log("TransferERC20Hook address:", address(transferHook));
        console2.log("Transfer amount:", transferAmount);
        console2.log("Treasury address:", treasury);

        // Propose the merkle root for this hook
        vm.startPrank(deployer);
        governor.proposeSuperBankHookMerkleRoot(address(transferHook), merkleRoot);

        // Warp past the timelock (7 days)
        vm.warp(block.timestamp + 7 days + 1);

        // Execute the merkle root update
        governor.executeSuperBankHookMerkleRootUpdate(address(transferHook));
        vm.stopPrank();

        console2.log("Merkle root set for TransferERC20Hook");

        // ============================================================
        // STEP 6: Execute hook on SuperBank to transfer to treasury
        // ============================================================
        console2.log("=== Step 6: Execute SuperBank hook to transfer to treasury ===");

        uint256 treasuryBalanceBefore = IERC20(WETH_BASE).balanceOf(treasury);
        console2.log("Treasury WETH balance before:", treasuryBalanceBefore);

        // Prepare hook execution data
        address[] memory hooks = new address[](1);
        hooks[0] = address(transferHook);

        bytes[] memory hookDatas = new bytes[](1);
        hookDatas[0] = hookData;

        // For single-leaf tree, empty proof is valid when root equals leaf
        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        // Expected output is the amount transferred (balance increase at treasury)
        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = transferAmount;

        // Execute the hook via SuperBank (requires BANK_MANAGER_ROLE)
        vm.prank(deployer);
        superBank.executeHooks(
            IHookExecutionData.HookExecutionData({
                hooks: hooks,
                data: hookDatas,
                merkleProofs: merkleProofs,
                expectedAssetsOrSharesOut: expectedOutputs
            })
        );

        // Verify transfer
        uint256 treasuryBalanceAfter = IERC20(WETH_BASE).balanceOf(treasury);
        uint256 superBankBalanceAfter = IERC20(WETH_BASE).balanceOf(address(superBank));

        console2.log("Treasury WETH balance after:", treasuryBalanceAfter);
        console2.log("SuperBank WETH balance after:", superBankBalanceAfter);
        console2.log("WETH transferred to treasury:", treasuryBalanceAfter - treasuryBalanceBefore);

        assertEq(
            treasuryBalanceAfter - treasuryBalanceBefore,
            transferAmount,
            "Treasury should receive the full transfer amount"
        );
        assertEq(superBankBalanceAfter, 0, "SuperBank should have 0 WETH after transfer");

        console2.log("=== Full upkeep flow + SuperBank hook transfer completed successfully! ===");
    }

    /// @notice Helper to create valid proofs from validators
    function _createValidProofs(
        address _strategy,
        uint256 _pps,
        uint256 _timestamp
    )
        internal
        view
        returns (bytes[] memory)
    {
        uint256 nonce = ecdsaOracle.noncePerStrategy(_strategy);

        bytes32 digest = _getDigest(_strategy, _pps, _timestamp, nonce);

        // ECDSAPPSOracle requires proofs ordered by signer address in ascending order
        bytes[] memory proofs = new bytes[](2);
        if (validator1 < validator2) {
            proofs[0] = _sign(validator1PrivateKey, digest);
            proofs[1] = _sign(validator2PrivateKey, digest);
        } else {
            proofs[0] = _sign(validator2PrivateKey, digest);
            proofs[1] = _sign(validator1PrivateKey, digest);
        }

        return proofs;
    }

    function _getDigest(
        address _strategy,
        uint256 _pps,
        uint256 _timestamp,
        uint256 _nonce
    )
        internal
        view
        returns (bytes32)
    {
        // Must use abi.encodePacked to match ECDSAPPSOracle.validateProofs
        bytes32 structHash =
            keccak256(abi.encodePacked(ecdsaOracle.UPDATE_PPS_TYPEHASH(), _strategy, _pps, _timestamp, _nonce));

        return keccak256(abi.encodePacked("\x19\x01", ecdsaOracle.domainSeparator(), structHash));
    }

    function _sign(uint256 privateKey, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
