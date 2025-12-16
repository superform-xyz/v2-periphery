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
import { SuperOracleL2 } from "../../../src/oracles/SuperOracleL2.sol";
import { FixedPriceOracle } from "../../../src/oracles/FixedPriceOracle.sol";
import { SuperformGasOracle } from "../../../src/oracles/SuperformGasOracle.sol";
import { ECDSAPPSOracle } from "../../../src/oracles/ECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";

/// @title SuperformGasOracleIntegrationTest
/// @notice Integration test for SuperformGasOracle on Base
/// @dev Tests the full oracle pipeline using SuperformGasOracle for gas pricing
contract SuperformGasOracleIntegrationTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Base Chainlink oracle addresses
    address constant ORACLE_ETH_USD_BASE = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    address constant ORACLE_SEQUENCER_UPTIME_BASE = 0xBCF85224fc0756B9Fa45aA7892530B47e10b6433;

    // Base chain constants
    address constant WETH_BASE = 0x4200000000000000000000000000000000000006;
    address constant USDC_BASE = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // Oracle constants (must match SuperGovernor)
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // UPKEEP_TOKEN price configuration (WETH priced in USD)
    int256 constant INITIAL_WETH_PRICE = 3000e18; // $3000 with 18 decimals
    uint8 constant WETH_PRICE_DECIMALS = 18;

    // Gas price configuration for SuperformGasOracle
    // Using 0 decimals (Gwei), so 1 = 1 Gwei (realistic for Base L2)
    int256 constant INITIAL_GAS_PRICE = 1; // 1 Gwei

    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");

    // Contracts
    SuperGovernor public governor;
    SuperVaultAggregator public aggregator;
    SuperOracleL2 public superOracle;
    FixedPriceOracle public wethPriceOracle;
    SuperformGasOracle public gasOracle;
    ECDSAPPSOracle public ecdsaOracle;

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

    // Constants
    uint256 constant GAS_PER_ENTRY = 60_000;
    uint256 constant PPS = 1e6;
    uint256 constant FORK_BLOCK = 24_000_000;

    function setUp() public {
        // Fork Base at a specific block
        vm.createSelectFork(vm.envString("BASE_RPC_URL"), FORK_BLOCK);

        deployer = makeAddr("deployer");
        manager = makeAddr("manager");
        treasury = makeAddr("treasury");
        validator1 = vm.addr(validator1PrivateKey);
        validator2 = vm.addr(validator2PrivateKey);

        vm.startPrank(deployer);

        // Deploy SuperformGasOracle (similar to production deployment)
        gasOracle = new SuperformGasOracle(INITIAL_GAS_PRICE, deployer);

        // Deploy SuperGovernor
        governor = new SuperGovernor(deployer, deployer, deployer, deployer, deployer, deployer, treasury, false);

        // Deploy implementation contracts
        address vaultImpl = address(new SuperVault(address(governor)));
        address strategyImpl = address(new SuperVaultStrategy(address(governor)));
        address escrowImpl = address(new SuperVaultEscrow());

        // Deploy SuperVaultAggregator
        aggregator = new SuperVaultAggregator(address(governor), vaultImpl, strategyImpl, escrowImpl);

        // Deploy FixedPriceOracle for WETH/USD
        wethPriceOracle = new FixedPriceOracle(INITIAL_WETH_PRICE, WETH_PRICE_DECIMALS, deployer);

        // Deploy SuperOracleL2 with SuperformGasOracle
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
        // Configure 3 feeds: GAS->WEI, ETH->USD, WETH->USD
        address[] memory bases = new address[](3);
        address[] memory quotes = new address[](3);
        bytes32[] memory providers = new bytes32[](3);
        address[] memory feeds = new address[](3);

        // Feed 1: GAS -> WEI (using SuperformGasOracle)
        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_SUPERFORM;
        feeds[0] = address(gasOracle);

        // Feed 2: ETH -> USD (Chainlink on Base)
        bases[1] = NATIVE_TOKEN;
        quotes[1] = USD_TOKEN;
        providers[1] = PROVIDER_CHAINLINK;
        feeds[1] = ORACLE_ETH_USD_BASE;

        // Feed 3: WETH -> USD (FixedPriceOracle)
        bases[2] = WETH_BASE;
        quotes[2] = USD_TOKEN;
        providers[2] = PROVIDER_SUPERFORM;
        feeds[2] = address(wethPriceOracle);

        superOracle = new SuperOracleL2(address(governor), bases, quotes, providers, feeds);
    }

    function _configureGovernor() internal {
        // Set SuperVaultAggregator
        governor.setAddress(governor.SUPER_VAULT_AGGREGATOR(), address(aggregator));

        // Set SuperOracle
        governor.setAddress(governor.SUPER_ORACLE(), address(superOracle));

        // Configure uptime feeds for L2 oracle
        {
            address[] memory dataOracles = new address[](3);
            dataOracles[0] = address(gasOracle);
            dataOracles[1] = ORACLE_ETH_USD_BASE;
            dataOracles[2] = address(wethPriceOracle);

            address[] memory uptimeOracles = new address[](3);
            uptimeOracles[0] = ORACLE_SEQUENCER_UPTIME_BASE;
            uptimeOracles[1] = ORACLE_SEQUENCER_UPTIME_BASE;
            uptimeOracles[2] = ORACLE_SEQUENCER_UPTIME_BASE;

            uint256[] memory gracePeriods = new uint256[](3);
            gracePeriods[0] = 3600;
            gracePeriods[1] = 3600;
            gracePeriods[2] = 3600;

            governor.batchSetOracleUptimeFeed(dataOracles, uptimeOracles, gracePeriods);
        }

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

        // Increase oracle staleness tolerance
        governor.setOracleMaxStaleness(30 days);

        address[] memory feedAddresses = new address[](3);
        feedAddresses[0] = address(gasOracle);
        feedAddresses[1] = ORACLE_ETH_USD_BASE;
        feedAddresses[2] = address(wethPriceOracle);

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

    /// @notice Test that SuperformGasOracle returns valid data
    function test_SuperformGasOracle_ReturnsValidData() public view {
        console2.log("=== SuperformGasOracle Data ===");

        // Check oracle interface
        uint8 decimals = gasOracle.decimals();
        string memory description = gasOracle.description();
        uint256 version = gasOracle.version();

        console2.log("Decimals:", decimals);
        console2.log("Description:", description);
        console2.log("Version:", version);

        // Get latest round data
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            gasOracle.latestRoundData();

        console2.log("Round ID:", roundId);
        console2.log("Answer (gas price):", uint256(answer));
        console2.log("Started At:", startedAt);
        console2.log("Updated At:", updatedAt);
        console2.log("Answered In Round:", answeredInRound);

        // Basic sanity checks
        assertGt(answer, 0, "Gas price should be > 0");
        assertEq(decimals, 0, "Decimals should be 0 (Gwei)");
        assertEq(description, "Superform Fast Gas / Gwei", "Description should match");
        assertEq(version, 1, "Version should be 1");
    }

    /// @notice Test that useBlockTimestamp flag works (should be true by default)
    function test_SuperformGasOracle_UseBlockTimestamp() public view {
        bool useBlockTimestamp = gasOracle.useBlockTimestamp();
        console2.log("useBlockTimestamp:", useBlockTimestamp);

        // By default, useBlockTimestamp should be true
        assertTrue(useBlockTimestamp, "useBlockTimestamp should be true by default");

        // When true, updatedAt should be block.timestamp
        (,, uint256 startedAt, uint256 updatedAt,) = gasOracle.latestRoundData();
        assertEq(startedAt, block.timestamp, "startedAt should be block.timestamp when useBlockTimestamp is true");
        assertEq(updatedAt, block.timestamp, "updatedAt should be block.timestamp when useBlockTimestamp is true");
    }

    /// @notice Test upkeep cost calculation with SuperformGasOracle
    function test_UpkeepCostCalculation_WithSuperformGasOracle() public view {
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));

        console2.log("=== Upkeep Cost with SuperformGasOracle ===");
        console2.log("Gas per entry:", GAS_PER_ENTRY);
        console2.log("Upkeep cost (in WETH):", upkeepCost);

        // Get the gas price from oracle
        int256 gasPrice = gasOracle.latestAnswer();
        console2.log("Gas price from oracle:", uint256(gasPrice));

        // Verify upkeep cost is reasonable
        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");
        assertLt(upkeepCost, 1e18, "Upkeep cost should be < 1 WETH");
    }

    /// @notice Test full PPS update flow with SuperformGasOracle
    function test_UpdatePPS_WithSuperformGasOracle() public {
        // Get upkeep cost
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        console2.log("Upkeep cost per entry:", upkeepCost);

        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");

        // Fund manager with WETH
        uint256 depositAmount = upkeepCost * 10;
        deal(WETH_BASE, manager, depositAmount);

        // Deposit upkeep
        vm.startPrank(manager);
        IERC20(WETH_BASE).approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        uint256 initialStrategyUpkeep = aggregator.getUpkeepBalance(strategy);
        uint256 initialClaimable = aggregator.claimableUpkeep();

        console2.log("Initial strategy upkeep:", initialStrategyUpkeep);
        console2.log("Initial claimable:", initialClaimable);

        // Move time forward
        vm.warp(block.timestamp + 10);

        // Create valid proofs and update PPS
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
        uint256 finalStrategyUpkeep = aggregator.getUpkeepBalance(strategy);
        uint256 finalClaimable = aggregator.claimableUpkeep();

        console2.log("Final strategy upkeep:", finalStrategyUpkeep);
        console2.log("Final claimable:", finalClaimable);
        console2.log("Upkeep deducted:", initialStrategyUpkeep - finalStrategyUpkeep);

        assertEq(
            initialStrategyUpkeep - finalStrategyUpkeep,
            upkeepCost,
            "Strategy upkeep should decrease by upkeep cost"
        );
        assertEq(finalClaimable - initialClaimable, upkeepCost, "Claimable should increase by upkeep cost");
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
