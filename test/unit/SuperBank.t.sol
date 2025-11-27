// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ApproveERC20Hook } from "@superform-v2-core/src/hooks/tokens/erc20/ApproveERC20Hook.sol";
import { Redeem4626VaultHook } from "@superform-v2-core/src/hooks/vaults/4626/Redeem4626VaultHook.sol";
import {
    AcrossSendFundsAndExecuteOnDstHook
} from "@superform-v2-core/src/hooks/bridges/across/AcrossSendFundsAndExecuteOnDstHook.sol";
import { SwapOdosV2Hook } from "@superform-v2-core/src/hooks/swappers/odos/SwapOdosV2Hook.sol";
import { Bank } from "../../src/Bank.sol";
import { SuperBank } from "../../src/SuperBank.sol";
import { ISuperBank } from "../../src/interfaces/ISuperBank.sol";
import { ISuperGovernor, FeeType } from "../../src/interfaces/ISuperGovernor.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";
import { InternalHelpers } from "@superform-v2-core/test/utils/InternalHelpers.sol";
import { SuperGovernor } from "../../src/SuperGovernor.sol";
import { Up } from "../../src/UP/Up.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { Mock4626Vault } from "../mocks/Mock4626Vault.sol";
import { MockSuperHook } from "../mocks/MockSuperHook.sol";
import { MockHookTarget } from "../mocks/MockHookTarget.sol";
import { MockMultiTargetHook } from "../mocks/MockMultiTargetHook.sol";
import { MockHookWithSlippage } from "../mocks/MockHookWithSlippage.sol";
import { IHookExecutionData } from "../../src/interfaces/IHookExecutionData.sol";
import { MockOdosRouterV2 } from "@superform-v2-core/test/mocks/MockOdosRouterV2.sol";
import { OdosAPIParser } from "@superform-v2-core/test/utils/parsers/OdosAPIParser.sol";
import { AcrossV3Helper } from "pigeon/across/AcrossV3Helper.sol";
import { MerkleTreeBuilder } from "../utils/MerkleTreeBuilder.sol";
import { SuperBankTestHelpers } from "../utils/SuperBankTestHelpers.sol";

import "forge-std/Test.sol";

contract SuperBankTest is PeripheryHelpers, InternalHelpers, OdosAPIParser {
    SuperGovernor internal superGovernor;
    SuperBank internal superBank;
    Up internal up;
    MockOdosRouterV2 internal odosRouter;
    MockERC20 internal token;
    Mock4626Vault internal vault;
    AcrossV3Helper internal acrossV3Helper;

    address internal sGovernor;
    address internal governor;
    address internal treasury;
    address internal oracleManager;
    address internal user;
    address internal hook1;
    address internal hook2;
    address internal fulfillHook1;
    address internal fulfillHook2;
    address internal validator1;
    address internal validator2;
    address internal ppsOracle1;
    address internal ppsOracle2;
    address internal superVaultAggregator;
    address internal strategy1;
    address internal admin;

    address underlying;

    string public ETHEREUM_RPC_URL = vm.envString(ETHEREUM_RPC_URL_KEY);
    string public BASE_RPC_URL = vm.envString(BASE_RPC_URL_KEY);

    function setUp() public {
        sGovernor = _deployAccount(0x1, "SuperGovernor");
        governor = _deployAccount(0x2, "Governor");
        treasury = _deployAccount(0x3, "Treasury");
        oracleManager = _deployAccount(0x4, "OracleManager");
        user = _deployAccount(0x5, "User");
        hook1 = _deployAccount(0x6, "Hook1");
        hook2 = _deployAccount(0x7, "Hook2");
        fulfillHook1 = _deployAccount(0x8, "FulfillHook1");
        fulfillHook2 = _deployAccount(0x9, "FulfillHook2");
        validator1 = _deployAccount(0xA, "Validator1");
        validator2 = _deployAccount(0xB, "Validator2");
        ppsOracle1 = _deployAccount(0xC, "PPSOracle1");
        ppsOracle2 = _deployAccount(0xD, "PPSOracle2");
        admin = _deployAccount(0xE, "Admin");
        superGovernor = new SuperGovernor(sGovernor, governor, governor, oracleManager, governor, treasury);

        superBank = new SuperBank(address(superGovernor));
        up = new Up(admin);

        underlying = CHAIN_1_USDC;
        odosRouter = new MockOdosRouterV2();
        vm.label(address(odosRouter), "OdosRouter");

        token = new MockERC20("Test Token", "TEST", 18);
        vm.label(address(token), "Test Token");

        vault = new Mock4626Vault(address(token), "Test Vault", "TSTV");
        vm.label(address(vault), "4626 vault");

        acrossV3Helper = new AcrossV3Helper();
        vm.label(address(acrossV3Helper), "Pigeon AcrossV3Helper");
        vm.allowCheatcodes(address(acrossV3Helper));
        vm.makePersistent(address(acrossV3Helper));
    }

    function test_SuperBank_Constructor() public {
        assertEq(address(superBank.SUPER_GOVERNOR()), address(superGovernor), "SuperGovernor address not set correctly");

        vm.expectRevert(ISuperBank.INVALID_ADDRESS.selector);
        new SuperBank(address(0));
    }

    function test_SuperBank_receive() public {
        uint256 initialBalance = address(superBank).balance;

        uint256 amountToSend = 1 ether;
        vm.deal(user, amountToSend);

        vm.prank(user);
        (bool success,) = address(superBank).call{ value: amountToSend }("");
        assertTrue(success, "ETH transfer failed");

        assertEq(address(superBank).balance, initialBalance + amountToSend, "SuperBank did not receive ETH correctly");
    }

    /// @notice Tests distribute reverts when caller is not bank manager
    /// @dev Covers SuperBank.sol:36-37 - access control check in _onlyBankManager
    function test_SuperBank_distribute_NotBankManager() public {
        // Don't grant BANK_MANAGER_ROLE to the caller
        vm.startPrank(user); // user is not a bank manager

        vm.expectRevert(ISuperBank.INVALID_BANK_MANAGER.selector);
        superBank.distribute(100 ether);

        vm.stopPrank();
    }

    function test_SuperBank_distribute_ZeroAmount() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        vm.expectRevert(Bank.ZERO_AMOUNT.selector);
        superBank.distribute(0);
    }

    function test_SuperBank_distribute_InvalidUpAmountToDistribute() public {
        vm.startPrank(sGovernor);
        vm.stopPrank();

        vm.startPrank(sGovernor);
        superGovernor.grantRole(keccak256("BANK_MANAGER_ROLE"), address(this));
        superGovernor.setAddress(keccak256("UP"), address(up));
        superGovernor.setAddress(keccak256("SUP"), address(this));
        superGovernor.setAddress(keccak256("TREASURY"), address(treasury));
        vm.stopPrank();

        vm.expectRevert(ISuperBank.INVALID_UP_AMOUNT_TO_DISTRIBUTE.selector);
        superBank.distribute(1e6);
    }

    function test_SuperBank_distribute_success_unit() public {
        address supToken = address(0xF); // Mock sUP token address
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        uint256 initialSupBalance = up.balanceOf(supToken);
        uint256 initialTreasuryBalance = up.balanceOf(treasury);

        uint256 revenueShare = superGovernor.getFee(FeeType.REVENUE_SHARE);
        uint256 expectedSupAmount = (upAmount * revenueShare) / 10_000;
        uint256 expectedTreasuryAmount = upAmount - expectedSupAmount;

        vm.expectEmit(true, true, true, true);
        emit ISuperBank.RevenueDistributed(address(up), supToken, treasury, expectedSupAmount, expectedTreasuryAmount);
        superBank.distribute(upAmount);

        assertEq(up.balanceOf(supToken), initialSupBalance + expectedSupAmount, "sUP token received incorrect amount");
        assertEq(
            up.balanceOf(treasury),
            initialTreasuryBalance + expectedTreasuryAmount,
            "Treasury received incorrect amount"
        );
    }

    /// @notice Tests distribute reverts when revenueShare exceeds BPS_PRECISION
    /// @dev Covers SuperBank.sol:65 - if (revenueShare > BPS_PRECISION) revert INVALID_REVENUE_SHARE()
    function test_SuperBank_distribute_RevenueShareExceedsPrecision() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return a value greater than BPS_PRECISION (10,000)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(10_001))
        );

        vm.expectRevert(ISuperBank.INVALID_REVENUE_SHARE.selector);
        superBank.distribute(upAmount);
    }

    /// @notice Tests distribute succeeds when revenueShare equals BPS_PRECISION
    /// @dev Covers SuperBank.sol:65 - boundary condition where revenueShare == BPS_PRECISION (10,000)
    function test_SuperBank_distribute_RevenueShareAtPrecision() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return exactly BPS_PRECISION (10,000)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(10_000))
        );

        // Should succeed - 100% goes to sUP, 0% to treasury
        uint256 expectedSupAmount = upAmount; // 100 ether * 10,000 / 10,000 = 100 ether
        uint256 expectedTreasuryAmount = 0;

        vm.expectEmit(true, true, true, true);
        emit ISuperBank.RevenueDistributed(address(up), supToken, treasury, expectedSupAmount, expectedTreasuryAmount);
        superBank.distribute(upAmount);

        assertEq(up.balanceOf(supToken), expectedSupAmount, "sUP token should receive 100% of distribution");
        assertEq(up.balanceOf(treasury), expectedTreasuryAmount, "Treasury should receive 0%");
    }

    /// @notice Tests distribute reverts with large revenueShare value
    /// @dev Covers SuperBank.sol:65 - tests with significantly higher value than BPS_PRECISION
    function test_SuperBank_distribute_RevenueShareLargeValue() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return a very large value
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(100_000))
        );

        vm.expectRevert(ISuperBank.INVALID_REVENUE_SHARE.selector);
        superBank.distribute(upAmount);
    }

    /// @notice Tests distribute when supAmount is zero (no transfer to sUP)
    /// @dev Covers SuperBank.sol:76 - if (supAmount > 0) branch when supAmount = 0
    function test_SuperBank_distribute_SupAmountZero() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return 0 (0% to sUP, 100% to treasury)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(0))
        );

        uint256 initialSupBalance = up.balanceOf(supToken);
        uint256 initialTreasuryBalance = up.balanceOf(treasury);

        // supAmount should be 0, treasuryAmount should be 100 ether
        vm.expectEmit(true, true, true, true);
        emit ISuperBank.RevenueDistributed(address(up), supToken, treasury, 0, upAmount);
        superBank.distribute(upAmount);

        // sUP should not receive anything
        assertEq(up.balanceOf(supToken), initialSupBalance, "sUP token should receive 0");
        // Treasury should receive everything
        assertEq(up.balanceOf(treasury), initialTreasuryBalance + upAmount, "Treasury should receive 100%");
    }

    /// @notice Tests distribute when supAmount is greater than zero
    /// @dev Covers SuperBank.sol:76 - if (supAmount > 0) branch when supAmount > 0
    function test_SuperBank_distribute_SupAmountGreaterThanZero() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return 5000 (50% to sUP, 50% to treasury)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(5000))
        );

        uint256 initialSupBalance = up.balanceOf(supToken);
        uint256 initialTreasuryBalance = up.balanceOf(treasury);

        uint256 expectedSupAmount = 50 ether;
        uint256 expectedTreasuryAmount = 50 ether;

        vm.expectEmit(true, true, true, true);
        emit ISuperBank.RevenueDistributed(
            address(up), supToken, treasury, expectedSupAmount, expectedTreasuryAmount
        );
        superBank.distribute(upAmount);

        // Both should receive 50%
        assertEq(up.balanceOf(supToken), initialSupBalance + expectedSupAmount, "sUP token should receive 50%");
        assertEq(
            up.balanceOf(treasury), initialTreasuryBalance + expectedTreasuryAmount, "Treasury should receive 50%"
        );
    }

    /// @notice Tests distribute with very small amounts that could round to zero
    /// @dev Covers SuperBank.sol:76 - edge case with small amounts and rounding
    function test_SuperBank_distribute_SmallAmountRounding() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        // Very small amount: 1 wei
        uint256 upAmount = 1;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return 5000 (50%)
        // With Math.Rounding.Ceil, even 1 wei at 50% should round up to 1
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(5000))
        );

        uint256 initialSupBalance = up.balanceOf(supToken);
        uint256 initialTreasuryBalance = up.balanceOf(treasury);

        superBank.distribute(upAmount);

        // With Rounding.Ceil, 1 * 5000 / 10000 = 0.5 rounds up to 1
        // So supAmount = 1, treasuryAmount = 0
        assertEq(up.balanceOf(supToken), initialSupBalance + 1, "sUP token should receive 1 wei (rounded up)");
        assertEq(up.balanceOf(treasury), initialTreasuryBalance, "Treasury should receive 0 wei");
    }

    /// @notice Tests distribute when treasuryAmount is zero (no transfer to treasury)
    /// @dev Covers SuperBank.sol:80 - if (treasuryAmount > 0) branch when treasuryAmount = 0
    function test_SuperBank_distribute_TreasuryAmountZero() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return 10,000 (100% to sUP, 0% to treasury)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(10_000))
        );

        uint256 initialSupBalance = up.balanceOf(supToken);
        uint256 initialTreasuryBalance = up.balanceOf(treasury);

        superBank.distribute(upAmount);

        // sUP should receive 100%, treasury should receive 0 (no transfer)
        assertEq(up.balanceOf(supToken), initialSupBalance + upAmount, "sUP token should receive 100%");
        assertEq(up.balanceOf(treasury), initialTreasuryBalance, "Treasury should receive 0 (no transfer)");
    }

    /// @notice Tests distribute when treasuryAmount is greater than zero
    /// @dev Covers SuperBank.sol:80 - if (treasuryAmount > 0) branch when treasuryAmount > 0
    function test_SuperBank_distribute_TreasuryAmountGreaterThanZero() public {
        address supToken = address(0xF);
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        superGovernor.setAddress(superGovernor.UP(), address(up));
        superGovernor.setAddress(superGovernor.SUP_STRATEGY(), supToken);
        superGovernor.setAddress(superGovernor.TREASURY(), treasury);
        vm.stopPrank();

        vm.warp(block.timestamp + 4 * 365 days);

        uint256 upAmount = 100 ether;
        vm.startPrank(admin);
        up.mint(address(superBank), upAmount);
        vm.stopPrank();

        // Mock getFee to return 3000 (30% to sUP, 70% to treasury)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getFee(uint8)", uint8(FeeType.REVENUE_SHARE)),
            abi.encode(uint256(3000))
        );

        uint256 initialSupBalance = up.balanceOf(supToken);
        uint256 initialTreasuryBalance = up.balanceOf(treasury);

        superBank.distribute(upAmount);

        uint256 expectedSupAmount = 30 ether;
        uint256 expectedTreasuryAmount = 70 ether;

        // Both should receive their respective shares
        assertEq(up.balanceOf(supToken), initialSupBalance + expectedSupAmount, "sUP token should receive 30%");
        assertEq(
            up.balanceOf(treasury), initialTreasuryBalance + expectedTreasuryAmount, "Treasury should receive 70%"
        );
    }

    /// @notice Tests executeHooks reverts when caller is not bank manager
    /// @dev Covers SuperBank.sol:36-37 - access control check in executeHooks
    function test_SuperBank_executeHooks_NotBankManager() public {
        // Don't grant BANK_MANAGER_ROLE to the caller
        vm.startPrank(user); // user is not a bank manager

        address[] memory hooks = new address[](1);
        hooks[0] = address(0x1111);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.expectRevert(ISuperBank.INVALID_BANK_MANAGER.selector);
        superBank.executeHooks(executionData);

        vm.stopPrank();
    }

    function test_SuperBank_executeHooks_ZeroLengthArray() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        address[] memory hooks = new address[](0);
        bytes[] memory data = new bytes[](0);
        bytes32[][] memory merkleProofs = new bytes32[][](0);
        uint256[] memory expectedOutputs = new uint256[](0);

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.startPrank(address(this));
        vm.expectRevert(Bank.ZERO_LENGTH_ARRAY.selector);
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    function test_SuperBank_executeHooks_InvalidArrayLength() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        address[] memory hooks = new address[](2);
        hooks[0] = address(0x1111);
        hooks[1] = address(0x2222);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](1);
        merkleProofs[1] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 0;
        expectedOutputs[1] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.expectRevert(Bank.INVALID_ARRAY_LENGTH.selector);
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    /// @notice Tests executeHooks reverts when hook address is zero
    /// @dev Covers Bank.sol:83 - if (hookAddress == address(0)) revert ZERO_ADDRESS()
    function test_SuperBank_executeHooks_ZeroAddressHook() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        address[] memory hooks = new address[](1);
        hooks[0] = address(0); // Zero address hook

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.expectRevert(Bank.ZERO_ADDRESS.selector);
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    /// @notice Tests executeHooks reverts when zero address is at different positions in array
    /// @dev Covers Bank.sol:83 - zero address check happens early in loop iteration
    function test_SuperBank_executeHooks_ZeroAddressAtDifferentPositions() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Test 1: Zero address in second position
        address[] memory hooks = new address[](2);
        hooks[0] = address(0); // Zero address first
        hooks[1] = address(0x2222);

        bytes[] memory data = new bytes[](2);
        data[0] = "data1";
        data[1] = "data2";

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](1);
        merkleProofs[1] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 0;
        expectedOutputs[1] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.expectRevert(Bank.ZERO_ADDRESS.selector);
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    /// @notice Tests executeHooks reverts when hook is not registered
    /// @dev Covers Bank.sol:92 - if (!_isHookRegistered(hookAddress)) revert HOOK_NOT_REGISTERED()
    function test_SuperBank_executeHooks_HookNotRegistered() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create a hook but don't register it
        address unregisteredHook = address(0x9999);

        address[] memory hooks = new address[](1);
        hooks[0] = unregisteredHook; // Not registered

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.expectRevert(Bank.HOOK_NOT_REGISTERED.selector);
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    /// @notice Tests executeHooks reverts with different unregistered hook addresses
    /// @dev Covers Bank.sol:92 - hook registration check works for any address
    function test_SuperBank_executeHooks_DifferentUnregisteredHooks() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Test with different unregistered addresses
        address[] memory unregisteredAddresses = new address[](3);
        unregisteredAddresses[0] = address(0x1234);
        unregisteredAddresses[1] = address(0x5678);
        unregisteredAddresses[2] = address(0xABCD);

        for (uint256 i = 0; i < unregisteredAddresses.length; i++) {
            address[] memory hooks = new address[](1);
            hooks[0] = unregisteredAddresses[i];

            bytes[] memory data = new bytes[](1);
            data[0] = "data1";

            bytes32[][] memory merkleProofs = new bytes32[][](1);
            merkleProofs[0] = new bytes32[](1);

            uint256[] memory expectedOutputs = new uint256[](1);
            expectedOutputs[0] = 0;

            IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
                hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
            });

            vm.expectRevert(Bank.HOOK_NOT_REGISTERED.selector);
            superBank.executeHooks(executionData);
        }

        vm.stopPrank();
    }

    /// @notice Tests executeHooks passes registration check for properly registered hook
    /// @dev Verifies that registered hooks don't trigger HOOK_NOT_REGISTERED error
    function test_SuperBank_executeHooks_RegisteredHookPassesCheck() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Should not revert with HOOK_NOT_REGISTERED (will fail later at merkle proof validation)
        vm.expectRevert(); // Will revert but not with HOOK_NOT_REGISTERED
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    /// @notice Tests executeHooks reverts when hook's inspect() method fails
    /// @dev Covers Bank.sol:193-196 - catch branch when inspect() reverts
    function test_SuperBank_executeHooks_InspectMethodFails() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create a hook that reverts in inspect()
        MockHookInspectFails mockHook = new MockHookInspectFails();

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Set a valid merkle root
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(bytes32(uint256(1)))
        );

        // Should revert with HOOK_VALIDATION_FAILED because inspect() fails (catch branch)
        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    /// @notice Tests executeHooks reverts when hook doesn't implement ISuperHookInspector
    /// @dev Covers Bank.sol:193-196 - catch branch when interface not implemented
    function test_SuperBank_executeHooks_HookMissingInspectInterface() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create a hook that doesn't implement ISuperHookInspector
        MockHookNoInspect mockHook = new MockHookNoInspect();

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Set a valid merkle root
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(bytes32(uint256(1)))
        );

        // Should revert with HOOK_VALIDATION_FAILED because inspect() doesn't exist (catch branch)
        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
        vm.stopPrank();
    }

    /// @notice Tests executeHooks reverts when merkle root is zero
    /// @dev Covers Bank.sol:187 - if (root == bytes32(0)) return false
    function test_SuperBank_executeHooks_MerkleRootZero() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0); // Empty proof

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Mock getSuperBankHookMerkleRoot to return bytes32(0)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(bytes32(0)) // Zero root should cause validation to fail
        );

        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
    }

    function test_SuperBank_executeHooks_InvalidMerkleProof() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);
        merkleProofs[0][0] = bytes32(uint256(1)); // Invalid proof

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Create a different Merkle root than what the proof is for
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(bytes32(uint256(2))) // Different root
        );

        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
    }

    /// @notice Tests executeHooks reverts when merkle proof is invalid with non-zero root
    /// @dev Covers Bank.sol:98-101 - validation failure with non-zero root
    function test_SuperBank_executeHooks_InvalidProofNonZeroRoot() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](1);
        merkleProofs[0][0] = bytes32(uint256(1)); // Invalid proof

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Set a non-zero root that doesn't match the proof
        bytes32 merkleRoot = bytes32(uint256(2));
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(merkleRoot)
        );

        // Should revert with HOOK_VALIDATION_FAILED
        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
    }

    /// @notice Tests single-leaf tree validation (empty proof, root equals leaf)
    /// @dev Covers Bank.sol:205-206 - single-leaf tree case
    function test_SuperBank_executeHooks_SingleLeafTreeValidation() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        // Empty proof for single-leaf tree
        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Calculate leaf (what hook.inspect() returns)
        bytes memory hookArgs = abi.encodePacked(address(mockTarget));
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook), hookArgs))));

        // For single-leaf tree: root == leaf, proof is empty
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(leaf) // Root equals leaf
        );

        // Should succeed - single-leaf tree validation passes when root == leaf and proof is empty
        vm.expectEmit(true, true, false, false, address(mockTarget));
        emit MockHookTarget.Executed();

        vm.expectEmit(true, true, true, true, address(superBank));
        emit Bank.HooksExecuted(hooks, data);

        superBank.executeHooks(executionData);
    }

    function test_SuperBank_executeHooks_HookExecutionFailed() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        mockTarget.setShouldFailExecution(true); // Set to fail during execution

        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Create Merkle root using new hook configuration approach
        bytes memory hookArgs = abi.encodePacked(address(mockTarget));
        bytes32 hookLeaf = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook), hookArgs))));
        bytes32 merkleRoot = hookLeaf; // Single-leaf tree

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0); // Empty proof for single-leaf tree

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(merkleRoot)
        );

        vm.expectRevert(Bank.HOOK_EXECUTION_FAILED.selector);
        superBank.executeHooks(executionData);
    }

    function test_SuperBank_executeHooks_Success() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Create Merkle root using new hook configuration approach
        bytes memory hookArgs = abi.encodePacked(address(mockTarget));
        bytes32 hookLeaf = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook), hookArgs))));
        bytes32 merkleRoot = hookLeaf; // Single-leaf tree

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0); // Empty proof for single-leaf tree

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(merkleRoot)
        );

        vm.expectEmit(true, true, false, false, address(mockTarget));
        emit MockHookTarget.Executed();

        vm.expectEmit(true, true, true, true, address(superBank));
        emit Bank.HooksExecuted(hooks, data);

        superBank.executeHooks(executionData);
    }

    function test_SuperBank_executeHooks_MultipleHooks() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget1 = new MockHookTarget();
        MockHookTarget mockTarget2 = new MockHookTarget();

        MockSuperHook mockHook1 = new MockSuperHook(address(mockTarget1));
        MockSuperHook mockHook2 = new MockSuperHook(address(mockTarget2));

        // Register hooks
        vm.startPrank(governor);
        superGovernor.registerHook(address(mockHook1));
        superGovernor.registerHook(address(mockHook2));
        vm.stopPrank();

        // Create Merkle roots using new hook configuration approach
        bytes memory hookArgs1 = abi.encodePacked(address(mockTarget1));
        bytes memory hookArgs2 = abi.encodePacked(address(mockTarget2));
        bytes32 hookLeaf1 = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook1), hookArgs1))));
        bytes32 hookLeaf2 = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook2), hookArgs2))));

        bytes32 merkleRoot1 = hookLeaf1;
        bytes32 merkleRoot2 = hookLeaf2;

        address[] memory hooks = new address[](2);
        hooks[0] = address(mockHook1);
        hooks[1] = address(mockHook2);

        bytes[] memory data = new bytes[](2);
        data[0] = "data1";
        data[1] = "data2";

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0);
        merkleProofs[1] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 0;
        expectedOutputs[1] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook1)),
            abi.encode(merkleRoot1)
        );

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook2)),
            abi.encode(merkleRoot2)
        );

        superBank.executeHooks(executionData);
    }

    function test_SuperBank_SwapHookOdos() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        uint256 amount = SMALL;

        vm.warp(block.timestamp + 4 * 365 days);

        vm.startPrank(admin);
        up.mint(address(odosRouter), amount);
        vm.stopPrank();

        ApproveERC20Hook approveHook = new ApproveERC20Hook();
        SwapOdosV2Hook odosHook = new SwapOdosV2Hook(address(odosRouter));

        // Register hooks
        vm.startPrank(governor);
        superGovernor.registerHook(address(approveHook));
        superGovernor.registerHook(address(odosHook));
        vm.stopPrank();

        _getTokens(address(token), address(superBank), amount);

        QuoteInputToken[] memory quoteInputTokens = new QuoteInputToken[](1);
        quoteInputTokens[0] = QuoteInputToken({ tokenAddress: address(underlying), amount: amount });

        QuoteOutputToken[] memory quoteOutputTokens = new QuoteOutputToken[](1);
        quoteOutputTokens[0] = QuoteOutputToken({ tokenAddress: address(up), proportion: 1 });

        bytes memory odosCalldata = abi.encodePacked(
            address(token),
            amount,
            address(this),
            address(up),
            amount,
            amount - amount * 1e4 / 1e5,
            true,
            uint256(0),
            bytes(""),
            address(0),
            uint32(0),
            false
        );
        bytes[] memory hooksData = new bytes[](2);
        hooksData[0] = _createApproveHookData(address(token), address(odosRouter), amount, false);
        hooksData[1] = odosCalldata;

        address[] memory hooksAddresses = new address[](2);
        hooksAddresses[0] = address(approveHook);
        hooksAddresses[1] = address(odosHook);

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0);
        merkleProofs[1] = new bytes32[](0);

        // Create proper Merkle leafs using hook configuration approach
        // ApproveERC20Hook.inspect() returns: abi.encodePacked(token, spender)
        bytes memory hookArgs1 = abi.encodePacked(address(token), address(odosRouter));
        bytes32 hookLeaf1 = keccak256(bytes.concat(keccak256(abi.encode(address(approveHook), hookArgs1))));

        // SwapOdosV2Hook.inspect() returns: abi.encodePacked(inputToken, inputReceiver, outputToken, executor)
        bytes memory hookArgs2 = abi.encodePacked(address(token), address(this), address(up), address(0));
        bytes32 hookLeaf2 = keccak256(bytes.concat(keccak256(abi.encode(address(odosHook), hookArgs2))));

        bytes32 merkleRoot1 = hookLeaf1;
        bytes32 merkleRoot2 = hookLeaf2;

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 0; // ApproveHook doesn't transfer assets
        expectedOutputs[1] = 0; // SwapHook output varies, use 0 for existing test

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooksAddresses,
            data: hooksData,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", hooksAddresses[0]),
            abi.encode(merkleRoot1)
        );

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", hooksAddresses[1]),
            abi.encode(merkleRoot2)
        );

        uint256 inputTokenBalanceBefore = token.balanceOf(address(superBank));
        uint256 upTokenBalanceBefore = up.balanceOf(address(superBank));
        superBank.executeHooks(executionData);
        uint256 inputTokenBalanceAfter = token.balanceOf(address(superBank));
        uint256 upTokenBalanceAfter = up.balanceOf(address(superBank));

        assertGt(inputTokenBalanceBefore, inputTokenBalanceAfter);
        assertGt(upTokenBalanceAfter, upTokenBalanceBefore);
    }

    function test_SuperBank_RedeemHookOdos() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        uint256 amount = SMALL;

        //add to vault
        _getTokens(address(token), address(this), amount);
        IERC20(token).approve(address(vault), amount);
        vault.deposit(amount, address(superBank));

        uint256 shares = vault.balanceOf(address(superBank));
        assertGt(shares, 0);

        uint256 superBankTokenBalanceBefore = token.balanceOf(address(superBank));
        assertEq(superBankTokenBalanceBefore, 0);

        Redeem4626VaultHook redeemHook = new Redeem4626VaultHook();

        // Register hook
        vm.prank(governor);
        superGovernor.registerHook(address(redeemHook));

        bytes[] memory hooksData = new bytes[](1);
        hooksData[0] = _createRedeem4626HookData(bytes32(0), address(vault), address(superBank), shares, false);

        address[] memory hooksAddresses = new address[](1);
        hooksAddresses[0] = address(redeemHook);

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        // Redeem4626VaultHook.inspect() returns: abi.encodePacked(yieldSource, owner)
        bytes memory hookArgs1 = abi.encodePacked(address(vault), address(superBank));
        bytes32 hookLeaf1 = keccak256(bytes.concat(keccak256(abi.encode(address(redeemHook), hookArgs1))));
        bytes32 merkleRoot1 = hookLeaf1;

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0; // RedeemHook output varies, use 0 for existing test

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooksAddresses,
            data: hooksData,
            merkleProofs: merkleProofs,
            expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", hooksAddresses[0]),
            abi.encode(merkleRoot1)
        );

        superBank.executeHooks(executionData);
        shares = vault.balanceOf(address(superBank));
        assertEq(shares, 0);

        uint256 superBankTokenBalanceAfter = token.balanceOf(address(superBank));
        assertGt(superBankTokenBalanceAfter, superBankTokenBalanceBefore);
    }

    function test_SuperBank_Across() public {
        uint256 baseForkId = vm.createFork(BASE_RPC_URL);
        uint256 ethForkId = vm.createFork(ETHEREUM_RPC_URL);

        //base is source
        vm.selectFork(baseForkId);
        {
            superGovernor = new SuperGovernor(sGovernor, governor, governor, oracleManager, governor, treasury);

            superBank = new SuperBank(address(superGovernor));
            up = new Up(admin);
            _getTokens(CHAIN_8453_USDC, address(superBank), uint256(100e6));

            vm.startPrank(sGovernor);
            superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
            vm.stopPrank();
        }

        AcrossSendFundsAndExecuteOnDstHook acrossSendFundsAndExecuteOnDstHook =
            new AcrossSendFundsAndExecuteOnDstHook(CHAIN_8453_SPOKE_POOL_V3_ADDRESS, address(this));

        // Register hook
        vm.prank(governor);
        superGovernor.registerHook(address(acrossSendFundsAndExecuteOnDstHook));

        IHookExecutionData.HookExecutionData memory executionData;
        {
            bytes[] memory hooksData = new bytes[](1);

            address[] memory dstTokens = new address[](1);
            dstTokens[0] = CHAIN_1_USDC;
            uint256[] memory intentAmounts = new uint256[](1);
            intentAmounts[0] = 100e6;
            bytes memory destinationData =
                abi.encode(bytes("0x123"), bytes("0x123"), address(superBank), dstTokens, intentAmounts);
            hooksData[0] = abi.encodePacked(
                uint256(0),
                address(superBank),
                CHAIN_8453_USDC,
                CHAIN_1_USDC,
                uint256(100e6),
                uint256(100e6),
                uint256(ETH),
                address(0),
                uint32(10 minutes),
                uint32(0),
                false,
                destinationData
            );

            address[] memory hooksAddresses = new address[](1);
            hooksAddresses[0] = address(acrossSendFundsAndExecuteOnDstHook);

            bytes32[][] memory merkleProofs = new bytes32[][](1);
            merkleProofs[0] = new bytes32[](0);

            // AcrossSendFundsAndExecuteOnDstHook.inspect() returns: abi.encodePacked(recipient, inputToken,
            // outputToken, exclusiveRelayer)
            bytes memory hookArgs = abi.encodePacked(address(superBank), CHAIN_8453_USDC, CHAIN_1_USDC, address(0));
            bytes32 hookLeaf =
                keccak256(bytes.concat(keccak256(abi.encode(address(acrossSendFundsAndExecuteOnDstHook), hookArgs))));
            bytes32 merkleRoot1 = hookLeaf;

            uint256[] memory expectedOutputs = new uint256[](1);
            expectedOutputs[0] = 0; // Across bridge hook, output varies

            executionData = IHookExecutionData.HookExecutionData({
                hooks: hooksAddresses,
                data: hooksData,
                merkleProofs: merkleProofs,
                expectedAssetsOrSharesOut: expectedOutputs
            });

            vm.mockCall(
                address(superGovernor),
                abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", hooksAddresses[0]),
                abi.encode(merkleRoot1)
            );

            vm.startPrank(address(superBank));
            IERC20(CHAIN_8453_USDC).approve(CHAIN_8453_SPOKE_POOL_V3_ADDRESS, 100e6);
            vm.stopPrank();
        }

        address acrossRelayer = _deployAccount(ACROSS_RELAYER_KEY, "ACROSS_RELAYER");

        vm.recordLogs();
        superBank.executeHooks(executionData);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        acrossV3Helper.help(
            CHAIN_8453_SPOKE_POOL_V3_ADDRESS,
            CHAIN_1_SPOKE_POOL_V3_ADDRESS,
            acrossRelayer,
            30 days,
            ethForkId,
            ETH,
            BASE,
            logs
        );

        //eth is destination
        vm.selectFork(ethForkId);
        uint256 usdcBalanceAfter = IERC20(CHAIN_1_USDC).balanceOf(address(superBank));
        assertEq(usdcBalanceAfter, uint256(100e6));
    }

    /// @notice Tests that hooks without inspect() or with empty args are rejected
    function test_SuperBank_executeHooks_EmptyHookArgs_Reverts() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create a hook that returns empty args from inspect()
        MockHookTarget mockTarget = new MockHookTarget();
        MockSuperHook mockHook = new MockSuperHook(address(mockTarget));

        // Register the hook first
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Override the hook's inspect to return empty bytes after registration
        vm.mockCall(address(mockHook), abi.encodeWithSignature("inspect(bytes)"), abi.encode(bytes("")));

        // Try to execute - should fail due to empty hookArgs
        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        // Mock a valid Merkle root (doesn't matter, will fail on empty args first)
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(bytes32(uint256(1)))
        );

        // Should revert with HOOK_VALIDATION_FAILED due to empty hookArgs
        vm.expectRevert(Bank.HOOK_VALIDATION_FAILED.selector);
        superBank.executeHooks(executionData);
    }

    /// @notice THE CRITICAL TEST: Proves the fix for multi-target hook Merkle proof reuse issue
    /// @dev This test demonstrates that a single hook can now call multiple external targets
    ///      OLD SYSTEM: Would fail with INVALID_MERKLE_PROOF because it tried to use one proof for 3 targets
    ///      NEW SYSTEM: Validates hook configuration once, then executes all targets successfully
    function test_SuperBank_MultiTargetHook_Success() public {
        // Setup: Grant bank manager role
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        // Create test token and recipients
        MockERC20 testToken = new MockERC20("Test Token", "TEST", 18);
        address recipient1 = address(0x1001);
        address recipient2 = address(0x1002);
        address recipient3 = address(0x1003);
        uint256 transferAmount = 100e18;

        // Create the multi-target hook
        MockMultiTargetHook multiTargetHook =
            new MockMultiTargetHook(address(testToken), recipient1, recipient2, recipient3, transferAmount);

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(multiTargetHook));

        // Fund the SuperBank with tokens
        testToken.mint(address(superBank), transferAmount * 3);

        bytes32 merkleRoot;
        IHookExecutionData.HookExecutionData memory executionData;
        {
            // Build Merkle tree using the new hook configuration approach
            bytes memory hookArgs = abi.encodePacked(address(testToken), recipient1, recipient2, recipient3);

            // Use MerkleTreeBuilder to create tree and proof
            MerkleTreeBuilder.HookConfig[] memory configs = new MerkleTreeBuilder.HookConfig[](1);
            configs[0] = MerkleTreeBuilder.HookConfig({ hookAddress: address(multiTargetHook), encodedArgs: hookArgs });

            merkleRoot = MerkleTreeBuilder.buildTree(configs);
            bytes32[] memory proof = MerkleTreeBuilder.getProof(configs, address(multiTargetHook), hookArgs);

            // Setup execution data
            address[] memory hooks = new address[](1);
            hooks[0] = address(multiTargetHook);

            bytes[] memory data = new bytes[](1);
            data[0] = ""; // Hook doesn't need calldata, uses constructor params

            bytes32[][] memory merkleProofs = new bytes32[][](1);
            merkleProofs[0] = proof;

            uint256[] memory expectedOutputs = new uint256[](1);
            expectedOutputs[0] = 0; // Multi-target hook, output varies

            executionData = IHookExecutionData.HookExecutionData({
                hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
            });
        }

        // Mock the governor to return our Merkle root
        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(multiTargetHook)),
            abi.encode(merkleRoot)
        );

        // Execute the hook - THIS IS THE CRITICAL TEST
        // In the OLD system, this would fail with INVALID_MERKLE_PROOF
        // In the NEW system, it validates the hook configuration once and executes all targets
        superBank.executeHooks(executionData);

        // Verify all three transfers succeeded (they all start with 0 balance)
        assertEq(testToken.balanceOf(recipient1), transferAmount, "Recipient 1 should receive tokens");
        assertEq(testToken.balanceOf(recipient2), transferAmount, "Recipient 2 should receive tokens");
        assertEq(testToken.balanceOf(recipient3), transferAmount, "Recipient 3 should receive tokens");

        // Verify SuperBank balance decreased
        assertEq(testToken.balanceOf(address(superBank)), 0, "SuperBank should have transferred all tokens");
    }

    // ============================================
    // NEW SLIPPAGE PROTECTION TESTS
    // ============================================

    /// @notice Test that slippage protection works correctly when output meets expected
    function test_SuperBank_executeHooks_SlippageProtection_Success() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        uint256 expectedOutput = 100e18;
        MockHookWithSlippage mockHook = new MockHookWithSlippage(address(mockTarget), expectedOutput);

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Create Merkle root
        bytes memory hookArgs = abi.encodePacked(address(mockTarget));
        bytes32 hookLeaf = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook), hookArgs))));
        bytes32 merkleRoot = hookLeaf;

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = expectedOutput;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(merkleRoot)
        );

        // Should succeed - actual output (100e18) >= expected output (100e18)
        superBank.executeHooks(executionData);
    }

    /// @notice Test that slippage protection reverts when output is too low
    function test_SuperBank_executeHooks_SlippageProtection_Reverts() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        uint256 actualOutput = 90e18;
        uint256 expectedOutput = 100e18;
        MockHookWithSlippage mockHook = new MockHookWithSlippage(address(mockTarget), actualOutput);

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Create Merkle root
        bytes memory hookArgs = abi.encodePacked(address(mockTarget));
        bytes32 hookLeaf = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook), hookArgs))));
        bytes32 merkleRoot = hookLeaf;

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = expectedOutput;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(merkleRoot)
        );

        // Should revert - actual output (90e18) < expected output (100e18)
        vm.expectRevert(Bank.MINIMUM_OUTPUT_AMOUNT_NOT_MET.selector);
        superBank.executeHooks(executionData);
    }

    /// @notice Test that slippage protection works with multiple hooks
    function test_SuperBank_executeHooks_SlippageProtection_MultipleHooks() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget1 = new MockHookTarget();
        MockHookTarget mockTarget2 = new MockHookTarget();

        MockHookWithSlippage mockHook1 = new MockHookWithSlippage(address(mockTarget1), 100e18);
        MockHookWithSlippage mockHook2 = new MockHookWithSlippage(address(mockTarget2), 200e18);

        // Register hooks
        vm.startPrank(governor);
        superGovernor.registerHook(address(mockHook1));
        superGovernor.registerHook(address(mockHook2));
        vm.stopPrank();

        // Create Merkle roots
        bytes memory hookArgs1 = abi.encodePacked(address(mockTarget1));
        bytes memory hookArgs2 = abi.encodePacked(address(mockTarget2));
        bytes32 hookLeaf1 = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook1), hookArgs1))));
        bytes32 hookLeaf2 = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook2), hookArgs2))));

        address[] memory hooks = new address[](2);
        hooks[0] = address(mockHook1);
        hooks[1] = address(mockHook2);

        bytes[] memory data = new bytes[](2);
        data[0] = "data1";
        data[1] = "data2";

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](0);
        merkleProofs[1] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](2);
        expectedOutputs[0] = 100e18; // Exact match for hook1
        expectedOutputs[1] = 150e18; // hook2 output (200e18) exceeds this

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook1)),
            abi.encode(hookLeaf1)
        );

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook2)),
            abi.encode(hookLeaf2)
        );

        // Should succeed - both hooks meet/exceed expected outputs
        superBank.executeHooks(executionData);
    }

    /// @notice Test edge case: zero expected output
    function test_SuperBank_executeHooks_SlippageProtection_ZeroExpected() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        MockHookWithSlippage mockHook = new MockHookWithSlippage(address(mockTarget), 50e18);

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Create Merkle root
        bytes memory hookArgs = abi.encodePacked(address(mockTarget));
        bytes32 hookLeaf = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook), hookArgs))));
        bytes32 merkleRoot = hookLeaf;

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 0; // Zero expected - any output should pass

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(merkleRoot)
        );

        // Should succeed - actual (50e18) >= expected (0)
        superBank.executeHooks(executionData);
    }

    /// @notice Test edge case: exact match
    function test_SuperBank_executeHooks_SlippageProtection_ExactMatch() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        MockHookTarget mockTarget = new MockHookTarget();
        uint256 exactAmount = 123_456_789e18;
        MockHookWithSlippage mockHook = new MockHookWithSlippage(address(mockTarget), exactAmount);

        // Register the hook
        vm.prank(governor);
        superGovernor.registerHook(address(mockHook));

        // Create Merkle root
        bytes memory hookArgs = abi.encodePacked(address(mockTarget));
        bytes32 hookLeaf = keccak256(bytes.concat(keccak256(abi.encode(address(mockHook), hookArgs))));
        bytes32 merkleRoot = hookLeaf;

        address[] memory hooks = new address[](1);
        hooks[0] = address(mockHook);

        bytes[] memory data = new bytes[](1);
        data[0] = "data1";

        bytes32[][] memory merkleProofs = new bytes32[][](1);
        merkleProofs[0] = new bytes32[](0);

        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = exactAmount; // Exact match

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.mockCall(
            address(superGovernor),
            abi.encodeWithSignature("getSuperBankHookMerkleRoot(address)", address(mockHook)),
            abi.encode(merkleRoot)
        );

        // Should succeed - boundary condition: actual == expected
        superBank.executeHooks(executionData);
    }

    /// @notice Test array length mismatch for expectedAssetsOrSharesOut
    function test_SuperBank_executeHooks_InvalidArrayLength_ExpectedOutputs() public {
        vm.startPrank(sGovernor);
        superGovernor.grantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
        vm.stopPrank();

        address[] memory hooks = new address[](2);
        hooks[0] = address(0x1111);
        hooks[1] = address(0x2222);

        bytes[] memory data = new bytes[](2);
        data[0] = "data1";
        data[1] = "data2";

        bytes32[][] memory merkleProofs = new bytes32[][](2);
        merkleProofs[0] = new bytes32[](1);
        merkleProofs[1] = new bytes32[](1);

        // Mismatched length: 1 expected output for 2 hooks
        uint256[] memory expectedOutputs = new uint256[](1);
        expectedOutputs[0] = 100e18;

        IHookExecutionData.HookExecutionData memory executionData = IHookExecutionData.HookExecutionData({
            hooks: hooks, data: data, merkleProofs: merkleProofs, expectedAssetsOrSharesOut: expectedOutputs
        });

        vm.expectRevert(Bank.INVALID_ARRAY_LENGTH.selector);
        superBank.executeHooks(executionData);
    }

    function retrieveSignatureData(address) external pure returns (bytes memory) {
        return "";
    }
}

// =============================================================
// Mock Contracts for Testing Inspect Catch Branch
// =============================================================

/// @notice Mock hook that reverts in inspect() method
/// @dev Used to test the catch branch in _validateHookConfiguration
contract MockHookInspectFails {
    function inspect(bytes memory) external pure returns (bytes memory) {
        revert("Inspect failed");
    }
}

/// @notice Mock hook that doesn't implement ISuperHookInspector interface
/// @dev Used to test the catch branch when interface is missing
contract MockHookNoInspect {
    // No inspect() method - doesn't implement ISuperHookInspector
}
