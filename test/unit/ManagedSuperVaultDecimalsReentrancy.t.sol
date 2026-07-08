// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultController } from "../../src/ManagedSuperVault/ManagedSuperVaultController.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { IManagedSuperVaultController } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultController.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @notice Malicious call target that tries to reenter the managed vault system mid-execution.
contract ReentrantTarget {
    address public vault;
    address public controller;
    bytes public payload;
    bool public attackVault;

    function arm(address vault_, address controller_, bytes calldata payload_, bool attackVault_) external {
        vault = vault_;
        controller = controller_;
        payload = payload_;
        attackVault = attackVault_;
    }

    // Called by controller.executeManagedCall; reenter the guarded entrypoint.
    fallback() external payable {
        (bool ok,) = (attackVault ? vault : controller).call(payload);
        // Bubble a revert so the outer executeManagedCall sees the reentry was rejected
        require(ok, "REENTRY_BLOCKED");
    }

    receive() external payable { }
}

contract ManagedSuperVaultDecimalsReentrancyTest is ManagedSuperVaultTestBase {
    /*//////////////////////////////////////////////////////////////
                        6-DECIMAL (USDC-LIKE) ASSET
    //////////////////////////////////////////////////////////////*/

    MockERC20 internal usdc;
    ManagedSuperVault internal usdcVault;
    ManagedSuperVaultController internal usdcController;

    function _createUsdcVault() internal {
        usdc = new MockERC20("USD Coin", "USDC", 6);
        usdc.mint(user, 1_000_000e6);
        IManagedSuperVaultAggregator.ManagedVaultCreationParams memory params = _defaultParams();
        params.asset = address(usdc);
        (address vault_, address controller_,) = _createManagedVault(params);
        usdcVault = ManagedSuperVault(vault_);
        usdcController = ManagedSuperVaultController(payable(controller_));
    }

    function test_sixDecimalAsset_depositNavRedeemRoundTrip() public {
        _createUsdcVault();
        ManagedSuperVault v = usdcVault;
        ManagedSuperVaultController c = usdcController;

        // PRECISION and initial PPS track asset decimals (1e6 == 1.0)
        assertEq(c.PRECISION(), 1e6);
        assertEq(aggregator.getPPS(address(c)), 1e6);
        assertEq(v.decimals(), 6);

        // Deposit 100 USDC at PPS 1.0 -> 100 shares
        vm.startPrank(user);
        usdc.approve(address(v), 100e6);
        v.requestDeposit(100e6, user, user);
        vm.stopPrank();

        uint256 shares = _fulfillAndClaimUsdc();
        assertEq(shares, 100e6);

        // NAV appreciates to 1.05 (6-decimal scale); the +5 USDC offchain gain is returned to custody
        _updateUsdcNav(1.05e6);
        assertEq(c.getStoredPPS(), 1.05e6);
        usdc.mint(address(c), 5e6);

        // Redeem all shares -> 105 USDC at PPS 1.05
        assertEq(_redeemAllUsdc(shares), 105e6);
    }

    function _fulfillAndClaimUsdc() internal returns (uint256 shares) {
        address[] memory depositors = new address[](1);
        depositors[0] = user;
        vm.prank(manager);
        usdcController.fulfillDepositRequests(depositors);
        uint256 claimable = usdcController.claimableDepositRequest(user);
        vm.prank(user);
        shares = usdcVault.deposit(claimable, user, user);
    }

    function _updateUsdcNav(uint256 newPPS) internal {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.prank(manager);
        uint256 pid = aggregator.proposeNAVUpdate(address(usdcController), newPPS, block.timestamp, EVIDENCE_HASH, "");
        vm.prank(attestor);
        aggregator.attestNAVUpdate(address(usdcController), pid);
    }

    function _redeemAllUsdc(uint256 shares) internal returns (uint256 received) {
        vm.prank(user);
        usdcVault.requestRedeem(shares, user, user);
        (, uint256 theoretical,) = usdcController.previewExactRedeem(user);
        address[] memory redeemers = new address[](1);
        redeemers[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = theoretical;
        vm.prank(manager);
        usdcController.fulfillRedeemRequests(redeemers, amounts);
        uint256 before = usdc.balanceOf(user);
        uint256 claimableAssets = usdcVault.maxWithdraw(user);
        vm.prank(user);
        usdcVault.withdraw(claimableAssets, user, user);
        received = usdc.balanceOf(user) - before;
    }

    /*//////////////////////////////////////////////////////////////
                            REENTRANCY
    //////////////////////////////////////////////////////////////*/

    function test_executeManagedCall_reentrancyBlocked() public {
        // Fund the controller with operational assets
        _depositRoundTrip(user, 100e18);

        ReentrantTarget target = new ReentrantTarget();

        // Allow calls to the malicious target for the selector the outer call uses (no value)
        IManagedSuperVaultController.CallRule memory rule;
        rule.allowed = true;
        vm.prank(manager);
        controller.setCallRule(address(target), bytes4(0xdeadbeef), rule);

        // Arm the target to reenter controller.executeManagedCall mid-execution
        IManagedSuperVaultController.ManagedCall memory innerCall =
            IManagedSuperVaultController.ManagedCall({ target: address(target), value: 0, data: "" });
        bytes memory reenterController =
            abi.encodeCall(controller.executeManagedCall, (innerCall, keccak256("reenter")));
        target.arm(address(vault), address(controller), reenterController, false);

        IManagedSuperVaultController.ManagedCall memory outerCall =
            IManagedSuperVaultController.ManagedCall({ target: address(target), value: 0, data: hex"deadbeef" });

        // The nonReentrant guard rejects the reentry; the outer call surfaces EXECUTION_FAILED
        vm.expectPartialRevert(IManagedSuperVaultController.EXECUTION_FAILED.selector);
        vm.prank(manager);
        controller.executeManagedCall(outerCall, keccak256("outer"));

        // Same holds when the target tries to reenter the vault (requestDeposit)
        bytes memory reenterVault =
            abi.encodeCall(vault.requestDeposit, (1e18, address(controller), address(controller)));
        target.arm(address(vault), address(controller), reenterVault, true);
        vm.expectPartialRevert(IManagedSuperVaultController.EXECUTION_FAILED.selector);
        vm.prank(manager);
        controller.executeManagedCall(outerCall, keccak256("outer-2"));
    }
}
