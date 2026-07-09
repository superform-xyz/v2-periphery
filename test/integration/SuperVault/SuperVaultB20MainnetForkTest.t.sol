// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";
import { Mock4626Vault } from "../../mocks/Mock4626Vault.sol";

/// @dev Minimal interface to read the auto-generated `strategy()` / `PRECISION()` getters
///      that are NOT exposed by ISuperVault (it only exposes `escrow()`).
interface IVaultStrategyRef {
    function strategy() external view returns (address);
    function PRECISION() external view returns (uint256);
}

/// @title SuperVaultB20MainnetForkTest
/// @notice Fork integration tests for the production B20-asset SuperVault on Base mainnet.
///
/// Context
/// ───────
/// B20 tokens are Base precompiles: `eth_getCode` returns `0xef` (1 byte).
/// The EVM sentinel byte `0xef` maps to INVALID in revm, so any attempt to execute
/// B20 bytecode in a Foundry fork reverts. All B20 ERC-20 calls must therefore be
/// intercepted with vm.mockCall; the vault/strategy/aggregator state is fully real.
///
/// Flow under test
/// ───────────────
/// 1. Register a freshly-deployed Mock4626Vault as a yield source.
/// 2. User deposits B20 → SuperVault mints shares to user.
/// 3. Manager executes ApproveAndDeposit4626VaultHook → strategy holds mock4626 shares.
/// 4. User requests redeem.
/// 5. Manager executes Redeem4626VaultHook → mock4626 shares burned, B20 "back" in strategy.
/// 6. Manager calls fulfillRedeemRequests → assets become claimable.
/// 7. User calls redeem → shares burned, B20 sent to user.
///
/// Merkle bypass
/// ─────────────
/// The two hooks use a custom mock4626 address that is not in the production global root.
/// We build a 2-leaf OZ-sorted strategy root covering exactly those two
/// (hookAddress, inspect(data)) pairs, then propose/warp/execute the root.
///
/// Run:
///   forge test --match-contract SuperVaultB20MainnetForkTest -vvvv
contract SuperVaultB20MainnetForkTest is Test {
    using Math for uint256;

    // ══════════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (BASE MAINNET)
    // ══════════════════════════════════════════════════════════════════════

    /// @dev B20 precompile token on Base mainnet (code.length == 1, sentinel 0xef)
    address constant B20_TOKEN = 0xb20000000000000000000067580D1a4fb5Ce5297;

    /// @dev Production B20 SuperVault
    address constant B20_VAULT = 0x45Ba4658e2f99158120D344B6978548A55286f23;

    /// @dev SuperVaultAggregator on Base mainnet
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;

    /// @dev Primary manager for the B20 SuperVault strategy
    address constant MAIN_MANAGER = 0x979f2d6371e36bCfef4A20bb85F02e85076c4770;

    /// @dev ApproveAndDeposit4626VaultHook on Base mainnet
    address constant APPROVE_AND_DEPOSIT_4626_HOOK = 0xba687c9D5113a3B2692fd87b0F389dD5fF402808;

    /// @dev Redeem4626VaultHook on Base mainnet
    address constant REDEEM_4626_VAULT_HOOK = 0x95C61fE513885E23Bd7DA1f27B1ad9B16AE29f81;

    /// @dev ERC4626YieldSourceOracle on Base mainnet
    address constant ERC4626_YIELD_SOURCE_ORACLE = 0x2412A5d7261995b49D1F3a731F8452641B916994;

    /// @dev Deposit amount: 1 B20 (18 decimals)
    uint256 constant DEPOSIT_AMOUNT = 1e18;

    // ══════════════════════════════════════════════════════════════════════
    //                             TEST STATE
    // ══════════════════════════════════════════════════════════════════════

    ISuperVault superVault;
    ISuperVaultAggregator aggregator;
    ISuperVaultStrategy strategyContract;
    address escrow;
    Mock4626Vault mock4626;
    address user;

    // ══════════════════════════════════════════════════════════════════════
    //                              SETUP
    // ══════════════════════════════════════════════════════════════════════

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        superVault = ISuperVault(B20_VAULT);
        aggregator = ISuperVaultAggregator(AGGREGATOR);
        strategyContract = ISuperVaultStrategy(IVaultStrategyRef(B20_VAULT).strategy());
        escrow = superVault.escrow();
        user = makeAddr("user");

        // Deploy a fresh ERC-4626 mock vault backed by B20.
        // ERC4626's _tryGetAssetDecimals() is a staticcall that silently falls back to
        // 18 decimals on failure, so the constructor completes even though B20 is a
        // precompile and any call to it reverts inside revm.
        mock4626 = new Mock4626Vault(B20_TOKEN, "Mock B20 Vault", "mvB20");

        _mockB20Calls();
    }

    // ══════════════════════════════════════════════════════════════════════
    //                              TESTS
    // ══════════════════════════════════════════════════════════════════════

    /// @notice Confirm B20 is a precompile with a 1-byte code body.
    function test_Fork_B20_CodeLengthIsOne() public view {
        assertEq(B20_TOKEN.code.length, 1, "B20 should return the 0xef precompile sentinel byte");
    }

    /// @notice Full lifecycle: deposit → deploy-to-yield-source → request-redeem →
    ///         unwind-from-yield-source → fulfill → claim.
    function test_Fork_B20_FullDepositRedeemFlow() public {
        address strategy = address(strategyContract);

        // ─── 1. Register mock4626 as a yield source ───────────────────────────
        vm.prank(MAIN_MANAGER);
        strategyContract.manageYieldSource(
            address(mock4626), ERC4626_YIELD_SOURCE_ORACLE, ISuperVaultStrategy.YieldSourceAction.Add
        );
        assertTrue(strategyContract.containsYieldSource(address(mock4626)), "mock4626 not registered");

        // ─── 2. User deposits B20 into the SuperVault ─────────────────────────
        uint256 vaultShares;
        {
            vm.prank(user);
            vaultShares = superVault.deposit(DEPOSIT_AMOUNT, user);
            assertGt(vaultShares, 0, "vault shares must be > 0");
            assertEq(superVault.balanceOf(user), vaultShares, "user should hold vault shares");
        }

        // ─── 3. Build 2-leaf strategy Merkle tree + activate root ──────────────
        //
        // ApproveAndDeposit4626VaultHook.inspect() → abi.encodePacked(yieldSource, token)
        // Redeem4626VaultHook.inspect()            → abi.encodePacked(yieldSource, owner)
        //   owner = strategy (strategy receives/holds mock4626 shares)
        bytes32 depositLeaf;
        bytes32 redeemLeaf;
        bytes32[] memory depositProof;
        bytes32[] memory redeemProof;
        {
            depositLeaf = _createLeaf(APPROVE_AND_DEPOSIT_4626_HOOK, abi.encodePacked(address(mock4626), B20_TOKEN));
            redeemLeaf = _createLeaf(REDEEM_4626_VAULT_HOOK, abi.encodePacked(address(mock4626), strategy));

            bytes32 root = depositLeaf < redeemLeaf
                ? keccak256(abi.encodePacked(depositLeaf, redeemLeaf))
                : keccak256(abi.encodePacked(redeemLeaf, depositLeaf));

            depositProof = new bytes32[](1);
            depositProof[0] = redeemLeaf;
            redeemProof = new bytes32[](1);
            redeemProof[0] = depositLeaf;

            vm.prank(MAIN_MANAGER);
            aggregator.proposeStrategyHooksRoot(strategy, root);
        }

        vm.warp(block.timestamp + aggregator.getHooksRootUpdateTimelock() + 1);
        aggregator.executeStrategyHooksRootUpdate(strategy);

        // After the warp, mock getLastUpdateTimestamp so _isPPSNotUpdated() does not
        // fire PPS_EXPIRED for any subsequent _validateStrategyState call.
        vm.mockCall(
            address(aggregator),
            abi.encodeCall(ISuperVaultAggregator.getLastUpdateTimestamp, (strategy)),
            abi.encode(block.timestamp)
        );

        // ─── 4. Execute deposit hook: route B20 into mock4626 ─────────────────
        //
        // ApproveAndDeposit4626VaultHook data layout (abi.encodePacked):
        //   bytes32 yieldSourceOracleId  (pos   0) = bytes32(0)
        //   address yieldSource          (pos  32) = mock4626
        //   address token                (pos  52) = B20_TOKEN
        //   uint256 amount               (pos  72) = DEPOSIT_AMOUNT
        //   bool    usePrevHookAmount    (pos 104) = false
        _executeHook(
            strategy,
            APPROVE_AND_DEPOSIT_4626_HOOK,
            abi.encodePacked(bytes32(0), address(mock4626), B20_TOKEN, DEPOSIT_AMOUNT, uint8(0)),
            0, // no minimum output required
            depositProof
        );
        assertEq(mock4626.balanceOf(strategy), DEPOSIT_AMOUNT, "strategy should hold mock4626 shares");

        // ─── 5. User requests redeem ───────────────────────────────────────────
        {
            vm.prank(user);
            superVault.requestRedeem(vaultShares, user, user);
            assertEq(
                strategyContract.pendingRedeemRequest(user), vaultShares, "pending redeem should equal vault shares"
            );
        }

        // ─── 6. Execute redeem hook: unwind mock4626 back to strategy ──────────
        //
        // Redeem4626VaultHook data layout:
        //   bytes32 yieldSourceOracleId  (pos   0) = bytes32(0)
        //   address yieldSource          (pos  32) = mock4626
        //   address owner                (pos  52) = strategy (holder of mock4626 shares)
        //   uint256 shares               (pos  72) = DEPOSIT_AMOUNT (1:1 mint ratio)
        //   bool    usePrevHookAmount    (pos 104) = false
        //
        // outAmount = B20.balanceOf(strategy) post − pre.  Both are mocked to the same
        // constant value so the delta is 0.  expectedOut = 0 bypasses the slippage check.
        _executeHook(
            strategy,
            REDEEM_4626_VAULT_HOOK,
            abi.encodePacked(bytes32(0), address(mock4626), strategy, DEPOSIT_AMOUNT, uint8(0)),
            0, // delta is 0 due to static mock → min must be 0
            redeemProof
        );
        assertEq(mock4626.balanceOf(strategy), 0, "strategy should have no mock4626 shares after unwind");

        // ─── 7. Fulfill redeem requests ────────────────────────────────────────
        uint256 totalAssetsOut;
        {
            uint256 pps = aggregator.getPPS(strategy);
            uint256 precision = IVaultStrategyRef(B20_VAULT).PRECISION();
            totalAssetsOut = vaultShares.mulDiv(pps, precision, Math.Rounding.Floor);
            console2.log("pps:", pps);
            console2.log("precision:", precision);
            console2.log("totalAssetsOut:", totalAssetsOut);

            address[] memory controllers = new address[](1);
            controllers[0] = user;
            uint256[] memory assetsOutArr = new uint256[](1);
            assetsOutArr[0] = totalAssetsOut;

            vm.prank(MAIN_MANAGER);
            strategyContract.fulfillRedeemRequests(controllers, assetsOutArr);
        }
        assertEq(strategyContract.claimableWithdraw(user), totalAssetsOut, "claimable should equal totalAssetsOut");

        // ─── 8. User claims the redeemed assets ───────────────────────────────
        {
            uint256 redeemableShares = superVault.maxRedeem(user);
            assertGt(redeemableShares, 0, "user should have redeemable shares");

            vm.prank(user);
            superVault.redeem(redeemableShares, user, user);
        }
        assertEq(strategyContract.claimableWithdraw(user), 0, "claimable should be 0 after claim");
        console2.log("B20 SuperVault fork test: full deposit-redeem flow passed");
    }

    // ══════════════════════════════════════════════════════════════════════
    //                          HELPERS
    // ══════════════════════════════════════════════════════════════════════

    /// @dev Mock all B20 ERC-20 calls.
    ///      B20 is a Base precompile (sentinel byte 0xef). Foundry's revm cannot
    ///      execute precompile logic; any raw call to B20_TOKEN would revert.
    ///      Broad selector mocks intercept every transfer/approve call before EVM
    ///      execution, returning pre-programmed safe values.
    function _mockB20Calls() internal {
        address strategy = IVaultStrategyRef(B20_VAULT).strategy();

        // Any transfer on B20 succeeds (covers fulfillRedeemRequests→escrow and escrow→user)
        vm.mockCall(B20_TOKEN, abi.encodeWithSelector(IERC20.transfer.selector), abi.encode(true));
        // Any transferFrom on B20 succeeds (covers vault.deposit() and mock4626.deposit())
        vm.mockCall(B20_TOKEN, abi.encodeWithSelector(IERC20.transferFrom.selector), abi.encode(true));
        // Any approve on B20 succeeds (ApproveAndDeposit hook issues 4 approve calls)
        vm.mockCall(B20_TOKEN, abi.encodeWithSelector(IERC20.approve.selector), abi.encode(true));

        // strategy: large balance so:
        //   - fulfillRedeemRequests balance check (strategyBalance >= totalAssetsOut) passes
        //   - Redeem4626VaultHook _preExecute/_postExecute delta == 0 (same value before & after)
        vm.mockCall(B20_TOKEN, abi.encodeCall(IERC20.balanceOf, (strategy)), abi.encode(type(uint256).max / 2));

        // escrow: large balance so SuperVault.redeem() escrow balance check passes
        vm.mockCall(B20_TOKEN, abi.encodeCall(IERC20.balanceOf, (escrow)), abi.encode(type(uint256).max / 2));

        // user: simulate holding DEPOSIT_AMOUNT of B20
        vm.mockCall(B20_TOKEN, abi.encodeCall(IERC20.balanceOf, (user)), abi.encode(DEPOSIT_AMOUNT));
    }

    /// @dev Compute the OZ-compatible leaf hash used by SuperVaultAggregator._createLeaf():
    ///      leaf = keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))))
    function _createLeaf(address hookAddress, bytes memory hookArgs) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
    }

    /// @dev Execute a single hook through strategy.executeHooks().
    ///      globalProof is always empty so the validator falls through to strategyProof.
    function _executeHook(
        address strategy,
        address hook,
        bytes memory hookCalldata,
        uint256 expectedOut,
        bytes32[] memory strategyProof
    )
        internal
    {
        address[] memory hooks = new address[](1);
        hooks[0] = hook;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = hookCalldata;

        uint256[] memory expected = new uint256[](1);
        expected[0] = expectedOut;

        bytes32[][] memory globalProofs = new bytes32[][](1);
        globalProofs[0] = new bytes32[](0); // empty → strategy root path

        bytes32[][] memory strategyProofs = new bytes32[][](1);
        strategyProofs[0] = strategyProof;

        vm.prank(MAIN_MANAGER);
        ISuperVaultStrategy(strategy).executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooks,
                hookCalldata: calldatas,
                expectedAssetsOrSharesOut: expected,
                globalProofs: globalProofs,
                strategyProofs: strategyProofs
            })
        );
    }
}
