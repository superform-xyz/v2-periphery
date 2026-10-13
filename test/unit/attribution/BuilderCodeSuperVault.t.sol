// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { SuperVault } from "../../../src/SuperVault/SuperVault.sol";
import { SuperVaultStrategy } from "../../../src/SuperVault/SuperVaultStrategy.sol";
import { SuperVaultEscrow } from "../../../src/SuperVault/SuperVaultEscrow.sol";
import { SuperVaultAggregator } from "../../../src/SuperVault/SuperVaultAggregator.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { MockERC20 } from "../../mocks/MockERC20.sol";
import { MockSuperOracle } from "../../mocks/MockSuperOracle.sol";
import { BuilderCodeFixtures } from "../../utils/BuilderCodeFixtures.sol";

/// @notice Real periphery vault/strategy/escrow/governance contracts; only asset/oracle are mocks.
/// @dev Native periphery coverage; run alongside the builder-code registry tests.
contract BuilderCodeSuperVaultCompatibilityTest is Test {
    SuperVault internal vault;
    SuperVaultStrategy internal strategy;
    MockERC20 internal asset;
    address internal user = makeAddr("user");
    address internal manager = makeAddr("manager");
    uint256 internal constant ASSETS = 1000 ether;

    function setUp() public {
        asset = new MockERC20("Asset", "ASSET", 18);
        SuperGovernor governor = new SuperGovernor(
            address(this),
            address(this),
            address(this),
            address(this),
            address(this),
            address(this),
            makeAddr("treasury"),
            false
        );
        SuperVaultAggregator aggregator = new SuperVaultAggregator(
            address(governor),
            address(new SuperVault(address(governor))),
            address(new SuperVaultStrategy(address(governor))),
            address(new SuperVaultEscrow())
        );
        governor.setAddress(governor.UP(), address(asset));
        governor.setAddress(governor.UPKEEP_TOKEN(), address(asset));
        governor.setAddress(governor.SUPER_BANK(), makeAddr("superBank"));
        governor.setAddress(governor.SUPER_ORACLE(), address(new MockSuperOracle(1e18)));
        governor.setAddress(governor.SUPER_VAULT_AGGREGATOR(), address(aggregator));
        vm.prank(manager);
        (address vaultAddress, address strategyAddress,) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: address(asset),
                name: "Builder Code Vault",
                symbol: "BCV",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 5,
                maxStaleness: 300,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 0, managementFeeBps: 0, recipient: manager
                })
            })
        );
        vault = SuperVault(vaultAddress);
        strategy = SuperVaultStrategy(payable(strategyAddress));
        asset.mint(user, ASSETS);
        vm.prank(user);
        asset.approve(address(vault), ASSETS);
    }

    function test_DepositSuffixPreservesResultsBalancesAndEvents() public {
        _compare(true, false, false);
    }

    function test_RequestSuffixPreservesResultsBalancesAndEvents() public {
        _compare(false, true, false);
    }

    function test_ClaimSuffixPreservesResultsBalancesAndEvents() public {
        _compare(false, false, true);
    }

    function test_AllThreeActionsWithSuffixPreserveResultsBalancesAndEvents() public {
        _compare(true, true, true);
    }

    function _compare(bool depositCode, bool requestCode, bool claimCode) internal {
        uint256 snapshot = vm.snapshotState();
        bytes32 baseline = _lifecycle(false, false, false);
        assertTrue(vm.revertToStateAndDelete(snapshot));
        assertEq(_lifecycle(depositCode, requestCode, claimCode), baseline);
    }

    function _lifecycle(bool depositCode, bool requestCode, bool claimCode) internal returns (bytes32) {
        vm.recordLogs();
        uint256 shares = _call(abi.encodeWithSignature("deposit(uint256,address)", ASSETS, user), depositCode);
        assertGt(shares, 0);
        assertEq(vault.balanceOf(user), shares);
        uint256 request =
            _call(abi.encodeWithSignature("requestRedeem(uint256,address,address)", shares, user, user), requestCode);
        assertEq(vault.pendingRedeemRequest(request, user), shares);
        address[] memory controllers = new address[](1);
        controllers[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = ASSETS;
        vm.prank(manager);
        strategy.fulfillRedeemRequests(controllers, amounts);
        uint256 claimable = vault.maxRedeem(user);
        assertEq(claimable, shares);
        uint256 received =
            _call(abi.encodeWithSignature("redeem(uint256,address,address)", claimable, user, user), claimCode);
        assertEq(received, ASSETS);
        assertEq(asset.balanceOf(user), ASSETS);
        assertEq(vault.balanceOf(user), 0);
        assertEq(vault.pendingRedeemRequest(request, user), 0);
        assertEq(vault.maxRedeem(user), 0);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        return keccak256(abi.encode(shares, request, received, asset.balanceOf(address(strategy)), logs));
    }

    function _call(bytes memory data, bool coded) internal returns (uint256) {
        if (coded) data = bytes.concat(data, BuilderCodeFixtures.suffix());
        vm.prank(user);
        (bool success, bytes memory result) = address(vault).call(data);
        if (!success) assembly ("memory-safe") { revert(add(result, 32), mload(result)) }
        return abi.decode(result, (uint256));
    }
}
