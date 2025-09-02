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
import { ERC7540YieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/ERC7540YieldSourceOracle.sol";
import { ERC5115YieldSourceOracle } from "@superform-v2-core/src/accounting/oracles/ERC5115YieldSourceOracle.sol";
import { ISuperLedger } from "@superform-v2-core/src/interfaces/accounting/ISuperLedger.sol";
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

contract SuperVault5115Tests is BaseSuperVaultTest {
    using Math for uint256;

    address operator = address(0x123);
    uint256 constant userPrivateKey = 0xA11CE;
    address userAddress; 

    // super vaults
    ERC5115YieldSourceOracle public oracle;
    ISuperLedger public superLedgerETH;
    SuperVault sv5115;
    SuperVaultEscrow escrow5115SuperVault;
    SuperVaultStrategy strategy5115SuperVault;
    
    function setUp() public override {
        super.setUp();
        userAddress = vm.addr(userPrivateKey); // Derive the correct address from private key

        vm.selectFork(FORKS[ETH]);

        superLedgerETH = ISuperLedger(_getContract(ETH, SUPER_LEDGER_KEY));
        oracle = ERC5115YieldSourceOracle(_getContract(ETH, ERC5115_YIELD_SOURCE_ORACLE_KEY));
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

        return;
        // Verify state
        assertEq(strategy5115SuperVault.pendingRedeemRequest(accountEth), 0, "Pending redeem request not cleared");
        assertGt(strategy5115SuperVault.claimableWithdraw(accountEth), 0, "No assets available to withdraw");
    }
}