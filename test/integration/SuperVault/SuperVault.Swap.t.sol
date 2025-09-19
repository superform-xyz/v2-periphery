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

// we need to `useLatestFork` on true
contract SuperVaultSwapTest is BaseSuperVaultTest {
    using Math for uint256;

    address operator = address(0x123);
    uint256 constant userPrivateKey = 0xA11CE; // Replace with a known good testing private key
    address userAddress; // Will be derived from private key

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


    function setUp() public override {
        useLatestFork = true;

        super.setUp();
        userAddress = vm.addr(userPrivateKey); // Derive the correct address from private key

        // Update test vault predictions with correct deployer address (this contract)
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
        // Calculate amounts based on ratios
        uint256 totalRatio = ratio1 + ratio2;
        uint256 vaultAllocation = fullAmount * 70 / 100; // Reserve 70% for vaults, 30% for swap
        uint256 vault1Amount = vaultAllocation * ratio1 / totalRatio;
        uint256 vault2Amount = vaultAllocation * ratio2 / totalRatio;
        uint256 swapAmount = fullAmount - vaultAllocation; // 30% for swap

        DepositAndSwapParams memory params = DepositAndSwapParams({
            fullAmount: fullAmount,
            assetToDeposit: assetToDeposit,
            strat: strat,
            vault1: vault1,
            vault2: vault2,
            depositHookAddress: _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY),
            approveAndSwapOdos: approveAndSwapOdosHookAddressETH,
            fullDepositAmount: vault1Amount,
            halfAmount: vault2Amount,
            swapAmount: swapAmount
        });

        address[] memory executeHookAddresses = new address[](3);
        executeHookAddresses[0] = params.depositHookAddress;
        executeHookAddresses[1] = params.depositHookAddress;
        executeHookAddresses[2] = params.approveAndSwapOdos;

        bytes[] memory executeHooksData = new bytes[](3);
        
        executeHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            params.vault1,
            params.assetToDeposit,
            vault1Amount,
            false,
            address(0),
            0
        );

        executeHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            params.vault2,
            params.assetToDeposit,
            vault2Amount,
            false,
            address(0),
            0
        );

        // --swap data
        QuoteInputToken[] memory quoteInputTokens = new QuoteInputToken[](1);
        quoteInputTokens[0] = QuoteInputToken({ tokenAddress: params.assetToDeposit, amount: params.swapAmount });
        QuoteOutputToken[] memory quoteOutputTokens = new QuoteOutputToken[](1);
        quoteOutputTokens[0] = QuoteOutputToken({ tokenAddress: CHAIN_1_USDT, proportion: 1 });

        string memory path = surlCallQuoteV2(quoteInputTokens, quoteOutputTokens, params.strat, ETH, true);
        string memory requestBody = surlCallAssemble(path, params.strat);

        OdosDecodedSwap memory odosDecodedSwap = decodeOdosSwapCalldata(fromHex(requestBody));
        bytes memory odosCalldata = _createOdosSwapHookData(
            odosDecodedSwap.tokenInfo.inputToken,
            odosDecodedSwap.tokenInfo.inputAmount,
            odosDecodedSwap.tokenInfo.inputReceiver,
            odosDecodedSwap.tokenInfo.outputToken,
            odosDecodedSwap.tokenInfo.outputQuote,
            odosDecodedSwap.tokenInfo.outputMin - odosDecodedSwap.tokenInfo.outputMin * 1e4 / 1e5,
            odosDecodedSwap.pathDefinition,
            odosDecodedSwap.executor,
            odosDecodedSwap.referralCode,
            false
        );
        executeHooksData[2] = odosCalldata;

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](3);
        expectedAssetsOrSharesOut[0] = IERC4626(address(params.vault1)).convertToShares(vault1Amount);
        expectedAssetsOrSharesOut[1] = IERC4626(address(params.vault2)).convertToShares(vault2Amount);
        expectedAssetsOrSharesOut[2] = odosDecodedSwap.tokenInfo.outputQuote;

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(executeHookAddresses[0]).inspect(executeHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(executeHookAddresses[1]).inspect(executeHooksData[1]);
        argsForProofs[2] = ISuperHookInspector(executeHookAddresses[2]).inspect(executeHooksData[2]);

        // TODO: REMOVE 
        vm.mockCall(
            address(aggregator),
            abi.encodeWithSelector(ISuperVaultAggregator.validateHook.selector),
            abi.encode(true)
        );

        vm.startPrank(MANAGER);
        ISuperVaultStrategy(payable(params.strat)).executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: executeHookAddresses,
                hookCalldata: executeHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: new bytes32[][](3),
                strategyProofs: new bytes32[][](3)
            })
        );
        vm.stopPrank();
    }

    function _depositAndSwap(uint256 fullAmount, address assetToDeposit, address strat, address vault1, address vault2) private {
        DepositAndSwapParams memory params = DepositAndSwapParams({
            fullAmount: fullAmount,
            assetToDeposit: assetToDeposit,
            strat: strat,
            vault1: vault1,
            vault2: vault2,
            depositHookAddress: _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY),
            approveAndSwapOdos: approveAndSwapOdosHookAddressETH,
            fullDepositAmount: fullAmount / 2,
            halfAmount: (fullAmount / 2) / 2,
            swapAmount: fullAmount - (fullAmount / 2)
        });

        address[] memory executeHookAddresses = new address[](3);
        executeHookAddresses[0] = params.depositHookAddress;
        executeHookAddresses[1] = params.depositHookAddress;
        executeHookAddresses[2] = params.approveAndSwapOdos;

        bytes[] memory executeHooksData = new bytes[](3);
        
        executeHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            params.vault1,
            params.assetToDeposit,
            params.halfAmount,
            false,
            address(0),
            0
        );

        executeHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            params.vault2,
            params.assetToDeposit,
            params.fullDepositAmount - params.halfAmount,
            false,
            address(0),
            0
        );

        // --swap data
        QuoteInputToken[] memory quoteInputTokens = new QuoteInputToken[](1);
        quoteInputTokens[0] = QuoteInputToken({ tokenAddress: params.assetToDeposit, amount: params.swapAmount });
        QuoteOutputToken[] memory quoteOutputTokens = new QuoteOutputToken[](1);
        quoteOutputTokens[0] = QuoteOutputToken({ tokenAddress: CHAIN_1_USDT, proportion: 1 });

        string memory path = surlCallQuoteV2(quoteInputTokens, quoteOutputTokens, params.strat, ETH, true);
        string memory requestBody = surlCallAssemble(path, params.strat);

        OdosDecodedSwap memory odosDecodedSwap = decodeOdosSwapCalldata(fromHex(requestBody));
        bytes memory odosCalldata = _createOdosSwapHookData(
            odosDecodedSwap.tokenInfo.inputToken,
            odosDecodedSwap.tokenInfo.inputAmount,
            odosDecodedSwap.tokenInfo.inputReceiver,
            odosDecodedSwap.tokenInfo.outputToken,
            odosDecodedSwap.tokenInfo.outputQuote,
            odosDecodedSwap.tokenInfo.outputMin - odosDecodedSwap.tokenInfo.outputMin * 1e4 / 1e5,
            odosDecodedSwap.pathDefinition,
            odosDecodedSwap.executor,
            odosDecodedSwap.referralCode,
            false
        );
        executeHooksData[2] = odosCalldata;

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](3);
        expectedAssetsOrSharesOut[0] = IERC4626(address(params.vault1)).convertToShares(params.halfAmount);
        expectedAssetsOrSharesOut[1] = IERC4626(address(params.vault2)).convertToShares(params.fullDepositAmount - params.halfAmount);
        expectedAssetsOrSharesOut[2] = odosDecodedSwap.tokenInfo.outputQuote;

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(executeHookAddresses[0]).inspect(executeHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(executeHookAddresses[1]).inspect(executeHooksData[1]);
        argsForProofs[2] = ISuperHookInspector(executeHookAddresses[2]).inspect(executeHooksData[2]);

        vm.startPrank(MANAGER);
        ISuperVaultStrategy(payable(params.strat)).executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: executeHookAddresses,
                hookCalldata: executeHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(executeHookAddresses, argsForProofs),
                strategyProofs: new bytes32[][](3)
            })
        );
        vm.stopPrank();
    }
}
