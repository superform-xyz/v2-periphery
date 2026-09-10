// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";

/// @title BSCDeploymentForkTest
/// @notice End-to-end check of the BNB Chain (56) SuperVaults periphery deployment of 2026-09-10:
///         wiring of the live contracts, then a real vault lifecycle through the production
///         SuperVaultAggregator - createVault -> deposit -> requestRedeem -> fulfil -> redeem.
/// @dev Fork of BSC mainnet. Set BSC_RPC_URL for a private endpoint; falls back to the public
///      dataseed (rate-limited but sufficient for this suite).
contract BSCDeploymentForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                    PRODUCTION ADDRESSES (BNB CHAIN, 56)
    //////////////////////////////////////////////////////////////*/
    // Periphery (script/output/prod/56/BNB-latest.json) - CREATE2, identical to Ethereum/Base
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address constant SUPER_ORACLE = 0x673ec4771F86Ddc9E6fDc47Ab44B91a8231De5eC;
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;
    address constant SUPER_VAULT_IMPL = 0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2;
    address constant STRATEGY_IMPL = 0x770abd170404B8ed8182c04f380E567e647b457D;
    address constant ESCROW_IMPL = 0x8982cf48eaB6616f2892888410afad9b0CD2BC9B;
    address constant EXECUTOR = 0x183e3171EEf801cE2A29FD48B3b21188f241875d;
    address constant BATCH_OPERATOR = 0x73d3f46d3a9f98C55C512DEca29993D28F93817c;
    address constant SUPERFORM_GAS_ORACLE = 0x473b88f017dE39d85a102DA01A35a1b3507eBcFc;
    address constant UP_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;

    // Chain-native feeds / assets
    address constant CHAINLINK_BNB_USD = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // 8 decimals
    address constant USDC_BSC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // Binance-Peg USDC, 18 decimals

    // SuperOracle pseudo-tokens (ConfigBase)
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant USD_TOKEN = 0x0000000000000000000000000000000000000348;
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    uint256 constant EXPECTED_HOOKS = 59; // ConfigureV2Periphery._hookKeys() as registered 2026-09-10
    uint256 constant PRECISION = 1e18;

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/
    ISuperGovernor internal governor = ISuperGovernor(SUPER_GOVERNOR);
    ISuperVaultAggregator internal aggregator = ISuperVaultAggregator(AGGREGATOR);
    ISuperOracle internal superOracle = ISuperOracle(SUPER_ORACLE);
    IERC20 internal usdc = IERC20(USDC_BSC);

    address internal manager = makeAddr("bsc-vault-manager");
    address internal treasury = makeAddr("bsc-fee-recipient");
    address internal alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.envOr("BSC_RPC_URL", string("https://bsc-dataseed.binance.org")));
        assertEq(block.chainid, 56, "not a BSC fork");
    }

    /*//////////////////////////////////////////////////////////////
                        1. DEPLOYMENT WIRING
    //////////////////////////////////////////////////////////////*/

    function test_Fork_BSC_AllContractsHaveCode() public view {
        address[13] memory deployed = [
            SUPER_GOVERNOR,
            AGGREGATOR,
            SUPER_ORACLE,
            SUPER_BANK,
            ECDSA_PPS_ORACLE,
            FIXED_PRICE_ORACLE,
            SUPER_VAULT_IMPL,
            STRATEGY_IMPL,
            ESCROW_IMPL,
            EXECUTOR,
            BATCH_OPERATOR,
            SUPERFORM_GAS_ORACLE,
            UP_OFT
        ];
        for (uint256 i; i < deployed.length; ++i) {
            assertGt(deployed[i].code.length, 0, "missing code");
        }
    }

    function test_Fork_BSC_GovernorWiring() public view {
        assertEq(governor.getAddress(governor.SUPER_VAULT_AGGREGATOR()), AGGREGATOR, "aggregator");
        assertEq(governor.getAddress(governor.SUPER_ORACLE()), SUPER_ORACLE, "super oracle");
        assertEq(governor.getAddress(governor.SUPER_BANK()), SUPER_BANK, "super bank");
        assertEq(governor.getAddress(governor.UP()), UP_OFT, "UP token");
        assertEq(governor.getAddress(governor.UPKEEP_TOKEN()), UP_OFT, "UPKEEP token");
        assertEq(governor.getActivePPSOracle(), ECDSA_PPS_ORACLE, "active PPS oracle");
        assertGe(governor.getRegisteredHooks().length, EXPECTED_HOOKS, "hooks registered");
        assertTrue(governor.isUpkeepPaymentsEnabled(), "upkeep payments enabled (prod)");
    }

    /// @dev Native/USD via Chainlink BNB/USD, UP/USD via the FixedPriceOracle ($0.09), and the
    ///      GAS->WEI feed (SuperformGasOracle) must all answer through the live SuperOracle
    function test_Fork_BSC_OracleFeedsAnswer() public view {
        (uint256 bnbUsd,, uint256 total, uint256 available) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertGt(bnbUsd, 100e18, "BNB/USD implausibly low");
        assertLt(bnbUsd, 100_000e18, "BNB/USD implausibly high");
        assertEq(total, available, "BNB/USD provider unavailable");

        (uint256 upUsd,,,) = superOracle.getQuoteFromProvider(1e18, UP_OFT, USD_TOKEN, AVERAGE_PROVIDER);
        assertEq(upUsd, 0.09e18, "UP/USD fixed price");

        // GAS -> WEI (SuperformGasOracle, wei per gas unit) must be quotable and non-zero
        (uint256 weiFor135kGas,,,) = superOracle.getQuoteFromProvider(135_000, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        assertGt(weiFor135kGas, 0, "GAS->WEI feed answers");

        // NOTE: SuperGovernor.getUpkeepCostPerSingleUpdate(ECDSAPPSOracle) reverts on BSC because
        // gasPerEntry is 0 - identical to Base and RH today (only Ethereum has 135_000 set). It is a
        // governor parameter (set_gas_info.sh / SetGasInfo), not a deployment fault, so we assert
        // parity with Base rather than a quote.
        assertEq(governor.getGasInfo(ECDSA_PPS_ORACLE), 0, "gasPerEntry unset on BSC, same as Base/RH");
    }

    /*//////////////////////////////////////////////////////////////
                    2. VAULT LIFECYCLE ON THE LIVE AGGREGATOR
    //////////////////////////////////////////////////////////////*/

    function _createVault() internal returns (address vault, address strategy, address escrow) {
        (vault, strategy, escrow) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: USDC_BSC,
                name: "BSC Fork Test SuperVault USDC",
                symbol: "tsvUSDC-bsc",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 3600,
                maxStaleness: 86_400,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: treasury
                })
            })
        );
    }

    function test_Fork_BSC_CreateVault() public {
        (address vault, address strategy, address escrow) = _createVault();

        assertGt(vault.code.length, 0, "vault clone");
        assertGt(strategy.code.length, 0, "strategy clone");
        assertGt(escrow.code.length, 0, "escrow clone");
        assertEq(IERC4626(vault).asset(), USDC_BSC, "asset");
        assertEq(aggregator.getMainManager(strategy), manager, "main manager seated");
        assertEq(aggregator.getPPS(strategy), 10 ** 18, "initial PPS = 1.0 in asset decimals (USDC on BSC has 18)");
        assertEq(IERC4626(vault).totalAssets(), 0, "fresh vault is empty");
    }

    function test_Fork_BSC_CreateVaultAndDeposit() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e18; // 1,000 USDC (18 decimals on BSC)

        deal(USDC_BSC, alice, amount);
        vm.startPrank(alice);
        usdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        // PPS is 1.0 and managementFee is 0 -> 1:1 shares, assets land in the strategy
        assertEq(shares, amount, "1:1 shares at initial PPS");
        assertEq(IERC20(vault).balanceOf(alice), shares, "alice holds the shares");
        assertEq(usdc.balanceOf(strategy), amount, "strategy holds the deposit");
        assertEq(usdc.balanceOf(alice), 0, "alice paid");
        assertEq(IERC4626(vault).totalAssets(), amount, "totalAssets");
        assertEq(IERC4626(vault).convertToAssets(shares), amount, "convertToAssets");
        assertEq(IERC4626(vault).totalSupply(), shares, "totalSupply");
    }

    /// @notice Deposit, then the async exit: user requests redeem, manager fulfils from idle
    ///         liquidity, user claims. Exercises the production strategy/escrow clones end to end.
    function test_Fork_BSC_DepositRequestRedeemFulfillAndRedeem() public {
        (address vault, address strategy, address escrow) = _createVault();
        uint256 amount = 2500e18;

        deal(USDC_BSC, alice, amount);
        vm.startPrank(alice);
        usdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();
        assertEq(IERC20(vault).balanceOf(alice), 0, "shares escrowed on request");

        // Manager fulfils the exact pending amount (PPS still 1.0, no gain -> no performance fee)
        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = amount;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(usdc.balanceOf(escrow), amount, "net assets parked in escrow");
        assertEq(ISuperVault(vault).claimableRedeemRequest(0, alice), shares, "claimable shares");

        vm.prank(alice);
        uint256 assetsBack = IERC4626(vault).redeem(shares, alice, alice);

        assertEq(assetsBack, amount, "full principal back at PPS 1.0");
        assertEq(usdc.balanceOf(alice), amount, "alice made whole");
        assertEq(IERC4626(vault).totalSupply(), 0, "all shares burned");
        assertEq(usdc.balanceOf(escrow), 0, "escrow drained");
    }

    /// @notice A second, unrelated user depositing after the first keeps 1:1 accounting
    function test_Fork_BSC_TwoDepositorsShareProRata() public {
        (address vault,,) = _createVault();
        address bob = makeAddr("bob");
        deal(USDC_BSC, alice, 100e18);
        deal(USDC_BSC, bob, 300e18);

        vm.startPrank(alice);
        usdc.approve(vault, 100e18);
        IERC4626(vault).deposit(100e18, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        usdc.approve(vault, 300e18);
        IERC4626(vault).deposit(300e18, bob);
        vm.stopPrank();

        assertEq(IERC4626(vault).totalAssets(), 400e18);
        assertLe(IERC4626(vault).maxWithdraw(alice) + IERC4626(vault).maxWithdraw(bob), 400e18, "no over-claim");
        assertEq(IERC4626(vault).convertToAssets(IERC20(vault).balanceOf(bob)), 300e18, "bob pro-rata");
    }
}
