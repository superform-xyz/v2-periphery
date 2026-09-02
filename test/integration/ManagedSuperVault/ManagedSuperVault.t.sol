// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../../utils/ManagedSuperVaultTestBase.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import {
    IManagedSuperVaultAggregator
} from "../../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import {
    IManagedSuperVaultDepositQueue
} from "../../../src/interfaces/ManagedSuperVault/IManagedSuperVaultDepositQueue.sol";
import { MockSuperHook } from "../../mocks/MockSuperHook.sol";
import { MockHookTarget } from "../../mocks/MockHookTarget.sol";

/// @notice Full-lifecycle integration tests for the Managed SuperVault family (fork-based reuse
///         architecture): async deposits through the queue, attested-NAV pricing, performance fee
///         skims, native async redeems, and hook execution through the REUSED Merkle machinery.
contract ManagedSuperVaultIntegrationTest is ManagedSuperVaultTestBase {
    uint256 internal constant WAD = 1e18;

    // Mirrors MockHookTarget.Executed for expectEmit
    event Executed();
    // Mirrors ISuperVaultStrategy.HooksExecuted for expectEmit
    event HooksExecuted(address[] hooks);

    /*//////////////////////////////////////////////////////////////
                        END-TO-END LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    // Expected E2E figures for a 100e18 deposit, +10% NAV, 10% perf fee, 50% protocol fee share
    uint256 internal constant E2E_DEPOSIT = 100e18;
    uint256 internal constant E2E_YIELD = 10e18; // 10% on principal
    uint256 internal constant E2E_FEE = 1e18; // 10% perf fee on 10e18 profit above HWM 1.0
    uint256 internal constant E2E_SF_FEE = 0.5e18; // 50% protocol share -> treasury
    uint256 internal constant E2E_POST_SKIM_PPS = 1.09e18; // 1.10 - fee/totalSupply

    /// @notice request deposit -> fulfill -> claim native shares -> NAV 1.1 -> skim 10% perf fee
    ///         -> requestRedeem -> fulfillRedeemRequests -> withdraw. End-user P&L must equal the
    ///         PPS path net of fees, and every fee leg must land where it belongs.
    function test_EndToEnd_DepositNavSkimRedeemLifecycle() public {
        uint256 userAssetsBefore = asset.balanceOf(user);

        uint256 shares = _e2eDepositLeg(); // steps 1-3
        _e2eNavAndSkimLeg(shares); // steps 4-5
        uint256 assetsOut = _e2eRedeemLeg(shares); // steps 6-8

        // End-user P&L consistent with the PPS path and fees:
        // gain = yield - perf fee = 10e18 - 1e18 = 9e18
        uint256 userGain = asset.balanceOf(user) - userAssetsBefore;
        assertEq(userGain, E2E_YIELD - E2E_FEE, "user nets yield - fee");
        assertEq(userGain, assetsOut - E2E_DEPOSIT, "P&L = pps path");

        // Full conservation: yield split exactly between user and the two fee recipients
        assertEq(userGain + E2E_FEE, E2E_YIELD, "value conservation");
        assertEq(asset.balanceOf(address(strategy)), 0, "strategy drained");
        assertEq(asset.balanceOf(address(escrow)), 0, "escrow drained");
    }

    /// @dev Steps 1-3: request on the queue -> manager fulfill -> claim NATIVE vault shares
    function _e2eDepositLeg() internal returns (uint256 shares) {
        // 1. User requests a deposit on the queue (assets held in queue custody)
        vm.startPrank(user);
        asset.approve(address(queue), E2E_DEPOSIT);
        queue.requestDeposit(E2E_DEPOSIT, user, user);
        vm.stopPrank();
        assertEq(asset.balanceOf(address(queue)), E2E_DEPOSIT, "queue holds pending assets");
        assertEq(queue.pendingDepositRequest(0, user), E2E_DEPOSIT, "pending recorded");

        // 2. Manager fulfills: queue -> vault.deposit -> assets land in the strategy,
        //    net shares pre-minted to the queue
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        queue.fulfillDepositRequests(depositors);
        assertEq(asset.balanceOf(address(strategy)), E2E_DEPOSIT, "deposits sit in the strategy");
        assertEq(queue.claimableDepositRequest(0, user), E2E_DEPOSIT, "claimable (no entry fee)");

        // 3. User claims NATIVE vault shares (pps 1.0, no management fee => 1:1)
        vm.prank(user);
        shares = queue.deposit(E2E_DEPOSIT, user, user);
        assertEq(shares, E2E_DEPOSIT, "shares = floor(assets * 1e18 / pps)");
        assertEq(vault.balanceOf(user), shares, "user holds native vault shares");
        assertEq(vault.balanceOf(address(queue)), 0, "queue fully drained of shares");
    }

    /// @dev Steps 4-5: attested NAV to 1.1 (yield realized into the strategy) + perf fee skim
    function _e2eNavAndSkimLeg(uint256 shares) internal {
        // 4. NAV moves to 1.1: realize the yield into the strategy so the attested NAV is backed,
        //    then push through propose/attest on the NAV oracle
        asset.mint(address(strategy), E2E_YIELD);
        _pushNAV(1.1e18);
        assertEq(strategy.getStoredPPS(), 1.1e18, "attested NAV stored");

        // 5. Manager skims the performance fee (10% of profit above HWM 1e18).
        //    POST_UNPAUSE_SKIM_TIMELOCK is 12h from lastUnpause (0 here); base warped to 30 days.
        uint256 treasuryBefore = asset.balanceOf(treasury);
        uint256 feeRecipientBefore = asset.balanceOf(feeRecipient);

        vm.prank(manager);
        strategy.skimPerformanceFee();

        assertEq(asset.balanceOf(treasury) - treasuryBefore, E2E_SF_FEE, "treasury fee share");
        assertEq(asset.balanceOf(feeRecipient) - feeRecipientBefore, E2E_FEE - E2E_SF_FEE, "manager fee share");
        assertEq(strategy.getStoredPPS(), E2E_POST_SKIM_PPS, "PPS reduced by fee extraction");
        assertEq(strategy.getStoredPPS(), 1.1e18 - (E2E_FEE * WAD / shares), "fee/supply reduction");
        assertEq(strategy.vaultHwmPps(), E2E_POST_SKIM_PPS, "HWM ratchets to post-fee PPS");
    }

    /// @dev Steps 6-8: native async redeem round trip at the post-skim PPS
    function _e2eRedeemLeg(uint256 shares) internal returns (uint256 assetsOut) {
        // 6. User requests redemption of all shares through the NATIVE vault redeem leg
        vm.prank(user);
        vault.requestRedeem(shares, user, user);
        assertEq(vault.balanceOf(address(escrow)), shares, "shares locked in escrow");

        // 7. Manager fulfills at the stored PPS: amounts = shares * pps / 1e18
        uint256 theoreticalAssets = shares * E2E_POST_SKIM_PPS / WAD; // 109e18
        assertEq(
            asset.balanceOf(address(strategy)),
            E2E_DEPOSIT + E2E_YIELD - E2E_FEE,
            "strategy exactly solvent for the full redemption"
        );

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = theoreticalAssets;
        vm.prank(manager);
        strategy.fulfillRedeemRequests(controllers, amounts);
        assertEq(vault.totalSupply(), 0, "all shares burned at fulfillment");

        // 8. User withdraws the fulfilled assets
        assertEq(vault.maxWithdraw(user), theoreticalAssets, "claimable assets at fulfillment price");
        assetsOut = _withdrawAll(user);
        assertEq(assetsOut, theoreticalAssets, "paid the theoretical amount");
    }

    /// @notice Two users deposit different amounts, NAV moves, both redeem everything:
    ///         payouts stay exactly proportional to deposits.
    function test_MultiUser_ProportionalRedemption() public {
        uint256 depositA = 100e18;
        uint256 depositB = 250e18;

        uint256 sharesA = _requestFulfillClaim(user, depositA);
        uint256 sharesB = _requestFulfillClaim(user2, depositB);
        assertEq(sharesA, depositA, "1:1 at pps 1.0");
        assertEq(sharesB, depositB, "1:1 at pps 1.0");

        // NAV up 20%, backed by realized yield in the strategy
        uint256 newPPS = 1.2e18;
        asset.mint(address(strategy), (depositA + depositB) * 20 / 100);
        _pushNAV(newPPS);

        // Both request full redemption
        vm.prank(user);
        vault.requestRedeem(sharesA, user, user);
        vm.prank(user2);
        vault.requestRedeem(sharesB, user2, user2);

        // Manager fulfills both in one sorted batch at the shared PPS
        _fulfillBatchAtPPS(newPPS);

        uint256 outA = _withdrawAll(user);
        uint256 outB = _withdrawAll(user2);

        // Exact per-user pricing at the shared PPS
        assertEq(outA, depositA * newPPS / WAD, "A paid at pps");
        assertEq(outB, depositB * newPPS / WAD, "B paid at pps");

        // Proportionality: outA / outB == depositA / depositB
        assertEq(outA * depositB, outB * depositA, "payouts proportional to deposits");

        assertEq(vault.totalSupply(), 0, "everything redeemed");
    }

    /// @dev Fulfills user and user2's pending redeem requests in one sorted batch, paying each
    ///      the theoretical shares * pps / 1e18 (fulfillRedeemRequests requires sorted, unique
    ///      controllers)
    function _fulfillBatchAtPPS(uint256 pps) internal {
        (address lo, address hi) = user < user2 ? (user, user2) : (user2, user);
        address[] memory controllers = new address[](2);
        controllers[0] = lo;
        controllers[1] = hi;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = strategy.pendingRedeemRequest(lo) * pps / WAD;
        amounts[1] = strategy.pendingRedeemRequest(hi) * pps / WAD;
        vm.prank(manager);
        strategy.fulfillRedeemRequests(controllers, amounts);
    }

    /// @dev Withdraws the full claimable balance for `who` and returns the assets received
    function _withdrawAll(address who) internal returns (uint256 assetsOut) {
        uint256 balBefore = asset.balanceOf(who);
        uint256 maxW = vault.maxWithdraw(who);
        vm.prank(who);
        vault.withdraw(maxW, who, who);
        assetsOut = asset.balanceOf(who) - balBefore;
        assertEq(assetsOut, maxW, "withdraw pays exactly maxWithdraw");
    }

    /*//////////////////////////////////////////////////////////////
                HOOK EXECUTION THROUGH REUSED MERKLE MACHINERY
    //////////////////////////////////////////////////////////////*/

    /// @notice Proves the execution-reuse decision end to end: register a hook on SuperGovernor,
    ///         install a STRATEGY hooks root through the managed aggregator's timelocked
    ///         propose/execute flow (single-leaf tree: root == leaf, empty proof), then drive
    ///         strategy.executeHooks full-depth so the hook's built executions actually run.
    function test_HookExecution_ThroughReusedMerkleMachinery() public {
        MockHookTarget target = new MockHookTarget();
        MockSuperHook hook = new MockSuperHook(address(target));

        // 1. Register the hook on SuperGovernor (GOVERNOR_ROLE)
        vm.prank(governor);
        superGovernor.registerHook(address(hook));
        assertTrue(superGovernor.isHookRegistered(address(hook)));

        // 2-3. Install a single-leaf STRATEGY hooks root through the timelocked manager flow.
        //      hookArgs = ISuperHookInspector(hook).inspect(hookCalldata), exactly as the strategy
        //      derives them at execution time.
        bytes memory hookCalldata = abi.encodePacked(bytes32(0), address(target)); // oracleId + yieldSource
        bytes memory hookArgs = hook.inspect(hookCalldata);
        _installSingleLeafStrategyRoot(address(hook), hookArgs);

        // 4. Single-leaf tree: empty proof is valid when root == leaf (_validateSingleHook);
        //    a foreign args payload does not validate
        assertTrue(_validateHook(address(hook), hookArgs), "leaf validates against installed strategy root");
        assertFalse(_validateHook(address(hook), abi.encodePacked(address(0xdead))), "foreign args rejected");

        // 5. Full-depth execution: strategy validates the hook against the Merkle root and runs
        //    its built executions (preExecute -> target.execute() -> postExecute)
        address[] memory hooks = new address[](1);
        hooks[0] = address(hook);

        vm.expectEmit(true, true, true, true, address(target));
        emit Executed();
        vm.expectEmit(true, true, true, true, address(strategy));
        emit HooksExecuted(hooks);

        vm.prank(manager);
        strategy.executeHooks(_singleHookExecuteArgs(address(hook), hookCalldata));
    }

    /// @dev Builds the leaf exactly as the aggregator does —
    ///      keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs)))) — proposes it as
    ///      the STRATEGY hooks root (MANAGER-gated), warps past the 15-min timelock, and executes
    function _installSingleLeafStrategyRoot(address hook, bytes memory hookArgs) internal {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));

        vm.prank(manager);
        aggregator.proposeStrategyHooksRoot(address(strategy), leaf);
        (bytes32 proposedRoot,) = aggregator.getProposedStrategyHooksRoot(address(strategy));
        assertEq(proposedRoot, leaf);

        vm.warp(block.timestamp + aggregator.getHooksRootUpdateTimelock() + 1);
        aggregator.executeStrategyHooksRootUpdate(address(strategy));
        assertEq(aggregator.getStrategyHooksRoot(address(strategy)), leaf, "root installed");
    }

    function _validateHook(address hook, bytes memory hookArgs) internal view returns (bool) {
        return aggregator.validateHook(
            address(strategy),
            IManagedSuperVaultAggregator.ValidateHookArgs({
                hookAddress: hook,
                hookArgs: hookArgs,
                globalProof: new bytes32[](0),
                strategyProof: new bytes32[](0)
            })
        );
    }

    function _singleHookExecuteArgs(
        address hook,
        bytes memory hookCalldata
    )
        internal
        pure
        returns (ISuperVaultStrategy.ExecuteArgs memory args)
    {
        args.hooks = new address[](1);
        args.hooks[0] = hook;
        args.hookCalldata = new bytes[](1);
        args.hookCalldata[0] = hookCalldata;
        args.expectedAssetsOrSharesOut = new uint256[](1);
        args.globalProofs = new bytes32[][](1);
        args.globalProofs[0] = new bytes32[](0);
        args.strategyProofs = new bytes32[][](1);
        args.strategyProofs[0] = new bytes32[](0);
    }

    /*//////////////////////////////////////////////////////////////
                        NAV STALENESS LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /// @notice Once the stored PPS ages past ppsExpiration (1 day default) with no NAV updates,
    ///         the queue stops accepting deposit requests; a fresh attested NAV restores service.
    function test_NAVStalenessLifecycle() public {
        assertEq(strategy.ppsExpiration(), 1 days, "default expiration");

        // Fresh vault accepts requests
        vm.startPrank(user);
        asset.approve(address(queue), 2e18);
        queue.requestDeposit(1e18, user, user);
        vm.stopPrank();

        // Warp past ppsExpiration without any NAV updates
        vm.warp(block.timestamp + 1 days + 1);

        vm.prank(user);
        vm.expectRevert(IManagedSuperVaultDepositQueue.VAULT_NOT_ACCEPTING_DEPOSITS.selector);
        queue.requestDeposit(1e18, user, user);

        // Fulfilling the earlier request is also blocked while expired (vault-side PPS_EXPIRED)
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        vm.expectRevert(ISuperVaultStrategy.PPS_EXPIRED.selector);
        queue.fulfillDepositRequests(depositors);

        // A fresh attested NAV restores deposits
        _pushNAV(1e18);

        vm.prank(user);
        queue.requestDeposit(1e18, user, user);
        assertEq(queue.pendingDepositRequest(0, user), 2e18, "requests accepted again");

        // And the full round trip works once more
        vm.prank(manager);
        queue.fulfillDepositRequests(depositors);
        vm.prank(user);
        uint256 shares = queue.deposit(2e18, user, user);
        assertEq(shares, 2e18, "claimed at pps 1.0");
    }
}
