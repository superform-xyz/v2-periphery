// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";

interface IGasFeed {
    function latestAnswer() external view returns (int256);
}

/// @notice Stand-in for Arc's native-balance precompile at `0x1800...0000`, which the USDC token
///         calls to settle every transfer. The real one is served by the Arc node; revm only sees
///         the 0xef marker byte and aborts with OpcodeNotFound, so a fork has to supply the move.
/// @dev No contract can debit a third party's native balance, so the stub reaches for the cheatcode
///      address to do exactly what the node does: subtract from the sender, add to the receiver.
///      Amounts are 18-decimal native wei, as the precompile receives them.
contract ArcNativeTransferPrecompile {
    Vm private constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    error ARC_INSUFFICIENT_BALANCE();

    function transfer(address from, address to, uint256 amount) external returns (bool) {
        uint256 fromBalance = from.balance;
        if (fromBalance < amount) revert ARC_INSUFFICIENT_BALANCE();
        if (from == to) return true;
        VM.deal(from, fromBalance - amount);
        VM.deal(to, to.balance + amount);
        return true;
    }
}

/// @title ArcDeploymentForkTest
/// @notice End-to-end check of the Arc (Circle L1, chain 5042) SuperVaults periphery deployment:
///         the live contracts from script/output/prod/5042/Arc-latest.json are used as-is - none of
///         them is redeployed or mocked - and a real vault lifecycle is driven through the
///         production SuperVaultAggregator: createVault -> deposit (ERC-4626) -> requestRedeem ->
///         fulfilRedeem -> redeem (ERC-7540). The only code this suite supplies is Arc's own node
///         precompiles, which have no bytecode to fork (see `setUp`).
/// @dev Arc's asset model is unusual and the suite pins it down explicitly:
///      - USDC is the *native* gas token with 18 decimals, and `0x3600...0000` is an ERC-20 view
///        over that same native balance with 6 decimals (1 native wei = 1e-12 USDC units).
///        Consequence: `deal(USDC_ARC, user, x)` cannot work (there is no balance slot to write);
///        funding happens with `vm.deal(user, x * 1e12)` instead - see `_fundUsdc`.
///      - the vault asset therefore has 6 decimals, so the initial PPS is 1e6, not 1e18.
///      - USDC movements are settled by node precompiles at `0x1800...0000/0001` rather than by
///        solidity, so no receiving contract needs a `receive()` for assets to land.
/// @dev Fork of Arc mainnet. Set ARC_RPC_URL (or ARC_MAINNET, as the deploy runners use) for a
///      private endpoint; falls back to the official public RPC.
contract ArcDeploymentForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                       PRODUCTION ADDRESSES (ARC, 5042)
    //////////////////////////////////////////////////////////////*/
    // Periphery (script/output/prod/5042/Arc-latest.json) - CREATE2, identical to Ethereum/Base/BSC
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address constant SUPER_ORACLE = 0x15fC3d92d31b1a19c1368f9Db801a418060e46B1;
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;
    address constant SUPER_VAULT_IMPL = 0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2;
    address constant STRATEGY_IMPL = 0x770abd170404B8ed8182c04f380E567e647b457D;
    address constant ESCROW_IMPL = 0x8982cf48eaB6616f2892888410afad9b0CD2BC9B;
    address constant SUPERFORM_GAS_ORACLE = 0x473b88f017dE39d85a102DA01A35a1b3507eBcFc;
    address constant UP_OFT = 0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E;

    /// @dev Arc's ERC-20 view over the native USDC balance (6 decimals). Native USDC has 18.
    address constant USDC_ARC = 0x3600000000000000000000000000000000000000;
    /// @dev native (18 dec) -> ERC-20 USDC (6 dec)
    uint256 constant NATIVE_PER_USDC_UNIT = 1e12;
    /// @dev Arc node precompiles the USDC token leans on: `0x1800...0000` moves native balance,
    ///      `0x1800...0001` answers `isBlocklisted(address)`. Both carry only the marker byte 0xef
    ///      on chain and are served natively by the node.
    address constant ARC_NATIVE_TRANSFER_PRECOMPILE = 0x1800000000000000000000000000000000000000;
    address constant ARC_BLOCKLIST_PRECOMPILE = 0x1800000000000000000000000000000000000001;
    /// @dev the marker byte Arc puts at its nodeside precompiles (0xef is not a valid opcode)
    bytes constant ARC_PRECOMPILE_MARKER = hex"ef";
    /// @dev PUSH1 0x20 PUSH1 0x00 RETURN - returns 32 zero bytes, i.e. `false` / not blocklisted
    bytes constant NOT_BLOCKLISTED_STUB = hex"60206000f3";

    // SuperOracle pseudo-tokens (ConfigBase). NATIVE on Arc is USDC, priced by Chainlink USDC/USD.
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant USD_TOKEN = 0x0000000000000000000000000000000000000348;
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    uint256 constant EXPECTED_HOOKS = 38; // ConfigureV2Periphery hook set as registered on Arc
    uint256 constant PRECISION = 1e18;
    uint256 constant GAS_PER_ENTRY = 135_000; // what SetGasInfo applies once it is run on Arc
    uint256 constant UP_USD_PRICE = 0.09e18; // FixedPriceOracle
    uint256 constant MIN_UPDATE_INTERVAL = 3600;
    uint256 constant MAX_STALENESS = 86_400;

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/
    ISuperGovernor internal governor = ISuperGovernor(SUPER_GOVERNOR);
    ISuperVaultAggregator internal aggregator = ISuperVaultAggregator(AGGREGATOR);
    ISuperOracle internal superOracle = ISuperOracle(SUPER_ORACLE);
    IERC20 internal usdc = IERC20(USDC_ARC);

    address internal manager = makeAddr("arc-vault-manager");
    address internal treasury = makeAddr("arc-fee-recipient");
    address internal alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.envOr("ARC_RPC_URL", vm.envOr("ARC_MAINNET", string("https://rpc.mainnet.arc.io"))));
        assertEq(block.chainid, 5042, "not an Arc fork");

        // Every USDC movement on Arc goes through two node precompiles: one moves the native
        // balance, one screens both parties against the blocklist. On chain they hold nothing but
        // the marker byte 0xef and are answered by the node, so revm hits OpcodeNotFound and every
        // transfer would abort on a fork. Nothing of ours is mocked here - this only hands revm the
        // node behaviour it lacks, and it hands back the same answers the live chain gives for the
        // fresh accounts this suite uses: the balance moves, and nobody is blocklisted.
        assertEq(ARC_NATIVE_TRANSFER_PRECOMPILE.code, ARC_PRECOMPILE_MARKER, "transfer precompile is nodeside");
        assertEq(ARC_BLOCKLIST_PRECOMPILE.code, ARC_PRECOMPILE_MARKER, "blocklist precompile is nodeside");
        vm.etch(ARC_NATIVE_TRANSFER_PRECOMPILE, address(new ArcNativeTransferPrecompile()).code);
        vm.allowCheatcodes(ARC_NATIVE_TRANSFER_PRECOMPILE); // the stub settles balances via vm.deal
        vm.etch(ARC_BLOCKLIST_PRECOMPILE, NOT_BLOCKLISTED_STUB);
    }

    /*//////////////////////////////////////////////////////////////
                          1. DEPLOYMENT WIRING
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Arc_AllContractsHaveCode() public view {
        address[11] memory deployed = [
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
            UP_OFT
        ];
        for (uint256 i; i < deployed.length; ++i) {
            assertGt(deployed[i].code.length, 0, "missing code");
        }
    }

    function test_Fork_Arc_GovernorWiring() public view {
        assertEq(governor.getAddress(governor.SUPER_VAULT_AGGREGATOR()), AGGREGATOR, "aggregator");
        assertEq(governor.getAddress(governor.SUPER_ORACLE()), SUPER_ORACLE, "super oracle");
        assertEq(governor.getAddress(governor.SUPER_BANK()), SUPER_BANK, "super bank");
        assertEq(governor.getAddress(governor.UP()), UP_OFT, "UP token");
        assertEq(governor.getAddress(governor.UPKEEP_TOKEN()), UP_OFT, "UPKEEP token");
        assertEq(governor.getActivePPSOracle(), ECDSA_PPS_ORACLE, "active PPS oracle");
        assertGe(governor.getRegisteredHooks().length, EXPECTED_HOOKS, "hooks registered");
        assertTrue(governor.isUpkeepPaymentsEnabled(), "upkeep payments enabled (prod)");
        assertLe(governor.getMinStaleness(), MAX_STALENESS, "min staleness allows a 24h vault");
    }

    /*//////////////////////////////////////////////////////////////
                      2. ARC'S NATIVE-USDC ASSET MODEL
    //////////////////////////////////////////////////////////////*/

    /// @notice `0x3600...0000` is an ERC-20 facade over the native balance: 6 decimals against the
    ///         18-decimal native USDC, so an account's ERC-20 balance is always native / 1e12.
    function test_Fork_Arc_UsdcErc20MirrorsNativeBalance() public {
        assertGt(USDC_ARC.code.length, 0, "USDC ERC-20 deployed");
        assertEq(IERC20Metadata(USDC_ARC).symbol(), "USDC", "symbol");
        assertEq(IERC20Metadata(USDC_ARC).decimals(), 6, "6 decimals on the ERC-20 side");

        vm.deal(alice, 1234.567891e18); // 1,234.567891 USDC expressed in 18-decimal native wei
        assertEq(usdc.balanceOf(alice), 1_234_567_891, "ERC-20 balance == native / 1e12");
        assertEq(alice.balance, 1234.567891e18, "native balance untouched by the view");

        // ERC-20 movements settle as native movements
        address bob = makeAddr("bob");
        vm.prank(alice);
        usdc.transfer(bob, 234.567891e6);
        assertEq(usdc.balanceOf(alice), 1000e6, "sender debited");
        assertEq(bob.balance, 234.567891e18, "receiver credited in native too");
    }

    /*//////////////////////////////////////////////////////////////
                      3. ORACLE FEEDS ON THE LIVE ARC SETUP
    //////////////////////////////////////////////////////////////*/

    /// @dev NATIVE/USD is Chainlink USDC/USD on Arc (the gas token is USDC), UP/USD is the
    ///      FixedPriceOracle at $0.09, and GAS->WEI is the SuperformGasOracle.
    function test_Fork_Arc_OracleFeedsAnswer() public view {
        (uint256 nativeUsd,, uint256 total, uint256 available) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertEq(total, available, "NATIVE/USD provider unavailable");
        // native is USDC, so it must sit on the dollar
        assertApproxEqRel(nativeUsd, 1e18, 0.02e18, "NATIVE(USDC)/USD off peg");

        (uint256 upUsd,,,) = superOracle.getQuoteFromProvider(1e18, UP_OFT, USD_TOKEN, AVERAGE_PROVIDER);
        assertEq(upUsd, UP_USD_PRICE, "UP/USD fixed price");

        uint256 weiPerGas = uint256(IGasFeed(SUPERFORM_GAS_ORACLE).latestAnswer());
        assertGt(weiPerGas, 0, "gas oracle answers");
        (uint256 weiForUpdate,,,) =
            superOracle.getQuoteFromProvider(GAS_PER_ENTRY, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        assertEq(weiForUpdate, GAS_PER_ENTRY * weiPerGas, "GAS->WEI is linear in the oracle answer");
    }

    /// @notice gasPerEntry is still unset on Arc, which makes the UP quote per PPS update revert
    ///         (a zero gas amount quotes to zero, the oracle skips zero quotes, count == 0).
    ///         Paid PPS updates stay blocked until `SetGasInfo(ECDSAPPSOracle, 135_000)` is run;
    ///         once it is, this test flips to the full feed reconciliation instead.
    function test_Fork_Arc_UpkeepQuoteNeedsGasInfo() public {
        uint256 gasPerEntry = governor.getGasInfo(ECDSA_PPS_ORACLE);

        if (gasPerEntry == 0) {
            vm.expectRevert(ISuperOracle.NO_VALID_REPORTED_PRICES.selector);
            governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
            console2.log("Arc: gasPerEntry unset - SetGasInfo still pending, PPS updates cannot be paid for");
            return;
        }

        // gas -> wei -> USD -> UP, the same composition the BSC suite pins
        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        (uint256 weiForUpdate,,,) =
            superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        (uint256 usdForUpdate,,,) =
            superOracle.getQuoteFromProvider(weiForUpdate, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertApproxEqRel(cost, usdForUpdate * PRECISION / UP_USD_PRICE, 1e12, "UP cost = usd(gas) / usd(UP)");
        console2.log("Arc upkeep cost per PPS update (UP wei):", cost);
    }

    /*//////////////////////////////////////////////////////////////
                4. VAULT LIFECYCLE ON THE LIVE AGGREGATOR
    //////////////////////////////////////////////////////////////*/

    function _createVault() internal returns (address vault, address strategy, address escrow) {
        (vault, strategy, escrow) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: USDC_ARC,
                name: "Arc Fork Test SuperVault USDC",
                symbol: "tsvUSDC-arc",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: MIN_UPDATE_INTERVAL,
                maxStaleness: MAX_STALENESS,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: treasury
                })
            })
        );
    }

    /// @dev `deal(USDC_ARC, ...)` is impossible on Arc (the ERC-20 has no balance storage), so the
    ///      account is funded natively and read back through the ERC-20 view.
    function _fundUsdc(address to, uint256 amount6) internal {
        vm.deal(to, amount6 * NATIVE_PER_USDC_UNIT);
        assertEq(usdc.balanceOf(to), amount6, "funding did not land");
    }

    function test_Fork_Arc_CreateVault() public {
        (address vault, address strategy, address escrow) = _createVault();

        assertGt(vault.code.length, 0, "vault clone");
        assertGt(strategy.code.length, 0, "strategy clone");
        assertGt(escrow.code.length, 0, "escrow clone");
        assertEq(IERC4626(vault).asset(), USDC_ARC, "asset");
        assertEq(IERC20Metadata(vault).decimals(), 6, "share decimals follow the 6-decimal asset");
        assertEq(aggregator.getMainManager(strategy), manager, "main manager seated");
        assertEq(aggregator.getPPS(strategy), 1e6, "initial PPS = 1.0 in asset decimals (USDC has 6)");
        assertEq(aggregator.getMinUpdateInterval(strategy), MIN_UPDATE_INTERVAL, "min update interval");
        assertEq(aggregator.getMaxStaleness(strategy), MAX_STALENESS, "max staleness");
        assertFalse(aggregator.isStrategyPaused(strategy), "fresh strategy live");
        assertFalse(aggregator.isPPSStale(strategy), "fresh PPS");
        assertEq(IERC4626(vault).totalAssets(), 0, "fresh vault is empty");
    }

    function test_Fork_Arc_CreateVaultAndDeposit() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6; // 1,000 USDC

        _fundUsdc(alice, amount);
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

    /// @notice The full flow the Arc deployment has to support: create a vault on the production
    ///         aggregator, deposit through ERC-4626, request the async exit, have the manager fulfil
    ///         it from idle liquidity, and claim the assets back.
    function test_Fork_Arc_FullFlow_CreateDepositRequestRedeemFulfillAndRedeem() public {
        (address vault, address strategy, address escrow) = _createVault();
        uint256 amount = 2500e6; // 2,500 USDC

        // --- deposit (ERC-4626) ---
        _fundUsdc(alice, amount);
        vm.startPrank(alice);
        usdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        assertEq(shares, amount, "1:1 shares at PPS 1.0");
        assertEq(usdc.balanceOf(strategy), amount, "deposit parked in the strategy");

        // --- request the async exit (ERC-7540) ---
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();
        assertEq(IERC20(vault).balanceOf(alice), 0, "shares escrowed on request");
        assertEq(ISuperVault(vault).pendingRedeemRequest(0, alice), shares, "request pending");

        // --- manager fulfils the exact pending amount (PPS still 1.0 -> no performance fee) ---
        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = amount;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(usdc.balanceOf(escrow), amount, "net assets parked in escrow");
        assertEq(usdc.balanceOf(strategy), 0, "strategy drained");
        assertEq(ISuperVault(vault).pendingRedeemRequest(0, alice), 0, "nothing pending anymore");
        assertEq(ISuperVault(vault).claimableRedeemRequest(0, alice), shares, "claimable shares");

        // --- claim ---
        vm.prank(alice);
        uint256 assetsBack = IERC4626(vault).redeem(shares, alice, alice);

        assertEq(assetsBack, amount, "full principal back at PPS 1.0");
        assertEq(usdc.balanceOf(alice), amount, "alice made whole");
        assertEq(alice.balance, amount * NATIVE_PER_USDC_UNIT, "and in native terms too");
        assertEq(IERC4626(vault).totalSupply(), 0, "all shares burned");
        assertEq(IERC4626(vault).totalAssets(), 0, "vault empty again");
        assertEq(usdc.balanceOf(escrow), 0, "escrow drained");
    }

    /// @notice A second, unrelated depositor keeps pro-rata accounting on the 6-decimal asset
    function test_Fork_Arc_TwoDepositorsShareProRata() public {
        (address vault,,) = _createVault();
        address bob = makeAddr("bob");
        _fundUsdc(alice, 100e6);
        _fundUsdc(bob, 300e6);

        vm.startPrank(alice);
        usdc.approve(vault, 100e6);
        IERC4626(vault).deposit(100e6, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        usdc.approve(vault, 300e6);
        IERC4626(vault).deposit(300e6, bob);
        vm.stopPrank();

        assertEq(IERC4626(vault).totalAssets(), 400e6, "pooled assets");
        assertLe(IERC4626(vault).maxWithdraw(alice) + IERC4626(vault).maxWithdraw(bob), 400e6, "no over-claim");
        assertEq(IERC4626(vault).convertToAssets(IERC20(vault).balanceOf(bob)), 300e6, "bob pro-rata");
    }
}
