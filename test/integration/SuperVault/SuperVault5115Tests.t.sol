// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";

// external
import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

// superform
import { IStandardizedYield } from "@superform-v2-core/src/vendor/pendle/IStandardizedYield.sol";

import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IERC7540Redeem, IERC7741 } from "../../../src/vendor/standards/ERC7540/IERC7540Vault.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ERC7540YieldSourceOracle } from "@superform-v2-core/test/mocks/unused-oracles/ERC7540YieldSourceOracle.sol";
import { ERC5115YieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/ERC5115YieldSourceOracle.sol";
import { ISuperLedger } from "@superform-v2-core/src/interfaces/accounting/ISuperLedger.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { IGearboxFarmingPool } from "../../vendor/gearbox/IGearboxFarmingPool.sol";
import { ISuperExecutor } from "@superform-v2-core/src/interfaces/ISuperExecutor.sol";
import { AccountInstance, UserOpData } from "modulekit/ModuleKit.sol";
import { Mock4626Vault } from "../../mocks/Mock4626Vault.sol";
import { RuggableVault } from "../../mocks/RuggableVault.sol";
import { RuggableConvertVault } from "../../mocks/RuggableConvertVault.sol";
import { MockNativeETHHook } from "../../mocks/MockNativeETHHook.sol";
import { MockETHReceiver } from "../../mocks/MockETHReceiver.sol";
import { Create2 } from "openzeppelin-contracts/contracts/utils/Create2.sol";

contract SuperVault5115Tests is BaseSuperVaultTest {
    using Math for uint256;

    address operator = address(0x123);
    uint256 constant userPrivateKey = 0xA11CE;
    address userAddress;

    // super vaults
    ERC5115YieldSourceOracle public oracle5115;
    SuperVault sv5115;
    SuperVaultEscrow escrow5115SuperVault;
    SuperVaultStrategy strategy5115SuperVault;

    function setUp() public override {
        super.setUp();
        userAddress = vm.addr(userPrivateKey); // Derive the correct address from private key

        vm.selectFork(FORKS[ETH]);

        superLedgerETH = ISuperLedger(_getContract(ETH, SUPER_LEDGER_KEY));
        oracle5115 = ERC5115YieldSourceOracle(_getContract(ETH, ERC5115_YIELD_SOURCE_ORACLE_KEY));
    }

    function _setup5115Vault() internal {
        // Deploy vault trio
        (address svAddr, address strategySuperVaultAddr, address escrowSuperVaultAddr) =
            _deployVault(address(asset5115), "sv5115");

        //todo define
        assertEq(strategySuperVaultAddr, globalSV5115Strategy, "SV STRATEGY NOT EQUAL TO PREDICTED");

        vm.label(svAddr, "SuperVault-5115");
        vm.label(strategySuperVaultAddr, "SuperVaultStrategy-5115");
        vm.label(escrowSuperVaultAddr, "SuperVaultEscrow-5115");

        // Cast addresses to contract types
        sv5115 = SuperVault(svAddr);
        escrow5115SuperVault = SuperVaultEscrow(escrowSuperVaultAddr);
        strategy5115SuperVault = SuperVaultStrategy(payable(strategySuperVaultAddr));

        // Add a new yield source as manager
        vm.startPrank(MANAGER);
        strategy5115SuperVault.manageYieldSource(
            address(pendleEthenaAddress), _getContract(ETH, ERC5115_YIELD_SOURCE_ORACLE_KEY), 0
        );
        vm.stopPrank();

        vm.startPrank(MANAGER);
        strategy5115SuperVault.proposeVaultFeeConfigUpdate(100, 0, TREASURY);
        vm.warp(block.timestamp + 1 weeks);
        strategy5115SuperVault.executeVaultFeeConfigUpdate();
        vm.stopPrank();

        vm.startPrank(MANAGER);
        strategy5115SuperVault.managePPSExpiration(1, 86_400); // 1 day
        strategy.managePPSExpiration(1, 86_400); // 1 day

        vm.warp(block.timestamp + 2 weeks);

        strategy5115SuperVault.managePPSExpiration(2, 0);
        strategy.managePPSExpiration(2, 0);
        vm.stopPrank();

        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        _updateSuperVaultPPS(address(strategy), address(vault));
    }

    function test_5115_Name() public {
        _setup5115Vault();
        string memory name = sv5115.name();
        assertEq(name, "SuperVault");
    }

    function test_5115_Symbol() public {
        _setup5115Vault();
        string memory symbol = sv5115.symbol();
        assertEq(symbol, "sv5115");
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT & ALLOCATE TESTS
    //////////////////////////////////////////////////////////////*/
    function test_Deposit5115() public {
        vm.selectFork(FORKS[ETH]);

        _setup5115Vault();

        uint256 sharesBefore = sv5115.balanceOf(accountEth);
        assertEq(sharesBefore, 0, "User has shares before deposit");

        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount, address(sv5115), address(asset5115));

        // Verify state
        uint256 userShares = sv5115.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset5115.balanceOf(address(strategy5115SuperVault)), depositAmount, "Wrong strategy balance");

        // Verify shares were minted immediately
        uint256 sharesAfter = sv5115.balanceOf(accountEth);
        assertGt(sharesAfter, 0, "No shares minted to user");
    }

    function test_Deposit5115_AndAllocate() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount, address(sv5115), address(asset5115));

        // Allocate the assets to yield sources
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        // Verify allocation state
        assertGt(pendleEthena.balanceOf(address(strategy5115SuperVault)), 0, "No shares allocated");
    }

    function test_Deposit5115_AndAllocateToYieldViaSmartAccountManager() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        vm.selectFork(FORKS[ETH]);

        // Deploy a new SuperVault with a smart account manager
        AccountInstance memory managerAccount = accInstances[1]; // Use a different account as manager
        _getTokens(address(asset5115), managerAccount.account, 1 ether); // Fund the manager account

        vm.prank(managerAccount.account);
        aggregator.updateVaultCreationConsent(true);

        // Deploy vault with smart account manager
        (address newVaultAddr, address newStrategyAddr,) =
            _deployVaultWithSmartAccountManager(managerAccount.account, address(asset5115), "SA-5115", "SA-5115");

        string memory _name = SuperVault(newVaultAddr).name();
        assertEq(_name, "SA-5115");

        string memory _symbol = SuperVault(newVaultAddr).symbol();
        assertEq(_symbol, "SA-5115");

        SuperVault newVault = SuperVault(newVaultAddr);
        SuperVaultStrategy newStrategy = SuperVaultStrategy(payable(newStrategyAddr));

        // Setup yield sources for the new strategy via smart account
        _manageYieldSourcesViaSmartAccount(managerAccount, newStrategy);

        // Direct deposit to the new vault
        _deposit(depositAmount, newVaultAddr, address(asset5115));

        // Verify deposit state
        uint256 userShares = newVault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset5115.balanceOf(address(newStrategy)), depositAmount, "Wrong strategy balance");

        // Allocate the assets to yield sources via smart account manager
        _depositFreeAssetsFromSingleAmountViaSmartAccount5115(
            depositAmount, pendleEthenaAddress, managerAccount, newStrategy
        );

        // Verify allocation state
        assertGt(pendleEthena.balanceOf(address(newStrategy)), 0, "No shares allocated");

        // Verify that the strategy has no free assets left
        assertEq(asset5115.balanceOf(address(newStrategy)), 0, "Strategy should have no free assets after allocation");
    }

    function test_DepositAndAllocateTo5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6; // 1000 USDC

        // Setup and fulfill deposit
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        // Verify state
        uint256 userShares = sv5115.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");

        // Verify allocation
        assertGt(pendleEthena.balanceOf(address(strategy5115SuperVault)), 0, "No shares allocated");
    }

    /*//////////////////////////////////////////////////////////////
                        REDEEM TESTS
    //////////////////////////////////////////////////////////////*/
    function test_RequestRedeem5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        // Request redemption
        uint256 vaultBalance = sv5115.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);
        _requestRedeem(redeemShares, address(sv5115));

        // Verify state
        assertEq(strategy5115SuperVault.pendingRedeemRequest(accountEth), redeemShares, "Wrong pending redeem amount");
        assertEq(sv5115.balanceOf(address(escrow5115SuperVault)), redeemShares, "Wrong escrow balance");
    }

    function test_FulfillRedeem_FullAmountWithThreshold5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6;

        // Deposit and allocate to yield
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);
        uint256 vaultBalance = sv5115.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);
        _requestRedeem(redeemShares, address(sv5115));
        _fulfillRedeem5115(redeemShares, address(sv5115), address(strategy5115SuperVault));

        // Verify state
        assertEq(strategy5115SuperVault.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy5115SuperVault.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_FulfillRedeem_FullAmount() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        // Request redemption
        uint256 vaultBalance = sv5115.balanceOf(accountEth);
        _requestRedeem(vaultBalance, address(sv5115));
        _fulfillRedeem5115(vaultBalance, address(sv5115), address(strategy5115SuperVault));

        // Verify state
        assertEq(strategy5115SuperVault.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy5115SuperVault.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_ClaimRedeem5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6; // 1000 USDC
        uint256 initialAssetBalance = asset5115.balanceOf(address(accountEth));
        console2.log("-------------- initialAssetBalance user", initialAssetBalance);

        // Deposit and allocate to yield
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);
        console2.log(
            "-------------- balance strategy after deposit ", asset5115.balanceOf(address(strategy5115SuperVault))
        );

        // Get balances after deposit
        uint256 assetBalanceAfterDeposit = asset5115.balanceOf(accountEth);
        uint256 initialShares = sv5115.balanceOf(accountEth);
        console2.log("-------------- initialAssetBalance user", assetBalanceAfterDeposit);
        console2.log("-------------- initialShares user", initialShares);
        console2.log(
            "-------------- balance strategy after redeem ", asset5115.balanceOf(address(strategy5115SuperVault))
        );

        // Request redeem of half the shares
        uint256 redeemShares = initialShares / 2;
        _requestRedeem(redeemShares, address(sv5115));
        _fulfillRedeem5115(redeemShares, address(sv5115), address(strategy5115SuperVault));
        console2.log(
            "-------------- balance strategy after redeem ", asset5115.balanceOf(address(strategy5115SuperVault))
        );

        // Get claimable assets
        uint256 claimableAssets = strategy5115SuperVault.claimableWithdraw(accountEth);
        console2.log("-------------- claimableAssets user", claimableAssets);

        // Claim redeem
        _claimWithdraw5115(claimableAssets, address(sv5115));

        // Verify state
        assertEq(sv5115.balanceOf(accountEth), initialShares - redeemShares, "Wrong final share balance");
        assertApproxEqRel(
            asset5115.balanceOf(accountEth), initialAssetBalance + claimableAssets, 0.05e18, "Wrong final asset balance"
        );
        assertEq(strategy5115SuperVault.claimableWithdraw(accountEth), 0, "Assets not claimed");
    }

    /*//////////////////////////////////////////////////////////////
                        ROUNDING & PPS TESTS
    //////////////////////////////////////////////////////////////*/
    function test_ConvertToShares5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 assetsAmount = 1000e6; // 1000 USDC

        // With fresh vault (1:1 ratio), should convert directly
        uint256 shares = sv5115.convertToShares(assetsAmount);
        assertEq(shares, assetsAmount, "Initial share conversion should be 1:1");

        // Make a deposit to ensure PPS is established
        _deposit(assetsAmount, address(sv5115), address(asset5115));

        // Should still be approximately 1:1 after initial deposit
        uint256 sharesAfter = sv5115.convertToShares(assetsAmount);
        assertApproxEqRel(sharesAfter, assetsAmount, 0.01e18, "Share conversion should be close to 1:1");
    }

    function test_ConvertToAssets5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 sharesAmount = 1000e6; // 1000 shares

        // With fresh vault (1:1 ratio), should convert directly
        uint256 assets = sv5115.convertToAssets(sharesAmount);
        assertEq(assets, sharesAmount, "Initial asset conversion should be 1:1");

        // Make a deposit to ensure PPS is established
        _deposit(2000e6); // 2000 USDC deposit

        // Should still be approximately 1:1 after initial deposit
        uint256 assetsAfter = sv5115.convertToAssets(sharesAmount);
        assertApproxEqRel(assetsAfter, sharesAmount, 0.01e18, "Asset conversion should be close to 1:1");
    }

    function test_Convert_VariousEdgeCases_AndInvalidPPS_5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        vm.warp(block.timestamp + 1 weeks);

        // Get the PPS before trying to set it to 0
        uint256 ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));
        assertGt(ppsBefore, 0, "Initial PPS should be greater than 0");

        // Attempt to set PPS to 0 using the actual PPS update mechanism - this will pause and mark stale
        _updateSuperVaultPPS_ToZero(address(strategy5115SuperVault));

        // Verify strategy is paused
        assertTrue(
            aggregator.isStrategyPaused(address(strategy5115SuperVault)),
            "Strategy should be paused after zero PPS attempt"
        );

        // Verify that PPS was NOT stored (protection for external integrators)
        uint256 ppsAfterAttempt = aggregator.getPPS(address(strategy5115SuperVault));
        assertEq(ppsAfterAttempt, ppsBefore, "PPS should remain at old value (zero PPS never stored)");

        // Unpause the strategy to enable the escape hatch (C1 check will be skipped)
        vm.prank(MANAGER);
        aggregator.unpauseStrategy(address(strategy5115SuperVault));

        // Advance time to ensure monotonic timestamp
        vm.warp(block.timestamp + 10);

        // Send fresh PPS update with 0 - C1 check will be skipped because ppsStale is true
        // BUT PPS will still not be stored because args.pps == 0
        _updateSuperVaultPPS_ToZero(address(strategy5115SuperVault));

        // Verify PPS is STILL at the old value (security: zero PPS can never be stored)
        uint256 ppsAfterEscapeHatch = aggregator.getPPS(address(strategy5115SuperVault));
        assertEq(ppsAfterEscapeHatch, ppsBefore, "PPS should remain at old value even with escape hatch");

        uint256 testAssets = 1000e6; // 1000 USDC
        uint256 testShares = 1000e6; // 1000 shares

        // Test convertToShares with the OLD PPS (not zero, because zero PPS is never stored)
        uint256 resultShares = sv5115.convertToShares(testAssets);
        assertGt(resultShares, 0, "convertToShares should use old PPS value");

        // Test convertToAssets with the OLD PPS
        uint256 resultAssets = sv5115.convertToAssets(testShares);
        assertGt(resultAssets, 0, "convertToAssets should use old PPS value");

        // Test totalAssets - should be based on old PPS
        uint256 totalAssets = sv5115.totalAssets();
        console2.log("totalAssets with old PPS:", totalAssets);

        // Test edge cases with zero inputs
        assertEq(sv5115.convertToShares(0), 0, "convertToShares(0) should return 0");
        assertEq(sv5115.convertToAssets(0), 0, "convertToAssets(0) should return 0");

        // Verify that operations requiring valid PPS should fail due to PAUSED status
        deal(address(asset5115), address(this), testAssets);
        asset5115.approve(address(sv5115), testAssets);

        // Deposit should revert with STRATEGY_PAUSED (because strategy is paused, not because PPS is 0)
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        sv5115.deposit(testAssets, address(this));

        // Mint should also revert with STRATEGY_PAUSED (strategy is paused)
        vm.expectRevert(ISuperVaultStrategy.STRATEGY_PAUSED.selector);
        sv5115.mint(testShares, address(this));
    }

    /*//////////////////////////////////////////////////////////////
                        OTHER TESTS
    //////////////////////////////////////////////////////////////*/
    function test_AuthorizeOperator5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        // Create signature components
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        // Generate signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                sv5115.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(sv5115.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Debug logs
        console2.log("User Address:", userAddress);
        console2.log("Operator:", operator);
        console2.log("Digest:", uint256(digest));

        vm.prank(operator);
        bool success = sv5115.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        assertTrue(success, "Authorization failed");
        assertTrue(sv5115.isOperator(userAddress, operator), "Operator not authorized");
        assertTrue(sv5115.authorizations(userAddress, nonce), "Nonce not marked as used");
    }

    function test_TotalAssets5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6; // 1000 USDC

        // Check initial total assets
        uint256 initialTotalAssets = sv5115.totalAssets();
        assertEq(initialTotalAssets, 0, "Initial totalAssets should be 0");

        // Perform deposit
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        // Verify assets reported by totalAssets
        uint256 totalAssetsAfterDeposit = sv5115.totalAssets();
        assertApproxEqRel(
            totalAssetsAfterDeposit, depositAmount, 0.01e18, "totalAssets should approximately equal deposit"
        );
    }

    function test_Mint5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 mintShares = 1000e6; // 1000 shares
        uint256 expectedAssets = sv5115.previewMint(mintShares);

        // Approve assets for minting
        _getTokens(address(asset5115), accountEth, expectedAssets);
        vm.prank(accountEth);
        asset5115.approve(address(sv5115), expectedAssets);

        // Mint shares
        vm.prank(accountEth);
        uint256 assetsUsed = sv5115.mint(mintShares, accountEth);

        // Verify results
        assertEq(assetsUsed, expectedAssets, "Wrong amount of assets used");
        assertEq(sv5115.balanceOf(accountEth), mintShares, "Wrong shares balance");
        assertEq(asset5115.balanceOf(address(strategy5115SuperVault)), expectedAssets, "Wrong strategy asset balance");
    }

    function test_MaxMint5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 result = sv5115.maxMint(accountEth);

        // By default, should be proportional to maxDeposit
        uint256 maxDeposit = sv5115.maxDeposit(accountEth);
        uint256 expectedMax = sv5115.convertToShares(maxDeposit);

        assertEq(result, expectedMax, "maxMint should match shares equivalent of maxDeposit");
    }

    function test_MaxWithdraw5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        // User balance vs maxWithdraw before redemption
        uint256 userBalance = sv5115.balanceOf(accountEth);
        uint256 maxWithdraw = sv5115.maxWithdraw(accountEth);

        console2.log("----- userBalance", userBalance);
        console2.log("----- maxWithdraw", maxWithdraw);

        // Before fulfilling redeem request, maxWithdraw should be 0
        assertEq(maxWithdraw, 0, "maxWithdraw should be 0 before redemption is fulfilled");

        // Make and fulfill redeem request
        _requestRedeem(userBalance, address(sv5115));
        _fulfillRedeem5115(userBalance, address(sv5115), address(strategy5115SuperVault));

        uint256 claimable = strategy5115SuperVault.claimableWithdraw(accountEth);
        uint256 maxWithdrawAfter = sv5115.maxWithdraw(accountEth);
        assertEq(maxWithdrawAfter, claimable, "maxWithdraw should match claimable amount");
    }

    function test_MaxRedeem5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        // Initial deposit and allocation
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        // Before redemption request, maxRedeem should be 0 (no claimable assets)
        uint256 maxRedeemBefore = sv5115.maxRedeem(accountEth);
        assertEq(maxRedeemBefore, 0, "maxRedeem should be 0 before redemption request is fulfilled");

        // Request and fulfill redemption for half of shares
        uint256 userShares = sv5115.balanceOf(accountEth);
        uint256 redeemAmount = userShares / 2;
        _requestRedeem(redeemAmount, address(sv5115));
        _fulfillRedeem5115(redeemAmount, address(sv5115), address(strategy5115SuperVault));

        // After fulfillment, maxRedeem should match the shares equivalent to claimable assets
        uint256 claimableAssets = strategy5115SuperVault.claimableWithdraw(accountEth);
        uint256 maxRedeemAfter = sv5115.maxRedeem(accountEth);

        // Calculate expected shares based on claimable assets and average withdraw price
        uint256 avgWithdrawPrice = strategy5115SuperVault.getAverageWithdrawPrice(accountEth);
        // Use Math.Rounding.Ceil to match the contract's implementation
        uint256 expectedShares = claimableAssets.mulDiv(sv5115.PRECISION(), avgWithdrawPrice, Math.Rounding.Ceil);

        // Verify maxRedeem matches expected shares with sufficient tolerance
        assertApproxEqAbs(
            maxRedeemAfter, expectedShares, 10, "maxRedeem should match shares equivalent of claimable assets"
        );
    }

    function test_PreviewDepositAndMint5115() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        uint256 amount = 1000e6; // 1000 USDC/shares

        // Test previewDeposit (implemented)
        uint256 expectedShares = sv5115.convertToShares(amount);
        uint256 previewShares = sv5115.previewDeposit(amount);
        assertEq(previewShares, expectedShares, "previewDeposit should match convertToShares");

        // Test previewMint (implemented)
        uint256 expectedAssets = sv5115.convertToAssets(amount);
        uint256 previewAssets = sv5115.previewMint(amount);
        assertEq(previewAssets, expectedAssets, "previewMint should match convertToAssets");
    }

    /*//////////////////////////////////////////////////////////////
                        PPS TESTS
    //////////////////////////////////////////////////////////////*/
    struct PositiveAndNegativePpsVars {
        uint256 feeBalanceBefore;
        // PPS
        uint256 ppsBefore;
        uint256 ppsAfter;
        // Deposit amounts
        uint256 deposit1Amount;
        uint256 deposit2Amount;
        uint256 deposit3Amount;
        // Shares
        uint256 shares1;
        uint256 shares2;
        uint256 shares3;
        uint256 totalShares;
        // Redemption 1
        uint256 redeemAmount1;
        uint256 superformFee1;
        uint256 recipientFee1;
        uint256 totalFee1;
        uint256 userBalanceBeforeRedeem1;
        uint256 treasuryBalanceAfterRedeem1;
        uint256 claimableAssets1;
        uint256 userAssetsAfterRedeem1;
        // Redemption 2
        uint256 remainingShares;
        uint256 redeemAmount2;
        uint256 superformFee2;
        uint256 recipientFee2;
        uint256 totalFee2;
        uint256 userBalanceBeforeRedeem2;
        uint256 treasuryBalanceAfterRedeem2;
        uint256 claimableAssets2;
        uint256 userAssetsAfterRedeem2;
    }

    function test_SuperVault_5115_PositivePPS() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        PositiveAndNegativePpsVars memory vars;
        vars.deposit1Amount = 1000e6;
        vars.deposit2Amount = 2000e6;
        vars.deposit3Amount = 3000e6; // 3000 USDC

        // deposit 1
        deal(address(asset5115), accountEth, vars.deposit1Amount);
        _deposit(vars.deposit1Amount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(
            vars.deposit1Amount, address(strategy5115SuperVault), pendleEthenaAddress
        );

        vars.shares1 = IERC20(sv5115.share()).balanceOf(accountEth);
        assertGt(vars.shares1, 0, "no shares minted for deposit 1");

        vm.warp(block.timestamp + 4 weeks);
        vars.ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));
        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        vars.ppsAfter = aggregator.getPPS(address(strategy5115SuperVault));
        assertGt(vars.ppsAfter, vars.ppsBefore);

        // deposit 2
        deal(address(asset5115), accountEth, vars.deposit2Amount);
        _deposit(vars.deposit2Amount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(
            vars.deposit2Amount, address(strategy5115SuperVault), pendleEthenaAddress
        );

        vars.shares2 = IERC20(sv5115.share()).balanceOf(accountEth) - vars.shares1;
        assertGt(vars.shares2, 0, "no shares minted for deposit 2");
        assertGt(vars.shares2, vars.shares1, "less shares than it should - deposit 2");

        vm.warp(block.timestamp + 4 weeks);
        vars.ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));
        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        vars.ppsAfter = aggregator.getPPS(address(strategy5115SuperVault));
        assertGt(vars.ppsAfter, vars.ppsBefore);

        // deposit 3
        deal(address(asset5115), accountEth, vars.deposit3Amount);
        _deposit(vars.deposit3Amount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(
            vars.deposit3Amount, address(strategy5115SuperVault), pendleEthenaAddress
        );

        vars.shares3 = IERC20(sv5115.share()).balanceOf(accountEth) - vars.shares1 - vars.shares2;
        assertGt(vars.shares3, 0, "no shares minted for deposit 3");
        assertGt(vars.shares3, vars.shares2, "less shares than it should - deposit 3");

        vm.warp(block.timestamp + 4 weeks);
        vars.ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));
        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        vars.ppsAfter = aggregator.getPPS(address(strategy5115SuperVault));
        assertGt(vars.ppsAfter, vars.ppsBefore);
    }

    function test_SuperVault_5115_NegativePPS() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        PositiveAndNegativePpsVars memory vars;
        vars.deposit1Amount = 6000e6; //deposit 1 + 2 + 3

        // deposit 1
        deal(address(asset5115), accountEth, vars.deposit1Amount);
        _deposit(vars.deposit1Amount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(
            vars.deposit1Amount, address(strategy5115SuperVault), pendleEthenaAddress
        );

        vars.shares1 = IERC20(sv5115.share()).balanceOf(accountEth);
        assertGt(vars.shares1, 0, "no shares minted for deposit 1");

        vm.warp(block.timestamp + 4 weeks);
        vars.ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));
        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        vars.ppsAfter = aggregator.getPPS(address(strategy5115SuperVault));
        assertGt(vars.ppsAfter, vars.ppsBefore);

        //redeem 1
        vars.totalShares = IERC20(sv5115.share()).balanceOf(accountEth);
        vars.redeemAmount1 = vars.totalShares / 4;

        // Record initial treasury balance
        vars.feeBalanceBefore = asset5115.balanceOf(TREASURY);
        vars.userBalanceBeforeRedeem1 = asset5115.balanceOf(accountEth);

        _requestRedeem(vars.redeemAmount1, address(sv5115));
        _fulfillRedeem5115(vars.redeemAmount1, address(sv5115), address(strategy5115SuperVault));

        uint256 claimableShares1 = sv5115.maxRedeem(accountEth);
        vars.claimableAssets1 = sv5115.maxWithdraw(accountEth);

        // Calculate actual assets that will be withdrawn using averageWithdrawPrice with Floor rounding
        // This matches redeem() behavior and ensures previewFees calculates fees on the correct amount
        uint256 averageWithdrawPrice1 = strategy5115SuperVault.getAverageWithdrawPrice(accountEth);
        uint256 actualAssetsWithdrawn1 =
            claimableShares1.mulDiv(averageWithdrawPrice1, sv5115.PRECISION(), Math.Rounding.Floor);

        uint256 pps = sv5115.totalSupply() > 0 ? sv5115.convertToAssets(sv5115.PRECISION()) : sv5115.PRECISION();
        uint256 expectedLedgerFee = superLedgerETH.previewFees(
            accountEth, address(sv5115), actualAssetsWithdrawn1, claimableShares1, 100, pps, sv5115.decimals()
        );
        // Note: expectedLedgerFee may be 0 when totalSupply() is 0. Calculate actual fee instead.
        console2.log("Expected fee for redemption 1 (preview):", expectedLedgerFee);

        _claimWithdraw5115(vars.claimableAssets1, address(sv5115));

        vars.treasuryBalanceAfterRedeem1 = asset5115.balanceOf(TREASURY);
        vars.userAssetsAfterRedeem1 = asset5115.balanceOf(accountEth) - vars.userBalanceBeforeRedeem1;
        assertGt(vars.userAssetsAfterRedeem1, 0, "no assets received - redeem 1");

        // Calculate actual fee collected
        vars.totalFee1 = vars.treasuryBalanceAfterRedeem1 - vars.feeBalanceBefore;
        // Note: Fee may be 0 for ERC5115 vaults in certain conditions
        console2.log("Actual fee for redemption 1:", vars.totalFee1);

        vm.warp(block.timestamp + 4 weeks);
        vars.ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));

        // Simulate a loss in the underlying Pendle vault by reducing its balance
        // This will cause the PPS to decrease when recalculated
        uint256 currentPendleBalance = pendleEthena.balanceOf(address(strategy5115SuperVault));
        uint256 lossAmount = currentPendleBalance / 10; // 10% loss

        // Transfer some Pendle tokens away to simulate loss
        vm.prank(address(strategy5115SuperVault));
        pendleEthena.transfer(address(0xdead), lossAmount);

        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        vars.ppsAfter = aggregator.getPPS(address(strategy5115SuperVault));
        assertLt(vars.ppsAfter, vars.ppsBefore, "pps did not decrease - redeem 1");

        //redeem 2
        vars.remainingShares = IERC20(sv5115.share()).balanceOf(accountEth);
        vars.redeemAmount2 = vars.remainingShares / 2;
        // Fees are now collected via skimPerformanceFee(), not during redemption

        vars.userBalanceBeforeRedeem2 = asset5115.balanceOf(accountEth);

        _requestRedeem(vars.redeemAmount2, address(sv5115));
        _fulfillRedeem5115(vars.redeemAmount2, address(sv5115), address(strategy5115SuperVault));

        uint256 claimableShares2 = sv5115.maxRedeem(accountEth);
        vars.claimableAssets2 = sv5115.maxWithdraw(accountEth);

        // Calculate actual assets that will be withdrawn using averageWithdrawPrice with Floor rounding
        // This matches redeem() behavior and ensures previewFees calculates fees on the correct amount
        uint256 averageWithdrawPrice2 = strategy5115SuperVault.getAverageWithdrawPrice(accountEth);
        uint256 actualAssetsWithdrawn2 =
            claimableShares2.mulDiv(averageWithdrawPrice2, sv5115.PRECISION(), Math.Rounding.Floor);

        pps = sv5115.totalSupply() > 0 ? sv5115.convertToAssets(sv5115.PRECISION()) : sv5115.PRECISION();
        expectedLedgerFee = superLedgerETH.previewFees(
            accountEth, address(sv5115), actualAssetsWithdrawn2, claimableShares2, 100, pps, sv5115.decimals()
        );
        // Note: expectedLedgerFee may be 0 when totalSupply() is 0. Calculate actual fee instead.
        console2.log("Expected fee for redemption 2 (preview):", expectedLedgerFee);

        _claimWithdraw5115(vars.claimableAssets2, address(sv5115));

        vars.treasuryBalanceAfterRedeem2 = asset5115.balanceOf(TREASURY);

        vars.userAssetsAfterRedeem2 = asset5115.balanceOf(accountEth) - vars.userBalanceBeforeRedeem2;
        assertGt(vars.userAssetsAfterRedeem2, 0, "no assets received - redeem 2");

        // Calculate actual fee collected
        vars.totalFee2 = vars.treasuryBalanceAfterRedeem2 - vars.treasuryBalanceAfterRedeem1;
        // Note: Fee may be 0 for ERC5115 vaults in certain conditions
        console2.log("Actual fee for redemption 2:", vars.totalFee2);

        vm.warp(block.timestamp + 4 weeks);
        vars.ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));
        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        vars.ppsAfter = aggregator.getPPS(address(strategy5115SuperVault));
        assertLt(vars.ppsAfter, vars.ppsBefore, "pps did not decrease - redeem 2");
    }

    /*//////////////////////////////////////////////////////////////
                        REALLOCATION TESTS
    //////////////////////////////////////////////////////////////*/
    struct ReallocationVars {
        uint256 depositAmount;
        uint256 shares1;
        uint256 ppsBefore;
        uint256 ppsAfter;
        uint256 initial5115Balance;
        uint256 initialNewVaultBalance;
        uint256 amountToReallocateFrom5115;
        uint256 assetAmountToReallocateFrom5115;
        address withdraw5115HookAddress;
        address deposit4626HookAddress;
        address[] hooksAddresses;
        bytes[] hooksData;
        uint256[] expectedAssetsOrSharesOut;
        bytes[] argsForProofs;
        uint256 final5115Balance;
        uint256 finalNewVaultBalance;
        uint256 totalAssetsAfter;
    }

    function test_SuperVault_5115_ReAllocate5115To4626() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        // Add a new yield source as manager
        vm.startPrank(MANAGER);
        strategy5115SuperVault.manageYieldSource(
            address(test11_Allocate_NewYieldSource), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0
        );
        vm.stopPrank();

        ReallocationVars memory vars;
        vars.depositAmount = 1000e6;

        // deposit 1
        deal(address(asset5115), accountEth, vars.depositAmount);
        _deposit(vars.depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(vars.depositAmount, address(strategy5115SuperVault), pendleEthenaAddress);

        vars.shares1 = IERC20(sv5115.share()).balanceOf(accountEth);
        assertGt(vars.shares1, 0, "no shares minted for deposit 1");

        vm.warp(block.timestamp + 4 weeks);
        vars.ppsBefore = aggregator.getPPS(address(strategy5115SuperVault));
        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));
        vars.ppsAfter = aggregator.getPPS(address(strategy5115SuperVault));
        assertGt(vars.ppsAfter, vars.ppsBefore, "pps not greater after 5115 deposit");

        // re-allocate to 4626 vaults
        // - we use the `test11_Allocate_NewYieldSource` as the re-allocation vault
        // allocate 50% from pendleEthenaAddress vault to the new one
        // Deploy using Create2.deploy() instead of new{salt} syntax for consistent prediction
        Mock4626Vault newVault = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "New Vault", "NV"))
            )
        );
        assertEq(address(newVault), address(test11_Allocate_NewYieldSource), "new vault address does not match");

        newVault.setAsset(address(asset5115));

        // initial balances
        vars.initial5115Balance = pendleEthena.balanceOf(address(strategy5115SuperVault));
        vars.initialNewVaultBalance =
            Mock4626Vault(test11_Allocate_NewYieldSource).balanceOf(address(strategy5115SuperVault));

        // amount to reallocate (50% of 5115 vault)
        vars.amountToReallocateFrom5115 = vars.initial5115Balance * 50 / 100;
        vars.assetAmountToReallocateFrom5115 =
            pendleEthena.previewRedeem(address(asset5115), vars.amountToReallocateFrom5115);

        console2.log("Asset amount to reallocate from 5115 vault:", vars.assetAmountToReallocateFrom5115);
        console2.log("Initial 5115 balance:", vars.initial5115Balance);
        console2.log("Amount to reallocate from 5115:", vars.amountToReallocateFrom5115);

        // Get hook addresses
        vars.withdraw5115HookAddress = _getHookAddress(ETH, REDEEM_5115_VAULT_HOOK_KEY);
        vars.deposit4626HookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        vars.hooksAddresses = new address[](2);
        vars.hooksAddresses[0] = vars.withdraw5115HookAddress;
        vars.hooksAddresses[1] = vars.deposit4626HookAddress;

        vars.hooksData = new bytes[](2);

        // redeem from 5115 vault (Pendle)
        console2.log("pendleEthenaAddress: ", pendleEthenaAddress);
        console2.log("address(strategy5115SuperVault): ", address(strategy5115SuperVault));
        console2.log("address(asset5115): ", address(asset5115));
        console2.log("test11_Allocate_NewYieldSource: ", address(test11_Allocate_NewYieldSource));
        vars.hooksData[0] = _create5115RedeemHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC5115_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            pendleEthenaAddress,
            address(asset5115),
            vars.amountToReallocateFrom5115,
            0,
            false
        );

        // deposit to 4626 vault
        vars.hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            test11_Allocate_NewYieldSource,
            address(asset5115),
            vars.assetAmountToReallocateFrom5115,
            false,
            address(0),
            0
        );

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = vars.assetAmountToReallocateFrom5115; // Expected assets from 5115 redeem
        vars.expectedAssetsOrSharesOut[1] =
            Mock4626Vault(test11_Allocate_NewYieldSource).convertToShares(vars.assetAmountToReallocateFrom5115); // Expected
        // shares from 4626 deposit

        vars.argsForProofs = new bytes[](2);
        vars.argsForProofs[0] = ISuperHookInspector(vars.hooksAddresses[0]).inspect(vars.hooksData[0]);
        vars.argsForProofs[1] = ISuperHookInspector(vars.hooksAddresses[1]).inspect(vars.hooksData[1]);

        vm.startPrank(MANAGER);
        strategy5115SuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: vars.hooksAddresses,
                hookCalldata: vars.hooksData,
                expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(vars.hooksAddresses, vars.argsForProofs),
                strategyProofs: new bytes32[][](vars.hooksAddresses.length)
            })
        );
        vm.stopPrank();

        // Verify reallocation results
        vars.final5115Balance = pendleEthena.balanceOf(address(strategy5115SuperVault));
        vars.finalNewVaultBalance =
            Mock4626Vault(test11_Allocate_NewYieldSource).balanceOf(address(strategy5115SuperVault));

        // Assert that 5115 vault balance decreased
        assertApproxEqRel(
            vars.final5115Balance,
            vars.initial5115Balance - vars.amountToReallocateFrom5115,
            0.01e18,
            "5115 vault balance should decrease by reallocated amount"
        );

        // Assert that 4626 vault balance increased
        assertGt(
            vars.finalNewVaultBalance,
            vars.initialNewVaultBalance,
            "4626 vault balance should increase after reallocation"
        );

        // Verify total assets have increased due to yield accumulation (we warped 4 weeks)
        // The total assets should be greater than initial deposit due to yield from the 5115 vault
        vars.totalAssetsAfter = sv5115.totalAssets();
        assertGt(
            vars.totalAssetsAfter,
            vars.depositAmount,
            "Total assets should increase due to yield accumulation during 4-week period"
        );

        // Ensure the increase is reasonable (not more than 50% which would indicate an error)
        assertLt(
            vars.totalAssetsAfter,
            vars.depositAmount * 150 / 100,
            "Total assets increase should be reasonable (less than 50%)"
        );

        console2.log("Final 5115 balance:", vars.final5115Balance);
        console2.log("Final new vault balance:", vars.finalNewVaultBalance);
        console2.log("Total assets after reallocation:", vars.totalAssetsAfter);
    }

    function test_SuperVault_4626_ReAllocate4626ToPendle() public {
        vm.selectFork(FORKS[ETH]);
        _setup5115Vault();

        ReallocationVars memory vars;
        vars.depositAmount = 1000e6;

        // initial vault
        // Deploy using Create2.deploy() instead of new{salt} syntax for consistent prediction
        Mock4626Vault newVault = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "New Vault", "NV"))
            )
        );
        assertEq(address(newVault), address(test11_Allocate_NewYieldSource), "new vault address does not match");
        // add the 4626 vault as a new yield source
        vm.startPrank(MANAGER);
        strategy5115SuperVault.manageYieldSource(
            address(test11_Allocate_NewYieldSource), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0
        );
        vm.stopPrank();

        newVault.setAsset(address(asset5115));

        // deposit 1
        deal(address(asset5115), accountEth, vars.depositAmount);
        _deposit(vars.depositAmount, address(sv5115), address(asset5115));
        _depositFreeAssetsFromSingleAmount5115(vars.depositAmount, address(strategy5115SuperVault), address(newVault));

        vars.shares1 = IERC20(sv5115.share()).balanceOf(accountEth);
        assertGt(vars.shares1, 0, "no shares minted for ` 1");

        vm.warp(block.timestamp + 4 weeks);
        _updateSuperVaultPPS(address(strategy5115SuperVault), address(sv5115));

        // initial balances
        // 4626 balances - re-using already defined variables
        vars.initial5115Balance =
            Mock4626Vault(test11_Allocate_NewYieldSource).balanceOf(address(strategy5115SuperVault));
        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy5115SuperVault));
        assertGt(vars.initial5115Balance, 0, "initial 4626 balance is 0");
        assertGt(vars.initialNewVaultBalance, 0, "initial new vault balance is 0");
        console2.log("Initial 4626 balance:", vars.initial5115Balance);
        console2.log("Initial new vault balance:", vars.initialNewVaultBalance);

        // re-allocate to pendle
        // amount to reallocate (50% of 4626 vault); re-using variables
        vars.amountToReallocateFrom5115 = vars.initialNewVaultBalance * 50 / 100;
        vars.assetAmountToReallocateFrom5115 = newVault.previewRedeem(vars.amountToReallocateFrom5115);
        console2.log("Asset amount to reallocate from 4626 vault:", vars.assetAmountToReallocateFrom5115);
        console2.log("Amount to reallocate from 4626:", vars.amountToReallocateFrom5115);

        // prepare hooks
        // withdraw from 4626; deposit to 5115; re-using variables
        vars.withdraw5115HookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        vars.deposit4626HookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_5115_VAULT_HOOK_KEY);

        vars.hooksAddresses = new address[](2);
        vars.hooksAddresses[0] = vars.withdraw5115HookAddress;
        vars.hooksAddresses[1] = vars.deposit4626HookAddress;

        vars.hooksData = new bytes[](2);

        console2.log(" accountEth ", accountEth);
        // redeem from 4626
        newVault.setAsset(address(asset5115));
        vars.hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(newVault),
            address(strategy5115SuperVault),
            vars.amountToReallocateFrom5115,
            false
        );

        // deposit to 5115 vault
        vars.hooksData[1] = _createApproveAndDeposit5115VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC5115_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            test11_Allocate_NewYieldSource,
            address(asset5115),
            vars.assetAmountToReallocateFrom5115,
            0,
            false,
            address(0),
            0
        );

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = vars.assetAmountToReallocateFrom5115; // Expected assets from 4626 redeem
        vars.expectedAssetsOrSharesOut[1] =
            pendleEthena.previewDeposit(address(asset5115), vars.assetAmountToReallocateFrom5115); // Expected shares
        // from
        // 5115 deposit

        vars.argsForProofs = new bytes[](2);
        vars.argsForProofs[0] = ISuperHookInspector(vars.hooksAddresses[0]).inspect(vars.hooksData[0]);
        vars.argsForProofs[1] = ISuperHookInspector(vars.hooksAddresses[1]).inspect(vars.hooksData[1]);
        vm.startPrank(MANAGER);
        strategy5115SuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: vars.hooksAddresses,
                hookCalldata: vars.hooksData,
                expectedAssetsOrSharesOut: vars.expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(vars.hooksAddresses, vars.argsForProofs),
                strategyProofs: new bytes32[][](vars.hooksAddresses.length)
            })
        );
        vm.stopPrank();
    }
}
