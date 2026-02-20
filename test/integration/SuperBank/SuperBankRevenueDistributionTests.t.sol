// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "../SuperVault/BaseSuperVaultTest.t.sol";
import { MockOdosRouterV2 } from "../../mocks/MockOdosRouterV2.sol";

// external
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { Vm } from "forge-std/Vm.sol";

// superform
import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { FeeType } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";

// v2-core hooks
import { AcrossV3Helper } from "@superform-v2-core/lib/pigeon/src/across/AcrossV3Helper.sol";
import { ApproveERC20Hook } from "@superform-v2-core/src/hooks/tokens/erc20/ApproveERC20Hook.sol";
import { SwapOdosV2Hook } from "@superform-v2-core/src/hooks/swappers/odos/SwapOdosV2Hook.sol";

// mocks
import { MockUp } from "../../mocks/MockUp.sol";

/// @title SuperBankRevenueDistributionTests
/// @notice Integration tests for SuperBank revenue distribution, cross-chain bridging, and UP swapping
/// @dev Tests the production flow: REVENUE_SHARE → skim → bridge → swap
///
/// NOTE: Time warps accumulate across helpers:
///   - _setRevenueShare: +7 days (governance timelock)
///   - _setFeeConfigToSuperBank: +1 week (fee config timelock)
///   - _setupFeesInSuperBank: +13 hours (skim timelock)
///   - _setupSuperBankHook: +7 days per hook (merkle root timelock)
/// Total time travel per test can exceed 14+ days. This is intentional for timelocks.
contract SuperBankRevenueDistributionTests is BaseSuperVaultTest {
    // Core contracts
    SuperBank public superBank;

    // Constants
    uint256 constant REVENUE_SHARE_20_PERCENT = 2000; // 20% in BPS

    function setUp() public virtual override {
        super.setUp();
        console2.log("--- SETUP SUPERBANK REVENUE DISTRIBUTION TESTS ---");

        vm.selectFork(FORKS[ETH]);

        // Get SuperBank
        superBank = SuperBank(payable(_getContract(ETH, SUPER_BANK_KEY)));

        console2.log("SuperBank address:", address(superBank));
        console2.log("Strategy address:", address(strategy));
    }

    /*//////////////////////////////////////////////////////////////
                    TEST 1: REVENUE_SHARE + SKIM
    //////////////////////////////////////////////////////////////*/

    /// @notice Test setting REVENUE_SHARE to 20% and skimming performance fees to SuperBank
    function test_SetRevenueShareAndSkimFees() public {
        console2.log("\n=== TEST 1: Set REVENUE_SHARE to 20% and Skim Fees ===");

        uint256 depositAmount = 10_000e6; // 10k USDC
        uint256 feesCollected = _setupFeesInSuperBank(depositAmount);

        console2.log("Fees collected by SuperBank:", feesCollected);

        // Verify revenue share was set correctly
        uint256 currentRevenueShare = superGovernor.getFee(FeeType.REVENUE_SHARE);
        assertEq(currentRevenueShare, REVENUE_SHARE_20_PERCENT, "Revenue share not set correctly");

        // Verify fees actually went to SuperBank (strictly greater, not greater-or-equal)
        assertGt(feesCollected, 0, "Fee collection cannot be zero");

        console2.log("\n=== TEST 1 PASSED ===");
    }

    /*//////////////////////////////////////////////////////////////
                    TEST 2: REVENUE_SHARE + SKIM + BRIDGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Test 1 + bridge funds from SuperBank on Ethereum to Base via Across
    function test_SetRevenueShareSkimAndBridgeToBase() public {
        console2.log("\n=== TEST 2: Set REVENUE_SHARE, Skim, and Bridge to Base ===");

        // Setup fees in SuperBank using common helper
        uint256 depositAmount = 10_000e6;
        uint256 feesCollected = _setupFeesInSuperBank(depositAmount);
        console2.log("Fees collected in SuperBank:", feesCollected);

        // Ensure we have funds to bridge (fallback if skim doesn't generate fees)
        uint256 bridgeAmount = feesCollected > 0 ? feesCollected : 1000e6;
        if (feesCollected == 0) {
            deal(address(asset), address(superBank), bridgeAmount);
            console2.log("Dealt USDC to SuperBank for bridging test:", bridgeAmount);
        }

        // Setup hooks for SuperBank (Approve + Across)
        address approveHook = hookAddresses[ETH][APPROVE_ERC20_HOOK_KEY];
        address acrossHook = hookAddresses[ETH][ACROSS_SEND_FUNDS_AND_EXECUTE_ON_DST_HOOK_KEY];
        address spokePoolV3 = SPOKE_POOL_V3_ADDRESSES[ETH];
        address baseUsdc = existingUnderlyingTokens[BASE][USDC_KEY];

        // Get SuperBank address on Base and record balance
        vm.selectFork(FORKS[BASE]);
        address superBankBase = _getContract(BASE, SUPER_BANK_KEY);
        uint256 baseSuperBankBalanceBefore = IERC20(baseUsdc).balanceOf(superBankBase);
        vm.selectFork(FORKS[ETH]);

        // Create hook data for approve (approve SpokePool to transfer USDC)
        bytes memory approveHookData = _createApproveHookData(
            address(asset), // token to approve
            spokePoolV3, // spender (Across SpokePool)
            bridgeAmount, // amount
            false // usePrevHookAmount
        );

        // Create hook data for Across bridge (no execution on destination)
        bytes memory acrossHookData = _createAcrossV3ReceiveFundsNoExecution(
            superBankBase, // recipient on Base
            address(asset), // input token (ETH USDC)
            baseUsdc, // output token (Base USDC)
            bridgeAmount, // input amount
            bridgeAmount * 99 / 100, // output amount (1% fee buffer)
            BASE, // destination chain
            false, // usePrevHookAmount
            bytes("") // no message/execution on destination
        );

        // Setup hooks with their actual hook data
        _setupSuperBankHook(approveHook, approveHookData);
        _setupSuperBankHook(acrossHook, acrossHookData);

        // Bridge funds to Base via Across
        address[] memory hooks = new address[](2);
        hooks[0] = approveHook;
        hooks[1] = acrossHook;

        bytes[] memory hookData = new bytes[](2);
        hookData[0] = approveHookData;
        hookData[1] = acrossHookData;

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0); // Single leaf, no proof needed
        merkleProofs[1] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 0; // Approve hook returns 0 output
        expectedOutputs[1] = 0; // Bridge hook returns 0 (bridge output is on destination)

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: hookData,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        // Record logs for Across helper
        vm.recordLogs();

        // Grant BANK_MANAGER_ROLE to this contract for testing
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superBank.executeHooks(executionData);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // Process Across message to Base using pigeon
        AcrossV3Helper(_getContract(ETH, ACROSS_V3_HELPER_KEY)).help(
            SPOKE_POOL_V3_ADDRESSES[ETH],
            SPOKE_POOL_V3_ADDRESSES[BASE],
            ACROSS_RELAYER,
            block.timestamp,
            FORKS[BASE],
            BASE,
            ETH,
            logs
        );

        // Verify funds arrived on Base
        vm.selectFork(FORKS[BASE]);
        uint256 baseSuperBankBalanceAfter = IERC20(baseUsdc).balanceOf(superBankBase);

        assertGt(baseSuperBankBalanceAfter, baseSuperBankBalanceBefore, "Base SuperBank should have received bridged funds");
        console2.log("Bridge result: received", baseSuperBankBalanceAfter - baseSuperBankBalanceBefore, "USDC on Base");

        console2.log("=== TEST 2 PASSED ===");
    }

    /*//////////////////////////////////////////////////////////////
                    TEST 3: REVENUE_SHARE + SKIM + BRIDGE + SWAP
    //////////////////////////////////////////////////////////////*/

    // Struct to hold swap test state across phases
    struct SwapTestState {
        address baseUsdc;
        address baseSuperBank;
        uint256 bridgeAmount;
    }

    /// @notice Test 1 + Test 2 + swap funds to UP on Base
    /// @dev This test bridges USDC to Base, then executes a swap from USDC to UP on Base SuperBank
    function test_SetRevenueShareSkimBridgeAndSwapToUP() public {
        console2.log("\n=== TEST 3: Set REVENUE_SHARE, Skim, Bridge, and Swap to UP ===");

        // Phase 1: Collect fees on ETH and bridge to Base
        SwapTestState memory state = _phase1_CollectFeesAndBridge();

        // Phase 2: Execute swap on Base
        _phase2_ExecuteSwapOnBase(state);

        console2.log("\n=== TEST 3 PASSED ===");
    }

    /// @notice Phase 1: Collect fees on ETH and bridge to Base
    function _phase1_CollectFeesAndBridge() internal returns (SwapTestState memory state) {
        // Setup fees in SuperBank using common helper
        uint256 depositAmount = 10_000e6;
        uint256 feesCollected = _setupFeesInSuperBank(depositAmount);

        // Ensure we have funds to bridge (fallback if skim doesn't generate fees)
        state.bridgeAmount = feesCollected > 0 ? feesCollected : 1000e6;
        if (feesCollected == 0) {
            deal(address(asset), address(superBank), state.bridgeAmount);
        }

        state.baseUsdc = existingUnderlyingTokens[BASE][USDC_KEY];
        state.baseSuperBank = _getContract(BASE, SUPER_BANK_KEY);

        // Execute bridge
        _executeBridgeToBase(state.bridgeAmount, state.baseSuperBank, state.baseUsdc);
    }

    /// @notice Execute bridge from ETH to Base
    function _executeBridgeToBase(uint256 bridgeAmount, address baseSuperBank, address baseUsdc) internal {
        address approveHook = hookAddresses[ETH][APPROVE_ERC20_HOOK_KEY];
        address acrossHook = hookAddresses[ETH][ACROSS_SEND_FUNDS_AND_EXECUTE_ON_DST_HOOK_KEY];

        bytes memory approveHookData = _createApproveHookData(
            address(asset), SPOKE_POOL_V3_ADDRESSES[ETH], bridgeAmount, false
        );
        bytes memory acrossHookData = _createAcrossV3ReceiveFundsNoExecution(
            baseSuperBank, address(asset), baseUsdc, bridgeAmount, bridgeAmount * 99 / 100, BASE, false, bytes("")
        );

        _setupSuperBankHook(approveHook, approveHookData);
        _setupSuperBankHook(acrossHook, acrossHookData);

        IHookExecutionData.HookExecutionData memory executionData = _createBridgeExecutionData(
            approveHook, acrossHook, approveHookData, acrossHookData
        );

        vm.recordLogs();
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superBank.executeHooks(executionData);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        AcrossV3Helper(_getContract(ETH, ACROSS_V3_HELPER_KEY)).help(
            SPOKE_POOL_V3_ADDRESSES[ETH],
            SPOKE_POOL_V3_ADDRESSES[BASE],
            ACROSS_RELAYER,
            block.timestamp,
            FORKS[BASE],
            BASE,
            ETH,
            logs
        );
    }

    /// @notice Create bridge execution data
    function _createBridgeExecutionData(
        address approveHook,
        address acrossHook,
        bytes memory approveHookData,
        bytes memory acrossHookData
    ) internal pure returns (IHookExecutionData.HookExecutionData memory) {
        address[] memory hooks = new address[](2);
        hooks[0] = approveHook;
        hooks[1] = acrossHook;

        bytes[] memory hookData = new bytes[](2);
        hookData[0] = approveHookData;
        hookData[1] = acrossHookData;

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0);
        merkleProofs[1] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](2);

        return IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: hookData,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });
    }

    /// @notice Phase 2: Execute swap on Base
    function _phase2_ExecuteSwapOnBase(SwapTestState memory state) internal {
        vm.selectFork(FORKS[BASE]);

        SuperBank baseSuperBankContract = SuperBank(payable(state.baseSuperBank));
        uint256 bridgedBalance = IERC20(state.baseUsdc).balanceOf(state.baseSuperBank);
        assertGt(bridgedBalance, 0, "Should have received bridged funds");

        // Deploy swap infrastructure
        MockOdosRouterV2 router = new MockOdosRouterV2();
        MockUp upToken = new MockUp(address(this));
        ApproveERC20Hook approveHook = new ApproveERC20Hook();
        SwapOdosV2Hook swapHook = new SwapOdosV2Hook(address(router));

        // Setup SuperGovernor on Base
        SuperGovernor baseGov = SuperGovernor(address(baseSuperBankContract.SUPER_GOVERNOR()));
        baseGov.registerHook(address(approveHook));
        baseGov.registerHook(address(swapHook));
        baseGov.grantRole(baseGov.BANK_MANAGER_ROLE(), address(this));

        // Mint UP to router for swap output
        uint256 expectedUp = bridgedBalance * 1e12;
        upToken.mint(address(router), expectedUp);

        // Execute swap
        _executeSwapOnBase(SwapExecutionParams({
            bank: baseSuperBankContract,
            gov: baseGov,
            usdc: state.baseUsdc,
            upToken: address(upToken),
            router: address(router),
            approveHook: address(approveHook),
            swapHook: address(swapHook),
            swapAmount: bridgedBalance,
            expectedUp: expectedUp
        }));
    }

    // Struct to reduce stack depth in swap execution
    struct SwapExecutionParams {
        SuperBank bank;
        SuperGovernor gov;
        address usdc;
        address upToken;
        address router;
        address approveHook;
        address swapHook;
        uint256 swapAmount;
        uint256 expectedUp;
    }

    /// @notice Execute swap hooks on Base SuperBank
    function _executeSwapOnBase(SwapExecutionParams memory p) internal {
        bytes memory approveData = _createApproveHookData(p.usdc, p.router, p.swapAmount, false);
        bytes memory swapData = _createSwapHookData(p.usdc, p.upToken, p.swapAmount, p.expectedUp);

        _setupSuperBankHookOnBase(p.gov, p.approveHook, approveData);
        _setupSuperBankHookOnBase(p.gov, p.swapHook, swapData);

        IHookExecutionData.HookExecutionData memory execData = _createSwapExecutionData(
            p.approveHook, p.swapHook, approveData, swapData
        );

        uint256 usdcBefore = IERC20(p.usdc).balanceOf(address(p.bank));
        uint256 upBefore = IERC20(p.upToken).balanceOf(address(p.bank));

        p.bank.executeHooks(execData);

        _verifySwapResults(p.usdc, p.upToken, address(p.bank), usdcBefore, upBefore);
    }

    /// @notice Verify swap results
    function _verifySwapResults(
        address usdc,
        address upToken,
        address bank,
        uint256 usdcBefore,
        uint256 upBefore
    ) internal {
        uint256 usdcAfter = IERC20(usdc).balanceOf(bank);
        uint256 upAfter = IERC20(upToken).balanceOf(bank);

        assertLt(usdcAfter, usdcBefore, "USDC should have been swapped");
        assertGt(upAfter, upBefore, "UP balance should have increased");

        console2.log("Swap complete: UP received", upAfter - upBefore);
    }

    /// @notice Create swap hook data for Odos
    function _createSwapHookData(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputQuote
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            inputToken,
            inputAmount,
            address(0),      // executor
            outputToken,
            outputQuote,
            outputQuote * 99 / 100,  // minOut
            false,           // usePrevHookAmount
            uint256(0),      // pathDefinitionLength
            bytes(""),       // pathDefinition
            address(0),      // referralCode
            uint32(0),       // referralFee
            false            // compact
        );
    }

    /// @notice Create swap execution data
    function _createSwapExecutionData(
        address approveHook,
        address swapHook,
        bytes memory approveData,
        bytes memory swapData
    ) internal pure returns (IHookExecutionData.HookExecutionData memory) {
        address[] memory hooks = new address[](2);
        hooks[0] = approveHook;
        hooks[1] = swapHook;

        bytes[] memory hookData = new bytes[](2);
        hookData[0] = approveData;
        hookData[1] = swapData;

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0);
        merkleProofs[1] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](2);

        return IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: hookData,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });
    }

    /// @notice Helper to setup hooks on Base SuperGovernor
    function _setupSuperBankHookOnBase(
        SuperGovernor baseGovernor,
        address hook,
        bytes memory hookDataForLeaf
    ) internal {
        _setupSuperBankHookWithGovernor(baseGovernor, hook, hookDataForLeaf);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Common setup: configure revenue share, deposit, allocate, simulate yield, and skim fees
    /// @param depositAmount Amount to deposit into SuperVault
    /// @return feesCollected Amount of fees collected in SuperBank
    function _setupFeesInSuperBank(uint256 depositAmount) internal returns (uint256 feesCollected) {
        _setRevenueShare(REVENUE_SHARE_20_PERCENT);
        _setFeeConfigToSuperBank(100);
        _updateSuperVaultPPS(address(strategy), address(vault));

        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        _updateSuperVaultPPS(address(strategy), address(vault));
        vm.warp(block.timestamp + 13 hours);

        // Simulate profit
        deal(address(asset), address(strategy), 100e6);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // Skim fees
        uint256 balanceBefore = asset.balanceOf(address(superBank));
        vm.prank(MANAGER);
        strategy.skimPerformanceFee();
        feesCollected = asset.balanceOf(address(superBank)) - balanceBefore;
    }

    /// @notice Sets the REVENUE_SHARE fee via governance timelock
    function _setRevenueShare(uint256 newRevenueShare) internal {
        superGovernor.proposeFee(FeeType.REVENUE_SHARE, newRevenueShare);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeFeeUpdate(FeeType.REVENUE_SHARE);
    }

    /// @notice Sets fee configuration for the strategy with SuperBank as recipient
    function _setFeeConfigToSuperBank(uint256 performanceFeeBps) internal {
        vm.prank(MANAGER);
        strategy.proposeVaultFeeConfigUpdate(
            performanceFeeBps,
            0, // managementFeeBps
            address(superBank) // recipient
        );

        vm.warp(block.timestamp + 1 weeks + 1);

        vm.prank(MANAGER);
        strategy.executeVaultFeeConfigUpdate();
    }

    /// @notice Sets up a hook for SuperBank execution with proper merkle root (ETH chain)
    function _setupSuperBankHook(address hook, bytes memory hookData) internal {
        _setupSuperBankHookWithGovernor(superGovernor, hook, hookData);
    }

    /// @notice Sets up a hook for SuperBank execution with proper merkle root (any chain)
    function _setupSuperBankHookWithGovernor(
        SuperGovernor governor,
        address hook,
        bytes memory hookData
    ) internal {
        bytes memory hookArgs = ISuperHookInspector(hook).inspect(hookData);
        bytes32 leafHash = keccak256(bytes.concat(keccak256(abi.encode(hook, hookArgs))));

        governor.proposeSuperBankHookMerkleRoot(hook, leafHash);
        vm.warp(block.timestamp + 7 days + 1);
        governor.executeSuperBankHookMerkleRootUpdate(hook);
    }

}
