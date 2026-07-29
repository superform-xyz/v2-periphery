// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";
import { MockOdosRouterV2 } from "../../mocks/MockOdosRouterV2.sol";
import { MockERC20 } from "../../mocks/MockERC20.sol";

import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { SuperVaultYieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/SuperVaultYieldSourceOracle.sol";
import { ApproveAndSwapOdosV2Hook } from "@superform-v2-core/src/hooks/swappers/odos/ApproveAndSwapOdosV2Hook.sol";
import { Mock4626Vault } from "../../mocks/Mock4626Vault.sol";

/// @title SuperVaultOfSuperVaultsCrossAsset
/// @notice Integration test: SuperAI (asset=USDC) deposits into underlying SuperVaults that hold
///         different assets (mockTSLA, mockSPCX, mockNVDA). Requires swap hooks to convert between
///         USDC and each mock token on deposit (USDC→token) and redeem (token→USDC).
contract SuperVaultOfSuperVaultsCrossAsset is BaseSuperVaultTest {
    using Math for uint256;

    // --- Mock tokens (6 decimals, matching USDC) ---
    MockERC20 public mockTSLA;
    MockERC20 public mockSPCX;
    MockERC20 public mockNVDA;

    // --- Mock 4626 vaults (yield sources for each underlying SV) ---
    Mock4626Vault public mock4626TSLA;
    Mock4626Vault public mock4626SPCX;
    Mock4626Vault public mock4626NVDA;

    // --- Layer-1 SuperVaults (asset = mockToken, yield source = Mock4626) ---
    SuperVault public svTSLA;
    SuperVaultStrategy public stratTSLA;

    SuperVault public svSPCX;
    SuperVaultStrategy public stratSPCX;

    SuperVault public svNVDA;
    SuperVaultStrategy public stratNVDA;

    // --- Layer-2 SuperVault (asset = USDC, yield sources = the 3 SuperVaults above) ---
    SuperVault public svAI;
    SuperVaultStrategy public stratAI;

    // --- Swap infrastructure ---
    MockOdosRouterV2 public odosRouter;
    address public approveAndSwapHook;

    // --- Oracle ---
    SuperVaultYieldSourceOracle public svOracle;

    /// @dev Struct to avoid stack-too-deep
    struct CrossAssetHookVars {
        address depositHookAddress;
        address redeemHookAddress;
        bytes32 oracleId;
        address[] hooks;
        bytes[] hookData;
        uint256[] expectedOut;
    }

    function setUp() public override {
        super.setUp();

        // Deploy mock tokens (6 decimals like USDC)
        mockTSLA = new MockERC20("Mock TSLA", "mTSLA", 6);
        mockSPCX = new MockERC20("Mock SPCX", "mSPCX", 6);
        mockNVDA = new MockERC20("Mock NVDA", "mNVDA", 6);

        vm.label(address(mockTSLA), "MockTSLA");
        vm.label(address(mockSPCX), "MockSPCX");
        vm.label(address(mockNVDA), "MockNVDA");

        // Deploy mock 4626 vaults for each token
        mock4626TSLA = new Mock4626Vault(address(mockTSLA), "Mock TSLA Yield", "y4626TSLA");
        mock4626SPCX = new Mock4626Vault(address(mockSPCX), "Mock SPCX Yield", "y4626SPCX");
        mock4626NVDA = new Mock4626Vault(address(mockNVDA), "Mock NVDA Yield", "y4626NVDA");

        vm.label(address(mock4626TSLA), "Mock4626TSLA");
        vm.label(address(mock4626SPCX), "Mock4626SPCX");
        vm.label(address(mock4626NVDA), "Mock4626NVDA");

        // Deploy mock Odos router and swap hook
        odosRouter = new MockOdosRouterV2();
        vm.label(address(odosRouter), "MockOdosRouter");
        approveAndSwapHook = address(new ApproveAndSwapOdosV2Hook(address(odosRouter)));
        vm.label(approveAndSwapHook, "ApproveAndSwapHook");
        superGovernor.registerHook(approveAndSwapHook);

        // Deploy layer-1 SuperVaults (each with a different mock token as asset)
        _deployLayer1Vaults();

        // Register Mock4626 vaults as yield sources for each layer-1 SuperVault
        _registerMockYieldSources();

        // Deploy the SuperVault-specific yield source oracle
        svOracle = new SuperVaultYieldSourceOracle(_getContract(ETH, SUPER_LEDGER_CONFIGURATION_KEY));

        // Update PPS for each layer-1 SuperVault (initial PPS = 1.0)
        _updateSuperVaultPPS(address(stratTSLA), address(svTSLA));
        _updateSuperVaultPPS(address(stratSPCX), address(svSPCX));
        _updateSuperVaultPPS(address(stratNVDA), address(svNVDA));

        // Deploy layer-2 SuperVault (SuperAI, asset = USDC)
        _deployLayer2Vault();

        // Update PPS for SuperAI
        _updateSuperVaultPPS(address(stratAI), address(svAI));
    }

    function _deployLayer1Vaults() internal {
        // Each underlying SV has a DIFFERENT asset (mock token, not USDC)
        (address v, address s,) = _deployVault(address(mockTSLA), "SV_TSLA");
        svTSLA = SuperVault(v);
        stratTSLA = SuperVaultStrategy(payable(s));

        (v, s,) = _deployVault(address(mockSPCX), "SV_SPCX");
        svSPCX = SuperVault(v);
        stratSPCX = SuperVaultStrategy(payable(s));

        (v, s,) = _deployVault(address(mockNVDA), "SV_NVDA");
        svNVDA = SuperVault(v);
        stratNVDA = SuperVaultStrategy(payable(s));
    }

    function _registerMockYieldSources() internal {
        address erc4626Oracle = _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY);

        vm.startPrank(MANAGER);
        stratTSLA.manageYieldSource(address(mock4626TSLA), erc4626Oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        stratSPCX.manageYieldSource(address(mock4626SPCX), erc4626Oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        stratNVDA.manageYieldSource(address(mock4626NVDA), erc4626Oracle, ISuperVaultStrategy.YieldSourceAction.Add);
        vm.stopPrank();
    }

    function _deployLayer2Vault() internal {
        (address v, address s,) = _deployVault(address(asset), "SV_AI");
        svAI = SuperVault(v);
        stratAI = SuperVaultStrategy(payable(s));

        // Register the 3 layer-1 SuperVaults as yield sources for SuperAI
        vm.startPrank(MANAGER);
        stratAI.manageYieldSource(address(svTSLA), address(svOracle), ISuperVaultStrategy.YieldSourceAction.Add);
        stratAI.manageYieldSource(address(svSPCX), address(svOracle), ISuperVaultStrategy.YieldSourceAction.Add);
        stratAI.manageYieldSource(address(svNVDA), address(svOracle), ISuperVaultStrategy.YieldSourceAction.Add);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit USDC into SuperAI, swap to mock tokens and deposit into underlying SVs
    function test_CrossAsset_DepositSwapAndAllocate() public {
        uint256 depositAmount = 3000e6; // 3000 USDC

        // Fund user and deposit into SuperAI
        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, address(svAI), address(asset));

        // Verify: user got SuperAI shares
        assertGt(svAI.balanceOf(accountEth), 0, "No SuperAI shares minted");

        // Verify: USDC is sitting as free assets in stratAI
        assertEq(asset.balanceOf(address(stratAI)), depositAmount, "Wrong free assets in stratAI");

        // Swap and deposit 1000 USDC worth to each underlying SV
        uint256 perVault = depositAmount / 3;
        _swapAndDeposit(mockTSLA, address(svTSLA), perVault);
        _swapAndDeposit(mockSPCX, address(svSPCX), perVault);
        _swapAndDeposit(mockNVDA, address(svNVDA), depositAmount - 2 * perVault);

        // Verify: stratAI holds shares of each underlying SV
        assertGt(svTSLA.balanceOf(address(stratAI)), 0, "No svTSLA shares");
        assertGt(svSPCX.balanceOf(address(stratAI)), 0, "No svSPCX shares");
        assertGt(svNVDA.balanceOf(address(stratAI)), 0, "No svNVDA shares");

        // Verify: stratAI should have zero free USDC left
        assertEq(asset.balanceOf(address(stratAI)), 0, "stratAI should have zero free USDC");

        // Verify: totalAssets of SuperAI reflects deposited amounts (minus swap fees)
        // MockOdosRouterV2 charges 0.5% fee per swap, so ~0.5% less per vault
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));
        console2.log("SuperAI totalAssets:", totalAssetsAI);
        // 0.5% fee on each swap means ~2985 USDC total (3000 * 0.995)
        uint256 expectedAfterFees = depositAmount - (depositAmount * 50 / 10_000);
        assertApproxEqAbs(totalAssetsAI, expectedAfterFees, 5e6, "totalAssets mismatch after allocation");
    }

    /// @notice Full lifecycle: deposit → swap+allocate → redeem → unwind → swap back → claim
    function test_CrossAsset_FullLifecycle() public {
        uint256 depositAmount = 3000e6;
        uint256 perVault = depositAmount / 3;

        // --- STEP 1: Deposit into SuperAI ---
        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, address(svAI), address(asset));
        assertGt(svAI.balanceOf(accountEth), 0, "No SuperAI shares minted");

        // --- STEP 2: Swap and allocate to all 3 underlying SVs ---
        _swapAndDeposit(mockTSLA, address(svTSLA), perVault);
        _swapAndDeposit(mockSPCX, address(svSPCX), perVault);
        _swapAndDeposit(mockNVDA, address(svNVDA), depositAmount - 2 * perVault);

        // Update PPS after allocation
        vm.warp(block.timestamp + 10);
        _updateSuperVaultPPS(address(stratAI), address(svAI));

        // --- STEP 3: User requests redeem of all shares ---
        _requestRedeem(svAI.balanceOf(accountEth), address(svAI));

        // --- STEP 4: Unwind from each underlying SV and swap back to USDC ---
        _unwindAndSwapBack(mockTSLA, address(svTSLA), address(stratTSLA));
        _unwindAndSwapBack(mockSPCX, address(svSPCX), address(stratSPCX));
        _unwindAndSwapBack(mockNVDA, address(svNVDA), address(stratNVDA));

        // --- STEP 5: Fulfill user's redeem request on SuperAI ---
        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accountEth;
        requestingUsers = _sortAndUniqueControllers(requestingUsers);

        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = asset.balanceOf(address(stratAI));

        vm.startPrank(MANAGER);
        stratAI.fulfillRedeemRequests(requestingUsers, totalAssetsOut);
        vm.stopPrank();

        // --- STEP 6: User claims ---
        uint256 claimable = svAI.maxWithdraw(accountEth);
        console2.log("Claimable assets:", claimable);
        assertGt(claimable, 0, "Nothing to claim");

        uint256 balanceBefore = asset.balanceOf(accountEth);
        vm.startPrank(accountEth);
        svAI.withdraw(claimable, accountEth, accountEth);
        vm.stopPrank();

        uint256 received = asset.balanceOf(accountEth) - balanceBefore;
        console2.log("User received USDC:", received);
        // ~1% round-trip loss (0.5% fee on each direction)
        uint256 expectedMin = depositAmount * 99 / 100 - 10e6; // ~1% loss with tolerance
        assertGt(received, expectedMin, "User lost too much on round trip");
    }

    /// @notice Verify PPS oracle correctly reflects underlying SV share values
    function test_CrossAsset_PPSReflectsUnderlyingValue() public {
        uint256 depositAmount = 3000e6;
        uint256 perVault = depositAmount / 3;

        _getTokens(address(asset), accountEth, depositAmount);
        _deposit(depositAmount, address(svAI), address(asset));

        _swapAndDeposit(mockTSLA, address(svTSLA), perVault);
        _swapAndDeposit(mockSPCX, address(svSPCX), perVault);
        _swapAndDeposit(mockNVDA, address(svNVDA), depositAmount - 2 * perVault);

        // Check totalAssets calculation works through the oracle chain
        (uint256 totalAssetsAI,) = totalAssetHelper.totalAssets(address(stratAI));

        // Cross-check: sum of convertToAssets for each underlying SV's shares held by stratAI
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

    /// @notice Swap USDC to a mock token and deposit into an underlying SuperVault
    /// @dev Chains 2 hooks: [ApproveAndSwapOdosV2Hook, ApproveAndDeposit4626VaultHook]
    function _swapAndDeposit(MockERC20 token, address superVault, uint256 usdcAmount) internal {
        // Calculate expected output after 0.5% fee
        uint256 swapOutput = usdcAmount - (usdcAmount * 50 / 10_000);

        // Pre-fund mock router with output tokens
        token.mint(address(odosRouter), usdcAmount);

        // Build 2-hook array: [swap, deposit]
        address[] memory hooks = new address[](2);
        hooks[0] = approveAndSwapHook;
        hooks[1] = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        bytes[] memory hookData = new bytes[](2);

        // Swap USDC → mock token
        uint256 outputMin = swapOutput * 99 / 100; // 1% slippage tolerance
        hookData[0] = _createOdosSwapHookData(
            address(asset), // inputToken = USDC
            usdcAmount, // inputAmount
            address(odosRouter), // inputReceiver (router)
            address(token), // outputToken = mock token
            usdcAmount, // outputQuote (1:1 before fee)
            outputMin, // outputMin
            bytes(""), // pathDefinition (empty for mock)
            address(0), // executor
            0, // referralCode
            false // usePrevHookAmount
        );

        // Deposit mock token into underlying SuperVault
        bytes32 oracleId = _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER);
        hookData[1] = _createApproveAndDeposit4626HookData(
            oracleId,
            superVault,
            address(token),
            swapOutput,
            false, // usePrevHookAmount
            address(0), // vaultBank
            0 // dstChainId
        );

        uint256[] memory expectedOut = new uint256[](2);
        expectedOut[0] = 0;
        expectedOut[1] = 0;

        // Mock validateHook to bypass merkle proof validation
        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        vm.startPrank(MANAGER);
        stratAI.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooks,
                hookCalldata: hookData,
                expectedAssetsOrSharesOut: expectedOut,
                globalProofs: new bytes32[][](2),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    /// @notice Unwind from an underlying SuperVault and swap the mock token back to USDC
    /// @dev Flow: requestRedeem → fulfill → withdraw → swap token→USDC
    function _unwindAndSwapBack(MockERC20 token, address superVault, address underlyingStrat) internal {
        uint256 shares = IERC4626(superVault).balanceOf(address(stratAI));

        // Step 1: stratAI requests redeem from underlying SV
        vm.startPrank(address(stratAI));
        SuperVault(superVault).requestRedeem(shares, address(stratAI), address(stratAI));
        vm.stopPrank();

        // Step 2: Fulfill underlying SV's redeem request
        // The underlying SV needs its mock token to fulfill. Deal tokens to the underlying strategy.
        uint256 tokensNeeded = IERC4626(superVault).convertToAssets(shares);
        deal(address(token), underlyingStrat, tokensNeeded);

        address[] memory controllers = new address[](1);
        controllers[0] = address(stratAI);
        controllers = _sortAndUniqueControllers(controllers);

        uint256[] memory totalAssetsOut = new uint256[](1);
        totalAssetsOut[0] = tokensNeeded;

        vm.startPrank(MANAGER);
        SuperVaultStrategy(payable(underlyingStrat)).fulfillRedeemRequests(controllers, totalAssetsOut);
        vm.stopPrank();

        // Step 3: stratAI withdraws mock tokens from underlying SV
        uint256 claimableTokens = SuperVault(superVault).maxWithdraw(address(stratAI));
        vm.startPrank(address(stratAI));
        SuperVault(superVault).withdraw(claimableTokens, address(stratAI), address(stratAI));
        vm.stopPrank();

        // Step 4: Swap mock token back to USDC via executeHooks
        _swapToUSDC(token, IERC20(address(token)).balanceOf(address(stratAI)));
    }

    /// @notice Swap a mock token back to USDC via the swap hook
    function _swapToUSDC(MockERC20 token, uint256 amount) internal {
        // Pre-fund mock router with USDC for the swap output
        deal(address(asset), address(odosRouter), amount);

        address[] memory hooks = new address[](1);
        hooks[0] = approveAndSwapHook;

        bytes[] memory hookData = new bytes[](1);
        uint256 outputMin = amount * 99 / 100;
        hookData[0] = _createOdosSwapHookData(
            address(token), // inputToken = mock token
            amount, // inputAmount
            address(odosRouter), // inputReceiver
            address(asset), // outputToken = USDC
            amount, // outputQuote (1:1 before fee)
            outputMin, // outputMin
            bytes(""), // pathDefinition
            address(0), // executor
            0, // referralCode
            false // usePrevHookAmount
        );

        uint256[] memory expectedOut = new uint256[](1);
        expectedOut[0] = 0;

        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        vm.startPrank(MANAGER);
        stratAI.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooks,
                hookCalldata: hookData,
                expectedAssetsOrSharesOut: expectedOut,
                globalProofs: new bytes32[][](1),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();
    }

}
