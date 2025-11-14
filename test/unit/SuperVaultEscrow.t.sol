// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { ISuperVaultEscrow } from "../../src/interfaces/SuperVault/ISuperVaultEscrow.sol";
import { PeripheryHelpers } from "../utils/PeripheryHelpers.sol";

import "forge-std/console2.sol";

contract SuperVaultEscrowTest is PeripheryHelpers {
    SuperVaultEscrow internal escrow;

    // Test addresses
    address internal vault;
    address internal user;

    /// @notice Sets up the test environment before each test case.
    function setUp() public {
        // Deploy test accounts
        vault = _deployAccount(0x1, "Vault");
        user = _deployAccount(0x2, "User");

        // Deploy escrow
        escrow = new SuperVaultEscrow();
    }

    /*//////////////////////////////////////////////////////////////
                        INITIALIZE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that initialize reverts when called with zero address
    function test_Initialize_RevertZeroAddress() public {
        vm.expectRevert(ISuperVaultEscrow.ZERO_ADDRESS.selector);
        escrow.initialize(address(0));
    }

    /// @notice Tests that initialize reverts when already initialized
    function test_Initialize_RevertAlreadyInitialized() public {
        // Initialize the first time - should succeed
        escrow.initialize(vault);

        // Try to initialize again - should revert
        vm.expectRevert(ISuperVaultEscrow.ALREADY_INITIALIZED.selector);
        escrow.initialize(vault);
    }

    /// @notice Tests successful initialization
    function test_Initialize_Success() public {
        // Verify not initialized initially
        assertFalse(escrow.initialized(), "Should not be initialized initially");
        assertEq(escrow.vault(), address(0), "Vault should be zero initially");

        // Initialize
        vm.expectEmit(true, true, true, true);
        emit ISuperVaultEscrow.Initialized(vault);
        escrow.initialize(vault);

        // Verify state after initialization
        assertTrue(escrow.initialized(), "Should be initialized");
        assertEq(escrow.vault(), vault, "Vault should be set");
    }

    /*//////////////////////////////////////////////////////////////
                        ESCROW SHARES TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that escrowShares reverts when caller is not vault
    function test_EscrowShares_RevertUnauthorized() public {
        // Initialize escrow
        escrow.initialize(vault);

        // Try to call escrowShares from non-vault address
        vm.prank(user);
        vm.expectRevert(ISuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.escrowShares(user, 100);
    }

    /// @notice Tests that escrowShares reverts when amount is zero
    function test_EscrowShares_RevertZeroAmount() public {
        // Initialize escrow
        escrow.initialize(vault);

        // Try to escrow zero amount
        vm.prank(vault);
        vm.expectRevert(ISuperVaultEscrow.ZERO_AMOUNT.selector);
        escrow.escrowShares(user, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        RETURN SHARES TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that returnShares reverts when caller is not vault
    function test_ReturnShares_RevertUnauthorized() public {
        // Initialize escrow
        escrow.initialize(vault);

        // Try to call returnShares from non-vault address
        vm.prank(user);
        vm.expectRevert(ISuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.returnShares(user, 100);
    }

    /// @notice Tests that returnShares reverts when amount is zero
    function test_ReturnShares_RevertZeroAmount() public {
        // Initialize escrow
        escrow.initialize(vault);

        // Try to return zero amount
        vm.prank(vault);
        vm.expectRevert(ISuperVaultEscrow.ZERO_AMOUNT.selector);
        escrow.returnShares(user, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        RETURN ASSETS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Tests that returnAssets reverts when caller is not vault
    function test_ReturnAssets_RevertUnauthorized() public {
        // Initialize escrow
        escrow.initialize(vault);

        // Try to call returnAssets from non-vault address
        vm.prank(user);
        vm.expectRevert(ISuperVaultEscrow.UNAUTHORIZED.selector);
        escrow.returnAssets(user, 100);
    }

    /// @notice Tests that returnAssets reverts when amount is zero
    function test_ReturnAssets_RevertZeroAmount() public {
        // Initialize escrow
        escrow.initialize(vault);

        // Try to return zero amount
        vm.prank(vault);
        vm.expectRevert(ISuperVaultEscrow.ZERO_AMOUNT.selector);
        escrow.returnAssets(user, 0);
    }

    /// @notice Tests that returnAssets reverts when to address is zero
    function test_ReturnAssets_RevertZeroAddress() public {
        // Initialize escrow
        escrow.initialize(vault);

        // Try to return assets to zero address
        vm.prank(vault);
        vm.expectRevert(ISuperVaultEscrow.ZERO_ADDRESS.selector);
        escrow.returnAssets(address(0), 100);
    }
}
