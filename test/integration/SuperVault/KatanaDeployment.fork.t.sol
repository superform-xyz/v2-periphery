// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";

/// @dev `ppsExpiration` is a public state variable on SuperVaultStrategy but is not part of
///      ISuperVaultStrategy, so it is reached through this minimal interface.
interface IStrategyPPSExpiration {
    function ppsExpiration() external view returns (uint256);
}

interface IGasFeed {
    function latestAnswer() external view returns (int256);
}

interface IHookInspector {
    function inspect(bytes calldata data) external view returns (bytes memory);
}

/// @dev The implementation getters are public immutables on SuperVaultAggregator but are not part
///      of ISuperVaultAggregator, so they are reached through this minimal interface.
interface IAggregatorImpls {
    function VAULT_IMPLEMENTATION() external view returns (address);
    function STRATEGY_IMPLEMENTATION() external view returns (address);
    function ESCROW_IMPLEMENTATION() external view returns (address);
}

/// @title KatanaDeploymentForkTest
/// @notice End-to-end check of the Katana (chain 747474) SuperVaults periphery deployment. The
///         live contracts from script/output/prod/747474/Katana-latest.json are used as-is: none
///         is redeployed or mocked. A real vault lifecycle runs through the production
///         SuperVaultAggregator (createVault -> deposit -> requestRedeem -> fulfilRedeem ->
///         redeem), and real v2-core ERC-4626 hooks are executed against a real Katana yield
///         source.
/// @dev Katana facts this suite pins down:
///      - There is no plain USDC/WETH on Katana. The canonical assets are Vault Bridge wrappers,
///        so the vault asset here is vbUSDC (6 decimals) and the initial PPS is 1e6, not 1e18.
///      - 62 v2-core hooks are DEPLOYED on Katana but, at the time of writing, NONE is registered
///        in the SuperGovernor and the global hooks root is zero. `executeHooks` gates on
///        `isHookRegistered` first, so no hook can run on Katana until the hook-registration step
///        is completed. `test_Fork_Katana_HookRegistrationGap` asserts that state deliberately so
///        this suite reports the blocker rather than hiding it, and the hook execution tests
///        register what they need inside the fork (via the live GOVERNOR_ROLE holder) to prove the
///        machinery works and will keep working once registration lands for real.
///      - Swap hooks do not exist on Katana at all, and Aave/Morpho/Euler/Pendle hooks have no
///        protocol instance there, so ERC-4626 is the only hook family with a live target.
/// @dev Fork of Katana mainnet. Set KATANA_RPC_URL for a private endpoint; falls back to public.
contract KatanaDeploymentForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                    PRODUCTION ADDRESSES (KATANA, 747474)
    //////////////////////////////////////////////////////////////*/
    // Periphery - script/output/prod/747474/Katana-latest.json
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address constant SUPER_ORACLE = 0x7d02Dff6A19204441ED8B60bF49c974c16b6C201;
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;
    address constant SUPER_VAULT_IMPL = 0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2;
    address constant STRATEGY_IMPL = 0x770abd170404B8ed8182c04f380E567e647b457D;
    address constant ESCROW_IMPL = 0x8982cf48eaB6616f2892888410afad9b0CD2BC9B;
    address constant SUPERFORM_GAS_ORACLE = 0x473b88f017dE39d85a102DA01A35a1b3507eBcFc;
    address constant SUPER_VAULT_EXECUTOR = 0x183e3171EEf801cE2A29FD48B3b21188f241875d;
    address constant SUPER_VAULT_BATCH_OPERATOR = 0x73d3f46d3a9f98C55C512DEca29993D28F93817c;
    address constant UP_OFT = 0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E;

    // v2-core hooks - script/output/prod/747474/Katana-latest.json (sibling v2-core repo)
    address constant APPROVE_AND_DEPOSIT_4626_HOOK = 0xba687c9D5113a3B2692fd87b0F389dD5fF402808;
    address constant REDEEM_4626_HOOK = 0x95C61fE513885E23Bd7DA1f27B1ad9B16AE29f81;
    address constant ERC4626_YIELD_SOURCE_ORACLE = 0x2412A5d7261995b49D1F3a731F8452641B916994;
    /// @dev The ERC4626 yield-source-oracle id as REGISTERED in Katana's SuperLedgerConfiguration
    ///      (0x2e2D7128...). Read off chain rather than re-derived: the id is a hash of a key and
    ///      the registering manager, and resolving it through
    ///      `getYieldSourceOracleConfig(id).yieldSourceOracle == ERC4626_YIELD_SOURCE_ORACLE` is the
    ///      only way to be sure which of the 8 registered ids is the 4626 one.
    bytes32 constant ERC4626_ORACLE_ID = 0x81ffb9d6917afb4d997776145a0ffe622f312cc61d79bb2bf50c292cb338f5f8;

    /// @dev Vault Bridge USDC: the canonical 6-decimal dollar asset on Katana, deepest activity
    ///      and the asset most Katana ERC-4626 vaults are built on.
    address constant VB_USDC = 0x203A662b0BD271A6ed5a60EdFbd04bFce608FD36;
    /// @dev Yearn's vbUSDC vault - real TVL, deposits uncapped. The hook target.
    address constant YVVB_USDC = 0x80c34BD3A3569E126e7055831036aa7b212cB159;

    /// @dev Live role holders on Katana (all EOAs; there are no Safes on this chain yet)
    address constant GOVERNOR_ROLE_HOLDER = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;

    // SuperOracle pseudo-tokens
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant USD_TOKEN = 0x0000000000000000000000000000000000000348;
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    uint256 constant MIN_UPDATE_INTERVAL = 600;
    uint256 constant MAX_STALENESS = 3600; // >= getMinStaleness() (300) on Katana
    uint256 constant HOOKS_ROOT_TIMELOCK = 900; // getHooksRootUpdateTimelock() on Katana
    uint256 constant UP_USD_PRICE = 0.09e18;

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/
    ISuperGovernor internal governor = ISuperGovernor(SUPER_GOVERNOR);
    ISuperVaultAggregator internal aggregator = ISuperVaultAggregator(AGGREGATOR);
    ISuperOracle internal superOracle = ISuperOracle(SUPER_ORACLE);
    IERC20 internal vbUsdc = IERC20(VB_USDC);

    address internal manager = makeAddr("katana-vault-manager");
    address internal treasury = makeAddr("katana-fee-recipient");
    address internal alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(
            vm.envOr("KATANA_RPC_URL", vm.envOr("KATANA_MAINNET", string("https://rpc.katana.network")))
        );
        assertEq(block.chainid, 747_474, "not a Katana fork");
    }

    /*//////////////////////////////////////////////////////////////
                          1. DEPLOYMENT WIRING
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Katana_AllContractsHaveCode() public view {
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
            SUPERFORM_GAS_ORACLE,
            SUPER_VAULT_EXECUTOR,
            SUPER_VAULT_BATCH_OPERATOR,
            UP_OFT
        ];
        for (uint256 i; i < deployed.length; ++i) {
            assertGt(deployed[i].code.length, 0, "periphery contract missing code");
        }
    }

    function test_Fork_Katana_GovernorWiring() public view {
        assertEq(governor.getAddress(keccak256("SUPER_VAULT_AGGREGATOR")), AGGREGATOR, "aggregator key");
        assertEq(governor.getAddress(keccak256("SUPER_ORACLE")), SUPER_ORACLE, "oracle key");
        assertEq(governor.getAddress(keccak256("SUPER_BANK")), SUPER_BANK, "bank key");
        // UP and UPKEEP_TOKEN are both the UpOFT on every omnichain deployment
        assertEq(governor.getAddress(keccak256("UP")), UP_OFT, "UP key");
        assertEq(governor.getAddress(keccak256("UPKEEP_TOKEN")), UP_OFT, "UPKEEP_TOKEN key");
        assertEq(governor.getActivePPSOracle(), ECDSA_PPS_ORACLE, "active PPS oracle");
        // Production validator set: a single signer with quorum 1
        assertEq(governor.getValidatorsCount(), 1, "validator count");
        assertEq(governor.getPPSOracleQuorum(), 1, "pps quorum");
    }

    function test_Fork_Katana_AggregatorKnowsImplementations() public view {
        IAggregatorImpls impls = IAggregatorImpls(AGGREGATOR);
        assertEq(impls.VAULT_IMPLEMENTATION(), SUPER_VAULT_IMPL, "vault impl");
        assertEq(impls.STRATEGY_IMPLEMENTATION(), STRATEGY_IMPL, "strategy impl");
        assertEq(impls.ESCROW_IMPLEMENTATION(), ESCROW_IMPL, "escrow impl");
        assertEq(aggregator.getHooksRootUpdateTimelock(), HOOKS_ROOT_TIMELOCK, "hooks root timelock");
    }

    /// @notice Katana's SuperOracle carries only the three deployment feeds: gas, native/USD and
    ///         UP/USD. No ERC-20 asset feed is registered, which is why the vault tests below never
    ///         price vbUSDC through it.
    function test_Fork_Katana_OracleFeedsAnswer() public view {
        (uint256 nativeUsd,, uint256 total, uint256 available) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertEq(total, available, "NATIVE/USD provider unavailable");
        // Katana's gas token is ETH, priced by the Chainlink ETH/USD proxy
        assertGt(nativeUsd, 0, "native(ETH)/USD feed answers");

        (uint256 upUsd,,,) = superOracle.getQuoteFromProvider(1e18, UP_OFT, USD_TOKEN, AVERAGE_PROVIDER);
        assertEq(upUsd, UP_USD_PRICE, "UP/USD is the fixed price oracle");

        uint256 weiPerGas = uint256(IGasFeed(SUPERFORM_GAS_ORACLE).latestAnswer());
        assertGt(weiPerGas, 0, "gas oracle answers");
    }

    /*//////////////////////////////////////////////////////////////
                      2. THE HOOK REGISTRATION GAP
    //////////////////////////////////////////////////////////////*/

    /// @notice Katana's hooks are DEPLOYED but NOT REGISTERED, and the global hooks root is empty.
    ///         Both are prerequisites for `executeHooks`, so this records the blocker explicitly.
    ///         When the hook-registration step is completed on Katana this test should be inverted
    ///         into a positive assertion and the in-fork registration below can be dropped.
    function test_Fork_Katana_HookRegistrationGap() public view {
        assertGt(APPROVE_AND_DEPOSIT_4626_HOOK.code.length, 0, "the hook IS deployed on Katana");
        assertGt(REDEEM_4626_HOOK.code.length, 0, "the redeem hook IS deployed on Katana");

        assertFalse(governor.isHookRegistered(APPROVE_AND_DEPOSIT_4626_HOOK), "deposit hook not registered yet");
        assertFalse(governor.isHookRegistered(REDEEM_4626_HOOK), "redeem hook not registered yet");
        assertEq(governor.getRegisteredHooks().length, 0, "no hook is registered on Katana");
        assertEq(aggregator.getGlobalHooksRoot(), bytes32(0), "global hooks root is unset");
    }

    /*//////////////////////////////////////////////////////////////
                       3. VAULT CREATION LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    function test_Fork_Katana_NoVaultExistedBefore() public view {
        assertEq(aggregator.getSuperVaultsCount(), 0, "Katana has no SuperVault yet");
    }

    function test_Fork_Katana_CreateVault() public {
        (address vault, address strategy, address escrow) = _createVault();

        assertGt(vault.code.length, 0, "vault clone");
        assertGt(strategy.code.length, 0, "strategy clone");
        assertGt(escrow.code.length, 0, "escrow clone");
        assertEq(IERC4626(vault).asset(), VB_USDC, "asset");
        assertEq(IERC20Metadata(vault).decimals(), 6, "share decimals follow the 6-decimal asset");
        assertEq(aggregator.getMainManager(strategy), manager, "main manager seated");
        assertEq(aggregator.getPPS(strategy), 1e6, "initial PPS = 1.0 in asset decimals");
        assertEq(aggregator.getMinUpdateInterval(strategy), MIN_UPDATE_INTERVAL, "min update interval");
        assertEq(aggregator.getMaxStaleness(strategy), MAX_STALENESS, "max staleness");
        assertFalse(aggregator.isStrategyPaused(strategy), "fresh strategy live");
        assertFalse(aggregator.isPPSStale(strategy), "fresh PPS");
        assertEq(IERC4626(vault).totalAssets(), 0, "fresh vault is empty");
        assertEq(aggregator.getSuperVaultsCount(), 1, "aggregator counts the new vault");
    }

    function test_Fork_Katana_CreateVaultAndDeposit() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6; // 1,000 vbUSDC

        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        // PPS is 1.0 and managementFeeBps is 0 -> 1:1 shares, assets park in the strategy
        assertEq(shares, amount, "1:1 shares at initial PPS");
        assertEq(IERC20(vault).balanceOf(alice), shares, "alice holds the shares");
        assertEq(vbUsdc.balanceOf(strategy), amount, "strategy holds the deposit");
        assertEq(IERC4626(vault).totalAssets(), amount, "totalAssets");
        assertEq(IERC4626(vault).convertToAssets(shares), amount, "convertToAssets");
    }

    /// @notice The full flow the Katana deployment has to support, on the production aggregator.
    function test_Fork_Katana_FullFlow_CreateDepositRequestRedeemFulfillAndRedeem() public {
        (address vault, address strategy, address escrow) = _createVault();
        uint256 amount = 2500e6;

        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        assertEq(shares, amount, "1:1 shares at PPS 1.0");

        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();
        assertEq(IERC20(vault).balanceOf(alice), 0, "shares escrowed on request");
        assertEq(ISuperVault(vault).pendingRedeemRequest(0, alice), shares, "request pending");

        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = amount;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(vbUsdc.balanceOf(escrow), amount, "net assets parked in escrow");
        assertEq(ISuperVault(vault).claimableRedeemRequest(0, alice), shares, "claimable");

        vm.prank(alice);
        uint256 assetsBack = IERC4626(vault).redeem(shares, alice, alice);

        assertEq(assetsBack, amount, "full principal back at PPS 1.0");
        assertEq(vbUsdc.balanceOf(alice), amount, "alice made whole");
        assertEq(IERC4626(vault).totalSupply(), 0, "all shares burned");
        assertEq(vbUsdc.balanceOf(escrow), 0, "escrow drained");
    }

    function test_Fork_Katana_TwoDepositorsShareProRata() public {
        (address vault,,) = _createVault();
        address bob = makeAddr("bob");
        _fundVbUsdc(alice, 100e6);
        _fundVbUsdc(bob, 300e6);

        vm.startPrank(alice);
        vbUsdc.approve(vault, 100e6);
        IERC4626(vault).deposit(100e6, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        vbUsdc.approve(vault, 300e6);
        IERC4626(vault).deposit(300e6, bob);
        vm.stopPrank();

        assertEq(IERC4626(vault).totalAssets(), 400e6, "pooled assets");
        assertLe(IERC4626(vault).maxWithdraw(alice) + IERC4626(vault).maxWithdraw(bob), 400e6, "no over-claim");
        assertEq(IERC4626(vault).convertToAssets(IERC20(vault).balanceOf(bob)), 300e6, "bob pro-rata");
    }

    /*//////////////////////////////////////////////////////////////
                    4. HOOK EXECUTION INTO A REAL VAULT
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes the REAL v2-core ApproveAndDeposit4626VaultHook from a real Katana
    ///         SuperVault strategy into a REAL Katana yield source (Yearn's vbUSDC vault).
    ///         Nothing about the hook or the target is mocked. The only thing supplied in-fork is
    ///         the governor-side hook registration, which Katana has not done yet - see
    ///         `test_Fork_Katana_HookRegistrationGap`.
    function test_Fork_Katana_ExecuteHook_Deposit4626IntoYearnVault() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;

        // fund the strategy by depositing through the vault, exactly as a user would
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();
        assertEq(vbUsdc.balanceOf(strategy), amount, "strategy funded");

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        uint256 sharesBefore = IERC20(YVVB_USDC).balanceOf(strategy);
        _executeHook(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        assertEq(vbUsdc.balanceOf(strategy), 0, "strategy deployed its whole balance");
        assertGt(IERC20(YVVB_USDC).balanceOf(strategy), sharesBefore, "strategy holds yield-source shares");
        // the position is worth what went in, give or take 4626 rounding
        assertApproxEqRel(
            IERC4626(YVVB_USDC).convertToAssets(IERC20(YVVB_USDC).balanceOf(strategy)), amount, 1e15, "position value"
        );
    }

    /// @notice Round trip through two real hooks: deposit into the Yearn vault, then redeem back.
    function test_Fork_Katana_ExecuteHooks_RoundTrip4626() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 500e6;

        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        // --- out: vbUSDC -> yvvbUSDC ---
        bytes memory depositData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, depositData);
        _executeHook(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, depositData);

        uint256 ySharesHeld = IERC20(YVVB_USDC).balanceOf(strategy);
        assertGt(ySharesHeld, 0, "position opened");

        // --- back: yvvbUSDC -> vbUSDC ---
        bytes memory redeemData = _redeem4626Data(YVVB_USDC, strategy, ySharesHeld);
        _registerHookAndAuthorise(strategy, REDEEM_4626_HOOK, redeemData);
        _executeHook(strategy, REDEEM_4626_HOOK, redeemData);

        assertEq(IERC20(YVVB_USDC).balanceOf(strategy), 0, "position fully closed");
        assertApproxEqRel(vbUsdc.balanceOf(strategy), amount, 1e15, "principal back in the strategy");
    }

    /// @notice An unregistered hook cannot execute even with a valid strategy root, which is the
    ///         check that currently blocks every hook on Katana.
    function test_Fork_Katana_ExecuteHook_RevertsWhenHookNotRegistered() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 100e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        // authorise the leaf but deliberately skip registerHook
        _setStrategyRoot(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));
    }

    /// @notice Only a manager may execute hooks.
    function test_Fork_Katana_ExecuteHook_RevertsForNonManager() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 100e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        vm.prank(alice);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));
    }

    /*//////////////////////////////////////////////////////////////
                        5. PPS UPDATES AND ACCRUAL
    //////////////////////////////////////////////////////////////*/

    /// @notice A quorum-signed PPS update is what makes a SuperVault accrue: shares reprice and
    ///         every holder's claim grows together. Driven here by pranking the live active PPS
    ///         oracle, since the production validator key is not available to a test.
    /// @dev Katana has `isUpkeepPaymentsEnabled() == true` and UPKEEP_TOKEN is UP, which has ZERO
    ///      total supply on Katana. A real keeper-paid update would therefore need the strategy's
    ///      upkeep balance funded first. `forwardPPS` only skips the payment leg, so the repricing
    ///      path itself is exercised unchanged.
    function test_Fork_Katana_PPSUpdateRepricesShares() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;

        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        assertEq(IERC4626(vault).convertToAssets(shares), amount, "flat at PPS 1.0");

        // +5% in asset decimals: 1.00 -> 1.05
        uint256 newPps = 1.05e6;
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, newPps);

        assertEq(aggregator.getPPS(strategy), newPps, "PPS stored");
        assertFalse(aggregator.isPPSStale(strategy), "fresh after update");
        assertEq(IERC4626(vault).convertToAssets(shares), 1050e6, "alice's claim grew with PPS");
        assertEq(IERC4626(vault).totalAssets(), 1050e6, "totalAssets = supply * PPS");
    }

    /// @notice Deposits after a PPS rise buy proportionally fewer shares, so the earlier holder
    ///         keeps the gain rather than sharing it with the newcomer.
    function test_Fork_Katana_DepositAfterPPSRiseIsNotDiluted() public {
        (address vault, address strategy,) = _createVault();
        address bob = makeAddr("bob");

        _fundVbUsdc(alice, 1000e6);
        vm.startPrank(alice);
        vbUsdc.approve(vault, 1000e6);
        uint256 aliceShares = IERC4626(vault).deposit(1000e6, alice);
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, 1.25e6); // +25%

        _fundVbUsdc(bob, 1000e6);
        vm.startPrank(bob);
        vbUsdc.approve(vault, 1000e6);
        uint256 bobShares = IERC4626(vault).deposit(1000e6, bob);
        vm.stopPrank();

        // same money, 25% fewer shares
        assertEq(bobShares, 800e6, "bob buys at the higher PPS");
        assertLt(bobShares, aliceShares, "bob holds fewer shares for the same assets");
        assertEq(IERC4626(vault).convertToAssets(aliceShares), 1250e6, "alice keeps her gain");
        assertEq(IERC4626(vault).convertToAssets(bobShares), 1000e6, "bob is flat on entry");
    }

    /// @notice Deposits fail closed once the PPS feed goes quiet. Note WHICH bound does it:
    ///         `isPPSStale` is a FLAG the aggregator raises on a deviation breach, a pause or an
    ///         underfunded keeper, not a time comparison. The time-based bound is the strategy's
    ///         own `ppsExpiration`, 1 day by default, so a vault whose oracle simply stops
    ///         publishing stays usable for a day and is then blocked.
    function test_Fork_Katana_DepositRevertsOncePPSExpires() public {
        (address vault, address strategy,) = _createVault();
        _fundVbUsdc(alice, 100e6);

        // past maxStaleness but inside ppsExpiration: still usable, and the flag is NOT set
        vm.warp(block.timestamp + MAX_STALENESS + 1);
        assertFalse(aggregator.isPPSStale(strategy), "stale is a flag, not a clock");
        assertFalse(_ppsExpired(strategy), "1-day expiry has not elapsed");
        vm.startPrank(alice);
        vbUsdc.approve(vault, 100e6);
        IERC4626(vault).deposit(50e6, alice);
        vm.stopPrank();

        // past ppsExpiration: deposits are blocked
        vm.warp(block.timestamp + IStrategyPPSExpiration(strategy).ppsExpiration() + 1);
        assertTrue(_ppsExpired(strategy), "PPS feed has gone quiet past its expiry");
        vm.prank(alice);
        vm.expectRevert();
        IERC4626(vault).deposit(50e6, alice);
    }

    /*//////////////////////////////////////////////////////////////
                               6. THE TARGET
    //////////////////////////////////////////////////////////////*/

    /// @notice Sanity-checks the Katana yield source the hook tests point at, so a failure there
    ///         is distinguishable from a failure in our own stack.
    function test_Fork_Katana_YieldSourceIsUsable() public view {
        assertEq(IERC4626(YVVB_USDC).asset(), VB_USDC, "yield source takes vbUSDC");
        assertGt(IERC4626(YVVB_USDC).totalAssets(), 0, "yield source has real TVL");
        assertGt(IERC4626(YVVB_USDC).maxDeposit(address(this)), 0, "yield source accepts deposits");
        assertEq(IERC20Metadata(VB_USDC).symbol(), "vbUSDC", "asset is Vault Bridge USDC");
        assertEq(IERC20Metadata(VB_USDC).decimals(), 6, "6 decimals");
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function _createVault() internal returns (address vault, address strategy, address escrow) {
        (vault, strategy, escrow) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: VB_USDC,
                name: "Katana Fork Test SuperVault vbUSDC",
                symbol: "tsvUSDC-katana",
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

    /// @dev vbUSDC is a standard ERC-20, so a balance write is enough; no Katana precompile is
    ///      involved (unlike Arc's native-backed USDC).
    function _fundVbUsdc(address to, uint256 amount) internal {
        deal(VB_USDC, to, amount);
        assertEq(vbUsdc.balanceOf(to), amount, "funding did not land");
    }

    /// @dev ApproveAndDeposit4626VaultHook data layout:
    ///      bytes32 oracleId | address yieldSource | address token | uint256 amount |
    ///      bool usePrevHookAmount | address vaultBank | uint256 dstChainId
    function _approveAndDeposit4626Data(
        address yieldSource,
        address token,
        uint256 amount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(_erc4626OracleId(), yieldSource, token, amount, false, address(0), uint256(0));
    }

    /// @dev Redeem4626VaultHook data layout:
    ///      bytes32 oracleId | address yieldSource | address owner | uint256 shares |
    ///      bool usePrevHookAmount | address vaultBank | uint256 dstChainId
    function _redeem4626Data(address yieldSource, address owner, uint256 shares) internal pure returns (bytes memory) {
        return abi.encodePacked(_erc4626OracleId(), yieldSource, owner, shares, false, address(0), uint256(0));
    }

    function _erc4626OracleId() internal pure returns (bytes32) {
        return ERC4626_ORACLE_ID;
    }

    /// @dev Registers the hook with the live GOVERNOR_ROLE holder and authorises this exact
    ///      (hook, args) pair as a single-leaf strategy root. Katana has registered nothing and has
    ///      no global root, so both steps are required for `executeHooks` to pass validation.
    function _registerHookAndAuthorise(address strategy, address hook, bytes memory hookData) internal {
        if (!governor.isHookRegistered(hook)) {
            vm.prank(GOVERNOR_ROLE_HOLDER);
            governor.registerHook(hook);
            assertTrue(governor.isHookRegistered(hook), "hook registered in-fork");
        }
        _setStrategyRoot(strategy, hook, hookData);
    }

    /// @dev Single-leaf tree: root == leaf and the empty proof is accepted explicitly by
    ///      `_validateSingleHook`.
    function _setStrategyRoot(address strategy, address hook, bytes memory hookData) internal {
        bytes memory hookArgs = IHookInspector(hook).inspect(hookData);
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));

        vm.prank(manager);
        aggregator.proposeStrategyHooksRoot(strategy, leaf);
        vm.warp(block.timestamp + HOOKS_ROOT_TIMELOCK + 1);
        aggregator.executeStrategyHooksRootUpdate(strategy);
        assertEq(aggregator.getStrategyHooksRoot(strategy), leaf, "strategy root active");
    }

    function _executeHook(address strategy, address hook, bytes memory hookData) internal {
        vm.prank(manager);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(hook, hookData));
    }

    /// @dev Pranks the live active PPS oracle, the only caller `forwardPPS` accepts.
    function _forwardPPS(address strategy, uint256 pps) internal {
        address[] memory strategies = new address[](1);
        strategies[0] = strategy;
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = pps;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = block.timestamp;

        vm.prank(ECDSA_PPS_ORACLE);
        aggregator.forwardPPS(
            ISuperVaultAggregator.ForwardPPSArgs({
                strategies: strategies, ppss: ppss, timestamps: timestamps, updateAuthority: ECDSA_PPS_ORACLE
            })
        );
    }

    /// @dev `ppsExpiration` is a strategy-level liveness bound separate from the aggregator's
    ///      stale flag; either one blocks deposits.
    function _ppsExpired(address strategy) internal view returns (bool) {
        return block.timestamp - aggregator.getLastUpdateTimestamp(strategy)
            > IStrategyPPSExpiration(strategy).ppsExpiration();
    }

    function _executeArgs(
        address hook,
        bytes memory hookData
    )
        internal
        pure
        returns (ISuperVaultStrategy.ExecuteArgs memory args)
    {
        address[] memory hooks = new address[](1);
        hooks[0] = hook;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = hookData;
        uint256[] memory expected = new uint256[](1);
        expected[0] = 0; // 0 disables the slippage assertion
        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0);
        bytes32[][] memory strategyProofs = new bytes32[][](1);
        strategyProofs[0] = new bytes32[](0);

        args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: calldatas,
            expectedAssetsOrSharesOut: expected,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });
    }
}
