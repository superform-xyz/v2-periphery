// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";

import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { SuperVaultYieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/SuperVaultYieldSourceOracle.sol";
import { Mock4626Vault } from "../../mocks/Mock4626Vault.sol";

/// @title SuperVaultOfSuperVaults
/// @notice Integration test: A SuperVault (SuperAI) whose yield sources are 3 other SuperVaults
///         (SuperTSLA, SuperSPCX, SuperNVDA). Each underlying SuperVault holds USDC as its asset
///         and uses a Mock4626 as its yield source. The key question is whether SuperAI can
///         correctly handle the fact that depositing into the underlying SuperVaults returns
///         *shares* (not USDC) back to SuperAI's strategy.
contract SuperVaultOfSuperVaults is BaseSuperVaultTest {
    using Math for uint256;

    // --- Underlying Mock4626 vaults (the "real" yield sources) ---
    Mock4626Vault public mockTSLA;
    Mock4626Vault public mockSPCX;
    Mock4626Vault public mockNVDA;

    // --- Layer-1 SuperVaults (asset = USDC, yield source = Mock4626) ---
    SuperVault public svTSLA;
    SuperVaultStrategy public stratTSLA;

    SuperVault public svSPCX;
    SuperVaultStrategy public stratSPCX;

    SuperVault public svNVDA;
    SuperVaultStrategy public stratNVDA;

    // --- Layer-2 SuperVault (asset = USDC, yield sources = the 3 SuperVaults above) ---
    SuperVault public svAI;
    SuperVaultStrategy public stratAI;

    // --- SuperVault-specific oracle (handles async redeem correctly) ---
    SuperVaultYieldSourceOracle public svOracle;

    /// @dev Struct to avoid stack-too-deep in helper functions
    struct ThreeVaultHookVars {
        address hookAddress;
        bytes32 oracleId;
        address[] hooks;
        bytes[] hookData;
        uint256[] expectedOut;
        bytes[] argsForProofs;
    }

    function setUp() public override {
        super.setUp();

        // Deploy 3 Mock4626 vaults as the "real" yield sources
        mockTSLA = new Mock4626Vault(address(asset), "Mock TSLA Yield", "mTSLA");
        mockSPCX = new Mock4626Vault(address(asset), "Mock SPCX Yield", "mSPCX");
        mockNVDA = new Mock4626Vault(address(asset), "Mock NVDA Yield", "mNVDA");

        vm.label(address(mockTSLA), "MockTSLA");
        vm.label(address(mockSPCX), "MockSPCX");
        vm.label(address(mockNVDA), "MockNVDA");

        // Deploy the 3 layer-1 SuperVaults
        _deployLayer1Vaults();

        // Register Mock4626 vaults as yield sources for each layer-1 SuperVault
        _registerMockYieldSources();

        // Deploy the SuperVault-specific yield source oracle
        svOracle = new SuperVaultYieldSourceOracle(_getContract(ETH, SUPER_LEDGER_CONFIGURATION_KEY));

        // Update PPS for each layer-1 SuperVault (initial PPS = 1.0)
        _updateSuperVaultPPS(address(stratTSLA), address(svTSLA));
        _updateSuperVaultPPS(address(stratSPCX), address(svSPCX));
        _updateSuperVaultPPS(address(stratNVDA), address(svNVDA));

        // Deploy the layer-2 SuperVault (SuperAI)
        _deployLayer2Vault();

        // Set up strategy-specific hooks root for stratAI so it can deposit/redeem
        // into the 3 underlying SuperVaults
        _setupStrategyHooksRoot();

        // Update PPS for SuperAI
        _updateSuperVaultPPS(address(stratAI), address(svAI));
    }

    function _deployLayer1Vaults() internal {
        (address v, address s,) = _deployVault(address(asset), "SV_TSLA");
        svTSLA = SuperVault(v);
        stratTSLA = SuperVaultStrategy(payable(s));

        (v, s,) = _deployVault(address(asset), "SV_SPCX");
        svSPCX = SuperVault(v);
        stratSPCX = SuperVaultStrategy(payable(s));

        (v, s,) = _deployVault(address(asset), "SV_NVDA");
        svNVDA = SuperVault(v);
        stratNVDA = SuperVaultStrategy(payable(s));
    }

    function _registerMockYieldSources() internal {
        address erc4626Oracle = _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY);

        vm.startPrank(MANAGER);
        stratTSLA.manageYieldSource(address(mockTSLA), erc4626Oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        stratSPCX.manageYieldSource(address(mockSPCX), erc4626Oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        stratNVDA.manageYieldSource(address(mockNVDA), erc4626Oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        vm.stopPrank();
    }

    function _deployLayer2Vault() internal {
        (address v, address s,) = _deployVault(address(asset), "SV_AI");
        svAI = SuperVault(v);
        stratAI = SuperVaultStrategy(payable(s));

        // Register the 3 layer-1 SuperVaults as yield sources for SuperAI
        // using the SuperVaultYieldSourceOracle (handles async redeem correctly)
        vm.startPrank(MANAGER);
        stratAI.manageYieldSource(address(svTSLA), address(svOracle), ISuperVaultStrategy.YieldSourceAction.Add);
        stratAI.manageYieldSource(address(svSPCX), address(svOracle), ISuperVaultStrategy.YieldSourceAction.Add);
        stratAI.manageYieldSource(address(svNVDA), address(svOracle), ISuperVaultStrategy.YieldSourceAction.Add);
        vm.stopPrank();
    }

    /// @notice Build a merkle tree for strategy-specific hooks root covering deposit/redeem
    ///         into/from the 3 underlying SuperVaults
    function _setupStrategyHooksRoot() internal {
        (, bytes32 root) = _buildStrategyTree();

        // Set the strategy hooks root for stratAI
        vm.startPrank(MANAGER);
        aggregator.proposeStrategyHooksRoot(address(stratAI), root);
        vm.stopPrank();

        vm.warp(block.timestamp + 20 minutes);
        aggregator.executeStrategyHooksRootUpdate(address(stratAI));
    }

    /// @dev Create a leaf matching SuperVaultAggregator._createLeaf()
    function _createLeaf(address hookAddress, bytes memory hookArgs) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(hookAddress, hookArgs))));
    }

    /// @dev Sort bytes32 array in ascending order
    function _sortBytes32(bytes32[] memory arr) internal pure {
        uint256 n = arr.length;
        for (uint256 i = 0; i < n; i++) {
            for (uint256 j = i + 1; j < n; j++) {
                if (arr[i] > arr[j]) {
                    (arr[i], arr[j]) = (arr[j], arr[i]);
                }
            }
        }
    }

    /// @dev Compute merkle root from sorted leaves (power-of-2 length)
    function _computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint256 n = leaves.length;
        while (n > 1) {
            for (uint256 i = 0; i < n / 2; i++) {
                bytes32 left = leaves[2 * i];
                bytes32 right = leaves[2 * i + 1];
                // OZ StandardMerkleTree uses commutative hash (sorted pair)
                if (left <= right) {
                    leaves[i] = keccak256(abi.encodePacked(left, right));
                } else {
                    leaves[i] = keccak256(abi.encodePacked(right, left));
                }
            }
            n = n / 2;
        }
        return leaves[0];
    }

    /// @dev Compute merkle proof for a specific leaf from sorted leaves (power-of-2 length)
    function _computeMerkleProof(bytes32[] memory leaves, uint256 leafIndex) internal pure returns (bytes32[] memory) {
        uint256 n = leaves.length;
        uint256 depth = 0;
        uint256 temp = n;
        while (temp > 1) {
            depth++;
            temp /= 2;
        }

        bytes32[] memory proof = new bytes32[](depth);
        uint256 proofIndex = 0;
        uint256 currentIndex = leafIndex;

        // Make a copy of leaves to avoid modifying original
        bytes32[] memory tree = new bytes32[](n);
        for (uint256 i = 0; i < n; i++) {
            tree[i] = leaves[i];
        }

        uint256 currentN = n;
        while (currentN > 1) {
            // Get sibling
            uint256 siblingIndex = currentIndex % 2 == 0 ? currentIndex + 1 : currentIndex - 1;
            proof[proofIndex] = tree[siblingIndex];
            proofIndex++;

            // Compute next level
            for (uint256 i = 0; i < currentN / 2; i++) {
                bytes32 left = tree[2 * i];
                bytes32 right = tree[2 * i + 1];
                if (left <= right) {
                    tree[i] = keccak256(abi.encodePacked(left, right));
                } else {
                    tree[i] = keccak256(abi.encodePacked(right, left));
                }
            }

            currentIndex /= 2;
            currentN /= 2;
        }

        return proof;
    }

    /// @dev Build sorted leaves array for the strategy tree and compute proofs
    function _buildStrategyTree()
        internal
        view
        returns (bytes32[] memory sortedLeaves, bytes32 root)
    {
        address depositHook = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        address redeemHook = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        sortedLeaves = new bytes32[](8);
        sortedLeaves[0] = _createLeaf(depositHook, abi.encodePacked(address(svTSLA), address(asset)));
        sortedLeaves[1] = _createLeaf(depositHook, abi.encodePacked(address(svSPCX), address(asset)));
        sortedLeaves[2] = _createLeaf(depositHook, abi.encodePacked(address(svNVDA), address(asset)));
        sortedLeaves[3] = _createLeaf(redeemHook, abi.encodePacked(address(svTSLA), address(stratAI)));
        sortedLeaves[4] = _createLeaf(redeemHook, abi.encodePacked(address(svSPCX), address(stratAI)));
        sortedLeaves[5] = _createLeaf(redeemHook, abi.encodePacked(address(svNVDA), address(stratAI)));
        sortedLeaves[6] = bytes32(0);
        sortedLeaves[7] = bytes32(0);

        _sortBytes32(sortedLeaves);

        // Compute root on a COPY so sortedLeaves is preserved for proof generation
        bytes32[] memory leavesCopy = new bytes32[](8);
        for (uint256 i = 0; i < 8; i++) {
            leavesCopy[i] = sortedLeaves[i];
        }
        root = _computeMerkleRoot(leavesCopy);
    }

    /// @dev Get strategy proof for a specific hook+args combination
    function _getStrategyProof(
        address hookAddress,
        bytes memory hookArgs
    )
        internal
        view
        returns (bytes32[] memory proof)
    {
        (bytes32[] memory sortedLeaves,) = _buildStrategyTree();
        bytes32 targetLeaf = _createLeaf(hookAddress, hookArgs);

        // Find the leaf index
        for (uint256 i = 0; i < sortedLeaves.length; i++) {
            if (sortedLeaves[i] == targetLeaf) {
                return _computeMerkleProof(sortedLeaves, i);
            }
        }
        revert("Leaf not found in strategy tree");
    }

    /*//////////////////////////////////////////////////////////////
                            TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that a user can deposit USDC into SuperAI, and that the manager
    ///         can allocate those free assets into the underlying SuperVaults.
    function test_SuperVaultOfSuperVaults_DepositAndAllocate() public {
        uint256 depositAmount = 3000e6; // 3000 USDC

        // Fund the user and deposit into SuperAI
        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, address(svAI), address(asset));

        // Verify: user got SuperAI shares
        assertGt(svAI.balanceOf(accountEth), 0, "No SuperAI shares minted");

        // Verify: USDC is sitting as free assets in stratAI
        assertEq(asset.balanceOf(address(stratAI)), depositAmount, "Wrong free assets in stratAI");

        // Now allocate ~1000 USDC to each underlying SuperVault via hooks
        uint256 perVault = depositAmount / 3;
        _allocateToThreeVaults(
            address(stratAI), perVault, perVault, depositAmount - 2 * perVault,
            address(svTSLA), address(svSPCX), address(svNVDA)
        );

        // Verify: stratAI now holds *shares* of each underlying SuperVault (not USDC)
        assertGt(svTSLA.balanceOf(address(stratAI)), 0, "No svTSLA shares");
        assertGt(svSPCX.balanceOf(address(stratAI)), 0, "No svSPCX shares");
        assertGt(svNVDA.balanceOf(address(stratAI)), 0, "No svNVDA shares");

        // Verify: stratAI should have zero free USDC left
        assertEq(asset.balanceOf(address(stratAI)), 0, "stratAI should have zero free USDC");

        // Verify: totalAssets of SuperAI should still be ~3000 USDC
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));
        console2.log("SuperAI totalAssets:", totalAssetsAI);
        assertApproxEqAbs(totalAssetsAI, depositAmount, 1e6, "totalAssets mismatch after allocation");
    }

    /// @notice Test the full lifecycle: deposit -> allocate -> request redeem -> fulfill -> claim
    function test_SuperVaultOfSuperVaults_FullLifecycle() public {
        uint256 depositAmount = 3000e6; // 3000 USDC
        uint256 perVault = depositAmount / 3;

        // --- STEP 1: Deposit ---
        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, address(svAI), address(asset));
        assertGt(svAI.balanceOf(accountEth), 0, "No SuperAI shares minted");

        // --- STEP 2: Allocate to underlying SuperVaults ---
        _allocateToThreeVaults(
            address(stratAI), perVault, perVault, depositAmount - 2 * perVault,
            address(svTSLA), address(svSPCX), address(svNVDA)
        );

        // Update PPS after allocation
        vm.warp(block.timestamp + 10);
        _updateSuperVaultPPS(address(stratAI), address(svAI));

        // --- STEP 3: Request redeem all shares ---
        _requestRedeem(svAI.balanceOf(accountEth), address(svAI));

        // --- STEP 4: Withdraw from underlying SuperVaults and fulfill ---
        _redeemFromThreeVaultsAndFulfill(address(stratAI), address(svTSLA), address(svSPCX), address(svNVDA));

        // --- STEP 5: Claim via withdraw ---
        uint256 claimable = svAI.maxWithdraw(accountEth);
        console2.log("Claimable assets:", claimable);
        assertGt(claimable, 0, "Nothing to claim");

        uint256 balanceBefore = asset.balanceOf(accountEth);
        vm.startPrank(accountEth);
        svAI.withdraw(claimable, accountEth, accountEth);
        vm.stopPrank();

        uint256 received = asset.balanceOf(accountEth) - balanceBefore;
        console2.log("User received USDC:", received);
        assertApproxEqAbs(received, depositAmount, 10e6, "User didn't get back approximately deposited amount");
    }

    /// @notice Test that PPS oracle correctly reflects underlying SV share values
    function test_SuperVaultOfSuperVaults_PPSReflectsUnderlyingValue() public {
        uint256 depositAmount = 3000e6;
        uint256 perVault = depositAmount / 3;

        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, address(svAI), address(asset));

        _allocateToThreeVaults(
            address(stratAI), perVault, perVault, depositAmount - 2 * perVault,
            address(svTSLA), address(svSPCX), address(svNVDA)
        );

        // Check totalAssets calculation works through the oracle
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));

        // The ERC4626 yield source oracle should query convertToAssets on each underlying SV
        uint256 expectedTotal = svTSLA.convertToAssets(svTSLA.balanceOf(address(stratAI)))
            + svSPCX.convertToAssets(svSPCX.balanceOf(address(stratAI)))
            + svNVDA.convertToAssets(svNVDA.balanceOf(address(stratAI)));

        console2.log("totalAssets from oracle:", totalAssetsAI);
        console2.log("expected from convertToAssets sum:", expectedTotal);

        assertApproxEqAbs(totalAssetsAI, expectedTotal, 1e6, "totalAssets doesn't match oracle calculation");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allocate free assets from a strategy to 3 underlying ERC4626 vaults via hooks
    function _allocateToThreeVaults(
        address strat,
        uint256 amount1,
        uint256 amount2,
        uint256 amount3,
        address vault1,
        address vault2,
        address vault3
    )
        internal
    {
        ThreeVaultHookVars memory v;
        v.hookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        v.oracleId = _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER);

        v.hooks = new address[](3);
        v.hooks[0] = v.hookAddress;
        v.hooks[1] = v.hookAddress;
        v.hooks[2] = v.hookAddress;

        v.hookData = new bytes[](3);
        v.hookData[0] = _createApproveAndDeposit4626HookData(v.oracleId, vault1, address(asset), amount1, false, address(0), 0);
        v.hookData[1] = _createApproveAndDeposit4626HookData(v.oracleId, vault2, address(asset), amount2, false, address(0), 0);
        v.hookData[2] = _createApproveAndDeposit4626HookData(v.oracleId, vault3, address(asset), amount3, false, address(0), 0);

        v.expectedOut = new uint256[](3);
        v.expectedOut[0] = IERC4626(vault1).convertToShares(amount1);
        v.expectedOut[1] = IERC4626(vault2).convertToShares(amount2);
        v.expectedOut[2] = IERC4626(vault3).convertToShares(amount3);

        // Get the inspected args for each hook
        v.argsForProofs = new bytes[](3);
        v.argsForProofs[0] = ISuperHookInspector(v.hooks[0]).inspect(v.hookData[0]);
        v.argsForProofs[1] = ISuperHookInspector(v.hooks[1]).inspect(v.hookData[1]);
        v.argsForProofs[2] = ISuperHookInspector(v.hooks[2]).inspect(v.hookData[2]);

        // Build strategy-specific proofs (global proofs will be empty)
        bytes32[][] memory globalProofs = new bytes32[][](3);
        globalProofs[0] = new bytes32[](0);
        globalProofs[1] = new bytes32[](0);
        globalProofs[2] = new bytes32[](0);

        bytes32[][] memory stratProofs = new bytes32[][](3);
        stratProofs[0] = _getStrategyProof(v.hookAddress, v.argsForProofs[0]);
        stratProofs[1] = _getStrategyProof(v.hookAddress, v.argsForProofs[1]);
        stratProofs[2] = _getStrategyProof(v.hookAddress, v.argsForProofs[2]);

        vm.startPrank(MANAGER);
        SuperVaultStrategy(payable(strat)).executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: v.hooks,
                hookCalldata: v.hookData,
                expectedAssetsOrSharesOut: v.expectedOut,
                globalProofs: globalProofs,
                strategyProofs: stratProofs
            })
        );
        vm.stopPrank();
    }

    /// @notice Redeem from 3 underlying SuperVaults (async ERC-7540 flow) and fulfill
    ///         the pending redeem request on SuperAI.
    ///
    ///  Since underlying yield sources are SuperVaults (ERC-7540), we can't just call
    ///  `redeem()` directly. The flow is:
    ///   1. stratAI calls requestRedeem on each underlying SV
    ///   2. Each underlying SV's manager redeems from their Mock4626 and fulfills stratAI's request
    ///   3. stratAI withdraws USDC from each underlying SV
    ///   4. Manager fulfills the user's redeem request on SuperAI
    function _redeemFromThreeVaultsAndFulfill(
        address strat,
        address vault1,
        address vault2,
        address vault3
    )
        internal
    {
        // --- Step 1: stratAI requests redeem from each underlying SuperVault ---
        uint256 shares1 = IERC4626(vault1).balanceOf(strat);
        uint256 shares2 = IERC4626(vault2).balanceOf(strat);
        uint256 shares3 = IERC4626(vault3).balanceOf(strat);

        vm.startPrank(strat);
        SuperVault(vault1).requestRedeem(shares1, strat, strat);
        SuperVault(vault2).requestRedeem(shares2, strat, strat);
        SuperVault(vault3).requestRedeem(shares3, strat, strat);
        vm.stopPrank();

        // --- Step 2: For each underlying SV, fulfill stratAI's request using free USDC ---
        _fulfillUnderlyingSV(address(stratTSLA), strat);
        _fulfillUnderlyingSV(address(stratSPCX), strat);
        _fulfillUnderlyingSV(address(stratNVDA), strat);

        // --- Step 3: stratAI withdraws USDC from each underlying SV ---
        uint256 claimable1 = SuperVault(vault1).maxWithdraw(strat);
        uint256 claimable2 = SuperVault(vault2).maxWithdraw(strat);
        uint256 claimable3 = SuperVault(vault3).maxWithdraw(strat);

        vm.startPrank(strat);
        SuperVault(vault1).withdraw(claimable1, strat, strat);
        SuperVault(vault2).withdraw(claimable2, strat, strat);
        SuperVault(vault3).withdraw(claimable3, strat, strat);
        vm.stopPrank();

        // --- Step 4: Fulfill the user's redeem request on SuperAI ---
        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accountEth;
        requestingUsers = _sortAndUniqueControllers(requestingUsers);

        // Use the USDC now in stratAI to fulfill
        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = asset.balanceOf(strat);

        vm.startPrank(MANAGER);
        SuperVaultStrategy(payable(strat)).fulfillRedeemRequests(requestingUsers, totalAssetsOut);
        vm.stopPrank();
    }

    /// @dev Helper: for an underlying SV, fulfill the pending request from `requester`
    ///      using free USDC already sitting in the strategy (not yet allocated to Mock4626).
    function _fulfillUnderlyingSV(address underlyingStrat, address requester) internal {
        address[] memory controllers = new address[](1);
        controllers[0] = requester;
        controllers = _sortAndUniqueControllers(controllers);

        // Use all free USDC in the underlying strategy to fulfill
        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = asset.balanceOf(underlyingStrat);

        vm.prank(MANAGER);
        SuperVaultStrategy(payable(underlyingStrat)).fulfillRedeemRequests(controllers, totalAssetsOut);
    }
}
