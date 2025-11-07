// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";
import { SuperRegistry } from "../../src/SuperRegistry.sol";
import { ISuperRegistry } from "../../src/interfaces/ISuperRegistry.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { BaseTestSuperAsset } from "../utils/BaseTestSuperAsset.sol";

contract SuperRegistryTest is Test, BaseTestSuperAsset {
    // Roles & Addresses
    address internal superRegistryAdmin;
    address internal registryAdmin;
    address internal user;

    // Role Hashes
    bytes32 internal SUPER_REGISTRY_ADMIN_ROLE;
    bytes32 internal REGISTRY_ADMIN_ROLE;

    // Constants
    uint256 internal constant TIMELOCK = 7 days;

    /// @notice Sets up the test environment before each test case.
    function setUp() public {
        superRegistryAdmin = _deployAccount(0x1, "SuperRegistryAdmin");
        registryAdmin = _deployAccount(0x2, "RegistryAdmin");
        user = _deployAccount(0x4, "User");

        // Deploy SuperRegistry with admin addresses
        superRegistry = new SuperRegistry(superRegistryAdmin, registryAdmin, address(this));

        // Get role hashes
        SUPER_REGISTRY_ADMIN_ROLE = superRegistry.SUPER_REGISTRY_ADMIN_ROLE();
        REGISTRY_ADMIN_ROLE = superRegistry.REGISTRY_ADMIN_ROLE();
    }

    // =============================================================
    // Vault Bank Management Tests
    // =============================================================

    /// @notice Tests adding a vault bank address for a specific chain
    function test_VaultBankManagement_AddVaultBank() public {
        uint64 chainId = 1;
        address vaultBank = _deployAccount(0x20, "VaultBank1");

        vm.prank(registryAdmin);
        vm.expectEmit(true, true, false, false);
        emit ISuperRegistry.VaultBankAddressAdded(chainId, vaultBank);
        superRegistry.addVaultBank(chainId, vaultBank);

        assertEq(superRegistry.getVaultBank(chainId), vaultBank, "Vault bank address mismatch");
    }

    /// @notice Tests adding multiple vault banks for different chains
    function test_VaultBankManagement_AddMultipleVaultBanks() public {
        uint64 chainId1 = 1;
        uint64 chainId2 = 137;
        address vaultBank1 = _deployAccount(0x20, "VaultBank1");
        address vaultBank2 = _deployAccount(0x21, "VaultBank2");

        vm.startPrank(registryAdmin);
        superRegistry.addVaultBank(chainId1, vaultBank1);
        superRegistry.addVaultBank(chainId2, vaultBank2);
        vm.stopPrank();

        assertEq(superRegistry.getVaultBank(chainId1), vaultBank1, "Chain 1 vault bank mismatch");
        assertEq(superRegistry.getVaultBank(chainId2), vaultBank2, "Chain 2 vault bank mismatch");
    }

    /// @notice Tests replacing an existing vault bank for the same chain
    function test_VaultBankManagement_ReplaceVaultBank() public {
        uint64 chainId = 1;
        address oldVaultBank = _deployAccount(0x20, "OldVaultBank");
        address newVaultBank = _deployAccount(0x21, "NewVaultBank");

        // Add initial vault bank
        vm.prank(registryAdmin);
        superRegistry.addVaultBank(chainId, oldVaultBank);
        assertEq(superRegistry.getVaultBank(chainId), oldVaultBank, "Initial vault bank not set");

        // Replace with new vault bank
        vm.prank(registryAdmin);
        vm.expectEmit(true, true, false, false);
        emit ISuperRegistry.VaultBankAddressAdded(chainId, newVaultBank);
        superRegistry.addVaultBank(chainId, newVaultBank);

        assertEq(superRegistry.getVaultBank(chainId), newVaultBank, "Vault bank not replaced");
    }

    /// @notice Tests access control - only REGISTRY_ADMIN_ROLE can add vault banks
    function test_VaultBankManagement_AccessControl() public {
        uint64 chainId = 1;
        address vaultBank = _deployAccount(0x20, "VaultBank");

        // Test with user (should fail)
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, REGISTRY_ADMIN_ROLE)
        );
        superRegistry.addVaultBank(chainId, vaultBank);

        // Test with superRegistryAdmin (should fail - needs REGISTRY_ADMIN_ROLE specifically for this function)
        vm.prank(superRegistryAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, superRegistryAdmin, REGISTRY_ADMIN_ROLE
            )
        );
        superRegistry.addVaultBank(chainId, vaultBank);

        // Test with registryAdmin (should succeed)
        vm.prank(registryAdmin);
        superRegistry.addVaultBank(chainId, vaultBank);
        assertEq(superRegistry.getVaultBank(chainId), vaultBank, "Registry admin should be able to add vault bank");
    }

    /// @notice Tests reverting when adding vault bank with zero chain ID
    function test_VaultBankManagement_Revert_ZeroChainId() public {
        address vaultBank = _deployAccount(0x20, "VaultBank");

        vm.prank(registryAdmin);
        vm.expectRevert(ISuperRegistry.INVALID_CHAIN_ID.selector);
        superRegistry.addVaultBank(0, vaultBank);
    }

    /// @notice Tests reverting when adding vault bank with zero address
    function test_VaultBankManagement_Revert_ZeroVaultBankAddress() public {
        uint64 chainId = 1;

        vm.prank(registryAdmin);
        vm.expectRevert(ISuperRegistry.INVALID_ADDRESS.selector);
        superRegistry.addVaultBank(chainId, address(0));
    }

    /// @notice Tests getting vault bank for non-existent chain returns zero address
    function test_VaultBankManagement_GetNonExistentVaultBank() public view {
        uint64 nonExistentChainId = 999;
        address result = superRegistry.getVaultBank(nonExistentChainId);
        assertEq(result, address(0), "Non-existent vault bank should return zero address");
    }

    /// @notice Tests edge case with maximum chain ID
    function test_VaultBankManagement_MaxChainId() public {
        uint64 maxChainId = type(uint64).max;
        address vaultBank = _deployAccount(0x20, "MaxChainVaultBank");

        vm.prank(registryAdmin);
        vm.expectEmit(true, true, false, false);
        emit ISuperRegistry.VaultBankAddressAdded(maxChainId, vaultBank);
        superRegistry.addVaultBank(maxChainId, vaultBank);

        assertEq(superRegistry.getVaultBank(maxChainId), vaultBank, "Max chain ID vault bank mismatch");
    }

    // =============================================================
    // Incentive Token Management Tests
    // =============================================================

    /// @notice Tests proposing to add incentive tokens
    function test_IncentiveTokenManagement_ProposeAddIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(registryAdmin);
        vm.expectEmit(true, true, false, false);
        emit ISuperRegistry.WhitelistedIncentiveTokensProposed(tokens, expectedTime);
        superRegistry.proposeAddIncentiveTokens(tokens);

        // Check that tokens are in proposed state (not yet whitelisted)
        assertFalse(superRegistry.isWhitelistedIncentiveToken(token1), "Token1 should not be whitelisted yet");
        assertFalse(superRegistry.isWhitelistedIncentiveToken(token2), "Token2 should not be whitelisted yet");
    }

    /// @notice Tests reverting when proposing to add incentive tokens with zero address
    function test_IncentiveTokenManagement_Revert_ProposeAddZeroAddress() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        vm.prank(registryAdmin);
        vm.expectRevert(ISuperRegistry.INVALID_ADDRESS.selector);
        superRegistry.proposeAddIncentiveTokens(tokens);
    }

    /// @notice Tests executing addition of incentive tokens after timelock
    function test_IncentiveTokenManagement_ExecuteAddIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        // Propose the tokens
        vm.prank(registryAdmin);
        superRegistry.proposeAddIncentiveTokens(tokens);

        // Warp to after timelock
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the addition
        vm.expectEmit(true, false, false, false);
        emit ISuperRegistry.WhitelistedIncentiveTokensAdded(tokens);
        superRegistry.executeAddIncentiveTokens();

        // Verify tokens are now whitelisted
        assertTrue(superRegistry.isWhitelistedIncentiveToken(token1), "Token1 should be whitelisted");
        assertTrue(superRegistry.isWhitelistedIncentiveToken(token2), "Token2 should be whitelisted");
    }

    /// @notice Tests reverting when executing add without proposal
    function test_IncentiveTokenManagement_Revert_ExecuteAddNoProposal() public {
        vm.expectRevert(ISuperRegistry.TIMELOCK_NOT_EXPIRED.selector);
        superRegistry.executeAddIncentiveTokens();
    }

    /// @notice Tests reverting when executing add before timelock expiry
    function test_IncentiveTokenManagement_Revert_ExecuteAddBeforeTimelock() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x111);

        // Propose the tokens
        vm.prank(registryAdmin);
        superRegistry.proposeAddIncentiveTokens(tokens);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperRegistry.TIMELOCK_NOT_EXPIRED.selector);
        superRegistry.executeAddIncentiveTokens();
    }

    /// @notice Tests proposing to remove incentive tokens
    function test_IncentiveTokenManagement_ProposeRemoveIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        // First add the tokens
        vm.prank(registryAdmin);
        superRegistry.proposeAddIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);
        superRegistry.executeAddIncentiveTokens();

        // Now propose to remove them
        vm.warp(block.timestamp + 1); // Move time forward slightly
        uint256 expectedTime = block.timestamp + TIMELOCK;

        vm.prank(registryAdmin);
        vm.expectEmit(true, true, false, false);
        emit ISuperRegistry.WhitelistedIncentiveTokensProposed(tokens, expectedTime);
        superRegistry.proposeRemoveIncentiveTokens(tokens);

        // Tokens should still be whitelisted until execution
        assertTrue(superRegistry.isWhitelistedIncentiveToken(token1), "Token1 should still be whitelisted");
        assertTrue(superRegistry.isWhitelistedIncentiveToken(token2), "Token2 should still be whitelisted");
    }

    /// @notice Tests reverting when proposing to remove non-whitelisted tokens
    function test_IncentiveTokenManagement_Revert_ProposeRemoveNotWhitelisted() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x111);

        vm.prank(registryAdmin);
        vm.expectRevert(ISuperRegistry.NOT_WHITELISTED_INCENTIVE_TOKEN.selector);
        superRegistry.proposeRemoveIncentiveTokens(tokens);
    }

    /// @notice Tests reverting when proposing to remove incentive tokens with zero address
    function test_IncentiveTokenManagement_Revert_ProposeRemoveZeroAddress() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0);

        vm.prank(registryAdmin);
        vm.expectRevert(ISuperRegistry.INVALID_ADDRESS.selector);
        superRegistry.proposeRemoveIncentiveTokens(tokens);
    }

    /// @notice Tests executing removal of incentive tokens after timelock
    function test_IncentiveTokenManagement_ExecuteRemoveIncentiveTokens() public {
        address token1 = address(0x111);
        address token2 = address(0x222);
        address[] memory tokens = new address[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        // First add the tokens
        vm.prank(registryAdmin);
        superRegistry.proposeAddIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);
        superRegistry.executeAddIncentiveTokens();

        // Now propose and execute removal
        vm.warp(block.timestamp + 1);
        vm.prank(registryAdmin);
        superRegistry.proposeRemoveIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);

        // Execute the removal
        vm.expectEmit(true, false, false, false);
        emit ISuperRegistry.WhitelistedIncentiveTokensRemoved(tokens);
        superRegistry.executeRemoveIncentiveTokens();

        // Verify tokens are no longer whitelisted
        assertFalse(superRegistry.isWhitelistedIncentiveToken(token1), "Token1 should not be whitelisted");
        assertFalse(superRegistry.isWhitelistedIncentiveToken(token2), "Token2 should not be whitelisted");
    }

    /// @notice Tests reverting when executing remove without proposal
    function test_IncentiveTokenManagement_Revert_ExecuteRemoveNoProposal() public {
        vm.expectRevert(ISuperRegistry.TIMELOCK_NOT_EXPIRED.selector);
        superRegistry.executeRemoveIncentiveTokens();
    }

    /// @notice Tests reverting when executing remove before timelock expiry
    function test_IncentiveTokenManagement_Revert_ExecuteRemoveBeforeTimelock() public {
        address token1 = address(0x111);
        address[] memory tokens = new address[](1);
        tokens[0] = token1;

        // First add the token
        vm.prank(registryAdmin);
        superRegistry.proposeAddIncentiveTokens(tokens);
        vm.warp(block.timestamp + TIMELOCK + 1);
        superRegistry.executeAddIncentiveTokens();

        // Propose removal
        vm.warp(block.timestamp + 1);
        vm.prank(registryAdmin);
        superRegistry.proposeRemoveIncentiveTokens(tokens);

        // Try to execute before timelock expires
        vm.expectRevert(ISuperRegistry.TIMELOCK_NOT_EXPIRED.selector);
        superRegistry.executeRemoveIncentiveTokens();
    }

    /// @notice Tests access control for proposing incentive token changes
    function test_IncentiveTokenManagement_AccessControl() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(0x111);

        // Test proposeAddIncentiveTokens with non-registry-admin role
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, REGISTRY_ADMIN_ROLE)
        );
        superRegistry.proposeAddIncentiveTokens(tokens);

        // Test proposeRemoveIncentiveTokens with non-registry-admin role
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, REGISTRY_ADMIN_ROLE)
        );
        superRegistry.proposeRemoveIncentiveTokens(tokens);

        // Test with superRegistryAdmin role (should fail - needs REGISTRY_ADMIN_ROLE specifically)
        vm.prank(superRegistryAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, superRegistryAdmin, REGISTRY_ADMIN_ROLE
            )
        );
        superRegistry.proposeAddIncentiveTokens(tokens);

        vm.prank(superRegistryAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, superRegistryAdmin, REGISTRY_ADMIN_ROLE
            )
        );
        superRegistry.proposeRemoveIncentiveTokens(tokens);
    }

    /// @notice Tests that execution functions are public (can be called by anyone)
    function test_IncentiveTokenManagement_PublicExecution() public {
        address token1 = address(0x111);
        address[] memory tokens = new address[](1);
        tokens[0] = token1;

        // Propose as registryAdmin
        vm.prank(registryAdmin);
        superRegistry.proposeAddIncentiveTokens(tokens);

        // Execute as regular user (should work)
        vm.warp(block.timestamp + TIMELOCK + 1);
        vm.prank(user);
        superRegistry.executeAddIncentiveTokens();

        assertTrue(superRegistry.isWhitelistedIncentiveToken(token1), "Token should be whitelisted");

        // Same for removal
        vm.warp(block.timestamp + 1);
        vm.prank(registryAdmin);
        superRegistry.proposeRemoveIncentiveTokens(tokens);

        vm.warp(block.timestamp + TIMELOCK + 1);
        vm.prank(user);
        superRegistry.executeRemoveIncentiveTokens();

        assertFalse(superRegistry.isWhitelistedIncentiveToken(token1), "Token should not be whitelisted");
    }
}
