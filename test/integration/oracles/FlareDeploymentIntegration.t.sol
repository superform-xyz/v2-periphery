// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperOracle } from "../../../src/oracles/SuperOracle.sol";
import { FixedPriceOracle } from "../../../src/oracles/FixedPriceOracle.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";

/// @title FlareDeploymentIntegrationTest
/// @notice Integration tests against the REAL deployed contracts on Flare mainnet (prod)
/// @dev Forks Flare and validates the full deployment: roles, oracle feeds, contract wiring, SuperBank
contract FlareDeploymentIntegrationTest is Test {
    // ─── Deployed prod contract addresses (from output/prod/14/Flare-latest.json) ───
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant SUPER_ORACLE = 0xA6480646D4c27Fc67f56eD3176838B8dED6Ca333;
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_VAULT_AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;
    address constant SUPER_VAULT_IMPL = 0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2;
    address constant SUPER_VAULT_STRATEGY_IMPL = 0x770abd170404B8ed8182c04f380E567e647b457D;
    address constant SUPER_VAULT_ESCROW_IMPL = 0x8982cf48eaB6616f2892888410afad9b0CD2BC9B;
    address constant SUPER_VAULT_BATCH_OPERATOR = 0x3047601ea12565C65b715137799a458971BA070B;
    address constant SUPER_VAULT_EXECUTOR = 0xA227Fe5d3295e108108d9FAEE24300dE3b45093C;

    // ─── Pre-requisite addresses (from output/prod/14/) ───
    address constant SUPERFORM_GAS_ORACLE = 0x473b88f017dE39d85a102DA01A35a1b3507eBcFc;
    address constant UP_OFT = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;

    // ─── External oracle addresses (from ConfigBase.sol) ───
    address constant ORACLE_FLR_USD = 0xbF9D1474E817C94163Fc7cc7Da5B4543CdA76697;

    // ─── Role addresses (from ConfigBase.sol) ───
    address constant DEPLOYER = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;
    address constant GUARDIAN = 0x5E8C68Ef250fdBcF696F838033CCcE23785DA03F;
    address constant ORACLE_MANAGER = 0xC72F6950FBF6ffE315525E200F6E54A05F739311;
    address constant BANK_MANAGER = 0xBe3B40a05BA6120B73F94c5018Bc90E49A6275E7;
    address constant GAS_MANAGER = 0x4d7AACD4b72e6BC6eA0eee6AA61A773A8b556B99;
    address constant TREASURY = 0x1dbD9b26b295A33f126456Ab4e498cd308622f08;

    // ─── Oracle constants ───
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD_TOKEN = address(840);
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    bytes32 constant PROVIDER_CHAINLINK = keccak256("CHAINLINK");
    bytes32 constant PROVIDER_SUPERFORM = keccak256("SUPERFORM");
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    // ─── Role constants ───
    bytes32 constant SUPER_GOVERNOR_ROLE = keccak256("SUPER_GOVERNOR_ROLE");
    bytes32 constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 constant ORACLE_MANAGER_ROLE = keccak256("ORACLE_MANAGER_ROLE");
    bytes32 constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");
    bytes32 constant GAS_MANAGER_ROLE = keccak256("GAS_MANAGER_ROLE");

    SuperGovernor governor;
    ISuperOracle oracle;

    function setUp() public {
        vm.createSelectFork(vm.envString("FLARE_RPC_URL"));
        governor = SuperGovernor(SUPER_GOVERNOR);
        oracle = ISuperOracle(SUPER_ORACLE);
    }

    /*//////////////////////////////////////////////////////////////
                        1. CONTRACT DEPLOYMENT CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice All deployed contracts have code on-chain
    function test_allContractsDeployed() public view {
        assertGt(SUPER_GOVERNOR.code.length, 0, "SuperGovernor not deployed");
        assertGt(SUPER_ORACLE.code.length, 0, "SuperOracle not deployed");
        assertGt(SUPER_BANK.code.length, 0, "SuperBank not deployed");
        assertGt(SUPER_VAULT_AGGREGATOR.code.length, 0, "SuperVaultAggregator not deployed");
        assertGt(ECDSA_PPS_ORACLE.code.length, 0, "ECDSAPPSOracle not deployed");
        assertGt(FIXED_PRICE_ORACLE.code.length, 0, "FixedPriceOracle not deployed");
        assertGt(SUPER_VAULT_IMPL.code.length, 0, "SuperVault impl not deployed");
        assertGt(SUPER_VAULT_STRATEGY_IMPL.code.length, 0, "SuperVaultStrategy impl not deployed");
        assertGt(SUPER_VAULT_ESCROW_IMPL.code.length, 0, "SuperVaultEscrow impl not deployed");
        assertGt(SUPER_VAULT_BATCH_OPERATOR.code.length, 0, "SuperVaultBatchOperator not deployed");
        assertGt(SUPER_VAULT_EXECUTOR.code.length, 0, "SuperVaultExecutor not deployed");

        // Pre-requisites
        assertGt(SUPERFORM_GAS_ORACLE.code.length, 0, "SuperformGasOracle not deployed");
        assertGt(UP_OFT.code.length, 0, "UpOFT not deployed");
        assertGt(ORACLE_FLR_USD.code.length, 0, "FLR/USD oracle not deployed");

        console2.log("All 14 contracts verified on-chain");
    }

    /*//////////////////////////////////////////////////////////////
                        2. SUPERGOVERNOR WIRING CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice SuperGovernor has correct contract addresses registered
    function test_governorContractAddressesSet() public view {
        address registeredOracle = governor.getAddress(governor.SUPER_ORACLE());
        address registeredBank = governor.getAddress(governor.SUPER_BANK());
        address registeredAggregator = governor.getAddress(governor.SUPER_VAULT_AGGREGATOR());

        assertEq(registeredOracle, SUPER_ORACLE, "SuperOracle not registered in governor");
        assertEq(registeredBank, SUPER_BANK, "SuperBank not registered in governor");
        assertEq(registeredAggregator, SUPER_VAULT_AGGREGATOR, "SuperVaultAggregator not registered in governor");

        console2.log("SuperOracle registered:", registeredOracle);
        console2.log("SuperBank registered:", registeredBank);
        console2.log("SuperVaultAggregator registered:", registeredAggregator);
    }

    /// @notice Active PPS oracle is set to ECDSAPPSOracle
    function test_activePPSOracleSet() public view {
        address activePPS = governor.getActivePPSOracle();
        assertEq(activePPS, ECDSA_PPS_ORACLE, "Active PPS oracle mismatch");
        console2.log("Active PPS Oracle:", activePPS);
    }

    /// @notice Validator configuration is set
    function test_validatorConfigSet() public view {
        (, address[] memory validators,, uint256 quorum) = governor.getValidatorConfig();
        assertGt(validators.length, 0, "No validators configured");
        assertEq(quorum, 1, "Quorum should be 1");
        console2.log("Validators:", validators.length);
        console2.log("Quorum:", quorum);
    }

    /*//////////////////////////////////////////////////////////////
                        3. ROLE CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deployer has the expected initial roles
    function test_deployerRoles() public view {
        assertTrue(
            governor.hasRole(SUPER_GOVERNOR_ROLE, DEPLOYER), "Deployer missing SUPER_GOVERNOR_ROLE"
        );
        assertTrue(
            governor.hasRole(governor.DEFAULT_ADMIN_ROLE(), DEPLOYER), "Deployer missing DEFAULT_ADMIN_ROLE"
        );
        assertTrue(governor.hasRole(GOVERNOR_ROLE, DEPLOYER), "Deployer missing GOVERNOR_ROLE");

        console2.log("Deployer roles verified");
    }

    /// @notice Guardian has GUARDIAN_ROLE
    function test_guardianRole() public view {
        assertTrue(governor.hasRole(GUARDIAN_ROLE, GUARDIAN), "Guardian missing GUARDIAN_ROLE");
        console2.log("Guardian role verified:", GUARDIAN);
    }

    /// @notice Designated managers have their respective roles
    function test_managerRoles() public view {
        assertTrue(
            governor.hasRole(ORACLE_MANAGER_ROLE, ORACLE_MANAGER), "OracleManager missing ORACLE_MANAGER_ROLE"
        );
        assertTrue(governor.hasRole(BANK_MANAGER_ROLE, BANK_MANAGER), "BankManager missing BANK_MANAGER_ROLE");
        assertTrue(governor.hasRole(GAS_MANAGER_ROLE, GAS_MANAGER), "GasManager missing GAS_MANAGER_ROLE");

        console2.log("Manager roles verified (oracle, bank, gas)");
    }

    /*//////////////////////////////////////////////////////////////
                    4. ORACLE FEED CHECKS (REAL ON-CHAIN DATA)
    //////////////////////////////////////////////////////////////*/

    /// @notice FLR/USD oracle returns a valid price via SuperOracle
    function test_flrUsdFeedLive() public view {
        (uint256 quoteAmount,,,) = oracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);

        console2.log("FLR/USD (1 FLR):", quoteAmount);

        assertGt(quoteAmount, 0, "FLR/USD price should be > 0");
        // FLR typically $0.001–$1
        assertGt(quoteAmount, 1e15, "FLR price should be > $0.001");
        assertLt(quoteAmount, 1e18, "FLR price should be < $1");
    }

    /// @notice GAS→WEI oracle returns non-zero via SuperOracle
    function test_gasToWeiFeedLive() public view {
        (uint256 quoteAmount,,,) = oracle.getQuoteFromProvider(1e18, GAS_QUOTE, WEI_QUOTE, PROVIDER_CHAINLINK);

        console2.log("GAS->WEI (1e18 gas units):", quoteAmount);
        assertGt(quoteAmount, 0, "GAS->WEI should be > 0");
    }

    /// @notice UP/USD returns $0.09 via FixedPriceOracle through SuperOracle
    function test_upUsdFeedLive() public view {
        (uint256 quoteAmount,,,) = oracle.getQuoteFromProvider(1e18, UP_OFT, USD_TOKEN, PROVIDER_SUPERFORM);

        console2.log("UP/USD (1 UP):", quoteAmount);
        assertEq(quoteAmount, 0.09e18, "UP price should be exactly $0.09");
    }

    /// @notice AVERAGE_PROVIDER works for FLR/USD
    function test_averageProviderFlrUsd() public view {
        (uint256 singleQuote,,,) = oracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);
        (uint256 avgQuote, uint256 deviation,, uint256 availableProviders) =
            oracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);

        assertEq(avgQuote, singleQuote, "Average should match single provider");
        assertEq(deviation, 0, "Deviation should be 0 with single provider");
        assertEq(availableProviders, 1, "Should have 1 available provider");
    }

    /*//////////////////////////////////////////////////////////////
                    5. FIXED PRICE ORACLE CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice FixedPriceOracle returns correct price and decimals
    function test_fixedPriceOracleConfig() public view {
        FixedPriceOracle fpo = FixedPriceOracle(FIXED_PRICE_ORACLE);

        assertEq(fpo.decimals(), 18, "FixedPriceOracle decimals should be 18");

        (, int256 price,,,) = fpo.latestRoundData();
        assertEq(price, 0.09e18, "FixedPriceOracle price should be $0.09");

        console2.log("FixedPriceOracle price:", uint256(price));
        console2.log("FixedPriceOracle decimals:", fpo.decimals());
    }

    /*//////////////////////////////////////////////////////////////
                    6. SUPERBANK CHECKS
    //////////////////////////////////////////////////////////////*/

    /// @notice SuperBank is deployed and accessible
    function test_superBankDeployed() public view {
        assertGt(SUPER_BANK.code.length, 0, "SuperBank should have code");

        // Verify SuperBank is registered in SuperGovernor
        address registeredBank = governor.getAddress(governor.SUPER_BANK());
        assertEq(registeredBank, SUPER_BANK, "SuperBank registration mismatch");

        console2.log("SuperBank verified at:", SUPER_BANK);
    }

    /*//////////////////////////////////////////////////////////////
                    7. DECIMAL SCALING VALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @notice 18-decimal FLR/USD feed scales linearly
    function test_flrUsdDecimalScaling() public view {
        (uint256 oneFlr,,,) = oracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);
        (uint256 tenFlr,,,) = oracle.getQuoteFromProvider(10e18, NATIVE_TOKEN, USD_TOKEN, PROVIDER_CHAINLINK);

        console2.log("1 FLR =", oneFlr, "USD");
        console2.log("10 FLR =", tenFlr, "USD");

        // Allow ±1 wei for rounding
        assertApproxEqAbs(tenFlr, oneFlr * 10, 1, "10 FLR should be 10x 1 FLR");
    }

    /// @notice UP/USD scales correctly for different amounts
    function test_upUsdScaling() public view {
        (uint256 oneUp,,,) = oracle.getQuoteFromProvider(1e18, UP_OFT, USD_TOKEN, PROVIDER_SUPERFORM);
        (uint256 hundredUp,,,) = oracle.getQuoteFromProvider(100e18, UP_OFT, USD_TOKEN, PROVIDER_SUPERFORM);

        console2.log("1 UP =", oneUp, "USD");
        console2.log("100 UP =", hundredUp, "USD");

        assertEq(oneUp, 0.09e18, "1 UP should be $0.09");
        assertApproxEqAbs(hundredUp, 9e18, 1, "100 UP should be $9.00");
    }
}
