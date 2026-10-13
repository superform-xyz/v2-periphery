// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
    function decimals() external view returns (uint8);
}

/// @title PlatabergetDeploymentForkTest
/// @notice End-to-end check of the Platåberget (Glamsterdam testnet, chain 7091047534) staging
///         deployment of 2026-09-15: wiring of the live periphery against the live v2-core stack,
///         oracle feeds under post-fork EVM rules, then a real vault lifecycle through the
///         production SuperVaultAggregator — createVault → mint mock USDC → deposit.
/// @dev Fork of Platåberget. Set PLATABERGET_RPC_URL for a private endpoint; falls back to the
///      public ethpandaops gateway (flaky under load but sufficient for this suite).
///      This is the first Superform vault lifecycle exercised under Glamsterdam gas rules
///      (EIP-8037 two-dimensional gas, EIP-2780 intrinsic split, EIP-7708 transfer logs).
contract PlatabergetDeploymentForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                STAGING ADDRESSES (PLATABERGET, 7091047534)
    //////////////////////////////////////////////////////////////*/
    // Periphery (script/output/staging/7091047534/Plataberget-latest.json)
    address constant SUPER_GOVERNOR = 0x0370F5F5f1a63688b16c60D59B19C7469ddb3D6b;
    address constant AGGREGATOR = 0xB383D4063d67F5452Df3e8A7C0062Eabc4049728;
    address constant SUPER_ORACLE = 0x76c78df642BB04556ad931CEC8B5fad85c34879A; // L1 SuperOracle (no sequencer)
    address constant SUPER_BANK = 0x69d53e376264EEb567213f07d8136050f99eeeC0;
    address constant ECDSA_PPS_ORACLE = 0x68718f31849f266dF64df08320776a39f06efaBd;
    address constant FIXED_PRICE_ORACLE = 0xb1E823c84e4aa9Ca38e2f82d3131412254099197;
    address constant SUPER_VAULT_IMPL = 0xB2fA782406453Fb345cDD7f2c3586003A3FE2bBB;
    address constant STRATEGY_IMPL = 0xaE15a0Cec3ef44843E7A88e0E5FA7A7527e6BC73;
    address constant ESCROW_IMPL = 0xC961bd0356b2318820bf79Fe21D23269A42B8863;
    address constant SUPERFORM_GAS_ORACLE = 0xCa35c983e810fBFe952A6CA59120fd9a8d2d58e3;

    // v2-core (script/output/staging/7091047534/Plataberget-latest.json in v2-core)
    address constant SUPER_LEDGER_CONFIGURATION = 0x102146454720de58Ee1331F7a91cdCC1F0c346E0;
    address constant SUPER_VALIDATOR = 0x5C563Ba4881e3c2710BABe76282895EfE5C8247d;
    address constant SUPER_EXECUTOR = 0xdC903190CF37993e970aA0b15cCC6e08EA12BCa0;
    address constant SUPER_DESTINATION_EXECUTOR = 0xd0B5d200a6B136D619Dd1c7BBA30b004b4773C40;

    // Devnet stand-ins (no Chainlink / LayerZero / canonical USDC on Platåberget)
    address constant MOCK_USDC = 0xec61E6337874d159DbF2b1bff88aC1b9e6Bf93bf; // MockERC20 "USDC", 6 dec, open mint
    // Serves as both UP and UPKEEP token in the governor (no UpOFT on the devnet)

    // SuperOracle pseudo-tokens (ConfigBase)
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant USD_TOKEN = 0x0000000000000000000000000000000000000348;
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    uint256 constant GLAMSTERDAM_MIN_BLOCK_GAS_LIMIT = 150_000_000; // limit ramps toward 200M in 1/1024 steps

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/
    ISuperGovernor internal governor = ISuperGovernor(SUPER_GOVERNOR);
    ISuperVaultAggregator internal aggregator = ISuperVaultAggregator(AGGREGATOR);
    ISuperOracle internal superOracle = ISuperOracle(SUPER_ORACLE);
    IMintableERC20 internal usdc = IMintableERC20(MOCK_USDC);

    address internal manager = makeAddr("plataberget-vault-manager");
    address internal treasury = makeAddr("plataberget-fee-recipient");
    address internal alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.envOr("PLATABERGET_RPC_URL", string("https://rpc.plataberget.ethpandaops.io")));
        assertEq(block.chainid, 7_091_047_534, "not a Plataberget fork");
    }

    /*//////////////////////////////////////////////////////////////
                        1. DEPLOYMENT WIRING
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Plataberget_AllContractsHaveCode() public view {
        address[14] memory deployed = [
            SUPER_GOVERNOR,
            AGGREGATOR,
            SUPER_ORACLE,
            SUPER_BANK,
            ECDSA_PPS_ORACLE,
            FIXED_PRICE_ORACLE,
            SUPER_VAULT_IMPL,
            STRATEGY_IMPL,
            ESCROW_IMPL,
            SUPERFORM_GAS_ORACLE,
            MOCK_USDC,
            SUPER_LEDGER_CONFIGURATION,
            SUPER_VALIDATOR,
            SUPER_EXECUTOR
        ];
        for (uint256 i; i < deployed.length; ++i) {
            assertGt(deployed[i].code.length, 0, "missing code");
        }
    }

    /// @notice The chain itself must be running Glamsterdam rules — that is the point of this fork
    function test_Fork_Plataberget_IsGlamsterdam() public view {
        assertGe(block.gaslimit, GLAMSTERDAM_MIN_BLOCK_GAS_LIMIT, "post-fork ~200M block gas limit");
    }

    function test_Fork_Plataberget_GovernorWiring() public view {
        assertEq(governor.getAddress(governor.SUPER_VAULT_AGGREGATOR()), AGGREGATOR, "aggregator wired");
        assertEq(governor.getAddress(governor.SUPER_ORACLE()), SUPER_ORACLE, "oracle wired");
        assertEq(governor.getAddress(governor.SUPER_BANK()), SUPER_BANK, "bank wired");
        assertEq(governor.getAddress(governor.UP()), MOCK_USDC, "UP token = mock USDC (devnet stand-in)");
        assertEq(governor.getAddress(governor.UPKEEP_TOKEN()), MOCK_USDC, "UPKEEP token = mock USDC");
        assertEq(governor.getActivePPSOracle(), ECDSA_PPS_ORACLE, "active PPS oracle");
    }

    /// @notice All three oracle feeds answer under post-fork rules (keeper-pushed SuperformGasOracle
    ///         backs both gas and ETH/USD; FixedPriceOracle backs UP/USD)
    function test_Fork_Plataberget_OracleFeedsValid() public view {
        (uint256 ethUsd,,, uint256 available1) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertGt(ethUsd, 0, "ETH/USD quote");
        assertGt(available1, 0, "ETH/USD providers");

        (uint256 gasWei,,, uint256 available2) =
            superOracle.getQuoteFromProvider(1, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        assertGt(gasWei, 0, "gas/wei quote");
        assertGt(available2, 0, "gas/wei providers");

        (uint256 upUsd,,, uint256 available3) =
            superOracle.getQuoteFromProvider(1e6, MOCK_USDC, USD_TOKEN, AVERAGE_PROVIDER);
        assertGt(upUsd, 0, "UP/USD quote");
        assertGt(available3, 0, "UP/USD providers");
    }

    /*//////////////////////////////////////////////////////////////
                    2. VAULT CREATION (REAL AGGREGATOR)
    //////////////////////////////////////////////////////////////*/

    function _createVault() internal returns (address vault, address strategy, address escrow) {
        (vault, strategy, escrow) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: MOCK_USDC,
                name: "Plataberget Fork Test SuperVault USDC",
                symbol: "tsvUSDC-plat",
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

    function test_Fork_Plataberget_CreateVault() public {
        (address vault, address strategy, address escrow) = _createVault();

        assertGt(vault.code.length, 0, "vault clone");
        assertGt(strategy.code.length, 0, "strategy clone");
        assertGt(escrow.code.length, 0, "escrow clone");
        assertEq(IERC4626(vault).asset(), MOCK_USDC, "asset");
        assertEq(aggregator.getMainManager(strategy), manager, "main manager seated");
        assertEq(aggregator.getPPS(strategy), 10 ** 6, "initial PPS = 1.0 in asset decimals (USDC has 6)");
        assertEq(IERC4626(vault).totalAssets(), 0, "fresh vault is empty");
    }

    /*//////////////////////////////////////////////////////////////
                    3. DEPOSIT (REAL MINT, REAL VAULT)
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Plataberget_CreateVaultAndDeposit() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6; // 1,000 USDC (6 decimals)

        // Real mint on the deployed mock — no balance cheatcodes on the asset
        usdc.mint(alice, amount);
        assertEq(usdc.balanceOf(alice), amount, "minted");

        vm.startPrank(alice);
        usdc.approve(vault, amount);
        uint256 gasBefore = gasleft();
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        uint256 depositGas = gasBefore - gasleft();
        vm.stopPrank();

        console2.log("deposit() gas under fork-local EVM:", depositGas);

        // PPS is 1.0 and managementFee is 0 -> 1:1 shares, assets land in the strategy
        assertEq(shares, amount, "1:1 shares at initial PPS");
        assertEq(IERC20(vault).balanceOf(alice), shares, "alice holds the shares");
        assertEq(usdc.balanceOf(strategy), amount, "strategy holds the deposit");
        assertEq(usdc.balanceOf(alice), 0, "alice paid");
        assertEq(IERC4626(vault).totalAssets(), amount, "totalAssets");
        assertEq(IERC4626(vault).convertToAssets(shares), amount, "convertToAssets");
        assertEq(IERC4626(vault).totalSupply(), shares, "totalSupply");
    }

    /// @notice Second depositor at unchanged PPS gets proportional shares — sanity that share math
    ///         holds on the live clones
    function test_Fork_Plataberget_TwoDepositors() public {
        (address vault,,) = _createVault();
        address bob = makeAddr("bob");

        usdc.mint(alice, 500e6);
        usdc.mint(bob, 1500e6);

        vm.startPrank(alice);
        usdc.approve(vault, 500e6);
        uint256 aliceShares = IERC4626(vault).deposit(500e6, alice);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(vault, 1500e6);
        uint256 bobShares = IERC4626(vault).deposit(1500e6, bob);
        vm.stopPrank();

        assertEq(aliceShares, 500e6, "alice 1:1");
        assertEq(bobShares, 1500e6, "bob 1:1 at unchanged PPS");
        assertEq(IERC4626(vault).totalAssets(), 2000e6, "pooled assets");
        assertEq(IERC4626(vault).totalSupply(), 2000e6, "pooled shares");
    }
}
