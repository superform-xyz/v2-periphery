// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { IHyperCorePerpSnapshot } from "@superform-v2-core/src/interfaces/accounting/IHyperCorePerpSnapshot.sol";
import { HyperCorePrecompileForwarderLib } from "@superform-v2-core/test/utils/HyperCorePrecompileForwarder.sol";

import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";

interface IHookInspector {
    function inspect(bytes calldata data) external view returns (bytes memory);
}

interface IHookResult {
    function getOutAmount(address account) external view returns (uint256);
    function getOutToken(address account) external view returns (address);
}

interface IHyperCoreDepositHookImmutables {
    function TOKEN() external view returns (address);
    function GATEWAY() external view returns (address);
    function DESTINATION_DEX() external view returns (uint32);
}

interface ICoreWriterHookImmutables {
    function CORE_WRITER() external view returns (address);
}

/// @title HyperEVMHyperCoreDeploymentForkTest
/// @notice Pilot integration: a SuperVault on HyperEVM (chain 999) whose strategy funds a HyperCore
///         perp account, and how that account is priced back into the vault's NAV.
///
///         The shape under test is the one a partner asked for: "set up a vault on HyperEVM to
///         deposit to an account on HyperCore". The HyperCore account IS the strategy clone: the
///         deposit gateway credits msg.sender, and CoreWriter's HyperCore actor is msg.sender, so the
///         strategy address is simultaneously the EVM holder of idle USDC and the HyperCore master
///         account holding the perp margin. Nothing else needs a key.
///
/// @dev What a fork CAN verify (and this suite does):
///      - the live periphery + v2-core HyperCore stack on 999 is wired and the hook immutables match
///        mainnet USDC / gateway / perp dex 0;
///      - the strategy executes the real ApproveAndHyperCoreDeposit hook against the REAL USDC and
///        REAL gateway: the gateway pulls exactly the amount, no allowance survives, and the gateway
///        emits the CoreWriter `sendAsset` for the strategy with destinationDex 0 (perp margin);
///      - the withdraw leg (usdClassTransfer perp->spot, sendAsset spot->HyperEVM) runs through the
///        strategy and the real CoreWriter logs the hook payloads byte-for-byte;
///      - the deployed HyperCorePerpPositionOracle reads GENUINE HyperCore state on the fork, through
///        precompile forwarders (vm.etch + vm.rpc), and a fresh strategy prices to zero on Core;
///      - the NAV model: PPS = (idle USDC + HyperCore accountValue) / supply, pushed through the live
///        ECDSA PPS oracle path, reprices shares for gains and losses, and a full
///        deposit -> deploy -> reprice -> unwind -> redeem cycle makes the holder whole at the new PPS.
///      What it CANNOT: observe the HyperCore-side credit of a fork-local deposit. HyperCore is node
///      state, not EVM state, so after the deposit hook runs the precompiles still report the fresh
///      strategy as empty. Where the Core credit matters (NAV tests) the margin-summary precompile is
///      mocked for the strategy with the figures HyperCore would hold, and the EVM credit of a
///      withdrawal is emulated with `deal`. Both are called out inline.
///
/// @dev PRODUCTION GAP, asserted by `test_Fork_HyperEVM_HookRegistrationGap`: as of this writing the
///      USDC-perp deposit hook (0xCF90...) is deployed on 999 but NOT registered in the SuperGovernor,
///      while the two CoreWriter hooks and ApproveERC20 are. `executeHooks` rejects it with
///      INVALID_HOOK. The strategy tests register it in-fork via a GOVERNOR_ROLE grant.
///
/// @dev Set HYPEREVM_RPC_URL; falls back to the public https://rpc.hyperliquid.xyz/evm.
contract HyperEVMHyperCoreDeploymentForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                  PRODUCTION ADDRESSES (HYPEREVM, 999)
    //////////////////////////////////////////////////////////////*/
    // Periphery - script/output/prod/999/HyperEVM-latest.json
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address constant SUPER_ORACLE = 0x40c72A5667572641Ca428a2DFa8456EBD4623c10;
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant SUPER_VAULT_IMPL = 0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2;
    address constant STRATEGY_IMPL = 0x770abd170404B8ed8182c04f380E567e647b457D;
    address constant ESCROW_IMPL = 0x8982cf48eaB6616f2892888410afad9b0CD2BC9B;
    address constant SUPER_VAULT_EXECUTOR = 0x183e3171EEf801cE2A29FD48B3b21188f241875d;

    // v2-core - script/output/prod/999/HyperEVM-latest.json (sibling v2-core repo)
    /// @dev ApproveAndHyperCoreDepositHook instance pinned to (USDC, USDC gateway, perp dex 0)
    address constant HYPERCORE_DEPOSIT_USDC_PERP_HOOK = 0xCF90E02ede782E6Cdce58fA6E4d2509614dF784D;
    address constant HYPERCORE_USD_CLASS_TRANSFER_HOOK = 0x50c925F20993E0A1C91623df444b226417866DEE;
    address constant HYPERCORE_SEND_ASSET_HOOK = 0x90dc9d2BB3cFF8E3b228F4a48Bb9678eCF52CD2E;
    address constant HYPERCORE_PERP_POSITION_ORACLE = 0xB493FDebc1b5758A24680ac691e6349dE12f95cd;
    address constant APPROVE_ERC20_HOOK = 0x17DdFE8988cF71BBd672e5daFc4f6D02Cf279fA4;

    // Hyperliquid system contracts (v2-core script/utils/ConstantsOtherHooks.sol)
    address constant CORE_WRITER = 0x3333333333333333333333333333333333333333;
    /// @dev The real USDC ERC-20 on HyperEVM, NOT what tokenInfo.evmContract returns
    address constant USDC = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    /// @dev Per-token HyperCore deposit gateway for USDC (tokenInfo.evmContract)
    address constant USDC_GATEWAY = 0x6B9E773128f453f5c2C60935Ee2DE2CBc5390A24;
    /// @dev HyperCore system address of USDC (token index 0): the sendAsset destination for a
    ///      spot -> HyperEVM withdrawal
    address constant USDC_SYSTEM_ADDRESS = 0x2000000000000000000000000000000000000000;
    uint64 constant USDC_CORE_TOKEN_INDEX = 0;
    /// @dev HyperCore USDC carries 8 wei decimals against 6 on the EVM; `sendAsset.wei` is in Core wei
    uint256 constant USDC_CORE_WEI_PER_EVM_UNIT = 100;

    // HyperCore read precompiles
    address constant WITHDRAWABLE_PRECOMPILE = 0x0000000000000000000000000000000000000803;
    address constant ACCOUNT_MARGIN_SUMMARY_PRECOMPILE = 0x000000000000000000000000000000000000080F;
    address constant CORE_USER_EXISTS_PRECOMPILE = 0x0000000000000000000000000000000000000810;
    uint32 constant PERP_DEX_0 = 0;
    uint32 constant BTC_PERP = 0;
    /// @dev HLP strategy sub-vault: a live HyperCore account with real open perps, used to prove the
    ///      deployed oracle reads genuine Core state on the fork
    address constant HLP_STRATEGY = 0x010461C14e146ac35Fe42271BDC1134EE31C703a;

    bytes32 constant RAW_ACTION_TOPIC = keccak256("RawAction(address,bytes)");
    bytes4 constant ACTION_USD_CLASS_TRANSFER_PREFIX = 0x01000007;
    bytes4 constant ACTION_SEND_ASSET_PREFIX = 0x0100000d;

    /// @dev CoreWriter action 13 arguments, as the gateway (or the sendAsset hook) encodes them
    struct SendAssetArgs {
        address destination;
        uint256 subAccount;
        uint32 sourceDex;
        uint32 destinationDex;
        uint64 token;
        uint64 amountWei;
    }

    uint256 constant MIN_UPDATE_INTERVAL = 600;
    uint256 constant MAX_STALENESS = 3600; // >= getMinStaleness() (300) on HyperEVM
    uint256 constant HOOKS_ROOT_TIMELOCK = 900; // getHooksRootUpdateTimelock() on HyperEVM
    uint256 constant PPS_ONE = 1e6; // PPS in asset decimals; USDC has 6

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/
    ISuperGovernor internal governor = ISuperGovernor(SUPER_GOVERNOR);
    ISuperVaultAggregator internal aggregator = ISuperVaultAggregator(AGGREGATOR);
    IHyperCorePerpSnapshot internal perpOracle = IHyperCorePerpSnapshot(HYPERCORE_PERP_POSITION_ORACLE);
    IERC20 internal usdc = IERC20(USDC);

    address internal manager = makeAddr("hyperevm-vault-manager");
    address internal treasury = makeAddr("hyperevm-fee-recipient");
    address internal governorEoa = makeAddr("hyperevm-fork-governor");
    address internal alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.envOr("HYPEREVM_RPC_URL", string("https://rpc.hyperliquid.xyz/evm")));
        assertEq(block.chainid, 999, "not a HyperEVM fork");
    }

    /*//////////////////////////////////////////////////////////////
                          1. DEPLOYMENT WIRING
    //////////////////////////////////////////////////////////////*/

    function test_Fork_HyperEVM_AllContractsHaveCode() public view {
        address[16] memory deployed = [
            SUPER_GOVERNOR,
            AGGREGATOR,
            SUPER_ORACLE,
            SUPER_BANK,
            ECDSA_PPS_ORACLE,
            SUPER_VAULT_IMPL,
            STRATEGY_IMPL,
            ESCROW_IMPL,
            SUPER_VAULT_EXECUTOR,
            HYPERCORE_DEPOSIT_USDC_PERP_HOOK,
            HYPERCORE_USD_CLASS_TRANSFER_HOOK,
            HYPERCORE_SEND_ASSET_HOOK,
            HYPERCORE_PERP_POSITION_ORACLE,
            CORE_WRITER,
            USDC,
            USDC_GATEWAY
        ];
        for (uint256 i; i < deployed.length; ++i) {
            assertGt(deployed[i].code.length, 0, "missing code");
        }
        assertTrue(USDC != USDC_GATEWAY, "token and gateway must never be the same address");
        assertEq(IERC20Metadata(USDC).decimals(), 6, "USDC decimals");
        assertEq(IERC20Metadata(USDC).symbol(), "USDC", "USDC symbol");
    }

    function test_Fork_HyperEVM_GovernorWiring() public view {
        assertEq(governor.getAddress(governor.SUPER_VAULT_AGGREGATOR()), AGGREGATOR, "aggregator wired");
        assertEq(governor.getAddress(governor.SUPER_ORACLE()), SUPER_ORACLE, "oracle wired");
        assertEq(governor.getAddress(governor.SUPER_BANK()), SUPER_BANK, "bank wired");
        assertEq(governor.getActivePPSOracle(), ECDSA_PPS_ORACLE, "active PPS oracle");
        assertEq(governor.getMinStaleness(), 300, "min staleness floor");
        assertEq(aggregator.getHooksRootUpdateTimelock(), HOOKS_ROOT_TIMELOCK, "strategy root timelock");
        assertEq(aggregator.getGlobalHooksRoot(), bytes32(0), "global root unset: strategy roots are the only path");
    }

    /// @notice The deployed deposit hook is pinned to mainnet USDC, the USDC gateway and perp dex 0,
    ///         so it can only ever move USDC into the executing account's perp margin.
    function test_Fork_HyperEVM_DepositHookImmutablesMatchMainnet() public view {
        IHyperCoreDepositHookImmutables hook = IHyperCoreDepositHookImmutables(HYPERCORE_DEPOSIT_USDC_PERP_HOOK);
        assertEq(hook.TOKEN(), USDC, "TOKEN = real USDC ERC-20");
        assertEq(hook.GATEWAY(), USDC_GATEWAY, "GATEWAY = USDC deposit gateway");
        assertEq(hook.DESTINATION_DEX(), PERP_DEX_0, "destinationDex 0 = perp margin, not spot");

        // The merkle leaf is built from inspect(): the pair (token, gateway) regardless of amount
        bytes memory args = IHookInspector(HYPERCORE_DEPOSIT_USDC_PERP_HOOK).inspect(_depositData(1));
        assertEq(args, abi.encodePacked(USDC, USDC_GATEWAY), "inspect = (TOKEN, GATEWAY)");

        assertEq(
            ICoreWriterHookImmutables(HYPERCORE_USD_CLASS_TRANSFER_HOOK).CORE_WRITER(), CORE_WRITER, "class transfer"
        );
        assertEq(ICoreWriterHookImmutables(HYPERCORE_SEND_ASSET_HOOK).CORE_WRITER(), CORE_WRITER, "send asset");
    }

    /// @notice Registration state on 999 at the time of writing: the CoreWriter hooks are registered,
    ///         the USDC-perp deposit hook is NOT. This test flips when governance registers it, which is
    ///         the signal to drop the in-fork `_registerDepositHookInFork` from the suite.
    function test_Fork_HyperEVM_HookRegistrationGap() public view {
        assertTrue(governor.isHookRegistered(HYPERCORE_USD_CLASS_TRANSFER_HOOK), "usdClassTransfer registered");
        assertTrue(governor.isHookRegistered(HYPERCORE_SEND_ASSET_HOOK), "sendAsset registered");
        assertTrue(governor.isHookRegistered(APPROVE_ERC20_HOOK), "approve erc20 registered");
        assertFalse(
            governor.isHookRegistered(HYPERCORE_DEPOSIT_USDC_PERP_HOOK),
            "deposit hook now registered: remove the in-fork registration"
        );
    }

    /*//////////////////////////////////////////////////////////////
                    2. VAULT CREATION ON THE LIVE AGGREGATOR
    //////////////////////////////////////////////////////////////*/

    function test_Fork_HyperEVM_CreateVault() public {
        (address vault, address strategy, address escrow) = _createVault();

        assertGt(vault.code.length, 0, "vault clone");
        assertGt(strategy.code.length, 0, "strategy clone");
        assertGt(escrow.code.length, 0, "escrow clone");
        assertEq(IERC4626(vault).asset(), USDC, "asset");
        assertEq(aggregator.getMainManager(strategy), manager, "main manager seated");
        assertEq(aggregator.getPPS(strategy), PPS_ONE, "initial PPS = 1.0");
        assertEq(IERC4626(vault).totalAssets(), 0, "fresh vault is empty");
    }

    function test_Fork_HyperEVM_CreateVaultAndDeposit() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;

        _depositAs(alice, vault, amount);

        assertEq(IERC20(vault).balanceOf(alice), amount, "1:1 shares at PPS 1.0");
        assertEq(usdc.balanceOf(strategy), amount, "strategy holds the deposit idle");
        assertEq(IERC4626(vault).totalAssets(), amount, "totalAssets");
    }

    /*//////////////////////////////////////////////////////////////
                3. FUNDING LEG: STRATEGY -> HYPERCORE PERP MARGIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Production gate in action: without governor registration the strategy rejects the
    ///         deposit hook before any merkle validation.
    function test_Fork_HyperEVM_ExecuteHook_RevertsUntilDepositHookIsRegistered() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 100e6);

        bytes memory data = _depositData(100e6);
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.INVALID_HOOK.selector);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, 0));
    }

    /// @notice The real v2-core deposit hook, executed by a real HyperEVM SuperVault strategy against the
    ///         REAL USDC and the REAL gateway. The gateway pulls exactly the amount and itself calls
    ///         CoreWriter: the RawAction it logs is a `sendAsset` crediting the STRATEGY on perp dex 0.
    function test_Fork_HyperEVM_ExecuteHook_DepositIntoHyperCorePerpMargin() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;
        _depositAs(alice, vault, amount);
        assertEq(usdc.balanceOf(strategy), amount, "strategy funded");

        bytes memory data = _depositData(amount);
        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data);

        vm.recordLogs();
        // expectedAssetsOrSharesOut = amount: the hook reports the EVM balance delta as outAmount, so the
        // slippage guard is meaningful here (unlike the CoreWriter hooks, which report 0).
        vm.prank(manager);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, amount));

        // --- EVM leg, fully observable ---
        assertEq(usdc.balanceOf(strategy), 0, "gateway pulled exactly the deposit amount");
        assertEq(usdc.allowance(strategy, USDC_GATEWAY), 0, "no standing allowance may survive");
        assertEq(IHookResult(HYPERCORE_DEPOSIT_USDC_PERP_HOOK).getOutAmount(strategy), amount, "outAmount");
        assertEq(IHookResult(HYPERCORE_DEPOSIT_USDC_PERP_HOOK).getOutToken(strategy), USDC, "outToken");

        // --- Core leg, as far as the EVM can see it: the gateway's CoreWriter emission ---
        SendAssetArgs memory sent = _decodeSendAsset(_singleRawActionPayload(vm.getRecordedLogs(), USDC_GATEWAY));
        assertEq(sent.destination, strategy, "HyperCore credits the STRATEGY: it is the HyperCore account");
        assertEq(sent.subAccount, 0, "no sub-account");
        assertEq(sent.sourceDex, type(uint32).max, "from gateway spot");
        assertEq(sent.destinationDex, PERP_DEX_0, "into perp dex 0 margin");
        assertEq(sent.token, USDC_CORE_TOKEN_INDEX, "USDC core index");
        assertEq(uint256(sent.amountWei), amount * USDC_CORE_WEI_PER_EVM_UNIT, "Core wei = EVM amount * 100");

        // The vault's own accounting is untouched by the deployment: PPS is reported, not derived
        assertEq(IERC4626(vault).totalAssets(), amount, "totalAssets unchanged until the PPS reporter speaks");
        assertEq(aggregator.getPPS(strategy), PPS_ONE, "PPS unchanged");
    }

    /// @notice Partial deployment: only the requested amount leaves, the remainder stays idle on the EVM
    ///         side and remains countable by balance.
    function test_Fork_HyperEVM_ExecuteHook_PartialDeploymentLeavesIdleBalance() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 1000e6);

        bytes memory data = _depositData(400e6);
        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data);
        _executeHook(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, 400e6);

        assertEq(usdc.balanceOf(strategy), 600e6, "600 idle on the EVM");
        assertEq(IHookResult(HYPERCORE_DEPOSIT_USDC_PERP_HOOK).getOutAmount(strategy), 400e6, "400 to Core");
    }

    /// @notice One strategy root authorises the (hook, token, gateway) pair, not an amount: the manager
    ///         can top up the HyperCore account repeatedly under the same root.
    function test_Fork_HyperEVM_ExecuteHook_RootIsAmountAgnostic() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 1000e6);

        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, _depositData(1));

        _executeHook(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, _depositData(250e6), 250e6);
        _executeHook(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, _depositData(750e6), 750e6);
        assertEq(usdc.balanceOf(strategy), 0, "both top-ups went through under one root");
    }

    /// @notice A deposit that exceeds idle USDC fails inside the gateway's transferFrom and the strategy
    ///         surfaces it as OPERATION_FAILED: nothing is half-applied.
    function test_Fork_HyperEVM_ExecuteHook_RevertsBeyondIdleBalance() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 100e6);

        bytes memory data = _depositData(101e6);
        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.OPERATION_FAILED.selector);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, 0));
        assertEq(usdc.balanceOf(strategy), 100e6, "untouched");
        assertEq(usdc.allowance(strategy, USDC_GATEWAY), 0, "no allowance leaked by the revert");
    }

    /*//////////////////////////////////////////////////////////////
            4. WITHDRAW LEG: PERP MARGIN -> SPOT -> HYPEREVM
    //////////////////////////////////////////////////////////////*/

    /// @notice The unwind, through the strategy, with the two CoreWriter hooks that ARE registered on
    ///         999: `usdClassTransfer(ntl, toPerp=false)` moves margin to spot, `sendAsset` to the USDC
    ///         system address moves spot back to the strategy's HyperEVM balance. CoreWriter never
    ///         reverts and reports nothing, so the strongest fork assertion is that the real CoreWriter
    ///         logs the hook-built payload byte-for-byte for the STRATEGY as actor.
    function test_Fork_HyperEVM_ExecuteHooks_WithdrawLegEmitsExactCoreWriterPayloads() public {
        (, address strategy,) = _createVault();
        uint256 amount = 1000e6;

        bytes memory classTransferData = _usdClassTransferData(uint64(amount), false);
        bytes memory sendAssetData = _sendAssetWithdrawData(uint64(amount * USDC_CORE_WEI_PER_EVM_UNIT));

        (bytes32 root, bytes32[] memory proofA, bytes32[] memory proofB) = _twoLeafTree(
            _leaf(HYPERCORE_USD_CLASS_TRANSFER_HOOK, classTransferData), _leaf(HYPERCORE_SEND_ASSET_HOOK, sendAssetData)
        );
        _activateRoot(strategy, root);

        address[] memory hooks = new address[](2);
        hooks[0] = HYPERCORE_USD_CLASS_TRANSFER_HOOK;
        hooks[1] = HYPERCORE_SEND_ASSET_HOOK;
        bytes[] memory datas = new bytes[](2);
        datas[0] = classTransferData;
        datas[1] = sendAssetData;
        bytes32[][] memory proofs = new bytes32[][](2);
        proofs[0] = proofA;
        proofs[1] = proofB;

        vm.recordLogs();
        vm.prank(manager);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgsMulti(hooks, datas, proofs));

        bytes[] memory payloads = _rawActionPayloads(vm.getRecordedLogs(), strategy);
        assertEq(payloads.length, 2, "two CoreWriter actions, both with the strategy as HyperCore actor");
        assertEq(
            payloads[0],
            _expectedClassTransferPayload(uint64(amount), false),
            "usdClassTransfer(ntl = 1000 USDC in 1e6, toPerp = false)"
        );
        assertEq(
            payloads[1],
            _expectedSendAssetWithdrawPayload(uint64(amount * USDC_CORE_WEI_PER_EVM_UNIT)),
            "sendAsset(USDC system address, spot -> spot, token 0, 1000 USDC in Core wei)"
        );
    }

    /// @notice CoreWriter hooks that move value are TRANSFORM-piped and publish no outAmount, so a
    ///         non-zero `expectedAssetsOrSharesOut` can never be met: the manager must pass 0 for them.
    function test_Fork_HyperEVM_ExecuteHooks_CoreWriterHookReportsNoOutAmount() public {
        (, address strategy,) = _createVault();
        bytes memory data = _usdClassTransferData(1_000_000, false);
        _setStrategyRoot(strategy, HYPERCORE_USD_CLASS_TRANSFER_HOOK, data);

        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET.selector);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(HYPERCORE_USD_CLASS_TRANSFER_HOOK, data, 1));

        _executeHook(strategy, HYPERCORE_USD_CLASS_TRANSFER_HOOK, data, 0);
        assertEq(IHookResult(HYPERCORE_USD_CLASS_TRANSFER_HOOK).getOutAmount(strategy), 0, "no EVM-observable delta");
    }

    /*//////////////////////////////////////////////////////////////
              5. NAV: PRICING THE HYPERCORE ACCOUNT INTO PPS
    //////////////////////////////////////////////////////////////*/

    /// @notice The DEPLOYED oracle on 999 reads genuine HyperCore state once the read precompiles are
    ///         reachable: on the fork they are code-less, so forwarders that proxy to the live node are
    ///         etched at the precompile addresses and the oracle runs unmodified against them.
    function test_Fork_HyperEVM_PerpOracle_ReadsLiveHyperCoreState() public {
        HyperCorePrecompileForwarderLib.install();

        uint32[] memory perps = new uint32[](1);
        perps[0] = BTC_PERP;
        IHyperCorePerpSnapshot.AccountSnapshot memory snap = perpOracle.getAccountSnapshot(HLP_STRATEGY, perps);

        assertTrue(snap.coreUserExists, "HLP strategy exists on Core");
        assertEq(snap.perpDex, PERP_DEX_0, "dex 0");
        assertGt(snap.accountValue, 0, "live account value");
        assertEq(snap.positions.length, 1, "one row per requested perp");
        assertEq(snap.positions[0].coin, "BTC", "BTC leg");
        assertEq(snap.positions[0].szDecimals, 5, "BTC size decimals");
        assertGt(snap.positions[0].markPx, 0, "live mark");
        console2.log("HLP accountValue (6dp USD):", uint256(int256(snap.accountValue)));
        console2.log("HLP marginUsed   (6dp USD):", uint256(snap.marginUsed));
    }

    /// @notice A freshly created strategy has no HyperCore footprint: the oracle prices it to zero on
    ///         Core, so pre-deployment NAV is exactly the idle EVM balance. This is also the state the
    ///         fork keeps reporting AFTER a fork-local deposit, since Core credits are node state.
    function test_Fork_HyperEVM_NAV_FreshStrategyPricesToZeroOnCore() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 1000e6);
        HyperCorePrecompileForwarderLib.install();

        IHyperCorePerpSnapshot.AccountSnapshot memory snap = perpOracle.getAccountSnapshot(strategy, new uint32[](0));
        assertFalse(snap.coreUserExists, "no Core account yet");
        assertEq(snap.accountValue, 0, "nothing on Core");
        assertEq(snap.withdrawableUsd, 0, "nothing withdrawable");

        assertEq(_nav(strategy), 1000e6, "NAV = idle USDC + 0");
        assertEq(_ppsFromNav(vault, strategy), PPS_ONE, "PPS 1.0");
    }

    /// @notice The NAV model for the pilot, end to end on the live vault:
    ///             NAV = idle USDC on the strategy + HyperCore accountValue(strategy, dex 0)
    ///             PPS = NAV / totalSupply
    ///         `accountValue` is HyperCore's own mark-to-market net of unrealised PnL and funding, so a
    ///         PPS reporter needs no per-position maths. The reporter signs it into the ECDSA PPS oracle,
    ///         which is the only caller `forwardPPS` accepts; the vault derives totalAssets from it.
    /// @dev The Core credit is not visible on a fork, so the margin-summary precompile is mocked for the
    ///      strategy with the figures HyperCore would hold after the deposit, then after a gain and a loss.
    function test_Fork_HyperEVM_NAV_PPSTracksHyperCoreAccountValue() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e6;
        _depositAs(alice, vault, amount);

        bytes memory data = _depositData(amount);
        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data);
        _executeHook(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, amount);
        assertEq(usdc.balanceOf(strategy), 0, "fully deployed to Core");

        // (1) Right after the credit lands: account value == what was sent, NAV unchanged, PPS stays 1.0
        _mockCoreAccount(strategy, int64(uint64(amount)));
        assertEq(_nav(strategy), amount, "NAV = 0 idle + 1000 on Core");
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, _ppsFromNav(vault, strategy));
        assertEq(aggregator.getPPS(strategy), PPS_ONE, "deployment is NAV-neutral");
        assertEq(IERC4626(vault).totalAssets(), amount, "totalAssets = supply * PPS");

        // (2) +5% mark-to-market on Core
        _mockCoreAccount(strategy, int64(uint64(1050e6)));
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, _ppsFromNav(vault, strategy));
        assertEq(aggregator.getPPS(strategy), 1.05e6, "PPS 1.05");
        assertEq(IERC4626(vault).totalAssets(), 1050e6, "gain priced in");
        assertEq(IERC4626(vault).convertToAssets(IERC20(vault).balanceOf(alice)), 1050e6, "holder claim grew");
        assertFalse(aggregator.isPPSStale(strategy), "fresh");

        // (3) a drawdown to 900 on Core
        _mockCoreAccount(strategy, int64(uint64(900e6)));
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, _ppsFromNav(vault, strategy));
        assertEq(aggregator.getPPS(strategy), 0.9e6, "PPS 0.90");
        assertEq(IERC4626(vault).totalAssets(), 900e6, "loss priced in");
    }

    /// @notice Mixed book: part idle on the EVM, part on Core. NAV is the sum, so the PPS reporter must
    ///         read BOTH legs; pricing only the Core account would under-report the vault.
    function test_Fork_HyperEVM_NAV_SumsIdleAndCoreLegs() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 1000e6);

        bytes memory data = _depositData(600e6);
        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data);
        _executeHook(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, 600e6);

        _mockCoreAccount(strategy, int64(uint64(630e6))); // 600 deployed, +5% on Core
        assertEq(usdc.balanceOf(strategy), 400e6, "idle leg");
        assertEq(_nav(strategy), 1030e6, "400 idle + 630 Core");

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, _ppsFromNav(vault, strategy));
        assertEq(IERC4626(vault).totalAssets(), 1030e6, "blended NAV");
    }

    /// @notice HyperCore's `accountValue` is SIGNED. A negative value (bad debt on the perp account) must
    ///         not underflow the NAV: the Core leg floors at zero and the vault is worth its idle USDC.
    ///         Reporting that PPS is an 80% move, beyond the aggregator's 50% deviation band, so the
    ///         live breaker refuses the write and auto-pauses the strategy instead of repricing. That is
    ///         the intended outcome for a liquidated perp account: deposits close until governance looks.
    function test_Fork_HyperEVM_NAV_NegativeAccountValueFloorsAtZeroAndTripsDeviationBreaker() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 1000e6);

        bytes memory data = _depositData(800e6);
        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data);
        _executeHook(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, 800e6);

        _mockCoreAccount(strategy, -50e6);
        assertEq(_nav(strategy), 200e6, "idle only; Core leg floored at 0, no underflow");
        assertEq(_ppsFromNav(vault, strategy), 0.2e6, "reporter would publish 0.20");
        assertEq(aggregator.getDeviationThreshold(strategy), 5e17, "default deviation band is 50%");

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, _ppsFromNav(vault, strategy));

        assertEq(aggregator.getPPS(strategy), PPS_ONE, "out-of-band PPS NOT written");
        assertTrue(aggregator.isStrategyPaused(strategy), "strategy auto-paused");
        assertTrue(aggregator.isPPSStale(strategy), "PPS flagged stale");
        assertEq(IERC4626(vault).maxDeposit(alice), 0, "vault closed to deposits");
    }

    /// @notice A loss inside the deviation band is simply priced in: -30% on Core is written as PPS 0.70.
    function test_Fork_HyperEVM_NAV_LossWithinBandIsWritten() public {
        (address vault, address strategy,) = _createVault();
        _depositAs(alice, vault, 1000e6);

        bytes memory data = _depositData(1000e6);
        _registerDepositHookInFork();
        _setStrategyRoot(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data);
        _executeHook(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, data, 1000e6);

        _mockCoreAccount(strategy, int64(uint64(700e6)));
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _forwardPPS(strategy, _ppsFromNav(vault, strategy));

        assertEq(aggregator.getPPS(strategy), 0.7e6, "PPS 0.70");
        assertFalse(aggregator.isStrategyPaused(strategy), "within band: no pause");
        assertEq(IERC4626(vault).totalAssets(), 700e6, "loss priced in");
    }

    /*//////////////////////////////////////////////////////////////
                        6. FULL CYCLE ON THE LIVE VAULT
    //////////////////////////////////////////////////////////////*/

    /// @notice deposit -> deploy to Core -> Core gains 5% -> reprice -> holder requests redeem ->
    ///         manager unwinds through the CoreWriter hooks -> fulfil at the new PPS -> holder redeems.
    /// @dev The HyperCore -> HyperEVM credit produced by `sendAsset` is node state and cannot be executed
    ///      on a fork; after the withdraw leg runs and is verified on CoreWriter, `deal` stands in for the
    ///      USDC arriving back on the strategy. Everything else is the live code path.
    function test_Fork_HyperEVM_FullCycle_DepositDeployRepriceUnwindRedeem() public {
        (address vault, address strategy, address escrow) = _createVault();
        uint256 amount = 1000e6;
        _depositAs(alice, vault, amount);
        uint256 shares = IERC20(vault).balanceOf(alice);

        // deploy
        bytes memory depositData = _depositData(amount);
        _registerDepositHookInFork();
        bytes memory classTransferData = _usdClassTransferData(uint64(1050e6), false);
        bytes memory sendAssetData = _sendAssetWithdrawData(uint64(1050e6 * USDC_CORE_WEI_PER_EVM_UNIT));
        {
            (bytes32 root, bytes32[] memory p0, bytes32[] memory p1, bytes32[] memory p2) = _threeLeafTree(
                _leaf(HYPERCORE_DEPOSIT_USDC_PERP_HOOK, depositData),
                _leaf(HYPERCORE_USD_CLASS_TRANSFER_HOOK, classTransferData),
                _leaf(HYPERCORE_SEND_ASSET_HOOK, sendAssetData)
            );
            _activateRoot(strategy, root);
            _executeHookWithProof(strategy, HYPERCORE_DEPOSIT_USDC_PERP_HOOK, depositData, p0, amount);
            assertEq(usdc.balanceOf(strategy), 0, "all capital on Core");

            // Core marks the account up 5%; the reporter prices it in
            _mockCoreAccount(strategy, int64(uint64(1050e6)));
            vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
            _forwardPPS(strategy, _ppsFromNav(vault, strategy));
            assertEq(IERC4626(vault).convertToAssets(shares), 1050e6, "claim at 1.05");

            // holder asks to leave while fully deployed
            vm.prank(alice);
            ISuperVault(vault).requestRedeem(shares, alice, alice);
            assertEq(ISuperVault(vault).pendingRedeemRequest(0, alice), shares, "pending");

            // manager unwinds the whole account: margin -> spot -> HyperEVM
            vm.recordLogs();
            _executeHookWithProof(strategy, HYPERCORE_USD_CLASS_TRANSFER_HOOK, classTransferData, p1, 0);
            _executeHookWithProof(strategy, HYPERCORE_SEND_ASSET_HOOK, sendAssetData, p2, 0);
            assertEq(_rawActionPayloads(vm.getRecordedLogs(), strategy).length, 2, "both unwind actions sent");
        }

        // FORK LIMIT: emulate the Core -> EVM credit that sendAsset produces on the real chain
        _mockCoreAccount(strategy, 0);
        deal(USDC, strategy, 1050e6);
        assertEq(_nav(strategy), 1050e6, "NAV back on the EVM side, unchanged by the unwind");

        // fulfil at the repriced NAV and let the holder claim
        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = 1050e6;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);
        assertEq(usdc.balanceOf(escrow), 1050e6, "escrowed for the holder");
        assertEq(ISuperVault(vault).claimableRedeemRequest(0, alice), shares, "claimable");

        vm.prank(alice);
        uint256 back = IERC4626(vault).redeem(shares, alice, alice);
        assertEq(back, 1050e6, "holder made whole at the Core-marked PPS");
        assertEq(usdc.balanceOf(alice), 1050e6, "received");
        assertEq(IERC4626(vault).totalSupply(), 0, "all shares burned");
        assertEq(usdc.balanceOf(strategy), 0, "strategy drained");
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Zero fees so NAV and PPS arithmetic is exact in the assertions; fee behaviour is covered by
    ///      the generic SuperVault suites and is not HyperCore-specific.
    function _createVault() internal returns (address vault, address strategy, address escrow) {
        (vault, strategy, escrow) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: USDC,
                name: "HyperEVM Fork Test SuperVault USDC (HyperCore perp)",
                symbol: "tsvUSDC-hc",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: MIN_UPDATE_INTERVAL,
                maxStaleness: MAX_STALENESS,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0, managementFeeBps: 0, recipient: treasury
                })
            })
        );
    }

    /// @dev HyperEVM USDC is a plain ERC-20 (the gateway is a separate contract), so a balance write is enough.
    function _depositAs(address who, address vault, uint256 amount) internal returns (uint256 shares) {
        deal(USDC, who, amount);
        vm.startPrank(who);
        usdc.approve(vault, amount);
        shares = IERC4626(vault).deposit(amount, who);
        vm.stopPrank();
    }

    /// @dev Grants GOVERNOR_ROLE to a fork-local EOA and registers the deposit hook, standing in for the
    ///      governance action 999 has not taken yet. OZ 5.x AccessControl keeps `_roles` at slot 0.
    function _registerDepositHookInFork() internal {
        if (governor.isHookRegistered(HYPERCORE_DEPOSIT_USDC_PERP_HOOK)) return;
        bytes32 role = governor.GOVERNOR_ROLE();
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(governorEoa, roleSlot));
        vm.store(SUPER_GOVERNOR, hasRoleSlot, bytes32(uint256(1)));
        assertTrue(governor.hasRole(role, governorEoa), "fork governor seated");

        vm.prank(governorEoa);
        governor.registerHook(HYPERCORE_DEPOSIT_USDC_PERP_HOOK);
        assertTrue(governor.isHookRegistered(HYPERCORE_DEPOSIT_USDC_PERP_HOOK), "registered in-fork");
    }

    /// @dev ApproveAndHyperCoreDepositHook data (85 bytes):
    ///      bytes32 placeholder | address placeholder | uint256 amount | bool usePrevHookAmount
    ///      Token, gateway and destination dex are immutables, so there is nothing else to supply.
    function _depositData(uint256 amount) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes32(0), address(0), amount, false);
    }

    /// @dev HyperCoreUsdClassTransferHook data (61 bytes):
    ///      bytes32 placeholder | address placeholder | uint64 ntl (1e6 USD units) | bool toPerp
    function _usdClassTransferData(uint64 ntl, bool toPerp) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes32(0), address(0), ntl, toPerp);
    }

    /// @dev HyperCoreSendAssetHook data (88 bytes), withdraw-to-HyperEVM shape:
    ///      bytes32 placeholder | address placeholder | address destination | uint64 token | uint64 amountWei
    function _sendAssetWithdrawData(uint64 amountWei) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes32(0), address(0), USDC_SYSTEM_ADDRESS, USDC_CORE_TOKEN_INDEX, amountWei);
    }

    /// @dev Pilot NAV: idle EVM USDC plus HyperCore's netted account value on perp dex 0, floored at zero.
    ///      Reads the DEPLOYED oracle; precompiles must be reachable (forwarder or mock).
    function _nav(address strategy) internal view returns (uint256) {
        IHyperCorePerpSnapshot.AccountSnapshot memory snap = perpOracle.getAccountSnapshot(strategy, new uint32[](0));
        uint256 coreLeg = snap.accountValue > 0 ? uint256(int256(snap.accountValue)) : 0;
        return usdc.balanceOf(strategy) + coreLeg;
    }

    function _ppsFromNav(address vault, address strategy) internal view returns (uint256) {
        uint256 supply = IERC4626(vault).totalSupply();
        return supply == 0 ? PPS_ONE : (_nav(strategy) * PPS_ONE) / supply;
    }

    /// @dev Stands in for the HyperCore-side state of `account` on the fork: `accountMarginSummary(0, account)`,
    ///      `coreUserExists(account)` and `withdrawable(account)` answer as HyperCore would. Only the three
    ///      account-level reads the NAV uses are mocked; perp-level reads still go to the live node.
    function _mockCoreAccount(address account, int64 accountValue) internal {
        uint64 nonNegative = accountValue > 0 ? uint64(accountValue) : 0;
        vm.mockCall(
            ACCOUNT_MARGIN_SUMMARY_PRECOMPILE,
            abi.encode(PERP_DEX_0, account),
            abi.encode(accountValue, uint64(0), uint64(0), accountValue)
        );
        vm.mockCall(CORE_USER_EXISTS_PRECOMPILE, abi.encode(account), abi.encode(true));
        vm.mockCall(WITHDRAWABLE_PRECOMPILE, abi.encode(account), abi.encode(nonNegative));
    }

    /// @dev Single-leaf tree: root == leaf and the empty proof is accepted explicitly by `_validateSingleHook`.
    function _setStrategyRoot(address strategy, address hook, bytes memory hookData) internal {
        _activateRoot(strategy, _leaf(hook, hookData));
    }

    function _activateRoot(address strategy, bytes32 root) internal {
        vm.prank(manager);
        aggregator.proposeStrategyHooksRoot(strategy, root);
        vm.warp(block.timestamp + HOOKS_ROOT_TIMELOCK + 1);
        aggregator.executeStrategyHooksRootUpdate(strategy);
        assertEq(aggregator.getStrategyHooksRoot(strategy), root, "strategy root active");
    }

    function _leaf(address hook, bytes memory hookData) internal view returns (bytes32) {
        bytes memory hookArgs = IHookInspector(hook).inspect(hookData);
        return keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));
    }

    /// @dev OZ StandardMerkleTree hashes a sorted pair, so for two leaves each proof is the sibling.
    function _twoLeafTree(
        bytes32 a,
        bytes32 b
    )
        internal
        pure
        returns (bytes32 root, bytes32[] memory proofA, bytes32[] memory proofB)
    {
        root = _hashPair(a, b);
        proofA = new bytes32[](1);
        proofA[0] = b;
        proofB = new bytes32[](1);
        proofB[0] = a;
    }

    /// @dev Three leaves: (a, b) paired, c promoted; proofs are [sibling, other-branch] / [ab].
    function _threeLeafTree(
        bytes32 a,
        bytes32 b,
        bytes32 c
    )
        internal
        pure
        returns (bytes32 root, bytes32[] memory proofA, bytes32[] memory proofB, bytes32[] memory proofC)
    {
        bytes32 ab = _hashPair(a, b);
        root = _hashPair(ab, c);
        proofA = new bytes32[](2);
        proofA[0] = b;
        proofA[1] = c;
        proofB = new bytes32[](2);
        proofB[0] = a;
        proofB[1] = c;
        proofC = new bytes32[](1);
        proofC[0] = ab;
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a <= b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }

    function _executeHook(address strategy, address hook, bytes memory hookData, uint256 expectedOut) internal {
        vm.prank(manager);
        ISuperVaultStrategy(strategy).executeHooks(_executeArgs(hook, hookData, expectedOut));
    }

    function _executeHookWithProof(
        address strategy,
        address hook,
        bytes memory hookData,
        bytes32[] memory proof,
        uint256 expectedOut
    )
        internal
    {
        ISuperVaultStrategy.ExecuteArgs memory args = _executeArgs(hook, hookData, expectedOut);
        args.strategyProofs[0] = proof;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).executeHooks(args);
    }

    function _executeArgs(
        address hook,
        bytes memory hookData,
        uint256 expectedOut
    )
        internal
        pure
        returns (ISuperVaultStrategy.ExecuteArgs memory args)
    {
        address[] memory hooks = new address[](1);
        hooks[0] = hook;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = hookData;
        bytes32[][] memory proofs = new bytes32[][](1);
        proofs[0] = new bytes32[](0);
        args = _executeArgsMulti(hooks, calldatas, proofs);
        args.expectedAssetsOrSharesOut[0] = expectedOut;
    }

    function _executeArgsMulti(
        address[] memory hooks,
        bytes[] memory calldatas,
        bytes32[][] memory strategyProofs
    )
        internal
        pure
        returns (ISuperVaultStrategy.ExecuteArgs memory args)
    {
        uint256 n = hooks.length;
        uint256[] memory expected = new uint256[](n); // 0 disables the slippage assertion
        bytes32[][] memory globalProofs = new bytes32[][](n);
        for (uint256 i; i < n; ++i) {
            globalProofs[i] = new bytes32[](0);
        }
        args = ISuperVaultStrategy.ExecuteArgs({
            hooks: hooks,
            hookCalldata: calldatas,
            expectedAssetsOrSharesOut: expected,
            globalProofs: globalProofs,
            strategyProofs: strategyProofs
        });
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

    /// @dev Every CoreWriter RawAction payload logged for `user`, in emission order.
    function _rawActionPayloads(Vm.Log[] memory logs, address user) internal pure returns (bytes[] memory payloads) {
        uint256 found;
        for (uint256 i; i < logs.length; ++i) {
            if (_isRawActionFor(logs[i], user)) ++found;
        }
        payloads = new bytes[](found);
        uint256 k;
        for (uint256 i; i < logs.length; ++i) {
            if (_isRawActionFor(logs[i], user)) payloads[k++] = abi.decode(logs[i].data, (bytes));
        }
    }

    function _singleRawActionPayload(Vm.Log[] memory logs, address user) internal pure returns (bytes memory) {
        bytes[] memory payloads = _rawActionPayloads(logs, user);
        assertEq(payloads.length, 1, "expected exactly one RawAction for user");
        return payloads[0];
    }

    function _isRawActionFor(Vm.Log memory log, address user) internal pure returns (bool) {
        return log.emitter == CORE_WRITER && log.topics.length > 1 && log.topics[0] == RAW_ACTION_TOPIC
            && log.topics[1] == bytes32(uint256(uint160(user)));
    }

    /// @dev `version ‖ uint24 action 7 ‖ abi.encode(uint64 ntl, bool toPerp)`
    function _expectedClassTransferPayload(uint64 ntl, bool toPerp) internal pure returns (bytes memory) {
        return abi.encodePacked(ACTION_USD_CLASS_TRANSFER_PREFIX, abi.encode(ntl, toPerp));
    }

    /// @dev `version ‖ uint24 action 13 ‖ abi.encode(destination, subAccount, sourceDex, destinationDex, token,
    /// wei)`
    ///      in the withdraw-to-HyperEVM shape: USDC system address, spot -> spot, token index 0.
    function _expectedSendAssetWithdrawPayload(uint64 amountWei) internal pure returns (bytes memory) {
        return abi.encodePacked(
            ACTION_SEND_ASSET_PREFIX,
            abi.encode(
                USDC_SYSTEM_ADDRESS, uint256(0), type(uint32).max, type(uint32).max, USDC_CORE_TOKEN_INDEX, amountWei
            )
        );
    }

    function _decodeSendAsset(bytes memory payload) internal pure returns (SendAssetArgs memory a) {
        assertEq(bytes4(payload), ACTION_SEND_ASSET_PREFIX, "CoreWriter action 13 (sendAsset)");
        (a.destination, a.subAccount, a.sourceDex, a.destinationDex, a.token, a.amountWei) =
            abi.decode(_slice(payload, 4), (address, uint256, uint32, uint32, uint64, uint64));
    }

    function _slice(bytes memory data, uint256 start) internal pure returns (bytes memory out) {
        out = new bytes(data.length - start);
        for (uint256 i; i < out.length; ++i) {
            out[i] = data[start + i];
        }
    }
}
