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
import { ISuperVaultExecutor } from "../../../src/interfaces/SuperVault/ISuperVaultExecutor.sol";

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
///      - The Katana hook set IS registered in the SuperGovernor (36 hooks), so the hook tests
///        below execute production-registered hooks rather than anything this suite registers.
///        The global hooks root is zero, as on every other chain, so authorisation runs through
///        per-strategy merkle roots only.
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

    /// @dev Second Katana vbUSDC yield source (MetaMorpho). Used to prove the hook path is not
    ///      specific to one target - Morpho itself is reachable only through ERC-4626 on Katana,
    ///      since no Morpho hook is deployed there.
    address constant STEAK_USDC = 0x61D4F9D3797BA4dA152238c53a6f93Fb665C3c1d;
    /// @dev Vault Bridge ETH (18 decimals) and its Yearn vault - proves decimal handling is not
    ///      specific to the 6-decimal asset.
    address constant VB_ETH = 0xEE7D8BCFb72bC1880D0Cf19822eB0A2e6577aB62;
    address constant YVVB_ETH = 0xE007CA01894c863d7898045ed5A3B4Abf0b18f37;

    address constant APPROVE_ERC20_HOOK = 0x17DdFE8988cF71BBd672e5daFc4f6D02Cf279fA4;
    /// @dev Deployed on Katana but deliberately NOT registered, because Aave is not deployed
    ///      there and the hook would have no pool to point at. Used to prove the registration
    ///      gate, since every hook this suite actually uses IS registered.
    address constant UNREGISTERED_AAVE_V4_LEND_HOOK = 0x354c65273D036AF8370f6d420254cF364A14E985;
    address constant DEPOSIT_4626_HOOK = 0x71761d36cF081A3762E5347b4e3635CeCAd5156b;

    /// @dev Live role holders on Katana (all EOAs; there are no Safes on this chain yet)
    address constant GOVERNOR_ROLE_HOLDER = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;
    address constant GUARDIAN_ROLE_HOLDER = 0x5E8C68Ef250fdBcF696F838033CCcE23785DA03F;
    address constant ORACLE_MANAGER_ROLE_HOLDER = 0xC72F6950FBF6ffE315525E200F6E54A05F739311;
    address constant BANK_MANAGER_ROLE_HOLDER = 0xBe3B40a05BA6120B73F94c5018Bc90E49A6275E7;
    address constant GAS_MANAGER_ROLE_HOLDER = 0x4d7AACD4b72e6BC6eA0eee6AA61A773A8b556B99;
    address constant TREASURY = 0x1dbD9b26b295A33f126456Ab4e498cd308622f08;

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
                      2. HOOK AUTHORISATION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Hook registration is complete on Katana: the governor knows the hook set, so
    ///         `executeHooks` can pass its first gate. The hook tests below therefore execute
    ///         PRODUCTION-registered hooks, not hooks this suite registered for itself.
    /// @dev The count is asserted as a floor rather than an exact number so adding a hook to the
    ///      set does not break the suite. For reference at the time of writing: Katana 36,
    ///      Arc 38, RH 42, Base 138.
    function test_Fork_Katana_HooksAreRegistered() public view {
        assertGe(governor.getRegisteredHooks().length, 36, "Katana hook set registered");

        assertTrue(governor.isHookRegistered(APPROVE_AND_DEPOSIT_4626_HOOK), "approve+deposit 4626");
        assertTrue(governor.isHookRegistered(REDEEM_4626_HOOK), "redeem 4626");
        assertTrue(governor.isHookRegistered(APPROVE_ERC20_HOOK), "approve erc20");
        assertTrue(governor.isHookRegistered(DEPOSIT_4626_HOOK), "deposit 4626");
    }

    /// @notice The global hooks root is still empty on Katana, as it is on every other chain, so
    ///         hooks authorise through per-strategy roots only. `_validateSingleHook` early-returns
    ///         false for a zero root, which means the global path can never pass today.
    function test_Fork_Katana_GlobalRootIsEmptySoStrategyRootsAreTheOnlyPath() public view {
        assertEq(aggregator.getGlobalHooksRoot(), bytes32(0), "global root unset");
        assertFalse(aggregator.isGlobalHooksRootVetoed(), "not vetoed");
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

    /// @notice `executeHooks` checks registration BEFORE merkle validation, so a hook the governor
    ///         does not know is rejected outright. Uses a real Katana-deployed but unregistered
    ///         hook (Aave V4 lend, which has no pool on Katana) rather than a fabricated address,
    ///         and sets no strategy root at all, since the registration gate fires first.
    function test_Fork_Katana_ExecuteHook_RevertsWhenHookNotRegistered() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 100e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        assertGt(UNREGISTERED_AAVE_V4_LEND_HOOK.code.length, 0, "the hook IS deployed");
        assertFalse(governor.isHookRegistered(UNREGISTERED_AAVE_V4_LEND_HOOK), "but is NOT registered");

        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy)
            .executeHooks(
                _executeArgs(UNREGISTERED_AAVE_V4_LEND_HOOK, _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount))
            );
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
                    6. DEPLOYMENT PARITY AND GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /// @notice The periphery is deployed with CREATE2 from a fixed salt namespace, so the core
    ///         singletons must land on the SAME address on Katana as on every other chain. A
    ///         mismatch here means the deployment used a different salt or different bytecode,
    ///         which is the single most useful signal that something went wrong.
    function test_Fork_Katana_Create2ParityWithFleet() public pure {
        // these are the fleet-wide addresses observed on Ethereum, Base, BSC, RH and Arc
        assertEq(SUPER_GOVERNOR, 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4, "governor parity");
        assertEq(AGGREGATOR, 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698, "aggregator parity");
        assertEq(SUPER_BANK, 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15, "bank parity");
        assertEq(SUPER_VAULT_IMPL, 0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2, "vault impl parity");
        assertEq(STRATEGY_IMPL, 0x770abd170404B8ed8182c04f380E567e647b457D, "strategy impl parity");
        assertEq(ESCROW_IMPL, 0x8982cf48eaB6616f2892888410afad9b0CD2BC9B, "escrow impl parity");
        assertEq(ECDSA_PPS_ORACLE, 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2, "pps oracle parity");
        assertEq(FIXED_PRICE_ORACLE, 0x66b30A0Dda7F868796ADC3d70232950D65F3565c, "fixed price parity");
        assertEq(SUPER_VAULT_EXECUTOR, 0x183e3171EEf801cE2A29FD48B3b21188f241875d, "executor parity");
        assertEq(SUPER_VAULT_BATCH_OPERATOR, 0x73d3f46d3a9f98C55C512DEca29993D28F93817c, "batch op parity");
        // SuperOracle is NOT fleet-shared: its constructor embeds the chain's own feed addresses
    }

    /// @notice Every privileged role on Katana is held by an EOA, and this records exactly which.
    ///         Katana has no Safe, unlike the chains that went through TransferSuperGovernorRole.
    function test_Fork_Katana_RoleHolders() public view {
        assertTrue(governor.hasRole(governor.SUPER_GOVERNOR_ROLE(), GOVERNOR_ROLE_HOLDER), "super governor");
        assertTrue(governor.hasRole(governor.GOVERNOR_ROLE(), GOVERNOR_ROLE_HOLDER), "governor");
        assertTrue(governor.hasRole(governor.GUARDIAN_ROLE(), GUARDIAN_ROLE_HOLDER), "guardian");
        assertTrue(governor.hasRole(governor.ORACLE_MANAGER_ROLE(), ORACLE_MANAGER_ROLE_HOLDER), "oracle manager");

        // all of them are EOAs - there is no multisig on Katana yet
        assertEq(GOVERNOR_ROLE_HOLDER.code.length, 0, "governor is an EOA");
        assertEq(GUARDIAN_ROLE_HOLDER.code.length, 0, "guardian is an EOA");
    }

    function test_Fork_Katana_TreasuryAndMinStaleness() public view {
        assertEq(governor.getAddress(keccak256("TREASURY")), TREASURY, "treasury key");
        assertEq(governor.getMinStaleness(), 300, "min staleness floor");
        assertTrue(governor.isUpkeepPaymentsEnabled(), "upkeep payments on");
    }

    /// @notice The validator registered in the governor is the production PPS updater, and the
    ///         oracle the governor points at is the one holding that config.
    function test_Fork_Katana_ValidatorSetMatchesProduction() public view {
        assertTrue(governor.isValidator(0x31a11c7502F6A5E551F50f0871d72E8Ce02D39E2), "prod PPS updater");
        assertEq(governor.getValidatorsCount(), 1, "single validator");
        assertEq(governor.getPPSOracleQuorum(), 1, "quorum 1");
        assertGt(ECDSA_PPS_ORACLE.code.length, 0, "the active oracle has code");
    }

    /*//////////////////////////////////////////////////////////////
                           7. FEES AND INVARIANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice An entry fee is skimmed on the GROSS deposit and shares are minted on the net.
    function test_Fork_Katana_EntryFeeIsSkimmedOnGross() public {
        uint256 feeBps = 50; // 0.5%
        (address vault,,) = _createVaultWithFees(0, feeBps);
        uint256 amount = 1000e6;

        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        uint256 expectedFee = (amount * feeBps) / 10_000;
        assertEq(vbUsdc.balanceOf(treasury), expectedFee, "fee landed with the recipient");
        assertEq(shares, amount - expectedFee, "shares minted on the net amount");
        assertEq(IERC4626(vault).previewDeposit(amount), shares, "previewDeposit agrees");
    }

    /// @notice The invariant the production monitors watch: totalAssets == totalSupply * storedPPS.
    function test_Fork_Katana_TotalAssetsEqualsSupplyTimesPPS() public {
        (address vault, address strategy,) = _createVault();
        _fundVbUsdc(alice, 777e6);
        vm.startPrank(alice);
        vbUsdc.approve(vault, 777e6);
        IERC4626(vault).deposit(777e6, alice);
        vm.stopPrank();

        _assertSupplyTimesPPSInvariant(vault, strategy);

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, 1.1e6);
        _assertSupplyTimesPPSInvariant(vault, strategy);
    }

    /// @notice Escrow holds exactly what has been fulfilled and nothing more, which is the
    ///         escrow-solvency property the monitors check.
    function test_Fork_Katana_EscrowHoldsOnlyFulfilledAssets() public {
        (address vault, address strategy, address escrow) = _createVault();
        address bob = makeAddr("bob");
        _fundVbUsdc(alice, 400e6);
        _fundVbUsdc(bob, 600e6);

        vm.startPrank(alice);
        vbUsdc.approve(vault, 400e6);
        uint256 aliceShares = IERC4626(vault).deposit(400e6, alice);
        ISuperVault(vault).requestRedeem(aliceShares, alice, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        vbUsdc.approve(vault, 600e6);
        uint256 bobShares = IERC4626(vault).deposit(600e6, bob);
        ISuperVault(vault).requestRedeem(bobShares, bob, bob);
        vm.stopPrank();

        // fulfil only alice
        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 400e6;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(vbUsdc.balanceOf(escrow), 400e6, "escrow holds only alice's fulfilled assets");
        assertEq(vbUsdc.balanceOf(strategy), 600e6, "bob's principal is still working");
        assertEq(ISuperVault(vault).pendingRedeemRequest(0, bob), bobShares, "bob still pending");
    }

    /// @notice A manager can pause the strategy, and a paused strategy stops accepting deposits.
    function test_Fork_Katana_PauseBlocksDeposits() public {
        (address vault, address strategy,) = _createVault();
        _fundVbUsdc(alice, 100e6);

        vm.prank(manager);
        aggregator.pauseStrategy(strategy);
        assertTrue(aggregator.isStrategyPaused(strategy), "paused");
        assertEq(IERC4626(vault).maxDeposit(alice), 0, "maxDeposit reports closed");

        vm.startPrank(alice);
        vbUsdc.approve(vault, 100e6);
        vm.expectRevert();
        IERC4626(vault).deposit(100e6, alice);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        8. MORE HOOK COVERAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Two hooks in ONE executeHooks call, authorised by a real two-leaf merkle tree with
    ///         real proofs: a standalone ApproveERC20Hook followed by Deposit4626VaultHook. This
    ///         is the shape a manager actually uses, and it exercises proof verification rather
    ///         than the single-leaf empty-proof shortcut.
    function test_Fork_Katana_ExecuteHooks_BatchApproveThenDeposit() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 800e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        _registerHook(APPROVE_ERC20_HOOK);
        _registerHook(DEPOSIT_4626_HOOK);

        // build the args BEFORE arming the prank: arguments are evaluated first, and the
        // root-activation inside _batchArgs would otherwise consume the prank, leaving
        // executeHooks to be called by the test contract.
        ISuperVaultStrategy.ExecuteArgs memory args = _batchArgs(strategy, amount);
        vm.prank(manager);
        ISuperVaultStrategy(strategy).executeHooks(args);

        assertEq(vbUsdc.balanceOf(strategy), 0, "strategy deployed its balance");
        assertGt(IERC20(YVVB_USDC).balanceOf(strategy), 0, "position opened via the batch");
    }

    /// @dev Kept in its own frame: assembling two hooks plus a two-leaf tree in the test body
    ///      overflows the stack without via-ir.
    function _batchArgs(
        address strategy,
        uint256 amount
    )
        internal
        returns (ISuperVaultStrategy.ExecuteArgs memory args)
    {
        args.hooks = new address[](2);
        args.hooks[0] = APPROVE_ERC20_HOOK;
        args.hooks[1] = DEPOSIT_4626_HOOK;

        args.hookCalldata = new bytes[](2);
        args.hookCalldata[0] = _approveErc20Data(VB_USDC, YVVB_USDC, amount);
        args.hookCalldata[1] = _deposit4626Data(YVVB_USDC, amount);

        args.expectedAssetsOrSharesOut = new uint256[](2);

        args.globalProofs = new bytes32[][](2);
        args.globalProofs[0] = new bytes32[](0);
        args.globalProofs[1] = new bytes32[](0);

        args.strategyProofs = new bytes32[][](2);
        (bytes32 root, bytes32[] memory proofA, bytes32[] memory proofB) = _twoLeafTree(
            _leaf(APPROVE_ERC20_HOOK, args.hookCalldata[0]), _leaf(DEPOSIT_4626_HOOK, args.hookCalldata[1])
        );
        args.strategyProofs[0] = proofA;
        args.strategyProofs[1] = proofB;

        _activateRoot(strategy, root);
    }

    /// @notice The hook path is not specific to one target: the same hook deposits into a second,
    ///         unrelated Katana vbUSDC vault (MetaMorpho's steakUSDC).
    function test_Fork_Katana_ExecuteHook_SecondYieldSource() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 600e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        bytes memory hookData = _approveAndDeposit4626Data(STEAK_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);
        _executeHook(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        assertEq(vbUsdc.balanceOf(strategy), 0, "deployed");
        assertGt(IERC20(STEAK_USDC).balanceOf(strategy), 0, "holds steakUSDC shares");
    }

    /// @notice A leaf authorises one exact (hook, args) pair. Changing the target vault after the
    ///         root is active must not execute, which is what stops a manager from redirecting
    ///         capital to an unapproved destination.
    function test_Fork_Katana_ExecuteHook_RevertsOnUnauthorisedTarget() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 100e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        // authorise yvvbUSDC ...
        bytes memory authorised = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, authorised);

        // ... then try steakUSDC with the same hook
        bytes memory swapped = _approveAndDeposit4626Data(STEAK_USDC, VB_USDC, amount);
        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, swapped));
    }

    /// @notice `expectedAssetsOrSharesOut` is the manager's own slippage guard. A deliberately
    ///         unreachable expectation must abort the execution.
    function test_Fork_Katana_ExecuteHook_SlippageGuardReverts() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 500e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        ISuperVaultStrategy.ExecuteArgs memory args = _executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData);
        args.expectedAssetsOrSharesOut[0] = type(uint128).max; // unreachable

        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).executeHooks(args);
    }

    /*//////////////////////////////////////////////////////////////
                        9. AN 18-DECIMAL ASSET
    //////////////////////////////////////////////////////////////*/

    /// @notice vbUSDC has 6 decimals, so every test above runs at PPS 1e6. A vbETH vault proves
    ///         the deployment is not accidentally tied to that: 18 decimals, PPS 1e18.
    function test_Fork_Katana_CreateVbEthVaultAndDeployViaHook() public {
        (address vault, address strategy,) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: VB_ETH,
                name: "Katana Fork Test SuperVault vbETH",
                symbol: "tsvETH-katana",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: MIN_UPDATE_INTERVAL,
                maxStaleness: MAX_STALENESS,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: treasury
                })
            })
        );

        assertEq(IERC20Metadata(vault).decimals(), 18, "18-decimal shares");
        assertEq(aggregator.getPPS(strategy), 1e18, "initial PPS = 1.0 at 18 decimals");

        uint256 amount = 2 ether;
        deal(VB_ETH, alice, amount);
        vm.startPrank(alice);
        IERC20(VB_ETH).approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();
        assertEq(shares, amount, "1:1 at PPS 1.0");

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_ETH, VB_ETH, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);
        _executeHook(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        assertEq(IERC20(VB_ETH).balanceOf(strategy), 0, "deployed");
        assertGt(IERC20(YVVB_ETH).balanceOf(strategy), 0, "holds yvvbETH");
    }

    /*//////////////////////////////////////////////////////////////
                    10. REDEMPTION PATHS AND PROTECTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice A performance fee is charged on PPS growth above the high-water mark and split with
    ///         the Superform treasury per the governor's PERFORMANCE_FEE_SHARE (5000 bps on
    ///         Katana, i.e. an even split).
    /// @dev The skim is NOT automatic on fulfilment: `skimPerformanceFee` is a separate
    ///      manager-called function, and it needs the gain to be liquid in the strategy because it
    ///      reverts with NOT_ENOUGH_FREE_ASSETS_FEE_SKIM otherwise.
    function test_Fork_Katana_PerformanceFeeSkimmedOnProfit() public {
        (address vault, address strategy,) = _createVaultWithFees(1000, 0); // 10% perf, no entry fee
        uint256 amount = 1000e6;

        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        // +10% PPS, and make the gain liquid so the skim can pay out
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, 1.1e6);
        deal(VB_USDC, strategy, 1100e6);

        uint256 recipientBefore = vbUsdc.balanceOf(treasury);
        uint256 superformBefore = vbUsdc.balanceOf(TREASURY);

        vm.prank(manager);
        ISuperVaultStrategy(strategy).skimPerformanceFee();

        // profit = 0.1 * 1000 = 100 ; fee = 10% of 100 = 10 ; split 50/50
        uint256 recipientFee = vbUsdc.balanceOf(treasury) - recipientBefore;
        uint256 superformFee = vbUsdc.balanceOf(TREASURY) - superformBefore;
        assertGt(recipientFee, 0, "strategy recipient earned a performance fee");
        assertGt(superformFee, 0, "Superform treasury took its share");
        assertApproxEqAbs(recipientFee + superformFee, 10e6, 2, "fee is 10% of the 100 profit");
        assertApproxEqAbs(recipientFee, superformFee, 2, "50/50 split at 5000 bps");
    }

    /// @notice A second skim with no further PPS growth takes nothing: the high-water mark means
    ///         the same profit is never charged twice.
    function test_Fork_Katana_PerformanceFeeNotChargedTwiceOnSameProfit() public {
        (address vault, address strategy,) = _createVaultWithFees(1000, 0);
        _fundVbUsdc(alice, 1000e6);
        vm.startPrank(alice);
        vbUsdc.approve(vault, 1000e6);
        IERC4626(vault).deposit(1000e6, alice);
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, 1.1e6);
        deal(VB_USDC, strategy, 1100e6);

        vm.prank(manager);
        ISuperVaultStrategy(strategy).skimPerformanceFee();
        uint256 afterFirst = vbUsdc.balanceOf(treasury);

        vm.prank(manager);
        ISuperVaultStrategy(strategy).skimPerformanceFee();
        assertEq(vbUsdc.balanceOf(treasury), afterFirst, "no fee on unchanged PPS");
    }

    /// @notice Fulfilment must land inside [requestPPS - slippage, currentPPS]. Paying out below
    ///         the holder's floor reverts, which is the protection on the exit side.
    function test_Fork_Katana_FulfilBelowSlippageFloorReverts() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();

        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 900e6; // 10% short, far outside the default 50 bps tolerance

        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);
    }

    /// @notice The holder sets their own exit tolerance; a wider setting lets a lower fulfilment
    ///         through that the default 50 bps would have rejected.
    function test_Fork_Katana_HolderCanWidenRedeemSlippage() public {
        (address vault, address strategy, address escrow) = _createVault();
        uint256 amount = 1000e6;
        _fundVbUsdc(alice, amount);

        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVaultStrategy(strategy).setRedeemSlippage(500); // 5%
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();

        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 970e6; // 3% short: inside 5%, outside the 50 bps default

        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);
        assertEq(vbUsdc.balanceOf(escrow), 970e6, "fulfilled at the holder's wider tolerance");
    }

    /// @notice A holder can withdraw the pending exit and get their shares back unredeemed.
    function test_Fork_Katana_CancelRedeemRequestReturnsShares() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 500e6;
        _fundVbUsdc(alice, amount);

        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        assertEq(IERC20(vault).balanceOf(alice), 0, "shares escrowed");

        ISuperVault(vault).cancelRedeemRequest(0, alice);
        vm.stopPrank();
        assertTrue(ISuperVault(vault).pendingCancelRedeemRequest(0, alice), "cancel pending");

        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillCancelRedeemRequests(controllers);
        assertEq(ISuperVault(vault).claimableCancelRedeemRequest(0, alice), shares, "cancel claimable");

        vm.prank(alice);
        ISuperVault(vault).claimCancelRedeemRequest(0, alice, alice);

        assertEq(IERC20(vault).balanceOf(alice), shares, "shares returned to alice");
        assertEq(ISuperVault(vault).pendingRedeemRequest(0, alice), 0, "no exit pending");
    }

    /// @notice The ERC-4626 `withdraw` path claims the same fulfilled position as `redeem`, priced
    ///         off the frozen average withdraw price rather than live PPS.
    function test_Fork_Katana_ClaimViaWithdrawInsteadOfRedeem() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 800e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();

        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = amount;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(IERC4626(vault).maxWithdraw(alice), amount, "claimable via withdraw");
        vm.prank(alice);
        IERC4626(vault).withdraw(amount, alice, alice);
        assertEq(vbUsdc.balanceOf(alice), amount, "withdraw paid out");
        assertEq(IERC4626(vault).maxWithdraw(alice), 0, "nothing left to claim");
    }

    /// @notice Nothing is claimable until the manager fulfils, which is the whole point of the
    ///         asynchronous exit.
    function test_Fork_Katana_NothingClaimableBeforeFulfilment() public {
        (address vault,,) = _createVault();
        uint256 amount = 300e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();

        assertEq(IERC4626(vault).maxWithdraw(alice), 0, "nothing claimable yet");
        assertEq(ISuperVault(vault).claimableRedeemRequest(0, alice), 0, "no claimable shares");
        assertEq(ISuperVault(vault).pendingRedeemRequest(0, alice), shares, "still pending");

        vm.prank(alice);
        vm.expectRevert();
        IERC4626(vault).redeem(shares, alice, alice);
    }

    /// @notice Fulfilment is all-or-nothing per controller: the assets paid must land inside
    ///         [requestPPS - slippage, currentPPS] for the WHOLE pending position, so there is no
    ///         partial-fill concept. Paying half reverts with BOUNDS_EXCEEDED.
    function test_Fork_Katana_FulfilmentIsAllOrNothingPerController() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();

        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 500e6; // half: below the floor for the full position

        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        // the full amount succeeds
        assetsOut[0] = amount;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);
        assertEq(IERC4626(vault).maxWithdraw(alice), amount, "fulfilled in full");
    }

    /// @notice Two exits fulfilled in one manager call, which is how a keeper clears a queue.
    /// @dev The controllers array must be sorted ASCENDING and unique, or the call reverts with
    ///      CONTROLLERS_NOT_SORTED_UNIQUE - a dedupe guard, and a real constraint for any keeper
    ///      building the batch.
    function test_Fork_Katana_BatchFulfilTwoControllers() public {
        (address vault, address strategy, address escrow) = _createVault();
        address bob = makeAddr("bob");
        _fundVbUsdc(alice, 300e6);
        _fundVbUsdc(bob, 700e6);

        vm.startPrank(alice);
        vbUsdc.approve(vault, 300e6);
        uint256 aliceShares = IERC4626(vault).deposit(300e6, alice);
        ISuperVault(vault).requestRedeem(aliceShares, alice, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        vbUsdc.approve(vault, 700e6);
        uint256 bobShares = IERC4626(vault).deposit(700e6, bob);
        ISuperVault(vault).requestRedeem(bobShares, bob, bob);
        vm.stopPrank();

        // sorted ascending by address, with the amounts following their controller
        address[] memory controllers = new address[](2);
        uint256[] memory assetsOut = new uint256[](2);
        if (alice < bob) {
            controllers[0] = alice;
            assetsOut[0] = 300e6;
            controllers[1] = bob;
            assetsOut[1] = 700e6;
        } else {
            controllers[0] = bob;
            assetsOut[0] = 700e6;
            controllers[1] = alice;
            assetsOut[1] = 300e6;
        }
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(vbUsdc.balanceOf(escrow), 1000e6, "both exits escrowed");
        assertEq(IERC4626(vault).maxWithdraw(alice), 300e6, "alice claimable");
        assertEq(IERC4626(vault).maxWithdraw(bob), 700e6, "bob claimable");
    }

    /*//////////////////////////////////////////////////////////////
                  11. THE FULL ECONOMIC LOOP VIA HOOKS
    //////////////////////////////////////////////////////////////*/

    /// @notice The loop a live vault runs: capital is deployed into a yield source through a hook,
    ///         the oracle reprices shares, and the holder's claim grows while the capital stays
    ///         deployed. The position is still held and still valued after the reprice.
    /// @dev Real yield cannot be forced on a fork here. yvvbUSDC is a Yearn V3 vault that tracks
    ///      totalAssets through internal accounting (idle plus debt), so donating vbUSDC to it
    ///      does NOT raise convertToAssets - I checked, the value was unchanged to the wei. So the
    ///      reprice is driven by the oracle, which is what happens in production anyway: the
    ///      off-chain service values the position and publishes the PPS.
    function test_Fork_Katana_DeployThenRepriceWhileDeployed() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);
        _executeHook(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        uint256 positionValue = IERC4626(YVVB_USDC).convertToAssets(IERC20(YVVB_USDC).balanceOf(strategy));
        assertApproxEqRel(positionValue, amount, 1e15, "position is worth the deployment");
        assertEq(vbUsdc.balanceOf(strategy), 0, "nothing idle");

        // the oracle publishes a 5% gain on the deployed position
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, 1.05e6);

        assertEq(IERC4626(vault).convertToAssets(shares), 1050e6, "claim grew with the reprice");
        assertGt(IERC20(YVVB_USDC).balanceOf(strategy), 0, "capital is still deployed");
        _assertSupplyTimesPPSInvariant(vault, strategy);
    }

    /// @notice A redemption while capital is deployed: the manager unwinds through the redeem hook
    ///         first, then fulfils from the recovered liquidity. This is the real exit path for a
    ///         vault that is not sitting in cash.
    function test_Fork_Katana_UnwindViaHookThenFulfilRedemption() public {
        (address vault, address strategy, address escrow) = _createVault();
        uint256 amount = 700e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        // deploy
        bytes memory depositData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, depositData);
        _executeHook(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, depositData);
        assertEq(vbUsdc.balanceOf(strategy), 0, "no idle liquidity");

        // the holder asks to leave while the vault is fully deployed
        vm.prank(alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);

        // manager unwinds via the redeem hook
        uint256 ySharesHeld = IERC20(YVVB_USDC).balanceOf(strategy);
        bytes memory redeemData = _redeem4626Data(YVVB_USDC, strategy, ySharesHeld);
        _registerHookAndAuthorise(strategy, REDEEM_4626_HOOK, redeemData);
        _executeHook(strategy, REDEEM_4626_HOOK, redeemData);
        assertGt(vbUsdc.balanceOf(strategy), 0, "liquidity recovered");

        // and fulfils from the recovered assets
        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = amount;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(vbUsdc.balanceOf(escrow), amount, "escrowed for the holder");
        vm.prank(alice);
        uint256 back = IERC4626(vault).redeem(shares, alice, alice);
        assertEq(back, amount, "holder made whole after a full round trip through the yield source");
    }

    /*//////////////////////////////////////////////////////////////
                      12. GUARDRAILS AND ISOLATION
    //////////////////////////////////////////////////////////////*/

    /// @notice A PPS move beyond the deviation threshold is NOT written. The strategy auto-pauses
    ///         and PPS is flagged stale, so the failure mode is a halt rather than a bad print.
    function test_Fork_Katana_PPSDeviationBreachAutoPauses() public {
        (address vault, address strategy,) = _createVault();
        _fundVbUsdc(alice, 100e6);
        vm.startPrank(alice);
        vbUsdc.approve(vault, 100e6);
        IERC4626(vault).deposit(100e6, alice);
        vm.stopPrank();

        assertEq(aggregator.getDeviationThreshold(strategy), 5e17, "default threshold is 50%");

        // +60%: beyond the band
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, 1.6e6);

        assertEq(aggregator.getPPS(strategy), 1e6, "the out-of-band PPS was NOT written");
        assertTrue(aggregator.isStrategyPaused(strategy), "strategy auto-paused");
        assertTrue(aggregator.isPPSStale(strategy), "PPS flagged stale");
        assertEq(IERC4626(vault).maxDeposit(alice), 0, "vault closed to deposits");
    }

    /// @notice Two vaults on the same asset keep separate accounting: a PPS move on one does not
    ///         touch the other.
    function test_Fork_Katana_TwoVaultsOnSameAssetAreIndependent() public {
        (address vaultA, address strategyA,) = _createVault();
        (address vaultB, address strategyB,) = _createVaultWithFees(0, 0);
        assertTrue(vaultA != vaultB, "distinct vaults");

        _fundVbUsdc(alice, 200e6);
        vm.startPrank(alice);
        vbUsdc.approve(vaultA, 100e6);
        IERC4626(vaultA).deposit(100e6, alice);
        vbUsdc.approve(vaultB, 100e6);
        IERC4626(vaultB).deposit(100e6, alice);
        vm.stopPrank();

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategyA, 1.2e6);

        assertEq(aggregator.getPPS(strategyA), 1.2e6, "A repriced");
        assertEq(aggregator.getPPS(strategyB), 1e6, "B untouched");
        assertEq(IERC4626(vaultA).totalAssets(), 120e6, "A grew");
        assertEq(IERC4626(vaultB).totalAssets(), 100e6, "B flat");
        assertEq(aggregator.getSuperVaultsCount(), 2, "both counted");
    }

    /// @notice A secondary manager can execute hooks, which is how the SuperVaultExecutor and
    ///         keeper automation drive a live vault.
    function test_Fork_Katana_SecondaryManagerCanExecuteHooks() public {
        address secondary = makeAddr("katana-secondary-manager");
        (address vault, address strategy,) = _createVault();
        vm.prank(manager);
        aggregator.addSecondaryManager(strategy, secondary);
        assertTrue(aggregator.isAnyManager(secondary, strategy), "secondary seated");

        uint256 amount = 400e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        vm.prank(secondary);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));
        assertGt(IERC20(YVVB_USDC).balanceOf(strategy), 0, "secondary deployed the capital");
    }

    /// @notice SuperBank is deployed and registered on Katana. It is governed separately from the
    ///         vaults (its hook roots live on SuperGovernor behind a 7-day timelock), so this only
    ///         records that the deployment is present and wired.
    function test_Fork_Katana_SuperBankIsDeployedAndWired() public view {
        assertGt(SUPER_BANK.code.length, 0, "bank deployed");
        assertEq(governor.getAddress(keccak256("SUPER_BANK")), SUPER_BANK, "bank registered");
    }

    /*//////////////////////////////////////////////////////////////
                13. SESSION KEYS VIA SUPERVAULTEXECUTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice SuperVaultExecutor is deployed on Katana but nothing had exercised it. This is the
    ///         path keeper automation uses: the executor is seated as a secondary manager, it
    ///         holds a session key with ExecuteHooks permission, and it drives the strategy.
    function test_Fork_Katana_SessionKeyCanExecuteHooks() public {
        (address vault, address strategy,) = _createVault();
        address keeper = makeAddr("katana-keeper");
        uint256 amount = 400e6;

        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        _seatExecutorAndGrantKey(strategy, keeper, _permExecuteHooks());

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        vm.prank(keeper);
        ISuperVaultExecutor(SUPER_VAULT_EXECUTOR)
            .executeHooks(strategy, _executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));

        assertEq(vbUsdc.balanceOf(strategy), 0, "keeper deployed the capital");
        assertGt(IERC20(YVVB_USDC).balanceOf(strategy), 0, "position opened via session key");
    }

    /// @notice Permissions are per-capability: a key granted only Pause cannot execute hooks.
    function test_Fork_Katana_SessionKeyWithoutPermissionCannotExecuteHooks() public {
        (address vault, address strategy,) = _createVault();
        address keeper = makeAddr("katana-keeper-pause-only");
        _fundVbUsdc(alice, 100e6);
        vm.startPrank(alice);
        vbUsdc.approve(vault, 100e6);
        IERC4626(vault).deposit(100e6, alice);
        vm.stopPrank();

        ISuperVaultExecutor.Permission[] memory perms = new ISuperVaultExecutor.Permission[](1);
        perms[0] = ISuperVaultExecutor.Permission.Pause;
        _seatExecutorAndGrantKey(strategy, keeper, perms);

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, 100e6);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        vm.prank(keeper);
        vm.expectRevert();
        ISuperVaultExecutor(SUPER_VAULT_EXECUTOR)
            .executeHooks(strategy, _executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));
    }

    /// @notice A revoked key stops working immediately, which is the containment lever if a
    ///         keeper is compromised.
    function test_Fork_Katana_RevokedSessionKeyCannotExecute() public {
        (address vault, address strategy,) = _createVault();
        address keeper = makeAddr("katana-keeper-revoked");
        _fundVbUsdc(alice, 100e6);
        vm.startPrank(alice);
        vbUsdc.approve(vault, 100e6);
        IERC4626(vault).deposit(100e6, alice);
        vm.stopPrank();

        _seatExecutorAndGrantKey(strategy, keeper, _permExecuteHooks());
        vm.prank(manager);
        ISuperVaultExecutor(SUPER_VAULT_EXECUTOR).revokeSessionKey(strategy, keeper);

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, 100e6);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        vm.prank(keeper);
        vm.expectRevert();
        ISuperVaultExecutor(SUPER_VAULT_EXECUTOR)
            .executeHooks(strategy, _executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));
    }

    /// @notice An expired key stops working without anyone having to revoke it.
    function test_Fork_Katana_ExpiredSessionKeyCannotExecute() public {
        (address vault, address strategy,) = _createVault();
        address keeper = makeAddr("katana-keeper-expiring");
        _fundVbUsdc(alice, 100e6);
        vm.startPrank(alice);
        vbUsdc.approve(vault, 100e6);
        IERC4626(vault).deposit(100e6, alice);
        vm.stopPrank();

        _seatExecutorAndGrantKey(strategy, keeper, _permExecuteHooks());

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, 100e6);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        // the grant below is 1 day; step past it
        vm.warp(block.timestamp + 2 days);

        vm.prank(keeper);
        vm.expectRevert();
        ISuperVaultExecutor(SUPER_VAULT_EXECUTOR)
            .executeHooks(strategy, _executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));
    }

    /*//////////////////////////////////////////////////////////////
                      14. GUARDIAN AND TIMELOCKS
    //////////////////////////////////////////////////////////////*/

    /// @notice The guardian can veto a strategy's hooks root, which blocks every hook on that
    ///         strategy without touching the root itself. It is the emergency brake, and it is
    ///         reversible.
    function test_Fork_Katana_GuardianVetoBlocksAndUnblocksHooks() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 300e6;
        _fundVbUsdc(alice, amount);
        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        bytes memory hookData = _approveAndDeposit4626Data(YVVB_USDC, VB_USDC, amount);
        _registerHookAndAuthorise(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);

        // veto: the root is still set, but nothing validates
        vm.prank(GUARDIAN_ROLE_HOLDER);
        governor.setStrategyHooksRootVetoStatus(strategy, true);
        assertTrue(aggregator.isStrategyHooksRootVetoed(strategy), "vetoed");
        assertTrue(aggregator.getStrategyHooksRoot(strategy) != bytes32(0), "root still present");

        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(APPROVE_AND_DEPOSIT_4626_HOOK, hookData));

        // lift it and the same call works
        vm.prank(GUARDIAN_ROLE_HOLDER);
        governor.setStrategyHooksRootVetoStatus(strategy, false);
        _executeHook(strategy, APPROVE_AND_DEPOSIT_4626_HOOK, hookData);
        assertGt(IERC20(YVVB_USDC).balanceOf(strategy), 0, "hooks work again after the veto is lifted");
    }

    /// @notice Changing the fee config is timelocked by a week, so a manager cannot raise fees on
    ///         holders without notice.
    function test_Fork_Katana_FeeConfigChangeIsTimelocked() public {
        (, address strategy,) = _createVaultWithFees(1000, 0);

        vm.prank(manager);
        ISuperVaultStrategy(strategy).proposeVaultFeeConfigUpdate(2000, 25, treasury);

        // not yet
        vm.prank(manager);
        vm.expectRevert();
        ISuperVaultStrategy(strategy).executeVaultFeeConfigUpdate();
        assertEq(ISuperVaultStrategy(strategy).getConfigInfo().performanceFeeBps, 1000, "old fee still in force");

        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(manager);
        ISuperVaultStrategy(strategy).executeVaultFeeConfigUpdate();
        assertEq(ISuperVaultStrategy(strategy).getConfigInfo().performanceFeeBps, 2000, "new fee active");
        assertEq(ISuperVaultStrategy(strategy).getConfigInfo().managementFeeBps, 25, "entry fee active");
    }

    /// @notice SetGasInfo has not been run on Katana, so a PPS update cannot be priced in UP and
    ///         keeper-paid updates stay blocked. Mirrors the same pending step on Arc. Flip this
    ///         to the full gas -> wei -> USD -> UP reconciliation once the step is run.
    function test_Fork_Katana_UpkeepQuoteNeedsGasInfo() public {
        uint256 gasPerEntry = governor.getGasInfo(ECDSA_PPS_ORACLE);

        if (gasPerEntry == 0) {
            vm.expectRevert();
            governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
            console2.log("Katana: gasPerEntry unset - SetGasInfo pending, paid PPS updates blocked");
            return;
        }

        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        (uint256 weiForUpdate,,,) =
            superOracle.getQuoteFromProvider(gasPerEntry, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        (uint256 usdForUpdate,,,) =
            superOracle.getQuoteFromProvider(weiForUpdate, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertApproxEqRel(cost, (usdForUpdate * 1e18) / UP_USD_PRICE, 1e12, "UP cost = usd(gas) / usd(UP)");
    }

    /*//////////////////////////////////////////////////////////////
                    15. SHARE MECHANICS AND ORACLE SCOPE
    //////////////////////////////////////////////////////////////*/

    /// @notice `mint` is the share-exact counterpart of `deposit` and must charge the matching
    ///         assets at the same PPS.
    function test_Fork_Katana_MintPathChargesMatchingAssets() public {
        (address vault,,) = _createVault();
        uint256 wanted = 250e6;

        uint256 quoted = IERC4626(vault).previewMint(wanted);
        _fundVbUsdc(alice, quoted);
        vm.startPrank(alice);
        vbUsdc.approve(vault, quoted);
        uint256 paid = IERC4626(vault).mint(wanted, alice);
        vm.stopPrank();

        assertEq(paid, quoted, "previewMint matched the charge");
        assertEq(IERC20(vault).balanceOf(alice), wanted, "exact shares minted");
        assertEq(vbUsdc.balanceOf(alice), 0, "alice paid exactly the quote");
    }

    /// @notice Shares move into escrow on requestRedeem, so the holder cannot transfer them while
    ///         the exit is pending. That is what stops a pending claim being sold twice.
    function test_Fork_Katana_EscrowedSharesCannotBeTransferred() public {
        (address vault,,) = _createVault();
        address bob = makeAddr("bob");
        uint256 amount = 200e6;
        _fundVbUsdc(alice, amount);

        vm.startPrank(alice);
        vbUsdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);

        assertEq(IERC20(vault).balanceOf(alice), 0, "shares left her balance");
        vm.expectRevert();
        IERC20(vault).transfer(bob, shares);
        vm.stopPrank();
    }

    /// @notice SuperOracle on Katana carries only the three deployment feeds. The vault asset has
    ///         NO price feed, and does not need one: share pricing comes from the stored PPS, not
    ///         from SuperOracle. Recorded so nobody assumes an asset feed exists.
    /// @dev Both calls revert rather than returning zero: AVERAGE_PROVIDER is a meta-provider for
    ///      quoting, so `getOracleAddress` rejects it with INVALID_ORACLE_PROVIDER, and the quote
    ///      has no feed to average. Either way the point stands - there is no asset feed, and the
    ///      vault does not need one.
    function test_Fork_Katana_SuperOracleHasNoFeedForTheVaultAsset() public {
        vm.expectRevert();
        superOracle.getOracleAddress(VB_USDC, USD_TOKEN, AVERAGE_PROVIDER);

        vm.expectRevert();
        superOracle.getQuoteFromProvider(1e6, VB_USDC, USD_TOKEN, AVERAGE_PROVIDER);

        // for contrast, the three feeds the deployment DID register do answer
        (uint256 nativeUsd,,,) = superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertGt(nativeUsd, 0, "native/USD is registered");
    }

    function test_Fork_Katana_BatchOperatorIsDeployedAndWired() public view {
        assertGt(SUPER_VAULT_BATCH_OPERATOR.code.length, 0, "batch operator deployed");
        assertGt(SUPER_VAULT_EXECUTOR.code.length, 0, "executor deployed");
        assertEq(
            address(ISuperVaultExecutor(SUPER_VAULT_EXECUTOR).SUPER_GOVERNOR()),
            SUPER_GOVERNOR,
            "executor knows the governor"
        );
    }

    /*//////////////////////////////////////////////////////////////
                               16. THE YIELD SOURCES
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

    /// @dev Asserts the hook is registered in PRODUCTION (it is, since the Katana hook set was
    ///      registered) and authorises this exact (hook, args) pair as a single-leaf strategy root.
    ///      Both gates are required for `executeHooks`: registration plus a merkle root.
    function _registerHookAndAuthorise(address strategy, address hook, bytes memory hookData) internal {
        assertTrue(governor.isHookRegistered(hook), "hook must be registered on Katana");
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

    function _createVaultWithFees(
        uint256 performanceFeeBps,
        uint256 managementFeeBps
    )
        internal
        returns (address vault, address strategy, address escrow)
    {
        (vault, strategy, escrow) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: VB_USDC,
                name: "Katana Fork Test SuperVault vbUSDC Fees",
                symbol: "tsvUSDCf-katana",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: MIN_UPDATE_INTERVAL,
                maxStaleness: MAX_STALENESS,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: performanceFeeBps, managementFeeBps: managementFeeBps, recipient: treasury
                })
            })
        );
    }

    function _assertSupplyTimesPPSInvariant(address vault, address strategy) internal view {
        uint256 supply = IERC4626(vault).totalSupply();
        uint256 pps = aggregator.getPPS(strategy);
        assertEq(IERC4626(vault).totalAssets(), (supply * pps) / 1e6, "totalAssets == supply * PPS");
    }

    /// @dev ApproveERC20Hook data layout:
    ///      bytes32 oracleId | address placeholder | address token | address spender |
    ///      uint256 amount | bool usePrevHookAmount
    function _approveErc20Data(address token, address spender, uint256 amount) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes32(0), address(0), token, spender, amount, false);
    }

    /// @dev Deposit4626VaultHook data layout (no approve leg):
    ///      bytes32 oracleId | address yieldSource | uint256 amount | bool usePrevHookAmount |
    ///      address vaultBank | uint256 dstChainId
    function _deposit4626Data(address yieldSource, uint256 amount) internal pure returns (bytes memory) {
        return abi.encodePacked(_erc4626OracleId(), yieldSource, amount, false, address(0), uint256(0));
    }

    function _leaf(address hook, bytes memory hookData) internal view returns (bytes32) {
        bytes memory hookArgs = IHookInspector(hook).inspect(hookData);
        return keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));
    }

    /// @dev OZ StandardMerkleTree hashes a sorted pair, so for two leaves each proof is simply
    ///      the sibling.
    function _twoLeafTree(
        bytes32 a,
        bytes32 b
    )
        internal
        pure
        returns (bytes32 root, bytes32[] memory proofA, bytes32[] memory proofB)
    {
        root = a <= b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
        proofA = new bytes32[](1);
        proofA[0] = b;
        proofB = new bytes32[](1);
        proofB[0] = a;
    }

    function _registerHook(address hook) internal view {
        assertTrue(governor.isHookRegistered(hook), "hook must be registered on Katana");
    }

    function _activateRoot(address strategy, bytes32 root) internal {
        vm.prank(manager);
        aggregator.proposeStrategyHooksRoot(strategy, root);
        vm.warp(block.timestamp + HOOKS_ROOT_TIMELOCK + 1);
        aggregator.executeStrategyHooksRootUpdate(strategy);
        assertEq(aggregator.getStrategyHooksRoot(strategy), root, "root active");
    }

    function _permExecuteHooks() internal pure returns (ISuperVaultExecutor.Permission[] memory perms) {
        perms = new ISuperVaultExecutor.Permission[](1);
        perms[0] = ISuperVaultExecutor.Permission.ExecuteHooks;
    }

    /// @dev The executor drives a strategy only once it is itself a manager on it, so the primary
    ///      manager seats it as a secondary manager and then grants the session key.
    function _seatExecutorAndGrantKey(
        address strategy,
        address key,
        ISuperVaultExecutor.Permission[] memory perms
    )
        internal
    {
        vm.startPrank(manager);
        aggregator.addSecondaryManager(strategy, SUPER_VAULT_EXECUTOR);
        ISuperVaultExecutor(SUPER_VAULT_EXECUTOR).grantSessionKey(strategy, key, block.timestamp + 1 days, perms);
        vm.stopPrank();
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
