// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// testing
import { BaseSuperVaultTest } from "./BaseSuperVaultTest.t.sol";

// external
import { console2 } from "forge-std/console2.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { MessageHashUtils } from "openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

// superform
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { IERC7540Redeem, IERC7741 } from "../../../src/vendor/standards/ERC7540/IERC7540Vault.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { IGearboxFarmingPool } from "../../../src/vendor/gearbox/IGearboxFarmingPool.sol";
import { ISuperExecutor } from "@superform-v2-core/src/interfaces/ISuperExecutor.sol";
import { AccountInstance, UserOpData } from "modulekit/ModuleKit.sol";
import { Mock4626Vault } from "../../mocks/Mock4626Vault.sol";
import { RuggableVault } from "../../mocks/RuggableVault.sol";
import { RuggableConvertVault } from "../../mocks/RuggableConvertVault.sol";
import { MockNativeETHHook } from "../../mocks/MockNativeETHHook.sol";
import { MockETHReceiver } from "../../mocks/MockETHReceiver.sol";
import { Create2 } from "openzeppelin-contracts/contracts/utils/Create2.sol";

contract SuperVaultTest is BaseSuperVaultTest {
    using Math for uint256;

    address operator = address(0x123);
    uint256 constant userPrivateKey = 0xA11CE; // Replace with a known good testing private key
    address userAddress; // Will be derived from private key

    address gearToken;
    IERC4626 gearboxVault;
    IGearboxFarmingPool gearboxFarmingPool;

    SuperVault gearSuperVault;
    SuperVaultEscrow escrowGearSuperVault;
    SuperVaultStrategy strategyGearSuperVault;

    function setUp() public override {
        super.setUp();
        userAddress = vm.addr(userPrivateKey); // Derive the correct address from private key

        // Update test vault predictions with correct deployer address (this contract)
        updateTestVaultPredictions();

        vm.selectFork(FORKS[ETH]);

        gearToken = existingUnderlyingTokens[ETH][GEAR_KEY];
        console2.log("gearToken: ", address(gearToken));
        vm.label(gearToken, "GearToken");

        // Get real yield sources from fork
        address gearboxVaultAddr = realVaultAddresses[ETH][ERC4626_VAULT_KEY][GEARBOX_VAULT_KEY][USDC_KEY];
        vm.label(gearboxVaultAddr, "GearboxVault");
        gearboxVault = IERC4626(gearboxVaultAddr);

        address gearboxStakingAddr =
            realVaultAddresses[ETH][STAKING_YIELD_SOURCE_ORACLE_KEY][GEARBOX_STAKING_KEY][GEAR_KEY];
        console2.log("gearboxStakingAddr: ", gearboxStakingAddr);
        vm.label(gearboxStakingAddr, "GearboxStaking");
        gearboxFarmingPool = IGearboxFarmingPool(gearboxStakingAddr);
    }

    /*//////////////////////////////////////////////////////////////
                       SUPERVAULT.SOL
    //////////////////////////////////////////////////////////////*/
    function test_Name_X() public view {
        string memory name = vault.name();
        assertEq(name, "SuperVault");
    }

    function test_Symbol() public view {
        string memory symbol = vault.symbol();
        assertEq(symbol, "SV_USDC");
    }

    function test_Deposit() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);

        // Verify state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");
    }

    function test_DepositDirectlyMintsShares() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Check state before deposit
        uint256 sharesBefore = vault.balanceOf(accountEth);
        assertEq(sharesBefore, 0, "User has shares before deposit");

        // Perform deposit
        _deposit(depositAmount);

        // Verify shares were minted immediately
        uint256 sharesAfter = vault.balanceOf(accountEth);
        assertGt(sharesAfter, 0, "No shares minted to user");

        // Assets should be in the strategy as free assets
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");
    }

    function test_DepositAndAllocateToYield() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Direct deposit
        _deposit(depositAmount);

        // Verify deposit state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        // Allocate the assets to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Verify allocation state
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");
    }

    function test_DepositAndAllocateToYieldViaSmartAccountManager() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deploy a new SuperVault with a smart account manager
        AccountInstance memory managerAccount = accInstances[1]; // Use a different account as manager
        _getTokens(address(asset), managerAccount.account, 1 ether); // Fund the manager account

        // Deploy vault with smart account manager
        (address newVaultAddr, address newStrategyAddr,) = _deployVaultWithSmartAccountManager(managerAccount.account);

        SuperVault newVault = SuperVault(newVaultAddr);
        SuperVaultStrategy newStrategy = SuperVaultStrategy(payable(newStrategyAddr));

        // Setup yield sources for the new strategy via smart account
        _manageYieldSourcesViaSmartAccount(managerAccount, newStrategy);

        // Direct deposit to the new vault
        _deposit(depositAmount, newVaultAddr, address(asset));

        // Verify deposit state
        uint256 userShares = newVault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");
        assertEq(asset.balanceOf(address(newStrategy)), depositAmount, "Wrong strategy balance");

        // Allocate the assets to yield sources via smart account manager
        _depositFreeAssetsFromSingleAmountViaSmartAccount(
            depositAmount, address(fluidVault), address(aaveVault), managerAccount, newStrategy
        );

        // Verify allocation state
        assertGt(fluidVault.balanceOf(address(newStrategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(newStrategy)), 0, "No aave shares allocated");

        // Verify that the strategy has no free assets left
        assertEq(asset.balanceOf(address(newStrategy)), 0, "Strategy should have no free assets after allocation");
    }

    function test_FulfillRedeem_FullAmountWithThreshold() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 vaultBalance = vault.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);
        _requestRedeem(redeemShares);
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_FulfillRedeem_FullAmount() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redemption
        uint256 vaultBalance = vault.balanceOf(accountEth);
        _requestRedeem(vaultBalance);
        _fulfillRedeem(vaultBalance, address(fluidVault), address(aaveVault));

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_DepositAndAllocate() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Setup and fulfill deposit
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Verify state
        uint256 userShares = vault.balanceOf(accountEth);
        assertGt(userShares, 0, "No shares minted to user");

        // Verify allocation
        assertGt(fluidVault.balanceOf(address(strategy)), 0, "No fluid shares allocated");
        assertGt(aaveVault.balanceOf(address(strategy)), 0, "No aave shares allocated");
    }

    /*//////////////////////////////////////////////////////////////
                        REDEEM FLOW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RequestRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redemption
        uint256 vaultBalance = vault.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);
        _requestRedeem(redeemShares);

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), redeemShares, "Wrong pending redeem amount");
        assertEq(vault.balanceOf(address(escrow)), redeemShares, "Wrong escrow balance");
    }

    function test_FulfillRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redemption
        uint256 vaultBalance = vault.balanceOf(accountEth);
        uint256 redeemShares = vaultBalance - (vaultBalance * 2e4 / 1e5);
        _requestRedeem(redeemShares);
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }

    function test_ClaimRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        uint256 initialAssetBalance = asset.balanceOf(address(accountEth));
        console2.log("-------------- initialAssetBalance user", initialAssetBalance);

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        console2.log("-------------- balance strategy after deposit ", asset.balanceOf(address(strategy)));

        // Get balances after deposit
        uint256 assetBalanceAfterDeposit = asset.balanceOf(accountEth);
        uint256 initialShares = vault.balanceOf(accountEth);
        console2.log("-------------- initialAssetBalance user", assetBalanceAfterDeposit);
        console2.log("-------------- initialShares user", initialShares);

        console2.log("-------------- balance strategy after redeem ", asset.balanceOf(address(strategy)));
        // Request redeem of half the shares
        uint256 redeemShares = initialShares / 2;
        _requestRedeem(redeemShares);
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        console2.log("-------------- balance strategy after redeem ", asset.balanceOf(address(strategy)));
        // Get claimable assets
        uint256 claimableShares = vault.maxRedeem(accountEth);
        console2.log("-------------- claimableShares user", claimableShares);
        // Claim redeem
        _claimRedeem(claimableShares);

        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);

        // Verify state
        assertEq(vault.balanceOf(accountEth), initialShares - redeemShares, "Wrong final share balance");
        assertApproxEqRel(
            asset.balanceOf(accountEth), initialAssetBalance + claimableAssets, 0.05e18, "Wrong final asset balance"
        );
        assertEq(strategy.claimableWithdraw(accountEth), 0, "Assets not claimed");
    }

    function test_AuthorizeOperator() public {
        // Create signature components
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        // Generate signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                vault.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
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
        bool success = vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        assertTrue(success, "Authorization failed");
        assertTrue(vault.isOperator(userAddress, operator), "Operator not authorized");
        assertTrue(vault.authorizations(userAddress, nonce), "Nonce not marked as used");
    }

    function test_RevertWhen_AuthorizingOperatorWithExpiredDeadline() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp - 1; // Expired deadline

        // Generate signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                vault.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );

        // User signs the message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Operator tries to use expired signature
        vm.prank(operator);
        vm.expectRevert(ISuperVault.DEADLINE_PASSED.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);
    }

    function test_RevertWhen_AuthorizingOperatorWithUsedNonce() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );
        vm.startPrank(userAddress);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // First authorization
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        // Try to use same nonce again
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        vm.stopPrank();
    }

    function test_RevertWhen_AuthorizingOperatorWithInvalidSignature() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        // Generate signature with wrong private key
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );
        uint256 wrongPrivateKey = 0x789; // Different private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(operator);
        vm.expectRevert(ISuperVault.INVALID_SIGNATURE.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);
    }

    function test_RevertWhen_OperatorAuthorizingSelf() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                vault.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), operator, operator, approved, nonce, deadline)
                )
            )
        );

        // Generate signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Operator tries to authorize themselves
        vm.prank(operator);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(operator, operator, approved, nonce, deadline, signature);
    }

    function test_RevertWhen_AuthorizingOperatorWithDifferentChainId() public {
        bool approved = true;
        bytes32 nonce = keccak256("test_nonce");
        uint256 deadline = block.timestamp + 1 hours;

        // Change chain ID
        uint256 originalChainId = block.chainid;
        vm.chainId(originalChainId + 1);

        // Generate signature with original chain ID
        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), operator, operator, approved, nonce, deadline)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(operator);
        vm.expectRevert(ISuperVault.INVALID_SIGNATURE.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);

        // Reset chain ID
        vm.chainId(originalChainId);
    }

    function test_InvalidateNonce() public {
        bytes32 nonce = keccak256("test_nonce");

        // Invalidate nonce
        vm.prank(userAddress);
        vault.invalidateNonce(nonce);

        // Try to use invalidated nonce
        bool approved = true;
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 domainSeparator = vault.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(vault.AUTHORIZE_OPERATOR_TYPEHASH(), userAddress, operator, approved, nonce, deadline)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(operator);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.authorizeOperator(userAddress, operator, approved, nonce, deadline, signature);
    }

    function test_TotalAssets() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Check initial total assets
        uint256 initialTotalAssets = vault.totalAssets();
        assertEq(initialTotalAssets, 0, "Initial totalAssets should be 0");

        // Perform deposit
        _deposit(depositAmount);

        // Allocate to yield
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Verify assets reported by totalAssets
        uint256 totalAssetsAfterDeposit = vault.totalAssets();
        assertApproxEqRel(
            totalAssetsAfterDeposit, depositAmount, 0.01e18, "totalAssets should approximately equal deposit"
        );
    }

    function test_ConvertToShares() public {
        uint256 assetsAmount = 1000e6; // 1000 USDC

        // With fresh vault (1:1 ratio), should convert directly
        uint256 shares = vault.convertToShares(assetsAmount);
        assertEq(shares, assetsAmount, "Initial share conversion should be 1:1");

        // Make a deposit to ensure PPS is established
        _deposit(assetsAmount);

        // Should still be approximately 1:1 after initial deposit
        uint256 sharesAfter = vault.convertToShares(assetsAmount);
        assertApproxEqRel(sharesAfter, assetsAmount, 0.01e18, "Share conversion should be close to 1:1");
    }

    function test_ConvertToAssets() public {
        uint256 sharesAmount = 1000e6; // 1000 shares

        // With fresh vault (1:1 ratio), should convert directly
        uint256 assets = vault.convertToAssets(sharesAmount);
        assertEq(assets, sharesAmount, "Initial asset conversion should be 1:1");

        // Make a deposit to ensure PPS is established
        _deposit(2000e6); // 2000 USDC deposit

        // Should still be approximately 1:1 after initial deposit
        uint256 assetsAfter = vault.convertToAssets(sharesAmount);
        assertApproxEqRel(assetsAfter, sharesAmount, 0.01e18, "Asset conversion should be close to 1:1");
    }

    /// @notice Tests the zero PPS fix using the actual deployed vault
    /// @dev This verifies the fix by setting PPS to 0 on the real vault and testing conversion functions
    function test_ConvertFunctions_ZeroPPS_RealVault() public {
        // First set PPS to 0 using the actual PPS update mechanism
        _updateSuperVaultPPS_ToZero(address(strategy));

        uint256 testAssets = 1000e6; // 1000 USDC
        uint256 testShares = 1000e6; // 1000 shares

        // Test convertToShares with zero PPS
        uint256 resultShares = vault.convertToShares(testAssets);
        assertEq(resultShares, 0, "convertToShares should return 0 when PPS is 0");

        // Test convertToAssets with zero PPS
        uint256 resultAssets = vault.convertToAssets(testShares);
        assertEq(resultAssets, 0, "convertToAssets should return 0 when PPS is 0");

        // Test totalAssets consistency - should also be 0 when PPS is 0 (if no supply)
        // Note: totalAssets depends on both PPS and total supply, so behavior may vary
        uint256 totalAssets = vault.totalAssets();
        console2.log("totalAssets with PPS=0:", totalAssets);

        // Test edge cases with zero inputs
        assertEq(vault.convertToShares(0), 0, "convertToShares(0) should return 0");
        assertEq(vault.convertToAssets(0), 0, "convertToAssets(0) should return 0");

        // Test with large values to ensure no overflow issues
        uint256 largeValue = type(uint128).max; // Use uint128 max to avoid potential overflow
        assertEq(vault.convertToShares(largeValue), 0, "convertToShares should return 0 for large values when PPS is 0");
        assertEq(vault.convertToAssets(largeValue), 0, "convertToAssets should return 0 for large values when PPS is 0");

        // Verify that operations requiring valid PPS should fail
        deal(address(asset), address(this), testAssets);
        asset.approve(address(vault), testAssets);

        // Deposit should revert with INVALID_PPS when PPS is 0
        vm.expectRevert(ISuperVault.INVALID_PPS.selector);
        vault.deposit(testAssets, address(this));

        // Mint should revert with INVALID_PPS when PPS is 0
        vm.expectRevert(ISuperVault.INVALID_PPS.selector);
        vault.mint(testShares, address(this));
    }

    function test_Mint() public {
        uint256 mintShares = 1000e6; // 1000 shares
        uint256 expectedAssets = vault.previewMint(mintShares);

        // Approve assets for minting
        _getTokens(address(asset), accountEth, expectedAssets);
        vm.prank(accountEth);
        asset.approve(address(vault), expectedAssets);

        // Mint shares
        vm.prank(accountEth);
        uint256 assetsUsed = vault.mint(mintShares, accountEth);

        // Verify results
        assertEq(assetsUsed, expectedAssets, "Wrong amount of assets used");
        assertEq(vault.balanceOf(accountEth), mintShares, "Wrong shares balance");
        assertEq(asset.balanceOf(address(strategy)), expectedAssets, "Wrong strategy asset balance");
    }

    function test_MaxMint() public view {
        uint256 result = vault.maxMint(accountEth);

        // By default, should be proportional to maxDeposit
        uint256 maxDeposit = vault.maxDeposit(accountEth);
        uint256 expectedMax = vault.convertToShares(maxDeposit);

        assertEq(result, expectedMax, "maxMint should match shares equivalent of maxDeposit");
    }

    function test_MaxWithdraw() public {
        // MaxWithdraw should be the user's claimable balance
        uint256 deposit = 1000e6; // 1000 USDC
        _deposit(deposit);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(deposit, address(fluidVault), address(aaveVault));

        // User balance vs maxWithdraw before redemption
        uint256 userBalance = vault.balanceOf(accountEth);
        uint256 maxWithdraw = vault.maxWithdraw(accountEth);

        // Before fulfilling redeem request, maxWithdraw should be 0
        assertEq(maxWithdraw, 0, "maxWithdraw should be 0 before redemption is fulfilled");

        // Make and fulfill redeem request
        _requestRedeem(userBalance);
        _fulfillRedeem(userBalance, address(fluidVault), address(aaveVault));

        // After fulfillment, maxWithdraw should match claimable amount
        uint256 claimable = strategy.claimableWithdraw(accountEth);
        uint256 maxWithdrawAfter = vault.maxWithdraw(accountEth);
        assertEq(maxWithdrawAfter, claimable, "maxWithdraw should match claimable amount");
    }

    function test_MaxRedeem() public {
        // Initial deposit and allocation
        uint256 deposit = 1000e6; // 1000 USDC
        _deposit(deposit);
        _depositFreeAssetsFromSingleAmount(deposit, address(fluidVault), address(aaveVault));

        // Before redemption request, maxRedeem should be 0 (no claimable assets)
        uint256 maxRedeemBefore = vault.maxRedeem(accountEth);
        assertEq(maxRedeemBefore, 0, "maxRedeem should be 0 before redemption request is fulfilled");

        // Request and fulfill redemption for half of shares
        uint256 userShares = vault.balanceOf(accountEth);
        uint256 redeemAmount = userShares / 2;
        _requestRedeem(redeemAmount);
        _fulfillRedeem(redeemAmount, address(fluidVault), address(aaveVault));

        // After fulfillment, maxRedeem should match the shares equivalent to claimable assets
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);
        uint256 maxRedeemAfter = vault.maxRedeem(accountEth);

        // Calculate expected shares based on claimable assets and average withdraw price
        uint256 avgWithdrawPrice = strategy.getAverageWithdrawPrice(accountEth);
        // Use Math.Rounding.Ceil to match the contract's implementation
        uint256 expectedShares = claimableAssets.mulDiv(vault.PRECISION(), avgWithdrawPrice, Math.Rounding.Ceil);

        // Verify maxRedeem matches expected shares with sufficient tolerance
        assertApproxEqAbs(
            maxRedeemAfter, expectedShares, 10, "maxRedeem should match shares equivalent of claimable assets"
        );
    }

    function test_PreviewDepositAndMint() public view {
        uint256 amount = 1000e6; // 1000 USDC/shares

        // Test previewDeposit (implemented)
        uint256 expectedShares = vault.convertToShares(amount);
        uint256 previewShares = vault.previewDeposit(amount);
        assertEq(previewShares, expectedShares, "previewDeposit should match convertToShares");

        // Test previewMint (implemented)
        uint256 expectedAssets = vault.convertToAssets(amount);
        uint256 previewAssets = vault.previewMint(amount);
        assertEq(previewAssets, expectedAssets, "previewMint should match convertToAssets");
    }

    function test_RevertWhen_PreviewWithdraw() public {
        uint256 amount = 1000e6; // 1000 USDC

        // previewWithdraw should revert with NOT_IMPLEMENTED
        vm.expectRevert(ISuperVault.NOT_IMPLEMENTED.selector);
        vault.previewWithdraw(amount);
    }

    function test_RevertWhen_PreviewRedeem() public {
        uint256 amount = 1000e6; // 1000 shares

        // previewRedeem should revert with NOT_IMPLEMENTED
        vm.expectRevert(ISuperVault.NOT_IMPLEMENTED.selector);
        vault.previewRedeem(amount);
    }

    function test_Redeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Deposit and allocate to yield
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Make and fulfill redemption request to get claimable assets
        uint256 userShares = vault.balanceOf(accountEth);
        _requestRedeem(userShares);
        _fulfillRedeem(userShares, address(fluidVault), address(aaveVault));

        // Get claimable amount
        uint256 maxRedeem = vault.maxRedeem(accountEth);
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);

        // Use redeem function to claim assets
        uint256 initialAssetBalance = asset.balanceOf(accountEth);
        vm.prank(accountEth);
        uint256 assetsRedeemed = vault.redeem(
            maxRedeem, // shares to redeem
            accountEth, // receiver
            accountEth // owner
        );

        // Verify results with tolerance for rounding errors
        assertApproxEqAbs(assetsRedeemed, claimableAssets, 5, "Wrong redeem amount (with tolerance)");
        assertApproxEqAbs(
            asset.balanceOf(accountEth),
            initialAssetBalance + claimableAssets,
            5,
            "Wrong final asset balance (with tolerance)"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        REDEMPTION FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PendingRedeemRequest() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Check initial state - no pending request
        uint256 initialPending = vault.pendingRedeemRequest(0, accountEth);
        assertEq(initialPending, 0, "Should have no initial pending request");

        // Request redeem for half of shares
        uint256 userShares = vault.balanceOf(accountEth);
        uint256 redeemAmount = userShares / 2;
        _requestRedeem(redeemAmount);

        // Check pending amount matches requested amount
        uint256 pendingAfterRequest = vault.pendingRedeemRequest(0, accountEth);
        assertEq(pendingAfterRequest, redeemAmount, "Pending request should match requested amount");
    }

    function test_CancelRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Request redeem
        uint256 userShares = vault.balanceOf(accountEth);
        uint256 redeemAmount = userShares / 2;
        _requestRedeem(redeemAmount);

        // Check shares are in escrow
        assertEq(vault.balanceOf(address(escrow)), redeemAmount, "Escrow should hold shares");

        // Cancel redeem
        vm.prank(accountEth);
        vault.cancelRedeem(accountEth);

        // Verify state after cancellation
        assertEq(vault.pendingRedeemRequest(0, accountEth), 0, "Pending request should be cleared");
        assertEq(vault.balanceOf(accountEth), userShares, "User should have original shares back");
        assertEq(vault.balanceOf(address(escrow)), 0, "Escrow should no longer hold shares");
    }

    function test_RevertWhen_CancelRedeemWithNoRequest() public {
        // Try to cancel when there's no request
        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.REQUEST_NOT_FOUND.selector);
        vault.cancelRedeem(accountEth);
    }

    /*//////////////////////////////////////////////////////////////
                        OPERATOR MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetOperator() public {
        // Initially not an operator
        assertFalse(vault.isOperator(accountEth, operator), "Should not be operator initially");

        // Set operator directly
        vm.prank(accountEth);
        vault.setOperator(operator, true);

        // Verify operator was set
        assertTrue(vault.isOperator(accountEth, operator), "Should be operator after setting");

        // Revoke operator permission
        vm.prank(accountEth);
        vault.setOperator(operator, false);

        // Verify operator was revoked
        assertFalse(vault.isOperator(accountEth, operator), "Should not be operator after revoking");
    }

    /*//////////////////////////////////////////////////////////////
                        INTERFACE SUPPORT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SupportsInterface() public view {
        // Test ERC7540Redeem interface
        bytes4 erc7540RedeemId = type(IERC7540Redeem).interfaceId;
        assertTrue(vault.supportsInterface(erc7540RedeemId), "Should support ERC7540Redeem");

        // Test ERC7741 interface
        bytes4 erc7741Id = type(IERC7741).interfaceId;
        assertTrue(vault.supportsInterface(erc7741Id), "Should support ERC7741");

        // Test ERC4626 interface
        bytes4 erc4626Id = type(IERC4626).interfaceId;
        assertTrue(vault.supportsInterface(erc4626Id), "Should support ERC4626");

        // Test ERC165 interface
        bytes4 erc165Id = type(IERC165).interfaceId;
        assertTrue(vault.supportsInterface(erc165Id), "Should support ERC165");

        // Test non-supported interface
        bytes4 randomId = bytes4(keccak256("random"));
        assertFalse(vault.supportsInterface(randomId), "Should not support random interface");
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTION COVERAGE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ValidateOwnerOrOperator() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        _deposit(depositAmount);
        address randomAddress = address(0xABC);
        vm.prank(randomAddress);
        vm.expectRevert(ISuperVault.INVALID_OWNER_OR_OPERATOR.selector);
        vault.requestRedeem(100e6, accountEth, accountEth);
    }

    /*//////////////////////////////////////////////////////////////
                        STRATEGY INTERACTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_UnauthorizedBurnShares() public {
        uint256 burnAmount = 1000e6;

        // Random address cannot call burnShares
        vm.prank(accountEth);
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.burnShares(burnAmount);
    }

    function test_OnRedeemClaimable() public {
        // Setup mock values for testing
        address user = accountEth;
        uint256 assets = 100e6;
        uint256 shares = 100e6;
        uint256 averageWithdrawPrice = vault.PRECISION();
        uint256 accumulatorShares = 500e6;
        uint256 accumulatorCostBasis = 500e6;

        // Only the strategy can call this function
        vm.expectEmit(true, true, true, true);
        emit ISuperVault.RedeemClaimable(
            user, 0, assets, shares, averageWithdrawPrice, accumulatorShares, accumulatorCostBasis
        );

        vm.prank(address(strategy));
        vault.onRedeemClaimable(user, assets, shares, averageWithdrawPrice, accumulatorShares, accumulatorCostBasis);
    }

    function test_RevertWhen_UnauthorizedOnRedeemClaimable() public {
        // Random address cannot call onRedeemClaimable
        vm.prank(accountEth);
        uint256 precision = vault.PRECISION();
        vm.expectRevert(ISuperVault.UNAUTHORIZED.selector);
        vault.onRedeemClaimable(accountEth, 100e6, 100e6, precision, 500e6, 500e6);
    }

    /*//////////////////////////////////////////////////////////////
                       SUPERVAULTSTRATEGY.SOL
    //////////////////////////////////////////////////////////////*/

    function test_RequestRedeem_MultipleUsers(uint256 depositAmount) public {
        // bound amount
        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        // request redeem for all users
        _requestRedeemForAllUsers(0);
    }

    function test_RequestRedeemMultipleUsers_With_CompleteFullfilment(uint256 depositAmount) public {
        // bound amount
        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        uint256 totalRedeemShares;
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            totalRedeemShares += vaultBalance;
        }

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fullfillment data
        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill redeem
        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // check that all pending requests are cleared
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_RequestRedeem_MultipleUsers_DifferentAmounts() public {
        uint256 depositAmount = 1000e6;

        // first deposit same amount for all users
        _completeDepositFlow(depositAmount);

        uint256[] memory redeemAmounts = new uint256[](ACCOUNT_COUNT);
        uint256 totalRedeemShares;

        // create redeem requests with randomized amounts based on vault balance
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            // random amount between 50% and 100% of maxRedeemable
            redeemAmounts[i] =
                bound(uint256(keccak256(abi.encodePacked(block.timestamp, i))), vaultBalance / 2, vaultBalance);
            redeemAmounts[i] =
                bound(uint256(keccak256(abi.encodePacked(block.timestamp, i))), vaultBalance / 2, vaultBalance);
            _requestRedeemForAccount(accInstances[i], redeemAmounts[i]);
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), redeemAmounts[i]);
            totalRedeemShares += redeemAmounts[i];
        }

        // fulfill all redeem requests
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;

        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // verify all redeems were fulfilled
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_RequestRedeemMultipleUsers_With_PartialUsersFullfilment(uint256 depositAmount) public {
        depositAmount = 100e6;

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        // store redeem amounts for later verification
        uint256[] memory redeemAmounts = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            redeemAmounts[i] = vault.balanceOf(accInstances[i].account);
        }

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fulfillment data for half the users
        uint256 partialUsersCount = ACCOUNT_COUNT / 2;
        uint256 totalRedeemShares;

        // calculate total redeem shares for partial users
        for (uint256 i; i < partialUsersCount; ++i) {
            totalRedeemShares += strategy.pendingRedeemRequest(accInstances[i].account);
        }

        address[] memory requestingUsers = new address[](partialUsersCount);
        for (uint256 i; i < partialUsersCount; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        (uint256 allocationAmountVault1, uint256 allocationAmountVault2) = _calculateVaultShares(totalRedeemShares);

        // fulfill redeem for half the users
        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
        console2.log("fulfilled redeem for half the users");
        // check that fulfilled requests are cleared
        for (uint256 i; i < partialUsersCount; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
        console2.log("checked that fulfilled requests are cleared");
        // check that remaining users still have pending requests
        for (uint256 i = partialUsersCount; i < ACCOUNT_COUNT; ++i) {
            uint256 pendingRedeem = strategy.pendingRedeemRequest(accInstances[i].account);
            assertEq(pendingRedeem, redeemAmounts[i]);
            uint256 claimable = strategy.claimableWithdraw(accInstances[i].account);
            assertEq(claimable, 0);
        }

        // calculate total redeem shares for remaining users
        totalRedeemShares = 0;
        uint256 j;
        requestingUsers = new address[](ACCOUNT_COUNT - partialUsersCount);
        for (uint256 i = partialUsersCount; i < ACCOUNT_COUNT;) {
            requestingUsers[j] = accInstances[i].account;
            totalRedeemShares += strategy.pendingRedeemRequest(accInstances[i].account);
            unchecked {
                ++i;
                ++j;
            }
        }

        allocationAmountVault1 = totalRedeemShares / 2;
        allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;

        // fulfill remaining users
        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
    }

    function test_RequestRedeem_RevertOnExceedingBalance(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        depositAmount = bound(depositAmount, 100e6, 10_000e6);

        // first deposit for single user
        _completeDepositFlow(depositAmount);

        // try to redeem more than balance
        uint256 vaultBalance = vault.balanceOf(accInstances[0].account);
        uint256 excessAmount = vaultBalance * 100;

        // should revert when trying to redeem more than balance
        _requestRedeemForAccount_Revert(accInstances[0], excessAmount);
    }

    function test_ClaimRedeem_RevertBeforeFulfillment() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);

        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;
        _requestRedeemForAccount(accInstances[0], redeemAmount);

        assertEq(strategy.pendingRedeemRequest(accInstances[0].account), redeemAmount);

        // try/catch pattern to verify the revert
        bool claimFailed = false;
        try this.externalClaimWithdraw(accInstances[0], redeemAmount) {
            claimFailed = false;
        } catch {
            claimFailed = true;
        }

        assertTrue(claimFailed, "Claim should have failed before fulfillment");

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accInstances[0].account;

        uint256 allocationAmountVault1 = redeemAmount / 2;
        uint256 allocationAmountVault2 = redeemAmount - allocationAmountVault1;

        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
        uint256 pendingRedeem = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingRedeem, 0);
        uint256 claimable = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimable, 0);

        _claimWithdrawForAccount(accInstances[0], vault.maxWithdraw(accInstances[0].account));

        assertEq(strategy.claimableWithdraw(accInstances[0].account), 0);
    }

    function test_ClaimRedeem_AfterPriceIncrease() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);
        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;

        _requestRedeemForAccount(accInstances[0], redeemAmount);

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accInstances[0].account;

        uint256 allocationAmountVault1 = redeemAmount / 2;
        uint256 allocationAmountVault2 = redeemAmount - allocationAmountVault1;
        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );
        console2.log("------fulfilled redeem");
        uint256 initialAssetBalance = asset.balanceOf(accInstances[0].account);

        // increase price of assets
        uint256 yieldAmount = 100e6;
        deal(address(asset), address(this), yieldAmount * 2);
        asset.approve(address(fluidVault), yieldAmount);
        asset.approve(address(aaveVault), yieldAmount);
        fluidVault.deposit(yieldAmount, address(this));
        aaveVault.deposit(yieldAmount, address(this));

        uint256 strategyAssetBalanceBefore = asset.balanceOf(address(strategy));
        uint256 maxWithdraw = vault.maxWithdraw(accInstances[0].account);
        console2.log("maxWithdraw", maxWithdraw);
        _claimWithdrawForAccount(accInstances[0], maxWithdraw);
        console2.log("------claimed withdraw");
        uint256 assetsReceived = asset.balanceOf(accInstances[0].account) - initialAssetBalance;
        assertApproxEqRel(
            assetsReceived,
            maxWithdraw,
            0.01e18,
            "Assets received should be greater than or equal to requested redeem amount"
        );

        uint256 strategyAssetBalanceAfter = asset.balanceOf(address(strategy));
        assertApproxEqRel(
            strategyAssetBalanceBefore - strategyAssetBalanceAfter,
            assetsReceived,
            0.01e18,
            "Strategy asset balance should decrease by the amount sent to user"
        );

        assertApproxEqRel(
            strategyAssetBalanceBefore - strategyAssetBalanceAfter,
            assetsReceived,
            0.01e18,
            "Strategy asset balance should decrease by the amount sent to user"
        );

        console2.log("Requested redeem amount:", redeemAmount);
        console2.log("Actual assets received:", assetsReceived);
        console2.log("Strategy asset withdrawn", strategyAssetBalanceBefore - strategyAssetBalanceAfter);

        // make sure redeem is cleared even if we have small rounding errors
        assertEq(strategy.claimableWithdraw(accInstances[0].account), 0);
    }

    // Helper function to handle deposit setup
    function _setupInitialDeposit(uint256 depositAmount) internal returns (uint256 initialShareBalance) {
        // add some tokens initially to the strategy
        _getTokens(address(asset), address(strategy), 1000);

        _getTokens(address(asset), accInstances[0].account, depositAmount);
        _depositForAccount(accInstances[0], depositAmount);

        // Verify deposit was successful
        initialShareBalance = vault.balanceOf(accInstances[0].account);
        console2.log("Initial share balance after deposit:", initialShareBalance);
        console2.log("Initial asset value:", vault.convertToAssets(initialShareBalance));

        require(initialShareBalance > 0, "Deposit failed - no shares minted");
        return initialShareBalance;
    }

    // Helper function to calculate redeem amounts
    function _calculateRedeemAmounts(uint256 redeemAmount)
        internal
        view
        returns (uint256 firstHalf, uint256 secondHalf)
    {
        // Calculate total assets using vault's conversion
        uint256 totalAssets = vault.convertToAssets(redeemAmount);

        console2.log("Total assets to redeem:", totalAssets);

        // Split evenly, rounding down first half
        firstHalf = totalAssets / 2;
        secondHalf = totalAssets - firstHalf;

        console2.log("First half:", firstHalf);
        console2.log("Second half:", secondHalf);
    }

    struct RoundingTestVars {
        uint256 depositAmount;
        uint256 initialShareBalance;
        uint256 initialAssetBalance;
        uint256 initialStrategyBalance;
        uint256 redeemAmount;
        uint256 firstHalf;
        uint256 secondHalf;
        uint256 maxWithdraw;
        uint256 finalShareBalance;
        uint256 finalAssetBalance;
        uint256 finalStrategyBalance;
        uint256 assetsReceived;
        uint256 remainingShareValue;
    }

    function test_Redeem_RoundingBehavior() public {
        RoundingTestVars memory vars;
        vars.depositAmount = 1000e6;

        _completeDepositFlow(vars.depositAmount);

        vars.initialShareBalance = vault.balanceOf(accInstances[0].account);
        vars.initialAssetBalance = asset.balanceOf(accInstances[0].account);

        console2.log("Initial shares:", vars.initialShareBalance);
        console2.log(
            "Initial price per share:",
            vault.totalAssets().mulDiv(vault.PRECISION(), vault.totalSupply(), Math.Rounding.Floor)
        );

        // Calculate redeem amount
        vars.redeemAmount = vars.initialShareBalance / 2;
        console2.log("Redeem amount (in shares):", vars.redeemAmount);

        _requestRedeemForAccount(accInstances[0], vars.redeemAmount);

        // Split redeem amount directly (don't convert to assets first)
        vars.firstHalf = vars.redeemAmount / 2;
        vars.secondHalf = vars.redeemAmount - vars.firstHalf;

        console2.log("First vault amount:", vars.firstHalf);
        console2.log("Second vault amount:", vars.secondHalf);

        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accInstances[0].account;
        _fulfillRedeemForUsers(
            requestingUsers, vars.firstHalf, vars.secondHalf, address(fluidVault), address(aaveVault)
        );

        vars.maxWithdraw = vault.maxWithdraw(accInstances[0].account);
        console2.log("maxWithdraw after fulfill:", vars.maxWithdraw);

        _claimWithdrawForAccount(accInstances[0], vars.maxWithdraw);

        vars.finalShareBalance = vault.balanceOf(accInstances[0].account);
        vars.finalAssetBalance = asset.balanceOf(accInstances[0].account);
        vars.assetsReceived = vars.finalAssetBalance - vars.initialAssetBalance;

        assertEq(vars.assetsReceived, vars.maxWithdraw, "Assets received should match maxWithdraw");
        assertApproxEqRel(
            vault.convertToAssets(vars.finalShareBalance), vars.depositAmount - vars.assetsReceived, 0.002e18
        );
    }

    function externalClaimWithdraw(AccountInstance memory accInst, uint256 assets) external {
        _claimWithdrawForAccount(accInst, assets);
    }

    function test_RequestRedeem_VerifyAmounts() public {
        RedeemVerificationVars memory vars;
        vars.depositAmount = 1000e6;

        _completeDepositFlow(vars.depositAmount);

        vars.userShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            vars.userShareBalances[i] = vault.balanceOf(accInstances[i].account);
        }
        console2.log("pps", vault.totalAssets().mulDiv(vault.PRECISION(), vault.totalSupply(), Math.Rounding.Floor));

        console2.log("deposits done");
        /// redeem half of the shares
        vars.redeemAmount = vault.balanceOf(accInstances[0].account) / 2;
        console2.log("redeem amount:", vars.redeemAmount);

        console2.log("pps", vault.totalAssets().mulDiv(vault.PRECISION(), vault.totalSupply(), Math.Rounding.Floor));

        console2.log("deposits done");
        /// redeem half of the shares
        vars.redeemAmount = vault.balanceOf(accInstances[0].account) / 2;
        console2.log("redeem amount:", vars.redeemAmount);

        _requestRedeemForAllUsers(vars.redeemAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialStrategyAssetBalance = asset.balanceOf(address(strategy));

        vars.totalDepositAmount = vars.depositAmount * ACCOUNT_COUNT;
        vars.totalRedeemAmount = vars.redeemAmount * ACCOUNT_COUNT;

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        vars.allocationAmountVault1 = vars.totalRedeemAmount / 2;
        vars.allocationAmountVault2 = vars.totalRedeemAmount - vars.allocationAmountVault1;

        _fulfillRedeemForUsers(
            requestingUsers,
            vars.allocationAmountVault1,
            vars.allocationAmountVault2,
            address(fluidVault),
            address(aaveVault)
        );

        vars.fluidVaultSharesDecrease = vars.initialFluidVaultBalance - fluidVault.balanceOf(address(strategy));
        vars.aaveVaultSharesDecrease = vars.initialAaveVaultBalance - aaveVault.balanceOf(address(strategy));
        vars.strategyAssetBalanceIncrease = asset.balanceOf(address(strategy)) - vars.initialStrategyAssetBalance;

        vars.fluidVaultAssetsValue = fluidVault.convertToAssets(vars.fluidVaultSharesDecrease);
        vars.aaveVaultAssetsValue = aaveVault.convertToAssets(vars.aaveVaultSharesDecrease);

        vars.totalAssetsRedeemed = vars.fluidVaultAssetsValue + vars.aaveVaultAssetsValue;

        vars.totalRedeemedAssets = vault.convertToAssets(vars.totalRedeemAmount);
        assertApproxEqRel(vars.totalAssetsRedeemed, vars.totalRedeemedAssets, 0.01e18);

        assertApproxEqRel(vars.strategyAssetBalanceIncrease, vars.totalRedeemedAssets, 0.01e18);

        _verifyRedeemSharesAndAssets(vars);
    }

    function test_MultipleUsers_SameAllocation_EqualRedeemValue() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);

        uint256[] memory initialShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialShareBalances[i] = vault.balanceOf(accInstances[i].account);
            console2.log("User", i, "initial share balance:", initialShareBalances[i]);
        }
        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;

        // request redem
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            _requestRedeemForAccount(accInstances[i], redeemAmount);
        }

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        uint256 totalRedeemAmount = redeemAmount * ACCOUNT_COUNT;
        uint256 allocationAmountVault1 = totalRedeemAmount / 2;
        uint256 allocationAmountVault2 = totalRedeemAmount - allocationAmountVault1;

        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        uint256[] memory initialAssetBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialAssetBalances[i] = asset.balanceOf(accInstances[i].account);
        }

        // Arrays to store results
        uint256[] memory assetsReceived = new uint256[](ACCOUNT_COUNT);
        uint256[] memory sharesBurned = new uint256[](ACCOUNT_COUNT);
        uint256[] memory assetPerShare = new uint256[](ACCOUNT_COUNT);

        // Claim redemptions for all users
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            // Record share balance before claiming
            uint256 shareBalanceBeforeClaim = vault.balanceOf(accInstances[i].account);
            console2.log("User", i, "share balance before claim:", shareBalanceBeforeClaim);

            uint256 maxWithdraw = vault.maxWithdraw(accInstances[i].account);
            _claimWithdrawForAccount(accInstances[i], maxWithdraw);

            uint256 shareBalanceAfterClaim = vault.balanceOf(accInstances[i].account);
            uint256 assetBalanceAfterClaim = asset.balanceOf(accInstances[i].account);

            console2.log("User", i, "share balance after claim:", shareBalanceAfterClaim);

            sharesBurned[i] = initialShareBalances[i] - shareBalanceAfterClaim;
            assetsReceived[i] = assetBalanceAfterClaim - initialAssetBalances[i];

            console2.log("User", i, "shares burned:", sharesBurned[i]);
            console2.log("User", i, "assets received:", assetsReceived[i]);

            if (sharesBurned[i] > 0) {
                assetPerShare[i] = assetsReceived[i] * vault.PRECISION() / sharesBurned[i];
                console2.log("User", i, "asset per share:", assetPerShare[i]);
            } else {
                console2.log("User", i, "!!! No shares were burned!");
            }

            assertGt(sharesBurned[i], 0, "No shares were burned for user");
            assertGt(assetsReceived[i], 0, "No assets were received for user");
        }

        for (uint256 i = 1; i < ACCOUNT_COUNT; i++) {
            assertApproxEqRel(assetPerShare[i], assetPerShare[0], 0.001e18, "Asset per share ratio should be equal");
            assertApproxEqRel(assetsReceived[i], assetsReceived[0], 0.001e18, "Assets received should be equal");
            assertApproxEqRel(sharesBurned[i], sharesBurned[0], 0.001e18, "Shares burned should be equal");
        }
    }

    function test_MultipleUsers_ChangingAllocation_RedeemValue() public {
        uint256 depositAmount = 1000e6;

        _completeDepositFlow(depositAmount);

        uint256[] memory initialShareBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialShareBalances[i] = vault.balanceOf(accInstances[i].account);
        }

        uint256 redeemAmount = vault.balanceOf(accInstances[0].account) / 2;

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            _requestRedeemForAccount(accInstances[i], redeemAmount);
        }
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        uint256 totalRedeemAmount = redeemAmount * ACCOUNT_COUNT;
        uint256 allocationAmountVault1 = totalRedeemAmount * 90 / 100;
        uint256 allocationAmountVault2 = totalRedeemAmount - allocationAmountVault1;
        console2.log("Redeem allocation vault1:", allocationAmountVault1 * 100 / totalRedeemAmount, "%");
        console2.log("Redeem allocation vault2:", allocationAmountVault2 * 100 / totalRedeemAmount, "%");

        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        uint256[] memory initialAssetBalances = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialAssetBalances[i] = asset.balanceOf(accInstances[i].account);
        }

        uint256[] memory assetsReceived = new uint256[](ACCOUNT_COUNT);
        uint256[] memory sharesBurned = new uint256[](ACCOUNT_COUNT);
        uint256[] memory assetPerShare = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            uint256 maxWithdraw = vault.maxWithdraw(accInstances[i].account);
            _claimWithdrawForAccount(accInstances[i], maxWithdraw);

            uint256 shareBalanceAfterClaim = vault.balanceOf(accInstances[i].account);
            uint256 assetBalanceAfterClaim = asset.balanceOf(accInstances[i].account);

            sharesBurned[i] = initialShareBalances[i] - shareBalanceAfterClaim;
            assetsReceived[i] = assetBalanceAfterClaim - initialAssetBalances[i];

            if (sharesBurned[i] > 0) {
                assetPerShare[i] = assetsReceived[i] * vault.PRECISION() / sharesBurned[i];
            }

            assertGt(sharesBurned[i], 0, "No shares were burned for user");
            assertGt(assetsReceived[i], 0, "No assets were received for user");

            console2.log("User", i, "shares burned:", sharesBurned[i]);
            console2.log("User", i, "assets received:", assetsReceived[i]);
            console2.log("User", i, "asset per share:", assetPerShare[i]);
            console2.log("Free assets in vault", asset.balanceOf(address(strategy)));
        }

        for (uint256 i = 1; i < ACCOUNT_COUNT; i++) {
            assertApproxEqRel(assetPerShare[i], assetPerShare[0], 0.001e18, "Asset per share ratio should be equal");
            assertApproxEqRel(assetsReceived[i], assetsReceived[0], 0.001e18, "Assets received should be equal");
            assertApproxEqRel(sharesBurned[i], sharesBurned[0], 0.001e18, "Shares burned should be equal");
        }

        uint256 totalAssetsReceived = 0;
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            totalAssetsReceived += assetsReceived[i];
        }

        assertApproxEqRel(
            totalAssetsReceived, totalRedeemAmount, 0.01e18, "Total assets received should match total redeem amount"
        );
    }
    /*//////////////////////////////////////////////////////////////
                      GAS REPORT TESTS
    //////////////////////////////////////////////////////////////*/

    struct NewYieldSourceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialMockVaultBalance;
        uint256 initialPendleVaultBalance;
        uint256 amountToReallocateFluidVault;
        uint256 amountToReallocateAaveVault;
        uint256 assetAmountToReallocateFromFluidVault;
        uint256 assetAmountToReallocateFromAaveVault;
        uint256 assetAmountToReallocateToMockVault;
        uint256 assetAmountToReallocateToPendleVault;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalMockVaultBalance;
        uint256 finalPendleVaultBalance;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        IERC4626 newVault;
        address pendleVault;
        // Price per share tracking
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
        uint256 initialPendleVaultPPS;
        uint256 initialMockVaultPPS;
    }

    function test_gasReport_RequestRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // First setup a deposit and claim it
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));
        // Now request redeem of half the shares
        uint256 redeemShares = vault.balanceOf(accountEth) / 2;
        _requestRedeem(redeemShares);

        // Verify state
        assertEq(strategy.pendingRedeemRequest(accountEth), redeemShares, "Wrong pending redeem amount");
        assertEq(vault.balanceOf(address(escrow)), redeemShares, "Wrong escrow balance");
    }

    function test_gasReport_ClaimRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC
        uint256 initialAssetBalance = asset.balanceOf(address(accountEth));

        // First setup a deposit and claim it
        _deposit(depositAmount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));
        // Get initial balances
        uint256 initialShares = vault.balanceOf(accountEth);

        console2.log("initial shares", initialShares);

        // Request redeem of half the shares
        uint256 redeemShares = initialShares / 2;
        _requestRedeem(redeemShares);
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        // Get claimable assets
        uint256 claimableAssets = strategy.claimableWithdraw(accountEth);
        uint256 claimableShares = vault.maxRedeem(accountEth);

        // Claim redeem
        _claimRedeem(claimableShares);

        // Verify state
        assertEq(vault.balanceOf(accountEth), initialShares - redeemShares, "Wrong final share balance");
        assertApproxEqRel(
            asset.balanceOf(accountEth), initialAssetBalance + claimableAssets, 0.05e18, "Wrong final asset balance"
        );
        assertEq(strategy.claimableWithdraw(accountEth), 0, "Assets not claimed");
    }

    function test_gasReport_TwoVaults_Fulfill() public {
        NewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        _completeDepositFlow(vars.depositAmount);
    }

    function test_gasReport_ThreeVaults_Fulfill_And_Rebalance() public {
        NewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(vault.PRECISION());
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(vault.PRECISION());

        // do an initial allo
        _completeDepositFlow(vars.depositAmount);

        // add new vault as yield source
        vars.newVault = IERC4626(0x797DD80692c3b2dAdabCe8e30C07fDE5307D48a9);

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(vars.newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialPendleVaultBalance = IERC4626(vars.newVault).balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial PendleVault balance:", vars.initialPendleVaultBalance);

        // 30/30/40
        // allocate 20% from each vault to the new one
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        vars.amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        vars.assetAmountToReallocateToPendleVault =
            vars.assetAmountToReallocateFromFluidVault + vars.assetAmountToReallocateFromAaveVault;
        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);

        vm.warp(block.timestamp + 20 days);

        // allocation
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](3);
        // redeem from FluidVault
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // redeem from AaveVault
        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to PendleVault
        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.newVault),
            address(asset),
            vars.assetAmountToReallocateToPendleVault,
            false,
            address(0),
            0
        );

        vm.startPrank(MANAGER);

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](3)
            })
        );
        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalPendleVaultBalance = vars.newVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("Final PendleVault balance:", vars.finalPendleVaultBalance);

        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - vars.amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - vars.amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalPendleVaultBalance, vars.initialPendleVaultBalance, "PendleVault balance should increase");

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + vars.newVault.convertToAssets(vars.initialPendleVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + vars.newVault.convertToAssets(vars.finalPendleVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        // Enhanced checks for price per share and yield
        console2.log("\n=== Enhanced Vault Metrics ===");

        // Price per share comparison
        uint256 fluidVaultFinalPPS = fluidVault.convertToAssets(vault.PRECISION());
        uint256 aaveVaultFinalPPS = aaveVault.convertToAssets(vault.PRECISION());
        uint256 pendleVaultFinalPPS = vars.newVault.convertToAssets(vault.PRECISION());

        console2.log("\nPrice per Share Changes:");
        console2.log("Fluid Vault:");
        console2.log("  Initial PPS:", vars.initialFluidVaultPPS);
        console2.log("  Final PPS:", fluidVaultFinalPPS);
        console2.log(
            "  Change:",
            fluidVaultFinalPPS > vars.initialFluidVaultPPS ? "+" : "",
            fluidVaultFinalPPS - vars.initialFluidVaultPPS
        );
        console2.log(
            "  Change %:", ((fluidVaultFinalPPS - vars.initialFluidVaultPPS) * 10_000) / vars.initialFluidVaultPPS
        );

        console2.log("\nAave Vault:");
        console2.log("  Initial PPS:", vars.initialAaveVaultPPS);
        console2.log("  Final PPS:", aaveVaultFinalPPS);
        console2.log(
            "  Change:",
            aaveVaultFinalPPS > vars.initialAaveVaultPPS ? "+" : "",
            aaveVaultFinalPPS - vars.initialAaveVaultPPS
        );
        console2.log(
            "  Change %:", ((aaveVaultFinalPPS - vars.initialAaveVaultPPS) * 10_000) / vars.initialAaveVaultPPS
        );

        console2.log("\nYield Metrics:");
        uint256 totalYield =
            vars.finalTotalValue > vars.initialTotalValue ? vars.finalTotalValue - vars.initialTotalValue : 0;
        console2.log("Total Yield:", totalYield);
        console2.log("Yield %:", (totalYield * 10_000) / vars.initialTotalValue);

        assertGe(fluidVaultFinalPPS, vars.initialFluidVaultPPS, "Fluid Vault should not lose value");
        assertGe(aaveVaultFinalPPS, vars.initialAaveVaultPPS, "Aave Vault should not lose value");
        assertGe(pendleVaultFinalPPS, vault.PRECISION(), "Pendle Vault should not lose value");

        uint256 totalFinalBalance =
            vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalPendleVaultBalance;

        uint256 fluidRatio = (vars.finalFluidVaultBalance * 100) / totalFinalBalance;
        uint256 aaveRatio = (vars.finalAaveVaultBalance * 100) / totalFinalBalance;
        uint256 pendleRatio = (vars.finalPendleVaultBalance * 100) / totalFinalBalance;

        console2.log("\nFinal Allocation Ratios:");
        console2.log("Fluid Vault:", fluidRatio, "%");
        console2.log("Aave Vault:", aaveRatio, "%");
        console2.log("Pendle Vault:", pendleRatio, "%");
    }

    /*//////////////////////////////////////////////////////////////
                                E2E tests
    //////////////////////////////////////////////////////////////*/

    struct MultipleDepositsPartialRedemptionsVars {
        // Balances
        uint256 initialUserAssets;
        uint256 feeBalanceBefore;
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
        uint256 claimableShares1;
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
        uint256 claimableShares2;
        uint256 userAssetsAfterRedeem2;
        // Redemption 3
        uint256 finalShares;
        uint256 superformFee3;
        uint256 recipientFee3;
        uint256 totalFee3;
        uint256 userBalanceBeforeRedeem3;
        uint256 treasuryBalanceAfterRedeem3;
        uint256 claimableAssets3;
        uint256 claimableShares3;
        uint256 userAssetsAfterRedeem3;
        // Totals
        uint256 totalDeposits;
        uint256 totalFees;
        uint256 totalAssetsReceived;
    }

    function test_SuperVault_E2E_Flow_With_Ledger_Fees() public {
        uint256 amount = 1000e6; // 1000 USDC

        vm.selectFork(FORKS[ETH]);

        // Record initial balances
        uint256 initialUserAssets = asset.balanceOf(accountEth);
        uint256 initialVaultAssets = asset.balanceOf(address(vault));

        // Step 1: Request Deposit
        _deposit(amount);

        // Verify assets transferred from user to vault
        assertEq(
            asset.balanceOf(accountEth), initialUserAssets - amount, "User assets not reduced after deposit request"
        );
        assertEq(
            asset.balanceOf(address(strategy)),
            initialVaultAssets + amount,
            "Vault assets not increased after deposit request"
        );

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(amount, address(fluidVault), address(aaveVault));

        // Verify shares minted to user
        uint256 userShares = vault.balanceOf(accountEth);

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(accountEth);
        uint256 feeBalanceBefore = asset.balanceOf(TREASURY);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // Step 4: Request Redeem
        _requestRedeem(userShares);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 6);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        /*
        The impact of fee collection at super vault is that when calculating a fee in core, the user cannot "claim" the
            whole set of shares he had inscribed as historical shares
        Claims 999552226 shares instead of 1000000000 accumulated shares, where the diff is explained by the "assets"
            collected as fees by the manager/superform in SuperVault
        For this reason, should we continue like this and assume this? Should we set a ledger configuration just for
            super vaults where the core fee on yield is 0 so the user is not double charged on performance?
        */
        address[] memory yieldSources = new address[](2);
        yieldSources[0] = address(fluidVault);
        yieldSources[1] = address(aaveVault);
        (uint256 superformFee, uint256 recipientFee,) = _calculatePerformanceFee(userShares, accountEth, yieldSources);

        // Step 5: Fulfill Redeem
        _fulfillRedeem(userShares, address(fluidVault), address(aaveVault));

        // Calculate expected assets based on shares
        uint256 claimableAssets = vault.maxWithdraw(accountEth);
        uint256 claimableShares = vault.maxRedeem(accountEth);
        console2.log("claimableShares", claimableShares);

        uint256 pps = strategy.getStoredPPS();
        uint256 expectedLedgerFee = superLedgerETH.previewFees(
            accountEth, address(vault), claimableAssets, claimableShares, 100, pps, vault.decimals()
        );

        console2.log("superformFee", superformFee);
        console2.log("recipientFee", recipientFee);
        console2.log("expectedLedgerFee", expectedLedgerFee);
        console2.log("claimableAssets", claimableAssets);
        console2.log("getAverageWithdrawPrice", strategy.getAverageWithdrawPrice(accountEth));

        // Step 6: Claim Redeem
        _claimRedeem(claimableShares);

        //uint256 totalFeesTaken = superformFee + recipientFee + expectedLedgerFee;
        uint256 totalFeesTaken = superformFee + recipientFee + expectedLedgerFee;
        console2.log("totalFeesTaken", totalFeesTaken);
        console2.log("expectedLedgerFee", expectedLedgerFee);
        console2.log("superformFee", superformFee);
        console2.log("recipientFee", recipientFee);

        // Final balance assertions
        assertGt(asset.balanceOf(accountEth), preRedeemUserAssets, "User assets not increased after redeem");

        // Verify fee was taken
        _assertFeeDerivation(totalFeesTaken, feeBalanceBefore, asset.balanceOf(TREASURY));
    }

    function test_SuperVault_E2E_Flow_With_PPS_Slippage_Update() public {
        uint256 amount = 1000e6; // 1000 USDC

        vm.selectFork(FORKS[ETH]);

        _overrideSuperLedgerSetUp();

        // Record initial balances
        uint256 initialUserAssets = asset.balanceOf(accountEth);
        uint256 initialVaultAssets = asset.balanceOf(address(vault));

        // Step 1: Request Deposit
        _deposit(amount);

        // Verify assets transferred from user to vault
        assertEq(
            asset.balanceOf(accountEth), initialUserAssets - amount, "User assets not reduced after deposit request"
        );
        assertEq(
            asset.balanceOf(address(strategy)),
            initialVaultAssets + amount,
            "Vault assets not increased after deposit request"
        );

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(amount, address(fluidVault), address(aaveVault));

        // Verify shares minted to user
        uint256 userShares = IERC20(vault.share()).balanceOf(accountEth);

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(accountEth);
        uint256 feeBalanceBefore = asset.balanceOf(TREASURY);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Update max PPS slippage to BPS_PRECISION (100%)
        _updateMaxPPSSlippageToMax();

        uint256 BPS_PRECISION = 10_000;

        vm.warp(block.timestamp + 2 weeks);

        // Update PPS to PPS before + BPS_PRECISION
        uint256 ppsBefore = aggregator.getPPS(address(strategy));
        uint256 targetPPS = ppsBefore + BPS_PRECISION;
        _updatePPSToTarget(address(strategy), address(vault), targetPPS);

        console2.log("--pps after slippage update---", aggregator.getPPS(address(strategy)));

        // Step 4: Request Redeem
        _requestRedeem(userShares);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 6);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        address[] memory yieldSources = new address[](2);
        yieldSources[0] = address(fluidVault);
        yieldSources[1] = address(aaveVault);
        (uint256 superformFee, uint256 recipientFee,) = _calculatePerformanceFee(userShares, accountEth, yieldSources);

        // Step 5: Fulfill Redeem
        _fulfillRedeem(userShares, address(fluidVault), address(aaveVault));

        // Calculate expected assets based on shares
        uint256 claimableShares = vault.maxRedeem(accountEth);

        // Step 6: Claim Redeem
        _claimRedeem(claimableShares);

        uint256 totalFeesTaken = superformFee + recipientFee;

        // Final balance assertions
        assertGt(asset.balanceOf(accountEth), preRedeemUserAssets, "User assets not increased after redeem");

        // Verify fee was taken
        _assertFeeDerivation(totalFeesTaken, feeBalanceBefore, asset.balanceOf(TREASURY));
    }

    function test_SuperVault_E2E_Flow_With_0_Ledger_Fees() public {
        uint256 amount = 1000e6; // 1000 USDC

        vm.selectFork(FORKS[ETH]);

        _overrideSuperLedgerSetUp();

        // Record initial balances
        uint256 initialUserAssets = asset.balanceOf(accountEth);
        uint256 initialVaultAssets = asset.balanceOf(address(vault));

        // Step 1: Request Deposit
        _deposit(amount);

        // Verify assets transferred from user to vault
        assertEq(
            asset.balanceOf(accountEth), initialUserAssets - amount, "User assets not reduced after deposit request"
        );
        assertEq(
            asset.balanceOf(address(strategy)),
            initialVaultAssets + amount,
            "Vault assets not increased after deposit request"
        );

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(amount, address(fluidVault), address(aaveVault));

        // Verify shares minted to user
        uint256 userShares = IERC20(vault.share()).balanceOf(accountEth);

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(accountEth);
        uint256 feeBalanceBefore = asset.balanceOf(TREASURY);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // Step 4: Request Redeem
        _requestRedeem(userShares);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 6);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        address[] memory yieldSources = new address[](2);
        yieldSources[0] = address(fluidVault);
        yieldSources[1] = address(aaveVault);
        (uint256 superformFee, uint256 recipientFee,) = _calculatePerformanceFee(userShares, accountEth, yieldSources);

        // Step 5: Fulfill Redeem
        _fulfillRedeem(userShares, address(fluidVault), address(aaveVault));

        // Calculate expected assets based on shares
        uint256 claimableShares = vault.maxRedeem(accountEth);

        // Step 6: Claim Redeem
        _claimRedeem(claimableShares);

        uint256 totalFeesTaken = superformFee + recipientFee;

        // Final balance assertions
        assertGt(asset.balanceOf(accountEth), preRedeemUserAssets, "User assets not increased after redeem");

        // Verify fee was taken
        _assertFeeDerivation(totalFeesTaken, feeBalanceBefore, asset.balanceOf(TREASURY));
    }

    function test_SuperVault_MultipleDeposits_PartialRedemptions() public {
        vm.selectFork(FORKS[ETH]);

        _overrideSuperLedgerSetUp();

        MultipleDepositsPartialRedemptionsVars memory vars;

        // Record initial balances
        vars.initialUserAssets = asset.balanceOf(accountEth);
        vars.feeBalanceBefore = asset.balanceOf(TREASURY);

        // ========== DEPOSIT 1 ==========
        console2.log("===== DEPOSIT 1 =====");
        vars.deposit1Amount = 1000e6; // 1000 USDC

        // Step 1: Request first Deposit
        _deposit(vars.deposit1Amount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(vars.deposit1Amount, address(fluidVault), address(aaveVault));

        // Get shares minted to user for first deposit
        vars.shares1 = vault.balanceOf(accountEth);
        console2.log("Shares after deposit 1:", vars.shares1);

        // Simulate some yield accrual between deposits
        vm.warp(block.timestamp + 4 weeks);
        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // ========== DEPOSIT 2 ==========
        console2.log("===== DEPOSIT 2 =====");
        vars.deposit2Amount = 2000e6; // 2000 USDC

        // Deal more tokens to user
        deal(address(asset), accountEth, vars.deposit2Amount);

        // Step 1: Request second Deposit
        _deposit(vars.deposit2Amount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(vars.deposit2Amount, address(fluidVault), address(aaveVault));

        // Get additional shares minted to user
        vars.shares2 = vault.balanceOf(accountEth) - vars.shares1;
        console2.log("Shares after deposit 2:", vars.shares2);

        // Simulate more yield accrual between deposits
        vm.warp(block.timestamp + 4 weeks);
        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));
        // ========== DEPOSIT 3 ==========
        console2.log("===== DEPOSIT 3 =====");
        vars.deposit3Amount = 3000e6; // 3000 USDC

        // Deal more tokens to user
        deal(address(asset), accountEth, vars.deposit3Amount);

        // Step 1: Request third Deposit
        _deposit(vars.deposit3Amount);

        // Need to allocate to yield sources before requesting redemption
        _depositFreeAssetsFromSingleAmount(vars.deposit3Amount, address(fluidVault), address(aaveVault));

        // Get additional shares minted to user
        vars.shares3 = vault.balanceOf(accountEth) - vars.shares1 - vars.shares2;
        console2.log("Shares after deposit 3:", vars.shares3);

        // Get total shares for user
        vars.totalShares = vault.balanceOf(accountEth);
        console2.log("Total shares:", vars.totalShares);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 42 weeks); // significant time for yield accrual

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // ========== REDEMPTION 1 (25% of shares) ==========
        console2.log("===== REDEMPTION 1 (25%) =====");
        vars.redeemAmount1 = vars.totalShares / 4; // 25% of shares
        console2.log("Redeeming shares (25%):", vars.redeemAmount1);

        vars.treasuryBalanceAfterRedeem1 = vars.feeBalanceBefore;

        // Record asset balance before redemption
        vars.userBalanceBeforeRedeem1 = asset.balanceOf(accountEth);

        // Step 1: Request first Redeem
        _requestRedeem(vars.redeemAmount1);

        // Calculate expected fee for first redemption
        address[] memory yieldSources = new address[](2);
        yieldSources[0] = address(fluidVault);
        yieldSources[1] = address(aaveVault);
        (vars.superformFee1, vars.recipientFee1,) =
            _calculatePerformanceFee(vars.redeemAmount1, accountEth, yieldSources);

        // Step 2: Fulfill first Redeem
        _fulfillRedeem(vars.redeemAmount1, address(fluidVault), address(aaveVault));

        // Step 3: Claim first Withdraw
        vars.claimableShares1 = vault.maxRedeem(accountEth);

        vars.totalFee1 = vars.superformFee1 + vars.recipientFee1;
        console2.log("Expected fee for redemption 1:", vars.totalFee1);
        _claimRedeem(vars.claimableShares1);

        vars.treasuryBalanceAfterRedeem1 = asset.balanceOf(TREASURY);

        // Verify user received assets
        vars.userAssetsAfterRedeem1 = asset.balanceOf(accountEth) - vars.userBalanceBeforeRedeem1;
        console2.log("User received assets after redemption 1:", vars.userAssetsAfterRedeem1);

        // Verify fee was taken correctly
        _assertFeeDerivation(vars.totalFee1, vars.feeBalanceBefore, vars.treasuryBalanceAfterRedeem1);
        console2.log("Treasury balance after redemption 1:", vars.treasuryBalanceAfterRedeem1);

        // ========== REDEMPTION 2 (33% of remaining shares) ==========
        console2.log("===== REDEMPTION 2 (33% of remaining) =====");
        vars.remainingShares = vault.balanceOf(accountEth);
        vars.redeemAmount2 = vars.remainingShares / 3; // 33% of remaining shares
        console2.log("Redeeming shares (33% of remaining):", vars.redeemAmount2);

        // Record asset balance before redemption
        vars.userBalanceBeforeRedeem2 = asset.balanceOf(accountEth);

        // Step 1: Request second Redeem
        _requestRedeem(vars.redeemAmount2);

        // Calculate expected fee for second redemption
        (vars.superformFee2, vars.recipientFee2,) =
            _calculatePerformanceFee(vars.redeemAmount2, accountEth, yieldSources);

        // Step 2: Fulfill second Redeem
        _fulfillRedeem(vars.redeemAmount2, address(fluidVault), address(aaveVault));

        // Step 3: Claim second Withdraw
        vars.claimableShares2 = vault.maxRedeem(accountEth);
        vars.claimableAssets2 = vault.maxWithdraw(accountEth);

        vars.totalFee2 = vars.superformFee2 + vars.recipientFee2;
        console2.log("Expected fee for redemption 2:", vars.totalFee2);

        _claimRedeem(vars.claimableShares2);

        vars.treasuryBalanceAfterRedeem2 = asset.balanceOf(TREASURY);

        // Verify user received assets
        vars.userAssetsAfterRedeem2 = asset.balanceOf(accountEth) - vars.userBalanceBeforeRedeem2;
        console2.log("User received assets after redemption 2:", vars.userAssetsAfterRedeem2);

        // Verify fee was taken correctly
        _assertFeeDerivation(vars.totalFee2, vars.treasuryBalanceAfterRedeem1, vars.treasuryBalanceAfterRedeem2);
        console2.log("Treasury balance after redemption 2:", vars.treasuryBalanceAfterRedeem2);

        // ========== REDEMPTION 3 (all remaining shares) ==========
        console2.log("===== REDEMPTION 3 (all remaining) =====");
        vars.finalShares = vault.balanceOf(accountEth);
        console2.log("Redeeming final shares:", vars.finalShares);

        // Record asset balance before redemption
        vars.userBalanceBeforeRedeem3 = asset.balanceOf(accountEth);

        // Step 1: Request third Redeem
        _requestRedeem(vars.finalShares);

        // Calculate expected fee for third redemption
        (vars.superformFee3, vars.recipientFee3,) = _calculatePerformanceFee(vars.finalShares, accountEth, yieldSources);

        // Step 2: Fulfill third Redeem
        _fulfillRedeem(vars.finalShares, address(fluidVault), address(aaveVault));

        // Step 3: Claim third Withdraw
        vars.claimableShares3 = vault.maxRedeem(accountEth);
        vars.claimableAssets3 = vault.maxWithdraw(accountEth);

        vars.totalFee3 = vars.superformFee3 + vars.recipientFee3;
        console2.log("Expected fee for redemption 3:", vars.totalFee3);
        _claimRedeem(vars.claimableShares3);

        vars.treasuryBalanceAfterRedeem3 = asset.balanceOf(TREASURY);

        // Verify user received assets
        vars.userAssetsAfterRedeem3 = asset.balanceOf(accountEth) - vars.userBalanceBeforeRedeem3;
        console2.log("User received assets after redemption 3:", vars.userAssetsAfterRedeem3);

        // Verify fee was taken correctly
        _assertFeeDerivation(vars.totalFee3, vars.treasuryBalanceAfterRedeem2, vars.treasuryBalanceAfterRedeem3);

        // Verify total fee collection
        vars.totalFees = vars.totalFee1 + vars.totalFee2 + vars.totalFee3;
        console2.log("Total fees collected:", vars.totalFees);
        console2.log("Initial treasury balance:", vars.feeBalanceBefore);
        console2.log("Final treasury balance:", vars.treasuryBalanceAfterRedeem3);
        assertEq(
            vars.treasuryBalanceAfterRedeem3, vars.feeBalanceBefore + vars.totalFees, "Total fee collection mismatch"
        );

        // Verify user has received all assets minus fees
        vars.totalDeposits = vars.deposit1Amount + vars.deposit2Amount + vars.deposit3Amount;
        vars.totalAssetsReceived =
            vars.userAssetsAfterRedeem1 + vars.userAssetsAfterRedeem2 + vars.userAssetsAfterRedeem3;
        console2.log("Total deposits:", vars.totalDeposits);
        console2.log("Total assets received:", vars.totalAssetsReceived);
        assertGt(vars.totalAssetsReceived, vars.totalDeposits, "User should receive more than deposited due to yield");

        // Verify all shares are redeemed
        assertEq(vault.balanceOf(accountEth), 0, "User should have no shares left");
    }

    /*//////////////////////////////////////////////////////////////
                       Vault Deployment test
    //////////////////////////////////////////////////////////////*/

    function test_DeployVault() public {
        // Deploy a new vault
        (address vaultAddr, address strategyAddr, address escrowAddr) = _deployVault(address(asset), "SV");
        // Verify addresses are not zero
        assertTrue(vaultAddr != address(0), "Vault address should not be zero");
        assertTrue(strategyAddr != address(0), "Strategy address should not be zero");
        assertTrue(escrowAddr != address(0), "Escrow address should not be zero");

        // Verify initialization
        SuperVault vaultContract = SuperVault(vaultAddr);
        ISuperVaultStrategy strategyContract = ISuperVaultStrategy(strategyAddr);
        SuperVaultEscrow escrowContract = SuperVaultEscrow(escrowAddr);

        // Check vault state
        assertEq(vaultContract.name(), "SuperVault", "Wrong vault name");
        assertEq(vaultContract.symbol(), "SV", "Wrong vault symbol");
        assertEq(vaultContract.asset(), address(asset), "Wrong asset");
        assertEq(address(vaultContract.strategy()), strategyAddr, "Wrong strategy");
        assertEq(vaultContract.decimals(), 6, "Wrong decimals");

        // Check strategy state
        (address _vaultAddr, address _asset, uint8 _decimals) = strategyContract.getVaultInfo();
        assertEq(_vaultAddr, vaultAddr, "Wrong vault in strategy");
        assertEq(_asset, address(asset), "Wrong asset in strategy");
        assertEq(_decimals, 6, "Wrong decimals in strategy");

        // Check escrow state
        assertTrue(escrowContract.initialized(), "Escrow not initialized");
        assertEq(escrowContract.vault(), vaultAddr, "Wrong vault in escrow");
        assertEq(escrowContract.strategy(), strategyAddr, "Wrong strategy in escrow");
    }

    function test_DeployMultipleVaults() public {
        // Deploy multiple vaults with different names/symbols
        string[3] memory symbols = ["sTV1", "sTV2", "sTV3"];

        for (uint256 i = 0; i < 3; i++) {
            // Deploy a new vault with custom configuration
            (address vaultAddr,,) = _deployVault(
                address(asset),
                symbols[i] // symbol
            );

            // Verify each vault is properly initialized
            SuperVault vaultContract = SuperVault(vaultAddr);
            assertEq(vaultContract.symbol(), symbols[i], "Wrong vault symbol");
            assertEq(vaultContract.decimals(), 6, "Wrong decimals");
        }
    }

    function test_RevertOnZeroAddresses() public {
        // Test with zero asset address
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        _createVault(
            VaultCreationParams({
                asset: address(0),
                manager: MANAGER,
                minUpdateInterval: 1000,
                maxStaleness: 10_000,
                performanceFeeBps: 1000,
                symbol: "TV"
            })
        );

        // Test with zero manager address (by temporarily setting SV_MANAGER to address(0))
        vm.expectRevert(ISuperVaultAggregator.ZERO_ADDRESS.selector);
        _createVault(
            VaultCreationParams({
                asset: address(asset),
                manager: address(0),
                minUpdateInterval: 1000,
                maxStaleness: 10_000,
                performanceFeeBps: 1000,
                symbol: "TV"
            })
        );
    }

    function test_CreateVaultWithSecondaryManagers() public {
        address[] memory secondaryManagers = new address[](2);
        secondaryManagers[0] = address(0x1);
        secondaryManagers[1] = address(0x2);
        (, address strategyAddr,) = _createVaultWithSecondaryManagers(
            VaultCreationParams({
                asset: address(asset),
                manager: address(this),
                minUpdateInterval: 1000,
                maxStaleness: 10_000,
                performanceFeeBps: 1000,
                symbol: "TV"
            }),
            secondaryManagers
        );

        address[] memory retrievedManagers = aggregator.getSecondaryManagers(strategyAddr);
        assertEq(retrievedManagers.length, 2);
        assertEq(retrievedManagers[0], address(0x1));
        assertEq(retrievedManagers[1], address(0x2));
    }

    struct VaultCreationParams {
        address asset;
        address manager;
        uint256 minUpdateInterval;
        uint256 maxStaleness;
        uint256 performanceFeeBps;
        string symbol;
    }

    function _createVault(VaultCreationParams memory params)
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        (vaultAddr, strategyAddr, escrowAddr) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: params.asset,
                name: "SuperVault",
                symbol: params.symbol,
                mainManager: params.manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: params.minUpdateInterval,
                maxStaleness: params.maxStaleness,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: params.performanceFeeBps,
                    managementFeeBps: 0,
                    recipient: address(this)
                })
            })
        );
    }

    function _createVaultWithSecondaryManagers(
        VaultCreationParams memory params,
        address[] memory secondaryManagers
    )
        internal
        returns (address vaultAddr, address strategyAddr, address escrowAddr)
    {
        (vaultAddr, strategyAddr, escrowAddr) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: params.asset,
                name: "SuperVault",
                symbol: params.symbol,
                mainManager: params.manager,
                secondaryManagers: secondaryManagers,
                minUpdateInterval: params.minUpdateInterval,
                maxStaleness: params.maxStaleness,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: params.performanceFeeBps,
                    managementFeeBps: 0,
                    recipient: address(this)
                })
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                       STAKE CLAIM FLOW TEST
    //////////////////////////////////////////////////////////////*/

    function test_SuperVault_StakeClaimFlow() public {
        _setupGearVault();
        uint256 amount = 1000e6;

        console2.log("DEPOSITING");
        _deposit(amount, address(gearSuperVault), address(asset));

        console2.log("DEPOSITING FREE ASSETS");
        _depositFreeAssetsFromSingleAmount_Gearbox(amount);

        uint256 amountToStake = gearboxVault.balanceOf(address(strategyGearSuperVault));

        console2.log("STAKING");
        _executeStakeHook(amountToStake);

        assertGt(
            gearboxFarmingPool.balanceOf(address(strategyGearSuperVault)),
            0,
            "Gearbox vault balance not increased after stake"
        );

        // Get shares minted to user
        uint256 userShares = gearSuperVault.balanceOf(accountEth);

        // Record balances before redeem
        // uint256 preRedeemUserAssets = asset.balanceOf(accountEth);

        console2.log("update pps before 60 week warp");
        vm.warp(block.timestamp + 1 hours);

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 60 weeks);

        console2.log("update pps before 60 week warp");

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        console2.log("ppsBeforeUnStake: ", aggregator.getPPS(address(strategyGearSuperVault)));

        uint256 preUnStakeGearboxBalance = gearboxVault.balanceOf(address(strategyGearSuperVault));

        uint256 amountToUnStake = gearboxFarmingPool.balanceOf(address(strategyGearSuperVault));

        _executeUnStakeHook(amountToUnStake);

        assertGt(
            gearboxVault.balanceOf(address(strategyGearSuperVault)),
            preUnStakeGearboxBalance,
            "Gearbox vault balance not decreased after unstake"
        );

        vm.warp(block.timestamp + 1 hours);

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        console2.log("ppsAfterUnStake: ", aggregator.getPPS(address(strategyGearSuperVault)));

        // Step 4: Request Redeem
        _requestRedeem(userShares, address(gearSuperVault));

        // Verify shares are escrowed
        assertEq(IERC20(gearSuperVault.share()).balanceOf(accountEth), 0, "User shares not transferred from account");
        assertEq(
            IERC20(gearSuperVault.share()).balanceOf(address(escrowGearSuperVault)),
            userShares,
            "Shares not transferred to escrow"
        );
        vm.warp(block.timestamp + 1 hours);

        _updateSuperVaultPPS(address(strategyGearSuperVault), address(gearSuperVault));

        // Step 5: Fulfill Redeem
        _fulfillRedeem_Gearbox_SV();

        uint256 claimableAssets = gearSuperVault.maxWithdraw(accountEth);
        uint256 claimableShares = gearSuperVault.maxRedeem(accountEth);
        console2.log("claimableShares", claimableShares);

        // Step 6: Claim Withdraw
        _claimWithdraw_Gearbox_SV(claimableAssets);

        /*
        assertEq(
            asset.balanceOf(accountEth),
            preRedeemUserAssets +  claimableAssets ,
            "User assets not increased after withdraw"
        );
        */
        /// @dev commented the above as there are small deviations between what the user actually got and what were the
        /// claimable assets
        /// this is due to ledger fees in core
        console2.log("ppsAfter: ", aggregator.getPPS(address(strategyGearSuperVault)));
    }

    function _setupGearVault() internal {
        // Deploy vault trio
        (address gearSuperVaultAddr, address strategyAddr, address escrowAddr) =
            _deployVault(address(asset), "svGearbox");

        assertEq(strategyAddr, globalSVGearStrategy, "SV STRATEGY NOT EQUAL TO PREDICTED");

        vm.label(gearSuperVaultAddr, "GearSuperVault");
        vm.label(strategyAddr, "GearSuperVaultStrategy");
        vm.label(escrowAddr, "GearSuperVaultEscrow");

        // Cast addresses to contract types
        gearSuperVault = SuperVault(gearSuperVaultAddr);
        escrowGearSuperVault = SuperVaultEscrow(escrowAddr);
        strategyGearSuperVault = SuperVaultStrategy(payable(strategyAddr));

        // Add a new yield source as manager
        vm.startPrank(MANAGER);
        strategyGearSuperVault.manageYieldSource(
            address(gearboxVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0
        );
        strategyGearSuperVault.manageYieldSource(
            address(gearboxFarmingPool), _getContract(ETH, STAKING_YIELD_SOURCE_ORACLE_KEY), 0
        );
        vm.stopPrank();

        vm.startPrank(MANAGER);
        strategyGearSuperVault.proposeVaultFeeConfigUpdate(100, 0, TREASURY);
        vm.warp(block.timestamp + 1 weeks);
        strategyGearSuperVault.executeVaultFeeConfigUpdate();
        vm.stopPrank();
    }

    function _depositFreeAssetsFromSingleAmount_Gearbox(uint256 depositAmount) internal {
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](1);
        fulfillHooksAddresses[0] = depositHookAddress;
        console2.log("GearSuperVault balance: ", asset.balanceOf(address(strategyGearSuperVault)));
        bytes[] memory fulfillHooksData = new bytes[](1);

        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(gearboxVault),
            address(asset),
            depositAmount,
            false,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        expectedAssetsOrSharesOut[0] = IERC4626(address(gearboxVault)).convertToShares(depositAmount);

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);

        vm.startPrank(MANAGER);
        strategyGearSuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();

        (uint256 pricePerShare) = _getSuperVaultPricePerShare();
        uint256 shares = depositAmount.mulDiv(strategyGearSuperVault.PRECISION(), pricePerShare);

        _trackDeposit(accountEth, shares, depositAmount);
    }

    function _executeStakeHook(uint256 amountToStake) internal {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, GEARBOX_APPROVE_AND_STAKE_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createApproveAndGearboxStakeHookData(
            _getYieldSourceOracleId(bytes32(bytes(STAKING_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(gearboxFarmingPool),
            address(gearboxVault),
            amountToStake,
            false
        );

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);

        vm.prank(MANAGER);
        strategyGearSuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](1),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
    }

    function _executeUnStakeHook(uint256 amountToUnStake) internal {
        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = _getHookAddress(ETH, GEARBOX_UNSTAKE_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createGearboxUnstakeHookData(
            _getYieldSourceOracleId(bytes32(bytes(STAKING_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(gearboxFarmingPool),
            amountToUnStake,
            false
        );

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);

        vm.prank(MANAGER);
        strategyGearSuperVault.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](1),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
    }

    function _fulfillRedeem_Gearbox_SV() internal {
        /// @dev with preserve percentages based on USD value allocation
        address[] memory requestingUsers = new address[](1);
        requestingUsers[0] = accountEth;
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](1);
        fulfillHooksAddresses[0] = withdrawHookAddress;

        uint256 shares = strategyGearSuperVault.pendingRedeemRequest(accountEth);

        bytes[] memory fulfillHooksData = new bytes[](1);
        fulfillHooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(gearboxVault),
            address(strategyGearSuperVault),
            shares,
            false
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](1);
        uint256 assets = gearSuperVault.convertToAssets(shares);
        uint256 underlyingShares = gearboxVault.previewDeposit(assets);
        expectedAssetsOrSharesOut[0] = underlyingShares - underlyingShares * 1e3 / 1e5;

        bytes[] memory argsForProofs = new bytes[](1);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);

        vm.startPrank(MANAGER);
        strategyGearSuperVault.fulfillRedeemRequests(
            ISuperVaultStrategy.FulfillArgs({
                controllers: requestingUsers,
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](1)
            })
        );
        vm.stopPrank();
    }

    function _claimWithdraw_Gearbox_SV(uint256 assets) internal {
        address[] memory claimHooksAddresses = new address[](1);
        claimHooksAddresses[0] = _getHookAddress(ETH, WITHDRAW_7540_VAULT_HOOK_KEY);

        bytes[] memory claimHooksData = new bytes[](1);
        claimHooksData[0] = _createWithdraw7540VaultHookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC7540_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(gearSuperVault),
            assets,
            false
        );

        ISuperExecutor.ExecutorEntry memory claimEntry =
            ISuperExecutor.ExecutorEntry({ hooksAddresses: claimHooksAddresses, hooksData: claimHooksData });
        UserOpData memory claimUserOpData = _getExecOps(instanceOnEth, superExecutorOnEth, abi.encode(claimEntry));
        executeOp(claimUserOpData);
    }

    /*//////////////////////////////////////////////////////////////
                        ALLOCATE TESTS
    //////////////////////////////////////////////////////////////*/

    struct RebalanceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 totalAssets;
        uint256 targetFluidVaultAssets;
        uint256 targetAaveVaultAssets;
        uint256 currentFluidVaultAssets;
        uint256 currentAaveVaultAssets;
        uint256 assetsToMove;
        uint256 sharesToRedeem;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalFluidVaultAssets;
        uint256 finalAaveVaultAssets;
        uint256 finalTotalAssets;
        uint256 fluidVaultPercentage;
        uint256 aaveVaultPercentage;
        uint256 initialTotalValue;
    }

    function test_Allocate_Rebalance() public {
        RebalanceVars memory vars;
        vars.depositAmount = 1000e6;

        //60/40 initial allo
        _completeDepositFlow(vars.depositAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        vars.totalAssets = vault.totalAssets();
        console2.log("vars.totalAssets", vars.totalAssets);
        vars.targetFluidVaultAssets = vars.totalAssets * 70 / 100;
        vars.targetAaveVaultAssets = vars.totalAssets * 30 / 100;
        console2.log("vars.targetFluidVaultAssets", vars.targetFluidVaultAssets);
        console2.log("vars.targetAaveVaultAssets", vars.targetAaveVaultAssets);

        vars.currentFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);
        vars.currentAaveVaultAssets = aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        console2.log("vars.currentFluidVaultAssets", vars.currentFluidVaultAssets);
        console2.log("vars.currentAaveVaultAssets", vars.currentAaveVaultAssets);

        console2.log("Current FluidVault assets:", vars.currentFluidVaultAssets);
        console2.log("Current AaveVault assets:", vars.currentAaveVaultAssets);
        console2.log("Target FluidVault assets:", vars.targetFluidVaultAssets);
        console2.log("Target AaveVault assets:", vars.targetAaveVaultAssets);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](2);

        // Determine which way to rebalance
        if (vars.currentFluidVaultAssets < vars.targetFluidVaultAssets) {
            _rebalanceFromAaveToFluid(vars, hooksAddresses, hooksData);
        } else {
            _rebalanceFromFluidToAave(vars, hooksAddresses, hooksData);
        }

        // final balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        vars.finalAaveVaultAssets = aaveVault.convertToAssets(vars.finalAaveVaultBalance);
        vars.finalTotalAssets = vars.finalFluidVaultAssets + vars.finalAaveVaultAssets;
        vars.fluidVaultPercentage = vars.finalFluidVaultAssets * 10_000 / vars.finalTotalAssets;
        vars.aaveVaultPercentage = vars.finalAaveVaultAssets * 10_000 / vars.finalTotalAssets;

        console2.log("Final FluidVault assets:", vars.finalFluidVaultAssets);
        console2.log("Final AaveVault assets:", vars.finalAaveVaultAssets);
        console2.log("Final FluidVault percentage:", vars.fluidVaultPercentage, "%");
        console2.log("Final AaveVault percentage:", vars.aaveVaultPercentage, "%");

        // checks
        assertApproxEqRel(vars.fluidVaultPercentage, 7000, 0.02e18, "FluidVault should have ~70% allocation");
        assertApproxEqRel(vars.aaveVaultPercentage, 3000, 0.02e18, "AaveVault should have ~30% allocation");

        // check total vcalue
        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalAssets, vars.initialTotalValue, 0.01e18, "Total value should be preserved during rebalancing"
        );
    }

    function test_Allocate_SmallAmounts() public {
        RebalanceVars memory vars;
        vars.depositAmount = 5e5; //0.5 usd

        _completeDepositFlow(vars.depositAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        address[] memory hooksAddresses = new address[](2);
        bytes[] memory hooksData = new bytes[](2);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        vars.currentFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);
        vars.currentAaveVaultAssets = aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.totalAssets = vars.currentFluidVaultAssets + vars.currentAaveVaultAssets;

        vars.targetFluidVaultAssets = (vars.totalAssets * 7000) / 10_000;
        vars.targetAaveVaultAssets = (vars.totalAssets * 3000) / 10_000;

        console2.log("Current FluidVault assets:", vars.currentFluidVaultAssets);
        console2.log("Target FluidVault assets:", vars.targetFluidVaultAssets);
        console2.log("Current AaveVault assets:", vars.currentAaveVaultAssets);
        console2.log("Target AaveVault assets:", vars.targetAaveVaultAssets);

        vm.startPrank(MANAGER);
        if (vars.currentFluidVaultAssets < vars.targetFluidVaultAssets) {
            _rebalanceFromAaveToFluid(vars, hooksAddresses, hooksData);
        } else {
            _rebalanceFromFluidToAave(vars, hooksAddresses, hooksData);
        }
        vm.stopPrank();

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        vars.finalAaveVaultAssets = aaveVault.convertToAssets(vars.finalAaveVaultBalance);
        vars.finalTotalAssets = vars.finalFluidVaultAssets + vars.finalAaveVaultAssets;
        vars.fluidVaultPercentage = (vars.finalFluidVaultAssets * 10_000) / vars.finalTotalAssets;
        vars.aaveVaultPercentage = (vars.finalAaveVaultAssets * 10_000) / vars.finalTotalAssets;

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("FluidVault percentage:", vars.fluidVaultPercentage);
        console2.log("AaveVault percentage:", vars.aaveVaultPercentage);

        assertApproxEqRel(
            vars.fluidVaultPercentage, 7000, 0.05e18, "FluidVault allocation should be ~70% even for small amounts"
        );
        assertApproxEqRel(
            vars.aaveVaultPercentage, 3000, 0.05e18, "AaveVault allocation should be ~30% even for small amounts"
        );

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalAssets,
            vars.initialTotalValue,
            0.02e18,
            "Total value should be preserved even with small amounts"
        );
    }

    function test_Allocate_LargeAmounts() public {
        RebalanceVars memory vars;
        vars.depositAmount = 10_000_000e6; // 10M USD * 30

        _completeDepositFlow(vars.depositAmount);

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        address[] memory hooksAddresses = new address[](2);
        bytes[] memory hooksData = new bytes[](2);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        vars.currentFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);
        vars.currentAaveVaultAssets = aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.totalAssets = vars.currentFluidVaultAssets + vars.currentAaveVaultAssets;

        vars.targetFluidVaultAssets = (vars.totalAssets * 7000) / 10_000;
        vars.targetAaveVaultAssets = (vars.totalAssets * 3000) / 10_000;

        console2.log("Current FluidVault assets:", vars.currentFluidVaultAssets);
        console2.log("Target FluidVault assets:", vars.targetFluidVaultAssets);
        console2.log("Current AaveVault assets:", vars.currentAaveVaultAssets);
        console2.log("Target AaveVault assets:", vars.targetAaveVaultAssets);

        vm.startPrank(MANAGER);
        if (vars.currentFluidVaultAssets < vars.targetFluidVaultAssets) {
            _rebalanceFromAaveToFluid(vars, hooksAddresses, hooksData);
        } else {
            _rebalanceFromFluidToAave(vars, hooksAddresses, hooksData);
        }
        vm.stopPrank();

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        vars.finalAaveVaultAssets = aaveVault.convertToAssets(vars.finalAaveVaultBalance);
        vars.finalTotalAssets = vars.finalFluidVaultAssets + vars.finalAaveVaultAssets;
        vars.fluidVaultPercentage = (vars.finalFluidVaultAssets * 10_000) / vars.finalTotalAssets;
        vars.aaveVaultPercentage = (vars.finalAaveVaultAssets * 10_000) / vars.finalTotalAssets;

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("FluidVault percentage:", vars.fluidVaultPercentage);
        console2.log("AaveVault percentage:", vars.aaveVaultPercentage);

        assertApproxEqRel(
            vars.fluidVaultPercentage, 7000, 0.01e18, "FluidVault allocation should be ~70% for large amounts"
        );
        assertApproxEqRel(
            vars.aaveVaultPercentage, 3000, 0.01e18, "AaveVault allocation should be ~30% for large amounts"
        );

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalAssets,
            vars.initialTotalValue,
            0.01e18,
            "Total value should be preserved even with large amounts"
        );
    }

    struct AllocateNewYieldSourceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialNewVaultBalance;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalNewVaultBalance;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
    }

    function test_Allocate_NewYieldSource() public {
        AllocateNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        // do an initial allo
        _completeDepositFlow(vars.depositAmount);
        IERC4626 newVault = IERC4626(CHAIN_1_EULER_VAULT);

        //  -- add funds to the newVault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(newVault), type(uint256).max);
        newVault.deposit(2 * LARGE_DEPOSIT, address(this));

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial NewVault balance:", vars.initialNewVaultBalance);

        // 30/30/40
        // allocate 20% from each vault to the new one
        uint256 amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        uint256 amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        uint256 assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(amountToReallocateFluidVault);
        uint256 assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(amountToReallocateAaveVault);
        uint256 assetAmountToReallocateToNewVault =
            assetAmountToReallocateFromFluidVault + assetAmountToReallocateFromAaveVault;
        console2.log("Asset amount to reallocate from FluidVault:", assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", assetAmountToReallocateFromAaveVault);

        // allocation
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](3);
        // redeem from FluidVault
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(fluidVault),
            address(strategy),
            amountToReallocateFluidVault,
            false
        );
        // redeem from AaveVault
        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(aaveVault),
            address(strategy),
            amountToReallocateAaveVault,
            false
        );
        // deposit to NewVault
        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), MANAGER),
            address(newVault),
            address(asset),
            assetAmountToReallocateToNewVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();

        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("Final NewVault balance:", vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalNewVaultBalance, vars.initialNewVaultBalance, "NewVault balance should increase");

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + newVault.convertToAssets(vars.initialNewVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance) + newVault.convertToAssets(vars.finalNewVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );
    }

    function test_13_TransferOfShares() public {
        _getTokens(address(asset), accInstances[0].account, 100e6);
        __deposit(accInstances[0], 100e6);

        uint256 shares = vault.balanceOf(accInstances[0].account);

        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, shares);

        console2.log("share balance ofuser2", IERC20(address(vault)).balanceOf(accInstances[1].account));

        _depositFreeAssetsFromSingleAmount(100e6, address(fluidVault), address(aaveVault));

        _updateSuperVaultPPS(address(strategy), address(vault));

        _requestRedeemForAccount(accInstances[1], shares);

        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[1].account;

        _fulfillRedeemForUsers(redeemUsers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        assertGt(IERC7540Redeem(address(vault)).claimableRedeemRequest(0, accInstances[1].account), 0);
        assertEq(IERC7540Redeem(address(vault)).pendingRedeemRequest(0, accInstances[1].account), 0);
        assertEq(vault.balanceOf(accInstances[1].account), 0);
    }

    function test_13_TransferFromOfShares() public {
        _getTokens(address(asset), accInstances[0].account, 100e6);
        __deposit(accInstances[0], 100e6);

        uint256 shares = vault.balanceOf(accInstances[0].account);

        vm.prank(accInstances[0].account);
        IERC20(address(vault)).approve(accInstances[1].account, shares);

        vm.prank(accInstances[1].account);
        IERC20(address(vault)).transferFrom(accInstances[0].account, accInstances[1].account, shares);

        console2.log("share balance ofuser2", IERC20(address(vault)).balanceOf(accInstances[1].account));

        _depositFreeAssetsFromSingleAmount(100e6, address(fluidVault), address(aaveVault));

        _updateSuperVaultPPS(address(strategy), address(vault));

        _requestRedeemForAccount(accInstances[1], shares);

        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[1].account;

        _fulfillRedeemForUsers(redeemUsers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        assertGt(IERC7540Redeem(address(vault)).claimableRedeemRequest(0, accInstances[1].account), 0);
        assertEq(IERC7540Redeem(address(vault)).pendingRedeemRequest(0, accInstances[1].account), 0);
        assertEq(vault.balanceOf(accInstances[1].account), 0);
    }

    /*//////////////////////////////////////////////////////////////
                       AUDIT FIX #10 - DEPOSIT RECEIVER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that deposit accounting follows the minted receiver, not the controller/sender
    function test_Fix10_DepositAccountingFollowsReceiver() public {
        uint256 depositAmount = 1000e6;

        // Setup: get tokens for user A (sender)
        _getTokens(address(asset), accInstances[0].account, depositAmount);

        // User A will be the sender/controller, User B will be the receiver
        address sender = accInstances[0].account;
        address receiver = accInstances[1].account;

        // Record initial accumulator states
        ISuperVaultStrategy.SuperVaultState memory senderStateBefore = strategy.getSuperVaultState(sender);
        ISuperVaultStrategy.SuperVaultState memory receiverStateBefore = strategy.getSuperVaultState(receiver);

        // User A deposits but specifies User B as receiver
        vm.startPrank(sender);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Verify shares were minted to receiver, not sender
        assertEq(vault.balanceOf(sender), 0, "Sender should not have shares");
        assertEq(vault.balanceOf(receiver), shares, "Receiver should have all shares");

        // Verify accumulator accounting follows the receiver
        ISuperVaultStrategy.SuperVaultState memory senderStateAfter = strategy.getSuperVaultState(sender);
        ISuperVaultStrategy.SuperVaultState memory receiverStateAfter = strategy.getSuperVaultState(receiver);

        // Sender's accumulator should not change
        assertEq(
            senderStateAfter.accumulatorShares,
            senderStateBefore.accumulatorShares,
            "Sender accumulator shares should not change"
        );
        assertEq(
            senderStateAfter.accumulatorCostBasis,
            senderStateBefore.accumulatorCostBasis,
            "Sender accumulator cost basis should not change"
        );

        // Receiver's accumulator should reflect the deposit
        assertEq(
            receiverStateAfter.accumulatorShares,
            receiverStateBefore.accumulatorShares + shares,
            "Receiver should get accumulator shares"
        );
        assertEq(
            receiverStateAfter.accumulatorCostBasis,
            receiverStateBefore.accumulatorCostBasis + depositAmount,
            "Receiver should get accumulator cost basis"
        );
    }

    /// @notice Test that mint accounting follows the minted receiver, not the controller/sender
    function test_Fix10_MintAccountingFollowsReceiver() public {
        uint256 mintShares = 1000e6;
        uint256 expectedAssets = vault.previewMint(mintShares);

        // Setup: get tokens for user A (sender)
        _getTokens(address(asset), accInstances[0].account, expectedAssets);

        // User A will be the sender/controller, User B will be the receiver
        address sender = accInstances[0].account;
        address receiver = accInstances[1].account;

        // Record initial accumulator states
        ISuperVaultStrategy.SuperVaultState memory senderStateBefore = strategy.getSuperVaultState(sender);
        ISuperVaultStrategy.SuperVaultState memory receiverStateBefore = strategy.getSuperVaultState(receiver);

        // User A mints but specifies User B as receiver
        vm.startPrank(sender);
        asset.approve(address(vault), expectedAssets);
        uint256 assetsUsed = vault.mint(mintShares, receiver);
        vm.stopPrank();

        // Verify shares were minted to receiver, not sender
        assertEq(vault.balanceOf(sender), 0, "Sender should not have shares");
        assertEq(vault.balanceOf(receiver), mintShares, "Receiver should have all shares");

        // Verify accumulator accounting follows the receiver
        ISuperVaultStrategy.SuperVaultState memory senderStateAfter = strategy.getSuperVaultState(sender);
        ISuperVaultStrategy.SuperVaultState memory receiverStateAfter = strategy.getSuperVaultState(receiver);

        // Sender's accumulator should not change
        assertEq(
            senderStateAfter.accumulatorShares,
            senderStateBefore.accumulatorShares,
            "Sender accumulator shares should not change"
        );
        assertEq(
            senderStateAfter.accumulatorCostBasis,
            senderStateBefore.accumulatorCostBasis,
            "Sender accumulator cost basis should not change"
        );

        // Receiver's accumulator should reflect the mint
        assertEq(
            receiverStateAfter.accumulatorShares,
            receiverStateBefore.accumulatorShares + mintShares,
            "Receiver should get accumulator shares"
        );
        assertEq(
            receiverStateAfter.accumulatorCostBasis,
            receiverStateBefore.accumulatorCostBasis + assetsUsed,
            "Receiver should get accumulator cost basis"
        );
    }

    /// @notice Test that receiver can successfully redeem after receiving deposit from another user
    function test_Fix10_ReceiverCanRedeemAfterReceivingDeposit() public {
        uint256 depositAmount = 1000e6;

        // Setup: get tokens for user A (sender)
        _getTokens(address(asset), accInstances[0].account, depositAmount);

        // User A will be the sender/controller, User B will be the receiver
        address sender = accInstances[0].account;
        address receiver = accInstances[1].account;

        // User A deposits but specifies User B as receiver
        vm.startPrank(sender);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, receiver);
        vm.stopPrank();

        // Allocate assets to yield sources
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // User B (receiver) should be able to request redeem for their shares
        vm.startPrank(receiver);
        vault.requestRedeem(shares, receiver, receiver);
        vm.stopPrank();

        // Verify redeem request was successful
        assertEq(strategy.pendingRedeemRequest(receiver), shares, "Receiver should have pending redeem request");
        assertEq(vault.balanceOf(address(escrow)), shares, "Shares should be in escrow");

        // Fulfill the redeem request
        address[] memory controllers = new address[](1);
        controllers[0] = receiver;
        _fulfillRedeemForUsers(controllers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        // Verify redemption was fulfilled
        assertEq(strategy.pendingRedeemRequest(receiver), 0, "Pending redeem should be cleared");
        assertGt(strategy.claimableWithdraw(receiver), 0, "Receiver should have claimable assets");

        // User B should be able to claim their assets
        uint256 claimableAssets = strategy.claimableWithdraw(receiver);
        uint256 initialAssetBalance = asset.balanceOf(receiver);

        vm.startPrank(receiver);
        vault.withdraw(claimableAssets, receiver, receiver);
        vm.stopPrank();

        // Verify assets were transferred to receiver
        assertEq(
            asset.balanceOf(receiver), initialAssetBalance + claimableAssets, "Receiver should receive their assets"
        );
        assertEq(strategy.claimableWithdraw(receiver), 0, "Claimable should be cleared");
    }

    /*//////////////////////////////////////////////////////////////
                       AUDIT FIX #15 - CONTROLLER/OWNER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that requestRedeem reverts when controller != owner
    function test_Fix15_RevertWhen_ControllerNotEqualOwner() public {
        uint256 depositAmount = 1000e6;

        // Setup: User A deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        address owner = accInstances[0].account;
        address controller = accInstances[1].account; // Different from owner
        uint256 shares = vault.balanceOf(owner);

        // Set operator permission so the call doesn't fail on authorization
        vm.prank(owner);
        vault.setOperator(controller, true);

        // Try to request redeem with controller != owner - should revert
        vm.startPrank(controller);
        vm.expectRevert(ISuperVault.CONTROLLER_MUST_EQUAL_OWNER.selector);
        vault.requestRedeem(shares, controller, owner);
        vm.stopPrank();
    }

    /// @notice Test that requestRedeem succeeds when controller == owner
    function test_Fix15_SucceedsWhen_ControllerEqualsOwner() public {
        uint256 depositAmount = 1000e6;

        // Setup: User A deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        address ownerController = accInstances[0].account; // Same address for both
        uint256 shares = vault.balanceOf(ownerController);

        // Request redeem with controller == owner - should succeed
        vm.startPrank(ownerController);
        uint256 requestId = vault.requestRedeem(shares, ownerController, ownerController);
        vm.stopPrank();

        // Verify redeem request was successful
        assertEq(requestId, 0, "Should return request ID 0");
        assertEq(strategy.pendingRedeemRequest(ownerController), shares, "Should have pending redeem request");
        assertEq(vault.balanceOf(address(escrow)), shares, "Shares should be in escrow");
    }

    /// @notice Test that fulfillment works correctly when controller == owner (no INSUFFICIENT_SHARES)
    function test_Fix15_FulfillmentWorksWithMatchedControllerOwner() public {
        uint256 depositAmount = 1000e6;

        // Setup: User A deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        address ownerController = accInstances[0].account;
        uint256 shares = vault.balanceOf(ownerController);

        // Request redeem with controller == owner
        vm.startPrank(ownerController);
        vault.requestRedeem(shares, ownerController, ownerController);
        vm.stopPrank();

        // Fulfill the redeem request - should not revert with INSUFFICIENT_SHARES
        address[] memory controllers = new address[](1);
        controllers[0] = ownerController;
        _fulfillRedeemForUsers(controllers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

        // Verify fulfillment was successful
        assertEq(strategy.pendingRedeemRequest(ownerController), 0, "Pending redeem should be cleared");
        assertGt(strategy.claimableWithdraw(ownerController), 0, "Should have claimable assets");

        // User should be able to claim their assets
        uint256 claimableAssets = strategy.claimableWithdraw(ownerController);
        uint256 initialAssetBalance = asset.balanceOf(ownerController);

        vm.startPrank(ownerController);
        vault.withdraw(claimableAssets, ownerController, ownerController);
        vm.stopPrank();

        // Verify assets were transferred correctly
        assertEq(asset.balanceOf(ownerController), initialAssetBalance + claimableAssets, "Should receive assets");
        assertEq(strategy.claimableWithdraw(ownerController), 0, "Claimable should be cleared");
    }

    /*//////////////////////////////////////////////////////////////
                       AUDIT FIX #1 - TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that transfer only moves accumulators, never touches request/claim state
    function test_Fix1_TransferDoesNotAffectRequestClaimState() public {
        // Setup: Deposit, allocate, request redeem, then partially fulfill to create claimable state
        uint256 depositAmount = 1000e6;
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 shares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = shares / 2;

        // Request redeem to create pending state
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Fulfill redeem to create claimable state
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _fulfillRedeemForUsers(redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault));

        // Record state before transfer
        uint256 pendingBefore = strategy.pendingRedeemRequest(accInstances[0].account);
        uint256 maxWithdrawBefore = strategy.claimableWithdraw(accInstances[0].account);
        uint256 avgRequestPPSBefore = strategy.getSuperVaultState(accInstances[0].account).averageRequestPPS;
        uint256 avgWithdrawPriceBefore = strategy.getAverageWithdrawPrice(accInstances[0].account);

        // Transfer remaining shares to another user
        uint256 remainingShares = vault.balanceOf(accInstances[0].account);
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, remainingShares);

        // Verify request/claim state unchanged for sender
        assertEq(
            strategy.pendingRedeemRequest(accInstances[0].account),
            pendingBefore,
            "pendingRedeemRequest should not change"
        );
        assertEq(
            strategy.claimableWithdraw(accInstances[0].account), maxWithdrawBefore, "maxWithdraw should not change"
        );
        assertEq(
            strategy.getSuperVaultState(accInstances[0].account).averageRequestPPS,
            avgRequestPPSBefore,
            "averageRequestPPS should not change"
        );
        assertEq(
            strategy.getAverageWithdrawPrice(accInstances[0].account),
            avgWithdrawPriceBefore,
            "averageWithdrawPrice should not change"
        );

        // Verify receiver has no request/claim state (since they didn't have any before)
        assertEq(
            strategy.pendingRedeemRequest(accInstances[1].account), 0, "Receiver should have no pendingRedeemRequest"
        );
        assertEq(strategy.claimableWithdraw(accInstances[1].account), 0, "Receiver should have no claimable");
        assertEq(
            strategy.getSuperVaultState(accInstances[1].account).averageRequestPPS,
            0,
            "Receiver should have no averageRequestPPS"
        );
        assertEq(
            strategy.getAverageWithdrawPrice(accInstances[1].account), 0, "Receiver should have no averageWithdrawPrice"
        );
    }

    /// @notice Test that transfer moves accumulators pro-rata and conserves total cost basis
    function test_Fix1_TransferMovesAccumulatorsProRata() public {
        uint256 depositAmount = 1000e6;
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 totalShares = vault.balanceOf(accInstances[0].account);
        uint256 transferShares = totalShares / 3; // Transfer 1/3 of shares

        // Record state before transfer
        ISuperVaultStrategy.SuperVaultState memory fromStateBefore =
            strategy.getSuperVaultState(accInstances[0].account);
        ISuperVaultStrategy.SuperVaultState memory toStateBefore = strategy.getSuperVaultState(accInstances[1].account);

        // Calculate expected pro-rata movement
        uint256 expectedMovedCostBasis =
            transferShares * fromStateBefore.accumulatorCostBasis / fromStateBefore.accumulatorShares;

        // Transfer shares
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, transferShares);

        // Record state after transfer
        ISuperVaultStrategy.SuperVaultState memory fromStateAfter = strategy.getSuperVaultState(accInstances[0].account);
        ISuperVaultStrategy.SuperVaultState memory toStateAfter = strategy.getSuperVaultState(accInstances[1].account);

        // Verify sender's accumulator updated correctly
        assertEq(
            fromStateAfter.accumulatorShares,
            fromStateBefore.accumulatorShares - transferShares,
            "Sender accumulator shares incorrect"
        );
        assertEq(
            fromStateAfter.accumulatorCostBasis,
            fromStateBefore.accumulatorCostBasis - expectedMovedCostBasis,
            "Sender accumulator cost basis incorrect"
        );

        // Verify receiver's accumulator updated correctly
        assertEq(
            toStateAfter.accumulatorShares,
            toStateBefore.accumulatorShares + transferShares,
            "Receiver accumulator shares incorrect"
        );
        assertEq(
            toStateAfter.accumulatorCostBasis,
            toStateBefore.accumulatorCostBasis + expectedMovedCostBasis,
            "Receiver accumulator cost basis incorrect"
        );

        // Verify total cost basis is conserved (within 1 wei tolerance for rounding)
        uint256 totalCostBasisBefore = fromStateBefore.accumulatorCostBasis + toStateBefore.accumulatorCostBasis;
        uint256 totalCostBasisAfter = fromStateAfter.accumulatorCostBasis + toStateAfter.accumulatorCostBasis;
        assertApproxEqAbs(totalCostBasisAfter, totalCostBasisBefore, 1, "Total cost basis not conserved");
    }

    /// @notice Test that zero-value transfer is a no-op
    function test_Fix1_ZeroValueTransferIsNoOp() public {
        uint256 depositAmount = 1000e6;
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);

        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        // Record state before zero transfer
        ISuperVaultStrategy.SuperVaultState memory fromStateBefore =
            strategy.getSuperVaultState(accInstances[0].account);
        ISuperVaultStrategy.SuperVaultState memory toStateBefore = strategy.getSuperVaultState(accInstances[1].account);

        // Perform zero-value transfer
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, 0);

        // Record state after zero transfer
        ISuperVaultStrategy.SuperVaultState memory fromStateAfter = strategy.getSuperVaultState(accInstances[0].account);
        ISuperVaultStrategy.SuperVaultState memory toStateAfter = strategy.getSuperVaultState(accInstances[1].account);

        // Verify no state changes occurred
        assertEq(
            fromStateAfter.accumulatorShares,
            fromStateBefore.accumulatorShares,
            "Sender accumulator shares should not change"
        );
        assertEq(
            fromStateAfter.accumulatorCostBasis,
            fromStateBefore.accumulatorCostBasis,
            "Sender accumulator cost basis should not change"
        );
        assertEq(
            toStateAfter.accumulatorShares,
            toStateBefore.accumulatorShares,
            "Receiver accumulator shares should not change"
        );
        assertEq(
            toStateAfter.accumulatorCostBasis,
            toStateBefore.accumulatorCostBasis,
            "Receiver accumulator cost basis should not change"
        );

        // Verify all other fields unchanged
        assertEq(
            fromStateAfter.pendingRedeemRequest,
            fromStateBefore.pendingRedeemRequest,
            "pendingRedeemRequest should not change"
        );
        assertEq(fromStateAfter.maxWithdraw, fromStateBefore.maxWithdraw, "maxWithdraw should not change");
        assertEq(
            fromStateAfter.averageRequestPPS, fromStateBefore.averageRequestPPS, "averageRequestPPS should not change"
        );
        assertEq(
            fromStateAfter.averageWithdrawPrice,
            fromStateBefore.averageWithdrawPrice,
            "averageWithdrawPrice should not change"
        );
    }

    /// @notice Test that audit #1 attack scenario fails - no clone/overwrite of claimable
    function test_Fix1_AuditAttackScenarioFails() public {
        uint256 depositAmount = 1000e6;

        // User A deposits
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 sharesA = vault.balanceOf(accInstances[0].account);
        uint256 transferShares = sharesA / 2; // Transfer half, keep half for redeem

        // User B makes a deposit (gets fresh shares with no claimable)
        _getTokens(address(asset), accInstances[1].account, depositAmount);
        __deposit(accInstances[1], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 claimableBBefore = strategy.claimableWithdraw(accInstances[1].account);
        assertEq(claimableBBefore, 0, "User B should have no claimable assets initially");

        // User A transfers half their shares to User B BEFORE redeem request
        vm.prank(accInstances[0].account);
        IERC20(address(vault)).transfer(accInstances[1].account, transferShares);

        // User A then requests redeem with remaining shares and gets claimable assets
        uint256 remainingSharesA = vault.balanceOf(accInstances[0].account);
        _requestRedeemForAccount(accInstances[0], remainingSharesA);

        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _fulfillRedeemForUsers(
            redeemUsers, remainingSharesA / 2, remainingSharesA / 2, address(fluidVault), address(aaveVault)
        );

        uint256 claimableA = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableA, 0, "User A should have claimable assets");

        // Verify attack failed: User B should not have gained User A's claimable assets
        uint256 claimableBAfter = strategy.claimableWithdraw(accInstances[1].account);
        assertEq(claimableBAfter, 0, "Attack failed: User B should not have claimable assets from User A");

        // Verify User A retains their claimable assets
        uint256 claimableAAfter = strategy.claimableWithdraw(accInstances[0].account);
        assertEq(claimableAAfter, claimableA, "User A should retain their claimable assets");

        // Verify only accumulators moved during transfer
        ISuperVaultStrategy.SuperVaultState memory stateB = strategy.getSuperVaultState(accInstances[1].account);

        // User B should have accumulator from the transfer but no request/claim state
        assertGt(stateB.accumulatorShares, 0, "User B should have accumulator shares from transfer");
        assertEq(stateB.pendingRedeemRequest, 0, "User B should have no pending requests");
        assertEq(stateB.maxWithdraw, 0, "User B should have no maxWithdraw");
        assertEq(stateB.averageRequestPPS, 0, "User B should have no averageRequestPPS");
        assertEq(stateB.averageWithdrawPrice, 0, "User B should have no averageWithdrawPrice");
    }

    /*//////////////////////////////////////////////////////////////
                            FIX #45 TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that cancel → re-request → fulfill works (no permanent lockout)
    function test_Fix45_CancelReRequestFulfillWorks() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 2;

        // Get initial accumulator state
        ISuperVaultStrategy.SuperVaultState memory initialState = strategy.getSuperVaultState(accInstances[0].account);
        uint256 initialAccumulatorShares = initialState.accumulatorShares;
        uint256 initialAccumulatorCostBasis = initialState.accumulatorCostBasis;

        // Step 1: Request redeem
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Verify request was placed
        uint256 pendingAfterRequest = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingAfterRequest, redeemShares, "Should have pending request");

        // Step 2: Cancel redeem
        vm.prank(accInstances[0].account);
        vault.cancelRedeem(accInstances[0].account);

        // Verify cancel cleared pending fields but preserved accumulators
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel =
            strategy.getSuperVaultState(accInstances[0].account);
        assertEq(stateAfterCancel.pendingRedeemRequest, 0, "Pending request should be cleared");
        assertEq(stateAfterCancel.averageRequestPPS, 0, "Average request PPS should be cleared");
        assertEq(stateAfterCancel.accumulatorShares, initialAccumulatorShares, "Accumulator shares should be preserved");
        assertEq(
            stateAfterCancel.accumulatorCostBasis,
            initialAccumulatorCostBasis,
            "Accumulator cost basis should be preserved"
        );
        assertEq(stateAfterCancel.maxWithdraw, initialState.maxWithdraw, "Max withdraw should be preserved");
        assertEq(
            stateAfterCancel.averageWithdrawPrice,
            initialState.averageWithdrawPrice,
            "Average withdraw price should be preserved"
        );

        // Step 3: Re-request redeem (should work without INSUFFICIENT_SHARES)
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Verify re-request worked
        uint256 pendingAfterReRequest = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingAfterReRequest, redeemShares, "Should have pending request after re-request");

        // Step 4: Fulfill redeem (should work without errors)
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _fulfillRedeemForUsers(redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault));

        // Verify fulfillment worked
        uint256 claimableAssets = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableAssets, 0, "Should have claimable assets after fulfillment");

        // Verify accumulator was properly debited
        ISuperVaultStrategy.SuperVaultState memory finalState = strategy.getSuperVaultState(accInstances[0].account);
        assertLt(finalState.accumulatorShares, initialAccumulatorShares, "Accumulator shares should be debited");
        assertLt(
            finalState.accumulatorCostBasis, initialAccumulatorCostBasis, "Accumulator cost basis should be debited"
        );
    }

    /// @notice Test that maxWithdraw and averageWithdrawPrice remain unchanged by cancel
    function test_Fix45_CancelPreservesClaimableState() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits, requests, gets partially fulfilled to create claimable state
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 firstRedeemShares = userShares / 3;

        // First redeem request and fulfillment to create claimable state
        _requestRedeemForAccount(accInstances[0], firstRedeemShares);
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _fulfillRedeemForUsers(
            redeemUsers, firstRedeemShares / 2, firstRedeemShares / 2, address(fluidVault), address(aaveVault)
        );

        // Get state after first fulfillment
        ISuperVaultStrategy.SuperVaultState memory stateAfterFirstFulfill =
            strategy.getSuperVaultState(accInstances[0].account);
        uint256 maxWithdrawBefore = stateAfterFirstFulfill.maxWithdraw;
        uint256 averageWithdrawPriceBefore = stateAfterFirstFulfill.averageWithdrawPrice;
        uint256 accumulatorSharesBefore = stateAfterFirstFulfill.accumulatorShares;
        uint256 accumulatorCostBasisBefore = stateAfterFirstFulfill.accumulatorCostBasis;

        assertGt(maxWithdrawBefore, 0, "Should have claimable assets");
        assertGt(averageWithdrawPriceBefore, 0, "Should have average withdraw price");

        // Second redeem request
        uint256 secondRedeemShares = userShares / 3;
        _requestRedeemForAccount(accInstances[0], secondRedeemShares);

        // Cancel the second request
        vm.prank(accInstances[0].account);
        vault.cancelRedeem(accInstances[0].account);

        // Verify claimable state is preserved
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel =
            strategy.getSuperVaultState(accInstances[0].account);
        assertEq(stateAfterCancel.maxWithdraw, maxWithdrawBefore, "Max withdraw should be unchanged by cancel");
        assertEq(
            stateAfterCancel.averageWithdrawPrice,
            averageWithdrawPriceBefore,
            "Average withdraw price should be unchanged by cancel"
        );
        assertEq(
            stateAfterCancel.accumulatorShares,
            accumulatorSharesBefore,
            "Accumulator shares should be unchanged by cancel"
        );
        assertEq(
            stateAfterCancel.accumulatorCostBasis,
            accumulatorCostBasisBefore,
            "Accumulator cost basis should be unchanged by cancel"
        );

        // Verify only pending fields were cleared
        assertEq(stateAfterCancel.pendingRedeemRequest, 0, "Pending request should be cleared");
        assertEq(stateAfterCancel.averageRequestPPS, 0, "Average request PPS should be cleared");
    }

    /// @notice Test that accumulators remain unchanged by cancel
    function test_Fix45_CancelPreservesAccumulators() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 2;

        // Get initial accumulator state
        ISuperVaultStrategy.SuperVaultState memory initialState = strategy.getSuperVaultState(accInstances[0].account);
        uint256 initialAccumulatorShares = initialState.accumulatorShares;
        uint256 initialAccumulatorCostBasis = initialState.accumulatorCostBasis;

        assertGt(initialAccumulatorShares, 0, "Should have accumulator shares");
        assertGt(initialAccumulatorCostBasis, 0, "Should have accumulator cost basis");

        // Request redeem
        _requestRedeemForAccount(accInstances[0], redeemShares);

        // Cancel redeem
        vm.prank(accInstances[0].account);
        vault.cancelRedeem(accInstances[0].account);

        // Verify accumulators are exactly the same
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel =
            strategy.getSuperVaultState(accInstances[0].account);
        assertEq(stateAfterCancel.accumulatorShares, initialAccumulatorShares, "Accumulator shares should be unchanged");
        assertEq(
            stateAfterCancel.accumulatorCostBasis,
            initialAccumulatorCostBasis,
            "Accumulator cost basis should be unchanged"
        );

        // User should still be able to make future redeems
        _requestRedeemForAccount(accInstances[0], redeemShares);
        uint256 pendingAfterNewRequest = strategy.pendingRedeemRequest(accInstances[0].account);
        assertEq(pendingAfterNewRequest, redeemShares, "Should be able to make new redeem request");
    }

    /// @notice Test that multiple cancel cycles work correctly
    function test_Fix45_MultipleCancelCycles() public {
        uint256 depositAmount = 1000e6;

        // Setup: User deposits and gets shares
        _getTokens(address(asset), accInstances[0].account, depositAmount);
        __deposit(accInstances[0], depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 userShares = vault.balanceOf(accInstances[0].account);
        uint256 redeemShares = userShares / 4;

        // Get initial accumulator state
        ISuperVaultStrategy.SuperVaultState memory initialState = strategy.getSuperVaultState(accInstances[0].account);
        uint256 initialAccumulatorShares = initialState.accumulatorShares;

        // Cycle 1: Request → Cancel
        _requestRedeemForAccount(accInstances[0], redeemShares);
        vm.prank(accInstances[0].account);
        vault.cancelRedeem(accInstances[0].account);

        // Verify state after first cancel
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel1 =
            strategy.getSuperVaultState(accInstances[0].account);
        assertEq(stateAfterCancel1.pendingRedeemRequest, 0, "Pending should be cleared after cancel 1");
        assertEq(stateAfterCancel1.accumulatorShares, initialAccumulatorShares, "Accumulators preserved after cancel 1");

        // Cycle 2: Request → Cancel
        _requestRedeemForAccount(accInstances[0], redeemShares);
        vm.prank(accInstances[0].account);
        vault.cancelRedeem(accInstances[0].account);

        // Verify state after second cancel
        ISuperVaultStrategy.SuperVaultState memory stateAfterCancel2 =
            strategy.getSuperVaultState(accInstances[0].account);
        assertEq(stateAfterCancel2.pendingRedeemRequest, 0, "Pending should be cleared after cancel 2");
        assertEq(stateAfterCancel2.accumulatorShares, initialAccumulatorShares, "Accumulators preserved after cancel 2");

        // Cycle 3: Request → Fulfill (should work)
        _requestRedeemForAccount(accInstances[0], redeemShares);
        address[] memory redeemUsers = new address[](1);
        redeemUsers[0] = accInstances[0].account;
        _fulfillRedeemForUsers(redeemUsers, redeemShares / 2, redeemShares / 2, address(fluidVault), address(aaveVault));

        // Verify final fulfillment worked
        uint256 claimableAssets = strategy.claimableWithdraw(accInstances[0].account);
        assertGt(claimableAssets, 0, "Should have claimable assets after final fulfillment");
    }

    function _rebalanceFromAaveToFluid(
        RebalanceVars memory vars,
        address[] memory hooksAddresses,
        bytes[] memory hooksData
    )
        private
    {
        _rebalanceFromVaultToVault(
            hooksAddresses,
            hooksData,
            address(aaveVault),
            address(fluidVault),
            vars.targetFluidVaultAssets,
            vars.currentFluidVaultAssets
        );
    }

    function _rebalanceFromFluidToAave(
        RebalanceVars memory vars,
        address[] memory hooksAddresses,
        bytes[] memory hooksData
    )
        private
    {
        _rebalanceFromVaultToVault(
            hooksAddresses,
            hooksData,
            address(fluidVault),
            address(aaveVault),
            vars.targetAaveVaultAssets,
            vars.currentAaveVaultAssets
        );
    }

    /*//////////////////////////////////////////////////////////////
                        SCENARIO TESTS
    //////////////////////////////////////////////////////////////*/

    struct MultipleOperationsVars {
        uint256 seed;
        uint256[] depositAmounts;
        address[] redeemUsers;
        uint256[] redeemAmounts;
        bool[] selected;
        uint256 selectedCount;
        uint256 totalRedeemShares;
        uint256 redeemSharesVault1;
        uint256 redeemSharesVault2;
        uint256 initialTimestamp;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
    }

    struct FinalBalanceVerificationVars {
        // Global vault state
        uint256 finalTotalAssets;
        uint256 finalTotalSupply;
        uint256 finalPricePerShare;
        uint256 totalValueLocked;
        // Strategy state
        uint256 fluidBalance;
        uint256 aaveBalance;
        // Escrow state
        uint256 escrowBalance;
        // Yield tracking
        uint256 totalYieldAccrued;
        uint256 yieldPerShare;
        // User accounting
        uint256 totalUserShares;
        uint256 totalUserAssets;
        uint256 totalPendingDeposits;
        uint256 totalPendingRedeems;
        // Per-user state
        uint256 currentShares;
        uint256 currentAssets;
        uint256 expectedShares;
        uint256 expectedAssets;
        uint256 userYieldAccrued;
        bool isRedeemer;
        uint256 redeemedShares;
    }

    struct ScenarioNewYieldSourceVars {
        uint256 depositAmount;
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialNewVaultBalance;
        uint256 amountToReallocateFluidVault;
        uint256 amountToReallocateAaveVault;
        uint256 assetAmountToReallocateFromFluidVault;
        uint256 assetAmountToReallocateFromAaveVault;
        uint256 assetAmountToReallocateToNewVault;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalNewVaultBalance;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        // Price per share tracking
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
    }

    struct VaultLifecycleVars {
        uint256[] userDepositAmounts;
        address[] users;
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        uint256[] userInitialShares;
        uint256[] userInitialAssets;
        uint256[] userFinalShares;
        uint256[] userFinalAssets;
        uint256[] userYields;
    }

    struct RugTestVarsDeposit {
        uint256 depositAmount;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
        uint256 rugPercentage;
        address[] depositUsers;
        uint256[] depositAmounts;
        uint256 initialTimestamp;
        RuggableVault ruggableVault;
    }

    struct RugTestVarsWithdraw {
        bool convertVault;
        uint256 depositAmount;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
        uint256 rugPercentage;
        address[] depositUsers;
        uint256[] depositAmounts;
        address[] redeemUsers;
        uint256[] redeemAmounts;
        uint256 totalRedeemShares;
        uint256 redeemSharesVault1;
        uint256 redeemSharesVault2;
        uint256 initialTimestamp;
        address ruggableVault;
        uint256 initialRuggableVaultBalance;
        uint256 initialFluidVaultBalance;
        uint256 initialRuggableVaultAssets;
        uint256 initialFluidVaultAssets;
        uint256 amountToReallocate;
        uint256 assetAmountToReallocate;
        uint256 finalRuggableVaultBalance;
        uint256 finalFluidVaultBalance;
        uint256 finalRuggableVaultAssets;
        uint256 finalFluidVaultAssets;
        uint256 initialTotalValue;
        uint256 finalTotalValue;
        uint256 vaultTotalAssetsAfterAllocation;
        uint256 pricePerShareAfterAllocation;
        uint256 ppsBeforeWarp;
        uint256 ppsAfterWarp;
        uint256[] expectedAssetsOrSharesOut;
        uint256 assetsVault1;
        uint256 assetsVault2;
        // Added to avoid stack too deep errors
        uint256 finalTotalAssets;
        uint256 finalTotalSupply;
        uint256 totalAssetsPreClaimTaintedAssets;
        uint256 totalSupplyPreClaimTaintedAssets;
        uint256 pricePerSharePreClaimTaintedAssets;
    }

    struct VaultCapTestVars {
        address withdrawHookAddress;
        address depositHookAddress;
        address[] hooksAddresses;
        bytes[] hooksData;
        // Initial setup
        uint256 depositAmount;
        uint256 initialFluidVaultPPS;
        uint256 initialAaveVaultPPS;
        uint256 totalInitialBalance;
        uint256 initialFluidRatio;
        uint256 initialAaveRatio;
        uint256 initialEulerRatio;
        // Vault balances
        uint256 initialFluidVaultBalance;
        uint256 initialAaveVaultBalance;
        uint256 initialEulerVaultBalance;
        // First reallocation (50/25/25)
        uint256 assetsToMove;
        uint256 finalFluidVaultBalance;
        uint256 finalAaveVaultBalance;
        uint256 finalEulerVaultBalance;
        uint256 totalFinalBalance;
        uint256 finalFluidRatio;
        uint256 finalAaveRatio;
        uint256 finalEulerRatio;
        // Second reallocation (40/30/30)
        uint256 newVaultCap;
        uint256 targetFluidAssets2;
        uint256 targetAaveAssets2;
        uint256 targetEulerAssets2;
        uint256 finalFluidVaultBalance2;
        uint256 finalAaveVaultBalance2;
        uint256 finalEulerVaultBalance2;
        uint256 finalFluidRatio2;
        uint256 finalAaveRatio2;
        uint256 finalEulerRatio2;
        uint256 finalTotalValue;
        // misc
        uint256 newSuperVaultCap;
    }

    struct TestVars {
        uint256 initialTimestamp;
        uint256 totalDeposited;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
        uint256 finalTotalAssets;
        uint256 finalTotalSupply;
        uint256 finalPricePerShare;
        uint256 fluidVaultBalance;
        uint256 aaveVaultBalance;
        uint256[] depositAmounts;
        address[] depositUsers;
    }

    struct YieldTestVars {
        uint256 depositAmount;
        uint256 initialTimestamp;
        Mock4626Vault vault1; // 3% yield
        Mock4626Vault vault2; // 5% yield
        Mock4626Vault vault3; // 10% yield
        uint256 initialVault1Balance;
        uint256 initialVault2Balance;
        uint256 initialVault3Balance;
        uint256 initialVault1Assets;
        uint256 initialVault2Assets;
        uint256 initialVault3Assets;
        uint256 finalVault1Assets;
        uint256 finalVault2Assets;
        uint256 finalVault3Assets;
        uint256 initialTotalAssets;
        uint256 initialTotalSupply;
        uint256 initialPricePerShare;
    }

    function test_1_DynamicAllocation() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 100e6;

        // Deploy using Create2.deploy() instead of new{salt} syntax for consistent prediction
        Mock4626Vault newVault = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "New Vault", "NV"))
            )
        );

        console2.log("newVault", address(newVault));
        console2.log("predicted", test1_DynamicAllocation_MockVault);
        assertEq(address(newVault), test1_DynamicAllocation_MockVault, "TEST1 VAULT NOT EQUAL TO PREDICTED");
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(newVault), type(uint256).max);
        newVault.deposit(2 * LARGE_DEPOSIT, address(this));

        // warp before adding a new vault;
        vm.warp(block.timestamp + 20 days);

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // warp again
        vm.warp(block.timestamp + 20 days);

        // create deposit requests for all users
        _depositForAllUsers(vars.depositAmount);

        // create fullfillment data
        uint256 totalAmount = vars.depositAmount * ACCOUNT_COUNT;
        uint256 allocationAmountVault1 = totalAmount * 40 / 100;
        uint256 allocationAmountVault2 = totalAmount * 30 / 100;
        uint256 allocationAmountVault3 = totalAmount * 30 / 100;

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill deposits
        _depositFreeAssets(
            address(fluidVault),
            address(aaveVault),
            address(newVault),
            allocationAmountVault1,
            allocationAmountVault2,
            allocationAmountVault3
        );

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial NewVault balance:", vars.initialNewVaultBalance);

        _test_1_performReallocation(vars, newVault);

        console2.log("\n=== Enhanced Vault Metrics ===");
        uint256 fluidVaultFinalPPS = fluidVault.convertToAssets(1e18);
        uint256 aaveVaultFinalPPS = aaveVault.convertToAssets(1e18);
        uint256 newVaultFinalPPS = newVault.convertToAssets(1e18);

        console2.log("\nPrice per Share Changes:");
        console2.log("Fluid Vault:");
        console2.log("  Initial PPS:", vars.initialFluidVaultPPS);
        console2.log("  Final PPS:", fluidVaultFinalPPS);
        console2.log(
            "  Change:",
            fluidVaultFinalPPS > vars.initialFluidVaultPPS ? "+" : "",
            fluidVaultFinalPPS - vars.initialFluidVaultPPS
        );
        console2.log(
            "  Change %:", ((fluidVaultFinalPPS - vars.initialFluidVaultPPS) * 10_000) / vars.initialFluidVaultPPS
        );

        console2.log("\nAave Vault:");
        console2.log("  Initial PPS:", vars.initialAaveVaultPPS);
        console2.log("  Final PPS:", aaveVaultFinalPPS);
        console2.log(
            "  Change:",
            aaveVaultFinalPPS > vars.initialAaveVaultPPS ? "+" : "",
            aaveVaultFinalPPS - vars.initialAaveVaultPPS
        );
        console2.log(
            "  Change %:", ((aaveVaultFinalPPS - vars.initialAaveVaultPPS) * 10_000) / vars.initialAaveVaultPPS
        );

        console2.log("\nYield Metrics:");
        uint256 totalYield =
            vars.finalTotalValue > vars.initialTotalValue ? vars.finalTotalValue - vars.initialTotalValue : 0;
        console2.log("Total Yield:", totalYield);
        console2.log("Yield %:", (totalYield * 10_000) / vars.initialTotalValue);

        assertGe(fluidVaultFinalPPS, vars.initialFluidVaultPPS, "Fluid Vault should not lose value");
        assertGe(aaveVaultFinalPPS, vars.initialAaveVaultPPS, "Aave Vault should not lose value");
        assertGe(newVaultFinalPPS, 1e18, "NewVault should not lose value");

        uint256 totalFinalBalance = vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalNewVaultBalance;
        uint256 fluidRatio = (vars.finalFluidVaultBalance * 100) / totalFinalBalance;
        uint256 aaveRatio = (vars.finalAaveVaultBalance * 100) / totalFinalBalance;
        uint256 newRatio = (vars.finalNewVaultBalance * 100) / totalFinalBalance;

        console2.log("\nFinal Allocation Ratios:");
        console2.log("Fluid Vault:", fluidRatio, "%");
        console2.log("Aave Vault:", aaveRatio, "%");
        console2.log("NewVault:", newRatio, "%");
    }

    function _test_1_performReallocation(ScenarioNewYieldSourceVars memory vars, Mock4626Vault newVault) private {
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        vars.amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        vars.assetAmountToReallocateToNewVault =
            vars.assetAmountToReallocateFromFluidVault + vars.assetAmountToReallocateFromAaveVault;

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);
        console2.log("Asset amount to reallocate from MocmVault:", vars.assetAmountToReallocateToNewVault);

        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        bytes[] memory hooksData = new bytes[](3);

        // Setup hooks
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );

        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );

        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(newVault),
            address(asset),
            vars.assetAmountToReallocateToNewVault,
            false,
            address(0),
            0
        );

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        // Perform allocation
        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](3)
            })
        );
        vm.stopPrank();
        vm.warp(block.timestamp + 20 days);

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("NewVault balance:", vars.finalNewVaultBalance);

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + newVault.convertToAssets(vars.initialNewVaultBalance);
        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance) + newVault.convertToAssets(vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total value should be preserved during allocation - after first reallocation"
        );

        // Verify balance changes
        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - vars.amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - vars.amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalNewVaultBalance, vars.initialNewVaultBalance, "NewVault balance should increase");

        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));
        vars.assetAmountToReallocateToNewVault = newVault.convertToAssets(vars.initialNewVaultBalance);
        vars.assetAmountToReallocateFromFluidVault = vars.assetAmountToReallocateToNewVault * 30 / 100;
        vars.assetAmountToReallocateFromAaveVault =
            vars.initialNewVaultBalance - vars.assetAmountToReallocateFromFluidVault; // the rest goes here

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);
        console2.log("Asset amount to reallocate from MocmVault:", vars.assetAmountToReallocateToNewVault);

        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;
        hooksAddresses[2] = depositHookAddress;

        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(newVault),
            address(strategy),
            vars.assetAmountToReallocateToNewVault,
            false
        );

        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            vars.assetAmountToReallocateFromFluidVault,
            false,
            address(0),
            0
        );

        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            vars.assetAmountToReallocateFromAaveVault,
            false,
            address(0),
            0
        );
        argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        // Perform allocation
        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](3)
            })
        );
        vm.stopPrank();
        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("NewVault balance:", vars.finalNewVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance) + newVault.convertToAssets(vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total value should be preserved during allocation - after second reallocation"
        );
    }

    function test_2_MultipleOperations_RandomAmounts(uint256 seed) public {
        MultipleOperationsVars memory vars;
        // Setup random seed and initial timestamp
        vars.initialTimestamp = block.timestamp;
        vars.seed = seed;
        // Generate random deposit amounts for all users (20 users)
        vars.depositAmounts = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            // Use the seed to generate random amounts
            // 50% chance for large amount (1M-2M), 50% chance for small amount (100-1000)
            uint256 rand = uint256(keccak256(abi.encodePacked(vars.seed, i)));
            if (rand % 2 == 0) {
                // Large amount: 1M-2M USDC
                vars.depositAmounts[i] = 1_000_000e6 + (rand % 1_000_000e6);
            } else {
                // Small amount: 100-1000 USDC
                vars.depositAmounts[i] = 100e6 + (rand % 900e6);
            }
        }

        _completeDepositFlowWithVaryingAmounts(vars.depositAmounts);

        _updateSuperVaultPPS(address(strategy), address(vault));

        // Store initial state for yield verification
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        //vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply,
        // Math.Rounding.Floor);

        // Verify initial balances and shares
        _verifyInitialBalances(vars.depositAmounts);

        // Simulate time passing (1 day) to accumulate some yield
        vm.warp(vars.initialTimestamp + 1 days);
        console2.log("\n=== After 1 day ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Setup redemption arrays
        vars.redeemUsers = new address[](15);
        vars.redeemAmounts = new uint256[](15);
        vars.selected = new bool[](ACCOUNT_COUNT);

        // Select random users for redemption
        vars = _selectRandomUsersForRedemption(vars);

        // Simulate some more time passing (12 days) before redemption requests
        vm.warp(vars.initialTimestamp + 10 days);
        _updateSuperVaultPPS(address(strategy), address(vault));
        vars.initialPricePerShare = strategy.getStoredPPS();
        console2.log("\n=== After 10 days ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Request redemptions
        _processRedemptionRequests(vars);

        // Calculate total redemption amount for allocation
        for (uint256 i; i < 15; i++) {
            vars.totalRedeemShares += vars.redeemAmounts[i];
        }

        // Simulate time passing (6 hours) before fulfilling redemptions
        vm.warp(vars.initialTimestamp + 10 days + 6 hours);
        console2.log("\n=== After 10 days and 6 hours ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Fulfill redemptions
        vars.redeemSharesVault1 = vars.totalRedeemShares / 2;
        vars.redeemSharesVault2 = vars.totalRedeemShares - vars.redeemSharesVault1;
        _fulfillRedeemForUsers(
            vars.redeemUsers, vars.redeemSharesVault1, vars.redeemSharesVault2, address(fluidVault), address(aaveVault)
        );

        // Simulate final time passing before final verification
        vm.warp(vars.initialTimestamp + 11 days);
        // Process claims for redeemed users
        _claimRedeemForUsers(vars.redeemUsers);

        console2.log("\n=== After 11 days ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", vault.totalAssets().mulDiv(1e18, vault.totalSupply(), Math.Rounding.Floor));

        // Verify final balances and shares
        _verifyFinalBalances(vars);
    }

    function test_3_UnderlyingVaults_StressTest() public {
        RugTestVarsWithdraw memory vars;

        // A vault that is rugged on deposit and on withdraw; 10% rug
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 10;
        vars.initialTimestamp = block.timestamp;

        vars.ruggableVault = Create2.deploy(
            0,
            keccak256(abi.encodePacked(TEST_SALT)),
            abi.encodePacked(
                type(RuggableVault).creationCode,
                abi.encode(IERC20(address(asset)), "Ruggable Vault", "RUG", true, true, vars.rugPercentage)
            )
        );

        vm.label(vars.ruggableVault, "Ruggable Vault");
        vm.label(address(fluidVault), "Fluid Vault");

        console2.log("ruggable vault", vars.ruggableVault);
        assertEq(vars.ruggableVault, test3_UnderlyingVaults_StressTest, "TEST3 VAULT NOT EQUAL TO PREDICTED");
        console2.log("fluid vault", address(fluidVault));

        // add some funds to the vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(vars.ruggableVault), type(uint256).max);
        RuggableVault(vars.ruggableVault).deposit(2 * LARGE_DEPOSIT, address(this));

        // create SV with fluid and this ruggable vault
        _deployNewSuperVaultWithRuggableVault(address(vars.ruggableVault));

        // users to deposit and withdraw
        vars.depositUsers = new address[](2);
        vars.depositAmounts = new uint256[](2);

        for (uint256 i; i < 2; ++i) {
            vars.depositUsers[i] = accInstances[i].account;
            vars.depositAmounts[i] = vars.depositAmount;
        }

        // perform deposit operations
        for (uint256 i; i < 2; ++i) {
            _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
            vm.startPrank(vars.depositUsers[i]);
            asset.approve(address(vault), vars.depositAmounts[i]);
            vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
            vm.stopPrank();
        }

        vm.warp(vars.initialTimestamp + 1 days);

        uint256 totalAmount = vars.depositAmount * 2;
        uint256 allocationAmountVault1 = totalAmount / 2;
        uint256 allocationAmountVault2 = totalAmount - allocationAmountVault1;

        // put 50-50 in each vault
        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = fluidVault.previewDeposit(allocationAmountVault1);
        expectedAssetsOrSharesOut[1] = IERC4626(vars.ruggableVault).previewDeposit(allocationAmountVault2);

        for (uint256 i; i < expectedAssetsOrSharesOut.length; i++) {
            expectedAssetsOrSharesOut[i] = expectedAssetsOrSharesOut[i] - expectedAssetsOrSharesOut[i] * 1e3 / 1e5;
        }

        _depositFreeAssets(
            allocationAmountVault1,
            allocationAmountVault2,
            address(fluidVault),
            address(vars.ruggableVault),
            expectedAssetsOrSharesOut,
            bytes4(0)
        );
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", RuggableVault(vars.ruggableVault).balanceOf(address(strategy)));

        vm.warp(block.timestamp + 12 weeks);

        uint256 prevPps = vars.initialPricePerShare;
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", RuggableVault(vars.ruggableVault).balanceOf(address(strategy)));

        assertApproxEqRel(vars.initialPricePerShare, prevPps, 0.1e18, "Price per share should be preserved");

        // redeem from 1 user
        vars.redeemUsers = new address[](1);
        vars.redeemAmounts = new uint256[](1);
        vars.totalRedeemShares = 0;

        vars.redeemUsers[0] = vars.depositUsers[0];
        vars.redeemAmounts[0] = vault.balanceOf(vars.redeemUsers[0]);
        assertGt(vars.redeemAmounts[0], 0, "Redeem amount should be greater than 0");
        vars.totalRedeemShares += vars.redeemAmounts[0];

        vm.startPrank(vars.redeemUsers[0]);
        vault.requestRedeem(vars.redeemAmounts[0], vars.redeemUsers[0], vars.redeemUsers[0]);
        vm.stopPrank();

        vars.redeemSharesVault1 = vars.totalRedeemShares / 2;
        vars.redeemSharesVault2 = vars.totalRedeemShares - vars.redeemSharesVault1;

        vars.assetsVault1 = vault.convertToAssets(vars.redeemSharesVault1);
        vars.assetsVault2 = vault.convertToAssets(vars.redeemSharesVault2);

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = vars.assetsVault1;
        vars.expectedAssetsOrSharesOut[1] = vars.assetsVault2;
        _fulfillRedeemForUsers(
            vars.redeemUsers,
            vars.redeemSharesVault1,
            vars.redeemSharesVault2,
            address(fluidVault),
            vars.ruggableVault,
            vars.expectedAssetsOrSharesOut,
            bytes4(0)
        );

        vm.warp(block.timestamp + 12 weeks);
        prevPps = vars.initialPricePerShare;
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", RuggableVault(vars.ruggableVault).balanceOf(address(strategy)));

        assertApproxEqRel(vars.initialPricePerShare, prevPps, 0.1e18, "Price per share should be preserved");
    }

    function test_4_Rebalance_Test() public {
        VaultCapTestVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // Initial allocation - this will put the first two vaults at ~50/50
        _completeDepositFlow(vars.depositAmount);

        // Add Euler vault as a new yield source
        address eulerVaultAddr = CHAIN_1_EULER_VAULT;
        vm.label(eulerVaultAddr, "EulerVault");
        IERC4626 eulerVault = IERC4626(eulerVaultAddr);

        // Add funds to the Euler vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(eulerVaultAddr, type(uint256).max);
        eulerVault.deposit(2 * LARGE_DEPOSIT, address(this));

        vm.warp(block.timestamp + 20 days);

        // Add Euler vault as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(eulerVaultAddr, _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // Get initial balances
        vars.initialFluidVaultBalance = fluidVault.convertToAssets(fluidVault.balanceOf(address(strategy)));
        vars.initialAaveVaultBalance = aaveVault.convertToAssets(aaveVault.balanceOf(address(strategy)));
        vars.initialEulerVaultBalance = eulerVault.convertToAssets(eulerVault.balanceOf(address(strategy)));

        console2.log("\n=== Initial Balances ===");
        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial EulerVault balance:", vars.initialEulerVaultBalance);

        // Calculate initial allocation percentages
        vars.totalInitialBalance =
            vars.initialFluidVaultBalance + vars.initialAaveVaultBalance + vars.initialEulerVaultBalance;
        vars.initialFluidRatio = (vars.initialFluidVaultBalance * 10_000) / vars.totalInitialBalance;
        vars.initialAaveRatio = (vars.initialAaveVaultBalance * 10_000) / vars.totalInitialBalance;
        vars.initialEulerRatio = (vars.initialEulerVaultBalance * 10_000) / vars.totalInitialBalance;

        console2.log("\n=== Initial Allocation Ratios ===");
        console2.log("Fluid Vault:", vars.initialFluidRatio / 100, "%");
        console2.log("Aave Vault:", vars.initialAaveRatio / 100, "%");
        console2.log("Euler Vault:", vars.initialEulerRatio / 100, "%");

        // First reallocation: Change to 50/25/25 (fluid/aave/euler)
        console2.log("\n=== First Reallocation: Target 50/25/25 ===");

        // Set up hooks for reallocation
        vars.withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        vars.depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        // Perform first reallocation to 50/25/25
        (
            vars.finalFluidVaultBalance,
            vars.finalAaveVaultBalance,
            vars.finalEulerVaultBalance,
            vars.finalFluidRatio,
            vars.finalAaveRatio,
            vars.finalEulerRatio
        ) = _reallocate(
            ReallocateArgs({
                vault1: fluidVault,
                vault2: aaveVault,
                vault3: eulerVault,
                targetVault1Percentage: 5000, // 50%
                targetVault2Percentage: 2500, // 25%
                targetVault3Percentage: 2500, // 25%
                withdrawHookAddress: vars.withdrawHookAddress,
                depositHookAddress: vars.depositHookAddress
            })
        );

        // Verify the allocation is close to 50/25/25
        assertApproxEqRel(vars.finalFluidRatio, 5000, 0.05e18, "Fluid allocation should be close to 50%");
        assertApproxEqRel(vars.finalAaveRatio, 2500, 0.05e18, "Aave allocation should be close to 25%");
        assertApproxEqRel(vars.finalEulerRatio, 2500, 0.05e18, "Euler allocation should be close to 25%");

        // Second reallocation: Change to 40/30/30 (fluid/aave/euler)
        console2.log("\n=== Second Reallocation: Target 40/30/30 ===");

        // Calculate target balances for 40/30/30 allocation
        vars.totalFinalBalance = vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalEulerVaultBalance;
        vars.targetFluidAssets2 = vars.totalFinalBalance * 4000 / 10_000;
        vars.targetAaveAssets2 = vars.totalFinalBalance * 3000 / 10_000;
        vars.targetEulerAssets2 = vars.totalFinalBalance * 3000 / 10_000;

        console2.log("Total Assets:", vars.totalFinalBalance);
        console2.log("Target Fluid Assets:", vars.targetFluidAssets2);
        console2.log("Target Aave Assets:", vars.targetAaveAssets2);
        console2.log("Target Euler Assets:", vars.targetEulerAssets2);

        console2.log("Target Aave assets would exceed vault cap!");
        console2.log("Vault Cap:", vars.newSuperVaultCap);
        console2.log("Target Aave Assets:", vars.targetAaveAssets2);
    }

    function test_5_EdgeCases_Small_Amounts() public {
        uint256 depositAmount = 100; // very small

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        uint256 totalRedeemShares;
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            totalRedeemShares += vaultBalance;
        }

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fullfillment data
        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill redeem
        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // check that all pending requests are cleared
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_5_EdgeCases_SmallAmounts_WithAllocation() public {
        uint256 depositAmount = 100; // very small

        _completeDepositFlow(depositAmount);

        uint256 fluidShares = fluidVault.balanceOf(address(strategy));
        uint256 aaveShares = aaveVault.balanceOf(address(strategy));

        uint256 currentFluidVaultAssets = fluidVault.convertToAssets(fluidShares);
        uint256 currentAaveVaultAssets = aaveVault.convertToAssets(aaveShares);
        uint256 totalAssets = currentFluidVaultAssets + currentAaveVaultAssets;

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        hooksAddresses[1] = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        bytes[] memory hooksData = new bytes[](2);

        uint256 amountToReallocate = fluidShares.mulDiv(3000, 10_000);
        uint256 assetAmountToReallocate = fluidVault.convertToAssets(amountToReallocate);

        _rebalanceFromVaultToVault(
            hooksAddresses,
            hooksData,
            address(fluidVault),
            address(aaveVault),
            currentFluidVaultAssets + assetAmountToReallocate,
            currentAaveVaultAssets
        );

        uint256 finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        uint256 finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        uint256 finalFluidVaultAssets = fluidVault.previewRedeem(finalFluidVaultBalance);
        uint256 finalAaveVaultAssets = aaveVault.previewRedeem(finalAaveVaultBalance);

        uint256 finalTotalAssets = finalFluidVaultAssets + finalAaveVaultAssets;

        assertApproxEqRel(finalTotalAssets, totalAssets, 0.05e18, "Total value should be preserved");

        _requestRedeemForAllUsers(0);

        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        _fulfillRedeemForUsers(
            requestingUsers, finalFluidVaultAssets, finalAaveVaultAssets, address(fluidVault), address(aaveVault)
        );

        // check that all pending requests are cleared
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_5_EdgeCases_Large_Amounts() public {
        uint256 depositAmount = 2_000_000e6; // very big

        // perform deposit operations
        _completeDepositFlow(depositAmount);

        uint256 totalRedeemShares;
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            uint256 vaultBalance = vault.balanceOf(accInstances[i].account);
            totalRedeemShares += vaultBalance;
        }

        // request redeem for all users
        _requestRedeemForAllUsers(0);

        // create fullfillment data
        uint256 allocationAmountVault1 = totalRedeemShares / 2;
        uint256 allocationAmountVault2 = totalRedeemShares - allocationAmountVault1;
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        // fulfill redeem
        _fulfillRedeemForUsers(
            requestingUsers, allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault)
        );

        // check that all pending requests are cleared
        for (uint256 i; i < ACCOUNT_COUNT; ++i) {
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0);
            assertGt(strategy.claimableWithdraw(accInstances[i].account), 0);
        }
    }

    function test_6_yieldAccumulation() public {
        YieldTestVars memory vars;
        vars.depositAmount = 1000e6; // 100,000 USDC
        vars.initialTimestamp = block.timestamp;

        // create yield testing vaults
        vars.vault1 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock4626Vault 3%", "MV3")
                )
            )
        );
        vars.vault2 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock4626Vault 5%", "MV5")
                )
            )
        );
        vars.vault3 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock4626Vault 10%", "MV10")
                )
            )
        );
        string[] memory vaultNames = new string[](3);
        vaultNames[0] = "test6YA_Mock4626Vault1";
        vaultNames[1] = "test6YA_Mock4626Vault2";
        vaultNames[2] = "test6YA_Mock4626Vault3";
        address[] memory vaultAddresses = new address[](3);
        vaultAddresses[0] = address(vars.vault1);
        vaultAddresses[1] = address(vars.vault2);
        vaultAddresses[2] = address(vars.vault3);

        console2.log("vault1", address(vars.vault1));
        console2.log("vault2", address(vars.vault2));
        console2.log("vault3", address(vars.vault3));

        assertEq(address(vars.vault1), test6_yieldAccumulation_vault1, "TEST6 VAULT1 NOT EQUAL TO PREDICTED");
        assertEq(address(vars.vault2), test6_yieldAccumulation_vault2, "TEST6 VAULT2 NOT EQUAL TO PREDICTED");
        assertEq(address(vars.vault3), test6_yieldAccumulation_vault3, "TEST6 VAULT3 NOT EQUAL TO PREDICTED");

        vars.vault1.setYield(3000); // 3%
        vars.vault2.setYield(5000); // 5%
        vars.vault3.setYield(10_000); // 10%

        // add some funds to each vault to bypass the VAULT_THRESHOLD_EXCEEDED error
        _getTokens(address(asset), address(this), 10 * LARGE_DEPOSIT);
        asset.approve(address(vars.vault1), type(uint256).max);
        asset.approve(address(vars.vault2), type(uint256).max);
        asset.approve(address(vars.vault3), type(uint256).max);
        vars.vault1.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault2.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault3.deposit(2 * LARGE_DEPOSIT, address(this));

        // add vaults to SV
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(vars.vault1), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault2), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault3), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // use 3 users to perform deposits
        for (uint256 i; i < 3; ++i) {
            _getTokens(address(asset), accInstances[i].account, vars.depositAmount);
            _depositForAccount(accInstances[i], vars.depositAmount);
        }

        // fulfill deposits
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory fulfillHooksAddresses = new address[](3);
        fulfillHooksAddresses[0] = depositHookAddress;
        fulfillHooksAddresses[1] = depositHookAddress;
        fulfillHooksAddresses[2] = depositHookAddress;

        bytes[] memory fulfillHooksData = new bytes[](3);
        // allocate up to the max allocation rate in the two Vaults
        fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.vault1),
            address(asset),
            vars.depositAmount,
            false,
            address(0),
            0
        );
        fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.vault2),
            address(asset),
            vars.depositAmount,
            false,
            address(0),
            0
        );
        fulfillHooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(vars.vault3),
            address(asset),
            vars.depositAmount,
            false,
            address(0),
            0
        );

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](3);
        expectedAssetsOrSharesOut[0] = IERC4626(address(vars.vault1)).convertToShares(vars.depositAmount);
        expectedAssetsOrSharesOut[1] = IERC4626(address(vars.vault2)).convertToShares(vars.depositAmount);
        expectedAssetsOrSharesOut[2] = IERC4626(address(vars.vault3)).convertToShares(vars.depositAmount);

        address[] memory requestingUsers = new address[](3);
        for (uint256 i; i < 3; ++i) {
            requestingUsers[i] = accInstances[i].account;
        }

        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
        argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);
        argsForProofs[2] = ISuperHookInspector(fulfillHooksAddresses[2]).inspect(fulfillHooksData[2]);

        vm.startPrank(MANAGER);
        console2.log("Executing hooks");
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: fulfillHooksAddresses,
                hookCalldata: fulfillHooksData,
                expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](fulfillHooksAddresses.length)
            })
        );
        console2.log("Hooks executed");
        vm.stopPrank();

        vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
        vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
        vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));

        vars.initialVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
        vars.initialVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
        vars.initialVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

        // fast forward time to simulate yield accumulation
        vm.warp(vars.initialTimestamp + 1 weeks);

        vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
        vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
        vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));

        vars.finalVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
        vars.finalVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
        vars.finalVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

        console2.log("initialVault1Assets", vars.initialVault1Assets);
        console2.log("finalVault1Assets  ", vars.finalVault1Assets);
        console2.log("initialVault2Assets", vars.initialVault2Assets);
        console2.log("finalVault2Assets  ", vars.finalVault2Assets);
        console2.log("initialVault3Assets", vars.initialVault3Assets);
        console2.log("finalVault3Assets  ", vars.finalVault3Assets);

        assertGt(vars.finalVault1Assets, vars.initialVault1Assets, "Vault 1 should have gained assets");
        assertGt(vars.finalVault2Assets, vars.initialVault2Assets, "Vault 2 should have gained assets");
        assertGt(vars.finalVault3Assets, vars.initialVault3Assets, "Vault 3 should have gained assets");

        uint256 vault1Yield = vars.finalVault1Assets - vars.initialVault1Assets;
        uint256 vault2Yield = vars.finalVault2Assets - vars.initialVault2Assets;
        uint256 vault3Yield = vars.finalVault3Assets - vars.initialVault3Assets;
        console2.log("vault1Yield", vault1Yield);
        console2.log("vault2Yield", vault2Yield);
        console2.log("vault3Yield", vault3Yield);

        assertGt(vault1Yield, 0, "Vault 1 should have gained assets");
        assertGt(vault2Yield, vault1Yield, "Vault 2 should have gained more assets than vault 1");
        assertGt(vault3Yield, vault2Yield, "Vault 3 should have gained more assets than vault 2");
    }

    function test_6_yieldAccumulation_WithRebalancing() public {
        YieldTestVars memory vars;
        vars.depositAmount = 1000e6; // 100,000 USDC
        vars.initialTimestamp = block.timestamp;

        // create yield testing vaults
        vars.vault1 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock Vault 3%", "MV3"))
            )
        );
        vars.vault2 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock Vault 5%", "MV5"))
            )
        );
        vars.vault3 = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "Mock Vault 10%", "MV10"))
            )
        );
        string[] memory vaultNames = new string[](3);
        vaultNames[0] = "test6YAREB_Mock4626Vault1";
        vaultNames[1] = "test6YAREB_Mock4626Vault2";
        vaultNames[2] = "test6YAREB_Mock4626Vault3";
        address[] memory vaultAddresses = new address[](3);
        vaultAddresses[0] = address(vars.vault1);
        vaultAddresses[1] = address(vars.vault2);
        vaultAddresses[2] = address(vars.vault3);

        console2.log("vault1", address(vars.vault1));
        console2.log("vault2", address(vars.vault2));
        console2.log("vault3", address(vars.vault3));

        assertEq(
            address(vars.vault1),
            test6_yieldAccumulation_WithRebalancing_vault1,
            "TEST6_REBAL_VAULT1 NOT EQUAL TO PREDICTED"
        );
        assertEq(
            address(vars.vault2),
            test6_yieldAccumulation_WithRebalancing_vault2,
            "TEST6_REBAL_VAULT2 NOT EQUAL TO PREDICTED"
        );
        assertEq(
            address(vars.vault3),
            test6_yieldAccumulation_WithRebalancing_vault3,
            "TEST6_REBAL_VAULT3 NOT EQUAL TO PREDICTED"
        );

        vars.vault1.setYield(3000); // 3%
        vars.vault2.setYield(5000); // 5%
        vars.vault3.setYield(10_000); // 10%

        // add some funds to each vault to bypass the VAULT_THRESHOLD_EXCEEDED error
        _getTokens(address(asset), address(this), 10 * LARGE_DEPOSIT);
        asset.approve(address(vars.vault1), type(uint256).max);
        asset.approve(address(vars.vault2), type(uint256).max);
        asset.approve(address(vars.vault3), type(uint256).max);
        vars.vault1.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault2.deposit(2 * LARGE_DEPOSIT, address(this));
        vars.vault3.deposit(2 * LARGE_DEPOSIT, address(this));

        // add vaults to SV
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(vars.vault1), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault2), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        strategy.manageYieldSource(address(vars.vault3), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // use 3 users to perform deposits
        for (uint256 i; i < 3; ++i) {
            _getTokens(address(asset), accInstances[i].account, vars.depositAmount);
            _depositForAccount(accInstances[i], vars.depositAmount);
        }

        // fulfill deposits
        {
            address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

            address[] memory fulfillHooksAddresses = new address[](3);
            fulfillHooksAddresses[0] = depositHookAddress;
            fulfillHooksAddresses[1] = depositHookAddress;
            fulfillHooksAddresses[2] = depositHookAddress;

            bytes[] memory fulfillHooksData = new bytes[](3);
            // allocate up to the max allocation rate in the two Vaults
            fulfillHooksData[0] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(vars.vault1),
                address(asset),
                vars.depositAmount,
                false,
                address(0),
                0
            );
            fulfillHooksData[1] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(vars.vault2),
                address(asset),
                vars.depositAmount,
                false,
                address(0),
                0
            );
            fulfillHooksData[2] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(vars.vault3),
                address(asset),
                vars.depositAmount,
                false,
                address(0),
                0
            );

            uint256[] memory expectedAssetsOrSharesOut = new uint256[](3);
            expectedAssetsOrSharesOut[0] = IERC4626(address(vars.vault1)).convertToShares(vars.depositAmount);
            expectedAssetsOrSharesOut[1] = IERC4626(address(vars.vault2)).convertToShares(vars.depositAmount);
            expectedAssetsOrSharesOut[2] = IERC4626(address(vars.vault3)).convertToShares(vars.depositAmount);

            address[] memory requestingUsers = new address[](3);
            for (uint256 i; i < 3; ++i) {
                requestingUsers[i] = accInstances[i].account;
            }

            bytes[] memory argsForProofs = new bytes[](3);
            argsForProofs[0] = ISuperHookInspector(fulfillHooksAddresses[0]).inspect(fulfillHooksData[0]);
            argsForProofs[1] = ISuperHookInspector(fulfillHooksAddresses[1]).inspect(fulfillHooksData[1]);
            argsForProofs[2] = ISuperHookInspector(fulfillHooksAddresses[2]).inspect(fulfillHooksData[2]);

            vm.startPrank(MANAGER);
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: fulfillHooksAddresses,
                    hookCalldata: fulfillHooksData,
                    expectedAssetsOrSharesOut: expectedAssetsOrSharesOut,
                    globalProofs: _getMerkleProofsForHooks(fulfillHooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](fulfillHooksAddresses.length)
                })
            );
            vm.stopPrank();
        }

        {
            vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
            vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
            vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));
            vars.initialVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
            vars.initialVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
            vars.initialVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

            address[] memory hooksAddresses = new address[](2);
            hooksAddresses[0] = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
            hooksAddresses[1] = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);
            bytes[] memory hooksData = new bytes[](2);

            uint256 amountToReallocate = vars.initialVault2Balance * 10 / 100; //10%
            uint256 assetAmountToReallocate = vars.vault2.convertToAssets(amountToReallocate);

            _rebalanceFixedAmountFromVaultToVault(
                hooksAddresses, hooksData, address(vars.vault2), address(vars.vault1), assetAmountToReallocate
            );

            // fast forward time to simulate yield accumulation
            vm.warp(vars.initialTimestamp + 1 weeks);
            _updateSuperVaultPPS(address(strategy), address(vault));
            vars.initialVault1Balance = vars.vault1.balanceOf(address(strategy));
            vars.initialVault2Balance = vars.vault2.balanceOf(address(strategy));
            vars.initialVault3Balance = vars.vault3.balanceOf(address(strategy));
            vars.finalVault1Assets = vars.vault1.convertToAssets(vars.initialVault1Balance);
            vars.finalVault2Assets = vars.vault2.convertToAssets(vars.initialVault2Balance);
            vars.finalVault3Assets = vars.vault3.convertToAssets(vars.initialVault3Balance);

            assertGt(
                vars.finalVault1Assets + vars.finalVault2Assets + vars.finalVault3Assets,
                vars.initialVault1Assets + vars.initialVault2Assets + vars.initialVault3Assets,
                "Total assets should have increased"
            );
        }
    }

    function test_9_VaultLifecycle_FullAlocateOverTime_() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // do an initial allocation
        _completeDepositFlow(vars.depositAmount);

        uint256[] memory initialUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory initialUserShares = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            initialUserShares[i] = vault.balanceOf(accInstances[i].account);
        }

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory midUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory midUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            midUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            midUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(midUserAssets[i], initialUserAssets[i], "User assets should increase after 20 days");
            assertEq(midUserShares[i], initialUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Yield after 20 days ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Current Assets:", midUserAssets[i]);
            console2.log("Yield:", midUserAssets[i] - initialUserAssets[i]);
            console2.log("Yield %:", ((midUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]);
        }

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        // 100% to aave allocation
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory finalUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory finalUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }

        // allocation; fluid -> aave
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](2);
        // redeem from fluid entirely
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // deposit to aave
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            vars.assetAmountToReallocateFromFluidVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        assertEq(vars.finalFluidVaultBalance, 0, "FluidVault balance should be 0");
        assertGt(vars.finalAaveVaultBalance, vars.initialAaveVaultBalance, "AaveVault balance should increase");

        vm.warp(block.timestamp + 20 days);

        // 80% to aave allocation
        vars.amountToReallocateAaveVault = vars.finalAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        // re-allocate back to fluid; withdraw from aave (20%)
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to fluid
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            vars.assetAmountToReallocateFromAaveVault,
            false,
            address(0),
            0
        );
        argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total final value should be preserved during allocation"
        );

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }
    }

    function test_9_VaultLifecycle_AddAndRemoveOverTime() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // do an initial allocation
        _completeDepositFlow(vars.depositAmount);

        uint256[] memory initialUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory initialUserShares = new uint256[](ACCOUNT_COUNT);
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            initialUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            initialUserShares[i] = vault.balanceOf(accInstances[i].account);
        }

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory midUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory midUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            midUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            midUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(midUserAssets[i], initialUserAssets[i], "User assets should increase after 20 days");
            assertEq(midUserShares[i], initialUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Yield after 20 days ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Current Assets:", midUserAssets[i]);
            console2.log("Yield:", midUserAssets[i] - initialUserAssets[i]);
            console2.log("Yield %:", ((midUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]);
        }

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);

        // 100% to aave allocation
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);

        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        uint256[] memory finalUserAssets = new uint256[](ACCOUNT_COUNT);
        uint256[] memory finalUserShares = new uint256[](ACCOUNT_COUNT);

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }

        // allocation; fluid -> aave
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](2);
        // redeem from fluid entirely
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // deposit to aave
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(asset),
            vars.assetAmountToReallocateFromFluidVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();

        // remove fluid vault entirely
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(fluidVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 2);
        vm.stopPrank();

        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance);
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance);

        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        assertEq(vars.finalFluidVaultBalance, 0, "FluidVault balance should be 0");
        assertGt(vars.finalAaveVaultBalance, vars.initialAaveVaultBalance, "AaveVault balance should increase");

        vm.warp(block.timestamp + 20 days);

        // 80% to aave allocation
        vars.amountToReallocateAaveVault = vars.finalAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        // re-allocate back to fluid; withdraw from aave (20%)
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to fluid
        hooksData[1] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(asset),
            vars.assetAmountToReallocateFromAaveVault,
            false,
            address(0),
            0
        );
        argsForProofs = new bytes[](2);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

        // re-add fluid vault
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(fluidVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        // try allocate again
        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](2),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();
        vars.finalTotalValue = aaveVault.convertToAssets(vars.finalAaveVaultBalance)
            + fluidVault.convertToAssets(vars.finalFluidVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue,
            vars.initialTotalValue,
            0.01e18,
            "Total final value should be preserved during allocation"
        );

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            finalUserAssets[i] = vault.convertToAssets(vault.balanceOf(accInstances[i].account));
            finalUserShares[i] = vault.balanceOf(accInstances[i].account);

            assertGt(finalUserAssets[i], midUserAssets[i], "User assets should increase after reallocation");
            assertEq(finalUserShares[i], midUserShares[i], "User shares should remain constant");

            console2.log(string.concat("\n=== User ", Strings.toString(i), " Final Yield ==="));
            console2.log("Initial Assets:", initialUserAssets[i]);
            console2.log("Mid Assets:", midUserAssets[i]);
            console2.log("Final Assets:", finalUserAssets[i]);
            console2.log("Total Yield:", finalUserAssets[i] - initialUserAssets[i]);
            console2.log(
                "Total Yield %:", ((finalUserAssets[i] - initialUserAssets[i]) * 10_000) / initialUserAssets[i]
            );
            console2.log("Post-Reallocation Yield:", finalUserAssets[i] - midUserAssets[i]);
            console2.log(
                "Post-Reallocation Yield %:", ((finalUserAssets[i] - midUserAssets[i]) * 10_000) / midUserAssets[i]
            );
        }
    }

    // function test_10_RuggableVault_Deposit_No_ExpectedAssetsOrSharesOut() public {
    //     RugTestVarsDeposit memory vars;
    //     vars.depositAmount = 1000e6;
    //     vars.rugPercentage = 10; // 0.1% rug
    //     vars.initialTimestamp = block.timestamp;

    //     // Deploy a ruggable vault that rugs on deposit
    //     vars.ruggableVault = new RuggableVault(
    //         IERC20(address(asset)),
    //         "Ruggable Vault",
    //         "RUG",
    //         true, // rug on deposit
    //         false, // don't rug on withdraw
    //         vars.rugPercentage
    //     );

    //     // Add funds to the ruggable vault to respect LARGE_DEPOSIT
    //     _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
    //     asset.approve(address(vars.ruggableVault), type(uint256).max);
    //     vars.ruggableVault.deposit(2 * LARGE_DEPOSIT, address(this));

    //     // Deploy a new SuperVault with the ruggable vault
    //     _deployNewSuperVaultWithRuggableVault(address(vars.ruggableVault));

    //     // Setup deposit users and amounts
    //     vars.depositUsers = new address[](5);
    //     vars.depositAmounts = new uint256[](5);
    //     for (uint256 i = 0; i < 5; i++) {
    //         vars.depositUsers[i] = accInstances[i].account;
    //         vars.depositAmounts[i] = vars.depositAmount;
    //     }

    //     // Perform deposits
    //     for (uint256 i = 0; i < 5; i++) {
    //         _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
    //         vm.startPrank(vars.depositUsers[i]);
    //         asset.approve(address(vault), vars.depositAmounts[i]);
    //         vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
    //         vm.stopPrank();
    //     }

    //     // Simulate time passing
    //     vm.warp(vars.initialTimestamp + 1 days);

    //     uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
    //     expectedAssetsOrSharesOut[0] = 1; //99% slippage
    //     expectedAssetsOrSharesOut[1] = 1; // 99% slippage
    //     _depositFreeAssets(
    //         vars.depositAmount * 5 / 2,
    //         vars.depositAmount * 5 / 2,
    //         address(fluidVault),
    //         address(vars.ruggableVault),
    //         expectedAssetsOrSharesOut,
    //         bytes4(0)
    //     );
    // }

    function test_10_RuggableVault_Deposit() public {
        RugTestVarsDeposit memory vars;
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 5000; // 50% rug
        vars.initialTimestamp = block.timestamp;

        // Deploy a ruggable vault that rugs on deposit
        vars.ruggableVault = RuggableVault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(RuggableVault).creationCode,
                    abi.encode(IERC20(address(asset)), "Ruggable Vault", "RUG", true, false, vars.rugPercentage)
                )
            )
        );
        console2.log("ruggableVault", address(vars.ruggableVault));
        assertEq(
            address(vars.ruggableVault), test10_RuggableVault_Deposit, "TEST10_DEPOSIT VAULT NOT EQUAL TO PREDICTED"
        );

        // Add funds to the ruggable vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(vars.ruggableVault), type(uint256).max);
        vars.ruggableVault.deposit(2 * LARGE_DEPOSIT, address(this));

        // Deploy a new SuperVault with the ruggable vault
        _deployNewSuperVaultWithRuggableVault(address(vars.ruggableVault));

        // Setup deposit users and amounts
        vars.depositUsers = new address[](5);
        vars.depositAmounts = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            vars.depositUsers[i] = accInstances[i].account;
            vars.depositAmounts[i] = vars.depositAmount;
        }

        // Perform deposits
        for (uint256 i = 0; i < 5; i++) {
            _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
            vm.startPrank(vars.depositUsers[i]);
            asset.approve(address(vault), vars.depositAmounts[i]);
            vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
            vm.stopPrank();
        }

        // Simulate time passing
        vm.warp(vars.initialTimestamp + 1 days);

        uint256 sharesVault1 = IERC4626(address(fluidVault)).convertToShares(vars.depositAmount * 5 / 2);
        uint256 sharesVault2 = IERC4626(address(vars.ruggableVault)).convertToShares(vars.depositAmount * 5 / 2);

        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = sharesVault1 - (sharesVault1 * 1e2 / 1e5); // 1% slippage
        expectedAssetsOrSharesOut[1] = (sharesVault2 - sharesVault2 * vars.rugPercentage / 10_000) * 2; // Should revert

        // expect revert on this call and try again after
        _depositFreeAssets(
            (vars.depositAmount * 5) / 2,
            (vars.depositAmount * 5) / 2,
            address(fluidVault),
            address(vars.ruggableVault),
            expectedAssetsOrSharesOut,
            ISuperVaultStrategy.MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET.selector
        );
        expectedAssetsOrSharesOut[1] = sharesVault2 - sharesVault2 * vars.rugPercentage / 10_000; // 50% rug
        _depositFreeAssets(
            vars.depositAmount * 5 / 2,
            vars.depositAmount * 5 / 2,
            address(fluidVault),
            address(vars.ruggableVault),
            expectedAssetsOrSharesOut,
            bytes4(0)
        );
    }

    function test_10_RuggableVault_WithdrawX() public {
        RugTestVarsWithdraw memory vars;
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 5000; // 50% rug
        vars.initialTimestamp = block.timestamp;

        // Deploy a ruggable vault that rugs on withdraw
        RuggableVault ruggableVault = RuggableVault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(RuggableVault).creationCode,
                    abi.encode(IERC20(address(asset)), "Ruggable Vault", "RUG", false, true, vars.rugPercentage)
                )
            )
        );
        console2.log("ruggableVault", address(ruggableVault));
        assertEq(address(ruggableVault), test10_RuggableVault_Withdraw, "TEST10_WITHDRAW VAULT NOT EQUAL TO PREDICTED");

        vars.ruggableVault = address(ruggableVault);
        vars.convertVault = false;
        // Log the rug configuration
        console2.log("\n=== RuggableVault Configuration ===");
        console2.log("Rug on deposit:", ruggableVault.rugOnDeposit());
        console2.log("Rug on withdraw:", ruggableVault.rugOnWithdraw());
        console2.log("Rug percentage:", ruggableVault.rugPercentage());

        // Calculate how much would be rugged for a sample amount
        uint256 sampleAmount = 1000e6;
        uint256 ruggedAmount = ruggableVault.calculateRuggedAmount(sampleAmount);
        console2.log("For a sample amount of", sampleAmount, "the rugged amount would be", ruggedAmount);

        // Verify the rug calculation is correct
        assertEq(
            ruggedAmount,
            sampleAmount * vars.rugPercentage / 10_000,
            "Rugged amount calculation should match expected value"
        );

        _testRuggableVaultWithdraw(vars);
    }

    function test_10_RuggableVault_Withdraw_ConvertDistortion() public {
        RugTestVarsWithdraw memory vars;
        vars.depositAmount = 1000e6;
        vars.rugPercentage = 5000; // 50% rug
        vars.initialTimestamp = block.timestamp;

        // Deploy a ruggable vault that rugs via convert functions
        RuggableConvertVault ruggableConvertVault = RuggableConvertVault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(
                    type(RuggableConvertVault).creationCode,
                    abi.encode(IERC20(address(asset)), "Ruggable Convert Vault", "RUGC", vars.rugPercentage, true)
                )
            )
        );
        console2.log("ruggableConvertVault", address(ruggableConvertVault));
        assertEq(
            address(ruggableConvertVault),
            test10_RuggableVault_Withdraw_ConvertDistortion,
            "TEST10_CONVERT VAULT NOT EQUAL TO PREDICTED"
        );

        vars.ruggableVault = address(ruggableConvertVault);
        vars.convertVault = true;
        _testRuggableVaultWithdraw(vars);

        // Verify that the SuperVault's totalAssets was affected by the inflated reporting
        uint256 vaultTotalAssets = ruggableConvertVault.totalAssets();
        console2.log("Ruggable vault total assets:", vaultTotalAssets);

        // Disable the rug to see the true value
        ruggableConvertVault.setRugEnabled(false);
        uint256 vaultTotalAssetsWithoutRug = ruggableConvertVault.totalAssets();
        console2.log("Ruggable total assets (rug disabled):", vaultTotalAssetsWithoutRug);
        console2.log("Difference:", vaultTotalAssets - vaultTotalAssetsWithoutRug);

        // The difference should be significant if there are still assets in the ruggable vault
        assertGt(
            vaultTotalAssets, vaultTotalAssetsWithoutRug, "SuperVault total assets should be higher with rug enabled"
        );
    }

    function test_11_Allocate_NewYieldSource() public {
        ScenarioNewYieldSourceVars memory vars;
        vars.depositAmount = 1000e6;

        vars.initialFluidVaultPPS = fluidVault.convertToAssets(1e18);
        vars.initialAaveVaultPPS = aaveVault.convertToAssets(1e18);

        // do an initial allo
        _completeDepositFlow(vars.depositAmount);

        // add new vault as yield source
        Mock4626Vault newVault = Mock4626Vault(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(TEST_SALT)),
                abi.encodePacked(type(Mock4626Vault).creationCode, abi.encode(address(asset), "New Vault", "NV"))
            )
        );
        console2.log("newVault", address(newVault));
        assertEq(address(newVault), test11_Allocate_NewYieldSource, "TEST11 VAULT NOT EQUAL TO PREDICTED");

        //  -- add funds to the newVault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(address(newVault), type(uint256).max);
        newVault.deposit(2 * LARGE_DEPOSIT, address(this));

        vm.warp(block.timestamp + 20 days);

        _updateSuperVaultPPS(address(strategy), address(vault));

        // -- add it as a new yield source
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(newVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0);
        vm.stopPrank();

        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.initialAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.initialNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Initial FluidVault balance:", vars.initialFluidVaultBalance);
        console2.log("Initial AaveVault balance:", vars.initialAaveVaultBalance);
        console2.log("Initial NewVault balance:", vars.initialNewVaultBalance);

        // 30/30/40
        // allocate 20% from each vault to the new one
        vars.amountToReallocateFluidVault = vars.initialFluidVaultBalance * 20 / 100;
        vars.amountToReallocateAaveVault = vars.initialAaveVaultBalance * 20 / 100;
        vars.assetAmountToReallocateFromFluidVault = fluidVault.convertToAssets(vars.amountToReallocateFluidVault);
        vars.assetAmountToReallocateFromAaveVault = aaveVault.convertToAssets(vars.amountToReallocateAaveVault);
        vars.assetAmountToReallocateToNewVault =
            vars.assetAmountToReallocateFromFluidVault + vars.assetAmountToReallocateFromAaveVault;
        console2.log("Asset amount to reallocate from FluidVault:", vars.assetAmountToReallocateFromFluidVault);
        console2.log("Asset amount to reallocate from AaveVault:", vars.assetAmountToReallocateFromAaveVault);

        vm.warp(block.timestamp + 20 days);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // allocation
        address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
        address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

        address[] memory hooksAddresses = new address[](3);
        hooksAddresses[0] = withdrawHookAddress;
        hooksAddresses[1] = withdrawHookAddress;
        hooksAddresses[2] = depositHookAddress;

        bytes[] memory hooksData = new bytes[](3);
        // redeem from FluidVault
        hooksData[0] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(fluidVault),
            address(strategy),
            vars.amountToReallocateFluidVault,
            false
        );
        // redeem from AaveVault
        hooksData[1] = _createRedeem4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(aaveVault),
            address(strategy),
            vars.amountToReallocateAaveVault,
            false
        );
        // deposit to NewVault
        hooksData[2] = _createApproveAndDeposit4626HookData(
            _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
            address(newVault),
            address(asset),
            vars.assetAmountToReallocateToNewVault,
            false,
            address(0),
            0
        );
        bytes[] memory argsForProofs = new bytes[](3);
        argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
        argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);
        argsForProofs[2] = ISuperHookInspector(hooksAddresses[2]).inspect(hooksData[2]);

        vm.startPrank(MANAGER);
        strategy.executeHooks(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: hooksAddresses,
                hookCalldata: hooksData,
                expectedAssetsOrSharesOut: new uint256[](3),
                globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                strategyProofs: new bytes32[][](hooksAddresses.length)
            })
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 20 days);
        _updateSuperVaultPPS(address(strategy), address(vault));

        // check new balances
        vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.finalAaveVaultBalance = aaveVault.balanceOf(address(strategy));
        vars.finalNewVaultBalance = newVault.balanceOf(address(strategy));

        console2.log("Final FluidVault balance:", vars.finalFluidVaultBalance);
        console2.log("Final AaveVault balance:", vars.finalAaveVaultBalance);
        console2.log("Final NewVault balance:", vars.finalNewVaultBalance);

        assertApproxEqRel(
            vars.finalFluidVaultBalance,
            vars.initialFluidVaultBalance - vars.amountToReallocateFluidVault,
            0.01e18,
            "FluidVault balance should decrease by the reallocated amount"
        );

        assertApproxEqRel(
            vars.finalAaveVaultBalance,
            vars.initialAaveVaultBalance - vars.amountToReallocateAaveVault,
            0.01e18,
            "AaveVault balance should decrease by the reallocated amount"
        );

        assertGt(vars.finalNewVaultBalance, vars.initialNewVaultBalance, "NewVault balance should increase");

        vars.initialTotalValue = fluidVault.convertToAssets(vars.initialFluidVaultBalance)
            + aaveVault.convertToAssets(vars.initialAaveVaultBalance)
            + newVault.convertToAssets(vars.initialNewVaultBalance);

        vars.finalTotalValue = fluidVault.convertToAssets(vars.finalFluidVaultBalance)
            + aaveVault.convertToAssets(vars.finalAaveVaultBalance) + newVault.convertToAssets(vars.finalNewVaultBalance);
        assertApproxEqRel(
            vars.finalTotalValue, vars.initialTotalValue, 0.01e18, "Total value should be preserved during allocation"
        );

        // Enhanced checks for price per share and yield
        console2.log("\n=== Enhanced Vault Metrics ===");

        // Price per share comparison
        uint256 fluidVaultFinalPPS = fluidVault.convertToAssets(1e18);
        uint256 aaveVaultFinalPPS = aaveVault.convertToAssets(1e18);
        uint256 newVaultFinalPPS = newVault.convertToAssets(1e18);

        console2.log("\nPrice per Share Changes:");
        console2.log("Fluid Vault:");
        console2.log("  Initial PPS:", vars.initialFluidVaultPPS);
        console2.log("  Final PPS:", fluidVaultFinalPPS);
        console2.log(
            "  Change:",
            fluidVaultFinalPPS > vars.initialFluidVaultPPS ? "+" : "",
            fluidVaultFinalPPS - vars.initialFluidVaultPPS
        );
        console2.log(
            "  Change %:", ((fluidVaultFinalPPS - vars.initialFluidVaultPPS) * 10_000) / vars.initialFluidVaultPPS
        );

        console2.log("\nAave Vault:");
        console2.log("  Initial PPS:", vars.initialAaveVaultPPS);
        console2.log("  Final PPS:", aaveVaultFinalPPS);
        console2.log(
            "  Change:",
            aaveVaultFinalPPS > vars.initialAaveVaultPPS ? "+" : "",
            aaveVaultFinalPPS - vars.initialAaveVaultPPS
        );
        console2.log(
            "  Change %:", ((aaveVaultFinalPPS - vars.initialAaveVaultPPS) * 10_000) / vars.initialAaveVaultPPS
        );

        console2.log("\nYield Metrics:");
        uint256 totalYield =
            vars.finalTotalValue > vars.initialTotalValue ? vars.finalTotalValue - vars.initialTotalValue : 0;
        console2.log("Total Yield:", totalYield);
        console2.log("Yield %:", (totalYield * 10_000) / vars.initialTotalValue);

        assertGe(fluidVaultFinalPPS, vars.initialFluidVaultPPS, "Fluid Vault should not lose value");
        assertGe(aaveVaultFinalPPS, vars.initialAaveVaultPPS, "Aave Vault should not lose value");
        assertGe(newVaultFinalPPS, 1e18, "NewVault should not lose value");

        uint256 totalFinalBalance = vars.finalFluidVaultBalance + vars.finalAaveVaultBalance + vars.finalNewVaultBalance;

        uint256 fluidRatio = (vars.finalFluidVaultBalance * 100) / totalFinalBalance;
        uint256 aaveRatio = (vars.finalAaveVaultBalance * 100) / totalFinalBalance;
        uint256 newRatio = (vars.finalNewVaultBalance * 100) / totalFinalBalance;

        console2.log("\nFinal Allocation Ratios:");
        console2.log("Fluid Vault:", fluidRatio, "%");
        console2.log("Aave Vault:", aaveRatio, "%");
        console2.log("NewVault:", newRatio, "%");
    }

    function test_12_multiMillionDeposits() public {
        TestVars memory vars;
        vars.initialTimestamp = block.timestamp;

        // Set up deposit amounts for multiple rounds
        // We'll do 3 rounds of deposits to reach 10M+ USDC
        uint256 depositRounds = 3;
        uint256 targetTotalDeposits = 9_000_000e6; // 10M USDC
        uint256 depositPerRound = targetTotalDeposits / depositRounds;
        uint256 depositPerUser = depositPerRound / ACCOUNT_COUNT;

        console2.log("\n=== Starting multi-million deposit test ===");
        console2.log("Target total deposits:", targetTotalDeposits / 1e6, "M USDC");
        console2.log("Deposit rounds:", depositRounds);
        console2.log("Deposit per round:", depositPerRound / 1e6, "M USDC");
        console2.log("Deposit per user per round:", depositPerUser / 1e6, "M USDC");

        // Round 1: Initial deposits
        console2.log("\n=== Round 1 Deposits ===");
        vars.depositAmounts = new uint256[](ACCOUNT_COUNT);
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            vars.depositAmounts[i] = depositPerUser;
        }
        _completeDepositFlowWithVaryingAmounts(vars.depositAmounts);
        vars.totalDeposited += depositPerRound;
        console2.log("balance of vault", IERC20(address(asset)).balanceOf(address(strategy)));
        console2.log("total deposited", vars.totalDeposited);
        console2.log("Total Assets:", vault.totalAssets());

        // Wait 1 week
        vm.warp(vars.initialTimestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("\n=== After 1 week ===");
        console2.log("Total Assets:", vault.totalAssets());
        console2.log("Price per share:", aggregator.getPPS(address(strategy)));

        // Round 2: More deposits after 1 week
        console2.log("\n=== Round 2 Deposits ===");
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            _getTokens(address(asset), accInstances[i].account, depositPerUser);
            __deposit(accInstances[i], depositPerUser);
        }

        // Prepare for fulfillment
        address[] memory requestingUsers = new address[](ACCOUNT_COUNT);
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            requestingUsers[i] = accInstances[i].account;
        }

        // Fulfill deposits with 60/40 split between vaults
        console2.log("deposit per round", depositPerRound);

        uint256 allocationAmountVault1 = (depositPerRound * 6000) / 10_000; // 60% to fluid vault
        uint256 allocationAmountVault2 = depositPerRound - allocationAmountVault1; // 40% to aave vault
        console2.log("\n=== Round 2 Fulfill Requests ===");

        console2.log("allocation vault 1", allocationAmountVault1);
        console2.log("allocation vault 2", allocationAmountVault2);
        console2.log("balance of vault", IERC20(address(asset)).balanceOf(address(strategy)));
        // TVL fluid 1669215723572
        // tvl aave 1668059877911
        _depositFreeAssets(allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault));

        vars.totalDeposited += depositPerRound;

        // Wait 2 more weeks
        vm.warp(vars.initialTimestamp + 3 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("\n=== After 3 weeks ===");
        console2.log("Total Assets:", vault.totalAssets() / 1e6, "M USDC");
        console2.log("Price per share:", aggregator.getPPS(address(strategy)));

        // Round 3: Final deposits after 3 weeks
        console2.log("\n=== Round 3 Deposits ===");
        for (uint256 i = 0; i < ACCOUNT_COUNT; i++) {
            _getTokens(address(asset), accInstances[i].account, depositPerUser);
            __deposit(accInstances[i], depositPerUser);
        }

        // Wait 2 more weeks before fulfilling final deposits
        vm.warp(vars.initialTimestamp + 5 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("\n=== After 5 weeks (before final fulfillment) ===");
        console2.log("Total Assets:", vault.totalAssets() / 1e6, "M USDC");
        console2.log("Price per share:", aggregator.getPPS(address(strategy)));

        // Store state before final fulfillment
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);

        // Fulfill final deposits with 70/30 split
        allocationAmountVault1 = (depositPerRound * 70) / 100; // 70% to fluid vault
        allocationAmountVault2 = depositPerRound - allocationAmountVault1; // 30% to aave vault

        _depositFreeAssets(allocationAmountVault1, allocationAmountVault2, address(fluidVault), address(aaveVault));

        vars.totalDeposited += depositPerRound;

        // Final verification after all deposits
        console2.log("\n=== Final state after all deposits ===");
        vars.finalTotalAssets = vault.totalAssets();
        vars.finalTotalSupply = vault.totalSupply();
        vars.finalPricePerShare = vars.finalTotalAssets.mulDiv(1e18, vars.finalTotalSupply, Math.Rounding.Floor);

        console2.log("Total deposited:", vars.totalDeposited / 1e6, "M USDC");
        console2.log("Final total assets:", vars.finalTotalAssets / 1e6, "M USDC");
        console2.log("Final price per share:", vars.finalPricePerShare);

        // Check underlying vault balances
        vars.fluidVaultBalance = fluidVault.balanceOf(address(strategy));
        vars.aaveVaultBalance = aaveVault.balanceOf(address(strategy));

        uint256 fluidVaultAssets = fluidVault.convertToAssets(vars.fluidVaultBalance);
        uint256 aaveVaultAssets = aaveVault.convertToAssets(vars.aaveVaultBalance);

        console2.log("\n=== Underlying vault balances ===");
        console2.log("Fluid vault shares:", vars.fluidVaultBalance);
        console2.log("Fluid vault assets:", fluidVaultAssets / 1e6, "M USDC");
        console2.log("Aave vault shares:", vars.aaveVaultBalance);
        console2.log("Aave vault assets:", aaveVaultAssets / 1e6, "M USDC");
        console2.log("Total underlying assets:", (fluidVaultAssets + aaveVaultAssets) / 1e6, "M USDC");

        // Verify total assets matches the sum of underlying vault assets
        assertApproxEqRel(vars.finalTotalAssets, fluidVaultAssets + aaveVaultAssets, 0.01e18); // 1% tolerance

        // Verify price per share increased over time (yield accrual)
        assertGt(vars.finalPricePerShare, 1e18, "Price per share should be greater than 1e18 after yield accrual");

        // Verify total deposits reached target
        assertGe(
            vars.finalTotalAssets, targetTotalDeposits, "Total assets should be at least the target deposit amount"
        );
    }

    // function test_13_TransferOfShares() public   {
    //     _getTokens(address(asset), accInstances[0].account, 100e6);
    //     __deposit(accInstances[0], 100e6);

    //     uint256 shares = vault.balanceOf(accInstances[0].account);

    //     vm.prank(accInstances[0].account);
    //     IERC20(address(vault)).transfer(accInstances[1].account, shares);

    //     console2.log("share balance ofuser2", IERC20(address(vault)).balanceOf(accInstances[1].account));

    //     _depositFreeAssetsFromSingleAmount(100e6, address(fluidVault), address(aaveVault));

    //     _updateSuperVaultPPS(address(strategy), address(vault));

    //     _requestRedeemForAccount(accInstances[1], shares);

    //     address[] memory redeemUsers = new address[](1);
    //     redeemUsers[0] = accInstances[1].account;

    //     _fulfillRedeemForUsers(redeemUsers, shares / 2, shares / 2, address(fluidVault), address(aaveVault));

    //     // console2.log("asset balance ofuser2", IERC20(address(asset)).balanceOf(accInstances[1].account));

    //     // _claimRedeemForUsers(redeemUsers);

    //     // console2.log("asset balance ofuser2", IERC20(address(asset)).balanceOf(accInstances[1].account));
    // }

    function _verifyInitialBalances(uint256[] memory depositAmounts) internal view {
        console2.log("\n=== Initial State ===");
        uint256 totalAssets = vault.totalAssets();
        uint256 totalSupply = vault.totalSupply();
        uint256 pricePerShare = totalAssets.mulDiv(1e18, totalSupply, Math.Rounding.Floor);

        console2.log("Total Assets:", totalAssets);
        console2.log("Total Supply:", totalSupply);
        console2.log("Price per share:", pricePerShare);

        // Verify vault invariants
        assertGt(totalSupply, 0, "Total supply should be positive");
        assertGt(totalAssets, 0, "Total assets should be positive");

        // Verify underlying balances
        uint256 totalUnderlyingInVaults =
            fluidVault.balanceOf(address(strategy)) + aaveVault.balanceOf(address(strategy));
        assertGt(totalUnderlyingInVaults, 0, "Should have balance in underlying vaults");

        // Verify total deposits match total assets (accounting for bootstrap amount)
        uint256 expectedTotalDeposits;
        for (uint256 i; i < depositAmounts.length; i++) {
            expectedTotalDeposits += depositAmounts[i];
        }
        assertApproxEqRel(totalAssets, expectedTotalDeposits, 0.01e18, "Total assets should match deposits");

        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            uint256 shares = vault.balanceOf(accInstances[i].account);
            uint256 assets = vault.convertToAssets(shares);
            assertApproxEqRel(assets, depositAmounts[i], 0.01e18);
            console2.log("\nUser", i);
            console2.log("deposited:", depositAmounts[i]);
            console2.log("got shares:", shares);
            console2.log("got assets:", assets);

            // Verify share-asset conversion consistency
            uint256 sharesFromAssets = vault.convertToShares(assets);
            assertApproxEqRel(sharesFromAssets, shares, 0.01e18, "Share-asset conversion should be consistent");
        }
    }

    function _selectRandomUsersForRedemption(MultipleOperationsVars memory vars)
        internal
        view
        returns (MultipleOperationsVars memory)
    {
        uint256 i;
        while (vars.selectedCount < 15) {
            uint256 randIndex = uint256(keccak256(abi.encodePacked(vars.seed, "redeem", i))) % ACCOUNT_COUNT;

            if (!vars.selected[randIndex]) {
                vars.redeemUsers[vars.selectedCount] = accInstances[randIndex].account;
                // Redeem 25-75% of their balance
                uint256 randPercent = 2500 + (uint256(keccak256(abi.encodePacked(vars.seed, "percent", i))) % 5100);
                uint256 shares = vault.balanceOf(accInstances[randIndex].account);

                vars.redeemAmounts[vars.selectedCount] = (shares * randPercent) / 10_000;
                vars.selected[randIndex] = true;
                vars.selectedCount++;
            }
            i++;
        }
        return vars;
    }

    function _processRedemptionRequests(MultipleOperationsVars memory vars) internal {
        for (uint256 i; i < vars.selectedCount; i++) {
            vm.startPrank(vars.redeemUsers[i]);
            vault.requestRedeem(vars.redeemAmounts[i], vars.redeemUsers[i], vars.redeemUsers[i]);
            vm.stopPrank();
        }
    }

    function _claimRedeemForUsers(address[] memory redeemUsers) internal {
        for (uint256 i; i < redeemUsers.length; i++) {
            address user = redeemUsers[i];
            uint256 maxWithdrawAmount = vault.maxWithdraw(user);
            if (maxWithdrawAmount > 0) {
                vm.startPrank(user);
                console2.log("withdrawing", maxWithdrawAmount, "for user", user);
                vault.withdraw(maxWithdrawAmount, user, user);
                vm.stopPrank();
            }
        }
    }

    function _verifyFinalBalances(MultipleOperationsVars memory vars) internal view {
        FinalBalanceVerificationVars memory v;

        // Calculate global vault state
        v.finalTotalAssets = vault.totalAssets();
        v.finalTotalSupply = vault.totalSupply();
        //v.finalPricePerShare = v.finalTotalAssets.mulDiv(1e18, v.finalTotalSupply, Math.Rounding.Floor);
        v.finalPricePerShare = strategy.getStoredPPS();
        v.totalValueLocked = v.finalTotalAssets;

        // Get escrow balance
        v.escrowBalance = vault.balanceOf(address(escrow));

        // Log final state
        console2.log("\n=== Final State ===");
        console2.log("Final Total Assets:", v.finalTotalAssets);
        console2.log("Final Total Supply:", v.finalTotalSupply);
        console2.log("Final Price per share:", v.finalPricePerShare);
        console2.log("Total Value Locked:", v.totalValueLocked);
        console2.log("Escrow Balance:", v.escrowBalance);

        // Verify escrow state
        assertEq(v.escrowBalance, 0, "Escrow should have no shares after all claims are processed");

        // Calculate yield metrics
        v.totalYieldAccrued =
            v.finalTotalAssets > vars.initialTotalAssets ? v.finalTotalAssets - vars.initialTotalAssets : 0;
        v.yieldPerShare = v.totalYieldAccrued.mulDiv(1e18, v.finalTotalSupply, Math.Rounding.Floor);

        console2.log("\n=== Yield Metrics ===");
        console2.log("Total Yield Accrued:", v.totalYieldAccrued);
        console2.log("Yield Per Share:", v.yieldPerShare);

        // Verify yield accrual
        assertGe(
            v.finalPricePerShare,
            vars.initialPricePerShare,
            "Price per share should not decrease over time due to yield"
        );
        assertGt(v.totalValueLocked, 0, "TVL should be positive");

        // Verify strategy state
        v.fluidBalance = fluidVault.balanceOf(address(strategy));
        v.aaveBalance = aaveVault.balanceOf(address(strategy));

        console2.log("\n=== Strategy State ===");
        console2.log("Fluid Vault Balance:", v.fluidBalance);
        console2.log("Aave Vault Balance:", v.aaveBalance);

        // Strategy invariant checks
        assertGt(v.fluidBalance, 0, "Should maintain minimum fluid vault allocation");
        assertGt(v.aaveBalance, 0, "Should maintain minimum aave vault allocation");

        // Verify user states and accumulate totals
        for (uint256 i; i < ACCOUNT_COUNT; i++) {
            v.currentShares = vault.balanceOf(accInstances[i].account);
            v.currentAssets = vault.convertToAssets(v.currentShares);
            v.totalUserShares += v.currentShares;
            v.totalUserAssets += v.currentAssets;

            // Check if user is a redeemer
            v.isRedeemer = false;
            v.redeemedShares = 0;
            for (uint256 j; j < 15; j++) {
                if (accInstances[i].account == vars.redeemUsers[j]) {
                    v.isRedeemer = true;
                    v.redeemedShares = vars.redeemAmounts[j];
                    break;
                }
            }

            // Calculate user's yield
            v.userYieldAccrued = v.currentAssets > vars.depositAmounts[i] ? v.currentAssets - vars.depositAmounts[i] : 0;

            console2.log(string.concat("\n=== User ", Strings.toString(i), " State ==="));
            console2.log("Current Shares:", v.currentShares);
            console2.log("Current Assets:", v.currentAssets);
            console2.log("Yield Accrued:", v.userYieldAccrued);

            if (v.isRedeemer) {
                v.expectedShares = vault.convertToShares(vars.depositAmounts[i]) - v.redeemedShares;
                assertApproxEqRel(v.currentShares, v.expectedShares, 0.01e18, "Redeemer shares mismatch");

                // Verify redeemer's remaining position if they still have shares
                if (v.currentShares > 0) {
                    assertGt(
                        v.currentAssets.mulDiv(v.finalTotalSupply, v.currentShares, Math.Rounding.Floor),
                        vars.depositAmounts[i],
                        "Redeemer's remaining position should be worth more due to yield"
                    );
                }
            } else {
                v.expectedAssets = vars.depositAmounts[i];
                assertApproxEqRel(v.currentAssets, v.expectedAssets, 0.01e18, "Non-redeemer assets mismatch");
                assertGt(v.currentAssets, vars.depositAmounts[i], "Non-redeemer should have more assets due to yield");
            }

            // Verify no pending operations
            v.totalPendingRedeems += strategy.pendingRedeemRequest(accInstances[i].account);
            assertEq(strategy.pendingRedeemRequest(accInstances[i].account), 0, "Should have no pending redemptions");
        }

        // Final global state verification
        console2.log("\n=== Final Verification ===");
        console2.log("Total User Shares:", v.totalUserShares);
        console2.log("Total User Assets:", v.totalUserAssets);
        console2.log("Total Pending Deposits:", v.totalPendingDeposits);
        console2.log("Total Pending Redeems:", v.totalPendingRedeems);

        assertApproxEqRel(v.totalUserShares, v.finalTotalSupply, 0.01e18, "Total shares should match supply");
        assertApproxEqRel(v.totalUserAssets, v.finalTotalAssets, 0.01e18, "Total assets should match TVL");
        assertEq(v.totalPendingDeposits, 0, "Should have no pending deposits globally");
        assertEq(v.totalPendingRedeems, 0, "Should have no pending redeems globally");
    }

    function _testRuggableVaultWithdraw(RugTestVarsWithdraw memory vars) internal {
        // Add funds to the ruggable vault to respect LARGE_DEPOSIT
        _getTokens(address(asset), address(this), 2 * LARGE_DEPOSIT);
        asset.approve(vars.ruggableVault, type(uint256).max);
        IERC4626(vars.ruggableVault).deposit(2 * LARGE_DEPOSIT, address(this));

        // Deploy a new SuperVault with the ruggable vault
        _deployNewSuperVaultWithRuggableVault(vars.ruggableVault);

        // Setup deposit users and amounts
        vars.depositUsers = new address[](5);
        vars.depositAmounts = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            vars.depositUsers[i] = accInstances[i].account;
            vars.depositAmounts[i] = vars.depositAmount;
        }

        // Perform deposits
        for (uint256 i = 0; i < 5; i++) {
            _getTokens(address(asset), vars.depositUsers[i], vars.depositAmounts[i]);
            vm.startPrank(vars.depositUsers[i]);
            asset.approve(address(vault), vars.depositAmounts[i]);
            vault.deposit(vars.depositAmounts[i], vars.depositUsers[i]);
            vm.stopPrank();
        }

        // Fulfill deposit requests
        uint256[] memory expectedAssetsOrSharesOut = new uint256[](2);
        expectedAssetsOrSharesOut[0] = IERC4626(address(fluidVault)).convertToShares(vars.depositAmount * 5 / 2);
        expectedAssetsOrSharesOut[1] = IERC4626(address(vars.ruggableVault)).convertToShares(vars.depositAmount * 5 / 2);
        _depositFreeAssets(
            vars.depositAmount * 5 / 2, vars.depositAmount * 5 / 2, address(fluidVault), vars.ruggableVault
        );
        console2.log("\n=== TIME WARPING ===");
        vars.ppsBeforeWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS BEFORE WARP", vars.ppsBeforeWarp);

        vm.warp(block.timestamp + 10 weeks);

        _updateSuperVaultPPS(address(strategy), address(vault));
        vars.ppsAfterWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS AFTER WARP", vars.ppsAfterWarp);

        // Store initial state
        vars.initialTotalAssets = vault.totalAssets();
        vars.initialTotalSupply = vault.totalSupply();
        vars.initialPricePerShare = vars.initialTotalAssets.mulDiv(1e18, vars.initialTotalSupply, Math.Rounding.Floor);

        // Log initial state
        console2.log("\n=== Initial State Before Redemption ===");
        console2.log("Initial Total Assets:", vars.initialTotalAssets);
        console2.log("Initial Total Supply:", vars.initialTotalSupply);
        console2.log("Initial Price per share:", vars.initialPricePerShare);
        console2.log("Ruggable Vault Balance:", IERC4626(vars.ruggableVault).balanceOf(address(strategy)));
        console2.log("Fluid Vault Balance:", fluidVault.balanceOf(address(strategy)));

        // Verify the initial state
        assertGt(vars.initialTotalAssets, 0, "Initial total assets should be positive");
        assertGt(vars.initialTotalSupply, 0, "Initial total supply should be positive");

        // Setup redeem users and amounts
        vars.redeemUsers = new address[](3);
        vars.redeemAmounts = new uint256[](3);
        vars.totalRedeemShares = 0;

        for (uint256 i = 0; i < 3; i++) {
            vars.redeemUsers[i] = vars.depositUsers[i];
            uint256 userShares = vault.balanceOf(vars.redeemUsers[i]);
            vars.redeemAmounts[i] = userShares; // Redeem all of their shares
            vars.totalRedeemShares += vars.redeemAmounts[i];
        }

        // Request redemptions
        for (uint256 i = 0; i < 3; i++) {
            vm.startPrank(vars.redeemUsers[i]);
            vault.requestRedeem(vars.redeemAmounts[i], vars.redeemUsers[i], vars.redeemUsers[i]);
            vm.stopPrank();
        }

        // Simulate time passing
        console2.log("\n=== TIME WARPING ===");
        vars.ppsBeforeWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS BEFORE WARP", vars.ppsBeforeWarp);

        vm.warp(block.timestamp + 12 weeks);

        _updateSuperVaultPPS(address(strategy), address(vault));
        vars.ppsAfterWarp = aggregator.getPPS(address(strategy));
        console2.log("PPS AFTER WARP", vars.ppsAfterWarp);

        // Fulfill redemption requests
        vars.redeemSharesVault1 = vars.totalRedeemShares / 2;
        vars.redeemSharesVault2 = vars.totalRedeemShares - vars.redeemSharesVault1;

        vars.assetsVault1 = IERC4626(address(fluidVault)).convertToAssets(vars.redeemSharesVault1);
        vars.assetsVault2 = IERC4626(address(vars.ruggableVault)).convertToAssets(vars.redeemSharesVault2);

        vars.expectedAssetsOrSharesOut = new uint256[](2);
        vars.expectedAssetsOrSharesOut[0] = vars.assetsVault1;
        vars.expectedAssetsOrSharesOut[1] = !vars.convertVault ? 1 : vars.assetsVault2; // this should make the call
            // revert

        // this should revert
        _fulfillRedeemForUsers(
            vars.redeemUsers,
            vars.redeemSharesVault1,
            vars.redeemSharesVault2,
            address(fluidVault),
            vars.ruggableVault,
            vars.expectedAssetsOrSharesOut,
            ISuperVaultStrategy.MINIMUM_OUTPUT_AMOUNT_ASSETS_NOT_MET.selector
        );

        vars.expectedAssetsOrSharesOut[0] = vars.assetsVault1 / 2;
        vars.expectedAssetsOrSharesOut[1] = vars.assetsVault2 / 2;
        _fulfillRedeemForUsers(
            vars.redeemUsers,
            vars.redeemSharesVault1,
            vars.redeemSharesVault2,
            address(fluidVault),
            vars.ruggableVault,
            vars.expectedAssetsOrSharesOut,
            bytes4(0)
        );

        // Log post-fulfillment state
        console2.log("\n=== Post-Fulfillment State ===");
        vars.totalAssetsPreClaimTaintedAssets = vault.totalAssets();
        vars.totalSupplyPreClaimTaintedAssets = vault.totalSupply();
        console2.log("Total Assets:", vars.totalAssetsPreClaimTaintedAssets);
        console2.log("Total Supply:", vars.totalSupplyPreClaimTaintedAssets);
        vars.pricePerSharePreClaimTaintedAssets = vars.totalAssetsPreClaimTaintedAssets.mulDiv(
            1e18, vars.totalSupplyPreClaimTaintedAssets, Math.Rounding.Floor
        );
        console2.log("Price per share:", vars.pricePerSharePreClaimTaintedAssets);
        console2.log("Ruggable Vault Balance:", IERC4626(vars.ruggableVault).balanceOf(address(strategy)));
        console2.log("Fluid Vault Balance:", fluidVault.balanceOf(address(strategy)));

        // Process claims for redeemed users, this will burn all tainted shares
        //_claimRedeemForUsers(vars.redeemUsers);

        // Verify global state
        vars.finalTotalAssets = vault.totalAssets();
        vars.finalTotalSupply = vault.totalSupply();
        uint256 finalPricePerShare = vars.finalTotalAssets.mulDiv(1e18, vars.finalTotalSupply, Math.Rounding.Floor);

        console2.log("\n=== Final State ===");
        console2.log("Final Total Assets:", vars.finalTotalAssets);
        console2.log("Final Total Supply:", vars.finalTotalSupply);
        console2.log("Final Price per share:", finalPricePerShare);

        // CONTINUATION: Allocate from rugged vault back to fluid vault
        console2.log("\n=== Allocating from Rugged Vault back to Fluid Vault ===");

        // Get initial balances
        vars.initialRuggableVaultBalance = IERC4626(vars.ruggableVault).balanceOf(address(strategy));
        vars.initialFluidVaultBalance = fluidVault.balanceOf(address(strategy));

        console2.log("Initial Ruggable Vault balance:", vars.initialRuggableVaultBalance);
        console2.log("Initial Fluid Vault balance:", vars.initialFluidVaultBalance);

        // Calculate asset amounts
        vars.initialRuggableVaultAssets = IERC4626(vars.ruggableVault).convertToAssets(vars.initialRuggableVaultBalance);
        vars.initialFluidVaultAssets = fluidVault.convertToAssets(vars.initialFluidVaultBalance);

        console2.log("Initial Ruggable Vault assets:", vars.initialRuggableVaultAssets);
        console2.log("Initial Fluid Vault assets:", vars.initialFluidVaultAssets);

        vars.amountToReallocate = vars.initialRuggableVaultBalance;
        vars.assetAmountToReallocate =
            IERC4626(vars.ruggableVault).convertToAssets(vars.amountToReallocate) * 5000 / 10_000;

        console2.log("Shares to reallocate from Ruggable Vault:", vars.amountToReallocate);
        console2.log("Asset amount to reallocate:", vars.assetAmountToReallocate);

        // Skip reallocation if there are no shares to reallocate
        if (vars.amountToReallocate > 0) {
            // Prepare allocation hooks
            address withdrawHookAddress = _getHookAddress(ETH, REDEEM_4626_VAULT_HOOK_KEY);
            address depositHookAddress = _getHookAddress(ETH, APPROVE_AND_DEPOSIT_4626_VAULT_HOOK_KEY);

            address[] memory hooksAddresses = new address[](2);
            hooksAddresses[0] = withdrawHookAddress;
            hooksAddresses[1] = depositHookAddress;

            bytes[] memory hooksData = new bytes[](2);

            // Redeem from Ruggable Vault
            hooksData[0] = _createRedeem4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                vars.ruggableVault,
                address(strategy),
                vars.amountToReallocate,
                false
            );

            // Deposit to Fluid Vault
            hooksData[1] = _createApproveAndDeposit4626HookData(
                _getYieldSourceOracleId(bytes32(bytes(ERC4626_YIELD_SOURCE_ORACLE_KEY)), address(this)),
                address(fluidVault),
                address(asset),
                vars.assetAmountToReallocate,
                false,
                address(0),
                0
            );
            bytes[] memory argsForProofs = new bytes[](2);
            argsForProofs[0] = ISuperHookInspector(hooksAddresses[0]).inspect(hooksData[0]);
            argsForProofs[1] = ISuperHookInspector(hooksAddresses[1]).inspect(hooksData[1]);

            // Execute allocation
            vm.startPrank(MANAGER);
            strategy.executeHooks(
                ISuperVaultStrategy.ExecuteArgs({
                    hooks: hooksAddresses,
                    hookCalldata: hooksData,
                    expectedAssetsOrSharesOut: new uint256[](2),
                    globalProofs: _getMerkleProofsForHooks(hooksAddresses, argsForProofs),
                    strategyProofs: new bytes32[][](hooksAddresses.length)
                })
            );
            vm.stopPrank();

            // Check final balances
            vars.finalRuggableVaultBalance = IERC4626(vars.ruggableVault).balanceOf(address(strategy));
            vars.finalFluidVaultBalance = fluidVault.balanceOf(address(strategy));

            console2.log("Final Ruggable Vault balance:", vars.finalRuggableVaultBalance);
            console2.log("Final Fluid Vault balance:", vars.finalFluidVaultBalance);

            // Calculate asset amounts after reallocation
            vars.finalRuggableVaultAssets = IERC4626(vars.ruggableVault).convertToAssets(vars.finalRuggableVaultBalance);
            vars.finalFluidVaultAssets = fluidVault.convertToAssets(vars.finalFluidVaultBalance);

            console2.log("Final Ruggable Vault assets:", vars.finalRuggableVaultAssets);
            console2.log("Final Fluid Vault assets:", vars.finalFluidVaultAssets);

            // Verify reallocation
            assertApproxEqRel(
                vars.finalRuggableVaultBalance,
                vars.initialRuggableVaultBalance - vars.amountToReallocate,
                0.01e18,
                "Ruggable Vault balance should decrease by the reallocated amount"
            );

            assertGt(vars.finalFluidVaultBalance, vars.initialFluidVaultBalance, "Fluid Vault balance should increase");

            // Check total value preservation
            vars.initialTotalValue = vars.initialRuggableVaultAssets + vars.initialFluidVaultAssets;
            vars.finalTotalValue = vars.finalRuggableVaultAssets + vars.finalFluidVaultAssets;

            console2.log("Initial total value:", vars.initialTotalValue);
            console2.log("Final total value:", vars.finalTotalValue);

            // Check final vault state
            vars.vaultTotalAssetsAfterAllocation = vault.totalAssets();
            vars.pricePerShareAfterAllocation =
                vars.vaultTotalAssetsAfterAllocation.mulDiv(1e18, vars.finalTotalSupply, Math.Rounding.Floor);

            console2.log("Vault total assets after allocation:", vars.vaultTotalAssetsAfterAllocation);
            console2.log("Price per share after allocation:", vars.pricePerShareAfterAllocation);
        } else {
            console2.log("Skipping reallocation as there are no shares to reallocate");
        }
    }

    function _deployNewSuperVaultWithRuggableVault(address ruggableVault) internal {
        // Deploy a new SuperVault with the ruggable vault
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_RUG");

        vault = SuperVault(vaultAddr);
        strategy = SuperVaultStrategy(payable(strategyAddr));
        escrow = SuperVaultEscrow(escrowAddr);

        // Replace aaveVault with ruggableVault in the strategy
        vm.startPrank(MANAGER);
        strategy.manageYieldSource(address(fluidVault), _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0); // Add

        strategy.manageYieldSource(ruggableVault, _getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY), 0); // Add
            // ruggableVault
        vm.stopPrank();
    }

    /// @notice Test that maxDeposit returns 0 when vault is paused
    function test_MaxDeposit_WhenPaused() public {
        // Arrange: Deploy a fresh vault
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_PAUSE_TEST");

        SuperVault testVault = SuperVault(vaultAddr);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddr));

        // Verify maxDeposit returns max value when not paused
        uint256 maxDepositBeforePause = testVault.maxDeposit(accountEth);
        assertEq(maxDepositBeforePause, type(uint256).max, "maxDeposit should return type(uint256).max when not paused");

        // Arrange: Set a strict deviation threshold to trigger pause (5% = 0.05 * 1e18)
        vm.prank(MANAGER);
        aggregator.updatePPSVerificationThresholds(
            address(testStrategy),
            type(uint256).max, // dispersionThreshold (disabled)
            0.05e18, // deviationThreshold (5%)
            type(uint256).max // mnThreshold (disabled)
        );

        // Get the current PPS to calculate a deviation that will trigger pause
        uint256 currentPPS = aggregator.getPPS(address(testStrategy));
        console2.log("Current PPS:", currentPPS);

        // Calculate a new PPS that deviates by more than 5% (let's use 10% increase)
        uint256 deviatingPPS = currentPPS + (currentPPS * 10 / 100); // 10% increase
        console2.log("Deviating PPS (10% increase):", deviatingPPS);

        // Act: Skip time to avoid UPDATE_TOO_FREQUENT error and create a PPS update that violates the deviation
        // threshold
        vm.warp(block.timestamp + 10); // Skip 10 seconds to avoid rate limiting
        _createPPSUpdateThatTriggersDeviation(address(testStrategy), deviatingPPS);

        // Assert: Verify the strategy is now paused
        bool isStrategyPaused = aggregator.isStrategyPaused(address(testStrategy));
        assertTrue(isStrategyPaused, "Strategy should be paused after PPS deviation");

        // Assert: Verify maxDeposit returns 0 when paused
        uint256 maxDepositAfterPause = testVault.maxDeposit(accountEth);
        assertEq(maxDepositAfterPause, 0, "maxDeposit should return 0 when paused");
    }

    /// @notice Test that maxMint returns 0 when vault is paused
    function test_MaxMint_WhenPaused() public {
        // Arrange: Deploy a fresh vault
        address vaultAddr;
        address strategyAddr;
        address escrowAddr;
        (vaultAddr, strategyAddr, escrowAddr) = _deployVault("SV_USDC_MINT_PAUSE_TEST");

        SuperVault testVault = SuperVault(vaultAddr);
        SuperVaultStrategy testStrategy = SuperVaultStrategy(payable(strategyAddr));

        // Verify maxMint returns max value when not paused
        uint256 maxMintBeforePause = testVault.maxMint(accountEth);
        assertEq(maxMintBeforePause, type(uint256).max, "maxMint should return type(uint256).max when not paused");

        // Arrange: Set a strict deviation threshold to trigger pause (5% = 0.05 * 1e18)
        vm.prank(MANAGER);
        aggregator.updatePPSVerificationThresholds(
            address(testStrategy),
            type(uint256).max, // dispersionThreshold (disabled)
            0.05e18, // deviationThreshold (5%)
            type(uint256).max // mnThreshold (disabled)
        );

        // Get the current PPS to calculate a deviation that will trigger pause
        uint256 currentPPS = aggregator.getPPS(address(testStrategy));
        console2.log("Current PPS:", currentPPS);

        // Calculate a new PPS that deviates by more than 5% (let's use 10% decrease)
        uint256 deviatingPPS = currentPPS - (currentPPS * 10 / 100); // 10% decrease
        console2.log("Deviating PPS (10% decrease):", deviatingPPS);

        // Act: Skip time to avoid UPDATE_TOO_FREQUENT error and create a PPS update that violates the deviation
        // threshold
        vm.warp(block.timestamp + 10); // Skip 10 seconds to avoid rate limiting
        _createPPSUpdateThatTriggersDeviation(address(testStrategy), deviatingPPS);

        // Assert: Verify the strategy is now paused
        bool isStrategyPaused = aggregator.isStrategyPaused(address(testStrategy));
        assertTrue(isStrategyPaused, "Strategy should be paused after PPS deviation");

        // Assert: Verify maxMint returns 0 when paused
        uint256 maxMintAfterPause = testVault.maxMint(accountEth);
        assertEq(maxMintAfterPause, 0, "maxMint should return 0 when paused");
    }

    /// @notice Helper function to create a PPS update that triggers deviation pause
    /// @param strategyAddr The strategy address to update
    /// @param newPPS The new PPS value that should trigger a deviation
    function _createPPSUpdateThatTriggersDeviation(address strategyAddr, uint256 newPPS) internal {
        UpdatePPSVars memory vars;

        // Get the current timestamp for the signature
        vars.timestamp = block.timestamp; // // Use current timestamp to avoid TIMESTAMP_EXCEEDS_BLOCK revert

        // Set the additional parameters: ppsStdev=0, validatorSet=1, totalValidators=1
        vars.ppsStdev = 0;
        vars.validatorSet = 1;
        vars.totalValidators = 1;

        // Create the message hash with the deviating PPS
        bytes32 structHash = keccak256(
            abi.encodePacked(
                ecdsappsOracle.UPDATE_PPS_TYPEHASH(),
                strategyAddr,
                newPPS,
                vars.ppsStdev,
                vars.validatorSet,
                vars.totalValidators,
                vars.timestamp,
                ecdsappsOracle.noncePerStrategy(strategyAddr)
            )
        );
        vars.ethSignedMessageHash = MessageHashUtils.toTypedDataHash(ecdsappsOracle.domainSeparator(), structHash);

        // Create signature (r, s, v) components using the constant KEEPER address
        (vars.v, vars.r, vars.s) = vm.sign(VALIDATOR_KEY, vars.ethSignedMessageHash);

        // Combine the signature components into a single bytes signature
        vars.signature = abi.encodePacked(vars.r, vars.s, vars.v);

        // Create an array of proofs with the signature
        vars.proofs = new bytes[](1);
        vars.proofs[0] = vars.signature;

        // Call batchUpdatePPS on the ECDSAPPSOracle with the deviating PPS
        address[] memory strategies = new address[](1);
        strategies[0] = strategyAddr;

        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = vars.proofs;

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = newPPS;

        uint256[] memory ppsStdevs = new uint256[](1);
        ppsStdevs[0] = vars.ppsStdev;

        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = vars.validatorSet;

        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = vars.totalValidators;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = vars.timestamp;

        ecdsappsOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps
            })
        );
    }

    /// @notice Helper function to set vault PPS to 0 for testing zero PPS scenarios
    /// @dev Exactly matches _updateSuperVaultPPS but forces PPS to 0
    /// @param strategyAddr The strategy address
    function _updateSuperVaultPPS_ToZero(address strategyAddr) internal {
        UpdatePPSVars memory vars;

        // Force PPS to 0 for testing
        vars.pps = 0;

        // Get the current timestamp for the signature
        vars.timestamp = block.timestamp;

        // Set the additional parameters as in _updateSuperVaultPPS
        vars.ppsStdev = 0;
        vars.validatorSet = 1;
        vars.totalValidators = 1;

        // Create the message hash with all parameters (exactly as in _updateSuperVaultPPS)
        bytes32 structHash = keccak256(
            abi.encodePacked(
                ecdsappsOracle.UPDATE_PPS_TYPEHASH(),
                strategyAddr,
                vars.pps,
                vars.ppsStdev,
                vars.validatorSet,
                vars.totalValidators,
                vars.timestamp,
                ecdsappsOracle.noncePerStrategy(strategyAddr)
            )
        );
        vars.ethSignedMessageHash = MessageHashUtils.toTypedDataHash(ecdsappsOracle.domainSeparator(), structHash);

        // Create signature (r, s, v) components using VALIDATOR_KEY (exactly as in _updateSuperVaultPPS)
        (vars.v, vars.r, vars.s) = vm.sign(VALIDATOR_KEY, vars.ethSignedMessageHash);

        // Combine the signature components into a single bytes signature
        vars.signature = abi.encodePacked(vars.r, vars.s, vars.v);

        // Create an array of proofs with the signature
        vars.proofs = new bytes[](1);
        vars.proofs[0] = vars.signature;

        // Call batchUpdatePPS on the ECDSAPPSOracle (exactly as in _updateSuperVaultPPS)
        address[] memory strategies = new address[](1);
        strategies[0] = strategyAddr;

        bytes[][] memory proofsArray = new bytes[][](1);
        proofsArray[0] = vars.proofs;

        uint256[] memory ppss = new uint256[](1);
        ppss[0] = vars.pps;

        uint256[] memory ppsStdevs = new uint256[](1);
        ppsStdevs[0] = vars.ppsStdev;

        uint256[] memory validatorSets = new uint256[](1);
        validatorSets[0] = vars.validatorSet;

        uint256[] memory totalValidators = new uint256[](1);
        totalValidators[0] = vars.totalValidators;

        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = vars.timestamp;

        ecdsappsOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies,
                proofsArray: proofsArray,
                ppss: ppss,
                ppsStdevs: ppsStdevs,
                validatorSets: validatorSets,
                totalValidators: totalValidators,
                timestamps: timestamps
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                        DUST BUG TESTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Test that exposes the dust bug in _handleClaimRedeem function
    /// @dev This test creates a scenario where the strategy balance is reduced below what users can claim,
    ///      but the difference is within the tolerance constant, causing the dust collection logic to trigger
    function test_DustBugInClaimRedeem() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Step 1: Deposit and set up redeem request
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialShares = vault.balanceOf(accountEth);
        uint256 redeemShares = initialShares / 2;

        // Request redeem
        _requestRedeem(redeemShares);

        // Fulfill the redeem request
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        // Get the claimable amount
        uint256 claimableAmount = strategy.claimableWithdraw(accountEth);
        console2.log("Claimable amount:", claimableAmount);

        // Step 2: Reduce strategy balance artificially (simulating insolvency)
        // This could happen due to various reasons like:
        // - Yield source losses
        // - Accounting errors

        uint256 strategyBalanceBefore = asset.balanceOf(address(strategy));
        console2.log("Strategy balance before reduction:", strategyBalanceBefore);

        // Simulate reducing strategy balance by transferring assets out
        // We'll make the difference exactly equal to TOLERANCE_CONSTANT (10 wei)
        // to trigger the dust collection logic
        uint256 reductionAmount = claimableAmount - strategyBalanceBefore + 5; // 5 wei less than tolerance

        // Transfer assets out of strategy to simulate insolvency
        vm.startPrank(address(strategy));
        asset.transfer(address(this), reductionAmount);
        vm.stopPrank();

        uint256 strategyBalanceAfter = asset.balanceOf(address(strategy));
        console2.log("Strategy balance after reduction:", strategyBalanceAfter);
        console2.log("Claimable amount:", claimableAmount);
        console2.log("Difference:", claimableAmount - strategyBalanceAfter);

        // Verify the difference is within tolerance constant
        assertTrue(claimableAmount > strategyBalanceAfter, "Claimable should be greater than available");
        assertTrue(claimableAmount - strategyBalanceAfter <= 10, "Difference should be within tolerance");

        // Step 3: Try to claim the full amount
        // This should trigger the dust collection logic and give the user the remaining balance
        uint256 userBalanceBefore = asset.balanceOf(accountEth);

        vm.startPrank(accountEth);
        vault.withdraw(claimableAmount, accountEth, accountEth);
        vm.stopPrank();

        uint256 userBalanceAfter = asset.balanceOf(accountEth);
        uint256 actualReceived = userBalanceAfter - userBalanceBefore;

        console2.log("User balance before claim:", userBalanceBefore);
        console2.log("User balance after claim:", userBalanceAfter);
        console2.log("Actual amount received:", actualReceived);
        console2.log("Strategy balance after claim:", asset.balanceOf(address(strategy)));

        // The bug: User receives less than they should have been able to claim
        // but the strategy balance is now 0, making the vault insolvent
        assertEq(actualReceived, strategyBalanceAfter, "User should receive remaining strategy balance");
        assertEq(asset.balanceOf(address(strategy)), 0, "Strategy should be empty");

        // This is problematic because:
        // 1. The user's maxWithdraw is not updated to reflect the actual amount received
        // 2. The vault becomes insolvent (strategy balance < 0 in accounting terms)
        // 3. Other users might not be able to claim their rightful amounts

        // Verify that the user's maxWithdraw is not properly updated
        uint256 remainingMaxWithdraw = strategy.claimableWithdraw(accountEth);
        console2.log("Remaining maxWithdraw:", remainingMaxWithdraw);

        // The user still has a positive maxWithdraw even though the strategy is empty
        assertGt(remainingMaxWithdraw, 0, "User should still have positive maxWithdraw");
    }

    /// @notice Test the dust bug with emergency withdrawal scenario
    /// @dev This test shows how emergency withdrawal can create the dust bug scenario
    function test_DustBugWithEmergencyWithdrawal() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Step 1: Deposit and set up redeem request
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialShares = vault.balanceOf(accountEth);
        uint256 redeemShares = initialShares / 2;

        // Request redeem
        _requestRedeem(redeemShares);

        // Fulfill the redeem request
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        uint256 claimableAmount = strategy.claimableWithdraw(accountEth);
        uint256 strategyBalanceBefore = asset.balanceOf(address(strategy));

        // Step 2: Enable emergency withdrawal and withdraw most assets
        vm.startPrank(MANAGER);

        // Propose emergency withdrawal
        strategy.manageEmergencyWithdraw(1, address(0), 0);

        // Wait for timelock and execute
        vm.warp(block.timestamp + 1 weeks);
        strategy.manageEmergencyWithdraw(2, address(0), 0);

        // Withdraw most assets, leaving just enough to trigger dust collection
        uint256 withdrawalAmount = strategyBalanceBefore - claimableAmount + 5; // 5 wei less than tolerance
        strategy.manageEmergencyWithdraw(3, address(this), withdrawalAmount);

        vm.stopPrank();

        uint256 strategyBalanceAfter = asset.balanceOf(address(strategy));
        console2.log("Strategy balance after emergency withdrawal:", strategyBalanceAfter);
        console2.log("Claimable amount:", claimableAmount);
        console2.log("Difference:", claimableAmount - strategyBalanceAfter);

        // Verify the difference is within tolerance constant
        assertTrue(claimableAmount > strategyBalanceAfter, "Claimable should be greater than available");
        assertTrue(claimableAmount - strategyBalanceAfter <= 10, "Difference should be within tolerance");

        // Step 3: Try to claim - this will trigger the dust bug
        uint256 userBalanceBefore = asset.balanceOf(accountEth);

        vm.startPrank(accountEth);
        vault.withdraw(claimableAmount, accountEth, accountEth);
        vm.stopPrank();

        uint256 userBalanceAfter = asset.balanceOf(accountEth);
        uint256 actualReceived = userBalanceAfter - userBalanceBefore;

        console2.log("Actual amount received:", actualReceived);
        console2.log("Strategy balance after claim:", asset.balanceOf(address(strategy)));

        // The dust bug occurs here
        assertEq(actualReceived, strategyBalanceAfter, "User receives remaining balance due to dust collection");
        assertEq(asset.balanceOf(address(strategy)), 0, "Strategy becomes empty");

        // The vault is now insolvent
        uint256 remainingMaxWithdraw = strategy.claimableWithdraw(accountEth);
        assertGt(remainingMaxWithdraw, 0, "User still has positive maxWithdraw despite empty strategy");
    }

    /// @notice Test the specific dust bug in maxWithdraw accounting
    /// @dev This test demonstrates the core issue: maxWithdraw is reduced by actualAmountToClaim
    ///      instead of assetsToClaim, causing accounting inconsistencies
    function test_DustBugMaxWithdrawAccounting() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Step 1: Deposit and set up redeem request
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialShares = vault.balanceOf(accountEth);
        uint256 redeemShares = initialShares / 2;

        // Request redeem
        _requestRedeem(redeemShares);

        // Fulfill the redeem request
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        uint256 claimableAmount = strategy.claimableWithdraw(accountEth);
        uint256 strategyBalanceBefore = asset.balanceOf(address(strategy));

        console2.log("Initial claimable amount:", claimableAmount);
        console2.log("Initial strategy balance:", strategyBalanceBefore);

        // Step 2: Reduce strategy balance to trigger dust collection
        // Make the difference exactly 5 wei (within TOLERANCE_CONSTANT of 10)
        uint256 reductionAmount = claimableAmount - strategyBalanceBefore + 5;

        // Transfer assets out of strategy
        vm.startPrank(address(strategy));
        asset.transfer(address(this), reductionAmount);
        vm.stopPrank();

        uint256 strategyBalanceAfter = asset.balanceOf(address(strategy));
        uint256 difference = claimableAmount - strategyBalanceAfter;

        console2.log("Strategy balance after reduction:", strategyBalanceAfter);
        console2.log("Difference (should be 5):", difference);
        console2.log("Tolerance constant: 10");

        // Verify we're in the dust collection scenario
        assertTrue(claimableAmount > strategyBalanceAfter, "Claimable should be greater than available");
        assertTrue(difference <= 10, "Difference should be within tolerance");

        // Step 3: Claim the full amount
        uint256 userBalanceBefore = asset.balanceOf(accountEth);
        uint256 maxWithdrawBefore = strategy.claimableWithdraw(accountEth);

        vm.startPrank(accountEth);
        vault.withdraw(claimableAmount, accountEth, accountEth);
        vm.stopPrank();

        uint256 userBalanceAfter = asset.balanceOf(accountEth);
        uint256 actualReceived = userBalanceAfter - userBalanceBefore;
        uint256 maxWithdrawAfter = strategy.claimableWithdraw(accountEth);

        console2.log("User received:", actualReceived);
        console2.log("MaxWithdraw before:", maxWithdrawBefore);
        console2.log("MaxWithdraw after:", maxWithdrawAfter);
        console2.log("MaxWithdraw reduction:", maxWithdrawBefore - maxWithdrawAfter);

        // The bug: maxWithdraw is reduced by actualReceived (strategyBalanceAfter)
        // instead of claimableAmount, leaving the user with extra claimable balance
        assertEq(actualReceived, strategyBalanceAfter, "User should receive remaining strategy balance");
        assertEq(maxWithdrawBefore - maxWithdrawAfter, actualReceived, "MaxWithdraw reduced by actual received");

        // The user still has claimable balance even though strategy is empty
        assertGt(maxWithdrawAfter, 0, "User should still have positive maxWithdraw");
        assertEq(maxWithdrawAfter, difference, "Remaining maxWithdraw should equal the dust amount");

        // This creates an insolvent state where the user can claim more than the strategy has
        assertEq(asset.balanceOf(address(strategy)), 0, "Strategy should be empty");
        assertGt(maxWithdrawAfter, 0, "But user still has claimable balance");
    }

    /// @notice Test the dust bug by directly calling the strategy function
    /// @dev This test directly calls handleOperations7540 to demonstrate the bug more clearly
    function test_DustBugDirectStrategyCall() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Step 1: Deposit and set up redeem request
        _deposit(depositAmount);
        _depositFreeAssetsFromSingleAmount(depositAmount, address(fluidVault), address(aaveVault));

        uint256 initialShares = vault.balanceOf(accountEth);
        uint256 redeemShares = initialShares / 2;

        // Request redeem
        _requestRedeem(redeemShares);

        // Fulfill the redeem request
        _fulfillRedeem(redeemShares, address(fluidVault), address(aaveVault));

        uint256 claimableAmount = strategy.claimableWithdraw(accountEth);
        uint256 strategyBalanceBefore = asset.balanceOf(address(strategy));

        // Step 2: Reduce strategy balance to trigger dust collection
        uint256 reductionAmount = claimableAmount - strategyBalanceBefore + 5; // 5 wei less than tolerance

        // Transfer assets out of strategy
        vm.startPrank(address(strategy));
        asset.transfer(address(this), reductionAmount);
        vm.stopPrank();

        uint256 strategyBalanceAfter = asset.balanceOf(address(strategy));
        uint256 difference = claimableAmount - strategyBalanceAfter;

        console2.log("=== Dust Bug Test ===");
        console2.log("Claimable amount:", claimableAmount);
        console2.log("Strategy balance after reduction:", strategyBalanceAfter);
        console2.log("Difference (dust):", difference);
        console2.log("Tolerance constant: 10");

        // Verify we're in the dust collection scenario
        assertTrue(claimableAmount > strategyBalanceAfter, "Claimable should be greater than available");
        assertTrue(difference <= 10, "Difference should be within tolerance");

        // Step 3: Directly call the strategy's claim function
        uint256 maxWithdrawBefore = strategy.claimableWithdraw(accountEth);

        // Call the strategy directly (this is what vault.withdraw calls internally)
        vm.startPrank(address(vault));
        strategy.handleOperations7540(
            ISuperVaultStrategy.Operation.ClaimRedeem, accountEth, accountEth, claimableAmount
        );
        vm.stopPrank();

        uint256 maxWithdrawAfter = strategy.claimableWithdraw(accountEth);
        uint256 userBalanceAfter = asset.balanceOf(accountEth);

        console2.log("User balance after claim:", userBalanceAfter);
        console2.log("MaxWithdraw before:", maxWithdrawBefore);
        console2.log("MaxWithdraw after:", maxWithdrawAfter);
        console2.log("MaxWithdraw reduction:", maxWithdrawBefore - maxWithdrawAfter);
        console2.log("Strategy balance after claim:", asset.balanceOf(address(strategy)));

        // The bug: maxWithdraw is reduced by the actual amount received (strategyBalanceAfter)
        // instead of the requested amount (claimableAmount)
        assertEq(maxWithdrawBefore - maxWithdrawAfter, strategyBalanceAfter, "MaxWithdraw reduced by actual received");
        assertEq(maxWithdrawAfter, difference, "Remaining maxWithdraw equals dust amount");

        // The user still has claimable balance even though strategy is empty
        assertGt(maxWithdrawAfter, 0, "User should still have positive maxWithdraw");
        assertEq(asset.balanceOf(address(strategy)), 0, "Strategy should be empty");

        console2.log("=== Bug Confirmed ===");
        console2.log("User can still claim:", maxWithdrawAfter);
        console2.log("But strategy has:", asset.balanceOf(address(strategy)));
        console2.log("Vault is insolvent!");
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that NO_PROPOSAL error is thrown when trying to execute emergency withdraw activation without a
    /// proposal
    function test_RevertWhen_ExecuteEmergencyWithdrawActivation_NoProposal() public {
        // Ensure there's no active proposal
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should not have active proposal");

        // Try to execute emergency withdraw activation without a proposal
        vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
        strategy.manageEmergencyWithdraw(2, address(0), 0); // action 2 = ExecuteActivation
    }

    /// @notice Test that anyone can try to execute emergency withdraw activation when there's no proposal and get
    /// NO_PROPOSAL error
    function test_RevertWhen_AnyoneTriesToExecuteEmergencyWithdrawActivation_NoProposal() public {
        // Ensure there's no active proposal
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should not have active proposal");

        // Switch to a random address (not manager)
        address randomUser = address(0x1234567890);
        vm.startPrank(randomUser);

        // Try to execute emergency withdraw activation without a proposal - should revert with NO_PROPOSAL, not access
        // control
        vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
        strategy.manageEmergencyWithdraw(2, address(0), 0); // action 2 = ExecuteActivation

        vm.stopPrank();
    }

    /// @notice Test that NO_PROPOSAL error is thrown when trying to cancel a proposal that doesn't exist
    function test_RevertWhen_CancelEmergencyWithdrawProposal_NoProposal() public {
        // Ensure there's no active proposal
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should not have active proposal");

        // Switch to manager
        vm.startPrank(MANAGER);

        // Try to cancel a proposal that doesn't exist
        vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
        strategy.manageEmergencyWithdraw(4, address(0), 0); // action 4 = CancelProposal

        vm.stopPrank();
    }

    /// @notice Test successful emergency withdraw proposal and execution workflow
    function test_EmergencyWithdrawProposalAndExecution() public {
        vm.startPrank(MANAGER);

        // Step 1: Propose emergency withdraw
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultStrategy.EmergencyWithdrawableProposed(true, block.timestamp + 1 weeks);
        strategy.manageEmergencyWithdraw(1, address(0), 0); // action 1 = Propose

        // Verify proposal state
        assertEq(strategy.proposedEmergencyWithdrawable(), true, "Proposal should be true");
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), block.timestamp + 1 weeks, "Wrong effective time");
        assertEq(strategy.emergencyWithdrawable(), false, "Emergency withdrawable should still be false");

        // Step 2: Try to execute before timelock expires
        vm.expectRevert(ISuperVaultStrategy.INVALID_TIMESTAMP.selector);
        strategy.manageEmergencyWithdraw(2, address(0), 0); // action 2 = ExecuteActivation

        // Step 3: Wait for timelock to expire and execute
        vm.warp(block.timestamp + 1 weeks);

        vm.expectEmit(true, true, true, true);
        emit ISuperVaultStrategy.EmergencyWithdrawableUpdated(true);
        strategy.manageEmergencyWithdraw(2, address(0), 0); // action 2 = ExecuteActivation

        // Verify execution state
        assertEq(strategy.emergencyWithdrawable(), true, "Emergency withdrawable should be true");
        assertEq(strategy.proposedEmergencyWithdrawable(), false, "Proposed should be reset to false");
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Effective time should be reset to 0");

        vm.stopPrank();
    }

    /// @notice Test successful emergency withdraw proposal cancellation workflow
    function test_EmergencyWithdrawProposalCancellation() public {
        vm.startPrank(MANAGER);

        // Step 1: Propose emergency withdraw
        strategy.manageEmergencyWithdraw(1, address(0), 0); // action 1 = Propose

        // Verify proposal state
        assertEq(strategy.proposedEmergencyWithdrawable(), true, "Proposal should be true");
        assertGt(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should have effective time");
        assertEq(strategy.emergencyWithdrawable(), false, "Emergency withdrawable should still be false");

        // Step 2: Cancel the proposal
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultStrategy.EmergencyWithdrawableProposalCanceled();
        strategy.manageEmergencyWithdraw(4, address(0), 0); // action 4 = CancelProposal

        // Verify cancellation state
        assertEq(strategy.proposedEmergencyWithdrawable(), false, "Proposed should be reset to false");
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Effective time should be reset to 0");
        assertEq(strategy.emergencyWithdrawable(), false, "Emergency withdrawable should remain false");

        vm.stopPrank();
    }

    /// @notice Test that trying to execute after cancellation fails with NO_PROPOSAL
    function test_RevertWhen_ExecuteAfterCancellation() public {
        vm.startPrank(MANAGER);

        // Step 1: Propose emergency withdraw
        strategy.manageEmergencyWithdraw(1, address(0), 0); // action 1 = Propose

        // Step 2: Cancel the proposal
        strategy.manageEmergencyWithdraw(4, address(0), 0); // action 4 = CancelProposal

        // Step 3: Try to execute - should fail with NO_PROPOSAL
        vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
        strategy.manageEmergencyWithdraw(2, address(0), 0); // action 2 = ExecuteActivation

        vm.stopPrank();
    }

    /// @notice Test that only manager can cancel proposals
    function test_RevertWhen_NonManagerTriesToCancelProposal() public {
        vm.startPrank(MANAGER);

        // Step 1: Propose emergency withdraw
        strategy.manageEmergencyWithdraw(1, address(0), 0); // action 1 = Propose

        vm.stopPrank();

        // Step 2: Try to cancel as non-manager
        address randomUser = address(0x1234567890);
        vm.startPrank(randomUser);

        vm.expectRevert(ISuperVaultStrategy.MANAGER_NOT_AUTHORIZED.selector);
        strategy.manageEmergencyWithdraw(4, address(0), 0); // action 4 = CancelProposal

        vm.stopPrank();
    }

    /// @notice Test that multiple proposals can be made and cancelled
    function test_MultipleProposalAndCancellationCycles() public {
        vm.startPrank(MANAGER);

        // Cycle 1: Propose and cancel
        strategy.manageEmergencyWithdraw(1, address(0), 0); // action 1 = Propose
        assertGt(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should have effective time");

        strategy.manageEmergencyWithdraw(4, address(0), 0); // action 4 = CancelProposal
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Effective time should be reset");

        // Cycle 2: Propose and cancel again
        strategy.manageEmergencyWithdraw(1, address(0), 0); // action 1 = Propose
        assertGt(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should have effective time again");

        strategy.manageEmergencyWithdraw(4, address(0), 0); // action 4 = CancelProposal
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Effective time should be reset again");

        // Cycle 3: Propose, wait, and execute
        strategy.manageEmergencyWithdraw(1, address(0), 0); // action 1 = Propose
        vm.warp(block.timestamp + 1 weeks);
        strategy.manageEmergencyWithdraw(2, address(0), 0); // action 2 = ExecuteActivation

        assertEq(strategy.emergencyWithdrawable(), true, "Emergency withdrawable should be true");

        vm.stopPrank();
    }

    /// @notice Test the vulnerability fix: anyone trying to reset emergency withdrawable flag when no proposal exists
    function test_VulnerabilityFixed_CannotResetEmergencyWithdrawableWhenNoProposal() public {
        // Ensure emergency withdrawable is initially false and no proposal exists
        assertEq(strategy.emergencyWithdrawable(), false, "Emergency withdrawable should be false initially");
        assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should not have active proposal");

        // Try as various actors to execute emergency withdraw activation without proposal
        address[] memory actors = new address[](3);
        actors[0] = MANAGER;
        actors[1] = accountEth;
        actors[2] = address(0x1234567890); // random address

        for (uint256 i = 0; i < actors.length; i++) {
            vm.startPrank(actors[i]);

            // Should revert with NO_PROPOSAL, not allowing them to reset the flag
            vm.expectRevert(ISuperVaultStrategy.NO_PROPOSAL.selector);
            strategy.manageEmergencyWithdraw(2, address(0), 0); // action 2 = ExecuteActivation

            vm.stopPrank();

            // Verify state hasn't changed
            assertEq(strategy.emergencyWithdrawable(), false, "Emergency withdrawable should remain false");
            assertEq(strategy.emergencyWithdrawableEffectiveTime(), 0, "Should still not have active proposal");
        }
    }

    /*//////////////////////////////////////////////////////////////
                       MANAGEMENT FEE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that deposit skims entry fee to recipient and mints net shares
    function test_Deposit_WithMgmtFee_SkimsAndMintsNet() public {
        // Set 1% management (entry) fee, recipient = TREASURY
        _setFeeConfig(100, 100, TREASURY);

        uint256 assets = 1000e6;
        _getTokens(address(asset), accInstances[0].account, assets);

        vm.startPrank(accInstances[0].account);
        asset.approve(address(vault), type(uint256).max);
        uint256 shares = vault.deposit(assets, accInstances[0].account);
        vm.stopPrank();

        // Fee = ceil(1% of 1000) = 10
        assertEq(asset.balanceOf(TREASURY), 10e6, "fee skimmed to recipient");
        // Strategy received assets - fee
        assertEq(asset.balanceOf(address(strategy)), 990e6, "strategy got net assets");

        // Shares minted equal previewDeposit(assets)
        uint256 expectedShares = vault.previewDeposit(assets);
        assertEq(shares, expectedShares, "minted shares = previewDeposit");
    }

    /// @notice Test that previewDeposit reflects entry fee precisely (ceil on fee)
    function test_PreviewDeposit_WithMgmtFee_FeeCeil() public {
        _setFeeConfig(100, 100, TREASURY); // 1%

        // Pick a value that exercises ceil rounding (e.g., 1 wei of USDC)
        uint256 tiny = 1; // 1 unit (1e-6 USDC)
        // fee = ceil(1% of 1) = 1 (since we can't take 0)
        uint256 expectedShares = vault.convertToShares(0); // assetsNet = 0

        assertEq(vault.previewDeposit(tiny), expectedShares, "fee rounds up");
    }

    /// @notice Test that mint path: previewMint returns gross and the vault actually charges it
    function test_Mint_WithMgmtFee_GrossChargedMatchesPreviewMint() public {
        _setFeeConfig(100, 100, TREASURY); // 1%

        // Seed payer
        _getTokens(address(asset), accInstances[0].account, 10_000e6);

        // Target shares
        uint256 sharesWanted = 123_456;

        // Compute required gross assets
        uint256 grossRequired = vault.previewMint(sharesWanted);
        vm.startPrank(accInstances[0].account);
        asset.approve(address(vault), type(uint256).max);
        uint256 assetsSpent = vault.mint(sharesWanted, accInstances[0].account);
        vm.stopPrank();

        assertEq(assetsSpent, grossRequired, "spent == previewMint");
        // Recipient got exactly the entry fee = gross - net
        uint256 net = vault.convertToAssets(sharesWanted);
        uint256 fee = assetsSpent - net;
        assertEq(asset.balanceOf(TREASURY), fee, "recipient got entry fee");
    }

    /// @notice Test that quote function and mint agree
    function test_QuoteMintAssetsGross_MatchesMintAndPreviews() public {
        _setFeeConfig(100, 350, TREASURY); // 3.5%

        uint256 shares = 1_000_000;
        (uint256 gross, uint256 net) = strategy.quoteMintAssetsGross(shares);

        // previewMint matches gross
        assertEq(vault.previewMint(shares), gross, "previewMint == quote gross");

        // Deposit enough and mint; caller pays 'gross'
        _getTokens(address(asset), accInstances[0].account, gross);
        vm.startPrank(accInstances[0].account);
        asset.approve(address(vault), type(uint256).max);
        uint256 paid = vault.mint(shares, accInstances[0].account);
        vm.stopPrank();

        assertEq(paid, gross, "paid gross");
        // Fee equals gross - net to recipient
        assertEq(asset.balanceOf(TREASURY), gross - net, "fee paid");
    }

    /*//////////////////////////////////////////////////////////////
                        NATIVE ETH HANDLING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ExecuteHooks_AcceptsPayable() public {
        // This test verifies that executeHooks can accept ETH (is payable)
        // Since reverts return ETH, we test by sending ETH directly to the receive function

        uint256 ethAmount = 1 ether;

        // Fund the manager with ETH
        vm.deal(MANAGER, ethAmount);
        uint256 strategyETHBefore = address(strategy).balance;

        // Send ETH directly to the strategy's receive function
        vm.startPrank(MANAGER);
        (bool success,) = address(strategy).call{ value: ethAmount }("");
        vm.stopPrank();

        // Verify the call succeeded and ETH was received
        assertTrue(success, "ETH transfer should succeed");
        assertEq(address(strategy).balance, strategyETHBefore + ethAmount, "Strategy should have received ETH");

        // Now test that executeHooks is payable by calling it with ETH (it will revert but not due to payable)
        ISuperVaultStrategy.ExecuteArgs memory args = ISuperVaultStrategy.ExecuteArgs({
            hooks: new address[](0), // Empty array will cause ZERO_LENGTH revert
            hookCalldata: new bytes[](0),
            expectedAssetsOrSharesOut: new uint256[](0),
            globalProofs: new bytes32[][](0),
            strategyProofs: new bytes32[][](0)
        });

        vm.deal(MANAGER, ethAmount);
        vm.startPrank(MANAGER);
        vm.expectRevert(ISuperVaultStrategy.ZERO_LENGTH.selector);
        strategy.executeHooks{ value: ethAmount }(args); // This proves it's payable
        vm.stopPrank();
    }

    function test_ReceiveFunction_AcceptsETH() public {
        uint256 ethAmount = 1 ether;

        // Send ETH directly to strategy
        vm.deal(address(this), ethAmount);
        uint256 strategyBalanceBefore = address(strategy).balance;

        // Send ETH to strategy
        (bool success,) = payable(address(strategy)).call{ value: ethAmount }("");
        assertTrue(success, "ETH transfer should succeed");

        // Verify ETH was received
        assertEq(address(strategy).balance, strategyBalanceBefore + ethAmount, "Strategy should receive ETH");
    }

    function test_RevertWhen_ExecuteHooks_WithoutPayable() public {
        // This test verifies that the old version would have failed
        // Since we've already added payable, we'll test with a mock that doesn't have payable

        // Create a simple contract without payable functions
        SimpleNonPayableContract nonPayable = new SimpleNonPayableContract();

        uint256 ethAmount = 1 ether;
        vm.deal(address(this), ethAmount);

        // Try to send ETH to non-payable function - this should fail
        (bool success,) = address(nonPayable).call{ value: ethAmount }(abi.encodeWithSignature("nonPayableFunction()"));
        assertFalse(success, "Should fail when sending ETH to non-payable function");
    }

    function test_executeHooks_WithNativeETHHook() public {
        vm.selectFork(FORKS[ETH]);
        uint256 depositAmount = 1000e6; // 1000 USDC
        uint256 ethAmount = 0.5 ether;

        // Add MockETHReceiver as active yield source
        address ethReceiver = contractAddresses[ETH]["MOCK_ETH_RECEIVER"];
        vm.startPrank(MANAGER);
        strategy.manageYieldSources(
            _toArray(ethReceiver),
            _toArray(_getContract(ETH, ERC4626_YIELD_SOURCE_ORACLE_KEY)),
            new uint8[](1) // actionType 0 = add
        );
        vm.stopPrank();

        // Fund MockETHReceiver with USDC so it can transfer when hook executes
        deal(address(asset), ethReceiver, depositAmount);

        // STEP 1: Execute native ETH hook separately via executeHooks
        address[] memory nativeHooks = new address[](1);
        nativeHooks[0] = contractAddresses[ETH]["MOCK_NATIVE_ETH_HOOK"]; // MockNativeETHHook

        bytes[] memory nativeHookCalldata = new bytes[](1);
        nativeHookCalldata[0] = _createMockNativeETHHookData(ethReceiver, ethAmount);

        uint256[] memory nativeExpectedOut = new uint256[](1);
        nativeExpectedOut[0] = ethAmount; // Expected ETH transfer amount

        // Create argsForProofs for native hook
        bytes[] memory nativeArgsForProofs = new bytes[](1);
        nativeArgsForProofs[0] = ISuperHookInspector(nativeHooks[0]).inspect(nativeHookCalldata[0]);

        // Get merkle proofs for native hook
        bytes32[][] memory nativeGlobalProofs = _getMerkleProofsForHooks(nativeHooks, nativeArgsForProofs);
        bytes32[][] memory nativeStrategyProofs = new bytes32[][](1);
        nativeStrategyProofs[0] = new bytes32[](0);

        // Fund manager with ETH for hook execution
        vm.deal(MANAGER, ethAmount);

        // Execute native ETH hook via executeHooks
        vm.startPrank(MANAGER);
        strategy.executeHooks{ value: ethAmount }(
            ISuperVaultStrategy.ExecuteArgs({
                hooks: nativeHooks,
                hookCalldata: nativeHookCalldata,
                expectedAssetsOrSharesOut: nativeExpectedOut,
                globalProofs: nativeGlobalProofs,
                strategyProofs: nativeStrategyProofs
            })
        );
        vm.stopPrank();
    }

    function _createMockNativeETHHookData(
        address ethReceiver,
        uint256 ethAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        // Create calldata following the standard hook format: oracleId + yieldSource + amount
        return abi.encodePacked(
            bytes32(0), // oracle ID placeholder
            ethReceiver, // yield source (ETH receiver)
            ethAmount // ETH amount to send
        );
    }

    /*//////////////////////////////////////////////////////////////
                       7540 UNDERLYING TESTS
    //////////////////////////////////////////////////////////////*/
    function test_7540Underlying_E2E_Flow() public {
        // Set up the vault
        _setUp7540UnderlyingSuperVault();

        AccountInstance memory instance = accInstances[0];
        address account = instance.account;

        // Deposit USDC into the SuperVault
        uint256 depositAmount = 1000e6; // 1000 USDC
        _getTokens(address(asset), account, depositAmount);
        __deposit(instance, depositAmount);

        // Verify state
        assertEq(asset.balanceOf(address(strategy)), depositAmount, "Wrong strategy balance");

        _depositFreeAssetsFromSingleAmount7540(depositAmount, address(aaveVault), address(centrifugeVault));

        uint256 userShares = vault.balanceOf(account);
        assertGt(userShares, 0, "No shares minted to user");

        // Record balances before redeem
        uint256 preRedeemUserAssets = asset.balanceOf(account);

        // Fast forward time to simulate yield on underlying vaults
        vm.warp(block.timestamp + 50 weeks);

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));

        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Step 4: Request Redeem
        __requestRedeem(instance, userShares, false);

        // Verify shares are escrowed
        assertEq(IERC20(vault.share()).balanceOf(account), 0, "User shares not transferred from account");
        assertEq(IERC20(vault.share()).balanceOf(address(escrow)), userShares, "Shares not transferred to escrow");

        console2.log("--pps before---", aggregator.getPPS(address(strategy)));
        vm.warp(block.timestamp + 1 weeks);
        _updateSuperVaultPPS(address(strategy), address(vault));

        console2.log("--pps after---", aggregator.getPPS(address(strategy)));

        // Step 5: Fulfill Redeem
        _fulfillRedeem7540Underlying(userShares, address(aaveVault), address(centrifugeVault), account);

        // Verify balances
        assertEq(asset.balanceOf(account), preRedeemUserAssets, "User assets not returned");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _toArray(address item) internal pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = item;
        return array;
    }

    function _toBoolArray(bool item) internal pure returns (bool[] memory) {
        bool[] memory array = new bool[](1);
        array[0] = item;
        return array;
    }

    function _toBytesArray(bytes memory item) internal pure returns (bytes[] memory) {
        bytes[] memory array = new bytes[](1);
        array[0] = item;
        return array;
    }

    function _toUint256Array(uint256 item) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = item;
        return array;
    }
}

/// @notice Simple contract without payable functions for testing
contract SimpleNonPayableContract {
    function nonPayableFunction() external pure returns (bool) {
        return true;
    }
}
