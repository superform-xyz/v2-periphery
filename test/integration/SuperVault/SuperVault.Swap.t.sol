// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";
import { MockOdosRouterV2 } from "../../mocks/MockOdosRouterV2.sol";

// external
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

// superform
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { ClaimsMerkleHelper } from "../../../test/utils/merkle/helper/ClaimsMerkleHelper.sol";
import { IDistributor } from "@superform-v2-core/src/vendor/merkl/IDistributor.sol";
import { BaseHook } from "@superform-v2-core/src/hooks/BaseHook.sol";
import { ApproveAndSwapOdosV2Hook } from "@superform-v2-core/src/hooks/swappers/odos/ApproveAndSwapOdosV2Hook.sol";

contract SuperVaultSwapTest is BaseSuperVaultTest, ClaimsMerkleHelper {

    address operator = address(0x123);
    uint256 constant userPrivateKey = 0xA11CE;
    address userAddress;

    MockOdosRouterV2 public odosRouter;
    address public odosRouterAddress;

    struct MerklHookWithSwapVars {
        uint256 depositAmount;
        uint256 userShares;
        uint256 fluidBalanceBeforeClaim;
        uint256 aaveBalanceBeforeClaim;
        address[] users;
        address[] tokens;
        uint256[] amounts;
        bytes32[][] proofs;
        bytes32 root;
        bytes32[] leaves;
        address depositHookAddress;
        address claimHookAddress;
        address[] hooksAddresses;
        bytes[] hooksData;
        QuoteInputToken[] quoteInputTokens;
        QuoteOutputToken[] quoteOutputTokens;
        string path;
        string requestBody;
        OdosDecodedSwap odosDecodedSwap;
        bytes odosCalldata;
        uint256 fluidBalanceAfterClaim;
        uint256 aaveBalanceAfterClaim;
    }

    struct DepositAndSwapParams {
        uint256 fullAmount;
        address assetToDeposit;
        address strat;
        address vault1;
        address vault2;
        address depositHookAddress;
        address approveAndSwapOdos;
        uint256 fullDepositAmount;
        uint256 halfAmount;
        uint256 swapAmount;
    }

    struct RatioCalculationVars {
        uint256 totalRatio;
        uint256 vaultAllocation;
        uint256 vault1Amount;
        uint256 vault2Amount;
        bytes32 yieldSourceOracleId;
    }

    struct SwapProcessingVars {
        string path;
        string requestBody;
        OdosDecodedSwap odosDecodedSwap;
        bytes odosCalldata;
        QuoteInputToken[] quoteInputTokens;
        QuoteOutputToken[] quoteOutputTokens;
    }

    struct ExecutionArrays {
        address[] executeHookAddresses;
        bytes[] executeHooksData;
        uint256[] expectedAssetsOrSharesOut;
        bytes[] argsForProofs;
    }

    function setUp() public override {
        useLatestFork = false; // Use pinned block for deterministic tests

        super.setUp();
        userAddress = vm.addr(userPrivateKey);

        updateTestVaultPredictions();

        _updateSuperVaultPPS(address(strategy), address(vault));

        useRealOdosRouter = false;

        // Setup Odos router based on flag
        if (useRealOdosRouter) {
            odosRouterAddress = CHAIN_1_ODOS_ROUTER;
        } else {
            odosRouter = new MockOdosRouterV2();
            odosRouterAddress = address(odosRouter);
        }

        // Deploy ApproveAndSwapOdosV2Hook with the correct router
        approveAndSwapOdosHookAddressETH = address(new ApproveAndSwapOdosV2Hook(odosRouterAddress));
        superGovernor.registerHook(approveAndSwapOdosHookAddressETH);
    }
    
    function _createOdosSwapCalldataRequest(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address _receiver
    )
        internal
        returns (bytes memory)
    {
        // get pathId
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: _tokenIn, amount: _amount });
        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: _tokenOut, proportion: 1 });
        string memory pathId = surlCallQuoteV2(inputTokens, outputTokens, _receiver, ETH, true);

        // get assemble data
        string memory swapCompactData = surlCallAssemble(pathId, _receiver);
        return fromHex(swapCompactData);
    }

    /*//////////////////////////////////////////////////////////////
                       SWAP TESTS
    //////////////////////////////////////////////////////////////*/
    function test_Deposit_Allocate_And_Swap() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Direct deposit
        _deposit(depositAmount);

        // Verify deposit state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        // Allocate the assets to yield sources
        // -- add it as a new yield source
        _depositAndSwap(depositAmount, address(asset), address(strategy), address(fluidVault), address(aaveVault));

        // Verify allocation state
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");

        // Verify swap happened
        uint256 balanceOfUsdt = IERC20(CHAIN_1_USDT).balanceOf(address(strategy));
        assertGt(balanceOfUsdt, 0, "No USDT allocated");
    }

    function test_Deposit_Allocate_And_Swap_Custom_Ratios() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Direct deposit
        _deposit(depositAmount);

        // Verify deposit state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        // Allocate the assets to yield sources
        _depositAndSwapWithCustomRatios(
            1000e6, address(asset), address(strategy), address(fluidVault), address(aaveVault), 3, 1
        );

        // Verify allocation state
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");
        assertGt(
            fluidVault.balanceOf(address(strategy)),
            aaveVault.balanceOf(address(strategy)),
            "Fluid vault has more shares than aave vault"
        );

        // Verify swap happened
        uint256 balanceOfUsdt = IERC20(CHAIN_1_USDT).balanceOf(address(strategy));
        assertGt(balanceOfUsdt, 0, "No USDT allocated");
    }

    function test_Deposit_Allocate_And_Swap_SingleVault() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Direct deposit
        _deposit(depositAmount);

        // Verify deposit state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        // Allocate ALL vault funds to only fluidVault (ratio 1:0)
        _depositAndSwapWithCustomRatios(
            depositAmount,
            address(asset),
            address(strategy),
            address(fluidVault),
            address(aaveVault),
            1,
            1 // 100% to fluid, 0% to aave
        );

        // Verify only fluidVault has allocations
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");

        // Verify swap still happened (30% of total)
        uint256 balanceOfUsdt = IERC20(CHAIN_1_USDT).balanceOf(address(strategy));
        assertGt(balanceOfUsdt, 0, "No USDT allocated");

        // Verify the amounts are correct
        uint256 expectedSwapAmount = depositAmount * 30 / 100; // 300 USDC worth of USDT
        assertApproxEqRel(balanceOfUsdt, expectedSwapAmount, 0.05e18, "USDT amount should be ~300 USDC equivalent");
    }

    //tests idea
    // - T1.MERKL claim and deposit
    // - T2.MERKL claim, swap and deposit
    // - T3.MERKL claim, use prev and deposit to fluid
    // T1.MERKL
    function test_MerklHook_And_Swap() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        _deposit(depositAmount);

        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 fluidBalanceBeforeClaim = fluidVault.balanceOf(address(strategy));
        uint256 aaveBalanceBeforeClaim = aaveVault.balanceOf(address(strategy));

        assertGt(fluidBalanceBeforeClaim, 0, "No fluid shares allocated");
        assertGt(aaveBalanceBeforeClaim, 0, "No aave shares allocated");

        // add some funds to merkle hook
        // prank and mock the tree
        address[] memory users = new address[](1);
        users[0] = address(strategy);
        address[] memory tokens = new address[](1);
        tokens[0] = address(asset); //assume we claim the same token to avoid a swap
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10e6;
        (bytes32[][] memory proofs, bytes32 root,) = _createClaimsTree(users, tokens, amounts);
        // set the tree
        vm.startPrank(CHAIN_1_MERKL_TREE_UPDATER_EOA);
        IDistributor(MERKL_DISTRIBUTOR).updateTree(IDistributor.MerkleTree({ merkleRoot: root, ipfsHash: "" }));
        vm.stopPrank();
        // advance time for the new tree to become active
        vm.warp(block.timestamp + 100 days);

        // deal some tokens
        deal(address(asset), address(MERKL_DISTRIBUTOR), 10e6);

        // execute hooks
        // - claim
        // - deposit usdc
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        address claimHookAddress = _getHookAddress(ETH, MERKL_CLAIM_REWARD_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        bytes[] memory hooksData = new bytes[](3);

        // Setup hooks
        hooksAddresses[0] = claimHookAddress;
        hooksAddresses[1] = depositHookAddress;
        hooksAddresses[2] = depositHookAddress;

        hooksData[0] = _createMerklClaimRewardHookData(tokens, amounts, proofs);
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            5e6,
            false,
            address(0),
            0
        );
        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            5e6,
            false,
            address(0),
            0
        );

        vm.mockCall(
            address(aggregator), abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector), abi.encode(true)
        );

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: new bytes32[][](3),
                strategyProofs: new bytes32[][](3)
            })
        );
        vm.stopPrank();

        uint256 fluidBalanceAfterClaim = fluidVault.balanceOf(address(strategy));
        uint256 aaveBalanceAfterClaim = aaveVault.balanceOf(address(strategy));

        assertGt(fluidBalanceAfterClaim, fluidBalanceBeforeClaim, "Fluid vault balance should have increased");
        assertGt(aaveBalanceAfterClaim, aaveBalanceBeforeClaim, "Aave vault balance should have increased");
    }

    // T2.MERKL
    function test_MerklHook_With_Swap() public {
        MerklHookWithSwapVars memory vars;
        vars.depositAmount = 1000e6; // 1000 USDC

        _deposit(vars.depositAmount);

        vars.userShares = vault.balanceOf(accountEth);
        assertGt(vars.userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), vars.depositAmount, "Wrong strategy balance");

        _depositFreeAssetsFromSingleAmount(vars.depositAmount, address(fluidVault), address(aaveVault));

        vars.fluidBalanceBeforeClaim = fluidVault.balanceOf(address(strategy));
        vars.aaveBalanceBeforeClaim = aaveVault.balanceOf(address(strategy));

        assertGt(vars.fluidBalanceBeforeClaim, 0, "No fluid shares allocated");
        assertGt(vars.aaveBalanceBeforeClaim, 0, "No aave shares allocated");

        // add some funds to merkle hook
        // prank and mock the tree
        vars.users = new address[](1);
        vars.users[0] = address(strategy);
        vars.tokens = new address[](1);
        vars.tokens[0] = address(CHAIN_1_USDT); // claim a different token so we can swap it
        vars.amounts = new uint256[](1);
        vars.amounts[0] = 10e6;
        (vars.proofs, vars.root, vars.leaves) = _createClaimsTree(vars.users, vars.tokens, vars.amounts);
        // set the tree
        vm.startPrank(CHAIN_1_MERKL_TREE_UPDATER_EOA);
        IDistributor(MERKL_DISTRIBUTOR).updateTree(IDistributor.MerkleTree({ merkleRoot: vars.root, ipfsHash: "" }));
        vm.stopPrank();
        // advance time for the new tree to become active
        vm.warp(block.timestamp + 100 days);

        // deal some tokens
        deal(address(CHAIN_1_USDT), address(MERKL_DISTRIBUTOR), 10e6);

        // execute hooks
        // - claim
        // - swap
        // - deposit usdc
        vars.depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        vars.claimHookAddress = _getHookAddress(ETH, MERKL_CLAIM_REWARD_HOOK_KEY);

        vars.hooksAddresses = new address[](4);
        vars.hooksData = new bytes[](4);

        // Setup hooks
        vars.hooksAddresses[0] = vars.claimHookAddress;
        vars.hooksAddresses[1] = approveAndSwapOdosHookAddressETH;
        vars.hooksAddresses[2] = vars.depositHookAddress;
        vars.hooksAddresses[3] = vars.depositHookAddress;

        // -- claim
        vars.hooksData[0] = _createMerklClaimRewardHookData(vars.tokens, vars.amounts, vars.proofs);

        // --swap data
        vars.quoteInputTokens = new QuoteInputToken[](1);
        vars.quoteInputTokens[0] = QuoteInputToken({ tokenAddress: address(CHAIN_1_USDT), amount: 10e6 });
        vars.quoteOutputTokens = new QuoteOutputToken[](1);
        vars.quoteOutputTokens[0] = QuoteOutputToken({ tokenAddress: address(asset), proportion: 1 });

        if (useRealOdosRouter) {
            vars.path = surlCallQuoteV2(vars.quoteInputTokens, vars.quoteOutputTokens, address(strategy), ETH, true);
            vars.requestBody = surlCallAssemble(vars.path, address(strategy));
            vars.odosDecodedSwap = decodeOdosSwapCalldata(fromHex(vars.requestBody));
            vars.odosCalldata = _createOdosSwapHookData(
                vars.odosDecodedSwap.tokenInfo.inputToken,
                vars.odosDecodedSwap.tokenInfo.inputAmount,
                vars.odosDecodedSwap.tokenInfo.inputReceiver,
                vars.odosDecodedSwap.tokenInfo.outputToken,
                vars.odosDecodedSwap.tokenInfo.outputQuote,
                vars.odosDecodedSwap.tokenInfo.outputMin * (1e5 - 1e4) / 1e5,
                vars.odosDecodedSwap.pathDefinition,
                vars.odosDecodedSwap.executor,
                vars.odosDecodedSwap.referralCode,
                false
            );
        } else {
            // Mock scenario: deal tokens to mock router and create simplified calldata
            deal(address(asset), address(odosRouter), 10e6);

            // Calculate outputMin safely to prevent underflow
            uint256 outputQuote = 10e6;
            uint256 slippageFactor = outputQuote * 1e4 / 1e5; // 10% slippage
            assert(outputQuote >= slippageFactor);
            uint256 outputMin = outputQuote - slippageFactor;

            vars.odosCalldata = _createOdosSwapHookData(
                address(CHAIN_1_USDT),
                10e6,
                odosRouterAddress,
                address(asset),
                outputQuote,
                outputMin,
                bytes(""),
                address(0),
                0,
                false
            );
        }
        vars.hooksData[1] = vars.odosCalldata;

        // -- deposit to fluid
        vars.hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            4e6,
            false,
            address(0),
            0
        );

        // -- deposit to aave
        vars.hooksData[3] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            4e6,
            false,
            address(0),
            0
        );

        vm.mockCall(
            address(aggregator), abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector), abi.encode(true)
        );

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: vars.hooksAddresses,
                hookCalldata: vars.hooksData,
                expectedAssetsOrSharesOut: new uint256[](4),
                globalProofs: new bytes32[][](4),
                strategyProofs: new bytes32[][](4)
            })
        );
        vm.stopPrank();

        vars.fluidBalanceAfterClaim = fluidVault.balanceOf(address(strategy));
        vars.aaveBalanceAfterClaim = aaveVault.balanceOf(address(strategy));

        assertGt(vars.fluidBalanceAfterClaim, vars.fluidBalanceBeforeClaim, "Fluid vault balance should have increased");
        assertGt(vars.aaveBalanceAfterClaim, vars.aaveBalanceBeforeClaim, "Aave vault balance should have increased");
    }

    // T3.MERKL
    function test_MerklHook_WithPrev_OneVault() public {
        // should change nothing because MerklHook does not return the out amount
        uint256 depositAmount = 1000e6; // 1000 USDC

        _deposit(depositAmount);

        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 fluidBalanceBeforeClaim = fluidVault.balanceOf(address(strategy));
        uint256 aaveBalanceBeforeClaim = aaveVault.balanceOf(address(strategy));

        assertGt(fluidBalanceBeforeClaim, 0, "No fluid shares allocated");
        assertGt(aaveBalanceBeforeClaim, 0, "No aave shares allocated");

        // add some funds to merkle hook
        // prank and mock the tree
        address[] memory users = new address[](1);
        users[0] = address(strategy);
        address[] memory tokens = new address[](1);
        tokens[0] = address(asset); //assume we claim the same token to avoid a swap
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10e6;
        (bytes32[][] memory proofs, bytes32 root,) = _createClaimsTree(users, tokens, amounts);
        // set the tree
        vm.startPrank(CHAIN_1_MERKL_TREE_UPDATER_EOA);
        IDistributor(MERKL_DISTRIBUTOR).updateTree(IDistributor.MerkleTree({ merkleRoot: root, ipfsHash: "" }));
        vm.stopPrank();
        // advance time for the new tree to become active
        vm.warp(block.timestamp + 100 days);

        // deal some tokens
        deal(address(asset), address(MERKL_DISTRIBUTOR), 10e6);

        // execute hooks
        // - claim
        // - deposit usdc
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        address claimHookAddress = _getHookAddress(ETH, MERKL_CLAIM_REWARD_HOOK_KEY);

        address[] memory hooksAddresses = new address[](2);
        bytes[] memory hooksData = new bytes[](2);

        // Setup hooks
        hooksAddresses[0] = claimHookAddress;
        hooksAddresses[1] = depositHookAddress;

        hooksData[0] = _createMerklClaimRewardHookData(tokens, amounts, proofs);
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            0,
            true,
            address(0),
            0
        );

        vm.mockCall(
            address(aggregator), abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector), abi.encode(true)
        );

        vm.startPrank(MANAGER);
        vm.expectRevert(BaseHook.AMOUNT_NOT_VALID.selector);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: new bytes32[][](2),
                strategyProofs: new bytes32[][](2)
            })
        );
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                       PRIVATE
    //////////////////////////////////////////////////////////////*/
    function _depositAndSwapWithCustomRatios(
        uint256 fullAmount,
        address assetToDeposit,
        address strat,
        address vault1,
        address vault2,
        uint256 ratio1,
        uint256 ratio2
    )
        private
    {
        RatioCalculationVars memory ratioVars;
        ratioVars.totalRatio = ratio1 + ratio2;
        ratioVars.vaultAllocation = fullAmount * 70 / 100; // Reserve 70% for vaults, 30% for swap
        ratioVars.vault1Amount = ratioVars.vaultAllocation * ratio1 / ratioVars.totalRatio;
        ratioVars.vault2Amount = ratioVars.vaultAllocation * ratio2 / ratioVars.totalRatio;
        ratioVars.yieldSourceOracleId =
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER);

        // Ensure no underflow in swapAmount calculation
        assert(fullAmount >= ratioVars.vaultAllocation);

        DepositAndSwapParams memory params = DepositAndSwapParams({
            fullAmount: fullAmount,
            assetToDeposit: assetToDeposit,
            strat: strat,
            vault1: vault1,
            vault2: vault2,
            depositHookAddress: _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY),
            approveAndSwapOdos: approveAndSwapOdosHookAddressETH,
            fullDepositAmount: ratioVars.vault1Amount,
            halfAmount: ratioVars.vault2Amount,
            swapAmount: fullAmount - ratioVars.vaultAllocation
        });

        ExecutionArrays memory arrays = ExecutionArrays({
            executeHookAddresses: new address[](3),
            executeHooksData: new bytes[](3),
            expectedAssetsOrSharesOut: new uint256[](3),
            argsForProofs: new bytes[](3)
        });

        arrays.executeHookAddresses[0] = params.depositHookAddress;
        arrays.executeHookAddresses[1] = params.depositHookAddress;
        arrays.executeHookAddresses[2] = params.approveAndSwapOdos;

        arrays.executeHooksData[0] = _createApproveAndDeposit4626HookData(
            ratioVars.yieldSourceOracleId,
            params.vault1,
            params.assetToDeposit,
            ratioVars.vault1Amount,
            false,
            address(0),
            0
        );

        arrays.executeHooksData[1] = _createApproveAndDeposit4626HookData(
            ratioVars.yieldSourceOracleId,
            params.vault2,
            params.assetToDeposit,
            ratioVars.vault2Amount,
            false,
            address(0),
            0
        );

        _processSwapData(params, arrays);

        arrays.expectedAssetsOrSharesOut[0] = IERC4626(address(params.vault1)).convertToShares(ratioVars.vault1Amount);
        arrays.expectedAssetsOrSharesOut[1] = IERC4626(address(params.vault2)).convertToShares(ratioVars.vault2Amount);

        // Ensure convertToShares returned valid values
        assert(arrays.expectedAssetsOrSharesOut[0] > 0);
        assert(arrays.expectedAssetsOrSharesOut[1] > 0);

        for (uint256 i; i < arrays.expectedAssetsOrSharesOut.length; i++) {
            // Apply slippage tolerance (0.1%)
            arrays.expectedAssetsOrSharesOut[i] =
                arrays.expectedAssetsOrSharesOut[i] * (1e5 - 1e3) / 1e5;
        }

        arrays.argsForProofs[0] =
            ISuperHookInspector(arrays.executeHookAddresses[0]).inspect(arrays.executeHooksData[0]);
        arrays.argsForProofs[1] =
            ISuperHookInspector(arrays.executeHookAddresses[1]).inspect(arrays.executeHooksData[1]);
        arrays.argsForProofs[2] =
            ISuperHookInspector(arrays.executeHookAddresses[2]).inspect(arrays.executeHooksData[2]);

        vm.mockCall(
            address(aggregator), abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector), abi.encode(true)
        );

        vm.startPrank(MANAGER);
        ISuperVaultStrategy(payable(params.strat))
            .executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: arrays.executeHookAddresses,
                    hookCalldata: arrays.executeHooksData,
                    expectedAssetsOrSharesOut: arrays.expectedAssetsOrSharesOut,
                    globalProofs: new bytes32[][](3),
                    strategyProofs: new bytes32[][](3)
                })
            );
        vm.stopPrank();
    }

    function _depositAndSwap(
        uint256 fullAmount,
        address assetToDeposit,
        address strat,
        address vault1,
        address vault2
    )
        private
    {
        RatioCalculationVars memory ratioVars;
        ratioVars.vaultAllocation = fullAmount / 2;
        ratioVars.vault1Amount = ratioVars.vaultAllocation / 2;

        // Ensure no underflow in vault2Amount calculation
        assert(ratioVars.vaultAllocation >= ratioVars.vault1Amount);
        ratioVars.vault2Amount = ratioVars.vaultAllocation - ratioVars.vault1Amount;

        ratioVars.yieldSourceOracleId =
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER);

        // Ensure no underflow in swapAmount calculation
        assert(fullAmount >= ratioVars.vaultAllocation);

        DepositAndSwapParams memory params = DepositAndSwapParams({
            fullAmount: fullAmount,
            assetToDeposit: assetToDeposit,
            strat: strat,
            vault1: vault1,
            vault2: vault2,
            depositHookAddress: _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY),
            approveAndSwapOdos: approveAndSwapOdosHookAddressETH,
            fullDepositAmount: ratioVars.vaultAllocation,
            halfAmount: ratioVars.vault1Amount,
            swapAmount: fullAmount - ratioVars.vaultAllocation
        });

        ExecutionArrays memory arrays = ExecutionArrays({
            executeHookAddresses: new address[](3),
            executeHooksData: new bytes[](3),
            expectedAssetsOrSharesOut: new uint256[](3),
            argsForProofs: new bytes[](3)
        });

        arrays.executeHookAddresses[0] = params.depositHookAddress;
        arrays.executeHookAddresses[1] = params.depositHookAddress;
        arrays.executeHookAddresses[2] = params.approveAndSwapOdos;

        arrays.executeHooksData[0] = _createApproveAndDeposit4626HookData(
            ratioVars.yieldSourceOracleId,
            params.vault1,
            params.assetToDeposit,
            ratioVars.vault1Amount,
            false,
            address(0),
            0
        );

        arrays.executeHooksData[1] = _createApproveAndDeposit4626HookData(
            ratioVars.yieldSourceOracleId,
            params.vault2,
            params.assetToDeposit,
            ratioVars.vault2Amount,
            false,
            address(0),
            0
        );

        _processSwapData(params, arrays);

        arrays.expectedAssetsOrSharesOut[0] = IERC4626(address(params.vault1)).convertToShares(ratioVars.vault1Amount);
        arrays.expectedAssetsOrSharesOut[1] = IERC4626(address(params.vault2)).convertToShares(ratioVars.vault2Amount);

        // Ensure convertToShares returned valid values
        assert(arrays.expectedAssetsOrSharesOut[0] > 0);
        assert(arrays.expectedAssetsOrSharesOut[1] > 0);

        for (uint256 i; i < arrays.expectedAssetsOrSharesOut.length; i++) {
            // Apply slippage tolerance (0.1%)
            arrays.expectedAssetsOrSharesOut[i] =
                arrays.expectedAssetsOrSharesOut[i] * (1e5 - 1e3) / 1e5;
        }

        arrays.argsForProofs[0] =
            ISuperHookInspector(arrays.executeHookAddresses[0]).inspect(arrays.executeHooksData[0]);
        arrays.argsForProofs[1] =
            ISuperHookInspector(arrays.executeHookAddresses[1]).inspect(arrays.executeHooksData[1]);
        arrays.argsForProofs[2] =
            ISuperHookInspector(arrays.executeHookAddresses[2]).inspect(arrays.executeHooksData[2]);

        vm.mockCall(
            address(aggregator), abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector), abi.encode(true)
        );

        vm.startPrank(MANAGER);
        ISuperVaultStrategy(payable(params.strat))
            .executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: arrays.executeHookAddresses,
                    hookCalldata: arrays.executeHooksData,
                    expectedAssetsOrSharesOut: arrays.expectedAssetsOrSharesOut,
                    globalProofs: new bytes32[][](3),
                    strategyProofs: new bytes32[][](3)
                })
            );
        vm.stopPrank();
    }

    function _processSwapData(DepositAndSwapParams memory params, ExecutionArrays memory arrays) private {
        SwapProcessingVars memory swapVars;

        swapVars.quoteInputTokens = new QuoteInputToken[](1);
        swapVars.quoteInputTokens[0] =
            QuoteInputToken({ tokenAddress: params.assetToDeposit, amount: params.swapAmount });
        swapVars.quoteOutputTokens = new QuoteOutputToken[](1);
        swapVars.quoteOutputTokens[0] = QuoteOutputToken({ tokenAddress: CHAIN_1_USDT, proportion: 1 });

        if (useRealOdosRouter) {
            swapVars.path =
                surlCallQuoteV2(swapVars.quoteInputTokens, swapVars.quoteOutputTokens, params.strat, ETH, true);
            swapVars.requestBody = surlCallAssemble(swapVars.path, params.strat);

            swapVars.odosDecodedSwap = decodeOdosSwapCalldata(fromHex(swapVars.requestBody));
            swapVars.odosCalldata = _createOdosSwapHookData(
                swapVars.odosDecodedSwap.tokenInfo.inputToken,
                swapVars.odosDecodedSwap.tokenInfo.inputAmount,
                swapVars.odosDecodedSwap.tokenInfo.inputReceiver,
                swapVars.odosDecodedSwap.tokenInfo.outputToken,
                swapVars.odosDecodedSwap.tokenInfo.outputQuote,
                swapVars.odosDecodedSwap.tokenInfo.outputMin * (1e5 - 1e4) / 1e5,
                swapVars.odosDecodedSwap.pathDefinition,
                swapVars.odosDecodedSwap.executor,
                swapVars.odosDecodedSwap.referralCode,
                false
            );
            arrays.executeHooksData[2] = swapVars.odosCalldata;
            arrays.expectedAssetsOrSharesOut[2] = swapVars.odosDecodedSwap.tokenInfo.outputQuote;
        } else {
            // Mock scenario: deal tokens to mock router and create simplified calldata
            deal(CHAIN_1_USDT, address(odosRouter), params.swapAmount);

            // Calculate outputMin safely to prevent underflow
            uint256 slippageFactor = params.swapAmount * 1e4 / 1e5; // 10% slippage
            assert(params.swapAmount >= slippageFactor);
            uint256 outputMin = params.swapAmount - slippageFactor;

            swapVars.odosCalldata = _createOdosSwapHookData(
                params.assetToDeposit,
                params.swapAmount,
                odosRouterAddress,
                CHAIN_1_USDT,
                params.swapAmount,
                outputMin,
                bytes(""),
                address(0),
                0,
                false
            );
            arrays.executeHooksData[2] = swapVars.odosCalldata;
            arrays.expectedAssetsOrSharesOut[2] = params.swapAmount;
        }
    }
}
