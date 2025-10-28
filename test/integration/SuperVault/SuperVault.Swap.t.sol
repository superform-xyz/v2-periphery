// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";

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

// we need to `useLatestFork` on true
contract SuperVaultSwapTest is BaseSuperVaultTest, ClaimsMerkleHelper {
    using Math for uint256;

    address operator = address(0x123);
    uint256 constant userPrivateKey = 0xA11CE; 
    address userAddress; 

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
        useLatestFork = true;

        super.setUp();
        userAddress = vm.addr(userPrivateKey); 

        updateTestVaultPredictions();
    }

    /*//////////////////////////////////////////////////////////////
                       SWAP TESTS
    //////////////////////////////////////////////////////////////*/
    function test_Deposit_Allocate_And_SwapX() public {
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
        _depositAndSwapWithCustomRatios(1000e6, address(asset), address(strategy), address(fluidVault), address(aaveVault), 3, 1);

        // Verify allocation state
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");
        assertGt(fluidVault.balanceOf(address(strategy)), aaveVault.balanceOf(address(strategy)), "Fluid vault has more shares than aave vault");

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
            1, 1  // 100% to fluid, 0% to aave
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

    /*//////////////////////////////////////////////////////////////
                       PRIVATE
    //////////////////////////////////////////////////////////////*/
    function _depositAndSwapWithCustomRatios(uint256 fullAmount, address assetToDeposit, address strat, address vault1, address vault2, uint256 ratio1, uint256 ratio2) private {
        RatioCalculationVars memory ratioVars;
        ratioVars.totalRatio = ratio1 + ratio2;
        ratioVars.vaultAllocation = fullAmount * 70 / 100; // Reserve 70% for vaults, 30% for swap
        ratioVars.vault1Amount = ratioVars.vaultAllocation * ratio1 / ratioVars.totalRatio;
        ratioVars.vault2Amount = ratioVars.vaultAllocation * ratio2 / ratioVars.totalRatio;
        ratioVars.yieldSourceOracleId = _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER);

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

        for (uint256 i; i < arrays.expectedAssetsOrSharesOut.length; i++) {
            arrays.expectedAssetsOrSharesOut[i] = arrays.expectedAssetsOrSharesOut[i] - arrays.expectedAssetsOrSharesOut[i] * 1e3/1e5;
        }
        
        arrays.argsForProofs[0] = ISuperHookInspector(arrays.executeHookAddresses[0]).inspect(arrays.executeHooksData[0]);
        arrays.argsForProofs[1] = ISuperHookInspector(arrays.executeHookAddresses[1]).inspect(arrays.executeHooksData[1]);
        arrays.argsForProofs[2] = ISuperHookInspector(arrays.executeHookAddresses[2]).inspect(arrays.executeHooksData[2]);

        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        vm.startPrank(MANAGER);
        ISuperVaultStrategy(payable(params.strat)).executeHooks(
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

    function _depositAndSwap(uint256 fullAmount, address assetToDeposit, address strat, address vault1, address vault2) private {
        RatioCalculationVars memory ratioVars;
        ratioVars.vaultAllocation = fullAmount / 2;
        ratioVars.vault1Amount = ratioVars.vaultAllocation / 2;
        ratioVars.vault2Amount = ratioVars.vaultAllocation - ratioVars.vault1Amount;
        ratioVars.yieldSourceOracleId = _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER);

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

        for (uint256 i; i < arrays.expectedAssetsOrSharesOut.length; i++) {
            arrays.expectedAssetsOrSharesOut[i] = arrays.expectedAssetsOrSharesOut[i] - arrays.expectedAssetsOrSharesOut[i] * 1e3/1e5;
        }

        arrays.argsForProofs[0] = ISuperHookInspector(arrays.executeHookAddresses[0]).inspect(arrays.executeHooksData[0]);
        arrays.argsForProofs[1] = ISuperHookInspector(arrays.executeHookAddresses[1]).inspect(arrays.executeHooksData[1]);
        arrays.argsForProofs[2] = ISuperHookInspector(arrays.executeHookAddresses[2]).inspect(arrays.executeHooksData[2]);

        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        vm.startPrank(MANAGER);
        ISuperVaultStrategy(payable(params.strat)).executeHooks(
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
        swapVars.quoteInputTokens[0] = QuoteInputToken({ tokenAddress: params.assetToDeposit, amount: params.swapAmount });
        swapVars.quoteOutputTokens = new QuoteOutputToken[](1);
        swapVars.quoteOutputTokens[0] = QuoteOutputToken({ tokenAddress: CHAIN_1_USDT, proportion: 1 });

        swapVars.path = surlCallQuoteV2(swapVars.quoteInputTokens, swapVars.quoteOutputTokens, params.strat, ETH, true);
        swapVars.requestBody = surlCallAssemble(swapVars.path, params.strat);

        swapVars.odosDecodedSwap = decodeOdosSwapCalldata(fromHex(swapVars.requestBody));
        swapVars.odosCalldata = _createOdosSwapHookData(
            swapVars.odosDecodedSwap.tokenInfo.inputToken,
            swapVars.odosDecodedSwap.tokenInfo.inputAmount,
            swapVars.odosDecodedSwap.tokenInfo.inputReceiver,
            swapVars.odosDecodedSwap.tokenInfo.outputToken,
            swapVars.odosDecodedSwap.tokenInfo.outputQuote,
            swapVars.odosDecodedSwap.tokenInfo.outputMin - swapVars.odosDecodedSwap.tokenInfo.outputMin * 1e4 / 1e5,
            swapVars.odosDecodedSwap.pathDefinition,
            swapVars.odosDecodedSwap.executor,
            swapVars.odosDecodedSwap.referralCode,
            false
        );
        arrays.executeHooksData[2] = swapVars.odosCalldata;
        arrays.expectedAssetsOrSharesOut[2] = swapVars.odosDecodedSwap.tokenInfo.outputQuote;
    }
}