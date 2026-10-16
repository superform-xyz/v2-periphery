// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { SuperVaultVetoRegistry } from "../../src/SuperVault/SuperVaultVetoRegistry.sol";

contract SuperVaultVetoRegistryTest is Test {
    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);
    address internal constant CAROL = address(0xCA401);

    function _registry(address[] memory guardians) internal returns (SuperVaultVetoRegistry) {
        return new SuperVaultVetoRegistry(guardians);
    }

    function test_singleGuardian() public {
        address[] memory g = new address[](1);
        g[0] = ALICE;
        SuperVaultVetoRegistry registry = _registry(g);

        assertTrue(registry.isGuardian(ALICE));
        assertFalse(registry.isGuardian(BOB));
        assertFalse(registry.isGuardian(address(0)));
        assertEq(registry.getGuardians().length, 1);
        assertEq(registry.getGuardians()[0], ALICE);
    }

    function test_guardianBatch() public {
        address[] memory g = new address[](3);
        g[0] = ALICE;
        g[1] = BOB;
        g[2] = CAROL;
        SuperVaultVetoRegistry registry = _registry(g);

        assertTrue(registry.isGuardian(ALICE));
        assertTrue(registry.isGuardian(BOB));
        assertTrue(registry.isGuardian(CAROL));
        assertFalse(registry.isGuardian(address(0xDEAD)));
        assertEq(registry.getGuardians().length, 3);
    }

    function test_emptyBatchReverts() public {
        address[] memory g = new address[](0);
        vm.expectRevert(SuperVaultVetoRegistry.EMPTY_GUARDIANS.selector);
        new SuperVaultVetoRegistry(g);
    }

    function test_zeroGuardianReverts() public {
        address[] memory g = new address[](2);
        g[0] = ALICE;
        g[1] = address(0);
        vm.expectRevert(SuperVaultVetoRegistry.ZERO_ADDRESS.selector);
        new SuperVaultVetoRegistry(g);
    }

    function test_duplicateGuardianReverts() public {
        address[] memory g = new address[](2);
        g[0] = ALICE;
        g[1] = ALICE;
        vm.expectRevert(abi.encodeWithSelector(SuperVaultVetoRegistry.DUPLICATE_GUARDIAN.selector, ALICE));
        new SuperVaultVetoRegistry(g);
    }

    function testFuzz_membershipIsExact(address probe) public {
        address[] memory g = new address[](2);
        g[0] = ALICE;
        g[1] = BOB;
        SuperVaultVetoRegistry registry = _registry(g);
        assertEq(registry.isGuardian(probe), probe == ALICE || probe == BOB);
    }
}
