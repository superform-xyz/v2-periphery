// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { SuperGovernor } from "../../src/SuperGovernor.sol";

/// @title ProposeSuperBankRootsRH
/// @notice ONE-OFF script: registers the SuperBank hooks and proposes their production merkle
///         roots on Robinhood Chain (4663). DELETE THIS FILE AFTER EXECUTION.
/// @dev Roots source: superman/deployments/superbank/generated/prod/4663/trees_summary.json
///      (also listed in superman/deployments/superbank/roots_to_propose.md, generated 2026-08-07).
///      Covers: USDG->USDC KyberSwap swap leaves, approve leaves (KyberSwap router + RH SpokePool
///      spenders) and the USDG/USDC(RH) -> USDC(Base) Across bridge routes.
///
///      Idempotent: skips hooks already registered, and skips proposals whose target root is
///      already active or already pending (so re-running never resets the 7-day timelock).
///
/// Run (requires GOVERNOR_ROLE, held by the v2-supervaults keystore account on RH):
///   source .env && FOUNDRY_TEST=test/integration/SuperBank forge script \
///     script/ProposeSuperBankRootsRH.s.sol \
///     --rpc-url "$RH_RPC_URL" \
///     --account v2-supervaults \
///     --skip "*RevenueDistribution*" \
///     --broadcast
///   (FOUNDRY_TEST + --skip work around test files on this branch that are stale vs the
///    bumped v2-core submodule and would otherwise fail compilation.)
///
/// After the 7-day timelock, execution is permissionless (any sender), e.g. via the v2-toolbox
/// `execute_superbank_hook_merkle_root` script per hook.
contract ProposeSuperBankRootsRH is Script {
    uint256 internal constant RH_CHAIN_ID = 4663;

    /// @notice Production SuperGovernor on RH
    address internal constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    function run() external {
        require(block.chainid == RH_CHAIN_ID, "RH_ONLY");

        address[5] memory hooks = [
            0x1851A98471ADE4a115B6FB7bd42934a200e58d9E, // ApproveERC20Hook
            0x05c49e05bb8575afdf1142cC95dA6747b069174A, // SwapKyberSwapHook
            0xcF5419270C9415E44c97E595c505708cfA334C30, // ApproveAndSwapKyberSwapHook
            0xf2D69C07B4729A2Af541C3387edaa9FA2DF9650b, // AcrossSendFundsAndExecuteOnDstHook
            0x91C5bf1B80465c7E86EB624d5DC84c75201afdAC // ApproveAndAcrossSendFundsAndExecuteOnDstHook
        ];
        bytes32[5] memory roots = [
            bytes32(0xe5a5e0e36de2a491600dfd9cfffe8f13403e69c5c83ab71f4630d8413436da47), // ApproveERC20Hook
            bytes32(0x70e3cd5a5e8ba0f9d36a829ffc78949f9e746f44da88d4260801e54cac23a9e1), // SwapKyberSwapHook
            bytes32(0x98eeb4c2db7afc6f5182e3e106bfa37128bcefd35c1af2462c445fde3db5c100), // ApproveAndSwapKyberSwap
            bytes32(0x2ef0b21142f2dca2cf6b7a1f42e028831d56d840118812b52f9d693e4e565ec9), // AcrossSendFunds
            bytes32(0x08a09ead8683e513410503091d25a8e819070f03a7c16f0965762a9a68df03a9) // ApproveAndAcross
        ];
        string[5] memory names = [
            "ApproveERC20Hook",
            "SwapKyberSwapHook",
            "ApproveAndSwapKyberSwapHook",
            "AcrossSendFundsAndExecuteOnDstHook",
            "ApproveAndAcrossSendFundsAndExecuteOnDstHook"
        ];

        SuperGovernor governor = SuperGovernor(SUPER_GOVERNOR);

        console2.log("=== SuperBank merkle root proposals on RH (4663) ===");
        console2.log("SuperGovernor:", SUPER_GOVERNOR);

        vm.startBroadcast();

        for (uint256 i = 0; i < hooks.length; i++) {
            console2.log("");
            console2.log(names[i], hooks[i]);

            if (!governor.isHookRegistered(hooks[i])) {
                governor.registerHook(hooks[i]);
                console2.log("  registered");
            } else {
                console2.log("  already registered");
            }

            if (governor.getSuperBankHookMerkleRoot(hooks[i]) == roots[i]) {
                console2.log("  root already active - skipping");
                continue;
            }

            (bytes32 pendingRoot, uint256 effectiveTime) = governor.getProposedSuperBankHookMerkleRoot(hooks[i]);
            if (pendingRoot == roots[i]) {
                console2.log("  root already proposed, effective at:", effectiveTime);
                continue;
            }

            governor.proposeSuperBankHookMerkleRoot(hooks[i], roots[i]);
            console2.log("  proposed root:");
            console2.logBytes32(roots[i]);
        }

        vm.stopBroadcast();

        console2.log("");
        console2.log("Done. Execute each root after the 7-day timelock (permissionless):");
        console2.log("  governor.executeSuperBankHookMerkleRootUpdate(hook)");
    }
}
