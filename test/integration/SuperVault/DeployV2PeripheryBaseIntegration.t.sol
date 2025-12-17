// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { ECDSA } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperVaultAggregator } from "../../../src/SuperVault/SuperVaultAggregator.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperOracleL2 } from "../../../src/oracles/SuperOracleL2.sol";
import { FixedPriceOracle } from "../../../src/oracles/FixedPriceOracle.sol";
import { SuperformGasOracle } from "../../../src/oracles/SuperformGasOracle.sol";
import { ECDSAPPSOracle } from "../../../src/oracles/ECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";

/// @title DeployV2PeripheryBaseIntegrationTest
/// @notice Integration test that mimics DeployV2Periphery on Base with UP token for upkeep payments
/// @dev Tests: deployment, upkeep enabled, mint UP tokens, create vault, deposit upkeep, updatePPS
contract DeployV2PeripheryBaseIntegrationTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Base Chainlink oracle addresses
    address constant ORACLE_ETH_USD_BASE = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    address constant ORACLE_SEQUENCER_UPTIME_BASE = 0xBCF85224fc0756B9Fa45aA7892530B47e10b6433;

    // Production gas oracle on Base (SuperformGasOracle)
    address constant ORACLE_GAS_TO_WEI_BASE = 0x473b88f017dE39d85a102DA01A35a1b3507eBcFc;

    // Base chain tokens
    address constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant UP_TOKEN_BASE = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;

    // UP token reference
    IERC20 public upToken;

    // Oracle constants (must match SuperGovernor)
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // UP token price configuration ($0.09 - same as mainnet)
    int256 constant INITIAL_UP_PRICE = 0.09e18;
    uint8 constant UP_PRICE_DECIMALS = 18;

    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");

    // Contracts
    SuperGovernor public governor;
    SuperVaultAggregator public aggregator;
    SuperOracleL2 public superOracle;
    FixedPriceOracle public fixedPriceOracle; // UP/USD oracle
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

    // Constants
    uint256 constant GAS_PER_ENTRY = 135_000; // Same as ConfigBase
    uint256 constant PPS = 1e6; // 1.0 in 6 decimals
    uint256 constant UP_TOKEN_MINT_AMOUNT = 150_000_000e18; // 150 million UP tokens

    function setUp() public {
        // Fork Base at latest block to ensure all production contracts exist
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        deployer = makeAddr("deployer");
        manager = makeAddr("manager");
        treasury = makeAddr("treasury");
        validator1 = vm.addr(validator1PrivateKey);
        validator2 = vm.addr(validator2PrivateKey);

        vm.startPrank(deployer);

        // Use real UP token on Base
        upToken = IERC20(UP_TOKEN_BASE);

        // Deploy SuperGovernor with upkeepPaymentsEnabled = true (like production)
        governor = new SuperGovernor(deployer, deployer, deployer, deployer, deployer, deployer, treasury, true);

        // Deploy implementation contracts
        address vaultImpl = address(new SuperVault(address(governor)));
        address strategyImpl = address(new SuperVaultStrategy(address(governor)));
        address escrowImpl = address(new SuperVaultEscrow());

        // Deploy SuperVaultAggregator
        aggregator = new SuperVaultAggregator(address(governor), vaultImpl, strategyImpl, escrowImpl);

        // Deploy SuperBank
        superBank = new SuperBank(address(governor));

        // Deploy FixedPriceOracle for UP/USD ($0.09)
        fixedPriceOracle = new FixedPriceOracle(INITIAL_UP_PRICE, UP_PRICE_DECIMALS, deployer);

        // Deploy SuperOracleL2 with Base feeds
        _deploySuperOracle();

        // Deploy ECDSAPPSOracle
        ecdsaOracle = new ECDSAPPSOracle(address(governor), "ECDSAPPS", "1");

        // Configure SuperGovernor
        _configureGovernor();

        // Create a vault and strategy
        _createVaultAndStrategy();

        vm.stopPrank();
    }

    function _deploySuperOracle() internal {
        // Configure 3 feeds: GAS->WEI, ETH->USD, UP->USD (same as DeployV2Periphery)
        address[] memory bases = new address[](3);
        address[] memory quotes = new address[](3);
        bytes32[] memory providers = new bytes32[](3);
        address[] memory feeds = new address[](3);

        // Feed 1: GAS -> WEI (using production SuperformGasOracle)
        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_CHAINLINK; // SuperformGasOracle implements AggregatorV3Interface
        feeds[0] = ORACLE_GAS_TO_WEI_BASE;

        // Feed 2: ETH -> USD (using Chainlink on Base)
        bases[1] = NATIVE_TOKEN;
        quotes[1] = USD_TOKEN;
        providers[1] = PROVIDER_CHAINLINK;
        feeds[1] = ORACLE_ETH_USD_BASE;

        // Feed 3: UP -> USD (using FixedPriceOracle)
        bases[2] = UP_TOKEN_BASE;
        quotes[2] = USD_TOKEN;
        providers[2] = PROVIDER_SUPERFORM;
        feeds[2] = address(fixedPriceOracle);

        superOracle = new SuperOracleL2(address(governor), bases, quotes, providers, feeds);
    }

    function _configureGovernor() internal {
        // Set SuperVaultAggregator
        governor.setAddress(governor.SUPER_VAULT_AGGREGATOR(), address(aggregator));

        // Set SuperOracle
        governor.setAddress(governor.SUPER_ORACLE(), address(superOracle));

        // Configure uptime feeds for L2 oracle - required by SuperOracleL2
        {
            address[] memory dataOracles = new address[](3);
            dataOracles[0] = ORACLE_GAS_TO_WEI_BASE;
            dataOracles[1] = ORACLE_ETH_USD_BASE;
            dataOracles[2] = address(fixedPriceOracle);

            address[] memory uptimeOracles = new address[](3);
            uptimeOracles[0] = ORACLE_SEQUENCER_UPTIME_BASE;
            uptimeOracles[1] = ORACLE_SEQUENCER_UPTIME_BASE;
            uptimeOracles[2] = ORACLE_SEQUENCER_UPTIME_BASE;

            uint256[] memory gracePeriods = new uint256[](3);
            gracePeriods[0] = 0; // Use default
            gracePeriods[1] = 0;
            gracePeriods[2] = 0;

            governor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        }

        // Set SuperBank
        governor.setAddress(governor.SUPER_BANK(), address(superBank));

        // Set UPKEEP_TOKEN to UP token
        governor.setAddress(governor.UPKEEP_TOKEN(), address(upToken));

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

        // Increase oracle staleness tolerance to account for time warps
        governor.setOracleMaxStaleness(30 days);

        address[] memory feedAddresses = new address[](3);
        feedAddresses[0] = ORACLE_GAS_TO_WEI_BASE;
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
                name: "Test Vault Base UP",
                symbol: "TVBU",
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

    /// @notice Test that upkeep payments are enabled (like production deployment)
    function test_UpkeepPaymentsEnabled() public view {
        bool enabled = governor.isUpkeepPaymentsEnabled();
        assertTrue(enabled, "Upkeep payments should be enabled");
        console2.log("Upkeep payments enabled:", enabled);
    }

    /// @notice Test that UP token is set as UPKEEP_TOKEN
    function test_UpkeepTokenIsUpToken() public view {
        address upkeepToken = governor.getAddress(governor.UPKEEP_TOKEN());
        assertEq(upkeepToken, address(upToken), "UPKEEP_TOKEN should be UP token");
        console2.log("UPKEEP_TOKEN:", upkeepToken);
    }

    /// @notice Test the full upkeep flow with UP tokens:
    /// Mint UP -> depositUpkeep -> PPS update -> verify upkeep deducted
    function test_FullUpkeepFlowWithUpToken() public {
        console2.log("=== Full Upkeep Flow with UP Token ===");

        // Step 1: Verify upkeep cost calculation works
        console2.log("=== Step 1: Get upkeep cost ===");
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        console2.log("Upkeep cost per entry (in UP tokens):", upkeepCost);
        console2.log("Gas per entry:", GAS_PER_ENTRY);
        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");

        // Step 2: Deal 150 million UP tokens to manager
        console2.log("=== Step 2: Deal UP tokens to manager ===");
        deal(address(upToken), manager, UP_TOKEN_MINT_AMOUNT);
        uint256 managerBalance = upToken.balanceOf(manager);
        console2.log("Manager UP balance:", managerBalance);
        assertEq(managerBalance, UP_TOKEN_MINT_AMOUNT, "Manager should have 150M UP tokens");

        // Step 3: Manager deposits upkeep tokens
        console2.log("=== Step 3: Deposit upkeep ===");
        uint256 depositAmount = upkeepCost * 10; // Deposit enough for 10 updates
        vm.startPrank(manager);
        upToken.approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        uint256 strategyUpkeepAfterDeposit = aggregator.getUpkeepBalance(strategy);
        console2.log("Strategy upkeep balance after deposit:", strategyUpkeepAfterDeposit);
        assertEq(strategyUpkeepAfterDeposit, depositAmount, "Strategy upkeep should equal deposit amount");

        // Record state before PPS update
        uint256 claimableUpkeepBefore = aggregator.claimableUpkeep();
        console2.log("Claimable upkeep before PPS update:", claimableUpkeepBefore);

        // Step 4: Run PPS update - this should deduct upkeep from strategy
        console2.log("=== Step 4: Run PPS update ===");
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

        // Verify upkeep was deducted
        uint256 strategyUpkeepAfterUpdate = aggregator.getUpkeepBalance(strategy);
        uint256 claimableUpkeepAfterUpdate = aggregator.claimableUpkeep();

        console2.log("Strategy upkeep after PPS update:", strategyUpkeepAfterUpdate);
        console2.log("Claimable upkeep after PPS update:", claimableUpkeepAfterUpdate);
        console2.log("Upkeep deducted from strategy:", strategyUpkeepAfterDeposit - strategyUpkeepAfterUpdate);

        assertEq(
            strategyUpkeepAfterDeposit - strategyUpkeepAfterUpdate,
            upkeepCost,
            "Strategy upkeep should decrease by upkeep cost"
        );
        assertEq(
            claimableUpkeepAfterUpdate - claimableUpkeepBefore, upkeepCost, "Claimable upkeep should increase by cost"
        );

        console2.log("=== Full upkeep flow with UP token completed successfully! ===");
    }

    /// @notice Test multiple PPS updates with UP token upkeep
    function test_MultiplePPSUpdatesWithUpToken() public {
        console2.log("=== Multiple PPS Updates with UP Token ===");

        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        uint256 numUpdates = 5;
        uint256 depositAmount = upkeepCost * (numUpdates + 2);

        // Deal and deposit UP tokens
        deal(address(upToken), manager, UP_TOKEN_MINT_AMOUNT);
        vm.startPrank(manager);
        upToken.approve(address(aggregator), depositAmount);
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

        console2.log("=== Multiple PPS updates completed successfully! ===");
    }

    /// @notice Test claiming upkeep to SuperBank with UP tokens
    function test_ClaimUpkeepToSuperBank() public {
        console2.log("=== Claim Upkeep to SuperBank ===");

        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        uint256 depositAmount = upkeepCost * 10;

        // Deal and deposit
        deal(address(upToken), manager, UP_TOKEN_MINT_AMOUNT);
        vm.startPrank(manager);
        upToken.approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        // Run PPS update
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

        uint256 claimable = aggregator.claimableUpkeep();
        uint256 superBankBefore = upToken.balanceOf(address(superBank));

        console2.log("Claimable upkeep:", claimable);
        console2.log("SuperBank UP balance before:", superBankBefore);

        // Claim to SuperBank
        vm.prank(deployer);
        governor.executeUpkeepClaim(claimable);

        uint256 superBankAfter = upToken.balanceOf(address(superBank));
        uint256 claimableAfter = aggregator.claimableUpkeep();

        console2.log("SuperBank UP balance after:", superBankAfter);
        console2.log("Claimable upkeep after claim:", claimableAfter);

        assertEq(claimableAfter, 0, "Claimable should be 0 after full claim");
        assertEq(superBankAfter - superBankBefore, claimable, "SuperBank should receive claimed amount");

        console2.log("=== Claim to SuperBank completed successfully! ===");
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
        bytes32 structHash =
            keccak256(abi.encodePacked(ecdsaOracle.UPDATE_PPS_TYPEHASH(), _strategy, _pps, _timestamp, _nonce));
        return keccak256(abi.encodePacked("\x19\x01", ecdsaOracle.domainSeparator(), structHash));
    }

    function _sign(uint256 privateKey, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
