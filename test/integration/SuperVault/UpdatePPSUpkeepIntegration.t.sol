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
import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { FixedPriceOracle } from "../../../src/oracles/FixedPriceOracle.sol";
import { ECDSAPPSOracle } from "../../../src/oracles/ECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { MockUp } from "../../mocks/MockUp.sol";

/// @title UpdatePPSUpkeepIntegrationTest
/// @notice Integration test for updatePPS with real mainnet oracles and UP token upkeep
/// @dev Tests the full oracle pipeline: GAS->WEI, ETH->USD, UP->USD via FixedPriceOracle
contract UpdatePPSUpkeepIntegrationTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // Mainnet Chainlink oracle addresses
    address constant ORACLE_ETH_USD_MAINNET = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant ORACLE_GAS_TO_ETH = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

    // Oracle constants (must match SuperGovernor)
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));

    // UP token configuration
    int256 constant INITIAL_UP_PRICE = 0.09e18; // $0.09 with 18 decimals
    uint8 constant UP_PRICE_DECIMALS = 18;

    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");

    // Contracts
    SuperGovernor public governor;
    SuperVaultAggregator public aggregator;
    SuperOracle public superOracle;
    FixedPriceOracle public fixedPriceOracle;
    ECDSAPPSOracle public ecdsaOracle;
    MockUp public upToken;

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
    uint256 constant PPS = 1e6; // 1.0 in 6 decimals

    function setUp() public {
        // Fork mainnet at a recent block
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));

        deployer = makeAddr("deployer");
        manager = makeAddr("manager");
        treasury = makeAddr("treasury");
        validator1 = vm.addr(validator1PrivateKey);
        validator2 = vm.addr(validator2PrivateKey);

        vm.startPrank(deployer);

        // Deploy UP token
        upToken = new MockUp(deployer);

        // Deploy SuperGovernor with deployer as all roles initially
        governor = new SuperGovernor(deployer, deployer, deployer, deployer, deployer, deployer, treasury);

        // Deploy implementation contracts
        address vaultImpl = address(new SuperVault(address(governor)));
        address strategyImpl = address(new SuperVaultStrategy(address(governor)));
        address escrowImpl = address(new SuperVaultEscrow());

        // Deploy SuperVaultAggregator
        aggregator = new SuperVaultAggregator(address(governor), vaultImpl, strategyImpl, escrowImpl);

        // Deploy FixedPriceOracle for UP/USD
        fixedPriceOracle = new FixedPriceOracle(INITIAL_UP_PRICE, UP_PRICE_DECIMALS, deployer);

        // Deploy SuperOracle with mainnet feeds
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
        // Configure 3 feeds: GAS->WEI, ETH->USD, UP->USD
        address[] memory bases = new address[](3);
        address[] memory quotes = new address[](3);
        bytes32[] memory providers = new bytes32[](3);
        address[] memory feeds = new address[](3);

        // Feed 1: GAS -> WEI (gas price oracle)
        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_CHAINLINK;
        feeds[0] = ORACLE_GAS_TO_ETH;

        // Feed 2: ETH -> USD
        bases[1] = NATIVE_TOKEN;
        quotes[1] = USD_TOKEN;
        providers[1] = PROVIDER_CHAINLINK;
        feeds[1] = ORACLE_ETH_USD_MAINNET;

        // Feed 3: UP -> USD (using FixedPriceOracle)
        bases[2] = address(upToken);
        quotes[2] = USD_TOKEN;
        providers[2] = PROVIDER_SUPERFORM;
        feeds[2] = address(fixedPriceOracle);

        superOracle = new SuperOracle(address(governor), bases, quotes, providers, feeds);
        // Note: Default staleness (2 days) is set by constructor for all feeds
    }

    function _configureGovernor() internal {
        // Set SuperVaultAggregator
        governor.setAddress(governor.SUPER_VAULT_AGGREGATOR(), address(aggregator));

        // Set SuperOracle
        governor.setAddress(governor.SUPER_ORACLE(), address(superOracle));

        // Set UP and UPKEEP_TOKEN
        // Both are the same token for mainnet testing; on L2s UPKEEP_TOKEN would be WETH
        governor.setAddress(governor.UP(), address(upToken));
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

        // Enable upkeep payments
        governor.proposeUpkeepPaymentsChange(true);
        vm.warp(block.timestamp + 8 days);
        governor.executeUpkeepPaymentsChange();

        // Increase oracle staleness tolerance to account for time warps (15+ days)
        // This allows real Chainlink data to still be considered fresh
        // Must update both defaultStaleness AND individual feed staleness (Math.min is used)
        governor.setOracleMaxStaleness(30 days);

        address[] memory feeds = new address[](3);
        feeds[0] = ORACLE_GAS_TO_ETH;
        feeds[1] = ORACLE_ETH_USD_MAINNET;
        feeds[2] = address(fixedPriceOracle);

        uint256[] memory staleness = new uint256[](3);
        staleness[0] = 30 days;
        staleness[1] = 30 days;
        staleness[2] = 30 days;

        governor.setOracleFeedMaxStalenessBatch(feeds, staleness);
    }

    function _createVaultAndStrategy() internal {
        // Get USDC on mainnet
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        (, address strat,) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: usdc,
                name: "Test Vault",
                symbol: "TV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: treasury
                })
            })
        );

        strategy = strat;
    }

    /// @notice Test that UP token is used for upkeep when updatePPS is called
    function test_UpdatePPS_UsesUpTokenForUpkeep() public {
        // First, get the upkeep cost per entry
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));
        console2.log("Upkeep cost per entry (in UP tokens):", upkeepCost);

        // Verify the cost is reasonable (should be > 0 with real oracles)
        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");

        // Mint UP tokens to manager and deposit as upkeep
        uint256 depositAmount = upkeepCost * 10; // Deposit 10x the cost for safety
        vm.prank(deployer);
        upToken.mint(manager, depositAmount);

        // Manager approves and deposits upkeep
        vm.startPrank(manager);
        upToken.approve(address(aggregator), depositAmount);
        aggregator.depositUpkeep(strategy, depositAmount);
        vm.stopPrank();

        // Record initial state
        uint256 initialStrategyUpkeep = aggregator.getUpkeepBalance(strategy);
        uint256 initialClaimableUpkeep = aggregator.claimableUpkeep();

        console2.log("Initial strategy upkeep balance:", initialStrategyUpkeep);
        console2.log("Initial claimable upkeep:", initialClaimableUpkeep);

        // Move time forward to ensure timestamp > lastUpdateTimestamp from vault creation
        // This is required because _forwardPPS checks args.timestamp > lastUpdate
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

        // Call updatePPS
        ecdsaOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies, proofsArray: proofsArray, ppss: ppss, timestamps: timestamps
            })
        );

        // Verify upkeep was deducted
        uint256 finalStrategyUpkeep = aggregator.getUpkeepBalance(strategy);
        uint256 finalClaimableUpkeep = aggregator.claimableUpkeep();

        console2.log("Final strategy upkeep balance:", finalStrategyUpkeep);
        console2.log("Final claimable upkeep:", finalClaimableUpkeep);
        console2.log("Upkeep deducted from strategy:", initialStrategyUpkeep - finalStrategyUpkeep);
        console2.log("Upkeep added to claimable:", finalClaimableUpkeep - initialClaimableUpkeep);

        // Assertions
        assertEq(
            initialStrategyUpkeep - finalStrategyUpkeep, upkeepCost, "Strategy upkeep should decrease by upkeep cost"
        );
        assertEq(
            finalClaimableUpkeep - initialClaimableUpkeep, upkeepCost, "Claimable upkeep should increase by upkeep cost"
        );
    }

    /// @notice Test upkeep cost calculation with real oracle prices
    function test_UpkeepCostCalculation() public view {
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));

        console2.log("=== Upkeep Cost Breakdown ===");
        console2.log("Gas per entry:", GAS_PER_ENTRY);
        console2.log("Upkeep cost in UP tokens:", upkeepCost);

        // Upkeep cost depends on gas price, ETH price, and UP price from real oracles
        // Just verify it's a reasonable non-zero value
        assertGt(upkeepCost, 0, "Upkeep cost should be > 0");
        assertLt(upkeepCost, 1000e18, "Upkeep cost should be < 1000 UP");
    }

    /// @notice Test that insufficient upkeep causes strategy to pause
    function test_InsufficientUpkeep_PausesStrategy() public {
        uint256 upkeepCost = governor.getUpkeepCostPerSingleUpdate(address(ecdsaOracle));

        // Deposit less than required upkeep
        uint256 insufficientAmount = upkeepCost / 2;
        vm.prank(deployer);
        upToken.mint(manager, insufficientAmount);

        vm.startPrank(manager);
        upToken.approve(address(aggregator), insufficientAmount);
        aggregator.depositUpkeep(strategy, insufficientAmount);
        vm.stopPrank();

        // Move time forward to ensure timestamp > lastUpdateTimestamp from vault creation
        vm.warp(block.timestamp + 10);

        // Try to update PPS
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
                strategies: strategies, proofsArray: proofsArray, ppss: ppss, timestamps: timestamps
            })
        );

        // Strategy should be paused due to insufficient upkeep
        bool isPaused = aggregator.isStrategyPaused(strategy);
        assertTrue(isPaused, "Strategy should be paused due to insufficient upkeep");
    }

    /// @notice Helper to create valid proofs from validators
    /// @dev Proofs must be ordered by signer address in ascending order (ECDSAPPSOracle requirement)
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
        // Order proofs based on which validator address is smaller
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
